local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Feed
--  The second chat of the full screen, above the chat (Board.lua): the same
--  messages in the same bubbles, but only the chats ticked for it in the list
--  on its head (the setting split: whispers, groups and guild at first), apart
--  from what the chat shows. Every message in it is there to read: none fades,
--  none slides. At its newest message it follows new ones; scrolled up, it
--  stays where it is, as the chat does.
--
--  It is as wide as the chat under it, so a message is wrapped for one width
--  and measured once for both (Bubble.Measure keeps that on the message). The
--  window tells it of every new message (Window.lua, Log.added) and of the
--  width (Feed.Fit); out of sight it only notes that its list is stale.
--  Search finds messages as the chat's does (Window.Found).
--
--  Built from the game's parts, as the chat: its scrolling list and scroll bar,
--  and for the list of chats its filter dropdown (WowStyle1FilterDropdownTemplate).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble = ns.Layout, ns.Bubble
local Feed = {}
ns.Feed = Feed

local panel, box, scroll, view, provider
local rowWidth
local shown          -- its panel is on show
local stale = true   -- the log has messages the list does not show
local follow = true  -- at the newest message: it stays there when one comes
local list = {}      -- the messages on show

local function Visible(entry)
    return ns.Channels.Split(entry.group) and ns.Window.Found(entry)
end

local function Bar()
    scroll:SetShown(not follow)
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

-- The list of chats on its head: everything the chat can show (Channels.Showable), each with its tick here.
local function IsTicked(chat) return ns.Guarded(ns.Channels.Split, chat.group) end
local function Tick(chat) ns.Guarded(ns.Channels.FlipSplit, chat.group) end

local function Menu(_, root)
    root:CreateTitle(ns.TEXT.showing)
    for _, chat in ipairs(ns.Channels.Showable()) do
        root:CreateCheckbox(chat.text, IsTicked, Tick, chat)
    end
end

function Feed.Build(holder)
    panel = holder
    panel.title:SetText(ns.TEXT.feed)
    local filter = CreateFrame("DropdownButton", nil, panel.head, "WowStyle1FilterDropdownTemplate")
    filter:SetPoint("RIGHT", -Layout.EDGE, 0)
    filter:SetWidth(100)
    filter:SetText(ns.TEXT.feedFilter)
    filter:SetupMenu(Menu)
    panel.filter = filter

    box = CreateFrame("Frame", nil, panel.body, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -Layout.EDGE)
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE)
    scroll = CreateFrame("EventFrame", nil, panel.body, "MinimalScrollBar")
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
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, Scrolled, Feed)
    Bar()
end

function Feed.Show(on)
    shown = on
    if on and stale then Fill() end
end

-- The chat's width now: the rows' width here too (they stand in a list as wide, Layout.Board).
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

function Feed.Search()
    Feed.Refill()
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
