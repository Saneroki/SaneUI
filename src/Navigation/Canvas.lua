local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Canvas
--  The frame the map is drawn in, the same for both views (Window.lua gives it
--  the camera of the view that shows): its layers, the player's place, the
--  mouse.
--
--      canvas (clips what it holds; the ground: one colour)
--       ├─ holder (at the canvas' middle; moved by a drag and by following)
--       │    ├─ terrain   the game's minimap textures and the overview (Terrain.lua)
--       │    ├─ art       Blizzard's map art and its explored parts (Art.lua)
--       │    └─ marks     the player's arrow, the map pin (Marks.lua)
--       └─ the game's minimap, between the art and the marks, while it shows (Hybrid.lua)
--  Their frame levels follow the canvas' at every layout (Canvas.LEVELS): a window raised to the full
--  screen and put back leaves its frames' levels as they come.
--
--  Laid out around an origin, the camera's middle when it last was: a texture
--  stands at (its point - origin) * zoom from the holder's middle, and the
--  holder at (origin - middle) * zoom from the canvas'. So a drag or a step of
--  following moves one frame, the holder, whatever is drawn. Laid out anew only
--  when the zoom changed, the holder has moved past a margin, or the zone in the
--  middle is another; then each layer draws what is in view now, from a pool that
--  keeps the textures still in view as they are (a file is never loaded twice
--  while it is in sight). The zoom changes at once, as on the game's map.
--
--  The mouse, the same in both views: a drag with the left button moves the map
--  (and stops following); the wheel zooms around the mouse (the game's minimap's
--  steps first while following, Hybrid.lua); a right click steps one map out
--  (zone, continent, world); Ctrl and a left click puts the game's map pin there;
--  a plain left click on the game's minimap pings. Over a continent shown whole
--  the zone under the mouse lights up, over the world the continent (Art.Light),
--  and a plain click opens it, as on the game's map.
--
--  On the window's way to the full screen and back the map goes with it (Morph): laid
--  out once, at the start, for the whole way, it is only scaled and moved on the
--  steps, from where the view it leaves looks to where the view it comes to looks.
--
--  The tracker asks where the player is: every frame while the view follows
--  (two questions to the game and one SetPoint), else a few times a second; and
--  after some time without the mouse on the map (the setting Follow again
--  after) the view follows again. Nothing else runs while nothing moves.
-------------------------------------------------------------------------------
local Coords, Live = ns.Coords, ns.Live
local Canvas = {}
ns.Canvas = Canvas

Canvas.GROUND = { 22 / 255, 38 / 255, 50 / 255 } -- the sea: where neither land nor art is (the terrain's water
                                                -- is cut away to it, dev/tools/terrain-art)
Canvas.PAPER = { 0.33, 0.29, 0.21 }             -- the sketches' sea past the world map: its paper, darker
Canvas.MARGIN = 0.15 -- what is laid out reaches so far past the view, as a part of its larger side
Canvas.OVERLAP = 1   -- each texture so many units larger than its square, so no seam shows between two
Canvas.DRAG = 4      -- the mouse moves so many units with the button held before it is a drag, not a click
Canvas.LOOK = 0.1    -- seconds between two looks at the player's place while the view does not follow
Canvas.LEVELS = { holder = 1, terrain = 2, art = 3, light = 4, marks = 20 } -- above the canvas; the game's
                                                         -- minimap at Hybrid.LEVEL, the full map's buttons at 30

local frame, holder, camera, tracker, layers, hover, ground
local held = false -- on the window's way, or hidden: its size changes lay nothing out
local morph       -- on the window's way: { a = where it comes from, b = where it goes, now = where it is }
-- Where the layers were laid out: the origin (u, v), the zoom (k), the view in the plane with its margin
-- (left, right, top, bottom), its height in yards (span); the continent's map whose plane it is (map), its
-- instance (continent), the level and the zone shown. One table, filled anew at each layout.
local view = { u = 0, v = 0, k = 1, left = 0, right = 0, top = 0, bottom = 0, span = 0, level = "continent" }
Canvas.view = view
local laid = false -- something is laid out
local known = false -- the player's place is known on the view's continent
local lastInput = 0 -- when the mouse last did something to the map
local overX, overY -- where the mouse was at the last look for the highlight (nil: look again)
local nextLook = 0

-------------------------------------------------------------------------------
--  Pools: a layer's textures, by key; masks that cut them to a shape
-------------------------------------------------------------------------------
local pools, masks = {}, {}

-- A texture cut by a mask (a MaskTexture of Canvas.Masks), or by none (nil); one at most.
local function Mask(texture, mask)
    local had = texture.mask
    if had == mask then return end
    if had then
        texture:RemoveMaskTexture(had)
        had.held[texture] = nil
    end
    if mask then
        texture:AddMaskTexture(mask)
        mask.held[texture] = true
    end
    texture.mask = mask
end

-- A layer's textures (of frame, in that draw layer), each kept by a key while it is asked for.
function Canvas.Pool(layer, drawLayer)
    return setmetatable({ frame = layer, drawLayer = drawLayer, used = {}, seen = {}, free = {} }, { __index = pools })
end

-- A layout begins: what is not asked for again until End goes.
function pools:Begin()
    wipe(self.seen)
end

-- The texture of key, showing file: the same as last time while it stayed in view; cut by mask, if given.
function pools:Get(key, file, sublevel, mask)
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
    Mask(texture, mask)
    self.seen[key] = true
    return texture
end

-- The layout is over: the textures not asked for go, their files let go.
function pools:End()
    for key, texture in pairs(self.used) do
        if not self.seen[key] then
            texture:Hide()
            texture:SetTexture(nil)
            Mask(texture, nil)
            self.used[key] = nil
            self.free[#self.free + 1] = texture
        end
    end
end

-- A layer's masks (of frame), each kept by a key while it is asked for: the alpha of a file over a
-- rectangle of the plane cuts the textures given it (a coast, a zone's outline).
function Canvas.Masks(layer)
    return setmetatable({ frame = layer, used = {}, seen = {}, free = {} }, { __index = masks })
end

function masks:Begin()
    wipe(self.seen)
end

-- The mask of key, file's alpha over the rectangle of the plane with its top left corner at u, v, width
-- and height yards large; nothing outside it.
function masks:Get(key, file, u, v, width, height)
    local mask = self.used[key]
    if not mask then
        mask = table.remove(self.free) or self.frame:CreateMaskTexture()
        mask.held = mask.held or {}
        mask:SetTexture(file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "TRILINEAR")
        mask:Show()
        self.used[key] = mask
    end
    self.seen[key] = true
    local k = view.k
    mask:ClearAllPoints()
    mask:SetPoint("TOPLEFT", holder, "CENTER", (u - view.u) * k, (v - view.v) * k)
    mask:SetSize(width * k, height * k)
    return mask
end

-- The layout is over: the masks not asked for let go of their textures and files.
function masks:End()
    for key, mask in pairs(self.used) do
        if not self.seen[key] then
            for texture in pairs(mask.held) do Mask(texture, nil) end
            mask:Hide()
            mask:SetTexture(nil)
            self.used[key] = nil
            self.free[#self.free + 1] = mask
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

-- The zone in the middle of the view, at the zone's level.
local function Zone()
    if camera.level ~= "zone" then return nil end
    return Coords.ZoneAt(camera.map, camera.u, camera.v)
end

-- The layers, as the view chosen draws them, at every zoom: Sketches (the art), Terrain (the land), Overlay
-- (the land, the art half see-through over it); the ground is the sea of the one or the other.
local function Draw()
    local chosen = ns.options.view
    local sea = chosen == "sketches" and Canvas.PAPER or Canvas.GROUND
    ground:SetColorTexture(sea[1], sea[2], sea[3])
    ns.Safe("terrain", ns.Terrain.Place, view, chosen ~= "sketches")
    ns.Safe("map art", ns.Art.Place, view, chosen == "sketches" and "full" or chosen == "overlay" and "half" or nil)
    ns.Safe("marks", ns.Marks.Pin, view)
end

-- The game's minimap for the view as it is now.
local function Native()
    local width, height = frame:GetSize()
    ns.Guarded(ns.Hybrid.Place, camera, width, height, known)
end

-- The layers' frame levels from the canvas' own.
local function Stack()
    local base = frame:GetFrameLevel()
    holder:SetFrameLevel(base + Canvas.LEVELS.holder)
    layers.terrain:SetFrameLevel(base + Canvas.LEVELS.terrain)
    layers.art:SetFrameLevel(base + Canvas.LEVELS.art)
    layers.light:SetFrameLevel(base + Canvas.LEVELS.light)
    ns.Marks.Stack(base + Canvas.LEVELS.marks)
end

-- Every layer laid out anew around the camera's middle.
function Canvas.Layout()
    if not frame or not camera or not camera.map then return end
    local width, height = frame:GetSize()
    if width <= 0 or height <= 0 then return end
    morph = nil
    ns.Hybrid.Fit(camera, width, height)
    camera:Frame(width, height)
    local box = Coords.Box(camera.map)
    view.u, view.v, view.k = camera.u, camera.v, camera.k
    view.map, view.continent, view.level = camera.map, box.continent, camera.level
    view.zone = Zone()
    view.span = height / camera.k
    view.left, view.right, view.top, view.bottom = camera:View(math.max(width, height) * Canvas.MARGIN)
    holder:SetScale(1)
    holder:SetPoint("CENTER", 0, 0)
    laid = true
    overX = nil -- the highlight is placed anew around the new origin
    Stack()
    Draw()
    Native()
end

-- The camera moved without zooming: the holder follows; past the margin, or over another zone, a layout.
function Canvas.Moved()
    if not laid or camera.k ~= view.k or camera.map ~= view.map or camera.level ~= view.level then
        return Canvas.Layout()
    end
    local x, y = (view.u - camera.u) * view.k, (view.v - camera.v) * view.k
    local width, height = frame:GetSize()
    local margin = math.max(width, height) * Canvas.MARGIN
    if math.abs(x) > margin or math.abs(y) > margin or (view.level == "zone" and Zone() ~= view.zone) then
        return Canvas.Layout()
    end
    holder:SetPoint("CENTER", x, y)
end

-- Drawn anew as it is, if it is laid out (the view chosen changed, data arrived, the game's minimap's zoom).
function Canvas.Refresh()
    if laid then Canvas.Layout() end
end

-------------------------------------------------------------------------------
--  The player
-------------------------------------------------------------------------------
local function Track()
    local now = GetTime()
    if not camera.follow and now < nextLook then return end
    nextLook = now + Canvas.LOOK
    local map, u, v, facing = Live.Player()
    local was, followed = known, camera.follow
    known = u ~= nil and map == camera.map
    if camera.follow and u then
        if map ~= camera.map then
            camera:Show(map, u, v)
            return Canvas.Layout()
        elseif u ~= camera.u or v ~= camera.v then
            camera:Look(u, v)
            Canvas.Moved()
        end
    elseif not camera.follow and u and ns.options.followAgain > 0 and now - lastInput > ns.options.followAgain
        and not frame:IsMouseOver() then
        camera.follow = true -- the next look puts the player in the middle
        nextLook = 0
    end
    if was ~= known or followed ~= camera.follow then Native() end
    ns.Marks.Player(view, map, u, v, facing, ns.Hybrid.Shown())
end
local tracking = ns.Guard(Track) -- made once

-------------------------------------------------------------------------------
--  The mouse
-------------------------------------------------------------------------------
local pressed, pressX, pressY, lastX, lastY, moved

-- The mouse in the canvas' units.
local function Cursor()
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    return x / scale, y / scale
end

-- The mouse from the canvas' middle, in its units.
local function FromMiddle()
    local x, y = Cursor()
    local middleX, middleY = frame:GetCenter()
    if not middleX then return nil end
    return x - middleX, y - middleY
end

local function Drag()
    local x, y = Cursor()
    if not moved then
        if math.abs(x - pressX) + math.abs(y - pressY) < Canvas.DRAG then return end
        moved, lastX, lastY = true, pressX, pressY
        known = false
        Native() -- the game's minimap goes: the view no longer follows
    end
    if x == lastX and y == lastY then return end
    camera:Pan(x - lastX, y - lastY)
    lastX, lastY = x, y
    lastInput = GetTime()
    Canvas.Moved()
end
local dragging = ns.Guard(Drag) -- made once: the per-frame step while the left button is held

local function Down(_, button)
    lastInput = GetTime()
    pressed, moved = button, false
    pressX, pressY = Cursor()
    if button == "LeftButton" then frame:SetScript("OnUpdate", dragging) end
end

-- The game's map pin where the mouse is: on the zone there, else the continent (as the game's map puts it
-- on the map it shows); at the world, on the continent under the mouse.
local function Pin(x, y)
    local u, v = camera.u + x / camera.k, camera.v + y / camera.k
    local continent = camera.map
    if camera.level == "world" then
        local under = Coords.ContinentAt(camera.map, u, v)
        local link = under and Coords.Link(camera.map, under)
        if not link then return UIErrorsFrame:AddMessage(ns.TEXT.noPin, 1, 0.1, 0.1) end
        continent, u, v = under, link.du + link.su * u, link.dv + link.sv * v
    end
    local map = Coords.ZoneAt(continent, u, v) or continent
    local mapX, mapY = Coords.ToMap(Coords.Box(map), u, v)
    if Live.SetWaypoint(map, mapX, mapY) then
        ns.Marks.Sound("UI_MAP_WAYPOINT_CONTROL_CLICK")
    else
        UIErrorsFrame:AddMessage(ns.TEXT.noPin, 1, 0.1, 0.1)
    end
end

-- A plain click on a map the view shows whole: the zone under the mouse at a continent, the continent at
-- the world, fills the view, as a click on the game's map opens it. False where nothing is opened.
local function Into(x, y)
    if camera.level == "zone" then return false end
    local u, v = camera.u + x / camera.k, camera.v + y / camera.k
    local map
    if camera.level == "world" then map = Coords.ContinentAt(camera.map, u, v) else map = Coords.ZoneAt(camera.map, u, v) end
    if not map or not camera:Fit(map) then return false end
    ns.Art.Unlight()
    Canvas.Layout()
    return true
end

local function Up(_, button)
    frame:SetScript("OnUpdate", nil)
    if button ~= pressed then return end
    pressed = nil
    lastInput = GetTime()
    if moved then
        moved = false
        return
    end
    local x, y = FromMiddle()
    if not x then return end
    if button == "LeftButton" then
        if IsControlKeyDown() then Pin(x, y) elseif not ns.Hybrid.Ping(x, y) then Into(x, y) end
    elseif button == "RightButton" and camera:StepOut() then
        Canvas.Layout()
    end
end

local function Wheel(_, delta)
    lastInput = GetTime()
    local width, height = frame:GetSize()
    if known and ns.Hybrid.Wheel(camera, delta, ns.Hybrid.Side(width, height)) then
        camera:Settle()
        return Canvas.Layout()
    end
    local x, y = FromMiddle()
    if not x then return end
    camera:ZoomAt(delta, x, y)
    Canvas.Layout()
end

-- While the mouse is over the canvas: what a click would open lights up, looked at again when the mouse
-- moved. Off the canvas, a button held, the window on its way: out of sight, and the look stops.
local function Over()
    if not frame:IsMouseOver() or pressed or held or not laid then
        hover:SetScript("OnUpdate", nil)
        overX = nil
        return ns.Art.Unlight()
    end
    local x, y = FromMiddle()
    if not x or (x == overX and y == overY) then return end
    overX, overY = x, y
    if view.level == "zone" then return ns.Art.Unlight() end
    ns.Art.Light(view, camera.u + x / camera.k, camera.v + y / camera.k)
end
local hovering = ns.Guard(Over) -- made once: the look while the mouse is over the canvas

local function Entered()
    hover:SetScript("OnUpdate", hovering)
end

-- A drag ends when the canvas goes (the window on its way, hidden).
local function Gone()
    frame:SetScript("OnUpdate", nil)
    pressed, moved = nil, false
end

-------------------------------------------------------------------------------
--  Open and closed
-------------------------------------------------------------------------------
-- The canvas, in parent. Its layers make their frames on the holder, in drawing order.
function Canvas.Build(parent)
    frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    frame:SetClipsChildren(true)
    Canvas.frame = frame
    ground = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    ground:SetAllPoints()
    ground:SetColorTexture(Canvas.GROUND[1], Canvas.GROUND[2], Canvas.GROUND[3])
    holder = CreateFrame("Frame", nil, frame)
    holder:SetSize(1, 1)
    holder:SetPoint("CENTER")
    layers = { terrain = ns.Terrain.Build(holder) }
    layers.art, layers.light = ns.Art.Build(holder)
    ns.Marks.Build(holder)
    Stack()
    tracker = CreateFrame("Frame", nil, frame)
    hover = CreateFrame("Frame", nil, frame)
    frame:EnableMouse(true)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseDown", ns.Guard(Down))
    frame:SetScript("OnMouseUp", ns.Guard(Up))
    frame:SetScript("OnMouseWheel", ns.Guard(Wheel))
    frame:SetScript("OnEnter", ns.Guard(Entered))
    frame:SetScript("OnHide", ns.Guard(Gone))
    -- Sized while it stands (Edit Mode): laid out for the new size; not on the window's way, nor hidden.
    frame:SetScript("OnSizeChanged", ns.Guard(function() if laid and not held then Canvas.Layout() end end))
    ns.Listen("LIVE", function(what)
        if what == "waypoint" then
            if laid then ns.Marks.Pin(view) end
        elseif what == "explored" or what == "zone" then
            Canvas.Refresh()
        end
    end)
    return frame
end

-- The view whose camera the canvas uses now (Window.lua: the small one, or the full screen's).
function Canvas.Use(viewCamera)
    camera = viewCamera
    Canvas.camera = camera
end

-- A camera ready for a view of that size: on the player the first time (else where it was left).
local function Aim(viewCamera, width, height)
    if viewCamera.map then return true end
    viewCamera.width, viewCamera.height = width, height
    local map, u, v = Live.Player()
    map = map or Coords.Continents()[1]
    return map and viewCamera:Show(map, u, v) or false
end

-- The canvas stands at its size (the window is small, or fills the screen): the camera on the player the
-- first time (else where it was left), laid out, the tracker on.
function Canvas.Open()
    local width, height = frame:GetSize()
    if width <= 0 or height <= 0 then return end
    held = false
    if not Aim(camera, width, height) then return end
    known = false
    nextLook = 0
    Canvas.Layout()
    tracker:SetScript("OnUpdate", tracking)
end

-- A camera looks at a map (the game's map was asked for at it): the map whole in the view.
function Canvas.Fit(viewCamera, map, width, height)
    viewCamera.width, viewCamera.height = width, height
    if not viewCamera.map then
        local home = Coords.ContinentOf(map) or Coords.Continents()[1]
        if not home or not viewCamera:Show(home) then return false end
    end
    return viewCamera:Fit(map)
end

-- Nothing follows, the game's minimap and the marks out of sight (the window on its way, or hidden).
function Canvas.Hold()
    if not frame then return end
    held = true
    tracker:SetScript("OnUpdate", nil)
    Gone()
    ns.Hybrid.Hide()
    ns.Marks.Clear()
end

-- Where a view looks, as plain numbers: its continent, middle, zoom, size and level.
local function Spot(from)
    return { map = from.map, u = from.u, v = from.v, k = from.k, width = from.width, height = from.height,
             level = from.level }
end

-- What a spot shows, and margin units past it: left, right, top, bottom in its plane.
local function Reach(spot, margin)
    local across, high = (spot.width / 2 + margin) / spot.k, (spot.height / 2 + margin) / spot.k
    return spot.u - across, spot.u + across, spot.v + high, spot.v - high
end

-- The window begins its way to the full screen or back (Window.lua): the canvas will be width x height
-- and show target's view there. The map is laid out once for the whole way, at the wider of the two
-- views' zooms, over what both show; Step scales and moves it from the view it leaves (or from where a way
-- turned back stands) to target's. Without a view to leave it simply stands at target's.
function Canvas.Morph(target, width, height)
    if not frame then return end
    Canvas.Hold()
    if width <= 0 or height <= 0 or not Aim(target, width, height) then return end
    ns.Hybrid.Fit(target, width, height)
    target:Frame(width, height)
    local b = Spot(target)
    local a = morph and morph.now or (laid and camera and camera.map and Spot(camera)) or nil
    if a and a.map ~= b.map then
        local link = Coords.Link(a.map, b.map) -- into the plane it goes to, at the same size on the screen
        if link then
            a.u, a.v, a.k, a.map = link.du + link.su * a.u, link.dv + link.sv * a.v, a.k / math.sqrt(link.su * link.sv), b.map
        else
            a = nil
        end
    end
    a = a or b
    local wide = a.height / a.k > b.height / b.k and a or b
    local margin = math.max(width, height) * Canvas.MARGIN
    local l1, r1, t1, b1 = Reach(a, margin)
    local l2, r2, t2, b2 = Reach(b, margin)
    view.u, view.v, view.k = wide.u, wide.v, wide.k
    view.map, view.continent, view.level = b.map, Coords.Box(b.map).continent, wide.level
    view.zone = wide.level == "zone" and Coords.ZoneAt(b.map, wide.u, wide.v) or nil
    view.span = wide.height / wide.k
    view.left, view.right = math.min(l1, l2), math.max(r1, r2)
    view.top, view.bottom = math.max(t1, t2), math.min(b1, b2)
    laid = true
    Stack()
    Draw()
    morph = { a = a, b = b, now = Spot(a) }
    Canvas.Step(0)
end

-- A step of the window's way: the share of it (0 to 1; past 1 and back for Swing, where the map stays at
-- its end). The middle goes straight, the zoom by equal factors, so the map neither rushes nor lags.
function Canvas.Step(share)
    if not morph then return end
    local a, b, now = morph.a, morph.b, morph.now
    local t = math.min(math.max(share, 0), 1)
    now.u, now.v = a.u + (b.u - a.u) * t, a.v + (b.v - a.v) * t
    now.k = a.k * (b.k / a.k) ^ t
    now.width, now.height = frame:GetSize()
    now.map, now.level = b.map, b.level
    local scale = now.k / view.k
    holder:SetScale(scale)
    holder:SetPoint("CENTER", (view.u - now.u) * now.k / scale, (view.v - now.v) * now.k / scale)
end

-- Hidden: every texture let go, nothing runs. Where the cameras looked is kept for the next time.
function Canvas.Close()
    if not frame then return end
    Canvas.Hold()
    laid, morph = false, nil
    ns.Safe("terrain", ns.Terrain.Clear)
    ns.Safe("map art", ns.Art.Clear)
end
