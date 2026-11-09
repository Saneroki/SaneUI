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
--      Map:Spawns("npc:69")         -- a thing's points: { [map] = { { x, y }, ... } }, of what goes on the map
--                                   -- only (an NPC with a service, a rare, a quest giver; an object)
--
--  A place is a plain table, read-only like a record, x and y from 0 to 1 on its map:
--      kind      "npc", "object", "place" or "travel": which set it came from
--      key       one per thing (Doc/ideas/Navigation.md, *One pin per thing*): "npc:69", "object:1617",
--                "place:12", "travel:3"; a boat's or zeppelin's dock "travel:<way>:<dock>", its number in the
--                way's docks
--      id        the creature's or object's ID; the place's or way's number
--      what      what it is: an NPC's services (a list) with rare = true, quests = { quest IDs it offers }, title (the
--                line under its name: Warrior Trainer);
--                an object's kind (herb, ore, chest, mailbox, quest, book, door, other); a place's kind
--                (crossing, cave, dungeon, raid, pier, mailbox, meetingstone, spirithealer); a way's kind
--                (boat, zeppelin, tram, lift, portal, flight)
--      name, to (the map a place or way leads to), levelMin, levelMax, side; instance (a dungeon's or raid's
--                entrance: its instance's map ID)
--      towards   a dock's: where its boat or zeppelin goes from there, its way's other docks, each { map, area
--                (the game's area there, AreaTable ID, or nil) }; dock: its number in the way's docks
--  An NPC with many points on a map (a wanderer, a rare) stands at the middles of its areas there instead; a
--  boat or a zeppelin at each of its docks (Travel's docks), one place per dock even where it stops twice.
--
--  Read as a job of the scheduler when a set it reads arrives or changes, MapReader.REREAD seconds after the change, so
--  that a burst of them (the stamps of NPCs and Quests move in play, with every row learned) is one walk. A change of the
--  facts alone (NPCs, Objects, Quests) is first looked through: the places are read anew only where a creature's or an
--  object's name or kind changed, not for a creature's health learned. A set Core does not hold (empty in the master, so
--  not shipped) or refused is passed over without a word: its places are simply not there.
-------------------------------------------------------------------------------
local Data, Steps = Core.Data, Core.Steps

local MapReader = {}
MapReader.MANY = 4   -- an NPC with more points than this on one map stands at its areas' middles there
MapReader.REREAD = 5 -- seconds a change waits before the places are read anew: a burst of changes is one walk
-- The sets read for the places, and those that say what a place is.
MapReader.PLACES = { "Spawns", "Places", "Travel" }
MapReader.FACTS = { "NPCs", "Objects", "Quests" }

local handles = {}
for _, name in ipairs(MapReader.PLACES) do handles[name] = Data.Set(name) end
for _, name in ipairs(MapReader.FACTS) do handles[name] = Data.Set(name) end

local byMap        -- [uiMapID] = its places, once read; nil while reading or not yet asked
local spawns = {}  -- [Spawns key] = { [map] = { { x, y }, ... } } of what goes on the map, of the same read as byMap
local said = { npc = {}, object = {} } -- [id] = what the facts said of each creature and object with a spawn, of the same read (Look)
local listeners = {}
local job, stale   -- a walk (or a look through the facts) is running; a set changed while it ran
local changed = {} -- [set name] = true: changed since the last walk began
local Again        -- what a change asks for, below
local NONE = {}
local FROZEN = { __newindex = function() error("a place of Sane UI's data is read-only", 2) end }

-- Whether a set can be had: Core holds it (or is still reading it), and it is not refused.
local function Usable(handle)
    local state = handle:State()
    return state == "ready" or state == "loading"
end

-- A record or an index' keys of a set that can be had; nothing (and no word) from one Core does not hold.
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
    return { services = services, rare = rare, quests = #quests > 0 and quests or nil, goods = npc and npc.goods,
             title = npc and npc.title },
        npc and npc.name, npc and npc.levelMin, npc and npc.levelMax
end

-- What the facts say of a creature (Creature's answers), or of an object, in one line: what a place gets of them. A
-- line that is the same after a change of the facts asks for no walk (Look).
local function SaidOf(what, name, low, high)
    if not what then return "" end
    return table.concat({ name or "", table.concat(what.services or NONE, ","), what.rare and "rare" or "", what.title or "",
        table.concat(what.quests or NONE, ","), low or "", high or "", type(what.goods) == "table" and #what.goods or "" }, "\031")
end

local function SaidOfObject(object)
    return (object and object.kind or "other") .. "\031" .. (object and object.name or "")
end

-- One entry of Spawns: its points, each on its map (into spawned); a creature with many points on a map at its
-- areas' middles. What the facts said of the creature or object goes into lines, for Look.
local function Spawn(found, key, record, spawned, lines)
    local kind, id = tostring(key):match("^(%a+):(%d+)$")
    id = tonumber(id)
    if not id or (kind ~= "npc" and kind ~= "object") then return end
    local what, name, low, high
    if kind == "npc" then
        what, name, low, high = Creature(id)
        lines.npc[id] = SaidOf(what, name, low, high)
        if not what then return end
    else
        local object = Get("Objects", id)
        lines.object[id] = SaidOfObject(object)
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
    spawned[place.key] = points
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
        name = record.name, to = record.to, levelMin = record.levelMin, levelMax = record.levelMax,
        instance = record.instance })
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
            dock = index, what = record.kind, name = record.name, side = record.side, towards = Hand(towards),
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
-- the other; told on the next frame once all are read. A set changed meanwhile: looked at after it (Again).
-- The places and the points come in together: the last read's stay in use until the new one is done.
local function Read()
    stale = false
    wipe(changed)
    local found, spawned, lines, names = {}, {}, { npc = {}, object = {} }, {}
    for _, name in ipairs(MapReader.PLACES) do
        if handles[name]:Ready() then names[#names + 1] = name end
    end
    local function Next(index)
        local name = names[index]
        if not name then
            job, byMap, spawns, said = nil, found, spawned, lines
            tell()
            if stale then Again() end
            return
        end
        local read = READERS[name]
        job = handles[name]:Each(function(key, record) read(found, key, record, spawned, lines) end, function(problem)
            if problem then
                job, byMap, spawns, said = nil, found, spawned, lines -- what was read stays; the failure is noted by the walk
                return tell()
            end
            Next(index + 1)
        end)
        if not job then Next(index + 1) end -- gone meanwhile
    end
    Next(1)
end

-- Only the facts changed (NPCs, Objects, Quests: their stamps move in play, with every row learned): what they say
-- of each creature and object placed, looked through as a job of the scheduler, and the places read anew only where
-- one says something else now. A creature's health learned costs no walk; a vendor's services or a rare's name do.
local function Look()
    stale = false -- as Read does: a change that lands while this look runs is looked at after it, once
    local creatures, objects = changed.NPCs or changed.Quests, changed.Objects
    wipe(changed)
    local differs = false
    job = Steps.Run({ name = "Map look", label = "data job Map look", done = function(problem)
        job = nil
        if problem or differs then return Read() end
        if stale then Again() end
    end }, function()
        for id, line in pairs(creatures and said.npc or NONE) do
            if SaidOf(Creature(id)) ~= line then
                differs = true
                return
            end
            Steps.Check()
        end
        for id, line in pairs(objects and said.object or NONE) do
            if SaidOfObject(Get("Objects", id)) ~= line then
                differs = true
                return
            end
            Steps.Check()
        end
    end)
    if not job then Read() end -- a look of the same name still running: cannot be (job), read anew to be sure
end

-- What a change asks for: the whole walk where a set of places changed (or none was read yet), else a look
-- through the facts; after the walk running now, if one is.
function Again()
    if job then
        stale = true
        return
    end
    local whole = byMap == nil
    for _, name in ipairs(MapReader.PLACES) do
        if changed[name] then whole = true end
    end
    if whole then Read() else Look() end
end

-- A set changed or arrived: read again MapReader.REREAD seconds later, once for all the sets told meanwhile (those
-- read with Core arrive at once; the rows learned in play come in bursts); after the walk running now, if one is.
local Reread = Core.Later(Again, MapReader.REREAD)

local function Changed(handle)
    changed[handle.name] = true
    if job then
        stale = true
        return
    end
    Reread()
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

-- A thing's points by map ({ [map] = { { x, y }, ... } }, x and y 0 to 1): of an object, or of an NPC that goes
-- on the map (with a service, a rare, a quest giver); nil for any other creature, or while first read.
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
