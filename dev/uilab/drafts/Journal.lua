local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Journal (a draft of the interface lab: dev/uilab/drafts/)
--  A window of the journal look (Doc/guides/interface-style.md) built from the
--  art's pieces (assets/generated/interface/pieces, pieces.json), as the game
--  draws them: the top in three (its middle stretched between its ends), the
--  edges and the bottom repeated, the bottom corners mitred (masks) under their
--  metal caps, the clasp, the page's paper cut to the page and never stretched,
--  the title in Kalam on the top's label, the close button on its corner patch.
--  Built on the game's API alone, so it moves into Core as it is once chosen.
--
--      local w = Journal.Window(parent, name, width, height, title)
--      w.content      -- the frame on the page that holds the window's content
--      Journal.Tab(parent, text, onClick) -- a tab of #183's leather patch
--      Journal.Rule(parent)               -- a pencil line on the paper
--      Journal.Font(fontString, size, bold, color)
-------------------------------------------------------------------------------
local Journal = {}
ns.Journal = Journal

local ART = "Interface\\AddOns\\SaneUI\\Art\\Journal\\"
Journal.ART = ART
Journal.FONT = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Regular.ttf"
Journal.FONT_BOLD = "Interface\\AddOns\\SaneUI\\Fonts\\Kalam-Bold.ttf"

-- The pieces are drawn for 4K: 2160 of their pixels are the screen's 768 units at UI scale 1.
local U = 768 / 2160
Journal.UNIT = U

-- Where things stand on the pieces, in their pixels (pieces.json, pieces.py).
local EDGE = 88                 -- the edges' and the bottom's thickness
local TILE = 600                -- the edges' and the bottom's tile length
local TOP_H = 248               -- the top's height
local TOP_LEFT, TOP_RIGHT = 368, 612   -- its two ends' widths; the middle stretches between them
local HEAD = 40                 -- the edges start this far under the window's top (under the top's paper)
local RIGHT_IN = 40             -- the book ends this far before the window's right side (the top reaches further)
local BOX_W, BOX_H = 132, 96    -- a bottom corner's box: its cap, its rounded outline, its mitre masks
local BOX_RIGHT = 168           -- the right corner's box starts this far from the window's right side
local CLASP_W, CLASP_H = 100, 292
local TITLE_X, TITLE_Y = 352, 192   -- the title's left middle on the label
local CLOSE_X, CLOSE_Y = 132, 76    -- the close patch's middle, from the right and the top
local PAGE = { 44, 188, 84, 44 }    -- the page's paper from the left, top, right and bottom
local CONTENT = { 104, 252, 144, 104 }   -- the content's room on the page: left, top, right, bottom
local PAPER = 2048              -- the paper piece's side
Journal.TONE = { 0.89, 0.854, 0.828 }   -- the paper piece times this is the page's tone (220, 204, 178)
Journal.INK = { 30 / 255, 23 / 255, 17 / 255 }   -- pencil on the paper
Journal.LEATHER = { 48 / 255, 30 / 255, 18 / 255 }   -- letters pressed into leather

local function u(n) return n * U end

