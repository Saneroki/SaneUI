local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Auction
--  What a thing fetches at the auction house: the lowest buyout price the
--  game listed for it when you last looked, kept from session to session in
--  the module's saved store (prices[item] = copper; seen[item] = the day).
--
--  Nothing is asked of the server: the prices are noted whenever the game
--  lists auctions to you anyway (browsing the auction house:
--  AUCTION_HOUSE_BROWSE_RESULTS_UPDATED and _ADDED). A thing you have not
--  seen there has no price. An item's panel shows it as its Auction row.
--  A price not seen again for KEEP days is no longer what the thing fetches:
--  it is forgotten at the login, so the store does not only grow.
-------------------------------------------------------------------------------
local Plain = SaneUI.Core.Plain
local Auction = {}
ns.Auction = Auction

local DAY = 86400
local KEEP = 30 -- days
local prices, seen -- the store's tables

local function Today()
    return math.floor(time() / DAY)
end

-- The items priced in the list on show: one item can have several rows (each of its kinds, an item
-- level, a suffix), and the lowest of them is its price. anew: a new list (a new search).
local listed = {}
local function Note(results, anew)
    if anew then wipe(listed) end
    if type(results) ~= "table" then return end
    local today = Today()
    for _, result in ipairs(results) do
        result = Plain(result)
        local key = type(result) == "table" and Plain(result.itemKey)
        local item = type(key) == "table" and Plain(key.itemID)
        local price = type(result) == "table" and Plain(result.minPrice)
        if type(item) == "number" and type(price) == "number" and price > 0
            and not (listed[item] and prices[item] <= price) then
            prices[item], seen[item], listed[item] = price, today, true
        end
    end
end

-- Forgets the prices not seen for KEEP days, and any without a day (a hand-edited store).
local function Forget()
    local today = Today()
    for item, day in pairs(seen) do
        if type(day) ~= "number" or today - day > KEEP then seen[item] = nil end
    end
    for item in pairs(prices) do
        if not seen[item] then prices[item] = nil end
    end
end

-- Listens for the auction house's lists. store: the module's saved store.
function Auction.Start(store)
    if type(store.prices) ~= "table" then store.prices = {} end
    if type(store.seen) ~= "table" then store.seen = {} end
    prices, seen = store.prices, store.seen
    Forget()
    local house = rawget(_G, "C_AuctionHouse")
    if not (house and house.GetBrowseResults) then return end
    SaneUI.Core.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function() Note(house.GetBrowseResults(), true) end)
    SaneUI.Core.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function(added) Note(added, false) end)
end

-- The lowest buyout last seen for an item, in copper; nil when never seen.
function Auction.Price(item)
    return prices and item and prices[item] or nil
end
