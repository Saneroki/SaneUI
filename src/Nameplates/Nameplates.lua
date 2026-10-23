local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Nameplates): it needs Core and nothing else, and
--  is switched on and off in the game's addon list.
--
--  It starts from the game's own nameplates and keeps them: their size (the
--  game's settings), where they stand and stack, what clicks them, their cast
--  bar and widgets. On each plate the game shows, a frame of ours is laid over
--  the game's health bar (Plate.lua) and stands in for it, for its name, level,
--  auras, classification, threat glow and raid marker, which go out of sight
--  under ours (their alpha, nothing of theirs written):
--    Bar.lua       the health bar, round at both ends (Core's cap masks), its
--                  border by the unit's rank, a ring on your target and focus,
--                  the unit's power along its bottom, a red glow on aggro
--    Text.lua      the line inside the bar: quest, raid marker, level, item
--                  level, threat, name, health; the bar as wide as the line
--    Resource.lua  your combo points on the power line of your target's bar
--    Auras.lua     your own debuffs above the bar, up to three of a foe's buffs
--                  left of it, crowd control right of it, in the game's own aura
--                  containers (hidden values and all)
--    Marks.lua     the raid marker, in the line
--    Range.lua     how far each plate's unit is from your character, whether
--                  your attacks reach it (its border red when not)
--    Scale.lua     every plate's size by that distance alone, moving evenly
--    CombatText.lua  what the unit takes (damage, heals; a miss, a parry, a
--                  block as a drawing) rising over its bar, and over your own
--                  character, in place of the game's own combat text
--  Players you cannot attack and do not know show no plate (Plate.lua).
--  Standing down, every plate is the game's own again (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Nameplates", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Nameplates",
    debuffs = "Your debuffs",
    debuffsTip = "Right above a nameplate's bar, from its left: the debuffs and damage over time you put on that creature or player, with the time each has left.",
    buffs = "Buffs on foes",
    buffsTip = "Left of the bar of a creature or player you can attack: up to three of its buffs, as the game picks them for nameplates.",
    quest = "Quest progress",
    questTip = "Inside the bar of a creature you have a quest objective for: a sword to kill it or a sack to loot it, and how many of how many.",
    gear = "Item level",
    gearTip = "Inside a player's bar, after the level: their item level (\"i32\"), once the game has let Sane UI inspect them (out of a fight, near enough).",
    control = "Crowd control",
    controlTip = "Right of the bar: stuns, fears, roots and the like on that creature or player, by anyone.",
    power = "Power line",
    powerTip = "Along the bottom of each bar, inside it: the unit's mana, rage or energy.",
    resource = "Combo points in your target's bar",
    resourceTip = "While you have combo points to build (a rogue, a druid in cat form), they show in your target's health bar, on its power line, one segment each.",
    range = "Out of reach: red border",
    rangeTip = "A foe's border turns red while none of your attacks reach it, as the game checks your own spells from your character.",
    players = "Only players you know",
    playersTip = "Plates of players you cannot attack show only for your group, your guild, your friends and your target. Players you can attack always have one.",
    distance = "Size by distance",
    distanceTip = "Nameplates by their distance from your character alone: full size within 10 yards, half at 40, a quarter at 60; they grow in when they appear. Off: the game's own scaling and fading.",
    castBar = "Cast bar",
    castBarTip = "Under a nameplate's bar: what its unit casts, with the seconds left in the spell's icon and the name of its target. Off: the game's own cast bar.",
    size = "Nameplate size",
    sizeTip = "How large nameplates are within 10 yards.",
    combatHeader = "Combat text",
    combatText = "Over nameplates",
    combatTextTip = "What a creature or player takes rises over its nameplate and fades: auto attacks and physical damage in white, spell damage in red, heals in green, critical hits larger; a miss, dodge, parry, block, evade or immunity as a drawing. The game says what a unit took, not from whom: in a group it is everybody's damage.",
    combatSelf = "Over your character",
    combatSelfTip = "The same for what you take, rising from about your character's feet: damage with a minus.",
    combatHeals = "Heals",
    combatHealsTip = "Heals in green with a plus.",
    combatPictures = "Drawings for what did no harm",
    combatPicturesTip = "A miss, dodge, parry, block, evade or immunity as a pencil drawing. Off: as the game's word (\"Miss\", \"Dodge\", ...).",
    combatGame = "Instead of the game's",
    combatGameTip = "The game's own combat text is switched off while ours shows: its numbers over units, and its scrolling text about you (with it its notes on entering a fight, low health, reputation and honor). Off: both show.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the nameplates are the game's own again"

local OPTIONS = {
    { key = "debuffs", default = true, text = ns.TEXT.debuffs, tip = ns.TEXT.debuffsTip },
    { key = "buffs", default = true, text = ns.TEXT.buffs, tip = ns.TEXT.buffsTip },
    { key = "quest", default = true, text = ns.TEXT.quest, tip = ns.TEXT.questTip },
    { key = "gear", default = true, text = ns.TEXT.gear, tip = ns.TEXT.gearTip },
    { key = "control", default = true, text = ns.TEXT.control, tip = ns.TEXT.controlTip },
    { key = "power", default = true, text = ns.TEXT.power, tip = ns.TEXT.powerTip },
    { key = "resource", default = true, text = ns.TEXT.resource, tip = ns.TEXT.resourceTip },
    { key = "range", default = true, text = ns.TEXT.range, tip = ns.TEXT.rangeTip },
    { key = "players", default = true, text = ns.TEXT.players, tip = ns.TEXT.playersTip },
    { key = "distance", default = true, text = ns.TEXT.distance, tip = ns.TEXT.distanceTip },
    { key = "foundCVars", default = {} }, -- the game's nameplate CVars as they were before ours (Scale.lua)
    { key = "castBar", default = true, text = ns.TEXT.castBar, tip = ns.TEXT.castBarTip },
    { key = "plateSize", default = 125, min = 50, max = 300, step = 5, unit = "%", text = ns.TEXT.size, tip = ns.TEXT.sizeTip },
    { key = "combatText", default = true, text = ns.TEXT.combatText, tip = ns.TEXT.combatTextTip, header = ns.TEXT.combatHeader },
    { key = "combatSelf", default = true, text = ns.TEXT.combatSelf, tip = ns.TEXT.combatSelfTip },
    { key = "combatHeals", default = true, text = ns.TEXT.combatHeals, tip = ns.TEXT.combatHealsTip },
    { key = "combatPictures", default = true, text = ns.TEXT.combatPictures, tip = ns.TEXT.combatPicturesTip },
    { key = "combatGame", default = true, text = ns.TEXT.combatGame, tip = ns.TEXT.combatGameTip },
    { key = "combatFoundCVars", default = {} }, -- the game's combat text CVars as they were before ours (CombatText.lua)
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "resource" then
        ns.Guarded(ns.Resource.Update)
    elseif key == "range" then
        ns.Guarded(ns.Range.Look)
    elseif key == "distance" or key == "plateSize" then
        ns.Guarded(ns.Scale.Update)
    elseif key == "combatText" or key == "combatSelf" or key == "combatGame" then
        ns.Guarded(ns.CombatText.Update)
    elseif key == "combatHeals" or key == "combatPictures" then
        return
    else
        ns.Guarded(ns.Plate.Refresh)
    end
end })

-- Standing down: every plate the game's own again, ours out of sight, the game's scaling by distance.
function ns.GiveBack()
    ns.Safe("give back", ns.Scale.GiveBack)
    ns.Safe("give back", ns.CombatText.GiveBack)
    ns.Plate.GiveBack()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

-- The game is about to write its settings: its nameplate CVars as they were before ours (Scale.lua).
function ns.OnLogout()
    ns.Safe("logout", ns.CombatText.Logout)
    ns.Safe("logout", ns.Scale.Logout)
end

function ns.OnLogin()
    ns.Plate.Start()
    ns.Resource.Start()
    ns.Range.Start()
    ns.Scale.Start()
    ns.CombatText.Start()
end
