local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Rewards
--  A quest's rewards as the NPC offers them (the quest window's own calls),
--  each item read for you, so that its line says it without its tooltip
--  (Saneroki, 2026-10-28):
--    - what it is: armour by its kind (Cloth, Leather, Mail, Plate) and its
--      slot; what everybody wears (a cloak, a ring, a neck, a trinket, a shirt)
--      by its slot alone; a weapon by its kind, and its hand where only one
--      hand holds it; else the game's kind of thing (a potion, a bag);
--    - whether you can use it, as the game says (its red in its own window);
--    - what a vendor pays for it, for all of them;
--    - what it changes against what you wear in its slot: its item level next
--      to the one worn, and the stats that go up and down, as the game works
--      them out (C_Item.GetItemStatDelta); for two slots of a kind (rings,
--      trinkets) against the weaker one worn; an empty slot says so.
--  An item the game has not described yet has its name and icon only: the game
--  tells it soon after (QUEST_ITEM_UPDATE, GET_ITEM_INFO_RECEIVED), and the
--  talk draws its rewards anew then (Talk.lua).
--
--      Rewards.Read(shown)       the rewards of the quest at hand ({} where the game shows none:
--                                shown false): { choices, items, spells, currencies, money, xp, honor, title }
--          an item:              { kind = "choice" or "reward", index, name, icon, count, quality, usable, link }
--          a currency:           the same with currency = true
--      Rewards.Describe(item)    what its line says: item.what, item.cantUse, item.value (copper),
--                                item.level, item.worn (the item level worn), item.empty, item.changes
--      Rewards.Changes(new, old) the stats that change from old to new, the largest first:
--                                { { key, name, amount }, ... }
--      Rewards.Required()        what a quest in progress asks for: { items, money }
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Rewards = {}
ns.Rewards = Rewards

Rewards.STATS = 4 -- the most stat changes a line names (the tooltip has them all)

local ARMOR, WEAPON = 4, 2 -- the game's item classes (Enum.ItemClass)
local MISC = 0             -- an armour's subclass for what is no cloth, leather, mail or plate
local DOT = " \194\183 "

-- Worn by every class, whatever armour it wears: said by the slot alone.
local ANYBODY = {
    INVTYPE_CLOAK = true, INVTYPE_FINGER = true, INVTYPE_NECK = true, INVTYPE_TRINKET = true,
    INVTYPE_BODY = true, INVTYPE_TABARD = true, INVTYPE_HOLDABLE = true,
}
-- A weapon held in one hand only: its hand said too.
local ONE_HAND = { INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true }

-- Where an item is worn: the game's slot numbers by their names (INVSLOT_*). Ranged things where the game
-- has no ranged slot (Retail): the main hand.
local SLOTS = {
    INVTYPE_HEAD = { "INVSLOT_HEAD" }, INVTYPE_NECK = { "INVSLOT_NECK" }, INVTYPE_SHOULDER = { "INVSLOT_SHOULDER" },
    INVTYPE_BODY = { "INVSLOT_BODY" }, INVTYPE_CHEST = { "INVSLOT_CHEST" }, INVTYPE_ROBE = { "INVSLOT_CHEST" },
    INVTYPE_WAIST = { "INVSLOT_WAIST" }, INVTYPE_LEGS = { "INVSLOT_LEGS" }, INVTYPE_FEET = { "INVSLOT_FEET" },
    INVTYPE_WRIST = { "INVSLOT_WRIST" }, INVTYPE_HAND = { "INVSLOT_HAND" },
    INVTYPE_FINGER = { "INVSLOT_FINGER1", "INVSLOT_FINGER2" },
    INVTYPE_TRINKET = { "INVSLOT_TRINKET1", "INVSLOT_TRINKET2" },
    INVTYPE_CLOAK = { "INVSLOT_BACK" }, INVTYPE_WEAPON = { "INVSLOT_MAINHAND" },
    INVTYPE_2HWEAPON = { "INVSLOT_MAINHAND" }, INVTYPE_WEAPONMAINHAND = { "INVSLOT_MAINHAND" },
    INVTYPE_WEAPONOFFHAND = { "INVSLOT_OFFHAND" }, INVTYPE_SHIELD = { "INVSLOT_OFFHAND" },
    INVTYPE_HOLDABLE = { "INVSLOT_OFFHAND" }, INVTYPE_TABARD = { "INVSLOT_TABARD" },
    INVTYPE_RANGED = { "ranged" }, INVTYPE_RANGEDRIGHT = { "ranged" }, INVTYPE_THROWN = { "ranged" },
    INVTYPE_RELIC = { "ranged" },
}
-- First in a line of stat changes: a weapon's damage, then armour; the rest by how much they change.
local FIRST = { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 1, RESISTANCE0_NAME = 2 }

