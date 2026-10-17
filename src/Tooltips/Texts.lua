local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Texts
--  The module's own words, and the words of the game it has to know.
--
--  A panel sorts a tooltip's lines, and some lines can only be known by what
--  they say ("Durability 61 / 120"): the game has no kind for them. Where the
--  game keeps the sentence in a global of its own (DURABILITY_TEMPLATE), that
--  is used and every language works. Where it does not, the English wording
--  is here, and in another language such a line simply stays a plain row.
-------------------------------------------------------------------------------

-- What the panels say themselves.
ns.TEXT = {
    -- A spell's facts in its strip (Kinds/Spell.lua), and the units after their numbers
    COST = "Cost", CAST = "Cast", COOLDOWN = "Cooldown", RANGE = "Range",
    SECONDS = "%s sec", MINUTES = "%s min", HOURS = "%s hr", YARDS = "%s yd",
    VENDOR = "Vendor", AUCTION = "Auction", USED_IN = "Used in",
    -- An item's sections (Kinds/Item.lua, Kinds/Gold.lua), from the module's own data
    PROFESSIONS = "Professions", GOLD = "Gold",
    AH_PROFIT = "AH profit", NO_VENDOR = "Can't be sold",
    SELL_AH = "Sell on the AH for %s", MORE_AH = "+%s over the AH",
    SELL_VENDOR = "Sell to a vendor", BUY_UNDER = "Buy if under %s", NOW = "now %s",
    PRICES = "Lowest %s", FEES = "Cut %s  \194\183  deposit %s, back when it sells",
    ALT_MORE = "Press ALT for +%d more",
    EQUIPPED = "Equipped",
    DPS = "DPS", DMG = "dmg", SPD = "spd", HPS = "HPS", DAMAGE = "Damage", HEALING = "Healing", PER = "Per %s", SPEED = "Speed", CRIT = "Crit",
    MANA = "Mana",
    -- What a spell is when it names no school (Spell.lua)
    PHYSICAL = "Physical", CC = "CC", UTILITY = "Utility",
    XP = "%d XP", KILLS = "Next level in %d", -- a creature: what killing it gives, and how many such kills you need
    OFFERS = "Offers", TURN_IN = "Turn in", -- the quest section (Kinds/Unit.lua)
    STARTS = "Starts the quest", QUEST_ITEM = "Quest item", -- an item a creature drops that starts a quest
    -- An item's quests (Kinds/Item.lua): the quest it starts, and where you stand with it
    QUEST = "Quest", STARTS_HEAD = "Starts", NEEDED_HEAD = "Needed for", QUESTLOG = "Questlog",
    IN_LOG = "In log", IN_LOG_COUNT = "In log  %s", AVAILABLE = "Available", NOT_YET = "Not yet", DONE_QUEST = "Done",
    CHANCE = "%s%%", -- how often a creature drops what a quest asks for, after the item's name: "33%"
    -- How an item binds, as players write it, by the game's kinds of binding (Enum.TooltipDataItemBinding)
    BINDS = {
        BindOnPickup = "BoP", BindOnEquip = "BoE", BindOnUse = "BoU", Soulbound = "Soulbound", Quest = "Quest",
        Account = "BoA", BnetAccount = "BoA", BindToAccount = "BoA", BindToBnetAccount = "BoA",
        AccountUntilEquipped = "WuE", BindToAccountUntilEquipped = "WuE", -- warbound until equipped
    },
    UNCOLLECTED = "Uncollected", LOOK_KNOWN = "Look known", -- an item's appearance, for your collection
    ITEM_LEVEL = "iLvl %d",
    PLAQUE = "|cff%siLvl %d -|r %s", -- a player's item level (in a colour given first) and level, on the plaque
    CREATES = "Creates",
    OBJECTIVES = "Objectives",
    TARGET = "Target", YOU = "You", -- whom a unit targets (the game's TARGET and UNIT_YOU where it has them)
    PVP = "PvP", TAPPED = "Tapped", AFK = "AFK", DND = "DND", DEAD = "Dead", GHOST = "Ghost", OFFLINE = "Offline",
    ELITE = "Elite", BOSS = "Boss", RARE = "Rare", -- a creature's rank (the game's ELITE, BOSS, RARE where it has them)
    BUFF = "Buff", DEBUFF = "Debuff",
    BY = "by %s",
    LEVEL = "Level %d",
    IN_PROGRESS = "In progress", READY = "Ready to turn in", DONE = "Completed",
    -- With Alt held: the technical details at a tooltip's bottom
    ID = "%s ID: %s", SPELL = "Spell", ICON = "Icon", NPC = "NPC", GUID = "GUID: %s",
}

