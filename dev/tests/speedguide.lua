-- Runs Speed Leveling's guide against the stand-in client (wowstub.lua): a guide written as text read into our shape
-- for one character (its head, who a step and a line are for, each kind of command, step marks, what cannot be read,
-- which games it is for), the import string of bought guides opened for the account (Unlock), the guide run (moving
-- on past done steps, the steps at hand, skipping, going back and being held there, what the game tells as it
-- happens, places, tests that pass a step by, the next guide), the guides kept (packed, chosen), the picture over the
-- world (drawn, clicked, scrolled, hidden), the arrow, the icons (only what can be used; secure), and standing down.
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

C_Timer.NewTicker = function(every, fn)
    local ticker = { cancelled = false }
    function ticker:Cancel() self.cancelled = true end
    local function Tick()
        if ticker.cancelled then return end
        fn(ticker)
        if not ticker.cancelled then C_Timer.After(every, Tick) end
    end
    C_Timer.After(every, Tick)
    return ticker
end

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
check(picture.ahead[1].number == 2 and picture.ahead[1].text:find("copper", 1, true), "the next steps listed")

-- The quest givers: the step's quest to take, and the next step's.
local wants = Guide.Quests()
check(wants.take[10], "the quest giver takes the step's quest")

-- Paused, by its switch in the minimap's satchel (Core.Offer): it holds where it is, the key and the quest givers leave
-- it, its view says so; what was done meanwhile counts once it goes on.
local function Switch()
    for _, switch in ipairs(Core.Switches()) do if switch.key == "speedleveling" then return switch end end
end
check(Switch() and Switch().state == "on", "its switch offered: on")
Switch().Click("LeftButton")
W.Wait(0.1)
check(ns.options.follow == "paused" and Switch().state == "paused", "a click pauses it")
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
check(not view._shown and Guide.Targets() == nil and Switch().state == "off", "off: no view, no guide followed")
Switch().Click("LeftButton")
W.Wait(0.1)
check(ns.options.follow == "on" and view._shown, "a click on the switch turns it on again")

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

-- An objective met: the goal line done.
quests.objectives[10] = { { finished = true, numFulfilled = 4, numRequired = 4 } }
check(Run.Lines(3)[2].done and Run.Lines(3)[2].have == 4, "an objective the game says is finished, with its count")

-- The place reached: the arrow stops pointing to it once you are near.
local line, idx = Run.Target()
check(line and line.map == 1411 and idx == 3, "the arrow points to the step's place")
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
--  Standing down
-------------------------------------------------------------------------------
check(not ns.off and #Core.log == 0, "no error stood the module down along the way: "
    .. tostring(Core.log[1] and Core.log[1].text))
ns.off = true
ns.GiveBack()
check(not Steps.Frame(), "stood down: the guide is hidden")
check(not pinned, "and its map pin gone")

io.write(("Speed Leveling guide: all %d checks passed.\n"):format(passed))
