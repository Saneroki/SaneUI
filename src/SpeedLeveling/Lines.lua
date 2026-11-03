local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Lines
--  What the game says about the things a guide's lines ask (Saneroki,
--  2026-10-25: our own engine runs the guides): quests (in the log, ready,
--  handed in, their objectives), items (in the bags and the bank, worn), spells
--  learnt, skills, auras, cooldowns, the level and its experience, money, where
--  you are, whether you are dead. Each answer is asked of the game when a line
--  is looked at; nothing of it is kept but what the game tells only as it
--  happens (a quest just taken or handed in, which its log shows a moment
--  later).
--
--      Lines.OnQuest(quest), Lines.Ready(quest), Lines.HandedIn(quest, account)
--      Lines.Objective(quest, goal)   finished, have, need, text, kind of a quest's objective; nil for none
--      Lines.Objectives(quest)        how many objectives the game gives for it
--      Lines.Brief(quest)             what a quest in your log asks, in the game's words; nil where it gives none
--      Lines.InDungeon(quest)         whether Core's data files a quest under a dungeon or a raid
--      Lines.Count(item, bank), Lines.Worn(slot)
--      Lines.Known(spell), Lines.Skill(name, max), Lines.Aura(spell)
--      Lines.Cooldown(kind, id)       seconds left, 0 when ready; nil when the game does not say
--      Lines.Reached(level, points, share)   whether the character is at a level (points short of or into it, a share)
--      Lines.Money(), Lines.Where(), Lines.InZone(to), Lines.InArea(area), Lines.Dead()
--      Lines.QuestName(quest), Lines.ItemName(item), Lines.SpellName(spell), Lines.NpcName(npc), Lines.AreaName(area)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Lines = {}
ns.Lines = Lines

Lines.TAKEN = 3     -- seconds a quest just taken counts as in the log, before the log shows it
Lines.NAMES = 1.5   -- seconds before a name the game did not know yet is asked again

local QUESTS, NPCS = Core.Data.Set("Quests"), Core.Data.Set("NPCs")
local EMPTY = {}

local taken = {}    -- [quest] = when it was taken, as the game told
local given = {}    -- [quest] = true: handed in, as the game told (this session)
local npcNames = {} -- [creature ID] = its name, or the time it was last asked for in vain

local function Log() return rawget(_G, "C_QuestLog") or EMPTY end
local function Now() return Plain(Core.Ask(rawget(_G, "GetTime"))) or 0 end

-------------------------------------------------------------------------------
--  Quests
-------------------------------------------------------------------------------
function Lines.OnQuest(quest)
    if type(quest) ~= "number" then return false end
    local log = Log()
    local on
    if log.IsOnQuest then
        on = Core.Ask(log.IsOnQuest, quest) == true
    else
        local index = Core.Ask(log.GetLogIndexForQuestID or rawget(_G, "GetQuestLogIndexByID"), quest)
        on = type(index) == "number" and index > 0
    end
    if on then return true end
    return taken[quest] ~= nil and Now() - taken[quest] < Lines.TAKEN
end

function Lines.HandedIn(quest, account)
    if type(quest) ~= "number" then return false end
    if given[quest] then return true end
    local log = Log()
    if account and log.IsQuestFlaggedCompletedOnAccount then
        return Core.Ask(log.IsQuestFlaggedCompletedOnAccount, quest) == true
    end
    return Core.Ask(log.IsQuestFlaggedCompleted or rawget(_G, "IsQuestFlaggedCompleted"), quest) == true
end

function Lines.Ready(quest)
    return Lines.OnQuest(quest) and Core.Ask(Log().IsComplete, quest) == true
end

-- A quest's objective as the game has it: done, how many there are and are wanted, its words, its kind
-- ("monster", "item", "object", ...); nil where the game gives none.
function Lines.Objective(quest, goal)
    local objectives = Core.Ask(Log().GetQuestObjectives, quest)
    local objective = type(objectives) == "table" and objectives[goal]
    if type(objective) ~= "table" then return nil end
    return Plain(objective.finished) == true, Plain(objective.numFulfilled), Plain(objective.numRequired),
           Plain(objective.text), Plain(objective.type)
end

function Lines.Objectives(quest)
    local objectives = Core.Ask(Log().GetQuestObjectives, quest)
    return type(objectives) == "table" and #objectives or 0
end

