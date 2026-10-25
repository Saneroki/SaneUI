local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Run
--  Runs a guide read from text (Format.lua) for the character played: where in
--  it you are, which steps are at hand, and which of their lines are done, as
--  the game tells it. Knows no frames; the view asks Guide.lua.
--
--  The steps at hand: the step you are at, and before it those that stay with
--  you a while: one that stays until it is done (#sticky), one that goes along
--  with the next step or up to a named one (#completewith). A step is done when
--  each of its things to do is done, or when one of its tests says it is not
--  for now (on a quest, money, an item count, a zone, a level); one with nothing
--  to do is done at once. You are moved on past each step done, and past one
--  that only goes along (it stays at hand). A step you go back to (Back, Go) is
--  held there until you go on, or until something of it gets done.
--
--  What the game tells only as it happens (a hearth, a flight, a vendor's or
--  trainer's window, the spirit healer, a spell cast, a home bound) counts for
--  the steps at hand while it happens; a place counts once you are near it,
--  looked at every Run.LOOK seconds while a step at hand waits for one.
--
--  Kept per character (Core.Character): the guide run (its name), the step of
--  each guide, the steps you skipped.
--
--      Run.Use(guide)        run that guide (Format's), from where you were in it; nil: none
--      Run.Guide()           the guide run, or nil
--      Run.At()              the step you are at (one past the last: the guide is through)
--      Run.Hand()            the steps at hand, in order: { index }
--      Run.Lines(index)      that step's lines as they stand: { { line, done, have, need } }
--      Run.Skip(index), Run.Back(), Run.Go(index)
--      Run.Check()           the game changed: moved on as far as done steps go; true when anything moved
--      Run.Saw(what)         a thing the game tells only as it happens, for the steps at hand
--      Run.Watch(changed)    the place looked at while a step waits for one (changed() after a move); Run.Stop()
--      Run.Distance(place)   how far the character is from a place, in yards
--      Run.Targets()         the names the steps at hand want found: foes, friends
--      Run.Uses()            the items and spells they want used
--      Run.Words(line)       a line's words: the guide's own, or ours made from the game's names
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Run = {}
ns.Run = Run

Run.LOOK = 1         -- seconds between looks at the player's place while a place is waited for
Run.BEHIND = 60      -- how many steps back the ones that stay at hand are looked for
Run.HEARTHSTONE = 6948
Run.HEARTH_SPELL = 8690 -- what the Hearthstone casts
Run.RECALL = 556        -- the shaman's Astral Recall

local QUESTS = Core.Data.Set("Quests")
local EMPTY = {}

local guide   -- the guide run (Format's), or nil
local mine    -- this character's notes: { guide = name, at = { [name] = index }, skipped = { [name] = { [index] = true } } }
local at = 1
local held    -- the step gone back to, while it waits for the player
local heldDone -- whether it was done when it was gone back to
local seen = {} -- [step index] = { [what] = true }: what happened while it was at hand
local ticker

local function Notes()
    if not mine then
        mine = Core.Character(ns.name)
        if type(mine.at) ~= "table" then mine.at = {} end
        if type(mine.skipped) ~= "table" then mine.skipped = {} end
    end
    return mine
end

local function Skipped()
    local notes = Notes()
    local list = notes.skipped[guide.name]
    if type(list) ~= "table" then
        list = {}
        notes.skipped[guide.name] = list
    end
    return list
end

-------------------------------------------------------------------------------
--  What the game says
-------------------------------------------------------------------------------
local function Log() return rawget(_G, "C_QuestLog") or EMPTY end

local function HandedIn(quest)
    local log = Log()
    local done = Core.Ask(log.IsQuestFlaggedCompleted or rawget(_G, "IsQuestFlaggedCompleted"), quest)
    return done == true
end

local function OnQuest(quest)
    local log = Log()
    if log.IsOnQuest then return Core.Ask(log.IsOnQuest, quest) == true end
    local index = Core.Ask(log.GetLogIndexForQuestID or rawget(_G, "GetQuestLogIndexByID"), quest)
    return type(index) == "number" and index > 0
end

local function Ready(quest)
    return OnQuest(quest) and Core.Ask(Log().IsComplete, quest) == true
end

-- A quest's objective as the game has it: done, how many there are, how many are wanted.
local function Objective(quest, goal)
    local objectives = Core.Ask(Log().GetQuestObjectives, quest)
    local objective = type(objectives) == "table" and objectives[goal]
    if type(objective) ~= "table" then return nil end
    return Plain(objective.finished) == true, Plain(objective.numFulfilled), Plain(objective.numRequired), Plain(objective.text)
end

local function Count(item)
    local items = rawget(_G, "C_Item")
    return Core.Ask(items and items.GetItemCount or rawget(_G, "GetItemCount"), item) or 0
end

local function Known(spell)
    return Core.Ask(rawget(_G, "IsPlayerSpell"), spell) == true or Core.Ask(rawget(_G, "IsSpellKnown"), spell) == true
end

-- Whether the character is at a level ("10", so many points short of it, so many or a share into it).
local function Reached(line)
    local level = Plain(UnitLevel("player")) or 0
    local points, most = Plain(UnitXP("player")) or 0, Plain(UnitXPMax("player")) or 1
    local reached
    if line.points and line.points < 0 then
        reached = level >= line.level or (level == line.level - 1 and most - points <= -line.points)
    elseif line.points then
        reached = level > line.level or (level == line.level and points >= line.points)
    elseif line.share then
        reached = level > line.level or (level == line.level and most > 0 and points / most >= line.share)
    else
        reached = level >= line.level
    end
    if line.below then return not reached end
    return reached
end

local function Money() return Plain(Core.Ask(rawget(_G, "GetMoney"))) or 0 end

-- The zone's name, the map the character is on, the subzone's name.
local function Where()
    local maps = rawget(_G, "C_Map")
    local map = maps and Plain(Core.Ask(maps.GetBestMapForUnit, "player"))
    return Plain(Core.Ask(rawget(_G, "GetRealZoneText"))) or Plain(Core.Ask(rawget(_G, "GetZoneText"))), map,
           Plain(Core.Ask(rawget(_G, "GetSubZoneText")))
end

local function InZone(to)
    local zone, map = Where()
    if type(to) == "number" then return to == map end
    return type(zone) == "string" and zone:lower() == tostring(to):lower()
end

local function AreaName(area)
    local maps = rawget(_G, "C_Map")
    return maps and Plain(Core.Ask(maps.GetAreaInfo, area)) or nil
end

local function InArea(area)
    local _, _, subzone = Where()
    local name = AreaName(area)
    return type(name) == "string" and name == subzone
end

-------------------------------------------------------------------------------
--  Places
-------------------------------------------------------------------------------
local mapIds      -- [name, small letters] = uiMapID, the zones first; made once
local mapSizes = {} -- [uiMapID] = { width, height } in yards, or false

local function MapId(map)
    if type(map) == "number" then return map end
    local maps = rawget(_G, "C_Map")
    if not mapIds and maps then
        mapIds = {}
        local root = Core.Ask(maps.GetFallbackWorldMapID) or 947
        local children = Core.Ask(maps.GetMapChildrenInfo, root, nil, true)
        local zone = rawget(_G, "Enum") and Enum.UIMapType and Enum.UIMapType.Zone or 3
        for pass = 1, 2 do
            for _, info in ipairs(type(children) == "table" and children or EMPTY) do
                local name = type(info.name) == "string" and info.name:lower()
                if name and not mapIds[name] and ((pass == 1) == (info.mapType == zone)) then mapIds[name] = info.mapID end
            end
        end
    end
    return mapIds and mapIds[tostring(map):lower()] or nil
end

-- A map's width and height in yards, from the game's world places of three of its corners.
local function Size(map)
    if mapSizes[map] ~= nil then return mapSizes[map] end
    local maps, vector = rawget(_G, "C_Map"), rawget(_G, "CreateVector2D")
    local size = false
    if maps and maps.GetWorldPosFromMapPos and vector then
        local function World(x, y)
            local continent, point = Core.Ask(maps.GetWorldPosFromMapPos, map, vector(x, y))
            if type(point) ~= "table" then return nil end
            return continent, Plain(point.x), Plain(point.y)
        end
        local c0, a0, b0 = World(0, 0)
        local c1, a1, b1 = World(1, 0)
        local c2, a2, b2 = World(0, 1)
        if a0 and a1 and a2 and b0 and b1 and b2 and c0 == c1 and c0 == c2 then
            size = { math.sqrt((a1 - a0) ^ 2 + (b1 - b0) ^ 2), math.sqrt((a2 - a0) ^ 2 + (b2 - b0) ^ 2) }
        end
    end
    mapSizes[map] = size
    return size
end

-- How far the character is from a place, in yards; nil where the game does not say (another continent, a dungeon).
function Run.Distance(place)
    if place.continent then
        local position = rawget(_G, "UnitPosition")
        if not position then return nil end
        local ok, north, west, _, world = pcall(position, "player")
        if not ok then return nil end
        north, west, world = Plain(north), Plain(west), Plain(world)
        if type(north) ~= "number" or type(west) ~= "number" or world ~= place.continent then return nil end
        -- The format writes a place in the world west first, then north.
        return math.sqrt((west - place.x) ^ 2 + (north - place.y) ^ 2)
    end
    local map = MapId(place.map)
    local maps = rawget(_G, "C_Map")
    if not (map and maps) then return nil end
    local point = Core.Ask(maps.GetPlayerMapPosition, map, "player")
    local size = Size(map)
    if type(point) ~= "table" or not size then return nil end
    local x, y = point.x, point.y
    if point.GetXY then x, y = point:GetXY() end
    x, y = Plain(x), Plain(y)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    return math.sqrt(((x - place.x / 100) * size[1]) ^ 2 + ((y - place.y / 100) * size[2]) ^ 2)
end

-------------------------------------------------------------------------------
--  Lines and steps
-------------------------------------------------------------------------------
-- Whether a line is done now, and for one with a count, how many there are and are wanted.
local CHECKS = {
    take = function(line) return OnQuest(line.quest) or HandedIn(line.quest) end,
    handin = function(line) return HandedIn(line.quest) end,
    goal = function(line)
        if HandedIn(line.quest) or Ready(line.quest) then return true end
        local finished, have, need = Objective(line.quest, line.goal)
        return finished == true, have, need
    end,
    carry = function(line)
        local have = Count(line.item)
        if line.quest and (HandedIn(line.quest) or Ready(line.quest)) then return true, have, line.count end
        return have >= line.count, have, line.count
    end,
    level = function(line) return Reached(line) end,
    learn = function(line) return Known(line.spell) end,
    bind = function(line, index)
        if seen[index] and seen[index].bind then return true end
        local home = line.to and Plain(Core.Ask(rawget(_G, "GetBindLocation")))
        return type(home) == "string" and home:lower() == line.to:lower()
    end,
    fly = function(_, index)
        return (seen[index] and seen[index].fly) or Core.Ask(rawget(_G, "UnitOnTaxi"), "player") == true
    end,
    zone = function(line) return InZone(line.to) end,
    area = function(line) return InArea(line.area) end,
    cast = function(line, index) return seen[index] and seen[index]["cast" .. line.spell] or false end,
    arrive = function(line)
        local distance = Run.Distance(line)
        return distance ~= nil and distance <= (line.near or ns.Format.FAR)
    end,
    manual = function() return false end,
}
-- Those the game tells only as they happen.
for _, what in ipairs({ "hearth", "flightpath", "revive", "shop", "trainer" }) do
    CHECKS[what] = function(_, index) return seen[index] and seen[index][what] or false end
end

local function Done(line, index)
    local check = CHECKS[line.what]
    if not check then return true end
    local done, have, need = check(line, index)
    return done and true or false, have, need
end

-- Whether a test says the step is not for now.
local TESTS = {
    onQuest = function(test)
        for _, quest in ipairs(test.quests) do if OnQuest(quest) then return false end end
        return true
    end,
    questReady = function(test)
        for _, quest in ipairs(test.quests) do if Ready(quest) then return false end end
        return true
    end,
    handedIn = function(test)
        for _, quest in ipairs(test.quests) do if HandedIn(quest) then return false end end
        return true
    end,
    open = function(test)
        for _, quest in ipairs(test.quests) do
            if not OnQuest(quest) and not HandedIn(quest) then return false end
        end
        return true
    end,
    money = function(test)
        local enough = Money() >= test.copper
        if test.more then return enough end
        return not enough
    end,
    count = function(test)
        local have = 0
        for _, item in ipairs(test.items) do have = have + Count(item) end
        local holds
        if test.sign == "<" then holds = have < test.total
        elseif test.sign == ">" then holds = have > test.total
        elseif test.sign:find("=") and #test.sign == 1 then holds = have == test.total
        elseif test.sign == "<=" then holds = have <= test.total
        elseif test.sign == ">=" then holds = have >= test.total
        else holds = have >= test.total end
        return not holds
    end,
    inZone = function(test)
        local inside = false
        for _, map in ipairs(test.maps) do if InZone(map) then inside = true end end
        return inside ~= test.away
    end,
    inArea = function(test)
        local inside = false
        for _, area in ipairs(test.areas) do if InArea(area) then inside = true end end
        return inside ~= test.away
    end,
    reached = function(test) return Reached(test) end,
}

-- Whether a step is passed by: skipped, one its tests rule out, or one that needs a step the player skipped.
local function Passed(index)
    local step = guide.steps[index]
    local skipped = Skipped()
    if skipped[index] then return true end
    if step.needs and guide.labels[step.needs] and skipped[guide.labels[step.needs]] then return true end
    for _, test in ipairs(step.unless or EMPTY) do
        if TESTS[test.what] and TESTS[test.what](test) then return true end
    end
    return false
end

-- Whether each thing to do of a step is done (a step with none: yes).
local function AllDone(index)
    for _, line in ipairs(guide.steps[index].lines) do
        if ns.Format.DOING[line.what] and not Done(line, index) then return false end
    end
    return true
end

local function Finished(index) return Passed(index) or AllDone(index) end

-- Whether an earlier step is still at hand with the one you are at.
local function Along(index)
    local step = guide.steps[index]
    if step.stays then return not Finished(index) end
    if not step.together then return false end
    local last = step.together == "next" and index + 1 or guide.labels[step.together]
    return last ~= nil and at <= last and not Finished(index)
end

-------------------------------------------------------------------------------
--  Moving through the guide
-------------------------------------------------------------------------------
local function Keep()
    Notes().at[guide.name] = at
end

-- On past each step done and each that only goes along; the step held stays until something of it gets done.
local function MoveOn()
    local from = at
    while at <= #guide.steps do
        local step = guide.steps[at]
        local finished = Finished(at)
        if at == held then
            if finished and heldDone then break end
            held = nil
        end
        if not (finished or step.together or step.stays) then break end
        at = at + 1
    end
    if at ~= from then Keep() end
    return at ~= from
end

function Run.Check()
    if not guide then return false end
    return MoveOn()
end

function Run.Guide() return guide end
function Run.At() return at end

function Run.Hand()
    local hand = {}
    if not guide then return hand end
    for index = math.max(1, at - Run.BEHIND), at - 1 do
        if Along(index) then hand[#hand + 1] = index end
    end
    if guide.steps[at] then hand[#hand + 1] = at end
    return hand
end

function Run.Lines(index)
    local lines = {}
    local step = guide and guide.steps[index]
    for _, line in ipairs(step and step.lines or EMPTY) do
        local done, have, need = Done(line, index)
        lines[#lines + 1] = { line = line, done = done, have = have, need = need }
    end
    return lines
end

-- The player skips a step at hand: it counts as done; the one you are at, you go on past it.
function Run.Skip(index)
    if not (guide and guide.steps[index]) then return end
    Skipped()[index] = true
    if index == at then
        held = nil
        at = at + 1
        MoveOn()
        Keep()
    end
end

-- To a step, and held there.
function Run.Go(index)
    if not guide then return end
    at = math.max(1, math.min(index, #guide.steps))
    Skipped()[at] = nil
    held, heldDone = at, Finished(at)
    Keep()
end

-- Back to the step before, past those that only go along.
function Run.Back()
    if not guide then return end
    local index = at - 1
    while index > 1 and (guide.steps[index].together or guide.steps[index].stays) do index = index - 1 end
    if index >= 1 then Run.Go(index) end
end

-- Things the game tells only as they happen, for the steps at hand.
function Run.Saw(what)
    if not guide then return end
    for _, index in ipairs(Run.Hand()) do
        seen[index] = seen[index] or {}
        seen[index][what] = true
    end
end

-- Whether a step at hand waits for a place.
local function Waiting()
    for _, index in ipairs(Run.Hand()) do
        for _, line in ipairs(guide.steps[index].lines) do
            if line.what == "arrive" and not Done(line, index) then return true end
        end
    end
    return false
end

-- The place is looked at while a step waits for one; the look stops by itself when none does.
function Run.Watch(changed)
    local waiting = guide ~= nil and Waiting()
    if waiting and not ticker then
        ticker = C_Timer.NewTicker(Run.LOOK, ns.Guard(function()
            if not guide or not Waiting() then
                ticker:Cancel()
                ticker = nil
            end
            if Run.Check() then changed() end
        end))
    elseif not waiting and ticker then
        ticker:Cancel()
        ticker = nil
    end
end

-- No more looks at the place (standing down).
function Run.Stop()
    if ticker then ticker:Cancel() end
    ticker = nil
end

function Run.Use(read)
    guide, held, at = read, nil, 1
    wipe(seen)
    if not guide then
        Notes().guide = nil
        return
    end
    local notes = Notes()
    notes.guide = guide.name
    local kept = tonumber(notes.at[guide.name])
    at = kept and math.max(1, math.min(kept, #guide.steps + 1)) or 1
    MoveOn()
end

-------------------------------------------------------------------------------
--  For the key and the view
-------------------------------------------------------------------------------
function Run.Targets()
    local foes, friends, have = {}, {}, {}
    local function Add(list, names)
        for _, name in ipairs(names or EMPTY) do
            if not have[name] then
                have[name] = true
                list[#list + 1] = name
            end
        end
    end
    for _, index in ipairs(Run.Hand()) do
        local step = guide.steps[index]
        Add(friends, step.friends)
        Add(foes, step.foes)
    end
    return foes, friends
end

function Run.Uses()
    local items, spells = {}, {}
    for _, index in ipairs(Run.Hand()) do
        local step = guide.steps[index]
        for _, item in ipairs(step.items or EMPTY) do items[#items + 1] = item end
        for _, line in ipairs(step.lines) do
            if line.what == "hearth" and not Done(line, index) then
                items[#items + 1] = Run.HEARTHSTONE
                spells[#spells + 1] = Run.RECALL
            end
        end
    end
    return items, spells
end

local function Title(quest)
    local name = QUESTS:Get(quest, "name")
    if type(name) ~= "string" then name = Plain(Core.Ask(Log().GetTitleForQuestID, quest)) end
    return type(name) == "string" and name or ns.TEXT.quest:format(quest)
end

local function ItemName(item)
    local items = rawget(_G, "C_Item")
    local name = Plain(Core.Ask(items and items.GetItemNameByID or rawget(_G, "GetItemInfo"), item))
    return type(name) == "string" and name or ns.TEXT.item:format(item)
end

local function SpellName(spell)
    local spells = rawget(_G, "C_Spell")
    local name = Plain(Core.Ask(spells and spells.GetSpellName or rawget(_G, "GetSpellInfo"), spell))
    return type(name) == "string" and name or ns.TEXT.spell:format(spell)
end

-- Our words for a line the guide gives none.
local WORDS = {
    take = function(line) return ns.TEXT.take:format(Title(line.quest)) end,
    handin = function(line) return ns.TEXT.handin:format(Title(line.quest)) end,
    goal = function(line)
        local _, _, _, text = Objective(line.quest, line.goal)
        return type(text) == "string" and text ~= "" and text:gsub(":%s*%d+%s*/%s*%d+$", "") or Title(line.quest)
    end,
    carry = function(line) return ItemName(line.item) end,
    level = function(line) return ns.TEXT.level:format(line.level) end,
    learn = function(line) return ns.TEXT.learn:format(SpellName(line.spell)) end,
    hearth = function(line) return line.to and ns.TEXT.hearthTo:format(line.to) or ns.TEXT.hearthNow end,
    bind = function(line) return line.to and ns.TEXT.bindTo:format(line.to) or ns.TEXT.bindHere end,
    flightpath = function(line) return line.to and ns.TEXT.flightpathAt:format(line.to) or ns.TEXT.flightpath end,
    fly = function(line) return line.to and ns.TEXT.flyTo:format(line.to) or ns.TEXT.fly end,
    zone = function(line) return ns.TEXT.goTo:format(tostring(line.to)) end,
    area = function(line) return ns.TEXT.goTo:format(AreaName(line.area) or tostring(line.area)) end,
    revive = function() return ns.TEXT.revive end,
    cast = function(line) return ns.TEXT.cast:format(SpellName(line.spell)) end,
    shop = function() return ns.TEXT.shop end,
    trainer = function() return ns.TEXT.trainer end,
    arrive = function() return ns.TEXT.arrive end,
}

function Run.Words(line)
    if line.words then return line.words end
    local words = WORDS[line.what]
    return words and words(line) or nil
end
