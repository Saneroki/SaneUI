local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Trips
--  The trip the player is on now: a flight from a flight master, a boat or a
--  zeppelin (Data.Ships), the tram (Core's set Travel). Where it goes, its stops,
--  how far along it is and how long it still takes.
--
--      local Trips = SaneUI.Core.Data.Trips()
--      Trips:Now()          -- the trip, or nil: { kind ("flight", "boat", "zeppelin", "tram"), key (a ship's or
--                           -- the tram's in Travel), stops = { { name or map and area, at } } (where it began first,
--                           -- where it ends last; at: yards along the way), yards (the way's), at (yards along it
--                           -- now), next (the number of the next stop), left and nextLeft (seconds to the end and
--                           -- to the next stop; nil while not known), landing (a flight asked to land at its next
--                           -- stop), points = { { world, x, y } } (the way on from where the player is), pace
--                           -- (yards a second now) and t (the GetTime() of that look: at + pace * (GetTime() - t)
--                           -- is where it is between two looks) }
--      Trips:CanLand()      -- a flight with a flight point before its end, not yet asked to land
--      Trips:Land()         -- a flight lands at its next flight point (the game's TaxiRequestEarlyLanding), as the
--                           -- game's button does on any flight; only from a click
--      Trips:OnChange(fn)   -- fn() on the frame after a trip began, ended, or a flight's end changed
--      Trips:NearTram(yards)    -- waiting at a station of the tram, within so many yards of it: the tram's key in
--                               -- the set and the station's number (1 or 2, as its path); nil else
--      Trips:TramNext(key, at)  -- at server time at (default: now): when the next train arrives at a station, when
--                               -- it leaves, and whether one stands there now (both stations alike: a train sets
--                               -- out from each together); nil while its times on this realm are not known
--
--  A flight: the game tells its route only at the flight master, when one is
--  taken (TakeTaxiNode): its hops then, each the set's flight between two flight
--  points, kept for the character until it lands, so a /reload in the air finds
--  it again. How far along: the player's place in the world (UnitPosition) on the
--  hops' points; how long: the yards left at the pace measured on this flight
--  (after Trips.MEASURE seconds), before that the median of this character's last
--  Trips.KEEP flights' paces, Trips.PACE before its first. A boat or a zeppelin:
--  as Data.Ships finds it aboard. The tram: a place in its map moving along its
--  stations' line at least Trips.SHARE of its speed (the set's time for a run);
--  Trips.SAMPLES looks of a ride that agree within Trips.AGREE seconds on when it
--  left its station are its times on this realm (kept as the ships' are, in
--  Core's saved data, for good: its wait is the set's); a train leaves each
--  station every wait seconds (the set's), and stands there wait less time.
--  Looked at every Trips.LOOK seconds, every Trips.CLOSE on a trip or in the
--  tram's map.
-------------------------------------------------------------------------------
local Data = Core.Data

local Trips = {}
Trips.PACE = 30          -- yards a second a flight is guessed to fly before this character's first is measured
Trips.MEASURE = 8        -- seconds of a flight measured before its own pace counts
Trips.KEEP = 5           -- flights whose paces are kept per character
Trips.NEAR = 150         -- yards from a flight's way the player may be and be on it (a /reload in the air)
Trips.TUNNEL = 150       -- yards from the tram's line its trains run within
Trips.SHARE = 0.6        -- the share of the tram's speed that is riding it
Trips.TAKEN = 15         -- seconds after a flight is taken within which it starts
Trips.STALE = 3600       -- seconds a kept flight is looked for after a /reload
Trips.LOOK, Trips.CLOSE = 2, 1
Trips.SAMPLES = 3        -- looks on a tram ride that agree on when it left make its times
Trips.AGREE = 2          -- seconds they agree within

local Travel = Data.Set("Travel")
local Ships = Data.Ships()
local trip        -- the trip now (Trips:Now)
local flight      -- the flight under way: { hops, way = { { x, y, at } }, yards, world, stops, start, first, landing }
local taken       -- a flight taken at the flight master, until it starts: { hops, at }
local tram        -- the last look in the tram's map: { key, along, t }, and riding: its trip's direction
local listeners = {}
local sqrt = math.sqrt

local function Character()
    return Core.Character(Core.name)
end

local tell = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("data: trips", fn) end
end)

local function Set(now)
    local before = trip
    trip = now
    if (before == nil) ~= (now == nil) or (before and now and (before.kind ~= now.kind or #before.stops ~= #now.stops)) then
        tell()
    end
end

-- The player's place in the world: x, y and the world's map (its fourth answer, past what Core.Ask gives); nil where
-- the game does not tell it.
local function Place()
    local position = rawget(_G, "UnitPosition")
    if not position then return nil end
    local ok, x, y, _, world = pcall(position, "player")
    if not ok then return nil end
    x, y, world = Core.Plain(x), Core.Plain(y), Core.Plain(world)
    if not x or not y or not world then return nil end
    return x, y, world
end

local function OnTaxi()
    return rawget(_G, "UnitOnTaxi") and Core.Plain(UnitOnTaxi("player")) and true or false
end

-- The nearest point of a way (a list of { x, y, at }) to a place, from about the yards at on: the yards along it there
-- and how far off it the place is.
local function Along(way, x, y, from)
    local best, bestAt
    for index = 1, #way - 1 do
        local a, b = way[index], way[index + 1]
        if b.at >= from then
            local dx, dy = b.x - a.x, b.y - a.y
            local length = dx * dx + dy * dy
            local t = length > 0 and math.max(0, math.min(1, ((x - a.x) * dx + (y - a.y) * dy) / length)) or 0
            local gap = sqrt((x - a.x - dx * t) ^ 2 + (y - a.y - dy * t) ^ 2)
            if not best or gap < best then best, bestAt = gap, a.at + (b.at - a.at) * t end
        end
    end
    return bestAt, best
end

-- The way on from yards at: { { world, x, y } }, its first point where the player is along it.
local function Onward(way, world, at)
    local points = {}
    for index = 1, #way - 1 do
        local a, b = way[index], way[index + 1]
        if b.at > at then
            if #points == 0 then
                local t = b.at > a.at and (at - a.at) / (b.at - a.at) or 0
                t = math.max(0, math.min(1, t))
                points[1] = { world = world, x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t }
            end
            points[#points + 1] = { world = world, x = b.x, y = b.y }
        end
    end
    return points
end

-------------------------------------------------------------------------------
--  Flights
-------------------------------------------------------------------------------
-- The route of the flight to a slot of the game's flight map: { { from, to, fromName, toName } } by the flight
-- points' IDs, one per hop; nil when the game does not tell it.
local function Route(slot)
    local count = Core.Plain(Core.Ask(rawget(_G, "GetNumRoutes"), slot))
    if type(count) ~= "number" or count < 1 then return nil end
    local map = Core.Plain(Core.Ask(rawget(_G, "GetTaxiMapID")))
    local nodes = rawget(_G, "C_TaxiMap") and map and Core.Ask(C_TaxiMap.GetAllTaxiNodes, map)
    local ids = {}
    for _, info in ipairs(type(nodes) == "table" and nodes or {}) do
        if info.slotIndex and info.nodeID then ids[info.slotIndex] = info.nodeID end
    end
    local hops = {}
    for hop = 1, count do
        local a = Core.Plain(Core.Ask(TaxiGetNodeSlot, slot, hop, true))
        local b = Core.Plain(Core.Ask(TaxiGetNodeSlot, slot, hop, false))
        hops[hop] = { from = ids[a], to = ids[b], fromName = Core.Plain(Core.Ask(TaxiNodeName, a)),
                      toName = Core.Plain(Core.Ask(TaxiNodeName, b)) }
    end
    return hops
end

-- The set's flight from one flight point to another.
local function Hop(from, to)
    if not from or not to then return nil end
    for _, key in ipairs(Travel:Keys("byFromNode", from)) do
        local record = Travel:Get(key)
        if record and record.kind == "flight" and record.toNode == to then return record end
    end
    return nil
end

-- A flight from its hops: its way's points with the yards along it, its stops, its length; without a way where
-- the set lacks one of its hops (or is not there).
local function Flight(hops, world)
    local way, stops, at = {}, { { name = hops[1].fromName, at = 0 } }, 0
    local whole = Travel:Ready()
    for _, hop in ipairs(hops) do
        local record = whole and Hop(hop.from, hop.to)
        local path = record and record.path
        if type(path) ~= "table" or #path < 2 then
            whole = false
        else
            for index, point in ipairs(path) do
                local last = way[#way]
                if last then at = at + sqrt((point.x - last.x) ^ 2 + (point.y - last.y) ^ 2) end
                if index > 1 or not last then way[#way + 1] = { x = point.x, y = point.y, at = at } end
            end
        end
        stops[#stops + 1] = { name = hop.toName, at = whole and at or nil }
    end
    if not whole then way = {} end
    return { hops = hops, world = world, way = way, yards = whole and at or nil, stops = stops }
end

-- This character's pace: the median of its last flights', else Trips.PACE. The saved file may hold anything: only
-- a pace that is a number above 0 counts.
local function Pace()
    local list, sorted = Character().flightPaces, {}
    if type(list) == "table" then
        for _, pace in ipairs(list) do
            if type(pace) == "number" and pace > 0 then sorted[#sorted + 1] = pace end
        end
    end
    if #sorted == 0 then return Trips.PACE end
    table.sort(sorted)
    return sorted[math.floor((#sorted + 1) / 2)]
end

local function Learn(pace)
    local char = Character()
    local list = type(char.flightPaces) == "table" and char.flightPaces or {}
    list[#list + 1] = pace
    while #list > Trips.KEEP do table.remove(list, 1) end
    char.flightPaces = list
end

local function Started(hops, now)
    local _, _, world = Place()
    flight = Flight(hops, world)
    flight.start = now
    Character().trip = { hops = hops, world = world, at = Core.Plain(Core.Ask(GetServerTime)) }
end

local function Landed(now)
    local f = flight
    flight = nil
    Character().trip = nil
    -- A whole flight, flown to its end: its pace counts for this character's next.
    if f and f.first and not f.landing and f.yards and f.at and f.at >= f.yards - Trips.NEAR then
        local seconds = (f.last or now) - f.first.t
        if seconds > Trips.MEASURE then Learn((f.at - f.first.at) / seconds) end
    end
end

-- The flight's trip now, from the player's place on its way.
local function Flying(now)
    local f = flight
    local stops = f.stops
    local x, y, world = Place()
    if #f.way >= 2 and x and world == f.world then
        local at, gap = Along(f.way, x, y, (f.at or 0) - 100)
        if at and gap <= Trips.NEAR then
            if at > (f.at or 0) + 0.5 then f.last = now end -- the last look it moved on (not waiting at its end)
            f.at = at
            if not f.first and now - f.start >= 2 then f.first = { at = at, t = now } end
        end
    end
    local pace = Pace()
    if f.first and now - f.first.t >= Trips.MEASURE and f.at > f.first.at then
        pace = (f.at - f.first.at) / (now - f.first.t)
    end
    local at = f.at or 0
    local last = #stops
    if f.landing then last = f.landing end
    local next = last
    for index = 2, last do
        if stops[index].at and stops[index].at > at + 1 then
            next = index
            break
        end
    end
    local shown = {}
    for index = 1, last do shown[index] = stops[index] end
    local yards = shown[last].at
    return { kind = "flight", stops = shown, yards = yards, at = at, next = next, landing = f.landing and true or nil,
             pace = pace, t = now,
             left = yards and math.max(0, (yards - at) / pace) or nil,
             nextLeft = shown[next].at and math.max(0, (shown[next].at - at) / pace) or nil,
             points = #f.way >= 2 and Onward(f.way, f.world, at) or {}, canLand = not f.landing and next < last }
end

function Trips:CanLand()
    return trip ~= nil and trip.canLand == true and OnTaxi()
end

function Trips:Land()
    if not OnTaxi() then return end
    Core.Ask(rawget(_G, "TaxiRequestEarlyLanding"))
end

-------------------------------------------------------------------------------
--  Boats, zeppelins and the tram
-------------------------------------------------------------------------------
local function Sailing()
    local key, stop, left, run, s = Ships:Aboard()
    local timetable = key and Ships:Table(key)
    local leg = timetable and timetable.runs[run]
    if not leg then return nil end
    local record = Travel:Get(key)
    local docks = record and type(record.docks) == "table" and record.docks or {}
    local function Stop(number, at)
        local entry = timetable.stops[number]
        local dock = entry and docks[entry.dock]
        return { map = dock and dock.map, area = entry and entry.area, at = at }
    end
    local points = {}
    for _, piece in ipairs(leg.pieces) do
        if piece.from + piece.length > s then
            if #points == 0 then
                local t = piece.length > 0 and math.max(0, (s - piece.from) / piece.length) or 0
                points[1] = { world = piece.world, x = piece.x1 + (piece.x2 - piece.x1) * t, y = piece.y1 + (piece.y2 - piece.y1) * t }
            end
            points[#points + 1] = { world = piece.world, x = piece.x2, y = piece.y2 }
        end
    end
    return { kind = timetable.kind, key = key, stops = { Stop(run, 0), Stop(stop, leg.yards) }, yards = leg.yards, at = s,
             next = 2, left = left, nextLeft = left, points = points,
             pace = left > 0 and (leg.yards - s) / left or 0, t = GetTime() }
end

-- The tram of a world's map: its key and record in the set (looked up once while the set stays as it is).
local trams -- [world] = key
local function Tram(world)
    if not trams then
        if not Travel:Ready() then return nil end
        trams = {}
        for _, key in ipairs(Travel:Keys("byKind", "tram")) do
            local record = Travel:Get(key)
            local path = record and record.path
            if type(path) == "table" and #path >= 2 and path[1].map and record.time and record.time > 0 then
                trams[path[1].map] = key
            end
        end
    end
    local key = trams[world]
    return key, key and Travel:Get(key)
end
Travel:OnStamp(function() trams = nil end)

-- Where a place lies by the tram's stations' line: yards along it from its first station, yards off it, its length.
local function ByLine(record, x, y)
    local a, b = record.path[1], record.path[2]
    local dx, dy = b.x - a.x, b.y - a.y
    local length = sqrt(dx * dx + dy * dy)
    if length == 0 then return nil end
    return ((x - a.x) * dx + (y - a.y) * dy) / length, math.abs((x - a.x) * dy - (y - a.y) * dx) / length, length
end

-- This realm's learnt times of a tram (key nil: of all, their table). The saved file may hold anything: a part
-- that is no table is made anew, a record without a number for its epoch is none.
local function TramLearnt(key)
    local store = Core.Store(Core.name)
    if type(store.trams) ~= "table" then store.trams = {} end
    local realm = Core.realm or "?"
    if type(store.trams[realm]) ~= "table" then store.trams[realm] = {} end
    local all = store.trams[realm]
    if key == nil then return all end
    local learnt = all[key]
    if type(learnt) ~= "table" or type(learnt.epoch) ~= "number" then return nil end
    if type(learnt.seen) ~= "number" then learnt.seen = nil end
    return learnt
end

-- A look on a tram ride: when it left its station (server time); enough that agree, its times on this realm.
local function Sample(ride, key, left)
    if ride.kept then return end
    local list = ride.samples or {}
    ride.samples = list
    list[#list + 1] = left
    while #list > Trips.SAMPLES do table.remove(list, 1) end -- the last looks of the ride
    if #list < Trips.SAMPLES then return end
    local sorted = {}
    for index, value in ipairs(list) do sorted[index] = value end
    table.sort(sorted)
    local middle = sorted[math.floor(#sorted / 2) + 1]
    for _, value in ipairs(list) do
        if math.abs(value - middle) > Trips.AGREE then return end
    end
    TramLearnt()[key] = { epoch = middle, seen = Ships.Now() }
    ride.kept = true
end

local function Tramming(now)
    local x, y, world = Place()
    local key, record
    if x then key, record = Tram(world) end
    if not key or not record then
        tram = nil
        return nil
    end
    local along, gap, length = ByLine(record, x, y)
    if not along then return nil end
    local before = tram
    tram = { key = key, along = along, t = now, toward = before and before.toward,
             samples = before and before.samples, kept = before and before.kept }
    if gap > Trips.TUNNEL then
        tram.toward, tram.samples, tram.kept = nil, nil, nil
        return nil
    end
    local speed = length / record.time
    local moving = false
    if before and before.key == key and now > before.t then
        local pace = (along - before.along) / (now - before.t)
        if math.abs(pace) >= speed * Trips.SHARE then
            tram.toward, moving = pace > 0 and 2 or 1, true
        elseif math.abs(pace) < 1 and (along <= Trips.NEAR or along >= length - Trips.NEAR) then
            -- standing at a station: off it, or waiting there; the next ride learns anew
            tram.toward, tram.samples, tram.kept = nil, nil, nil
        end
    end
    if not tram.toward then return nil end
    local docks = type(record.docks) == "table" and record.docks or {}
    local areas = type(record.dockAreas) == "table" and record.dockAreas or {}
    local from, to = tram.toward == 2 and 1 or 2, tram.toward
    local at = math.max(0, math.min(length, tram.toward == 2 and along or length - along))
    local function Stop(number, yards)
        local dock = docks[number]
        local area = areas[number]
        return { map = dock and dock.map, area = area and area > 0 and area or nil, at = yards }
    end
    if moving then Sample(tram, key, Ships.Now() - at / speed) end
    local left = (length - at) / speed
    return { kind = "tram", key = key, name = record.name, stops = { Stop(from, 0), Stop(to, length) }, yards = length,
             at = at, next = 2, left = left, nextLeft = left, points = {}, pace = speed, t = now }
end

function Trips:NearTram(yards)
    local x, y, world = Place()
    local key, record
    if x then key, record = Tram(world) end
    if not key or not record then return nil end
    local along, gap, length = ByLine(record, x, y)
    if not along or gap > Trips.TUNNEL then return nil end
    if along <= yards then return key, 1 end
    if along >= length - yards then return key, 2 end
    return nil
end

function Trips:TramNext(key, at)
    local learnt = TramLearnt(key)
    local record = Travel:Get(key)
    if not learnt or not learnt.epoch or not record or not record.wait or not record.time then return nil end
    at = at or Ships.Now()
    local wait = record.wait
    local stay = math.max(0, wait - record.time)
    local leave = learnt.epoch + math.ceil((at - learnt.epoch) / wait) * wait
    return leave - stay, leave, leave - at <= stay
end

-------------------------------------------------------------------------------
--  The looks
-------------------------------------------------------------------------------
-- The flight kept for this character (a /reload in the air), if the saved file holds it whole: when it began,
-- and its hops as Route made them (tables, their names text); else none.
local function Kept()
    local kept = Character().trip
    if type(kept) ~= "table" or type(kept.at) ~= "number" or type(kept.world) ~= "number" or type(kept.hops) ~= "table"
        or not kept.hops[1] then
        return nil
    end
    for _, hop in ipairs(kept.hops) do
        if type(hop) ~= "table" or (hop.fromName ~= nil and type(hop.fromName) ~= "string")
            or (hop.toName ~= nil and type(hop.toName) ~= "string") then return nil end
    end
    return kept
end

local function Look()
    local now = GetTime()
    local flying = OnTaxi()
    if taken and now - taken.at > Trips.TAKEN then taken = nil end
    if flying and not flight then
        if taken then
            Started(taken.hops, now)
            taken = nil
        else
            -- On a flight not seen taken (a /reload in the air): the one kept, while the player is on its way.
            local kept = Kept()
            local server = Core.Plain(Core.Ask(GetServerTime))
            if kept and server and server - kept.at < Trips.STALE then
                flight = Flight(kept.hops, kept.world)
                flight.start = now - Trips.MEASURE
            end
        end
    elseif not flying and flight and now - flight.start > 2 then
        Landed(now)
    end
    if flight then
        Set(Flying(now))
        return true
    end
    local sailing = Sailing()
    if sailing then
        Set(sailing)
        return true
    end
    local riding = Tramming(now)
    Set(riding)
    return riding ~= nil or tram ~= nil or taken ~= nil
end

function Trips:Now()
    return trip
end

function Trips:OnChange(fn)
    listeners[#listeners + 1] = fn
end

-- At the flight master: the route of the flight taken, until it starts.
local hooked = false
local function Hook()
    if hooked then return end
    hooked = true
    if rawget(_G, "TakeTaxiNode") then
        hooksecurefunc("TakeTaxiNode", Core.Guard("data: trips", function(slot)
            local hops = Route(slot)
            if hops then taken = { hops = hops, at = GetTime() } end
        end))
    end
    -- Asked to land at the next flight point (our button or the game's): the flight ends there.
    if rawget(_G, "TaxiRequestEarlyLanding") then
        hooksecurefunc("TaxiRequestEarlyLanding", Core.Guard("data: trips", function()
            if flight and trip and trip.canLand then
                flight.landing = trip.next
                Set(Flying(GetTime()))
                tell()
            end
        end))
    end
end

local wanted, entered, looking = false, false, false -- a module asked for the trips; the world is there; the looks run
local Tick
Tick = Core.Guard("data: trips", function()
    local close = Look()
    C_Timer.After(close and Trips.CLOSE or Trips.LOOK, Tick) -- unguarded: Tick is the guard (Core.Guard)
end)
-- The hooks and the looks begin once a module asked for the trips (Data.Trips: Navigation, as its files are read)
-- and the world is there; before, nothing is watched (nobody would show it).
local function Begin()
    if looking or not (wanted and entered) then return end
    looking = true
    Hook()
    C_Timer.After(Trips.CLOSE, Tick) -- unguarded: Tick is the guard (Core.Guard)
end
Core.On("PLAYER_ENTERING_WORLD", function()
    tram = nil
    entered = true
    Begin()
end)
-- Taking off and landing: looked at at once.
Core.On("PLAYER_CONTROL_LOST", function() if looking then Look() end end)
Core.On("PLAYER_CONTROL_GAINED", function() if looking then Look() end end)

function Data.Trips()
    if not wanted then
        wanted = true
        Begin()
    end
    return Trips
end
