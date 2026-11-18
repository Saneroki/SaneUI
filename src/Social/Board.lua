local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Board
--  The full screen's windows, while the window stands full: on Core's board
--  (Core.Board), so they share the screen as you arrange them, in layouts
--  behind tabs in the full window's title bar (drag a window's head to move
--  it, the gap between two to share their room anew, its X to take it off;
--  the dropdown Windows adds one). Social's windows:
--      talks    the conversations (Conversations.lua), whose part beside their
--               list holds the one chosen: a conversation of theirs, or the
--               chat itself, the window's (Window.lua), or the second chat
--               (Feed.lua); those two stand in the window's own frame for the
--               chat, placed there (Board.Show: chat)
--      friends  the friends list (Friends.lua), the group finder one of its tabs
--      guild    the guild window (Guild.lua: the guild key's own), held in its
--               panel as large as fits there, at most its own size; left out of
--               the laying out while there is none (out of a guild, closed)
--      chat     the chat itself, the window's (Window.lua), with its line to
--               write in: in a layout that has it, the chat stands here and not
--               among the conversations
--      view:<id> a chat view (Feed.lua), each one a window of its own: a list of
--               its own in it, and the list of the chats it shows on its head
--  The first layout is the arrangement the full screen has at first: side
--  by side and as high as the screen, the conversations on two thirds at the
--  left, the friends list on the third at the right (Saneroki, 2026-11-18;
--  Layout.Board gives the rooms, Default makes a layout of them), laid out for
--  the screen as it is until you change it; the guild window only once you
--  put it there. A layout without the conversations has no chat in it.
--
--  A panel is Core's (Board.lua: a plate in SaneUI's look, a head with its
--  title at the left, its buttons and the X at its right, its body under the
--  head); what is in it is its part's. A part listens to the game only while
--  its panel is shown (Part.Show). A part runs apart from the chat (ns.Safe):
--  one that fails is noted and the chat goes on; only the window's own work
--  stands the module down.
--
--  What is typed into the full window's search box goes to every panel
--  (Board.Search): the friends list finds what its tab shown lists (friends,
--  groups, ...), the conversations those with the words in their name or
--  their messages (the chat and the second chat find messages themselves).
--
--  A part is a table with:
--      Part.Build(panel)      makes what it holds; panel.title, panel.head, panel.body are there
--      Part.Show(on)          its panel is shown (on) or hidden
--      Part.Search(text)      what is typed into the search box ("": nothing)
--      Part.Size(w, h)        its panel is that wide and high now, before it is shown (a part may lack it)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Board = {}
ns.Board = Board

local layouts -- Core's board, once the window is there (Board.Take)
local inside  -- what the window holds while it stands full
Board.panels = {} -- [key] = the panel, once made (Core's board's)

-- A part's steps, each by itself under the part's name.
local function Step(key, part, name)
    return function(_, ...)
        local own = ns[part]
        if own[name] then ns.Safe(key, own[name], ...) end
    end
end

local function Part(key, part, title, least)
    return { key = key, title = title, least = least,
             build = function(panel) ns.Safe(key, ns[part].Build, panel) end,
             show = Step(key, part, "Show"), size = Step(key, part, "Size"), search = Step(key, part, "Search") }
end

-- Social's windows, in the dropdown's order; the chat views' after them (Windows).
local WINDOWS = {
    Part("talks", "Conversations", ns.TEXT.talks, { Layout.TALKS_MIN, 240 }),
    Part("friends", "Friends", Core.Word("FRIENDS_LIST", "Friends List"), { Layout.FRIENDS_WIDTH, Layout.FRIENDS_LOW }),
    { key = "guild", title = Core.Word("GUILD", "Guild"),
      least = function() return ns.Guild.Least() end,
      present = function() return ns.Guild.Size(inside) ~= nil end },
    { key = "chat", title = Core.Word("CHAT", "Chat"), least = { Layout.VIEW_LEAST[1], Layout.VIEW_LEAST[2] } },
}

