local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Join: the game's own chat channels, the same on every
--  character. A channel of the game (General, Trade, ..., as the game names it,
--  in its language) may carry a wish, kept in the setting presence and set by
--  its tick in the list on the chat's name (Flip, In):
--      none    never ticked: the game decides, as it always does
--      true    ticked, always in it: joined wherever the game offers it
--      false   unticked, never in it: left whenever the game put the character in it
--  The game may refuse a leave (Retail's Newcomer Chat, for one) and writes a
--  line of its own each time, so a channel it refused is not asked again until
--  the next login or a click on its tick (kept); its tick shows the character
--  is still in it, and the wish stays.
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
--
--  A character starts in none of the game's public channels (Saneroki,
--  2026-10-30): they are for the player to join when needed. So each one, by
--  the kind the game gives it, is left the first time the character is seen
--  active in it, once per channel and character, also what the game joins late
--  or only in a place (a city's Trade, a newcomer's chat). The game remembers
--  for each character what it left. A channel so noted is never left again, nor
--  is one the player joined: asked for by a person, a join comes through the
--  game's own functions, which are watched; the game's own joins do not. A wish
--  goes first. The notes are the character's own (char.public), whichever
--  profile it uses, and are made only at its first load, with nothing saved for
--  it yet: a character saved before stays in what it is in. Retail's Newcomer
--  Chat, which the game joins by itself, carries the wish never in it in both
--  standard profiles (Core's Presets.lua), so it is left on every character the
--  game lets go, and again each time the game puts one back in it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain

local Join = {}
ns.Join = Join

local FIRST = 8 -- seconds after entering the world before a look: the game joins its own channels first
local QUIET = 2 -- seconds after the game's word on its channels

-- The kind of channel that is the game's own (Enum.PermanentChatChannelType).
local GAME = Enum and Enum.PermanentChatChannelType and Enum.PermanentChatChannelType.Zone or 1

-- The game's ways to join a channel when somebody asks; what it joins by itself comes from the server, past these.
local JOINS = { "JoinPermanentChannel", "JoinTemporaryChannel", "JoinChannelByName" }

local asked = {} -- [channel] = the zone a join was asked for in
local kept = {}  -- [a channel's name, lower case] = true: the game refused to let the character leave it
local owed       -- chat was locked down at the last look
local ready      -- the first look came: from then on the game is done joining its own
local public     -- this character's notes: [a channel's word, lower case] = true, left once or joined by the player; nil: leaves none

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

-- Whether a channel the character is in is one of the game's: by the kind the game gives it; without
-- that, by being on offer.
local function Games(name, offered)
    local chat = rawget(_G, "C_ChatInfo")
    local info = Core.Ask(chat and chat.GetChannelInfoFromIdentifier, name)
    local kind = type(info) == "table" and Plain(info.channelType) or nil
    if kind ~= nil then return kind == GAME end
    return offered ~= nil and offered[name:lower()] == true
end

-- Whether a channel is noted, by any word it goes by: a join may name it by its shortcut or by what the game shows
-- ("Services", "Trade (Services)").
local function Noted(number, name)
    local Base = ns.Channels.Base
    local _, full = Core.Ask(GetChannelName, number)
    return public[ns.Channels.Own(number, name):lower()] or public[Base(name):lower()] or public[Base(full):lower()]
end

-- Each public channel the character is in and not noted yet: left, unless a wish speaks for it (never in it is Settle's
-- own). One switched off here waits: the game has it on its list outside a city, and a leave then may not hold.
local function LeaveOnce(offered)
    local joined = { GetChannelList() } -- number, name, disabled; and so on
    for index = 1, #joined, 3 do
        local number, name = Plain(joined[index]), Plain(joined[index + 1])
        if type(number) == "number" and type(name) == "string" and not Plain(joined[index + 2])
            and not Noted(number, name) and Games(name, offered) then
            local own = ns.Channels.Own(number, name)
            public[own:lower()] = true
            if Wishes()[own] == nil and Wishes()[ns.Channels.Base(name)] == nil then LeaveChannelByName(name) end
        end
    end
end

-- Brings the channels in line with the wishes.
function Join.Settle()
    if ns.ChatLocked() then
        owed = true
        return
    end
    owed = false
    local _, offered = Offered()
    if ready and public then LeaveOnce(offered) end
    local zone = Zone()
    for name, wish in pairs(Wishes()) do
        local number = type(name) == "string" and Plain(GetChannelName(name))
        if wish == false and number and number ~= 0 then
            if not kept[name:lower()] then LeaveChannelByName(name) end
        elseif wish == true and number == 0 and asked[name] ~= zone and (not offered or offered[name:lower()]) then
            asked[name] = zone
            JoinPermanentChannel(name, nil, 1, 1) -- into the first chat window, as /join does
        end
    end
end

-- A wish set (nil: the game decides), followed at once.
function Join.Wish(name, wish)
    Wishes()[name] = wish
    asked[name] = nil
    ns.Safe("channels", Join.Settle)
end

-- Whether a channel's tick is on. The wish counts at once, as the game answers a moment later; one the game
-- refused to let go is still joined, whatever is wished; never ticked, it is what the game says.
function Join.In(name)
    if kept[name:lower()] then return true end
    local wish = Wishes()[name]
    if wish ~= nil then return wish end
    return (Plain(GetChannelName(name)) or 0) ~= 0
end

-- A click on a channel's tick: joined or left from now on, on every character. A channel the game refused is asked
-- for again: you asked.
function Join.Flip(name)
    local wish = not Join.In(name)
    kept[name:lower()] = nil
    Join.Wish(name, wish)
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

-- This character's notes: made if nothing is saved for it yet (Core.Character makes its row, so asked first).
function Join.Notes()
    local chars = Core.Store(ns.name).chars
    local first = type(chars) ~= "table" or chars[Core.charKey] == nil
    local char = Core.Character(ns.name)
    if first then char.public = {} end
    public = type(char.public) == "table" and char.public or nil
end

-- A join somebody asked for: that channel is the player's from now on, whether the game takes it or not (asked for
-- in the wrong place, it counts for when the character gets there). Core's guard, not the module's: the channels go on
-- when the window has stood down, and a join missed then would be left at the next load.
local Asked = Core.Guard("Social: channels", function(name)
    name = Plain(name)
    if public and type(name) == "string" then public[ns.Channels.Base(name):lower()] = true end
end)

-- From the login on. The game's word on its channels counts only after the first look: until then
-- the game is still joining its own.
function Join.Watch()
    Join.Notes()
    for _, join in ipairs(JOINS) do
        if rawget(_G, join) then hooksecurefunc(join, Asked) end
    end
    local function Look()
        ready = true
        ns.Safe("channels", Join.Settle)
    end
    local first, soon = Core.Later(Look, FIRST), Core.Later(Look, QUIET)
    ns.On("PLAYER_ENTERING_WORLD", first)
    ns.On("CHAT_MSG_CHANNEL_NOTICE", function() -- the game joined, changed or left a channel for the character
        if ready then soon() end
        ns.Menu.Refresh()
    end)
    ns.On("CHAT_MSG_CHANNEL_LEAVE_PREVENTED", function(name)
        name = Plain(name)
        if type(name) == "string" then kept[ns.Channels.Base(name):lower()] = true end
        ns.Menu.Refresh()
    end)
    ns.On("ADDON_RESTRICTION_STATE_CHANGED", function() -- chat's lockdown may be over
        if owed then soon() end
    end)
end
