-- Runs Speed Leveling's guide against the stand-in client (wowstub.lua): a guide written as text read into our shape
-- for one character (its head, who a step and a line are for, each kind of command, step marks, what cannot be read),
-- the guide run (moving on past done steps, the steps at hand, skipping, going back and being held there, what the
-- game tells as it happens, places, tests that pass a step by, the next guide), the guides kept, the known guide's
-- loaded guide as our picture (its colours, its steps, going to a step), the view over the world (drawn, clicked,
-- scrolled, its menu, hidden), the arrow (where it points, what to do there, turned, how far and how long), the icons
-- to use and to target (secure, held in a fight), the known guide's window, arrow and boxes lent and given back, and
-- standing down.
-- The guide format's own words come from Core (Core.Neighbours.KNOWN.guide): the test names none of its own.
-- Usage, from the project folder:  lua5.1 dev/tests/speedguide.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

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
function methods:GetScale() return self._scale or 1 end
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

-- The key's secure parts, enough for it to start beside the guide (dev/tests/speedleveling.lua tries them).
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
W.level = 5
local xp = 100
UnitXP = function() return xp end
UnitXPMax = function() return 400 end
local money = 50
GetMoney = function() return money end
GetRealZoneText = function() return "Durotar" end
GetSubZoneText = function() return "Valley of Trials" end
local taxi = false
UnitOnTaxi = function() return taxi end

-- The quests: taken (on), handed in (done), ready to hand in (ready), their objectives.
local quests = { on = {}, done = {}, ready = {}, objectives = {} }
C_QuestLog = rawget(_G, "C_QuestLog") or {}
C_QuestLog.IsOnQuest = function(quest) return quests.on[quest] == true end
C_QuestLog.IsQuestFlaggedCompleted = function(quest) return quests.done[quest] == true end
C_QuestLog.IsComplete = function(quest) return quests.ready[quest] == true end
C_QuestLog.GetQuestObjectives = function(quest) return quests.objectives[quest] end
C_QuestLog.GetNumQuestLogEntries = function() return 0 end
local known = {}
IsPlayerSpell = function(spell) return known[spell] == true end

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
local Format, Run, Guide, Steps = ns.Format, ns.Run, ns.Guide, ns.Steps
local orc = { side = "Horde", race = "Orc", class = "WARRIOR" }
local human = { side = "Alliance", race = "Human", class = "MAGE" }

