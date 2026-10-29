local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Upgrade
--  Whether a thing of the loot would make the character better (Saneroki,
--  2026-10-29: a green arrow on it, and the switch Always show upgrades): gear
--  the character can wear now, by the game's own word (C_PlayerInfo.CanUseItem)
--  and its level, and in its place either nothing is worn, or what is worn has
--  a lower item level (of two places of a kind, rings and trinkets, the weaker
--  one). Never armour of a lighter kind than the one worn there (cloth over
--  mail), nor an off hand while a two-handed weapon is held. Shirts, tabards
--  and bags are no gear here.
--
--      Upgrade.Is(line)   "empty" (nothing worn there) or "better" (a higher item level); nil: no upgrade
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Upgrade = {}
ns.Upgrade = Upgrade

local ARMOR = 4                                 -- the game's item class of armour (Enum.ItemClass)
local CLOTH, PLATE = 1, 4                       -- its kinds by weight, cloth to plate (Enum.ItemArmorSubclass)
local TWO_HANDS = { INVTYPE_2HWEAPON = true }

-- Where each kind of gear is worn: the game's places (INVSLOT_*); "ranged" is the ranged place where the game has
-- one, else the main hand (Retail).
local PLACES = {
    INVTYPE_HEAD = { "INVSLOT_HEAD" }, INVTYPE_NECK = { "INVSLOT_NECK" }, INVTYPE_SHOULDER = { "INVSLOT_SHOULDER" },
    INVTYPE_CHEST = { "INVSLOT_CHEST" }, INVTYPE_ROBE = { "INVSLOT_CHEST" }, INVTYPE_WAIST = { "INVSLOT_WAIST" },
    INVTYPE_LEGS = { "INVSLOT_LEGS" }, INVTYPE_FEET = { "INVSLOT_FEET" }, INVTYPE_WRIST = { "INVSLOT_WRIST" },
    INVTYPE_HAND = { "INVSLOT_HAND" }, INVTYPE_CLOAK = { "INVSLOT_BACK" },
    INVTYPE_FINGER = { "INVSLOT_FINGER1", "INVSLOT_FINGER2" }, INVTYPE_TRINKET = { "INVSLOT_TRINKET1", "INVSLOT_TRINKET2" },
    INVTYPE_WEAPON = { "INVSLOT_MAINHAND" }, INVTYPE_2HWEAPON = { "INVSLOT_MAINHAND" },
    INVTYPE_WEAPONMAINHAND = { "INVSLOT_MAINHAND" }, INVTYPE_WEAPONOFFHAND = { "INVSLOT_OFFHAND" },
    INVTYPE_SHIELD = { "INVSLOT_OFFHAND" }, INVTYPE_HOLDABLE = { "INVSLOT_OFFHAND" },
    INVTYPE_RANGED = { "ranged" }, INVTYPE_RANGEDRIGHT = { "ranged" }, INVTYPE_THROWN = { "ranged" },
    INVTYPE_RELIC = { "ranged" },
}
local OFF_HAND = { INVSLOT_OFFHAND = true }

local ranged -- the ranged place's number, false where the game has none (asked once)
local function Place(name)
    if name == "ranged" then
        if ranged == nil then ranged = Core.Ask(rawget(_G, "GetInventorySlotInfo"), "RangedSlot") or false end
        return ranged or rawget(_G, "INVSLOT_MAINHAND")
    end
    return rawget(_G, name)
end

-- What the game says of an item: where it is worn, its item level, the level it asks, its class and kind.
local function Facts(item)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" or not item then return nil end
    local ok, name, _, _, level, needs, _, _, _, where, _, _, class, kind = pcall(info, item)
    if not ok or not name then return nil end
    local detailed = rawget(_G, "C_Item") and C_Item.GetDetailedItemLevelInfo
    local scaled = detailed and Plain(Core.Ask(detailed, item))
    return { where = Plain(where), level = type(scaled) == "number" and scaled > 0 and scaled or Plain(level) or 0,
             needs = Plain(needs) or 0, class = Plain(class), kind = Plain(kind) }
end

-- Whether the character can wear it now: the game's word on the item, and the level it asks.
local function Wearable(line, facts)
    local player = rawget(_G, "C_PlayerInfo")
    if line.id and player and player.CanUseItem and Core.Ask(player.CanUseItem, line.id) == false then return false end
    local level = Plain(Core.Ask(UnitLevel, "player"))
    return not (type(level) == "number" and facts.needs > level)
end

local function Weight(facts)
    if facts and facts.class == ARMOR and type(facts.kind) == "number" and facts.kind >= CLOTH and facts.kind <= PLATE then
        return facts.kind
    end
    return nil
end

function Upgrade.Is(line)
    if not line or line.kind ~= "item" or not line.link then return nil end
    local facts = Facts(line.link)
    local places = facts and PLACES[facts.where]
    if not places or not Wearable(line, facts) then return nil end
    local weakest
    for _, name in ipairs(places) do
        local place = Place(name)
        if not place then return nil end
        if OFF_HAND[name] then
            local held = Facts(Core.Ask(GetInventoryItemLink, "player", Place("INVSLOT_MAINHAND")))
            if held and TWO_HANDS[held.where] then return nil end -- both hands hold one weapon
        end
        local worn = Facts(Core.Ask(GetInventoryItemLink, "player", place))
        if not worn then return "empty" end
        if not weakest or worn.level < weakest.level then weakest = worn end
    end
    local mine, theirs = Weight(facts), Weight(weakest)
    if mine and theirs and mine < theirs then return nil end -- lighter armour than worn
    if facts.level > weakest.level then return "better" end
    return nil
end
