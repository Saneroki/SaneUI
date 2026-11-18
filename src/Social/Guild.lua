local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Guild
--  The guild window on the full screen (Board.lua): one of its windows, at
--  its top right at first, the friends list under it. Not built anew: the
--  guild window itself is held in its panel and works as always, as large as
--  it is, smaller where its panel is smaller (never larger), and the first
--  layout makes its room that size.
--
--  Which window: the one the game's guild key opens (ToggleGuildFrame). That
--  is the game's own (its guild and communities window, Blizzard_Communities),
--  or the window of another addon that answers the key instead, whatever its
--  size. It is found by what the key does: of the windows the game knows by
--  name (those Esc closes, UISpecialFrames, and its panels, UIPanelWindows),
--  the one open after the key's work that was not open before; the largest,
--  if more came. Its name is kept (store.guildWindow), so one that is open
--  already when the full screen comes is taken as it is, in a later session
--  too. One open already is left open when the full screen goes; one opened
--  for it is closed then, as Esc closes it.
--
--  Held: seated in its panel's body (Core.Seat), which lends its place, layer
--  and scale and gives them back exactly, puts it back when the game places it
--  anew (its panels make room for each other), and gives it back when it
--  closes. Its parent stays its own, and it stands at the screen's place of
--  its room (not anchored to our window): a drag moves it out as always, and a
--  window with protected buttons never ties ours to the fight's rules. Its
--  room is its own size at the scale that fits the body (at most its own), at
--  the body's top, in its middle: so the seat's fitting keeps it exactly at
--  that scale. A new size (another tab, made small) makes the room anew.
--  Closed (its close button, Esc), the others take its room, and it stays
--  closed while the full screen stands, unless you open it again yourself (the
--  guild key): then it is back in its panel.
--
--  Out of a fight only: the game opens its panels for an addon only then, and
--  a window holding protected buttons cannot be moved in one (its seat waits).
--  One that closes in a fight comes back once the fight is over; one opened
--  for a full screen that goes in a fight is closed then. Only while
--  you are in a guild and the layout holds it. A step that fails
--  gives the window back and holds it no more until the next /reload.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Guild = {}
ns.Guild = Guild

Guild.LOOK = 0.2 -- seconds after the guild key's work until the window that came is looked for

local window   -- the guild window, once found
local size     -- its own size, the last time it was measured: { width, height } in the full screen's units
local inside   -- what the full window holds, while the full screen stands
local opened   -- opened for the full screen: closed again when that goes
local tried    -- its key was used once while the full screen stands (again after a fight)
local dismissed -- closed while the full screen stands: not opened again until it comes anew
local off      -- a step failed: the window is left to itself
local seats = {} -- [frame] = its seat in its room (Core.Seat)

-- A step that fails gives the window back, and holds it no more.
local Free
local function Try(fn, ...)
    if off then return nil end
    local ok, result = xpcall(fn, Core.Trace, ...)
    if ok then return result end
    off = true
    ns.Report("guild window", result)
    pcall(Free, false)
    return nil
end

local Reboard = Core.Later(function() ns.Guarded(ns.Window.Reboard) end)

-------------------------------------------------------------------------------
--  Which window
-------------------------------------------------------------------------------
local function Frame(name)
    local frame = type(name) == "string" and rawget(_G, name)
    if type(frame) == "table" and type(frame.GetObjectType) == "function" and frame.IsShown then return frame end
end

-- The windows the game knows by name and that are open now: [frame] = true.
local function Open()
    local open = {}
    for _, name in ipairs(rawget(_G, "UISpecialFrames") or {}) do
        local frame = Frame(name)
        if frame and frame:IsShown() then open[frame] = true end
    end
    for name in pairs(rawget(_G, "UIPanelWindows") or {}) do
        local frame = Frame(name)
        if frame and frame:IsShown() then open[frame] = true end
    end
    return open
end

-- The guild window open now, if one is: the one found before (this session, or its kept name), else the game's.
local function Current()
    window = window or Frame(ns.store.guildWindow)
    if window and window:IsShown() then return window end
    local game = Frame("CommunitiesFrame")
    if game and game:IsShown() then return game end
end

-------------------------------------------------------------------------------
--  Held in its room
-------------------------------------------------------------------------------
-- Closed while seated (given back already): its room goes to the friends list. Closed by the player, it stays
-- closed while the full screen stands; closed in a fight (the game hides a window with protected buttons), it
-- comes back after it.
local function Gone(frame)
    if frame ~= window then return end
    if not (InCombatLockdown() or UnitAffectingCombat("player")) then dismissed = true end
    opened = false
    Reboard()
end

-- Opened again by you while the full screen stands (the guild key): it is in its panel again.
local function Back(frame)
    if frame ~= window or not inside then return end
    dismissed = false
    Reboard()
end

-- Its seat, made once per window: a new size makes its room anew (sized).
local function SeatOf(frame)
    local seat = seats[frame]
    if not seat then
        seat = Core.Seat.New(frame, { label = "Social: guild window", sized = Reboard,
                                      gone = function() Try(Gone, frame) end })
        seats[frame] = seat
        frame:HookScript("OnShow", ns.Guard(function(self) Try(Back, self) end))
    end
    return seat
end

