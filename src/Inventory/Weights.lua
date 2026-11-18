local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Weights
--  What each stat is worth to a character, by class and specialization
--  (Saneroki, 2026-10-30): so that "an upgrade" means better for the one who
--  plays it, not only a higher item level. Core.Upgrade asks for them
--  (Core.WeighWith), so the bags, the loot, Speed Leveling's rewards and its
--  group rolls all judge the same way; with Inventory off, item levels decide.
--
--  One line for each specialization, the one a leveling character plays: the
--  stat a character builds on is worth 1, so that a warrior's and a druid's
--  numbers can be held against each other. A character without a specialization
--  yet goes by its class's first line (early).
--    Forever  pairs of a stat and its worth. What follows from the game's rules
--             is held to: a warrior's Strength is 2 Attack Power, 14 Attack
--             Power 1 damage per second (dps), so dps 7 where Strength is 1.
--    Retail   the main stat, then the secondary stats best first; gear there
--             scales, so the rest is the same for all (Weights.LADDER, sta, dps).
--
--  A shield build (Saneroki, 2026-11-04): a warrior whose talents work only
--  with a shield fights with a one-handed weapon and a shield, however much
--  more a two-hander's damage would weigh. So Core.Upgrade is told (shield):
--  no two-hander, the off hand the shield's. A shield build is the game's
--  primary talent tree being Protection (Weights.SHIELD), or a talent whose
--  spell the game's tooltip says asks for a shield. Before the first talent
--  (level 10) nothing asks for one, and the two-hander's damage leads.
--
--      Weights.Now()               the character's weights: { [the game's stat key] = worth, ranged = worth,
--                                  shield = true on a shield build }
--      Weights.For(game, class, spec)   the same for any: "forever" or "retail", the game's class token, spec in small
--                                  letters; a class's early line for a spec it has no line for
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Weights = {}
ns.Weights = Weights

