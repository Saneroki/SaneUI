local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Social - Channels
--  Where you can write right now: the list behind the input's label.
--  Knows no frames.
--
--  One entry: kind ("SAY", "GUILD", "CHANNEL"), text (the game's own word, or
--  "2. Trade"), and for a channel its number as target.
--  A whisper is not in it: it needs somebody to whisper to (/w name, /r).
--
--  And what the window can show (Showable): every kind of chat and every
--  channel you are in, for the list of what to show; whether a group is shown
--  (Shown). And a chat's name in short (Brief).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Channels = {}
ns.Channels = Channels

-- The game's own word for a kind of chat ("Guild"); ours where it has none. A group with a switch of
-- its own in the settings (ns.SHOWS) goes by that switch's words, so the list and the page agree.
function Channels.Word(kind)
    if ns.SHOWS[kind] then return ns.TEXT.kinds[kind] end
    return _G["CHAT_MSG_" .. kind] or ns.TEXT.kinds[kind] or kind
end

-- A channel's name as the game shows it. A community's channel is called "Community:<club>:<stream>"
-- inside; the game turns that into the community's name (its own chat does the same).
function Channels.Name(name)
    if not name then return nil end
    return ChatFrameUtil and Core.Ask(ChatFrameUtil.ResolveChannelName, name) or name
end

-- A channel's own name: "Trade" of "Trade - City". The part behind it changes with where you are.
function Channels.Base(name)
    return name and (name:match("^(.-)%s+%-%s") or name) or "?"
end

-- A name in short: the first letter of each of its words. "Guild" is G, "Raid Warning" RW.
-- A letter may be more than one byte (other languages). Made once per name: it comes with every message.
local briefs = {} -- [name] = the same in short
function Channels.Brief(name)
    local brief = briefs[name]
    if brief then return brief end
    local letters = {}
    for word in name:gmatch("%S+") do
        local letter = word:match("^[%z\1-\127\194-\244][\128-\191]*")
        if letter and not letter:match("^%p") then letters[#letters + 1] = letter end
    end
    brief = #letters > 0 and table.concat(letters) or name
    briefs[name] = brief
    return brief
end

-- Whether the window shows the messages of a group ("GUILD", "CHANNEL:2"); a tick in the list of what to show.
-- A few groups have a switch of their own in the settings (ns.SHOWS): that says it, for both. Every
-- other group's tick is the setting mute ([group] = true: not shown), kept with the rest.
function Channels.Shown(group)
    local key = ns.SHOWS[group]
    if key then return ns.options[key] and true or false end
    return not ns.options.mute[group]
end

-- The tick of a group flipped (the list of what to show): set as the options page sets it (Core.Set), so the
-- window shows the list anew and an open options page shows the switch as it is now.
function Channels.Flip(group)
    local key = ns.SHOWS[group]
    if key then return Core.Set(ns.name, key, not ns.options[key]) end
    local mute = Core.Copy(ns.options.mute)
    mute[group] = not mute[group] or nil
    Core.Set(ns.name, "mute", mute)
end

local function Add(list, kind)
    list[#list + 1] = { kind = kind, text = Channels.Word(kind) }
end

-- Everything the window can show: every group of the log (Log.GROUPS), and every channel you are in.
-- One entry: group (what a message of it carries, Log.lua) and text.
function Channels.Showable()
    local list = {}
    for index, kinds in ipairs(ns.Log.GROUPS) do list[index] = { group = kinds[1], text = Channels.Word(kinds[1]) } end
    local joined = { GetChannelList() }
    for index = 1, #joined, 3 do
        local id, name = joined[index], joined[index + 1]
        list[#list + 1] = { group = "CHANNEL:" .. id, text = ("%d. %s"):format(id, Channels.Name(name)) }
    end
    return list
end

function Channels.List()
    local list = {}
    Add(list, "SAY")
    Add(list, "YELL")
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then Add(list, "PARTY") end
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then Add(list, "RAID") end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then Add(list, "INSTANCE_CHAT") end
    if IsInGuild() then
        Add(list, "GUILD")
        if not (C_GuildInfo and C_GuildInfo.IsGuildOfficer) or C_GuildInfo.IsGuildOfficer() then Add(list, "OFFICER") end
    end
    -- The channels you joined: number, name, switched off; and so on.
    local joined = { GetChannelList() }
    for index = 1, #joined, 3 do
        local id, name, disabled = joined[index], joined[index + 1], joined[index + 2]
        if not disabled then list[#list + 1] = { kind = "CHANNEL", target = id, text = ("%d. %s"):format(id, Channels.Name(name)) } end
    end
    return list
end
