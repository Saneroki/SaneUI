local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Offer
--  The spells still to learn in a spellbook of Sane UI's own, through Core
--  (Core.Spellbook; Saneroki, 2026-11-06: the full screen's spellbook (Spellbook/)
--  shows them, as the game's book does here). What goes there, as in the game's
--  book (Book.lua):
--    - each tab its grey entries after its own spells, what you can learn now
--      first; General its two sections, the passive spells and the skills to
--      learn (the weapon skills); the first class tab the spells no tab was
--      found for
--    - a search the spells still to learn by name or rank, each in its tab
--    - the Home tab and its page (Home.lua), the module's lines in the book's
--      menu (Menu.lua) and the switch Show unlearned spells beside its pages
--  The entries are this module's own (Item.lua), drawn into the other book's
--  pages: their look, tooltip, the clock and the quest's mark, the drag that
--  reserves a button (Drag.lua), the right click's menu.
--
--  Forever's only, as the list of spells still to come (Sources.lua). Every
--  part runs behind the module's guard: an error stands the module down, and
--  the book shows the game's spells alone (Core.Spellbook.Offer is nil then).
-------------------------------------------------------------------------------
if not SaneUI.Core.FOREVER then return end

local S, L, I, H = ns.Sources, ns.BookLayout, ns.BookItem, ns.Home
local Core = SaneUI.Core
local TEXT = ns.TEXT

-- The grey entries are shown: the module is ready, and the switch Show unlearned spells is on.
local function Shown()
    return ns.ready and ns.char and ns.options.showHidden
end

-- Entries in the book's order: what you can learn now first, then by level, name and rank (Layout.ByLevel).
local function Sorted(entries)
    local items = {}
    for index, entry in ipairs(entries) do items[index] = { entry = entry } end
    table.sort(items, L.ByLevel)
    for index, item in ipairs(items) do entries[index] = item.entry end
    return entries
end

local function General()
    return Enum.SpellBookSkillLineIndex and Enum.SpellBookSkillLineIndex.General or 1
end

-- The first of your skill lines that is not General: the spells no tab was found for are listed there.
local function FirstClass(lines)
    local general, first = General(), nil
    for _, line in ipairs(lines or {}) do
        if line ~= general and (not first or line < first) then first = line end
    end
    return first
end

local function Spells(line, showRanks)
    if not Shown() then return {} end
    return Sorted(S.Unlearned(line, showRanks))
end

local function Sections(line, lines, hidePassives, showRanks)
    local sections = {}
    if not Shown() then return sections end
    local function Add(text, entries)
        if #entries > 0 then sections[#sections + 1] = { text = text, entries = Sorted(entries) } end
    end
    if line == General() then
        if not hidePassives then Add(TEXT.passives, S.UnlearnedPassives(showRanks)) end
        Add(TEXT.skills, S.UnlearnedSkills())
    end
    if line == FirstClass(lines) then Add(TEXT.others, S.Unlearned(nil, showRanks)) end
    return sections
end

-- Each find in the tab it is listed in: a passive spell or a skill in General, a spell no tab was found for in
-- the first class tab.
local function Search(text, lines, showRanks)
    local found = {}
    if not Shown() then return found end
    local general, first = General(), FirstClass(lines)
    for _, entry in ipairs(S.Matching((text or ""):lower(), showRanks)) do
        local line = (entry.passive or entry.skill) and general or entry.tab or first
        if line then
            found[line] = found[line] or {}
            table.insert(found[line], entry)
        end
    end
    for _, entries in pairs(found) do Sorted(entries) end
    return found
end

local function Set(frame, entry, width)
    I.Set(frame, entry, nil, width)
end

local option = Core.Described(ns.name, "showHidden")
local Guard = ns.Guard

Core.Spellbook.Serve(ns, {
    Spells = Guard(Spells),
    Sections = Guard(Sections),
    Search = Guard(Search),
    Make = Guard(I.Create),
    Set = Guard(Set),
    Home = {
        icon = H.Offer.icon, name = H.Offer.name, tip = H.Offer.tip,
        First = Guard(H.Offer.First),
        Surface = Guard(H.Offer.Surface),
        Draw = Guard(H.Offer.Draw),
    },
    Menu = Guard(ns.BookMenu),
    Switch = {
        text = option.text, tip = option.tip,
        On = Guard(function() return ns.options.showHidden and true or false end),
        Set = Guard(function(on) return Core.Set(ns.name, "showHidden", on and true or false) end),
    },
})

-- Whatever the module draws anew, the other book draws anew too: a spell learned, a reservation made or taken off,
-- a switch, a visit to the trainer. Once a frame, however many came.
ns.Listen("REFRESH", Core.Spellbook.Changed)
