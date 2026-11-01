local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - Data - Found
--  The discoveries (Doc/ideas/Data.md, *Discoveries and notices*): every change the game's own data took in play, in one
--  short list, and the one chat line that tells of them. The database tells, no module prints anything about data.
--
--      Data.Discovered("Quests", 77, "new", { "name" })   Core's watchers, once a change was accepted (how nil: seen here)
--      Data.Discovered("Drops", "object:1617", "drop", { "gather=2838" })   an item no data listed for that way
--      Data.Discovered("Vendors", 12, "changed", parts, "shared")           taken from the guild or the group (Bundle.lua)
--      Data.Found(fromDay)                                the list, the newest first: { day, build, how, set, key, what, parts }
--      Data.Discoveries.Prices(count)                     a scan moved so many prices: told, not kept (the auction file has them)
--
--  Kept in SaneUIData_Learned[game].found, a packed line each: no time finer than the day, nothing of who: a discovery is
--  the game's fact, not the player's story. At most Found.MOST, none older than Found.DAYS days: the sets keep the rest.
--
--  The chat lines (the switches of the page General, both off by default): one line, summed up, of what was accepted. The
--  first at once, then at most one of a kind in Found.GAP seconds, never in a fight: what comes meanwhile waits for it.
--  [Details] prints the newest discoveries (an addon link: the game hands it to EventRegistry's SetItemRef).
-------------------------------------------------------------------------------
local Data, Codec = Core.Data, Core.Data.Codec

local Found = {}
Data.Discoveries = Found
Found.DAYS = 90        -- days a discovery is kept
Found.MOST = 2000      -- discoveries kept at most, the oldest go first
Found.GAP = 15 * 60    -- seconds between two chat lines of a kind
Found.SHOWN = 15       -- /sane data found: the newest so many

local PART, LIST = "\031", "\030"
local LINK = "addon:SaneUI:data"
local SWITCHES = { data = "chatData", prices = "chatPrices" }
local NOUNS = {
    Quests = { "quest", "quests" }, NPCs = { "NPC", "NPCs" }, Vendors = { "vendor", "vendors" }, Spells = { "spell", "spells" },
    Items = { "item", "item" .. "s" }, Travel = { "way", "ways" }, Drops = { "drop", "drops" },
}
local TEXT = {
    data = "data: %s%s. %s",
    prices = "auction prices: %d moved. %s",
    build = " (%s)",
    new = "%d new %s", changed = "%d changed %s", drop = "%d new %s",
    details = "|cff71d5ff|H" .. LINK .. "|h[Details]|h|r",
    none = "no discoveries yet.",
    entry = "%s: %s %s %s%s.",
    entryParts = " (%s)",
    shared = ", from your guild or group",
    words = { new = "new", changed = "changed", drop = "new drop on" },
    report = "discoveries: %d kept, the last on %s (/sane data found).",
}

local list            -- the saved lines, the oldest first
local parsed          -- list taken apart: made when first asked, kept up
local waiting = { data = {}, prices = 0 } -- what the next line of each kind sums up
local told = {}       -- [kind] = GetTime() of the last line
local armed = {}      -- [kind] = true while a line waits for its time

local function Today()
    local now = Core.Plain(Core.Ask(rawget(_G, "GetServerTime"))) or Core.Ask(rawget(_G, "time")) or 0
    return math.floor(now / 86400)
end

local function Build()
    local _, number = Core.Ask(rawget(_G, "GetBuildInfo"))
    return tonumber(number) or 0
end

local function Read(line)
    local fields = Codec.Cut(line, PART)
    local key = fields[5]
    return { day = tonumber(fields[1]) or 0, build = tonumber(fields[2]) or 0, how = fields[3], set = fields[4],
        key = tonumber(key) or key, what = fields[6], parts = fields[7] and fields[7] ~= "" and Codec.Cut(fields[7], LIST) or {} }
end

-- "3 new quests, 12 changed items"
local function Sum(counts)
    local names, words = {}, {}
    for name in pairs(counts) do names[#names + 1] = name end
    table.sort(names)
    for index, name in ipairs(names) do
        local what, set = name:match("^(%a+)|(.+)$")
        local noun = NOUNS[set] or { set, set }
        words[index] = TEXT[what]:format(counts[name], noun[counts[name] == 1 and 1 or 2])
    end
    return table.concat(words, ", ")
end

local Speak

local function Switched(kind)
    return Core.general ~= nil and Core.general[SWITCHES[kind]] == true
end

-- The line of a kind, now; in a fight, or while the game restricts addons, it waits for that to end (Released).
function Speak(kind)
    armed[kind] = nil
    if not Switched(kind) then
        waiting.data, waiting.prices = kind == "data" and {} or waiting.data, kind == "prices" and 0 or waiting.prices
        return
    end
    if Core.Restricted() then
        armed[kind] = "fight"
        return
    end
    if kind == "data" then
        if not next(waiting.data) then return end
        local patch = Core.Ask(rawget(_G, "GetBuildInfo"))
        Core.Print(TEXT.data:format(Sum(waiting.data), type(patch) == "string" and TEXT.build:format(patch) or "", TEXT.details))
        waiting.data = {}
    else
        if waiting.prices == 0 then return end
        Core.Print(TEXT.prices:format(waiting.prices, TEXT.details))
        waiting.prices = 0
    end
    told[kind] = GetTime()
end

-- Something to tell: at once when the last line is long enough ago, else when it is.
local function Tell(kind)
    if armed[kind] or not Switched(kind) then return end
    local wait = told[kind] and told[kind] + Found.GAP - GetTime() or 0
    if wait <= 0 then return Speak(kind) end
    armed[kind] = true
    C_Timer.After(wait, Core.Guard("data: found", function() Speak(kind) end))
end

-- The fight over, or the game's restriction lifted (Core.lua hears that event first, so Core.Restricted says so already):
-- the lines that waited for it. Not while another restriction still holds.
local function Released()
    if Core.Restricted() then return end
    local kinds = {}
    for kind, why in pairs(armed) do
        if why == "fight" then kinds[#kinds + 1] = kind end
    end
    for _, kind in ipairs(kinds) do Speak(kind) end
end
Core.On("PLAYER_REGEN_ENABLED", Released)
Core.On("ADDON_RESTRICTION_STATE_CHANGED", Released)

-- A change accepted. False when it cannot be kept yet.
function Data.Discovered(set, key, what, parts, how)
    if not list or key == nil then return false end
    how = how or "watcher"
    local line = table.concat({ Today(), Build(), how, set, tostring(key), what, table.concat(parts or {}, LIST) }, PART)
    list[#list + 1] = line
    if #list > Found.MOST then table.remove(list, 1) end
    parsed = nil
    local name = what .. "|" .. set
    waiting.data[name] = (waiting.data[name] or 0) + 1
    Tell("data")
    if how ~= "shared" and Data.Bundle then Data.Bundle.Note(set, key) end
    return true
end

-- The discoveries from a day on (all: nil), the newest first. Read-only.
function Data.Found(fromDay)
    if not parsed then
        parsed = {}
        for index = #(list or {}), 1, -1 do parsed[#parsed + 1] = Read(list[index]) end
    end
    if not fromDay then return parsed end
    local some = {}
    for _, entry in ipairs(parsed) do
        if entry.day >= fromDay then some[#some + 1] = entry end
    end
    return some
end

-- A scan moved prices, this account's own or a member's.
function Found.Prices(count)
    if type(count) ~= "number" or count <= 0 then return end
    waiting.prices = waiting.prices + count
    Tell("prices")
end

-- /sane data found, and the chat line's [Details]
function Found.Say()
    local entries = Data.Found()
    if #entries == 0 then return Core.Print(TEXT.none) end
    for index = 1, math.min(#entries, Found.SHOWN) do
        local entry = entries[index]
        local handle = Data.Set(entry.set)
        local name = handle:Ready() and entry.what ~= "drop" and handle:Get(entry.key, "name") or nil
        Core.Print(TEXT.entry:format(date("%Y-%m-%d", entry.day * 86400), TEXT.words[entry.what] or entry.what, entry.set,
            name or tostring(entry.key), #entry.parts > 0 and TEXT.entryParts:format(table.concat(entry.parts, ", ")) or "")
            .. (entry.how == "shared" and TEXT.shared or ""))
    end
end

local function Clicked(_, link)
    if link == LINK then Found.Say() end
end

local registry = rawget(_G, "EventRegistry")
if type(registry) == "table" and registry.RegisterCallback then
    registry:RegisterCallback("SetItemRef", Core.Guard("data: found", Clicked), Found)
end

Data.reports[#Data.reports + 1] = function()
    local entries = Data.Found()
    if #entries > 0 then Core.Print(TEXT.report:format(#entries, date("%Y-%m-%d", entries[1].day * 86400))) end
end

Data.Saved("Learned", function(part)
    if type(part.found) ~= "table" then part.found = {} end
    list, parsed = part.found, nil
    local oldest = Today() - Found.DAYS
    for index = #list, 1, -1 do
        local line = list[index]
        if type(line) ~= "string" or (tonumber(line:match("^%d+")) or 0) < oldest then table.remove(list, index) end
    end
end)
