local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Coords
--  The spaces the map is drawn in, and the one place that turns one into
--  another. Knows no frames.
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

local boxes = {} -- [uiMapID] = its box, or false: asked once a session
local probe      -- the one vector every question to the game is put in

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

-- The continent a map lies on: itself, or the first of its parents that is one; nil when none is.
function Coords.ContinentOf(map)
    local seen = 0
    while map and map > 0 and seen < 10 do
        local info = Core.Ask(C_Map.GetMapInfo, map)
        if type(info) ~= "table" then return nil end
        if info.mapType == Coords.CONTINENT then return map end
        map, seen = info.parentMapID, seen + 1
    end
    return nil
end

-- The world's continents that have a box, as the game lists them (none known in advance).
function Coords.Continents()
    local list = {}
    local world = Core.Ask(C_Map.GetFallbackWorldMapID)
    local children = world and Core.Ask(C_Map.GetMapChildrenInfo, world, Coords.CONTINENT)
    for _, info in ipairs(type(children) == "table" and children or {}) do
        if info.mapID and Coords.Box(info.mapID) then list[#list + 1] = info.mapID end
    end
    return list
end

-- Where the player is: the continent's map, and the point in its plane. Only the map when the game does
-- not tell the position there (an instance), nil when it tells nothing.
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
