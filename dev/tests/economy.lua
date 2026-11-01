-- Runs the Economy module against the stand-in client (wowstub.lua): what is worth buying and selling right now from
-- made-up prices, the server asked one item at a time, a purchase and a post from a click only, what is bought going by the
-- server's answer and never over the line's limit, the tab on the game's window and the gold on sale, and standing down.
-- The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/economy.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local money = 100000
GetMoney = function() return money end

-- The game's lists and templates: a list keeps its lines, a line is drawn for each
local noop = function() end
CreateScrollBoxListLinearView = function()
    local view = {}
    function view:SetElementExtent() end
    function view:SetElementInitializer(_, init) self.init = init end
    return view
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.view = view end }
CreateDataProvider = function(elements) return { elements = elements } end
ScrollBoxConstants = { RetainScrollPosition = true }
W.templates.WowScrollBoxList = function(box)
    box.rows = {}
    function box:SetDataProvider(provider)
        self.lines = provider.elements
        for index, line in ipairs(provider.elements) do
            local row = self.rows[index]
            if not row then
                row = CreateFrame("Button", nil, self)
                self.rows[index] = row
            end
            self.view.init(row, line)
        end
    end
    function box:ForEachFrame(fn)
        for index = 1, #(self.lines or {}) do fn(self.rows[index]) end
    end