-- Its own size in the full screen's units, as it is when not seated.
local function Measure(frame)
    local width, height = SeatOf(frame):Size()
    local ratio = UIParent:GetEffectiveScale() / inside:GetEffectiveScale()
    return { width * ratio, height * ratio }
end

-- Closed as Esc closes it: a panel of the game's by the game's panels, any other window by itself.
local function Close(frame)
    local name, panels = frame:GetName(), rawget(_G, "UIPanelWindows")
    if name and panels and panels[name] then HideUIPanel(frame) else frame:Hide() end
end

-- One opened for the full screen and held no more, after a fight in which it could not be closed: closed now,
-- unless it is held again meanwhile (then it is closed when its room goes).
local function Shut()
    local frame = window
    if not (frame and opened) or (seats[frame] and seats[frame].held) then return end
    opened = false
    if frame:IsShown() then Close(frame) end
end

-- Out of its room: its place, layer and scale back as they were (in a fight once it is over); close: one
-- opened for the full screen is closed too; in a fight it stays marked, and goes once the fight is over.
Free = function(close)
    local frame = window
    if not frame then return end
    if seats[frame] then seats[frame]:Free() end
    if close and opened and InCombatLockdown() then return Core.AfterCombat("Social: guild window", Shut) end
    if close and opened and frame:IsShown() then Close(frame) end
    opened = false
end

-- Seated in its room (its panel's body: left, top, width, height in the full screen's units from its top left):
-- its own size at the scale that fits there, at most its own, at the room's top in its middle. In a fight not now
-- (Seat says no), once it is over.
local function Place(rect)
    local left, top = inside:GetLeft(), inside:GetTop()
    if not (left and top) then return end
    local seat = SeatOf(window)
    local ratio = inside:GetEffectiveScale() / UIParent:GetEffectiveScale() -- the full screen's units, in UIParent's
    local width, height = seat:Size()
    if not (width and height and width > 0 and height > 0) then return end
    local scale = math.min(1, rect[3] * ratio / width, rect[4] * ratio / height)
    width, height = width * scale, height * scale
    seat:Hold((left + rect[1]) * ratio + (rect[3] * ratio - width) / 2, (top - rect[2]) * ratio, width, height,
        inside:GetFrameStrata(), inside:GetFrameLevel() + Layout.GUILD_LEVEL)
end

-------------------------------------------------------------------------------
--  Found by its key
-------------------------------------------------------------------------------
-- The window that is open now is the guild window: known by its name from now on.
local function Take(frame)
    if frame ~= window then Free(false) end
    window = frame
    ns.store.guildWindow = frame:GetName()
    SeatOf(frame)
end

-- A while after the guild key's work: the window that came. The full screen gone meanwhile, it goes too.
local before
local function Found()
    local came, area = nil, 0
    for frame in pairs(Open()) do
        if not before[frame] then
            local width, height = Core.Plain(frame:GetWidth()) or 0, Core.Plain(frame:GetHeight()) or 0
            if width * height > area then came, area = frame, width * height end
        end
    end
    before = nil
    if not came then return end
    if not inside then return Close(came) end
    Take(came)
    opened = true
    Reboard()
end
local Look = ns.Guard(function() Try(Found) end)

-- The guild key's work, as the key does it: the game's guild window, or the one that answers the key instead.
local function Fetch()
    tried = true
    local toggle = rawget(_G, "ToggleGuildFrame")
    if not toggle or InCombatLockdown() then return end
    before = Open()
    toggle()
    C_Timer.After(Guild.LOOK, Look)
end

-------------------------------------------------------------------------------
--  The full screen
-------------------------------------------------------------------------------
-- While the full screen stands it hears of fights ending (a window closed in one comes back) and of your guild.
local function Again()
    tried = false
    Reboard()
end
local EVENTS = { PLAYER_REGEN_ENABLED = Again, PLAYER_GUILD_UPDATE = Reboard }
local listening
local function Listen(on)
    if listening == on then return end
    listening = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
end

local function Ask(room)
    inside = room
    Listen(true)
    if not IsInGuild() then return nil end
    local frame = Current()
    if frame then
        Take(frame)
        size = Measure(frame)
        return size
    end
    if dismissed or tried or InCombatLockdown() then return nil end
    Fetch()
    return size -- its room is there at once, from the last time; Found makes it anew
end

-- The full screen lays itself out in what the window holds (room): the guild window's own size, to make its room
-- that large; nil: none (not in a guild, closed, or none answers the key). Asked first, it opens.
function Guild.Size(room)
    return Try(Ask, room)
end

-- Its least size in the full screen's units, made smaller as far as Layout.GUILD_LEAST: the least of its panel's body.
function Guild.Least()
    if not size then return nil end
    return { math.ceil(size[1] * Layout.GUILD_LEAST) + 2 * Layout.EDGE, math.ceil(size[2] * Layout.GUILD_LEAST) + 2 * Layout.EDGE }
end

local function Hold(rect)
    if not rect or not (window and window:IsShown()) then return Free(rect == nil) end
    Place(rect)
end

-- Its room on the full screen (its panel's body), or none: then it is given back, and closed if it was opened for
-- the full screen.
function Guild.Hold(rect)
    Try(Hold, rect)
end

local function Leave()
    Free(true)
    inside, tried, dismissed = nil, false, false
    Listen(false)
end

-- The full screen went: the window is given back, and closed if it was opened for it.
function Guild.Leave()
    if inside then Try(Leave) end
end
