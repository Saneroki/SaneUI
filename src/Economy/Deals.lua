local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Economy - Deals
--  What is worth buying and what worth selling right now, as two plain lists.
--  No frames: Tab.lua draws them, the tests feed them made-up prices.
--
--  To buy: an item of the last scan that costs clearly under its usual price,
--  under the most worth paying (Core's Prices:Limit: what a sale at its best time
--  brings after the cut and the post, less a margin), and seen selling. How many
--  is capped by what sells in a week: what would stay unsold brings nothing.
--
--      { key, id, low, limit, gain, most, high, highAt, allDay, at, daily, total, side }
--
--  or that costs much less here than it fetches in the house of the other kind, your
--  side's or a neutral one, each reckoned by that house's own cut and deposit (Core's
--  Prices:Route): the better of the two ways. side then names that house.
--
--  To sell: what any of your characters holds, that a sale now brings more for
--  than a vendor pays, after the cut and the post, where the price is not soon to
--  be clearly better and the item was not seen unsold. Only what is in the bags
--  of the character you play can be posted; the rest says who has it.
--
--      { key, id, item, price, gain, total, count, here, bag, slot, vendor, there, side }
--
--  Where the other house pays clearly more, the line says to take it there: side
--  names that house, price is its price, and nothing is posted from here.
--
--      Deals.Buys(), Deals.Sells()   the lists, best first
--      Deals.Refresh()               makes them anew, in steps, while the page is up
--      Deals.Ready(fn)               fn() once they are
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Data, Steps, Plain, Ask = Core.Data, Core.Steps, Core.Plain, Core.Ask
local PRICES, ITEMS = Data.Series("Prices"), Data.Set("Items")
local Deals = {}
ns.Deals = Deals

local JOB = "Economy: deals"
local CHEAP = 0.85      -- the share of its usual price under which an item is worth a closer look
local WEEK = 7          -- days of sales worth buying ahead
local KEPT = 40         -- lines kept in each list
local BOP, QUEST = 1, 4 -- the game's bind types that can never go to an auction house
local ACCOUNT = "account" -- the account's own bank, in the characters' data

local buys, sells = {}, {}
local ready

-- What a vendor pays for one, and how it binds; 0 and nil while neither the data nor the game has the item.
local function Facts(id)
    local record = ITEMS:Get(id)
    if record then return record.sell or 0, record.bind end
    local info = C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if not info then return 0, nil end
    local each = Plain((select(11, info(id))))
    if type(each) ~= "number" and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return type(each) == "number" and each or 0, Plain((select(14, info(id))))
end
Deals.Facts = Facts

local function Better(one, other)
    if one.total ~= other.total then return one.total > other.total end
    return one.key < other.key
end

local function Keep(list)
    table.sort(list, Better)
    for index = #list, KEPT + 1, -1 do list[index] = nil end
    return list
end

local function Most(key, limit, daily)
    return math.max(1, math.min(PRICES:Under(key, limit) or 1, math.ceil(daily * WEEK)))
end

-- To buy here and sell here.
local function Here(key, id, low, vendor)
    local outlook = PRICES:Outlook(key)
    if not outlook or not outlook.daily or outlook.daily <= 0 then return nil end
    local post = PRICES:Post(vendor, key)
    local limit = PRICES:Limit(outlook, post)
    if not limit or low > limit then return nil end
    local gain = PRICES:Sale(outlook.high) - post - low
    local most = Most(key, limit, outlook.daily)
    return { key = key, id = id, low = low, limit = limit, gain = gain, most = most, high = outlook.high,
        highAt = outlook.highAt, allDay = outlook.allDay, at = outlook.at, daily = outlook.daily, total = gain * most }
end

-- To buy here and sell in the house of the other kind.
local function Away(key, id, low, vendor)
    local route = PRICES:Route(key, vendor)
    if not (route and route.sale and route.daily and route.daily > 0) then return nil end
    local limit = PRICES:Trip(route)
    if low > limit then return nil end
    local gain = route.sale - low
    local most = Most(key, limit, route.daily)
    return { key = key, id = id, low = low, limit = limit, gain = gain, most = most, high = route.high, side = route.side,
        daily = route.daily, total = gain * most }
end

-- A line to buy, or nil for an item that is no deal. Most items end at the first look, at no cost.
function Deals.Buy(key)
    local low = PRICES:Last(key)
    if not low or low <= 0 then return nil end
    local usual, theirs = PRICES:Usual(key), PRICES:RouteUsual(key)
    local cheap, far = usual and low <= usual * CHEAP, theirs and low * PRICES.TRIP <= theirs
    if not (cheap or far) then return nil end
    local id = tonumber(key:match("^%d+"))
    local vendor = Facts(id)
    local here, away = cheap and Here(key, id, low, vendor), far and Away(key, id, low, vendor)
    if here and away then return away.total > here.total and away or here end
    return here or away or nil
