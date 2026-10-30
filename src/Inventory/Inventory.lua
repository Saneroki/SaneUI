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
    bagsWeapons = "Weapons",
    bagsRings = "Rings",
    bagsTrinkets = "Trinkets",
    bagsOtherGear = "Shirts, Tabards & Other Gear",
    bagsSets = "Item Set Gear",
    bagsPotions = "Potions",
    bagsBuffs = "Buffs",
    bagsCamp = "Camp Items",
    bagsFood = "Food",
    bagsReagentBag = "Reagent Bag",
    bagsSpecial = "Special Bags",
    bagsArmory = "The Armory",
    bagsPrep = Core.Word("AUCTION_CATEGORY_CONSUMABLES", "Consumables"),
    bagsCategories = "Categories",
    sideFold = "Fold the Sidebar",
    bagsTrash = "Destroy Item",
    bagsTrashTip = "Let an item go here to destroy it. The game asks first, as when you drop it into the world.",
    bagsGroupFold = "Fold Its Categories Into It",
    bagsGroupUnfold = "List Its Categories",
    bagsGroupDivide = "Divide Into Its Categories in All Items",
    bagsGroupWhole = "Show Whole in All Items",
    sideUnfold = "Unfold the Sidebar",
    bagsAddCategory = "Add Category",
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
    bagsKeys = "Bag Keys Open Our Bags",
    bagsKeysTip = "Your bag keys and the game's bag buttons open the Inventory full screen with our bags; the game's bags stay closed (the dropdown Classic windows still opens them).",
    bagsFirstTip = "The view the bags open with: every item by category, every slot of your bags together, or each bag by itself.",
    bagsShowPinnedTip = "Pinned Items at the top of the bags: the items you pinned with a middle click.",
    bagsPinnedOne = "Pinned in One Bag and Each Bag",
    bagsPinnedOneTip = "Pinned Items also above the bags as they are.",
    bagsShowRecentTip = "Recent Items at the top of the bags: what came into them lately.",
    bagsRecentOne = "Recent in One Bag and Each Bag",
    bagsRecentOneTip = "Recent Items also above the bags as they are.",
    bagsShowAdd = "Show Add Category",
    bagsShowAddTip = "Add Category at the foot of the sidebar, to make a category of your own.",
    bagsMergeTip = "Stacks of one item show as one with their count added up (never gear; not at a vendor, the bank, the mail, a trade or the auction house).",
    bagsMarkerOptionTip = "The category Junk and the coin on the bar that marks junk by clicks. Off: grey items stay in their categories.",
    bagsSplitter = "Stack Splitter Everywhere",
    bagsSplitterTip = "Shift and a click on a stack opens our splitter in every view (in the views without empty slots it always does).",
    bagsItemLevel = "Show Item Level",
    bagsItemLevelTip = "The item level of gear at the top left of its square.",
    bagsShowBind = "Show BoE",
    bagsShowBindTip = "BoE at the bottom left of gear that binds when equipped and is not bound yet.",
    bagsSetName = "Show Set Name",
    bagsSetNameTip = "The name of the equipment set an item is in, at the bottom of its square.",
    bagsCoin = "Coin on Junk",
    bagsCoinTip = "The game's coin at the corner of every junk item.",
    bagsGrey = "Grey Junk",
    bagsGreyTip = "Junk items shown in grey.",
    bankTabs = "All Bank Tabs",
    bankOne = "One Bank",
    bankTabsHead = "Tabs",
    bankGroup = "Group by Category",
    bankBuy = "Buy Tab",
    bankBuyTip = "Click to buy another tab; the game asks first.",
    bankRenameAsk = "New name for the tab %s:",
    bankTabTip = "Right-click: its name and what it takes.",
    bagsSort = "Sort Bags",
    bagsSortTip = "Moves your items into the order of the categories, and inside each by Sort By: pinned items first, partial stacks joined, the empty slots last. Not in a fight; the reagent bag, the keyring and bags for one kind of item stay as they are.",
    bagsSorting = "Sorting your bags...",
    bagsSplit = "Split Stack",
    bagsSplitOne = "Split",
    bagsSplitAll = "Auto Split",
    bagsSold = "Junk sold: %d for %s.",
    bagsUnsold = "%d junk items could not be sold.",
    bagsRepaired = "Repaired for %s.",
    bagsAutoSell = "Auto Sell",
    bagsAutoSellTip = "At a vendor your junk is sold as the window opens, what you marked as junk too. Hold Shift to leave it to you.",
    bagsAutoRepair = "Auto Repair",
    bagsAutoRepairTip = "At a vendor who repairs, your gear is mended as the window opens, after the junk is sold, with your own gold if you have enough. Hold Shift to leave it to you.",
    bagsMakeRoom = "Make Room",
    bagsMakeRoomTip = "One slot of your bags stays free: when the last one fills, your cheapest junk is destroyed at your next key press, and the chat says what went. With no junk to destroy, a warning comes up on the screen. It is the switch Make room for loot of the module Loot.",
    bagsRoomGone = "Destroyed %s to keep a slot free.",
    bagsRoomNone = "Your bags are full, and there is no junk to destroy.",
    bagsSpeedLeveling = "Speed Leveling",
    bagsSpeedLevelingTip = "On: this character uses the profile Speedleveling, with all of Speed Leveling's automation. Off: it goes back to the profile it used before, Accountwide if it had no other.",
    noAsk = "Equip and delete without asking",
    noAskTip = "The game no longer asks before gear binds to you or loses its refund, or before an item is destroyed, whatever its quality: the moment you drop it, it is gone. Where the game keeps destroying for a click of your own, its question comes up with the word it wants already typed in.",
    -- A new level, in the middle of the screen (LevelUp.lua)
    levelHeader = "Level Up",
    levelToast = "Level-up Toast",
    levelToastTip = "At a new level: the level, the stats it brought and how long you played on the level before, in the middle of the screen, in place of the game's toast and its lines in the chat. Off: the game's own.",
    levelTitle = "Level %d!",
    levelStat = "%s |cff6fe06f+%d|r",
    levelTook = "Leveled %s",
    -- The bags' dropdown View (Bags/Bags.lua)
    bagsLook = "Display",
    bagsShowPinned = "Show Pinned Items",
    bagsShowRecent = "Show Recent Items",
    bagsMerge = "Merge Stacks",
    bagsItemSize = "Item Size",
    bagsFirst = "Open With",
    bagsOn = "Switched Off",
    bagsSwitchOn = "Switch On %s",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the bottom right corner no longer fills the screen with your inventory; the bag keys open the game's bags; a new level is told by the game again"

