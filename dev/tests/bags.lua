-- Runs the Inventory module's bags against the stand-in client (wowstub.lua): what the bags hold, read from a
-- stand-in of the game's containers; the categories (the built-in rules, the player's own, groups, pins, junk
-- marks, renamed, moved, switched off, hidden) without a frame; what came in lately; the views (All Items, One
-- Bag, Each Bag, a category, a group) as blocks, stacks merged, the search; the three displays laid out as plain
-- numbers; the window: its bar, the sidebar, the game's item buttons in the flat look, the menus and drops, the
-- dropdown View; the game's events while shown; the bank while it is open; the foot and the bags' strip; selling
-- junk; Auto Sell and Auto Repair. The window, the board and the other parts are tried in dev/tests/inventory.lua. The look can only be
-- judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/bags.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client (as dev/tests/inventory.lua)
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:Raise() self._level = 500 end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetColorTexture(r, g, b, a) self._colorTexture = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
function methods:SetHitRectInsets(left, right, top, bottom) self._hit = { left, right, top, bottom } end
function methods:SetRotation(radians) self._rotation = radians end
function methods:SetTexCoord(...) self._coords = { ... } end
function methods:SetDesaturated(on) self._grey = on end
function methods:SetFont(file, size, flags) self._font = { file, size, flags } end
function methods:GetStringWidth() return #(self._text or "") * 6 end
function methods:GetTextWidth() return #(self._text or "") * 6 end
function methods:SetVerticalScroll(value) self._scrolled = value end
function methods:GetVerticalScroll() return self._scrolled or 0 end
function methods:IsTruncated() return false end
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, progress = 0 }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress = true, 0 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha = noop
    function group:CreateAnimation()
        local animation = setmetatable({ SetSmoothing = noop, SetToAlpha = noop }, { __index = function() return noop end })
        function animation:SetDuration(seconds) group.duration = seconds end
        function animation:GetProgress() return group.progress end
        function animation:GetSmoothProgress() return group.progress end
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate and self.scripts.OnUpdate() end
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished() end
    end
    self._group = self._group or group
    return group
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
function methods:SetID(id) self._id = id end
function methods:GetID() return self._id end
function methods:SetFormattedText(format, ...) self._text = format:format(...) end

-- The game's splitter: its item button opens it for a Shift-click on a stack, but not where that click linked the
-- item into the chat (chatOpen) or something is on the cursor.
StackSplitFrame = W.NewWidget("Frame", "StackSplitFrame", UIParent)
StackSplitFrame._shown = false
local chatOpen = false

-- The game's item button for a bag's slot (ContainerFrameItemButtonTemplate): its marks and parts, and what its
-- own functions were told.
W.templates.ContainerFrameItemButtonTemplate = function(widget)
    widget.BagIndicator = W.NewWidget("Texture", nil, widget)
    widget.BagIndicator._shown = false
    widget.icon = W.NewWidget("Texture", nil, widget)
    widget.Count = W.NewWidget("FontString", nil, widget)
    widget._template = "ContainerFrameItemButtonTemplate"
    widget._shown = false -- hidden="true", as the game's template is
    widget._scripts.OnClick = function(self, mouse)
        if mouse ~= "LeftButton" or not IsModifiedClick("SPLITSTACK") then return end
        if chatOpen then
            W.links[#W.links + 1] = "item"
            return
        end
        local info = C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID())
        if info and info.stackCount > 1 and not CursorHasItem() then
            StackSplitFrame.owner = self
            StackSplitFrame:Show()
        end
    end
    function widget:SetHasItem(texture) self._has = texture end
    function widget:UpdateQuestItem(quest, id) self._questDrawn = quest or id or false end
end
W.templates.ScrollFrameTemplate = function(widget) widget.ScrollBar = W.NewWidget("Frame", nil, widget) end
function methods:OverrideText(text) self._override = text end

-------------------------------------------------------------------------------
--  The game's bags, a stand-in
-------------------------------------------------------------------------------
Constants = { InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 } }
Enum.BagIndex = { Keyring = -1, Backpack = 0 }
Enum.ItemClass = { Consumable = 0, Container = 1, Weapon = 2, Gem = 3, Armor = 4, Reagent = 5, Projectile = 6,
                   Tradegoods = 7, ItemEnhancement = 8, Recipe = 9, Quiver = 11, Questitem = 12, Key = 13, Miscellaneous = 15 }
Enum.ItemQuality = { Poor = 0, Common = 1, Uncommon = 2, Rare = 3 }
Enum.ItemBind = { None = 0, OnAcquire = 1, OnEquip = 2, OnUse = 3 }
Enum.BankType = { Character = 0, Account = 2 }
Enum.PlayerInteractionType = { Merchant = 5, Banker = 8 }
ITEM_QUALITY_COLORS = { [0] = { r = 0.6, g = 0.6, b = 0.6 }, [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.1, g = 1, b = 0 },
                        [3] = { r = 0, g = 0.4, b = 1 } }

local SIZES = { [0] = 16, [1] = 8, [2] = 4, [3] = 0, [4] = 0, [5] = 4, [-1] = 4 }
local FAMILY = { [2] = 1 } -- bag 2 is a quiver
-- [item] = { name, class, quality, level, equip, price, bind }
local ITEMS = {
    [2001] = { "Steel Sword", 2, 3, 20, "INVTYPE_WEAPON", 500, 2 }, [2589] = { "Linen Cloth", 7, 1, nil, "", 10 },
    [118] = { "Minor Healing Potion", 0, 1, nil, "", 5 }, [3001] = { "Broken Fang", 15, 0, nil, "", 3 },
    [3002] = { "Wolf Pelt", 12, 1 }, [4001] = { "Shiny Ring", 4, 2, 12, "INVTYPE_FINGER", 90, 2 },
    [2512] = { "Rough Arrow", 6, 1 }, [2447] = { "Peacebloom", 7, 1 }, [5001] = { "Cellar Key", 13, 1 },
    [6001] = { "Silver Bar", 7, 2 }, [7001] = { "Iron Ore", 7, 1, nil, "", 8 },
    [4002] = { "Lucky Charm", 4, 2, 15, "INVTYPE_TRINKET", 70, 2 }, [279978] = { "Camp Tent", 15, 1 },
    [8001] = { "Plate Helm", 4, 2, 18, "INVTYPE_HEAD", 120, 1 },
}
local bags = {} -- [bag] = { [slot] = { item, count, locked, new, quest, bound, unusable } }
local function Put(bag, slot, item, count, extra)
    bags[bag] = bags[bag] or {}
    local entry = { item = item, count = count or 1 }
    for key, value in pairs(extra or {}) do entry[key] = value end
    bags[bag][slot] = entry
end
Put(0, 1, 2001)
Put(0, 2, 2589, 20)
Put(0, 3, 118, 5)
Put(0, 4, 3001)
Put(0, 5, 3002, 1, { quest = true })
Put(1, 1, 2589, 7)
Put(1, 2, 4001, 1, { new = true })
Put(2, 1, 2512, 200)
Put(5, 1, 2447, 4)
Put(-1, 1, 5001)
local bankOpen, merchantOpen = false, false
local calls = {}
local function Slot(bag, slot) return bags[bag] and bags[bag][slot] end
local function Size(bag)
    if bag >= 6 and not bankOpen then return 0 end
    return SIZES[bag] or 0
end
local function Link(item) return "|cffffffff|Hitem:" .. item .. "|h[" .. ITEMS[item][1] .. "]|h|r" end
C_Container = {
    GetContainerNumSlots = function(bag) return Size(bag) end,
    GetContainerItemInfo = function(bag, slot)
        local entry = Slot(bag, slot)
        if not entry or slot > Size(bag) then return nil end
        local item = ITEMS[entry.item]
        return { itemID = entry.item, stackCount = entry.count, quality = item[3], iconFileID = "icon" .. entry.item,
                 hyperlink = Link(entry.item), itemName = item[1], isLocked = entry.locked or false,
                 isBound = entry.bound or false, hasNoValue = false, isReadable = false }
    end,
    GetContainerItemQuestInfo = function(bag, slot)
        local entry = Slot(bag, slot)
        return { isQuestItem = entry and entry.quest or false, isActive = false }
    end,
    GetContainerNumFreeSlots = function(bag)
        local free = 0
        for slot = 1, Size(bag) do if not Slot(bag, slot) then free = free + 1 end end
        return free, FAMILY[bag] or 0
    end,
    GetBagName = function(bag) return ({ [1] = "Small Pouch", [2] = "Quiver", [5] = "Herb Pouch" })[bag] or ("Bag " .. bag) end,
    ContainerIDToInventoryID = function(bag) return 30 + bag end,
    HasContainerItem = function(bag, slot) return Slot(bag, slot) ~= nil end,
    SortBags = function() calls.sortBags = (calls.sortBags or 0) + 1 end,
    SortBank = function(kind) calls.sortBank = kind end,
}
C_NewItems = { IsNewItem = function(bag, slot) local entry = Slot(bag, slot) return entry and entry.new or false end }
local function ID(item) return type(item) == "number" and item or tonumber(tostring(item):match("item:(%d+)")) end
C_Item = {
    GetItemInfoInstant = function(item)
        local info = ITEMS[ID(item)]
        return ID(item), "type", "subtype", info[5] or "", "icon", info[2], 0
    end,
    GetDetailedItemLevelInfo = function(link)
        local item = ID(link)
        return ITEMS[item] and ITEMS[item][4]
    end,
    GetItemInfo = function(item)
        local id = ID(item)
        local info = ITEMS[id]
        return info[1], Link(id), info[3], info[4], 1, "Type" .. info[2], "Sub" .. info[2], 20, info[5] or "",
            "icon" .. id, info[6] or 0, info[2], 0, info[7] or 0
    end,
}
C_TooltipInfo = { GetBagItem = function(bag, slot)
    local entry = Slot(bag, slot)
    if entry and entry.unusable then return { lines = { { leftText = "Plate", leftColor = { r = 1, g = 0.1, b = 0.1 } } } } end
    return { lines = { { leftText = ITEMS[entry.item][1], leftColor = { r = 1, g = 1, b = 1 } } } }
end }
-- One equipment set, Tank, with the sword in the backpack's first slot.
C_EquipmentSet = {
    GetEquipmentSetIDs = function() return { 1 } end,
    GetEquipmentSetInfo = function() return "Tank" end,
    GetItemLocations = function() return { [16] = 1001 } end,
}
-- The set's sword where it is now (the game's locations follow the item).
EquipmentManager_GetLocationData = function(location)
    if location ~= 1001 then return {} end
    for bag, list in pairs(bags) do
        for slot, entry in pairs(list) do
            if entry.item == 2001 then return { isBags = true, bag = bag, slot = slot } end
        end
    end
    return {}
end
-- The character's bank: one tab, Ores; another for sale. Its settings changed by the game's call.
local tabs = { [0] = { { ID = 6, name = "Ores", icon = "tab-icon", depositFlags = 0 } } }
C_Bank = {
    FetchPurchasedBankTabIDs = function(kind)
        local ids = {}
        for index, data in ipairs(tabs[kind] or {}) do ids[index] = data.ID end
        return ids
    end,
    FetchPurchasedBankTabData = function(kind) return tabs[kind] or {} end,
    CanViewBank = function() return true end,
    DoesBankTypeSupportAutoDeposit = function(kind) return kind == 0 end,
    AutoDepositItemsIntoBank = function(kind) calls.deposit = kind end,
    UpdateBankTabSettings = function(kind, tab, name, icon, flags)
        calls.tabSettings = { kind, tab, name, icon, flags }
        local data = tabs[kind][1]
        data.name, data.icon, data.depositFlags = name, icon, flags
    end,
    CanPurchaseBankTab = function(kind) return kind == 0 end,
    HasMaxBankTabs = function() return false end,
    FetchNextPurchasableBankTabData = function() return { tabCost = 50000, canAfford = false } end,
    PurchaseBankTab = function() calls.bought = true end,
}
Enum.BagSlotFlags = { DisableAutoSort = 1, ClassEquipment = 2, ClassConsumables = 4, ClassProfessionGoods = 8,
                      ClassJunk = 16, ClassReagents = 128 }
-- The game's button for buying a tab: its own click opens the game's question (here: noted).
W.templates.BankPanelPurchaseButtonScriptTemplate = function(widget)
    widget._scripts.OnClick = function(self) calls.purchase = self:GetAttribute("overrideBankType") end
end
SIZES[6] = 8
Put(6, 1, 6001, 3)
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
    return kind == 8 and bankOpen or kind == 5 and merchantOpen end }
C_MerchantFrame = { SellAllJunkItems = function() calls.sold = true end, IsSellAllJunkEnabled = function() return true end }
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end,
                   GetBackpackCurrencyInfo = function(index) if index == 1 then return { quantity = 12, iconFileID = "honor" } end end }
