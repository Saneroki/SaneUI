local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Tooltips - Kinds - Gold
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
--  The advice is the way that brings the most; the auction house, after its
--  post, and disenchanting if your character can, must bring 5% more than
--  the way before to be advised (BETTER), for the trouble. Where the scans show the
--  price will be better soon, the advice is to sell then:
--
--      Sell Fri 18:00-21:00 for 3s 60c     +45c more
--
--  On an item the auction house lists to you (you buy it), the advice is the most
--  it is worth paying instead: what it brings again at the auction house, from a
--  vendor or disenchanted (green while the lowest price now is under it, red over
--  it). Where the scans know the item, that is what it will fetch less the cut and
--  the post, less a margin (Core's Prices:Limit), with when to sell and how many cost less:
--
--      Buy if under 15s 40c                  now 10s
--      Sell Fri 18:00-21:00 for 20s      +8s 80c each
--      12 on offer under 15s 40c
--
--  or, too dear now, when it will be cheap enough:
--
--      Buy if under 15s 40c                  now 18s
--      Buy Tue 03:00-06:00 for 14s
--
--  The forecast is Core's (Prices:Outlook, Core's Data/Rhythm.lua): from three days of an
--  item's prices on, a time only where the scans show one. An item seen not to sell
--  gets no advice to buy it for that.
--
--  With Alt held: under Disenchant each material (how often, how many, what it
--  brings); then the price to post it at (Sell at: the lowest offer less a
--  step, never so low that a sale brings less than a vendor pays); under the
--  advice the price it comes from, the market, how many are on offer and when
--  that was seen, the cut and the deposit, what the forecast stands on (what it
--  usually costs, its dearest and cheapest time, how much of it sells); last, how
--  its price went (PriceGraph.lua).
--
--  What the house takes, and how a post and a price to post are reckoned, is Core's (Data/Fees.lua).
--
--  Disenchanting, from Core's data (the set Disenchants, Doc/guides/data.md):
--  a weapon or an armour of uncommon quality and up, by its class, quality and
--  item level. A material without a price seen makes no value: the row says so.
--
--  The prices are Core's (Data.Series("Prices")): what the auction house lists
--  right now while you look at it, else its last full scan. The panels are read
--  anew when they change. Without one, the section is the vendor's row, under
--  its caption all the same.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask, Data = Core.Plain, Core.Ask, Core.Data
local DISENCHANTS, PRICES = Data.Set("Disenchants"), Data.Series("Prices")
local Read, TEXT = ns.Reader, ns.TEXT
local Gold = {}
ns.Gold = Gold

