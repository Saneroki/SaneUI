local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Plates smaller the farther their unit is from you: their own size at your
--  feet, half at forty yards, a quarter at sixty, the farthest the game shows
--  plates of units you have not targeted, in one straight line. Your target's
--  plate, which the game shows farther, stays at a quarter beyond that.
--
--  The game scales its plates by distance itself, in a straight line, by its
--  CVars for it: this file sets that line (Scale.CVARS: full size at no
--  distance, Scale.FAR at the farthest reach) with nothing else in it (no
--  larger target, no larger elites), while the setting is on, and puts the
--  game's defaults back when it is switched off or the module stands down.
--  CVars this client does not have are left alone, and none is set in a fight
--  (some of the game's nameplate CVars are locked then): that waits for the
--  fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Scale = {}
ns.Scale = Scale

Scale.FAR = 0.25 -- the size at the plates' farthest reach (sixty yards: the game's limit)
Scale.CVARS = {
    nameplateMaxScale = "1",
    nameplateMinScale = tostring(Scale.FAR),
    nameplateMaxScaleDistance = "0", -- smaller from your feet on
    nameplateMinScaleDistance = "0", -- smallest at the farthest reach
    nameplateSelectedScale = "1",
    nameplateLargerScale = "1",
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
