local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling - Grind
--  Cloth where you kill anyway (Saneroki, 2026-10-31): after a step that has you
--  kill humanoids, whoever works with cloth gets a step of its own to kill on for
--  a while. Humanoids drop cloth by their level (Grind.CLOTH), so this is cloth
--  you need only while your skill still works with it, and only while they are
--  worth killing: a step is passed by once you are Grind.OUTLEVEL levels over them
--  (two levels under you a creature still gives about three quarters of the
--  experience), once you carry what it asks, or once you left the zone. Each stop
--  asks Grind.STOP more of that cloth, up to Grind.STACK, so it stays a little
--  more at each place and never a long grind; what you use up later is asked
--  again. Skip the first one with a click and the others of that zone go with it.
--
--  Who is killed comes from Core's sets: the quest's objective (Quests), the
--  creatures that drop what it asks (Drops), their kind and levels (NPCs), and
--  whether there are enough of them to go on with (Grind.MANY spawn points, so a
--  quest's one boss is none: CreatureSpawns, Spawns).
--
--      Grind.Weave(guide, Add)   Add(at, step) for each step of a guide just read
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Grind = {}
ns.Grind = Grind

Grind.STOP = 5      -- of a cloth each stop asks more
Grind.STACK = 20    -- and at most
Grind.STOPS = 4     -- stops for one cloth in one zone
Grind.OUTLEVEL = 2  -- levels you may be over them for the kill to be worth it
Grind.MANY = 6      -- spawn points of a creature for there to be more of it to kill
-- Which cloth humanoids of a level drop most, and from which skill up to which each profession works with it (where
-- its next cloth takes over).
Grind.CLOTH = {
    { item = 2589, from = 6, to = 16, Tailoring = { 1, 75 }, ["First Aid"] = { 1, 80 } },
    { item = 2592, from = 17, to = 26, Tailoring = { 75, 125 }, ["First Aid"] = { 80, 150 } },
    { item = 4306, from = 27, to = 41, Tailoring = { 125, 175 }, ["First Aid"] = { 150, 210 } },
    { item = 4338, from = 42, to = 51, Tailoring = { 175, 250 }, ["First Aid"] = { 210, 260 } },
    { item = 14047, from = 52, to = 63, Tailoring = { 250, 300 }, ["First Aid"] = { 260, 300 } },
}
Grind.SKILLS = { "Tailoring", "First Aid" }

local QUESTS, NPCS, DROPS, CREATURES, SPAWNS = Core.Data.Set("Quests"), Core.Data.Set("NPCs"), Core.Data.Set("Drops"),
                                               Core.Data.Set("CreatureSpawns"), Core.Data.Set("Spawns")
local EMPTY = {}

-- Whether there are enough of a creature around to go on killing it.
local function Many(npc)
    local points = CREATURES:Get(npc, "points") or SPAWNS:Get("npc:" .. tostring(npc), "points")
    return type(points) == "table" and #points >= Grind.MANY
end

-- The creatures an objective has you kill: itself, or those that drop what it asks.
local function Foes(objective)
    if objective.kind == "kill" and type(objective.what) == "number" then return { objective.what } end
    local foes = {}
    if objective.kind == "loot" and type(objective.what) == "number" then
        for _, key in ipairs(DROPS:Keys("byItem", objective.what) or EMPTY) do
            local npc = tonumber(tostring(key):match("^npc:(%d+)$"))
            if npc then foes[#foes + 1] = npc end
        end
    end
    return foes
end

-- The humanoids a step has you kill: their highest level, and a word for who they are; nil for none.
local function Humanoids(step)
    for _, line in ipairs(step.lines) do
        local record = line.what == "goal" and QUESTS:Get(line.quest)
        for _, objective in ipairs(record and record.objectives or EMPTY) do
            if objective.index == line.goal then
                for _, npc in ipairs(Foes(objective)) do
                    local top = NPCS:Get(npc, "levelMax")
                    if NPCS:Get(npc, "kind") == "humanoid" and type(top) == "number" and Many(npc) then return top, npc end
                end
            end
        end
    end
    return nil
end

local function ClothOf(level)
    for _, cloth in ipairs(Grind.CLOTH) do
        if level >= cloth.from and level <= cloth.to then return cloth end
    end
    return nil
end

-- A stop: kill on here, for a profession, until you carry so much of a cloth.
local function Stop(skill, cloth, zone, place, top, count, step, first)
    local reach = cloth[skill]
    return { woven = skill, foes = step.foes, needs = first,
             unless = { { what = "inZone", maps = { zone }, away = true },
                        { what = "hasSkill", skill = skill, level = reach[1], sign = "<" },
                        { what = "hasSkill", skill = skill, level = reach[2] },
                        { what = "reached", level = top + Grind.OUTLEVEL + 1 } },
             lines = { { what = "place", map = place.map, x = place.x, y = place.y, continent = place.continent },
                       { what = "note", words = ns.TEXT.grind:format(top + Grind.OUTLEVEL) },
                       { what = "carry", item = cloth.item, count = count } } }
end

-- The runs of kills of a guide: a step that goes on with the same creature counts with the step before it.
local function Runs(guide)
    local runs = {}
    for index, step in ipairs(guide.steps) do
        local top, npc = Humanoids(step)
        local zone, place = ns.Gathering.Stop(step)
        if top and zone then
            local run = runs[#runs]
            if run and run.npc == npc then
                run.index = index
            else
                runs[#runs + 1] = { index = index, npc = npc, top = top, zone = zone, place = place, step = step }
            end
        end
    end
    return runs
end

function Grind.Weave(guide, Add)
    local stops, firsts = {}, {} -- per zone and cloth: how many stops so far, the first stop's label per profession
    for _, run in ipairs(Runs(guide)) do
        local cloth = ClothOf(run.top)
        local key = cloth and (run.zone .. "/" .. cloth.item)
        local stop = key and (stops[key] or 0) + 1
        if stop and stop <= Grind.STOPS then
            stops[key] = stop
            local count = math.min(stop * Grind.STOP, Grind.STACK)
            for _, skill in ipairs(Grind.SKILLS) do
                local label = "grind/" .. skill .. "/" .. key
                local made = Stop(skill, cloth, run.zone, run.place, run.top, count, run.step, firsts[label])
                if stop == 1 then
                    made.label = label
                    firsts[label] = label
                end
                local at = run.index + 1
                while at > 1 and guide.steps[at - 1].together do at = at - 1 end
                Add(at, made)
            end
        end
    end
end
