local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Window
--  The window: the list of messages, a window of Core's of the kind screen
--  (Core.Window.KINDS: on the screen all the time, docked at first in the lower
--  left corner, no title bar while small). Moving, sizing (only in Blizzard's
--  Edit Mode: there Core lays its box over the window and puts a grip in a
--  corner), docking to a screen edge and keeping the place are Core's
--  (Core/Window.lua); what follows from a new size is ours. The list stands in
--  what Core lays out for what a window holds (window.inside): the whole window
--  while it is small, under Core's title bar while it fills the screen.
--
--  It has no background and no border: the messages stand over the game, and
--  a click on them goes through to the game, unless it is on a link or a name
--  (Links.lua). The window takes only the mouse's coming (Core.Hover): then the
--  button for the line to write in is there (Chrome), and a watch looks whether
--  the mouse is still there, until it has gone. The scroll bar is there while
--  the list is scrolled up from its newest message (Bar).
--
--  Built from the game's parts: its scrolling list (which only makes rows for
--  the messages in view) and its scroll bar.
--  Made when it is first shown; while it is hidden nothing is drawn, the
--  messages only go into the log.
--
--  A change of the width wraps every message anew (Bubble.Measure), once the
--  sizing is over; a change of the height is the list's own business.
--
--  While the window is open the game's own chat may be out of sight (a
--  setting; Native.lua) and its edit box sits at the bottom of the window
--  (Input.lua); the list ends above it while it is shown (Room).
--
--  Few messages stand at the bottom, the newest lowest: the list gets as much
--  empty room above them as they leave free (Settle).
--
--  A message fades a while after it came, each by itself (Fade.lua). The
--  mouse over the window does not bring them back; the wheel does (Reveal), and
--  so does the line to write in: then all are there to read, until the mouse
--  leaves the window at the newest message, or the line closes. While the
--  window fills the screen none fades at all (FadeAfter).
--
--  Nothing jumps: a new message fades in, and when the messages move up, for a
--  new one or for the line to write in, they slide there (Slide). A scroll with
--  the wheel glides, as the game's list can (SetInterpolateScroll).
--
--  Fading and sliding have nothing to do with each other. A message's fade is
--  its own, kept on it (Fade.lua); a row only shows it (Paint), whichever
--  message the list gives the row. The slide moves the list's content, not a
--  row, and touches no alpha.
--
--  A message the list's top edge cuts through is not shown (Trim).
--
--  Docked to a screen edge, the window fills the screen when the mouse is
--  pushed against that edge, on a background that hides the game as much as
--  set, and goes back when it is pushed there again (Core's Edge.lua, as the
--  section Expand window of our settings says). Full, nothing behind it takes
--  the mouse, and every message is there to read for as long as it stands
--  full, wherever the mouse is (on a panel, on the guild window). The
--  messages stay in sight and at the list's bottom while the size moves, and
--  are wrapped for the new width once it stands. Full, Core's dropdown Classic windows offers the game's own chat
--  (ours is put away), friends list and group finder (ns.CLASSIC, Social.lua). Full, the list takes the
--  mouse too: a drag over the messages picks their words to copy (Select.lua).
--
--  The chat stands in a frame of its own (column): all of what the window
--  holds, but once the window stands full with its windows on Core's board
--  (Board.lua: the conversations, the friends list, the guild window, the
--  chat, the chat views, as the layout chosen has them), its part of the full
--  screen: the body of the chat's own window, or else beside the
--  conversations' list while the chat is the one chosen there; a layout with
--  neither has it out of sight. A conversation or a chat view chosen there
--  (Feed.lua: a list of its own), the frame is out of sight, and a
--  conversation's own line is the one to write in. The game's line opened
--  then (Enter, /, a reply) belongs to the chat: the chat is chosen (Room).
--  Messages of the chat that come while it is out of sight on the full screen
--  are not seen yet (Window.Unread: its row there is lit). The list, the
--  button for the line to write in, the line and its smiley hang on that
--  frame; what is measured for them is its size (Area). The panels go when the
--  window starts back, and the chat has the whole window.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble, Fade = ns.Layout, ns.Bubble, ns.Fade
local Window = {}
ns.Window = Window

