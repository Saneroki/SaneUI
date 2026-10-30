-------------------------------------------------------------------------------
--  Sane UI - Core - Sync - Chat: the chat channels of your own, and the chat
--  windows (their tabs, what each shows, where they stand) with the colours of
--  the kinds of chat. The game's own channels, joined or left, are the Social
--  module's.
--  All through the game's stored chat settings (SetChatWindow*,
--  *ChatWindowMessages, *ChatWindowChannel, ChangeChatColor), never its chat
--  frames: they read those settings when the interface loads, hence a /reload;
--  a colour they take at once from the game's own event, which runs in our call.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sync = Core.Sync -- Sync.lua
local Plain = Core.Plain

local WINDOWS = Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or 10
local CLOSE = 1 / 256 -- two colour or place values nearer than this are the same: the game keeps floats
local RELOAD = "the chat windows"

local function Apart(a, b)
    return math.abs((tonumber(a) or 0) - (tonumber(b) or 0)) > CLOSE
end

-------------------------------------------------------------------------------
--  Channels of your own
-------------------------------------------------------------------------------
-- The kind of channel the game keeps for a player's own (Enum.PermanentChatChannelType: the game's
-- own are Zone, a community's Communities).
local OWN = Enum and Enum.PermanentChatChannelType and Enum.PermanentChatChannelType.Custom or 3

-- The game's own channels on offer ([lower-case name] = true); nil on a client that cannot say.
local function Offered()
    local enumerate = rawget(_G, "EnumerateServerChannels")
    if type(enumerate) ~= "function" then return nil end
    local offered = {}
    for _, name in ipairs({ enumerate() }) do
        if type(name) == "string" then offered[name:lower()] = true end
    end
    return offered
end

-- Whether a channel is the player's own: by the kind the game's channel info gives; without it, by
-- not being one of the game's. nil when neither can tell.
local function Own(name, offered)
    local chat = rawget(_G, "C_ChatInfo")
    local info = Core.Ask(chat and chat.GetChannelInfoFromIdentifier, name)
    local kind = type(info) == "table" and Plain(info.channelType) or nil
    if kind ~= nil then return kind == OWN end
    if offered then return not offered[name:lower()] end
    return nil
end

