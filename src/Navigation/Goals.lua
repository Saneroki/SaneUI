local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Goals
--  What your quests still ask of the world, and where exactly it stands: of each quest in the log that Core's
--  data holds, the open objectives' things (a creature to kill or speak to, an object to use, what gives an item to
--  loot) at every point Core's sets know them, so the map can pin the very spawns and not only the quest's area.
--  Knows no frames: Pins.lua makes them pins.
--
--      Goals.Read()         the log read again if it said it changed; true when what is wanted changed
--      Goals.Wanted()       [thing] = { texture, goals = { { quest, index }, ... } }: "npc:69", "object:1617"
--      Goals.Spots(thing)   its points by map: { [map] = { { map, x, y }, ... } }, x and y in percent
--      Goals.Stale()        the log changed: read again when next asked
--      Goals.Forget()       Core's data changed: nothing kept
--
--  The counts in an objective's words change with every kill, what is wanted only when one is done: so the pins
--  are made again only then, and a tooltip asks the game for the words (PinView.lua).
--  A quest Core's data does not hold has no goals: the game's own question mark and area stand for it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Goals = {}
ns.Goals = Goals

Goals.SPEAK = "Interface\\CURSOR\\Speak" -- a creature to speak to: the game's mouse cursor, as the quest log's sword and sack
Goals.GIVERS = 12    -- things pinned for an item to loot, the likeliest first, at most
Goals.UNLIKELY = 0.5 -- of the likeliest's chance: a thing that gives an item less often is left out

local QUESTS, SPAWNS, CREATURES = Core.Data.Set("Quests"), Core.Data.Set("Spawns"), Core.Data.Set("CreatureSpawns")
local NONE = {}

local wanted = {}  -- Goals.Wanted's answer
local said         -- what is wanted, in one line: the same again changes nothing
local stale = true -- the log said it changed since it was read
local spots = {}   -- [thing] = its points by map, until Core's data changes
local givers = {}  -- [item] = the things that give it, until Core's data changes

-- What gives an item to loot: by Core's Drops, the likeliest first (From's order), at most GIVERS. A cloth or a meat
-- many creatures may drop: those that give it far less often than the likeliest are left out, those without a known
-- chance kept (only that they give it is known).
local function Givers(item)
    local list = givers[item]
    if list then return list end
    list = {}
    local best
    for _, entry in ipairs(Core.Data.Drops():From(item)) do
        local kind = entry.key:match("^(%a+):")
        local way = kind == "npc" and entry.how == "loot" or kind == "object" and entry.how ~= "fish"
        if way then
            best = best or entry.rate
            if entry.rate == 0 or entry.rate >= best * Goals.UNLIKELY then list[#list + 1] = entry.key end
            if #list >= Goals.GIVERS then break end
        end
    end
    givers[item] = list
    return list
end

-- The things an objective of Core's data asks for: each its key; those of no kind with a place (an area to explore, an
-- event) none.
local function Things(objective)
    local kind, what = objective.kind, objective.what
    if type(what) ~= "number" then return NONE end
    if kind == "kill" or kind == "talk" then return { "npc:" .. what } end
    if kind == "object" then return { "object:" .. what } end
    if kind == "loot" then return Givers(what) end
    return NONE
end

-- An open objective's things into what is wanted: one entry per thing, however many quests ask for it; a thing to
-- kill in the sword's picture also where another objective loots from it.
local function Want(found, quest, objective)
    local asks = ns.QuestLog.ASKS[objective.kind] or Goals.SPEAK
    for _, thing in ipairs(Things(objective)) do
        local entry = found[thing]
        if not entry then
            entry = { texture = asks, goals = {} }
            found[thing] = entry
        elseif objective.kind == "kill" then
            entry.texture = asks
        end
        entry.goals[#entry.goals + 1] = { quest = quest, index = objective.index }
    end
end

function Goals.Read()
    if not stale then return false end
    stale = false
    local found, parts = {}, {}
    if QUESTS:Ready() then
        for index = 1, Core.Ask(C_QuestLog.GetNumQuestLogEntries) or 0 do
            local info = Core.Ask(C_QuestLog.GetInfo, index)
            local quest = type(info) == "table" and not info.isHeader and not info.isHidden and Core.Plain(info.questID)
            local record = quest and QUESTS:Get(quest)
            local open = record and Core.Ask(C_QuestLog.GetQuestObjectives, quest)
            for _, objective in ipairs(type(open) == "table" and record.objectives or NONE) do
                local state = open[objective.index]
                if type(state) == "table" and not Core.Plain(state.finished) then
                    Want(found, quest, objective)
                    parts[#parts + 1] = quest .. "/" .. objective.index
                end
            end
        end
    end
    local line = table.concat(parts, " ")
    if line == said then return false end
    said, wanted = line, found
    return true
end

function Goals.Wanted()
    return wanted
end

function Goals.Spots(thing)
    local known = spots[thing]
    if known then return known end
    known = {}
    local creature = tonumber(thing:match("^npc:(%d+)$"))
    local points = SPAWNS:Get(thing, "points") or creature and CREATURES:Get(creature, "points")
    for _, point in pairs(type(points) == "table" and points or NONE) do
        if type(point) == "table" and point.map then
            known[point.map] = known[point.map] or {}
            local list = known[point.map]
            list[#list + 1] = point
        end
    end
    spots[thing] = known
    return known
end

function Goals.Stale()
    stale = true
end

function Goals.Forget()
    wipe(spots)
    wipe(givers)
    said, stale = nil, true
end
