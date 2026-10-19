local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Tooltips - Gathering
--  How likely gathering a herb or an ore raises your skill, in the game's
--  colours of difficulty: on the tooltip of the herb or the vein itself
--  (Kinds/Object.lua), and on what it gives (Kinds/Item.lua). From Core's
--  data: the sets Objects (each node's skill, the skill it needs, where it
--  turns yellow and grey) and Drops (what each gives; Doc/guides/data.md). In
--  the section Professions, after the professions that use the thing:
--
--      PROFESSIONS ────────────────────────
--      [*] Herbalism  160/225     125  150  188  225
--
--  The four numbers are where each colour begins: the skill the node needs
--  (orange: a point each time), the node's own yellow, green halfway from
--  there to grey (as the game colours a recipe), the node's grey (no points
--  any more). The word is in the colour your skill has now: on the node's own
--  tooltip the colour the game gives its line of the skill, elsewhere worked
--  out the same way, red while your skill (with its bonus) is below what the
--  node needs and red without the profession; after it, small, your skill. On
--  what nodes give: each node that gives it by its name, the easiest first;
--  without Alt only that one, and how many more Alt shows.
--
--  A node is known by its name: the tooltip of a thing in the world gives no
--  ID. The data has the names in English, so in another language there is no
--  section. Your skill is the game's (C_SkillInfo), asked once and again when
--  it changes; what is found in the data is kept until the data changes.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain, Ask, Data = Core.Plain, Core.Ask, Core.Data
local OBJECTS, DROPS = Data.Set("Objects"), Data.Set("Drops")
local Read, TEXT, COLOR = ns.Reader, ns.TEXT, ns.COLOR
local ASIDE = COLOR.ASIDE
local Gathering = {}
ns.Gathering = Gathering

-- The skills a node is gathered with, by the game's skill line: its icon, and its name where the game
-- does not say it (you have not learned it)
local SKILLS = {
    [182] = { icon = "Interface\\Icons\\Trade_Herbalism", word = TEXT.HERBALISM },
    [186] = { icon = "Interface\\Icons\\Trade_Mining", word = TEXT.MINING },
}
local GATHERED = { herb = true, ore = true } -- the kinds of object that are gathered with a skill
local HELD = 400 -- names and items kept at most (each thing pointed at), then forgotten together

-- The game's colours of difficulty, as its professions and quest log use them: the global the client
-- has, else the quest log's table, else that table's numbers.
local function Difficulty(global, quest, r, g, b)
    local color = rawget(_G, global)
    if type(color) == "table" and color.GetRGB then
        local cr, cg, cb = color:GetRGB()
        if cr then return { cr, cg, cb } end
    end
    local quests = rawget(_G, "QuestDifficultyColors")
    local known = type(quests) == "table" and quests[quest]
    if type(known) == "table" and known.r then return { known.r, known.g, known.b } end
    return { r, g, b }
end
-- By your chance, the worst first: none (you cannot gather it), orange, yellow, green, grey
local CHANCES = {
    Difficulty("IMPOSSIBLE_DIFFICULTY_COLOR", "impossible", 1, 0.1, 0.1),
    Difficulty("DIFFICULT_DIFFICULTY_COLOR", "verydifficult", 1, 0.5, 0.25),
    Difficulty("FAIR_DIFFICULTY_COLOR", "difficult", 1, 0.82, 0),
    Difficulty("EASY_DIFFICULTY_COLOR", "standard", 0.25, 0.75, 0.25),
    Difficulty("TRIVIAL_DIFFICULTY_COLOR", "trivial", 0.5, 0.5, 0.5),
}
local HEX = {}
for index, color in ipairs(CHANCES) do HEX[index] = ns.Hex(color[1], color[2], color[3]) end

