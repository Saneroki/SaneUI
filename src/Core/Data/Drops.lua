local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Drops
--  How often things come (Doc/guides/data.md, *Drop rates*): what a creature, a node or a fishing water gives, for every
--  view. The set Drops is what shipped; over it what this account counted in play (Tally.lua), every build kept, and what
--  the guild's and the group's members counted (Bundle.lua). A key is "npc:<id>", "object:<id>" or "zone:<map>".
--
--      local Drops = Data.Drops()
--      Drops:Of("object:1617")              what it gives, the most likely first: one entry per item and way
--      Drops:Of("object:1617", "period")    this build period only
--      Drops:Rare("object:1617")            only what comes at most Drops.RARE percent of the time
--      Drops:Chance("npc:69", 769)          its chance in percent (nil while too few came), how many came, of how many
--      Drops:From(2838)                     who gives an item, the likeliest first: the entries with their key
--      Drops:Knows("npc:69", "skin", 2318)  whether the set lists that item for that way
--      Drops:Name("object:1617")            the thing's or the creature's name
--
--  An entry: item, how (loot, skin, pickpocket, gather, fish), quest (0: for everybody), drops (loots it came in), units
--  (how many in all), loots (of that way), chance (percent), rate (percent, however few came), yield (units a time it came),
--  perVisit (units a visit, a node's), rare, shipped (only the set lists it), listed (its chance is the set's), doubt (what
--  the set says of it the game has not confirmed yet). The list also has loots[how] and visits[how].
--
--  - **A chance needs Drops.SURE drops;** until then a view has how many of how many: a rare gem seen once is counted, not
--    made a percentage. Below Drops.ENOUGH loots the set's own chance stands, where it has one.
--  - **Rare** is by how seldom it comes, not by an item's colour: a vein's gem, a hide that rarely comes off a corpse.
--  - **Members' counts** are summed robustly (Doc/ideas/Data.md, *Poisoning* 6), a way at a time: one whose chance is far from
--    everybody else's with enough loots both sides to be sure is left out, and with four voices or more none makes up more
--    than a quarter. Counts of this player's other accounts (Prices.Mine) always count, as its own do.
-------------------------------------------------------------------------------
local Data = Core.Data
local Tally = Data.Tally
local DROPS = Data.Set("Drops")
local floor, sqrt, abs, min = math.floor, math.sqrt, math.abs, math.min

local Drops = {}
Drops.SURE = 3       -- drops of an item before it gets a chance
Drops.ENOUGH = 50    -- loots of a way before play's chance stands over the set's
Drops.RARE = 10      -- percent: what comes at most this often is a rare drop
Drops.LOOTS = 30     -- loots both sides before a member's chance can be told to be far off
Drops.Z = 4          -- how far off: two-proportion z
Drops.SHARE = 0.25   -- the most of a way's loots one member makes up
Drops.VOICES = 4     -- voices of a way from which on that holds

local LINES, RARES = 12, 5 -- /sane data gathered: lines at most, rare items on a line at most
local TEXT = {
    none = "nothing gathered or skinned is counted yet.",
    line = "%s: %d %s%s.%s",
    visits = " in %d visits",
    rare = " Rare: %s.",
    count = "%s %d of %d",
    chance = "%s %.1f%% (%d of %d)",
    more = "and %d more.",
    report = "gathered and skinned, counted in play: %d kinds, %d rare drops (/sane data gathered).",
    gather = "gathered", skin = "skinned",
}

local answers, sources, stamp = {}, {}, nil -- what was worked out, until something was counted

local function Stamp()
    return Tally.stamp + (Data.Bundle and Data.Bundle.stamp or 0) + (DROPS:Ready() and DROPS:Stamp() or 0)
end

local function Fresh()
    local now = Stamp()
    if now ~= stamp then
        answers, sources, stamp = {}, {}, now
    end
end

