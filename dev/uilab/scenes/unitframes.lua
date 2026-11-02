-- Unit frames: Core and the module Combat from their TOCs, your frame, your target's and your focus's with their casts, your timers and your pet
-- The game's frames ours stand for are not loaded in the lab: a plain frame stands in for each. A cast runs over and
-- over on you and your target, your three timers stand still, by the game's functions standing in. The module's table
-- is LabCombat in the console: LabCast("Fireball") casts, LabCast() stops; Lab.Fire("MIRROR_TIMER_STOP", "BREATH") ends
-- the breath, "EXHAUSTION" the fatigue, "FEIGNDEATH" the feign death.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
-- The lab takes a status bar's atlas for a file: here the atlas on its fill.
local create = CreateFrame
CreateFrame = function(kind, ...)
    local frame = create(kind, ...)
    local fill = frame.SetStatusBarTexture
    if kind == "StatusBar" then
        frame.SetStatusBarTexture = function(self, asset)
            local art = type(asset) == "string" and asset:find("^ui%-")
            fill(self, art and "Interface\\Buttons\\WHITE8X8" or asset)
            if art then self:GetStatusBarTexture():SetAtlas(asset) end
        end
    end
    return frame
end
RegisterUnitWatch = function(frame) frame:Show() end
UnregisterUnitWatch = function() end
RegisterStateDriver, UnregisterStateDriver = function() end, function() end
SecureHandlerSetFrameRef = function() end
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

local cast -- { name, icon, starts, ends }
UnitCastingInfo = function(unit)
    if cast and unit == "player" then return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, "cast-1", false, 133 end
    if cast and unit == "target" then return "Shadow Bolt", "", 136197, cast.starts, cast.ends, false, "cast-2", true, 686 end
end
UnitChannelInfo = function() end

function LabCast(name, seconds)
    local now = GetTime() * 1000
    cast = name and { name = name, icon = 135812, starts = now, ends = now + (seconds or 3) * 1000 } or nil
    Lab.Fire(cast and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_STOP", "player", "cast-1", 133)
    Lab.Fire(cast and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_STOP", "target", "cast-2", 686)
end

local timers = { { "BREATH", 42000, 60000, -1, 0, "Breath" }, { "EXHAUSTION", 25000, 60000, -1, 0, "Fatigue" },
                 { "FEIGNDEATH", 200000, 360000, -1, 0, "Feign Death" } }
GetMirrorTimerInfo = function(index)
    if timers[index] then return unpack(timers[index]) end
    return "UNKNOWN", 0, 0, 0, 0, ""
end
GetMirrorTimerProgress = function(timer)
    for _, one in ipairs(timers) do
        if one[1] == timer then return one[2] end
    end
    return 0
end

-- Your pet, with a resource of its own.
local powerType, powerMost, power, unitName, exists = UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitExists
local health, healthMost = UnitHealth, UnitHealthMax
UnitExists = function(unit) return unit == "pet" or exists(unit) end
UnitHealth = function(unit, ...) if unit == "pet" then return 800 end return health(unit, ...) end
UnitHealthMax = function(unit, ...) if unit == "pet" then return 1000 end return healthMost(unit, ...) end
UnitPowerType = function(unit) if unit == "pet" then return 2, "FOCUS" end return powerType(unit) end
UnitPowerMax = function(unit, ...) if unit == "pet" then return 100 end return powerMost(unit, ...) end
UnitPower = function(unit, ...) if unit == "pet" then return 65 end return power(unit, ...) end
UnitName = function(unit) if unit == "pet" then return "Wolf" end return unitName(unit) end

Lab.TOC("src/Core/SaneUI.toc")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
LabCombat.UnitAuras.missing = true -- the lab has no aura containers: the frames do without, as in a client without them
Lab.OnLogin(function()
    SaneUI.Core.Set("Combat", "unitRest", false) -- the scene is to look at: never out of sight
    for _, timer in ipairs(timers) do Lab.Fire("MIRROR_TIMER_START", unpack(timer)) end
    local function Again()
        LabCast("Fireball")
        C_Timer.After(4, Again)
    end
    Again()
end)