local WEAPON = Enum.ItemClass and Enum.ItemClass.Weapon or 2
local ARMOR = Enum.ItemClass and Enum.ItemClass.Armor or 4
local DISENCHANTED = { [WEAPON] = true, [ARMOR] = true } -- the item classes disenchanting takes
local UNCOMMON = Enum.ItemQuality and Enum.ItemQuality.Uncommon or 2 -- and from which quality
local HELD = 400      -- items whose row of disenchanting is kept, then forgotten together
local DISENCHANT_SPELL = 13262 -- the game's spell: only with it is disenchanting a way for this character
local STRETCH = 3 * 3600 -- how long the time a forecast names lasts (Core's Rhythm.lua)

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

-- What a sale of one at the auction house brings: its price, after the cut (Core's Data/Fees.lua).
local function Sale(price)
    return PRICES:Sale(price)
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

-- What disenchanting brings: every material as often and as many as it comes, at its lowest price now after
-- the cut. Nil when a material has no price.
local function Disenchanted(record)
    local value = 0
    for _, material in ipairs(record.gives or {}) do
        local price = PRICES:Low(material.item)
        if not price then return nil end
        value = value + (material.chance or 0) / 100 * ((material.min or 1) + (material.max or 1)) / 2 * Sale(price)
    end
    return math.floor(value + 0.5)
end

-- What is known of the item at the auction house, for one read
local market = {}

-- Works out the section from what is known, for one of the item. item: its link, or its ID; id: its ID;
-- vendor: what a vendor pays for one (0: it buys none), or nil; bound: it cannot be sold at the auction
-- house. Fills market:
--   vendor, ah      what each way brings for one (nil: not this way; vendor 0: no vendor buys it)
--   current         the lowest price at the auction house now
--   post            what putting one up costs
--   outlook, limit  what the scans tell of its price ahead (from TRUSTED days on), and the most worth paying to sell it on
--   more            for "later" and "there": how much more that brings than the best way now
--   route, trip     what the house of the other kind says of it (Prices:Route), and whether the limit is that of a sale there
--   record, broken  its row of disenchanting, what that brings for one (nil: not this way, or no prices)
--   advice, worth   "ah", "later", "there", "vendor", "disenchant" or "buy"; for buy, the most it is worth paying
local function Work(item, id, vendor, bound, tooltip)
    wipe(market)
    local unit = vendor or 0
    market.vendor, market.item = vendor, item
    if not bound then
        market.current = PRICES:Low(item)
        if market.current then
            market.ah = Sale(market.current)
            market.post = PRICES:Post(vendor, item)
            local outlook = PRICES:Outlook(item)
            market.few = outlook and outlook.days < PRICES.TRUSTED
            if outlook and not market.few then
                market.outlook = outlook
                market.limit = PRICES:Limit(outlook, market.post)
            end
        end
        market.route = PRICES:Route(item, vendor)
        local trip = PRICES:Trip(market.route)
        if trip and trip > (market.limit or 0) then market.limit, market.trip = trip, true end
    end
    market.record = id and DisenchantOf(id)
    market.broken = market.record and Disenchanted(market.record) or nil
    local own = market.broken and Ask(rawget(_G, "IsPlayerSpell"), DISENCHANT_SPELL) == true and market.broken or 0
    if Buying(tooltip) and market.current then
        market.worth = math.floor(math.max(unit, market.limit or Sale(market.current), own))
        market.advice = market.worth > 0 and "buy" or nil
        return market
    end
    local best, value = unit > 0 and "vendor" or nil, unit
    local sale = market.ah and market.ah - market.post
    local better = PRICES.BETTER
    if sale and sale > value * better then best, value = "ah", sale end
    if own > value * better then best, value = "disenchant", own end
    local outlook = market.outlook
    local later = outlook and outlook.highAt and outlook.highAt > outlook.at and PRICES:Later(outlook, value, market.post)
    if later then best, value, market.more = "later", later, later - value end
    local there = market.route and market.route.sale
    if there and there > value * PRICES.AWAY then best, value, market.more = "there", there, there - value end
    market.advice = value > 0 and best or nil
    return market
end

local function Row(label, value)
    local row = Read.Text("sub", label, DETAIL[1], DETAIL[2], DETAIL[3])
    row.right, row.rr, row.rg, row.rb = Money(value), MONEY[1], MONEY[2], MONEY[3]
    if value == 0 and label == TEXT.VENDOR then row.right, row.rr, row.rg, row.rb = TEXT.NO_VENDOR, DETAIL[1], DETAIL[2], DETAIL[3] end
    return row
end

-- When a forecast names, as the player's clock says it: the day, and its stretch if the time of day counts. Held for the
-- hour: a tooltip is read several times a second.
local whens, whensHour = {}, nil
local function When(outlook, at)
    local now = outlook.at
    local hour = math.floor(now / 3600)
    if hour ~= whensHour then
        wipe(whens)
        whensHour = hour
    end
    local text = whens[at]
    if text then return text end
    text = date("%j", at) == date("%j", now) and TEXT.TODAY or date("%a", at)
    if not outlook.allDay then text = TEXT.WHEN:format(text, Core.ClockAt(at), Core.ClockAt(at + STRETCH)) end
    whens[at] = text
    return text
end

-- The house of the other kind, in words.
local function Where(route)
    return route.side == "neutral" and TEXT.NEUTRAL_AH or TEXT.FACTION_AH
end

-- The advice in one line: what to do (left, in its colour) and how much more (right).
local function Advice(m)
    local left, right, color, rightColor
    local advice = m.advice
    if advice == "ah" then
        left, color = Read.Memo("goldAdvice", TEXT.SELL_AH, Money(m.current)), SELL
    elseif advice == "later" then
        left, color = Read.Memo("goldLater", TEXT.SELL_WHEN, When(m.outlook, m.outlook.highAt), Money(m.outlook.high)), SELL
        right, rightColor = Read.Memo("goldMore", TEXT.MORE, Money(m.more)), SELL
    elseif advice == "there" then
        left, color = Read.Memo("goldThere", TEXT.SELL_THERE, Where(m.route), Money(m.route.high)), SELL
        right, rightColor = Read.Memo("goldMore", TEXT.MORE, Money(m.more)), SELL
    elseif advice == "vendor" then
        left, color = TEXT.SELL_VENDOR, VENDOR
        if m.ah and m.vendor > m.ah then right, rightColor = Read.Memo("goldMore", TEXT.MORE_AH, Money(m.vendor - m.ah)), DETAIL end
    elseif advice == "disenchant" then
        left, color = Read.Memo("goldAdvice", TEXT.DISENCHANT_IT, Money(m.broken)), SELL
    elseif advice == "buy" then
        local good = m.current < m.worth
        left, color = Read.Memo("goldAdvice", TEXT.BUY_UNDER, Money(m.worth)), good and SELL or NO
        right, rightColor = Read.Memo("goldNow", TEXT.NOW, Money(m.current)), good and SELL or NO
    end
    if not left then return end
    local row = Read.Text("row", left, color[1], color[2], color[3])
    if right then row.right, row.rr, row.rg, row.rb = right, rightColor[1], rightColor[2], rightColor[3] end
end

-- Under the advice to buy: when to sell and what one brings, and how many cost less; too dear now, when to buy instead.
local function Plan(m, item)
    local outlook, limit = m.outlook, m.limit
    local route = m.route
    if m.advice == "buy" and m.trip and m.current <= limit then
        local row = Read.Text("row", Read.Memo("goldPlanThere", TEXT.SELL_THERE, Where(route), Money(route.high)), SELL[1], SELL[2], SELL[3])
        row.right, row.rr, row.rg, row.rb = Read.Memo("goldEach", TEXT.EACH, Money(route.sale - m.current)), SELL[1], SELL[2], SELL[3]
        local units = PRICES:Under(item, limit)
        if units and units > 0 then Read.Text("small", Read.Memo("goldUnder", TEXT.ON_OFFER, units, Money(limit)), SMALL[1], SMALL[2], SMALL[3]) end
        return
    end
    -- Too dear here, and worth the trip to buy it there
    if m.advice == "buy" and route and route.low > 0 and limit and route.low <= limit and route.low * PRICES.TRIP <= m.current then
        return Read.Text("row", Read.Memo("goldPlanBuy", TEXT.BUY_THERE, Where(route), Money(route.low)), SELL[1], SELL[2], SELL[3])
    end
    if m.advice ~= "buy" or not (outlook and limit) then return end
    if m.current <= limit then
        local price = Money(outlook.high)
        local left = outlook.highAt and outlook.highAt > outlook.at and Read.Memo("goldPlan", TEXT.SELL_WHEN, When(outlook, outlook.highAt), price)
            or Read.Memo("goldPlanFor", TEXT.SELL_FOR, price)
        local row = Read.Text("row", left, SELL[1], SELL[2], SELL[3])
        row.right, row.rr, row.rg, row.rb = Read.Memo("goldEach", TEXT.EACH, Money(Sale(outlook.high) - m.post - m.current)), SELL[1], SELL[2], SELL[3]
        local units = PRICES:Under(item, limit)
        if units and units > 0 then Read.Text("small", Read.Memo("goldUnder", TEXT.ON_OFFER, units, Money(limit)), SMALL[1], SMALL[2], SMALL[3]) end
    elseif outlook.lowAt and outlook.lowAt > outlook.at and outlook.low <= limit then
        Read.Text("row", Read.Memo("goldPlanBuy", TEXT.BUY_WHEN, When(outlook, outlook.lowAt), Money(outlook.low)), SELL[1], SELL[2], SELL[3])
    end
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
        local price = PRICES:Low(material.item)
        if price then row.right, row.rr, row.rg, row.rb = Money(Sale(price)), SMALL[1], SMALL[2], SMALL[3] end
    end
end

-- The price to post one at, at the auction house: Core's, from the lowest offer. Nil without an offer seen.
local function PostAt(m)
    if not m.current then return nil end
    return PRICES:PostAt(m.current, m.vendor, m.item)
end
Gold.PostAt = PostAt

-- With Alt held: what the forecast stands on, small: what the item usually costs and where that goes, its dearest and cheapest
-- time, what sells of it.
local function Forecast(m)
    if m.few then return Read.Text("small", TEXT.FEW_SCANS, SMALL[1], SMALL[2], SMALL[3]) end
    local outlook = m.outlook
    if not outlook then return end
    local percent = math.floor(math.abs(outlook.drift) * 100 + 0.5)
    local text = percent < 1 and TEXT.USUAL or outlook.drift > 0 and TEXT.RISING or TEXT.FALLING
    Read.Text("small", Read.Memo(text, text, Money(outlook.usual), percent), SMALL[1], SMALL[2], SMALL[3])
    if outlook.highAt then Read.Text("small", Read.Memo("goldDear", TEXT.DEAREST, When(outlook, outlook.highAt), Money(outlook.high)), SMALL[1], SMALL[2], SMALL[3]) end
    if outlook.lowAt then Read.Text("small", Read.Memo("goldCheap", TEXT.CHEAPEST, When(outlook, outlook.lowAt), Money(outlook.low)), SMALL[1], SMALL[2], SMALL[3]) end
    if outlook.each then
        local rate = outlook.daily >= 10 and "%.0f" or "%.1f"
        Read.Text("small", Read.Memo("goldSells", TEXT.SELLS, rate:format(outlook.daily), Money(outlook.each)), SMALL[1], SMALL[2], SMALL[3])
    elseif outlook.daily then
        Read.Text("small", TEXT.NO_SALES, SMALL[1], SMALL[2], SMALL[3])
    end
    if m.limit and m.advice ~= "buy" then Read.Text("small", Read.Memo("goldWorth", TEXT.WORTH, Money(m.limit)), SMALL[1], SMALL[2], SMALL[3]) end
end

-- With Alt held: what the house of the other kind asks.
local function Elsewhere(m)
    local route = m.route
    if not route or route.low <= 0 then return end
    local text = route.usual and Read.Memo("goldElsewhere", TEXT.THERE_USUAL, Where(route), Money(route.low), Money(route.usual))
        or Read.Memo("goldElsewhereLow", TEXT.THERE, Where(route), Money(route.low))
    Read.Text("small", text, SMALL[1], SMALL[2], SMALL[3])
end

-- With Alt held: where the numbers come from, small: the price, the market and what is on offer, how long ago.
local function Details(m, item)
    if not m.current then return end
    Read.Text("small", Read.Memo("goldPrices", TEXT.PRICES, Money(m.current)), SMALL[1], SMALL[2], SMALL[3])
    local _, usual, units, _, _, at = PRICES:Last(item)
    if at then
        local days = math.floor(((Ask(rawget(_G, "GetServerTime")) or at) - at) / 86400)
        local when = days < 1 and Core.ClockAt(at) or Read.Memo("goldDays", TEXT.DAYS_AGO, days)
        local seen = units and units > 0 and Read.Memo("goldSeen", TEXT.SEEN, units, when) or Read.Memo("goldSeen", TEXT.SEEN_AT, when)
        Read.Text("small", seen, SMALL[1], SMALL[2], SMALL[3])
        if usual and usual > 0 then
            Read.Text("small", Read.Memo("goldUsual", TEXT.MARKET, Money(usual)), SMALL[1], SMALL[2], SMALL[3])
        end
    end
    local fees = Read.Memo("goldFees", TEXT.FEES, Money(m.current * PRICES:Cut()), Money(PRICES:Deposit(m.vendor, 1)))
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
    local link = ctx.data and Plain(ctx.data.hyperlink)
    local item = type(link) == "string" and link or id
    local m = Work(item, id, Gold.VendorEach(id, line), bound, ctx.tooltip)
    if not (m.vendor or m.ah or m.advice or binding or looks) then return end
    -- A vendor's price alone has no advice: there is no choice to make.
    local alone = not (m.ah or m.advice == "buy" or m.advice == "disenchant")
    local alt = IsAltKeyDown()
    Read.Section(TEXT.GOLD)
    Gold.Terms(binding, looks)
    if m.vendor then Row(TEXT.VENDOR, m.vendor) end -- every item, also one no vendor buys
    if m.ah then Row(TEXT.AH_PROFIT, m.ah) end
    local disenchant = m.record
    if disenchant then
        if m.broken then
            Row(TEXT.DISENCHANT, m.broken)
        else
            local row = Read.Text("sub", TEXT.DISENCHANT, DETAIL[1], DETAIL[2], DETAIL[3])
            row.right, row.rr, row.rg, row.rb = TEXT.NO_PRICES, SMALL[1], SMALL[2], SMALL[3]
        end
        if alt then Materials(disenchant) end
    end
    local post = alt and PostAt(m)
    if post then Row(TEXT.SELL_AT, post) end
    if not alone then
        Advice(m)
        Plan(m, item)
    end
    if alt then
        Details(m, item)
        Forecast(m)
        Elsewhere(m)
    end
    if alt and not bound and PRICES:Last(item) then ns.Graph.Row(item) end
end

-- What disenchanting gives is asked for once the loading screen is gone; the shown panels are drawn anew
-- when it comes or changes, and when the auction house's prices do (arrived).
function Gold.Start(arrived)
    if arrived then PRICES:OnChange(arrived) end
    DISENCHANTS:OnStamp(function()
        wipe(disenchants)
        heldCount = 0
        if arrived then arrived() end
    end)
    Data.Prepare("Disenchants")
end
