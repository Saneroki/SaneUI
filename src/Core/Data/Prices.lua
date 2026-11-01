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
--      Prices:Outlook(item)    what the scans tell of its price ahead and of how it sells, for a view to say when to buy and sell:
--                              Rhythm.lua's table, nil before a scan took a sample of it. Read it at once, keep nothing of it
--      Prices:Under(item, price)  how many are on offer at that price or less, by the last scan or the game's list of the item's
--                              offers; nil while neither was seen in this session
--      Prices:Usual(key)       what an item usually costs, a look at its rhythm's line alone; nil: no line
--      Prices:Scanned()        the keys of the house's last scan, a new table: { key, ... }, for a view that looks through them
--      Prices:OnSale()         money, auctions, at: what this player's characters had on sale at the last full scan of this house
--                              and of the other kind (Prices.Other), all accounts' that link their files (Doc/guides/data.md,
--                              *Across accounts*); nil before such a scan
--      Prices.Other()          the house of the other kind a character of yours can reach: the neutral one from your side's, your
--                              side's from the neutral one. Nil: nobody of yours has seen it
--      Prices.Within(house, fn, ...)  fn(...) with everything of Prices reading that house, for what weighs two houses against each
--                              other; it must not wait for a frame in there
--      Prices:Stamp()          a number that moves with every change of a price, for a view to know its picture is old
--      Prices:OnChange(fn)     fn() on the next frame after prices changed: a list of the game's, or a scan kept
--      Prices.Account()        takes in what another account's file left in the global: the addon
--                              SaneUI_AuctionDatabase is links to every account's file (Doc/guides/data.md, *Across
--                              accounts*), read over this account's own points where they are newer
--      Prices.Heard(house, at, text, sender, channel)   what a guild or group member's scan found, told by Relay.lua: kept apart
--                              as that sender's, it fills in only where this account's point is older, and a price five
--                              times off waits for a second sender
--      Prices.Forget(sender)   what members sent taken out again: one sender's, or none named: everybody's
--
--  item is an item's ID, its link or its key. A link names its kind (gear by level and suffix, a pet by species); an ID, or a
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
local Rhythm = Data.Rhythm
local Plain, Ask = Core.Plain, Core.Ask
local Prices = {}

Prices.FRESH = 30  -- days a price counts without being seen again
Prices.DOUBTS = 200 -- far-off prices in one member's scan before it counts as false
Prices.KEYS = 8000 -- keys of one house standing as one member's at most: a house's items and gear kinds, with room
local TRUST = 5    -- how far off a member's price may stand from what is known before a second sender must say it too
local PRICE_MOST, COUNT_MOST, ITEM_MOST = 1e11, 1e7, 2147483647 -- past these no number in a member's block is true
local LEVEL_MOST, SUFFIX_MOST, SPECIES_MOST = 9999, 99999, 99999 -- a kind's level, suffix and species past these is none the game makes
Prices.UNITS = 65536 -- an offer as one number, price * UNITS + count: sorted with no table per offer
local UNITS = Prices.UNITS

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
                       --                      history = { [key] = points }, held, outlook = { [key] = what Rhythm read }, offers = { [key] = offers },
                       --                      shared = { [key] = sender }, under = { [key] = the point it stands over },
                       --                      heard = { [sender] = how many keys stand as its (Prices.KEYS) },
                       --                      told = { [at] = true: a scan's line of a member's } }
