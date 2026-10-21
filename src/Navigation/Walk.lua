local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Walk
--  Where a player can walk: Core's set Walking (pack Routes, loaded when the
--  first route is asked for), made from the game's own files by dev/tools/walk-
--  data. Per terrain tile a block: its floors joined into rectangles, each with
--  its height, its kind (land or water), its region (all a player can walk
--  between) and its openings into its neighbours. Knows no frames.
--
--      Walk.Ready()            the set is there (asked for, loaded soon, if not)
--      Walk.Tile(key)          a tile's rectangles, unpacked the first time (the game's base64,
--                              deflate and CBOR); the Walk.KEEP asked for last kept; nil without ground
--      Walk.Rect(tile, index)  a rectangle's column, row, width, height (samples), z, kind, region
--      Walk.Box(tile, index)   a rectangle in the plane: its left, right, top, bottom
--      Walk.Inside(tile, index, u, v), Walk.Gap(tile, index, u, v)   a point of the plane on it; how far from it
--      Walk.Under(continent, u, v)   the rectangles under a point of a continent's plane
--      Walk.Around(continent, u, v, reach, fn)   each rectangle within reach yards of a point
--      Walk.Nearest(continent, u, v, reach, region, kind)  the nearest rectangle within reach yards
--      Walk.Regions(continent, u, v, reach)   the regions of the floors under a point and around it
--      Walk.Opening(tile, index, n), Walk.Openings(tile, index, fn)   a rectangle's openings
--      Walk.Follow(continent, u, v, key, index, fromU, fromV)   the floor a walker has come to from the one before
--      Walk.Floor(continent, u, v, indoors, reach, height)   the floor a walker stands on where it is not followed
--
--  A tile's samples run from its north west corner, 256 along a side (Walk.SAMPLE
--  yards each); the plane's u grows east and v north (Coords.lua).
--
--  Floors lie one over the other (a cave under a hill, a building's storeys, a
--  city in a mountain), and the game tells no height of the player (UnitPosition's
--  is always 0). So the floor a walker stands on is followed as they go: from the
--  rectangle they stood on through the openings nearest the way they went to the
--  one that holds them now (Follow); where it cannot be, it is chosen (Floor): near
--  the height they had, else outdoors the highest floor under them, indoors the
--  lowest near them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Walk = {}
ns.Walk = Walk

Walk.FORMAT = 1
Walk.SIDE = 256                    -- samples along a tile's side
Walk.SAMPLE = Coords.TILE / Walk.SIDE
Walk.KEEP = 48                     -- tiles kept unpacked: the one asked for longest ago let go
Walk.LAND, Walk.WATER = 1, 2
Walk.FOLLOW = 64                   -- rectangles looked at, at most, for the floor a walker has come to
Walk.STRIDE = 30                   -- yards from the walker those may lie
Walk.ROOF = 6                      -- yards around a walker indoors whose floors may be theirs (their own may
                                   -- be missing right under them: a storey above, a mountain over a city)
Walk.RISE = 12                     -- yards a floor the walker cannot be followed onto may lie over or under the
                                   -- one they stood on and still be theirs

local Walking = Core.Data.Set("Walking")
local open = {}   -- [tile key] = its tile, or false: no ground there
local stamps = {} -- [tile key] = when it was last asked for (a count), while it is unpacked
local kept, clock = 0, 0

-- Whether the walking data can be read now; asked for when not (its pack loads soon after).
function Walk.Ready()
    local state = Walking:State()
    if state == "ready" then return true end
    if state == "idle" or state == "loading" then Core.Data.Prepare("Walking") end
    return false
end

-- Whether the walking data is there at all (its pack installed and switched on).
function Walk.Known()
    local state = Walking:State()
    return state == "ready" or state == "idle" or state == "loading"
end

local function Unpack(text)
    local util = rawget(_G, "C_EncodingUtil")
    if not util or type(text) ~= "string" then return nil end
    local raw = util.DecodeBase64(text)
    local method = rawget(_G, "Enum") and Enum.CompressionMethod and Enum.CompressionMethod.Deflate or 0
    local data = raw and util.DecompressString(raw, method)
    return data and util.DeserializeCBOR(data)
end