-- A global text of the game, or nil. (Reading a global that is not there is no error in the game.)
local function Global(name)
    local text = rawget(_G, name)
    return type(text) == "string" and text or nil
end
ns.Global = Global

-- Turns one of the game's sentences with gaps ("Durability %d / %d") into a pattern that finds
-- the gaps' values in a line. name: the game's global for it; english: the wording if it has none.
local function Pattern(name, english)
    local sentence = Global(name) or english
    -- The gaps: a whole number, a number with a fraction, any words
    sentence = sentence:gsub("%%[%d%$%.%-+ #]*[diu]", "\1"):gsub("%%[%d%$%.%-+ #]*[fg]", "\2"):gsub("%%[%d%$%.%-+ #]*s", "\3")
    sentence = sentence:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%0") -- the rest stands for itself
    sentence = sentence:gsub("\1", "(%%d+)"):gsub("\2", "([%%d%%.,]+)"):gsub("\3", "(.-)")
    return "^" .. sentence .. "$"
end

-- Finds the words in any mix of capitals and small letters: "Damage per Second" also finds
-- "damage per second" and "Damage Per Second".
local function AnyCase(words)
    words = words:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%0")
    return (words:gsub("%a", function(letter) return "[" .. letter:lower() .. letter:upper() .. "]" end))
end

ns.PATTERN = {
    MIN_LEVEL = Pattern("ITEM_MIN_LEVEL", "Requires Level %d"),
    DPS = Pattern("DPS_TEMPLATE", "(%s damage per second)"),
    DPS_WORDS = AnyCase(Global("ITEM_MOD_DAMAGE_PER_SECOND_SHORT") or "Damage per Second"),
    ARMOR = Pattern("ARMOR_TEMPLATE", "%s Armor"),
    DURABILITY = Pattern("DURABILITY_TEMPLATE", "Durability %d / %d"),
    ITEM_LEVEL = Pattern("ITEM_LEVEL", "Item Level %d"),
    -- What else an item asks of you: a class or race, a profession's skill, a reputation, a spell
    -- known. The panel shows them in its header, under the level it needs (Kinds/Item.lua).
    REQUIRES = {
        Pattern("ITEM_CLASSES_ALLOWED", "Classes: %s"), Pattern("ITEM_RACES_ALLOWED", "Races: %s"),
        Pattern("ITEM_MIN_SKILL", "Requires %s (%d)"), Pattern("ITEM_REQ_REPUTATION", "Requires %s - %s"),
        Pattern("ITEM_REQ_SKILL", "Requires %s"),
    },
}

-- Whole lines of the game an item's panel knows by their words.
ns.LINES = {
    -- The game writes what an item sells for once more as a line of text ("Sell Price: 81"), and a
    -- stack's lowest and highest price under it
    SELL = (Global("SELL_PRICE") or "Sell Price") .. ":",
    MINIMUM = Global("MINIMUM") or "Minimum", MAXIMUM = Global("MAXIMUM") or "Maximum",
    -- The sentence over the changes a comparison lists
    DELTA = Global("ITEM_DELTA_DESCRIPTION") or "If you replace this item, the following stat changes will occur:",
    DELTA_BOTH = Global("ITEM_DELTA_MULTIPLE_COMPARISON_DESCRIPTION") or "If you replace these items, the following stat changes will occur:",
    -- Whether you have an item's appearance
    UNCOLLECTED = Global("TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN") or "You haven't collected this appearance",
    LOOK_KNOWN = Global("TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN") or "You've collected this appearance, but not from this item",
    -- An item that starts a quest: its panel names the quest instead
    STARTS_QUEST = Global("ITEM_STARTS_QUEST") or "This Item Begins a Quest",
}

