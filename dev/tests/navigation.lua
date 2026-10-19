-- Runs the Navigation module against the stand-in client (wowstub.lua) on a small made-up world: the map's
-- spaces and the map tree, the camera's levels, what the game tells (Live), the map drawn each of the three
-- ways in both views, the mouse (drag, wheel, right click, Ctrl-click), the game's minimap taken over ours and
-- given back, the game's map kept closed and its keys. The look itself can only be judged in the game.
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

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1600, 900
Enum.UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4 }
function CreateVector2D(x, y)
    local vector = { x = x, y = y }
    function vector:SetXY(a, b) self.x, self.y = a, b end
    function vector:GetXY() return self.x, self.y end
    return vector
end
UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = CreateVector2D(x, y) } end }
function methods:GetLeft() return self._left or 0 end
function methods:GetBottom() return self._bottom or 0 end
function methods:GetCenter() return (self._width or 0) / 2, (self._height or 0) / 2 end
function methods:LockHighlight() self._lit = true end
function methods:UnlockHighlight() self._lit = false end
function methods:EnableMouse(on) self._mouse = on and true or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on and true or false end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetRotation(angle) self._rotation = angle end
function methods:GetChildren()
    local list = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == self and widget._kind ~= "Texture" and widget._kind ~= "FontString" then list[#list + 1] = widget end
    end
    return unpack(list)
end
-- An animation: the test moves its clock (as dev/tests/window.lua does).
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, progress = 0 }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress = true, 0 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha = noop
    function group:CreateAnimation()
        local animation = setmetatable({ SetSmoothing = noop, SetToAlpha = noop }, { __index = function() return noop end })
        function animation:SetDuration(seconds) group.duration = seconds end
        function animation:GetProgress() return group.progress end
        function animation:GetSmoothProgress() return group.progress end
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate and self.scripts.OnUpdate() end
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished() end
    end
    self._group = self._group or group
    return group
end
local cursorX, cursorY = 100, 100
GetCursorPosition = function() return cursorX, cursorY end
local ctrl = false
IsControlKeyDown = function() return ctrl end
IsIndoors = function() return false end
GetPlayerFacing = function() return 1.5 end
IsInRaid = function() return false end
GetNumSubgroupMembers = function() return 1 end
UnitIsUnit = function(a, b) return a == b end

