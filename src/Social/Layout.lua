local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Layout
--  Every size and distance of the chat window, and what follows from the
--  window's width. Plain numbers in, plain numbers out: knows no frames.
--
--  A row is as wide as the list. Somebody else's message:
--      [icon] Name · Guild · 21:07
--             ( the bubble, at most SHARE of what is left )
--  Yours: the same without icon and name, at the right edge. A note (system,
--  emote, achievement): a bubble alone, in the middle, as wide as the others at most.
-------------------------------------------------------------------------------
local Layout = {}
ns.Layout = Layout

Layout.WIDTH, Layout.HEIGHT = 380, 260        -- the window at first
Layout.MIN_WIDTH, Layout.MIN_HEIGHT = 180, 130
Layout.LEVEL = 100                             -- the window's frame level: above the action bars (50 and a few)
Layout.FADE = 1                                -- seconds a message takes to fade out, at first (a setting: fadeOutTime)
Layout.APPEAR = 0.4                            -- seconds a message takes to fade in, at first (a setting: fadeInTime)
Layout.SLIDE = 0.3                             -- seconds the messages take to slide to their new place, at first (slideTime)
Layout.EDGE = 6                                -- from the window's border to what is in it
Layout.SCROLL = 14                             -- room at the right for the scroll bar
Layout.ICON = 28                               -- the round class icon with its ring
Layout.RING = 1                                -- the ring's width
Layout.GAP = 6                                 -- icon to bubble
Layout.HEAD = 18                               -- the line with name, channel and time; follows the text size (Bubble.Size)
Layout.PAD_X, Layout.PAD_Y = 9, 6              -- bubble's edge to its text
Layout.RADIUS = 8                              -- of a bubble's corners, and of the line to write in
Layout.SPACING = 3                             -- row to row
Layout.SHARE = 0.82                            -- of a row's width a bubble may take
Layout.MIN_TEXT = 60
-- The line you write in is the game's edit box, 32 high with a few empty pixels around its art.
Layout.INPUT_HEIGHT = 32                       -- its height with one line of text: the button beside it is as high
Layout.INPUT_LINES = 6                         -- it grows with its text, up to so many lines
Layout.INPUT_INSET = 3                         -- its plate is that much smaller than the edit box, all around
Layout.INPUT_LEFT, Layout.INPUT_BOTTOM = 28, 2 -- its place from the window's corner, right of the button
Layout.GRIP_ROOM = 18                          -- the room the grip takes at the window's lower right
Layout.FACE = 24                               -- the smiley beside the line, before the grip (Picker.lua)
Layout.INPUT_RIGHT = Layout.GRIP_ROOM + Layout.FACE + 2 -- it ends before the smiley