-- A chat view's window: a list of its own in its body (Feed.New), and on its head the list of the chats it shows.
local function View(view)
    local key = "view:" .. view.id
    return { key = key, title = view.name, least = Layout.VIEW_LEAST,
        build = function(panel)
            panel.list = ns.Feed.New(view, panel.body)
            local filter = CreateFrame("DropdownButton", nil, panel.head, "WowStyle1FilterDropdownTemplate")
            filter:SetPoint("RIGHT", -Layout.EDGE, 0)
            filter:SetWidth(100)
            filter:SetText(ns.TEXT.feedFilter)
            filter:SetupMenu(ns.Feed.Menu(view)) -- guarded: Feed.Menu hands out ns.Guard(fn), made once per view
            panel.filter = filter
        end,
        show = function(panel, on) ns.Safe(key, panel.list.Show, panel.list, on) end,
        size = function(panel, width) ns.Safe(key, panel.list.Fit, panel.list, Layout.RowWidth(width)) end,
        search = function(panel) ns.Safe(key, panel.list.Refill, panel.list) end }
end

local views = {} -- [view] = its window's spec, made once
local listed = {}
local function Windows()
    wipe(listed)
    for index, spec in ipairs(WINDOWS) do listed[index] = spec end
    for _, view in ipairs(ns.Feed.Views()) do
        views[view] = views[view] or View(view)
        listed[#listed + 1] = views[view]
    end
    return listed
end

-- The first layout: the rooms the full screen has at first (Layout.Board), side by side, each share as wide as its room:
-- the conversations and the friends list.
local function Default(width, height)
    local rooms = Layout.Board(width, height, { friends = true, talks = true, list = ns.store.talkList })
    local parts, shares = {}, {}
    for _, key in ipairs({ "talks", "friends" }) do
        if rooms[key] then parts[#parts + 1], shares[#shares + 1] = { key = key }, rooms[key][3] end
    end
    if #parts < 2 then return parts[1] end
    return { split = "x", parts = parts, shares = shares }
end

-- Core's window is made (Window.lua): its full screen is Core's board.
function Board.Take(window)
    layouts = Core.Board.New(window, {
        store = ns.store, key = "board", label = "Social",
        windows = Windows,
        default = function(width, height) return ns.Safe("board", Default, width, height) end,
        changed = function() ns.Guarded(ns.Window.Reboard) end,
    })
    Board.panels = layouts.panels
    Board.layouts = layouts
end

-- A panel's body in what the window holds: under its head.
local function Body(rect)
    local head = Core.Board.HEAD
    return { rect[1] + Layout.EDGE, rect[2] + head + Layout.EDGE, rect[3] - 2 * Layout.EDGE, rect[4] - head - 2 * Layout.EDGE }
end

-- Whether the layout laid out last holds a window.
function Board.Has(key)
    return layouts ~= nil and layouts:Has(key)
end

-- Whether the layout chosen holds a window, the full screen standing or not (the setup's ticks, Setup.lua).
function Board.Holds(key)
    return layouts ~= nil and layouts:Holds(key) or false
end

-- Where the setup puts a window it ticks: the friends list at the right of the conversations, the guild window at
-- the right of the friends list (of the conversations without it), as the first layout has them.
local BESIDE = { friends = { "talks", "right" }, guild = { "friends", "right" } }

-- A window of the full screen into the layout chosen, or off it (the setup's ticks): kept, laid out anew if it stands.
function Board.Put(key, on)
    if not layouts then return end
    local beside = BESIDE[key] or {}
    local target, side = beside[1], beside[2]
    if key == "guild" and not layouts:Holds("friends") then target, side = "talks", "right" end
    layouts:Put(key, on, target, side)
end

-- A chat view renamed: its window's head says so.
function Board.Retitle(key, title)
    for _, spec in pairs(views) do
        if spec.key == key then spec.title = title end
    end
    local panel = layouts and layouts.panels[key]
    if panel then panel.title:SetText(title) end
end

-- A chat view that is no more: out of every layout.
function Board.Forget(key)
    if layouts then layouts:Forget(key) end
    if layouts and layouts.standing then ns.Guarded(ns.Window.Reboard) end
end

-- What the lists of the friends list's tabs are built from, as the game builds its own: a list of rows
-- of one height (its scrolling list and scroll bar) between the head and a foot of buttons
-- (UIPanelButtonTemplate). init(row, element) draws a row, made by the list; the list is returned.
-- holder: a panel, or a part of one (holder.body, the frame to fill; holder.label, its name in the error
-- log); top: how far down the body the list starts (EDGE at first); extent(element): a list whose rows are not all
-- of one height (the conversations' heads), each element's height (ROW, if it fails).
function Board.List(holder, init, top, extent)
    local box = CreateFrame("Frame", nil, holder.body, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -(top or Layout.EDGE))
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.FOOT + Layout.EDGE)
    local scroll = CreateFrame("EventFrame", nil, holder.body, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 2)
    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, 0)
    -- The list draws its rows outside our own guard: nothing but the guard there (the name for the error log made
    -- here, once: a holder's name stays).
    local label = Board.Label(holder)
    if extent then
        view:SetElementExtentCalculator(function(_, element) return ns.Safe(label, extent, element) or Layout.ROW end)
    else
        view:SetElementExtent(Layout.ROW)
    end
    view:SetElementInitializer("Button", function(row, element) ns.Safe(label, init, row, element) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, scroll, view)
    box.provider = CreateDataProvider()
    box:SetDataProvider(box.provider)
    -- Said in the list's middle while it holds nothing.
    box.empty = holder.body:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    box.empty:SetPoint("LEFT", box, "LEFT", Layout.EDGE, 0)
    box.empty:SetPoint("RIGHT", box, "RIGHT", -Layout.EDGE, 0)
    box.empty:SetWordWrap(true)
    return box
end

-- The name a panel or a part of one has in the error log.
function Board.Label(holder)
    return holder.label or (holder.title and holder.title:GetText()) or "panel"
end

-- The list shows these elements now; text: what is said while there are none.
function Board.Fill(box, elements, text)
    box.provider:Flush()
    box.provider:InsertTable(elements)
    box.empty:SetText(text or "")
    box.empty:SetShown(#elements == 0)
end

-- A button of the panel's foot, the game's, that wide, side by side from the left (after: the one left of it).
-- panel: a panel or a part of one (Board.List).
function Board.Button(panel, text, width, click, after)
    local button = CreateFrame("Button", nil, panel.body, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    if after then
        button:SetPoint("LEFT", after, "RIGHT", 4, 0)
    else
        button:SetPoint("BOTTOMLEFT", Layout.EDGE, Layout.EDGE)
    end
    button:SetText(text)
    button:SetScript("OnClick", function(self) ns.Safe(Board.Label(panel), click, self) end)
    return button
end

-- A row of a list: the game's look for its friends list's rows (FriendsListButtonTemplate): a faint
-- background, a highlight under the mouse, kept while chosen (LockHighlight), and two lines of text.
function Board.Row(row)
    if row.top then return row end
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetPoint("TOPLEFT", 0, -1)
    row.back:SetPoint("BOTTOMRIGHT", 0, 1)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
    local highlight = row:GetHighlightTexture()
    if highlight then highlight:SetVertexColor(0.243, 0.570, 1) end -- the game's HIGHLIGHT_LIGHT_BLUE
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.top = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.top:SetJustifyH("LEFT")
    row.top:SetWordWrap(false)
    row.bottom = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    row.bottom:SetJustifyH("LEFT")
    row.bottom:SetWordWrap(false)
    row.side = row:CreateTexture(nil, "ARTWORK")
    row.right = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -6, 0)
    return row
end

-- The window stands full: what the window holds (inside) is that wide and high. The windows of the layout chosen
-- are put at their places (Core's board), the guild window held in its panel; returns where the chat stands: its own
-- window's body (own: true), else the part of the conversations beside their list and under the line with the name
-- of the one chosen (chat; none without either), and the conversations' rect (talks).
function Board.Show(room, width, height)
    inside = room
    local rects = layouts:Show(room, width, height)
    -- The game's guild window is held only while no module offers a guild window of its own.
    ns.Guild.Hold(rects.guild and not Core.Board.Offered("Social", "guild") and Body(rects.guild) or nil)
    local talks, board = rects.talks, { talks = rects.talks }
    local own = rects.chat
    if own then
        local head = Core.Board.HEAD
        board.chat, board.own = { own[1], own[2] + head, own[3], own[4] - head }, true
    elseif talks then
        local list = Layout.TalkList(ns.store.talkList, talks[3])
        local beside, under = list + 1, Core.Board.HEAD + Layout.TALK_HEAD
        board.chat = { talks[1] + beside, talks[2] + under, talks[3] - beside, talks[4] - under }
    end
    return board
end

-- The window is at its size, or on its way there: every panel out of sight, the guild window given back.
function Board.Hide()
    ns.Select.Clear()
    if layouts then layouts:Hide() end
    ns.Guild.Leave()
end

-- The search box of the full window: to every panel that is shown; one shown later finds it then.
function Board.Search(text)
    if layouts then layouts:Search(text or "") end
end
