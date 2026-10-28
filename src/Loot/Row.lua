local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Row
--  One line of the loot window, on the journal's paper: the thing's picture in
--  a pencil slot (how many on it), its name in its quality's colour as ink,
--  under it a note in faint pencil (Slots.Note). Under the mouse a light pencil
--  shading; a thing that is not the player's to take now is faint.
--
--      local row = Row.New(parent)      -- made once, used again
--      Row.Set(row, line, notes)        -- shows a line of Slots (notes: the note under the name)
--      Row.Color(quality)               -- a quality's colour as ink on the paper
--  The clicks and the tooltip are the window's (Window.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local S = ns.SIZE
local Row = {}
ns.Row = Row

function Row.Color(quality)
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and quality and colors[quality]
    if not color then return J.INK[1], J.INK[2], J.INK[3] end
    return J.Ink(color.r, color.g, color.b)
end

function Row.New(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(S.row)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.shade = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.shade:SetAllPoints()
    row.shade:SetColorTexture(J.SHADE[1], J.SHADE[2], J.SHADE[3], J.SHADE[4])
    row.shade:Hide()

    row.holder = CreateFrame("Frame", nil, row)
    row.holder:SetSize(S.icon, S.icon)
    row.holder:SetPoint("LEFT", row, "LEFT", 2, 0)
    J.Slot(row.holder, 1)
    local inset = S.icon * J.SLOT_ICON
    row.icon = row.holder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", inset, -inset)
    row.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    row.count = row.holder:CreateFontString(nil, "OVERLAY")
    row.count:SetFont(J.FONT_BOLD, 11 * J.PX, "OUTLINE")
    row.count:SetTextColor(1, 1, 1)
    row.count:SetPoint("BOTTOMRIGHT", row.holder, "BOTTOMRIGHT", -1, 1)

    row.name = row:CreateFontString(nil, "ARTWORK")
    J.Font(row.name, 14, true)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.note = row:CreateFontString(nil, "ARTWORK")
    J.Font(row.note, 11, false, J.FAINT)
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    return row
end

-- The name alone in the middle, or the name above its note.
local function Lay(row, note)
    local left = S.icon + 2 + S.gap
    row.name:ClearAllPoints()
    row.note:ClearAllPoints()
    if note then
        row.name:SetPoint("BOTTOMLEFT", row, "LEFT", left, 0)
        row.name:SetPoint("BOTTOMRIGHT", row, "RIGHT", -2, 0)
        row.note:SetPoint("TOPLEFT", row, "LEFT", left, -1)
        row.note:SetPoint("TOPRIGHT", row, "RIGHT", -2, -1)
    else
        row.name:SetPoint("LEFT", row, "LEFT", left, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    end
end

function Row.Set(row, line, notes)
    row.line = line
    row.icon:SetTexture(line.icon)
    row.icon:SetDesaturated(line.locked)
    row.count:SetText(line.count and line.count > 1 and line.count or "")
    row.name:SetText(line.name)
    row.name:SetTextColor(Row.Color(line.quality))
    local note = notes and ns.Slots.Note(line) or ""
    if line.locked then note = ns.TEXT.locked end
    row.note:SetText(note)
    Lay(row, note ~= "")
    row:SetAlpha(line.locked and J.FAINT[4] or 1)
    row:Show()
end
