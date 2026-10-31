local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Planner
--  The way to the game's map pin, drawn as the golden line (Route.lua), while the
--  setting Route to the map pin is on. Knows no frames.
--
--      the journey   a graph over the player, the pin, the flight points this character knows, the docks of the
--                    boats and zeppelins, the cities' entrances to the tram, the hearthstone's place and where the
--                    teleports this character has bring one, on every
--                    plane (a continent, or a map of its own on the world map: Zephras Isle, Coords.Planes), so
--                    a journey may cross a third one (the hearthstone home, then a ship over the sea); its ways:
--                    on foot between two places of one plane (guessed at Planner.DETOUR times the straight line;
--                    between places that share no region of the walking data Planner.APART seconds more: a tower,
--                    a gap in the walking data, taken only where nothing else goes; at the character's own speed,
--                    Speeds: on land the fastest it was seen riding where it rides, a yard swum at its speed in
--                    water, so a rider goes round a lake where one on foot swims across), the flights between known
--                    flight points
--                    (the game's, Core's set Travel, as only its side flies them; each at its way's length at
--                    Planner.FLY yards a second, Planner.FASTER times that with the Legacy perk Frequent Flier, taking
--                    off and landing once, Planner.BOARD, however many flight points it passes over), the boats and
--                    zeppelins from dock to dock (Core's set Travel, the game's own ways of them: the wait for one
--                    and the trip, Planner.Ship), the tram from one city's entrance to it to the other's (Core's
--                    set Travel: the way down and up, the wait for a train, its next where a ride taught its
--                    times, and its run, Tram), the lifts from one end to the other (Core's set Travel, each end at
--                    its landing, Lifts.lua: the wait for the car, half the time between two departures, and its
--                    ride), the portals from their trigger to where they bring one (Core's set Travel, Portals:
--                    Planner.PORTAL seconds; with walking data only one with a floor at both ends), the
--                    hearthstone from the player to its place (its cooldown and the cast; or the shaman's Astral
--                    Recall, which brings one there too), the teleports this character has (Core's set Travel,
--                    Teleports: a spell it knows, with its reagent in the bags, or an item it holds that the game
--                    lets it use) from the player to where each brings one (its cooldown and the cast); the quickest
--                    taken (Dijkstra). Between two levels a lift joins (Thunder Bluff's mesa and Mulgore), or a
--                    level and a place below it (the Undercity under the ruins over it, Lifts.Stand; also where
--                    the two share a region), no walk: the lift is the way. No ride brings one back to where the
--                    rides since the last walk began (up a lift and straight down again, so that a walk follows a
--                    walk)
--      the walks     then priced on the walking data by its coarse layer (Search.Price): the first from the floor
--                    the player stands on, the others from the floor they start on where it is known (a lift's
--                    landing, a portal's end, a teleport's landing), else from every floor at the place they start;
--                    one to a lift's end to a floor of its own level (Lifts.Heights); a walk priced Planner.WORSE
--                    times its guess or more is put in at its price, one not found as
--                    none (between places that share no region, every walk between those regions too), and the
--                    journey chosen again, up to Planner.TRIES times while its searches have looked at fewer than
--                    Planner.BUDGET nodes (Find); so a walk many times its straight line is never searched as a
--                    short one. Of the journeys whose walks were all priced, the quickest stays, its walks searched
--                    along their coarse ways and drawn (Search.Walk). The journey and its
--                    walks are one job of Core's scheduler (a few milliseconds a frame, never in a fight); a new
--                    pin stops it, and the line of the pin before goes at once
--      the floor     the player's, followed as they go (Walk.Follow, every Planner.FOOT seconds while there is a
--                    pin): the game tells no height, and floors lie one over the other (a cave under a hill, a
--                    city in a mountain, a building's storeys); where it cannot be followed, the floor near the
--                    height they had; after a leap (a portal, a teleport), the floor where it brings one (Arrival);
--                    else (the first plan, a loading screen) the one Walk.Floor chooses (outdoors the highest,
--                    indoors the lowest), a guess where others lie under the player; a lift of the line ridden
--                    (Rode), the landing at its other end
--      without data  (the set Walking not there, or a plane it has nothing of): each walk a straight line
--      the line      always from the player: at every step of the canvas' tracker where along it the player is
--                    (the cut: of the next Planner.AHEAD parts of it, the first within Planner.SLACK yards of the
--                    nearest), and it is drawn from the player's arrow to that point and on from there (Route.Cut);
--                    what lies behind is gone, the legs after the next are fainter
--      planned again when the pin moves, when the player is Planner.OFF yards off the line (Planner.ABOARD
--                    from a ship's way), after a flight or a ship has landed, and when the data arrives; for the
--                    player's moves never more often than every Planner.AGAIN seconds. Aboard a boat or a
--                    zeppelin the line stays; a new pin then is planned from where it lands, its way on in front
--                    (the ship the plan has, or the one Core's Data.Trips finds the player on, to the pier of its
--                    next dock); in the tram's tunnel (a map of no plane) the line stays as it is
--      on a flight   its way on (Core's Data.Trips), drawn anew from where the player is every Planner.AGAIN
--                    seconds, the plan from where it lands to the pin after it; without a pin, the flight's
--                    way alone
--      a way asked   for a module that leads the player (Saneroki, 2026-10-31: the guide's arrow; Core.Ways, Aim and
--      for           Ahead): a second way of the same making to a place of its own, whatever the map pin says and
--                    with the setting off too, followed as the arrow asks and never drawn. Where the pin leads to
--                    that place, its way is the one: no search made twice. Ahead tells what the arrow needs of it:
--                    the line Planner.LEAD yards on, the yards to the next ride or the end, that ride
--
--  The flight points this character has found are learnt at a flight master (TAXIMAP_OPENED: its
--  flight map's states, and every plane's points as the game's maps mark them then; before a flight
--  master was opened this session the game does not know them) and kept for the character
--  (Planner.Knows): only those are flown, and the map shows the others red. The world map's own list
--  holds every point on this client, found or not. The hearthstone's place is learnt where the character binds it
--  (HEARTHSTONE_BOUND) and where it (or Astral Recall) brings the character, and kept for the character with the
--  game's name of it (GetBindLocation), which tells when it was bound elsewhere since. Where a teleport brings one
--  is Core's: the set's, or where one brought a character, learnt in play (Core's Data/Teleports.lua).
--
--  A boat or zeppelin: its timetable is Core's (Data.Ships): the game's way and stays, its sailing at the
--  game's transports' speed, its round where the set or a ride knows it. The wait for one is the time to its
--  next departure where a ride on this realm taught its times, else half its round.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live, Walk, Gates, Search, Lifts = ns.Coords, ns.Live, ns.Walk, ns.Gates, ns.Search, ns.Lifts
local Planner = {}
ns.Planner = Planner

Planner.RUN = 7          -- yards a second on foot, the game's run speed (where the game does not tell the character's)
Planner.SWIM = 4.2       -- yards a second swimming, where the game does not tell: 60 % of the run speed
Planner.FLY = 30         -- yards a second on a flight, about the game's flights
Planner.FASTER = 1.2     -- times as fast a flight is with the Legacy perk Frequent Flier (the game's 20 % faster)
Planner.BOARD = 8        -- seconds a flight takes besides its way: taking off, landing
Planner.HEARTH = 15      -- seconds a teleport takes besides its cooldown: the cast (the game's 10 for the hearthstone
                         -- and every teleport of the routes), the loading screen
Planner.PORTAL = 3       -- seconds a portal takes: the step into it, the move
Planner.ARRIVE = 20      -- yards from a portal's end its floor may lie (at about its height)
Planner.STATION = 30     -- seconds the tram takes besides the wait and its run, a guess: the walks between the
                         -- cities' entrances and its platforms, the loading screens into its map and out
Planner.DETOUR = 1.3     -- a walk not searched yet is guessed at so many times the straight line
Planner.SLOPE = math.tan(math.rad(50)) -- yards up a yard on foot, at most: the steepest floor (dev/tools/walk-data)
Planner.WORSE = 1.6      -- a walk found this much longer than its guess makes the journey be chosen again
Planner.TRIES = 8        -- times at most the journey is chosen again so (or for a walk not found, Find)
Planner.BUDGET = 400000  -- nodes a plan's searches look at, beyond which it is chosen again no more (Find)
Planner.APART = 60       -- seconds more a walk between two places that share no region of the walking data costs
                         -- (and no lift joins: then there is no walk)
Planner.REGION = 20      -- yards around a place whose floors' regions are its own too (a tower's foot, a shore)
Planner.OFF = 40         -- yards off the line that make a new plan
Planner.ABOARD = 150     -- yards off a boat's or zeppelin's way the player may be while the line stays
Planner.DECK = 40        -- yards off its way the player may be and be aboard (Core's Ships.NEAR)
Planner.DOCK = 30        -- yards along its way from where it was boarded, beyond which the player is aboard
Planner.PIER = 60        -- yards from where a boat stops to the floor one boards it from, at most
Planner.AGAIN = 3        -- seconds at least between two plans
Planner.LOOK = 1         -- seconds between two looks whether the player left the line
Planner.FOOT = 0.25      -- seconds between two looks at the floor the player stands on
Planner.LEAP = 50        -- yards the player may move between two looks and their floor still be followed
Planner.HOP = 20         -- yards a second faster than anyone runs or rides (the swiftest mounts: 14): a step between
                         -- two looks so fast is a hop (a portal's few yards up or down a tower, Arrival)
Planner.AHEAD = 60       -- parts of the line ahead of where the player was, looked at for where they are now
Planner.SLACK = 5        -- yards a part further on must be nearer than the first ones to be where the player is
Planner.SAME = 1         -- yards apart two places are one: the pin on the place asked for leads there
Planner.LEAD = 15        -- yards along the line ahead of the player the way asked for turns to (Ahead)
Planner.THERE = 8        -- yards from a leg's end that count as at it: on with the next leg (Ahead)
Planner.HEARTHSTONE, Planner.HOMEWARD = 6948, 8690 -- the hearthstone: its item, its spell
Planner.RECALL = 556     -- the shaman's Astral Recall: to the hearthstone's place too, a spell with its own cooldown
Planner.FLIER = 1225490  -- the Legacy perk Frequent Flier: its spell (flights 20 % faster, half price)

local SHIPS = { "boat", "zeppelin" }
-- The rides that begin where one stands: nothing to walk to on them, they are to be taken (Ahead). A lift is not one: it
-- comes by itself, and the line goes on from it.
local BOARDED = { flight = true, boat = true, zeppelin = true, tram = true, portal = true, hearth = true, teleport = true }
local Travel = Core.Data.Set("Travel")
local Ships = Core.Data.Ships()
local Trips = Core.Data.Trips()
-- A way followed: target ({ map, u, v, at }: where it leads, in its plane), plan (the journey: { legs, at (the leg the
-- player is on), cut, target }), job (the plan being made: a job of Core's scheduler), lastPlan, nextLook, onTaxi.
local function NewWay()
    return { lastPlan = -math.huge, nextLook = 0, onTaxi = false }
end
local pin, guide = NewWay(), NewWay() -- the way to the map pin, drawn; the way to the place asked for, while the pin's
                                      -- does not lead there
local WAYS = { pin, guide }
local aim = {}          -- the point a module asked the way to: a map of the game's, x, y (Planner.Aim)
local asked             -- that place in its plane ({ map, u, v, at }), while the game can place it
local Settle            -- (below)
local made = 0          -- jobs made, each by a name of its own
local land = Planner.RUN -- yards a second on land in the plan being made (Speeds)
local docks             -- every dock, by name, while Core's set Travel stays as it is (Docks)
local portals           -- every portal, while Core's set Travel stays as it is (Portals)
local landings = {}     -- [a teleport's key] = where it brings one on its floor ({ map, u, v, floor = { key, index, z }
                        -- }), or false: no floor there; kept while the walking data and Travel stay as they are
                        -- (Teleports)
local planes = {}       -- [the world's map] = the map of its plane (Coords.Planes), or false
local regions = {}      -- [place name] = where a flight point, a dock, a lift's or a portal's end or a teleport's
                        -- landing stands: { set (the regions of
                        -- the walking data, or false: none), below (the lifts' upper levels it stands below, or
                        -- false) }; kept while the walking data and Travel stay as they are (Journey)
local footing           -- the floor the player stands on: { key, index, map = its plane } (Walk.Follow), nil while
                        -- not known
local seen = {}         -- where the player was at the last look at their floor: { map, u, v, at } (Footing)
local nextFoot = 0
local homeward          -- when the hearthstone was used: its place is where the character is next
local told = {}

local function Distance(au, av, bu, bv)
    return math.sqrt((au - bu) ^ 2 + (av - bv) ^ 2)
end

-------------------------------------------------------------------------------
--  Flight points
-------------------------------------------------------------------------------
-- The flight points this character has found, kept for it as flightPoints ({ [node ID] = true }; anything else saved
-- there: none).
local function Known()
    local char = Core.Character(ns.name)
    if type(char.flightPoints) ~= "table" then char.flightPoints = {} end
    return char.flightPoints
end

-- Whether this character has found a flight point: the routes fly only from and to those, and the map shows the
-- others red (Pins.lua).
function Planner.Knows(node)
    return node ~= nil and Known()[node] == true
end

local Points -- (below)
local opened = false -- a flight master was opened this session: the game's maps tell which flight points are found

-- At a flight master (and when the game says a flight point's state changed, once one was opened): what the game
-- tells of the flight points then. Every plane's as the game's maps mark them (isUndiscovered): the game knows which
-- ones the character has found only once it opened a flight master this session. Then the flight master's own map
-- (C_TaxiMap.GetAllTaxiNodes): Current and Reachable found, Unreachable not (the game's flight map leaves those out);
-- on its older window by name, among the flight points of the player's continent (NONE: not found). True when what
-- this character has found changed.
local function Learn()
    opened = true
    local known, changed = Known(), false
    local function Mark(node, found)
        found = found or nil
        if known[node] ~= found then known[node], changed = found, true end
    end
    for _, plane in ipairs(Coords.Planes()) do
        for _, info in ipairs(Live.Flights(plane)) do
            local undiscovered = Core.Plain(info.isUndiscovered)
            if info.nodeID and type(undiscovered) == "boolean" then Mark(info.nodeID, not undiscovered) end
        end
    end
    local get = C_TaxiMap and C_TaxiMap.GetAllTaxiNodes
    local map = rawget(_G, "GetTaxiMapID") and Core.Plain(Core.Ask(GetTaxiMapID))
    local listed = get and map and Core.Ask(get, map)
    local states = rawget(_G, "Enum") and Enum.FlightPathState or {}
    if type(listed) == "table" and #listed > 0 then
        for _, info in ipairs(listed) do
            if info.nodeID then Mark(info.nodeID, Core.Plain(info.state) ~= (states.Unreachable or 2)) end
        end
        return changed
    end
    local count = rawget(_G, "NumTaxiNodes") and Core.Plain(Core.Ask(NumTaxiNodes)) or 0
    local continent = Live.Player()
    if count == 0 or not continent then return changed end
    local byName = {}
    for node, point in pairs(Points(continent)) do byName[point.name] = node end
    for index = 1, count do
        local kind = Core.Ask(TaxiNodeGetType, index)
        local node = kind and byName[Core.Ask(TaxiNodeName, index)]
        if node then Mark(node, kind ~= "NONE") end
    end
    return changed
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

-- How fast this character goes, in yards a second, on land and swimming: as the game tells it now (GetUnitSpeed, with
-- what speeds it up: a mount, a form, an aspect), on land at least the fastest it was seen riding (it rides again where
-- it rode, Ridden); where the game tells nothing, Planner.RUN and Planner.SWIM.
local function Speeds()
    local ok, _, run, _, swim = pcall(rawget(_G, "GetUnitSpeed"), "player")
    run, swim = ok and Core.Plain(run), ok and Core.Plain(swim)
    run = type(run) == "number" and run > 0 and run or Planner.RUN
    swim = type(swim) == "number" and swim > 0 and swim or Planner.SWIM
    return math.max(run, tonumber(Core.Character(ns.name).ride) or 0), swim
end

-- The character on a mount (not a flight's): how fast it rides, kept where faster than seen before (Speeds).
local function Ridden()
    if not Core.Ask(rawget(_G, "IsMounted")) or Core.Ask(rawget(_G, "UnitOnTaxi"), "player") then return end
    local ok, _, run = pcall(rawget(_G, "GetUnitSpeed"), "player")
    run = ok and Core.Plain(run)
    local char = Core.Character(ns.name)
    if type(run) == "number" and run < Planner.HOP and run > (tonumber(char.ride) or 0) then char.ride = run end
end

-- How many times as fast as Planner.FLY this character's flights are: Planner.FASTER with the Legacy perk Frequent
-- Flier (its spell known, or its aura on the character, as the game tells it), else 1.
function Planner.Pace()
    local book, auras = rawget(_G, "C_SpellBook"), rawget(_G, "C_UnitAuras")
    if book and Core.Ask(book.IsSpellKnown, Planner.FLIER) then return Planner.FASTER end
    if auras and type(Core.Ask(auras.GetPlayerAuraBySpellID, Planner.FLIER)) == "table" then return Planner.FASTER end
    return 1
end

-- The flights from a flight point this character may take: { { to, seconds, flight } }, each at its way's length
-- at Planner.FLY yards a second, pace times that (taking off and landing are the journey's, once for all the flights
-- one after the other).
local function Flights(node, points, known, pace)
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
            list[#list + 1] = { to = to, seconds = length / (Planner.FLY * pace), flight = flight }
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
    if world == nil then return nil end -- (a trip's place the game did not tell)
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
--  Portals
-------------------------------------------------------------------------------
-- Every portal of Core's set Travel (a trigger of the game's that brings one elsewhere on its continent the moment one
-- steps into it: Darnassus and Rut'theran Village; or a portal object one uses: Stormwind's and Dalaran's), on a plane
-- of the world map: { key, kind ("portal"), map, u, v, z (the trigger), tu, tv, tz (where it brings one), side (one
-- side's only, else nil) }. Made once Core's set Travel is there, again when it changes.
local function Portals()
    if portals then return portals end
    local found = {}
    for _, key in ipairs(Travel:Keys("byKind", "portal")) do
        local way = Travel:Get(key)
        local path = type(way) == "table" and way.path
        local a, b = type(path) == "table" and path[1], type(path) == "table" and path[2]
        local map = a and a.map and Plane(a.map)
        if map and b and a.x and a.y and b.x and b.y then
            found[#found + 1] = { key = key, kind = "portal", map = map, u = -a.y, v = a.x, z = a.z, tu = -b.y,
                                  tv = b.x, tz = b.z, side = way.side }
        end
    end
    if Travel:Ready() and #Coords.Planes() > 0 then portals = found end
    return found
end

-- A portal's floors, worked out once the walking data is there: at its trigger and where it brings one, each the floor
-- within Planner.ARRIVE yards nearest its point at its height (Walk.Landing); false where one has none (the walking
-- data holds no floor of that room: then the portal is no way of the journey).
local function Ends(portal)
    if portal.ends == nil and Walk.Ready() then
        local a, ai = Walk.Landing(portal.map, portal.u, portal.v, portal.z or 0, Planner.ARRIVE)
        local b, bi = Walk.Landing(portal.map, portal.tu, portal.tv, portal.tz or 0, Planner.ARRIVE)
        portal.ends = a and b and { { a.key, ai, z = select(5, Walk.Rect(a, ai)) }, { b.key, bi, z = select(5, Walk.Rect(b, bi)) } }
            or false
    end
    return portal.ends
end

-------------------------------------------------------------------------------
--  The hearthstone and the teleports
-------------------------------------------------------------------------------
-- The seconds a cooldown has left (start and duration as the game tells them; none: 0).
local function Left(start, duration)
    if type(start) == "number" and type(duration) == "number" and start > 0 then
        return math.max(0, start + duration - GetTime())
    end
    return 0
end

-- The seconds until this character can cast a spell it knows (its cooldown left), nil when it does not know it.
local function Spell(spell)
    local book, spells = rawget(_G, "C_SpellBook"), rawget(_G, "C_Spell")
    if not (book and Core.Ask(book.IsSpellKnown, spell)) then return nil end
    local cooldown = spells and Core.Ask(spells.GetSpellCooldown, spell)
    if type(cooldown) ~= "table" then return 0 end
    return Left(Core.Plain(cooldown.startTime), Core.Plain(cooldown.duration))
end

-- Whether this character has an item in its bags.
local function Held(item)
    local items = rawget(_G, "C_Item")
    local count = items and Core.Ask(items.GetItemCount, item)
    return type(count) == "number" and count > 0
end

-- The seconds until this character can use an item of its bags (its cooldown left), nil when it has none or the game
-- says it cannot use it (its level, its skill, its charges spent).
local function Item(item)
    if not Held(item) or Core.Ask(C_Item.IsUsableItem, item) == false then return nil end
    return Left(Core.Ask(C_Item.GetItemCooldown, item))
end

-- Its place ({ map, u, v }) and the seconds until it brings the character there (the cooldown of the hearthstone or
-- of Astral Recall, the sooner, and the cast); nil when it cannot: neither in the bags nor known, its place not known
-- (or saved in another shape), or bound elsewhere since.
local function Hearth()
    local place = Core.Character(ns.name).hearth
    if type(place) ~= "table" or type(place.map) ~= "number" or type(place.u) ~= "number" or type(place.v) ~= "number"
        or not Coords.Box(place.map) then return nil end
    local bound = rawget(_G, "GetBindLocation") and Core.Ask(GetBindLocation)
    if bound and place.name and bound ~= place.name then return nil end
    local stone, recall = Item(Planner.HEARTHSTONE), Spell(Planner.RECALL)
    local left = stone and recall and math.min(stone, recall) or stone or recall
    if not left then return nil end
    return place, left + Planner.HEARTH
end

-- The seconds until this character can take a teleport of Core's set Travel (its cooldown left); nil when it cannot:
-- its spell not known or its reagent not in the bags; none of its items in the bags that the game lets it use.
local function Usable(way)
    if type(way.items) ~= "table" then
        if not way.spell or (way.reagent and not Held(way.reagent)) then return nil end
        return Spell(way.spell)
    end
    local soonest
    for _, item in pairs(way.items) do
        local left = Item(item)
        if left and (not soonest or left < soonest) then soonest = left end
    end
    return soonest
end

-- The teleports this character has now (Core's set Travel, kind teleport: of its side or of both) that bring one to a
-- known place of a plane (the set's, or where one brought a character, learnt by Core): { { name ("teleport:<key>"),
-- way, seconds (its cooldown left and the cast, Planner.HEARTH), place = { map, u, v, z, floor } } }. Its floor where
-- the place's height is known and the walking data is there: the one within Planner.ARRIVE yards nearest it at that
-- height (Walk.Landing; none there: the walk from it starts from every floor at the place, as the hearthstone's), a
-- guess (the place is not yet the game's own, and a rebuilt city may close that floor in: Teleport: Stormwind's height
-- is the Wizard's Sanctum's cellar's), so the walk from it takes the floors around it too, as from the player's.
local function Teleports(faction)
    local list = {}
    for _, key in ipairs(Travel:Keys("byKind", "teleport")) do
        local way = Travel:Get(key)
        local landing = way and type(way.path) == "table" and way.path[1]
        local map = type(landing) == "table" and landing.map and landing.x and landing.y and Plane(landing.map)
        local left = map and (not way.side or way.side == faction) and Usable(way)
        if left then
            local place = { map = map, u = -landing.y, v = landing.x, z = landing.z }
            if landing.z and Walk.Ready() then
                if landings[key] == nil then
                    local tile, index = Walk.Landing(map, place.u, place.v, landing.z, Planner.ARRIVE)
                    landings[key] = tile and { map = map, u = place.u, v = place.v,
                                               floor = { tile.key, index, z = select(5, Walk.Rect(tile, index)),
                                                         guess = true } }
                        or false
                end
                place.floor = landings[key] and landings[key].floor or nil
                place.z = place.floor and place.floor.z or place.z
            end
            list[#list + 1] = { name = "teleport:" .. key, way = way, seconds = left + Planner.HEARTH, place = place }
        end
    end
    return list
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
-- Where a portal or a teleport brought the player, on its floor there; nil else. After a leap: the nearest of the
-- places they bring one within Planner.ARRIVE yards of the player (a teleport lands one on its very place). After a
-- hop (fu, fv, fz: where the player was and their floor's height): a portal's end within Planner.ARRIVE yards whose
-- trigger lay within as many of where they were, at about that height (Walk.RISE): the Wizard's Sanctum's two go up
-- and down a tower a few yards across, between rooms one over the other.
local function Arrival(map, u, v, fu, fv, fz)
    local best, floor
    for _, portal in ipairs(Portals()) do
        local ends = portal.ends
        if ends and portal.map == map and (not fu or (Distance(fu, fv, portal.u, portal.v) <= Planner.ARRIVE
            and (not fz or not ends[1].z or math.abs(fz - ends[1].z) <= Walk.RISE))) then
            local gap = Distance(u, v, portal.tu, portal.tv)
            if gap <= Planner.ARRIVE and (not best or gap < best) then best, floor = gap, ends[2] end
        end
    end
    if not fu then
        for _, landing in pairs(landings) do
            local gap = landing and landing.map == map and Distance(u, v, landing.u, landing.v)
            if gap and gap <= Planner.ARRIVE and (not best or gap < best) then best, floor = gap, landing.floor end
        end
    end
    return floor and { floor[1], floor[2], map = map, u = u, v = v, z = floor.z, guess = floor.guess } or nil
end

-- The floor under the player now, as { key, index, z, guess } for the search (nil while the walking data has none
-- there): followed from the one before (Walk.Follow); where it cannot be followed, the floor near them at about the
-- height they had (Walk.Floor), else the one before while they are within Walk.STRIDE yards of it (a gap in the walking
-- data, a rock or a cart it does not hold); else chosen anew (Walk.Floor: outdoors the highest, indoors the lowest),
-- so too after a leap of more than Planner.LEAP yards (a summons: the height before tells nothing there; through a
-- portal or by a teleport, the floor where it brings one, Arrival). After a hop (now: the time of this look; a step
-- since the last one faster than Planner.HOP yards a second) through a portal, the floor where it brings one. A
-- floor chosen among others under the player is a guess (a rock's top over a street may be the highest), and so are
-- those followed from it, until the player stands where only one floor lies under them.
local function Footing(map, u, v, now)
    if not Walk.Ready() then return nil end
    local fu, fv = seen.map == map and seen.u, seen.map == map and seen.v
    local hop = fu and now and seen.at and Distance(u, v, fu, fv) > Planner.HOP * math.max(now - seen.at, Planner.FOOT)
    if now then seen.map, seen.u, seen.v, seen.at = map, u, v, now end
    if footing and (footing.map ~= map or Distance(u, v, footing.u, footing.v) > Planner.LEAP) then
        footing = Arrival(map, u, v)
    elseif footing and hop then
        footing = Arrival(map, u, v, fu, fv, footing.z) or footing
    end
    local tile, index
    if footing then
        local key, followed = Walk.Follow(map, u, v, footing[1], footing[2], footing.u, footing.v)
        if key then
            footing[1], footing[2], footing.u, footing.v = key, followed, u, v
            footing.z = select(5, Walk.Rect(Walk.Tile(key), followed))
            if footing.guess and #Walk.Under(map, u, v) == 1 then footing.guess = nil end
            return footing
        end
        tile, index = Walk.Floor(map, u, v, false, Search.REACH, footing.z)
        local before = not tile and Walk.Tile(footing[1])
        if before and footing[2] <= before.count and Walk.Gap(before, footing[2], u, v) <= Walk.STRIDE then return footing end
    end
    local guess = footing and footing.guess or nil
    if not tile then
        tile, index = Walk.Floor(map, u, v, Core.Ask(IsIndoors) == true, Search.REACH)
        guess = #Walk.Under(map, u, v) ~= 1 or nil
    end
    footing = tile and { tile.key, index, map = map, u = u, v = v, z = select(5, Walk.Rect(tile, index)), guess = guess }
        or nil
    return footing
end

-- The floor the player stands on as it is followed ({ key, index, z, guess }); nil while it is not known.
function Planner.Floor()
    return footing
end

-- A lift of the line ridden: the game tells no height, and no floor is followed through a lift's shaft. The player was
-- at a lift that joins the two levels of the line's lift (Lifts.Near: the one planned, or another beside it) as long as
-- its ride takes, then went on along the line past it: on that lift's landing at the other level now (else, at it no
-- longer, the time there counts anew).
local function Rode(plan, map, u, v, now)
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
-- A place reached on foot is a node of the journey of its own: its name behind this (Journey).
local FOOT = "~"

-- The place of a node of the journey, and whether it was reached on foot.
local function Place(node)
    if type(node) == "string" and node:sub(1, 1) == FOOT then
        local name = node:sub(2)
        return tonumber(name) or name, true
    end
    return node, false
end

-- Whether two sets of regions share one.
local function Share(a, b)
    for region in pairs(a) do
        if b[region] then return true end
    end
    return false
end

-- Whether every region of one place is cut off from every region of another (Find).
local function Cut(cut, a, b)
    for from in pairs(a) do
        local off = cut[from]
        if not off then return false end
        for to in pairs(b) do
            if not off[to] then return false end
        end
    end
    return true
end

-- Whether a lift's upper level lies over one place (below: the upper levels it stands below, Lifts.Stand) and the
-- other stands on that level (other: its regions; otherBelow: the upper levels it stands below), so the lift is the
-- way between them, also where they share a region (the Undercity, joined to the ruins over it far off by its
-- sewers). Two places below one level are a walk apart.
local function Over(below, other, otherBelow)
    return below ~= nil and Share(below, other) and not (otherBelow and Share(otherBelow, below))
end

-- The quickest journey by the guesses from the start (start: { map, u, v, from: the player's floor }) to the goal (a
-- place: { map, u, v }): a list of steps { kind = "walk" | "flight" | "boat" | "zeppelin" | "tram" | "lift" | "portal" |
-- "hearth" | "teleport", from, to (the places' names), map, u1, v1, map2, u2, v2, ... (a walk's floor: the one it
-- starts on, where known, level: the heights of the one it ends on, to a lift's end, and apart: the regions of its ends
-- where they share none; a lift's near and far: its ends) } and its seconds; nil when none reaches it. No walk follows
-- another (one walk straight on is a way of its own), and no ride brings one back to where the rides since the last
-- walk began (up a lift and straight down: a walk would go on from where one walked to).
-- measured: { [from] = { [to] = seconds } } walks searched already, in place of their guesses; cut: { [region] = {
-- [region] = true } } regions no walk was found between (Find), none walked between. A flight point is two places: on
-- the ground (its node's ID) and in the air over it (minus that), the air reached by a flight only (taking off is its
-- first's), so a flight over many flight points takes off and lands once, and one comes down at a flight point only
-- after a flight (no walk follows another there); the flights one after the other are one step (hops: each flight's
-- record and ends, in order).
local function Journey(start, goal, measured, cut)
    local known = Known()
    -- A boat, zeppelin or tram of one side (Core's set Travel: its towns'): none for the other side (their guards).
    local faction = Core.Plain(UnitFactionGroup("player"))
    faction = type(faction) == "string" and faction:lower() or nil
    local now = Ships.Now()
    local useData = Walk.Ready()
    -- The places: the two ends, and on every plane the known flight points, the docks, the lifts' ends, the
    -- hearthstone's, where the teleports bring one. A place's floor and height where they are known: the player's, a
    -- lift's end's, a portal's and a teleport's ends'.
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
    -- Each portal's two ends (with walking data, only one both of whose ends lie on a floor): its trigger, and where
    -- it brings one, each on its floor there.
    for _, portal in ipairs(Portals()) do
        local ends = useData and Ends(portal)
        if not useData or ends then
            local name = "portal:" .. portal.key
            places[name .. ":in"] = { map = portal.map, u = portal.u, v = portal.v, z = ends and ends[1].z or portal.z,
                                      floor = ends and ends[1] or nil, portal = portal, out = name .. ":out" }
            places[name .. ":out"] = { map = portal.map, u = portal.tu, v = portal.tv, z = ends and ends[2].z or portal.tz,
                                       floor = ends and ends[2] or nil }
        end
    end
    local hearth, homeSeconds = Hearth()
    if hearth then places.hearth = { map = hearth.map, u = hearth.u, v = hearth.v } end
    -- Where the teleports this character has bring one (on its floor there, where known).
    local teleports = Teleports(faction)
    for _, teleport in ipairs(teleports) do places[teleport.name] = teleport.place end
    local pace = Planner.Pace()
    -- A walk's seconds: as found, else guessed (between two places of known heights the climb too, as the search
    -- counts it, and at least the way the steepest floor needs to climb it: a lift's two ends are no walk apart);
    -- and whether it was found.
    local function Walking(fromName, a, toName, b)
        local found = measured[fromName]
        found = found and found[toName]
        if found then return found, true end
        local rise = a.z and b.z and math.abs(a.z - b.z) or 0
        local way = math.max(Distance(a.u, a.v, b.u, b.v), rise / Planner.SLOPE)
        return (way + rise * Search.CLIMB) * Planner.DETOUR / land, false
    end
    -- The regions of the walking data a place stands in (nil: not known; walks are then not ruled out), and the
    -- lifts' upper levels it stands below (Lifts.Stand): a flight point's, a dock's, a lift's end's, a portal's end's
    -- and a teleport's kept from plan to plan (regions), the ends' and the hearthstone's (they move) for this one. A
    -- place's floor known (the player's, a lift's landing, a portal's end, a teleport's landing): its region (the
    -- player's a guess: those of the floors around them too); the pin's those of the floors under it, where there are
    -- any (on a mesa, not the land at its foot); any other's those of the floors under it and within Planner.REGION
    -- yards.
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
                -- A floor that is a guess (Footing): the regions of every floor at the place as well.
                set = floor.guess and Walk.Regions(place.map, place.u, place.v, Walk.ROOF) or {}
                set[tile.region[floor[2]]] = true
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
    -- Dijkstra over the places; a flight point in the air is its node's ID, negative. A place reached on foot is a node
    -- of its own (its name behind FOOT, Place), from which no walk goes on: a walk on from there would be one walk,
    -- and the walk straight there is a way of its own (each searched as it is, Find); nor after taking off there, as
    -- the air over a flight point is reached by a flight only; nor by riding back to where the rides since the last
    -- walk began (origin), which leaves one where one walked to (a lift up and straight down, a flight back to where
    -- it took off). boarded: [node] = that place, for one reached by a ride. apart: [node] = the regions of the two
    -- places the walk to it runs between, where they share none ({ from's, to's }: a guess a search may not find).
    local best, from, how, done, apart, boarded = { start = 0 }, {}, {}, {}, {}, {}
    local finish = FOOT .. "end"
    local current, low, origin
    local function Reach(name, seconds, way, far)
        if way ~= "walk" and Place(name) == origin then return end
        if not done[name] and (not best[name] or seconds < best[name]) then
            best[name], from[name], how[name], apart[name] = seconds, current, way, far
            boarded[name] = way ~= "walk" and origin or nil
        end
    end
    while true do
        current, low = nil, nil
        for name, seconds in pairs(best) do
            if not done[name] and (not low or seconds < low) then current, low = name, seconds end
        end
        if not current or current == finish then break end
        done[current] = true
        Core.Steps.Check()
        local name0, walked = Place(current)
        origin = boarded[current] or name0
        local here = places[name0]
        if not here then
            -- In the air over a flight point, come there by a flight: on to the next ones, or down.
            for _, flight in ipairs(Flights(-current, points, known, pace)) do
                Reach(-flight.to, low + flight.seconds, flight.flight)
            end
            Reach(-current, low, "down")
        else
            -- On foot (not on from a walk): to every place of the same plane; between places that share no region, it
            -- costs more (unless the walk was found already: then as found), and between two levels a lift joins, or a
            -- level and a place below it, there is none (the lift is the way); nor between regions no walk was found
            -- between. A place's regions are looked up only for a walk that may still be part of a quicker journey:
            -- the first plan unpacks no tiles of places nobody walks to.
            local mine, mineBelow
            for name, place in pairs(walked and {} or places) do
                local node = FOOT .. name
                if not done[node] and place.map == here.map and name ~= name0 and name ~= "start" then
                    local seconds, found = Walking(name0, here, name, place)
                    local total = low + seconds
                    if (not best[node] or total < best[node]) and (not best[finish] or total < best[finish]) then
                        local far
                        if not found then
                            if mine == nil then
                                mine, mineBelow = RegionsOf(name0)
                                mine = mine or false
                            end
                            local theirs, theirBelow
                            if mine then theirs, theirBelow = RegionsOf(name) end
                            if theirs then
                                local apartOf = not Share(mine, theirs)
                                if (apartOf and (Lifts.Joined(mine, theirs, here.map) or Cut(cut, mine, theirs)))
                                    or Over(mineBelow, theirs, theirBelow) or Over(theirBelow, mine, mineBelow) then
                                    total = nil
                                elseif apartOf then
                                    total = total + Planner.APART
                                    far = { mine, theirs }
                                end
                            end
                        end
                        if total then Reach(node, total, "walk", far) end
                    end
                end
            end
            -- Off from a known flight point: its flights, taking off and landing (Planner.BOARD) with the first. Never
            -- up and straight down again: a walk would go on from where one walked to, from any of its floors.
            if points[name0] and here == points[name0] then
                for _, flight in ipairs(Flights(name0, points, known, pace)) do
                    Reach(-flight.to, low + Planner.BOARD + flight.seconds, flight.flight)
                end
            end
            -- By sea or air: the boats and zeppelins from a dock; the wait for the next one where its times on this
            -- realm are known (a ride taught them, Data.Ships), else half its round. Underground: the tram (Tram),
            -- its next train where a ride taught its times (Data.Trips), once down at its platform.
            if here.dock then
                for _, ship in ipairs(here.dock.ways) do
                    if places[ship.to] and (not ship.way.side or ship.way.side == faction) then
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
            -- Through a portal (one of the player's side or of both): from its trigger to where it brings one.
            local portal = here.portal
            if portal and (not portal.side or portal.side == faction) then Reach(here.out, low + Planner.PORTAL, portal) end
            -- Home: the hearthstone from where the player is; and the teleports this character has.
            if current == "start" then
                if places.hearth then Reach("hearth", low + homeSeconds, "hearth") end
                for _, teleport in ipairs(teleports) do Reach(teleport.name, low + teleport.seconds, teleport.way) end
            end
        end
    end
    if not best[finish] then return nil end
    -- A place by its node; one in the air, the flight point under it.
    local function Where(node)
        local name = Place(node)
        return places[name] or (type(name) == "number" and places[-name])
    end
    local steps = {}
    local at = finish
    while at ~= "start" do
        local previous, way = from[at], how[at]
        local a, b = Where(previous), Where(at)
        if way == "down" then
            -- Landing: in the flight's own time (Planner.BOARD, with its first hop).
        elseif type(way) == "table" and way.kind == "flight" then
            local after = steps[1]
            local hop = { flight = way, u1 = a.u, v1 = a.v, u2 = b.u, v2 = b.v }
            if after and after.kind == "flight" and after.from == at then
                -- The flight before the next one: one flight, from here on.
                table.insert(after.hops, 1, hop)
                after.from, after.u1, after.v1 = previous, a.u, a.v
            else
                table.insert(steps, 1, { kind = "flight", hops = { hop }, from = previous, to = at, name = b.name, map = a.map,
                    u1 = a.u, v1 = a.v, map2 = b.map, u2 = b.u, v2 = b.v })
            end
        else
            local step = { from = (Place(previous)), to = (Place(at)), map = a.map, u1 = a.u, v1 = a.v, map2 = b.map,
                           u2 = b.u, v2 = b.v }
            if way == "walk" then
                step.kind, step.guess, step.floor, step.apart = "walk", (Walking(step.from, a, step.to, b)), a.floor,
                    apart[at]
                step.level = b.lift and Lifts.Heights(b.lift) or nil
            elseif way == "hearth" then
                step.kind = "hearth"
            elseif way.kind == "teleport" or way.kind == "tram" then
                step.kind = way.kind
            elseif way.kind == "lift" then
                step.kind, step.near, step.far = "lift", a.lift, b.lift
            elseif way.kind == "portal" then
                step.kind = "portal"
            else
                step.kind, step.ship = way.kind, way
            end
            table.insert(steps, 1, step)
        end
        at = previous
    end
    return steps, best[finish]
end

-- What a walk priced tells the next choice of the journey (Find; found: { seconds, way }; { near = true, way }, one
-- between places that share no region that ends only as near as one walks; false; or "off": no walking data at one
-- of its ends, Search.Price): found, its seconds in place of its guess; not found (or only near), none (too long for
-- the search, or no way), and between places that share no region, no other walk between those regions either
-- (Teldrassil's top and the shore under it).
local function Measured(measured, cut, step, found)
    if found == "off" then return end -- no walking data at one of its ends: nothing to tell
    local seconds = type(found) == "table" and found.seconds or nil
    measured[step.from] = measured[step.from] or {}
    measured[step.from][step.to] = seconds or math.huge
    if not seconds and step.apart then
        for a in pairs(step.apart[1]) do
            cut[a] = cut[a] or {}
            for b in pairs(step.apart[2]) do cut[a][b] = true end
        end
    end
end

-- Every walk of the journey priced by the coarse layer (in the plan's job), one after the other: each from the floor
-- it starts on where that is known (the player's, a lift's landing, a portal's end, a teleport's landing), else from
-- every floor at the place it starts; one to a lift's end to a floor of its level. A walk much dearer than its guess,
-- or one not found (Teldrassil's top and the shore under it: the portal is the way): the journey chosen again with the
-- walks priced so far in place of their guesses, those not found as none (Measured), up to Planner.TRIES times while
-- its searches have looked at fewer than Planner.BUDGET nodes. Of the journeys whose walks were all priced, the
-- quickest as priced stays (one chosen again by its guesses may come out dearer than one before it: a walk found up to
-- Planner.WORSE times its guess, or the tries spent), each walk searched along its coarse way for its line. Where
-- nothing else goes, the walk not found stays: drawn as near as one walks, then straight, where its search came that
-- near (a place nobody walks onto, a plateau no lift reaches), else straight.
local function Find(start, goal)
    local measured, walked, cut, memo = {}, {}, {}, {}
    local tries, spent = Planner.TRIES, Search.looked
    local kept, keptSeconds -- the quickest journey priced whole so far, and its seconds so
    local swim
    land, swim = Speeds()
    local water = math.max(1, land / swim) -- a yard swum costs so many on land
    while true do
        local steps, seconds = Journey(start, goal, measured, cut)
        if not steps or not Walk.Ready() then return steps end
        local again = false
        for _, step in ipairs(steps) do
            if step.kind == "walk" then
                local key = step.from .. ":" .. step.to
                if walked[key] == nil then
                    local cost, rest, way = Search.Price(step.map, step.u1, step.v1, step.u2, step.v2, step.floor,
                        Core.Steps.Check, water, memo, step.level)
                    if not cost then
                        walked[key] = rest == "off" and "off" or false
                    elseif step.apart and rest > Search.NEAR then
                        -- Between places that share no region, a walk that ends only as near as one walks is none
                        -- (another way may reach the place: a lift, a portal); kept to be drawn, should it stay.
                        walked[key] = { near = true, way = way }
                    else
                        walked[key] = { seconds = cost / land, way = way }
                    end
                end
                local found = walked[key]
                Measured(measured, cut, step, found)
                step.walked = found
                local priced = type(found) == "table" and found.seconds or nil
                -- The journey's seconds as priced: the walk's own in place of its guess (and of Planner.APART, a
                -- guess's only); one not found, none.
                if found ~= "off" then
                    local guessed = step.guess + (step.apart and Planner.APART or 0)
                    seconds = priced and seconds + priced - guessed or math.huge
                end
                if tries > 0 and Search.looked - spent < Planner.BUDGET
                    and ((found ~= "off" and not priced) or (priced and priced > step.guess * Planner.WORSE)) then
                    again = true
                    break
                end
            end
        end
        local whole = true
        for _, step in ipairs(steps) do
            if step.kind == "walk" and step.walked == nil then whole = false end
        end
        if whole and (not kept or seconds < keptSeconds) then kept, keptSeconds = steps, seconds end
        if not again then
            -- The journey stays, or a quicker one priced whole before it: its walks' lines, each along its coarse way.
            steps = kept
            for _, step in ipairs(steps) do
                local found = step.kind == "walk" and step.walked
                if type(found) == "table" then
                    if found.points == nil then
                        found.points = Search.Walk(step.map, step.u1, step.v1, step.u2, step.v2, step.floor,
                            Core.Steps.Check, water, found.way) or false
                    end
                    step.points = found.points or nil
                end
            end
            return steps
        end
        tries = tries - 1
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

local function Stop(way)
    if way.job then way.job:Stop() end
    way.job = nil
end

-- Each walk's yards from its start at each of its points, once for all: Ahead asks what is left many times a second.
local function Measure(legs)
    for _, leg in ipairs(legs) do
        if leg.kind == "walk" then
            local along, walked = { 0 }, 0
            for index = 2, #leg.points do
                local a, b = leg.points[index - 1], leg.points[index]
                walked = walked + Distance(a.u, a.v, b.u, b.v)
                along[index] = walked
            end
            leg.along, leg.yards = along, walked
        end
    end
end

-- A way made: its legs, the player at its start (the cut follows them from there, Planner.Track); the pin's drawn.
local function Show(way, legs)
    Measure(legs)
    way.plan = { legs = legs, at = 1, target = way.target, cut = { leg = 1, index = 1, t = 0 } }
    if way == pin then
        ns.Route.Show(way.plan)
        Settle()
    end
end

-- The journey made, each walk as it was found (or straight); keep: a leg in front of it (the flight the player is
-- on, or the boat or zeppelin).
local function Draw(way, steps, keep)
    local legs = { keep }
    for _, step in ipairs(steps) do
        if step.kind == "walk" then
            local points = {}
            local list = step.points or { step.u1, step.v1, step.u2, step.v2 }
            for index = 1, #list, 2 do points[#points + 1] = { map = step.map, u = list[index], v = list[index + 1] } end
            legs[#legs + 1] = { kind = "walk", points = points }
        elseif step.kind == "flight" then
            legs[#legs + 1] = { kind = "flight", to = step.name, points = FlightPoints(step) }
        elseif step.kind == "hearth" or step.kind == "teleport" or step.kind == "tram" or step.kind == "lift"
            or step.kind == "portal" then
            -- Straight to the hearthstone's place, or where a teleport brings one; the tram's from entrance to entrance
            -- (its tunnel's map has no plane); a lift's from its landing to the one at its other end (near and far: its
            -- ends, for Rode); a portal's from its trigger to where it brings one.
            legs[#legs + 1] = { kind = step.kind, near = step.near, far = step.far,
                                points = { { map = step.map, u = step.u1, v = step.v1 },
                                           { map = step.map2, u = step.u2, v = step.v2 } } }
        else
            legs[#legs + 1] = { kind = step.kind, ship = true, points = ShipPoints(step) }
        end
    end
    Show(way, legs)
end

-- The plan made as a job (Find), drawn once found; start: { map, u, v, from (the player's floor), keep (the leg drawn
-- in front of it) }. None found: the leg in front stays, or the way goes (the pin's across the sea, told once).
local function Make(way, start)
    Stop(way)
    made = made + 1
    local goal, steps = way.target, nil
    way.job = Core.Steps.Run({ name = "navigation: route " .. made, label = "navigation: route", done = function(problem)
        way.job = nil
        if problem or goal ~= way.target then return end -- failed (noted by the scheduler), or another place since
        if steps then return Draw(way, steps, start.keep) end
        if way == pin and start.map ~= goal.map and Travel:Ready() and not told.sea then
            told.sea = true
            ns.Print(Planner.TEXT.sea)
        end
        if start.keep then return Draw(way, {}, start.keep) end
        way.plan = nil
        if way == pin then
            ns.Route.Show(nil)
            Settle()
        end
    end }, function()
        steps = Find(start, goal)
    end)
end

-- How far a point of a continent's plane is from a leg of the line, and how far along the leg its nearest point lies
-- (the yards of the leg's parts on that continent before it); nil when no part of it lies on that continent.
local function Along(leg, map, u, v)
    local best, at, walked = nil, nil, 0
    local points = leg.points
    for index = 1, #points do
        local a, b = points[index], points[index + 1]
        if a.map == map then
            local gap, t, length = nil, 0, 0
            if b and b.map == map then
                local du, dv = b.u - a.u, b.v - a.v
                length = du * du + dv * dv
                t = length > 0 and math.max(0, math.min(1, ((u - a.u) * du + (v - a.v) * dv) / length)) or 0
                length = math.sqrt(length)
                gap = Distance(u, v, a.u + du * t, a.v + dv * t)
            else
                gap = Distance(u, v, a.u, a.v)
            end
            if not best or gap < best then best, at = gap, walked + t * length end
            walked = walked + length
        end
    end
    return best, at
end

-- The boat's or zeppelin's leg of a plan (the one drawn, or the one before a new pin) the player is aboard: the leg
-- the line is at, or the next, is one; the player is within Planner.DECK yards of its way where it lies more than
-- Planner.DOCK yards along it from where it was boarded (or on another continent than that), not swimming. Standing
-- in the town at its dock (by the way it comes in or leaves by) is not aboard.
local function Aboard(drawn, map, u, v)
    if not drawn or (rawget(_G, "IsSwimming") and IsSwimming()) then return nil end
    for index = drawn.at, drawn.at + 1 do
        local leg = drawn.legs[index]
        local first = leg and leg.ship and leg.points[1]
        if first then
            local gap, along = Along(leg, map, u, v)
            if gap and gap <= Planner.DECK and (first.map ~= map or along > Planner.DOCK) then return leg, index end
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

-- Plans a way from the player to its target now; aboard a boat or zeppelin (of the plan drawn, or of the one
-- before: before), from where it lands; on a flight, from where it lands, its way on drawn in front (without a
-- target, that alone).
local function Plan(way, before)
    way.lastPlan = GetTime()
    local flying = Flying()
    if flying and way.target then
        local last = flying.points[#flying.points]
        return Make(way, { map = last.map, u = last.u, v = last.v, keep = flying })
    elseif flying then
        Stop(way)
        return Show(way, { flying })
    end
    if not way.target then
        Stop(way)
        way.plan = nil
        if way == pin then ns.Route.Show(nil) end
        return
    end
    local map, pu, pv = Live.Player()
    if not pu then return end
    local leg = Aboard(before or way.plan, map, pu, pv) or Riding()
    if leg then
        local last = leg.points[#leg.points]
        return Make(way, { map = last.map, u = last.u, v = last.v, keep = leg })
    end
    local floor = Footing(map, pu, pv, GetTime())
    Make(way, { map = map, u = pu, v = pv, from = floor and { floor[1], floor[2], z = floor.z, guess = floor.guess } })
end

-- Every way with a target planned anew.
local function Replan()
    for _, way in ipairs(WAYS) do
        if way.target then Plan(way) end
    end
end

-- Whether two places are one.
local function Same(a, b)
    return a ~= nil and b ~= nil and a.map == b.map and Distance(a.u, a.v, b.u, b.v) <= Planner.SAME
end

-- A point of a map (0 to 1) in its plane: { map, u, v, at (the map) }, or nil.
local function InPlane(map, x, y)
    local plane = map and Coords.PlaneOf(map)
    local u, v
    if plane then u, v = Coords.MapToPlane(map, x, y, plane) end
    return u and { map = plane, u = u, v = v, at = map } or nil
end

-- Who finds the way to the place asked for: the pin's way where that leads there (made, or being made: the way found
-- so far stays until it is there), else a way of its own. The place looked at again each time: one asked for before
-- the game could place it comes in here. With no way left, the floor goes, and with the route off the unpacked tiles too.
Settle = function()
    local place = not ns.off and InPlane(aim[1], aim[2], aim[3]) or nil
    if not (place and asked and place.map == asked.map and place.u == asked.u and place.v == asked.v) then asked = place end
    local shared = asked and Same(asked, pin.target) and (pin.plan or pin.job)
    local own = not shared and asked or nil
    if not asked or (shared and pin.plan) then guide.plan = nil end
    if own ~= guide.target then
        Stop(guide)
        guide.target = own
        if own then
            guide.plan = nil
            Plan(guide)
        end
    end
    if not pin.target and not guide.target then
        footing = nil
        if ns.off or not ns.Pins.Shows("route") then
            Walk.Forget()
            Gates.Forget()
        end
    end
end

-------------------------------------------------------------------------------
--  Following the pin and the player
-------------------------------------------------------------------------------
Planner.TEXT = {
    sea = "no way to the map pin's continent is known yet: no line.",
}

-- The game's map pin in its plane, or nil.
local function Pinned()
    return InPlane(Live.Waypoint())
end

-- The pin moved, came or went: planned anew (or the line goes); the line to the pin before goes at once.
function Planner.Update()
    Stop(pin)
    local wanted = ns.Pins.Shows("route") and not ns.off
    pin.target = wanted and Pinned() or nil
    local before = pin.plan
    if pin.plan then
        pin.plan = nil
        ns.Route.Show(nil)
    end
    -- Without a pin, a flight's way is drawn all the same.
    if not wanted or (not pin.target and not Flying()) then
        pin.target = nil
        return Settle()
    end
    Plan(pin, before)
    Settle()
end

-- The game says its map pin or its arrow changed: planned anew only when the pin is somewhere else now (the arrow
-- led to a quest: the plan, or the job making it, stay).
local function Waypoint()
    local now, target = Pinned(), pin.target
    if target and now and now.map == target.map and now.u == target.u and now.v == target.v and (pin.plan or pin.job) then
        return
    end
    Planner.Update()
end

-- On a flight: its way on drawn anew from where the player is, the rest of the plan kept (planned once from where it
-- lands, when the flight's leg is not the plan's first yet).
local function Fly(now)
    local flying = Flying()
    if not flying then return end
    local plan = pin.plan
    if plan and plan.legs[1] and plan.legs[1].flying and not pin.job then
        pin.lastPlan = now
        plan.legs[1], plan.at = flying, 1
        plan.cut.leg, plan.cut.index, plan.cut.t = 1, 1, 0
        return ns.Route.Show(plan)
    end
    if not pin.job then Plan(pin) end
end

-- Where along the line the player is (the plan's cut), from where they were: of the next Planner.AHEAD parts of it
-- (on the player's plane), the first within Planner.SLACK yards of the nearest; on the part they were on, never
-- back. The cut: its leg, the part (index: from point index to the next) and the share t along it, the point there
-- (u, v), how far the player is from it (gap; nil while no part ahead lies on their plane) and where they are (map,
-- pu, pv). True when it moved.
local nearLeg, nearIndex, nearT, nearGap = {}, {}, {}, {} -- reused: asked at every step of the canvas' tracker
local function Follow(plan, map, u, v)
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

-- Where along its line the player is, the pin's drawn from there.
local function Walked(way, map, u, v)
    if way.plan and u and Follow(way.plan, map, u, v) and way == pin then ns.Route.Cut(way.plan) end
end

-- Every Planner.FOOT seconds the floor the player stands on (a lift of a line ridden, Rode; on a trip none).
local function Stand(map, u, v, now)
    if now < nextFoot then return end
    nextFoot = now + Planner.FOOT
    Ridden()
    if u and (pin.target or guide.target) and not ns.off then
        -- On a flight, a boat, a zeppelin or the tram no floor is under the player: chosen anew where they come
        -- down.
        if Trips:Now() or (rawget(_G, "UnitOnTaxi") and Core.Plain(UnitOnTaxi("player"))) then
            footing = nil
        else
            Rode(pin.plan, map, u, v, now)
            Rode(guide.plan, map, u, v, now)
            Footing(map, u, v, now)
        end
    end
end

-- Every Planner.LOOK seconds whether to plan a way again: off the line (aboard a boat or zeppelin: off its way), after
-- a flight landed.
local function Looked(way, map, u, v, now)
    if now < way.nextLook then return end
    way.nextLook = now + Planner.LOOK
    if not u then return end
    local flying = rawget(_G, "UnitOnTaxi") and Core.Plain(UnitOnTaxi("player")) and true or false
    if flying then
        way.onTaxi = true
        if way == pin and ns.Pins.Shows("route") and not ns.off and now - way.lastPlan >= Planner.AGAIN then Fly(now) end
        return
    end
    if way.onTaxi then
        way.onTaxi = false
        if not way.target then
            way.plan = nil
            if way == pin then ns.Route.Show(nil) end
            return
        end
        if now - way.lastPlan >= Planner.AGAIN then return Plan(way) end
    end
    if not way.target then return end
    if way.job or now - way.lastPlan < Planner.AGAIN then return end
    if not way.plan then return Plan(way) end
    local leg = way.plan.legs[way.plan.cut.leg]
    local gap = way.plan.cut.gap
    if leg and leg.ship and (gap and gap <= Planner.ABOARD or Riding()) then return end -- aboard: the line stays
    if not gap or gap > Planner.OFF then Plan(way) end
end

-- A step of the canvas' tracker: the player's place (Route.Track).
function Planner.Track(map, u, v, now)
    Walked(pin, map, u, v)
    Stand(map, u, v, now)
    Looked(pin, map, u, v, now)
end

-------------------------------------------------------------------------------
--  The way asked for (Core.Ways)
-------------------------------------------------------------------------------
-- Lead to a point of a map (0 to 1) from now on; no map: nowhere.
function Planner.Aim(map, x, y)
    aim[1], aim[2], aim[3] = map, x, y
    Settle()
end

-- Whether the player is done with a leg: within Planner.THERE yards of its end; of a ride, nearer that than its start too
-- (a lift's two ends may lie one over the other: the line goes on from it when the player does).
local function Past(leg, map, u, v)
    local first, last = leg.points[1], leg.points[#leg.points]
    if last.map ~= map then return false end
    local gap = Distance(u, v, last.u, last.v)
    if gap > Planner.THERE then return false end
    return leg.kind == "walk" or first.map ~= map or gap < Distance(u, v, first.u, first.v)
end

-- The point of the line Planner.LEAD yards on from where the player is on leg at (past a lift: on the walk after it).
local function Lead(plan, at)
    local cut, legs = plan.cut, plan.legs
    if legs[at].kind == "lift" and legs[at + 1] then at = at + 1 end
    local points = legs[at].points
    local index, au, av = 1, points[1].u, points[1].v
    if at == cut.leg then index, au, av = cut.index, cut.u, cut.v end
    local rest = Planner.LEAD
    for number = index + 1, #points do
        local point = points[number]
        local length = Distance(au, av, point.u, point.v)
        if length >= rest then
            local share = rest / length
            return au + (point.u - au) * share, av + (point.v - av) * share
        end
        rest, au, av = rest - length, point.u, point.v
    end
    return au, av
end

-- The yards from the player to the end of leg at, along its line where it is a walk.
local function Left(plan, at, u, v)
    local cut, leg = plan.cut, plan.legs[at]
    local first, last = leg.points[1], leg.points[#leg.points]
    if not leg.along then return Distance(u, v, last.u, last.v) end
    if at ~= cut.leg then return leg.yards + Distance(u, v, first.u, first.v) end
    local start = leg.points[cut.index]
    return leg.yards - leg.along[cut.index] - Distance(start.u, start.v, cut.u, cut.v) + cut.gap
end

-- Where a ride brings one, in the game's words: a flight's flight point, else the zone its way ends in; asked once.
local function Towards(leg)
    if leg.to == nil then
        local last = leg.points[#leg.points]
        local zone = Coords.ZoneAt(last.map, last.u, last.v)
        local info = zone and Core.Ask(C_Map.GetMapInfo, zone)
        leg.to = type(info) == "table" and Core.Plain(info.name) or false
    end
    return leg.to or nil
end

-- Where to go now on the way asked for (Core.Ways.Ahead has what it tells); nil while no way is known: none found yet,
-- none, or the player on no part of it. Followed here, as the canvas may not be up: it follows only the pin's.
local ahead = {} -- reused: asked many times a second
function Planner.Ahead()
    if ns.off or not asked then return nil end
    local map, u, v = Live.Player()
    if not u then return nil end
    local way = pin.plan and Same(asked, pin.target) and pin or guide
    local now = GetTime()
    Walked(way, map, u, v)
    Stand(map, u, v, now)
    Looked(way, map, u, v, now)
    local plan = way.plan
    if not plan or not plan.cut.gap then return nil end
    local legs, at = plan.legs, plan.cut.leg
    while legs[at + 1] and Past(legs[at], map, u, v) do at = at + 1 end
    local leg = legs[at]
    local ride = leg.kind ~= "walk" and leg or legs[at + 1]
    local lu, lv = Lead(plan, at)
    ahead.way, ahead.yards = math.atan2(u - lu, lv - v), Left(plan, at, u, v)
    ahead.ride, ahead.to = ride and ride.kind or nil, ride and Towards(ride) or nil
    ahead.here = BOARDED[leg.kind]
    return ahead
end

-- At a flight master: what this character has found, learnt; a pin set before, planned again when that changed.
local function Taxi()
    if Learn() then ns.Guarded(Replan) end
end
ns.On("TAXIMAP_OPENED", function() ns.Safe("flight points", Taxi) end)
-- The game says a flight point's state changed (one found): learnt again, once a flight master was opened.
ns.On("TAXI_NODE_STATUS_CHANGED", function()
    if opened then ns.Safe("flight points", Taxi) end
end)
ns.On("HEARTHSTONE_BOUND", function() ns.Safe("hearthstone", Home) end)
Core.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", function(_, _, spell)
    spell = Core.Plain(spell)
    if (spell == Planner.HOMEWARD or spell == Planner.RECALL) and not ns.off then
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
    ns.Guarded(Replan)
end
Core.Data.Set("Walking"):OnStamp(ns.Guard(function()
    footing, portals = nil, nil
    wipe(landings)
    Walk.Forget()
    Gates.Forget()
    Lifts.Forget()
    Changed()
end))
-- (also when Core learnt where a teleport brings one)
Travel:OnStamp(ns.Guard(function()
    docks, portals = nil, nil
    wipe(landings)
    Lifts.Forget()
    Changed()
end))
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
    if ns.off then return end
    for _, way in ipairs(WAYS) do
        if way ~= pin or ns.Pins.Shows("route") then
            if flying or flew or (sailed and not aboard) then
                Stop(way)
                if way.target or (way == pin and Flying()) then
                    Plan(way)
                else
                    way.plan = nil
                    if way == pin then ns.Route.Show(nil) end
                end
            elseif aboard and not sailed and way.target and not way.job then
                local map, u, v = Live.Player()
                if not (u and Aboard(way.plan, map, u, v)) then Plan(way) end
            end
        end
    end
end))
ns.Listen("LIVE", function(what)
    if what == "waypoint" then ns.Guarded(Waypoint) end
end)
Core.Ways.Serve({ Aim = Planner.Aim, Ahead = Planner.Ahead })
