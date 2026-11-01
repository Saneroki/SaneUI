-- Runs Speed Leveling's guide against the stand-in client (wowstub.lua): a guide written as text read into our shape
-- for one character (its head, who a step and a line are for, each kind of command, step marks, what cannot be read,
-- which games it is for), the import string of bought guides opened for the account (Unlock), the guide run (moving
-- on past done steps, the steps at hand, skipping, going back and being held there, what the game tells as it
-- happens, places, tests that pass a step by, the next guide), what the game knows done by itself (at a guide picked
-- partway, past steps it cannot judge, after a click back, your place kept), the guides kept (packed, chosen), the
-- picture over the world (drawn, clicked, scrolled, hidden), the arrow (a facing the game hides), the icons (only what
-- can be used; secure: held in a fight), what the game hides (secret values), and standing down.
-- The guide format's own words come from Core (Core.Neighbours.KNOWN.guide): the test names none of its own.
-- Usage, from the project folder:  lua5.1 dev/tests/speedguide.lua

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
--  What the guide needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:GetStringHeight() return self._text and self._text ~= "" and 14 or 0 end
function methods:GetStringWidth() return #(self._text or "") * 6 end
function methods:SetAlpha(alpha) self._alpha = alpha end
function methods:GetAlpha() return self._alpha end
function methods:SetScale(scale) self._scale = scale end
function methods:SetHeight(height) self._height = height end
function methods:GetHeight() return self._height end
function methods:SetWidth(width) self._width = width end
function methods:GetWidth() return self._width end
function methods:SetSize(width, height) self._width, self._height = width, height end
function methods:SetRotation(angle) self._rotation = angle end
function methods:SetTextColor(r, g, b) self._color = { r, g, b } end
function methods:SetFormattedText(format, ...) self._text = format:format(...) end
function methods:GetLeft() return self._left or 900 end
function methods:GetBottom() return self._bottom or 300 end
function methods:GetTop() return self._top or 600 end
local facing = 0
GetPlayerFacing = function() return facing end

function methods:SetAttribute(name, value)
    self._attributes = self._attributes or {}
    self._attributes[name] = value
end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function RegisterStateDriver() end
function UnregisterStateDriver() end
function ClearOverrideBindings() end
function GetBindingKey() return nil end
UnitExists = function(unit) return unit == "player" end

-- An orc warrior of the Horde, level 5, 100 of 400 points into it, with some money.
UnitRace = function() return "Orc", "Orc", 2 end
UnitClass = function() return "Warrior", "WARRIOR", 1 end
UnitFactionGroup = function() return "Horde" end
UnitIsDeadOrGhost = function() return false end
UnitOnTaxi = function() return false end
GetNumGroupMembers = function() return 0 end
W.level = 5
local xp = 100
UnitLevel = function() return W.level end
UnitXP = function() return xp end
UnitXPMax = function() return 400 end
local money = 0
GetMoney = function() return money end
local zone, subzone = "Durotar", "Valley of Trials"
GetRealZoneText = function() return zone end
GetSubZoneText = function() return subzone end
GetBindLocation = function() return "Razor Hill" end
local home = false
HEARTHSTONE_BOUND = true

-- The quests: on, done, ready, objectives; names.
local quests = { on = {}, done = {}, ready = {}, objectives = {}, names = { [10] = "Your Place", [11] = "Cutting Teeth" } }
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.IsOnQuest = function(q) return quests.on[q] == true end
C_QuestLog.IsQuestFlaggedCompleted = function(q) return quests.done[q] == true end
C_QuestLog.IsComplete = function(q) return quests.ready[q] == true end
C_QuestLog.GetQuestObjectives = function(q) return quests.objectives[q] end
C_QuestLog.GetTitleForQuestID = function(q) return quests.names[q] end
C_QuestLog.GetNumQuestLogEntries = function() return 0 end
C_QuestLog.RequestLoadQuestByID = function() end

local known = {}
IsPlayerSpell = function(spell) return known[spell] == true end
IsSpellKnown = function(spell) return known[spell] == true end
C_Item = rawget(_G, "C_Item") or {}
C_Item.GetItemCount = function(id) local it = W.items[id] return it and it.count or 0 end
C_Item.GetItemNameByID = function(id) return W.items[id] and W.items[id].name or nil end
C_Item.GetItemIconByID = function() return 134400 end
C_Item.IsUsableItem = function() return true end
C_Item.GetItemSpell = function(id) return W.items[id] and W.items[id].use or nil end
C_Container = { GetItemCooldown = function() return 0, 0, 1 end }

-- The world: Durotar is map 1411 on continent 1, 2000 x 2000 yards; the player at its middle.
local pos = { x = 0.5, y = 0.5 }
C_Map = rawget(_G, "C_Map") or {}
C_Map.GetBestMapForUnit = function() return 1411 end
C_Map.GetMapInfo = function(id) return { mapID = id, name = "Durotar", mapType = 3, parentMapID = 12 } end
C_Map.GetFallbackWorldMapID = function() return 947 end
C_Map.GetMapChildrenInfo = function() return { { mapID = 1411, name = "Durotar", mapType = 3 } } end
C_Map.GetPlayerMapPosition = function() return { x = pos.x, y = pos.y, GetXY = function(s) return s.x, s.y end } end
C_Map.GetAreaInfo = function(a) return a == 500 and "Valley of Trials" or "Somewhere" end
CreateVector2D = function(x, y) return { x = x, y = y } end
C_Map.GetWorldPosFromMapPos = function(_, p)
    -- map (0,0) is world (2000,2000); each unit of fraction is 2000 yards, x to the east, y to the south.
    return 1, { x = 2000 - p.x * 2000, y = 2000 - p.y * 2000 }
end
-- The game's map pin: Durotar takes one, nothing else does.
local pinned
UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { uiMapID = map, position = { x = x, y = y } } end }
C_Map.CanSetUserWaypointOnMap = function(map) return map == 1411 end
C_Map.SetUserWaypoint = function(point) pinned = point end
C_Map.HasUserWaypoint = function() return pinned ~= nil end
C_Map.GetUserWaypoint = function() return pinned end
C_Map.ClearUserWaypoint = function() pinned = nil end
C_Map.GetMapPosFromWorldPos = function(_, world, named)
    return named or 1411, { x = (2000 - world.y) / 2000, y = (2000 - world.x) / 2000 }
end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local Core = SaneUI.Core
assert(Core.Profiles.Use("Speedleveling"), "the profile this module works on")
local KNOWN = Core.Neighbours.KNOWN.guide

-- The format's words, by ours: its command word for each of ours, its step mark for each of ours.
local C, M = {}, {}
for theirs, ours in pairs(KNOWN.commands) do if not C[ours] then C[ours] = theirs end end
for theirs, ours in pairs(KNOWN.marks) do M[ours] = theirs end
local COLOUR = KNOWN.colours
local function Line(command, values, words, only)
    return "." .. C[command] .. " " .. values .. (words and (" >> " .. words) or "") .. (only and (" << " .. only) or "")
end
local function Mark(mark, value) return "#" .. M[mark] .. (value and (" " .. value) or "") end

