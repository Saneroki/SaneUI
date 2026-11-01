local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Confirm
--  What the game confirmed in play of the facts our data has not had confirmed yet (Doc/guides/data.md,
--  *Verified*), and sharing it, and what Core learned in play, with the Sane UI of the guild, the party and the raid.
--
--      Data.Confirm("Places", 412)              Core's watchers (Watchers.lua): the game agrees with the entry
--      Data.Confirm("Bosses", 1144, "l17076")   ... with a part of it: a boss's item ("l" and its ID), its ability ("a"
--                                               and the spell's); a part the entry lacks (an item the boss dropped
--                                               that the set does not name) is confirmed too: a fact of its own
--      Data.Confirmed("Bosses", 1144, "l17076") whether it is confirmed: the whole entry, or that part
--      Data.ConfirmedParts("Bosses", 1144)      { "l17076", "a8269", ... }: the parts confirmed (a view adds those the
--                                               entry lacks)
--      Data.Confirm("Quests", 77, "name")       ... a field the game told and the entry agrees with; a member of a
--                                               list ("startNPCs=1234"); a spawn point ("p" and its code): Check.lua
--                                               and Watchers.lua
--      Data.OnConfirm(fn)                       fn() on the frame after something was confirmed, here or by others
--      Data.Share("Items", 16801)               a row learned here (Data.Learn) shared with the guild and the group
--
--  Kept in SaneUIData_Learned[game].confirmed[set][key] = "day\031build\031parts", the parts cut by \030 ("*": the
--  whole entry), until the harvest takes them into the master (dev/tools/data harvest) and a release ships the entry
--  verified; at the login those of an entry the set no longer lists unverified (and Core did not learn) are dropped.
--  Handle:Unverified (Data.lua) asks Data.Confirmed. Of an entry Core learned, the parts the game told are kept too
--  (Confirm.Told), so the harvest takes only those of the row. What members confirmed stands apart in heard[set][key],
--  of the same shape: the views read it as confirmed, it is never sent on, and the harvest never reads it. Whether the
--  game's own word is kept and shared is decided by this client's own alone (Data.Confirmed's own, Unverified's), so
--  what members told never stands in for the game's word here.
--
--  Shared (the wire's kind V: set, key, parts; learned rows as a block of kind L) with the guild and with the party or
--  raid, whoever there has Sane UI: what one player confirms, the others take (an entry or a part they have unverified;
--  a boss's item or ability only where the game knows that item or spell). Sent slowly, Confirm.GAP seconds apart, and
--  never in a fight, while the game restricts addons, or inside an instance: what is found there waits in the outbox
--  (kept in the saved file, at most Confirm.OUTBOX) and goes once the player is out and has somebody to tell.
--
--  No message is trusted (Doc/ideas/Data.md, *Poisoning*). A member's confirmation waits in session memory until
--  Bundle.SENDERS different members sent the same part, one of them on the guild's channel (a group can hold strangers),
--  unless the sender is this player's other account (Prices.Mine); a part must be one Check.lua would make of the entry
--  as this client has it, and an entry takes at most Confirm.MOST parts from members. A row learned by somebody else is
--  taken only where it changes nothing but what play teaches of the thing (Confirm.SHARED: an item's stats, armour,
--  damage and speed), or where the set lacks the item and the game knows it; a set keeps at most Confirm.KEPT such rows,
--  apart from what was learned here (Data.LearnRow). A block off its shape (a key that is no number, more rows than
--  Confirm.ROWS) is a strike (Relay.Strike). A confirmation or row taken from others is not passed on again.
-------------------------------------------------------------------------------
local Data, Wire, Codec = Core.Data, Core.Wire, Core.Data.Codec

local Confirm = {}
Data.Confirmations = Confirm
Confirm.GAP = 2        -- seconds between two sends
Confirm.WAIT = 10      -- seconds before a send the wire had no room for is tried again
Confirm.OUTBOX = 500   -- confirmations and rows waiting at most; the oldest go first
Confirm.PARTS = 12     -- parts of one entry in one message at most
Confirm.ROWS = 8       -- learned rows in one block at most
Confirm.MOST = 60      -- parts of one entry taken from members at most
Confirm.WAITING = 200  -- parts heard from one member that wait for the others at most
Confirm.KEPT = 500     -- rows of one set taken from members at most; the oldest go first
-- The fields a row learned by somebody else may change: what play teaches of the thing.
Confirm.SHARED = { Items = { stats = true, armor = true, damageMin = true, damageMax = true, speed = true } }
-- The kinds of parts, and how a part from somebody else is checked: the game must know the item or the spell.
local function Asked(api, name, ...)
    local space = rawget(_G, api)
    return type(space) == "table" and Core.Ask(space[name], ...) ~= nil
end
Confirm.KINDS = {
    l = function(id)
        local items = Data.Set("Items")
        return (items:Ready() and items:Get(id) ~= nil) or Asked("C_Item", "GetItemInfoInstant", id)
    end,
    a = function(id) return Asked("C_Spell", "GetSpellName", id) end,
}

local WHOLE, LIST, PART = "*", "\030", "\031"
local ENTRY, ROW = "\028", "\029" -- a block's rows: set, key and row cut by \028, the rows by \029
local HEARD = { GUILD = true, PARTY = true, RAID = true, INSTANCE_CHAT = true } -- taken from these channels only

local confirmed      -- this client's confirmed[set][key] = packed, once Core's saved variables are read
local heard          -- what members confirmed, heard[set][key] = packed, apart: never sent on, never harvested
local outbox         -- what waits to be shared: "V\031set\031key\031part" or "L\031set\031key"
local parsed = {}    -- [set][key] = { day, build, parts = { [part] = true } (this client's and the members' together),
                     -- own = { ... }, heard = { ... } }, made from the saved texts when first asked
local voices = {}    -- ["set\031key\031part"] = { by = { [sender] = true }, count, guild }: a member's confirmation that
                     -- waits for the others (session memory)
local waiting = {}   -- [sender] = how many parts wait with its name
local listeners = {}

-- The server's day (days since 1970) and the client's build: when something was confirmed.
local function Today()
    local now = Core.Ask(rawget(_G, "GetServerTime")) or Core.Ask(rawget(_G, "time")) or 0
    return math.floor(now / 86400)
end

local function Build()
    local _, number = Core.Ask(rawget(_G, "GetBuildInfo"))
    return tonumber(number) or 0
end

-- Whether the sender is a character of this player's other account (Prices.lua, read after this file).
local function Mine(sender)
    local prices = Data.Series and Data.Series("Prices")
    return prices ~= nil and prices.Mine(sender) == true
end

-- The parts of a packed text ("day\031build\031parts") into one of an entry's sets (own or heard), and into its parts;
-- its day and build where newer.
local function Unpack(entry, packed, into)
    if type(packed) ~= "string" then return end
    local fields = Codec.Cut(packed, PART)
    entry.day, entry.build = math.max(entry.day, tonumber(fields[1]) or 0), math.max(entry.build, tonumber(fields[2]) or 0)
    for _, part in ipairs(Codec.Cut(fields[3] or "", LIST)) do
        if part ~= "" then into[part], entry.parts[part] = true, true end
    end
end

-- An entry's confirmations taken apart, this client's own and the members' together; nil when there are none (or the
-- saved values are no packed texts).
local function Parsed(name, key)
    local list = parsed[name]
    if not list then
        list = {}
        parsed[name] = list
    end
    local entry = list[key]
    if entry ~= nil then return entry or nil end
    local own = confirmed and type(confirmed[name]) == "table" and confirmed[name][key]
    local told = heard and type(heard[name]) == "table" and heard[name][key]
    if type(own) ~= "string" and type(told) ~= "string" then
        list[key] = false
        return nil
    end
    entry = { day = 0, build = 0, parts = {}, own = {}, heard = {} }
    Unpack(entry, own, entry.own)
    Unpack(entry, told, entry.heard)
    list[key] = entry
    return entry
end

-- Whether the whole entry, or that part, is confirmed: by the game here or by members (a view's question); own: by the
-- game here alone, what members told aside (the question where this client's own confirming and sending are decided).
function Data.Confirmed(name, key, part, own)
    local entry = Parsed(name, key)
    if not entry then return false end
    local parts = own and entry.own or entry.parts
    return parts[WHOLE] or (part ~= nil and parts[part]) or false
end

-- A set of parts as a sorted list, the whole entry's mark left out.
local function Listed(parts)
    local list = {}
    for part in pairs(parts or {}) do
        if part ~= WHOLE then list[#list + 1] = part end
    end
    table.sort(list)
    return list
end

-- The parts confirmed, sorted: by the game here or by members; own: the game's here alone (Check.lua's play list).
function Data.ConfirmedParts(name, key, own)
    local entry = Parsed(name, key)
    return Listed(entry and (own and entry.own or entry.parts))
end

-- The parts the game told here, none of the members': what a learned row of this client's goes out with (Bundle.lua).
function Confirm.ToldParts(name, key)
    return Data.ConfirmedParts(name, key, true)
end

local Tell = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("data: confirmed", fn) end
end)

function Data.OnConfirm(fn)
    for _, known in ipairs(listeners) do
        if known == fn then return end
    end
    listeners[#listeners + 1] = fn
end

-- A part's waiting voices forgotten: it was settled, here or by enough members.
local function Settled(name, key, part)
    local text = name .. PART .. tostring(key) .. PART .. part
    local entry = voices[text]
    if not entry then return end
    for sender in pairs(entry.by) do waiting[sender] = waiting[sender] - 1 end
    voices[text] = nil
end

-- Keeps a confirmation: the entry's packed text written anew with the part added, today's day and this build; a
-- member's (others) apart, in heard, read together with this client's own.
local function Store(name, key, part, others)
    local where = others and heard or confirmed
    if type(where[name]) ~= "table" then where[name] = {} end
    local entry = Parsed(name, key) or { day = 0, build = 0, parts = {}, own = {}, heard = {} }
    local kept = others and entry.heard or entry.own
    kept[part], entry.parts[part] = true, true
    entry.day, entry.build = Today(), Build()
    local list = {}
    for each in pairs(kept) do list[#list + 1] = each end
    table.sort(list)
    where[name][key] = entry.day .. PART .. entry.build .. PART .. table.concat(list, LIST)
    Data.NoteBuild()
    parsed[name][key] = entry
    Settled(name, key, part)
    Tell()
end

-------------------------------------------------------------------------------
--  Sharing
-------------------------------------------------------------------------------
local Step
local soon = Core.Later(function() Step() end, Confirm.GAP)
local later = Core.Later(function() Step() end, Confirm.WAIT)

local function Queue(text)
    if not outbox then return end
    for _, waiting in ipairs(outbox) do
        if waiting == text then return end
    end
    if #outbox >= Confirm.OUTBOX then table.remove(outbox, 1) end
    outbox[#outbox + 1] = text
    soon()
end

-- The channels there is somebody to tell on: the guild, and the raid or else the party.
local function Channels()
    local list = {}
    if Core.Ask(rawget(_G, "IsInGuild")) then list[#list + 1] = "GUILD" end
    local home = rawget(_G, "LE_PARTY_CATEGORY_HOME")
    if Core.Ask(rawget(_G, "IsInRaid"), home) then
        list[#list + 1] = "RAID"
    elseif Core.Ask(rawget(_G, "IsInGroup"), home) then
        list[#list + 1] = "PARTY"
    end
    return list
end

-- Whether sharing waits now: a fight, a restriction of the game's, or inside an instance (the group's own chat there
-- is kept for the fight).
local function Held()
    if Core.Restricted() or not Core.Data.Sharing() then return true end
    return Core.Ask(rawget(_G, "IsInInstance")) == true
end
Confirm.Held = Held

-- The first of what waits, with what else waits of the same kind that goes along: a confirmation's other parts of the
-- same entry, other learned rows.
local function Take()
    local first = Codec.Cut(outbox[1], PART)
    local taken, parts, rows = { 1 }, {}, {}
    for index, text in ipairs(outbox) do
        local fields = Codec.Cut(text, PART)
        if first[1] == "V" and fields[1] == "V" and fields[2] == first[2] and fields[3] == first[3] and #parts < Confirm.PARTS then
            parts[#parts + 1] = fields[4]
            if index > 1 then taken[#taken + 1] = index end
        elseif first[1] == "L" and fields[1] == "L" and #rows < Confirm.ROWS then
            local row = Data.Learned(fields[2], tonumber(fields[3]) or fields[3])
            if row then rows[#rows + 1] = fields[2] .. ENTRY .. fields[3] .. ENTRY .. row end
            if index > 1 then taken[#taken + 1] = index end
        end
    end
    return first, taken, parts, rows
end

-- A send: the first of what waits with what goes along, on every channel there is somebody on. Nothing while sharing
-- is held (a fight, a restriction, an instance, the switch off) or nobody is there: the events below and the switch
-- (Confirm.Switched) ask again then; only a send the wire had no room for is tried again by itself, Confirm.WAIT
-- seconds later.
function Step()
    if not outbox or #outbox == 0 or Held() then return end
    local channels = Channels()
    if #channels == 0 then return end
    local first, taken, parts, rows = Take()
    local sent = true
    for _, channel in ipairs(channels) do
        if first[1] == "V" then
            sent = Wire.Send("V", { first[2], first[3], table.concat(parts, ","), n = 3 }, channel) and sent
        elseif #rows > 0 then
            sent = Wire.SendBlock("L", table.concat(rows, ROW), channel) and sent
        end
    end
    if not sent then return later() end -- the wire's queue is full: tried again later
    table.sort(taken, function(a, b) return a > b end)
    for _, index in ipairs(taken) do table.remove(outbox, index) end
    if #outbox > 0 then soon() end
end

for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "ADDON_RESTRICTION_STATE_CHANGED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
    "PLAYER_GUILD_UPDATE" }) do
    Core.On(event, function()
        if outbox and #outbox > 0 then soon() end
    end)
end

-- The switch Share data with my guild and group turned (Saved.lua, the general options' hook): what waited goes.
function Confirm.Switched()
    if outbox and #outbox > 0 then soon() end
end

-- A key as a message carries it, as the set has it: a number for a set keyed by numbers.
local function Key(name, text)
    local number = tonumber(text)
    if number and Data.Set(name):Get(number) then return number end
    return text
end

-- A part of somebody else's: whole; a field the game told, as Check.lua names it (a field told whole, "startNPCs=1234"
-- a member of a list the entry holds, "health=12" a key of a map it holds); or one of a known kind whose item or
-- spell the game knows. Never a part the entry as this client has it could not have.
local function Known(name, key, part)
    if part == WHOLE then return true end
    local handle = Data.Set(name)
    local field, value = part:match("^([%w_]+)=(.*)$")
    if not field then
        if handle:HasField(part) then
            local how = Data.Checks.Spec(handle)[part]
            return not (how and (how.member or how.map)) -- a list's or a map's part names its member
        end
        local kind, id = part:match("^(%a)(%d+)$")
        local check = kind and Confirm.KINDS[kind]
        return check ~= nil and check(tonumber(id)) == true
    end
    local how = handle:HasField(field) and Data.Checks.Spec(handle)[field]
    local held = how and handle:Get(key, field)
    if not (how and type(held) == "table") then return false end
    if how.map then
        for inner in pairs(held) do
            if tostring(inner) == value then return true end
        end
        return false
    end
    if not how.member then return false end
    for _, element in ipairs(held) do
        local id = element
        if how.by then id = type(element) == "table" and element[how.by] or nil end
        if id ~= nil and tostring(id) == value then return true end
    end
    return false
end

-- Whether an entry holds as many parts as members may give it.
local function Full(name, key)
    local entry = Parsed(name, key)
    if not entry then return false end
    local count = 0
    for _ in pairs(entry.parts) do count = count + 1 end
    return count >= Confirm.MOST
end

-- A part a member confirmed: true once Bundle.SENDERS different members sent it, one of them on the guild's channel (a
-- group can hold strangers); until then it waits in session memory, at most Confirm.WAITING parts with one member's name.
local function Agreed(name, key, part, sender, channel)
    local text = name .. PART .. tostring(key) .. PART .. part
    local entry = voices[text]
    if not (entry and entry.by[sender]) then
        if (waiting[sender] or 0) >= Confirm.WAITING then return false end
        if not entry then
            entry = { by = {}, count = 0 }
            voices[text] = entry
        end
        entry.by[sender], entry.count, waiting[sender] = true, entry.count + 1, (waiting[sender] or 0) + 1
    end
    if channel == "GUILD" then entry.guild = true end
    return entry.count >= Data.Bundle.SENDERS and entry.guild == true
end

-- A confirmation from somebody else: kept apart where this client has the entry, or that part of it, unverified, once
-- enough members said the same (Agreed), or this player's other account did.
Wire.Listen("V", function(sender, fields, channel)
    if not (heard and HEARD[channel] and Data.Sharing()) then return end
    local name, text = fields[1], fields[2]
    if type(name) ~= "string" or not Data.Set(name):Ready() or type(text) ~= "string" then return end
    local key = Key(name, text)
    if not Data.Set(name):Get(key) then return end
    local mine = Mine(sender)
    for part in (fields[3] or ""):gmatch("[^,]+") do
        local asked = part ~= WHOLE and part or nil
        if Data.Set(name):Unverified(key, asked) and Known(name, key, part) and not Full(name, key)
            and (mine or Agreed(name, key, part, sender, channel)) then
            Store(name, key, part, true)
        end
    end
end)

-- Rows learned by somebody else: each taken where it changes only what play teaches of the thing (Confirm.SHARED), or
-- names an item the set lacks and the game knows; kept apart (Data.LearnRow). A key that is no number, or more rows
-- than a block may hold, is off its shape: the rest of the block is passed over, and the sender earns a strike.
Wire.ListenBlock("L", function(sender, text, channel)
    if not (HEARD[channel] and Data.Sharing()) or type(text) ~= "string" then return end
    local rows = Codec.Cut(text, ROW)
    local strike = #rows > Confirm.ROWS
    for index = 1, math.min(#rows, Confirm.ROWS) do
        local fields = Codec.Cut(rows[index], ENTRY)
        local name, keyText, row = fields[1], fields[2], fields[3]
        if not (keyText and keyText:match("^%d+$") and row) then
            strike = true
            break
        end
        local open = name and Confirm.SHARED[name]
        if open then
            local key = tonumber(keyText)
            local before = Data.Set(name):Get(key)
            local taken = Data.LearnRow(name, key, row, function(record, current)
                -- an item the set lacks: only one the game knows (Items is the one set shared this way)
                if not current then return record.name ~= nil and Confirm.KINDS.l(key) == true end
                for field, value in pairs(record) do
                    if not open[field] and field ~= "since" and field ~= "day" and field ~= "patch"
                        and not Core.Same(value, current[field]) then return false end
                end
                for field, value in pairs(current) do
                    if not open[field] and record[field] == nil and field ~= "since" and field ~= "day" and field ~= "patch"
                        and value ~= nil then return false end
                end
                return true
            end, Confirm.KEPT)
            if taken then Data.Discovered(name, key, before and "changed" or "new", nil, "shared") end
        end
    end
    if strike then Data.Relay.Strike(sender) end
end)

-------------------------------------------------------------------------------
--  Confirming
-------------------------------------------------------------------------------
-- The game agrees with an entry (part nil) or a part of it: kept, the views told on the next frame, and shared. Only
-- where the entry is there and still unverified (a part the entry lacks counts, the entry being unverified). True when
-- it was kept.
function Data.Confirm(name, key, part)
    if not confirmed or key == nil then return false end
    local handle = Data.Set(name)
    -- the game's own word, whatever members told of it (own): kept as this client's, and shared
    if not handle:Get(key) or not handle:Unverified(key, part, true) then return false end
    part = part or WHOLE
    Store(name, key, part)
    Queue("V" .. PART .. name .. PART .. tostring(key) .. PART .. part)
    return true
end

-- What the game told of an entry Core learned (Check.lua): its parts kept as told, so the harvest stages only what the
-- game said of the row and not the set's facts it carries along. Not shared: a learned row goes as a whole.
function Confirm.Told(name, key, part)
    if not confirmed or key == nil or type(part) ~= "string" then return false end
    local entry = Parsed(name, key)
    if entry and entry.own[part] then return true end
    Store(name, key, part)
    return true
end

-- A part members told of an entry, with a row enough of them sent (Bundle.lua): kept apart as heard, where the entry as
-- this client has it can hold it (Known). True when it is, or was, kept.
function Confirm.Heard(name, key, part)
    if not heard or key == nil or type(part) ~= "string" or not Data.Set(name):Ready() then return false end
    local entry = Parsed(name, key)
    if entry and entry.parts[part] then return true end
    if not Known(name, key, part) or Full(name, key) then return false end
    Store(name, key, part, true)
    return true
end

-- A row learned here shared with the guild and the group (only the sets others take, Confirm.SHARED).
function Data.Share(name, key)
    if not (Confirm.SHARED[name] and Data.Learned(name, key)) then return false end
    Queue("L" .. PART .. name .. PART .. tostring(key))
    return true
end

-- What a release took in since: the confirmations of an entry the set no longer lists unverified, and that Core did
-- not learn (nor take from members), are dropped (the master has them); asked before this client's confirmations
-- count, so only the set's own marks answer.
local function Drop(list)
    for name, entries in pairs(list) do
        local handle = Data.Set(name)
        if type(entries) ~= "table" then
            list[name] = nil
        elseif handle:Ready() then
            for key in pairs(entries) do
                -- gone from the set too (nor learned): nothing left to confirm
                local learnt = Data.Learned(name, key) ~= nil or Data.Taken(name, key) ~= nil
                if not handle:Get(key) or (not learnt and not handle:Unverified(key)) then entries[key] = nil end
            end
            if next(entries) == nil then list[name] = nil end
        end
    end
end

Data.Saved("Learned", function(part)
    for _, name in ipairs({ "confirmed", "heard", "outbox" }) do
        if type(part[name]) ~= "table" then part[name] = {} end
    end
    Drop(part.confirmed)
    Drop(part.heard)
    confirmed, heard, outbox, parsed = part.confirmed, part.heard, part.outbox, {}
    for index = #outbox, 1, -1 do
        if type(outbox[index]) ~= "string" then table.remove(outbox, index) end
    end
    if #outbox > 0 then later() end
end)
