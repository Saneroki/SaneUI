local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling - Detours
--  A herb or ore that stands near your way right now (Saneroki, 2026-10-31). The
--  guide's steps of Gathering.lua say where levelling costs least; between them,
--  whatever the game's minimap really shows (Core.Sight: Navigation's Found) is
--  fetched on the way when it is worth it: a step stands over the guide's, with
--  the arrow, the map pin and the key on that node, and when it is over you are back
--  on the guide where you were.
--
--  Worth it means: you have the profession, the steps ahead of you still ask more
--  of it (Gathering.Goal), the node can give you a skill point, and the way round
--  it adds at most Detours.FAR yards to your way to the guide's next place, less
--  the less likely a skill point is (Gathering.Chance). Not in a fight, dead or in
--  flight.
--
--  The step ends by itself as soon as the node is gone: you gathered it, or somebody
--  else did (the minimap no longer shows it). It ends too once your skill got where
--  the steps ahead want it, once you stood beside the node for Detours.WAIT seconds
--  without it going, after Detours.LONG seconds, or with a click on the step. A node
--  it ended on is not asked for again for Detours.AGAIN seconds.
--
--  The step stands at Detours.STEP, a number outside the guide's own, so the guide's
--  steps and your place in them stay as they are. Knows only Core.Sight, so without
--  Navigation, or on a client whose minimap does not answer (Retail), there are none.
--
--      Detours.Use(guide)      none for a guide just taken up
--      Detours.Update(shown)   looks while the guide is shown
--      Detours.Hand()          the step: { Detours.STEP } or nothing
--      Detours.Leave()         a click on the step
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Detours = {}
ns.Detours = Detours

Detours.STEP = -2    -- where the step stands in guide.steps: outside the guide's own numbers
Detours.LOOK = 1.5   -- seconds between looks at what is in sight
Detours.FAR = 60     -- yards a node may add to your way, with a skill point sure
Detours.FRESH = 20   -- seconds since the minimap last showed it
Detours.THERE = 10   -- yards: you are at it
Detours.WAIT = 8     -- seconds beside it before it counts as not to be had
Detours.LONG = 45    -- seconds a detour takes at most
Detours.AGAIN = 300  -- seconds a node it ended on is not asked for again
Detours.SAME = 0.004 -- of the map: as near as two readings of one node
Detours.WORDS = { herb = "gatherHerb", ore = "gatherOre" }

local Lines = ns.Lines
local EMPTY = {}

local guide      -- the guide run
local going      -- the detour: { key, map, x, y, skill, goal, since, beside }
local ended = {} -- the nodes it ended on: { key, map, x, y, at }
local ticker

local function Now() return Plain(Core.Ask(GetTime)) or 0 end

local function Same(a, map, x, y)
    return a.map == map and math.abs(a.x - x) < Detours.SAME and math.abs(a.y - y) < Detours.SAME
end

local function Tried(key, map, x, y)
    for index = #ended, 1, -1 do
        local node = ended[index]
        if Now() - node.at > Detours.AGAIN then
            table.remove(ended, index)
        elseif node.key == key and Same(node, map, x, y) then
            return true
        end
    end
    return false
end

-- The detour over: back on the guide. Nothing of it stays in the guide, and that node is left alone a while.
local function End()
    ended[#ended + 1] = { key = going.key, map = going.map, x = going.x, y = going.y, at = Now() }
    going = nil
    if guide then guide.steps[Detours.STEP] = nil end
    ns.Guide.CheckSoon()
end

-- Whether you cannot go anywhere for a node now.
local function Busy()
    return Lines.Dead() or Core.Ask(rawget(_G, "UnitAffectingCombat"), "player") == true
        or Core.Ask(rawget(_G, "UnitOnTaxi"), "player") == true
end

-- What a node adds to your way to a place, in yards (there and back where there is no place), and how far off it is.
local function Added(place, aim)
    local yards, way = ns.Run.Way(place)
    if not yards then return nil end
    local to, toWay
    if aim then to, toWay = ns.Run.Way(aim) end
    if not to then return yards * 2, yards end
    -- The two ways are known from where you stand: the rest of the triangle from them.
    local beyond = math.sqrt(math.max(0, yards ^ 2 + to ^ 2 - 2 * yards * to * math.cos(way - toWay)))
    return yards + beyond - to, yards
end

local function Go(seen, skill, goal)
    local node, map, x, y = seen.node, seen.map, seen.x, seen.y
    going = { key = node.key, map = map, x = x, y = y, skill = skill, goal = goal, since = Now() }
    guide.steps[Detours.STEP] = {
        chain = ns.TEXT.detour, things = { node.name },
        lines = { { what = "place", map = map, x = x * 100, y = y * 100 },
                  { what = "note", words = ns.TEXT[Detours.WORDS[node.kind]]:format(node.name) },
                  { what = "skill", skill = skill, level = goal, words = ns.TEXT.skillHere } } }
    ns.Guide.CheckSoon()
end

-- The node worth the least way, if any is worth any.
local function Seek()
    if Busy() then return end
    local aim, now, best, bestSkill, bestGoal, least = ns.Run.Target(), Now(), nil, nil, nil, nil
    for _, seen in ipairs(Core.Sight.Nodes()) do
        local node = seen.node
        local skill = node and ns.Gathering.SKILLS[node.kind]
        local rank = skill and Lines.Skill(skill) or -1
        local goal = rank >= 0 and ns.Gathering.Goal(skill, rank)
        local chance = goal and ns.Gathering.Chance(node, rank)
        if chance and chance > 0 and now - seen.seen <= Detours.FRESH and not Tried(node.key, seen.map, seen.x, seen.y) then
            local added = Added({ map = seen.map, x = seen.x * 100, y = seen.y * 100 }, aim)
            if added and added <= Detours.FAR * chance and (not least or added < least) then
                best, bestSkill, bestGoal, least = seen, skill, goal, added
            end
        end
    end
    if best then Go(best, bestSkill, bestGoal) end
end

-- Whether the node of the detour is still in sight.
local function There()
    for _, seen in ipairs(Core.Sight.Nodes()) do
        if seen.node and seen.node.key == going.key and Same(going, seen.map, seen.x, seen.y) then return true end
    end
    return false
end

-- The detour goes on, or it is over.
local function Follow()
    local now = Now()
    if not There() or Lines.Skill(going.skill) >= going.goal or now - going.since > Detours.LONG then return End() end
    local yards = ns.Run.Way({ map = going.map, x = going.x * 100, y = going.y * 100 })
    if not yards then return End() end
    if yards > Detours.THERE then
        going.beside = nil
    elseif not going.beside then
        going.beside = now
    elseif now - going.beside > Detours.WAIT then
        End()
    end
end

local function Look()
    if not guide then return end
    if going then
        if ns.options.gather then Follow() else End() end
    elseif ns.options.gather then
        Seek()
    end
end

function Detours.Use(read)
    if guide then guide.steps[Detours.STEP] = nil end
    guide, going = read, nil
end

function Detours.Hand()
    return going and { Detours.STEP } or EMPTY
end

function Detours.Leave()
    if going then End() end
end

function Detours.Update(shown)
    local on = shown and not ns.off
    if on and not ticker then
        ticker = C_Timer.NewTicker(Detours.LOOK, ns.Guard(Look))
    elseif not on and ticker then
        ticker:Cancel()
        ticker = nil
    end
end
