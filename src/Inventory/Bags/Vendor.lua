local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Vendor
--  Auto Sell and Auto Repair (Saneroki, 2026-10-30): two checkboxes in the foot
--  of the bags, left of the gold, pencil boxes with a pencil tick (the settings
--  autoSell and autoRepair, on at first, also on the page Inventory), and what
--  they do as a vendor's window opens, whether the bags were ever opened or
--  not. The junk goes first, so its money goes to the repair: what the bar's
--  Sell All Junk Items sells (Foot.Sell), unasked. Then all the gear, with the
--  character's own money and only if that is enough. Shift held as the window
--  opens leaves both to the player.
--
--      Vendor.Build(foot, gold)   the boxes in the foot, left of gold (Foot.Build)
--      Vendor.Refresh()           the ticks and widths as the settings have them
--      Vendor.Start()             listens for vendors, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Vendor = {}
ns.Vendor = Vendor

Vendor.BOX = 15                 -- a checkbox's pencil box
Vendor.BOX_WEIGHT = 0.5         -- its pencil
Vendor.WORD_GAP = 4             -- from a box to its word
Vendor.APART = 12               -- between the two, and from the gold
Vendor.TICK = 2                 -- the tick's pencil
Vendor.TICK_WAY = { { -4, 0 }, { -1, -3 }, { 5, 4 } } -- the tick's line from the box's middle
Vendor.BOXES = { { key = "autoRepair", word = "bagsAutoRepair", tip = "bagsAutoRepairTip" },
                 { key = "autoSell", word = "bagsAutoSell", tip = "bagsAutoSellTip" } } -- from the gold leftwards

local boxes = {}

local function Game(name, ...)
    return Core.Ask(rawget(_G, name), ...)
end

-------------------------------------------------------------------------------
--  At a vendor
-------------------------------------------------------------------------------
-- All the gear mended, while the vendor is there, with the character's own money.
local function Repair()
    if not ns.options.autoRepair or not ns.Foot.Talking("Merchant") then return end
    if not Game("CanMerchantRepair") then return end
    local cost, can = Game("GetRepairAllCost")
    cost = Core.Plain(cost)
    if not can or type(cost) ~= "number" or cost <= 0 or cost > (Core.Plain(Game("GetMoney")) or 0) then return end
    Game("RepairAllItems")
    Core.Print(ns.TEXT.bagsRepaired:format(Core.Coins(cost) or tostring(cost)))
end

local function Arrived()
    if not ns.Foot.Talking("Merchant") or Game("IsShiftKeyDown") then return end
    if not ns.options.autoSell then return Repair() end
    ns.Bags.Store() -- the player's junk marks, the bags' window perhaps not built yet
    ns.Foot.Sell(Repair)
end

function Vendor.Start()
    ns.On("MERCHANT_SHOW", Core.Later(function() ns.Guarded(Arrived) end))
end

-------------------------------------------------------------------------------
--  The boxes
-------------------------------------------------------------------------------
local function Clicked(box)
    local on = ns.options[box.key] == false
    Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    Core.Set(ns.name, box.key, on)
end

local function Entered(box)
    box.pencil:SetStrong(true)
    GameTooltip:SetOwner(box, "ANCHOR_TOP")
    GameTooltip:SetText(ns.TEXT[box.word], 1, 1, 1)
    GameTooltip:AddLine(ns.TEXT[box.tip], 1, 0.82, 0, true)
    GameTooltip:Show()
end

local function Left(box)
    box.pencil:SetStrong(false)
    GameTooltip_Hide()
end

-- The tick, drawn as two pencil strokes: Kalam has no such letter.
local function Tick(parent)
    local tick = CreateFrame("Frame", nil, parent)
    tick:SetAllPoints()
    local ink = ns.Paper.INK
    for index = 2, #Vendor.TICK_WAY do
        local from, to = Vendor.TICK_WAY[index - 1], Vendor.TICK_WAY[index]
        local stroke = tick:CreateLine(nil, "ARTWORK")
        stroke:SetThickness(Vendor.TICK)
        stroke:SetColorTexture(ink[1], ink[2], ink[3], ink[4])
        stroke:SetStartPoint("CENTER", tick, from[1], from[2])
        stroke:SetEndPoint("CENTER", tick, to[1], to[2])
    end
    return tick
end

local function Box(foot, spec, font)
    local box = CreateFrame("CheckButton", nil, foot)
    box:SetHeight(Vendor.BOX)
    box.key, box.word, box.tip = spec.key, spec.word, spec.tip
    local square = CreateFrame("Frame", nil, box)
    square:SetSize(Vendor.BOX, Vendor.BOX)
    square:SetPoint("LEFT")
    box.pencil = J.Box(square, Vendor.BOX_WEIGHT)
    box.tick = Tick(square)
    box.text = box:CreateFontString(nil, "ARTWORK")
    if font then box.text:SetFontObject(font) end
    box.text:SetPoint("LEFT", square, "RIGHT", Vendor.WORD_GAP, 0)
    box.text:SetText(ns.TEXT[spec.word])
    box:SetScript("OnClick", ns.Guard(Clicked))
    box:SetScript("OnEnter", ns.Guard(Entered))
    box:SetScript("OnLeave", ns.Guard(Left))
    return box
end

function Vendor.Refresh()
    for _, box in ipairs(boxes) do
        local on = ns.options[box.key] ~= false
        box:SetChecked(on)
        box.tick:SetShown(on)
        box:SetWidth(Vendor.BOX + Vendor.WORD_GAP + (box.text:GetStringWidth() or 0))
    end
end

function Vendor.Build(foot, gold)
    local font = ns.Bags.Fonts().count
    local before = gold
    for index, spec in ipairs(Vendor.BOXES) do
        local box = Box(foot, spec, font)
        box:SetPoint("RIGHT", before, "LEFT", -Vendor.APART, 0)
        boxes[index] = box
        before = box
    end
    Vendor.boxes = boxes
    Vendor.Refresh()
end
