local _, ns = ...
local D = ns.Data

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Weapon skills
--  The weapon skills a class can learn from a weapon master, as the spell that
--  teaches each one. They are no class spells: the class trainer does not have
--  them, and the spellbook shows them in its General tab.
-------------------------------------------------------------------------------
local AXES, AXES_2H, MACES, MACES_2H, POLEARMS, SWORDS, SWORDS_2H = 196, 197, 198, 199, 200, 201, 202
local STAVES, BOWS, GUNS, DAGGERS, THROWN, CROSSBOWS, FIST = 227, 264, 266, 1180, 2567, 5011, 15590

local BY_CLASS = {
    WARRIOR = { AXES, AXES_2H, MACES, MACES_2H, POLEARMS, SWORDS, SWORDS_2H, STAVES, BOWS, GUNS, DAGGERS, THROWN, CROSSBOWS, FIST },
    PALADIN = { AXES, AXES_2H, MACES, MACES_2H, POLEARMS, SWORDS, SWORDS_2H },
    HUNTER = { AXES, AXES_2H, POLEARMS, SWORDS, SWORDS_2H, STAVES, BOWS, GUNS, DAGGERS, THROWN, CROSSBOWS, FIST },
    ROGUE = { AXES, MACES, SWORDS, BOWS, GUNS, DAGGERS, THROWN, CROSSBOWS, FIST },
    PRIEST = { MACES, STAVES, DAGGERS },
    SHAMAN = { AXES, AXES_2H, MACES, MACES_2H, STAVES, DAGGERS, FIST },
    DRUID = { MACES, MACES_2H, POLEARMS, STAVES, DAGGERS, FIST },
    MAGE = { SWORDS, STAVES, DAGGERS },
    WARLOCK = { SWORDS, STAVES, DAGGERS },
}

-- { id = spell, level = , cost = copper }: a weapon master asks 10 silver; polearms come at level 20 for 1 gold.
-- Your class is known at login (Trainer.lua, D.Fill).
D.AtLogin(function()
    D.WeaponSkills = {}
    for _, id in ipairs(BY_CLASS[D.class] or {}) do
        local polearms = id == POLEARMS
        table.insert(D.WeaponSkills, { id = id, level = polearms and 20 or 1, cost = polearms and 10000 or 1000 })
    end
end)
