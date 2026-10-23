local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Every plate's size, by how far its unit is from your character and by
--  nothing else: Scale.Full() (the setting Nameplate size) within ten yards,
--  then down to half of it at forty yards and a quarter at sixty
--  (Scale.CURVE, straight between). Selected or not, rank, anything else:
--  the same size at the same distance. No transparency of ours, but a plate
--  appearing springs in from nothing.
--
--  The distance is Range.lua's (from your character, never the camera). The
--  game's own scaling of plates (by the camera's distance, a larger target,
--  larger elites) and its fading are switched off by its CVars (Scale.CVARS),
--  and whatever scale the game still gives a plate is undone (our size over
--  the plate's own scale), so ours is the only one.
--
--  Each plate moves to its size on a spring (Scale.SPRING: a little past it,
--  then settling), from nothing when it appears, from its last size when its
--  distance changes. A driver frame looks at the distances every
--  Range.EVERY seconds and moves the springs every frame while one moves;
--  hidden while no plate shows. The game's unit frame on a plate (its cast
--  bar) is scaled along, without our size setting.
--
--  Switched off (or the module standing down): the game's defaults come
--  back, and every plate is at Scale.Full() over the game's own scaling.
--  CVars this client does not have are left alone, and none is set in a
--  fight (some of the game's nameplate CVars are locked then): that waits for
--  the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Scale = {}
ns.Scale = Scale

Scale.SIZE = 250 -- the setting Nameplate size at first: our bar's size within ten yards, in percent
Scale.CURVE = { { 10, 1 }, { 40, 0.5 }, { 60, 0.25 } } -- { yards, share of the full size }, straight between
-- The spring a plate moves on: its pull to its size, its damping (a little past it, then settling), and when it is
-- still (closer than REST, slower than REST).
Scale.SPRING = { PULL = 170, DAMP = 15, REST = 0.002 }
Scale.SHOW = 0.12 -- seconds a plate takes from unseen to seen as it appears
-- The game's CVars and ours for them: none of its scaling, none of its fading (but behind walls, which stays its own).
Scale.CVARS = {
    nameplateMaxScale = "1",
    nameplateMinScale = "1",
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
local moving = 0     -- plates on their spring now

-- Our bar's size within ten yards, from the setting.
function Scale.Full()
    return ((ns.options or {}).size or Scale.SIZE) / 100
end

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

-- The share of the full size a plate has at that distance.
function Scale.Size(yards)
    local curve = Scale.CURVE
    if yards <= curve[1][1] then return curve[1][2] end
    for index = 2, #curve do
        local a, b = curve[index - 1], curve[index]
        if yards <= b[1] then return a[2] + (b[2] - a[2]) * (yards - a[1]) / (b[1] - a[1]) end
    end
    return curve[#curve][2]
end

-- A plate at its size now (a share of the full size): our dress at the full size times it, the game's unit frame at
-- it alone, each over the scale the game gives the plate, which they inherit.
local function Show(dress, share)
    local own = Plain(dress.plate:GetScale())
    if type(own) ~= "number" or own <= 0 then own = 1 end
    dress:SetScale(math.max(Scale.Full() * share / own, 0.001))
    if dress.frame then dress.frame:SetScale(math.max(share / own, 0.001)) end
end

-- One step of a plate's spring towards its size; whether it still moves.
function Scale.Step(dress, elapsed)
    local spring = Scale.SPRING
    local aim = dress.aim or 1
    local now, speed = dress.now or aim, dress.speed or 0
    elapsed = math.min(elapsed, 0.05) -- a long frame does not throw it
    speed = speed + (spring.PULL * (aim - now) - spring.DAMP * speed) * elapsed
    now = now + speed * elapsed
    local still = math.abs(aim - now) < spring.REST and math.abs(speed) < spring.REST
    if still then now, speed = aim, 0 end
    dress.now, dress.speed = now, speed
    Show(dress, now)
    if dress.showing then
        dress.showing = math.min(dress.showing + elapsed / Scale.SHOW, 1)
        dress:SetAlpha(dress.showing)
        if dress.showing >= 1 then dress.showing = nil end
    end
    return not still or dress.showing ~= nil
end

-- Every plate's size aimed at its distance's (Range.lua's; kept where it could not be told), and shown anew where
-- the game changed the scale it gives the plate.
local function Aim()
    for _, dress in pairs(ns.Plate.shown) do
        local aim = Scale.Size(dress.yards or 0)
        local own = Plain(dress.plate:GetScale())
        if aim ~= dress.aim or own ~= dress.given then
            dress.aim, dress.given = aim, own
            dress.moving = true
        end
    end
end

local since = 0
local function Tick(_, elapsed)
    since = since + elapsed
    if since >= ns.Range.EVERY then
        since = 0
        ns.Range.Look()
        if active then Aim() end
    end
    if not active then return end
    for _, dress in pairs(ns.Plate.shown) do
        if dress.moving then dress.moving = Scale.Step(dress, elapsed) end
    end
end

-- The driver running while plates show (it looks at their distances and reaches, and moves their springs).
function Scale.Again()
    if not driver then return end
    driver:SetShown(not ns.off and next(ns.Plate.shown) ~= nil)
end

-- A plate that has just appeared: it springs in from nothing, to the size of its distance once that is known.
function Scale.Born(dress)
    if not active or ns.off then return end
    dress.now, dress.speed, dress.aim, dress.moving = 0, 0, Scale.Size(dress.yards or 0), true
    dress.showing = 0
    dress:SetAlpha(0)
    Show(dress, 0)
    Scale.Again()
end

-- A dress without our curve: the full size over the game's own scaling, seen, the game's unit frame at its own
-- scale (a plate taken back, the setting off, standing down).
function Scale.Leave(dress)
    if dress.frame then dress.frame:SetScale(1) end
    dress:SetScale(Scale.Full())
    dress:SetAlpha(1)
    dress.now, dress.speed, dress.aim, dress.moving, dress.showing, dress.yards = nil, nil, nil, nil, nil, nil
end

local function Fought()
    if not waiting then return end
    waiting = false
    Scale.Update()
end

-- As the setting says, now or at the end of the fight. Turned off, every plate without our curve at once; the size
-- setting changed, every plate at it.
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
    if active then
        for _, dress in pairs(ns.Plate.shown) do
            dress.moving = true
            if not dress.now then dress.now = Scale.Size(dress.yards or 0) end
        end
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
