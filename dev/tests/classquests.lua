-- Runs Speed Leveling's class quests against the stand-in client (wowstub.lua): which chains are a character's by class,
-- race and side, the step that comes up at its level over the guide with the guide's own steps untouched, the way
-- through a quest (to take, what it asks, to hand in), what the guide does itself, a chain left and brought back, the
-- switch, what the arrow, the key and the view make of it, and the key in a fight.
-- Usage, from the project folder:  lua5.1 dev/tests/classquests.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
local E = require("encoding")
W.Install(_G)
bit = E.bit
C_EncodingUtil = E.C_EncodingUtil

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:GetStringHeight() return self._text and self._text ~= "" and 14 or 0 end
function methods:GetStringWidth() return #(self._text or "") * 6 end
function RegisterStateDriver() end
function UnregisterStateDriver() end
function ClearOverrideBindings() end
function GetBindingKey() return nil end
UnitExists = function(unit) return unit == "player" end
UnitIsDeadOrGhost = function() return false end
UnitOnTaxi = function() return false end
GetNumGroupMembers = function() return 0 end
GetMoney = function() return 0 end
GetRealZoneText = function() return "Teldrassil" end
GetSubZoneText = function() return "" end
GetBindLocation = function() return "Dolanaar" end
HEARTHSTONE_BOUND = true
IsPlayerSpell = function() return false end
IsSpellKnown = function() return false end

-------------------------------------------------------------------------------
--  The character and what the game says of its quests
-------------------------------------------------------------------------------
local WARRIOR, DRUID = 1, 11
local NIGHTELF, TAUREN, SKYBORNE = 4, 6, 95
local me = { class = DRUID, race = NIGHTELF, side = "Alliance", level = 9 }
UnitClass = function() return "Druid", "DRUID", me.class end
UnitRace = function() return "Night Elf", "NightElf", me.race end
UnitFactionGroup = function() return me.side end
UnitLevel = function() return me.level end
UnitXP, UnitXPMax = function() return 0 end, function() return 100 end

local quests
local function Reset() quests = { on = {}, done = {}, ready = {}, objectives = {}, text = {} } end
Reset()
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.IsOnQuest = function(q) return quests.on[q] == true end
C_QuestLog.IsQuestFlaggedCompleted = function(q) return quests.done[q] == true end
C_QuestLog.IsComplete = function(q) return quests.ready[q] == true end
C_QuestLog.GetQuestObjectives = function(q) return quests.objectives[q] end
C_QuestLog.GetTitleForQuestID = function(q) return "Quest " .. q end
C_QuestLog.GetNumQuestLogEntries = function() return 0 end
C_QuestLog.RequestLoadQuestByID = function() end
C_QuestLog.GetLogIndexForQuestID = function(q) return quests.on[q] and q or 0 end
GetQuestLogQuestText = function(index) return "A long tale.", quests.text[index] end
C_Map = rawget(_G, "C_Map") or {}
C_Map.GetMapInfo = function(map) return { name = "Map " .. map, mapType = 3 } end
C_Map.GetBestMapForUnit = function() return 1411 end

-------------------------------------------------------------------------------
--  Core, its data, and the module
-------------------------------------------------------------------------------
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core

