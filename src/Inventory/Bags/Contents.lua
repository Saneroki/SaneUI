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
--        subclass, equip, level, category, junk, pinned, set, reagentBag,
--        special, kind, place,
--        boe (binds when equipped), bind (the game's bind type), sell (one's
--        price at a vendor), required (the level it needs), kindName,
--        subName (the game's words for its class and subclass), unusable }
--  item nil: the slot is empty. place: "bags" (carried) or the bank's kind.
--  unusable: the character cannot use or wear it (a line of its tooltip in
--  the game's red), asked once per item link until the next level.
--
--  Its category is Categories.lua's (record.category), from its class
--  (C_Item.GetItemInfoInstant), what the game says of a quest item
--  (C_Container.GetContainerItemQuestInfo), the bag it is in (reagentBag,
--  special: a bag for one kind of item) and the equipment set it is in (set:
--  the set's name, the first set that has that slot).
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

-- What the game says of an item beyond its slot (C_Item.GetItemInfo): its bind type, price, the level it needs,
-- its class's and subclass's words; nil while the game does not know it yet.
local function Info(record)
    local items = rawget(_G, "C_Item")
    local fn = items and items.GetItemInfo or rawget(_G, "GetItemInfo")
    if not fn then return true end
    local ok, name, _, _, _, required, kindName, subName, _, _, _, sell, _, _, bind = pcall(fn, record.link or record.item)
    if not ok or Plain(name) == nil then return end
    record.required, record.kindName, record.subName = Plain(required), Plain(kindName), Plain(subName)
    record.sell, record.bind = Plain(sell), Plain(bind)
    return true
end

-- Whether the character cannot use an item: a line of its tooltip in the game's red (a recipe: the game's own
-- answer); kept per link until the next level (Contents.Leveled).
local unusable = {}
local function Red(color)
    return type(color) == "table" and (color.r or 0) > 0.9 and (color.g or 1) < 0.2 and (color.b or 1) < 0.2
end
local function Unusable(record)
    local link = record.link
    if not link then return false end
    local known = unusable[link]
    if known ~= nil then return known end
    local items = rawget(_G, "C_Item") or {}
    local answer = false
    if record.class == (CLASS.Recipe or 9) and items.IsUsableItem then
        answer = Ask(items.IsUsableItem, link) ~= true
    elseif Contents.GEAR[record.class] or items.GetItemSpell and Ask(items.GetItemSpell, link) then
        local tips = rawget(_G, "C_TooltipInfo")
        local data = tips and tips.GetBagItem and Ask(tips.GetBagItem, record.bag, record.slot)
        if type(data) ~= "table" or type(data.lines) ~= "table" then return false end
        for _, line in ipairs(data.lines) do
            if Red(line.leftColor) or Red(line.rightColor) then
                answer = true
                break
            end
        end
    end
    unusable[link] = answer
    return answer
end

function Contents.Leveled()
    for link in pairs(unusable) do unusable[link] = nil end
end

-- The equipment sets' slots in the bags and the bank: ["bag:slot"] = the first set's name; read anew before the
-- slots are (Contents.Sets).
Contents.setAt = {}
function Contents.Sets()
    local at = Contents.setAt
    for key in pairs(at) do at[key] = nil end
    local sets = rawget(_G, "C_EquipmentSet")
    local unpack = rawget(_G, "EquipmentManager_GetLocationData")
    if not (sets and sets.GetEquipmentSetIDs and sets.GetItemLocations and unpack) then return at end
    for _, id in ipairs(Ask(sets.GetEquipmentSetIDs) or {}) do
        local name = sets.GetEquipmentSetInfo and Plain(Ask(sets.GetEquipmentSetInfo, id))
        for _, location in pairs(Ask(sets.GetItemLocations, id) or {}) do
            location = Plain(location)
            local data = type(location) == "number" and location >= 0 and Ask(unpack, location)
            if type(data) == "table" and data.isBags and data.bag and data.slot then
                local key = data.bag .. ":" .. data.slot
                if not at[key] then at[key] = name or "" end
            end
        end
    end
    return at
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
        record.class, record.subclass, record.equip, record.level, record.category = nil, nil, nil, nil, nil
        record.junk, record.pinned, record.set = false, false, nil
        record.boe, record.bind, record.sell, record.required, record.kindName, record.subName = false, nil, nil, nil, nil, nil
        record.unusable = false
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
    local known = Info(record)
    record.boe = Contents.GEAR[record.class] and (record.bind == (Enum and Enum.ItemBind and Enum.ItemBind.OnEquip or 2)) or false
    record.unusable = Unusable(record)
    if not known or record.name == "" or Contents.GEAR[record.class] and not record.level then Contents.waiting[record.item] = true end
    record.set = Contents.setAt[bag .. ":" .. slot]
    ns.Categories.Classify(record)
    return record
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

-- The name a bag is shown by: the backpack, the reagent bag, the keyring, the bag's own name; a bank's tab by
-- its number in that bank.
function Contents.BagWord(bag, place)
    if bag == Contents.BACKPACK then return Core.Word("BAG_NAME_BACKPACK", Core.Word("BACKPACK_TOOLTIP", "Backpack")) end
    if bag == Contents.KEYRING then return Core.Word("KEYRING", "Keyring") end
    if (not place or place == "bags") and Contents.Reagent(bag) then return ns.TEXT.bagsReagentBag end
    if place and place ~= "bags" then
        local bank = rawget(_G, "C_Bank")
        for _, kind in ipairs(Contents.BANKS) do
            if kind.kind == place and bank and bank.FetchPurchasedBankTabData and kind.type then
                for index, tab in ipairs(Ask(bank.FetchPurchasedBankTabData, kind.type) or {}) do
                    if Plain(tab.ID) == bag then
                        local name = Plain(tab.name)
                        return type(name) == "string" and name ~= "" and name or ns.TEXT.bagsTab:format(index)
                    end
                end
            end
        end
    end
    local api = Containers()
    local name = api and api.GetBagName and Plain(Ask(api.GetBagName, bag))
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
        local carried = not place or place == "bags"
        for slot = 1, Contents.Size(bag) do
            local record = Contents.Record(bag, slot)
            record.reagentBag = carried and Contents.Reagent(bag)
            record.special = carried and kind ~= "bags" and not record.reagentBag
            Contents.Read(bag, slot, place)
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
    { key = "default", word = Core.Word("DEFAULT", "Default") },
    { key = "quality", word = Core.Word("QUALITY", "Quality") },
    { key = "name", word = Core.Word("NAME", "Name") },
    { key = "level", word = Core.Word("STAT_AVERAGE_ITEM_LEVEL", "Item Level") },
}

-- Each order's tests: a < b (a comes first), b < a, or neither. The first order: gear by item level, then the
-- game's subclass words, the quality, the name.
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
local function ByGear(a, b)
    local ga, gb = Contents.GEAR[a.class] and a.level or 0, Contents.GEAR[b.class] and b.level or 0
    if ga ~= gb then return ga > gb end
end
local function ByKind(a, b)
    local ka, kb = a.subName or "", b.subName or ""
    if ka ~= kb then return ka < kb end
end
local function ByItem(a, b)
    if a.item ~= b.item then return (a.item or 0) < (b.item or 0) end
end
local TESTS = {
    default = { ByGear, ByKind, ByQuality, ByName, ByItem },
    quality = { ByQuality, ByLevel, ByName },
    name = { ByName, ByQuality },
    level = { ByLevel, ByQuality, ByName },
}

-- One comparison per order; made once. A list holds records, or entries { record, count } (a merged stack).
local COMPARE = {}
for key, tests in pairs(TESTS) do
    COMPARE[key] = function(a, b)
        a, b = a.record or a, b.record or b
        for _, test in ipairs(tests) do
            local first = test(a, b)
            if first ~= nil then return first end
        end
        return ByPlace(a, b)
    end
end

-- A list of records (or entries) with items sorted by order (Contents.ORDERS' keys).
function Contents.Sort(list, order)
    table.sort(list, COMPARE[TESTS[order] and order or "default"])
    return list
end

-------------------------------------------------------------------------------
--  Search
-------------------------------------------------------------------------------
-- Whether a record with an item is found by a query (Core.Fuzzy.Query): by its name, its category's name or
-- its item level.
function Contents.Found(record, query)
    if not query then return true end
    if not record.item then return false end
    return Core.Fuzzy.Match(query, record.name, ns.Categories.Word(record.category), record.level and tostring(record.level)) ~= nil
end

-------------------------------------------------------------------------------
--  Junk
-------------------------------------------------------------------------------
-- The records of these slots that are junk to sell, into a list (emptied first): not in a special bag, not in
-- an equipment set, not pinned, with a price, not one the vendor would buy back for its price (refundable).
-- And whether they are just what the game sells as junk (its grey items with a price), so that the game's own
-- sell-all does it.
local function Refundable(record)
    local api = Containers()
    local info = api and api.GetContainerItemPurchaseInfo and Ask(api.GetContainerItemPurchaseInfo, record.bag, record.slot, false)
    return type(info) == "table" and (Plain(info.refundSeconds) or 0) > 0
end
function Contents.Junk(slots, into)
    for index = #into, 1, -1 do into[index] = nil end
    local same = true
    for _, record in ipairs(slots) do
        if record.item then
            local sold = record.junk and not record.special and not record.set and not record.pinned and not Refundable(record)
            if sold then into[#into + 1] = record end
            if (sold or false) ~= (record.quality == Contents.POOR and not record.worthless) then same = false end
        end
    end
    return into, same
end
