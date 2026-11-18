local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Chat windows
--  More than one chat window on the screen, for whoever wants them (Saneroki,
--  2026-11-18): a chat view (Feed.lua) stands on the screen as a chat window of
--  its own, beside the chat, as the game's chat windows can stand apart from
--  its general chat, each with its own choice of chats. It is the same view as
--  on the full screen: its name, its ticks, its row in the conversations' list.
--
--  Put on the screen and taken off: in the list behind the chat's button (its
--  column Chat windows: a tick for each chat view, and New Window, a new view on
--  the screen at once, its list open to tick what it shows), by a chat view's
--  right click on the full screen, and by the window's own button. That button
--  stands in its lower left corner while the mouse is over the window (as the
--  chat's does), its name at its top left with it; a click opens its list:
--  Rename Window, Close Window (it leaves the screen; the view stays on the full
--  screen) and the chats it shows, each ticked. While it shows nothing, its name,
--  its button and a word on what to do stand there, so it is never lost unseen.
--
--  It looks and behaves as the chat does: no background, a click goes through to
--  the game but on a link or a name, the newest message at the bottom, every
--  message fading a while after it came (the chat's settings, Animations), all
--  back to read at a turn of the wheel until the mouse leaves at the newest,
--  sliding up for a new one, a message the top edge cuts through out of sight.
--  Moved, sized and docked in Edit Mode, as the chat (Core's window of the kind
--  screen, its name on its box there; it does not fill the screen: that is the
--  chat's). Its place is kept per profile, by its view (key "view:<id>"). The
--  line to write in stays the chat's: Enter opens it there.
--
--  Its fading goes by a message's age alone (when it came: entry.at), not by the
--  fade the chat keeps on the message (Fade.lua): the same message may stand in
--  both, revealed in one and not in the other. A turn of the wheel lifts every
--  message to all there (lift: a table of its own that Fade.lua moves, so it
--  fades in and out as a message does). An OnUpdate only while something moves,
--  one timer for the next message to begin fading.
--
--  On the screen while the chat window stands at its size (Stand: not while it
--  fills the screen, where the views stand on the full screen, nor while it is
--  put away) and its view wants it (view.screen, kept with the views,
--  account-wide). Made the first time it is shown. A list of a view as Feed's
--  are (Feed.Join): fed every message by the window (Feed.Added), filled anew for
--  its ticks (Feed.Refill), wrapped anew for the text size and the bubbles' look
--  (Feed.Rewrap), gone with its view (Feed.Remove: Point(nil)). A view on the
--  screen counts no message as not seen. Every step runs in ns.Safe("chat
--  windows", ...): one that fails is noted, the chat goes on.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble, Fade, Feed = ns.Layout, ns.Bubble, ns.Fade, ns.Feed
local ChatWindows = {}
ns.ChatWindows = ChatWindows

local LABEL = "chat windows" -- in the error log
local NAME = 18              -- the room at its top for its name
local HEIGHT = 200           -- a new one's height (as wide as the chat at first)
local CHAT = "Interface\\ChatFrame\\UI-ChatIcon-Chat"

local windows = setmetatable({}, { __mode = "k" }) -- [view] = its window, made once it is first wanted
local stands = false -- the chat window stands on the screen at its size: these may stand too
local built = 0      -- windows made this session: each new one a step aside from the last at first

local methods = {}
local meta = { __index = methods }

-------------------------------------------------------------------------------
--  Fading, by a message's age
-------------------------------------------------------------------------------
-- The chat's settings of fading (Window.Animate), read once a round: after how many seconds a message begins to
-- fade (nil: never), how long a whole fade in and out takes, how much of a faded one is still seen.
local after, fadeIn, fadeOut, floor

local function Times()
    local options = ns.options
    local all = options.animations
    local instant = Core.general and Core.general.animations == false
    after = (all and options.fade) and options.fadeAfter or nil
    fadeIn = (all and options.fadeInOn and not instant) and options.fadeInTime or 0
    fadeOut = (all and not instant) and options.fadeOutTime or 0
    floor = options.fadeFloorOn and math.min(math.max((options.fadeFloor or 0) / 100, 0), 1) or 0
end

local function Ease(t)
    return Core.Motion.Ease(Fade.CURVE, t)
end

-- How much of a message is seen at that time by its age (Times read): in from nothing, all there until after, then
-- out to floor. Also whether it is on its way now, and when it begins to fade out (nil: it does already, or never).
local function Aged(entry, now)
    local at = entry.at or now
    local age = now - at
    local alpha, moving, due = 1, false, nil
    if fadeIn > 0 and age < fadeIn then alpha, moving = Ease(math.max(age, 0) / fadeIn), true end
    if after then
        local out = age - after
        if out < 0 then
            due = at + after
        elseif fadeOut > 0 and out < fadeOut then
            alpha, moving = math.min(alpha, 1 - (1 - floor) * Ease(out / fadeOut)), true
        else
            alpha = math.min(alpha, floor)
        end
    end
    return alpha, moving, due
end

-- Every row in view shows how much of its message is seen: its age's, or more while the wheel lifts them all.
-- Returns whether something is on its way (then again next frame) and when the next one in view begins to fade.
local painting, paintAt, moving, due
local function PaintRow(row, entry)
    local lifted = painting.lifted
    if lifted >= 1 then return row:SetAlpha(1) end
    local alpha, still, at = Aged(entry, paintAt)
    row:SetAlpha(math.max(alpha, lifted))
    if still then moving = true end
    if at and (not due or at < due) then due = at end
end

local function Paint(win)
    Times()
    painting, paintAt, moving, due = win, GetTime(), false, nil
    win.lifted = Fade.Alpha(win.lift, paintAt)
    if Fade.Moving(win.lift) then moving = true end
    win.box:ForEachFrame(PaintRow)
    return moving, due
end

-- Painted every frame while something is on its way; once nothing is, a timer for the next to begin fading. A timer
-- that is no longer the one wanted (dueAt has changed since) does nothing.
local function Run(win)
    if win.box and win.shown then win.frame:SetScript("OnUpdate", win.step) end
end

local function Step(win)
    local still, at = Paint(win)
    if still then return end
    win.frame:SetScript("OnUpdate", nil)
    win.dueAt = at
    if at then C_Timer.After(math.max(at - GetTime(), 0) + 0.01, win.expire) end
end

local function Expire(win)
    if win.dueAt and GetTime() >= win.dueAt - 0.001 then
        win.dueAt = nil
        Run(win)
    end
end

-- Every message back to read (on: a turn of the wheel), or fading by its age again; both gently.
local function Reveal(win, on)
    if win.revealed == on then return end
    win.revealed = on
    Fade.To(win.lift, on and 1 or 0, GetTime())
    Run(win)
end

-------------------------------------------------------------------------------
--  Its list
-------------------------------------------------------------------------------
local function Bar(win)
    win.scroll:SetShown(win.shown and not win.follow or false)
end

local function ToEnd(win)
    win.follow = true
    win.box:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
    Bar(win)
end

-- Rows the list's top edge cuts through are out of sight, the others shown.
local edge
local function TrimRow(row)
    local top = row:GetTop()
    Bubble.Cut(row, top ~= nil and top > edge)
end

local function Trim(win)
    edge = win.box:GetTop()
    if not edge then return end
    edge = edge + 0.5 -- a row that starts at the edge is whole
    win.box:ForEachFrame(TrimRow)
end

-- The list may tell of a scroll before it has put the rows in their new places: again a frame later.
local function Laid(win)
    Trim(win)
    win.trim()
end

-- The room above the messages that puts them at the list's bottom; none once they fill it. True if it changed.
local function Settle(win)
    if not win.width then return false end
    local height = Layout.ListHeight(win.frame:GetHeight() - (win.handle.top or 0), nil, NAME)
    local entries, total = win.entries, 0
    for index = #entries, 1, -1 do
        total = total + Bubble.Measure(entries[index], win.width) + (index > 1 and Layout.SPACING or 0)
        if total >= height then break end
    end
    local room = math.max(height - total, 0)
    local padding = win.lay:GetPadding()
    if padding:GetTop() == room then return false end
    padding:SetTop(room)
    return true
end

local function Resettle(win)
    if Settle(win) then win.box:FullUpdate(ScrollBoxConstants.UpdateImmediately) end
    if win.follow then ToEnd(win) end
end

-- Its name, its button and what to do stand there while the mouse is over it, its list is open, or it shows nothing.
local function Chrome(win)
    local empty = #win.entries == 0
    local on = win.awake or win.menu ~= nil or empty
    win.button:SetShown(on)
    win.name:SetShown(on)
    win.hint:SetShown(empty)
    if empty then win.hint:SetText(next(win.view.shows) and ns.TEXT.windowQuiet or ns.TEXT.windowPick) end
end

-- Its messages anew: every one the log has that its view shows, at the newest, each as its age says.
local function Fill(win)
    win.stale = false
    wipe(win.entries)
    for _, entry in ipairs(ns.Log.list) do
        if Feed.Shows(win.view, entry.group) then win.entries[#win.entries + 1] = entry end
    end
    win.provider:Flush()
    Settle(win)
    win.provider:InsertTable(win.entries)
    ToEnd(win)
    Chrome(win)
    Run(win)
end

-- Its rows that wide: its messages wrapped for it. True if that changed.
local function Fit(win)
    local width = Layout.RowWidth(win.frame:GetWidth())
    if width == win.width then return false end
    win.width = width
    return true
end

local function Rewrap(win)
    if not win.box or not win.width then return end
    local stick = win.follow
    Settle(win)
    win.box:Rebuild(ScrollBoxConstants.RetainScrollPosition)
    if stick then ToEnd(win) end
end

-- Core's window has placed it (built, dragged, sized, a profile's place): wrapped once for its width now.
local function Placed(win)
    if Fit(win) then Rewrap(win) else Resettle(win) end
end

-- While it is sized the messages keep their wrapping and only stand at the bottom anew (Placed wraps them after).
local function Sized(win)
    Resettle(win)
end

local function Scrolled(win)
    win.follow = win.box:IsAtEnd() or not win.box:HasScrollableExtent()
    Bar(win)
    Laid(win)
    if win.follow and win.revealed and not win.hover.over then Reveal(win, false) end
end

-- The list asks these outside our own guard, and never may a height be nothing (it would stop the list).
local function Measured(win, entry)
    return Bubble.Known(entry, win.width) or Bubble.Measure(entry, win.width)
end

local function DrawRow(win, row, entry)
    Bubble.Init(row, entry, win.width)
    Times()
    local lifted = Fade.Alpha(win.lift, GetTime())
    local alpha, still, at = Aged(entry, GetTime())
    row:SetAlpha(math.max(alpha, lifted))
    if lifted < 1 and (still or (at and (not win.dueAt or at < win.dueAt))) then Run(win) end
end

-------------------------------------------------------------------------------
--  Its list of what it shows (its button)
-------------------------------------------------------------------------------
local function Rename(win)
    local view = win.view
    Core.AskText(ns.TEXT.windowRename, nil, Core.Word("ACCEPT", "Accept"), view.name, function(text)
        ns.Safe(LABEL, Feed.Rename, view, text)
        ns.Safe(LABEL, ns.Conversations.Relist)
    end, 32)
end

-- Opens its list at the mouse, or closes it if it is open.
local function Toggle(win)
    if win.menu then return win.menu:Close() end
    win.menu = MenuUtil.CreateContextMenu(win.frame, win.fill)
    Chrome(win)
end

-- Its scripts and its list's lines, made once for each window (the game calls them outside our own guard).
local function Wire(win)
    win.step = ns.Guard(function() Step(win) end)
    win.expire = ns.Guard(function() Expire(win) end)
    win.trim = Core.Later(function() if win.shown then ns.Safe(LABEL, Trim, win) end end)
    win.open = Core.Later(function() if win.shown and not win.menu then ns.Safe(LABEL, Toggle, win) end end)
    win.gone = ns.Guard(function(menu)
        if menu ~= win.menu then return end
        win.menu = nil
        Chrome(win)
    end)
    win.shows = ns.Guard(function(chat) return Feed.Shows(win.view, chat.group) end)
    win.flip = ns.Guard(function(chat) Feed.Flip(win.view, chat.group) end)
    win.fill = ns.Guard(function(_, root)
        root:AddMenuReleasedCallback(win.gone)
        root:CreateTitle(win.view.name)
        root:CreateButton(Core.Word("RENAME_CHAT_WINDOW", "Rename Window"), win.rename)
        root:CreateButton(Core.Word("CLOSE_CHAT_WINDOW", "Close Window"), win.close)
        root:CreateDivider()
        root:CreateTitle(ns.TEXT.showing)
        for _, chat in ipairs(ns.Channels.Showable()) do
            root:CreateCheckbox(chat.text, win.shows, win.flip, chat)
        end
    end)
    win.rename = ns.Guard(function() Rename(win) end)
    win.close = ns.Guard(function() ChatWindows.Put(win.view, false) end)
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------
local function Build(win)
    local view = win.view
    -- Where the chat is, above the action bars; everything in it is its child and drawn with it.
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(Layout.LEVEL)
    win.frame = frame
    -- At first above the chat at its first place, each new one a step aside: Edit Mode puts it where it is wanted.
    local step = built * Core.Window.CASCADE
    built = built + 1
    win.handle = Core.Window.New(frame, {
        kind = "screen", store = ns.store, key = "view:" .. view.id, title = view.name, edge = false,
        first = { point = "BOTTOMLEFT", x = step, y = Layout.HEIGHT + HEIGHT + 2 * Layout.EDGE + step,
                  width = Layout.WIDTH, height = HEIGHT },
        minWidth = Layout.MIN_WIDTH, minHeight = Layout.MIN_HEIGHT,
        docked = function() ns.Safe(LABEL, Placed, win) end,
    })
    -- Only the mouse's coming: a click on it still goes into the game.
    win.hover = Core.Hover(frame, { every = 0.2, label = ns.name .. ": chat window",
        enter = function() ns.Safe(LABEL, function() win.awake = true Chrome(win) end) end,
        leave = function() ns.Safe(LABEL, function()
            win.awake = false
            Chrome(win)
            if win.follow then Reveal(win, false) end
        end) end })

    local inside = win.handle.inside
    local name = inside:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    name:SetPoint("TOPLEFT", Layout.EDGE + 2, -3)
    name:SetPoint("TOPRIGHT", -Layout.EDGE, -3)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    name:SetText(view.name)
    win.name = name

    local box = CreateFrame("Frame", nil, inside, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -NAME)
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE)
    local scroll = CreateFrame("EventFrame", nil, inside, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 14) -- ends above the grip
    local lay = CreateScrollBoxListLinearView(0, 0, 0, 0, Layout.SPACING)
    lay:SetElementExtentCalculator(function(_, entry) return ns.Safe(LABEL, Measured, win, entry) or 1 end)
    lay:SetElementInitializer("Frame", function(row, entry) ns.Safe(LABEL, DrawRow, win, row, entry) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, scroll, lay)
    box:SetInterpolateScroll(true)
    scroll:SetInterpolateScroll(true)
    box:HookScript("OnMouseWheel", function() ns.Safe(LABEL, Reveal, win, true) end) -- at the newest too
    win.slide = Core.Motion.Slide(box.ScrollTarget, ns.options.slideTime)
    win.provider = CreateDataProvider()
    box:SetDataProvider(win.provider)
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, function() ns.Safe(LABEL, Scrolled, win) end, win)
    box:RegisterCallback(BaseScrollBoxEvents.OnLayout, function() ns.Safe(LABEL, Laid, win) end, win)
    win.box, win.scroll, win.lay = box, scroll, lay

    -- What to do while it shows nothing, in its middle.
    local hint = inside:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    hint:SetPoint("LEFT", box, "LEFT", Layout.EDGE, 0)
    hint:SetPoint("RIGHT", box, "RIGHT", -Layout.EDGE, 0)
    hint:SetWordWrap(true)
    win.hint = hint

    -- Its list, in the corner where the chat's button is; the art is the game's own chat button's.
    local button = CreateFrame("Button", nil, frame)
    button:SetSize(Layout.INPUT_HEIGHT, Layout.INPUT_HEIGHT)
    button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, Layout.INPUT_BOTTOM)
    button:SetFrameLevel(box:GetFrameLevel() + 5)
    button:SetNormalTexture(CHAT .. "-Up")
    button:SetPushedTexture(CHAT .. "-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetScript("OnClick", function() ns.Safe(LABEL, Toggle, win) end)
    ns.Menu.Button(button) -- a press on it is its own, not a click outside its list
    Core.Tip(button, function() return win.view and win.view.name end, ns.TEXT.windowTip, "ANCHOR_TOPLEFT")
    win.button = button

    frame:SetScript("OnSizeChanged", function() ns.Safe(LABEL, Sized, win) end)
    Fit(win)
    win.handle:Place() -- where it was left; at its first place if it never was moved
end

-- On the screen (on) or out of sight. Shown, its messages are as their ages say at once, and its view's are seen.
local function Show(win, on)
    on = on and win.view ~= nil
    if on and not win.frame then Build(win) end
    if not win.frame or win.shown == on then return end
    win.shown = on
    if on then
        win.frame:Show()
        if win.stale then Fill(win) end
        Chrome(win)
        Bar(win)
        Run(win)
        Feed.Saw(win.view)
        return
    end
    win.frame:Hide()
    win.hover:Stop()
    win.frame:SetScript("OnUpdate", nil)
    win.dueAt, win.revealed, win.awake = nil, false, false
    Fade.To(win.lift, 0, GetTime(), true)
    if win.menu then win.menu:Close() end
end

-------------------------------------------------------------------------------
--  As a list of its view (Feed.Join)
-------------------------------------------------------------------------------
-- A new message (Feed.Added). The oldest the log let go leave with it, in one update; scrolled up, what is read
-- stays where it is. At the newest the others slide up to make room for it.
function methods:Added(entry)
    if not self.box or not self.shown then
        self.stale = true
        return
    end
    local entries, gone, removed = self.entries, 0, 0
    while entries[gone + 1] and entries[gone + 1].gone do gone = gone + 1 end
    local seen = Feed.Shows(self.view, entry.group)
    if gone == 0 and not seen then return end
    local stick = self.follow
    if not stick then
        for index = 1, gone do removed = removed + Bubble.Measure(entries[index], self.width) + Layout.SPACING end
    end
    if gone > 0 then ns.Log.Shift(entries, gone) end
    if seen then entries[#entries + 1] = entry end
    Settle(self)
    if gone > 0 then self.provider:RemoveIndexRange(1, gone) end
    if removed > 0 then
        self.box:ScrollToOffset(math.max((self.box:GetDerivedScrollOffset() or 0) - removed, 0), ScrollBoxConstants.NoScrollInterpolation)
    end
    if not seen then return end
    self.provider:Insert(entry)
    Chrome(self)
    Run(self)
    if not stick then return end
    ToEnd(self)
    local options = ns.options
    if options.animations and options.slide and (options.slideTime or 0) > 0 and self.frame:IsVisible() then
        self.slide:From(0, -(Bubble.Measure(entry, self.width) + (#entries > 1 and Layout.SPACING or 0)))
    end
end

function methods:Refill()
    if self.box and self.shown then Fill(self) else self.stale = true end
end

function methods:Rewrap()
    Rewrap(self)
end

-- Its view is no more (Feed.Remove): off the screen for good.
function methods:Point(view)
    if view == self.view then return end
    Show(self, false)
    self.view, self.stale = view, true
end

local function New(view)
    local win = setmetatable({ view = view, entries = {}, stale = true, follow = true, shown = false,
                               lift = { to = 0 }, lifted = 0 }, meta)
    Wire(win)
    windows[view] = win
    Feed.Join(win)
    return win
end

-------------------------------------------------------------------------------
--  Every chat window
-------------------------------------------------------------------------------
-- Each chat view on the screen that wants to be, while the chat stands at its size; the others out of sight.
function ChatWindows.Follow()
    for _, view in ipairs(Feed.Views()) do
        local wanted = stands and view.screen == true and not ns.off
        local win = windows[view]
        if wanted and not win then win = New(view) end
        if win then Show(win, wanted) end
    end
end

-- The chat window stands on the screen at its size (on), or fills it, or is put away: these follow.
function ChatWindows.Stand(on)
    stands = on and true or false
    ChatWindows.Follow()
end

-- Whether a chat view stands on the screen as a window of its own (the tick in the chat's list).
function ChatWindows.Shown(view)
    return view.screen == true
end

-- A chat view on the screen as a window of its own (on), or not; kept with the view. The conversations' list shows
-- whether its messages wait.
function ChatWindows.Put(view, on)
    view.screen = on and true or nil
    ChatWindows.Follow()
    ns.Conversations.Said()
end

function ChatWindows.Flip(view)
    ChatWindows.Put(view, view.screen ~= true)
end

-- New Window: one more chat view, on the screen at once, its list open a moment later (the chat's has closed) to
-- tick what it shows.
function ChatWindows.Make()
    local view = Feed.Make()
    view.name = ns.TEXT.newWindow:format(view.id)
    ChatWindows.Put(view, true)
    ns.Conversations.Relist()
    local win = windows[view]
    if win and win.shown then win.open() end
    return view
end

-- A chat view renamed (Feed.Rename): its window's name, and its box's in Edit Mode.
function ChatWindows.Retitle(view)
    local win = windows[view]
    if not win or not win.frame then return end
    win.name:SetText(view.name)
    win.handle:SetTitle(view.name)
end

-- The settings of fading and sliding changed (Window.Animate): every window as they say now.
function ChatWindows.Animate()
    for _, win in pairs(windows) do
        if win.slide then
            win.slide:SetTime(ns.options.slideTime)
            if not (ns.options.animations and ns.options.slide) then win.slide:Stop() end
        end
        Run(win)
    end
end

-- The window of a chat view, once made (for the tests).
function ChatWindows.Of(view)
    return windows[view]
end