local records = {
    ClassQuests = {
        [1101] = { name = "Bear Form", class = DRUID, side = "alliance", races = { NIGHTELF }, level = 10, quests = { 10, 11, 12 } },
        [1102] = { name = "Bear Form", class = DRUID, side = "horde", races = { TAUREN }, level = 10, quests = { 20 } },
        [1103] = { name = "Ursera", class = DRUID, races = { SKYBORNE }, level = 10, quests = { 30 } },
        [1104] = { name = "Aquatic Form", class = DRUID, side = "alliance", races = { NIGHTELF }, level = 16, quests = { 40, 41 } },
        [1105] = { name = "Marked", class = DRUID, level = 18, quests = { 50 }, also = { 51, 52 } },
        [1106] = { name = "Later", class = DRUID, level = 18, quests = { 60, 61 } },
        [101] = { name = "Whirlwind Weapon", class = WARRIOR, level = 30, quests = { 70 } },
    },
    Quests = {
        [10] = { minLevel = 10, startNPCs = { { npc = 300 }, { npc = 301, side = "horde" } }, finishNPCs = { { npc = 302 } },
                 objectives = { { index = 1, kind = "kill", what = 200 } } },
        [11] = { minLevel = 10, startNPCs = { { npc = 302 } }, finishObjects = { { object = 900 } },
                 objectives = { { index = 1, kind = "loot", what = 500 } } },
        [12] = { minLevel = 10, startItems = { 600 }, finishNPCs = { { npc = 300 } } },
        [20] = { minLevel = 10, startNPCs = { { npc = 310 } }, finishNPCs = { { npc = 310 } } },
        [30] = { minLevel = 10, startNPCs = { { npc = 320 } }, finishNPCs = { { npc = 320 } } },
        [40] = { minLevel = 16, startNPCs = { { npc = 300 } }, finishNPCs = { { npc = 300 } } },
        [41] = { minLevel = 20, startNPCs = { { npc = 300 } }, finishNPCs = { { npc = 300 } } },
        [50] = { minLevel = 18, startNPCs = { { npc = 300 } }, finishNPCs = { { npc = 300 } } },
        [60] = { minLevel = 18, startObjects = { { object = 900 } }, finishNPCs = { { npc = 300 } } },
        [61] = { minLevel = 18, startNPCs = { { npc = 300 } }, finishNPCs = { { npc = 300 } } },
        [70] = { minLevel = 30, startNPCs = { { npc = 300 } }, finishNPCs = { { npc = 300 } } },
    },
    NPCs = { [200] = { name = "Lunaclaw" }, [201] = { name = "A dropper" }, [300] = { name = "Mathrengyl" }, [301] = { name = "A stranger" },
             [302] = { name = "Dendrite" }, [310] = { name = "Turak" }, [320] = { name = "Urs'endris" } },
    Objects = { [900] = { name = "Moonkin Stone" } },
    Drops = { ["npc:201"] = { items = { { item = 500, how = "loot" } } } },
    Spawns = {
        ["npc:200"] = { points = { { map = 1412, x = 90, y = 90 }, { map = 1411, x = 11, y = 11 }, { map = 1411, x = 40, y = 40 } } },
        ["npc:201"] = { points = { { map = 1411, x = 12, y = 12 } } },
        ["npc:300"] = { points = { { map = 1411, x = 10, y = 10 } } },
        ["npc:301"] = { points = { { map = 1411, x = 50, y = 50 } } },
        ["npc:302"] = { points = { { map = 1413, x = 20, y = 20 } } },
        ["npc:310"] = { points = { { map = 1420, x = 30, y = 30 } } },
        ["object:900"] = { points = { { map = 1411, x = 60, y = 60 } } },
    },
}
local byClass = { [DRUID] = { 1101, 1102, 1103, 1104, 1105, 1106 }, [WARRIOR] = { 101 } }
local realSet = Core.Data.Set
Core.Data.Set = function(name)
    if not records[name] then return realSet(name) end
    local handle = {}
    function handle:Get(key, field)
        local record = records[name][key]
        if field then return record and record[field] end
        return record
    end
    function handle:Keys(index, value)
        if name == "ClassQuests" and index == "byClass" then return byClass[value] or {} end
        if name == "Drops" and index == "byItem" then return value == 500 and { "npc:201" } or {} end
        return {}
    end
    return handle
end
local ns = W.LoadAddon(root, "SpeedLeveling", "SaneUI_SpeedLeveling")
Core.Data.Set = realSet
W.Fire("ADDON_LOADED", "SaneUI_SpeedLeveling")