end
W.templates.MinimalScrollBar = noop
W.templates.InsetFrameTemplate = noop
W.templates.UIPanelButtonTemplate = noop
W.templates.PanelTabButtonTemplate = function(tab) -- it joins its parent's list of tabs, as the game's does
    local parent = tab:GetParent()
    local list = rawget(parent, "Tabs") or {}
    parent.Tabs = list
    list[#list + 1] = tab
end
PanelTemplates_DeselectTab = function(tab) tab.chosen = false end
PanelTemplates_SelectTab = function(tab) tab.chosen = true end
PanelTemplates_TabResize = noop
local updated = 0
PanelTemplates_UpdateTabs = function() updated = updated + 1 end
ItemLocation = {}
function ItemLocation:CreateFromBagAndSlot(bag, slot)
    return { bag = bag, slot = slot, IsValid = function() return true end }
end
Enum.AuctionHouseSortOrder = { Price = 0 }
Enum.ItemCommodityStatus = { Unknown = 0, Item = 1, Commodity = 2 }

-- The game's auction house: offers the test sets, every restricted call noted, and failing without a click
local clicked = false
local calls, searches = {}, {}
local ready = true
local commodities, items = {}, {}
local function Restricted(name, fn)
    return function(...)
        if not clicked then error(name .. " without a click") end
        calls[#calls + 1] = { name, ... }
        return fn and fn(...)
    end
end
C_AuctionHouse = {
    IsThrottledMessageSystemReady = function() return ready end,
    MakeItemKey = function(item, level, suffix, species) return { itemID = item, itemLevel = level or 0, itemSuffix = suffix or 0, battlePetSpeciesID = species or 0 } end,
    SendSearchQuery = function(key) searches[#searches + 1] = key end,
    GetNumCommoditySearchResults = function(item) return #(commodities[item] or {}) end,
    GetCommoditySearchResultInfo = function(item, index) return commodities[item][index] end,
    GetCommoditySearchResultsQuantity = function() return 0 end,
    GetNumItemSearchResults = function(key) return #(items[key.itemID] or {}) end,
    GetItemSearchResultInfo = function(key, index) return items[key.itemID][index] end,
    GetItemSearchResultsQuantity = function() return 0 end,
    PlaceBid = Restricted("PlaceBid"),
    StartCommoditiesPurchase = Restricted("StartCommoditiesPurchase"),
    ConfirmCommoditiesPurchase = Restricted("ConfirmCommoditiesPurchase"),
    CancelCommoditiesPurchase = function() calls[#calls + 1] = { "CancelCommoditiesPurchase" } end,
    PostItem = Restricted("PostItem", function() return C_AuctionHouse.warns end),
    PostCommodity = Restricted("PostCommodity", function() return C_AuctionHouse.warns end),
    IsSellItemValid = function() return true end,
    GetItemCommodityStatus = function() return C_AuctionHouse.status end,
    GetAvailablePostCount = function() return 7 end,
}
C_AuctionHouse.status = Enum.ItemCommodityStatus.Commodity
local function Click(button)
    clicked = true
    button._scripts.OnClick(button, "LeftButton")
    clicked = false
end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Economy", "SaneUI_Economy")
W.Fire("ADDON_LOADED", "SaneUI_Economy")
W.Fire("PLAYER_LOGIN")
W.Fire("ADDON_LOADED", "SaneUI_AuctionData")
local Core = SaneUI.Core
local Data = Core.Data
local Prices, Rhythm = Data.Series("Prices"), Data.Rhythm
local Deals, Live, Trade, TEXT = ns.Deals, ns.Live, ns.Trade, ns.TEXT
local function Coins(copper) return Core.Coins(copper) or ("%dc"):format(copper) end
check(ns.options.dealsFirst == true, "the auction house opens on Deals at first")

-- Core's steps run to the end (the lists are made in steps).
local function Steps()
    local frame = Core.Steps.frame
    for _ = 1, 100 do
        local update = frame._scripts.OnUpdate
        if not update then return end
        W.ms = (W.ms or 0) + 16
        update(frame, 0.016)
    end
end

-------------------------------------------------------------------------------
--  The bags walked for what can be posted (before any price: the lists stay empty)
-------------------------------------------------------------------------------
-- The backpack and the bags, and in Retail the reagent bag after them (its constant; Forever has none).
local walked = {}
C_Container = { GetContainerNumSlots = function(bag) walked[#walked + 1] = bag return 0 end }
Constants.InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 }
Deals.Refresh()
Steps()
check(#walked == 6 and walked[1] == 0 and walked[6] == 5, "Retail: the reagent bag (5) walked after the backpack and the four bags: " .. #walked)
walked = {}
Constants.InventoryConstants = nil
Deals.Refresh()
Steps()
check(#walked == 5 and walked[5] == 4, "Forever, without the constant: the backpack and the four bags alone: " .. #walked)
C_Container = nil

-------------------------------------------------------------------------------
--  Prices the scans left
-------------------------------------------------------------------------------
local house = Prices.House("player")
local now = GetServerTime()
local DAY = 86400
local vendors = { [2589] = 13, [2592] = 33, [1000] = 2000, [1001] = 2000 }
C_Item.GetItemInfo = function(id)
    return "Thing", nil, nil, nil, nil, nil, nil, (id == 1000 or id == 1001) and 1 or 20, nil, nil, vendors[id] or 0
end

-- Three weeks at a usual price, seen selling so many a day.
local function Known(key, usual, sold)
    local line
    for step = 21 * 8, 1, -1 do line = Rhythm.Seen(line, now - step * 3 * 3600, usual) end
    house.rhythm[key] = sold and Rhythm.Sold(line, now, sold * 7, sold * 7 * usual) or line
end
local function Listed(key, low, units, auctions)
    Prices.Take(house, key, now, low, low, units or 20, auctions or 4, 2)
end
house.watched, house.watchedAt, house.kept = 7 * DAY, now, now
Known("2589", 1000, 10)  Listed("2589", 500)            -- half its usual price, and it sells
Known("2592", 1000, 10)  Listed("2592", 990)            -- about its usual price
Known("3000", 1000)      Listed("3000", 500)            -- cheap, but nobody buys it
Known("1000", 50000, 3)  Listed("1000", 20000, 1, 1)    -- gear, a single piece, cheap
Known("1001", 50000, 3)  Listed("1001", 50000, 1, 1)    -- gear at its usual price
Prices.Offers(house, { ["2589"] = { 400 * Prices.UNITS + 8, 500 * Prices.UNITS + 200, 900 * Prices.UNITS + 3, 5000 * Prices.UNITS + 20 } })
Prices.Changed()

check(#Prices:Scanned() == 5, "the last scan's items")
local line = Deals.Buy("2589")
check(line and line.low == 500 and line.limit == math.floor((math.floor(999 * 0.95) - 20) / 1.1), "cheap, selling: a deal, its limit after the cut, the post and a margin: " .. tostring(line and line.limit))
check(line.gain == math.floor(1000 * 0.95) - 20 - 500, "and what one brings: the 1s post shared by a lot of five")
check(line.most == 70, "at most a week of sales, though more cost less: " .. tostring(line.most))
check(Deals.Buy("2592") == nil, "at its usual price: no deal")
check(Deals.Buy("3000") == nil, "seen not selling: no deal, however cheap")
check(Deals.Buy("1000").limit % 1 == 0, "gear is a deal too")
house.watched = nil
Prices.Changed()
check(Deals.Buy("2589") == nil, "while selling is not known yet: no deal, it has to be likely")
house.watched = 7 * DAY
Prices.Changed()

local mine = { key = "1001", id = 1001, item = 1001, count = 1, here = 1, bag = 0, slot = 3, there = {} }
local sell = Deals.Sell(mine)
check(sell and sell.price == 49900 and sell.vendor == 2000, "gear to sell: under the lowest offer by whole silver: " .. tostring(sell and sell.price))
check(sell.gain == math.floor(49900 * 0.95) - math.max(100, math.floor(2000 * 0.2)) - 2000, "it brings what a sale leaves over a vendor: " .. tostring(sell.gain))
vendors[1001] = 48000
check(Deals.Sell({ key = "1001", id = 1001, item = 1001, count = 1, here = 1, there = {} }) == nil, "a vendor pays as much: not for the auction house")
vendors[1001] = 2000
check(Deals.Sell({ key = "1000", id = 1000, item = 1000, count = 1, here = 1, there = {} }) == nil, "far under its usual price: better kept")
check(Deals.Sell({ key = "9", id = 9, item = 9, count = 1, here = 1, there = {} }) == nil, "no price: nothing to say")

-- The neutral house: cheap here, dear there, by its own fees
local side = UnitFactionGroup
UnitFactionGroup = function(unit) if unit == "npc" then return "Neutral" end return side(unit) end
local neutral = Prices.House("npc")
UnitFactionGroup = side
local function There(key, usual, low)
    local kept = house
    house = neutral
    Known(key, usual, 10)
    house = kept
    Prices.Take(neutral, key, now, low, usual, 10, 10, 1)
end
neutral.watched, neutral.watchedAt = 7 * DAY, now
Known("2600", 1000, 10)  Listed("2600", 1000)           -- at its usual price here, far dearer there
There("2600", 5000, 4800)
Known("2601", 1000, 10)  Listed("2601", 1000)           -- a little dearer there: not worth the way
There("2601", 1300, 1200)
vendors[2600], vendors[2601] = 10, 10
Prices.Changed()
local away = Deals.Buy("2600")
check(away and away.side == "neutral" and away.limit == math.floor((math.floor(4999 * 0.85) - 100 / 1) / 1.25), "not cheap here, but far dearer in the neutral house: a deal there, by its fees: " .. tostring(away and away.limit))
check(away.gain == math.floor(4999 * 0.85) - 100 - 1000 and away.high == 5000, "what one brings after its cut, the post, and what it cost")
check(Deals.Buy("2601") == nil, "a little dearer there: after its cut no deal")
local both = Deals.Buy("2589")
check(both and both.side == nil, "cheap here and with nothing there: a deal here")
local taken = Deals.Sell({ key = "2600", id = 2600, item = 2600, count = 3, here = 3, bag = 0, slot = 4, there = {} })
check(taken and taken.side == "neutral" and taken.price == 5000 and taken.total == (math.floor(4999 * 0.85) - 100 - 10) * 3, "yours to sell, and the other house pays clearly more: the line says to take it there")
check(Deals.Sell({ key = "2601", id = 2601, item = 2601, count = 3, here = 3, bag = 0, slot = 4, there = {} }).side == nil, "a little more there: sold here")
Listed("2600", 0)
Listed("2601", 0)
Prices.Changed()

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
AuctionHouseFrame = CreateFrame("Frame", "AuctionHouseFrame", UIParent)
AuctionHouseFrame:SetSize(800, 538)
AuctionHouseFrame.AuctionsTab = CreateFrame("Button", nil, AuctionHouseFrame)
AuctionHouseFrame.Tabs = { AuctionHouseFrame.AuctionsTab }
function AuctionHouseFrame:SetDisplayMode(mode) self.mode = mode end
function AuctionHouseFrame:SetTitle(title) self.title = title end
function AuctionHouseFrame:UpdateTitle() self.title = "the game's" end
house.onSale, house.onSaleCount = 30000, 2
W.Fire("AUCTION_HOUSE_SHOW")
W.Wait(0.1)
W.Wait(0.1)
local function Frames(kind)
    local found = {}
    for _, frame in ipairs(W.frames) do
        if frame._kind == kind then found[#found + 1] = frame end
    end
    return found
end
local page, tab, corner
for _, frame in ipairs(W.frames) do
    if frame._kind == "Button" and frame ~= AuctionHouseFrame.AuctionsTab and frame._parent and frame._parent._parent == AuctionHouseFrame then tab = frame end
    if frame._parent == AuctionHouseFrame and frame.text then corner = frame end
    if frame._parent == AuctionHouseFrame and frame._kind == "Frame" and not frame.text and frame:IsShown() and frame._scripts ~= nil and frame ~= corner then
        if #(frame._children or {}) > 0 or not page then page = page or frame end
    end
end
check(tab and tab:GetText() == TEXT.tab and tab.chosen == true, "a tab Deals stands on the game's window, and it is chosen: it opens first")
check(page and page:IsShown() and AuctionHouseFrame.AuctionsTab.chosen == false, "its page is up, the game's tabs not chosen")
check(AuctionHouseFrame.title == TEXT.tab, "and the window is called so")
check(AuctionHouseFrame.Tabs[2] == nil, "the game's list of tabs is left alone")
local total = corner.text:GetText()
check(total == TEXT.onSale:format(Coins(30000)), "the gold on sale in the corner: " .. tostring(total))
Steps()
local buys = Deals.Buys()
check(#buys == 2 and buys[1].key == "2589" and buys[2].key == "1000", "the lists are made in steps, the deal that brings the most in all first: " .. #buys)

-------------------------------------------------------------------------------
--  The server, one item at a time
-------------------------------------------------------------------------------
check(#searches == 1 and searches[1].itemID == 2589, "the first line is asked of the server, one at a time")
ready = false
commodities[2589] = { { unitPrice = 400, quantity = 8, numOwnerItems = 0 }, { unitPrice = 500, quantity = 300, numOwnerItems = 100 },
    { unitPrice = 5000, quantity = 20, numOwnerItems = 0 } }
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
check(Live.Offers("2589") and Live.Offers("2589").commodity and #Live.Offers("2589").offers == 3, "the answer is kept")
check(#searches == 1, "while the game holds back, nothing more is asked")
ready = true
W.Fire("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
check(#searches == 2 and searches[2].itemID == 1000, "then the next line")
items[1000] = { { auctionID = 77, buyoutAmount = 20000, quantity = 1, containsOwnerItem = false },
    { auctionID = 78, buyoutAmount = 19000, quantity = 1, containsOwnerItem = true } }
W.Fire("ITEM_SEARCH_RESULTS_UPDATED", { itemID = 1000, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 })
check(#Live.Offers("1000").offers == 1 and Live.Offers("1000").offers[1].auction == 77, "an item sold whole: your own auction left out")
items[1000][3] = { auctionID = 79, buyoutAmount = W.Secret(), quantity = 1, containsOwnerItem = false }
W.Fire("ITEM_SEARCH_RESULTS_UPDATED", { itemID = 1000, itemLevel = 0, itemSuffix = 0, battlePetSpeciesID = 0 })
commodities[2589][4] = { unitPrice = 450, quantity = W.Secret(), numOwnerItems = 0 }
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
check(#Live.Offers("1000").offers == 1 and Live.Offers("1000").offers[1].auction == 77 and #Live.Offers("2589").offers == 3 and not ns.off,
    "an offer whose price or count the game hides (a secret value) is left out, never computed with")
items[1000][3], commodities[2589][4] = nil, nil
searches = {}
Live.Want({ "4242", "4243" })
check(#searches == 1 and searches[1].itemID == 4242, "(asked)")
W.Wait(6)
check(#searches == 2 and searches[2].itemID == 4243 and #Live.Offers("4242").offers == 0, "no answer in time: nothing to buy there, and the next is asked")
W.Fire("ITEM_SEARCH_RESULTS_UPDATED", { itemID = 4243, itemLevel = 60, itemSuffix = 0, battlePetSpeciesID = 0 })
check(Live.Offers("4243"), "an answer goes to what was asked, however the game counts its kinds")
searches = {}
local units, cost = Live.Under("2589", 900, 70)
check(units == 70 and cost == 8 * 400 + 62 * 500, "what the server says under the limit, up to the most: " .. units)
check(select(1, Live.Under("2589", 900, 1000)) == 208, "your own offers are not for you to buy")

-------------------------------------------------------------------------------
--  Buying, from a click only
-------------------------------------------------------------------------------
local function Rows(kind)
    local found = {}
    for _, frame in ipairs(W.frames) do
        if frame.kind == kind and frame.line then found[frame.line.key] = frame end
    end
    return found
end
local rows = Rows("buy")
local wand, cloth = rows["1000"], rows["2589"]
W.Wait(0.1)
check(wand and wand.action:GetText() == TEXT.buy and not wand.action._disabled, "the server told an offer under the limit: the button is ready")
W.items[1000] = { name = "Wand" }
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589) -- any answer draws the lines anew
local named = wand.name:GetText()
W.items[1000] = { name = W.Secret() }
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
check(named == "Wand" and wand.name:GetText() == "?" and not ns.off,
    "a name the game hides (a secret value) is drawn as ?, never computed with: " .. tostring(wand.name:GetText()))
W.items[1000] = nil
Click(wand.action)
check(#calls == 1 and calls[1][1] == "PlaceBid" and calls[1][2] == 77 and calls[1][3] == 20000, "one click buys a thing sold whole: the offer the server told, at its price")
W.Fire("AUCTION_HOUSE_PURCHASE_COMPLETED", 77)
check(Live.Offers("1000") == nil, "bought: asked again")
calls = {}

Click(cloth.action)
check(#calls == 1 and calls[1][1] == "StartCommoditiesPurchase" and calls[1][2] == 2589 and calls[1][3] == 70, "a thing sold by the unit: the first click asks what they cost")
check(Trade.Pending("2589") == nil, "no sum yet")
W.Fire("COMMODITY_PRICE_UPDATED", 480, 33600)
check(Trade.Pending("2589").total == 33600 and cloth.action:GetText() == TEXT.confirm, "the server\'s sum stands on the line, and the same button confirms it")
check(cloth.note:GetText() == TEXT.confirmLine:format(70, Coins(33600)), "what it will cost is on the line: " .. tostring(cloth.note:GetText()))
Click(cloth.action)
check(#calls == 2 and calls[2][1] == "ConfirmCommoditiesPurchase" and calls[2][3] == 70, "the second click buys them, nothing happens by itself")
W.Fire("COMMODITY_PURCHASE_SUCCEEDED")
check(Live.Offers("2589") == nil, "bought: asked again")
calls = {}

W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
Click(cloth.action)
local limit = cloth.line.limit
W.Fire("COMMODITY_PRICE_UPDATED", limit + 1, (limit + 1) * 70)
check(#calls == 2 and calls[2][1] == "CancelCommoditiesPurchase" and Trade.Pending("2589") == nil, "the sum came out over the limit: called off, nothing bought")
check(cloth.note:GetText() == TEXT.dearer, "and it says so")
calls = {}
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
money = 100
Click(cloth.action)
check(#calls == 0 and cloth.note:GetText() == TEXT.noMoney, "too little gold: not even asked")
money = 100000
W.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", 2589)
Click(cloth.action)
check(#calls == 1, "(asked)")
W.Fire("AUCTION_HOUSE_CLOSED")
check(#calls == 2 and calls[2][1] == "CancelCommoditiesPurchase", "the window closed while a purchase waits: it is called off")
calls = {}
Live.Want({})
local errored = pcall(C_AuctionHouse.PlaceBid, 1, 1)
check(errored == false, "(the stand-in refuses a call without a click)")
W.Fire("AUCTION_HOUSE_SHOW")
W.Wait(0.1)

-------------------------------------------------------------------------------
--  Posting, from a click only
-------------------------------------------------------------------------------
check(Deals.Sell({ key = "2589", id = 2589, item = 2589, count = 7, here = 7, bag = 0, slot = 3, there = {} }) == nil,
    "far under its usual price: better kept, though no time stands out")
Listed("2589", 1000)
Prices.Changed()
sell = Deals.Sell({ key = "2589", id = 2589, item = 2589, count = 7, here = 7, bag = 0, slot = 3, there = {} })
check(sell and sell.price == 999 and sell.total == sell.gain * 7, "at its usual price: what stacks goes one copper under the lowest offer, the sum for all of it")
Click({ _scripts = { OnClick = function() ns.Trade.Post(sell) end } })
check(calls[1][1] == "PostCommodity" and calls[1][3] == 2 and calls[1][4] == 7 and calls[1][5] == 999, "a post of all of it, at the price, for the duration in the game\'s setting: " .. tostring(calls[1][3]))
calls = {}
check(corner.text:GetText() == TEXT.onSale:format(Coins(30000 + 999 * 7)), "the gold on sale grows with it: " .. tostring(corner.text:GetText()))
C_AuctionHouse.status = Enum.ItemCommodityStatus.Item
Click({ _scripts = { OnClick = function() ns.Trade.Post(mine) end } })
check(calls[1][1] == "PostItem" and calls[1][4] == 7 and calls[1][5] == nil and calls[1][6] == 49900, "a piece sold whole, a buyout and no bid")
calls = {}
C_AuctionHouse.warns = true
local told
Trade.OnChange(function(_, word) told = word end)
Click({ _scripts = { OnClick = function() ns.Trade.Post(mine) end } })
check(told == TEXT.noPost, "the game wants a warning accepted: nothing counts as posted")
C_AuctionHouse.warns = nil
C_AuctionHouse.status = Enum.ItemCommodityStatus.Unknown
Click({ _scripts = { OnClick = function() ns.Trade.Post(mine) end } })
check(told == TEXT.noPost, "the game does not know the item yet: nothing is posted")

-------------------------------------------------------------------------------
--  The tab, and standing down
-------------------------------------------------------------------------------
AuctionHouseFrame:SetDisplayMode("the game\'s")
check(not page:IsShown() and tab.chosen == false and updated == 1 and AuctionHouseFrame.title == "the game's",
    "the game wants its page back (a tab, an item to post): ours goes, its tabs and title as they were")
Click(tab)
check(page:IsShown() and tab.chosen == true, "our tab brings it back")
AuctionHouseFrame:SetDisplayMode("the game\'s")
ns.options.dealsFirst = false
W.Fire("AUCTION_HOUSE_SHOW")
W.Wait(0.1)
check(not page:IsShown(), "with the option off the window opens on the game\'s own tab")
ns.options.dealsFirst = true
house.onSale, house.onSaleCount, house.kept = 1000, 1, now + 5
Prices.Changed()
W.Wait(6)
check(corner.text:GetText() == TEXT.onSale:format(Coins(1000)), "a new scan: its sum, what was posted here is in it: " .. tostring(corner.text:GetText()))

-- A fight with the auction window open (the game keeps it open): the tab opens and the game gets its page back as ever,
-- for none of our frames is protected, so there is nothing for the game to block.
W.Combat(true)
Click(tab)
local opened = page:IsShown()
AuctionHouseFrame:SetDisplayMode("the game\'s")
check(opened and not page:IsShown() and not ns.off and not (page:IsProtected() or tab:IsProtected() or corner:IsProtected()),
    "in a fight the tab opens and closes as ever: none of ours is a protected frame, nothing for the game to block")
W.Combat(false)

ns.StandDown("a test")
check(ns.off and not tab:IsShown() and not corner:IsShown() and not page:IsShown(), "standing down: no tab, no page, no corner")
W.Fire("AUCTION_HOUSE_SHOW")
W.Wait(0.1)
check(not page:IsShown(), "and it stays so")

io.write(("Economy: all %d checks passed.\n"):format(passed))
