-- Navigation's setup: the setup window on its six pages, the big arrow into the hot corner of the small map's stand-in
-- Core and Onboarding from their TOCs, Navigation's setup alone (Setup.lua), the rest of Navigation standing in: the
-- small map's window in the top right corner with the corner's square Core's Edge would put there. In the console:
-- LabStep(2) goes to a page, LabSet("expandClick", false) changes the switch as the window's round buttons do,
-- LabFull(true) as if the map filled the screen, LabDock("TOPLEFT") docks the stand-in in another corner ("right":
-- along an edge; nil: away from the edges), LabSetup() opens the window again.
Lab.TOC("src/Core/SaneUI.toc")
local Core = SaneUI.Core
local ns = Lab.Addon("SaneUI_Navigation")
Core.NewModule("SaneUI_Navigation", "Navigation", ns)
Lab.TOC("src/Onboarding/SaneUI_Onboarding.toc")

-- The switches the setup shows: the section Expand window, as Navigation has it.
local OPTIONS = {}
Core.Edge.Options(OPTIONS, 1)
Core.Options("Navigation", OPTIONS)

-- What Setup.lua reads of the rest of Navigation.
ns.options = {}
ns.Native = { OWN = "SANEUI_MAP" }
ns.Route = { EDGE = "Interface\\Artifacts\\_Artifacts-DependencyBar-BG",
             FILL = "Interface\\Artifacts\\_Artifacts-DependencyBar-Fill", THICK = 6 }

-- The small map's stand-in in the top right corner, and the edge's spot where it is docked.
local lab = { at = "TOPRIGHT", full = false }
local window, spot
local SIDES = { right = "RIGHT", left = "LEFT", top = "TOP", bottom = "BOTTOM" }
local edge = { strips = {} }
function edge:Spot()
    if not lab.at then return nil end
    local point = SIDES[lab.at] or lab.at
    spot:ClearAllPoints()
    spot:SetPoint(point, UIParent, point, 0, 0)
    spot:SetSize(SIDES[lab.at] and 2 or 4, SIDES[lab.at] and 200 or 4)
    return spot, SIDES[lab.at] and lab.at or "corner", not SIDES[lab.at] and lab.at or nil
end
ns.Window = { handle = { edge = edge } }

Lab.Addon("SaneUI_Navigation", "src/Navigation/Setup.lua")

function LabSetup()
    ns.options = Core.Settings("Navigation") or ns.options
    Core.Onboarding.Open("Navigation", lab.step)
end

function LabStep(index)
    lab.step = index
    SaneUI.Onboarding.Window.Go(index)
end

function LabSet(key, value)
    SaneUI.Onboarding.Window.Set("Navigation", key, value)
end

function LabFull(on)
    edge.full = on and true or false
    SaneUI.Onboarding.Window.Changed()
end

function LabDock(at)
    lab.at = at
    if window then
        local point = at and (SIDES[at] or at) or "CENTER"
        window:ClearAllPoints()
        window:SetPoint(point, UIParent, point, 0, 0)
    end
    SaneUI.Onboarding.Window.Changed()
end

Lab.OnLogin(function()
    window = CreateFrame("Frame", nil, UIParent)
    window:SetSize(200, 200)
    window:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)
    local ground = window:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(window)
    ground:SetColorTexture(0.16, 0.21, 0.13, 1)
    spot = CreateFrame("Frame", nil, window)
    LabSetup()
    LabStep(2)
end)
