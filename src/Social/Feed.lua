local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Feed
--  The second chat of the full screen, one of the conversations' list
--  (Conversations.lua): the same messages in the same bubbles, but only the
--  chats ticked for it in the list on the line with its name (the setting
--  split: whispers, groups and guild at first), apart from what the chat
--  shows. Every message in it is there to read: none fades, none slides. At
--  its newest message it follows new ones; scrolled up, it stays where it is,
--  as the chat does.
--
--  Chosen there, it stands where the chat stands, in the window's frame for
--  the chat (Window.lua, column), in the chat's place: as wide, so a message is
--  wrapped for one width and measured once for both (Bubble.Measure keeps that
--  on the message), and over the line to write in, the chat's. The window
--  tells it of every new message (Log.added), of the width (Feed.Fit) and of
--  the line's height (Feed.Room); out of sight it only notes that its list is
--  stale. Search finds messages as the chat's does (Window.Found).
--
--  Its words are picked to copy as the chat's are (Select.lua).
--
--  Built from the game's parts, as the chat: its scrolling list and scroll bar.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble = ns.Layout, ns.Bubble
local Feed = {}
ns.Feed = Feed

local box, scroll, view, provider
local rowWidth
local shown          -- it is on show
local stale = true   -- the log has messages the list does not show
local follow = true  -- at the newest message: it stays there when one comes
local list = {}      -- the messages on show

local function Visible(entry)
    return ns.Channels.Split(entry.group) and ns.Window.Found(entry)
end

local function Bar()
    scroll:SetShown(shown and not follow or false)
end

local function ToEnd()
    follow = true
    box:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
    Bar()
end

local function Scrolled()
    follow = box:IsAtEnd() or not box:HasScrollableExtent()
    Bar()
end

local function Height(_, entry)
    return Bubble.Known(entry, rowWidth) or ns.Guarded(Bubble.Measure, entry, rowWidth) or 1
end

local function Draw(row, entry)
    ns.Guarded(Bubble.Init, row, entry, rowWidth)
end

local function Fill()
    stale = false
    wipe(list)
    for _, entry in ipairs(ns.Log.list) do
        if Visible(entry) then list[#list + 1] = entry end
    end
    provider:Flush()
    provider:InsertTable(list)
    ToEnd()
end

-- The list of chats on the line with its name: everything the chat can show (Channels.Showable), each with its
-- tick here (Conversations.lua sets it up).
local function IsTicked(chat) return ns.Guarded(ns.Channels.Split, chat.group) end
local function Tick(chat) ns.Guarded(ns.Channels.FlipSplit, chat.group) end

function Feed.Menu(_, root)
    root:CreateTitle(ns.TEXT.showing)
    for _, chat in ipairs(ns.Channels.Showable()) do
        root:CreateCheckbox(chat.text, ns.Guard(IsTicked), ns.Guard(Tick), chat)
    end
end

-- Its list in the window's frame for the chat (parent), where the chat's own stands; made the first time it is chosen.
local function Build(parent)
    box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -Layout.EDGE)
    scroll = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 2)
    view = CreateScrollBoxListLinearView(0, 0, 0, 0, Layout.SPACING)
    view:SetElementExtentCalculator(Height)
    view:SetElementInitializer("Frame", Draw)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, scroll, view)
    box:SetInterpolateScroll(true)
    scroll:SetInterpolateScroll(true)
    provider = CreateDataProvider()
    box:SetDataProvider(provider)
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, ns.Guard(Scrolled), Feed)
    ns.Select.Attach(box, list) -- only on the full screen: its words are picked to copy
    ns.Select.Allow(box, true)
end

-- The list ends above the line to write in while that is shown, at the chat's edge otherwise.
local writing -- the line's height while it is shown
local function Bottom()
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE + (writing and Layout.Input(writing) or 0))
end

-- The line to write in is that high now (false: it is gone).
function Feed.Room(input)
    writing = input
    if not box then return end
    local stick = follow
    Bottom()
    if stick and shown then ToEnd() end
end

-- Chosen in the conversations' list (on), in the window's frame for the chat (parent), or not (any more).
function Feed.Show(on, parent)
    shown = on and true or false
    if on and not box then Build(parent) end
    if not box then return end
    Bottom()
    box:SetShown(shown)
    Bar()
    if on and stale then Fill() end
end

-- The last message it shows, or would: for its row in the conversations' list.
function Feed.Last()
    local entries = ns.Log.list
    for index = #entries, 1, -1 do
        if Visible(entries[index]) then return entries[index] end
    end
end

-- The chat's width now: the rows' width here too (it stands in the chat's place).
function Feed.Fit(width)
    if width == rowWidth then return end
    rowWidth = width
    Feed.Rewrap()
end

-- Every message measured and drawn anew: a new width, text size, bubble look or way of naming the chats.
function Feed.Rewrap()
    if not box or not rowWidth then return end
    local stick = follow
    box:Rebuild(ScrollBoxConstants.RetainScrollPosition)
    if stick then ToEnd() end
end

-- What it shows has changed (its ticks, the search): the list anew, now or once it is shown.
function Feed.Refill()
    if box and shown then Fill() else stale = true end
end

-- A new message (Window.lua). The oldest the log let go leave the list with it, in one update.
function Feed.Added(entry)
    if not box or not shown then
        stale = true
        return
    end
    local gone = 0
    while list[gone + 1] and list[gone + 1].gone do gone = gone + 1 end
    if gone > 0 then
        ns.Log.Shift(list, gone)
        provider:RemoveIndexRange(1, gone)
    end
    if not Visible(entry) then return end
    local stick = follow
    list[#list + 1] = entry
    provider:Insert(entry)
    if stick then ToEnd() end
end
