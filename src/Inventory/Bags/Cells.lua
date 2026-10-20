local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Cells
--  The item buttons of the bag window: the game's own
--  (ContainerFrameItemButtonTemplate, Blizzard_UIPanels_Game's
--  ContainerFrame), one per slot of a bag, made the first time that slot is
--  shown and used again in every view. Its click, drag, tooltip, the
--  splitting of a stack, selling at a vendor, putting into the bank: all the
--  template's own code, so using an item from our window is the game's own
--  click, in a fight too.
--
--  Each bag's buttons stand in a frame of ours that carries the bag's ID
--  (SetID): the template asks its parent for the bag (GetBagID, as the game's
--  bag windows always did), so the bag is never written into the button and
--  nothing of ours taints the click. The slot is the button's own ID.
--  What a button shows is drawn as the game's bag window draws it
--  (ContainerFrameMixin:UpdateItems), by the template's own functions: icon,
--  count, quality border, grey while locked, the quest mark, the glow of a new
--  item, the junk coin at a vendor (on what is junk to us: Groups.lua), the
--  cooldown; the search's dimming is the game's too (SetMatchesSearch). Ours
--  on it: the item level of gear, in its top right corner; in the list, a
--  line behind it that the button's click reaches over (its hit rect), so the
--  whole line is the item. A click the game's button does nothing with (Alt
--  and the right button) opens our menu for the item (Bags.Clicked), by a
--  hook after the button's own click.
--
--  Made out of a fight only: a slot first shown in a fight waits for its end
--  (Cells.short tells the window).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Cells = {}
ns.Cells = Cells

Cells.TEMPLATE = "ContainerFrameItemButtonTemplate"

