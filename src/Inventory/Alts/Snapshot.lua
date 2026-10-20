local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Snapshot
--  What the window of the other characters shows, without a frame: the
--  account's characters as Core's data framework keeps them (Core.Data,
--  Characters.lua; read only, never written), what each has where, and what
--  of it the search finds. Roster.lua and Items.lua only draw what this says.
--
--      Snapshot.Characters()          the roster: the character logged in first, then the others by
--                                     name, the account's own bank last where it holds something;
--                                     nil while Core's data is not loaded yet
--      Snapshot.Sections(key, query)  what one of them has, place by place:
--                                     { { place = "bags", items = { { item, count }, ... } }, ... },
--                                     only what the search finds (query: Fuzzy.Query's words, or nil)
--      Snapshot.Found(key, query)     how many things of that one the search finds (stacks counted whole)
--      Snapshot.Gold()                the gold of every character together
--      Snapshot.Name(item)            an item's name, once the game knows it (asked for, once, if not)
--      Snapshot.Learned(item)         the game told of an item: whether it is one asked for (then forgotten)
--      Snapshot.Ago(day)              how many days ago a day of the server's was (0: today), or nil
--
--  An item is found by its ID (a number typed) or by its name: each word
--  typed found in it whole, as a piece or as its words' first letters
--  (Core.Fuzzy). Letters spread through a name are too loose a fit among a
--  bag of names. A name the game does not know yet is asked for; the window
--  draws anew when it comes (Alts.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Data, Fuzzy = Core.Data, Core.Fuzzy
local Snapshot = {}
ns.Snapshot = Snapshot

Snapshot.ACCOUNT = "account"                 -- the account's own bank, as Core's data names it
Snapshot.PLACES = { "bags", "bank", "worn" } -- a character's places, in the order the window shows them
local ACCOUNT_PLACES = { "bank" }
local DAY = 86400

local names, lows = {}, {} -- [item] = its name and the name in lower case, once the game knows it
local asked = {}           -- [item] = true: asked of the game, never again (one it never knows stays nameless);
                           -- "waiting" until the game told of it

function Snapshot.Characters()
    local all = Data.Characters()
    if not all then return nil end
    local rows = {}
    for _, who in ipairs(all) do
        if who.key == Core.charKey then table.insert(rows, 1, who) else rows[#rows + 1] = who end
    end
    local bank = Data.Items(Snapshot.ACCOUNT, "bank")
    if bank and #bank > 0 then rows[#rows + 1] = { key = Snapshot.ACCOUNT } end
    return rows
end

function Snapshot.Name(item)
    if names[item] then return names[item] end
    local items = rawget(_G, "C_Item")
    if not items then return nil end
    local name = Core.Ask(items.GetItemNameByID, item)
    if type(name) == "string" and name ~= "" then
        names[item], lows[item] = name, name:lower()
        return name
    end
    if not asked[item] then
        asked[item] = "waiting"
        Core.Ask(items.RequestLoadItemDataByID, item)
    end
    return nil
end

function Snapshot.Learned(item)
    if asked[item] ~= "waiting" then return false end
    asked[item] = true
    return true
end

-- Whether the search finds an item.
local function Finds(query, item)
    local number = #query == 1 and tonumber(query[1])
    if number then return number == item end
    local name = Snapshot.Name(item)
    if not name then return false end
    for _, word in ipairs(query) do
        local rank = Fuzzy.Rank(word, name, lows[item])
        if not rank or rank < Fuzzy.INSIDE then return false end
    end
    return true
end

local function Places(key)
    return key == Snapshot.ACCOUNT and ACCOUNT_PLACES or Snapshot.PLACES
end

function Snapshot.Sections(key, query)
    local sections = {}
    for _, place in ipairs(Places(key)) do
        local items = Data.Items(key, place) or {}
        if query then
            local found = {}
            for _, entry in ipairs(items) do
                if Finds(query, entry.item) then found[#found + 1] = entry end
            end
            items = found
        end
        sections[#sections + 1] = { place = place, items = items }
    end
    return sections
end

function Snapshot.Found(key, query)
    local count = 0
    for _, place in ipairs(Places(key)) do
        for _, entry in ipairs(Data.Items(key, place) or {}) do
            if Finds(query, entry.item) then count = count + entry.count end
        end
    end
    return count
end

function Snapshot.Gold()
    local total = 0
    for _, who in ipairs(Data.Characters() or {}) do
        if type(who.money) == "number" then total = total + who.money end
    end
    return total
end

function Snapshot.Ago(day)
    local now = Core.Ask(rawget(_G, "GetServerTime"))
    if type(day) ~= "number" or type(now) ~= "number" then return nil end
    return math.max(0, math.floor(now / DAY) - day)
end
