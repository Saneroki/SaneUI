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

-- Adds and removes members of a list (kinds of chat, channels) until it holds what is wanted.
local function Match(id, want, have, add, remove)
    local wanted, had, changed = Set(want), Set(have), false
    for value in pairs(had) do
        if not wanted[value] then remove(id, value) changed = true end
    end
    for value in pairs(wanted) do
        if not had[value] then add(id, value) changed = true end
    end
    return changed
end

-- Gives one window what was kept; true if anything differed.
local function WriteTab(id, want)
    local have, changed = Tab(id), false
    local function Put(differs, set, ...)
        if differs then set(id, ...) changed = true end
    end
    local tint, now = type(want.tint) == "table" and want.tint or have.tint, have.tint
    Put(type(want.title) == "string" and want.title ~= "" and want.title ~= have.title, SetChatWindowName, want.title)
    Put(type(want.font) == "number" and want.font > 0 and want.font ~= have.font, SetChatWindowSize, want.font)
    Put(Apart(tint[1], now[1]) or Apart(tint[2], now[2]) or Apart(tint[3], now[3]), SetChatWindowColor, tint[1], tint[2], tint[3])
    Put(Apart(tint[4], now[4]), SetChatWindowAlpha, tint[4])
    Put(want.shown ~= have.shown, SetChatWindowShown, want.shown)
    Put(want.locked ~= have.locked, SetChatWindowLocked, want.locked)
    Put(want.through ~= have.through, SetChatWindowUninteractable, want.through)
    Put(want.dock ~= have.dock, SetChatWindowDocked, want.dock or nil)
    if type(want.kinds) == "table" and Match(id, want.kinds, have.kinds, AddChatWindowMessages, RemoveChatWindowMessages) then changed = true end
    if type(want.channels) == "table" and Match(id, want.channels, have.channels, AddChatWindowChannel, RemoveChatWindowChannel) then changed = true end
    local spot, at = want.spot, have.spot
    if id > 1 and type(spot) == "table" and type(spot[1]) == "string" then
        Put(spot[1] ~= at[1] or Apart(spot[2], at[2]) or Apart(spot[3], at[3]), SetChatWindowSavedPosition, spot[1], spot[2], spot[3])
        Put(Apart(spot[4], at[4]) or Apart(spot[5], at[5]), SetChatWindowSavedDimensions, spot[4], spot[5])
    end
    return changed
end

-- The colours of the kinds of chat ("SAY", "CHANNEL1", ...), and whether names in them are in their
-- class colour.
local function Colours()
    local colours = {}
    if type(ChatTypeInfo) ~= "table" then return colours end
    for kind, info in pairs(ChatTypeInfo) do
        if type(kind) == "string" and type(info) == "table" and type(info.r) == "number" then
            colours[kind] = { r = info.r, g = info.g, b = info.b, byClass = info.colorNameByClass and true or false }
        end
    end
    return colours
end

-- True if any differed: the frames take a colour from the game's event, which runs in our call.
local function WriteColours(colours)
    if type(ChatTypeInfo) ~= "table" then return false end
    local changed = false
    for kind, want in pairs(colours) do
        local info = ChatTypeInfo[kind]
        if type(info) == "table" and type(want) == "table" then
            if Apart(want.r, info.r) or Apart(want.g, info.g) or Apart(want.b, info.b) then
                ChangeChatColor(kind, want.r, want.g, want.b)
                changed = true
            end
            if type(want.byClass) == "boolean" and want.byClass ~= (info.colorNameByClass and true or false) then
                SetChatColorNameByClass(kind, want.byClass)
                changed = true
            end
        end
    end
    return changed
end

Sync.Part("chatFrames", "elsewhere", {
    text = "Chat windows",
    tip = "The chat windows and their tabs: names, text size, colour, locked or docked, what each shows, where the free ones stand and how big they are (the first stands where Edit Mode puts it), and the colours of the kinds of chat. In place after a /reload.",
    reload = RELOAD,
    Read = function()
        local tabs = {}
        for id = 1, WINDOWS do tabs[id] = Tab(id) end
        return { tabs = tabs, colours = Colours() }
    end,
    Write = function(data)
        local changed = false
        if type(data.tabs) == "table" then
            for id = 1, WINDOWS do
                local want = data.tabs[id]
                if type(want) == "table" and WriteTab(id, want) then changed = true end
            end
        end
        if type(data.colours) == "table" and WriteColours(data.colours) then changed = true end
        return changed
    end,
})
