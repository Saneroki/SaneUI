local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Gates
--  The coarse layer over the walking data (Core's set Walking, its field gates,
--  made by dev/tools/walk-gates from the tiles' blocks): per terrain tile its
--  gates, the stretches of its borders where one walks across into the next
--  tile (one for each part of the tile that meets a part of the next one there,
--  at most a quarter of the border long), and what the walk between each two
--  gates of one part costs inside the tile. A part: the rectangles of a tile one
--  can walk between without leaving it. Search.lua crosses the tiles between a
--  walk's start and its end by their gates. Knows no frames.
--
--      Gates.Tile(key)              a tile's gates, unpacked the first time (Walk.Unpack); the Gates.KEEP asked for
--                                   last kept; nil where the tile has none (no ground, or the layer is not there)
--      Gates.Cost(gates, a, b, water)   what the walk from gate a to gate b of one part costs, in yards on land
--      Gates.Ends(id)               the two tiles a gate lies between (north or west first), its side on the first
--      Gates.Parts(tile)            each rectangle's part on a walking tile (Walk.Tile's)
--      Gates.Edges(tile, side)      the rectangles of a walking tile with an opening across one of its sides
--
--  A tile's gates: count; per gate (1 to count: the north side's in order along
--  it, then the east's, the south's, the west's) its side, first and last sample
--  along the side (from its west or north end), part, point (u, v: the middle of
--  its stretch on the border) and number among all (id: Gates.Id, the same on
--  both its tiles); byId, bySide; rects: how many rectangles the block it was made
--  from has (another number: made from another block, its parts not to be
--  trusted on this one).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Walk = ns.Coords, ns.Walk
local Gates = {}
ns.Gates = Gates

Gates.FORMAT = 1
Gates.KEEP = 400      -- tiles' gates kept unpacked (some 16 KB each): the one asked for longest ago let go
Gates.CLIMB = 0.25    -- each yard up costs so many yards more (Search.CLIMB)

local Walking = Core.Data.Set("Walking")
local open = {}   -- [tile key] = its gates, or false: none
local stamps = {} -- [tile key] = when it was last asked for (a count), while unpacked
local kept, clock = 0, 0
local SIDE = 256  -- samples along a tile's side (Walk.SIDE)

-- A border's number: of the tile north or west of it, twice its key, and 1 for that tile's south side.
local function Border(key, side)
    if side == 1 then return key * 2 end
    if side == 2 then return key * 2 + 1 end
    if side == 0 then return (key - 64) * 2 + 1 end
    return (key - 1) * 2
end

-- A gate's number among all: its border's and its place along the border (from 1, as both its tiles list it).
function Gates.Id(key, side, place)
    return (Border(key, side) + 1) * 1024 + place
end

-- The two tiles a gate lies between, the north or west one first, and the side of that one it lies on (1 east, 2
-- south).
function Gates.Ends(id)
    local border = math.floor(id / 1024) - 1
    local key = math.floor(border / 2)
    if border % 2 == 1 then return key, key + 64, 2 end
    return key, key + 1, 1
end

-- A tile's field read (dev/tools/walk-gates): its gates, side by side, and its parts' costs: per part its gates, then
-- one number for each two of them in order (1 and 2, 1 and 3, ..., 2 and 3, ...), then the ways a rider takes instead
-- (the pair, that way's number).
local function Read(key, block)
    local rest = key % 4096
    local left, top = Coords.Corner(rest % 64, math.floor(rest / 64))
    local s = Walk.SAMPLE
    local gates = { key = key, rects = block[3], side = {}, first = {}, last = {}, part = {}, u = {}, v = {}, id = {},
                    byId = {}, bySide = { [0] = {}, {}, {}, {} }, group = {}, at = {}, costs = block[8] }
    local n = 0
    for side = 0, 3 do
        local list = block[side + 4]
        local place = 0
        for at = 1, #list, 3 do
            n, place = n + 1, place + 1
            local first, last = list[at], list[at + 1]
            gates.side[n], gates.first[n], gates.last[n], gates.part[n] = side, first, last, list[at + 2]
            local middle = (first + last + 1) / 2
            if side == 0 then
                gates.u[n], gates.v[n] = left + middle * s, top
            elseif side == 1 then
                gates.u[n], gates.v[n] = left + SIDE * s, top - middle * s
            elseif side == 2 then
                gates.u[n], gates.v[n] = left + middle * s, top - SIDE * s
            else
                gates.u[n], gates.v[n] = left, top - middle * s
            end
            local id = Gates.Id(key, side, place)
            gates.id[n], gates.byId[id] = id, n
            table.insert(gates.bySide[side], n)
        end
    end
    gates.count = n
    -- Each part: a group of its gates (group.gates, in order; at: a gate's place in its group), where its costs begin
    -- (base), and the rider's ways (ride: [pair] = that way's number).
    local costs, at = block[8], 1
    while at <= #costs do
        local size = costs[at]
        local group = { size = size, gates = {}, base = at + size }
        for x = 1, size do
            local g = costs[at + x]
            group.gates[x] = g
            gates.group[g], gates.at[g] = group, x
        end
        at = at + size + 1 + size * (size - 1) / 2
        local ride = costs[at]
        if ride > 0 then
            group.ride = {}
            for e = 1, ride do group.ride[costs[at + 2 * e - 1]] = costs[at + 2 * e] end
        end
        at = at + 1 + 2 * ride
    end
    return gates
end

-- The tile asked for longest ago let go, once more than Gates.KEEP are unpacked.
local function Trim()
    while kept > Gates.KEEP do
        local oldest, when
        for key, stamp in pairs(stamps) do
            if not when or stamp < when then oldest, when = key, stamp end
        end
        open[oldest], stamps[oldest] = nil, nil
        kept = kept - 1
    end
end

-- A tile's gates, unpacked; nil where it has none (no ground, the layer not there, or of another format).
function Gates.Tile(key)
    local gates = open[key]
    if gates ~= nil then
        if gates then
            clock = clock + 1
            stamps[key] = clock
        end
        return gates or nil
    end
    if not Walk.Ready() then return nil end
    local text = Walking:Get(key, "gates")
    local block = text and Walk.Unpack(text)
    if type(block) ~= "table" or block[1] ~= Gates.FORMAT or type(block[8]) ~= "table" then
        open[key] = false
        return nil
    end
    gates = Read(key, block)
    open[key] = gates
    clock, kept = clock + 1, kept + 1
    stamps[key] = clock
    Trim()
    return gates
end

-- What a way's number holds: its yards on land, climbed, gone down and swum (land + 2^13 x up + 2^23 x down + 2^33 x
-- swum, each whole).
local function Way(number)
    local land = number % 8192
    number = (number - land) / 8192
    local up = number % 1024
    number = (number - up) / 1024
    local down = number % 1024
    return land, up, down, (number - down) / 1024
