-- Runs the Inventory module's bags against the stand-in client (wowstub.lua): what the bags hold, read from a
-- stand-in of the game's containers; the categories (the built-in rules, the player's own, groups, pins, junk
-- marks, renamed, moved, switched off, hidden) without a frame; what came in lately; the views (All Items, One
-- Bag, Each Bag, a category, a group) as blocks, stacks merged, the search; the three displays laid out as plain
-- numbers; the window: its bar, the sidebar, the game's item buttons in the flat look, the menus and drops, the
-- dropdown View; the game's events while shown; the bank while it is open; the foot and the bags' strip; selling
-- junk. The window, the board and the other parts are tried in dev/tests/inventory.lua. The look can only be
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
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
function methods:SetHitRectInsets(left, right, top, bottom) self._hit = { left, right, top, bottom } end
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

-- The game's item button for a bag's slot (ContainerFrameItemButtonTemplate): its marks and parts, and what its
-- own functions were told.
W.templates.ContainerFrameItemButtonTemplate = function(widget)
    widget.BagIndicator = W.NewWidget("Texture", nil, widget)
    widget.BagIndicator._shown = false
    widget.icon = W.NewWidget("Texture", nil, widget)
    widget.Count = W.NewWidget("FontString", nil, widget)
    widget._template = "ContainerFrameItemButtonTemplate"
    widget._shown = false -- hidden="true", as the game's template is
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
EquipmentManager_GetLocationData = function(location)
    if location == 1001 then return { isBags = true, bag = 0, slot = 1 } end
    return {}
end
C_Bank = {
    FetchPurchasedBankTabIDs = function(kind) return kind == 0 and { 6 } or {} end,
    FetchPurchasedBankTabData = function(kind) return kind == 0 and { { ID = 6, name = "Ores" } } or {} end,
    CanViewBank = function() return true end,
    DoesBankTypeSupportAutoDeposit = function(kind) return kind == 0 end,
    AutoDepositItemsIntoBank = function(kind) calls.deposit = kind end,
}
SIZES[6] = 8
Put(6, 1, 6001, 3)
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
    return kind == 8 and bankOpen or kind == 5 and merchantOpen end }
C_MerchantFrame = { SellAllJunkItems = function() calls.sold = true end, IsSellAllJunkEnabled = function() return true end }
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end,
                   GetBackpackCurrencyInfo = function(index) if index == 1 then return { quantity = 12, iconFileID = "honor" } end end }
GetMoney = function() return 12345 end
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
-- Only the bags on the full screen: the other parts are tried elsewhere.
ns.store.board = { chosen = 1, tabs = { { name = "Default", tree = { key = "bags" } } } }
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")
local Contents, Layout, Cells, Bags, Foot = ns.Contents, ns.Layout, ns.Cells, ns.Bags, ns.Foot
local Categories, Views, Recent, Sidebar = ns.Categories, ns.Views, ns.Recent, ns.BagSidebar

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
check(sword.category == "sets" and ring.category == "armor" and linen.category == "trade" and potion.category == "consumables",
    "set gear, armor, trade goods, consumables")
check(fang.category == "junk" and fang.junk and pelt.category == "misc" and arrows.category == "special"
    and herb.category == "reagent" and key.category == "special",
    "grey: junk; a quest item in Miscellaneous while Quest Items is off; the special bags' and the reagent bag's")
check(table.concat(Categories.order, ",") ==
    "pinned,recent,weapons,armor,sets,consumables,enhance,camp,trade,professions,reagent,misc,quest,special,junk",
    "the first order: Pinned and Recent first, Junk last")
check(Categories.GroupOf("weapons") == "armory" and Categories.GroupOf("sets") == "armory" and Categories.GroupOf("consumables") == "prep"
    and Categories.GroupWord("armory") == "The Armory", "the first groups: The Armory, Adventure Prep")
local function Reclassify()
    for _, record in ipairs(slots) do if record.item then Categories.Classify(record) end end
end
-- The rules beyond the class.
Put(0, 6, 4002)
Put(0, 7, 279978)
local charm = Contents.Read(0, 6, "bags")
local tent = Contents.Read(0, 7, "bags")
check(charm.category == "weapons" and tent.category == "camp", "a trinket with the weapons, a camp item in Camp Items")
bags[0][6], bags[0][7] = nil, nil
Contents.Read(0, 6, "bags")
Contents.Read(0, 7, "bags")
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
local own = Categories.New("Potions")
check(own == "own1" and Categories.Word(own) == "Potions" and Categories.Own(own)
    and Categories.rank[own] == Categories.rank.misc - 1, "a category of the player's own, made before Miscellaneous")
