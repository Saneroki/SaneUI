-- Runs the Combat module's threat and damage meter (src/Combat/Meter/) against the stand-in client (wowstub.lua): where it
-- stands, that it has no title bar or background and takes no click, the list with you on top and how it is sorted, the
-- bars and their numbers, the ticks, the fights' pages, the saved fights, threat added up, and above all a fight with the
-- numbers hidden (W.Secret): nothing of them may be compared or computed, here an error. The look is judged in the
-- interface lab (the scene meter). At its end it runs again as Retail loads the module ("retail": W.Play).
-- Usage, from the project folder:  lua5.1 dev/tests/meter.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
local RETAIL = arg[1] == "retail"
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
local fight = require("combatclient").Install(W)
local units = fight.units

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:GetFrameLevel() return self._level or 1 end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
local function noop() end
function methods:CreateAnimationGroup()
    local group = setmetatable({}, { __index = function() return noop end })
    function group:CreateAnimation() return setmetatable({}, { __index = function() return noop end }) end
    return group
end
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    function controls:GetCurrentPage() return 1 end
end
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:GetCenter()
    return self._left and self._left + self._width / 2, self._bottom and self._bottom + self._height / 2
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetCursorPosition = function() return 0, 0 end
GetBindingKey, GetBindingText = function() end, function(key) return key end
EventUtil = { ContinueOnAddOnLoaded = function() end }
TalentMicroButton, SpellbookMicroButton = W.NewWidget("Button", "TalentMicroButton"), W.NewWidget("Button", "SpellbookMicroButton")
ClearOverrideBindings, SetOverrideBinding = function() end, function() end
C_SpellBook.IsSpellBookItemLooseFlyoutMember = function() return false end
C_SpecializationInfo = { GetCombatConfigIDForSpecGroup = function(group) return 100 + group end }
for _, bar in ipairs({ MainActionBar, StanceBar }) do
    bar.UpdateDividers, bar.Update, bar.UpdateState = function() end, function() end, function() end
end
for _, button in ipairs(MainActionBar.actionButtons) do button.Update, button.UpdateButtonArt = function() end, function() end end
RAID_CLASS_COLORS = { DRUID = { r = 1, g = 0.49, b = 0.04 } }
GetClassAtlas = function(class) return "classicon-" .. class end

-- The game's menu is a frame: it says whether it is open.
local menuMade = MenuUtil.CreateContextMenu
MenuUtil.CreateContextMenu = function(...)
    local menu = menuMade(...)
    function menu:IsShown() return false end
    return menu
end

-- Your group: you, a tank, a healer, and who is hunting.
local GUID = { player = "Player-1-1", raid1 = "Player-1-1", raid2 = "Player-1-2", raid3 = "Player-1-3", raid4 = "Player-1-4" }
units.player = { name = "Droopy", surname = "Fairwind", player = true, class = "DRUID", level = 60, health = 850, most = 1000,
                 power = 30, powerMost = 100 }
units.raid1 = units.player
units.raid2 = { name = "Brisa", surname = "Ashford", class = "WARRIOR", level = 59 }
units.raid3 = { name = "Caelum", surname = "Crowley", class = "PRIEST", level = 58 }
units.raid4 = { name = "Dorin", surname = "Dunmere", class = "HUNTER", level = 60 }
local raid = true
IsInRaid = function() return raid end
IsInGroup = function() return raid end
GetNumGroupMembers = function() return raid and 4 or 0 end
GetRaidRosterInfo = function() end
UnitGUID = function(unit) return GUID[unit] end
UnitIsUnit = function(a, b) return GUID[a] ~= nil and GUID[a] == GUID[b] end
GetAverageItemLevel = function() return 72, 71.4 end
local levels = { ["Player-1-2"] = 66, ["Player-1-3"] = 64 }
local inspected
CanInspect, CheckInteractDistance = function() return true end, function() return true end
NotifyInspect = function(unit) inspected = unit end
ClearInspectPlayer = function() end
C_PaperDollInfo = {}
C_PaperDollInfo.GetInspectItemLevel = function(unit) return levels[GUID[unit]] end

