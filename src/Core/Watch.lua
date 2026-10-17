local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Watch
--  Looking at something a few times a second, only while there is something
--  to see.
--
--  A watch (Core.Watch) calls fn every so many seconds while it is out and its
--  frame is shown. It is a small frame of its own, a child of that frame, whose
--  OnUpdate the game runs only while it is shown: taken in, or the frame
--  hidden, nothing runs. An error stops it (it would come again at every look)
--  and is noted once.
--
--      local watch = Core.Watch(frame, 0.1, function(passed) end, "label")  -- passed: seconds since the last look
--      watch:Start()   watch:Stop()   watch:IsRunning()   watch.frame
--
--  Hover (Core.Hover) is the mouse on a window: the game tells when it comes
--  (the OnEnter of the window, or of a part of it), and from then a watch looks
--  whether it is still there, until it has gone; then it is taken in. The
--  window takes only the mouse's coming (SetMouseMotionEnabled): clicks go on
--  to what is under it.
--
--      local hover = Core.Hover(frame, {
--          hot = region,          -- whose OnEnter starts it; without: frame; false: only Start does
--          dwell = 0.2,           -- seconds the mouse rests on hot before it is there (0: at once)
--          linger = 0.5,          -- seconds it has been away from frame before it is gone (0: at once)
--          margin = 4,            -- how far around frame still counts as on it
--          every = 0.1,           -- seconds between two looks
--          keep = function() end, -- while true it is not gone (it is kept open, another part has it)
--          enter = function() end, leave = function() end,
--          label = "expand",      -- what a failure is noted as
--      })
--      hover.over                 -- the mouse is there: told enter, not yet leave
--      hover:Start(over)          -- looks from now on, as if the mouse came (over: it is there already)
--      hover:Stop()               -- looks no more, and tells nothing
--  A held left button counts as the mouse there: something of the window is
--  being dragged.
-------------------------------------------------------------------------------
local watches = {}

function watches:Start()
    self.waited = 0
    self.frame:Show()
end

function watches:Stop()
    self.frame:Hide()
end

function watches:IsRunning()
    return self.frame:IsShown()
end

local function Tick(watch, elapsed)
    watch.waited = watch.waited + elapsed
    if watch.waited < watch.every then return end
    local passed = watch.waited
    watch.waited = 0
    local ok, problem = xpcall(watch.fn, Core.Trace, passed)
    if ok then return end
    watch.frame:Hide()
    Core.Report(watch.label, problem)
end

function Core.Watch(parent, every, fn, label)
    local watch = setmetatable({ every = every or 0, fn = fn, waited = 0, label = label or "watch" }, { __index = watches })
    local frame = CreateFrame("Frame", nil, parent)
    frame:Hide()
    frame:SetScript("OnUpdate", function(_, elapsed) Tick(watch, elapsed) end)
    watch.frame = frame
    return watch
end

-------------------------------------------------------------------------------
--  The mouse on a window
-------------------------------------------------------------------------------
local hovers = {}

function hovers:Start(over)
    self.over, self.rested, self.away = over and true or false, 0, 0
    self.watch:Start()
end

function hovers:Stop()
    self.over = false
    self.watch:Stop()
end

-- One look: not there yet, the mouse resting on hot long enough makes it there, and the mouse gone takes
-- the watch in; there, the mouse away long enough is gone.
local function Look(hover, passed)
    local options = hover.options
    if not hover.over then
        if not hover.hot or not hover.hot:IsMouseOver() then return hover:Stop() end
        hover.rested = hover.rested + passed
        if hover.rested < (options.dwell or 0) then return end
        hover.over, hover.away = true, 0
        if options.enter then Core.Safe(hover.watch.label, options.enter) end
        return
    end
    local margin = options.margin or 0
    if (options.keep and options.keep()) or IsMouseButtonDown("LeftButton")
        or hover.frame:IsMouseOver(margin, -margin, -margin, margin) then
        hover.away = 0
        return
    end
    hover.away = hover.away + passed
    if hover.away < (options.linger or 0) then return end
    hover:Stop()
    if options.leave then Core.Safe(hover.watch.label, options.leave) end
end

function Core.Hover(frame, options)
    local hover = setmetatable({ frame = frame, options = options, over = false, rested = 0, away = 0 }, { __index = hovers })
    hover.watch = Core.Watch(frame, options.every or 0.1, function(passed) Look(hover, passed) end, options.label or "hover")
    if options.hot == false then return hover end
    local hot = options.hot or frame
    hover.hot = hot
    -- Only the mouse's coming is asked for: clicks go on to what is under it.
    if hot.SetMouseMotionEnabled then hot:SetMouseMotionEnabled(true) else hot:EnableMouse(true) end
    hot:HookScript("OnEnter", function()
        if hover.watch:IsRunning() then return end
        if (options.dwell or 0) > 0 then return hover:Start(false) end
        hover:Start(true) -- there at once
        if options.enter then Core.Safe(hover.watch.label, options.enter) end
    end)
    return hover
end