-- A voice's part of a way added to a sum, at a share of its weight.
local function Fold(total, voice, way, share)
    total.loots[way] = (total.loots[way] or 0) + (voice.loots[way] or 0) * share
    local start = way .. "|"
    for name, given in pairs(voice.items) do
        if name:sub(1, #start) == start then
            local had = total.items[name] or { 0, 0 }
            total.items[name] = { had[1] + given[1] * share, had[2] + given[2] * share }
        end
    end
    local how, quest = way:match("^(.+)|(%d+)$")
    if quest == "0" and voice.visits[how] then total.visits[how] = (total.visits[how] or 0) + voice.visits[how] * share end
end

-- Whether a member's chance of an item of a way is far from everybody else's, with enough loots both sides to be sure.
local function Odd(voice, way, all)
    local mine, others = voice.loots[way], all.loots[way] - voice.loots[way]
    if mine < Drops.LOOTS or others < Drops.LOOTS then return false end
    local start = way .. "|"
    for name, given in pairs(all.items) do
        if name:sub(1, #start) == start then
            local own = voice.items[name] and voice.items[name][1] or 0
            local rest = given[1] - own
            local pooled = given[1] / (mine + others)
            local spread = sqrt(pooled * (1 - pooled) * (1 / mine + 1 / others))
            if spread > 0 and abs(own / mine - rest / others) / spread > Drops.Z then return true end
        end
    end
    return false
end

-- This account's counts of a key with the members' over them.
local function Counted(key, period)
    local total = Tally.Counts(key, period)
    local voices = Data.Bundle and Data.Bundle.Voices(key, period) or {}
    local ways = {}
    for _, voice in ipairs(voices) do
        for way in pairs(voice.loots) do
            ways[way] = ways[way] or {}
            table.insert(ways[way], voice)
        end
    end
    for way, list in pairs(ways) do
        local all = { loots = {}, items = {}, visits = {} }
        Fold(all, total, way, 1)
        for _, voice in ipairs(list) do Fold(all, voice, way, 1) end
        local heard = #list + ((total.loots[way] or 0) > 0 and 1 or 0)
        local cap = heard >= Drops.VOICES and all.loots[way] * Drops.SHARE or nil
        for _, voice in ipairs(list) do
            if voice.mine then
                Fold(total, voice, way, 1)
            elseif not Odd(voice, way, all) then
                Fold(total, voice, way, cap and min(1, cap / voice.loots[way]) or 1)
            end
        end
    end
    return total
end

local function Round(value)
    return floor(value + 0.5)
end

local function Likelier(a, b)
    if a.rate ~= b.rate then return a.rate > b.rate end
    if a.item ~= b.item then return a.item < b.item end
    return a.how < b.how
end

-- The set's word on a counted entry, or the entry of what only the set lists.
local function Shipped(list, record, doubt)
    for _, drop in ipairs(type(record) == "table" and record.items or {}) do
        local entry
        for _, each in ipairs(list) do
            if each.item == drop.item and each.quest == (drop.quest or 0) and (not drop.how or drop.how == each.how) then
                entry = each
                break
            end
        end
        if entry then
            if entry.loots < Drops.ENOUGH and drop.chance then
                entry.chance, entry.rate, entry.listed, entry.doubt = drop.chance, drop.chance, true, doubt
            end
        else
            local chance = drop.chance
            list[#list + 1] = { item = drop.item, how = drop.how or "loot", quest = drop.quest or 0, drops = drop.drops or 0,
                units = drop.drops or 0, loots = record.loots or 0, chance = chance, rate = chance or 0, shipped = true, doubt = doubt }
        end
    end
end

-- What a key gives: see the file's words. Read-only: answers are kept until something is counted.
function Drops:Of(key, period)
    Fresh()
    local name = period and key .. "\031" or key
    if answers[name] then return answers[name] end
    local total = Counted(key, period)
    local list = { loots = {}, visits = {} }
    for how, visits in pairs(total.visits) do list.visits[how] = Round(visits) end
    for way, loots in pairs(total.loots) do
        local how, quest = way:match("^(.+)|(%d+)$")
        if quest == "0" then list.loots[how] = Round(loots) end
    end
    for item, given in pairs(total.items) do
        local how, quest, id = item:match("^(.+)|(%d+)|(%d+)$")
        local loots = total.loots[how .. "|" .. quest] or 0
        if given[1] > 0 and loots > 0 then
            local drops, rate = Round(given[1]), 100 * given[1] / loots
            list[#list + 1] = { item = tonumber(id), how = how, quest = tonumber(quest), drops = drops, units = Round(given[2]),
                loots = Round(loots), rate = rate, chance = drops >= Drops.SURE and rate or nil, yield = given[2] / given[1],
                perVisit = (total.visits[how] or 0) > 0 and given[2] / total.visits[how] or nil }
        end
    end
    local record = DROPS:Ready() and DROPS:Get(key) or nil
    Shipped(list, record, record ~= nil and DROPS:Unverified(key))
    for _, entry in ipairs(list) do entry.rare = entry.rate > 0 and entry.rate <= Drops.RARE end
    table.sort(list, Likelier)
    answers[name] = list
    return list
end

-- Only what comes seldom, the rarest last.
function Drops:Rare(key, period)
    local found = {}
    for _, entry in ipairs(self:Of(key, period)) do
        if entry.rare then found[#found + 1] = entry end
    end
    return found
end

-- An item's chance from a key, for everybody where it holds for everybody: chance, drops, loots; nil when it has none.
function Drops:Chance(key, item, period)
    local best
    for _, entry in ipairs(self:Of(key, period)) do
        if entry.item == item and (not best or (best.quest ~= 0 and entry.quest == 0)) then best = entry end
    end
    if best then return best.chance, best.drops, best.loots end
    return nil
end

-- Who gives an item, the likeliest first.
function Drops:From(item)
    Fresh()
    if sources[item] then return sources[item] end
    local keys = {}
    for key in pairs(Tally.Keys(item)) do keys[key] = true end
    for _, key in ipairs(DROPS:Ready() and DROPS:Keys("byItem", item) or {}) do keys[key] = true end
    local found = {}
    for key in pairs(keys) do
        for _, entry in ipairs(self:Of(key)) do
            if entry.item == item then
                local copy = { key = key }
                for field, value in pairs(entry) do copy[field] = value end
                found[#found + 1] = copy
            end
        end
    end
    table.sort(found, function(a, b)
        if a.rate ~= b.rate then return a.rate > b.rate end
        if a.key ~= b.key then return a.key < b.key end
        return a.how < b.how
    end)
    sources[item] = found
    return found
end

-- Whether the set lists an item for that way (a row that names no way lists it for every way). True while the set is not
-- there: nothing is a discovery then.
function Drops:Knows(key, how, item)
    if not DROPS:Ready() then return true end
    local record = DROPS:Get(key)
    for _, drop in ipairs(type(record) == "table" and record.items or {}) do
        if drop.item == item and (not drop.how or drop.how == how) then return true end
    end
    return false
end

-- A key's name: the thing's or the creature's, or the key.
function Drops:Name(key)
    local kind, id = key:match("^(%a+):(%d+)$")
    local name = kind == "object" and Data.Set("Objects") or kind == "npc" and Data.Set("NPCs") or nil
    return name and name:Ready() and name:Get(tonumber(id), "name") or key
end

local function ItemName(item)
    local items = Data.Set("Items")
    return items:Ready() and items:Get(item, "name") or ("item " .. item)
end

-- What came of a key's rare drops, as a line's end.
local function Words(entries)
    local words = {}
    for index = 1, min(#entries, RARES) do
        local entry = entries[index]
        words[index] = entry.chance and TEXT.chance:format(ItemName(entry.item), entry.chance, entry.drops, entry.loots)
            or TEXT.count:format(ItemName(entry.item), entry.drops, entry.loots)
    end
    return table.concat(words, ", ")
end

-- What was gathered and skinned, the most gathered first: for each, how often and in how many visits, and its rare drops.
function Drops:Gathered()
    local found = {}
    for key in pairs(Tally.All()) do
        local list = self:Of(key)
        for _, how in ipairs({ "gather", "skin" }) do
            if (list.loots[how] or 0) > 0 then
                local rare = {}
                for _, entry in ipairs(list) do
                    if entry.rare and entry.how == how and not entry.shipped then rare[#rare + 1] = entry end
                end
                found[#found + 1] = { key = key, how = how, loots = list.loots[how], visits = list.visits[how], rare = rare }
            end
        end
    end
    table.sort(found, function(a, b)
        if a.loots ~= b.loots then return a.loots > b.loots end
        if a.key ~= b.key then return a.key < b.key end
        return a.how < b.how
    end)
    return found
end

-- /sane data gathered
function Drops:Say()
    local found = self:Gathered()
    if #found == 0 then return Core.Print(TEXT.none) end
    for index = 1, min(#found, LINES) do
        local each = found[index]
        Core.Print(TEXT.line:format(self:Name(each.key), each.loots, TEXT[each.how], each.visits and TEXT.visits:format(each.visits) or "",
            #each.rare > 0 and TEXT.rare:format(Words(each.rare)) or ""))
    end
    if #found > LINES then Core.Print(TEXT.more:format(#found - LINES)) end
end

Data.reports[#Data.reports + 1] = function()
    local found, rare = Drops:Gathered(), 0
    for _, each in ipairs(found) do rare = rare + #each.rare end
    if #found > 0 then Core.Print(TEXT.report:format(#found, rare)) end
end

function Data.Drops()
    return Drops
end
