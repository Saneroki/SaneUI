local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Doll
--  The character's doll in Sane UI's own look (Doc/guides/interface-style.md,
--  Views: Character doll): one picture of its own leather frame and paper
--  (Core's Art/Journal/doll, made by dev/tools/journal-art), its gear slots in
--  two arcs round the hero's place, a paper strip beside seven of each side's
--  slots and under the weapons, hanging out over the leather. Code puts the
--  live content in: the game's item buttons in the slots, the items' stats on
--  the strips (centred: DPS, armor, the primary stats, then the rest), the
--  character's live model in the hero's place, on the page's plain paper.
--
--  Where things stand on it, in the pixels of a 1080p layout (its own pixels
--  halved), from its top left: dev/tools/journal-art prints them.
--
--      Doll.Build(parent)         -- the picture in parent (sized Doll.WIDTH x Doll.HEIGHT units)
--      Doll.Rect(rect)            -- a rect of the doll's in units: left, top, width, height
--      Doll.Strip(parent, rect)   -- a strip's lines; strip:Fill(stats) (a list of words) or strip:Empty()
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Doll = {}
ns.Doll = Doll

local PX = J.PX
Doll.PIXELS = { 680, 902 }              -- its size in a 1080p layout's pixels
Doll.WIDTH, Doll.HEIGHT = Doll.PIXELS[1] * PX, Doll.PIXELS[2] * PX

-- The slots { left, top, right, bottom }, each with its strip; by the game's slot names in Slots.COLUMNS' order.
Doll.TOP = { { 149, 64, 213, 128 }, { 465, 64, 529, 128 } }   -- head and hands, as large as the others: no strip
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
Doll.INSET = { top = 7, side = 7, weapon = 14, ammo = 5 }

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

Doll.STAT_SIZE, Doll.STAT_LEAST = 13, 9   -- a stat's words (1080p pixels), and the least they are brought down to
Doll.LINE = 15                           -- a line's height (1080p pixels)

-- A strip's line: centred across the strip.
local function Line(strip)
    local fs = strip:CreateFontString(nil, "OVERLAY")
    J.Font(fs, Doll.STAT_SIZE)
    fs:SetJustifyH("CENTER")
    fs:SetWordWrap(false)
    fs:SetTextColor(J.INK[1], J.INK[2], J.INK[3], 0.9)
    return fs
end

-- The stats on the strip, centred both ways: one to a line while they fit, else as many to a line as needed.
local function FillStrip(strip, stats)
    local lines, n = strip.lines, #strip.lines
    local count = math.min(#stats, n)
    local per = count > 0 and math.ceil(#stats / count) or 0
    local height = Doll.LINE * PX
    local top = (strip:GetHeight() - count * height) / 2
    for i, fs in ipairs(lines) do
        if i <= count then
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", 4 * PX, -(top + (i - 1) * height))
            fs:SetPoint("TOPRIGHT", -4 * PX, -(top + (i - 1) * height))
            Fit(fs, table.concat(stats, "  ", (i - 1) * per + 1, math.min(#stats, i * per)), Doll.STAT_SIZE, Doll.STAT_LEAST)
            fs:SetTextColor(J.INK[1], J.INK[2], J.INK[3], 0.9)
        else
            fs:SetText("")
        end
    end
end

-- An empty slot: a blank strip (its tooltip names the slot).
local function EmptyStrip(strip)
    for _, fs in ipairs(strip.lines) do fs:SetText("") end
end

-- A strip's lines over its paper: three, a weapon's strip (wide and low) two.
function Doll.Strip(parent, rect, wide)
    local strip = CreateFrame("Frame", nil, parent)
    local x, y, w, h = Doll.Rect(rect)
    strip:SetPoint("TOPLEFT", x, -y)
    strip:SetSize(w, h)
    strip.lines = {}
    for i = 1, wide and 2 or 3 do strip.lines[i] = Line(strip) end
    strip.wide = wide or false
    strip.Fill, strip.Empty = FillStrip, EmptyStrip
    return strip
end
