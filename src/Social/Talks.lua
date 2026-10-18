local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Talks
--  The conversations: every whisper, and the chat of your party, your raid and
--  your instance group, each in a conversation of its own, apart from the
--  chat's log (Log.lua). One for each player whispered with (a Battle.net
--  friend by their BattleTag), one for each kind of group. Knows no frames:
--  the full screen's panel shows them (Conversations.lua).
--
--  A conversation:
--      key       "W:Droopy Fairwind" (a character, by its player key, Core.PlayerKeyOf),
--                "B:Jaina#1234" (a Battle.net friend), "PARTY", "RAID", "INSTANCE_CHAT"
--      kind      "WHISPER", "BN_WHISPER", or the group's: "PARTY", "RAID", "INSTANCE_CHAT"
--      with      whom: the character's name as the game gives it, or the BattleTag (whispers only)
--      name      a Battle.net friend's name in this session (|K...|k, the game shows the name)
--      account   a Battle.net friend's account in this session (its number changes between sessions)
--      class     the character's class, once they wrote
--      last      when its last message came: time(), the computer's clock
--      unread    messages of others that came while it was not read
--      messages  its messages, oldest first: the log's fields (Log.KEPT), and stamp (time())
--
--  Its messages are copies of the log's: they are kept longer (the setting
--  talkSize, for each conversation) and measured for the panel's width
--  (Bubble.Measure keeps one width on a message). A whisper's copy has no
--  chat's name above its bubble: the conversation says whose it is.
--
--  The one read now (Talks.reading: the panel on show, it chosen) gets its
--  messages read, and keeps all of them until it is left: nothing moves away
--  under the eyes. The others keep their last talkSize.
--
--  Kept per character over a logout or /reload (Save, Restore), as the chat's
--  history. A Battle.net friend's name (|K...|k) and link stand for that friend
--  in this session only: a Battle.net conversation is kept by the BattleTag, its
--  messages without the friend's name, found anew in the next session.
--  Personal data (Doc/guides/data.md): never shared.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talks = { list = {}, by = {} } -- the conversations, the last spoken in first; [key] = the conversation
ns.Talks = Talks

-- Talks.added(talk, message, new): set by the panel that shows them, told of every message (new: the
-- conversation began with it). Talks.reading: the conversation read right now (Read).

Talks.MOST = 50   -- conversations kept at most: one more, and the one quiet the longest goes
Talks.VERSION = 1 -- the shape Save writes

-- The kinds of group whose chat is a conversation of its own, by the group of their messages (Log.GROUPS),
-- in the order they come when you are in them and nobody spoke yet.
Talks.GROUPS = { PARTY = true, RAID = true, INSTANCE_CHAT = true }
Talks.GROUP_ORDER = { "PARTY", "RAID", "INSTANCE_CHAT" }
local KINDS = { WHISPER = true, BN_WHISPER = true, PARTY = true, RAID = true, INSTANCE_CHAT = true }

-- Whether you are in a group of that kind now, and the game's words when you are not.
local IN = {
    PARTY = function() return IsInGroup(LE_PARTY_CATEGORY_HOME) end,
    RAID = function() return IsInRaid(LE_PARTY_CATEGORY_HOME) end,
    INSTANCE_CHAT = function() return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) end,
}
local OUT = {
    PARTY = Core.Word("ERR_NOT_IN_GROUP", "You aren't in a party."),
    RAID = Core.Word("ERR_NOT_IN_RAID", "You are not in a raid group"),
    INSTANCE_CHAT = Core.Word("ERR_NOT_IN_INSTANCE_GROUP", "You aren't in an instance group."),
}

-- "Thrall-Realm" is "Thrall" on your own realm.
local function Short(name)
    if type(name) ~= "string" then return nil end
    return Core.Ask(rawget(_G, "Ambiguate"), name, "none") or name
end

-- A Battle.net friend's BattleTag, by their account in this session; nil: the game does not say.
local function Tag(account)
    local info = C_BattleNet and Core.Ask(C_BattleNet.GetAccountInfoByID, account)
    local tag = type(info) == "table" and Core.Plain(info.battleTag)
    return type(tag) == "string" and tag ~= "" and tag or nil
end

-- The conversation a message is part of: its key, kind and with; nil for none. A Battle.net friend whose
-- BattleTag the game does not say is kept by the account, for this session only.
local function Whose(entry)
    if Talks.GROUPS[entry.group] then return entry.group, entry.group end
    local with = entry.with
    if type(with) ~= "string" or with == "" then return nil end
    if entry.account then
        local tag = Tag(entry.account)
        return tag and ("B:" .. tag) or ("B#" .. tostring(entry.account)), "BN_WHISPER", tag
    end
    return "W:" .. (Core.PlayerKeyOf(with) or with), "WHISPER", with
end

