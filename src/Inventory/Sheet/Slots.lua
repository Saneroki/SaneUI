local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Slots
--  The equipment slots of our character sheet, round the model where the
--  game's sheet has them (Camelot's PaperDollFrame.xml): eight down the left
--  pane's left side, eight down its right side, the weapons along its bottom,
--  and the ammo beside them for a character that uses ammo. Each is an item
--  button (the game's ItemButton) on the game's slot frame
--  (UI-Character-Info-GearSlot): the item's icon, count and quality border, a
--  red tint while it is broken or cannot be used, grey while it is locked;
--  empty, the slot's own picture.
--
--  Its tooltip is the game's (GameTooltip:SetInventoryItem; empty, the slot's
--  name). A click picks the item up, or puts the one on the cursor there; a
--  drag the same; a modified click links it, compares it or tries it on
--  (HandleModifiedItemClick). Using an equipped item by a right click is left
--  to the game's own sheet and the action bars: that call is the game's own.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Slots = {}
ns.Slots = Slots

Slots.SIZE = 37                 -- an item button, as the game's
Slots.GAP = 6                   -- between two slots
Slots.TOP = 60                  -- the first row below the left pane's top
Slots.LEFT, Slots.RIGHT = 24, 20 -- the columns in from the left pane's sides
Slots.BOTTOM = 30               -- the weapons above the left pane's bottom
Slots.AMMO = 27                 -- the ammo slot: smaller, right of the ranged slot
Slots.AMMO_GAP = 19
Slots.RED = { 0.9, 0, 0 }       -- broken or unusable, as the game tints it

-- The slots by the game's names, in their columns.
Slots.COLUMNS = {
    left = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" },
    right = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" },
    bottom = { "MainHandSlot", "SecondaryHandSlot", "RangedSlot" },
}

local buttons = {} -- [inventory slot ID] = our button
local ammo         -- the ammo slot's button

-- A function of the game's by its name, called if this client has it.
local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function PaperDoll()
    return rawget(_G, "C_PaperDollInfo") or {}
end

-- The slot's ID, its empty picture and whether it shows a relic when empty (the game's GetInventorySlotInfo).
local function Info(name)
    local info = PaperDoll().GetInventorySlotInfo or rawget(_G, "GetInventorySlotInfo")
    return Core.Ask(info, name)
end

local function Uses(what)
    local fn = PaperDoll()[what]
    if fn then return Core.Ask(fn) end
end

-- The game's words for an empty slot ("Head", "Main Hand"), by the slot's name.
local function Named(button)
    return Core.Word(button.slot:upper(), button.slot)
end

