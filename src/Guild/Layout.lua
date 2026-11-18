local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Guild - Layout
--  Every size and spacing of the guild window in one place, and the arithmetic
--  that follows from the room it has (Doc/guides/gui-development.md, *Layout*).
--  Knows no frames, so the tests can check it.
--
--  The page from its top: the head (the guild's name, its counts, the buttons)
--  with the crest at its left reaching down over the tabs, the row of tabs, the
--  view's title line, the view's small tabs (only where a tab has several
--  views), the view, the status line at its bottom.
-------------------------------------------------------------------------------
local Layout = {}
ns.Layout = Layout

Layout.EDGE = 6          -- from the page's edges
Layout.GAP = 8           -- between panels
Layout.HEAD = 40         -- the head
Layout.CREST = 58        -- the crest ring, reaching from the head over the tabs
Layout.EMBLEM = 46       -- the guild's emblem inside it
Layout.TABS = 32         -- the row of tabs (the game's tab's height)
Layout.TAB_LEFT = 70     -- the first tab from the page's left: right of the crest
Layout.TOOL = 28         -- the view's title line
Layout.SUB = 26          -- the view's small tabs
Layout.STATUS = 22       -- the status line
Layout.STATUS_TIME = 6   -- seconds a status line stays, then it fades
Layout.LEAST = { 860, 560 }  -- the least room the page lays out in
Layout.MOST = { 1180, 860 }  -- the most it wants on a full screen
Layout.BUTTON = 22       -- the game's buttons' height
Layout.ICON = 18         -- a class icon in a list
Layout.ROW = 22          -- a list's row
Layout.TALL_ROW = 32     -- the roster's row: name over class and rank
Layout.HEADER = 20       -- a table's column heads
Layout.PANEL_HEAD = 24   -- a panel's heading
Layout.DETAIL = 260      -- the roster's member page at the right
Layout.LIST = 300        -- the equipment's list of characters at the left
Layout.SLOT = 40         -- an item slot of the doll
Layout.SLOT_GAP = 6
Layout.LEFT_COLUMN = 292 -- the overview's left column
Layout.RIGHT_COLUMN = 268 -- its right column

-- How far down the page the view starts: under the head, the tabs, its title and, with small tabs, them.
function Layout.ViewTop(sub)
    return Layout.HEAD + Layout.TABS + Layout.TOOL + (sub and Layout.SUB or 0)
end

-- The room the page wants on a full screen that large: as much as it can use, never more than the screen.
function Layout.Want(width, height)
    return { math.min(Layout.MOST[1], math.floor(width * 0.64)), math.min(Layout.MOST[2], math.floor(height)) }
end

-- The overview's columns for a body that wide: three (left, middle, right) or, narrow, two (the right one folded
-- under the left). Returns the widths of left, middle, right (right 0 when folded).
function Layout.Overview(width)
    local left, right, gap = Layout.LEFT_COLUMN, Layout.RIGHT_COLUMN, Layout.GAP
    local middle = width - left - right - 2 * gap - 2 * Layout.EDGE
    if middle >= 300 then return left, middle, right end
    middle = width - left - gap - 2 * Layout.EDGE
    return left, math.max(middle, 200), 0
end

-- The days since a day (the server's day numbers), for "last online" and the news.
function Layout.Ago(day, today)
    if not day or not today then return nil end
    return math.max(0, today - day)
end

-- "today", "3 days ago", "2 months ago" for days ago; nil for none.
function Layout.AgoText(days)
    local TEXT = ns.TEXT
    if not days then return nil end
    if days < 1 then return TEXT.seenToday end
    if days < 60 then return TEXT.seenDays:format(days) end
    return TEXT.seenMonths:format(math.floor(days / 30))
end

-- Seconds since a time as the game writes a span ("5 Min", "2 Hr"); nil for none.
function Layout.SinceText(seconds)
    if not seconds then return nil end
    seconds = math.max(0, seconds)
    if seconds < 60 then return ("%d s"):format(seconds) end
    if seconds < 3600 then return ("%d min"):format(math.floor(seconds / 60)) end
    if seconds < 86400 then return ("%d h"):format(math.floor(seconds / 3600)) end
    return ("%d d"):format(math.floor(seconds / 86400))
end
