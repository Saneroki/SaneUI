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
--    Sample.lua    a made-up plate drawn by this same code, for the setup
--    Setup.lua     the setup, step by step: its words and sample plates,
--                  handed to Core; the window is the addon Onboarding's
--  Players who may not attack you nor you them and whom you do not know show
--  no plate, nor do critters unless the setting shows them (Plate.lua).
--  The setting Plates show picks what each plate shows (ns.Style,
--  Plate.Style): the bar and the auras around it, the health bar only, or the
--  spells only (no bar, no name; a faint dot and, on your target, an arrow).
--  Standing down, every plate is the game's own again (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Nameplates", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Nameplates",
    style = "Plates show",
    styleTip = "What every nameplate shows. Health bar and spells: the bar with its name and health, your debuffs above it, a foe's buffs left of it, crowd control right of it. Health bar only: the bar without those auras and without the tracked auras under it; its cast bar stays. Spells only: no bar and no name; the auras, the cast bar, the raid marker and your combo points where they stand, and a gold arrow over your target.",
    styleBoth = "Health bar and spells",
    styleBar = "Health bar only",
    styleSpells = "Spells only",
    dot = "Dot where a plate is",
    dotTip = "With Spells only: a small faint dot in the middle of each plate, in the colour its bar would have, so you see there is a plate while it shows no spells. On by itself when you choose Spells only.",
    setup = "Set up step by step",
    setupTip = "A window that walks you through every part of the nameplates, a step at a time, with a sample plate that shows each choice at once. Also /sane setup nameplates.",
    debuffs = "Your debuffs",
    debuffsTip = "Right above a nameplate's bar, from its left: at most this many of the debuffs and damage over time you put on that creature or player, with the time each has left; never more than fit over the bar. 0: none.",
    buffs = "Buffs on foes",
    buffsTip = "Left of the bar of a creature or player you can attack: at most this many of its buffs, as the game picks them for nameplates. 0: none.",
    quest = "Quest progress",
    questTip = "Inside the bar of a creature you have a quest objective for: a sword to kill it or a sack to loot it, and how many of how many.",
    level = "Level",
    levelTip = "Inside the bar, first: the unit's level, in the game's colour for how hard it is for you (a skull where it is too high to tell).",
    gear = "Item level",
    gearTip = "Inside a player's bar, after the level: their item level (\"i32\"), the average level of the gear they wear, once the game has let Sane UI inspect them (out of a fight, near enough).",
    health = "Health",
    healthTip = "At the bar's right end: how much health the unit has, short (850, 1.2k, 1.32m).",
    percent = "Health in percent",
    percentTip = "At the bar's right end, after the health: how much of it is left (100%).",
    control = "Crowd control",
    controlTip = "Right of the bar: at most this many of the stuns, fears, roots and the like on that creature or player, by anyone. 0: none.",
    power = "Power line",
    powerTip = "Along the bottom of each bar, inside it: the unit's mana, rage or energy.",
    resource = "Combo points under the bar",
    resourceTip = "While you have combo points to build (a rogue, a druid in cat form), they show in your target's health bar, on its power line, one segment each.",
    barrier = "Barriers",
    barrierTip = "What absorbs damage on a unit, in the game's shield art on its bar: after the health while it fits, against the bar's right end when it does not.",
    lost = "Lost maximum health",
    lostTip = "Maximum health taken away for a while: the bar's fill ends earlier and the rest of its length is hatched.",
    dispel = "Dispellable auras",
    dispelTip = "What you or your group can take off a friend, or a buff you can remove from a foe: the game's icon of its type, a green drop for poison and so on, above the bar's right end.",
    range = "Out of reach: red border",
    rangeTip = "A foe's border turns red while none of your attacks reach it, as the game checks your own spells from your character.",
    players = "Only players you know",
    playersTip = "Hides the plate of every friendly player who is not in your party, raid or guild and not on your friends list (and their pets'). Your target and anyone you could fight always have one. Off: every player's plate shows. Its key: Show or hide players you don't know.",
    critters = "Plates on critters",
    crittersTip = "Critters, wild pets and companion pets (rabbits, rats, deer and the like) have a nameplate with their name. Off: none, unless one is your target or a quest of yours wants it.",
    distance = "Size by distance",
    distanceTip = "Nameplates by their distance from your character alone: full size within " .. Core.Distance(10) .. ", half at " .. Core.Distance(40) .. ", a quarter at " .. Core.Distance(60) .. "; they fade in softly when they appear. Off: the game's own scaling and fading.",
    castBar = "Cast bar",
    castBarTip = "Under a nameplate's bar: what its unit casts, with the seconds left in the spell's icon and the name of its target. Off: the game's own cast bar.",
    size = "Nameplate size",
    sizeTip = "How large nameplates are within " .. Core.Distance(10) .. ".",
    transparency = "Nameplate transparency",
    transparencyTip = "How much you see through every nameplate but your target's (that one has a slider of its own): 0% solid, 100% off: none shown.",
    targetTransparency = "Your target's transparency",
    targetTransparencyTip = "How much you see through your target's nameplate: 0% solid, 100% off: none shown.",
    combatHeader = "Combat text",
    combatText = "Over nameplates",
    combatTextTip = "What a creature or player takes rises over its nameplate and fades: auto attacks and physical damage in white, spell damage in red, heals in green, critical hits larger; a miss, dodge, parry, block, evade or immunity in words. The game says what a unit took, not from whom: in a group it is everybody's damage.",
    combatSelf = "Over your character",
    combatSelfTip = "The same for what you take, rising from about your character's feet: damage with a minus.",
    combatHeals = "Heals",
    combatHealsTip = "Heals in green with a plus.",
    combatGame = "Instead of the game's",
    combatGameTip = "The game's own combat text is switched off while ours shows: its numbers over units, and its scrolling text about you (with it its notes on entering a fight, low health, reputation and honor). Off: both show.",
    classColour = "Class colours",
    classColourTip = "A player's bar in their class's colour (a mage light blue, a warrior brown). Off: as a creature's, red for a foe, blue for a friend.",
    marker = "Raid markers",
    markerTip = "The raid marker someone of your group put on it (a skull, a star ...), in the bar after its level.",
    castHeight = "Cast bar height",
    castHeightTip = "How high the cast bar under a plate is: 100% as high as the health bar.",
    auraSize = "Spell icon size",
    auraSizeTip = "How large the icons of your debuffs, a foe's buffs and the crowd control are: 100% as high as the health bar.",
    debuffPlace = "Your debuffs: where",
    buffPlace = "Buffs on foes: where",
    controlPlace = "Crowd control: where",
    placeTip = "Where these icons stand: above the bar, at its left or at its right. Two kinds on the same side stand in rows, one above the other.",
    above = "Above",
    left = "Left",
    right = "Right",
    duration = "Time left in the icons",
    durationTip = "The seconds left of a debuff or buff, in its icon. One with more than a minute left shows none, so the number always fits.",
    durationSize = "Time left: size",
    durationSizeTip = "How large the seconds left are: a share of the icon's height.",
    durationTransparency = "Time left: transparency",
    durationTransparencyTip = "How much you see through the seconds left: 0% solid, 100% off: none shown.",
    knownTransparency = "Players you know: transparency",
    knownTransparencyTip = "How much you see through the plates of your party, raid, guild and friends: 0% solid, 100% off: none shown.",
    strangerTransparency = "Players you don't know: transparency",
    strangerTransparencyTip = "How much you see through the plates of friendly players who are not in your party, raid or guild and not on your friends list, while they show (Only players you know off, or its key): 0% solid, 100% off: none shown.",
    critterTransparency = "Critters: transparency",
    critterTransparencyTip = "How much you see through the plates of critters, wild pets and companion pets, while they show: 0% solid, 100% off: none shown.",
    distanceStrength = "Size by distance: how much",
    distanceStrengthTip = "How much smaller plates get far away. 100%: half at " .. Core.Distance(40) .. ", a quarter at " .. Core.Distance(60) .. ". 50%: three quarters at " .. Core.Distance(40) .. ". 0%: all full size.",
    strangersKey = "Show or hide players you don't know",
    strangersShown = "Players you don't know: their plates show",
    strangersHidden = "Players you don't know: their plates are hidden",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the nameplates are the game's own again"

