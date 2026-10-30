local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Economy - Trade
--  A purchase and a post. The game takes each only from a click of the player
--  (HasRestrictions in its documentation), so each runs inside the button's
--  OnClick, never after a timer or an event, and one click does one thing: never a
--  loop.
--
--  An item bought whole takes one click: its cheapest offer the server told, at the
--  price it told. Things sold by the unit take two on the same button: the first
--  asks the server what they cost now, the second buys them for that, with the
--  sum on show. If the sum is over what the line allows, it is called off.
--
--      Trade.Buy(line)         a line of Deals.Buys(), from a click
--      Trade.Post(line)        a line of Deals.Sells(), from a click
--      Trade.Pending(key)      the purchase that waits for its second click: { units, total }, nil: none
--      Trade.OnChange(fn)      fn(key, word) when one went on; word: what to tell, or nil
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask = Core.Plain, Core.Ask
local PRICES = Core.Data.Series("Prices")
local Trade = {}
ns.Trade = Trade

local TEXT = ns.TEXT
local CHOSEN, USUAL = "auctionHouseDurationDropdown", 2 -- the game's setting of the duration last chosen; before any
local pending, bidding, paying -- the purchase of a commodity under way: { key, id, units, limit, total }; a bid: { auction, key };
                               -- the key of a purchase confirmed, until the server says it went through
local changed

local function Tell(key, word)
    if changed then changed(key, word) end
end

local function Off(word)
    local key = pending and pending.key
    if pending then
        pending = nil
        Ask(C_AuctionHouse.CancelCommoditiesPurchase)
    end
    Tell(key, word)
end

local function Second()
    local line = pending
    pending = nil
    if (Ask(rawget(_G, "GetMoney")) or 0) < line.total then
        pending = line
        return Off(TEXT.noMoney)
    end
    paying = line.key
    C_AuctionHouse.ConfirmCommoditiesPurchase(line.id, line.units)
    Tell(line.key)
end

function Trade.Buy(line)
    if pending and pending.key == line.key and pending.total then return Second() end
    if pending then Off() end
    local answer = ns.Live.Offers(line.key)
    if not answer then return end
    local money = Ask(rawget(_G, "GetMoney")) or 0
    if answer.commodity then
        local units, cost = ns.Live.Under(line.key, line.limit, line.most)
        if units == 0 then return Tell(line.key, TEXT.gone) end
        if cost > money then return Tell(line.key, TEXT.noMoney) end
        pending = { key = line.key, id = line.id, units = units, limit = line.limit }
        C_AuctionHouse.StartCommoditiesPurchase(line.id, units)
        return Tell(line.key)
    end
    local offer = ns.Live.Cheapest(line.key, line.limit)
    if not offer then return Tell(line.key, TEXT.gone) end
    if offer.buyout > money then return Tell(line.key, TEXT.noMoney) end
    bidding = { auction = offer.auction, key = line.key }
    C_AuctionHouse.PlaceBid(offer.auction, offer.buyout)
    Tell(line.key)
end

local function Priced(_, total)
    if not pending then return end
    if Plain(total) > pending.units * pending.limit then return Off(TEXT.dearer) end
    pending.total = Plain(total)
    Tell(pending.key)
end

function Trade.Pending(key)
    return pending and pending.key == key and pending.total and pending or nil
end

function Trade.Post(line)
    local auctions = C_AuctionHouse
    local location = ItemLocation:CreateFromBagAndSlot(line.bag, line.slot)
    if not (location:IsValid() and auctions.IsSellItemValid(location, false)) then return Tell(line.key, TEXT.noPost) end
    local status = auctions.GetItemCommodityStatus(location)
    local units = auctions.GetAvailablePostCount(location)
    local duration = tonumber(Ask(rawget(_G, "GetCVar"), CHOSEN)) or USUAL
    local price = PRICES:PostAt(PRICES:Low(line.item) or line.price, line.vendor, line.item)
    local stopped -- the game wants its warning accepted first: it told so itself, nothing is posted
    if status == Enum.ItemCommodityStatus.Commodity then
        stopped = auctions.PostCommodity(location, duration, units, price)
    elseif status == Enum.ItemCommodityStatus.Item then
        stopped = auctions.PostItem(location, duration, units, nil, price)
    else
        return Tell(line.key, TEXT.noPost)
    end
    if stopped then return Tell(line.key, TEXT.noPost) end
    ns.Tab.Posted(price * units, units)
    Tell(line.key, TEXT.posted)
end

function Trade.OnChange(fn)
    changed = fn
end

local function Purchased(auction)
    if not bidding or bidding.auction ~= Plain(auction) then return end
    local key = bidding.key
    bidding = nil
    ns.Live.Forget(key)
    Tell(key, TEXT.bought)
end

function Trade.Start()
    Core.On("COMMODITY_PRICE_UPDATED", ns.Guard(Priced))
    Core.On("COMMODITY_PRICE_UNAVAILABLE", ns.Guard(function() Off(TEXT.gone) end))
    Core.On("COMMODITY_PURCHASE_FAILED", ns.Guard(function() Off(TEXT.gone) end))
    Core.On("COMMODITY_PURCHASE_SUCCEEDED", ns.Guard(function()
        local key = paying
        paying = nil
        if key then
            ns.Live.Forget(key)
            Tell(key, TEXT.bought)
        end
    end))
    Core.On("AUCTION_HOUSE_PURCHASE_COMPLETED", ns.Guard(Purchased))
    Core.On("AUCTION_HOUSE_CLOSED", ns.Guard(function()
        if pending then Off() end
    end))
end
