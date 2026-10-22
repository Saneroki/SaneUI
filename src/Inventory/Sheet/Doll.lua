local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Doll
--  The character's doll in Sane UI's own look (Doc/guides/interface-style.md,
--  Views: Character doll): one picture of its own leather frame and paper
--  (Core's Art/Journal/doll, made by dev/tools/journal-art), its gear slots in
--  two arcs round the hero's place, a paper strip beside seven of each side's
--  slots and under the weapons, hanging out over the leather. Code puts the
--  live content in: the game's item buttons in the slots, the items' words on
--  the strips (the name in its quality's colour, the slot and item level, its
--  two largest stats), the character's live model in the hero's place.
--
--  Where things stand on it, in the pixels of a 1080p layout (its own pixels
--  halved), from its top left: dev/tools/journal-art prints them.
--
--      Doll.Build(parent)         -- the picture in parent (sized Doll.WIDTH x Doll.HEIGHT units)
--      Doll.Rect(rect)            -- a rect of the doll's in units: left, top, width, height
--      Doll.Strip(parent, rect)   -- a strip's three lines; strip:Fill(name, color, line, stats) or strip:Empty(word)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Doll = {}
ns.Doll = Doll

local PX = J.PX
Doll.PIXELS = { 680, 902 }              -- its size in a 1080p layout's pixels
Doll.WIDTH, Doll.HEIGHT = Doll.PIXELS[1] * PX, Doll.PIXELS[2] * PX

-- The slots { left, top, right, bottom }, each with its strip; by the game's slot names in Slots.COLUMNS' order.
Doll.TOP = { { 138, 44, 228, 134 }, { 433, 44, 528, 134 } }   -- head and hands: no strip
Doll.LEFT = {
    { { 155, 146, 219, 210 }, { 45, 142, 151, 212 } },
    { { 145, 228, 209, 292 }, { 35, 224, 141, 294 } },
    { { 139, 310, 203, 374 }, { 29, 306, 135, 376 } },
    { { 139, 391, 203, 455 }, { 29, 387, 135, 457 } },
    { { 145, 471, 209, 535 }, { 50, 467, 141, 537 } },
    { { 155, 551, 219, 615 }, { 64, 547, 151, 617 } },
    { { 168, 631, 232, 695 }, { 80, 627, 164, 697 } },
}
Doll.RIGHT = {
    { { 455, 146, 519, 210 }, { 521, 142, 619, 212 } },
    { { 465, 228, 529, 292 }, { 531, 224, 637, 294 } },
    { { 471, 310, 535, 374 }, { 537, 306, 643, 376 } },
    { { 471, 391, 535, 455 }, { 537, 387, 643, 457 } },
    { { 465, 471, 529, 535 }, { 531, 467, 628, 537 } },
    { { 455, 551, 519, 615 }, { 521, 547, 614, 617 } },
    { { 442, 631, 506, 695 }, { 508, 627, 599, 697 } },
}
Doll.WEAPONS = {
    { { 130, 736, 226, 822 }, { 88, 839, 241, 878 } },
    { { 284, 736, 382, 822 }, { 258, 839, 411, 878 } },
    { { 442, 736, 538, 822 }, { 427, 839, 567, 878 } },
}
Doll.AMMO = { 550, 770, 594, 812 }
Doll.HERO = { 238, 30, 434, 708 }       -- the hero's place: his name and level at its top, the model under them
Doll.NAME_Y, Doll.LEVEL_Y, Doll.MODEL_TOP = 40, 64, 84
Doll.CLOSE = { 485, 30 }                -- the X's middle, on the right strap
Doll.HEAD = 30                          -- the top a window is dragged by
-- An item's icon in its slot: so much inside the slot's painted box, each side.
Doll.INSET = { top = 12, side = 7, weapon = 14, ammo = 5 }

local PICTURE = J.PIECES.doll

-- A rect of the doll's (1080p pixels) in units: left, top, width, height.
function Doll.Rect(r)
    return r[1] * PX, r[2] * PX, (r[3] - r[1]) * PX, (r[4] - r[2]) * PX
end

-- The picture, filling parent (which is Doll.WIDTH x Doll.HEIGHT units).
function Doll.Build(parent)
    local art = parent:CreateTexture(nil, "BACKGROUND")
    art:SetTexture(J.ART .. "doll")
    art:SetTexCoord(0, PICTURE[1] / PICTURE[3], 0, PICTURE[2] / PICTURE[4])
    art:SetAllPoints()
    return art
end

-- A font string's size brought down until its text fits its width (sizes in 1080p pixels, from size to least).
local function Fit(fs, text, size, least, bold, flags)
    local width = fs:GetWidth()
    fs:SetText(text or "")
    for s = size, least, -1 do
        fs:SetFont(bold and J.FONT_BOLD or J.FONT, s * PX, flags or "")
        if width <= 0 or fs:GetStringWidth() <= width then return end
    end
end

-- A line of a strip, its top that far under the strip's top.
local function Line(strip, size, bold, top)
    local fs = strip:CreateFontString(nil, "OVERLAY")
    J.Font(fs, size, bold)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetPoint("TOPLEFT", 5 * PX, -top)
    fs:SetPoint("TOPRIGHT", -3 * PX, -top)
    return fs
end

local SIZES = { 14, 12, 12 }   -- the name, the slot and level, the stats (1080p pixels)
local function FillStrip(strip, name, color, line, stats)
    local lines = strip.lines
    Fit(lines[1], name, SIZES[1], 9, true, "OUTLINE")
    lines[1]:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1, 1)
    Fit(lines[2], line, SIZES[2], 9)
    lines[2]:SetTextColor(J.INK[1], J.INK[2], J.INK[3], 0.85)
    Fit(lines[3], stats, SIZES[3], 9)
    lines[3]:SetTextColor(J.INK[1], J.INK[2], J.INK[3], 0.85)
end

-- An empty slot: its word, faint, on the strip's first line.
local function EmptyStrip(strip, word)
    local lines = strip.lines
    Fit(lines[1], word, SIZES[2], 9)
    lines[1]:SetTextColor(J.INK[1], J.INK[2], J.INK[3], 0.45)
    lines[2]:SetText("")
    lines[3]:SetText("")
end

-- A strip's three lines over its paper; a weapon's strip (wide and low) has two.
function Doll.Strip(parent, rect, wide)
    local strip = CreateFrame("Frame", nil, parent)
    local x, y, w, h = Doll.Rect(rect)
    strip:SetPoint("TOPLEFT", x, -y)
    strip:SetSize(w, h)
    strip.lines = {}
    local count = wide and 2 or 3
    for i = 1, 3 do
        strip.lines[i] = Line(strip, SIZES[i], i == 1, (i - 1) * (h / count) + (wide and 2 or 4) * PX)
    end
    if wide then
        -- the weapon's: the name over the level and stats on one line
        strip.lines[3]:Hide()
        strip.wide = true
    end
    strip.Fill, strip.Empty = FillStrip, EmptyStrip
    if wide then
        function strip.Fill(self, name, color, line, stats)
            FillStrip(self, name, color, (line or "") .. ((stats and stats ~= "") and ("  ·  " .. stats) or ""), nil)
        end
    end
    return strip
end
