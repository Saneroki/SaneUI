local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - DockWatch
--  At a dock of a boat or a zeppelin, or a station of the tram: each that stops
--  there, where it goes, and when it comes and leaves, once a ride taught its
--  times on this realm (Core's Data.Ships, Data.Trips), worked out anew from the
--  clock each time, also after a /reload or a login (Saneroki, 2026-11-09); until
--  then how often it sails (one ridden once whose round is not learnt yet: ride it
--  again). Nothing on a trip. While the setting Ship times at a dock is on. The
--  overlay draws it (TripView.lua); this knows no frames.
--
--      DockWatch.Rows()     the ways waiting here, soonest first: { { kind, icon, name, status, known, arrive,
--                           -- leave, here, last (when it last left here), every (seconds between two departures) } }
--                           -- (server times)
--      DockWatch.Update()   drawn again now (the setting changed)
--      DockWatch.Timer(key, dock)  the words of when the ship of way key next comes to its dock number dock and
--                           -- leaves (the tram: its next train at that station), and whether its times are known;
--                           -- nil for a way of no timetable (a dock pin's tooltip on the map, PinView.lua)
--      DockWatch.Clock(s)   seconds as the game's clock writes them (1:05)
--
--  Within DockWatch.NEAR yards of where one stops (a tram's station:
--  DockWatch.STATION), kept up to DockWatch.FAR (so it does not blink at the edge).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local DockWatch = {}
ns.DockWatch = DockWatch

DockWatch.NEAR = 60      -- yards from where a boat or zeppelin stops within which its times show
DockWatch.FAR = 90       -- yards beyond which they go again
DockWatch.STATION = 200  -- yards along the tram's line from a station within which its times show
DockWatch.ROWS = 4       -- rows at most

DockWatch.TEXT = {
    here = "In port, leaves in %s",
    coming = "Arrives in %s, leaves in %s",
    every = "Sails every %s (ride it once for its times)",
    about = "Sails about every %s (ride it once for its times)",
    again = "Sails about every %s (ride it again for its times)",
    trams = "A train about every %s (ride it once for its times)",
    to = "To %s",
}

local Travel = Core.Data.Set("Travel")
local Ships = Core.Data.Ships()
local Trips = Core.Data.Trips()
local shown = false      -- whether the last look found rows (then kept up to DockWatch.FAR yards)

-- Seconds as the game's clock writes them (1:05).
local function Clock(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    local clock = rawget(_G, "SecondsToClock")
    if clock then
        local ok, text = pcall(clock, seconds)
        if ok and type(text) == "string" then return text end
    end
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end
DockWatch.Clock = Clock

-- A stop's dock in the game's words (its area, and the zone where that is another); nil when not known.
local function DockName(key, stop)
    local record = Travel:Get(key)
    local dock = record and type(record.docks) == "table" and record.docks[stop.dock]
    if not dock then return nil end
    return ns.Pins.Towards({ map = dock.map, area = stop.area })
end

-- Where a stop's boat goes on from it: the name of the next stop at another dock.
local function Onward(key, timetable, number)
    local stops, from = timetable.stops, timetable.stops[number].dock
    for step = 1, #stops - 1 do
        local stop = stops[(number - 1 + step) % #stops + 1]
        if stop.dock ~= from then return DockName(key, stop) end
    end
    return nil
end

local function Icon(timetable)
    return ns.Pins.WAY_ICONS[timetable.kind] or ns.Pins.WAY_ICONS.boat
end

-- A row's words: when it comes and leaves, or how often (now: server time; ridden: a ride of it is kept, its round not
-- learnt yet).
local function Status(row, now, every, known, ridden)
    if not row.leave then
        local words = known and DockWatch.TEXT.every or ridden and DockWatch.TEXT.again or DockWatch.TEXT.about
        return words:format(Clock(every))
    end
    if row.here then return DockWatch.TEXT.here:format(Clock(row.leave - now)) end
    return DockWatch.TEXT.coming:format(Clock(row.arrive - now), Clock(row.leave - now))
end

-- The tram, waiting at one of its stations: its next train, to the other station.
local function Tram(rows, now)
    local key, station = Trips:NearTram(DockWatch.STATION)
    local record = key and Travel:Get(key)
    if not record or not record.wait then return end
    local docks = type(record.docks) == "table" and record.docks or {}
    local areas = type(record.dockAreas) == "table" and record.dockAreas or {}
    local other = station == 1 and 2 or 1
    local dock, area = docks[other], areas[other]
    local name = dock and ns.Pins.Towards({ map = dock.map, area = area and area > 0 and area or nil })
    local arrive, leave, here = Trips:TramNext(key, now)
    local row = { kind = "tram", icon = ns.Pins.WAY_ICONS.tram, name = name and DockWatch.TEXT.to:format(name) or record.name,
                  arrive = arrive, leave = leave, here = here, known = leave ~= nil, every = record.wait,
                  last = leave and leave - record.wait }
    row.status = leave and Status(row, now) or DockWatch.TEXT.trams:format(Clock(record.wait))
    rows[#rows + 1] = row
end

-- Each way that stops near: the stop of it there that it leaves soonest, and when, known first and soonest
-- first; nothing on a trip.
function DockWatch.Rows()
    local rows = {}
    if Trips:Now() or (ns.options and ns.options.dockTimes == false) then
        shown = false
        return rows
    end
    local now = Ships.Now()
    local best = {}
    for _, near in ipairs(Ships:Near(shown and DockWatch.FAR or DockWatch.NEAR)) do
        local timetable = Ships:Table(near.key)
        local arrive, leave, here = Ships:Next(near.key, near.stop)
        local row = best[near.key]
        if timetable and (not row or (leave and (not row.leave or leave < row.leave))) then
            local name = Onward(near.key, timetable, near.stop)
            row = { kind = timetable.kind, icon = Icon(timetable),
                    name = name and DockWatch.TEXT.to:format(name) or ns.Pins.WAY_WORDS[timetable.kind],
                    arrive = arrive, leave = leave, here = here, known = leave ~= nil, every = timetable.round,
                    last = leave and leave - timetable.round }
            row.status = Status(row, now, timetable.round, timetable.known, Ships:Seen(near.key) ~= nil)
            best[near.key] = row
        end
    end
    for _, row in pairs(best) do rows[#rows + 1] = row end
    Tram(rows, now)
    table.sort(rows, function(a, b)
        if a.known ~= b.known then return a.known end
        if a.arrive and b.arrive and a.arrive ~= b.arrive then return a.arrive < b.arrive end
        return a.name < b.name
    end)
    while #rows > DockWatch.ROWS do table.remove(rows) end
    shown = #rows > 0
    return rows
end

function DockWatch.Timer(key, dock)
    local now = Ships.Now()
    local timetable = Ships:Table(key)
    if timetable then
        -- Its stop at that dock it leaves soonest (one that stops there twice).
        local best
        for number, stop in ipairs(timetable.stops) do
            if stop.dock == dock then
                local arrive, leave, here = Ships:Next(key, number)
                if not best or (leave and (not best.leave or leave < best.leave)) then
                    best = { arrive = arrive, leave = leave, here = here }
                end
            end
        end
        if not best then return nil end
        return Status(best, now, timetable.round, timetable.known, Ships:Seen(key) ~= nil), best.leave ~= nil
    end
    local record = Travel:Get(key)
    if not record or record.kind ~= "tram" or not record.wait then return nil end
    local arrive, leave, here = Trips:TramNext(key, now)
    if not leave then return DockWatch.TEXT.trams:format(Clock(record.wait)), false end
    return Status({ arrive = arrive, leave = leave, here = here }, now), true
end

function DockWatch.Update()
    if ns.TripView then ns.TripView.Update() end
end
