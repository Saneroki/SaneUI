local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Talks
--  The conversations: every whisper, and the chat of each group you are in,
--  each in a conversation of its own, apart from the chat's log (Log.lua). One
--  for each player whispered with (a Battle.net friend by their BattleTag),
--  and one for each group you join, as a whisper starts one: the party you
--  join (and the raid it becomes) is one, the next group you join another, an
--  instance group one of its own. A group's conversation is known by the
--  group's own GUID (GROUP_JOINED), its chat (party, raid, raid warning;
--  instance) goes there and nowhere else, and it is named by the others in it.
--  Once you leave (GROUP_LEFT) it ends: it stays in the list to read, as long
--  as the others do, and is written in no more. Knows no frames: the full
--  screen's panel shows them (Conversations.lua).
--
--  A conversation:
--      key       "W:Droopy Fairwind" (a character, by its player key, Core.PlayerKeyOf),
--                "B:Jaina#1234" (a Battle.net friend), "G:<the group's GUID>" (a group)
--      kind      "WHISPER", "BN_WHISPER", or the group's: "PARTY", "RAID", "INSTANCE_CHAT" (a party that
--                becomes a raid is a raid from then on)
--      category  a group's: the game's LE_PARTY_CATEGORY_HOME or _INSTANCE
--      members   a group's: the others who were in it, as the game names them, in the order they came
--      started, ended   a group's: when you joined it and left it (time(); ended: none while you are in it)
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
local Talks = { list = {}, by = {} } -- the conversations, the newest message first; [key] = the conversation
ns.Talks = Talks

-- Talks.added(talk, message, new): set by the panel that shows them, told of every message (new: the
-- conversation began with it). Talks.reading: the conversation read right now (Read).

Talks.MOST = 50   -- conversations kept at most: one more, and the one quiet the longest goes
Talks.SAVED = 1000 -- messages kept over a logout, of all conversations together: the newest conversations' first
Talks.VERSION = 2 -- the shape Save writes; 2: what follows from the rest is not kept (a whisper's colour, a chat's short name)

-- The kinds of group whose chat is a conversation of its own, by the group of their messages (Log.GROUPS),
-- in the order they come when you are in them and nobody spoke yet.
Talks.GROUPS = { PARTY = true, RAID = true, INSTANCE_CHAT = true }
Talks.GROUP_ORDER = { "PARTY", "RAID", "INSTANCE_CHAT" }
local KINDS = { WHISPER = true, BN_WHISPER = true, PARTY = true, RAID = true, INSTANCE_CHAT = true }
local HOME, INSTANCE = LE_PARTY_CATEGORY_HOME or 1, LE_PARTY_CATEGORY_INSTANCE or 2
Talks.NAMES = 3      -- a group's conversation is named by so many of the others in it, then how many more
Talks.MEMBERS = 40   -- the others kept for a group, at most
Talks.current = {}   -- [category] = the key of the conversation of the group you are in

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

local Current -- (below: the conversation of the group you are in)

-- The conversation a message is part of: its key, kind and with; nil for none. A group's chat goes to the group you
-- are in now (none once you left it). A Battle.net friend whose BattleTag the game does not say is kept by the
-- account, for this session only.
local function Whose(entry)
    if Talks.GROUPS[entry.group] then
        local talk = Current(entry.group == "INSTANCE_CHAT" and INSTANCE or HOME)
        if talk then return talk.key, talk.kind end
        return nil
    end
    local with = entry.with
    if type(with) ~= "string" or with == "" then return nil end
    if entry.account then
        local tag = Tag(entry.account)
        return tag and ("B:" .. tag) or ("B#" .. tostring(entry.account)), "BN_WHISPER", tag
    end
    return "W:" .. (Core.PlayerKeyOf(with) or with), "WHISPER", with
end

