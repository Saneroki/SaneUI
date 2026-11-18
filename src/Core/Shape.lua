local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Shape
--  The plate a window stands on: a fill with round corners, and a thin trim
--  along its edge that follows their round. How round is a setting of the
--  window's (Shape.Options):
--    Corner radius        a share of half the window's shorter side at rest
--                         (its size in its zone, not the size it grows to), so
--                         at 100 % a square window is a circle; 0 is square.
--    Don't round corners on screen edges   (on at first) a corner on the
--                         screen's edge is square and the trim is out of the
--                         screen there: the window is one with that edge, as
--                         if it grew out of it. Off, every corner is round,
--                         wherever it is.
--
--      local shape = Shape.New(host, settings, rect)
--          host       the frame its textures are drawn in, on its BACKGROUND layer
--          settings   a table with those two switches, read at every Fit (a module's
--                     settings); nil: as they are at first (Shape.DEFAULTS); or
--                     { radius = 8 }: every corner that round, in UI units, wherever it is
--                     (a chat's bubble); trim = its trim's width in UI units (Shape.TRIM at first)
--          rect       the frame whose place it fills; nil: host
--      shape:Look(look)     -- look = { file = a tile, size = its size in UI units (or no file: a
--                           -- colour), top = { r, g, b }, bottom = { r, g, b } (the fill's gradient),
--                           -- alpha = how solid the fill is (1: solid), trim = { r, g, b } (or none) }
--      shape:Fit(left, bottom, width, height)  -- laid out for that place (from the screen's lower left
--                           -- corner); without: where its frame is now, or else where it last was
--      shape:Follow()       -- laid out anew whenever its frame's size changes (a plate that lives in a
--                           -- frame of its own: what it needs is its size)
--      shape:Base(width, height)   -- the size its corners are measured on; nil: its size at each Fit
--      shape:Flatten(share)        -- that share of the way to square (0: as set, 1: square; at the next
--                                  -- Fit): a window filling the screen ends square, its trim out of sight
--      shape:SetAlpha(fill, trim)  shape:SetShown(on)
--      Shape.Round(texture)        -- a round mask of the same circle over the texture (an icon); returns it
--
--  How it is drawn. A mask is stretched whole (Tooltips found it: no slice
--  margins) and a texture takes three at most, so each corner is a square piece
--  of its own, cut by a circle (Art/circle, made by dev/tools/shape-art) twice
--  the corner's radius wide on the arc's centre; the rest of the fill is up to
--  five strips that leave the corners out. All are painted alike, so they meet
--  without a seam: the gradient's colours at their own top and bottom, or the
--  tile where they lie (its coordinates counted from the window's top left
--  corner). The trim lies over the fill: a strip along each side between its
--  corners, and in each round corner the arc, the corner's piece in the trim's
--  colour cut by the same circle and by a hole (Art/circle-hole) the trim's
--  width smaller; it is made only for a look that has one. Without the masks
--  (the files not found) every corner is square.
--
--  Each corner's radius is its own. With the switch on it is no larger than its
--  gaps to the screen's edges, so a corner that comes to an edge flattens out on
--  the way there, and a side's trim slides out of the screen: nothing jumps
--  while a window grows to fill the screen (Edge.lua). A window that fills the
--  screen is never round, whatever the switches say: on its way there it
--  flattens (Flatten), every corner and the trim on the screen's edges with it.
-------------------------------------------------------------------------------
local Shape = {}
Core.Shape = Shape

Shape.TRIM = 2 -- the trim's width in UI units
Shape.CIRCLE = "Interface\\AddOns\\" .. ADDON .. "\\Art\\circle"
Shape.HOLE = "Interface\\AddOns\\" .. ADDON .. "\\Art\\circle-hole"
-- White rings as large as the picture, to sweep with the game's Cooldown widget (dev/tools/shape-art); the wide one
-- is the thicker band.
Shape.RING = "Interface\\AddOns\\" .. ADDON .. "\\Art\\ring"
Shape.RING_WIDE = "Interface\\AddOns\\" .. ADDON .. "\\Art\\ring-wide"
-- A bar's two ends (a nameplate's): masks a quarter of the bar's height wide, white but for the corners on
-- their outer side, round with that radius; laid over the bar's ends with CLAMPTOWHITE (dev/tools/shape-art).
Shape.CAP_LEFT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\cap-left"
Shape.CAP_RIGHT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\cap-right"
-- The top left corner of a plate whose edge fades out softly, drawn as a texture (Lore's talk): white, its alpha whole
-- inside a round corner and fading to nothing towards the picture's edges (half of it the fade, three eighths the
-- round); its last column and row are the straight edge's fade (dev/tools/shape-art).
Shape.SOFT_CORNER = "Interface\\AddOns\\" .. ADDON .. "\\Art\\soft-corner"
-- One corner of a rectangle cut round (dev/tools/shape-art): laid over that corner as large as the radius, wrapped with
-- white beyond it, it rounds that corner alone, at any radius, on a shape of any height.
Shape.CORNER = {
    TOPLEFT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\corner-tl",
    TOPRIGHT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\corner-tr",
    BOTTOMLEFT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\corner-bl",
    BOTTOMRIGHT = "Interface\\AddOns\\" .. ADDON .. "\\Art\\corner-br",
}
Shape.PORTRAIT = "Interface\\CharacterFrame\\TempPortraitAlphaMask" -- the game's round mask, should ours be missing
local WHITE = "Interface\\Buttons\\WHITE8X8"
local HOLLOW = 0.01 -- a hole too small to see: an arc no wider than the trim is a whole quarter disc

