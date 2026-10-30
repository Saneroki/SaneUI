-- Inventory: Core and the module Inventory from their TOCs, its full screen with the character, the bags and the alts
-- The lab has no model scene: a plain frame stands in for the character's model. The game's stats come from its own
-- character sheet's own files (Blizzard_UIPanels_Game's stats). The module's table is LabInventory in the console:
-- LabInventory.Board.layouts:Remove("alts") takes a window off, LabInventory.Board.Add("bank") puts one on.
-- Blizzard's item utilities (ItemButtonUtil), which the game's item buttons ask for
Lab.Blizzard("Blizzard_FrameXMLUtil")
-- The game's character sheet's stats: its table of them and the functions that fill and explain each
-- (the files its TOC loads for this client, in its order)
Lab.BlizzardFiles("Blizzard_UIPanels_Game", "Camelot/PaperDollFrameConstants.lua", "Camelot/PaperDollFrame.lua",
    "Vanilla/PaperDollFrameStats.lua", "Cata/PaperDollFrameStats.lua", "Camelot/PaperDollFrameStats.lua")
local create = CreateFrame
CreateFrame = function(kind, ...)
    if kind == "ModelScene" then return create("Frame", ...) end
    return create(kind, ...)
end
GetShapeshiftFormID = GetShapeshiftFormID or function() return nil end
-- The doll's slots: the lab knows the slots by the game's older names
C_PaperDollInfo.GetInventorySlotInfo = GetInventorySlotInfo
C_PaperDollInfo.IsRangedSlotShown = function() return true end
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Inventory/SaneUI_Inventory.toc")
LabInventory = ns
Lab.OnLogin(function()
    if ns and ns.Window then ns.Window.Open("bags") end
    if ns and ns.Board and not ns.Board.Panel("stats") then ns.Board.Add("stats") end
end)
