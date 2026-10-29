local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Row
--  One line of the loot window (Saneroki, 2026-10-29): a plate with smooth
--  round corners (Core.Shape, as the chat's bubbles), a dark fill half
--  see-through and a thin trim in the thing's quality colour (a quest's things
--  in the game's gold); in it the thing's picture on a small round plate of its
--  own, trimmed in that colour, how many on it, its name in that colour,
--  outlined; under the name, small, its kind and how it binds (Slots.Note) and
--  at the right what a vendor pays for all of it; the game's green arrow on the
--  picture where it would make the character better (Upgrade.lua); at the top
--  right an A on a
--  small round plate: the thing taken at once from now on (on the player's
--  list: gold). Under the mouse the fill darkens; a thing that is not the
--  player's to take now is faint.
--
--      local row = Row.New(parent)          -- made once, used again
--      Row.Set(row, line, notes, onList)    -- shows a line of Slots (notes: the line under the name)
--      Row.Auto(row, onList)                -- the A as the player's word stands
--      Row.Color(quality), Row.Gold()       -- a quality's colour, the game's gold
--      Row.Font(fontString, size, bold)     -- Kalam outlined, to stand on the world
--      Row.Plate(frame, radius, fill)       -- a round plate (the line's, the window's buttons')
--      Row.Width(row), Row.Fit(row, width)  -- how wide its parts run; its plate laid out for the window's width
--  The clicks and the tooltips are the window's (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Row = {}
ns.Row = Row

local GREY = { 0.72, 0.72, 0.72 }
local TRIM = { 0.45, 0.45, 0.45 } -- a plate's trim where no quality colours it (the buttons)
local SHADE, LIT = 0.5, 0.75 -- the fill's darkness, and under the mouse

function Row.Color(quality)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and quality and colors[quality]
    if not color then return 1, 1, 1 end
    return color.r, color.g, color.b
end

-- The game's gold, as its quest things are marked.
function Row.Gold()
    local gold = rawget(_G, "NORMAL_FONT_COLOR")
    if type(gold) == "table" and gold.r then return gold.r, gold.g, gold.b end
    return 1, 0.82, 0
end

function Row.Font(fs, size, bold)
    fs:SetFont(bold and J.FONT_BOLD or J.FONT, size * J.PX, "OUTLINE")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.6)
end

-- A plate behind a frame with smooth round corners (Core.Shape: its corners cut by Core's circle, the trim an
-- arc there), a black fill (fill: how solid, half at first) and a thin trim:
--      plate:Paint(r, g, b)    the trim's colour (nil: grey)
--      plate:SetLit(on)        the fill darker, under the mouse
--      plate:Fit(width, height)  laid out for the frame at that size (its place does not matter: round wherever)
function Row.Plate(frame, radius, fill)
    local shape = Core.Shape.New(frame, { radius = radius, trim = S.trim })
    local plate = { shape = shape, fill = fill or SHADE, trim = TRIM, lit = false }
    local function Look()
        shape:Look({ top = { 0, 0, 0 }, alpha = plate.lit and LIT or plate.fill, trim = plate.trim })
    end
    function plate.Paint(_, r, g, b)
        plate.trim = r and { r, g, b } or TRIM
        Look()
    end
    function plate.SetLit(_, on)
        plate.lit = on and true or false
        Look()
    end
    function plate.Fit(_, width, height) shape:Fit(0, 0, width, height) end
    Look()
    return plate
end

function Row.New(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(S.row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.plate = Row.Plate(row, S.radius)

    -- the picture on a small round plate of its own, nearly black, trimmed in the same colour; the picture square,
    -- set in so far that its corners stay inside the plate's round (a dark line between trim and picture)
    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(S.icon, S.icon)
    row.holder:SetPoint("LEFT", row, "LEFT", S.pad, 0)
    row.holder.plate = Row.Plate(row.holder, S.iconRadius, 0.9)
    row.holder.plate:Fit(S.icon, S.icon)
    row.icon = row.holder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", S.iconInset, -S.iconInset)
    row.icon:SetPoint("BOTTOMRIGHT", -S.iconInset, S.iconInset)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- the game's own sign of an upgrade (its bags have it): a green arrow on the picture's top left
    row.upgrade = row.holder:CreateTexture(nil, "OVERLAY", nil, 2)
    row.upgrade:SetAtlas("bags-greenarrow")
    row.upgrade:SetSize(S.arrow, S.arrow)
    row.upgrade:SetPoint("TOPLEFT", row.holder, "TOPLEFT", 1, -1)
    row.upgrade:Hide()
    row.count = row.holder:CreateFontString(nil, "OVERLAY")
    Row.Font(row.count, 11, true)
    row.count:SetTextColor(1, 1, 1)
    row.count:SetPoint("BOTTOMRIGHT", row.holder, "BOTTOMRIGHT", -2, 1)

    -- the A: taken at once from now on
    row.auto = CreateFrame("Button", nil, row)
    row.auto:SetSize(S.auto, S.auto)
    row.auto.plate = Row.Plate(row.auto, S.autoRadius)
    row.auto.plate:Fit(S.auto, S.auto)
    row.auto.text = row.auto:CreateFontString(nil, "OVERLAY")
    Row.Font(row.auto.text, 12, true)
    row.auto.text:SetPoint("CENTER", 0, 0)
    row.auto.text:SetText(ns.TEXT.auto)

    row.name = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.name, 14, true)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.note = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.note, 11, false)
    row.note:SetTextColor(GREY[1], GREY[2], GREY[3])
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    row.worth = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.worth, 11, false)
    row.worth:SetTextColor(1, 1, 1)
    row.worth:SetJustifyH("RIGHT")
    return row