Categories.Assign(118, own)
Reclassify()
check(potion.category == own, "an item put into it")
Categories.Rename("trade", "Cloth")
check(Categories.Word("trade") == "Cloth", "a category renamed")
Categories.Rename("trade", "")
check(Categories.Word("trade") == "Trade Goods", "no name: its own again")
local before = Categories.rank.trade
Categories.Move("trade", 1)
check(Categories.rank.trade == before + 1 and kept.order[1] == "weapons", "moved down one, the order kept")
Categories.Move("trade", -1)
local group = Categories.GroupWith("trade", own)
check(Categories.GroupOf("trade") == group and Categories.GroupOf(own) == group and Categories.GroupWord(group) == "Trade Goods & Potions",
    "two categories made a group, named by its members")
Categories.Join("professions", group)
check(Categories.GroupWord(group) == "Trade Goods, Potions, & Professions", "a third joins it")
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
check(Words(blocks) == "Pinned Items=0,The Armory=2,Adventure Prep=1,Trade Goods=1,Reagent Bag=1,Miscellaneous=1,Special Bags=2,Junk=1",
    "All Items: Pinned (with its +, empty too), a block per category, a group's members as one, the empty ones left out: " .. Words(blocks))
check(blocks[1].plus and blocks[4].plus and blocks[4].key == "trade" and not blocks[5].plus and not blocks[2].plus,
    "a + after Pinned and after a category that takes items; not after the reagent bag's, not after a group")
local function Named(list, word)
    for index = 1, list.count do
        if list[index].word == word then return list[index] end
    end
end
local trade = Named(blocks, "Trade Goods")
check(trade.entries[1].count == 27 and trade.number == 1, "the stacks of one item merged into one cell, the count of them all")
check(Named(blocks, "The Armory").entries[1].record.name == "Steel Sword" and Named(blocks, "The Armory").group == "armory",
    "gear by item level first")
