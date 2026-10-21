local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Kinds - Gold
--  An item's Gold section (Kinds/Item.lua draws it last): what one of the item
--  brings in, two ways, and in one line what to do with it. Always for one,
--  also when you point at a stack: the ways compare one to one.
--
--      GOLD ───────────────────────────────
--      BoE                     Uncollected    how it binds (red until it is bound: it can still
--                                             be traded) and whether you have its look, short
--      Vendor                       2s 98c    what a vendor pays for one (every item; one
--                                             it does not buy: "Can't be sold")
--      AH profit                    2s 85c    what a sale of one at the auction house brings,
--                                             at its lowest price, after the house's cut
--      Disenchant                   1s 40c    what disenchanting it brings: its materials,
--                                             each at its lowest price after the cut, as often
--                                             and as many as disenchanting gives them
--      Sell on the AH for 3s 09c
--
--  The advice is the way that brings the most; the auction house must bring 5%
--  more than a vendor to be advised (BETTER), for the trouble. On an item the
--  auction house lists to you (you buy it), the advice is the most it is worth
--  paying instead: what it brings again at the auction house or from a vendor
--  (green while the lowest price now is under it, red over it).
--
--  With Alt held: under Disenchant each material (how often, how many, what it
--  brings); then the price to post it at (Sell at: the lowest offer less one
--  copper, never so low that a sale brings less than a vendor pays); under the
--  advice the price it comes from, the cut and the deposit.
--
--  Disenchanting, from Core's data (the set Disenchants, Doc/guides/data.md):
--  a weapon or an armour of uncommon quality and up, by its class, quality and
--  item level. A material without a price seen makes no value: the row says so.
--
--  The prices are the ones you last saw yourself at the auction house
--  (Auction.lua). Without one, the section is the vendor's row, under its
--  caption all the same.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask, Data = Core.Plain, Core.Ask, Core.Data
local DISENCHANTS = Data.Set("Disenchants")
local Read, TEXT = ns.Reader, ns.TEXT
local Gold = {}
ns.Gold = Gold

local CUT = 0.05      -- the auction house's cut of a sale
local DEPOSIT = 0.60  -- a 48-hour auction's deposit, of what a vendor pays (15% for every 12 hours).
                      -- Given back when the item sells.
local BETTER = 1.05   -- how much more the auction house must bring than a vendor to be advised
local UNDERCUT = 1    -- copper under the lowest offer, for the price to post
local WEAPON = Enum.ItemClass and Enum.ItemClass.Weapon or 2
local ARMOR = Enum.ItemClass and Enum.ItemClass.Armor or 4
local DISENCHANTED = { [WEAPON] = true, [ARMOR] = true } -- the item classes disenchanting takes
local UNCOMMON = Enum.ItemQuality and Enum.ItemQuality.Uncommon or 2 -- and from which quality
local HELD = 400      -- items whose row of disenchanting is kept, then forgotten together

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

-- Whether the auction house shows what it sells (its Buy views), not your own auctions or what you post.
-- Where the client does not say (no such frame or views), its lists alone tell, as before.
local function BuyView()
    local house, modes = rawget(_G, "AuctionHouseFrame"), rawget(_G, "AuctionHouseFrameDisplayMode")
    if not (type(house) == "table" and type(house.GetDisplayMode) == "function" and type(modes) == "table"
        and (modes.Buy or modes.ItemBuy or modes.CommoditiesBuy)) then
        return true
    end
    local mode = Ask(house.GetDisplayMode, house)
    return mode ~= nil and (mode == modes.Buy or mode == modes.ItemBuy or mode == modes.CommoditiesBuy)
end

-- Whether the panel's item is one the auction house lists to you (to buy), by how the game filled
-- the tooltip: by its item key (GetItemKey), or by its link without the vendor's price, which only the
-- house's lists leave out (GetHyperlink's fourth argument, hideVendorPrice); and only while it shows
-- what it sells (its lists of your own auctions are filled the same way).
local function Buying(tooltip)
    local info = tooltip and tooltip.GetPrimaryTooltipInfo and Plain(tooltip:GetPrimaryTooltipInfo())
    local getter = type(info) == "table" and Plain(info.getterName)
    if type(getter) ~= "string" then return false end
    local listed = getter:find("ItemKey", 1, true) or getter:find("Auction", 1, true)
    if not listed and getter == "GetHyperlink" then
        local args = Plain(info.getterArgs)
        listed = type(args) == "table" and Plain(args[4]) == true
    end
    return listed and BuyView() or false
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

-- Disenchanting -----------------------------------------------------------------------------------
local disenchants, heldCount = {}, 0 -- [item] = its record of Disenchants, or false: none

