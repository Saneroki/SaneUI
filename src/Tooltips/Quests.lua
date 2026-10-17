local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Quests
--  The quest part of a creature's and an item's panel, from the module's quest
--  facts (Data/Quests.lua, ns.QuestFacts) and your quest log.
--
--  For a creature or an NPC (Quests.Of, shown by Kinds/Unit.lua):
--
--      drop    it drops a thing one of your objectives still asks for, with
--              how often ("Candle 1/4", "33%")
--      opener  it drops an item that starts a quest you may take now
--      due     a quest in your log goes back to it, ready or not
--      give    it gives a quest you may take now
--
--  For an item (Quests.Item, shown by Kinds/Item.lua): the quest it starts
--  (opener) and the quests whose objectives ask for it (wants), each with your
--  standing: in your log, open to you now, open later, done.
--
--  What a creature must be killed for the game says itself, in the tooltip's
--  quest lines.
--
--  Whether you may take a quest: it must be meant for you (your side, race and
--  class), your level must have reached its own lowest level and not passed
--  its highest, the quests it asks first must be done, and nothing that
--  closes it may be in your log or done. An NPC leaves out what the game shows
--  grey for your level (its trivial range); an item's panel keeps it.
--
--  The facts' strings are taken apart when a tooltip first asks. A creature's
--  tooltip is read again and again (a unit frame's many times a second): its
--  list is made once and kept until your quest log or your level changes.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Quests = {}
ns.Quests = Quests

local EMPTY = {}
local NOTHING = { n = 0 } -- the list of whatever the facts do not know

-------------------------------------------------------------------------------
--  You, as the facts ask: filled before each list is made (Who)
-------------------------------------------------------------------------------
local me = {}
local SIDES = { Alliance = "A", Horde = "H" } -- the facts' side letters

local function Who()
    me.level = Plain(UnitLevel("player")) or 1
    if not me.side or me.side == "-" then me.side = SIDES[Plain(UnitFactionGroup("player")) or ""] or "-" end
    me.race = Plain((select(3, UnitRace("player"))))
    me.class = Plain((select(3, UnitClass("player"))))
    -- How far below your level a quest is grey to the game; nil when the game does not say
    local range = Core.Ask(rawget(_G, "UnitQuestTrivialLevelRange"), "player")
    if type(range) ~= "number" then range = Core.Ask(rawget(_G, "GetQuestGreenRange"), "player") end
    me.grey = type(range) == "number" and range or nil
end

-------------------------------------------------------------------------------
--  A quest's record: "levels;rule;races;classes;title" (Data/Quests.lua)
-------------------------------------------------------------------------------
local records = {} -- [id] = the record taken apart, or false when the facts lack it

-- "1.7" -> { [1] = true, [7] = true }; "" -> nil
local function Members(text)
    if text == "" then return nil end
    local set = {}
    for number in text:gmatch("%d+") do set[tonumber(number)] = true end
    return set
end

-- The rule's quests of one sign that hold for your side: "+12+13!H32" with "+" -> { 12, 13 }
local function Signed(rule, sign)
    local list
    for mark, side, id in rule:gmatch("([%+/!])([AH]?)(%d+)") do
        if mark == sign and (side == "" or side == me.side) then
            list = list or {}
            list[#list + 1] = tonumber(id)
        end
    end
    return list or EMPTY
end

local function Record(id)
    local found = records[id]
    if found ~= nil then return found end
    local facts = ns.QuestFacts
    local text = facts and facts.quest and facts.quest[id]
    found = false
    if text then
        local levels, rule, races, classes, title = text:match("^([^;]*);([^;]*);([^;]*);([^;]*);(.*)$")
        if levels then
            local low, level, high = levels:match("^(%d*)%-(%d*)%-?(%d*)$")
            if not low then low, level, high = levels, levels, "" end
            level = tonumber(level)
            if not me.side then Who() end
            found = {
                title = title, level = level, high = tonumber(high),
                from = tonumber(low) or level or 1,         -- the level you may take it from
                side = (races == "A" or races == "H") and races or nil,
                races = (races ~= "A" and races ~= "H") and Members(races) or nil,
                classes = Members(classes),
                after = Signed(rule, "+"), anyOf = Signed(rule, "/"), closers = Signed(rule, "!"),
            }
            if #found.anyOf == 0 then found.anyOf = nil end
        end
    end
    records[id] = found
    return found
end
Quests.Record = Record

-------------------------------------------------------------------------------
--  Where you stand with a quest
-------------------------------------------------------------------------------
local function InLog(id) return Plain(C_QuestLog.IsOnQuest(id)) == true end
local function Completed(id) return Plain(C_QuestLog.IsQuestFlaggedCompleted(id)) == true end

-- Meant for you: your side, your race, your class (each where the game says it)
local function Meant(record)
    if record.side and record.side ~= me.side then return false end
    if record.races and me.race and not record.races[me.race] then return false end
    return not (record.classes and me.class and not record.classes[me.class])
end

-- Closed for good: one of its closers is in your log or done, or you are past its highest level
local function Closed(record)
    if record.high and me.level > record.high then return true end
    for _, other in ipairs(record.closers) do
        if InLog(other) or Completed(other) then return true end
    end
    return false
end

-- The quests it asks first are done: all of its "+", one of its "/"
local function Prepared(record)
    for _, other in ipairs(record.after) do
        if not Completed(other) then return false end
    end
    if not record.anyOf then return true end
    for _, other in ipairs(record.anyOf) do
        if Completed(other) then return true end
    end
    return false
end

-- Grey to the game: so far below your level that it gives next to nothing
local function Grey(record)
    return me.grey ~= nil and record.level ~= nil and me.level - record.level > me.grey
end

-- "log" (in your quest log), "done", "open" (you may take it now), "soon" (not yet: your level,
-- or a quest to do first), or nil: not for you (side, race, class) or closed to you. Who() first.
local function Standing(id, record)
    if InLog(id) then return "log" end
    if Completed(id) then return "done" end
    if not Meant(record) or Closed(record) then return nil end
    if me.level < record.from or not Prepared(record) then return "soon" end
    return "open"
end

-- Open to you now, and not grey: what a creature may show
local function Takeable(id, record)
    return Standing(id, record) == "open" and not Grey(record)
end

-------------------------------------------------------------------------------
--  Names
-------------------------------------------------------------------------------

-- A quest's name in your language when the game has it, else the facts'; nil when neither knows it.
function Quests.Title(id, record)
    local title = C_QuestLog.GetTitleForQuestID and Plain(C_QuestLog.GetTitleForQuestID(id))
    if type(title) == "string" and title ~= "" then return title end
    record = record or Record(id)
    return record and record.title ~= "" and record.title or nil
end

-- An item's name in your language, or nil while the game does not have it yet: then it is asked
-- for, and a later read of the tooltip has it.
function Quests.ItemName(item)
    if not item then return nil end
    local name = C_Item.GetItemNameByID and Plain(C_Item.GetItemNameByID(item))
    if type(name) == "string" and name ~= "" then return name end
    if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(item) end
    return nil
end

-------------------------------------------------------------------------------
--  The lists
-------------------------------------------------------------------------------

-- Puts the next entry into a list, using the list's old tables again.
local function Put(list, kind, quest, text, extra, item)
    local n = list.n + 1
    local entry = list[n]
    if not entry then
        entry = {}
        list[n] = entry
    end
    entry.kind, entry.quest, entry.text, entry.extra, entry.item = kind, quest, text, extra, item
    entry.done, entry.state = nil, nil
    list.n = n
    return entry
end

-- A chance as the facts keep it ("33", "0": below 1 %) as shown, without the percent sign
local function Chance(text)
    if text == "" then return nil end
    return text == "0" and "<1" or text
end

-- Your objective of a quest in your log: its table, or nil
local function Objective(quest, index)
    local objectives = Plain(C_QuestLog.GetQuestObjectives(quest))
    local objective = type(objectives) == "table" and Plain(objectives[index])
    return type(objective) == "table" and objective or nil
end

-- The entries of one group of an NPC's or item's record ("g7,15,H1718": letter "g"), each as
-- side, a, b, c (the numbers of "60.2.33"); only your side's
local function Each(text, letter, fn, list)
    local group = text:match("%f[%w]" .. letter .. "([^ ]*)")
    if not group then return end
    for side, a, b, c in group:gmatch("([AH]?)(%d+)%.?(%d*)%.?(%d*)") do
        if side == "" or side == me.side then fn(list, tonumber(a), tonumber(b), c) end
    end
end

-- A creature's or an NPC's: in this order what it drops for you, the items it drops that start
-- a quest, the quests it takes back, the quests it gives
local function Dropped(list, quest, index, chance)
    if not InLog(quest) then return end
    local objective = Objective(quest, index)
    local text = objective and Plain(objective.text)
    if type(text) == "string" and not Plain(objective.finished) and Quests.Title(quest) then
        Put(list, "drop", quest, text, Chance(chance))
    end
end
local function Opener(list, item, quest, chance)
    local record = Record(quest)
    if record and Takeable(quest, record) then
        Put(list, "opener", quest, Quests.Title(quest, record), Chance(chance), item)
    end
end
local function Due(list, quest)
    local title = InLog(quest) and Quests.Title(quest)
    if title then
        Put(list, "due", quest, title, C_QuestLog.ReadyForTurnIn and Plain(C_QuestLog.ReadyForTurnIn(quest)) == true)
    end
end
local function Given(list, quest)
    local record = Record(quest)
    if record and Takeable(quest, record) then Put(list, "give", quest, Quests.Title(quest, record)) end
end

local function FillCreature(text, list)
    Each(text, "d", Dropped, list)
    Each(text, "s", Opener, list)
    Each(text, "t", Due, list)
    Each(text, "g", Given, list)
end

-- An item's: first the quest it starts, then the quests that want it, those in your log first (with
-- your count "1/4" in extra, done when the objective is complete), then open, soon, done. A name
-- comes once: of quests with the same name only the first counts (the same quest at other places).
local ORDER = { "log", "open", "soon", "done" }
local standings = {} -- the quests that want the item and are for you: quest, state, objective; used again
local named = {}
local function FillItem(text, list, item)
    local starts = tonumber(text:match("%f[%w]b(%d+)"))
    local record = starts and Record(starts)
    local state = record and Standing(starts, record)
    if state then Put(list, "opener", starts, Quests.Title(starts, record), nil, item).state = state end
    local wants = text:match("%f[%w]n([^ ]*)")
    if not wants then return end
    -- Each quest's standing once, then the quests by standing
    local count = 0
    for quest, index in wants:gmatch("(%d+)%.(%d+)") do
        quest = tonumber(quest)
        record = Record(quest)
        state = record and Standing(quest, record)
        if state then
            standings[count + 1], standings[count + 2], standings[count + 3] = quest, state, tonumber(index)
            count = count + 3
        end
    end
    wipe(named)
    for _, wanted in ipairs(ORDER) do
        for at = 1, count, 3 do
            local quest = standings[at]
            local title = standings[at + 1] == wanted and Quests.Title(quest)
            if title and not named[title] then
                named[title] = true
                local tally, done
                local objective = wanted == "log" and Objective(quest, standings[at + 2])
                if objective then
                    local have, need = Plain(objective.numFulfilled), Plain(objective.numRequired)
                    if type(have) == "number" and type(need) == "number" then tally = ("%d/%d"):format(have, need) end
                    done = Plain(objective.finished) == true
                end
                local entry = Put(list, "wants", quest, title, tally)
                entry.state, entry.done = wanted, done
            end
        end
    end
end

-- The lists made so far, each with the change it was made after; a list made before the last
-- change of your quest log or level is made anew
local made = { npc = {}, item = {} }
local changes = 0

-- The list of the NPC or item with this ID, from its record, made anew when it is out of date. A
-- broken record ends the list there (what was found before it stays); the problem is noted and
-- told once.
local function List(kind, id, fill)
    local facts = ns.QuestFacts
    local text = id and facts and facts[kind] and facts[kind][id]
    if not text then return NOTHING end
    local list = made[kind][id]
    if list and list.change == changes then return list end
    if not list then
        list = {}
        made[kind][id] = list
    end
    list.n, list.change = 0, changes
    Who()
    local ok, problem = xpcall(fill, Core.Trace, text, list, id)
    if not ok then ns.Report("quest facts", problem) end
    return list
end

-- The quest list of the creature or NPC with this ID: n entries { kind, quest, text, extra,
-- item }. kind: drop, opener, due, give (see the top); text: the objective's words
-- (drop) or the quest's name; extra: how often it drops (drop, opener: "33", "<1", or nil when
-- not known), whether it is ready (due); item: the item that starts the quest (opener).
-- Kept until something changes: not to be changed.
function Quests.Of(npc)
    return List("npc", npc, FillCreature)
