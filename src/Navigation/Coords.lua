local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Coords
--  The spaces the map is drawn in, the map tree, and the one place that turns
--  one space into another. Knows no frames.
--
--      map     (uiMapID, x, y): 0 to 1 from the map's top left corner; the game's map API
--      world   (continent, X, Y) in yards: X grows to the north, Y to the west; the terrain's grid
--      plane   (u, v) in yards on one continent: u = -Y grows to the east (right), v = X to the
--              north (up); what the canvas draws, so that the screen is the plane times a scale
--
--  A map's box in the plane comes from the game (C_Map.GetWorldPosFromMapPos at
--  its corners), asked once a session. A map the game gives no box for (a
--  dungeon, the world map) has none: false.
--
--  The map tree, found at run time: the world map (C_Map.GetFallbackWorldMapID),
--  its continents, their zones. Each continent has its own plane; the world map
--  links them: a continent's rectangle on it (C_Map.GetMapRectOnMap) puts every
--  continent, and the world map itself, into any continent's plane (Link,
--  WorldBox), so the map zooms from a zone out to the whole world in one space.
--
--  The terrain's grid: every continent is 64 x 64 tiles of 1600/3 yards, its
--  middle at the world's 0, 0; a tile's key in Core's set Tiles is
--  continent * 4096 + row * 64 + column.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = {}
ns.Coords = Coords

Coords.TILE = 1600 / 3 -- a terrain tile's side in yards
Coords.GRID = 64       -- tiles a continent's grid has along each side, its middle at 32
local MIDDLE = Coords.GRID / 2
local floor = math.floor

-- The game's numbers for kinds of map (Enum.UIMapType), should the table be missing.
local KINDS = rawget(_G, "Enum") and Enum.UIMapType or {}
Coords.WORLD, Coords.CONTINENT, Coords.ZONE = KINDS.World or 1, KINDS.Continent or 2, KINDS.Zone or 3

local boxes = {}      -- [uiMapID] = its box, or false: asked once a session
local continentOf = {} -- [uiMapID] = the continent it lies on, or false
local onWorld = {}    -- [continent] = { x0, x1, y0, y1 } on the world map, or false
local links = {}      -- [from] = { [to] = { su, sv, du, dv } or false }
local worldBoxes = {} -- [continent] = the world map's box in that continent's plane, or false
local world           -- the world map's ID, once asked
local probe           -- the one vector every question to the game is put in

-- The world position the game gives for a point of a map: its continent and the vector's two numbers.
local function World(map, x, y)
    probe = probe or CreateVector2D(0, 0)
    probe:SetXY(x, y)
    local continent, position = Core.Ask(C_Map.GetWorldPosFromMapPos, map, probe)
    if type(continent) ~= "number" or type(position) ~= "table" then return nil end
    return continent, Core.Plain(position.x), Core.Plain(position.y)
end

-- A map's box: its continent, its top left corner in the plane (u, v) and its size in yards (width
-- to the east, height to the south); false when the game gives none. Which of the vector's two numbers
-- is which is read from the map itself: the one that changes from the map's left edge to its right is
-- Y (west), the other X (north).
function Coords.Box(map)
    local box = boxes[map]
    if box ~= nil then return box end
    box = false
    local c0, a0, b0 = World(map, 0, 0)
    local c1, a1, b1 = World(map, 1, 1)
    local c2, a2, b2 = World(map, 1, 0)
    if c0 and a0 and b0 and a1 and b1 and a2 and b2 and c1 == c0 and c2 == c0 then
        local west0, west1, north0, north1 = b0, b1, a0, a1
        if math.abs(a2 - a0) > math.abs(b2 - b0) then west0, west1, north0, north1 = a0, a1, b0, b1 end
        local width, height = west0 - west1, north0 - north1
        if width > 0 and height > 0 then
            box = { continent = c0, u = -west0, v = north0, width = width, height = height }
        end
    end
    boxes[map] = box
    return box
end

-- A point of a map in the plane of its continent, and back.
function Coords.ToPlane(box, x, y)
    return box.u + x * box.width, box.v - y * box.height
end

function Coords.ToMap(box, u, v)
    return (u - box.u) / box.width, (box.v - v) / box.height
end

-------------------------------------------------------------------------------
--  The terrain's grid
-------------------------------------------------------------------------------
-- The terrain tile a point of the plane lies on: its column and row (0 to 63 on the grid).
function Coords.Tile(u, v)
    return floor(MIDDLE + u / Coords.TILE), floor(MIDDLE - v / Coords.TILE)
end

-- A tile's top left corner in the plane.
function Coords.Corner(column, row)
    return (column - MIDDLE) * Coords.TILE, (MIDDLE - row) * Coords.TILE
end

-- A tile's key in Core's set Tiles.
function Coords.TileKey(continent, column, row)
    return continent * Coords.GRID * Coords.GRID + row * Coords.GRID + column
end

-------------------------------------------------------------------------------
--  The map tree
-------------------------------------------------------------------------------
-- The world map, the root of the tree.
function Coords.WorldMap()
    world = world or Core.Ask(C_Map.GetFallbackWorldMapID)
    return world
end

-- The continent a map lies on: itself, or the first of its parents that is one; nil when none is.
function Coords.ContinentOf(map)
    if not map then return nil end
    local found = continentOf[map]
    if found ~= nil then return found or nil end
    found = false
    local at, seen = map, 0
    while at and at > 0 and seen < 10 do
        local info = Core.Ask(C_Map.GetMapInfo, at)
        if type(info) ~= "table" then break end
        if info.mapType == Coords.CONTINENT then found = at break end
        at, seen = info.parentMapID, seen + 1
    end
    continentOf[map] = found
    return found or nil
