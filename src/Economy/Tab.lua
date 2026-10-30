local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy - Tab
--  The tab Deals on the game's auction house window, in the game's own look, and
--  open first (the option Open on Deals):
--
--      Buy now                                Sell now
--      [] Linen Cloth        +1s 20c each     [] Copper Ore     +2g 10s in all
--         10s now, sell Fri for 20s  [ Buy ]     Post at 3s 20c       [ Post ]
--
--  Nothing is written into the game's window: its page is covered by ours and stays
--  as it was, our tab stands after its tabs and marks them as not chosen with the
--  game's own calls while ours is (they set its title too), and a hook on its
--  SetDisplayMode tells when it wants its page back (a tab, an item clicked to post).
--
--  The corner of the window says how much gold you have on sale, on every tab.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Data, Ask = Core.Data, Core.Ask
local PRICES = Data.Series("Prices")
local Tab = {}
ns.Tab = Tab

local TEXT, SIZE = ns.TEXT, ns.SIZE
local GOOD = { 0.3, 0.9, 0.3 }  -- what a deal brings
local SOFT = { 0.7, 0.7, 0.7 }  -- a line's small words
local HOUR = 3 * 3600           -- how long the time a forecast names lasts (Core's Rhythm.lua)
local SIGHT = 12                -- lines asked of the server ahead: as many as a column shows
local TOLD = 4                  -- seconds a word stays on a line
local REFRESH = 5               -- seconds after a change of prices the lists are made anew
local BASE_LEVEL = 100          -- our page over the game's pages, and under its portrait
local OVER_BORDER = 800         -- the gold on sale, over the window's border and title bar

local page, tab, corner, columns = nil, nil, nil, {}
local words = {}                -- [key] = { text, until }: what a line says of what just went on it
local posted = { money = 0, auctions = 0, at = nil }
local given = false

local function Money(copper)
    local whole = math.max(0, math.floor(copper + 0.5))
    return Core.Coins(whole) or ("%dc"):format(whole)
end

local function When(line)
    local at = line.highAt
    if not at or at <= line.at then return nil end
    local text = date("%j", at) == date("%j", line.at) and TEXT.today or date("%a", at)
    if line.allDay then return text end
    return TEXT.when:format(text, Core.ClockAt(at), Core.ClockAt(at + HOUR))
end

local function NameOf(id)
    local name = Core.Plain(Ask(C_Item.GetItemNameByID, id))
    if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return name or "?"
end

local function Color(id)
    local quality = Core.Plain(Ask(C_Item.GetItemQualityByID, id))
    local color = quality and rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[quality]
    if color then return color.r, color.g, color.b end
    return 1, 1, 1
end

local function Told(key)
    local word = words[key]
    if word and word.till > (Ask(rawget(_G, "GetTime")) or 0) then return word.text end
    return nil
end

-------------------------------------------------------------------------------
--  A line
-------------------------------------------------------------------------------
local function Press(button)
    local row = button:GetParent()
    local line = row.line
    if not line then return end
    if row.kind == "buy" then ns.Trade.Buy(line) else ns.Trade.Post(line) end
end

local function Enter(row)
    local line = row.line
    if not line then return end
    GameTooltip:SetOwner(row, "ANCHOR_LEFT")
    if type(line.item) == "string" then GameTooltip:SetHyperlink(line.item) else GameTooltip:SetItemByID(line.id) end
    GameTooltip:Show()
end

local function Leave()
    GameTooltip:Hide()
end

local function Make(row)
    row:SetHeight(SIZE.row)
    row:EnableMouse(true)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(SIZE.icon, SIZE.icon)
    row.icon:SetPoint("LEFT", 4, 0)
    row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.action:SetSize(SIZE.button, SIZE.buttonHigh)
    row.action:SetPoint("BOTTOMRIGHT", -2, 3)
    row.action:SetScript("OnClick", ns.Guard(Press))
    row.gain = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.gain:SetPoint("TOPRIGHT", -4, -3)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 6, 0)
    row.name:SetPoint("TOPRIGHT", row.gain, "TOPLEFT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.note = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.note:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 1)
    row.note:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", SIZE.noteWide, 1)
    row.note:SetJustifyH("LEFT")
    row.note:SetWordWrap(false)
    row.note:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    row:SetScript("OnEnter", ns.Guard(Enter))
    row:SetScript("OnLeave", ns.Guard(Leave))
    row.made = true
end

-- What the button of a line to buy says and does, by what the server told so far.
local function BuyButton(row, line)
    local answer = ns.Live.Offers(line.key)
    local pending = ns.Trade.Pending(line.key)
    local word, on = TEXT.waiting, false
    if pending then
        word, on = TEXT.confirm, true
        row.note:SetText(TEXT.confirmLine:format(pending.units, Money(pending.total)))
    elseif answer then
        local there = answer.commodity and ns.Live.Under(line.key, line.limit, line.most) > 0 or (not answer.commodity and ns.Live.Cheapest(line.key, line.limit))
        word, on = there and TEXT.buy or TEXT.gone, there and true or false
    end
    row.action:SetText(word)
    row.action:SetEnabled(on)
end

local function DrawBuy(row, line)
    row.name:SetText(NameOf(line.id))
    row.name:SetTextColor(Color(line.id))
    row.gain:SetText(TEXT.each:format(Money(line.gain)))
    local when = When(line)
    row.note:SetText(when and TEXT.buyLine:format(Money(line.low), when, Money(line.high)) or TEXT.buyLineNow:format(Money(line.low), Money(line.high)))
    BuyButton(row, line)
end

local function DrawSell(row, line)
    row.name:SetText(line.count > 1 and ("%s x%d"):format(NameOf(line.id), line.count) or NameOf(line.id))
    row.name:SetTextColor(Color(line.id))
    row.gain:SetText(TEXT.total:format(Money(line.total)))
    local parts = { TEXT.sellLine:format(Money(line.price)) }
    if line.here > 0 and #line.there > 0 then parts[2] = TEXT.sellHere:format(line.here) end
    for _, place in ipairs(line.there) do
        if #parts < 3 then parts[#parts + 1] = TEXT.sellThere:format(place.name, place.count) end
    end
    row.note:SetText(table.concat(parts, "  \194\183  "))
    row.action:SetText(TEXT.post)
    row.action:SetEnabled(line.here > 0)
    row.action:SetShown(line.here > 0)
end

local function Draw(row, line, kind)
    if not row.made then Make(row) end
    row.line, row.kind = line, kind
    row.icon:SetTexture(Ask(C_Item.GetItemIconByID, line.id))
    if kind == "buy" then DrawBuy(row, line) else DrawSell(row, line) end
    local word = Told(line.key)
    if word then row.note:SetText(word) end
end

-------------------------------------------------------------------------------
--  The columns
-------------------------------------------------------------------------------
local function Column(kind, head, left, right)
    local column = {}
    local frame = CreateFrame("Frame", nil, page, "InsetFrameTemplate")
    frame:SetPoint("TOPLEFT", page, "TOPLEFT", left, 0)
    frame:SetPoint("BOTTOM", page, "BOTTOM", 0, 0)
    frame:SetPoint("RIGHT", page, "RIGHT", right, 0)
    local caption = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    caption:SetPoint("TOPLEFT", kind == "buy" and SIZE.portrait or 8, -8)
    caption:SetText(head)
    column.empty = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    column.empty:SetPoint("TOPLEFT", 16, -SIZE.head - 16)
    column.empty:SetPoint("RIGHT", -16, 0)
    column.empty:SetJustifyH("LEFT")
    local box = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -SIZE.head)
    box:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -SIZE.scrollbar, 4)
    local bar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 3, -2)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 3, 2)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(SIZE.row)
    view:SetElementInitializer("Button", ns.Guard(function(row, line) Draw(row, line, kind) end))
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    column.box, column.kind, column.frame = box, kind, frame
    return column
