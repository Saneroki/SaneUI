local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - GroupBuffs
--  Which of your own buffs a member of your party or raid is missing: the
--  buffs of your class that you know (Buffs.CLASSES). Each entry is a family:
--  any of its names on the unit is enough, whoever cast it, so a Prayer of
--  Fortitude counts for a Power Word: Fortitude, and another priest's does too.
--  A paladin's blessing is different: each paladin has one of its own on a unit
--  (own: only yours counts), and a shout reaches your own party only (party).
--
--  Spells are looked for by name, which is every rank's (English clients only).
--  The game's name lookup finds a spell of your own, so one you do not know
--  (yet) finds nothing and that family is not yours. In a fight the game hides
--  auras from addons: nothing is read then, the icons stay as they were, and
--  everyone is read again when it ends (Group.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Buffs = {}
ns.GroupBuffs = Buffs

Buffs.MOST = 3 -- icons on a frame at most
local BLESSINGS = { own = true,
    "Blessing of Kings", "Blessing of Wisdom", "Blessing of Might", "Blessing of Salvation", "Blessing of Light",
    "Blessing of Sanctuary", "Greater Blessing of Kings", "Greater Blessing of Wisdom", "Greater Blessing of Might",
    "Greater Blessing of Salvation", "Greater Blessing of Light", "Greater Blessing of Sanctuary" }
Buffs.CLASSES = {
    PRIEST = { { "Power Word: Fortitude", "Prayer of Fortitude" }, { "Divine Spirit", "Prayer of Spirit" },
               { "Shadow Protection", "Prayer of Shadow Protection" } },
    MAGE = { { "Arcane Intellect", "Arcane Brilliance" } },
    DRUID = { { "Mark of the Wild", "Gift of the Wild" } },
    PALADIN = { BLESSINGS },
    WARRIOR = { { "Battle Shout", party = true } },
    EVOKER = { { "Blessing of the Bronze" } },
    SHAMAN = { { "Skyfury" } },
}
-- For a preview of someone whose class has none.
Buffs.SAMPLES = { "Interface\\Icons\\Spell_Holy_WordFortitude", "Interface\\Icons\\Spell_Holy_MagicalSentry",
                  "Interface\\Icons\\Spell_Nature_Regeneration" }

local known = {} -- the families you know, each with its icon: { family = ..., icon = ... }

-- Your own spell of that name, or nil.
local function Own(name)
    local spells = rawget(_G, "C_Spell")
    local info = spells and Core.Ask(spells.GetSpellInfo, name)
    return type(info) == "table" and info or nil
end

-- The families you know now (at the login, and when your spells change).
function Buffs.Learn()
    wipe(known)
    local _, class = Core.Ask(UnitClass, "player")
    for _, family in ipairs(Buffs.CLASSES[class] or {}) do
        for _, name in ipairs(family) do
            local spell = Own(name)
            if spell then
                known[#known + 1] = { family = family, icon = spell.iconID or spell.originalIconID }
                break
            end
        end
    end
end

-- Whether you have any buff of your own to give.
function Buffs.Any()
    return known[1] ~= nil
end

local function Has(unit, family)
    local read = C_UnitAuras.GetAuraDataBySpellName
    local filter = family.own and "HELPFUL|PLAYER" or "HELPFUL"
    for _, name in ipairs(family) do
        if type(Core.Ask(read, unit, name, filter)) == "table" then return true end
    end
    return false
end

-- The icons of your buffs the unit is missing, into list (emptied first); how many, Buffs.MOST at most. nil while the
-- game hides auras: the list is as it was.
function Buffs.Missing(unit, list)
    if Core.Restricted() then return nil end
    wipe(list)
    if Core.Ask(UnitIsDeadOrGhost, unit) or Core.Ask(UnitIsConnected, unit) == false then return 0 end
    for _, entry in ipairs(known) do
        local family = entry.family
        local reached = not family.party or Core.Ask(UnitInParty, unit)
        if reached and #list < Buffs.MOST and not Has(unit, family) then list[#list + 1] = entry.icon end
    end
    return #list
end

-- Your known icons for a preview, the samples where you know none.
function Buffs.Icons()
    local icons = {}
    for _, entry in ipairs(known) do icons[#icons + 1] = entry.icon end
    return icons[1] and icons or Buffs.SAMPLES
end