end

-- A line to sell, or nil for what is better kept or sold another way. what: { key, id, item, count, here, bag, slot, there }.
function Deals.Sell(what)
    local vendor = Facts(what.id)
    local low = PRICES:Low(what.item)
    local post = low and PRICES:Post(vendor, what.item)
    local price = low and PRICES:PostAt(low, vendor, what.item)
    local sale = low and PRICES:Sale(price) - post or 0
    local route = PRICES:Route(what.item, vendor)
    if route and route.sale and route.sale > math.max(sale, vendor) * PRICES.AWAY then
        what.price, what.vendor, what.side = route.high, vendor, route.side
        what.gain, what.total = route.sale - vendor, (route.sale - vendor) * what.count
        return what
    end
    if not low or sale <= vendor * PRICES.BETTER then return nil end
    local outlook = PRICES:Outlook(what.item)
    if outlook and outlook.days >= PRICES.TRUSTED and (outlook.daily == 0 or PRICES:Later(outlook, sale, post)) then return nil end
    what.price, what.vendor, what.gain, what.total = price, vendor, sale - vendor, (sale - vendor) * what.count
    return what
end

-- The bags past the backpack, and Retail's reagent bag after them (as Core counts the bags carried; Forever, without
-- the constant, has four).
local function Bags()
    local constants = rawget(_G, "Constants") and Constants.InventoryConstants
    local bags = constants and constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4
    return bags + (constants and constants.NumReagentBagSlots or 0)
end

-- The bags of the character played, a slot at a time: its things are the ones that can be posted now.
local function InBags(held)
    local bags = rawget(_G, "C_Container")
    if not bags then return end
    for bag = 0, Bags() do
        for slot = 1, Ask(bags.GetContainerNumSlots, bag) or 0 do
            local info = Plain(Ask(bags.GetContainerItemInfo, bag, slot))
            local id = type(info) == "table" and Plain(info.itemID)
            if type(id) == "number" and Plain(info.isBound) ~= true then
                local link = Plain(info.hyperlink)
                local key = PRICES.Gear(id) and type(link) == "string" and PRICES.LinkKey(link, id) or tostring(id)
                local what = held[key]
                if not what then
                    what = { key = key, id = id, item = link or id, count = 0, here = 0, bag = bag, slot = slot, there = {} }
                    held[key] = what
                end
                local count = Plain(info.stackCount) or 1
                what.count, what.here = what.count + count, what.here + count
            end
        end
        Steps.Check()
    end
end

local function Elsewhere(held, id, count, name)
    local _, bind = Facts(id)
    if bind == BOP or bind == QUEST then return end
    local key = tostring(id)
    local what = held[key]
    if not what then
        what = { key = key, id = id, item = id, count = 0, here = 0, there = {} }
        held[key] = what
    end
    what.count = what.count + count
    what.there[#what.there + 1] = { name = name, count = count }
end

-- What the others have, and this character's bank: the characters' data knows items by ID, so kinds of gear are one line.
local function OnOthers(held)
    local me = Core.charKey
    for _, who in ipairs(Data.Characters() or {}) do
        for _, place in ipairs({ "bags", "bank" }) do
            if not (who.key == me and place == "bags") then
                local name = who.key == me and ns.TEXT.bank or who.name
                for _, thing in ipairs(Data.Items(who.key, place) or {}) do Elsewhere(held, thing.item, thing.count, name) end
            end
        end
        Steps.Check()
    end
    for _, thing in ipairs(Data.Items(ACCOUNT, "bank") or {}) do Elsewhere(held, thing.item, thing.count, ns.TEXT.accountBank) end
end

local function Make()
    local list = {}
    for _, key in ipairs(PRICES:Scanned()) do
        local line = Deals.Buy(key)
        if line then list[#list + 1] = line end
        Steps.Check()
    end
    local held, sold = {}, {}
    InBags(held)
    OnOthers(held)
    for _, what in pairs(held) do
        local line = Deals.Sell(what)
        if line then sold[#sold + 1] = line end
        Steps.Check()
    end
    buys, sells = Keep(list), Keep(sold)
end

function Deals.Buys() return buys end
function Deals.Sells() return sells end

function Deals.Ready(fn)
    ready = fn
end

function Deals.Refresh()
    if Steps.Running(JOB) then return end
    Steps.Run({ name = JOB, label = "economy: deals", done = ns.Guard(function()
        if ready then ready() end
    end) }, Make)
end