end

-- The quest list of the item with this ID: n entries { kind, quest, text, extra, done, state,
-- item } (kind: opener, wants; state: log, open, soon, done; see FillItem).
-- Kept like a creature's: not to be changed.
function Quests.Item(item)
    return List("item", item, FillItem)
end

-------------------------------------------------------------------------------
--  A quest's level and name as a row
-------------------------------------------------------------------------------

-- A quest's level, and r, g, b: the colour of how hard it is for you. nil when the facts do not
-- know its level.
function Quests.Level(quest)
    local record = quest and Record(quest)
    local level = record and record.level
    if not level then return nil end
    local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
    if not color then return level, unpack(ns.COLOR.DETAIL) end
    return level, color.r, color.g, color.b
end

-- A quest's name as a row of a panel, in the game's gold, with its level at the right in the
-- colour of how hard it is for you (when the facts know it). For the quest sections (Kinds).
function Quests.Heading(title, quest)
    local Read, gold = ns.Reader, ns.COLOR.GOLD
    local row = Read.Text("sub", title, gold[1], gold[2], gold[3])
    local level, r, g, b = Quests.Level(quest)
    if level then row.right, row.rr, row.rg, row.rb = Read.Memo("questLevel" .. level, ns.TEXT.LEVEL, level), r, g, b end
    return row
end

-- The lists go out of date when your quest log changes (a quest taken, progressed, handed in or
-- given up; also often enough for a quest's name in your language to have come) or your level does.
function Quests.Start()
    local function Changed() changes = changes + 1 end
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "PLAYER_LEVEL_CHANGED" }) do
        Core.On(event, Changed)
    end
end
