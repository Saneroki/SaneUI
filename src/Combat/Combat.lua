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
--  the bottom edge; full, it holds your talents and your spellbook on Core's
--  board (Board.lua): the game's own window, or the window of a talent planner
--  Sane UI knows (Core.Neighbours) as the Talents panel. Beside a creature's
--  nameplate, a mark while it belongs to an objective still to do (QuestMarks.lua).
--  The game's own frames
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
    -- An empty panel: what opens the window it holds. %s: the game's key for it.
    click = "Click here or press %s to open it here.",
    clickNoKey = "Click here to open it here.",
    fight = "Press %s to open it here. A click here works again after the fight.",
    fightNoKey = "A click here opens it again after the fight.",
    one = "The game shows your talents and your spellbook one at a time.",
    later = "Available at level %d.",
    notYet = "Not available yet.",
    planner = "Closed. Click here to open it again.",
    nameplates = "Nameplates",
    questMarks = "Quest marks on nameplates",
    questMarksTip = "A creature that belongs to a quest in your log shows a small mark beside its nameplate while an objective of it is still to do: a sword to kill it, a sack to loot it, with the count still open. As the game says it in the creature's tooltip.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the bottom edge no longer fills the screen; your talents and spellbook are the game's own again"

local OPTIONS = {
    { key = "questMarks", default = true, text = ns.TEXT.questMarks, header = ns.TEXT.nameplates, tip = ns.TEXT.questMarksTip },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, 1)
-- Core's window takes the section in by itself (Edge.lua); the quest marks are looked at again.
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "questMarks" then ns.Guarded(ns.QuestMarks.Update) end
end })

-- Standing down, what is seated on the full screen is given back and the window goes.
function ns.GiveBack()
    ns.Board.Leave()
    ns.Window.Hide()
    ns.QuestMarks.Hide()
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Window.Build()
    ns.Board.Follow()
    ns.QuestMarks.Start()
end
