local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Search
--  A walk from one point of a plane to another over the walking data (Walk.lua):
--  the rectangles from the floor the start stands on to a floor at the end,
--  through their openings, the shortest by A* (each step costs the way from where
--  the rectangle was entered to where the straight line on to the end crosses the
--  opening, so open ground costs its straight way, not a stair of nearest points;
--  a yard swum the water's price, Search.WATER or the planner's; and Search.CLIMB
--  times what it climbs); then the line pulled straight
--  through the openings it passes (a funnel: corners only where something is in
--  the way), the openings drawn in a little from their ends so the line does not
--  graze a wall. Knows no frames.
--
--      Search.Walk(continent, u1, v1, u2, v2, from, check, water)   points { u1, v1, ..., u2, v2 }, the cost in yards
--                      and the yards from the walking data to the end (0: on it; more than Search.NEAR: as near as
--                      one walks, Search.FAR); nil and "off" where the walking data has no floor near the start or the end
--                      (nothing to search), nil where no way is found (or Search.MOST rectangles were looked at
--                      first); from: the floor the start stands on ({ key, index }, Walk.Follow's), else every
--                      floor under it; check: called between pieces of the work (in a job of Core's scheduler,
--                      its Steps.Check); water: what a yard swum costs in yards on land (the walker's speed on land
--                      over theirs in water), else Search.WATER
--
--  The start: on its floor (where that is a guess, the others under it too, taken
--  only where no way leaves that one, Search.ASIDE), or the floors under it and
--  within Walk.ROOF yards,
--  each over the lowest at the cost of the climb (none: the nearest within
--  Search.REACH yards, else within Search.FAR: a gap in the walking data). The end: on a floor of the regions the start is in, under
--  it or within Search.NEAR yards of it (a pin inside a wall, or where its own
--  floor is missing from the data: Ironforge's city under its mountain), else the
--  nearest within Search.FAR (a pin on a tower, or on a plateau no lift reaches:
--  the planner takes the lifts, Lifts.lua). Floors one over the other are each a
--  start or an end of their own, so the walk is the shortest between any two. What
--  lies between the walking data and the point itself is drawn straight and costs
--  Search.STRAIGHT times its yards: the line always runs from the start to the end,
--  and a way that reaches the end on foot is taken where there is one.
-------------------------------------------------------------------------------
local Walk = ns.Walk
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
Search.EDGE = 0.8       -- yards an opening is drawn in from its ends
Search.ASIDE = 500      -- yards more a walk from another floor at the start costs than one from the floor it was
                        -- guessed on: taken only where no way leaves that one (a roof, a rock's top over a street, a
                        -- floor the walking data closes in), and not counted in its cost
Search.MOST = 200000    -- rectangles looked at, at most, before a search gives up
Search.looked = 0       -- rectangles looked at by every search so far (a plan counts its own: Planner.BUDGET)
Search.EVERY = 64       -- rectangles looked at between two looks at the frame's time

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
local function Goals(continent, u, v, regions)
    local goals, any = {}, false
    Walk.Around(continent, u, v, Search.NEAR, function(tile, index, nu, nv, gap)
        if regions[tile.region[index]] then
            goals[Id(tile, index)], any = { tile, index, nu, nv, gap * Search.STRAIGHT }, true
        end
    end)
    if any then return goals end
    for region in pairs(regions) do
        local tile, index, nu, nv = Walk.Nearest(continent, u, v, Search.FAR, region)
        if tile then
            goals[Id(tile, index)], any = { tile, index, nu, nv, sqrt((nu - u) ^ 2 + (nv - v) ^ 2) * Search.STRAIGHT }, true
        end
    end
    return any and goals or nil
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

-- The search itself; check() is called every Search.EVERY rectangles (the scheduler's Check, or nothing).
local function Run(continent, u1, v1, u2, v2, start, check, water)
    if not Walk.Ready() then return nil, "off" end
    local sources, own = Sources(continent, u1, v1, start)
    if #sources == 0 then return nil, "off" end
    local regions = {}
    for _, source in ipairs(sources) do regions[source[1].region[source[2]]] = true end
    local goals = Goals(continent, u2, v2, regions)
    -- None of the start's regions near the end: no way, where the end has floors at all near it.
    if not goals then return nil, not Walk.Nearest(continent, u2, v2, Search.FAR) and "off" or nil end
    local g, from, enterU, enterV, tiles, indexes = {}, {}, {}, {}, {}, {}
    local viaSide, viaFirst, viaLast = {}, {}, {} -- the opening each floor was reached through, from its from
    local closed, heap, keys = {}, {}, {}
    for _, source in ipairs(sources) do
        local tile, index, su, sv, cost = source[1], source[2], source[3], source[4], source[5]
        local id = Id(tile, index)
        if g[id] == nil or cost < g[id] then
            g[id], tiles[id], indexes[id], enterU[id], enterV[id] = cost, tile, index, su, sv
            Push(heap, keys, cost + sqrt((u2 - su) ^ 2 + (v2 - sv) ^ 2), id)
        end
    end
    local seen = 0
    while heap[1] do
        local id = Pop(heap, keys)
        if id == GOAL then break end
        if not closed[id] then
            closed[id] = true
            seen = seen + 1
            Search.looked = Search.looked + 1
            if seen > Search.MOST then return nil end
            if check and seen % Search.EVERY == 0 then check() end
            local tile, index = tiles[id], indexes[id]
            local weight = tile.kind[index] == Walk.WATER and water or 1
            local fu, fv, here, z = enterU[id], enterV[id], g[id], tile.rects[index * 5] / 4
            -- A floor at the end: the end itself from it.
            local goal = goals[id]
            if goal then
                local du, dv = goal[3] - fu, goal[4] - fv
                local cost = here + sqrt(du * du + dv * dv) * weight + goal[5]
                if g[GOAL] == nil or cost < g[GOAL] then
                    g[GOAL], from[GOAL] = cost, id
                    Push(heap, keys, cost, GOAL)
                end
            end
            for n = 1, #tile.opens[index] do
                local side, first, last, next, other = Walk.Opening(tile, index, n)
                local nid = side and next.key * 65536 + other
                if nid and not closed[nid] then
                    local au, av, bu, bv = Walk.Portal(tile, index, side, first, last)
                    local pu, pv = Through(fu, fv, au, av, bu, bv, u2, v2)
                    local du, dv = pu - fu, pv - fv
                    local cost = here + sqrt(du * du + dv * dv) * weight
                    local rise = next.rects[other * 5] / 4 - z
                    if rise > 0 then cost = cost + rise * Search.CLIMB end
                    if g[nid] == nil or cost < g[nid] then
                        g[nid], from[nid] = cost, id
                        viaSide[nid], viaFirst[nid], viaLast[nid] = side, first, last
                        enterU[nid], enterV[nid] = pu, pv
                        tiles[nid], indexes[nid] = next, other
                        du, dv = u2 - pu, v2 - pv
                        Push(heap, keys, cost + sqrt(du * du + dv * dv), nid)
                    end
                end
            end
        end
    end
    if g[GOAL] == nil then return nil end
    -- The openings passed, from the floor it started on to the one it ends on.
    local last = from[GOAL]
    local goal = goals[last]
    local list = {}
    local id = last
    while viaSide[id] do
        local parent = from[id]
        table.insert(list, 1, Portal(tiles[parent], indexes[parent], viaSide[id], viaFirst[id], viaLast[id]))
        id = parent
    end
    local su, sv = enterU[id], enterV[id]
    local cost = g[GOAL]
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

function Search.Walk(continent, u1, v1, u2, v2, from, check, water)
    return Run(continent, u1, v1, u2, v2, from, check, water or Search.WATER)
end
