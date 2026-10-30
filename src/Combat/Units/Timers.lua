local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Timers
--  What the game counts down on you (its mirror timers: your breath under
--  water, fatigue far out at sea, feign death), as part of your frame, in place
--  of its bars at the top of the screen: while one runs, a bar in the frame's
--  stack (Bar.Fit), under your cast, at a power bar's height: the game's name
--  for it on the left, the seconds left on the right, as the powers are
--  written. Breath may fill again once you are back up: the bar follows the
--  game (GetMirrorTimerProgress, on the bar's own OnUpdate while it shows)
--  until the game says it stopped.
--
--  The game's own bars hear no timer start while this is on (Timers.EVENTS,
--  Units.lua: Core.Lend's SetDeaf); one that runs already ends as it would.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Timers = {}
ns.UnitTimers = Timers

Timers.MOST = 3 -- as many as the game keeps at once
Timers.COLOURS = { BREATH = { 0, 0.5, 1 } }
Timers.PLAIN = { 1, 0.7, 0 } -- every other timer's
Timers.SAMPLE = { value = 42000, most = 60000 } -- what the sample shows in Edit Mode (milliseconds)
Timers.EVENTS = { "MIRROR_TIMER_START", "PLAYER_ENTERING_WORLD" } -- how the game's bars learn of a timer

local face   -- your frame
local wanted -- whether this is on

-- The bar of a timer, or with timer nil the first that is free.
local function Find(timer)
    for _, bar in ipairs(face.timers) do
        if bar.timer == timer then return bar end
    end
end

-- A number or a flag, as the game gives it by event and by asking.
local function Paused(paused)
    return paused == true or (type(paused) == "number" and paused > 0)
end

-- How much is left on a bar (milliseconds); its seconds written only as they change.
local function Write(bar, value)
    bar:SetValue(value / 1000)
    local seconds = math.ceil(value / 1000)
    if seconds == bar.seconds then return end
    bar.seconds = seconds
    bar.left:SetFormattedText("%d", seconds)
end

local function Tick(bar)
    if bar.paused or not bar.timer then return end
    local value = Core.Ask(rawget(_G, "GetMirrorTimerProgress"), bar.timer)
    if type(value) == "number" then Write(bar, value) end
end
local OnUpdate = ns.Guard(Tick)

-- A timer on its bar, into the stack.
local function Run(timer, value, most, paused, label)
    local bar = Find(timer) or Find(nil)
    if not bar then return end
    bar.timer, bar.paused, bar.seconds = timer, Paused(paused), nil
    local colour = Timers.COLOURS[timer] or Timers.PLAIN
    bar:SetStatusBarColor(colour[1], colour[2], colour[3])
    bar:SetMinMaxValues(0, most / 1000)
    Write(bar, value)
    bar.label:SetText(label or "")
    if not bar.on then
        bar.on = true
        ns.UnitBar.Fit(face)
    end
end

-- Every timer running as the game says it now.
local function Read()
    if not face or not wanted or Core.EditMode.active then return end
    for index = 1, Timers.MOST do
        local ok, timer, value, most, _, paused, label = pcall(GetMirrorTimerInfo, index)
        if ok and type(timer) == "string" and timer ~= "UNKNOWN" and type(value) == "number" and type(most) == "number" then
            Run(timer, value, most, paused, label)
        end
    end
end

local function Started(timer, value, most, _, paused, label)
    if face and wanted and type(value) == "number" and type(most) == "number" then
        Run(timer, value, most, paused, label)
    end
end

local function Stopped(timer)
    local bar = face and timer and Find(timer)
    if not bar then return end
    bar.timer, bar.on = nil, false
    ns.UnitBar.Fit(face)
end

local function Held(timer, paused)
    local bar = face and timer and Find(timer)
    if bar then bar.paused = Paused(paused) end
end

-- The bars in your frame's stack, hidden until a timer runs, as high as height.
function Timers.Make(owner, height)
    face = owner
    face.timers = {}
    local Text = ns.UnitText
    for index = 1, Timers.MOST do
        local bar = ns.UnitBar.Strip(face, face.health:GetFrameLevel())
        bar:Hide()
        local over = Text.Over(bar)
        bar.label, bar.left = Text.Line(over, "LEFT", Text.SMALL), Text.Line(over, "RIGHT", Text.SMALL)
        bar.label:SetPoint("LEFT", bar, "LEFT", Text.INSET - 1, 0)
        bar.left:SetPoint("RIGHT", bar, "RIGHT", 1 - Text.INSET, 0)
        bar.tall = height
        bar:SetScript("OnUpdate", OnUpdate)
        face.timers[index] = bar
        face.under[#face.under + 1] = bar
    end
end

-- The bars on, as the game's timers are now (in Edit Mode a sample, to show how far the frame's outline goes), or off.
function Timers.Set(on)
    wanted = on
    if not face then return end
    for _, bar in ipairs(face.timers) do bar.timer, bar.on = nil, false end
    if on and Core.EditMode.active then
        Run("BREATH", Timers.SAMPLE.value, Timers.SAMPLE.most, true, ns.TEXT.samples.breath)
    else
        Read()
    end
    ns.UnitBar.Fit(face)
end

function Timers.Start()
    ns.On("MIRROR_TIMER_START", Started)
    ns.On("MIRROR_TIMER_STOP", Stopped)
    ns.On("MIRROR_TIMER_PAUSE", Held)
    ns.On("PLAYER_ENTERING_WORLD", Read)
end
