local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Rest
--  What shows only while it is needed (Saneroki, 2026-11-01): a set of frames,
--  out of sight while you are at rest, in sight while
--      the mouse is on it
--      something goes on: you fight, you are in a group, you are dead, your
--                         health is not full, your resource is not where it
--                         rests (Rest.Busy)
--      Edit Mode is open  to be placed
--      its module holds it (hold)
--  A set may rest in a group too (InGroup; Saneroki, 2026-11-07): a group then
--  counts for nothing, the rest as above.
--
--  An element's own choices (Core.Element, its right click; Saneroki,
--  2026-11-14) come on top, each switching the set on by itself: out of sight
--  while you fight, the mouse on it too (Hide in combat); out of sight but while
--  the mouse is on it or its module holds it (Show on mouseover). Edit Mode and
--  its window unlocked or filling the screen (Keep) keep it in sight; its module
--  keeping it out of sight (Away: the minimap while the game's own is chosen)
--  comes before everything.
--
--  Your resource: mana, energy and focus rest full, rage, runic power and
--  combo points rest empty, so a warrior at rest does not count as out of rage.
--
--  Your health: the game hides it from addons at all times (only a widget may
--  be given it), so no sum tells whether it is full. What the game does tell is
--  each change (UNIT_HEALTH), and out of a fight it comes back in steps until it
--  is full: health that changed in the last Rest.HEALTH seconds is taken for not
--  full. So after a fight, a loading screen or a /reload a set stays that long,
--  whatever your health is. Where the game does tell the number, the number
--  counts.
--
--  A set takes the mouse where it is out of sight: alpha 0 leaves a frame its
--  clicks, which is how the mouse can be seen on it. Only its alpha changes, in a
--  fight too (the game allows that on protected frames), by one clock of its own:
--  no animation on a frame of the game's.
--
--  Whether the mouse is on it: the game may hide where a frame stands and whether
--  it shows (the size of a frame it lays out from hidden data, an aura container's:
--  IsMouseOver and IsVisible then answer a secret, which no condition may test), so
--  each answer goes through Core.Plain, and hidden means no. The doors do not need
--  to ask: their OnEnter and OnLeave say it. A set whose doors cannot hear it (a
--  frame of no mouse of its own, or one whose clicks go through) looks for the
--  mouse on its areas every Rest.LOOK seconds instead (Watch), only while it is
--  out of sight and the mouse would bring it.
--
--      local rest = Core.Rest.New({ label = "action bars", frames = { ... }, hold = function() ... end })
--      rest:Hot(frame)         -- the mouse on it counts as on the set: an area and a door
--      rest:Area(frame)        -- only its rectangle: what holds the mouse once it came (a frame of no mouse of its own)
--      rest:Door(frame)        -- only a way in, and on while the mouse is on it: its OnEnter and OnLeave (a button)
--      rest:Enter()            -- the mouse came, told by a module that hears it itself; it goes off the hot frames
--      rest:Switch(on)         -- on: at rest as said above; off: the frames as they were
--      rest:InGroup(on)        -- on: at rest in a group too; off (as made): in sight in a group
--      rest:Element(fight, mouse)  -- an element's choices: out of sight in a fight; only the mouse (or hold) shows it
--      rest:Keep(on)           -- in sight whatever else (its window unlocked, or filling the screen)
--      rest:Away(on)           -- out of sight whatever else (its module keeps it so)
--      rest:Watch(on)          -- the mouse looked for on its areas, where no door hears it
--      rest:Look()             -- hold's answer may have changed
--      rest:Resting()          -- whether it is out of sight now, or going
--      Core.Rest.Busy(inGroup) -- whether something goes on; inGroup: a group does not count
--      Core.Rest.New({ ..., window = window })  -- the set is that element's (Core.Element.Join)
--  Nothing is heard and nothing runs while no set is on.
-------------------------------------------------------------------------------
local Rest = {}
Core.Rest = Rest
local Plain = Core.Plain

Rest.FADE = 0.2     -- seconds a set takes to come and go
Rest.LINGER = 0.2   -- seconds the mouse may be off a set before it goes: from one hot frame to the next
Rest.HEALTH = 5     -- seconds after your health last changed that it counts as not full (Health)
Rest.AGAIN = 1      -- seconds between two looks while that time runs out
Rest.LOOK = 0.1     -- seconds between two looks for the mouse on a set no door of its own hears (Watch)

local EVENTS = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
                 "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }
local UNIT_EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }
local RENEW = { PLAYER_REGEN_ENABLED = true, PLAYER_ENTERING_WORLD = true, UNIT_HEALTH = true, UNIT_MAXHEALTH = true }
local FULL = { "Mana", "Energy", "Focus", "Runes", "Essence" } -- the powers that rest full, by the game's names