-- The conversation with a character, by the name the game gives (a whisper's target); nil: none yet.
function Talks.Whisper(name)
    if type(name) ~= "string" or name == "" then return nil end
    return Talks.by["W:" .. (Core.PlayerKeyOf(name) or name)]
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

-- The conversation with the newest message stands first.
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
    local word = ns.Channels.Word(talk.kind)
    local members = talk.category and talk.members
    if type(members) ~= "table" or #members == 0 then return word end
    local shown = {}
    for index = 1, math.min(#members, Talks.NAMES) do
        shown[index] = Core.People and Core.People.Shown(members[index]) or members[index]
    end
    local more = #members > Talks.NAMES and (" +" .. (#members - Talks.NAMES)) or ""
    return word .. ": " .. table.concat(shown, ", ") .. more
end

-- A message of the log (Log.Add) that belongs into a conversation: a copy of it goes there.
function Talks.Add(entry)
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

-------------------------------------------------------------------------------
--  Groups
-------------------------------------------------------------------------------
-- The kind of chat of the group you are in of that category: an instance group's, a raid's, a party's.
local function KindOf(category)
    if category == INSTANCE then return "INSTANCE_CHAT" end
    return IsInRaid(category) and "RAID" or "PARTY"
end

-- The others in the group of that category now, as the game names them: a raid's by its roster, a party's by
-- its units.
local function Others(category)
    local names, me = {}, Short(Core.Ask(UnitName, "player"))
    if IsInRaid(category) then
        for index = 1, (GetNumGroupMembers(category)) or 0 do
            local name = Short(Core.Plain((GetRaidRosterInfo(index))))
            if name and name ~= me then names[#names + 1] = name end
        end
        return names
    end
    local count = rawget(_G, "GetNumSubgroupMembers")
    count = count and count(category) or math.max(((GetNumGroupMembers(category)) or 0) - 1, 0)
    for index = 1, count do
        local name = Short(Core.Plain((UnitName("party" .. index))))
        if name then names[#names + 1] = name end
    end
    return names
end

-- The group's conversation as the group is now: its kind (a party become a raid), the others who came.
local function Roster(talk)
    talk.kind = KindOf(talk.category)
    talk.members = type(talk.members) == "table" and talk.members or {}
    local known = {}
    for _, name in ipairs(talk.members) do known[name] = true end
    for _, name in ipairs(Others(talk.category)) do
        if not known[name] and #talk.members < Talks.MEMBERS then
            known[name] = true
            talk.members[#talk.members + 1] = name
        end
    end
end

-- A group joined (its GUID, or none: you were in it already when it was first asked about): a conversation of
-- its own, last in the list until somebody speaks there.
local function Begin(category, guid)
    guid = Core.Plain(guid)
    local key = "G:" .. (type(guid) == "string" and guid ~= "" and guid or (category .. ":" .. time()))
    local talk = Talks.by[key] or Make(key, KindOf(category), nil, true)
    talk.category, talk.started, talk.ended = category, talk.started or time(), nil
    Talks.current[category] = key
    Roster(talk)
    return talk
end

-- The group of that category left: its conversation ends, to read on.
local function End(category)
    local talk = Talks.by[Talks.current[category] or ""]
    if talk then talk.ended = time() end
    Talks.current[category] = nil
end

-- The conversation of the group of that category you are in; nil: you are in none (then one that was is ended).
Current = function(category)
    local talk = Talks.by[Talks.current[category] or ""]
    if not IsInGroup(category) then
        if Talks.current[category] then End(category) end
        return nil
    end
    return talk or Begin(category, nil)
end

-- The conversations of the groups you are in, to write in though nobody spoke there yet.
function Talks.Groups()
    Current(HOME)
    Current(INSTANCE)
end

-- The game tells of a group joined and left (its category: the home group unless the instance's), and of who is
-- in it: the conversations follow.
local function Of(category) return category == INSTANCE and INSTANCE or HOME end
Core.On("GROUP_JOINED", function(category, guid) ns.Safe("talks", Begin, Of(category), guid) end)
Core.On("GROUP_LEFT", function(category) ns.Safe("talks", End, Of(category)) end)
-- Who is in them is asked anew a frame later, once for a run of the game's word on it (a raid forming tells it many
-- times in a row).
local function Rosters()
    for category in pairs(Talks.current) do
        local talk = Current(category)
        if talk then Roster(talk) end
    end
end
Core.On("GROUP_ROSTER_UPDATE", Core.Later(function() ns.Safe("talks", Rosters) end))

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

-- Whether you can write in a conversation now; false and why not, in the game's words where it has them. A group's:
-- only while you are in that group.
function Talks.Writable(talk)
    local within = IN[talk.kind]
    if within then
        if talk.category then
            if Talks.current[talk.category] == talk.key and IsInGroup(talk.category) then return true end
            return false, talk.ended and ns.TEXT.groupOver or OUT[talk.kind]
        end
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
        send(text, talk.category and KindOf(talk.category) or talk.kind)
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
-- chat's history (Log.Saved). A Battle.net friend's own messages go without the friend's name and link. What follows
-- from the rest is not kept (Taken makes it anew): a whisper's colour (its kind and side), a chat's short name (its name).
local function Kept(message, bnet, whisper)
    local copy = { stamp = message.stamp }
    for _, field in ipairs(ns.Log.KEPT) do copy[field] = message[field] end
    if bnet then copy.name, copy.link = nil, nil end
    if whisper then copy.r, copy.g, copy.b = nil, nil, nil end
    if copy.label then copy.short = nil end
    for _, field in ipairs({ "text", "name", "label", "link" }) do
        if OfSession(copy[field]) then return nil end
    end
    if type(copy.link) == "string" then copy.link = (copy.link:gsub("^(|Hplayer:[^:|]*):%d+", "%1:0")) end
    return copy
end

-- Every conversation with messages, each with its last talkSize, into the character's saved settings: the newest
-- first, Talks.SAVED messages of them all at most (the saved settings are read at every login, of every character).
function Talks.Save(char)
    local saved, most, left = {}, ns.options.talkSize or 100, Talks.SAVED
    for _, talk in ipairs(Talks.list) do
        if left <= 0 then break end
        if not talk.session and #talk.messages > 0 then
            local kept = { key = talk.key, kind = talk.kind, with = talk.with, class = talk.class, last = talk.last,
                           unread = talk.unread, category = talk.category, members = talk.members,
                           started = talk.started, ended = talk.ended, messages = {} }
            local bnet = talk.kind == "BN_WHISPER"
            local whisper = bnet or talk.kind == "WHISPER"
            for index = math.max(#talk.messages - math.min(most, left) + 1, 1), #talk.messages do
                kept.messages[#kept.messages + 1] = Kept(talk.messages[index], bnet, whisper)
            end
            left = left - #kept.messages
            if #kept.messages > 0 then saved[#saved + 1] = kept end
        end
    end
    char.talks = #saved > 0 and saved or nil
    char.talksVersion = char.talks and Talks.VERSION or nil
    char.talkGroups = next(Talks.current) and Core.Copy(Talks.current) or nil -- the groups you are in: the same after a /reload
end

local SIDES = { left = true, right = true, center = true }
local WHISPERED = { WHISPER = true, BN_WHISPER = true }

-- The colour the game gives a whisper of that kind, sent (right) or come: a whisper's messages keep none (Kept).
local function Colour(kind, side)
    local info = WHISPERED[kind] and ChatTypeInfo and ChatTypeInfo[kind .. (side == "right" and "_INFORM" or "")]
    if type(info) == "table" and info.r then return info.r, info.g, info.b end
end

-- One message as it was kept in a conversation of that kind, of the right kinds only (a hand edit may have changed
-- it); nil: none.
local function Taken(kept, last, kind)
    if type(kept) ~= "table" or type(kept.text) ~= "string" or not SIDES[kept.side] then return nil end
    local message = { stamp = tonumber(kept.stamp) or last }
    for _, field in ipairs(ns.Log.KEPT) do
        local value = kept[field]
        if type(value) == "string" or type(value) == "number" then message[field] = value end
    end
    local r, g, b = tonumber(message.r), tonumber(message.g), tonumber(message.b)
    if not (r and g and b) then r, g, b = Colour(kind, message.side) end
    message.r, message.g, message.b = r or 1, g or 1, b or 1
    -- A group's chat in short follows from its name, as the log makes it (Log.Read); a whisper's copies have neither.
    if type(message.label) == "string" and not message.short then message.short = ns.Channels.Brief(message.label) end
    message.time = message.time and tostring(message.time) or ""
    if type(message.class) ~= "string" then message.class = nil end
    if message.tie and not ns.Layout.TIES[message.tie] then message.tie = nil end
    return message
end

-- The conversations saved before, back at the login, the newest message first; current: the groups you were in
-- (a group you are still in goes on in its conversation; one you left meanwhile ends when it is first asked about).
function Talks.Restore(saved, current)
    if type(saved) ~= "table" then return end
    for _, kept in ipairs(saved) do
        local fit = type(kept) == "table" and type(kept.key) == "string" and KINDS[kept.kind] and type(kept.messages) == "table"
            and (Talks.GROUPS[kept.kind] or type(kept.with) == "string") and not Talks.by[kept.key]
        if fit then
            local talk = Make(kept.key, kept.kind, type(kept.with) == "string" and kept.with or nil, true)
            talk.class = type(kept.class) == "string" and kept.class or nil
            talk.last = tonumber(kept.last) or 0
            talk.unread = math.max(math.floor(tonumber(kept.unread) or 0), 0)
            if kept.category == HOME or kept.category == INSTANCE then
                talk.category, talk.started, talk.ended = kept.category, tonumber(kept.started), tonumber(kept.ended)
                talk.members = {}
                for _, name in ipairs(type(kept.members) == "table" and kept.members or {}) do
                    if type(name) == "string" and #talk.members < Talks.MEMBERS then talk.members[#talk.members + 1] = name end
                end
            end
            for _, message in ipairs(kept.messages) do talk.messages[#talk.messages + 1] = Taken(message, talk.last, talk.kind) end
            if #talk.messages == 0 then Drop(talk) end
        end
    end
    table.sort(Talks.list, function(a, b) return a.last > b.last end)
    while #Talks.list > Talks.MOST do Drop(Talks.list[#Talks.list]) end
    for _, category in ipairs({ HOME, INSTANCE }) do
        local key = type(current) == "table" and current[category]
        local talk = type(key) == "string" and Talks.by[key]
        if talk and talk.category == category and not talk.ended then Talks.current[category] = key end
    end
end
