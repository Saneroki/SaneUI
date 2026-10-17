local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Fade
--  How much of a message is seen: fading in, there, fading out, gone. Knows
--  no frames.
--
--  It is kept on the message, never on a row: the list hands its rows from one
--  message to another whenever it lays them out (a new message, a scroll, a
--  slide), and a fade kept on a row would be cut off or begun anew. A message
--  knows where its fade began (from), where it goes (to), since when (since)
--  and for how long (span); what it shows at any time follows from that alone
--  (Alpha). Whoever draws a row asks it, as often as it likes.
--
--  A fade goes to all (1) or to a faded message's opacity (0, or more if set).
--  A fade begins from wherever the message is: one that turns back half way
--  turns back from there, and takes only the time for the rest of the way.
--  How long a whole fade takes, in and out, is a setting (Fade.Times); with
--  no time, or Sane UI's animations off (Core.general.animations), a message is
--  there or not at once. Its way is one of the game's easing curves, slow at
--  both ends (Core.Motion.Ease, Fade.CURVE).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Fade = {}
ns.Fade = Fade

Fade.CURVE = "InOutQuadratic" -- slow at both ends, so neither its start nor its end shows as a step
local fadeIn, fadeOut = Layout.APPEAR, Layout.FADE -- seconds of a whole fade in, and out

-- How long a whole fade in and a whole fade out take; 0: none, at once.
function Fade.Times(inSeconds, outSeconds)
    fadeIn, fadeOut = math.max(inSeconds or 0, 0), math.max(outSeconds or 0, 0)
end

-- How much of the message is seen at that time: 0 nothing, 1 all. A message no fade ever touched is seen.
function Fade.Alpha(entry, now)
    local since = entry.since
    if not since then return entry.to or 1 end
    local t = (now - since) / entry.span
    if t >= 1 then
        entry.since = nil -- the fade is over
        return entry.to
    end
    if t <= 0 then return entry.from end
    return entry.from + (entry.to - entry.from) * Core.Motion.Ease(Fade.CURVE, t)
end

-- Whether it is fading right now.
function Fade.Moving(entry)
    return entry.since ~= nil
end

-- The message fades to `to` (1 seen, 0 gone, or between), from where it is now; at once if instantly.
-- One already on its way there goes on as it was.
function Fade.To(entry, to, now, instantly)
    if entry.to == to and not instantly then return end
    local alpha = Fade.Alpha(entry, now)
    entry.to = to
    local span = (to > alpha and fadeIn or fadeOut) * math.abs(to - alpha)
    if instantly or span <= 0 or (Core.general and Core.general.animations == false) then
        entry.since = nil
        return
    end
    entry.from, entry.since, entry.span = alpha, now, span
end

-- A new message: from nothing, in.
function Fade.Enter(entry, now)
    entry.to = 0
    entry.since = nil
    Fade.To(entry, 1, now)
end
