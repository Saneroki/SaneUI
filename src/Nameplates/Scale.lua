local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Scale
--  Every plate's size: your target's always Scale.Full() (the setting
--  Nameplate size); any other's by how far its unit is from your character
--  and nothing else: full within ten yards, then down to half at forty yards
--  and a quarter at sixty (Scale.CURVE, straight between). A plate appears
--  at the size of its distance (its unit asked at once, Range.One), never
--  larger, and fades in from unseen in a straight line (Scale.SHOW): as long
--  as running takes from 60 yards, where the game first shows plates, to 55.
--  The game tells addons no distance that far (Range.lua), so the fade is
--  timed. Besides, every plate is as transparent as the settings say
--  (Scale.Seen: Nameplate transparency, your target's Your target's
--  transparency; 0% at first), the fade in reaching that.
--
--  The distance is Range.lua's (from your character, never the camera). The
--  game's own scaling of plates (by the camera's distance, a larger target,
--  larger elites) and its fading are switched off by its CVars (Scale.CVARS),
--  and whatever scale the game still gives a plate is undone (our size over
--  the plate's own scale), so ours is the only one.
--
--  Each plate moves to its size eased: quickly at first, slower as it
--  arrives, never past it (Scale.EASE; Scale.QUICK as it is selected or let
--  go), so a step from rung to rung of Range.lua's ladder is over in a
--  moment. A driver frame looks at the distances
--  every Range.EVERY seconds, moves them on between looks every frame
--  (Range.Drift, so a plate follows a moving unit all the way) and moves the
--  plates every frame while one moves;
--  hidden while no plate shows. The game's unit frame on a plate (its cast
--  bar) is scaled along, without our size setting.
--
--  One more CVar is ours whenever the module is on, with the setting or
--  without (Scale.ALWAYS): the game shows friendly players by name only
--  (nameplateShowOnlyNameForFriendlyPlayerUnits), which hides their health
--  bar, auras and cast bar and makes the plate not clickable; off, their
--  plates are whole and Plate.lua dresses them like every other.
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
Scale.EASE = 0.08  -- how quickly a plate follows its unit's distance: within this many seconds it covers about two
                   -- thirds of the way to its size, nearly all of it within three times as long, never past it
Scale.QUICK = 0.05 -- the same for a size it takes for any other reason (selected or let go, the setting)
Scale.SNAP = 0.002 -- this near its size (a share of the full size), it is there
Scale.TEXT = 0.04  -- its texts measured anew each time its size moved on by this share since (Text.Refit)
Scale.SHOW = 5 / 7 -- seconds a plate takes from unseen to seen as it appears, in a straight line: as long as
                   -- running (7 yards a second) takes from 60 yards (Range.FAR) to 55
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
-- And those ours whenever the module is on: friendly players' plates whole, not by name only.
Scale.ALWAYS = {
    nameplateShowOnlyNameForFriendlyPlayerUnits = "0",
}

local waiting = false
local active = false  -- the CVars ours: the plates on our curve
local applied = false -- ours were set this session: switched off, what was there before goes back
local kept = false    -- the same for Scale.ALWAYS
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

-- How much of a plate shows: your target's less by the setting Your target's transparency, any other's by Nameplate
-- transparency.
function Scale.Seen(dress)
    local key = "transparency"
    if dress.unit and Plain(UnitIsUnit(dress.unit, "target")) == true then key = "targetTransparency" end
    return 1 - ((ns.options or {})[key] or 0) / 100
end

-- A dress at what shows of it now: its fade in (dress.showing, from 0 to 1) times that.
function Scale.Fade(dress)
    dress:SetAlpha((dress.showing or 1) * Scale.Seen(dress))
end