-- The game's meter: its fights, oldest first, and each one's list by type. A number can be hidden (Hide).
Enum.DamageMeterType = { DamageDone = 0, Dps = 1, HealingDone = 2, Hps = 3, Interrupts = 5 }
Enum.DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 2 }
local NAMES = { [0] = "damage", [1] = "damage", [2] = "healing", [3] = "healing", [5] = "interrupts" }
local fights, overall, hidden, hiddenGuids = {}, nil, false, false
local asked = {}

local function Hide(value)
    if hidden then return W.Secret(value) end
    return value
end

local function Session(numbers, seconds)
    local function List(kind)
        local list, top = {}, 0
        for guid, row in pairs(numbers) do
            local amount = row[kind] or 0
            list[#list + 1] = { sourceGUID = hiddenGuids and W.Secret(guid) or guid, name = row.name, classFilename = row.class,
                                isLocalPlayer = guid == GUID.player, amount = amount }
            top = math.max(top, amount)
        end
        table.sort(list, function(a, b) return a.amount > b.amount end)
        for _, source in ipairs(list) do
            local amount = source.amount
            source.amount = nil
            source.totalAmount, source.amountPerSecond = Hide(amount), Hide(amount / seconds)
        end
        return { combatSources = list, maxAmount = Hide(top), totalAmount = Hide(0), durationSeconds = Hide(seconds) }
    end
    return List
end