local skills = {} -- [skill line] = { rank, reach, most, name }, or false: not learned
local named = {}  -- [a thing's name] = its node's record, or false: none
local given = {}  -- [item] = the nodes that give it, the easiest first, or false: none
local bands = setmetatable({}, { __mode = "k" }) -- [a node's record] = where each colour begins, as a text
local namedCount, givenCount = 0, 0

-- Your skill in a skill line: its rank, what it reaches with its bonus, its most, its name; nil when
-- you have not learned it.
local function Yours(skill)
    local known = skills[skill]
    if known == nil then
        known = false
        local info = rawget(_G, "C_SkillInfo")
        info = info and Ask(info.GetSkillLineInfoByID, skill)
        local rank = type(info) == "table" and Plain(info.rank)
        if type(rank) == "number" and rank > 0 then
            local bonus, most, name = Plain(info.modifier), Plain(info.maxRank), Plain(info.name)
            known = {
                rank = rank, reach = rank + (type(bonus) == "number" and bonus or 0),
                most = type(most) == "number" and most or rank, name = type(name) == "string" and name ~= "" and name or nil,
            }
        end
        skills[skill] = known
    end
    return known or nil
end

-- The skill's name: the game's, else the module's word for it.
function Gathering.Word(skill)
    local yours = Yours(skill)
    return yours and yours.name or (SKILLS[skill] and SKILLS[skill].word)
end

-- Where gathering a node turns green: halfway from its yellow to its grey, as the game colours a recipe.
local function Green(record)
    return math.ceil((record.yellowAt + record.greyAt) / 2)
end

-- Your chance with a node: an index into CHANCES. A node the data has no yellow and grey for is orange
-- while you can gather it.
local function Chance(record, yours)
    if not yours or yours.reach < record.skillLevel then return 1 end
    if not record.greyAt then return 2 end
    local rank = yours.rank
    if rank < record.yellowAt then return 2 end
    if rank < Green(record) then return 3 end
    if rank < record.greyAt then return 4 end
    return 5
end

-- Where each colour begins for a node, each number in its colour; the skill it needs alone where the
-- data has no more.
local function Bands(record)
    local text = bands[record]
    if not text then
        if record.greyAt then
            text = ("|cff%s%d|r  |cff%s%d|r  |cff%s%d|r  |cff%s%d|r"):format(HEX[2], record.skillLevel, HEX[3], record.yellowAt,
                HEX[4], Green(record), HEX[5], record.greyAt)
        else
            text = ("|cff%s%d|r"):format(HEX[2], record.skillLevel)
        end
        bands[record] = text
    end
    return text
end

-- The chance a colour of the game's stands for (its line of the skill on a node's tooltip), or nil.
local function ChanceOf(r, g, b)
    if not (r and g and b) then return nil end
    for index, color in ipairs(CHANCES) do
        if ns.Like(r, g, b, color) then return index end
    end
    return nil
end

-- A record of the data that is a node gathered with a skill (its yellow and grey both, or neither).
local function Gathered(record)
    return type(record) == "table" and GATHERED[record.kind] and SKILLS[record.skill] and type(record.skillLevel) == "number"
        and (type(record.yellowAt) == "number") == (type(record.greyAt) == "number")
end

local function Ready()
    return OBJECTS:Ready() and DROPS:Ready()
end

-- The node of this name (a thing in the world), its record of the data, or nil. Nothing is kept while
-- the data is not there yet.
function Gathering.Find(name)
    if type(name) ~= "string" or name == "" or not Ready() then return nil end
    local known = named[name]
    if known == nil then
        known = false
        for _, key in ipairs(OBJECTS:Keys("byName", name)) do
            local record = OBJECTS:Get(key)
            if Gathered(record) then
                known = record
                break
            end
        end
        if namedCount >= HELD then
            wipe(named)
            namedCount = 0
        end
        named[name], namedCount = known, namedCount + 1
    end
    return known or nil
end

local function Easier(a, b)
    if a.skillLevel ~= b.skillLevel then return a.skillLevel < b.skillLevel end
    return (a.name or "") < (b.name or "")
end

-- Whether one of the Drops' entries says its object gives item by gathering.
local function Gives(entry, item)
    for _, drop in pairs(type(entry) == "table" and entry.items or {}) do
        if type(drop) == "table" and drop.item == item and drop.how == "gather" then return true end
    end
    return false
end

-- The nodes that give an item, the easiest first; nil when none does (or the data is not there yet).
local function Sources(item)
    local known = given[item]
    if known == nil then
        if not Ready() then return nil end
        known = false
        for _, key in ipairs(DROPS:Keys("byItem", item)) do
            local object = type(key) == "string" and tonumber(key:match("^object:(%d+)$"))
            local record = object and OBJECTS:Get(object)
            if Gathered(record) and Gives(DROPS:Get(key), item) then
                known = known or {}
                known[#known + 1] = record
            end
        end
        if known then table.sort(known, Easier) end
        if givenCount >= HELD then
            wipe(given)
            givenCount = 0
        end
        given[item], givenCount = known, givenCount + 1
    end
    return known or nil
end

-- One row: the skill's icon, words in the colour of your chance, at the right where each colour begins.
-- One row: the skill's icon, words in the colour of your chance (chance: the game's own, where known), at
-- the right where each colour begins.
local function Row(record, words, chance)
    local color = CHANCES[chance or Chance(record, Yours(record.skill))]
    local row = Read.Text("sub", words, color[1], color[2], color[3])
    row.icon = SKILLS[record.skill].icon
    row.right = Bands(record)
    return row
end

-- On the tooltip of a herb or a vein (record: Gathering.Find): its skill, your skill after it, in the
-- section Professions. r, g, b: the colour of the game's own line of the skill, where it has one.
function Gathering.Node(record, r, g, b)
    if not Gathered(record) then return end
    Read.Section(TEXT.PROFESSIONS)
    local skill = record.skill
    local row = Row(record, Gathering.Word(skill), ChanceOf(r, g, b))
    local yours = Yours(skill)
    row.label = yours and Read.Memo("gatherSkill", TEXT.SKILL, yours.rank, yours.most) or TEXT.NOT_LEARNED
    row.labelFont = "small"
end

-- On what nodes give: each node by its name, the easiest first; without Alt only that one. In the section
-- Professions, after the professions that use it.
function Gathering.Item(ctx, item)
    local list = item and Sources(item)
    if not list then return end
    Read.Section(TEXT.PROFESSIONS)
    local shown = IsAltKeyDown() and #list or 1
    for index = 1, shown do Row(list[index], list[index].name) end
    if shown < #list then
        Read.Text("small", Read.Memo("gatherMore", TEXT.ALT_MORE, #list - shown), ASIDE[1], ASIDE[2], ASIDE[3]).indent = 20
    end
end

-- Your skill is asked anew when it changes, what the data says when the data does; then arrived() is
-- called, for the shown panels.
function Gathering.Start(arrived)
    Core.On("SKILL_LINES_CHANGED", function()
        wipe(skills)
        if arrived then arrived() end
    end)
    local function Arrived()
        wipe(named)
        wipe(given)
        namedCount, givenCount = 0, 0
        if arrived then arrived() end
    end
    OBJECTS:OnStamp(Arrived)
    DROPS:OnStamp(Arrived)
    Data.Prepare("Objects") -- (in the same pack as Drops, which Quests.lua asks for too)
end
