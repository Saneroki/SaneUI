local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Combat): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  Everything about the fight will be here, each part in files of its own:
--  the unit frames (you, your target, its target, your focus, your pet), the
--  party and the raid, your buffs and debuffs, the nameplates, and what goes
--  with them (cast bars, totems, bosses). The plan is Doc/ideas/Combat.md.
--
--  Built so far: its window (Window.lua), docked in the screen's bottom middle
--  and filling the screen when the mouse is pushed against the middle half of
--  the bottom edge; full, it holds your talents and your spellbook side by
--  side (Board.lua): the game's own window, or the window of a talent planner
--  Sane UI knows (Core.Neighbours) as the Talents panel. The game's own frames
--  stay as they are. Each part falls back to the game's own when it fails
--  (Core's StandDown, GiveBack), and only reads what it shows: the game's live
--  data, and Core's data framework for anything kept (Doc/ideas/Data.md).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Combat", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = "Combat",
    talents = Core.Word("TALENTS", "Talents"),
    spellbook = Core.Word("SPELLBOOK", "Spellbook"),
    open = "Open",
    -- An empty panel: what opens it here. %s: the game's key for it, or the words below without one.
    hint = "Not open. %s or the button opens it here.",
    hintKey = "Not open. %s opens it here.",
    hintFight = "Not open. %s opens it here; the button comes back after the fight.",
    hintPlanner = "Closed. The button opens it here again.",
    noKey = "Its key in the game's Keybindings",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the bottom edge no longer fills the screen; your talents and spellbook are the game's own again"

local OPTIONS = {}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, 1)
-- Core's window takes the section in by itself (Edge.lua): nothing more to do here.
Core.Options(ns.name, OPTIONS)

-- Standing down, what is seated on the full screen is given back and the window goes.
function ns.GiveBack()
    ns.Board.Leave()
    ns.Window.Hide()
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Window.Build()
    ns.Board.Follow()
end
