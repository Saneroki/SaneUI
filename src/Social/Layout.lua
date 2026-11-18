local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Layout
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

Layout.WIDTH, Layout.HEIGHT = 686, 307.5      -- the window at first (as Saneroki has it, 2026-11-18)
Layout.MIN_WIDTH, Layout.MIN_HEIGHT = 180, 130
Layout.LEVEL = 100                             -- the window's frame level: above the action bars (50 and a few)
Layout.INPUT_LEVEL = 13                        -- the line to write in drawn so far above the window: over the messages (their bubbles reach 11 there)
Layout.FADE = 1                                -- seconds a message takes to fade out, at first (a setting: fadeOutTime)
Layout.APPEAR = 0.5                            -- seconds a message takes to fade in, at first (a setting: fadeInTime)
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
-- The line you write in is the game's edit box, 32 high with its plate and a few empty pixels around that.
Layout.INPUT_HEIGHT = 32                       -- its height with one line of text: the button beside it is as high
Layout.INPUT_LINES = 6                         -- it grows with its text, up to so many lines
Layout.INPUT_INSET = 3                         -- its plate is that much smaller than the line, all around
Layout.INPUT_LEFT, Layout.INPUT_BOTTOM = 28, 2 -- its place from the window's corner, right of the button
Layout.GRIP_ROOM = 18                          -- the room the grip takes at the window's lower right
Layout.FACE = 24                               -- the smiley beside the line, before the grip (Picker.lua)
Layout.INPUT_RIGHT = Layout.GRIP_ROOM + Layout.FACE + 2 -- it ends before the smiley

-- The full screen's first layout (Board.lua, Default: Core's board lays out the others): side by side, each as high
-- as the room, the conversations (Conversations.lua) at the left, whose part beside their list holds the chat chosen
-- there (a conversation, the chat or the second chat), and the friends list (Friends.lua, the group finder one of its
-- tabs) at the right: two thirds and one third of the room (SHARES; Saneroki, 2026-11-18: "on the social full screen
-- as default there should only be the conversation window 2/3rd of the fullscreen and one third of the window to the
-- right is the friendslist window"). The guild window comes only when you put it there (the dropdown Windows, the
-- setup's tick: beside the friends list). Each at least as wide as it may be: the conversations TALKS_MIN, the
-- friends list FRIENDS_WIDTH; where the room lacks that, the friends list is left out. All within PAD of the screen
-- and of each other. Without the conversations (want.talks) the chat stands in their place, CHAT_MIN wide at least.
Layout.PAD = SaneUI.Core.Board.PAD                -- (Core's board's)
Layout.SHARES = { talks = 2, friends = 1 }     -- the first layout's widths, as shares of the room
Layout.FRIENDS_WIDTH = 340                     -- the game's friends list is as wide (Blizzard_FriendsFrame)
Layout.FRIENDS_LOW = 220                       -- the friends list at its lowest
Layout.GUILD_LEAST = 0.6                       -- the guild window made smaller to this much of its size at most
Layout.GUILD_LEVEL = 10                        -- the guild window drawn so far above what the full window holds
Layout.CHAT_MIN = 420
Layout.HEADER = SaneUI.Core.Board.HEAD        -- a panel's head: its title and its buttons (Core's board's)
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
-- The conversations' panel (Conversations.lua): the list of them at its left, the one chosen beside it, under a
-- line with its name. The line between the two can be dragged: the list as wide as you leave it (Layout.TalkList).
Layout.TALKS_MIN = 460
Layout.TALK_LIST = 190                         -- the list of conversations, at first
Layout.TALK_LIST_LEAST = 150                   -- the list at its narrowest
Layout.TALK_PAGE = Layout.TALKS_MIN - Layout.TALK_LIST - 1 -- the one chosen beside it, at its narrowest
Layout.TALK_GRIP = 8                           -- the strip over the line between them that the mouse takes
Layout.TALK_ICON = 24                          -- a conversation's icon in that list
Layout.TALK_PART = 24                          -- the head over a part of that list (Whispers, Groups), with the game's +/- before its name
Layout.TALK_HEAD = 28                          -- the line with the name of the one chosen
Layout.VIEW_LEAST = { 300, 160 }              -- a chat view's window, and the chat's, at their smallest

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

-- Words picked in a message to copy (Select.lua) are lit in the grey the game lights picked text with in its own
-- scrolling lists (ScrollingMessageFrame).
Layout.PICKED = { 0.37, 0.37, 0.37 }

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

-- The width of the conversations' list in their panel that wide, as wished (the width it was dragged to; nil: as at
-- first): never narrower than TALK_LIST_LEAST, and the one chosen beside it keeps TALK_PAGE. Whole pixels.
function Layout.TalkList(wished, panelWidth)
    local width = math.floor((tonumber(wished) or Layout.TALK_LIST) + 0.5)
    return math.max(math.min(width, math.floor(panelWidth) - Layout.TALK_PAGE - 1), Layout.TALK_LIST_LEAST)
end

-- Where each part of the full screen stands, in a room that wide and high (what the window holds, under its
-- title bar): { left, top, width, height } from the room's top left corner, whole pixels. want: which parts are
-- wished: friends, talks (true), list (the width the conversations' list was dragged to). A part not wished, or
-- without room, is nil; chat is always there: the conversations' part beside their list and under the line with its
-- name, or their place.
function Layout.Board(width, height, want)
    local pad = Layout.PAD
    local top, high = pad, math.floor(height) - 2 * pad
    local room = math.floor(width) - 2 * pad
    local first = want.talks and "talks" or "chat"
    local least = want.talks and Layout.TALKS_MIN or Layout.CHAT_MIN
    local board = {}
    if want.friends and room - pad >= least + Layout.FRIENDS_WIDTH then
        -- The friends list its share, between its least and what leaves the first its least.
        local free, S = room - pad, Layout.SHARES
        local friends = math.floor(free * S.friends / (S.talks + S.friends))
        friends = math.min(math.max(friends, Layout.FRIENDS_WIDTH), free - least)
        board[first] = { pad, top, free - friends, high }
        board.friends = { pad + free - friends + pad, top, friends, high }
    elseif room >= least then
        board[first] = { pad, top, room, high }
    else -- not even the conversations: the chat alone
        board.chat = { pad, top, room, high }
        return board
    end
    local talks = board.talks
    if talks then
        local beside, under = Layout.TalkList(want.list, talks[3]) + 1, Layout.HEADER + Layout.TALK_HEAD
        board.chat = { talks[1] + beside, talks[2] + under, talks[3] - beside, talks[4] - under }
    end
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
