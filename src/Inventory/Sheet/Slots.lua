local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Slots
--  The equipment slots of our character sheet, in the slots painted on the
--  doll (Doll.lua): the game's sheet's slots in its order (Camelot's
--  PaperDollFrame.xml), eight down the left, eight down the right in their
--  arcs, the weapons along the bottom, and the ammo beside them for a
--  character that uses ammo. Each is an item button (the game's ItemButton)
--  without the game's frame: the item's icon, count and quality border, a red
--  tint while it is broken or cannot be used, grey while it is locked; empty,
--  the doll's own sketch in the slot. Beside each (but the two at the top) its
--  paper strip says the item: its name in its quality's colour, the slot and
--  its item level, its two largest stats; empty, the slot's word.
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

-- One slot's button (size: the button's), without the game's frame round it: the doll's painted box is its frame.
local function Make(parent, name, size)
    local id, picture, relic = Info(name)
    if not id then return nil end
    local made, button = pcall(CreateFrame, "ItemButton", nil, parent)
    if not made then button = CreateFrame("Button", nil, parent, "ItemButtonTemplate") end
    button:SetSize(size, size)
    button:SetID(id)
    button.slot, button.picture, button.relic = name, picture, relic
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
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

-- A button in its painted slot of the doll (rect: the slot, inset: from its sides to the icon).
local function Put(pane, name, rect, inset, strip, wide)
    local x, y, w, h = ns.Doll.Rect(rect)
    local px = ns.Doll.Rect({ 0, 0, inset, 0 })
    local size = math.min(w, h) - 2 * px
    local button = Make(pane, name, size)
    if not button then return nil end
    button:SetPoint("CENTER", pane, "TOPLEFT", x + w / 2, -(y + h / 2))
    if strip then button.strip = ns.Doll.Strip(pane, strip, wide) end
    return button
end

-- The buttons in their slots on the doll.
function Slots.Build(pane)
    local Doll, inset = ns.Doll, ns.Doll.INSET
    local columns = Slots.COLUMNS
    Put(pane, columns.left[1], Doll.TOP[1], inset.top)
    Put(pane, columns.right[1], Doll.TOP[2], inset.top)
    for index = 2, #columns.left do
        local place = Doll.LEFT[index - 1]
        if place then Put(pane, columns.left[index], place[1], inset.side, place[2]) end
    end
    for index = 2, #columns.right do
        local place = Doll.RIGHT[index - 1]
        if place then Put(pane, columns.right[index], place[1], inset.side, place[2]) end
    end
    for index, name in ipairs(columns.bottom) do
        local place = Doll.WEAPONS[index]
        local button = place and Put(pane, name, place[1], inset.weapon, place[2], true)
        if name == "RangedSlot" then Slots.ranged = button elseif name == "MainHandSlot" then Slots.main = button end
    end
    ammo = Put(pane, "AmmoSlot", Doll.AMMO, inset.ammo)
    Slots.Place()
end

-- The ranged slot only where the game shows one; the ammo slot while the character uses ammo.
function Slots.Place()
    local ranged, ammoNeeded = Uses("IsRangedSlotShown"), Game("UnitUsesAmmo", "player")
    if Slots.ranged then
        Slots.ranged:SetShown(ranged and true or false)
        if Slots.ranged.strip then Slots.ranged.strip:SetShown(ranged and true or false) end
    end
    if ammo then ammo:SetShown((ranged and ammoNeeded) and true or false) end
end

-- The words on a slot's strip: the item's name in its quality's colour, the slot and its item level, its two
-- largest stats by the game's short names; empty, the slot's word.
local function Stats(link)
    local get = (rawget(_G, "C_Item") or {}).GetItemStats or rawget(_G, "GetItemStats")
    local stats = link and get and Core.Ask(get, link)
    if type(stats) ~= "table" then return "" end
    local list = {}
    for key, value in pairs(stats) do
        local word = type(key) == "string" and rawget(_G, key)
        if type(word) == "string" and type(value) == "number" and value > 0 and key:find("^ITEM_MOD_") then
            list[#list + 1] = { word = word, value = value }
        end
    end
    table.sort(list, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.word < b.word
    end)
    local parts = {}
    for i = 1, math.min(2, #list) do parts[i] = ("+%d %s"):format(list[i].value, list[i].word) end
    return table.concat(parts, "  ")
end

local function Words(button, id)
    local strip = button.strip
    if not strip then return end
    local link = Core.Ask(GetInventoryItemLink, "player", id)
    if not link then return strip:Empty(Named(button)) end
    local name, _, quality, level = Core.Ask(rawget(_G, "GetItemInfo"), link)
    local detailed = (rawget(_G, "C_Item") or {}).GetDetailedItemLevelInfo or rawget(_G, "GetDetailedItemLevelInfo")
    level = (detailed and Core.Ask(detailed, link)) or level
    local colors = rawget(_G, "ITEM_QUALITY_COLORS")
    local color = colors and quality and colors[quality]
    local line = Named(button)
    if level then line = line .. "  ·  " .. Core.Word("ITEM_LEVEL_ABBR", "iLvl") .. " " .. level end
    strip:Fill(name or link:match("%[(.-)%]") or "", color, line, Stats(link))
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
        -- empty: the doll's own sketch in its slot shows
        Game("SetItemButtonTexture", button, nil)
        Game("SetItemButtonCount", button, 0)
        Game("SetItemButtonTextureVertexColor", button, 1, 1, 1)
        Game("SetItemButtonNormalTextureVertexColor", button, 1, 1, 1)
    end
    Game("SetItemButtonQuality", button, Core.Ask(GetInventoryItemQuality, "player", id), Core.Ask(GetInventoryItemID, "player", id))
    Game("SetItemButtonDesaturated", button, Core.Ask(IsInventoryItemLocked, id) and true or false)
    Words(button, id)
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
