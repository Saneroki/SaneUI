-- Price graph: an item's tooltip with Alt held, how its price went in its Gold section, in every range; when to buy and sell it
-- Core, its auction data and Tooltips from their TOCs; the auction data is made up, shaped as scans leave it: forty days
-- and a day of scans, every 16 minutes. In the console: LabRange("24h") shows a range, LabTap() is a tap of Ctrl, LabAlt(false)
-- lets go of Alt, LabPinned() shows the chat link's tooltip, whose buttons take the mouse, LabBuying(price) shows the item as
-- a row of the auction house's list at that price, LabBuying() as yours again, LabSold(false) as an item nobody buys, LabScans(1)
-- with a day of scans behind it. Three weeks of scans lie behind it: dear from 18:00 to 21:00, cheap from 3:00 to 6:00, 12 sold
-- a day, of which the scene lists five. The module is LabTooltips.
local filled
TooltipDataProcessor = { AllTypes = "ALL", AddTooltipPostCall = function(_, fn) filled = fn end }

local held = true
IsAltKeyDown = function() return held end

Lab.TOC("src/Core/SaneUI.toc")
Lab.TOC("src/AuctionData/SaneUI_AuctionData.toc")
local ns = Lab.TOC("src/Tooltips/SaneUI_Tooltips.toc")
LabTooltips = ns

local ITEM = 2589 -- Linen Cloth, from the data master
local DAY, SCAN = 86400, 16 * 60

-- A price that goes up and down over the weeks, with a little noise of its own each time
local function Price(at)
    local days = at / DAY
    return math.floor(4200 + 1400 * math.sin(days / 3.1) + 500 * math.sin(days * 2.3) + (at * 7 % 311))
end

local listed -- how the game fills a row of the auction house's list: without the vendor's price (Kinds/Gold.lua, Buying)

local function Tip(tooltip)
    tooltip.GetPrimaryTooltipInfo = function() return listed end
    tooltip:ClearLines()
    tooltip:AddLine("Linen Cloth")
    tooltip:AddLine("Sell Price: 13c")
    tooltip:Show()
    filled(tooltip, { type = Enum.TooltipDataType.Item, id = ITEM, lines = {
        { leftText = "Linen Cloth", type = 0 }, { leftText = "Sell Price: 13c", type = 0 } } })
end

local function Show()
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("CENTER", UIParent, "CENTER", -180, 40)
    Tip(GameTooltip)
end

function LabRange(key)
    SaneUI.Core.Set("Tooltips", "priceRange", key)
    Show()
end

function LabTap()
    SaneUI.Core.Ask(function() Lab.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 1) end)
    Lab.Fire("MODIFIER_STATE_CHANGED", "LCTRL", 0)
end

function LabAlt(on)
    held = on
    Lab.Fire("MODIFIER_STATE_CHANGED", "LALT", on and 1 or 0)
end

function LabPinned()
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    ItemRefTooltip:ClearAllPoints()
    ItemRefTooltip:SetPoint("CENTER", UIParent, "CENTER", 180, 40)
    ItemRefTooltip:EnableMouse(true)
    Tip(ItemRefTooltip)
end

local function Dressed(at)
    local hour = date("*t", at).hour
    return hour >= 18 and hour < 21 and 8200 or hour >= 3 and hour < 6 and 3100 or 4300
end

-- The scans' line of the item: that many days, and how many sold.
local function Scans(days, sold)
    local Prices, Rhythm = SaneUI.Core.Data.Series("Prices"), SaneUI.Core.Data.Rhythm
    local house, now = Prices.House("player"), GetServerTime()
    local line
    for step = days * 8, 1, -1 do
        local at = now - step * 3 * 3600
        line = Rhythm.Seen(line, at, Dressed(at))
    end
    house.rhythm[tostring(ITEM)] = sold and Rhythm.Sold(line, now, sold * 7, sold * 7 * 4500) or line
    house.watched, house.watchedAt = 7 * DAY, now
    Prices.Changed()
end

function LabScans(days)
    Scans(days, 12)
    Show()
end

function LabSold(on)
    Scans(21, on and 12 or nil)
    Show()
end

function LabBuying(price)
    local Prices = SaneUI.Core.Data.Series("Prices")
    listed = price and { getterName = "GetHyperlink", getterArgs = { "item:" .. ITEM, nil, nil, true, n = 4 } } or nil
    Prices.Take(Prices.House("player"), tostring(ITEM), GetServerTime(), price or 4300, 4800, 120, 30, 12)
    Prices.Changed()
    Show()
end

Lab.OnLogin(function()
    SaneUI.Core.Set("Tooltips", "show", "always") -- at first the game shows them only while Shift is held
    local Prices = SaneUI.Core.Data.Series("Prices")
    local house = Prices.House("player")
    local now, today = GetServerTime(), math.floor(GetServerTime() / DAY)
    for day = today - 40, today - 2 do
        local at = (day + 0.5) * DAY
        house.days[day] = ("%d=%d,%d,120,30,12;"):format(ITEM, Price(at), Price(at + DAY) + 900)
    end
    for at = (today - 1) * DAY, now, SCAN do
        house.recent[at] = ("%d=%d,%d;"):format(ITEM, Price(at), Price(at + DAY) + 900)
    end
    Prices.Take(house, tostring(ITEM), now, Price(now), Price(now + DAY) + 900, 120, 30, 12)
    local UNITS = Prices.UNITS
    Prices.Offers(house, { [tostring(ITEM)] = { 3900 * UNITS + 20, 4000 * UNITS + 20, 4100 * UNITS + 10, 7000 * UNITS + 20 } })
    Scans(21, 12)
    Show()
end)