end

-- What the walk from gate a to gate b (of one part of a tile) costs, in yards on land: its yards, a yard swum at the
-- walker's price (water), each yard up Gates.CLIMB more; of the way on foot and the one a rider takes instead (where
-- the one on foot swims), the cheaper.
function Gates.Cost(gates, a, b, water)
    local group = gates.group[a]
    local x, y = gates.at[a], gates.at[b]
    local forward = x < y
    if not forward then x, y = y, x end
    local pair = (x - 1) * (2 * group.size - x) / 2 + (y - x)
    local land, up, down, swum = Way(gates.costs[group.base + pair])
    local cost = land + water * swum + Gates.CLIMB * (forward and up or down)
    local other = group.ride and group.ride[pair]
    if other then
        land, up, down, swum = Way(other)
        other = land + water * swum + Gates.CLIMB * (forward and up or down)
        if other < cost then cost = other end
    end
    return cost
end

-- Each rectangle's part on a walking tile: the rectangles one can walk between on the tile, numbered by the lowest
-- of their surfaces (as dev/tools/walk-gates numbers them). Worked out once a tile.
function Gates.Parts(tile)
    local parts = tile.parts
    if parts then return parts end
    local surface, parent, opens = tile.surface, {}, tile.opens or Walk.Links(tile)
    local function Find(x)
        local root = x
        while parent[root] do root = parent[root] end
        while parent[x] and parent[x] ~= root do
            local up = parent[x]
            parent[x] = root
            x = up
        end
        return root
    end
    for index = 1, tile.count do
        local list, a = opens[index], surface[index]
        for n = 1, #list do
            local o = list[n]
            if o[4] == 0 and surface[o[5]] ~= a then
                local ra, rb = Find(a), Find(surface[o[5]])
                if ra < rb then parent[rb] = ra elseif rb < ra then parent[ra] = rb end
            end
        end
    end
    parts = {}
    for index = 1, tile.count do parts[index] = Find(surface[index]) end
    tile.parts = parts
    return parts
end

-- The rectangles of a walking tile with an opening across one of its sides, flat: index, first, last (samples along
-- the side; an opening along a rectangle's whole edge, that edge). Worked out once a tile and side.
function Gates.Edges(tile, side)
    tile.edges = tile.edges or {}
    local list = tile.edges[side]
    if list then return list end
    list = {}
    local r, all = tile.rects, tile.opens or Walk.Links(tile)
    for index = 1, tile.count do
        local opens = all[index]
        for n = 1, #opens do
            local o = opens[n]
            if o[4] == side + 1 then
                local first, last = o[2], o[3]
                if not first then
                    local base = (index - 1) * 5
                    if side == 0 or side == 2 then
                        first, last = r[base + 1], r[base + 1] + r[base + 3] - 1
                    else
                        first, last = r[base + 2], r[base + 2] + r[base + 4] - 1
                    end
                end
                list[#list + 1], list[#list + 2], list[#list + 3] = index, first, last
            end
        end
    end
    tile.edges[side] = list
    return list
end

-- Every tile's gates let go (the walking data changed, the route switched off).
function Gates.Forget()
    wipe(open)
    wipe(stamps)
    kept = 0
end