-- The two switches, as a window without settings of its own has them.
Shape.DEFAULTS = { corners = 10, squareEdges = true }
Shape.KEYS = { corners = true, squareEdges = true }

-- Puts the two switches into a module's (Core.Options) at that place of its list, in that tab, under
-- that parent switch (or none), and (header) as a section of their own.
function Shape.Options(list, at, tab, parent, header)
    local section = {
        { key = "corners", default = Shape.DEFAULTS.corners, min = 0, max = 100, step = 1, unit = "%", text = "Corner radius",
          header = header, headerTip = header and "How round the window is at its place: filling the screen, it is always square.",
          tip = "How round the window's corners are, as a share of half its shorter side at its size in its zone. 0 is square; at 100 a square window is a circle. Filling the screen, a window is always square." },
        { key = "squareEdges", default = Shape.DEFAULTS.squareEdges, text = "Don't round corners on screen edges",
          tip = "A corner that lies on the edge of the screen stays square, so the window is one with that edge. Off: every corner is round, wherever it is, until the window fills the screen." },
    }
    for index, option in ipairs(section) do
        option.tab, option.parent = tab, parent
        table.insert(list, at + index - 1, option)
    end
end

-- The corners, by the frame's names for them: whether at its left side, whether at its bottom.
local CORNERS = {
    { left = true, bottom = false }, -- TOPLEFT
    { left = false, bottom = false }, -- TOPRIGHT
    { left = true, bottom = true }, -- BOTTOMLEFT
    { left = false, bottom = true }, -- BOTTOMRIGHT
}
local STRIPS = 5 -- the fill: five strips, then the four corners' pieces (6 to 9)
local SIDES = 4  -- the trim: left, right, bottom, top, then the four arcs (5 to 8)

local methods = {}

local function Clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

-- A piece at x, y from the frame's lower left corner, that wide and high; nothing to see if it has no room.
local function Put(shape, piece, x, y, width, height)
    if not shape.shown or width <= 0 or height <= 0 then return piece:Hide() end
    piece:ClearAllPoints()
    piece:SetPoint("BOTTOMLEFT", shape.host, "BOTTOMLEFT", x, y)
    piece:SetSize(width, height)
    piece:Show()
end

-- The gradient's colour that share of the way up, from its bottom.
local function Tint(look, share)
    local top, bottom = look.top, look.bottom
    return CreateColor(bottom[1] + (top[1] - bottom[1]) * share, bottom[2] + (top[2] - bottom[2]) * share,
        bottom[3] + (top[3] - bottom[3]) * share, look.alpha or 1)
end