end

-- The name alone beside the picture (the A at its right), or the name over the line of its kind and worth (the kind
-- reaches to the line's right end where it sells for nothing: no empty words to lean on).
local function Lay(row, second, worth)
    local left = S.pad + S.icon + S.gap
    for _, part in ipairs({ row.name, row.note, row.worth, row.auto }) do part:ClearAllPoints() end
    if second then
        row.auto:SetPoint("TOPRIGHT", row, "TOPRIGHT", -S.pad, -S.pad)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", left, -S.pad)
        row.worth:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -S.pad, S.pad)
        row.note:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", left, S.pad)
        if worth then
            row.note:SetPoint("RIGHT", row.worth, "LEFT", -S.gap, 0)
        else
            row.note:SetPoint("RIGHT", row, "RIGHT", -S.pad, 0)
        end
    else
        row.auto:SetPoint("RIGHT", row, "RIGHT", -S.pad, 0)
        row.name:SetPoint("LEFT", row, "LEFT", left, 0)
    end
    if row.auto:IsShown() then
        row.name:SetPoint("RIGHT", row.auto, "LEFT", -S.gap / 2, 0)
    else
        row.name:SetPoint("RIGHT", row, "RIGHT", -S.pad, 0)
    end
end

-- What a vendor pays for all of it, in the game's coins; nothing for what sells for nothing.
local function Worth(line)
    local each = tonumber(line.worth) or 0
    if line.kind ~= "item" or each <= 0 then return "" end
    return Core.Coins(each * (tonumber(line.count) or 1)) or ""
end

-- The A as the player's word stands: gold while the thing is on the list.
function Row.Auto(row, onList)
    row.auto.on = onList and true or false
    if onList then row.auto.text:SetTextColor(Row.Gold()) else row.auto.text:SetTextColor(GREY[1], GREY[2], GREY[3]) end
end

function Row.Set(row, line, notes, onList)
    row.line = line
    row.icon:SetTexture(line.icon)
    row.icon:SetDesaturated(line.locked)
    row.upgrade:SetShown(line.upgrade ~= nil)
    row.count:SetText(line.count and line.count > 1 and line.count or "")
    row.name:SetText(line.name)
    row.name:SetTextColor(Row.Color(line.quality))
    local r, g, b
    if ns.Slots.Quest(line) then r, g, b = Row.Gold() else r, g, b = Row.Color(line.quality) end
    row.plate:Paint(r, g, b)
    row.holder.plate:Paint(r, g, b)
    local note = notes and ns.Slots.Note(line) or ""
    if line.locked then note = ns.TEXT.locked end
    row.note:SetText(note)
    local worth = notes and Worth(line) or ""
    row.worth:SetText(worth)
    row.auto:SetShown(line.kind == "item" and line.id ~= nil)
    Row.Auto(row, onList)
    Lay(row, note ~= "" or worth ~= "", worth ~= "")
    row.plate:SetLit(false)
    row:SetAlpha(line.locked and 0.5 or 1)
    row:Show()
end

-- The line's plate laid out for its width (the window's, Window.Fill).
function Row.Fit(row, width)
    row.plate:Fit(width, S.row)
end

-- How wide the line's parts run: its picture, then the wider of its name (and A) and its second line.
function Row.Width(row)
    local function Wide(fs) return tonumber(fs:GetStringWidth()) or 0 end
    local top = Wide(row.name) + (row.auto:IsShown() and S.auto + S.gap / 2 or 0)
    local second = Wide(row.note) + Wide(row.worth) + S.gap
    return S.pad + S.icon + S.gap + math.max(top, second) + S.pad
end
