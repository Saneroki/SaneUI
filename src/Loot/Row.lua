local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Row
--  One line of the loot window, straight on the world (no paper, no shade):
--  the thing's picture in a thin border of its quality's colour (a quest's
--  things in the game's gold), how many on it, its name in its quality's
--  colour with a thin dark outline; under it, when asked, a small grey note
--  (Slots.Note). Under the mouse a soft dark shade fading out to the right; a
--  thing that is not the player's to take now is faint.
--
--      local row = Row.New(parent)      -- made once, used again
--      Row.Set(row, line, notes)        -- shows a line of Slots (notes: the note under the name)
--      Row.Color(quality)               -- a quality's colour, the game's own
--      Row.Gold()                       -- the game's gold (a quest's things, a word under the mouse)
--      Row.Width(row)                   -- how wide its picture and words run
--      Row.Font(fontString, size, bold) -- Kalam outlined, to stand on the world
--  The clicks and the tooltip are the window's (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Row = {}
ns.Row = Row

local GREY = { 0.72, 0.72, 0.72 }

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

function Row.New(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(S.row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.shade = row:CreateTexture(nil, "BACKGROUND")
    row.shade:SetAllPoints()
    row.shade:SetColorTexture(1, 1, 1, 1)
    if row.shade.SetGradient and rawget(_G, "CreateColor") then
        row.shade:SetGradient("HORIZONTAL", CreateColor(0, 0, 0, 0.5), CreateColor(0, 0, 0, 0))
    else
        row.shade:SetColorTexture(0, 0, 0, 0.3)
    end
    row.shade:Hide()

    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(S.icon, S.icon)
    row.holder:SetPoint("LEFT", row, "LEFT", 0, 0)
    -- a dark hair round the border, so a light quality reads over a light ground
    row.edge = row.holder:CreateTexture(nil, "BACKGROUND")
    row.edge:SetPoint("TOPLEFT", -1, 1)
    row.edge:SetPoint("BOTTOMRIGHT", 1, -1)
    row.edge:SetColorTexture(0, 0, 0, 0.8)
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

    row.name = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.name, 15, true)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.note = row:CreateFontString(nil, "ARTWORK")
    Row.Font(row.note, 11, false)
    row.note:SetTextColor(GREY[1], GREY[2], GREY[3])
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    return row
end

-- The name alone in the middle, or the name above its note.
local function Lay(row, note)
    local left = S.icon + S.gap
    row.name:ClearAllPoints()
    row.note:ClearAllPoints()
    if note then
        row.name:SetPoint("BOTTOMLEFT", row, "LEFT", left, -1)
        row.name:SetPoint("BOTTOMRIGHT", row, "RIGHT", 0, -1)
        row.note:SetPoint("TOPLEFT", row, "LEFT", left, -1)
        row.note:SetPoint("TOPRIGHT", row, "RIGHT", 0, -1)
    else
        row.name:SetPoint("LEFT", row, "LEFT", left, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    end
end

function Row.Set(row, line, notes)
    row.line = line
    row.icon:SetTexture(line.icon)
    row.icon:SetDesaturated(line.locked)
    row.count:SetText(line.count and line.count > 1 and line.count or "")
    row.name:SetText(line.name)
    row.name:SetTextColor(Row.Color(line.quality))
    if ns.Slots.Quest(line) then
        row.border:SetColorTexture(Row.Gold())
    else
        row.border:SetColorTexture(Row.Color(line.quality))
    end
    local note = notes and ns.Slots.Note(line) or ""
    if line.locked then note = ns.TEXT.locked end
    row.note:SetText(note)
    Lay(row, note ~= "")
    row:SetAlpha(line.locked and 0.5 or 1)
    row:Show()
end

-- How wide the line's words run, past its picture.
function Row.Width(row)
    local name = tonumber(row.name:GetStringWidth()) or 0
    local note = tonumber(row.note:GetStringWidth()) or 0
    return S.icon + S.gap + math.max(name, note) + 2
end