local ns = W.LoadAddon(root, "SpeedLeveling", "SaneUI_SpeedLeveling")
W.Fire("ADDON_LOADED", "SaneUI_SpeedLeveling")
W.Fire("PLAYER_LOGIN")
local Format, Run, Guide, Steps, Unlock = ns.Format, ns.Run, ns.Guide, ns.Steps, ns.Unlock
local orc = { side = "Horde", race = "Orc", class = "WARRIOR", level = 5, game = "forever" }
local human = { side = "Alliance", race = "Human", class = "MAGE", level = 5, game = "forever" }

-------------------------------------------------------------------------------
--  Who a line is for
-------------------------------------------------------------------------------
check(Format.For(orc, "Horde") and Format.For(orc, "Orc Warrior") and Format.For(orc, "Dwarf Hunter/Orc Warrior"),
    "OR between slashes, AND between spaces")
check(not Format.For(orc, "Orc Mage") and not Format.For(orc, "Alliance"), "an AND-group needs every name")
check(not Format.For(orc, "!Orc") and Format.For(orc, "!Mage") and Format.For(orc, "!Human"), "! before a name: all but it")
check(Format.For(orc, "5") and not Format.For(orc, "6") and Format.For(orc, "!6"), "a number: the level reached")
check(Format.For({ side = "Neutral", level = 1 }, "Alliance") and Format.For({ side = "Neutral", level = 1 }, "Horde"),
    "a neutral character counts as both sides")
check(Format.For({ race = "Scourge", level = 1 }, "Undead"), "Undead names the Scourge race")
check(Format.Plays(orc, { "forever", "tbc" }) and Format.Plays(orc, { "classic" }) and not Format.Plays(orc, { "retail" })
    and Format.Plays(orc, {}), "a guide's games: Forever falls back to classic; none plays anywhere")

-------------------------------------------------------------------------------
--  Reading a guide
-------------------------------------------------------------------------------
local TEXT = table.concat({
    "<< Horde",
    "#forever",
    "#tbc",
    Mark("name", "1-6 Valley"),
    Mark("title", "Valley of Trials"),
    Mark("group", "Our Group"),
    Mark("subgroup", "Speedrun"),
    Mark("after", "6-10 Hills;Other Group\\6-10 Other << Warrior"),
    Mark("defaultFor", "Orc/Troll"),
    "-- a comment",
    "step",
    "    >>Talk to |c" .. COLOUR.friend .. "Kaltunk|r",
    "    " .. Line("take", "10", "Accept the first"),
    "    " .. Line("friend", "Kaltunk"),
    "step << !Orc",
    "    " .. Line("take", "99"),
    "step << Warrior/Shaman",
    "    " .. Mark("together", "next"),
    "    +Kill boars until you have some copper << Warrior",
    "    +Never seen << Mage",
    "    " .. Line("foe", "*Mottled Boar"),
    "    " .. Line("money", ">0.01"),
    "step",
    "    " .. Mark("label", "Teeth"),
    "    " .. Line("place", "1411,45.5,62.2"),
    "    " .. Line("goal", "10,1 --Mottled Boar slain (4)"),
    "    " .. Line("carry", "770,6,10"),
    "    " .. Line("use", "6948"),
    "    .notacommand 3 >> Words of a command not known",
    "    " .. Line("take", "abc"),
    "step",
    "    " .. Mark("stays"),
    "    " .. Line("level", "6", "Reach level 6"),
    "step",
    "    " .. Line("onQuest", "11"),
    "    " .. Line("handin", "11"),
    "step",
    "    #" .. KNOWN.modes[1],
    "    " .. Line("take", "500"),
    "step",
    "    " .. Mark("aside"),
    "    " .. Line("place", "1411/1,-600.5,-4200.25,20"),
    "step",
    "    " .. Mark("needs", "Teeth"),
    "    " .. Line("hearth", "", "Hearth to the valley"),
    "step",
    "    " .. Line("handin", "10"),
    "    *A note\\nwith two lines",
}, "\n")

local head = Format.Head(TEXT)
check(head.name == "1-6 Valley" and head.group == "Our Group" and head.subgroup == "Speedrun", "the head alone: name, group, subgroup")
check(head.games[1] == "forever" and head.games[2] == "classic" or (head.games[1] == "forever"), "its games, from the head")
check(head.only == "Horde" and head.defaultFor == "Orc/Troll", "who it is for; who starts with it")
check(head.after[1].name == "6-10 Hills" and head.after[2].name == "Other Group\\6-10 Other" and head.after[2].only == "Warrior",
    "the guides after it, each with its own who")

