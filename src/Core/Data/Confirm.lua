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
--      Data.OnConfirm(fn)                       fn() on the frame after something was confirmed, here or by others
--      Data.Share("Items", 16801)               a row learned here (Data.Learn) shared with the guild and the group
--
--  Kept in SaneUIData_Learned[game].confirmed[set][key] = "day\031build\031parts", the parts cut by \030 ("*": the
--  whole entry), until the harvest takes them into the master (dev/tools/data harvest) and a release ships the entry
--  verified. Handle:Unverified (Data.lua) asks Data.Confirmed.
--
--  Shared (the wire's kind V: set, key, parts; learned rows as a block of kind L) with the guild and with the party or
--  raid, whoever there has Sane UI: what one player confirms, the others take (an entry or a part they have unverified;
--  a boss's item or ability only where the game knows that item or spell). Sent slowly, Confirm.GAP seconds apart, and
--  never in a fight, while the game restricts addons, or inside an instance: what is found there waits in the outbox
--  (kept in the saved file, at most Confirm.OUTBOX) and goes once the player is out and has somebody to tell. A row
--  learned by somebody else is taken only where it changes nothing but what play teaches of it (Confirm.SHARED: an
--  item's stats, armour, damage and speed); a confirmation or row taken from others is not passed on again.
-------------------------------------------------------------------------------
local Data, Wire, Codec = Core.Data, Core.Wire, Core.Data.Codec

local Confirm = {}
Data.Confirmations = Confirm
Confirm.GAP = 2        -- seconds between two sends
Confirm.WAIT = 10      -- seconds between two looks while the outbox waits (a fight, an instance, nobody to tell)
Confirm.OUTBOX = 500   -- confirmations and rows waiting at most; the oldest go first
Confirm.PARTS = 12     -- parts of one entry in one message at most
Confirm.ROWS = 8       -- learned rows in one block at most
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
local outbox         -- what waits to be shared: "V\031set\031key\031part" or "L\031set\031key"
local parsed = {}    -- [set][key] = { day, build, parts = { [part] = true } }, made from confirmed when first asked
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

-- An entry's confirmations taken apart; nil when there are none (or the saved value is no packed text).
local function Parsed(name, key)
    local list = parsed[name]
    if not list then
        list = {}
        parsed[name] = list
    end
    local entry = list[key]
    if entry ~= nil then return entry or nil end
    local packed = confirmed and type(confirmed[name]) == "table" and confirmed[name][key]
    if type(packed) ~= "string" then
        list[key] = false
        return nil
    end
    local fields = Codec.Cut(packed, PART)
    entry = { day = tonumber(fields[1]) or 0, build = tonumber(fields[2]) or 0, parts = {} }
    for _, part in ipairs(Codec.Cut(fields[3] or "", LIST)) do
        if part ~= "" then entry.parts[part] = true end
    end
    list[key] = entry
    return entry
end

function Data.Confirmed(name, key, part)
    local entry = Parsed(name, key)
    if not entry then return false end
    return entry.parts[WHOLE] or (part ~= nil and entry.parts[part]) or false
end

function Data.ConfirmedParts(name, key)
    local list = {}
    local entry = Parsed(name, key)
    if entry then
        for part in pairs(entry.parts) do
            if part ~= WHOLE then list[#list + 1] = part end
        end
        table.sort(list)
    end
    return list
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

-- Keeps a confirmation: the entry's packed text written anew with the part added, today's day and this build.
local function Store(name, key, part)
    if type(confirmed[name]) ~= "table" then confirmed[name] = {} end
    local entry = Parsed(name, key) or { parts = {} }
    entry.parts[part] = true
    entry.day, entry.build = Today(), Build()
    local list = {}
    for each in pairs(entry.parts) do list[#list + 1] = each end
    table.sort(list)
    confirmed[name][key] = entry.day .. PART .. entry.build .. PART .. table.concat(list, LIST)
    Data.NoteBuild()
    parsed[name][key] = entry
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
    if Core.Restricted() then return true end
    return Core.Ask(rawget(_G, "IsInInstance")) == true
end

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

function Step()
    if not outbox or #outbox == 0 then return end
    local channels = not Held() and Channels() or {}
    if #channels == 0 then return later() end
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

for _, event in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE" }) do
    Core.On(event, function()
        if outbox and #outbox > 0 then soon() end
    end)
end

-- A key as a message carries it, as the set has it: a number for a set keyed by numbers.
local function Key(name, text)
    local number = tonumber(text)
    if number and Data.Set(name):Get(number) then return number end
    return text
end

-- A part of somebody else's: whole, or one of a known kind whose item or spell the game knows.
local function Known(part)
    if part == WHOLE then return true end
    local kind, id = part:match("^(%a)(%d+)$")
    local check = kind and Confirm.KINDS[kind]
    return check ~= nil and check(tonumber(id)) == true
end

-- A confirmation from somebody else: kept where this client has the entry, or that part of it, unverified.
Wire.Listen("V", function(_, fields, channel)
    if not (confirmed and HEARD[channel]) then return end
    local name, text = fields[1], fields[2]
    if type(name) ~= "string" or not Data.Set(name):Ready() or type(text) ~= "string" then return end
    local key = Key(name, text)
    if not Data.Set(name):Get(key) then return end
    for part in (fields[3] or ""):gmatch("[^,]+") do
        local asked = part ~= WHOLE and part or nil
        if Known(part) and Data.Set(name):Unverified(key, asked) then Store(name, key, part) end
    end
end)

-- Rows learned by somebody else: each taken where it changes only what play teaches of the thing (Confirm.SHARED).
Wire.ListenBlock("L", function(_, text, channel)
    if not HEARD[channel] or type(text) ~= "string" then return end
    for _, item in ipairs(Codec.Cut(text, ROW)) do
        local fields = Codec.Cut(item, ENTRY)
        local name, row = fields[1], fields[3]
        local open = name and Confirm.SHARED[name]
        if open and row and fields[2] then
            local key = tonumber(fields[2]) or fields[2]
            Data.LearnRow(name, key, row, function(record, current)
                if not current then return record.name ~= nil end
                for field, value in pairs(record) do
                    if not open[field] and field ~= "since" and field ~= "day" and field ~= "patch"
                        and not Core.Same(value, current[field]) then return false end
                end
                for field, value in pairs(current) do
                    if not open[field] and record[field] == nil and field ~= "since" and field ~= "day" and field ~= "patch"
                        and value ~= nil then return false end
                end
                return true
            end)
        end
    end
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
    if not handle:Get(key) or not handle:Unverified(key, part) then return false end
    part = part or WHOLE
    Store(name, key, part)
    Queue("V" .. PART .. name .. PART .. tostring(key) .. PART .. part)
    return true
end

-- A row learned here shared with the guild and the group (only the sets others take, Confirm.SHARED).
function Data.Share(name, key)
    if not (Confirm.SHARED[name] and Data.Learned(name, key)) then return false end
    Queue("L" .. PART .. name .. PART .. tostring(key))
    return true
end

Data.Saved("Learned", function(part)
    if type(part.confirmed) ~= "table" then part.confirmed = {} end
    if type(part.outbox) ~= "table" then part.outbox = {} end
    confirmed, outbox, parsed = part.confirmed, part.outbox, {}
    for index = #outbox, 1, -1 do
        if type(outbox[index]) ~= "string" then table.remove(outbox, index) end
    end
    if #outbox > 0 then later() end
end)
