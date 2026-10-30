local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Scan
--  The full scan of the auction house (Doc/ideas/Economy.md, *The full scan*). While the auction house is
--  open the whole house is asked for by itself, at once and then every Scan.INTERVAL seconds, and what it
--  lists goes into the history in the saved variable SaneUIData_Market, which the game writes into its WTF
--  folder at every logout and /reload. The game's request needs no click, so all of it runs with the
--  game in the background, as long as the auction house stays open. The server allows one scan in 15
--  minutes and says nothing when it refuses, so the time is noted at its answer, never at the request. A
--  scan another addon asked for is read the same: the game tells every addon.
--
--  The history, per auction house (part.houses["eu/1234/horde"]), one string per server day, so a saved file
--  holds a few values a day however many items a house has (Doc/guides/data.md, *Saved variables*):
--
--      days[day]  = "key=low,market,units,auctions,sellers;..."
--      scans[day] = how many scans that day's string holds
--      at         = when the server last answered; kept, rows, items, left = the last scan kept:
--                   when, its auctions, its items, the rows left out (gear the game did not know in time)
--
--  key is the game's own ItemKey: the item's ID, or "item:level:suffix:species" for gear and pets. Prices
--  are per unit in copper: low is the lowest of the day, market the median of the units on offer, and
--  everything but low comes from the last scan of the day that saw the item. 0: no buyout. Names stay out:
--  sellers is a count.
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

local JOB = "Full auction scan"
local ROWS = 64         -- rows read between two looks at the frame's time
local SAME = 14 * 60    -- the game tells again as item data comes in: this soon and as many rows, it is the same scan
local UNITS = 65536     -- a row as one number, price * UNITS + count: sorted with no table per row
local GEAR = { [2] = true, [4] = true, [17] = true } -- the game's item classes (Enum.ItemClass): weapons, armour, pets

local SAY = { house = "auction house %s: %d days, last scan %s, %d auctions of %d items." }

local state = { phase = "closed", read = 0, rows = 0, next = 0, span = 0 }
local listeners = {}
local part            -- this game version's part of SaneUIData_Market
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

-- The auction house open now, by region, realm and side: the side of the NPC that opened it, neutral for
-- one of the goblin towns' (Doc/ideas/Data.md, *Realms and regions*).
local function HouseKey()
    local unit = Core.Ask(rawget(_G, "UnitExists"), "npc") and "npc" or "player"
    local side = Core.Ask(rawget(_G, "UnitFactionGroup"), unit)
    return ("%s/%s/%s"):format(tostring(Core.Ask(rawget(_G, "GetCurrentRegionName")) or "?"):lower(),
        tostring(Core.Ask(rawget(_G, "GetRealmID")) or 0), type(side) == "string" and side:lower() or "neutral")
end

-- A house's part; one of a wrong shape goes to broken, never wiped.
local function House(key)
    if type(part.houses) ~= "table" then part.houses = {} end
    local known = part.houses[key]
    if type(known) ~= "table" or type(known.days) ~= "table" or type(known.scans) ~= "table" then
        if known ~= nil then
            part.broken = type(part.broken) == "table" and part.broken or {}
            part.broken[#part.broken + 1] = known
        end
        known = { days = {}, scans = {} }
        part.houses[key] = known
    end
    return known
end

local function Remember(known)
    state.kept, state.total, state.items = known.kept, known.rows, known.items
end

-------------------------------------------------------------------------------
--  Reading the rows
-------------------------------------------------------------------------------
-- The key of a row of gear or a pet, from its link; nil while the game does not know the item yet.
local function GearKey(index, item)
    local link = C_AuctionHouse.GetReplicateItemLink(index)
    if type(link) ~= "string" then return nil end
    local species = link:match("battlepet:(%d+)")
    if species then return ("%d:0:0:%s"):format(item, species) end
    local level = C_Item.GetDetailedItemLevelInfo(link)
    if type(level) ~= "number" then return nil end
    local suffix = link:match("item:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:(%-?%d*)")
    return ("%d:%d:%d:0"):format(item, level, tonumber(suffix) or 0)
end

-- Plain, gear, or false for an item the game does not know at all (left out), asked of the game once a scan.
local function Kind(scan, item)
    local kind = scan.kinds[item]
    if kind == nil then
        local _, _, _, _, _, class = C_Item.GetItemInfoInstant(item)
        kind = class ~= nil and (GEAR[class] and "gear" or "plain")
        scan.kinds[item] = kind
    end
    return kind
end

local function Count(scan, key, count, buyout, owner)
    local entry = scan.found[key]
    if not entry then
        entry = { units = 0, auctions = 0, sellers = 0, owners = {}, prices = {} }
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
end

-- One row into the scan; false when the list is gone (the auction house closed).
local function Row(scan, index)
    local _, _, count, _, _, _, _, _, _, buyout, _, _, _, owner, _, _, item = C_AuctionHouse.GetReplicateItemInfo(index)
    if type(item) ~= "number" then return false end
    if type(count) ~= "number" or count <= 0 then return true end
    local kind, key = Kind(scan, item), item
    if not kind then return true end
    if kind == "gear" then
        key = GearKey(index, item)
        if not key then
            scan.later[#scan.later + 1] = index
            if not scan.asked[item] then scan.wanted[item] = true end
            return true
        end
    end
    Count(scan, tostring(key), count, type(buyout) == "number" and buyout or 0, owner)
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

-- An item's line of the day's string.
local function Line(key, entry)
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
    local earlier = entry.earlier
    if earlier and earlier > 0 and (low == 0 or earlier < low) then low = earlier end
    return ("%s=%d,%d,%d,%d,%d;"):format(key, low, market, entry.units, entry.auctions, entry.sellers)
end

-- Kept in one go at the end: the day's string made anew, what this scan saw in place of its lines, the
-- items only an earlier scan of the day saw as they were.
local function Keep(scan, home, day, now)
    local lines, items = {}, 0
    local before = home.days[day]
    if type(before) == "string" then
        for line, key, low in before:gmatch("(([^=;]+)=(%d+),[^;]*;)") do
            local entry = scan.found[key]
            if entry then entry.earlier = tonumber(low) else lines[#lines + 1] = line end
            Steps.Check()
        end
    end
    for key, entry in pairs(scan.found) do
        lines[#lines + 1] = Line(key, entry)
        items = items + 1
        Steps.Check()
    end
    Steps.Fresh() -- the one step that cannot be cut: alone in its frame
    home.days[day] = table.concat(lines)
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
    local scan = { found = {}, kinds = {}, later = {}, wanted = {}, asked = {} }
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
    open, openedAt, house = true, now, House(HouseKey())
    Remember(house)
    state.outcome = house.kept and "kept" or nil
    state.next, state.span = math.max((tonumber(house.at) or 0) + Scan.INTERVAL, now), Scan.INTERVAL
    Phase(Steps.Running(JOB) and "reading" or "waiting")
    TickSoon()
end

local function Closed()
    open = false
    Phase("closed")
end

Core.On("AUCTION_HOUSE_SHOW", Opened)
Core.On("AUCTION_HOUSE_CLOSED", Closed)
Core.On("REPLICATE_ITEM_LIST_UPDATE", Answered)

Data.Saved("Market", function(saved) part = saved end)

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
    for key in pairs(part.houses) do
        local known, days = House(key), 0
        for _ in pairs(known.days) do days = days + 1 end
        local when = known.kept and date("%Y-%m-%d ", known.kept) .. Core.ClockAt(known.kept) or "none"
        Core.Print(SAY.house:format(key, days, when, known.rows or 0, known.items or 0))
    end
end