-- The made-up world, in yards: each map's top (X at y = 0), bottom (X at y = 1), left (Y at x = 0) and
-- right (Y at x = 1) edge, as the game's world positions are: X to the north, Y to the west; a continent's
-- rectangle on the world map (x0, x1, y0, y1).
local MAPS = {
    [947] = { kind = 1, parent = 0 },
    [1415] = { kind = 2, parent = 947, continent = 0, top = 4000, bottom = -16000, left = 4000, right = -4000,
               world = { 0.62, 0.94, 0.18, 0.82 } },
    -- Twice as many yards in a rectangle as large: drawn at half the scale, alike both ways, as the game's are
    [1414] = { kind = 2, parent = 947, continent = 1, top = 20000, bottom = -20000, left = 12000, right = -12000,
               world = { 0.06, 0.54, 0.18, 0.82 } },
    [1429] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000 },
    [9999] = { kind = 3, parent = 1415, continent = 0, top = -8500, bottom = -10000, left = 1000, right = -1000, swapped = true },
    [500] = { kind = 4, parent = 1429 }, -- a dungeon: no box
}
local player = { map = 1429, x = 0.75, y = 0.3 }
local waypoint, tracked = nil, false
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
    GetMapRectOnMap = function(map, top)
        local rect = top == 947 and MAPS[map] and MAPS[map].world
        if rect then return rect[1], rect[2], rect[3], rect[4] end
    end,
    GetBestMapForUnit = function() return player.map end,
    GetPlayerMapPosition = function(map, unit)
        if unit == "party1" and map == 1429 then return CreateVector2D(0.5, 0.5) end
        if unit ~= "player" or map ~= player.map or not MAPS[map].top then return nil end
        return CreateVector2D(player.x, player.y)
    end,
    GetMapArtLayers = function(map)
        if not MAPS[map] or (not MAPS[map].top and map ~= 947) then return {} end
        return { { layerWidth = 1002, layerHeight = 668, tileWidth = 256, tileHeight = 256 } }
    end,
    GetMapArtLayerTextures = function(map)
        local files = {}
        for index = 1, 12 do files[index] = map * 100 + index end
        return files
    end,
    GetMapInfoAtPosition = function(map, x, y)
        -- Elwynn's box on the continent's map: x from 0.375 to 0.625, y from 0.625 to 0.7
        if map == 1415 and x >= 0.375 and x <= 0.625 and y >= 0.625 and y <= 0.7 then return { mapID = 1429, mapType = 3 } end
        if map == 947 then
            for _, id in ipairs({ 1415, 1414 }) do
                local r = MAPS[id].world
                if x >= r[1] and x <= r[2] and y >= r[3] and y <= r[4] then return { mapID = id, mapType = 2 } end
            end
        end
        return { mapID = map, mapType = MAPS[map].kind }
    end,
    HasUserWaypoint = function() return waypoint ~= nil end,
    GetUserWaypoint = function() return waypoint end,
    CanSetUserWaypointOnMap = function(map) return MAPS[map] and MAPS[map].kind == 3 or false end,
    SetUserWaypoint = function(point) waypoint = point end,
    ClearUserWaypoint = function() waypoint = nil end,
    GetUserWaypointHyperlink = function() return "|Hworldmap|h[Map Pin]|h" end,
}
C_SuperTrack = { IsSuperTrackingUserWaypoint = function() return tracked end,
                 SetSuperTrackedUserWaypoint = function(on) tracked = on end }
C_QuestLog = { GetQuestsOnMap = function(map) return map == 1429 and { { questID = 7, x = 0.4, y = 0.4 } } or nil end }
C_TaxiMap = { GetTaxiNodesForMap = function(map) return map == 1429 and { { nodeID = 2, name = "Goldshire" } } or {} end }
C_VignetteInfo = {
    GetVignettes = function() return { "v1", "v2" } end,
    GetVignetteInfo = function(guid) return guid == "v1" and { name = "A rare" } or nil end,
    GetVignettePosition = function(guid, map) return guid == "v1" and map == 1429 and CreateVector2D(0.6, 0.2) or nil end,
}
C_AreaPoiInfo = { GetAreaPOIForMap = function() return { 11 } end,
                  GetAreaPOIInfo = function(_, id) return { areaPoiID = id, name = "A point" } end }
local exploredParts = { { textureWidth = 300, textureHeight = 200, offsetX = 100, offsetY = 50, fileDataIDs = { 701, 702 } },
                        { textureWidth = 64, textureHeight = 64, offsetX = 0, offsetY = 0, fileDataIDs = { 703 }, isShownByMouseOver = true } }
C_MapExplorationInfo = { GetExploredMapTextures = function(map) return map == 1429 and exploredParts or {} end }

