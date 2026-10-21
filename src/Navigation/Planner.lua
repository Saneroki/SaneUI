local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Planner
--  The way to the game's map pin, drawn as the golden line (Route.lua), while the
--  setting Route to the map pin is on. Knows no frames.
--
--      the journey   a graph over the player, the pin, the flight points this character knows, the docks of the
--                    boats and zeppelins, the cities' entrances to the tram and the hearthstone's place, on every
--                    plane (a continent, or a map of its own on the world map: Zephras Isle, Coords.Planes), so
--                    a journey may cross a third one (the hearthstone home, then a ship over the sea); its ways:
--                    on foot between two places of one plane (guessed at Planner.DETOUR times the straight line;
--                    between places that share no region of the walking data Planner.APART seconds more: a tower,
--                    a gap in the walking data, taken only where nothing else goes), the flights between known
--                    flight points
--                    (the game's, Core's set Travel, as only its side flies them; each at its way's length, taking
--                    off and landing once, Planner.BOARD, however many flight points it passes over), the boats and
--                    zeppelins from dock to dock (Core's set Travel, the game's own ways of them: the wait for one
--                    and the trip, Planner.Ship), the tram from one city's entrance to it to the other's (Core's
--                    set Travel: the way down and up, the wait for a train, its next where a ride taught its
--                    times, and its run, Tram), the lifts from one end to the other (Core's set Travel, each end at
--                    its landing, Lifts.lua: the wait for the car, half the time between two departures, and its
--                    ride), the hearthstone from the player to its place (its cooldown and the cast); the quickest
--                    taken (Dijkstra). Between two levels a lift joins (Thunder Bluff's mesa and Mulgore), or a
--                    level and a place below it (the Undercity under the ruins over it, Lifts.Stand; also where
--                    the two share a region), no walk: the lift is the way
--      the walks     then searched on the walking data (Search.lua): the first from the floor the player stands
--                    on, the others from the floor of the lift's landing they start at, else from every floor at
--                    the place they start; a walk found much longer than its guess is put in at its true length and
--                    the journey chosen again, once. The journey and its
--                    walks are one job of Core's scheduler (a few milliseconds a frame, never in a fight); a new
--                    pin stops it, and the line of the pin before goes at once
--      the floor     the player's, followed as they go (Walk.Follow, every Planner.FOOT seconds while there is a
--                    pin): the game tells no height, and floors lie one over the other (a cave under a hill, a
--                    city in a mountain, a building's storeys); where it cannot be followed (the first plan, a
--                    loading screen), the one Walk.Floor chooses (outdoors the highest, indoors the lowest); a lift
--                    of the line ridden (Rode), the landing at its other end
--      without data  (the set Walking not there, or a plane it has nothing of): each walk a straight line
--      the line      always from the player: at every step of the canvas' tracker where along it the player is
--                    (the cut: of the next Planner.AHEAD parts of it, the first within Planner.SLACK yards of the
--                    nearest), and it is drawn from the player's arrow to that point and on from there (Route.Cut);
--                    what lies behind is gone, the legs after the next are fainter
--      planned again when the pin moves, when the player is Planner.OFF yards off the line (Planner.ABOARD
--                    from a ship's way), after a flight or a ship has landed, and when the data arrives; never
--                    more often than every Planner.AGAIN seconds. Aboard a boat or a zeppelin the line stays; a
--                    new pin then is planned from where it lands, its way on in front (the ship the plan has, or
--                    the one Core's Data.Trips finds the player on, to the pier of its next dock); in the tram's
--                    tunnel (a map of no plane) the line stays as it is
--      on a flight   its way on (Core's Data.Trips), drawn anew from where the player is every Planner.AGAIN
--                    seconds, the plan from where it lands to the pin after it; without a pin, the flight's
--                    way alone
--
--  The flight points this character knows are read at the flight master (the game's flight map
--  tells them, TAXIMAP_OPENED) and kept for the character: the world map's own list calls every
--  point known on this client. The hearthstone's place is learnt where the character binds it
--  (HEARTHSTONE_BOUND) and where it brings the character, and kept for the character with the
--  game's name of it (GetBindLocation), which tells when it was bound elsewhere since.
--
--  A boat or zeppelin: its timetable is Core's (Data.Ships): the game's way and stays, its sailing at the
--  game's transports' speed, its round where the set or a ride knows it. The wait for one is the time to its
--  next departure where a ride on this realm taught its times, else half its round.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live, Walk, Search, Lifts = ns.Coords, ns.Live, ns.Walk, ns.Search, ns.Lifts
local Planner = {}
ns.Planner = Planner

Planner.RUN = 7          -- yards a second on foot, the game's run speed
Planner.FLY = 30         -- yards a second on a flight, about the game's flights
Planner.BOARD = 8        -- seconds a flight takes besides its way: taking off, landing
Planner.HEARTH = 15      -- seconds the hearthstone takes besides its cooldown: the cast, the loading screen
Planner.STATION = 30     -- seconds the tram takes besides the wait and its run, a guess: the walks between the
                         -- cities' entrances and its platforms, the loading screens into its map and out
Planner.DETOUR = 1.3     -- a walk not searched yet is guessed at so many times the straight line
Planner.WORSE = 1.6      -- a walk found this much longer than its guess makes the journey be chosen again
Planner.APART = 60       -- seconds more a walk between two places that share no region of the walking data costs
                         -- (and no lift joins: then there is no walk)
Planner.REGION = 20      -- yards around a place whose floors' regions are its own too (a tower's foot, a shore)
Planner.OFF = 40         -- yards off the line that make a new plan
Planner.ABOARD = 150     -- yards off a boat's or zeppelin's way the player may be and still be aboard
Planner.DOCK = 30        -- yards from the dock it was boarded at, beyond which the player is aboard
Planner.PIER = 60        -- yards from where a boat stops to the floor one boards it from, at most
Planner.AGAIN = 3        -- seconds at least between two plans
Planner.LOOK = 1         -- seconds between two looks whether the player left the line
Planner.FOOT = 0.25      -- seconds between two looks at the floor the player stands on
Planner.AHEAD = 60       -- parts of the line ahead of where the player was, looked at for where they are now
Planner.SLACK = 5        -- yards a part further on must be nearer than the first ones to be where the player is
Planner.HEARTHSTONE, Planner.HOMEWARD = 6948, 8690 -- the hearthstone: its item, its spell

local SHIPS = { "boat", "zeppelin" }
local Travel = Core.Data.Set("Travel")
local Ships = Core.Data.Ships()
local Trips = Core.Data.Trips()
local target            -- { map, u, v }: the pin in its plane
local plan              -- the journey drawn: { legs, at (the leg the player is on), cut, target }
local job               -- the plan being made: a job of Core's scheduler
local made = 0          -- jobs made, each by a name of its own
local docks             -- every dock, by name, while Core's set Travel stays as it is (Docks)
local planes = {}       -- [the world's map] = the map of its plane (Coords.Planes), or false
local regions = {}      -- [place name] = where a flight point, a dock or a lift's end stands: { set (the regions of
                        -- the walking data, or false: none), below (the lifts' upper levels it stands below, or
                        -- false) }; kept while the walking data and Travel stay as they are (Journey)
local footing           -- the floor the player stands on: { key, index, map = its plane } (Walk.Follow), nil while
                        -- not known
local lastPlan, nextLook, nextFoot = -math.huge, 0, 0
local onTaxi = false
local homeward          -- when the hearthstone was used: its place is where the character is next
local told = {}

local function Distance(au, av, bu, bv)
    return math.sqrt((au - bu) ^ 2 + (av - bv) ^ 2)
end

-------------------------------------------------------------------------------
--  Flight points
-------------------------------------------------------------------------------
-- The flight points this character knows, kept for it ({ [node ID] = true }; anything else saved there: none).
local function Known()
    local char = Core.Character(ns.name)
    if type(char.flights) ~= "table" then char.flights = {} end
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

-- The flight points of a plane the player's side may use: { [node ID] = { map, u, v, name } }, in that plane.
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

-- The flights from a flight point this character may take: { { to, seconds, flight } }, each at its way's length
-- (taking off and landing are the journey's, once for all the flights one after the other).
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
            list[#list + 1] = { to = to, seconds = length / Planner.FLY, flight = flight }
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  Boats and zeppelins
-------------------------------------------------------------------------------
-- The map whose plane is the yards of one of the world's maps (0 the Eastern Kingdoms, 1 Kalimdor, 2991 Zephras
-- Isle), or nil: a map none of the planes on the game's world map has (Coords.Planes).
local function Plane(world)
    local found = planes[world]
    if found ~= nil then return found or nil end
    local list = Coords.Planes()
    for _, map in ipairs(list) do
        if Coords.Box(map).continent == world then found = map break end
    end
    if #list > 0 then planes[world] = found or false end
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

-- A boat's or zeppelin's docks and the ways between them, from its timetable (Core's, Data.Ships: the game's way and
-- stays, its sailing, its round where known): a list of docks { world, x, y, ways = { [other dock] = { seconds, trip,
-- stop, from, till } } }, one for each place it stops at; from and till the indexes of its way's points where one
-- boards and leaves it, stop that stop's number in the timetable; trip the seconds from leaving there to arriving;
-- seconds the trip and the wait for it while its times on this realm are not known (half its round). key: its
-- record's in the set (its timetable kept, and its learnt round); without, a record of its own.
function Planner.Ship(way, key)
    local timetable = key and Ships:Table(key) or Ships.Timetable(way)
    if not timetable then return {} end
    local list, of = {}, {}
    for number, stop in ipairs(timetable.stops) do
        local dock = list[stop.dock]
        if not dock then
            dock = { world = stop.world, x = stop.x, y = stop.y, ways = {} }
            list[stop.dock] = dock
        end
        of[number] = dock
    end
    local round = timetable.round
    for i, a in ipairs(timetable.stops) do
        for j, b in ipairs(timetable.stops) do
            local from, to = of[i], of[j]
            if from ~= to then
                local trip = (b.arrive - a.leave) % round
                local seconds = round / 2 + trip
                -- A dock stopped at twice: left from the stop that sails soonest.
                if not from.ways[to] or seconds < from.ways[to].seconds then
                    from.ways[to] = { seconds = seconds, trip = trip, stop = i, from = a.index, till = b.index }
                end
            end
        end
    end
    return list
end

-- The tram's two docks (Docks): the cities' entrances to its stations (the set's docks, points of the city maps), each
-- in its plane and boarded right there (pu, pv), with a way to the other: the walks down and up and the loading
-- screens (Planner.STATION), the wait for a train (half the seconds between two from a station, the set's wait) and
-- its run (time). None while the set lacks one of them or the entrances lie on two planes (the tunnel's own map has
-- none: the way is drawn straight from entrance to entrance).
local function Tram(found, key, way)
    local list = type(way.docks) == "table" and way.docks or {}
    if #list ~= 2 or not way.time or not way.wait then return end
    local ends = {}
    for index, dock in ipairs(list) do
        local map = Coords.PlaneOf(dock.map)
        local u, v
        if map and dock.x and dock.y then u, v = Coords.MapToPlane(dock.map, dock.x / 100, dock.y / 100, map) end
        if not u then return end
        local name = "dock:" .. key .. ":" .. index
        ends[index] = { name = name, map = map, u = u, v = v, pu = u, pv = v, kind = "tram", ways = {} }
    end
    local a, b = ends[1], ends[2]
    if a.map ~= b.map then return end
    local seconds = Planner.STATION + way.wait / 2 + way.time
    a.ways[1] = { to = b.name, seconds = seconds, kind = "tram", way = way, key = key }
    b.ways[1] = { to = a.name, seconds = seconds, kind = "tram", way = way, key = key }
    found[a.name], found[b.name] = a, b
end

-- Every dock of the boats and zeppelins on a plane of the world map, and the tram's entrances, by name
-- ("dock:<way>:<n>"): { name, map, u, v (where it stops, in that plane), kind, ways = { { to = name, seconds, from,
-- till, kind, way } } }. Made once Core's set Travel is there, again when it changes.
local function Docks()
    if docks then return docks end
    local found = {}
    for _, kind in ipairs(SHIPS) do
        for _, key in ipairs(Travel:Keys("byKind", kind)) do
            local way = Travel:Get(key)
            local list = way and Planner.Ship(way, key) or {}
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
                        ways[#ways + 1] = { to = names[other], seconds = trip.seconds, trip = trip.trip, stop = trip.stop,
                                            from = trip.from, till = trip.till, kind = kind, way = way, key = key }
                    end
                end
            end
        end
    end
    for _, key in ipairs(Travel:Keys("byKind", "tram")) do
        local way = Travel:Get(key)
        if way then Tram(found, key, way) end
    end
    if Travel:Ready() and #Coords.Planes() > 0 then docks = found end
    return found
end

-- Where one stands to board at a dock: the nearest floor of land within Planner.PIER yards of where the boat stops
-- (the pier; a zeppelin's tower, over which it stops), else that place; worked out once the walking data is there.
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
-- when it cannot: none in the bags, its place not known (or saved in another shape), or bound elsewhere since.
local function Hearth()
    local place = Core.Character(ns.name).hearth
    if type(place) ~= "table" or type(place.map) ~= "number" or type(place.u) ~= "number" or type(place.v) ~= "number"
        or not Coords.Box(place.map) then return nil end
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
--  The floor the player stands on
-------------------------------------------------------------------------------
-- The floor under the player now, as { key, index } for the search (nil while the walking data has none there):
-- followed from the one before (Walk.Follow); where it cannot be followed, the floor near them at about the height
-- they had (Walk.Floor), else the one before while they are within Walk.STRIDE yards of it (a gap in the walking
-- data, a rock or a cart it does not hold); else chosen anew (Walk.Floor: outdoors the highest, indoors the lowest).
local function Footing(map, u, v)
    if not Walk.Ready() then return nil end
    local tile, index
    if footing and footing.map == map then
        local key, followed = Walk.Follow(map, u, v, footing[1], footing[2], footing.u, footing.v)
        if key then
            footing[1], footing[2], footing.u, footing.v = key, followed, u, v
            footing.z = select(5, Walk.Rect(Walk.Tile(key), followed))
            return footing
        end
        tile, index = Walk.Floor(map, u, v, false, Search.REACH, footing.z)
        local before = not tile and Walk.Tile(footing[1])
        if before and footing[2] <= before.count and Walk.Gap(before, footing[2], u, v) <= Walk.STRIDE then return footing end
    end
    if not tile then tile, index = Walk.Floor(map, u, v, Core.Ask(IsIndoors) == true, Search.REACH) end
    footing = tile and { tile.key, index, map = map, u = u, v = v, z = select(5, Walk.Rect(tile, index)) } or nil
    return footing
end

-- A lift of the line ridden: the game tells no height, and no floor is followed through a lift's shaft. The player was
-- at a lift that joins the two levels of the line's lift (Lifts.Near: the one planned, or another beside it) as long as
-- its ride takes, then went on along the line past it: on that lift's landing at the other level now (else, at it no
-- longer, the time there counts anew).
local function Rode(map, u, v, now)
    for index, leg in ipairs(plan and plan.legs or {}) do
        local near, far = leg.near, leg.far
        if leg.kind == "lift" and near and far and not leg.rode then
            local lift = Lifts.Near(map, u, v, near.lift[1].region, near.lift[2].region)
            if lift then
                leg.at, leg.since = lift, leg.since or now
            elseif leg.since then
                local at = leg.at
                if plan.cut.leg > index and now - leg.since >= at.time then
                    leg.rode = true
                    local landing = at[far == far.lift[1] and 1 or 2]
                    local tile = Walk.Tile(landing.floor[1])
                    if tile and landing.floor[2] <= tile.count then
                        footing = { landing.floor[1], landing.floor[2], map = map, u = landing.pu, v = landing.pv,
                                    z = select(5, Walk.Rect(tile, landing.floor[2])) }
                    end
                end
                leg.since = nil
            end
        end
    end
end

-------------------------------------------------------------------------------
--  The journey
-------------------------------------------------------------------------------
-- Whether two sets of regions share one.
local function Share(a, b)
    for region in pairs(a) do
        if b[region] then return true end
    end
    return false
end

-- Whether a lift's upper level lies over one place (below: the upper levels it stands below, Lifts.Stand) and the
-- other stands on that level (other: its regions; otherBelow: the upper levels it stands below), so the lift is the
-- way between them, also where they share a region (the Undercity, joined to the ruins over it far off by its
-- sewers). Two places below one level are a walk apart.
local function Over(below, other, otherBelow)
    return below ~= nil and Share(below, other) and not (otherBelow and Share(otherBelow, below))
end

-- The quickest journey by the guesses from the start (start: { map, u, v, from: the player's floor }) to the goal (a
-- place: { map, u, v }): a list of steps { kind = "walk" | "flight" | "boat" | "zeppelin" | "tram" | "lift" | "hearth",
-- from, to (the places' names), map, u1, v1, map2, u2, v2, ... (a walk's floor: the one it starts on, where known; a
-- lift's near and far: its ends) } and its seconds; nil when none reaches it. measured:
-- { [from] = { [to] = seconds } } walks searched already, in place of their guesses. A flight point is two places: on
-- the ground (its node's ID) and in the air over it (minus that), so a flight over many flight points takes off and
-- lands once; the flights one after the other are one step (hops: each flight's record and ends, in order).
local function Journey(start, goal, measured)
    local known = Known()
    local now = Ships.Now()
    local useData = Walk.Ready()
    -- The places: the two ends, and on every plane the known flight points, the docks, the lifts' ends, the
    -- hearthstone's. A place's floor and height where they are known: the player's, a lift's end's.
    local places = {
        start = { map = start.map, u = start.u, v = start.v, floor = start.from, z = start.from and start.from.z },
        ["end"] = { map = goal.map, u = goal.u, v = goal.v, at = goal.at },
    }
    local points = {}
    for _, plane in ipairs(Coords.Planes()) do
        for node, point in pairs(Points(plane)) do
            points[node] = point
            if known[node] then places[node] = point end
        end
    end
    for name, dock in pairs(Docks()) do
        local u, v = Pier(dock)
        places[name] = { map = dock.map, u = u, v = v, dock = dock }
    end
    -- Each end of a lift at its landing (with walking data, only a lift both of whose ends lie on one).
    for _, lift in ipairs(Lifts.All()) do
        if not useData or (Lifts.Landed(lift[1]) and Lifts.Landed(lift[2])) then
            for _, point in ipairs(lift) do
                places[point.name] = { map = point.map, u = point.pu or point.u, v = point.pv or point.v, z = point.z,
                                       floor = point.floor, lift = point }
            end
        end
    end
    local hearth, homeSeconds = Hearth()
    if hearth then places.hearth = { map = hearth.map, u = hearth.u, v = hearth.v } end
    -- A walk's seconds: as found, else guessed (between two places of known heights, the climb too, as the search
    -- counts it: a lift's two ends are no walk apart); and whether it was found.
    local function Walking(fromName, a, toName, b)
        local found = measured[fromName]
        found = found and found[toName]
        if found then return found, true end
        local climb = a.z and b.z and math.abs(a.z - b.z) * Search.CLIMB or 0
        return (Distance(a.u, a.v, b.u, b.v) + climb) * Planner.DETOUR / Planner.RUN, false
    end
    -- The regions of the walking data a place stands in (nil: not known; walks are then not ruled out), and the
    -- lifts' upper levels it stands below (Lifts.Stand): a flight point's, a dock's and a lift's end's kept from plan
    -- to plan (regions), the ends' and the hearthstone's (they move) for this one. A place's floor known (the
    -- player's, a lift's landing): its region; the pin's those of the floors under it, where there are any (on a
    -- mesa, not the land at its foot); any other's those of the floors under it and within Planner.REGION yards.
    local moving = {}
    local function RegionsOf(name)
        if not useData then return nil end
        local kept = (name == "start" or name == "end" or name == "hearth") and moving or regions
        local found = kept[name]
        if found == nil then
            local place = places[name]
            local floor = place.floor
            local tile = floor and Walk.Tile(floor[1])
            local set
            if tile and floor[2] <= tile.count then
                set = { [tile.region[floor[2]]] = true }
            else
                floor = nil
                set = name == "end" and Walk.Regions(place.map, place.u, place.v, 0)
                    or Walk.Regions(place.map, place.u, place.v, Planner.REGION)
            end
            local below
            set, below = Lifts.Stand(place.map, place.u, place.v, set, floor, Planner.REGION, place.at)
            found = { set = set or false, below = below or false }
            kept[name] = found
            Core.Steps.Check() -- its tiles unpacked: the frame's time may be spent
        end
        return found.set or nil, found.below or nil
    end
    -- Dijkstra over the places; a flight point in the air is its node's ID, negative.
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
        Core.Steps.Check()
        local here = places[current]
        if not here then
            -- In the air over a flight point: on to the next ones, or down.
            for _, flight in ipairs(Flights(-current, points, known)) do Reach(-flight.to, low + flight.seconds, flight.flight) end
            Reach(-current, low, "down")
        else
            -- On foot: to every place of the same plane; between places that share no region, it costs more (unless
            -- the walk was found already: then as found), and between two levels a lift joins, or a level and a place
            -- below it, there is none (the lift is the way). A place's regions are looked up only for a walk that may
            -- still be part of a quicker journey: the first plan unpacks no tiles of places nobody walks to.
            local mine, mineBelow
            for name, place in pairs(places) do
                if not done[name] and place.map == here.map then
                    local seconds, found = Walking(current, here, name, place)
                    local total = low + seconds
                    if (not best[name] or total < best[name]) and (not best["end"] or total < best["end"]) then
                        if not found then
                            if mine == nil then
                                mine, mineBelow = RegionsOf(current)
                                mine = mine or false
                            end
                            local theirs, theirBelow
                            if mine then theirs, theirBelow = RegionsOf(name) end
                            if theirs then
                                local apart = not Share(mine, theirs)
                                if (apart and Lifts.Joined(mine, theirs, here.map)) or Over(mineBelow, theirs, theirBelow)
                                    or Over(theirBelow, mine, mineBelow) then
                                    total = nil
                                elseif apart then
                                    total = total + Planner.APART
                                end
                            end
                        end
                        if total then Reach(name, total, "walk") end
                    end
                end
            end
            -- Up into the air at a known flight point.
            if points[current] and here == points[current] then Reach(-current, low + Planner.BOARD, "up") end
            -- By sea or air: the boats and zeppelins from a dock; the wait for the next one where its times on this
            -- realm are known (a ride taught them, Data.Ships), else half its round. Underground: the tram (Tram),
            -- its next train where a ride taught its times (Data.Trips), once down at its platform.
            if here.dock then
                for _, ship in ipairs(here.dock.ways) do
                    if places[ship.to] then
                        local seconds, at = ship.seconds, now + low
                        local _, leaves
                        if ship.stop then
                            _, leaves = Ships:Next(ship.key, ship.stop, at)
                            if leaves then seconds = leaves - at + ship.trip end
                        elseif ship.kind == "tram" then
                            local down = Planner.STATION / 2
                            _, leaves = Trips:TramNext(ship.key, at + down)
                            if leaves then seconds = Planner.STATION + leaves - at - down + ship.way.time end
                        end
                        Reach(ship.to, low + seconds, ship)
                    end
                end
            end
            -- Up or down: a lift from its end to its other one, the wait for its car (half the time between two
            -- departures from an end) and its ride.
            if here.lift then
                local lift = here.lift.lift
                local other = lift[here.lift == lift[1] and 2 or 1]
                if places[other.name] then Reach(other.name, low + lift.wait / 2 + lift.time, lift) end
            end
            -- Home: the hearthstone from where the player is.
            if current == "start" and places.hearth then Reach("hearth", low + homeSeconds, "hearth") end
        end
    end
    if not best["end"] then return nil end
    -- A place by its name; one in the air, the flight point under it.
    local function Where(name)
        return places[name] or (type(name) == "number" and places[-name])
    end
    local steps = {}
    local at = "end"
    while at ~= "start" do
        local previous, way = from[at], how[at]
        local a, b = Where(previous), Where(at)
        if way == "up" or way == "down" then
            -- Taking off and landing: in the flight's own time.
        elseif type(way) == "table" and way.kind == "flight" then
            local after = steps[1]
            local hop = { flight = way, u1 = a.u, v1 = a.v, u2 = b.u, v2 = b.v }
            if after and after.kind == "flight" and after.from == at then
                -- The flight before the next one: one flight, from here on.
                table.insert(after.hops, 1, hop)
                after.from, after.u1, after.v1 = previous, a.u, a.v
            else
                table.insert(steps, 1, { kind = "flight", hops = { hop }, from = previous, to = at, map = a.map, u1 = a.u,
                    v1 = a.v, map2 = b.map, u2 = b.u, v2 = b.v })
            end
        else
            local step = { from = previous, to = at, map = a.map, u1 = a.u, v1 = a.v, map2 = b.map, u2 = b.u, v2 = b.v }
            if way == "walk" then
                step.kind, step.guess, step.floor = "walk", (Walking(previous, a, at, b)), a.floor
            elseif way == "hearth" then
                step.kind = "hearth"
            elseif way.kind == "tram" then
                step.kind, step.tram = "tram", way
            elseif way.kind == "lift" then
                step.kind, step.near, step.far = "lift", a.lift, b.lift
            else
                step.kind, step.ship = way.kind, way
            end
            table.insert(steps, 1, step)
        end
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

-- Every walk of the journey searched (in the plan's job), one after the other: each from the floor it starts on where
-- that is known (the player's, a lift's landing), else from every floor at the place it starts. A walk much longer
-- than its guess, once: the journey chosen again with the walks found so far in place of their guesses (and kept for
-- it).
local function Find(start, goal)
    local measured, walked = {}, {}
    local again = true
    while true do
        local steps = Journey(start, goal, measured)
        if not steps or not Walk.Ready() then return steps end
        local worse = false
        for _, step in ipairs(steps) do
            if step.kind == "walk" then
                local key = step.from .. ":" .. step.to
                if walked[key] == nil then
                    local points, cost = Search.Walk(step.map, step.u1, step.v1, step.u2, step.v2, step.floor,
                        Core.Steps.Check)
                    walked[key] = points and { points = points, seconds = cost / Planner.RUN } or false
                    if points then
                        measured[step.from] = measured[step.from] or {}
                        measured[step.from][step.to] = cost / Planner.RUN
                    end
                end
                local found = walked[key]
                step.points = found and found.points or nil
                if again and found and found.seconds > step.guess * Planner.WORSE then
                    worse = true
                    break
                end
            end
        end
        if not worse then return steps end
        again = false
    end
end

-- A flight's points in its plane: each hop's way as the game's path has it, else its two ends.
local function FlightPoints(step)
    local points = {}
    for _, hop in ipairs(step.hops) do
        local path = hop.flight.path
        if type(path) == "table" and #path >= 2 then
            for index, point in ipairs(path) do
                -- The world's yards: x to the north, y to the west; the plane: u = -y, v = x.
                if index > 1 or #points == 0 then points[#points + 1] = { map = step.map, u = -point.y, v = point.x } end
            end
        else
            if #points == 0 then points[1] = { map = step.map, u = hop.u1, v = hop.v1 } end
            points[#points + 1] = { map = step.map, u = hop.u2, v = hop.v2 }
        end
    end
    return points
end

-- A boat's or zeppelin's points: from the pier it is boarded at along its way to the pier it is left at, each point
-- in its plane (one on a map no plane has, left out).
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
    if job then job:Stop() end
    job = nil
end

-- A way drawn: its legs, the player at its start (the cut follows them from there, Planner.Track).
local function Show(legs)
    plan = { legs = legs, at = 1, target = target, cut = { leg = 1, index = 1, t = 0 } }
    ns.Route.Show(plan)
end

-- The journey drawn, each walk as it was found (or straight); keep: a leg drawn in front of it (the flight the player
-- is on, or the boat or zeppelin).
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
        elseif step.kind == "hearth" or step.kind == "tram" or step.kind == "lift" then
            -- Straight to the hearthstone's place; the tram's from entrance to entrance (its tunnel's map has no
            -- plane); a lift's from its landing to the one at its other end (near and far: its ends, for Rode).
            legs[#legs + 1] = { kind = step.kind, near = step.near, far = step.far,
                                points = { { map = step.map, u = step.u1, v = step.v1 },
                                           { map = step.map2, u = step.u2, v = step.v2 } } }
        else
            legs[#legs + 1] = { kind = step.kind, ship = true, points = ShipPoints(step) }
        end
    end
    Show(legs)
end

-- The plan made as a job (Find), drawn once found; start: { map, u, v, from (the player's floor), keep (the leg drawn
-- in front of it) }. None found: the leg in front stays drawn, or the line goes (across the sea, told once).
local function Make(start)
    Stop()
    made = made + 1
    local goal, steps = target, nil
    job = Core.Steps.Run({ name = "navigation: route " .. made, label = "navigation: route", done = function(problem)
        job = nil
        if problem or goal ~= target then return end -- failed (noted by the scheduler), or another pin since
        if steps then return Draw(steps, start.keep) end
        if start.map ~= goal.map and Travel:Ready() and not told.sea then
            told.sea = true
            ns.Print(Planner.TEXT.sea)
        end
        if start.keep then return Draw({}, start.keep) end
        plan = nil
        ns.Route.Show(nil)
    end }, function()
        steps = Find(start, goal)
    end)
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

-- The boat's or zeppelin's leg of a plan (the one drawn, or the one before a new pin) the player is aboard: the leg
-- the line is at, or the next, is one; the player is more than Planner.DOCK yards from where it was boarded, within
-- Planner.ABOARD yards of its way, not swimming.
local function Aboard(drawn, map, u, v)
    if not drawn or (rawget(_G, "IsSwimming") and IsSwimming()) then return nil end
    for index = drawn.at, drawn.at + 1 do
        local leg = drawn.legs[index]
        local first = leg and leg.ship and leg.points[1]
        if first and (first.map ~= map or Distance(u, v, first.u, first.v) > Planner.DOCK) then
            local gap = Gap(leg, map, u, v)
            if gap and gap <= Planner.ABOARD then return leg, index end
        end
    end
    return nil
end

-- Aboard a boat or a zeppelin by Core's Data.Trips (one the plan may not have: boarded before the pin was set): its way
-- on from where the player is to the pier of the dock it comes to next, as a leg in the planes; nil while not aboard.
local function Riding()
    local trip = Trips:Now()
    if not trip or (trip.kind ~= "boat" and trip.kind ~= "zeppelin") then return nil end
    local key, stop = Ships:Aboard()
    local timetable = key and Ships:Table(key)
    local entry = timetable and timetable.stops[stop]
    local dock = entry and Docks()["dock:" .. key .. ":" .. entry.dock]
    if not dock then return nil end
    local points = {}
    for _, point in ipairs(trip.points or {}) do
        local map = Plane(point.world)
        if map then points[#points + 1] = { map = map, u = -point.y, v = point.x } end
    end
    local u, v = Pier(dock)
    points[#points + 1] = { map = dock.map, u = u, v = v }
    if #points < 2 then return nil end
    return { kind = trip.kind, ship = true, points = points }
end

-- On a flight (Core's Data.Trips): its way on from where the player is, as a leg in the planes; nil without one.
local function Flying()
    local trip = Trips:Now()
    if not trip or trip.kind ~= "flight" or #trip.points < 2 then return nil end
    local points = {}
    for _, point in ipairs(trip.points) do
        local map = Plane(point.world)
        if map then points[#points + 1] = { map = map, u = -point.y, v = point.x } end
    end
    if #points < 2 then return nil end
    return { kind = "flight", flying = true, points = points }
end

-- Plans the way from the player to the target now; aboard a boat or zeppelin (of the plan drawn, or of the one
-- before: before), from where it lands; on a flight, from where it lands, its way on drawn in front (without a
-- target, that alone).
local function Plan(before)
    lastPlan = GetTime()
    local flying = Flying()
    if flying and target then
        local last = flying.points[#flying.points]
        return Make({ map = last.map, u = last.u, v = last.v, keep = flying })
    elseif flying then
        Stop()
        return Show({ flying })
    end
    if not target then
        Stop()
        plan = nil
        return ns.Route.Show(nil)
    end
    local map, pu, pv = Live.Player()
    if not pu then return end
    local leg = Aboard(before or plan, map, pu, pv) or Riding()
    if leg then
        local last = leg.points[#leg.points]
        return Make({ map = last.map, u = last.u, v = last.v, keep = leg })
    end
    Make({ map = map, u = pu, v = pv, from = Footing(map, pu, pv) })
end

-------------------------------------------------------------------------------
--  Following the pin and the player
-------------------------------------------------------------------------------
Planner.TEXT = {
    sea = "no way to the map pin's continent is known yet: no line.",
}

-- The game's map pin in its plane: { map, u, v, at (the map it was put on) }, or nil.
local function Pinned()
    local map, x, y = Live.Waypoint()
    local plane = map and Coords.PlaneOf(map)
    local u, v
    if plane then u, v = Coords.MapToPlane(map, x, y, plane) end
    return u and { map = plane, u = u, v = v, at = map } or nil
end

-- The pin moved, came or went: planned anew (or the line goes); the line to the pin before goes at once.
function Planner.Update()
    Stop()
    local wanted = ns.Pins.Shows("route") and not ns.off
    target = wanted and Pinned() or nil
    local before = plan
    if plan then
        plan = nil
        ns.Route.Show(nil)
    end
    -- Without a pin, a flight's way is drawn all the same.
    if not wanted or (not target and not Flying()) then
        target, footing = nil, nil
        return
    end
    Plan(before)
end

-- The game says its map pin or its arrow changed: planned anew only when the pin is somewhere else now (the arrow
-- led to a quest: the plan, or the job making it, stay).
local function Waypoint()
    local now = Pinned()
    if target and now and now.map == target.map and now.u == target.u and now.v == target.v and (plan or job) then
        return
    end
    Planner.Update()
end

-- On a flight: its way on drawn anew from where the player is, the rest of the plan kept (planned once from where it
-- lands, when the flight's leg is not the plan's first yet).
local function Fly(now)
    local flying = Flying()
    if not flying then return end
    if plan and plan.legs[1] and plan.legs[1].flying and not job then
        lastPlan = now
        plan.legs[1], plan.at = flying, 1
        plan.cut.leg, plan.cut.index, plan.cut.t = 1, 1, 0
        return ns.Route.Show(plan)
    end
    if not job then Plan() end
end

-- Where along the line the player is (the plan's cut), from where they were: of the next Planner.AHEAD parts of it
-- (on the player's plane), the first within Planner.SLACK yards of the nearest; on the part they were on, never
-- back. The cut: its leg, the part (index: from point index to the next) and the share t along it, the point there
-- (u, v), how far the player is from it (gap; nil while no part ahead lies on their plane) and where they are (map,
-- pu, pv). True when it moved.
local nearLeg, nearIndex, nearT, nearGap = {}, {}, {}, {} -- reused: asked at every step of the canvas' tracker
local function Follow(map, u, v)
    local cut, legs = plan.cut, plan.legs
    local count, found, best = 0, 0, nil
    local leg, index = cut.leg, cut.index
    while legs[leg] and count < Planner.AHEAD do
        local points = legs[leg].points
        while points[index + 1] and count < Planner.AHEAD do
            local a, b = points[index], points[index + 1]
            count = count + 1
            local t, gap
            if a.map == map and b.map == map then
                local du, dv = b.u - a.u, b.v - a.v
                local length = du * du + dv * dv
                t = length > 0 and math.max(0, math.min(1, ((u - a.u) * du + (v - a.v) * dv) / length)) or 0
                if leg == cut.leg and index == cut.index and t < cut.t then t = cut.t end
                gap = Distance(u, v, a.u + du * t, a.v + dv * t)
            elseif a.map == map or b.map == map then
                -- A part from one plane onto another (the hearthstone's, a ship's leap): its end on the player's.
                t = a.map == map and 0 or 1
                local at = t == 0 and a or b
                gap = Distance(u, v, at.u, at.v)
            end
            if t then
                found = found + 1
                nearLeg[found], nearIndex[found], nearT[found], nearGap[found] = leg, index, t, gap
                if not best or gap < best then best = gap end
            end
            index = index + 1
        end
        leg, index = leg + 1, 1
    end
    local moved = cut.map ~= map or cut.pu ~= u or cut.pv ~= v
    cut.map, cut.pu, cut.pv, cut.gap = map, u, v, best
    for n = 1, found do
        if nearGap[n] <= best + Planner.SLACK then
            local points, t = legs[nearLeg[n]].points, nearT[n]
            local a, b = points[nearIndex[n]], points[nearIndex[n] + 1]
            moved = moved or cut.leg ~= nearLeg[n] or cut.index ~= nearIndex[n] or cut.t ~= t
            cut.leg, cut.index, cut.t, cut.gap = nearLeg[n], nearIndex[n], t, nearGap[n]
            cut.u, cut.v = a.u + (b.u - a.u) * t, a.v + (b.v - a.v) * t
            break
        end
    end
    plan.at = cut.leg
    return moved
end

-- A step of the canvas' tracker: the player's place (Route.Track). Every step: where along the line the player is,
-- the line drawn from there; every Planner.FOOT seconds the floor they stand on (a lift of the line ridden, Rode);
-- every Planner.LOOK seconds whether to plan again: off the line (aboard a boat or zeppelin: off its way), after a
-- flight landed.
function Planner.Track(map, u, v, now)
    if plan and u and Follow(map, u, v) then ns.Route.Cut(plan) end
    if now >= nextFoot then
        nextFoot = now + Planner.FOOT
        if u and target and not ns.off then
            Rode(map, u, v, now)
            Footing(map, u, v)
        end
    end
    if now < nextLook then return end
    nextLook = now + Planner.LOOK
    if not u then return end
    local flying = rawget(_G, "UnitOnTaxi") and Core.Plain(UnitOnTaxi("player")) and true or false
    if flying then
        onTaxi = true
        if ns.Pins.Shows("route") and not ns.off and now - lastPlan >= Planner.AGAIN then Fly(now) end
        return
    end
    if onTaxi then
        onTaxi = false
        if not target then
            plan = nil
            return ns.Route.Show(nil)
        end
        if now - lastPlan >= Planner.AGAIN then return Plan() end
    end
    if not target then return end
    if job or now - lastPlan < Planner.AGAIN then return end
    if not plan then return Plan() end
    local leg = plan.legs[plan.cut.leg]
    local gap = plan.cut.gap
    if leg and leg.ship and (gap and gap <= Planner.ABOARD or Riding()) then return end -- aboard: the line stays
    if not gap or gap > Planner.OFF then Plan() end
end

ns.On("TAXIMAP_OPENED", function() ns.Safe("flight points", Learn) end)
ns.On("HEARTHSTONE_BOUND", function() ns.Safe("hearthstone", Home) end)
Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spell)
    if Core.Plain(spell) == Planner.HOMEWARD and not ns.off then
        homeward = GetTime()
        arriving()
    end
end)
-- A loading screen: the floor the player stands on is chosen anew; after the hearthstone (onto another continent),
-- its place once the game tells it.
ns.On("PLAYER_ENTERING_WORLD", function()
    footing = nil
    if homeward then arriving() end
end)
-- The walking data or the flights arrived (a pin set before them got a straight line): planned again, the places'
-- regions looked up anew (and the player's floor, with walking data of another shape).
local function Changed()
    wipe(regions)
    if target then ns.Guarded(Plan) end
end
Core.Data.Set("Walking"):OnStamp(function()
    footing = nil
    Lifts.Forget()
    Changed()
end)
Travel:OnStamp(function()
    docks = nil
    Lifts.Forget()
    Changed()
end)
-- A ride taught a boat's round: its trips made anew.
Ships:OnLearn(ns.Guard(function() docks = nil end))
-- A flight began, ended or was asked to land at its next flight point: its way, and the plan from where it lands
-- (after it: from where the player is). A ship landed: planned from where the player is; boarded, one the plan has
-- not (Riding): planned from where it lands.
local aloft, sailing = false, false
Trips:OnChange(ns.Guard(function()
    local trip = Trips:Now()
    local flying = trip ~= nil and trip.kind == "flight"
    local aboard = trip ~= nil and (trip.kind == "boat" or trip.kind == "zeppelin")
    local flew, sailed = aloft, sailing
    aloft, sailing = flying, aboard
    if not ns.Pins.Shows("route") or ns.off then return end
    if flying or flew or (sailed and not aboard) then
        Stop()
        if target or Flying() then return Plan() end
        plan = nil
        return ns.Route.Show(nil)
    end
    if aboard and not sailed and target and not job then
        local map, u, v = Live.Player()
        if not (u and Aboard(plan, map, u, v)) then Plan() end
    end
end))
ns.Listen("LIVE", function(what)
    if what == "waypoint" then ns.Guarded(Waypoint) end
end)
