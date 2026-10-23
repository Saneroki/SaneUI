local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Journal
--  Sane UI's own look (Doc/guides/interface-style.md): a book of cream paper
--  bound in thin stitched leather, everything on the paper drawn in pencil,
--  the words in Kalam. Built from the art's pieces (Art/Journal/, made by
--  dev/tools/journal-art), as the game draws them:
--    - the window: the top in three (its middle stretched between its ends),
--      the edges and the bottom repeated, the bottom corners mitred (masks)
--      under their metal caps, the clasp on the right edge; the paper cut to
--      the page, never stretched; it fits any size, so a window on Core's
--      board follows the lines dragged between the windows;
--    - pencil on the paper: a rule, a box (nine pieces, its corners whole),
--      an item's slot (one square box);
--    - leather: a button of the patch, its word pressed in;
--    - Kalam in graphite, as font objects and on font strings.
--
--  The pieces are drawn for 4K: one of their pixels is one of a 4K screen's
--  (2160 of them are the screen's 768 units at UI scale 1). Each texture holds
--  its piece at its top left (Journal.PIECES: the piece's size, the texture's).
--
--      local look = Journal.Dress(frame, title)   -- frame gets the window round it (any size)
--      look.content, look.title, look.close, look.head   -- the page's room, the title, the X, the top
--      Journal.Inner(width, height)       -- the page's room in a dressed frame that large
--      Journal.Outer(width, height)       -- the frame round a page's room that large
--      Journal.Paper(frame)               -- the page's paper alone, cut to frame
--      Journal.Rule(parent)               -- a pencil line (anchor its ends)
--      Journal.Box(frame, weight)         -- a pencil box round frame; box:SetStrong(on)
--      Journal.Slot(frame, out)           -- an item's pencil slot at frame's edge (icon inset SLOT_ICON)
--      Journal.Button(parent, text, onClick)   -- a leather patch, its word pressed in
--      Journal.Patch(frame, height)       -- the patch's leather behind a frame of that height
--      Journal.Font(fontString, size, bold, color, alpha)   -- Kalam (size in 1080p pixels)
--      Journal.FontObject(name, size, bold, flags)          -- a font object of Kalam in graphite
--      Journal.Press(fontString, size)    -- letters pressed into leather
--      Journal.Ink(r, g, b)               -- a game colour that reads on the paper (darkened)
-------------------------------------------------------------------------------
local Journal = {}
Core.Journal = Journal

local ART = "Interface\\AddOns\\SaneUI\\Art\\Journal\\"
Journal.ART = ART
Journal.FONT = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Regular.ttf"
Journal.FONT_BOLD = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Bold.ttf"
Journal.FONT_LIGHT = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Light.ttf"

-- A 4K pixel in units at UI scale 1; a 1080p pixel (the designs' unit) in units. The window's leather and its
-- page's margins are drawn at Journal.SCALE of their 4K size (never larger than the pieces are drawn for), so a
-- full screen of several windows keeps room for what they hold.
local U = 768 / 2160
Journal.UNIT = U
Journal.PX = 768 / 1080
Journal.SCALE = 0.8

-- Each piece: { its width, its height, its texture's width, height } (dev/tools/journal-art prints them).
Journal.PIECES = {
    ["frame-top-left"] = { 368, 248, 512, 256 },
    ["frame-top-middle"] = { 300, 248, 512, 256 },
    ["frame-top-right"] = { 612, 248, 1024, 256 },
    ["frame-left"] = { 88, 600, 128, 1024 },
    ["frame-right"] = { 88, 600, 128, 1024 },
    ["frame-bottom"] = { 600, 88, 1024, 128 },
    ["frame-clasp"] = { 100, 292, 128, 512 },
    ["frame-cap-left"] = { 132, 96, 256, 128 },
    ["frame-cap-right"] = { 132, 96, 256, 128 },
    ["paper"] = { 2048, 2048, 2048, 2048 },
    ["patch"] = { 256, 252, 256, 256 },
    ["pencil-box"] = { 338, 116, 512, 128 },
    ["pencil-rule"] = { 225, 12, 256, 16 },
    ["pencil-slot"] = { 116, 116, 128, 128 },
    ["stain-1"] = { 511, 484, 512, 512 },
    ["stain-2"] = { 380, 330, 512, 512 },
    ["sketch-map-1"] = { 420, 354, 512, 512 },
    ["sketch-tree-1"] = { 378, 448, 512, 512 },
    ["doll"] = { 1360, 1804, 2048, 2048 },
    ["trash"] = { 248, 248, 256, 256 },      -- the bags' waste bin, a pencil drawing
    ["arrow"] = { 64, 64, 64, 64 },          -- the sidebars' fold arrow, pencil, pointing down (code turns it)
}
local PIECES = Journal.PIECES

-- Where things stand on the window's pieces, in their pixels.
local EDGE = 88                 -- the edges' and the bottom's thickness
local TILE = 600                -- the edges' and the bottom's tile length
local TOP_H = 248               -- the top's height
local TOP_LEFT, TOP_RIGHT = 368, 612   -- its two ends' widths; the middle stretches between them
local HEAD = 40                 -- the edges start this far under the window's top (under the top's paper)
local RIGHT_IN = 40             -- the book ends this far before the window's right side (the top reaches further)
local BOX_W, BOX_H = 132, 96    -- a bottom corner's box: its cap, its mitre masks
local BOX_RIGHT = 168           -- the right corner's box starts this far from the window's right side
local CLASP_W, CLASP_H = 100, 292
local TITLE_X, TITLE_Y = 352, 192   -- the title's left middle on the label
local TITLE_END = 330               -- the label ends this far before the window's right side
local CLOSE_X, CLOSE_Y = 132, 76    -- the close patch's middle, from the right and the top
local STRAP = 128                   -- the strap's height: the top a window is dragged by
local PAGE = { 44, 188, 84, 44 }    -- the page's paper from the left, top, right and bottom
local CONTENT = { 104, 252, 144, 104 }   -- the content's room on the page: left, top, right, bottom

Journal.TONE = { 0.89, 0.854, 0.828 }    -- the paper piece times this is the page's tone (220, 204, 178)
Journal.INK = { 30 / 255, 23 / 255, 17 / 255 }        -- pencil on the paper
Journal.FAINT = { 30 / 255, 23 / 255, 17 / 255, 0.6 } -- pencil written lightly: counts, notes
Journal.LEATHER = { 200 / 255, 170 / 255, 128 / 255 } -- letters pressed into leather: tan, as title-text.png
Journal.LIT = { 238 / 255, 214 / 255, 172 / 255 }     -- a pressed word under the mouse
Journal.SHADE = { 30 / 255, 23 / 255, 17 / 255, 0.08 } -- a light pencil shading on the paper (a row under the mouse)
Journal.CHOSEN = { 30 / 255, 23 / 255, 17 / 255, 0.14 } -- a little more of it (a chosen row)

local function u(n) return n * U * Journal.SCALE end

-- A texture showing its piece's own pixels l..r, t..b (or the whole piece).
local function Coords(texture, piece, l, r, t, b)
    local p = PIECES[piece]
    texture:SetTexCoord((l or 0) / p[3], (r or p[1]) / p[3], (t or 0) / p[4], (b or p[2]) / p[4])
end
Journal.Coords = Coords

function Journal.Texture(parent, piece, layer, sub)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub)
    texture:SetTexture(ART .. piece)
    Coords(texture, piece)
    return texture
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
-- A strip of a repeated piece from a to b (units from the frame's top left) along one side, the tiles counted from
-- origin, its textures kept in the look's pool under key. Masks go on every texture of the strip. The tiles are
-- counted whole (never stepped by a remainder, which in floating point can come out a hair under a tile and stop
-- the strip from moving on), and no strip has more than Journal.MOST_TILES of them.
Journal.MOST_TILES = 64
local function Strip(look, key, piece, layer, across, width, a, b, vertical, origin, masks)
    local frame = look.frame
    local pool = look.strips[key] or {}
    look.strips[key] = pool
    local tile = u(TILE)
    local n = 0
    if b - a > 0.01 and b - a < tile * Journal.MOST_TILES then
        local first = math.floor((a - origin) / tile)
        local last = math.ceil((b - origin) / tile) - 1
        for i = first, last do
            local start = origin + i * tile
            local from, to = math.max(a, start), math.min(b, start + tile)
            if to - from > 0.01 then
                n = n + 1
                local t = pool[n]
                if not t then
                    t = frame:CreateTexture(nil, layer, nil, 0)
                    t:SetTexture(ART .. piece)
                    for _, m in ipairs(masks or {}) do t:AddMaskTexture(m) end
                    pool[n] = t
                end
                t:ClearAllPoints()
                local px = U * Journal.SCALE
                local c0, c1 = (from - start) / px, (to - start) / px
                if vertical then
                    t:SetPoint("TOPLEFT", frame, "TOPLEFT", across, -from)
                    t:SetSize(width, to - from)
                    Coords(t, piece, 0, EDGE, c0, c1)
                else
                    t:SetPoint("TOPLEFT", frame, "TOPLEFT", from, -across)
                    t:SetSize(to - from, width)
                    Coords(t, piece, c0, c1, 0, EDGE)
                end
                t:Show()
            end
        end
    end
    for i = n + 1, #pool do pool[i]:Hide() end
end

local function Mask(frame, piece)
    local m = frame:CreateMaskTexture()
    m:SetTexture(ART .. piece, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetSize(u(BOX_W), u(BOX_H))
    return m
end

-- The paper cut to its texture's frame: scaled up only when the frame is larger than the piece.
local function Cut(paper)
    local w, h = paper:GetSize()
    if not (w and h) or w <= 0 or h <= 0 then return end
    local pw, ph = w / (U * Journal.SCALE), h / (U * Journal.SCALE)
    local k = math.max(1, pw / PIECES.paper[1], ph / PIECES.paper[2])
    paper:SetTexCoord(0, pw / (PIECES.paper[3] * k), 0, ph / (PIECES.paper[4] * k))
end

-- The window laid out for the frame's size: the strips, the corners, the paper's cut.
local function Layout(look)
    local f = look.frame
    local w, h = f:GetSize()
    if not (w and h) or w <= 0 or h <= 0 then return end
    local boxTop = h - u(BOX_H)
    local span = w - u(RIGHT_IN)              -- the book's right end
    local rightBox = w - u(BOX_RIGHT)
    look.maskLeftEdge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    look.maskLeftBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    look.maskRightEdge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", rightBox, 0)
    look.maskRightBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", rightBox, 0)
    -- the edges from under the top to the corners' boxes, and on through them under their masks
    Strip(look, "left", "frame-left", "BORDER", 0, u(EDGE), u(HEAD), boxTop, true, u(HEAD))
    Strip(look, "leftCorner", "frame-left", "BORDER", 0, u(EDGE), boxTop, h, true, u(HEAD), { look.maskLeftEdge })
    Strip(look, "right", "frame-right", "BORDER", span - u(EDGE), u(EDGE), u(HEAD), boxTop, true, u(HEAD))
    Strip(look, "rightCorner", "frame-right", "BORDER", span - u(EDGE), u(EDGE), boxTop, h, true, u(HEAD),
        { look.maskRightEdge })
    -- the bottom from the left corner's box to the right one's, and through them under their masks
    Strip(look, "bottomLeft", "frame-bottom", "BORDER", h - u(EDGE), u(EDGE), 0, u(BOX_W), false, 0, { look.maskLeftBottom })
    Strip(look, "bottom", "frame-bottom", "BORDER", h - u(EDGE), u(EDGE), u(BOX_W), rightBox, false, 0)
    Strip(look, "bottomRight", "frame-bottom", "BORDER", h - u(EDGE), u(EDGE), rightBox, span, false, 0,
        { look.maskRightBottom })
    look.clasp:ClearAllPoints()
    look.clasp:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -(h - u(CLASP_H)) / 2)
    Cut(look.paper)
end

-- The least a dressed frame may be: the top's two ends side by side, the top and the bottom's corners.
Journal.LEAST = { u(TOP_LEFT + TOP_RIGHT), u(TOP_H + BOX_H) }

function Journal.Inner(width, height)
    return width - u(CONTENT[1] + CONTENT[3]), height - u(CONTENT[2] + CONTENT[4])
end

function Journal.Outer(width, height)
    return math.max(Journal.LEAST[1], width + u(CONTENT[1] + CONTENT[3])),
        math.max(Journal.LEAST[2], height + u(CONTENT[2] + CONTENT[4]))
end

-- Dresses a frame as a window of the journal (its size is the frame's, any size from Journal.LEAST). Returns the
-- look: look.content (the page's room), look.title (a font string on the label), look.close (the X on the
-- corner patch; its click is the caller's), look.head (a frame over the strap and the label, for dragging).
function Journal.Dress(frame, title)
    local look = { frame = frame, strips = {} }

    look.paper = frame:CreateTexture(nil, "BACKGROUND")
    look.paper:SetTexture(ART .. "paper")
    look.paper:SetPoint("TOPLEFT", frame, "TOPLEFT", u(PAGE[1]), -u(PAGE[2]))
    look.paper:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -u(PAGE[3]), u(PAGE[4]))
    look.paper:SetVertexColor(Journal.TONE[1], Journal.TONE[2], Journal.TONE[3])

    look.maskLeftEdge = Mask(frame, "frame-mitre-left-edge")
    look.maskLeftBottom = Mask(frame, "frame-mitre-left-bottom")
    look.maskRightEdge = Mask(frame, "frame-mitre-right-edge")
    look.maskRightBottom = Mask(frame, "frame-mitre-right-bottom")

    for _, side in ipairs({ "left", "right" }) do
        local cap = Journal.Texture(frame, "frame-cap-" .. side, "BORDER", 2)
        cap:SetSize(u(BOX_W), u(BOX_H))
        if side == "left" then
            cap:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        else
            cap:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -u(BOX_RIGHT), 0)
        end
    end

    look.clasp = Journal.Texture(frame, "frame-clasp", "ARTWORK", 0)
    look.clasp:SetSize(u(CLASP_W), u(CLASP_H))

    look.topLeft = Journal.Texture(frame, "frame-top-left", "ARTWORK", 1)
    look.topLeft:SetSize(u(TOP_LEFT), u(TOP_H))
    look.topLeft:SetPoint("TOPLEFT")
    look.topRight = Journal.Texture(frame, "frame-top-right", "ARTWORK", 1)
    look.topRight:SetSize(u(TOP_RIGHT), u(TOP_H))
    look.topRight:SetPoint("TOPRIGHT")
    look.topMiddle = Journal.Texture(frame, "frame-top-middle", "ARTWORK", 1)
    look.topMiddle:SetHeight(u(TOP_H))
    look.topMiddle:SetPoint("TOPLEFT", frame, "TOPLEFT", u(TOP_LEFT), 0)
    look.topMiddle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -u(TOP_RIGHT), 0)

    -- the top a window is held by: the strap and the label
    look.head = CreateFrame("Frame", nil, frame)
    look.head:SetPoint("TOPLEFT")
    look.head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -u(CLOSE_X + 40), 0)
    look.head:SetHeight(u(TOP_H - 24))

    look.title = look.head:CreateFontString(nil, "OVERLAY")
    Journal.Font(look.title, 20, true, Journal.INK, 0.9)
    look.title:SetPoint("LEFT", frame, "TOPLEFT", u(TITLE_X), -u(TITLE_Y))
    look.title:SetPoint("RIGHT", frame, "TOPRIGHT", -u(TITLE_END), -u(TITLE_Y))
    look.title:SetJustifyH("LEFT")
    look.title:SetWordWrap(false)
    look.title:SetText(title or "")

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(u(72), u(72))
    close:SetPoint("CENTER", frame, "TOPRIGHT", -u(CLOSE_X), -u(CLOSE_Y))
    local x = close:CreateFontString(nil, "OVERLAY")
    Journal.Press(x, 19)
    x:SetPoint("CENTER", 0, u(2))
    x:SetText("x")
    close:SetFontString(x)
    close:SetPushedTextOffset(u(1), -u(2))
    close:SetScript("OnEnter", Core.Guard("journal", function() x:SetTextColor(Journal.LIT[1], Journal.LIT[2], Journal.LIT[3], 1) end))
    close:SetScript("OnLeave", Core.Guard("journal", function()
        x:SetTextColor(Journal.LEATHER[1], Journal.LEATHER[2], Journal.LEATHER[3], 0.85)
    end))
    look.close = close
    look.strap = u(STRAP)

    look.content = CreateFrame("Frame", nil, frame)
    look.content:SetPoint("TOPLEFT", frame, "TOPLEFT", u(CONTENT[1]), -u(CONTENT[2]))
    look.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -u(CONTENT[3]), u(CONTENT[4]))

    function look.Layout() Layout(look) end
    frame:HookScript("OnSizeChanged", Core.Guard("journal", function() Layout(look) end))
    Layout(look)
    return look
