local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Window
--  The window: a top bar (no title: Saneroki), the list of messages. Moving, sizing
--  (only in Blizzard's Edit Mode: there Core lays its box over the window and
--  puts a grip in a corner), docking to a screen edge and keeping the place are
--  Core's (Core/Window.lua); what follows from a new size is ours.
--
--  It has no background and no border: the messages stand over the game, and
--  a click on them goes through to the game, unless it is on a link or a name
--  (Links.lua). The bar and the button for the line to write in
--  are only there while the mouse is over the window (Chrome); the bar takes
--  no click, the button does only while it is shown. Since nothing else of
--  the window takes the mouse, nothing tells when it comes: a ticker looks,
--  while the window is shown (Watch). The scroll bar is there while the list
--  is scrolled up from its newest message (Bar).
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
--  leaves the window at the newest message, or the line closes.
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
--  the mouse, and every message is there to read. The messages stay in sight
--  and at the list's bottom while the size moves, and are wrapped for the new
--  width once it stands. Full, Core's dropdown Classic windows offers the game's own chat
--  (ours is put away) and friends list (ns.CLASSIC, Social.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble, Fade = ns.Layout, ns.Bubble, ns.Fade
local Window = {}
ns.Window = Window

local frame, box, view, provider
local handle         -- Core's part of the window: moves, sizes and docks it, keeps its place
local rowWidth       -- of the list, from the window's width
local writing        -- the height of the line to write in while it is shown
local top            -- where the list starts, from the window's top: under the bar, or under Core's dropdown
local awake, watch   -- the mouse is over the window; the ticker that sees it come and leave
local revealed       -- a scroll has brought every message back
local slide, drop, rise, sliding -- the messages sliding to their place: the animation, its two parts, how far
local scroll         -- the scroll bar
local chrome = {}    -- what the window is handled by: shown with the mouse over it
local list = {}      -- the messages on show: the log's, without those of the chats switched off
local stale = true   -- the log has messages the list does not show
-- The list is at the newest message (or everything fits): it stays there when a message comes
-- or its size changes. Scrolled up to read, it stays where it is.
local follow = true

-- The scroll bar, while the list is scrolled up: at the newest message it is of no use.
local function Bar()
    scroll:SetShown(not follow)
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
-- were and slide up to their place. A slide still going on is taken into the new one.
-- Two moves at once, as the game's own animations do it: one of no time back, one to the place.
local slides = true -- the setting: slides at all
local function Slide(by)
    if by == 0 or not slides or not frame:IsVisible() then return end
    if slide:IsPlaying() then by = by + sliding * (1 - rise:GetSmoothProgress()) end
    slide:Stop()
    sliding = by
    drop:SetOffset(0, -by)
    rise:SetOffset(0, by)
    slide:Play()
end

-- Only a scroll of yours brings the messages back (the wheel, Revealed): the list tells of a scroll
-- for its own moves too, a new message at its end among them, and for a moment is not at its end.
local function Scrolled()
    follow = box:IsAtEnd() or not box:HasScrollableExtent()
    Bar()
    Laid()
end

-- The room above the messages that puts them at the list's bottom; none once they fill it.
-- True if it changed. A message's height is known after its first measuring.
local function Settle()
    local height = Layout.ListHeight(frame:GetHeight(), writing, top)
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
-- message's text, its speaker's name or its chat's, as Core's fuzzy finding finds letters; nil: no search.
local query

-- A message's text as it reads: without colours, links' codes and icons.
local function Readable(text)
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", ""))
end

local function Visible(entry)
    if not ns.Channels.Shown(entry.group) then return false end
    return not query or Core.Fuzzy.Match(query, Readable(entry.text or ""), entry.name, entry.label) ~= nil
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
end

-- After how many seconds a message fades right now; nil: it does not (fading out is off, or every
-- animation, or the messages are there to read).
local function FadeAfter()
    local options = ns.options
    if revealed or writing or not (options.animations and options.fade) then return nil end
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

local function Step()
    if not ns.Guarded(Paint) then frame:SetScript("OnUpdate", nil) end
end

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

Expire = function() ns.Guarded(Due) end

-- The settings of fading and sliding: how long a fade in and out takes (fading in switched off: at
-- once), whether the messages fade out at all and how far, whether they slide and how fast. All
-- animations off: nothing fades or slides, and every message stays.
function Window.Animate()
    local options = ns.options
    local all = options.animations
    Fade.Times(all and options.fadeInOn and options.fadeInTime or 0, all and options.fadeOutTime or 0)
    slides = all and options.slide and options.slideTime > 0 or false -- a slide of no time is none
    if not frame then return end
    rise:SetDuration(options.slideTime)
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

-- The bar not while the window fills the screen: Core's title bar is at its top then.
local function Chrome()
    local full = handle and handle.edge and handle.edge.full
    for index, part in ipairs(chrome) do part:SetShown(awake and not (index == 1 and full) or false) end
end

local function Asleep()
    awake = false
    Chrome()
end

-- The mouse came over the window: what it is handled by is there.
local function Wake()
    awake = true
    Chrome()
end

-- A held button may be a drag (in Edit Mode): the mouse may be outside, the window is still in hand.
local function Watch()
    local over = frame:IsMouseOver() or (awake and IsMouseButtonDown("LeftButton"))
    if over and not awake then
        Wake()
    elseif awake and not over then
        Asleep()
    end
    -- Scrolled up, the messages stay to read on, until the list is back at its newest.
    if not over and follow then Reveal(false) end
end

local function Watching()
    ns.Guarded(Watch)
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
end

-- The bubbles are more or less solid, or the chats named otherwise: every row in view is drawn anew.
function Window.Repaint()
    if not frame then return end
    Bubble.Opacity(ns.options.bubbleOpacity)
    Bubble.Brief(ns.options.shortNames)
    ns.Input.Paint()
    Rewrap()
end

-- The list is higher or lower now: the messages still stand at its bottom.
local function Resettle()
    if Settle() then box:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
    if follow then ToEnd() end
end

-- The list ends above the line you write in while that is shown, at the window's edge otherwise.
local function Bottom(input)
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE + (input and Layout.Input(input) or 0))
end

