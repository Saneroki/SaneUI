local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Quests
--  The quest part of a creature's and an item's panel, from Core's data (the
--  sets Quests and Drops, Doc/guides/data.md) and your quest log.
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
--  The module only reads: Core loads the packs (Prepare at login) and answers
--  nil until they are there, so a panel has no quest part until then, and none
--  at all with the pack switched off. A creature's tooltip is read again and
--  again (a unit frame's many times a second): its list is made once and kept
--  until your quest log or your level changes, or the data does.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Data = Core.Data
local QUESTS, DROPS = Data.Set("Quests"), Data.Set("Drops")
local Quests = {}
ns.Quests = Quests

local EMPTY = {}
local NOTHING = { n = 0 } -- the list of what has no ID

-------------------------------------------------------------------------------
--  You, as the data asks: filled before each list is made (Who)
-------------------------------------------------------------------------------
local me = {}
local SIDES = { Alliance = "alliance", Horde = "horde" } -- the data's sides

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
--  Where you stand with a quest (its record: Core's, shared and read-only)
-------------------------------------------------------------------------------
local function InLog(id) return Plain(C_QuestLog.IsOnQuest(id)) == true end
local function Completed(id) return Plain(C_QuestLog.IsQuestFlaggedCompleted(id)) == true end

local function Has(list, value)
    for _, each in ipairs(list) do
        if each == value then return true end
    end
    return false
end

-- For you: a part that names no side, or yours
local function Yours(side) return side == nil or side == me.side end

-- Meant for you: your side, your race, your class (each where the data says it)
local function Meant(record)
    if record.side and record.side ~= me.side then return false end
    if record.races and me.race and not Has(record.races, me.race) then return false end
    return not (record.classes and me.class and not Has(record.classes, me.class))
end

-- Closed for good: you are past its highest level, or one of the quests that close it is in your
-- log or done
local function Closed(record)
    if record.maxLevel and me.level > record.maxLevel then return true end
    for _, need in ipairs(record.requires or EMPTY) do
        if need.kind == "closed" and Yours(need.side) and (InLog(need.quest) or Completed(need.quest)) then return true end
    end
    return false
end

-- The quests it asks first are done: all of those it needs done, one of those it needs one of
local function Prepared(record)
    local anyOf, one = false, false
    for _, need in ipairs(record.requires or EMPTY) do
        if Yours(need.side) then
            if need.kind == "done" and not Completed(need.quest) then return false end
            if need.kind == "one" then
                anyOf = true
                one = one or Completed(need.quest)
            end
        end
    end
    return one or not anyOf
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
    if me.level < (record.minLevel or record.level or 1) or not Prepared(record) then return "soon" end
    return "open"
end

-- Open to you now, and not grey: what a creature may show
local function Takeable(id, record)
    return Standing(id, record) == "open" and not Grey(record)
end

-------------------------------------------------------------------------------
--  Names
-------------------------------------------------------------------------------

-- A quest's name in your language when the game has it, else the data's; nil when neither knows it.
function Quests.Title(id, record)
    local title = C_QuestLog.GetTitleForQuestID and Plain(C_QuestLog.GetTitleForQuestID(id))
    if type(title) == "string" and title ~= "" then return title end
    record = record or QUESTS:Get(id)
    return record and record.name or nil
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

-- A chance as shown, without the percent sign: whole percent, "<1" below one; nil when not known
local function Chance(chance)
    if type(chance) ~= "number" then return nil end
    if chance < 1 then return "<1" end
    return tostring(math.floor(chance + 0.5))
end

-- Your objective of a quest in your log: its table, or nil
local function Objective(quest, index)
    local objectives = Plain(C_QuestLog.GetQuestObjectives(quest))
    local objective = type(objectives) == "table" and Plain(objectives[index])
    return type(objective) == "table" and objective or nil
end

-- The number of the quest's objective that asks you to loot this item (the game's number), or nil
local function Wants(record, item)
    for position, objective in ipairs(record and record.objectives or EMPTY) do
        if objective.kind == "loot" and objective.what == item then return objective.index or position end
    end
    return nil
end

-- Whether an NPC stands in a quest's list of givers or takers for you (a part may hold for one side)
local function Listed(places, npc)
    for _, place in ipairs(places or EMPTY) do
        if place.npc == npc and Yours(place.side) then return true end
    end
    return false
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

local function FillCreature(list, npc)
    local drops = DROPS:Get("npc:" .. npc)
    local items = drops and drops.items or EMPTY
    for _, drop in ipairs(items) do
        for _, quest in ipairs(QUESTS:Keys("byObjective", drop.item)) do
            local index = Wants(QUESTS:Get(quest), drop.item)
            if index then Dropped(list, quest, index, drop.chance) end
        end
    end
    for _, drop in ipairs(items) do
        for _, quest in ipairs(QUESTS:Keys("byStartItem", drop.item)) do
            local record = QUESTS:Get(quest)
            if record and Takeable(quest, record) then
                Put(list, "opener", quest, Quests.Title(quest, record), Chance(drop.chance), drop.item)
            end
        end
    end
    for _, quest in ipairs(QUESTS:Keys("byFinishNPC", npc)) do
        local title = InLog(quest) and Listed(QUESTS:Get(quest, "finishNPCs"), npc) and Quests.Title(quest)
        if title then
            Put(list, "due", quest, title, C_QuestLog.ReadyForTurnIn and Plain(C_QuestLog.ReadyForTurnIn(quest)) == true)
        end
    end
    for _, quest in ipairs(QUESTS:Keys("byStartNPC", npc)) do
        local record = QUESTS:Get(quest)
        if record and Listed(record.startNPCs, npc) and Takeable(quest, record) then
            Put(list, "give", quest, Quests.Title(quest, record))
        end
    end
end

-- An item's: first the quest it starts, then the quests that want it, those in your log first (with
-- your count "1/4" in extra, done when the objective is complete), then open, soon, done. A name
-- comes once: of quests with the same name only the first counts (the same quest at other places).
local ORDER = { "log", "open", "soon", "done" }
local standings = {} -- the quests that want the item and are for you: quest, state, objective; used again
local named = {}
local function FillItem(list, item)
    for _, quest in ipairs(QUESTS:Keys("byStartItem", item)) do
        local record = QUESTS:Get(quest)
        local state = record and Standing(quest, record)
        if state then Put(list, "opener", quest, Quests.Title(quest, record), nil, item).state = state end
    end
    -- Each quest's standing once, then the quests by standing
    local count = 0
    for _, quest in ipairs(QUESTS:Keys("byObjective", item)) do
        local record = QUESTS:Get(quest)
        local index = Wants(record, item)
        local state = index and Standing(quest, record)
        if state then
            standings[count + 1], standings[count + 2], standings[count + 3] = quest, state, index
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
-- change of your quest log, your level or the data is made anew
local made = { npc = {}, item = {} }
local changes = 0