end

-- The page's paper alone over a frame (a page without the window round it): cut, never stretched.
function Journal.Paper(frame, layer)
    local paper = frame:CreateTexture(nil, layer or "BACKGROUND")
    paper:SetTexture(ART .. "paper")
    paper:SetAllPoints()
    paper:SetVertexColor(Journal.TONE[1], Journal.TONE[2], Journal.TONE[3])
    frame:HookScript("OnSizeChanged", Core.Guard("journal", function() Cut(paper) end))
    Cut(paper)
    return paper
end

-------------------------------------------------------------------------------
--  Pencil
-------------------------------------------------------------------------------
-- A pencil line (#14's top line), its height the boxes' line weight; anchor its ends.
local RULE_H = 12 * U
function Journal.Rule(parent, layer)
    local t = Journal.Texture(parent, "pencil-rule", layer or "ARTWORK")
    t:SetHeight(RULE_H)
    return t
end

-- A pencil box round frame, in nine pieces: its corners whole (30 % of the piece's height), its sides stretched.
-- weight: its size against the design's (1: the box of a section; less for small boxes).
local BOX_CORNER = 35
local BOX_SLICES = { { 0, BOX_CORNER }, { BOX_CORNER, 338 - BOX_CORNER }, { 338 - BOX_CORNER, 338 } }
local BOX_ROWS = { { 0, BOX_CORNER }, { BOX_CORNER, 116 - BOX_CORNER }, { 116 - BOX_CORNER, 116 } }

local function Strong(box, on)
    local a = on and 1 or 0.75
    for _, t in ipairs(box.parts) do t:SetAlpha(a) end
end

function Journal.Box(frame, weight, layer)
    local c = BOX_CORNER * U * (weight or 1)
    local box = { parts = {}, SetStrong = Strong }
    for row = 1, 3 do
        for col = 1, 3 do
            local t = frame:CreateTexture(nil, layer or "BORDER")
            t:SetTexture(ART .. "pencil-box")
            Coords(t, "pencil-box", BOX_SLICES[col][1], BOX_SLICES[col][2], BOX_ROWS[row][1], BOX_ROWS[row][2])
            local x = col == 1 and "LEFT" or col == 3 and "RIGHT" or ""
            local y = row == 1 and "TOP" or row == 3 and "BOTTOM" or ""
            if col ~= 2 then t:SetWidth(c) end
            if row ~= 2 then t:SetHeight(c) end
            if row ~= 2 and col ~= 2 then
                t:SetPoint(y .. x, frame, y .. x)
            elseif row == 2 and col ~= 2 then
                t:SetPoint("TOP" .. x, frame, "TOP" .. x, 0, -c)
                t:SetPoint("BOTTOM" .. x, frame, "BOTTOM" .. x, 0, c)
            elseif col == 2 and row ~= 2 then
                t:SetPoint(y .. "LEFT", frame, y .. "LEFT", c, 0)
                t:SetPoint(y .. "RIGHT", frame, y .. "RIGHT", -c, 0)
            else
                t:SetPoint("TOPLEFT", frame, "TOPLEFT", c, -c)
                t:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -c, c)
            end
            box.parts[#box.parts + 1] = t
        end
    end
    -- the middle is the page: only the lines are drawn
    box.parts[5]:Hide()
    Strong(box, false)
    return box
end

-- An item's slot: a square pencil box at frame's edge (out: units beyond it), the icon inset by Journal.SLOT_ICON of
-- its side so it covers the box's inner line, as the design draws a slot.
Journal.SLOT_ICON = 0.1
function Journal.Slot(frame, out, layer)
    local t = Journal.Texture(frame, "pencil-slot", layer or "BACKGROUND")
    out = out or 1
    t:SetPoint("TOPLEFT", -out, out)
    t:SetPoint("BOTTOMRIGHT", out, -out)
    return t
end

-------------------------------------------------------------------------------
--  Words
-------------------------------------------------------------------------------
-- Kalam at a size given in the pixels of a 1080p layout (the designs' unit), in a colour.
function Journal.Font(fs, size, bold, color, alpha)
    fs:SetFont(bold and Journal.FONT_BOLD or Journal.FONT, size * Journal.PX, "")
    color = color or Journal.INK
    fs:SetTextColor(color[1], color[2], color[3], alpha or color[4] or 1)
    fs:SetShadowOffset(0, 0)
end

-- A font object of Kalam in graphite (size in 1080p pixels), made once by its name.
local fonts = {}
function Journal.FontObject(name, size, bold, flags, color)
    local font = fonts[name]
    if not font then
        font = CreateFont(name)
        fonts[name] = font
    end
    font:SetFont(bold and Journal.FONT_BOLD or Journal.FONT, size * Journal.PX, flags or "")
    color = color or Journal.INK
    font:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    font:SetShadowOffset(0, 0)
    return font
end

-- Letters pressed into leather (as title-text.png): the leather's light tan where it is pressed, a dark edge of
-- the cut under it.
function Journal.Press(fs, size)
    fs:SetFont(Journal.FONT_BOLD, size * Journal.PX, "")
    fs:SetTextColor(Journal.LEATHER[1], Journal.LEATHER[2], Journal.LEATHER[3], 0.85)
    fs:SetShadowColor(18 / 255, 10 / 255, 5 / 255, 0.8)
    fs:SetShadowOffset(Journal.PX * 0.7, -Journal.PX)
end

-- A colour of the game's (a quality's, a class's) that reads on the paper: darkened toward the graphite, so the
-- light ones (white, yellow, the priest's) stay readable.
function Journal.Ink(r, g, b)
    local k = 0.62
    local ink = Journal.INK
    local function mix(v, i) return math.max(0, v * k + i * (1 - k) - 0.08) end
    return mix(r, ink[1]), mix(g, ink[2]), mix(b, ink[3])
end

-------------------------------------------------------------------------------
--  Leather
-------------------------------------------------------------------------------
-- #183's leather patch behind a button (or any frame) of its height: its ends kept, its middle stretched.
local PATCH_END = 0.25
function Journal.Patch(frame, height)
    local p = PIECES.patch
    local endW = height * (p[1] * PATCH_END) / p[2]
    local parts = {}
    for i, c in ipairs({ { 0, PATCH_END }, { PATCH_END, 1 - PATCH_END }, { 1 - PATCH_END, 1 } }) do
        local t = Journal.Texture(frame, "patch", "BACKGROUND")
        Coords(t, "patch", c[1] * p[1], c[2] * p[1], 0, p[2])
        parts[i] = t
    end
    parts[1]:SetPoint("TOPLEFT"); parts[1]:SetPoint("BOTTOMLEFT"); parts[1]:SetWidth(endW)
    parts[3]:SetPoint("TOPRIGHT"); parts[3]:SetPoint("BOTTOMRIGHT"); parts[3]:SetWidth(endW)
    parts[2]:SetPoint("TOPLEFT", parts[1], "TOPRIGHT"); parts[2]:SetPoint("BOTTOMRIGHT", parts[3], "BOTTOMLEFT")
    return parts, endW
end

-- A button of the leather patch, its word pressed in.
local function Chosen(button, on)
    local v = on and 1 or 0.82
    for _, t in ipairs(button.parts) do t:SetVertexColor(v, v, v) end
    button.label:SetAlpha(on and 1 or 0.85)
end

function Journal.Button(parent, text, onClick, height)
    local b = CreateFrame("Button", nil, parent)
    height = height or 30 * Journal.PX
    local parts, endW = Journal.Patch(b, height)
    local label = b:CreateFontString(nil, "OVERLAY")
    Journal.Press(label, 14)
    label:SetPoint("CENTER", 0, 1)
    label:SetText(text or "")
    b:SetFontString(label)
    b:SetPushedTextOffset(0.5, -1)
    b:SetSize(math.max(height, label:GetStringWidth() + endW * 2), height)
    b.parts, b.label, b.SetChosen = parts, label, Chosen
    Chosen(b, true)
    b:SetScript("OnEnter", Core.Guard("journal", function() label:SetTextColor(Journal.LIT[1], Journal.LIT[2], Journal.LIT[3], 1) end))
    b:SetScript("OnLeave", Core.Guard("journal", function()
        label:SetTextColor(Journal.LEATHER[1], Journal.LEATHER[2], Journal.LEATHER[3], 0.85)
    end))
    if onClick then b:SetScript("OnClick", Core.Guard("journal", onClick)) end
    return b
end
