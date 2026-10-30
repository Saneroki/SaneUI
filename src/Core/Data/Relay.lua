local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Relay
--  Auction prices shared with the guild and the group (Doc/ideas/Data.md, *Scans*): when a member's Sane UI keeps a full
--  scan, every other member's prices move too, at once and by themselves. So do those of this player's other accounts
--  running in the same guild or group, who are members like any other. The way of it:
--
--      have   a scan was kept: one message on the guild and the group: this house, this time
--      want   a member with nothing as new answers on that channel after a moment; the others hear it and stay quiet
--      blocks only then, on that channel: what moved in that scan. With nobody asking, one message is all there is
--      ask    a minute after the login: who has a newer scan of this house? The one who answers offers it whole
--
--  One transfer per house in Relay.QUIET seconds, whatever the guild's size, and only the guild, the party and the
--  raid: never a whisper, where the server would not stand for the sender. A received text is read, never run, and
--  fills in only where this account's point is older (Prices.Heard). What came from others is not passed on. The
--  switch Share data with my guild and group turns all of it off, sending and taking.
-------------------------------------------------------------------------------
local Data, Wire = Core.Data, Core.Wire
local Prices = Data.Series("Prices")
local Relay = {}
Data.Relay = Relay

Relay.QUIET = 15 * 60 -- seconds: one transfer per house, and a member who has one this new wants no other
Relay.MOST = 6000     -- items of one scan told: about six minutes at the messages' pace
Relay.BYTES = 6000    -- bytes of a block before it is packed: well under the wire's 4 KB packed
Relay.WAIT = 3        -- seconds at most a member waits before it answers, so that not all answer at once
Relay.RETRY = 5       -- seconds before a block the queue had no room for is tried again
Relay.LISTEN = 60     -- seconds after the login before asking: a transfer under way rides along

local KIND, TAG = "A", "prices"
local offer             -- this account's scan on offer: { house, at, lines, channels, turn, sent, blocks }
local transfers = {}    -- [house] = the newest scan a member offered or sent
local taken = {}        -- [house] = the newest scan taken from a member
local asking = {}       -- [house] = the scan this account is about to want
Relay.heard = { items = 0 } -- what members told: for /sane data

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

local function Stop()
    Wire.Drop(KIND, TAG)
    offer = nil
end

-- The lines cut into blocks, each saying what house and when.
local function Blocks(given)
    local blocks, lines, size = {}, {}, 0
    local head = ("%s\n%d\n"):format(given.house, given.at)
    local function Close()
        blocks[#blocks + 1] = head .. table.concat(lines)
        lines, size = {}, 0
    end
    for _, line in ipairs(given.lines) do
        if size + #line > Relay.BYTES then Close() end
        lines[#lines + 1] = line
        size = size + #line
    end
    if #lines > 0 then Close() end
    return blocks
end

local FeedSoon

-- The blocks as the queue has room for them, a channel at a time. A block it refuses with nothing waiting never fits: passed over.
local function Feed()
    while offer and offer.channels[offer.turn] do
        while offer.sent < #offer.blocks do
            local sent = Wire.SendBlock(KIND, offer.blocks[offer.sent + 1], offer.channels[offer.turn], nil, TAG)
            if not sent and Wire.Waiting() > 0 then
                FeedSoon()
                return
            end
            offer.sent = offer.sent + 1
        end
        offer.turn, offer.sent = offer.turn + 1, 0
    end
end
FeedSoon = Core.Later(Feed, Relay.RETRY)

-- Somebody on that channel wants the scan on offer.
local function Serve(channel)
    for _, known in ipairs(offer.channels) do
        if known == channel then return end
    end
    offer.channels[#offer.channels + 1] = channel
    offer.blocks = offer.blocks or Blocks(offer)
    Feed()
end

-- A scan to offer: what moved in it, or all of it for a member who asked. A newer scan goes on, what waits of the last is
-- dropped; a member who scans soon after a transfer of that house keeps it to itself.
function Relay.Offer(house, at, lines)
    Stop()
    if not (Data.Sharing() and house and #lines > 0) or at - (transfers[house] or 0) < Relay.QUIET then return end
    for index = #lines, Relay.MOST + 1, -1 do lines[index] = nil end
    offer = { house = house, at = at, lines = lines, channels = {}, turn = 1, sent = 0 }
    for _, channel in ipairs(Channels()) do
        Wire.Send(KIND, { "have", house, at, n = 3 }, channel, nil, true)
    end
end

-- A member offers a scan: wanted unless this account has something as new; after a moment, unless somebody else asked.
local function Offered(house, at, channel)
    transfers[house] = math.max(transfers[house] or 0, at)
    if offer and offer.house == house and offer.at < at then Stop() end
    local kept = Prices.Kept(house)
    if not kept or at - math.max(kept, taken[house] or 0) < Relay.QUIET or asking[house] == at then return end
    asking[house] = at
    Core.Later(function()
        if asking[house] ~= at then return end
        asking[house] = nil
        Wire.Send(KIND, { "want", house, at, n = 3 }, channel, nil, true)
    end, math.random() * Relay.WAIT)()
end

-- A member who just logged in asks: the one with the newest scan offers it, the others hear that and stay quiet.
local function Asked(house, since)
    local kept = Prices.Kept(house)
    if not kept or kept <= since then return end
    Core.Later(function()
        if (transfers[house] or 0) >= kept then return end
        local at, lines = Prices.Lines(house, since)
        if at then Relay.Offer(house, at, lines) end
    end, 1 + math.random())()
end

function Relay.Told(_, fields, channel)
    if channel == "WHISPER" or not Data.Sharing() then return end
    local what, house, at = fields[1], fields[2], tonumber(fields[3])
    if not (house and at) then return end
    if what == "have" then
        Offered(house, at, channel)
    elseif what == "want" then
        if asking[house] == at then asking[house] = nil end
        if offer and offer.house == house and offer.at == at then Serve(channel) end
    elseif what == "ask" then
        Asked(house, at)
    end
end

-- A block whole: "house\nat\nlines".
function Relay.Block(sender, text, channel)
    if channel == "WHISPER" or not Data.Sharing() then return end
    local house, at, lines = text:match("^([^\n]+)\n(%d+)\n(.*)$")
    if not house then return end
    at = tonumber(at)
    transfers[house] = math.max(transfers[house] or 0, at)
    if Prices.Heard(house, at, lines, sender) then
        taken[house] = math.max(taken[house] or 0, at)
        local _, count = lines:gsub(";", ";")
        Relay.heard.items, Relay.heard.at = Relay.heard.items + count, at
    end
end

-- A minute after the login: who has a newer scan of the house of this player's side?
local function Ask()
    if not Data.Sharing() then return end
    local home = Prices.House("player")
    local house = home and Prices.Key(home)
    if not house or transfers[house] then return end
    for _, channel in ipairs(Channels()) do
        Wire.Send(KIND, { "ask", house, math.max(Prices.Kept(house) or 0, taken[house] or 0), n = 3 }, channel, nil, true)
    end
end

Relay.Ask = Ask
Wire.Listen(KIND, Relay.Told)
Wire.ListenBlock(KIND, Relay.Block)
Core.On("PLAYER_LOGIN", Core.Later(Ask, Relay.LISTEN))

-- /sane data: what members told since the login.
local SAY = { heard = "auction prices told by your guild and group since the login: %d, the last from a scan at %s." }
Data.reports[#Data.reports + 1] = function()
    if Relay.heard.at then Core.Print(SAY.heard:format(Relay.heard.items, Core.ClockAt(Relay.heard.at))) end
end
