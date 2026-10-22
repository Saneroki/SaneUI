-- Inventory: Core and the module Inventory from their TOCs, its full screen with the character, the bags and the alts
-- The lab has no model scene: a plain frame stands in for the character's model. The stats window is left out of the
-- first layout (its list is a scroll box the lab cannot lay out yet). The module's table is LabInventory in the
-- console: LabInventory.Board.layouts:Remove("alts") takes a window off, LabInventory.Board.Add("bank") puts one on.
-- Blizzard's item utilities (ItemButtonUtil), which the game's item buttons ask for
Lab.Blizzard("Blizzard_FrameXMLUtil")
local create = CreateFrame
CreateFrame = function(kind, ...)
    if kind == "ModelScene" then return create("Frame", ...) end
    return create(kind, ...)
end
GetShapeshiftFormID = GetShapeshiftFormID or function() return nil end
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Inventory/SaneUI_Inventory.toc")
LabInventory = ns
if ns and ns.Board then ns.Board.FIRST.stats = nil end
Lab.OnLogin(function()
    if ns and ns.Window then ns.Window.Open("bags") end
end)
