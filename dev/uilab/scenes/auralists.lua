-- Edit tracked: Core and the module Combat from their TOCs with Core's real spell sets, the window with marks, three reminders
-- (Rejuvenation twice: on the party and raid frames, its copy chosen, on the nameplates while a druid is in your group) and
-- a search typed
-- The sets are the built ones (BUILD/SaneUI/Sets: dev/build makes them). In the console: LabSearch("rejuv") types into
-- the search box, LabSearch() empties it; LabCombat is the module's table.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer", "PartyFrame", "CompactRaidFrameContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
    if template == "SecureGroupHeaderTemplate" then template = nil end -- not in the lab; the group frames are off here
    return create(kind, name, parent, template, ...)
end
IsInGroup, IsInRaid = function() return false end, function() return false end
RegisterUnitWatch = function(frame) frame:Show() end
UnregisterUnitWatch = function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
SecureHandlerSetFrameRef = function() end
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

Lab.TOC("src/Core/SaneUI.toc")
Lab.Addon("SaneUI_LabSets", "BUILD/SaneUI/Sets/Classes.lua", "BUILD/SaneUI/Sets/SkillLines.lua",
          "BUILD/SaneUI/Sets/Spells.lua", "BUILD/SaneUI/Sets/CreatureSpells.lua", "BUILD/SaneUI/Sets/Auras.lua")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
LabCombat.UnitAuras.missing = true -- the lab has no aura containers
SaneUI.Core.HealthMarks.missing = true

function LabSearch(text)
    LabCombat.AuraLists.Open(text or "")
end

Lab.OnLogin(function()
    local Lists = LabCombat.AuraLists
    Lists.Put("white", { id = 774, name = "Rejuvenation" })
    Lists.Put("show", { id = 774, name = "Rejuvenation" })
    Lists.Put("show", { id = 8936, name = "Regrowth" })
    Lists.Put("black", { id = 430, name = "Drink" })
    Lists.Put("hide", { id = 430, name = "Drink" })
    Lists.Put("hidden", { id = 1126, name = "Mark of the Wild" })
    Lists.Put("white", { id = 7386, name = "Sunder Armor" })
    local Reminders = LabCombat.Reminders
    Reminders.Make({ id = 1126, name = "Mark of the Wild", icon = 136078, harmful = false, unit = "player" })
    local rejuvenation = Reminders.Make({ id = 774, name = "Rejuvenation", icon = 136081, harmful = false, unit = "player" })
    rejuvenation.bar, rejuvenation.own = Reminders.GROUP, true
    local again = Reminders.Copy(rejuvenation)
    again.bar, again.class = Reminders.PLATES, "DRUID"
    Lists.Open(nil, "Rejuvenation")
    LabSearch("re")
end)
