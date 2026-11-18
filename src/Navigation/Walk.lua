local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Walk
--  Where a player can walk: Core's set Walking, made from the game's own files
--  by dev/tools/walk-data. Per terrain tile a block: its floors joined into rectangles, each with
--  its height, its kind (the ground, water, a building's floor), its region (all a player can walk
--  between) and its openings into its neighbours. Knows no frames.
--
--      Walk.Ready()            the set is there
--      Walk.Tile(key)          a tile's rectangles, unpacked the first time (the game's base64,
--                              deflate and CBOR, Walk.Unpack); the Walk.KEEP asked for last kept; nil without ground
--      Walk.Links(tile)        a tile's openings, worked out the first time they are needed (looking up the
--                              floors at a place needs none)
--      Walk.Rect(tile, index)  a rectangle's column, row, width, height (samples), z, kind, region
--      Walk.Box(tile, index)   a rectangle in the plane: its left, right, top, bottom
--      Walk.Inside(tile, index, u, v), Walk.Gap(tile, index, u, v)   a point of the plane on it; how far from it
--      Walk.Under(continent, u, v)   the rectangles under a point of a continent's plane
--      Walk.Around(continent, u, v, reach, fn)   each rectangle within reach yards of a point
--      Walk.Nearest(continent, u, v, reach, region, kind)  the nearest rectangle within reach yards
--      Walk.NearestOf(continent, u, v, reach, regions)   the nearest of each of several regions, in one look
--      Walk.Regions(continent, u, v, reach)   the regions of the floors under a point and around it
--      Walk.Opening(tile, index, n), Walk.Openings(tile, index, fn)   a rectangle's openings
--      Walk.Drops(tile, index), Walk.Drop(tile, index, n)   its drops (one way down off a ledge or a cliff) and hops
--      Walk.Fall(tile, index, side, first, last, next, other)   a drop's way off and where it lands, in the plane
--      Walk.Follow(continent, u, v, key, index, fromU, fromV)   the floor a walker has come to from the one before
--      Walk.Straight(tile, index, u1, v1, u2, v2, dry)   whether a walker on a floor gets to a place going straight
--      Walk.Floor(continent, u, v, indoors, reach, height)   the floor a walker stands on where it is not followed
--      Walk.Landing(continent, u, v, z, reach)   the floor nearest a point at a height (a lift's or a portal's end, a teleport's landing)
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
--  lowest of a building's floors near them.
--
--  A drop: one way down off a rectangle's side onto a lower one (Saneroki,
--  2026-11-16: "route over mountains where you can fall down without dying"), off
--  a ledge, a cliff or a mountainside too steep to walk, the ground falling away
--  over at most 24 samples between; with its height in whole yards. The search
--  takes those up to Walk.FALL, never back up; the floor's following takes any
--  (the walker fell). A hop: over a step or a short steep stretch of a mountain's
--  trail between two floors, both ways (found from each end), with its rise; the
--  game's own triangles make a way there that the samples split. Listed with the
--  drops, marked.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Walk = {}
ns.Walk = Walk