end

-- The world's continents that have a box, as the game lists them (none known in advance); asked once a
-- session, the same list each time (not to be changed).
local continents
function Coords.Continents()
    if continents then return continents end
    local list = {}
    local root = Coords.WorldMap()
    local children = root and Core.Ask(C_Map.GetMapChildrenInfo, root, Coords.CONTINENT)
    for _, info in ipairs(type(children) == "table" and children or {}) do
        if info.mapID and Coords.Box(info.mapID) then list[#list + 1] = info.mapID end
    end
    if #list > 0 then continents = list end
    return list
end

-- A continent's rectangle on the world map (0 to 1), or nil.
local function OnWorld(continent)
    local rect = onWorld[continent]
    if rect == nil then
        rect = false
        local root = Coords.WorldMap()
        if root and root ~= continent then
            -- Four answers: Core.Ask hands on three.
            local ok, x0, x1, y0, y1 = pcall(C_Map.GetMapRectOnMap, continent, root)
            if ok and type(x0) == "number" and type(x1) == "number" and type(y0) == "number" and type(y1) == "number"
                and x1 > x0 and y1 > y0 then
                rect = { x0, x1, y0, y1 }
            end
        end
        onWorld[continent] = rect
    end
    return rect or nil
end

-- A point of a continent's plane on the world map (0 to 1), and back; nil when the game does not link them.
function Coords.ToWorldMap(continent, u, v)
    local box, rect = Coords.Box(continent), OnWorld(continent)
    if not box or not rect then return nil end
    local x, y = Coords.ToMap(box, u, v)
    return rect[1] + x * (rect[2] - rect[1]), rect[3] + y * (rect[4] - rect[3])
end

function Coords.FromWorldMap(continent, x, y)
    local box, rect = Coords.Box(continent), OnWorld(continent)
    if not box or not rect then return nil end
    return Coords.ToPlane(box, (x - rect[1]) / (rect[2] - rect[1]), (y - rect[3]) / (rect[4] - rect[3]))
end

-- How a point of one continent's plane lies in another's, through the world map: u' = du + su * u,
-- v' = dv + sv * v. The same continent: as it is. nil when the game does not link them.
function Coords.Link(from, to)
    local list = links[from]
    if not list then
        list = {}
        links[from] = list
    end
    local link = list[to]
    if link == nil then
        link = false
        if from == to then
            link = { su = 1, sv = 1, du = 0, dv = 0 }
        else
            local x0, y0 = Coords.ToWorldMap(from, 0, 0)
            local x1, y1 = Coords.ToWorldMap(from, 1, 1)
            if x0 and x1 then
                local u0, v0 = Coords.FromWorldMap(to, x0, y0)
                local u1, v1 = Coords.FromWorldMap(to, x1, y1)
                if u0 and u1 then link = { su = u1 - u0, sv = v1 - v0, du = u0, dv = v0 } end
            end
        end
        list[to] = link
    end
    return link or nil
end

-- The world map's box in a continent's plane (the world map has no world position of its own), or nil.
function Coords.WorldBox(continent)
    local box = worldBoxes[continent]
    if box == nil then
        box = false
        local u0, v0 = Coords.FromWorldMap(continent, 0, 0)
        local u1, v1 = Coords.FromWorldMap(continent, 1, 1)
        if u0 and u1 and u1 > u0 and v0 > v1 then
            box = { continent = Coords.Box(continent).continent, u = u0, v = v0, width = u1 - u0, height = v0 - v1 }
        end
        worldBoxes[continent] = box
    end
    return box or nil
end

-- The map of that kind under a point of a continent's plane, as the game's maps say: the continent
-- under it on the world map, or the zone under it on the continent's map. nil when none is.
local function At(map, x, y, kind)
    if not x or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    local info = Core.Ask(C_Map.GetMapInfoAtPosition, map, x, y)
    if type(info) == "table" and info.mapType == kind and info.mapID ~= map then return info.mapID end
    return nil
end

function Coords.ContinentAt(continent, u, v)
    local root = Coords.WorldMap()
    if not root then return nil end
    local x, y = Coords.ToWorldMap(continent, u, v)
    return At(root, x, y, Coords.CONTINENT)
end

function Coords.ZoneAt(continent, u, v)
    local box = Coords.Box(continent)
    if not box then return nil end
    local x, y = Coords.ToMap(box, u, v)
    return At(continent, x, y, Coords.ZONE)
end

-- A point of a map (0 to 1) in a continent's plane: the map's own box, linked to that continent. nil when
-- the map has no box or its continent is not linked.
function Coords.MapToPlane(map, x, y, continent)
    local box = Coords.Box(map)
    local home = box and Coords.ContinentOf(map)
    local link = home and Coords.Link(home, continent)
    if not link then return nil end
    local u, v = Coords.ToPlane(box, x, y)
    return link.du + link.su * u, link.dv + link.sv * v
end

-- Where the player is: the continent's map, and the point in its plane. Only the map when the game does
-- not tell the position there (an instance), nil when it tells nothing. Asked every frame while the view
-- follows: the boxes and the tree are kept, so it costs two questions to the game.
function Coords.Player()
    local map = Core.Ask(C_Map.GetBestMapForUnit, "player")
    if not map then return nil end
    local continent = Coords.ContinentOf(map)
    local position = Core.Ask(C_Map.GetPlayerMapPosition, map, "player")
    local box, home = Coords.Box(map), continent and Coords.Box(continent)
    if not position or not box or not home or box.continent ~= home.continent then return continent end
    local x, y = Core.Plain(position.x), Core.Plain(position.y)
    if not x or not y then return continent end
    return continent, Coords.ToPlane(box, x, y)
end