local ears = CreateFrame("Frame")
local live = {}         -- [a set switched on] = true
local following = false -- something is heard
local fighting = false  -- you are in a fight
local busy = false      -- something but a group goes on, as last looked at
local grouped = false   -- you are in a group, as last looked at
local fought = false    -- you were in a fight, as last looked at
local changed = 0       -- the game's time your health last changed
local again             -- looks again while that time runs out

-- The game's numbers, asked when first needed: these tables are the game's to fill.
local function Power(name)
    local kinds = rawget(_G, "Enum") and Enum.PowerType
    return kinds and kinds[name]
end

-- Whether a power of yours stands away from where it rests. A hidden one tells nothing: not away.
local function Away(power)
    local most = power and Core.Ask(UnitPowerMax, "player", power)
    if not most or most <= 0 then return false end
    local now = Core.Ask(UnitPower, "player", power)
    if not now then return false end
    for _, name in ipairs(FULL) do
        if Power(name) == power then return now < most end
    end
    return now > 0
end

-- Your own power, your mana while another shows (a druid's form), your combo points.
local function Spent()
    return Away(Core.Ask(UnitPowerType, "player")) or Away(Power("Mana")) or Away(Power("ComboPoints"))
end

-- Whether your health is not full: by its numbers where the game tells them, else by its last change.
local function Hurt()
    local now, most = Core.Ask(UnitHealth, "player"), Core.Ask(UnitHealthMax, "player")
    if now and most then return now < most end
    return GetTime() < changed + Rest.HEALTH
end

-- Whether something but a group goes on.
local function Going()
    if fighting or Core.Ask(UnitIsDeadOrGhost, "player") then return true end
    return Hurt() or Spent()
end

local function Grouped()
    return Core.Ask(IsInGroup) == true
end

function Rest.Busy(inGroup)
    return Going() or (not inGroup and Grouped())
end

-- Every set looks again, once what goes on changed.
local function Look()
    local now, group = Going() and true or false, Grouped()
    -- A fight counts by itself too: a set hidden in a fight changes though something went on before.
    if now == busy and group == grouped and fighting == fought then return end
    busy, grouped, fought = now, group, fighting
    for set in pairs(live) do set:Look() end
end

again = Core.Later(function()
    Look()
    if GetTime() < changed + Rest.HEALTH then again() end
end, Rest.AGAIN, "rest")

-- Health changed, or may have without a word (a fight's end, a loading screen): the time runs from now.
local function Renew()
    changed = GetTime()
    again()
end

local function Fight()
    return Core.Ask(UnitAffectingCombat, "player") == true or InCombatLockdown() == true
end

local function Heard(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        fighting = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        fighting = false
    elseif event == "PLAYER_ENTERING_WORLD" then
        fighting = Fight()
    end
    if RENEW[event] then Renew() end
    Look()
end
ears:SetScript("OnEvent", Core.Guard("rest", Heard))

-- Heard only while a set is on.
local function Follow()
    local wanted = next(live) ~= nil
    if wanted == following then return end
    following = wanted
    if not wanted then return ears:UnregisterAllEvents() end
    for _, event in ipairs(EVENTS) do ears:RegisterEvent(event) end
    for _, event in ipairs(UNIT_EVENTS) do ears:RegisterUnitEvent(event, "player") end
    fighting = Fight()
    Renew()
    busy, grouped, fought = Going() and true or false, Grouped(), fighting
end

-------------------------------------------------------------------------------
--  A set
-------------------------------------------------------------------------------
local sets = {}

-- Whether a set is wanted in sight now: its module keeping it out of sight comes first; then Edit Mode and its window
-- unlocked or full (Keep); a fight it hides in; the mouse on it and its module's hold; the mouse alone; at rest (Switch)
-- what goes on; else in sight.
local function Wanted(set)
    if set.away then return false end
    if Core.EditMode.active or set.kept then return true end
    if set.fight and fighting then return false end
    if set.over or (set.hold and Core.Safe(set.label, set.hold)) then return true end
    if set.mouse then return false end
    return not set.resting or busy or (grouped and not set.inGroup)
end

-- The mouse looked for on its areas (Watch) while it is out of sight and the mouse would bring it.
local function Seek(set, wanted)
    if set.watching and not wanted and (set.mouse or set.resting) and not set.away and not (set.fight and fighting) then
        if not set.seek:IsRunning() then set.seek:Start() end
    else
        set.seek:Stop()
    end
end

local function Step(set, progress)
    set.alpha = set.from + (set.to - set.from) * progress
    for _, frame in ipairs(set.frames) do frame:SetAlpha(set.alpha) end
end

function sets:Look()
    if not self.on then return end
    local wanted = Wanted(self)
    Seek(self, wanted)
    local alpha = wanted and 1 or 0
    if alpha == self.to then return end
    self.from, self.to = self.alpha, alpha
    local still = Core.general and Core.general.animations == false
    self.clock:Run(still and 0 or Rest.FADE)
end

local function Over(set, on)
    set.over = on
    set:Look()
end

function sets:Enter()
    if not self.on then return end
    self.hover:Start(true)
    Over(self, true)
end

function sets:Door(frame)
    frame:HookScript("OnEnter", self.entered) -- guarded: Core.Guard, made once in Rest.New
    frame:HookScript("OnLeave", self.left)    -- guarded: the same
end

function sets:Area(frame)
    self.hot[#self.hot + 1] = frame
end

function sets:Hot(frame)
    self:Area(frame)
    self:Door(frame)
end

function sets:Resting()
    return self.on and self.to == 0
end

function sets:InGroup(on)
    self.inGroup = on and true or false
    self:Look()
end

-- On while any of its reasons is: at rest (Switch), an element's choices (Element); off, its frames as they were.
local function Turn(set)
    local on = set.resting or set.fight or set.mouse or false
    if on == set.on then return set:Look() end
    set.on = on
    set.clock:Stop()
    set.alpha, set.to = 1, 1
    if on then
        live[set] = true
        Follow()
        for _, frame in ipairs(set.frames) do
            local lend = Core.Lend(frame)
            lend:SetAlpha(1)
            set.lends[#set.lends + 1] = lend
        end
        return set:Look()
    end
    live[set] = nil
    Follow()
    set.over, set.door = false, nil
    set.hover:Stop()
    set.seek:Stop()
    for index = #set.lends, 1, -1 do Core.Safe(set.label, set.lends[index].Return, set.lends[index]) end
    wipe(set.lends)
end

function sets:Switch(on)
    self.resting = on and true or false
    Turn(self)
end

function sets:Element(fight, mouse)
    self.fight, self.mouse = fight and true or false, mouse and true or false
    Turn(self)
end

function sets:Keep(on)
    self.kept = on and true or false
    self:Look()
end

function sets:Away(on)
    self.away = on and true or false
    self:Look()
end

function sets:Watch(on)
    self.watching = on and true or false
    self:Look()
end

-- Off for every reason: a set that cannot change stays in sight.
local function Off(set)
    set.resting, set.fight, set.mouse = false, false, false
    Turn(set)
end

-- The mouse on a door it came in by (one that went without a word no longer holds it), or on an area in sight of the
-- game (a frame out of its parent's sight has no place to be on).
local function Under(set)
    if set.door and Plain(set.door:IsVisible()) ~= false then return true end
    for _, frame in ipairs(set.hot) do
        if Plain(frame:IsVisible()) and Plain(frame:IsMouseOver()) then return true end
    end
    return false
end

function Rest.New(options)
    local set = setmetatable({ label = options.label or "rest", frames = options.frames, hold = options.hold, hot = {},
                               lends = {}, on = false, over = false, inGroup = false, alpha = 1, from = 1, to = 1,
                               resting = false, fight = false, mouse = false, kept = false, away = false,
                               watching = false },
                             { __index = sets })
    -- A frame of ours for the clock and the mouse's watch: the game's own are left alone. Above the screen's top
    -- edge, so the mouse is never on it.
    local host = CreateFrame("Frame", nil, UIParent)
    host:SetSize(1, 1)
    host:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT")
    set.clock = Core.Motion.Clock(host, function(progress) Step(set, progress) end, function(problem)
        Core.NoteError(set.label, problem)
        Core.Safe(set.label, Off, set) -- a set that cannot change stays in sight
    end)
    set.hover = Core.Hover(host, { hot = false, linger = Rest.LINGER, label = set.label,
                                   keep = function() return Under(set) end,
                                   leave = function() Over(set, false) end })
    set.entered = Core.Guard(set.label, function(frame)
        set.door = frame
        set:Enter()
    end)
    set.left = Core.Guard(set.label, function() set.door = nil end)
    -- Where no door hears the mouse: a look at its areas now and then, while the mouse would bring it.
    set.seek = Core.Watch(host, Rest.LOOK, function()
        if not set.over and Under(set) then set:Enter() end
    end, set.label)
    if options.window and Core.Element then Core.Element.Join(options.window, set) end
    return set
end

-- Edit Mode opened or closed: every set in sight, or at rest again.
Core.EditMode.Watch(Core.Guard("rest", function()
    for set in pairs(live) do set:Look() end
end))
