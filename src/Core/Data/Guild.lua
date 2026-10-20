local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Guild
--  The guild's records (CLAUDE.md, *Game facts, not people*: people information, built locally for each user,
--  never shipped; Doc/ideas/Guild.md, *The data*): the game's roster as it is now, its history (who joined,
--  left, went up or down a rank, reached a level) and every member's records, each of a kind (card: who the
--  character is and what it wears; more kinds as the views come), shared with the guild by the wire
--  (Wire.lua). Kept per guild, realm and name, in the saved variable of the pack Guild (SaneUIData_Guild),
--  which ships nothing. Quiet until a module starts it (Guild.Start): without the module Guild nothing is
--  asked of the game, sent or kept.
--
--      local Guild = SaneUI.Core.Data.Guild
--      Guild.Start()                 the module wants it: the pack loaded, the roster read, the wire listened to
--      Guild.Key()                   this character's guild ("Name-Realm"), nil outside one
--      Guild.Info()                  { name, realm, rank, rankIndex, total, online, motd, text } of the guild now
--      Guild.Roster()                the members now: { key, name, rank, rankIndex, level, class, className, zone,
--                                    note, officerNote, online, status, mobile, away (days, offline), joined (day),
--                                    guid, index (in the game's roster, for its own calls) }
--      Guild.Member(key)             one of them
--      Guild.History(key, most)      the roster's history, newest first (of one member, or all):
--                                    { day, what = "join" | "leave" | "up" | "down" | "level", key, from, to }
--      Guild.Record(key, kind)       a member's record of that kind: its text and stamp, or nil
--      Guild.Records(kind)           [key] = { text, stamp } of every member that has one
--      Guild.Kind(kind, most)        a kind of record the guild keeps (a module's): its largest text in bytes
--      Guild.Publish(kind, text)     this character's record of that kind changed: kept, and sent while allowed
--      Guild.Allow(kind, on)         whether this character sends its records of that kind (the module's switch)
--      Guild.Card()                  this character's card, read from the game now
--      Guild.Peers()                 [key] = { seen, version }: who in the guild runs Sane UI, as heard
--      Guild.Rights()                what the player may do in the guild: invite, remove, promote, demote, notes,
--                                    officerNotes, viewOfficerNotes, motd, info, officer
--      Guild.Sync()                  ask the guild for what is newer now, and the roster
--      Guild.Stamp(), Guild.OnChange(fn)   moves (fn(what) is called) when any of it changes:
--                                    "roster", "history", "records", "peers"
--
--  The wire's kind G. A member says now and then which records it has (a hello: kind and stamp of each); a
--  record changes: its owner sends it to the guild as a block. Who has an older one, or none, asks the owner
--  by a whisper, two at a time, the same record of the same member at most once a minute; the owner answers
--  with the block by a whisper. A record is taken only from its owner (the server names the sender: a
--  member publishes only its own), only from a member of this guild, only a kind the guild keeps, only
--  newer than the one kept, never from more than a day ahead.
--
--      SaneUIData_Guild["forever"] = { format = 1, guilds = { ["Name-Realm"] = {
--          seen = 20744,                                      the server's day it was last read
--          members = { ["Droopy Fairwind"] = "rank\031level\031joined" },   what the history compares with
--          history = "day\031what\031key\031from\031to\030...",  oldest first, the last 500
--          records = { ["Droopy Fairwind"] = { card = "stamp\031text" } },
--      } } }
-------------------------------------------------------------------------------
local Data, Wire = Core.Data, Core.Wire
local Plain, Ask = Core.Plain, Core.Ask

local Guild = {}
Data.Guild = Guild

local PACK, KIND = "Guild", "G"
local LIST, PART = "\030", "\031"
Guild.FORMAT = 1
Guild.HISTORY = 500      -- events kept per guild
Guild.HELLO = 900        -- seconds between hellos
Guild.ANSWER = 6         -- seconds at most a member waits before it answers a newcomer's hello
Guild.ASK_GAP = 60       -- seconds before the same record of the same member is asked again
Guild.ASKING = 2         -- asks waiting for an answer at once
Guild.AHEAD = 86400      -- seconds a record's stamp may be ahead of this client's clock
Guild.SHRINK = 0.1       -- a roster that shrinks by more than this share at once is not believed

local kinds = { card = 4096 } -- [kind] = its largest text: the kinds the guild keeps
local started = false
local part, here, key      -- SaneUIData_Guild[game]; this guild's entry; its key
local roster, byKey = {}, {} -- the members as the game said last
local info = {}
local allowed, own = {}, {} -- [kind] = true: sent; [kind] = { text, stamp }: this character's records
local peers = {}
local asking, asked, pending = 0, {}, {} -- asks in flight; [member \t kind] = when; the asks waiting
local listeners, stamp = {}, 0
local helloAt = 0

local function Now() return Ask(rawget(_G, "GetServerTime")) or 0 end

-- All of a game function's answers, each nil when hidden; nothing when it is missing or failed. For the
-- functions that answer more than Core.Ask's three.
local function Answers(fn, ...)
    if type(fn) ~= "function" then return {} end
    local results = { pcall(fn, ...) }
    if not results[1] then return {} end
    local list = {}
    for index = 2, #results do list[index - 1] = Plain(results[index]) end
    return list
end
local function Day() return math.floor(Now() / 86400) end
local function Clock() return Ask(GetTime) or 0 end

local function Changed(what)
    stamp = stamp + 1
    for _, fn in ipairs(listeners) do Core.Safe("data: guild", fn, what) end
end

local function Split(text, by)
    local parts = {}
    if type(text) ~= "string" or text == "" then return parts end
    local at = 1
    while true do
        local cut = text:find(by, at, true)
        if not cut then
            parts[#parts + 1] = text:sub(at)
            return parts
        end
        parts[#parts + 1] = text:sub(at, cut - 1)
        at = cut + 1
    end
end
Guild.Split = Split

-------------------------------------------------------------------------------
--  The saved part
-------------------------------------------------------------------------------
-- This character's guild's key: its name and realm, or nil outside a guild.
local function GuildKey()
    local answers = Answers(rawget(_G, "GetGuildInfo"), "player")
    local name, realm = answers[1], answers[4]
    if type(name) ~= "string" or name == "" then return nil end
    realm = type(realm) == "string" and realm ~= "" and realm or Ask(rawget(_G, "GetNormalizedRealmName")) or "?"
    return name .. "-" .. realm, name, realm
end

local function Entry()
    if not part then return nil end
    local name = GuildKey()
    if not name then return nil end
    local entry = part.guilds[name]
    if type(entry) ~= "table" then
        entry = {}
        part.guilds[name] = entry
    end
    if type(entry.members) ~= "table" then entry.members = {} end
    if type(entry.records) ~= "table" then entry.records = {} end
    if type(entry.history) ~= "string" then entry.history = "" end
    return entry, name
end

local function Opened(saved)
    part = saved
    if part.format ~= Guild.FORMAT or type(part.guilds) ~= "table" then
        part.format, part.guilds = Guild.FORMAT, type(part.guilds) == "table" and part.guilds or {}
    end
    here, key = Entry()
    Changed("records")
    Guild.Read()
end

-------------------------------------------------------------------------------
--  The roster
-------------------------------------------------------------------------------
local function Event(day, what, member, from, to)
    if not here then return end
    local line = table.concat({ day, what, member, from or "", to or "" }, PART)
    local text = here.history == "" and line or here.history .. LIST .. line
    local events = Split(text, LIST)
    if #events > Guild.HISTORY then
        text = table.concat(events, LIST, #events - Guild.HISTORY + 1)
    end
    here.history = text
end

-- Days since a member was online, as the game tells it; nil while online or not told.
local function Away(index)
    local answers = Answers(rawget(_G, "GetGuildRosterLastOnline"), index)
    local years, months, days = tonumber(answers[1]), tonumber(answers[2]), tonumber(answers[3])
    if not (years or months or days or answers[4]) then return nil end
    return (years or 0) * 365 + (months or 0) * 30 + (days or 0)
end

-- The roster read from the game; its history noted against what was read before.
function Guild.Read()
    local total, online = Ask(rawget(_G, "GetNumGuildMembers"))
    total = tonumber(total) or 0
    local list, map = {}, {}
    for index = 1, total do
        -- name, rank, rank index, level, class name, zone, note, officer note, online, status, class, ..., mobile (14)
        local a = Answers(rawget(_G, "GetGuildRosterInfo"), index)
        local member = Core.PlayerKeyOf(a[1])
        if member and not map[member] then
            local entry = { key = member, name = member, rank = a[2], rankIndex = tonumber(a[3]) or 0,
                level = tonumber(a[4]) or 0, className = a[5], class = a[11], zone = a[6], note = a[7],
                officerNote = a[8], online = a[9] and true or false, status = a[10], mobile = a[14] and true or false,
                guid = a[17], index = index }
            if not entry.online then entry.away = Away(index) end
            list[#list + 1] = entry
            map[member] = entry
        end
    end
    if total > 0 and #list == 0 then return end -- the game has not got the roster yet
    roster, byKey = list, map
    info.total, info.online = total, tonumber(online) or 0
    local guildKey, name, realm = GuildKey()
    info.name, info.realm = name, realm
    local mine = Answers(rawget(_G, "GetGuildInfo"), "player")
    info.rank, info.rankIndex = mine[2], tonumber(mine[3])
    local util = rawget(_G, "C_GuildInfo")
    info.motd = util and Ask(util.GetMOTD) or Ask(rawget(_G, "GetGuildRosterMOTD"))
    info.text = util and Ask(util.GetInfoText) or Ask(rawget(_G, "GetGuildInfoText"))
    if guildKey ~= key then here, key = Entry() end
    if here then
        local day, before, noted = Day(), here.members, false
        local first = next(before) == nil
        local kept = 0
        for _ in pairs(before) do kept = kept + 1 end
        -- A roster that shrinks a lot at once is the game's partial answer, not members leaving.
        local whole = #list >= total and (kept == 0 or #list >= kept * (1 - Guild.SHRINK))
        for member, entry in pairs(map) do
            local old = before[member]
            if not old then
                before[member] = entry.rankIndex .. PART .. entry.level .. PART .. day
                if not first then Event(day, "join", member) noted = true end
            else
                local fields = Split(old, PART)
                local rankBefore, levelBefore = tonumber(fields[1]), tonumber(fields[2])
                if rankBefore and rankBefore ~= entry.rankIndex then
                    Event(day, entry.rankIndex < rankBefore and "up" or "down", member, rankBefore, entry.rankIndex)
                    noted = true
                end
                if levelBefore and entry.level > levelBefore then
                    Event(day, "level", member, levelBefore, entry.level)
                    noted = true
                end
                before[member] = entry.rankIndex .. PART .. entry.level .. PART .. (fields[3] or "")
            end
            entry.joined = tonumber(Split(before[member], PART)[3])
        end
        if whole then
            for member in pairs(before) do
                if not map[member] then
                    before[member] = nil
                    Event(day, "leave", member)
                    noted = true
                end
            end
        end
        here.seen = day
        if noted then Changed("history") end
    end
    Changed("roster")
end

-------------------------------------------------------------------------------
--  Records
-------------------------------------------------------------------------------
local function Kept(member, kind)
    local records = here and here.records[member]
    local value = records and records[kind]
    if type(value) ~= "string" then return nil end
    local at = value:find(PART, 1, true)
    if not at then return nil end
    return value:sub(at + 1), tonumber(value:sub(1, at - 1))
end

-- A record taken into what is kept, if it is newer.
local function Keep(member, kind, text, when)
    if not here or not kinds[kind] or type(text) ~= "string" or #text > kinds[kind] then return false end
    when = tonumber(when)
    if not when or when > Now() + Guild.AHEAD then return false end
    local _, before = Kept(member, kind)
    if before and before >= when then return false end
    here.records[member] = here.records[member] or {}
    here.records[member][kind] = when .. PART .. text
    return true
end

local function Hello(fresh)
    if not key then return end
    local fields = { "h", fresh and "1" or "0", Guild.Version() }
    for kind, mine in pairs(own) do
        if allowed[kind] then fields[#fields + 1] = kind .. "=" .. mine.stamp end
    end
    fields.n = #fields
    Wire.Send(KIND, fields, "GUILD")
    helloAt = Clock()
end

local function AskNext()
    while asking < Guild.ASKING and pending[1] do
        local job = table.remove(pending, 1)
        local member = byKey[job.member]
        if member and member.online then
            asking = asking + 1
            asked[job.member .. "\t" .. job.kind] = Clock()
            Wire.Send(KIND, { "a", job.kind, n = 2 }, "WHISPER", job.name)
            Core.Later(function()
                asking = math.max(0, asking - 1)
                AskNext()
            end, 15)()
        end
    end
end

-- A member has a record we lack or have older: asked for, in turn.
local function Want(member, kind, when, name)
    local _, have = Kept(member, kind)
    if have and have >= when then return end
    local last = asked[member .. "\t" .. kind]
    if last and Clock() - last < Guild.ASK_GAP then return end
    for _, job in ipairs(pending) do
        if job.member == member and job.kind == kind then return end
    end
    pending[#pending + 1] = { member = member, kind = kind, name = name }
    AskNext()
end

local function Heard(sender, fields, channel, name)
    if not here or (channel ~= "GUILD" and not byKey[sender]) then return end
    local what = fields[1]
    if what == "h" then
        peers[sender] = { seen = Now(), version = fields[3] }
        for index = 4, #fields do
            local kind, when = (fields[index] or ""):match("^(%a+)=(%d+)$")
            if kind and kinds[kind] then Want(sender, kind, tonumber(when), name) end
        end
        -- A newcomer: answered with our own hello, a moment later, unless one went out lately.
        if fields[2] == "1" and Clock() - helloAt > 30 then
            Core.Later(function() if Clock() - helloAt > 30 then Hello(false) end end, math.random() * Guild.ANSWER)()
        end
        Changed("peers")
    elseif what == "a" then
        local kind = fields[2]
        local mine = kind and own[kind]
        if mine and allowed[kind] and byKey[sender] then
            Wire.SendBlock(KIND, kind .. PART .. mine.stamp .. PART .. mine.text, "WHISPER", name)
        end
    end
end

local function HeardBlock(sender, text, channel)
    if not here or (channel ~= "GUILD" and not byKey[sender]) then return end
    local kind, when, body = text:match("^(%a+)\031(%d+)\031(.*)$")
    if not kind then return end
    asked[sender .. "\t" .. kind] = nil
    if Keep(sender, kind, body, when) then Changed("records") end
end

-------------------------------------------------------------------------------
--  This character's card
-------------------------------------------------------------------------------
-- The slots of a card: the gear (1 to 19 but the shirt and tabard count too), in the game's slot IDs.
Guild.SLOTS = { 1, 2, 3, 15, 5, 4, 19, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }

local function ItemLevel(link)
    if type(link) ~= "string" then return nil end
    local items = rawget(_G, "C_Item")
    local level = items and items.GetDetailedItemLevelInfo and Ask(items.GetDetailedItemLevelInfo, link)
    if not level then level = Answers(rawget(_G, "GetItemInfo"), link)[4] end
    return tonumber(level)
end

local function Professions()
    local list = {}
    local count = Ask(rawget(_G, "GetNumSkillLines")) or 0
    local header
    for index = 1, count do
        local a = Answers(rawget(_G, "GetSkillLineInfo"), index)
        local name, isHeader, rank, most = a[1], a[2], a[4], a[7]
        if isHeader then
            header = name
        elseif type(name) == "string" and header and (header == Core.Word("TRADE_SKILLS", "Professions")
            or header == Core.Word("SECONDARY_SKILLS", "Secondary Skills")) then
            list[#list + 1] = name:gsub("[,:\030\031]", " ") .. ":" .. (tonumber(rank) or 0) .. ":" .. (tonumber(most) or 0)
        end
    end
    return table.concat(list, ",")
end

-- This character's card as text: format, class, race, sex, level, item level, worn ("slot:item:level,..."),
-- professions ("name:rank:most,...").
function Guild.Card()
    local _, class = Ask(UnitClass, "player")
    local _, _, race = Ask(UnitRace, "player")
    local sex = Ask(UnitSex, "player")
    local level = Ask(UnitLevel, "player")
    local worn, sum, counted = {}, 0, 0
    for _, slot in ipairs(Guild.SLOTS) do
        local item = Ask(GetInventoryItemID, "player", slot)
        if item then
            local itemLevel = ItemLevel(Ask(GetInventoryItemLink, "player", slot))
            worn[#worn + 1] = slot .. ":" .. item .. ":" .. (itemLevel or "")
            if itemLevel and slot ~= 4 and slot ~= 19 then sum, counted = sum + itemLevel, counted + 1 end
        end
    end
    local average = counted > 0 and math.floor(sum / counted * 10 + 0.5) / 10 or ""
    return table.concat({ "1", class or "", race or "", sex or "", level or "", average, table.concat(worn, ","), Professions() }, PART)
end

-- A card's text taken apart.
function Guild.ReadCard(text)
    local fields = Split(text, PART)
    if fields[1] ~= "1" then return nil end
    local card = { class = fields[2], race = tonumber(fields[3]), sex = tonumber(fields[4]), level = tonumber(fields[5]),
                   itemLevel = tonumber(fields[6]), worn = {}, professions = {} }
    for _, piece in ipairs(Split(fields[7], ",")) do
        local slot, item, itemLevel = piece:match("^(%d+):(%d+):(%d*)$")
        if slot then card.worn[tonumber(slot)] = { item = tonumber(item), level = tonumber(itemLevel) } end
    end
    for _, piece in ipairs(Split(fields[8], ",")) do
        local name, rank, most = piece:match("^(.-):(%d+):(%d+)$")
        if name then card.professions[#card.professions + 1] = { name = name, rank = tonumber(rank), most = tonumber(most) } end
    end
    return card
end

local Recard = Core.Later(function()
    if not started then return end
    Guild.Publish("card", Guild.Card())
end, 3)

-------------------------------------------------------------------------------
--  What a module calls
-------------------------------------------------------------------------------
function Guild.Key() return key end
function Guild.Info() return info end
function Guild.Roster() return roster end
function Guild.Member(member) return byKey[member] end
function Guild.Peers() return peers end
function Guild.Stamp() return stamp end

function Guild.OnChange(fn)
    listeners[#listeners + 1] = fn
end

function Guild.Version()
    local version = Ask(C_AddOns and C_AddOns.GetAddOnMetadata, "SaneUI", "Version")
    return type(version) == "string" and version or "?"
end

function Guild.History(member, most)
    local events = {}
    if not here then return events end
    local lines = Split(here.history, LIST)
    for index = #lines, 1, -1 do
        local fields = Split(lines[index], PART)
        if not member or fields[3] == member then
            events[#events + 1] = { day = tonumber(fields[1]), what = fields[2], key = fields[3],
                                    from = tonumber(fields[4]), to = tonumber(fields[5]) }
            if most and #events >= most then break end
        end
    end
    return events
end

function Guild.Record(member, kind)
    return Kept(member, kind)
end

function Guild.Records(kind)
    local list = {}
    if not here then return list end
    for member in pairs(here.records) do
        local text, when = Kept(member, kind)
        if text then list[member] = { text = text, stamp = when } end
    end
    return list
end

function Guild.Kind(kind, most)
    if type(kind) == "string" and kind:match("^%a+$") then kinds[kind] = tonumber(most) or 4096 end
end

function Guild.Publish(kind, text)
    if type(text) ~= "string" or not kinds[kind] then return end
    local mine = own[kind]
    if mine and mine.text == text then return end
    own[kind] = { text = text, stamp = Now() }
    local me = Core.PlayerKey("player")
    if me and Keep(me, kind, text, own[kind].stamp) then Changed("records") end
    if allowed[kind] and key then
        Wire.SendBlock(KIND, kind .. PART .. own[kind].stamp .. PART .. text, "GUILD")
    end
end

function Guild.Allow(kind, on)
    local was = allowed[kind]
    allowed[kind] = on and true or nil
    if on and not was and own[kind] and key and started then
        Wire.SendBlock(KIND, kind .. PART .. own[kind].stamp .. PART .. own[kind].text, "GUILD")
    end
end

function Guild.Rights()
    local util = rawget(_G, "C_GuildInfo") or {}
    local function Can(fn) return Ask(fn) == true end
    return {
        invite = Can(rawget(_G, "CanGuildInvite")),
        remove = Can(rawget(_G, "CanGuildRemove")),
        promote = Can(rawget(_G, "CanGuildPromote")),
        demote = Can(rawget(_G, "CanGuildDemote")),
        notes = Can(rawget(_G, "CanEditPublicNote")),
        officerNotes = Can(util.CanEditOfficerNote),
        viewOfficerNotes = Can(util.CanViewOfficerNote),
        motd = Can(rawget(_G, "CanEditMOTD")),
        info = Can(rawget(_G, "CanEditGuildInfo")),
        officer = Can(util.IsGuildOfficer),
        leader = Can(rawget(_G, "IsGuildLeader")),
    }
end

-- The game asked for the roster anew (it answers with GUILD_ROSTER_UPDATE).
local function Request()
    local util = rawget(_G, "C_GuildInfo")
    if util and util.GuildRoster then Ask(util.GuildRoster) else Ask(rawget(_G, "GuildRoster")) end
end

function Guild.Sync()
    if not started then return end
    Request()
    Hello(false)
end

local Reread = Core.Later(function() Guild.Read() end, 0.5)

function Guild.Start()
    if started then return end
    started = true
    Data.Saved(PACK, Opened)
    Wire.Listen(KIND, Heard)
    Wire.ListenBlock(KIND, HeardBlock)
    Core.On("GUILD_ROSTER_UPDATE", Reread)
    Core.On("PLAYER_GUILD_UPDATE", function()
        here, key = Entry()
        Reread()
    end)
    Core.On("PLAYER_EQUIPMENT_CHANGED", Recard)
    Core.On("PLAYER_LEVEL_UP", Recard)
    Core.On("SKILL_LINES_CHANGED", Recard)
    Request()
    Recard()
    -- The first hello once the game has settled, then now and then.
    Core.Later(function()
        Hello(true)
        local ticker = rawget(_G, "C_Timer")
        if ticker and ticker.NewTicker then
            ticker.NewTicker(Guild.HELLO, Core.Guard("data: guild", function() Hello(false) end))
        end
    end, 15)()
end
