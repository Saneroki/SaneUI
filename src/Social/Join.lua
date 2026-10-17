local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Join: the game's own chat channels, the same on every
--  character. A channel of the game (General, Trade, ..., as the game names it,
--  in its language) may carry a wish, kept in the setting presence:
--      none    the game decides, as it always does
--      true    always in it: joined wherever the game offers it
--      false   never in it: left whenever the game put the character in it
--  The game says which of its channels are on offer where the character is
--  (EnumerateServerChannels): a city's channels only in a city. A join is asked
--  for once per zone, so one the game refuses is not asked for again and again.
--  Looked at a while after the character entered the world (the game joins its
--  channels first, so their numbers stay the game's), when the game tells of a
--  channel it joined, changed or left for the character, after a loading
--  screen, and at once when a wish changes. Never while chat is locked down:
--  what is owed then follows when that is over.
--  Only through the game's own /join and /leave (JoinPermanentChannel,
--  LeaveChannelByName). Knows no frames: it works whether the window is open
--  or not. The list on the chat's name shows the wishes (Menu.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain

local Join = {}
ns.Join = Join

local FIRST = 8 -- seconds after entering the world before a look: the game joins its own channels first
local QUIET = 2 -- seconds after the game's word on its channels

-- The kind of channel that is the game's own (Enum.PermanentChatChannelType).
local GAME = Enum and Enum.PermanentChatChannelType and Enum.PermanentChatChannelType.Zone or 1

local asked = {} -- [channel] = the zone a join was asked for in
local owed       -- chat was locked down at the last look

-- The wishes of the settings in use.
local function Wishes()
    return ns.options.presence
end

-- The game's channels on offer where the character is, in the game's order and as a set (lower
-- case). nil on a client that cannot say: then every wish counts as on offer, and the once-per-zone
-- rule keeps a refused join from being asked for again.
local function Offered()
    local enumerate = rawget(_G, "EnumerateServerChannels")
    if type(enumerate) ~= "function" then return nil end
    local list, set = {}, {}
    for _, name in ipairs({ enumerate() }) do
        name = Plain(name)
        if type(name) == "string" and not set[name:lower()] then
            list[#list + 1], set[name:lower()] = name, true
        end
    end
    return list, set
end

local function Zone()
    return Core.Ask(rawget(_G, "GetRealZoneText")) or "?"
end

-- Brings the channels in line with the wishes.
function Join.Settle()
    local chat = rawget(_G, "C_ChatInfo")
    if chat and Core.Ask(chat.InChatMessagingLockdown) then
        owed = true
        return
    end
    owed = false
    local _, offered = Offered()
    local zone = Zone()
    for name, wish in pairs(Wishes()) do
        local number = type(name) == "string" and Plain(GetChannelName(name))
        if wish == false and number and number ~= 0 then
            LeaveChannelByName(name)
        elseif wish == true and number == 0 and asked[name] ~= zone and (not offered or offered[name:lower()]) then
            asked[name] = zone
            JoinPermanentChannel(name, nil, 1, 1) -- into the first chat window, as /join does
        end
    end
end

-- A wish set from the list on the chat's name (nil: the game decides), followed at once.
function Join.Wish(name, wish)
    Wishes()[name] = wish
    asked[name] = nil
    ns.Safe("channels", Join.Settle)
end

function Join.Wished(name)
    return Wishes()[name]
end

-- Whether a channel the character is in is one of the game's: by the kind the game gives it; without
-- that, by being on offer.
local function Games(name, offered)
    local chat = rawget(_G, "C_ChatInfo")
    local info = Core.Ask(chat and chat.GetChannelInfoFromIdentifier, name)
    local kind = type(info) == "table" and Plain(info.channelType) or nil
    if kind ~= nil then return kind == GAME end
    return offered ~= nil and offered[name:lower()] == true
end

-- The game's channels for the list on the chat's name: those the character is in, by their number;
-- then those on offer here; then any other with a wish, by name. Each: { name, wish }.
function Join.List()
    local list, listed = {}, {}
    local function Add(name)
        local key = name:lower()
        if listed[key] then return end
        listed[key] = true
        list[#list + 1] = { name = name, wish = Wishes()[name] }
    end
    local offeredList, offered = Offered()
    local joined = { GetChannelList() } -- number, name, disabled; and so on
    for index = 1, #joined, 3 do
        local name = Plain(joined[index + 1])
        if type(name) == "string" and Games(name, offered) then Add(ns.Channels.Base(name)) end
    end
    for _, name in ipairs(offeredList or {}) do Add(name) end
    local rest = {}
    for name in pairs(Wishes()) do
        if type(name) == "string" and not listed[name:lower()] then rest[#rest + 1] = name end
    end
    table.sort(rest)
    for _, name in ipairs(rest) do Add(name) end
    return list
end

-- From the login on. The game's word on its channels counts only after the first look: until then
-- the game is still joining its own.
function Join.Watch()
    local ready
    local function Look()
        ready = true
        ns.Safe("channels", Join.Settle)
    end
    local first, soon = Core.Later(Look, FIRST), Core.Later(Look, QUIET)
    ns.On("PLAYER_ENTERING_WORLD", first)
    ns.On("CHAT_MSG_CHANNEL_NOTICE", function() -- the game joined, changed or left a channel for the character
        if ready then soon() end
    end)
    ns.On("ADDON_RESTRICTION_STATE_CHANGED", function() -- chat's lockdown may be over
        if owed then soon() end
    end)
end
