local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Ships
--  The boats and zeppelins of Core's set Travel as timetables, and when they
--  really sail on this realm, learnt in play (Doc/guides/data.md, *The ships'
--  times*). The game tells neither: its tables hold a transport's way and how
--  long it stands at each dock, and nothing about where it is now.
--
--      local Ships = SaneUI.Core.Data.Ships()
--      Ships:Table(key)        -- its timetable: { round, known (the round is the set's or learnt, not
--                              -- estimated), given (the set's own), stops = { { index, world, x, y, stay, arrive,
--                              -- leave, dock, area } } },
--                              -- the seconds into its round it arrives at each stop and leaves it (the first
--                              -- stop leaves at 0; dock: its number among the way's docks, stops within
--                              -- Ships.SAME yards one dock, as the set's docks; area: the game's area it lies in,
--                              -- from the set's dockAreas, which names it); nil for no boat or zeppelin of the set
--      Ships:Next(key, stop, at)   -- at server time at (default: now): the next time it arrives at that stop
--                              -- (its number in stops) and when it leaves, as server times, and whether it
--                              -- stands there now (then arrive is when it came); nil while its times on this
--                              -- realm are not known (no ride seen, or longer ago than Ships.TRUST)
--      Ships:Near(yards)       -- the stops within so many yards of the player now: a list of { key, stop }
--      Ships:Seen(key)         -- when its times were last learnt here (server time) and how many rides did
--      Ships:Aboard()          -- aboard a boat or zeppelin now: its key, the stop it comes to next, the seconds
--                              -- until it arrives there (from where the player is along its way), the run it is
--                              -- on (its number in runs: from stop run to the next) and the yards sailed of it;
--                              -- nil else
--      Ships.Timetable(record) -- a timetable from a record of the set (not kept; Table keeps the set's own)
--      Ships.Run(yards)        -- the seconds a run of so many yards takes from one stop to the next
--      Ships:OnLearn(fn)       -- fn(key) on the frame after a ride taught its times
--      Ships.Now()             -- the server's time, to a part of a second
--
--  The timetable: the way's points and stays are the game's; between two stops it
--  sails at Ships.SPEED yards a second, speeding up and slowing down at Ships.ACCEL
--  (the game's transports' own data); a leap onto another map takes no time. Where
--  the round is known (the set's wait, or learnt), the sailing is stretched to it.
--
--  Learnt in play: every Ships.LOOK seconds (Ships.CLOSE near a stop or aboard)
--  the player's place in the world is compared with every way on that map. A
--  place within Ships.NEAR yards of a way, moving on along it at the boat's speed
--  while it sails at full speed, says when the boat left its last stop, and so the
--  start of its round (its epoch); Ships.SAMPLES of them that agree within
--  Ships.AGREE seconds are a ride, kept for this realm in Core's saved data
--  (Core.Store), on this computer only. Where the set has no round, the rides learn
--  it from the rounds between them, and correct it while they agree with it (Keep,
--  below). Nothing in a taxi's flight, and nothing while the set Travel is not
--  loaded (it is Core's, read with Core at the login).
-------------------------------------------------------------------------------
local Data = Core.Data

local Ships = {}
Ships.SPEED = 30         -- yards a second at full speed
Ships.ACCEL = 1          -- yards a second each second into and out of a stop
Ships.FAR = 500          -- yards: from a way's last point to its first, farther is a leap
Ships.SAME = 20          -- yards between two stops at one dock (the set's docks)
Ships.NEAR = 40          -- yards from its way the player may be and be aboard
Ships.DOCK = 250         -- yards from a stop within which the player's place is looked at often
Ships.LOOK, Ships.CLOSE = 3, 1 -- seconds between two looks: anywhere, near a stop or aboard
Ships.SAMPLES = 5        -- samples at full speed that make a ride
Ships.AGREE = 4          -- seconds they agree within
Ships.PACE = 0.3         -- a share the player's pace along the way may differ from the boat's
Ships.TRUST = 12 * 3600  -- seconds a ride's times are trusted
Ships.ROUNDS = 40        -- at most so many rounds between two rides that give a round not confirmed yet
Ships.KINDS = { boat = true, zeppelin = true }

local Travel = Data.Set("Travel")
local tables = {}        -- [key] = its timetable, or false: made when first asked, again when the set changes
local listeners = {}
local ride               -- the ride being watched: { key, epochs = { ... } }, or kept: { key, kept = true }
local aboard             -- the last look found the player aboard: { key, run, s, at }
local offset             -- GetServerTime() - GetTime(), taken when the server's second turned

local sqrt, floor = math.sqrt, math.floor

-------------------------------------------------------------------------------
--  Time
-------------------------------------------------------------------------------
-- The server's time to a part of a second: its whole seconds, the client's clock for the rest.
local lastSecond
function Ships.Now()
    local server, now = Core.Plain(Core.Ask(GetServerTime)), GetTime()
    if server and server ~= lastSecond then
        if lastSecond then offset = server - now end
        lastSecond = server
    end
    if offset then return now + offset end
    return server or now
end

-------------------------------------------------------------------------------
--  The timetable
-------------------------------------------------------------------------------
-- Seconds a run of so many yards takes from one stop to the next, and how long until s yards of it are sailed.
local function Run(yards)
    local v, a = Ships.SPEED, Ships.ACCEL
    if yards >= v * v / a then return 2 * v / a + (yards - v * v / a) / v end
    return 2 * sqrt(yards / a)
end

local function Into(yards, s)
    local v, a = Ships.SPEED, Ships.ACCEL
    local ramp, total = v * v / (2 * a), Run(yards)
    s = math.max(0, math.min(yards, s))
    if s <= math.min(ramp, yards / 2) then return sqrt(2 * s / a) end
    if s >= yards - math.min(ramp, yards / 2) then return total - sqrt(2 * (yards - s) / a) end
    return v / a + (s - ramp) / v
end

-- Whether s yards into a run the boat sails at full speed (not speeding up, nor slowing down).
local function Cruising(yards, s)
    local ramp = Ships.SPEED * Ships.SPEED / (2 * Ships.ACCEL)
    return s > ramp and s < yards - ramp
end

-- This realm's learnt times of a way (key nil: of all, their table). The saved file may hold anything: a part
-- that is no table is made anew, a record without a number for its epoch is none, a value of the wrong kind goes.
local NUMBERS = { "seen", "rides", "round", "span" }
local function Learnt(key)
    local store = Core.Store(Core.name)
    if type(store.ships) ~= "table" then store.ships = {} end
    local realm = Core.realm or "?"
    if type(store.ships[realm]) ~= "table" then store.ships[realm] = {} end
    local all = store.ships[realm]
    if key == nil then return all end
    local learnt = all[key]
    if type(learnt) ~= "table" or type(learnt.epoch) ~= "number" then return nil end
    for _, field in ipairs(NUMBERS) do
        if type(learnt[field]) ~= "number" then learnt[field] = nil end
    end
    if learnt.doubt ~= true then learnt.doubt = nil end
    return learnt
end

-- A way's timetable from its record: its stops in its way's order from its first stop round, the runs between them
-- (each its yards, and the pieces of its way it sails on each map), the seconds into its round of each arrival and
-- departure.
local function Make(key, way)
    local path = way and Ships.KINDS[way.kind] and way.path
    if type(path) ~= "table" or #path < 2 then return false end
    local count = #path
    local worlds, world = {}, nil
    for index, point in ipairs(path) do
        world = point.map or world
        worlds[index] = world
    end
    local first
    for index, point in ipairs(path) do
        if point.stay then first = index break end
    end
    if not first then return false end
    -- Round once from the first stop: each point, then the piece of way to the next (a leap: none); a stop ends
    -- the run that came to it. Back at the first stop the last run ends, and no stop is added again.
    local stops, runs = {}, {}
    local run = { yards = 0, pieces = {} }
    for step = 0, count do
        local index = (first - 1 + step) % count + 1
        local point = path[index]
        if point.stay then
            if step > 0 then
                runs[#runs + 1] = run
                run = { yards = 0, pieces = {} }
            end
            if step < count then
                stops[#stops + 1] = { index = index, world = worlds[index], x = point.x, y = point.y, stay = point.stay }
            end
        end
        if step == count then break end
        local nextIndex = index % count + 1
        local after = path[nextIndex]
        local length = sqrt((after.x - point.x) ^ 2 + (after.y - point.y) ^ 2)
        local leap = after.jump or worlds[nextIndex] ~= worlds[index] or (nextIndex == 1 and length > Ships.FAR)
        if not leap then
            run.pieces[#run.pieces + 1] = { world = worlds[index], x1 = point.x, y1 = point.y, x2 = after.x, y2 = after.y,
                                            from = run.yards, length = length }
            run.yards = run.yards + length
        end
    end
    -- The sailing, stretched to the known round.
    local sailing, standing = 0, 0
    for _, each in ipairs(runs) do sailing = sailing + Run(each.yards) end
    for _, stop in ipairs(stops) do standing = standing + stop.stay end
    local learnt = key ~= nil and Learnt(key) or nil -- a record not of the set (Ships.Timetable) has no times here
    local given = way.wait ~= nil and way.wait > standing -- the set's own round: rides never change it
    local round = given and way.wait or (learnt and learnt.round)
    local known = round ~= nil and round > standing
    if not known then round = sailing + standing end
    local stretch = sailing > 0 and (round - standing) / sailing or 1
    local at = 0
    for number, stop in ipairs(stops) do
        if number > 1 then
            at = at + Run(runs[number - 1].yards) * stretch
            stop.arrive = at
            at = at + stop.stay
        end
        stop.leave = number == 1 and 0 or at
    end
    stops[1].arrive = round - stops[1].stay
    -- Its docks, numbered in the order it first comes to them (from its first stop, as the set lists them).
    local docks = {}
    for _, stop in ipairs(stops) do
        for number, dock in ipairs(docks) do
            if dock.world == stop.world and (dock.x - stop.x) ^ 2 + (dock.y - stop.y) ^ 2 <= Ships.SAME * Ships.SAME then
                stop.dock = number
                break
            end
        end
        if not stop.dock then
            docks[#docks + 1] = stop
            stop.dock = #docks
        end
        local area = type(way.dockAreas) == "table" and way.dockAreas[stop.dock]
        stop.area = area and area > 0 and area or nil
    end
    return { key = key, kind = way.kind, round = round, known = known, given = given, stretch = stretch, stops = stops,
             runs = runs }
end

function Ships.Timetable(record)
    return Make(nil, record) or nil
end
Ships.Run = Run

function Ships:Table(key)
    local found = tables[key]
    if found == nil then
        if not Travel:Ready() then
            Data.Prepare("Travel")
            return nil
        end
        found = Make(key, Travel:Get(key))
        tables[key] = found
    end
    return found or nil
end

-- Every boat and zeppelin of the set: its key and its timetable.
local function Every()
    local list = {}
    if not Travel:Ready() then return list end
    for kind in pairs(Ships.KINDS) do
        for _, key in ipairs(Travel:Keys("byKind", kind)) do
            local timetable = Ships:Table(key)
            if timetable then list[#list + 1] = timetable end
        end
    end
    return list
end

-------------------------------------------------------------------------------
--  When it sails here
-------------------------------------------------------------------------------
function Ships:Next(key, stop, at)
    local timetable = self:Table(key)
    local learnt = Learnt(key)
    local entry = timetable and timetable.stops[stop]
    if not entry or not learnt or not learnt.epoch then return nil end
    at = at or Ships.Now()
    if at - (learnt.seen or 0) > Ships.TRUST then return nil end
    local round = timetable.round
    local arrive = learnt.epoch + entry.arrive + math.ceil((at - learnt.epoch - entry.arrive) / round) * round
    local before = arrive - round
    if at >= before and at < before + entry.stay then return before, before + entry.stay, true end
    return arrive, arrive + entry.stay, false
end

function Ships:Aboard()
    if not aboard or GetTime() - aboard.at > 2 * Ships.CLOSE + 1 then return nil end
    local timetable = self:Table(aboard.key)
    local run = timetable and timetable.runs[aboard.run]
    if not run then return nil end
    local since = GetTime() - aboard.at
    local left = (Run(run.yards) - Into(run.yards, aboard.s)) * timetable.stretch - since
    -- The yards sailed since that look, at full speed at most.
    local s = math.min(run.yards, aboard.s + since * Ships.SPEED / timetable.stretch)
    return aboard.key, aboard.run % #timetable.stops + 1, math.max(0, left), aboard.run, s
end

function Ships:Seen(key)
    local learnt = Learnt(key)
    if not learnt then return nil end
    return learnt.seen, learnt.rides
end

function Ships:OnLearn(fn)
    listeners[#listeners + 1] = fn
end

local tell = {}
local told = Core.Later(function()
    for key in pairs(tell) do
        tell[key] = nil
        for _, fn in ipairs(listeners) do Core.Safe("data: ships", fn, key) end
    end
end)

-- A ride's epochs agree: kept for this realm. Where the set has no round of its own, the rides learn it, each
-- from the rounds since the ride before. A ride that agrees with the round learnt (within twice AGREE) is of the
-- same run of the realm: it confirms the round, and corrects it when it spans more rounds than the round was
-- learnt from. One that does not is of a new run (a restart of the realm starts its ships anew), or the round is
-- wrong: its time is taken, the round kept but doubted, and the next one that does not agree gives the round. A
-- round worked out from the estimate is doubted too, until a ride agrees with it.
local function Keep(key, epoch, now)
    local timetable = Ships:Table(key)
    local before = Learnt(key)
    local entry = { epoch = epoch, seen = now, rides = (before and before.rides or 0) + 1,
                    round = before and before.round, span = before and before.span, doubt = before and before.doubt }
    if before and timetable and not timetable.given then
        local gap = epoch - before.epoch
        local rounds = floor(gap / timetable.round + 0.5)
        local round = rounds >= 1 and gap / rounds or nil
        if before.round and math.abs(gap - rounds * timetable.round) <= 2 * Ships.AGREE then
            if round then
                entry.doubt = nil
                if rounds > (before.span or 0) then entry.round, entry.span = round, rounds end
            end
        elseif before.round and not before.doubt then
            entry.doubt = true
        elseif round and rounds <= Ships.ROUNDS and math.abs(round - timetable.round) < timetable.round * 0.25 then
            entry.round, entry.span, entry.doubt = round, rounds, true
        end
        if entry.round ~= before.round then tables[key] = nil end -- made anew with the learnt round
    end
    Learnt()[key] = entry
    tell[key] = true
    told()
end

-- Where along a way a place of the world lies: the timetable, its run's number and the yards into it; the way
-- nearest within Ships.NEAR yards.
local function Along(world, x, y)
    local best, bestTable, bestRun, bestS
    for _, timetable in ipairs(Every()) do
        for number, run in ipairs(timetable.runs) do
            for _, piece in ipairs(run.pieces) do
                if piece.world == world then
                    local dx, dy = piece.x2 - piece.x1, piece.y2 - piece.y1
                    local length = dx * dx + dy * dy
                    local t = length > 0 and math.max(0, math.min(1, ((x - piece.x1) * dx + (y - piece.y1) * dy) / length)) or 0
                    local gap = sqrt((x - piece.x1 - dx * t) ^ 2 + (y - piece.y1 - dy * t) ^ 2)
                    if gap <= Ships.NEAR and (not best or gap < best) then
                        best, bestTable, bestRun, bestS = gap, timetable, number, piece.from + piece.length * t
                    end
                end
            end
        end
    end
    return bestTable, bestRun, bestS
end

-- The player's place in the world: x, y and the world's map; nil where the game does not tell it (an instance, a
-- loading screen). Its fourth answer is the map: past what Core.Ask gives.
local function Place()
    local position = rawget(_G, "UnitPosition")
    if not position then return nil end
    local ok, x, y, _, world = pcall(position, "player")
    if not ok then return nil end
    x, y, world = Core.Plain(x), Core.Plain(y), Core.Plain(world)
    if not x or not y or not world then return nil end
    return x, y, world
end

function Ships:Near(yards)
    local list = {}
    local x, y, world = Place()
    if not x then return list end
    for _, timetable in ipairs(Every()) do
        for number, stop in ipairs(timetable.stops) do
            if stop.world == world and (stop.x - x) ^ 2 + (stop.y - y) ^ 2 <= yards * yards then
                list[#list + 1] = { key = timetable.key, stop = number }
            end
        end
    end
    return list
end

-- Whether a place of the world is near one of the stops (so it is looked at often).
local function NearStop(world, x, y)
    for _, timetable in ipairs(Every()) do
        for _, stop in ipairs(timetable.stops) do
            if stop.world == world and (stop.x - x) ^ 2 + (stop.y - y) ^ 2 <= Ships.DOCK * Ships.DOCK then return true end
        end
    end
    return false
end

local last -- the sample before: { key, run, s, t }

-- One look at the player's place: aboard a boat at full speed, when it left its last stop; enough that agree, a ride.
local function Look()
    if rawget(_G, "UnitOnTaxi") and Core.Plain(UnitOnTaxi("player")) then
        last, ride = nil, nil
        return false
    end
    local x, y, world = Place()
    if not x then
        last, ride, aboard = nil, nil, nil
        return false
    end
    local now = Ships.Now()
    local timetable, number, s = Along(world, x, y)
    if not timetable then
        last, ride, aboard = nil, nil, nil
        return NearStop(world, x, y)
    end
    local run = timetable.runs[number]
    if last and last.key == timetable.key and last.run == number and now > last.t then
        local pace = (s - last.s) / (now - last.t)
        local speed = Ships.SPEED / timetable.stretch
        -- Moving on along the way at the boat's full speed (faster than any mount): aboard; then on this run
        -- while it moves on, slowing down into the next stop too.
        local still = aboard and aboard.key == timetable.key and aboard.run == number
        if pace <= speed * (1 + Ships.PACE) and s > last.s + 1
            and (pace >= speed * (1 - Ships.PACE) or still) then
            aboard = { key = timetable.key, run = number, s = s, at = GetTime() }
        end
        -- A ride counted once: until the player is off its way.
        local kept = ride and ride.kept and ride.key == timetable.key
        if not kept and math.abs(pace - speed) <= speed * Ships.PACE and Cruising(run.yards, s) then
            local left = timetable.stops[number].leave -- the run starts at stop number and ends at the next
            local epoch = now - Into(run.yards, s) * timetable.stretch - left
            if not ride or ride.key ~= timetable.key then ride = { key = timetable.key, epochs = {} } end
            local list = ride.epochs
            list[#list + 1] = epoch
            if #list >= Ships.SAMPLES then
                table.sort(list)
                local middle = list[floor(#list / 2) + 1]
                local agree = 0
                for _, value in ipairs(list) do
                    if math.abs(value - middle) <= Ships.AGREE then agree = agree + 1 end
                end
                if agree >= Ships.SAMPLES then
                    Keep(timetable.key, middle, now)
                    ride = { key = timetable.key, kept = true }
                end
            end
        end
    end
    last = { key = timetable.key, run = number, s = s, t = now }
    return true
end

-- The looks, one after the other: often near a stop or aboard, else seldom.
local looking = false
local Tick
Tick = Core.Guard("data: ships", function()
    local close = Look()
    C_Timer.After(close and Ships.CLOSE or Ships.LOOK, Tick) -- unguarded: Tick is the guard (Core.Guard)
end)
-- A loading screen: the samples before it were of another place.
Core.On("PLAYER_ENTERING_WORLD", function() last, ride = nil, nil end)
-- The set Travel arrived (with Core, at the login): the looks begin then, and
-- never before, so nothing is looked at for a set that is not loaded. It changed: its timetables are made anew.
Travel:OnStamp(function()
    wipe(tables)
    if looking then return end
    looking = true
    C_Timer.After(Ships.LOOK, Tick) -- unguarded: Tick is the guard (Core.Guard)
end)

function Data.Ships()
    return Ships
end