-- The facts a spell's tooltip states in lines of their own (Kinds/Spell.lua): what it costs, its
-- range, its cast and its cooldown. The game has no function for all of them (none for a spell's
-- cooldown as such), so each is known by the game's own sentence for it, in every language. key:
-- the fact; unit: how its number is shown ("3 min"; a sentence without a number, "Channeled", is
-- shown as written); caption: a cost's, its power's name.
local function Fact(key, name, english, how)
    how = how or {}
    how.key, how.pattern = key, Pattern(name, english)
    return how
end
ns.FACTS = {
    Fact("cost", "MANA_COST", "%d Mana", { caption = Global("MANA") or "Mana" }),
    Fact("cost", "RAGE_COST", "%d Rage", { caption = Global("RAGE") or "Rage" }),
    Fact("cost", "ENERGY_COST", "%d Energy", { caption = Global("ENERGY") or "Energy" }),
    Fact("cost", "FOCUS_COST", "%d Focus", { caption = Global("FOCUS") or "Focus" }),
    Fact("range", "SPELL_RANGE", "%s yd range", { unit = ns.TEXT.YARDS }),
    Fact("range", "MELEE_RANGE", "Melee Range"),
    Fact("cast", "SPELL_CAST_TIME_SEC", "%.3g sec cast", { unit = ns.TEXT.SECONDS }),
    Fact("cast", "SPELL_CAST_TIME_MIN", "%.3g min cast", { unit = ns.TEXT.MINUTES }),
    Fact("cast", "SPELL_CAST_TIME_INSTANT", "Instant cast"),
    Fact("cast", "SPELL_CAST_TIME_INSTANT_NO_MANA", "Instant"),
    Fact("cast", "SPELL_CAST_CHANNELED", "Channeled"),
    Fact("cast", "SPELL_ON_NEXT_SWING", "Next melee"),
    Fact("cast", "SPELL_ON_NEXT_RANGED", "Next ranged"),
    Fact("cooldown", "SPELL_RECAST_TIME_SEC", "%.3g sec cooldown", { unit = ns.TEXT.SECONDS }),
    Fact("cooldown", "SPELL_RECAST_TIME_MIN", "%.3g min cooldown", { unit = ns.TEXT.MINUTES }),
    Fact("cooldown", "SPELL_RECAST_TIME_HOURS", "%.3g hrs cooldown", { unit = ns.TEXT.HOURS }),
}

-- What only an English description tells (in another language a spell has no school and no numbers).
local english = {
    -- What a spell is: the school it names first, by the game's numbers of the schools
    -- (2 holy ... 7 arcane, as GetSpellCritChance takes them)
    schools = { [2] = "holy", [3] = "fire", [4] = "nature", [5] = "frost", [6] = "shadow", [7] = "arcane" },
    heals = "heal",     -- no school named, but it heals
    damage = "damage",  -- no school named, but it hurts
    -- No school named, but it takes control of the target: crowd control
    controls = { "%f[%a]stun", "%f[%a]incapacitat", "%f[%a]fear", "%f[%a]polymorph", "%f[%a]sheep", "%f[%a]sleep",
        "%f[%a]root", "%f[%a]immobiliz", "%f[%a]disorient", "%f[%a]horror", "%f[%a]charm", "%f[%a]silenc",
        "%f[%a]banish", "%f[%a]hibernat", "%f[%a]freez", "%f[%a]knock" },
    -- The words between the numbers of a description, in small letters (Numbers.lua). Each is tried
    -- on the words after a number (joint, hurt, spread, repeats), the words after the next one (time)
    -- or the words before it (mend).
    words = {
        joint = "^%s*to%s*$",            -- "16 to 25": one amount, the middle of the two
        time = "^%s*sec",                -- "15 sec": the number is a time
        spread = "over%s*$",             -- "45 damage over 15 sec": all of it, over that time
        repeats = { "each second for%s*$", "every second for%s*$" }, -- "24 ... each second for 3 sec"
        hurt = "damage",                 -- after the number: it hurts
        mend = "%f[%a]heal[^t]",         -- before it: it heals ("heals the target for 40"; not "health")
        -- A description with one of these is about something else than what the spell does itself
        elsewhere = { "weapon", "attack power", "absorb" },
    },
}
ns.STATS = { enUS = english, enGB = english }
