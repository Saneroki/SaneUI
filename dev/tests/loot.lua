-- Runs the Loot module against the stand-in client (wowstub.lua): the game's loot window and roll frames kept out
-- of the way and given back, the open loot read into lines, what the rules take at once (and what never), the window
-- with its lines (bars by quality, a quest's gold), clicks (take, link, the loot list), Link and Close as bare words,
-- the lines closing up under the mouse, a slot cleared and changed, the game's Auto Loot,
-- full bags (a thing the rules could not take shows again; the page that makes room, the cheapest first), the master
-- looter's menu, the game's sentences read back, the roll cards (choices offered, a choice made, who chose what,
-- the time line), the feed (merged lines, the group's by quality, money, what was taken at once, a big pile, a hidden
-- line), Retail's path, and standing down.
-- The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/loot.lua

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
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:GetStringWidth() return #(tostring(self._text or "")) * 6 end
function methods:GetStringHeight() return 12 end
function methods:GetEffectiveScale() return 1 end
function methods:GetVerticalScroll() return self._scroll or 0 end
function methods:SetVerticalScroll(at) self._scroll = at end
function methods:Click(button) if self._scripts.OnClick then self._scripts.OnClick(self, button or "LeftButton") end end
function methods:SetColorTexture(r, g, b, a) self._color = { r, g, b, a or 1 } end

-- The game's sentences about loot (English).
LOOT = "Loot"
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
LOOT_ITEM = "%s receives loot: %s."
LOOT_ITEM_MULTIPLE = "%s receives loot: %sx%d."
LOOT_ITEM_PUSHED_SELF = "You receive item: %s."
LOOT_ROLL_NEED = "%s has selected Need for: %s"
LOOT_ROLL_GREED = "%s has selected Greed for: %s"
LOOT_ROLL_PASSED = "%s passed on: %s"
LOOT_ROLL_NEED_SELF = "You have selected Need for: %s"
LOOT_ROLL_WON = "%s won: %s"
YOU_LOOT_MONEY = "You loot %s"
LOOT_MONEY_SPLIT = "Your share of the loot is %s."
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
CURRENCY_GAINED = "You receive currency: %s."
CURRENCY_GAINED_MULTIPLE = "You receive currency: %s x%d."
ERR_INV_FULL = "Inventory is full."
ITEM_BIND_ON_PICKUP, ITEM_BIND_ON_EQUIP = "Binds when picked up", "Binds when equipped"
INVTYPE_CHEST = "Chest"
for index, name in ipairs({ "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }) do
    _G["ITEM_QUALITY" .. (index - 1) .. "_DESC"] = name
end
ITEM_QUALITY_COLORS = {}
for quality = 0, 5 do ITEM_QUALITY_COLORS[quality] = { r = 0.2 * quality, g = 0.5, b = 0.5 } end
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 }, WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
LOOT_ROLL_INELIGIBLE_REASON2 = "You cannot use this."
SOUNDKIT = { UI_CONTAINER_ITEM_OPEN = 1, FISHING_REEL_IN = 2 }

Enum.LootSlotType = { None = 0, Item = 1, Money = 2, Currency = 3 }
Enum.LootMethod = { Freeforall = 0, Roundrobin = 1, Masterlooter = 2, Group = 3, Needbeforegreed = 4, Personal = 5 }

-- What the game knows of items: [link] = { name, quality, kind, where, icon, worth, bind }
local items = {}
local function Link(id, name) return ("|cff1eff00|Hitem:%d::::::::|h[%s]|h|r"):format(id, name) end
local function Item(id, name, quality, worth, bind, where, class)
    local link = Link(id, name)
    items[link] = { name = name, quality = quality, kind = "Armor", sub = "Cloth", where = where or "", icon = 1000 + id,
                    worth = worth or 0, bind = bind, class = class or 4, level = 10, subclass = 1 }
    return link
end
local CLOTH = Item(2589, "Linen Cloth", 1, 13, nil, nil, 7)
local ROBE = Item(6000, "Apprentice Robe", 2, 120, 2, "INVTYPE_CHEST")
local RING = Item(7000, "Bound Ring", 3, 900, 1)
local TUSK = Item(8000, "Boar Tusk", 1, 5, nil, nil, 15)
local GEM = Item(9000, "Shiny Gem", 4, 5000, nil, nil, 3)
local BREAD = Item(4540, "Tough Hunk of Bread", 1, 1, nil, nil, 0)
local SCRAP = Item(3300, "Rabbit's Foot", 0, 4, nil, nil, 15)
C_Item.GetItemInfo = function(link)
    local item = items[link] or items[Link(tonumber(link) or 0, "?")]
    if type(link) == "number" then
        for known, entry in pairs(items) do
            if known:match("item:(%d+)") == tostring(link) then item = entry end
        end
    end
    if not item then return nil end
    return item.name, link, item.quality, item.level, item.needs or 1, item.kind, item.sub, 20, item.where, item.icon, item.worth,
        item.class, item.subclass, item.bind
end
C_Item.GetItemCount = function() return 7 end
-- What the character wears ([place] = link) and whether the game says it can use an item ([item ID] = false: not).
local worn, unusable = {}, {}
INVSLOT_HEAD, INVSLOT_CHEST, INVSLOT_WAIST, INVSLOT_MAINHAND, INVSLOT_OFFHAND = 1, 5, 6, 16, 17
INVSLOT_FINGER1, INVSLOT_FINGER2 = 11, 12
GetInventoryItemLink = function(_, place) return worn[place] end
C_PlayerInfo = { CanUseItem = function(id) return unusable[id] ~= true end }
C_CurrencyInfo = {
    GetCoinTextureString = function(copper) return ("%dc"):format(copper) end,
    GetCurrencyInfoFromLink = function() return { name = "Honor", iconFileID = 500, quality = 1, quantity = 40 } end,
}

-- The open loot: a slot = { kind, icon, name, count, quality, locked, questItem, questID, active, link, currency }
local loot = {}
local taken, closed, linked = {}, 0, nil
GetNumLootItems = function() return #loot end
GetLootSlotInfo = function(slot)
    local s = loot[slot]
    if not s or s.gone then return nil end
    return s.icon, s.name, s.count or 1, s.currency, s.quality or 1, s.locked or false, s.questItem or false, s.questID,
        s.active or false, s.kind == 2
end
GetLootSlotType = function(slot)
    local s = loot[slot]
    if not s or s.gone then return 0 end
    return s.kind or 1
end
GetLootSlotLink = function(slot) return loot[slot] and loot[slot].link end
LootSlot = function(slot) taken[#taken + 1] = slot end
CloseLoot = function() closed = closed + 1 end
IsFishingLoot = function() return false end
IsAltKeyDown = function() return W.alt or false end
HandleModifiedItemClick = function(link) linked = link end
-- Without a name, any modified click (the game's own use in its loot window).
IsModifiedClick = function(action)
    if action == nil then return W.modifier ~= nil end
    return W.modifier == action
end
UnitExists = function(unit) return unit == "target" end
UnitIsDead = function(unit) return unit == "target" end
UnitIsUnit = function(a, b) return a == b end
IsInRaid = function() return W.raid or false end

local function Slot(link, extra)
    local item = items[link]
    local s = { kind = 1, icon = item.icon, name = item.name, quality = item.quality, link = link }
    for key, value in pairs(extra or {}) do s[key] = value end
    return s
end
local function Coins(copper) return { kind = 2, icon = 133784, name = ("%d Copper"):format(copper), quality = 0 } end

-- The game's loot window and roll frames.
CreateFrame("Frame", "LootFrame", UIParent)
LootFrame:RegisterEvent("LOOT_OPENED")
LootFrame:RegisterEvent("LOOT_CLOSED")
CreateFrame("Frame", "GroupLootContainer", UIParent)
W.cvarInfo.autoLootDefault = { default = "1", scope = "account" } -- the game's Auto Loot, on as many players have it

-- The bags: [bag] = { [slot] = { link, count, quest, noValue, locked } }; size slots each.
local bags, size = { [0] = {}, {}, {}, {}, {} }, 4
local picked
C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and size or 0 end,
    GetContainerNumFreeSlots = function(bag)
        local free = 0
        for slot = 1, size do if not (bags[bag] and bags[bag][slot]) then free = free + 1 end end
        return bags[bag] and free or 0, 0
    end,
    GetContainerItemInfo = function(bag, slot)
        local thing = bags[bag] and bags[bag][slot]
        if not thing then return nil end
        local item = items[thing.link]
        return { hyperlink = thing.link, stackCount = thing.count or 1, quality = item.quality, iconFileID = item.icon,
                 hasNoValue = thing.noValue or false, isLocked = thing.locked or false }
    end,
    GetContainerItemQuestInfo = function(bag, slot)
        local thing = bags[bag] and bags[bag][slot]
        return { isQuestItem = thing and thing.quest or false }
    end,
    PickupContainerItem = function(bag, slot) picked = { bag, slot } end,
}
CursorHasItem = function() return false end
NUM_BAG_SLOTS = 4

-- The group's rolls: [rollID] = { name, link, quality, canNeed, canGreed, canTransmog, canDisenchant, reasonGreed, left }
local rolls, rolled = {}, {}
GetLootRollItemInfo = function(id)
    local r = rolls[id]
    if not r then return nil end
    return 1000 + id, r.name, 1, r.quality, true, r.canNeed, r.canGreed, r.canDisenchant, 0, r.reasonGreed or 0, 0, 0,
        r.canTransmog
end
GetLootRollItemLink = function(id) return rolls[id] and rolls[id].link end
GetLootRollTimeLeft = function(id) return rolls[id] and rolls[id].left or 0 end
RollOnLoot = function(id, kind) rolled[#rolled + 1] = { id, kind } end
GetActiveLootRollIDs = function()
    local ids = {}
    for id in pairs(rolls) do ids[#ids + 1] = id end
    table.sort(ids)
    return ids
end
C_Loot = { GetLootRollDuration = function() return 60000 end }

-- The master looter's.
local method, given, asked = Enum.LootMethod.Group, nil, nil
C_PartyInfo = { GetLootMethod = function() return method, method == Enum.LootMethod.Masterlooter and 0 or nil, nil end }
GetLootThreshold = function() return 2 end
GetMasterLootCandidate = function(_, index)
    local list = { { "Tester", "Mage", "MAGE" }, { "Brute", "Warrior", "WARRIOR" } }
    local c = list[index]
    if c then return c[1], c[2], c[3] end
end
GiveMasterLoot = function(slot, index) given = { slot, index } end
DoMasterLootRoll = function(slot) asked = slot end

-------------------------------------------------------------------------------
--  Loaded and started
-------------------------------------------------------------------------------
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core
local ns = W.LoadAddon(root, "Loot", "SaneUI_Loot")
W.Fire("ADDON_LOADED", "SaneUI_Loot")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Loot == ns and not ns.off, "the module is made and started")
check(not LootFrame:IsEventRegistered("LOOT_OPENED"), "the game's loot window no longer hears that loot opened")
check(LootFrame:IsEventRegistered("LOOT_CLOSED"), "what else it hears it still hears")
check(GroupLootContainer:GetParent() ~= UIParent and not GroupLootContainer:GetParent():IsShown(),
    "the game's roll frames are held in a hidden frame")
local options = ns.options
check(options.window and options.atMouse and options.rolls and options.feed and options.feedMoney, "the switches are on at first")
check(options.notes == false, "no line under a name at first")
for _, key in ipairs({ "takeCoins", "takeCurrency", "takeQuest", "takeJunk" }) do
    check(options[key] == true, key .. " is on at first, Loot's own default")
end
for _, key in ipairs({ "takeAll", "takeTrade", "takeGear", "takeConsumable" }) do
    check(options[key] == false, key .. " is off at first")
end
check(C_CVar.GetCVar("autoLootDefault") == "0" and options.lent.autoLootDefault.was == "1",
    "the game's Auto Loot lent off while ours is on, what it was kept")
-- Sync writes the profile's game settings a moment after the login: its Auto Loot on must not undo the lend.
Core.Sync.SetCVar("autoLootDefault", "1")
check(C_CVar.GetCVar("autoLootDefault") == "0" and Core.Sync.Value("autoLootDefault") == "1",
    "Sync's writing of the profile leaves the lend alone, and keeps the player's own value")

-------------------------------------------------------------------------------
--  The sentences read back
-------------------------------------------------------------------------------
local Chat = ns.Chat
local who, link, count = Chat.Received("You receive loot: " .. CLOTH .. "x3.")
check(who == nil and link == CLOTH and count == 3, "your loot with a count")
who, link, count = Chat.Received("You receive loot: " .. ROBE .. ".")
check(who == nil and link == ROBE and count == 1, "your loot, one")
who, link, count = Chat.Received("Brute receives loot: " .. ROBE .. ".")
check(who == "Brute" and link == ROBE and count == 1, "another's loot")
who, link, count = Chat.Received("Brute receives loot: " .. CLOTH .. "x2.")
check(who == "Brute" and link == CLOTH and count == 2, "another's loot with a count")
check(Chat.Received("Hello there.") == nil, "another line is no loot")
local found, chooser, choice, rolledLink = Chat.Rolled("Brute has selected Greed for: " .. ROBE)
check(found and chooser == "Brute" and choice == "greed" and rolledLink == ROBE, "another's choice")
found, chooser, choice = Chat.Rolled("You have selected Need for: " .. ROBE)
check(found and chooser == nil and choice == "need", "your own choice")
found, chooser, choice = Chat.Rolled("Brute won: " .. ROBE)
check(found and chooser == "Brute" and choice == "won", "who won")
check(Chat.Money("You loot 1 Gold, 2 Silver, 3 Copper") == 10203, "money looted, in copper")
check(Chat.Money("Your share of the loot is 45 Copper.") == 45, "a share of the money")
local cLink, cCount = Chat.Currency("You receive currency: |Hcurrency:1792|h[Honor]|h x12.")
check(cLink == "|Hcurrency:1792|h[Honor]|h" and cCount == 12, "a currency with its count")

-------------------------------------------------------------------------------
--  The rules
-------------------------------------------------------------------------------
loot = { Coins(42), Slot(CLOTH, { count = 2 }), Slot(ROBE), Slot(RING), Slot(TUSK, { questItem = true }) }
local lines = ns.Slots.Read()
check(#lines == 5 and lines[1].kind == "money" and lines[2].kind == "item" and lines[2].count == 2, "the loot read")
check(lines[3].id == 6000 and lines[3].bind == 2 and lines[3].worth == 120 and lines[3].where == "Chest", "an item's facts")
check(ns.Slots.Note(lines[3]) == "|cffff8040BoE|r · Chest", "the note under a name: BoE short and orange, the kind")
check(ns.Slots.Note(lines[4]) == "|cffff2020BoP|r · Cloth", "BoP short and red")
-- an appearance the character could collect and has not (the game's collection): Uncollected, light blue
C_TransmogCollection = {
    GetItemInfo = function(link) if link == ROBE then return 77, 7700 elseif link == RING then return 78, 7800 end end,
    PlayerCanCollectSource = function() return true, true end,
    GetAppearanceInfoBySource = function(source) return { appearanceIsCollected = source == 7800 } end,
}
check(ns.Slots.Uncollected(ROBE) and not ns.Slots.Uncollected(RING) and not ns.Slots.Uncollected(CLOTH),
    "uncollected: what the game says can be collected and is not")
lines[3].uncollected = true
check(ns.Slots.Note(lines[3]) == "|cffff8040BoE|r · |cff87abffUncollected|r · Chest", "Uncollected after the bind, light blue")
lines[3].uncollected = nil
C_TransmogCollection.PlayerCanCollectSource = function() return true, false end
check(not ns.Slots.Uncollected(ROBE), "not where the character cannot collect it")
C_TransmogCollection = nil
check(ns.Slots.Note(lines[1]) == ns.TEXT.coins and ns.Slots.Note(lines[5]) == ns.TEXT.questItem, "notes of coins and quests")
local function Wanted(index, change)
    local o = { kept = {} }
    for key, value in pairs(change or {}) do o[key] = value end
    return ns.Slots.Wanted(lines[index], o)
end
check(not Wanted(1) and not Wanted(2) and not Wanted(3) and not Wanted(4) and not Wanted(5), "nothing at first")
check(Wanted(1, { takeCoins = true }) and not Wanted(2, { takeCoins = true }), "coins by their switch")
check(Wanted(5, { takeQuest = true }) and not Wanted(3, { takeQuest = true }), "quest items by theirs")
check(Wanted(2, { takeTrade = true }) and not Wanted(3, { takeTrade = true }), "trade goods (cloth) by theirs")
check(Wanted(3, { takeGear = true }) and not Wanted(2, { takeGear = true }), "gear by its own")
check(not Wanted(4, { takeGear = true }), "never by a kind's switch what binds when picked up")
check(Wanted(4, { takeAll = true }), "by Everything it is taken, and the game asks")
check(Wanted(1, { takeAll = true }) and Wanted(2, { takeAll = true }) and Wanted(3, { takeAll = true }), "Everything")
check(Wanted(3, { kept = { [6000] = true } }), "the player's word: taken")
check(not Wanted(3, { takeAll = true, kept = { [6000] = false } }), "the player's word: never, over Everything")
check(Wanted(4, { kept = { [7000] = true } }), "the player's word takes even what binds when picked up")
check(ns.Slots.Rule(lines[2], { takeTrade = true, kept = {} }) == "takeTrade", "the rule that takes it")
local food, junk = ns.Slots.Item(4540), ns.Slots.Item(3300)
check(food and food.class == 0 and ns.Slots.Wanted(food, { takeConsumable = true, kept = {} }), "consumables by theirs")
check(junk and ns.Slots.Wanted(junk, { takeJunk = true, kept = {} }) and not ns.Slots.Wanted(food, { takeJunk = true, kept = {} }),
    "junk: the poor ones")
check(ns.Slots.Quest({ kind = "item", class = 12 }), "an item of the quests' class is a quest's")
lines[2].locked = true
check(not Wanted(2, { takeAll = true }), "never a locked thing")

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
local Window = ns.Window
-- A loot opened as the game opens one: the last one closed, this one ready, then open.
local function Open(auto)
    W.Fire("LOOT_CLOSED")
    taken, closed = {}, 0
    W.Fire("LOOT_READY", auto or false)
    W.Fire("LOOT_OPENED", auto or false, false)
end
local function Shown() return Window.frame and Window.frame:IsShown() end
local function Rows()
    local list = {}
    for _, row in ipairs(W.frames) do
        if row.line and row._shown and row._parent and row._parent._parent and row.SetScript and row.holder then
            list[#list + 1] = row
        end
    end
    table.sort(list, function(a, b) return a.line.slot < b.line.slot end)
    return list
end

loot = { Coins(42), Slot(CLOTH, { count = 2 }), Slot(ROBE), Slot(RING), Slot(TUSK, { questItem = true }) }
Open()
check(#taken == 2 and taken[1] == 1 and taken[2] == 5, "at first the coins and the quest item at once, nothing lent")
check(not options.takeAll, "by their own switches, Everything off")
check(Shown() and #Rows() == 3, "the rest waits in the window")
check(Rows()[2].note:GetText() == "" and Rows()[2].worth:GetText() == "", "no line under a name at first")
check(Rows()[2].name._points[1][1] == "LEFT", "the name alone in the middle of its line")
Window.Close()
-- The switches each stand alone: off, nothing is taken.
options.takeCoins, options.takeCurrency, options.takeQuest, options.takeJunk = false, false, false, false
options.notes = true
Open()
check(#taken == 0 and #W.frames > 0, "with every switch off nothing is taken")
options.takeCoins, options.takeQuest = true, true
Open()
check(#taken == 2 and taken[1] == 1 and taken[2] == 5, "with their switches: the coins and the quest item at once")
check(Shown(), "the window opens for the rest")
check(Window.frame._points[1] and Window.frame._points[1][1] == "TOPLEFT", "it stands at the mouse")
local rows = Rows()
check(#rows == 3 and rows[1].line.slot == 2 and rows[3].line.slot == 4, "a line for each thing not taken at once")
check(rows[1].count:GetText() == 2 and rows[1].name:GetText() == "Linen Cloth", "the count on the picture, the name")
check(rows[2].note:GetText() == "|cffff8040BoE|r · Chest" and rows[2].worth:GetText() == "120c",
    "under the name its kind, at the right what a vendor pays")
check(rows[1].worth:GetText() == "26c", "the worth of the whole stack")
options.notes = false
Window.Fill()
check(rows[2].note:GetText() == "" and rows[2].worth:GetText() == "", "the line under the name switched off")
options.notes = true
Window.Fill()
local function Colour(bar) return bar.colour end
check(Colour(rows[1].bar)[1] == ITEM_QUALITY_COLORS[1].r and Colour(rows[2].bar)[1] == ITEM_QUALITY_COLORS[2].r,
    "each line a bar in its quality's colour, as a nameplate's")
check(rows[2].bar.fill._texture == "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" and #rows[2].bar.halves == 2,
    "the nameplates' shaded fill, its border two round halves")
check(rows[2].holder.plate == nil and rows[2].holder._width == rows[2].bar.inner and rows[2].holder._points[1][1] == "TOPLEFT",
    "the picture at the bar's left end, as tall as its fill, no border of its own")
local caps = 0
for _, frame in ipairs(W.frames) do
    if frame._parent == rows[2].holder and frame._kind == "MaskTexture" and frame._points[1] and frame._points[1][2] == rows[2].holder then
        caps = caps + 1
    end
end
check(caps == 2, "its corners round by the bar's own caps, the same radius")
check(not rows[2].bar.lit, "its border dark")
rows[2]._scripts.OnEnter(rows[2])
check(rows[2].bar.lit, "grey under the mouse")
rows[2]._scripts.OnLeave(rows[2])
check(rows[2].auto:IsShown() and not rows[2].auto.on, "an A on each item, not lit")
check(Window.frame._width >= ns.SIZE.least and Window.frame._width <= ns.SIZE.width, "as wide as its words, within bounds")
check(Window.frame._height and Window.frame._height > 3 * ns.SIZE.row, "the window as high as its lines")

-- the game clears what was taken
loot[1].gone, loot[5].gone = true, true
W.Fire("LOOT_SLOT_CLEARED", 1)
W.Fire("LOOT_SLOT_CLEARED", 5)
check(#Rows() == 3 and Shown(), "the taken ones were never shown")

-- a click takes, Shift-click links, Alt-click lists
taken = {}
rows[1]._scripts.OnClick(rows[1], "LeftButton")
check(taken[1] == 2, "a click takes the thing")
W.modifier = "CHATLINK"
rows[2]._scripts.OnClick(rows[2], "LeftButton")
check(linked == ROBE and #taken == 1, "a modified click links it, takes nothing")
W.modifier = nil
W.alt = true
rows[2]._scripts.OnClick(rows[2], "LeftButton")
check(options.kept[6000] == true, "Alt-click puts it on the loot list")
rows[2]._scripts.OnClick(rows[2], "LeftButton")
check(options.kept[6000] == nil, "and again takes it off")
W.alt = false
taken = {}
rows[2].auto._scripts.OnClick(rows[2].auto)
check(options.kept[6000] == true and rows[2].auto.on and taken[1] == 3, "the A: on the list, lit, and taken now")
rows[2].auto._scripts.OnClick(rows[2].auto)
check(options.kept[6000] == nil and not rows[2].auto.on, "the A again: off the list")

-- a slot changed, cleared
loot[2].count = 5
W.Fire("LOOT_SLOT_CHANGED", 2)
check(Rows()[1].count:GetText() == 5, "a changed slot is drawn anew")
loot[2].gone = true
W.Fire("LOOT_SLOT_CLEARED", 2)
check(#Rows() == 2 and Rows()[1].line.slot == 3, "a cleared slot's line goes")

-- Link: the loot's links into the chat box, never sent by us
local function Word(text)
    for _, frame in ipairs(W.frames) do
        if frame._parent == Window.frame and frame.text and frame.text:GetText() == text then return frame end
    end
end
local linkWord, closeWord = Word(ns.TEXT.link), Word(ns.TEXT.close)
check(linkWord and linkWord:IsShown() and closeWord and closeWord:IsShown(), "at the foot: Link and Close")
check(linkWord._points[1][1] == "BOTTOMLEFT" and closeWord._points[1][1] == "BOTTOMRIGHT", "side by side, at the bottom")
check(linkWord.bar == nil and closeWord.bar == nil, "no border and no background: the word alone")
local function Off(word)
    local r, g, b = word.text:GetTextColor()
    return math.abs(r - 238 / 255) < 0.01 and math.abs(g - 229 / 255) < 0.01 and math.abs(b - 208 / 255) < 0.01
end
check(Off(linkWord) and Off(closeWord), "their words off white")
linkWord._scripts.OnEnter(linkWord)
check(not Off(linkWord), "gold under the mouse")
linkWord._scripts.OnLeave(linkWord)
check(Off(linkWord), "off white again")
local opened, inserted
ChatFrameUtil.OpenChat = function(text) opened = text end
ChatFrameUtil.GetActiveWindow = function() return nil end
linkWord._scripts.OnClick(linkWord)
check(opened == ROBE .. " " .. RING, "Link opens the chat box with the loot's links")
ChatFrameUtil.GetActiveWindow = function()
    return { Insert = function(_, text) inserted = text end, SetFocus = function() end }
end
linkWord._scripts.OnClick(linkWord)
check(inserted == ROBE .. " " .. RING, "or puts them into the chat box being written in")
ChatFrameUtil.GetActiveWindow = function() return nil end

loot[3].locked = true
W.Fire("LOOT_SLOT_CHANGED", 3)
check(Rows()[1]:GetAlpha() < 1 and Rows()[1].note:GetText() == ns.TEXT.locked, "a locked thing is faint, and says so")
options.notes = false
Window.Fill()
check(Rows()[1]:GetAlpha() < 1 and Rows()[1].note:GetText() == "", "the line under its name off: faint, no line")
local said
local addLine = GameTooltip.AddLine
GameTooltip.AddLine = function(_, text) said = said or text == ns.TEXT.locked end
Rows()[1]._scripts.OnEnter(Rows()[1])
GameTooltip.AddLine = addLine
Rows()[1]._scripts.OnLeave(Rows()[1])
check(said, "and its tooltip says so")
options.notes = true
Window.Fill()
taken = {}
Rows()[1]._scripts.OnClick(Rows()[1], "LeftButton")
check(#taken == 0, "and is not taken")

-- all taken: the loot closes
loot[3].gone, loot[4].gone = true, true
closed = 0
W.Fire("LOOT_SLOT_CLEARED", 3)
W.Fire("LOOT_SLOT_CLEARED", 4)
check(not Shown() and closed == 1, "the last thing taken closes the window and the loot")
W.Fire("LOOT_CLOSED")
check(closed == 1, "the game's closing closes nothing twice")

-- Close and Esc close the loot
loot = { Slot(ROBE) }
Open()
check(Shown(), "opened again")
closeWord._scripts.OnClick(closeWord)
check(not Shown() and closed == 1, "closed by the player: the loot is closed")

-- a thing taken: the lines close up, the next one under the mouse where the taken one stood
W.cursorX, W.cursorY = 500, 400
loot = { Slot(ROBE), Slot(CLOTH), Slot(GEM), Coins(7) }
options.takeCoins = false
Open()
local top, step = 400 + ns.SIZE.row / 2, ns.SIZE.row + ns.SIZE.rowGap
check(Window.frame._points[1][4] == 500 - ns.SIZE.row / 2 and Window.frame._points[1][5] == top,
    "the first line's picture under the mouse")
check(Word(ns.TEXT.link):IsShown(), "Link while there are links")
Rows()[1]._scripts.OnClick(Rows()[1], "LeftButton")
loot[1].gone = true
W.Fire("LOOT_SLOT_CLEARED", 1)
check(#Rows() == 3 and Rows()[1].line.slot == 2 and Window.frame._points[1][5] == top,
    "the first taken: the second closes up under the mouse, the window stays")
Rows()[3]._scripts.OnClick(Rows()[3], "LeftButton")
loot[4].gone = true
W.Fire("LOOT_SLOT_CLEARED", 4)
check(#Rows() == 2 and Window.frame._points[1][5] == top - step,
    "the last taken: the window comes down a line, the one before under the mouse")
loot[2].gone = true
W.Fire("LOOT_SLOT_CLEARED", 2)
check(Window.frame._points[1][5] == top - step, "a thing taken by something else moves nothing")
Window.Close()
options.takeCoins = true
W.cursorX, W.cursorY = nil, nil

-- a quest's thing in gold; money alone has nothing to link
options.takeQuest, options.takeCoins = false, false
loot = { Slot(TUSK, { questItem = true }), Coins(3) }
Open()
check(Colour(Rows()[1].bar)[1] == 1 and Colour(Rows()[1].bar)[2] == 0.82, "a quest's thing: a gold bar")
check(Rows()[1].note:GetText() == ns.TEXT.questItem, "its line under the name: a quest's")
check(Rows()[2].note:GetText() == ns.TEXT.coins and Rows()[2].note._points[2][2] == Rows()[2],
    "selling for nothing (coins): the line under the name reaches the line's end, not empty words")
Window.Close()
loot = { Coins(3) }
Open()
check(Shown() and not Word(ns.TEXT.link):IsShown() and Word(ns.TEXT.close):IsShown(), "money alone: Close alone")
Window.Close()
options.takeQuest, options.takeCoins = true, true

-- the rules take everything: no window, the game closes the loot
loot = { Coins(10), Slot(TUSK, { questItem = true }) }
Open()
check(not Shown() and #taken == 2, "everything taken at once: no window")
loot[1].gone, loot[2].gone = true, true
W.Fire("LOOT_SLOT_CLEARED", 1)
W.Fire("LOOT_SLOT_CLEARED", 2)
W.Fire("LOOT_CLOSED")
W.Wait(1)
check(not Shown(), "and none after")

-- the game's Auto Loot: shown only if something is left
loot = { Slot(CLOTH), Slot(ROBE) }
Open(true)
check(not Shown(), "Auto Loot: no window at once")
loot[1].gone = true
W.Fire("LOOT_SLOT_CLEARED", 1)
W.Wait(0.5)
check(Shown() and #Rows() == 1 and Rows()[1].line.slot == 2, "what Auto Loot left shows a moment later")
Window.Close()

-- a thing the rules took could not be taken: it shows again
loot = { Slot(TUSK, { questItem = true }), Slot(ROBE) }
Open()
check(#Rows() == 1, "the quest item is being taken")
W.Fire("UI_ERROR_MESSAGE", 3, ERR_INV_FULL)
check(#Rows() == 2, "the bags were full: it shows after all")
Window.Close()

-- as soon as the loot is ready, before it opens; a big pile a few slots a frame, nothing asked twice
options.takeTrade = true
loot = {}
for _ = 1, 7 do loot[#loot + 1] = Slot(CLOTH) end
W.Fire("LOOT_CLOSED")
taken = {}
W.Fire("LOOT_READY", false)
check(#taken == ns.SIZE.burst, "ready: the first few taken at once")
W.Fire("LOOT_OPENED", false, false)
check(#taken == math.min(7, 2 * ns.SIZE.burst), "opened: the next few, nothing asked again")
for _ = 1, 3 do
    for _, frame in ipairs(W.frames) do
        if frame._shown and frame._scripts.OnUpdate and frame._parent == UIParent then frame._scripts.OnUpdate(frame, 0.016) end
    end
end
local once = {}
for _, slot in ipairs(taken) do once[slot] = (once[slot] or 0) + 1 end
local twice = false
for _, n in pairs(once) do if n > 1 then twice = true end end
check(#taken == 7 and not twice, "the rest in the frames after, each slot once")
check(not Shown(), "all of it taken: no window")
options.takeTrade = false
W.Fire("LOOT_CLOSED")

-- Shift's Auto Loot (the game takes everything): nothing asked by us
loot = { Slot(TUSK, { questItem = true }) }
W.Fire("LOOT_CLOSED")
taken = {}
W.Fire("LOOT_READY", true)
W.Fire("LOOT_OPENED", true, false)
check(#taken == 0, "the game's Auto Loot: we ask for nothing")
W.Fire("LOOT_CLOSED")

-- At the mouse off: where it was placed
options.atMouse = false
loot = { Slot(ROBE) }
Open()
check(Window.frame._points[1][2] == UIParent and Window.frame._points[1][1] == "LEFT", "at its first place")
Window.Close()
options.atMouse = true

-------------------------------------------------------------------------------
--  Bags full
-------------------------------------------------------------------------------
check(#ns.Full.Rank({ { bag = 0, slot = 1, worth = 5, count = 1, quality = 1, name = "a" },
                      { bag = 0, slot = 2, worth = 1, count = 2, quality = 1, name = "b" },
                      { bag = 0, slot = 3, worth = 0, count = 1, quality = 0, name = "c" },
                      { bag = 0, slot = 4, worth = 9, count = 1, quality = 4, name = "d" },
                      { bag = 0, slot = 5, worth = 1, count = 1, quality = 1, name = "e", quest = true },
                      { bag = 0, slot = 6, worth = 1, count = 1, quality = 1, name = "f", noValue = true } }) == 2,
    "never offered: worth nothing, epic, a quest's, unsellable")
local ranked = ns.Full.Rank({ { bag = 0, slot = 1, worth = 5, count = 1, quality = 1, name = "a" },
                              { bag = 0, slot = 2, worth = 1, count = 2, quality = 1, name = "b" } })
check(ranked[1].name == "b", "the cheapest stack first")

for bag = 0, 4 do
    for slot = 1, size do bags[bag][slot] = { link = GEM } end
end
bags[1][2] = { link = CLOTH, count = 3 }   -- 39
bags[2][3] = { link = TUSK, count = 2 }    -- 10
bags[3][1] = { link = TUSK, count = 1, quest = true }
loot = { Slot(ROBE) }
Open()
local page = ns.Full
local pageFrame
for _, frame in ipairs(W.frames) do
    if frame._parent == Window.frame and frame.head and frame.rule then pageFrame = frame end
end
check(pageFrame and pageFrame:IsShown(), "bags full: the page beside the window")
local texts = {}
for _, frame in ipairs(W.frames) do
    if frame._parent == pageFrame and frame.name and frame.worth and frame._shown then
        texts[#texts + 1] = frame.name:GetText() .. " / " .. frame.worth:GetText()
    end
end
table.sort(texts)
check(texts[1] == "Apprentice Robe / Worth 120c" and texts[2] == "Boar Tusk / Worth 10c", "the thing's worth, the cheapest of yours")
local room
for _, frame in ipairs(W.frames) do
    if frame._parent == pageFrame and frame.name and frame.name:GetText() == "Boar Tusk" then room = frame end
end
room._scripts.OnClick(room)
check(picked and picked[1] == 2 and picked[2] == 3, "a click picks it up")
bags[2][3] = nil
W.Fire("BAG_UPDATE_DELAYED")
check(not pageFrame:IsShown(), "room again: the page goes")
Window.Close()
check(page ~= nil, "the page's table")
for bag = 0, 4 do bags[bag] = {} end

-------------------------------------------------------------------------------
--  The master looter
-------------------------------------------------------------------------------
method = Enum.LootMethod.Masterlooter
loot = { Slot(CLOTH), Slot(ROBE) }
check(not ns.Master.Gives(ns.Slots.Line(1)) and ns.Master.Gives(ns.Slots.Line(2)), "the group's quality is yours to give")
Open()
taken = {}
W.menus = {}
Rows()[2]._scripts.OnClick(Rows()[2], "LeftButton")
check(#taken == 0 and #W.menus == 1, "a click opens the menu, takes nothing")
local menu = W.menus[1]
check(menu[1].title == "Apprentice Robe" and menu[2].text == ns.TEXT.give, "the menu: the thing, Give to")
local names = {}
for _, entry in ipairs(menu[2].sub) do names[#names + 1] = entry.text end
check(table.concat(names, ",") == "Tester,Brute", "everybody who may have it, by class")
W.popups = {}
menu[2].sub[2].fn()
check(#W.popups == 1, "the game asks first")
W.popups[1].data.callback()
check(given and given[1] == 2 and given[2] == 2, "then the thing is given")
menu[3].fn()
check(asked == 2, "or a roll asked of the group")
Window.Close()
method = Enum.LootMethod.Group

-------------------------------------------------------------------------------
--  The roll cards
-------------------------------------------------------------------------------
local function Cards()
    local list = {}
    for _, frame in ipairs(W.frames) do
        if frame.choices and frame.chose and frame._shown then list[#list + 1] = frame end
    end
    return list
end
local function Choices(card)
    local list = {}
    for _, button in ipairs(card.choices) do
        if button._shown then list[#list + 1] = button end
    end
    table.sort(list, function(a, b) return a._points[1][4] < b._points[1][4] end)
    return list
end
rolls[7] = { name = "Apprentice Robe", link = ROBE, quality = 2, canNeed = false, canGreed = true, left = 30000 }
W.Fire("START_LOOT_ROLL", 7, 60000)
local cards = Cards()
check(#cards == 1 and cards[1].name:GetText() == "Apprentice Robe", "a card for the roll")
local choices = Choices(cards[1])
check(#choices == 3, "Need, Greed and Pass")
local words = {}
for _, button in ipairs(choices) do words[#words + 1] = button.word end
check(table.concat(words, ",") == "Need,Greed,Pass", "in their order")
check(choices[1].reason and choices[1]:GetAlpha() < 1, "a refused choice is faint, with its reason")
choices[1]._scripts.OnClick(choices[1])
check(#rolled == 0, "a refused choice does nothing")
W.Fire("CHAT_MSG_LOOT", "Brute has selected Greed for: " .. ROBE)
W.Fire("CHAT_MSG_LOOT", "Brute has selected Greed for: " .. ROBE)
check(choices[2].text:GetText() == "Greed 1", "who chose what, counted once each")
W.Fire("CHAT_MSG_LOOT", "Mira passed on: " .. ROBE)
check(choices[3].text:GetText() == "Pass 1", "a pass counted")
cards[1]:GetParent()._scripts.OnUpdate(cards[1]:GetParent(), 1)
check(math.abs(cards[1].time._width - (ns.SIZE.card[1] - 2 * ns.SIZE.gap) / 2) < 0.01, "the time line half long at half the time")
choices[2]._scripts.OnClick(choices[2])
check(rolled[1][1] == 7 and rolled[1][2] == 2, "Greed chosen")
rolls[8] = { name = "Shiny Gem", link = GEM, quality = 4, canNeed = true, canGreed = true, canTransmog = true,
             canDisenchant = true, left = 60000 }
W.Fire("START_LOOT_ROLL", 8, 60000)
check(#Cards() == 2, "a second card")
words = {}
for _, button in ipairs(Choices(Cards()[2])) do words[#words + 1] = button.word end
check(table.concat(words, ",") == "Need,Transmog,Disenchant,Pass", "Transmog for Greed, Disenchant where offered")
W.Fire("CANCEL_LOOT_ROLL", 7)
rolls[7] = nil
check(#Cards() == 1 and Cards()[1].name:GetText() == "Shiny Gem", "a roll over: its card goes")
options.rolls = false
ns.Game.Update()
check(#Cards() == 0 and GroupLootContainer:GetParent() == UIParent, "off: the game's roll frames are back")
options.rolls = true
ns.Game.Update()
check(#Cards() == 1 and GroupLootContainer:GetParent() ~= UIParent, "on again: a card for the roll still open")
W.Fire("CANCEL_ALL_LOOT_ROLLS")
rolls = {}
check(#Cards() == 0, "all rolls over")

-------------------------------------------------------------------------------
--  The feed
-------------------------------------------------------------------------------
local function Feed()
    local list = {}
    for _, frame in ipairs(W.frames) do
        if frame.entry and frame.icon and frame._shown then list[#list + 1] = frame end
    end
    table.sort(list, function(a, b) return a._points[1][5] > b._points[1][5] end)
    return list
end
W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. CLOTH .. "x2.")
local feed = Feed()
check(#feed == 1 and feed[1].text:GetText():find("Linen Cloth x2", 1, true), "your loot rises")
check(feed[1].text:GetText():find("(7)", 1, true), "with how many you carry")
W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. CLOTH .. ".")
check(#Feed() == 1 and Feed()[1].text:GetText():find("Linen Cloth x3", 1, true), "the same thing adds to its line")
W.Fire("CHAT_MSG_LOOT", "Brute receives loot: " .. CLOTH .. ".")
check(#Feed() == 1, "the group's below the quality: not shown")
W.Fire("CHAT_MSG_LOOT", "Brute receives loot: " .. ROBE .. ".")
check(#Feed() == 2 and Feed()[2].text:GetText() == "Brute: Apprentice Robe", "the group's, named")
W.Fire("CHAT_MSG_MONEY", "You loot 2 Silver")
check(#Feed() == 3 and Feed()[3].text:GetText() == "200c", "money")
W.Fire("CHAT_MSG_CURRENCY", "You receive currency: |Hcurrency:1792|h[Honor]|h x12.")
check(#Feed() == 4 and Feed()[4].text:GetText():find("Honor x12", 1, true), "a currency")
W.clock = W.clock + 10
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 0.1)
check(#Feed() == 0, "they fade and go")

-- What is taken at once is seen all the same: Loot's own defaults, nothing lent, and the feed says what came.
options.takeCoins, options.takeCurrency, options.takeQuest, options.takeJunk = true, true, true, true
local pile = { Coins(42), Slot(SCRAP), Slot(TUSK, { questItem = true }), Slot(ROBE),
               { kind = 3, icon = 500, name = "Honor", count = 12, currency = 1792 } }
loot = pile
Open()
check(#taken == 4 and taken[1] == 1 and taken[2] == 2 and taken[3] == 3 and taken[4] == 5,
    "coins, junk, the quest item and the currency at once by their own switches")
check(Shown() and #Rows() == 1 and Rows()[1].line.link == ROBE, "the rest waits in the window")
W.Fire("CHAT_MSG_MONEY", "You loot 42 Copper")
W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. SCRAP .. ".")
W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. TUSK .. ".")
W.Fire("CHAT_MSG_CURRENCY", "You receive currency: |Hcurrency:1792|h[Honor]|h x12.")
check(#Feed() == 4 and Feed()[1].text:GetText() == "42c" and Feed()[2].text:GetText():find("Rabbit's Foot", 1, true)
      and Feed()[3].text:GetText():find("Boar Tusk", 1, true) and Feed()[4].text:GetText():find("Honor x12", 1, true),
    "and every one of them rises in the feed")
Window.Close()
-- Speed Leveling's Take all loot is lent over them; given back, they stand as they stood.
loot = { Coins(42), Slot(SCRAP), Slot(ROBE) }
Core.Set(ns.name, "takeAll", true)
Core.Set(ns.name, "showUpgrades", false)
Open()
check(#taken == 3 and not Shown(), "Everything lent: all of it at once")
Core.Set(ns.name, "takeAll", false)
Core.Set(ns.name, "showUpgrades", true)
Open()
check(#taken == 2 and Shown() and options.takeCoins and options.takeCurrency and options.takeQuest and options.takeJunk,
    "given back, the switches of kinds still decide")
Window.Close()
W.clock = W.clock + 10
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 0.1)

-- A big pile: nothing goes unseen. What comes while the lines are full waits and rises as they go.
local heaps = {}
for index = 1, 10 do
    heaps[index] = Item(20000 + index, "Heap " .. index, 1)
    W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. heaps[index] .. ".")
end
check(#Feed() == 8 and Feed()[1].text:GetText():find("Heap 1", 1, true) and Feed()[8].text:GetText():find("Heap 8", 1, true),
    "eight lines at a time, the first of the pile still there")
W.Fire("CHAT_MSG_LOOT", "You receive loot: " .. heaps[3] .. ".")
check(#Feed() == 8 and Feed()[3].text:GetText():find("Heap 3 x2", 1, true), "the same thing still adds to its line")
W.clock = W.clock + 10
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 0.1)
check(#Feed() == 2 and Feed()[1].text:GetText():find("Heap 9", 1, true) and Feed()[2].text:GetText():find("Heap 10", 1, true),
    "the two that waited rise as the others go")
W.clock = W.clock + 10
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 0.1)
check(#Feed() == 0, "and go in their turn")

-- The game does not name the currency: the name in its line.
local currencyInfo = C_CurrencyInfo.GetCurrencyInfoFromLink
C_CurrencyInfo.GetCurrencyInfoFromLink = function() return nil end
W.Fire("CHAT_MSG_CURRENCY", "You receive currency: |Hcurrency:9|h[Marks]|h x2.")
C_CurrencyInfo.GetCurrencyInfoFromLink = currencyInfo
check(#Feed() == 1 and Feed()[1].text:GetText() == "Marks x2", "a currency the game does not describe still rises")
W.clock = W.clock + 10
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 0.1)

-- A line the game hides from addons (a secret value) is passed over: nothing breaks, nothing stands down.
local hidden = "You receive loot: " .. ROBE .. "."
issecretvalue = function(value) return value == hidden end
W.Fire("CHAT_MSG_LOOT", hidden)
issecretvalue = nil
check(#Feed() == 0 and not ns.off, "a hidden line is passed over")

-------------------------------------------------------------------------------
--  Edit Mode and /sane loot
-------------------------------------------------------------------------------
EventRegistry:TriggerEvent("EditMode.Enter")
check(not Window.frame:IsShown(), "in Edit Mode, at the mouse: no window to place")
EventRegistry:TriggerEvent("EditMode.Exit")
options.atMouse = false
EventRegistry:TriggerEvent("EditMode.Enter")
check(Window.frame:IsShown() and not Window.Shown(), "At the mouse off: the window shows to be placed, no loot in it")
local samples = 0
for _, frame in ipairs(W.frames) do
    if frame.line and frame._shown and frame.holder and frame._parent and frame._parent._parent._parent == Window.frame then
        samples = samples + 1
    end
end
check(samples == 2, "two lines as they will look")
check(#Cards() == 1 and Cards()[1].name:GetText() == ns.TEXT.rollsView, "a roll card to place")
check(#Feed() == 3, "feed lines to place")
W.clock = W.clock + 60
Cards()[1]:GetParent()._scripts.OnUpdate(Cards()[1]:GetParent(), 1)
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 1)
check(#Cards() == 1 and #Feed() == 3, "they stand while Edit Mode is open")
loot = { Slot(ROBE) }
Open()
check(Window.Shown() and #Rows() == 1, "loot in Edit Mode: the loot itself")
Window.Close()
EventRegistry:TriggerEvent("EditMode.Exit")
check(not Window.frame:IsShown(), "Edit Mode closed: the window goes")
options.atMouse = true
W.clock = W.clock + 60
Cards()[1]:GetParent()._scripts.OnUpdate(Cards()[1]:GetParent(), 1)
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 1)
check(#Cards() == 0 and #Feed() == 0, "the tried card and lines go")
W.printed = {}
SlashCmdList.SANEUI("loot list")
check(W.printed[1] and W.printed[1]:find(ns.TEXT.listEmpty, 1, true), "/sane loot list: the list is empty")
options.kept[6000] = true
SlashCmdList.SANEUI("loot list")
check(W.printed[2] and W.printed[2]:find("Apprentice Robe", 1, true), "/sane loot list names what is on it")
options.kept[6000] = nil
SlashCmdList.SANEUI("loot try")
check(#Cards() == 1 and #Feed() == 3, "/sane loot try: a card and the feed to look at")
W.clock = W.clock + 60
Cards()[1]:GetParent()._scripts.OnUpdate(Cards()[1]:GetParent(), 1)
Feed()[1]:GetParent()._scripts.OnUpdate(Feed()[1]:GetParent(), 1)

-------------------------------------------------------------------------------
--  Upgrades
-------------------------------------------------------------------------------
W.level = 20
local SASH = Item(5000, "Silk Sash", 2, 300, 2, "INVTYPE_WAIST")
local HELM = Item(5001, "Mail Coif", 2, 400, 2, "INVTYPE_HEAD")
local OLD_HELM = Item(5002, "Old Coif", 1, 40, 2, "INVTYPE_HEAD")
local PLATE_HELM = Item(5003, "Plate Helm", 1, 40, 2, "INVTYPE_HEAD")
items[HELM].level, items[HELM].subclass = 20, 3
items[OLD_HELM].level, items[OLD_HELM].subclass = 12, 3
items[PLATE_HELM].level, items[PLATE_HELM].subclass = 8, 4
local function Up(link)
    loot = { Slot(link) }
    return ns.Slots.Line(1).upgrade
end
check(Up(SASH) == "empty", "nothing worn there: an upgrade")
worn[INVSLOT_HEAD] = OLD_HELM
check(Up(HELM) == "better", "a higher item level than worn: an upgrade")
worn[INVSLOT_HEAD] = HELM
check(Up(OLD_HELM) == nil, "a lower one: none")
worn[INVSLOT_HEAD] = PLATE_HELM
check(Up(HELM) == nil, "lighter armour than worn: none, whatever its level")
worn[INVSLOT_HEAD] = nil
unusable[5000] = true
check(Up(SASH) == nil, "what the game says you cannot use: none")
unusable[5000] = nil
items[SASH].needs, W.level = 10, 5
check(Up(SASH) == nil, "not yet of its level: none")
items[SASH].needs, W.level = nil, 20
-- With the character's weights the stats decide: a lower item level with the right stats goes over a higher one.
do
    local Core, stats = SaneUI.Core, {}
    local get = C_Item.GetItemStats
    C_Item.GetItemStats = function(link) return stats[link] end
    Core.WeighWith(function() return { ITEM_MOD_STRENGTH_SHORT = 1, ITEM_MOD_INTELLECT_SHORT = 0.1 } end)
    stats[HELM], stats[OLD_HELM] = { ITEM_MOD_INTELLECT_SHORT = 30 }, { ITEM_MOD_STRENGTH_SHORT = 10 }
    worn[INVSLOT_HEAD] = OLD_HELM
    check(Up(HELM) == nil, "weights: a higher item level of the wrong stats is no upgrade")
    worn[INVSLOT_HEAD] = HELM
    check(Up(OLD_HELM) == "better", "weights: a lower item level of the right stats is")
    check(select(2, Core.Upgrade(OLD_HELM)) == 7, "and what it gains")
    worn[INVSLOT_HEAD] = nil
    check(select(2, Core.Upgrade(HELM)) == 3, "nothing worn there: all it is worth")
    stats[HELM], stats[OLD_HELM] = {}, {}
    worn[INVSLOT_HEAD] = OLD_HELM
    Core.WeighWith(function() return { ITEM_MOD_STRENGTH_SHORT = 1.5 } end)
    check(Up(HELM) == "better", "no stats on either: the item level decides")
    worn[INVSLOT_HEAD] = nil
    Core.WeighWith(nil)
    C_Item.GetItemStats = get
end
W.level = 20
check(Up(CLOTH) == nil and Up(TUSK) == nil, "no gear: none")

loot = { Slot(SASH), Slot(CLOTH) }
options.takeAll = true
Open()
check(#taken == 1 and taken[1] == 2 and Shown() and #Rows() == 1 and Rows()[1].line.slot == 1,
    "Always show upgrades: Everything takes the rest, the upgrade waits in the window")
check(Rows()[1].upgrade:IsShown() and Rows()[1].upgrade._atlas == "bags-greenarrow"
      and Rows()[1].upgrade._points[1][2] == Rows()[1].name, "the game's green arrow in front of its name")
options.kept[5000] = true
Open()
check(#taken == 1, "over your word too")
options.kept[5000] = nil
options.showUpgrades = false
Open()
check(#taken == 2 and not Shown(), "the switch off: taken with the rest")
options.showUpgrades, options.takeAll = true, false
W.Fire("LOOT_CLOSED")
loot = { Slot(CLOTH) }
Open()
check(not Rows()[1].upgrade:IsShown(), "no arrow on what is no upgrade")
Window.Close()
W.Fire("LOOT_CLOSED")

-------------------------------------------------------------------------------
--  The options' tab Your items
-------------------------------------------------------------------------------
options.seen = { 2589, 6000 }
options.kept = { [7000] = true, [9000] = false }
local tab = CreateFrame("Frame", nil, UIParent)
local height = ns.Items.Build(tab)
check(type(height) == "number" and height > 0 and tab._height == height, "the tab filled, as high as its list")
local function Listed()
    local list = {}
    for _, frame in ipairs(W.frames) do
        if frame._parent == tab and frame.entry and frame._shown then
            list[#list + 1] = { name = frame.name:GetText(), ticked = frame.check:GetChecked(), why = frame.why:GetText(),
                                frame = frame }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end
local list = Listed()
check(#list == 4, "the things met of late and those with a word")
check(list[1].name == "Apprentice Robe" and not list[1].ticked and list[1].why == "", "a thing left for a click")
check(list[2].name == "Bound Ring" and list[2].ticked and list[2].why == ns.TEXT.whyList, "a thing on your word")
check(list[4].name == "Shiny Gem" and not list[4].ticked and list[4].why == ns.TEXT.whyNever, "a thing never taken")
options.takeTrade = true
ns.Items.Refresh()
list = Listed()
check(list[3].name == "Linen Cloth" and list[3].ticked and list[3].why == ns.TEXT.takeTrade, "taken by its kind's switch")
list[3].frame.check._scripts.OnClick(list[3].frame.check)
check(options.kept[2589] == false, "unticked: your word, never, over the switch")
list = Listed()
list[3].frame.check._scripts.OnClick(list[3].frame.check)
check(options.kept[2589] == nil, "ticked again: the switch says it anyway, the word goes")
list = Listed()
list[1].frame.check._scripts.OnClick(list[1].frame.check)
check(options.kept[6000] == true, "a thing ticked: taken at once from now on")
options.takeTrade = false
ns.Items.forget._scripts.OnClick(ns.Items.forget)
list = Listed()
check(#list == 3 and #options.seen == 0, "Forget the rest: only those with a word stay")
options.kept = {}
ns.Items.Refresh()
check(#Listed() == 0, "nothing left")
loot = { Slot(GEM), Slot(TUSK) }
Open()
check(options.seen[1] == 9000 and options.seen[2] == 8000, "what is met in loot comes into the list, newest first")
Window.Close()
W.Fire("LOOT_CLOSED")

-- the options page: in tabs, Your items last, filled by the module
check(Core.Tabbed(ns.name), "the options page is one in tabs")
local page = CreateFrame("Frame", nil, UIParent)
Core.Config.BuildTabbed(page, ns.name)
check(page.tabs and #page.tabs == 4 and page.parts[4].child and page.parts[4].child._height > 0,
    "its tabs: the switches', then Your items")

-- switched off: the game's own window, and its Auto Loot as it was
Core.Set(ns.name, "window", false)
check(LootFrame:IsEventRegistered("LOOT_OPENED") and C_CVar.GetCVar("autoLootDefault") == "1"
      and options.lent.autoLootDefault == nil, "ours off: the game's window and its Auto Loot back")
Core.Set(ns.name, "window", true)
check(not LootFrame:IsEventRegistered("LOOT_OPENED") and C_CVar.GetCVar("autoLootDefault") == "0", "and ours again")

-------------------------------------------------------------------------------
--  Retail
-------------------------------------------------------------------------------
W.Play("retail")
loot = { Slot(ROBE), Coins(5) }
Open()
check(Shown() and #Rows() == 1 and taken[1] == 2, "Retail: the same window and rules")
Window.Close()
W.Play("forever")

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
loot = { Slot(ROBE) }
Open()
ns.StandDown("a test")
check(ns.off and LootFrame:IsEventRegistered("LOOT_OPENED"), "stood down: the game's loot window hears loot again")
check(GroupLootContainer:GetParent() == UIParent, "and its roll frames are back")
check(C_CVar.GetCVar("autoLootDefault") == "1", "and its Auto Loot as it was")
check(not Shown(), "ours is closed")
Open()
check(not Shown() and #taken == 0, "and opens no more")

io.write(("Loot: all %d checks passed.\n"):format(passed))