local frame, box, view, provider
local handle         -- Core's part of the window: moves, sizes and docks it, keeps its place
local column         -- where the chat stands: all of what the window holds, or its part of the full screen
local board          -- the full screen's parts as they stand (Layout.Board); nil: the chat has the whole window
local picked = "chat" -- chosen in the full screen's conversations: "chat", or nil (a conversation or a chat view)
local unread = 0     -- messages of the chat that came while it stood out of sight on the full screen
local rowWidth       -- of the list, from the window's width
local writing        -- the height of the line to write in while it is shown
local awake, hover   -- the mouse is over the window; what sees it come and leave (Core.Hover)
local revealed       -- a scroll has brought every message back
local slide          -- the messages sliding to their place (Core.Motion.Slide)
local scroll         -- the scroll bar
local write          -- the button for the line to write in: shown with the mouse over the window
local list = {}      -- the messages on show: the log's, without those of the chats switched off
local stale = true   -- the log has messages the list does not show
-- The list is at the newest message (or everything fits): it stays there when a message comes
-- or its size changes. Scrolled up to read, it stays where it is.
local follow = true

-- The scroll bar, while the list is scrolled up: at the newest message it is of no use.
local function Bar()
    scroll:SetShown(not follow and box:IsShown())
end

local function ToEnd()
    follow = true
    box:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
    Bar()
end

-- Rows the list's top edge cuts through are taken out of sight, the others shown.
local edge
local function TrimRow(row)
    local top = row:GetTop()
    Bubble.Cut(row, top ~= nil and top > edge)
end

local function Trim()
    edge = box:GetTop()
    if not edge then return end
    edge = edge + 0.5 -- a row that starts at the edge is whole
    box:ForEachFrame(TrimRow)
end

-- The list may tell of a scroll before it has put the rows in their new places: look again a frame later.
local TrimLater = Core.Later(function()
    if frame:IsShown() then ns.Guarded(Trim) end
end)

local function Laid()
    ns.Guarded(Trim)
    TrimLater()
end

-- Every message there to read, or fading as its age says; both gently.
local function Reveal(on)
    if revealed == on then return end
    revealed = on
    Window.Refade()
end

local function Revealed()
    ns.Guarded(Reveal, true)
end

-- The messages moved up by that much at once (down, if less than 0): they are put back where they
-- were and slide up to their place (Core.Motion.Slide). A slide still going on is taken into the new one.
local slides = true -- the setting: slides at all
local function Slide(by)
    if by == 0 or not slides or not frame:IsVisible() then return end
    slide:From(0, -by)
end

-- Only a scroll of yours brings the messages back (the wheel, Revealed): the list tells of a scroll
-- for its own moves too, a new message at its end among them, and for a moment is not at its end.
-- Back at the newest message with the mouse away, they fade again.
local function Scrolled()
    follow = box:IsAtEnd() or not box:HasScrollableExtent()
    Bar()
    Laid()
    if follow and revealed and not frame:IsMouseOver() then Reveal(false) end
end

-- The chat's width and height: what the window holds (under Core's title bar while that is there), or the
-- chat's part of the full screen.
local function Area()
    local chat = board and board.chat
    if chat then return chat[3], chat[4] end
    return frame:GetWidth(), frame:GetHeight() - (handle.top or 0)
end

-- What the chat's frame shows: the chat, but on a full screen whose conversations hold it only while it is the one
-- chosen there (nil: the frame is out of sight). In a layout with the chat's own window it always stands there; in
-- one with neither, it has no place: out of sight.
local function Shows()
    if not board or board.own then return "chat" end
    if not board.talks then return nil end
    return picked
end

-- The chat's frame where Area says, with what it shows.
local function Seat()
    local chat = board and board.chat
    column:ClearAllPoints()
    if chat then
        column:SetPoint("TOPLEFT", handle.inside, "TOPLEFT", chat[1], -chat[2])
        column:SetSize(chat[3], chat[4])
    else
        column:SetPoint("TOPLEFT", handle.inside, "TOPLEFT")
        column:SetPoint("BOTTOMRIGHT", handle.inside, "BOTTOMRIGHT")
    end
    if not box then return end
    local shows = Shows()
    column:SetShown(shows ~= nil)
    box:SetShown(shows == "chat")
    Bar()
    if shows and unread > 0 then
        unread = 0 -- in sight again: its new messages are seen
        ns.Conversations.Said()
    end