-- input: the height of the line to write in; false: it is gone. It grows with its text.
local function Room(input)
    local was, stick = writing, follow
    writing = input
    Bottom(input)
    Resettle()
    if stick then Slide((input and Layout.Input(input) or 0) - (was and Layout.Input(was) or 0)) end
    if not was ~= not input then Window.Refade() end
end

-- The window is that wide now.
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
    if Fit(frame:GetWidth()) then Rewrap() else Resettle() end
end

-- The list starts under the bar; while the window fills the screen, under Core's title bar there (its
-- search, its dropdown Classic windows, its buttons), so that covers neither a message nor the scroll bar.
local function Top()
    local want = Layout.BAR
    if handle.edge and handle.edge.full then want = math.max(Core.Window.BAR, Layout.BAR) end
    if want == top then return end
    top = want
    box:SetPoint("TOPLEFT", Layout.EDGE, -top)
end

local function Placed()
    ns.Guarded(Top)
    ns.Guarded(Refit)
    ns.Guarded(ns.Input.Grow)
    ns.Guarded(ns.Input.Layer)
end

-- It has begun to fill the screen (full) or to go back: its layer has changed. Full, it is there to
-- read every message, until the mouse leaves it at the newest one (Watch).
local function Filled(full)
    ns.Input.Layer()
    Chrome()
    if full then Reveal(true) end
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
end

-- The section Expand window was changed: switched off, the window is back at its size at once.
function Window.Expand()
    if frame then handle.edge:Update() end
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

    local bar = CreateFrame("Frame", nil, frame)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(Layout.BAR)
    handle = Core.Window.New(frame, {
        store = ns.store, title = ns.TEXT.title, sizable = true, dock = true, edge = ns.options, classic = ns.CLASSIC,
        native = ns.NATIVE, close = ns.Close, search = function(text) ns.Guarded(Window.Search, text) end,
        first = { point = "LEFT", x = 40, y = 0, width = Layout.WIDTH, height = Layout.HEIGHT },
        minWidth = Layout.MIN_WIDTH, minHeight = Layout.MIN_HEIGHT,
        docked = Placed, motion = Kind,
        filled = function(full) ns.Guarded(Filled, full) end,
    })

    -- Opens and closes the line to write in, in the corner where that line starts and as high as it.
    -- The art is the game's own chat button's.
    local write = CreateFrame("Button", nil, frame)
    write:SetSize(Layout.INPUT_HEIGHT, Layout.INPUT_HEIGHT)
    write:SetPoint("BOTTOMLEFT", 0, Layout.INPUT_BOTTOM)
    write:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Up")
    write:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat-Down")
    write:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    write:SetScript("OnClick", function(self) ns.Guarded(ns.Input.Toggle, self) end)

    box = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    top = Layout.BAR
    box:SetPoint("TOPLEFT", Layout.EDGE, -top)
    Bottom(false)
    scroll = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
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
    box:HookScript("OnMouseWheel", Revealed) -- at the newest message too, where there is nothing to scroll
    slide = box.ScrollTarget:CreateAnimationGroup()
    drop = slide:CreateAnimation("Translation")
    drop:SetDuration(0)
    rise = slide:CreateAnimation("Translation")
    rise:SetSmoothing("OUT")
    provider = CreateDataProvider()
    box:SetDataProvider(provider)
    Window.Animate()
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, Scrolled, Window)
    box:RegisterCallback(BaseScrollBoxEvents.OnLayout, Laid, Window)
    chrome[1], chrome[2] = bar, write
    Chrome()
    Bar()

    frame:SetScript("OnSizeChanged", Sized)

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
function Window.Show()
    if not frame then Build() end
    if ns.off then return end -- building it failed half way, and the game's chat is back
    frame:Show()
    Back(false)
    -- Five times a second, the mouse: cheap, and the grip is there as soon as it is wanted.
    if not watch then watch = C_Timer.NewTicker(0.2, Watching) end
    if stale then Fill() end
    Window.Refade(true) -- what came or ran out meanwhile is as it is now, at once
    Window.Native()
    ns.Input.Take(frame, Room)
end

-- Hidden, the game's chat is back as it was.
function Window.Hide()
    if not frame then return end
    frame:Hide()
    if watch then watch:Cancel() end
    watch, revealed, dueAt = nil, nil, nil
    frame:SetScript("OnUpdate", nil)
    Asleep()
    ns.Input.Release()
    ns.Native.Show()
    Back(true)
end

-- Off at login (the switch Chat window): the window is made, out of sight, so the game's chat has its
-- button to bring ours back.
function Window.Away()
    if not frame then Build() end
    if ns.off then return end
    Window.Hide()
end

-- A new message. The log lets its oldest go a batch at a time (Log.Add): those leave the list
-- together, in one update of it.
ns.Log.added = function(entry)
    if not frame or not frame:IsShown() then
        stale = true
        return
    end
    local gone, removed = 0, 0
    while list[gone + 1] and list[gone + 1].gone do gone = gone + 1 end
    local seen = Visible(entry)
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
