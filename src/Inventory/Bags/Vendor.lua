local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Bags - Vendor
--  Auto Sell and Auto Repair (Saneroki, 2026-10-30): two checkboxes in the foot
--  of the bags, left of the gold, the game's checkboxes (the settings
--  autoSell and autoRepair, on at first, also on the page Inventory), and what
--  they do as a vendor's window opens, whether the bags were ever opened or
--  not. The junk goes first, so its money goes to the repair: what the bar's
--  Sell All Junk Items sells (Foot.Sell), unasked. Then all the gear, with the
--  character's own money and only if that is enough. Shift held as the window
--  opens leaves both to the player. Beside them Make Room, Loot's own switch
--  (Room.lua), and Speed Leveling, which is the profile Speedleveling for this
--  character or the one it used before (Core's Profiles.SetLeveling), Saneroki,
--  the same day; no box where that module is off.
--
--      Vendor.Build(foot, gold)   the boxes in the foot, left of gold (Foot.Build)
--      Vendor.Refresh()           the ticks and widths as the settings have them
--      Vendor.Width(words)        how wide the boxes are together, with their words or without
--      Vendor.Words(on)           the boxes' words shown or left out (a narrow window: Foot.Room)
--      Vendor.Start()             listens for vendors, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Vendor = {}
ns.Vendor = Vendor

Vendor.BOX = 15                 -- a checkbox: the game's minimal one
Vendor.WORD_GAP = 4             -- from a box to its word
Vendor.APART = 12               -- between the two, and from the gold
Vendor.BOXES = { { key = "autoRepair", word = "bagsAutoRepair", tip = "bagsAutoRepairTip" },
                 { key = "autoSell", word = "bagsAutoSell", tip = "bagsAutoSellTip" },
                 { key = "full", word = "bagsMakeRoom", tip = "bagsMakeRoomTip", module = "Loot" },
                 { key = "take", word = "bagsSpeedLeveling", tip = "bagsSpeedLevelingTip", module = "SpeedLeveling",
                   profile = true } } -- from the gold leftwards; a profile's: key only tells that its module is there

local boxes = {}
local worded = true -- the boxes' words shown

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
    Core.OnSwitches(ns.Guard(Vendor.Refresh))
end

-------------------------------------------------------------------------------
--  The boxes
-------------------------------------------------------------------------------
-- Where a box's setting is: this module's, the one it names, or the profile in use.
local function On(box)
    if box.profile then return Core.Profiles.Leveling() end
    local options = box.module and Core.Settings(box.module) or ns.options
    return options[box.key] ~= false
end

local function Clicked(box)
    local on = not On(box)
    Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    if box.profile then
        Core.Profiles.SetLeveling(on)
    else
        Core.Set(box.module or ns.name, box.key, on)
        Vendor.Refresh()
    end
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

-- The tick: the game's own (checkmark-minimal), over the box.
local function Tick(parent)
    local tick = ns.Style.Texture(parent, "check", "ARTWORK")
    tick:SetPoint("CENTER", 1, 1)
    tick:SetSize(Vendor.BOX + 3, Vendor.BOX + 3)
    return tick
end

-- The box: the game's minimal checkbox, brighter under the mouse.
local function Square(parent)
    local square = ns.Style.Texture(parent, "pencil-slot", "BORDER")
    square:SetAllPoints()
    return { SetStrong = function(_, on) square:SetVertexColor(on and 1.25 or 1, on and 1.25 or 1, on and 1.25 or 1) end }
end

local function Box(foot, spec, font)
    local box = CreateFrame("CheckButton", nil, foot)
    box:SetHeight(Vendor.BOX)
    box.key, box.word, box.tip, box.module, box.profile = spec.key, spec.word, spec.tip, spec.module, spec.profile
    local square = CreateFrame("Frame", nil, box)
    square:SetSize(Vendor.BOX, Vendor.BOX)
    square:SetPoint("LEFT")
    box.pencil = Square(square)
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

-- A box's width, with its word or without.
local function Wide(box, words)
    return Vendor.BOX + (words and Vendor.WORD_GAP + (box.text:GetStringWidth() or 0) or 0)
end

function Vendor.Refresh()
    for _, box in ipairs(boxes) do
        local on = On(box)
        box:SetChecked(on)
        box.tick:SetShown(on)
        box:SetWidth(Wide(box, worded))
    end
end

function Vendor.Width(words)
    local wide = 0
    for _, box in ipairs(boxes) do wide = wide + Wide(box, words) + Vendor.APART end
    return wide
end

function Vendor.Words(on)
    worded = on
    for _, box in ipairs(boxes) do
        box.text:SetShown(on)
        box:SetWidth(Wide(box, on))
    end
end

function Vendor.Build(foot, gold)
    local font = ns.Bags.Fonts().count
    local before = gold
    for _, spec in ipairs(Vendor.BOXES) do
        if not spec.module or Core.Described(spec.module, spec.key) then
            local box = Box(foot, spec, font)
            box:SetPoint("RIGHT", before, "LEFT", -Vendor.APART, 0)
            boxes[#boxes + 1] = box
            before = box
        end
    end
    Vendor.boxes = boxes
    Vendor.Refresh()
end
