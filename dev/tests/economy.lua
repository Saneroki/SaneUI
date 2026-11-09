-- Runs the Economy module against the stand-in client (wowstub.lua): what is worth buying and selling right now from
-- made-up prices, the server asked one item at a time, a purchase and a post from a click only, what is bought going by the
-- server's answer and never over the line's limit, the tab on the game's window and the gold on sale; the tab Banker on the
-- mail window (what goes, profession items too, the name kept, mails of twelve sent one after the other, a refusal, a slow
-- mail, what stops one, when it opens first, Send by itself in the profile Speedleveling); and standing down.
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

-------------------------------------------------------------------------------
--  The tab Banker on the mail window
-------------------------------------------------------------------------------
-- The bags: [bag][slot] = { id, count, bound, locked, refuse (the game will not put it into a mail) }
local bagged = { [0] = {}, [1] = {} }
local classes = { [2589] = 7, [2770] = 7, [2592] = 7, [17029] = 5, [6948] = 15, [2318] = 7 }
W.items[2589] = { name = "Linen Cloth" }
W.items[2770], W.items[2592], W.items[17029], W.items[2318] = { name = "Copper Ore" }, { name = "Wool Cloth" }, { name = "Holy Candle" }, { name = "Light Leather" }
C_Item.GetItemInfoInstant = function(id) return id, "", "", "", 0, classes[id], 0 end
C_Container = {
    GetContainerNumSlots = function(bag) return bagged[bag] and 20 or 0 end,
    GetContainerItemInfo = function(bag, slot)
        local held = bagged[bag] and bagged[bag][slot]
        if held then return { itemID = held.id, stackCount = held.count, isBound = held.bound or false, isLocked = held.locked or false } end
    end,
    PickupContainerItem = function(bag, slot)
        local held = bagged[bag][slot]
        if held and not held.locked then
            held.locked = true
            W.cursor = { kind = "item", bag = bag, slot = slot }
        end
    end,
}
ClearCursor = function()
    if W.cursor and W.cursor.bag then bagged[W.cursor.bag][W.cursor.slot].locked = false end
    W.cursor = nil
end
-- The mail: what is attached, every mail sent, and the server's answer when the test gives it
ATTACHMENTS_MAX_SEND = 12
local attached, mails = {}, {}
local function Attached()
    local count = 0
    for _ in pairs(attached) do count = count + 1 end
    return count
end
HasSendMailItem = function(slot) return attached[slot] ~= nil end
ClickSendMailItemButton = function(slot, clear)
    local held = attached[slot]
    if clear then
        if held then bagged[held.bag][held.slot].locked, attached[slot] = false, nil end
        return
    end
    local cursor = W.cursor
    if cursor and cursor.bag and not held and not bagged[cursor.bag][cursor.slot].refuse then
        attached[slot], W.cursor = { bag = cursor.bag, slot = cursor.slot }, nil
    end
