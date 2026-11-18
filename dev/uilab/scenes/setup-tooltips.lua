-- Tooltips' setup: the setup window on its one step, your own tooltip as the sample over Forever's loading screen
-- Core, Tooltips and Onboarding from their TOCs; the lab's unit tooltip stands in for the game's, the data it would
-- carry given here. In the console: LabSet("cursor", "always"), LabSet("models", false), LabSet("opacity", 40),
-- LabSet("show", "always") change a switch as the window's controls do; LabSetup() opens the window again.
TooltipDataProcessor = { AllTypes = "ALL", AddTooltipPostCall = function() end }

Lab.TOC("src/Core/SaneUI.toc")
local ns = Lab.TOC("src/Tooltips/SaneUI_Tooltips.toc")
Lab.TOC("src/Onboarding/SaneUI_Onboarding.toc")
LabTooltips = ns

-- What the game has and the lab does not yet: a unit's name by its GUID, its health in percent.
UnitTokenFromGUID = function(guid) if guid == UnitGUID("player") then return "player" end end
UnitHealthPercent = function(unit) return math.floor(UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100 + 0.5) end
CurveConstants = CurveConstants or { ScaleTo100 = 1 }

-- The data the game's tooltip carries for your character, and its lines by number (the lab's tooltip has neither).
local function Data()
    local reader = ns.Setup.reader
    if reader and not reader.labbed then
        reader.labbed = true
        local name = reader:GetName()
        function reader:GetPrimaryTooltipData()
            return { type = Enum.TooltipDataType.Unit, guid = UnitGUID("player"), lines = {} }
        end
        function reader:GetLeftLine(index) return _G[name .. "TextLeft" .. index] end
        function reader:GetRightLine(index) return _G[name .. "TextRight" .. index] end
    end
end

function LabSetup()
    SaneUI.Core.Onboarding.Open("Tooltips")
    Data()
    SaneUI.Onboarding.Window.Changed()
end

function LabSet(key, value)
    SaneUI.Onboarding.Window.Set("Tooltips", key, value)
end

Lab.OnLogin(LabSetup)
