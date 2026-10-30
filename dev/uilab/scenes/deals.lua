-- Deals: the game's auction house window, open on the tab Deals: what to buy, what to sell, the gold on sale in its corner
-- The game's window from its own files, Core, its auction data and Economy from their TOCs. The prices are made up, three weeks
-- of scans behind each; the game's search answers come by themselves a moment later. In the console: LabEmpty() shows the page
-- before any scan is in, LabScan() brings the prices back. The module is LabEconomy.
Lab.Blizzard("Blizzard_FrameXMLUtil")
Lab.Blizzard("Blizzard_AuctionHouseUI")
Lab.TOC("src/Core/SaneUI.toc")
Lab.TOC("src/AuctionData/SaneUI_AuctionData.toc")
LabEconomy = Lab.TOC("src/Economy/SaneUI_Economy.toc")

g_auctionHouseSortsBySearchContext = {} -- the game's saved variable
C_WowTokenPublic = setmetatable({}, { __index = function() return function() end end })
WowToken_IsWowTokenAuctionDialogShown = function() return false end

-- The game's own words for its coins, which the lab does not have
GOLD_AMOUNT_TEXTURE = "%d|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t"
SILVER_AMOUNT_TEXTURE = "%d|TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:2:0|t"
COPPER_AMOUNT_TEXTURE = "%d|TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:2:0|t"

local DAY = 86400
-- id, name, what it usually costs, what it costs now, a dear stretch, how many sell a day, a stack's size
local THINGS = {
    { 2589, 1000, 480, true, 34, 20 },
    { 2592, 2600, 1400, true, 21, 20 },
    { 2318, 800, 520, false, 14, 20 },
    { 2319, 3000, 1900, true, 9, 20 },
    { 4306, 5200, 2800, false, 40, 20 },
    { 4338, 3400, 2100, true, 16, 20 },
    { 2770, 900, 610, false, 55, 20 },
    { 2771, 2400, 1500, true, 28, 20 },
    { 5212, 90000, 45000, true, 2, 1 },
    { 2840, 1300, 1290, false, 24, 20 },
    { 3576, 4100, 4100, false, 12, 20 },
}
local BAGS = { [0] = { { 2840, 18 }, { 3576, 6 } } }
local info = C_Item.GetItemInfo
local NAMES = { [2589] = "Linen Cloth", [2592] = "Wool Cloth", [2318] = "Light Leather", [2319] = "Medium Leather", [4306] = "Silk Cloth",
    [4338] = "Mageweave Cloth", [2770] = "Copper Ore", [2771] = "Tin Ore", [5212] = "Blazing Wand", [2840] = "Copper Bar", [3576] = "Tin Bar" }
C_Item.GetItemInfo = function(id)
    for _, thing in ipairs(THINGS) do
        if thing[1] == id then return NAMES[id], nil, 2, nil, nil, nil, nil, thing[6], nil, nil, 13, nil, nil, 0 end
    end
    return info and info(id)
end
C_Item.GetItemNameByID = function(id) return NAMES[id] end
C_Item.GetItemIconByID = function() return 134400 end
C_Item.GetItemQualityByID = function() return 1 end

C_AuctionHouse.IsThrottledMessageSystemReady = function() return true end
C_AuctionHouse.ReplicateItems = function() end
C_AuctionHouse.GetNumReplicateItems = function() return 0 end
C_AuctionHouse.MakeItemKey = function(item, level, suffix, species)
    return { itemID = item, itemLevel = level or 0, itemSuffix = suffix or 0, battlePetSpeciesID = species or 0 }
end
local function Thing(id)
    for _, thing in ipairs(THINGS) do
        if thing[1] == id then return thing end
    end
end
C_AuctionHouse.SendSearchQuery = function(key)
    C_Timer.After(0.4, function()
        if Thing(key.itemID)[6] > 1 then Lab.Fire("COMMODITY_SEARCH_RESULTS_UPDATED", key.itemID)
        else Lab.Fire("ITEM_SEARCH_RESULTS_UPDATED", key) end
    end)
end
C_AuctionHouse.GetNumCommoditySearchResults = function() return 2 end
C_AuctionHouse.GetCommoditySearchResultInfo = function(item, index)
    return { itemID = item, unitPrice = Thing(item)[3] + (index - 1) * 5, quantity = 20, numOwnerItems = 0, auctionID = index, owners = {} }
end
C_AuctionHouse.GetCommoditySearchResultsQuantity = function() return 40 end
C_AuctionHouse.GetNumItemSearchResults = function() return 1 end
C_AuctionHouse.GetItemSearchResultInfo = function(key)
    return { itemKey = key, auctionID = 1, buyoutAmount = Thing(key.itemID)[3], quantity = 1, containsOwnerItem = false }
end
C_AuctionHouse.GetItemSearchResultsQuantity = function() return 1 end
C_Container = C_Container or {}
C_Container.GetContainerNumSlots = function(bag) return BAGS[bag] and #BAGS[bag] or 0 end
C_Container.GetContainerItemInfo = function(bag, slot)
    local thing = BAGS[bag] and BAGS[bag][slot]
    return thing and { itemID = thing[1], stackCount = thing[2], isBound = false, hyperlink = "item:" .. thing[1] } or nil
end

local function Fill()
    local Core = SaneUI.Core
    local Prices, Rhythm = Core.Data.Series("Prices"), Core.Data.Rhythm
    local house = Prices.House("player")
    local now = GetServerTime()
    for _, thing in ipairs(THINGS) do
        local line
        for step = 21 * 8, 1, -1 do
            local at = now - step * 3 * 3600
            local hour = date("*t", at).hour
            line = Rhythm.Seen(line, at, thing[2] * (thing[4] and hour >= 18 and hour < 21 and 1.4 or 1))
        end
        local key = tostring(thing[1])
        house.rhythm[key] = Rhythm.Sold(line, now, thing[5] * 7, thing[5] * 7 * thing[2])
        Prices.Take(house, key, now, thing[3], thing[2], 40, 8, 3)
    end
    house.watched, house.watchedAt, house.kept = 7 * DAY, now, now
    house.onSale, house.onSaleCount = 1284500, 37
    Prices.Changed()
end

function LabScan()
    Fill()
    LabEconomy.Deals.Refresh()
end

function LabEmpty()
    local Prices = SaneUI.Core.Data.Series("Prices")
    local house = Prices.House("player")
    house.rhythm, house.index, house.onSale, house.kept = {}, nil, nil, nil
    for _, thing in ipairs(THINGS) do Prices.See(tostring(thing[1])) end
    LabEconomy.Deals.Refresh()
end

Lab.OnLogin(function()
    AuctionHouseFrame:SetScript("OnShow", nil) -- its searches need more of the server than the lab has
    AuctionHouseFrame:Show()
    AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy) -- as its OnShow does: the game's own page, under ours
    Fill()
    C_Timer.After(0.2, function() Lab.Fire("AUCTION_HOUSE_SHOW") end) -- the modules' logins run first
end)