end
GetSendMailPrice = function() return 30 * math.max(1, Attached()) end
SendMail = function(name, subject, body) mails[#mails + 1] = { name = name, subject = subject, body = body, count = Attached() } end
local function Delivered()
    for _, held in pairs(attached) do bagged[held.bag][held.slot] = nil end
    for slot in pairs(attached) do attached[slot] = nil end
    W.Fire("MAIL_SEND_SUCCESS")
end
-- The game's mail window, its two tabs, and the function its tabs and its show call
MailFrame = CreateFrame("Frame", "MailFrame", UIParent)
MailFrame:SetSize(338, 424)
MailFrame.numTabs = 2
function MailFrame:SetTitle(title) self.title = title end
MailFrameTab1 = CreateFrame("Button", "MailFrameTab1", MailFrame)
MailFrameTab2 = CreateFrame("Button", "MailFrameTab2", MailFrame)
MailFrameTab_OnClick = function(_, id)
    MailFrame.selectedTab = id
    MailFrame:SetTitle(id == 1 and "Inbox" or "Send Mail")
end
W.templates.InputBoxTemplate = noop
local function OpenMail()
    MailFrame:Show()
    MailFrameTab_OnClick(nil, 1) -- the game's own show picks the inbox
    W.Fire("MAIL_SHOW")
    W.Wait(0.1)
end
local function CloseMail()
    MailFrame:Hide()
    W.Fire("MAIL_CLOSED")
end

-- What is in the bags: two stacks of cloth, ore, a reagent, fourteen stacks of wool, and what never goes
bagged[0][1] = { id = 2589, count = 20 }
bagged[0][2] = { id = 2589, count = 7 }
bagged[0][3] = { id = 2770, count = 10 }
bagged[0][4] = { id = 17029, count = 5 }
bagged[0][5] = { id = 6948, count = 1 }               -- the hearthstone: no trade good
bagged[0][6] = { id = 2318, count = 3, bound = true } -- bound: it cannot be mailed
for slot = 1, 14 do bagged[1][slot] = { id = 2592, count = 1 } end
local Banker = ns.Banker
local lines, stacks = Banker.Goods()
check(#lines == 4 and lines[1].id == 2589 and lines[1].count == 27 and lines[1].stacks == 2 and #stacks == 18,
    "what goes: the trade goods and reagents, one line an item, not the hearthstone nor what is bound: " .. #lines .. ", " .. #stacks)

OpenMail()
local mailPage, mailTab, nameBox, sendButton, rows
for _, frame in ipairs(W.frames) do
    if frame._kind == "Button" and frame._parent and frame._parent._parent == MailFrame and frame:GetText() == TEXT.banker then mailTab = frame end
    if frame._parent == MailFrame and frame._kind == "Frame" and frame:IsShown() and #(frame._children or {}) > 0 and not mailPage then mailPage = frame end
end
for _, frame in ipairs(W.frames) do
    if frame._parent == mailPage and frame._kind == "EditBox" then nameBox = frame end
    if frame._parent == mailPage and frame._kind == "Button" then sendButton = frame end
    if rawget(frame, "rows") and frame._parent and frame._parent._parent == mailPage then rows = frame.rows end
end
check(mailTab and mailTab.chosen == true and mailPage and mailPage:IsShown() and MailFrame.title == TEXT.banker,
    "no banker named yet: the mail window opens on the tab Banker, and is called so")
check(MailFrameTab1.chosen == false and MailFrameTab2.chosen == false and rawget(MailFrame, "Tabs") == nil, "the game's tabs are not chosen, its list of tabs left alone")
check(nameBox and sendButton and not sendButton:IsEnabled(), "without a name there is nothing to send to")
check(rows and #rows == 4 and rows[1].name:GetText() == "Linen Cloth x27" and rows[1].note:GetText() == TEXT.bankerStacks:format(2),
    "the list: an item a line, with its count and its stacks: " .. tostring(rows and rows[1] and rows[1].name:GetText()))

nameBox:SetText("  Bank Alt ")
nameBox._scripts.OnTextChanged(nameBox, true)
W.Wait(0.2)
check(Banker.Name() == "Bank Alt" and ns.store.bankers["Stub|Alliance"] == "Bank Alt", "the name typed is the banker, remembered for this realm and faction")
check(sendButton:IsEnabled() and sendButton:GetText() == TEXT.bankerSend, "now Send is ready")
local summary = TEXT.bankerCount:format("18 stacks", "2 mails")
local said = {}
for _, frame in ipairs(W.frames) do
    if frame._parent == mailPage and frame._kind == "FontString" then said[#said + 1] = frame end
end
local function Says(text)
    for _, words in ipairs(said) do
        if words:GetText() == text then return true end
    end
    return false
end
check(Says(summary) and Says(TEXT.bankerKept:format("Alliance", "Stub Realm")), "it says how much goes in how many mails, and for whom the name is kept")

local candle = rows[3]
check(candle.line.id == 17029 and candle.tick:GetChecked() == true, "(the reagent is ticked)")
candle.tick:SetChecked(false)
candle.tick._scripts.OnClick(candle.tick)
check(Banker.Kept(17029) and candle.note:GetText() == TEXT.bankerStays and #select(2, Banker.Goods()) == 17, "unticked, it stays with you, and is remembered")

-- Send: the first mail on the click, the next when the game says the first went
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 1 and mails[1].name == "Bank Alt" and mails[1].count == 12 and mails[1].subject == TEXT.bankerOf:format(TEXT.bankerSubject, 1, 2),
    "the click sends the first mail: twelve stacks to the banker, 1 of 2: " .. tostring(mails[1] and mails[1].subject))
check(not sendButton:IsEnabled() and sendButton:GetText() == TEXT.bankerSending, "and waits for the game")
Delivered()
W.Wait(0.6)
check(#mails == 2 and mails[2].count == 5 and mails[2].subject == TEXT.bankerOf:format(TEXT.bankerSubject, 2, 2), "it went: the rest goes by itself in the second mail")
Delivered()
W.Wait(0.6)
check(#mails == 2 and Says(TEXT.bankerSent:format("Bank Alt", "2 mails")) and not sendButton:IsEnabled(), "all gone: it says so, and nothing is left to send")
check(bagged[0][4] and not bagged[0][4].locked and bagged[0][5] and bagged[0][6], "what stays is still in the bags: the reagent unticked, the hearthstone, what is bound")

-- The game refuses a mail: its reason on the line, the items back in the bags
bagged[0][7] = { id = 2770, count = 4 }
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0.2)
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 3 and mails[3].count == 1 and mails[3].subject == TEXT.bankerSubject, "one mail of one stack: no count in its subject")
W.Fire("UI_ERROR_MESSAGE", 50, "No player named that")
W.Fire("MAIL_FAILED")
check(Attached() == 0 and not bagged[0][7].locked and Says(TEXT.bankerRefused:format("No player named that")) and sendButton:IsEnabled(),
    "refused: the stack is back in its bag, the game's reason on the line, Send ready again")

-- A mail that neither goes nor is refused: the button is the player's again, and a click sends that mail again
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 4, "(sent)")
W.Wait(11)
check(sendButton:IsEnabled() and sendButton:GetText() == TEXT.bankerAgain and Says(TEXT.bankerSlow), "no answer in time: Send again, and why")
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 5 and mails[5].count == 1 and Attached() == 1, "a click sends the same mail once more")
Delivered()
W.Wait(0.6)
check(Says(TEXT.bankerSent:format("Bank Alt", "1 mail")), "it went: one mail")

-- What stops a mail before it is sent
bagged[0][8] = { id = 2770, count = 2 }
bagged[0][9] = { id = 2592, count = 1, refuse = true }
attached[1] = { bag = 0, slot = 3 }
bagged[0][3] = { id = 2770, count = 1, locked = true }
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0.2)
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 5 and Says(TEXT.bankerAttached) and attached[1].slot == 3, "something of the player's on the Send Mail tab: nothing is sent, nothing of theirs moved")
attached[1], bagged[0][3] = nil, nil
W.cursor = { kind = "spell" }
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 5 and Says(TEXT.bankerCursor), "something on the cursor: nothing is sent")
W.cursor = nil
money = 10
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 5 and Attached() == 0 and not bagged[0][8].locked and Says(TEXT.bankerPostage:format(Core.Coins(30) or "")),
    "too little gold for the postage: nothing sent, the stack back in its bag, the postage named")
