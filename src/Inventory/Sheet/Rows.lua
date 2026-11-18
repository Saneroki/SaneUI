local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Sheet - Rows
--  The rows the sheet's reputation and skills tabs list, in the game's three
--  looks (ReputationFrame.xml, SkillsFrame.xml, the same in both):
--      header     the game's collapse-and-expand art, its name, its fold sign
--                 (plus or minus) at its right; a click folds or unfolds it
--      subheader  a header with a value of its own: its fold button at its left
--                 (campaign_headericon), its name, its bar
--      entry      its name and the game's coloured bar (ColoredProgressBarTemplate;
--                 Forever's: where the game has none, Retail, ours, Rows.Bar)
--  An entry or subheader is lit as the game lights them: a faint light that is
--  brighter while it is chosen or under the mouse, in the colour its tab says.
--
--      Rows.Draw(row, kind, name, collapsed, owner, indent)   -- indent: how far in from the left (skills
--                                                             -- under a sub-header, as the game indents them)
--          owner = { click = function(row) end, fold = function(row) end,
--                    enter = function(row) end, leave = function(row) end }
--      Rows.Light(row, alpha, color)
--      Rows.Bar(parent)   -- a coloured bar: bar:SetFillPercent(share), bar:SetText(text), bar.Fill
--  Every part of a row is made once (a row is drawn for another kind than it was
--  last as the list scrolls); its scripts call its owner's functions, ns.Safe.
-------------------------------------------------------------------------------
local Rows = {}
ns.Rows = Rows

-- The game's sizes: a row's height for each look, the bars, where the names start.
Rows.HEADER, Rows.SUBHEADER, Rows.ENTRY = 28, 22, 30
Rows.BAR, Rows.BAR_HEIGHT, Rows.SIDE_BAR = 160, 29, 180
Rows.NAME_LEFT, Rows.HEADER_LEFT = 15, 10
-- Our bar where the game has no coloured bar: its track in from the bar's sides and as high as the game's fill,
-- the game's plain status bar texture as its fill (both games have it), tinted by the tab.
Rows.TRACK_INSET, Rows.TRACK = 6, 15
Rows.FILL = "Interface\\TargetingFrame\\UI-StatusBar"

-- Our bar's calls, as the game's bar answers them (ColoredProgressBarMixin): the fill that share of the track.
local function OwnFill(bar, share)
    share = math.min(1, math.max(0, tonumber(share) or 0))
    local width = (bar:GetWidth() or 0) - 2 * Rows.TRACK_INSET
    bar.Fill:SetWidth(math.max(1, share * width))
    bar.Fill:SetTexCoord(0, share, 0, 1)
    bar.Fill:SetShown(share > 0)
end

local function OwnText(bar, text)
    bar.Text:SetText(text)
end

-- A coloured bar: the game's (ColoredProgressBarTemplate, Forever's), else ours with the same calls and parts.
function Rows.Bar(parent)
    if rawget(_G, "ColoredProgressBarMixin") then return CreateFrame("Frame", nil, parent, "ColoredProgressBarTemplate") end
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetSize(Rows.BAR, Rows.BAR_HEIGHT)
    bar.track = bar:CreateTexture(nil, "BACKGROUND")
    bar.track:SetColorTexture(0, 0, 0, 0.5)
    bar.track:SetPoint("LEFT", Rows.TRACK_INSET, 0)
    bar.track:SetPoint("RIGHT", -Rows.TRACK_INSET, 0)
    bar.track:SetHeight(Rows.TRACK)
    bar.Fill = bar:CreateTexture(nil, "BORDER")
    bar.Fill:SetTexture(Rows.FILL)
    bar.Fill:SetPoint("TOPLEFT", bar.track, "TOPLEFT")
    bar.Fill:SetPoint("BOTTOMLEFT", bar.track, "BOTTOMLEFT")
    bar.Fill:Hide()
    bar.Text = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    bar.Text:SetPoint("LEFT")
    bar.Text:SetPoint("RIGHT")
    bar.SetFillPercent, bar.SetText = OwnFill, OwnText
    return bar
end

local function Call(row, name)
    local owner = row.owner
    if owner and owner[name] then owner[name](row) end
end

local function Clicked(row)
    if row.kind == "header" then Call(row, "fold") else Call(row, "click") end
end

local function Folded(row)
    Call(row, "fold")
end

local function Entered(row)
    Call(row, "enter")
end

local function Left(row)
    Call(row, "leave")
end

