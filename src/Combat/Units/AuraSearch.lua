local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - AuraSearch
--  What the aura lists' search box finds (Lists.lua), in groups: each class's
--  auras (the spells of its class lines that put an aura on: Core's sets
--  SkillLines and Spells), the enemies' (CreatureSpells) and those of food,
--  potions, elixirs, items and the world (Auras). One entry per name in a group,
--  whatever its rank, as the lists mark auras by name. Read once, at the first
--  search: the classes at once, the other two a part per frame, out of a fight
--  (Data's jobs); a search asked for meanwhile runs when they are read.
--
--  Typed, a spell's number finds that spell wherever the game knows it, first.
--  Without the sets (Retail, until its data comes) a name finds only a spell of
--  your own, as the game knows it by name.
--
--  A search is Core's (Fuzzy): forgiving, ranked. The groups come in the order
--  of their best find, your own class first where two are as good, and within a
--  group the best first.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Search = {}
ns.AuraSearch = Search

Search.CLASSES = 20 -- the class numbers looked at, from 1: the game's, and room for more
Search.ENEMIES, Search.ITEMS = 100, 101 -- the two groups' places after the classes

local entries, groups -- what is searched: { id, name, icon, group } each; the groups by key
local reading = 0     -- the jobs still reading a set
local pending         -- the newest search asked for while they read

-- Whether a spell's record puts an aura on: one of its effects does. A spell the set holds no effects of counts.
local function Aura(record)
    local effects = record.effects
    if type(effects) ~= "table" then return true end
    for _, effect in pairs(effects) do
        if type(effect) == "table" and (tonumber(effect.aura) or 0) > 0 then return true end
    end
    return false
end

local function Group(key, title, colour, order)
    local group = { key = key, title = title, colour = colour, order = order, names = {} }
    groups[key] = group
    return group
end

-- An entry of a group, once per name.
local function Add(group, id, name, icon)
    if type(name) ~= "string" or name == "" or group.names[name] then return end
    group.names[name] = true
    entries[#entries + 1] = { id = id, name = name, icon = icon, group = group }
end

-- The players' auras, class by class: the spells of each class line.
local function Classes()
    local Data = Core.Data
    local classes, lines, spells = Data.Set("Classes"), Data.Set("SkillLines"), Data.Set("Spells")
    if not (classes:Ready() and lines:Ready() and spells:Ready()) then return end
    local _, mine = Core.Ask(UnitClass, "player")
    for id = 1, Search.CLASSES do
        local class = classes:Get(id)
        if class then
            local group = Group("class" .. id, class.name or class.file, class.color, id)
            group.own = class.file ~= nil and class.file == mine
            for _, line in ipairs(lines:Keys("byClass", id)) do
                local record = lines:Get(line)
                if record and record.kind == "class" then
                    for _, spell in pairs(record.spells or {}) do
                        local found = spells:Get(spell)
                        if found and Aura(found) then Add(group, spell, found.name, found.icon) end
                    end
                end
            end
        end
    end
end

-- A set read: the search asked for meanwhile runs once all are.
local function Finished()
    reading = reading - 1
    if reading > 0 or not pending then return end
    local again = pending
    pending = nil
    again()
end

-- A set read into its group a part per frame.
local function Walk(name, group)
    local set = Core.Data.Set(name)
    local job = set:Ready() and set:Each(function(key, record) Add(group, key, record.name, record.icon) end, Finished)
    if job then reading = reading + 1 end
end

-- Everything to search, once; again later while Core is still reading its own files.
local function Gather()
    if entries then return end
    if Core.Data.Set("Spells"):State() == "loading" then return end
    entries, groups = {}, {}
    Classes()
    local TEXT = ns.TEXT
    Walk("CreatureSpells", Group("enemies", TEXT.searchEnemies, nil, Search.ENEMIES))
    Walk("Auras", Group("items", TEXT.searchItems, nil, Search.ITEMS))
end

-- What the game itself finds by the text: the spell of that number, or (without the sets) a spell of yours by name.
local function Typed(text)
    local spells = rawget(_G, "C_Spell")
    if not spells then return nil end
    local id = tonumber(text)
    local name, title
    if id then
        name, title = Core.Ask(spells.GetSpellName, id), ns.TEXT.searchNumber
    elseif not (entries and entries[1]) then
        local info = Core.Ask(spells.GetSpellInfo, text)
        id = type(info) == "table" and Plain(info.spellID) or nil
        name, title = id and Plain(info.name), ns.TEXT.searchYours
    end
    if type(name) ~= "string" or type(id) ~= "number" then return nil end
    local entry = { id = id, name = name, icon = Core.Ask(spells.GetSpellTexture, id) }
    return { title = title, entries = { entry } }
end

local function Better(a, b)
    if a.rank ~= b.rank then return a.rank > b.rank end
    return a.name < b.name
end

local function First(a, b)
    if a.best ~= b.best then return a.best > b.best end
    if (a.group.own or false) ~= (b.group.own or false) then return a.group.own == true end
    return a.group.order < b.group.order
end

-- The entries found, by group: { title, colour, entries } each, in the order they come.
local function Grouped(found, ranks, typed)
    local list, by = {}, {}
    for index, entry in ipairs(found or {}) do
        local group = entry.group
        local shown = by[group]
        if not shown then
            shown = { group = group, title = group.title, colour = group.colour, best = 0, entries = {} }
            by[group] = shown
            list[#list + 1] = shown
        end
        entry.rank = ranks[index] or 0
        shown.entries[#shown.entries + 1] = entry
        if entry.rank > shown.best then shown.best = entry.rank end
    end
    for _, shown in ipairs(list) do table.sort(shown.entries, Better) end
    table.sort(list, First)
    if typed then table.insert(list, 1, typed) end
    return list
end

-- A search: done(list) with the groups found (an empty list: nothing; nil: nothing typed). While the sets are read
-- the list holds what the game found by itself, list.reading is true, and done is told again once they are read.
function Search.Find(text, done)
    text = (text or ""):match("^%s*(.-)%s*$")
    local query = Core.Fuzzy.Query(text)
    if not query then
        pending = nil
        return done(nil)
    end
    Gather()
    local typed = Typed(text)
    if not entries or reading > 0 then
        pending = function() Search.Find(text, done) end
        local list = { typed }
        list.reading = true
        return done(list)
    end
    pending = nil
    Core.Fuzzy.Filter(entries, query, { "name" }, function(found, ranks) done(Grouped(found, ranks, typed)) end)
end

-- The shown entry's name with what was typed in it in the game's gold.
function Search.Lit(entry, text)
    local query = Core.Fuzzy.Query(text)
    if not query then return entry.name end
    local spots, all = {}, {}
    for _, word in ipairs(query) do
        if Core.Fuzzy.Rank(word, entry.name, nil, spots) then
            for _, at in ipairs(spots) do all[#all + 1] = at end
        end
    end
    return Core.Fuzzy.Highlight(entry.name, all)
end
