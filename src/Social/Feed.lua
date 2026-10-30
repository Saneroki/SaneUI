local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Feed
--  The chat views of the full screen: as many as you make, each with its own
--  name and its own choice of chats (its ticks, apart from what the chat
--  shows), the messages in the chat's bubbles, but every one there to read:
--  none fades, none slides. At its newest message a list follows new ones;
--  scrolled up, it stays where it is, as the chat does.
--
--  A view is a row of the conversations' list (Conversations.lua): chosen, it
--  stands beside the list, in the conversations' own part. It is a window of
--  the full screen's layouts too (Board.lua, its key "view:<id>"), in as many
--  layouts as you like. Each place it stands is a list of its own (Feed.New),
--  all fed by the window (Log.added → Feed.Added); one out of sight only
--  notes that it is stale, and is filled anew when it is shown. A message is
--  wrapped once per width and measured once (Bubble.Measure keeps that on the
--  message), so lists as wide as the chat cost no measuring of their own.
--
--  Kept in the module's store, account-wide as the layouts that name them:
--      store.views = { next = 3, list = { { id = 1, name = "Second chat", shows = { WHISPER = true, ... } }, ... } }
--  At first one, the second chat, showing whispers, your groups and guild.
--
--  Messages that came while none of a view's lists was on show are counted,
--  for this session only, not kept with the view (unseen; the last one's chat
--  colour in a table of the view's own, made once: tints): its row in the
--  conversations' list is lit as the game's chat tabs light a new message,
--  until a list of it is shown.
--
--  Built from the game's parts, as the chat: its scrolling list and scroll bar.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Bubble = ns.Layout, ns.Bubble
local Feed = {}
ns.Feed = Feed

Feed.FIRST = { WHISPER = true, PARTY = true, RAID = true, INSTANCE_CHAT = true, GUILD = true, OFFICER = true } -- the first view's

local lists = {} -- every list made, in the order made
local unseen = setmetatable({}, { __mode = "k" }) -- [view] = its messages not seen yet, this session
local tints = setmetatable({}, { __mode = "k" }) -- [view] = { r, g, b } of its last message not seen, reused
local menus = setmetatable({}, { __mode = "k" }) -- [view] = its list of chats (Feed.Menu), made once

-------------------------------------------------------------------------------
--  The views
-------------------------------------------------------------------------------
local function Kept()
    local views = ns.store.views
    if type(views) ~= "table" or type(views.list) ~= "table" then
        views = { next = 2, list = { { id = 1, name = ns.TEXT.feed, shows = Core.Copy(Feed.FIRST) } } }
        ns.store.views = views
    end
    views.next = math.max(tonumber(views.next) or 1, #views.list + 1)
    return views
end

-- Every view, in the order made.
function Feed.Views()
    return Kept().list
end

function Feed.View(id)
    for _, view in ipairs(Kept().list) do
        if view.id == id then return view end
    end
end

-- Whether a view shows the messages of a group (Log.lua: GUILD, CHANNEL:Trade, ...).
function Feed.Shows(view, group)
    return view ~= nil and type(view.shows) == "table" and view.shows[group] == true
end

local function Visible(view, entry)
    return Feed.Shows(view, entry.group) and ns.Window.Found(entry)
end

-- Every list of a view (nil: of every view) filled anew (its ticks, the search), now or once it is shown.
function Feed.Refill(view)
    for _, list in ipairs(lists) do
        if not view or list.view == view then list:Refill() end
    end
end

-- A new view, showing nothing at first: its chats are ticked in the list on its name's line.
function Feed.Make()
    local views = Kept()
    local id = views.next
    views.next = id + 1
    local view = { id = id, name = ns.TEXT.newView:format(id), shows = {} }
    views.list[#views.list + 1] = view
    return view
end

function Feed.Rename(view, name)
    name = type(name) == "string" and name:match("^%s*(.-)%s*$") or ""
    if name == "" then return end
    view.name = name
    ns.Board.Retitle("view:" .. view.id, name)
end

-- A view is no more: out of the list, its lists out of sight, out of every layout.
function Feed.Remove(view)
    local list = Kept().list
    for index = #list, 1, -1 do
        if list[index] == view then table.remove(list, index) end
    end
    for _, each in ipairs(lists) do
        if each.view == view then each:Point(nil) end
    end
    ns.Board.Forget("view:" .. view.id)
end

-- A tick of a view flipped: its lists show their messages anew.
function Feed.Flip(view, group)
    view.shows = type(view.shows) == "table" and view.shows or {}
    view.shows[group] = not view.shows[group] or nil
    Feed.Refill(view)
    ns.Conversations.Said()
end

-- The list of chats on the line with a view's name: everything the chat can show (Channels.Showable), each with
-- its tick for this view. The game asks for it when it opens, outside our own guard: behind one, made once a view.
function Feed.Menu(view)
    local menu = menus[view]
    if not menu then
        menu = ns.Guard(function(_, root)
            root:CreateTitle(ns.TEXT.showing)
            for _, chat in ipairs(ns.Channels.Showable()) do
                root:CreateCheckbox(chat.text, ns.Guard(function() return Feed.Shows(view, chat.group) end),
                    ns.Guard(function() Feed.Flip(view, chat.group) end))
            end
        end)
        menus[view] = menu
    end
    return menu
end

-- The last message a view shows, or would: for its row in the conversations' list.
function Feed.Last(view)
    local entries = ns.Log.list
    for index = #entries, 1, -1 do
        if Visible(view, entries[index]) then return entries[index] end
    end
end

-- Whether a list of a view is on show.
local function Seen(view)
    for _, list in ipairs(lists) do
        if list.view == view and list.shown then return true end
    end
    return false
end

-- A view's new messages not seen, and the chat colour of the last; 0 once a list of it is on show.
function Feed.Unread(view)
    return unseen[view] or 0, tints[view]
end

-------------------------------------------------------------------------------
--  A list of a view
-------------------------------------------------------------------------------
local methods = {}
local meta = { __index = methods }

local function Bar(list)
    list.scroll:SetShown(list.shown and not list.follow or false)
end

local function ToEnd(list)
    list.follow = true
    list.box:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
    Bar(list)
end

local function Fill(list)
    list.stale = false
    wipe(list.entries)
    if list.view then
        for _, entry in ipairs(ns.Log.list) do
            if Visible(list.view, entry) then list.entries[#list.entries + 1] = entry end
        end
    end
    list.provider:Flush()
    list.provider:InsertTable(list.entries)
    ToEnd(list)
end

-- Its scrolling list in its parent, from top below the parent's top down; made the first time it is shown.
local function Build(list)
    local parent = list.parent
    local box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -list.top)
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.EDGE)
    local scroll = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 2)
    -- The list asks these outside our own guard: behind one of ours, and never a height of nothing, which would stop it.
    local function Measured(entry)
        return list.width and (Bubble.Known(entry, list.width) or Bubble.Measure(entry, list.width)) or 1
    end
    local function Drawn(row, entry)
        if list.width then Bubble.Init(row, entry, list.width) end
    end
    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, Layout.SPACING)
    view:SetElementExtentCalculator(function(_, entry) return ns.Guarded(Measured, entry) or 1 end)
    view:SetElementInitializer("Frame", function(row, entry) ns.Guarded(Drawn, row, entry) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, scroll, view)
    box:SetInterpolateScroll(true)
    scroll:SetInterpolateScroll(true)
    list.provider = CreateDataProvider()
    box:SetDataProvider(list.provider)
    box:RegisterCallback(BaseScrollBoxEvents.OnScroll, ns.Guard(function()
        list.follow = box:IsAtEnd() or not box:HasScrollableExtent()
        Bar(list)
    end), list)
    list.box, list.scroll = box, scroll
    ns.Select.Attach(box, list.entries) -- only on the full screen: its words are picked to copy
    ns.Select.Allow(box, true)
