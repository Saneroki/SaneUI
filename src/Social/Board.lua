local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Board
--  The full screen's panels around the chat: while the window stands full,
--  the friends list at its left (Friends.lua), the group finder at its right
--  (Finder.lua) and a second chat above the chat (Feed.lua), as the settings
--  wish (the section Full screen) and as the screen has room (Layout.Board).
--  The chat itself is the window's (Window.lua): it stands in the room left.
--
--  A panel is a frame of ours on a plate in Sane UI's look (Core.Skin: the
--  dark tile of the game's dialogs, a thin bronze trim, round corners), with a
--  head: its title at the left, its buttons at the right (panel.head). What is
--  under the head (panel.body) is its part's. Made the first time it is shown,
--  then kept. Out of sight while the window is at its size; a part listens to
--  the game only while its panel is shown (Part.Show). The panels come in with
--  a short fade once the window stands full, and go at once when it starts
--  back: they are never sized on the way.
--
--  A panel's part runs apart from the chat (ns.Safe): one that fails is noted
--  and the chat goes on; only the window's own work stands the module down.
--
--  What is typed into the full window's search box goes to every panel
--  (Board.Search): the second chat finds messages as the chat does, the
--  friends list friends, the group finder groups.
--
--  A part is a table with:
--      Part.Build(panel)      makes what it holds; panel.title, panel.head, panel.body are there
--      Part.Show(on)          its panel is shown (on) or hidden
--      Part.Search(text)      what is typed into the search box ("": nothing)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Board = {}
ns.Board = Board

Board.FADE = 0.3 -- seconds a panel takes to come in

-- The panels by their key in Layout.Board, with the switch that wishes each and its part.
Board.PANELS = {
    { key = "friends", wish = "boardFriends", part = "Friends" },
    { key = "finder", wish = "boardFinder", part = "Finder" },
    { key = "feed", wish = "boardFeed", part = "Feed" },
}
Board.panels = {} -- [key] = the panel, once made
local search = "" -- what is in the search box now

-- A panel in what the window holds (inside): its plate, a head with its title, a body under the head.
local function Make(inside, spec)
    local panel = CreateFrame("Frame", nil, inside)
    panel.skin = Core.Skin.New(panel, { radius = Layout.RADIUS })
    panel.head = CreateFrame("Frame", nil, panel)
    panel.head:SetPoint("TOPLEFT")
    panel.head:SetPoint("TOPRIGHT")
    panel.head:SetHeight(Layout.HEADER)
    panel.title = panel.head:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.title:SetPoint("LEFT", Layout.EDGE + 4, 0)
    local line = panel.head:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
    line:SetPoint("BOTTOMLEFT", Layout.EDGE, 0)
    line:SetPoint("BOTTOMRIGHT", -Layout.EDGE, 0)
    line:SetHeight(1)
    panel.body = CreateFrame("Frame", nil, panel)
    panel.body:SetPoint("TOPLEFT", 0, -Layout.HEADER)
    panel.body:SetPoint("BOTTOMRIGHT")
    panel.fade = Core.Motion.Fade(panel)
    panel.part = ns[spec.part]
    panel:Hide()
    ns.Safe(spec.key, panel.part.Build, panel)
    return panel
end

-- What the friends list and the group finder are built from, as the game builds its own: a list of rows
-- of one height (its scrolling list and scroll bar) between the head and a foot of buttons
-- (UIPanelButtonTemplate). init(row, element) draws a row, made by the list; the list is returned.
-- holder: a panel, or a part of one (holder.body, the frame to fill; holder.label, its name in the error
-- log); top: how far down the body the list starts (EDGE at first).
function Board.List(holder, init, top)
    local box = CreateFrame("Frame", nil, holder.body, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", Layout.EDGE, -(top or Layout.EDGE))
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, Layout.FOOT + Layout.EDGE)
    local scroll = CreateFrame("EventFrame", nil, holder.body, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 2)
    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, 0)
    view:SetElementExtent(Layout.ROW)
    view:SetElementInitializer("Button", function(row, element) ns.Safe(Board.Label(holder), init, row, element) end)
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

-- One panel at its place (a rect of Layout.Board), shown; or hidden (nil).
local function Put(inside, spec, rect)
    local panel = Board.panels[spec.key]
    if not rect then
        if panel and panel:IsShown() then
            panel:Hide()
            ns.Safe(spec.key, panel.part.Show, false)
        end
        return
    end
    panel = panel or Make(inside, spec)
    Board.panels[spec.key] = panel
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", inside, "TOPLEFT", rect[1], -rect[2])
    panel:SetSize(rect[3], rect[4])
    panel.skin:Rest()
    if panel:IsShown() then return end
    panel:Show()
    panel.fade:To(1, ns.options.animations and Board.FADE or 0, 0)
    ns.Safe(spec.key, panel.part.Show, true)
    ns.Safe(spec.key, panel.part.Search, search)
end

-- The window stands full: what the window holds (inside) is that wide and high. Each panel wished and with room
-- is put at its place; returns the board (Layout.Board), whose chat is the room left for the chat.
function Board.Show(inside, width, height)
    local options = ns.options
    local want = { friends = options.boardFriends, finder = options.boardFinder, feed = options.boardFeed }
    local board = Layout.Board(width, height, want, options.feedShare / 100)
    -- The second chat is as wide as the chat (Window.lua tells it so too): its messages are measured once,
    -- for that width, when it first fills its list.
    ns.Feed.Fit(Layout.RowWidth(board.chat[3]))
    for _, spec in ipairs(Board.PANELS) do Put(inside, spec, board[spec.key]) end
    return board
end

-- The window is at its size, or on its way there: every panel out of sight.
function Board.Hide()
    for _, spec in ipairs(Board.PANELS) do Put(nil, spec, nil) end
end

-- The search box of the full window: to every panel that is shown; one shown later finds it then (Put).
function Board.Search(text)
    search = text or ""
    for _, panel in pairs(Board.panels) do
        if panel:IsShown() then ns.Safe("search", panel.part.Search, search) end
    end
end
