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
--                              deflate and CBOR); the last Walk.KEEP kept; nil without ground
--      Walk.Rect(tile, index)  a rectangle's column, row, width, height (samples), z, kind, region
--      Walk.Under(continent, u, v)   the rectangles under a point of a continent's plane
--      Walk.Nearest(continent, u, v, reach)  the nearest rectangle within reach yards
--      Walk.Box(tile, index)   a rectangle in the plane: its left, right, top, bottom
--
--  A tile's samples run from its north west corner, 256 along a side (Walk.SAMPLE
--  yards each); the plane's u grows east and v north (Coords.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Walk = {}
ns.Walk = Walk

Walk.FORMAT = 1
Walk.SIDE = 256                    -- samples along a tile's side
Walk.SAMPLE = Coords.TILE / Walk.SIDE
Walk.KEEP = 48                     -- tiles kept unpacked: the oldest let go
Walk.LAND, Walk.WATER = 1, 2

local Walking = Core.Data.Set("Walking")
local open = {}  -- [tile key] = its tile, or false: no ground there
local order = {} -- the keys unpacked, oldest first

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
-- edge the two share, worked out when first used (Walk.Openings: the neighbour's tile is unpacked by then).
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

-- A tile's rectangles and openings, unpacked; nil where it has no ground (or the data is not there yet).
function Walk.Tile(key)
    local tile = open[key]
    if tile ~= nil then return tile or nil end
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
    order[#order + 1] = key
    if #order > Walk.KEEP then
        local old = table.remove(order, 1)
        open[old] = nil
    end
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

-- The nearest rectangle within reach yards of a point (on its tile and the tiles around it), and the nearest
-- point of it; nil when none. region: only of that region.
function Walk.Nearest(continent, u, v, reach, region)
    local best, bestTile, bestIndex, bu, bv
    local key = Walk.Key(continent, u, v)
    if not key then return nil end
    for dr = -1, 1 do
        for dc = -1, 1 do
            local tile = Walk.Tile(key + dr * 64 + dc)
            if tile then
                for index = 1, tile.count do
                    if not region or tile.region[index] == region then
                        local left, right, top, bottom = Walk.Box(tile, index)
                        local nu, nv = math.max(left, math.min(right, u)), math.max(bottom, math.min(top, v))
                        local gap = (nu - u) ^ 2 + (nv - v) ^ 2
                        if gap <= reach * reach and (not best or gap < best) then
                            best, bestTile, bestIndex, bu, bv = gap, tile, index, nu, nv
                        end
                    end
                end
            end
        end
    end
    if not best then return nil end
    return bestTile, bestIndex, bu, bv
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

-- A rectangle's openings: fn(side, first, last, tile, index) for each, the neighbour's tile unpacked (an opening
-- into a tile not there is passed over). first and last count along the side on the rectangle's own tile.
local STEP = { [0] = -64, [1] = 1, [2] = 64, [3] = -1 } -- the next tile north, east, south, west
local OFFSET = { [0] = { -1, 0 }, [1] = { 0, 1 }, [2] = { 1, 0 }, [3] = { 0, -1 } } -- its rows, columns away
function Walk.Openings(tile, index, fn)
    for _, opening in ipairs(tile.opens[index]) do
        local side, first, last, where, other = opening[1], opening[2], opening[3], opening[4], opening[5]
        local next = tile
        if where > 0 then next = Walk.Tile(tile.key + STEP[where - 1]) end
        if next and other <= next.count then
            if not first then
                local dr, dc = 0, 0
                if where > 0 then
                    side = where - 1
                    dr, dc = OFFSET[side][1], OFFSET[side][2]
                else
                    side = Side(tile, index, other)
                end
                first, last = Shared(tile, index, next, other, side, dr, dc)
                opening[1], opening[2], opening[3] = side, first, last
            end
            if first then fn(side, first, last, next, other) end
        end
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

-- Every tile let go (the route is off, or a test begins).
function Walk.Forget()
    wipe(open)
    wipe(order)
end
