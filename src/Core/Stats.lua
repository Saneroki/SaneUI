local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Stats
--  The stats as players write them (Saneroki, 2026-10-30): Str, Stam, Crit, in
--  every view of Sane UI. The one place those words are kept; a stat the game
--  words differently one day stays long until it is added here.
--
--      Core.StatWord("Strength")     -> "Str"; a word that is no stat as it came
--      Core.StatLine("+8 Stamina")   -> "+8 Stam", "62 Armor" -> "62 Arm"; only a
--                                       line that is a number and a stat: a
--                                       sentence stays as it is
--
--  The game's own windows keep its words: its strings are not ours to write.
-------------------------------------------------------------------------------

-- Each stat: its short word, then what the game calls it: its strings' names, and the English words where they have
-- none in a client. Block, Dodge, Parry, Hit, Haste, Mana, Leech and Speed are short already.
local LIST = {
    { "Str", "SPELL_STAT1_NAME", "ITEM_MOD_STRENGTH_SHORT", "Strength" },
    { "Agi", "SPELL_STAT2_NAME", "ITEM_MOD_AGILITY_SHORT", "Agility" },
    { "Stam", "SPELL_STAT3_NAME", "ITEM_MOD_STAMINA_SHORT", "Stamina" },
    { "Int", "SPELL_STAT4_NAME", "ITEM_MOD_INTELLECT_SHORT", "Intellect" },
    { "Spi", "SPELL_STAT5_NAME", "ITEM_MOD_SPIRIT_SHORT", "Spirit" },
    { "HP", "HEALTH", "ITEM_MOD_HEALTH_SHORT", "Health" },
    { "Arm", "RESISTANCE0_NAME", "STAT_ARMOR", "Armor" },
    { "Bonus Arm", "ITEM_MOD_EXTRA_ARMOR_SHORT", "STAT_BONUS_ARMOR", "Bonus Armor" },
    { "Def", "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "DEFENSE", "Defense" },
    { "BVal", "ITEM_MOD_BLOCK_VALUE_SHORT", "Block Value" },
    { "Resil", "ITEM_MOD_RESILIENCE_RATING_SHORT", "STAT_RESILIENCE", "Resilience", "PvP Resilience" },
    { "Crit", "ITEM_MOD_CRIT_RATING_SHORT", "STAT_CRITICAL_STRIKE", "MELEE_CRIT_CHANCE", "RANGED_CRIT_CHANCE",
      "SPELL_CRIT_CHANCE", "Critical Strike", "Crit Chance" },
    { "Crit dmg", "Critical Damage", "Crit Damage", "Critical Strike Damage" },
    { "Hit", "STAT_HIT_CHANCE", "Hit Chance" },
    { "AP", "ITEM_MOD_ATTACK_POWER_SHORT", "STAT_ATTACK_POWER", "Attack Power", "Melee Attack Power" },
    { "RAP", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "Ranged Attack Power" },
    { "Feral AP", "ITEM_MOD_FERAL_ATTACK_POWER_SHORT", "Attack Power In Forms" },
    { "ASpd", "STAT_ATTACK_SPEED", "Attack Speed" },
    { "Exp", "ITEM_MOD_EXPERTISE_RATING_SHORT", "STAT_EXPERTISE", "Expertise" },
    { "APen", "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT", "STAT_ARMOR_PENETRATION", "Armor Piercing", "Armor Penetration" },
    { "SP", "ITEM_MOD_SPELL_POWER_SHORT", "STAT_SPELLPOWER", "Spell Power" },
    { "SDmg", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "STAT_SPELLDAMAGE", "Spell Damage", "Bonus Damage" },
    { "Heal", "ITEM_MOD_SPELL_HEALING_DONE_SHORT", "STAT_SPELLHEALING", "Healing", "Bonus Healing" },
    { "SPen", "ITEM_MOD_SPELL_PENETRATION_SHORT", "STAT_SPELL_PENETRATION", "Spell Piercing", "Spell Penetration" },
    { "All Res", "ITEM_MOD_SPELL_RESISTANCE_ALL_SCHOOLS_SHORT", "Spell Resistance" },
    { "MP5", "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_POWER_REGEN0_SHORT", "MANA_REGEN", "Mana Regen", "Mana Per 5 Sec." },
    { "HP5", "ITEM_MOD_HEALTH_REGEN_SHORT", "ITEM_MOD_HEALTH_REGENERATION_SHORT", "Health Regen", "Health Per 5 Sec." },
    { "Mast", "ITEM_MOD_MASTERY_RATING_SHORT", "STAT_MASTERY", "Mastery" },
    { "Vers", "ITEM_MOD_VERSATILITY", "STAT_VERSATILITY", "Versatility" },
    { "Avoid", "ITEM_MOD_CR_AVOIDANCE_SHORT", "STAT_AVOIDANCE", "Avoidance" },
    { "Move", "STAT_MOVEMENT_SPEED", "Movement Speed" },
    { "DPS", "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "Damage Per Second" },
    { "iLvl", "STAT_AVERAGE_ITEM_LEVEL", "Item Level" },
}
for _, school in ipairs({ "Holy", "Fire", "Nature", "Frost", "Shadow", "Arcane" }) do
    LIST[#LIST + 1] = { school .. " Res", school .. " Resistance" }
    LIST[#LIST + 1] = { school .. " dmg", school .. " Damage" }
    LIST[#LIST + 1] = { school .. " pen", school .. " Piercing", school .. " Penetration" }
end

-- [the game's word in small letters] = the short word.
local SHORT = {}
for _, stat in ipairs(LIST) do
    for index = 2, #stat do
        SHORT[Core.Word(stat[index], stat[index]):lower()] = stat[1]
    end
end

function Core.StatWord(word)
    return type(word) == "string" and SHORT[word:lower()] or word
end

function Core.StatLine(line)
    if type(line) ~= "string" then return line end
    -- "+8 Stamina"; a comparison's change has its number coloured: "|cff00ff00+2.2|r damage per second"
    local number, word = line:match("^([%+%-]?[%d,%.]+%%?)%s+(.+)$")
    if not number then number, word = line:match("^(|c%x+[%+%-]?[%d,%.]+%%?|r)%s+(.+)$") end
    local short = word and SHORT[word:lower()]
    return short and number .. " " .. short or line
end