end

-- A list of a view (nil: none yet, Point) in parent, starting top below its top (EDGE without).
function Feed.New(view, parent, top)
    local list = setmetatable({ view = view, parent = parent, top = top or Layout.EDGE, entries = {}, stale = true,
                                follow = true, shown = false }, meta)
    lists[#lists + 1] = list
    return list
end

-- Shown (on) or out of sight. Shown, its view's new messages are seen.
function methods:Show(on)
    self.shown = (on and self.view ~= nil) and true or false
    if self.shown and not self.box then Build(self) end
    if not self.box then return end
    self.box:SetShown(self.shown)
    Bar(self)
    if not self.shown then return end
    if self.stale then Fill(self) end
    if unseen[self.view] then
        unseen[self.view] = nil
        ns.Conversations.Said()
    end
end

-- It shows another view now (the one chosen in the conversations' list), or none.
function methods:Point(view)
    if view == self.view then return end
    self.view, self.stale = view, true
    if not view then return self:Show(false) end
    if self.shown and self.box then Fill(self) end
end

-- Its rows that wide (Layout.RowWidth of its part): every message wrapped anew.
function methods:Fit(width)
    if width == self.width then return end
    self.width = width
    self:Rewrap()
end

function methods:Rewrap()
    if not self.box or not self.width then return end
    local stick = self.follow
    self.box:Rebuild(ScrollBoxConstants.RetainScrollPosition)
    if stick then ToEnd(self) end
end

function methods:Refill()
    if self.box and self.shown then Fill(self) else self.stale = true end
end

-- A new message (Feed.Added). The oldest the log let go leave the list with it, in one update.
function methods:Added(entry)
    if not self.box or not self.shown then
        self.stale = true
        return
    end
    local entries, gone = self.entries, 0
    while entries[gone + 1] and entries[gone + 1].gone do gone = gone + 1 end
    if gone > 0 then
        ns.Log.Shift(entries, gone)
        self.provider:RemoveIndexRange(1, gone)
    end
    if not Visible(self.view, entry) then return end
    local stick = self.follow
    entries[#entries + 1] = entry
    self.provider:Insert(entry)
    if stick then ToEnd(self) end
end

-------------------------------------------------------------------------------
--  Every list
-------------------------------------------------------------------------------
-- A new message (Window.lua): to every list; a view none of whose lists is on show counts it as not seen.
function Feed.Added(entry)
    for _, list in ipairs(lists) do list:Added(entry) end
    for _, view in ipairs(Kept().list) do
        if Feed.Shows(view, entry.group) and not Seen(view) then
            unseen[view] = (unseen[view] or 0) + 1
            local tint = tints[view] or {} -- one table for each view: this comes with nearly every message
            tint[1], tint[2], tint[3] = entry.r or 1, entry.g or 1, entry.b or 1
            tints[view] = tint
        end
    end
end

-- Every message measured and drawn anew: a new text size, bubble look or way of naming the chats.
function Feed.Rewrap()
    for _, list in ipairs(lists) do list:Rewrap() end
end