local keys = {}        -- [a house's part] = its key
local database         -- [a house's key] = { index, days, recent, kept }: what all accounts hold together, through the links
local ours = {}        -- [a character's key] = true: the characters of this player's accounts, through the same links
local doubted = {}     -- [key] = { sender, low, guild }: a shared price far from what is known, until a second sender says so
local doubts = {}      -- [sender] = { at, far }: the far-off prices of that member's last scan
local kinds = {}       -- [item] = whether the auction house tells its kinds apart
local listed = {}      -- [key] = the lowest price in the list on show
local listeners = {}
local stamp = 0        -- moves with every change of a price
local reading          -- the house read for a moment instead (Prices.Within)
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
-- A house's part by its key, made where there is none yet. One of a wrong shape goes to broken, never wiped.
local function Part(key)
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
    if type(known.rhythm) ~= "table" then known.rhythm = {} end
    keys[known] = key
    return known
end

-- The part of the house of unit's side, by region, realm and side (Doc/ideas/Data.md, *Realms and regions*): the
-- player's, or the NPC's that opened one, neutral where it has none (the goblin towns'). Nil before Core's saved
-- variables are read, or while the player's side is not told yet.
function Prices.House(unit)
    if not part then return nil end
    local side = Ask(rawget(_G, "UnitFactionGroup"), unit)
    if unit == "player" and type(side) ~= "string" then return nil end
    return Part(("%s/%s/%s"):format(tostring(Ask(rawget(_G, "GetCurrentRegionName")) or "?"):lower(),
        tostring(Ask(rawget(_G, "GetRealmID")) or 0), type(side) == "string" and side:lower() or "neutral"))
end

local function Current()
    if reading then return reading end
    if opened then return opened end
    mine = mine or Prices.House("player")
    return mine
end

function Prices.Other()
    local house = Current()
    local key = house and keys[house]
    if not key then return nil end
    if key:find("/neutral$") then
        mine = mine or Prices.House("player")
        return mine ~= house and mine or nil
    end
    local neutral = key:gsub("/[^/]+$", "/neutral")
    local seen = (database and database[neutral]) or (type(part.houses) == "table" and part.houses[neutral])
    return seen and Part(neutral) or nil
end

function Prices.Within(house, fn, ...)
    local was = reading
    reading = house
    local ok, one, other = pcall(fn, ...)
    reading = was
    if not ok then error(one, 0) end
    return one, other
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

Prices.KeyOf = KeyOf

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

-- A key as a member's (sender) or this account's own again (nil): book.shared, with the keys standing as each member's
-- counted (Prices.KEYS).
local function Owned(book, key, sender)
    local was = book.shared[key]
    if was == sender then return end
    if was then book.heard[was] = (book.heard[was] or 1) - 1 end
    if sender then book.heard[sender] = (book.heard[sender] or 0) + 1 end
    book.shared[key] = sender
end

local function Book(house)
    local book = books[house]
    if book then return book end
    book = { index = {}, gear = {}, history = {}, held = 0, outlook = {}, outlooks = 0, offers = {}, shared = {}, under = {}, heard = {}, told = {} }
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
    -- What members sent, apart in the saved file as here
    for sender, text in pairs(type(house.heard) == "table" and house.heard or NONE) do
        if type(text) == "string" then
            for key, point in text:gmatch(SAVED) do
                local own = book.index[key]
                if not own or tonumber(point:match("^%d+")) > tonumber(own:match("^%d+")) then
                    if not book.shared[key] then book.under[key] = own end
                    Owned(book, key, sender)
                    Put(book, key, point)
                end
            end
        end
    end
    return book
end

-- A scan's point of an item (Scan.lua). True when its price moved: what another running account has to be told.
function Prices.Take(house, key, at, low, market, units, auctions, sellers)
    local book = Book(house)
    local point = book.index[key]
    Owned(book, key, nil)
    book.under[key] = nil
    Put(book, key, POINT:format(at, low, market, units, auctions, sellers))
    return point == nil or tonumber(point:match("^%d+,(%d+)")) ~= low or tonumber(point:match("^%d+,%d+,(%d+)")) ~= market
end

-- The house's points written into its saved string.
function Prices.Save(house)
    local book, lines, count, heard = Book(house), {}, 0, {}
    for key, point in pairs(book.index) do
        local sender = book.shared[key]
        if sender then
            local list = heard[sender] or {}
            heard[sender] = list
            list[#list + 1] = key .. "=" .. point .. ";"
            point = book.under[key]
        end
        if point then
            count = count + 1
            lines[count] = key .. "=" .. point .. ";"
        end
    end
    for sender, list in pairs(heard) do heard[sender] = table.concat(list) end
    house.index, house.heard, book.dirty = table.concat(lines), next(heard) and heard or nil, false
end

-- A scan was kept: the histories taken apart are old.
function Prices.Changed()
    for _, book in pairs(books) do book.history, book.held, book.outlook, book.outlooks = {}, 0, {}, 0 end
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
    Owned(book, key, nil)
    book.under[key] = nil
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
        if book.index[item] then return book.index[item], item end
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

-- The rhythm to read: of the account that took the most samples, as two accounts in one house see the same auctions.
local function Watcher(house)
    local shared = database and database[keys[house]]
    if shared and shared.rhythm and shared.samples > (tonumber(house.samples) or 0) then return shared end
    return house
end

-- The key of an item in the house read now, and its book.
local function Asked(item)
    local house = Current()
    local book = house and item and Book(house)
    if not book then return nil end
    local _, key = Point(book, item)
    return key, book, house
end

function Prices:Outlook(item)
    local key, book, house = Asked(item)
    if not key then return nil end
    local source = Watcher(house)
    local line = source.rhythm[key]
    if not line then return nil end
    local now = Now()
    local hour = math.floor(now / 3600)
    local held = book.outlook[key]
    if not held or held.hour ~= hour then
        held = Rhythm.Read(line, now, tonumber(source.watched), tonumber(source.watchedAt)) or {}
        held.hour = hour
        if book.outlooks >= HISTORIES then book.outlook, book.outlooks = {}, 0 end
        book.outlook[key], book.outlooks = held, book.outlooks + 1
    end
    return held.days and held or nil
end

function Prices:Under(item, price)
    local key, book = Asked(item)
    local list = key and book.offers[key]
    if not list then return nil end
    local units = 0
    for _, offer in ipairs(list) do
        if math.floor(offer / UNITS) > price then break end
        units = units + offer % UNITS
    end
    return units
end

-- What a scan found on offer (Scan.lua): { [key] = sorted offers }.
function Prices.Offers(house, lists)
    Book(house).offers = lists
end

function Prices:Usual(key)
    local house = Current()
    if not house then return nil end
    return Rhythm.Usual(Watcher(house).rhythm[key])
end

-- Which of the account's and the database's last scan is newer: the part that holds it.
local function Newest(house)
    local shared = database and database[keys[house]]
    if shared and shared.kept > (tonumber(house.kept) or 0) then return shared end
    return house
end

function Prices:Scanned()
    local list, count = {}, 0
    local house = Current()
    if not house then return list end
    local last = tonumber(Newest(house).kept) or 0
    for key, point in pairs(Book(house).index) do
        local at = tonumber(point:match("^%d+"))
        if at and at >= last then
            count = count + 1
            list[count] = key
        end
    end
    return list
end

function Prices:OnSale()
    local house = Current()
    local newest = house and Newest(house)
    local other = house and Prices.Other()
    local second = other and Newest(other)
    if not (newest and newest.onSale) and not (second and second.onSale) then return nil end
    local money, auctions = 0, 0
    for _, each in ipairs({ newest, second }) do
        money, auctions = money + (each.onSale or 0), auctions + (each.onSaleCount or 0)
    end
    return money, auctions, newest.kept
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
-- Several accounts' strings of a day stand joined in one, so a key can come more than once: the lowest price of them, and
-- the market price of the last that has one.
local function Entry(text, key)
    if type(text) ~= "string" then return nil end
    local word, low, market = ";" .. key .. "=", nil, nil
    local _, stop = text:find(word, 1, true)
    if text:sub(1, #key + 1) == key .. "=" then stop = #key + 1 end
    while stop do
        local price, usual = text:match(LOW_MARKET, stop + 1)
        price, usual = tonumber(price), tonumber(usual)
        if price and (not low or (price > 0 and (low == 0 or price < low))) then low = price end
        if usual and (not market or usual > 0) then market = usual end
        _, stop = text:find(word, stop, true)
    end
    return low, market
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

-- A house of an account's file joined to what the accounts hold together. Texts of a day join plainly, the last to scan at
-- the end: each line starts the string or follows a ";", and Entry takes the last market there is.
local function Join(key, house)
    local shared = database[key]
    if not shared then
        shared = { index = "", days = {}, recent = {}, kept = 0, samples = 0 }
        database[key] = shared
    end
    local samples = tonumber(house.samples) or 0
    if samples > shared.samples and type(house.rhythm) == "table" then
        shared.rhythm, shared.samples, shared.watched, shared.watchedAt = house.rhythm, samples, house.watched, house.watchedAt
    end
    local kept = tonumber(house.kept) or 0
    local newer = kept >= shared.kept
    if type(house.index) == "string" then shared.index = shared.index .. house.index end
    for day, text in pairs(type(house.days) == "table" and house.days or NONE) do
        if type(text) == "string" then
            local held = shared.days[day] or ""
            shared.days[day] = newer and held .. text or text .. held
        end
    end
    for at, text in pairs(type(house.recent) == "table" and house.recent or NONE) do shared.recent[at] = text end
    if newer then shared.kept, shared.onSale, shared.onSaleCount = kept, house.onSale, house.onSaleCount end
end

-- The part of a house this account knows; nil for another.
local function Known(key)
    if Current() == nil or type(part.houses) ~= "table" then return nil end
    local house = part.houses[key]
    return type(house) == "table" and keys[house] and house or nil
end

-- Whether two prices are within what a scan may move one by itself (Doc/ideas/Data.md, *Poisoning*).
local function Near(one, other)
    return one <= other * TRUST and other <= one * TRUST
end

-- A shared price where this account knows another: true when it may stand. Far off, it waits apart for a second sender, and
-- one of the two must be of the guild: a group can hold strangers.
local function Believed(name, low, known, sender, channel)
    if not known or known == 0 or low == 0 or Near(low, known) then return true end
    local first = doubted[name]
    if first and first.sender ~= sender and Near(first.low, low) and (first.guild or channel == "GUILD") then
        doubted[name] = nil
        return true
    end
    doubted[name] = { sender = sender, low = low, guild = channel == "GUILD" }
    return false
end

-- A block's lines by their strict shape: { { name, low, market, units, auctions, sellers }, ... }, or nil where one byte of the
-- text is anything else (a kind's level, suffix or species past what the game makes too): then none of it is taken.
local function Lines(text)
    local list, read = {}, 0
    for line, name, low, market, units, auctions, sellers in text:gmatch("(([^=;]+)=(%d+),(%d+),(%d+),(%d+),(%d+);)") do
        low, market, units, auctions, sellers = tonumber(low), tonumber(market), tonumber(units), tonumber(auctions), tonumber(sellers)
        local level, suffix, species = name:match("^%d+:(%d+):%-?(%d+):(%d+)$")
        if not (name:find("^%d+$") or level) or tonumber(name:match("^%d+")) > ITEM_MOST
            or (level and (tonumber(level) > LEVEL_MOST or tonumber(suffix) > SUFFIX_MOST or tonumber(species) > SPECIES_MOST))
            or low > PRICE_MOST or market > PRICE_MOST or units > COUNT_MOST or auctions > COUNT_MOST or sellers > COUNT_MOST then
            return nil
        end
        read = read + #line
        list[#list + 1] = { name, low, market, units, auctions, sellers }
    end
    if read ~= #text then return nil end
    return list
end

-- Far-off prices of one scan of one sender: beyond a few, a scan is not honest. True when it went beyond.
local function TooFar(sender, at, far)
    local count = doubts[sender]
    if not count or count.at ~= at then
        count = { at = at, far = 0 }
        doubts[sender] = count
    end
    count.far = count.far + far
    return count.far > Prices.DOUBTS
end

-- What a member's scan found (Relay.lua): "key=low,market,units,auctions,sellers;..." of a house this account knows, kept apart
-- as that sender's, over what this account has only where that is older. How many stood, and a word where the sender earned
-- a strike: shape (a line off it, a key of a kind the game would not make: gear's plain, a plain item's with a kind, or more
-- lines than a scan has, Relay.MOST), many (more keys standing as the sender's than a house holds, Prices.KEYS: the rest of
-- the block is passed over), or far. A point stands in the newest prices and, for a graph, that scan's line; the days, the
-- whole scans and this account's own points never hold it, so it can be taken out again, and nothing shared reaches the harvest.
function Prices.Heard(key, at, text, sender, channel)
    local house = Known(key)
    if not house then return 0 end
    local read = Lines(text)
    if not read or #read > Data.Relay.MOST then return 0, "shape" end
    for _, line in ipairs(read) do
        local gear = Prices.Gear(tonumber(line[1]:match("^%d+")))
        if gear ~= nil and (line[1]:find(":", 1, true) ~= nil) ~= gear then return 0, "shape" end
    end
    local book, lines, taken, far, many = Book(house), {}, 0, 0, false
    local stale = Now() - Prices.FRESH * DAY
    for _, line in ipairs(read) do
        local name, low = line[1], line[2]
        local known = book.index[name]
        local knownAt = known and tonumber(known:match("^%d+"))
        if (not knownAt or knownAt < at) and Prices.Gear(tonumber(name:match("^%d+"))) ~= nil then -- the game knows the item
            if book.shared[name] ~= sender and (book.heard[sender] or 0) >= Prices.KEYS then
                many = true
                break
            end
            local current = knownAt and knownAt >= stale and tonumber(known:match("^%d+,(%d+)")) or nil
            if Believed(name, low, current, sender, channel) then
                if not book.shared[name] then book.under[name] = known end
                Owned(book, name, sender)
                Put(book, name, POINT:format(at, low, line[3], line[4], line[5], line[6]))
                taken = taken + 1
                lines[taken] = name .. "=" .. low .. "," .. line[3] .. ";"
            else
                far = far + 1
            end
        end
    end
    if taken > 0 then
        database = database or {}
        local shared = database[key] or { index = "", days = {}, recent = {}, kept = 0, samples = 0 }
        database[key] = shared
        shared.recent[at] = (shared.recent[at] or "") .. table.concat(lines)
        book.told[at] = true
        book.dirty = true
        Prices.Changed()
    end
    if many then return taken, "many" end
    return taken, TooFar(sender, at, far) and "far" or nil
end

-- What members sent taken out again, and what waits of it: one sender's, or none named: everybody's. This account's own points
-- stand as they were.
function Prices.Forget(sender)
    for name, first in pairs(doubted) do
        if not sender or first.sender == sender then doubted[name] = nil end
    end
    for house, book in pairs(books) do
        local changed = false
        for key, who in pairs(book.shared) do
            if not sender or who == sender then
                book.index[key], book.shared[key], book.under[key], changed = book.under[key], nil, nil, true
            end
        end
        if sender then book.heard[sender] = nil else book.heard = {} end
        if changed then
            local shared = database and database[keys[house]]
            for at in pairs(book.told) do
                if shared then shared.recent[at] = nil end
            end
            book.told = {}
            Prices.Save(house)
        end
    end
    -- The houses not asked about in this session
    for _, house in pairs(part and type(part.houses) == "table" and part.houses or NONE) do
        if type(house) == "table" and type(house.heard) == "table" then
            if sender then house.heard[sender] = nil else house.heard = nil end
        end
    end
    Prices.Changed()
end

-- What members' prices stand now and wait, for /sane data.
function Prices.Shared()
    local standing, waiting = 0, 0
    for _, book in pairs(books) do
        for _ in pairs(book.shared) do standing = standing + 1 end
    end
    for _ in pairs(doubted) do waiting = waiting + 1 end
    return standing, waiting
end

-- When this account last scanned a house it knows, 0 for never; nil for a house it does not.
function Prices.Kept(key)
    local house = Known(key)
    return house and (tonumber(house.kept) or 0) or nil
end

-- This account's last scan of a house as Relay.lua tells it, whole, for a member who has none as new: its time and lines.
function Prices.Lines(key, since)
    local house = Known(key)
    local kept = house and tonumber(house.kept)
    if not kept or kept <= since then return nil end
    local lines = {}
    for name, point in pairs(Book(house).index) do
        local at, rest = point:match("^(%d+),(.*)$")
        if tonumber(at) >= kept then lines[#lines + 1] = name .. "=" .. rest .. ";" end
    end
    return kept, lines
end

-- Called after each link of the addon SaneUI_AuctionDatabase: that account's file has just run, and left its saved
-- variable in the global. What it holds of this game version is joined, and the global cleared: this account's own file is
-- read after these (the addon SaneUI_AuctionData says so), and must find nothing there.
function Prices.Account()
    local saved = rawget(_G, "SaneUIData_Market")
    rawset(_G, "SaneUIData_Market", nil)
    local client = type(saved) == "table" and saved[Data.Game()]
    for key in pairs(type(client) == "table" and type(client.mine) == "table" and client.mine or {}) do ours[key] = true end
    local houses = type(client) == "table" and client.houses
    if type(houses) ~= "table" then return end
    database = database or {}
    for key, house in pairs(houses) do
        if type(house) == "table" then Join(key, house) end
    end
end

-- What the accounts hold together forgotten (the tests' way back).
function Prices.Clear()
    database = nil
    wipe(ours)
end

-- Whether a sender is a character of this player's: each account's auction file names its characters, and every account reads
-- the others' (Prices.Account). Without those links, this account's alone.
function Prices.Mine(sender)
    return ours[sender] == true or (part ~= nil and type(part.mine) == "table" and part.mine[sender] == true)
end

-- The house prices are read from now: the one open, else the one of your side.
function Prices.Read()
    return Current()
end

-- The key of a house's part.
function Prices.Key(house)
    return keys[house]
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

-- The offers the game listed of an item, for Prices:Under.
local function Offered(key, list)
    local house = Current()
    if house then
        table.sort(list)
        Book(house).offers[key] = list
    end
end

-- All the offers of a thing sold by the unit: the cheapest of them.
local function Commodity(item)
    local auctions = rawget(_G, "C_AuctionHouse")
    item = Plain(item)
    local count = auctions and Ask(auctions.GetNumCommoditySearchResults, item)
    local lowest
    local list = {}
    for index = 1, type(count) == "number" and count or 0 do
        local offer = Plain(Ask(auctions.GetCommoditySearchResultInfo, item, index))
        local price = type(offer) == "table" and Plain(offer.unitPrice)
        if type(price) == "number" and price > 0 then
            if not lowest or price < lowest then lowest = price end
            list[#list + 1] = price * UNITS + math.min(tonumber(Plain(offer.quantity)) or 1, UNITS - 1)
        end
    end
    if lowest then
        Offered(tostring(item), list)
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
    local list = {}
    for index = 1, type(count) == "number" and count or 0 do
        local offer = Plain(Ask(auctions.GetItemSearchResultInfo, itemKey, index))
        local buyout = type(offer) == "table" and Plain(offer.buyoutAmount)
        local quantity = type(offer) == "table" and Plain(offer.quantity)
        if type(buyout) == "number" and buyout > 0 and type(quantity) == "number" and quantity > 0 then
            local price = math.ceil(buyout / quantity)
            if not lowest or price < lowest then lowest = price end
            list[#list + 1] = price * UNITS + math.min(quantity, UNITS - 1)
        end
    end
    if lowest then
        Offered(key, list)
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

Core.On("PLAYER_LOGIN", function()
    local key = Core.PlayerKey("player")
    if not (part and key) then return end
    if type(part.mine) ~= "table" then part.mine = {} end
    part.mine[key] = true
end)
