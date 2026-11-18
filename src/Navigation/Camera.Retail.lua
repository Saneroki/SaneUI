local _, ns = ...
if not SaneUI.Core.RETAIL then return end

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Camera.Retail
--  Retail's map is the game's own map tree, one map at a time (Saneroki,
--  2026-10-25), where WoW: Forever's is one world to roam with our own tiles:
--  the map shown (camera.shown) fills the view whole; the wheel zooms in on it
--  up to the largest scale of its art (as near as the game's own map comes, or
--  Camera.DEEP units to a pixel of its art), out to it whole again; a click goes
--  into the map under the mouse, a right click up to the map over it: a zone,
--  its continent, Azeroth, the Cosmic map of every world (Canvas.lua). Its
--  middle stays on the map. Following the player, it shows the map the game
--  says the player is on (Camera.Wanted). The art's layer follows the zoom
--  (camera.layer, Art.lua), as the game's own map picks it.
--
--  The spaces stay WoW: Forever's (Coords.lua): the map shown lies in its
--  plane, in yards, so the pins, the party, the route and the game's minimap
--  stand where they stand in both games. Two answers of the map tree differ:
--      Coords.PlaneOf  a map whose box lies in another instance than its
--                      continent's (a battleground, a dungeon's floor, an isle of
--                      its own) is a plane of its own, shown alone
--      Coords.Box      the top of the tree, which has no place in any world (the
--                      Cosmic map), is a sheet of its own, as large as Coords.SHEET
--                      and of its art's shape
--  Every other part of the camera is WoW: Forever's (Camera.lua), its methods
--  the ones these do not replace.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Camera = ns.Coords, ns.Camera

Camera.DEEP = 4       -- the nearest zoom at least: so many of the view's units to one pixel of the map's art
Coords.SHEET = 100000 -- the Cosmic map's width in yards of its own: a size to zoom on, no place in any world

-------------------------------------------------------------------------------
--  The map tree, as Retail has it
-------------------------------------------------------------------------------
local Box, PlaneOf = Coords.Box, Coords.PlaneOf -- WoW: Forever's answers, which these build on
local sheets, planes = {}, {} -- [uiMapID] = its sheet, its plane; or false: asked once a session
local top                     -- the top of the tree, asked once

function Coords.Box(map)
    local box = Box(map)
    if box or not map or map == Coords.WorldMap() then return box end
    top = top or Coords.Top()
    if map ~= top then return box end
    local sheet = sheets[map]
    if sheet == nil then
        local art = ns.Art.Of(map)
        sheet = art and { continent = -1, u = 0, v = 0, width = Coords.SHEET, height = Coords.SHEET * art.height / art.width }
            or false
        sheets[map] = sheet
    end
    return sheet
end

function Coords.PlaneOf(map)
    if not map then return nil end
    local found = planes[map]
    if found ~= nil then return found or nil end
    found = PlaneOf(map) or false
    local box = Box(map)
    local home = found and Box(found)
    if box and not (home and home.continent == box.continent) then found = map end
    if not found and Coords.Box(map) then found = map end -- the sheet
    planes[map] = found
    return found or nil
end

-------------------------------------------------------------------------------
--  The camera: one map at a time
-------------------------------------------------------------------------------
local LEVELS = { [Coords.COSMIC] = "world", [Coords.WORLD] = "world", [Coords.CONTINENT] = "continent" }
local NONE = {}
local single = setmetatable({}, { __index = Camera.methods })

local function Info(map)
    local info = map and Core.Ask(C_Map.GetMapInfo, map)
    return type(info) == "table" and info or nil
end

-- A map's box in a plane: its own where it lies there; Azeroth's (the world map) linked into a continent's plane on
-- it (Coords.WorldBox). nil where it has none there.
local function BoxIn(map, plane)
    if not plane then return nil end
    if map == Coords.WorldMap() then return Coords.WorldBox(plane) end
    if Coords.PlaneOf(map) ~= plane then return nil end
    return Coords.Box(map) or nil
end

-- The plane a map is shown in: its own; Azeroth in a continent's on it: the view's own if it lies on Azeroth, else
-- the player's, else the first continent's. nil where none.
local function PlaneFor(map, current)
    if map ~= Coords.WorldMap() then return Coords.PlaneOf(map) end
    local player = ns.Live.Player()
    for _, plane in ipairs({ current or false, player or false, Coords.Continents()[1] or false }) do
        if plane and Coords.WorldBox(plane) then return plane end
    end
    return nil
end

-- The largest scale of a map's art layers: as near as the game's own map comes, as a share of the map whole.
local function Deepest(map)
    local most = 1
    for _, layer in ipairs(ns.Art.Layers(map) or {}) do
        local scale = tonumber(layer.maxScale)
        if scale and scale > most then most = scale end
    end
    return most
end

-- The zooms from the view's size and the map shown: whole (fit, the farthest too) and the nearest. False where the
-- map has no box in the plane, or no art.
local function Limits(self)
    local box = self.shown and BoxIn(self.shown, self.map)
    local art = box and ns.Art.Of(self.shown)
    if not art then return false end
    local whole = math.min(self.width / box.width, self.height / box.height)
    self.box, self.whole = box, whole
    self.fit = whole * Camera.FIT
    self.far = self.fit
    self.near = math.max(self.fit, whole * Deepest(self.shown), Camera.DEEP * art.width / box.width)
    return true
