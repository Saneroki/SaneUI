local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Planner
--  The way to the game's map pin, drawn as the golden line (Route.lua), while the
--  setting Route to the map pin is on. Knows no frames.
--
--      the journey   on the player's continent: on foot all the way, or on foot to a flight point
--                    this character knows, flights between known ones (the game's flights, Core's set
--                    Travel, as only its side flies them), on foot from the last; each walk guessed at
--                    Planner.DETOUR times the straight line, each flight at its way's length, and the
--                    quickest taken (a small graph, Dijkstra)
--      the walks     then searched on the walking data (Search.lua, a job of Core's scheduler); a walk
--                    found much longer than its guess is put in at its true length and the journey
--                    chosen again, once
--      without data  (the pack Routes not installed): a straight line to the pin
--      planned again when the pin moves, when the player has left the line by Planner.OFF yards, or
--                    when a flight has landed; never more often than every Planner.AGAIN seconds
--
--  The flight points this character knows are read at the flight master (the game's flight map
--  tells them, TAXIMAP_OPENED) and kept for the character: the world map's own list calls every
--  point known on this client. Ships and zeppelins are not in the plan yet: their timetables are not
--  in the game's tables; a pin on another continent gets no line.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live, Walk, Search = ns.Coords, ns.Live, ns.Walk, ns.Search
local Planner = {}
ns.Planner = Planner

Planner.RUN = 7          -- yards a second on foot, the game's run speed
Planner.FLY = 30         -- yards a second on a flight, about the game's flights
Planner.BOARD = 8        -- seconds a flight takes besides its way: taking off, landing
Planner.DETOUR = 1.3     -- a walk not searched yet is guessed at so many times the straight line
Planner.WORSE = 1.6      -- a walk found this much longer than its guess makes the journey be chosen again
Planner.OFF = 40         -- yards off the line that make a new plan
Planner.AGAIN = 3        -- seconds at least between two plans
Planner.LOOK = 1         -- seconds between two looks whether the player left the line

local Travel = Core.Data.Set("Travel")
local target            -- { map, u, v }: the pin in its continent's plane
local plan              -- the journey being planned or drawn: { legs, at, made }
local jobs = {}         -- the walks being searched
local lastPlan, nextLook = -math.huge, 0
local onTaxi = false
local told = {}

-------------------------------------------------------------------------------
--  Flight points
-------------------------------------------------------------------------------
-- The flight points this character knows, kept for it ({ [node ID] = true }).
local function Known()
    local char = Core.Character(ns.name)
    char.flights = char.flights or {}
    return char.flights
end

local Points -- (below)

-- At the flight master: every flight point the game's flight map lists is one this character knows (by its
-- ID; on the game's older flight master window by its name, among the flight points of the player's continent).
local function Learn()
    local known = Known()
    local get = C_TaxiMap and C_TaxiMap.GetAllTaxiNodes
    local map = rawget(_G, "GetTaxiMapID") and Core.Plain(Core.Ask(GetTaxiMapID))
    local listed = get and map and Core.Ask(get, map)
    if type(listed) == "table" and #listed > 0 then
        for _, info in ipairs(listed) do
            if info.nodeID then known[info.nodeID] = true end
        end
        return
    end
    local count = rawget(_G, "NumTaxiNodes") and Core.Plain(Core.Ask(NumTaxiNodes)) or 0
    local continent = Live.Player()
    if count == 0 or not continent then return end
    local byName = {}
    for node, point in pairs(Points(continent)) do byName[point.name] = node end
    for index = 1, count do
        local kind = Core.Ask(TaxiNodeGetType, index)
        local node = kind and kind ~= "NONE" and byName[Core.Ask(TaxiNodeName, index)]
        if node then known[node] = true end
    end
end

