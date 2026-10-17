local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - which spellbook tab a spell belongs to (last resort)
--
--  The game tells an addon the tab of a spell only once you know one of its
--  ranks, or at the class trainer (his list is grouped by tab). For a spell
--  that is still entirely new, and before your first visit to the trainer,
--  this list is used: English spell name -> skill line number, as in Classic.
--  A spell that is not here, or a game in another language, simply lands in
--  the last group of the first class tab until the trainer has been visited.
--
--  The numbers are the game's skill lines (26 = Arms, 256 = Fury ...);
--  C_SpellBook.GetSkillLineIndexByID turns one into a spellbook tab.
-------------------------------------------------------------------------------
local lines = {
    WARRIOR = {
        [26] = { "Battle Stance", "Charge", "Hamstring", "Heroic Strike", "Mocking Blow", "Mortal Strike", "Overpower",
                 "Rend", "Retaliation", "Sweeping Strikes", "Thunder Clap" },
        [256] = { "Battle Shout", "Berserker Rage", "Berserker Stance", "Bloodthirst", "Challenging Shout", "Cleave",
                  "Death Wish", "Demoralizing Shout", "Execute", "Intercept", "Intimidating Shout", "Piercing Howl",
                  "Pummel", "Recklessness", "Slam", "Whirlwind" },
        [257] = { "Bloodrage", "Concussion Blow", "Defensive Stance", "Disarm", "Last Stand", "Revenge", "Shield Bash",
                  "Shield Block", "Shield Slam", "Shield Wall", "Sunder Armor", "Taunt" },
    },
    PALADIN = {
        [594] = { "Blessing of Light", "Blessing of Wisdom", "Cleanse", "Consecration", "Divine Favor", "Exorcism",
                  "Flash of Light", "Greater Blessing of Light", "Greater Blessing of Wisdom", "Hammer of Wrath",
                  "Holy Light", "Holy Shock", "Holy Wrath", "Lay on Hands", "Purify", "Redemption",
                  "Seal of Light", "Seal of Righteousness", "Seal of Wisdom", "Sense Undead", "Turn Undead" },
        [267] = { "Blessing of Freedom", "Blessing of Kings", "Blessing of Protection", "Blessing of Sacrifice",
                  "Blessing of Salvation", "Blessing of Sanctuary", "Concentration Aura", "Devotion Aura",
                  "Divine Intervention", "Divine Protection", "Divine Shield", "Fire Resistance Aura",
                  "Frost Resistance Aura", "Greater Blessing of Kings", "Greater Blessing of Salvation",
                  "Greater Blessing of Sanctuary", "Hammer of Justice", "Holy Shield", "Righteous Fury",
                  "Seal of Justice", "Shadow Resistance Aura" },
        [184] = { "Blessing of Might", "Greater Blessing of Might", "Judgement", "Repentance", "Retribution Aura",
                  "Sanctity Aura", "Seal of Command", "Seal of the Crusader" },
    },
    HUNTER = {
        [50] = { "Aspect of the Beast", "Aspect of the Cheetah", "Aspect of the Hawk", "Aspect of the Monkey",
                 "Aspect of the Pack", "Aspect of the Wild", "Beast Lore", "Bestial Wrath", "Call Pet", "Dismiss Pet",
                 "Eagle Eye", "Eyes of the Beast", "Feed Pet", "Intimidation", "Mend Pet", "Revive Pet", "Scare Beast",
                 "Tame Beast" },
        [163] = { "Aimed Shot", "Arcane Shot", "Auto Shot", "Concussive Shot", "Distracting Shot", "Flare",
                  "Hunter's Mark", "Multi-Shot", "Rapid Fire", "Scatter Shot", "Scorpid Sting", "Serpent Sting",
                  "Tranquilizing Shot", "Trueshot Aura", "Viper Sting", "Volley" },
        [51] = { "Counterattack", "Deterrence", "Disengage", "Explosive Trap", "Feign Death", "Freezing Trap",
                 "Frost Trap", "Immolation Trap", "Mongoose Bite", "Raptor Strike", "Track Beasts", "Track Demons",
                 "Track Dragonkin", "Track Elementals", "Track Giants", "Track Hidden", "Track Humanoids",
                 "Track Undead", "Wing Clip", "Wyvern Sting" },
    },
    ROGUE = {
        [253] = { "Ambush", "Cheap Shot", "Cold Blood", "Eviscerate", "Expose Armor", "Garrote", "Kidney Shot",
                  "Rupture", "Slice and Dice" },
        [38] = { "Adrenaline Rush", "Backstab", "Blade Flurry", "Evasion", "Feint", "Gouge", "Kick", "Riposte",
                 "Sinister Strike", "Sprint" },
        [39] = { "Blind", "Detect Traps", "Disarm Trap", "Distract", "Ghostly Strike", "Hemorrhage", "Pick Pocket",
                 "Premeditation", "Preparation", "Safe Fall", "Sap", "Stealth", "Vanish" },
    },
    PRIEST = {
        [613] = { "Dispel Magic", "Divine Spirit", "Elune's Grace", "Fear Ward", "Feedback", "Inner Fire", "Inner Focus",
                  "Levitate", "Mana Burn", "Power Infusion", "Power Word: Fortitude", "Power Word: Shield",
                  "Prayer of Fortitude", "Prayer of Spirit", "Shackle Undead", "Starshards" },
        [56] = { "Abolish Disease", "Cure Disease", "Desperate Prayer", "Flash Heal", "Greater Heal", "Heal",
                 "Holy Fire", "Holy Nova", "Lesser Heal", "Lightwell", "Prayer of Healing", "Renew", "Resurrection",
                 "Smite" },
        [78] = { "Devouring Plague", "Fade", "Hex of Weakness", "Mind Blast", "Mind Control", "Mind Flay",
                 "Mind Soothe", "Mind Vision", "Prayer of Shadow Protection", "Psychic Scream", "Shadow Protection",
                 "Shadow Word: Pain", "Shadowform", "Shadowguard", "Silence", "Touch of Weakness", "Vampiric Embrace" },
    },
    SHAMAN = {
        [375] = { "Chain Lightning", "Earth Shock", "Earthbind Totem", "Elemental Mastery", "Fire Nova Totem",
                  "Flame Shock", "Frost Shock", "Lightning Bolt", "Magma Totem", "Purge", "Searing Totem",
                  "Stoneclaw Totem" },
        [373] = { "Astral Recall", "Far Sight", "Fire Resistance Totem", "Flametongue Totem", "Flametongue Weapon",
                  "Frost Resistance Totem", "Frostbrand Weapon", "Ghost Wolf", "Grace of Air Totem", "Grounding Totem",
                  "Lightning Shield", "Nature Resistance Totem", "Rockbiter Weapon", "Sentry Totem", "Stoneskin Totem",
                  "Stormstrike", "Strength of Earth Totem", "Water Breathing", "Water Walking", "Windfury Totem",
                  "Windfury Weapon", "Windwall Totem" },
        [374] = { "Ancestral Spirit", "Chain Heal", "Cure Disease", "Cure Poison", "Disease Cleansing Totem",
                  "Healing Stream Totem", "Healing Wave", "Lesser Healing Wave", "Mana Spring Totem", "Mana Tide Totem",
                  "Nature's Swiftness", "Poison Cleansing Totem", "Reincarnation", "Tranquil Air Totem", "Tremor Totem" },
    },
    MAGE = {
        [237] = { "Amplify Magic", "Arcane Brilliance", "Arcane Explosion", "Arcane Intellect", "Arcane Missiles",
                  "Arcane Power", "Blink", "Conjure Food", "Conjure Mana Agate", "Conjure Mana Citrine",
                  "Conjure Mana Jade", "Conjure Mana Ruby", "Conjure Water", "Counterspell", "Dampen Magic",
                  "Detect Magic", "Evocation", "Mage Armor", "Mana Shield", "Polymorph", "Presence of Mind",
                  "Remove Lesser Curse", "Slow Fall" },
        [8] = { "Blast Wave", "Combustion", "Fire Blast", "Fire Ward", "Fireball", "Flamestrike", "Pyroblast", "Scorch" },
        [6] = { "Blizzard", "Cold Snap", "Cone of Cold", "Frost Armor", "Frost Nova", "Frost Ward", "Frostbolt",
                "Ice Armor", "Ice Barrier", "Ice Block" },
    },
    WARLOCK = {
        [355] = { "Amplify Curse", "Corruption", "Curse of Agony", "Curse of Doom", "Curse of Exhaustion",
                  "Curse of Recklessness", "Curse of Shadow", "Curse of Tongues", "Curse of Weakness",
                  "Curse of the Elements", "Dark Pact", "Death Coil", "Drain Life", "Drain Mana", "Drain Soul", "Fear",
                  "Howl of Terror", "Life Tap", "Siphon Life" },
        [354] = { "Banish", "Create Firestone", "Create Healthstone", "Create Soulstone", "Create Spellstone",
                  "Demon Armor", "Demon Skin", "Demonic Sacrifice", "Detect Greater Invisibility",
                  "Detect Invisibility", "Detect Lesser Invisibility", "Enslave Demon", "Eye of Kilrogg",
                  "Fel Domination", "Health Funnel", "Inferno", "Ritual of Doom", "Ritual of Summoning", "Sense Demons",
                  "Shadow Ward", "Soul Link", "Summon Felhunter", "Summon Imp", "Summon Succubus", "Summon Voidwalker",
                  "Unending Breath" },
        [593] = { "Conflagrate", "Hellfire", "Immolate", "Rain of Fire", "Searing Pain", "Shadow Bolt", "Shadowburn",
                  "Soul Fire" },
    },
    DRUID = {
        [574] = { "Barkskin", "Entangling Roots", "Faerie Fire", "Hibernate", "Hurricane", "Moonfire", "Moonkin Form",
                  "Nature's Grasp", "Soothe Animal", "Starfire", "Teleport: Moonglade", "Thorns", "Wrath" },
        [134] = { "Aquatic Form", "Bash", "Bear Form", "Cat Form", "Challenging Roar", "Claw", "Cower", "Dash",
                  "Demoralizing Roar", "Dire Bear Form", "Enrage", "Feral Charge", "Ferocious Bite",
                  "Frenzied Regeneration", "Growl", "Maul", "Pounce", "Prowl", "Rake", "Ravage", "Rip", "Shred", "Swipe",
                  "Tiger's Fury", "Track Humanoids", "Travel Form" },
        [573] = { "Abolish Poison", "Cure Poison", "Gift of the Wild", "Healing Touch", "Innervate", "Mark of the Wild",
                  "Rebirth", "Regrowth", "Rejuvenation", "Remove Curse", "Swiftmend", "Tranquility" },
    },
}

-- [class][spell name] = skill line number
ns.SkillLineOfName = {}
for class, byLine in pairs(lines) do
    local names = {}
    for line, list in pairs(byLine) do
        for _, name in ipairs(list) do names[name] = line end
    end
    ns.SkillLineOfName[class] = names
end

-- The three lines of each class in the order of its talent trees, for abilities that
-- come from a talent: the tree says the tab.
ns.TreeLines = {
    WARRIOR = { 26, 256, 257 }, PALADIN = { 594, 267, 184 }, HUNTER = { 50, 163, 51 },
    ROGUE = { 253, 38, 39 }, PRIEST = { 613, 56, 78 }, SHAMAN = { 375, 373, 374 },
    MAGE = { 237, 8, 6 }, WARLOCK = { 355, 354, 593 }, DRUID = { 574, 134, 573 },
}
