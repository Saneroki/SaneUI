local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Search
--  A walk from one point of a plane to another over the walking data (Walk.lua):
--  the rectangles from the floor the start stands on to a floor at the end,
--  through their openings, the shortest by A* (each step costs the way from where
--  the rectangle was entered to where the straight line on to the next aim crosses
--  the opening, so open ground costs its straight way, not a stair of nearest
--  points; a yard swum the water's price, Search.WATER or the planner's; and
--  Search.CLIMB times what it climbs); down the drops too, one way (off a ledge or
--  a cliff, Walk.FALL high at most: the way across and Search.DROP times each yard
--  fallen), and over the hops both ways (up a mountain's trail: the way across and
--  the climb); then the line pulled straight through the openings it passes (a
--  funnel: corners only where something is in the way; a drop's or a hop's way off
--  and where it lands), the openings drawn in a little from their ends so the line
--  does not graze a wall. Knows no frames.
--
--  In two steps, over the coarse layer (Gates.lua): first the price (Search.Price),
--  rectangle by rectangle only on the tiles where the walk starts and ends, across
--  the others by their gates and what the walks between them cost (where the start's
--  tiles and the end's lie apart: with what the walk costs from each gate on, found
--  back from the end, to guide it out of the start's tiles, Back); then the line
--  (Search.Walk), rectangle by rectangle on the tiles that way crosses only, each
--  step aimed at the way's next gate. So a long walk looks at a band of rectangles
--  along its way, not at everything as near as its length, and a walk many times
--  its straight line is priced at once. A start priced again in one plan goes out
--  of its tiles as the first time (Out, kept in the planner's memo).
--
--      Search.Price(continent, u1, v1, u2, v2, from, check, water, memo, level)   the cost in yards on land, the yards
--                      from the walking data to the end (0: on it; more than Search.NEAR: as near as one walks,
--                      Search.FAR) and what Search.Walk needs to draw it; nil and "off" where the walking data has no
--                      floor near the start or the end (nothing to search), nil where no way is found (or Search.MOST
--                      nodes were looked at first); from: the floor the start stands on ({ key, index }, Walk.Follow's),
--                      else every floor under it; check: called between pieces of the work (in a job of Core's
--                      scheduler, its Steps.Check); water: what a yard swum costs in yards on land (the walker's speed on
--                      land over theirs in water), else Search.WATER; memo: a table kept while one plan is made; level:
--                      the heights the floor it ends on lies between ({ low, high }: a lift's end's, Lifts.Heights)
--      Search.Walk(continent, u1, v1, u2, v2, from, check, water, found)   points { u1, v1, ..., u2, v2 }, the cost and
--                      the yards from the walking data to the end, or nil (and "off") as Search.Price; found: what
--                      Search.Price gave for this walk, else it is priced first
--
--  The start: on its floor (where that is a guess, the others under it too, taken
--  only where no way leaves that one, Search.ASIDE), or the floors under it and
--  within Walk.ROOF yards,
--  each over the lowest at the cost of the climb (none: the nearest within
--  Search.REACH yards, else within Search.FAR: a gap in the walking data). The end: on a floor of the regions the start is in, under
--  it or within Search.NEAR yards of it (a pin inside a wall, or where its own
--  floor is missing from the data: Ironforge's city under its mountain), else the
--  nearest within Search.FAR (a pin on a tower, or on a plateau no lift reaches:
--  the planner takes the lifts, Lifts.lua); a walk to a lift's end on a floor of
--  its level within Search.NEAR yards only, never on the other level over or under
--  it (none there: no way). Floors one over the other are each a
--  start or an end of their own, so the walk is the shortest between any two. What
--  lies between the walking data and the point itself is drawn straight and costs
--  Search.STRAIGHT times its yards: the line always runs from the start to the end,
--  and a way that reaches the end on foot is taken where there is one.
-------------------------------------------------------------------------------
local Walk, Gates = ns.Walk, ns.Gates
local Search = {}
ns.Search = Search

Search.REACH = 40       -- yards the start may be from the walking data's nearest floor
Search.NEAR = 50        -- yards from the end a floor of the walk's regions may be and end it, the rest straight
Search.FAR = 500        -- yards from the end the nearest such floor may be, at most, where none is that near
Search.STRAIGHT = 6     -- what lies off the walking data, straight, costs so many times its yards
Search.WATER = 1 / 0.6  -- a yard swum costs so many on land, where the walk is not told (one swims at 60 % of one's
                        -- speed on land: the planner tells the character's own, Planner.lua)
Search.CLIMB = 0.25     -- each yard up costs so many yards more: the game runs as fast up a hill as on the flat
                        -- (no slope over 50 degrees is a floor at all), so the shorter way over a hill or a pass is
                        -- taken; of two ways about as long the flatter
Search.DROP = 1         -- each yard fallen off a drop costs so many yards more: a fall takes health, so of two ways
                        -- about as long the one with the smaller fall
Search.EDGE = 0.8       -- yards an opening is drawn in from its ends
Search.ASIDE = 500      -- yards more a walk from another floor at the start costs than one from the floor it was
                        -- guessed on: taken only where no way leaves that one (a roof, a rock's top over a street, a
                        -- floor the walking data closes in), and not counted in its cost
Search.MOST = 200000    -- nodes (rectangles, gates) looked at, at most, before a search gives up
Search.looked = 0       -- nodes looked at by every search so far (a plan counts its own: Planner.BUDGET)
Search.EVERY = 64       -- nodes looked at between two looks at the frame's time
Search.AIM = 1.2        -- times the estimate of what is left counts along the coarse way: the line's search a little
                        -- greedy (a third fewer rectangles, the walk a few tenths of a percent longer)
Search.SLACK = 1000     -- yards more than the cheapest way out of the start's tiles found so far the estimate back
                        -- from the end goes on for the others (Back)

local floor, sqrt = math.floor, math.sqrt
local GOAL = -1 -- the end itself, reached from each floor at it
local function Id(tile, index) return tile.key * 65536 + index end

-- The floors the walk may start on: { tile, index, u, v (the start on it), cost (of the way onto it) } each, and the
-- id of the floor it stands on where that is known (from). Not knowing which floor the start is on (a flight point,
-- the tram's entrance): those under it and within Walk.ROOF yards (its own may be missing right under it: Ironforge's
-- floor at the tram's entrance), each at its way there, straight, and the climb from the lowest of them: a place
-- stands on its lowest floor rather than on the hill or the mountain over it (Ironforge's flight master under the
-- mountain, whose top is the shorter way to Tinker Town). Knowing it: that one; where it is a guess (guess: the
-- player's, chosen among others, Planner.lua), the others too, at Search.ASIDE more.
local function Sources(continent, u, v, from)
    local list, own = {}, nil
    local tile = from and Walk.Tile(from[1])
    if tile and from[2] <= tile.count then
        local left, right, top, bottom = Walk.Box(tile, from[2])
        local su, sv = math.max(left, math.min(right, u)), math.max(bottom, math.min(top, v))
        local gap = sqrt((su - u) ^ 2 + (sv - v) ^ 2)
        if gap <= Search.REACH then
            list[1] = { tile, from[2], su, sv, gap * Search.STRAIGHT }
            own = Id(tile, from[2])
        end
    end
    if own and not from.guess then return list, own end
    local first, lowest = #list + 1, nil
    Walk.Around(continent, u, v, Walk.ROOF, function(near, index, nu, nv, gap)
        if Id(near, index) ~= own then
            local z = near.rects[index * 5] / 4
            list[#list + 1] = { near, index, nu, nv, gap * Search.STRAIGHT, z }
            if not lowest or z < lowest then lowest = z end
        end
    end)
    for n = first, #list do
        local source = list[n]
        source[5] = source[5] + source[6] - lowest + (own and Search.ASIDE or 0)
    end
    if #list == 0 then
        local near, index, su, sv = Walk.Nearest(continent, u, v, Search.REACH)
        if not near then near, index, su, sv = Walk.Nearest(continent, u, v, Search.FAR) end
        if near then list[1] = { near, index, su, sv, sqrt((su - u) ^ 2 + (sv - v) ^ 2) * Search.STRAIGHT } end
    end
    return list, own
end

-- The floors the walk may end on, of the regions it may start in: [id] = { tile, index, u, v (its point nearest the
-- end), cost (the rest of the way, straight) }; nil when none is near enough. Those under the end, and those within
-- Search.NEAR yards of it at Search.STRAIGHT times their way to it: the end's own floor may be missing from the data
-- where another lies over it (Ironforge's city under its mountain), and the walk to the one over it is the long way.
-- With a level (the heights a lift's end's floors lie between), only those at its heights: none such, none. Second,
-- where it looked for the nearest floor of each region: whether any floor at all lies within Search.FAR yards.
local function Goals(continent, u, v, regions, level)
    local goals, any = {}, false
    Walk.Around(continent, u, v, Search.NEAR, function(tile, index, nu, nv, gap)
        local z = tile.rects[index * 5] / 4
        if regions[tile.region[index]] and (not level or (z >= level[1] and z <= level[2])) then
            goals[Id(tile, index)], any = { tile, index, nu, nv, gap * Search.STRAIGHT }, true
        end
    end)
    if any then return goals end
    if level then return nil end
    local nearest, seen = Walk.NearestOf(continent, u, v, Search.FAR, regions)
    for _, near in pairs(nearest) do
        local tile, index, nu, nv = near[1], near[2], near[3], near[4]
        goals[Id(tile, index)], any = { tile, index, nu, nv, sqrt((nu - u) ^ 2 + (nv - v) ^ 2) * Search.STRAIGHT }, true
    end
    return any and goals or nil, seen
end

-- Where the way from a point (fu, fv) to the walk's end (eu, ev) crosses an opening (au, av to bu, bv: a
-- rectangle's side, level or upright) at the least: where the straight line between them crosses its line (the end
-- mirrored over it where both lie on one side), held within the opening.
local function Through(fu, fv, au, av, bu, bv, eu, ev)
    if av == bv then
        local a, b = fv - av, ev - av
        if a * b > 0 then b = -b end
        local u = a ~= b and fu + (eu - fu) * a / (a - b) or eu
        if au > bu then au, bu = bu, au end
        return u < au and au or u > bu and bu or u, av
    end
    local a, b = fu - au, eu - au
    if a * b > 0 then b = -b end
    local v = a ~= b and fv + (ev - fv) * a / (a - b) or ev
    if av > bv then av, bv = bv, av end
    return au, v < av and av or v > bv and bv or v
end

-- A binary heap of node ids, each by the f it had when it was put in (keys); an id put in again with a lower f is
-- in it twice, and the later one taken out is passed over (closed).
local function Push(heap, keys, f, id)
    local n = #heap + 1
    heap[n], keys[n] = id, f
    while n > 1 do
        local parent = floor(n / 2)
        if keys[parent] <= keys[n] then break end
        heap[parent], heap[n] = heap[n], heap[parent]
        keys[parent], keys[n] = keys[n], keys[parent]
        n = parent
    end
end

local function Pop(heap, keys)
    local top, size = heap[1], #heap
    heap[1], keys[1] = heap[size], keys[size]
    heap[size], keys[size] = nil, nil
    size = size - 1
    local n = 1
    while true do
        local left, right, small = n * 2, n * 2 + 1, n
        if left <= size and keys[left] < keys[small] then small = left end
        if right <= size and keys[right] < keys[small] then small = right end
        if small == n then break end
        heap[small], heap[n] = heap[n], heap[small]
        keys[small], keys[n] = keys[n], keys[small]
        n = small
    end
    return top
end

-- The line pulled through the openings (each { left u, left v, right u, right v } as seen going through),
-- from the start to the end: the corners where it must turn.
local function Cross(au, av, bu, bv, cu, cv) -- > 0: c lies left of the way from a to b
    return (bu - au) * (cv - av) - (bv - av) * (cu - au)
end

local function Funnel(su, sv, portals, eu, ev)
    local points = { su, sv }
    portals[#portals + 1] = { eu, ev, eu, ev }
    local apexU, apexV = su, sv
    local leftU, leftV, rightU, rightV = su, sv, su, sv
    local leftAt, rightAt = 0, 0
    local i = 1
    local guard = 0
    while i <= #portals and guard < 100000 do
        guard = guard + 1
        local p = portals[i]
        local lu, lv, ru, rv = p[1], p[2], p[3], p[4]
        local restart = false
        -- The right side narrows (moves left).
        if Cross(apexU, apexV, rightU, rightV, ru, rv) >= 0 then
            if (apexU == rightU and apexV == rightV) or Cross(apexU, apexV, leftU, leftV, ru, rv) < 0 then
                rightU, rightV, rightAt = ru, rv, i
            else
                points[#points + 1], points[#points + 2] = leftU, leftV
                apexU, apexV = leftU, leftV
                rightU, rightV = apexU, apexV
                i = leftAt + 1
                rightAt = leftAt
                restart = true
            end
        end
        if not restart then
            -- The left side narrows (moves right).
            if Cross(apexU, apexV, leftU, leftV, lu, lv) <= 0 then
                if (apexU == leftU and apexV == leftV) or Cross(apexU, apexV, rightU, rightV, lu, lv) > 0 then
                    leftU, leftV, leftAt = lu, lv, i
                else
                    points[#points + 1], points[#points + 2] = rightU, rightV
                    apexU, apexV = rightU, rightV
                    leftU, leftV = apexU, apexV
                    i = rightAt + 1
                    leftAt = rightAt
                    restart = true
                end
            end
        end
        if not restart then i = i + 1 end
    end
    points[#points + 1], points[#points + 2] = eu, ev
    -- A corner reached twice in a row (the funnel came back to its apex) is one; the end is the end itself, not a
    -- corner a hair before it.
    local clean = { points[1], points[2] }
    for index = 3, #points, 2 do
        local u, v = points[index], points[index + 1]
        if math.abs(u - clean[#clean - 1]) > 0.5 or math.abs(v - clean[#clean]) > 0.5 then
            clean[#clean + 1], clean[#clean + 2] = u, v
        end
    end
    if #clean == 2 then clean[3], clean[4] = eu, ev else clean[#clean - 1], clean[#clean] = eu, ev end
    return clean
end

-- An opening drawn in from its ends, as left and right going through it from its side (north: going north,
-- the west end on the left; east: the north end; south: the east end; west: the south end).
local function Portal(tile, index, side, first, last)
    local u1, v1, u2, v2 = Walk.Portal(tile, index, side, first, last)
    local length = math.sqrt((u2 - u1) ^ 2 + (v2 - v1) ^ 2)
    local cut = math.min(Search.EDGE, length * 0.45) / length
    u1, v1, u2, v2 = u1 + (u2 - u1) * cut, v1 + (v2 - v1) * cut, u2 - (u2 - u1) * cut, v2 - (v2 - v1) * cut
    -- Walk.Portal gives a north or south side west to east, an east or west side north to south.
    if side == 0 or side == 1 then return { u1, v1, u2, v2 } end
    return { u2, v2, u1, v1 }
end

-- A drop as two openings the line passes: its way off (as Portal) and where it lands (Walk.Fall), alike.
local function Fallen(tile, index, side, first, last, next, other)
    local off = Portal(tile, index, side, first, last)
    local au, av, _, _, cu, cv = Walk.Fall(tile, index, side, first, last, next, other)
    local du, dv = cu - au, cv - av
    return off, { off[1] + du, off[2] + dv, off[3] + du, off[4] + dv }
end


-- The next tile north, east, south, west.
local STEP = { [0] = -64, [1] = 1, [2] = 64, [3] = -1 }

-- A point on a tile's side, so many samples along it (from its west end, or its north end).
local function OnSide(tile, side, along)
    local s = Walk.SAMPLE
    if side == 0 then return tile.left + along * s, tile.top end
    if side == 2 then return tile.left + along * s, tile.top - Walk.SIDE * s end
    if side == 1 then return tile.left + Walk.SIDE * s, tile.top - along * s end
    return tile.left, tile.top - along * s
end

-- The samples of a rectangle's side: its first and last.
local function SideOf(tile, index, side)
    local r, base = tile.rects, (index - 1) * 5
    if side == 0 or side == 2 then return r[base + 1], r[base + 1] + r[base + 3] - 1 end
    return r[base + 2], r[base + 2] + r[base + 4] - 1
end

-- The search: A* from the sources (or from the ways out of the start's tiles, opts.exits) to the goals, over
-- rectangles (ids from Id, above 0) and gates (minus their number); check() is called every Search.EVERY nodes.
-- opts:
--   near    [tile key] = true: the tiles searched rectangle by rectangle (where the walk starts and ends); the
--           others are crossed by their gates (Gates.lua), where both tiles of a border have them. nil: every tile
--   exits   with near: where the walk leaves the start's tiles and what each costs (Out); the search starts there
--   guide   with near: what the walk costs from each gate on (Back): the estimate of what is left from a gate, and
--           on the start's tiles from the cheapest way out of them
--   out     with near: no goal; every rectangle of the near tiles reached, each gate out of them reached, not crossed
--   way     the coarse way (Way): only its tiles searched, each step aimed at its next gate, the estimate of what is
--           left the way's from there (Search.AIM times)
-- Gives the search's tables, or nil where nothing was found (or Search.MOST nodes were looked at).
local function Run(sources, goals, u2, v2, check, water, opts)
    local near, way, guide, out = opts.near, opts.way, opts.guide, opts.out
    -- The nodes' tables, a part per tile (the gates and the end in part 0, by their numbers): Lua makes a table twice
    -- as large all at once when it is full, and 14 tables with a key per node did so together past some 130,000 nodes,
    -- 20 to 130 ms in one frame (card #574); a tile's part holds no more than its rectangles.
    local parts, heap, keys = {}, {}, {}
    local function Part(key)
        local part = { g = {}, from = {}, enterU = {}, enterV = {}, aim = {}, first = {}, tiles = {}, viaSide = {},
                       viaFirst = {}, viaLast = {}, viaDrop = {}, across = {}, closed = {} }
        parts[key] = part
        return part
    end
    local within, ahead = way and way.tiles, way and #way.u or 0
    local weight = way and Search.AIM or 1
    -- The estimate of what is left from a point (of a rectangle on tile key, or of the gate gid), its next gate on the
    -- way m.
    local function Rest(pu, pv, m, key, gid)
        if out then return 0 end
        if m <= ahead then return (sqrt((way.u[m] - pu) ^ 2 + (way.v[m] - pv) ^ 2) + way.rest[m]) * weight end
        if guide then
            if gid then return guide.cost[gid] or guide.Least(pu, pv) end
            if guide.zone[key] then
                local best, exits = math.huge, guide.exits
                for e = 1, #exits, 3 do
                    local du, dv = exits[e] - pu, exits[e + 1] - pv
                    local rest = sqrt(du * du + dv * dv) + exits[e + 2]
                    if rest < best then best = rest end
                end
                return best
            end
        end
        return sqrt((u2 - pu) ^ 2 + (v2 - pv) ^ 2) * weight
    end
    -- The way's next gate from m on, where a step from tile into next crosses the border m lies on: the one after it.
    local function Onward(m, tile, next)
        if next ~= tile and m <= ahead and ((way.a[m] == tile.key and way.b[m] == next.key)
            or (way.b[m] == tile.key and way.a[m] == next.key)) then
            return m + 1
        end
        return m
    end
    -- Whether a node was looked at: a rectangle (its tile's key, its index), a gate (0, its number).
    local function Closed(key, slot)
        local part = parts[key]
        return part ~= nil and part.closed[slot] ~= nil
    end
    -- A node reached at a cost from parent (origin: the node parent's way began at): kept where it is the cheapest so
    -- far; then true, its part and its slot there.
    local function Reach(nid, cost, parent, pu, pv, m, origin)
        local key, slot
        if nid > 0 then key, slot = floor(nid / 65536), nid % 65536 else key, slot = 0, -nid end
        local part = parts[key] or Part(key)
        local g = part.g
        if g[slot] == nil or cost < g[slot] then
            g[slot], part.from[slot], part.enterU[slot], part.enterV[slot], part.aim[slot] = cost, parent, pu, pv, m
            part.first[slot] = parent and origin or nid
            if nid > 0 then
                Push(heap, keys, cost + Rest(pu, pv, m, key), nid)
            else
                Push(heap, keys, cost + Rest(pu, pv, m, nil, -nid), nid)
            end
            return true, part, slot
        end
    end
    if opts.exits then
        for gid, exit in pairs(opts.exits) do Reach(-gid, exit[1], nil, exit[2], exit[3], 1) end
    else
        for _, source in ipairs(sources) do
            local tile, index = source[1], source[2]
            local reached, part, slot = Reach(Id(tile, index), source[5], nil, source[3], source[4], 1)
            if reached then part.tiles[slot] = tile end
        end
    end
    local seen = 0
    while heap[1] do
        local id = Pop(heap, keys)
        if id == GOAL then break end
        local node, at
        if id > 0 then node, at = parts[floor(id / 65536)], id % 65536 else node, at = parts[0], -id end
        if not node.closed[at] then
            node.closed[at] = true
            seen = seen + 1
            Search.looked = Search.looked + 1
            if seen > Search.MOST then return nil end
            if check and seen % Search.EVERY == 0 then check() end
            local fu, fv, here, m, origin = node.enterU[at], node.enterV[at], node.g[at], node.aim[at], node.first[at]
            if id > 0 then
                local tile, index = node.tiles[at], at
                local weight = tile.kind[index] == Walk.WATER and water or 1
                local z = tile.rects[index * 5] / 4
                local tu, tv = u2, v2 -- where the steps aim
                if m <= ahead then tu, tv = way.u[m], way.v[m] end
                -- A floor at the end: the end itself from it.
                local goal = goals[id]
                if goal then
                    local du, dv = goal[3] - fu, goal[4] - fv
                    local cost = here + sqrt(du * du + dv * dv) * weight + goal[5]
                    local ends = parts[0] or Part(0)
                    if ends.g[-GOAL] == nil or cost < ends.g[-GOAL] then
                        ends.g[-GOAL], ends.from[-GOAL] = cost, id
                        Push(heap, keys, cost, GOAL)
                    end
                end
                local gates = near and Gates.Tile(tile.key)
                if gates and gates.rects ~= tile.count then gates = nil end -- made from another block: none
                local opens = (tile.opens or Walk.Links(tile))[index]
                for n = 1, #opens do
                    local where = opens[n][4]
                    if where > 0 and gates and not near[tile.key + STEP[where - 1]]
                        and Gates.Tile(tile.key + STEP[where - 1]) then
                        -- Into a tile crossed by its gates: the gates on this side of this rectangle's part that the
                        -- opening reaches, each from where it crosses the opening (the gate's middle, held within
                        -- both).
                        local side = where - 1
                        local low, high = opens[n][2], opens[n][3]
                        if not low then low, high = SideOf(tile, index, side) end
                        local part = Gates.Parts(tile)[index]
                        local list = gates.bySide[side]
                        for k = 1, #list do
                            local a = list[k]
                            local nid = -gates.id[a]
                            if gates.part[a] == part and gates.first[a] <= high and gates.last[a] >= low
                                and not Closed(0, -nid) then
                                local lo, hi = math.max(low, gates.first[a]), math.min(high, gates.last[a]) + 1
                                local middle = (gates.first[a] + gates.last[a] + 1) / 2
                                local qu, qv = OnSide(tile, side, middle < lo and lo or middle > hi and hi or middle)
                                local gu, gv = gates.u[a], gates.v[a]
                                local cost = here + sqrt((qu - fu) ^ 2 + (qv - fv) ^ 2) * weight
                                    + sqrt((gu - qu) ^ 2 + (gv - qv) ^ 2)
                                local reached, to, slot = Reach(nid, cost, id, gu, gv, m, origin)
                                if reached then to.across[slot] = nil end
                            end
                        end
                    else
                        local side, low, high, next, other = Walk.Opening(tile, index, n)
                        local nid = side and next.key * 65536 + other
                        if nid and not Closed(next.key, other) and (not within or within[next.key]) then
                            local au, av, bu, bv = Walk.Portal(tile, index, side, low, high)
                            local pu, pv = Through(fu, fv, au, av, bu, bv, tu, tv)
                            local du, dv = pu - fu, pv - fv
                            local cost = here + sqrt(du * du + dv * dv) * weight
                            local rise = next.rects[other * 5] / 4 - z
                            if rise > 0 then cost = cost + rise * Search.CLIMB end
                            local reached, to, slot = Reach(nid, cost, id, pu, pv, Onward(m, tile, next), origin)
                            if reached then
                                to.viaSide[slot], to.viaFirst[slot], to.viaLast[slot], to.viaDrop[slot] = side, low, high, nil
                                to.tiles[slot] = next
                            end
                        end
                    end
                end
                -- Down its drops, one way, and over its hops: to where the line on to the aim crosses the way off,
                -- across to where it lands, each yard fallen Search.DROP more, each yard a hop climbs Search.CLIMB
                -- more. Into another tile only where that one is searched rectangle by rectangle (no gate crosses a
                -- border down a drop).
                local drops = Walk.Drops(tile, index)
                for n = 1, #drops do
                    if drops[n][7] or drops[n][6] <= Walk.FALL then
                        local side, low, high, next, other, height, hop = Walk.Drop(tile, index, n)
                        local nid = side and next.key * 65536 + other
                        if nid and not Closed(next.key, other) and (not within or within[next.key])
                            and not (next ~= tile and gates and not near[next.key] and Gates.Tile(next.key)) then
                            local au, av, bu, bv, cu, cv = Walk.Fall(tile, index, side, low, high, next, other)
                            local pu, pv = Through(fu, fv, au, av, bu, bv, tu, tv)
                            local qu, qv = pu + cu - au, pv + cv - av
                            local cost = here + sqrt((pu - fu) ^ 2 + (pv - fv) ^ 2) * weight
                                + sqrt((qu - pu) ^ 2 + (qv - pv) ^ 2)
                            if not hop then
                                cost = cost + height * Search.DROP
                            elseif height > 0 then
                                cost = cost + height * Search.CLIMB
                            end
                            local reached, to, slot = Reach(nid, cost, id, qu, qv, Onward(m, tile, next), origin)
                            if reached then
                                to.viaSide[slot], to.viaFirst[slot], to.viaLast[slot], to.viaDrop[slot] = side, low, high, true
                                to.tiles[slot] = next
                            end
                        end
                    end
                end
            elseif not out then
                -- A gate: into the rectangles of a tile searched so (those of the gate's part that open across its
                -- stretch, each entered where the gate's middle is held within its opening), else across a tile to
                -- the other gates of its part there.
                local gid = -id
                local keyA, keyB, sideA = Gates.Ends(gid)
                for k = 1, 2 do
                    local key = k == 1 and keyA or keyB
                    local side = k == 1 and sideA or (sideA + 2) % 4
                    local gates = Gates.Tile(key)
                    local a = gates and gates.byId[gid]
                    if near[key] or not a then
                        local tile = Walk.Tile(key)
                        local other = Gates.Tile(k == 1 and keyB or keyA)
                        local o = other and other.byId[gid]
                        local low, high
                        if a then low, high = gates.first[a], gates.last[a]
                        elseif o then low, high = other.first[o], other.last[o] end
                        if tile and low then
                            local part = a and gates.rects == tile.count and gates.part[a]
                            local tileParts = part and Gates.Parts(tile)
                            local edges = Gates.Edges(tile, side)
                            local middle = (low + high + 1) / 2
                            for e = 1, #edges, 3 do
                                local index, f, l = edges[e], edges[e + 1], edges[e + 2]
                                local nid = Id(tile, index)
                                if f <= high and l >= low and (not tileParts or tileParts[index] == part)
                                    and not Closed(tile.key, index) then
                                    local lo, hi = math.max(f, low), math.min(l, high) + 1
                                    local pu, pv = OnSide(tile, side, middle < lo and lo or middle > hi and hi or middle)
                                    local reached, to, slot = Reach(nid, here + sqrt((pu - fu) ^ 2 + (pv - fv) ^ 2), id, pu,
                                        pv, m, origin)
                                    if reached then to.viaSide[slot], to.tiles[slot] = nil, tile end
                                end
                            end
                        end
                    else
                        local group = gates.group[a]
                        for y = 1, group and group.size or 0 do
                            local b = group.gates[y]
                            local nid = -gates.id[b]
                            if b ~= a and not Closed(0, -nid) then
                                local reached, to, slot = Reach(nid, here + Gates.Cost(gates, a, b, water), id, gates.u[b],
                                    gates.v[b], m, origin)
                                if reached then to.across[slot] = key end
                            end
                        end
                        -- The ways down a drop from it, one way (into another part of the tile too).
                        local falls = gates.falls[a]
                        for f = 1, falls and #falls or 0, 3 do
                            local b = falls[f]
                            local nid = -gates.id[b]
                            if not Closed(0, -nid) then
                                local reached, to, slot = Reach(nid, here + Gates.Down(falls[f + 1], falls[f + 2], water), id,
                                    gates.u[b], gates.v[b], m, origin)
                                if reached then to.across[slot] = key end
                            end
                        end
                    end
                end
            end
        end
    end
    if not (parts[0] and parts[0].g[-GOAL] ~= nil) and not out then return nil end
    return { parts = parts }
end

-- A node's value in a search's tables (Run): name, the node's id; nil where it was not reached.
local function Of(state, name, id)
    local part = state.parts[id > 0 and floor(id / 65536) or 0]
    return part and part[name][id > 0 and id % 65536 or -id]
end

-- The walk's start and end on the walking data: its sources, the floor it stands on (own) and its goals (at the
-- level's heights, where it has one); nil and "off" where the walking data has no floor near the start or the end, nil
-- where none of the start's regions reaches the end.
local function Prepare(continent, u1, v1, u2, v2, start, level)
    if not Walk.Ready() then return nil, "off" end
    local sources, own = Sources(continent, u1, v1, start)
    if #sources == 0 then return nil, "off" end
    local regions = {}
    for _, source in ipairs(sources) do regions[source[1].region[source[2]]] = true end
    local goals, seen = Goals(continent, u2, v2, regions, level)
    -- None of the start's regions near the end: no way, where the end has floors at all near it (seen: as Goals
    -- found looking for the nearest of each region).
    if not goals then
        if seen == nil then seen = Walk.Nearest(continent, u2, v2, Search.FAR) ~= nil end
        return nil, not seen and "off" or nil
    end
    return sources, own, goals
end

-- The coarse way of a search: its gates from the start on (each one's point, what the walk costs from there on, the
-- two tiles it lies between) and the tiles it crosses (tiles, the start's and the end's given); nil where it crossed no
-- gate (found rectangle by rectangle all the way).
local function Way(state, tiles)
    local list = {}
    local id = Of(state, "from", GOAL)
    while id do
        if id < 0 then table.insert(list, 1, id) end
        id = Of(state, "from", id)
    end
    if #list == 0 then return nil end
    local total = Of(state, "g", GOAL)
    local way = { u = {}, v = {}, rest = {}, a = {}, b = {}, tiles = tiles }
    for m, nid in ipairs(list) do
        local keyA, keyB = Gates.Ends(-nid)
        way.u[m], way.v[m], way.rest[m], way.a[m], way.b[m] = Of(state, "enterU", nid), Of(state, "enterV", nid),
            total - Of(state, "g", nid), keyA, keyB
        local across = Of(state, "across", nid)
        if across then tiles[across] = true end
    end
    return way
end

-- The line of a search found rectangle by rectangle: the openings passed, pulled straight; points, cost, rest.
local function Line(state, goals, own, u1, v1, u2, v2)
    local last = Of(state, "from", GOAL)
    local goal = goals[last]
    local list = {}
    local id = last
    while Of(state, "viaSide", id) do
        local parent = Of(state, "from", id)
        local side, low, high = Of(state, "viaSide", id), Of(state, "viaFirst", id), Of(state, "viaLast", id)
        if Of(state, "viaDrop", id) then
            local off, landed = Fallen(Of(state, "tiles", parent), parent % 65536, side, low, high, Of(state, "tiles", id),
                id % 65536)
            table.insert(list, 1, landed)
            table.insert(list, 1, off)
        else
            table.insert(list, 1, Portal(Of(state, "tiles", parent), parent % 65536, side, low, high))
        end
        id = parent
    end
    local su, sv = Of(state, "enterU", id), Of(state, "enterV", id)
    local cost = Of(state, "g", GOAL)
    if own and id ~= own then cost = cost - Search.ASIDE end
    local points = Funnel(su, sv, list, goal[3], goal[4])
    -- The start and the end themselves, where they lie off the walking data: straight to it, straight from it (a
    -- hair off: in its place).
    if (su - u1) ^ 2 + (sv - v1) ^ 2 > 0.25 then
        table.insert(points, 1, v1)
        table.insert(points, 1, u1)
    else
        points[1], points[2] = u1, v1
    end
    local rest = sqrt((goal[3] - u2) ^ 2 + (goal[4] - v2) ^ 2)
    if rest > 0.5 then
        points[#points + 1], points[#points + 2] = u2, v2
    else
        points[#points - 1], points[#points] = u2, v2
    end
    return points, cost, rest
end

-- The tiles of a list of floors (the sources, or the goals): [key] = true.
local function TilesOf(list)
    local found = {}
    for _, place in pairs(list) do found[place[1].key] = true end
    return found
end

-- Whether two sets of tiles lie apart: none of the one is any of the other or beside it.
local function Apart(a, b)
    for key in pairs(a) do
        for row = -64, 64, 64 do
            if b[key + row - 1] or b[key + row] or b[key + row + 1] then return false end
        end
    end
    return true
end

-- What the walk costs from each gate on to its end, by the coarse layer, found back from the end: from the gates on
-- the end's tiles' borders (each at its straight way to the end) across the tiles crossed by their gates, by what each
-- of their walks costs, those nearest to the start first (A*), until every way out of the start's tiles (zone: the
-- gates on their borders) is reached, or what is left costs Search.SLACK more than the cheapest of them so far. The
-- search from the start then makes for the cheapest way out of its tiles, and from a gate on its cost (one not reached
-- costs at least what was left then, less its way from the start). nil where no way out of the start's tiles is
-- reached.
local function Back(zone, ends, near, u1, v1, u2, v2, water, check)
    -- Whether the walk crosses a gate's other tile by its gates (one not searched rectangle by rectangle).
    local function Across(gid, key)
        local keyA, keyB = Gates.Ends(gid)
        local other = keyA == key and keyB or keyA
        return not near[other] and Gates.Tile(other) ~= nil
    end
    local exits, count = {}, 0
    for key in pairs(zone) do
        local gates = Gates.Tile(key)
        if not gates then return nil end
        for a = 1, gates.count do
            if Across(gates.id[a], key) then exits[gates.id[a]], count = true, count + 1 end
        end
    end
    if count == 0 then return nil end
    local cost, closed, heap, keys = {}, {}, {}, {}
    for key in pairs(ends) do
        local gates = Gates.Tile(key)
        for a = 1, gates and gates.count or 0 do
            local gid = gates.id[a]
            if Across(gid, key) then
                local gu, gv = gates.u[a], gates.v[a]
                local c = sqrt((gu - u2) ^ 2 + (gv - v2) ^ 2)
                if not cost[gid] or c < cost[gid] then
                    cost[gid] = c
                    Push(heap, keys, c + sqrt((gu - u1) ^ 2 + (gv - v1) ^ 2), gid)
                end
            end
        end
    end
    local reached, best, stop, seen, known = 0, nil, math.huge, 0, {}
    while heap[1] do
        local f = keys[1]
        local gid = Pop(heap, keys)
        if not closed[gid] then
            if best and f > best + Search.SLACK then
                stop = f
                break
            end
            closed[gid], known[gid] = true, cost[gid]
            seen = seen + 1
            Search.looked = Search.looked + 1
            if seen > Search.MOST then
                stop = f
                break
            end
            if check and seen % Search.EVERY == 0 then check() end
            if exits[gid] then
                reached = reached + 1
                if not best or f < best then best = f end
                if reached == count then
                    stop = heap[1] and keys[1] or math.huge
                    break
                end
            end
            local keyA, keyB = Gates.Ends(gid)
            for k = 1, 2 do
                local key = k == 1 and keyA or keyB
                local gates = not near[key] and Gates.Tile(key)
                local a = gates and gates.byId[gid]
                local group = a and gates.group[a]
                -- The gates of its part, then those whose ways down a drop come to it (the drop taken the way it goes).
                local landed = a and gates.landed[a]
                local size = group and group.size or 0
                for y = 1, size + (landed and #landed / 3 or 0) do
                    local b, c
                    if y <= size then
                        b = group.gates[y]
                        c = b ~= a and cost[gid] + Gates.Cost(gates, b, a, water)
                    else
                        local f = (y - size) * 3 - 2
                        b, c = landed[f], cost[gid] + Gates.Down(landed[f + 1], landed[f + 2], water)
                    end
                    local bid = gates.id[b]
                    if c and not closed[bid] and (not cost[bid] or c < cost[bid]) then
                        cost[bid] = c
                        Push(heap, keys, c + sqrt((gates.u[b] - u1) ^ 2 + (gates.v[b] - v1) ^ 2), bid)
                    end
                end
            end
        end
    end
    if not best then return nil end
    local function Least(gu, gv)
        local least = stop - sqrt((gu - u1) ^ 2 + (gv - v1) ^ 2)
        local straight = sqrt((gu - u2) ^ 2 + (gv - v2) ^ 2)
        return least > straight and least or straight
    end
    -- The ways out but those dearer than the cheapest by more than the start's tiles' width: from nowhere in them is
    -- such a one the cheapest.
    local found, least, west, east, south, north = {}, math.huge, math.huge, -math.huge, math.huge, -math.huge
    for gid in pairs(exits) do
        local gates = Gates.Tile((Gates.Ends(gid)))
        local at = gates and gates.byId[gid]
        if at then
            local gu, gv = gates.u[at], gates.v[at]
            local c = known[gid] or Least(gu, gv)
            found[#found + 1] = { gu, gv, c }
            least, west, east = math.min(least, c), math.min(west, gu), math.max(east, gu)
            south, north = math.min(south, gv), math.max(north, gv)
        end
    end
    local width = sqrt((east - west) ^ 2 + (north - south) ^ 2)
    local list = {}
    for _, exit in ipairs(found) do
        if exit[3] <= least + width then
            list[#list + 1], list[#list + 2], list[#list + 3] = exit[1], exit[2], exit[3]
        end
    end
    return { cost = known, exits = list, zone = zone, Least = Least }
end

-- The ways out of the start's tiles (zone) and what each costs from the start: every rectangle of them reached (a
-- search with no goal), each opening out of them at the gates of its border there. { [gate's number] = { cost, u, v,
-- aside } }; aside: its way starts on a floor other than the one the start stands on (Search.ASIDE in its cost).
local function Out(sources, own, zone, water, check)
    local state = Run(sources, {}, 0, 0, check, water, { near = zone, out = true })
    local exits = {}
    local gates = state and state.parts[0]
    for slot, cost in pairs(gates and gates.g or {}) do
        if -slot < GOAL then
            exits[slot] = { cost, gates.enterU[slot], gates.enterV[slot], own ~= nil and gates.first[slot] ~= own }
        end
    end
    return exits
end

-- What a walk costs, by the coarse way: see the header. From the start's tiles and those of the end rectangle by
-- rectangle, across the others by their gates; a start already priced in this plan (memo) from the ways out of its
-- tiles found then (Out).
function Search.Price(continent, u1, v1, u2, v2, from, check, water, memo, level)
    water = water or Search.WATER
    local sources, own, goals = Prepare(continent, u1, v1, u2, v2, from, level)
    if not sources then return nil, own end
    local zone, ends = TilesOf(sources), TilesOf(goals)
    local apart = Apart(zone, ends)
    local exits
    if apart and memo then
        local key = ("%d %.3f %.3f %s %s %s %s"):format(continent, u1, v1, from and from[1] or "", from and from[2] or "",
            from and from.guess and "?" or "", water)
        local start = memo[key] or { uses = 0 }
        memo[key] = start
        start.uses = start.uses + 1
        if start.uses > 1 then
            start.exits = start.exits or Out(sources, own, zone, water, check)
            exits = start.exits
        end
    end
    local state
    if exits then
        state = Run(sources, goals, u2, v2, check, water, { near = ends, exits = exits })
    else
        local near = {}
        for key in pairs(zone) do near[key] = true end
        for key in pairs(ends) do near[key] = true end
        local guide = apart and Back(zone, ends, near, u1, v1, u2, v2, water, check) or nil
        state = Run(sources, goals, u2, v2, check, water, { near = near, guide = guide })
    end
    if not state then return nil end
    local tiles = {}
    for key in pairs(zone) do tiles[key] = true end
    for key in pairs(ends) do tiles[key] = true end
    local way = Way(state, tiles)
    if not way then
        -- Found rectangle by rectangle all the way: its line now.
        local points, cost, rest = Line(state, goals, own, u1, v1, u2, v2)
        return cost, rest, { points = points, cost = cost, rest = rest }
    end
    local id = Of(state, "from", GOAL)
    local goal = goals[id]
    while Of(state, "from", id) do id = Of(state, "from", id) end
    local cost = Of(state, "g", GOAL)
    if (exits and exits[-id][4]) or (not exits and own and id ~= own) then cost = cost - Search.ASIDE end
    return cost, sqrt((goal[3] - u2) ^ 2 + (goal[4] - v2) ^ 2),
        { sources = sources, own = own, goals = goals, way = way, water = water }
end

-- A walk's line: see the header. Along its coarse way, rectangle by rectangle on the tiles it crosses; where the
-- coarse layer does not fit the walking data (made from other blocks), on every tile.
function Search.Walk(continent, u1, v1, u2, v2, from, check, water, found)
    if not found then
        local cost, rest
        cost, rest, found = Search.Price(continent, u1, v1, u2, v2, from, check, water)
        if not cost then return nil, rest end
    end
    if found.points then return found.points, found.cost, found.rest end
    local state = Run(found.sources, found.goals, u2, v2, check, found.water, { way = found.way })
        or Run(found.sources, found.goals, u2, v2, check, found.water, {})
    if not state then return nil end
    return Line(state, found.goals, found.own, u1, v1, u2, v2)
end