end

-- The room above the messages that puts them at the list's bottom; none once they fill it.
-- True if it changed. A message's height is known after its first measuring.
local function Settle()
    local _, area = Area()
    local height = Layout.ListHeight(area, writing)
    local total = 0
    for index = #list, 1, -1 do
        total = total + Bubble.Measure(list[index], rowWidth) + (index > 1 and Layout.SPACING or 0)
        if total >= height then break end
    end
    local room = math.max(height - total, 0)
    local padding = view:GetPadding()
    if padding:GetTop() == room then return false end
    padding:SetTop(room)
    return true
end

-- Not of a chat that is switched off in the list of what to show (Menu.lua).
-- What is typed into the search box of the full window's title bar (Core's): every word must be in the
-- message's text as it reads (Core.Fuzzy.Plain: without colours, links' codes and icons), its speaker's name
-- or its chat's, as Core's fuzzy finding finds letters; nil: no search. The list is at most a few hundred
-- messages: it is searched at once (Fuzzy.Filter is for longer ones). The chat views (Feed.lua) find by it too.
local query

function Window.Found(entry)
    return not query or Core.Fuzzy.Match(query, Core.Fuzzy.Plain(entry.text or ""), entry.name, entry.label,
        entry.name and Core.People and Core.People.Shown(entry.name)) ~= nil
end

local function Visible(entry)
    return ns.Channels.Shown(entry.group) and Window.Found(entry)
end

