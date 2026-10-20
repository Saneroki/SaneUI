local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Search
--  A walk from one point of a continent's plane to another over the walking data
--  (Walk.lua): the rectangles from the one under the start to the one under the
--  end, through their openings, the shortest by A* (each step costs the way from
--  where the rectangle was entered to the nearest point of the opening, water
--  twice that); then the line pulled straight through the openings it passes
--  (a funnel: corners only where something is in the way), the openings drawn in
--  a little from their ends so the line does not graze a wall. Knows no frames.
--
--      Search.Walk(continent, u1, v1, u2, v2)  in one go: points { u1, v1, u2, v2, ... } and the cost
--                                              in yards, or nil (no way on foot, or no data)
--      Search.Start(continent, u1, v1, u2, v2, done)  as a job of Core's scheduler, a few milliseconds a
--                                              frame and never in a fight: done(points, cost) once found
--                                              (nil, nil: none); gives the job (job:Stop())
--
--  Both ends are put on the nearest rectangle within Search.REACH yards. Two ends
--  in different regions are no walk at all, known at once.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Walk = ns.Walk
local Search = {}
ns.Search = Search

Search.REACH = 40       -- yards an end may be from the walking data's nearest rectangle
Search.WATER = 2        -- swimming costs so many times walking
Search.EDGE = 0.8       -- yards an opening is drawn in from its ends
Search.MOST = 200000    -- rectangles looked at, at most, before a search gives up
Search.EVERY = 64       -- rectangles looked at between two looks at the frame's time

local floor = math.floor
local function Id(tile, index) return tile.key * 65536 + index end

-- The ends: a rectangle under the point (or the nearest), each end's rectangles with the region both share.
local function Ends(continent, u1, v1, u2, v2)
    local starts, ends = Walk.Under(continent, u1, v1), Walk.Under(continent, u2, v2)
    for _, a in ipairs(starts) do
        local _, _, _, _, _, _, region = Walk.Rect(a[1], a[2])
        for _, b in ipairs(ends) do
            local _, _, _, _, _, _, other = Walk.Rect(b[1], b[2])
            if region == other then return a[1], a[2], u1, v1, b[1], b[2], u2, v2 end
        end
    end
    -- Not both on one region's floor: the nearest of each, the end's within the start's region.
    local st, si, su, sv
    if starts[1] then
        st, si, su, sv = starts[1][1], starts[1][2], u1, v1
    else
        st, si, su, sv = Walk.Nearest(continent, u1, v1, Search.REACH)
    end
    if not st then return nil end
    local _, _, _, _, _, _, region = Walk.Rect(st, si)
    local et, ei, eu, ev = Walk.Nearest(continent, u2, v2, Search.REACH, region)
    if not et then return nil end
    return st, si, su, sv, et, ei, eu, ev
end

-- The nearest point of a segment to a point.
local function Closest(u, v, au, av, bu, bv)
    local du, dv = bu - au, bv - av
    local length = du * du + dv * dv
    if length == 0 then return au, av end
    local t = ((u - au) * du + (v - av) * dv) / length
    t = math.max(0, math.min(1, t))
    return au + du * t, av + dv * t
end

-- A binary heap of node ids by their f.
local function Push(heap, f, id)
    local n = #heap + 1
    heap[n] = id
    while n > 1 do
        local parent = floor(n / 2)
        if f[heap[parent]] <= f[heap[n]] then break end
        heap[parent], heap[n] = heap[n], heap[parent]
        n = parent
    end
end