-- The game's minimap: its cluster (an Edit Mode system with a selection box), the container, the minimap with
-- its zoom buttons and border.
local radii = { [0] = 240, 200, 160, 120, 80, 50 }
local ground, ignoreRotation, configs = true, false, 0
local cluster = W.NewWidget("Frame", "MinimapCluster", UIParent)
cluster._mouse, cluster._alpha = true, 1
function cluster:UpdateMinimapConfig() configs = configs + 1 end
cluster.Selection = W.NewWidget("Frame", nil, cluster)
cluster.Selection._mouse = true
cluster.ZoneTextButton = W.NewWidget("Button", nil, cluster)
cluster.ZoneTextButton._mouse = true
local container = W.NewWidget("Frame", nil, cluster)
local minimap = W.NewWidget("Minimap", "Minimap", container)
minimap._zoom, minimap._wheel, minimap._mouse = 2, true, true
minimap:SetSize(198, 198)
minimap:SetPoint("CENTER", container, "CENTER", 0, 0)
function minimap:GetZoom() return self._zoom end
function minimap:SetZoom(step) self._zoom = step end
function minimap:GetZoomLevels() return 6 end
function minimap:SetMaskTexture(mask) self._mask = mask end
function minimap:SetPassThroughButtons(...) self._through = { ... } end
function minimap:PingLocation(x, y) self._ping = { x, y } end
minimap.ZoomIn = W.NewWidget("Button", nil, minimap)
minimap.ZoomIn._mouse = true
local backdrop = W.NewWidget("Frame", "MinimapBackdrop", minimap)
rawset(_G, "MinimapCluster", cluster)
rawset(_G, "Minimap", minimap)
rawset(_G, "MinimapBackdrop", backdrop)
C_Minimap = {
    GetViewRadius = function() return radii[minimap._zoom] end,
    SetDrawGroundTextures = function(on) ground = on end,
    SetIgnoreRotateMinimap = function(on) ignoreRotation = on end,
}

-- The game's map and its panel functions, and the key bindings.
local worldMap = W.NewWidget("Frame", "WorldMapFrame", UIParent)
worldMap:Hide()
worldMap._map = 1415
function worldMap:GetMapID() return self._map end
rawset(_G, "WorldMapFrame", worldMap)
local panels = { shown = 0, hidden = 0 }
local function Run(frame, script) if frame._scripts[script] then frame._scripts[script](frame) end end
ShowUIPanel = function(frame) panels.shown = panels.shown + 1; frame._shown = true; Run(frame, "OnShow") end
HideUIPanel = function(frame) panels.hidden = panels.hidden + 1; frame._shown = false; Run(frame, "OnHide") end
local KEYS = { TOGGLEWORLDMAP = { "M" }, TOGGLEQUESTLOG = { "L" }, TOGGLEMINIMAP = { "CTRL-R" } }
GetBindingKey = function(action) return unpack(KEYS[action] or {}) end
local overrides = {}
SetOverrideBindingClick = function(_, _, key, button, click) overrides[key] = button .. ":" .. click end
ClearOverrideBindings = function() overrides = {} end

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

-- The textures shown, by file.
local function Shown()
    local shown = {}
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._shown and widget._texture then shown[widget._texture] = widget end
    end
    return shown
end
local function Count(shown, low, high)
    local count = 0
    for file in pairs(shown) do if type(file) == "number" and file >= low and file <= high then count = count + 1 end end
    return count
end
local function Overviews(shown, continent)
    local count = 0
    for file in pairs(shown) do
        if type(file) == "string" and file:find("Art\\Terrain\\" .. continent .. "-", 1, true) then count = count + 1 end
    end
    return count
end

-------------------------------------------------------------------------------
--  Coords
-------------------------------------------------------------------------------
local Coords = ns.Coords
local box = Coords.Box(1429)
check(box and box.continent == 0 and box.u == -1000 and box.v == -8500 and box.width == 2000 and box.height == 1500,
    "a map's box in the plane: u = -Y of its left edge, v = X of its top, its size in yards")
local swapped = Coords.Box(9999)
check(swapped and swapped.u == box.u and swapped.v == box.v and swapped.width == box.width and swapped.height == box.height,
    "which of the game's two numbers is north is read from the map itself")
check(Coords.Box(500) == false and Coords.Box(947) == false, "a dungeon and the world map have no box")
local u, v = Coords.ToPlane(box, 0.75, 0.3)
check(near(u, 500) and near(v, -8950), "a map point in the plane: east is +u, north is +v")
local x, y = Coords.ToMap(box, u, v)
check(near(x, 0.75) and near(y, 0.3), "and back")
local column, row = Coords.Tile(u, v)
check(column == 32 and row == 48 and Coords.TileKey(0, column, row) == 3104 and Coords.TileKey(1, 32, 32) == 4096 + 2080,
    "the terrain tile under a point, and its key in the set Tiles")