-- The bags' settings (Bags/): what they show, how items look on them.
local OPENS = { { "all", ns.TEXT.bagsAllItems }, { "one", ns.TEXT.bagsOneBag }, { "each", ns.TEXT.bagsEachBag } }
local OPTIONS = {
    { key = "first", default = "all", choices = OPENS, text = ns.TEXT.bagsFirst, tip = ns.TEXT.bagsFirstTip,
      header = ns.TEXT.bags },
    { key = "bagKeys", default = true, text = ns.TEXT.bagsKeys, tip = ns.TEXT.bagsKeysTip },
    { key = "bags", default = {} }, -- the bags' display, order, categories and columns (Bags.lua), each profile its own
    { key = "autoSell", default = true, text = ns.TEXT.bagsAutoSell, tip = ns.TEXT.bagsAutoSellTip },
    { key = "autoRepair", default = true, text = ns.TEXT.bagsAutoRepair, tip = ns.TEXT.bagsAutoRepairTip },
    { key = "showPinned", default = true, text = ns.TEXT.bagsShowPinned, tip = ns.TEXT.bagsShowPinnedTip },
    { key = "noAsk", default = true, text = ns.TEXT.noAsk, tip = ns.TEXT.noAskTip },
    { key = "deleteRefused", default = false }, -- the game refused to destroy an item without its question (Asks.lua)
    { key = "pinnedOne", default = true, text = ns.TEXT.bagsPinnedOne, tip = ns.TEXT.bagsPinnedOneTip },
    { key = "showRecent", default = true, text = ns.TEXT.bagsShowRecent, tip = ns.TEXT.bagsShowRecentTip },
    { key = "recentOne", default = false, text = ns.TEXT.bagsRecentOne, tip = ns.TEXT.bagsRecentOneTip },
    { key = "addCategory", default = true, text = ns.TEXT.bagsShowAdd, tip = ns.TEXT.bagsShowAddTip },
    { key = "merge", default = true, text = ns.TEXT.bagsMerge, tip = ns.TEXT.bagsMergeTip },
    { key = "marker", default = true, text = ns.TEXT.bagsMarker, tip = ns.TEXT.bagsMarkerOptionTip },
    { key = "splitter", default = false, text = ns.TEXT.bagsSplitter, tip = ns.TEXT.bagsSplitterTip },
    { key = "itemLevel", default = true, text = ns.TEXT.bagsItemLevel, tip = ns.TEXT.bagsItemLevelTip },
    { key = "bind", default = false, text = ns.TEXT.bagsShowBind, tip = ns.TEXT.bagsShowBindTip },
    { key = "setName", default = false, text = ns.TEXT.bagsSetName, tip = ns.TEXT.bagsSetNameTip },
    { key = "coin", default = false, text = ns.TEXT.bagsCoin, tip = ns.TEXT.bagsCoinTip },
    { key = "grey", default = false, text = ns.TEXT.bagsGrey, tip = ns.TEXT.bagsGreyTip },
    { key = "levelToast", default = true, text = ns.TEXT.levelToast, tip = ns.TEXT.levelToastTip, header = ns.TEXT.levelHeader },
}
-- The sections Expand window and Window corners, as Core has them for every window (Edge.lua, Shape.lua).
Core.Edge.Options(OPTIONS, 1)
-- Core's window takes the section Expand window in by itself (Edge.lua); without Can expand to fullscreen the bag
-- keys are the game's again (Keys.Taken); Auto Sell and Auto Repair change only their boxes; a bags' setting draws
-- the bags anew.
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "bagKeys" or key == "expand" then return ns.Guarded(ns.Keys.Apply) end
    if Core.Edge.KEYS[key] then return end
    if key == "autoSell" or key == "autoRepair" then return ns.Guarded(ns.Vendor.Refresh) end
    if key == "bags" then return ns.Guarded(ns.Bags.Reload) end
    if key == "levelToast" then return ns.Guarded(ns.LevelUp.Apply) end
    if ns.Bags then ns.Guarded(ns.Bags.Settled) end
    if ns.Alts then ns.Guarded(ns.Alts.Changed) end
end })

-- Standing down, the game's bag keys and bag windows are the game's again first, then the full screen's windows go
-- and the window with them; each step by itself, so one that fails keeps none of the others from it.
function ns.GiveBack()
    ns.Safe("giving back", ns.Keys.Leave)
    ns.Safe("giving back", ns.Board.Hide)
    ns.Safe("giving back", ns.Window.Hide)
    ns.Safe("giving back", ns.LevelUp.GiveBack)
end

function ns.OnLoad()
    ns.store, ns.options = Core.Store(ns.name), Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Window.Build()
    ns.Recent.Start()
    ns.Bank.Start()
    ns.Vendor.Start()
    ns.Weights.Start()
    ns.LevelUp.Start()
    ns.Keys.Start()
    ns.Asks.Start()
    ns.Room.Start()
end