-- The values the CVars had before ours (the game's, a profile's, the player's), kept with the module's settings so a
-- logout can put them back: [name] = value.
local function Found()
    local options = ns.options or {}
    if type(options.foundCVars) ~= "table" then options.foundCVars = {} end
    return options.foundCVars
end

-- Each CVar of a list ours, where this client has it; what it had before kept first (once, as it was first seen,
-- also one already at our value: a value of the player's own, never a later value of ours). Whether all those
-- there are ours.
local function Ours(list)
    local found, done = Found(), true
    for name, value in pairs(list) do
        local now = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            if found[name] == nil then found[name] = tostring(now) end
            if tostring(now) ~= value then done = Put(name, value) and done end
        end
    end
    return done
end

-- Each CVar of a list back to what it had before ours, and nothing kept any more: from now on they are the game's
-- and the profiles' alone.
local function Restore(list)
    local found = Found()
    for name, value in pairs(list) do
        local now, default = Core.Ask(C_CVar.GetCVarInfo, name)
        if now ~= nil then
            -- What was found before ours (kept whether it equalled ours or not); a found table wiped meanwhile (a
            -- reset of the settings, a profile moved) with the CVar still at ours: the game's default.
            local back = found[name]
            if back == nil and tostring(now) == tostring(value) then back = default end
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

-- One step of a plate towards its size, eased (the same share of what is left each moment: quick at first, slower as
-- it arrives, never past it), and of its fade in; whether it still moves.
function Scale.Step(dress, elapsed)
    elapsed = math.min(elapsed, 0.1)
    local aim = dress.aim or 1
    local now = dress.now or aim
    now = aim + (now - aim) * math.exp(-elapsed / (dress.quick and Scale.QUICK or Scale.EASE))
    if math.abs(aim - now) <= Scale.SNAP then now, dress.quick = aim, nil end
    dress.now = now
    Show(dress, now)
    -- Its texts measured anew at this size, after the plate took it, once it moved on by Scale.TEXT or settled: the
    -- room is there before a text needs it.
    local measured = dress.measured
    if not measured or (now == aim and measured ~= now) or math.abs(now - measured) > Scale.TEXT * math.max(now, 0.05) then
        dress.measured = now
        ns.Text.Refit(dress)
    end
    if dress.showing then
        dress.showing = math.min(dress.showing + elapsed / Scale.SHOW, 1)
        if dress.showing >= 1 then dress.showing = nil end
        Scale.Fade(dress)
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
-- more quickly still than by distance.
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
        -- Its distance moved on between looks, and its size aimed at it every frame (your target's stays full).
        if ns.Range.Drift(dress, elapsed) and not dress.target then
            local aim = Scale.Size(dress.yards)
            if aim ~= dress.aim then dress.aim, dress.moving = aim, true end
        end
        if dress.moving then dress.moving = Scale.Step(dress, elapsed) end
    end
end

-- The driver running while plates show (it looks at their distances and reaches, and moves the plates).
function Scale.Again()
    if not driver then return end
    driver:SetShown(not ns.off and next(ns.Plate.shown) ~= nil)
end

-- A plate that has just appeared: at its size at once (its unit's distance asked now, not at the next look; your
-- target's full), unseen, fading in. Laid out at that size at its first step (fitted 0). Without our curve, at once
-- as transparent as the setting says.
function Scale.Born(dress)
    if not active or ns.off then
        Scale.Fade(dress)
        return
    end
    ns.Range.One(dress.unit, dress)
    local target = Plain(UnitIsUnit(dress.unit, "target")) == true
    local size = target and 1 or Scale.Size(dress.yards or 0)
    dress.now, dress.aim, dress.target, dress.moving, dress.fitted, dress.measured = size, size, target, true, 0, nil
    dress.showing = 0
    Scale.Fade(dress)
    Show(dress, size)
    Scale.Again()
end

-- A dress without our curve: the full size over the game's own scaling, seen (as the transparency settings say), the game's unit frame at its own scale (a plate taken back, the setting off, standing down).
function Scale.Leave(dress)
    if dress.frame then dress.frame:SetScale(1) end
    dress:SetScale(Scale.Full())
    dress.now, dress.aim, dress.moving, dress.showing, dress.yards = nil, nil, nil, nil, nil
    Scale.Fade(dress)
    dress.least, dress.most, dress.pace, dress.mark, dress.markAt, dress.rung = nil, nil, nil, nil, nil, nil
    dress.quick, dress.target, dress.fitted, dress.measured = nil, nil, nil, nil
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
        if on then
            applied = true
            active = Ours(Scale.CVARS)
        elseif applied then
            -- Switched off (or standing down): what was there before ours, once; then the CVars are left alone.
            applied = false
            Restore(Scale.CVARS)
        end
        if not ns.off then
            kept = true
            Ours(Scale.ALWAYS)
        elseif kept then
            kept = false
            Restore(Scale.ALWAYS)
        end
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
    if applied then
        applied, active = false, false
        Restore(Scale.CVARS)
    end
    if kept then
        kept = false
        Restore(Scale.ALWAYS)
    end
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
for _, list in ipairs({ Scale.CVARS, Scale.ALWAYS }) do
    for name in pairs(list) do watched[name:lower()] = true end
end

local function Changed(name)
    if (applied or kept) and type(name) == "string" and watched[name:lower()] then again() end
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
