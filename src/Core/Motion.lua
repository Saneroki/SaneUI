local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Motion
--  How Sane UI's frames move from one size or place to another. A motion is a
--  length of time and one of the easing curves of Blizzard's own interface
--  (EasingUtil, Blizzard_SharedXML): how much of the way a frame has gone after
--  so much of the time. There are four:
--      Glide     0.35 s   quick at first, then settling into place   (OutQuartic)
--      Swing     0.45 s   a little past the mark, then back to it    (OutBack)
--      Even      0.5 s    a gentle start and a gentle end            (InOutCubic)
--      Instant            no motion: at the end at once
--  Glide is the general one at first, a switch on the page Appearance of Sane
--  UI's options (Core.general.motion, Saved.lua). A window may have a setting
--  of its own instead (Social's), with "Use global type" among its choices. A
--  key nobody knows (an old saved one) means the general one.
--
--      local motion = Motion.Kind(key)          -- a window's own setting; nil, "global" or unknown: the general one
--      motion.time                              -- its seconds; 0: no motion
--      Motion.Share(motion, progress)           -- the share of the way after that share of the time
--      Motion.Ease(curve, progress)             -- one of EasingUtil's curves by its name; straight if the game lacks it
--      Motion.Choices(own)                      -- for a dropdown (Core.Options); own: with "Use global type" first
--
--      local clock = Motion.Clock(frame, step, failed)
--      clock:Run(seconds)  clock:Stop()  clock:IsRunning()
--
--      local fade = Motion.Fade(region)         -- its alpha moves: fade:To(alpha, seconds, from)
--      local slide = Motion.Slide(region, seconds)  -- slide:From(x, y): shown that far off, it moves back
--
--  The clock calls step(progress) every frame while it runs and step(1) at its
--  end: an animation of the game's that moves nothing by itself, so the game
--  calls it only while it runs and nothing is looked at while nothing moves.
--  Out of sight, or with no time, it is at its end at once: also when the frame
--  is hidden while it runs. An error in step stops it (it would come again
--  every frame) and goes to failed(problem).
-------------------------------------------------------------------------------
local Motion = {}
Core.Motion = Motion

Motion.GLOBAL = "global" -- a window's own setting: the general kind
Motion.DEFAULT = "glide"
local TEXT = { global = "Use global type" }

-- In the order the dropdowns list them. curve: the name of the function in Blizzard's EasingUtil.
-- The key "off" is also what a module passes while its own animations are switched off.
Motion.KINDS = {
    { key = "glide", text = "Glide", time = 0.35, curve = "OutQuartic" },
    { key = "swing", text = "Swing", time = 0.45, curve = "OutBack" }, -- a tenth past the mark at most
    { key = "even", text = "Even", time = 0.5, curve = "InOutCubic" },
    { key = "off", text = "Instant", time = 0 },
}
local byKey = {}
for _, kind in ipairs(Motion.KINDS) do byKey[kind.key] = kind end

-- The kind a window moves by: its own setting (key), or the general one if it has none or names none.
function Motion.Kind(key)
    -- Animations switched off (Appearance): nothing of Sane UI's moves, whatever a window's own setting says.
    if Core.general and Core.general.animations == false then return byKey.off end
    if not byKey[key] then key = Core.general and Core.general.motion end
    return byKey[key] or byKey[Motion.DEFAULT]
end

-- The game's curve of that name at progress (0 to 1). A client without it moves straight, at an
-- even pace, rather than not at all.
function Motion.Ease(curve, progress)
    if progress <= 0 then return 0 elseif progress >= 1 then return 1 end
    local curves = rawget(_G, "EasingUtil")
    local ease = type(curves) == "table" and curves[curve]
    if type(ease) ~= "function" then return progress end
    return ease(progress)
end

function Motion.Share(kind, progress)
    if not kind.curve or kind.time <= 0 then return 1 end
    return Motion.Ease(kind.curve, progress)
end

-- The choices of a dropdown, as Core.Options has them: { value, words }.
function Motion.Choices(own)
    local choices = {}
    if own then choices[1] = { Motion.GLOBAL, TEXT.global } end
    for _, kind in ipairs(Motion.KINDS) do choices[#choices + 1] = { kind.key, kind.text } end
    return choices
end

-------------------------------------------------------------------------------
--  The clock
-------------------------------------------------------------------------------
local clocks = {}

local function Tick(clock, progress)
    local ok, problem = xpcall(clock.step, Core.Trace, progress)
    if ok then return end
    clock.group:Stop()
    if clock.failed then clock.failed(problem) else Core.NoteError("motion", problem) end
end

function clocks:Run(seconds)
    self.group:Stop()
    if seconds <= 0 or not self.frame:IsVisible() then return Tick(self, 1) end
    self.animation:SetDuration(seconds)
    self.group:Play()
end

function clocks:Stop() self.group:Stop() end
function clocks:IsRunning() return self.group:IsPlaying() end

function Motion.Clock(frame, step, failed)
    local clock = setmetatable({ frame = frame, step = step, failed = failed }, { __index = clocks })
    local group = frame:CreateAnimationGroup()
    local animation = group:CreateAnimation("Animation")
    -- The end is OnFinished's alone: a last OnUpdate at 1 would end it twice.
    group:SetScript("OnUpdate", function()
        local progress = animation:GetProgress()
        if progress < 1 then Tick(clock, progress) end
    end)
    group:SetScript("OnFinished", function() Tick(clock, 1) end)
    -- Hidden on the way, it is at its end at once: nothing waits out of sight half way (an opening
    -- window caught at half its size).
    frame:HookScript("OnHide", function()
        if not group:IsPlaying() then return end
        group:Stop()
        Tick(clock, 1)
    end)
    clock.group, clock.animation = group, animation
    return clock
end

-------------------------------------------------------------------------------
--  A region's fade and slide
-------------------------------------------------------------------------------
--  What a window holds fading out and coming in again (Edge.lua), a list's
--  messages sliding up to make room (Social): the game's own animations, an
--  Alpha and a Translation, smoothed as the game smooths its own (SetSmoothing
--  OUT: quick at first, settling), so the game moves them and no code of ours
--  runs on the way. With Sane UI's animations off (Core.general.animations), no
--  time, or out of sight, each is where it goes at once.
--
--      local fade = Motion.Fade(region)
--      fade:To(alpha, seconds, from)    -- from its alpha now (or from), to alpha
--      local slide = Motion.Slide(region, seconds)
--      slide:From(x, y)                 -- shown that far from its place at once, it moves back to it in its
--                                       -- seconds; one still on its way adds what it had left
--      slide:SetTime(seconds)   fade:Stop()   slide:Stop()   fade:IsPlaying()   slide:IsPlaying()
local function Moves(region)
    return not (Core.general and Core.general.animations == false) and region:IsVisible()
end

local fades = {}

function fades:To(alpha, seconds, from)
    self.group:Stop()
    local region = self.region
    if not seconds or seconds <= 0 or not Moves(region) then return region:SetAlpha(alpha) end
    self.alpha:SetFromAlpha(from or region:GetAlpha())
    self.alpha:SetToAlpha(alpha)
    self.alpha:SetDuration(seconds)
    self.group:Play()
end

function fades:Stop() self.group:Stop() end
function fades:IsPlaying() return self.group:IsPlaying() end

function Motion.Fade(region)
    local group = region:CreateAnimationGroup()
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetSmoothing("OUT")
    group:SetToFinalAlpha(true) -- the region keeps the alpha it went to
    return setmetatable({ region = region, group = group, alpha = alpha }, { __index = fades })
end

local slides = {}

function slides:SetTime(seconds)
    self.time = seconds or 0
    self.home:SetDuration(self.time)
end

-- Two moves at once, as the game's own animations do it: one of no time away from the place, one back to it.
function slides:From(x, y)
    if (x == 0 and y == 0) or self.time <= 0 or not Moves(self.region) then return end
    if self.group:IsPlaying() then
        local left = 1 - self.home:GetSmoothProgress()
        x, y = x + self.x * left, y + self.y * left
    end
    self.group:Stop()
    self.x, self.y = x, y
    self.away:SetOffset(x, y)
    self.home:SetOffset(-x, -y)
    self.group:Play()
end

function slides:Stop() self.group:Stop() end
function slides:IsPlaying() return self.group:IsPlaying() end

function Motion.Slide(region, seconds)
    local group = region:CreateAnimationGroup()
    local away = group:CreateAnimation("Translation")
    away:SetDuration(0)
    local home = group:CreateAnimation("Translation")
    home:SetSmoothing("OUT")
    local slide = setmetatable({ region = region, group = group, away = away, home = home, x = 0, y = 0 }, { __index = slides })
    slide:SetTime(seconds)
    return slide
end