-- A strip of a repeated tile from a to b along one side (units from the window's top left), the tile's phase
-- counted from `origin`; its textures kept in the window's pool under `key`. Masks (mask textures) go on every
-- texture of the strip.
local function strip(f, key, file, layer, sub, across, width, a, b, vertical, origin, masks)
    local pools = f.journalStrips
    local pool = pools[key] or {}
    pools[key] = pool
    local tile = u(TILE)
    local n, pos = 0, a
    while pos < b - 0.01 do
        local phase = (pos - origin) % tile
        local len = math.min(tile - phase, b - pos)
        n = n + 1
        local t = pool[n]
        if not t then
            t = f:CreateTexture(nil, layer, nil, sub)
            t:SetTexture(file)
            for _, m in ipairs(masks or {}) do t:AddMaskTexture(m) end
            pool[n] = t
        end
        t:ClearAllPoints()
        if vertical then
            t:SetPoint("TOPLEFT", f, "TOPLEFT", across, -pos)
            t:SetSize(width, len)
            t:SetTexCoord(0, 1, phase / tile, (phase + len) / tile)
        else
            t:SetPoint("TOPLEFT", f, "TOPLEFT", pos, -across)
            t:SetSize(len, width)
            t:SetTexCoord(phase / tile, (phase + len) / tile, 0, 1)
        end
        t:Show()
        pos = pos + len
    end
    for i = n + 1, #pool do pool[i]:Hide() end
end

local function texture(f, file, layer, sub)
    local t = f:CreateTexture(nil, layer, nil, sub)
    t:SetTexture(ART .. file)
    return t
end

local function mask(f, file)
    local m = f:CreateMaskTexture()
    m:SetTexture(ART .. file, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetSize(u(BOX_W), u(BOX_H))
    return m
end

-- Lays the frame out for the window's size: the strips, the corners, the paper's cut.
local function layout(f)
    local w, h = f:GetSize()
    if w <= 0 or h <= 0 then return end
    local boxTop = h - u(BOX_H)
    local span = w - u(RIGHT_IN)              -- the book's right end
    local rightBox = w - u(BOX_RIGHT)
    local p = f.journal
    p.maskLeftEdge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    p.maskLeftBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    p.maskRightEdge:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", rightBox, 0)
    p.maskRightBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", rightBox, 0)
    -- the edges from under the top to the corners' boxes, and on through them under their masks
    strip(f, "left", ART .. "frame-left", "BORDER", 0, 0, u(EDGE), u(HEAD), boxTop, true, u(HEAD))
    strip(f, "leftCorner", ART .. "frame-left", "BORDER", 0, 0, u(EDGE), boxTop, h, true, u(HEAD), { p.maskLeftEdge })
    strip(f, "right", ART .. "frame-right", "BORDER", 0, span - u(EDGE), u(EDGE), u(HEAD), boxTop, true, u(HEAD))
    strip(f, "rightCorner", ART .. "frame-right", "BORDER", 0, span - u(EDGE), u(EDGE), boxTop, h, true, u(HEAD), { p.maskRightEdge })
    -- the bottom from the left corner's box to the right one's, and through them under their masks
    strip(f, "bottomLeft", ART .. "frame-bottom", "BORDER", 0, h - u(EDGE), u(EDGE), 0, u(BOX_W), false, 0, { p.maskLeftBottom })
    strip(f, "bottom", ART .. "frame-bottom", "BORDER", 0, h - u(EDGE), u(EDGE), u(BOX_W), rightBox, false, 0)
    strip(f, "bottomRight", ART .. "frame-bottom", "BORDER", 0, h - u(EDGE), u(EDGE), rightBox, span, false, 0, { p.maskRightBottom })
    -- the top: its ends whole, its middle stretched between them
    p.topMiddle:SetWidth(math.max(0.01, w - u(TOP_LEFT) - u(TOP_RIGHT)))
    p.clasp:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -(h - u(CLASP_H)) / 2)
    -- the paper: cut to the page, scaled up only when the page is larger than the piece
    local pw = (w - u(PAGE[1]) - u(PAGE[3])) / U
    local ph = (h - u(PAGE[2]) - u(PAGE[4])) / U
    local k = math.max(1, pw / PAPER, ph / PAPER)
    p.paper:SetTexCoord(0, pw / (PAPER * k), 0, ph / (PAPER * k))
end

-- A window of the journal look: width and height in units (at the least as wide as the top's two ends).
function Journal.Window(parent, name, width, height, title)
    local f = CreateFrame("Frame", name, parent or UIParent)
    f:SetSize(math.max(width, u(TOP_LEFT + TOP_RIGHT)), height)
    f.journalStrips = {}
    local p = {}
    f.journal = p

    p.paper = texture(f, "paper", "BACKGROUND")
    p.paper:SetPoint("TOPLEFT", f, "TOPLEFT", u(PAGE[1]), -u(PAGE[2]))
    p.paper:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -u(PAGE[3]), u(PAGE[4]))
    p.paper:SetVertexColor(unpack(Journal.TONE))

    p.maskLeftEdge = mask(f, "frame-mitre-left-edge")
    p.maskLeftBottom = mask(f, "frame-mitre-left-bottom")
    p.maskRightEdge = mask(f, "frame-mitre-right-edge")
    p.maskRightBottom = mask(f, "frame-mitre-right-bottom")

    for _, side in ipairs({ "left", "right" }) do
        local cap = texture(f, "frame-cap-" .. side, "BORDER", 2)
        cap:SetSize(u(BOX_W), u(BOX_H))
        if side == "left" then
            cap:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        else
            cap:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", -u(BOX_RIGHT), 0)
        end
    end

    p.clasp = texture(f, "frame-clasp", "ARTWORK", 0)
    p.clasp:SetSize(u(CLASP_W), u(CLASP_H))

    p.topLeft = texture(f, "frame-top-left", "ARTWORK", 1)
    p.topLeft:SetSize(u(TOP_LEFT), u(TOP_H))
    p.topLeft:SetPoint("TOPLEFT")
    p.topRight = texture(f, "frame-top-right", "ARTWORK", 1)
    p.topRight:SetSize(u(TOP_RIGHT), u(TOP_H))
    p.topRight:SetPoint("TOPRIGHT")
    p.topMiddle = texture(f, "frame-top-middle", "ARTWORK", 1)
    p.topMiddle:SetHeight(u(TOP_H))
    p.topMiddle:SetPoint("TOPLEFT", p.topLeft, "TOPRIGHT")

    f.title = f:CreateFontString(nil, "OVERLAY")
    Journal.Font(f.title, 22, true, Journal.INK, 0.9)
    f.title:SetPoint("LEFT", f, "TOPLEFT", u(TITLE_X), -u(TITLE_Y))
    f.title:SetText(title or "")

    local close = CreateFrame("Button", nil, f)
    close:SetSize(u(64), u(64))
    close:SetPoint("CENTER", f, "TOPRIGHT", -u(CLOSE_X), -u(CLOSE_Y))
    local x = close:CreateFontString(nil, "OVERLAY")
    Journal.Press(x, 19)
    x:SetPoint("CENTER", 0, u(2))
    x:SetText("x")
    close:SetFontString(x)
    close:SetPushedTextOffset(u(1), -u(2))
    close:SetScript("OnEnter", function() x:SetTextColor(0.42, 0.27, 0.15, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(Journal.LEATHER[1], Journal.LEATHER[2], Journal.LEATHER[3], 0.85) end)
    close:SetScript("OnClick", function() f:Hide() end)
    f.close = close

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", u(CONTENT[1]), -u(CONTENT[2]))
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -u(CONTENT[3]), u(CONTENT[4]))

    f:SetScript("OnSizeChanged", layout)
    layout(f)
    return f
end

-- Kalam at a size given in the pixels of a 1080p layout (the designs' unit), in a colour.
function Journal.Font(fs, size, bold, color, alpha)
    fs:SetFont(bold and Journal.FONT_BOLD or Journal.FONT, size * 768 / 1080, "")
    color = color or Journal.INK
    fs:SetTextColor(color[1], color[2], color[3], alpha or 1)
    fs:SetShadowOffset(0, 0)
end

-- Letters pressed into leather: a dark cut with a faint light lip under it.
function Journal.Press(fs, size)
    fs:SetFont(Journal.FONT_BOLD, size * 768 / 1080, "")
    fs:SetTextColor(Journal.LEATHER[1], Journal.LEATHER[2], Journal.LEATHER[3], 0.85)
    fs:SetShadowColor(225 / 255, 190 / 255, 145 / 255, 0.3)
    fs:SetShadowOffset(0, -768 / 1080)
end

-- A tab of #183's leather patch, its ends kept and its middle stretched, its word pressed in.
local PATCH_W, PATCH_H, PATCH_END = 778, 766, 0.25
function Journal.Tab(parent, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    local height = 34 * 768 / 1080
    local endW = height * (PATCH_W * PATCH_END) / PATCH_H
    local parts = {}
    for i, c in ipairs({ { 0, PATCH_END }, { PATCH_END, 1 - PATCH_END }, { 1 - PATCH_END, 1 } }) do
        local t = b:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(ART .. "patch")
        t:SetTexCoord(c[1], c[2], 0, 1)
        parts[i] = t
    end
    parts[1]:SetPoint("TOPLEFT"); parts[1]:SetPoint("BOTTOMLEFT"); parts[1]:SetWidth(endW)
    parts[3]:SetPoint("TOPRIGHT"); parts[3]:SetPoint("BOTTOMRIGHT"); parts[3]:SetWidth(endW)
    parts[2]:SetPoint("TOPLEFT", parts[1], "TOPRIGHT"); parts[2]:SetPoint("BOTTOMRIGHT", parts[3], "BOTTOMLEFT")
    local label = b:CreateFontString(nil, "OVERLAY")
    Journal.Press(label, 15)
    label:SetPoint("CENTER", 0, 1)
    label:SetText(text)
    b:SetFontString(label)
    b:SetPushedTextOffset(0.5, -1)
    b:SetSize(label:GetStringWidth() + endW * 2 + 6, height)
    b.parts = parts
    function b:SetChosen(on)
        local v = on and 1 or 0.78
        for _, t in ipairs(parts) do t:SetVertexColor(v, v, v) end
        label:SetAlpha(on and 1 or 0.8)
    end
    b:SetChosen(false)
    b:SetScript("OnClick", onClick)
    return b
end

-- A pencil line on the paper (#14's top line), along its parent's width at the boxes' line weight.
function Journal.Rule(parent)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetTexture(ART .. "pencil-rule")
    t:SetHeight(97 * (58 / 931) * 768 / 1080)
    return t
end
