-- Unit frames: Core and the module Combat from their TOCs, your frame with a cast and your breath as part of it
-- The game's frames ours stand for are not loaded in the lab: a plain frame stands in for each. A cast runs over and
-- over and your breath goes down, by the game's functions standing in. The module's table is LabCombat in the console:
-- LabCast("Fireball") casts, LabCast() stops; Lab.Fire("MIRROR_TIMER_STOP", "BREATH") ends the breath.
for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PlayerCastingBarFrame",
                        "OverlayPlayerCastingBarFrame", "MirrorTimerContainer" }) do
    CreateFrame("Frame", name, UIParent)
end
-- The lab hides what lies beyond a mask's rectangle, where the game's CLAMPTOWHITE shows it, and takes a status bar's
-- atlas for a file: here masks without a picture, so the bars are seen (square at their ends), and the atlas on its fill.
local create = CreateFrame
CreateFrame = function(kind, ...)
    local frame = create(kind, ...)
    local mask, fill = frame.CreateMaskTexture, frame.SetStatusBarTexture
    frame.CreateMaskTexture = function(self, ...)
        local made = mask(self, ...)
        made.SetTexture = function() end
        return made
    end
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
ClearOverrideBindings, SetOverrideBinding, GetBindingKey = function() end, function() end, function() end

local cast -- { name, icon, starts, ends }
UnitCastingInfo = function()
    if cast then return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, "cast-1", false, 133 end
end
UnitChannelInfo = function() end

function LabCast(name, seconds)
    local now = GetTime() * 1000
    cast = name and { name = name, icon = 135812, starts = now, ends = now + (seconds or 3) * 1000 } or nil
    Lab.Fire(cast and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_STOP", "player", "cast-1", 133)
end

local breath, BREATH = 42000, 60000
GetMirrorTimerInfo = function(index)
    if index == 1 then return "BREATH", breath, BREATH, -1, 0, "Breath" end
    return "UNKNOWN", 0, 0, 0, 0, ""
end
GetMirrorTimerProgress = function() return breath end

Lab.TOC("src/Core/SaneUI.toc")
LabCombat = Lab.TOC("src/Combat/SaneUI_Combat.toc")
LabCombat.UnitAuras.missing = true -- the lab has no aura containers: the frames do without, as in a client without them
Lab.OnLogin(function()
    Lab.Fire("MIRROR_TIMER_START", "BREATH", breath, BREATH, -1, 0, "Breath")
    local function Again()
        LabCast("Fireball")
        C_Timer.After(4, Again)
    end
    Again()
end)
