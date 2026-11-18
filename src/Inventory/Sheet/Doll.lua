local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Sheet - Doll
--  The character's doll in the kit's look (Core.Look; Doc/guides/interface-
--  style.md, The kit: the character window, "a prime example"): the heavy
--  bronze frame round it, the gear slots in the game's two columns with
--  Forever's gear slot frames (UI-Character-Info-GearSlot), the weapons in a
--  row under them, and in the middle the hero's place: the character's name
--  and level line at the top, the live model under them, on the plate itself.
--  Beside seven of each column's slots and under each weapon the item's stats. Code puts the live content in:
--  the game's item buttons in the slots, the items' stats in the boxes, the
--  model in the hero's place.
--
--  Where things stand, in the pixels of a 1080p layout, from its top left:
--
--      Doll.Build(parent)         -- the frame in parent (sized Doll.WIDTH x Doll.HEIGHT units)
--      Doll.Rect(rect)            -- a rect of the doll's in units: left, top, width, height
--      Doll.Strip(parent, rect)   -- an item's stat lines; strip:Fill(stats) (a list of words) or strip:Empty()
--      Doll.Cover(parent, l, r, top) -- the plate again from top down, over the model below the hero's place
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Look = Core.Look
local Style = ns.Style
local Doll = {}
ns.Doll = Doll

local PX = Style.PX
Doll.PIXELS = { 700, 884 }              -- its size in a 1080p layout's pixels
Doll.WIDTH, Doll.HEIGHT = Doll.PIXELS[1] * PX, Doll.PIXELS[2] * PX

-- The slots { left, top, right, bottom }, each with its box; by the game's slot names in Slots.COLUMNS' order. A
-- column's slots 64 high, 14 apart, from 96 down; the boxes on their inner side.
local SLOT, STEP, FIRST = 64, 78, 96
local LEFT_X, RIGHT_X = 34, 602
local function Row(index) return FIRST + index * STEP end
Doll.TOP = { { LEFT_X, Row(0), LEFT_X + SLOT, Row(0) + SLOT }, { RIGHT_X, Row(0), RIGHT_X + SLOT, Row(0) + SLOT } } -- head, neck: no box
Doll.LEFT, Doll.RIGHT = {}, {}
for index = 1, 7 do
    local y = Row(index)
    Doll.LEFT[index] = { { LEFT_X, y, LEFT_X + SLOT, y + SLOT }, { LEFT_X + SLOT + 8, y + 2, 232, y + SLOT - 2 } }
    Doll.RIGHT[index] = { { RIGHT_X, y, RIGHT_X + SLOT, y + SLOT }, { 468, y + 2, RIGHT_X - 8, y + SLOT - 2 } }
end
Doll.WEAPONS = {
    { { 160, 736, 240, 816 }, { 128, 824, 272, 864 } },
    { { 310, 736, 390, 816 }, { 278, 824, 422, 864 } },
    { { 460, 736, 540, 816 }, { 428, 824, 572, 864 } },
}
Doll.AMMO = { 584, 754, 628, 798 }
Doll.HERO = { 244, 22, 456, 712 }       -- the hero's place: his name and level at its top, the model under them
Doll.NAME_Y, Doll.LEVEL_Y, Doll.MODEL_TOP = 34, 58, 84
Doll.GROUND = 700                       -- where the model's feet stand
Doll.FOOT = 712                         -- the foot of the hero's place: the model is hidden below it
Doll.CLOSE = { 672, 26 }                -- the X's middle, in the top right corner inside the band
Doll.HEAD = 30                          -- the top a window is dragged by
-- An item's icon in its slot: so much inside the slot's rect, each side.
Doll.INSET = { top = 7, side = 7, weapon = 10, ammo = 4 }
Doll.FRAME = 1.49                       -- the gear slot's frame round its button (the game's 55 round 37)

-- A rect of the doll's (1080p pixels) in units: left, top, width, height.
function Doll.Rect(r)
    return r[1] * PX, r[2] * PX, (r[3] - r[1]) * PX, (r[4] - r[2]) * PX
end

-- The frame, filling parent (which is Doll.WIDTH x Doll.HEIGHT units): the window's own frame, as it scales with the
-- doll. The hero stands on the plate itself, nothing round him (Saneroki, 2026-11-15).
function Doll.Build(parent)
    return Look.Frame(parent)
end

-- The plate again from top (1080p pixels) down to the band and from left to right, in parent (as large as the
-- doll): drawn over what stands there, it hides it (the model's legs below the hero's place). A frame that clips a
-- plate laid as the window's own is (Look.Frame's, 4 in from the doll's sides), so its grain runs on unbroken.
function Doll.Cover(parent, left, right, top)
    local clip = CreateFrame("Frame", nil, parent)
    clip:SetPoint("TOPLEFT", parent, "TOPLEFT", left * PX, -top * PX)
    clip:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", right * PX, -(Doll.PIXELS[2] - 14) * PX)
    clip:SetClipsChildren(true)
    local whole = CreateFrame("Frame", nil, clip)
    whole:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    whole:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    Look.Plate(whole, "ARTWORK")
    Doll.covered = clip
    return clip
end

-- An item's slot frame (the character window's gear slot) round its button: centred on it, Doll.FRAME as large.
function Doll.Frame(parent, button)
    local frame = parent:CreateTexture(nil, "BORDER")
    Look.Atlas(frame, "ui-character-info-gearslot")
    local size = button:GetWidth() * Doll.FRAME
    frame:SetSize(size, size)
    frame:SetPoint("CENTER", button)
    return frame
end

-- A font string's size brought down until its text fits its width (sizes in 1080p pixels, from size to least).
local function Fit(fs, text, size, least, flags)
    local width = fs:GetWidth()
    fs:SetText(text or "")
    for s = size, least, -1 do
        fs:SetFont(Look.FONT, s * PX, flags or "")
        if width <= 0 or fs:GetStringWidth() <= width then return end
    end
end

Doll.STAT_SIZE, Doll.STAT_LEAST = 13, 9   -- a stat's words (1080p pixels), and the least they are brought down to
Doll.LINE = 15                           -- a line's height (1080p pixels)

-- A stat line: centred across its room, white.
local function Line(strip)
    local fs = strip:CreateFontString(nil, "OVERLAY")
    Style.SetFont(fs, Doll.STAT_SIZE, false, Style.INK, 0.9)
    fs:SetJustifyH("CENTER")
    fs:SetWordWrap(false)
    return fs
end

-- The stats in their room, centred both ways: one to a line while they fit, else as many to a line as needed.
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
            fs:SetTextColor(Style.INK[1], Style.INK[2], Style.INK[3], 0.9)
        else
            fs:SetText("")
        end
    end
end

-- An empty slot: no stats (its tooltip names the slot).
local function EmptyStrip(strip)
    for _, fs in ipairs(strip.lines) do fs:SetText("") end
end

-- An item's stats beside its slot, on the plate itself (Saneroki, 2026-11-15: no box round them): three lines, a
-- weapon's (wide and low) two.
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
