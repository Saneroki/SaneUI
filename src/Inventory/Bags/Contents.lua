local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Contents
--  What the player's bags hold, as the game tells it, without a frame: the
--  containers (the backpack, the bags, the reagent bag, the keyring; the
--  bank's tabs while the bank is open), what is in each slot, the free slots
--  by kind of bag, the group each item is in, what is junk, and the orders
--  items are sorted by. The bag window (Bags.lua) reads it and draws; the
--  tests run it without the game.
--
--  A slot's record is kept and filled anew at each reading, never made again
--  while the bags change:
--      { bag, slot, item, count, quality, link, name, icon, locked, bound,
--        worthless, readable, quest, questID, questActive, new, class,
--        subclass, equip, level, natural, home, junk, group, place }
--  item nil: the slot is empty. place: "bags" (carried) or the bank's kind.
--
--  The groups are the game's own (its auction house's categories, as
--  Camelot lists them, in their order), with what is pinned and what is new
--  first and the junk last; an item goes by its class
--  (C_Item.GetItemInfoInstant), a quest item by what the game says of it
--  (C_Container.GetContainerItemQuestInfo): its natural group. The player may
--  put it into another (home), pin it, rename, move, hide or join the groups
--  (Groups.lua); group is the one it shows in.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Contents = {}
ns.Contents = Contents

local Plain, Ask = Core.Plain, Core.Ask

local INDEX = Enum and Enum.BagIndex or {}
local CLASS = Enum and Enum.ItemClass or {}
local QUALITY = Enum and Enum.ItemQuality or {}
local BANK_TYPE = Enum and Enum.BankType or {}
Contents.KEYRING = INDEX.Keyring or -1
Contents.BACKPACK = INDEX.Backpack or 0
Contents.POOR = QUALITY.Poor or 0

