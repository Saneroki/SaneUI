-- Party and raid frames: Core and the module Combat from their TOCs, Edit Mode open with the frame's preview of made-up units
-- The game's secure group headers are not in the lab, so this is Edit Mode's preview, the same faces as the live ones.
-- The module's table is LabCombat in the console: LabPreview(40) shows that many, LabSize(600, 160, 120) sets the max
-- width, max height and max unit width, LabChoose() opens its dialog as a click on it does.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
-- The lab hides what lies beyond a mask's rectangle, where the game's CLAMPTOWHITE shows it: masks without a picture,
-- so the bars are seen (square at their ends).
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end
    local frame = create(kind, name, parent, template, ...)
    local mask = frame.CreateMaskTexture
    frame.CreateMaskTexture = function(self, ...)
        local made = mask(self, ...)
        made.SetTexture = function() end
        return made
    end
    return frame
end
IsInGroup, IsInRaid = function() return false end, function() return false end -- no headers: see above
RegisterUnitWatch = function(frame) frame:Show() end
UnregisterUnitWatch = function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
RegisterAttributeDriver, UnregisterAttributeDriver = function() end, function() end
SecureHandlerSetFrameRef = function() end
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

Lab.TOC("src/Core/SaneUI.toc")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
LabCombat.UnitAuras.missing = true -- the lab has no aura containers
SaneUI.Core.HealthMarks.missing = true

function LabPreview(count)
    SaneUI.Core.Set("Combat", "groupPreview", count)
end
function LabSize(width, height, unit)
    SaneUI.Core.Set("Combat", "groupWidth", width)
    SaneUI.Core.Set("Combat", "groupHeight", height)
    SaneUI.Core.Set("Combat", "groupUnitWidth", unit)
end
-- The frame chosen, as a click on its box in Edit Mode: the dialog with its settings.
function LabChoose()
    for _, window in ipairs(SaneUI.Core.Window.All()) do
        if window.options.key == "groupPlace" then SaneUI.Core.Selection.Select(window) end
    end
end
Lab.OnLogin(function()
    EventRegistry:TriggerEvent("EditMode.Enter")
    LabPreview(40)
end)
