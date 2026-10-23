local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Every plate's size: your target's always Scale.Full() (the setting
--  Nameplate size); any other's by how far its unit is from your character
--  and nothing else: full within ten yards, then down to half at forty yards
--  and a quarter at sixty (Scale.CURVE, straight between). No transparency of ours, but a plate
--  appearing grows in from nothing.
--
--  The distance is Range.lua's (from your character, never the camera). The
--  game's own scaling of plates (by the camera's distance, a larger target,
--  larger elites) and its fading are switched off by its CVars (Scale.CVARS),
--  and whatever scale the game still gives a plate is undone (our size over
--  the plate's own scale), so ours is the only one.
--
--  Each plate moves to its size at an even pace, in a straight line, never
--  past it: with its unit's distance about as fast as a running unit changes
--  it (Scale.SPEED), so it shrinks and grows smoothly from rung to rung of
--  Range.lua's ladder; quickly when selected or let go (Scale.QUICK); from
--  nothing when it appears (within Scale.GROW). A driver frame looks at the distances
--  every Range.EVERY seconds and moves the plates every frame while one moves;
--  hidden while no plate shows. The game's unit frame on a plate (its cast
--  bar) is scaled along, without our size setting.
--
--  While on, the CVars are ours: set again a little after the game has its
--  stored settings and Core's Sync has written a profile's (both come after
--  the login and would bring the game's scaling back), and whenever one of
--  them changes (CVAR_UPDATE). What they had before ours is kept with the
--  module's settings and goes back when the setting is switched off, the
--  module stands down, or the game is about to write its settings (a
--  logout, a /reload): so a module switched off or not loaded leaves the
--  game's and the profiles' values alone, and every plate is then at
--  Scale.Full() over the game's own scaling.
--  CVars this client does not have are left alone, and none is set in a
--  fight (some of the game's nameplate CVars are locked then): that waits for
--  the fight's end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Scale = {}
ns.Scale = Scale

Scale.SIZE = 125 -- the setting Nameplate size at first: our bar's size within ten yards, in percent
Scale.CURVE = { { 10, 1 }, { 40, 0.5 }, { 60, 0.25 } } -- { yards, share of the full size }, straight between
Scale.SPEED = 0.2  -- how fast a plate follows its unit's distance: shares of the full size a second, in a straight
                   -- line (about as fast as a running unit changes it)
Scale.QUICK = 2    -- how fast it moves to a size for any other reason (selected, the setting)
Scale.GROW = 0.2   -- seconds a plate takes to grow from nothing as it appears
Scale.SHOW = 0.12  -- seconds a plate takes from unseen to seen as it appears
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
local active = false  -- the CVars ours: the plates on our curve
local applied = false -- ours were set this session: switched off, what was there before goes back
local driver

-- Our bar's size within ten yards, from the setting.
function Scale.Full()
    return ((ns.options or {}).plateSize or Scale.SIZE) / 100
end

-- One CVar set: through Core's Sync where it is there (it keeps a profile's game settings and knows which the game
-- takes), else the game's own. Whether it was set.
local function Put(name, value)
    local sync = Core.Sync
    if sync and sync.SetCVar then return sync.SetCVar(name, value) ~= false end
    return Core.Ask(C_CVar.SetCVar, name, value) ~= false
end

-- The values the CVars had before ours (the game's, a profile's, the player's), kept with the module's settings so a
-- logout can put them back: [name] = value.
local function Found()
    local options = ns.options or {}
    if type(options.foundCVars) ~= "table" then options.foundCVars = {} end
    return options.foundCVars
end

-- Each CVar ours, where this client has it; what it had before kept first (once: not a value of ours). Whether all
-- those there are ours.
local function Ours()
    local found, done = Found(), true
    for name, value in pairs(Scale.CVARS) do
        local now = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil and tostring(now) ~= value then
            if found[name] == nil then found[name] = tostring(now) end
            done = Put(name, value) and done
        end
    end
    return done
end

-- Each CVar back to what it had before ours (the game's default for one of ours whose earlier value is not known),
-- and nothing kept any more: from now on they are the game's and the profiles' alone.
local function Restore()
    local found = Found()
    for name, value in pairs(Scale.CVARS) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            local back = found[name] or (tostring(now) == value and default) or nil
            if back ~= nil and tostring(now) ~= tostring(back) then Put(name, tostring(back)) end
        end
        found[name] = nil
    end
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

-- One step of a plate towards its size, at an even pace (faster while it grows in); whether it still moves.
function Scale.Step(dress, elapsed)
    local aim = dress.aim or 1
    local now = dress.now or aim
    local pace = dress.growing and aim / Scale.GROW or dress.quick and Scale.QUICK or Scale.SPEED
    local step = pace * math.min(elapsed, 0.1)
    if math.abs(aim - now) <= step then
        now, dress.growing, dress.quick = aim, nil, nil
    else
        now = now + (aim > now and step or -step)
    end
    dress.now = now
    Show(dress, now)
    if dress.showing then
        dress.showing = math.min(dress.showing + elapsed / Scale.SHOW, 1)
        dress:SetAlpha(dress.showing)
        if dress.showing >= 1 then dress.showing = nil end
    end
    -- Laid out anew when its size settled or moved on by a tenth since: the border one screen pixel at this size.
    if not dress.fitted then dress.fitted = now end
    local fitted = dress.fitted
    if (now == aim and fitted ~= now) or math.abs(now - fitted) > 0.1 * math.max(now, 0.05) then
        dress.fitted = now
        ns.Plate.Refit(dress)
    end
    return now ~= aim or dress.showing ~= nil
end

-- Every plate's size aimed: your target's full, any other's that of its distance (Range.lua's; kept where it could
-- not be told); shown anew where the game changed the scale it gives the plate. Selected or let go, a plate moves
-- quickly; by distance, evenly with its unit.
local function Aim()
    for unit, dress in pairs(ns.Plate.shown) do
        local target = Plain(UnitIsUnit(unit, "target")) == true
        local aim = target and 1 or Scale.Size(dress.yards or 0)
        local own = Plain(dress.plate:GetScale())
        if target ~= (dress.target == true) then dress.target, dress.quick = target, true end
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

-- The driver running while plates show (it looks at their distances and reaches, and moves the plates).
function Scale.Again()
    if not driver then return end
    driver:SetShown(not ns.off and next(ns.Plate.shown) ~= nil)
end

-- A plate that has just appeared: it grows in from nothing, to the size of its distance once that is known.
function Scale.Born(dress)
    if not active or ns.off then return end
    dress.now, dress.aim, dress.moving, dress.growing, dress.fitted = 0, Scale.Size(dress.yards or 0), true, true, 0
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
    dress.now, dress.aim, dress.moving, dress.growing, dress.showing, dress.yards = nil, nil, nil, nil, nil, nil
    dress.quick, dress.target, dress.fitted = nil, nil, nil
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
    elseif on then
        applied = true
        active = Ours()
    elseif applied then
        -- Switched off (or standing down): what was there before ours, once; then the CVars are left alone.
        applied = false
        Restore()
    end
    if active then
        for _, dress in pairs(ns.Plate.shown) do
            dress.moving = true
            if not dress.now then dress.now = Scale.Size(dress.yards or 0) end
        end
    end
    Scale.Again()
end

-- The game about to write its settings (a logout, a /reload): what was there before ours goes back, so with the
-- module gone the game and the profiles have their own; loaded again, it sets ours again at the login.
function Scale.Logout()
    if not applied then return end
    applied, active = false, false
    Restore()
end

-- The game's own again (standing down): out of a fight now, else at its end.
function Scale.GiveBack()
    Scale.Update()
end

-- Once more a little later: after the game's stored settings and Core's Sync have written theirs (both come after
-- the login; Sync waits 2 seconds) and would bring the game's scaling and fading back, or after something else set
-- one of ours.
Scale.AGAIN = 3
local again = Core.Later(function() Scale.Update() end, Scale.AGAIN)
local watched = {} -- [lower-case CVar name] = true
for name in pairs(Scale.CVARS) do watched[name:lower()] = true end

local function Changed(name)
    if applied and type(name) == "string" and watched[name:lower()] then again() end
end

function Scale.Start()
    driver = CreateFrame("Frame")
    driver:Hide()
    driver:SetScript("OnUpdate", ns.Guard(Tick))
    Scale.driver = driver
    ns.On("PLAYER_REGEN_ENABLED", Fought)
    ns.On("PLAYER_ENTERING_WORLD", again)
    ns.On("VARIABLES_LOADED", again)
    ns.On("CVAR_UPDATE", Changed)
    Scale.Update()
end