local function Add(id, name, seconds, numbers)
    fights[#fights + 1] = { sessionID = id, name = name, durationSeconds = seconds, numbers = numbers, list = Session(numbers, seconds) }
end

local PEOPLE = { ["Player-1-1"] = { "Droopy Fairwind", "DRUID" }, ["Player-1-2"] = { "Brisa Ashford", "WARRIOR" },
                 ["Player-1-3"] = { "Caelum Crowley", "PRIEST" }, ["Player-1-4"] = { "Dorin Dunmere", "HUNTER" } }
local function Numbers(rows)
    for guid, row in pairs(rows) do row.name, row.class = PEOPLE[guid][1], PEOPLE[guid][2] end
    return rows
end

C_DamageMeter = {
    IsDamageMeterAvailable = function() return true, "" end,
    GetAvailableCombatSessions = function()
        local list = {}
        for index, one in ipairs(fights) do
            list[index] = { sessionID = one.sessionID, name = one.name, durationSeconds = one.durationSeconds }
        end
        return list
    end,
    GetCombatSessionFromType = function(kind, type)
        asked[#asked + 1] = { kind = kind, type = type }
        if kind == Enum.DamageMeterSessionType.Overall then return overall(NAMES[type]) end
        return fights[#fights].list(NAMES[type])
    end,
    GetCombatSessionFromID = function(id, type)
        asked[#asked + 1] = { id = id, type = type }
        for _, one in ipairs(fights) do
            if one.sessionID == id then return one.list(NAMES[type]) end
        end
    end,
    GetCombatSessionSourceFromType = function(_, type, guid)
        local numbers = fights[#fights].numbers[guid]
        return { totalAmount = Hide(numbers and numbers[NAMES[type]] or 0), maxAmount = Hide(0), combatSpells = {} }
    end,
}
C_DamageMeter.GetCombatSessionSourceFromID = C_DamageMeter.GetCombatSessionSourceFromType

-- The first fight, and all fights added up.
Add(7, "Hogger", 10, Numbers({
    ["Player-1-1"] = { damage = 3000, healing = 100, interrupts = 1 },
    ["Player-1-2"] = { damage = 2000, healing = 0, interrupts = 3 },
    ["Player-1-3"] = { damage = 100, healing = 9000 },
    ["Player-1-4"] = { damage = 8000, healing = 0, interrupts = 0 },
}))
overall = Session(Numbers({
    ["Player-1-1"] = { damage = 100000, healing = 1, interrupts = 1 },
    ["Player-1-4"] = { damage = 200000, healing = 1, interrupts = 1 },
}), 100)

-- Threat on the mob: raw threat a hundred times what the game speaks of (Threat.SCALE), hidden or not.
local threat = {}
local mobAttackable = true
UnitCanAttack = function() return mobAttackable end
UnitDetailedThreatSituation = function(unit)
    local row = threat[GUID[unit]]
    if not row then return nil end
    return row[1] == 100, 0, Hide(row[1]), Hide(row[1]), Hide(row[2])
end
units.target = { name = "Hogger", health = 100, most = 100 }

-- The game's own meter, to be kept out of sight.
DamageMeter = W.NewWidget("Frame", "DamageMeter", UIParent)
local meterParent = DamageMeter:GetParent()
W.cvarInfo.damageMeterEnabled = { default = "0" }

if RETAIL then W.Play("retail") end
W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")

local Meter, Fights, Threat, Read, Row = ns.Meter, ns.MeterFights, ns.MeterThreat, ns.MeterRead, ns.MeterRow
local handle = Meter.handle
local frame = handle.frame
local function Set(key, value) Core.Set("Combat", key, value) end

-- The rows there are, by the name they show.
local function Find(name)
    for _, widget in ipairs(W.frames) do
        if rawget(widget, "bars") and widget.name._text == (RETAIL and name:match("^%S+") or name) then return widget end
    end
end
local box
for _, widget in ipairs(W.frames) do
    if rawget(widget, "_template") == "WowScrollBoxList" then box = widget end
end
local function Order()
    local names = {}
    for index, person in ipairs(box.lines) do names[index] = person.name:match("^%S+") end
    return table.concat(names, ", ")
end
-- A bar of a row by its kind's words.
local function Bar(row, word)
    for _, bar in ipairs(row.bars) do
        if bar._shown and bar.label._text == word then return bar end
    end
end

-------------------------------------------------------------------------------
--  Where it stands, what it is
-------------------------------------------------------------------------------
-- At first it hides out of a fight and alone: there empty, for the mouse's coming; the rest of this file has it in sight.
local block
for _, widget in ipairs(W.frames) do
    if rawget(widget, "_template") == nil and widget._parent == handle.inside and widget._kind == "Frame" then block = widget end
end
check(frame:IsShown() and not block._shown, "out of a fight the window is there, nothing of it to see")
Set("meterHideRest", false)
Set("meterHideAlone", false)
check(block._shown, "with both off in sight")

Meter.Refresh()
local point, _, relative, x, y = frame:GetPoint(1)
check(point == "TOPLEFT" and relative == "TOPLEFT" and x == 320 and y == 0, "at first right of the quest log, at the very top")
check(frame:GetWidth() == Meter.WIDTH and frame:GetHeight() == Meter.HEIGHT, "at its first size")
check(frame:GetFrameStrata() == "LOW", "in the layer of the quest log on the screen")
check(handle.bar == nil, "no title bar")
check(not frame:IsMouseClickEnabled() and frame:IsMouseMotionEnabled(), "it takes no click, only the mouse's coming")
local drawn = 0
for _, widget in ipairs(W.frames) do
    if widget._kind == "Texture" and widget._parent == frame then drawn = drawn + 1 end
end
check(drawn == 0, "no background")
check(W.cvars.damageMeterEnabled == "1", "the game's meter gathers: its setting is on")
check(DamageMeter:GetParent() ~= meterParent, "and its window is out of sight: ours or the game's, never both")

-------------------------------------------------------------------------------
--  The list
-------------------------------------------------------------------------------
local mine = Find("Droopy Fairwind")
check(mine and mine.level._text == 60 and mine.item._text == 71, "your own line: level, item level and name")
check(mine.icon._atlas == "classicon-druid" or mine.icon._shown, "and your class's icon")
check(mine:GetParent() == block, "you stand apart from the list")
check(Order() == "Dorin, Brisa, Caelum", "the others by DPS, the game's list as it comes")

local healer = Find("Caelum Crowley")
check(healer.item._text == Row.NONE, "an item level nobody read yet")
check(Bar(mine, "Damage")._max == 8000 and Bar(mine, "Damage")._value == 3000, "a bar's whole length is the fight's highest")
check(Bar(mine, "Damage").value._text:find("3000", 1, true) and Bar(mine, "Damage").value._text:find("/s", 1, true),
    "its numbers: per second and the whole fight")
check(Bar(mine, "Interrupts").value._text == "1", "interrupts: a count alone")
check(Bar(healer, "Healing")._barColor[2] > Bar(healer, "Healing")._barColor[1], "healing green")
check(Bar(mine, "Threat") and Bar(mine, "Damage") and Bar(mine, "Healing") and Bar(mine, "Interrupts"), "a bar for each thing")

Set("meterThreat", false)
check(Bar(mine, "Threat") == nil and Bar(mine, "Damage") ~= nil, "unticked, on every character")
check(mine:GetHeight() == Row.Height(3), "and the row is lower")
Set("meterThreat", true)

Set("meterMine", false)
check(Order():find("Droopy", 1, true) and Order():find("^Dorin"), "My self on top off: you among the others")
Set("meterMine", true)
check(not Order():find("Droopy", 1, true), "on again: on top")

for _, want in ipairs({ { "hps", "^Caelum" }, { "interrupts", "^Brisa" }, { "damage", "^Dorin" }, { "healing", "^Caelum" } }) do
    Set("meterOrder", want[1])
    check(Order():find(want[2]), "sorted by " .. want[1])
end
asked = {}
Set("meterOrder", "dps")
local rate
for _, one in ipairs(asked) do rate = rate or one.type == Enum.DamageMeterType.Dps end
check(rate, "by DPS the game's list by DPS is read")

-- Only as many as fit, the wheel for the rest.
frame._height = Row.Height(4) * 2 + 1
frame:GetScript("OnSizeChanged")(frame)
check(frame._wheel == true, "more than fit: the wheel scrolls them")
check(box._height == Row.Height(4), "whole rows only")
frame:GetScript("OnMouseWheel")(frame, -1)
check(box.first == 2, "a character a notch")
frame:GetScript("OnMouseWheel")(frame, -1)
frame:GetScript("OnMouseWheel")(frame, -1)
check(box.first == 3, "no further than the last")
frame:GetScript("OnMouseWheel")(frame, 1)
check(box.first == 2, "and back")
frame._height = Meter.HEIGHT
frame:GetScript("OnSizeChanged")(frame)
check(not frame._wheel and box.first == 1, "all fit: the wheel is the game's again, nobody out of sight")

-------------------------------------------------------------------------------
--  Grows down, or up
-------------------------------------------------------------------------------
frame._left, frame._bottom, frame._width, frame._height = 320, 680, 260, 400
handle.options.docked()
check(block:GetPoint(1) == "TOPLEFT", "in the screen's top half it hangs from the top")
frame._bottom = 100
handle.options.docked()
check(block:GetPoint(1) == "BOTTOMLEFT", "in the bottom half it stands on the bottom and grows up")
frame._bottom = 680
handle.options.docked()

-------------------------------------------------------------------------------
--  The mouse
-------------------------------------------------------------------------------
local controls
for _, widget in ipairs(W.frames) do
    if widget._parent == block and rawget(widget, "_width") == ns.MeterControls.WIDTH then controls = widget end
end
check(controls and not controls._shown, "no buttons at rest")
frame._mouseOver = true
frame:GetScript("OnEnter")(frame)
check(controls._shown and frame.drag._shown, "the mouse on it: the buttons, and the first line to drag it by")
check(handle:Draggable(), "which moves a window without a title bar")
frame._mouseOver = false
W.Wait(1)
for _ = 1, 20 do
    for _, widget in ipairs(W.frames) do
        local update = widget._shown and widget._scripts and widget._scripts.OnUpdate
        if update then update(widget, 0.1) end
    end
end
check(not controls._shown and not frame.drag._shown, "gone with the mouse")

-------------------------------------------------------------------------------
--  A character's own bars
-------------------------------------------------------------------------------
local function Choice(words)
    for _, item in ipairs(W.menus[#W.menus].items or W.menus[#W.menus]) do
        if item.text == words then return item end
    end
end
Set("meterDamage", false)
Set("meterHealing", false)
Set("meterInterrupts", false)
local brisaRow = Find("Brisa Ashford")
check(Bar(brisaRow, "Threat") and not Bar(brisaRow, "Damage"), "the window set to threat alone")
check(not brisaRow.line._shown, "a name takes no click at rest")
frame:GetScript("OnEnter")(frame)
frame._mouseOver = true
check(brisaRow.line._shown, "with the mouse on the window it does")
brisaRow.line:GetScript("OnClick")(brisaRow.line, "RightButton")
check(Choice("Show Damage") and not Choice("Show Damage").checked("damage"), "a right click on a name: that character's own flyout")
Choice("Show Damage").fn("damage")
brisaRow = Find("Brisa Ashford")
check(Bar(brisaRow, "Threat") and Bar(brisaRow, "Damage"), "damage for that character alone")
check(not Bar(Find("Dorin Dunmere"), "Damage"), "and for nobody else")
check(box.view.extent(nil, brisaRow.line.person) > box.view.extent(nil, Find("Dorin Dunmere").line.person),
    "their row is higher")
check(ns.store.meterPeople[GUID.raid2].damage == true, "kept by who they are")
frame.drag:GetScript("OnMouseUp")(frame.drag, "RightButton")
check(Choice("Show Threat").checked("threat"), "your own line's name takes it too")
Choice("Show Threat").fn("threat")
check(not Bar(mine, "Threat") and #Find("Dorin Dunmere").bars >= 1, "and a bar can go for one character as well")
frame.drag:GetScript("OnMouseUp")(frame.drag, "RightButton") -- the game's menu builds itself anew after a tick
Choice("As the window's ticks").fn()
check(Bar(mine, "Threat") and ns.store.meterPeople[GUID.player] == nil, "as the window's ticks again")
brisaRow.line:GetScript("OnClick")(brisaRow.line, "RightButton")
Set("meterDamage", true)
Choice("Show Damage").fn("damage")
check(not Bar(Find("Brisa Ashford"), "Damage") and Bar(Find("Dorin Dunmere"), "Damage"),
    "with the window showing damage, one character can do without")
Choice("Show Damage").fn("damage")
check(ns.store.meterPeople[GUID.raid2] == nil, "what comes out as the ticks is no choice of its own")
Set("meterHealing", true)
Set("meterInterrupts", true)
frame._mouseOver = false
for _ = 1, 20 do
    for _, widget in ipairs(W.frames) do
        local update = widget._shown and widget._scripts and widget._scripts.OnUpdate
        if update then update(widget, 0.1) end
    end
end

-------------------------------------------------------------------------------
--  Pages
-------------------------------------------------------------------------------
Add(8, "Vancleef", 20, Numbers({
    ["Player-1-1"] = { damage = 500, healing = 0, interrupts = 0 },
    ["Player-1-4"] = { damage = 900, healing = 0, interrupts = 2 },
}))
Meter.Refresh()
local page, count = Fights.Page()
check(page == 2 and count == 2, "the last page: the fight going on or last")
check(Bar(mine, "Damage")._value == 500, "with Reset on new combat this fight alone")
Set("meterReset", false)
check(Bar(mine, "Damage")._value == 100000, "without it all fights added up")
Set("meterReset", true)
Fights.Step(-1)
Meter.Refresh()
check(Fights.Page() == 1 and Bar(mine, "Damage")._value == 3000, "the arrow back: the fight before, by its own number")
check(Find("Brisa Ashford") ~= nil, "with who fought in it, here or not")
Fights.Step(-1)
check(Fights.Page() == 1, "no page before the first")
Fights.Step(1)
Meter.Refresh()
check(Fights.Page() == 2 and Bar(mine, "Damage")._value == 500, "on: the last page again")

-------------------------------------------------------------------------------
--  Threat
-------------------------------------------------------------------------------
Fights.Step(-1) -- a new fight goes to the live page
threat = { ["Player-1-1"] = { 20, 10000 }, ["Player-1-2"] = { 100, 50000 } }
W.Combat(true)
W.clock = W.clock + 5
Meter.Refresh()
check(Fights.Page() == 2, "a new fight: the live page")
threat["Player-1-1"][2], threat["Player-1-2"][2] = 30000, 90000
W.clock = W.clock + 5
Meter.Refresh()
local brisa = Find("Brisa Ashford")
check(Bar(brisa, "Threat")._max == 100 and Bar(brisa, "Threat")._value == 100, "the bar: their share of the mob")
check(Bar(brisa, "Threat").value._text:find("400", 1, true), "threat gained in the fight, in the game's threat")
check(Bar(brisa, "Threat").value._text:find("/s", 1, true), "and per second")
W.Fire("PLAYER_TARGET_CHANGED")
threat["Player-1-1"][2], threat["Player-1-2"][2] = 5, 7
Meter.Refresh()
check(Bar(brisa, "Threat").value._text:find("400", 1, true), "another mob is no loss of what was gained")
W.Combat(false)

-------------------------------------------------------------------------------
--  A fight with the numbers hidden
-------------------------------------------------------------------------------
Add(9, "Mutanus", 30, Numbers({
    ["Player-1-1"] = { damage = 100, healing = 0, interrupts = 0 },
    ["Player-1-3"] = { damage = 300, healing = 500, interrupts = 1 },
    ["Player-1-4"] = { damage = 200, healing = 0, interrupts = 0 },
}))
hidden = true
threat = { ["Player-1-1"] = { 40, 30000 } }
W.Combat(true)
Meter.Refresh()
check(not ns.off, "no number hidden by the game was compared or computed")
check(issecretvalue(Bar(mine, "Damage")._value) and issecretvalue(Bar(mine, "Damage")._max), "they go to the bar as they came")
check(Order() == "Caelum, Dorin, Brisa", "sorted by the places on the game's list")
check(issecretvalue(Bar(mine, "Threat")._value), "a share on a boss too")
check(Bar(mine, "Threat").value._text ~= nil, "and into its words")

-- Who the sources are hidden too: each member is asked for by their GUID, which gives the total.
hiddenGuids = true
Meter.Refresh()
check(not ns.off and issecretvalue(Bar(Find("Caelum Crowley"), "Damage")._value), "members asked for one by one")

-- A read the game refuses: nothing shows and nothing is wrong.
local list = C_DamageMeter.GetCombatSessionFromType
C_DamageMeter.GetCombatSessionFromType = function() error("a secret table") end
Meter.Refresh()
check(not ns.off, "a table the game keeps closed stops nothing")
C_DamageMeter.GetCombatSessionFromType = list

-------------------------------------------------------------------------------
--  Saved fights
-------------------------------------------------------------------------------
local printed = #W.printed
Fights.Save("Mutanus again")
check(#Fights.List() == 0 and #W.printed > printed, "asked in a fight it waits for the end, and says so")
hidden, hiddenGuids = false, false
W.Combat(false)
W.Wait(1)
check(#Fights.List() == 1 and Fights.List()[1].name == "Mutanus again", "over: saved under its name")
local record = Fights.List()[1]
check(record.people[1].name:find("^Droopy") and record.people[1].me, "with who was there")

Fights.Save("")
check(Fights.List()[2].name:find("Mutanus", 1, true), "an empty name: the one offered")
Fights.Delete(Fights.List()[2])
check(#Fights.List() == 1, "deleted")

raid = false
Fights.Load(record)
Meter.Refresh()
check(Fights.Loaded() and Find("Caelum Crowley") ~= nil, "loaded out of the group: its people as they were")
check(Bar(mine, "Damage")._value == 100 and Bar(mine, "Damage")._max == 300, "and its numbers")
Fights.Step(1)
Meter.Refresh()
check(not Fights.Loaded(), "an arrow leads back to the fights")
Fights.Load(record)
W.Combat(true)
check(not Fights.Loaded(), "and so does a new fight")
W.Combat(false)
raid = true

-------------------------------------------------------------------------------
--  When it shows
-------------------------------------------------------------------------------
Set("meterHideRest", true)
Set("meterHideAlone", true)
check(frame:IsShown() and not block._shown, "Hide outside combat: out of a fight out of sight")
W.Fire("PLAYER_REGEN_DISABLED") -- as the game tells of it, its lockdown has not begun
check(block._shown, "a fight brings it")
local running = false
for _, widget in ipairs(W.frames) do
    if widget._parent == frame and widget._shown and widget._scripts and widget._scripts.OnUpdate then running = true end
end
check(running, "and its looks run, the game's lockdown or not")
W.Combat(true)
raid = false
W.Fire("GROUP_ROSTER_UPDATE")
check(not block._shown, "Hide when not in group: left alone in the fight out of sight")
raid = true
W.Fire("GROUP_ROSTER_UPDATE")
check(block._shown, "a group brings it back")
W.Combat(false)
W.Wait(0)
check(not block._shown, "the fight over: gone again")

frame._mouseOver = true
frame:GetScript("OnEnter")(frame)
check(block._shown, "Show on mouseover: the mouse on its place brings it")
frame._mouseOver = false
for _ = 1, 20 do
    for _, widget in ipairs(W.frames) do
        local update = widget._shown and widget._scripts and widget._scripts.OnUpdate
        if update then update(widget, 0.1) end
    end
end
check(not block._shown and not frame._wheel, "and it goes with the mouse, the wheel the game's")

Set("meterHover", false)
check(not frame:IsShown(), "without it the window itself is gone")
W.Combat(true)
check(frame:IsShown() and block._shown, "and a fight brings it")
W.Combat(false)
W.Wait(0)
Set("meterHover", true)

Fights.Load(record)
Meter.Refresh()
check(block._shown, "a saved fight loaded stays in sight, in a group or not")
Fights.Unload()
Meter.Refresh()
check(not block._shown, "back to the fights it goes")
if not RETAIL then
    Meter.Dress(true)
    check(block._shown, "on the full screen it always shows")
    Meter.Dress(false)
    check(not block._shown, "and not back on the screen")
end
Set("meterHideRest", false)
Set("meterHideAlone", false)

-------------------------------------------------------------------------------
--  Its other look, on or off, standing down
-------------------------------------------------------------------------------
if not RETAIL then
    Meter.Dress(true)
    check(frame:GetFrameStrata() == "DIALOG", "over the full screen, above the board")
    local _, _, _, fullX, fullY = frame:GetPoint(1)
    check(fullX == Meter.FULL_X and fullY == Meter.FULL_Y, "in its top left corner, its own place")
    Meter.Dress(false)
    local _, _, _, screenX = frame:GetPoint(1)
    check(frame:GetFrameStrata() == "LOW" and screenX ~= Meter.FULL_X, "and back at its place on the screen")
end

Meter.Toggle()
check(not frame:IsShown() and W.cvars.damageMeterEnabled == "0", "off: gone, the game's setting as it was")
check(DamageMeter:GetParent() == meterParent, "and the game's window back")
Meter.Toggle()
check(frame:IsShown() and DamageMeter:GetParent() ~= meterParent, "on again")

ns.StandDown("a test")
check(not frame:IsShown() and DamageMeter:GetParent() == meterParent and W.cvars.damageMeterEnabled == "0",
    "standing down: the game's meter is back")

if RETAIL then
    io.write(("Meter in Retail: all %d checks passed.\n"):format(passed))
    return
end
check(os.execute(("lua5.1 '%s/dev/tests/meter.lua' retail"):format(root)) == 0, "in Retail the meter runs as that game has it")
io.write(("Meter: all %d checks passed.\n"):format(passed))
