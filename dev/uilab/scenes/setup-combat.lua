-- Combat's setup: the setup window on its pages, each sample drawn by the module's own code (the party and raid
-- frames' made-up members going through 5, 10, 20 and 40, the nameplates' sample plates). Core, Combat and Onboarding
-- from their TOCs; the game's plates and unit frames are not in the lab, so only the setup's samples show (a plain
-- frame stands in for each of the game's frames ours stand for). In the console: LabStep(3) goes to a page (3: the
-- party and raid frames, 12: the nameplates' spells), LabSet("groupBeside", false) changes a switch as the window's
-- controls do, LabSetup() opens the window again. LabCombat is the module's table.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end -- not in the lab
    return create(kind, name, parent, template, ...)
end
SecureHandlerSetFrameRef = function() end
RegisterUnitWatch, UnregisterUnitWatch = function(frame) frame:Show() end, function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
SecureCmdOptionParse = function() return nil end
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Combat/SaneUI_Combat.toc")
ns.UnitAuras.missing = true -- the lab has no aura containers
Lab.TOC("src/Onboarding/SaneUI_Onboarding.toc")
LabCombat = ns

local lab = { step = 3 }

function LabSetup()
    SaneUI.Core.Onboarding.Open("Combat", lab.step)
end

function LabStep(index)
    lab.step = index
    SaneUI.Onboarding.Window.Go(index)
end

function LabSet(key, value)
    SaneUI.Onboarding.Window.Set("Combat", key, value)
end

Lab.OnLogin(function()
    LabSetup()
    LabStep(lab.step)
end)