local function Fill()
    stale = false
    wipe(list)
    for _, entry in ipairs(ns.Log.list) do
        if Visible(entry) then list[#list + 1] = entry end
    end
    provider:Flush()
    Settle()
    provider:InsertTable(list)
    ToEnd()
    Window.Refade() -- a message the list did not have before is as it is now, at once
    ns.Conversations.Said() -- the chat's row in the full screen's conversations shows the last anew
end

-- After how many seconds a message fades right now; nil: it does not (fading out is off, or every
-- animation, or the messages are there to read: revealed, written to, or the window fills the screen).
local function FadeAfter()
    local options = ns.options
    if revealed or writing or (handle.edge and handle.edge.full) or not (options.animations and options.fade) then return nil end
    return options.fadeAfter
end

-- How much of a faded message is still seen: nothing, or the opacity set.
local function Faded()
    local options = ns.options
    return options.fadeFloorOn and math.min(math.max(options.fadeFloor / 100, 0), 1) or 0
end

-- Whether a message is to be seen now: always, or until its time is over.
local function Wanted(entry, now, after)
    return not after or entry.at + after > now
end

-- Every row in view shows how much of its message is seen. While one of them fades, the window
-- does this every frame (Step); once none does, it stops.
local paintAt, moving
local function PaintRow(row, entry)
    row:SetAlpha(Fade.Alpha(entry, paintAt))
    if Fade.Moving(entry) then moving = true end
end

local function Paint()
    paintAt, moving = GetTime(), false
    box:ForEachFrame(PaintRow)
    return moving
end

local Step = ns.Guard(function()
    if not Paint() then frame:SetScript("OnUpdate", nil) end
end)

local function Run()
    frame:SetScript("OnUpdate", Step)
end

-- The messages are in the order they came, so those whose time is over are the first of the list:
-- oldest is the index of the first still in by its age (one past the end: none is). One timer looks
-- at the next whose time runs out (dueAt) and fades it, and those behind it that are due too, then
-- sets the timer for the next; the rest of the list is not walked. A timer set for a time that is no
-- longer due (the messages were revealed, the window hidden, a later time set since) does nothing; one
-- function for all of them, no closure per timer. Refade walks the whole list and sets oldest anew.
local oldest, dueAt = 1, nil
local Expire

local function Next(now, after)
    local entry = after and list[oldest]
    dueAt = entry and entry.at + after or nil
    if dueAt then C_Timer.After(dueAt - now + 0.01, Expire) end
end

local function Due()
    local now = GetTime()
    if not dueAt or now < dueAt - 0.001 then return end
    local after, faded = FadeAfter(), Faded()
    if not after then
        dueAt = nil
        return
    end
    while list[oldest] and not Wanted(list[oldest], now, after) do
        Fade.To(list[oldest], faded, now)
        oldest = oldest + 1
    end
    Next(now, after)
    if Paint() then Run() end
end

Expire = ns.Guard(Due)

-- The settings of fading and sliding: how long a fade in and out takes (fading in switched off: at
-- once), whether the messages fade out at all and how far, whether they slide and how fast. All
-- animations off: nothing fades or slides, and every message stays.
function Window.Animate()
    local options = ns.options
    local all = options.animations
    Fade.Times(all and options.fadeInOn and options.fadeInTime or 0, all and options.fadeOutTime or 0)
    slides = all and options.slide and options.slideTime > 0 or false -- a slide of no time is none
    if not frame then return end
    slide:SetTime(options.slideTime)
    if not slides then slide:Stop() end
    Window.Refade(not all) -- all off: what fades now is where it goes at once
end

-- Every message anew: in if it is to be seen, out if not, each from where it is now. instantly: no
-- fade, for messages that came while the window was hidden.
function Window.Refade(instantly)
    if not frame then return end
    local now, after, faded = GetTime(), FadeAfter(), Faded()
    oldest = nil
    for index, entry in ipairs(list) do
        local wanted = Wanted(entry, now, after)
        if wanted then oldest = oldest or index end
        Fade.To(entry, wanted and 1 or faded, now, instantly or entry.to == nil)
    end
    oldest = oldest or #list + 1
    Next(now, after)
    -- At once: a change of no time is seen now, not a frame later.
    if Paint() then Run() end
end

-- The button for the line to write in: there while the mouse is over the window.
local function Chrome()
    write:SetShown(awake or false)
end

local function Asleep()
    awake = false
    Chrome()
end

-- The mouse came over the window (Core.Hover: a held button counts, a drag may leave it): its button is there.
local function Wake()
    awake = true
    Chrome()
end

-- The mouse has gone. Scrolled up, the messages stay to read on, until the list is back at its newest.
local function Left()
    Asleep()
    if follow then Reveal(false) end
end

-- The list calls these while it scrolls, outside our own guard, and for every message whenever one
-- comes. A height of nothing would stop it. One measured already is known without a guard.
local function Height(_, entry)
    return Bubble.Known(entry, rowWidth) or ns.Guarded(Bubble.Measure, entry, rowWidth) or 1
end

local function DrawRow(row, entry)
    Bubble.Init(row, entry, rowWidth)
    row:SetAlpha(Fade.Alpha(entry, GetTime()))
    if Fade.Moving(entry) then Run() end
end

local function Draw(row, entry)
    ns.Guarded(DrawRow, row, entry)
end

-- The list tells of a scroll in the middle of its own work too: what counts is how it was before.
local function Rewrap()
    local stick = follow
    Settle()
    box:Rebuild(ScrollBoxConstants.RetainScrollPosition)
    if stick then ToEnd() end
end

-- The text has another size: every message is measured anew.
function Window.Resize()
    if not frame then return end
    Bubble.Size(ns.options.textSize)
    Rewrap()
    ns.Feed.Rewrap()
    ns.Safe("conversations", ns.Conversations.Rewrap)
end

-- The bubbles are more or less solid, or the chats named otherwise, or a player's alias changed: every row
-- in view is drawn anew, in the chat and in the full screen's chat views and conversations.
function Window.Repaint()
    if not frame then return end
    Bubble.Opacity(ns.options.bubbleOpacity)
    Bubble.Brief(ns.options.shortNames)
    ns.Input.Paint()
    Rewrap()
    ns.Feed.Rewrap()
    ns.Safe("conversations", ns.Conversations.Rewrap)
end

-- The list is higher or lower now: the messages still stand at its bottom.
local function Resettle()
    if Settle() then box:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
    if follow then ToEnd() end
end

-- The list ends above the line you write in while that is shown, at the chat's edge otherwise.
local function Bottom(input)
    box:SetPoint("BOTTOMRIGHT", column, "BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE + (input and Layout.Input(input) or 0))
end

-- input: the height of the line to write in; false: it is gone. It grows with its text. Opened while a conversation
-- or a chat view is chosen on the full screen, the line is the chat's: the chat is chosen.
local function Room(input)
    local was, stick = writing, follow
    writing = input
    Bottom(input)
    Resettle()
    if stick then Slide((input and Layout.Input(input) or 0) - (was and Layout.Input(was) or 0)) end
    if not was ~= not input then Window.Refade() end
    if input and not Shows() then ns.Safe("conversations", ns.Conversations.Chat) end
end

-- The game's line is in use in the window now (not closed, not at rest).
function Window.Writing()
    return writing and true or false
end

-- The last message on show: for the chat's row in the conversations' list.
function Window.Last()
    return list[#list]
end

-- How many messages of the chat came while it stood out of sight on the full screen, and the chat colour of the
-- last (its row in the conversations' list is lit for them).
function Window.Unread()
    local last = unread > 0 and list[#list]
    return unread, last and { last.r or 1, last.g or 1, last.b or 1 } or nil
end

-- Chosen in the full screen's conversations: the chat ("chat"), or a conversation or a chat view (nil).
function Window.Pick(what)
    picked = what == "chat" and "chat" or nil
    ns.Select.Clear() -- what was picked to copy stood in what the frame showed
    if not frame then return end
    Seat()
    if what == "chat" then Resettle() end
end

-- The chat is that wide now: its messages are wrapped for it.
local function Fit(width)
    local now = Layout.RowWidth(width)
    if now == rowWidth then return false end
    rowWidth = now
    return true
end

-- Core's window has placed ours: when it was built, after every drag and every sizing, for
-- /sane social reset, and once it has filled the screen or is back. The messages are wrapped for its
-- width now, once, not on every step of a sizing; the game tells of the new size a moment later.
-- A new height alone: the messages stand at the list's bottom anew. The line to write in is as wide as the window
-- now, and drawn in the window's layer, which is higher while it fills the screen.
local function Refit()
    if Fit((Area())) then Rewrap() else Resettle() end
end

-- The full screen's panels as the window stands: there while it stands full (Board.lua), the chat in its
-- part of the screen; gone at its size, the chat in the whole window.
local function Lay()
    local full = handle.edge and handle.edge.full
    board = full and ns.Board.Show(handle.inside, frame:GetWidth(), frame:GetHeight() - (handle.top or 0)) or nil
    if not full then ns.Board.Hide() end
    Seat()
end

local function Placed()
    ns.Guarded(Lay)
    ns.Guarded(Refit)
    ns.Guarded(ns.Input.Grow)
    ns.Guarded(ns.Input.Layer)
end

-- The panels wished on the full screen changed (Board.lua): laid out anew, if it stands full now.
function Window.Reboard()
    if frame and handle.edge and handle.edge.full and not (handle.edge.clock and handle.edge.clock:IsRunning()) then Placed() end
end

-- It has begun to fill the screen (full) or to go back: its layer has changed. Full, every message is there to
-- read (FadeAfter), and back at its size still, until the mouse leaves it at the newest one; if the mouse left
-- meanwhile (it went over the guild window), those whose time is over fade on the way back. The panels go at
-- once then, and the chat has the whole window again.
local function Filled(full)
    ns.Select.Allow(box, full) -- full, words are picked out of its messages to copy; at its size a click goes into the game
    ns.Input.Layer()
    Chrome()
    if full then Reveal(true) else Window.Refade() end
    if not full and board then
        board = nil
        ns.Board.Hide()
        Seat()
    end
end

-- How it fills the screen: as its own setting says, or the general one; all animations off, at once.
local function Kind()
    return ns.options.animations and ns.options.motion or "off"
end

-- The search box in the full window's title bar was typed into (Core's, "" when emptied): only the
-- messages that match are on show, all of them again once it is empty.
function Window.Search(text)
    query = Core.Fuzzy.Query(text)
    Window.Refill()
    ns.Feed.Refill()
    ns.Board.Search(text)
end

-- While the window is sized the messages keep their wrapping (Refit wraps them when it is over) and
-- only stand at the list's bottom anew. The line to write in is as wide as the window. Also on every
-- frame of its way to the whole screen and back: the messages stay in sight and in place all the
-- way (their heights are known for the wrapping they keep), and Placed wraps them once it stands.
local function Sized()
    ns.Guarded(Resettle)
    ns.Guarded(ns.Input.Grow)
end

-- Its first place and size (/sane social reset).
function Window.Reset()
    if frame then handle:Reset() end
end

local function Build()
    -- Where the action bars are, and above them. Everything in the window is its child and drawn with it.
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(Layout.LEVEL)

    handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, title = ns.TEXT.title, edge = ns.options, classic = ns.CLASSIC,
        native = ns.NATIVE, close = ns.Close, search = function(text) ns.Guarded(Window.Search, text) end,
        first = { dock = "BOTTOMLEFT", width = Layout.WIDTH, height = Layout.HEIGHT },
        minWidth = Layout.MIN_WIDTH, minHeight = Layout.MIN_HEIGHT,
        docked = Placed, motion = Kind,
        filled = function(full) ns.Guarded(Filled, full) end,
    })
    ns.Board.Take(handle) -- its full screen: Social's windows on Core's board
    -- Only the mouse's coming: a click on the window still goes into the game.
    hover = Core.Hover(frame, { every = 0.2, label = ns.name .. ": mouse",
        enter = function() ns.Guarded(Wake) end, leave = function() ns.Guarded(Left) end })

    column = CreateFrame("Frame", nil, frame)
    Seat()

    -- Opens and closes the line to write in, in the corner where that line starts and as high as it.
    -- The art is the game's own chat button's. It and the list are the chat frame's: out of sight with it.
    write = CreateFrame("Button", nil, column)
    write:SetSize(Layout.INPUT_HEIGHT, Layout.INPUT_HEIGHT)
    write:SetPoint("BOTTOMLEFT", column, "BOTTOMLEFT", 0, Layout.INPUT_BOTTOM)
    write:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
    write:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
    write:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    write:SetScript("OnClick", function(self) ns.Guarded(ns.Input.Toggle, self) end)

    box = CreateFrame("Frame", nil, column, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", column, "TOPLEFT", Layout.EDGE, -Layout.EDGE)
    Bottom(false)
    scroll = CreateFrame("EventFrame", nil, column, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 14) -- ends above the grip

    Bubble.Size(ns.options.textSize)
    Bubble.Opacity(ns.options.bubbleOpacity)
    Bubble.Brief(ns.options.shortNames)
    Bubble.Ruler(frame)
    view = CreateScrollBoxListLinearView(0, 0, 0, 0, Layout.SPACING)
    view:SetElementExtentCalculator(Height)
    view:SetElementInitializer("Frame", Draw)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, scroll, view)
    box:SetInterpolateScroll(true)
    scroll:SetInterpolateScroll(true)
    box:HookScript("OnMouseWheel", ns.Guard(Revealed)) -- at the newest message too, where there is nothing to scroll
    slide = Core.Motion.Slide(box.ScrollTarget, ns.options.slideTime)
    provider = CreateDataProvider()
    box:SetDataProvider(provider)
    Window.Animate()
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, ns.Guard(Scrolled), Window)
    box:RegisterCallback(BaseScrollBoxEvents.OnLayout, ns.Guard(Laid), Window)
    ns.Select.Attach(box, list)
    Chrome()
    Bar()

    frame:SetScript("OnSizeChanged", ns.Guard(Sized))

    handle:Place() -- where it was left; at its first place and size if it never was moved
end

-- While chat is locked down (a fight, a dungeon) the game hands addons no messages (Log.Read leaves
-- them out); then only its own chat can show them.
local function Locked()
    return C_ChatInfo and Core.Ask(C_ChatInfo.InChatMessagingLockdown) or false
end

-- The game's own chat next to our window, or out of sight while ours is open: a setting. Always on
-- show while chat is locked down; the game tells when that begins and ends (Social.lua).
function Window.Native()
    if frame and frame:IsShown() and not ns.options.showNative and not Locked() then
        ns.Native.Hide()
    else
        ns.Native.Show()
    end
end

-- The button on the game's chat that brings ours back (Core's, ns.NATIVE): there only while ours is away.
local function Back(away)
    local button = handle and handle:Attach()
    if button then button:SetShown(away and not ns.off) end
