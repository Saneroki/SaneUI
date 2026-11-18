local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Book data
--  What the spellbook holds, as the game's own book gathers it in this client
--  (Blizzard_PlayerSpells, Camelot/SpellBook/Blizzard_SpellBookFrame.lua
--  CreateCategoryMixins, SpellBook/Blizzard_SpellBookCategory.lua):
--    - a tab per skill line the game does not hide (C_SpellBook's skill
--      lines: General, the class's, the professions), its icon the skill
--      line's (the General tab: the class's icon), one group under the skill
--      line's name, the entries its slots in the player's bank
--    - the pet's tab while your pet has a spellbook (Enum.SpellBookSpellBank.Pet),
--      one group under PET
--  and what each tab shows (SpellBookFrameMixin:ShouldDisplaySpellBookItem):
--  no passives while the game's option hides them (spellBookHidePassives),
--  only the highest rank unless it shows all ranks (ShowAllSpellRanks), and the
--  spells of a flyout loose, as the game's book does with its option *Use
--  flyouts* off (a flyout's own entry is left out).
--
--  A search (Data.Search) finds entries of every tab by their name or rank,
--  each tab's finds under its name, as the game's search results show them.
--
--  What a module offers beyond the game's spells (Core.Spellbook: Abilities'
--  spells still to learn, Saneroki, 2026-11-06) comes in too: its entries after
--  a tab's own and in its sections under them, its finds in each tab's, its
--  Home tab in front of the others. Such an entry is { future = entry }, drawn
--  by the offer's own frame (Book.lua); the offer's Home tab is { home = true }.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Data = {}
ns.SpellbookData = Data

local function Book()
    return rawget(_G, "C_SpellBook")
end

-- A game function of C_SpellBook's, asked plainly; nil where it is missing or failed.
local function Ask(name, ...)
    local book = Book()
    return Core.Ask(book and book[name], ...)
end

local function Enum_(group, key)
    local enum = rawget(_G, "Enum")
    return enum and enum[group] and enum[group][key]
end

local function Banks()
    return Enum_("SpellBookSpellBank", "Player") or 0, Enum_("SpellBookSpellBank", "Pet") or 1
end

-- The game's filter for an entry (SpellBookFrameMixin:ShouldDisplaySpellBookItem), searching or not.
local function Shown(slot, bank, searching)
    local kind = Ask("GetSpellBookItemType", slot, bank)
    if kind == nil then return false end
    if kind == Enum_("SpellBookItemType", "Flyout") then return false end
    if not searching and GetCVarBool("spellBookHidePassives") and Ask("IsSpellBookItemPassive", slot, bank) then
        return false
    end
    if not searching and not GetCVarBool("ShowAllSpellRanks") and Ask("IsSpellBookItemLowRank", slot, bank) then
        return false
    end
    return true
end

-- An entry: its slot and bank, and whether the game's book marks it missing from your bars (a skill line of
-- yours, not another specialization's).
local function Entry(slot, bank, status)
    return { slot = slot, bank = bank, status = status }
end

-- How many spells your pet's book holds while it has one (HasPetSpells, PetHasSpellbook); nil without.
local function PetSpells()
    local count = Ask("HasPetSpells")
    if type(count) == "number" and count > 0 and Core.Ask(rawget(_G, "PetHasSpellbook")) then return count end
    return nil
end

