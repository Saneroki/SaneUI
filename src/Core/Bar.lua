local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Bar
--  A progress bar for any module (a reputation, a quest's count, a skill:
--  anything with a value and a most), drawn with the art of the game's own
--  experience bar (Blizzard_StatusTrackingBar): its dark background, its fill,
--  the paler part ahead of the fill for what is still to come (where the game
--  shows rested experience), the pip at that part's end, and the dividers the
--  game cuts its bar into. Every piece is one of Blizzard's atlases, untinted.
--
--  A gain rises: the fill goes up to its new value, quickly at first and then
--  settling (Motion.Ease), in a time that grows with the share gained
--  (Bar.RISE to Bar.RISE_WHOLE), with the game's own flare running at its end.
--  Anything else (a loss, another most: a new level) is there at once, and so
--  is everything out of sight, or with the kind of motion Instant. Its length
--  and thickness move as a window's size does (Motion.lua). Nothing runs while
--  nothing moves (Motion.Clock).
--
--      local bar = Core.Bar.New(parent, {
--          width = 240, height = 12,             -- at first; or anchor bar.frame by two sides
--          segments = 10,                        -- cut into so many by the game's dividers; 1: none;
--                                                -- nil: as many as the game cuts its own bar into
--          fill = atlas, flare = atlas,          -- another of the game's fills, and its flare
--          motion = function() return key end,   -- its kind of motion (a key of Motion.KINDS); nil: the general one
--          moved = function(value, most) end,    -- told the value the fill stands for, on its way too (as the
--                                                -- game's animated status bars tell theirs): for a number beside it
--      })
--      bar.frame                                 -- to anchor
--      bar:SetValue(value, most, ahead)          -- ahead: the part still to come after the value (nil: none);
--                                                -- most 0 or nil: full, there is nothing more to reach
--      bar:SetSize(width, height)                -- moves there; nil keeps that one as it is
-------------------------------------------------------------------------------
local Bar = {}
Core.Bar = Bar

-- The game's experience bar: StatusTrackingBarTemplate, ExpBar.xml and ExpBarOverrides.lua.
Bar.ART = {
    background = "UI-HUD-ExperienceBar-Background",
    fill = "UI-HUD-ExperienceBar-Fill-Experience",
    ahead = "UI-HUD-ExperienceBar-Fill-Prediction",
    pip = "UI-HUD-ExperienceBar-Frame-Pip",
    divider = "ui-hud-experiencebar-divider",
    flare = "UI-HUD-ExperienceBar-Flare-XP-2x-Flipbook",
}
-- The flare is a flipbook, laid out as the game's status bar plays it (GradualAnimatedStatusBar.xml):
-- its rows, columns and pictures, and its width for each unit of the bar's height (32.5 on 10).
local FLIPBOOK = { rows = 7, columns = 4, frames = 28, wide = 3.25 }
-- The pip's and a divider's width for each unit of the bar's height, as the game sizes them on its
-- bars (a pip 10 by 14 on a bar 14 high, a divider 3 by 10). The game hides the pip this close to an end.
local PIP_WIDE, DIVIDER_WIDE, PIP_EDGE = 10 / 14, 3 / 10, 0.01
Bar.RISE, Bar.RISE_WHOLE = 0.35, 1.1 -- seconds a gain takes: a sliver, and the whole bar
Bar.CURVE = "OutQuartic"              -- the rise's curve (Motion.Ease)

local function Clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

local methods = {}

-- A fill: a status bar of the game's over the whole frame, that many levels above it. The game cuts
-- its picture at the value: nothing is stretched.
local function Fill(frame, atlas, above)
    local status = CreateFrame("StatusBar", nil, frame)
    status:SetAllPoints()
    status:SetFrameLevel(frame:GetFrameLevel() + above)
    status:SetStatusBarTexture(atlas)
    status:SetMinMaxValues(0, 1)
    status:SetValue(0)
    return status
end

-- The pip, at the end of what is still to come: there when a value is set, and with a new size.
local function Pip(bar)
    local width, height = bar.frame:GetWidth(), bar.frame:GetHeight()
    local reach = math.min(bar.to + bar.ahead, 1)
    bar.pip:SetSize(math.max(height * PIP_WIDE, 1), height)
    bar.pip:ClearAllPoints()
    bar.pip:SetPoint("CENTER", bar.frame, "LEFT", width * reach, 0)
    bar.pip:SetShown(bar.ahead > 0 and reach >= PIP_EDGE and reach <= 1 - PIP_EDGE)
end

-- The flare, at the fill's end: the one piece that moves on every step of a rise.
local function Flare(bar)
    if not bar.flare then return end
    local width, height = bar.frame:GetWidth(), bar.frame:GetHeight()
    bar.flare:SetSize(height * FLIPBOOK.wide, height)
    bar.flare:ClearAllPoints()
    bar.flare:SetPoint("RIGHT", bar.frame, "LEFT", width * bar.shown + 1, 0)
end

-- Every piece that follows the length and the height: the dividers, the pip, the flare (a new size).
local function Layout(bar)
    local width, height = bar.frame:GetWidth(), bar.frame:GetHeight()
    local count = #bar.dividers + 1
    for index, divider in ipairs(bar.dividers) do
        divider:SetSize(math.max(height * DIVIDER_WIDE, 1), height)
        divider:ClearAllPoints()
        divider:SetPoint("CENTER", bar.frame, "LEFT", math.floor(width * index / count + 0.5), 0)
    end
    Pip(bar)
    Flare(bar)
end

local function Kind(bar)
    return Core.Motion.Kind(bar.options.motion and Core.Safe("bar", bar.options.motion))
end

-- The value the fill stands for now, on its way or there.
local function Tell(bar, value)
    bar.standing = value
    if bar.options.moved then Core.Safe("bar", bar.options.moved, value, bar.most) end
end

-- The game's flare at the fill's end, running for that many seconds; or put away (none).
local function Flaring(bar, seconds)
    if not bar.flare then return end
    bar.flaring:Stop()
    bar.flare:SetShown(seconds ~= nil)
    if not seconds then return end
    bar.flipbook:SetDuration(seconds)
    bar.flaring:Play()
end

-- The fill at its value: a rise ended, or there was none to show.
local function Settle(bar)
    bar.shown = bar.to
    bar.filled:SetValue(bar.to)
    Flaring(bar, nil)
    Flare(bar)
    Tell(bar, bar.value)
end

-- One step of a rise, that share of its time: the fill and its flare.
local function Rise(bar, progress)
    if progress >= 1 then return Settle(bar) end
    local share = Core.Motion.Ease(Bar.CURVE, progress)
    bar.shown = bar.from + (bar.to - bar.from) * share
    bar.filled:SetValue(bar.shown)
    Flare(bar)
    Tell(bar, bar.started + (bar.value - bar.started) * share)
end

function methods:SetValue(value, most, ahead)
    value, most = tonumber(value) or 0, tonumber(most) or 0
    local share = most > 0 and Clamp(value / most, 0, 1) or 1
    self.ahead = most > 0 and Clamp((tonumber(ahead) or 0) / most, 0, 1) or 0
    -- A gain: more of the same most than before. Anything else is there at once.
    local gain = self.value ~= nil and most == self.most and value > self.value and share > self.shown
    local started = self.standing or self.value or value
    self.value, self.most, self.to = value, most, share
    self.coming:SetValue(math.min(share + self.ahead, 1))
    self.rising:Stop()
    Pip(self) -- what is still to come and its pip are at their new place at once
    if not gain or Kind(self).time <= 0 then return Settle(self) end
    self.from, self.started = self.shown, started
    local seconds = Bar.RISE + (Bar.RISE_WHOLE - Bar.RISE) * (share - self.shown)
    Flaring(self, seconds)
    self.rising:Run(seconds)
end

-- One step of a change of size, that share of the way.
local function Size(bar, progress)
    local share = Core.Motion.Share(bar.kind, progress)
    bar.frame:SetSize(math.max(bar.fromWidth + (bar.toWidth - bar.fromWidth) * share, 1),
        math.max(bar.fromHeight + (bar.toHeight - bar.fromHeight) * share, 1))
end

function methods:SetSize(width, height)
    local frame = self.frame
    self.fromWidth, self.fromHeight = frame:GetSize()
    self.toWidth, self.toHeight = width or self.fromWidth, height or self.fromHeight
    self.kind = Kind(self)
    self.sizer:Run(self.kind.time)
end

-- The game's flare as a texture with its flipbook, or nil where the game cannot play one.
local function MakeFlare(bar, over, atlas)
    local flare = over:CreateTexture(nil, "OVERLAY")
    flare:SetAtlas(atlas)
    flare:SetBlendMode("ADD")
    flare:Hide()
    local ok, flaring, flipbook = pcall(function()
        local group = flare:CreateAnimationGroup()
        local book = group:CreateAnimation("FlipBook")
        book:SetFlipBookRows(FLIPBOOK.rows)
        book:SetFlipBookColumns(FLIPBOOK.columns)
        book:SetFlipBookFrames(FLIPBOOK.frames)
        return group, book
    end)
    if not ok then return Core.NoteError("bar", flaring) end
    bar.flare, bar.flaring, bar.flipbook = flare, flaring, flipbook
end

function Bar.New(parent, options)
    options = options or {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(options.width or 240, options.height or 12)
    frame:SetClipsChildren(true) -- the flare on a short fill stays inside the bar
    local bar = setmetatable({ frame = frame, options = options, shown = 0, to = 0, from = 0, ahead = 0, dividers = {} },
        { __index = methods })

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas(Bar.ART.background)
    background:SetAllPoints()
    -- What is still to come lies under the fill: it shows only past the fill's end.
    bar.coming = Fill(frame, Bar.ART.ahead, 1)
    bar.filled = Fill(frame, options.fill or Bar.ART.fill, 2)

    -- Above both: the dividers, the pip, the flare.
    local over = CreateFrame("Frame", nil, frame)
    over:SetAllPoints()
    over:SetFrameLevel(frame:GetFrameLevel() + 3)
    local segments = math.floor(tonumber(options.segments) or tonumber(rawget(_G, "STATUS_BAR_NUM_SEGMENTS")) or 1)
    for index = 1, segments - 1 do
        local divider = over:CreateTexture(nil, "ARTWORK")
        divider:SetAtlas(Bar.ART.divider)
        bar.dividers[index] = divider
    end
    bar.pip = over:CreateTexture(nil, "OVERLAY")
    bar.pip:SetAtlas(Bar.ART.pip)
    bar.pip:Hide()
    MakeFlare(bar, over, options.flare or Bar.ART.flare)

    bar.rising = Core.Motion.Clock(frame, function(progress) Rise(bar, progress) end)
    bar.sizer = Core.Motion.Clock(frame, function(progress) Size(bar, progress) end)
    frame:SetScript("OnSizeChanged", function() Core.Safe("bar", Layout, bar) end)
    Layout(bar)
    return bar
end