end

-- Shown, the window is the chat: the game's edit box comes here, and its chat goes out of sight if set so.
-- As Core's window was left: filling the screen again if it was left so (Open).
function Window.Show()
    if not frame then Build() end
    if ns.off then return end -- building it failed half way, and the game's chat is back
    handle:Remember("native", nil) -- ours is the one chosen
    handle:Open()
    Back(false)
    if stale then Fill() end
    Window.Refade(true) -- what came or ran out meanwhile is as it is now, at once
    Window.Native()
    ns.Input.Take(frame, Room, column)
end

-- Hidden, the game's chat is back as it was.
function Window.Hide()
    if not frame then return end
    frame:Hide()
    ns.Select.Allow(box, false)
    board = nil
    ns.Board.Hide()
    Seat()
    hover:Stop()
    revealed, dueAt = nil, nil
    frame:SetScript("OnUpdate", nil)
    Asleep()
    ns.Input.Release()
    ns.Native.Show()
    Back(true)
end

-- Put away (the switch Chat window off, also at login): the window is made, out of sight, so the game's chat
-- has its button to bring ours back; Core's window keeps that the game's is chosen (its native).
function Window.Away()
    if not frame then Build() end
    if ns.off then return end
    Window.Hide()
    handle:Remember("native", true)
end