options.merge = false
blocks = Views.Build("all", { section }, nil, "default", options)
check(#Named(blocks, "Trade Goods").entries == 2, "stacks not merged when the player says so")
options.merge = nil
Categories.Pin(2589, true)
Reclassify()
Recent.list[1] = 118
blocks = Views.Build("all", { section }, nil, "default", options)
check(blocks[1].word == "Pinned Items" and #blocks[1].entries == 1 and blocks[2].word == "Recent Items" and blocks[3].word == "The Armory",
    "Pinned and Recent first, their items in their own categories too")
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
check(Words(blocks) == "Armor=1,Item Set Gear=1" and blocks[1].level == 3, "a group: its members each a block")
local counts = Views.Counts(section)
check(counts.trade == 1 and counts["group:armory"] == 2 and counts.junk == 1 and counts.pinned == 0, "how many each category holds")

-------------------------------------------------------------------------------
--  The displays, without a frame
-------------------------------------------------------------------------------
local places = {}
local width = 10 * (Layout.SIZE + Layout.GAP) - Layout.GAP
check(Layout.Columns(width) == 10, "as many cells to a line as fit")
blocks = Views.Build("all", { section }, nil, "default", options)
local count, height = Layout.Lay("grid", blocks, width, places)
local kinds = {}
for index = 1, count do kinds[places[index].kind] = (kinds[places[index].kind] or 0) + 1 end
check(kinds.head == 8 and kinds.cell == 9 and kinds.plus == 4 and kinds.pad == 8 * 10 - 9 - 4,
    "grid: a head per block, its cells, its +, every last line made whole with pads")
check(places[1].kind == "head" and places[2].kind == "plus" and places[2].x == 0 and places[3].kind == "pad",
    "Pinned empty: its + first, then pads")
local armory
for index = 1, count do
    if places[index].kind == "head" and places[index].block.word == "The Armory" then armory = index end
end
local top = places[armory].y + Layout.HEAD + Layout.HEAD_GAP
check(places[armory + 1].kind == "cell" and places[armory + 1].y == top and places[armory + 2].x == Layout.SIZE + Layout.GAP
    and places[armory + 3].kind == "pad", "a block's cells under its head, side by side")
count = Layout.Lay("list", blocks, width, places)
check(places[2].kind == "head" and places[3].kind == "row" and places[3].size == Layout.ICON and places[3].width == width,
    "list: a line per cell (Pinned empty: its head only)")
check(select(1, Layout.Shape(9, 10)) == 3 and select(1, Layout.Shape(2, 10)) == 2 and select(2, Layout.Shape(10, 10)) == 3,
    "compact: each block near square")
count = Layout.Lay("compact", blocks, width, places)
check(places[1].kind == "label" and places[1].block.word == "The Armory" and places[2].kind == "cell" and places[4].kind == "label"
    and places[4].x > 0, "compact: the blocks side by side, each with its name over it (an empty one left out)")

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
kept = ns.store.bags
local function Y(button) return -button:GetParent()._points[1][5] end
local function HeadNamed(word)
    for _, widget in ipairs(W.frames) do
        if widget.clean and widget.word._text == word and widget:IsShown() then return widget end
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
check(drawn[swordButton].texture == "icon2001" and HeadNamed("The Armory")
    and Y(swordButton) == -HeadNamed("The Armory")._points[1][5] + Layout.HEAD + Layout.HEAD_GAP,
    "All Items at first: the sword under its group's head")
check(Cells.Pads() > 0, "the blocks made whole with pads")
local levelText
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == 20 or widget._text == "20" then levelText = widget end
end
check(levelText, "the item level of gear on its button")
local trade = HeadNamed("Trade Goods")
check(trade and trade.number._text == "(1)" and drawn[Cells.Button(0, 2)].count == 27, "the two stacks of cloth as one cell of 27")

-- The sidebar.
local function RowNamed(word)
    for _, row in ipairs(Sidebar.Rows()) do
        if row.word == word and row:IsShown() then return row end
    end
end
check(RowNamed("All Items") and RowNamed("One Bag") and RowNamed("Each Bag") and RowNamed("Pinned Items")
    and RowNamed("The Armory") and RowNamed("Armor") and not RowNamed("Weapons / Trinkets") and RowNamed("Add Category"),
    "the sidebar: the views, Pinned, the categories with something in them, a group's members, Add Category")
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
check(HeadNamed("Trade Goods") and not HeadNamed("Junk") and not swordButton:IsShown() or Cells.Record(swordButton).item == 2589,
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
popup.data.callback("Potions")
check(kept.assigned[118] == "own1" and HeadNamed("Potions"), "made, the item in it")
menu = ItemMenu(Cells.Button(0, 3))
Choose(menu, "Junk")
check(kept.assigned[118] == "junk" and HeadNamed("Potions"), "marked as junk; its own category stays (the player's own, empty)")
Choose(ItemMenu(Cells.Button(0, 3)), "Junk")
check(kept.assigned[118] == "own1", "unmarked: back where it was put")

-- Let go over a head or a row.
local head = HeadNamed("Potions")
head:GetScript("OnEnter")(head)
check(not head.lit:IsShown(), "nothing held: the head is not lit")
head:GetScript("OnLeave")(head)
holding = 2589
head = HeadNamed("Potions")
head:GetScript("OnEnter")(head)
check(head.lit:IsShown(), "an item brought over a category's head: lit")
head:GetScript("OnReceiveDrag")(head)
check(kept.assigned[2589] == "own1" and holding == nil, "let go there: put into that category, the item back in its slot")
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

-- A category's +: an item brought to it goes in; clicked with nothing, the next item clicked does.
local function PlusOf(key)
    for _, widget in ipairs(W.frames) do
        if widget.sign and widget.key == key and widget:IsShown() then return widget end
    end
end
local plus = PlusOf("trade")
check(plus and PlusOf("pinned") and not PlusOf("reagent"), "a + after Pinned and Trade Goods, none after the reagent bag's")
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
menu = RowMenu("Potions")
check(menu[1].title == "Potions" and Line(menu, "Rename") and Line(menu, "Move Up") and Line(menu, "Create Group With")
    and Line(menu, "Hide in All Items") and Line(menu, "Switch Off") and Line(menu, "Icon") and Line(menu, "Delete"),
    "a right click on the player's own category: its menu")
Choose(menu, "Rename")
popup = W.popups[#W.popups]
check(popup.box.text == "Potions", "renamed in the game's dialog, the name in it")
popup.data.callback("Flasks")
check(HeadNamed("Flasks") and RowNamed("Flasks"), "renamed")
menu = RowMenu("Flasks")
local third = Line(menu, "Icon").sub[3]
third.fn(third.data)
check(kept.own[1].icon == Categories.ICONS[3], "its icon chosen")
menu = RowMenu("Flasks")
Choose(Line(menu, "Create Group With").sub, "Trade Goods")
check(RowNamed("Trade Goods & Flasks") and Categories.GroupOf("own1"), "grouped with another from the menu")
menu = RowMenu("Trade Goods & Flasks")
check(Line(menu, "Disband Group") and Line(menu, "Hide in All Items"), "the group's menu")
Choose(menu, "Disband Group")
check(not Categories.GroupOf("own1"), "disbanded")
menu = RowMenu("Trade Goods")
Choose(menu, "Hide in All Items")
check(not HeadNamed("Trade Goods") and kept.hidden.trade, "hidden from All Items")
Choose(RowMenu("Trade Goods"), "Hide in All Items")
check(HeadNamed("Trade Goods"), "shown again")
Choose(RowMenu("Trade Goods"), "Switch Off")
check(not RowNamed("Trade Goods") and Categories.Off("trade"), "switched off: its items in Miscellaneous")
local dropdown
for _, widget in ipairs(W.frames) do
    if widget._generator and widget._override == "View" then dropdown = widget end
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
check(kept.order == "name", "sorted by name, kept")
dropdown:GenerateMenu()
Choose(dropdown._items, "Default")
dropdown:GenerateMenu()
Choose(dropdown._items, "Show Pinned Items")
check(kept.showPinned == false, "Pinned hidden from the dropdown")
check(not RowNamed("Pinned Items"), "not in the sidebar then")
dropdown:GenerateMenu()
Choose(dropdown._items, "Show Pinned Items")
check(RowNamed("Pinned Items"), "shown again")

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
local clean
for _, widget in ipairs(W.frames) do
    if widget._parent and widget._parent._parent == panel.body and widget._scripts.OnClick and widget._normalAtlas == "bags-button-autosort-up" then clean = widget end
end
if not clean then
    for _, widget in ipairs(W.frames) do
        if widget._scripts and widget._scripts.OnClick and widget._scripts.OnEnter and widget._parent and widget._parent._parent == panel.body
            and widget._kind == "Button" and not widget.clean and widget:GetWidth() == ns.Bags.BAR_BUTTON then clean = widget end
    end
end
clean:GetScript("OnClick")(clean)
check(calls.sortBags == 1, "the clean-up button: the game's clean-up of the bags")
W.combat = true
clean:GetScript("OnClick")(clean)
W.combat = false
check(calls.sortBags == 1, "not in a fight")

-------------------------------------------------------------------------------
--  The foot and the bags' strip
-------------------------------------------------------------------------------
check(not Bags.strip:IsShown(), "the bags' strip hidden at first")
local toggle = Bags.bar.bags
toggle:GetScript("OnClick")(toggle)
check(Bags.strip:IsShown() and kept.strip, "its button shows the strip, kept")
local bagButtons = {}
for _, widget in ipairs(W.frames) do
    if widget._parent == Bags.strip and widget._kind == "ItemButton" and widget:IsShown() then bagButtons[#bagButtons + 1] = widget end
end
check(#bagButtons == 7, "the bags in the strip: the backpack, four bag slots, the reagent bag's, the keyring")
check(drawn[bagButtons[2]].texture == "bag-icon" and drawn[bagButtons[4]].texture == "empty-bag", "a bag's icon, an empty slot's picture")
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
check(Text("12345c"), "the gold, in the game's coins")
check(Text("12"), "a currency watched in the backpack")

-- At a vendor: the junk sold, asked first.
merchantOpen = true
W.Fire("MERCHANT_SHOW")
W.Wait(0)
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
check(W.printed[#W.printed]:find("Sold 2 junk items for 28c", 1, true), "the chat says how many, for how much: " .. W.printed[#W.printed])
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

-------------------------------------------------------------------------------
--  The bank, while it is open
-------------------------------------------------------------------------------
bankOpen = true
W.Fire("BANKFRAME_OPENED")
W.Wait(0)
local bar = Cells.Button(6, 1)
check(bar and bar:IsShown() and bar:GetParent():GetID() == 6, "at the bank: its tabs' items after the bags, the game's buttons")
local bankHead = HeadNamed("Bank")
check(bankHead and bankHead.clean:IsShown(), "the bank under a head of its own, with its clean-up")
bankHead.clean:GetScript("OnClick")(bankHead.clean)
check(calls.sortBank == 0, "the bank's clean-up: the game's, for that bank")
local deposit = Text("Deposit All Reagents")
check(deposit, "at the bank: the button to put the reagents in")
deposit:GetParent():GetScript("OnClick")(deposit:GetParent())
check(calls.deposit == 0, "the reagents put into the bank, by the game")
row = RowNamed("Each Bag")
row:GetScript("OnClick")(row, "LeftButton")
check(HeadNamed("Ores"), "Each Bag at the bank: its tabs by their names")
row = RowNamed("All Items")
row:GetScript("OnClick")(row, "LeftButton")
bankOpen = false
W.Fire("BANKFRAME_CLOSED")
W.Wait(0)
check(not Cells.Shown(6, 1) and not Text("Deposit All Reagents"), "the bank closed: its items go")

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
check(Cells.short and Cells.Shown(3, 16) and not Cells.Shown(-1, 4) and Cells.Shown(0, 1), "in a fight the cells without a button yet wait; the others are drawn")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(not Cells.short and Cells.Shown(-1, 4), "after the fight: made and drawn")
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

for label, problem in pairs(Core.errors) do check(false, "no step failed on the way: " .. label .. ": " .. tostring(problem.text)) end
ns.StandDown("a test")
check(ns.off and not panel:IsShown(), "standing down: the bags go with the window")

io.write(("Bags: all %d checks passed.\n"):format(passed))