-- The tabs there are now, each { key, name, icon, bank, first, count } (a skill line's with its line, the index):
-- the offer's Home first (Core.Spellbook), the skill lines', then the pet's.
function Data.Tabs()
    local tabs = {}
    local offer = Core.Spellbook.Offer()
    local home = offer and offer.Home
    if home then tabs[1] = { key = "home", home = true, name = home.name, icon = home.icon, tip = home.tip } end
    local player, pet = Banks()
    local general = Enum_("SpellBookSkillLineIndex", "General") or 1
    for index = 1, Ask("GetNumSpellBookSkillLines") or 0 do
        local line = Ask("GetSpellBookSkillLineInfo", index)
        if type(line) == "table" and not line.shouldHide then
            local icon = line.iconID
            if index == general then
                local class = Ask("GetClassSkillLineInfo")
                icon = type(class) == "table" and class.iconID or icon
            end
            tabs[#tabs + 1] = { key = "line" .. index, line = index, name = line.name, icon = icon, bank = player,
                                first = (line.itemIndexOffset or 0) + 1, count = line.numSpellBookItems or 0 }
        end
    end
    local count = PetSpells()
    if count then
        local icon = Core.Ask(rawget(_G, "GetPetIcon"))
        tabs[#tabs + 1] = { key = "pet", name = Core.Word("PET", "Pet"), icon = icon, bank = pet, first = 1, count = count }
    end
    return tabs
end

-- Whether your pet has a spellbook now (its tab is there): without one the pet book's key opens nothing (Keys.lua).
function Data.HasPet()
    return PetSpells() ~= nil
end

-- A tab's entries the game's book would show.
local function Entries(tab, searching, match)
    local entries = {}
    if not tab.bank then return entries end -- the offer's Home: a page of its own
    for slot = tab.first, tab.first + tab.count - 1 do
        if Shown(slot, tab.bank, searching) and (not match or match(slot, tab.bank)) then
            entries[#entries + 1] = Entry(slot, tab.bank, true)
        end
    end
    return entries
end

-- The player's skill lines, in the book's order (the offer's sections ask for them).
local function Lines(tabs)
    local lines = {}
    for _, tab in ipairs(tabs) do
        if tab.line then lines[#lines + 1] = tab.line end
    end
    return lines
end

-- The offer's entries, each an element of the pages after those in the list.
local function Future(list, entries)
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do list[#list + 1] = { future = entry } end
    return list
end

-- The game's options for its book, which the offer's entries follow too.
local function Showing()
    return GetCVarBool("ShowAllSpellRanks") and true or false, GetCVarBool("spellBookHidePassives") and true or false
end

-- A tab's groups for the pages: its spells under its name, the offer's after them; then the offer's sections, each
-- under its heading. tabs: the tabs there are (Data.Tabs, read anew without).
function Data.Groups(tab, tabs)
    local entries = Entries(tab)
    local offer = Core.Spellbook.Offer()
    local sections = {}
    if offer and tab.line then
        local ranks, passives = Showing()
        if offer.Spells then Future(entries, offer.Spells(tab.line, ranks)) end
        if offer.Sections then
            local made = offer.Sections(tab.line, Lines(tabs or Data.Tabs()), passives, ranks)
            for _, section in ipairs(type(made) == "table" and made or {}) do
                local elements = Future({}, section.entries)
                if #elements > 0 then sections[#sections + 1] = { header = { text = section.text }, elements = elements } end
            end
        end
    end
    local groups = {}
    if #entries > 0 then groups[1] = { header = { text = tab.name }, elements = entries } end
    for _, group in ipairs(sections) do groups[#groups + 1] = group end
    return groups
end

-- What a search finds in every tab: each tab's finds under its name. The words are looked for in an entry's
-- name and rank, without regard to case.
function Data.Search(tabs, text)
    local wanted = (text or ""):lower()
    local offer = Core.Spellbook.Offer()
    local futures = offer and offer.Search and offer.Search(wanted, Lines(tabs), (Showing())) or nil
    futures = type(futures) == "table" and futures or {}
    local function Match(slot, bank)
        local info = Ask("GetSpellBookItemInfo", slot, bank)
        if type(info) ~= "table" then return false end
        for _, words in ipairs({ info.name, info.subName }) do
            if type(words) == "string" and words:lower():find(wanted, 1, true) then return true end
        end
        return false
    end
    local groups = {}
    for _, tab in ipairs(tabs) do
        local entries = Entries(tab, true, Match)
        if tab.line then Future(entries, futures[tab.line]) end
        if #entries > 0 then groups[#groups + 1] = { header = { text = tab.name }, elements = entries } end
    end
    return groups
end

Data.Ask = Ask
Data.Enum = Enum_
Data.Banks = Banks