-- The row of disenchanting an item falls in (Core's set Disenchants): by its class, quality and item
-- level. Nil for one that is not disenchanted, or while the data or the item is not there yet.
local function DisenchantOf(id)
    local known = disenchants[id]
    if known ~= nil then return known or nil end
    if not DISENCHANTS:Ready() then return nil end
    local class = C_Item.GetItemInfoInstant and Plain((select(6, C_Item.GetItemInfoInstant(id))))
    local quality = Plain(C_Item.GetItemQualityByID(id))
    if not (class and DISENCHANTED[class] and type(quality) == "number" and quality >= UNCOMMON) then
        known = false
    else
        local info = C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
        local level = info and Plain((select(4, info(id))))
        if type(level) ~= "number" then return nil end -- not loaded yet (Gold.VendorEach asks for it)
        known = false
        for _, key in ipairs(DISENCHANTS:Keys("byQuality", quality)) do
            local record = DISENCHANTS:Get(key)
            if record and record.class == class and (record.levelMin or 0) <= level and level <= (record.levelMax or 0) then
                known = record
                break
            end
        end
    end
    if heldCount >= HELD then
        wipe(disenchants)
        heldCount = 0
    end
    disenchants[id], heldCount = known, heldCount + 1
    return known or nil
end

-- What disenchanting brings: every material as often and as many as it comes, at its lowest price after
-- the cut. Nil when a material has no price seen.
local function Disenchanted(record)
    local value = 0
    for _, material in ipairs(record.gives or {}) do
        local price = ns.Auction.Price(material.item)
        if not price then return nil end
        value = value + (material.chance or 0) / 100 * ((material.min or 1) + (material.max or 1)) / 2 * Sale(price)
    end
    return math.floor(value + 0.5)
end

-- With Alt held, under Disenchant: each material, how often, how many, and what one brings.
local function Materials(record)
    for index, material in ipairs(record.gives or {}) do
        local name = Plain(C_Item.GetItemNameByID and C_Item.GetItemNameByID(material.item))
        if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(material.item) end
        local count = material.min == material.max and ("%d"):format(material.min or 1)
            or Read.Memo("materialCount" .. index, "%d-%d", material.min or 1, material.max or 1)
        local chance = Read.Memo("materialChance" .. index, "%g", math.floor((material.chance or 0) * 10 + 0.5) / 10)
        local row = Read.Text("small", Read.Memo("material" .. index, TEXT.MATERIAL, chance, count, name or "?"), SMALL[1], SMALL[2], SMALL[3])
        row.indent = 20
        local price = ns.Auction.Price(material.item)
        if price then row.right, row.rr, row.rg, row.rb = Money(Sale(price)), SMALL[1], SMALL[2], SMALL[3] end
    end
end

-- The price to post one at, at the auction house: the lowest offer less an undercut, never so low that a
-- sale brings less than a vendor pays. Nil without an offer seen.
local function PostAt(m)
    if not m.current then return nil end
    local floor = (m.vendor or 0) > 0 and math.ceil(m.vendor / (1 - CUT)) or 1
    return math.max(m.current - UNDERCUT, floor)
end
Gold.PostAt = PostAt

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

-- The section's first row: how the item binds at the left, whether you have its look at the right,
-- each a short word in its colour (Kinds/Item.lua); none without either.
function Gold.Terms(binding, looks)
    if not (binding or looks) then return end
    local row = Read.Text("sub", binding or "", DETAIL[1], DETAIL[2], DETAIL[3])
    row.right = looks or ""
end

-- The section, at the panel's end. line: what a vendor pays as the game's price line says (a stack:
-- for all of it); id: the item; bound: it cannot be sold at the auction house; binding and looks: the
-- first row's words (Terms).
function Gold.Section(ctx, id, line, bound, binding, looks)
    local m = Work(id, Gold.VendorEach(id, line), bound, ctx.tooltip)
    if not (m.vendor or m.ah or m.advice or binding or looks) then return end
    -- A vendor's price alone has no advice: there is no choice to make.
    local alone = not (m.ah or m.advice == "buy")
    local alt = IsAltKeyDown()
    Read.Section(TEXT.GOLD)
    Gold.Terms(binding, looks)
    if m.vendor then Row(TEXT.VENDOR, m.vendor) end -- every item, also one no vendor buys
    if m.ah then Row(TEXT.AH_PROFIT, m.ah) end
    local disenchant = id and DisenchantOf(id)
    if disenchant then
        local value = Disenchanted(disenchant)
        if value then
            Row(TEXT.DISENCHANT, value)
        else
            local row = Read.Text("sub", TEXT.DISENCHANT, DETAIL[1], DETAIL[2], DETAIL[3])
            row.right, row.rr, row.rg, row.rb = TEXT.NO_PRICES, SMALL[1], SMALL[2], SMALL[3]
        end
        if alt then Materials(disenchant) end
    end
    local post = alt and PostAt(m)
    if post then Row(TEXT.SELL_AT, post) end
    if not alone then Advice(m) end
    if alt then Details(m) end
end

-- What disenchanting gives is asked for once the loading screen is gone; the shown panels are drawn anew
-- when it comes or changes (arrived).
function Gold.Start(arrived)
    DISENCHANTS:OnStamp(function()
        wipe(disenchants)
        heldCount = 0
        if arrived then arrived() end
    end)
    Data.Prepare("Disenchants")
end
