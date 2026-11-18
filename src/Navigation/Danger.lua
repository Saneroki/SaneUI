local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Danger
--  How dangerous a place is for you: the enemies that spawn near it, by their levels
--  against yours (Saneroki, 2026-11-11: "Color the golden routing line in depending on
--  how dangerous it is. So we know where which enemies spawn and what their level is.
--  Can we make a routing show fx red if the enemies level range is clearly above me").
--  The golden line takes its colour from it (Route.lua). No frames.
--
--      Danger.At(plane, u, v)   0: no enemy there a few levels above you; 1: one Danger.ORANGE levels
--                               above you or more (the game's very difficult, orange); 2: Danger.RED
--                               levels or more (its impossible, red). 0 everywhere until worked out
--      Danger.Ready()           whether the enemies are worked out
--      Danger.Work()            work them out (a job), where they are not yet and the data is there
--
--  The enemies: every creature of Core's set CreatureSpawns (its points) that is hostile to your side (its
--  faction template in the set NPCs, the template's reaction in the set FactionTemplates, the client's own
--  table), no critter, no rare (one alone that wanders), whose levels span at most Danger.SPAN (not a pet or a
--  summon seen at many levels). Each of its points marks the cells of a grid of Danger.CELL yards on its
--  plane within Danger.REACH yards of it (about how near one comes before it attacks) with its lowest
--  level; a cell keeps the highest. Worked out once, a job of Core's scheduler, when first asked, and again
--  when the data changes; a level gained changes only the steps, so the line is coloured anew.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Danger = {}
ns.Danger = Danger

Danger.CELL = 50   -- yards a cell of the grid is on a side
Danger.REACH = 25  -- yards round a spawn point where its creature is a danger
Danger.ORANGE = 3  -- levels above you an enemy is very difficult (the game's orange: DifficultyUtil)
Danger.RED = 5     -- levels above you it is impossible (the game's red)
Danger.SPAN = 3    -- levels a creature's range may span and still be counted (as the zones' levels, Label.lua)
Danger.SKIP = { rare = true, rareelite = true, worldboss = true, trivial = true, minus = true }

local Creatures, NPCs = Core.Data.Set("CreatureSpawns"), Core.Data.Set("NPCs")
local Templates = Core.Data.Set("FactionTemplates")
local grids    -- [plane] = { [cell] = the highest lowest level of the enemies near it }; nil until worked out
local reading  -- the walk over the creatures working them out
local floor = math.floor
local NONE = {}

-- A cell's key from its column and row on the grid (both well within 2^15 of 0 on every plane).
local function Cell(column, row)
    return (column + 32768) * 65536 + row + 32768
end

-- Your side as the set FactionTemplates names it ("alliance", "horde"), nil while the game tells none.
local function Side()
    local side = Core.Plain(UnitFactionGroup("player"))
    return type(side) == "string" and side:lower() or nil
end

-- A creature's lowest level where it is an enemy of the side, else nil.
local function Enemy(npc, side)
    if type(npc) ~= "table" or not npc.faction then return nil end
    local low = npc.levelMin
    if type(low) ~= "number" or low <= 0 or npc.kind == "critter" or Danger.SKIP[npc.rank or ""] then return nil end
    local high = type(npc.levelMax) == "number" and npc.levelMax or low
    if high - low > Danger.SPAN then return nil end
    if Templates:Get(npc.faction, side) ~= "hostile" then return nil end
    return low
end

-- The cells within Danger.REACH of a point marked with level, the higher kept.
local function Mark(grid, u, v, level)
    local cell, reach = Danger.CELL, Danger.REACH
    for column = floor((u - reach) / cell), floor((u + reach) / cell) do
        for row = floor((v - reach) / cell), floor((v + reach) / cell) do
            local key = Cell(column, row)
            local had = grid[key]
            if not had or had < level then grid[key] = level end
        end
    end
end

-- The grids worked out, once: a walk over the creatures' spawns (a job of Core's scheduler); the line coloured
-- anew once done.
local function Work()
    if grids or reading then return end
    local side = Side()
    if not side or not (Creatures:Ready() and NPCs:Ready() and Templates:Ready()) then return end
    local found, planes = {}, {} -- [plane] = grid; [map] = its plane, or false
    local job = Creatures:Each(function(id, record)
        local level = Enemy(NPCs:Get(id), side)
        if not level then return end
        for _, point in ipairs(type(record.points) == "table" and record.points or NONE) do
            local map = type(point) == "table" and point.map
            local plane = map and planes[map]
            if map and plane == nil then
                plane = Coords.PlaneOf(map) or false
                planes[map] = plane
            end
            local u, v
            if plane then u, v = Coords.MapToPlane(map, point.x / 100, point.y / 100, plane) end
            if u then
                local grid = found[plane]
                if not grid then
                    grid = {}
                    found[plane] = grid
                end
                Mark(grid, u, v, level)
            end
        end
    end, function(problem)
        reading = nil
        if problem then return end
        grids = found
        if ns.Route then ns.Safe("route", ns.Route.Again) end
    end)
    reading = job or nil
end

function Danger.Ready()
    return grids ~= nil
end

-- The enemies worked out, where they are not yet and the data is there (a job: the line is drawn again once done).
Danger.Work = Work

function Danger.At(plane, u, v)
    if not grids then
        Work()
        return 0
    end
    local grid = plane and grids[plane]
    local level = grid and grid[Cell(floor(u / Danger.CELL), floor(v / Danger.CELL))]
    if not level then return 0 end
    local above = level - (Core.Plain(UnitLevel("player")) or 1)
    if above >= Danger.RED then return 2 end
    if above >= Danger.ORANGE then return 1 end
    return 0
end

-- A level gained: the line's colours anew, a moment later (the game tells the new level at once only in the event).
-- The creatures, their facts or the templates changed: worked out again when next asked.
ns.On("PLAYER_LEVEL_UP", Core.Later(function()
    if grids and ns.Route then ns.Safe("route", ns.Route.Again) end
end, 1))
local function Stale()
    if reading then reading:Stop() end
    grids, reading = nil, nil
    if ns.Route then ns.Safe("route", ns.Route.Again) end
end
Creatures:OnStamp(ns.Guard(Stale))
NPCs:OnStamp(ns.Guard(Stale))
Templates:OnStamp(ns.Guard(Stale))
