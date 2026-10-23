local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Categories
--  The categories the bag window sorts its items into, without a frame: the
--  built-in ones (their rules fixed here), the player's own, the groups of
--  categories, and what the player chose for single items.
--
--  The built-in categories, in their first order (Categories.LIST):
--      Pinned, Recent       at the very top, never moved: a second look at
--                           items that stay in their own category too
--      the gear by its slot (Head, Neck, Shoulder, Back, Chest, Wrist,
--                           Hands, Waist, Legs, Feet, Rings, Trinkets,
--                           Weapons, Off Hand, Ranged), then Shirts, Tabards
--                           & Other Gear (the gear no slot takes)
--      Item Set Gear        weapons and armor of one of the character's
--                           equipment sets
--      Potions              the consumables the game calls potions
--      Buffs                what lasts a while: elixirs, flasks, scrolls,
--                           gems and enchantments, and any other consumable
--                           whose effect lasts Categories.LASTING or longer
--                           (Core's data: the item's use spell, its aura)
--      Camp Items           the game's camp items, by item ID
--      Food                 the other consumables (food and drink, bandages)
--      Trade Goods          trade goods and reagents
--      Professions          recipes and profession items
--      Reagent Bag          whatever is in the reagent bag
--      Containers           bags and quivers lying in the bags (the game's
--                           classes Container and Quiver: always empty there)
--                           and what a right click opens (a lockbox, a
--                           satchel: the game's hasLoot) (Saneroki, 2026-10-23)
--      Miscellaneous        what no other category takes
--      Quest Items          off at first (they are in Miscellaneous then)
--      Special Bags         what is in a bag for one kind of item that is
--                           worn (a quiver, a soul or herb bag: the game's bag
--                           family)
--      Junk                 the last: grey items not filed elsewhere, and
--                           what the player marked as junk; only while the
--                           junk marker is on (Categories.Marker)
--  An item goes to the first that takes it: the reagent bag's, a special
--  bag's, the category the player put it into, Camp Items, Quest Items, Junk
--  (grey), Containers (what opens), Item Set Gear, then by its slot or its kind of consumable (the
--  categories that ask more than the class), then by its class, each in the
--  categories' order, else Miscellaneous. A category switched off sends its items to Miscellaneous.
--
--  The player may move a category up or down (Categories.Move: past a
--  whole group, a group's member among its members; MoveGroup: a group as
--  one) or drag it to another place in the sidebar (Categories.Place, a
--  group's members together: PlaceGroup), rename it (no name: its own again), switch it off, hide it from All Items, put categories together
--  under a group (a group's items show as one part in All Items, the group
--  named by its members, "A & B", until the player names it; a group left
--  with one member is no more), make categories of their own (a name and an
--  icon; they hold only what is put into them) and delete them. At first
--  the gear's categories and Item Set Gear are the group The Armory, Potions,
--  Buffs, Camp Items and Food the group Consumables.
--
--  An item is pinned by its item ID, put into a category (assigned), or
--  marked as junk (put into Junk; unmarked, it goes back where it was).
--  What the player chose is kept in store.bags (the window's: Categories.Use),
--  account-wide, never trusted as it comes (Categories.Check):
--      assigned  { [item] = key }      an item put into a category
--      before    { [item] = key }      where a junk-marked item was before
--      pinned    { [item] = true }
--      own       { { key, word, icon }, ... }   the player's own categories
--      order     { key, ... }          the movable categories in the
--                                      player's order (nil: the first order)
--      words     { [key] = word }      a category renamed
--      member    { [key] = group }     a category's group (false: none)
--      groups    { [group] = { word } } a group's own name (none: its
--                                      members')
--      off       { [key] = true }      switched off (nil: Quest Items off)
--      hidden    { [key or group] = true }   not in All Items
--      whole     { [group] = true }  a group shown as one part in All Items,
--                                      not divided into its members
--      folded    { [group] = true }  a group's members not listed in the
--                                      sidebar
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Categories = {}
ns.Categories = Categories

local CLASS = Enum and Enum.ItemClass or {}
local SUB = Enum and Enum.ItemConsumableSubclass or {}
local ICONS = "Interface\\Icons\\"

Categories.PINNED, Categories.RECENT, Categories.JUNK = "pinned", "recent", "junk"
Categories.CATCH_ALL = "misc"
Categories.LETTERS = 30   -- the most a name may have
Categories.OWN_ICON = ICONS .. "INV_Misc_QuestionMark"
-- Sane UI's own pencil drawings of the sidebars' rows (dev/tools/category-art): a built-in category, view or group
-- by its key, "add" (Add Category) and "own" (a category of the player's own that has no icon of its own).
Categories.ART = "Interface\\AddOns\\SaneUI_Inventory\\Art\\Categories\\"
-- The icons a category of the player's own may take (the dialog's choice).
Categories.ICONS = {
    "INV_Misc_QuestionMark", "INV_Misc_Bag_10", "INV_Misc_Gem_01", "INV_Potion_54", "INV_Misc_Herb_19",
    "INV_Ore_Copper_01", "INV_Fabric_Linen_01", "INV_Enchant_DustArcane", "INV_Misc_Key_03", "INV_Misc_Toy_10",
    "INV_Misc_Ticket_Tarot_Stack_01", "INV_Misc_Bone_HumanSkull_01", "INV_Banner_02", "Trade_Engineering",
}
for index, name in ipairs(Categories.ICONS) do Categories.ICONS[index] = ICONS .. name end

-- The game's camp items (by item ID).
Categories.CAMP = {}
for _, item in ipairs({
    279938, 279940, 279941, 279943, 279944, 279945, 279947, 279948, 279949, 279950, 279951, 279952, 279955, 279956,
    279957, 279959, 279960, 279961, 279962, 279964, 279965, 279966, 279967, 279968, 279969, 279970, 279973, 279974,
    279976, 279978, 279979, 279981, 279982, 279985, 279987, 279988, 279989, 279990,
}) do Categories.CAMP[item] = true end

Categories.LASTING = 15 * 60 * 1000   -- a consumable whose aura lasts this long (ms) is a buff

local function Set(...)
    local set = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if value ~= nil then set[value] = true end
    end
    return set
end

-- The built-in categories in their first order. fixed: at the top, never moved or grouped; last: after every
-- other; alone: never in a group; take: what puts an item there besides its class (Categories.Classify).
Categories.LIST = {
    { key = "pinned", word = ns.TEXT.bagsPinned,
      fixed = true, alone = true, view = true },
    { key = "recent", word = ns.TEXT.bagsRecent,
      fixed = true, alone = true, view = true },
    -- the gear by its slot (the game's words for the slots), the gear no slot takes, the sets' gear
    { key = "head", word = Core.Word("INVTYPE_HEAD", "Head"), group = "armory",
      equip = Set("INVTYPE_HEAD") },
    { key = "neck", word = Core.Word("INVTYPE_NECK", "Neck"), group = "armory",
      equip = Set("INVTYPE_NECK") },
    { key = "shoulder", word = Core.Word("INVTYPE_SHOULDER", "Shoulder"), group = "armory",
      equip = Set("INVTYPE_SHOULDER") },
    { key = "back", word = Core.Word("INVTYPE_CLOAK", "Back"), group = "armory",
      equip = Set("INVTYPE_CLOAK") },
    { key = "chest", word = Core.Word("INVTYPE_CHEST", "Chest"), group = "armory",
      equip = Set("INVTYPE_CHEST", "INVTYPE_ROBE") },
    { key = "wrist", word = Core.Word("INVTYPE_WRIST", "Wrist"), group = "armory",
      equip = Set("INVTYPE_WRIST") },
    { key = "hands", word = Core.Word("INVTYPE_HAND", "Hands"), group = "armory",
      equip = Set("INVTYPE_HAND") },
    { key = "waist", word = Core.Word("INVTYPE_WAIST", "Waist"), group = "armory",
      equip = Set("INVTYPE_WAIST") },
    { key = "legs", word = Core.Word("INVTYPE_LEGS", "Legs"), group = "armory",
      equip = Set("INVTYPE_LEGS") },
    { key = "feet", word = Core.Word("INVTYPE_FEET", "Feet"), group = "armory",
      equip = Set("INVTYPE_FEET") },
    { key = "finger", word = ns.TEXT.bagsRings, group = "armory",
      equip = Set("INVTYPE_FINGER") },
    { key = "trinket", word = ns.TEXT.bagsTrinkets, group = "armory",
      equip = Set("INVTYPE_TRINKET") },
    { key = "weapons", word = ns.TEXT.bagsWeapons, group = "armory",
      equip = Set("INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND") },
    { key = "offhand", word = Core.Word("INVTYPE_WEAPONOFFHAND", "Off Hand"),
      group = "armory", equip = Set("INVTYPE_SHIELD", "INVTYPE_HOLDABLE", "INVTYPE_WEAPONOFFHAND") },
    { key = "ranged", word = Core.Word("INVTYPE_RANGED", "Ranged"), group = "armory",
      equip = Set("INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT", "INVTYPE_THROWN", "INVTYPE_RELIC") },
    { key = "armor", word = ns.TEXT.bagsOtherGear, group = "armory",
      classes = Set(CLASS.Weapon or 2, CLASS.Armor or 4) },
    { key = "sets", word = ns.TEXT.bagsSets, group = "armory", take = "set" },
    -- the consumables by their kind (the game's subclasses, Enum.ItemConsumableSubclass), the rest by their class
    { key = "potions", word = ns.TEXT.bagsPotions, group = "prep",
      classes = Set(CLASS.Consumable or 0), subclasses = Set(SUB.Potion or 1) },
    { key = "enhance", word = ns.TEXT.bagsBuffs, group = "prep",
      classes = Set(CLASS.Consumable or 0, CLASS.Gem or 3, CLASS.ItemEnhancement or 8),
      subclasses = Set(SUB.Elixir or 2, SUB.Flasksphials or 3, SUB.Scroll or 4, SUB.Itemenhancement or 6,
          SUB.ItemenhancementTemporary or 15),
      whole = Set(CLASS.Gem or 3, CLASS.ItemEnhancement or 8), lasting = true },
    { key = "camp", word = ns.TEXT.bagsCamp, group = "prep", take = "camp" },
    { key = "consumables", word = ns.TEXT.bagsFood,
      group = "prep", classes = Set(CLASS.Consumable or 0) },
    { key = "trade", word = Core.Word("AUCTION_CATEGORY_TRADE_GOODS", "Trade Goods"),
      classes = Set(CLASS.Tradegoods or 7, CLASS.Reagent or 5) },
    { key = "professions", word = Core.Word("TRADE_SKILLS", "Professions"),
      classes = Set(CLASS.Recipe or 9, CLASS.Profession) },
    { key = "containers", word = Core.Word("AUCTION_CATEGORY_CONTAINERS", "Containers"),
      classes = Set(CLASS.Container or 1, CLASS.Quiver or 11), take = "loot" },
    { key = "reagent", word = ns.TEXT.bagsReagentBag, alone = true, take = "reagent",
      unassignable = true },
    { key = "misc", word = Core.Word("AUCTION_CATEGORY_MISCELLANEOUS", "Miscellaneous"),
      catchAll = true },
    { key = "quest", word = Core.Word("AUCTION_CATEGORY_QUEST_ITEMS", "Quest Items"), take = "quest" },
    { key = "special", word = ns.TEXT.bagsSpecial, alone = true,
      take = "special", unassignable = true, late = true },
    { key = "junk", word = Core.Word("BAG_FILTER_JUNK", "Junk"), alone = true,
      last = true },
}
Categories.DEF = {}
for _, def in ipairs(Categories.LIST) do Categories.DEF[def.key] = def end
-- The groups at first, and their names.
Categories.GROUPS = { armory = ns.TEXT.bagsArmory, prep = ns.TEXT.bagsPrep }
Categories.OFF = { quest = true }

local kept = {}
local First        -- the first category whose rules take a record (Classify)
local order = {}   -- the categories now, in order: { key, ... } (Categories.Order)
local rank = {}    -- [key] = its place in order
local groupOf = {} -- [key] = its group now (nil: none)
Categories.order, Categories.rank = order, rank

-------------------------------------------------------------------------------
--  What is kept
-------------------------------------------------------------------------------
local function Table(t, key)
    if type(t[key]) ~= "table" then t[key] = {} end
    return t[key]
end

local function Known(key)
    if type(key) ~= "string" then return false end
    if Categories.DEF[key] then return true end
    for _, own in ipairs(kept.own or {}) do
        if own.key == key then return true end
    end
    return false
end

-- Saved data comes from hand edits and older versions: what is not of the right kind goes.
function Categories.Check(bags)
    local own = Table(bags, "own")
    local seen = {}
    for index = #own, 1, -1 do
        local entry = own[index]
        if type(entry) ~= "table" or type(entry.key) ~= "string" or not entry.key:match("^own%d+$") or seen[entry.key]
            or type(entry.word) ~= "string" or entry.word == "" then
            table.remove(own, index)
        else
            seen[entry.key] = true
            if type(entry.icon) ~= "string" and type(entry.icon) ~= "number" then entry.icon = nil end
        end
    end
    kept.own = own
    for _, name in ipairs({ "assigned", "before" }) do
        local map = Table(bags, name)
        for item, key in pairs(map) do
            if type(item) ~= "number" or not Known(key) or Categories.DEF[key] and Categories.DEF[key].unassignable then map[item] = nil end
        end
    end
    local pinned = Table(bags, "pinned")
    for item, on in pairs(pinned) do
        if type(item) ~= "number" or on ~= true then pinned[item] = nil end
    end
    local words = Table(bags, "words")
    for key, word in pairs(words) do
        if not Known(key) or type(word) ~= "string" or word == "" then words[key] = nil end
    end
    local member = bags.member
    if member ~= nil and type(member) ~= "table" then member = nil end
    if member then
        for key, group in pairs(member) do
            if not Known(key) or (group ~= false and type(group) ~= "string") then member[key] = nil end
        end
    end
    bags.member = member
    local groups = Table(bags, "groups")
    for group, entry in pairs(groups) do
        if type(group) ~= "string" or type(entry) ~= "table" or (entry.word ~= nil and type(entry.word) ~= "string") then
            groups[group] = nil
        end
    end
    if bags.off ~= nil and type(bags.off) ~= "table" then bags.off = nil end
    for key, on in pairs(bags.off or {}) do
        if not Known(key) or type(on) ~= "boolean" then bags.off[key] = nil end
    end
    for _, name in ipairs({ "hidden", "whole", "folded" }) do
        local map = Table(bags, name)
        for key, on in pairs(map) do
            if type(key) ~= "string" or on ~= true then map[key] = nil end
        end
    end
    if type(bags.order) == "table" then
        local orderSeen = {}
        for index = #bags.order, 1, -1 do
            local key = bags.order[index]
            if not Known(key) or orderSeen[key] or Categories.DEF[key] and (Categories.DEF[key].fixed or Categories.DEF[key].last) then
                table.remove(bags.order, index)
            else
                orderSeen[key] = true
            end
        end
    else
        bags.order = nil
    end
    if type(bags.ownNext) ~= "number" then bags.ownNext = 1 end
end

-- The window's store (store.bags), checked; the order built anew.
function Categories.Use(bags)
    kept = bags
    Categories.Check(bags)
    Categories.Order()
end

-------------------------------------------------------------------------------
--  The order
-------------------------------------------------------------------------------
local function Own(key)
    for _, own in ipairs(kept.own or {}) do
        if own.key == key then return own end
    end
end
Categories.Own = function(key) return Own(key) ~= nil end

-- Whether a category is switched off (its items in Miscellaneous).
function Categories.Off(key)
    local off = kept.off
    if off and off[key] ~= nil then return off[key] end
    return Categories.OFF[key] == true
end

-- Whether the junk marker is on (Junk exists, marks count); the module's settings say (marker).
function Categories.Marker()
    local options = ns.options
    return not (type(options) == "table" and options.marker == false)
end

-- A category's group now: the player's choice, else its first one while that group stands.
local function Group(key)
    local member = kept.member
    if member and member[key] ~= nil then return member[key] or nil end
    local def = Categories.DEF[key]
    return def and def.group or nil
end

-- The categories in order, anew: Pinned and Recent first, then the movable ones in the player's order (a
-- category new since then before Miscellaneous, a late one at the end), Junk last while the marker is on. A
-- category switched off is still in the order (to switch it on again), but holds nothing.
function Categories.Order()
    for index = #order, 1, -1 do order[index] = nil end
    for key in pairs(rank) do rank[key] = nil end
    for key in pairs(groupOf) do groupOf[key] = nil end
    local movable, seen = {}, {}
    -- Only a list is the player's order (anything else in the store is not read).
    local list = type(kept.order) == "table" and kept.order or nil
    for _, key in ipairs(list or {}) do
        if Known(key) and not seen[key] then
            movable[#movable + 1] = key
            seen[key] = true
        end
    end
    local function Before(key, catchAll)
        for index, other in ipairs(movable) do
            if other == catchAll then
                table.insert(movable, index, key)
                return
            end
        end
        movable[#movable + 1] = key
    end
    for _, def in ipairs(Categories.LIST) do
        if not (def.fixed or def.last or seen[def.key]) then
            if not list or def.late then movable[#movable + 1] = def.key else Before(def.key, Categories.CATCH_ALL) end
            seen[def.key] = true
        end
    end
    for _, own in ipairs(kept.own or {}) do
        if not seen[own.key] then
            Before(own.key, Categories.CATCH_ALL)
            seen[own.key] = true
        end
    end
    for _, def in ipairs(Categories.LIST) do
        if def.fixed then order[#order + 1] = def.key end
    end
    for _, key in ipairs(movable) do order[#order + 1] = key end
    if Categories.Marker() then order[#order + 1] = Categories.JUNK end
    for index, key in ipairs(order) do
        rank[key] = index
        local def = Categories.DEF[key]
        if not (def and def.alone) then groupOf[key] = Group(key) end
    end
    -- A group of one is no group.
    local members = {}
    for _, key in ipairs(order) do
        local group = groupOf[key]
        if group then members[group] = (members[group] or 0) + 1 end
    end
    for key, group in pairs(groupOf) do
        if members[group] < 2 then groupOf[key] = nil end
    end
    return order
end

-- A category's group now (nil: none), a group's members in order.
function Categories.GroupOf(key)
    return groupOf[key]
end

function Categories.Members(group)
    local list = {}
    for _, key in ipairs(order) do
        if groupOf[key] == group then list[#list + 1] = key end
    end
    return list
end

-- A category's name and icon (an icon: a texture, or an atlas first and the texture where the game lacks it).
function Categories.Word(key)
    local words = kept.words
    if words and words[key] then return words[key] end
    local def = Categories.DEF[key]
    if def then return def.word end
    local own = Own(key)
    return own and own.word or tostring(key)
end

function Categories.Icon(key)
    if Categories.DEF[key] then return Categories.ART .. key end
    local own = Own(key)
    if own and own.icon and own.icon ~= Categories.OWN_ICON then return own.icon end
    return Categories.ART .. "own"
end

-- A group's icon: a built-in group's own drawing, else its first member's.
function Categories.GroupIcon(group)
    if Categories.GROUPS[group] then return Categories.ART .. group end
    local first = Categories.Members(group)[1]
    return first and Categories.Icon(first) or Categories.ART .. "own"
end

-- Whether an icon is one of Sane UI's own drawings (drawn whole), not one of the game's (cut a little round its edge).
function Categories.Drawn(file)
    return type(file) == "string" and file:sub(1, #Categories.ART) == Categories.ART
end

-- A group's name: the player's, else its own first name, else its members' ("A & B", "A, B, & C").
function Categories.GroupWord(group)
    local entry = kept.groups and kept.groups[group]
    if entry and entry.word then return entry.word end
    if Categories.GROUPS[group] then return Categories.GROUPS[group] end
    local words = {}
    for _, key in ipairs(Categories.Members(group)) do words[#words + 1] = Categories.Word(key) end
    if #words <= 2 then return table.concat(words, " & ") end
    return table.concat(words, ", ", 1, #words - 1) .. ", & " .. words[#words]
end

-------------------------------------------------------------------------------
--  Sorting an item in
-------------------------------------------------------------------------------
-- Whether a consumable's use lasts a while: the aura of its use spell lasts Categories.LASTING or longer (Core's
-- data: Items' effects, Auras' durations; unknown: no).
local items, auras
local function Lasting(item)
    local data = Core.Data
    if not (data and data.Set and item) then return false end
    items, auras = items or data.Set("Items"), auras or data.Set("Auras")
    if not (items:Ready() and auras:Ready()) then return false end
    local effects = items:Get(item, "effects")
    for _, effect in ipairs(type(effects) == "table" and effects or {}) do
        local duration = type(effect) == "table" and effect.trigger == "use" and auras:Get(effect.spell, "duration")
        if type(duration) == "number" and duration >= Categories.LASTING then return true end
    end
    return false
end

-- Whether a category's rules take a record: by its slot (equip: gear only), by its class and kind (subclasses;
-- whole: a class taken whole; lasting: a consumable whose use lasts), or by its class alone.
local function Rules(def, record)
    if def.equip then return ns.Contents.GEAR[record.class] and def.equip[record.equip] or false end
    if not (def.classes and def.classes[record.class]) then return false end
    if def.subclasses then
        return def.subclasses[record.subclass] or def.whole and def.whole[record.class]
            or def.lasting and record.class == (CLASS.Consumable or 0) and Lasting(record.item) or false
    end
    return true
end

-- The first category in order whose rules take a record: of those that ask more than the class (a slot, a kind:
-- specific) or of those that do not.
First = function(record, specific)
    for _, key in ipairs(order) do
        local def = Categories.DEF[key]
        if def and (def.equip or def.classes) and ((def.equip or def.subclasses) and true or false) == specific
            and Rules(def, record) then
            return key
        end
    end
end

-- Where a record with an item goes now: record.category; whether it is junk (record.junk: in Junk with a price,
-- the marker on, not pinned); whether it is pinned.
function Categories.Classify(record)
    local item = record.item
    local key = (kept.assigned or {})[item]
    record.pinned = (kept.pinned or {})[item] == true
    local marker = Categories.Marker()
    if record.reagentBag then
        key = "reagent"
    elseif record.special then
        key = "special"
    elseif key == Categories.JUNK and not marker then
        key = nil
    end
    if not key then
        if Categories.CAMP[item] then
            key = "camp"
        elseif record.quest or record.questID then
            key = "quest"
        elseif record.quality == ns.Contents.POOR and marker then
            key = Categories.JUNK
        elseif record.loot then
            key = "containers"
        elseif record.set and ns.Contents.GEAR[record.class] then
            key = "sets"
        else
            key = First(record, true) or First(record, false)
        end
    end
    if not key or not rank[key] or Categories.Off(key) then key = Categories.CATCH_ALL end
    record.category = key
    record.junk = key == Categories.JUNK and not record.worthless and not record.pinned
    return key
end

-------------------------------------------------------------------------------
--  The player's choices for items
-------------------------------------------------------------------------------
-- Whether an item may be put into a category (not Pinned, Recent, the reagent bag's, the special bags').
function Categories.Takes(key)
    if not rank[key] then return false end
    local def = Categories.DEF[key]
    return not (def and (def.fixed or def.unassignable))
end

function Categories.Pin(item, on)
    kept.pinned = kept.pinned or {}
    kept.pinned[item] = on and true or nil
end

function Categories.Pinned(item)
    return (kept.pinned or {})[item] == true
end

-- An item put into a category (nil: back to where the rules put it); Junk remembers where it was.
function Categories.Assign(item, key)
    kept.assigned, kept.before = kept.assigned or {}, kept.before or {}
    if key == Categories.JUNK then
        local was = kept.assigned[item]
        if was ~= Categories.JUNK then kept.before[item] = was end
    else
        kept.before[item] = nil
    end
    kept.assigned[item] = key
end

function Categories.Assigned(item)
    return (kept.assigned or {})[item]
end

-- Marked as junk, or unmarked: back into the category it was put into before, else where the rules put it; a
-- grey item (quality) unmarked is kept out of Junk by putting it into Miscellaneous.
function Categories.MarkJunk(item, on, quality)
    if on then return Categories.Assign(item, Categories.JUNK) end
    kept.assigned = kept.assigned or {}
    local was = kept.before and kept.before[item]
    if kept.assigned[item] == Categories.JUNK then kept.assigned[item] = (was and Known(was)) and was or nil end
    if kept.before then kept.before[item] = nil end
    if not kept.assigned[item] and quality == ns.Contents.POOR then kept.assigned[item] = Categories.CATCH_ALL end
end

-- Whether an item with this quality counts as junk now: marked, or grey and not put elsewhere.
function Categories.Junk(item, quality)
    if not Categories.Marker() then return false end
    local key = (kept.assigned or {})[item]
    if key then return key == Categories.JUNK end
    return quality == ns.Contents.POOR
end

-------------------------------------------------------------------------------
--  The player's choices for categories and groups
-------------------------------------------------------------------------------
local function Changed()
    Categories.Order()
end

-- The movable categories as they stand, kept as the player's order.
local function Keep()
    local movable = {}
    for _, key in ipairs(order) do
        local def = Categories.DEF[key]
        if not (def and (def.fixed or def.last)) then movable[#movable + 1] = key end
    end
    kept.order = movable
    return movable
end

-- A category renamed; no name: a built-in one gets its own back, the player's own keeps the one it has.
function Categories.Rename(key, word)
    kept.words = kept.words or {}
    word = type(word) == "string" and word:match("^%s*(.-)%s*$") or ""
    local own = Own(key)
    if own then
        if word ~= "" then own.word = word:sub(1, Categories.LETTERS) end
    else
        kept.words[key] = word ~= "" and word:sub(1, Categories.LETTERS) or nil
    end
end

function Categories.RenameGroup(group, word)
    kept.groups = kept.groups or {}
    word = type(word) == "string" and word:match("^%s*(.-)%s*$") or ""
    kept.groups[group] = kept.groups[group] or {}
    kept.groups[group].word = word ~= "" and word:sub(1, Categories.LETTERS) or nil
end

-- The movable categories as they stand, as units: a group's members together (where its first one stands, as the
-- sidebar shows them), every other category alone; laid back as the player's order.
local function Units()
    local units, of = {}, {}
    for _, key in ipairs(Keep()) do
        local group = groupOf[key]
        local unit = group and of[group]
        if unit then
            unit[#unit + 1] = key
        else
            unit = { key, group = group }
            units[#units + 1] = unit
            if group then of[group] = unit end
        end
    end
    return units
end

local function Lay(units)
    local movable = {}
    for _, unit in ipairs(units) do
        for _, key in ipairs(unit) do movable[#movable + 1] = key end
    end
    kept.order = movable
    Changed()
end

-- Whether a unit (or a group's member, a key) is seen: one of its categories switched on, as the sidebar shows them.
local function Seen(entry)
    if type(entry) == "string" then return not Categories.Off(entry) end
    for _, key in ipairs(entry) do
        if not Categories.Off(key) then return true end
    end
    return false
end

-- Whether list[index] swapped places with the next one a step away that is seen (those switched off are stepped
-- over: every move moves something the player sees).
local function Swap(list, index, step)
    local target = index + step
    while list[target] ~= nil and not Seen(list[target]) do target = target + step end
    if list[target] == nil then return false end
    list[index], list[target] = list[target], list[index]
    return true
end

-- Moved one place up (-1) or down (1): a category in no group past the next category or group (a group counts as
-- one, those switched off do not), a group's member among its members.
function Categories.Move(key, step)
    local units = Units()
    for index, unit in ipairs(units) do
        for place, other in ipairs(unit) do
            if other == key then
                local moved
                if unit.group then moved = Swap(unit, place, step) else moved = Swap(units, index, step) end
                if moved then Lay(units) end
                return
            end
        end
    end
end

-- A group moved one place up or down as one, past the next category or group.
function Categories.MoveGroup(group, step)
    local units = Units()
    for index, unit in ipairs(units) do
        if unit.group == group then
            if Swap(units, index, step) then Lay(units) end
            return
        end
    end
end

function Categories.SwitchOff(key, off)
    kept.off = kept.off or {}
    kept.off[key] = off and true or false
    Changed()
end

function Categories.Hide(key, hidden)
    kept.hidden = kept.hidden or {}
    kept.hidden[key] = hidden and true or nil
end

function Categories.Hidden(key)
    return (kept.hidden or {})[key] == true
end

-- A group divided into its members in All Items (at first), or shown whole, as one part.
function Categories.Divided(group)
    return (kept.whole or {})[group] ~= true
end

function Categories.Divide(group, on)
    kept.whole = kept.whole or {}
    kept.whole[group] = (not on) or nil
end

-- A group's members listed under it in the sidebar (at first), or folded into its row.
function Categories.Folded(group)
    return (kept.folded or {})[group] == true
end

function Categories.Fold(group, on)
    kept.folded = kept.folded or {}
    kept.folded[group] = on and true or nil
end

-- Where the rules put an item, whatever the player chose for it (by the game's instant item info): Camp Items,
-- then by its slot or kind, then by its class, else Miscellaneous.
function Categories.Rule(item)
    if Categories.CAMP[item] then return "camp" end
    local class, subclass, equip = ns.Contents.Instant(item)
    local key = class and (First({ item = item, class = class, subclass = subclass, equip = equip }, true)
        or First({ item = item, class = class, subclass = subclass, equip = equip }, false))
    if not key or not rank[key] or Categories.Off(key) then key = Categories.CATCH_ALL end
    return key
end

-- An item let go over a group: the member the rules put it into, if it is that group's (nil: nothing to put it
-- into, the rules do it); else the group's first member that takes items.
function Categories.Into(group, item)
    local rule = Categories.Rule(item)
    if groupOf[rule] == group then return nil end
    for _, member in ipairs(Categories.Members(group)) do
        if Categories.Takes(member) and not Categories.Off(member) then return member end
    end
end

-- Whether a category may be in a group (not Pinned, Recent, Junk, the bags' own).
function Categories.Groupable(key)
    local def = Categories.DEF[key]
    return rank[key] ~= nil and not (def and def.alone)
end

local function Member(key, group)
    kept.member = kept.member or {}
    kept.member[key] = group or false
end

-- Two categories made a new group; a category put into a group, or taken out of its group; a group undone.
function Categories.GroupWith(key, other)
    kept.ownGroup = (tonumber(kept.ownGroup) or 0) + 1
    local group = "group" .. kept.ownGroup
    Member(key, group)
    Member(other, group)
    -- The two together in the order: the first one's place.
    local movable = Keep()
    local first, second
    for index, value in ipairs(movable) do
        if value == key or value == other then
            if first then second = index else first = index end
        end
    end
    if first and second and second > first + 1 then
        local moved = table.remove(movable, second)
        table.insert(movable, first + 1, moved)
    end
    Changed()
    return group
end

function Categories.Join(key, group)
    Member(key, group)
    local movable = Keep()
    local last, at
    for index, value in ipairs(movable) do
        if groupOf[value] == group then last = index end
        if value == key then at = index end
    end
    if last and at and at ~= last then
        local moved = table.remove(movable, at)
        if at < last then last = last - 1 end
        table.insert(movable, last + 1, moved)
    end
    Changed()
end

function Categories.Ungroup(key)
    Member(key, false)
    Changed()
end

function Categories.Disband(group)
    for _, key in ipairs(Categories.Members(group)) do Member(key, false) end
    if kept.groups then kept.groups[group] = nil end
    Changed()
end

-- Whether a category can be moved (not Pinned, Recent, Junk).
function Categories.Movable(key)
    local def = Categories.DEF[key]
    return rank[key] ~= nil and not (def and (def.fixed or def.last))
end

-- These categories (in their order) taken out of the player's order and put back before or after target (nil, or
-- one that does not move: at the end, before Junk).
local function Put(keys, target, after)
    local movable = Keep()
    local moving = {}
    for _, key in ipairs(keys) do moving[key] = true end
    for index = #movable, 1, -1 do
        if moving[movable[index]] then table.remove(movable, index) end
    end
    local at = #movable + 1
    for index, key in ipairs(movable) do
        if key == target then
            at = after and index + 1 or index
            break
        end
    end
    for offset, key in ipairs(keys) do table.insert(movable, at + offset - 1, key) end
end

-- A category moved before (or after) another (the sidebar's drag), then in group (nil: in none; one that is never
-- in a group stays in none).
function Categories.Place(key, target, after, group)
    if not Categories.Movable(key) or key == target then return end
    Put({ key }, target, after)
    if Categories.Groupable(key) then Member(key, group or false) end
    Changed()
end

-- A group's members moved together before (or after) a category that is not one of them.
function Categories.PlaceGroup(group, target, after)
    local members = Categories.Members(group)
    if #members == 0 then return end
    for _, key in ipairs(members) do
        if key == target then return end
    end
    Put(members, target, after)
    Changed()
end

-- A category of the player's own made (its key), renamed, deleted (its items back where the rules put them).
function Categories.New(word, icon)
    word = type(word) == "string" and word:match("^%s*(.-)%s*$") or ""
    if word == "" then return nil end
    kept.own = kept.own or {}
    local key = "own" .. kept.ownNext
    kept.ownNext = kept.ownNext + 1
    kept.own[#kept.own + 1] = { key = key, word = word:sub(1, Categories.LETTERS), icon = icon }
    Changed()
    return key
end

function Categories.SetIcon(key, icon)
    local own = Own(key)
    if own then own.icon = icon end
end

function Categories.Delete(key)
    local own = kept.own or {}
    for index = #own, 1, -1 do
        if own[index].key == key then table.remove(own, index) end
    end
    for item, value in pairs(kept.assigned or {}) do
        if value == key then kept.assigned[item] = nil end
    end
    for item, value in pairs(kept.before or {}) do
        if value == key then kept.before[item] = nil end
    end
    if kept.member then kept.member[key] = nil end
    if kept.words then kept.words[key] = nil end
    if kept.hidden then kept.hidden[key] = nil end
    if type(kept.order) == "table" then
        for index = #kept.order, 1, -1 do
            if kept.order[index] == key then table.remove(kept.order, index) end
        end
    end
    Changed()
end