-- An opening of a rectangle: { side, first, last, where, index }; side, first and last nil for one along the whole
-- edge the two share, worked out when first used (Walk.Opening: the neighbour's tile is unpacked by then).
local function Open(list, side, first, last, where, index)
    list[#list + 1] = { side, first, last, where, index }
end

-- The openings of two rectangles of one surface that touch: along all their shared edge (dev/tools/walk-data
-- keeps any two neighbouring samples of a surface one way).
local function Touching(tile, first, last)
    local rects, opens = tile.rects, tile.opens
    local byWest, byNorth = {}, {}
    for index = first, last do
        local base = (index - 1) * 5
        local column, row = rects[base + 1], rects[base + 2]
        byWest[column] = byWest[column] or {}
        table.insert(byWest[column], index)
        byNorth[row] = byNorth[row] or {}
        table.insert(byNorth[row], index)
    end
    for index = first, last do
        local base = (index - 1) * 5
        local column, row, width, height = rects[base + 1], rects[base + 2], rects[base + 3], rects[base + 4]
        for _, other in ipairs(byWest[column + width] or {}) do
            local o = (other - 1) * 5
            local a, b = math.max(row, rects[o + 2]), math.min(row + height, rects[o + 2] + rects[o + 4]) - 1
            if a <= b then
                Open(opens[index], 1, a, b, 0, other)
                Open(opens[other], 3, a, b, 0, index)
            end
        end
        for _, other in ipairs(byNorth[row + height] or {}) do
            local o = (other - 1) * 5
            local a, b = math.max(column, rects[o + 1]), math.min(column + width, rects[o + 1] + rects[o + 3]) - 1
            if a <= b then
                Open(opens[index], 2, a, b, 0, other)
                Open(opens[other], 0, a, b, 0, index)
            end
        end
    end
end

-- A tile's block read: its surfaces (how many rectangles each, kind, region), its rectangles (column, row, width,
-- height, z in quarter yards) and their openings; those of one surface that touch are worked out (Touching),
-- those written once on their tile get their other way.
local function Read(tile, block)
    local surfaces, rects, links = block[2], block[3], block[4]
    tile.rects, tile.kind, tile.region, tile.opens = rects, {}, {}, {}
    tile.count = #rects / 5
    for index = 1, tile.count do tile.opens[index] = {} end
    local index = 0
    for s = 1, #surfaces, 3 do
        local first = index + 1
        for _ = 1, surfaces[s] do
            index = index + 1
            tile.kind[index], tile.region[index] = surfaces[s + 1], surfaces[s + 2]
        end
        Touching(tile, first, index)
    end
    local at = 1
    for rect = 1, tile.count do
        local stop = at + links[at]
        at = at + 1
        while at <= stop do
            local value = links[at]
            local side, first, last, target
            if value < 0 then
                side, first, last, target = -1 - value, links[at + 1], links[at + 2], links[at + 3]
                at = at + 4
            else
                target = value
                at = at + 1
            end
            local where, other = target % 5, math.floor(target / 5) + 1
            Open(tile.opens[rect], side, first, last, where, other)
            -- Written once on its own tile, from the north or west: the other way too.
            if where == 0 and tile.opens[other] then
                if side then
                    Open(tile.opens[other], (side + 2) % 4, first, last, 0, rect)
                else
                    Open(tile.opens[other], nil, nil, nil, 0, rect)
                end
            end
        end
    end
end

-- The tile asked for longest ago let go, once more than Walk.KEEP are unpacked.
local function Trim()
    while kept > Walk.KEEP do
        local oldest, at
        for key, stamp in pairs(stamps) do
            if not at or stamp < at then oldest, at = key, stamp end
        end
        open[oldest], stamps[oldest] = nil, nil
        kept = kept - 1
    end
end

-- A tile's rectangles and openings, unpacked; nil where it has no ground (or the data is not there yet). Each ask
-- keeps it among the last asked for, so the tiles a route and the player's place need stay. In a job of Core's
-- scheduler (a plan, Planner.lua) an unpacking may end the frame's time: the job goes on in the next frame.
function Walk.Tile(key)
    local tile = open[key]
    if tile ~= nil then
        if tile then
            clock = clock + 1
            stamps[key] = clock
        end
        return tile or nil
    end
    if not Walk.Ready() then return nil end
    local text = Walking:Get(key, "block")
    local block = text and Unpack(text)
    if type(block) ~= "table" or block[1] ~= Walk.FORMAT or type(block[2]) ~= "table" or type(block[3]) ~= "table"
        or type(block[4]) ~= "table" then
        open[key] = false
        return nil
    end
    local continent = math.floor(key / 4096)
    local rest = key % 4096
    tile = { key = key, continent = continent, row = math.floor(rest / 64), column = rest % 64 }
    Read(tile, block)
    tile.left, tile.top = Coords.Corner(tile.column, tile.row)
    open[key] = tile
    clock, kept = clock + 1, kept + 1
    stamps[key] = clock
    Trim()
    Core.Steps.Check()
    return tile
end

-- A rectangle (index from 1): column, row, width, height in samples, z in yards, kind, region.
function Walk.Rect(tile, index)
    local base = (index - 1) * 5
    local r = tile.rects
    return r[base + 1], r[base + 2], r[base + 3], r[base + 4], r[base + 5] / 4, tile.kind[index], tile.region[index]
end

-- A rectangle in the plane: left, right, top, bottom (u grows east, v north).
function Walk.Box(tile, index)
    local column, row, width, height = Walk.Rect(tile, index)
    local s = Walk.SAMPLE
    return tile.left + column * s, tile.left + (column + width) * s, tile.top - row * s, tile.top - (row + height) * s
end

-- Whether a point of the plane lies on a rectangle (its edges count).
function Walk.Inside(tile, index, u, v)
    local left, right, top, bottom = Walk.Box(tile, index)
    return u >= left and u <= right and v <= top and v >= bottom
end

-- The tile key of a point of a continent's plane (its continent's instance number, as the set keys them).
function Walk.Key(continent, u, v)
    local box = Coords.Box(continent)
    if not box then return nil end
    local column, row = Coords.Tile(u, v)
    if column < 0 or row < 0 or column >= Coords.GRID or row >= Coords.GRID then return nil end
    return Coords.TileKey(box.continent, column, row)
