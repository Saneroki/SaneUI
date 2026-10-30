local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy - Live
--  What the server says of the items in sight. A scan has no auction IDs and can
--  be 15 minutes old, so a purchase always goes by this answer. The lines in
--  sight are asked one at a time, as the game allows, so that a click can buy at
--  once.
--
--      Live.Want(keys)         the items wanted, the first first; the rest forgotten
--      Live.Offers(key)        { commodity, offers = { ... } }, cheapest first; nil: not told yet, or old. An item the
--                              server gave no answer for in time has no offers, so it cannot hold up the ones after it
--                              a commodity's offer: { price, units }, units of others alone
--                              an item's offer: { auction, buyout, units, price }, your own left out
--      Live.Under(key, limit, most)  units and money, at most most units, of a commodity at limit or less
--      Live.Cheapest(key, limit)     an item's cheapest offer at limit or less a unit
--      Live.Forget(key)        it changed: asked again
--      Live.OnChange(fn)       fn(key) when an answer came
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local PRICES = Core.Data.Series("Prices")
local Live = {}
ns.Live = Live

local FRESH = 90        -- seconds an answer counts
local ANSWER = 5        -- seconds a search may take before the next is asked
local ORDER = 1         -- the game's sort by price (Enum.AuctionHouseSortOrder.Price), for the file's first read
local NONE = {}

local wanted, known = {}, {}  -- keys; [key] = { at, commodity, offers }
local waiting, waitingAt      -- the key asked about, and when
local changed
local Soon

local function Clock()
    return Ask(rawget(_G, "GetTime")) or 0
end

local function ItemKey(key)
    local auctions = C_AuctionHouse
    local item, level, suffix, species = key:match("^(%d+):(%-?%d+):(%-?%d+):(%d+)$")
    if item then return auctions.MakeItemKey(tonumber(item), tonumber(level), tonumber(suffix), tonumber(species)) end
    return auctions.MakeItemKey(tonumber(key))
end

local function Sorts()
    local order = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or ORDER
    return { { sortOrder = order, reverseSort = false } }
end

-- Asks about the first item wanted that has no fresh answer, when the game lets it.
local function Next()
    local auctions = rawget(_G, "C_AuctionHouse")
    if not auctions then return end
    local now = Clock()
    if waiting then
        if now - waitingAt < ANSWER then return end
        known[waiting] = { at = now, offers = NONE } -- no answer that fits: nothing to buy now, and the next may go on
        waiting = nil
    end
    if Ask(auctions.IsThrottledMessageSystemReady) ~= true then return end
    for _, key in ipairs(wanted) do
        local answer = known[key]
        if not answer or now - answer.at > FRESH then
            waiting, waitingAt = key, now
            Ask(auctions.SendSearchQuery, ItemKey(key), Sorts(), true)
            Soon()
            return
        end
    end
end
Soon = Core.Later(Next, ANSWER)

local function Told(key, commodity, offers)
    known[key] = { at = Clock(), commodity = commodity, offers = offers }
    if waiting == key then waiting = nil end
    if changed then changed(key) end
    Next()
end

local function Commodity(item)
    item = Plain(item)
    local auctions = C_AuctionHouse
    local offers = {}
    for index = 1, Ask(auctions.GetNumCommoditySearchResults, item) or 0 do
        local offer = Plain(Ask(auctions.GetCommoditySearchResultInfo, item, index))
        local price = type(offer) == "table" and Plain(offer.unitPrice)
        if type(price) == "number" then
            local units = (Plain(offer.quantity) or 0) - (Plain(offer.numOwnerItems) or 0)
            if units > 0 then offers[#offers + 1] = { price = price, units = units } end
        end
    end
    Told(tostring(item), true, offers)
end

local function Item(itemKey)
    local key = PRICES.KeyOf(itemKey)
    if not key then return end
    -- The answer to what was asked is for that line, however the game counts its kinds.
    if waiting and tonumber(waiting:match("^%d+")) == tonumber(key:match("^%d+")) then key = waiting end
    local auctions = C_AuctionHouse
    local offers = {}
    for index = 1, Ask(auctions.GetNumItemSearchResults, itemKey) or 0 do
        local offer = Plain(Ask(auctions.GetItemSearchResultInfo, itemKey, index))
        local buyout = type(offer) == "table" and Plain(offer.buyoutAmount)
        local units = type(offer) == "table" and Plain(offer.quantity)
        if type(buyout) == "number" and buyout > 0 and type(units) == "number" and units > 0 and Plain(offer.containsOwnerItem) ~= true then
            offers[#offers + 1] = { auction = Plain(offer.auctionID), buyout = buyout, units = units, price = math.ceil(buyout / units) }
        end
    end
    table.sort(offers, function(one, other) return one.price < other.price end)
    Told(key, false, offers)
end

function Live.Want(keys)
    wanted = keys
    Next()
end

function Live.Offers(key)
    local answer = known[key]
    if answer and Clock() - answer.at <= FRESH then return answer end
    return nil
end

function Live.Under(key, limit, most)
    local answer = known[key]
    local units, money = 0, 0
    for _, offer in ipairs(answer and answer.offers or NONE) do
        if offer.price > limit or units >= most then break end
        local take = math.min(offer.units, most - units)
        units, money = units + take, money + take * offer.price
    end
    return units, money
end

function Live.Cheapest(key, limit)
    local answer = known[key]
    local offer = answer and answer.offers[1]
    return offer and offer.price <= limit and offer or nil
end

function Live.Forget(key)
    known[key] = nil
    Next()
end

function Live.OnChange(fn)
    changed = fn
end

function Live.Start()
    Core.On("COMMODITY_SEARCH_RESULTS_UPDATED", ns.Guard(Commodity))
    Core.On("ITEM_SEARCH_RESULTS_UPDATED", ns.Guard(Item))
    Core.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", ns.Guard(Next))
    Core.On("AUCTION_HOUSE_CLOSED", ns.Guard(function()
        wanted, known, waiting = {}, {}, nil
    end))
end
