local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Log
--  The messages: what one of the game's chat events says (Read), and the list
--  of the last ones (Add). Knows no frames.
--
--  A message is a plain table:
--      side    "left" (somebody else), "right" (you), "center" (a note: the
--              system, an emote, an achievement; a bubble in the middle, no name above it)
--      text    what was said
--      name    who said it (left only)
--      link    the same as the game's link to them: a click whispers (left only)
--      class   the speaker's class, "MAGE" (left only, if the game knows it)
--      tie     what the speaker is to you: "friend", "guild", "raid", "party" (left only; the first that holds)
--      label   where: "Guild", "Trade", "To Thrall"
--      short   the same in short: "G", "T" (not for "To Thrall")
--      group   what it is shown or hidden with: "GUILD", "CHANNEL:2", "PRINT" (Log.GROUPS)
--      r, g, b the game's colour for that kind of chat
--      time    "21:07"
--      at      when it came, on the game's clock (GetTime): what fading counts from
--      gone    true once the log let it go (Add): the window lets it go too
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Log = { list = {} }
ns.Log = Log

-- Log.added(entry): set by whoever shows the list (Window.lua), told of every new message.

Log.MAX = 200   -- messages kept at most; more if the history saved is longer (Log.Keep)
Log.PRUNE = 25  -- the oldest go so many at a time: the window's list is updated for them once, not for each

