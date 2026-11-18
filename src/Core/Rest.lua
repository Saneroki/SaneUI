local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Rest
--  What shows only while it is needed (Saneroki, 2026-11-01): a set of frames,
--  out of sight while you are at rest, in sight while
--      the mouse is on it
--      something goes on: you fight, you are in a group, you are dead, your
--                         health is not full, your resource is not where it
--                         rests (Rest.Busy)
--      Edit Mode is open  to be placed
--      its module holds it (hold)
--  A set may rest in a group too (InGroup; Saneroki, 2026-11-07): a group then
--  counts for nothing, the rest as above. And it may rest whatever goes on
--  (Fight(false); Saneroki, 2026-11-18: "show only on mouseover, show always
--  during combat, always show in party", each its own): a fight, your health,
--  your resource and death then count for nothing either, only the mouse, a
--  group (unless InGroup), its hold and Edit Mode.
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
--  to ask: their OnEnter and OnLeave say it.
--
--      local rest = Core.Rest.New({ label = "action bars", frames = { ... }, hold = function() ... end })
--      rest:Hot(frame)         -- the mouse on it counts as on the set: an area and a door
--      rest:Area(frame)        -- only its rectangle: what holds the mouse once it came (a frame of no mouse of its own)
--      rest:Door(frame)        -- only a way in, and on while the mouse is on it: its OnEnter and OnLeave (a button)
--      rest:Enter()            -- the mouse came, told by a module that hears it itself; it goes off the hot frames
--      rest:Switch(on)         -- on: at rest as said above; off: the frames as they were
--      rest:InGroup(on)        -- on: at rest in a group too; off (as made): in sight in a group
--      rest:Fight(on)          -- on (as made): what goes on shows it; off: at rest in a fight too
--      rest:Look()             -- hold's answer may have changed
--      rest:Resting()          -- whether it is out of sight now, or going
--      Core.Rest.Busy(inGroup) -- whether something goes on; inGroup: a group does not count
--  Nothing is heard and nothing runs while no set is on.
-------------------------------------------------------------------------------
local Rest = {}
Core.Rest = Rest
local Plain = Core.Plain

Rest.FADE = 0.2     -- seconds a set takes to come and go
Rest.LINGER = 0.2   -- seconds the mouse may be off a set before it goes: from one hot frame to the next
Rest.HEALTH = 5     -- seconds after your health last changed that it counts as not full (Health)
Rest.AGAIN = 1      -- seconds between two looks while that time runs out

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
    if now == busy and group == grouped then return end
    busy, grouped = now, group
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
    busy, grouped = Going() and true or false, Grouped()
end

-------------------------------------------------------------------------------
--  A set
-------------------------------------------------------------------------------
local sets = {}

local function Wanted(set)
    return (busy and set.fight) or (grouped and not set.inGroup) or set.over or Core.EditMode.active
        or (set.hold and Core.Safe(set.label, set.hold))
end

local function Step(set, progress)
    set.alpha = set.from + (set.to - set.from) * progress
    for _, frame in ipairs(set.frames) do frame:SetAlpha(set.alpha) end
end

function sets:Look()
    if not self.on then return end
    local alpha = Wanted(self) and 1 or 0
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

function sets:Fight(on)
    self.fight = on ~= false
    self:Look()
end

function sets:Switch(on)
    on = on and true or false
    if on == self.on then return self:Look() end
    self.on = on
    self.clock:Stop()
    self.alpha, self.to = 1, 1
    if on then
        live[self] = true
        Follow()
        for _, frame in ipairs(self.frames) do
            local lend = Core.Lend(frame)
            lend:SetAlpha(1)
            self.lends[#self.lends + 1] = lend
        end
        return self:Look()
    end
    live[self] = nil
    Follow()
    self.over, self.door = false, nil
    self.hover:Stop()
    for index = #self.lends, 1, -1 do Core.Safe(self.label, self.lends[index].Return, self.lends[index]) end
    wipe(self.lends)
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
                               lends = {}, on = false, over = false, inGroup = false, fight = true, alpha = 1, from = 1,
                               to = 1 },
                             { __index = sets })
    -- A frame of ours for the clock and the mouse's watch: the game's own are left alone. Above the screen's top
    -- edge, so the mouse is never on it.
    local host = CreateFrame("Frame", nil, UIParent)
    host:SetSize(1, 1)
    host:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT")
    set.clock = Core.Motion.Clock(host, function(progress) Step(set, progress) end, function(problem)
        Core.NoteError(set.label, problem)
        Core.Safe(set.label, set.Switch, set, false) -- a set that cannot change stays in sight
    end)
    set.hover = Core.Hover(host, { hot = false, linger = Rest.LINGER, label = set.label,
                                   keep = function() return Under(set) end,
                                   leave = function() Over(set, false) end })
    set.entered = Core.Guard(set.label, function(frame)
        set.door = frame
        set:Enter()
    end)
    set.left = Core.Guard(set.label, function() set.door = nil end)
    return set
end

-- Edit Mode opened or closed: every set in sight, or at rest again.
Core.EditMode.Watch(Core.Guard("rest", function()
    for set in pairs(live) do set:Look() end
end))
