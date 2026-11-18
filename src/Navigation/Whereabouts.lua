local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Whereabouts
--  Where your guild's members stand (Saneroki, 2026-11-18: "Guild members exact placement on
--  the map should not be default but should be visible when someone searches for that guild
--  member in the map searchbar"): while the full map's search shows members of your guild
--  (Find.lua: a name, "guild"), their SaneUI is asked where they are, and those who tell it
--  stand there on the map; the others at the middle of the zone the roster names, as before.
--  Nothing is asked otherwise, nothing kept longer than a few seconds, nothing saved.
--
--      Whereabouts.Want(members)   the search shows these members (Find.lua's entries, by who: a
--                                  player's key): asked now and every Whereabouts.EVERY seconds while
--                                  the search stands on the full map; nil: none, nothing asked
--      Whereabouts.Place(key)      where that member said it stands: { map, x, y } (0 to 1); nil where
--                                  it has not said so lately
--
--  On Core's wire, the kind H, urgent: "?" and the names asked (their keys, cut by commas; none: all
--  of them) to the guild. Each member asked answers with a whisper while its switch for it is on
--  (guildPlace, on the page Navigation): "!", its map and its place, or "!" alone where the game
--  tells no place (inside an instance); never in a fight, to one asker once every Whereabouts.GAP
--  seconds at most. An answer is taken only by a whisper, only from a member asked within
--  Whereabouts.HOLD seconds, only of a map the game knows and a place on it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Wire = Core.Wire
local Whereabouts = {}
ns.Whereabouts = Whereabouts

Whereabouts.KIND = "H"      -- the wire's kind
Whereabouts.EVERY = 5       -- seconds between two asks while the search shows members
Whereabouts.LEAST = 2       -- seconds at least between two asks (as the words typed change who is found)
Whereabouts.HOLD = 15       -- seconds after an ask its answers are taken
Whereabouts.FRESH = 20      -- seconds a place told stands (asked anew meanwhile)
Whereabouts.GAP = 2         -- seconds at least between two answers to one asker
Whereabouts.NAMES = 200     -- bytes of names an ask carries at most; for more, all are asked

local NONE = {}
local wanted          -- [key] = true: the members the search shows; nil: none
local names           -- their keys for the ask, cut by commas; "" (all) where they do not fit
local last = -math.huge -- when the last ask went
local places = {}     -- [key] = { map, x, y, at }
local answered, count = {}, 0 -- [asker's key] = when it was answered last; how many are noted
local ticker

local function Fighting()
    return Core.Ask(rawget(_G, "InCombatLockdown")) == true
end

-- The guild asked where the members the search shows stand: only while the search stands on the full map, in a
-- guild, out of a fight (the wire holds messages back in one: they would come late), Whereabouts.LEAST apart.
local function Ask()
    if not wanted or ns.off or Fighting() or not Core.Ask(rawget(_G, "IsInGuild")) then return end
    if not (ns.FindBox and ns.FindBox.Up and ns.FindBox.Up()) then return end
    local now = GetTime()
    if now - last < Whereabouts.LEAST then return end
    last = now
    Wire.Send(Whereabouts.KIND, { "?", names, n = 2 }, "GUILD", nil, true)
end
local Soon = Core.Later(ns.Guard(Ask), Whereabouts.LEAST, "Navigation: guild places")

-- The search's pins drawn anew a moment after a place was told (several answers come close together).
local Redraw = Core.Later(ns.Guard(function()
    if ns.Find and ns.Find.Retold then ns.Find.Retold() end
end), 0.2, "Navigation: guild places")

-- Every Whereabouts.EVERY seconds while the search shows members: asked again; a place not told anew meanwhile goes.
local function Tick()
    Ask()
    local now, gone = GetTime(), false
    for key, place in pairs(places) do
        if now - place.at > Whereabouts.FRESH then
            places[key] = nil
            gone = true
        end
    end
    if gone and ns.Find and ns.Find.Retold then ns.Find.Retold() end
end

function Whereabouts.Want(members)
    local set, keys, size = nil, {}, 0
    for _, entry in ipairs(members or NONE) do
        local key = entry.who
        if type(key) == "string" and key ~= "" and not (set and set[key]) then
            set = set or {}
            set[key] = true
            keys[#keys + 1] = key
            size = size + #key + 1
        end
    end
    local text = set and (size <= Whereabouts.NAMES and table.concat(keys, ",") or "") or nil
    local changed = text ~= names
    wanted, names = set, text
    if not set then
        if ticker then ticker:Cancel() end
        ticker = nil
        return
    end
    if not ticker then ticker = C_Timer.NewTicker(Whereabouts.EVERY, ns.Guard(Tick)) end
    if changed then
        if GetTime() - last >= Whereabouts.LEAST then Ask() else Soon() end
    end
end

function Whereabouts.Place(key)
    local place = key and places[key]
    if not place then return nil end
    if GetTime() - place.at > Whereabouts.FRESH then
        places[key] = nil
        return nil
    end
    return place
end

-- A member asked where we are: told by a whisper, while the switch lets it (below).
local function Answer(sender, asked, name)
    if not (ns.options and ns.options.guildPlace) or Fighting() then return end
    if type(asked) == "string" and asked ~= "" then
        local mine, named = Core.PlayerKey("player"), false
        for each in asked:gmatch("[^,]+") do
            if each == mine then named = true break end
        end
        if not named then return end
    end
    local now = GetTime()
    if answered[sender] and now - answered[sender] < Whereabouts.GAP then return end
    if count > 200 then answered, count = {}, 0 end
    if not answered[sender] then count = count + 1 end
    answered[sender] = now
    local map = Plain(Core.Ask(C_Map.GetBestMapForUnit, "player"))
    local position = map and Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local x, y = position and Plain(position.x), position and Plain(position.y)
    local fields = { "!", n = 1 }
    if type(x) == "number" and type(y) == "number" then
        fields = { "!", tostring(map), ("%.4f"):format(x), ("%.4f"):format(y), n = 4 }
    end
    Wire.Send(Whereabouts.KIND, fields, "WHISPER", name or sender, true)
end

-- A member asked said where it stands (or that the game tells it no place: forgotten).
local function Told(sender, fields)
    if not (wanted and wanted[sender]) or GetTime() - last > Whereabouts.HOLD then return end
    if fields[2] == nil or fields[2] == "" then
        if places[sender] then
            places[sender] = nil
            Redraw()
        end
        return
    end
    local map, x, y = tonumber(fields[2]), tonumber(fields[3]), tonumber(fields[4])
    if not (map and x and y) or map ~= math.floor(map) or map <= 0 or x < 0 or x > 1 or y < 0 or y > 1 then return end
    if not Core.Ask(C_Map.GetMapInfo, map) then return end
    places[sender] = { map = map, x = x, y = y, at = GetTime() }
    Redraw()
end

-- A message of the kind H came (Core.Wire): an ask on the guild's channel, an answer by a whisper; nothing else.
function Whereabouts.Heard(sender, fields, channel, name)
    if ns.off or type(fields) ~= "table" then return end
    if fields[1] == "?" and channel == "GUILD" then return Answer(sender, fields[2], name) end
    if fields[1] == "!" and channel == "WHISPER" then return Told(sender, fields) end
end

if Wire and Wire.Listen then Wire.Listen(Whereabouts.KIND, ns.Guard(Whereabouts.Heard)) end
