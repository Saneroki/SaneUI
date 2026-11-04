local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Class quests
--  Your class's quest chains over your guide (Saneroki, 2026-10-31): Bear Form
--  at 10, Aquatic Form at 16, a warlock's pets, a shaman's totems, each race's
--  own way to them. The guide knows who plays: when your level reaches a chain
--  for your class, race and side (Core's set ClassQuests), its next step stands
--  on top of the steps at hand, and the arrow, the map pin and the key go by it
--  (Run.Hand, Run.Target) until it is done; your guide goes on under it.
--
--  One step at a time, made as it comes up from what Core's sets hold on the
--  quest (Quests, Spawns) and what the game says: to its giver, what it asks, to
--  whoever takes it, on to the next quest. It stands at ClassQuests.STEP, a number
--  outside the guide's own, so the guide's steps, and your place in them, stay the
--  same with and without it. How far a chain is, the game tells: a quest in your
--  log or handed in, and the quests before it lie behind you.
--
--  What your guide does itself stays your guide's: a quest it hands in shows
--  nothing here, a quest it takes shows from there on. So does what a guide
--  further on your way does (Guide.Later; Saneroki, 2026-11-04): a quest taken
--  now and finished levels later waits for that guide, off your way no sooner.
--  A chain it leaves open meanwhile waits, and the next one that is due comes up.
--
--  A click on the step leaves the chain for this character: its quests are yours
--  to take or not, and if you take one, it comes back. ClassQuests.Back() brings back
--  every chain you left. Without Core's data (Retail, for now) there are no chains.
--
--      ClassQuests.Use(guide)    the chains of this character, for a guide just taken up
--      ClassQuests.Check()       the step anew, as the game says now: true when it changed
--      ClassQuests.Hand()        the step that is due: { ClassQuests.STEP } or nothing
--      ClassQuests.Leave()       leaves the chain of the step that is due
--      ClassQuests.Left(), ClassQuests.Back()   how many chains were left; all brought back
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local ClassQuests = {}
ns.ClassQuests = ClassQuests

ClassQuests.STEP = -1 -- where the step stands in guide.steps: outside the guide's own numbers

local Lines = ns.Lines
local CHAINS, QUESTS, SPAWNS, OBJECTS, DROPS = Core.Data.Set("ClassQuests"), Core.Data.Set("Quests"),
    Core.Data.Set("Spawns"), Core.Data.Set("Objects"), Core.Data.Set("Drops")
local EMPTY = {}
local TAKE, WORK, HANDIN = "take", "work", "handin" -- how far a quest is

local guide     -- the guide run
local chains    -- this character's, the lowest level first: { key, name, level, quests, also }
local asked     -- what the guide does itself: { take = { [quest] = true }, handin = { [quest] = true } }
local later     -- what the guides after it do, the same way
local due       -- the step that is due: its chain, quest and stage; nil for none

local function Notes()
    local notes = Core.Character(ns.name)
    if type(notes.classLeft) ~= "table" then notes.classLeft = {} end
    return notes.classLeft
end

local function Side()
    local side = Plain(Core.Ask(rawget(_G, "UnitFactionGroup"), "player"))
    return type(side) == "string" and side:lower() or nil
end

local function Has(list, value)
    for _, each in ipairs(list or EMPTY) do
        if each == value then return true end
    end
    return false
end

-------------------------------------------------------------------------------
--  Who plays
-------------------------------------------------------------------------------
-- The chains for this character, the lowest level first.
local function Mine()
    local _, _, class = Core.Ask(rawget(_G, "UnitClass"), "player")
    local _, _, race = Core.Ask(rawget(_G, "UnitRace"), "player")
    local side = Side()
    local list = {}
    for _, key in ipairs(CHAINS:Keys("byClass", Plain(class)) or EMPTY) do
        local chain = CHAINS:Get(key)
        if chain and (not chain.side or chain.side == side) and (not chain.races or Has(chain.races, Plain(race))) then
            list[#list + 1] = { key = key, name = chain.name, level = chain.level, quests = chain.quests, also = chain.also }
        end
    end
    table.sort(list, function(a, b)
        if a.level ~= b.level then return a.level < b.level end
        return a.key < b.key
    end)
    return list
end

-- What the guide takes and hands in itself.
local function Asked(steps)
    local mine = { take = {}, handin = {} }
    for _, step in ipairs(steps) do
        for _, line in ipairs(step.lines) do
            if line.quest and (line.what == "take" or line.what == "handin") then mine[line.what][line.quest] = true end
        end
    end
    return mine
end

function ClassQuests.Use(read)
    guide, due = read, nil
    if guide then guide.steps[ClassQuests.STEP] = nil end
    chains = guide and Mine() or nil
    asked = guide and Asked(guide.steps) or nil
    later = guide and ns.Guide and ns.Guide.Later and ns.Guide.Later(guide) or { take = {}, handin = {} }
end

-------------------------------------------------------------------------------
--  How far a chain is
-------------------------------------------------------------------------------
-- Whether a quest in your log is ready to hand in: done, or one with no objectives, that asks only to go to whoever
-- takes it.
local function Ready(quest)
    return Lines.Ready(quest) or Lines.Objectives(quest) == 0
end

-- A chain's quest by its number: the first as you came to it, from whichever NPC gave it.
local function QuestOf(chain, number)
    if number == 1 then
        for _, quest in ipairs(chain.also or EMPTY) do
            if Lines.OnQuest(quest) or Lines.HandedIn(quest) then return quest end
        end
    end
    return chain.quests[number]
end

-- Where a chain stands: the number of its quest that is next and how far that one is; nil: it is through. The last
-- quest you came to says: those before it lie behind you.
local function Stage(chain)
    for number = #chain.quests, 1, -1 do
        local quest = QuestOf(chain, number)
        if Lines.HandedIn(quest) then
            if number == #chain.quests then return nil end
            return number + 1, TAKE
        elseif Lines.OnQuest(quest) then
            return number, Ready(quest) and HANDIN or WORK
        end
    end
    return 1, TAKE
end

-- Whether a quest of a chain, this far, is the guide's to lead: a quest it or a guide after it hands in, or one they
-- take that is still to take.
local function Guides(quest, stage)
    return asked.handin[quest] or later.handin[quest] or (stage == TAKE and (asked.take[quest] or later.take[quest]))
end

-- Whether your level lets the chain go on with that quest.
local function Allowed(chain, quest)
    local level = Plain(Core.Ask(rawget(_G, "UnitLevel"), "player")) or 1
    return level >= chain.level and level >= (QUESTS:Get(quest, "minLevel") or 0)
end

-- Whether you left a chain: it stays left unless you took one of its quests yourself.
local function Gone(chain)
    if not Notes()[chain.key] then return false end
    for _, quest in ipairs(chain.quests) do
        if Lines.OnQuest(quest) then return false end
    end
    return true
end

-- The step that is due: the first chain, by level, with a step for you now.
local function Due()
    if not (chains and ns.options.classQuests) then return nil end
    for _, chain in ipairs(chains) do
        if not Gone(chain) then
            local number, stage = Stage(chain)
            local quest = number and QuestOf(chain, number)
            if quest and Allowed(chain, quest) and not Guides(quest, stage) then return chain, number, quest, stage end
        end
    end
    return nil
end

-------------------------------------------------------------------------------
--  Where
-------------------------------------------------------------------------------
-- The point of a creature or object nearest a place, and how far (none on that map: as far as can be); without a place
-- its first; nil where Core knows none.
local function Spot(key, near)
    local points = SPAWNS:Get(key, "points")
    if type(points) ~= "table" then return nil end
    local best, score
    for _, point in pairs(points) do
        if type(point) == "table" and point.map then
            local this = near and math.huge or 0
            if near and point.map == near.map then this = (point.x - near.x) ^ 2 + (point.y - near.y) ^ 2 end
            if not best or this < score then best, score = point, this end
        end
    end
    return best, score
end

-- Who gives or takes a quest: the NPC nearest you of those for your side, else an object: whom to name, where it stands.
local function Party(record, npcs, objects, near)
    local side = Side()
    local best, far
    for _, each in ipairs(record[npcs] or EMPTY) do
        if not each.side or each.side == side then
            local point = Spot("npc:" .. each.npc, near)
            local away = point and ns.Run.Distance(point)
            if not best or (away and (not far or away < far)) then
                best, far = { npc = each.npc, name = Lines.NpcName(each.npc), point = point }, away
            end
        end
    end
    if best then return best end
    for _, each in ipairs(record[objects] or EMPTY) do
        if not each.side or each.side == side then
            return { object = each.object, name = OBJECTS:Get(each.object, "name"),
                     point = Spot("object:" .. each.object, near) }
        end
    end
    return nil
end

local function Zone(point)
    local maps = rawget(_G, "C_Map")
    local info = point and maps and Core.Ask(maps.GetMapInfo, point.map)
    return type(info) == "table" and Plain(info.name) or nil
end

-- "Talk to Uzzek in The Barrens": the words large on the step; one with no name known, the quest's.
local function Words(who, quest, verb)
    if not (who and who.name) then return Lines.QuestName(quest) end
    local zone = Zone(who.point)
    return (zone and ns.TEXT.classAtIn or ns.TEXT.classAt):format(who.object and ns.TEXT.classGo or verb, who.name, zone)
end

local function Place(step, point)
    if point then step.lines[#step.lines + 1] = { what = "place", map = point.map, x = point.x, y = point.y } end
end

local function Meet(step, who)
    if not who then return end
    if who.npc and who.name then step.friends = { who.name } end
    if who.object and who.name then step.things = { who.name } end
end

-- Where an objective is to be done: what is to be killed or used, what an item comes from (near where the quest goes on).
local function Field(objective, near)
    local kind, what = objective.kind, objective.what
    if not what then return nil end
    if kind == "kill" or kind == "talk" then return Spot("npc:" .. what, near) end
    if kind == "object" then return Spot("object:" .. what, near) end
    local best, score
    if kind == "loot" then
        for _, key in ipairs(DROPS:Keys("byItem", what) or EMPTY) do
            local point, far = Spot(tostring(key), near)
            if point and (not best or far < score) then best, score = point, far end
        end
    end
    return best
end

-------------------------------------------------------------------------------
--  The step
-------------------------------------------------------------------------------
local function Take(step, record, quest, near)
    local who = Party(record, "startNPCs", "startObjects", near)
    local item = (record.startItems or EMPTY)[1]
    if who then
        step.lines[1] = { what = "note", words = Words(who, quest, ns.TEXT.classTalk) }
        Place(step, who.point)
        Meet(step, who)
    elseif item then
        step.lines[1] = { what = "note", words = ns.TEXT.classUse:format(Lines.ItemName(item)) }
        step.items, step.uses = { item }, { { item = item } }
    else
        step.lines[1] = { what = "note", words = Lines.QuestName(quest) }
    end
    step.lines[#step.lines + 1] = { what = "take", quest = quest }
end

local function Work(step, record, quest, near)
    step.lines[1] = { what = "note", words = Lines.QuestName(quest) }
    step.lines[2] = { what = "brief", quest = quest }
    for goal = 1, Lines.Objectives(quest) do
        step.lines[#step.lines + 1] = { what = "goal", quest = quest, goal = goal }
    end
    for _, objective in ipairs(record.objectives or EMPTY) do
        local point = Field(objective, near)
        if point then return Place(step, point) end
    end
end

local function HandIn(step, record, quest, near, after)
    local who = Party(record, "finishNPCs", "finishObjects", near)
    step.lines[1] = { what = "note", words = Words(who, quest, ns.TEXT.classTalk) }
    if who then
        Place(step, who.point)
        Meet(step, who)
    end
    step.lines[#step.lines + 1] = { what = "handin", quest = quest }
    -- The next quest from the same NPC goes with it: one talk does both.
    local following = after and QUESTS:Get(after)
    local next = following and Party(following, "startNPCs", "startObjects", near)
    if next and who and next.npc and next.npc == who.npc then
        step.lines[#step.lines + 1] = { what = "take", quest = after }
    end
end

-- Near where the quest began: an objective, or an NPC with several places, is sought where you are sent anyway.
local function Near(record)
    local giver = record.startNPCs and record.startNPCs[1]
    return giver and Spot("npc:" .. giver.npc) or nil
end

local function Build(chain, number, quest, stage)
    local record = QUESTS:Get(quest) or EMPTY
    due = { key = chain.key, quest = quest, stage = stage }
    local step = { lines = {}, chain = ns.TEXT.classStep:format(chain.name, number, #chain.quests) }
    local near = Near(record)
    if stage == TAKE then
        Take(step, record, quest, nil)
    elseif stage == WORK then
        Work(step, record, quest, near)
    else
        HandIn(step, record, quest, near, chain.quests[number + 1])
    end
    guide.steps[ClassQuests.STEP] = step
end

function ClassQuests.Check()
    if not guide then return false end
    local chain, number, quest, stage = Due()
    if not chain then
        local had = due ~= nil
        due, guide.steps[ClassQuests.STEP] = nil, nil
        return had
    end
    if due and due.key == chain.key and due.quest == quest and due.stage == stage then return false end
    Build(chain, number, quest, stage)
    return true
end

function ClassQuests.Hand()
    return due and { ClassQuests.STEP } or EMPTY
end

function ClassQuests.Leave()
    if due then Notes()[due.key] = true end
end

function ClassQuests.Left()
    local count = 0
    for _, chain in ipairs(chains or EMPTY) do
        if Notes()[chain.key] then count = count + 1 end
    end
    return count
end

function ClassQuests.Back()
    wipe(Notes())
end