local rangedSlot -- the ranged slot's number, false where the game has none (asked once)

local function Slot(name)
    if name == "ranged" then
        if rangedSlot == nil then rangedSlot = Core.Ask(rawget(_G, "GetInventorySlotInfo"), "RangedSlot") or false end
        return rangedSlot or rawget(_G, "INVSLOT_MAINHAND")
    end
    return rawget(_G, name)
end

-- The game's description of an item: nil while it has none yet.
local function Info(link)
    local get = (C_Item and C_Item.GetItemInfo) or rawget(_G, "GetItemInfo")
    if type(get) ~= "function" or type(link) ~= "string" then return nil end
    local ok, name, _, _, level, _, kind, subKind, _, slot, _, price, class, subclass = pcall(get, link)
    if not ok or not name then return nil end
    return { kind = kind, subKind = subKind, slot = slot, price = price, class = class, subclass = subclass,
             level = level }
end

-- An item's level as it is worn (scaled where the game scales it).
local function Level(link, info)
    local detailed = C_Item and C_Item.GetDetailedItemLevelInfo
    local level = detailed and Core.Ask(detailed, link)
    if type(level) == "number" and level > 0 then return level end
    info = info or Info(link)
    return info and info.level or nil
end

local function Join(first, second)
    if first and first ~= "" and second and second ~= "" then return first .. DOT .. second end
    if first and first ~= "" then return first end
    return second
end

local function What(info)
    local slotWord = info.slot and info.slot ~= "" and rawget(_G, info.slot) or nil
    if type(slotWord) ~= "string" then slotWord = nil end
    if info.class == ARMOR then
        if ANYBODY[info.slot] or info.subclass == MISC then return slotWord or info.subKind end
        return Join(info.subKind, slotWord)
    elseif info.class == WEAPON then
        return ONE_HAND[info.slot] and Join(info.subKind, slotWord) or info.subKind
    end
    if info.subKind and info.subKind ~= "" and info.subKind ~= info.kind then return info.subKind end
    return info.kind
end

