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
--    Text.lua      inside the bar: level and threat, the name, health
--    Resource.lua  your combo points on the power line of your target's bar
--    Auras.lua     your own debuffs above the bar, up to three of a foe's buffs
--                  left of it, crowd control right of it, in the game's own aura
--                  containers (hidden values and all)
--    Marks.lua     the raid marker, right of the bar
--    Scale.lua     plates smaller far away (the game's CVars for it)
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
    control = "Crowd control",
    controlTip = "Right of the bar: stuns, fears, roots and the like on that creature or player, by anyone.",
    power = "Power line",
    powerTip = "Along the bottom of each bar, inside it: the unit's mana, rage or energy.",
    resource = "Combo points in your target's bar",
    resourceTip = "While you have combo points to build (a rogue, a druid in cat form), they show in your target's health bar, on its power line, one segment each.",
    players = "Only players you know",
    playersTip = "Plates of players you cannot attack show only for your group, your guild, your friends and your target. Players you can attack always have one.",
    distance = "Smaller far away",
    distanceTip = "Nameplates shrink the farther their unit is from you.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the nameplates are the game's own again"

local OPTIONS = {
    { key = "debuffs", default = true, text = ns.TEXT.debuffs, tip = ns.TEXT.debuffsTip },
    { key = "buffs", default = true, text = ns.TEXT.buffs, tip = ns.TEXT.buffsTip },
    { key = "control", default = true, text = ns.TEXT.control, tip = ns.TEXT.controlTip },
    { key = "power", default = true, text = ns.TEXT.power, tip = ns.TEXT.powerTip },
    { key = "resource", default = true, text = ns.TEXT.resource, tip = ns.TEXT.resourceTip },
    { key = "players", default = true, text = ns.TEXT.players, tip = ns.TEXT.playersTip },
    { key = "distance", default = true, text = ns.TEXT.distance, tip = ns.TEXT.distanceTip },
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "resource" then
        ns.Guarded(ns.Resource.Update)
    elseif key == "distance" then
        ns.Guarded(ns.Scale.Update)
    else
        ns.Guarded(ns.Plate.Refresh)
    end
end })

-- Standing down: every plate the game's own again, ours out of sight, the game's scaling by distance.
function ns.GiveBack()
    ns.Safe("give back", ns.Scale.GiveBack)
    ns.Plate.GiveBack()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Plate.Start()
    ns.Resource.Start()
    ns.Scale.Start()
end
