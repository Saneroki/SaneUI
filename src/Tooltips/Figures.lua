local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Figures
--  Which 3D model a tooltip's thing has, to stand in its picture's place
--  (Panel.lua, the option models). A unit's is its own (Kinds/Unit.lua: its
--  portrait); here are a thing's:
--
--      a mount         the item that teaches it, the spell that summons it:
--                      the mount's model (the game's mount collection)
--      a pet           the item that teaches it: the pet's model (the pet
--                      collection)
--      a piece of gear what can be worn and seen on a character: your own
--                      character wearing it, as the game's dressing room
--                      shows it; a helm close to the face, a cloak from behind
--
--  Everything else keeps its icon. What a thing has is asked of the game once
--  for each thing and kept: a tooltip is read several times a second.
--
--  The model is told in the panel's head (Model.lua): model (the unit's GUID,
--  the creature's display, the item's link: the model changes when it does),
--  modelKind ("display", "dress"), modelZoom (1: the face; 0: the whole of it)
--  and modelTurn (radians).
-------------------------------------------------------------------------------
local Plain, Ask = SaneUI.Core.Plain, SaneUI.Core.Ask
local Figures = {}
ns.Figures = Figures

-- Gear the dressing room puts on a character, by where it is worn (GetItemInfoInstant's equip
-- location): how near the camera comes and how the character is turned. Where the game cannot say
-- whether an item can be tried on (C_Item.IsDressableItemByID), these are the ones that can.
local WORN = {
    INVTYPE_HEAD = { zoom = 0.9 }, INVTYPE_SHOULDER = { zoom = 0.6 }, INVTYPE_CLOAK = { turn = math.pi },
    INVTYPE_CHEST = {}, INVTYPE_ROBE = {}, INVTYPE_BODY = {}, INVTYPE_TABARD = {}, INVTYPE_WRIST = {},
    INVTYPE_HAND = {}, INVTYPE_WAIST = {}, INVTYPE_LEGS = {}, INVTYPE_FEET = {},
    INVTYPE_WEAPON = {}, INVTYPE_2HWEAPON = {}, INVTYPE_WEAPONMAINHAND = {}, INVTYPE_WEAPONOFFHAND = {},
    INVTYPE_SHIELD = {}, INVTYPE_HOLDABLE = {}, INVTYPE_RANGED = {}, INVTYPE_RANGEDRIGHT = {}, INVTYPE_THROWN = {},
}
local PLAIN = {} -- worn where the list above does not say how: the whole character, from the front
local CREATURE_TURN = -0.5 -- a mount or a pet, a little from the side
local NONE = false

-- What each thing has, as asked once: [item] or [spell] = { kind, display, zoom, turn } or NONE
local items, spells = {}, {}

-- A mount's model: its display (GetMountInfoExtraByID), or the first of its displays where it has
-- several (GetMountAllCreatureDisplayInfoByID).
local function MountDisplay(mount)
    local journal = rawget(_G, "C_MountJournal")
    if not (journal and mount) then return nil end
    local display = Ask(journal.GetMountInfoExtraByID, mount)
    if type(display) == "number" and display > 0 then return display end
    local all = Ask(journal.GetMountAllCreatureDisplayInfoByID, mount)
    local first = type(all) == "table" and Plain(all[1])
    display = type(first) == "table" and Plain(first.creatureDisplayID)
    return type(display) == "number" and display > 0 and display or nil
end

-- A pet's model: the twelfth answer of GetPetInfoByItemID, the pet's display.
local function PetDisplay(id)
    local pets = rawget(_G, "C_PetJournal")
    if not (pets and pets.GetPetInfoByItemID) then return nil end
    local answers = { pcall(pets.GetPetInfoByItemID, id) } -- (once for each item)
    local display = answers[1] and Plain(answers[13])
    return type(display) == "number" and display > 0 and display or nil
end

-- A creature's model for a thing: { "display", its display, zoom, turn }
local function Creature(display)
    return { "display", display, 0, CREATURE_TURN }
end

local function Item(id)
    local journal = rawget(_G, "C_MountJournal")
    local display = journal and MountDisplay(Ask(journal.GetMountFromItem, id)) or PetDisplay(id)
    if display then return Creature(display) end
    if not C_Item.GetItemInfoInstant then return NONE end
    local _, _, _, where = C_Item.GetItemInfoInstant(id)
    where = Plain(where)
    if type(where) ~= "string" then return nil end -- not known yet: asked again
    local dressable = C_Item.IsDressableItemByID
    local worn = WORN[where]
    if dressable then
        if Ask(dressable, id) ~= true then return NONE end
        worn = worn or PLAIN
    elseif not worn then
        return NONE
    end
    return { "dress", nil, worn.zoom or 0, worn.turn or 0 }
end

-- Fills in the head the model of an item: a mount's or a pet's, or for gear your character wearing it
-- (its link from the tooltip, or else the item itself).
function Figures.Item(head, id, tooltip)
    if not id then return end
    local known = items[id]
    if known == nil then
        known = Item(id)
        if known == nil then return end
        items[id] = known
    end
    if not known then return end
    local model = known[2]
    if known[1] == "dress" then
        local _, link = Ask(tooltip.GetItem, tooltip)
        model = type(link) == "string" and link ~= "" and link or ("item:%d"):format(id)
    end
    head.model, head.modelKind, head.modelZoom, head.modelTurn = model, known[1], known[3], known[4]
end

-- Fills in the head the model of a spell that summons a mount.
function Figures.Spell(head, id)
    if not id then return end
    local known = spells[id]
    if known == nil then
        local journal = rawget(_G, "C_MountJournal")
        local display = journal and MountDisplay(Ask(journal.GetMountFromSpell, id))
        known = display and Creature(display) or NONE
        spells[id] = known
    end
    if not known then return end
    head.model, head.modelKind, head.modelZoom, head.modelTurn = known[2], known[1], known[3], known[4]
end
