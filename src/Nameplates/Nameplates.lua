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
--  bar, threat glow and widgets. On each plate the game shows, a frame of ours
--  is laid over the game's health bar (Plate.lua) and stands in for it, for
--  its name, its auras, its classification and its raid marker, which go out
--  of sight under ours (their alpha, nothing of theirs written):
--    Bar.lua       the health bar, round at both ends (Core's cap masks), in the
--                  game's colours, its border lit on your target and your focus
--    Resource.lua  your combo points along the bottom of your target's bar
--    Auras.lua     your own debuffs and up to three of a foe's buffs, above the
--                  name, in the game's own aura containers (hidden values and all)
--    Marks.lua     the mark on rares and the raid marker, right of the bar
--  Standing down, every plate is the game's own again (GiveBack).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Nameplates", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Nameplates",
    debuffs = "Your debuffs",
    debuffsTip = "Above a nameplate, from its left: the debuffs you put on that creature or player, with the time each has left.",
    buffs = "Buffs on foes",
    buffsTip = "Above the nameplate of a creature or player you can attack, from its right: up to three of its buffs, as the game picks them for nameplates.",
    resource = "Combo points in your target's bar",
    resourceTip = "While you have combo points to build (a rogue, a druid in cat form), they show along the bottom of your target's health bar, one segment each.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the nameplates are the game's own again"

local OPTIONS = {
    { key = "debuffs", default = true, text = ns.TEXT.debuffs, tip = ns.TEXT.debuffsTip },
    { key = "buffs", default = true, text = ns.TEXT.buffs, tip = ns.TEXT.buffsTip },
    { key = "resource", default = true, text = ns.TEXT.resource, tip = ns.TEXT.resourceTip },
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "resource" then ns.Guarded(ns.Resource.Update) else ns.Guarded(ns.Plate.Refresh) end
end })

-- Standing down: every plate the game's own again, ours out of sight.
function ns.GiveBack()
    ns.Plate.GiveBack()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Plate.Start()
    ns.Resource.Start()
end
