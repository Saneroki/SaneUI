-- Price graph: an item's tooltip with Alt held, how its price went in its Gold section, in every range
-- Core, its auction data and Tooltips from their TOCs; the auction data is made up, shaped as scans leave it: forty days
-- and a day of scans, every 16 minutes. In the console: LabRange("24h") shows a range, LabTap() is a tap of Ctrl, LabAlt(false)
-- lets go of Alt, LabPinned() shows the chat link's tooltip, whose buttons take the mouse. The module is LabTooltips.
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

local function Tip(tooltip)
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
    Prices.Changed()
    Show()
end)