end

-- The map shown's art layers as the zoom picks one of them (Layer): each with art, its smallest scale; read once with
-- the map (Put), not at every look.
local function Layers(self)
    local list = {}
    for index, layer in ipairs(ns.Art.Layers(self.shown) or NONE) do
        if ns.Art.Of(self.shown, index) then list[#list + 1] = { index = index, scale = tonumber(layer.minScale) or 0 } end
    end
    self.layers = list
end

-- The layer of the map's art the zoom shows: the last whose smallest scale it has reached, as the game's own map's
-- zoom levels pick it (Blizzard_MapCanvas, MapCanvas_ScrollContainerMixin.lua). Looked up again once the zoom (or
-- the map whole's) changed: scaled is the share of the map whole it was last picked for.
local function Layer(self)
    local scale, found = self.k / self.whole, 1
    for _, layer in ipairs(self.layers or NONE) do
        if layer.scale <= scale * (1 + 1e-6) then found = layer.index end
    end
    self.layer, self.scaled = found, scale
end

-- The zoom within its bounds (the game's minimap's step while it shows: Hybrid.lua), the middle on the map.
local function Clamp(self)
    local box = self.box
    if not box then return end
    local near = self.native and self.k or self.near
    self.k = math.max(self.far, math.min(near, self.k))
    self.u = math.max(box.u, math.min(box.u + box.width, self.u))
    self.v = math.min(box.v, math.max(box.v - box.height, self.v))
end

-- To a map: its plane, its box and zooms, its level (the kind of map it is) and its art's layers, kept until the next
-- (Settle asks the game nothing). False, and the camera as it was, where it cannot be shown.
local function Put(self, map)
    local plane = map and PlaneFor(map, self.map)
    if not plane then return false end
    local was, shown = self.map, self.shown
    self.map, self.shown = plane, map
    if Limits(self) then
        local info = Info(map)
        self.level = info and LEVELS[info.mapType] or "zone"
        Layers(self)
        self.scaled = nil
        return true
    end
    self.map, self.shown = was, shown
    if shown then Limits(self) end
    return false
end

-- The map the player is on, as the game says it, or the first over it the view can show; nil where none. Asked every
-- frame while a view follows: one question to the game, the rest kept.
function Camera.Wanted()
    local map, seen = Core.Ask(C_Map.GetBestMapForUnit, "player"), 0
    while map and map > 0 and seen < 10 do
        if ns.Art.Of(map) and Coords.Box(map) and Coords.PlaneOf(map) then return map end
        local info = Info(map)
        map, seen = info and info.parentMapID, seen + 1
    end
    return nil
end

function single:Nearest()
    return self.near or Camera.Near()
end

-- What the view shows while it follows the player (Canvas.lua): the map the player is on.
function single:Wants()
    return Camera.Wanted()
end

-- After every change (each frame while a view follows): the zoom and the middle within the map; the art's layer, where
-- the zoom changed. The level is the map shown's (Put).
function single:Settle()
    Clamp(self)
    if self.box and self.k / self.whole ~= self.scaled then Layer(self) end
end

function single:Frame(width, height)
    self.width, self.height = width, height
    Limits(self)
    self:Settle()
end

-- Looks at a plane (the player's, following; the first time): the map the player is on where it lies there, else the
-- plane's own; at u, v (its middle unless given), at that zoom (as it is; the first time the map whole, as the game's
-- own map opens).
function single:Show(map, u, v, k)
    local first = not self.shown
    local wanted = Camera.Wanted()
    if not (wanted and Coords.PlaneOf(wanted) == map) then wanted = map end
    if not Put(self, wanted) then return false end
    local box = self.box
    self:Look(u or box.u + box.width / 2, v or box.v - box.height / 2, k or (first and self.fit) or self.k)
    return true
end

-- Looks at a whole map (a click into it, a right click out of another, the selector, a pin, a quest): it alone, whole
-- in the view; the view no longer follows.
function single:Fit(map)
    if not Put(self, map) then return false end
    local box = self.box
    self.follow, self.native = false, nil
    self:Look(box.u + box.width / 2, box.v - box.height / 2, self.fit)
    return true
end

-- One map out: the first map over the one shown that the view can show; false at the top. (No click of ours does
-- it since 2026-11-18: the wheel zooms.)
function single:StepOut()
    local info, seen = Info(self.shown), 0
    local parent = info and info.parentMapID
    while parent and parent > 0 and seen < 10 do
        if self:Fit(parent) then return true end
        info = Info(parent)
        parent, seen = info and info.parentMapID, seen + 1
    end
    return false
end

-- A map under a point of the plane on the map shown, as the game's own map goes into it at a click (its
-- NavigateToCursor): nil where none, or where the view cannot show it.
function single:Under(u, v)
    local box = self.box
    if not box then return nil end
    local x, y = Coords.ToMap(box, u, v)
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    local info = Core.Ask(C_Map.GetMapInfoAtPosition, self.shown, x, y)
    local map = type(info) == "table" and info.mapID
    if not map or map == self.shown or not ns.Art.Of(map) or not PlaneFor(map, self.map) then return nil end
    return map
end

function Camera.New()
    return setmetatable({ u = 0, v = 0, k = 0.1, width = 1, height = 1, far = 0.001, fit = 0.001, follow = true,
                          level = "zone" }, { __index = single })
end
