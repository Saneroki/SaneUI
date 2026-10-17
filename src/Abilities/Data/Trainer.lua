local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Trainer data
--  The spells a class learns at its trainer, rank by rank, with the level and
--  the price of each. The game tells an addon only what you know already, so
--  Sane UI carries the rest itself: one file per class in Classes/, and the
--  spells that quests give (QuestSpells.lua).
--
--  A class file hands over two tables.
--  Families: one string per spell, its ranks from first to last, each written
--  "spell:level:copper". Every rank needs the one before it. A bare "spell"
--  is a rank the trainer does not sell (you start with it, or a quest gives
--  it): it only stands before the next rank.
--  Conditions, by spell ID, for the few ranks that differ:
--      talent = spell     a talent to learn first
--      after = spell      another spell to learn first
--      alone = true       the trainer sells it without the rank before it
--      side = "Horde"     only for that faction ("Alliance" or "Horde")
--      raceIDs = { ... }  only for these races (the game's race IDs)
--  A condition holds for the rank it is written on and for every later rank
--  of the same spell, until a later rank sets that field again.
--
--  Who you are is certain only at login, so each file wraps its tables in a
--  function and D.Fill runs the one of your class then: the other classes'
--  tables are never built.
-------------------------------------------------------------------------------
local D = {}
ns.Data = D

-- Every rank and quest reward a character like you can learn, from login on (D.Fill):
-- { id, level, cost = copper, prior = the rank to learn before it, talent, after, quest = { areas } }
D.spells = {}
-- D.class, D.side (your faction) and D.raceID: who you are, also from login on.

local classFiles = {} -- [class] = the function of its file in Classes/
local waiting = {}    -- what the other files of Data/ do once your class and race are known
local nextRank = {}   -- [spell] = the rank that follows it

-- A file of Classes/: D.Class("MAGE", function() return families, conditions end).
function D.Class(class, tables)
    classFiles[class] = tables
end

-- Another file of Data/ that needs to know who you are.
function D.AtLogin(work)
    waiting[#waiting + 1] = work
end

-- Whether the conditions a rank has gathered let you learn it at all.
local function ForYou(rule)
    if rule.side and rule.side ~= D.side then return false end
    return rule.raceIDs == nil or tContains(rule.raceIDs, D.raceID)
end

-- One class file's families into D.spells, and each rank's successor into nextRank.
local function Read(families, conditions)
    conditions = conditions or {}
    for _, family in ipairs(families or {}) do
        local prior, rule = nil, {}
        for token in family:gmatch("%S+") do
            local id, level, cost = token:match("^(%d+):(%d+):(%d+)$")
            id = tonumber(id or token)
            local change = id and conditions[id]
            if change then
                local merged = {}
                for key, value in pairs(rule) do merged[key] = value end
                for key, value in pairs(change) do merged[key] = value end
                rule = merged
            end
            if prior and id then nextRank[prior] = id end
            if id and level and ForYou(rule) then
                D.spells[#D.spells + 1] = { id = id, level = tonumber(level), cost = tonumber(cost),
                                            prior = not rule.alone and prior or nil, talent = rule.talent, after = rule.after }
            end
            prior = id
        end
    end
end

-- At login, once: your class, faction and race, then the spells meant for you. The class
-- functions are let go afterwards, and with them every table only they held.
function D.Fill()
    if not classFiles then return end
    D.class = SaneUI.Core.class
    D.side = ns.Plain(UnitFactionGroup("player"))
    D.raceID = ns.Plain((select(3, UnitRace("player"))))
    local file = classFiles[D.class]
    classFiles = nil
    if file then Read(file()) end
    for _, work in ipairs(waiting) do work() end
    waiting = nil
end

-- [class][spell] = { { raceIDs, level, area or areas, quests }, ... }: the first row that names
-- your race is yours.
function D.AddQuestSpells(byClass)
    for id, rows in pairs(byClass[D.class] or {}) do
        for _, row in ipairs(rows) do
            if tContains(row.raceIDs, D.raceID) then
                D.spells[#D.spells + 1] = { id = id, level = row.level, cost = 0,
                                            quest = { areas = row.areas or { row.area } } }
                break
            end
        end
    end
end

-- In your spellbook or known: one question to the game where the client has it.
local KnownOrInBook = C_SpellBook.IsSpellKnownOrInSpellBook
local function InBook(id)
    local bank = Enum.SpellBookSpellBank.Player
    if KnownOrInBook then return KnownOrInBook(id, bank, false) and true or false end
    return (C_SpellBook.IsSpellInSpellBook ~= nil and C_SpellBook.IsSpellInSpellBook(id, bank, false))
        or C_SpellBook.IsSpellKnown(id, bank) or false
end

-- Learned: you have this rank or any rank after it. Where a new rank takes the old one's place
-- in the spellbook, the game no longer reports the old one as known.
function D.Learned(id)
    while id do
        if InBook(id) then return true end
        id = nextRank[id]
    end
    return false
end

-- A rank named with a numeral, "Instant Poison II" with the rank line "Rank 2", is the spell
-- "Instant Poison": the numeral only says the rank again. Other names stay as they are.
local NUMERALS = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
                   "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX" }
function D.FamilyName(name, sub)
    local rank = sub and tonumber(sub:match("%d+"))
    local numeral = rank and NUMERALS[rank]
    if not numeral then return name end
    local tail = " " .. numeral
    if #name > #tail and name:sub(-#tail) == tail then return name:sub(1, #name - #tail) end
    return name
end

-- Name (the family's), rank line and icon of a spell; nothing while the game has not fetched its
-- texts yet (ask with C_Spell.RequestLoadSpellData; the answer is SPELL_DATA_LOAD_RESULT).
function D.Info(id)
    if C_Spell.IsSpellDataCached and not C_Spell.IsSpellDataCached(id) then return nil end
    local name = C_Spell.GetSpellName(id)
    if not name or name == "" then return nil end
    local sub = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(id)
    if sub == "" then sub = nil end
    return D.FamilyName(name, sub), sub, C_Spell.GetSpellTexture(id)
end