-- A piece of the fill from x0, y0 to x1, y1, in a fill that high: put there and painted for that place.
local function Fill(shape, index, x0, y0, x1, y1, height)
    local piece = shape.fills[index]
    Put(shape, piece, x0, y0, x1 - x0, y1 - y0)
    if x1 <= x0 or y1 <= y0 or not shape.shown then return end
    local look = shape.look
    if look.file then
        local size = look.size or 256
        piece:SetTexCoord(x0 / size, x1 / size, (height - y1) / size, (height - y0) / size)
    elseif shape.gradient then
        piece:SetGradient("VERTICAL", Tint(look, y0 / height), Tint(look, y1 / height))
    end
end

-- A mask centred at x, y from the frame's lower left corner, a circle of that radius (never none:
-- a mask of no size is no use to anyone).
local function Circle(shape, mask, x, y, radius)
    radius = math.max(radius, HOLLOW)
    mask:ClearAllPoints()
    mask:SetPoint("CENTER", shape.host, "BOTTOMLEFT", x, y)
    mask:SetSize(2 * radius, 2 * radius)
end

local function Lay(shape)
    local look, settings = shape.look, shape.settings
    if not look or not shape.width then return end
    local left, bottom = shape.left, shape.bottom
    local width, height = math.max(shape.width, 0), math.max(shape.height, 0)
    if width <= 0 or height <= 0 then return end

    -- Each corner's radius: the share of half the shorter side at rest, no more than half the shorter side
    -- now, and with the switch on no more than the gaps between that corner's sides and the screen's edges.
    local gapLeft, gapBottom = left, bottom
    local gapRight, gapTop = UIParent:GetWidth() - left - width, UIParent:GetHeight() - bottom - height
    local flat = shape.flat or 0
    local radius = tonumber(settings.radius)
    if not radius then
        local share = Clamp((tonumber(settings.corners) or 0) / 100, 0, 1)
        radius = share * math.min(shape.baseWidth or width, shape.baseHeight or height) / 2
    end
    radius = shape.square and 0 or math.max(radius, 0) * (1 - flat)
    local square, half, radii = settings.squareEdges, math.min(width, height) / 2, shape.radii
    for index, corner in ipairs(CORNERS) do
        local round = radius
        if square then
            round = math.min(round, math.max(corner.left and gapLeft or gapRight, 0),
                math.max(corner.bottom and gapBottom or gapTop, 0))
        end
        radii[index] = Clamp(round, 0, half)
    end
    local tl, tr, bl, br = radii[1], radii[2], radii[3], radii[4]

    -- The fill: strips from the bottom up, each leaving out the corners it is beside, then the corners.
    local low, lower = math.min(bl, br), math.max(bl, br)
    local high, higher = math.min(tl, tr), math.max(tl, tr)
    Fill(shape, 1, bl, 0, width - br, low, height)
    Fill(shape, 2, bl > low and bl or 0, low, width - (br > low and br or 0), lower, height)
    Fill(shape, 3, 0, lower, width, height - higher, height)
    Fill(shape, 4, tl > high and tl or 0, height - higher, width - (tr > high and tr or 0), height - high, height)
    Fill(shape, 5, tl, height - high, width - tr, height, height)
    for index, corner in ipairs(CORNERS) do
        local round = radii[index]
        local x = corner.left and 0 or width - round
        local y = corner.bottom and 0 or height - round
        Fill(shape, STRIPS + index, x, y, x + round, y + round, height)
        local centreX, centreY = corner.left and round or width - round, corner.bottom and round or height - round
        Circle(shape, shape.circles[index], centreX, centreY, round)
    end

    -- The trim: a strip along each side between its corners. With the switch on, a side that comes to the
    -- screen's edge pushes its strip out of the frame by as much as it is nearer than the trim is wide:
    -- at the edge the strip is out of the screen. Flattened, a side at the edge pushes it out as far as
    -- the shape is flat, whatever the switch. The strips across own a square corner, those up and down
    -- start after them.
    local trims = shape.trims
    if not look.trim then
        for _, piece in ipairs(trims) do piece:Hide() end
        return
    end
    local trim = tonumber(settings.trim) or Shape.TRIM
    for index = 1, #CORNERS do
        local corner = CORNERS[index]
        local round = radii[index]
        Circle(shape, shape.holes[index], corner.left and round or width - round, corner.bottom and round or height - round,
            round - trim)
    end
    local function Out(gap)
        local out = square and Clamp(trim - gap, 0, trim) or 0
        return gap <= 0 and math.max(out, flat * trim) or out
    end
    local outLeft, outRight, outBottom, outTop = Out(gapLeft), Out(gapRight), Out(gapBottom), Out(gapTop)
    local from = bl > 0 and bl or trim - outBottom
    local to = height - (tl > 0 and tl or trim - outTop)
    Put(shape, trims[1], -outLeft, from, trim, to - from)
    from = br > 0 and br or trim - outBottom
    to = height - (tr > 0 and tr or trim - outTop)
    Put(shape, trims[2], width - trim + outRight, from, trim, to - from)
    Put(shape, trims[3], bl, -outBottom, width - bl - br, trim)
    Put(shape, trims[4], tl, height - trim + outTop, width - tl - tr, trim)
    for index, corner in ipairs(CORNERS) do
        local round = radii[index]
        Put(shape, trims[SIDES + index], corner.left and 0 or width - round, corner.bottom and 0 or height - round, round, round)
    end
