local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Canvas
--  The frame the map is drawn in, the same for both views (Window.lua gives it
--  the camera of the view that shows): its layers, the player's place, the
--  mouse.
--
--      canvas (clips what it holds; the ground: one colour)
--       ├─ holder (at the canvas' middle; moved by a drag and by following)
--       │    ├─ sea       the sea's layers over the ground: the game's own waves twice, a soft shade (Waves),
--       │    │            the Maelstrom's whirlpool (Whirlpool)
--       │    ├─ terrain   the game's minimap textures and the overview (Terrain.lua)
--       │    ├─ art       Blizzard's map art and its explored parts, the view Parchment (Art.lua)
--       │    ├─ indoors   the indoor map of the building the player is in (Indoors.lua)
--       │    ├─ light     the zone under the mouse (Art.lua)
--       │    ├─ farms     the places to farm a thing the map's search found, glowing (Farms.lua)
--       │    ├─ areas     the quest's areas (Areas.lua)
--       │    ├─ route     the golden line (Route.lua)
--       │    ├─ paths     the ways of the flight point or dock under the mouse (Paths.lua)
--       │    ├─ sketch    the drawings of your plans shown (Draw.lua)
--       │    ├─ pins      the pins of the game and of Core's data (PinView.lua)
--       │    └─ marks     the party, the player's arrow, the map pin (Marks.lua)
--       └─ the game's minimap, between the route and the pins, while it shows (Hybrid.lua): small, in the
--          middle; full, around the player; under the route where it keeps its own ground (Stack)
--  Whatever the view, what stands on the map (areas, route, pins, marks) is always over the map's own
--  layers: their frame levels follow the canvas' at every layout (Canvas.LEVELS), so a window raised to the
--  full screen and put back, which leaves its frames' levels as they come, never puts the map over them.
--  It also keeps inside the canvas by itself (Canvas.edge): the game cut the map's textures at the canvas'
--  edge, but drew the lines and buttons laid out past the view over the screen around the small window.
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
--  (zone, continent, world); a double click puts the game's map pin there (on a
--  pin: where the pin stands), and so does Ctrl and a click, the game's own way.
--  Over a continent shown whole the zone under the mouse lights up, over the world
--  the continent is named (Art.Light), and a plain click opens it, as on the game's map;
--  where a click opens nothing, it pings there to the group as a click on the
--  game's minimap does (Ping.lua), at once (the game takes a ping only in the
--  click itself). A click on a pin is the pin's first, where
--  it has one of its own (PinView.Act). The middle button brings the view back
--  onto the player, following, near enough for the game's minimap's dots (Home).
--  A plane of its own (Zephras Isle) is drawn as a continent is, as a zone
--  (Camera.lua).
--
--  Retail shows one map at a time, as the game's own map does (Camera.Retail.lua:
--  camera.shown): a click goes into the map the game says is under the mouse, at
--  every level (a city in its zone too), and lights it up before; a right click
--  goes up to the map over it; the wheel zooms within the map shown; following,
--  the view shows the map the player is on (camera:Wants).
--
--  On the window's way to the full screen and back the map goes with it (Morph): laid
--  out once, at the start, for the whole way, it is only scaled and moved on the
--  steps, from where the view it leaves looks to where the view it comes to looks;
--  meanwhile nothing lays it out again (a refresh, the wheel, a press).
--
--  The tracker asks where the player is: every frame while the view follows
--  (three questions to the game and one SetPoint; the zone in the middle a few
--  times a second), else a few times a second. A view moved off the player follows
--  again only while the box Follow me is ticked (the setting followMap, TopBar.lua)
--  and no mouse button is held: the small view the moment the player walks; the full
--  map, which is always under the mouse and there to be looked around, as the player
--  walks once the mouse has left it alone for Canvas.AGAIN.
--  Nothing else runs while nothing moves. Where the game tells no place of the
--  player (an instance) the small view draws nothing of ours but the sea: the
--  game's minimap, with its own ground, is the map there (Hybrid.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Live = ns.Coords, ns.Live
local Canvas = {}
ns.Canvas = Canvas

Canvas.GROUND = { 22 / 255, 38 / 255, 50 / 255 } -- the sea: where neither land nor art is (the terrain's water
                                                -- is cut away to it, dev/tools/terrain-art)
