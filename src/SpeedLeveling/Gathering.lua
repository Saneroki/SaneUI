local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Gathering
--  Your professions keep up with where the guide takes you (Saneroki, 2026-10-29;
--  as steps of the guide 2026-10-30; where the guide passes the most nodes anyway
--  2026-10-31). The guide is walked as it is taken up, with the guides after it,
--  and the steps of your professions are woven in (Gathering.Weave). A step for a
--  profession you have not learnt is passed by and not listed (Run.lua), so the
--  steps stay the same for a character whatever it learns and whatever its race,
--  and so does its place in the guide. The view keeps the guide's own numbers
--  (step.shown, guide.total): ours bear the number of the step they stand by.
--
--  Mining and Herbalism are levelled where it costs least: a zone counts where the
--  guide spends Gathering.STAY steps and enough grows (Gathering.RICH; a city is no
--  place to level), and of the steps there the one with the most nodes around it
--  (Gathering.NEAR yards, at least Gathering.FEW) gets a step of its own after it:
--  "Level Mining to 16", with its count and bar and the arrow on those nodes. How
--  far: to what the next harder zone asks, as far as the nodes around still teach
--  (Gathering.TEACHES), so a spot of weak nodes asks less, and a later spot of better
--  ones asks the rest. Before the guide goes on to the harder zone, a second step
--  checks the same again (not where a spot stands just before it, nor when the next
--  zone teaches that too: then you would not have to come back). A zone with nothing
--  to gather asks nothing of you, and a step is passed by once you left its zone: the
--  next zone asks its own.
--
--  The crafts and the rest stay as they were: before the first step into a zone
--  that asks more than the guide's zones so far, a step of its own for each.
--
--  What a zone asks comes from the game's own facts in Core's sets: Objects (each
--  herb's and ore's skill) and Spawns (where they grow): the lowest skill that
--  gathers Gathering.SHARE of that zone's spawns of that kind. Each profession goes
--  by what it works with, the others by the higher of the two; a zone where nothing
--  grows asks nothing. Without Core's data (Retail, for now) no step is woven.
--
--      Gathering.Need(zone)         { herb, ore, any } a zone (its map's number) asks; nil where nothing grows
--      Gathering.Chance(node, rank) how likely a node of Objects gives a skill point at that rank; nil: too hard yet
--      Gathering.Goal(skill, rank)  the level the steps ahead still ask of that skill above that rank; nil for none
--      Gathering.Stop(step)         the zone of a step's first place of its own, and that line
--      Gathering.Weave(guide)       the steps of the professions put into a guide just read
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Gathering = {}
ns.Gathering = Gathering

Gathering.SHARE = 0.5   -- the share of a zone's herbs or ore a skill should gather to be enough for it
Gathering.STAY = 10     -- the steps a guide spends in a zone for that zone to count
Gathering.NEAR = 150    -- yards around a step of the guide that count as around it
Gathering.FEW = 5       -- nodes around a step for it to be a place to level at
Gathering.RICH = 30     -- nodes of a kind in a zone for it to be a place to level at
Gathering.TEACHES = 0.4 -- the chance of a skill point a node must still give to be stopped for
Gathering.CLOSE = 3     -- steps: a spot this near the zone's end needs no check after it
Gathering.AHEAD = 5     -- guides read on for where the way goes next
-- A node whose thresholds the data lacks counts as the weakest kind: it never asks for more than it may give.
Gathering.YELLOW, Gathering.GREY = 9, 19
Gathering.KINDS = { "herb", "ore" }
Gathering.SKILLS = { ore = "Mining", herb = "Herbalism" }
-- Every profession, in the game's words and the order of its steps, and what of a zone it goes by.
Gathering.PROFESSIONS = {
    { "Mining", "ore" }, { "Herbalism", "herb" }, { "Skinning", "any" }, { "Blacksmithing", "ore" },
    { "Engineering", "ore" }, { "Alchemy", "herb" }, { "Leatherworking", "any" }, { "Tailoring", "any" },
    { "Enchanting", "any" }, { "Cooking", "any" }, { "First Aid", "any" }, { "Fishing", "any" },
}

local OBJECTS, SPAWNS = Core.Data.Set("Objects"), Core.Data.Set("Spawns")
local EMPTY = {}
local needs -- [zone] = { herb = skill, ore = skill, any = the higher }, once Core's data gave any
local placed = {} -- [zone .. kind] = { { x, y, node } }: x and y 0 to 1
local ZONE -- the game's map type of a zone

-- A map's zone: the map itself where it is one, else the zone it lies in (a town, a cave); the map where none is.
local function ZoneOf(map)
    local maps = rawget(_G, "C_Map")
    if type(map) ~= "number" or not maps then return map end
    ZONE = ZONE or (rawget(_G, "Enum") and Enum.UIMapType and Enum.UIMapType.Zone or 3)
    local at, seen = map, 0
    while type(at) == "number" and seen < 6 do
        local info = Core.Ask(maps.GetMapInfo, at)
        if type(info) ~= "table" then break end
        if Plain(info.mapType) == ZONE then return at end
        at, seen = Plain(info.parentMapID), seen + 1
    end
    return map
end

-- Every zone's asks from Core's sets: per zone and kind the spawns at each skill, then the lowest skill that reaches
-- the share. nil while the sets are not there yet (asked again later).
local function Needs()
    if needs then return needs end
    local counts, found = {}, false
    for _, kind in ipairs(Gathering.KINDS) do
        for _, key in ipairs(OBJECTS:Keys("byKind", kind) or EMPTY) do
            local level = OBJECTS:Get(key, "skillLevel")
            local points = SPAWNS:Get("object:" .. tostring(key), "points")
            if type(level) == "number" and type(points) == "table" then
                for _, point in pairs(points) do
                    if type(point) == "table" and type(point.map) == "number" then
                        local zone = counts[point.map] or {}
                        counts[point.map] = zone
                        zone[kind] = zone[kind] or { total = 0 }
                        zone[kind][level] = (zone[kind][level] or 0) + 1
                        zone[kind].total = zone[kind].total + 1
                        found = true
                    end
                end
            end
        end
    end
    if not found then return nil end
    needs = {}
    for zone, kinds in pairs(counts) do
        needs[zone] = {}
        for kind, spawns in pairs(kinds) do
            local levels = {}
            for level in pairs(spawns) do if type(level) == "number" then levels[#levels + 1] = level end end
            table.sort(levels)
            local reached = 0
            for _, level in ipairs(levels) do
                reached = reached + spawns[level]
                if reached >= spawns.total * Gathering.SHARE then
                    needs[zone][kind] = level
                    needs[zone].any = math.max(needs[zone].any or 0, level)
                    break
                end
            end
        end
    end
    return needs
end

function Gathering.Need(zone)
    local all = Needs()
    return all and all[zone] or nil
end

local function Name(zone)
    local maps = rawget(_G, "C_Map")
    local info = maps and Core.Ask(maps.GetMapInfo, zone)
    return type(info) == "table" and Plain(info.name) or tostring(zone)
end

-------------------------------------------------------------------------------
--  What a node teaches
-------------------------------------------------------------------------------
local function Thresholds(node)
    local level = node.skillLevel or 1
    return level, node.yellowAt or (level + Gathering.YELLOW), node.greyAt or (level + Gathering.GREY)
end

function Gathering.Chance(node, rank)
    local level, yellow, grey = Thresholds(node)
    if rank < level then return nil end
    if rank < yellow then return 1 end
    if rank >= grey then return 0 end
    return (grey - rank) / (grey - yellow)
end

-- The rank up to which a node still teaches well enough to stop for.
local function Reach(node)
    local _, yellow, grey = Thresholds(node)
    return math.floor(grey - Gathering.TEACHES * (grey - yellow))
end

-- How far nodes teach, from the lowest up: each kind of node takes over from where the ones below it got to. A single
-- node of a kind teaches nobody a level.
local function Taught(around)
    local kinds, list = {}, {}
    for _, spot in ipairs(around) do
        local node = spot.node
        if not kinds[node] then
            kinds[node] = 0
            list[#list + 1] = node
        end
        kinds[node] = kinds[node] + 1
    end
    table.sort(list, function(a, b) return (a.skillLevel or 0) < (b.skillLevel or 0) end)
    local level = 1
    for _, node in ipairs(list) do
        if kinds[node] > 1 and (node.skillLevel or 0) <= level then level = math.max(level, Reach(node)) end
    end
    return level
end

-- A zone's herbs or ore.
local function Placed(zone, kind)
    local key = tostring(zone) .. kind
    if placed[key] then return placed[key] end
    local list = {}
    for _, id in ipairs(OBJECTS:Keys("byKind", kind) or EMPTY) do
        local node = OBJECTS:Get(id)
        local points = SPAWNS:Get("object:" .. tostring(id), "points")
        if type(node) == "table" and type(node.skillLevel) == "number" and type(points) == "table" then
            for _, point in pairs(points) do
                if type(point) == "table" and point.map == zone then
                    list[#list + 1] = { x = point.x / 100, y = point.y / 100, node = node }
                end
            end
        end
    end
    placed[key] = list
    return list
end

-- The nodes of a list within Gathering.NEAR yards of a place on the zone's map, and their middle.
local function Around(list, x, y, yards)
    local around, sumX, sumY = {}, 0, 0
    for _, spot in ipairs(list) do
        if ((spot.x - x) * yards[1]) ^ 2 + ((spot.y - y) * yards[2]) ^ 2 <= Gathering.NEAR ^ 2 then
            around[#around + 1] = spot
            sumX, sumY = sumX + spot.x, sumY + spot.y
        end
    end
    return around, sumX / math.max(#around, 1), sumY / math.max(#around, 1)
end

-------------------------------------------------------------------------------
--  Where the guide goes
-------------------------------------------------------------------------------
-- The zone of a step's first place of its own (a point on the way is none), and that line.
function Gathering.Stop(step)
    for _, line in ipairs(step.lines) do
        if (line.what == "place" or line.what == "arrive") and line.map and not line.way then
            local zone = ZoneOf(ns.Run.MapId(line.map))
            if zone then return zone, line end
        end
    end
    return nil
end

-- The way from this guide on, step by step: each step's zones in this guide, the guides after it only as zones.
local function Way(guide)
    local way, read = {}, guide
    for number = 0, Gathering.AHEAD do
        if not read then break end
        for index, step in ipairs(read.steps) do
            local zone = Gathering.Stop(step)
            if zone then way[#way + 1] = { zone = zone, index = number == 0 and index or nil } end
        end
        read = ns.Guide.After(read)
    end
    return way
end

-- The stays of a way for a kind: { zone, first, last, steps, open } in order. Only zones where that kind grows count; a
-- stay too short to count goes, and what it split is one stay again. first and last are steps of this guide; open: the
-- stay goes on in the next guide.
local function Stays(way, kind)
    local runs = {}
    for _, visit in ipairs(way) do
        local need = Gathering.Need(visit.zone)
        if need and need[kind] and #Placed(visit.zone, kind) >= Gathering.RICH then
            local run = runs[#runs]
            if not (run and run.zone == visit.zone) then
                run = { zone = visit.zone, steps = 0 }
                runs[#runs + 1] = run
            end
            run.steps = run.steps + 1
            if visit.index then
                run.first, run.last = run.first or visit.index, visit.index
            else
                run.open = true
            end
        end
    end
    local stays = {}
    for _, run in ipairs(runs) do
        if run.steps >= Gathering.STAY then
            local stay = stays[#stays]
            if stay and stay.zone == run.zone then
                stay.steps, stay.open = stay.steps + run.steps, run.open
                stay.first, stay.last = stay.first or run.first, run.last or stay.last
            else
                stays[#stays + 1] = run
            end
        end
    end
    return stays
end

-------------------------------------------------------------------------------
--  The steps
-------------------------------------------------------------------------------
-- A step of a craft, before a zone: passed by once you stand in that zone.
local function Step(skill, level, zone)
    return { woven = skill, unless = { { what = "inZone", maps = { zone }, away = false } },
             lines = { { what = "note", words = ns.TEXT.raiseSkill:format(skill, level) },
                       { what = "skill", skill = skill, level = level, words = ns.TEXT.skillBefore:format(Name(zone)) } } }
end

-- A step of Mining or Herbalism, in a zone: passed by once you left that zone. The place, where it has one, is where the nodes are.
local function Here(skill, level, zone, words, x, y)
    local step = { woven = skill, unless = { { what = "inZone", maps = { zone }, away = true } }, lines = {} }
    if x then step.lines[1] = { what = "place", map = zone, x = x * 100, y = y * 100 } end
    step.lines[#step.lines + 1] = { what = "note", words = ns.TEXT.raiseSkill:format(skill, level) }
    step.lines[#step.lines + 1] = { what = "skill", skill = skill, level = level, words = words }
    return step
end

-- The steps of a stay with the most nodes around them, one for each level they teach to, in the guide's order, each
-- asking more than the one before: { index, level, x, y }.
local function Spots(guide, stay, kind, want, yards)
    local list, best = Placed(stay.zone, kind), {}
    for index = stay.first, stay.last do
        local zone, line = Gathering.Stop(guide.steps[index])
        local map, x, y
        if zone == stay.zone then map, x, y = ns.Run.Point(line) end
        if map == stay.zone then
            local around, middleX, middleY = Around(list, x, y, yards)
            if #around >= Gathering.FEW then
                local level = math.min(want, Taught(around))
                local kept = best[level]
                if not kept or #around >= kept.count then
                    best[level] = { index = index, level = level, x = middleX, y = middleY, count = #around }
                end
            end
        end
    end
    local spots = {}
    for _, spot in pairs(best) do spots[#spots + 1] = spot end
    table.sort(spots, function(a, b) return a.index < b.index end)
    local kept, highest = {}, 1
    for _, spot in ipairs(spots) do
        if spot.level > highest then
            kept[#kept + 1] = spot
            highest = spot.level
        end
    end
    return kept
end

-- Where a step goes that follows a step of the guide: one that goes along with the next stays with it, ours after both.
local function After(guide, index)
    local at = index + 1
    while at > 1 and guide.steps[at - 1] and guide.steps[at - 1].together do at = at - 1 end
    return at
end

-- The harder zone after a stay, by the zones that follow, and what it asks.
local function Ahead(stays, number, kind)
    local here = Gathering.Need(stays[number].zone)[kind]
    for later = number + 1, #stays do
        local asked = Gathering.Need(stays[later].zone)[kind]
        if asked > here then return asked, stays[later].zone end
    end
    return nil
end

-- Mining's or Herbalism's steps for a guide: at the best spots of each stay, and the check before the guide leaves the zone.
local function Along(guide, way, kind, Add)
    local skill = Gathering.SKILLS[kind]
    local stays = Stays(way, kind)
    for number, stay in ipairs(stays) do
        local want, harder = Ahead(stays, number, kind)
        local yards = stay.first and ns.Run.Yards(stay.zone)
        if want and stay.first then
            local spots = yards and Spots(guide, stay, kind, want, yards) or EMPTY
            for _, spot in ipairs(spots) do
                Add(After(guide, spot.index), Here(skill, spot.level, stay.zone, ns.TEXT.skillHere, spot.x, spot.y))
            end
            local last = spots[#spots]
            local level = last and last.level or math.min(want, Taught(Placed(stay.zone, kind)))
            local following = stays[number + 1]
            local teachesToo = following and following.zone ~= harder and Taught(Placed(following.zone, kind)) >= level
            if not stay.open and not teachesToo and level > 1
                and not (last and stay.last - last.index <= Gathering.CLOSE) then
                Add(After(guide, stay.last), Here(skill, level, stay.zone, ns.TEXT.skillBefore:format(Name(harder))))
            end
        end
    end
end

-- The zones a guide goes to, step by step, each once a step (the points on the way do not count), and the steps it
-- spends in each.
local function Zones(guide)
    local visits, stays = {}, {}
    for index, step in ipairs(guide.steps) do
        local here = {}
        for _, line in ipairs(step.lines) do
            local zone = (line.what == "place" or line.what == "arrive") and line.map and not line.way
                and ZoneOf(ns.Run.MapId(line.map))
            if zone and not here[zone] then
                here[zone] = true
                here[#here + 1] = zone
                stays[zone] = (stays[zone] or 0) + 1
            end
        end
        visits[index] = here
    end
    return visits, stays
end

-- A zone's steps for what it asks more of than any zone so far (highest); nil for none. Mining and Herbalism have their own.
local function Asked(zone, highest)
    local need, steps = Gathering.Need(zone), {}
    if not need then return nil end
    for _, profession in ipairs(Gathering.PROFESSIONS) do
        local level = need[profession[2]]
        local gathers = profession[1] == Gathering.SKILLS[profession[2]]
        if not gathers and level and level > (highest[profession[2]] or 1) then
            steps[#steps + 1] = Step(profession[1], level, zone)
        end
    end
    for kind, level in pairs(need) do highest[kind] = math.max(highest[kind] or 0, level) end
    return steps[1] and steps or nil
end

-- The crafts' steps: before the first step into each zone that asks more than the ones before.
local function Crafts(guide, Add)
    local visits, stays = Zones(guide)
    local highest = {}
    for index, here in ipairs(visits) do
        for _, zone in ipairs(here) do
            local steps = stays[zone] >= Gathering.STAY and Asked(zone, highest)
            for _, step in ipairs(steps or EMPTY) do Add(After(guide, index - 1), step) end
        end
    end
end

-- Our steps into the guide's. The labels move with the steps; ours get theirs here.
local function Sew(guide, gates)
    local woven, moved, goals = {}, {}, {} -- moved: [a step's old number] = its new one
    local function Ours(index)
        for _, step in ipairs(gates[index] or EMPTY) do
            step.shown = math.min(index, #guide.steps)
            woven[#woven + 1] = step
            if step.label then guide.labels[step.label] = #woven end
            for _, line in ipairs(step.lines) do
                if line.what == "skill" then goals[#goals + 1] = { index = #woven, skill = line.skill, level = line.level } end
            end
        end
    end
    local labels = {}
    for label, index in pairs(guide.labels) do labels[label] = index end
    for index, step in ipairs(guide.steps) do
        Ours(index)
        step.shown = index
        woven[#woven + 1] = step
        moved[index] = #woven
    end
    Ours(#guide.steps + 1)
    for label, index in pairs(labels) do guide.labels[label] = moved[index] end
    guide.steps, guide.total, guide.goals = woven, #guide.steps, goals
end

function Gathering.Weave(guide)
    if not Needs() then return end
    local gates = {} -- [the step they go before] = { steps }
    local function Add(at, step)
        gates[at] = gates[at] or {}
        table.insert(gates[at], step)
    end
    local way = Way(guide)
    for _, kind in ipairs({ "ore", "herb" }) do Along(guide, way, kind, Add) end
    Crafts(guide, Add)
    ns.Grind.Weave(guide, Add)
    if next(gates) then Sew(guide, gates) end
end

function Gathering.Goal(skill, rank)
    local guide, at = ns.Run.Guide(), ns.Run.At()
    for _, goal in ipairs(guide and guide.goals or EMPTY) do
        if goal.skill == skill and goal.index >= at and goal.level > rank then return goal.level end
    end
    return nil
end
