local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Conversations
--  The conversations' panel of the full screen (Board.lua), at its left: the
--  list of conversations (Talks.lua), the last spoken in first, and beside it
--  the one chosen, its messages in the chat's bubbles (Bubble.lua) and a line
--  to write in it under them.
--
--      list      a row for each: the class icon of the one whispered with (the
--                game's Battle.net portrait for a Battle.net friend, the game's
--                conversation icon for a group), the name (the alias the player
--                gave, Core.People), the last message, its time, and how many
--                messages wait to be read; the panel's title counts them all
--      foot      Whisper (the game's line opens with /w, to name whom: its
--                name completion helps) and Remove (the conversation chosen,
--                with all its messages, once confirmed)
--      the one chosen: its name and the note about them on a line of their
--                own, its messages with a pill for each day, the line to write in
--
--  A click chooses a conversation: its messages are read. A right click on a
--  whisper opens the game's own menu of that player, as the friends list's does
--  (whisper, invite, ignore, Set Alias, Set Note). A conversation you begin
--  yourself (from anywhere: the chat's line, a name's menu) is chosen as soon
--  as your first message comes back. A group you are in is listed though
--  nobody spoke there yet, to write in.
--
--  The line to write in is an edit box of ours, unlike the chat's (the game's
--  own, Input.lua): Enter sends to the conversation as the game's line sends
--  (Talks.Send), and the line stays to write the next; Esc leaves it. A line
--  that starts with / is a command: it goes to the game's line, where Enter
--  runs it as the game runs commands. While chat is locked down (a fight, a
--  dungeon) only the game's own line sends: the words stay, and that is said.
--
--  Every message is there to read: none fades, none slides; at the newest the
--  list follows new ones, scrolled up it stays, as the second chat (Feed.lua).
--  The search box of the full window finds conversations by name and by their
--  messages; the one chosen then shows the messages found (all of them, if its
--  name was found). Shown, the panel listens to the game's groups and to
--  Battle.net; hidden, it only notes what came, and nothing is read.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Board, Layout, Bubble, Contacts, Talks = ns.Board, ns.Layout, ns.Bubble, ns.Contacts, ns.Talks
local Conversations = {}
ns.Conversations = Conversations

local GROUP = "Interface\\ChatFrame\\UI-ChatConversationIcon" -- the game's icon of a conversation
local BNET = "Interface\\FriendsFrame\\Battlenet-Portrait"    -- the game's portrait of Battle.net
local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"     -- a character whose class is not known yet
local DAY = 86400

