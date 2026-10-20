local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_Inventory): it needs Core and nothing else, and is
--  switched on and off in the game's addon list. The plan is Doc/ideas/Inventory.md.
--
--  What you carry and wear. Its window (Window.lua) is docked in the screen's
--  bottom right corner: the mouse pushed into that corner fills the screen with
--  the module's windows on Core's board (Board.lua); pushed there again, or Esc,
--  they go. Each window is a part in files of its own that registers itself
--  with the board (Board.Part): the character sheet, the bags, the other
--  characters. The game's own sheet and bags stay as they are, and their keys
--  open them as before. What the account's characters have (bags, bank, worn)
--  is kept by Core's data framework (Core.Data.Characters); this module only
--  reads it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Inventory", ns)

-- Every word the module shows; the game's own where it has one.
ns.TEXT = {
    title = Core.Word("INVENTORY_TOOLTIP", "Inventory"),
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the bottom right corner no longer fills the screen with your inventory"

local OPTIONS = {}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, 1)
-- Core's window takes the section in by itself (Edge.lua): nothing more to do here.
Core.Options(ns.name, OPTIONS)

-- Standing down, the full screen's windows go and the window with them.
function ns.GiveBack()
    ns.Board.Hide()
    ns.Window.Hide()
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Window.Build()
end
