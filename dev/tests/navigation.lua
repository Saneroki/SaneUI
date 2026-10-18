-- Runs the Navigation module against the stand-in client (wowstub.lua) on a small made-up world: the map's
-- spaces (map, world, plane) and the terrain's grid, the camera's drag and zoom, and the map drawn from a
-- small Tiles pack and the game's map art, each of the three ways. The look itself can only be judged in
-- the game.
-- Usage, from the project folder:  lua5.1 dev/tests/navigation.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-- What the module needs of the client ------------------------------------------------------
Enum.UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4 }
local vectors = {}
function CreateVector2D(x, y)
    local vector = { x = x, y = y }
    function vector:SetXY(a, b) self.x, self.y = a, b end
    function vector:GetXY() return self.x, self.y end
    vectors[#vectors + 1] = vector
    return vector
end
function W.methods:GetCenter() return 800, 450 end
function W.methods:LockHighlight() self._lit = true end
function W.methods:UnlockHighlight() self._lit = false end
local cursorX, cursorY = 800, 450
GetCursorPosition = function() return cursorX, cursorY end

-- The made-up world, in yards: each map's top (X at y = 0), bottom (X at y = 1), left (Y at x = 0) and
-- right (Y at x = 1) edge, as the game's world positions are: X to the north, Y to the west.
local MAPS = {
    [947] = { kind = 1, parent = 0 },
    [1415] = { kind = 2, parent = 947, continent = 0, top = 4000, bottom = -16000, left = 4000, right = -4000 },
    [1414] = { kind = 2, parent = 947, continent = 1, top = 10000, bottom = -10000, left = 6000, right = -6000 },
    [1429] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000 },
    [9999] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000, swapped = true },
    [500] = { kind = 4, parent = 1429 }, -- a dungeon: no box
}
local player = { map = 1429, x = 0.75, y = 0.3 }
C_Map = {
    GetWorldPosFromMapPos = function(map, position)
        local info = MAPS[map]
        if not info or not info.top then return nil end
        local north = info.top + position.y * (info.bottom - info.top)
        local west = info.left + position.x * (info.right - info.left)
        -- The game's vector: x is north, y is west; map 9999 says it the other way round.
        if info.swapped then return info.continent, CreateVector2D(west, north) end
        return info.continent, CreateVector2D(north, west)
    end,
    GetMapInfo = function(map)
        local info = MAPS[map]
        return info and { mapID = map, mapType = info.kind, parentMapID = info.parent } or nil
    end,
    GetFallbackWorldMapID = function() return 947 end,
    GetMapChildrenInfo = function(map, kind)
        local list = {}
        for _, id in ipairs({ 1415, 1414, 1429 }) do
            if MAPS[id].parent == map and (not kind or MAPS[id].kind == kind) then list[#list + 1] = { mapID = id, mapType = MAPS[id].kind } end
        end
        return list
    end,
    GetBestMapForUnit = function() return player.map end,
    GetPlayerMapPosition = function(map)
        if map ~= player.map or not MAPS[map].top then return nil end
        return CreateVector2D(player.x, player.y)
    end,
    GetMapArtLayers = function(map)
        if not MAPS[map] or not MAPS[map].top then return {} end
        return { { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 } }
    end,
    GetMapArtLayerTextures = function(map)
        local files = {}
        for index = 1, 12 do files[index] = map * 100 + index end
        return files
    end,
    -- Elwynn's box on the continent's map: x from 0.375 to 0.625, y from 0.625 to 0.7
    GetMapInfoAtPosition = function(map, x, y)
        if map == 1415 and x >= 0.375 and x <= 0.625 and y >= 0.625 and y <= 0.7 then return { mapID = 1429, mapType = 3 } end
        return { mapID = map, mapType = MAPS[map].kind }
    end,
}

-- The terrain's data: a pack with four tiles round the player, and one on the other continent.
local folder = io.popen("mktemp -d -t saneui-navigation-XXXXXX"):read("*l")
local packPath = folder .. "/SaneUI_Data_World"
os.execute(("mkdir -p '%s'"):format(packPath))
local TILES = { [3104] = 801, [3105] = 802, [3168] = 803, [3169] = 804, [4096 + 2080] = 900 }
local rows = {}
for key, file in pairs(TILES) do rows[#rows + 1] = ("R[%d] = \"70245\\t\\t%d\""):format(key, file) end
table.sort(rows)
local out = assert(io.open(packPath .. "/Tiles.lua", "w"))
out:write('local S = SaneUI.Core.Data.Add(1, "Tiles", { game = "forever", hash = "00000001", build = 70245, key = "int", fields = { "minimap" }, types = { "int" }, patches = {} })\n'
    .. "if not S then return end\nlocal R = S.rows\n" .. table.concat(rows, "\n") .. "\n")
out:close()
out = assert(io.open(packPath .. "/SaneUI_Data_World.toc", "w"))
out:write("## Title: Data: World\n## LoadOnDemand: 1\n## X-SaneUI-Sets: Tiles\n## X-SaneUI-Format: 1\n## X-SaneUI-Game: forever\nTiles.lua\n")
out:close()
W.AddPack(packPath)

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Navigation", "SaneUI_Navigation")
W.Fire("ADDON_LOADED", "SaneUI_Navigation")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Navigation == ns and not ns.off, "the module is made and started")

-- Coords -------------------------------------------------------------------------------------
local Coords = ns.Coords
local box = Coords.Box(1429)
check(box and box.continent == 0 and box.u == -1000 and box.v == -8500 and box.width == 2000 and box.height == 1500,
    "a map's box in the plane: u = -Y of its left edge, v = X of its top, its size in yards")
local swapped = Coords.Box(9999)
check(swapped and swapped.u == box.u and swapped.v == box.v and swapped.width == box.width and swapped.height == box.height,
    "which of the game's two numbers is north is read from the map itself")
check(Coords.Box(500) == false and Coords.Box(500) == false, "a map without a world position has no box (asked once)")
local u, v = Coords.ToPlane(box, 0.75, 0.3)
check(near(u, 500) and near(v, -8950), "a map point in the plane: east is +u, north is +v")
local x, y = Coords.ToMap(box, u, v)
check(near(x, 0.75) and near(y, 0.3), "and back")
-- The world's X -8950, Y -500: column floor(32 + 500 / 533.3) = 32, row floor(32 + 8950 / 533.3) = 48
local column, row = Coords.Tile(u, v)
check(column == 32 and row == 48 and Coords.TileKey(0, column, row) == 3104 and Coords.TileKey(1, 32, 32) == 4096 + 2080,
    "the terrain tile under a point, and its key in the set Tiles")
local left, top = Coords.Corner(column, row)
check(left <= u and u < left + Coords.TILE and top >= v and v > top - Coords.TILE, "a tile's corner: the point lies in its square")
check(Coords.ContinentOf(1429) == 1415 and Coords.ContinentOf(1415) == 1415 and Coords.ContinentOf(947) == nil,
    "the continent a map lies on, by its parents")
local continents = Coords.Continents()
check(#continents == 2 and continents[1] == 1415 and continents[2] == 1414, "the continents, as the game lists them")
local map, pu, pv = Coords.Player()
check(map == 1415 and near(pu, 500) and near(pv, -8950), "where the player is: the continent and the point in its plane")
player.map = 500
check(Coords.Player() == 1415 and select(2, Coords.Player()) == nil, "in a dungeon: only the continent, no point")
player.map = 1429

-- Camera -------------------------------------------------------------------------------------
local Camera = ns.Camera
local camera = Camera.New()
local continent = Coords.Box(1415)
camera:Frame(continent, 1600, 900)
check(near(camera.far, math.min(1600 / 8000, 900 / 20000) * Camera.FIT), "the farthest zoom shows the whole continent")
camera:Look(500, -8950, 0.3)
local mouseX, mouseY = 200, -100
local aimU, aimV = camera.u + mouseX / camera.k, camera.v + mouseY / camera.k
camera:ZoomAt(2, mouseX, mouseY)
check(near(camera.k, 0.3 * Camera.STEP ^ 2) and near(camera.u + mouseX / camera.k, aimU) and near(camera.v + mouseY / camera.k, aimV),
    "the wheel zooms around the point under the mouse: it stays where it is")
camera:ZoomAt(100, 0, 0)
check(camera.k == Camera.NEAR, "no nearer than the nearest zoom")
camera:ZoomAt(-100, 0, 0)
check(camera.k == camera.far, "no farther than the whole continent")
camera:Look(0, -5000, 0.5)
camera:Pan(50, -100)
check(near(camera.u, -100) and near(camera.v, -4800), "a drag right and down moves the middle left and up: the map follows the mouse")
camera:Pan(1e6, 0)
check(camera.u == continent.u, "the middle stays on the continent")
local l, r, t, b = camera:View(0)
check(near(r - l, 1600 / camera.k) and near(t - b, 900 / camera.k), "what is in view, in yards")

-- The window and the map ---------------------------------------------------------------------
local Window, Canvas = ns.Window, ns.Canvas
check(Window.frame and Canvas.frame and not Canvas.frame:GetParent():IsShown(), "built at login, docked; small, it shows nothing")
local Tiles = Core.Data.Set("Tiles")
check(Tiles:State() == "loading", "the terrain's data is asked for at login")
-- The loading screen goes: the scheduler loads the pack, its listeners are told on the frame after.
W.Fire("LOADING_SCREEN_DISABLED")
local steps = Core.Steps.frame
for _ = 1, 4 do
    W.Wait(0)
    if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
end
os.execute(("rm -rf '%s'"):format(folder))
check(#W.fileErrors == 0, "the pack's file ran" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))
check(Tiles:Ready() and Tiles:Get(3104, "minimap") == 801, "the pack is loaded: the set Tiles answers")

-- The textures shown, by file.
local function Shown()
    local shown = {}
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._shown and type(widget._texture) == "number" then shown[widget._texture] = widget end
    end
    return shown
end
local function Count(shown, low, high)
    local count = 0
    for file in pairs(shown) do if file >= low and file <= high then count = count + 1 end end
    return count
end

-- The window fills the screen: the canvas has its size, and opens at the player.
Canvas.frame._width, Canvas.frame._height = 1600, 900
Canvas.Open()
camera = Canvas.camera
check(camera.map == 1415 and near(camera.u, 500) and near(camera.v, -8950) and near(camera.k, 900 / Camera.START),
    "it opens at the player, on the player's continent, about a zone high")
check(ns.options.view == "overlay", "the overlay is the view at first")
local shown = Shown()
check(Count(shown, 801, 804) == 4 and not shown[900], "the overlay: the four terrain tiles of this continent in view, none of the other's")
local tile = shown[801]
local point = tile._points[1]
-- Tile 3104 is column 32, row 48: its corner u = 0, v = (32 - 48) * 533.3; the origin is the player
check(point[1] == "TOPLEFT" and point[3] == "CENTER" and near(point[4], (0 - 500) * camera.k)
    and near(point[5], (16 * -Coords.TILE + 8950) * camera.k), "a tile stands at (its corner - the origin) times the zoom")
check(near(tile._width, Coords.TILE * camera.k + Canvas.OVERLAP), "as large as its square, and a little more: no seam")
check(Count(shown, 142901, 142912) > 0 and Count(shown, 141501, 141512) == 0,
    "up close, the zone's own map over the terrain, alone: the continent's does not show through it")
local art -- any texture of the art: its layer's opacity
for file, texture in pairs(shown) do if file > 100000 then art = texture end end
check(art._parent._alpha == ns.Art.HALF, "half see-through over the terrain")

-- The view buttons: Blizzard maps
local function Button(key)
    for _, widget in ipairs(W.frames) do
        if widget.key == key and widget._scripts.OnClick then return widget end
    end
end
check(Button("overlay")._lit and not Button("terrain")._lit, "the view chosen is lit")
Button("blizzard")._scripts.OnClick(Button("blizzard"))
shown = Shown()
check(ns.options.view == "blizzard" and Button("blizzard")._lit and not Button("overlay")._lit, "a click chooses the view: kept in the settings")
check(Count(shown, 801, 804) == 0 and Count(shown, 141501, 141512) > 0 and Count(shown, 142901, 142912) > 0 and art._parent._alpha == 1,
    "Blizzard maps: no terrain; the continent's art with the zone's over it, opaque")
Button("terrain")._scripts.OnClick(Button("terrain"))
shown = Shown()
check(Count(shown, 801, 804) == 4 and Count(shown, 141501, 142912) == 0, "Terrain: the tiles alone")

-- A drag moves the holder only; past the margin, a layout.
local before = shown[801]._points[1][4]
Canvas.frame._scripts.OnMouseDown(Canvas.frame, "LeftButton")
check(Canvas.frame._scripts.OnUpdate, "the left button down: a step each frame while it drags")
cursorX = cursorX + 40
Canvas.frame._scripts.OnUpdate(Canvas.frame, 0.016)
local holder = shown[801]._points[1][2]
local last = holder._points[#holder._points]
check(near(camera.u, 500 - 40 / camera.k) and shown[801]._points[1][4] == before and near(last[4], 40) and near(last[5], 0),
    "a drag moves the holder, nothing else")
cursorX = cursorX + 1000
Canvas.frame._scripts.OnUpdate(Canvas.frame, 0.016)
check(Canvas.view.u == camera.u, "past the margin: laid out anew around the new middle")
Canvas.frame._scripts.OnMouseUp(Canvas.frame, "LeftButton")
check(not Canvas.frame._scripts.OnUpdate, "the button up: nothing runs any more")

-- The wheel zooms around the mouse; far out the terrain gives way to the art.
cursorX, cursorY = 800, 450
local k = camera.k
Canvas.frame._scripts.OnMouseWheel(Canvas.frame, 1)
check(near(camera.k, k * Camera.STEP) and Canvas.view.k == camera.k, "a notch of the wheel: nearer, laid out anew")
camera:Look(500, -8950)
Canvas.Layout()
check(Count(Shown(), 801, 804) == 4, "back at the player: the four tiles")
local tilesBefore = ns.Terrain.CAP
ns.Terrain.CAP = 2
Canvas.Refresh()
shown = Shown()
check(Count(shown, 801, 804) == 0 and Count(shown, 141501, 142912) > 0, "too many tiles in view: the art carries the view")
ns.Terrain.CAP = tilesBefore

-- Small again: every texture let go.
Canvas.Close()
shown = Shown()
check(Count(shown, 801, 804) == 0 and Count(shown, 141501, 142912) == 0, "small again: nothing drawn, the files let go")

-- A failure stands the module down: the window goes.
ns.StandDown("a test")
check(ns.off and not Window.frame:IsShown(), "standing down, the map window goes")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Navigation: all %d checks passed.\n"):format(passed))
