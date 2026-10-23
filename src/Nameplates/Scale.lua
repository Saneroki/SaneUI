local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  One hand on every plate's size and transparency, so nothing else pulls at
--  them: Scale.FULL within ten yards, then down to half of it at forty yards
--  and a quarter at sixty (Scale.CURVE, straight between), the farthest the
--  game shows plates of units you have not targeted. Your target's plate,
--  which the game shows farther, stays at that quarter beyond. A plate
--  springs in when it appears (Scale.Spring), and one you have not targeted
--  fades out over the last yards before the game takes it away (Scale.FADE).
--
--  How far a unit is the game does not tell addons; but the game scales its
--  plates by distance itself, in a straight line, by its CVars for it. So this
--  file sets that line to run from 1 at your feet to Scale.LINE at the
--  farthest reach, with nothing else in it (no larger target, no larger
--  elites) and the game's own fading of plates off, and reads it back: the
--  scale the game gave a plate (its frame's scale) is how far its unit is.
--  Then our dress on the plate is scaled to its size on our curve (over the
--  game's scale, which it inherits), and the game's unit frame on the plate
--  (its cast bar) to the curve alone. Looked at a few times a second while
--  plates show, every frame while one springs; a plate scaled anew only when
--  its size changed by more than a little.
--
--  Switched off (or the module standing down) the game's defaults come back
--  and every plate is at Scale.FULL over the game's own scaling. CVars this
--  client does not have are left alone, and none is set in a fight (some of
--  the game's nameplate CVars are locked then): that waits for the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Scale = {}
ns.Scale = Scale

Scale.FULL = 3     -- our bar's size within ten yards, over the plate's own (the size a target had before)
Scale.CURVE = { { 10, 1 }, { 40, 0.5 }, { 60, 0.25 } } -- { yards, share of Scale.FULL }, straight between
Scale.FAR = 60     -- the farthest the game shows plates of units not targeted, in yards (its limit)
Scale.FADE = 5     -- yards before the farthest reach over which a plate not targeted fades out
Scale.LINE = 0.25  -- the game's scale at the farthest reach: its line, read back for the distance
Scale.EVERY = 0.05 -- seconds between looks while nothing springs
Scale.STEP = 0.005 -- a change of scale smaller than this is left alone
-- The spring of a plate appearing: from FROM of its size, swinging past it and settling within TIME seconds, its
-- alpha up from none within SHOW seconds.
Scale.SPRING = { FROM = 0.6, DECAY = 9, SWING = 16, TIME = 0.45, SHOW = 0.15 }

-- The game's CVars and ours for them: its scaling a straight line from 1 at no distance to Scale.LINE at the farthest
-- reach, nothing scaled for other reasons, and none of its fading (but behind walls, which stays the game's).
Scale.CVARS = {
    nameplateMaxScale = "1",
    nameplateMinScale = tostring(Scale.LINE),
    nameplateMaxScaleDistance = "0",
    nameplateMinScaleDistance = "0",
    nameplateSelectedScale = "1",
    nameplateLargerScale = "1",
    nameplateMinAlpha = "1",
    nameplateMaxAlpha = "1",
    nameplateSelectedAlpha = "1",
    nameplateNotSelectedAlpha = "1",
}

local waiting = false
local active = false -- the CVars ours: the plates on our curve
local driver
local springing = 0  -- plates springing now

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

-- The farthest the game draws plates of units not targeted, in yards: its CVar, no more than its limit.
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

-- The share of Scale.FULL a plate has at that distance.
function Scale.Size(yards)
    local curve = Scale.CURVE
    if yards <= curve[1][1] then return curve[1][2] end
    for index = 2, #curve do
        local a, b = curve[index - 1], curve[index]
        if yards <= b[1] then return a[2] + (b[2] - a[2]) * (yards - a[1]) / (b[1] - a[1]) end
    end
    return curve[#curve][2]
end

-- How opaque a plate not targeted is at that distance: fully, but over the last Scale.FADE yards of the reach.
function Scale.Fade(yards, reach)
    return math.min(math.max((reach - yards) / Scale.FADE, 0), 1)
end

-- A plate springing in, that many seconds after it appeared: its size's share (past 1 and back) and its alpha.
function Scale.Spring(seconds)
    local spring = Scale.SPRING
    if seconds >= spring.TIME then return 1, 1 end
    local size = 1 - (1 - spring.FROM) * math.exp(-seconds * spring.DECAY) * math.cos(seconds * spring.SWING)
    return size, math.min(seconds / spring.SHOW, 1)
end

-- A dress at that scale and alpha, the game's unit frame under it at its own scale; each only when it changed.
local function Set(dress, scale, alpha, frame)
    if math.abs((dress.scaled or 0) - scale) >= Scale.STEP then
        dress.scaled = scale
        dress:SetScale(scale)
    end
    if math.abs((dress.faded or -1) - alpha) >= 0.01 then
        dress.faded = alpha
        dress:SetAlpha(alpha)
    end
    if dress.frame and math.abs((dress.frameScaled or 0) - frame) >= Scale.STEP then
        dress.frameScaled = frame
        dress.frame:SetScale(frame)
    end
end

-- Every plate on our curve, a springing one on its spring.
local function Look()
    local reach, now = Reach(), GetTime()
    springing = 0
    for unit, dress in pairs(ns.Plate.shown) do
        local scale = Plain(dress.plate:GetScale())
        if type(scale) == "number" and scale > 0 then
            local yards = Scale.Distance(scale, reach)
            local size = Scale.Size(yards)
            local alpha = Plain(UnitIsUnit(unit, "target")) and 1 or Scale.Fade(yards, reach)
            local pop, shown = 1, 1
            if dress.born then
                pop, shown = Scale.Spring(now - dress.born)
                if now - dress.born >= Scale.SPRING.TIME then dress.born = nil else springing = springing + 1 end
            end
            Set(dress, Scale.FULL * size * pop / scale, alpha * shown, size / scale)
        end
    end
end

local since = 0
local function Tick(_, elapsed)
    since = since + elapsed
    if springing == 0 and since < Scale.EVERY then return end
    since = 0
    Look()
end

-- The looks running while ours is on and plates show; stopped otherwise.
function Scale.Again()
    if not driver then return end
    driver:SetShown(active and not ns.off and next(ns.Plate.shown) ~= nil)
end

-- A plate that has just appeared: it springs in (Plate.lua).
function Scale.Born(dress)
    if not active or ns.off then return end
    dress.born = GetTime()
    springing = springing + 1
    dress:SetAlpha(0)
    dress.faded = 0
    Scale.Again()
end

-- A dress as it is without our curve: Scale.FULL over the game's own scaling, opaque, the game's unit frame at its
-- own scale (a plate taken back, the setting off, standing down).
function Scale.Leave(dress)
    if dress.frame then dress.frame:SetScale(1) end
    dress:SetScale(Scale.FULL)
    dress:SetAlpha(1)
    dress.scaled, dress.faded, dress.frameScaled, dress.born = Scale.FULL, 1, 1, nil
end

local function Fought()
    if not waiting then return end
    waiting = false
    Scale.Update()
end

-- As the setting says, now or at the end of the fight. Turned off, every plate without our curve at once.
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
    driver:SetScript("OnUpdate", ns.Guard(Tick))
    Scale.driver = driver
    ns.On("PLAYER_REGEN_ENABLED", Fought)
    Scale.Update()
end