local function Make(key, kind, with, last)
    local talk = { key = key, kind = kind, with = with, messages = {}, unread = 0, last = 0 }
    Talks.by[key] = talk
    if last then
        Talks.list[#Talks.list + 1] = talk
    else
        table.insert(Talks.list, 1, talk)
    end
    return talk
end

-- The conversation spoken in last stands first.
local function Front(talk)
    local list = Talks.list
    if list[1] == talk then return end
    for index, other in ipairs(list) do
        if other == talk then
            table.remove(list, index)
            break
        end
    end
    table.insert(list, 1, talk)
end

local function Drop(talk)
    Talks.by[talk.key] = nil
    for index, other in ipairs(Talks.list) do
        if other == talk then return table.remove(Talks.list, index) end
    end
end

-- The last talkSize messages of a conversation that is not read now; how many went.
local function Trim(talk)
    local over = #talk.messages - (ns.options.talkSize or 100)
    if over <= 0 or talk == Talks.reading then return 0 end
    ns.Log.Shift(talk.messages, over)
    return over
end

-- No more than MOST conversations: those quiet the longest go, never the one read now.
local function Crowd()
    local list = Talks.list
    local index = #list
    while #list > Talks.MOST and index > 0 do
        if list[index] ~= Talks.reading then Drop(list[index]) end
        index = index - 1
    end
end

-- Who a conversation is with, as shown: the alias the player gave a character (Core.People), else its name
-- without the realm; a Battle.net friend by name (their BattleTag without its number while the game does not
-- know them); a group by the game's word for its chat.
function Talks.Name(talk)
    if talk.kind == "WHISPER" then
        return Core.People and Core.People.Shown(talk.with) or Short(talk.with) or "?"
    end
    if talk.kind == "BN_WHISPER" then
        if not talk.name then Talks.Account(talk) end
        return talk.name or (talk.with or "?"):match("^[^#]+")
    end
    return ns.Channels.Word(talk.kind)
end

-- A message of the log (Log.Add) that belongs into a conversation: a copy of it goes there.
function Talks.Add(entry)
    if not ns.options.boardTalks then return end
    local key, kind, with = Whose(entry)
    if not key then return end
    local talk = Talks.by[key]
    local new = talk == nil
    if new then
        talk = Make(key, kind, with)
        talk.session = kind == "BN_WHISPER" and not with or nil
    end
    local message = { stamp = time() }
    for _, field in ipairs(ns.Log.KEPT) do message[field] = entry[field] end
    if kind == "WHISPER" or kind == "BN_WHISPER" then message.label, message.short = nil, nil end
    local messages = talk.messages
    messages[#messages + 1] = message
    talk.last = message.stamp
    if kind == "BN_WHISPER" then talk.name, talk.account = entry.with, entry.account end
    if entry.side == "left" then
        talk.class = entry.class or talk.class
        if talk ~= Talks.reading then talk.unread = talk.unread + 1 end
    end
    Front(talk)
    Trim(talk)
    Crowd()
    if Talks.added then Talks.added(talk, message, new) end
end

-- A group's conversation, to write in though nobody spoke there yet (you are in that group); last in the list.
function Talks.Group(kind)
    if not Talks.GROUPS[kind] then return nil end
    return Talks.by[kind] or Make(kind, kind, nil, true)
end

-- The panel reads that conversation now (nil: none, the panel is hidden): its messages are read, and the one
-- left keeps its last talkSize again.
function Talks.Read(talk)
    local before = Talks.reading
    Talks.reading = talk
    if before and before ~= talk then Trim(before) end
    if talk then talk.unread = 0 end
end

-- How many messages wait to be read, in all conversations.
function Talks.Unread()
    local count = 0
    for _, talk in ipairs(Talks.list) do count = count + talk.unread end
    return count
end

-- A conversation gone, with its messages.
function Talks.Remove(talk)
    if not talk or Talks.by[talk.key] ~= talk then return end
    Drop(talk)
    if Talks.reading == talk then Talks.reading = nil end
end

-- The setting talkSize changed: every conversation keeps its last messages as it says.
function Talks.Trim()
    for _, talk in ipairs(Talks.list) do Trim(talk) end
end

-- A Battle.net friend's account in this session: the one their last message came with, else found by their
-- BattleTag among your Battle.net friends (and their name with it); nil: not among them.
function Talks.Account(talk)
    if talk.account then return talk.account end
    if talk.kind ~= "BN_WHISPER" or not talk.with or not BNGetNumFriends then return nil end
    for index = 1, (BNGetNumFriends()) or 0 do
        local info = C_BattleNet.GetFriendAccountInfo(index)
        if info and info.battleTag == talk.with then
            talk.account = info.bnetAccountID
            if type(info.accountName) == "string" and info.accountName ~= "" then talk.name = info.accountName end
            return talk.account
        end
    end
    return nil
end

-- Whether you can write in a conversation now; false and why not, in the game's words where it has them.
function Talks.Writable(talk)
    local within = IN[talk.kind]
    if within then
        if within() then return true end
        return false, OUT[talk.kind]
    end
    if talk.kind == "BN_WHISPER" and not Talks.Account(talk) then return false, ns.TEXT.talkGone end
    return true
end

-- A message sent into a conversation, as the game's own line sends it (its SendText): its words put in as the
-- game puts them in (%t, the target's name), and kept as the one told last, so the game's /r and its reply
-- keys know it. True once sent; false and why not. The message comes back from the game (a whisper's
-- _INFORM event, or the group's chat) and joins the conversation from there.
function Talks.Send(talk, text)
    local ok, why = Talks.Writable(talk)
    if not ok then return false, why end
    local util = ChatFrameUtil
    if util and util.SubstituteChatMessageBeforeSend then text = util.SubstituteChatMessageBeforeSend(text) end
    local told = util and util.SetLastToldTarget
    if talk.kind == "BN_WHISPER" then
        C_BattleNet.SendWhisper(Talks.Account(talk), text)
        if told and talk.name then told(talk.name, "BN_WHISPER") end
        return true
    end
    local send = C_ChatInfo and C_ChatInfo.SendChatMessage or rawget(_G, "SendChatMessage")
    if talk.kind == "WHISPER" then
        if told then told(talk.with, "WHISPER") end
        send(text, "WHISPER", nil, talk.with)
    else
        send(text, talk.kind)
    end
    return true
end

-------------------------------------------------------------------------------
--  Kept over a logout or /reload
-------------------------------------------------------------------------------
-- A text of this session only: a Battle.net friend's name or link (Log.lua says why).
local function OfSession(value)
    return type(value) == "string" and (value:find("|K", 1, true) or value:find("|HBNplayer", 1, true)) and true or false
end

-- What of a message is kept; nil for one of this session only. A player's link keeps no line number, as the
-- chat's history (Log.Saved). A Battle.net friend's own messages go without the friend's name and link.
local function Kept(message, bnet)
    local copy = { stamp = message.stamp }
    for _, field in ipairs(ns.Log.KEPT) do copy[field] = message[field] end
    if bnet then copy.name, copy.link = nil, nil end
    for _, field in ipairs({ "text", "name", "label", "link" }) do
        if OfSession(copy[field]) then return nil end
    end
    if type(copy.link) == "string" then copy.link = (copy.link:gsub("^(|Hplayer:[^:|]*):%d+", "%1:0")) end
    return copy
end

-- Every conversation with messages, each with its last talkSize, into the character's saved settings.
function Talks.Save(char)
    local saved, most = {}, ns.options.talkSize or 100
    for _, talk in ipairs(Talks.list) do
        if not talk.session and #talk.messages > 0 then
            local kept = { key = talk.key, kind = talk.kind, with = talk.with, class = talk.class, last = talk.last,
                           unread = talk.unread, messages = {} }
            local bnet = talk.kind == "BN_WHISPER"
            for index = math.max(#talk.messages - most + 1, 1), #talk.messages do
                kept.messages[#kept.messages + 1] = Kept(talk.messages[index], bnet)
            end
            if #kept.messages > 0 then saved[#saved + 1] = kept end
        end
    end
    char.talks = #saved > 0 and saved or nil
    char.talksVersion = char.talks and Talks.VERSION or nil
end

local SIDES = { left = true, right = true, center = true }

-- One message as it was kept, of the right kinds only (a hand edit may have changed it); nil: none.
local function Taken(kept, last)
    if type(kept) ~= "table" or type(kept.text) ~= "string" or not SIDES[kept.side] then return nil end
    local message = { stamp = tonumber(kept.stamp) or last }
    for _, field in ipairs(ns.Log.KEPT) do
        local value = kept[field]
        if type(value) == "string" or type(value) == "number" then message[field] = value end
    end
    message.r, message.g, message.b = tonumber(message.r) or 1, tonumber(message.g) or 1, tonumber(message.b) or 1
    message.time = message.time and tostring(message.time) or ""
    if type(message.class) ~= "string" then message.class = nil end
    if message.tie and not ns.Layout.TIES[message.tie] then message.tie = nil end
    return message
end

-- The conversations saved before, back at the login, the last spoken in first.
function Talks.Restore(saved)
    if type(saved) ~= "table" then return end
    for _, kept in ipairs(saved) do
        local fit = type(kept) == "table" and type(kept.key) == "string" and KINDS[kept.kind] and type(kept.messages) == "table"
            and (Talks.GROUPS[kept.kind] or type(kept.with) == "string") and not Talks.by[kept.key]
        if fit then
            local talk = Make(kept.key, kept.kind, type(kept.with) == "string" and kept.with or nil, true)
            talk.class = type(kept.class) == "string" and kept.class or nil
            talk.last = tonumber(kept.last) or 0
            talk.unread = math.max(math.floor(tonumber(kept.unread) or 0), 0)
            for _, message in ipairs(kept.messages) do talk.messages[#talk.messages + 1] = Taken(message, talk.last) end
            if #talk.messages == 0 then Drop(talk) end
        end
    end
    table.sort(Talks.list, function(a, b) return a.last > b.last end)
    while #Talks.list > Talks.MOST do Drop(Talks.list[#Talks.list]) end
end