Walk.FORMAT = 3                    -- the blocks' format (dev/tools/walk-data's FORMAT; 3: with the drops and hops)
Walk.FALL = 54                     -- yards: the highest drop a walk takes (49 metres; Saneroki, 2026-11-18: "A fall of
                                   -- 50 meters is safe", measured with /sane falls). dev/tools/walk-gates' FALL alike
Walk.SIDE = 256                    -- samples along a tile's side
Walk.SAMPLE = Coords.TILE / Walk.SIDE
Walk.KEEP = 48                     -- tiles kept unpacked: the one asked for longest ago let go
Walk.PIECE = 256                   -- rectangles of a tile's openings made between two looks at the frame's time
Walk.CELL = 16                     -- samples a side of the cells a tile's rectangles are filed in, for the looks round a place
Walk.LAND, Walk.WATER, Walk.BUILT = 1, 2, 3 -- a floor's kind: the ground, a water's surface, a building's floor
Walk.FOLLOW = 64                   -- rectangles looked at, at most, for the floor a walker has come to
Walk.STRIDE = 30                   -- yards from the walker those may lie
Walk.RAY = 256                     -- rectangles a straight walk crosses, at most (Walk.Straight)
Walk.ROOF = 6                      -- yards around a walker indoors whose floors may be theirs (their own may
                                   -- be missing right under them: a storey above, a mountain over a city)
Walk.RISE = 12                     -- yards a floor the walker cannot be followed onto may lie over or under the
                                   -- one they stood on and still be theirs
Walk.LEVEL = 3                     -- a yard up or down counts as so many across where a lift's end lands
                                   -- (dev/tools/walk-data's LEVEL): beside its shaft, not on the roof over it

local Walking = Core.Data.Set("Walking")
local open = {}   -- [tile key] = its tile, or false: no ground there
local stamps = {} -- [tile key] = when it was last asked for (a count), while it is unpacked
local kept, clock = 0, 0

-- Whether the walking data can be read now.
function Walk.Ready()
    return Walking:State() == "ready"
end

-- Whether the walking data is there at all (Core holds it, or is still reading it).
function Walk.Known()
    local state = Walking:State()
    return state == "ready" or state == "loading"
end

-- A packed field of the set (a tile's block, its gates: Gates.lua) as the game unpacks it: base64, deflate, CBOR; nil
-- for one the game cannot read (each step behind Core.Ask: a bad set file is no ground, no error).
function Walk.Unpack(text)
    local util = rawget(_G, "C_EncodingUtil")
    if not util or type(text) ~= "string" then return nil end
    local raw = Core.Ask(util.DecodeBase64, text)
    local method = rawget(_G, "Enum") and Enum.CompressionMethod and Enum.CompressionMethod.Deflate or 0
    local data = raw and Core.Ask(util.DecompressString, raw, method)
    return data and Core.Ask(util.DeserializeCBOR, data)
end

-- An opening of a rectangle: { side, first, last, where, index }; side, first and last nil for one along the whole
-- edge the two share, worked out when first used (Walk.Opening: the neighbour's tile is unpacked by then).
local function Open(list, side, first, last, where, index)
    list[#list + 1] = { side, first, last, where, index }
end

-- The rectangles of a surface that begin on one line of its tile (a column: at 2, along their rows; a row: at 1,
-- along their columns), in the order of where they begin along it, with the longest's length (Along).
local function Line(rects, list, at)
    table.sort(list, function(a, b) return rects[(a - 1) * 5 + at] < rects[(b - 1) * 5 + at] end)
    local starts, longest = {}, 0
    for k, index in ipairs(list) do
        local base = (index - 1) * 5
        starts[k] = rects[base + at]
        if rects[base + at + 2] > longest then longest = rects[base + at + 2] end
    end
    list.starts, list.longest = starts, longest
end

-- Of a line's rectangles (Line) those that share some of low to high (samples, high past the end) along it, into
-- found, in the order of their indexes; how many. Only those that begin within the longest's length before low are
-- looked at, found by halving (2026-11-18: every rectangle of the line looked at took a large tile 30 to 90 ms, in one
-- frame: card #574).
local found = {}
local function Along(rects, list, at, low, high)
    local starts = list.starts
    local from, lo, hi = low - list.longest, 1, #starts + 1
    while lo < hi do
        local middle = math.floor((lo + hi) / 2)
        if starts[middle] > from then hi = middle else lo = middle + 1 end
    end
    local count = 0
    for k = lo, #starts do
        local start = starts[k]
        if start >= high then break end
        local index = list[k]
        if start + rects[(index - 1) * 5 + at + 2] > low then
            count = count + 1
            found[count] = index
        end
    end
    for k = 2, count do
        local index, j = found[k], k - 1
        while j >= 1 and found[j] > index do
            found[j + 1] = found[j]
            j = j - 1
        end
        found[j + 1] = index
    end
    return count
end

-- The openings of two rectangles of one surface that touch: along all their shared edge (dev/tools/walk-data
-- keeps any two neighbouring samples of a surface one way). Made in the order of the rectangles, each one's east
-- neighbours, then its south ones, by their indexes; the frame given back every Walk.PIECE rectangles.
local function Touching(tile, opens, first, last)
    local rects = tile.rects
    local byWest, byNorth = {}, {}
    for index = first, last do
        local base = (index - 1) * 5
        local column, row = rects[base + 1], rects[base + 2]
        byWest[column] = byWest[column] or {}
        table.insert(byWest[column], index)
        byNorth[row] = byNorth[row] or {}
        table.insert(byNorth[row], index)
    end
    for _, list in pairs(byWest) do Line(rects, list, 2) end
    for _, list in pairs(byNorth) do Line(rects, list, 1) end
    for index = first, last do
        if index % Walk.PIECE == 0 then Core.Steps.Check() end
        local base = (index - 1) * 5
        local column, row, width, height = rects[base + 1], rects[base + 2], rects[base + 3], rects[base + 4]
        local east = byWest[column + width]
        for k = 1, east and Along(rects, east, 2, row, row + height) or 0 do
            local other = found[k]
            local o = (other - 1) * 5
            local a, b = math.max(row, rects[o + 2]), math.min(row + height, rects[o + 2] + rects[o + 4]) - 1
            Open(opens[index], 1, a, b, 0, other)
            Open(opens[other], 3, a, b, 0, index)
        end
        local south = byNorth[row + height]
        for k = 1, south and Along(rects, south, 1, column, column + width) or 0 do
            local other = found[k]
            local o = (other - 1) * 5
            local a, b = math.max(column, rects[o + 1]), math.min(column + width, rects[o + 1] + rects[o + 3]) - 1
            Open(opens[index], 2, a, b, 0, other)
            Open(opens[other], 0, a, b, 0, index)
        end
    end
end

-- A tile's block read: its surfaces (how many rectangles each, kind, region) and its rectangles (column, row, width,
-- height, z in quarter yards), each rectangle's kind, region and surface (numbered from 1 in the block's order); its
-- openings only once they are needed (Walk.Links): they take most of an unpacking's time and memory.
local function Read(tile, block)
    local surfaces, rects = block[2], block[3]
    tile.rects, tile.kind, tile.region, tile.surface, tile.links = rects, {}, {}, {}, block[4]
    tile.falls, tile.leaps = block[5], block[6]
    tile.count = #rects / 5
    local index, number = 0, 0
    for s = 1, #surfaces, 3 do
        number = number + 1
        for _ = 1, surfaces[s] do
            index = index + 1
            tile.kind[index], tile.region[index], tile.surface[index] = surfaces[s + 1], surfaces[s + 2], number
        end
    end
end

-- A tile's openings (tile.opens[index]: a rectangle's), worked out the first time they are needed: those of one
-- surface that touch (Touching), and those the block writes, once on their tile, with their other way. Its drops and
-- hops too (tile.drops[index]: { side, first, last, where, index, height } each, a hop's with its rise and true
-- after it; only of the rectangles that have any). In a job of Core's scheduler (a route's plan) the frame is given
-- back every Walk.PIECE rectangles (card #574: a large tile's took 30 to 130 ms, the collector's steps with them, in
-- one frame): the tile has them only once all are made, so what asks meanwhile (the line followed, another plan)
-- makes its own.
function Walk.Links(tile)
    if tile.opens then return tile.opens end
    local falls, leaps, links = tile.falls, tile.leaps, tile.links
    local opens, drops = {}, {}
    for at = 1, #falls, 6 do
        local rect, target = falls[at] + 1, falls[at + 4]
        drops[rect] = drops[rect] or {}
        table.insert(drops[rect], { falls[at + 1], falls[at + 2], falls[at + 3], target % 5, math.floor(target / 5) + 1,
                                    falls[at + 5] })
    end
    for at = 1, #leaps, 6 do
        local rect, target = leaps[at] + 1, leaps[at + 4]
        drops[rect] = drops[rect] or {}
        table.insert(drops[rect], { leaps[at + 1], leaps[at + 2], leaps[at + 3], target % 5, math.floor(target / 5) + 1,
                                    leaps[at + 5], true })
    end
    for index = 1, tile.count do opens[index] = {} end
    local surface, first = tile.surface, 1
    for index = 1, tile.count do
        if index == tile.count or surface[index + 1] ~= surface[index] then
            Touching(tile, opens, first, index)
            first = index + 1
        end
    end
    local at = 1
    for rect = 1, tile.count do
        if rect % Walk.PIECE == 0 then Core.Steps.Check() end
        local stop = at + links[at]
        at = at + 1
        while at <= stop do
            local value = links[at]
            local side, low, high, target
            if value < 0 then
                side, low, high, target = -1 - value, links[at + 1], links[at + 2], links[at + 3]
                at = at + 4
            else
                target = value
                at = at + 1
            end
            local where, other = target % 5, math.floor(target / 5) + 1
            Open(opens[rect], side, low, high, where, other)
            -- Written once on its own tile, from the north or west: the other way too.
            if where == 0 and opens[other] then
                if side then
                    Open(opens[other], (side + 2) % 4, low, high, 0, rect)
                else
                    Open(opens[other], nil, nil, nil, 0, rect)
                end
            end
        end
    end
    if tile.opens then return tile.opens end -- made meanwhile by what asked while this one waited
    tile.opens, tile.drops = opens, drops
    tile.falls, tile.leaps, tile.links = nil, nil, nil
    return opens
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
    local block = text and Walk.Unpack(text)
    if type(block) ~= "table" or block[1] ~= Walk.FORMAT or type(block[2]) ~= "table" or type(block[3]) ~= "table"
        or type(block[4]) ~= "table" or type(block[5]) ~= "table" or type(block[6]) ~= "table" then
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

-- A tile's rectangles filed by the cells of Walk.CELL samples a side they overlap: cells[row * the cells a side +
-- column + 1] = their indexes, in order; made the first time a place on the tile is looked up (card #574: a look
-- round a point went through every rectangle of up to 9 tiles, some 135,000, and the first plan makes dozens).
local function Cells(tile)
    local cells = tile.cells
    if cells then return cells end
    cells = {}
    local r, size = tile.rects, Walk.CELL
    local across = Walk.SIDE / size
    for index = 1, tile.count do
        local base = (index - 1) * 5
        local column, row, width, height = r[base + 1], r[base + 2], r[base + 3], r[base + 4]
        for cr = math.floor(row / size), math.floor((row + height - 1) / size) do
            for cc = math.floor(column / size), math.floor((column + width - 1) / size) do
                local cell = cr * across + cc + 1
                local list = cells[cell]
                if not list then
                    list = {}
                    cells[cell] = list
                end
                list[#list + 1] = index
            end
        end
    end
    tile.cells = cells
    return cells
end

local NONE = {}

-- The rectangles under a point: { { tile, index }, ... }, the ones on foot (the ground, a building's floor) first.
function Walk.Under(continent, u, v)
    local found = {}
    local key = Walk.Key(continent, u, v)
    local tile = key and Walk.Tile(key)
    if not tile then return found end
    local s, size = Walk.SAMPLE, Walk.CELL
    local column, row = math.floor((u - tile.left) / s), math.floor((tile.top - v) / s)
    if column < 0 or row < 0 or column >= Walk.SIDE or row >= Walk.SIDE then return found end
    local r = tile.rects
    for _, index in ipairs(Cells(tile)[math.floor(row / size) * (Walk.SIDE / size) + math.floor(column / size) + 1] or NONE) do
        local base = (index - 1) * 5
        local c, w = r[base + 1], r[base + 3]
        if column >= c and column < c + w then
            local top, h = r[base + 2], r[base + 4]
            if row >= top and row < top + h then
                if tile.kind[index] ~= Walk.WATER then table.insert(found, 1, { tile, index }) else found[#found + 1] = { tile, index } end
            end
        end
    end
    return found
end

-- The rectangles of a tile that may lie within reach yards of a point, by their cells (Cells), in order; nil where
-- that comes into half its cells or more (then all are looked at, as fast).
local function Within(tile, u, v, reach)
    local s, size, last = Walk.SAMPLE, Walk.CELL, Walk.SIDE - 1
    local across = Walk.SIDE / size
    local c0 = math.max(0, math.floor((u - reach - tile.left) / s) - 1)
    local c1 = math.min(last, math.floor((u + reach - tile.left) / s) + 1)
    local r0 = math.max(0, math.floor((tile.top - v - reach) / s) - 1)
    local r1 = math.min(last, math.floor((tile.top - v + reach) / s) + 1)
    if c0 > c1 or r0 > r1 then return NONE end
    local cc0, cc1, cr0, cr1 = math.floor(c0 / size), math.floor(c1 / size), math.floor(r0 / size), math.floor(r1 / size)
    if (cc1 - cc0 + 1) * (cr1 - cr0 + 1) * 2 >= across * across then return nil end
    local cells, r, list = Cells(tile), tile.rects, {}
    for cr = cr0, cr1 do
        for cc = cc0, cc1 do
            for _, index in ipairs(cells[cr * across + cc + 1] or NONE) do
                -- once, from the first of these cells it lies in
                local base = (index - 1) * 5
                if math.max(cc0, math.floor(r[base + 1] / size)) == cc and math.max(cr0, math.floor(r[base + 2] / size)) == cr then
                    list[#list + 1] = index
                end
            end
        end
    end
    table.sort(list)
    return list
end

-- Each rectangle within reach yards of a point (on its tile and the tiles around it that reach comes into):
-- fn(tile, index, nu, nv, gap), its nearest point to it and how far that is (0: under it). False from fn stops. In a
-- job of Core's scheduler the frame may be given back after each tile (a large one's rectangles took some 6 ms).
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
                local list = Within(tile, u, v, reach)
                for k = 1, list and #list or tile.count do
                    local index = list and list[k] or k
                    local l, r, t, b = Walk.Box(tile, index)
                    local pu, pv = math.max(l, math.min(r, u)), math.max(b, math.min(t, v))
                    local gap = (pu - u) ^ 2 + (pv - v) ^ 2
                    if gap <= most and fn(tile, index, pu, pv, math.sqrt(gap)) == false then return end
                end
                Core.Steps.Check()
            end
        end
    end
end

-- The nearest rectangle within reach yards of a point, and the nearest point of it; nil when none. region: only of
-- that region; kind: only of that kind (Walk.LAND: on foot, a building's floor too).
function Walk.Nearest(continent, u, v, reach, region, kind)
    local best, bestTile, bestIndex, bu, bv
    Walk.Around(continent, u, v, reach, function(tile, index, nu, nv, gap)
        local own = tile.kind[index]
        if (not region or tile.region[index] == region) and (not kind or own == kind or (kind == Walk.LAND and own == Walk.BUILT))
            and (not best or gap < best) then
            best, bestTile, bestIndex, bu, bv = gap, tile, index, nu, nv
        end
    end)
    if not best then return nil end
    return bestTile, bestIndex, bu, bv
end

-- Of each of several regions ({ [region] = true }) the nearest rectangle within reach yards of a point, in one look
-- round it (Walk.Nearest's for each, card #574): { [region] = { tile, index, nu, nv } }; and whether any rectangle of
-- any region lies within reach.
function Walk.NearestOf(continent, u, v, reach, regions)
    local found, best, any = {}, {}, false
    Walk.Around(continent, u, v, reach, function(tile, index, nu, nv, gap)
        any = true
        local region = tile.region[index]
        if regions[region] and (not best[region] or gap < best[region]) then
            best[region], found[region] = gap, { tile, index, nu, nv }
        end
    end)
    return found, any
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
    local opening = (tile.opens or Walk.Links(tile))[index][n]
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
    for n = 1, #(tile.opens or Walk.Links(tile))[index] do
        local side, first, last, next, other = Walk.Opening(tile, index, n)
        if side then fn(side, first, last, next, other) end
    end
end

-- A rectangle's drops and hops: { { side, first, last, where, index, height (a hop's rise), hop }, ... } (none: an
-- empty list, not to be changed).
local NONE = {}
function Walk.Drops(tile, index)
    if not tile.opens then Walk.Links(tile) end
    return tile.drops[index] or NONE
end

-- A rectangle's drop or hop n (1 to #Walk.Drops(tile, index)): its side, the first and last sample along it (on the
-- rectangle's own tile), the tile (unpacked) and index of the rectangle it lands on, its height in yards (a hop's
-- rise) and whether it is a hop; nil for one into a tile that is not there.
function Walk.Drop(tile, index, n)
    local drop = Walk.Drops(tile, index)[n]
    local next = tile
    if drop[4] > 0 then next = Walk.Tile(tile.key + STEP[drop[4] - 1]) end
    if not next or drop[5] > next.count then return nil end
    return drop[1], drop[2], drop[3], next, drop[5], drop[6], drop[7] == true
end

-- A drop in the plane: the way off (u1, v1, u2, v2: its stretch of the rectangle's side, as Walk.Portal gives it), then
-- where it lands, the same stretch moved across to the side of the rectangle landed on that faces it (where that one
-- reaches under the way off, a deck's edge over the ground: the way off itself).
function Walk.Fall(tile, index, side, first, last, next, other)
    local au, av, bu, bv = Walk.Portal(tile, index, side, first, last)
    local left, right, top, bottom = Walk.Box(next, other)
    local du, dv = 0, 0
    if side == 0 then
        dv = math.max(0, bottom - av)
    elseif side == 1 then
        du = math.max(0, left - au)
    elseif side == 2 then
        dv = math.min(0, top - av)
    else
        du = math.min(0, right - au)
    end
    return au, av, bu, bv, au + du, av + dv, bu + du, bv + dv
end

-- An opening as a segment of the plane: its two ends (u1, v1, u2, v2), from the rectangle's side.
function Walk.Portal(tile, index, side, first, last)
    local r, base = tile.rects, (index - 1) * 5
    local column, row, width, height = r[base + 1], r[base + 2], r[base + 3], r[base + 4]
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
-- (Walk.Follow's last answer): that one while the point lies on it; else, of the rectangles its openings and drops lead
-- to (and theirs, at most Walk.FOLLOW of them, within Walk.STRIDE yards of the point), the one that holds the point
-- through the openings nearest the way the walker went: the floors over and under the right one are reached through
-- openings elsewhere (a cave's mouth is not the path up the hill over it). A drop of any height: the walker fell. Gives
-- its key and index; nil when none holds it (in the air, the walker taken away, a place the data has no floor at).
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
            for n = 1, #(here.opens or Walk.Links(here))[number] do
                local side, first, last, next, other = Walk.Opening(here, number, n)
                if side and not closed[next.key * 65536 + other] and Off(next, other, u, v) <= Walk.STRIDE then
                    local au, av, bu, bv = Walk.Portal(here, number, side, first, last)
                    size = size + 1
                    tiles[size], numbers[size] = next, other
                    costs[size] = cost + Apart(au, av, bu, bv, fromU, fromV, u, v)
                end
            end
            for n = 1, #Walk.Drops(here, number) do
                local side, first, last, next, other = Walk.Drop(here, number, n)
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

-- The rectangle a line leaving rectangle index of tile through its side at (u, v) comes into: of that side's
-- openings, the one holding the point (a little past its ends counts: a line through a corner gets through); nil
-- where none does (a wall, a cliff, the data's end), or only into water where dry.
local REACH = 1e-3 -- yards past an opening's ends (and a rectangle's edges) that still count as on it
local function Through(tile, index, side, u, v, dry)
    for n = 1, #(tile.opens or Walk.Links(tile))[index] do
        local at, first, last, next, other = Walk.Opening(tile, index, n)
        if at == side and not (dry and next.kind[other] == Walk.WATER) then
            local au, av, bu, bv = Walk.Portal(tile, index, side, first, last)
            local along, low, high = u, au, bu
            if side == 1 or side == 3 then along, low, high = v, bv, av end
            if along >= low - REACH and along <= high + REACH then return next, other end
        end
    end
    return nil
end

-- Whether a walker on rectangle index of tile at (u1, v1) gets to (u2, v2) going straight: from rectangle to
-- rectangle through the openings the line crosses their edges at (so on the floor they are on, as Follow: never
-- onto the one over or under it, nor down a drop), to one that holds the end; never into water where dry; at most
-- Walk.RAY rectangles. False where the line meets an edge with no opening there, or the start does not lie on the
-- rectangle.
function Walk.Straight(tile, index, u1, v1, u2, v2, dry)
    local du, dv = u2 - u1, v2 - v1
    local length = math.sqrt(du * du + dv * dv)
    local left, right, top, bottom = Walk.Box(tile, index)
    if u1 < left - REACH or u1 > right + REACH or v1 > top + REACH or v1 < bottom - REACH then return false end
    local corner = length > 0 and REACH / length or 0
    for _ = 1, Walk.RAY do
        if u2 >= left - REACH and u2 <= right + REACH and v2 <= top + REACH and v2 >= bottom - REACH then return true end
        -- Where the line leaves the rectangle: the side ahead of it it crosses first; through a corner, either.
        local tu = du > 0 and (right - u1) / du or du < 0 and (left - u1) / du or math.huge
        local tv = dv > 0 and (top - v1) / dv or dv < 0 and (bottom - v1) / dv or math.huge
        local t = math.min(tu, tv)
        if t == math.huge then return false end
        local eu, ev = u1 + du * t, v1 + dv * t
        local next, other
        if tu <= tv + corner then next, other = Through(tile, index, du > 0 and 1 or 3, eu, ev, dry) end
        if not next and tv <= tu + corner then next, other = Through(tile, index, dv > 0 and 0 or 2, eu, ev, dry) end
        if not next then return false end
        tile, index = next, other
        left, right, top, bottom = Walk.Box(tile, index)
    end
    return false
end

-- The floor a walker stands on at a point when it cannot be followed from the one before. height: the height of the
-- floor they stood on, where one is known: then the floor within Walk.ROOF yards nearest that height, if no more than
-- Walk.RISE yards from it (none: nil; a gap in the data, likely, the walker cannot have left their height). Nothing
-- known of before: of the floors under it, outdoors the highest (nothing over the walker but the sky); indoors the
-- lowest within Walk.ROOF yards (inside a building or a cave: over the walker its upper storeys, the ground or the
-- mountain), a building's floor before any other (the game's indoors is a building's or a cave's: the ground deep
-- under a city's buildings is nobody's); none there, the nearest within reach yards. Gives its tile, its index and the
-- point of it nearest to the walker; nil when none.
function Walk.Floor(continent, u, v, indoors, reach, height)
    local best, bestIndex, bestZ, bu, bv, built
    Walk.Around(continent, u, v, (indoors or height) and Walk.ROOF or 0, function(tile, index, nu, nv)
        local z = tile.rects[index * 5] / 4
        local own = tile.kind[index] == Walk.BUILT
        local better
        if height then
            better = math.abs(z - height) <= Walk.RISE and (not bestZ or math.abs(z - height) < math.abs(bestZ - height))
        elseif indoors then
            better = not bestZ or (own and not built) or (own == built and z < bestZ)
        else
            better = not bestZ or z > bestZ
        end
        if better then best, bestIndex, bestZ, bu, bv, built = tile, index, z, nu, nv, own end
    end)
    if best or height then return best, bestIndex, bu, bv end
    return Walk.Nearest(continent, u, v, reach)
end

-- The floor nearest a point at a height (a lift's end beside its shaft, a portal's end, a teleport's landing): of
-- the floors within reach yards whose height is no more than Walk.RISE yards from it, the nearest counting both, the
-- height Walk.LEVEL times; its tile, its index and its point nearest the point. nil when none.
function Walk.Landing(continent, u, v, z, reach)
    local best, bestTile, bestIndex, bu, bv
    Walk.Around(continent, u, v, reach, function(tile, index, nu, nv, gap)
        local rise = tile.rects[index * 5] / 4 - z
        local cost = gap * gap + (Walk.LEVEL * rise) ^ 2
        if math.abs(rise) <= Walk.RISE and (not best or cost < best) then
            best, bestTile, bestIndex, bu, bv = cost, tile, index, nu, nv
        end
    end)
    if not best then return nil end
    return bestTile, bestIndex, bu, bv
end

-- Every tile let go (the route switched off, the walking data changed: Planner.lua).
function Walk.Forget()
    wipe(open)
    wipe(stamps)
    kept = 0
end
