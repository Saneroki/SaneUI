local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Wire
--  Sane UI's addon messages (Doc/guides/data.md, *Messages*): what Core sends to the Sane UI of other
--  players in the guild, the party or the raid, and takes from them. One prefix, SaneUI, for everything.
--
--      local Wire = SaneUI.Core.Wire
--      Wire.Listen("G", fn)            fn(sender, fields, channel, name): a message of kind G came; sender is
--                                      the sender's key (guide, *Players*), fields its fields after the head,
--                                      name the sender as the server named it (for a whisper back)
--      Wire.Send("G", { ... }, "GUILD")          queued; a whisper names its target: Wire.Send(kind, fields, "WHISPER", name)
--      Wire.Send("G", { ... }, "GUILD", nil, true)  urgent: before what waits in bulk
--      Wire.ListenBlock("G", fn)       fn(sender, text, channel, name): a block of kind G came whole
--      Wire.SendBlock("G", text, "GUILD")        packed, cut into parts, queued in bulk; false when too large
--                                      or when its parts do not all fit in the queue
--      Wire.SendBlock("G", text, "GUILD", nil, tag)   with a tag of the sender's own (a record's kind), so that
--      Wire.Drop("G", tag)             what still waits of it can be dropped (a switch turned off)
--
--  A message is its kind (letters) with the protocol number, the game version's sign, then its fields, all
--  cut by tabs: "G1\tf\thello\t...". A kind, protocol or game version not this client's is ignored, and so
--  are the player's own messages and a sender whose name has no key. At most 255 bytes: a longer message is
--  not sent (Core.Report says so); what is long goes as a block. A block is packed by the game
--  (C_EncodingUtil, zlib, whose checksum catches damage), made text (Base64) and cut into numbered parts:
--  "P1\tf\t<kind>\t<transfer>\t<part>\t<parts>\t<size>\t<text>"; the size is the unpacked one, checked after
--  unpacking. A packed block is at most 4 KB; a transfer with no new part for two minutes is dropped.
--
--  Received text is read, never run. The event only puts a message into the inbox (Doc/ideas/Data.md,
--  *Limits*); the scheduler takes it in later, within the frame's budget, out of a fight. A sender of more
--  than 90 messages a minute is not heard for ten minutes.
--
--  The queue keeps to the game's budget for addon messages, which it does not publish: ten at once, then one
--  a second; when the game says it was too much (a throttle), half that for half a minute. Nothing is sent
--  in a fight or while the game holds addon messages back (InChatMessagingLockdown); a message waits for at
--  most ten minutes when urgent, an hour in bulk, and at most 300 wait. The queue's frame runs only while
--  something waits.
-------------------------------------------------------------------------------
local Wire = {}
Core.Wire = Wire

Wire.PREFIX = "SaneUI"
Wire.PROTOCOL = 1
Wire.MAX = 255          -- bytes in a message
Wire.PART = 200         -- Base64 text in a block's part
Wire.BLOCK = 4096       -- bytes of a packed block
Wire.UNPACKED = 65536   -- bytes of an unpacked block
Wire.BURST = 10         -- messages at once
Wire.RATE = 1           -- messages a second after that
Wire.SLOW = 30          -- seconds at half the rate after a throttle
Wire.URGENT_HOLD = 600  -- seconds an urgent message waits at most
Wire.BULK_HOLD = 3600   -- seconds one in bulk waits at most
Wire.QUEUE = 300        -- messages waiting at most
Wire.INBOX = 1000       -- messages received, not taken in yet, at most
Wire.STALE = 120        -- seconds without a new part before a transfer is dropped
Wire.PER_MINUTE = 90    -- messages taken from one sender in a minute
Wire.MUTE = 600         -- seconds a sender of too many is not heard
Wire.CHANNELS = { GUILD = true, OFFICER = true, PARTY = true, RAID = true, INSTANCE_CHAT = true, WHISPER = true }
Wire.refused = 0        -- messages the game refused for good since the login (no guild, no group, the target offline): /sane data

local TAB, BLOCK_KIND = "\t", "P"
local SIGNS = { forever = "f", ["forever-beta"] = "b", ["forever-ptr"] = "p", retail = "r", ["retail-beta"] = "q", ["retail-ptr"] = "t" }
local JOB = "wire: inbox"
-- The game's answers to a send (Enum.SendAddonMessageResult): what waits and goes again, what is dropped.
local RESULT = Enum and Enum.SendAddonMessageResult or {}
local THROTTLED = { [RESULT.AddonMessageThrottle or 3] = true, [RESULT.ChannelThrottle or 8] = true }
local HELD = RESULT.AddOnMessageLockdown or 11
local DONE = RESULT.Success or 0

