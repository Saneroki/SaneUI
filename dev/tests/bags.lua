-- Runs the Inventory module's bags against the stand-in client (wowstub.lua): what the bags hold, read from a
-- stand-in of the game's containers; the views (every slot, the groups, the list, the compact one) laid out as
-- plain numbers and drawn with the game's item buttons; the search; the player's groups (pinned items, own groups,
-- the game's renamed, moved, hidden and joined, junk marked and unmarked) without a frame and by the window's menus
-- and drops; the game's events while shown; the bank while it is open; the foot (the bags, the free slots, selling
-- junk, the gold). The window, the board and the other parts are tried in dev/tests/inventory.lua. The look can
-- only be judged in the game.
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

-- The game's item button for a bag's slot (ContainerFrameItemButtonTemplate): its marks, and what its own
-- functions were told.
W.templates.ContainerFrameItemButtonTemplate = function(widget)
    widget.BagIndicator = W.NewWidget("Texture", nil, widget)
    widget.BagIndicator._shown = false
    widget._template = "ContainerFrameItemButtonTemplate"
    widget._shown = false -- hidden="true", as the game's template is
    function widget:SetMatchesSearch(on) self._matches = on end
    function widget:UpdateNewItem(quality) self._newDrawn = quality end
    function widget:SetHasItem(texture) self._has = texture end
    function widget:UpdateJunkItem(quality, noValue) self._junk = quality == 0 and not noValue end
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
Enum.BankType = { Character = 0, Account = 2 }
Enum.PlayerInteractionType = { Merchant = 5, Banker = 8 }
ITEM_QUALITY_COLORS = { [0] = { r = 0.6, g = 0.6, b = 0.6 }, [1] = { r = 1, g = 1, b = 1 }, [2] = { r = 0.1, g = 1, b = 0 },
                        [3] = { r = 0, g = 0.4, b = 1 } }

local SIZES = { [0] = 16, [1] = 8, [2] = 4, [3] = 0, [4] = 0, [5] = 4, [-1] = 4 }
local FAMILY = { [2] = 1 } -- bag 2 is a quiver
local ITEMS = { -- [item] = { name, class, quality, level }
    [2001] = { "Steel Sword", 2, 3, 20 }, [2589] = { "Linen Cloth", 7, 1 }, [118] = { "Minor Healing Potion", 0, 1 },
    [3001] = { "Broken Fang", 15, 0 }, [3002] = { "Wolf Pelt", 12, 1 }, [4001] = { "Shiny Ring", 4, 2, 12 },
    [2512] = { "Rough Arrow", 6, 1 }, [2447] = { "Peacebloom", 7, 1 }, [5001] = { "Cellar Key", 13, 1 },
    [6001] = { "Silver Bar", 7, 2 }, [7001] = { "Iron Ore", 7, 1 },
}
local bags = {} -- [bag] = { [slot] = { item, count, locked, new, quest } }
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
local bankOpen, merchantOpen, junk = false, false, 1
local calls = {}
local function Slot(bag, slot) return bags[bag] and bags[bag][slot] end
local function Size(bag)
    if bag >= 6 and not bankOpen then return 0 end
    return SIZES[bag] or 0
end
C_Container = {
    GetContainerNumSlots = function(bag) return Size(bag) end,
    GetContainerItemInfo = function(bag, slot)
        local entry = Slot(bag, slot)
        if not entry or slot > Size(bag) then return nil end
        local item = ITEMS[entry.item]
        return { itemID = entry.item, stackCount = entry.count, quality = item[3], iconFileID = "icon" .. entry.item,
                 hyperlink = "|cffffffff|Hitem:" .. entry.item .. "|h[" .. item[1] .. "]|h|r", itemName = item[1],
                 isLocked = entry.locked or false, isBound = false, hasNoValue = false, isReadable = false }
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
    GetBagName = function(bag) return ({ [2] = "Quiver", [5] = "Herb Pouch" })[bag] or ("Bag " .. bag) end,
    ContainerIDToInventoryID = function(bag) return 30 + bag end,
    HasContainerItem = function(bag, slot) return Slot(bag, slot) ~= nil end,
    SortBags = function() calls.sortBags = (calls.sortBags or 0) + 1 end,
    SortBank = function(kind) calls.sortBank = kind end,
}
C_NewItems = { IsNewItem = function(bag, slot) local entry = Slot(bag, slot) return entry and entry.new or false end }
C_Item = {
    GetItemInfoInstant = function(item)
        local info = ITEMS[item]
        return item, "type", "subtype", info[2] == 2 and "INVTYPE_WEAPON" or "", "icon", info[2], 0
    end,
    GetDetailedItemLevelInfo = function(link)
        local item = tonumber(link:match("item:(%d+)"))
        return ITEMS[item] and ITEMS[item][4]
    end,
}
C_Bank = {
    FetchPurchasedBankTabIDs = function(kind) return kind == 0 and { 6 } or {} end,
    CanViewBank = function() return true end,
    DoesBankTypeSupportAutoDeposit = function(kind) return kind == 0 end,
    AutoDepositItemsIntoBank = function(kind) calls.deposit = kind end,
}
SIZES[6] = 8
Put(6, 1, 6001, 3)
C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
    return kind == 8 and bankOpen or kind == 5 and merchantOpen end }
