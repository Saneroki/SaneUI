local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Social - Conversations
--  The conversations' panel of the full screen (Board.lua), at its left: the
--  list of conversations (Talks.lua), the newest message first, and beside it
--  the one chosen, its messages in the chat's bubbles (Bubble.lua) and a line
--  to write in it under them. First in the list stands the chat (unless the
--  layout has it as a window of its own, Board.lua): chosen, it stands beside
--  the list where a conversation's messages do, in the window's frame for the
--  chat (Window.Pick), with its own line to write in, the game's. Then the
--  chat views (Feed.lua), as many as you made: chosen, one stands there in a
--  list of its own (views).
--
--      list      the chat with the game's chat icon, then each chat view, then
--                a row for each conversation: the class icon of the one whispered
--                with (the game's Battle.net portrait for a Battle.net friend, the
--                game's conversation icon for a group), the name (the alias the
--                player gave, Core.People), the last message, its time, and how
--                many messages wait to be read; the panel's title counts them all.
--                A row with messages not seen yet is lit with the glow the game's
--                chat tabs have for a new message, in its chat's colour. The
--                conversations stand in two parts, not mixed (Saneroki, 2026-11-18):
--                the whispers, then the groups' (party, raid, instance), each under
--                a head with the game's +/- (its quest log's): a click folds the
--                part away, and shows it again (kept: store.talkFolds); folded, the
--                head counts what waits in it and is lit as a row is
--      foot      New chat view (one more view, showing nothing until its chats
--                are ticked), then Whisper (the game's line opens with /w, to name
--                whom: its name completion helps) and Remove (the one chosen, a
--                conversation with all its messages or a chat view, once
--                confirmed)
--      the one chosen: its name and the note about them on a line of their
--                own, its messages with a pill for each day, the line to write in;
--                the chat's and a chat view's line has the list of the chats each
--                shows, with their ticks (the chat's are those of the list on its
--                line's name too)
--
--  A click chooses a conversation: its messages are read. A right click on a
--  whisper opens the game's own menu of that player, as the friends list's does
--  (whisper, invite, ignore, Set Alias, Set Note), with Social's lines and
--  Delete conversation (PlayerMenu.lua; Saneroki, 2026-11-18: "rightclick on
--  whispers and group windows to say Delete the conversation"); on a group's,
--  its name and Delete conversation; on a chat view, Rename, Remove and Its own
--  window on the screen (ChatWindows.lua). A conversation you begin
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
--  The game's line opened while a conversation is chosen (Opened): by Enter
--  alone, the conversation's line takes the cursor instead; a reply or a
--  whisper to somebody with a conversation chooses theirs, the same; anything
--  else (a command, a whisper to somebody new) chooses the chat, whose line
--  it is. A conversation chosen while the game's line is in use closes that.
--
--  The line between the list and the one chosen can be dragged, the list
--  made wider or narrower (Layout.TalkList: its least, and the least of the
--  one chosen). While it is held only the line follows the mouse; let go, the
--  list is that wide, kept (store.talkList), and the full screen is laid out
--  anew once: the messages beside it are wrapped once for their new width,
--  not at every step, as the window does when it is sized.
--
--  Every message is there to read: none fades, none slides; at the newest the
--  list follows new ones, scrolled up it stays, as a chat view's (Feed.lua).
--  Its words are picked to copy as the chat's are (Select.lua), the days'
--  pills aside.
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
local DAY = 86400

-- The chat in the list: chosen, it stands in the window's frame for the chat (Window.Pick). A chat view's row (Row).
local CHAT = { pinned = "chat", icon = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up" }
local VIEW = "Interface\\ChatFrame\\UI-ChatWhisperIcon"        -- a chat view's icon
local GLOW = "Interface\\ChatFrame\\ChatFrameTab-NewMessage"   -- the game's chat tabs' light for a new message
local rows = {}                                                -- [view] = its row in the list, made once
local BNET = "Interface\\FriendsFrame\\Battlenet-Portrait"    -- the game's portrait of Battle.net
local UNKNOWN = "Interface\\Icons\\INV_Misc_QuestionMark"     -- a character whose class is not known yet
local FOLDED = "Interface\\Buttons\\UI-PlusButton-Up"         -- a part folded away: the game's +, as its quest log's
local UNFOLDED = "Interface\\Buttons\\UI-MinusButton-Up"      -- a part shown: its -
local FOLD = 14                                               -- the +/- that large
-- The parts of the list, in their order: whom a conversation is with decides (Part). kind: the chat whose colour lights
-- a folded part's head for what waits in it.
local PARTS = {
    { key = "whispers", text = ns.TEXT.whispers, kind = "WHISPER" },
    { key = "groups", text = ns.TEXT.groups, kind = "PARTY" },
}
local heads = {}                                              -- [key] = the head of that part in the list, made once

local panel, side, box, remove     -- the panel; the list's part ({ body, label }), its list, the button Remove
local start, add                    -- the buttons Whisper and New chat view
local views                         -- the list of the chat view chosen (Feed.New), beside the list
local divider, grip                 -- the line between the list and the one chosen, the strip over it to drag it
local listWidth = Layout.TALK_LIST  -- the list's width now (Layout.TalkList)
local panelWidth                    -- the panel's, once it is known (Size)
local page, heading, filter         -- the part of the one chosen, the line with its name, the chats the chat shows
local mine                          -- what of that part is a conversation's own: its messages and its line
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
    if Day(stamp) == Day(time()) then return Core.ClockAt(stamp) end
    local at, short = date("*t", stamp), rawget(_G, "FormatShortDate")
    return short and short(at.day, at.month) or ("%d/%d"):format(at.month, at.day)
end

-- The pill before a day's first message: a note in the middle (Bubble.lua), grey.
local function Pill(stamp)
    local day, text = Day(stamp), DayText(stamp)
    local pill = pills[day]
    if not pill or pill.text ~= text then
        local grey = GRAY_FONT_COLOR
        pill = { side = "center", text = text, r = grey.r, g = grey.g, b = grey.b, time = "", day = day, pill = true }
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
    if talk.pinned then return { NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b } end
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
    if talk.pinned then return texture:SetTexture(talk.icon) end
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

-- The name in the list and over the messages: the chat's, a chat view's, a conversation's.
local function Name(talk)
    if talk == CHAT then return Core.Word("CHAT", "Chat") end
    if talk.view then return talk.view.name end
    return Talks.Name(talk)
end

-- Its last message: the chat's last on show (Window.lua), a chat view's (Feed.lua), a conversation's.
local function Last(talk)
    if talk == CHAT then return ns.Window.Last() end
    if talk.view then return ns.Feed.Last(talk.view) end
    return talk.messages[#talk.messages]
end

-- The last message, in short, under its name: whose (yours, or a speaker's where many speak) and its words.
local function Preview(talk)
    local last = Last(talk)
    if not last then return "" end
    local text = ns.Log.Readable(last)
    if last.side == "right" then return ns.TEXT.you .. ": " .. text end
    if (talk.pinned or Talks.GROUPS[talk.kind]) and last.name then
        return (Core.People and Core.People.Shown(last.name) or last.name) .. ": " .. text
    end
    return text
end

-- When its last message came, at its row: the chat's by the time the chat gives it.
local function Time(talk)
    if not talk.pinned then return When(talk.last) end
    local last = Last(talk)
    return last and last.time or ""
end

-------------------------------------------------------------------------------
--  The list of conversations
-------------------------------------------------------------------------------
-- How many of its messages are not seen yet, and the chat colour to light its row in (nil: its name's).
local function Unread(talk)
    if talk == CHAT then return ns.Window.Unread() end
    if talk.view then return ns.Feed.Unread(talk.view) end
    return talk.unread or 0, nil
end

-- A chat view's row in the list, the same table always (the one chosen is known by it).
local function Row(view)
    rows[view] = rows[view] or { pinned = "view", view = view, icon = VIEW }
    return rows[view]
end

-- What a row of this list has beyond Board.Row's, made once: the list hands its rows from a conversation to a
-- head and back. The icon round; how many wait, the glow, a head's +/- (not the icon: that is cut round).
local function Parts(row)
    Board.Row(row)
    if row.count then return end
    Core.Shape.Round(row.icon)
    row.count = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.glow = row:CreateTexture(nil, "BORDER")
    row.glow:SetTexture(GLOW)
    row.glow:SetBlendMode("ADD")
    row.glow:SetPoint("TOPLEFT", 0, -1)
    row.glow:SetPoint("BOTTOMRIGHT", 0, 1)
    row.fold = row:CreateTexture(nil, "ARTWORK")
    row.fold:SetSize(FOLD, FOLD)
    row.fold:SetPoint("LEFT", 6, 0)
end

-- The glow on a row with messages not seen yet, in that colour; none on the one chosen.
local function Glow(row, lit, colour)
    row.glow:SetShown(lit)
    if lit then row.glow:SetVertexColor(colour[1], colour[2], colour[3]) end
end

local function Count(waiting)
    return waiting > 0 and (waiting > 99 and "99+" or tostring(waiting)) or ""
end

-- A part's head (Head): the game's - or + before its name, in the game's gold; folded, how many messages wait in it
-- at its right, lit as a row with messages not seen yet.
local function DrawHead(row, head)
    Parts(row)
    row.talk = head
    row:EnableMouse(true)
    row.back:Hide()
    row.icon:Hide()
    row.side:Hide()
    if row.invite then row.invite:Hide() end
    row.fold:Show()
    row.fold:SetTexture(head.folded and FOLDED or UNFOLDED)
    row.top:ClearAllPoints()
    row.top:SetPoint("LEFT", row.fold, "RIGHT", 5, 0)
    row.top:SetPoint("RIGHT", -44, 0)
    row.top:SetText(head.part.text)
    row.top:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
    row.bottom:SetText("")
    row.right:SetText("")
    local waiting = head.folded and head.unread or 0
    row.count:ClearAllPoints()
    row.count:SetPoint("RIGHT", -6, 0)
    row.count:SetText(Count(waiting))
    local info = ChatTypeInfo and ChatTypeInfo[head.part.kind]
    Glow(row, waiting > 0, info and info.r and { info.r, info.g, info.b } or { NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b })
    row:UnlockHighlight()
end

-- A row of the list (Board.Row, the friends list's look): icon, name, the last message; at its right the time
-- and how many wait to be read. The one chosen keeps its highlight; one with messages not seen yet is lit.
local function Draw(row, talk)
    if talk.head then return DrawHead(row, talk) end
    Parts(row)
    Contacts.Entry(row)
    row.talk = talk
    row.fold:Hide()
    row.count:ClearAllPoints()
    row.count:SetPoint("BOTTOMRIGHT", -6, 5)
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
    row.top:SetText(Name(talk))
    row.top:SetTextColor(colour[1], colour[2], colour[3])
    row.bottom:ClearAllPoints()
    row.bottom:SetPoint("TOPLEFT", row.top, "BOTTOMLEFT", 0, -3)
    row.bottom:SetPoint("TOPRIGHT", row.top, "BOTTOMRIGHT", 0, -3)
    row.bottom:SetText(Preview(talk))
    local waiting, tint = Unread(talk)
    local unread = waiting > 0
    local words = unread and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
    row.bottom:SetTextColor(words.r, words.g, words.b)
    row.right:ClearAllPoints()
    row.right:SetPoint("TOPRIGHT", -6, -5)
    row.right:SetText(Time(talk))
    row.right:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
    row.count:SetText(Count(waiting))
    Glow(row, unread and talk ~= open, tint or colour)
    if talk == open then row:LockHighlight() else row:UnlockHighlight() end
end

-- How high an element of the list is: a part's head lower than a row.
local function RowHeight(element)
    return element.head and Layout.TALK_PART or Layout.ROW
end

-- Who a whisper is with, as the friends list's tooltip names them: their name, the whole name or BattleTag
-- under it, the note about them.
local function Tip(row)
    local talk = row.talk
    if talk and talk.head then return Core.ShowTip(row, talk.part.text, ns.TEXT.partTip) end
    if not talk or talk.pinned or Talks.GROUPS[talk.kind] then return end
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

-- The list asks outside our own guard: behind one of ours, and never a height of nothing (it would stop the list).
local function Measured(entry)
    return Bubble.Known(entry, rowWidth) or Bubble.Measure(entry, rowWidth)
end

local function Height(_, entry)
    return ns.Safe("conversations", Measured, entry) or 1
end

local function DrawMessage(row, entry)
    ns.Safe("conversations", Bubble.Init, row, entry, rowWidth)
end

-- The search found the one chosen by its name: all its messages are on show.
local function Named(talk)
    return not query or Core.Fuzzy.Match(query, Name(talk), talk.with) ~= nil
end

-- A message of the one chosen is on show: no search, its name found, or the message (Window.Found, as the chat).
local function Visible(talk, message)
    return Named(talk) or ns.Window.Found(message)
end

-- A conversation is in the list: no search, or its name or one of its messages found. The chat and the second
-- chat always are: they find their messages themselves (Window.Found).
local function Listed(talk)
    if talk.pinned or Named(talk) then return true end
    for _, message in ipairs(talk.messages) do
        if ns.Window.Found(message) then return true end
    end
    return false
end

-- The line with the name of the one chosen, and the note about them (or a Battle.net friend's BattleTag).
-- The chat's and the second chat's line has the list of the chats each shows at its right.
local function Heading()
    filter:SetShown(open ~= nil and open.pinned ~= nil)
    heading:SetPoint("TOPRIGHT", open and open.pinned and -(2 * Layout.EDGE + filter:GetWidth()) or -Layout.EDGE, -8)
    if not open then return heading:SetText("") end
    local colour = Colour(open)
    local about = Note(open) or (open.kind == "BN_WHISPER" and open.with) or nil
    heading:SetText(Name(open) .. (about and ("  |cff" .. Core.Hex(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
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
    if open and not open.pinned then ok, why = Talks.Writable(open) end
    edit:SetEnabled(ok and true or false)
    if not ok and edit:HasFocus() then edit:ClearFocus() end
    hint:SetText(not open and "" or ok and ns.TEXT.talkHint:format(Talks.Name(open)) or why or "")
    Hint()
end

-- The messages of the one chosen anew, a pill before each day's first, at the newest. A Battle.net friend's
-- kept messages get the name the friend has in this session (Talks.lua).
local function Fill()
    wipe(list)
    if open and not open.pinned then
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
    if open.pinned or list[#list] == message or not Visible(open, message) then return end
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

local Choose, Removable

-- The one chosen can be removed: a chat view, a conversation with messages; never the chat.
Removable = function(talk)
    if not talk or talk == CHAT then return false end
    return talk.view ~= nil or #talk.messages > 0
end

-------------------------------------------------------------------------------
--  The parts of the list
-------------------------------------------------------------------------------
-- The part a conversation stands in: a group's, else the whispers' (a character's, a Battle.net friend's).
local function Part(talk)
    return Talks.GROUPS[talk.kind] and "groups" or "whispers"
end

-- The parts folded away, as kept (saved data comes from older versions and from hand edits).
local function Folds()
    local folds = ns.store.talkFolds
    if type(folds) ~= "table" then
        folds = {}
        ns.store.talkFolds = folds
    end
    return folds
end

local function Folded(key)
    return Folds()[key] == true
end

-- The head of a part in the list, the same table always: part, and as the list was made last, folded and how many
-- messages wait in it.
local function Head(part)
    heads[part.key] = heads[part.key] or { head = true, part = part, unread = 0 }
    return heads[part.key]
end

-- The part of a conversation chosen by itself (your first whisper to somebody, a reply) shown, if it was folded away:
-- true then.
local function Unfold(talk)
    if not talk or talk.pinned or talk.head then return false end
    local folds, key = Folds(), Part(talk)
    if not folds[key] then return false end
    folds[key] = nil
    return true
end

-- The list anew: the chat (unless it has a window of its own), the chat views, then the conversations found and the
-- groups you are in though nobody spoke there yet, each in its part under that part's head (a part with none has no
-- head); a part folded away shows only its head, while nothing is searched for. One of them is chosen while there are
-- any: the one chosen before, if it is still there (also in a part folded away), else the first that is no head.
local function Update()
    if not shown then return end
    Talks.Groups()
    local elements, listed = {}, false
    if not Board.Has("chat") then
        elements[1], listed = CHAT, open == CHAT
    end
    for _, view in ipairs(ns.Feed.Views()) do
        local element = Row(view)
        elements[#elements + 1] = element
        listed = listed or element == open
    end
    local parts = {}
    for _, talk in ipairs(Talks.list) do
        if (#talk.messages > 0 or Talks.Writable(talk)) and Listed(talk) then
            local key = Part(talk)
            parts[key] = parts[key] or {}
            parts[key][#parts[key] + 1] = talk
            listed = listed or talk == open
        end
    end
    for _, part in ipairs(PARTS) do
        local talks = parts[part.key]
        if talks then
            local head = Head(part)
            head.folded = not query and Folded(part.key)
            head.unread = 0
            elements[#elements + 1] = head
            for _, talk in ipairs(talks) do
                head.unread = head.unread + (talk.unread or 0)
                if not head.folded then elements[#elements + 1] = talk end
            end
        end
    end
    Board.Fill(box, elements)
    if not listed then
        local first
        for _, element in ipairs(elements) do
            if not element.head then first = element break end
        end
        return Choose(first)
    end
    Title()
    Heading()
    Line()
    remove:SetEnabled(Removable(open))
end

-- The list of the chats the chat shows, ticked as in the list on its line's name (Menu.lua).
local function IsShown(chat) return ns.Guarded(ns.Channels.Shown, chat.group) end
local function Switch(chat) ns.Guarded(ns.Channels.Flip, chat.group) end
-- The game asks for the list when it opens, outside our own guard.
local Showing = ns.Guard(function(_, root)
    root:CreateTitle(ns.TEXT.showing)
    for _, chat in ipairs(ns.Channels.Showable()) do
        root:CreateCheckbox(chat.text, IsShown, Switch, chat)
    end
end)

-- A conversation chosen: its messages read and on show, its row marked. The chat chosen: it stands beside the list
-- (Window.Pick); a chat view: its list there (views). Another than the chat chosen while the game's line is in use
-- there: that is closed (with the chat's own window it stays, it is there).
Choose = function(talk)
    open = talk
    ns.Select.Clear()
    if Unfold(talk) then Update() end -- (open is the one chosen already: Update chooses none)
    local pinned = talk and talk.pinned
    Talks.Read(not pinned and talk or nil)
    mine:SetShown(not pinned)
    views:Point(talk and talk.view or nil)
    views:Show(talk ~= nil and talk.view ~= nil)
    if pinned then filter:SetupMenu(talk.view and ns.Feed.Menu(talk.view) or Showing) end -- guarded: Feed.Menu's and Showing are ns.Guard(fn)
    if pinned ~= "chat" and ns.Window.Writing() and not Board.Has("chat") then ns.Input.Close() end
    ns.Window.Pick(pinned == "chat" and "chat" or nil)
    box:ForEachFrame(Draw)
    Title()
    Heading()
    Line()
    remove:SetEnabled(Removable(talk))
    Fill()
end

local Changed = Core.Later(function() ns.Safe("conversations", Update) end)
-- Shown, it hears of the groups you join and leave, and of Battle.net friends (their names, whether they are there).
local EVENTS = { "GROUP_ROSTER_UPDATE", "GROUP_JOINED", "GROUP_LEFT", "BN_FRIEND_INFO_CHANGED", "BN_CONNECTED",
                 "BN_DISCONNECTED" }

-- A chat view removed, once confirmed: out of the list and of every layout.
local function Forget(talk)
    Core.Confirm(ns.TEXT.viewRemove, talk.view.name, function()
        ns.Feed.Remove(talk.view)
        rows[talk.view] = nil
        Update()
    end)
end

-- A right click on a chat view: Rename, Remove.
local function ViewMenu(owner, talk)
    MenuUtil.CreateContextMenu(owner, ns.Guard(function(_, root)
        root:CreateTitle(talk.view.name)
        root:CreateButton(ns.TEXT.rename, ns.Guard(function()
            Core.AskText(ns.TEXT.viewRename, nil, Core.Word("ACCEPT", "Accept"), talk.view.name, function(text)
                ns.Feed.Rename(talk.view, text)
                Update()
                box:ForEachFrame(Draw)
            end, 32)
        end))
        root:CreateButton(Core.Word("REMOVE", "Remove"), ns.Guard(function() Forget(talk) end))
        -- On the screen as a chat window of its own beside the chat, once the full screen goes (ChatWindows.lua).
        root:CreateCheckbox(ns.TEXT.onScreen, ns.Guard(function() return talk.view.screen == true end),
            ns.Guard(function() ns.ChatWindows.Flip(talk.view) end))
    end))
end

-- A head clicked: its part folded away, or shown again.
local function Fold(head)
    local folds = Folds()
    folds[head.part.key] = not folds[head.part.key] or nil
    Update()
end

local function Click(row, button)
    local talk = row.talk
    if not talk then return end
    if talk.head then return Fold(talk) end
    if button == "RightButton" then
        if talk.view then return ViewMenu(row, talk) end
        if talk.pinned then return end -- the chat: no menu
        return ns.PlayerMenu.Talk(row, talk, Update)
    end
    if talk ~= open then Choose(talk) end
end

-- New chat view: one more, chosen, showing nothing until its chats are ticked (the list on its name's line).
local function NewView()
    local view = ns.Feed.Make()
    Update()
    Choose(Row(view))
end

-- Whisper: the game's line opens with /w, to name whom; once your first message comes back the conversation
-- is chosen (Added).
local function Start()
    ChatFrameUtil.OpenChat((rawget(_G, "SLASH_WHISPER1") or "/w") .. " ")
end

-- Remove: the one chosen and all its messages, once confirmed; a chat view, out of every layout too.
local function Remove()
    local talk = open
    if not Removable(talk) then return end
    if talk.view then return Forget(talk) end
    Core.Confirm(ns.TEXT.talkRemove, Talks.Name(talk), function()
        Talks.Remove(talk)
        Update()
    end)
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
    -- While chat is locked down (a fight, a dungeon) the game sends only from its own line.
    if ns.ChatLocked() then return ns.Print(ns.TEXT.talkLocked) end
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
    -- Your own first message to somebody new: their conversation is chosen, whole (the chat or a chat view out of sight).
    if new and message.side == "right" and not ns.Window.Writing() then
        Update()
        return Choose(talk)
    end
    -- The list anew once a frame (Changed), not for each message of a busy group; the one chosen shows it at once.
    Changed()
    if talk == open then Append(message) end
end
Talks.added = function(...) ns.Safe("conversations", Added, ...) end

-- A message came into the chat's log (Window.lua): the rows of the chat and the second chat show it, once a frame.
local Redraw = Core.Later(function()
    if shown then ns.Safe("conversations", box.ForEachFrame, box, Draw) end
end)
function Conversations.Said()
    if shown then Redraw() end
end

-- The game's line was opened while a conversation or a chat view is chosen, the chat out of sight (Window.lua). A
-- frame later, when the game has given it the cursor: a chat view chosen, the chat is chosen, whose line it is. A
-- conversation chosen: opened by Enter alone (empty, not a whisper), the conversation's own line takes over, if it
-- can be written in; a whisper to somebody with a conversation (a reply, a name's Whisper) chooses theirs, the
-- same; anything else chooses the chat.
local function Opened()
    local line = ns.Input.Line()
    if not shown or not line or not open or open == CHAT or Board.Has("chat") then return end
    if open.view then return Choose(CHAT) end
    local text, kind = line:GetText() or "", line:GetChatType()
    local talk = open
    if text == "" and kind == "WHISPER" then
        -- In chat lockdown the one to reply to may be a name the game hides: then none is known.
        talk = Talks.Whisper(Core.Plain(line:GetTellTarget()))
    elseif text ~= "" or kind == "BN_WHISPER" then
        talk = nil
    end
    if not talk or not Talks.Writable(talk) then return Choose(CHAT) end
    ns.Input.Close()
    if talk ~= open then Choose(talk) end
    edit:SetFocus()
end
local Open = Core.Later(function() ns.Safe("conversations", Opened) end)
function Conversations.Chat()
    if shown and open and open ~= CHAT then Open() end
end

-------------------------------------------------------------------------------
--  The line between the list and the one chosen
-------------------------------------------------------------------------------
-- The line that far from the panel's left; bright while the mouse is on it or holds it.
local function Rule(x)
    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT", x, -Layout.EDGE)
    divider:SetPoint("BOTTOMLEFT", x, Layout.EDGE)
end

local function Light(on)
    divider:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], on and 0.9 or 0.35)
end

-- The list that wide, its two buttons sharing it, the line and the one chosen beside it.
local function Divide(width)
    listWidth = width
    side.body:SetWidth(width)
    local half = math.floor((width - 2 * Layout.EDGE - 4) / 2)
    start:SetWidth(half)
    remove:SetWidth(half)
    add:SetWidth(2 * half + 4)
    Rule(width)
    page:SetPoint("TOPLEFT", width + 1, 0)
end

-- While the line is held: where the mouse and the list's width were when it was taken, and the width it is at.
local held

local function Pointer()
    return (GetCursorPosition()) / panel.body:GetEffectiveScale()
end

local Follow = ns.Guard(function()
    held.width = Layout.TalkList(held.from + Pointer() - held.x, panelWidth)
    Rule(held.width)
end)

local function Take(_, button)
    if button ~= "LeftButton" or not panelWidth or held then return end
    held = { x = Pointer(), from = listWidth, width = listWidth }
    Light(true)
    grip:SetScript("OnUpdate", Follow)
end

-- Let go (or the full screen went meanwhile: hidden): the list as wide as it was left, kept, and the full screen
-- laid out anew once.
local function Let()
    if not held then return end
    local width = held.width
    held = nil
    grip:SetScript("OnUpdate", nil)
    if not (grip:IsVisible() and grip:IsMouseOver()) then
        SetCursor(nil)
        Light(false)
    end
    if width == listWidth then return end
    ns.store.talkList = width
    if grip:IsVisible() then ns.Window.Reboard() else Rule(listWidth) end
end

local function Enter()
    SetCursor("UI_RESIZE_CURSOR")
    Light(true)
end

local function Leave()
    if held then return end
    SetCursor(nil)
    Light(false)
end

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
        if row.wired then return end -- its scripts once: the list hands its rows from one conversation to another
        row.wired = true
        row:SetScript("OnClick", function(self, button) ns.Safe("conversations", Click, self, button) end)
        row:SetScript("OnEnter", function(self) ns.Safe("conversations", Tip, self) end)
        row:SetScript("OnLeave", GameTooltip_Hide) -- unguarded: the game's own
    end, nil, RowHeight) -- a part's head lower than a row
    start = Board.Button(side, Core.Word("WHISPER", "Whisper"), 1, Start)
    remove = Board.Button(side, Core.Word("REMOVE", "Remove"), 1, Remove, start)
    add = Board.Button(side, ns.TEXT.newViewButton, 1, NewView)
    add:ClearAllPoints()
    add:SetPoint("BOTTOMLEFT", start, "TOPLEFT", 0, 4)
    box:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, 2 * Layout.FOOT + Layout.EDGE) -- above both rows of buttons
    divider = panel.body:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    Light(false)

    -- The one chosen: its name on a line, its messages, the line to write in. The chat and the second chat stand
    -- under that line where a conversation's messages and line do (Layout.Board: board.chat).
    page = CreateFrame("Frame", nil, panel.body)
    page:SetPoint("BOTTOMRIGHT")
    Divide(listWidth)

    -- The strip over the line that takes the mouse: above the list and the one chosen, whose edges it overlaps.
    grip = CreateFrame("Frame", nil, panel.body)
    grip:SetPoint("TOP", divider, "TOP")
    grip:SetPoint("BOTTOM", divider, "BOTTOM")
    grip:SetWidth(Layout.TALK_GRIP)
    grip:SetFrameLevel(panel.body:GetFrameLevel() + 20)
    grip:EnableMouse(true)
    grip:SetScript("OnMouseDown", ns.Guard(Take))
    grip:SetScript("OnMouseUp", ns.Guard(Let))
    grip:SetScript("OnHide", ns.Guard(Let))
    grip:SetScript("OnEnter", ns.Guard(Enter))
    grip:SetScript("OnLeave", ns.Guard(Leave))
    heading = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("TOPLEFT", Layout.EDGE + 4, -8)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)
    filter = CreateFrame("DropdownButton", nil, page, "WowStyle1FilterDropdownTemplate")
    filter:SetPoint("TOPRIGHT", -Layout.EDGE, -(Layout.TALK_HEAD - 22) / 2)
    filter:SetWidth(100)
    filter:SetText(ns.TEXT.feedFilter)
    filter:Hide()
    mine = CreateFrame("Frame", nil, page)
    mine:SetAllPoints()
    views = ns.Feed.New(nil, page, Layout.TALK_HEAD) -- the chat view chosen, under the line with its name

    local plate = CreateFrame("Frame", nil, mine)
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
    Core.Caret(edit)
    hint = edit:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    hint:SetPoint("LEFT", Layout.PAD_X, 0)
    hint:SetPoint("RIGHT", -Layout.PAD_X, 0)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(false)

    chat = CreateFrame("Frame", nil, mine, "WowScrollBoxList")
    chat:SetPoint("TOPLEFT", Layout.EDGE, -Layout.TALK_HEAD)
    chat:SetPoint("BOTTOMRIGHT", -Layout.EDGE - Layout.SCROLL, 2 * Layout.EDGE + Layout.INPUT_HEIGHT - 2 * Layout.INPUT_INSET)
    scroll = CreateFrame("EventFrame", nil, mine, "MinimalScrollBar")
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
    ns.Select.Attach(chat, list) -- its words are picked to copy, the days' pills aside
    ns.Select.Allow(chat, true)
    empty = mine:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    empty:SetPoint("LEFT", chat, "LEFT", Layout.EDGE, 0)
    empty:SetPoint("RIGHT", chat, "RIGHT", -Layout.EDGE, 0)
    empty:SetWordWrap(true)
    Bar()
    Line()
end

-- Its panel is that wide: the list as wide as it was left (Layout.TalkList, as Layout.Board counts it for the
-- chat beside it), the messages wrapped for the part beside it.
function Conversations.Size(width)
    panelWidth = width
    if not held then Divide(Layout.TalkList(ns.store.talkList, width)) end
    local now = Layout.RowWidth(width - listWidth - 1)
    views:Fit(now)
    if now == rowWidth then return end
    rowWidth = now
    Conversations.Rewrap()
end

-- Shown, the one chosen is read and the list follows the game; hidden, nothing is read, nothing listens.
function Conversations.Show(on)
    shown = on
    Talks.Read(on and open and not open.pinned and open or nil)
    for _, event in ipairs(EVENTS) do
        if on then Core.On(event, Changed) else Core.Off(event, Changed) end
    end
    views:Show(on and open ~= nil and open.view ~= nil)
    if not on then
        if edit:HasFocus() then edit:ClearFocus() end
        return
    end
    Update()
    Fill()
end

-- A chat view made, renamed or removed, or the chat's own window come or gone: the list anew.
function Conversations.Relist()
    if shown then Update() end
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
