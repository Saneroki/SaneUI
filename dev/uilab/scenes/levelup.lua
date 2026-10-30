-- Level up: a new level in the middle of the screen, the stats it brought and how long the level before took
-- Core and the module Inventory from their TOCs, as in the scene inventory. It stays up here (LevelUp.HOLD); the module's
-- table is LabLevelUp in the console: LabLevel(23, 1, 3) says another level, with so much Strength and Stamina.
Lab.Blizzard("Blizzard_FrameXMLUtil")
Lab.BlizzardFiles("Blizzard_UIPanels_Game", "Camelot/PaperDollFrameConstants.lua", "Camelot/PaperDollFrame.lua",
    "Vanilla/PaperDollFrameStats.lua", "Cata/PaperDollFrameStats.lua", "Camelot/PaperDollFrameStats.lua")
local create = CreateFrame
CreateFrame = function(kind, ...)
    if kind == "ModelScene" then return create("Frame", ...) end
    return create(kind, ...)
end
GetShapeshiftFormID = GetShapeshiftFormID or function() return nil end
C_PaperDollInfo.GetInventorySlotInfo = GetInventorySlotInfo
C_PaperDollInfo.IsRangedSlotShown = function() return true end
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Inventory/SaneUI_Inventory.toc")
LabLevelUp = ns

-- The world behind: a screenshot of the game's (a local picture, assets/generated/ui-lab/backdrops/, not in the
-- repository; without it a magenta box: choose the backdrop dark).
local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
local picture = world:CreateTexture(nil, "BACKGROUND")
picture:SetAllPoints(world)
picture:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

function LabLevel(level, strength, stamina)
    local Core, TEXT = SaneUI.Core, ns.TEXT
    local lines = {}
    if strength then lines[#lines + 1] = TEXT.levelStat:format(Core.StatWord("Strength"), strength) end
    if stamina then lines[#lines + 1] = TEXT.levelStat:format(Core.StatWord("Stamina"), stamina) end
    ns.LevelUp.Show(level, lines, ns.LevelUp.Took(7 * 3600))
end

Lab.OnLogin(function()
    ns.LevelUp.HOLD = 3600
    LabLevel(22, 2, 1)
end)
