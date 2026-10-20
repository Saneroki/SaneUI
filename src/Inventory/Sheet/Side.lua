local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Side
--  The pane over the sheet's right that tells of what is chosen on a tab, as
--  the game's sheet has it (CharacterFrameSidePaneTemplate), ours: a title and
--  a subtitle in its middle, the game's line under them, a description, rows
--  (a label with its value, or a wrapped line), and a foot at its bottom for
--  the tab's own switches. Empty, a word in its middle says what to choose.
--
--      local side = ns.Side.New(right, footHeight)
--      ns.Side.Title(side, title, subtitle, titleColor, subtitleColor)
--      ns.Side.Describe(side, text, height)
--      ns.Side.Rows(side)  then  ns.Side.Row(side, label, value, labelColor, valueColor)
--                                ns.Side.Line(side, text, color)
--      ns.Side.Empty(side, text)   -- text: empty, saying it; nil: not empty
--  side.foot is the foot's frame; side.content holds the title down to the rows.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Side = {}
ns.Side = Side

-- The game's sizes: in from the right pane's corners, the title's and rows' width, the empty word's.
Side.LEFT, Side.TOP, Side.RIGHT, Side.BOTTOM = 16, 14, 12, 14
Side.WIDTH, Side.EMPTY_WIDTH, Side.EMPTY_Y = 195, 170, 30
Side.DESCRIPTION = 90 -- a description's height unless a tab says
Side.ROW, Side.GAP = 16, 2

local function Colour(region, color)
    if color then region:SetTextColor(color.r, color.g, color.b) end
end

function Side.New(parent, foot)
    local side = CreateFrame("Frame", nil, parent)
    side:SetPoint("TOPLEFT", parent, "TOPLEFT", Side.LEFT, -Side.TOP)
    side:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -Side.RIGHT, Side.BOTTOM)
    local content = CreateFrame("Frame", nil, side)
    content:SetAllPoints()
    side.content = content
    side.title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalMed3")
    side.title:SetWidth(Side.WIDTH)
    side.title:SetJustifyH("CENTER")
    side.title:SetPoint("TOP")
    side.subtitle = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    side.subtitle:SetWidth(Side.WIDTH)
    side.subtitle:SetJustifyH("CENTER")
    side.subtitle:SetPoint("TOP", side.title, "BOTTOM", 0, -3)
    side.divider = content:CreateTexture(nil, "BORDER")
    side.divider:SetAtlas("UI-Character-Info-ScrollLine", true)
    side.divider:SetPoint("TOP", side.subtitle, "BOTTOM", 0, -4)
    side.description = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    side.description:SetJustifyH("LEFT")
    side.description:SetJustifyV("TOP")
    side.description:SetWordWrap(true)
    side.description:SetPoint("TOP", side.divider, "BOTTOM", 0, -6)
    side.description:SetPoint("LEFT")
    side.description:SetPoint("RIGHT", -14, 0)
    side.rows = CreateFrame("Frame", nil, content)
    side.rows:SetWidth(Side.WIDTH)
    side.rows:SetHeight(1)
    side.rows:SetPoint("TOP", side.description, "BOTTOM", 0, -6)
    side.used, side.made = 0, {}
    side.foot = CreateFrame("Frame", nil, side)
    side.foot:SetPoint("BOTTOMLEFT")
    side.foot:SetPoint("BOTTOMRIGHT")
    side.foot:SetHeight(foot or 1)
    side.empty = side:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    side.empty:SetWidth(Side.EMPTY_WIDTH)
    side.empty:SetJustifyH("CENTER")
    side.empty:SetPoint("CENTER", 0, Side.EMPTY_Y)
    side.empty:Hide()
    return side
end

function Side.Title(side, title, subtitle, titleColor, subtitleColor)
    side.title:SetText(title or "")
    side.subtitle:SetText(subtitle or "")
    Colour(side.title, titleColor or rawget(_G, "NORMAL_FONT_COLOR"))
    Colour(side.subtitle, subtitleColor or rawget(_G, "HIGHLIGHT_FONT_COLOR"))
end

-- The description, that high (or the game's default); none: no room taken.
function Side.Describe(side, text, height, color)
    if text and text ~= "" then
        side.description:SetHeight(height or Side.DESCRIPTION)
        side.description:SetText(text)
        Colour(side.description, color or rawget(_G, "WHITE_FONT_COLOR"))
    else
        side.description:SetText("")
        side.description:SetHeight(1)
    end
end

-- The rows start anew.
function Side.Rows(side)
    for _, row in ipairs(side.made) do row:Hide() end
    side.used = 0
    side.rows:SetHeight(1)
end

local function Next(side)
    side.used = side.used + 1
    local row = side.made[side.used]
    if not row then
        row = CreateFrame("Frame", nil, side.rows)
        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.value = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        side.made[side.used] = row
    end
    row:ClearAllPoints()
    row:SetWidth(Side.WIDTH)
    if side.used == 1 then
        row:SetPoint("TOP", side.rows, "TOP")
    else
        row:SetPoint("TOP", side.made[side.used - 1], "BOTTOM", 0, -Side.GAP)
    end
    row.label:ClearAllPoints()
    row.value:ClearAllPoints()
    row:Show()
    return row
end

-- A row of a label and its value, side by side.
function Side.Row(side, label, value, labelColor, valueColor)
    local row = Next(side)
    row:SetHeight(Side.ROW)
    row.label:SetWidth(0)
    row.label:SetWordWrap(false)
    row.label:SetJustifyH("LEFT")
    row.label:SetPoint("LEFT")
    row.label:SetText(label or "")
    Colour(row.label, labelColor or rawget(_G, "NORMAL_FONT_COLOR"))
    row.value:SetPoint("RIGHT")
    row.value:SetText(value or "")
    Colour(row.value, valueColor or rawget(_G, "HIGHLIGHT_FONT_COLOR"))
    row.value:Show()
    return row
end

-- A row of one wrapped line.
function Side.Line(side, text, color)
    local row = Next(side)
    row.label:SetWidth(Side.WIDTH)
    row.label:SetWordWrap(true)
    row.label:SetJustifyH("LEFT")
    row.label:SetPoint("TOPLEFT")
    row.label:SetText(text or "")
    Colour(row.label, color or rawget(_G, "NORMAL_FONT_COLOR"))
    row.value:Hide()
    row:SetHeight(math.max(1, Core.Plain(row.label:GetStringHeight()) or Side.ROW))
    return row
end

-- Empty (text: what to choose) or not (nil): the content goes, or comes back.
function Side.Empty(side, text)
    side.empty:SetText(text or "")
    side.empty:SetShown(text ~= nil)
    side.content:SetShown(text == nil)
end
