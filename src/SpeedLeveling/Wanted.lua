local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Wanted
--  What the key looks for around you, by name, in this order (the key takes
--  the first it finds), the NPCs before the creatures (Saneroki, 2026-10-25):
--    1. the NPCs the steps at hand of your leveling guide name (Guide.lua: the
--       guide Sane UI knows while it is loaded, else a guide pasted as text;
--       while the switch is on)
--    2. the NPCs your finished quests are handed in to, of your side
--    3. the creatures the guide's step names
--    4. the creatures of your quests' open objectives (Core's sets Quests and
--       NPCs): those to kill, then those that drop an item to loot (Drops),
--       the likeliest first, at most DROPPERS an item
--    5. creatures the game itself marks for a quest of yours (Core.UnitQuest)
--       on a nameplate: what Core's data does not know
--  Core's names are English: on a client in another language only 1, 3 and 5.
--
--  And the things of the world your quests want picked up or used (Object),
--  by the game's object ID, in any language: those of open objectives, those
--  an item to loot comes from (Drops), those a finished quest is handed in to.
--  The game tells no addon where they are; the key finds the one its interact
--  key would use (the soft target, Key.lua).
--
--  The quests' part is read anew after the quest log changed, the guide's at
--  each question.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Wanted = {}
ns.Wanted = Wanted

Wanted.DROPPERS = 3 -- creatures named for an item to loot
Wanted.PLATES = 40  -- nameplate units looked at when the quest log changed

local QUESTS, NPCS, DROPS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Drops")
local ENGLISH = { enUS = true, enGB = true }
local EMPTY = {}

local quests       -- the names of 2 and 4, { friends, foes }, and the objects, { [ID] = true }; nil: to be read anew
local marked = {}  -- the creatures of 5, in the order they were seen
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

-- The quests in the log: the creatures of their open objectives (to kill, then to loot from) and the NPCs to hand
-- the finished ones in to, by name (English only); the objects of their objectives, of the items to loot and to
-- hand in to, by ID.
local function Read()
    local foes, friends, have, objects = {}, {}, {}, {}
    quests = { foes = foes, friends = friends, objects = objects }
    local log = rawget(_G, "C_QuestLog")
    local total = log and Core.Ask(log.GetNumQuestLogEntries)
    if type(total) ~= "number" then return end
    local english = English()
    local side = Core.Ask(UnitFactionGroup, "player")
    side = type(side) == "string" and side:lower() or nil
    local items, due = {}, {}
    for index = 1, total do
        local info = Core.Ask(log.GetInfo, index)
        local quest = type(info) == "table" and not info.isHeader and Plain(info.questID)
        local record = type(quest) == "number" and QUESTS:Get(quest)
        if record and Core.Ask(log.IsComplete, quest) then
            for _, finish in ipairs(record.finishNPCs or EMPTY) do
                if not finish.side or finish.side == side then due[#due + 1] = finish.npc end
            end
            for _, finish in ipairs(record.finishObjects or EMPTY) do
                if not finish.side or finish.side == side then objects[finish.object] = true end
            end
        elseif record then
            local open = Core.Ask(log.GetQuestObjectives, quest)
            for _, objective in ipairs(record.objectives or EMPTY) do
                local state = type(open) == "table" and open[objective.index]
                if type(state) == "table" and not Plain(state.finished) then
                    if objective.kind == "kill" then
                        Add(foes, have, Name(objective.what))
                    elseif objective.kind == "loot" then
                        items[#items + 1] = objective.what
                    elseif objective.kind == "object" and type(objective.what) == "number" then
                        objects[objective.what] = true
                    end
                end
            end
        end
    end
    for _, item in ipairs(items) do
        for _, npc in ipairs(Droppers(item, objects)) do Add(foes, have, Name(npc)) end
    end
    for _, npc in ipairs(due) do Add(friends, have, Name(npc)) end
    if not english then
        wipe(foes)
        wipe(friends)
    end
end

-- A creature on a nameplate that the game marks for a quest of yours (5).
local function Seen(unit)
    if Core.Ask(UnitIsPlayer, unit) then return end
    local doing = Core.UnitQuest(unit)
    if doing == "kill" or doing == "loot" then Add(marked, markedSet, (Core.Ask(UnitName, unit))) end
end

-- Every name wanted, in the order above, and the same as a set.
function Wanted.Names()
    if not quests then Read() end
    local names, have = {}, {}
    local foes, friends
    foes, friends = ns.Guide.Targets()
    for _, list in ipairs({ friends or EMPTY, quests.friends, foes or EMPTY, quests.foes, marked }) do
        for _, name in ipairs(list) do Add(names, have, name) end
    end
    return names, have
end

-- Whether a unit is wanted: a creature or NPC of those names, or one the game marks for a quest of yours.
function Wanted.Unit(unit)
    if not Core.Ask(UnitExists, unit) or Core.Ask(UnitIsPlayer, unit) then return false end
    local _, have = Wanted.Names()
    local name = Core.Ask(UnitName, unit)
    if type(name) == "string" and have[name] then return true end
    local doing = Core.UnitQuest(unit)
    return doing == "kill" or doing == "loot"
end

-- Whether a thing of the world is one your quests want, by its GUID ("GameObject-0-...-<ID>-<spawn>").
function Wanted.Object(guid)
    if type(guid) ~= "string" then return false end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if kind ~= "GameObject" then return false end
    if not quests then Read() end
    return quests.objects[tonumber(id)] == true
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