function Lines.Brief(quest)
    local log = Log()
    local index = Core.Ask(log.GetLogIndexForQuestID or rawget(_G, "GetQuestLogIndexByID"), quest)
    if type(index) ~= "number" or index < 1 then return nil end
    local _, asks = Core.Ask(rawget(_G, "GetQuestLogQuestText"), index)
    asks = Plain(asks)
    return type(asks) == "string" and asks ~= "" and asks or nil
end

-- Whether Core's data files a quest under a dungeon or a raid (its tags); false where it does not say, as in a game
-- without data.
function Lines.InDungeon(quest)
    for _, tag in pairs(QUESTS:Get(quest, "tags") or EMPTY) do
        if tag == "dungeon" or tag == "raid" then return true end
    end
    return false
end

-------------------------------------------------------------------------------
--  Items, spells, skills, auras, cooldowns
-------------------------------------------------------------------------------
function Lines.Count(item, bank)
    local items = rawget(_G, "C_Item")
    local count = Core.Ask(items and items.GetItemCount or rawget(_G, "GetItemCount"), item, bank and true or false)
    return type(count) == "number" and count or 0
end

-- The item worn in an equipment slot (the game's slot number), or nil.
function Lines.Worn(slot)
    return Plain(Core.Ask(rawget(_G, "GetInventoryItemID"), "player", slot))
end

function Lines.Known(spell)
    return Core.Ask(rawget(_G, "IsPlayerSpell"), spell) == true or Core.Ask(rawget(_G, "IsSpellKnown"), spell) == true
end

-- A skill's rank (or its highest rank, max), by its name in the game's words; -1 for one not learnt.
function Lines.Skill(name, max)
    name = tostring(name or ""):lower()
    local info = rawget(_G, "C_SkillInfo")
    if info and info.GetNumSkillLines and info.GetSkillLineInfo then
        for index = 1, Core.Ask(info.GetNumSkillLines) or 0 do
            local line = Core.Ask(info.GetSkillLineInfo, index)
            if type(line) == "table" and not Plain(line.isHeader) and tostring(Plain(line.name) or ""):lower() == name then
                return Plain(max and line.maxRank or line.rank) or -1
            end
        end
    end
    local professions = rawget(_G, "GetProfessions")
    if professions then
        local ok, a, b, c, d, e = pcall(professions)
        for _, index in ipairs(ok and { a, b, c, d, e } or EMPTY) do
            local answers = { pcall(GetProfessionInfo, index) }
            if answers[1] and tostring(Plain(answers[2]) or ""):lower() == name then
                return Plain(max and answers[5] or answers[4]) or -1
            end
        end
    end
    return -1
end

-- An aura of yours by its spell: its stacks and seconds left (0 for one that lasts), or nil for none.
function Lines.Aura(spell)
    local auras = rawget(_G, "C_UnitAuras")
    local aura = auras and Core.Ask(auras.GetPlayerAuraBySpellID, spell)
    if type(aura) ~= "table" then return nil end
    local ending = Plain(aura.expirationTime) or 0
    local left = ending > 0 and math.max(0, ending - Now()) or 0
    return Plain(aura.applications) or 0, left
end

-- Seconds left on a spell's or item's cooldown, 0 when ready; nil when the game does not say.
function Lines.Cooldown(kind, id)
    local start, duration
    if kind == "item" then
        local bags = rawget(_G, "C_Container")
        start, duration = Core.Ask(bags and bags.GetItemCooldown or rawget(_G, "GetItemCooldown"), id)
    else
        local spells = rawget(_G, "C_Spell")
        local info = spells and spells.GetSpellCooldown and Core.Ask(spells.GetSpellCooldown, id)
        if type(info) == "table" then
            start, duration = Plain(info.startTime), Plain(info.duration)
        else
            start, duration = Core.Ask(rawget(_G, "GetSpellCooldown"), id)
        end
    end
    if type(start) ~= "number" or type(duration) ~= "number" then return nil end
    if start <= 0 or duration <= 0 then return 0 end
    return math.max(0, start + duration - Now())
end

-------------------------------------------------------------------------------
--  The character
-------------------------------------------------------------------------------
-- Whether the character is at a level: points less than 0, so many points short of it (from the level before);
-- points more than 0, so many into it; share, that share of its bar into it; else the level reached.
function Lines.Reached(level, points, share)
    local now = Plain(Core.Ask(UnitLevel, "player")) or 0
    local have, most = Plain(Core.Ask(UnitXP, "player")) or 0, Plain(Core.Ask(UnitXPMax, "player")) or 1
    if points and points < 0 then
        return now >= level or (now == level - 1 and have >= most + points)
    elseif points and points > 0 then
        return now > level or (now == level and have >= points)
    elseif share and share > 0 then
        return now > level or (now == level and most > 0 and have >= most * share)
    end
    return now >= level
end

function Lines.Money() return Plain(Core.Ask(rawget(_G, "GetMoney"))) or 0 end

-- The zone's name, the map the character is on, the subzone's name.
function Lines.Where()
    local maps = rawget(_G, "C_Map")
    local map = maps and Plain(Core.Ask(maps.GetBestMapForUnit, "player"))
    return Plain(Core.Ask(rawget(_G, "GetRealZoneText"))) or Plain(Core.Ask(rawget(_G, "GetZoneText"))), map,
           Plain(Core.Ask(rawget(_G, "GetSubZoneText")))
end

-- Whether the character is in a zone: a map's number (that map or one inside it), else its name.
function Lines.InZone(to)
    local zone, map = Lines.Where()
    if type(to) == "number" then
        local maps, seen = rawget(_G, "C_Map"), 0
        while type(map) == "number" and seen < 8 do
            if map == to then return true end
            local info = maps and Core.Ask(maps.GetMapInfo, map)
            map, seen = type(info) == "table" and Plain(info.parentMapID) or nil, seen + 1
        end
        return false
    end
    return type(zone) == "string" and zone:lower() == tostring(to):lower()
end

function Lines.AreaName(area)
    local maps = rawget(_G, "C_Map")
    return maps and Plain(Core.Ask(maps.GetAreaInfo, area)) or nil
end

-- Whether the character is in a subzone: the game's area number, or its name.
function Lines.InArea(area)
    local _, _, subzone = Lines.Where()
    local name = type(area) == "number" and Lines.AreaName(area) or area
    return type(name) == "string" and type(subzone) == "string" and name:lower() == subzone:lower()
end

function Lines.Dead()
    return Core.Ask(UnitIsDeadOrGhost, "player") == true
end

-------------------------------------------------------------------------------
--  Names
-------------------------------------------------------------------------------
function Lines.QuestName(quest)
    local name = Plain(Core.Ask(Log().GetTitleForQuestID, quest))
    if type(name) ~= "string" or name == "" then name = QUESTS:Get(quest, "name") end
    if type(name) ~= "string" or name == "" then
        Core.Ask(Log().RequestLoadQuestByID, quest)
        return ns.TEXT.quest:format(quest)
    end
    return name
end

function Lines.ItemName(item)
    local items = rawget(_G, "C_Item")
    local name = Plain(Core.Ask(items and items.GetItemNameByID or rawget(_G, "GetItemInfo"), item))
    if type(name) == "string" then return name end
    Core.Ask(items and items.RequestLoadItemDataByID, item)
    return ns.TEXT.item:format(item)
end

function Lines.SpellName(spell)
    local spells = rawget(_G, "C_Spell")
    local name = Plain(Core.Ask(spells and spells.GetSpellName or rawget(_G, "GetSpellInfo"), spell))
    return type(name) == "string" and name or ns.TEXT.spell:format(spell)
end

-- A creature's name by its ID: Core's (English), else the game's own (its tooltip of the creature, once it knows
-- it); nil while neither knows.
function Lines.NpcName(npc)
    local known = npcNames[npc]
    if type(known) == "string" then return known end
    local name = NPCS:Get(npc, "name")
    if type(name) == "string" and name ~= "" then
        npcNames[npc] = name
        return name
    end
    if type(known) == "number" and Now() - known < Lines.NAMES then return nil end
    local info = rawget(_G, "C_TooltipInfo")
    local data = info and Core.Ask(info.GetHyperlink, "unit:Creature-0-0-0-0-" .. npc .. "-0000000000")
    local first = type(data) == "table" and type(data.lines) == "table" and data.lines[1]
    name = type(first) == "table" and Plain(first.leftText)
    if type(name) == "string" and name ~= "" then
        npcNames[npc] = name
        return name
    end
    npcNames[npc] = Now()
    return nil
end

-------------------------------------------------------------------------------
--  What the game tells only as it happens
-------------------------------------------------------------------------------
function Lines.Start()
    ns.On("QUEST_ACCEPTED", function(first, second)
        local quest = Plain(second) or Plain(first)
        if type(quest) == "number" then taken[quest] = Now() end
    end)
    ns.On("QUEST_TURNED_IN", function(quest)
        quest = Plain(quest)
        if type(quest) == "number" then given[quest] = true end
    end)
    ns.On("QUEST_REMOVED", function(quest)
        quest = Plain(quest)
        if type(quest) == "number" then taken[quest] = nil end
    end)
end
