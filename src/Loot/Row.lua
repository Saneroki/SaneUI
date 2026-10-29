local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Row
--  One line of the loot window (Saneroki, 2026-10-29): a dark shade half
--  see-through, outlined in the thing's quality colour (a quest's things in
--  the game's gold); in it the thing's picture in a border of that colour, how
--  many on it, its name in that colour, outlined; under the name, small, its
--  kind and how it binds (Slots.Note) and at the right what a vendor pays for
--  all of it; at the top right an A: the thing taken at once from now on (on
--  the player's list: gold). Under the mouse the shade darkens; a thing that
--  is not the player's to take now is faint.
--
--      local row = Row.New(parent)          -- made once, used again
--      Row.Set(row, line, notes, onList)    -- shows a line of Slots (notes: the line under the name)
--      Row.Auto(row, onList)                -- the A as the player's word stands
--      Row.Color(quality), Row.Gold()       -- a quality's colour, the game's gold
--      Row.Font(fontString, size, bold)     -- Kalam outlined, to stand on the world
--      Row.Shade(frame), Row.Outline(frame) -- the line's shade and outline, for the window's buttons too
--      Row.Width(row)                       -- how wide its parts run
--  The clicks and the tooltips are the window's (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Row = {}
ns.Row = Row

local GREY = { 0.72, 0.72, 0.72 }
local SHADE, LIT = 0.5, 0.75 -- the shade's darkness, and under the mouse

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

-- A dark shade over a frame, half see-through: shade:SetLit(on) darkens it under the mouse.
function Row.Shade(frame)
    local shade = frame:CreateTexture(nil, "BACKGROUND")
    shade:SetAllPoints()
    shade:SetColorTexture(0, 0, 0, SHADE)
    function shade.SetLit(_, on) shade:SetColorTexture(0, 0, 0, on and LIT or SHADE) end
    return shade
end

-- A thin outline round a frame, four lines: outline:SetColor(r, g, b, a).
function Row.Outline(frame)
    local outline = {}
    for index, side in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                                 { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local edge = frame:CreateTexture(nil, "BORDER")
        edge:SetPoint(side[1])
        edge:SetPoint(side[2])
        if index <= 2 then edge:SetHeight(1) else edge:SetWidth(1) end
        outline[index] = edge
    end
    function outline.SetColor(_, r, g, b, a)
        for _, edge in ipairs(outline) do edge:SetColorTexture(r, g, b, a or 1) end
    end
    outline:SetColor(1, 1, 1, 0.5)
    return outline
end

function Row.New(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(S.row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.shade = Row.Shade(row)
    row.outline = Row.Outline(row)

    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(S.icon, S.icon)
    row.holder:SetPoint("LEFT", row, "LEFT", S.pad, 0)
    -- a dark hair round the border, so a light quality reads over the shade
    row.edge = row.holder:CreateTexture(nil, "BACKGROUND")
    row.edge:SetPoint("TOPLEFT", -1, 1)
    row.edge:SetPoint("BOTTOMRIGHT", 1, -1)
    row.edge:SetColorTexture(0, 0, 0, 0.9)
    row.border = row.holder:CreateTexture(nil, "BORDER")
    row.border:SetAllPoints()
    row.border:SetColorTexture(1, 1, 1, 1)
    row.icon = row.holder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", S.border, -S.border)
    row.icon:SetPoint("BOTTOMRIGHT", -S.border, S.border)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.count = row.holder:CreateFontString(nil, "OVERLAY")
    Row.Font(row.count, 11, true)
    row.count:SetTextColor(1, 1, 1)
    row.count:SetPoint("BOTTOMRIGHT", row.holder, "BOTTOMRIGHT", -2, 1)

    -- the A: taken at once from now on
    row.auto = CreateFrame("Button", nil, row)
    row.auto:SetSize(S.auto, S.auto)
    row.auto.shade = Row.Shade(row.auto)
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
    row.count:SetText(line.count and line.count > 1 and line.count or "")
    row.name:SetText(line.name)
    row.name:SetTextColor(Row.Color(line.quality))
    if ns.Slots.Quest(line) then
        row.border:SetColorTexture(Row.Gold())
        row.outline:SetColor(Row.Gold())
    else
        local r, g, b = Row.Color(line.quality)
        row.border:SetColorTexture(r, g, b, 1)
        row.outline:SetColor(r, g, b, 1)
    end
    local note = notes and ns.Slots.Note(line) or ""
    if line.locked then note = ns.TEXT.locked end
    row.note:SetText(note)
    local worth = notes and Worth(line) or ""
    row.worth:SetText(worth)
    row.auto:SetShown(line.kind == "item" and line.id ~= nil)
    Row.Auto(row, onList)
    Lay(row, note ~= "" or worth ~= "", worth ~= "")
    row.shade:SetLit(false)
    row:SetAlpha(line.locked and 0.5 or 1)
    row:Show()
end

-- How wide the line's parts run: its picture, then the wider of its name (and A) and its second line.
function Row.Width(row)
    local function Wide(fs) return tonumber(fs:GetStringWidth()) or 0 end
    local top = Wide(row.name) + (row.auto:IsShown() and S.auto + S.gap / 2 or 0)
    local second = Wide(row.note) + Wide(row.worth) + S.gap
    return S.pad + S.icon + S.gap + math.max(top, second) + S.pad
end
