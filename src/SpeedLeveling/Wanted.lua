local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Wanted
--  What the key looks for around you, by name, in this order (the key takes
--  the first it finds), the NPCs before the creatures (Saneroki, 2026-10-25):
--    1. the NPCs the steps at hand of your guide name (Guide.Targets; while the
--       switch is on)
--    2. the NPCs your finished quests are handed in to, of your side, the
--       nearest first (Core's sets Quests, Spawns)
--    3. the creatures the guide's steps name
--    4. creatures the game itself marks for a quest of yours (Core.UnitQuest)
--       on a nameplate: they are near
--    5. the creatures of your quests' open objectives, from Core's data (the
--       sets Quests, NPCs, Spawns): those to kill, then those that drop an item
--       to loot (Drops: the likeliest three an item); of those Core knows where
--       they live, only those of the zone you are in, the nearest first, then
--       those it knows no place of
--    6. a quest Core's data does not hold (Retail has no data yet): the
--       creature its objective names in the game's own words ("Mottled Boar
--       slain: 2/10")
--  Core's names are English: on a client in another language only 1, 3, 4, 6.
--
--  And the things of the world (Object): the one the interact key would use
--  counts when your quests want it by the game's object ID (those of open
--  objectives, those an item to loot comes from, those a finished quest is
--  handed in to; any language), when the game says it belongs to a quest of
--  yours, or when your guide's steps at hand or an open objective name it.
--  The game tells no addon where things are; the key knows the one its
--  interact key would use (the soft target, Key.lua).
--
--  The quests' part is read anew after the quest log changed; the order by how
--  near at each question.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Wanted = {}
ns.Wanted = Wanted

Wanted.DROPPERS = 3 -- creatures named for an item to loot
Wanted.PLATES = 40  -- nameplate units looked at when the quest log changed

local QUESTS, NPCS, DROPS, SPAWNS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Drops"),
                                    Core.Data.Set("Spawns")
local ENGLISH = { enUS = true, enGB = true }
local EMPTY = {}
local ZONE = 3 -- the game's Enum.UIMapType.Zone, should its name be missing

local quests       -- what the log wants, read once a change: { friends, foes, words, objects, names }; nil: anew
local marked = {}  -- the creatures of 4, in the order they were seen
local markedSet = {}

local function English()
    return ENGLISH[Core.Ask(rawget(_G, "GetLocale")) or ""] == true
end

