local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Upgrade
--  Whether an item would make the character better (Saneroki, 2026-10-29: a
--  green arrow on it, and Loot's switch Always show upgrades; 2026-10-30: the
--  arrow on the items in the bags too, Speed Leveling's rewards): gear the
--  character can wear now, by the game's own word (C_PlayerInfo.CanUseItem)
--  and its level, and in its place either nothing is worn, or what is worn is
--  worth less (of two places of a kind, rings and trinkets, the weaker one).
--  Worth: its stats by the character's weights (Core.WeighWith: Inventory's, by
--  class and specialization; a two-handed weapon against both hands), else
--  its item level. Never armour of a lighter kind than the one worn there
--  (cloth over mail), nor an off hand while a two-handed weapon is held.
--  Shirts, tabards and bags are no gear here.
--
--      Core.Upgrade(link, id)   "empty" (nothing worn there) or "better", what it brings (its worth or what it gains
--                               on what is worn) and the place it goes (of two the empty or the weaker one); nil: no
--                               upgrade. id: the item's, read from the link without it
--      Core.WeighWith(fn)       fn() gives the character's weights: { [the game's stat key] = worth, ranged = worth
--                               of a ranged weapon's damage per second }, nil for none
-------------------------------------------------------------------------------
local Plain = Core.Plain

local ARMOR = 4                                 -- the game's item class of armour (Enum.ItemClass)
local CLOTH, PLATE = 1, 4                       -- its kinds by weight, cloth to plate (Enum.ItemArmorSubclass)
local TWO_HANDS = { INVTYPE_2HWEAPON = true }
local RANGED = { INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_THROWN = true }
local DPS = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT"

-- Where each kind of gear is worn: the game's places (INVSLOT_*); "ranged" is Forever's ranged place (the game's
-- RangedSlot: bows, guns, wands, thrown weapons, relics), Retail's main hand, where its ranged weapons are held.
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

local ranged -- the ranged place's number (asked once), false where the game does not say it
local function Place(name)
    if name == "ranged" then
        if ranged == nil then
            local doll = rawget(_G, "C_PaperDollInfo")
            local slot = Core.Ask(doll and doll.GetInventorySlotInfo or rawget(_G, "GetInventorySlotInfo"), "RangedSlot")
            ranged = Core.ForGame({ forever = type(slot) == "number" and slot or rawget(_G, "INVSLOT_RANGED"),
                                    retail = rawget(_G, "INVSLOT_MAINHAND") }) or false
        end
        return ranged or nil
    end
    return rawget(_G, name)
end

local weigh         -- what gives the character's weights
local weights       -- those the scores were made with
local scores = {}   -- [link] = its stats by them

function Core.WeighWith(fn) weigh = fn end

-- An item's stats by the character's weights; nil with no weights, or while the game does not say.
local function Score(link, where)
    local now = weigh and Core.Ask(weigh) or nil
    if now ~= weights then weights, scores = now, {} end
    if not now then return nil end
    if scores[link] then return scores[link] end
    local get = rawget(_G, "C_Item") and C_Item.GetItemStats or rawget(_G, "GetItemStats")
    local stats = Core.Ask(get, link)
    if type(stats) ~= "table" then return nil end
    local score = 0
    for stat, amount in pairs(stats) do
        local worth = now[stat]
        if stat == DPS and RANGED[where] then worth = now.ranged end
        if worth and type(amount) == "number" then score = score + worth * amount end
    end
    scores[link] = score
    return score
end

-- What the game says of an item: where it is worn, its item level, the level it asks, its class and kind, its score.
local function Facts(item)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    if type(info) ~= "function" or not item then return nil end
    local ok, name, _, _, level, needs, _, _, _, where, _, _, class, kind = pcall(info, item)
    if not ok or not name then return nil end
    local detailed = rawget(_G, "C_Item") and C_Item.GetDetailedItemLevelInfo
    local scaled = detailed and Plain(Core.Ask(detailed, item))
    return { where = Plain(where), level = type(scaled) == "number" and scaled > 0 and scaled or Plain(level) or 0,
             needs = Plain(needs) or 0, class = Plain(class), kind = Plain(kind), score = Score(item, Plain(where)) }
end

-- What one is worth: its score, else its item level.
local function Value(facts)
    return facts.score and facts.score > 0 and facts.score or facts.level
end

-- Whether the character can wear it now: the game's word on the item, and the level it asks.
local function Wearable(id, facts)
    local player = rawget(_G, "C_PlayerInfo")
    if id and player and player.CanUseItem and Core.Ask(player.CanUseItem, id) == false then return false end
    local level = Plain(Core.Ask(UnitLevel, "player"))
    return not (type(level) == "number" and facts.needs > level)
end

local function Weight(facts)
    if facts and facts.class == ARMOR and type(facts.kind) == "number" and facts.kind >= CLOTH and facts.kind <= PLATE then
        return facts.kind
    end
    return nil
end

function Core.Upgrade(link, id)
    if type(link) ~= "string" then return nil end
    local facts = Facts(link)
    local places = facts and PLACES[facts.where]
    if not places or not Wearable(id or tonumber(link:match("item:(%d+)")), facts) then return nil end
    local weakest, at
    for _, name in ipairs(places) do
        local place = Place(name)
        if not place then return nil end
        if OFF_HAND[name] then
            local held = Facts(Core.Ask(GetInventoryItemLink, "player", Place("INVSLOT_MAINHAND")))
            if held and TWO_HANDS[held.where] then return nil end -- both hands hold one weapon
        end
        local worn = Facts(Core.Ask(GetInventoryItemLink, "player", place))
        if not worn then return "empty", Value(facts), place end
        if not weakest or Value(worn) < Value(weakest) then weakest, at = worn, place end
    end
    local mine, theirs = Weight(facts), Weight(weakest)
    if mine and theirs and mine < theirs then return nil end -- lighter armour than worn
    local ours, held = facts.score, weakest.score
    if ours and held and (ours > 0 or held > 0) then
        if TWO_HANDS[facts.where] then
            local off = Facts(Core.Ask(GetInventoryItemLink, "player", Place("INVSLOT_OFFHAND")))
            held = held + (off and off.score or 0)
        end
        if ours > held then return "better", ours - held, at end
        return nil
    end
    if facts.level > weakest.level then return "better", facts.level - weakest.level, at end
    return nil
end