Canvas.PAPER = { 0.33, 0.29, 0.21 }             -- the sketches' sea past the world map: its paper, darker
-- The sea over the ground (Waves): layers repeated over the plane, so they move with the map, each copy `size` units
-- on a side at every zoom; where the paper shows instead of the sea (Sketches, Blended far out), they fade as the
-- sea's colour does. The game's own ocean texture, its light alone (Art/Sea.blp, made by dev/tools/terrain-art: a
-- quarter of its size, 256 x 256, its own size on a 4K screen, softened by a pixel), twice: small, and larger by a
-- factor that does not divide into the first, shifted and turned half round (its streaks still run the same way), so
-- the two grids never line up alike in view and no copy shows as a tile (Saneroki, 2026-11-11: "it is very tiled");
-- over them a soft shade (Art/SeaShade.blp, a tileable noise made by the same tool): slow patches of darker water,
-- deeper and shallower seas, hundreds of units across.
--   file, size (units a copy's side), colour, alpha, turned (half round), shift (where the copies start, 0 to 1)
Canvas.SEA = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Sea"
Canvas.SEA_SHADE = "Interface\\AddOns\\SaneUI_Navigation\\Art\\SeaShade"
Canvas.SEA_LAYERS = {
    { file = Canvas.SEA, size = 91, colour = { 120 / 255, 170 / 255, 190 / 255 }, alpha = 0.34 },
    { file = Canvas.SEA, size = 157, colour = { 120 / 255, 170 / 255, 190 / 255 }, alpha = 0.28, turned = true,
      shift = { 0.37, 0.61 } },
    { file = Canvas.SEA_SHADE, size = 1100, colour = { 8 / 255, 16 / 255, 24 / 255 }, alpha = 0.45 },
}
-- The Maelstrom's whirlpool over the waves, where WoW: Forever's world map paints it (Saneroki, 2026-11-15: "add a
-- whirlpool into the middle of the sea like it is on the original maps"): that map's own spiral, its ink and the
-- light at its middle in white (Art/Whirlpool.blp, cut from the map's art by dev/tools/terrain-art --whirlpool),
-- tinted as the waves' foam and shown as much as they are (Whirlpool). x, y: its middle, wide, high: its size, each
-- 0 to 1 of the world map, as the tool prints them. Forever's alone: Retail's world map is another.
Canvas.WHIRLPOOL = Core.FOREVER and {
    file = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Whirlpool", x = 0.5000, y = 0.4955, wide = 0.1996, high = 0.2994,
    colour = { 150 / 255, 195 / 255, 210 / 255 }, alpha = 0.55,
} or nil
-- The view Blended: Blizzard's map art over the terrain whole while the view is BLEND[1] yards high or more, gone at
-- BLEND[2] or less; between, faded by the zoom's own steps (each a factor), so every step changes it alike.
Canvas.BLEND = { 9000, 1200 }
Canvas.MARGIN = 0.15 -- what is laid out reaches so far past the view, as a part of its larger side
Canvas.OVERLAP = 1   -- each texture so many units larger than its square, so no seam shows between two
Canvas.DRAG = 4      -- the mouse moves so many units with the button held before it is a drag, not a click
Canvas.LOOK = 0.1    -- seconds between two looks at the player's place while the view does not follow
Canvas.AGAIN = 10    -- seconds the mouse leaves the full map alone before it follows again (Again; the tip of Follow me)
Canvas.DOUBLE = 0.3  -- a second click so many seconds after the first, near where it was, is a double click
Canvas.NEAR = 8      -- units the mouse may move between the two clicks of a double click
Canvas.HOME = 400    -- yards across the view's shorter side a middle click comes back at where the game's minimap
                     -- is not ours (Home)
-- Above the canvas, in drawing order; the game's minimap at Hybrid.LEVEL (10), the full map's bars at 30.
Canvas.LEVELS = { holder = 1, terrain = 2, art = 3, indoors = 4, light = 5, farms = 6, areas = 7, route = 8,
                  paths = 9, sketch = 11, pins = 12, marks = 20, satchel = 30 }
Canvas.MAP = 5 -- the highest level of the map itself: what stands on it is above this
Canvas.OVER_GROUND = 11 -- the route where the game's minimap keeps its own ground: over that, under the pins (Stack)

local frame, holder, camera, tracker, layers, hover, ground
local waves = {} -- the sea's layers (Waves): { texture, spec } each; one whose file is missing left out
local whirl       -- the whirlpool's texture (Whirlpool), nil where there is none
local held = false -- on the window's way, or hidden: its size changes lay nothing out
local morph       -- on the window's way: { a = where it comes from, b = where it goes, now = where it is }
-- Where the layers were laid out: the origin (u, v), the zoom (k), the view in the plane with its margin
-- (left, right, top, bottom), its height in yards (span); the plane's map (map: a continent's, or a plane of its
-- own), its instance (continent), the level and the zone shown; one map at a time (Retail): the map shown (shown),
-- its box in the plane (box) and its art's layer (layer). One table, filled anew at each layout.
local view = { u = 0, v = 0, k = 1, left = 0, right = 0, top = 0, bottom = 0, span = 0, level = "continent" }
Canvas.view = view
-- The canvas' own rectangle in the holder's units as the holder stands now (x, y: its offset from the canvas'
-- middle in its own units; scale: on the window's way), left, right, bottom, top: the route is cut at it, pins
-- and marks show only while wholly inside it (Route.Fit, PinView.Fit, Marks.Fit; Canvas.Inside).
local edge = { left = 0, right = 0, bottom = 0, top = 0, x = 0, y = 0, scale = 1 }
Canvas.edge = edge
Canvas.REFIT = 0.5 -- the holder moves so many units before what stands on the map is kept inside anew
local laid = false -- something is laid out
local known = false -- the player's place is known in the view's plane
-- The small view follows the player where the game tells no place of the player (an instance): the game's
-- minimap alone is the map there, and nothing of ours is drawn but the sea (Lost; Hybrid.Place).
local lost = false
-- There the small view was wheeled out past the game's widest step: the dungeon's whole map stands over it
-- (Dungeons.Small), and the game's minimap out of sight under it.
local whole = false
local lastInput = 0 -- when the mouse last did something to the map
local pressed -- the mouse button held on the map (Down), nil while none
local seenU, seenV -- the player's place at the tracker's last look
local overX, overY -- where the mouse was at the last look for the highlight (nil: look again)
local nextLook = 0
local nextZone = 0 -- while the view moves, when the zone in its middle is next asked of the game (Moved)
local zoneOwed = false -- the view moved without that ask (within a Canvas.LOOK of the last): Track asks it later
local spun = false -- notches of the wheel added up in the camera and not laid out yet (Zoomed): a layout takes them

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

-- The canvas' rectangle for the holder at x, y (its offset from the canvas' middle, in its own units) and scale.
local function Bounds(x, y, scale)
    local width, height = frame:GetSize()
    edge.x, edge.y, edge.scale = x, y, scale
    edge.left, edge.right = -width / 2 / scale - x, width / 2 / scale - x
    edge.bottom, edge.top = -height / 2 / scale - y, height / 2 / scale - y
end

-- What stands on the map kept inside the canvas' rectangle as it is now.
local function Keep()
    ns.Safe("route", ns.Route.Fit, edge)
    ns.Safe("paths", ns.Paths.Fit, edge)
    ns.Safe("drawings", ns.Draw.Fit, edge)
    ns.Safe("pins", ns.PinView.Fit, edge)
    ns.Safe("marks", ns.Marks.Fit, edge)
    ns.Guarded(ns.Hybrid.Keep)
end

-- Whether something at x, y (the holder's units) reaching half units each way lies wholly inside the canvas.
function Canvas.Inside(x, y, half)
    return x - half >= edge.left and x + half <= edge.right and y - half >= edge.bottom and y + half <= edge.top
end

-- The zone in the middle of the view, at the zone's level; one map at a time, the map shown.
local function Zone()
    if camera.level ~= "zone" then return nil end
    if camera.shown then return camera.shown end
    return Coords.ZoneAt(camera.map, camera.u, camera.v)
end

-- How much of Blizzard's map art the view Blended draws over the terrain when the view is span yards high (0 to 1).
function Canvas.Blend(span)
    local whole, gone = Canvas.BLEND[1], Canvas.BLEND[2]
    if span >= whole then return 1 end
    if span <= gone then return 0 end
    local x = math.log(span / gone) / math.log(whole / gone)
    return x * x * (3 - 2 * x)
end

-- The sea's layers over the view's rectangle (as laid out), shown so much (0 to 1). They are laid by the plane, so a
-- drag or a step of following moves them with the land; a layer turned half round reads the plane's coordinates
-- negated; each texture coordinate counted from a copy's corner near the rectangle, so the numbers stay small however
-- far out the plane reaches.
local NO_SHIFT = { 0, 0 }

-- The whirlpool (Canvas.WHIRLPOOL) where the world map puts it in the view's plane, shown so much (0 to 1) while it
-- meets the view; on a plane the world map does not hold, none.
local function Whirlpool(shown)
    if not whirl then return end
    local spec = Canvas.WHIRLPOOL
    local world = shown > 0 and Coords.WorldBox(view.map)
    local u, v
    if world then u, v = Coords.FromWorldMap(view.map, spec.x, spec.y) end
    if not u then return whirl:Hide() end
    local width, height = spec.wide * world.width, spec.high * world.height
    local left, top = u - width / 2, v + height / 2
    if left > view.right or left + width < view.left or top < view.bottom or top - height > view.top then
        return whirl:Hide()
    end
    Canvas.Put(whirl, left, top, width, height)
    whirl:SetAlpha(spec.alpha * shown)
    whirl:Show()
end

local function Waves(shown)
    local k = view.k
    for _, layer in ipairs(waves) do
        local texture, spec = layer.texture, layer.spec
        if shown <= 0 then
            texture:Hide()
        else
            local size, shift = spec.size, spec.shift or NO_SHIFT
            local s0, s1 = view.left * k / size + shift[1], view.right * k / size + shift[1]
            local t0, t1 = -view.top * k / size + shift[2], -view.bottom * k / size + shift[2]
            if spec.turned then s0, s1, t0, t1 = -s0, -s1, -t0, -t1 end
            local x, y = math.floor(math.min(s0, s1)), math.floor(math.min(t0, t1))
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", holder, "CENTER", (view.left - view.u) * k, (view.top - view.v) * k)
            texture:SetPoint("BOTTOMRIGHT", holder, "CENTER", (view.right - view.u) * k, (view.bottom - view.v) * k)
            texture:SetTexCoord(s0 - x, s1 - x, t0 - y, t1 - y)
            texture:SetAlpha(spec.alpha * shown)
            texture:Show()
        end
    end
    Whirlpool(shown)
end

-- Every layer's textures let go: nothing of ours drawn but the sea (the canvas' ground), in one colour.
local function Empty()
    for _, layer in ipairs(waves) do layer.texture:Hide() end
    if whirl then whirl:Hide() end
    ns.Safe("terrain", ns.Terrain.Clear)
    ns.Safe("map art", ns.Art.Clear)
    ns.Safe("indoors", ns.Indoors.Clear)
    ns.Safe("areas", ns.Areas.Clear)
    ns.Safe("farms", ns.Farms.Hide)
    ns.Safe("drawings", ns.Draw.Clear)
    ns.Safe("route", ns.Route.Clear)
    ns.Safe("paths", ns.Paths.Clear)
    ns.Safe("pins", ns.PinView.Clear)
end

-- Whether the small view follows the player where the game tells no place of the player (u nil: an instance)
-- while the game's minimap is ours to stand in for our map there.
local function Lost(u)
    return u == nil and camera == ns.Window.small and camera.follow and ns.Hybrid.Taken() or false
end

-- The layers, as the view chosen draws them, at every zoom: Parchment (the art), Scrying (the land), Blended (the
-- art over the land, faded out as the view comes close: Canvas.Blend); the ground is the sea of the one or the
-- other, or between them, the waves on the terrain's. Only a layer that shows is drawn. In an instance (lost) none:
-- the game's minimap is the map there, on the sea's colour alone.
local function Draw()
    if lost then
        ground:SetColorTexture(Canvas.GROUND[1], Canvas.GROUND[2], Canvas.GROUND[3])
        Empty()
        return ns.Safe("marks", ns.Marks.Clear)
    end
    local chosen = ns.View()
    local art = chosen == "sketches" and 1 or chosen == "blend" and Canvas.Blend(view.span) or 0
    local sea, paper = Canvas.GROUND, Canvas.PAPER
    ground:SetColorTexture(sea[1] + (paper[1] - sea[1]) * art, sea[2] + (paper[2] - sea[2]) * art,
        sea[3] + (paper[3] - sea[3]) * art)
    Waves(1 - art)
    layers.art:SetAlpha(art)
    ns.Safe("terrain", ns.Terrain.Place, view, art < 1)
    ns.Safe("map art", ns.Art.Place, view, art > 0)
    ns.Safe("indoors", ns.Indoors.Place, view)
    ns.Safe("areas", ns.Areas.Place, view, camera == ns.Window.small)
    ns.Safe("farms", ns.Farms.Place, view, camera == ns.Window.small) -- the places to farm a thing (Farms.lua)
    ns.Safe("route", ns.Route.Place, view)
    ns.Safe("paths", ns.Paths.Place, view)
    ns.Safe("drawings", ns.Draw.Place, view, camera == ns.Window.small) -- your drawings (Draw.lua)
    ns.Safe("pins", ns.PinView.Place, view, camera == ns.Window.small)
    ns.Safe("marks", ns.Marks.Pin, view)
    ns.Safe("marks", ns.Marks.Vias, view)
    ns.Safe("marks", ns.Marks.Group, view) -- at once at the new zoom, their size too
end

-- The player's place in the holder's units while it is on the view's plane (map, u, v from Live.Player), else nil.
local function Here(map, u, v)
    if not u or map ~= view.map then return nil end
    return (u - view.u) * view.k, (v - view.v) * view.k
end

-- The game's minimap for the view as it is now; on the full map, on the player at once. Out of sight under a
-- dungeon's whole map on the small view (whole).
local function Native()
    if whole then return ns.Guarded(ns.Hybrid.Hide) end
    local width, height = frame:GetSize()
    ns.Guarded(ns.Hybrid.Place, camera, width, height, known, lost)
    local map, u, v = Live.Player()
    ns.Guarded(ns.Hybrid.Follow, holder, Here(map, u, v))
end

-- The layers' frame levels from the canvas' own. Where our map has no land the game's minimap keeps its own ground
-- (Hybrid.Place), and that hides what stands under it: the route stands over it there.
local function Stack()
    local base = frame:GetFrameLevel()
    holder:SetFrameLevel(base + Canvas.LEVELS.holder)
    for name, layer in pairs(layers) do layer:SetFrameLevel(base + Canvas.LEVELS[name]) end
    if not ns.Terrain.Possible() then
        layers.route:SetFrameLevel(base + Canvas.OVER_GROUND)
        layers.paths:SetFrameLevel(base + Canvas.OVER_GROUND)
    end
    ns.PinView.Stack(base + Canvas.LEVELS.pins)
    ns.Marks.Stack(base + Canvas.LEVELS.marks)
    ns.Satchel.Stack(base + Canvas.LEVELS.satchel)
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
    view.shown, view.box, view.layer = camera.shown, camera.shown and camera.box or nil, camera.layer
    view.zone = Zone()
    view.span = height / camera.k
    view.left, view.right, view.top, view.bottom = camera:View(math.max(width, height) * Canvas.MARGIN)
    holder:SetScale(1)
    holder:SetPoint("CENTER", 0, 0)
    Bounds(0, 0, 1)
    laid, spun = true, false
    overX = nil -- the highlight is placed anew around the new origin
    nextZone, zoneOwed = GetTime() + Canvas.LOOK, false -- the zone in the middle was just asked
    local _, u = Live.Player()
    lost = Lost(u)
    whole = camera == ns.Window.small and ns.Guarded(ns.Dungeons.Small, lost) or false
    Stack()
    Draw()
    Native()
    ns.Safe("bar", ns.TopBar.Update)
end

-- The camera moved without zooming: the holder follows; past the margin, or over another zone, a layout. The
-- zone in the middle is asked of the game every Canvas.LOOK while the view moves, not at each of its steps.
function Canvas.Moved()
    if not laid or camera.k ~= view.k or camera.map ~= view.map or camera.level ~= view.level or camera.shown ~= view.shown then
        return Canvas.Layout()
    end
    local x, y = (view.u - camera.u) * view.k, (view.v - camera.v) * view.k
    local width, height = frame:GetSize()
    local margin = math.max(width, height) * Canvas.MARGIN
    if math.abs(x) > margin or math.abs(y) > margin then return Canvas.Layout() end
    if view.level == "zone" then
        local now = GetTime()
        if now >= nextZone then
            nextZone, zoneOwed = now + Canvas.LOOK, false
            if Zone() ~= view.zone then return Canvas.Layout() end
        else
            zoneOwed = true -- asked once the Canvas.LOOK has passed, should the view stop meanwhile (Track)
        end
    end
    holder:SetPoint("CENTER", x, y)
    if math.abs(x - edge.x) >= Canvas.REFIT or math.abs(y - edge.y) >= Canvas.REFIT then
        Bounds(x, y, 1)
        Keep()
    end
end

-- Drawn anew as it is, if it is laid out (the view chosen changed, data arrived, the game's minimap's zoom). Not
-- on the window's way, nor while hidden (held): the camera then is the one of the view it leaves (Morph), and a
-- layout would end the map's way with the window. Nothing asked for is lost: the hold ends only where the window
-- stands, and that lays the map out anew (Open).
function Canvas.Refresh()
    if laid and not held then Canvas.Layout() end
end

-- Whether our map is drawn: laid out (shown, not let go), and not standing aside for the game's minimap in an
-- instance (lost).
function Canvas.Laid()
    return laid and not lost
end

-------------------------------------------------------------------------------
--  The player
-------------------------------------------------------------------------------
-- Whether a view that does not follow the player follows again, never with a mouse button held on it (u: the
-- player's place, nil where the game tells none; walked: it changed since the last look). Where the game tells none
-- the small view does at once, ticked or not: the game's minimap is the map there. Else only with the box Follow me
-- ticked: the small view as soon as the player walks, the full map as the player walks once the mouse has left it
-- alone for Canvas.AGAIN.
local function Again(now, u, walked)
    if pressed then return false end
    local small = camera == ns.Window.small
    if small and u == nil then return true end
    if not (ns.options.followMap and u and walked) then return false end
    return small or now - lastInput > Canvas.AGAIN
end

local function Track()
    local now = GetTime()
    if not camera.follow and now < nextLook then return end
    nextLook = now + Canvas.LOOK
    -- A zone the view's last moves owe (Moved): asked now that the Canvas.LOOK has passed, so a drag or a walk that
    -- ended within it does not leave the zone shown stale.
    if zoneOwed and now >= nextZone then
        nextZone, zoneOwed = now + Canvas.LOOK, false
        if laid and view.level == "zone" and Zone() ~= view.zone then return Canvas.Layout() end
    end
    local map, u, v, facing = Live.Player()
    local walked = u ~= seenU or v ~= seenV
    seenU, seenV = u, v
    local was, followed = known, camera.follow
    known = u ~= nil and map == camera.map
    if Lost(u) ~= lost then return Canvas.Layout() end -- into an instance or out of it: drawn anew (Draw, Hybrid)
    if camera.follow and u then
        -- Into the player's plane; one map at a time, also onto the map the player is on now (another zone).
        if map ~= camera.map or camera.shown and camera:Wants() ~= camera.shown then
            camera:Show(map, u, v)
            return Canvas.Layout()
        elseif u ~= camera.u or v ~= camera.v then
            camera:Look(u, v)
            Canvas.Moved()
        end
    elseif not camera.follow and Again(now, u, walked) then
        -- The next look puts the player in the middle; in an instance (no place) the game's minimap comes back.
        camera.follow = true
        nextLook = 0
    end
    if was ~= known or followed ~= camera.follow then Native() end
    ns.Hybrid.Follow(holder, Here(map, u, v))
    -- Our arrow in both views, over the game's minimap (the game's own arrow on it shows only at times).
    ns.Marks.Player(view, map, u, v, facing)
    if not lost then ns.Marks.Group(view, now) end -- in an instance the game's minimap shows the party itself
    ns.Route.Track(map, u, v, now)
    if laid and not lost then ns.Indoors.Track(view, now) end
end
local tracking = ns.Guard(Track) -- made once

-------------------------------------------------------------------------------
--  The mouse
-------------------------------------------------------------------------------
local pressX, pressY, lastX, lastY, moved
-- A drag of the golden line or of a waypoint (Route.Grab, Marks.Vias), in place of the map's: key (the stage of the
-- line pressed: a new waypoint goes on it, Planner.Via), via (the waypoint moved), from and to (the stages the faint
-- lines run from and to, Route.Bend); nil while a drag is the map's.
local grab

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

-- The mouse in the plane of the view (the camera's map), from the canvas' middle (FromMiddle); nil off it.
local function Pointed(x, y)
    if not x or camera.map ~= view.map then return nil end
    return camera.u + x / camera.k, camera.v + y / camera.k
end

-- A press on the golden line on the full map, the map not whole on the screen (not at the world) and no modifier
-- held (Ctrl and a click, Shift and a click are the map's): a drag of it puts a waypoint where it is let go. The
-- line under the mouse as drawn (Route.Grab); nil where none is.
local function Grab()
    if camera ~= ns.Window.full or lost or not laid or camera.level == "world" or IsModifierKeyDown() then return nil end
    local u, v = Pointed(FromMiddle())
    local key = u and ns.Route.Grab((u - view.u) * view.k, (v - view.v) * view.k)
    return key and { key = key, from = key, to = key } or nil
end

-- The line or a waypoint dragged: where the waypoint would go, the faint lines to it.
local function Bend()
    local u, v = Pointed(FromMiddle())
    if not u then return end
    ns.Safe("route", ns.Route.Bend, (u - view.u) * view.k, (v - view.v) * view.k, grab.from, grab.to)
    ns.Safe("marks", ns.Marks.Ghost, view, view.map, u, v)
end

-- The drag of the line or a waypoint over: its faint lines and ghost gone; let go (not dropped), the waypoint put
-- where the mouse is (Planner.Via).
local function Unbend(dragged, put)
    ns.Safe("route", ns.Route.Unbend)
    ns.Safe("marks", ns.Marks.Ghost, view, nil)
    local u, v = Pointed(FromMiddle())
    if put and u then ns.Safe("route", ns.Planner.Via, dragged.key, view.map, u, v, dragged.via) end
end

local function Drag()
    local x, y = Cursor()
    if not moved then
        if math.abs(x - pressX) + math.abs(y - pressY) < Canvas.DRAG then return end
        moved, lastX, lastY = true, pressX, pressY
        if not grab then
            known = false
            Native() -- the game's minimap goes: the view no longer follows
        end
    end
    if x == lastX and y == lastY then return end
    if grab then
        lastX, lastY = x, y
        lastInput = GetTime()
        return Bend()
    end
    camera:Pan(x - lastX, y - lastY)
    lastX, lastY = x, y
    lastInput = GetTime()
    Canvas.Moved()
end
local dragging = ns.Guard(Drag) -- made once: the per-frame step while the left button is held

-- own: the press is the canvas' own (not a pin's or a mark's, Canvas.Press): on the golden line, a drag of it. While
-- a tool of the palette is on (Draw.lua) the left button is the tool's, and a drag with the right one moves the map.
local function Down(own, button)
    if held then return end -- on the window's way: its camera is not the one shown (Morph), no drag nor click
    lastInput = GetTime()
    if grab then Unbend() end -- another button during a drag of the line: that drag ends, nothing put
    local tool = own and not lost and ns.Draw.Tool()
    if tool and button == "LeftButton" then
        pressed = nil
        return ns.Draw.Press()
    end
    pressed, moved = button, false
    pressX, pressY = Cursor()
    grab = own and button == "LeftButton" and Grab() or nil
    if button == "LeftButton" or (tool and button == "RightButton") then frame:SetScript("OnUpdate", dragging) end
end

-- Where the game's map pin goes for the mouse at x, y from the view's middle: on the zone there, else the continent
-- (as the game's map puts it on the map it shows); at the world, and off the view's continent closer in (the other
-- one beside it), on the continent (or the plane of its own) under the mouse. { map, x, y } (PinView.Drop takes it),
-- or { } where there is none.
local function Where(x, y)
    local u, v = camera.u + x / camera.k, camera.v + y / camera.k
    local plane, own = camera.map, camera.box
    local off = own and not (u >= own.u and u <= own.u + own.width and v <= own.v and v >= own.v - own.height)
    if camera.level == "world" or off then
        local under = Coords.PlaneAt(camera.map, u, v)
        local link = under and Coords.Link(camera.map, under)
        if link then
            plane, u, v = under, link.du + link.su * u, link.dv + link.sv * v
        elseif camera.level == "world" then
            return {}
        end
    end
    local map = Coords.ZoneAt(plane, u, v) or plane
    local box = Coords.Box(map) -- (a zone the game gives no world position for has none: no place to pin there)
    if not box then return {} end
    local mapX, mapY = Coords.ToMap(box, u, v)
    return { map = map, x = mapX, y = mapY }
end

-- A plain click on a map the view shows whole: the zone under the mouse at a continent, the continent (or the
-- plane of its own) at the world, fills the view, as a click on the game's map opens it; one map at a time
-- (Retail), the map the game says is under the mouse on the map shown, at every level (camera:Under). False where
-- nothing is opened.
local function Into(x, y)
    local u, v = camera.u + x / camera.k, camera.v + y / camera.k
    local map
    if camera.shown then
        map = camera:Under(u, v)
    elseif camera.level == "zone" then
        return false
    elseif camera.level == "world" then
        map = Coords.PlaneAt(camera.map, u, v)
    else
        map = Coords.ZoneAt(camera.map, u, v)
    end
    if not map or not camera:Fit(map) then return false end
    ns.Art.Unlight()
    Canvas.Layout()
    return true
end

-- The press is over: true when it was a click (not a drag, the button that was pressed; not on a waypoint's mark). A
-- drag of the line or a waypoint puts the waypoint where it is let go.
local function Finish(button)
    frame:SetScript("OnUpdate", nil)
    if button ~= pressed then return false end
    pressed = nil
    lastInput = GetTime()
    local dragged = grab
    grab = nil
    if dragged then Unbend(dragged, moved) end
    if moved then
        moved = false
        return false
    end
    return not (dragged and dragged.via)
end

-- The last plain left click, for a double click: when, where the mouse was (from the view's middle), and what the
-- map pin goes on then: the pin clicked, else the place on the map as it was (Where).
local last

-- A click on the map, or on a pin (pin: its record, PinView.lua). The right button steps one map out; Ctrl and the
-- left puts the game's map pin there. Two plain left clicks on the same (a pin, or the map) within Canvas.DOUBLE,
-- near each other: the map pin where the first was (the view may have changed in between). One: the pin's own
-- (PinView.Act), else the map under the mouse opens, else a ping there, at once (Ping.Send: so the first click of a
-- double click pings too). In an instance our map is not drawn: no place to pin, the game's minimap pings itself.
local function Clicked(button, pin)
    if button == "MiddleButton" then
        last = nil
        return Canvas.Home()
    end
    local x, y = FromMiddle()
    if not x then return end
    if button == "RightButton" then
        last = nil
        if ns.Markers.Moving() then return ns.Markers.Stay() end -- (a marker waiting for its place stays)
        if camera:StepOut() then Canvas.Layout() end
        return
    end
    if button ~= "LeftButton" then return end
    -- Your markers (Markers.lua): Alt and a click puts a new one there; one waiting for its new place goes there.
    if not pin and (IsAltKeyDown() or ns.Markers.Moving()) then
        last = nil
        if lost then return end
        if ns.Markers.Moving() then return ns.Markers.Put(Where(x, y)) end
        return ns.Markers.New(Where(x, y))
    end
    if IsControlKeyDown() then
        last = nil
        if not lost then ns.PinView.Drop(pin or Where(x, y)) end
        return
    end
    local now = GetTime()
    if last and last.pin == pin and now - last.at < Canvas.DOUBLE
        and math.abs(x - last.x) + math.abs(y - last.y) <= Canvas.NEAR then
        local first = last
        last = nil
        -- (a flight point's or dock's ways the first click kept drawn: let go again, the double click pins only)
        if first.kept then ns.Safe("paths", ns.Paths.Toggle, first.pin) end
        if not lost then ns.PinView.Drop(first.pin or first.spot) end
        return
    end
    -- Shift and a click is a pin's own (a map opened), never half of a double click.
    last = not IsShiftKeyDown() and { at = now, x = x, y = y, pin = pin, spot = not lost and Where(x, y) } or nil
    local was = pin and ns.Paths.Active(pin)
    if pin and ns.PinView.Act(pin) then
        if last and ns.Paths.Active(pin) ~= was then last.kept = true end
        return
    end
    if lost then return ns.Hybrid.Ping(x, y) end
    if Into(x, y) then return end
    ns.Ping.Send(camera.map, camera.u + x / camera.k, camera.v + y / camera.k)
end

local function Up(_, button)
    if button == "LeftButton" and ns.Draw.Busy() then return ns.Draw.Release() end -- (a drawing let go)
    if Finish(button) then Clicked(button) end
end

-- The mouse on the map now (Draw.lua): its point in the view's plane and the spot under it ({ map, x, y }, as the
-- game's map pin would go there; { } where none); nil off the map or before it was laid out.
function Canvas.Under()
    local x, y = FromMiddle()
    if not x or not laid then return nil end
    local u, v = Pointed(x, y)
    if not u then return nil end
    return u, v, Where(x, y)
end

-- A pin was pressed (PinView.lua): the map takes the press as its own, so a drag that starts on a pin moves
-- the map. Let go: a drag is the map's; a click as on the map, but the pin's own first (Clicked). A waypoint's mark
-- (via: its waypoint, Marks.Vias) pressed with the left button: a drag of it moves the waypoint, small or full.
function Canvas.Press(button, via)
    Down(nil, button)
    if via and button == "LeftButton" and pressed and not lost and laid and camera.level ~= "world" then
        grab = { via = via, key = via, from = via, to = ns.Planner.After(via) }
    end
end

function Canvas.Release(button, pin)
    if Finish(button) then Clicked(button, pin) end
end

-- Zooms in around a point of the view's plane (a gathered marker clicked), by notches of the wheel.
function Canvas.ZoomTo(u, v, notches)
    if not laid then return end
    camera.follow = false
    camera:Look(u, v)
    camera:ZoomAt(notches, 0, 0)
    Canvas.Layout()
end

-- Looks at a point of a map (x, y: 0 to 1 on it; a quest chosen in the quest log): there in the middle, at the zoom
-- the view has, in its plane; one map at a time, that map shown whole first. The view no longer follows, as after a
-- drag. A dungeon's map over the full map goes. False where the map has no place on our planes.
function Canvas.LookAt(map, x, y)
    if not laid or held or lost then return false end
    local plane = Coords.PlaneOf(map)
    local u, v
    if plane and x and y then u, v = Coords.MapToPlane(map, x, y, plane) end
    if not u then return false end
    if camera.shown and not camera:Fit(map) then return false end
    ns.Dungeons.Close()
    camera.follow = false
    lastInput = GetTime()
    if plane == camera.map then camera:Look(u, v) else camera:Show(plane, u, v) end
    Canvas.Layout()
    return true
end

-- A view on the player and following (the full map opened with its box Follow me ticked): at once where the game
-- tells the player's place, else from the tracker's next look.
function Canvas.Center(viewCamera)
    viewCamera.follow = true
    local map, u, v = Live.Player()
    if not u or not viewCamera.map then return end
    if map == viewCamera.map then viewCamera:Look(u, v) else viewCamera:Show(map, u, v) end
end

-- The middle button: the view back on the player and following, near enough for the game's minimap's dots
-- (Hybrid.Home: the small view at its middle step, the full map where that step's square takes Hybrid.ROOM of it;
-- where the game's minimap is not ours, Canvas.HOME yards across the view's shorter side). One map at a time
-- (Retail), the map the player is on. A dungeon's map over the full map goes.
function Canvas.Home()
    if not laid or held then return end
    local width, height = frame:GetSize()
    lastInput = GetTime()
    camera.follow = true
    if not ns.Hybrid.Home(camera, width, height) then
        camera.native, camera.k = nil, math.min(width, height) / Canvas.HOME
    end
    local map, u, v = Live.Player()
    if u and (map ~= camera.map or camera.shown and camera:Wants() ~= camera.shown) then
        camera:Show(map, u, v, camera.k)
    elseif u then
        camera:Look(u, v, camera.k)
    end
    ns.Dungeons.Close()
    nextLook = 0
    Canvas.Layout()
end

-- The full map's box Follow me ticked or not (TopBar.lua, the settings): ticked, on the player at once and following;
-- not, it stays where it is and no longer follows.
function Canvas.Following()
    local full = ns.Window.full
    if ns.options.followMap then Canvas.Center(full) else full.follow = false end
    if camera == full and laid and not held then
        nextLook = 0
        Canvas.Layout()
    end
end

-- Shows a map whole (a pin that leads into another map), as a click on a zone does; a dungeon's on the full map
-- in its own view (Dungeons.lua).
function Canvas.Show(map)
    if ns.Dungeons.Show(map) then return true end
    if not laid or not camera:Fit(map) then return false end
    lastInput = GetTime()
    Canvas.Layout()
    return true
end

-- The wheel's notches, at most one layout a frame however fast it spins: the first notch of a frame is laid out at
-- once (a single notch is never later), the others of that frame are only added up in the camera and laid out once,
-- on the next frame (Spin); a layout meanwhile for another reason takes them along.
local wheeling = false -- a frame's layout of the notches was done: the next notches wait for Spin
local Spin
Spin = Core.Later(function()
    if spun and laid and not held then
        Canvas.Layout() -- the notches added up; it clears spun
        return Spin() -- this frame had its layout: a notch now waits for the next
    end
    wheeling = false
end)

local function Zoomed()
    if wheeling then
        spun = true
        return
    end
    wheeling = true
    Spin()
    Canvas.Layout()
end

local function Wheel(_, delta)
    if held then return end -- on the window's way: its camera is not the one shown (Morph)
    lastInput = GetTime()
    local width, height = frame:GetSize()
    -- In a dungeon, out past the game's widest step: the dungeon's whole map, where we have one (Dungeons.Whole).
    if lost and delta < 0 and camera.native == 0 and ns.Dungeons.Whole() then return Canvas.Layout() end
    if (known or lost) and ns.Hybrid.Wheel(camera, delta, ns.Hybrid.Side(width, height)) then
        camera:Settle()
        return Zoomed()
    end
    local x, y = FromMiddle()
    if not x then return end
    camera:ZoomAt(delta, x, y)
    Zoomed()
end

-- While the mouse is over the canvas: what a click would open lights up, looked at again when the mouse
-- moved, and the window's grip is seen (Window.Hovered). A button held, the window on its way: nothing
-- lights up. Off the canvas the look stops.
local function Over()
    if not frame:IsMouseOver() then
        hover:SetScript("OnUpdate", nil)
        overX = nil
        ns.Window.Hovered(false)
        return ns.Art.Unlight()
    end
    if pressed or held or lost or not laid then
        overX = nil
        return ns.Art.Unlight()
    end
    local x, y = FromMiddle()
    if not x or (x == overX and y == overY) then return end
    overX, overY = x, y
    if view.level == "zone" and not view.shown then return ns.Art.Unlight() end
    ns.Art.Light(view, camera.u + x / camera.k, camera.v + y / camera.k)
end
local hovering = ns.Guard(Over) -- made once: the look while the mouse is over the canvas

local function Entered()
    hover:SetScript("OnUpdate", hovering)
    ns.Window.Hovered(true)
end

-- A drag ends when the canvas goes (the window on its way, hidden).
local function Gone()
    frame:SetScript("OnUpdate", nil)
    pressed, moved = nil, false
    if grab then
        grab = nil
        Unbend()
    end
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
    -- The sea's layers, under every layer of the map (their frames stand over the holder), in their order.
    waves = {}
    for index, spec in ipairs(Canvas.SEA_LAYERS) do
        local texture = holder:CreateTexture(nil, "BACKGROUND", nil, index - 8)
        texture:Hide()
        if texture:SetTexture(spec.file, "REPEAT", "REPEAT") ~= false then -- a file missing: that layer is left out
            texture:SetVertexColor(spec.colour[1], spec.colour[2], spec.colour[3])
            texture.layer = index
            waves[#waves + 1] = { texture = texture, spec = spec }
        end
    end
    local spec = Canvas.WHIRLPOOL -- over the waves and their shade
    whirl = spec and holder:CreateTexture(nil, "BACKGROUND", nil, #Canvas.SEA_LAYERS - 7) or nil
    if whirl then
        whirl:Hide()
        if whirl:SetTexture(spec.file, "CLAMP", "CLAMP", "TRILINEAR") == false then
            whirl = nil -- the file missing: no whirlpool
        else
            whirl:SetVertexColor(spec.colour[1], spec.colour[2], spec.colour[3])
        end
    end
    layers = { terrain = ns.Terrain.Build(holder) }
    layers.art, layers.light = ns.Art.Build(holder)
    layers.indoors = ns.Indoors.Build(holder)
    layers.areas, layers.route = ns.Areas.Build(holder), ns.Route.Build(holder)
    layers.farms = ns.Farms.Build(holder)
    layers.sketch = ns.Draw.Build(holder)
    layers.paths = ns.Paths.Build(holder)
    ns.PinView.Build(holder)
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
        local drawn = Canvas.Laid() -- laid out, and not standing aside for the game's minimap (an instance)
        if what == "waypoint" then
            if drawn then ns.Marks.Pin(view) end
            -- The game's arrow may lead to another quest now: its pins (the game's alone) and area.
            ns.Pins.Changed("waypoint")
            if drawn then ns.Safe("pins", ns.PinView.Place, view, camera == ns.Window.small) end
            if drawn then ns.Safe("areas", ns.Areas.Place, view, camera == ns.Window.small) end
        elseif what == "explored" then
            ns.Pins.Changed(what)
            Canvas.Refresh() -- the map's art shows what is explored
        elseif ns.Pins.Changed(what) and drawn then
            -- The pins only ("zone" too: a burst of them comes at each new part of a building), not the whole map.
            ns.Safe("pins", ns.PinView.Place, view, camera == ns.Window.small)
            if what == "quests" then ns.Safe("areas", ns.Areas.Place, view, camera == ns.Window.small) end
        end
    end)
    return frame
end

-- Whether the map takes the mouse: off while the window rests out of sight, so the game's own minimap under it
-- takes it (Window.lua).
function Canvas.Mouse(on)
    if not frame then return end
    frame:EnableMouse(on)
    frame:EnableMouseWheel(on)
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
    lastInput = GetTime()
    if not viewCamera.map then
        local home = Coords.PlaneOf(map) or Coords.Continents()[1]
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

-- Where a view looks, as plain numbers: its plane, middle, zoom, size and level; one map at a time, the map shown,
-- its box and its art's layer.
local function Spot(from)
    return { map = from.map, u = from.u, v = from.v, k = from.k, width = from.width, height = from.height,
             level = from.level, shown = from.shown, box = from.shown and from.box or nil, layer = from.layer }
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
    view.shown, view.box, view.layer = b.shown, b.box, b.layer
    view.zone = wide.level == "zone" and (b.shown or Coords.ZoneAt(b.map, wide.u, wide.v)) or nil
    view.span = wide.height / wide.k
    view.left, view.right = math.min(l1, l2), math.max(r1, r2)
    view.top, view.bottom = math.max(t1, t2), math.min(b1, b2)
    laid, lost = true, false -- on the way our map goes with the window; where it stands, Layout looks again
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
    local x, y = (view.u - now.u) * now.k / scale, (view.v - now.v) * now.k / scale
    holder:SetScale(scale)
    holder:SetPoint("CENTER", x, y)
    Bounds(x, y, scale)
    Keep()
end

-- Hidden: every texture let go, nothing runs. Where the cameras looked is kept for the next time.
function Canvas.Close()
    if not frame then return end
    Canvas.Hold()
    laid, morph = false, nil
    Empty()
end