local TEXT = {
    long = "a message of kind %s is %d bytes, more than %d: not sent",
    large = "a block of kind %s is %d bytes packed, more than %d: not sent",
    report = "addon messages: %d waiting to be sent, %d refused by the game since the login.",
}

local listeners, blockListeners = {}, {} -- [kind] = { fn, ... }
local registered = false
local urgent, bulk = {}, {}              -- what waits: { text, channel, target, at }
local tokens, last, slowUntil = Wire.BURST, nil, 0
local inbox, head, tail = {}, 1, 0        -- received, not taken in yet: { text, channel, name }, head to tail
local transfers = {}                     -- [sender key \t transfer] = a block being put together
local heard = {}                         -- [sender key] = { count, since, mutedUntil }
local own, sign                          -- this player's key and game version's sign, once known
local nextTransfer = 0
local frame

local function Now()
    return Core.Ask(GetTime) or 0
end

-- The sign of this client's game version in a message; "u" when it cannot be told (heard only by its like).
function Wire.Sign()
    if not sign then sign = SIGNS[Core.Data.Game and Core.Data.Game() or ""] or "u" end
    return sign
end

local function Own()
    if not own then own = Core.PlayerKey("player") end
    return own
end

-- A field as a message can carry it: text without tabs and zero bytes.
local function Field(value)
    if value == nil then return "" end
    value = tostring(value)
    if value:find("[\t%z]") then value = value:gsub("[\t%z]", " ") end
    return value
end

-- A message's text: its head, then its fields.
function Wire.Text(kind, fields)
    local parts = { kind .. Wire.PROTOCOL, Wire.Sign() }
    for index = 1, fields.n or #fields do parts[#parts + 1] = Field(fields[index]) end
    return table.concat(parts, TAB)
end

