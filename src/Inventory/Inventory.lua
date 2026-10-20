local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory
--  The module's own table (ns in all its files), and how it stands down.
--
--  An addon of its own (SaneUI_Inventory): it needs Core and nothing else, and is
--  switched on and off in the game's addon list.
--
--  Everything about what you carry and wear will be here. Its first part is the
--  corner (Corner.lua): the mouse pushed into the screen's bottom right corner
--  opens the game's own bags and character sheet together, and pushed there
--  again closes them. The game's bags and sheet stay as they are, and their keys
--  work as before. What the account's characters have (bags, bank, worn) is kept
--  by Core's data framework (Core.Data.Characters); this module only reads it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Inventory", ns)

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the bottom right corner no longer opens your bags and character; their keys still do"

-- Standing down, the corner goes: the game's bags and sheet are the game's all along.
function ns.GiveBack()
    ns.Corner.Off()
end

function ns.OnLogin()
    ns.Corner.On()
end