end

-- The trim's pieces, made for the first look that has a trim: the strips along the sides and the arcs,
-- each arc cut by its corner's circle and by a hole the trim's width smaller.
local function Trims(shape)
    if #shape.trims > 0 then return end
    local host = shape.host
    for index = 1, SIDES + #CORNERS do
        local piece = host:CreateTexture(nil, "BACKGROUND", nil, -7)
        piece:SetTexture(WHITE)
        shape.trims[index] = piece
    end
    for index = 1, #CORNERS do
        local hole = host:CreateMaskTexture()
        if hole:SetTexture(Shape.HOLE, "CLAMPTOWHITE", "CLAMPTOWHITE") and not shape.square then
            local arc = shape.trims[SIDES + index]
            arc:AddMaskTexture(shape.circles[index])
            arc:AddMaskTexture(hole)
        else
            shape.square = true
        end
        shape.holes[index] = hole
    end
end

-- How it looks: its tile or its gradient, how solid, and the trim's colour.
function methods:Look(look)
    self.look = look
    local top, bottom = look.top or { 0, 0, 0 }, look.bottom or look.top or { 0, 0, 0 }
    look.top, look.bottom = top, bottom
    local alpha = look.alpha or 1
    self.gradient = not look.file and (top[1] ~= bottom[1] or top[2] ~= bottom[2] or top[3] ~= bottom[3])
    for _, piece in ipairs(self.fills) do
        if look.file then
            piece:SetTexture(look.file, "REPEAT", "REPEAT")
            piece:SetVertexColor(1, 1, 1, alpha)
        else
            piece:SetTexture(WHITE)
            piece:SetTexCoord(0, 1, 0, 1)
            piece:SetVertexColor(bottom[1], bottom[2], bottom[3], alpha) -- the gradient, if any, is set by Fill
        end
    end
    local trim = look.trim
    if trim then
        Trims(self)
        for _, piece in ipairs(self.trims) do piece:SetVertexColor(trim[1], trim[2], trim[3], 1) end
    end
    Lay(self)
end

function methods:Fit(left, bottom, width, height)
    if left then
        self.left, self.bottom, self.width, self.height = left, bottom, width, height
    else
        local rect = self.rect
        local x, y = rect:GetLeft(), rect:GetBottom()
        if x and y then self.left, self.bottom, self.width, self.height = x, y, rect:GetWidth(), rect:GetHeight() end
    end
    Lay(self)
end

-- Its frame's size changed: laid out for it, at its place if it has one (a plate that is not by the
-- screen's edges needs only its size).
local function Followed(shape)
    local rect = shape.rect
    shape:Fit(rect:GetLeft() or 0, rect:GetBottom() or 0, rect:GetWidth(), rect:GetHeight())
end

function methods:Follow()
    self.rect:HookScript("OnSizeChanged", function() Core.Safe("shape", Followed, self) end)