function Rewards.Changes(new, old)
    local delta = (C_Item and C_Item.GetItemStatDelta) or rawget(_G, "GetItemStatDelta")
    local list = {}
    if type(delta) ~= "function" then return list end
    local ok, stats = pcall(delta, new, old)
    if not ok or type(stats) ~= "table" then return list end
    for key, amount in pairs(stats) do
        amount = Core.Plain(amount)
        local name = type(key) == "string" and rawget(_G, key)
        if type(amount) == "number" and amount ~= 0 and type(name) == "string" then
            list[#list + 1] = { key = key, name = Core.StatWord(name), amount = amount }
        end
    end
    table.sort(list, function(a, b)
        local fa, fb = FIRST[a.key] or 9, FIRST[b.key] or 9
        if fa ~= fb then return fa < fb end
        if math.abs(a.amount) ~= math.abs(b.amount) then return math.abs(a.amount) > math.abs(b.amount) end
        return a.name < b.name
    end)
    return list
end

-- Against what you wear in its slot: the weaker of two, or nothing worn there.
local function Against(item, info)
    local slots = SLOTS[info.slot]
    if not slots then return end
    local worn, wornLevel
    for _, name in ipairs(slots) do
        local slot = Slot(name)
        local link = slot and Core.Ask(GetInventoryItemLink, "player", slot)
        if not link then
            item.empty = true
            return
        end
        local level = Level(link) or 0
        if not worn or level < wornLevel then worn, wornLevel = link, level end
    end
    item.worn = wornLevel
    item.changes = Rewards.Changes(item.link, worn)
end

function Rewards.Describe(item)
    item.what, item.cantUse, item.value, item.level, item.worn, item.empty, item.changes = nil, nil, nil, nil, nil, nil, nil
    if item.currency then return item end
    item.cantUse = item.usable == false
    local info = Info(item.link)
    if not info then return item end
    item.what = What(info)
    if type(info.price) == "number" then item.value = info.price * math.max(1, item.count or 1) end
    if SLOTS[info.slot] then
        item.level = Level(item.link, info)
        if not item.cantUse then Against(item, info) end
    end
    return item
end

-------------------------------------------------------------------------------
--  Reading them from the game
-------------------------------------------------------------------------------
local function Item(kind, index)
    local ok, name, icon, count, quality, usable = pcall(GetQuestItemInfo, kind, index)
    if not ok then return nil end
    return Rewards.Describe({ kind = kind, index = index, name = name, icon = icon, count = count, quality = quality,
                              usable = usable, link = Core.Ask(GetQuestItemLink, kind, index) })
end

-- A currency to choose (the quest window's own call for it).
local function Currency(kind, index)
    local offer = rawget(_G, "C_QuestOffer")
    local info = offer and offer.GetQuestRewardCurrencyInfo and Core.Ask(offer.GetQuestRewardCurrencyInfo, kind, index)
    if type(info) ~= "table" then return nil end
    return { kind = kind, index = index, currency = true, name = info.name, icon = info.texture, quality = info.quality,
             count = info.totalRewardAmount or info.baseRewardAmount }
end

local function Count(fn)
    local count = Core.Ask(rawget(_G, fn))
    return type(count) == "number" and count or 0
end

function Rewards.Read(shown)
    local list = { choices = {}, items = {}, spells = {}, currencies = {}, shown = shown ~= false,
                   money = 0, xp = 0, honor = 0 }
    if shown == false then return list end
    for index = 1, Count("GetNumQuestChoices") do
        local loot = Core.Ask(rawget(_G, "GetQuestItemInfoLootType"), "choice", index)
        local entry = loot == 1 and Currency("choice", index) or Item("choice", index)
        if entry then list.choices[#list.choices + 1] = entry end
    end
    for index = 1, Count("GetNumQuestRewards") do
        local entry = Item("reward", index)
        if entry then list.items[#list.items + 1] = entry end
    end
    local quest = Core.Ask(rawget(_G, "GetQuestID"))
    local system = rawget(_G, "C_QuestInfoSystem")
    if quest and system then
        local currencies = Core.Ask(system.GetQuestRewardCurrencies, quest)
        for index, info in ipairs(type(currencies) == "table" and currencies or {}) do
            list.currencies[#list.currencies + 1] = { kind = "reward", index = index, currency = true, name = info.name,
                icon = info.texture, quality = info.quality, count = info.totalRewardAmount or info.baseRewardAmount }
        end
        local spells = Core.Ask(system.GetQuestRewardSpells, quest)
        local book = rawget(_G, "C_SpellBook")
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
        for _, id in ipairs(type(spells) == "table" and spells or {}) do
            local info = Core.Ask(system.GetQuestRewardSpellInfo, quest, id)
            local known = book and bank and Core.Ask(book.IsSpellInSpellBook, id, bank, true)
            if type(info) == "table" and info.texture and not known then
                list.spells[#list.spells + 1] = { spell = id, name = info.name, icon = info.texture }
            end
        end
    end
    list.money = Count("GetRewardMoney")
    list.xp = Count("GetRewardXP")
    list.honor = Count("GetRewardHonor")
    list.title = Core.Ask(rawget(_G, "GetRewardTitle"))
    return list
end

-- What a quest in progress asks for: its items (with how many), its money.
function Rewards.Required()
    local list = { items = {} }
    for index = 1, Count("GetNumQuestItems") do
        local ok, name, icon, count, quality = pcall(GetQuestItemInfo, "required", index)
        if ok and name then
            list.items[#list.items + 1] = { kind = "required", index = index, name = name, icon = icon, count = count,
                                           quality = quality, link = Core.Ask(GetQuestItemLink, "required", index) }
        end
    end
    list.money = Count("GetQuestMoneyToGet")
    return list
end