-- What the plates show (the setting Plates show, Saneroki, 2026-11-09): "both" the bar and the auras around it,
-- "bar" the health bar only, "spells" the spells only (no bar, no name).
ns.STYLES = { { "both", ns.TEXT.styleBoth }, { "bar", ns.TEXT.styleBar }, { "spells", ns.TEXT.styleSpells } }

-- How many of each kind of aura show at most (Saneroki, 2026-11-16: "how many buffs, debuffs and CCs they want to
-- see"), each 0 for none: the switches Your debuffs, Buffs on foes and Crowd control were these before.
ns.AURAS = { debuffCount = 8, buffCount = 3, controlCount = 2 }
-- Where each kind stands (Saneroki, 2026-11-16: "choose where the spells are"): above the bar, at its left or right.
ns.PLACES = { { "above", ns.TEXT.above }, { "left", ns.TEXT.left }, { "right", ns.TEXT.right } }

local OPTIONS = {
    -- The setup, step by step (Setup.lua, the window of the addon Onboarding).
    { key = "setup", text = ns.TEXT.setup, tip = ns.TEXT.setupTip,
      button = function() Core.Onboarding.Open(ns.name) end },
    { key = "style", default = "both", choices = ns.STYLES, text = ns.TEXT.style, tip = ns.TEXT.styleTip },
    { key = "dot", default = false, parent = "style", parentValue = "spells", text = ns.TEXT.dot, tip = ns.TEXT.dotTip },
    { key = "classColour", default = true, text = ns.TEXT.classColour, tip = ns.TEXT.classColourTip },
    { key = "quest", default = true, text = ns.TEXT.quest, tip = ns.TEXT.questTip },
    { key = "level", default = true, text = ns.TEXT.level, tip = ns.TEXT.levelTip },
    { key = "gear", default = true, text = ns.TEXT.gear, tip = ns.TEXT.gearTip },
    { key = "health", default = true, text = ns.TEXT.health, tip = ns.TEXT.healthTip },
    { key = "percent", default = true, text = ns.TEXT.percent, tip = ns.TEXT.percentTip },
    { key = "marker", default = true, text = ns.TEXT.marker, tip = ns.TEXT.markerTip },
    { key = "debuffCount", default = ns.AURAS.debuffCount, min = 0, max = 12, step = 1, text = ns.TEXT.debuffs,
      tip = ns.TEXT.debuffsTip },
    { key = "debuffPlace", default = "above", choices = ns.PLACES, text = ns.TEXT.debuffPlace, tip = ns.TEXT.placeTip },
    { key = "buffCount", default = ns.AURAS.buffCount, min = 0, max = 6, step = 1, text = ns.TEXT.buffs,
      tip = ns.TEXT.buffsTip },
    { key = "buffPlace", default = "left", choices = ns.PLACES, text = ns.TEXT.buffPlace, tip = ns.TEXT.placeTip },
    { key = "controlCount", default = ns.AURAS.controlCount, min = 0, max = 4, step = 1, text = ns.TEXT.control,
      tip = ns.TEXT.controlTip },
    { key = "controlPlace", default = "right", choices = ns.PLACES, text = ns.TEXT.controlPlace, tip = ns.TEXT.placeTip },
    { key = "auraSize", default = 100, min = 50, max = 200, step = 10, unit = "%", text = ns.TEXT.auraSize,
      tip = ns.TEXT.auraSizeTip },
    { key = "duration", default = true, text = ns.TEXT.duration, tip = ns.TEXT.durationTip },
    { key = "durationSize", default = 50, min = 30, max = 90, step = 5, unit = "%", parent = "duration",
      text = ns.TEXT.durationSize, tip = ns.TEXT.durationSizeTip },
    { key = "durationTransparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100, parent = "duration",
      text = ns.TEXT.durationTransparency, tip = ns.TEXT.durationTransparencyTip },
    { key = "power", default = true, text = ns.TEXT.power, tip = ns.TEXT.powerTip },
    { key = "resource", default = true, text = ns.TEXT.resource, tip = ns.TEXT.resourceTip },
    { key = "barrier", default = true, text = ns.TEXT.barrier, tip = ns.TEXT.barrierTip },
    { key = "lost", default = true, text = ns.TEXT.lost, tip = ns.TEXT.lostTip },
    { key = "dispel", default = true, text = ns.TEXT.dispel, tip = ns.TEXT.dispelTip },
    { key = "range", default = true, text = ns.TEXT.range, tip = ns.TEXT.rangeTip },
    { key = "players", default = true, text = ns.TEXT.players, tip = ns.TEXT.playersTip },
    { key = "critters", default = false, text = ns.TEXT.critters, tip = ns.TEXT.crittersTip },
    { key = "distance", default = true, text = ns.TEXT.distance, tip = ns.TEXT.distanceTip },
    { key = "distanceStrength", default = 100, min = 0, max = 100, step = 10, unit = "%", parent = "distance",
      text = ns.TEXT.distanceStrength, tip = ns.TEXT.distanceStrengthTip },
    { key = "foundCVars", default = {} }, -- the game's nameplate CVars as they were before ours (Scale.lua)
    { key = "castBar", default = true, text = ns.TEXT.castBar, tip = ns.TEXT.castBarTip },
    { key = "castHeight", default = 100, min = 50, max = 200, step = 10, unit = "%", parent = "castBar",
      text = ns.TEXT.castHeight, tip = ns.TEXT.castHeightTip },
    { key = "plateSize", default = 125, min = 50, max = 300, step = 5, unit = "%", text = ns.TEXT.size, tip = ns.TEXT.sizeTip },
    { key = "transparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100, text = ns.TEXT.transparency, tip = ns.TEXT.transparencyTip },
    { key = "targetTransparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100, text = ns.TEXT.targetTransparency,
      tip = ns.TEXT.targetTransparencyTip },
    { key = "knownTransparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100, text = ns.TEXT.knownTransparency,
      tip = ns.TEXT.knownTransparencyTip },
    { key = "strangerTransparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100,
      text = ns.TEXT.strangerTransparency, tip = ns.TEXT.strangerTransparencyTip },
    { key = "critterTransparency", default = 0, min = 0, max = 100, step = 5, unit = "%", offAt = 100,
      text = ns.TEXT.critterTransparency, tip = ns.TEXT.critterTransparencyTip },
    { key = "combatText", default = true, text = ns.TEXT.combatText, tip = ns.TEXT.combatTextTip, header = ns.TEXT.combatHeader },
    { key = "combatSelf", default = true, text = ns.TEXT.combatSelf, tip = ns.TEXT.combatSelfTip },
    { key = "combatHeals", default = true, text = ns.TEXT.combatHeals, tip = ns.TEXT.combatHealsTip },
    { key = "combatGame", default = true, text = ns.TEXT.combatGame, tip = ns.TEXT.combatGameTip },
    { key = "combatFoundCVars", default = {} }, -- the game's combat text CVars as they were before ours (CombatText.lua)
}
-- What the plates show now (the setting Plates show): "both", "bar" or "spells".
function ns.Style()
    return (ns.options or {}).style or "both"
end

-- A switch changed: what it touches done anew.
local function Apply(key)
    if key == "resource" then
        ns.Guarded(ns.Resource.Update)
    elseif key == "range" then
        ns.Guarded(ns.Range.Look)
    elseif key == "distance" or key == "plateSize" or key == "distanceStrength" then
        ns.Guarded(ns.Scale.Update)
    elseif key == "duration" or key == "durationSize" or key == "durationTransparency" then
        ns.Guarded(ns.Auras.Restyle)
    elseif key == "auraSize" or key == "debuffPlace" or key == "buffPlace" or key == "controlPlace" then
        -- The icons' rows above the bar change how closely the plates stack (Scale.Stacking).
        ns.Guarded(ns.Plate.Refresh)
        ns.Guarded(ns.Scale.Update)
    elseif key == "combatText" or key == "combatSelf" or key == "combatGame" then
        ns.Guarded(ns.CombatText.Update)
    elseif key == "combatHeals" then
        return
    elseif key == "style" then -- what the plates show, and how closely they stack (no auras: closer, Scale.Stacking)
        ns.Guarded(ns.Plate.Refresh)
        ns.Guarded(ns.Scale.Update)
    else
        ns.Guarded(ns.Plate.Refresh)
    end
end

Core.Options(ns.name, OPTIONS, {
    -- 1: the switches Your debuffs, Buffs on foes and Crowd control became how many of each (none: 0).
    version = 1,
    upgrade = function(values, from)
        if from < 1 then
            for old, count in pairs({ debuffs = "debuffCount", buffs = "buffCount", control = "controlCount" }) do
                if values[old] == false then values[count] = 0 end
            end
        end
    end,
    -- Plates show turned to Spells only: the dot where a plate is on with it (Saneroki, 2026-11-09: "automatically on
    -- when the nameplate is changed into only Spells"), and off again by its own switch.
    changed = function(key, value)
        if key == "style" and value == "spells" then Core.Set(ns.name, "dot", true) end
        Apply(key)
    end,
    -- Another profile's settings came in: everything done anew, as each switch would be; none set for another, so the
    -- dot keeps the profile's own value.
    replaced = function()
        for _, key in ipairs({ "resource", "range", "distance", "combatText", "style" }) do Apply(key) end
    end,
})

-- The key Show or hide players you don't know (Bindings.xml): the setting Only players you know turned over, told as
-- the game tells its own plates' keys (UIErrorsFrame, in yellow).
function ns.ToggleStrangers()
    local hidden = Core.Set(ns.name, "players", (ns.options or {}).players == false)
    local words = hidden and ns.TEXT.strangersHidden or ns.TEXT.strangersShown
    local errors, colour = rawget(_G, "UIErrorsFrame"), rawget(_G, "YELLOW_FONT_COLOR")
    if type(errors) == "table" and errors.AddMessage and type(colour) == "table" then
        errors:AddMessage(words, colour.r, colour.g, colour.b)
    else
        Core.Print(words)
    end
end
BINDING_NAME_SANEUI_NAMEPLATES_STRANGERS = ns.TEXT.strangersKey

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
