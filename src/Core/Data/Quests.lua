local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  SaneUI - Core - Data - Quests
--  The quest watchers (Doc/guides/data.md, *Checked in play*): every quest the player is offered, takes, works on and
--  hands in, compared with the set Quests (Data.Check), so a quest our data has is confirmed field by field and one it
--  lacks (a quest only Forever has) is learned whole as the game shows it, while the player does it.
--
--      offered      QUEST_DETAIL: its title, the NPC, thing or item that offers it, its rewards (items, items to
--                   choose, money, experience, a spell); and what the offer proves of its requirements: offered at a
--                   lower level, to a race, class or side, or without a quest the set says must be done first
--      taken        QUEST_ACCEPTED: its level, group size, daily, and its objectives as the quest log lists them
--                   (kind, how many, the game's text)
--      worked on    QUEST_WATCH_UPDATE: where an objective's count went up (a cell of the map, Tally.Cell), and which
--                   creature it was (the dead target its text names) or item (looted, its name in the text: Loot.lua)
--      handed in    QUEST_COMPLETE: who takes it back; QUEST_TURNED_IN: the experience and money it gave; a quest
--                   offered by the same NPC right after it, with no list in between, is the next of its chain
--
--  Texts (the title, an objective's) only on an English client: the set's are English. Experience only below the
--  highest level and at most QuestWatch.XP levels over the quest's (it is cut beyond), money only below the highest
--  level (it grows there), a quest that scales neither. A requirement is narrowed only by the player's own character,
--  and only by a quest an NPC or a thing offered (a quest another player shared says nothing of it).
-------------------------------------------------------------------------------
local Data = Core.Data
local Watchers, Tally, Checks = Data.Watchers, Data.Tally, Data.Checks
local NONE = Checks.NONE

local QuestWatch = {}
Data.QuestWatch = QuestWatch
QuestWatch.XP = 5     -- levels over a quest's at which its experience is still whole
QuestWatch.NEXT = 3   -- seconds after a hand-in within which the quest the same NPC offers is the next of its chain

local Quests = Data.Set("Quests")
local ENGLISH = { enUS = true, enGB = true }
-- The quest log's kinds of objectives as the set's
local KINDS = { monster = "kill", item = "loot", object = "object", event = "event" }

local offered = {}  -- [quest] = { xp, money }: what its offer showed, until its level is known
local progress = {} -- [quest] = { [objective] = count fulfilled }, the quests in the log
local noted = {}    -- what an objective's count going up left to look at: { quest, map, x, y, creature, name }
local handedIn      -- the last quest handed in: { quest, giver, at }
local listed = 0    -- GetTime() of the last list of an NPC's quests (gossip, greeting)

local function English()
    return ENGLISH[Core.Ask(rawget(_G, "GetLocale")) or ""] == true
end

local function Log()
    return rawget(_G, "C_QuestLog") or {}
end

-- The player's level, the highest level, race and class (the game's IDs) and side.
local function Player()
    local level = Core.Ask(rawget(_G, "UnitLevel"), "player")
    local top = Core.Ask(rawget(_G, "GetMaxPlayerLevel"))
    local _, _, race = Core.Ask(rawget(_G, "UnitRace"), "player")
    local _, _, class = Core.Ask(rawget(_G, "UnitClass"), "player")
    local side = Core.Ask(rawget(_G, "UnitFactionGroup"), "player")
    return level, top, race, class, type(side) == "string" and side:lower() or nil
end

-- Who offers or takes a quest: the game's unit "npc", a creature or a thing; nil for a player (a shared quest).
local function Other()
    if Core.Ask(rawget(_G, "UnitIsPlayer"), "npc") then return nil end
    return Watchers.Thing("npc")
end

local function Contains(list, value)
    for _, each in ipairs(list or {}) do
        if each == value then return true end
    end
    return false
end

-- The items of a quest's rewards as the offer lists them ("reward", "choice"); nil while one is not loaded yet (the
-- list is then not whole), NONE for none.
local function Items(kind, count)
    count = tonumber(count) or 0
    if count == 0 then return NONE end
    local list = {}
    for index = 1, count do
        local get = rawget(_G, "GetQuestItemInfo")
        local ok, _, _, units, _, _, item = pcall(get, kind, index)
        item, units = ok and Core.Plain(item), ok and Core.Plain(units)
        if type(item) ~= "number" or item <= 0 then
            local link = Core.Ask(rawget(_G, "GetQuestItemLink"), kind, index)
            item = type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
        end
        if not item then return nil end
        list[#list + 1] = { item = item, count = math.max(1, tonumber(units) or 1) }
    end
    return list
end

-- What an offer proves of a quest's requirements: the fields it narrows, put into told.
local function Narrow(told, record)
    if not record then return end
    local level, _, race, class, side = Player()
    if type(level) == "number" and type(record.minLevel) == "number" and level < record.minLevel then
        told.minLevel = level
    end
    if type(race) == "number" and record.races and not Contains(record.races, race) then
        local list = Core.Copy(record.races)
        list[#list + 1] = race
        told.races = list
    end
    if type(class) == "number" and record.classes and not Contains(record.classes, class) then
        local list = Core.Copy(record.classes)
        list[#list + 1] = class
        told.classes = list
    end
    if side and record.side and record.side ~= side then told.side = NONE end
    local done = Log().IsQuestFlaggedCompleted
    if type(record.requires) ~= "table" or not done then return end
    local kept, wrong, anyOne, oneDone = {}, false, false, false
    for _, rule in ipairs(record.requires) do
        if rule.kind == "one" and (not rule.side or rule.side == side) then
            anyOne = true
            if Core.Ask(done, rule.quest) then oneDone = true end
        end
    end
    for _, rule in ipairs(record.requires) do
        local mine = not rule.side or rule.side == side
        local finished = mine and Core.Ask(done, rule.quest) == true
        if mine and ((rule.kind == "done" and not finished) or (rule.kind == "closed" and finished)
            or (rule.kind == "one" and anyOne and not oneDone)) then
            wrong = true
        else
            kept[#kept + 1] = rule
        end
    end
    if wrong then told.requires = #kept > 0 and kept or NONE end
end

-- The experience and money a quest gives, told where they are whole for this character (see the top).
local function Rewards(told, quest, level, xp, money)
    local mine, top = Player()
    if type(mine) ~= "number" or type(top) ~= "number" or mine >= top then return end
    if type(money) == "number" and money >= 0 then told.rewardMoney = money > 0 and money or NONE end
    if type(xp) == "number" and xp > 0 and type(level) == "number" and level > 0 and mine <= level + QuestWatch.XP then
        told.rewardXP = xp
    end
    offered[quest] = nil
end

-------------------------------------------------------------------------------
--  Offered
-------------------------------------------------------------------------------
Core.On("GOSSIP_SHOW", function() listed = GetTime() end)
Core.On("QUEST_GREETING", function() listed = GetTime() end)

Core.On("QUEST_DETAIL", function(startItem)
    local quest = Core.Ask(rawget(_G, "GetQuestID"))
    if type(quest) ~= "number" or quest <= 0 or not Quests:Ready() then return end
    local record, told = Quests:Get(quest), {}
    if English() then
        local title = Core.Ask(rawget(_G, "GetTitleText"))
        if type(title) == "string" and title ~= "" then told.name = title end
    end
    local kind, id = Other()
    startItem = Core.Plain(startItem)
    if type(startItem) == "number" and startItem > 0 then
        told.startItems = startItem
    elseif kind == "npc" then
        told.startNPCs = { npc = id }
    elseif kind == "object" then
        told.startObjects = { object = id }
    end
    told.rewardItems = Items("reward", Core.Ask(rawget(_G, "GetNumQuestRewards")))
    told.rewardChoices = Items("choice", Core.Ask(rawget(_G, "GetNumQuestChoices")))
    local system = rawget(_G, "C_QuestInfoSystem")
    local spells = system and Core.Ask(system.GetQuestRewardSpells, quest)
    if type(spells) == "table" then
        local spell = Core.Plain(spells[1])
        told.rewardSpell = type(spell) == "number" and spell or NONE
    end
    local xp, money = Core.Ask(rawget(_G, "GetRewardXP")), Core.Ask(rawget(_G, "GetRewardMoney"))
    offered[quest] = { xp = xp, money = money }
    if record and record.level then Rewards(told, quest, record.level, xp, money) end
    if kind or told.startItems then Narrow(told, record) end
    -- Right after a hand-in, offered by the same NPC with no list in between: the next quest of that one's chain
    local before = handedIn
    if before and kind == "npc" and before.giver == id and before.quest ~= quest and GetTime() - before.at <= QuestWatch.NEXT
        and listed < before.at then
        Data.Check("Quests", before.quest, { next = quest })
    end
    handedIn = nil
    Data.Check("Quests", quest, told)
end)

-------------------------------------------------------------------------------
--  Taken: the quest log
-------------------------------------------------------------------------------
-- The game's text of an objective without its count ("Wolf Meat: 3/8" is "Wolf Meat").
local function Words(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub(":%s*%d+%s*/%s*%d+%s*$", ""):gsub("^%s*%d+%s*/%s*%d+%s+", "")
    text = text:match("^%s*(.-)%s*$")
    return text ~= "" and text or nil
end
QuestWatch.Words = Words

-- A quest's entry in the log: its info, its objectives; nil when it is not in the log.
local function Entry(quest)
    local log = Log()
    local index = Core.Ask(log.GetLogIndexForQuestID, quest)
    local info = type(index) == "number" and Core.Ask(log.GetInfo, index)
    if type(info) ~= "table" or info.isHeader then return nil end
    local objectives = Core.Ask(log.GetQuestObjectives, quest)
    return info, type(objectives) == "table" and objectives or {}
end

-- The objectives as the log lists them, put into the set's (what each asks for and its stage stay the set's, or what
-- play found: whats[index]); nil when one is of a kind the set has no word for (the list would not be whole).
local function Objectives(record, list, whats)
    local own, merged, seen = {}, {}, {}
    for _, objective in ipairs(record and record.objectives or {}) do own[objective.index] = objective end
    local english = English()
    for index, objective in ipairs(list) do
        local kind = KINDS[Core.Plain(objective.type) or ""]
        if not kind then return nil end
        local old = own[index] or {}
        local count = Core.Plain(objective.numRequired)
        local what = whats and whats[index]
        if not what and old.kind == kind then what = old.what end
        merged[#merged + 1] = { index = index, kind = kind, what = what,
            count = type(count) == "number" and count >= 1 and count or old.count,
            text = english and Words(Core.Plain(objective.text)) or old.text, stage = old.stage }
        seen[index] = true
    end
    for _, objective in ipairs(record and record.objectives or {}) do
        if not seen[objective.index] then merged[#merged + 1] = Core.Copy(objective) end
    end
    table.sort(merged, function(a, b) return (a.index or 0) < (b.index or 0) end)
    return #merged > 0 and merged or nil
end

-- The counts of a quest's objectives, as the log has them now.
local function Counts(list)
    local counts = {}
    for index, objective in ipairs(list) do counts[index] = tonumber(Core.Plain(objective.numFulfilled)) or 0 end
    return counts
end

-- A quest in the log compared: its level, size, daily, objectives; whats[index]: what play found an objective asks for.
local function Taken(quest, whats)
    if not Quests:Ready() then return end
    local info, list = Entry(quest)
    if not info then return end
    local record, told = Quests:Get(quest), {}
    local scaling = Core.Plain(info.isScaling) == true
    local level = Core.Plain(info.level)
    if type(level) == "number" and level > 0 and not scaling then told.level = level end
    if English() then
        local title = Core.Plain(info.title)
        if type(title) == "string" and title ~= "" then told.name = title end
    end
    local group, tags = Core.Plain(info.suggestedGroup), {}
    if type(group) == "number" and group > 1 then
        told.groupSize = group
        tags[#tags + 1] = "group"
    end
    local daily = rawget(_G, "Enum") and Enum.QuestFrequency and Enum.QuestFrequency.Daily or 1
    if Core.Plain(info.frequency) == daily then tags[#tags + 1] = "daily" end
    if #tags > 0 then told.tags = tags end
    told.objectives = Objectives(record, list, whats)
    local shown = offered[quest]
    if shown and told.level then Rewards(told, quest, told.level, shown.xp, shown.money) end
    progress[quest] = Counts(list)
    Data.Check("Quests", quest, told)
end
QuestWatch.Taken = Taken

local function Last(...)
    local found
    for index = 1, select("#", ...) do
        local value = Core.Plain((select(index, ...)))
        if type(value) == "number" then found = value end
    end
    return found
end

-- Some clients give the quest log's line first: the quest is the last number of the event.
Core.On("QUEST_ACCEPTED", function(...)
    local quest = Last(...)
    if quest then Core.Later(function() Taken(quest) end)() end
end)

-------------------------------------------------------------------------------
--  Worked on: where an objective's count went up, and what it asks for
-------------------------------------------------------------------------------
-- An objective's count gone up: noted at once (the place, the dead target), looked at once nothing restricts it.
local Look
local lookSoon = Core.Later(function() Look() end, 0.2)
local lookLater = Core.Later(function() Look() end, 2)

Core.On("QUEST_WATCH_UPDATE", function(quest)
    quest = Core.Plain(quest)
    if type(quest) ~= "number" or #noted >= 50 then return end
    local map, x, y = Tally.Here()
    local kind, id = Watchers.Thing("target")
    local dead = kind == "npc" and Core.Ask(rawget(_G, "UnitIsDead"), "target") == true
    noted[#noted + 1] = { quest = quest, map = map, x = x, y = y, creature = dead and id or nil,
        name = dead and Core.Ask(rawget(_G, "UnitName"), "target") or nil }
    lookSoon()
end)

-- The objective whose text names a creature or an item (the game's text, the game's name: any language).
local function Named(text, name)
    return type(text) == "string" and type(name) == "string" and name ~= "" and text:find(name, 1, true) ~= nil
end

function Look()
    if Core.Restricted() then return lookLater() end
    local list = noted
    noted = {}
    for _, note in ipairs(list) do
        local info, objectives = Entry(note.quest)
        local before = progress[note.quest]
        if info and before then
            local whats
            for index, objective in ipairs(objectives) do
                local count = tonumber(Core.Plain(objective.numFulfilled)) or 0
                if count > (before[index] or 0) then
                    if note.map then Tally.Cell(("quest:%d/%d"):format(note.quest, index), note.map, note.x, note.y) end
                    if note.creature and Core.Plain(objective.type) == "monster" and Named(Core.Plain(objective.text), note.name) then
                        whats = whats or {}
                        whats[index] = note.creature
                    end
                end
            end
            if whats then Taken(note.quest, whats) else progress[note.quest] = Counts(objectives) end
        elseif info then
            progress[note.quest] = Counts(objectives)
        end
    end
end

-- An item looted (Loot.lua): an objective of a quest in the log whose text names it asks for it.
function QuestWatch.Looted(item, name)
    if type(item) ~= "number" or type(name) ~= "string" then return end
    for quest in pairs(progress) do
        local info, objectives = Entry(quest)
        if info then
            for index, objective in ipairs(objectives) do
                if Core.Plain(objective.type) == "item" and Words(Core.Plain(objective.text)) == name then
                    local record = Quests:Get(quest)
                    local known
                    for _, own in ipairs(record and record.objectives or {}) do
                        if own.index == index and own.what == item then known = true end
                    end
                    if not known then Taken(quest, { [index] = item }) end
                end
            end
        end
    end
end

-- The quests in the log whose objectives for items are not done yet, with those objectives' words (Loot.lua counts
-- an item those quests ask for as dropping for them).
function QuestWatch.Wanting()
    local wanting = {}
    for quest in pairs(progress) do
        local info, objectives = Entry(quest)
        if info then
            for _, objective in ipairs(objectives) do
                if Core.Plain(objective.type) == "item" and not Core.Plain(objective.finished) then
                    local words = Words(Core.Plain(objective.text))
                    wanting[quest] = wanting[quest] or {}
                    if words then wanting[quest][words] = true end
                end
            end
        end
    end
    return wanting
end

-- The quests in the log: their counts, once at the login and whenever the log changes (a quest taken elsewhere,
-- abandoned, done).
local Scan = Core.Later(function()
    local log = Log()
    local total = Core.Ask(log.GetNumQuestLogEntries)
    if type(total) ~= "number" then return end
    local present = {}
    for index = 1, total do
        local info = Core.Ask(log.GetInfo, index)
        local quest = type(info) == "table" and not info.isHeader and Core.Plain(info.questID)
        if type(quest) == "number" then
            present[quest] = true
            if not progress[quest] then
                local objectives = Core.Ask(log.GetQuestObjectives, quest)
                progress[quest] = Counts(type(objectives) == "table" and objectives or {})
            end
        end
    end
    for quest in pairs(progress) do
        if not present[quest] then progress[quest] = nil end
    end
end, 1)
Core.On("QUEST_LOG_UPDATE", function() Scan() end)
Core.On("PLAYER_ENTERING_WORLD", function() Scan() end)

-------------------------------------------------------------------------------
--  Handed in
-------------------------------------------------------------------------------
local function Taker()
    local quest = Core.Ask(rawget(_G, "GetQuestID"))
    if type(quest) ~= "number" or quest <= 0 then return end
    local kind, id = Other()
    if kind == "npc" then
        Data.Check("Quests", quest, { finishNPCs = { npc = id } })
    elseif kind == "object" then
        Data.Check("Quests", quest, { finishObjects = { object = id } })
    end
end
Core.On("QUEST_COMPLETE", Taker)
Core.On("QUEST_PROGRESS", Taker)

Core.On("QUEST_TURNED_IN", function(quest, xp, money)
    quest, xp, money = Core.Plain(quest), Core.Plain(xp), Core.Plain(money)
    if type(quest) ~= "number" then return end
    local kind, id = Other()
    handedIn = kind == "npc" and { quest = quest, giver = id, at = GetTime() } or nil
    progress[quest] = nil
    local record = Quests:Ready() and Quests:Get(quest)
    if record and record.level then
        local told = {}
        Rewards(told, quest, record.level, xp, money)
        if next(told) then Data.Check("Quests", quest, told) end
    end
end)