end

local function Empty(column, list)
    local text = ""
    if #list == 0 then
        if column.kind == "sell" then
            text = TEXT.noSells
        elseif not PRICES:OnSale() then
            text = TEXT.noScan
        else
            text = TEXT.noBuys .. " " .. TEXT.fewBuys:format(PRICES.TRUSTED)
        end
    end
    column.empty:SetText(text)
    column.empty:SetShown(#list == 0)
end

local function Fill()
    if not page then return end
    local buys, sells = ns.Deals.Buys(), ns.Deals.Sells()
    columns.buy.box:SetDataProvider(CreateDataProvider(buys), ScrollBoxConstants.RetainScrollPosition)
    columns.sell.box:SetDataProvider(CreateDataProvider(sells), ScrollBoxConstants.RetainScrollPosition)
    Empty(columns.buy, buys)
    Empty(columns.sell, sells)
    local keys = {}
    for index = 1, math.min(SIGHT, #buys) do keys[#keys + 1] = buys[index].key end
    for index = 1, math.min(SIGHT, #sells) do
        if sells[index].here > 0 then keys[#keys + 1] = sells[index].key end
    end
    ns.Live.Want(keys)
end

local function Redraw()
    if not (page and page:IsShown()) then return end
    for _, column in pairs(columns) do
        column.box:ForEachFrame(function(row) if row.line then Draw(row, row.line, column.kind) end end)
    end
end

-------------------------------------------------------------------------------
--  The gold on sale
-------------------------------------------------------------------------------
local function Corner()
    if not corner then return end
    local money, _, at = PRICES:OnSale()
    if posted.at ~= at then posted.at, posted.money, posted.auctions = at, 0, 0 end
    local total = (money or 0) + posted.money
    corner.text:SetText(TEXT.onSale:format(Money(total)))
    corner:SetWidth(corner.text:GetStringWidth())
    corner:SetShown(not ns.off)
end

function Tab.Posted(money, auctions)
    posted.money, posted.auctions = posted.money + money, posted.auctions + auctions
    Corner()
end

-------------------------------------------------------------------------------
--  The tab
-------------------------------------------------------------------------------
local function Open()
    if ns.off or not page then return end
    page:Show()
    for _, each in ipairs(AuctionHouseFrame.Tabs or {}) do PanelTemplates_DeselectTab(each) end
    PanelTemplates_SelectTab(tab)
    AuctionHouseFrame:SetTitle(TEXT.tab)
    ns.Deals.Refresh()
    Fill()
end

local function Close()
    if not (page and page:IsShown()) then return end
    page:Hide()
    PanelTemplates_DeselectTab(tab)
    PanelTemplates_UpdateTabs(AuctionHouseFrame)
    AuctionHouseFrame:UpdateTitle()
    ns.Live.Want({})
end

local RefreshSoon = Core.Later(function()
    if page and page:IsShown() then ns.Deals.Refresh() end
    Corner()
end, REFRESH)

local function Build()
    if page or given then return end
    local window = rawget(_G, "AuctionHouseFrame")
    if not window then return end
    page = CreateFrame("Frame", nil, window)
    page:SetPoint("TOPLEFT", window, "TOPLEFT", SIZE.side, -SIZE.top)
    page:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -SIZE.side, SIZE.bottom)
    page:SetFrameLevel(window:GetFrameLevel() + BASE_LEVEL)
    page:EnableMouse(true)
    local ground = page:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(page)
    ground:SetColorTexture(0, 0, 0, 1)
    local half = (window:GetWidth() - 2 * SIZE.side) / 2
    columns.buy = Column("buy", TEXT.buyHead, 0, -(half + SIZE.gap / 2))
    columns.sell = Column("sell", TEXT.sellHead, half + SIZE.gap / 2, 0)
    page:Hide()

    -- The game's tab template joins its parent's list of tabs: its parent is a frame of ours, not the game's window.
    local holder = CreateFrame("Frame", nil, window)
    holder:SetAllPoints(window)
    tab = CreateFrame("Button", nil, holder, "PanelTabButtonTemplate")
    tab:SetText(TEXT.tab)
    tab:SetPoint("LEFT", window.AuctionsTab, "RIGHT", -15, 0)
    PanelTemplates_TabResize(tab, 20, nil, 70)
    PanelTemplates_DeselectTab(tab)
    tab:SetScript("OnClick", ns.Guard(function()
        Core.Sound("IG_CHARACTER_INFO_TAB")
        Open()
    end))

    corner = CreateFrame("Frame", nil, window)
    corner:SetPoint("TOPRIGHT", window, "TOPRIGHT", -SIZE.corner, -2)
    corner:SetHeight(SIZE.cornerHigh)
    corner:SetFrameLevel(window:GetFrameLevel() + OVER_BORDER)
    corner.text = corner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    corner.text:SetPoint("RIGHT")
    corner.text:SetJustifyH("RIGHT")
    Core.Tip(corner, TEXT.onSaleHead, TEXT.onSaleTip)

    hooksecurefunc(window, "SetDisplayMode", ns.Guard(Close))
    Corner()
end

local function Shown()
    Build()
    Corner()
    if ns.options.dealsFirst then Open() end
end
local ShownSoon = Core.Later(Shown)

function Tab.Start()
    Core.On("AUCTION_HOUSE_SHOW", ns.Guard(ShownSoon))
    PRICES:OnChange(ns.Guard(RefreshSoon))
    ns.Deals.Ready(ns.Guard(Fill))
    ns.Live.OnChange(ns.Guard(Redraw))
    ns.Trade.OnChange(ns.Guard(function(key, word)
        if key and word then words[key] = { text = word, till = (Ask(rawget(_G, "GetTime")) or 0) + TOLD } end
        Redraw()
        if word == TEXT.bought or word == TEXT.posted then RefreshSoon() end
    end))
    if Data.OnCharacters then Data.OnCharacters(ns.Guard(RefreshSoon)) end
end

-- The window as the game made it: our tab and page gone, its own tab chosen again.
function Tab.GiveBack()
    given = true
    if page then
        Close()
        page:Hide()
    end
    if tab then tab:Hide() end
    if corner then corner:Hide() end
end
