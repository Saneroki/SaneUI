local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Party
--  The party on one guide, a step at a time (Saneroki, 2026-11-05: "I play on 2
--  characters and the order in which they choose the next quest is a little
--  random. Can you make sure that the 2 characters in the party are synced with
--  the quest order?"). Each character runs its guide by its own quest log, so the
--  one whose drop came first went on to the next quest while the other did not.
--  So each member tells the others of the party or raid where it is in the guide
--  it follows (Core's wire, kind S), and whoever is through with a step first
--  waits on it (Run.lua) until every member on that guide is through with it
--  too; then all go on together. A step is known by the line of the guide's text
--  it begins at (its row, Format.lua), the same for every class and race whatever
--  steps the guide keeps for each: a druid's step a warrior lacks holds the
--  warrior at the step before it, and the other way round.
--
--  Only members who follow the same guide count, while they are online; each
--  tells only while its guide is followed and the switch Wait for the party is
--  on. A message: the guide's key (its first Party.KEY bytes), the row, and
--  letters: "w" waiting there, through with it; "a" asking the others to tell
--  theirs (the first message after a login, a /reload or joining a group). Sent
--  as the place changes; the wire holds it in a fight.
--
--      Party.Holding(key, row)   the names of the members on that guide not yet through with the step at that row,
--                                nil: nobody holds you
--      Party.Tell()              your place told to the group, when it changed (after each check of the guide)
--      Party.GiveBack()          resting or stood down: the group told you follow along no more
--      Party.Start()             listens, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Party = {}
ns.Party = Party

Party.KIND = "S" -- the wire's kind of these messages
Party.KEY = 180  -- bytes of a guide's key a message carries, so it stays within the wire's 255

local places = {}  -- [member's key] = { key = guide's key, row, waits }: where each member said it is
local members = {} -- [member's key] = the name to show: the group's members now, online
local told         -- what was told last: "key\trow\tw", "" for no place; nil: nothing since the group was joined

local function Cut(key) return key:sub(1, Party.KEY) end

local function Grouped()
    local size = Plain(Core.Ask(rawget(_G, "GetNumGroupMembers")))
    return type(size) == "number" and size > 1 and size or nil
end

-- The group's members now, online; what was said of one who left or went offline is forgotten.
local function Roster()
    wipe(members)
    local size = Grouped()
    local raid = size and Plain(Core.Ask(rawget(_G, "IsInRaid"))) == true
    for n = 1, size or 0 do
        local unit = (raid and "raid" or "party") .. n
        local key = Core.PlayerKey(unit)
        if key and Plain(Core.Ask(rawget(_G, "UnitIsConnected"), unit)) ~= false then
            members[key] = Core.FullName(unit) or key
        end
    end
    for member in pairs(places) do
        if not members[member] then places[member] = nil end
    end
end

-- Whether a member holds you at the step at that row of that guide: on it, and not through with that step yet (before
-- it, or at it and not waiting there).
function Party.Holding(key, row)
    if not ns.options.party or not next(places) then return nil end
    key = Cut(key)
    local names
    for member, there in pairs(places) do
        if members[member] and there.key == key and (there.row < row or (there.row == row and not there.waits)) then
            names = names or {}
            names[#names + 1] = members[member]
        end
    end
    if names then table.sort(names) end
    return names
end

-- Your place told to the group when it is not what was told last; again: told even so (an answer to one who asked);
-- none: that you follow along no more.
local function Send(again, none)
    local size = Grouped()
    if not size then
        told = nil
        return
    end
    local key, row, waits
    if not none and ns.options.party and ns.Guide.Following() then key, row, waits = ns.Run.Spot() end
    local text = key and (Cut(key) .. "\t" .. row .. "\t" .. (waits and "w" or "")) or ""
    if text == (told or "") and not (again and key) then return end
    local ask = told == nil
    told = text
    local channel = Plain(Core.Ask(rawget(_G, "IsInRaid"))) == true and "RAID" or "PARTY"
    Core.Wire.Send(Party.KIND, { key and Cut(key) or "", row or "", (waits and "w" or "") .. (ask and "a" or ""), n = 3 },
        channel, nil, true)
end

function Party.Tell()
    if ns.off then return end
    Send(false)
end

-- The module resting or stood down: the group told you follow along no more, so nobody waits for you. What they say
-- meanwhile is not heard: taken up again, you ask anew.
function Party.GiveBack()
    Send(false, true)
    told = nil
    wipe(places)
end

-- What a member told: where it is, or that it follows no guide; one who asks is answered.
local function Heard(sender, fields, channel)
    if channel ~= "PARTY" and channel ~= "RAID" then return end
    if not members[sender] then Roster() end
    if not members[sender] then return end
    local key, row, letters = fields[1], fields[2], fields[3] or ""
    row = type(row) == "string" and row:match("^%d+$") and tonumber(row) or nil
    local was, now = places[sender], nil
    if type(key) == "string" and key ~= "" and row then
        now = { key = key, row = row, waits = letters:find("w", 1, true) ~= nil }
    end
    places[sender] = now
    if letters:find("a", 1, true) then Send(true) end
    if (was and (was.key .. was.row .. tostring(was.waits))) ~= (now and (now.key .. now.row .. tostring(now.waits))) then
        ns.Guide.CheckSoon()
    end
end

-- The group changed: who is in it; one who left holds nobody any more, one who came is told (and asked).
local function Changed()
    if ns.off then return end
    Roster()
    if not Grouped() then told = nil end
    Send(false)
    ns.Guide.CheckSoon()
end

function Party.Start()
    Core.Wire.Listen(Party.KIND, ns.Guard(Heard))
    ns.On("GROUP_ROSTER_UPDATE", Changed)
    ns.On("UNIT_CONNECTION", Changed)
    Roster()
end
