local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Plates smaller the farther their unit is from you: full size close by, a
--  little over half far away. The game scales its plates by distance itself,
--  by its CVars for it; this file sets them while the setting is on, and
--  puts the game's defaults back when it is switched off or the module
--  stands down. CVars this client does not have are left alone, and none is
--  set in a fight (some of the game's nameplate CVars are locked then): that
--  waits for the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Scale = {}
ns.Scale = Scale

-- The game's CVars for it and ours for them: the scale close by and far away, the distance within which a plate
-- is full size, and how far before the plates' farthest reach it is smallest.
Scale.CVARS = {
    nameplateMaxScale = "1",
    nameplateMinScale = "0.55",
    nameplateMaxScaleDistance = "10",
    nameplateMinScaleDistance = "5",
}

local waiting = false

-- Each CVar ours (on) or the game's default (off), where this client has it.
local function Apply(on)
    for name, value in pairs(Scale.CVARS) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            local wanted = on and value or default
            if wanted ~= nil and tostring(now) ~= wanted then Core.Ask(C_CVar.SetCVar, name, wanted) end
        end
    end
end

local function Fought()
    if not waiting then return end
    waiting = false
    Scale.Update()
end

-- As the setting says, now or at the end of the fight.
function Scale.Update()
    if InCombatLockdown() then
        waiting = true
        return
    end
    Apply(not ns.off and (ns.options or {}).distance ~= false)
end

-- The game's own again (standing down): out of a fight now, else at its end.
function Scale.GiveBack()
    Scale.Update()
end

function Scale.Start()
    ns.On("PLAYER_REGEN_ENABLED", Fought)
    Scale.Update()
end
