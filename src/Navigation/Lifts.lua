local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Lifts
--  The lifts of Core's set Travel on the walking data (Walk.lua): each end of
--  a lift's car on its landing, the floor beside its shaft at its height, and
--  the levels a lift joins (the region of its lower landing and that of its
--  upper one), where a place stands among them. For the planner (Planner.lua).
--  Knows no frames.
--
--      Lifts.All()         every lift of a plane of the world map (Coords.Planes): { kind ("lift"), key, way, map
--                          (its plane), u, v (its shaft), time (its slower ride), wait (between two departures from an
--                          end), maps (the zone maps its ends lie on), [1] its lower end, [2] its upper }, each end
--                          { name ("lift:<key>:<n>"), lift, map, u, v, z (its height) }
--      Lifts.Landed(end)   whether the end lies on a landing (asked once the walking data is there): then also its
--                          floor ({ key, index }), pu, pv (the landing's point nearest the shaft) and region
--      Lifts.Levels(map)   the levels the lifts of a plane join: { lower, upper (regions), stacked }, one per two
--                          regions a lift's landings lie in: stacked, one over the other (the Undercity under the ruins
--                          of Lordaeron), or side by side (Thunder Bluff's mesa and Mulgore at its foot); a lift within
--                          one region (the Great Lift) joins none
--      Lifts.Joined(a, b, map)   whether a lift joins a region of each of two places (sets of regions)
--      Lifts.Stand(map, u, v, regions, floor, reach, at)   where a place stands (floor: its own where known; at:
--                          the pin's map): its regions without the levels it does not stand on, and the lifts' upper
--                          levels it stands below ({ [region] = true }, nil: none)
--      Lifts.Near(map, u, v, lower, upper)   a lift within Lifts.NEAR yards of the point that joins those two
--                          regions, and its ends
--
--  Two levels are stacked where, on a ring Lifts.RING yards round their lifts' shafts, at least a third of the points
--  on the lower level lie under the upper (the Undercity under the ruins; Thunder Bluff's mesa stands beside the land
--  at its foot). A place below a stacked lift's upper level stands there, not on that level: one whose floor is known
--  (the player's, a lift's end) where that level's floors lie over it by more than Walk.RISE yards; any other where
--  floors of the lift's lower level lie under that level's under the place (the Undercity's flight master). A pin on
--  the map the lift's ends lie on (the Undercity's) also over floors of any other region below that level's (the
--  city's lower parts, which the walking data does not join to the lift), and, with none under it, where the nearest
--  such floor within Lifts.RING yards lies under that level (the city's bank, its floor missing from the walking data
--  under the throne room); a pin on another map stands as its floors are (the ruins' courtyard over their cellars).
--  It stands on the floor below that showed it.
--  Where two levels side by side lie one over the other, by the lift (its upper landing over the platform at its
--  foot), a place stands on the upper. A walk between two levels a lift joins, or between a level and a place below
--  it, is none: the lift is the way (Planner.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Walk = ns.Coords, ns.Walk
local Lifts = {}
ns.Lifts = Lifts

Lifts.LANDING = 20  -- yards from a lift's end its landing may lie (beside its shaft: a door, a platform)
Lifts.NEAR = 12     -- yards from its shaft within which a player is at a lift (on its car, or at its landing)
Lifts.RING = 40     -- yards round a lift's shaft where its levels are looked at: one over the other, or side by side

local Travel = Core.Data.Set("Travel")
local lifts       -- every lift, while Core's set Travel stays as it is
local levels = {} -- [plane] = its levels, while the walking data stays as it is too

-- The map of the plane a world's map lies in (0 the Eastern Kingdoms, 1 Kalimdor), or nil.
local function Plane(world)
    for _, map in ipairs(Coords.Planes()) do
        if Coords.Box(map).continent == world then return map end
    end
    return nil
end

function Lifts.All()
    if lifts then return lifts end
    local list, planes = {}, {}
    for _, key in ipairs(Travel:Keys("byKind", "lift")) do
        local way = Travel:Get(key)
        local path = way and type(way.path) == "table" and way.path
        local low, high = path and path[1], path and path[2]
        if low and high and low.map and low.x and low.y and low.z and high.z and way.time and way.wait then
            if planes[low.map] == nil then planes[low.map] = Plane(low.map) or false end
            local map = planes[low.map]
            if map then
                -- The world's yards: x to the north, y to the west; the plane: u = -y, v = x.
                local lift = { kind = "lift", key = key, way = way, map = map, u = -low.y, v = low.x, time = way.time,
                               wait = way.wait, maps = {} }
                for index, point in ipairs({ low, high }) do
                    lift[index] = { name = "lift:" .. key .. ":" .. index, lift = lift, map = map, u = lift.u,
                                    v = lift.v, z = point.z }
                end
                for _, at in ipairs({ way.from or false, way.to or false }) do
                    if at and at.map then lift.maps[at.map] = true end
                end
                list[#list + 1] = lift
            end
        end
    end
    if Travel:Ready() and #Coords.Planes() > 0 then lifts = list end
    return list
end

function Lifts.Landed(point)
    if point.landed == nil then
        if not Walk.Ready() then return false end
        local tile, index, pu, pv = Walk.Landing(point.map, point.u, point.v, point.z, Lifts.LANDING)
        point.landed = tile ~= nil
        if tile then
            point.floor, point.pu, point.pv, point.region = { tile.key, index }, pu, pv, tile.region[index]
        end
    end
    return point.landed
end

-- Of sixteen points on a ring Lifts.RING yards round a lift's shaft, those on its lower level, and of those the ones
-- under its upper level.
local function Ring(lift)
    local on, under = 0, 0
    for step = 0, 15 do
        local angle = step * math.pi / 8
        local low, high
        local u, v = lift.u + Lifts.RING * math.cos(angle), lift.v + Lifts.RING * math.sin(angle)
        for _, found in ipairs(Walk.Under(lift.map, u, v)) do
            local tile, index = found[1], found[2]
            local z, region = tile.rects[index * 5] / 4, tile.region[index]
            if region == lift[1].region and (not low or z < low) then low = z end
            if region == lift[2].region and (not high or z > high) then high = z end
        end
        if low then
            on = on + 1
            if high and high > low + Walk.RISE then under = under + 1 end
        end
    end
    return on, under
end

function Lifts.Levels(map)
    local found = levels[map]
    if found then return found end
    found = {}
    local byPair = {}
    for _, lift in ipairs(Lifts.All()) do
        if lift.map == map and Lifts.Landed(lift[1]) and Lifts.Landed(lift[2]) and lift[1].region ~= lift[2].region then
            local pair = lift[1].region .. ":" .. lift[2].region
            local level = byPair[pair]
            if not level then
                level = { lower = lift[1].region, upper = lift[2].region, on = 0, under = 0, maps = {} }
                byPair[pair] = level
                found[#found + 1] = level
            end
            local on, under = Ring(lift)
            level.on, level.under = level.on + on, level.under + under
            for at in pairs(lift.maps) do level.maps[at] = true end
        end
    end
    for _, level in ipairs(found) do level.stacked = level.on > 0 and level.under * 3 >= level.on end
    if lifts and Walk.Ready() then levels[map] = found end
    return found
end

function Lifts.Joined(a, b, map)
    for _, level in ipairs(Lifts.Levels(map)) do
        if (a[level.lower] and b[level.upper]) or (a[level.upper] and b[level.lower]) then return true end
    end
    return false
end

-- The highest floor of a region in a list of floors ({ tile, index } each), or nil.
local function Top(list, region)
    local top
    for _, found in ipairs(list) do
        local tile, index = found[1], found[2]
        local z = tile.rects[index * 5] / 4
        if tile.region[index] == region and (not top or z > top) then top = z end
    end
    return top
end

-- Whether a place stands below a stacked level (Lifts' header): by its own floor's height where it is known (ownZ, of
-- the region own), else by the floors under it (under) of the level's lower region; wide (a pin on the lift's map):
-- of any other, and with none there, the nearest within Lifts.RING yards. And the region of the floor below that
-- showed it.
local function Under(map, u, v, under, level, own, ownZ, wide)
    local upper = level.upper
    local top = Top(under, upper)
    if not top then return false end
    if ownZ then return own ~= upper and top > ownZ + Walk.RISE end
    local function Below(region, z)
        return region ~= upper and (wide or region == level.lower) and z < top - Walk.RISE
    end
    for _, found in ipairs(under) do
        local tile, index = found[1], found[2]
        if Below(tile.region[index], tile.rects[index * 5] / 4) then return true, tile.region[index] end
    end
    if not wide then return false end
    local best, at, au, av, region
    Walk.Around(map, u, v, Lifts.RING, function(tile, index, nu, nv, gap)
        local z = tile.rects[index * 5] / 4
        if Below(tile.region[index], z) and (not best or gap < best) then
            best, at, au, av, region = gap, z, nu, nv, tile.region[index]
        end
    end)
    local over = best and Top(Walk.Under(map, au, av), upper)
    if over and over > at + Walk.RISE then return true, region end
    return false
end

function Lifts.Stand(map, u, v, regions, floor, reach, at)
    local list = regions and Lifts.Levels(map)
    if not list or #list == 0 then return regions, nil end
    local under = Walk.Under(map, u, v)
    if #under == 0 and reach and not floor then
        Walk.Around(map, u, v, reach, function(tile, index) under[#under + 1] = { tile, index } end)
    end
    local tile = floor and Walk.Tile(floor[1])
    local own, ownZ
    if tile and floor[2] <= tile.count then own, ownZ = tile.region[floor[2]], tile.rects[floor[2] * 5] / 4 end
    local below, drop, add
    for _, level in ipairs(list) do
        if level.stacked then
            local under_it, region = Under(map, u, v, under, level, own, ownZ, at and level.maps[at])
            if under_it then
                below, drop = below or {}, drop or {}
                below[level.upper], drop[level.upper] = true, true
                if region then
                    add = add or {}
                    add[region] = true
                end
            end
        elseif not ownZ and Top(under, level.upper) and Top(under, level.lower) then
            drop = drop or {}
            drop[level.lower] = true
        end
    end
    if not drop then return regions, nil end
    local kept
    for region in pairs(regions) do
        if not drop[region] then
            kept = kept or {}
            kept[region] = true
        end
    end
    for region in pairs(add or {}) do
        kept = kept or {}
        kept[region] = true
    end
    return kept or regions, below
end

function Lifts.Near(map, u, v, lower, upper)
    local best, at
    for _, lift in ipairs(Lifts.All()) do
        if lift.map == map and lift[1].region == lower and lift[2].region == upper then
            local gap = math.sqrt((lift.u - u) ^ 2 + (lift.v - v) ^ 2)
            if gap <= Lifts.NEAR and (not at or gap < at) then best, at = lift, gap end
        end
    end
    return best
end

-- The walking data or Core's set Travel changed: the lifts and their landings found anew.
function Lifts.Forget()
    lifts = nil
    wipe(levels)
end
