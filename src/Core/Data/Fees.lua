local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Fees
--  What the auction house takes, and what that leaves: the one place these are reckoned, for every view (Doc/guides/data.md,
--  *Fees*). Added to the series Prices. The numbers are the game's own (the client's table AuctionHouse, its duration words):
--
--                      cut of a sale    deposit, of the vendor price of what is put up, for 2, 8, 24 hours
--      faction house       5%                5%, 20%, 60%
--      neutral house      15%               25%, 100%, 300%
--
--  Retail's three durations are 12, 24 and 48 hours (Retail's own rule: three, six and twelve times the rate).
--  An auction costs at least 1s, whatever the deposit says, and a stack of any size pays that once. A sale gives the deposit back
--  and an auction that runs out keeps it, so it counts in full, as one failed post for each sale: what is advised stays worth it.
--  Whether it is the shown deposit or the whole 1s that comes back is not settled.
--
--  A price moves in copper only for what stacks (sold by the unit); a thing that does not stack is priced in whole silver.
--
--      Prices:Cut()                  the share of a sale the house read now keeps
--      Prices:Sale(price)            what a sale at that price brings, after the cut
--      Prices:Deposit(vendor, count) what an auction of count costs to put up, at the duration last chosen in the game's window
--      Prices:Post(vendor, item)     what putting one up costs: its auction's cost shared by as many as others put in one
--      Prices:Step(item)             the smallest step of its price, in copper
--      Prices:PostAt(price, vendor, item)  the price to post at: one step under that price, on a step, never so low that a
--                                    sale brings less than a vendor pays
--      Prices:Limit(outlook, post)   the most worth paying to sell it on (Prices:Outlook, Prices:Post): what a sale at its best
--                                    time brings, less a margin. Nil for an item seen not selling, or known too shortly
--      Prices:Later(outlook, value, post)  what a sale at the price to expect brings where that is worth the wait over value,
--                                    what the best way brings now; nil where it is not
--      Prices:Route(item, vendor)    what the house of the other kind says of it, each number by that house's own cut and deposit, for
--                                    weighing a trip there: { side, low, at, usual, high, daily, sale }, one table used again: read it at
--                                    once. nil: no such house, or it has not seen the item. side: "neutral" or "faction"; low: its lowest
--                                    price, when last seen (at); usual, high, daily, sale: nil while there is nothing to go by
--                                    (known too shortly, seen not selling, or last seen too long ago); sale: what a sale there brings
--      Prices:RouteUsual(key)        what the item usually costs in that house, a look at its line alone
--      Prices:Trip(route)            the most worth paying to sell it on there: nil where that house has nothing to go by
-------------------------------------------------------------------------------
local Plain, Ask = Core.Plain, Core.Ask
local Prices = Core.Data.Series("Prices")

local CUT, RATE = { faction = 0.05, neutral = 0.15 }, { faction = 0.05, neutral = 0.25 }
local LENGTHS = { forever = { 1, 4, 12 }, retail = { 3, 6, 12 } } -- how many times the rate each of the three durations costs
local CHOSEN, USUAL = "auctionHouseDurationDropdown", 2 -- the game's setting of the duration last chosen; before any
local POST_LEAST = 100 -- 1s: the least an auction costs to put up, however cheap the item
local MARGIN = 1.10    -- how much more a sale later must bring than the item costs: prices miss, and not all of it sells
local LATER = 1.05     -- how much more a sale later must bring than a sale now to be worth the wait
local TRUSTED = 3      -- days of an item's prices before anything is said of where they go
Prices.TRUSTED = TRUSTED
Prices.BETTER = 1.05   -- how much more the auction house must bring than a vendor to be advised
Prices.AWAY = 1.10     -- how much more a sale in the other house must bring than the best way here to be worth the trip
local TRIP = 1.25      -- how much more a sale in the other house must bring than the item costs: the way, and its prices are older
Prices.TRIP = TRIP
local STALE = 3 * 86400 -- seconds after which what the other house listed is no ground for a trip
local NEUTRAL = "neutral"

local function Side()
    local key = Prices.Key(Prices.Read())
    return key and key:find("/neutral$") and "neutral" or "faction"
end

function Prices:Cut()
    return CUT[Side()]
end

function Prices:Sale(price)
    return math.floor(price - price * self:Cut())
end

function Prices:Deposit(vendor, count)
    local chosen = tonumber(Ask(rawget(_G, "GetCVar"), CHOSEN))
    local lengths = Core.ForGame(LENGTHS) or LENGTHS.forever
    local times = lengths[chosen] or lengths[USUAL]
    return math.max(POST_LEAST, math.floor((vendor or 0) * (count or 1) * RATE[Side()] * times))
end

function Prices:Post(vendor, item)
    local _, _, units, auctions = self:Last(item)
    local lot = units and auctions and auctions > 0 and math.max(1, math.floor(units / auctions)) or 1
    return self:Deposit(vendor, lot) / lot
end

-- Unknown yet: whole silver, a step that is good for everything.
function Prices:Step(item)
    local id = type(item) == "string" and tonumber(item:match("item:(%d+)") or item:match("^(%d+)")) or item
    local auctions = rawget(_G, "C_AuctionHouse")
    if type(id) ~= "number" or (auctions and auctions.SupportsCopperValues and Ask(auctions.SupportsCopperValues) == false) then return 100 end
    local info = C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    local stack = info and Plain((select(8, info(id))))
    return type(stack) == "number" and stack > 1 and 1 or 100
end

function Prices:PostAt(price, vendor, item)
    local step = self:Step(item)
    local least = (vendor or 0) > 0 and vendor / (1 - self:Cut()) or 0
    return math.max(step, math.ceil((price - step) / step) * step, math.ceil(least / step) * step)
end

function Prices:Later(outlook, value, post)
    if not outlook or outlook.days < TRUSTED then return nil end
    local later = self:Sale(outlook.high) - post
    return later > value * LATER and later or nil
end

local route = {}

-- Inside the other house (Prices.Within): all that is reckoned here is by its fees.
local function There(self, item, vendor)
    local low, _, _, _, _, at = self:Last(item)
    if not low then return nil end
    wipe(route)
    route.side, route.low, route.at = Side() == NEUTRAL and NEUTRAL or "faction", low, at
    local outlook = self:Outlook(item)
    local now = Ask(rawget(_G, "GetServerTime")) or 0
    if outlook and outlook.days >= TRUSTED and outlook.daily ~= 0 and now - at <= STALE then
        route.usual, route.high, route.daily = outlook.usual, outlook.high, outlook.daily
        route.sale = self:Sale(outlook.high - 1) - self:Post(vendor, item)
    end
    return route
end

function Prices:Route(item, vendor)
    local other = Prices.Other()
    if not other then return nil end
    return (Prices.Within(other, There, self, item, vendor))
end

function Prices:RouteUsual(key)
    local other = Prices.Other()
    if not other then return nil end
    return (Prices.Within(other, self.Usual, self, key))
end

function Prices:Trip(there)
    return there and there.sale and math.floor(there.sale / TRIP) or nil
end

function Prices:Limit(outlook, post)
    if not outlook or outlook.days < TRUSTED or outlook.daily == 0 then return nil end
    return math.floor((self:Sale(outlook.high - 1) - post) / MARGIN)
end