money = 100000
sendButton._scripts.OnClick(sendButton, "LeftButton")
check(#mails == 6 and mails[6].count == 1 and not bagged[0][9].locked, "a stack the game will not put into a mail is left in its bag")
Delivered()
W.Wait(0.6)
check(#mails == 6 and Says(TEXT.bankerSent:format("Bank Alt", "1 mail")), "and not tried again: the run ends as sent")
bagged[0][9] = nil

-- The game wants its page back
MailFrameTab_OnClick(MailFrameTab2, 2)
check(not mailPage:IsShown() and mailTab.chosen == false and MailFrame.title == "Send Mail", "the game's tab: ours goes, the game's page and title as they were")
mailTab._scripts.OnClick(mailTab)
check(mailPage:IsShown() and mailTab.chosen == true and MailFrame.title == TEXT.banker, "our tab brings it back")
CloseMail()

-- When it does not open first
OpenMail()
check(not mailPage:IsShown(), "a banker named and nothing to send: the inbox, as the game opens it")
CloseMail()
bagged[0][10] = { id = 2770, count = 3 }
Banker.SetName(Core.FullName("player"))
OpenMail()
check(not mailPage:IsShown(), "on the banker itself: the inbox")
mailTab._scripts.OnClick(mailTab)
check(Says(TEXT.bankerMe) and not sendButton:IsEnabled(), "its tab says it is the banker, and sends nothing")
CloseMail()
Banker.SetName("Bank Alt")
ns.options.bankerFirst = false
OpenMail()
check(not mailPage:IsShown(), "with the option off the window opens on the inbox")
ns.options.bankerFirst = true
OpenMail()
check(mailPage:IsShown(), "on again, something to send: on Banker")
CloseMail()

-- Profession items go too: the bags' category Professions, the recipes and (Retail's) the class Profession
classes[2553], classes[190000] = 9, 19
W.items[2553], W.items[190000] = { name = "Recipe: Elixir of Minor Agility" }, { name = "A profession's tool" }
bagged[0][11] = { id = 2553, count = 1 }
bagged[0][12] = { id = 190000, count = 1 }
local goes = {}
lines, stacks = Banker.Goods()
for _, stack in ipairs(stacks) do goes[stack.id] = true end
check(#stacks == 3 and goes[2770] and goes[2553] and goes[190000], "profession items go too: a recipe, a profession's tool, beside the ore")

-- Send by itself: on in the profile Speedleveling alone, and what goes is sent as the mailbox opens
check(ns.options.bankerAuto == false, "Send by itself is off at first")
Core.Profiles.SetLeveling(true)
check(Core.Profiles.Leveling() and ns.options.bankerAuto == true, "Speed Leveling on: the profile Speedleveling sends by itself")
local before = #mails
ns.options.bankerFirst = false
OpenMail()
local last = mails[#mails]
check(#mails == before + 1 and last.name == "Bank Alt" and last.count == 3 and last.subject == TEXT.bankerSubject and mailPage:IsShown(),
    "the mailbox opens: all of it goes at once, on Banker though Open on Banker is off, without a click")
Delivered()
W.Wait(0.6)
check(#mails == before + 1 and Says(TEXT.bankerSent:format("Bank Alt", "1 mail")) and not bagged[0][11], "went: it says so, the recipe gone")
CloseMail()
local shift = IsShiftKeyDown
IsShiftKeyDown = function() return true end
bagged[0][13] = { id = 2770, count = 1 }
OpenMail()
check(#mails == before + 1 and not mailPage:IsShown(), "Shift held as it opens: nothing sent, the inbox as the option has it")
IsShiftKeyDown = shift
CloseMail()
ns.options.bankerFirst = true
Banker.SetName(nil)
OpenMail()
check(#mails == before + 1 and mailPage:IsShown(), "no banker named: nothing to send to, the tab asks for the name")
CloseMail()
Banker.SetName("Bank Alt")
Core.Profiles.SetLeveling(false)
check(not Core.Profiles.Leveling() and ns.options.bankerAuto == false, "Speed Leveling off: back to the profile before, Send by itself off")
OpenMail()
check(#mails == before + 1 and mailPage:IsShown() and sendButton:IsEnabled(), "on Banker, and nothing goes before the click")
CloseMail()

ns.StandDown("a test")
check(ns.off and not tab:IsShown() and not corner:IsShown() and not page:IsShown(), "standing down: no tab, no page, no corner")
check(not mailTab:IsShown() and not mailPage:IsShown(), "and no tab Banker on the mail window")
OpenMail()
check(not mailPage:IsShown(), "which stays so")
W.Fire("AUCTION_HOUSE_SHOW")
W.Wait(0.1)
check(not page:IsShown(), "and it stays so")

io.write(("Economy: all %d checks passed.\n"):format(passed))
