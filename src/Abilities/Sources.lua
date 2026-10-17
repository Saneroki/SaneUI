local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Sources
--  Which spells you have, which are still to come, and in which spellbook tab
--  each of them belongs.
--
--  An entry is a small table: { kind = "spell" | "item" | "macro", id, name, icon }.
--  Spells are matched by name, so a reservation for "Fireball" is met by any rank.
--
--  WoW: Forever does not tell an addon which spells a class still gets (checked in
--  the game, 2026-10-08: the spellbook lists learned spells only). The list comes
--  from the trainer data in Data/, plus the game's talent tree, plus whatever the
--  class trainer's own window shows at a visit.
--
--  Two parts, at two speeds. What you have (ScanBook) is read after every change,
--  out of a fight: the reservations need it. The list of what is still to come is
--  the expensive part, so it is only built when something reads it (S.All: the
--  spellbook's pages, Home, a command) and something changed since.
-------------------------------------------------------------------------------
local S = {}
ns.Sources = S
local D = ns.Data
local Core = SaneUI.Core

S.QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

S.known = {}     -- [spell name] = spell ID of the rank you can cast now
S.has = {}       -- [spell name] = true when you have a rank of it, passive spells too
S.knownTab = {}  -- [spell name] = the spellbook tab a rank you have sits in
S.stats = {}     -- what the list was built from, for /sane ab debug

local unlearned = {} -- every spell and rank still to learn, sorted by name and rank (S.All)
local byID = {}      -- the same by spell ID
local stale = true   -- something changed since the list was built: build it again when it is read

local function Bank()
    return Enum.SpellBookSpellBank.Player
end

local function KnownByID(id)
    return C_SpellBook.IsSpellKnown ~= nil and C_SpellBook.IsSpellKnown(id, Bank()) or false
end

-- Learned, as the trainer data sees it: a rank counts once you have any later rank of it.
local Learned = D.Learned

-------------------------------------------------------------------------------
--  Names the game has to fetch first. Asked once each; the answer is an event.
-------------------------------------------------------------------------------
local requested = {} -- [spell ID] = "pending" or "done"

local function RequestSpell(id)
    if requested[id] then return end
    requested[id] = "pending"
    C_Spell.RequestLoadSpellData(id)
end

-- Called with the spell of a load event. True when it answers one of our requests: the list
-- is then built again, the next time something reads it.
function S.Loaded(id)
    if requested[id] ~= "pending" then return false end
    requested[id] = "done"
    stale = true
    return true
end

-- Something the list is made from changed (the trainer's window, a spell added by hand):
-- build it again, and let what shows it draw it again.
local function Changed()
    stale = true
    ns.QueueUpdate(false, 0)
end

-------------------------------------------------------------------------------
--  Talent abilities, from the game's talent tree
-------------------------------------------------------------------------------
-- Every talent of the class as { id = spell, tree = which of the trees }:
-- configuration -> trees -> nodes -> entries -> the spell each one teaches.
local traitSpells
local function TraitSpells()
    if traitSpells and #traitSpells > 0 then return traitSpells end
    traitSpells = {}
    if not (C_Traits and C_Traits.GetTreeNodes and C_ClassTalents and C_ClassTalents.GetActiveConfigID) then
        return traitSpells
    end
    pcall(function()
        local config = C_ClassTalents.GetActiveConfigID()
        local info = config and C_Traits.GetConfigInfo(config)
        local trees = info and info.treeIDs or {}
        for treeIndex, treeID in ipairs(trees) do
            for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
                local node = C_Traits.GetNodeInfo(config, nodeID)
                for _, entryID in ipairs(node and node.entryIDs or {}) do
                    local entry = C_Traits.GetEntryInfo(config, entryID)
                    local definition = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
                    local spell = definition and ns.Plain(definition.spellID or definition.overriddenSpellID)
                    if type(spell) == "number" then
                        -- one tree for the whole class says nothing about the tab
                        traitSpells[#traitSpells + 1] = { id = spell, tree = #trees == 3 and treeIndex or nil }
                    end
                end
            end
        end
    end)
    return traitSpells
end

-------------------------------------------------------------------------------
--  The class trainer's window. His list is grouped the way the spellbook is,
--  so one visit tells the tab of every spell he teaches.
-------------------------------------------------------------------------------
local filterOpened = false -- true while we switched the trainer's "unavailable" filter on ourselves
local lineByName = {}      -- [name of a spellbook tab] = its number; filled by the spellbook scan
local kept                 -- [name#rank] = true: a trainer row that is in the saved settings already

-- The spell behind a trainer row, only when the game confirms it by name.
local function ServiceSpell(index, name)
    local data = Core.Ask(C_TooltipInfo and C_TooltipInfo.GetTrainerService, index)
    local id = type(data) == "table" and ns.Plain(data.id)
    if type(id) == "number" and C_Spell.GetSpellName(id) == name then return id end
    return nil
end

-- The rows read at an earlier visit, by name and rank, so they are not read again: asking the
-- game which spell a row teaches costs a tooltip each, and the window is read at every update.
local function Kept(spells)
    if not kept then
        kept = {}
        for _, spell in pairs(spells) do
            if type(spell) == "table" and type(spell.name) == "string" then
                kept[spell.name .. "#" .. tostring(spell.sub or "")] = true
            end
        end
    end
    return kept
end

-- Returns true when the open window is your class trainer's.
local function ReadTrainer()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) or not ns.char then return false end
    if IsTradeskillTrainer and IsTradeskillTrainer() then return false end
    local pet = Enum.TrainerType and Enum.TrainerType.Pet
    if pet and C_Trainer and C_Trainer.GetTrainerType and C_Trainer.GetTrainerType() == pet then return false end

    -- His rows are grouped under the names of spellbook tabs. A weapon master or a riding
    -- trainer has no row under one of your tabs, and is left alone.
    local rows, isClassTrainer = {}, false
    for index = 1, (GetNumTrainerServices() or 0) do
        local name, kind, icon, level, sub, category = GetTrainerServiceInfo(index)
        name, kind, category = ns.Plain(name), ns.Plain(kind), ns.Plain(category)
        if name and name ~= "" and kind ~= "header" and category and category ~= "" then
            rows[#rows + 1] = { index = index, name = name, icon = ns.Plain(icon), level = ns.Plain(level),
                                sub = ns.Plain(sub), category = category }
            if lineByName[category] then isClassTrainer = true end
        end
    end
    if not isClassTrainer then return false end

    local store = ns.DB.trainer[ns.class]
    local done, changed = Kept(store.spells), false
    for _, row in ipairs(rows) do
        -- Kept also for a tab you do not have yet: it appears with your first spell of that line.
        if store.tabs[row.name] ~= row.category then
            store.tabs[row.name] = row.category
            changed = true
        end
        local sub = type(row.sub) == "string" and row.sub ~= "" and row.sub or nil
        local key = row.name .. "#" .. (sub or "")
        if not done[key] then
            done[key] = true
            local id = ServiceSpell(row.index, row.name)
            local cost = GetTrainerServiceCost and ns.Plain((GetTrainerServiceCost(row.index))) or nil
            store.spells[id or key] = { name = row.name, sub = sub, icon = row.icon, id = id,
                                        level = type(row.level) == "number" and row.level or 0,
                                        cost = type(cost) == "number" and cost or nil }
            changed = true
        end
    end
    if changed then
        if not store.told then
            store.told = true
            ns.Print(ns.TEXT.trainerRead)
        end
        Changed()
    end
    return true
end

local function RestoreFilter()
    if not filterOpened then return end
    filterOpened = false
    SetTrainerServiceTypeFilter("unavailable", false)
end

-- The spells still to come are the rows the trainer marks "unavailable". If you have
-- that filter off, it is switched on for half a second to read them, then put back.
-- The game answers a filter change with TRAINER_UPDATE (its own window waits for that), which
-- reads the rows too; the read after half a second is for an answer that came late, and costs
-- little, as rows already kept are skipped. Only at your class trainer: any other trainer's
-- window is not touched at all.
function S.TrainerShown()
    if not ReadTrainer() then return end
    if GetTrainerServiceTypeFilter and SetTrainerServiceTypeFilter
       and not GetTrainerServiceTypeFilter("unavailable") then
        filterOpened = true
        SetTrainerServiceTypeFilter("unavailable", true)
        C_Timer.After(0.5, function()
            ns.Safe("trainer", ReadTrainer)
            RestoreFilter()
        end)
    end
end

S.TrainerUpdated = ReadTrainer
S.TrainerClosed = RestoreFilter

-------------------------------------------------------------------------------
--  What you have: the spellbook
-------------------------------------------------------------------------------
local probed = {}  -- [spell ID] = tab, or false: what the game's skill-line table said (FindTab)
local lineCount = 0

function S.ScanBook()
    local known, has, knownTab, low = {}, {}, {}, {}
    local lines = {}
    local bank, types = Bank(), Enum.SpellBookItemType
    -- One spellbook item under one of its names. Keeps the rank you can cast: the highest one learned.
    local function Note(key, line, item, isLow)
        has[key] = true
        knownTab[key] = knownTab[key] or line
        if not item.isPassive and (not known[key] or (low[key] and not isLow)) then
            known[key], low[key] = item.spellID or item.actionID, isLow
        end
    end
    for line = 1, (C_SpellBook.GetNumSpellBookSkillLines() or 0) do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(line)
        if info and not info.shouldHide and (info.offSpecID or 0) == 0 then
            if info.name then lines[info.name] = line end
            local first = (info.itemIndexOffset or 0) + 1
            for index = first, first + (info.numSpellBookItems or 0) - 1 do
                local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
                local name = item and ns.Plain(item.name)
                if name and name ~= "" and item.itemType == types.Spell and not item.isOffSpec then
                    -- "Instant Poison II" is "Instant Poison" in the trainer data (D.Info): known by both.
                    local sub = ns.Plain(item.subName)
                    local base = D.FamilyName(name, type(sub) == "string" and sub or nil)
                    local isLow = not item.isPassive and C_SpellBook.IsSpellBookItemLowRank(index, bank) and true or false
                    Note(name, line, item, isLow)
                    if base ~= name then Note(base, line, item, isLow) end
                end
            end
        end
    end
    S.known, S.has, S.knownTab = known, has, knownTab
    lineByName = lines
    -- a new tab moves the numbers of the others: ask the game again
    local count = C_SpellBook.GetNumSpellBookSkillLines() or 0
    if count ~= lineCount then lineCount, probed = count, {} end
    stale = true -- what is still to come depends on what you have
end

-------------------------------------------------------------------------------
--  The spellbook tab of a spell you do not have yet
-------------------------------------------------------------------------------
local function LineIndex(skillLine)
    local index = Core.Ask(C_SpellBook.GetSkillLineIndexByID, skillLine)
    return type(index) == "number" and index or nil
end

-- Ask the game's own tables whether a spell is filed under one of the class's three lines.
-- Not every build answers this for class spells; asked once per spell, until the tabs change.
local function ProbeTab(id)
    if probed[id] == nil then
        probed[id] = false
        local inLine = C_TradeSkillUI and C_TradeSkillUI.IsRecipeInSkillLine
        for _, line in ipairs(inLine and ns.TreeLines[ns.class] or {}) do
            if Core.Ask(inLine, id, line) == true then
                probed[id] = LineIndex(line) or false
                break
            end
        end
    end
    return probed[id] or nil
end

-- Returns the tab and how it was found (the name of a counter in S.stats).
local function FindTab(entry)
    local name = entry.name
    if S.knownTab[name] then return S.knownTab[name], "tabKnown" end

    local category = ns.DB.trainer[ns.class].tabs[name]
    if category and lineByName[category] then return lineByName[category], "tabTrainer" end

    local tab = entry.id and ProbeTab(entry.id)
    if tab then return tab, "tabProbe" end

    local names = ns.SkillLineOfName[ns.class]
    tab = names and names[name] and LineIndex(names[name])
    if tab then return tab, "tabStatic" end

    local trees = ns.TreeLines[ns.class]
    tab = entry.tree and trees and trees[entry.tree] and LineIndex(trees[entry.tree])
    if tab then return tab, "tabTalent" end

    return nil, "tabNone"
end

-------------------------------------------------------------------------------
--  Building the lists
-------------------------------------------------------------------------------
-- Where a spell stands. Spells of the talent tree are "talent", spells added by hand "other".
-- A trainer or quest spell is checked as the game's own spellbook does it: the level first
-- ("level": not reached yet), then what you must have learned before it ("talentfirst", or
-- "spellfirst" with entry.missing: the rank before it or another spell), and then it is
-- "quest" (go and do the quest) or "trainable" (the trainer teaches it to you now).
local function State(entry, playerLevel)
    entry.missing = nil
    if entry.talent then return "talent" end
    if not entry.level then return "other" end
    if entry.level > playerLevel then return "level" end
    if entry.talentFirst and not Learned(entry.talentFirst) then return "talentfirst" end
    local missing = (entry.prior and not Learned(entry.prior) and entry.prior)
        or (entry.after and not Learned(entry.after) and entry.after)
    if missing then
        entry.missing = missing
        return "spellfirst"
    end
    return entry.quest and "quest" or "trainable"
end

local function Build()
    local list, ids, byKey, byName = {}, {}, {}, {}
    local stats = { known = 0, unlearned = 0, data = 0, talent = 0, trainer = 0, extra = 0, skill = 0,
                    tabKnown = 0, tabTrainer = 0, tabProbe = 0, tabStatic = 0, tabTalent = 0, tabNone = 0 }
    local skipped = { missing = 0, unnamed = 0, passive = 0 }
    for _ in pairs(S.has) do stats.known = stats.known + 1 end

    local function add(entry)
        local key = entry.name .. "#" .. (entry.sub or "")
        if (entry.id and ids[entry.id]) or byKey[key] then return end
        if entry.id then ids[entry.id] = entry end
        byKey[key], byName[entry.name] = entry, true
        entry.kind = "spell"
        entry.rank = entry.sub and tonumber(entry.sub:match("%d+")) or nil
        list[#list + 1] = entry
        stats[entry.source] = stats[entry.source] + 1
    end

    -- 1. What the class trainer teaches and what quests give, from the trainer data. A spell whose
    --    texts the game has not fetched yet is asked for, and listed once the answer has come (S.Loaded).
    for _, spell in ipairs(D.spells) do
        if not Learned(spell.id) then
            local name, sub, icon = D.Info(spell.id)
            if name then
                add({ id = spell.id, name = name, sub = sub, icon = icon, level = spell.level, cost = spell.cost,
                      quest = spell.quest, prior = spell.prior, talentFirst = spell.talent, after = spell.after,
                      source = "data" })
            else
                RequestSpell(spell.id)
            end
        end
    end

    -- 1b. The weapon skills a weapon master teaches the class.
    for _, skill in ipairs(D.WeaponSkills or {}) do
        if not Learned(skill.id) then
            local name, _, icon = D.Info(skill.id)
            if name then
                add({ id = skill.id, name = name, icon = icon, level = skill.level, cost = skill.cost, skill = true, source = "skill" })
            else
                RequestSpell(skill.id)
            end
        end
    end

    -- 2. Rows read at the class trainer that the trainer data does not have (a new build
    --    of the game can be ahead of it). Without a spell ID only a wholly new name is added.
    --    They are saved settings: a row of another shape (a hand edit) is passed over.
    for _, row in pairs(ns.DB.trainer[ns.class].spells) do
        if type(row) == "table" and type(row.name) == "string" and (row.id == nil or type(row.id) == "number") then
            local learned = (row.id and Learned(row.id)) or (not row.id and S.has[row.name])
            if not learned then
                add({ id = row.id, name = row.name, sub = type(row.sub) == "string" and row.sub or nil, icon = row.icon,
                      level = tonumber(row.level), cost = tonumber(row.cost), source = "trainer" })
            end
        end
    end

    -- 3. Spells known only by their ID: talent abilities and the ones added by hand.
    local function addByID(id, source, tree)
        if not C_Spell.DoesSpellExist(id) then
            skipped.missing = skipped.missing + 1
            return
        end
        local name = C_Spell.GetSpellName(id)
        if not name or name == "" then
            skipped.unnamed = skipped.unnamed + 1
            RequestSpell(id)
            return
        end
        if byName[name] or S.has[name] or KnownByID(id) then return end
        if C_Spell.IsSpellPassive(id) then
            skipped.passive = skipped.passive + 1
            return
        end
        add({ id = id, name = name, icon = C_Spell.GetSpellTexture(id), source = source,
              talent = source == "talent" or nil, tree = tree, extra = source == "extra" or nil })
    end

    local traits = TraitSpells()
    for _, talent in ipairs(traits) do addByID(talent.id, "talent", talent.tree) end
    for _, id in ipairs(ns.DB.extras[ns.class]) do
        if type(id) == "number" then addByID(id, "extra") end
    end

    -- Every rank of a spell sits in the same tab, so the tab is found once per name.
    local playerLevel = UnitLevel("player") or 1
    local tabOf = {}
    for _, entry in ipairs(list) do
        entry.passive = entry.id and C_Spell.IsSpellPassive(entry.id) and true or false
        entry.state = State(entry, playerLevel)
        entry.status = nil -- the words for it (Book/Item.lua) are made again from the new state
        local found = tabOf[entry.name]
        if not found then
            found = { FindTab(entry) }
            tabOf[entry.name] = found
        end
        entry.tab = found[1]
        stats[found[2]] = stats[found[2]] + 1
    end
    stats.unlearned = #list

    table.sort(list, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        local rankA, rankB = a.rank or 0, b.rank or 0
        if rankA ~= rankB then return rankA < rankB end
        return (a.level or 999) < (b.level or 999)
    end)

    unlearned, byID, S.stats = list, ids, stats
    local _, build = GetBuildInfo()
    ns.DB.diag = {
        class = ns.class, level = playerLevel, build = build, stats = stats, skipped = skipped,
        offered = { traits = #traits },
    }
end

-- Built when it is read and something changed since; an error leaves the last list in place.
local function Fresh()
    if not stale or not ns.char then return end
    stale = false
    ns.Safe("scan", Build)
end

-- Every spell and rank still to learn, sorted by name and rank.
function S.All()
    Fresh()
    return unlearned
end

-- One icon per spell (showRanks false), and then only for spells you have no rank of at all.
local function Pick(wanted, showRanks)
    local out, seen = {}, {}
    for _, entry in ipairs(S.All()) do
        if wanted(entry) then
            if showRanks then
                out[#out + 1] = entry
            elseif not S.has[entry.name] and not seen[entry.name] then
                seen[entry.name] = true
                out[#out + 1] = entry
            end
        end
    end
    return out
end

-- The grey icons of one spellbook tab: its active spells. tab nil gives the spells no tab was
-- found for. Passive spells and skills are not among them: they have places of their own.
function S.Unlearned(tab, showRanks)
    return Pick(function(entry) return entry.tab == tab and not entry.passive and not entry.skill end, showRanks)
end

-- Every passive spell still to learn, whichever tab it would be in: they are all listed in General.
function S.UnlearnedPassives(showRanks)
    return Pick(function(entry) return entry.passive and not entry.skill end, showRanks)
end

-- The skills still to learn (weapon skills). Also listed in General.
function S.UnlearnedSkills()
    return Pick(function(entry) return entry.skill end, true)
end

-- An unlearned spell by its ID, for links and menus.
function S.UnlearnedByID(id)
    Fresh()
    return byID[id]
end

-- The game's texture for the entry, else the one it was saved with (a file ID or a path; anything
-- else is no texture), else the question mark.
function S.Icon(entry)
    local icon
    if entry.kind == "spell" and entry.id then
        icon = C_Spell.GetSpellTexture(entry.id)
    elseif entry.kind == "item" and entry.id then
        icon = C_Item.GetItemIconByID(entry.id)
    end
    if icon then return icon end
    local own = entry.icon
    if type(own) == "number" or type(own) == "string" then return own end
    return S.QUESTION
end

function S.Name(entry)
    if not entry.name then
        if entry.kind == "spell" and entry.id then
            entry.name = C_Spell.GetSpellName(entry.id)
        elseif entry.kind == "item" and entry.id then
            entry.name = C_Item.GetItemNameByID(entry.id)
        end
    end
    return entry.name or (tostring(entry.kind) .. " " .. tostring(entry.id))
end

-- The number of the macro with this name; 0 when there is none.
local function MacroIndex(name)
    if GetMacroIndexByName then return GetMacroIndexByName(name) or 0 end
    -- A client without that function: look through the account's macros, then the character's.
    local last = (MAX_ACCOUNT_MACROS or 120) + (MAX_CHARACTER_MACROS or 30)
    for index = 1, GetMacroInfo and last or 0 do
        if GetMacroInfo(index) == name then return index end
    end
    return 0
end

-- Do you have it now? Returns what to pick up: a spell ID, an item ID or a macro index.
function S.Available(entry)
    if entry.kind == "spell" then
        S.Name(entry)
        local id = entry.name and S.known[entry.name]
        if id then return id end
        if entry.id and KnownByID(entry.id) then return entry.id end
    elseif entry.kind == "item" then
        if entry.id and (C_Item.GetItemCount(entry.id) or 0) > 0 then return entry.id end
    elseif entry.kind == "macro" then
        local index = entry.name and MacroIndex(entry.name) or 0
        if index > 0 then return index end
    end
    return nil
end

-------------------------------------------------------------------------------
--  Adding a spell by hand: a link or an ID
-------------------------------------------------------------------------------
-- "item:6948" and "spell:133" are inside every link; a bare number is a spell
-- unless preferItem is set.
function S.Parse(text, preferItem)
    if type(text) ~= "string" then return nil end
    local id = text:match("item:(%d+)")
    if id then return "item", tonumber(id) end
    id = text:match("spell:(%d+)")
    if id then return "spell", tonumber(id) end
    local word, number = text:lower():match("^%s*(%a*)%s*(%d+)%s*$")
    if not number then return nil end
    if word == "item" or (word == "" and preferItem) then return "item", tonumber(number) end
    if word == "spell" or word == "" then return "spell", tonumber(number) end
    return nil
end

local function Contains(list, value)
    for index, v in ipairs(list) do
        if v == value then return index end
    end
    return nil
end

-- Returns ok, message.
function S.AddExtra(id)
    local TEXT = ns.TEXT
    if not C_Spell.DoesSpellExist(id) then return false, TEXT.noSpell:format(id) end
    local name = C_Spell.GetSpellName(id)
    if name and C_Spell.IsSpellPassive(id) then return false, TEXT.isPassive:format(name) end
    if name and S.has[name] then return true, TEXT.known:format(name) end
    for _, entry in ipairs(S.All()) do
        if entry.name == name then return true, TEXT.listed:format(name) end
    end
    if not Contains(ns.DB.extras[ns.class], id) then table.insert(ns.DB.extras[ns.class], id) end
    Changed()
    return true, TEXT.added:format(name or TEXT.someSpell:format(id))
end

function S.RemoveExtra(entry)
    local list = ns.DB.extras[ns.class]
    local index = Contains(list, entry.id)
    if index then table.remove(list, index) end
    Changed()
end
