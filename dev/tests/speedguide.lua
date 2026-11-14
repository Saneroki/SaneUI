-- Runs Speed Leveling's guide against the stand-in client (wowstub.lua): a guide written as text read into our shape
-- for one character (its head, who a step and a line are for, each kind of command, step marks, what cannot be read,
-- which games it is for), the import string of bought guides opened for the account (Unlock), the guide run (moving
-- on past done steps, the steps at hand, skipping, going back and being held there, what the game tells as it
-- happens, places, tests that pass a step by, the next guide), what the game knows done by itself (at a guide picked
-- partway, past steps it cannot judge, after a click back, your place kept), steps paused and taken up again, skipped,
-- and what waits on them on hold (down a quest chain by Core's requires), the guides kept (packed, chosen), the
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
function methods:SetTexture(texture) self._texture = texture return true end -- found
function methods:EnableMouse(on) self._mouse = on end
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

-- Core's set Quests as the module reads it, with what a quest needs done first (requires) and whole records (records)
-- where the test says; the rest is Core's own.
local requires, records = {}, {}
local realSet = Core.Data.Set
Core.Data.Set = function(name)
    local handle = realSet(name)
    if name ~= "Quests" then return handle end
    local proxy = setmetatable({}, { __index = function(_, key)
        local value = handle[key]
        if type(value) ~= "function" then return value end
        return function(_, ...) return value(handle, ...) end
    end })
    function proxy:Get(key, field)
        if field == "requires" then return requires[key] end
        if records[key] then return field and records[key][field] or not field and records[key] or nil end
        return handle:Get(key, field)
    end
    return proxy
end
local ns = W.LoadAddon(root, "SpeedLeveling", "SaneUI_SpeedLeveling")
Core.Data.Set = realSet
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
    -- Dungeon quests the text does not mark (quest 7 is one): out of a normal guide, a step with nothing left of its
    -- own with them, its name too; a step that keeps a quest of its own stays without the line.
    local function Unmarked(group)
        local text = table.concat({ "#group " .. group, "step", "    #label walk", Line("place", "1411/0,100,100,10"),
            Line("goal", "7,1"), "step", Line("take", "2"), Line("take", "7"), "step", "    #label words",
            Line("friend", "Someone", "Talk to Someone"), "step", Line("handin", "7") }, "\n")
        local read = Format.NoDungeonQuests(Format.Read(text, orc), function(quest) return quest == 7 end)
        local shape = {}
        for _, step in ipairs(read.steps) do
            local quests = {}
            for _, line in ipairs(step.lines) do quests[#quests + 1] = line.quest or line.what end
            shape[#shape + 1] = table.concat(quests, "+")
        end
        return table.concat(shape, " "), read
    end
    local plain, read = Unmarked("A Guide")
    check(plain == "2 say" and read.labels.walk == nil and read.labels.words == 2,
        "a normal guide: a dungeon quest out, also unmarked, and a step with nothing else of its own")
    check(Unmarked("A Dungeon Guide") == "arrive+7 2+7 say 7", "a dungeon guide keeps its dungeon quests")
    check(Format.NoDungeonQuests(Format.Read("step\n" .. Line("take", "7"), orc), nil).steps[1] ~= nil,
        "no test: the guide as it was read")
end
local slip = Format.Read("step\n" .. Line("place", "1411/1,-623.92.00,-4214.45") .. "\nstep\n" .. Line("place", "1411,43.73,39.43s"), orc)
check(slip.steps[1].lines[1].x == -623.92 and slip.steps[2].lines[1].y == 39.43,
    "a coordinate with a slip of the pen after it: the number it starts with")
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
check(Guide.Empty() == "none", "the view knows no guide is kept")
Steps.Update()
local view = rawget(_G, "SaneUISpeedLevelingSteps")
check(view and view._shown, "the view stays, with its head, while no guide is followed")
local function Shown(text)
    for _, widget in ipairs(W.frames) do
        if widget._text == text and widget._shown then return widget end
    end
end
-- No guide (Saneroki, 2026-11-09): "Select a guide", its button beside it, under them what the mouse does, on a shade.
local hintText = Shown(ns.TEXT.selectGuide)
local emptyCard = hintText and hintText._parent
local choose = emptyCard and emptyCard.choose
check(hintText ~= nil and choose and choose._shown and choose.label._text == ns.TEXT.guides,
    "its card says to select a guide, a button beside it")
check(Shown(ns.TEXT.howTo) and Shown(ns.TEXT.howTo)._parent == emptyCard, "and under it what the mouse does")
check(choose._points[1][4] > hintText._points[1][4], "the button after the words, on their line")
check(emptyCard._height > 0 and emptyCard.shade ~= nil, "on a shade, as high as its words")
choose._scripts.OnEnter(choose)
check(choose.plate.look.alpha == ns.Steps.BUTTON_LIT, "the mouse on the button: its band more solid")
choose._scripts.OnLeave(choose)
check(choose.plate.look.alpha == ns.Steps.BAND, "and back")
-- None kept: the button opens the window of the guides kept; built, with its import line and its box.
choose._scripts.OnClick(choose, "LeftButton")
local lineTitle = Shown(ns.TEXT.stringTitle)
check(lineTitle ~= nil and lineTitle._parent:IsVisible() ~= false, "none kept: the button opens the guides, with the import line")
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
    -- One kept for this character, none followed: the button opens the menu of the guides for it.
    check(Guide.Empty() == "unchosen" and choose._shown, "one for you, none followed: the button")
    local menus = #W.menus
    choose._scripts.OnClick(choose, "LeftButton")
    check(#W.menus == menus + 1 and W.menus[#W.menus][1].title == ns.TEXT.guides, "it opens the menu of the guides")
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

-- Only the steps in sight: the head and the icons come with the mouse and stay a moment. The half of the screen that
-- holds its place says which way the view goes: from its top down, they under the steps; from its bottom up, they over.
;(function()
    local spot, head = rawget(_G, "SaneUISpeedLevelingGuide"), ns.Steps.closer._parent
    local row = rawget(_G, "SaneUISpeedLevelingIcons")
    local function Tick(seconds) spot._scripts.OnUpdate(spot, seconds) end
    local function Hidden() return not head._shown and row._alpha == 0 and icon1._mouse == false end
    local function Seen() return head._shown and row._alpha == 1 and icon1._mouse == true end
    view._mouseOver = false
    Tick(1)
    Steps.Update()
    check(view._shown and Hidden(), "the steps alone: no head, no icons, nothing in the mouse's way")
    view._mouseOver = true
    Tick(0.1)
    check(Seen(), "the mouse on the steps: the head and the icons come")
    view._mouseOver = false
    head._mouseOver = true
    Tick(1)
    check(Seen(), "they stay with the mouse on the head")
    head._mouseOver = false
    Tick(ns.Steps.PEEK / 2)
    check(Seen(), "and a moment after it left")
    Tick(ns.Steps.PEEK)
    check(Hidden(), "then they go")
    head._mouseOver = true
    Tick(1)
    check(Hidden(), "the mouse where the head is not in sight: nothing comes")
    head._mouseOver = false
    row._mouseOver = true
    Tick(1)
    check(Hidden(), "nor where the icons are: out of a fight they are not there")

    -- In a fight the game holds the icons: they stay open to the mouse and come where it is, out of sight or not.
    row._mouseOver = false
    W.Combat(true)
    check(not head._shown and row._alpha == 0 and icon1._mouse == true, "a fight begins: the icons open to the mouse, unseen")
    row._mouseOver = true
    Tick(1)
    check(head._shown and row._alpha == 1, "the mouse on them in the fight: they come")
    row._mouseOver = false
    Tick(1)
    check(not head._shown and row._alpha == 0 and icon1._mouse == true, "and go, still open to the mouse")
    W.Combat(false)
    check(Hidden(), "the fight over: out of the mouse's way again")

    -- Which way: the place's edges stay, the view and what shows with it go from there.
    local screen = UIParent._height
    local high = 768
    UIParent._height = high
    local function Standing(top)
        spot._top, spot._bottom = top, top - ns.Steps.PLACE
        Steps.Update()
    end
    Standing(high - 40)
    local point = view._points[1]
    check(point[1] == "TOPLEFT" and point[2] == spot and point[3] == "TOPLEFT", "the upper half: the view hangs from its place's top")
    point = head._points[1]
    check(point[1] == "TOPLEFT" and point[2] == view and point[3] == "BOTTOMLEFT" and point[5] == -ns.Steps.GAP, "the head under the steps")
    point = row._points[1]
    check(point[1] == "TOPLEFT" and point[5] == spot._top - view:GetHeight() - ns.Steps.GAP - head:GetHeight() - ns.Icons.BESIDE,
        "the icons under the head")
    Standing(ns.Steps.PLACE + 40)
    point = view._points[1]
    check(point[1] == "BOTTOMLEFT" and point[2] == spot and point[3] == "BOTTOMLEFT", "the lower half: it stands on its place's bottom")
    point = head._points[1]
    check(point[1] == "BOTTOMLEFT" and point[2] == view and point[3] == "TOPLEFT" and point[5] == ns.Steps.GAP, "the head over the steps")
    point = row._points[1]
    check(point[1] == "BOTTOMLEFT" and point[5] == spot._bottom + view:GetHeight() + ns.Steps.GAP + head:GetHeight() + ns.Icons.BESIDE,
        "the icons over the head")
    W.Combat(true)
    local before = row._points[1]
    Standing(high - 40)
    check(row._points[1] == before and Core.Owed("speedleveling: icons"), "moved in a fight the icons stay, owed to its end")
    W.Combat(false)
    check(row._points[1][1] == "TOPLEFT", "and follow once it is over")
    spot._top, spot._bottom = nil, nil
    UIParent._height = screen
    Steps.Update()
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

-- A middle click anywhere on the view (Saneroki, 2026-11-09): its settings: Your guide on, paused or off, the guide's
-- switches, each with its words and its tip from the options page, and All settings... for that page.
;(function()
    Steps.Update()
    local card = Shown(ns.TEXT.step:format(3))._parent
    local menus, at = #W.menus, Run.At()
    card._scripts.OnClick(card, "MiddleButton")
    check(#W.menus == menus + 1 and Run.At() == at and not Run.Paused(at) and card._shown,
        "a middle click on a step: the settings, the step neither paused nor skipped")
    local menu = W.menus[#W.menus]
    check(menu[1].title == ns.TEXT.settings and menu[2].title == ns.TEXT.follow, "titled, Your guide first")
    check(menu[3].text == ns.TEXT.followOn and menu[4].text == ns.TEXT.followPaused and menu[5].text == ns.TEXT.followOff
        and menu[3].checked() and not menu[4].checked(), "on, paused or off; on now")
    for index, key in ipairs(ns.Steps.SETTINGS) do
        local item, option = menu[5 + index], Core.Described(ns.name, key)
        check(item and item.checkbox and item.text == option.text and item.checked() == (ns.options[key] == true),
            "the switch " .. key .. " to tick, as on the options page")
    end
    check(menu[6].text == ns.TEXT.gather and menu[7].text == ns.TEXT.party, "the professions and the party first")
    local arrow = menu[5 + 4]
    local was = ns.options.showArrow
    arrow.fn()
    check(ns.options.showArrow == not was and arrow.checked() == not was, "a tick switches it")
    arrow.fn()
    check(ns.options.showArrow == was, "and back")
    menu[4].fn()
    W.Wait(0.1)
    check(ns.options.follow == "paused" and menu[4].checked(), "paused from the menu")
    menu[3].fn()
    W.Wait(0.1)
    check(ns.options.follow == "on" and Run.At() == at, "on again, where it was")
    W.options.opened = nil
    menu[#menu].fn()
    check(menu[#menu].text == ns.TEXT.allSettings and W.options.opened == Core.pages[ns.name]:GetID(),
        "All settings... opens Speed Leveling's page")
    -- The head too; a right click there is still the guides.
    local head = ns.Steps.closer._parent
    head._scripts.OnClick(head, "MiddleButton")
    check(W.menus[#W.menus][1].title == ns.TEXT.settings, "a middle click on the head: the settings")
    head._scripts.OnClick(head, "RightButton")
    check(W.menus[#W.menus][1].title == ns.TEXT.guides, "a right click there: the guides")
    check(not ns.off and #Core.log == 0, "no error: " .. tostring(Core.log[1] and Core.log[1].text))
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
    -- Every corner of a shade as round, no border.
    local function Round(shade, height)
        for corner = 1, 4 do
            if shade.radii[corner] ~= ns.Steps.ROUND then return false end
        end
        return #shade.trims == 0 and shade.width == ns.Steps.WIDTH and shade.height == height
    end
    check(Round(card.shade, card:GetHeight()), "a step's shade: its corners round, no border, as high as its step")
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
    local shade
    for _, widget in ipairs(W.frames) do
        if widget.plate and widget._parent == view then shade = widget end
    end
    check(shade and shade._shown and Round(shade.plate, shade:GetHeight()), "the list's shade alike")
    check(ns.Steps.LIST_PAD >= ns.Steps.ROUND, "a gold band at the list's top or bottom stays clear of the round corners")
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
    row._scripts.OnClick(row, "MiddleButton")
    check(row._shown and not went and W.menus[#W.menus][1].title == ns.TEXT.settings, "a middle click: the settings")
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
-- The arrow: straight at the guide's place, never along a route (Saneroki, 2026-11-07), the yards as the crow flies; at
-- the place where the toast stands, and away while that shows.
;(function()
    local Arrow, aimed, told = ns.Arrow, nil, { way = 2.5, yards = 340, ride = "flight", to = "Crossroads" }
    Core.Set(ns.name, "showArrow", false)
    Core.Ways.Serve({ Aim = function(map, x, y) aimed = map and { map, x, y } or false end, Ahead = function() return told end })
    local facing, way = rawget(_G, "GetPlayerFacing"), Run.Way
    local yards = 200
    GetPlayerFacing, Run.Way = function() return 0.5 end, function() return yards, 1.5 end
    Core.Set(ns.name, "showArrow", true)
    local frame = rawget(_G, "SaneUISpeedLevelingArrow")
    check(frame and frame._shown and aimed == nil, "the arrow shows and asks no way of Navigation")
    W.menus = {}
    frame._scripts.OnMouseUp(frame, "RightButton")
    check(W.menus[1] and W.menus[1][1].title == ns.TEXT.arrowView and W.menus[1][2].text == Core.Element.TEXT.unlock,
        "a right click on it: its Unlock to move and ticks (Core.Element)")
    local point, _, relative, _, y = frame:GetPoint(1)
    check(point == "TOP" and relative == "TOP" and y == -Core.TOAST_TOP,
        "at first where the travel overlay stands, the toast of a new level beside it")
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
    check(ring._shown and math.abs(ring._rotation - 1) < 1e-6 and far:GetText():find(Core.Distance(200), 1, true)
        and said and said ~= "" and not said:find("Crossroads", 1, true)
        and not picture:GetTexture():find("UITaxiCursor2x", 1, true),
        "a route known with a flight next: still straight at the place, its yards, the step's words and picture")
    GetPlayerFacing = function() return W.Secret() end -- the facing hidden from addons: it goes through Core.Plain
    Arrow.Update(true)
    check(not ring._shown and far:GetText() == "" and words:GetText() == said,
        "a facing the game hides: no turn and no yards, the words alone, nothing computed with it")
    GetPlayerFacing = function() return 0.5 end
    yards = 1
    Arrow.Update(true)
    check(not ring._shown and not picture._shown and far:GetText() == "" and words:GetText() == said,
        "within the place's reach: only the words")
    yards = 200
    Arrow.Update(true)
    local toast = CreateFrame("Frame")
    toast:Hide()
    Core.TellsAtTop(toast)
    check(not Core.TopTaken() and frame._shown, "nothing at the toast's place: the arrow there")
    toast:Show()
    check(Core.TopTaken() and not frame._shown, "the travel overlay comes: the arrow makes way")
    Arrow.Update(true)
    check(not frame._shown, "and stays away as the guide goes on")
    toast:Hide()
    check(not Core.TopTaken() and frame._shown and ring._shown, "gone: the arrow back")
    Core.Set(ns.name, "showArrow", false)
    check(not frame._shown and aimed == nil, "the arrow off: hidden, still no way asked")
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

-- Going to a step holds you there; a skip (a right click) moves on; back one goes back.
Run.Go(3)
check(Run.At() == 3, "go to a step and be held there")
local was = Run.At()
Guide.Skip(3)
check(Run.At() > was, "a skip of the step at hand moves on")
local after = Run.At()
Guide.Back()
check(Run.At() < after, "back one goes back")

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
-- A bare name after a guide stays in its group: one there for somebody else sends it on to the next name, never to
-- another group's guide of that name (a normal guide's next never leads into the dungeon guide).
;(function()
    local guides = Core.Store(ns.name).guides
    guides["Our Group\\Fork << Alliance"] = { name = "Fork", group = "Our Group", only = "Alliance",
                                              text = "<< Alliance\nstep\n" .. Line("take", "1") }
    guides["Our Dungeons\\Fork"] = { name = "Fork", group = "Our Dungeons", text = "step\n" .. Line("take", "1") }
    guides["Our Group\\Fork Too"] = { name = "Fork Too", group = "Our Group", text = "step\n" .. Line("take", "1") }
    local after = Guide.After({ after = { { name = "Fork" }, { name = "Fork Too" } }, group = "Our Group" })
    check(after and after.key == "Our Group\\Fork Too", "the next guide stays in its group: " .. tostring(after and after.key))
    local named = Guide.After({ after = { { name = "Our Dungeons\\Fork" } }, group = "Our Group" })
    check(named and named.key == "Our Dungeons\\Fork", "another group's guide by its group's name")
    local away = Guide.After({ after = { { name = "Fork" } }, group = "Elsewhere" })
    check(away and away.key == "Our Dungeons\\Fork", "a name not in its group: the one for this character elsewhere")
    guides["Our Group\\Fork << Alliance"], guides["Our Dungeons\\Fork"], guides["Our Group\\Fork Too"] = nil, nil, nil
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

    -- A quest line the format marks to tick by hand: its quest handed in, it lies behind you, so a place worked out
    -- again (a guide picked partway, a place not saved) goes past it; while its quest is open it waits for your click.
    quests.done[620], quests.done[621] = true, true
    Follow("Made Ticks", {
        { take(620) },                                      -- 1  handed in
        { Line("manualOnly", ""), Line("goal", "621,1") },  -- 2  to tick by hand, its quest handed in
        { Line("manualOnly", ""), Line("goal", "622,1") },  -- 3  to tick by hand, its quest still open
        { hand(620) },                                      -- 4
        { hand(621) },                                      -- 5
    })
    check(Run.At() == 3, "a line to tick by hand: passed once its quest is handed in, an open one waits: " .. Run.At())
    quests.done[620], quests.done[621] = nil, nil

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
--  Paused, skipped, and what waits on them on hold (Saneroki, 2026-11-04)
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
    -- A step's card in the view, drawn anew; a click on it.
    local function Card(number)
        Steps.Update()
        for _, widget in ipairs(W.frames) do
            if widget.number == number and widget.label and widget._shown then return widget end
        end
    end
    local function Click(number, button)
        local card = Card(number)
        check(card ~= nil, "a card for step " .. number)
        card._scripts.OnClick(card, button or "LeftButton")
    end
    local function Has(list, value)
        for _, each in ipairs(list or {}) do if each == value then return true end end
        return false
    end
    local take, hand = function(q) return Line("take", tostring(q)) end, function(q) return Line("handin", tostring(q)) end
    local function Near(x) return Line("place", "1411," .. x .. "," .. x) end

    -- A click pauses the step: still shown, but on past it as past a done one; the arrow, the key and the quest givers
    -- by the next.
    local key = Follow("Made Pause", {
        { Near(20), take(1501), Line("friend", "Grull"), Line("use", "6948") }, -- 1
        { Near(30), take(1502), Line("friend", "Brak") },   -- 2
        { Near(40), take(1503) },                           -- 3
        { take(1504) }, { take(1505) }, { take(1506) }, { take(1507) }, { take(1508) }, -- 4 to 8
    })
    check(Run.At() == 1 and Run.Target().x == 20, "at the first step, the arrow to it")
    Click(1)
    check(Run.At() == 2 and Run.Place() == 2 and not Has(Run.Hand(), 1), "a click pauses it: on past it, not at hand")
    local picture = Guide.Picture()
    check(picture.hand[1].number == 1 and picture.hand[1].paused and picture.hand[2].number == 2 and not picture.hand[2].paused,
        "still shown, in the guide's order, marked paused")
    check(Run.Target().x == 30, "the arrow and the map pin go by the next step")
    local foes, friends = Guide.Targets()
    check(Has(friends, "Brak") and not Has(friends, "Grull"), "and so does the key")
    check(not Guide.Quests().take[1501] and Guide.Quests().take[1502], "and the quest givers")
    check(not Has(Guide.Uses(), 6948), "and the items to use, the icons'")
    check(not Run.Ticked(1) and Guide.Line(1).paused and not Guide.Line(1).done, "not done; marked so in the list too")
    local card = Card(1)
    check(card and card.label._text == ns.TEXT.step:format(1) .. " " .. Steps.PAUSE and card._alpha == Steps.RESTING,
        "its card faint, the game's pause button by its number")
    check(Card(2)._alpha == 1, "the next step's card as ever")
    check(Core.Character(ns.name).paused[key][1], "kept for the character")
    Run.Use(Run.Guide())
    check(Run.At() == 2 and Run.Paused(1) and Guide.Picture().hand[1].paused, "and over a /reload")

    -- A click on it again: taken up and gone to, your place kept; done, back to your place.
    Click(1)
    check(Run.At() == 1 and Run.Place() == 2 and not Run.Paused(1) and Run.Target().x == 20, "a click again: taken up, gone to")
    foes, friends = Guide.Targets()
    check(Has(friends, "Grull") and Guide.Quests().take[1501] and Has(Guide.Uses(), 6948),
        "the key, the quest givers and the icons follow it")
    check(Card(1)._alpha == 1 and Card(1).label._text == ns.TEXT.step:format(1), "its card as any step's")
    quests.on[1501] = true
    check(Run.Check() and Run.At() == 2 and Run.Place() == 2, "done: back to your place")

    -- Paused, then done as the game knows it: it goes, as any done step.
    Click(2)
    check(Run.At() == 3 and Run.Paused(2), "paused")
    quests.on[1502] = true
    Run.Check()
    check(not Run.Paused(2) and not Has(Run.Shown(), 2) and Run.Ticked(2), "done meanwhile: gone from sight, ticked")

    -- A right click skips the step at hand.
    Click(3, "RightButton")
    check(Run.At() == 4 and Core.Character(ns.name).skipped[key][3] and not Has(Run.Shown(), 3), "a right click skips it")

    -- No flood: of many paused, only those nearest your place are in sight; all are marked in the list.
    for number = 4, 7 do Click(number) end
    local shown = Run.Shown()
    check(Run.At() == 8 and #shown == Run.PAUSED + 1 and shown[1] == 5 and shown[#shown] == 8 and not Has(shown, 4),
        "four paused: the three nearest your place in sight, with the step at hand")
    check(Guide.Line(4).paused, "the one out of sight still marked in the list")
    -- The list: a paused step's number is the pause button, it is faint; a double click goes to it, taken up.
    view._mouseOver = true
    view._scripts.OnMouseWheel(view, -1)
    local row
    for _, widget in ipairs(W.frames) do
        if widget.step == 4 and widget._shown then row = widget end
    end
    check(row and row.number._text == Steps.PAUSE and row._alpha == Steps.RESTING and not row.band._shown,
        "in the list: the pause button for its number, faint, no gold band")
    row._scripts.OnDoubleClick(row, "LeftButton")
    check(Run.At() == 4 and Run.Place() == 8 and not Run.Paused(4), "a double click there goes to it, taken up")
    view._mouseOver = false
    Steps.Update()

    -- What waits on a step paused or skipped is on hold: its quest and, down the chain, a quest that needs it done first
    -- (Core's requires: one it needs, or each of those of which it needs one; not one it closes). Passed by, not done,
    -- not at hand: the next step free of it is the one at hand. A step with a line free of it stays, asking that alone.
    local function Chain(name, base)
        requires[base + 2] = { { kind = "done", quest = base + 1 } }
        requires[base + 3] = { { kind = "one", quest = base + 1 }, { kind = "one", quest = base + 99 } }
        requires[base + 4] = { { kind = "closed", quest = base + 1 } }
        local key = Follow(name, {
            { Near(20), take(base + 1), Line("friend", "Giver") },        -- 1  paused or skipped
            { Near(25), Line("goal", (base + 1) .. ",1"), Line("foe", "Wolf") }, -- 2  works on its quest: on hold
            { Near(30), take(base + 20), Line("friend", "Free") },        -- 3  free of it
            { hand(base + 1) },                                           -- 4  on hold
            { take(base + 2) },                                           -- 5  needs it done first: on hold
            { Line("goal", (base + 2) .. ",1") },                         -- 6  down the chain: on hold
            { hand(base + 20), Line("goal", (base + 1) .. ",1") },        -- 7  a line free of it: stays
            { take(base + 3), take(base + 4) },                           -- 8  one of two; one it closes: free
        })
        check(Run.At() == 1 and Run.Target().x == 20, "at the step that takes the chain's first quest")
        return key
    end
    local base = 1600
    key = Chain("Made Hold", base)
    Click(1)
    check(Run.At() == 3, "paused: on past it and past what works on its quest, to the next step free of it: " .. Run.At())
    check(Run.OnHold(2) and Run.OnHold(4) and Run.OnHold(5) and Run.OnHold(6), "what waits on it is on hold, down the chain")
    check(not Run.OnHold(1) and not Run.OnHold(3) and not Run.OnHold(7) and not Run.OnHold(8), "the rest is not")
    check(Run.Target().x == 30 and not Has(Run.Shown(), 2), "the arrow to the free step; a step on hold is not in sight")
    foes, friends = Guide.Targets()
    check(Has(friends, "Free") and not Has(foes, "Wolf") and not Has(friends, "Giver"), "the key goes by it")
    check(not Run.Ticked(2) and Guide.Line(2).onHold and not Guide.Line(2).done, "on hold: not done, marked in the list")
    quests.on[base + 20] = true
    check(Run.Check() and Run.At() == 7, "the free step done: on past those on hold, to one with a line free: " .. Run.At())
    local seven = Guide.Picture().hand
    seven = seven[#seven]
    check(seven.number == 7 and #seven.lines == 1 and Run.Lines(7)[2].onHold, "it asks only the free line")
    check(Guide.Quests().handin[base + 20] and not Guide.Quests().handin[base + 1], "the quest givers alike")
    Run.Use(Run.Guide())
    check(Run.At() == 7 and Run.OnHold(2) and Run.Paused(1), "all kept over a /reload")

    -- Taken up again: gone to; once its quest is taken, the guide goes back to what waited on it, one by one, your place
    -- kept, then back to your place.
    Click(1)
    check(Run.At() == 1 and Run.Place() == 7 and not Run.OnHold(2) and not Run.OnHold(5), "taken up: nothing waits any more")
    quests.on[base + 1] = true
    check(Run.Check() and Run.At() == 2 and Run.Place() == 7, "its quest taken: back to what works on it, your place kept")
    foes = Guide.Targets()
    check(Run.Target().x == 25 and Has(foes, "Wolf"), "the arrow and the key follow it")
    quests.objectives[base + 1] = { { finished = true, numFulfilled = 1, numRequired = 1 } }
    check(Run.Check() and Run.At() == 4, "done: on to the next that waited")
    quests.on[base + 1], quests.done[base + 1] = nil, true
    check(Run.Check() and Run.At() == 5, "and the next, down the chain")
    quests.on[base + 2] = true
    quests.objectives[base + 2] = { { finished = true, numFulfilled = 1, numRequired = 1 } }
    check(Run.Check() and Run.At() == 7 and Run.Place() == 7 and #Guide.Picture().hand[1].lines == 2,
        "all done: back at your place, the step asking both its lines again: " .. Run.At())

    -- The quest taken anyway while its step is paused: what waited on it is free, the guide goes back to it.
    base = 1700
    key = Chain("Made Anyway", base)
    Click(1)
    check(Run.At() == 3 and Run.OnHold(2), "paused, what waits on it on hold")
    quests.on[base + 1] = true
    check(Run.Check() and Run.At() == 2 and Run.Place() == 3 and not Run.Paused(1) and not Has(Run.Shown(), 1),
        "its quest taken anyway: the paused step done and gone, back to what waited")

    -- A skip puts what waits on it on hold just the same; going to it again frees it.
    base = 1800
    key = Chain("Made Skip", base)
    Click(1, "RightButton")
    check(Run.At() == 3 and Run.OnHold(2) and Run.OnHold(5) and Run.OnHold(6) and not Run.OnHold(8),
        "skipped: on hold alike, down the chain: " .. Run.At())
    check(not Has(Run.Shown(), 1) and Guide.Quests().take[base + 2] == nil, "nothing of it in sight or for the quest givers")
    Run.Go(1)
    check(Run.At() == 1 and Run.Place() == 3 and not Run.OnHold(2), "gone to again: not skipped, nothing waits")
    for number = base + 2, base + 4 do requires[number] = nil end
    for _, number in ipairs({ 1600, 1700 }) do
        for each = number + 2, number + 4 do requires[each] = nil end
    end
end)()

-------------------------------------------------------------------------------
--  The party on one guide (Saneroki, 2026-11-05): whoever is through with a step first waits for the others
-------------------------------------------------------------------------------
;(function()
    -- In a party with Buddy Stub, a mage: the guide's mage step is his alone.
    local name, groupSize, sent = UnitName, GetNumGroupMembers, {}
    UnitName = function(unit) if unit == "party1" then return "Buddy", "Stub" end return name(unit) end
    GetNumGroupMembers = function() return 2 end
    local send = Core.Wire.Send
    Core.Wire.Send = function(kind, fields, channel) sent[#sent + 1] = { kind = kind, fields = fields, channel = channel } end
    local function Told() return sent[#sent] and sent[#sent].kind == "S" and sent[#sent] or nil end
    local text = { "#forever", "<< Horde", Mark("name", "Made Party"), Mark("group", "Made Up"),
                   "step", "    " .. Line("take", "2001"), "step << Mage", "    " .. Line("take", "2002"),
                   "step", "    " .. Line("take", "2003"), "step", "    " .. Line("take", "2004") }
    Guide.AddAll({ table.concat(text, "\n") })
    local key = "Made Up\\Made Party << Horde"
    Guide.Choose(key)
    check(Guide.Chosen() == key and ns.options.party == true, "follows the party's guide; Together with the party on in Speedleveling")
    local steps = Run.Guide().steps
    check(#steps == 3 and steps[1].row == 5 and steps[2].row == 9 and steps[3].row == 11,
        "each step knows the line of the text it begins at, the mage's step left out: "
        .. tostring(steps[2] and steps[2].row))
    local function Says(row, letters)
        Core.Wire.Take(Core.Wire.Text("S", { key, row, letters or "", n = 3 }), "PARTY", "Buddy Stub")
        W.Wait(1)
    end
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(1)
    local told = Told()
    check(told and told.channel == "PARTY" and told.fields[1] == key and told.fields[2] == 5 and told.fields[3] == "a",
        "joined: where you are told to the party, asking theirs")

    -- Buddy at the first step too; you take its quest first: you wait on it.
    Says(5)
    quests.on[2001] = true
    W.Fire("QUEST_ACCEPTED", 2001)
    W.Wait(1)
    local waiting = Run.Waiting()
    check(Run.At() == 1 and waiting and waiting[1] == "Buddy Stub", "through with it first: you wait on it for Buddy: "
        .. Run.At())
    local lines = Guide.Picture().hand[1].lines
    check(lines[#lines].text == ns.TEXT.waitFor:format("Buddy Stub") and not lines[#lines].done,
        "the step says who you wait for")
    told = Told()
    check(told.fields[2] == 5 and told.fields[3] == "w", "and the party is told you wait there")
    steps[1].friends, steps[1].foes = { "Kaltunk" }, { "Mottled Boar" }
    local foes, friends = Guide.Targets()
    check(foes[1] == "Mottled Boar" and friends[1] == nil, "while you wait its creatures are wanted, its NPCs no more")
    steps[1].friends, steps[1].foes = nil, nil

    -- Buddy through with it, on his mage step: you go on to the next step of yours, and wait at it once done.
    Says(7)
    check(Run.At() == 2 and not Run.Waiting(), "Buddy on: you too, past the step he has and you have not: " .. Run.At())
    quests.on[2003] = true
    W.Fire("QUEST_ACCEPTED", 2003)
    W.Wait(1)
    check(Run.At() == 2 and Run.Waiting(), "through with the next step while he is on his own: you wait for him there")
    Says(9)
    check(Run.At() == 2 and Run.Waiting(), "he is at your step, not through with it: you still wait")
    Says(9, "w")
    check(Run.At() == 3 and not Run.Waiting(), "he waits there for you: you are both through with it, on together")
    told = Told()
    check(told.fields[2] == 11 and told.fields[3] == "", "told where you are now")

    -- Asked, you answer; a step you skip is not waited on; out of the group nobody holds you.
    local count = #sent
    Says(11, "a")
    check(#sent == count + 1 and Told().fields[2] == 11, "asked by one who came back: answered")
    Says(9)
    quests.on[2004] = true
    W.Fire("QUEST_ACCEPTED", 2004)
    W.Wait(1)
    check(Run.Through() == false and Run.At() == 3 and Run.Waiting(), "behind you he holds you at the last step")
    Core.Set(ns.name, "party", false)
    check(ns.Party.Holding(key, 11) == nil, "Together with the party off: nobody holds you")
    W.Wait(1)
    check(Run.Through() and Told() and Told().fields[1] == "", "on through the guide, the party told you follow along no more")
    Core.Set(ns.name, "party", true)
    check((ns.Party.Holding(key, 11) or {})[1] == "Buddy Stub", "on again: he would hold you")
    GetNumGroupMembers = function() return 0 end
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(1)
    check(ns.Party.Holding(key, 11) == nil, "out of the group: nobody holds you")

    UnitName, GetNumGroupMembers, Core.Wire.Send = name, groupSize, send
    for quest = 2001, 2004 do quests.on[quest] = nil end
end)()

-------------------------------------------------------------------------------
--  One guide for the party, read together (Saneroki, 2026-11-05: "Make one merged guide")
-------------------------------------------------------------------------------
;(function()
    -- An orc warrior and an orc mage. 3101 for all; 3102 a mage's class quest; 3103 a quest the guide gives mages only,
    -- open to anyone; a warrior's trainer; a step for both with a mage's line of an open quest (3104) and one of a
    -- mage's class quest (3105); a step for all but mages (3106).
    local mage = { side = "Horde", race = "Orc", class = "MAGE", level = 5, game = "forever" }
    local text = table.concat({ "#forever", "<< Horde", Mark("name", "Made Together"), Mark("group", "Made Up"),
        "step", "    " .. Line("take", "3101"),
        "step << Mage", "    " .. Line("take", "3102"),
        "step << Mage", "    " .. Line("take", "3103"),
        "step << Warrior", "    " .. Line("trainer", "", "Train your class spells"),
        "step", "    " .. Line("take", "3104", nil, "Mage"), "    " .. Line("take", "3105", nil, "Mage"),
        "    " .. Line("handin", "3101"),
        "step << !Mage", "    " .. Line("take", "3106"),
        "step", "    " .. Line("handin", "3104") }, "\n")
    for _, quest in ipairs({ 3101, 3103, 3104, 3106 }) do records[quest] = {} end
    records[3102], records[3105] = { classes = { 8 } }, { classes = { 8 } }
    local function Open(class)
        return function(quest)
            local record = records[quest]
            return record ~= nil and (not record.classes or record.classes[1] == class)
        end
    end
    local function Rows(guide)
        local rows = {}
        for _, step in ipairs(guide.steps) do rows[#rows + 1] = step.row end
        return table.concat(rows, ",")
    end
    local warrior = { side = "Horde", race = "Orc", class = "WARRIOR", level = 5, game = "forever", with = { mage } }
    local withWarrior = { side = "Horde", race = "Orc", class = "MAGE", level = 5, game = "forever", with = { orc } }
    local mine = Format.Together(Format.Read(text, warrior), Open(1))
    local theirs = Format.Together(Format.Read(text, withWarrior), Open(8))
    check(Rows(Format.Read(text, orc)) == "5,11,13,17,19" and Rows(Format.Read(text, mage)) == "5,7,9,13,19",
        "alone, each keeps steps of its own: " .. Rows(Format.Read(text, orc)))
    check(Rows(mine) == "5,7,9,11,13,17,19" and Rows(theirs) == Rows(mine),
        "read together, the same steps for both, every step of either class: " .. Rows(mine))
    check(mine.steps[2].theirs and mine.steps[2].theirs[1] == "MAGE" and not mine.steps[3].theirs
        and mine.steps[3].lines[1].route, "the mage's class quest stays his; the quest the guide gives mages is yours too")
    check(theirs.steps[4].theirs and theirs.steps[4].theirs[1] == "WARRIOR" and not theirs.steps[6].theirs
        and theirs.steps[6].lines[1].route, "and the other way round: the warrior's trainer his, all but mages' the mage's too")
    check(mine.steps[4].alone and not mine.steps[1].alone and not mine.steps[3].alone and not Format.Read(text, orc).steps[1].alone,
        "your trainer yours alone, run beside his; a step you share, or one read alone, not")
    local quests5 = {}
    for _, line in ipairs(mine.steps[5].lines) do quests5[#quests5 + 1] = line.quest .. (line.route and "*" or "") end
    check(table.concat(quests5, ",") == "3104*,3101", "in a step for both, of the mage's lines his open quest only: "
        .. table.concat(quests5, ","))

    -- In the game: Buddy Stub, an orc mage, in your party, on your guide.
    local name, groupSize, class, sent = UnitName, GetNumGroupMembers, UnitClass, {}
    UnitName = function(unit) if unit == "party1" then return "Buddy", "Stub" end return name(unit) end
    UnitClass = function(unit) if unit == "party1" then return "Mage", "MAGE", 8 end return class(unit) end
    GetNumGroupMembers = function() return 2 end
    LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", WARRIOR = "Warrior" }
    local send = Core.Wire.Send
    Core.Wire.Send = function(kind, fields, channel) sent[#sent + 1] = { kind = kind, fields = fields, channel = channel } end
    local function Told() return sent[#sent] and sent[#sent].kind == "S" and sent[#sent] or nil end
    Guide.AddAll({ text })
    local key = "Made Up\\Made Together << Horde"
    Guide.Choose(key)
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(1)
    check(Guide.Chosen() == key and #Run.Guide().steps == 5 and not Run.Guide().notes, "alone: the warrior's own steps")
    local function Says(row, letters)
        Core.Wire.Take(Core.Wire.Text("S", { key, row, letters or "", n = 3 }), "PARTY", "Buddy Stub")
        W.Wait(1)
    end
    Says(13)
    local notes = Core.Character(ns.name)
    check(type(notes.with) == "table" and notes.with[1] == "MAGE Orc" and not notes.with[2],
        "he tells where he is on your guide: his class and race kept for this character")
    check(#Run.Guide().steps == 7 and Run.Guide().notes == key .. " + MAGE Orc" and Run.At() == 1,
        "the guide read together with him, kept apart, your place where it was: " .. Run.At())
    local line = Guide.Line(2)
    check(Run.Theirs(2)[1] == "MAGE" and line.onHold and line.text:find("^Mage: ") ~= nil,
        "his class's step in your list: faint, his class before its words: " .. line.text)
    quests.on[3101] = true
    W.Fire("QUEST_ACCEPTED", 3101)
    W.Wait(1)
    check(Run.At() == 3 and not Run.Waiting(), "past his class's step, on to the quest the guide gives mages: yours too: "
        .. Run.At())
    -- He is on his class's own step before it: you wait before the step you share, nothing of it for the key yet.
    Run.Guide().steps[3].friends, Run.Guide().steps[3].foes = { "Kaltunk" }, { "Mottled Boar" }
    Says(7)
    local waits, before = Run.Waiting()
    local foes, friends = Guide.Targets()
    check(waits and waits[1] == "Buddy Stub" and before and not foes[1] and not friends[1],
        "he is busy with his class's step: you wait before the next step you share, its targets not yet wanted")
    Says(9)
    foes = Guide.Targets()
    check(not Run.Waiting() and foes[1] == "Mottled Boar", "he is at it too: you do it together")
    Run.Guide().steps[3].friends, Run.Guide().steps[3].foes = nil, nil
    Says(13)
    requires[3103] = { { kind = "done", quest = 3190 } }
    Run.Check()
    check(Run.At() == 4, "a quest of his way that needs one you never did asks nothing of you: " .. Run.At())
    requires[3103] = nil
    W.Fire("TRAINER_SHOW")
    W.Wait(1)
    check(Run.At() == 5 and #Run.Guide().steps[5].lines == 2, "your trainer, then the step for both, without his class quest")

    -- He is busy with his class's quests: you wait for him, told so, also while not through with your step.
    Says(13, "c")
    local waiting = Run.Waiting()
    check(waiting and waiting[1] == ns.TEXT.onChain:format("Buddy Stub") and not Told().fields[3]:find("w"),
        "he is on his class quests: you wait for him, the party not told you are through")
    quests.done[3101], quests.on[3101], quests.on[3104] = true, nil, true
    W.Fire("QUEST_TURNED_IN", 3101)
    W.Wait(1)
    check(Run.At() == 5 and Run.Waiting() and Told().fields[3]:find("w"), "through with it: you wait there for him")
    Says(17)
    check(Run.At() == 6 and not Run.Waiting(), "he is through and on: you too: " .. Run.At())
    local hand = ns.ClassQuests.Hand
    ns.ClassQuests.Hand = function() return { ns.ClassQuests.STEP } end
    check(select(4, Run.Spot()) == true, "a class quest of yours on top: the party is told so")
    ns.ClassQuests.Hand = hand

    -- The switch off: alone again, your place by its row; on: together again.
    Core.Set(ns.name, "party", false)
    W.Wait(1)
    check(not Run.Guide().notes and #Run.Guide().steps == 5 and Run.Guide().steps[Run.At()].row == 17,
        "Together with the party off: your own steps, at the same step of the text: " .. Run.At())
    Core.Set(ns.name, "party", true)
    W.Wait(1)
    check(Run.Guide().notes and #Run.Guide().steps == 7 and Run.Guide().steps[Run.At()].row == 17,
        "on again: together, at that step still: " .. Run.At())
    GetNumGroupMembers = function() return 0 end
    W.Fire("GROUP_ROSTER_UPDATE")
    W.Wait(1)
    check(Run.Guide().notes and notes.with[1] == "MAGE Orc", "out of the group: he is kept, the guide stays one for you both")

    notes.with = nil
    Guide.Reread()
    UnitName, UnitClass, GetNumGroupMembers, Core.Wire.Send = name, class, groupSize, send
    LOCALIZED_CLASS_NAMES_MALE = nil
    for quest = 3101, 3106 do quests.on[quest], quests.done[quest], records[quest] = nil, nil, nil end
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
