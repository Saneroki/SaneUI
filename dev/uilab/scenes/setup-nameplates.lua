-- Nameplates' setup: the setup window on its twelve pages, the sample plates of each drawn by the module's own code
-- Core, Nameplates and Onboarding from their TOCs; the game's plates are not in the lab, so only the setup's samples
-- show. In the console: LabStep(10) goes to a page (10: Spells on it), LabSet("controlPlace", "bottom") changes a
-- switch as the window's controls do, LabSetup() opens the window again.
Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Nameplates/SaneUI_Nameplates.toc")
Lab.TOC("src/Onboarding/SaneUI_Onboarding.toc")
LabNameplates = ns

local lab = { step = 10 }

function LabSetup()
    SaneUI.Core.Onboarding.Open("Nameplates", lab.step)
end

function LabStep(index)
    lab.step = index
    SaneUI.Onboarding.Window.Go(index)
end

function LabSet(key, value)
    SaneUI.Onboarding.Window.Set("Nameplates", key, value)
end

Lab.OnLogin(function()
    LabSetup()
    LabStep(lab.step)
end)