end

-- The rectangles under a point: { { tile, index }, ... }, land first.
function Walk.Under(continent, u, v)
    local found = {}
    local key = Walk.Key(continent, u, v)
    local tile = key and Walk.Tile(key)
    if not tile then return found end
    local s = Walk.SAMPLE
    local column, row = math.floor((u - tile.left) / s), math.floor((tile.top - v) / s)
    local r = tile.rects
    for index = 1, tile.count do
        local base = (index - 1) * 5
        local c, w = r[base + 1], r[base + 3]
        if column >= c and column < c + w then
            local top, h = r[base + 2], r[base + 4]
            if row >= top and row < top + h then
                if tile.kind[index] == Walk.LAND then table.insert(found, 1, { tile, index }) else found[#found + 1] = { tile, index } end
            end
        end
    end
    return found
end

-- Each rectangle within reach yards of a point (on its tile and the tiles around it that reach comes into):
-- fn(tile, index, nu, nv, gap), its nearest point to it and how far that is (0: under it). False from fn stops.
function Walk.Around(continent, u, v, reach, fn)
    local key = Walk.Key(continent, u, v)
    if not key then return end
    local column, row = Coords.Tile(u, v)
    local most = reach * reach
    for dr = -1, 1 do
        for dc = -1, 1 do
            local left, top = Coords.Corner(column + dc, row + dr)
            local nu = math.max(left, math.min(left + Coords.TILE, u))
            local nv = math.max(top - Coords.TILE, math.min(top, v))
            local inside = column + dc >= 0 and column + dc < Coords.GRID and row + dr >= 0 and row + dr < Coords.GRID
            local tile = inside and (nu - u) ^ 2 + (nv - v) ^ 2 <= most and Walk.Tile(key + dr * 64 + dc)
            if tile then
                for index = 1, tile.count do
                    local l, r, t, b = Walk.Box(tile, index)
                    local pu, pv = math.max(l, math.min(r, u)), math.max(b, math.min(t, v))
                    local gap = (pu - u) ^ 2 + (pv - v) ^ 2
                    if gap <= most and fn(tile, index, pu, pv, math.sqrt(gap)) == false then return end
                end
            end
        end
    end
end

-- The nearest rectangle within reach yards of a point, and the nearest point of it; nil when none. region: only of
-- that region; kind: only of that kind.
function Walk.Nearest(continent, u, v, reach, region, kind)
    local best, bestTile, bestIndex, bu, bv
    Walk.Around(continent, u, v, reach, function(tile, index, nu, nv, gap)
        if (not region or tile.region[index] == region) and (not kind or tile.kind[index] == kind)
            and (not best or gap < best) then
            best, bestTile, bestIndex, bu, bv = gap, tile, index, nu, nv
        end
    end)
    if not best then return nil end
    return bestTile, bestIndex, bu, bv
end

-- The regions of the floors under a point and within reach yards of it: { [region] = true }, nil when there are none
-- (a place nobody can walk to, or no data there).
function Walk.Regions(continent, u, v, reach)
    local regions
    Walk.Around(continent, u, v, reach, function(tile, index)
        regions = regions or {}
        regions[tile.region[index]] = true
    end)
    return regions
end

-- The first and last sample of the edge two rectangles share on a side of a (b on the tile dr, dc tiles away, on
-- a's grid), or nil.
local function Shared(tile, index, other, otherIndex, side, dr, dc)
    local a, b = (index - 1) * 5, (otherIndex - 1) * 5
    local ra, rb = tile.rects, other.rects
    local bc, br = rb[b + 1] + dc * Walk.SIDE, rb[b + 2] + dr * Walk.SIDE
    local first, last
    if side == 0 or side == 2 then
        first, last = math.max(ra[a + 1], bc), math.min(ra[a + 1] + ra[a + 3], bc + rb[b + 3]) - 1
    else
        first, last = math.max(ra[a + 2], br), math.min(ra[a + 2] + ra[a + 4], br + rb[b + 4]) - 1
    end
    if first > last then return nil end
    return first, last
end

-- Which side of a rectangle another of its tile touches: 0 north, 1 east, 2 south, 3 west.
local function Side(tile, index, otherIndex)
    local r, a, b = tile.rects, (index - 1) * 5, (otherIndex - 1) * 5
    if r[b + 2] + r[b + 4] == r[a + 2] then return 0 end
    if r[b + 1] == r[a + 1] + r[a + 3] then return 1 end
    if r[b + 2] == r[a + 2] + r[a + 4] then return 2 end
    return 3
end

-- A rectangle's opening n (1 to #tile.opens[index]): its side, the first and last sample along it (on the
-- rectangle's own tile), the neighbour's tile (unpacked) and index; nil for one into a tile that is not there, or
-- that shares no edge. Asked for one by one, so a search makes no function for each rectangle it looks at.
local STEP = { [0] = -64, [1] = 1, [2] = 64, [3] = -1 } -- the next tile north, east, south, west
local OFFSET = { [0] = { -1, 0 }, [1] = { 0, 1 }, [2] = { 1, 0 }, [3] = { 0, -1 } } -- its rows, columns away
function Walk.Opening(tile, index, n)
    local opening = tile.opens[index][n]
    local side, first, last, where, other = opening[1], opening[2], opening[3], opening[4], opening[5]
    local next = tile
    if where > 0 then next = Walk.Tile(tile.key + STEP[where - 1]) end
    if not next or other > next.count then return nil end
    if not first then
        local dr, dc = 0, 0
        if where > 0 then
            side = where - 1
            dr, dc = OFFSET[side][1], OFFSET[side][2]
        else
            side = Side(tile, index, other)
        end
        first, last = Shared(tile, index, next, other, side, dr, dc)
        if not first then return nil end
        opening[1], opening[2], opening[3] = side, first, last
    end
    return side, first, last, next, other
end

-- A rectangle's openings: fn(side, first, last, tile, index) for each, the neighbour's tile unpacked (an opening
-- into a tile not there is passed over). first and last count along the side on the rectangle's own tile.
function Walk.Openings(tile, index, fn)
    for n = 1, #tile.opens[index] do
        local side, first, last, next, other = Walk.Opening(tile, index, n)
        if side then fn(side, first, last, next, other) end
    end
end

-- An opening as a segment of the plane: its two ends (u1, v1, u2, v2), from the rectangle's side.
function Walk.Portal(tile, index, side, first, last)
    local column, row, width, height = Walk.Rect(tile, index)
    local s = Walk.SAMPLE
    if side == 0 or side == 2 then
        local v = tile.top - (side == 0 and row or row + height) * s
        return tile.left + first * s, v, tile.left + (last + 1) * s, v
    end
    local u = tile.left + (side == 1 and column + width or column) * s
    return u, tile.top - first * s, u, tile.top - (last + 1) * s
end

-- How far a point of the plane is from a rectangle (0 on it).
function Walk.Gap(tile, index, u, v)
    local left, right, top, bottom = Walk.Box(tile, index)
    local du = u < left and left - u or u > right and u - right or 0
    local dv = v > top and v - top or v < bottom and bottom - v or 0
    return math.sqrt(du * du + dv * dv)
end
local Off = Walk.Gap

-- How far a point is from a segment.
local function ToSegment(u, v, au, av, bu, bv)
    local du, dv = bu - au, bv - av
    local length = du * du + dv * dv
    local t = length > 0 and math.max(0, math.min(1, ((u - au) * du + (v - av) * dv) / length)) or 0
    return math.sqrt((u - au - du * t) ^ 2 + (v - av - dv * t) ^ 2)
end

-- Which way a point lies of the line from p to q (> 0 left of it, < 0 right, 0 on it).
local function Turn(pu, pv, qu, qv, ru, rv)
    return (qu - pu) * (rv - pv) - (qv - pv) * (ru - pu)
end

-- How far two segments are from each other (0 where they cross).
local function Apart(au, av, bu, bv, cu, cv, du, dv)
    local d1, d2 = Turn(cu, cv, du, dv, au, av), Turn(cu, cv, du, dv, bu, bv)
    local d3, d4 = Turn(au, av, bu, bv, cu, cv), Turn(au, av, bu, bv, du, dv)
    if d1 * d2 <= 0 and d3 * d4 <= 0 and (d1 ~= 0 or d2 ~= 0) then return 0 end
    return math.min(ToSegment(au, av, cu, cv, du, dv), ToSegment(bu, bv, cu, cv, du, dv),
        ToSegment(cu, cv, au, av, bu, bv), ToSegment(du, dv, au, av, bu, bv))
end

-- The floor a walker stands on at a point (u, v), who stood on rectangle index of tile key at (fromU, fromV) before
-- (Walk.Follow's last answer): that one while the point lies on it; else, of the rectangles its openings lead to (and
-- theirs, at most Walk.FOLLOW of them, within Walk.STRIDE yards of the point), the one that holds the point through
-- the openings nearest the way the walker went: the floors over and under the right one are reached through openings
-- elsewhere (a cave's mouth is not the path up the hill over it). Gives its key and index; nil when none holds it (a
-- jump down, the walker taken away, a place the data has no floor at).
local tiles, numbers, costs, closed = {}, {}, {}, {} -- reused: asked for while the player moves
local function Clean(size)
    for n = 1, size do tiles[n], numbers[n], costs[n] = nil, nil, nil end
end
function Walk.Follow(continent, u, v, key, index, fromU, fromV)
    local tile = Walk.Tile(key)
    if not tile or index > tile.count then return nil end
    if Walk.Inside(tile, index, u, v) then return key, index end
    fromU, fromV = fromU or u, fromV or v
    wipe(closed)
    tiles[1], numbers[1], costs[1] = tile, index, 0
    local size, looked = 1, 0
    while size > 0 and looked < Walk.FOLLOW do
        local at = 1
        for n = 2, size do
            if costs[n] < costs[at] then at = n end
        end
        local here, number, cost = tiles[at], numbers[at], costs[at]
        tiles[at], numbers[at], costs[at] = tiles[size], numbers[size], costs[size]
        tiles[size], numbers[size], costs[size] = nil, nil, nil
        size = size - 1
        local id = here.key * 65536 + number
        if not closed[id] then
            closed[id] = true
            looked = looked + 1
            if looked > 1 and Walk.Inside(here, number, u, v) then
                Clean(size)
                return here.key, number
            end
            for n = 1, #here.opens[number] do
                local side, first, last, next, other = Walk.Opening(here, number, n)
                if side and not closed[next.key * 65536 + other] and Off(next, other, u, v) <= Walk.STRIDE then
                    local au, av, bu, bv = Walk.Portal(here, number, side, first, last)
                    size = size + 1
                    tiles[size], numbers[size] = next, other
                    costs[size] = cost + Apart(au, av, bu, bv, fromU, fromV, u, v)
                end
            end
        end
    end
    Clean(size)
    return nil
end

-- The floor a walker stands on at a point when it cannot be followed from the one before. height: the height of the
-- floor they stood on, where one is known: then the floor within Walk.ROOF yards nearest that height, if no more than
-- Walk.RISE yards from it (none: nil; a gap in the data, likely, the walker cannot have left their height). Nothing
-- known of before: of the floors under it, outdoors the highest (nothing over the walker but the sky); indoors the
-- lowest within Walk.ROOF yards (inside a building or a cave: over the walker its upper storeys, the ground or the
-- mountain); none there, the nearest within reach yards. Gives its tile, its index and the point of it nearest to the
-- walker; nil when none.
function Walk.Floor(continent, u, v, indoors, reach, height)
    local best, bestIndex, bestZ, bu, bv
    Walk.Around(continent, u, v, (indoors or height) and Walk.ROOF or 0, function(tile, index, nu, nv)
        local z = tile.rects[index * 5] / 4
        local better
        if height then
            better = math.abs(z - height) <= Walk.RISE and (not bestZ or math.abs(z - height) < math.abs(bestZ - height))
        else
            better = not bestZ or (indoors and z < bestZ) or (not indoors and z > bestZ)
        end
        if better then best, bestIndex, bestZ, bu, bv = tile, index, z, nu, nv end
    end)
    if best or height then return best, bestIndex, bu, bv end
    return Walk.Nearest(continent, u, v, reach)
end

-- Every tile let go (the route is off, or a test begins).
function Walk.Forget()
    wipe(open)
    wipe(stamps)
    kept = 0
end
