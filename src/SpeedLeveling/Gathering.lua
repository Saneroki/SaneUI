local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Gathering
--  Your professions keep up with where the guide takes you (Saneroki, 2026-10-29;
--  as steps of the guide 2026-10-30). The guide is walked as it is taken up. Before
--  the first step into a zone that asks more than the guide's zones so far, and
--  where it stays a while (Gathering.STAY steps: an errand there asks nothing), a
--  step of its own for each profession, woven into the guide (Gathering.Weave):
--  "Level Mining to 65", with its count and bar, done when your skill is there
--  and skipped by a click as any step. A step for a profession you have not learnt
--  is passed by and not listed (Run.lua), so that the steps stay the same for a
--  character whatever it learns, and so does its place in the guide.
--
--  What a zone asks comes from the game's own facts in Core's sets: Objects (each
--  herb's and ore's skill) and Spawns (where they grow): the lowest skill that
--  gathers Gathering.SHARE of that zone's spawns of that kind. Each profession goes
--  by what it works with, the others by the higher of the two; a zone where nothing
--  grows asks nothing. Without Core's data (Retail, for now) no step is woven.
--
--      Gathering.Need(zone)    { herb, ore, any } a zone (its map's number) asks; nil where nothing grows
--      Gathering.Weave(guide)  the steps of the professions put into a guide just read
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Gathering = {}
ns.Gathering = Gathering

Gathering.SHARE = 0.5   -- the share of a zone's herbs or ore a skill should gather to be enough for it
Gathering.STAY = 10     -- the steps a guide spends in a zone for that zone to count
Gathering.KINDS = { "herb", "ore" }
-- Every profession, in the game's words and the order of its steps, and what of a zone it goes by.
Gathering.PROFESSIONS = {
    { "Mining", "ore" }, { "Herbalism", "herb" }, { "Skinning", "any" }, { "Blacksmithing", "ore" },
    { "Engineering", "ore" }, { "Alchemy", "herb" }, { "Leatherworking", "any" }, { "Tailoring", "any" },
    { "Enchanting", "any" }, { "Cooking", "any" }, { "First Aid", "any" }, { "Fishing", "any" },
}

local OBJECTS, SPAWNS = Core.Data.Set("Objects"), Core.Data.Set("Spawns")
local needs -- [zone] = { herb = skill, ore = skill, any = the higher }, once Core's data gave any
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
        for _, key in ipairs(OBJECTS:Keys("byKind", kind) or {}) do
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

-- A step of the guide for one profession.
local function Step(skill, level, zone)
    return { woven = skill, unless = { { what = "inZone", maps = { zone }, away = false } },
             lines = { { what = "note", words = ns.TEXT.raiseSkill:format(skill, level) },
                       { what = "skill", skill = skill, level = level, words = ns.TEXT.skillBefore:format(Name(zone)) } } }
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

-- A zone's steps for what it asks more of than any zone so far (highest); nil for none.
local function Asked(zone, highest)
    local need, steps = Gathering.Need(zone), {}
    if not need then return nil end
    for _, profession in ipairs(Gathering.PROFESSIONS) do
        local level = need[profession[2]]
        if level and level > (highest[profession[2]] or 0) then steps[#steps + 1] = Step(profession[1], level, zone) end
    end
    for kind, level in pairs(need) do highest[kind] = math.max(highest[kind] or 0, level) end
    return steps[1] and steps or nil
end

function Gathering.Weave(guide)
    if not Needs() then return end
    local visits, stays = Zones(guide)
    local highest, gates = {}, {} -- gates: [the step they go before] = { steps }
    for index, here in ipairs(visits) do
        for _, zone in ipairs(here) do
            local steps = stays[zone] >= Gathering.STAY and Asked(zone, highest)
            if steps then
                -- A step that goes along with the next stays with it: ours go before both.
                local at = index
                while at > 1 and guide.steps[at - 1].together do at = at - 1 end
                gates[at] = gates[at] or {}
                for _, step in ipairs(steps) do table.insert(gates[at], step) end
            end
        end
    end
    if not next(gates) then return end
    local woven, moved = {}, {} -- moved: [a step's old number] = its new one
    for index, step in ipairs(guide.steps) do
        for _, ours in ipairs(gates[index] or {}) do woven[#woven + 1] = ours end
        woven[#woven + 1] = step
        moved[index] = #woven
    end
    guide.steps = woven
    for label, index in pairs(guide.labels) do guide.labels[label] = moved[index] end
end