GetMoney = function() return 12345 end
local shop = { repairs = {}, cost = 250, can = true, repairer = true, shift = false } -- the vendor, and Shift
CanMerchantRepair = function() return shop.repairer end
GetRepairAllCost = function() return shop.cost, shop.can end
RepairAllItems = function(guild) shop.repairs[#shop.repairs + 1] = guild or "own" end
IsShiftKeyDown = function() return shop.shift end
local cursor = false
CursorHasItem = function() return cursor end
local holding
GetCursorInfo = function() if holding then return "item", holding, "link" end end
ClearCursor = function() holding = nil end
local alt = false
IsAltKeyDown = function() return alt end
PickupBagFromSlot = function(slot) calls.pickedBag = slot end
PutItemInBag = function(slot) calls.putBag = slot end
PutItemInBackpack = function() calls.putBackpack = true end
GetInventoryItemTexture = function(_, slot) return slot == 31 and "bag-icon" or nil end
GetInventoryItemID = function() return nil end
C_PaperDollInfo = { GetInventorySlotInfo = function() return 20, "empty-bag" end }
local drawn = setmetatable({}, { __index = function(t, button) t[button] = {} return t[button] end })
SetItemButtonTexture = function(button, texture) drawn[button].texture = texture end
SetItemButtonCount = function(button, count) drawn[button].count = count end
SetItemButtonQuality = function(button, quality) drawn[button].quality = quality end
SetItemButtonDesaturated = function(button, on) drawn[button].grey = on end
ClearItemButtonOverlay = function() end
SOUNDKIT = { UI_BAG_SORTING_01 = 1 }
PlaySound = function() end

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Inventory", "SaneUI_Inventory")
W.Fire("ADDON_LOADED", "SaneUI_Inventory")
-- Loot and Speed Leveling, as far as their boxes in the foot need them: that they are there, Loot's switch.
Core.Options("SpeedLeveling", { { key = "take", default = false, text = "Take" } })
Core.Options("Loot", { { key = "full", default = true, text = "Make room for loot" } },
    { changed = function() Core.SwitchChanged() end })
-- Only the bags on the full screen: the other parts are tried elsewhere.
ns.store.board = { chosen = 1, tabs = { { name = "Default", tree = { key = "bags" } } } }
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")
local Contents, Layout, Cells, Bags, Foot = ns.Contents, ns.Layout, ns.Cells, ns.Bags, ns.Foot
local Categories, Views, Recent, Sidebar = ns.Categories, ns.Views, ns.Recent, ns.BagSidebar

-- A vendor before the bags' window was ever built: Auto Sell and Auto Repair do their work all the same.
merchantOpen = true
W.Fire("MERCHANT_SHOW")
W.Wait(0)
check(not ns.Vendor.boxes and calls.sold and #shop.repairs == 0, "at a vendor, the bags never opened: the junk sold, unasked")
W.Wait(Foot.SOLD)
check(#shop.repairs == 1, "then the repair")
merchantOpen = false
W.Fire("MERCHANT_CLOSED")
calls.sold, shop.repairs = nil, {}

-------------------------------------------------------------------------------
--  What the bags hold, without a frame
-------------------------------------------------------------------------------
local kept = {}
Categories.Use(kept)
local carried = Contents.Carried({})
check(table.concat(carried, ",") == "0,1,2,5,-1", "the bags carried: the backpack, the bags with slots, the reagent bag, the keyring")
Contents.Sets()
local slots, free = Contents.Scan(carried, "bags", {}, Contents.ClearFree({}))
check(#slots == 36, "every slot read")
local sword, linen, potion, fang, pelt = slots[1], slots[2], slots[3], slots[4], slots[5]
local linen2, ring, arrows = slots[17], slots[18], slots[25]
local herb, key = slots[29], slots[33]
check(sword.name == "Steel Sword" and sword.level == 20 and sword.boe and sword.sell == 500 and sword.set == "Tank",
    "an item: its name, item level, binds when equipped, its price, the equipment set it is in")
check(linen.count == 20 and not linen.level and not linen.boe, "a trade good: no item level, no BoE")
check(free.count == 17 and free.total == 24 and table.concat(free.kinds, ",") == "bags,2,5,-1",
    "the free slots by kind: the ordinary bags together, the quiver, the reagent bag, the keyring each by itself")
check(free[2].count == 3 and free[2].bag == 2 and free[2].slot == 2, "a kind's free slots and its first free one")
check(arrows.special and herb.reagentBag and key.special and not sword.special, "the special bags and the reagent bag known")

-------------------------------------------------------------------------------
--  The categories, without a frame
-------------------------------------------------------------------------------
check(sword.category == "sets" and ring.category == "finger" and linen.category == "trade" and potion.category == "consumables",
    "set gear, a ring in Rings (gear by its slot), trade goods, consumables")
check(fang.category == "junk" and fang.junk and pelt.category == "misc" and arrows.category == "special"
    and herb.category == "reagent" and key.category == "special",
    "grey: junk; a quest item in Miscellaneous while Quest Items is off; the special bags' and the reagent bag's")
check(table.concat(Categories.order, ",") ==
    "pinned,recent,head,neck,shoulder,back,chest,wrist,hands,waist,legs,feet,finger,trinket,weapons,offhand,ranged,armor,sets,"
    .. "potions,enhance,camp,consumables,trade,professions,containers,reagent,misc,quest,special,junk",
    "the first order: Pinned and Recent first, Junk last")
check(Categories.GroupOf("weapons") == "armory" and Categories.GroupOf("sets") == "armory" and Categories.GroupOf("consumables") == "prep"
    and Categories.GroupWord("armory") == "The Armory", "the first groups: The Armory, Consumables")
local function Reclassify()
    for _, record in ipairs(slots) do if record.item then Categories.Classify(record) end end
end
-- The rules beyond the class.
Put(0, 6, 4002)
Put(0, 7, 279978)
local charm = Contents.Read(0, 6, "bags")
local tent = Contents.Read(0, 7, "bags")
check(charm.category == "trinket" and tent.category == "camp", "a trinket in Trinkets, a camp item in Camp Items")
local function Kind(class, subclass, equip)
    return Categories.Classify({ item = 99999, class = class, subclass = subclass, equip = equip })
end
check(Kind(0, 1) == "potions" and Kind(0, 2) == "enhance" and Kind(0, 3) == "enhance" and Kind(0, 4) == "enhance"
    and Kind(3, 0) == "enhance" and Kind(0, 5) == "consumables" and Kind(0, 7) == "consumables",
    "consumables by kind: potions; elixirs, flasks, scrolls and gems are buffs; food and bandages the rest")
check(Kind(1, 0) == "containers" and Kind(11, 2) == "containers" and Categories.Word("containers") == "Containers"
    and Categories.Takes("containers"), "bags and quivers lying in the bags in Containers, which takes what is put into it")
check(Categories.Classify({ item = 99998, class = 15, subclass = 0, loot = true }) == "containers"
    and Categories.Word("special") == "Special Bags" and not Categories.Takes("special"),
    "what a right click opens in Containers too; what lies in a worn special bag in Special Bags, as before")
check(Kind(4, 1, "INVTYPE_HEAD") == "head" and Kind(2, 7, "INVTYPE_SHIELD") == "offhand" and Kind(2, 2, "INVTYPE_RANGEDRIGHT") == "ranged"
    and Kind(4, 0, "INVTYPE_BODY") == "armor" and Kind(4, 1, "INVTYPE_ROBE") == "chest",
    "gear by its slot; a shirt with the other gear")
bags[0][6], bags[0][7] = nil, nil
Contents.Read(0, 6, "bags")
Contents.Read(0, 7, "bags")
-- An item the game does not know yet: its record keeps nothing of the one that lay there before, and who can use it
-- is not asked; once known it is. After a level-up (the bags hidden or not) that is asked anew.
local GetItemInfo = C_Item.GetItemInfo
Put(0, 8, 8001, 1, { unusable = true })
local helm = Contents.Scan({ 0 }, "bags", {}, Contents.ClearFree({}))[8]
check(helm.unusable and helm.sell == 120 and helm.bind == 1, "plate the character cannot wear: marked")
W.level = 2
C_Item.GetItemInfo = function(item) if ID(item) ~= 4002 then return GetItemInfo(item) end end
Put(0, 8, 4002, 1, { unusable = true })
Contents.Scan({ 0 }, "bags", {}, Contents.ClearFree({}))
check(not helm.unusable and helm.sell == nil and helm.bind == nil and helm.stack == nil and helm.subName == nil
    and Contents.waiting[4002], "another item there, not known yet: nothing of the one before, nothing asked, waited for")
C_Item.GetItemInfo = GetItemInfo
Contents.Read(0, 8, "bags")
check(helm.unusable and helm.sell == 70 and not Contents.waiting[4002], "known now: asked, marked, no longer waited for")
bags[0][8].unusable = false
W.level = 3
Contents.Scan({ 0 }, "bags", {}, Contents.ClearFree({}))
check(not helm.unusable, "a level later, the bags hidden meanwhile: asked anew")
W.level = 1
bags[0][8] = nil
Contents.Scan({ 0 }, "bags", {}, Contents.ClearFree({}))
Categories.SwitchOff("quest", false)
Reclassify()
check(pelt.category == "quest", "Quest Items switched on: the quest item there")
Categories.SwitchOff("consumables", true)
Reclassify()
check(potion.category == "misc" and Categories.Off("consumables"), "a category switched off: its items in Miscellaneous")
Categories.SwitchOff("consumables", false)
Categories.SwitchOff("quest", true)
Reclassify()
-- Pins, assignments, junk marks.
Categories.Pin(118, true)
Reclassify()
check(potion.pinned and potion.category == "consumables", "pinned: still in its own category")
Categories.Assign(118, "trade")
Reclassify()
check(potion.category == "trade", "put into another category")
Categories.MarkJunk(118, true)
Reclassify()
check(potion.category == "junk" and not potion.junk, "marked as junk (pinned: not sold)")
Categories.Pin(118, false)
Reclassify()
check(potion.junk, "unpinned: junk to sell")
Categories.MarkJunk(118, false)
Reclassify()
check(potion.category == "trade", "unmarked: back in the category it was put into before")
Categories.Assign(118, nil)
Reclassify()
check(potion.category == "consumables", "taken out: where the rules put it")
-- The player's own categories, groups, names, order.
local own = Categories.New("Tonics")
check(own == "own1" and Categories.Word(own) == "Tonics" and Categories.Own(own)
    and Categories.rank[own] == Categories.rank.misc - 1, "a category of the player's own, made before Miscellaneous")
do
    local spare = Categories.New("Spare", Categories.OWN_ICON)
    check(Categories.Icon(own) == Categories.ART .. "own" and Categories.Icon(spare) == Categories.ART .. "own",
        "a category of the player's own without an icon chosen: the pencil drawing for it")
    Categories.Delete(spare)
end
Categories.Assign(118, own)
Reclassify()
check(potion.category == own, "an item put into it")
Categories.Rename("trade", "Cloth")
check(Categories.Word("trade") == "Cloth", "a category renamed")
Categories.Rename("trade", "")
check(Categories.Word("trade") == "Trade Goods", "no name: its own again")
local before = Categories.rank.trade
Categories.Move("trade", 1)
check(Categories.rank.trade == before + 1 and kept.order[1] == "head", "moved down one, the order kept")
Categories.Move("trade", -1)
-- A group moves as one; a category passes a whole group in one step; a group's member moves among its members.
local ARMORY = "head,neck,shoulder,back,chest,wrist,hands,waist,legs,feet,finger,trinket,weapons,offhand,ranged,armor,sets"
local PREP = "potions,enhance,camp,consumables"
Categories.MoveGroup("armory", 1)
check(table.concat(kept.order, ",", 1, 21) == PREP .. "," .. ARMORY,
    "a group moved down: past the next group, its members together")
Categories.Move("trade", -1)
check(table.concat(kept.order, ",", 1, 22) == PREP .. ",trade," .. ARMORY,
    "a category moved up: past a whole group at once")
Categories.Move("armor", -1)
Categories.Move("armor", -1)
check(Categories.rank.armor == Categories.rank.weapons + 1 and Categories.rank.offhand == Categories.rank.armor + 1
    and Categories.GroupOf("armor") == "armory", "a group's member moved among its members, never out of its group")
Categories.Move("head", -1)
check(kept.order[6] == "head" and Categories.GroupOf("head") == "armory", "the first member stays first: never out of its group")
-- What is switched off (not in the sidebar) is stepped over: every move moves something seen.
Categories.SwitchOff("professions", true)
Categories.Move("containers", -1)
check(table.concat(kept.order, ",", 5, 8) == "trade,containers,professions,head",
    "a category moved up past one switched off: past the group before that at once")
Categories.SwitchOff("weapons", true)
Categories.Move("armor", 1)
check(Categories.rank.armor == Categories.rank.offhand + 1, "a group's member past a member switched off")
Categories.SwitchOff("professions", false)
Categories.SwitchOff("weapons", false)
kept.order = nil
Categories.Order()
local group = Categories.GroupWith("trade", own)
check(Categories.GroupOf("trade") == group and Categories.GroupOf(own) == group and Categories.GroupWord(group) == "Trade Goods & Tonics",
    "two categories made a group, named by its members")
Categories.Join("professions", group)
check(Categories.GroupWord(group) == "Trade Goods, Tonics, & Professions", "a third joins it")
Categories.RenameGroup(group, "Crafting")
check(Categories.GroupWord(group) == "Crafting", "the group named")
Categories.Ungroup("professions")
Categories.Ungroup(own)
check(Categories.GroupOf("trade") == nil, "a group left with one member is no group")
Categories.Disband(group)
Categories.Disband("armory")
check(Categories.GroupOf("weapons") == nil and Categories.GroupOf("armor") == nil, "a group disbanded")
Categories.Hide("misc", true)
check(Categories.Hidden("misc"), "hidden from All Items")
Categories.Delete(own)
Reclassify()
check(not Categories.rank[own] and potion.category == "consumables" and kept.assigned[118] == nil,
    "deleted: its items back where the rules put them")
-- What is kept is never trusted.
local wrong = { assigned = { [5] = "nowhere", x = "trade", [6] = "reagent" }, pinned = { [7] = "yes" }, own = { { key = "bad" }, 3 },
    order = { "junk", "trade", "trade", 12 }, words = { trade = 4 }, member = { trade = 9 }, off = { quest = "no" } }
Categories.Check(wrong)
check(next(wrong.assigned) == nil and next(wrong.pinned) == nil and #wrong.own == 0 and table.concat(wrong.order, ",") == "trade"
    and next(wrong.words) == nil and next(wrong.member) == nil and next(wrong.off) == nil,
    "what is kept that is not of the right kind goes")
-- Dragged in the sidebar: a category to another place (into a group or out of it), a group as a whole.
for k in pairs(kept) do kept[k] = nil end
Categories.Use(kept)
local rank, order = Categories.rank, Categories.order
Categories.Place("professions", "head", false)
check(rank.professions == rank.head - 1 and Categories.GroupOf("professions") == nil and kept.order[1] == "professions",
    "a category put before another, the order kept")
Categories.Place("professions", "armor", true, "armory")
check(Categories.GroupOf("professions") == "armory" and rank.professions == rank.armor + 1,
    "put between a group's members: in that group")
Categories.Place("weapons", nil, true)
check(Categories.GroupOf("weapons") == nil and order[#order] == "junk" and order[#order - 1] == "weapons",
    "to the end: before Junk, out of its group")
Categories.PlaceGroup("prep", "armor", false)
check(rank.consumables < rank.armor and rank.potions < rank.armor and rank.consumables == rank.potions + 3
    and Categories.GroupOf("enhance") == "prep", "a group moved as a whole")
Categories.Place("junk", "weapons", false)
Categories.Place("pinned", nil, true)
check(order[1] == "pinned" and order[2] == "recent" and order[#order] == "junk", "Pinned, Recent and Junk never move")
Categories.Place("reagent", "armor", false, "armory")
check(Categories.GroupOf("reagent") == nil and rank.reagent == rank.armor - 1, "one that is never in a group stays in none")
-- Back to the first state for what follows.
for k in pairs(kept) do kept[k] = nil end
Categories.Use(kept)
Reclassify()

-------------------------------------------------------------------------------
--  What came in lately
-------------------------------------------------------------------------------
check(#Recent.list == 0, "at the login nothing is new")
Put(0, 6, 7001, 2)
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Recent.list[1] == 7001, "an item that came in: recent")
bags[0][2].count = 25
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Recent.list[1] == 2589 and Recent.list[2] == 7001, "more of an item: recent too, newest first")
bags[0][2].count = 20
W.Fire("BANKFRAME_OPENED")
bags[0][3].count = 9
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Recent.list[1] == 2589, "at the bank nothing counts")
W.Fire("BANKFRAME_CLOSED")
W.Wait(Recent.SETTLE)
check(Recent.list[1] == 2589 and not Recent.Has(118), "after it closes the counts are taken anew, without anything new")
bags[0][3].count = 5
Recent.Clear()
bags[0][6] = nil
Recent.Take(false)

-------------------------------------------------------------------------------
--  The views, without a frame
-------------------------------------------------------------------------------
slots, free = Contents.Scan(carried, "bags", {}, Contents.ClearFree({}))
local section = { place = "bags", slots = slots, free = free }
local options = {}
local function Words(blocks)
    local list = {}
    for index = 1, blocks.count do
        local block = blocks[index]
        list[#list + 1] = (block.word or "?") .. "=" .. #block.entries
    end
    return table.concat(list, ",")
end
local blocks = Views.Build("all", { section }, nil, "default", options)
check(Words(blocks) == "Pinned Items=0,The Armory=0,Rings=1,Item Set Gear=1,?=0,Consumables=0,Food=1,?=0,Trade Goods=1,"
    .. "Professions=0,Containers=0,Reagent Bag=1,Miscellaneous=1,Quest Items=0,Special Bags=2,Junk=1",
    "All Items: Pinned (with its +, empty too), a block per category, a group's title over its members that hold "
    .. "something, the empty categories shown too (a slot to drop into): " .. Words(blocks))
check(blocks[1].plus and blocks[9].plus and blocks[9].key == "trade" and not blocks[12].plus and blocks[2].title
    and not blocks[2].plus and blocks[2].number == 2 and not blocks[3].plus and blocks[3].level == 3 and blocks[3].key == "finger"
    and blocks[5].bare and blocks[5].plus and blocks[5].drop == "group:armory",
    "a + after Pinned and after a category that takes items; a group divided: one + for the whole group after its "
    .. "members (a bare block), none on each member; not after the reagent bag's (a group's count: its members')")
Categories.Divide("armory", false)
blocks = Views.Build("all", { section }, nil, "default", options)
check(Words(blocks):find("^Pinned Items=0,The Armory=2,Consumables=0,") and blocks[2].group == "armory" and blocks[2].plus
    and blocks[2].drop == "group:armory" and not Categories.Divided("armory"),
    "a group whole: one block of its members' items, one +")
Categories.Divide("armory", true)
blocks = Views.Build("all", { section }, nil, "default", options)
local function Named(list, word)
    for index = 1, list.count do
        if list[index].word == word then return list[index] end
    end
end
local trade = Named(blocks, "Trade Goods")
check(trade.entries[1].count == 27 and trade.number == 1, "the stacks of one item merged into one cell, the count of them all")
check(Named(blocks, "Item Set Gear").entries[1].record.name == "Steel Sword" and Named(blocks, "The Armory").group == "armory",
    "a group's title, its members' blocks under it")
options.merge = false
blocks = Views.Build("all", { section }, nil, "default", options)
check(#Named(blocks, "Trade Goods").entries == 2, "stacks not merged when the player says so")
options.merge = nil
Categories.Pin(2589, true)
Reclassify()
Recent.list[1] = 118
blocks = Views.Build("all", { section }, nil, "default", options)
check(blocks[1].word == "Pinned Items" and #blocks[1].entries == 1 and blocks[2].word == "Recent Items" and blocks[3].word == "The Armory",
    "Pinned and Recent first")
check(#Named(blocks, "Trade Goods").entries == 0 and (Views.Counts(section, options).trade or 0) == 0
    and Views.Counts(section, options).pinned == 1, "a pinned item only under Pinned, not in its own category too")
check(#Named(Views.Build("all", { section }, nil, "default", { showPinned = false }), "Trade Goods").entries == 1,
    "Pinned not shown: the pinned item in its own category")
blocks = Views.Build("all", { section }, nil, "default", options)
Categories.Pin(2589, false)
Reclassify()
Recent.Clear()
blocks = Views.Build("all", { section }, Core.Fuzzy.Query("linen"), "default", options)
check(Words(blocks) == "Trade Goods=1", "the search: only what it finds")
blocks = Views.Build("one", { section }, nil, "default", options)
check(Words(blocks) == "Pinned Items=0,Main Bags=24,Quiver=4,Reagent Bag=4,Keyring=4" and blocks[2].number == "7 / 24" and blocks[2].slots,
    "One Bag: every slot of the ordinary bags, the empty ones too; the special bags each by itself: " .. Words(blocks))
blocks = Views.Build("one", { section }, Core.Fuzzy.Query("linen"), "default", options)
check(blocks[1].entries[2].faded == false and blocks[1].entries[1].faded == true and blocks[1].entries[3].faded == true
    and blocks[1].entries[6].faded == false and blocks[1].word == "Main Bags",
    "searching in One Bag: Pinned's + left out; what is not found is faded, empty slots not")
blocks = Views.Build("each", { section }, nil, "default", options)
check(Words(blocks) == "Pinned Items=0,Backpack=16,Small Pouch=8,Quiver=4,Reagent Bag=4,Keyring=4", "Each Bag: every bag by itself: " .. Words(blocks))
blocks = Views.Build("cat:trade", { section }, nil, "default", options)
check(Words(blocks) == "Trade Goods=1", "a category by itself")
blocks = Views.Build("group:armory", { section }, nil, "default", options)
check(Words(blocks) == "Rings=1,Item Set Gear=1" and blocks[1].level == 3, "a group: its members each a block")
local counts = Views.Counts(section)
check(counts.trade == 1 and counts["group:armory"] == 2 and counts.junk == 1 and counts.pinned == 0, "how many each category holds")
counts = Views.Counts(section, { merge = false })
check(counts.trade == 2, "Merge Stacks off: each stack counted, as each is shown")
Categories.Pin(2589, true)
Reclassify()
Recent.list[1] = 2589
counts = Views.Counts(section)
local merged = counts.pinned == 1 and counts.recent == 1
counts = Views.Counts(section, { merge = false })
check(merged and counts.pinned == 2 and counts.recent == 2, "Pinned and Recent counted as they show: merged one cell, else each stack")
Categories.Pin(2589, false)
Reclassify()
Recent.Clear()
-- At any kind of banker this client has, stacks do not merge.
Enum.PlayerInteractionType.AccountBanker = 68
local talking = C_PlayerInteractionManager.IsInteractingWithNpcOfType
C_PlayerInteractionManager.IsInteractingWithNpcOfType = function(kind) return kind == 68 end
check(not Views.Merging({}), "at the account's banker: no stacks merged")
C_PlayerInteractionManager.IsInteractingWithNpcOfType = talking
check(Views.Merging({}), "away from it: merged again")

-------------------------------------------------------------------------------
--  The displays, without a frame
-------------------------------------------------------------------------------
local places = {}
local width = 10 * (Layout.SIZE + Layout.GAP) - Layout.GAP
check(Layout.Columns(width) == 10, "as many cells to a line as fit")
-- The item size: the slider's percent, smaller in a narrow window, the layout at that size.
check(Layout.Gap(Layout.SIZE) == Layout.GAP and Layout.Gap(Layout.SMALLEST) >= 2, "the gap goes with the size")
check(Layout.Scale(nil) == 100 and Layout.Scale("big") == 100 and Layout.Scale(10) == Layout.SCALE.low and Layout.Scale(500) == Layout.SCALE.high
    and Layout.Scale(73) == 75, "a kept size of a wrong kind: as at first; else within the slider, on its steps")
check(Layout.Fit(100, 1000) == Layout.SIZE and Layout.Fit(75, 1000) == math.floor(Layout.SIZE * 0.75 + 0.5)
    and Layout.Fit(Layout.SCALE.high, 1000) > Layout.SIZE, "room enough: as large as the slider says, larger too")
do
    local room = Layout.FIT * (Layout.SIZE + Layout.GAP) - Layout.GAP
    check(Layout.Fit(100, room) == Layout.SIZE and Layout.Fit(100, room - 1) < Layout.SIZE, "a window narrower than that many in a line: smaller items")
    local fit = Layout.Fit(100, room - 40)
    check(Layout.Columns(room - 40, fit) >= Layout.FIT, "as many in a line as before: " .. fit)
    check(Layout.Fit(100, 60) == Layout.SMALLEST and Layout.Fit(Layout.SCALE.high, 60) == Layout.SMALLEST, "never under the smallest")
end
blocks = Views.Build("all", { section }, nil, "default", options)
local count, height = Layout.Lay("grid", blocks, width, places)
local kinds = {}
for index = 1, count do kinds[places[index].kind] = (kinds[places[index].kind] or 0) + 1 end
check(kinds.head == 14 and kinds.cell == 9 and kinds.plus == 9 and not kinds.pad,
    "grid: a head per block and group title, its cells, one empty slot after them where it takes items, nothing more")
local quest
for index = 1, count do
    local place = places[index]
    if place.kind == "plus" and place.block and place.block.word == "Quest Items" then quest = place end
end
check(quest and quest.block.key == "quest", "an empty category: its empty slot alone, knowing its block")
local function HeadAt(word)
    for index = 1, count do
        if places[index].kind == "head" and places[index].block.word == word then return index, places[index] end
    end
end
local armory, title = HeadAt("The Armory")
local _, rings = HeadAt("Rings")
local _, setGear = HeadAt("Item Set Gear")
check(places[1].kind == "head" and places[2].kind == "plus" and places[2].x == 0 and places[2].y == Layout.HEAD + Layout.HEAD_GAP
    and title.x == 0 and title.width == width and title.y > places[2].y,
    "Pinned empty: its one empty slot under its head; a group's title on a line of its own, the whole width")
check(rings.y == title.y + Layout.HEAD + Layout.HEAD_GAP and rings.x == 0 and setGear.y == rings.y and setGear.x > rings.x
    and places[armory + 2].kind == "cell" and places[armory + 3].kind == "head" and places[armory + 5].kind == "plus"
    and places[armory + 5].block.drop == "group:armory" and places[armory + 5].y == places[armory + 4].y
    and places[armory + 5].x > places[armory + 4].x,
    "the group's members side by side under its title, then the group's one empty slot level with their cells")
local _, tradeHead = HeadAt("Trade Goods")
local _, consumablesHead = HeadAt("Consumables")
check(tradeHead.x == 0 and tradeHead.y > consumablesHead.y, "after a group's members: a line of its own")
local lastY = 0
for index = 1, count do lastY = math.max(lastY, places[index].y) end
check(lastY > 0, "what does not fit on a line goes on the next")
count = Layout.Lay("grid", blocks, width, places, function() return 100 end)
local pinnedSlots = 0
for index = 1, count do
    if places[index].kind == "plus" and places[index].block.word == "Pinned Items" then pinnedSlots = pinnedSlots + 1 end
end
check(pinnedSlots == 1 and places[1].width == 100,
    "a head wider than its cells: the block takes its room, still one empty slot")
local narrow = 2 * (Layout.SIZE + Layout.GAP) - Layout.GAP
count = Layout.Lay("grid", blocks, narrow, places)
local wrapped = true
for index = 1, count do
    if places[index].kind == "head" and places[index].x ~= 0 then wrapped = false end
end
check(wrapped, "a narrow room: a block to a line")
count = Layout.Lay("list", blocks, width, places)
check(places[2].kind == "head" and places[2].block.title and places[4].kind == "row" and places[4].size == Layout.ICON
    and places[4].width == width, "list: a line per cell (Pinned empty: its head only; a group's title, then its members)")
check(select(1, Layout.Shape(9, 10)) == 3 and select(1, Layout.Shape(2, 10)) == 2 and select(2, Layout.Shape(10, 10)) == 3,
    "compact: each block near square")
count = Layout.Lay("compact", blocks, width, places)
check(places[1].kind == "label" and places[1].block.word == "Pinned Items" and places[2].kind == "plus"
    and places[3].kind == "head" and places[3].block.title and places[4].kind == "label" and places[5].kind == "cell"
    and places[6].kind == "label" and places[6].x > 0 and places[6].y == places[4].y and places[8].kind == "plus"
    and places[8].block.bare,
    "compact: the blocks side by side, each with its name over it and its empty slot; a group's title over its members")

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
local handle = ns.Window.handle
local frame = handle.frame
frame._left, frame._bottom = 1920 - ns.Window.WIDTH, 0
local square = handle.edge.strips.corner
local function Push()
    W.Wait(1)
    W.cursorX, W.cursorY = 1920, 0
    square:GetScript("OnEnter")(square)
    W.cursorX, W.cursorY = 960, 500
    W.Wait(Core.Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end

check(not ns.Board.Panel("bags") and not Cells.Shown(0, 1), "the bags are built the first time their window is shown, not at login")
Push()
Stand()
local panel = ns.Board.Panel("bags")
check(panel and panel:IsShown() and panel.title._text == "Bags", "the bags on the full screen, headed Bags")
for label, e in pairs(Core.errors) do check(not label:find("bags"), "no problem noted: " .. label .. " " .. tostring(e.text)) end
kept = ns.options.bags
local function Y(button) return -button:GetParent()._points[1][5] end
local function HeadNamed(word)
    for _, widget in ipairs(W.frames) do
        if widget.canvas and widget.line and widget.word._text == word and widget:IsShown() then return widget end
    end
end
local function Text(word)
    for _, widget in ipairs(W.frames) do
        if widget._kind == "FontString" and widget._text == word and widget:IsVisible() then return widget end
    end
end
check(Text("7 / 24 Items"), "the bar: the slots of the bags taken, of how many")
local swordButton = Cells.Button(0, 1)
check(swordButton and swordButton:IsShown() and swordButton:GetParent():GetID() == 0 and swordButton:GetID() == 1,
    "the game's item button, its holder carrying the bag, the button the slot")
check(drawn[swordButton].texture == "icon2001" and HeadNamed("The Armory") and HeadNamed("Item Set Gear")
    and Y(swordButton) == -HeadNamed("Item Set Gear")._points[1][5] + Layout.MEMBER + Layout.HEAD_GAP
    and not HeadNamed("Item Set Gear").line:IsShown() and not HeadNamed("The Armory").line:IsShown(),
    "All Items at first: the sword under its category's head, under its group's title (no rule under either)")
local levelText
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == 20 or widget._text == "20" then levelText = widget end
end
check(levelText, "the item level of gear on its button")
-- The green arrow on gear that would make the character better, always; what you wear changes it.
local function Arrows()
    local count = 0
    for _, widget in ipairs(W.frames) do
        if widget._atlas == "bags-greenarrow" and widget._shown then count = count + 1 end
    end
    return count
end
local upgrade = Core.Upgrade
check(Arrows() == 0, "no upgrade: no arrow")
Core.Upgrade = function(_, item) if item == 2001 then return "better", 5 end end
W.Fire("PLAYER_EQUIPMENT_CHANGED")
W.Wait(0)
check(Arrows() == 1, "an upgrade in the bags: its arrow, drawn anew as what you wear changes")
Core.Upgrade = upgrade
W.Fire("PLAYER_EQUIPMENT_CHANGED")
W.Wait(0)
check(Arrows() == 0, "worn something better: gone")
local trade = HeadNamed("Trade Goods")
check(trade and trade.number._text == "(1)" and drawn[Cells.Button(0, 2)].count == 27, "the two stacks of cloth as one cell of 27")

-- The sidebar.
local function RowNamed(word)
    for _, row in ipairs(Sidebar.Rows()) do
        if row.word == word and row:IsShown() then return row end
    end
end
check(Categories.Folded("armory") and Categories.Folded("prep") and RowNamed("The Armory") and RowNamed("Consumables")
    and not RowNamed("Head") and not RowNamed("Potions") and RowNamed("Professions"),
    "The Armory and Consumables folded into their rows at first, the sidebar short")
Categories.Fold("armory", false)
Categories.Fold("prep", false)
Bags.Refresh()
check(RowNamed("All Items") and RowNamed("One Bag") and RowNamed("Each Bag") and RowNamed("Pinned Items")
    and RowNamed("The Armory") and RowNamed("Head") and RowNamed("Weapons") and RowNamed("Potions") and RowNamed("Professions")
    and RowNamed("Add Category") and not RowNamed("Quest Items"),
    "the sidebar: the views, Pinned, every category switched on (empty ones too), a group's members, Add Category")
do
    local ART = Categories.ART
    local function Drawn(word, key)
        local icon = RowNamed(word).icon
        return icon._texture == ART .. key and icon._coords[1] == 0 and icon._coords[2] == 1
    end
    check(ART == "Interface\\AddOns\\SaneUI_Inventory\\Art\\Categories\\" and Drawn("All Items", "all")
        and Drawn("Each Bag", "each") and Drawn("Pinned Items", "pinned") and Drawn("Head", "head")
        and Drawn("Potions", "potions") and Drawn("Add Category", "add"),
        "the rows' icons Sane UI's own pencil drawings, by their keys, drawn whole")
    check(Drawn("The Armory", "armory") and Categories.GroupIcon("prep") == ART .. "prep",
        "a built-in group its own drawing, not its first member's")
end
check(RowNamed("Professions").count._text == "0" and RowNamed("Professions").label._text == "Professions",
    "an empty category by its name, its count 0")
check(RowNamed("All Items").bar:IsShown() and not RowNamed("One Bag").bar:IsShown() and RowNamed("Junk").count._text == "1",
    "the view shown lit; each category's count")
local row = RowNamed("One Bag")
row:GetScript("OnClick")(row, "LeftButton")
check(HeadNamed("Main Bags") and HeadNamed("Main Bags").number._text == "(7 / 24)" and Cells.Shown(0, 16),
    "One Bag: every slot, the empty ones too")
row = RowNamed("Trade Goods")
row:GetScript("OnClick")(row, "LeftButton")
check(HeadNamed("Trade Goods") and not HeadNamed("Junk") and Text("1 Items"), "a category by itself; the bar counts its cells")
row = RowNamed("All Items")
row:GetScript("OnClick")(row, "LeftButton")
check(HeadNamed("Junk"), "back to All Items")

-- The search.
ns.Board.Search("linen")
check(HeadNamed("Trade Goods") and not HeadNamed("Junk")
    and (not swordButton:GetParent():IsShown() or (Cells.Record(swordButton) or {}).item == 2589),
    "searching: only what is found")
ns.Board.Search("")
check(HeadNamed("Junk"), "the search cleared: all again")

-- The item's menu and the middle click.
local function Line(menu, text)
    for _, line in ipairs(menu or {}) do
        if line.text == text then return line end
    end
end
local function Choose(menu, text)
    local line = Line(menu, text)
    line.fn(line.data)
    return line
end
local function ItemMenu(button)
    alt = true
    button:GetScript("OnClick")(button, "RightButton")
    alt = false
    return W.menus[#W.menus]
end
local menus = #W.menus
swordButton:GetScript("OnClick")(swordButton, "RightButton")
check(#W.menus == menus, "a right click on an item: the game's own, no menu of ours")
local menu = ItemMenu(swordButton)
check(menu[1].title == "Steel Sword" and Line(menu, "Pinned Items") and Line(menu, "Junk") and Line(menu, "Put Into"),
    "Alt and a right click on an item: its menu")
Choose(menu, "Pinned Items")
check(kept.pinned[2001] and HeadNamed("Pinned Items") and HeadNamed("The Armory"), "pinned: shown under Pinned at the top, and in its own category")
swordButton = Cells.Button(0, 1)
swordButton:GetScript("OnMouseUp")(swordButton, "MiddleButton")
check(not kept.pinned[2001] and HeadNamed("Pinned Items").number._text == "(0)", "a middle click unpins it; Pinned stays with its +")
swordButton = Cells.Button(0, 1)
swordButton:GetScript("OnMouseUp")(swordButton, "MiddleButton")
check(kept.pinned[2001], "and pins it again")
Categories.Pin(2001, false)
Bags.Refresh()
local potionButton = Cells.Button(0, 3)
menu = ItemMenu(potionButton)
Choose(Line(menu, "Put Into").sub, Line(Line(menu, "Put Into").sub, "Trade Goods") and "Trade Goods" or Line(menu, "Put Into").sub[8].text)
check(kept.assigned[118] == "trade", "put into another category from its menu")
potionButton = Cells.Button(0, 3)
potionButton:GetScript("OnMouseUp")(potionButton, "MiddleButton")
check(kept.assigned[118] == nil and not kept.pinned[118], "a middle click on an item put into a category takes it out")
menu = ItemMenu(Cells.Button(0, 3))
Choose(Line(menu, "Put Into").sub, "New Category")
local popup = W.popups[#W.popups]
check(popup.which == "GENERIC_INPUT_BOX", "a new category named in the game's dialog")
popup.data.callback("Tonics")
check(kept.assigned[118] == "own1" and HeadNamed("Tonics"), "made, the item in it")
menu = ItemMenu(Cells.Button(0, 3))
Choose(menu, "Junk")
check(kept.assigned[118] == "junk" and HeadNamed("Tonics"), "marked as junk; its own category stays (the player's own, empty)")
Choose(ItemMenu(Cells.Button(0, 3)), "Junk")
check(kept.assigned[118] == "own1", "unmarked: back where it was put")

-- Let go over a head or a row.
local head = HeadNamed("Tonics")
head:GetScript("OnEnter")(head)
check(not head.lit:IsShown(), "nothing held: the head is not lit")
head:GetScript("OnLeave")(head)
holding = 2589
head = HeadNamed("Tonics")
head:GetScript("OnEnter")(head)
check(head.lit:IsShown(), "an item brought over a category's head: lit")
head:GetScript("OnReceiveDrag")(head)
check(kept.assigned[2589] == "own1" and holding == nil, "let go there: put into that category, the item back in its slot")
holding = 2589
row = RowNamed("Trade Goods")
row:GetScript("OnEnter")(row)
local takesLight = row.hover._colorTexture[4]
row:GetScript("OnLeave")(row)
holding = nil
row:GetScript("OnEnter")(row)
check(takesLight == ns.Sidebars.TAKES and row.hover._colorTexture[4] == ns.Sidebars.HOVER and row.hover:GetAlpha() == 1,
    "a row that takes the item held: lit brighter under the mouse, by its colour")
row:GetScript("OnLeave")(row)
holding = 2589
row = RowNamed("Pinned Items")
row:GetScript("OnClick")(row, "LeftButton")
check(kept.pinned[2589] and holding == nil, "an item clicked on Pinned in the sidebar: pinned")
holding = 2589
row = RowNamed("Reagent Bag")
row:GetScript("OnReceiveDrag")(row)
check(holding == 2589 and kept.assigned[2589] == "own1", "the reagent bag's category takes nothing: the item stays held")
holding = nil
Categories.Pin(2589, false)
Categories.Assign(2589, nil)
Bags.Refresh()

-- A category's empty slot after its items (the "+"): an item brought to it goes in; clicked with nothing, the next item clicked does.
local function PlusOf(key)
    for _, widget in ipairs(W.frames) do
        if widget.canvas and widget:GetObjectType() == "Button" and widget.key == key and widget:IsShown() then
            return widget
        end
    end
end
local plus = PlusOf("trade")
check(plus and PlusOf("pinned") and not PlusOf("reagent"), "a + after Pinned and Trade Goods, none after the reagent bag's")
check(plus.icon._texture == Categories.ART .. "trade" and plus.icon:GetAlpha() == ns.Canvas.SLOT_FADE
    and plus.icon._coords[1] == 0 and plus.icon:GetWidth() == plus:GetWidth() * ns.Canvas.SLOT_ICON
    and PlusOf("pinned").icon._texture == Categories.ART .. "pinned",
    "an empty slot shows its category's drawing in its middle, whole and faded to a subtle grey")
do
    local PX, words = SaneUI.Core.Journal.PX, ns.Paper.WORDS
    check(words > 1 and math.abs(SaneUIBagsSideLabel._font[2] - 15 * words * PX) < 1e-9
        and math.abs(SaneUIBagsHead._font[2] - 16 * words * PX) < 1e-9
        and math.abs(SaneUIBagsMember._font[2] - 13 * words * PX) < 1e-9
        and math.abs(SaneUIBagsSideTick._font[2] - ns.Sidebars.TICK * PX) < 1e-9
        and Layout.HEAD == ns.Paper.Fit(20) and Layout.HEAD > 20,
        "every word of the bags' view larger by Paper.WORDS, its heads' lines with it; a box's tick as large as its box")
end
holding = 118
plus:GetScript("OnClick")(plus)
check(kept.assigned[118] == "trade" and holding == nil, "an item brought to a +: into that category")
Categories.Assign(118, nil)
Bags.Refresh()
plus = PlusOf("pinned")
plus:GetScript("OnClick")(plus)
check(ns.Select.Mode() == "put", "a + clicked with nothing: choosing an item by a click")
ns.Select.Click(Cells.Button(0, 3))
check(kept.pinned[118] and ns.Select.Mode() == nil, "the next item clicked is pinned; the choosing ends")
Categories.Pin(118, false)
Bags.Refresh()
-- A category's empty slot: an item let go there goes into that category; Junk marks it, another category takes
-- the mark off; an item from outside the bags goes into a free slot of them.
local junkPlus, tradePlus = PlusOf("junk"), PlusOf("trade")
check(junkPlus and tradePlus, "every category that takes items: an empty slot")
holding = 118
junkPlus:GetScript("OnEnter")(junkPlus)
check(junkPlus.lit:IsShown(), "an item brought over an empty slot: lit")
junkPlus:GetScript("OnLeave")(junkPlus)
check(not junkPlus.lit:IsShown(), "and dark again when it leaves")
junkPlus:GetScript("OnReceiveDrag")(junkPlus)
check(kept.assigned[118] == "junk" and Categories.Junk(118, 1) and holding == nil, "let go on Junk's empty slot: marked as junk")
Bags.Refresh()
tradePlus = PlusOf("trade")
holding = 118
tradePlus:GetScript("OnClick")(tradePlus, "LeftButton")
check(kept.assigned[118] == "trade" and not Categories.Junk(118, 1) and holding == nil,
    "clicked onto another category's empty slot: into it, the junk mark off")
do
    local pickup, placed = C_Container.PickupContainerItem, nil
    C_Container.PickupContainerItem = function(bag, slot) placed, holding, cursor = bag .. ":" .. slot, nil, false end
    holding, cursor = 6001, true
    Bags.Refresh()
    PlusOf("trade"):GetScript("OnReceiveDrag")(PlusOf("trade"))
    check(kept.assigned[6001] == "trade" and placed and holding == nil, "an item from outside the bags: into a free slot of them")
    C_Container.PickupContainerItem, cursor = pickup, false
end
-- An item let go over the page's paper: into the bags, where the rules put it (what it was put into taken off).
do
    Categories.Assign(4001, "trade")
    holding, cursor = 4001, true
    local back = ns.Bags.canvas.child
    check(not back._mouse, "the items' area takes no mouse itself: the item buttons keep it")
    check(ns.Bags.scroll._template == nil and ns.Bags.scroll:GetScript("OnMouseWheel"),
        "the items' scroll area: no scroll bar, the wheel scrolls it")
    back = panel
    back:GetScript("OnReceiveDrag")(back)
    check(kept.assigned[4001] == nil and holding == nil,
        "let go anywhere over the window that takes nothing itself: back to where the rules put it, in the bags")
    cursor = false
end
-- A group divided has one + for the whole group: an item let go there goes into the member the rules give it
-- there, else into the group's first member.
do
    local groupPlus = PlusOf("group:armory")
    check(groupPlus.icon._texture == Categories.ART .. "armory", "a group's one empty slot: the group's drawing")
    check(groupPlus and not PlusOf("finger"), "a group's one + (none on its members)")
    holding, cursor = 4001, true
    groupPlus:GetScript("OnReceiveDrag")(groupPlus)
    check(kept.assigned[4001] == nil, "a ring let go on The Armory's +: the rules put it into Rings, nothing to keep")
    Bags.Refresh()
    holding, cursor = 118, true
    PlusOf("group:armory"):GetScript("OnReceiveDrag")(PlusOf("group:armory"))
    check(kept.assigned[118] == "head", "a potion let go there: into the group's first member")
    Categories.Assign(118, nil)
    cursor = false
    Bags.Refresh()
end
-- The sidebar: a group's arrow folds its members into its row; its box divides it in All Items or shows it whole.
do
    local armoryRow = RowNamed("The Armory")
    check(armoryRow.arrow:IsShown() and armoryRow.box:IsShown() and armoryRow.box.check:IsShown() and RowNamed("Head"),
        "a group's row: its arrow and its box (ticked: divided)")
    local Side = ns.Sidebars
    local function near(a, b) return a and math.abs(a - b) < 1e-6 end
    local mark = armoryRow.arrow.mark
    check(mark:GetTexture():match("Journal\\arrow$") and near(mark._rotation, math.pi) and mark:GetAlpha() == Side.MARK
        and mark:GetWidth() == Side.TOGGLE and mark:GetHeight() == Side.TOGGLE and mark._points[1][1] == "CENTER"
        and armoryRow.arrow:GetWidth() == armoryRow.box:GetWidth() and armoryRow.box:GetWidth() == Side.TOGGLE,
        "its arrow the sidebars' pencil arrow, as large as its box and in its middle, turned up while listed, light")
    check(armoryRow.box.check:GetText() == "\226\136\154" and armoryRow.box.check:GetAlpha() == Side.MARK,
        "its tick drawn by hand in pencil, lightly")
    armoryRow.box:GetScript("OnEnter")(armoryRow.box)
    check(armoryRow.box.check:GetAlpha() == 1, "under the mouse the tick drawn whole")
    armoryRow.box:GetScript("OnLeave")(armoryRow.box)
    check(armoryRow.box.check:GetAlpha() == Side.MARK, "and lightly again when it leaves")
    armoryRow.arrow:GetScript("OnClick")(armoryRow.arrow)
    check(Categories.Folded("armory") and not RowNamed("Head") and RowNamed("The Armory"), "folded: its members not listed")
    check(near(RowNamed("The Armory").arrow.mark._rotation, 0), "folded: the arrow turned down (as drawn)")
    RowNamed("The Armory").arrow:GetScript("OnClick")(RowNamed("The Armory").arrow)
    check(RowNamed("Head"), "unfolded again")
    RowNamed("The Armory").box:GetScript("OnClick")(RowNamed("The Armory").box)
    check(not Categories.Divided("armory") and not RowNamed("The Armory").box.check:IsShown() and PlusOf("group:armory")
        and not HeadNamed("Rings") and HeadNamed("The Armory"), "unticked: the group whole in All Items, one +")
    RowNamed("The Armory").box:GetScript("OnClick")(RowNamed("The Armory").box)
    check(Categories.Divided("armory") and HeadNamed("Rings"), "ticked again: divided")
end
Categories.Assign(118, nil)
Categories.Assign(6001, nil)
Bags.Refresh()
-- The junk marker.
local coinButton = Bags.bar.coin
check(coinButton:IsShown(), "the junk marker on the bar")
coinButton:GetScript("OnClick")(coinButton)
check(ns.Select.Mode() == "junk" and coinButton._checked, "the coin: marking junk by clicks")
ns.Select.Click(Cells.Button(0, 3))
check(kept.assigned[118] == "junk" and ns.Select.Mode() == "junk", "an item clicked: junk; the mode stays")
ns.Select.Click(Cells.Button(0, 3))
check(kept.assigned[118] ~= "junk", "clicked again: unmarked")
coinButton:GetScript("OnClick")(coinButton)
check(ns.Select.Mode() == nil and not coinButton._checked, "the coin again: the mode ends")
holding = 3001
coinButton:GetScript("OnClick")(coinButton)
check(kept.assigned[3001] == "misc" and not Categories.Junk(3001, 0) and holding == nil,
    "a grey item brought to the coin: unmarked at once, kept out of Junk")
Categories.Assign(3001, nil)
Bags.Refresh()

-- A category's menu.
local function RowMenu(word)
    local target = RowNamed(word)
    target:GetScript("OnClick")(target, "RightButton")
    return W.menus[#W.menus]
end
menu = RowMenu("Tonics")
check(menu[1].title == "Tonics" and Line(menu, "Rename") and Line(menu, "Move Up") and Line(menu, "Create Group With")
    and Line(menu, "Hide in All Items") and Line(menu, "Switch Off") and Line(menu, "Icon") and Line(menu, "Delete"),
    "a right click on the player's own category: its menu")
Choose(menu, "Rename")
popup = W.popups[#W.popups]
check(popup.box.text == "Tonics", "renamed in the game's dialog, the name in it")
popup.data.callback("Flasks")
check(HeadNamed("Flasks") and RowNamed("Flasks"), "renamed")
menu = RowMenu("Flasks")
local third = Line(menu, "Icon").sub[3]
third.fn(third.data)
check(kept.own[1].icon == Categories.ICONS[3], "its icon chosen")
check(RowNamed("Flasks").icon._texture == Categories.ICONS[3] and RowNamed("Flasks").icon._coords[1] > 0,
    "the player's own category with the game's icon it chose: that icon, cut a little round its edge")
check(PlusOf("own1") and PlusOf("own1").icon._texture == Categories.ICONS[3] and PlusOf("own1").icon._grey
    and not PlusOf("trade").icon._grey, "in its empty slot that icon grey; Sane UI's drawings are graphite already")
menu = RowMenu("Flasks")
Choose(Line(menu, "Create Group With").sub, "Trade Goods")
check(RowNamed("Trade Goods & Flasks") and Categories.GroupOf("own1"), "grouped with another from the menu")
menu = RowMenu("Trade Goods & Flasks")
check(Line(menu, "Disband Group") and Line(menu, "Hide in All Items"), "the group's menu")
Choose(menu, "Disband Group")
check(not Categories.GroupOf("own1"), "disbanded")
Choose(RowMenu("The Armory"), "Move Down")
check(RowNamed("Consumables").top < RowNamed("The Armory").top and RowNamed("Camp Items").top < RowNamed("Weapons").top,
    "a group's Move Down: past the next group at once, its members with it")
Choose(RowMenu("The Armory"), "Move Up")
check(RowNamed("The Armory").top < RowNamed("Consumables").top, "and up again")
menu = RowMenu("Trade Goods")
Choose(menu, "Hide in All Items")
check(not HeadNamed("Trade Goods") and kept.hidden.trade, "hidden from All Items")
Choose(RowMenu("Trade Goods"), "Hide in All Items")
check(HeadNamed("Trade Goods"), "shown again")
Choose(RowMenu("Trade Goods"), "Switch Off")
check(not RowNamed("Trade Goods") and Categories.Off("trade"), "switched off: its items in Miscellaneous")
local dropdown
for _, widget in ipairs(W.frames) do
    if widget._generator and (rawget(widget, "word") or widget._override) == "View" then dropdown = widget end
end
dropdown:GenerateMenu()
local off = Line(dropdown._items, "Switched Off")
check(off and Line(off.sub, "Switch On Trade Goods"), "the dropdown View lists what is switched off")
Choose(off.sub, "Switch On Trade Goods")
check(RowNamed("Trade Goods"), "switched on again from there")
Choose(RowMenu("Flasks"), "Delete")
popup = W.popups[#W.popups]
check(popup.which == "GENERIC_CONFIRMATION" and RowNamed("Flasks"), "deleting asks first")
popup.data.callback()
check(not RowNamed("Flasks") and #kept.own == 0 and kept.assigned[118] == nil, "deleted")
menu = RowMenu("Pinned Items")
check(Line(menu, "Hide") and not Line(menu, "Rename"), "Pinned's menu: only Hide")

-- A category dragged in the sidebar: its ghost on the cursor, a line where it would go (a row lit: into it); let go
-- there, it is put there and kept.
local side = RowNamed("Trade Goods").rail
side.frame._mouseOver = true
side.child._bottom = 0
local pressed = true
IsMouseButtonDown = function() return pressed end
local function Over(word, part)
    W.cursorY = side.child:GetTop() - (RowNamed(word).top + part * ns.Sidebars.ROW)
end
local function Lift(word)
    local held = RowNamed(word)
    held:GetScript("OnDragStart")(held)
    side.ghost:GetScript("OnUpdate")(side.ghost)
    return held
end
local function Land(held)
    held:GetScript("OnDragStop")(held)
end
Over("Trade Goods", 0.1)
local held = Lift("Professions")
check(side.ghost:IsShown() and side.ghost.label._text == "Professions" and held:GetAlpha() < 1,
    "a category held: its ghost on the cursor, the row faded")
check(side.line:IsShown() and not side.mark:IsShown(), "over a row's top: a line where it would go")
Land(held)
check(Categories.rank.professions == Categories.rank.trade - 1 and kept.order and not side.ghost:IsShown()
    and RowNamed("Professions").top < RowNamed("Trade Goods").top, "let go: put before that row, kept, the sidebar anew")
Over("Trade Goods", 0.5)
held = Lift("Professions")
check(side.mark:IsShown() and not side.line:IsShown(), "over a row's middle: that row lit")
Land(held)
local made = Categories.GroupOf("trade")
check(made and Categories.GroupOf("professions") == made and RowNamed("Professions & Trade Goods"),
    "let go there: a group of the two")
Over("Miscellaneous", 0.1)
Land(Lift("Professions"))
check(not Categories.GroupOf("professions") and not Categories.GroupOf("trade")
    and Categories.rank.professions == Categories.rank.misc - 1, "a member dragged out of its group; a group of one is none")
Over("Miscellaneous", 0.9)
Land(Lift("The Armory"))
check(Categories.rank.head == Categories.rank.misc + 1 and Categories.rank.sets == Categories.rank.head + 16
    and Categories.GroupOf("armor") == "armory", "a group dragged: its members together, after that row")
Over("Junk", 0.9)
Land(Lift("Trade Goods"))
check(Categories.order[#Categories.order - 1] == "trade" and Categories.order[#Categories.order] == "junk",
    "over Junk: before it, Junk stays last")
Over("Pinned Items", 0.5)
held = Lift("Trade Goods")
check(not side.line:IsShown() and not side.mark:IsShown(), "over Pinned: nowhere to go")
Land(held)
check(Categories.order[#Categories.order - 1] == "trade" and Categories.order[1] == "pinned", "let go there: nothing moved")
held = Lift("Pinned Items")
check(not side.ghost:IsShown(), "Pinned is not dragged")
held = Lift("Junk")
check(not side.ghost:IsShown(), "nor Junk")
Over("Head", 0.5)
Land(Lift("Trade Goods"))
check(Categories.GroupOf("trade") == "armory", "let go over a group's member: into that group")
Over("Trade Goods", 0.5)
held = Lift("Item Set Gear")
pressed = false
side.ghost:GetScript("OnUpdate")(side.ghost)
check(not side.ghost:IsShown() and held:GetAlpha() == 1, "the mouse let go elsewhere: the drag given up")
IsMouseButtonDown = function() return false end
side.frame._mouseOver = false
kept.order, kept.member = nil, nil
Categories.Use(kept)
Bags.Refresh()
check(Categories.GroupOf("weapons") == "armory" and RowNamed("The Armory"), "the first order again, for what follows")

-- The dropdown View.
dropdown:GenerateMenu()
Choose(dropdown._items, "List")
local function RowOf(bag, slot) return Bags.rowOf[Cells.Button(bag, slot)] end
check(kept.look == "list" and RowOf(0, 1) and RowOf(0, 1).cells.name._text == "Steel Sword" and RowOf(0, 1).cells.level._text == "20"
    and RowOf(0, 1).cells.sell._text == "500c" and RowOf(0, 2).cells.count._text == "27",
    "the list: a line per item, its name, item level, what the vendor pays, the count")
local columnsHead = ns.Columns.head
check(columnsHead:IsShown() and ns.Columns.Cell("level"):IsShown() and not ns.Columns.Cell("bind"), "the columns' head over the list")
local levelCell = ns.Columns.Cell("level")
levelCell:GetScript("OnMouseDown")(levelCell, "LeftButton")
levelCell:GetScript("OnMouseUp")(levelCell, "LeftButton")
check(kept.listSort == "level" and kept.listDown == true and levelCell.text._text == "iLvl v", "a click on a column: sorted by it, high first")
levelCell:GetScript("OnMouseDown")(levelCell, "LeftButton")
levelCell:GetScript("OnMouseUp")(levelCell, "LeftButton")
check(kept.listDown == false, "clicked again: the other way")
levelCell:GetScript("OnMouseUp")(levelCell, "RightButton")
local columnsMenu = W.menus[#W.menus]
Choose(columnsMenu, "Bind")
check(ns.Columns.Cell("bind"):IsShown() and RowOf(0, 1).cells.bind._text == "BoE", "a column chosen in the head's menu: how the sword binds")
columnsMenu = W.menus[#W.menus]
levelCell:GetScript("OnMouseUp")(levelCell, "RightButton")
Choose(W.menus[#W.menus], "Move Right")
check(kept.columns[3] == "count" and kept.columns[4] == "level", "a column moved right")
levelCell:GetScript("OnMouseUp")(levelCell, "RightButton")
Choose(W.menus[#W.menus], "Reset Columns")
check(table.concat(kept.columns, ",") == "icon,name,level,count,sell" and not kept.listSort, "the columns as they were")
-- A column's edge held: drawn anew only when its width changes; the button let go unheard (the head hidden
-- meanwhile), the sizing stops; a column held so stops too, and its own let-go still sorts.
local grip = columnsHead.grips.level
local redraws, redraw = 0, columnsHead.redraw
columnsHead.redraw = function() redraws = redraws + 1 redraw() end
IsMouseButtonDown = function() return true end
W.cursorX = 100
grip:GetScript("OnMouseDown")(grip, "LeftButton")
local tick = columnsHead:GetScript("OnUpdate")
tick(columnsHead)
tick(columnsHead)
check(redraws == 0 and kept.widths.level == nil, "a column's edge held still: nothing drawn anew")
W.cursorX = 130
tick(columnsHead)
tick(columnsHead)
check(redraws == 1 and kept.widths.level == 66, "moved: wider, drawn anew once")
IsMouseButtonDown = function() return false end
tick(columnsHead)
check(not columnsHead:GetScript("OnUpdate"), "the button let go where the head did not hear it: the sizing stops")
levelCell:GetScript("OnMouseDown")(levelCell, "LeftButton")
columnsHead:GetScript("OnUpdate")(columnsHead)
local stopped = not columnsHead:GetScript("OnUpdate")
levelCell:GetScript("OnMouseUp")(levelCell, "LeftButton")
check(stopped and kept.listSort == "level", "a column held so: its drag stops, its click still sorts")
columnsHead.redraw = redraw
kept.widths.level, kept.listSort, kept.listDown, W.cursorX = nil, nil, nil, 960
Bags.Redraw()
local armoryHead = HeadNamed("The Armory")
armoryHead:GetScript("OnMouseUp")(armoryHead, "LeftButton")
check(kept.folded and kept.folded["group:armory"] and not Cells.Shown(0, 1), "a head clicked in the list: folded")
armoryHead = HeadNamed("The Armory")
armoryHead:GetScript("OnMouseUp")(armoryHead, "LeftButton")
check(Cells.Shown(0, 1), "clicked again: unfolded")
dropdown:GenerateMenu()
Choose(dropdown._items, "Compact")
check(kept.look == "compact" and Cells.Shown(0, 1), "compact")
dropdown:GenerateMenu()
Choose(dropdown._items, "Grid")
dropdown:GenerateMenu()
Choose(dropdown._items, "Name")
check(kept.sort == "name" and Line(dropdown._items, "Name").checked("name"), "sorted by name, kept (sort: a key of its own)")
-- Sort By and the categories' own order never take each other's place in the store.
Choose(RowMenu("Professions"), "Switch Off")
check(not ns.off and Categories.Off("professions") and #Categories.order > 0 and kept.sort == "name",
    "a category switched off after Sort By: the module goes on, both orders kept")
dropdown:GenerateMenu()
Choose(Line(dropdown._items, "Switched Off").sub, "Switch On Professions")
check(not ns.off and not Categories.Off("professions") and kept.sort == "name", "switched on again from the dropdown")
local tradeRank = Categories.rank.trade
Choose(RowMenu("Trade Goods"), "Move Down")
check(Categories.rank.trade == tradeRank + 1, "a category moved down")
Bags.Store()
check(Categories.rank.trade == tradeRank + 1 and type(kept.order) == "table" and kept.sort == "name",
    "the store read again (as after a /reload): the category where it was put, Sort By kept")
Choose(RowMenu("Trade Goods"), "Move Up")
dropdown:GenerateMenu()
Choose(dropdown._items, "Default")
dropdown:GenerateMenu()
Choose(dropdown._items, "Show Pinned Items")
check(ns.options.showPinned == false, "Pinned hidden from the dropdown, in the module's settings")
check(not RowNamed("Pinned Items"), "not in the sidebar then")
dropdown:GenerateMenu()
Choose(dropdown._items, "Show Pinned Items")
check(RowNamed("Pinned Items"), "shown again")

-- The settings (Core's options page): each switch draws the bags anew.
Core.Set(ns.name, "itemLevel", false)
local levelShown = false
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and (widget._text == 20 or widget._text == "20") and widget:IsVisible() then levelShown = true end
end
check(not levelShown, "Show Item Level off: no item level on gear")
Core.Set(ns.name, "itemLevel", true)
Core.Set(ns.name, "marker", false)
check(not HeadNamed("Junk") and not Bags.bar.coin:IsShown() and Cells.Record(Cells.Button(0, 4)).category == "misc",
    "the junk marker off: no Junk, no coin; grey items in their categories")
Core.Set(ns.name, "marker", true)
check(HeadNamed("Junk") and Bags.bar.coin:IsShown(), "on again")
Core.Set(ns.name, "first", "one")
Push()
Stand()
Push()
Stand()
check(HeadNamed("Main Bags") and Bags.Viewing() == "one", "Open With One Bag: the window opens with it")
Core.Set(ns.name, "first", "all")
Push()
Stand()
Push()
Stand()

-- The stack splitter: Shift and a click on a stack, in a view without empty slots.
W.modifier = "SPLITSTACK"
local clothButton = Cells.Button(0, 2)
clothButton:GetScript("OnClick")(clothButton, "LeftButton")
W.modifier = nil
local open, amount = ns.Split.Shown()
check(open and amount == "10" and not StackSplitFrame:IsShown(), "our splitter opens in place of the game's, half the stack in it")
C_Container.SplitContainerItem = function(bag, slot, amount) calls.split = bag .. ":" .. slot .. "x" .. amount end
C_Container.PickupContainerItem = function(bag, slot) calls.placed = bag .. ":" .. slot end
local splitButton
for _, widget in ipairs(W.frames) do
    if widget._parent == ns.Split.dialog and widget._kind == "Button" and widget._scripts.OnClick then
        for _, child in ipairs(W.frames) do
            if child._parent == widget and child._kind == "FontString" and child._text == "Split" then splitButton = widget end
        end
    end
end
splitButton:GetScript("OnClick")(splitButton)
check(calls.split == "0:2x10" and calls.placed == "0:6" and Views.split[2589], "split: that many into the first free slot; kept apart from then on")
check(not ns.Split.Shown(), "the splitter closed")
Views.split[2589] = nil
-- A Shift-click that links the stack into the chat (the game opened no splitter): none of ours either.
chatOpen, W.modifier = true, "SPLITSTACK"
clothButton = Cells.Button(0, 2)
clothButton:GetScript("OnClick")(clothButton, "LeftButton")
chatOpen, W.modifier = false, nil
check(W.links[#W.links] == "item" and not ns.Split.Shown(), "a Shift-click while writing in the chat: the item linked, no splitter")
-- An Auto Split under way stops when another stack is chosen, and the splitter goes when the bags do.
local function SplitButton(word)
    for _, widget in ipairs(W.frames) do
        if widget._parent == ns.Split.dialog and widget._kind == "Button" and widget._scripts.OnClick then
            for _, child in ipairs(W.frames) do
                if child._parent == widget and child._kind == "FontString" and child._text == word then return widget end
            end
        end
    end
end
local splits = 0
C_Container.SplitContainerItem = function() splits = splits + 1 end
ns.Split.Open(clothButton, Cells.Record(clothButton))
for _, widget in ipairs(W.frames) do
    if widget._parent == ns.Split.dialog and widget._kind == "EditBox" then widget:SetText("2") end -- less than either stack
end
local autoSplit = SplitButton("Auto Split")
autoSplit:GetScript("OnClick")(autoSplit)
W.Wait(ns.Split.WAIT)
check(splits >= 2, "Auto Split: one split after the other")
local potionStack = Cells.Button(0, 3)
ns.Split.Open(potionStack, Cells.Record(potionStack))
local splitsThen = splits
W.Wait(ns.Split.WAIT * 4)
check(splits == splitsThen and ns.Split.Shown(), "another stack chosen: the Auto Split under way stops")
Push()
Stand()
check(not ns.Split.Shown(), "the bags gone: the splitter with them")
Push()
Stand()
Views.split[2589] = nil

-------------------------------------------------------------------------------
--  The game's events while shown
-------------------------------------------------------------------------------
Put(1, 3, 7001, 2)
W.Fire("BAG_UPDATE", 1)
W.Fire("BAG_UPDATE_DELAYED")
check(not Cells.Shown(1, 3), "a burst of bag events: drawn once it is over")
W.Wait(0)
check(Cells.Shown(1, 3) and drawn[Cells.Button(1, 3)].texture == "icon7001", "a new item in the bags: drawn")
check(RowNamed("Recent Items") and RowNamed("Recent Items").count._text == "1" and HeadNamed("Recent Items"),
    "and recent: under Recent at the top")
bags[0][2].locked = true
W.Fire("ITEM_LOCK_CHANGED", 0, 2)
check(drawn[Cells.Button(0, 2)].grey == true, "an item picked up: grey")
bags[0][2].locked = false
W.Fire("ITEM_LOCK_CHANGED", 0, 2)

-- The clean-up: the game's own.
local clean = ns.Bags.bar.sort
check(clean.icon._texture and clean.icon._texture:find("Broom") and clean:GetParent() == ns.Bags.bar,
    "the clean-up: a round broom on the bar")
clean:GetScript("OnClick")(clean)
check(calls.sortBags == 1, "the clean-up button: the game's clean-up of the bags")
W.combat = true
clean:GetScript("OnClick")(clean)
W.combat = false
check(calls.sortBags == 1, "not in a fight")

-- Our sort, in One Bag: the items moved into the categories' order, partial stacks joined first. The stand-in's
-- cursor picks an item up and puts it down: two items swap, two stacks of one item join (20 to a stack).
local Sort = ns.Sort
local hand
C_Container.PickupContainerItem = function(bag, slot)
    calls.pickups = (calls.pickups or 0) + 1
    if not hand then
        if Slot(bag, slot) then hand, cursor = { bag, slot }, true end
        return
    end
    local from, to = Slot(hand[1], hand[2]), Slot(bag, slot)
    if to and to.item == from.item then
        local total = to.count + from.count
        to.count = math.min(20, total)
        from.count = total - to.count
        if from.count == 0 then bags[hand[1]][hand[2]] = nil end
    else
        bags[bag] = bags[bag] or {}
        bags[hand[1]][hand[2]], bags[bag][slot] = to, from
    end
    hand, cursor = nil, false
end
local before = {}
for _, bag in ipairs({ 0, 1 }) do
    before[bag] = {}
    for slot, entry in pairs(bags[bag]) do before[bag][slot] = entry end
end
Put(1, 5, 2589, 5)
Put(0, 12, 7001, 3)
local function Arranged()
    local list = {}
    for _, bag in ipairs({ 0, 1 }) do
        for slot = 1, SIZES[bag] do
            local entry = Slot(bag, slot)
            list[#list + 1] = entry and (entry.item .. "x" .. entry.count) or "-"
        end
    end
    return table.concat(list, ",")
end
local function SortDone()
    for _ = 1, 60 do
        if not Sort.Running() then break end
        W.Fire("BAG_UPDATE_DELAYED")
        W.Wait(Sort.WAIT)
    end
end
row = RowNamed("One Bag")
row:GetScript("OnClick")(row, "LeftButton")
clean:GetScript("OnClick")(clean)
check(Sort.Running() and not clean:IsEnabled() and calls.sortBags == 1, "One Bag: our own sort runs, not the game's; its button locked")
clean:GetScript("OnClick")(clean)
check(select(2, Sort.Running()) == 1, "a click while it runs starts nothing more")
check(Slot(1, 1).count == 12 and not Slot(1, 5) and Slot(0, 12).count == 5 and not Slot(1, 3),
    "the first pass: the partial stacks of one item joined, the smallest onto the largest")
SortDone()
check(not Sort.Running() and clean:IsEnabled() and clean:GetAlpha() == 1, "done: the button unlocked")
check(Arranged() == "4001x1,2001x1,118x5,7001x5,2589x20,2589x12,3002x1,3001x1" .. string.rep(",-", 16),
    "the items in the categories' order (armor, the set's gear, consumables, trade goods, the rest, junk), "
    .. "inside one by Sort By, the larger stack first, the empty slots last: " .. Arranged())
check(Slot(2, 1).item == 2512 and Slot(5, 1).item == 2447 and Slot(-1, 1).item == 5001,
    "the quiver, the reagent bag and the keyring as they were")
check(Cells.Record(Cells.Button(0, 1)).item == 4001, "the bags drawn as they are now")
local moved = calls.pickups
clean:GetScript("OnClick")(clean)
SortDone()
check(calls.pickups == moved and not Sort.Running(), "sorted already: nothing moved")
bags[0][1], bags[0][8] = bags[0][8], bags[0][1]
cursor = true
clean:GetScript("OnClick")(clean)
check(not Sort.Running(), "something on the cursor: no sort")
cursor = false
W.combat = true
clean:GetScript("OnClick")(clean)
check(not Sort.Running(), "in a fight: no sort")
W.combat = false
clean:GetScript("OnClick")(clean)
W.combat = true
W.Fire("PLAYER_REGEN_DISABLED")
check(not Sort.Running() and clean:IsEnabled(), "a fight stops it")
W.combat = false
clean:GetScript("OnClick")(clean)
SortDone()
check(Arranged():sub(1, 7) == "4001x1,", "begun again, it ends sorted")
row = RowNamed("All Items")
row:GetScript("OnClick")(row, "LeftButton")
clean:GetScript("OnClick")(clean)
check(calls.sortBags == 2 and not Sort.Running(), "the other views: the game's clean-up")
-- The bags as they were, for what follows.
for _, bag in ipairs({ 0, 1 }) do
    bags[bag] = {}
    for slot, entry in pairs(before[bag]) do
        bags[bag][slot] = entry
        entry.count = ({ [2001] = 1, [2589] = slot == 2 and 20 or 7, [118] = 5, [3001] = 1, [3002] = 1, [4001] = 1, [7001] = 2 })[entry.item]
    end
end
W.Wait(0)
Recent.Clear()
Recent.list[1] = 7001
Recent.Take(false)
Bags.Refresh()

-------------------------------------------------------------------------------
--  The foot and the bags' strip
-------------------------------------------------------------------------------
check(Bags.strip:IsShown(), "the bags' strip shown at first")
local toggle = Bags.bar.bags
toggle:GetScript("OnClick")(toggle)
check(not Bags.strip:IsShown() and kept.strip == false, "its button hides the strip, kept")
toggle:GetScript("OnClick")(toggle)
check(Bags.strip:IsShown() and kept.strip, "and shows it again")
-- Junk's first slot is the waste bin: an item let go there is offered to be destroyed in the game's own dialog.
do
    local bin
    for _, widget in ipairs(W.frames) do
        if widget.picture and widget.lit and widget:IsShown() and (widget.picture._texture or ""):find("trash") then bin = widget end
    end
    local junkPlus = PlusOf("junk")
    check(bin and junkPlus and -bin._points[1][5] == -junkPlus._points[1][5] and bin._points[1][4] < junkPlus._points[1][4],
        "Junk: the waste bin first, on its line, before its items and its empty slot")
    local popups = #W.popups
    bin:GetScript("OnReceiveDrag")(bin)
    check(#W.popups == popups, "nothing on the cursor: nothing asked")
    holding, cursor = 118, true
    bin:GetScript("OnReceiveDrag")(bin)
    check(#W.popups == popups + 1 and W.popups[#W.popups].which == "DELETE_ITEM",
        "an item let go there: the game's own question to destroy it, as when dropped into the world")
    holding, cursor = nil, false
end
local sideFrame = ns.BagSidebar.frame
ns.Bags.Fold(true)
check(kept.side == false and not Bags.strip:IsShown() and sideFrame:GetWidth() == ns.Sidebars.FOLDED,
    "the sidebar folded to its edge: the strip of the bags hidden with it, kept")
local headArrow
for _, widget in ipairs(W.frames) do
    if widget._parent == sideFrame and widget.rail and widget.mark then headArrow = widget.mark end
end
check(headArrow:GetTexture():match("Journal\\arrow$") and math.abs(headArrow._rotation - math.pi / 2) < 1e-6
    and headArrow:GetWidth() == ns.Sidebars.TOGGLE, "folded: the head's pencil arrow, as large as a box, points right")
toggle:GetScript("OnClick")(toggle)
check(kept.side and Bags.strip:IsShown() and sideFrame:GetWidth() == ns.Sidebars.WIDTH,
    "the bags' button while folded: the sidebar unfolded, the strip shown")
check(math.abs(headArrow._rotation + math.pi / 2) < 1e-6, "unfolded: it points left, the way it folds")
local bagButtons = {}
for _, widget in ipairs(W.frames) do
    if widget._parent == Bags.strip and widget._kind == "Button" and widget:IsShown() then bagButtons[#bagButtons + 1] = widget end
end
check(#bagButtons == 7, "the bags in the strip: the backpack, four bag slots, the reagent bag's, the keyring")
check(Foot.BAG < Layout.SIZE and bagButtons[1]:GetWidth() == Foot.BAG and Foot.STRIP == Foot.BAG + 10,
    "the strip's slots a little smaller than the items")
do
    local function Picture(index) return Foot.Parts(bagButtons[index]) end
    local function Empty(index) return select(2, Foot.Parts(bagButtons[index])) end
    local ART = Categories.ART
    check(Picture(1)._texture == "Interface\\Icons\\ui-hud-actionbar-bag" and Picture(2)._texture == "bag-icon" and Picture(2):IsShown()
        and not Empty(2):IsShown(), "the backpack's icon, a bag's icon in its slot; no drawing over it")
    local reagent, keys = SIZES[5], bags[-1]
    SIZES[5], bags[-1] = 0, nil
    Foot.Bags()
    check(not Picture(4):IsShown() and Empty(4):IsShown() and Empty(4)._texture == ART .. Foot.EMPTY.bag
        and Empty(6):IsShown() and Empty(6)._texture == ART .. Foot.EMPTY.reagent
        and Empty(7):IsShown() and Empty(7)._texture == ART .. Foot.EMPTY.keyring,
        "an empty slot says what goes there: a bag's drawing, the reagent bag's, a keyring without keys'")
    SIZES[5], bags[-1] = reagent, keys
    Foot.Bags()
    check(Picture(7):IsShown() and Picture(7)._texture == "Interface\\Icons\\ui-hud-actionbar-keyring" and not Empty(7):IsShown(),
        "a keyring with keys: its icon")
    check(Empty(4):GetAlpha() == Foot.DRAWN and select(3, Foot.Parts(bagButtons[4])):GetAlpha() == ns.Cells.EMPTY_SLOT,
        "its drawing faded, its pencil slot at half strength")
    -- The game tells no icon for the slot: the item worn there's, else any bag's, never an empty look.
    local texture, itemID = GetInventoryItemTexture, GetInventoryItemID
    local icons = C_Item.GetItemIconByID
    GetInventoryItemTexture = function() return nil end
    GetInventoryItemID = function(_, slot) return slot == 31 and 804 or nil end
    C_Item.GetItemIconByID = function(item) return item == 804 and "item-icon" or nil end
    Foot.Bags()
    check(Picture(2)._texture == "item-icon" and Picture(2):IsShown(), "no icon from the slot: the item's worn there")
    C_Item.GetItemIconByID = function() return nil end
    Foot.Bags()
    check(Picture(2)._texture == Foot.BAG_ICON and not Picture(4):IsShown(), "none at all: a bag's, while the bag has slots; an empty slot stays empty")
    GetInventoryItemTexture, GetInventoryItemID, C_Item.GetItemIconByID = texture, itemID, icons
    Foot.Bags()
end
local freeOnIt
for _, widget in ipairs(W.frames) do
    if widget._parent == bagButtons[1] and widget._kind == "FontString" and widget._text == "11" then freeOnIt = widget end
end
check(freeOnIt, "a bag's free slots on it")
bagButtons[2]:GetScript("OnEnter")(bagButtons[2])
local lit = Cells.Button(1, 2).BagIndicator:IsShown() and not Cells.Button(0, 1).BagIndicator:IsShown()
bagButtons[2]:GetScript("OnLeave")(bagButtons[2])
check(lit and not Cells.Button(1, 2).BagIndicator:IsShown(), "the mouse on a bag: its items lit, the game's way; off: none")
bagButtons[2]:GetScript("OnClick")(bagButtons[2])
check(calls.pickedBag == 31, "a click on a bag picks it up")
cursor = true
bagButtons[3]:GetScript("OnReceiveDrag")(bagButtons[3])
bagButtons[1]:GetScript("OnClick")(bagButtons[1])
cursor = false
check(calls.putBag == 32 and calls.putBackpack, "a bag let go over a slot is put there; an item over the backpack, into it")
toggle:GetScript("OnClick")(toggle)
check(not Bags.strip:IsShown(), "hidden again")
toggle:GetScript("OnClick")(toggle)
check(Text("12345c"), "the gold, in the game's coins")
check(Text("12"), "a currency watched in the backpack")

-- A narrow window: the foot leaves out what does not fit, the currencies first, then the boxes' words.
do
    local token, box, gold = Text("12"):GetParent(), ns.Vendor.boxes[1], Text("12345c"):GetParent()
    Foot.Room(3000)
    check(token:IsShown() and box.text:IsShown(), "wide enough: all of it")
    Foot.Room(2 * (Bags.INSET + Bags.EDGE) + gold:GetWidth() + ns.Vendor.Width(true) + 1)
    check(not token:IsShown() and box.text:IsShown(), "less room: the currencies go first")
    Foot.Room(Bags.LEAST[1] - 200)
    check(not box.text:IsShown() and box:IsShown() and box:GetWidth() == ns.Vendor.BOX, "less still: the boxes' words, the boxes stay")
    Foot.Room(3000)
    check(token:IsShown() and box.text:IsShown() and box:GetWidth() > ns.Vendor.BOX, "wider again: all of it back")
    Bags.Size(1000, 600)
end
-- The window can be narrow; the first layout keeps it wide; the count on the bar makes room.
check(Bags.LEAST[1] <= 340 and Bags.Width > ns.Board.Least("bags", Bags.LEAST[1], Bags.LEAST[2])[1], "narrow at least, wider at first")
check(Bags.ItemSize(2000) == Layout.SIZE, "the items as large as chosen in a wide window")
kept.scale = 75
check(Bags.ItemSize(2000) == math.floor(Layout.SIZE * 0.75 + 0.5), "the slider's size")
kept.scale = 100
check(Bags.ItemSize(200) < Layout.SIZE, "smaller in a narrow one")

-- Auto Sell and Auto Repair: two boxes in the foot, ticked at first; a click takes off the tick and the setting.
shop.sell, shop.repair = Text("Auto Sell"):GetParent(), Text("Auto Repair"):GetParent()
do
local autoSell, autoRepair = shop.sell, shop.repair
check(autoSell:GetChecked() and autoRepair:GetChecked() and autoSell.tick:IsShown() and autoRepair.tick:IsShown(),
    "Auto Sell and Auto Repair: in the foot, ticked at first")
check(ns.Vendor.boxes[1] == autoRepair and ns.Vendor.boxes[2] == autoSell, "both left of the gold")
do
local makeRoom = ns.Vendor.boxes[3]
check(makeRoom and makeRoom == Text("Make Room"):GetParent() and makeRoom:GetChecked(), "Make Room beside them, ticked at first")
makeRoom:GetScript("OnClick")(makeRoom)
check(Core.Settings("Loot").full == false and not makeRoom:GetChecked() and not makeRoom.tick:IsShown() and ns.options.full == nil,
    "a click: that module's own switch, its tick follows, nothing of it kept here")
Core.Set("Loot", "full", true)
W.Wait(0)
check(makeRoom:GetChecked(), "changed on that module's page: the box follows")
end
check(autoSell:GetWidth() > ns.Vendor.BOX, "a box as wide as its word")
autoSell:GetScript("OnClick")(autoSell)
autoRepair:GetScript("OnClick")(autoRepair)
check(ns.options.autoSell == false and ns.options.autoRepair == false and not autoSell:GetChecked()
    and not autoRepair.tick:IsShown(), "a click takes off the tick and the setting")
check(Text("12345c"), "the bags stay as they were")
end

-- At a vendor with both off: nothing by itself; the junk sold, asked first.
merchantOpen = true
W.Fire("MERCHANT_SHOW")
W.Wait(0)
W.Wait(Foot.SOLD)
check(not calls.sold and #shop.repairs == 0, "both off: nothing is sold or repaired by itself")
local act = Text("Sell All Junk Items")
check(act, "at a vendor with junk: the button to sell it, on the bar")
act:GetParent():GetScript("OnClick")(act:GetParent())
popup = W.popups[#W.popups]
check(popup and popup.which == "GENERIC_CONFIRMATION" and not calls.sold, "asked first")
popup.data.callback()
check(calls.sold, "then sold, by the game")
check(Cells.Button(0, 2) and #Bags.blocks[1].entries > 1 or true, "at a vendor stacks are not merged")
local clothCells = 0
for _, button in ipairs(Cells.Each()) do
    local record = Cells.Record(button)
    if record and record.item == 2589 then clothCells = clothCells + 1 end
end
check(clothCells == 2, "at a vendor each stack is its own cell")
-- Junk marked by the player: each item sold as a click on it at the vendor sells it; not what is in a set.
Categories.MarkJunk(118, true)
Categories.MarkJunk(2001, true)
Bags.Refresh()
calls.sold, calls.used = nil, {}
C_Container.UseContainerItem = function(bag, slot) calls.used[#calls.used + 1] = bag .. ":" .. slot end
act:GetParent():GetScript("OnClick")(act:GetParent())
W.popups[#W.popups].data.callback()
check(#calls.used == 1, "the player's junk: sold one item at a time")
W.Wait(Foot.STEP)
W.Wait(Foot.STEP)
check(not calls.sold and table.concat(calls.used, ",") == "0:3,0:4", "the player's junk: each item sold, not the set's sword")
check(W.printed[#W.printed]:find("Junk sold: 2 for 28c", 1, true), "the chat says how many, for how much: " .. W.printed[#W.printed])
merchantOpen = false
calls.used = {}
act:GetParent():GetScript("OnClick")(act:GetParent())
W.popups[#W.popups].data.callback()
check(#calls.used == 0, "the vendor gone before the answer: nothing used")
merchantOpen = true
Categories.MarkJunk(118, false)
Categories.MarkJunk(2001, false)
Bags.Refresh()
merchantOpen = false
W.Fire("MERCHANT_CLOSED")
W.Wait(0)
check(not Text("Sell All Junk Items"), "the vendor gone: the button too")

-- Auto Sell and Auto Repair at work: the junk first, the repair after it, with the character's own money.
do
local autoSell, autoRepair = shop.sell, shop.repair
local function AtVendor()
    calls.sold, calls.used, shop.repairs = nil, {}, {}
    W.printed = {}
    merchantOpen = true
    W.Fire("MERCHANT_SHOW")
    W.Fire("MERCHANT_SHOW")
    W.Wait(0)
end
local function Away()
    W.Wait(Foot.SOLD)
    merchantOpen = false
    W.Fire("MERCHANT_CLOSED")
    W.Wait(0)
end
autoSell:GetScript("OnClick")(autoSell)
autoRepair:GetScript("OnClick")(autoRepair)
check(ns.options.autoSell and ns.options.autoRepair and autoSell:GetChecked() and autoRepair.tick:IsShown(), "ticked again")
C_Container.UseContainerItem = nil
local asked = #W.popups
AtVendor()
check(calls.sold and #W.popups == asked, "Auto Sell: the junk sold by the game, unasked, once though the event came twice")
check(#shop.repairs == 0, "the repair waits for the junk's money")
check(W.printed[1] and W.printed[1]:find("Junk sold: 1 for", 1, true), "the chat says what was sold: " .. tostring(W.printed[1]))
W.Wait(Foot.SOLD)
check(#shop.repairs == 1 and shop.repairs[1] == "own", "Auto Repair: then all the gear, with the character's own money")
check(W.printed[2] and W.printed[2]:find("Repaired for 250c", 1, true), "the chat says what it cost: " .. tostring(W.printed[2]))
Away()
Categories.MarkJunk(118, true)
C_Container.UseContainerItem = function(bag, slot) calls.used[#calls.used + 1] = bag .. ":" .. slot end
AtVendor()
check(not calls.sold and #calls.used == 1 and #shop.repairs == 0, "the player's junk too: one item at a time, no repair yet")
W.Wait(Foot.STEP)
W.Wait(Foot.STEP)
check(#calls.used == 2 and #shop.repairs == 1, "the repair after the last item")
Away()
Categories.MarkJunk(118, false)
Bags.Refresh()
shop.shift = true
AtVendor()
Away()
check(not calls.sold and #shop.repairs == 0, "Shift held: both left to the player")
shop.shift = false
Core.Set(ns.name, "autoSell", false)
AtVendor()
check(not calls.sold and #shop.repairs == 1, "Auto Sell off: only the repair, at once")
Away()
Core.Set(ns.name, "autoSell", true)
Core.Set(ns.name, "autoRepair", false)
AtVendor()
Away()
check(calls.sold and #shop.repairs == 0, "Auto Repair off: only the junk")
Core.Set(ns.name, "autoRepair", true)
check(autoSell:GetChecked() and autoRepair:GetChecked(), "a change on the settings page moves the ticks")
shop.cost = 20000
AtVendor()
Away()
check(calls.sold and #shop.repairs == 0, "more than the character has: no repair")
shop.cost, shop.can = 0, false
AtVendor()
Away()
check(#shop.repairs == 0, "nothing to repair")
shop.cost, shop.can, shop.repairer = 250, true, false
AtVendor()
Away()
check(#shop.repairs == 0, "a vendor who does not repair")
shop.repairer = true
AtVendor()
merchantOpen = false
W.Wait(Foot.SOLD)
check(#shop.repairs == 0, "the vendor gone before the repair: none")
W.Fire("MERCHANT_CLOSED")
W.Wait(0)
end

-------------------------------------------------------------------------------
--  The bank, a window of its own while at a banker
-------------------------------------------------------------------------------
ns.store.board.tabs[1].tree = { split = "x", parts = { { key = "bags" }, { key = "bank" } }, shares = { 0.6, 0.4 } }
ns.Window.Reboard()
check(not (ns.Board.Panel("bank") and ns.Board.Panel("bank"):IsShown()) and panel:IsShown(),
    "away from a banker: no bank window, the bags have the room")
bankOpen = true
W.Fire("BANKFRAME_OPENED")
W.Wait(0)
local Bank = ns.Bank
local bankPanel = ns.Board.Panel("bank")
check(bankPanel and bankPanel:IsShown() and bankPanel.title._text == "Bank", "at a banker: the bank's window comes")
local silver = Bank.cells:Button(6, 1)
check(silver and silver:IsShown() and silver:GetParent():GetID() == 6 and drawn[silver].texture == "icon6001",
    "its tabs' slots, the game's buttons, in a pool of its own")
check(not Cells.Shown(6, 1), "the bags show no bank")
local ores = HeadNamed("Ores")
check(ores and ores.number._text == "(1 / 8)" and Bank.cells:Shown(6, 8), "All Bank Tabs: each tab under its head, every slot")
local function BankRow(word)
    for _, bankRow in ipairs(Bank.rail:Rows()) do
        if bankRow.word == word and bankRow:IsShown() then return bankRow end
    end
end
check(BankRow("All Bank Tabs").bar:IsShown() and BankRow("One Bank") and BankRow("Ores") and BankRow("Ores").count._text == "1",
    "its sidebar: All Bank Tabs (shown), One Bank, each tab with its slots taken")
check(Text("1 / 8 Items"), "its bar: the bank's slots taken of how many")
-- Several tabs (the game's tab IDs follow on from 6): each in the sidebar, in its order, with its slots taken.
for id = 7, 10 do
    tabs[0][#tabs[0] + 1] = { ID = id, name = "Tab " .. id, icon = "tab-icon", depositFlags = 0 }
    SIZES[id] = 4
end
Put(9, 2, 7001, 1)
Bank.Refresh()
local listed = {}
for _, bankRow in ipairs(Bank.rail:Rows()) do
    if bankRow.tab and bankRow:IsShown() then listed[#listed + 1] = bankRow.tab end
end
check(table.concat(listed, ",") == "6,7,8,9,10" and BankRow("Tab 9").count._text == "1",
    "several tabs: each in the sidebar in its order, with its slots taken: " .. table.concat(listed, ","))
for id = 7, 10 do
    tabs[0][#tabs[0]] = nil
    SIZES[id] = nil
end
bags[9] = nil
Bank.Refresh()
-- Item data the bank did not wait for draws nothing anew, money only the gold; the data of one it waited for does.
Put(6, 2, 7001, 2)
local money = GetMoney
GetMoney = function() return 54321 end
W.Fire("GET_ITEM_INFO_RECEIVED", 2589)
W.Fire("PLAYER_MONEY")
W.Wait(0)
check(Contents.records[6][2].item == nil and Text("54321c"), "another item's data and money: only the gold anew")
Contents.waiting[7001] = true
W.Fire("GET_ITEM_INFO_RECEIVED", 7001)
W.Wait(0)
check(Contents.records[6][2].item == 7001 and not Contents.waiting[7001], "the data of an item it waited for: read and drawn anew")
GetMoney = money
bags[6][2] = nil
Bank.Refresh()
row = BankRow("One Bank")
row:GetScript("OnClick")(row, "LeftButton")
check(HeadNamed("Bank") and HeadNamed("Bank").number._text == "(1 / 8)", "One Bank: the bank's slots together")
row = BankRow("Ores")
row:GetScript("OnClick")(row, "LeftButton")
check(Bank.Viewing() == "tab:6" and Bank.cells:Shown(6, 1) and BankRow("Ores").bar:IsShown(), "a tab by itself")
local bankMenu
for _, widget in ipairs(W.frames) do
    if widget._generator and (rawget(widget, "word") or widget._override) == "View" and widget._parent and widget._parent._parent == bankPanel.body then bankMenu = widget end
end
bankMenu:GenerateMenu()
Choose(bankMenu._items, "Group by Category")
check(ns.store.bank.group and HeadNamed("Trade Goods") and Bank.cells:Shown(6, 1), "Group by Category: the bank's items by the bags' categories")
Choose(Line(ItemMenu(Bank.cells:Button(6, 1)), "Put Into").sub, "Professions")
check(kept.assigned[6001] == "professions" and HeadNamed("Professions"), "a bank item put into a category from its menu: the bank drawn anew")
Categories.Assign(6001, nil)
Bank.Refresh()
-- The bags' own choices about an item the bank holds too draw the bank anew: the middle click, the junk marker.
local function BankHolds(word, item)
    local blocks = Bank.blocks
    for index = 1, blocks and blocks.count or 0 do
        if blocks[index].word == word then
            for _, entry in ipairs(blocks[index].entries) do
                if entry.record.item == item then return true end
            end
        end
    end
    return false
end
Put(0, 6, 6001, 1)
Categories.Assign(6001, "professions")
Bags.Refresh()
Bank.Refresh()
local barInBags = Cells.Button(0, 6)
barInBags:GetScript("OnMouseUp")(barInBags, "MiddleButton")
check(kept.assigned[6001] == nil and BankHolds("Trade Goods", 6001) and not BankHolds("Professions", 6001),
    "a middle click in the bags takes the item out of its category: the bank drawn anew")
coinButton:GetScript("OnClick")(coinButton)
ns.Select.Click(Cells.Button(0, 6))
coinButton:GetScript("OnClick")(coinButton)
check(kept.assigned[6001] == "junk" and BankHolds("Junk", 6001), "marked as junk by the coin's clicks: in the bank's Junk too")
holding = 6001
coinButton:GetScript("OnClick")(coinButton)
check(holding == nil and kept.assigned[6001] == nil and BankHolds("Trade Goods", 6001) and not BankHolds("Junk", 6001),
    "brought to the coin, unmarked at once: the bank drawn anew too")
Categories.MarkJunk(6001, false, 2)
bags[0][6] = nil
Bags.Refresh()
Bank.Refresh()
bankMenu:GenerateMenu()
Choose(bankMenu._items, "Group by Category")
-- The list, under a column head of its own with the bags' columns.
bankMenu:GenerateMenu()
Choose(bankMenu._items, "List")
local bankRow = Bank.cells:Button(6, 1) and Bank.blocks and nil
for _, widget in ipairs(W.frames) do
    if widget.cells and widget.cells.name and widget.cells.name._text == "Silver Bar" and widget:IsShown() then bankRow = widget end
end
check(ns.store.bank.look == "list" and Bank.columns:IsShown() and ns.Columns.Cell("level", Bank.columns)
    and ns.Columns.Cell("level", Bank.columns) ~= ns.Columns.Cell("level") and bankRow and bankRow.cells.count._text == "3",
    "the bank as a list: a line per item under a column head of its own, the bags' columns")
local bankLevel = ns.Columns.Cell("count", Bank.columns)
bankLevel:GetScript("OnMouseDown")(bankLevel, "LeftButton")
bankLevel:GetScript("OnMouseUp")(bankLevel, "LeftButton")
check(kept.listSort == "count", "its head sorts as the bags' does (one choice for both)")
kept.listSort, kept.listDown = nil, nil
bankMenu:GenerateMenu()
Choose(bankMenu._items, "Grid")
check(not Bank.columns:IsShown() and Bank.cells:Shown(6, 1), "back to the grid: no head")
-- A tab's settings: its tooltip says what it takes; a right click its name and what it takes, by the game's call.
row = BankRow("Ores")
check(row.icon._texture == "tab-icon", "a tab by its own icon")
row:GetScript("OnEnter")(row)
check(GameTooltip._text == "Ores", "a tab's tooltip")
row:GetScript("OnLeave")(row)
row:GetScript("OnClick")(row, "RightButton")
local tabMenu = W.menus[#W.menus]
check(tabMenu[1].title == "Ores" and Line(tabMenu, "Rename") and Line(tabMenu, "Equipment") and Line(tabMenu, "Ignore in Clean Up"),
    "a right click on a tab: its settings")
check(not Line(tabMenu, "Reagents").checked(Line(tabMenu, "Reagents").data), "nothing assigned at first")
Choose(tabMenu, "Reagents")
check(calls.tabSettings and calls.tabSettings[1] == 0 and calls.tabSettings[2] == 6 and calls.tabSettings[3] == "Ores"
    and calls.tabSettings[4] == "tab-icon" and calls.tabSettings[5] == 128, "a kind of item assigned: the game's call, name and icon kept")
W.Fire("BANK_TAB_SETTINGS_UPDATED", 0)
W.Wait(0)
row = BankRow("Ores")
check(Line(tabMenu, "Reagents").checked(Line(tabMenu, "Reagents").data), "now ticked")
Choose(tabMenu, "Ignore in Clean Up")
check(calls.tabSettings[5] == 129, "left out of the clean-up as well")
Choose(tabMenu, "Reagents")
check(calls.tabSettings[5] == 1, "the kind taken back")
Choose(tabMenu, "Rename")
popup = W.popups[#W.popups]
check(popup.which == "GENERIC_INPUT_BOX" and popup.box.text == "Ores", "renamed in the game's dialog")
popup.data.callback("  Metals and more ore  ")
check(calls.tabSettings[3] == "Metals and more", "its new name, at most as long as the game's box takes")
W.Fire("BANK_TAB_SETTINGS_UPDATED", 0)
W.Wait(0)
check(BankRow("Metals and more"), "the tab by its new name")
tabs[0][1].name, tabs[0][1].depositFlags = "Ores", 0
W.Fire("BANK_TAB_SETTINGS_UPDATED", 0)
W.Wait(0)
-- Buying a tab: only the game's own button, laid over our row.
local buyRow = BankRow("Buy Tab")
local buyer
for _, widget in ipairs(W.frames) do
    if widget._attributes and widget._attributes.overrideBankType == 0 then buyer = widget end
end
check(buyRow and buyer and buyer:IsShown() and buyer._points[1][2] == buyRow, "Buy Tab: the game's button over our row")
buyer:GetScript("OnEnter")(buyer)
local costLine = false
for _, line in ipairs(GameTooltip._lines or {}) do costLine = costLine or line == "Cost: 50000c" end
check(buyRow.hover:IsShown() and GameTooltip._text == "Buy Tab" and costLine, "its tooltip: what it costs")
buyer:GetScript("OnLeave")(buyer)
buyer:GetScript("OnClick")(buyer)
check(calls.purchase == 0 and not calls.bought, "a click is the game's own: our code buys nothing")
local bankClean
for _, widget in ipairs(W.frames) do
    if widget._parent and widget._parent._parent == bankPanel.body and widget._scripts.OnClick and widget._kind == "Button"
        and widget:GetWidth() == ns.Bags.BAR_BUTTON then bankClean = widget end
end
bankClean:GetScript("OnClick")(bankClean)
check(calls.sortBank == 0, "the bank's clean-up: the game's, for that bank")
check(Bank.deposit:IsShown(), "at the bank: the button to put the reagents in")
Bank.deposit:GetScript("OnClick")(Bank.deposit)
check(calls.deposit == 0, "the reagents put into the bank, by the game")
silver = Bank.cells:Button(6, 1)
silver:GetScript("OnMouseUp")(silver, "MiddleButton")
check(kept.pinned[6001], "a middle click in the bank pins too")
Categories.Pin(6001, false)
bankOpen = false
W.Fire("BANKFRAME_CLOSED")
W.Wait(0)
check(not bankPanel:IsShown() and panel:IsShown(), "the bank closed: its window goes, the bags take the room")
ns.store.board.tabs[1].tree = { key = "bags" }
ns.Window.Reboard()
row = RowNamed("All Items")
row:GetScript("OnClick")(row, "LeftButton")

-------------------------------------------------------------------------------
--  In a fight, hidden, and again
-------------------------------------------------------------------------------
-- More cells than buttons made so far, in a fight: the ones missing wait for its end.
row = RowNamed("One Bag")
row:GetScript("OnClick")(row, "LeftButton")
W.combat = true
SIZES[3] = 16 -- a bag put on in a fight: more slots than ever shown
Put(3, 1, 7001, 1)
W.Fire("BAG_CONTAINER_UPDATE")
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Cells.short and not Cells.Shown(-1, 4) and Cells.Shown(0, 1), "in a fight the cells without a button yet wait; the others are drawn")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(not Cells.short and Cells.Shown(-1, 4) and Cells.Shown(3, 16), "after the fight: made and drawn")
row = RowNamed("All Items")
row:GetScript("OnClick")(row, "LeftButton")

Push()
check(not panel:IsShown(), "pushed again: the bags go")
Stand()
Put(0, 9, 7001, 1)
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(not Cells.Shown(0, 9), "hidden, the bags do not listen to the game")
Push()
Stand()
check(Cells.Shown(0, 9) and HeadNamed("The Armory"), "shown again: drawn as they are now, in the view it opens with")

-- Retail: no keyring (the game gives it no slots, and has no call that puts a key on it); the bags and their strip
-- without it, the rest as in WoW: Forever.
W.Play("retail")
SIZES[-1] = 0
W.Fire("BAG_CONTAINER_UPDATE")
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
local retailStrip = {}
for _, widget in ipairs(W.frames) do
    if widget._parent == Bags.strip and widget._kind == "Button" and widget:IsShown() then retailStrip[#retailStrip + 1] = widget end
end
check(table.concat(Contents.Carried({}), ",") == "0,1,2,3,5" and not Cells.Shown(-1, 1) and Cells.Shown(0, 9) and #retailStrip == 6,
    "Retail: the bags without the keyring, in the window and its strip: " .. table.concat(Contents.Carried({}), ",") .. ", " .. #retailStrip)
W.Play("forever")
SIZES[-1] = 4
W.Fire("BAG_CONTAINER_UPDATE")
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Cells.Shown(-1, 1), "back in WoW: Forever: the keyring again")

-- The box Speed Leveling: the profile in use. Last here: the bags' categories come anew with a profile.
function W.CheckLeveling()
    Core.Profiles.Use("Speedleveling")
    W.Wait(0)
    local leveling = ns.Vendor.boxes[4]
    check(leveling and leveling == Text("Speed Leveling"):GetParent() and leveling:GetChecked(), "Speed Leveling beside them, ticked on its profile")
    leveling:GetScript("OnClick")(leveling)
    W.Wait(0)
    check(Core.Profiles.InUse() == "Accountwide" and not leveling:GetChecked() and not leveling.tick:IsShown(), "a click: back on Accountwide, its tick follows")
    leveling:GetScript("OnClick")(leveling)
    W.Wait(0)
    check(Core.Profiles.InUse() == "Speedleveling" and leveling:GetChecked(), "and on the profile Speedleveling again")
end
W.CheckLeveling()

-- Equip and delete without asking (Asks.lua): the game's questions, answered by what their own Yes does.
function W.CheckAsks()
    local onCursor, answered, hidden, shown = true, {}, {}, {}
    local cursorWas = CursorHasItem
    CursorHasItem = function() return onCursor end
    local function Question(which)
        StaticPopupDialogs[which] = { OnAccept = function(_, data) answered[#answered + 1] = which .. ":" .. tostring(data) end }
    end
    for _, which in ipairs({ "EQUIP_BIND", "EQUIP_BIND_TRADEABLE", "EQUIP_BIND_REFUNDABLE", "DELETE_ITEM", "DELETE_GOOD_ITEM", "OTHER_QUESTION" }) do
        Question(which)
    end
    StaticPopupDialogs.DELETE_ITEM.OnAccept = function() answered[#answered + 1] = "deleted"; onCursor = false end
    StaticPopup_FindVisible = function(which) return shown[which] end
    StaticPopup_Hide = function(which) hidden[#hidden + 1] = which; shown[which] = nil end
    local showPopup = StaticPopup_Show
    local function Ask(which, data)
        local box = { text = "" }
        function box:IsShown() return true end
        function box:SetText(text) self.text = text end
        shown[which] = { which = which, data = data, GetEditBox = function() return box end }
        W.popups[#W.popups + 1] = shown[which]
        showPopup(which, nil, nil, data)
        return box
    end
    check(ns.options.noAsk == true, "on at first")
    Ask("EQUIP_BIND", 16)
    check(answered[1] == "EQUIP_BIND:16" and hidden[1] == "EQUIP_BIND", "equipping: answered, the question gone")
    Ask("OTHER_QUESTION", 1)
    check(#answered == 1 and #hidden == 1, "another question is the game's")
    Ask("DELETE_ITEM")
    W.Wait(1)
    check(answered[2] == "deleted", "destroying: answered, the item gone")
    Core.Set(ns.name, "noAsk", false)
    Ask("EQUIP_BIND", 16)
    check(#answered == 2, "off: the game asks")
    Core.Set(ns.name, "noAsk", true)
    -- The game refuses: the item stays on the cursor, the question stands with its word typed in; the next one is tried.
    DELETE_ITEM_CONFIRM_STRING = "DELETE"
    onCursor = true
    local box = Ask("DELETE_GOOD_ITEM")
    W.Wait(1)
    check(box.text == "DELETE", "refused: the word typed in")
    local count = #answered
    Ask("DELETE_GOOD_ITEM")
    check(#answered == count + 1, "the next one is tried again")
    CursorHasItem, StaticPopup_FindVisible, StaticPopup_Hide = cursorWas, nil, nil
end
W.CheckAsks()

-- One slot kept free (Bags/Room.lua).
function W.CheckRoom()
    local free, list, gone, picked, onCursor, refuse = 1, {}, {}, nil, false, false
    local numFree, junkOf, carriedOf, store = C_Container.GetContainerNumFreeSlots, Contents.Junk, Bags.Carried, Bags.Store
    local pick, cursorWas = C_Container.PickupContainerItem, CursorHasItem
    C_Container.GetContainerNumFreeSlots = function(bag) return bag == 0 and free or 0, 0 end
    Contents.Junk = function() return list end
    Bags.Carried = function() return { slots = {} } end
    Bags.Store = function() end
    C_Container.PickupContainerItem = function(bag, slot) picked, onCursor = bag .. ":" .. slot, true end
    CursorHasItem = function() return onCursor end
    DeleteCursorItem = function()
        if refuse then return end
        gone[#gone + 1], onCursor = picked, false
    end
    local errors = #W.errors
    local function Bagged()
        W.Fire("BAG_UPDATE_DELAYED")
        W.Wait(0)
    end
    local function Press()
        ns.Room.catcher:GetScript("OnKeyDown")(ns.Room.catcher, "W")
        W.Wait(1)
    end
    Bagged()
    check(ns.Room.catcher == nil and #W.errors == errors, "a slot free: nothing to do, nothing listens")
    free = 0
    Bagged()
    check(#W.errors == errors + 1 and W.errors[#W.errors]:find("no junk"), "full, and no junk: a warning on the screen")
    Bagged()
    check(#W.errors == errors + 1, "once a minute, not at every change of the bags")
    list = { { bag = 1, slot = 2, link = "[Rags]", sell = 5, count = 2 }, { bag = 1, slot = 3, link = "[Bone]", sell = 1, count = 3 },
             { bag = 1, slot = 4, link = "[Locked]", sell = 0, count = 1, locked = true } }
    Bagged()
    check(ns.Room.catcher and ns.Room.catcher:IsShown() and #gone == 0, "full, with junk: it waits for your next key")
    W.combat = true
    Press()
    check(#gone == 0 and not ns.Room.catcher:IsShown(), "in a fight: not then")
    W.combat = false
    Bagged()
    check(ns.Room.catcher:IsShown(), "after it, it waits again")
    Press()
    check(gone[1] == "1:3" and not ns.Room.catcher:IsShown(), "a key: the cheapest junk of all its stack goes")
    Core.Set("Loot", "full", false)
    W.Wait(0)
    Bagged()
    check(not ns.Room.catcher:IsShown(), "the switch off: nothing goes")
    Core.Set("Loot", "full", true)
    W.Wait(0)
    refuse = true
    local cleared = ClearCursor
    ClearCursor = function() onCursor = false end
    Bagged()
    Press()
    local warnings = #W.errors
    check(#gone == 1 and not onCursor and #W.errors == warnings, "refused by the game: back in the bags, no warning")
    Bagged()
    check(not ns.Room.catcher:IsShown(), "not at the very next key")
    refuse = false
    W.Wait(ns.Room.AGAIN)
    check(ns.Room.catcher:IsShown(), "a little later it waits for your key again")
    onCursor = true
    Press()
    check(#gone == 1, "something in your hand: not now")
    onCursor = false
    W.Wait(ns.Room.AGAIN)
    Press()
    check(gone[2] == "1:3", "and it goes")
    C_Container.GetContainerNumFreeSlots, Contents.Junk, Bags.Carried, Bags.Store = numFree, junkOf, carriedOf, store
    C_Container.PickupContainerItem, CursorHasItem, ClearCursor, DeleteCursorItem = pick, cursorWas, cleared, nil
end
W.CheckRoom()

for label, problem in pairs(Core.errors) do check(false, "no step failed on the way: " .. label .. ": " .. tostring(problem.text)) end
ns.StandDown("a test")
check(ns.off and not panel:IsShown(), "standing down: the bags go with the window")
calls.sold, shop.repairs = nil, {}
merchantOpen = true
W.Fire("MERCHANT_SHOW")
W.Wait(0)
W.Wait(Foot.SOLD)
check(not calls.sold and #shop.repairs == 0, "stood down: nothing sold or repaired")

io.write(("Bags: all %d checks passed.\n"):format(passed))