-- The full screen holds panels beside and above the chat (Board.lua): the friends list at the right (the
-- group finder is one of its tabs), a second chat with its own choice of chats above the chat, all within PAD
-- of the screen and of each other. The friends list is left out where it would leave the chat narrower than
-- CHAT_MIN; the second chat takes SPLIT of the height (a setting), and is left out where the chat
-- under it would be lower than CHAT_LOW.
Layout.PAD = 12
Layout.FRIENDS_WIDTH = 340                     -- the game's friends list is as wide (Blizzard_FriendsFrame)
Layout.CHAT_MIN = 420
Layout.CHAT_LOW = 160
Layout.FEED_LOW = 120                          -- the second chat at its lowest
Layout.HEADER = 30                             -- a panel's head: its title and its buttons
Layout.ROW = 34                                -- a row of the friends list and of the group finder
Layout.FOOT = 30                               -- a panel's foot: its buttons
-- The friends list's panel (Friends.lua) holds more than one list: tabs under its head, a line with the search
-- box and the filter under the tabs where the list shown can be searched, and a line of its own where a list
-- needs one (the box to add a friend, the raid's switches).
Layout.TABS = 34                               -- the row of tabs (the game's MinimalTabTemplate stands on its line)
Layout.TAB_PAD = 20                            -- a tab's room around its words, at most; less where the row is full
Layout.TOOLS = 28                              -- the search box and the filter
Layout.LINE = 28                               -- a list's own line above it
Layout.INVITE = 24                             -- the button at a row's right to ask a friend into your group

-- The only colours of our own: the ring around the icon of somebody who is something to you. The
-- bubbles' fill is a setting (bubbleBack, bubbleColor: Bubble.Clear), the same for all; yours differ by
-- their side. Everything else is the game's (chat and class colours). The window itself has no fill
-- and no border.
Layout.TIES = {
    none = { 1.00, 1.00, 1.00 },   -- white: a stranger
    friend = { 1.00, 0.82, 0.00 }, -- yellow
    guild = { 0.25, 1.00, 0.25 },  -- green
    raid = { 0.64, 0.30, 0.94 },   -- purple
    party = { 0.30, 0.60, 1.00 },  -- blue
}

-- The width of a row in a window that wide.
function Layout.RowWidth(windowWidth)
    return math.max(math.floor(windowWidth) - 2 * Layout.EDGE - Layout.SCROLL, Layout.MIN_TEXT)
end

-- What the list gives up at its bottom for a line to write in of that height.
function Layout.Input(height)
    return Layout.INPUT_BOTTOM + height - Layout.EDGE
end

-- The height of the line to write in for a text that high, whose lines are that high. One line is
-- INPUT_HEIGHT; every further one adds its own height, up to INPUT_LINES.
function Layout.InputHeight(textHeight, lineHeight)
    local more = math.min(math.max(textHeight - lineHeight, 0), (Layout.INPUT_LINES - 1) * lineHeight)
    return Layout.INPUT_HEIGHT + math.ceil(more)
end

-- The height of the list in a window that high; input: the height of the line to write in, if it is shown;
-- top: where the list starts from the window's top, EDGE at first (lower under Core's title bar while the
-- window fills the screen: Window.lua, Top).
function Layout.ListHeight(windowHeight, input, top)
    return math.floor(windowHeight) - (top or Layout.EDGE) - Layout.EDGE - (input and Layout.Input(input) or 0)
end

-- Where each part of the full screen stands, in a room that wide and high (what the window holds, under its
-- title bar): { left, top, width, height } from the room's top left corner, whole pixels. want: which
-- panels are wished (friends, feed); share: the second chat's part of the height, 0..1. A panel not
-- wished, or without room, is nil; chat is always there.
function Layout.Board(width, height, want, share)
    local pad = Layout.PAD
    local left, right = pad, math.floor(width) - pad
    local top, bottom = pad, math.floor(height) - pad
    local friends = want.friends and Layout.FRIENDS_WIDTH + pad or 0
    if right - left - friends < Layout.CHAT_MIN then friends = 0 end
    local board = {}
    if friends > 0 then
        board.friends = { right - Layout.FRIENDS_WIDTH, top, Layout.FRIENDS_WIDTH, bottom - top }
        right = right - friends
    end
    local tall = bottom - top
    local feed = want.feed and math.max(math.floor(tall * math.min(math.max(share or 0, 0), 1)), Layout.FEED_LOW) or 0
    if feed > 0 and tall - feed - pad < Layout.CHAT_LOW then feed = 0 end
    if feed > 0 then
        board.feed = { left, top, right - left, feed }
        top = top + feed + pad
    end
    board.chat = { left, top, right - left, bottom - top }
    return board
end

-- The widest a message's text may be in a row that wide. Whole pixels: half ones blur.
function Layout.TextWidth(rowWidth, side)
    if side == "center" then return math.max(math.floor(rowWidth * Layout.SHARE) - 2 * Layout.PAD_X, Layout.MIN_TEXT) end
    local room = rowWidth - Layout.ICON - Layout.GAP -- yours keep the same distance from the left edge
    return math.max(math.floor(room * Layout.SHARE) - 2 * Layout.PAD_X, Layout.MIN_TEXT)
end

-- The bubble around a text of that size.
function Layout.Bubble(textWidth, textHeight)
    return math.ceil(textWidth) + 2 * Layout.PAD_X, math.ceil(textHeight) + 2 * Layout.PAD_Y
end

-- The height of the whole row.
function Layout.RowHeight(side, textHeight)
    local _, height = Layout.Bubble(0, textHeight)
    if side == "center" then return height end
    return Layout.HEAD + height
end