-- The short names of the lines below, and the keys the game's GetItemStats answers with. dps is a melee weapon's or a
-- staff's; ranged a bow's, gun's, thrown weapon's or wand's damage per second (Core.Upgrade tells them apart).
Weights.STATS = {
    str = "ITEM_MOD_STRENGTH_SHORT", agi = "ITEM_MOD_AGILITY_SHORT", sta = "ITEM_MOD_STAMINA_SHORT",
    int = "ITEM_MOD_INTELLECT_SHORT", spi = "ITEM_MOD_SPIRIT_SHORT", armor = "RESISTANCE0_NAME",
    ap = "ITEM_MOD_ATTACK_POWER_SHORT", rap = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    sp = "ITEM_MOD_SPELL_POWER_SHORT", dmg = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", heal = "ITEM_MOD_SPELL_HEALING_DONE_SHORT",
    mp5 = "ITEM_MOD_MANA_REGENERATION_SHORT", hit = "ITEM_MOD_HIT_RATING_SHORT", crit = "ITEM_MOD_CRIT_RATING_SHORT",
    haste = "ITEM_MOD_HASTE_RATING_SHORT", exp = "ITEM_MOD_EXPERTISE_RATING_SHORT",
    def = "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", dodge = "ITEM_MOD_DODGE_RATING_SHORT", block = "ITEM_MOD_BLOCK_VALUE_SHORT",
    mastery = "ITEM_MOD_MASTERY_RATING_SHORT", vers = "ITEM_MOD_VERSATILITY",
    dps = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", ranged = "ranged",
}
-- The classes that may fight with a shield by their talents, and the specialization (the game's primary talent tree)
-- that always does: in both games a warrior's Protection.
Weights.SHIELD = { WARRIOR = "protection" }
Weights.LADDER = { 0.7, 0.6, 0.5, 0.4 } -- Retail: the secondary stats, best first
Weights.RETAIL_STA = 0.3                -- Retail: Stamina, to stay alive
Weights.RETAIL_DPS = 2                  -- Retail: a physical fighter's weapon damage per second

local WARRIOR = "dps 7 ranged .5 str 1 ap .5 sta .6 agi .4 hit 1 crit .9 exp .8 haste .5 armor .01"
local CASTER = "int 1 sp 1 dmg 1 sta .5 spi .5 hit .5 crit .5 haste .4 mp5 .4 armor .01 ranged 1"
-- In WoW: Forever, Cat, Bear and Dire Bear Form swing the equipped weapon: their attacks deal its damage per second
-- (unlike Classic, where forms ignored it). A druid's Strength is 2 Attack Power, in forms and out, so as a warrior's:
-- dps 7 where Strength is 1.
local FERAL = "str 1 agi 1 ap .5 sta .5 int .25 spi .25 hit 1 exp .9 crit 1 haste .6 dodge .5 def .5 dps 7 armor .02"

Weights.FOREVER = {
    WARRIOR = {
        early = WARRIOR,
        arms = WARRIOR,
        fury = "dps 7 ranged .5 str 1 ap .5 sta .6 agi .45 hit 1.1 crit 1 exp .9 haste .5 armor .01",
        protection = "dps 5 ranged .5 str .8 ap .4 sta 1 agi .5 hit 1 exp .8 crit .5 def .7 dodge .7 block .3 armor .02",
    },
    DRUID = {
        early = CASTER,
        balance = "int 1 sp 1 dmg 1 sta .5 spi .5 hit .9 crit .8 haste .6 mp5 .4 armor .01",
        feral = FERAL, ["feral combat"] = FERAL, -- WoW: Forever names the tree Feral Combat (GetSpecializationInfo)
        restoration = "int 1 heal 1 sp 1 sta .5 spi .6 mp5 .5 haste .5 crit .4 armor .01",
    },
    ROGUE = {
        early = "dps 7 ranged .3 agi 1 ap .5 str .5 sta .35 crit 1.1 hit .9 haste .6 exp .7 armor .01",
        assassination = "dps 7 ranged .3 crit 1.1 agi 1 ap .5 str .5 sta .35 hit .9 haste .6 exp .7 armor .01",
        combat = "dps 7 ranged .3 crit 1.1 agi 1 ap .5 str .5 sta .35 hit 1 haste .6 exp .7 armor .01",
        subtlety = "dps 7 ranged .3 crit 1.1 agi 1 ap .5 str .5 sta .35 hit .9 haste .5 exp .7 armor .01",
    },
    HUNTER = {
        early = "ranged 5 dps .5 agi 1 rap .5 ap .25 int .4 sta .3 spi .3 armor .01",
        ["beast mastery"] = "ranged 5 dps .5 agi 1 rap .5 ap .25 crit .8 int .35 sta .3 spi .3 hit .9 haste .5 str .1 armor .01",
        marksmanship = "ranged 5 dps .5 agi 1 rap .5 ap .25 crit .8 int .35 sta .3 spi .3 hit .9 haste .5 str .1 armor .01",
        survival = "ranged 5 dps 1 agi 1 rap .5 ap .3 crit .8 str .3 int .3 sta .3 spi .3 hit .9 haste .5 armor .01",
    },
    MAGE = {
        early = CASTER,
        arcane = "int 1 sp .9 dmg .9 spi .6 mp5 .5 sta .35 crit .6 haste .5 hit .5 armor .01 ranged 1",
        fire = "sp 1 dmg 1 int .8 mp5 .5 sta .35 spi .3 crit .7 haste .5 hit .5 armor .01 ranged 1",
        frost = "sp 1 dmg 1 int .8 mp5 .5 sta .35 spi .3 haste .7 crit .6 hit .5 armor .01 ranged 1",
    },
    PRIEST = {
        early = CASTER,
        discipline = "int 1 sp 1 dmg 1 heal 1 sta .5 spi .5 mp5 .5 crit .3 haste .3 armor .01 ranged 1",
        holy = "int 1 sp 1 dmg 1 heal 1 sta .5 spi .5 mp5 .5 crit .3 haste .3 armor .01 ranged 1",
        shadow = "int 1 sp 1 dmg 1 sta .5 spi .5 hit .9 crit .7 haste .4 mp5 .3 armor .01 ranged 1",
    },
    PALADIN = {
        early = "dps 7 str 1 ap .5 sta .7 sp .5 dmg .5 int .3 armor .01",
        holy = "heal 1 sp 1 dmg .8 int .9 crit .6 spi .4 mp5 .4 sta .5 armor .01",
        protection = "sp 1 dmg 1 sta .8 int .6 str .5 ap .25 hit .8 dps 5 def .5 dodge .5 block .3 armor .02",
        retribution = "dps 7 str 1 ap .5 sta .7 sp .5 dmg .5 int .4 hit 1 crit .9 agi .3 armor .01",
    },
    SHAMAN = {
        early = "dmg 1 sp 1 str .8 ap .4 int .6 sta .4 spi .4 dps 4 armor .01",
        elemental = "dmg 1 sp 1 int 1 crit .7 hit .7 sta .4 spi .4 haste .5 mp5 .4 armor .01",
        enhancement = "dps 7 hit 1 exp 1 str .9 ap .45 int .6 crit .6 dmg .4 sp .4 agi .3 sta .4 armor .01",
        restoration = "heal 1 sp 1 int .7 spi .7 crit .5 haste .5 mp5 .5 sta .4 armor .01",
    },
    WARLOCK = {
        early = "ranged 2 sp 1 dmg 1 int .8 sta .5 spi .5 hit .5 crit .4 haste .4 armor .01",
        affliction = "sp 1 dmg 1 ranged 1.5 int .5 spi .5 sta .4 hit .8 crit .5 haste .4 armor .01",
        demonology = "sp 1 dmg 1 ranged 1.5 int .5 spi .5 sta .4 hit .8 crit .5 haste .4 armor .01",
        destruction = "sp 1 dmg 1 ranged 1.5 int .6 spi .6 sta .35 hit .8 crit .5 haste .4 armor .01",
    },
}

-- The main stat, then the secondary stats best first.
Weights.RETAIL = {
    WARRIOR = { early = "str crit haste mastery vers", arms = "str mastery crit vers haste",
                fury = "str haste vers mastery crit", protection = "str crit vers mastery haste" },
    DRUID = { early = "int haste crit mastery vers", balance = "int haste mastery crit vers",
              feral = "agi haste crit vers mastery", guardian = "agi haste vers crit mastery",
              restoration = "int haste mastery vers crit" },
    ROGUE = { early = "agi crit vers haste mastery", assassination = "agi vers mastery crit haste",
              outlaw = "agi crit vers haste mastery", subtlety = "agi vers mastery haste crit" },
    HUNTER = { early = "agi crit haste mastery vers", ["beast mastery"] = "agi mastery crit haste vers",
               marksmanship = "agi vers haste crit mastery", survival = "agi haste mastery crit vers" },
    MAGE = { early = "int crit haste vers mastery", arcane = "int vers crit haste mastery",
             fire = "int haste vers mastery crit", frost = "int mastery crit haste vers" },
    PRIEST = { early = "int crit haste vers mastery", discipline = "int haste crit mastery vers",
               holy = "int crit vers mastery haste", shadow = "int crit vers mastery haste" },
    PALADIN = { early = "str crit haste mastery vers", holy = "int mastery crit haste vers",
                protection = "str crit vers haste mastery", retribution = "str crit haste mastery vers" },
    SHAMAN = { early = "int crit haste vers mastery", elemental = "int crit vers haste mastery",
               enhancement = "agi crit haste mastery vers", restoration = "int crit haste mastery vers" },
    WARLOCK = { early = "int crit haste vers mastery", affliction = "int crit haste mastery vers",
                demonology = "int mastery crit vers haste", destruction = "int haste vers crit mastery" },
    DEATHKNIGHT = { early = "str crit mastery haste vers", blood = "str crit mastery vers haste",
                    frost = "str crit mastery haste vers", unholy = "str crit mastery haste vers" },
    DEMONHUNTER = { early = "agi crit haste mastery vers", havoc = "agi crit haste mastery vers",
                    vengeance = "agi crit vers mastery haste" },
    MONK = { early = "agi crit mastery haste vers", brewmaster = "agi crit vers mastery haste",
             mistweaver = "int haste crit vers mastery", windwalker = "agi crit mastery haste vers" },
    EVOKER = { early = "int haste crit vers mastery", devastation = "int haste crit vers mastery",
               preservation = "int mastery crit haste vers", augmentation = "int crit haste vers mastery" },
}

local made = {} -- [line] = its table, made once
local now       -- the character's, until its specialization changes

-- A Forever line, pairs of a stat and its worth, as the table Core.Upgrade reads.
local function Pairs(line)
    local weights = {}
    for name, worth in line:gmatch("(%S+) (%S+)") do weights[Weights.STATS[name]] = tonumber(worth) end
    return weights
end

-- A Retail line: the main stat, the secondaries down the ladder, the rest as for all.
local function Ladder(line)
    local weights, rung = {}, 0
    for name in line:gmatch("%S+") do
        weights[Weights.STATS[name]] = Weights.LADDER[rung] or 1
        rung = rung + 1
    end
    weights[Weights.STATS.sta] = Weights.RETAIL_STA
    if not line:find("^int") then
        weights[Weights.STATS.dps], weights.ranged = Weights.RETAIL_DPS, Weights.RETAIL_DPS
    end
    return weights
end

function Weights.For(game, class, spec)
    local lines = (game == "forever" and Weights.FOREVER or Weights.RETAIL)[class]
    local line = lines and (lines[spec] or lines.early)
    if not line then return nil end
    made[line] = made[line] or (game == "forever" and Pairs or Ladder)(line)
    return made[line]
end

-- The character's specialization's name in small letters; nil before it has one.
local function Spec()
    local specs = rawget(_G, "C_SpecializationInfo")
    local index = specs and specs.GetSpecialization and Core.Ask(specs.GetSpecialization)
    if type(index) ~= "number" or index < 1 then return nil end
    local _, name = Core.Ask(specs.GetSpecializationInfo, index, false, false, nil, Core.Ask(UnitSex, "player"))
    return type(name) == "string" and name:lower() or nil
end

local ARMOR, SHIELDS = 4, 6 -- the game's item class of armour and its kind for shields (Enum.ItemClass, ItemArmorSubclass)

-- Whether a tooltip's line asks for a shield, in the game's words for a spell's equipped item (SPELL_EQUIPPED_ITEM,
-- "Requires %s") and its name for the kind (Shield or Shields, the game writes either).
local function AsksShield(text, lead, shields)
    if type(text) ~= "string" or text:sub(1, #lead) ~= lead then return false end
    local rest = text:sub(#lead + 1)
    return rest ~= "" and (rest:find(shields, 1, true) ~= nil or shields:find(rest, 1, true) ~= nil)
end

-- Whether a talent the character has asks for a shield: the tooltip of its spell, as the game writes it (in WoW:
-- Forever Shield Slam, Bastion, Defiance). The active configuration's nodes with a rank (C_Traits).
local function ShieldTalent()
    local traits, talents, tips = rawget(_G, "C_Traits"), rawget(_G, "C_ClassTalents"), rawget(_G, "C_TooltipInfo")
    local items, form = rawget(_G, "C_Item"), rawget(_G, "SPELL_EQUIPPED_ITEM")
    if not (traits and talents and tips and items and type(form) == "string") then return false end
    local lead, shields = form:match("^(.-)%%s"), Plain(Core.Ask(items.GetItemSubClassInfo, ARMOR, SHIELDS))
    local config = Plain(Core.Ask(talents.GetActiveConfigID))
    local info = lead and type(shields) == "string" and shields ~= "" and config and Core.Ask(traits.GetConfigInfo, config)
    for _, tree in ipairs(type(info) == "table" and type(info.treeIDs) == "table" and info.treeIDs or {}) do
        for _, id in ipairs(Core.Ask(traits.GetTreeNodes, tree) or {}) do
            local node = Core.Ask(traits.GetNodeInfo, config, id)
            local active = type(node) == "table" and (Plain(node.activeRank) or 0) > 0 and node.activeEntry
            local entry = type(active) == "table" and Core.Ask(traits.GetEntryInfo, config, active.entryID)
            local definition = type(entry) == "table" and entry.definitionID and Core.Ask(traits.GetDefinitionInfo, entry.definitionID)
            local spell = type(definition) == "table" and Plain(definition.spellID)
            local tip = spell and Core.Ask(tips.GetSpellByID, spell)
            for _, line in ipairs(type(tip) == "table" and type(tip.lines) == "table" and tip.lines or {}) do
                if AsksShield(Plain(line.leftText), lead, shields) then return true end
            end
        end
    end
    return false
end

local shielded = {} -- [weights] = the same with shield, made once

function Weights.Now()
    if now == nil then
        local _, class = Core.Ask(UnitClass, "player")
        local spec = Spec()
        now = Weights.For(Core.FOREVER and "forever" or "retail", class, spec) or false
        if now and Weights.SHIELD[class] and (spec == Weights.SHIELD[class] or ShieldTalent()) then
            if not shielded[now] then
                local copy = { shield = true }
                for stat, worth in pairs(now) do copy[stat] = worth end
                shielded[now] = copy
            end
            now = shielded[now]
        end
    end
    return now or nil
end

local function Changed() now = nil end

function Weights.Start()
    for _, event in ipairs({ "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
                             "TRAIT_CONFIG_UPDATED" }) do
        ns.On(event, Changed)
    end
    Core.WeighWith(Weights.Now)
end
