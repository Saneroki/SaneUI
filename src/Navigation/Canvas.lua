local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Canvas
--  The frame the map is drawn in, its layers and the mouse.
--
--      canvas (clips what it holds; the ground: one colour)
--       └─ holder (at the canvas' middle; moved by a drag)
--            ├─ terrain   the game's minimap textures (Terrain.lua)
--            └─ art       Blizzard's map art (Art.lua)
--
--  Laid out around an origin, the camera's middle when it last was: a texture
--  stands at (its point - origin) * zoom from the holder's middle, and the
--  holder at (origin - middle) * zoom from the canvas'. So a drag moves one
--  frame, the holder, whatever is drawn. Laid out anew only when the zoom
--  changed, or the holder has moved past a margin; then each layer draws what is
--  in view now, from a pool that keeps the textures still in view as they are
--  (a file is never loaded twice while it is in sight).
--
--  Nothing runs at rest: the per-frame step is there only while the left button
--  drags the map.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Canvas = {}
ns.Canvas = Canvas

Canvas.GROUND = { 0.04, 0.05, 0.06 } -- where neither terrain nor art is: nearly black, as the plan's black minimap
Canvas.MARGIN = 0.15  -- what is laid out reaches so far past the view, as a part of its larger side
Canvas.OVERLAP = 1    -- each texture so many units larger than its square, so no seam shows between two

local frame, holder, camera
-- Where the layers were laid out: the origin (u, v), the zoom (k) and the view in the plane with its margin;
-- also the continent and its map. One table, filled anew at each layout.
local view = { u = 0, v = 0, k = 1, left = 0, right = 0, top = 0, bottom = 0, span = 0 }
Canvas.view = view
local laid = false -- something is laid out

-------------------------------------------------------------------------------
--  Pools: a layer's textures, by key
-------------------------------------------------------------------------------
local pools = {}

-- A layer's textures (of frame, in that draw layer), each kept by a key while it is asked for.
function Canvas.Pool(layer, drawLayer)
    return setmetatable({ frame = layer, drawLayer = drawLayer, used = {}, seen = {}, free = {} }, { __index = pools })
end

-- A layout begins: what is not asked for again until End goes.
function pools:Begin()
    wipe(self.seen)
end

-- The texture of key, showing file: the same as last time while it stayed in view.
function pools:Get(key, file, sublevel)
    local texture = self.used[key]
    if not texture then
        texture = table.remove(self.free) or self.frame:CreateTexture(nil, self.drawLayer)
        -- Placed to a fraction of a unit: not snapped to the screen's pixels, so neighbours meet.
        if texture.SetSnapToPixelGrid then
            texture:SetSnapToPixelGrid(false)
            texture:SetTexelSnappingBias(0)
        end
        texture:SetTexture(file, "CLAMP", "CLAMP", "TRILINEAR")
        texture:Show()
        self.used[key] = texture
    end
    texture:SetDrawLayer(self.drawLayer, sublevel or 0)
    self.seen[key] = true
    return texture
end

-- The layout is over: the textures not asked for go, their files let go.
function pools:End()
    for key, texture in pairs(self.used) do
        if not self.seen[key] then
            texture:Hide()
            texture:SetTexture(nil)
            self.used[key] = nil
            self.free[#self.free + 1] = texture
        end
    end
end

-------------------------------------------------------------------------------
--  Placing
-------------------------------------------------------------------------------
-- A texture over a rectangle of the plane: its top left corner (u, v) and its size in yards. part: how much
-- of it to show, from its left and its top (0 to 1; the last tiles of a map's art reach past its edge).
function Canvas.Put(texture, u, v, width, height, partX, partY)
    local k = view.k
    partX, partY = partX or 1, partY or 1
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", holder, "CENTER", (u - view.u) * k, (v - view.v) * k)
    texture:SetSize(width * partX * k + Canvas.OVERLAP, height * partY * k + Canvas.OVERLAP)
    texture:SetTexCoord(0, partX, 0, partY)
end

-- The layers, as the view chosen draws them: the terrain (unless Blizzard maps), and the art over it
-- (half see-through for the overlay), or alone where the terrain is too much to draw (far out).
local function Draw()
    local chosen = ns.options.view
    local terrain = ns.Safe("terrain", ns.Terrain.Place, view, chosen ~= "blizzard")
    local mode = "full"
    if terrain then mode = chosen == "overlay" and "half" or nil end
    ns.Safe("map art", ns.Art.Place, view, mode)
end

-- Every layer laid out anew around the camera's middle.
function Canvas.Layout()
    if not frame or not camera.box then return end
    local width, height = frame:GetSize()
    if width <= 0 or height <= 0 then return end
    view.u, view.v, view.k = camera.u, camera.v, camera.k
    view.span = height / camera.k -- yards the view is high, without the margin
    view.left, view.right, view.top, view.bottom = camera:View(math.max(width, height) * Canvas.MARGIN)
    holder:SetPoint("CENTER", 0, 0)
    laid = true
    Draw()
end

-- The camera moved without zooming: the holder follows; past the margin, a layout.
function Canvas.Moved()
    if not laid then return Canvas.Layout() end
    local x, y = (view.u - camera.u) * view.k, (view.v - camera.v) * view.k
    local width, height = frame:GetSize()
    local margin = math.max(width, height) * Canvas.MARGIN
    if math.abs(x) > margin or math.abs(y) > margin or camera.k ~= view.k then return Canvas.Layout() end
    holder:SetPoint("CENTER", x, y)
end

-------------------------------------------------------------------------------
--  The mouse
-------------------------------------------------------------------------------
local lastX, lastY -- where the mouse was at the drag's last step

-- The mouse in the canvas' units.
local function Cursor()
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    return x / scale, y / scale
end

local function Drag()
    local x, y = Cursor()
    if x == lastX and y == lastY then return end
    camera:Pan(x - lastX, y - lastY)
    lastX, lastY = x, y
    Canvas.Moved()
end
local dragging = ns.Guard(Drag) -- made once: the per-frame step while the left button is held

local function Down(_, button)
    if button ~= "LeftButton" then return end
    lastX, lastY = Cursor()
    frame:SetScript("OnUpdate", dragging)
end

local function Up(_, button)
    if button and button ~= "LeftButton" then return end
    frame:SetScript("OnUpdate", nil)
end

local function Wheel(_, delta)
    local x, y = Cursor()
    local middleX, middleY = frame:GetCenter()
    if not middleX then return end
    camera:ZoomAt(delta, x - middleX, y - middleY)
    Canvas.Layout()
end

-------------------------------------------------------------------------------
--  Open and closed
-------------------------------------------------------------------------------
-- The canvas, in parent. Its layers (Terrain, Art) make their frames on the holder, in drawing order.
function Canvas.Build(parent)
    frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    frame:SetClipsChildren(true)
    local ground = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    ground:SetAllPoints()
    ground:SetColorTexture(Canvas.GROUND[1], Canvas.GROUND[2], Canvas.GROUND[3])
    holder = CreateFrame("Frame", nil, frame)
    holder:SetSize(1, 1)
    holder:SetPoint("CENTER")
    ns.Terrain.Build(holder)
    ns.Art.Build(holder)
    camera = ns.Camera.New()
    Canvas.camera, Canvas.frame = camera, frame
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseDown", ns.Guard(Down))
    frame:SetScript("OnMouseUp", ns.Guard(Up))
    frame:SetScript("OnMouseWheel", ns.Guard(Wheel))
    frame:SetScript("OnHide", ns.Guard(Up)) -- a drag ends when the canvas goes
    return frame
end

-- The canvas has its size (the window fills the screen): it looks at the player's continent, at the player
-- the first time and whenever the player is on another continent now; else where it was left.
function Canvas.Open()
    local width, height = frame:GetSize()
    if width <= 0 or height <= 0 then return end
    local map, u, v = ns.Coords.Player()
    map = map or camera.map or ns.Coords.Continents()[1]
    local box = map and ns.Coords.Box(map)
    if not box then return end
    local fresh = map ~= camera.map
    camera:Frame(box, width, height)
    if fresh then
        camera:Look(u or box.u + box.width / 2, v or box.v - box.height / 2, height / ns.Camera.START)
    end
    camera.map = map
    view.map, view.continent = map, box.continent
    Canvas.Layout()
end

-- The window is small again: every texture let go, nothing is drawn. Where the camera looked is kept for
-- the next time.
function Canvas.Close()
    if not frame then return end
    Up()
    laid = false
    ns.Safe("terrain", ns.Terrain.Clear)
    ns.Safe("map art", ns.Art.Clear)
end

-- Drawn anew as it is, if it is laid out (the view chosen changed, the terrain's data arrived).
function Canvas.Refresh()
    if laid then Canvas.Layout() end
end
