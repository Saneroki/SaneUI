local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Guild
--  The guild window on the full screen (Board.lua), at its top right, the
--  friends list under it. Not built anew: the guild window itself is held
--  there and works as always, as large as it is (smaller where the screen
--  lacks room: Layout.Board), and the full screen makes its room that size.
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
--  Held: its place, layer and scale are lent (Core.Lend) and given back
--  exactly. Its parent stays its own, and it stands at the screen's place of
--  its room (not anchored to our window): a drag moves it out as always, and a
--  window with protected buttons never ties ours to the fight's rules. The
--  game may place it anew (its panels make room for each other): a hook after
--  its SetPoint puts it back. A new size (sized, made small) makes the room
--  anew. Closed (its close button, Esc), the friends list takes its room, and
--  it stays closed while the full screen stands.
--
--  Out of a fight only: the game opens its panels for an addon only then, and
--  a window holding protected buttons cannot be moved in one (Lend waits).
--  One that closes in a fight comes back once the fight is over. Only while
--  you are in a guild and its switch is on (boardGuild). A step that fails
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
local slot     -- its room there now (Layout.Board): left, top, width, height, how much smaller
local held     -- it stands in its room now
local opened   -- opened for the full screen: closed again when that goes
local tried    -- its key was used once while the full screen stands (again after a fight)
local dismissed -- closed while the full screen stands: not opened again until it comes anew
local placing  -- our own SetPoint on it is running
local off      -- a step failed: the window is left to itself
local base     -- its own scale before it was lent
local lends = {}  -- [frame] = what of it is lent (Core.Lend)
local hooked = {} -- [frame] = true: its SetPoint, its hiding and its size are followed

-- A step that fails gives the window back, and holds it no more.
local Free
local function Try(fn, ...)
    if off then return nil end
    local ok, result = xpcall(fn, Core.Trace, ...)
    if ok then return result end
    off = true
    ns.Report("guild window", result)
    if held then pcall(Free, false) end
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

-- Its size in the full screen's units, without what we made it smaller.
local function Measure(frame)
    local ratio = frame:GetEffectiveScale() / inside:GetEffectiveScale()
    local smaller = held and slot and slot[5] or 1
    return { (Core.Plain(frame:GetWidth()) or 0) * ratio / smaller, (Core.Plain(frame:GetHeight()) or 0) * ratio / smaller }
end

-------------------------------------------------------------------------------
--  Held in its room
-------------------------------------------------------------------------------
-- At the screen's place of its room: its top left corner where the room's is.
local function Place(frame)
    local left, top = inside:GetLeft(), inside:GetTop()
    if not (left and top) then return end
    local scale, own = inside:GetEffectiveScale(), frame:GetEffectiveScale()
    placing = true
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (left + slot[1]) * scale / own, (top - slot[2]) * scale / own)
    placing = false
end

local function Seat()
    local lent = lends[window]
    if not lent:Lent() then base = window:GetScale() end
    held = true
    if not lent:SetScale(base * slot[5]) then return end -- protected in a fight: once it is over
    lent:SetLayer(inside:GetFrameStrata(), inside:GetFrameLevel() + Layout.GUILD_LEVEL)
    lent:SetPoints(Place)
end

-- Closed as Esc closes it: a panel of the game's by the game's panels, any other window by itself.
local function Close(frame)
    local name, panels = frame:GetName(), rawget(_G, "UIPanelWindows")
    if name and panels and panels[name] then HideUIPanel(frame) else frame:Hide() end
end

-- Out of its room: its place, layer and scale back as they were (in a fight once it is over); close: one
-- opened for the full screen is closed too.
Free = function(close)
    slot = nil
    if not held then return end
    held = false
    local frame = window
    lends[frame]:Return()
    if close and opened and frame:IsShown() and not InCombatLockdown() then Close(frame) end
    opened = false
end

-------------------------------------------------------------------------------
--  Followed
-------------------------------------------------------------------------------
-- The game placed it anew: back in its room.
local function Moved(frame)
    if frame ~= window or not held or placing or not slot or Core.Locked(frame) then return end
    Place(frame)
end

-- It closed: its room goes to the friends list. Closed by the player, it stays closed while the full screen
-- stands; closed in a fight (the game hides a window with protected buttons), it comes back after it.
local function Closed(frame)
    if frame ~= window or not held then return end
    if not (InCombatLockdown() or UnitAffectingCombat("player")) then dismissed = true end
    Free(false)
    Reboard()
end

local function Sized(frame)
    if frame == window and held then Reboard() end
end

local function Follow(frame)
    lends[frame] = lends[frame] or Core.Lend(frame)
    if hooked[frame] then return end
    hooked[frame] = true
    hooksecurefunc(frame, "SetPoint", ns.Guard(function(self) Try(Moved, self) end))
    frame:HookScript("OnHide", ns.Guard(function(self) Try(Closed, self) end))
    frame:HookScript("OnSizeChanged", ns.Guard(function(self) Try(Sized, self) end))
end

-- The window that is open now is the guild window: known by its name from now on.
local function Take(frame)
    if frame ~= window and held then Free(false) end
    window = frame
    ns.store.guildWindow = frame:GetName()
    Follow(frame)
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
    if not ns.options.boardGuild or not IsInGuild() then return nil end
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
-- that large; nil: none (not wished, not in a guild, closed, or none answers the key). Asked first, it opens.
function Guild.Size(room)
    return Try(Ask, room)
end

local function Hold(rect)
    if not rect or not (window and window:IsShown()) then return Free(rect == nil) end
    slot = rect
    Seat()
end

-- Its room on the full screen (a rect of Layout.Board), or none: then it is given back, and closed if it was
-- opened for the full screen.
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
