local ADDON = ...
local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Shape
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
--                     settings); nil: as they are at first (Shape.DEFAULTS)
--          rect       the frame whose place it fills; nil: host
--      shape:Look(look)     -- look = { file = a tile, size = its size in UI units (or no file: a
--                           -- colour), top = { r, g, b }, bottom = { r, g, b } (the fill's gradient),
--                           -- trim = { r, g, b } (or none) }
--      shape:Fit(left, bottom, width, height)  -- laid out for that place (from the screen's lower left
--                           -- corner); without: where its frame is now, or else where it last was
--      shape:Base(width, height)   -- the size its corners are measured on; nil: its size at each Fit
--      shape:Flatten(share)        -- that share of the way to square (0: as set, 1: square; at the next
--                                  -- Fit): a window filling the screen ends square, its trim out of sight
--      shape:SetAlpha(fill, trim)  shape:SetShown(on)
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
--  width smaller. Without the masks (the files not found) every corner is square.
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
local WHITE = "Interface\\Buttons\\WHITE8X8"
local HOLLOW = 0.01 -- a hole too small to see: an arc no wider than the trim is a whole quarter disc

-- The two switches, as a window without settings of its own has them.
Shape.DEFAULTS = { corners = 10, squareEdges = true }
Shape.KEYS = { corners = true, squareEdges = true }

-- Puts the two switches into a module's (Core.Options) at that place of its list, in that tab, under
-- that parent switch (or none).
function Shape.Options(list, at, tab, parent)
    local section = {
        { key = "corners", default = Shape.DEFAULTS.corners, min = 0, max = 100, step = 1, unit = "%", text = "Corner radius",
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
        bottom[3] + (top[3] - bottom[3]) * share, 1)
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
    local share = shape.square and 0 or Clamp((tonumber(settings.corners) or 0) / 100, 0, 1)
    local flat = shape.flat or 0
    local radius = share * (1 - flat) * math.min(shape.baseWidth or width, shape.baseHeight or height) / 2
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
        Circle(shape, shape.holes[index], centreX, centreY, round - Shape.TRIM)
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
    local trim = Shape.TRIM
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

-- How it looks: its tile or its gradient, and the trim's colour.
function methods:Look(look)
    self.look = look
    local top, bottom = look.top or { 0, 0, 0 }, look.bottom or look.top or { 0, 0, 0 }
    look.top, look.bottom = top, bottom
    self.gradient = not look.file and (top[1] ~= bottom[1] or top[2] ~= bottom[2] or top[3] ~= bottom[3])
    for _, piece in ipairs(self.fills) do
        if look.file then
            piece:SetTexture(look.file, "REPEAT", "REPEAT")
            piece:SetVertexColor(1, 1, 1, 1)
        else
            piece:SetTexture(WHITE)
            piece:SetTexCoord(0, 1, 0, 1)
            piece:SetVertexColor(bottom[1], bottom[2], bottom[3], 1) -- the gradient, if any, is set by Fill
        end
    end
    local trim = look.trim
    if trim then
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
    for index = 1, SIDES + #CORNERS do
        local piece = host:CreateTexture(nil, "BACKGROUND", nil, -7)
        piece:SetTexture(WHITE)
        shape.trims[index] = piece
    end
    for index = 1, #CORNERS do
        -- A mask carries its file before it is given to a texture. SetTexture says whether the game found it.
        local circle, hole = host:CreateMaskTexture(), host:CreateMaskTexture()
        local found = circle:SetTexture(Shape.CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        found = hole:SetTexture(Shape.HOLE, "CLAMPTOWHITE", "CLAMPTOWHITE") and found
        if found then
            shape.fills[STRIPS + index]:AddMaskTexture(circle)
            shape.trims[SIDES + index]:AddMaskTexture(circle)
            shape.trims[SIDES + index]:AddMaskTexture(hole)
        else
            shape.square = true
        end
        shape.circles[index], shape.holes[index] = circle, hole
    end
    return shape
end
