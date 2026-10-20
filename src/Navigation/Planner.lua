local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Planner
--  The way to the game's map pin, drawn as the golden line (Route.lua), while the
--  setting Route to the map pin is on. Knows no frames.
--
--      the journey   a small graph over the player, the pin, the flight points this character knows, the docks
--                    of the boats and zeppelins and the hearthstone's place, on the continents of the player and
--                    the pin; its ways: on foot between two places of one continent (guessed at Planner.DETOUR
--                    times the straight line, within one region of the walking data), the flights between known
--                    flight points (the game's, Core's set Travel, as only its side flies them; each at its way's
--                    length), the boats and zeppelins from dock to dock (Core's set Travel, the game's own ways of
--                    them: the wait for one and the trip, Planner.Ship), the hearthstone from the player to its
--                    place (its cooldown and the cast); the quickest taken (Dijkstra)
--      the walks     then searched on the walking data (Search.lua, a job of Core's scheduler); a walk
--                    found much longer than its guess is put in at its true length and the journey
--                    chosen again, once
--      without data  (the pack Routes not installed): each walk a straight line
--      planned again when the pin moves, when the player has left the line by Planner.OFF yards, or
--                    when a flight has landed; never more often than every Planner.AGAIN seconds. Aboard a
--                    boat or a zeppelin the line stays, and a new pin is planned from where it lands.
--
--  The flight points this character knows are read at the flight master (the game's flight map
--  tells them, TAXIMAP_OPENED) and kept for the character: the world map's own list calls every
--  point known on this client. The hearthstone's place is learnt where the character binds it
--  (HEARTHSTONE_BOUND) and where it brings the character, and kept for the character with the
--  game's name of it (GetBindLocation), which tells when it was bound elsewhere since.
--
--  A boat or zeppelin: the game's tables have its way, its docks and how long it stands at each, but
--  neither its speed nor its timetable. Until its time once round is learnt in play (the set's wait),
--  it is guessed to move at Planner.SAIL yards a second and to take Planner.LEAP seconds a leap (onto
--  another continent: a loading screen); once round is then its sailing, its stays and its leaps, and
--  half of that the wait for it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live, Walk, Search = ns.Coords, ns.Live, ns.Walk, ns.Search
local Planner = {}
ns.Planner = Planner

Planner.RUN = 7          -- yards a second on foot, the game's run speed
Planner.FLY = 30         -- yards a second on a flight, about the game's flights
Planner.BOARD = 8        -- seconds a flight takes besides its way: taking off, landing
Planner.SAIL = 25        -- yards a second a boat or zeppelin is guessed to move, until its times are learnt
Planner.LEAP = 10        -- seconds a boat's or zeppelin's leap is guessed to take
Planner.HEARTH = 15      -- seconds the hearthstone takes besides its cooldown: the cast, the loading screen
Planner.DETOUR = 1.3     -- a walk not searched yet is guessed at so many times the straight line
Planner.WORSE = 1.6      -- a walk found this much longer than its guess makes the journey be chosen again
Planner.OFF = 40         -- yards off the line that make a new plan
Planner.ABOARD = 150     -- yards off a boat's or zeppelin's way the player may be and still be aboard
Planner.DOCK = 30        -- yards from the dock it was boarded at, beyond which the player is aboard
Planner.PIER = 40        -- yards from where a boat stops to the floor one boards it from, at most
Planner.SAME = 20        -- yards between two stops at one dock
Planner.AGAIN = 3        -- seconds at least between two plans
Planner.LOOK = 1         -- seconds between two looks whether the player left the line
Planner.HEARTHSTONE, Planner.HOMEWARD = 6948, 8690 -- the hearthstone: its item, its spell

local SHIPS = { "boat", "zeppelin" }
local Travel = Core.Data.Set("Travel")
local target            -- { map, u, v }: the pin in its continent's plane
local plan              -- the journey being planned or drawn: { legs, at, target }
local jobs = {}         -- the walks being searched
local docks             -- every dock, by name, while Core's set Travel stays as it is (Docks)
local planes = {}       -- [the world's map] = the continent's map of its plane, or false
local lastPlan, nextLook = -math.huge, 0
local onTaxi = false
local homeward          -- when the hearthstone was used: its place is where the character is next
local told = {}

local function Distance(au, av, bu, bv)
    return math.sqrt((au - bu) ^ 2 + (av - bv) ^ 2)
end

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

-- The flight points of a continent the player's side may use: { [node ID] = { map, u, v, name } }, in its plane.
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
            if u then found[info.nodeID] = { map = continent, u = u, v = v, name = info.name } end
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
                length = Distance(a.u, a.v, b.u, b.v)
            end
            list[#list + 1] = { to = to, seconds = length / Planner.FLY + Planner.BOARD, flight = flight }
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  Boats and zeppelins
-------------------------------------------------------------------------------
-- The continent's map whose plane is the yards of one of the world's maps (0 the Eastern Kingdoms, 1 Kalimdor),
-- or nil: a map no continent of the game's world map has.
local function Plane(world)
    local found = planes[world]
    if found ~= nil then return found or nil end
    local continents = Coords.Continents()
    for _, continent in ipairs(continents) do
        if Coords.Box(continent).continent == world then found = continent break end
    end
    if #continents > 0 then planes[world] = found or false end
    return found
end

-- The world's map of each point of a transport's way: the last one given at or before it.
local function Worlds(path)
    local worlds, world = {}, nil
    for index, point in ipairs(path) do
        world = point.map or world
        worlds[index] = world
    end
    return worlds
end

-- A boat's or zeppelin's docks and the ways between them, from its record of Core's set Travel: a list of docks
-- { world, x, y, ways = { [other dock] = { seconds, from, till } } }, one for each place it stops at; from and
-- till the indexes of its way's points where one boards and leaves it. seconds: the wait for it (half its way once
-- round) and the trip, its stays at the docks in between included.
function Planner.Ship(way)
    local path = type(way) == "table" and way.path
    if type(path) ~= "table" or #path < 2 then return {} end
    local worlds = Worlds(path)
    -- Along the way to each point: the yards sailed, the leaps, the seconds stood at docks before it.
    local at, leaps, stays = {}, {}, {}
    local yards, leapt, stood = 0, 0, 0
    for index, point in ipairs(path) do
        if index > 1 then
            if point.jump then
                leapt = leapt + 1
            else
                local before = path[index - 1]
                yards = yards + Distance(before.x, before.y, point.x, point.y)
            end
        end
        at[index], leaps[index], stays[index] = yards, leapt, stood
        stood = stood + (point.stay or 0)
    end
    leapt = leapt + 1 -- after its last point it starts again from its first
    -- Its speed: guessed, or the one its time once round makes, learnt in play.
    local speed = Planner.SAIL
    local moving = way.wait and way.wait - stood - leapt * Planner.LEAP
    if moving and moving > 0 and yards > 0 then speed = yards / moving end
    local round = way.wait or yards / speed + stood + leapt * Planner.LEAP
    local function Trip(i, j)
        local sailed, leaping, standing
        if j > i then
            sailed, leaping, standing = at[j] - at[i], leaps[j] - leaps[i], stays[j] - stays[i]
        else
            sailed, leaping, standing = yards - at[i] + at[j], leapt - leaps[i] + leaps[j], stood - stays[i] + stays[j]
        end
        -- Its stay where one boards is part of the wait.
        return sailed / speed + standing - path[i].stay + leaping * Planner.LEAP
    end
    local list, visits, dockOf = {}, {}, {}
    for index, point in ipairs(path) do
        if point.stay then
            local dock
            for _, other in ipairs(list) do
                if other.world == worlds[index] and Distance(other.x, other.y, point.x, point.y) <= Planner.SAME then
                    dock = other
                    break
                end
            end
            if not dock then
                dock = { world = worlds[index], x = point.x, y = point.y, ways = {} }
                list[#list + 1] = dock
            end
            visits[#visits + 1], dockOf[index] = index, dock
        end
    end
    for _, i in ipairs(visits) do
        for _, j in ipairs(visits) do
            local a, b = dockOf[i], dockOf[j]
            if a ~= b then
                local seconds = round / 2 + Trip(i, j)
                if not a.ways[b] or seconds < a.ways[b].seconds then a.ways[b] = { seconds = seconds, from = i, till = j } end
            end
        end
    end
    return list
end

-- Every dock of the boats and zeppelins on a continent of the world map, by name ("dock:<way>:<n>"): { name, map, u,
-- v (where it stops, in the continent's plane), kind, ways = { { to = name, seconds, from, till, kind, way } } }.
-- Made once Core's set Travel is there, again when it changes.
local function Docks()
    if docks then return docks end
    local found = {}
    for _, kind in ipairs(SHIPS) do
        for _, key in ipairs(Travel:Keys("byKind", kind)) do
            local way = Travel:Get(key)
            local list = way and Planner.Ship(way) or {}
            local names = {}
            for index, dock in ipairs(list) do
                local map = Plane(dock.world)
                if map then
                    local name = "dock:" .. key .. ":" .. index
                    names[dock] = name
                    found[name] = { name = name, map = map, u = -dock.y, v = dock.x, kind = kind, ways = {} }
                end
            end
            for _, dock in ipairs(list) do
                local ways = names[dock] and found[names[dock]].ways
                for other, trip in pairs(dock.ways) do
                    if ways and names[other] then
                        ways[#ways + 1] = { to = names[other], seconds = trip.seconds, from = trip.from, till = trip.till,
                                            kind = kind, way = way }
                    end
                end
            end
        end
    end
    if Travel:Ready() and #Coords.Continents() > 0 then docks = found end
    return found
end

-- Where one stands to board at a dock: the nearest floor of land within Planner.PIER yards of where the boat stops
-- (the pier), else that place; worked out once the walking data is there.
local function Pier(dock)
    if dock.pu then return dock.pu, dock.pv end
    if not Walk.Ready() then return dock.u, dock.v end
    local tile, _, u, v = Walk.Nearest(dock.map, dock.u, dock.v, Planner.PIER, nil, Walk.LAND)
    if tile then dock.pu, dock.pv = u, v else dock.pu, dock.pv = dock.u, dock.v end
    return dock.pu, dock.pv
end

-------------------------------------------------------------------------------
--  The hearthstone
-------------------------------------------------------------------------------
-- Its place ({ map, u, v }) and the seconds until it brings the character there (its cooldown, the cast); nil
-- when it cannot: none in the bags, its place not known, or bound elsewhere since.
local function Hearth()
    local place = Core.Character(ns.name).hearth
    if type(place) ~= "table" or not place.map or not place.u or not Coords.Box(place.map) then return nil end
    local bound = rawget(_G, "GetBindLocation") and Core.Ask(GetBindLocation)
    if bound and place.name and bound ~= place.name then return nil end
    local items = rawget(_G, "C_Item")
    local count = items and Core.Ask(items.GetItemCount, Planner.HEARTHSTONE)
    if type(count) ~= "number" or count < 1 then return nil end
    local start, duration = Core.Ask(items.GetItemCooldown, Planner.HEARTHSTONE)
    local left = 0
    if type(start) == "number" and type(duration) == "number" and start > 0 then
        left = math.max(0, start + duration - GetTime())
    end
    return place, left + Planner.HEARTH
end

-- The character's place now as the hearthstone's (where it was bound, or where it brought the character); false
-- while the game does not tell it (a loading screen).
local function Home()
    local map, u, v = Live.Player()
    if not u then return false end
    local name = rawget(_G, "GetBindLocation") and Core.Ask(GetBindLocation)
    Core.Character(ns.name).hearth = { map = map, u = u, v = v, name = name }
    return true
end

-- After the hearthstone was used: its place is where the character stands once it has arrived.
local function Arrived()
    if homeward and GetTime() - homeward < 60 and Home() then homeward = nil end
end
local arriving = Core.Later(Arrived, 2)

-------------------------------------------------------------------------------
--  The journey
-------------------------------------------------------------------------------
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

-- The quickest journey by the guesses from the player (start) to the pin (end): a list of steps { kind = "walk" |
-- "flight" | "boat" | "zeppelin" | "hearth", from, to, map, u1, v1, map2, u2, v2, ... } and its seconds.
-- measured: { ["from:to"] = seconds } walks searched already, in place of their guesses.
local function Journey(startMap, pu, pv, endMap, tu, tv, measured)
    local known = Known()
    local useData = Walk.Ready()
    -- The places: the two ends, and on their continents the known flight points, the docks, the hearthstone's.
    local places = { start = { map = startMap, u = pu, v = pv }, ["end"] = { map = endMap, u = tu, v = tv } }
    local points = {}
    for _, continent in ipairs(startMap == endMap and { startMap } or { startMap, endMap }) do
        for node, point in pairs(Points(continent)) do
            points[node] = point
            if known[node] then places[node] = point end
        end
    end
    for name, dock in pairs(Docks()) do
        if dock.map == startMap or dock.map == endMap then
            local u, v = Pier(dock)
            places[name] = { map = dock.map, u = u, v = v, dock = dock }
        end
    end
    local hearth, homeSeconds = Hearth()
    if hearth and (hearth.map == startMap or hearth.map == endMap) then
        places.hearth = { map = hearth.map, u = hearth.u, v = hearth.v }
    end
    local function Walking(fromName, a, toName, b)
        return measured[fromName .. ":" .. toName] or Distance(a.u, a.v, b.u, b.v) * Planner.DETOUR / Planner.RUN
    end
    -- The region of the walking data a place stands in (nil: not known; walks are then not ruled out).
    local regions = {}
    local function RegionOf(name)
        if not useData then return nil end
        if regions[name] == nil then
            local place = places[name]
            regions[name] = Region(place.map, place.u, place.v) or false
        end
        return regions[name] or nil
    end
    -- Dijkstra over the places.
    local best, from, how, done = { start = 0 }, {}, {}, {}
    local current, low
    local function Reach(name, seconds, way)
        if not done[name] and (not best[name] or seconds < best[name]) then
            best[name], from[name], how[name] = seconds, current, way
        end
    end
    while true do
        current, low = nil, nil
        for name, seconds in pairs(best) do
            if not done[name] and (not low or seconds < low) then current, low = name, seconds end
        end
        if not current or current == "end" then break end
        done[current] = true
        local here = places[current]
        -- On foot: to every place of the same continent, within the same region.
        local region = RegionOf(current)
        for name, place in pairs(places) do
            if not done[name] and place.map == here.map then
                local other = RegionOf(name)
                if region == nil or other == nil or other == region then
                    Reach(name, low + Walking(current, here, name, place), "walk")
                end
            end
        end
        -- By air: the flights from a flight point.
        if points[current] then
            for _, flight in ipairs(Flights(current, points, known)) do Reach(flight.to, low + flight.seconds, flight.flight) end
        end
        -- By sea or air: the boats and zeppelins from a dock.
        if here.dock then
            for _, ship in ipairs(here.dock.ways) do
                if places[ship.to] then Reach(ship.to, low + ship.seconds, ship) end
            end
        end
        -- Home: the hearthstone from where the player is.
        if current == "start" and places.hearth then Reach("hearth", low + homeSeconds, "hearth") end
    end
    if not best["end"] then return nil end
    local steps = {}
    local at = "end"
    while at ~= "start" do
        local previous, way = from[at], how[at]
        local a, b = places[previous], places[at]
        local step = { from = previous, to = at, map = a.map, u1 = a.u, v1 = a.v, map2 = b.map, u2 = b.u, v2 = b.v }
        if way == "walk" then
            step.kind, step.guess = "walk", Walking(previous, a, at, b)
        elseif way == "hearth" then
            step.kind = "hearth"
        elseif way.kind == "flight" then
            step.kind, step.flight = "flight", way
        else
            step.kind, step.ship = way.kind, way
        end
        table.insert(steps, 1, step)
        at = previous
    end
    -- Walks one after the other (through a flight point not flown from, a dock not sailed from) are one walk.
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
local function FlightPoints(step)
    local points = {}
    local path = step.flight and step.flight.path
    if path and Coords.Box(step.map) then
        for _, point in ipairs(path) do
            -- The world's yards: x to the north, y to the west; the plane: u = -y, v = x.
            points[#points + 1] = { map = step.map, u = -point.y, v = point.x }
        end
    end
    if #points < 2 then
        points = { { map = step.map, u = step.u1, v = step.v1 }, { map = step.map2, u = step.u2, v = step.v2 } }
    end
    return points
end

-- A boat's or zeppelin's points: from the pier it is boarded at along its way to the pier it is left at, each point
-- in its continent's plane (one on a map no continent has, left out).
local function ShipPoints(step)
    local ship = step.ship
    local path = ship.way.path
    local worlds = Worlds(path)
    local points = { { map = step.map, u = step.u1, v = step.v1 } }
    local index = ship.from
    while true do
        local point, map = path[index], Plane(worlds[index])
        if map then points[#points + 1] = { map = map, u = -point.y, v = point.x } end
        if index == ship.till then break end
        index = index % #path + 1
    end
    points[#points + 1] = { map = step.map2, u = step.u2, v = step.v2 }
    return points
end

local function Stop()
    for _, job in ipairs(jobs) do job:Stop() end
    wipe(jobs)
end

-- The journey drawn once every walk of it is found (or, without the walking data, at once, straight); keep: a leg
-- drawn in front of it (the boat or zeppelin the player is aboard).
local function Draw(steps, keep)
    local legs = { keep }
    for _, step in ipairs(steps) do
        if step.kind == "walk" then
            local points = {}
            local list = step.points or { step.u1, step.v1, step.u2, step.v2 }
            for index = 1, #list, 2 do points[#points + 1] = { map = step.map, u = list[index], v = list[index + 1] } end
            legs[#legs + 1] = { kind = "walk", points = points }
        elseif step.kind == "flight" then
            legs[#legs + 1] = { kind = "flight", points = FlightPoints(step) }
        elseif step.kind == "hearth" then
            legs[#legs + 1] = { kind = "hearth", points = { { map = step.map, u = step.u1, v = step.v1 },
                                                            { map = step.map2, u = step.u2, v = step.v2 } } }
        else
            legs[#legs + 1] = { kind = step.kind, ship = true, points = ShipPoints(step) }
        end
    end
    plan = { legs = legs, at = 1, target = target }
    ns.Route.Show(plan)
end

local Make -- (below)

-- Every walk of the journey searched, one after the other; a walk much longer than guessed, once: chosen again.
local function Walks(start, steps, measured, again)
    Stop()
    local pending = {}
    for _, step in ipairs(steps) do
        if step.kind == "walk" then pending[#pending + 1] = step end
    end
    local function Next(index)
        local step = pending[index]
        if not step then return Draw(steps, start.keep) end
        jobs[1] = Search.Start(step.map, step.u1, step.v1, step.u2, step.v2, function(points, cost)
            jobs[1] = nil
            if points then
                step.points = points
                local seconds = cost / Planner.RUN
                measured[step.from .. ":" .. step.to] = seconds
                if again and seconds > step.guess * Planner.WORSE then
                    return Make(start, measured, false)
                end
            end
            Next(index + 1)
        end)
        if not jobs[1] then Next(index + 1) end -- the scheduler would not take it: drawn without
    end
    Next(1)
end

-- start: { map, u, v, keep } where the journey begins, and the leg drawn in front of it.
Make = function(start, measured, again)
    local steps = Journey(start.map, start.u, start.v, target.map, target.u, target.v, measured)
    if not steps then
        if start.map ~= target.map and Travel:Ready() and not told.sea then
            told.sea = true
            ns.Print(Planner.TEXT.sea)
        end
        plan = nil
        return ns.Route.Show(nil)
    end
    if not Walk.Ready() then return Draw(steps, start.keep) end
    Walks(start, steps, measured, again)
end

-- How far a point of a continent's plane is from a leg of the line; nil when no part of it lies on that continent.
local function Gap(leg, map, u, v)
    if not leg then return nil end
    local best
    local points = leg.points
    for index = 1, #points do
        local a, b = points[index], points[index + 1]
        if a.map == map then
            local gap
            if b and b.map == map then
                local du, dv = b.u - a.u, b.v - a.v
                local length = du * du + dv * dv
                local t = length > 0 and math.max(0, math.min(1, ((u - a.u) * du + (v - a.v) * dv) / length)) or 0
                gap = Distance(u, v, a.u + du * t, a.v + dv * t)
            else
                gap = Distance(u, v, a.u, a.v)
            end
            if not best or gap < best then best = gap end
        end
    end
    return best
end

-- The boat's or zeppelin's leg the player is aboard: the leg the line is at, or the next, is one; the player is
-- more than Planner.DOCK yards from where it was boarded, within Planner.ABOARD yards of its way, not swimming.
local function Aboard(map, u, v)
    if not plan or (rawget(_G, "IsSwimming") and IsSwimming()) then return nil end
    for index = plan.at, plan.at + 1 do
        local leg = plan.legs[index]
        local first = leg and leg.ship and leg.points[1]
        if first and (first.map ~= map or Distance(u, v, first.u, first.v) > Planner.DOCK) then
            local gap = Gap(leg, map, u, v)
            if gap and gap <= Planner.ABOARD then return leg, index end
        end
    end
    return nil
end

-- Plans the way from the player to the target now; aboard a boat or zeppelin, from where it lands.
local function Plan()
    lastPlan = GetTime()
    if not target then return ns.Route.Show(nil) end
    local map, pu, pv = Live.Player()
    if not pu then return end
    local leg = Aboard(map, pu, pv)
    if leg then
        local last = leg.points[#leg.points]
        return Make({ map = last.map, u = last.u, v = last.v, keep = leg }, {}, true)
    end
    Make({ map = map, u = pu, v = pv }, {}, true)
end

-------------------------------------------------------------------------------
--  Following the pin and the player
-------------------------------------------------------------------------------
Planner.TEXT = {
    sea = "no way to the map pin's continent is known yet: no line.",
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
        target, plan = nil, nil
        return ns.Route.Show(nil)
    end
    target = { map = continent, u = u, v = v }
    Plan()
end

-- A step of the canvas' tracker: the player's place (Route.Track). The line moves on to its next leg when the
-- player is nearer to that; planned again when the player left the line (aboard a boat or zeppelin: its way), and
-- after a flight landed.
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
    if #jobs > 0 or now - lastPlan < Planner.AGAIN then return end
    if not plan then return Plan() end
    local here, next = Gap(plan.legs[plan.at], map, u, v), Gap(plan.legs[plan.at + 1], map, u, v)
    if next and (not here or next < here) then
        plan.at, here = plan.at + 1, next
        ns.Route.Show(plan) -- the legs after the next are drawn fainter
    end
    local leg = plan.legs[plan.at]
    if not here or here > (leg and leg.ship and Planner.ABOARD or Planner.OFF) then Plan() end
end

ns.On("TAXIMAP_OPENED", function() ns.Safe("flight points", Learn) end)
ns.On("HEARTHSTONE_BOUND", function() ns.Safe("hearthstone", Home) end)
Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spell)
    if spell == Planner.HOMEWARD and not ns.off then
        homeward = GetTime()
        arriving()
    end
end)
-- A loading screen after the hearthstone (onto another continent): its place once the game tells it.
ns.On("PLAYER_ENTERING_WORLD", function()
    if homeward then arriving() end
end)
-- The walking data or the flights arrived (a pin set before them got a straight line): planned again.
local function Changed()
    if target then ns.Guarded(Plan) end
end
Core.Data.Set("Walking"):OnStamp(Changed)
Travel:OnStamp(function()
    docks = nil
    Changed()
end)
ns.Listen("LIVE", function(what)
    if what == "waypoint" then ns.Guarded(Planner.Update) end
end)
