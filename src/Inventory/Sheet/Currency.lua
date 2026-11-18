local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Sheet - Currency
--  The sheet's currency tab, as the game's sheet has it (Camelot's TokenFrame),
--  ours: over the left pane your currencies (C_CurrencyInfo's list) in the
--  game's looks: its headers (a click folds or unfolds them, Rows.lua), its
--  sub-headers with their fold button, and a currency as the game draws it:
--  its name, how many you have and its icon at the right (greyed while you have
--  none), a tick while it shows on the backpack. A click chooses a currency;
--  Shift and a click links it in the chat, the game's watch key and a click
--  shows it on the backpack or not. At the right (Side.lua) the chosen one: its
--  name, icon and count, its description, its total and weekly caps, what an
--  account transfer loses or that the whole account shares it, and the game's
--  two switches: unused, shown on the backpack.
--
--  The game's currency transfer opens a panel of the game's window manager,
--  which our code must not open (Doc/guides/addon-standards.md, Known traps):
--  it stays on the game's own sheet. Showing a currency on the backpack is the
--  game's own call; how many the backpack has room for is the game's to say.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Currency = {}
ns.Currency = Currency

-- The game's sizes (Blizzard_TokenUI.xml, .lua): a header's and a currency's height, the icon, the tick, the
-- description's height, and how far rows are set in by their depth in the list.
Currency.HEADER, Currency.ENTRY = 26, 22
Currency.ICON, Currency.ICON_RIGHT, Currency.CHECK = 20, 20, 16
Currency.DESCRIPTION = 90
Currency.INDENT_FIRST, Currency.INDENT_DEEP = 2, 50

local list, side, unused, backpack
local chosen -- the chosen currency's place in the list, and its name (the game's TokenFrame keeps both)
local chosenName

local function Info()
    return rawget(_G, "C_CurrencyInfo") or {}
end

local function Big(number)
    local big = rawget(_G, "BreakUpLargeNumbers")
    return big and big(number or 0) or tostring(number or 0)
end

local function Kind(data)
    if data.isHeader and (data.currencyListDepth or 0) == 0 then return "header" end
    if data.isHeader then return "subheader" end
    return "entry"
end

-- How far a row is set in by its depth, as the game sets it in.
local function Indent(data)
    local depth = data.currencyListDepth or 0
    if data.isHeader and depth == 0 then return 0 end
    if depth == 1 then return Currency.INDENT_FIRST end
    return Currency.INDENT_DEEP * (depth - 1)
end

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local function Fold(row)
    local data = row.data
    if not data then return end
    Core.Ask(Info().ExpandCurrencyList, data.currencyIndex, not data.isHeaderExpanded)
    Currency.Refresh()
end

local function Light(row)
    local data = row.data
    if not data or Kind(data) ~= "entry" then return end
    local isChosen, over = data.name == chosenName, row:IsMouseOver()
    ns.Rows.Light(row, (isChosen and 0.20) or (over and 0.10) or 0)
end

-- A click: Shift links the currency, the watch key shows it on the backpack or not, else it is chosen.
local function Choose(row)
    local data = row.data
    if not data then return end
    if Kind(data) == "subheader" then return Fold(row) end
    if IsModifiedClick("CHATLINK") and HandleModifiedItemClick(Core.Ask(Info().GetCurrencyListLink, data.currencyIndex)) then
        return
    end
    if IsModifiedClick("TOKENWATCHTOGGLE") then
        Core.Ask(Info().SetCurrencyBackpack, data.currencyIndex, not data.isShowInBackpack)
    else
        chosen, chosenName = data.currencyIndex, data.name
    end
    Currency.Refresh()
end

local OWNER = { click = Choose, fold = Fold, enter = Light, leave = Light }

-- A currency's own parts at the right of its row: its icon, how many, the backpack's tick.
local function Parts(row)
    if row.coin then return end
    row.coin = row:CreateTexture(nil, "ARTWORK")
    row.coin:SetSize(Currency.ICON, Currency.ICON)
    row.coin:SetPoint("RIGHT", -Currency.ICON_RIGHT, 0)
    row.count = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightRight")
    row.count:SetPoint("RIGHT", row.coin, "LEFT", -5, 0)
    row.watched = row:CreateTexture(nil, "OVERLAY")
    row.watched:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.watched:SetSize(Currency.CHECK, Currency.CHECK)
    row.watched:SetPoint("LEFT", row.coin, "RIGHT", 0, 0)
end

local function Draw(row, data)
    row.data = data
    local kind = Kind(data)
    local collapsed = not data.isHeaderExpanded
    ns.Rows.Draw(row, kind, data.name, collapsed, OWNER, Indent(data))
    Parts(row)
    row.bar:Hide()
    local entry = kind == "entry"
    row.coin:SetShown(entry)
    row.count:SetShown(entry)
    row.watched:SetShown(entry and data.isShowInBackpack and true or false)
    if kind == "subheader" then
        row.name:SetFontObject("GameFontHighlightLeft")
        row.name:SetPoint("RIGHT", -10, 0)
    end
    if not entry then return end
    row.name:SetFontObject("GameFontHighlightLeft")
    row.name:ClearAllPoints()
    row.name:SetPoint("LEFT", ns.Rows.NAME_LEFT + Indent(data), 0)
    row.name:SetPoint("RIGHT", row.count, "LEFT", -10, 0)
    row.count:SetText(Big(data.quantity))
    row.coin:SetTexture(data.iconFileID)
    local color = (data.quantity or 0) > 0 and rawget(_G, "HIGHLIGHT_FONT_COLOR") or rawget(_G, "DISABLED_FONT_COLOR")
    if color then
        row.count:SetTextColor(color.r, color.g, color.b)
        row.name:SetTextColor(color.r, color.g, color.b)
    end
    Light(row)
end

local function Extent(data)
    return Kind(data) == "entry" and Currency.ENTRY or Currency.HEADER
end

-------------------------------------------------------------------------------
--  The chosen currency, at the right
-------------------------------------------------------------------------------
local function Unused(box)
    ns.Side.Sound(box)
    Core.Ask(Info().SetCurrencyUnused, chosen, box:GetChecked() and true or false)
    Currency.Refresh()
end

local function Backpack(box)
    ns.Side.Sound(box)
    Core.Ask(Info().SetCurrencyBackpack, chosen, box:GetChecked() and true or false)
    Currency.Refresh()
end

-- The pane at the right: the chosen currency, or a word to choose one (TokenDetailFrameMixin:Refresh).
function Currency.Detail()
    if not side then return end
    local data = chosen and Core.Ask(Info().GetCurrencyListInfo, chosen)
    if type(data) ~= "table" or data.isHeader then
        ns.Side.Empty(side, Core.Word("TOKEN_DETAIL_SELECT_PROMPT", "Select a currency to see more about it."))
        unused:Hide()
        backpack:Hide()
        return
    end
    ns.Side.Empty(side, nil)
    local markup = rawget(_G, "CreateSimpleTextureMarkup")
    local icon = markup and markup(data.iconFileID or 0, 16, 16) or ""
    ns.Side.Title(side, data.name, icon .. " " .. Big(data.quantity), rawget(_G, "CHARACTER_FRAME_SIDE_PANEL_CURRENCY_COLOR"))
    ns.Side.Describe(side, Core.Ask(Info().GetCurrencyDescription, data.currencyID) or "", Currency.DESCRIPTION)
    ns.Side.Rows(side)
    if (data.maxQuantity or 0) > 0 then
        ns.Side.Row(side, Core.Word("CURRENCY_DETAIL_TOTAL_CAP_LABEL", "Total Maximum"), Big(data.maxQuantity))
    end
    if data.canEarnPerWeek and (data.maxWeeklyQuantity or 0) > 0 then
        ns.Side.Row(side, Core.Word("CURRENCY_DETAIL_WEEKLY_CAP_LABEL", "Weekly Maximum"),
            Big(data.quantityEarnedThisWeek) .. " / " .. Big(data.maxWeeklyQuantity))
    end
    if data.isAccountTransferable then
        local lost = data.transferPercentage and (100 - data.transferPercentage) or 0
        if lost > 0 then
            ns.Side.Spacer(side, 4)
            ns.Side.Line(side, Core.Word("CURRENCY_TRANSFER_LOSS", "%d%% is lost in a transfer."):format(math.ceil(lost)),
                rawget(_G, "NORMAL_FONT_COLOR"))
        end
    elseif data.isAccountWide then
        ns.Side.Spacer(side, 4)
        ns.Side.Line(side, Core.Word("ACCOUNT_LEVEL_CURRENCY", "Shared by your whole account."), rawget(_G, "GREEN_FONT_COLOR"))
    end
    unused:SetShown(data.discovered and true or false)
    unused:SetChecked(data.isTypeUnused and true or false)
    backpack:SetShown(data.discovered and true or false)
    backpack:SetChecked(data.isShowInBackpack and true or false)
end

-------------------------------------------------------------------------------
--  The tab
-------------------------------------------------------------------------------
-- The list as the game has it now; the choice kept by name (it moves when headers fold), else the first currency.
function Currency.Refresh()
    if not list then return end
    local elements, found, first = {}, nil, nil
    for index = 1, Core.Ask(Info().GetCurrencyListSize) or 0 do
        local data = Core.Ask(Info().GetCurrencyListInfo, index)
        if type(data) == "table" then
            data.currencyIndex = index
            elements[#elements + 1] = data
            if not data.isHeader then
                first = first or data
                if chosenName and data.name == chosenName then found = data end
            end
        end
    end
    if found then
        chosen = found.currencyIndex
    elseif first and not chosenName then
        chosen, chosenName = first.currencyIndex, first.name
    else
        chosen, chosenName = nil, nil
    end
    ns.List.Fill(list, elements)
    Currency.Detail()
end

local function Build(left, right)
    list = ns.List.New(left, { extent = Extent, draw = Draw })
    side = ns.Side.New(right, ns.Side.Foot(2))
    unused = ns.Side.Check(side.foot, Core.Word("UNUSED", "Unused"), Core.Word("TOKEN_MOVE_TO_UNUSED", ""), nil, Unused)
    unused:SetPoint("TOPLEFT", side.foot, "TOPLEFT", -4, 0)
    backpack = ns.Side.Check(side.foot, Core.Word("SHOW_ON_BACKPACK", "Show on Backpack"), Core.Word("TOKEN_SHOW_ON_BACKPACK", ""), nil, Backpack)
    backpack:SetPoint("TOPLEFT", unused, "BOTTOMLEFT", 0, -ns.Side.CHECK_GAP)
end

local later = Core.Later(function() ns.Safe("character", Currency.Refresh) end)
local EVENTS = { "CURRENCY_DISPLAY_UPDATE", "ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED" }

-- Shown: drawn as the game has it, and anew when it changes; hidden, the choice starts afresh next time, as the
-- game's does.
local function Show(on)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, later) else Core.Off(event, later) end
    end
    if on then
        Currency.Refresh()
    else
        chosen, chosenName = nil, nil
    end
end

-- A window of its own on the board: the currencies at the left, the chosen one at the right.
ns.Page.Part("currency", Core.Word("CURRENCY", "Currency"), ns.Page.Least(ns.List.LEAST + ns.Page.SIDE, ns.List.LEAST_HEIGHT),
    { side = true, Build = Build, Show = Show })
