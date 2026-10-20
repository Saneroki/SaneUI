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
    bagsList = "List",
    bagsCompact = "Compact",
    bagsFree = "%d free",
    bagsTaken = "%d / %d",
    bagsItems = "%d / %d Items",
    bagsCells = "%d Items",
    bagsShow = "Show Bags",
    bagsBoE = "BoE",
    bagsAllItems = "All Items",
    bagsOneBag = "One Bag",
    bagsEachBag = "Each Bag",
    bagsMain = "Main Bags",
    bagsTab = "Bank Tab %d",
    bagsPinned = "Pinned Items",
    bagsRecent = "Recent Items",
    bagsWeapons = "Weapons / Trinkets",
    bagsSets = "Item Set Gear",
    bagsEnhance = "Gear Enhancements",
    bagsCamp = "Camp Items",
    bagsReagentBag = "Reagent Bag",
    bagsSpecial = "Special Bags",
    bagsArmory = "The Armory",
    bagsPrep = "Adventure Prep",
    bagsCategories = "Categories",
    bagsAddCategory = "Add Category",
    bagsFold = "Fold the sidebar",
    bagsUnfold = "Unfold the sidebar",
    bagsGrid = "Grid",
    bagsGold = "Gold on this account",
    -- The bags' categories (Bags/Categories.lua, Bags/Menus.lua)
    bagsPutInto = "Put Into",
    bagsTakeOut = "Take Out of %s",
    bagsNew = "New Category",
    bagsNewAsk = "Name of the new category:",
    bagsRename = "Rename",
    bagsRenameAsk = "New name for %s:",
    bagsRenameGameAsk = "New name for %s (none: its own again):",
    bagsUp = "Move Up",
    bagsDown = "Move Down",
    bagsGroupWith = "Create Group With",
    bagsAddToGroup = "Add to Group",
    bagsUngroup = "Take Out of %s",
    bagsDisband = "Disband Group",
    bagsHideAll = "Hide in All Items",
    bagsOff = "Switch Off",
    bagsIcon = "Icon",
    bagsClear = "Clear",
    bagsDeleteAsk = "Delete the category %s? Its items go back to their own categories.",
    bagsPinnedTip = "Middle-click an item to pin it here, or to unpin it. Pinned items stay in their own category too.",
    bagsRecentTip = "What came into your bags lately. These items stay in their own category too.",
    bagsDropTip = "Let an item go here to put it into this category.",
    bagsHeadTip = "Right-click: rename, move, group, hide or switch off this category.",
    bagsPlusTip = "Bring an item here to put it in, or click here and then on an item.",
    bagsMarker = "Junk Marker",
    bagsMarkerTip = "Click here, then click items to mark them as junk or unmark them; click here again to stop. An item brought here is marked at once.",
    bagsLevel = "iLvl",
    bagsRequired = "Req",
    bagsBind = "Bind",
    bagsSell = "Sell Price",
    bagsBoP = "BoP",
    bagsBoU = "BoU",
    bagsQuest = "Quest",
    bagsSoulbound = "SB",
    bagsColumns = "Columns",
    bagsMoveLeft = "Move Left",
    bagsMoveRight = "Move Right",
    bagsRound = "Round Icons",
    bagsResetColumns = "Reset Columns",
    bagsSold = "Sold %d junk items for %s.",
    bagsUnsold = "%d junk items could not be sold.",
    -- The bags' dropdown View (Bags/Bags.lua)
    bagsLook = "Display",
    bagsShowPinned = "Show Pinned Items",
    bagsShowRecent = "Show Recent Items",
    bagsHideEmpty = "Hide Empty Categories",
    bagsMerge = "Merge Stacks",
    bagsFirst = "Open With",
    bagsOn = "Switched Off",
    bagsSwitchOn = "Switch On %s",
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
    ns.Recent.Start()
end