-- The flight points of a continent the player's side may use: { [node ID] = { u, v, name } }, in its plane.
Points = function(continent)
    local found = {}
    local faction = Core.Plain(UnitFactionGroup("player"))
    local sides = rawget(_G, "Enum") and Enum.FlightPathFaction or {}
    for _, info in ipairs(Live.Flights(continent)) do
        local side = info.faction
        local ours = not ((side == sides.Horde and faction ~= "Horde") or (side == sides.Alliance and faction ~= "Alliance"))
        local position = info.position
        local x, y = position and Core.Plain(position.x), position and Core.Plain(position.y)
        if ours and x and y and info.nodeID then
            local u, v = Coords.MapToPlane(continent, x, y, continent)
            if u then found[info.nodeID] = { u = u, v = v, name = info.name } end
        end
    end
    return found
end

-- The flights from a flight point this character may take: { { to, seconds, flight } }.
local function Flights(node, points, known)
    local list = {}
    local side = Core.Plain(UnitFactionGroup("player"))
    side = side and side:lower()
    for _, key in ipairs(Travel:Keys("byFromNode", node)) do
        local flight = Travel:Get(key)
        local to = flight and flight.toNode
        if to and known[to] and points[to] and flight.kind == "flight" and (not flight.side or flight.side == side) then
            local length = flight.length
            if not length then
                local a, b = points[node], points[to]
                length = math.sqrt((a.u - b.u) ^ 2 + (a.v - b.v) ^ 2)
            end
            list[#list + 1] = { to = to, seconds = length / Planner.FLY + Planner.BOARD, flight = flight }
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  The journey
-------------------------------------------------------------------------------
local function Distance(au, av, bu, bv)
    return math.sqrt((au - bu) ^ 2 + (av - bv) ^ 2)
end

-- The region of the walking data under a point (nil: none, or the data not there).
local function Region(continent, u, v)
    local under = Walk.Under(continent, u, v)
    local first = under[1]
    if not first then
        local tile, index = Walk.Nearest(continent, u, v, Search.REACH)
        if not tile then return nil end
        first = { tile, index }
    end
    local _, _, _, _, _, _, region = Walk.Rect(first[1], first[2])
    return region
end

-- The quickest journey by the guesses: a list of steps { kind = "walk" | "flight", ... } and its seconds.
-- known walks: { ["from:to"] = seconds } measured ones in place of guesses.
local function Journey(continent, pu, pv, tu, tv, measured)
    local points, known = Points(continent), Known()
    local useData = Walk.Ready()
    local startRegion = useData and Region(continent, pu, pv)
    local endRegion = useData and Region(continent, tu, tv)
    local function Walking(fromKey, au, av, toKey, bu, bv)
        local key = fromKey .. ":" .. toKey
        if measured[key] then return measured[key] end
        return Distance(au, av, bu, bv) * Planner.DETOUR / Planner.RUN
    end
    -- Dijkstra over: the start, the known flight points, the end.
    local best = { start = 0 }
    local from, how = {}, {}
    local done = {}
    local nodes = { "end" }
    for node in pairs(points) do
        if known[node] then nodes[#nodes + 1] = node end
    end
    local function Place(name)
        if name == "start" then return pu, pv end
        if name == "end" then return tu, tv end
        return points[name].u, points[name].v
    end
    -- The region of the walking data a place stands in (nil: not known; walks are then not ruled out).
    local regions = {}
    local function RegionOf(name)
        if not useData then return nil end
        if name == "start" then return startRegion end
        if name == "end" then return endRegion end
        if regions[name] == nil then
            local u, v = Place(name)
            regions[name] = Region(continent, u, v) or false
        end
        return regions[name] or nil
    end
    while true do
        local current, low
        for name, seconds in pairs(best) do
            if not done[name] and (not low or seconds < low) then current, low = name, seconds end
        end
        if not current or current == "end" then break end
        done[current] = true
        local cu, cv = Place(current)
        -- On foot: to every known flight point and to the end, within the same region.
        local region = RegionOf(current)
        for _, node in ipairs(nodes) do
            local other = node ~= current and not done[node] and RegionOf(node)
            if node ~= current and not done[node] and (region == nil or other == nil or other == region) then
                local nu, nv = Place(node)
                local seconds = low + Walking(current, cu, cv, node, nu, nv)
                if not best[node] or seconds < best[node] then
                    best[node], from[node], how[node] = seconds, current, "walk"
                end
            end
        end
        -- By air: the flights from a flight point.
        if current ~= "start" then
            for _, flight in ipairs(Flights(current, points, known)) do
                local seconds = low + flight.seconds
                if not done[flight.to] and (not best[flight.to] or seconds < best[flight.to]) then
                    best[flight.to], from[flight.to], how[flight.to] = seconds, current, flight.flight
                end
            end
        end
    end
    if not best["end"] then return nil end
    local steps = {}
    local at = "end"
    while at ~= "start" do
        local previous = from[at]
        local au, av = Place(previous)
        local bu, bv = Place(at)
        if how[at] == "walk" then
            table.insert(steps, 1, { kind = "walk", from = previous, to = at, u1 = au, v1 = av, u2 = bu, v2 = bv,
                                     guess = Walking(previous, au, av, at, bu, bv) })
        else
            table.insert(steps, 1, { kind = "flight", from = previous, to = at, u1 = au, v1 = av, u2 = bu, v2 = bv,
                                     flight = how[at] })
        end
        at = previous
    end
    -- Walks one after the other (through a flight point not flown from) are one walk.
    local joined = {}
    for _, step in ipairs(steps) do
        local last = joined[#joined]
        if last and last.kind == "walk" and step.kind == "walk" then
            last.to, last.u2, last.v2, last.guess = step.to, step.u2, step.v2, last.guess + step.guess
        else
            joined[#joined + 1] = step
        end
    end
    return joined, best["end"]
end

-- A flight's points in the continent's plane: its way as the game's path has it, else its two ends.
local function FlightPoints(continent, step)
    local points = {}
    local path = step.flight and step.flight.path
    local box = Coords.Box(continent)
    if path and box then
        for _, point in ipairs(path) do
            -- The world's yards: x to the north, y to the west; the plane: u = -y, v = x.
            points[#points + 1] = { map = continent, u = -point.y, v = point.x }
        end
    end
    if #points < 2 then
        points = { { map = continent, u = step.u1, v = step.v1 }, { map = continent, u = step.u2, v = step.v2 } }
    end
    return points
end

local function Stop()
    for _, job in ipairs(jobs) do job:Stop() end
    wipe(jobs)
end

-- The journey drawn once every walk of it is found (or, without the walking data, at once, straight).
local function Draw(continent, steps)
    local legs = {}
    for _, step in ipairs(steps) do
        if step.kind == "walk" then
            local points = {}
            local list = step.points or { step.u1, step.v1, step.u2, step.v2 }
            for index = 1, #list, 2 do points[#points + 1] = { map = continent, u = list[index], v = list[index + 1] } end
            legs[#legs + 1] = { kind = "walk", points = points }
        else
            legs[#legs + 1] = { kind = "flight", points = FlightPoints(continent, step) }
        end
    end
    plan = { legs = legs, at = 1, continent = continent }
    ns.Route.Show(plan)
end

local Make -- (below)

-- Every walk of the journey searched, one after the other; a walk much longer than guessed, once: chosen again.
local function Walks(continent, pu, pv, tu, tv, steps, measured, again)
    Stop()
    local pending = {}
    for _, step in ipairs(steps) do
        if step.kind == "walk" then pending[#pending + 1] = step end
    end
    local function Next(index)
        local step = pending[index]
        if not step then return Draw(continent, steps) end
        jobs[1] = Search.Start(continent, step.u1, step.v1, step.u2, step.v2, function(points, cost)
            jobs[1] = nil
            if points then
                step.points = points
                local seconds = cost / Planner.RUN
                measured[step.from .. ":" .. step.to] = seconds
                if again and seconds > step.guess * Planner.WORSE then
                    return Make(continent, pu, pv, tu, tv, measured, false)
                end
            end
            Next(index + 1)
        end)
        if not jobs[1] then Next(index + 1) end -- the scheduler would not take it: drawn without
    end
    Next(1)
end

Make = function(continent, pu, pv, tu, tv, measured, again)
    local steps = Journey(continent, pu, pv, tu, tv, measured)
    if not steps then
        return ns.Route.Show(nil)
    end
    if not Walk.Ready() then return Draw(continent, steps) end
    Walks(continent, pu, pv, tu, tv, steps, measured, again)
end

-- Plans the way from the player to the target now.
local function Plan()
    lastPlan = GetTime()
    if not target then return ns.Route.Show(nil) end
    local map, pu, pv = Live.Player()
    if not pu then return end
    if map ~= target.map then
        if not told.sea then
            told.sea = true
            ns.Print(Planner.TEXT.sea)
        end
        return ns.Route.Show(nil)
    end
    Make(map, pu, pv, target.u, target.v, {}, true)
end

-------------------------------------------------------------------------------
--  Following the pin and the player
-------------------------------------------------------------------------------
Planner.TEXT = {
    sea = "the map pin is on another continent: routes do not cross the sea yet.",
}

-- The pin moved, came or went: planned anew (or the line goes).
function Planner.Update()
    Stop()
    local wanted = ns.options.route and not ns.off
    local map, x, y = Live.Waypoint()
    if not wanted or not map then
        target, plan = nil, nil
        return ns.Route.Show(nil)
    end
    local continent = Coords.ContinentOf(map)
    local u, v
    if continent then u, v = Coords.MapToPlane(map, x, y, continent) end
    if not u then
        target = nil
        return ns.Route.Show(nil)
    end
    target = { map = continent, u = u, v = v }
    Plan()
end

-- The distance of a point from the drawn line's next walk.
local function Off(u, v)
    if not plan then return 0 end
    local leg = plan.legs[1]
    if not leg or leg.kind ~= "walk" then return 0 end
    local best
    local points = leg.points
    for index = 1, #points - 1 do
        local a, b = points[index], points[index + 1]
        local du, dv = b.u - a.u, b.v - a.v
        local length = du * du + dv * dv
        local t = length > 0 and math.max(0, math.min(1, ((u - a.u) * du + (v - a.v) * dv) / length)) or 0
        local gap = Distance(u, v, a.u + du * t, a.v + dv * t)
        if not best or gap < best then best = gap end
    end
    return best or 0
end

-- A step of the canvas' tracker: the player's place (Route.Track). Planned again when the player left the line,
-- and after a flight landed.
function Planner.Track(map, u, v, now)
    if not target or not u or now < nextLook then return end
    nextLook = now + Planner.LOOK
    local flying = rawget(_G, "UnitOnTaxi") and UnitOnTaxi("player") and true or false
    if flying then
        onTaxi = true
        return
    end
    if onTaxi then
        onTaxi = false
        if now - lastPlan >= Planner.AGAIN then return Plan() end
    end
    if #jobs == 0 and now - lastPlan >= Planner.AGAIN and (map ~= (plan and plan.continent) or Off(u, v) > Planner.OFF) then
        Plan()
    end
end

ns.On("TAXIMAP_OPENED", function() ns.Safe("flight points", Learn) end)
-- The walking data or the flights arrived (a pin set before them got a straight line): planned again.
local function Arrived()
    if target then ns.Guarded(Plan) end
end
Core.Data.Set("Walking"):OnStamp(Arrived)
Travel:OnStamp(Arrived)
ns.Listen("LIVE", function(what)
    if what == "waypoint" then ns.Guarded(Planner.Update) end
end)
