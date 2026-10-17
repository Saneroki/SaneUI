local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Gold
--  An item's Gold section (Kinds/Item.lua draws it last): what one of the item
--  brings in, two ways, and in one line what to do with it. Always for one,
--  also when you point at a stack: the ways compare one to one.
--
--      GOLD ───────────────────────────────
--      Vendor                       2s 98c    what a vendor pays for one (every item; one
--                                             it does not buy: "Can't be sold")
--      AH profit                    2s 85c    what a sale of one at the auction house brings,
--                                             at its lowest price, after the house's cut
--      Sell on the AH for 3s 09c
--
--  The advice is the way that brings the most; the auction house must bring 5%
--  more than a vendor to be advised (BETTER), for the trouble. On an item the
--  auction house lists to you (you buy it), the advice is the most it is worth
--  paying instead: what it brings again at the auction house or from a vendor
--  (green while the lowest price now is under it, red over it).
--
--  With Alt held, under it: the price it comes from, the cut and the deposit.
--
--  The prices are the ones you last saw yourself at the auction house
--  (Auction.lua). Without one, the section is the vendor's row.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Read, TEXT = ns.Reader, ns.TEXT
local Gold = {}
ns.Gold = Gold

local CUT = 0.05      -- the auction house's cut of a sale
local DEPOSIT = 0.60  -- a 48-hour auction's deposit, of what a vendor pays (15% for every 12 hours).
                      -- Given back when the item sells.
local BETTER = 1.05   -- how much more the auction house must bring than a vendor to be advised

local COLOR = ns.COLOR
local DETAIL, MONEY = COLOR.DETAIL, COLOR.TITLE -- the rows' words; what they bring
local SELL = COLOR.DONE    -- sell or buy at the auction house: green
local NO = COLOR.RED       -- too dear to buy: red
local VENDOR = COLOR.TITLE
local SMALL = COLOR.ASIDE  -- the details with Alt

-- Money as the game writes it with its coin icons, kept by value: a tooltip is read several times
-- a second, with the same prices.
local coins, coinCount = {}, 0
local function Money(copper)
    copper = math.max(0, math.floor(copper + 0.5))
    local text = coins[copper]
    if text then return text end
    if coinCount > 300 then
        wipe(coins)
        coinCount = 0
    end
    text = Core.Coins(copper) or ("%dc"):format(copper)
    coins[copper], coinCount = text, coinCount + 1
    return text
end
Gold.Money = Money

-- What a sale of one at the auction house brings: its price, after the cut.
local function Sale(price)
    return math.floor(price - price * CUT)
end
Gold.Sale = Sale

-- Whether the panel's item is one the auction house lists to you (to buy), by how the game filled
-- the tooltip (its getter: GetItemKey for the house's lists).
local function Buying(tooltip)
    local info = tooltip and tooltip.GetPrimaryTooltipInfo and Plain(tooltip:GetPrimaryTooltipInfo())
    local getter = type(info) == "table" and Plain(info.getterName)
    return type(getter) == "string" and (getter:find("ItemKey", 1, true) or getter:find("Auction", 1, true)) ~= nil
end

-- What is known of the item at the auction house, for one read
local market = {}

-- Works out the section from what is known, for one of the item. vendor: what a vendor pays for
-- one (0: it buys none), or nil; bound: it cannot be sold at the auction house. Fills market:
--   vendor, ah      what each way brings for one (nil: not this way; vendor 0: no vendor buys it)
--   current         the lowest price you last saw at the auction house
--   advice, worth   "ah", "vendor" or "buy"; for buy, the most it is worth paying
local function Work(id, vendor, bound, tooltip)
    wipe(market)
    local unit = vendor or 0
    market.vendor = vendor
    if not bound then
        market.current = ns.Auction.Price(id)
        if market.current then market.ah = Sale(market.current) end
    end
    if Buying(tooltip) and market.current then
        market.worth = math.floor(math.max(unit, market.current * (1 - CUT)))
        market.advice = market.worth > 0 and "buy" or nil
        return market
    end
    local best, value = unit > 0 and "vendor" or nil, unit
    if market.ah and market.ah > value * BETTER then best, value = "ah", market.ah end
    market.advice = value > 0 and best or nil
    return market
end
Gold.Work = Work

local function Row(label, value)
    local row = Read.Text("sub", label, DETAIL[1], DETAIL[2], DETAIL[3])
    row.right, row.rr, row.rg, row.rb = Money(value), MONEY[1], MONEY[2], MONEY[3]
    if value == 0 and label == TEXT.VENDOR then row.right, row.rr, row.rg, row.rb = TEXT.NO_VENDOR, DETAIL[1], DETAIL[2], DETAIL[3] end
    return row
end

-- The advice in one line: what to do (left, in its colour) and how much more (right).
local function Advice(m)
    local left, right, color, rightColor
    local advice = m.advice
    if advice == "ah" then
        left, color = Read.Memo("goldAdvice", TEXT.SELL_AH, Money(m.current)), SELL
    elseif advice == "vendor" then
        left, color = TEXT.SELL_VENDOR, VENDOR
        if m.ah and m.vendor > m.ah then right, rightColor = Read.Memo("goldMore", TEXT.MORE_AH, Money(m.vendor - m.ah)), DETAIL end
    elseif advice == "buy" then
        local good = m.current < m.worth
        left, color = Read.Memo("goldAdvice", TEXT.BUY_UNDER, Money(m.worth)), good and SELL or NO
        right, rightColor = Read.Memo("goldNow", TEXT.NOW, Money(m.current)), good and SELL or NO
    end
    if not left then return end
    local row = Read.Text("row", left, color[1], color[2], color[3])
    if right then row.right, row.rr, row.rg, row.rb = right, rightColor[1], rightColor[2], rightColor[3] end
end

-- With Alt held: where the numbers come from, small.
local function Details(m)
    if not m.current then return end
    Read.Text("small", Read.Memo("goldPrices", TEXT.PRICES, Money(m.current)), SMALL[1], SMALL[2], SMALL[3])
    local fees = Read.Memo("goldFees", TEXT.FEES, Money(m.current * CUT), Money((m.vendor or 0) * DEPOSIT))
    Read.Text("small", fees, SMALL[1], SMALL[2], SMALL[3])
end

-- What a vendor pays for one of the item (GetItemInfo's eleventh answer; 0: it buys none). While the
-- game does not have the item yet, it is asked for (a later read of the tooltip has it) and line
-- stands in: what the game's price line says, or nil.
function Gold.VendorEach(id, line)
    local info = C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    local each = id and info and Plain((select(11, info(id))))
    if type(each) == "number" then return each end
    if id and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return line
end

-- The section, at the panel's end. line: what a vendor pays as the game's price line says (a stack:
-- for all of it); id: the item; bound: it cannot be sold at the auction house.
function Gold.Section(ctx, id, line, bound)
    local m = Work(id, Gold.VendorEach(id, line), bound, ctx.tooltip)
    if not (m.vendor or m.ah or m.advice) then return end
    -- A vendor's price alone is a row under a divider, as the game has it: no caption, no advice.
    local alone = not (m.ah or m.advice == "buy")
    if alone then
        ctx.rule = true
    else
        ctx.rule = false
        local caption = Read.Row()
        caption.kind, caption.left = "caption", TEXT.GOLD
    end
    if m.vendor then Row(TEXT.VENDOR, m.vendor) end -- every item, also one no vendor buys
    if m.ah then Row(TEXT.AH_PROFIT, m.ah) end
    if not alone then Advice(m) end
    if IsAltKeyDown() then Details(m) end
end