-- Read first in the list of parts (Sync.Part order): a channel joined goes into the first chat window,
-- which the windows' part then puts right.
Sync.Part("ownChannels", "elsewhere", {
    text = "Your own chat channels",
    tip = "The chat channels you made or joined yourself, not the game's nor a community's: joined on every character when it logs in. One with a password cannot be joined this way.",
    -- The names of those this character is in. When the game cannot tell its own from the player's,
    -- what was kept stays (else the game's would be joined everywhere).
    Read = function()
        local offered, names = Offered(), {}
        local list = { GetChannelList() } -- number, name, disabled; and so on
        for index = 1, #list, 3 do
            local name = Plain(list[index + 1])
            local community = Plain(select(4, GetChannelName(list[index])))
            if type(name) == "string" and not community then
                local own = Own(name, offered)
                if own == nil then return Sync.Taken("ownChannels") end
                if own then names[#names + 1] = name end
            end
        end
        return names
    end,
    -- Joins those it is not in, as the game's /join does: into the first chat window.
    Write = function(names)
        for _, name in ipairs(names) do
            if type(name) == "string" and Plain(GetChannelName(name)) == 0 then JoinPermanentChannel(name, nil, 1, 1) end
        end
    end,
})

-------------------------------------------------------------------------------
--  Chat windows
-------------------------------------------------------------------------------
-- The arguments as a list, every second one from the first (name and number pairs).
local function Odd(...)
    local list = {}
    for index = 1, select("#", ...), 2 do list[#list + 1] = select(index, ...) end
    return list
end

local function Set(list)
    local set = {}
    for _, value in ipairs(list) do set[value] = true end
    return set
end

-- One window as the game keeps it. dock: its place in the dock, false when it stands free. spot: where
-- it stands and its size; not for the first, which Edit Mode places.
local function Tab(id)
    local title, font, r, g, b, alpha, shown, locked, dock, through = GetChatWindowInfo(id)
    local tab = { title = title, font = font, tint = { r, g, b, alpha }, shown = shown and true or false,
        locked = locked and true or false, dock = type(dock) == "number" and dock or false, through = through and true or false,
        kinds = { GetChatWindowMessages(id) }, channels = Odd(GetChatWindowChannels(id)) }
    if id > 1 then
        local point, x, y = GetChatWindowSavedPosition(id)
        local width, height = GetChatWindowSavedDimensions(id)
        tab.spot = { point, x, y, width, height }
    end
    return tab
end

-- Whether a kept value is a table of so many numbers (a colour, a place): one of an older shape is not.
local function Numbers(list, first, last)
    if type(list) ~= "table" then return false end
    for index = first, last do
        if type(list[index]) ~= "number" then return false end
    end
    return true
end

-- Adds and removes members of a list (kinds of chat, channels) until it holds what is wanted; a member
-- that is no text is not one this version kept.
local function Match(id, want, have, add, remove)
    local names = {}
    for _, value in ipairs(want) do
        if type(value) == "string" then names[#names + 1] = value end
    end
    local wanted, had, changed = Set(names), Set(have), false
    for value in pairs(had) do
        if not wanted[value] then remove(id, value) changed = true end
    end
    for value in pairs(wanted) do
        if not had[value] then add(id, value) changed = true end
    end
    return changed
end

-- Those of a list that are in a set of lower-case names.
local function Among(list, arranged)
    local names = {}
    for _, name in ipairs(list) do
        if type(name) == "string" and arranged[name:lower()] then names[#names + 1] = name end
    end
    return names
end

-- Gives one window what was kept; true if anything differed. Each value is checked for its kind first: one
-- of an older shape, or missing, leaves that setting as the game has it.
local function WriteTab(id, want, arranged)
    local have, changed = Tab(id), false
    local function Put(differs, set, ...)
        if differs then set(id, ...) changed = true end
    end
    local function Switch(key, set)
        Put(type(want[key]) == "boolean" and want[key] ~= have[key], set, want[key])
    end
    local tint, now = want.tint, have.tint
    Put(type(want.title) == "string" and want.title ~= "" and want.title ~= have.title, SetChatWindowName, want.title)
    Put(type(want.font) == "number" and want.font > 0 and want.font ~= have.font, SetChatWindowSize, want.font)
    if Numbers(tint, 1, 3) then
        Put(Apart(tint[1], now[1]) or Apart(tint[2], now[2]) or Apart(tint[3], now[3]), SetChatWindowColor, tint[1], tint[2], tint[3])
    end
    if Numbers(tint, 4, 4) then Put(Apart(tint[4], now[4]), SetChatWindowAlpha, tint[4]) end
    Switch("shown", SetChatWindowShown)
    Switch("locked", SetChatWindowLocked)
    Switch("through", SetChatWindowUninteractable)
    local dock = want.dock
    Put((dock == false or type(dock) == "number") and dock ~= have.dock, SetChatWindowDocked, dock or nil)
    if type(want.kinds) == "table" and Match(id, want.kinds, have.kinds, AddChatWindowMessages, RemoveChatWindowMessages) then changed = true end
    if type(want.channels) == "table" and Match(id, Among(want.channels, arranged), Among(have.channels, arranged), AddChatWindowChannel, RemoveChatWindowChannel) then changed = true end
    local spot, at = want.spot, have.spot
    if id > 1 and type(spot) == "table" and type(spot[1]) == "string" and Numbers(spot, 2, 5) then
        Put(spot[1] ~= at[1] or Apart(spot[2], at[2]) or Apart(spot[3], at[3]), SetChatWindowSavedPosition, spot[1], spot[2], spot[3])
        Put(Apart(spot[4], at[4]) or Apart(spot[5], at[5]), SetChatWindowSavedDimensions, spot[4], spot[5])
    end
    return changed
end

-- The channels this character is in: their names by their numbers here, and their numbers by their names
-- in lower case.
local function Joined()
    local names, numbers = {}, {}
    local get = rawget(_G, "GetChannelList")
    local list = get and { get() } or {} -- number, name, disabled; and so on
    for index = 1, #list, 3 do
        local number, name = Plain(list[index]), Plain(list[index + 1])
        if type(number) == "number" and type(name) == "string" then names[number], numbers[name:lower()] = name, number end
    end
    return names, numbers
end

-- The channels the windows' lists are matched for ([lower-case name] = true): those the kept windows name and this
-- character is in, or joins in this writing (its own). A kept one it is not in stays out: what a character left is not
-- for a window's list to bring back. One no kept window names stays as the game has it: a new character's General,
-- which Social leaves a moment later, is no change to offer a /reload for.
local function Arranged(tabs)
    local _, here = Joined()
    local own = Sync.Taken("ownChannels")
    for _, name in ipairs(type(own) == "table" and own or {}) do
        if type(name) == "string" then here[name:lower()] = true end
    end
    local arranged = {}
    for id = 1, WINDOWS do
        local tab = tabs[id]
        for _, name in ipairs(type(tab) == "table" and type(tab.channels) == "table" and tab.channels or {}) do
            if type(name) == "string" and here[name:lower()] then arranged[name:lower()] = true end
        end
    end
    return arranged
end

-- The number of a channel's kind of chat ("CHANNEL5"); nil for any other kind.
local function Channel(kind)
    return tonumber(kind:match("^CHANNEL(%d+)$"))
end

-- A kind of chat's colour as it is kept, and whether names in it are in their class colour; name: a channel's.
local function Entry(info, name)
    return { name = name, r = info.r, g = info.g, b = info.b, byClass = info.colorNameByClass and true or false }
end

-- Gives one kind of chat its kept colour; true if it differed: the frames take it from the game's event,
-- which runs in our call.
local function WriteColour(kind, want)
    local info = ChatTypeInfo[kind]
    if type(info) ~= "table" or type(want) ~= "table" then return false end
    local changed = false
    local colour = type(want.r) == "number" and type(want.g) == "number" and type(want.b) == "number"
    if colour and (Apart(want.r, info.r) or Apart(want.g, info.g) or Apart(want.b, info.b)) then
        ChangeChatColor(kind, want.r, want.g, want.b)
        changed = true
    end
    if type(want.byClass) == "boolean" and want.byClass ~= (info.colorNameByClass and true or false) then
        SetChatColorNameByClass(kind, want.byClass)
        changed = true
    end
    return changed
end

-- The colours of the kinds of chat ("SAY", "YELL", ...), the channels' apart (below).
local function Colours()
    local colours = {}
    if type(ChatTypeInfo) ~= "table" then return colours end
    for kind, info in pairs(ChatTypeInfo) do
        if type(kind) == "string" and not Channel(kind) and type(info) == "table" and type(info.r) == "number" then
            colours[kind] = Entry(info)
        end
    end
    return colours
end

-- True if any differed. A channel's kept by its number (an older shape) is not written: that number may be
-- another channel here.
local function WriteColours(colours)
    if type(ChatTypeInfo) ~= "table" then return false end
    local changed = false
    for kind, want in pairs(colours) do
        if type(kind) == "string" and not Channel(kind) and WriteColour(kind, want) then changed = true end
    end
    return changed
end

-------------------------------------------------------------------------------
--  The channels' colours
-------------------------------------------------------------------------------
-- The game keeps a channel's colour by the channel's number here ("CHANNEL5"), which another character may
-- give another channel: they are kept by the channel's name (in lower case) instead, and each is given to
-- this character's channel of that name. One this character is not in waits for it: Sync's own channels are
-- joined in the same writing, and the server answers a join later. Until it is given, and for a channel this
-- character is not in at all, what was kept stays kept.
local waiting = {} -- [lower-case name] = its kept colour, for a channel not joined here yet

local function Channels()
    local channels = {}
    if type(ChatTypeInfo) ~= "table" then return channels end
    for number, name in pairs(Joined()) do
        local info, key = ChatTypeInfo["CHANNEL" .. number], name:lower()
        if not waiting[key] and type(info) == "table" and type(info.r) == "number" then channels[key] = Entry(info, name) end
    end
    local taken = Sync.Taken("chatFrames")
    for key, want in pairs(type(taken) == "table" and type(taken.channels) == "table" and taken.channels or {}) do
        if type(key) == "string" and type(want) == "table" and channels[key:lower()] == nil then channels[key:lower()] = want end
    end
    return channels
end

-- Each kept colour at this character's number for its channel; one not joined here waits. True if any differed.
local function WriteChannels(channels)
    if type(ChatTypeInfo) ~= "table" then return false end
    local _, numbers = Joined()
    local changed = false
    for key, want in pairs(channels) do
        if type(key) == "string" and type(want) == "table" then
            local number = numbers[key:lower()]
            if not number then
                waiting[key:lower()] = want
            elseif WriteColour("CHANNEL" .. number, want) then
                changed = true
            end
        end
    end
    return changed
end

-- The game's list of channels changed (a join answered): a channel joined since takes the colour that waited
-- for it, once; not in a fight, and only while Sync keeps the chat windows.
local function Answered()
    if not (Core.Profiles.On() and Sync.PartKept("chatFrames")) or type(ChatTypeInfo) ~= "table" then
        wipe(waiting)
        return
    end
    local _, numbers = Joined()
    local changed = false
    for key, want in pairs(waiting) do
        local number = numbers[key]
        if number then
            waiting[key] = nil
            if WriteColour("CHANNEL" .. number, want) then changed = true end
        end
    end
    if changed then Sync.OfferReload({ RELOAD }) end
end
local AnsweredSoon = Core.Later(function() Core.AfterCombat("Sync: channel colours", Answered) end)
Core.On("CHANNEL_UI_UPDATE", function()
    if next(waiting) then AnsweredSoon() end
end)

Sync.Part("chatFrames", "elsewhere", {
    text = "Chat windows",
    tip = "The chat windows and their tabs: names, text size, colour, locked or docked, what each shows, where the free ones stand and how big they are (the first stands where Edit Mode puts it), and the colours of the kinds of chat. In place after a /reload.",
    reload = RELOAD,
    Read = function()
        local tabs = {}
        for id = 1, WINDOWS do tabs[id] = Tab(id) end
        return { tabs = tabs, colours = Colours(), channels = Channels() }
    end,
    Write = function(data)
        local changed = false
        wipe(waiting) -- from now on only these settings' channels wait, not those given before
        if type(data.tabs) == "table" then
            local arranged = Arranged(data.tabs)
            for id = 1, WINDOWS do
                local want = data.tabs[id]
                if type(want) == "table" and WriteTab(id, want, arranged) then changed = true end
            end
        end
        if type(data.colours) == "table" and WriteColours(data.colours) then changed = true end
        if type(data.channels) == "table" and WriteChannels(data.channels) then changed = true end
        return changed
    end,
})
