local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Scan
--  The full scan of the auction house (Doc/ideas/Economy.md, *The full scan*). While the auction house is
--  open the whole house is asked for by itself, at once and then every Scan.INTERVAL seconds, and what it
--  lists goes into the history in the saved variable SaneUIData_Market, in a file of its own apart from the
--  settings (the addon SaneUI_AuctionData), which the game writes into its WTF folder at every logout and /reload.
--  The game's request needs no click, so all of it runs with the
--  game in the background, as long as the auction house stays open. The server allows one scan in 15
--  minutes and says nothing when it refuses, so the time is noted at its answer, never at the request. A
--  scan another addon asked for is read the same: the game tells every addon.
--
--  The history, per auction house (part.houses["eu/1234/horde"]), as few values as a saved file can hold it
--  (Doc/guides/data.md, *Saved variables*). Every scan whole has a file of its own, the addon SaneUI_AuctionScans, which
--  this account loads when the auction house opens, as every account reads the rest at each login:
--
--      whole[at]  = (SaneUIData_Scans, part.houses[house]) every row of the scan the server answered at that time, as
--                   the game gave it (Scan.WHOLE, Forever's; what goes on into the database is filtered there):
--                   "<build>\n<block>\n<block>...",
--                   a block being Scan.BLOCK rows packed by the game (zlib, Base64), a row
--                   "key,count,buyout,minBid,increment,bid,timeLeft,status,seller,bidder,link" (link: gear's,
--                   the game's item string). The sellers' and bidders' names are the only ones kept: local,
--                   never for the database (Doc/guides/data.md, *The full auction scan*).
--      days[day]  = "key=low,market,units,auctions,sellers;..."
--      recent[at] = "key=low,market;...", each scan of today and yesterday (Scan.RECENT, Forever's), its own lowest:
--                   what a graph of a day reads, as a scan kept whole is too much to open for a tooltip
--      scans[day] = how many scans that day's string holds
--      index      = each item's newest point, for Prices.lua
--      at         = when the server last answered; kept, rows, items, left = the last scan kept:
--                   when, its auctions, its items, the rows left out (gear the game did not know in time)
--
--  key is the game's own ItemKey: the item's ID, or "item:level:suffix:species" for gear and pets. Prices
--  are per unit in copper: low is the lowest of the day, market the median of the units on offer, and
--  everything but low comes from the last scan of the day that saw the item. 0: no buyout.
--
--      Core.Data.Scan.State()      what a view shows: { phase, outcome, read, rows, next, span, kept, total, items }
--                                  phase: closed, waiting, asking or reading; outcome: how the last try ended,
--                                  kept, refused or lost; read of rows while reading; next: the server time of
--                                  the next request, span: the seconds that wait was; kept, total, items: the
--                                  last scan kept
--      Core.Data.Scan.OnChange(fn) fn(state) at every change, and twice a second while the house is open
--      Core.Data.Scan.Start()      a scan now, whatever the time says (the bar, pressed); false while one runs
-------------------------------------------------------------------------------
local Data, Steps = Core.Data, Core.Steps
local Scan = {}
Data.Scan = Scan

Scan.INTERVAL = 16 * 60 -- seconds from one answer to the next request: the server's 15 minutes and one to spare
Scan.ANSWER = 90        -- seconds the server has to answer; after them it refused
Scan.RETRY = 3 * 60     -- seconds to the next request after a refusal: it says neither why nor until when
Scan.SETTLE = 2         -- seconds the window gets for its own first searches
Scan.TICK = 0.5         -- seconds between two looks, only while the house is open
Scan.ITEMS = 30         -- seconds gear and pets may wait for the game to know them
Scan.ASKS = 20          -- items asked of the server in one round of that wait
Scan.KEEP = { retail = 7 } -- days kept per game: Retail's house is far bigger and its data's plan is still to come
Scan.WHOLE = { forever = true } -- the games whose scans are kept row by row, each one
Scan.RECENT = { forever = true } -- the games whose scans of today and yesterday are kept as a line per item, for a day's graph
Scan.BLOCK = 1024       -- rows packed at a time: a few milliseconds, within a frame's budget

local JOB = "Full auction scan"
local ROWS = 64         -- rows read between two looks at the frame's time
local SAME = 14 * 60    -- the game tells again as item data comes in: this soon and as many rows, it is the same scan
local UNITS = 65536     -- a row as one number, price * UNITS + count: sorted with no table per row
local RAW = "%s,%d,%.0f,%.0f,%.0f,%.0f,%d,%d,%s,%s,%s" -- a row kept whole; whole numbers past what %d holds on every client
local DAILY = "%s=%.0f,%.0f,%.0f,%d,%d;"               -- an item's line of a day
local RECENT = "%s=%.0f,%.0f;"                         -- an item's line of one scan

local SAY = { house = "auction house %s: %d days, %d whole scans (%.1f MB), last scan %s, %d auctions of %d items." }
local Prices = Data.Series("Prices")

local state = { phase = "closed", read = 0, rows = 0, next = 0, span = 0 }
local listeners = {}
local part            -- this game version's part of SaneUIData_Market
local scans           -- this game version's part of SaneUIData_Scans, once its addon is loaded
local house           -- the part of the auction house that is open
local open = false
local openedAt, askedAt, finished = 0, 0, false

local function Now()
    return Core.Ask(rawget(_G, "GetServerTime")) or 0
end

local function Changed()
    for _, fn in ipairs(listeners) do Core.Safe("data: auction scan", fn, state) end
end

local function Phase(phase)
    state.phase = open and phase or "closed"
    Changed()
end

local function Wait(now, seconds)
    state.next, state.span = now + seconds, seconds
end

local function Remember(known)
    state.kept, state.total, state.items = known.kept, known.rows, known.items
end

-------------------------------------------------------------------------------
--  Reading the rows
-------------------------------------------------------------------------------
local function Count(scan, key, count, buyout, owner)
    local entry = scan.found[key]
    if not entry then
        entry = { units = 0, auctions = 0, sellers = 0, owners = {}, prices = {}, rows = {} }
        scan.found[key] = entry
    end
    entry.units, entry.auctions = entry.units + count, entry.auctions + 1
    if owner and not entry.owners[owner] then
        entry.owners[owner], entry.sellers = true, entry.sellers + 1
    end
    -- A row with no buyout (bid only) counts for the auctions and units, not for the prices.
    if buyout > 0 then
        entry.prices[#entry.prices + 1] = math.ceil(buyout / count) * UNITS + math.min(count, UNITS - 1)
    end
    return entry
end

-- One row into the scan; false when the list is gone (the auction house closed).
local function Row(scan, index)
    local auctions = C_AuctionHouse
    local _, _, count, _, _, _, _, minBid, increment, buyout, bid, bidder, bidderFull, owner, ownerFull, status, item =
        auctions.GetReplicateItemInfo(index)
    if type(item) ~= "number" then return false end
    if type(count) ~= "number" or count <= 0 then return true end
    local gear = Prices.Gear(item)
    if gear == nil then return true end
    local key, link = tostring(item), nil
    if gear then
        link = auctions.GetReplicateItemLink(index)
        key = type(link) == "string" and Prices.LinkKey(link, item) or nil
        if not key then
            scan.later[#scan.later + 1] = index
            if not scan.asked[item] then scan.wanted[item] = true end
            return true
        end
    end
    owner = ownerFull or owner
    local entry = Count(scan, key, count, type(buyout) == "number" and buyout or 0, owner)
    if scan.whole then
        entry.rows[#entry.rows + 1] = RAW:format(key, count, tonumber(buyout) or 0, tonumber(minBid) or 0, tonumber(increment) or 0,
            tonumber(bid) or 0, auctions.GetReplicateItemTimeLeft(index) or 0, tonumber(status) or 0, owner or "",
            bidderFull or bidder or "", link and link:match("|H(.-)|h") or "")
    end
    return true
end

-- Gear and pets the game did not know: asked of the server a few at a time, the rows read again each
-- round, for Scan.ITEMS seconds. What it still does not know then is left out, never keyed wrongly.
local function Later(scan)
    local deadline = GetTime() + Scan.ITEMS
    while #scan.later > 0 and GetTime() < deadline do
        local asks = 0
        for item in pairs(scan.wanted) do
            if asks >= Scan.ASKS then break end
            asks = asks + 1
            scan.wanted[item], scan.asked[item] = nil, true
            C_Item.RequestLoadItemDataByID(item)
        end
        Steps.Spend() -- the game gets a frame to take the answers in
        local rows = scan.later
        scan.later = {}
        for _, index in ipairs(rows) do
            if not Row(scan, index) then return false end
            Steps.Check()
        end
    end
    return true
end

-- This scan's lowest and market price of an item, and its line of the day's string.
local function Point(key, entry)
    local prices, low, market = entry.prices, 0, 0
    if #prices > 0 then
        table.sort(prices)
        low = math.floor(prices[1] / UNITS)
        local units = 0
        for _, each in ipairs(prices) do units = units + each % UNITS end
        local seen = 0
        for _, each in ipairs(prices) do
            seen = seen + each % UNITS
            if seen * 2 >= units then
                market = math.floor(each / UNITS)
                break
            end
        end
    end
    local earlier, lowest = entry.earlier, low
    if earlier and earlier > 0 and (low == 0 or earlier < low) then lowest = earlier end
    return low, market, DAILY:format(key, lowest, market, entry.units, entry.auctions, entry.sellers)
end

-- Every row of the scan, packed a block at a time, grouped by item: nil where the game cannot pack.
local function Whole(scan, now)
    local util = rawget(_G, "C_EncodingUtil")
    if not (util and util.CompressString and util.EncodeBase64) then return nil end
    local method = Enum and Enum.CompressionMethod and Enum.CompressionMethod.Zlib or 1
    local _, build = Core.Ask(rawget(_G, "GetBuildInfo"))
    local blocks, rows, count = { tostring(build or 0) }, {}, 0
    local function Pack()
        local packed = Core.Ask(util.CompressString, table.concat(rows, "\n", 1, count), method)
        local text = packed and Core.Ask(util.EncodeBase64, packed)
        if not text then return false end
        blocks[#blocks + 1], count = text, 0
        Steps.Check()
        return true
    end
    for _, entry in pairs(scan.found) do
        for _, row in ipairs(entry.rows) do
            count = count + 1
            rows[count] = row
            if count == Scan.BLOCK and not Pack() then return nil end
        end
    end
    if count > 0 and not Pack() then return nil end
    return table.concat(blocks, "\n")
end

-- Kept in one go at the end: the day's string made anew, what this scan saw in place of its lines, the
-- items only an earlier scan of the day saw as they were; each item's newest point; the scan whole.
local function Keep(scan, home, day, now)
    local lines, items = {}, 0
    local recent = Core.ForGame(Scan.RECENT) and {} or nil
    local before = home.days[day]
    if type(before) == "string" then
        for line, key, low in before:gmatch("(([^=;]+)=(%d+),[^;]*;)") do
            local entry = scan.found[key]
            if entry then entry.earlier = tonumber(low) else lines[#lines + 1] = line end
            Steps.Check()
        end
    end
    for key, entry in pairs(scan.found) do
        local low, market, line = Point(key, entry)
        lines[#lines + 1] = line
        if recent then recent[#recent + 1] = RECENT:format(key, low, market) end
        items = items + 1
        Prices.Take(home, key, now, low, market, entry.units, entry.auctions, entry.sellers)
        Steps.Check()
    end
    local whole = scan.whole and Whole(scan, now)
    if scan.whole and not whole then Core.NoteError("data: auction scan", "a whole scan could not be packed") end
    Steps.Fresh() -- the steps that cannot be cut: alone in their frames
    home.days[day] = table.concat(lines)
    Steps.Spend()
    Steps.Fresh()
    if recent then
        home.recent[now] = table.concat(recent)
        for old in pairs(home.recent) do
            if math.floor(old / 86400) < day - 1 then home.recent[old] = nil end
        end
        Steps.Spend()
        Steps.Fresh()
    end
    Prices.Save(home)
    if whole then
        scans.houses = type(scans.houses) == "table" and scans.houses or {}
        local key = Prices.Key(home)
        scans.houses[key] = type(scans.houses[key]) == "table" and scans.houses[key] or {}
        scans.houses[key][now] = whole
    end
    Prices.Changed()
    Steps.Spend()
    home.scans[day] = (tonumber(home.scans[day]) or 0) + 1
    home.kept, home.rows, home.items, home.left = now, state.rows, items, #scan.later
    local keep = Core.ForGame(Scan.KEEP)
    if keep then
        for old in pairs(home.days) do
            if old <= day - keep then home.days[old], home.scans[old] = nil, nil end
        end
    end
    Remember(home)
    finished = true
end

-- The job: every row, read in steps. Nothing is kept of a scan the game took away halfway.
local function Read(home, day, now)
    local scan = { found = {}, later = {}, wanted = {}, asked = {}, whole = Core.ForGame(Scan.WHOLE) and scans ~= nil }
    local index = 0
    while index < state.rows do
        if not Row(scan, index) then return end
        index = index + 1
        if index % ROWS == 0 then
            state.read = index
            Steps.Check()
            local rows = C_AuctionHouse.GetNumReplicateItems()
            if rows < index then return end
            state.rows = rows
        end
    end
    state.read = index
    if Later(scan) then Keep(scan, home, day, now) end
end

local function Done()
    state.outcome = finished and "kept" or "lost"
    Phase("waiting")
end

-------------------------------------------------------------------------------
--  The request and the answer
-------------------------------------------------------------------------------
local function Answered()
    if not open or Steps.Running(JOB) then return end
    local now, rows = Now(), C_AuctionHouse.GetNumReplicateItems()
    if rows <= 0 then return end
    if rows == house.rows and now - (tonumber(house.at) or 0) < SAME then return end
    house.at = now
    state.read, state.rows, state.outcome = 0, rows, nil
    finished = false
    Wait(now, Scan.INTERVAL)
    Phase("reading")
    Steps.Run({ name = JOB, priority = true, label = "data: auction scan", done = Done }, Read, house, math.floor(now / 86400), now)
end

local TickSoon

local function Tick()
    if not open then return end
    TickSoon()
    local now = Now()
    if state.phase == "waiting" then
        if now >= state.next and now >= openedAt + Scan.SETTLE and C_AuctionHouse.IsThrottledMessageSystemReady() then
            askedAt, state.outcome = now, nil
            Phase("asking")
            C_AuctionHouse.ReplicateItems()
        end
    elseif state.phase == "asking" and now >= askedAt + Scan.ANSWER then
        -- A press inside the server's 15 minutes changes nothing: the wait goes on where it was.
        state.outcome = "refused"
        Wait(now, math.max(Scan.RETRY, (tonumber(house.at) or 0) + Scan.INTERVAL - now))
        Phase("waiting")
    end
    Changed()
end
TickSoon = Core.Later(Tick, Scan.TICK)

local function Opened()
    local auctions = rawget(_G, "C_AuctionHouse")
    if open or not part or not (auctions and auctions.ReplicateItems) then return end
    local now = Now()
    house = Prices.House(Core.Ask(rawget(_G, "UnitExists"), "npc") and "npc" or "player")
    if not house then return end
    open, openedAt = true, now
    if Core.ForGame(Scan.WHOLE) and not scans then
        local addons = rawget(_G, "C_AddOns")
        Core.Ask(addons and addons.LoadAddOn, "SaneUI_AuctionScans") -- its file read now: a moment that grows with it
    end
    Prices.Open(house)
    Remember(house)
    state.outcome = house.kept and "kept" or nil
    state.next, state.span = math.max((tonumber(house.at) or 0) + Scan.INTERVAL, now), Scan.INTERVAL
    Phase(Steps.Running(JOB) and "reading" or "waiting")
    TickSoon()
end

local function Closed()
    open = false
    Prices.Open(nil)
    Phase("closed")
end

Core.On("AUCTION_HOUSE_SHOW", Opened)
Core.On("AUCTION_HOUSE_CLOSED", Closed)
Core.On("REPLICATE_ITEM_LIST_UPDATE", Answered)

Data.Saved("Market", function(saved) part = saved end)
Data.Saved("Scans", function(saved) scans = saved end)

function Scan.State()
    return state
end

function Scan.OnChange(fn)
    listeners[#listeners + 1] = fn
end

-- The next look asks, whatever the time says. The server still decides: inside its 15 minutes it stays silent,
-- and that is told as any refusal.
function Scan.Start()
    if state.phase ~= "waiting" then return false end
    state.next = Now()
    Tick()
    return true
end

-- /sane data: what the history holds, per auction house.
Data.reports[#Data.reports + 1] = function()
    if not (part and type(part.houses) == "table") then return end
    for key, known in pairs(part.houses) do
        local days, wholes, bytes = 0, 0, 0
        for _ in pairs(type(known) == "table" and type(known.days) == "table" and known.days or {}) do days = days + 1 end
        local whole = scans and type(scans.houses) == "table" and scans.houses[key]
        for _, text in pairs(type(whole) == "table" and whole or {}) do
            wholes, bytes = wholes + 1, bytes + #text
        end
        local kept = type(known) == "table" and known.kept
        local when = kept and date("%Y-%m-%d ", kept) .. Core.ClockAt(kept) or "none"
        Core.Print(SAY.house:format(key, days, wholes, bytes / 1048576, when,
            type(known) == "table" and known.rows or 0, type(known) == "table" and known.items or 0))
    end
end