local parts = Format.Parts("local x = 1\nGuide([[" .. TEXT .. "]])\nGuide([[" .. Mark("name", "Second") .. "\nstep\n]])")
check(#parts == 2 and parts[1] == TEXT, "a Lua file's long brackets: each pair a guide")

local guide, problems = Format.Read(TEXT, orc)
check(guide.mine and guide.name == "1-6 Valley" and guide.title == "Valley of Trials", "the head: name and title")
check(not Format.Read(TEXT, human).mine, "a Horde guide is not the human's")
check(#guide.steps == 8, "the steps for the orc warrior: " .. #guide.steps)
local first = guide.steps[1]
check(first.lines[1].what == "say" and first.lines[1].words:find("Kaltunk", 1, true), "words only: what to do")
check(first.lines[2].what == "take" and first.lines[2].quest == 10 and first.lines[2].words == "Accept the first",
    "a quest to take, with the guide's words")
check(first.friends[1] == "Kaltunk", "an NPC for the key")
local boars = guide.steps[2]
check(boars.together == "next" and #boars.lines == 1 and boars.lines[1].what == "manual", "with the next; a line for the warrior only")
check(boars.foes[1] == "Mottled Boar" and boars.unless[1].what == "money" and boars.unless[1].more
    and boars.unless[1].copper == 100, "a creature for the key (its * gone); passed by with a silver")
local teeth = guide.steps[3]
check(guide.labels.Teeth == 3 and teeth.label == "Teeth", "a step's name")
check(teeth.lines[1].what == "place" and teeth.lines[1].map == 1411 and teeth.lines[1].x == 45.5, "a place on a map, no reach")
check(teeth.lines[2].what == "goal" and teeth.lines[2].quest == 10 and teeth.lines[2].goal == 1, "an objective, the comment cut off")
check(teeth.lines[3].what == "carry" and teeth.lines[3].item == 770 and teeth.lines[3].count == 6 and teeth.lines[3].quest == 10,
    "an item to carry, for a quest")
check(teeth.items[1] == 6948, "an item for the key")
check(teeth.lines[4].what == "say" and teeth.lines[4].words == "Words of a command not known", "a command not known: its words")
check(#problems == 1 and problems[1]:find("could not be read", 1, true), "a command that cannot be read is said: " .. tostring(problems[1]))
check(guide.steps[4].stays and guide.steps[4].lines[1].what == "level" and guide.steps[4].lines[1].level == 6, "a step that stays")
check(guide.steps[5].unless[1].what == "onQuest" and guide.steps[5].unless[1].quests[1] == 11, "a test: on a quest")
check(guide.steps[6].aside and guide.steps[6].lines[1].what == "arrive" and guide.steps[6].lines[1].continent == 1
    and guide.steps[6].lines[1].near == 20, "a place in the world with a reach: to get to; a step aside")
check(guide.steps[7].needs == "Teeth" and guide.steps[7].lines[1].what == "hearth", "a step that needs another")
check(guide.steps[8].lines[2].what == "note" and guide.steps[8].lines[2].words == "A note\nwith two lines", "a note of two lines")
for _, step in ipairs(guide.steps) do
    for _, line in ipairs(step.lines) do check(line.quest ~= 500 and line.quest ~= 99, "no step of another mode or race") end
end
-- Dungeons: a normal guide has none, a dungeon guide runs them; each drops the steps for the other way.
do
    local function Marks(group)
        local text = table.concat({ "#group " .. group, "step", "    #label gone", Line("dungeon", "WC"), Line("take", "1"),
            "step", Line("take", "2"), "step", Line("take", "3"), Line("dungeon", "!WC") }, "\n")
        local read = Format.Read(text, orc)
        local quests = {}
        for _, step in ipairs(read.steps) do quests[#quests + 1] = step.lines[1].quest end
        return table.concat(quests, " "), read
    end
    local plain, read = Marks("A Guide")
    check(plain == "2 3" and read.labels.gone == nil, "a normal guide: no step of a dungeon, its name gone with it")
    check(Marks("A Dungeon Guide") == "1 2", "a dungeon guide: the dungeon's steps, not those for skipping it")
end
local level = Format.Read("step\n" .. Line("level", "10-1475") .. "\n" .. Line("level", "<10.5,1"), orc).steps[1]
check(level.lines[1].points == -1475 and level.lines[1].level == 10, "so many points short of a level")
check(level.unless[1].what == "reached" and level.unless[1].share == 0.5 and level.unless[1].below, "a level that passes a step by")

-------------------------------------------------------------------------------
--  The import string of bought guides, opened for the account
-------------------------------------------------------------------------------
BNGetInfo = function() return 1, "Tester#4242" end
local recipe = Core.Neighbours.Lock("guide")
local g1 = "#forever\n" .. Mark("name", "Bought A") .. "\n" .. Mark("group", "Bought") .. "\nstep\n" .. Line("take", "1")
local g2 = "#forever\n" .. Mark("name", "Bought B") .. "\n" .. Mark("group", "Bought") .. "\nstep\n" .. Line("handin", "1")
local string = E.Lock("Tester#4242", { g1, g2 }, recipe)
check(Unlock.Looks(string) and not Unlock.Looks("step\n.accept 1"), "an import string is told from a guide's text")
-- The unlock runs in Core's job steps: drive the scheduler's frame until it is done.
local function Pump()
    local f = Core.Steps.frame
    for _ = 1, 50 do
        W.ms = W.ms + 100
        if f._scripts and f._scripts.OnUpdate then f._scripts.OnUpdate(f, 0.1) end
    end
end
local opened, failed
Unlock.Open(string, function(texts, problem) opened, failed = texts, problem end)
Pump()
check(opened and #opened == 2 and opened[1]:find("Bought A", 1, true) and not failed, "opened for the right account: two guides")
BNGetInfo = function() return 1, "Other#9999" end
local badTexts, badProblem
Unlock.Open(string, function(texts, problem) badTexts, badProblem = texts, problem end)
Pump()
check(not badTexts and badProblem == ns.TEXT.unlockAccount, "another account: refused")
BNGetInfo = function() return 1, "Tester#4242" end

-------------------------------------------------------------------------------
--  The guides kept, one run
-------------------------------------------------------------------------------
check(Guide.Picture() == nil, "no guide yet: no picture")
check(Guide.Empty() == ns.TEXT.noGuide, "the view says no guide is kept")
Steps.Update()
local view = rawget(_G, "SaneUISpeedLevelingSteps")
check(view and view._shown, "the view stays, with its head, while no guide is followed")
local function Shown(text)
    for _, widget in ipairs(W.frames) do
        if widget._text == text and widget._shown then return widget end
    end
end
local hintText = Shown(ns.TEXT.noGuide)
check(hintText ~= nil, "its line says how to add a guide")
-- A click on that line opens the window of the guides kept; built, with its import line and its box.
hintText._parent._scripts.OnClick(hintText._parent, "LeftButton")
local lineTitle = Shown(ns.TEXT.stringTitle)
check(lineTitle ~= nil and lineTitle._parent:IsVisible() ~= false, "a click opens the guides, with the import line")
check(not ns.off and #Core.log == 0, "the guides' window is built without an error: "
    .. tostring(Core.log[1] and Core.log[1].text))
ns.Guides.Open() -- closed again
local names = Guide.AddAll(Format.Parts("Guide([[" .. TEXT .. "]])\nGuide([[" .. Mark("name", "6-10 Hills")
    .. "\n#forever\n<< Horde\n" .. Mark("group", "Our Group") .. "\nstep\n" .. Line("take", "20") .. "\n]])"), false)
check(#names == 2 and names[1] == "1-6 Valley" and names[2] == "6-10 Hills", "two guides kept")
check(type(Core.Store(ns.name).guides["Our Group\\1-6 Valley << Horde"]) == "table",
    "kept by group and name, and for whom its head says")
check(Guide.Chosen() == "Our Group\\1-6 Valley << Horde", "a character without a guide takes the first for it")
check(Core.Character(ns.name).guide == "Our Group\\1-6 Valley << Horde", "kept for the character")
-- A guide with no step to follow for this character (every step somebody else's) is kept for the account but never
-- chosen for it (the picture would have no step to show), and said so; a step that is not there asks nothing of the guide.
;(function()
    local valley = Guide.Chosen()
    local headAlone = "#forever\n" .. Mark("name", "Head Alone") .. "\n" .. Mark("group", "Our Group")
    local elsewhere = "#forever\n" .. Mark("name", "Elsewhere") .. "\n" .. Mark("group", "Our Group") .. "\nstep << Mage\n"
        .. Line("take", "50")
    local kept, problems = Guide.AddAll({ headAlone, elsewhere }, false)
    check(#problems == 2 and problems[1]:find("Head Alone", 1, true) and problems[2]:find("Elsewhere", 1, true)
        and problems[2]:find("kept, not chosen", 1, true) and type(Core.Store(ns.name).guides["Our Group\\Elsewhere"]) == "table",
        "every step somebody else's: kept for the account, not chosen, and said: " .. tostring(problems[2]))
    check(Guide.Chosen() == valley, "the guide followed stays")
    Core.Store(ns.name).guides["Our Group\\Empty"] = { name = "Empty", group = "Our Group", text = elsewhere }
    Guide.Choose("Our Group\\Empty")
    local ok, picture = pcall(Guide.Picture)
    check(ok and Guide.Chosen() == nil and picture == nil, "one kept before with no step for you: chosen, none is followed: "
        .. tostring(picture))
    check(pcall(Steps.Update), "and the view draws nothing of it")
    Core.Store(ns.name).guides["Our Group\\Empty"] = nil
    Core.Store(ns.name).guides["Our Group\\Elsewhere"], Core.Store(ns.name).guides["Our Group\\Head Alone"] = nil, nil
    Guide.Choose(valley)
    check(Guide.Chosen() == valley, "the guide back")
    check(Guide.Line(999).shown == 999 and Guide.Line(999).text == "", "a step that is not there: its number, no words")
end)()
check(#Guide.Kept() == 2 and Guide.Kept()[1].group == "Our Group", "listed by group and name")
Guide.AddAll(opened, true)
check(#Guide.Kept() == 4, "the bought guides kept too")
for _, kept in ipairs(Guide.Kept()) do if kept.name == "Bought A" then check(kept.bought, "a bought guide is marked so") end end
W.Wait(1)

-- The first step: nothing done; the key wants its NPC.
check(Run.At() == 1 and #Run.Hand() == 1, "at the first step")
local _, friends = Guide.Targets()
check(friends and friends[1] == "Kaltunk", "the key finds its NPC")
local picture = Guide.Picture()
check(picture.title == "Valley of Trials" and picture.at == 1 and picture.total == 8, "the head: title, where")
check(picture.hand[1].lines[1].text:find("|cff%x%x%x%x%x%xKaltunk|r"), "the NPC's name in our colour")
check(not picture.hand[1].lines[1].text:find(COLOUR.friend, 1, true), "the format's colour word is gone")
check(Guide.Line(Guide.Listed()[2]).number == 2 and Guide.Line(2).text:find("copper", 1, true), "the next steps listed")
-- The format's colour words are Core's, asked once: a picture drawn again asks nothing anew.
;(function()
    local format, asked = Core.Neighbours.Format, 0
    Core.Neighbours.Format = function(...) asked = asked + 1 return format(...) end
    Guide.Picture()
    Guide.Bare("|c" .. COLOUR.foe .. "Boar|r")
    Guide.Things()
    check(asked == 0, "the format's colour words are kept from the first painting, not asked at every line: " .. asked)
    Core.Neighbours.Format = format
end)()

-- The quest givers: the step's quest to take, and the next step's.
local wants = Guide.Quests()
check(wants.take[10], "the quest giver takes the step's quest")

-- Paused, by the setting Your guide: it holds where it is, the key and the quest givers leave it, its view says so; what
-- was done meanwhile counts once it goes on.
local function Switch()
    for _, switch in ipairs(Core.Switches()) do if switch.key == "speedleveling" then return switch end end
end
check(Switch() and Switch().state == "on", "its switch offered: on")
Core.Set(ns.name, "follow", "paused")
W.Wait(0.1)
check(Switch().state == "on", "the switch is Speed Leveling's, not the guide's: paused, it stays on")
check(Guide.Targets() == nil and Guide.Quests() == nil and Guide.Uses() == nil, "paused: no targets, quests or items for it")
Steps.Update()
local pausedLine = Shown(ns.TEXT.paused)
check(pausedLine and view._shown and Shown("Valley of Trials"), "paused: its head, and a line saying so")
quests.on[10] = true
W.Fire("QUEST_ACCEPTED", 10)
W.Wait(1)
check(Run.At() == 1, "paused: it holds where it is")
pausedLine._parent._scripts.OnClick(pausedLine._parent, "LeftButton")
W.Wait(1)
check(ns.options.follow == "on" and Run.At() == 3, "a click on the line goes on, as far as was done: " .. Run.At())
Core.Set(ns.name, "follow", "off")
W.Wait(0.1)
check(not view._shown and Guide.Targets() == nil, "off: no view, no guide followed")
Core.Set(ns.name, "follow", "on")
W.Wait(0.1)
check(view._shown, "on again")

-- The switch of the minimap's satchel and the box in the bags are one: the profile, and off nothing of the guide shows.
Switch().Click("LeftButton")
W.Wait(0.1)
check(not Core.Profiles.Leveling() and Switch() and Switch().state == "off" and not view._shown and Guide.Targets() == nil,
    "a click: Speed Leveling off, the guide gone, and the switch still there to turn it on")
Switch().Click("RightButton")
check(not Core.Profiles.Leveling(), "the right button does nothing, as on the box")
Core.Set(ns.name, "follow", "on")
W.Wait(0.1)
check(not view._shown and Guide.Targets() == nil, "whatever Your guide says there: nothing of it shows")
Core.Profiles.SetLeveling(true)
W.Wait(0.1)
check(Switch().state == "on" and view._shown, "turned on elsewhere, as the box does: the switch follows, the guide is back")
Core.Profiles.SetLeveling(false)
W.Wait(0.1)
check(Switch().state == "off" and not view._shown, "and off again, though the setting is the same on both profiles")
Switch().Click("LeftButton")
W.Wait(0.1)
check(Core.Profiles.Leveling() and view._shown, "a click brings it back")

-- The quest taken: on past the step; the boars go along with the next one.
quests.on[10] = true
W.Fire("QUEST_ACCEPTED", 10)
W.Wait(1)
check(Run.At() == 3, "the step done: on past it, and past the one that goes along: " .. Run.At())
local hand = Run.Hand()
check(#hand == 2 and hand[1] == 2 and hand[2] == 3, "the boars stay at hand with the next")
local foes = Guide.Targets()
check(foes[1] == "Mottled Boar", "the key finds the boars")

-- The icons: only an item you can use, not the gear a step mentions.
W.items[6948] = { name = "Hearthstone", count = 1, use = "Astral Recall" }
W.items[770] = { name = "Some Gear", count = 1 } -- no use: not shown
Steps.Update()
local icon1 = rawget(_G, "SaneUISpeedLevelingIcon1")
check(icon1 and icon1:GetAttribute("type") == "item" and icon1:GetAttribute("item") == "item:6948",
    "the usable item is an icon; a click uses it")
-- In a fight the game holds secure buttons: the row stays as it was, and follows by itself once the fight is over.
;(function()
    W.Combat(true)
    W.items[6948].count = 0 -- the Hearthstone gone from the bags in the fight
    Steps.Update()
    check(icon1:IsProtected() and icon1._shown and icon1:GetAttribute("item") == "item:6948" and Core.Owed("speedleveling: icons"),
        "in a fight the secure icons stay as they were, the change owed to its end")
    W.Combat(false)
    check(icon1:GetAttribute("item") == nil and icon1:GetAttribute("type") == "macro" and not Core.Owed("speedleveling: icons"),
        "the fight over: the row follows by itself")
    W.items[6948].count = 1
    Steps.Update()
    check(icon1:GetAttribute("item") == "item:6948", "the Hearthstone back: its icon again")
end)()

-- At a glance: a thing to do says its count once, before its words, whichever way the game writes it; the step's number
-- stands at the top right.
;(function()
    local function Said()
        Steps.Update()
        for _, widget in ipairs(W.frames) do
            if widget._shown and type(widget._text) == "string" and widget._text:find("^2/4 ") then return widget._text end
        end
    end
    quests.objectives[10] = { { finished = false, numFulfilled = 2, numRequired = 4, text = "2/4 Boars slain" } }
    check(Said() == "2/4 Boars slain", "the game writes the count first: once: " .. tostring(Said()))
    quests.objectives[10][1].text = "Boars slain: 2/4"
    check(Said() == "2/4 Boars slain", "after the words: once, in the same place: " .. tostring(Said()))
    local label = Shown(ns.TEXT.step:format(3))
    check(label and label._points[1][1] == "TOPRIGHT", "the step's number at the card's top right")
end)()

-- The list only on the wheel, in the place of the steps at hand: the whole guide, your step in its middle and marked,
-- a line at a time from its first step to its last; the steps back at the cross, or when it is left alone.
;(function()
    Steps.Update()
    local card = Shown(ns.TEXT.step:format(3))._parent
    local all, at = Guide.Listed()
    check(all[at] == 3 and all[1] == 1 and all[#all] > 3, "the list is every step of the guide, in order")
    local function Rows()
        local rows = {}
        for _, widget in ipairs(W.frames) do
            if widget.step and widget._shown then rows[#rows + 1] = widget end
        end
        return rows
    end
    check(card._shown and #Rows() == 0 and not ns.Steps.closer._shown, "the steps alone: no list under them")
    local long, tall = ns.options.ahead, ns.Steps.ROW
    ns.options.ahead, ns.Steps.ROW = 3, 10000 -- three lines of the list, whatever the view's height
    view._mouseOver = true
    view._scripts.OnMouseWheel(view, -1)
    local rows = Rows()
    check(not card._shown and #rows == 3 and rows[2].step == all[at], "a turn of the wheel: the list in their place, your step in its middle")
    check(rows[1].step == 2 and rows[1].band._shown and rows[2].band._shown and rows[2].mark._shown
        and not rows[3].band._shown and not rows[3].mark._shown, "every step at hand clearly marked, the others not")
    check(rows[2].text._color == nil or rows[2].text._color[1] == 1, "and white")
    check(ns.Steps.closer._shown, "the cross in the corner")
    for _ = 1, 20 do view._scripts.OnMouseWheel(view, 1) end
    rows = Rows()
    check(rows[1].step == all[1], "the wheel goes up to the guide's first step, and stops there")
    view._scripts.OnMouseWheel(view, -1)
    check(Rows()[1].step == all[2], "a line at a time")
    for _ = 1, 40 do rows[1]._scripts.OnMouseWheel(rows[1], -1) end
    rows = Rows()
    check(rows[#rows].step == all[#all] and #rows == 3, "down to its last, the list full")
    -- Left alone: the mouse on it holds it; off it, the steps come back in a while, a turn of the wheel starts that anew.
    view._scripts.OnUpdate(view, ns.Steps.LINGER * 2)
    check(not card._shown, "the mouse on the view: it stays")
    view._mouseOver = false
    view._scripts.OnUpdate(view, ns.Steps.LINGER - 1)
    check(not card._shown, "the mouse gone: not at once")
    rows[1]._scripts.OnMouseWheel(rows[1], 1)
    view._scripts.OnUpdate(view, ns.Steps.LINGER - 1)
    check(not card._shown, "the wheel counts")
    Menu = { GetManager = function() return { IsAnyMenuOpen = function() return true end } end }
    view._scripts.OnUpdate(view, ns.Steps.LINGER * 2)
    check(not card._shown, "so does a menu of a line, open")
    Menu = nil
    view._scripts.OnUpdate(view, ns.Steps.LINGER - 1)
    check(not card._shown, "still within its time")
    view._scripts.OnUpdate(view, 2)
    check(card._shown and #Rows() == 0 and view._scripts.OnUpdate == nil and not ns.Steps.closer._shown,
        "left alone: the steps are back")
    -- The cross, and over a step the wheel brings it too.
    view._mouseOver = true
    card._scripts.OnMouseWheel(card, 1)
    check(not card._shown and Rows()[2].step == all[at], "a turn over a step brings the list, in the middle again")
    ns.Steps.closer._scripts.OnClick(ns.Steps.closer, "LeftButton")
    check(card._shown and #Rows() == 0, "the cross: the steps are back at once")
    card._scripts.OnMouseWheel(card, 1)
    local went, row = nil, Rows()[1]
    local go = Guide.Go
    Guide.Go = function(step) went = step end
    row._scripts.OnClick(row, "LeftButton")
    check(row._shown, "a single click does nothing")
    row._scripts.OnDoubleClick(row, "LeftButton")
    check(went == row.step, "a double click goes to that step")
    Steps.Update()
    check(card._shown and not row._shown, "and the steps are back")
    Guide.Go = go
    -- Another guide chosen while the list shows, one shorter than the list's numbers: its steps at hand, no list of the
    -- old one's.
    card._scripts.OnMouseWheel(card, 1)
    check(#Rows() == 3 and not card._shown, "the list once more")
    local chosen = Guide.Chosen()
    Guide.Choose("Our Group\\6-10 Hills << Horde")
    local ok, problem = pcall(Steps.Update)
    check(ok and #Rows() == 0 and not ns.Steps.closer._shown,
        "another guide chosen while the list shows: its steps, not the old list: " .. tostring(problem))
    Guide.Choose(chosen)
    Steps.Update()
    check(Guide.Chosen() == chosen and Shown(ns.TEXT.step:format(3)) ~= nil, "the first guide back, at its step")
    view._mouseOver = false
    ns.options.ahead, ns.Steps.ROW = long, tall
end)()

-- An objective met: the goal line done.
quests.objectives[10] = { { finished = true, numFulfilled = 4, numRequired = 4 } }
check(Run.Lines(3)[2].done and Run.Lines(3)[2].have == 4, "an objective the game says is finished, with its count")

-- The place reached: the arrow stops pointing to it once you are near.
local line, idx = Run.Target()
check(line and line.map == 1411 and idx == 3, "the arrow points to the step's place")
-- The arrow: along the way found for it (Core.Ways), whatever the map pin, straight while there is none; the ride next
-- in its words and picture, at a ride only those; at the place where the toast stands, and away while that shows.
;(function()
    local Arrow, aimed, told = ns.Arrow, nil, nil
    Core.Set(ns.name, "showArrow", false)
    Core.Ways.Serve({ Aim = function(map, x, y) aimed = map and { map, x, y } or false end, Ahead = function() return told end })
    local facing, way = rawget(_G, "GetPlayerFacing"), Run.Way
    GetPlayerFacing, Run.Way = function() return 0.5 end, function() return 200, 1.5 end
    Core.Set(ns.name, "showArrow", true)
    local frame = rawget(_G, "SaneUISpeedLevelingArrow")
    check(frame and frame._shown and aimed and aimed[1] == 1411 and math.abs(aimed[2] - 0.455) < 1e-6
        and math.abs(aimed[3] - 0.622) < 1e-6, "the arrow asks the way to the guide's place, on the game's map")
    local point, _, relative, _, y = frame:GetPoint(1)
    check(point == "TOP" and relative == "TOP" and y == -Core.TOAST_TOP,
        "at first where the toast of a new level and the travel overlay stand")
    local ring, picture, texts = nil, nil, {}
    for _, widget in ipairs(W.frames) do
        if widget._texture == Arrow.RING then ring = widget end
        if widget._kind == "FontString" and widget._parent == frame then texts[#texts + 1] = widget end
    end
    for _, widget in ipairs(W.frames) do
        if widget._kind == "Texture" and widget._parent == ring._parent and widget ~= ring and widget._texture then
            picture = widget
        end
    end
    local words, far = texts[1], texts[2]
    local said = words:GetText()
    check(ring._shown and math.abs(ring._rotation - 1) < 1e-6 and said and said ~= "", "no way known: straight at the place")
    told = { way = 2.5, yards = 340 }
    Arrow.Update(true)
    check(math.abs(ring._rotation - 2) < 1e-6 and far:GetText():find(Core.Distance(340), 1, true) and words:GetText() == said,
        "a way known: turned along it, with its yards, the step's words")
    GetPlayerFacing = function() return W.Secret() end -- the facing hidden from addons: it goes through Core.Plain
    Arrow.Update(true)
    check(not ring._shown and far:GetText() == "" and words:GetText() == said,
        "a facing the game hides: no turn and no yards, the words alone, nothing computed with it")
    GetPlayerFacing = function() return 0.5 end
    told = { way = 2.5, yards = 90, ride = "flight", to = "Crossroads" }
    Arrow.Update(true)
    check(ring._shown and words:GetText() == "Fly to Crossroads" and picture:GetTexture():find("UITaxiCursor2x", 1, true),
        "a ride next: its words and picture, the ring still leads to it")
    told = { way = 2.5, yards = 1, ride = "flight", to = "Crossroads", here = true }
    Arrow.Update(true)
    check(not ring._shown and picture._shown and far:GetText() == "" and words:GetText() == "Fly to Crossroads",
        "at the ride: nothing to point at, what to take")
    told = { way = 2.5, yards = 1 }
    Arrow.Update(true)
    check(not ring._shown and not picture._shown and far:GetText() == "" and words:GetText() == said,
        "within the place's reach by the way: only the words")
    told = { way = 2.5, yards = 340 }
    Arrow.Update(true)
    local toast = CreateFrame("Frame")
    toast:Hide()
    Core.TellsAtTop(toast)
    check(not Core.TopTaken() and frame._shown, "nothing at the toast's place: the arrow there")
    toast:Show()
    check(Core.TopTaken() and not frame._shown, "the toast or the travel overlay comes: the arrow makes way")
    Arrow.Update(true)
    check(not frame._shown, "and stays away as the guide goes on")
    toast:Hide()
    check(not Core.TopTaken() and frame._shown and ring._shown, "gone: the arrow back")
    Core.Set(ns.name, "showArrow", false)
    check(not frame._shown and aimed == false, "the arrow off: no way asked any more")
    Core.Ways.Serve(nil)
    GetPlayerFacing, Run.Way = facing, way
end)()
-- The game's map pin there, set once for the place: what you do to it stays until the guide goes on.
;(function()
    local function At(x, y)
        return pinned and pinned.uiMapID == 1411 and math.abs(pinned.position.x - x) < 1e-6
            and math.abs(pinned.position.y - y) < 1e-6
    end
    W.Wait(ns.Pin.ASK)
    check(At(0.455, 0.622), "the game's map pin on the place the guide sends you to")
    pinned = nil
    W.Wait(ns.Pin.ASK * 3)
    check(not pinned, "taken away by hand: it stays away while the place is the same")
    Core.Set(ns.name, "mapPin", false)
    Core.Set(ns.name, "mapPin", true)
    check(At(0.455, 0.622), "the switch off and on: there again")
    Core.Set(ns.name, "mapPin", false)
    check(not pinned, "the switch off: the guide's pin goes")
    local own = { uiMapID = 1411, position = { x = 0.1, y = 0.2 } }
    pinned = own
    Core.Set(ns.name, "mapPin", true)
    check(At(0.455, 0.622), "on again: the guide's pin in place of yours")
    pinned = own
    W.Wait(ns.Pin.ASK * 2)
    check(pinned == own, "a pin you put yourself stays while the place is the same")
    Core.Set(ns.name, "mapPin", false)
    check(pinned == own, "and when the guide stops: that one is not the guide's")
    pinned = nil
    Core.Set(ns.name, "mapPin", true)

    local map, x, y = Run.Point({ map = "Durotar", x = 45.5, y = 62.2 })
    check(map == 1411 and x == 0.455 and math.abs(y - 0.622) < 1e-6, "a place on a map named: the game's map, 0 to 1")
    map, x, y = Run.Point({ map = 1411, continent = 1, x = 1000, y = 500 })
    check(map == 1411 and x == 0.5 and y == 0.75, "a place in the world: north first, as the game asks")
    check(Run.Point({ map = 1411, continent = 1, x = 9000, y = 500 }) == nil, "off the map: no point")
    check(Run.Point({ map = "Nowhere", x = 1, y = 1 }) == nil, "a map the game does not know: none")
    check(Run.SamePlace(line, line) and not Run.SamePlace(line, nil) and not Run.SamePlace(line, { map = 1, x = 1, y = 1 }),
        "whether two places are the same")

    local any = C_Map.CanSetUserWaypointOnMap
    C_Map.CanSetUserWaypointOnMap = function() return false end
    Core.Set(ns.name, "mapPin", false)
    Core.Set(ns.name, "mapPin", true)
    check(not pinned, "a place the game takes no pin on: none, and no fuss")
    C_Map.CanSetUserWaypointOnMap = any
    Core.Set(ns.name, "mapPin", false)
    Core.Set(ns.name, "mapPin", true)
    check(At(0.455, 0.622), "taken again where it may")
end)()
pos.x, pos.y = 0.455, 0.622
check(Run.Distance({ map = 1411, x = 45.5, y = 62.2 }) < 2, "the distance on a map, in yards")

-- Going to a step holds you there; a click skips it and moves on; a right click goes back.
Run.Go(3)
check(Run.At() == 3, "go to a step and be held there")
local was = Run.At()
Guide.Skip(3)
check(Run.At() > was, "a click skips the step at hand and moves on")
local after = Run.At()
Guide.Back()
check(Run.At() < after, "a right click goes back")

-- A test passes a step by: step 5 is skipped while not on quest 11, held once on it.
Run.Go(5)
quests.on[11] = false
check(Run.At() == 5 and Run.Check() == false, "held at the test step while nothing changed")
Guide.Skip(5)
check(Run.At() > 5, "skipped past it")

-- The guide moves to its end and goes on to the next it names.
quests.on[11] = true
quests.done[11], quests.done[10] = true, true
local guard = 0
while not Run.Through() and guard < 20 do Run.Skip(Run.At()) guard = guard + 1 end
Guide.CheckSoon()
W.Wait(1)
check(Guide.Chosen() == "Our Group\\6-10 Hills << Horde", "through the guide: on to the one it names next")

-- Two guides of one name for different characters: both kept, apart; the one for this character is the one listed
-- as its own.
Guide.AddAll(Format.Parts("Guide([[#forever\n<< Horde\n" .. Mark("name", "Twin") .. "\n" .. Mark("group", "Our Group")
    .. "\nstep\n" .. Line("take", "40") .. "\n]])\nGuide([[#forever\n<< Horde skip\n" .. Mark("name", "Twin") .. "\n"
    .. Mark("group", "Our Group") .. "\nstep\n" .. Line("take", "41") .. "\n]])"), true)
local twins, mineTwins = 0, 0
for _, kept in ipairs(Guide.Kept()) do
    if kept.name == "Twin" then
        twins = twins + 1
        if kept.mine then mineTwins = mineTwins + 1 end
    end
end
check(twins == 2 and mineTwins == 1, "guides of one name for different characters kept apart: " .. twins)
-- A damaged saved file: a record with numbers and tables where words belong, or without a name, fails no list and no
-- menu; what of it is words counts.
;(function()
    local guides = Core.Store(ns.name).guides
    guides["Our Group\\Odd"] = { name = "Odd", group = 7, subgroup = {}, title = false, only = 9, games = "forever",
                                 text = "step\n" .. Line("take", "1") }
    guides[42] = { name = {}, group = "Our Group", text = "step" }
    local ok, kept = pcall(Guide.Kept)
    local odd, nameless
    for _, entry in ipairs(ok and kept or {}) do
        if entry.name == "Odd" then odd = entry end
        if entry.key == 42 then nameless = entry end
    end
    check(ok and odd and odd.group == "" and odd.subgroup == "" and odd.title == nil and odd.mine and not nameless,
        "a damaged record is listed by what of it is words, one without a name not at all: " .. tostring(ok and "" or kept))
    local found, after = pcall(Guide.After, { after = { { name = "Odd" } }, group = "Our Group" })
    check(found and after and after.key == "Our Group\\Odd", "and found as the guide after another: " .. tostring(after))
    guides["Our Group\\Odd"], guides[42] = nil, nil
end)()

-------------------------------------------------------------------------------
--  Guide packs, and the view's menu
-------------------------------------------------------------------------------
-- A pack of this game's guides, in the addon list, loaded on demand: its guide to choose; a part of a longer way
-- (another's next) and a divider are not listed. The other game's pack is not loaded.
local function Head(text)
    local head = Format.Head(text)
    head.zlib = E.Encode64(E.Zlib(text))
    return head
end
local packWay = table.concat({ "#forever", "<< Horde", Mark("name", "Pack Way"), Mark("group", "Packed"),
                               Mark("after", "Pack Part"), "step", Line("take", "30") }, "\n")
local packPart = table.concat({ "#forever", Mark("name", "Pack Part"), Mark("group", "Packed"), Mark("part"), "step",
                                Line("take", "31") }, "\n")
local packDivider = table.concat({ "#forever", Mark("name", "A line"), Mark("group", "Packed"), Mark("divider"), "step",
                                   "+1" }, "\n")
local function Pack(name, game)
    W.addons[#W.addons + 1] = { name = name, title = name, loadable = false, reason = "DEMAND_LOADED", enabled = 2,
                                metadata = { LoadOnDemand = "1", ["X-SaneUI-Guides"] = "1", ["X-SaneUI-Games"] = game } }
end
Pack("SaneUI_GuidesForever", "forever")
W.onDemand.SaneUI_GuidesForever = function()
    SaneUI.SpeedLeveling.TakeGuides("SaneUI_GuidesForever", { Head(packWay), Head(packPart), Head(packDivider) })
end
Pack("SaneUI_GuidesRetail", "retail")
W.onDemand.SaneUI_GuidesRetail = function() error("the other game's pack loaded") end
Guide.LoadPacks()
check(W.loaded.SaneUI_GuidesForever and not W.loaded.SaneUI_GuidesRetail, "this game's guide pack loaded, not the other's")
local listed = {}
for _, kept in ipairs(Guide.Kept()) do listed[kept.name] = kept end
check(listed["Pack Way"] and listed["Pack Way"].pack and listed["Pack Way"].mine, "its guide listed, from the pack")
check(not listed["Pack Part"] and not listed["A line"], "a part of a longer way and a divider: not listed")
check(listed["1-6 Valley"] and not listed["1-6 Valley"].pack, "the guides kept beside it")
-- The window: under their groups' headings; a pack's guide has no cross to forget it.
ns.Guides.Open()
local function Row(words)
    for _, widget in ipairs(W.frames) do
        if widget._shown and type(widget._text) == "string" and widget._text:sub(1, #words) == words then return widget end
    end
end
local packRow = Row("Pack Way")
check(Shown("Packed") and packRow and not packRow._parent.forget._shown, "the window: the pack's guide, nothing to forget")
local keptRow = Row(listed["1-6 Valley"].title) -- a guide with a title is listed by it, its subgroup after it
check(keptRow and keptRow._parent.forget._shown, "a kept one can be forgotten")
ns.Guides.Open()
-- A right click on the view: the guides by group, a click on one follows it (by its key).
Steps.Update()
local heading = Shown(Guide.Picture().title)
heading._parent._scripts.OnClick(heading._parent, "RightButton")
local menu, packed = W.menus[#W.menus], nil
for _, item in ipairs(menu) do if item.text == "Packed" then packed = item end end
local way
for _, item in ipairs(packed and packed.sub or {}) do if item.text == "Pack Way" then way = item end end
check(way ~= nil, "the view's menu: the pack's group, its guide in it")
way.fn()
check(Guide.Chosen() == "Packed\\Pack Way << Horde" and Run.Guide().name == "Pack Way", "chosen there: followed, read from the pack")
check(way.checked(), "the menu shows it chosen")
-- Through: on to its next, a part of the way that is not listed.
quests.done[30] = true
while not Run.Through() and guard < 40 do Run.Skip(Run.At()) guard = guard + 1 end
Guide.CheckSoon()
W.Wait(1)
check(Guide.Chosen() == "Packed\\Pack Part", "through: on to its next, a part from the pack")

-------------------------------------------------------------------------------
--  What the game knows done: made-up steps
-------------------------------------------------------------------------------
;(function()
    local function Follow(name, steps)
        local text = { "#forever", "<< Horde", Mark("name", name), Mark("group", "Made Up") }
        for _, lines in ipairs(steps) do
            text[#text + 1] = "step"
            for _, line in ipairs(lines) do text[#text + 1] = "    " .. line end
        end
        Guide.AddAll({ table.concat(text, "\n") })
        local key = "Made Up\\" .. name .. " << Horde"
        Guide.Choose(key)
        check(Guide.Chosen() == key, "follows the made-up guide " .. name)
        return key
    end
    local take, hand = function(q) return Line("take", tostring(q)) end, function(q) return Line("handin", tostring(q)) end
    local hearth, shop, words = Line("hearth", "", "Hearth home"), Line("shop", ""), ">>Only words"

    -- A guide picked partway: the game knows the first steps done, so it goes on by itself, past steps it cannot judge
    -- (a hearth, a vendor, a thing to tick by hand) that a later done step shows are behind you.
    quests.done[601], quests.on[602] = true, true
    quests.objectives[602] = { { finished = true, numFulfilled = 3, numRequired = 3 } }
    local key = Follow("Made Way", {
        { take(601) },              -- 1  handed in
        { hearth },                 -- 2  cannot be judged: lies behind 4
        { shop },                   -- 3  so does this
        { hand(601), take(602) },   -- 4
        { "+Tick this by hand" },   -- 5  lies behind 6
        { Line("goal", "602,1") },  -- 6  an objective finished
        { Line("level", "9") },     -- 7  a level not reached: you stop here
        { hearth },                 -- 8
        { words },                  -- 9  nothing to do
        { hand(603) },              -- 10
        { take(604) },              -- 11
        { hand(605) },              -- 12
        { take(606) },              -- 13
        { take(607) },              -- 14
    })
    check(Run.At() == 7 and Run.Place() == 7, "picked partway: on as far as the game knows, past what it cannot judge: " .. Run.At())
    check(Run.Ticked(2) and Run.Ticked(3) and Run.Ticked(4) and Run.Ticked(5) and Run.Ticked(6),
        "those behind you show as done, judged or not")
    check(not Run.Ticked(7) and not Run.Ticked(8) and not Run.Ticked(9), "those ahead do not: nothing to do is not done")
    quests.done[603] = true
    check(Run.Ticked(10), "a step ahead the game knows is done shows as done before you get there")
    check(not Guide.Line(8).done and Guide.Line(10).done, "the list's ticks are what the game knows, not where you are")
    quests.done[603] = nil

    -- A level the game hides (a secret value) goes through Core.Plain: no level reached, nothing computed with it.
    local plainLevel = UnitLevel
    UnitLevel = function() return W.Secret() end
    check(Run.Check() == false and Run.At() == 7, "a level the game hides is no level reached: the step stays, no error")
    UnitLevel = plainLevel
    -- The level comes: on to the hearth, which stays: nothing after it is known done yet. Your click still does it.
    W.level = 9
    check(Run.Check() and Run.At() == 8, "a level reached moves it on")
    check(Run.Check() == false and Run.At() == 8, "a step that cannot be judged stays while nothing after it is known done")
    Run.Saw("hearth")
    check(Run.Check() and Run.At() == 10, "seen as it happens it is done, as ever")
    Guide.Back()
    Guide.Back()
    check(Run.At() == 8 and Run.Place() == 10, "back to the hearth: your place stays")
    quests.done[603] = true
    Guide.Skip(8)
    check(Run.At() == 11, "a click goes on, back to your place and past what got done meanwhile: " .. Run.At())
    check(not Core.Character(ns.name).skipped[key][8], "it was seen done: the click marks nothing")
    Run.Go(5)
    Guide.Skip(5)
    check(Run.At() == 11 and Core.Character(ns.name).skipped[key][5], "a thing only you can tick: your click ticks it, back to your place")

    -- A step the game can judge as still to do is never passed by itself, whatever is done after it.
    quests.done[605] = true
    check(Run.Check() == false and Run.At() == 11 and Run.Ticked(12), "a quest still to take holds you; done ones after it just show")
    Guide.Skip(11)
    check(Run.At() == 13, "skipped by hand: past the done one too")

    -- Back to a step the game knows is done: you can look at it, it stays done, the guide keeps your place.
    Run.Go(4)
    check(Run.At() == 4 and Run.Place() == 13, "gone back: the step shown, your place kept")
    check(Run.Check() == false and Run.At() == 4, "it stays for you to look at, done as it is")
    local picture = Guide.Picture(3)
    check(picture.at == 4 and picture.place == 13 and picture.hand[#picture.hand].number == 4 and picture.hand[#picture.hand].done,
        "the picture: that step, done; how far you are stays your place")
    check(Guide.Line(5).done and Guide.Line(7).done, "the steps after it still show as done")
    check(Core.Character(ns.name).at[key] == 13, "your place is what is kept")
    Steps.Update()
    check(Shown(ns.TEXT.step:format(4) .. " " .. Steps.TICK), "the view: a tick by the step's number")
    check(Shown(ns.TEXT.progress:format(13, 14, 93)), "the view: how far you are is your place")
    Run.Use(Run.Guide())
    check(Run.At() == 13 and Run.Place() == 13, "a /reload while looking back: at your place")
    Run.Go(4)
    Guide.Back()
    check(Run.At() == 3 and Run.Place() == 13, "a right click goes further back, your place stays")
    Run.Go(4)
    Guide.Skip(4)
    check(Run.At() == 13 and not Core.Character(ns.name).skipped[key][4], "a click goes on, back to your place, marking nothing")

    -- Back to redo a step: something the game says is open, or one it cannot judge. Held until done, then your place.
    quests.done[601] = nil
    check(not Run.Ticked(1), "a step behind you the game says is open shows open")
    Run.Go(1)
    check(Run.At() == 1 and Run.Check() == false and Run.At() == 1, "gone back to redo it: it waits for you")
    quests.on[601] = true
    check(Run.Check() and Run.At() == 13 and Run.Place() == 13, "done: back to your place")
    Run.Go(3)
    check(Run.Check() == false and Run.At() == 3, "a step it cannot judge, gone back to, stays though a later one is done")
    Run.Saw("shop")
    check(Run.Check() and Run.At() == 13, "done as it happens: back to your place")

    -- Going forward is another thing: that step becomes your place, and what you jumped over shows open.
    Run.Go(14)
    check(Run.At() == 14 and Run.Place() == 14 and not Run.Ticked(13), "a step after your place becomes your place")
    Run.Go(2)
    Run.Go(14)
    check(Run.At() == 14 and Run.Place() == 14 and Run.Check() == false, "going to your place ends looking back")

    -- What proves nothing: a level (it can be had ahead of the guide), a thing asked already, one that only goes along.
    quests.done[610] = true
    Follow("Made Level", { { hearth }, { Line("level", "3") }, { take(611) } })
    check(Run.At() == 1, "a level reached is no proof you came this way")
    Follow("Made Twice", { { take(610) }, { hearth }, { take(610) }, { hand(612) } })
    check(Run.At() == 2, "a quest the guide asks again proves nothing about the step between")
    Follow("Made Along", { { hearth }, { Mark("together", "next"), take(610) }, { hand(612) } })
    check(Run.At() == 1, "a step that only goes along is no proof")
    quests.done[612] = true
    check(Run.Check() and Run.Through(), "a step of its own is, and that was the guide's last")

    -- The cost: a check reads the step you are at and at most Run.PROOF more, however long the guide.
    local function Asks(fn)
        local count = 0
        local done, have = C_QuestLog.IsQuestFlaggedCompleted, C_Item.GetItemCount
        C_QuestLog.IsQuestFlaggedCompleted = function(q) count = count + 1 return done(q) end
        C_Item.GetItemCount = function(id) count = count + 1 return have(id) end
        fn()
        C_QuestLog.IsQuestFlaggedCompleted, C_Item.GetItemCount = done, have
        return count
    end
    local long = {}
    for n = 1, 400 do long[n] = { take(700 + n) } end
    Follow("Made Long", long)
    check(Asks(Run.Check) <= 2, "a step still to do: only that step is asked")
    long = {}
    for n = 1, 400 do long[n] = { Line("carry", (9000 + n) .. ",1") } end
    Follow("Made Carry", long)
    local asks = Asks(Run.Check)
    check(Run.At() == 1 and asks <= Run.PROOF + 2, "a step it cannot judge: the way ahead read so far and no further: " .. asks)
    W.level = 5
end)()

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
check(not ns.off and #Core.log == 0, "no error stood the module down along the way: "
    .. tostring(Core.log[1] and Core.log[1].text))
ns.off = true
ns.GiveBack()
check(not Steps.Frame(), "stood down: the guide is hidden")
check(not pinned, "and its map pin gone")

io.write(("Speed Leveling guide: all %d checks passed.\n"):format(passed))