local left, top = Coords.Corner(column, row)
check(left <= u and u < left + Coords.TILE and top >= v and v > top - Coords.TILE, "a tile's corner: the point lies in its square")
check(Coords.ContinentOf(1429) == 1415 and Coords.ContinentOf(1415) == 1415 and Coords.ContinentOf(947) == nil,
    "the continent a map lies on, by its parents")
local continents = Coords.Continents()
check(#continents == 2 and continents[1] == 1415 and continents[2] == 1414, "the continents, as the game lists them")
-- The world map: Eastern Kingdoms (8000 x 20000 yards) on its x 0.62 to 0.94, y 0.18 to 0.82
local whole = Coords.WorldBox(1415)
check(whole and near(whole.width, 8000 / 0.32) and near(whole.height, 20000 / 0.64) and near(whole.u, -4000 - 0.62 * 25000)
    and near(whole.v, 4000 + 0.18 * 31250), "the world map's box in a continent's plane, from that continent's rectangle on it")
local link = Coords.Link(1414, 1415)
local wx, wy = Coords.ToWorldMap(1414, -12000, 20000) -- Kalimdor's top left corner
local lu, lv = Coords.FromWorldMap(1415, wx, wy)
check(link and near(link.du + link.su * -12000, lu) and near(link.dv + link.sv * 20000, lv) and near(wx, 0.06) and near(wy, 0.18)
    and near(link.su, 0.5) and near(link.sv, 0.5), "one continent's plane in another's, through the world map")
check(Coords.Link(1415, 1415).su == 1 and Coords.Link(1415, 1415).du == 0, "a continent in its own plane: as it is")
check(Coords.ContinentAt(1415, lu + 10, lv - 10) == 1414 and Coords.ZoneAt(1415, 500, -8950) == 1429
    and Coords.ZoneAt(1415, 3000, 0) == nil, "the continent and the zone under a point, as the game's maps say")
local mu, mv = Coords.MapToPlane(1429, 0.75, 0.3, 1415)
check(near(mu, 500) and near(mv, -8950), "a point of a zone in its continent's plane")
local map, pu, pv = Coords.Player()
check(map == 1415 and near(pu, 500) and near(pv, -8950), "where the player is: the continent and the point in its plane")
player.map = 500
local inMap, inU = Coords.Player()
check(inMap == 1415 and inU == nil, "in a dungeon without a box: its continent, no point")
player.map = 1429

-------------------------------------------------------------------------------
--  Camera
-------------------------------------------------------------------------------
local Camera = ns.Camera
local camera = Camera.New()
camera.width, camera.height = 1600, 900
check(camera:Show(1415, 500, -8950), "a camera looks at a continent")
check(near(camera.k, 900 / Camera.START) and camera.level == "zone", "about a zone high, the first time: the zone's level")
check(near(camera.fit, math.min(1600 / 8000, 900 / 20000) * Camera.FIT) and near(camera.far, math.min(1600 / whole.width, 900 / whole.height) * Camera.FIT),
    "it fits the continent, and farther out the world")
local mouseX, mouseY = 200, -100
camera.follow = false
local aimU, aimV = camera.u + mouseX / camera.k, camera.v + mouseY / camera.k
camera:ZoomAt(2, mouseX, mouseY)
check(near(camera.u + mouseX / camera.k, aimU) and near(camera.v + mouseY / camera.k, aimV),
    "the wheel zooms around the point under the mouse: it stays where it is")
camera.follow = true
local middleU = camera.u
camera:ZoomAt(1, mouseX, mouseY)
check(camera.u == middleU, "a view that follows the player zooms around its middle")
camera:ZoomAt(100, 0, 0)
check(camera.k == Camera.NEAR, "no nearer than its own nearest zoom")
camera:ZoomAt(-100, 0, 0)
check(camera.k == camera.far and camera.level == "world", "out to the whole world")
camera:Look(camera.u, camera.v, camera.fit * 0.9)
check(camera.level == "world", "the world is left only past the continent's fit: some slack")
camera:Look(500, -8950, camera.fit * 1.01)
check(camera.level == "continent" and camera.map == 1415, "in again over the same continent: its level")
check(camera:StepOut() and camera.level == "world", "right click on a continent: the world whole")
-- Over Kalimdor on the world map, zoomed in: the camera moves into Kalimdor's plane, the same on the screen.
camera:Look(lu + 2000 * link.su, lv - 2000 * link.sv)
local screenK = camera.fit * 1.2
camera:Look(camera.u, camera.v, screenK)
check(camera.map == 1414 and camera.level ~= "world" and near(camera.k, screenK * link.su),
    "in again over another continent: its plane, at the same size on the screen")
camera:Show(1415, 500, -8950, 0.4)
check(camera.level == "zone" and camera:StepOut() and camera.level == "continent" and near(camera.k, camera.fit),
    "right click in a zone: its continent whole")
check(camera:Fit(1429) and camera.level == "zone" and not camera.follow, "a map fitted into the view: a zone")
check(camera:Fit(947) and camera.level == "world", "and the world")
camera:Show(1415, 0, -5000, 0.5)
camera:Pan(50, -100)
check(near(camera.u, -100) and near(camera.v, -4800) and not camera.follow, "a drag moves the middle against the mouse and stops following")
camera:Pan(-1e6, 0)
check(camera.u == camera.box.u + camera.box.width, "the middle stays on the continent")

-------------------------------------------------------------------------------
--  Live
-------------------------------------------------------------------------------
local Live = ns.Live
local lmap, lu2, _, facing = Live.Player()
check(lmap == 1415 and near(lu2, 500) and facing == 1.5, "Live: the player, with the facing")
check(#Live.Group(1429) == 1 and Live.Group(1429)[1].unit == "party1", "Live: the party on a map")
check(Live.Quests(1429)[1].questID == 7 and #Live.Quests(1415) == 0, "Live: the quests on a map")
check(Live.Flights(1429)[1].name == "Goldshire", "Live: the flight points")
check(#Live.Vignettes(1429) == 1 and Live.Vignettes(1429)[1].info.name == "A rare", "Live: rares nearby, where the game places them")
check(Live.Points(1429)[1].name == "A point", "Live: the game's own points")
check(#Live.Explored(1429) == 2 and #Live.Explored(1415) == 0, "Live: the explored parts")
local told = {}
ns.Listen("LIVE", function(what) told[#told + 1] = what end)
W.Fire("QUEST_LOG_UPDATE")
W.Fire("QUEST_POI_UPDATE")
W.Fire("QUEST_LOG_UPDATE")
check(#told == 0, "a burst of the game's events: nothing at once")
W.Wait(0)
check(#told == 1 and told[1] == "quests", "and one message on the next frame")

-------------------------------------------------------------------------------
--  The window, the minimap taken
-------------------------------------------------------------------------------
local Window, Canvas, Hybrid = ns.Window, ns.Canvas, ns.Hybrid
check(Window.frame and Canvas.frame and Window.frame:GetFrameStrata() == "LOW", "built at login, in the game's minimap's layer")
check(Hybrid.Taken() and minimap:GetParent() == Canvas.frame and minimap._mask == Hybrid.MASK and not minimap._wheel,
    "the game's minimap is over our map, square, its wheel ours")
check(minimap._through and minimap._through[1] == "LeftButton" and minimap._through[2] == "RightButton",
    "its left and right clicks go through to our map")
check(ground == false and ignoreRotation == true and backdrop._alpha == 0 and minimap.ZoomIn._alpha == 0 and not minimap.ZoomIn._mouse,
    "its ground off, its rotation ignored, its border and zoom buttons out of sight")
check(cluster._alpha == 0 and not cluster._mouse and not cluster.ZoneTextButton._mouse and cluster.Selection._mouse,
    "the rest of the game's minimap out of sight and without clicks, but Edit Mode's selection")
check(minimap._zoom == 2 and Window.small.native == 2, "the small view starts at the step the player had")
radii[0] = 250
W.Fire("PLAYER_ENTERING_WORLD")
check(near(Hybrid.Zoom(0, 200), 100 / 250) and minimap._zoom == 2, "after a loading screen its steps are measured again, its step as it was")
radii[0] = 240
W.Fire("PLAYER_ENTERING_WORLD")

-- The terrain's data arrives after the loading screen.
local Tiles = Core.Data.Set("Tiles")
W.Fire("LOADING_SCREEN_DISABLED")
local steps = Core.Steps.frame
for _ = 1, 4 do
    W.Wait(0)
    if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
end
os.execute(("rm -rf '%s'"):format(folder))
check(#W.fileErrors == 0, "the pack's file ran" .. (W.fileErrors[1] and ": " .. W.fileErrors[1] or ""))
check(Tiles:Ready() and Tiles:Get(3104, "minimap") == 801, "the pack is loaded: the set Tiles answers")

-- Small: 200 x 200, following the player at the game's step 2 (radius 160 yards).
local frame = Canvas.frame
frame._width, frame._height = 200, 200
Canvas.Use(Window.small)
Canvas.Open()
local small = Window.small
local tracker
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget._scripts.OnUpdate then tracker = widget end
end
check(tracker, "the tracker runs while the window shows")
tracker._scripts.OnUpdate(tracker, 0.016)
check(near(small.u, 500) and near(small.v, -8950) and near(small.k, 100 / 160), "the small view follows the player, at the step's zoom")
check(minimap._shown and minimap._width == 200 and minimap._zoom == 2, "the game's minimap shows in its middle, as large as the view")
local shown = Shown()
local arrow
for _, widget in ipairs(W.frames) do if widget._atlas == "UI-WorldMapArrow" then arrow = widget end end
check(arrow and not arrow._shown, "our arrow is out of sight while the game's minimap shows its own")
check(Count(shown, 801, 804) > 0 and Overviews(shown, 0) > 0, "the overlay under it: the terrain's tiles over its overview")

-- The wheel walks the game's steps, then our map goes on alone.
frame._scripts.OnMouseWheel(frame, 1)
check(small.native == 3 and near(small.k, 100 / 120) and minimap._zoom == 3, "a notch in: the game's next step")
frame._scripts.OnMouseWheel(frame, -1)
frame._scripts.OnMouseWheel(frame, -1)
frame._scripts.OnMouseWheel(frame, -1)
check(small.native == 0 and near(small.k, 100 / 240), "out to the game's widest step")
frame._scripts.OnMouseWheel(frame, -1)
check(small.native == nil and near(small.k, 100 / 240 / Camera.STEP) and not minimap._shown,
    "out past it: our map alone, a notch farther, the game's minimap out of sight")
tracker._scripts.OnUpdate(tracker, 0.016)
check(arrow._shown and arrow._rotation == 1.5, "our arrow shows instead, turned as the player faces")
frame._scripts.OnMouseWheel(frame, 1)
check(small.native == 0 and minimap._shown, "in again: the game's widest step, its minimap back")

-- A drag: no longer following, the game's minimap goes; it follows again after a while without the mouse.
frame._scripts.OnMouseDown(frame, "LeftButton")
cursorX = cursorX + 30
frame._scripts.OnUpdate(frame, 0.016)
check(not small.follow and not minimap._shown and near(small.u, 500 - 30 / small.k), "a drag: the map moves, it no longer follows")
frame._scripts.OnMouseUp(frame, "LeftButton")
check(not frame._scripts.OnUpdate, "the button up: nothing runs any more")
W.Wait(ns.options.followAgain + 1)
frame._mouseOver = true
tracker._scripts.OnUpdate(tracker, 0.016)
check(not small.follow, "not while the mouse is on the map")
frame._mouseOver = false
W.Wait(0.2)
tracker._scripts.OnUpdate(tracker, 0.016)
tracker._scripts.OnUpdate(tracker, 0.016)
check(small.follow and near(small.u, 500) and minimap._shown, "then it follows again, the game's minimap with it")

-- A plain click on the game's minimap pings; Ctrl and a click puts the map pin there.
cursorX, cursorY = 120, 110
frame._scripts.OnMouseDown(frame, "LeftButton")
frame._scripts.OnMouseUp(frame, "LeftButton")
check(minimap._ping and minimap._ping[1] == 20 and minimap._ping[2] == 10, "a click: the game's ping, where it was clicked")
ctrl = true
cursorX, cursorY = 100, 100
frame._scripts.OnMouseDown(frame, "LeftButton")
frame._scripts.OnMouseUp(frame, "LeftButton")
ctrl = false
check(waypoint and waypoint.uiMapID == 1429 and near(waypoint.position.x, 0.75) and near(waypoint.position.y, 0.3) and not tracked,
    "Ctrl-click: the game's map pin on the zone there, not yet followed, as the game's map does")
W.Fire("USER_WAYPOINT_UPDATED")
W.Wait(0)
local pin
for _, widget in ipairs(W.frames) do if widget._kind == "Button" and widget.icon then pin = widget end end
check(pin and pin._shown and pin.icon._atlas == "Waypoint-MapPin-Untracked", "the pin shows, as the game's")
pin._scripts.OnClick(pin, "LeftButton")
check(tracked, "a click on it: the game's arrow leads there")
ctrl = true
pin._scripts.OnClick(pin, "LeftButton")
ctrl = false
check(waypoint == nil, "Ctrl-click on it: gone")

-- Right click: one map out.
small:Show(1415, 500, -8950, 0.5)
small.native = nil
Canvas.Layout()
check(small.level == "zone", "close in: the zone's level")
frame._scripts.OnMouseDown(frame, "RightButton")
frame._scripts.OnMouseUp(frame, "RightButton")
check(small.level == "continent" and near(small.k, small.fit), "right click: its continent whole")

-------------------------------------------------------------------------------
--  The full screen: the same map, its own camera; the views at every zoom
-------------------------------------------------------------------------------
Window.Toggle()
local clock = Window.frame._group
check(clock and clock.playing, "the map key fills the screen")
frame._width, frame._height = 1600, 868
clock:Run(1)
local full = Window.full
check(Canvas.camera == full and near(full.u, 500) and near(full.k, 868 / Camera.START), "full: its own camera, at the player the first time")
local bar
for _, widget in ipairs(W.frames) do if widget.key == "overlay" then bar = widget._parent end end
check(bar and bar._shown, "full: the view buttons")
shown = Shown()
check(Count(shown, 801, 804) == 4 and Count(shown, 142901, 142912) > 0 and Count(shown, 141501, 141512) == 0,
    "the overlay up close: the tiles, the zone's map alone over them")
local function Button(key)
    for _, widget in ipairs(W.frames) do if widget.key == key and widget._scripts.OnClick then return widget end end
end
check(Button("overlay")._lit and not Button("terrain")._lit, "the view chosen is lit")
Button("blizzard")._scripts.OnClick(Button("blizzard"))
shown = Shown()
check(ns.options.view == "blizzard" and Button("blizzard")._lit and Count(shown, 801, 804) == 0
    and Count(shown, 141501, 141512) > 0 and Count(shown, 142901, 142912) > 0, "Blizzard maps: the continent's art, the zone's over it")
check(shown[701] and shown[702] and not shown[703], "and what was explored of the zone, but what shows only under the mouse")
-- Out to the world: every view stays as chosen.
full:Fit(947)
Canvas.Layout()
shown = Shown()
check(Count(shown, 94701, 94712) > 0 and Count(shown, 801, 804) == 0, "Blizzard maps at the world: the world map")
Button("terrain")._scripts.OnClick(Button("terrain"))
shown = Shown()
check(Overviews(shown, 0) > 0 and Overviews(shown, 1) > 0 and Count(shown, 94701, 94712) == 0,
    "Terrain at the world: every continent's overview, no art")
Button("overlay")._scripts.OnClick(Button("overlay"))
shown = Shown()
check(Overviews(shown, 0) > 0 and Count(shown, 94701, 94712) > 0, "Overlay at the world: both")
local tilesBefore = ns.Terrain.CAP
full:Show(1415, 500, -8950, 0.3)
ns.Terrain.CAP = 2
Canvas.Layout()
shown = Shown()
check(Count(shown, 801, 804) == 0 and Overviews(shown, 0) > 0, "too many tiles in view: the overview alone, still terrain")
ns.Terrain.CAP = tilesBefore

-- Back to the corner: the small view as it was left.
Window.Toggle()
frame._width, frame._height = 200, 200
Window.frame._group:Run(1)
check(Canvas.camera == small and small.level == "continent", "back small: its own camera, where it was")

-------------------------------------------------------------------------------
--  The game's map and keys
-------------------------------------------------------------------------------
check(overrides.M == "SaneUINavigationKey:map" and overrides.L == "SaneUINavigationKey:quests"
    and overrides["CTRL-R"] == "SaneUINavigationKey:minimap", "the game's map, quest log and minimap keys open ours")
local key = rawget(_G, "SaneUINavigationKey")
key._scripts.OnClick(key, "minimap", true)
key._scripts.OnClick(key, "minimap", false)
check(not Window.frame._shown, "the minimap key hides our window (its release does nothing more)")
key._scripts.OnClick(key, "minimap", true)
check(Window.frame._shown, "and shows it again")
-- Another way to the game's map: closed on the next frame, ours opened at its map.
worldMap._map = 1429
ShowUIPanel(worldMap)
check(worldMap._shown and worldMap._alpha == 0, "the game's map shows: out of sight at once")
W.Wait(0)
check(not worldMap._shown and worldMap._alpha == 1 and panels.hidden == 1, "on the next frame: closed by the game's panel function")
check(full.level == "zone" and near(full.u, 0) and Window.frame._group.playing, "ours opens, at the zone it was asked for")
Window.frame._group:Run(1)
-- In a fight the game's map stays.
W.combat = true
ShowUIPanel(worldMap)
W.Wait(0)
check(worldMap._shown and worldMap._alpha == 1, "in a fight: the game's map stays open, as the game's")
W.combat = false
HideUIPanel(worldMap)
-- The switch Show the game's map: no longer caught, its keys the game's.
Core.Set(ns.name, "nativeMap", true)
check(overrides.M == nil and overrides["CTRL-R"], "Show the game's map: its keys are the game's again")
ShowUIPanel(worldMap)
W.Wait(0)
check(worldMap._shown, "and it opens as the game's")
HideUIPanel(worldMap)
Core.Set(ns.name, "nativeMap", false)

-- The switch Show the game's minimap: given back, exactly.
Core.Set(ns.name, "nativeMinimap", true)
check(not Hybrid.Taken() and minimap:GetParent() == container and minimap._wheel and #minimap._through == 0
    and ground == true and ignoreRotation == false and configs > 0, "Show the game's minimap: its place, wheel, clicks, ground, rotation and mask back")
check(cluster._alpha == 1 and cluster._mouse and cluster.ZoneTextButton._mouse and backdrop._alpha == 1 and minimap.ZoomIn._mouse,
    "its cluster, border and buttons back")
check(overrides["CTRL-R"] == nil, "and its key")
Core.Set(ns.name, "nativeMinimap", false)
check(Hybrid.Taken(), "off again: taken again")

-- A failure stands the module down: everything given back.
ns.StandDown("a test")
check(ns.off and not Window.frame:IsShown() and not Hybrid.Taken() and next(overrides) == nil and minimap:GetParent() == container,
    "standing down: the window goes, the game's minimap and keys are back")

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Navigation: all %d checks passed.\n"):format(passed))
