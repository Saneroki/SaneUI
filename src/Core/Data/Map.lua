local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Map
--  What Core's data puts on a map (Doc/ideas/Data.md, *Places on the map*): the
--  places of the sets Spawns (NPCs with a service, rares, quest givers, the
--  objects players use), Places (crossings, caves, entrances, piers, mailboxes,
--  meeting stones, spirit healers) and Travel (boats, zeppelins, trams, lifts,
--  portals), each with what it is. A module only reads them:
--
--      local Map = SaneUI.Core.Data.Map()
--      local list = Map:On(1429)    -- the places on that map, or nil while they are being read
--      Map:OnChange(Redraw)         -- fn() on the frame after the places changed (OffChange)
--      Map:Spawns("npc:69")         -- an NPC's or object's points: { [map] = { { x, y }, ... } }
--
--  A place is a plain table, read-only like a record, x and y from 0 to 1 on its map:
--      kind      "npc", "object", "place" or "travel": which set it came from
--      key       one per thing (Doc/ideas/Navigation.md, *One pin per thing*): "npc:69", "object:1617",
--                "place:12", "travel:3"; a boat's or zeppelin's dock "travel:<way>:<dock>", its number in the
--                way's docks
--      id        the creature's or object's ID; the place's or way's number
--      what      what it is: an NPC's services (a list) with rare = true, quests = { quest IDs it offers };
--                an object's kind (herb, ore, chest, mailbox, quest, book, door, other); a place's kind
--                (crossing, cave, dungeon, raid, pier, mailbox, meetingstone, spirithealer); a way's kind
--                (boat, zeppelin, tram, lift, portal, flight)
--      name, to (the map a place or way leads to), levelMin, levelMax, side
--      towards   a dock's: where its boat or zeppelin goes from there, its way's other docks, each { map, area
--                (the game's area there, AreaTable ID, or nil) }
--  An NPC with many points on a map (a wanderer, a rare) stands at the middles of its areas there instead; a
--  boat or a zeppelin at each of its docks (Travel's docks), one place per dock even where it stops twice.
--
--  Read as a job of the scheduler when a set it reads arrives or changes. A set no pack holds (empty in the
--  master, so not shipped) or switched off is passed over without a word: its places are simply not there.
-------------------------------------------------------------------------------
local Data = Core.Data

local MapReader = {}
MapReader.MANY = 4 -- an NPC with more points than this on one map stands at its areas' middles there
-- The sets read for the places, and those that say what a place is.
MapReader.PLACES = { "Spawns", "Places", "Travel" }
MapReader.FACTS = { "NPCs", "Objects", "Quests" }

local handles = {}
for _, name in ipairs(MapReader.PLACES) do handles[name] = Data.Set(name) end
for _, name in ipairs(MapReader.FACTS) do handles[name] = Data.Set(name) end

local byMap        -- [uiMapID] = its places, once read; nil while reading or not yet asked
local spawns = {}  -- [Spawns key] = { [map] = { { x, y }, ... } }
local listeners = {}
local job, stale -- a walk is running; a set changed while it ran
local FROZEN = { __newindex = function() error("a place of Sane UI's data is read-only", 2) end }

-- Whether a set can be had: there is a pack for it, and it is not switched off or refused.
local function Usable(handle)
    local state = handle:State()
    return state == "ready" or state == "loading" or state == "idle"
end

-- A record or an index' keys of a set that can be had; nothing (and no word) from one no pack holds.
local function Get(name, key)
    local handle = handles[name]
    return Usable(handle) and handle:Get(key) or nil
end

local function Keys(name, index, value)
    local handle = handles[name]
    return Usable(handle) and handle:Keys(index, value) or {}
end

local function Hand(value)
    if Data.frozen then return setmetatable(value, FROZEN) end
    return value
end

-- Adds a place to its map's list (x, y in percent, as the master keeps them).
local function Put(found, map, x, y, place)
    if type(map) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return end
    local list = found[map]
    if not list then
        list = {}
        found[map] = list
    end
    local copy = { x = x / 100, y = y / 100 }
    for field, value in pairs(place) do copy[field] = value end
    list[#list + 1] = Hand(copy)
end

-- What an NPC is: its services, whether it is a rare, the quests it offers; nil for one that is none of them
-- (it belongs to the creatures' spawns, not to the map).
local function Creature(id)
    local npc = Get("NPCs", id)
    local quests = Keys("Quests", "byStartNPC", id)
    local services = npc and npc.services
    local rare = npc and (npc.rank == "rare" or npc.rank == "rareelite") or nil
    if not (services and #services > 0) and not rare and #quests == 0 then return nil end
    return { services = services, rare = rare, quests = #quests > 0 and quests or nil, goods = npc and npc.goods },
        npc and npc.name, npc and npc.levelMin, npc and npc.levelMax
end

-- One entry of Spawns: its points, each on its map; a creature with many points on a map at its areas' middles.
local function Spawn(found, key, record)
    local kind, id = tostring(key):match("^(%a+):(%d+)$")
    id = tonumber(id)
    if not id or (kind ~= "npc" and kind ~= "object") then return end
    local what, name, low, high
    if kind == "npc" then
        what, name, low, high = Creature(id)
        if not what then return end
    else
        local object = Get("Objects", id)
        what, name = object and object.kind or "other", object and object.name
    end
    local place = { kind = kind, key = kind .. ":" .. id, id = id, what = what, name = name, levelMin = low, levelMax = high }
    local points, count = {}, {}
    for _, point in ipairs(record.points or {}) do
        local map = point.map
        points[map] = points[map] or {}
        local list = points[map]
        list[#list + 1] = { point.x / 100, point.y / 100 }
        count[map] = (count[map] or 0) + 1
    end
    spawns[place.key] = points
    local middles = {}
    if kind == "npc" then
        for _, middle in ipairs(record.middles or {}) do
            middles[middle.map] = true
            if (count[middle.map] or 0) > MapReader.MANY then Put(found, middle.map, middle.x, middle.y, place) end
        end
    end
    for _, point in ipairs(record.points or {}) do
        if not (middles[point.map] and count[point.map] > MapReader.MANY) then Put(found, point.map, point.x, point.y, place) end
    end
end

local function Place(found, key, record)
    local point = record.point
    if not point then return end
    Put(found, point.map, point.x, point.y, { kind = "place", key = "place:" .. key, id = key, what = record.kind,
        name = record.name, to = record.to, levelMin = record.levelMin, levelMax = record.levelMax })
end

-- A boat or a zeppelin at each of its docks, one place each (also where it stops twice), with where it goes from there:
-- its other docks, each { map, area }, and to (their map) where it is one.
local function Docks(found, key, record)
    local docks, areas = record.docks, record.dockAreas or {}
    for index, dock in ipairs(docks) do
        local towards = {}
        for other, there in ipairs(docks) do
            local area = areas[other]
            if other ~= index then
                towards[#towards + 1] = Hand({ map = there.map, area = area and area > 0 and area or nil })
            end
        end
        Put(found, dock.map, dock.x, dock.y, { kind = "travel", key = "travel:" .. key .. ":" .. index, id = key,
            what = record.kind, name = record.name, side = record.side, towards = Hand(towards),
            to = #towards == 1 and towards[1].map or nil })
    end
end

-- A way: a boat or a zeppelin at its docks; else at its start, and a way between two places (not a flight: the game
-- knows its flight points) at both ends.
local function Way(found, key, record)
    if record.kind == "flight" then return end
    if record.docks then return Docks(found, key, record) end
    local place = { kind = "travel", key = "travel:" .. key, id = key, what = record.kind, name = record.name,
        side = record.side }
    local from, to = record.from, record.to
    if from then Put(found, from.map, from.x, from.y, place) end
    if to and (not from or to.map ~= from.map or to.x ~= from.x or to.y ~= from.y) then
        Put(found, to.map, to.x, to.y, place)
    end
end

local READERS = { Spawns = Spawn, Places = Place, Travel = Way }

local tell = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("data: map", fn) end
end)

-- Every place read anew, a walk over each set that is there (Each: a job of the scheduler), one after
-- the other; told on the next frame once all are read. A set changed meanwhile: read again after it.
local function Read()
    stale = false
    local found, names = {}, {}
    wipe(spawns)
    for _, name in ipairs(MapReader.PLACES) do
        if handles[name]:Ready() then names[#names + 1] = name end
    end
    local function Next(index)
        local name = names[index]
        if not name then
            job = nil
            if stale then return Read() end
            byMap = found
            return tell()
        end
        local read = READERS[name]
        job = handles[name]:Each(function(key, record) read(found, key, record) end, function(problem)
            if problem then
                job, byMap = nil, found -- what was read stays; the failure is noted by the walk
                return tell()
            end
            Next(index + 1)
        end)
        if not job then Next(index + 1) end -- gone meanwhile
    end
    Next(1)
end

-- A set changed or arrived: read again (after the job running now, if one is).
local function Changed()
    if job then
        stale = true
        return
    end
    Read()
end

local started = false
local function Start()
    if started then return end
    started = true
    for _, handle in pairs(handles) do
        handle:OnStamp(Changed)
        if Usable(handle) then Data.Prepare(handle.name) end
    end
    Read()
end

local reader = {}

-- The places on a map, or nil while they are being read (the first time it is asked, the sets are asked for).
function reader:On(map)
    Start()
    if not byMap then return nil end
    return byMap[map] or Hand({})
end

-- An NPC's or object's points by map ({ [map] = { { x, y }, ... } }, x and y 0 to 1), or nil.
function reader:Spawns(key)
    Start()
    return byMap and spawns[key] or nil
end

-- fn() on the frame after the places changed; given twice, told once.
function reader:OnChange(fn)
    self:OffChange(fn)
    listeners[#listeners + 1] = fn
end

function reader:OffChange(fn)
    for index = #listeners, 1, -1 do
        if listeners[index] == fn then table.remove(listeners, index) end
    end
end

function Data.Map()
    return reader
end
Data.MapReader = MapReader