local function Pop(heap, f)
    local top = heap[1]
    local last = table.remove(heap)
    if #heap == 0 then return top end
    heap[1] = last
    local n, size = 1, #heap
    while true do
        local left, right, small = n * 2, n * 2 + 1, n
        if left <= size and f[heap[left]] < f[heap[small]] then small = left end
        if right <= size and f[heap[right]] < f[heap[small]] then small = right end
        if small == n then break end
        heap[small], heap[n] = heap[n], heap[small]
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
    -- A corner reached twice in a row (the funnel came back to its apex) is one.
    local clean = { points[1], points[2] }
    for index = 3, #points, 2 do
        local u, v = points[index], points[index + 1]
        if math.abs(u - clean[#clean - 1]) > 0.5 or math.abs(v - clean[#clean]) > 0.5 then
            clean[#clean + 1], clean[#clean + 2] = u, v
        end
    end
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
local function Run(continent, u1, v1, u2, v2, check)
    if not Walk.Ready() then return nil end
    local st, si, su, sv, et, ei, eu, ev = Ends(continent, u1, v1, u2, v2)
    if not st then return nil end
    local _, _, _, _, _, _, startRegion = Walk.Rect(st, si)
    local _, _, _, _, _, _, endRegion = Walk.Rect(et, ei)
    if startRegion ~= endRegion then return nil end
    local start, goal = Id(st, si), Id(et, ei)
    local g, f, from, enterU, enterV, via = {}, {}, {}, {}, {}, {}
    local tiles, indexes = { [start] = st }, { [start] = si }
    local closed = {}
    local heap = {}
    g[start], enterU[start], enterV[start] = 0, su, sv
    f[start] = math.sqrt((eu - su) ^ 2 + (ev - sv) ^ 2)
    Push(heap, f, start)
    local seen = 0
    while heap[1] do
        local id = Pop(heap, f)
        if id == goal then break end
        if not closed[id] then
            closed[id] = true
            seen = seen + 1
            if seen > Search.MOST then return nil end
            if seen % Search.EVERY == 0 and check then check() end
            local tile, index = tiles[id], indexes[id]
            local _, _, _, _, _, kind = Walk.Rect(tile, index)
            local weight = kind == Walk.WATER and Search.WATER or 1
            local fu, fv = enterU[id], enterV[id]
            Walk.Openings(tile, index, function(side, first, last, next, other)
                local nid = Id(next, other)
                if closed[nid] then return end
                local au, av, bu, bv = Walk.Portal(tile, index, side, first, last)
                local pu, pv = Closest(fu, fv, au, av, bu, bv)
                local cost = g[id] + math.sqrt((pu - fu) ^ 2 + (pv - fv) ^ 2) * weight
                if g[nid] == nil or cost < g[nid] then
                    g[nid], from[nid], via[nid] = cost, id, { tile, index, side, first, last }
                    enterU[nid], enterV[nid] = pu, pv
                    tiles[nid], indexes[nid] = next, other
                    f[nid] = cost + math.sqrt((eu - pu) ^ 2 + (ev - pv) ^ 2)
                    Push(heap, f, nid)
                end
            end)
        end
    end
    if g[goal] == nil then return nil end
    -- The openings passed, from the start to the end.
    local list = {}
    local id = goal
    while id ~= start do
        local step = via[id]
        table.insert(list, 1, Portal(step[1], step[2], step[3], step[4], step[5]))
        id = from[id]
    end
    local _, _, _, _, _, kind = Walk.Rect(et, ei)
    local last = math.sqrt((eu - enterU[goal]) ^ 2 + (ev - enterV[goal]) ^ 2) * (kind == Walk.WATER and Search.WATER or 1)
    local points = Funnel(su, sv, list, eu, ev)
    return points, g[goal] + last
end

function Search.Walk(continent, u1, v1, u2, v2)
    return Run(continent, u1, v1, u2, v2, nil)
end

-- As a job of Core's scheduler: done(points, cost) when found, done(nil) when there is none; the job stops
-- when asked (job:Stop()) and waits in a fight.
local jobs = 0
function Search.Start(continent, u1, v1, u2, v2, done)
    jobs = jobs + 1
    local result, cost
    return Core.Steps.Run({ name = "navigation: walk " .. jobs, label = "navigation: route", done = function(problem)
        if problem then return done(nil) end
        done(result, cost)
    end }, function()
        result, cost = Run(continent, u1, v1, u2, v2, Core.Steps.Check)
    end)
end