local panel, side, box, remove     -- the panel; the list's part ({ body, label }), its list, the button Remove
local page, heading                 -- the part of the one chosen, and the line with its name over its messages
local chat, scroll, view, provider, empty -- its messages, and what is said where there are none
local edit, hint, fill              -- the line to write in, what it says while empty, its plate (Core's Shape)
local rowWidth                      -- of its messages
local shown, open                   -- the panel is on show; the conversation chosen
local follow = true                 -- at the newest message: it stays there when one comes
local typed, query = "", nil        -- what the search box holds, and what it finds (Core.Fuzzy.Query)
local list = {}                     -- the messages of the one chosen on show, a pill before each day
local pills = {}                    -- [day] = the pill of that day, while it says the same

-------------------------------------------------------------------------------
--  Words for a time
-------------------------------------------------------------------------------
local function Day(stamp)
    return date("%Y-%m-%d", stamp)
end

-- A day as a pill says it: Today, Yesterday, else its weekday and date in the game's words.
local function DayText(stamp)
    local now = time()
    local day = Day(stamp)
    if day == Day(now) then return ns.TEXT.today end
    if day == Day(now - DAY) then return ns.TEXT.yesterday end
    local at = date("*t", stamp)
    local names, short = rawget(_G, "CALENDAR_WEEKDAY_NAMES"), rawget(_G, "FormatShortDate")
    local when = short and short(at.day, at.month, at.year) or ("%d/%d/%d"):format(at.month, at.day, at.year)
    local weekday = type(names) == "table" and names[at.wday]
    return weekday and (weekday .. ", " .. when) or when
end

-- When a conversation's last message came, at its row: the time today, the date before.
local function When(stamp)
    if not stamp or stamp <= 0 then return "" end
    if Day(stamp) == Day(time()) then return date("%H:%M", stamp) end
    local at, short = date("*t", stamp), rawget(_G, "FormatShortDate")
    return short and short(at.day, at.month) or ("%d/%d"):format(at.month, at.day)
end

-- The pill before a day's first message: a note in the middle (Bubble.lua), grey.
local function Pill(stamp)
    local day, text = Day(stamp), DayText(stamp)
    local pill = pills[day]
    if not pill or pill.text ~= text then
        local grey = GRAY_FONT_COLOR
        pill = { side = "center", text = text, r = grey.r, g = grey.g, b = grey.b, time = "", day = day }
        pills[day] = pill
    end
    return pill
end

-------------------------------------------------------------------------------
--  The look of a conversation
-------------------------------------------------------------------------------
-- The colour of a conversation's name: a character's class (the game's friends list's yellow while not
-- known), a Battle.net friend's blue, a group's chat colour.
local function Colour(talk)
    if talk.kind == "WHISPER" then
        local class = talk.class and RAID_CLASS_COLORS[talk.class]
        if class then return { class.r, class.g, class.b } end
        return Contacts.WOW
    end
    if talk.kind == "BN_WHISPER" then return Contacts.BNET end
    local info = ChatTypeInfo and ChatTypeInfo[talk.kind]
    if info and info.r then return { info.r, info.g, info.b } end
    return { NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b }
end

local function Icon(texture, talk)
    if talk.kind == "BN_WHISPER" then return texture:SetTexture(BNET) end
    if talk.kind ~= "WHISPER" then return texture:SetTexture(GROUP) end
    if talk.class and GetClassAtlas then
        texture:SetAtlas(GetClassAtlas(talk.class:lower()))
    else
        texture:SetTexture(UNKNOWN)
    end
end

-- The note the player wrote about a character (Core.People); nil: none.
local function Note(talk)
    if talk.kind ~= "WHISPER" or not Core.People then return nil end
    return Core.People.Note(Core.People.Key(talk.with))
end

-- A conversation's last message, in short, under its name: whose (yours, or a speaker's in a group) and its words.
local function Preview(talk)
    local last = talk.messages[#talk.messages]
    if not last then return "" end
    local text = Core.Fuzzy.Plain(last.text or "")
    if last.side == "right" then return ns.TEXT.you .. ": " .. text end
    if Talks.GROUPS[talk.kind] and last.name then
        return (Core.People and Core.People.Shown(last.name) or last.name) .. ": " .. text
    end
    return text
end

-------------------------------------------------------------------------------
--  The list of conversations
-------------------------------------------------------------------------------
-- A row of the list (Board.Row, the friends list's look): icon, name, the last message; at its right the time
-- and how many wait to be read. The one chosen keeps its highlight.
local function Draw(row, talk)
    Board.Row(row)
    Contacts.Entry(row)
    row.talk = talk
    if not row.count then
        Core.Shape.Round(row.icon)
        row.count = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        row.count:SetPoint("BOTTOMRIGHT", -6, 5)
    end
    if row.invite then row.invite:Hide() end
    row.side:Hide()
    local back = Contacts.BACKS[talk.kind == "BN_WHISPER" and "bnet" or talk.kind == "WHISPER" and "wow" or "offline"]
    row.back:SetColorTexture(back[1], back[2], back[3], back[4])
    row.icon:ClearAllPoints()
    row.icon:SetSize(Layout.TALK_ICON, Layout.TALK_ICON)
    row.icon:SetPoint("LEFT", 5, 0)
    Icon(row.icon, talk)
    local left = Layout.TALK_ICON + 10
    row.top:ClearAllPoints()
    row.top:SetPoint("TOPLEFT", left, -4)
    row.top:SetPoint("TOPRIGHT", -44, -4)
    local colour = Colour(talk)
    row.top:SetText(Talks.Name(talk))
    row.top:SetTextColor(colour[1], colour[2], colour[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(Preview(talk))
    local unread = talk.unread > 0
    local words = unread and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
    row.bottom:SetTextColor(words.r, words.g, words.b)
    row.right:ClearAllPoints()
    row.right:SetPoint("TOPRIGHT", -6, -5)
    row.right:SetText(When(talk.last))
    row.right:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    row.count:SetText(unread and tostring(talk.unread) or "")
    if talk == open then row:LockHighlight() else row:UnlockHighlight() end
end

-- Who a whisper is with, as the friends list's tooltip names them: their name, the whole name or BattleTag
-- under it, the note about them.
local function Tip(row)
    local talk = row.talk
    if not talk or Talks.GROUPS[talk.kind] then return end
    local tip, shown = GameTooltip, Talks.Name(talk)
    tip:SetOwner(row, "ANCHOR_RIGHT", 4, 0)
    local colour = Colour(talk)
    tip:SetText(shown, colour[1], colour[2], colour[3])
    if talk.with and talk.with ~= shown then tip:AddLine(talk.with, GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b) end
    local note = Note(talk)
    if note then
        tip:AddLine(("|T%s:14:14|t %s"):format(Contacts.NOTE, note), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    tip:Show()
end

-- The game's own menu of the player a whisper is with, as its friends list opens it (and our lines in it,
-- Core.People). A Battle.net friend only while the game knows the account.
local function Menu(talk)
    if talk.kind == "WHISPER" then
        local show = rawget(_G, "FriendsFrame_ShowDropdown")
        if show then show(talk.with, true, nil, "WHISPER", DEFAULT_CHAT_FRAME) end
    elseif talk.kind == "BN_WHISPER" then
        local show, account = rawget(_G, "FriendsFrame_ShowBNDropdown"), Talks.Account(talk)
        if show and account then
            show(talk.name, true, nil, "BN_WHISPER", DEFAULT_CHAT_FRAME, nil, account, nil, nil, nil, nil, talk.with)
        end
    end
end

-------------------------------------------------------------------------------
--  The one chosen
-------------------------------------------------------------------------------
local function Bar()
    scroll:SetShown(not follow)
end

local function ToEnd()
    follow = true
    chat:ScrollToEnd(ScrollBoxConstants.NoScrollInterpolation)
    Bar()
end

local function Scrolled()
    follow = chat:IsAtEnd() or not chat:HasScrollableExtent()
    Bar()
end

local function Height(_, entry)
    return Bubble.Known(entry, rowWidth) or ns.Safe("conversations", Bubble.Measure, entry, rowWidth) or 1
end

local function DrawMessage(row, entry)
    ns.Safe("conversations", Bubble.Init, row, entry, rowWidth)
end

-- The search found the one chosen by its name: all its messages are on show.
local function Named(talk)
    return not query or Core.Fuzzy.Match(query, Talks.Name(talk), talk.with) ~= nil
end

-- A message of the one chosen is on show: no search, its name found, or the message (Window.Found, as the chat).
local function Visible(talk, message)
    return Named(talk) or ns.Window.Found(message)
end

-- A conversation is in the list: no search, or its name or one of its messages found.
local function Listed(talk)
    if Named(talk) then return true end
    for _, message in ipairs(talk.messages) do
        if ns.Window.Found(message) then return true end
    end
    return false
end

-- The line with the name of the one chosen, and the note about them (or a Battle.net friend's BattleTag).
local function Heading()
    if not open then return heading:SetText("") end
    local colour = Colour(open)
    local about = Note(open) or (open.kind == "BN_WHISPER" and open.with) or nil
    heading:SetText(Talks.Name(open) .. (about and ("  |cff" .. Core.Hex(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        .. about:gsub("|", "||") .. "|r") or ""))
    heading:SetTextColor(colour[1], colour[2], colour[3])
end

-- What the line to write in says while it is empty.
local function Hint()
    hint:SetShown((edit:GetText() or "") == "" and not edit:HasFocus())
end

-- The line can be written in while the one chosen can be (a group you are in, a friend Battle.net knows).
local function Line()
    local ok, why = false, nil
    if open then ok, why = Talks.Writable(open) end
    edit:SetEnabled(ok and true or false)
    if not ok and edit:HasFocus() then edit:ClearFocus() end
    hint:SetText(not open and "" or ok and ns.TEXT.talkHint:format(Talks.Name(open)) or why or "")
    Hint()
end

-- The messages of the one chosen anew, a pill before each day's first, at the newest. A Battle.net friend's
-- kept messages get the name the friend has in this session (Talks.lua).
local function Fill()
    wipe(list)
    if open then
        local day
        for _, message in ipairs(open.messages) do
            if Visible(open, message) then
                message.day = message.day or Day(message.stamp or 0)
                if message.day ~= day then
                    day = message.day
                    list[#list + 1] = Pill(message.stamp or 0)
                end
                if open.kind == "BN_WHISPER" and message.side == "left" and not message.name then message.name = Talks.Name(open) end
                list[#list + 1] = message
            end
        end
    end
    provider:Flush()
    provider:InsertTable(list)
    empty:SetText(not open and "" or #list > 0 and "" or query and ns.TEXT.noneFound or ns.TEXT.talkEmpty)
    empty:SetShown(#list == 0)
    ToEnd()
end

-- A new message of the one chosen: at the end, after a pill if a new day began.
local function Append(message)
    if list[#list] == message or not Visible(open, message) then return end
    local stick = follow
    message.day = message.day or Day(message.stamp)
    local last = list[#list]
    if not last or last.day ~= message.day then
        local pill = Pill(message.stamp)
        list[#list + 1] = pill
        provider:Insert(pill)
    end
    list[#list + 1] = message
    provider:Insert(message)
    empty:Hide()
    if stick then ToEnd() end
end

-------------------------------------------------------------------------------
--  The panel
-------------------------------------------------------------------------------
local function Title()
    local unread = Talks.Unread()
    panel.title:SetText(unread > 0 and ns.TEXT.talksCount:format(unread) or ns.TEXT.talks)
end

local Choose

-- The list anew: the conversations found, the groups you are in though nobody spoke there yet. One of them is
-- chosen while there are any: the one chosen before, if it is still listed, else the first.
local function Update()
    if not shown then return end
    for _, kind in ipairs(Talks.GROUP_ORDER) do
        if Talks.Writable({ kind = kind }) then Talks.Group(kind) end
    end
    local elements, listed = {}, false
    for _, talk in ipairs(Talks.list) do
        if (#talk.messages > 0 or Talks.Writable(talk)) and Listed(talk) then
            elements[#elements + 1] = talk
            listed = listed or talk == open
        end
    end
    Board.Fill(box, elements, query and ns.TEXT.noTalkFound or ns.TEXT.noTalks)
    if not listed then return Choose(elements[1]) end
    Title()
    Heading()
    Line()
    remove:SetEnabled(open ~= nil and #open.messages > 0)
end

-- A conversation chosen: its messages read and on show, its row marked.
Choose = function(talk)
    open = talk
    Talks.Read(talk)
    box:ForEachFrame(Draw)
    Title()
    Heading()
    Line()
    remove:SetEnabled(talk ~= nil and #talk.messages > 0)
    Fill()
end

local Changed = Core.Later(function() ns.Safe("conversations", Update) end)
-- Shown, it hears of the groups you join and leave, and of Battle.net friends (their names, whether they are there).
local EVENTS = { "GROUP_ROSTER_UPDATE", "GROUP_JOINED", "GROUP_LEFT", "BN_FRIEND_INFO_CHANGED", "BN_CONNECTED",
                 "BN_DISCONNECTED" }

local function Click(row, button)
    local talk = row.talk
    if not talk then return end
    if button == "RightButton" then return Menu(talk) end
    if talk ~= open then Choose(talk) end
end

-- Whisper: the game's line opens with /w, to name whom; once your first message comes back the conversation
-- is chosen (Added).
local function Start()
    ChatFrameUtil.OpenChat((rawget(_G, "SLASH_WHISPER1") or "/w") .. " ")
end

-- Remove: the one chosen and all its messages, once confirmed.
local function Remove()
    local talk = open
    if not talk then return end
    Core.Confirm(ns.TEXT.talkRemove, Talks.Name(talk), function()
        Talks.Remove(talk)
        Update()
    end)
end

-- While chat is locked down (a fight, a dungeon) the game sends only from its own line.
local function Locked()
    return C_ChatInfo and Core.Ask(C_ChatInfo.InChatMessagingLockdown) or false
end

-- Enter in the line: the words to the one chosen; a command to the game's line, where Enter runs it.
local function Send()
    local text = ((edit:GetText() or ""):gsub("[\r\n]+", " ")):match("^%s*(.-)%s*$")
    if text == "" or not open then return edit:ClearFocus() end
    if text:sub(1, 1) == "/" then
        edit:SetText("")
        edit:ClearFocus()
        return ChatFrameUtil.OpenChat(text)
    end
    if Locked() then return ns.Print(ns.TEXT.talkLocked) end
    local sent, why = Talks.Send(open, text)
    if sent then
        edit:SetText("")
    elseif why then
        ns.Print(why)
    end
end

-- A message came into a conversation (Talks.Add). Hidden, the panel lists them anew once it is shown.
local function Added(talk, message, new)
    if not panel or not shown then return end
    if new and message.side == "right" then
        open = talk
        Talks.Read(talk)
        Update()
        return Fill()
    end
    Update()
    if talk == open then Append(message) end
end
Talks.added = function(...) ns.Safe("conversations", Added, ...) end

function Conversations.Build(holder)
    panel = holder
    panel.title:SetText(ns.TEXT.talks)
    -- The list at the left, a line between it and the one chosen.
    local left = CreateFrame("Frame", nil, panel.body)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")
    left:SetWidth(Layout.TALK_LIST)
    side = { body = left, label = "conversations" }
    box = Board.List(side, function(row, talk)
        Draw(row, talk)
        row:SetScript("OnClick", function(self, button) ns.Safe("conversations", Click, self, button) end)
        row:SetScript("OnEnter", function(self) ns.Safe("conversations", Tip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide) -- unguarded: the game's own
    end)
    local width = math.floor((Layout.TALK_LIST - 2 * Layout.EDGE - 4) / 2)
    local start = Board.Button(side, Core.Word("WHISPER", "Whisper"), width, Start)
    remove = Board.Button(side, Core.Word("REMOVE", "Remove"), width, Remove, start)
    local divider = panel.body:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
    divider:SetPoint("TOPLEFT", Layout.TALK_LIST, -Layout.EDGE)
    divider:SetPoint("BOTTOMLEFT", Layout.TALK_LIST, Layout.EDGE)
    divider:SetWidth(1)

    -- The one chosen: its name on a line, its messages, the line to write in.
    page = CreateFrame("Frame", nil, panel.body)
    page:SetPoint("TOPLEFT", Layout.TALK_LIST + 1, 0)
    page:SetPoint("BOTTOMRIGHT")
    heading = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("TOPLEFT", Layout.EDGE + 4, -8)
    heading:SetPoint("TOPRIGHT", -Layout.EDGE, -8)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)

    local plate = CreateFrame("Frame", nil, page)
    plate:SetPoint("BOTTOMLEFT", Layout.EDGE, Layout.EDGE)
    plate:SetPoint("BOTTOMRIGHT", -Layout.EDGE, Layout.EDGE)
    plate:SetHeight(Layout.INPUT_HEIGHT - 2 * Layout.INPUT_INSET)
    fill = Core.Shape.New(plate, { radius = Layout.RADIUS }) -- the bubbles' plate, as the chat's line has
    fill:Follow()
    Bubble.Paint(fill)
    edit = CreateFrame("EditBox", nil, plate)
    edit:SetAllPoints()
    edit:SetFontObject(ChatFontNormal)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(255) -- a chat message's most, as the game's line
    edit:SetTextInsets(Layout.PAD_X, Layout.PAD_X, 0, 0)
    edit:SetScript("OnEnterPressed", function() ns.Safe("conversations", Send) end)
    edit:SetScript("OnEscapePressed", ns.Guard(function(self) self:ClearFocus() end))
    local hinted = ns.Guard(Hint)
    edit:SetScript("OnEditFocusGained", hinted)
    edit:SetScript("OnEditFocusLost", hinted)
    edit:SetScript("OnTextChanged", hinted)
    hint = edit:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    hint:SetPoint("LEFT", Layout.PAD_X, 0)
    hint:SetPoint("RIGHT", -Layout.PAD_X, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(false)

    chat = CreateFrame("Frame", nil, page, "WowScrollBoxList")
    chat:SetPoint("TOPLEFT", Layout.EDGE, -Layout.LINE)
    chat:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, 2 * Layout.EDGE + Layout.INPUT_HEIGHT - 2 * Layout.INPUT_INSET)
    scroll = CreateFrame("EventFrame", nil, page, "MinimalScrollBar")
    scroll:SetPoint("TOPLEFT", chat, "TOPRIGHT", 4, -2)
    scroll:SetPoint("BOTTOMLEFT", chat, "BOTTOMRIGHT", 4, 2)
    view = CreateScrollBoxListLinearView(0, 0, 0, 0, Layout.SPACING)
    view:SetElementExtentCalculator(Height)
    view:SetElementInitializer("Frame", DrawMessage)
    ScrollUtil.InitScrollBoxListWithScrollBar(chat, scroll, view)
    chat:SetInterpolateScroll(true)
    scroll:SetInterpolateScroll(true)
    provider = CreateDataProvider()
    chat:SetDataProvider(provider)
    chat:RegisterCallback(BaseScrollBoxEvents.OnScroll, ns.Guard(Scrolled), Conversations)
    empty = page:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("LEFT", chat, "LEFT", Layout.EDGE, 0)
    empty:SetPoint("RIGHT", chat, "RIGHT", -Layout.EDGE, 0)
    empty:SetWordWrap(true)
    Bar()
    Line()
end

-- Its panel is that wide: the messages are wrapped for the part beside the list.
function Conversations.Size(width)
    local now = Layout.RowWidth(width - Layout.TALK_LIST - 1)
    if now == rowWidth then return end
    rowWidth = now
    Conversations.Rewrap()
end

-- Shown, the one chosen is read and the list follows the game; hidden, nothing is read, nothing listens.
function Conversations.Show(on)
    shown = on
    Talks.Read(on and open or nil)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    if not on then
        if edit:HasFocus() then edit:ClearFocus() end
        return
    end
    Update()
    Fill()
end

function Conversations.Search(text)
    text = text or ""
    if text == typed then return end
    typed, query = text, Core.Fuzzy.Query(text)
    if not shown then return end
    Update()
    Fill()
end

-- Every message measured and drawn anew (a new width, text size or bubble look), the names anew (an alias).
function Conversations.Rewrap()
    if not chat then return end
    Bubble.Paint(fill)
    if rowWidth then
        local stick = follow
        chat:Rebuild(ScrollBoxConstants.RetainScrollPosition)
        if stick then ToEnd() end
    end
    if shown then Update() end
end