-------------------------------------------------------------------------------
--  Reading a guide
-------------------------------------------------------------------------------
local TEXT = table.concat({
    "<< Horde",
    Mark("name", "1-6 Valley"),
    Mark("group", "Our Group"),
    Mark("after", "6-10 Hills;Other Group\\6-10 Other"),
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
    "    " .. Line("foe", "Mottled Boar"),
    "    " .. Line("money", ">0.01"),
    "step",
    "    " .. Mark("label", "Teeth"),
    "    " .. Line("place", "1411,45.5,62.2"),
    "    " .. Line("goal", "10,1 --Mottled Boar slain (4)"),
    "    " .. Line("carry", "770,6,10,2"),
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

local parts = Format.Parts("local x = 1\nGuide([[" .. TEXT .. "]])\nGuide([[" .. Mark("name", "Second") .. "\nstep\n]])")
check(#parts == 2 and parts[1] == TEXT, "a Lua file's long brackets: each pair a guide")
check(#Format.Parts(TEXT) == 1 and #Format.Parts("  \n ") == 0, "a bare text: one guide; nothing: none")

local guide, problems = Format.Read(TEXT, orc)
check(guide.mine and guide.name == "1-6 Valley" and guide.group == "Our Group", "the head: its name and group")
check(guide.after[1] == "6-10 Hills" and guide.after[2] == "Other Group\\6-10 Other", "the guides after it, in order")
check(guide.defaultFor[1] == "Orc" and guide.defaultFor[2] == "Troll", "who starts with it")
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
    and boars.unless[1].copper == 100, "a creature for the key; passed by with a silver")
local teeth = guide.steps[3]
check(guide.labels.Teeth == 3 and teeth.label == "Teeth", "a step's name")
check(teeth.lines[1].what == "place" and teeth.lines[1].map == 1411 and teeth.lines[1].x == 45.5, "a place on a map, no reach")
check(teeth.lines[2].what == "goal" and teeth.lines[2].quest == 10 and teeth.lines[2].goal == 1, "an objective, the comment cut off")
check(teeth.lines[3].what == "carry" and teeth.lines[3].item == 770 and teeth.lines[3].count == 6 and teeth.lines[3].quest == 10,
    "an item to carry, for a quest")
check(teeth.items[1] == 6948, "an item for the key")
check(teeth.lines[4].what == "say" and teeth.lines[4].words == "Words of a command not known", "a command not known: its words")
check(#problems == 1 and problems[1]:find("cannot be read", 1, true), "a command that cannot be read is said: " .. tostring(problems[1]))
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
check(Format.For(orc, "Orc/Troll Warrior") and not Format.For(orc, "!Orc") and Format.For(orc, "!Undead")
    and Format.For({ race = "Scourge" }, "Undead"), "who a line is for")

-------------------------------------------------------------------------------
--  The guides kept, one run
-------------------------------------------------------------------------------
check(Guide.Picture() == nil, "no guide yet: nothing to show")
check(not rawget(_G, "SaneUISpeedLevelingSteps"), "and no view made")
local names = Guide.Add("Guide([[" .. TEXT .. "]])\nGuide([[" .. Mark("name", "6-10 Hills") .. "\n<< Horde\nstep\n"
    .. Line("take", "20") .. "\n]])")
check(#names == 2 and names[1] == "1-6 Valley" and names[2] == "6-10 Hills", "two guides kept")
check(Core.Store(ns.name).guides["1-6 Valley"].text == TEXT, "kept as their text")
check(Guide.Chosen() == "1-6 Valley", "a character without a guide takes the first for it")
check(Core.Character(ns.name).guide == "1-6 Valley", "kept for the character")
check(#Guide.Kept() == 2 and Guide.Kept()[1].group == "", "listed by group and name")
W.Wait(1)

-- The first step: nothing done; the key wants its NPC.
check(Run.At() == 1 and #Run.Hand() == 1, "at the first step")
local _, friends = Guide.Targets()
check(friends and friends[1] == "Kaltunk", "the key finds its NPC")
local picture = Guide.Picture()
check(picture.title == "Valley" and picture.levels == "1-6" and picture.at == 1 and picture.total == 8, "the head: zone, levels, where")
check(picture.hand[1].lines[1].text:find("|cff%x%x%x%x%x%xKaltunk|r"), "the NPC's name in our colour")
check(not picture.hand[1].lines[1].text:find(COLOUR.friend, 1, true), "the format's colour word is gone")
check(picture.hand[1].lines[2].count and not picture.hand[1].lines[2].done, "the quest to take: a thing to do")
check(picture.ahead[1].number == 2 and picture.ahead[1].text:find("copper", 1, true), "the next steps listed")
local iconRow = rawget(_G, "SaneUISpeedLevelingIcons")
local icon1, icon2 = rawget(_G, "SaneUISpeedLevelingIcon1"), rawget(_G, "SaneUISpeedLevelingIcon2")
check(iconRow and iconRow._shown and iconRow._points[1][2] == UIParent and iconRow._points[1][5] == 600 + ns.Icons.ABOVE,
    "the icons over the guide's top, placed by the screen")
check(icon1._template == "SecureActionButtonTemplate" and icon1:GetAttribute("type") == "macro"
    and icon1:GetAttribute("macrotext") == "/cleartarget\n/targetexact Kaltunk\n/tm [exists] !8", "a click targets the NPC, marked")
check(not (icon2 and icon2._shown), "one icon")

-- The quest taken: on past the step; the boars go along with the next one.
quests.on[10] = true
W.Fire("QUEST_ACCEPTED", 10)
W.Wait(1)
check(Run.At() == 3, "the step done: on past it, and past the one that goes along: " .. Run.At())
local hand = Run.Hand()
check(#hand == 2 and hand[1] == 2 and hand[2] == 3, "the boars stay at hand with the next")
local foes = Guide.Targets()
check(foes[1] == "Mottled Boar", "the key finds the boars")
W.items[6948] = { name = "Hearthstone", count = 1 }
Steps.Update()
icon1, icon2 = rawget(_G, "SaneUISpeedLevelingIcon1"), rawget(_G, "SaneUISpeedLevelingIcon2")
check(icon1:GetAttribute("type") == "item" and icon1:GetAttribute("item") == "item:6948", "the step's item first: a click uses it")
check(icon2._shown and icon2:GetAttribute("macrotext"):find("Mottled Boar", 1, true), "then the creature to fight")
W.combat = true
W.items[6948] = nil
Steps.Update()
check(icon1:GetAttribute("item") == "item:6948", "in a fight the game holds them: as they were")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(icon1:GetAttribute("macrotext"):find("Mottled Boar", 1, true) and not icon2._shown, "after it: what is wanted now")
local items = Guide.Uses()
check(items[1] == 6948, "and the step's item")

-- A count on the objective, then the money that passes the boars by.
quests.objectives[10] = { { text = "Mottled Boar slain: 2/4", finished = false, numFulfilled = 2, numRequired = 4 } }
W.items[770] = { name = "Scorpid Stinger", count = 3 }
picture = Guide.Picture()
local counted
for _, line in ipairs(picture.hand[2].lines) do if line.have == 2 and line.need == 4 then counted = line end end
check(counted and counted.text:find("Mottled Boar slain", 1, true), "an objective with its count")
money = 200
W.Fire("PLAYER_MONEY")
W.Wait(1)
check(#Run.Hand() == 1, "a silver: the boars are passed by")

-- Done: the objective and the items; the step that stays comes along. On quest 11, its step waits for its hand-in.
quests.on[11] = true
quests.objectives[10][1].finished = true
W.items[770].count = 6
W.Fire("BAG_UPDATE_DELAYED")
W.Wait(1)
check(Run.At() == 5, "the objective and the items done: on: " .. Run.At())
check(Run.Hand()[1] == 4 and Run.Hand()[2] == 5, "the level to reach stays at hand")
-- Off quest 11: its step is passed by; the step aside waits for its place.
quests.on[11] = nil
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)
check(Run.At() == 6, "not on its quest: the step passed by: " .. Run.At())
W.place = { -4250, -600, 0, 1 } -- the game's two numbers of a place in the world, its height, the continent
W.Wait(2)
check(Run.At() == 6, "too far from the place")
-- The arrow: to the place, the yards under it, turned as the player faces.
local place, there = Guide.Target()
check(place and place.continent == 1 and place.near == 20 and there.number == 6, "the arrow points to the step's place")
check(Guide.Doing(there) == "go", "getting there is all: the map's picture")
local yards, way = Run.Way(place)
check(math.abs(yards - 49.75) < 0.01 and math.abs(way - math.atan2(-0.5, 49.75)) < 1e-6, "how far and which way")
Steps.Update()
local arrowFrame = rawget(_G, "SaneUISpeedLevelingArrow")
local ring, picture, words, far
for _, widget in ipairs(W.frames) do
    if widget._texture == ns.Arrow.RING then ring = widget end
end
for _, widget in ipairs(W.frames) do
    if widget._parent == ring._parent and widget._kind == "Texture" and type(widget._texture) == "string"
        and widget._texture:find("CURSOR", 1, true) then picture = widget end
    if widget._parent == arrowFrame and widget._kind == "FontString" then
        if widget._text == "Get there" then words = widget elseif widget._text == "50 yd" then far = widget end
    end
end
check(arrowFrame and arrowFrame._shown and ring._shown, "the arrow: a part of its own, its leather ring shown")
check(picture and picture._texture:find("Directions", 1, true), "in its hole: the picture of getting there")
check(words and far, "under it what to do there, and how far")
check(math.abs(ring._rotation - way) < 1e-6, "facing north: turned the way to the place")
facing = math.pi / 2
Steps.Update()
check(math.abs(ring._rotation - (way - math.pi / 2)) < 1e-6, "facing west: turned with you")
facing = 0
W.clock = W.clock + 1
W.place = { -4240, -600, 0, 1 }
Steps.Update()
check(far._text:find("40 yd", 1, true) and far._text:find("11 s", 1, true), "closing in: the time to get there: " .. far._text)
W.place = { -4250, -600, 0, 1 }
W.clock = W.clock + 1
Steps.Update()
check(not far._text:find(" s", 1, true), "walking away: no time")
Core.Set(ns.name, "showArrow", false)
check(not arrowFrame._shown, "Show the arrow off: hidden")
Core.Set(ns.name, "showArrow", true)
check(arrowFrame._shown, "on again")
W.place = { -4200, -605, 0, 2 }
W.Wait(2)
check(Run.At() == 6, "on another continent")
W.place = { -4200, -605, 0, 1 }
W.Wait(2)
check(Run.At() == 7, "near enough: on")
check(Guide.Target() == nil, "no place left: the arrow has nowhere to point")
Steps.Update()
check(not arrowFrame._shown, "and is out of sight")

-- The hearth: as it is cast.
check(Run.Uses()[1] == Run.HEARTHSTONE, "the hearth: the key's Hearthstone")
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", Run.HEARTH_SPELL)
W.Wait(1)
check(Run.At() == 8, "hearthed: on")

-- Back, held there though done; a click skips it; skipping the label's step passes the one that needs it.
Guide.Back()
check(Run.At() == 7, "back one step")
W.Fire("QUEST_LOG_UPDATE")
W.Wait(1)
check(Run.At() == 7, "held there though it is done")
Guide.Go(3)
Guide.Skip(3)
check(Run.At() == 8 and Core.Character(ns.name).skipped["1-6 Valley"][3], "skipped: on, kept as skipped; the step "
    .. "that needs it passed by: " .. Run.At())
check(Core.Character(ns.name).at["1-6 Valley"] == 8, "where you are, kept")

-- The level: the step that stays goes; the last step done: the next guide.
W.level = 6
quests.done[10] = true
W.Fire("PLAYER_LEVEL_UP", 6)
W.Wait(1)
check(Guide.Chosen() == "6-10 Hills" and Run.At() == 1, "through: on to the guide it names next")

-- Remove and choose.
Guide.Choose("1-6 Valley")
check(Guide.Chosen() == "1-6 Valley" and Run.At() == 9, "chosen again: where it was left")
Guide.Remove("6-10 Hills")
check(#Guide.Kept() == 1, "a guide forgotten")
Guide.Go(1)

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
quests.done[10], quests.on[10] = nil, nil
Guide.Go(1)
W.Wait(1)
local view = rawget(_G, "SaneUISpeedLevelingSteps")
check(view and view:IsShown(), "the view over the world")
local cards, rows = {}, {}
for _, widget in ipairs(W.frames) do
    if widget._parent == view and widget._kind == "Button" and widget._scripts.OnClick and widget._shown then
        if widget.label then cards[#cards + 1] = widget end
    end
    if widget._parent == view and widget._scripts.OnDoubleClick and widget._shown then rows[#rows + 1] = widget end
end
check(#cards == 1 and cards[1].number == 1 and cards[1].label._text == "Step 1", "a card for the step at hand")
check(#rows == 5 and ns.options.ahead == 5, "the next steps, as many as the switch says: " .. #rows)
check(rows[2]._alpha < rows[1]._alpha, "fading as they go down")
check(rows[1].text._color[1] == Steps.GREY and not rows[1].text._text:find("|c", 1, true), "greyed out, no colours in them")
local target = rows[1].step
rows[1]._scripts.OnDoubleClick(rows[1])
W.Wait(1)
check(target == 2 and Run.At() == target, "a double click goes there")
cards[1]._scripts.OnClick(cards[1], "RightButton")
W.Wait(1)
check(Run.At() == 1, "a right click goes back one")
cards[1]._scripts.OnClick(cards[1], "LeftButton")
W.Wait(1)
check(Run.At() >= 2, "a click skips the step")
Guide.Go(1)
Core.Set(ns.name, "ahead", 2)
W.Wait(1)
local shown = 0
for _, row in ipairs(rows) do if row._shown then shown = shown + 1 end end
check(shown == 2, "two next steps listed")
-- The wheel: back to the step at hand and before, as far as the first step; down again.
Guide.Go(3)
W.Wait(1)
rows[1]._scripts.OnMouseWheel(rows[1], 1)
rows[1]._scripts.OnMouseWheel(rows[1], 1)
check(rows[1].step == 2 and rows[1].tick._text == Steps.TICK and rows[2].step == 3 and rows[2].tick._text == "",
    "scrolled up: a done step with its tick, then the one at hand: " .. tostring(rows[1].step))
rows[1]._scripts.OnMouseWheel(rows[1], 5)
check(rows[1].step == 1, "no further up than the first step")
rows[1]._scripts.OnMouseWheel(rows[1], -1)
check(rows[1].step == 2, "down again")
-- A right click on a listed step: its menu, Go to step.
local menus = #W.menus
rows[1]._scripts.OnClick(rows[1], "RightButton")
local menu = W.menus[#W.menus]
check(#W.menus == menus + 1 and menu[2] and menu[2].text == ns.TEXT.goToStep:format(2), "its menu: Go to step 2")
menu[2].fn()
W.Wait(1)
check(Run.At() == 2, "and it goes there")
Core.Set(ns.name, "showGuide", false)
check(not view:IsShown(), "Show the guide off: hidden")
Core.Set(ns.name, "showGuide", true)
check(view:IsShown(), "on: shown again")

-------------------------------------------------------------------------------
--  The known guide's loaded guide
-------------------------------------------------------------------------------
local own = CreateFrame("Frame", KNOWN.window, UIParent)
local menuOpened = 0
own[KNOWN.menu] = function() menuOpened = menuOpened + 1 end
local ownArrow = CreateFrame("Frame", nil, UIParent)
ownArrow.element = { wx = -600.5, wy = -4300.25, instance = 1 }
ownArrow:Hide()
local boxes = {}
for index, name in ipairs(KNOWN.boxes) do
    boxes[index] = CreateFrame("Frame", name, UIParent)
    boxes[index]:SetPoint("CENTER", UIParent, "CENTER", 0, index * 50)
    boxes[index]:SetWidth(100)
end
local elements = {
    { text = "Talk to |cff00ff25Gornek|r", textOnly = true },
    { text = "Accept Cutting Teeth", tag = "accept" },
    { text = "Cutting Teeth: 3/10", completed = false },
    { text = "Accepted", completed = true },
}
local steps = {}
for index = 1, 12 do steps[index] = { index = index, elements = { { text = "Step " .. index .. " words", textOnly = true } } } end
steps[4].elements = elements
steps[6].optional = true
local book = { [KNOWN.current] = { name = "6-10 Durotar", steps = steps },
               [KNOWN.progress] = function() return 4 end,
               [KNOWN.colourTable] = { [COLOUR.friend] = "FF00FF25" },
               [KNOWN.part] = { [KNOWN.lists] = function() return { "Gornek" }, {}, {} end },
               [KNOWN.items] = { [5000] = true }, [KNOWN.spells] = {}, [KNOWN.arrow] = ownArrow }
W.items[5000] = { name = "Cleansing Totem", count = 2 }
local went
book[KNOWN.go] = function(number) went = number end
own[KNOWN.hand] = { steps[4] }
local library = { GetAddon = function(_, name) return name == KNOWN.addon and book or nil end }
_G[KNOWN.stub] = { GetLibrary = function(_, name) return name == KNOWN.library and library or nil end }
W.loaded[KNOWN.addon] = true

picture = Guide.Picture()
check(picture.known and picture.title == "Durotar" and picture.levels == "6-10" and picture.at == 4 and picture.total == 12,
    "the known guide's guide: its zone, levels, step")
check(picture.hand[1].number == 4 and #picture.hand[1].lines == 4, "its step at hand with its lines")
check(not picture.hand[1].lines[1].text:find("00ff25", 1, true), "its colour of NPCs made ours")
check(picture.hand[1].lines[2].what == "take", "a line's command in our word")
check(picture.hand[1].lines[3].have == 3 and picture.hand[1].lines[3].need == 10 and picture.hand[1].lines[4].done,
    "a count read from its words; a line done")
check(picture.ahead[1].number == 5 and picture.ahead[2].number == 7, "the next steps, the optional one left out")
check(Guide.Targets()[1] == nil and select(2, Guide.Targets())[1] == "Gornek", "the key finds its NPC")
check(Guide.Uses()[1] == 5000, "and its items")
-- A click ticks a step at hand off whole, line by line by its own function, whichever step it is.
local ticked = {}
book[KNOWN.complete] = function(holder) ticked[#ticked + 1] = holder.element end
steps[3].elements = { { text = "Kill boars along the way", textOnly = false }, { text = "+ by hand" } }
Guide.Skip(4)
check(#ticked == #elements and ticked[1] == elements[1] and went == nil, "a click: each line ticked off by its own function")
ticked = {}
Guide.Skip(3)
check(#ticked == 2 and ticked[1] == steps[3].elements[1], "a step kept in view before the one it is at: ticked off too")
-- Without such a function: past the step clicked, from the one it is at on.
book[KNOWN.complete] = nil
Guide.Skip(5)
check(went == 6, "no function to tick: past the step clicked")
went = nil
Guide.Skip(3)
check(went == nil, "before the one it is at: nothing")
book[KNOWN.complete] = function(holder) ticked[#ticked + 1] = holder.element end
-- The list from any step: back through the done ones, a tick before each.
picture = Guide.Picture(3, -3)
check(picture.shift == -3 and picture.ahead[1].number == 2 and picture.ahead[1].done and not picture.ahead[3].done,
    "the list scrolled back: done steps, ticked")
picture = Guide.Picture(3, -10)
check(picture.shift == -4 and picture.ahead[1].number == 1, "no further back than the first step")
Guide.Back()
check(went == 3, "a right click: back one, by its own function")
Steps.Update()
check(own._alpha == 0 and own._scale == Steps.UNSEEN, "its own window unseen while ours shows its guide")
check(Guide.Target() == nil and ownArrow._parent == UIParent, "its arrow not shown: ours points nowhere, its own left")
ownArrow:Show()
Steps.Update()
place, there = Guide.Target()
check(place and place.continent == 1 and place.x == -600.5 and place.y == -4300.25 and Guide.Doing(there) == "take",
    "its arrow shown: ours points to its place, a quest to take there")
check(ownArrow._parent ~= UIParent and not ownArrow:IsVisible(), "its own arrow put away")
check(boxes[1]._parent == UIParent and boxes[1]._points[1][1] == "CENTER", "its own boxes left as they are: its own")
check(rawget(_G, "SaneUISpeedLevelingIcon1"):GetAttribute("item") == "item:5000"
    and rawget(_G, "SaneUISpeedLevelingIcon2"):GetAttribute("macrotext"):find("Gornek", 1, true), "its item and its NPC")
Core.Set(ns.name, "icons", false)
check(not rawget(_G, "SaneUISpeedLevelingIcons")._shown, "icons off: the row hidden")
Core.Set(ns.name, "icons", true)
check(rawget(_G, "SaneUISpeedLevelingIcons")._shown, "on: shown again")
Core.Set(ns.name, "knownWindow", false)
check(own._alpha == 1 and own:GetScale() == 1, "Hide its own window off: given back as it was")
Core.Set(ns.name, "knownWindow", true)
check(own._alpha == 0, "on: unseen again")
own:Hide()
Steps.Update()
check(not view:IsShown() and own._alpha == 1, "its window closed: ours hidden too, its own given back")
own:Show()
Steps.Update()
check(view:IsShown(), "open again: shown")
Core.Set(ns.name, "knownGuide", false)
check(not Guide.Picture().known and Guide.Picture().title == "Valley" and own._alpha == 1,
    "the known guide's switch off: the pasted guide, its window given back")
Core.Set(ns.name, "knownGuide", true)

-- The menu on the zone.
local header
for _, widget in ipairs(W.frames) do
    if widget._parent == view and widget._kind == "Button" and widget._scripts.OnClick and not widget.label
        and not widget._scripts.OnDoubleClick then header = widget end
end
header._scripts.OnClick(header)
check(menuOpened == 1, "a right click on the zone: the known guide's own menu")
rows[1]._scripts.OnClick(rows[1])
local rowMenu = W.menus[#W.menus]
check(rowMenu[3] and rowMenu[3].text == ns.TEXT.guideMenu, "a listed step's menu: the known guide's own menu under Go to")
rowMenu[3].fn()
check(menuOpened == 2, "which opens it")
Core.Set(ns.name, "knownGuide", false)
menus = #W.menus
header._scripts.OnClick(header)
check(#W.menus == menus + 1 and #W.menus[#W.menus] >= 3 and menuOpened == 2, "the pasted guide: our menu, the guides and paste")
Core.Set(ns.name, "knownGuide", true)

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
Steps.Update()
check(own._alpha == 0, "lent before standing down")
ns.StandDown("a test")
check(not view:IsShown() and own._alpha == 1 and own:GetScale() == 1, "standing down: hidden, its window given back")
check(ownArrow._parent == UIParent and boxes[1]._parent == UIParent, "and its arrow and boxes")
Steps.Update()
check(not view:IsShown(), "nothing more after standing down")

io.write(("Speed Leveling's guide: all %d checks passed.\n"):format(passed))
