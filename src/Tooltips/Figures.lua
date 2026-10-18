local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Figures
--  Which 3D model a tooltip's thing has (Panel.lua, the option models). A
--  unit's is its own (Kinds/Unit.lua: its portrait); here are a thing's:
--
--      a mount         the item that teaches it, the spell that summons it:
--                      the mount's model (the game's mount collection), in
--                      the picture's place
--      a pet           the item that teaches it: the pet's model (the pet
--                      collection), in the picture's place
--      a piece of gear what can be worn and seen on a character keeps its
--                      icon; with Alt held, your own character wearing it
--                      stands beside the panel, as the game's dressing room
--                      shows it (Panel.lua, Stage)
--
--  Everything else keeps its icon. What a thing has is asked of the game once
--  for each thing and kept: a tooltip is read several times a second.
--
--  The model is told in the panel's head (Model.lua): model (the creature's
--  display: the model changes when it does), modelKind ("display"),
--  modelZoom (0: the whole of it) and modelTurn (radians); for gear, dress
--  (the item's link).
-------------------------------------------------------------------------------
local Plain, Ask = SaneUI.Core.Plain, SaneUI.Core.Ask
local Figures = {}
ns.Figures = Figures

-- Where gear the dressing room puts on a character is worn (GetItemInfoInstant's equip location):
-- where the game cannot say whether an item can be tried on (C_Item.IsDressableItemByID), these
-- are the places of the ones that can.
local WORN = {}
for _, where in ipairs({ "HEAD", "SHOULDER", "CLOAK", "CHEST", "ROBE", "BODY", "TABARD", "WRIST", "HAND", "WAIST",
    "LEGS", "FEET", "WEAPON", "2HWEAPON", "WEAPONMAINHAND", "WEAPONOFFHAND", "SHIELD", "HOLDABLE", "RANGED",
    "RANGEDRIGHT", "THROWN" }) do
    WORN["INVTYPE_" .. where] = true
end
local CREATURE_TURN = -0.5 -- a mount or a pet, a little from the side
local NONE, DRESS = false, "dress"

-- What each thing has, as asked once: [item] or [spell] = { kind, display, zoom, turn }, DRESS (gear,
-- for the character beside the panel) or NONE
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
    if dressable then
        if Ask(dressable, id) ~= true then return NONE end
    elseif not WORN[where] then
        return NONE
    end
    return DRESS
end

-- Fills in the head the model of an item: a mount's or a pet's in the picture's place (pictured: the
-- panel has a picture); for gear, the link your character tries on beside the panel with Alt held (the
-- tooltip's own link, or else the item itself).
function Figures.Item(head, id, tooltip, pictured)
    if not id then return end
    local known = items[id]
    if known == nil then
        known = Item(id)
        if known == nil then return end
        items[id] = known
    end
    if not known then return end
    if known == DRESS then
        local _, link = Ask(tooltip.GetItem, tooltip)
        head.dress = type(link) == "string" and link ~= "" and link or ("item:%d"):format(id)
    elseif pictured then
        head.model, head.modelKind, head.modelZoom, head.modelTurn = known[2], known[1], known[3], known[4]
    end
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
