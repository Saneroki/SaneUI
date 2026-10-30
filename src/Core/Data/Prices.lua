local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Prices
--  What a thing fetches at the auction house, for every view: the one place a price is read (Doc/guides/data.md,
--  *Prices*). A price comes from what the game told last: the auction house's own lists while you look at them
--  (browsing, an item's offers), newest of all, else the last full scan that saw the thing (Scan.lua), kept in
--  SaneUIData_Market. Prices are per auction house: while one is open its own, else the one of your side.
--  A price of one house is never read for another.
--
--      local Prices = SaneUI.Core.Data.Series("Prices")
--      Prices:Low(item)        the lowest price now, per unit, in copper; nil: none, or none for Prices.FRESH days
--      Prices:Last(item)       low, market, units, auctions, sellers, at: the newest point, however old; nil: none
--      Prices:Range(item, from, to)
--                              how its price went: { { at, low, market }, ... }, oldest first, from server time from to
--                              server time to (nil: from the first point, to now). One table used again: read it at once
--      Prices:Stamp()          a number that moves with every change of a price, for a view to know its picture is old
--      Prices:OnChange(fn)     fn() on the next frame after prices changed: a list of the game's, or a scan kept
--      Prices.Database(game, houses)   what all accounts hold together, from the addon SaneUI_AuctionDatabase, which a tool
--                              on this computer makes: read over this account's own where it is newer
--
--  item is an item's ID or its link. A link names its kind (gear by level and suffix, a pet by species); an ID, or a
--  link of a kind no scan saw, the cheapest of its kinds.
--
--  Each house's newest points stand in its saved string index, "key=at,low,market,units,auctions,sellers;...",
--  key being the game's own ItemKey: the item's ID, or "item:level:suffix:species" for gear and pets. It is taken
--  apart when a house is first asked about, written back with each scan and at the logout.
--
--  A range reads what is most current for each stretch of time, whichever holds it (History): the scans of today and
--  yesterday (recent), a point a scan; the database's days, which took this account's in with all the others'; this account's
--  own days it does not have; and last the item's newest point, which what the game lists right now moves on.
-------------------------------------------------------------------------------
local Data = Core.Data
local Plain, Ask = Core.Plain, Core.Ask
local Prices = {}

Prices.FRESH = 30  -- days a price counts without being seen again

local DAY = 86400
local HISTORIES = 64   -- items whose history stays taken apart, per house, then forgotten together
local CAGE = 82800 -- the one item every caged pet is listed as
local GEAR = { [2] = true, [4] = true, [17] = true } -- the game's item classes (Enum.ItemClass): weapons, armour, pets
local POINT = "%.0f,%.0f,%.0f,%.0f,%d,%d"            -- whole numbers, past what %d holds on every client
local SAVED = "([^=;]+)=(%d+,%d+,%d+,%d+,%d+,%d+);"
local FIELDS = "^(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)$"
local LOW_MARKET = "^(%d+),(%d+)"                    -- how a line of a day or a scan begins
local NONE = {}

local part             -- this game version's part of SaneUIData_Market
local mine, opened     -- the house of your side, once asked for; the one open now
local books = {}       -- [a house's part] = { index = { [key] = point }, gear = { [item] = { key, ... } }, dirty,
                       --                      history = { [key] = points }, held }
local keys = {}        -- [a house's part] = its key
local database         -- [a house's key] = { index, days }: what all accounts hold together, where a tool made that
local kinds = {}       -- [item] = whether the auction house tells its kinds apart
local listed = {}      -- [key] = the lowest price in the list on show
local listeners = {}
local stamp = 0        -- moves with every change of a price
local range, newest = {}, {} -- what Prices:Range hands out, used again

local function Now()
    return Ask(rawget(_G, "GetServerTime")) or 0
end

local TellSoon = Core.Later(function()
    for _, fn in ipairs(listeners) do Core.Safe("data: prices", fn) end
end)

-------------------------------------------------------------------------------
--  Houses and keys
-------------------------------------------------------------------------------
-- The part of the house of unit's side, by region, realm and side (Doc/ideas/Data.md, *Realms and regions*): the
-- player's, or the NPC's that opened one, neutral where it has none (the goblin towns'). One of a wrong shape goes
-- to broken, never wiped. Nil before Core's saved variables are read, or while the player's side is not told yet.
function Prices.House(unit)
    if not part then return nil end
    local side = Ask(rawget(_G, "UnitFactionGroup"), unit)
    if unit == "player" and type(side) ~= "string" then return nil end
    local key = ("%s/%s/%s"):format(tostring(Ask(rawget(_G, "GetCurrentRegionName")) or "?"):lower(),
        tostring(Ask(rawget(_G, "GetRealmID")) or 0), type(side) == "string" and side:lower() or "neutral")
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
    if type(known.whole) ~= "table" then known.whole = {} end
    if type(known.recent) ~= "table" then known.recent = {} end
    keys[known] = key
    return known
end

local function Current()
    if opened then return opened end
    mine = mine or Prices.House("player")
    return mine
end

local function Moved()
    stamp = stamp + 1
    TellSoon()
end

-- The house prices are read from while one is open (the auction house's own, by Scan.lua); nil: closed.
function Prices.Open(house)
    opened = house
    Moved()
end

-- Whether the auction house tells the item's kinds apart: true for gear and pets, false for all else, nil for
-- an item the game does not know.
function Prices.Gear(item)
    local kind = kinds[item]
    if kind == nil then
        local instant = C_Item.GetItemInfoInstant
        if not instant then return false end
        local _, _, _, _, _, class = instant(item)
        if class == nil then return nil end
        kind = GEAR[class] == true
        kinds[item] = kind
    end
    return kind
end

-- The key of an item of a kind, from its link; nil while the game does not know the item yet.
function Prices.LinkKey(link, item)
    local species = link:match("battlepet:(%d+)")
    if species then return ("%d:0:0:%s"):format(item, species) end
    local level = C_Item.GetDetailedItemLevelInfo(link)
    if type(level) ~= "number" then return nil end
    local suffix = link:match("item:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:(%-?%d*)")
    return ("%d:%d:%d:0"):format(item, level, tonumber(suffix) or 0)
end

-- The key of the game's own ItemKey, as its lists give it.
local function KeyOf(itemKey)
    itemKey = Plain(itemKey)
    local item = type(itemKey) == "table" and Plain(itemKey.itemID)
    if type(item) ~= "number" then return nil end
    if not Prices.Gear(item) then return tostring(item) end
    return ("%d:%d:%d:%d"):format(item, Plain(itemKey.itemLevel) or 0, Plain(itemKey.itemSuffix) or 0, Plain(itemKey.battlePetSpeciesID) or 0)
end

-------------------------------------------------------------------------------
--  The points
-------------------------------------------------------------------------------
local function Put(book, key, point)
    if book.index[key] == nil then
        local item = tonumber(key:match("^(%d+):"))
        if item then
            local list = book.gear[item] or {}
            book.gear[item] = list
            list[#list + 1] = key
        end
    end
    book.index[key] = point
end

local function Book(house)
    local book = books[house]
    if book then return book end
    book = { index = {}, gear = {}, history = {}, held = 0 }
    books[house] = book
    if type(house.index) == "string" then
        for key, point in house.index:gmatch(SAVED) do Put(book, key, point) end
    end
    local shared = database and database[keys[house]]
    if type(shared) == "table" and type(shared.index) == "string" then
        for key, point in shared.index:gmatch(SAVED) do
            local own = book.index[key]
            if not own or tonumber(point:match("^%d+")) > tonumber(own:match("^%d+")) then Put(book, key, point) end
        end
    end
    return book
end

-- A scan's point of an item (Scan.lua).
function Prices.Take(house, key, at, low, market, units, auctions, sellers)
    Put(Book(house), key, POINT:format(at, low, market, units, auctions, sellers))
end

-- The house's points written into its saved string.
function Prices.Save(house)
    local book, lines, count = Book(house), {}, 0
    for key, point in pairs(book.index) do
        count = count + 1
        lines[count] = key .. "=" .. point .. ";"
    end
    house.index, book.dirty = table.concat(lines), false
end

-- A scan was kept: the histories taken apart are old.
function Prices.Changed()
    for _, book in pairs(books) do book.history, book.held = {}, 0 end
    Moved()
end

local function Fields(point)
    local at, low, market, units, auctions, sellers = point:match(FIELDS)
    return tonumber(low), tonumber(market), tonumber(units), tonumber(auctions), tonumber(sellers), tonumber(at)
end

-- What the game lists right now, the newest of all: the lowest price, and how many are on offer where it says.
-- The rest of the point stays the last scan's. No price: the point is forgotten (the tests' way back).
function Prices.See(key, low, units)
    local house = Current()
    if not house then return end
    local book = Book(house)
    if low == nil then
        book.index[key] = nil
    else
        local market, was, auctions, sellers
        if book.index[key] then
            local _
            _, market, was, auctions, sellers = Fields(book.index[key])
        end
        Put(book, key, POINT:format(Now(), low, market or 0, units or was or 0, auctions or 0, sellers or 0))
    end
    book.dirty = true
    Moved()
end

-- The point of an item and its key: its link's kind where a scan saw that, else plain, else the cheapest of its kinds.
local function Point(book, item)
    local id = item
    if type(item) == "string" then
        id = tonumber(item:match("item:(%d+)")) or (item:find("battlepet:", 1, true) and CAGE) or nil
        if id and book.gear[id] then
            local key = Prices.LinkKey(item, id)
            if key and book.index[key] then return book.index[key], key end
        end
    end
    if type(id) ~= "number" then return nil end
    local plain = book.index[tostring(id)]
    if plain then return plain, tostring(id) end
    local best, bestKey, lowest
    for _, key in ipairs(book.gear[id] or NONE) do
        local point = book.index[key]
        local low = point and tonumber(point:match("^%d+,(%d+)"))
        if low and low > 0 and (not lowest or low < lowest) then best, bestKey, lowest = point, key, low end
    end
    return best, bestKey
end

function Prices:Last(item)
    local house = Current()
    local point = house and item and Point(Book(house), item)
    if point then return Fields(point) end
    return nil
end

function Prices:Low(item)
    local low, _, _, _, _, at = self:Last(item)
    if low and low > 0 and Now() - at <= Prices.FRESH * DAY then return low end
    return nil
end

function Prices:Stamp()
    return stamp
end

function Prices:OnChange(fn)
    listeners[#listeners + 1] = fn
end

-------------------------------------------------------------------------------
--  The history
-------------------------------------------------------------------------------
-- The low and market price a saved string of "key=low,market...;" lines has for key; nil where it has no line of it.
local function Entry(text, key)
    if type(text) ~= "string" then return nil end
    local _, stop = text:find(";" .. key .. "=", 1, true)
    if not stop and text:sub(1, #key + 1) == key .. "=" then stop = #key + 1 end
    if not stop then return nil end
    local low, market = text:match(LOW_MARKET, stop + 1)
    return tonumber(low), tonumber(market)
end

local function Earlier(a, b)
    return a.at < b.at
end

-- Every point kept of a key, oldest first, taken apart once: a scan's under the time it came, a day's in the middle of that
-- day. What stands for a day is the most current that holds it: its scans, this account's and the database's; else the
-- database's line, which took this account's in with all the others'; else this account's own. Held until a scan is kept:
-- what the game lists meanwhile moves only the newest point (Range).
local function History(house, book, key)
    local points = book.history[key]
    if points then return points end
    points = {}
    local count, days = 0, {}
    local shared = database and database[keys[house]]
    shared = type(shared) == "table" and shared or NONE
    local function Scans(list)
        for at, text in pairs(type(list) == "table" and list or NONE) do
            local low, market = Entry(text, key)
            if low then
                count = count + 1
                points[count] = { at = at, low = low, market = market }
                days[math.floor(at / DAY)] = true
            end
        end
    end
    local function Days(list)
        for day, text in pairs(type(list) == "table" and list or NONE) do
            local low, market = Entry(text, key)
            if low and not days[day] then
                count = count + 1
                points[count] = { at = (day + 0.5) * DAY, low = low, market = market }
                days[day] = true
            end
        end
    end
    Scans(house.recent)
    Scans(shared.recent)
    Days(shared.days)
    Days(house.days)
    table.sort(points, Earlier)
    if book.held >= HISTORIES then book.history, book.held = {}, 0 end
    book.history[key], book.held = points, book.held + 1
    return points
end

function Prices:Range(item, from, to)
    wipe(range)
    local house = Current()
    local book = house and item and Book(house)
    local point, key
    if book then point, key = Point(book, item) end
    if not key then return range end
    to = to or Now()
    local count, last = 0, 0
    for _, each in ipairs(History(house, book, key)) do
        if each.at > to then break end
        if not from or each.at >= from then
            count = count + 1
            range[count] = each
        end
        last = each.at
    end
    local low, market, _, _, _, at = Fields(point)
    if at > last and at <= to and (not from or at >= from) then
        newest.at, newest.low, newest.market = at, low, market
        range[count + 1] = newest
    end
    return range
end

-- Called by the file of the addon SaneUI_AuctionDatabase as the game reads it; another game's is not taken.
function Prices.Database(game, houses)
    if game == Data.Game() and type(houses) == "table" then database = houses end
end

function Data.Series(name)
    return name == "Prices" and Prices or nil
end

-------------------------------------------------------------------------------
--  What the game lists
-------------------------------------------------------------------------------
-- A row of a list: the lowest of the list on show is the price of each kind.
local function Listed(key, price, units)
    if key and type(price) == "number" and price > 0 and not (listed[key] and listed[key] <= price) then
        listed[key] = price
        Prices.See(key, price, type(units) == "number" and units or nil)
    end
end

-- The list of what you browse. anew: a new list, a new search.
local function Browsed(results, anew)
    if anew then wipe(listed) end
    if type(results) ~= "table" then return end
    for _, result in ipairs(results) do
        result = Plain(result)
        if type(result) == "table" then Listed(KeyOf(result.itemKey), Plain(result.minPrice), Plain(result.totalQuantity)) end
    end
end

-- All the offers of a thing sold by the unit: the cheapest of them.
local function Commodity(item)
    local auctions = rawget(_G, "C_AuctionHouse")
    item = Plain(item)
    local count = auctions and Ask(auctions.GetNumCommoditySearchResults, item)
    local lowest
    for index = 1, type(count) == "number" and count or 0 do
        local offer = Plain(Ask(auctions.GetCommoditySearchResultInfo, item, index))
        local price = type(offer) == "table" and Plain(offer.unitPrice)
        if type(price) == "number" and price > 0 and (not lowest or price < lowest) then lowest = price end
    end
    if lowest then
        listed[tostring(item)] = nil
        Listed(tostring(item), lowest, Plain(Ask(auctions.GetCommoditySearchResultsQuantity, item)))
    end
end

-- All the offers of an item sold one by one, or a stack at a time: the cheapest of them, per unit.
local function Offers(itemKey)
    local auctions = rawget(_G, "C_AuctionHouse")
    local key = KeyOf(itemKey)
    local count = key and auctions and Ask(auctions.GetNumItemSearchResults, itemKey)
    local lowest
    for index = 1, type(count) == "number" and count or 0 do
        local offer = Plain(Ask(auctions.GetItemSearchResultInfo, itemKey, index))
        local buyout = type(offer) == "table" and Plain(offer.buyoutAmount)
        local quantity = type(offer) == "table" and Plain(offer.quantity)
        if type(buyout) == "number" and buyout > 0 and type(quantity) == "number" and quantity > 0 then
            local price = math.ceil(buyout / quantity)
            if not lowest or price < lowest then lowest = price end
        end
    end
    if lowest then
        listed[key] = nil
        Listed(key, lowest, Plain(Ask(auctions.GetItemSearchResultsQuantity, itemKey)))
    end
end

Core.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function()
    local auctions = rawget(_G, "C_AuctionHouse")
    if auctions then Browsed(Ask(auctions.GetBrowseResults), true) end
end)
Core.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function(added) Browsed(added, false) end)
Core.On("COMMODITY_SEARCH_RESULTS_UPDATED", Commodity)
Core.On("ITEM_SEARCH_RESULTS_UPDATED", Offers)

-- What the game listed since the last scan stays for the next login.
Core.On("PLAYER_LOGOUT", function()
    for house, book in pairs(books) do
        if book.dirty then Prices.Save(house) end
    end
end)

Data.Saved("Market", function(saved) part = saved end)