-- A message's text taken apart: its kind, protocol, sign and fields; nil for what is no message of ours.
function Wire.Read(text)
    if type(text) ~= "string" or #text > Wire.MAX then return nil end
    local fields, at = {}, 1
    while true do
        local tab = text:find(TAB, at, true)
        if not tab then
            fields[#fields + 1] = text:sub(at)
            break
        end
        fields[#fields + 1] = text:sub(at, tab - 1)
        at = tab + 1
    end
    local kind, protocol = (fields[1] or ""):match("^(%a+)(%d+)$")
    if not kind or #fields < 2 then return nil end
    local sign = fields[2]
    table.remove(fields, 1)
    table.remove(fields, 1)
    return kind, tonumber(protocol), sign, fields
end

-------------------------------------------------------------------------------
--  Sending
-------------------------------------------------------------------------------
local Pump

local function Queue(text, channel, target, hurry, kind, tag)
    local list = hurry and urgent or bulk
    if #urgent + #bulk >= Wire.QUEUE then
        if hurry and #bulk > 0 then table.remove(bulk, 1) else return false end
    end
    list[#list + 1] = { text = text, channel = channel, target = target, at = Now(), kind = kind, tag = tag }
    Pump()
    return true
end

-- Sends a message to a channel (GUILD, PARTY, RAID, INSTANCE_CHAT, OFFICER; WHISPER with its target), in
-- turn; urgent before what waits in bulk. false: not sent (too long, no such channel, the queue full).
function Wire.Send(kind, fields, channel, target, hurry)
    if not Wire.CHANNELS[channel] or (channel == "WHISPER" and type(target) ~= "string") then return false end
    local text = Wire.Text(kind, fields)
    if #text > Wire.MAX then
        Core.Report("wire", TEXT.long:format(kind, #text, Wire.MAX))
        return false
    end
    return Queue(text, channel, target, hurry)
end

-- Sends a block of text, packed, in parts, in bulk. false: not sent (the game cannot pack, too large, the
-- queue has no room for all its parts: a block in part is of no use to anybody).
function Wire.SendBlock(kind, text, channel, target, tag)
    if type(text) ~= "string" or not Wire.CHANNELS[channel] then return false end
    if channel == "WHISPER" and type(target) ~= "string" then return false end
    local util = rawget(_G, "C_EncodingUtil")
    if not util or #text > Wire.UNPACKED then return false end
    local method = Enum and Enum.CompressionMethod and Enum.CompressionMethod.Zlib or 1
    local packed = Core.Ask(util.CompressString, text, method)
    if type(packed) ~= "string" then return false end
    if #packed > Wire.BLOCK then
        Core.Report("wire", TEXT.large:format(kind, #packed, Wire.BLOCK))
        return false
    end
    local encoded = Core.Ask(util.EncodeBase64, packed)
    if type(encoded) ~= "string" then return false end
    local parts = math.max(1, math.ceil(#encoded / Wire.PART))
    if #urgent + #bulk + parts > Wire.QUEUE then return false end
    nextTransfer = nextTransfer % 9999 + 1
    for part = 1, parts do
        local piece = encoded:sub((part - 1) * Wire.PART + 1, part * Wire.PART)
        local fields = { kind, nextTransfer, part, parts, part == 1 and #text or "", piece, n = 6 }
        if not Queue(Wire.Text(BLOCK_KIND, fields), channel, target, false, kind, tag) then return false end
    end
    return true
end

-- What waits of that kind with that tag is not sent after all (Wire.SendBlock's tag): how many were dropped.
function Wire.Drop(kind, tag)
    local dropped = 0
    if tag == nil then return dropped end
    for _, list in ipairs({ urgent, bulk }) do
        for index = #list, 1, -1 do
            if list[index].kind == kind and list[index].tag == tag then
                table.remove(list, index)
                dropped = dropped + 1
            end
        end
    end
    return dropped
end

-- Whether the game lets addon messages go now.
local function Open()
    if InCombatLockdown() then return false end
    local info = rawget(_G, "C_ChatInfo")
    if info and info.InChatMessagingLockdown and Core.Ask(info.InChatMessagingLockdown) == true then return false end
    return true
end

local function Expired(list, hold, now)
    while list[1] and now - list[1].at > hold do table.remove(list, 1) end
end

-- One step of the queue: as many as the budget lets go.
local function Step()
    local now = Now()
    Expired(urgent, Wire.URGENT_HOLD, now)
    Expired(bulk, Wire.BULK_HOLD, now)
    if not urgent[1] and not bulk[1] then
        frame:Hide()
        return
    end
    local rate = now < slowUntil and Wire.RATE / 2 or Wire.RATE
    tokens = math.min(Wire.BURST, tokens + (now - (last or now)) * rate)
    last = now
    if not Open() then return end
    local info = rawget(_G, "C_ChatInfo")
    if not (info and info.SendAddonMessage) then
        wipe(urgent)
        wipe(bulk)
        return
    end
    while tokens >= 1 do
        local list = urgent[1] and urgent or bulk
        local message = list[1]
        if not message then break end
        local ok, result = pcall(info.SendAddonMessage, Wire.PREFIX, message.text, message.channel, message.target)
        result = ok and Core.Plain(result) or nil
        if result == HELD then return end
        if THROTTLED[result] then
            slowUntil = now + Wire.SLOW
            tokens = 0
            return
        end
        table.remove(list, 1) -- sent, or the game refused it for good (no guild, no group, the target offline)
        tokens = tokens - 1
        if result ~= nil and result ~= DONE and result ~= true then Wire.refused = Wire.refused + 1 end
    end
end

function Pump()
    if not frame then
        frame = CreateFrame("Frame")
        frame:Hide()
        frame:SetScript("OnUpdate", Core.Guard("wire", Step))
        Wire.frame = frame -- the queue's frame, shown while something waits (for the tests)
    end
    if not frame:IsShown() then
        last = last or Now()
        frame:Show()
    end
end

-- How many messages wait to be sent.
function Wire.Waiting()
    return #urgent + #bulk
end

-- /sane data: what waits, and what the game refused for good (Data.lua's reports: its file is read before this one).
Core.Data.reports[#Core.Data.reports + 1] = function()
    if #urgent + #bulk + Wire.refused > 0 then Core.Print(TEXT.report:format(#urgent + #bulk, Wire.refused)) end
end

-------------------------------------------------------------------------------
--  Receiving
-------------------------------------------------------------------------------
local function Tell(list, ...)
    if not list then return end
    for _, fn in ipairs(list) do Core.Safe("wire", fn, ...) end
end

-- A sender heard once more: false while it sends too much.
local function Allowed(sender, now)
    local entry = heard[sender]
    if not entry then
        entry = { count = 0, since = now, mutedUntil = 0 }
        heard[sender] = entry
    end
    if now < entry.mutedUntil then return false end
    if now - entry.since >= 60 then entry.count, entry.since = 0, now end
    entry.count = entry.count + 1
    if entry.count > Wire.PER_MINUTE then
        entry.mutedUntil = now + Wire.MUTE
        return false
    end
    return true
end

-- A number in a message: digits only, so never NaN, a fraction or a sign (tonumber takes "nan" and "2.5").
local function Whole(text)
    return type(text) == "string" and text:match("^%d+$") and tonumber(text) or nil
end

-- A block's part: put with the others of its transfer; the whole block told once its last part is there.
local function Part(sender, fields, channel, name, now)
    local kind, id, part, parts, size, piece = fields[1], fields[2], Whole(fields[3]), Whole(fields[4]), fields[5], fields[6]
    if not (kind and kind:match("^%a+$") and id and part and parts and piece) then return end
    if parts < 1 or parts > math.ceil(Wire.BLOCK * 4 / 3 / Wire.PART) + 1 or part < 1 or part > parts then return end
    for key, transfer in pairs(transfers) do
        if now - transfer.seen > Wire.STALE then transfers[key] = nil end
    end
    local key = sender .. TAB .. id
    local transfer = transfers[key]
    if not transfer or transfer.kind ~= kind or transfer.parts ~= parts then
        transfer = { kind = kind, parts = parts, got = 0, pieces = {} }
        transfers[key] = transfer
    end
    transfer.seen = now
    if part == 1 then transfer.size = Whole(size) end
    if not transfer.pieces[part] then
        transfer.pieces[part] = piece
        transfer.got = transfer.got + 1
    end
    if transfer.got < parts then return end
    transfers[key] = nil
    local util = rawget(_G, "C_EncodingUtil")
    if not util or not blockListeners[kind] then return end
    local packed = Core.Ask(util.DecodeBase64, table.concat(transfer.pieces))
    if type(packed) ~= "string" or #packed > Wire.BLOCK then return end
    local method = Enum and Enum.CompressionMethod and Enum.CompressionMethod.Zlib or 1
    local text = Core.Ask(util.DecompressString, packed, method)
    if type(text) ~= "string" or #text ~= transfer.size or #text > Wire.UNPACKED then return end
    Tell(blockListeners[kind], sender, text, channel, name)
end

-- One received message taken in.
function Wire.Take(text, channel, name)
    local kind, protocol, from, fields = Wire.Read(text)
    if not kind or protocol ~= Wire.PROTOCOL or from ~= Wire.Sign() then return end
    local sender = Core.PlayerKeyOf(name)
    if not sender or sender == Own() then return end
    local now = Now()
    if not Allowed(sender, now) then return end
    if kind == BLOCK_KIND then return Part(sender, fields, channel, name, now) end
    Tell(listeners[kind], sender, fields, channel, name)
end

-- The scheduler's job: the inbox taken in, within the frame's budget.
local function Inbox()
    while head <= tail do
        local message = inbox[head]
        inbox[head] = nil
        head = head + 1
        Wire.Take(message.text, message.channel, message.name)
        Core.Steps.Check()
    end
    head, tail = 1, 0
end

-- The game hands a message over: only the least is done here.
local function Heard(prefix, text, channel, name)
    if Core.Plain(prefix) ~= Wire.PREFIX then return end
    text, channel, name = Core.Plain(text), Core.Plain(channel), Core.Plain(name)
    if type(text) ~= "string" or type(name) ~= "string" then return end
    if tail - head + 1 >= Wire.INBOX then return end
    tail = tail + 1
    inbox[tail] = { text = text, channel = channel, name = name }
    if not Core.Steps.Running(JOB) then Core.Steps.Run(JOB, Inbox) end
end

local function Register()
    if registered then return end
    registered = true
    local info = rawget(_G, "C_ChatInfo")
    if info and info.RegisterAddonMessagePrefix then Core.Ask(info.RegisterAddonMessagePrefix, Wire.PREFIX) end
    Core.On("CHAT_MSG_ADDON", Heard)
end

-- fn(sender, fields, channel, name) for every message of that kind.
function Wire.Listen(kind, fn)
    listeners[kind] = listeners[kind] or {}
    table.insert(listeners[kind], fn)
    Register()
end

-- fn(sender, text, channel, name) for every block of that kind, once whole.
function Wire.ListenBlock(kind, fn)
    blockListeners[kind] = blockListeners[kind] or {}
    table.insert(blockListeners[kind], fn)
    Register()
end