-- The groups in the order they are shown at first (Groups.lua: in the player's order).
Contents.GROUPS = {
    { key = "pinned", word = ns.TEXT.bagsPinned },
    { key = "new", word = Core.Word("NEW", "New") },
    { key = "weapons", word = Core.Word("AUCTION_CATEGORY_WEAPONS", "Weapons") },
    { key = "armor", word = Core.Word("AUCTION_CATEGORY_ARMOR", "Armor") },
    { key = "containers", word = Core.Word("AUCTION_CATEGORY_CONTAINERS", "Containers") },
    { key = "consumables", word = Core.Word("AUCTION_CATEGORY_CONSUMABLES", "Consumables") },
    { key = "trade", word = Core.Word("AUCTION_CATEGORY_TRADE_GOODS", "Trade Goods") },
    { key = "ammo", word = Core.Word("AUCTION_CATEGORY_PROJECTILE", "Ammo") },
    { key = "recipes", word = Core.Word("AUCTION_CATEGORY_RECIPES", "Recipes") },
    { key = "quest", word = Core.Word("AUCTION_CATEGORY_QUEST_ITEMS", "Quest Items") },
    { key = "other", word = Core.Word("AUCTION_CATEGORY_MISCELLANEOUS", "Miscellaneous") },
    { key = "junk", word = Core.Word("BAG_FILTER_JUNK", "Junk") },
}
Contents.GROUP = {} -- [key] = { key, word }
for _, group in ipairs(Contents.GROUPS) do Contents.GROUP[group.key] = group end

-- An item's class to its group, as the game's auction house sorts them; a class not named is "other".
Contents.CLASSES = {
    [CLASS.Weapon or 2] = "weapons", [CLASS.Armor or 4] = "armor",
    [CLASS.Container or 1] = "containers", [CLASS.Quiver or 11] = "containers",
    [CLASS.Consumable or 0] = "consumables", [CLASS.ItemEnhancement or 8] = "consumables",
    [CLASS.Tradegoods or 7] = "trade", [CLASS.Reagent or 5] = "trade", [CLASS.Gem or 3] = "trade",
    [CLASS.Projectile or 6] = "ammo", [CLASS.Recipe or 9] = "recipes", [CLASS.Questitem or 12] = "quest",
}
-- The classes whose items carry an item level worth showing: what is worn.
Contents.GEAR = { [CLASS.Weapon or 2] = true, [CLASS.Armor or 4] = true }

-------------------------------------------------------------------------------
--  The containers
-------------------------------------------------------------------------------
local function Containers()
    local api = rawget(_G, "C_Container")
    return api and api.GetContainerNumSlots and api.GetContainerItemInfo and api or nil
end

local function Constant(name, fallback)
    local constants = rawget(_G, "Constants") and Constants.InventoryConstants
    return constants and constants[name] or fallback
end

-- How many slots a container has; 0 for one the character does not have.
function Contents.Size(bag)
    local api = Containers()
    local size = api and Plain(Ask(api.GetContainerNumSlots, bag))
    return type(size) == "number" and size > 0 and size or 0
end

-- The bags carried, in the order shown: the backpack, the bags, the reagent bag, the keyring. Only those
-- with slots. into: a list to fill (emptied first).
function Contents.Carried(into)
    for index = #into, 1, -1 do into[index] = nil end
    local bags = Constant("NumBagSlots", rawget(_G, "NUM_BAG_SLOTS") or 4)
    local last = bags + Constant("NumReagentBagSlots", 0)
    for bag = Contents.BACKPACK, last do
        if Contents.Size(bag) > 0 then into[#into + 1] = bag end
    end
    if Contents.Size(Contents.KEYRING) > 0 then into[#into + 1] = Contents.KEYRING end
    return into
end

-- Whether a container is a reagent bag (only reagents go in).
function Contents.Reagent(bag)
    local bags = Constant("NumBagSlots", rawget(_G, "NUM_BAG_SLOTS") or 4)
    return bag > bags and bag <= bags + Constant("NumReagentBagSlots", 0)
end

-- The banks the game lets the player see now, each { kind, word, bags = { tab IDs } }, in the order shown:
-- the character's own, then the account's. Only while the bank is open (Contents.bankOpen, the window's).
Contents.BANKS = {
    { type = BANK_TYPE.Character, kind = "bank", word = Core.Word("BANK", "Bank") },
    { type = BANK_TYPE.Account, kind = "account", word = Core.Word("ACCOUNT_BANK_PANEL_TITLE", "Account Bank") },
}
function Contents.Banks(into)
    for index = #into, 1, -1 do into[index] = nil end
    local bank = rawget(_G, "C_Bank")
    if not (Contents.bankOpen and bank and bank.FetchPurchasedBankTabIDs) then return into end
    for _, kind in ipairs(Contents.BANKS) do
        local viewable = kind.type and (not bank.CanViewBank or Ask(bank.CanViewBank, kind.type) ~= false)
        local tabs = viewable and Ask(bank.FetchPurchasedBankTabIDs, kind.type)
        kind.bags = kind.bags or {}
        for index = #kind.bags, 1, -1 do kind.bags[index] = nil end
        if type(tabs) == "table" then
            for _, bag in ipairs(tabs) do
                bag = Plain(bag)
                if type(bag) == "number" and Contents.Size(bag) > 0 then kind.bags[#kind.bags + 1] = bag end
            end
        end
        if #kind.bags > 0 then into[#into + 1] = kind end
    end
    return into
end

-------------------------------------------------------------------------------
--  The slots
-------------------------------------------------------------------------------
local records = {} -- [bag] = { [slot] = record }
Contents.records = records
Contents.waiting = {} -- [item] = true: the game did not know its name or item level yet (GET_ITEM_INFO_RECEIVED)

-- The record of a slot (made once).
function Contents.Record(bag, slot)
    local slots = records[bag]
    if not slots then
        slots = {}
        records[bag] = slots
    end
    local record = slots[slot]
    if not record then
        record = { bag = bag, slot = slot }
        slots[slot] = record
    end
    return record
end

local function Instant(item)
    local items = rawget(_G, "C_Item")
    local fn = items and items.GetItemInfoInstant or rawget(_G, "GetItemInfoInstant")
    if not fn then return nil end
    local ok, _, _, _, equip, _, class, subclass = pcall(fn, item)
    if not ok then return nil end
    return Plain(class), Plain(subclass), Plain(equip)
end

-- An item's level, for gear only; nil while the game does not know it yet.
local function Level(link, class)
    if not (link and Contents.GEAR[class]) then return nil end
    local items = rawget(_G, "C_Item")
    local fn = items and items.GetDetailedItemLevelInfo or rawget(_G, "GetDetailedItemLevelInfo")
    local level = fn and Plain(Ask(fn, link))
    return type(level) == "number" and level > 0 and level or nil
end

-- The group of its kind a record with an item goes in: a quest's, else its class's.
function Contents.Classed(record)
    if record.quest or record.questID then return "quest" end
    return Contents.CLASSES[record.class] or "other"
end

-- The game's group for a record with an item: junk (grey with a price), else the group of its kind.
function Contents.Natural(record)
    if record.quality == Contents.POOR and not record.worthless then return "junk" end
    return Contents.Classed(record)
end

-- Where a record with an item goes, anew: home (the player's group for it, else its natural one); whether it
-- is junk (in Junk with a price, not pinned); the group it shows in: Pinned, else New while new, else its
-- home's (or the group that one is joined into).
function Contents.Place(record, new)
    local Groups = ns.Groups
    local pinned = Groups.Pinned(record.item)
    record.home = Groups.Home(record.item, record.natural)
    record.junk = record.home == Groups.JUNK and not record.worthless and not pinned
    if pinned then
        record.group = Groups.PINNED
    elseif new then
        record.group = Groups.NEW
    else
        record.group = Groups.Shown(record.home)
    end
    return record
end

local function Bool(value)
    return Plain(value) == true
end

-- A slot read anew into its record; returns the record.
function Contents.Read(bag, slot, place)
    local record = Contents.Record(bag, slot)
    record.place = place or "bags"
    local api = Containers()
    local info = api and Ask(api.GetContainerItemInfo, bag, slot)
    local item = type(info) == "table" and Plain(info.itemID) or nil
    record.item = type(item) == "number" and item or nil
    if not record.item then
        record.count, record.quality, record.link, record.name, record.icon = nil, nil, nil, nil, nil
        record.locked, record.bound, record.worthless, record.readable, record.quest = false, false, false, false, false
        record.questID, record.questActive, record.new = nil, false, false
        record.class, record.subclass, record.equip, record.level, record.group = nil, nil, nil, nil, nil
        record.natural, record.home, record.junk = nil, nil, false
        return record
    end
    local count = Plain(info.stackCount)
    record.count = type(count) == "number" and count or 1
    record.quality = Plain(info.quality)
    record.link = Plain(info.hyperlink)
    local name = Plain(info.itemName)
    record.name = type(name) == "string" and name ~= "" and name
        or record.link and Core.Fuzzy.Plain(record.link):match("%[(.-)%]") or ""
    record.icon = Plain(info.iconFileID)
    record.locked, record.bound = Bool(info.isLocked), Bool(info.isBound)
    record.worthless, record.readable = Bool(info.hasNoValue), Bool(info.isReadable)
    local quest = api.GetContainerItemQuestInfo and Ask(api.GetContainerItemQuestInfo, bag, slot)
    quest = type(quest) == "table" and quest or nil
    record.quest = quest and Bool(quest.isQuestItem) or false
    record.questID = quest and Plain(quest.questID) or nil
    record.questActive = quest and Bool(quest.isActive) or false
    local new = rawget(_G, "C_NewItems")
    record.new = new and new.IsNewItem and Ask(new.IsNewItem, bag, slot) == true or false
    record.class, record.subclass, record.equip = Instant(record.item)
    record.level = Level(record.link, record.class)
    if record.name == "" or Contents.GEAR[record.class] and not record.level then Contents.waiting[record.item] = true end
    record.natural = Contents.Natural(record)
    return Contents.Place(record, record.new)
end

-------------------------------------------------------------------------------
--  Free slots
-------------------------------------------------------------------------------
-- A container's free slots and the kind of bag it is: "bags" for those any item goes in (the backpack and
-- ordinary bags, the bank's tabs: their place instead), else the container itself (a reagent bag, the
-- keyring, a bag for one kind of item only: the game's bag family).
function Contents.Kind(bag, place)
    if place and place ~= "bags" then return place end
    if bag == Contents.KEYRING or Contents.Reagent(bag) then return bag end
    local api = Containers()
    local _, family = Ask(api and api.GetContainerNumFreeSlots, bag)
    family = Plain(family)
    if type(family) == "number" and family ~= 0 then return bag end
    return "bags"
end

-- The name a kind of bag is shown by.
function Contents.KindWord(kind)
    if kind == "bags" then return Core.Word("HUD_EDIT_MODE_BAGS_LABEL", "Bags") end
    if kind == Contents.KEYRING then return Core.Word("KEYRING", "Keyring") end
    for _, bank in ipairs(Contents.BANKS) do
        if bank.kind == kind then return bank.word end
    end
    local api = Containers()
    local name = type(kind) == "number" and api and api.GetBagName and Plain(Ask(api.GetBagName, kind))
    return type(name) == "string" and name ~= "" and name or Core.Word("BAGSLOT", "Bag")
end

-- A tally of free slots, kept and filled anew: free.kinds = { kind, ... } in the order met, and
-- free[kind] = { kind, count (free), total (slots), bag, slot (the first free one) }; free.count and
-- free.total for the ordinary bags (the kind "bags").
function Contents.ClearFree(free)
    free.kinds = free.kinds or {}
    for index = #free.kinds, 1, -1 do
        local entry = free[free.kinds[index]]
        entry.count, entry.total, entry.bag, entry.slot = 0, 0, nil, nil
        free.kinds[index] = nil
    end
    free.count, free.total = 0, 0
    return free
end

local function Tally(free, kind, record)
    local entry = free[kind]
    if not entry then
        entry = { kind = kind, count = 0, total = 0 }
        free[kind] = entry
    end
    if entry.total == 0 and entry.count == 0 then free.kinds[#free.kinds + 1] = kind end
    entry.total = entry.total + 1
    if not record.item then
        entry.count = entry.count + 1
        if not entry.bag then entry.bag, entry.slot = record.bag, record.slot end
    end
    if kind == "bags" then
        free.total = free.total + 1
        if not record.item then free.count = free.count + 1 end
    end
end

-- Every slot of these containers read (in their order) and added to slots, the free ones tallied in free;
-- place: "bags" (carried) or a bank's kind.
function Contents.Scan(bags, place, slots, free)
    for _, bag in ipairs(bags) do
        local kind = Contents.Kind(bag, place)
        for slot = 1, Contents.Size(bag) do
            local record = Contents.Read(bag, slot, place)
            record.kind = kind
            slots[#slots + 1] = record
            Tally(free, kind, record)
        end
    end
    return slots, free
end

-------------------------------------------------------------------------------
--  Orders
-------------------------------------------------------------------------------
-- How a view sorts what is in a group: by the first of these that differs, then by the one after; at last by
-- the bag and slot, so that an item keeps its place while only its count changes.
Contents.ORDERS = {
    { key = "quality", word = Core.Word("QUALITY", "Quality") },
    { key = "name", word = Core.Word("NAME", "Name") },
    { key = "level", word = Core.Word("STAT_AVERAGE_ITEM_LEVEL", "Item Level") },
}

-- Each order's tests: a < b (a comes first), b < a, or neither.
local function ByQuality(a, b)
    local qa, qb = a.quality or -1, b.quality or -1
    if qa ~= qb then return qa > qb end
end
local function ByLevel(a, b)
    local la, lb = a.level or 0, b.level or 0
    if la ~= lb then return la > lb end
end
local function ByName(a, b)
    local na, nb = a.name or "", b.name or ""
    if na ~= nb then return na < nb end
end
local function ByPlace(a, b)
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end
local TESTS = {
    quality = { ByQuality, ByLevel, ByName },
    name = { ByName, ByQuality },
    level = { ByLevel, ByQuality, ByName },
}

-- One comparison per order, grouped (the group's place in the player's order first) or not; made once.
local COMPARE = {}
local rank -- the groups' places (Groups.rank; Groups.lua comes later in the TOC): taken at each sort
for key, tests in pairs(TESTS) do
    local function Compare(a, b)
        for _, test in ipairs(tests) do
            local first = test(a, b)
            if first ~= nil then return first end
        end
        return ByPlace(a, b)
    end
    COMPARE[key] = Compare
    COMPARE[key .. "+group"] = function(a, b)
        local ra, rb = rank[a.group] or math.huge, rank[b.group] or math.huge
        if ra ~= rb then return ra < rb end
        return Compare(a, b)
    end
end

-- A list of records with items sorted by order ("quality", "name", "level"), by group first if grouped.
function Contents.Sort(list, order, grouped)
    local compare = COMPARE[(TESTS[order] and order or "quality") .. (grouped and "+group" or "")]
    rank = ns.Groups.rank
    table.sort(list, compare)
    return list
end

-------------------------------------------------------------------------------
--  Search
-------------------------------------------------------------------------------
-- Whether a record with an item is found by a query (Core.Fuzzy.Query): by its name, its group's name or
-- its item level.
function Contents.Found(record, query)
    if not query then return true end
    if not record.item then return false end
    return Core.Fuzzy.Match(query, record.name, ns.Groups.Word(record.group), record.level and tostring(record.level)) ~= nil
end

-------------------------------------------------------------------------------
--  Junk
-------------------------------------------------------------------------------
-- The records of these slots that are junk, into a list (emptied first); and whether they are just what the
-- game sells as junk (its grey items with a price), so that the game's own sell-all does it.
function Contents.Junk(slots, into)
    for index = #into, 1, -1 do into[index] = nil end
    local same = true
    for _, record in ipairs(slots) do
        if record.item then
            if record.junk then into[#into + 1] = record end
            if record.junk ~= (record.quality == Contents.POOR and not record.worthless) then same = false end
        end
    end
    return into, same
end