-- Ours or the game's, as the switch Chat window says: the one place it is kept (Social.lua, Choose).
function Window.Follow()
    if ns.options.window then Window.Show() else Window.Away() end
end

-- A new message. The log lets its oldest go a batch at a time (Log.Add): those leave the list
-- together, in one update of it. The full screen's chat views hear of it first (Feed.lua), and the
-- conversations' list, whose rows of the chat and the chat views show the last message. One of the chat's that
-- comes while the chat stands out of sight on the full screen is not seen yet.
ns.Log.added = function(entry)
    ns.Feed.Added(entry)
    if not frame or not frame:IsShown() then
        stale = true
        ns.Conversations.Said()
        return
    end
    local gone, removed = 0, 0
    while list[gone + 1] and list[gone + 1].gone do gone = gone + 1 end
    local seen = Visible(entry)
    if seen and board and not Shows() then unread = unread + 1 end
    ns.Conversations.Said()
    local stick = follow
    -- Scrolled up, what you read stays where it is: the list keeps its offset from the top, and the
    -- rows that leave were above it.
    if not stick then
        for index = 1, gone do removed = removed + Bubble.Measure(list[index], rowWidth) + Layout.SPACING end
    end
    if gone > 0 then
        ns.Log.Shift(list, gone)
        oldest = math.max(oldest - gone, 1)
    end
    if seen then list[#list + 1] = entry end
    if gone == 0 and not seen then return end
    Settle()
    if gone > 0 then provider:RemoveIndexRange(1, gone) end
    if removed > 0 then
        box:ScrollToOffset(math.max((box:GetDerivedScrollOffset() or 0) - removed, 0), ScrollBoxConstants.NoScrollInterpolation)
    end
    if seen then
        local now = GetTime()
        Fade.Enter(entry, now)
        -- Its time runs out after all others'; it only needs a timer if none is set (then every
        -- other message's time is over, and it is the next).
        local after = FadeAfter()
        if after and not dueAt then Next(now, after) end
        provider:Insert(entry)
        Run()
    end
    if stick then
        ToEnd()
        -- At the newest message the others move up by the new one's row: they slide there.
        if seen then Slide(Bubble.Measure(entry, rowWidth) + (#list > 1 and Layout.SPACING or 0)) end
    end
end

-- What is shown and what is not has changed: the list anew.
function Window.Refill()
    if frame and frame:IsShown() then Fill() else stale = true end
end