local function Enter(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if not GameTooltip:SetInventoryItem("player", button:GetID()) then GameTooltip:SetText(Named(button)) end
    GameTooltip:Show()
end

local function Click(button, which)
    local id = button:GetID()
    if IsModifiedClick() then
        Game("HandleModifiedItemClick", Core.Ask(GetInventoryItemLink, "player", id))
    elseif which == "LeftButton" then
        Game("PickupInventoryItem", id)
    end
end

local function Drag(button)
    Game("PickupInventoryItem", button:GetID())
end

-- One slot's button, on its slot frame (atlas: the game's frame behind it; size: the button's).
local function Make(parent, name, atlas, size)
    local id, picture, relic = Info(name)
    if not id then return nil end
    local made, button = pcall(CreateFrame, "ItemButton", nil, parent)
    if not made then button = CreateFrame("Button", nil, parent, "ItemButtonTemplate") end
    button:SetSize(size, size)
    button:SetID(id)
    button.slot, button.picture, button.relic = name, picture, relic
    local back = CreateFrame("Frame", nil, button)
    back:SetPoint("CENTER")
    back:SetSize(1, 1)
    back:SetFrameLevel(math.max(0, button:GetFrameLevel() - 2))
    local frame = back:CreateTexture(nil, "BACKGROUND")
    frame:SetAtlas(atlas, true)
    frame:SetPoint("CENTER")
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnEnter", function(self) ns.Safe("character", Enter, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function(self, which) ns.Safe("character", Click, self, which) end)
    button:SetScript("OnDragStart", function(self) ns.Safe("character", Drag, self) end)
    button:SetScript("OnReceiveDrag", function(self) ns.Safe("character", Drag, self) end)
    buttons[id] = button
    return button
end

-- The buttons in their places on the left pane.
function Slots.Build(pane)
    local step = Slots.SIZE + Slots.GAP
    for index, name in ipairs(Slots.COLUMNS.left) do
        local button = Make(pane, name, "UI-Character-Info-GearSlot", Slots.SIZE)
        if button then button:SetPoint("TOPLEFT", pane, "TOPLEFT", Slots.LEFT, -Slots.TOP - (index - 1) * step) end
    end
    for index, name in ipairs(Slots.COLUMNS.right) do
        local button = Make(pane, name, "UI-Character-Info-GearSlot", Slots.SIZE)
        if button then button:SetPoint("TOPRIGHT", pane, "TOPRIGHT", -Slots.RIGHT, -Slots.TOP - (index - 1) * step) end
    end
    local before
    for _, name in ipairs(Slots.COLUMNS.bottom) do
        local button = Make(pane, name, "UI-Character-Info-GearSlot", Slots.SIZE)
        if button and before then button:SetPoint("TOPLEFT", before, "TOPRIGHT", Slots.GAP, 0) end
        before = button or before
        if name == "RangedSlot" then Slots.ranged = button elseif name == "MainHandSlot" then Slots.main = button end
    end
    ammo = Make(pane, "AmmoSlot", "UI-Character-Info-GearSlotSmall", Slots.AMMO)
    if ammo and Slots.ranged then ammo:SetPoint("LEFT", Slots.ranged, "RIGHT", Slots.AMMO_GAP, 0) end
    Slots.Place()
end

-- The weapons' row as the game places it: the ranged slot only where the game shows one; moved left to make
-- room for the ammo slot while the character uses ammo.
function Slots.Place()
    local ranged, ammoNeeded = Uses("IsRangedSlotShown"), Game("UnitUsesAmmo", "player")
    local main = Slots.main
    if main then
        main:ClearAllPoints()
        main:SetPoint("BOTTOM", main:GetParent(), "BOTTOM", (ranged and ammoNeeded) and -60 or -40, Slots.BOTTOM)
    end
    if Slots.ranged then Slots.ranged:SetShown(ranged and true or false) end
    if ammo then ammo:SetShown((ranged and ammoNeeded) and true or false) end
end

-- One slot drawn as it is now (the game's PaperDollItemSlotButton_Update, for our button).
local function Draw(button)
    local id = button:GetID()
    local texture = Core.Ask(GetInventoryItemTexture, "player", id)
    if texture then
        Game("SetItemButtonTexture", button, texture)
        Game("SetItemButtonCount", button, Core.Ask(GetInventoryItemCount, "player", id))
        local broken = Core.Ask(GetInventoryItemBroken, "player", id) or Core.Ask(rawget(_G, "GetInventoryItemEquippedUnusable"), "player", id)
        local r, g, b = 1, 1, 1
        if broken then r, g, b = Slots.RED[1], Slots.RED[2], Slots.RED[3] end
        Game("SetItemButtonTextureVertexColor", button, r, g, b)
        Game("SetItemButtonNormalTextureVertexColor", button, r, g, b)
    else
        local picture = button.picture
        if button.relic and Game("UnitHasRelicSlot", "player") then picture = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Relic.blp" end
        Game("SetItemButtonTexture", button, picture)
        Game("SetItemButtonCount", button, 0)
        Game("SetItemButtonTextureVertexColor", button, 1, 1, 1)
        Game("SetItemButtonNormalTextureVertexColor", button, 1, 1, 1)
    end
    Game("SetItemButtonQuality", button, Core.Ask(GetInventoryItemQuality, "player", id), Core.Ask(GetInventoryItemID, "player", id))
    Game("SetItemButtonDesaturated", button, Core.Ask(IsInventoryItemLocked, id) and true or false)
end

-- A slot changed (by its ID), or all of them (nil).
function Slots.Update(id)
    if id then
        local button = buttons[id]
        if button then ns.Safe("character", Draw, button) end
        return
    end
    for _, button in pairs(buttons) do ns.Safe("character", Draw, button) end
end

-- Our button for a slot ID, once built.
function Slots.Button(id)
    return buttons[id]
end