-- Every part a row may need, made once.
local function Parts(row)
    if row.name then return end
    row:RegisterForClicks("LeftButtonUp")
    row.headBack = row:CreateTexture(nil, "BACKGROUND")
    row.headBack:SetAtlas("common-button-list-collapseExpand")
    row.headLight = row:CreateTexture(nil, "HIGHLIGHT")
    row.headLight:SetAtlas("common-button-list-collapseExpand")
    row.headLight:SetBlendMode("ADD")
    row.headLight:SetAlpha(0.3)
    row.headLight:SetAllPoints()
    row.state = row:CreateTexture(nil, "BORDER")
    row.state:SetPoint("RIGHT", -8, -1)
    row.light = CreateFrame("Frame", nil, row)
    row.light:SetFrameLevel(math.max(0, row:GetFrameLevel() - 1))
    local leftSide = row.light:CreateTexture(nil, "BACKGROUND")
    leftSide:SetAtlas("charactercreate-customize-dropdown-linemouseover-side")
    leftSide:SetWidth(6)
    leftSide:SetPoint("TOPLEFT")
    leftSide:SetPoint("BOTTOMLEFT")
    local rightSide = row.light:CreateTexture(nil, "BACKGROUND")
    rightSide:SetAtlas("charactercreate-customize-dropdown-linemouseover-side")
    rightSide:SetWidth(6)
    rightSide:SetPoint("TOPRIGHT")
    rightSide:SetPoint("BOTTOMRIGHT")
    local middle = row.light:CreateTexture(nil, "BACKGROUND")
    middle:SetAtlas("charactercreate-customize-dropdown-linemouseover-middle")
    middle:SetPoint("TOPLEFT", leftSide, "TOPRIGHT")
    middle:SetPoint("BOTTOMRIGHT", rightSide, "BOTTOMLEFT")
    row.light.parts = { leftSide, rightSide, middle }
    row.toggle = CreateFrame("Button", nil, row)
    row.toggle:SetSize(20, 20)
    row.toggle:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    row.toggle:SetScript("OnClick", function() ns.Safe("character", Folded, row) end)
    row.bar = Rows.Bar(row)
    row.bar:SetSize(Rows.BAR, Rows.BAR_HEIGHT)
    row.bar:SetPoint("RIGHT", -3, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.name:SetHeight(15)
    row:SetScript("OnClick", function(self) ns.Safe("character", Clicked, self) end)
    row:SetScript("OnEnter", function(self) ns.Safe("character", Entered, self) end)
    row:SetScript("OnLeave", function(self) ns.Safe("character", Left, self) end)
end

-- A row drawn in a look: its parts shown or hidden, its name placed; the tab fills the bar and the light.
function Rows.Draw(row, kind, name, collapsed, owner, indent)
    Parts(row)
    row.kind, row.owner = kind, owner
    indent = indent or 0
    row.headBack:ClearAllPoints()
    row.headBack:SetPoint("TOPLEFT", indent, 0)
    row.headBack:SetPoint("BOTTOMRIGHT")
    row.light:ClearAllPoints()
    row.light:SetPoint("TOPLEFT", indent, 0)
    row.light:SetPoint("BOTTOMRIGHT")
    row.toggle:ClearAllPoints()
    row.toggle:SetPoint("LEFT", 2 + indent, 0)
    local header = kind == "header"
    row.headBack:SetShown(header)
    row.headLight:SetShown(header)
    row.state:SetShown(header)
    row.light:SetShown(not header)
    row.bar:SetShown(not header)
    row.toggle:SetShown(kind == "subheader")
    row.name:ClearAllPoints()
    row.name:SetText(name or "")
    if header then
        row.name:SetFontObject("GameFontNormalLeft")
        row.name:SetPoint("LEFT", Rows.HEADER_LEFT + indent, 0)
        row.name:SetPoint("RIGHT", row.state, "LEFT", -4, 0)
        row.state:SetAtlas(collapsed and "common-button-list-plus" or "common-button-list-minus", true)
        return
    end
    row.name:SetFontObject("GameFontHighlight")
    if kind == "subheader" then
        row.toggle:SetNormalAtlas(collapsed and "campaign_headericon_closed" or "campaign_headericon_open")
        row.toggle:SetPushedAtlas(collapsed and "campaign_headericon_closedpressed" or "campaign_headericon_openpressed")
        row.name:SetPoint("LEFT", row.toggle, "RIGHT", 3, 0)
    else
        row.name:SetPoint("LEFT", Rows.NAME_LEFT + indent, 0)
    end
    row.name:SetPoint("RIGHT", row.bar, "LEFT", -10, 0)
end

-- The row's light: that bright, in that colour (white without one).
function Rows.Light(row, alpha, color)
    color = color or rawget(_G, "WHITE_FONT_COLOR")
    for _, part in ipairs(row.light.parts) do
        if color then part:SetVertexColor(color.r, color.g, color.b) end
    end
    row.light:SetAlpha(alpha)
end

-- A row's height for its look.
function Rows.Height(kind)
    if kind == "header" then return Rows.HEADER end
    if kind == "subheader" then return Rows.SUBHEADER end
    return Rows.ENTRY
end
