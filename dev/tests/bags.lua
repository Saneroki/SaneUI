-- Runs the Inventory module's bags against the stand-in client (wowstub.lua): what the bags hold, read from a
-- stand-in of the game's containers; the views (every slot, the groups, the list, the compact one) laid out as
-- plain numbers and drawn with the game's item buttons; the search; the game's events while shown; the bank while
-- it is open; the foot (the bags, the free slots, selling junk, the gold). The window, the board and the other
-- parts are tried in dev/tests/inventory.lua. The look can only be judged in the game.
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
