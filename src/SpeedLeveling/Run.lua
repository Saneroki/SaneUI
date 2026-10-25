local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Run
--  Runs a guide read from text (Format.lua) for the character played (Saneroki,
--  2026-10-25: our own engine, needing no other addon): where in it you are,
--  which steps are at hand, and which of their lines are done, as the game tells
--  it (Lines.lua). Knows no frames; the view asks Guide.lua.
--
--  The steps at hand: the step you are at, and before it those that stay with
--  you a while: one that stays until it is done (#sticky), one that goes along
--  with the next step or up to a named one (#completewith). A step is done when
--  each of its things to do is done, or when one of its tests says it is not for
--  now (on a quest, money, an item count, a zone, a level); one with nothing to
--  do is done at once. You are moved on past each step done, and past one that
--  only goes along. A step you go back to (Back, Go) is held there until you go
--  on, or until something of it gets done.
--
--  What the game tells only as it happens (a hearth, a flight, a vendor's or
--  trainer's window, the spirit healer, a spell cast, a home bound) counts for
--  the steps at hand while it happens; a place counts once you are near it,
--  looked at every Run.LOOK seconds while a step at hand waits for one.
--
--  Kept per character (Core.Character): the guide run (its key), the step of
--  each guide, the steps you skipped.
--
--      Run.Use(guide)        run that guide (Format's), from where you were in it; nil: none
--      Run.Guide(), Run.At(), Run.Hand(), Run.Lines(index), Run.Listed(index)
--      Run.Skip(index), Run.Back(), Run.Go(index)
--      Run.Check()           the game changed: moved on as far as done steps go; true when anything moved
--      Run.Through()         the guide is at its end (on to the one it names next)
--      Run.Saw(what), Run.Watch(changed), Run.Stop()
--      Run.Way(place)        how far from a place, in yards, and which way; Run.Distance
--      Run.Target()          where the arrow points: the place line and its step
--      Run.ObjectiveKind(quest, goal), Run.Targets(), Run.Uses(), Run.UseOn(), Run.Quests(), Run.Words(line)
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
Run.GCD = 1.5           -- a cooldown this short is the global one

local Lines = ns.Lines
local EMPTY = {}

local guide   -- the guide run (Format's), or nil
local mine    -- this character's notes: { guide = key, at = { [key] = index }, skipped = { [key] = { [index] = true } } }
local at = 1
local held     -- the step gone back to, while it waits for the player
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
    local key = guide.key or guide.name
    local list = notes.skipped[key]
    if type(list) ~= "table" then
        list = {}
        notes.skipped[key] = list
    end
    return list
end

-------------------------------------------------------------------------------
--  Places (the geometry, kept apart: the game's world coordinates)
-------------------------------------------------------------------------------
local mapIds       -- [name, small letters] = uiMapID, the zones first; made once
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

-- How far the character is from a place, in yards, and which way it lies (radians from the north, turning to the
-- left as the game's facing does); nil where the game does not say (another continent, a dungeon).
function Run.Way(place)
    local north, west
    if place.continent then
        local position = rawget(_G, "UnitPosition")
        if not position then return nil end
        local ok, x, y, _, world = pcall(position, "player")
        x, y, world = Plain(x), Plain(y), Plain(world)
        if not ok or type(x) ~= "number" or type(y) ~= "number" or world ~= place.continent then return nil end
        -- The format writes a place in the world west first, then north; the game's own two numbers go north first.
        north, west = place.y - x, place.x - y
    else
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
        -- A map's x grows to the east, its y to the south.
        west, north = -(place.x / 100 - x) * size[1], -(place.y / 100 - y) * size[2]
    end
    return math.sqrt(north ^ 2 + west ^ 2), math.atan2(west, north)
end

function Run.Distance(place)
    return (Run.Way(place))
end

-------------------------------------------------------------------------------
--  Whether a line is done
-------------------------------------------------------------------------------
-- Each DOING word: done now, and for one with a count, how many there are and are wanted (index: the step, for what
-- the game told only as it happened).
local DONE = {
    take = function(line) return Lines.OnQuest(line.quest) or Lines.HandedIn(line.quest) end,
    handin = function(line) return Lines.HandedIn(line.quest) end,
    goal = function(line)
        if Lines.HandedIn(line.quest) or Lines.Ready(line.quest) then return true end
        local finished, have, need = Lines.Objective(line.quest, line.goal)
        return finished == true, have, need
    end,
    carry = function(line)
        local have = Lines.Count(line.item, true)
        if line.quest and (Lines.HandedIn(line.quest) or Lines.Ready(line.quest)) then return true, have, line.count end
        return have >= line.count, have, line.count
    end,
    destroy = function(line) return Lines.Count(line.item, true) == 0 end,
    level = function(line) return Lines.Reached(line.level, line.points, line.share) end,
    learn = function(line) return Lines.Known(line.spell) end,
    skill = function(line)
        local rank = Lines.Skill(line.skill)
        if rank < 0 then return false end
        if line.sign == "<" then return rank < line.level end
        if line.sign == ">" then return rank > line.level end
        return rank >= line.level
    end,
    bind = function(line, index)
        if seen[index] and seen[index].bind then return true end
        local home = line.to and Plain(Core.Ask(rawget(_G, "GetBindLocation")))
        return type(home) == "string" and home:lower() == line.to:lower()
    end,
    fly = function(_, index)
        return (seen[index] and seen[index].fly) or Core.Ask(rawget(_G, "UnitOnTaxi"), "player") == true
    end,
    zone = function(line) return Lines.InZone(line.to) end,
    area = function(line) return Lines.InArea(line.area) end,
    cast = function(line, index) return seen[index] and seen[index]["cast" .. line.spell] or false end,
    equip = function(line)
        local worn = Lines.Worn(line.slot)
        if not worn then return false end
        return not line.item or worn == line.item
    end,
    aura = function(line) return (Lines.Aura(line.spell)) ~= nil end,
    arrive = function(line)
        local distance = Run.Distance(line)
        return distance ~= nil and distance <= (line.near or ns.Format.FAR)
    end,
    manual = function() return false end,
}
-- Those the game tells only as they happen.
for _, what in ipairs({ "hearth", "flightpath", "revive", "shop", "trainer", "stable", "tame" }) do
    DONE[what] = function(_, index) return seen[index] and seen[index][what] or false end
end

local function Done(line, index)
    local check = DONE[line.what]
    if not check then return true end
    local done, have, need = check(line, index)
    return done and true or false, have, need
end

-------------------------------------------------------------------------------
--  Whether a test passes the step by
-------------------------------------------------------------------------------
local function AnyOnQuest(quests)
    for _, quest in ipairs(quests) do if Lines.OnQuest(quest) then return true end end
    return false
end
local function AnyReady(quests)
    for _, quest in ipairs(quests) do if Lines.Ready(quest) then return true end end
    return false
end
local function AnyHandedIn(quests)
    for _, quest in ipairs(quests) do if Lines.HandedIn(quest) then return true end end
    return false
end

local function Grouped()
    local size = Plain(Core.Ask(rawget(_G, "GetNumGroupMembers")))
    return type(size) == "number" and size > 1
end

local TESTS = {
    onQuest = function(test) return not AnyOnQuest(test.quests) end,
    notOnQuest = function(test) return AnyOnQuest(test.quests) end,
    questReady = function(test) return not AnyReady(test.quests) end,
    questOpen = function(test) return AnyReady(test.quests) end,
    handedIn = function(test) return not AnyHandedIn(test.quests) end,
    open = function(test)
        for _, quest in ipairs(test.quests) do if not Lines.HandedIn(quest) then return false end end
        return true
    end,
    money = function(test)
        local enough = Lines.Money() >= test.copper
        return test.more and enough or (not test.more and not enough)
    end,
    count = function(test)
        local have = 0
        for _, item in ipairs(test.items) do have = have + Lines.Count(item, true) end
        local met
        if test.sign == "<" then met = have < test.total
        elseif test.sign == ">" then met = have > test.total
        elseif test.sign == "<=" then met = have <= test.total
        elseif test.sign == ">=" then met = have >= test.total
        elseif test.sign and test.sign:find("=") then met = have == test.total
        else met = have >= test.total end
        return not met
    end,
    inZone = function(test)
        local inside = false
        for _, map in ipairs(test.maps) do if Lines.InZone(map) then inside = true end end
        return inside ~= test.away
    end,
    inArea = function(test)
        local inside = false
        for _, area in ipairs(test.areas) do if Lines.InArea(area) then inside = true end end
        return inside ~= test.away
    end,
    reached = function(test) return Lines.Reached(test.level, test.points, test.share) end,
    grouped = function() return not Grouped() end,
    solo = function() return Grouped() end,
    maxLevel = function(test)
        local level = Plain(Core.Ask(UnitLevel, "player")) or 0
        return level > test.level
    end,
    ready = function(test)
        local left = Lines.Cooldown(test.kind, test.id)
        if left == nil then return false end
        left = math.max(0, left - Run.GCD) -- the global cooldown does not count
        return test.under and left < test.left or (not test.under and left > test.left)
    end,
    atHome = function(test)
        local home = Plain(Core.Ask(rawget(_G, "GetBindLocation")))
        local name = test.area and Lines.AreaName(test.area)
        return type(home) == "string" and type(name) == "string" and home:lower() == name:lower()
    end,
    worn = function(test)
        local worn = Lines.Worn(test.slot)
        local on = worn ~= nil and (not test.item or worn == test.item)
        return on ~= (test.below == true)
    end,
    hasAura = function(test)
        local has = (Lines.Aura(test.spell)) ~= nil
        return has ~= (test.below == true)
    end,
    hasSpell = function(test) return Lines.Known(test.spell) end,
    hasSkill = function(test)
        local rank = Lines.Skill(test.skill)
        if rank < 0 then return false end
        if test.sign == "<" then return rank < test.level end
        if test.sign == ">" then return rank > test.level end
        return rank >= test.level
    end,
    stat = function() return false end, -- gear stats: left to the player (never passes the step by on its own)
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
    Notes().at[guide.key or guide.name] = at
end

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

function Run.Through()
    return guide ~= nil and at > #guide.steps
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

-- Whether a step is one the list shows (not a step that only goes along, nor a hidden one).
function Run.Listed(index)
    local step = guide and guide.steps[index]
    return step ~= nil and not step.aside and not step.hidden
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

function Run.Go(index)
    if not guide then return end
    at = math.max(1, math.min(index, #guide.steps))
    Skipped()[at] = nil
    held, heldDone = at, Finished(at)
    Keep()
end

function Run.Back()
    if not guide then return end
    local index = at - 1
    while index > 1 and (guide.steps[index].together or guide.steps[index].stays) do index = index - 1 end
    if index >= 1 then Run.Go(index) end
end

function Run.Saw(what)
    if not guide then return end
    for _, index in ipairs(Run.Hand()) do
        seen[index] = seen[index] or {}
        seen[index][what] = true
    end
end

-- Where the arrow points: the first place not yet passed of the steps at hand, the step you are at first; a point on
-- the way, or a place to get to, is passed once you were within its reach. The place line and its step; nil for none.
function Run.Target()
    if not guide then return nil end
    local order = {}
    if guide.steps[at] then order[1] = at end
    for _, index in ipairs(Run.Hand()) do
        if index ~= at then order[#order + 1] = index end
    end
    for _, index in ipairs(order) do
        for number, line in ipairs(guide.steps[index].lines) do
            local key = "place" .. number
            if (line.what == "place" or line.what == "arrive") and not (seen[index] and seen[index][key]) then
                local passable = line.way or line.what == "arrive"
                local distance = passable and Run.Distance(line)
                if distance and distance <= (line.near and line.near > 0 and line.near or ns.Format.FAR) then
                    seen[index] = seen[index] or {}
                    seen[index][key] = true
                else
                    return line, index
                end
            end
        end
    end
    return nil
end

local function Waiting()
    for _, index in ipairs(Run.Hand()) do
        for _, line in ipairs(guide.steps[index].lines) do
            if line.what == "arrive" and not Done(line, index) then return true end
        end
    end
    return false
end

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
    notes.guide = guide.key or guide.name
    local kept = tonumber(notes.at[guide.key or guide.name])
    at = kept and math.max(1, math.min(kept, #guide.steps + 1)) or 1
    MoveOn()
end

-------------------------------------------------------------------------------
--  For the key, the quest givers and the view
-------------------------------------------------------------------------------
function Run.ObjectiveKind(quest, goal)
    return (select(5, Lines.Objective(quest, goal)))
end

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
        -- A step with a revive line wants the Spirit Healer, while you are dead.
        for _, line in ipairs(step.lines) do
            if line.what == "revive" and Lines.Dead() and not Done(line, index) then Add(friends, { "Spirit Healer" }) end
        end
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

-- The items the steps at hand name to use, each with its line's words (what it is used on): { { item, words } }.
function Run.UseOn()
    local uses = {}
    if not guide then return uses end
    for _, index in ipairs(Run.Hand()) do
        for _, use in ipairs(guide.steps[index].uses or EMPTY) do uses[#uses + 1] = use end
    end
    return uses
end

-- What the steps at hand take and hand in, and the talk options they name, for the quest givers (Quests.lua).
function Run.Quests()
    local want = { take = {}, handin = {}, gossip = {} }
    if not guide then return want end
    -- The steps at hand, and the step after the last of them (a quest giver often offers the next step's quests too).
    local indexes = {}
    local last = at
    for _, index in ipairs(Run.Hand()) do
        indexes[#indexes + 1] = index
        last = math.max(last, index)
    end
    if guide.steps[last + 1] then indexes[#indexes + 1] = last + 1 end
    for _, index in ipairs(indexes) do
        local step = guide.steps[index]
        if step then
            for _, line in ipairs(step.lines) do
                if line.what == "take" and not Lines.HandedIn(line.quest) then
                    want.take[line.quest] = true
                elseif line.what == "handin" then
                    want.handin[line.quest] = line.reward or true
                end
            end
        end
    end
    return want
end

-------------------------------------------------------------------------------
--  Our words for a line the guide gives none
-------------------------------------------------------------------------------
local WORDS = {
    take = function(line) return ns.TEXT.acceptQuest:format(Lines.QuestName(line.quest)) end,
    handin = function(line) return ns.TEXT.handinQuest:format(Lines.QuestName(line.quest)) end,
    goal = function(line)
        local _, _, _, text = Lines.Objective(line.quest, line.goal)
        return type(text) == "string" and text ~= "" and (text:gsub(":%s*%d+%s*/%s*%d+$", "")) or Lines.QuestName(line.quest)
    end,
    carry = function(line) return Lines.ItemName(line.item) end,
    destroy = function(line) return ns.TEXT.destroy:format(Lines.ItemName(line.item)) end,
    level = function(line)
        if line.points and line.points < 0 then return ns.TEXT.levelShort:format(-line.points, line.level) end
        if line.points then return ns.TEXT.levelInto:format(line.points, line.level) end
        if line.share then return ns.TEXT.levelShare:format(math.floor(line.share * 100 + 0.5), line.level) end
        return ns.TEXT.level:format(line.level)
    end,
    learn = function(line) return ns.TEXT.learn:format(Lines.SpellName(line.spell)) end,
    skill = function(line) return ns.TEXT.skill:format(line.level, line.skill) end,
    hearth = function(line) return line.to and ns.TEXT.hearthTo:format(line.to) or ns.TEXT.hearthNow end,
    bind = function(line) return line.to and ns.TEXT.bindTo:format(line.to) or ns.TEXT.bindHere end,
    flightpath = function(line) return line.to and ns.TEXT.flightpathAt:format(line.to) or ns.TEXT.flightpath end,
    fly = function(line) return line.to and ns.TEXT.flyTo:format(line.to) or ns.TEXT.fly end,
    zone = function(line) return ns.TEXT.goTo:format(tostring(line.to)) end,
    area = function(line) return ns.TEXT.goTo:format(Lines.AreaName(line.area) or tostring(line.area)) end,
    revive = function() return ns.TEXT.revive end,
    cast = function(line) return ns.TEXT.cast:format(Lines.SpellName(line.spell)) end,
    shop = function() return ns.TEXT.shop end,
    trainer = function() return ns.TEXT.trainer end,
    stable = function() return ns.TEXT.stable end,
    arrive = function() return ns.TEXT.arrive end,
}

function Run.Words(line)
    if line.words then return line.words end
    local words = WORDS[line.what]
    return words and words(line) or nil
end