C_MerchantFrame = { SellAllJunkItems = function() calls.sold = true end, IsSellAllJunkEnabled = function() return true end,
                    GetNumJunkItems = function() return junk end }
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end,
                   GetBackpackCurrencyInfo = function(index) if index == 1 then return { quantity = 12, iconFileID = "honor" } end end }
GetMoney = function() return 12345 end
local cursor = false
CursorHasItem = function() return cursor end
local alt = false
IsAltKeyDown = function() return alt end
PickupBagFromSlot = function(slot) calls.pickedBag = slot end
PutItemInBag = function(slot) calls.putBag = slot end
PutItemInBackpack = function() calls.putBackpack = true end
GetInventoryItemTexture = function(_, slot) return slot == 31 and "bag-icon" or nil end
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

-------------------------------------------------------------------------------
--  What the bags hold, without a frame
-------------------------------------------------------------------------------
local carried = Contents.Carried({})
check(table.concat(carried, ",") == "0,1,2,5,-1", "the bags carried: the backpack, the bags with slots, the reagent bag, the keyring")
local slots, free = Contents.Scan(carried, "bags", {}, Contents.ClearFree({}))
check(#slots == 36, "every slot read")
check(slots[1].name == "Steel Sword" and slots[1].group == "weapons" and slots[1].level == 20, "an item: its name, group, item level")
check(slots[2].group == "trade" and slots[2].count == 20 and not slots[2].level, "a trade good: no item level")
check(slots[4].group == "junk" and slots[5].group == "quest" and slots[16 + 2].group == "new", "junk, a quest's item, a new item")
check(free.count == 17 and free.total == 24 and table.concat(free.kinds, ",") == "bags,2,5,-1",
    "the free slots by kind: the ordinary bags together, the quiver, the reagent bag, the keyring each by itself")
check(free[2].count == 3 and free[2].bag == 2 and free[2].slot == 2 and free[-1].count == 3, "a kind's free slots and its first free one")
local list = {}
for _, record in ipairs(slots) do if record.item then list[#list + 1] = record end end
Contents.Sort(list, "name", false)
check(list[1].name == "Broken Fang" and list[#list].name == "Wolf Pelt", "sorted by name")
Contents.Sort(list, "quality", true)
check(list[1].group == "new" and list[2].name == "Steel Sword" and list[#list].group == "junk",
    "grouped: new first, then the game's groups in their order, junk last")
check(Contents.Found(slots[2], Core.Fuzzy.Query("linen")) and not Contents.Found(slots[1], Core.Fuzzy.Query("linen"))
    and Contents.Found(slots[1], Core.Fuzzy.Query("weap")), "found by its name or its group's")

-- The layout: whole cells in lines as wide as the room.
local sections = { { place = "bags", slots = slots, free = free } }
local places = {}
local count, height = Layout.Lay("slots", sections, 10 * (Layout.SIZE + Layout.GAP) - Layout.GAP, nil, "quality", places)
local first, kinds = nil, 0
for index = 1, count do
    if places[index].kind == "cell" and not first then first = places[index] end
    if places[index].kind == "head" then kinds = kinds + 1 end
end
check(kinds == 4 and first.record.bag == 0 and first.record.slot == 1 and first.x == 0, "every slot in the bags' order, a head per kind of bag")
local tenth, eleventh
for index = 1, count do
    local place = places[index]
    if place.kind == "cell" and place.record.bag == 0 and place.record.slot == 10 then tenth = place end
    if place.kind == "cell" and place.record.bag == 0 and place.record.slot == 11 then eleventh = place end
end
check(tenth.x == 9 * (Layout.SIZE + Layout.GAP) and eleventh.x == 0 and eleventh.y == tenth.y + Layout.SIZE + Layout.GAP,
    "ten to a line where ten fit, the next line under it")
check(height > 0, "the layout's height")

-------------------------------------------------------------------------------
--  The player's groups, without a frame
-------------------------------------------------------------------------------
local Groups = ns.Groups
local chosen = {}
Groups.Use(chosen)
check(Groups.list[1] == "pinned" and Groups.list[2] == "new" and Groups.list[3] == "weapons" and Groups.list[#Groups.list] == "junk",
    "the groups in the game's order, Pinned and New first, Junk last")
-- Each record placed anew, as the window reads the bags after a choice.
local function Again()
    for _, record in ipairs(slots) do
        if record.item then Contents.Place(record, record.new) end
    end
end
local function HeadOf(key)
    for index = 1, count do
        if places[index].kind == "head" and places[index].group == key then return places[index] end
    end
end
local function CellOf(record)
    for index = 1, count do
        if places[index].kind == "cell" and places[index].record == record then return places[index] end
    end
end
local linen, potion, fang, pelt, herb = slots[2], slots[3], slots[4], slots[5], slots[29]
check(herb.item == 2447 and slots[17].item == 2589, "the records the checks use")

-- Pinned.
Groups.Pin(2589, true)
Again()
check(linen.group == "pinned" and slots[17].group == "pinned" and linen.home == "trade" and chosen.pinned[2589],
    "a pinned item: in Pinned, every stack of it, its own group kept")
Contents.Sort(list, "quality", true)
check(list[1].group == "pinned" and list[2].group == "pinned" and list[3].group == "new", "Pinned first, above New")
count = Layout.Lay("groups", sections, 400, nil, "quality", places)
check(places[1].group == "pinned" and places[1].word == "Pinned" and places[1].number == 2, "its head at the top, with how many")
Groups.Pin(2589, false)
Again()
check(linen.group == "trade" and chosen.pinned[2589] == nil, "unpinned: back in its group, nothing kept")

-- Junk marked and unmarked.
Groups.MarkJunk(118, true, potion.natural, Contents.Classed(potion))
Again()
check(potion.group == "junk" and potion.junk and chosen.put[118] == "junk", "an item marked as junk: in Junk, junk to sell")
local junk, same = Contents.Junk(slots, {})
check(#junk == 2 and junk[1] == potion and junk[2] == fang and not same, "the junk: the marked item and the grey one; not just the game's")
Groups.MarkJunk(118, false, potion.natural, Contents.Classed(potion))
Again()
check(potion.group == "consumables" and not potion.junk and chosen.put[118] == nil, "unmarked: back in its own group, nothing kept")
Groups.MarkJunk(3001, false, fang.natural, Contents.Classed(fang))
Again()
check(fang.group == "other" and not fang.junk and chosen.put[3001] == "other", "a grey item unmarked: in the group of its kind, no junk")
junk, same = Contents.Junk(slots, {})
check(#junk == 0 and not same, "no junk; the game would still sell the grey one")
Groups.MarkJunk(3001, true, fang.natural, Contents.Classed(fang))
Again()
junk, same = Contents.Junk(slots, {})
check(fang.junk and chosen.put[3001] == nil and #junk == 1 and same, "marked again: just the game's junk, nothing kept")
Groups.Pin(3001, true)
Again()
check(not fang.junk and fang.home == "junk", "a pinned item is never junk to sell")
Groups.Pin(3001, false)
Again()

-- The player's own groups.
local herbs = Groups.New("  Herbs  ")
check(herbs == "own1" and Groups.Word(herbs) == "Herbs" and Groups.Own(herbs) and Groups.list[3] == herbs,
    "a group of the player's own: named, at the top under New")
check(Groups.New("   ") == nil and Groups.New("Bones") == "own2", "none without a name; the next its own key")
count = Layout.Lay("groups", sections, 400, nil, "quality", places)
check(HeadOf(herbs) and HeadOf(herbs).number == 0 and HeadOf(herbs).word == "Herbs" and HeadOf("own2"),
    "an empty group of the player's own shows its head, to drop items on")
count = Layout.Lay("groups", sections, 400, Core.Fuzzy.Query("linen"), "quality", places)
check(not HeadOf(herbs), "not while searching")
count = Layout.Lay("compact", sections, 400, nil, "quality", places)
check(not HeadOf(herbs), "nor in the compact view, which has no heads")
check(Groups.PutInto(2447, herbs, herb.natural) and Groups.PutInto(2589, herbs, linen.natural), "items put into it")
Again()
check(herb.group == herbs and linen.group == herbs and slots[17].group == herbs and chosen.put[2447] == herbs, "they show in it, kept")
count = Layout.Lay("groups", sections, 400, nil, "quality", places)
check(HeadOf(herbs).number == 3 and not HeadOf("trade") and CellOf(herb).y > HeadOf(herbs).y, "under its head; Trade Goods empty, gone")
check(Groups.PutInto(2447, "trade", herb.natural) and chosen.put[2447] == nil, "put into its own group: taken out, nothing kept")
Groups.PutInto(2447, herbs, herb.natural)
check(Groups.PutInto(2447, "pinned", herb.natural) and chosen.pinned[2447] and chosen.put[2447] == herbs, "put into Pinned: pinned, its group kept")
Groups.PutInto(2447, herbs, herb.natural)
check(not chosen.pinned[2447], "put into a group: pinned no more")
check(not Groups.PutInto(2447, "new", herb.natural) and not Groups.PutInto(2447, "own9", herb.natural), "not into New, nor a group there is not")
Again()

-- Hidden.
check(Groups.Hide(herbs, true), "a group hidden")
count = Layout.Lay("groups", sections, 400, nil, "quality", places)
check(not HeadOf(herbs) and not CellOf(linen), "its head and items left out")
count = Layout.Lay("list", sections, 400, nil, "quality", places)
check(not HeadOf(herbs), "in the list too")
count = Layout.Lay("groups", sections, 400, Core.Fuzzy.Query("linen"), "quality", places)
check(HeadOf(herbs) and CellOf(linen), "found by a search all the same")
count = Layout.Lay("compact", sections, 400, nil, "quality", places)
check(not CellOf(linen) and CellOf(slots[1]), "left out of the compact view")
count = Layout.Lay("slots", sections, 400, nil, "quality", places)
check(CellOf(linen), "the view of every slot shows every slot")
Groups.Hide(herbs, false)
check(not chosen.groups[herbs].hidden, "shown again")

-- Renamed.
check(Groups.Rename("weapons", " Blades ") and Groups.Word("weapons") == "Blades" and chosen.groups.weapons.word == "Blades",
    "a group of the game's renamed")
check(Contents.Found(slots[1], Core.Fuzzy.Query("blades")), "its items found by its new name")
check(Groups.Rename("weapons", "") and Groups.Word("weapons") == "Weapons" and chosen.groups.weapons == nil,
    "no name: the game's again, nothing kept")
check(not Groups.Rename(herbs, "  ") and Groups.Word(herbs) == "Herbs" and Groups.Rename(herbs, "Plants") and Groups.Word(herbs) == "Plants",
    "the player's own keeps its name when given none")
check(not Groups.Rename("pinned", "Top") and not Groups.Hide("new", true), "Pinned and New stay as they are")

-- Joined.
check(Groups.Join("quest", "other"), "a group of the game's joined into another")
Again()
check(pelt.group == "other" and pelt.home == "quest", "its items show in that one")
count = Layout.Lay("groups", sections, 400, nil, "quality", places)
check(not HeadOf("quest") and HeadOf("other").number == 2, "its head gone, the other's counting them")
check(not Groups.Join("junk", "other") and not Groups.Join("weapons", "junk") and not Groups.Join("armor", "quest")
    and not Groups.Join(herbs, "other") and not Groups.Join("weapons", "weapons"),
    "Junk never joins nor takes in; nor does a joined group, nor joins one of the player's own, nor itself")
check(not Groups.Takes("quest") and Groups.Takes("other") and not Groups.Takes("junk"), "items go into no joined group")
check(Groups.Join("quest", nil) and chosen.groups.quest == nil, "shown by itself again, nothing kept")
Again()
check(pelt.group == "quest", "its items back under its head")

-- Moved.
local shown = { weapons = true, consumables = true, [herbs] = true }
check(not Groups.Move(herbs, -1, shown, true) and Groups.Move(herbs, 1, shown, true), "the first under New does not move up")
check(Groups.Move("consumables", -1, shown), "moved up")
check(Groups.rank.consumables == Groups.rank.weapons - 1 and Groups.rank[herbs] < Groups.rank.consumables and chosen.ranks[3] == "consumables",
    "past the group shown above it, in the player's order, kept")
check(Groups.Move("consumables", 1, nil) and Groups.rank.consumables == Groups.rank.weapons + 1, "down past the next")
check(not Groups.Move("junk", 1, nil, true) and not Groups.Move("pinned", 1, nil), "nothing moves below the last; Pinned stays")

-- Deleted.
Groups.Join("trade", herbs)
check(Groups.Delete(herbs) and not Groups.Delete("trade"), "a group of the player's own deleted; none of the game's")
Again()
check(linen.group == "trade" and chosen.put[2589] == nil and chosen.groups.trade == nil and Groups.rank[herbs] == nil
    and chosen.ranks[1] == "own2", "its items back in their own groups, the group joined into it by itself again")
Groups.Delete("own2")

-- What is kept is never trusted.
local messy = { pinned = { [1] = true, x = true, [2] = "yes" }, put = { [3] = "trade", [4] = 5 }, ranks = { "armor", 5 },
                groups = { pinned = { word = "Top" }, own7 = { own = true }, armor = { into = 3, hidden = "yes" }, made = { word = "x" } } }
Groups.Check(messy)
check(messy.pinned[1] and messy.pinned.x == nil and messy.pinned[2] == nil and messy.put[3] == "trade" and messy.put[4] == nil,
    "kept pins and groups of items: only those of the right kind")
check(messy.groups.pinned == nil and messy.groups.own7.word == "Group" and messy.groups.armor.into == nil
    and messy.groups.armor.hidden == nil and messy.groups.made == nil and #messy.ranks == 1,
    "kept groups: no Pinned, an own one named, wrong values gone, none that is not there")
check(Groups.Check({ ranks = "no" }).ranks == nil, "an order that is no list: the game's")
Groups.Use({})
Again()

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
local function Placed()
    local list = {}
    for _, button in ipairs(Cells.Each()) do list[#list + 1] = button end
    return list
end
Push()
Stand()
local panel = ns.Board.Panel("bags")
check(panel and panel:IsShown() and panel.title._text == "Bags", "the bags on the full screen, headed Bags")
for label in pairs(Core.errors) do check(not label:find("bags"), "no problem noted: " .. label) end

-- The groups (the first view).
local sword = Cells.Button(0, 1)
check(sword._template == "ContainerFrameItemButtonTemplate" and sword:GetID() == 1 and sword:GetParent():GetID() == 0,
    "each item the game's own item button, its slot its ID, its bag its holder's ID")
check(not (sword._attributes and sword._attributes.bagid), "nothing of ours written into the game's button (no bag attribute)")
check(drawn[sword].texture == "icon2001" and drawn[sword].quality == 3 and sword:IsShown(), "drawn the game's way")
local ring = Cells.Button(1, 2)
local function Y(button) return -button._points[1][5] * (button._scale or 1) end
check(Y(ring) == Layout.HEAD and Y(sword) > Y(ring), "the new item first, under its head; the sword's group below it")
local free0 = Cells.Button(0, 6)
check(free0:IsShown() and drawn[free0].count == 17 and not Cells.Shown(0, 7),
    "the free slots: a cell for the ordinary bags' first free one, with how many")
check(Cells.Button(2, 2):IsShown() and drawn[Cells.Button(2, 2)].count == 3, "a cell for the quiver's free ones")

-- The search: in the groups, what is not found is left out.
ns.Board.Search("linen")
local shown = Placed()
check(#shown == 2 and Cells.Button(0, 2):IsShown() and Cells.Button(1, 1):IsShown() and not sword:IsShown(),
    "searching: only the items found, every stack, no free slots")
ns.Board.Search("")

-- The views, by the dropdown.
local menu = {}
for _, widget in ipairs(W.frames) do
    if widget._generator and widget._override == "View" then menu = widget end
end
check(menu._generator, "the dropdown View on the panel's head")
local function Pick(text)
    menu:GenerateMenu()
    for _, item in ipairs(menu._items) do
        if item.text == text then item.fn(item.data) return true end
    end
end
check(Pick("All"), "the view of every slot can be chosen")
check(ns.store.bags.view == "slots", "the view kept")
check(Cells.Button(0, 7):IsShown() and drawn[Cells.Button(0, 7)].texture == nil, "every slot: the empty ones too, the game's empty slot")
ns.Board.Search("linen")
check(sword:IsShown() and sword._matches == false and Cells.Button(0, 2)._matches == true,
    "every slot: what is not found is dimmed (the game's own dimming), not left out")
check(Cells.Button(0, 7)._matches == true, "an empty slot is not dimmed by a search")
ns.Board.Search("")

check(Pick("List"), "the list can be chosen")
local row = Bags.rowOf[sword]
check(row and row:IsShown() and row.name._text == "Steel Sword" and row.level._text == 20, "the list: a line per item, its name and item level")
local inset = (Layout.ROW - Layout.ICON) / 2
check(sword._scale == Layout.ICON / Layout.SIZE and math.abs(-sword._hit[2] * sword._scale - (row._width - inset - Layout.ICON)) < 1e-6,
    "its item button small at the line's left, its click reaching over the rest of the line")
check(row.name._color[3] == 1 and row.name._color[1] == 0, "the name in its quality's colour")

check(Pick("Compact"), "the compact view can be chosen")
check(sword._scale == Layout.SMALL / Layout.SIZE and sword._hit[2] == 0, "compact: smaller, the click on the button only")
check(Pick("Categories"), "back to the groups")

-- Sorting.
check(Pick("Name") and ns.store.bags.order == "name", "sorted by name, kept")
Pick("Quality")

-------------------------------------------------------------------------------
--  Pinned items, the player's groups, junk: on the window
-------------------------------------------------------------------------------
local function Line(menu, text)
    for _, line in ipairs(menu or {}) do
        if line.text == text then return line end
    end
end
local function Choose(menu, text) -- a line of a menu clicked
    local line = Line(menu, text)
    line.fn(line.data)
    return line
end
local function HeadNamed(word)
    for _, widget in ipairs(W.frames) do
        if widget.clean and widget.word._text == word and widget:IsShown() then return widget end
    end
end
local function ItemMenu(button)
    alt = true
    button:GetScript("OnClick")(button, "RightButton")
    alt = false
    return W.menus[#W.menus]
end
local function HeadMenu(word)
    local head = HeadNamed(word)
    head:GetScript("OnMouseUp")(head, "RightButton")
    return W.menus[#W.menus]
end
local kept = ns.store.bags

local menus = #W.menus
sword:GetScript("OnClick")(sword, "RightButton")
check(#W.menus == menus, "a right click on an item: the game's own, no menu of ours")
local menu = ItemMenu(sword)
check(menu[1].title == "Steel Sword" and Line(menu, "Pinned") and Line(menu, "Junk") and Line(menu, "Put Into"),
    "Alt and a right click on an item: its menu")
check(not Line(menu, "Pinned").checked(), "not pinned yet")
Choose(menu, "Pinned")
check(kept.pinned[2001] and Y(sword) == Layout.HEAD and Y(ring) > Y(sword) and HeadNamed("Pinned"),
    "pinned, kept: at the top under Pinned, above New")
menu = ItemMenu(sword)
check(Line(menu, "Pinned").checked(), "its menu says so")
Choose(menu, "Pinned")
check(not kept.pinned[2001] and not HeadNamed("Pinned") and Y(ring) == Layout.HEAD, "unpinned: back in its group")

-- Junk.
local flask = Cells.Button(0, 3)
check(not flask._junk and Cells.Button(0, 4)._junk, "the vendor's coin on the grey item only")
menu = ItemMenu(flask)
Choose(menu, "Junk")
check(kept.put[118] == "junk" and flask._junk, "marked as junk, kept; the vendor's coin on it")
check(Line(ItemMenu(flask), "Junk").checked(), "its menu says so")
Choose(ItemMenu(flask), "Junk")
check(kept.put[118] == nil and not flask._junk, "unmarked")
menus = #W.menus
ItemMenu(Cells.Button(0, 7))
check(#W.menus == menus, "an empty slot has no menu")

-- Put into a group, a new one, taken out.
menu = ItemMenu(flask)
local into = Line(menu, "Put Into")
check(Line(into.sub, "Weapons") and Line(into.sub, "Consumables").checked("consumables") and not Line(into.sub, "Junk")
    and not Line(into.sub, "Pinned") and not Line(into.sub, "New"), "Put Into: the groups items go in, its own ticked")
Choose(into.sub, "New Group")
local popup = W.popups[#W.popups]
check(popup.which == "GENERIC_INPUT_BOX", "a new group named in the game's dialog")
popup.data.callback("Potions")
check(kept.groups.own1.word == "Potions" and kept.put[118] == "own1" and HeadNamed("Potions") and flask:IsShown(),
    "made, the item put into it, under its head")
menu = ItemMenu(flask)
check(Line(Line(menu, "Put Into").sub, "Potions").checked("own1"), "its menu ticks it")
Choose(menu, "Take Out of Potions")
check(kept.put[118] == nil and HeadNamed("Potions") and HeadNamed("Potions").number._text == "0",
    "taken out; the empty group keeps its head")

-- Let go over a group's head.
local holding
GetCursorInfo = function() if holding then return "item", holding, "link" end end
ClearCursor = function() holding = nil end
local head = HeadNamed("Potions")
head:GetScript("OnEnter")(head)
check(not head.lit:IsShown(), "nothing held: the head is not lit")
head:GetScript("OnLeave")(head)
holding = 118
head:GetScript("OnEnter")(head)
check(head.lit:IsShown(), "an item brought over a group's head: lit")
head:GetScript("OnReceiveDrag")(head)
check(kept.put[118] == "own1" and holding == nil, "let go there: put into that group, the item back in its slot")
head:GetScript("OnLeave")(head)
holding = 118
head = HeadNamed("Weapons")
head:GetScript("OnMouseUp")(head, "LeftButton")
check(kept.put[118] == "weapons" and holding == nil, "picked up and clicked on a head: the same")
holding = 118
head = HeadNamed("New")
head:GetScript("OnReceiveDrag")(head)
check(holding == 118 and kept.put[118] == "weapons", "New takes nothing: the item stays held")
holding = nil
GetCursorInfo = function() return nil end

-- A group's menu.
menu = HeadMenu("Potions")
check(menu[1].title == "Potions" and Line(menu, "Rename") and Line(menu, "Delete") and Line(menu, "Hide") and not Line(menu, "Join With"),
    "a right click on a head of the player's own group: its menu")
check(Line(menu, "Move Up").disabled and not Line(menu, "Move Down").disabled, "the top one moves down only")
Choose(menu, "Rename")
popup = W.popups[#W.popups]
check(popup.box.text == "Potions", "renamed in the game's dialog, the name in it")
popup.data.callback("Flasks")
check(HeadNamed("Flasks") and not HeadNamed("Potions"), "renamed")
Choose(HeadMenu("Flasks"), "Move Down")
check(Groups.rank.own1 > Groups.rank.weapons, "moved down past the next group shown")
menu = HeadMenu("Weapons")
local join = Line(menu, "Join With")
check(join and Line(join.sub, "Armor") and Line(join.sub, "Flasks") and not Line(join.sub, "Junk") and not Line(join.sub, "Weapons"),
    "a group of the game's joins another, not Junk, not itself")
Choose(join.sub, "Armor")
check(not HeadNamed("Weapons") and HeadNamed("Armor") and sword:IsShown() and kept.groups.weapons.into == "armor",
    "joined: its items under the other's head, kept")
Choose(HeadMenu("Armor"), "Show Weapons by Itself")
check(HeadNamed("Weapons") and kept.groups.weapons == nil, "shown by itself again")
Choose(HeadMenu("Flasks"), "Hide")
check(not HeadNamed("Flasks") and kept.groups.own1.hidden, "hidden")
menu = {}
for _, widget in ipairs(W.frames) do
    if widget._generator and widget._override == "View" then menu = widget end
end
menu:GenerateMenu()
local groupsMenu = Line(menu._items, "Groups")
check(groupsMenu and not Line(groupsMenu.sub, "Flasks").checked("own1") and Line(groupsMenu.sub, "Junk").checked("junk"),
    "the dropdown View: every group, ticked while shown")
Choose(groupsMenu.sub, "Flasks")
check(HeadNamed("Flasks") and not kept.groups.own1.hidden, "shown again from there")
check(Pick("New Group"), "a new group from the dropdown too")
W.popups[#W.popups].data.callback("Keys")
check(HeadNamed("Keys") and kept.groups.own2.word == "Keys", "made")
Choose(HeadMenu("Keys"), "Delete")
popup = W.popups[#W.popups]
check(popup.which == "GENERIC_CONFIRMATION" and HeadNamed("Keys"), "deleting asks first")
popup.data.callback()
check(not HeadNamed("Keys") and kept.groups.own2 == nil, "deleted")
menu = HeadMenu("New")
check(menu[1].title == "New" and not Line(menu, "Rename") and Line(menu, "New Group"), "New's head: only a new group")

-- Back to the game's groups for the checks that follow.
for _, key in ipairs({ "pinned", "put", "groups" }) do kept[key] = {} end
kept.ranks = nil
Groups.Use(kept)
Bags.Refresh()
check(not HeadNamed("Flasks") and Y(ring) == Layout.HEAD, "the game's groups again")

-------------------------------------------------------------------------------
--  The game's events while shown
-------------------------------------------------------------------------------
Put(1, 3, 7001, 2)
W.Fire("BAG_UPDATE", 1)
W.Fire("BAG_UPDATE_DELAYED")
check(not Cells.Shown(1, 3), "a burst of bag events: drawn once it is over")
W.Wait(0)
check(Cells.Shown(1, 3) and drawn[Cells.Button(1, 3)].texture == "icon7001", "a new item in the bags: drawn")
bags[0][2].locked = true
W.Fire("ITEM_LOCK_CHANGED", 0, 2)
check(drawn[Cells.Button(0, 2)].grey == true, "an item picked up: grey")
bags[0][2].locked = false
W.Fire("ITEM_LOCK_CHANGED", 0, 2)

-- A new item stays in New while the window is open.
bags[1][2].new = false
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Y(ring) < Y(sword), "the game's new mark gone (the mouse was on it): still new while the window is open")

-- The clean-up: the game's own.
local clean
for _, widget in ipairs(W.frames) do
    if widget._parent == panel.head and widget._scripts.OnClick and widget._scripts.OnEnter then clean = widget end
end
clean:GetScript("OnClick")(clean)
check(calls.sortBags == 1, "the clean-up button: the game's clean-up of the bags")
W.combat = true
clean:GetScript("OnClick")(clean)
W.combat = false
check(calls.sortBags == 1, "not in a fight")

-------------------------------------------------------------------------------
--  The foot
-------------------------------------------------------------------------------
local bagButtons = {}
for _, widget in ipairs(W.frames) do
    if widget._parent == Foot.frame and widget._kind == "ItemButton" and widget:IsShown() then bagButtons[#bagButtons + 1] = widget end
end
check(#bagButtons == 7, "the bags in the foot: the backpack, four bag slots, the reagent bag's, the keyring")
check(drawn[bagButtons[2]].texture == "bag-icon" and drawn[bagButtons[4]].texture == "empty-bag", "a bag's icon, an empty slot's picture")
bagButtons[2]:GetScript("OnEnter")(bagButtons[2])
local lit, unlit = Cells.Button(1, 1).BagIndicator:IsShown(), not sword.BagIndicator:IsShown()
bagButtons[2]:GetScript("OnLeave")(bagButtons[2])
check(lit and unlit and not Cells.Button(1, 1).BagIndicator:IsShown(), "the mouse on a bag: its items lit, the game's way; off: none")
bagButtons[2]:GetScript("OnClick")(bagButtons[2])
check(calls.pickedBag == 31, "a click on a bag picks it up")
cursor = true
bagButtons[3]:GetScript("OnReceiveDrag")(bagButtons[3])
bagButtons[1]:GetScript("OnClick")(bagButtons[1])
cursor = false
check(calls.putBag == 32 and calls.putBackpack, "a bag let go over a slot is put there; an item over the backpack, into it")
local gold
for _, widget in ipairs(W.frames) do
    if widget._parent == Foot.frame and widget.text and widget.text._text == "12345c" then gold = widget end
end
check(gold, "the gold, in the game's coins")
local found
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == "16 free" and widget._parent == Foot.frame then found = widget end
end
check(found, "the free slots of the ordinary bags")

-- At a vendor: the junk sold, asked first.
merchantOpen = true
W.Fire("MERCHANT_SHOW")
W.Wait(0)
local act
for _, widget in ipairs(W.frames) do
    if widget._parent == panel.head and widget._text == "Sell All Junk Items" then act = widget end
end
check(act and act:IsShown(), "at a vendor with junk: the button to sell it, on the head")
act:GetScript("OnClick")(act)
local popup = W.popups[#W.popups]
check(popup and popup.which == "GENERIC_CONFIRMATION" and not calls.sold, "asked first")
popup.data.callback()
check(calls.sold, "then sold, by the game")
-- Junk marked by the player: each item sold as a click on it at the vendor sells it.
Groups.MarkJunk(118, true, "consumables", "consumables")
Bags.Refresh()
calls.sold, calls.used = nil, {}
C_Container.UseContainerItem = function(bag, slot) calls.used[#calls.used + 1] = bag .. ":" .. slot end
act:GetScript("OnClick")(act)
W.popups[#W.popups].data.callback()
check(not calls.sold and table.concat(calls.used, ",") == "0:3,0:4", "the player's junk: each item sold, the marked one and the grey one")
merchantOpen = false
calls.used = {}
act:GetScript("OnClick")(act)
W.popups[#W.popups].data.callback()
check(#calls.used == 0, "the vendor gone before the answer: nothing used")
merchantOpen = true
Groups.MarkJunk(118, false, "consumables", "consumables")
Bags.Refresh()
merchantOpen = false
W.Fire("MERCHANT_CLOSED")
W.Wait(0)
check(not act:IsShown(), "the vendor gone: the button too")

-------------------------------------------------------------------------------
--  The bank, while it is open
-------------------------------------------------------------------------------
bankOpen = true
W.Fire("BANKFRAME_OPENED")
W.Wait(0)
local bar = Cells.Button(6, 1)
check(bar and bar:IsShown() and bar:GetParent():GetID() == 6, "at the bank: its tabs' items after the bags, the game's buttons")
local bankHead
for _, widget in ipairs(W.frames) do
    if widget.word and widget.word._text == "Bank" and widget:IsShown() then bankHead = widget end
end
check(bankHead and bankHead.clean:IsShown(), "the bank under a head of its own, with its clean-up")
bankHead.clean:GetScript("OnClick")(bankHead.clean)
check(calls.sortBank == 0, "the bank's clean-up: the game's, for that bank")
local deposit
for _, widget in ipairs(W.frames) do
    if widget._parent == panel.head and widget._text == "Deposit All Reagents" then deposit = widget end
end
check(deposit and deposit:IsShown(), "at the bank: the button to put the reagents in")
deposit:GetScript("OnClick")(deposit)
check(calls.deposit == 0, "the reagents put into the bank, by the game")
bankOpen = false
W.Fire("BANKFRAME_CLOSED")
W.Wait(0)
check(not bar:IsShown() and not deposit:IsShown(), "the bank closed: its items go")

-------------------------------------------------------------------------------
--  In a fight, hidden, and again
-------------------------------------------------------------------------------
W.combat = true
SIZES[3] = 4 -- a bag put on in a fight: slots never shown before
Put(3, 1, 7001, 1)
W.Fire("BAG_CONTAINER_UPDATE")
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(Cells.short and not Cells.Shown(3, 1) and Cells.Shown(0, 1), "in a fight a slot first shown waits for its button; the others are drawn")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(Cells.Shown(3, 1), "after the fight: made and drawn")

Push()
check(not panel:IsShown(), "pushed again: the bags go")
Stand()
Put(0, 7, 7001, 1)
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(0)
check(not Cells.Shown(0, 7), "hidden, the bags do not listen to the game")
Push()
Stand()
check(Cells.Shown(0, 7), "shown again: drawn as they are now")
check(Y(ring) > Y(sword), "the new item in its own group the next time the window opens")

for label, problem in pairs(Core.errors) do check(false, "no step failed on the way: " .. label .. ": " .. tostring(problem.text)) end
ns.StandDown("a test")
check(ns.off and not panel:IsShown(), "standing down: the bags go with the window")

io.write(("Bags: all %d checks passed.\n"):format(passed))