end

function methods:Base(width, height)
    self.baseWidth, self.baseHeight = width, height
end

function methods:Flatten(share)
    self.flat = Clamp(share or 0, 0, 1)
end

function methods:SetAlpha(fill, trim)
    for _, piece in ipairs(self.fills) do piece:SetAlpha(fill) end
    for _, piece in ipairs(self.trims) do piece:SetAlpha(trim or fill) end
end

function methods:SetShown(on)
    self.shown = on and true or false
    if self.shown then return Lay(self) end
    for _, piece in ipairs(self.fills) do piece:Hide() end
    for _, piece in ipairs(self.trims) do piece:Hide() end
end

function Shape.New(host, settings, rect)
    local shape = setmetatable({ host = host, settings = settings or Shape.DEFAULTS, rect = rect or host, shown = true,
                                 fills = {}, trims = {}, circles = {}, holes = {}, radii = { 0, 0, 0, 0 } }, { __index = methods })
    for index = 1, STRIPS + #CORNERS do shape.fills[index] = host:CreateTexture(nil, "BACKGROUND", nil, -8) end
    for index = 1, #CORNERS do
        -- A mask carries its file before it is given to a texture. SetTexture says whether the game found it.
        local circle = host:CreateMaskTexture()
        if circle:SetTexture(Shape.CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") then
            shape.fills[STRIPS + index]:AddMaskTexture(circle)
        else
            shape.square = true
        end
        shape.circles[index] = circle
    end
    return shape
end

-------------------------------------------------------------------------------
--  A thing's bar, as the nameplates draw theirs (Saneroki, 2026-10-29 for the
--  loot window's lines; 2026-11-11: a quest's rewards "like the party roll
--  window", so rolling on loot and choosing a quest's reward look the same).
--  The game's shaded health fill (its raid frames') in a colour, its corners
--  round a quarter of its height (the caps), behind it a border of one screen
--  pixel, nearly black, round with it (the corner masks), grey under the mouse
--  as a nameplate's on your target, gold round a thing chosen. Its words in the
--  game's outlined font of its nameplates.
--
--      local bar = Shape.Bar(frame, height)   -- behind a frame of that height: bar:Paint(r, g, b), bar:SetLit(on),
--                                             -- bar:SetChosen(on); bar.fill, bar.inner (its fill's height), bar.pixel
--      Shape.Caps(texture, anchor, height)    -- a texture's two ends round as a bar of that height (a picture at a
--                                             -- bar's left end, a line over its foot)
--      Shape.BarFont(fontString, size)        -- the game's outlined nameplate font, size in 1080p pixels
--      Shape.Quality(quality), Shape.Gold()   -- a quality's colour, the game's gold
-------------------------------------------------------------------------------
Shape.FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill"
Shape.BAR_ROUND = 1 / 4                 -- a bar's corners round so much of its height
Shape.BAR_BORDER = { 0, 0, 0, 0.9 }     -- nearly black
Shape.BAR_LIT = { 0.5, 0.5, 0.5, 1 }    -- under the mouse
Shape.BAR_DARK = { 0.16, 0.16, 0.18 }   -- a bar of no thing
-- The game's font objects for its nameplates' names: their face and outline.
Shape.BAR_FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate" }

function Shape.Quality(quality)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and quality and colors[quality]
    if not color then return 1, 1, 1 end
    return color.r, color.g, color.b
end

-- The game's gold, as its quest things are marked.
function Shape.Gold()
    local gold = rawget(_G, "NORMAL_FONT_COLOR")
    if type(gold) == "table" and gold.r then return gold.r, gold.g, gold.b end
    return 1, 0.82, 0
end

-- The face and outline of the game's font for its nameplates (asked once); Core's bold font outlined where it has none.
local face
local function Face()
    if face then return face end
    for _, name in ipairs(Shape.BAR_FONTS) do
        local object = rawget(_G, name)
        local file, _, flags
        if type(object) == "table" and object.GetFont then file, _, flags = object:GetFont() end
        if type(file) == "string" then
            face = { name = name, file = file, flags = (flags and flags ~= "") and flags or "OUTLINE" }
            return face
        end
    end
    face = { file = Core.Look.FONT, flags = "OUTLINE" }
    return face
end

-- size: in 1080p pixels, as SaneUI's other words. On the game's font object, as Nameplates' Text.lua: its shadow is
-- the game's, none of ours.
function Shape.BarFont(fs, size)
    local look = Face()
    if look.name then fs:SetFontObject(look.name) end
    fs:SetFont(look.file, size * Core.Look.PX, look.flags)
end

-- Two caps over a texture laid at a region's two ends (anchor), rounding them as a bar of that height is rounded;
-- made on the texture's own frame, as a mask must be.
function Shape.Caps(texture, anchor, height)
    for _, side in ipairs({ "LEFT", "RIGHT" }) do
        local cap = texture:GetParent():CreateMaskTexture()
        cap:SetTexture(side == "LEFT" and Shape.CAP_LEFT or Shape.CAP_RIGHT, "CLAMPTOWHITE", "CLAMPTOWHITE")
        cap:SetPoint("TOP" .. side, anchor, "TOP" .. side)
        cap:SetPoint("BOTTOM" .. side, anchor, "BOTTOM" .. side)
        cap:SetWidth(math.max(height * Shape.BAR_ROUND, 0.01))
        texture:AddMaskTexture(cap)
    end
end

-- The border is a plate of two halves behind the fill, each round at its own two corners by the corner masks (a
-- texture takes three masks at most), so its round is the same at any width; the fill a screen pixel inside it, its
-- ends round by the two caps.
function Shape.Bar(frame, height)
    local bar = { lit = false, chosen = false }
    local pixel = Core.Pixels(frame, 1)
    local radius = height * Shape.BAR_ROUND
    bar.halves = {}
    for index, corners in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" } }) do
        local half = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        half:SetTexture(WHITE)
        half:SetPoint(corners[1], frame, corners[1])
        half:SetPoint(corners[2], frame, corners[2])
        half:SetHeight(height / 2)
        for _, corner in ipairs(corners) do
            local mask = frame:CreateMaskTexture()
            mask:SetTexture(Shape.CORNER[corner], "CLAMPTOWHITE", "CLAMPTOWHITE")
            mask:SetPoint(corner, half, corner)
            mask:SetSize(radius, radius)
            half:AddMaskTexture(mask)
        end
        bar.halves[index] = half
    end
    bar.fill = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    bar.fill:SetTexture(Shape.FILL)
    bar.fill:SetPoint("TOPLEFT", frame, "TOPLEFT", pixel, -pixel)
    bar.fill:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pixel, pixel)
    bar.inner = height - 2 * pixel
    bar.pixel = pixel
    Shape.Caps(bar.fill, bar.fill, bar.inner)
    local function Border()
        local colour = bar.lit and Shape.BAR_LIT or Shape.BAR_BORDER
        local r, g, b, a = colour[1], colour[2], colour[3], colour[4]
        if bar.chosen and not bar.lit then
            r, g, b = Shape.Gold()
            a = 1
        end
        for _, half in ipairs(bar.halves) do half:SetVertexColor(r, g, b, a) end
    end
    function bar.Paint(_, r, g, b)
        bar.colour = { r, g, b }
        bar.fill:SetVertexColor(r, g, b, 1)
    end
    function bar.SetLit(_, on)
        bar.lit = on and true or false
        Border()
    end
    function bar.SetChosen(_, on)
        bar.chosen = on and true or false
        Border()
    end
    bar:Paint(Shape.BAR_DARK[1], Shape.BAR_DARK[2], Shape.BAR_DARK[3])
    bar:SetLit(false)
    return bar
end

-- A round icon: a mask of the same circle over the whole texture (the game's round portrait mask where
-- ours is not found). Returns the mask.
function Shape.Round(texture)
    local mask = texture:GetParent():CreateMaskTexture()
    if not mask:SetTexture(Shape.CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") then
        mask:SetTexture(Shape.PORTRAIT, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    end
    mask:SetAllPoints(texture)
    texture:AddMaskTexture(mask)
    return mask
end
