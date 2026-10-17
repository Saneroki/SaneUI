local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Expand
--  A window that is small at rest and grows to a larger size while the mouse
--  rests on it. The mouse has to stay a moment (Expand.DWELL) before it opens,
--  so passing over it does nothing; open, it waits a moment after the mouse has
--  gone (Expand.LINGER) before it closes, so a slip past its edge closes
--  nothing. A window can also be kept open (expand:Stay(true)) by a control of
--  its own (the window to try, Demo.lua, has a box Keep open); let go, it closes
--  once the mouse is away. The size moves as the general kind of motion says,
--  or the window's own (Motion.lua).
--
--      local expand = Core.Expand.New(frame, {
--          width = 360, height = 240,     -- its size when open
--          corner = "TOPLEFT", spot = 24, -- only the mouse in that corner (a square that large) opens it;
--                                         -- without a corner, anywhere on it
--          hover = false,                 -- the mouse does not open it: only Open and Stay do
--          changed = function(open) end,  -- it begins to open or to close: show or hide what it holds
--          motion = function() end,       -- its own kind of motion (a key of Motion.KINDS); without: the general one
--          still = function() end,        -- while true it neither opens nor closes (another part has its
--                                         -- size: it fills the screen, Edge.lua)
--      })
--      expand:Open()   expand:Close()     -- by hand (Close also lets go of Stay)
--      expand:Stay(on)                    -- kept open (on); or let go: closed now, or once the mouse is away
--      expand.open, expand.stays
--
--  The small size is the one the frame has when it opens. The frame grows from
--  the point it hangs on: a docked window (Dock.lua) away from its screen edge.
--
--  The mouse's coming is the game's event (OnEnter, motion only: clicks go on
--  to what is under it). From then until the window is closed again a watch
--  (Core.Hover, Watch.lua) looks at the mouse every Expand.STEP seconds: whether
--  it is over the window (IsMouseOver measures the window's rectangle, so a
--  button in it is the window too; Expand.MARGIN around). A held left button
--  counts as the mouse on it: the window is being dragged. Kept open (Stay),
--  there is nothing to look for, and the watch is in. The rest of the time it
--  costs nothing. The motion is an animation of the game's that runs only while
--  the size changes (Motion.Clock).
-------------------------------------------------------------------------------
local Expand = {}
Core.Expand = Expand

Expand.DWELL = 0.2  -- seconds the mouse rests on it before it opens
Expand.LINGER = 0.5 -- seconds the mouse is away before it closes
Expand.STEP = 0.1   -- seconds between two looks at the mouse while the watch is out
Expand.MARGIN = 4   -- how far outside the window the mouse still counts as on it

local function Still(expand)
    return expand.options.still and Core.Safe("expand", expand.options.still) or false
end

-- Another part took the size on the way (the window begins to fill the screen): the motion gives it
-- up where it is. The watch still closes the window once that part is done.
local function Step(expand, progress)
    if Still(expand) then return expand.clock:Stop() end
    local share = Core.Motion.Share(expand.kind, progress)
    expand.frame:SetSize(expand.fromWidth + (expand.toWidth - expand.fromWidth) * share,
        expand.fromHeight + (expand.toHeight - expand.fromHeight) * share)
end

local function Go(expand, open)
    if expand.open == open or Still(expand) then return end
    local frame, options = expand.frame, expand.options
    -- At rest and closed, the frame has its small size. In the middle of closing it has not.
    if open and not expand.clock:IsRunning() then expand.smallWidth, expand.smallHeight = frame:GetSize() end
    expand.open = open
    expand.fromWidth, expand.fromHeight = frame:GetSize() -- from where it is: a change of mind never jumps
    if open then
        expand.toWidth, expand.toHeight = options.width, options.height
    else
        expand.toWidth, expand.toHeight = expand.smallWidth, expand.smallHeight
    end
    -- Open, the watch closes it once the mouse has gone (not while it is kept open); closed, it is in.
    if open and not expand.stays then expand.hover:Start(true) else expand.hover:Stop() end
    if options.changed then Core.Safe("expand", options.changed, open) end
    -- Out of sight nothing moves: it has its new size at once (Motion.Clock).
    expand.kind = Core.Motion.Kind(options.motion and Core.Safe("expand", options.motion))
    expand.clock:Run(expand.kind.time)
end

local methods = {}
function methods:Open() Go(self, true) end

function methods:Close()
    self.stays = false
    Go(self, false)
end

-- Kept open: nothing to look for, the watch is in. Let go: closed, unless the mouse may keep it open and
-- is on it (then the watch closes it once the mouse has gone).
function methods:Stay(on)
    self.stays = on and true or false
    if self.stays then
        Go(self, true)
        return self.hover:Stop()
    end
    if self.options.hover == false or not self.frame:IsMouseOver() then return Go(self, false) end
    if self.open then self.hover:Start(true) end
end

function Expand.New(frame, options)
    local expand = setmetatable({ frame = frame, options = options, open = false, stays = false }, { __index = methods })
    expand.clock = Core.Motion.Clock(frame, function(progress) Step(expand, progress) end)

    -- Without hover the mouse opens nothing; with a corner, only the mouse in that corner does.
    local hot = options.hover ~= false and frame or false
    if hot and options.corner then
        hot = CreateFrame("Frame", nil, frame)
        hot:SetSize(options.spot or 24, options.spot or 24)
        hot:SetPoint(options.corner)
    end
    expand.hot = hot or frame
    -- The mouse on it opens it (the hover is there); gone a while, it closes. While it is kept open, or
    -- another part has its size, the mouse's going closes nothing.
    expand.hover = Core.Hover(frame, { hot = hot, dwell = Expand.DWELL, linger = Expand.LINGER, margin = Expand.MARGIN,
        every = Expand.STEP, label = "expand",
        keep = function() return expand.stays or Still(expand) end,
        enter = function() Go(expand, true) end,
        leave = function() expand:Close() end })
    expand.watch = expand.hover.watch.frame
    return expand
end
