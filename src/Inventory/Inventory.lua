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
    -- The bags (Bags/)
    bags = Core.Word("HUD_EDIT_MODE_BAGS_LABEL", "Bags"),
    bagsView = Core.Word("VIEW", "View"),
    bagsOrder = Core.Word("RAID_FRAME_SORT_LABEL", "Sort By"),
    bagsSlots = Core.Word("ALL", "All"),
    bagsGroups = Core.Word("CATEGORIES", "Categories"),
    bagsList = "List",
    bagsCompact = "Compact",
    bagsFree = "%d free",
    bagsGold = "Gold on this account",
    -- The bags' groups (Bags/Groups.lua, Bags/Menus.lua)
    bagsPinned = "Pinned",
    bagsGroup = "Group",
    bagsGroupsMenu = "Groups",
    bagsPutInto = "Put Into",
    bagsTakeOut = "Take Out of %s",
    bagsNew = "New Group",
    bagsNewAsk = "Name of the new group:",
    bagsRename = "Rename",
    bagsRenameAsk = "New name for %s:",
    bagsRenameGameAsk = "New name for %s (none: its own again):",
    bagsUp = "Move Up",
    bagsDown = "Move Down",
    bagsJoin = "Join With",
    bagsJoined = "Joined Here",
    bagsApart = "Show %s by Itself",
    bagsDeleteAsk = "Delete the group %s? Its items go back to their own groups.",
    bagsDropTip = "Let an item go here to put it into this group.",
    bagsHeadTip = "Right-click: rename, move, join or hide this group.",
    bagsItemTip = "Alt and right-click an item: pin it, mark it as junk, put it into a group.",
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
