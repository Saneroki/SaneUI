local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Plates smaller the farther their unit is from you, on a curve of two
--  steps: twice their size close by, slowly down to their own size at forty
--  yards (half the closest), then faster to half their size at sixty (a
--  quarter of the closest), the farthest the game shows plates of units you
--  have not targeted. Your target's plate, which the game shows farther,
--  stays at its smallest beyond that.
--
--  How: the game scales its plates by distance itself, in a straight line
--  only, by its CVars for it. This file sets that line to run from full size
--  at your feet to Scale.LINE at the plates' farthest reach, with nothing
--  else in it (no larger target, no larger elites), so the scale the game
--  gives a plate (its frame's scale) tells how far its unit is. From that
--  distance comes the size on our curve, and the plate is scaled by the
--  difference: the game's unit frame on it (its cast bar and all) and our
--  dress alike. Checked a few times a second while plates show, a plate
--  scaled anew only when its size changed by more than a little.
--
--  The CVars are set while the setting is on, and the game's defaults put
--  back when it is switched off or the module stands down, with every plate
--  at the game's scale again. CVars this client does not have are left
--  alone, and none is set in a fight (some of the game's nameplate CVars are
--  locked then): that waits for the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Scale = {}
ns.Scale = Scale

Scale.LINE = 0.25 -- the game's scale at the plates' farthest reach, while ours is on
Scale.FAR = 60    -- the farthest the game shows plates of units not targeted, in yards (its limit)
-- Our curve: { yards, size } from close to far, a straight line between each two.
Scale.CURVE = { { 0, 2 }, { 40, 1 }, { 60, 0.5 } }
Scale.EVERY = 0.05 -- seconds between looks
Scale.STEP = 0.01  -- a change of scale smaller than this is left alone

-- The game's CVars and ours for them: its line from full size at no distance to Scale.LINE at the farthest reach
-- (a MinScaleDistance of 0: the smallest at the farthest), and nothing scaled for other reasons.
Scale.CVARS = {
    nameplateMaxScale = "1",
    nameplateMinScale = tostring(Scale.LINE),
    nameplateMaxScaleDistance = "0",
    nameplateMinScaleDistance = "0",
    nameplateSelectedScale = "1",
    nameplateLargerScale = "1",
}

local waiting = false
local active = false -- the CVars ours: the plates follow the curve
local driver

-- Each CVar ours (on) or the game's default (off), where this client has it. Whether all those there are ours.
local function Apply(on)
    local done = true
    for name, value in pairs(Scale.CVARS) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            local wanted = on and value or default
            if wanted ~= nil and tostring(now) ~= wanted then
                done = Core.Ask(C_CVar.SetCVar, name, wanted) ~= false and done
            end
        end
    end
    return done
end

-- The farthest the game draws plates, in yards: its CVar, no more than its limit.
local function Reach()
    local value = tonumber(Core.Ask(C_CVar.GetCVar, "nameplateMaxDistance"))
    if not value or value <= 0 then return Scale.FAR end
    return math.min(value, Scale.FAR)
end

-- How far a plate's unit is, from the scale the game gave the plate (its straight line, read backwards).
function Scale.Distance(scale, reach)
    local share = (1 - scale) / (1 - Scale.LINE)
    return math.min(math.max(share, 0), 1) * reach
end

-- The size on our curve at that distance.
function Scale.Size(yards)
    local curve = Scale.CURVE
    if yards <= curve[1][1] then return curve[1][2] end
    for index = 2, #curve do
        local a, b = curve[index - 1], curve[index]
        if yards <= b[1] then return a[2] + (b[2] - a[2]) * (yards - a[1]) / (b[1] - a[1]) end
    end
    return curve[#curve][2]
end

-- A dress and the game's unit frame under it scaled by that much (1: as the game has them).
local function Set(dress, by)
    if math.abs((dress.scaled or 1) - by) < Scale.STEP then return end
    dress.scaled = by
    dress:SetScale(by)
    if dress.frame then dress.frame:SetScale(by) end
end

-- Every plate on our curve.
local function Look()
    local reach = Reach()
    for _, dress in pairs(ns.Plate.shown) do
        local scale = Plain(dress.plate:GetScale())
        if type(scale) == "number" and scale > 0 then
            Set(dress, Scale.Size(Scale.Distance(scale, reach)) / scale)
        end
    end
end

local since = 0
local function Tick(_, elapsed)
    since = since + elapsed
    if since < Scale.EVERY then return end
    since = 0
    Look()
end

-- The looks running while ours is on and plates show; stopped otherwise.
function Scale.Again()
    if not driver then return end
    driver:SetShown(active and not ns.off and next(ns.Plate.shown) ~= nil)
end

-- A dress taken off its unit (Plate.lua): it and the game's unit frame at the game's scale.
function Scale.Leave(dress)
    if dress.frame then dress.frame:SetScale(1) end
    dress:SetScale(1)
    dress.scaled = nil
end

local function Fought()
    if not waiting then return end
    waiting = false
    Scale.Update()
end

-- As the setting says, now or at the end of the fight. Turned off, every plate at the game's scale at once.
function Scale.Update()
    local on = not ns.off and (ns.options or {}).distance ~= false
    if not on then
        active = false
        for _, dress in pairs(ns.Plate.shown) do Scale.Leave(dress) end
    end
    if InCombatLockdown() then
        waiting = true
    else
        active = Apply(on) and on
    end
    Scale.Again()
end

-- The game's own again (standing down): out of a fight now, else at its end.
function Scale.GiveBack()
    Scale.Update()
end

function Scale.Start()
    driver = CreateFrame("Frame")
    driver:Hide()
    Scale.driver = driver
    driver:SetScript("OnUpdate", ns.Guard(Tick))
    ns.On("PLAYER_REGEN_ENABLED", Fought)
    Scale.Update()
end