local known = Core.Neighbours.KNOWN.guide
local C = {}
for theirs, ours in pairs(known.commands) do if not C[ours] then C[ours] = theirs end end
local function L(command, values, words) return "." .. C[command] .. " " .. values .. (words and (" >> " .. words) or "") end
local GUIDE = table.concat({
    "#forever", "#name Test", "#group G",
    "step", L("take", "1"),
    "step", L("handin", "1"),
    "step", L("take", "2"),
}, "\n")
W.Fire("PLAYER_LOGIN")
assert(Core.Profiles.Use("Speedleveling"), "the profile this module works on")
ns.Guide.AddAll(ns.Format.Parts(GUIDE), false)

local Run, Guide, ClassQuests = ns.Run, ns.Guide, ns.ClassQuests
local STEP = ClassQuests.STEP

-- The guide taken up anew for the character as it is now.
local function Fresh(text)
    Run.Use(ns.Format.Read(text or GUIDE, { side = me.side, race = "NightElf", class = "DRUID", level = me.level, game = "forever" }))
end
local function Step() return Run.Guide().steps[STEP] end
local function Words(index)
    local words = {}
    for _, state in ipairs(Run.Lines(index or STEP)) do words[#words + 1] = Run.Words(state.line) or "" end
    return table.concat(words, " | ")
end
local function Check()
    return Run.Check()
end

-------------------------------------------------------------------------------
--  For whom, and when
-------------------------------------------------------------------------------
Fresh()
check(Run.Guide() and #Run.Guide().steps == 3, "the guide is read")
check(Step() == nil and Run.Hand()[1] == 1, "level 9: nothing yet, the guide alone")
me.level = 10
check(Check() == true and Step() ~= nil, "level 10: the chain's step comes up as the level does")
check(Run.Hand()[1] == STEP and Run.Hand()[2] == 1, "over the steps at hand, the guide's still there")
check(#Run.Guide().steps == 3 and Run.At() == 1 and Run.Place() == 1, "and the guide's own steps and your place are as they were")
check(Words():find("Talk to Mathrengyl in Map 1411", 1, true), "whom to talk to, and where")
check(Words():find("Accept Quest 10", 1, true), "and what to take")
local picture = Guide.Picture(3, 0)
check(picture.hand[1].chain == "Bear Form: 1 of 3" and picture.hand[1].number == STEP, "the view names the chain and how far")
check(picture.total == 3 and picture.place == 1 and picture.hand[2].chain == nil, "the guide's numbers are the guide's")
local line = Run.Target()
check(line and line.map == 1411 and line.x == 10, "the arrow goes to the giver first")
check(Run.Quests().take[10] == true and Run.Quests().take[1] == true, "the key takes the chain's quest and the guide's")
check(Run.Guide().steps[STEP].friends[1] == "Mathrengyl", "and looks for its giver")

me.race, me.side = TAUREN, "Horde"
Fresh()
check(Step() and Words():find("Talk to Turak", 1, true) and Words():find("Quest 20", 1, true), "a tauren gets a tauren's chain")
me.race = SKYBORNE
Fresh()
check(Step() and Words():find("Quest 30", 1, true), "a Skyborne of either side the chain of its race")
check(Words():find("Talk to Urs'endris", 1, true) and not Words():find(" in ", 1, true), "where Core knows no place, the name alone")
me.class, me.race = WARRIOR, TAUREN
Fresh()
check(Step() == nil, "a warrior at level 10 has none")
me.level = 30
check(Check() == true and Words():find("Quest 70", 1, true), "and at 30 a warrior's own")
me.class, me.race, me.side, me.level = DRUID, NIGHTELF, "Alliance", 10
Fresh()

-- A map's name the game hides (a secret value): the giver's name alone, nothing made of it. The name is a field of
-- the game's table, which only the module's own Core.Plain reaches.
local mapInfo = C_Map.GetMapInfo
C_Map.GetMapInfo = function(map) return { name = W.Secret(), mapType = 3 } end
Fresh()
check(Words():find("Talk to Mathrengyl", 1, true) and not Words():find(" in ", 1, true), "a zone the game hides: the name alone")
C_Map.GetMapInfo = mapInfo
Fresh()

-------------------------------------------------------------------------------
--  Through a quest
-------------------------------------------------------------------------------
quests.on[10] = true
quests.objectives[10] = { { finished = false, numFulfilled = 0, numRequired = 1, text = "Lunaclaw defeated: 0/1", type = "monster" } }
quests.text[10] = "Use the Moondust on the stone."
check(Check() == true and Words():find("Use the Moondust on the stone.", 1, true), "in your log: the game's words for what it asks")
check(Words():find("Lunaclaw defeated", 1, true), "and its objectives, as the game counts them")
check(Run.Lines(STEP)[3].line.what == "goal" and Run.Target().x == 11, "the arrow to the place nearest its giver")
check(Guide.Doing(Guide.Picture(0, 0).hand[1]) == "kill", "the arrow's picture is what it asks")
quests.ready[10] = true
check(Check() == true and Words():find("Talk to Dendrite in Map 1413", 1, true), "ready: to whoever takes it")
check(Words():find("Hand in Quest 10", 1, true) and Words():find("Accept Quest 11", 1, true), "and the next quest from that NPC goes with it")
check(Run.Quests().handin[10] == true and Run.Quests().take[11] == true, "the key does both")
quests.on[10], quests.ready[10], quests.done[10] = nil, nil, true
quests.on[11] = true
quests.objectives[11] = { { finished = false, numFulfilled = 0, numRequired = 3, text = "Claws: 0/3", type = "item" } }
check(Check() == true and Run.Target().x == 12, "an item to loot: the place of what drops it")
quests.ready[11] = true
check(Check() == true and Words():find("Go to Moonkin Stone", 1, true) and Run.Guide().steps[STEP].things[1] == "Moonkin Stone",
    "handed in to a thing: go there, the key wants it")
check(Guide.Things()[1] == "Moonkin Stone", "and the guide says so")
quests.on[11], quests.ready[11], quests.done[11] = nil, nil, true
check(Check() == true and Words():find("Use ", 1, true) and Step().items[1] == 600 and Step().uses[1].item == 600,
    "a quest an item starts: the item to use")
check(Check() == false, "asked again with nothing new, nothing changes")
quests.done[12] = true
check(Check() == true and Step() == nil and Run.Hand()[1] == 1, "the last handed in: the chain is through, the guide alone")
check(Run.Target() == nil, "and the arrow is the guide's again")

-- A quest that only asks you to go to whoever takes it: nothing to do, whatever the game calls it.
Reset()
quests.done[10], quests.done[11] = true, true
quests.on[12] = true
Check()
check(Words():find("Talk to Mathrengyl", 1, true) and Words():find("Hand in Quest 12", 1, true), "no objectives: straight to whoever takes it")
check(not Words():find("A long tale", 1, true), "with nothing in between")

-- A quest further on shows you came that way, whatever the game says of those before it.
Reset()
quests.done[11] = true
Check()
check(Words():find("Quest 12", 1, true), "a later quest done: on from there")
Reset()

-------------------------------------------------------------------------------
--  Levels within a chain, one chain after another
-------------------------------------------------------------------------------
quests.done[10], quests.done[11], quests.done[12] = true, true, true
me.level = 16
Check()
check(Words():find("Quest 40", 1, true), "the next chain, at its level")
quests.done[40] = true
Check()
check(Step() == nil, "its next quest wants level 20: nothing for now")
me.level = 18
Check()
check(Words():find("Quest 50", 1, true), "and the next chain that is due comes up meanwhile")
quests.done[52] = true
Check()
check(Words():find("Quest 60", 1, true) and Words():find("Go to Moonkin Stone", 1, true), "the first quest from another NPC will do: that chain is through")
quests.done[52], quests.done[60], quests.done[61] = nil, true, true
quests.on[51] = true
quests.ready[51] = false
Check()
check(Words():find("Quest 51", 1, true), "and what you took from that NPC is what is followed")
Reset()
me.level = 10
Fresh()

-------------------------------------------------------------------------------
--  What the guide does itself
-------------------------------------------------------------------------------
local OWN = table.concat({ "#forever", "#name Own", "#group G", "step", L("take", "10"), "step", L("handin", "10") }, "\n")
Fresh(OWN)
check(Step() == nil, "a quest the guide takes and hands in is the guide's")
quests.on[10] = true
Check()
check(Step() == nil, "all the way")
Reset()
local TAKES = table.concat({ "#forever", "#name Takes", "#group G", "step", L("take", "10") }, "\n")
Fresh(TAKES)
check(Step() == nil, "a quest the guide only takes: left to it")
quests.on[10] = true
Check()
check(Step() ~= nil and Words():find("Quest 10", 1, true), "and shown from there on, as it does not hand it in")
Reset()
Fresh()

-------------------------------------------------------------------------------
--  Left and brought back
-------------------------------------------------------------------------------
local number = Guide.Picture(0, 0).hand[1].number
Guide.Skip(number)
check(Step() == nil and ClassQuests.Left() == 1, "a click leaves the chain")
check(Run.At() == 1 and Run.Place() == 1, "and your place in the guide is as it was")
Fresh()
check(Step() == nil, "and it stays left")
me.level = 16
Check()
check(Words():find("Quest 40", 1, true), "the next chain still comes")
me.level = 10
quests.on[10] = true
Check()
check(Words():find("Quest 10", 1, true), "a quest of it taken yourself: it is back")
Reset()
Check()
check(Step() == nil, "gone from the log, left again")
ClassQuests.Back()
check(ClassQuests.Left() == 0, "brought back")
Check()
check(Words():find("Quest 10", 1, true), "and there it is")

Core.Set(ns.name, "classQuests", false)
Check()
check(Step() == nil and Run.Hand()[1] == 1, "the switch off: no class quests")
Core.Set(ns.name, "classQuests", true)
Check()
check(Step() ~= nil, "on: back")

-- Several givers: the one nearest you.
do
    local distance = Run.Distance
    Run.Distance = function(point) return point.x == 10 and 500 or 90 end
    me.side = "Horde"
    records.ClassQuests[1101].side, records.ClassQuests[1102] = "horde", nil
    Fresh()
    check(Words():find("Talk to A stranger", 1, true), "of two givers for you, the nearer")
    me.side = "Alliance"
    records.ClassQuests[1101].side = "alliance"
    Fresh()
    check(Words():find("Talk to Mathrengyl", 1, true), "and one for the other side is not yours")
    Run.Distance = distance
end

-------------------------------------------------------------------------------
--  In a fight
-------------------------------------------------------------------------------
-- The key's buttons are the game's secure ones: in a fight they stay as they were, whatever the chain's step comes
-- to meanwhile, and what it wants on them follows once the fight is over (the module's own check, by its timer).
do
    local find = rawget(_G, ns.Key.FIND)
    Reset()
    Fresh()
    Guide.CheckSoon()
    W.Wait(1)
    local before = find:GetAttribute("macrotext")
    W.Combat(true)
    quests.on[10], quests.ready[10] = true, true
    Guide.CheckSoon()
    W.Wait(1)
    check(before:find("Mathrengyl", 1, true) and Words():find("Talk to Dendrite", 1, true)
        and find:GetAttribute("macrotext") == before and Core.Owed("Speed Leveling: refresh"),
        "in a fight the chain goes on, the key's buttons stay the game's: what they want waits")
    W.Combat(false)
    local macro = find:GetAttribute("macrotext")
    check(macro:find("Dendrite", 1, true) and not macro:find("Mathrengyl", 1, true), "and follows once it is over")
    Reset()
end

Run.Use(nil)
check(ClassQuests.Hand()[1] == nil and Run.Check() == false, "no guide: nothing")

io.write(("Class quests: all %d checks passed\n"):format(passed))