-- The list of the NPC or item with this ID, made anew when it is out of date. A failure ends the
-- list there (what was found before it stays); the problem is noted and told once.
local function List(kind, id, fill)
    local list = made[kind][id]
    if list and list.change == changes then return list end
    if not list then
        list = {}
        made[kind][id] = list
    end
    list.n, list.change = 0, changes
    if not QUESTS:Ready() then return list end -- not loaded yet (Start asked for it), or not there
    Who()
    local ok, problem = xpcall(fill, Core.Trace, list, id)
    if not ok then ns.Report("quest data", problem) end
    return list
end

-- The quest list of the creature or NPC with this ID: n entries { kind, quest, text, extra,
-- item }. kind: drop, opener, due, give (see the top); text: the objective's words
-- (drop) or the quest's name; extra: how often it drops (drop, opener: "33", "<1", or nil when
-- not known), whether it is ready (due); item: the item that starts the quest (opener).
-- Kept until something changes: not to be changed.
function Quests.Of(npc)
    if not npc then return NOTHING end
    return List("npc", npc, FillCreature)
end

-- The quest list of the item with this ID: n entries { kind, quest, text, extra, done, state,
-- item } (kind: opener, wants; state: log, open, soon, done; see FillItem).
-- Kept like a creature's: not to be changed.
function Quests.Item(item)
    if not item then return NOTHING end
    return List("item", item, FillItem)
end

-------------------------------------------------------------------------------
--  A quest's level and name as a row
-------------------------------------------------------------------------------

-- A quest's level, and r, g, b: the colour of how hard it is for you. nil when the data does not
-- know its level.
function Quests.Level(quest)
    local level = quest and QUESTS:Get(quest, "level")
    if not level then return nil end
    local color = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
    if not color then return level, unpack(ns.COLOR.DETAIL) end
    return level, color.r, color.g, color.b
end

-- A quest's name as a row of a panel, in the game's gold, with its level at the right in the
-- colour of how hard it is for you (when the data knows it). For the quest sections (Kinds).
function Quests.Heading(title, quest)
    local Read, gold = ns.Reader, ns.COLOR.GOLD
    local row = Read.Text("sub", title, gold[1], gold[2], gold[3])
    local level, r, g, b = Quests.Level(quest)
    if level then row.right, row.rr, row.rg, row.rb = Read.Memo("questLevel" .. level, ns.TEXT.LEVEL, level), r, g, b end
    return row
end

-- The lists go out of date when your quest log changes (a quest taken, progressed, handed in or
-- given up; also often enough for a quest's name in your language to have come) or your level does,
-- and when the data arrives or changes: then arrived() is called too, for the shown panels.
function Quests.Start(arrived)
    local function Changed() changes = changes + 1 end
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "PLAYER_LEVEL_CHANGED" }) do
        Core.On(event, Changed)
    end
    local function Arrived()
        Changed()
        if arrived then arrived() end
    end
    QUESTS:OnStamp(Arrived)
    DROPS:OnStamp(Arrived)
    -- Loaded soon after the loading screen, so they are there before the first tooltip that needs them
    Data.Prepare("Quests")
    Data.Prepare("Drops")
end
