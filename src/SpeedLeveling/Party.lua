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
--  One guide for all of you (Saneroki, 2026-11-05: "I need them both to follow
--  the same steps ... Make one merged guide"): the classes and races of the
--  members on your guide are kept for the character (Core.Character, its with),
--  and the guide, and each one after it, is read together with them
--  (Format.Together): the same steps by the same numbers for each of you, every
--  step of any of your classes among them. What only one class does there (its
--  trainer, its class quests) only that one does; the others go past it to the
--  next step you share and wait there. Kept while they are offline or apart, and
--  made anew whenever members on your guide are other ones.
--
--  Only members who follow the same guide count, while they are online; each
--  tells only while its guide is followed and the switch Together with the
--  party is on. A message: the guide's key (its first Party.KEY bytes), the row,
--  and letters: "w" waiting there, through with it; "c" busy with a quest of its
--  class's on top of it (ClassQuests.lua), whom the others wait for there too;
--  "a" asking the others to tell theirs (the first message after a login, a
--  /reload or joining a group). Sent as the place changes; the wire holds it in a
--  fight.
--
--      Party.Holding(key, row)   the names of the members on that guide not yet through with the step at that row,
--                                nil: nobody holds you
--      Party.Busy(key, row, theirs)  the names of those of them busy with what only their class does before that row:
--                                a quest of their class's on top at it or before it, or at a row where theirs(row) says
--                                the guide's step is theirs alone
--      Party.With()              the others you read your guide together with: { { class, race } }; nil: alone
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

local places = {}  -- [member's key] = { key = guide's key, row, waits, chain }: where each member said it is
local members = {} -- [member's key] = the name to show: the group's members now, online
local kinds = {}   -- [member's key] = its class and race, the game's words ("DRUID NightElf")
local told         -- what was told last: "key\trow\twc", "" for no place; nil: nothing since the group was joined

local function Cut(key) return key:sub(1, Party.KEY) end

local function Grouped()
    local size = Plain(Core.Ask(rawget(_G, "GetNumGroupMembers")))
    return type(size) == "number" and size > 1 and size or nil
end

-- The group's members now, online; what was said of one who left or went offline is forgotten.
local function Roster()
    wipe(members)
    wipe(kinds)
    local size = Grouped()
    local raid = size and Plain(Core.Ask(rawget(_G, "IsInRaid"))) == true
    for n = 1, size or 0 do
        local unit = (raid and "raid" or "party") .. n
        local key = Core.PlayerKey(unit)
        if key and Plain(Core.Ask(rawget(_G, "UnitIsConnected"), unit)) ~= false then
            members[key] = Core.FullName(unit) or key
            local _, class = Core.Ask(UnitClass, unit)
            local _, race = Core.Ask(UnitRace, unit)
            class, race = Plain(class), Plain(race)
            kinds[key] = type(class) == "string" and type(race) == "string" and (class .. " " .. race) or nil
        end
    end
    for member in pairs(places) do
        if not members[member] then places[member] = nil end
    end
end

-- Whether a member holds you at the step at that row of that guide: on it, and not through with that step yet (before
-- it, or at it and not waiting there).
-- The names of the members on that guide for whom holds(there) is true; nil for none. One busy with its class's
-- quests is named so.
local function Named(key, holds)
    if not ns.options.party or not next(places) then return nil end
    key = Cut(key)
    local names
    for member, there in pairs(places) do
        if members[member] and there.key == key and holds(there) then
            names = names or {}
            names[#names + 1] = there.chain and ns.TEXT.onChain:format(members[member]) or members[member]
        end
    end
    if names then table.sort(names) end
    return names
end

function Party.Holding(key, row)
    return Named(key, function(there) return there.row < row or (there.row == row and not there.waits) end)
end

function Party.Busy(key, row, theirs)
    return Named(key, function(there)
        return (there.chain and there.row <= row) or (there.row < row and theirs(there.row))
    end)
end

-- The others you read your guide together with, as the character keeps them ("DRUID NightElf"); nil while alone or the
-- switch is off.
function Party.With()
    local with = ns.options.party and Core.Character(ns.name).with
    if type(with) ~= "table" or not with[1] then return nil end
    local list = {}
    for _, kind in ipairs(with) do
        local class, race = tostring(kind):match("^(%S+) (%S+)$")
        if class then list[#list + 1] = { class = class, race = race } end
    end
    return list[1] and list or nil
end

-- Who of the group is on your guide now: their kinds kept, the guide read anew when they are others than before (one
-- of your own class and race changes nothing: alone it reads the same). Nobody on it: those kept stay.
local function Learn()
    local guide = ns.options.party and ns.Run.Guide()
    if not guide then return end
    local key, found, seen, any = Cut(guide.key or guide.name), {}, {}, false
    local _, class = Core.Ask(UnitClass, "player")
    local _, race = Core.Ask(UnitRace, "player")
    local mine = tostring(Plain(class)) .. " " .. tostring(Plain(race))
    for member, there in pairs(places) do
        if members[member] and there.key == key then
            any = true
            local kind = kinds[member]
            if not kind then return end -- not known yet: decided once it is
            if kind ~= mine and not seen[kind] then
                seen[kind] = true
                found[#found + 1] = kind
            end
        end
    end
    if not any then return end
    table.sort(found)
    local notes = Core.Character(ns.name)
    local was = type(notes.with) == "table" and table.concat(notes.with, ",") or ""
    if table.concat(found, ",") == was then return end
    notes.with = found[1] and found or nil
    ns.Guide.Reread()
end

-- Your place told to the group when it is not what was told last; again: told even so (an answer to one who asked);
-- none: that you follow along no more.
local function Send(again, none)
    local size = Grouped()
    if not size then
        told = nil
        return
    end
    local key, row, waits, chain
    if not none and ns.options.party and ns.Guide.Following() then key, row, waits, chain = ns.Run.Spot() end
    local letters = (waits and "w" or "") .. (chain and "c" or "")
    local text = key and (Cut(key) .. "\t" .. row .. "\t" .. letters) or ""
    if text == (told or "") and not (again and key) then return end
    local ask = told == nil
    told = text
    local channel = Plain(Core.Ask(rawget(_G, "IsInRaid"))) == true and "RAID" or "PARTY"
    Core.Wire.Send(Party.KIND, { key and Cut(key) or "", row or "", letters .. (ask and "a" or ""), n = 3 },
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
        now = { key = key, row = row, waits = letters:find("w", 1, true) ~= nil, chain = letters:find("c", 1, true) ~= nil }
    end
    places[sender] = now
    if letters:find("a", 1, true) then Send(true) end
    local function Said(there) return there and (there.key .. there.row .. tostring(there.waits) .. tostring(there.chain)) end
    if Said(was) ~= Said(now) then
        Learn()
        ns.Guide.CheckSoon()
    end
end

-- The group changed: who is in it; one who left holds nobody any more, one who came is told (and asked).
local function Changed()
    if ns.off then return end
    Roster()
    if not Grouped() then told = nil end
    Learn()
    Send(false)
    ns.Guide.CheckSoon()
end

function Party.Start()
    Core.Wire.Listen(Party.KIND, ns.Guard(Heard))
    ns.On("GROUP_ROSTER_UPDATE", Changed)
    ns.On("UNIT_CONNECTION", Changed)
    Roster()
end
