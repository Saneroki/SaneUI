local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Gathering
--  Whether your gathering keeps up with where the guide takes you (Saneroki,
--  2026-10-29: Herbalism and Mining high enough before the guide goes on to a
--  harder zone). The next zone the guide's steps go to is the first one ahead
--  where herbs or ore grow; for each of those two skills you have, the skill
--  that zone asks is worked out from the game's own facts in Core's sets:
--  Objects (each herb's and ore's skill) and Spawns (where they grow), the
--  lowest skill that gathers Gathering.SHARE of that zone's spawns of that
--  kind. Where yours is lower, the guide's view says so, under its head.
--  Without Core's data (Retail, for now) it says nothing.
--
--      Gathering.Need(zone)   { herb = skill, ore = skill } a zone (its map's number) asks; nil where nothing grows
--      Gathering.Short()      nil, or { map, name, short = { { skill, have, need } } }: the next zone ahead with
--                             herbs or ore, and each of your gathering skills that is lower than it asks
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Gathering = {}
ns.Gathering = Gathering

Gathering.SHARE = 0.5   -- the share of a zone's herbs or ore a skill should gather to be enough for it
Gathering.AHEAD = 12    -- zones ahead looked at, at most
Gathering.KINDS = { "herb", "ore" }

local OBJECTS, SPAWNS, SKILLS = Core.Data.Set("Objects"), Core.Data.Set("Spawns"), Core.Data.Set("SkillLines")
local needs -- [zone] = { herb = skill, ore = skill }, once Core's data gave any
local names = {} -- [kind] = the skill's name in the game's words (SkillLines)
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
                if not names[kind] then
                    local skill = OBJECTS:Get(key, "skill")
                    names[kind] = skill and SKILLS:Get(skill, "name") or nil
                end
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

function Gathering.Short()
    if not ns.options.gather or not Needs() then return nil end
    local maps = rawget(_G, "C_Map")
    local here = ZoneOf(maps and Core.Ask(maps.GetBestMapForUnit, "player"))
    for _, map in ipairs(ns.Run.ZonesAhead(Gathering.AHEAD)) do
        local zone = ZoneOf(map)
        local need = zone ~= here and Gathering.Need(zone)
        if need then
            -- The first zone ahead where anything grows decides: enough for it, nothing is said.
            local short = {}
            for _, kind in ipairs(Gathering.KINDS) do
                local name = names[kind]
                local have = name and need[kind] and ns.Lines.Skill(name) or -1
                if have >= 0 and have < need[kind] then
                    short[#short + 1] = { skill = name, have = have, need = need[kind] }
                end
            end
            return short[1] and { map = zone, name = Name(zone), short = short } or nil
        end
    end
    return nil
end