-- A name into a list, once (have: the names in it).
local function Add(list, have, name)
    if type(name) == "string" and name ~= "" and not have[name] then
        have[name] = true
        list[#list + 1] = name
    end
end

local function Name(npc)
    return type(npc) == "number" and NPCS:Get(npc, "name") or nil
end

-------------------------------------------------------------------------------
--  Where they live
-------------------------------------------------------------------------------
-- The zone you are in and where you stand on its map (shares of 100); nil where the game does not say.
local function Here()
    local maps = rawget(_G, "C_Map")
    if not maps then return nil end
    local map = Plain(Core.Ask(maps.GetBestMapForUnit, "player"))
    local zone = rawget(_G, "Enum") and Enum.UIMapType and Enum.UIMapType.Zone or ZONE
    local seen = 0
    while type(map) == "number" and seen < 8 do
        local info = Core.Ask(maps.GetMapInfo, map)
        if type(info) ~= "table" or Plain(info.mapType) == zone or not Plain(info.parentMapID) then break end
        map, seen = Plain(info.parentMapID), seen + 1
    end
    if type(map) ~= "number" then return nil end
    local point = Core.Ask(maps.GetPlayerMapPosition, map, "player")
    local x, y
    if type(point) == "table" then
        if point.GetXY then x, y = point:GetXY() else x, y = point.x, point.y end
    end
    x, y = Plain(x), Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return { map = map } end
    return { map = map, x = x * 100, y = y * 100 }
end

-- How far a creature's nearest spawn of your zone is (squared, in shares of the map); false: Core knows its places,
-- none in your zone; nil: Core knows none.
local function Distance(npc, here)
    local points = SPAWNS:Get("npc:" .. tostring(npc), "points")
    if type(points) ~= "table" or not points[1] then return nil end
    if not here then return 0 end
    local best = false
    for _, point in pairs(points) do
        if type(point) == "table" and point.map == here.map then
            local d = here.x and ((point.x - here.x) ^ 2 + (point.y - here.y) ^ 2) or 0
            if not best or d < best then best = d end
        end
    end
    return best
end

-- Creatures by their IDs as names, the nearest first: those of your zone, then those of no known place.
local function Nearest(ids, here)
    local known, unknown = {}, {}
    for _, npc in ipairs(ids) do
        local d = Distance(npc, here)
        if d then known[#known + 1] = { npc = npc, d = d } elseif d == nil then unknown[#unknown + 1] = npc end
    end
    table.sort(known, function(a, b)
        if a.d ~= b.d then return a.d < b.d end
        return a.npc < b.npc
    end)
    local names, have = {}, {}
    for _, entry in ipairs(known) do Add(names, have, Name(entry.npc)) end
    for _, npc in ipairs(unknown) do Add(names, have, Name(npc)) end
    return names
end

-------------------------------------------------------------------------------
--  The quest log
-------------------------------------------------------------------------------
-- The creatures that drop an item when looted, the likeliest first (one without a chance last), at most DROPPERS;
-- the objects it comes from go into objects.
local function Droppers(item, objects)
    local found = {}
    for _, key in ipairs(DROPS:Keys("byItem", item)) do
        local kind, id = tostring(key):match("^(%a+):(%d+)$")
        id = tonumber(id)
        local record = id and (kind == "npc" or kind == "object") and DROPS:Get(key)
        for _, drop in ipairs(record and record.items or EMPTY) do
            if drop.item == item and kind == "object" and drop.how ~= "fish" then
                objects[id] = true
                break
            elseif drop.item == item and (drop.how == nil or drop.how == "loot") then
                found[#found + 1] = { npc = id, chance = drop.chance or 0 }
                break
            end
        end
    end
    table.sort(found, function(a, b)
        if a.chance ~= b.chance then return a.chance > b.chance end
        return a.npc < b.npc
    end)
    local npcs = {}
    for index = 1, math.min(#found, Wanted.DROPPERS) do npcs[index] = found[index].npc end
    return npcs
end

-- An objective's words without colours and without its count, before or after them ("Mottled Boar slain: 2/10",
-- "2/10 Mottled Boar slain"): what is to be done.
local function Label(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("\194\160", " ")
    text = text:gsub("^%s*%d+%s*/%s*%d+%s*", ""):gsub("[%s:]*%d+%s*/%s*%d+%s*$", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text ~= "" and text or nil
end

-- A pattern of the game's words for a creature slain, its counts left out ("%s slain"): the name caught.
local function Pattern(word)
    if type(word) ~= "string" or not word:find("%%s") then return nil end
    word = word:gsub("[%s:]*%%%d?%$?d%s*/%s*%%%d?%$?d[%s:]*", "")
    local pattern = word:gsub("%%%d?%$?s", "\0"):gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"):gsub("%z", "(.-)")
    return "^" .. pattern .. "$"
end

local KILLED = Pattern(Core.Word("QUEST_MONSTERS_KILLED", "%s slain: %d/%d"))

-- The quests in the log: by Core's data the creatures of their open objectives (to kill, then to loot from) and the
-- NPCs to hand the finished ones in to (English only), the objects of their objectives, of the items to loot and to
-- hand in to, by ID; for a quest Core does not hold, the creatures its objectives name in the game's words; and the
-- names of the things open objectives name (for objects in front of you, any language).
local function Read()
    local foes, words, due, objects, names = {}, {}, {}, {}, {}
    quests = { foes = foes, words = words, due = due, objects = objects, names = names }
    local log = rawget(_G, "C_QuestLog")
    local total = log and Core.Ask(log.GetNumQuestLogEntries)
    if type(total) ~= "number" then return end
    local english = English()
    local side = Core.Ask(UnitFactionGroup, "player")
    side = type(side) == "string" and side:lower() or nil
    local items, haveFoe, haveWord = {}, {}, {}
    for index = 1, total do
        local info = Core.Ask(log.GetInfo, index)
        local quest = type(info) == "table" and not Plain(info.isHeader) and Plain(info.questID)
        local record = type(quest) == "number" and QUESTS:Get(quest)
        local open = type(quest) == "number" and Core.Ask(log.GetQuestObjectives, quest)
        local complete = type(quest) == "number" and Core.Ask(log.IsComplete, quest)
        if record and complete then
            for _, finish in ipairs(record.finishNPCs or EMPTY) do
                if not finish.side or finish.side == side then due[#due + 1] = finish.npc end
            end
            for _, finish in ipairs(record.finishObjects or EMPTY) do
                if not finish.side or finish.side == side then objects[finish.object] = true end
            end
        elseif record then
            for _, objective in ipairs(record.objectives or EMPTY) do
                local state = type(open) == "table" and open[objective.index]
                if type(state) == "table" and not Plain(state.finished) then
                    if objective.kind == "kill" and type(objective.what) == "number" then
                        if not haveFoe[objective.what] then
                            haveFoe[objective.what] = true
                            foes[#foes + 1] = objective.what
                        end
                    elseif objective.kind == "loot" then
                        items[#items + 1] = objective.what
                    elseif objective.kind == "object" and type(objective.what) == "number" then
                        objects[objective.what] = true
                    end
                end
            end
        end
        -- The game's own words of what is open: a creature to kill where Core holds no quest, a thing's name always.
        if type(open) == "table" and not complete then
            for _, state in ipairs(open) do
                local text = type(state) == "table" and not Plain(state.finished) and Label(Plain(state.text))
                local kind = type(state) == "table" and Plain(state.type)
                if text and kind == "monster" and not record then
                    Add(words, haveWord, KILLED and text:match(KILLED))
                elseif text and (kind == "object" or kind == "item") then
                    names[text:lower()] = true
                end
            end
        end
    end
    for _, item in ipairs(items) do
        for _, npc in ipairs(Droppers(item, objects)) do
            if not haveFoe[npc] then
                haveFoe[npc] = true
                foes[#foes + 1] = npc
            end
        end
    end
    if not english then
        wipe(foes)
        wipe(due)
    end
end

-- A creature on a nameplate that the game marks for a quest of yours (4).
local function Seen(unit)
    if Core.Ask(UnitIsPlayer, unit) then return end
    local doing = Core.UnitQuest(unit)
    if doing == "kill" or doing == "loot" then Add(marked, markedSet, (Core.Ask(UnitName, unit))) end
end

-- Every name wanted, in the order above, and the same as a set.
function Wanted.Names()
    if not quests then Read() end
    local here = Here()
    local names, have = {}, {}
    local foes, friends = ns.Guide.Targets()
    for _, list in ipairs({ friends or EMPTY, Nearest(quests.due, here), foes or EMPTY, marked,
                            Nearest(quests.foes, here), quests.words }) do
        for _, name in ipairs(list) do Add(names, have, name) end
    end
    return names, have
end

-- Whether a unit is wanted: a creature or NPC of those names, or one the game marks for a quest of yours: a creature
-- to kill or loot, or an NPC that is no foe (one to hand a quest in to, or to speak to; on any client, without Core's
-- data). have: the names as a set, where the caller asked for them already (Key.Refresh asks once for all it does).
function Wanted.Unit(unit, have)
    if not Core.Ask(UnitExists, unit) or Core.Ask(UnitIsPlayer, unit) then return false end
    if not have then have = select(2, Wanted.Names()) end
    local name = Core.Ask(UnitName, unit)
    if type(name) == "string" and have[name] then return true end
    local doing = Core.UnitQuest(unit)
    if doing == "kill" or doing == "loot" then return true end
    local log = rawget(_G, "C_QuestLog")
    return Core.Ask(UnitCanAttack, "player", unit) ~= true and log ~= nil
        and Core.Ask(log.UnitIsRelatedToActiveQuest, unit) == true
end

-- Whether the thing of the world in front of you (its GUID, "GameObject-0-...-<ID>-<spawn>") is one your quests or
-- your guide want: by its ID, by the game's word, or by its name.
function Wanted.Object(guid)
    if type(guid) ~= "string" then return false end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind ~= "GameObject" then return false end
    if not quests then Read() end
    if quests.objects[tonumber(id)] then return true end
    -- The game's own word, where it gives one for a thing.
    local log = rawget(_G, "C_QuestLog")
    local related = log and log.UnitIsRelatedToActiveQuest and Core.Ask(log.UnitIsRelatedToActiveQuest, "softinteract")
    if related == true then return true end
    local name = Plain(Core.Ask(UnitName, "softinteract"))
    if type(name) ~= "string" or name == "" then return false end
    name = name:lower()
    if quests.names[name] then return true end
    for _, named in ipairs(ns.Guide.Things() or EMPTY) do
        if named:lower() == name then return true end
    end
    return false
end

-- The quests or the switch changed: all read anew, the nameplates shown now looked at again, the key told.
function Wanted.Changed()
    quests = nil
    wipe(marked)
    wipe(markedSet)
    for index = 1, Wanted.PLATES do
        local unit = "nameplate" .. index
        if Core.Ask(UnitExists, unit) then Seen(unit) end
    end
    ns.Key.Refresh()
end

function Wanted.Start()
    local changed = Core.Later(ns.Wanted.Changed, 0.5)
    ns.On("QUEST_LOG_UPDATE", changed)
    ns.On("NAME_PLATE_UNIT_ADDED", Seen)
end