local NOTE, MINE = "center", "right"
-- [event] = the side its messages are always on; true: yours on the right, others on the left.
Log.EVENTS = {
    CHAT_MSG_SAY = true, CHAT_MSG_YELL = true,
    CHAT_MSG_WHISPER = true, CHAT_MSG_WHISPER_INFORM = MINE,
    CHAT_MSG_BN_WHISPER = true, CHAT_MSG_BN_WHISPER_INFORM = MINE,
    CHAT_MSG_PARTY = true, CHAT_MSG_PARTY_LEADER = true,
    CHAT_MSG_RAID = true, CHAT_MSG_RAID_LEADER = true, CHAT_MSG_RAID_WARNING = true,
    CHAT_MSG_INSTANCE_CHAT = true, CHAT_MSG_INSTANCE_CHAT_LEADER = true,
    CHAT_MSG_GUILD = true, CHAT_MSG_OFFICER = true,
    CHAT_MSG_CHANNEL = true,
    CHAT_MSG_MONSTER_SAY = true, CHAT_MSG_MONSTER_YELL = true, CHAT_MSG_MONSTER_WHISPER = true,
    CHAT_MSG_EMOTE = NOTE, CHAT_MSG_TEXT_EMOTE = NOTE, CHAT_MSG_MONSTER_EMOTE = NOTE,
    CHAT_MSG_ACHIEVEMENT = NOTE, CHAT_MSG_GUILD_ACHIEVEMENT = NOTE,
}
-- Every other line comes as the game's chat writes it (Log.Line): the system's (many of them have
-- no event: your time played, a slash command's answer), loot, pings, a boss's emote, a channel's
-- notice, a friend coming online, an addon's print. So nothing the game's chat shows is missing.

-- What the window can show or hide, in the order the list of what to show offers it (Channels.lua):
-- each group first, then the kinds of chat that belong to it (a party's leader speaks in the party's
-- chat, a Battle.net whisper is a whisper). Every channel is a group of its own besides these; the
-- notices of all channels (somebody joined or left, "Joined Channel") are one group.
Log.GROUPS = {
    { "SAY" }, { "YELL" }, { "EMOTE", "TEXT_EMOTE" },
    { "WHISPER", "WHISPER_INFORM", "BN_WHISPER", "BN_WHISPER_INFORM", "AFK", "DND", "BN_WHISPER_PLAYER_OFFLINE" },
    { "PARTY", "PARTY_LEADER" }, { "RAID", "RAID_LEADER", "RAID_WARNING" },
    { "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER" }, { "GUILD", "GUILD_ACHIEVEMENT", "GUILD_ITEM_LOOTED", "GUILD_DISCORD" }, { "OFFICER" },
    { "MONSTER", "MONSTER_SAY", "MONSTER_YELL", "MONSTER_WHISPER", "MONSTER_EMOTE", "MONSTER_PARTY",
      "RAID_BOSS_EMOTE", "RAID_BOSS_WHISPER", "QUEST_BOSS_EMOTE", "ENCOUNTER_EVENT" },
    { "PING" },
    { "REWARDS", "LOOT", "MONEY", "CURRENCY", "SKILL", "TRADESKILLS", "OPENING", "PET_INFO", "COLLECTED_APPEARANCE",
      "COMBAT_XP_GAIN", "COMBAT_HONOR_GAIN", "COMBAT_FACTION_CHANGE", "COMBAT_MISC_INFO" },
    { "BATTLEGROUND", "BG_SYSTEM_HORDE", "BG_SYSTEM_ALLIANCE", "BG_SYSTEM_NEUTRAL" },
    { "PET_BATTLE", "PET_BATTLE_INFO", "PET_BATTLE_COMBAT_LOG" },
    { "CHANNEL_NOTICES", "CHANNEL_JOIN", "CHANNEL_LEAVE", "CHANNEL_LIST", "CHANNEL_NOTICE", "CHANNEL_NOTICE_USER" },
    { "SYSTEM", "ACHIEVEMENT", "RESTRICTED", "FILTERED", "IGNORED", "TARGETICONS", "VOICE_TEXT",
      "BN_ALERT", "BN_BROADCAST", "BN_BROADCAST_INFORM",
      "BN_INLINE_TOAST_ALERT", "BN_INLINE_TOAST_BROADCAST", "BN_INLINE_TOAST_BROADCAST_INFORM" },
    { "PRINT" },
}
local GROUP = {} -- [kind of chat] = its group
for _, kinds in ipairs(Log.GROUPS) do
    for _, kind in ipairs(kinds) do GROUP[kind] = kinds[1] end
end
-- These carry only what was done ("waves."), the name comes in front. A monster's emote
-- has a place for the name in its text ("%s goes into a frenzy!"), and so has an achievement
-- ("%s has earned the achievement [Level 10]!"), where the name is the player's link, in brackets, as
-- in the game's chat.
local NAME_FIRST = { CHAT_MSG_EMOTE = true }
local NAME_INSIDE = { CHAT_MSG_MONSTER_EMOTE = true, CHAT_MSG_ACHIEVEMENT = true, CHAT_MSG_GUILD_ACHIEVEMENT = true }
local NAME_LINKED = { CHAT_MSG_ACHIEVEMENT = true, CHAT_MSG_GUILD_ACHIEVEMENT = true }

-- "Thrall-Realm" is "Thrall" on your own realm.
local function Short(name)
    if name == nil or name == "" then return nil end
    return Ambiguate and Ambiguate(name, "none") or name
end

-- The game's colour for a kind of chat; every channel you joined has its own.
local function Color(kind, channel)
    local info = ChatTypeInfo and (channel and ChatTypeInfo[kind .. channel] or ChatTypeInfo[kind])
    if info and info.r then return info.r, info.g, info.b end
    return 1, 1, 1
end

-------------------------------------------------------------------------------
--  Who speaks: asked once per speaker, not for every message
-------------------------------------------------------------------------------
local CAP = 500              -- speakers remembered at most in each; then all of them are asked anew
local classes, ties = {}, {} -- [GUID] = the speaker's class; what the speaker is to you (false: nothing)
local kept = { [classes] = 0, [ties] = 0 } -- answers in each

local function Remember(cache, guid, value)
    if kept[cache] >= CAP then
        wipe(cache)
        kept[cache] = 0
    end
    cache[guid], kept[cache] = value, kept[cache] + 1
end

-- A class never changes. Not every sender is a player: the game knows no class for a creature.
local function Class(guid)
    if not guid then return nil end
    local class = classes[guid]
    if class then return class end
    local _, found = Core.Ask(GetPlayerInfoByGUID, guid)
    if found then Remember(classes, guid, found) end
    return found
end

-- What a speaker is to you. A friend first, then your guild, then your group.
local function Ask(guid)
    if C_FriendList.IsFriend(guid) then return "friend" end
    local account = C_BattleNet.GetAccountInfoByGUID(guid)
    if account and account.isFriend then return "friend" end
    if IsGuildMember(guid) then return "guild" end
    if C_PartyInfo.IsGUIDInGroup(guid) then return IsInRaid() and "raid" or "party" end
    return false
end

local function Tie(guid, kind)
    if kind == "BN_WHISPER" then return "friend" end
    if not guid then return nil end
    local tie = ties[guid]
    if tie == nil then
        -- Not every client has all of these: no answer is no tie.
        local ok, found = pcall(Ask, guid)
        if not ok then return nil end
        tie = found
        Remember(ties, guid, tie)
    end
    return tie or nil
end

-- Your friends, your guild or your group changed: what a speaker is to you is asked anew.
function Log.Forget()
    wipe(ties)
    kept[ties] = 0
end

-------------------------------------------------------------------------------
--  Reading a message
-------------------------------------------------------------------------------
-- A message's raid marks ({skull}, {rt8}) as their icons, as the game's chat shows them; a raid's
-- group expressions only where the game's chat allows them.
local function Icons(text, kind, noIcons)
    local info, util = C_ChatInfo, ChatFrameUtil
    if not (info and info.ReplaceIconAndGroupExpressions and text:find("{", 1, true)) then return text end
    local group = util and Core.Ask(util.GetChatCategory, kind) or kind
    local groups = util and Core.Ask(util.CanChatGroupPerformExpressionExpansion, group)
    local shown = Core.Ask(info.ReplaceIconAndGroupExpressions, text, ns.Plain(noIcons), not groups)
    return type(shown) == "string" and shown or text
end

-- The speaker's name as the game's chat links it: a click whispers to them, a right click is their menu
-- (SetItemRef). A Battle.net friend by their account, everybody else by name and realm.
local function Link(kind, sender, name, lineID, account)
    if kind:sub(1, 3) == "BN_" then
        if not (account and GetBNPlayerLink) then return nil end
        return GetBNPlayerLink(sender, name, account, lineID, kind, sender)
    end
    return GetPlayerLink and GetPlayerLink(sender, name, lineID, kind) or nil
end

-- What a chat event says; nil for one that cannot be shown. The arguments are the game's:
-- text, sender, language, channel ("2. Trade - City"), ..., 8 channel number, 9 channel name, ..., 11 the line's
-- number, 12 sender's GUID, 13 a Battle.net friend's account, 16 the sender hidden in a letterbox (a
-- cinematic's: the game's chat does not show it either), 17 raid marks ({skull}) left as words.
function Log.Read(event, text, sender, _, _, _, _, _, channelIndex, channelName, _, lineID, guid, account, _, _, letterbox, noIcons)
    local side = Log.EVENTS[event]
    -- In a fight the game may hide a message from addons; its own chat still shows it.
    text, sender, guid = ns.Plain(text), ns.Plain(sender), ns.Plain(guid)
    if not side or type(text) ~= "string" or text == "" or ns.Plain(letterbox) then return nil end

    local kind = event:sub(10) -- after "CHAT_MSG_"
    local name = Short(sender)
    local channel = kind == "CHANNEL" and ns.Plain(channelIndex) or nil
    local entry = { text = text, time = date("%H:%M"), at = GetTime() }
    entry.r, entry.g, entry.b = Color(kind, channel)
    -- A channel by its number: that is what the list of what to show has, whatever the game calls it where.
    entry.group = channel and ("CHANNEL:" .. channel) or GROUP[kind] or kind

    if side == NOTE then
        entry.side = NOTE
        if name and NAME_FIRST[event] then
            entry.text = name .. " " .. text
        elseif name and NAME_INSIDE[event] then
            local shown = NAME_LINKED[event] and GetPlayerLink and GetPlayerLink(sender, "[" .. name .. "]") or name
            entry.text = text:gsub("%%s", function() return shown end)
        end
        return entry
    end

    entry.text = Icons(text, kind, noIcons)
    if side == MINE then
        entry.side, entry.label = MINE, name and ns.TEXT.to:format(name) or nil
        return entry
    end

    -- The game's own word for the kind of chat ("Guild"), or the channel's name as the game shows it.
    local channelText = channel and ns.Channels.Name(ns.Plain(channelName))
    entry.label = channelText or ns.Channels.Word(kind)
    entry.short = ns.Channels.Brief(channel and ns.Channels.Base(channelText) or entry.label)
    if guid and guid == Core.charKey then
        entry.side = MINE
    else
        entry.side, entry.name, entry.class, entry.tie = "left", name, Class(guid), Tie(guid, kind)
        entry.link = name and Link(kind, sender, name, ns.Plain(lineID), ns.Plain(account))
    end
    return entry
end

-------------------------------------------------------------------------------
--  A line the game's chat wrote: what no event of ours told
-------------------------------------------------------------------------------
-- The game's chat writes a line with the number of its kind of chat (ChatTypeInfo[kind].id), and one
-- of a speaker also with its event; an addon's print has neither. Not every client does: some write
-- their loot or skill lines with neither. So the event is also taken from the game's own chat filters
-- (Log.Before), which the game's chat asks right before it writes the line of a chat event.
local kinds, read -- [number] = its kind of chat; [number] = true: a kind read from its events (Log.Read)
local learned = {} -- [number] = true: not known even after learning anew
local beforeWindow, beforeEvent -- the chat window handling a chat event right now, and that event

local function Learn()
    kinds, read = {}, {}
    for kind, info in pairs(ChatTypeInfo or {}) do
        local id = type(info) == "table" and info.id
        if id then
            kinds[id] = kind
            read[id] = Log.EVENTS["CHAT_MSG_" .. kind] and true or nil
        end
    end
end

-- What a line of that kind and event is shown or hidden with. Its event says it best (CHAT_MSG_LOOT:
-- loot). A line of a channel's own kind (CHANNEL2) is a message in that channel when it comes with
-- its event (one we do not read: a community's channel); without one, or with one of a channel's
-- notices (CHAT_MSG_CHANNEL_JOIN, ..._NOTICE), it is a notice. Neither kind nor event: a print, but
-- for one with a channel's link (a join or leave the client told nothing of).
local function Group(kind, event, text)
    local from = event and event:match("^CHAT_MSG_(.+)$")
    local channel = kind and kind:match("^CHANNEL(%d+)$")
    if from and from:find("^CHANNEL_") then return "CHANNEL_NOTICES" end
    if channel then return from and ("CHANNEL:" .. channel) or "CHANNEL_NOTICES" end
    kind = from or kind
    if not kind then return text and text:find("|Hchannel:", 1, true) and "CHANNEL_NOTICES" or "PRINT" end
    return GROUP[kind] or kind
end

-- The game's chat filters (ChatFrame_AddMessageEventFilter) are asked with the window and the event
-- right before it writes that event's line; After: the window is done with it.
function Log.Before(window, event)
    beforeWindow, beforeEvent = window, event
end

function Log.After()
    beforeWindow, beforeEvent = nil, nil
end

-- The chat events whose lines the game's chat writes and we do not read: every one of its kinds of
-- chat and their groups (ChatTypeInfo, ChatTypeGroup). [event] = true.
function Log.Unread()
    local events = {}
    local function Take(event)
        if type(event) == "string" and event:find("^CHAT_MSG_") and not Log.EVENTS[event] then events[event] = true end
    end
    for kind in pairs(ChatTypeInfo or {}) do Take("CHAT_MSG_" .. tostring(kind)) end
    for _, group in pairs(rawget(_G, "ChatTypeGroup") or {}) do
        if type(group) == "table" then
            for _, event in pairs(group) do Take(event) end
        end
    end
    return events
end

-- One event the game's chat shows in two of its windows is written into each, in the same frame:
-- a window that writes a text more often in this frame than any other did so far has a new line.
local stamp, taken, given = nil, {}, {} -- the frame's time; [text] = lines taken; [window] = { [text] = lines written }

local function Fresh(window, text)
    local now = GetTime()
    if now ~= stamp then
        stamp = now
        wipe(taken)
        wipe(given)
    end
    local written = given[window]
    if not written then
        written = {}
        given[window] = written
    end
    local count = (written[text] or 0) + 1
    written[text] = count
    if count <= (taken[text] or 0) then return false end
    taken[text] = count
    return true
end

-- The game puts its time in front of some lines, if you have its chat show times; ours has its own.
-- (No closure for every line: most players show no times.)
local function Stamp()
    local Format = ChatFrameUtil and ChatFrameUtil.GetTimestampFormat or rawget(_G, "GetChatTimestampFormat")
    local format = Format and Format()
    if not format then return nil end
    local Write = rawget(_G, "TimeUtil") and TimeUtil.BetterDate or rawget(_G, "BetterDate")
    return Write and Write(format, time())
end

local function Untimed(text)
    local ok, shown = pcall(Stamp)
    if ok and type(shown) == "string" and shown ~= "" and text:sub(1, #shown) == shown then return text:sub(#shown + 1) end
    return text
end

-- A line one of the game's chat windows got (its AddMessage): a note in the colour it came with,
-- unless it is a message we read from its event.
local motd, motdAt -- the guild's message of the day as last told (Log.Motd), and when

function Log.Line(window, text, r, g, b, id, event)
    if not event and window == beforeWindow then event = beforeEvent end
    if event and Log.EVENTS[event] then return end
    text = ns.Plain(text)
    if type(text) ~= "string" or text == "" then return end
    if text == motd and motdAt == GetTime() then return end -- told by its own event (Log.Motd)
    -- The numbers of the kinds may come later than the first line: learned anew for one not known.
    if not kinds or (id and not kinds[id] and not learned[id]) then
        Learn()
        if id and not kinds[id] then learned[id] = true end
    end
    if id and read[id] then return end
    if not Fresh(window, text) then return end
    local kind = id and kinds[id]
    Log.Add({ side = NOTE, group = Group(kind, event, text), text = Untimed(text), time = date("%H:%M"), at = GetTime(),
              r = ns.Plain(r) or 1, g = ns.Plain(g) or 1, b = ns.Plain(b) or 1 })
end

-- The guild's message of the day, as the game's chat says it.
function Log.Motd(text)
    text = ns.Plain(text)
    if type(text) ~= "string" or text == "" then return end
    local r, g, b = Color("GUILD")
    text = GUILD_MOTD_TEMPLATE and GUILD_MOTD_TEMPLATE:format(text) or text
    -- The game's chat may have written it already, a moment ago in this same frame: that line is the guild's.
    local now, last = GetTime(), Log.list[#Log.list]
    motd, motdAt = text, now
    if last and last.text == text and last.at == now then
        last.group = "GUILD"
        return
    end
    Log.Add({ side = NOTE, group = "GUILD", text = text, time = date("%H:%M"), at = now, r = r, g = g, b = b })
end

-------------------------------------------------------------------------------
--  The history: the last messages, kept over a logout or /reload
-------------------------------------------------------------------------------
-- What of a message is kept; the rest is the window's (measures, fading) or of this session (at).
local KEPT = { "side", "text", "name", "link", "class", "tie", "label", "short", "group", "r", "g", "b", "time" }

-- So many messages are kept at least, for a history that long.
function Log.Keep(count)
    Log.MAX = math.max(200, count or 0)
end

-- A Battle.net friend's name (|K...|k, and its link) stands for that friend in this session only:
-- after a restart it may be another's. Such a message is not kept.
local function OfSession(entry)
    for _, key in ipairs({ "text", "name", "label", "link" }) do
        local value = entry[key]
        if type(value) == "string" and (value:find("|K", 1, true) or value:find("|HBNplayer", 1, true)) then return true end
    end
    return false
end

-- The last count messages, as plain tables to save; nil for none. A player's link keeps no line
-- number: it is this session's (a report from its menu would find another line).
function Log.Saved(count)
    local list = Log.list
    if not count or count < 1 or #list == 0 then return nil end
    local saved = {}
    for index = math.max(#list - count + 1, 1), #list do
        local entry = list[index]
        if not OfSession(entry) then
            local copy = {}
            for _, key in ipairs(KEPT) do copy[key] = entry[key] end
            if type(copy.link) == "string" then copy.link = (copy.link:gsub("^(|Hplayer:[^:|]*):%d+", "%1:0")) end
            saved[#saved + 1] = copy
        end
    end
    return saved
end

-- What the history is: 2 since lines without a chat type number go by their event (Log.Before).
-- One saved before that has such lines among the prints.
Log.HISTORY = 2

local function Near(a, b) return math.abs(a - b) < 0.01 end

-- An old history's print that was none: a line with a channel's link is a channel's notice; else the
-- group of the kinds of chat with its very colour, if they are all of one (the system's first).
local function Guess(entry)
    if entry.text:find("|Hchannel:", 1, true) then return "CHANNEL_NOTICES" end
    if Near(entry.r, 1) and Near(entry.g, 1) and Near(entry.b, 1) then return "PRINT" end -- white: a print's own
    local found
    for kind, info in pairs(ChatTypeInfo or {}) do
        if type(info) == "table" and info.r and Near(info.r, entry.r) and Near(info.g, entry.g) and Near(info.b, entry.b)
            and not tostring(kind):find("^CHANNEL") then
            local group = GROUP[kind] or kind
            if group == "SYSTEM" or found == "SYSTEM" then
                found = "SYSTEM"
            elseif found and found ~= group then
                return "PRINT"
            else
                found = group
            end
        end
    end
    return found or "PRINT"
end

-- Messages saved before go in front of the log, as long gone by: faded out at once, there when you
-- scroll back. Only what a message is made of is taken, of the right kind. version: Log.HISTORY when
-- it was saved; an older one's prints are sorted anew (Guess), and a line it has twice at once, once as
-- a print and once in a group (the guild's message of the day), is there once.
function Log.Restore(saved, version)
    if type(saved) ~= "table" then return end
    local old, past, legacy, twice = {}, GetTime() - 86400, version ~= Log.HISTORY, {}
    for _, kept in ipairs(saved) do
        if type(kept) == "table" and type(kept.text) == "string" and type(kept.side) == "string" then
            local entry = { at = past }
            for _, key in ipairs(KEPT) do
                local value = kept[key]
                if type(value) == "string" or type(value) == "number" then entry[key] = value end
            end
            entry.r, entry.g, entry.b = entry.r or 1, entry.g or 1, entry.b or 1
            -- What a bubble needs to be drawn (a hand edit may have taken it out, or made it a number)
            entry.time = entry.time and tostring(entry.time) or ""
            if type(entry.class) ~= "string" then entry.class = nil end
            if entry.tie and not ns.Layout.TIES[entry.tie] then entry.tie = nil end
            local key, was = entry.time .. entry.text, entry.group
            if legacy and was == "PRINT" then entry.group = Guess(entry) end
            if not (legacy and twice[key] and twice[key] ~= was) then old[#old + 1] = entry end
            twice[key] = twice[key] or was
        end
    end
    -- In front of what is there, oldest first. Each insert moves only the live messages up (none at
    -- the login), not what was put in before it.
    local list = Log.list
    for index, entry in ipairs(old) do table.insert(list, index, entry) end
    while #list > Log.MAX do table.remove(list, 1) end
end

-- Takes the first count off a list, all in one go: the rest moves up once, not once for each.
function Log.Shift(list, count)
    for index = 1, #list do list[index] = list[index + count] end
end

function Log.Add(entry)
    local list = Log.list
    list[#list + 1] = entry
    if #list > Log.MAX then
        for index = 1, Log.PRUNE do list[index].gone = true end
        Log.Shift(list, Log.PRUNE)
    end
    if Log.added then Log.added(entry) end
end