local holders = {} -- [bag] = the frame its buttons stand in
local buttons = {} -- [bag] = { [slot] = button }
local levels = {}  -- [button] = the item level's words on it (ours, kept apart from the game's button)
local placed = {}  -- [button] = the round it was placed in
local shown = {}   -- the buttons placed, in a list (Cells.Each)
local round = 0
local parent       -- the frame the holders fill (the scroll area's child)

-- The mouse on a button, or off it: the window lights a list's line (Bags.Hover).
local function Hovered(button, on)
    if ns.Bags and ns.Bags.Hover then ns.Bags.Hover(button, on) end
end

-- A click on a button, after the game's own: the window may answer it (Bags.Clicked).
local function Clicked(button, mouse)
    if ns.Bags and ns.Bags.Clicked then ns.Bags.Clicked(button, mouse) end
end

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- A method of the template's, if this client's template has it.
local function Call(button, name, ...)
    local fn = button[name]
    if type(fn) == "function" then return fn(button, ...) end
end

function Cells.Build(child)
    parent = child
end

local function Holder(bag)
    local holder = holders[bag]
    if not holder then
        holder = CreateFrame("Frame", nil, parent)
        holder:SetID(bag)
        holder:SetAllPoints(parent)
        holders[bag] = holder
    end
    return holder
end

-- The button of a slot; made now if need be, nil in a fight for one not made yet (Cells.short is set).
function Cells.Button(bag, slot)
    local slots = buttons[bag]
    local button = slots and slots[slot]
    if button then return button end
    if InCombatLockdown() then
        Cells.short = true
        return nil
    end
    if not slots then
        slots = {}
        buttons[bag] = slots
    end
    button = CreateFrame("ItemButton", nil, Holder(bag), Cells.TEMPLATE)
    button:SetID(slot)
    local level = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    level:SetPoint("TOPRIGHT", -2, -2)
    level:Hide()
    levels[button] = level
    button:SetFrameLevel(parent:GetFrameLevel() + 3) -- above a list's line (the template sets a level of its own)
    button:HookScript("OnEnter", function(self) ns.Safe("bags", Hovered, self, true) end)
    button:HookScript("OnLeave", function(self) ns.Safe("bags", Hovered, self, false) end)
    button:HookScript("OnClick", function(self, mouse) ns.Safe("bags", Clicked, self, mouse) end)
    slots[slot] = button
    return button
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
-- A button as the record says, the game's way; dim: the search did not find it.
function Cells.Draw(button, record, dim)
    local texture = record.item and record.icon or nil
    Game("ClearItemButtonOverlay", button)
    Call(button, "SetHasItem", texture)
    Game("SetItemButtonTexture", button, texture)
    Game("SetItemButtonQuality", button, record.quality, record.link, false, record.bound)
    Game("SetItemButtonCount", button, record.item and record.count or 0)
    Game("SetItemButtonDesaturated", button, record.locked)
    Call(button, "UpdateExtended")
    Call(button, "UpdateQuestItem", record.quest, record.questID, record.questActive)
    Call(button, "UpdateNewItem", record.quality)
    -- The vendor's coin on what is junk to us (marked, or grey and not unmarked), not on every grey item.
    Call(button, "UpdateJunkItem", record.junk and ns.Contents.POOR or nil, record.worthless)
    Call(button, "UpdateItemContextMatching")
    Call(button, "UpdateCooldown", texture)
    Call(button, "SetReadable", record.readable)
    local tip = rawget(_G, "GameTooltip")
    if tip then Call(button, "CheckUpdateTooltip", tip:GetOwner()) end
    Call(button, "SetMatchesSearch", not dim)
    local level = levels[button]
    if record.level then
        local color = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[record.quality]
        level:SetText(record.level)
        if color then level:SetTextColor(color.r, color.g, color.b) else level:SetTextColor(1, 1, 1) end
        level:Show()
    else
        level:Hide()
    end
end

-- A cell for a kind of bag's free slots: that kind's first free slot, with how many there are.
function Cells.DrawFree(button, record, entry)
    Cells.Draw(button, record, false)
    Game("SetItemButtonCount", button, entry.count)
end

-- One slot's lock changed (an item picked up or put down): grey or not, as the game shows it.
function Cells.Lock(record)
    local slots = buttons[record.bag]
    local button = slots and slots[record.slot]
    if button and placed[button] == round then Game("SetItemButtonDesaturated", button, record.locked) end
end

-- The cooldowns of the buttons shown, anew.
function Cells.Cooldowns()
    for _, button in ipairs(shown) do
        local api = rawget(_G, "C_Container")
        local holder = button:GetParent()
        local has = api and api.HasContainerItem and Core.Ask(api.HasContainerItem, holder:GetID(), button:GetID())
        Call(button, "UpdateCooldown", has)
    end
end

-- The buttons of one bag lit (the game's mark for a bag's items, as its combined bag does while the mouse is on
-- a bag of the bag bar); nil: none.
function Cells.Light(bag)
    for _, button in ipairs(shown) do
        local mark = button.BagIndicator
        if mark and mark.SetShown then mark:SetShown(bag ~= nil and button:GetParent():GetID() == bag) end
    end
end

-------------------------------------------------------------------------------
--  Placing
-------------------------------------------------------------------------------
-- A new round of placing: what is not placed in it goes out of sight at Done.
function Cells.Begin()
    round = round + 1
    for index = #shown, 1, -1 do shown[index] = nil end
    Cells.short = false
end

-- A button at its place in the parent (its top left, x right and y down), at that scale; row: the width of a
-- list's line its click reaches over (nil: only the button).
function Cells.Place(button, x, y, scale, row)
    button:SetScale(scale)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x / scale, -y / scale)
    local reach = row and (row - ns.Layout.SIZE * scale) / scale or 0
    button:SetHitRectInsets(0, -reach, 0, 0)
    button:Show()
    if placed[button] ~= round then shown[#shown + 1] = button end
    placed[button] = round
end

function Cells.Done()
    for _, slots in pairs(buttons) do
        for _, button in pairs(slots) do
            if placed[button] ~= round and button:IsShown() then
                button:Hide()
                local mark = button.BagIndicator
                if mark and mark.Hide then mark:Hide() end
            end
        end
    end
end

-- The buttons placed in this round, in their order.
function Cells.Each()
    return shown
end

-- Whether a slot's button stands in the window now.
function Cells.Shown(bag, slot)
    local slots = buttons[bag]
    local button = slots and slots[slot]
    return button ~= nil and placed[button] == round and button:IsShown()
end

-- Every button out of sight (the module stood down, or the panel hidden).
function Cells.HideAll()
    round = round + 1
    for index = #shown, 1, -1 do shown[index] = nil end
    Cells.Done()
end
