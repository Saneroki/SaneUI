-- Runs the Combat module against the stand-in client (wowstub.lua): its window docked at the bottom middle, the
-- middle half of the bottom edge filling the screen, its windows there on Core's board (our own talents and
-- spellbook side by side, each as wide as its share of the game's sizes), a planner Sane UI knows as a window of
-- its own (listed only while it is there, seated in its panel, opened and closed with it), the quest marks beside
-- nameplates, and giving everything back. Our spellbook itself is tried in dev/tests/book.lua, our talents in
-- dev/tests/talents.lua. The look can only be judged in the game. At its end it runs again as Retail loads the module
-- ("retail": W.Play), where neither our spellbook nor our talents are.
-- Usage, from the project folder:  lua5.1 dev/tests/combat.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
local RETAIL = arg[1] == "retail"
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:Raise() self._level = 500 end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:IsProtected() return self._protected or false end
-- An animation: the test moves its clock (as dev/tests/window.lua does).
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, progress = 0 }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress = true, 0 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha = noop
    function group:CreateAnimation()
        local animation = setmetatable({ SetSmoothing = noop, SetToAlpha = noop }, { __index = function() return noop end })
        function animation:SetDuration(seconds) group.duration = seconds end
        function animation:GetProgress() return group.progress end
        function animation:GetSmoothProgress() return group.progress end
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate and self.scripts.OnUpdate() end
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished() end
    end
    self._group = self._group or group
    return group
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetCursorPosition = function() return W.cursorX or 0, W.cursorY or 0 end
GetBindingKey = function(action) return action == "TOGGLESPELLBOOK" and "P" or nil end
GetBindingText = function(key) return key end
-- The game's addons it loads when first wanted: a function waits for one.
local waiting = {}
EventUtil = { ContinueOnAddOnLoaded = function(name, fn)
    if W.loaded[name] then return fn() end
    waiting[name] = fn
end }

-- The game's micro menu buttons the open buttons click.
TalentMicroButton = W.NewWidget("Button", "TalentMicroButton")
SpellbookMicroButton = W.NewWidget("Button", "SpellbookMicroButton")

-- The game's override bindings (Keys.lua): kept per owner, to look at.
W.overrides = {}
ClearOverrideBindings = function(owner) W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end

-- The game's paging controls in our spellbook (dev/tests/book.lua tries them): a page of so many.
W.templates.PagingControlsHorizontalTemplate = function(controls)
    controls.PageText = W.NewWidget("FontString", nil, controls)
    controls.currentPage, controls.maxPages = 1, 1
    function controls:GetCurrentPage() return self.currentPage end
    function controls:SetMaxPages(count) self.maxPages = math.max(count, 1) end
    function controls:UpdateControls() end
end
-- WoW: Forever's spellbook and talents, which ours are made after (Combat.lua, ns.Serves): the spells of its flyouts
-- loose in its book, its two specializations each with a talent config of its own. Retail lacks both (W.Play).
C_SpellBook.IsSpellBookItemLooseFlyoutMember = function() return false end
C_SpecializationInfo = { GetCombatConfigIDForSpecGroup = function(group) return 100 + group end }

-- The unit frames and the clean action bars: the game's unit functions, unit watch, frames and main action bar.
local fight = require("combatclient").Install(W)
local units, Unit, watched, divider = fight.units, fight.Unit, fight.watched, fight.divider
units.player = { name = "Droopy", surname = "Fairwind", player = true, class = "WARRIOR", level = 20, health = 850,
                 most = 1000, power = 30, powerMost = 100 }
W.actions[1] = { kind = "spell", id = 6603 } -- the main bar's first button holds an action, its second is empty
if RETAIL then W.Play("retail") end

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Board, Edge = ns.Board, Core.Edge

-------------------------------------------------------------------------------
--  In Retail: neither our spellbook nor our talents, so no full screen and the game's keys its own; the quest marks
-------------------------------------------------------------------------------
if RETAIL then
    check(Core.RETAIL and not ns.Serves() and not Board.Present("spellbook") and not Board.Present("talents"),
        "Retail has not the spellbook and talents ours are made after: neither of ours is there")
    check(ns.Window.handle == nil and not ns.Window.Full() and not ns.Window.Fill(),
        "no window: the bottom edge fills no screen")
    check(next(W.overrides) == nil and not ns.Keys.Taken() and not ns.Keys.Taken("TOGGLETALENTS"),
        "no key of the game's runs ours: its spellbook and talents keys open its own windows")
    ns.Keys.Press("spellbook")
    ns.Keys.Press("talents")
    check(not ns.off and not ns.Window.Full(), "our own keys (in the game's key bindings) do nothing, and nothing fails")
    local listed = {}
    for _, option in ipairs(Core.described[ns.name].list) do listed[option.key] = true end
    check(listed.questMarks and listed.unitPlayer and listed.unitSize and listed.cleanBars and not listed.keys
        and not listed.expand, "its settings: the unit frames, the action bars and the quest marks")
    local player = ns.Units.KINDS[1].button
    check(player and watched[player] and player.face.level._text == "20" and PlayerFrame._mouse == false
        and TargetFrame._parent ~= UIParent and ns.ActionBars.Clean() and MainActionBar.BorderArt._alpha == 0,
        "the unit frames and the clean action bars, as in Forever")
    Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
    local plate = W.NewWidget("Frame", nil, UIParent)
    C_NamePlate = { GetNamePlateForUnit = function(unit) return unit == "nameplate1" and plate or nil end }
    C_QuestLog = { UnitIsRelatedToActiveQuest = function() return true end }
    C_TooltipInfo.GetUnit = function() return { lines = { { type = 8, leftText = "Young Wolf slain: 3/8" } } } end
    UnitIsPlayer, UnitName = function() return false end, function() return "Young Wolf" end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    local mark
    for _, widget in ipairs(W.frames) do if widget._parent == plate and widget.icon then mark = widget end end
    check(mark and mark._shown and mark.icon._texture == ns.QuestMarks.ICONS.kill and mark.count._text == "3/8",
        "the quest marks beside nameplates, as in Forever")
    ns.StandDown("a test")
    check(ns.off and not mark._shown
        and ns.GIVEN_BACK == "no quest marks beside nameplates; the game's own unit frames and action bars are back",
        "standing down: the quest marks go, and what is told says so")
    check(PlayerFrame._mouse == true and TargetFrame._parent == UIParent and MainActionBar.BorderArt._alpha == 1,
        "and the game's unit frames and action bars are its own again")
    io.write(("Combat in Retail: all %d checks passed.\n"):format(passed))
    return
end

-------------------------------------------------------------------------------
--  The window, docked at the bottom middle
-------------------------------------------------------------------------------
local handle = ns.Window.handle
local frame = handle.frame
check(handle.zone == "BOTTOM" and frame._width == ns.Window.WIDTH and not frame._mouse,
    "its window is docked at the bottom middle at first, and takes no click while small")
frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0
local strip = handle.edge.strips.bottom
check(strip and strip:IsShown() and strip._points[1][1] == "BOTTOM" and strip._points[1][2] == UIParent
    and strip._width == 1920 * ns.Window.STRIP and near(strip._height, 2 * 768 / 2160) and strip._strata == "DIALOG",
    "the strip that fills the screen is the middle half of the screen's bottom edge, however wide the window is")
UIParent._width = 1600
W.Fire("DISPLAY_SIZE_CHANGED")
check(strip._width == 800, "another screen size: still half of it")
UIParent._width = 1920
W.Fire("UI_SCALE_CHANGED")
check(strip._width == 960, "another UI scale: still half")


-------------------------------------------------------------------------------
--  The full screen: Core's board, nothing open
-------------------------------------------------------------------------------
local inside, layouts = handle.inside, Board.layouts
-- Where what the full window holds stands, and its layer, as the game gives a child its parent's (the stand-in
-- knows no anchors).
local top = 1080 - Core.Window.BAR
inside._left, inside._bottom, inside._height = 0, 0, top
inside._strata, inside._level = "HIGH", 501
local pad, edge, head = Core.Board.PAD, Core.Board.EDGE, Core.Board.HEAD

local function Push()
    W.Wait(1) -- a while after the strip came under the mouse
    strip:GetScript("OnEnter")(strip)
    W.cursorX, W.cursorY = 960, 500 -- the mouse goes away again: the next push counts
    W.Wait(Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end
local function Back()
    frame._group:Run(1)
    handle:Place()
    frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0
end
-- A panel's body (a rect of the board), as a window seated there has it.
local function Body(rect)
    return { rect[1] + edge, rect[2] + head + edge, rect[3] - 2 * edge, rect[4] - head - 2 * edge }
end
-- A window of that size seated in a room of the board: as large as fits, never larger, in its middle.
local function Seated(window, room, width, height)
    local scale = math.min(room[3] / width, room[4] / height, 1)
    local point = window._points[1]
    return Core.Lent(window) and near(window._scale, scale) and #window._points == 1 and point[1] == "TOPLEFT"
        and point[2] == UIParent and near(point[4] * scale, room[1] + (room[3] - width * scale) / 2)
        and near(point[5] * scale, top - room[2] - (room[4] - height * scale) / 2)
end
local function In(key) return Body(layouts.rects[key]) end


Push()
check(handle.edge.full and not layouts.standing, "the mouse pushed against the middle of the bottom edge fills the screen; the board waits until it stands")
Stand()
local talents, book = layouts.panels.talents, layouts.panels.spellbook
local hasTalents = Board.Present("talents")
check(layouts.standing and layouts:Has("spellbook") and book and book:IsShown()
    and (not hasTalents or (layouts:Has("talents") and talents and talents:IsShown())),
    "standing, Core's board holds our own talents and spellbook")
check(book.title._text == ns.TEXT.spellbook and (not hasTalents or talents.title._text == ns.TEXT.talents),
    "each panel is headed with its name")
if hasTalents then
    local rects = layouts.rects
    local room = 1920 - 3 * pad
    local talentsWidth = math.floor(room * 1218 / (1218 + ns.Book.WIDE) + 0.5)
    check(rects.talents[1] == pad and rects.talents[3] == talentsWidth and rects.spellbook[1] == 2 * pad + talentsWidth
        and rects.spellbook[3] == room - talentsWidth and rects.talents[4] == top - 2 * pad,
        "the first layout: the talents at the left, the spellbook at the right, each as wide as its share of the game's sizes")
end
check(not Board.Present("planner"), "without a talent planner Sane UI knows, there is no planner's window to add")
Push()
check(not handle.edge.full, "back to its size")
Back()

-------------------------------------------------------------------------------
--  Your spellbook and talents keys open ours
-------------------------------------------------------------------------------
local owner
for each, bindings in pairs(W.overrides) do if bindings.P then owner = each end end
check(owner and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook and ns.Keys.Taken(),
    "at the login, the key of the game's spellbook (P) runs our own key")
ns.Keys.Press("spellbook")
check(handle.edge.full, "pressed: the full screen comes")
Stand()
check(layouts:Has("spellbook"), "with the spellbook on it")
ns.Keys.Press("spellbook")
check(not handle.edge.full, "pressed again: back to its size, as the game's key toggles its window")
Back()
Core.Set(ns.name, "keys", false)
check(W.overrides[owner] == nil and not ns.Keys.Taken(), "the switch off: the game's keys open the game's windows")
Core.Set(ns.name, "keys", true)
check(W.overrides[owner] and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook, "on again: ours")
ns.Keys.Press("pet")
check(not handle.edge.full, "without a pet's spellbook the pet book's key does nothing, as the game's")
-- A key while the screen may not fill (Edit Mode): what it asked for does not wait for a full screen that comes
-- another way.
C_SpellBook.HasPetSpells = function() return 1 end -- a pet with its spellbook from here on
PetHasSpellbook = function() return true end
Core.EditMode.active = true
ns.Keys.Press("pet")
Core.EditMode.active = false
check(not handle.edge.full, "in Edit Mode a key fills no screen")
Push()
Stand()
check(handle.edge.full and ns.Book.Chosen() == "line1", "the next full screen comes as it is: the book not at the pet's tab")
-- The full screen's search box: what is typed reaches its windows (the book shows what it finds).
local box = handle.bar.box
handle.bar.find:GetScript("OnClick")(handle.bar.find) -- the search opened over the title bar
box:SetText("frost")
box:GetScript("OnTextChanged")(box)
check(Board.layouts.search == "frost" and ns.Book.Chosen() == nil, "what is typed into the full screen's search box reaches its windows")
-- The pet book's key: the book at the pet's tab, the search left and its box emptied, the screen staying full
-- where it showed another; pressed again at the pet's tab, back to its size.
ns.Keys.Press("pet")
box:GetScript("OnTextChanged")(box) -- the game's box tells its change by itself
check(handle.edge.full and ns.Book.Chosen() == "pet" and box:GetText() == "" and Board.layouts.search == "",
    "the pet book's key: the book at the pet's tab, the search box emptied")
check(not box:IsShown() and handle.bar.find:IsShown(), "and closed as Esc closes it: the title and the layouts' tabs back")
ns.Keys.Press("pet")
check(not handle.edge.full, "pressed again there: back to its size, as the game's key toggles its window")
Back()

-------------------------------------------------------------------------------
--  A talent planner Sane UI knows: a window of its own
-------------------------------------------------------------------------------
-- Its folder, window and functions as Core knows them (Neighbours.lua), so this file names no addon.
local known = Core.Neighbours.KNOWN.talents
check(Core.Neighbours.Window("talents") == nil, "while it is not installed, there is no planner")
local planner
local opens, closes = 0, 0
_G[known.api] = { UI = {
    [known.open] = function()
        opens = opens + 1
        planner = planner or W.NewWidget("Frame", known.window, UIParent)
        _G[known.window] = planner
        planner:SetSize(1000, 640)
        planner._strata = "HIGH"
        planner:Show()
    end,
    [known.close] = function()
        closes = closes + 1
        if planner then planner:Hide() end
    end,
} }
W.loaded[known.addon] = true
local handleOf = Core.Neighbours.Window("talents")
check(handleOf and handleOf.title == known.title and not handleOf:Shown(), "installed and loaded: Core gives a handle on it")
check(Board.Present("planner"), "now its window is there to add to the full screen")

Push()
Stand()
layouts:Toggle("planner") -- the dropdown Windows ticks it: on the layout
W.Wait(0)
local plannerPanel = layouts.panels.planner
check(layouts:Has("planner") and plannerPanel and plannerPanel:IsShown() and plannerPanel.title._text == ns.TEXT.planner,
    "ticked in the dropdown, the planner gets a panel of its own")
-- Its body where the board put it (the stand-in knows no anchors); laid out again, the planner is seated a frame later.
plannerPanel.body._left, plannerPanel.body._bottom, plannerPanel.body._width, plannerPanel.body._height = 100, 100, 800, 500
ns.Window.Reboard()
W.Wait(0)
check(opens >= 1 and planner and planner:IsShown() and Core.Lent(planner), "its panel shown, the planner opens and is seated in it")
Push()
check(not handle.edge.full and closes >= 1 and not planner:IsShown() and not Core.Lent(planner),
    "the window goes back: the planner is given back and closes")
Back()
_G[known.api].UI[known.open]() -- opened by its own command while the window is small
W.Wait(0)
check(handle.edge.full, "opened any way of its own while its panel is on the layout, the full screen comes with it")
Stand()
-------------------------------------------------------------------------------
--  Quest marks beside nameplates: as the game says it in the creature's tooltip data
-------------------------------------------------------------------------------
local questMark -- a mark shown at the end, looked at again after standing down
do
    local QuestMarks = ns.QuestMarks
    Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
    local plates, related, lines = {}, {}, {}
    C_NamePlate = { GetNamePlateForUnit = function(unit) return plates[unit] end }
    C_QuestLog = { UnitIsRelatedToActiveQuest = function(unit) return related[unit] or false end }
    C_TooltipInfo.GetUnit = function(unit) return { lines = lines[unit] or {} } end
    UnitIsPlayer = function(unit) return unit == "nameplate9" end
    UnitName = function(unit) return unit == "nameplate1" and "Young Wolf" or "Kobold Miner" end
    plates.nameplate1 = W.NewWidget("Frame", nil, UIParent)
    plates.nameplate1.UnitFrame = W.NewWidget("Frame", nil, plates.nameplate1)
    plates.nameplate2 = W.NewWidget("Frame", nil, UIParent)
    related.nameplate1, related.nameplate2 = true, true
    lines.nameplate1 = { { type = 17, leftText = "Wolves Across the Border" }, { type = 8, leftText = "Young Wolf slain: 3/8" } }
    lines.nameplate2 = { { type = 17, leftText = "Kobold Candles" }, { type = 8, leftText = "Large Candle: 1/8" } }
    local function Mark(plate)
        for _, widget in ipairs(W.frames) do if widget._parent == plate and widget.icon then return widget end end
    end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
    local wolf, kobold = Mark(plates.nameplate1), Mark(plates.nameplate2)
    check(wolf and wolf._shown and wolf.icon._texture == QuestMarks.ICONS.kill and wolf.count._text == "3/8"
        and wolf._points[1][2] == plates.nameplate1.UnitFrame, "a creature an objective names: the sword beside its plate, the count left of it")
    check(kobold and kobold._shown and kobold.icon._texture == QuestMarks.ICONS.loot and kobold.count._text == "1/8",
        "one the game ties to a quest whose objective names something else: the sack, to loot it")
    lines.nameplate1[2] = { type = 8, leftText = "Young Wolf slain: 8/8", completed = true }
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not wolf._shown and kobold._shown, "the objective done (the quest log changed): its mark goes, the others stay")
    related.nameplate2 = nil
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not kobold._shown, "the game says it no longer belongs to a quest: no mark")
    related.nameplate2 = true
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(not kobold._shown, "its plate gone: nothing of it is looked at")
    plates.nameplate9 = W.NewWidget("Frame", nil, UIParent)
    related.nameplate9 = true
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate9")
    check(not Mark(plates.nameplate9), "a player's plate: none")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
    check(kobold._shown, "shown again on the plate the game hands out again")
    Core.Set(ns.name, "questMarks", false)
    check(not kobold._shown, "the setting Quest marks on nameplates off: none")
    local reads = 0
    C_TooltipInfo.GetUnit = function(unit) reads = reads + 1 return { lines = lines[unit] or {} } end
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
    W.Fire("QUEST_LOG_UPDATE")
    W.Wait(0)
    check(reads == 0, "and nothing of the game's tooltip data is read meanwhile")
    Core.Set(ns.name, "questMarks", true)
    check(kobold._shown, "on again: there")
    questMark = kobold
end



-------------------------------------------------------------------------------
--  Unit frames: ours for you, your target and your focus, the game's out of sight
-------------------------------------------------------------------------------
local unitButtons = {}
do
    UnitName, UnitIsPlayer = fight.UnitName, fight.UnitIsPlayer -- as before the quest marks' plates
    local Units, Text = ns.Units, ns.UnitText
    for index, kind in ipairs(Units.KINDS) do unitButtons[kind.unit] = kind.button end
    local player, target, focus = unitButtons.player, unitButtons.target, unitButtons.focus
    check(player and target and focus and player._template == "SecureUnitButtonTemplate"
        and player:GetAttribute("unit") == "player" and target:GetAttribute("unit") == "target"
        and player:GetAttribute("*type1") == "target" and player:GetAttribute("*type2") == "togglemenu",
        "three secure unit buttons: a click targets, a right click opens the game's menu")
    check(watched[player] and watched[target] and watched[focus], "the game's unit watch shows each while its unit is there")
    local face = player.face
    check(face.name._text == "" and face.level._text == "20" and face.value._text == "850 | 85%",
        "your frame: your level, no name, your health and how much is left")
    local green = ns.UnitBar.GREEN
    check(face.health._max == 1000 and face.health._value == 850 and face.health._barColor[1] == green[1]
        and face.health._barColor[2] == green[2], "the bar green, not in your class's colour")
    local rage = face.powers[1]
    check(rage._shown and rage._max == 100 and rage._value == 30 and rage.value._text == "30 | 30%"
        and not face.powers[2]._shown and player._height == Units.HEIGHT + Units.POWER and Units.POWER == Units.HEIGHT / 2,
        "your rage in a bar under it, half as high, its words on the right: \"30 | 30%\"")
    check(near(rage._points[1][5], -(Units.HEIGHT + Core.Pixels(face, 1))) and rage._points[2][3] == "TOPRIGHT",
        "the power bar a pixel under the health bar, inside the outline")
    face._width, face._height = Units.WIDTH, Units.HEIGHT -- the stand-in places nothing: as large as its button
    Text.Layout(face)
    check(face.level._points[1][1] == "LEFT" and face.value._points[1][1] == "RIGHT" and face.name._points[1][1] == "LEFT"
        and face.name._points[1][4] == face.room.left + Text.GAP
        and near(face.name._width, Units.WIDTH - face.room.left - face.room.right - 2 * Text.GAP),
        "the level on the left, the name after it from the left up to the health, the health on the right")
    check(PlayerFrame.PlayerFrameContainer._alpha == 0 and PlayerFrame.PlayerFrameContent._alpha == 0
        and PlayerFrame._mouse == false and PlayerFrame._parent == UIParent,
        "the game's own frame out of sight and takes no clicks; it stays where it is, with what hangs on it")
    check(TargetFrame._parent ~= UIParent and TargetFrame._parent == FocusFrame._parent and not TargetFrame._parent._shown,
        "the game's target and focus frames stand in a hidden frame of ours")

    -- Your target: a creature, an elite, marked with a skull.
    units.target = { name = "Kobold Miner", level = 22, health = 40, most = 120, foe = true, reaction = 2,
                     classification = "elite", raid = 8 }
    W.Fire("PLAYER_TARGET_CHANGED")
    local foe = target.face
    check(foe.name._text == "Kobold Miner" and foe.value._text == "40 | 33%" and foe.raid._shown and foe.raid._cell == 8,
        "your target: its name, health, and its raid marker beside its level")
    check(foe.rank == ns.UnitBar.RANKS.elite and foe.health._barColor[2] == green[2] and foe.health._barColor[1] == green[1],
        "green for a foe too; the gold line of an elite")
    -- One width for every frame: the border on its edge, an elite's gold line inside it, the bar inside both.
    local pixel = Core.Pixels(foe, 1)
    check(target._width == Units.WIDTH and target._width == player._width and foe.border[1]._points[1][4] == 0
        and near(foe.rankLine[1]._points[1][4], pixel) and foe.rankLine[1]._shown
        and near(foe.health._points[1][4], 2 * pixel) and near(face.health._points[1][4], pixel)
        and near(foe.halo[1][1]._points[1][4], -pixel),
        "an elite's frame as wide as any: its rank's line inside the border, only the glow beyond the edge")
    -- Your target's target: a row under your target's frame while there is one, as a cast bar under a nameplate.
    local row = foe.rowButton
    check(row and row._template == "SecureUnitButtonTemplate" and row:GetAttribute("unit") == "targettarget"
        and row:GetAttribute("*type1") == "target" and row._parent == target and row._points[1][3] == "BOTTOMLEFT"
        and watched[row] and not foe.rowShown and not foe.row._shown,
        "its target's row: a secure button right under the frame, shown by the unit watch, none while it has no target")
    units.targettarget = { name = "Droopy", surname = "Fairwind", player = true, health = 600, most = 1000 }
    row:Show() -- the game's unit watch: your target has a target
    local calm = ns.UnitBar.CALM
    check(foe.rowShown and foe.row._shown and foe.rowName._text == "Droopy Fairwind" and foe.row._value == 600
        and foe.row._barColor[1] == calm[1] and foe.row._barColor[2] == calm[2] and foe.row._barColor[3] == calm[3]
        and foe.rowName._justify == "CENTER",
        "it shows under the frame: in the nameplates' light yellow of a neutral creature, its name alone in the middle")
    check(near(foe.border[2]._points[1][5], -(Units.POWER + Units.ROW)) and near(foe.health._points[2][5], -Units.HEIGHT)
        and near(foe.powers[1]._points[2][5], -(Units.HEIGHT + Units.POWER)),
        "the frame's outline goes round all, its power bar square at its bottom over the row")
    units.targettarget.health = 300
    foe.row._scripts.OnUpdate(foe.row, Units.POLL)
    check(foe.row._value == 300, "read again while it shows (the game sends no events of a target's target)")
    row:Hide()
    check(not foe.rowShown and not foe.row._shown and near(foe.border[2]._points[1][5], -Units.POWER),
        "gone: the frame alone again, its outline round its health and power")
    -- The game hides the row while the frame is out of sight (your target gone): no OnHide then; the frame looks again
    -- as it shows.
    foe.rowShown = true
    row._shown = false
    target:Hide()
    target:Show()
    check(not foe.rowShown and not foe.row._shown, "a row hidden while its frame was out of sight is gone when it shows")
    units.targettarget = nil
    units.target.health = 30
    W.Fire("UNIT_HEALTH", "target")
    check(foe.value._text == "30 | 25%" and foe.health._value == 30, "its health as it goes, heard from its own events")
    units.target.tanking = true
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(foe.glow._alpha == 1, "the glow while you have its aggro")
    units.target.tanking = false
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(foe.glow._alpha == 0, "and none while you do not")
    -- In a fight the game hides its health and your threat: shown as they are, nothing computed with them.
    issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    local hidden = { secret = true }
    units.target.health, units.target.tanking = hidden, hidden
    W.Fire("UNIT_HEALTH", "target")
    W.Fire("UNIT_THREAT_LIST_UPDATE", "target")
    check(not ns.off and foe.health._value == hidden and type(foe.value._text) == "table"
        and foe.value._text.abbreviated == hidden and foe.glow._alpha.from == hidden,
        "hidden health and threat: the bar, the text and the glow take them as they are")
    issecretvalue = nil
    units.target.health, units.target.tanking, units.target.dead = 0, false, true
    W.Fire("UNIT_HEALTH", "target")
    check(foe.value._text == ns.UnitText.DEAD, "a dead unit: Dead in place of its health")
    units.target.dead = false
    units.target.raid = nil
    W.Fire("RAID_TARGET_UPDATE")
    check(not foe.raid._shown and foe.room.left == Text.INSET + foe.levelRoom, "its marker taken off: none, and no room kept")

    -- Edit Mode: a frame whose unit is not there shows a sample, to be placed; after it, the unit watch again.
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(not watched[focus] and focus._shown and focus.face.sample and focus.face.name._text == ns.TEXT.samples.focus
        and focus.face.level._text == "20", "in Edit Mode your focus's frame shows as a sample, named for it")
    check(focus.face.rowShown and focus.face.rowName._text == ns.TEXT.samples.focustarget
        and player.face.rowShown and player.face.rowName._text == ns.TEXT.samples.pet,
        "and the rows under the frames too, named for what they stand for")
    check(not target.face.sample and target.face.name._text == "Kobold Miner", "a frame whose unit is there shows it")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(watched[focus] and not focus.face.sample and watched[focus.face.rowButton],
        "after Edit Mode the unit watch shows it again, and its row")
    focus.face.rowButton:Hide() -- the game's unit watch: your focus has no target
    player.face.rowButton:Hide() -- nor you a pet
    -- Edit Mode put the full screen back to its place (as every window of Core's): full again for what follows.
    if not handle.edge.full then
        Push()
        Stand()
    end

    -- The settings: each frame on or off, their size.
    Core.Set(ns.name, "unitFocus", false)
    check(not focus._shown and not watched[focus] and FocusFrame._parent == UIParent,
        "Your focus's frame off: ours hidden, the game's back")
    Core.Set(ns.name, "unitFocus", true)
    check(watched[focus] and FocusFrame._parent ~= UIParent, "on again: ours, the game's away")
    Core.Set(ns.name, "unitPlayer", false)
    check(PlayerFrame.PlayerFrameContainer._alpha == 1 and PlayerFrame._mouse == true and not player._shown,
        "Your frame off: the game's own frame as it was")
    Core.Set(ns.name, "unitPlayer", true)
    -- Your pet: a row under your frame; the game's pet frame by its alpha and clicks (its layout re-parents it).
    local pet = player.face.rowButton
    check(pet:GetAttribute("unit") == "pet" and watched[pet] and PetFrame._alpha == 0 and PetFrame._mouse == false
        and PetFrame._parent == PlayerFrame, "your pet's row under your frame, the game's pet frame out of sight")
    units.pet = { name = "Wolf", health = 80, most = 100 }
    pet:Show()
    check(player.face.rowName._text == "Wolf" and player.face.row._value == 80 and player.face.row._barColor[2] == green[2],
        "your pet: its name and health, green")
    Core.Set(ns.name, "unitPet", false)
    check(not watched[pet] and not pet._shown and PetFrame._alpha == 1 and PetFrame._mouse == true
        and not player.face.rowShown, "Your pet off: no row, the game's pet frame back")
    Core.Set(ns.name, "unitPet", true)
    check(watched[pet] and PetFrame._alpha == 0, "on again")
    Core.Set(ns.name, "unitTargetTarget", false)
    check(not watched[target.face.rowButton] and watched[target], "Your target's target off: no row, the frame stays")
    Core.Set(ns.name, "unitTargetTarget", true)
    units.pet = nil
    -- A druid: your frame keeps two power slots, mana always, a form's power under it.
    units.player.class, units.player.powerType, units.player.powerToken = "DRUID", 3, "ENERGY"
    units.player.power, units.player.powerMost, units.player.mana, units.player.manaMost = 80, 100, 2400, 3000
    ns.Units.Apply()
    check(player._height == Units.HEIGHT + 2 * Units.POWER and face.powersShown == 2
        and face.powers[1].value._text == "2.4k | 80%" and face.powers[2].value._text == "80 | 80%" and face.powers[2]._shown,
        "a druid in cat form: mana in the first bar, energy under it")
    units.player.powerType, units.player.powerToken, units.player.power, units.player.powerMost = 0, "MANA", 2400, 3000
    W.Fire("UNIT_DISPLAYPOWER", "player")
    check(face.powersShown == 1 and not face.powers[2]._shown and face.powers[1].value._text == "2.4k | 80%"
        and player._height == Units.HEIGHT + 2 * Units.POWER,
        "out of the form: the mana bar alone (the button keeps its size: it is changed out of a fight only)")
    units.player.class, units.player.powerType, units.player.powerToken = "WARRIOR", 1, "RAGE"
    units.player.power, units.player.powerMost, units.player.mana, units.player.manaMost = 30, 100, nil, nil
    ns.Units.Apply()
    check(player._height == Units.HEIGHT + Units.POWER and face.powers[1].value._text == "30 | 30%", "a warrior again: one bar")

    Core.Set(ns.name, "unitSize", 150)
    check(player._scale == 1.5 and target._scale == 1.5 and PlayerFrame._mouse == false, "Unit frame size: all three larger")
    Core.Set(ns.name, "unitSize", 100)
    -- In a fight secure frames are not changed: what is asked for waits for its end.
    W.combat = true
    Core.Set(ns.name, "unitTarget", false)
    check(watched[target] and TargetFrame._parent ~= UIParent, "switched off in a fight: nothing changes yet")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(not watched[target] and TargetFrame._parent == UIParent, "after the fight: ours hidden, the game's back")
    Core.Set(ns.name, "unitTarget", true)
    check(not ns.off, "and nothing failed")
end

-------------------------------------------------------------------------------
--  Auras on the frames: the game's containers, three of each kind; your lists
-------------------------------------------------------------------------------
do
    local target, player = unitButtons.target, unitButtons.player
    units.target = { name = "Kobold Miner", level = 22, health = 40, most = 120, foe = true, reaction = 2 }
    W.Fire("PLAYER_TARGET_CHANGED")
    local auras = target.face.auras
    local debuffs, buffs, control = auras.debuffs, auras.buffs, auras.control
    check(debuffs and buffs and control and debuffs._template == "CustomAuraContainerTemplate"
        and debuffs._groups.auto.options.maxFrameCount == 3 and buffs._groups.auto.options.maxFrameCount == 3
        and control._groups.auto.options.maxFrameCount == 3, "three containers of the game's, three auras of each kind")
    check(debuffs._groups.auto.filter == "HARMFUL|PLAYER|!CROWD_CONTROL" and buffs._groups.auto.filter == "HELPFUL|INCLUDE_NAME_PLATE_ONLY"
        and control._groups.auto.filter == "HARMFUL|CROWD_CONTROL" and debuffs._unit == "target",
        "on a foe: your debuffs, its buffs as the game shows them on plates, crowd control")
    check(debuffs._groups.auto.options.sortMethod == AuraContainerSortMethod.UnitFrameDebuff
        and buffs._groups.auto.options.sortMethod == AuraContainerSortMethod.BigDefensive,
        "the most important first: the game's unit frame order for debuffs, big defensives for buffs")
    local mine = player.face.auras
    check(mine.debuffs._groups.auto.filter == "HARMFUL|!CROWD_CONTROL" and mine.buffs._groups.auto.filter == "HELPFUL",
        "on you: any debuffs, any buffs")
    check(debuffs._points[1][1] == "BOTTOMLEFT" and debuffs._points[1][3] == "TOPLEFT" and buffs._points[1][3] == "TOPRIGHT"
        and control._points[1][3] == "TOPRIGHT" and control._points[1][1] == "TOPLEFT",
        "debuffs above from the left, buffs above from the right, crowd control right of the frame")
    check(not debuffs._groups.listed.enabled and debuffs._groups.auto.candidates == nil, "no lists yet: nothing filtered")
    -- A right click on an icon, out of a fight: the spell on a list.
    local icon = debuffs._groups.auto.icon
    icon._SetSpellName._text = "Sunder Armor"
    W.auras.target = { HARMFUL = { { name = "Rend", spellId = 772 }, { name = "Sunder Armor", spellId = 7386, icon = 132363 } } }
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    local menu = W.menus[1]
    check(menu and menu[1].title == "Sunder Armor" and menu[2].text == ns.TEXT.auraAlways and menu[3].text == ns.TEXT.auraNever
        and menu[4].text == ns.TEXT.auraLists, "its menu: Always show, Never show, Aura lists")
    menu[2].fn()
    check(ns.options.auraWhite[7386] == "Sunder Armor" and debuffs._groups.listed.enabled
        and debuffs._groups.listed.candidates.includeSpellIDs[7386] and debuffs._groups.auto.candidates.excludeSpellIDs[7386]
        and mine.buffs._groups.listed.candidates.includeSpellIDs[7386],
        "Always show: shown in front of the rest (the game includes it there and leaves it out of the rest)")
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    W.menus[1][3].fn()
    check(ns.options.auraBlack[7386] and not ns.options.auraWhite[7386] and not debuffs._groups.listed.enabled
        and control._groups.auto.candidates.excludeSpellIDs[7386], "Never show: off the other list, never shown")
    W.combat = true
    W.menus = {}
    icon._scripts.OnMouseUp(icon, "RightButton")
    check(W.menus[1][1].title == ns.TEXT.auraFight and W.menus[1][2].text == ns.TEXT.auraLists,
        "in a fight the game keeps the icons from addons: only the lists' window")
    W.combat = false
    -- The window: the lists side by side, a spell added by its number, taken off by its X.
    W.menus[1][2].fn()
    local lists = ns.AuraLists
    W.spells[1459] = { name = "Arcane Intellect" }
    local box
    for _, widget in ipairs(W.frames) do if widget._kind == "EditBox" and widget._template == "InputBoxTemplate" then box = widget end end
    box:SetText("1459")
    box._scripts.OnEnterPressed(box)
    check(ns.options.auraWhite[1459] == "Arcane Intellect" and mine.buffs._groups.listed.candidates.includeSpellIDs[1459],
        "typed by its number, Enter: on Always show")
    local line
    for _, widget in ipairs(W.frames) do
        if widget.entry and widget.entry.id == 1459 and widget._shown then line = widget end
    end
    check(line and line.name._text == "Arcane Intellect" and line.number._text == 1459, "listed with its name and number")
    box:SetText("Nonsense")
    box._scripts.OnEnterPressed(box)
    check(ns.options.auraWhite.Nonsense == nil, "a name the game does not know: nothing added")
    lists.Take("white", 1459)
    lists.Take("black", 7386)
    check(next(ns.options.auraWhite) == nil and next(ns.options.auraBlack) == nil and debuffs._groups.auto.candidates == nil,
        "taken off: no lists again")
    Core.Set(ns.name, "unitAuras", false)
    check(not debuffs._shown and debuffs._unit == "none", "Auras on the frames off: none")
    Core.Set(ns.name, "unitAuras", true)
    check(debuffs._shown and debuffs._unit == "target" and not ns.off, "on again")
    units.target = nil
end

-------------------------------------------------------------------------------
--  The action bars, clean: only the buttons that hold something, each its icon alone
-------------------------------------------------------------------------------
do
    local bar = MainActionBar
    local full, empty = bar.actionButtons[1], bar.actionButtons[2]
    local arrow = bar.ActionBarPageNumber.UpButton
    check(ns.ActionBars.Clean() and bar.BorderArt._alpha == 0 and bar.EndCaps._alpha == 0 and divider._alpha == 0,
        "the bar's frame, end caps and dividers out of sight")
    check(bar.ActionBarPageNumber._alpha == 1 and arrow._mouse == true,
        "its page number and arrows stay: which bar shows, and the clicks to change it")
    check(full.NormalTexture._alpha == 0 and full.SlotArt._alpha == 0 and full.SlotBackground._alpha == 0
        and full.Border._alpha == 0, "a button's frame, slot, background and border out of sight")
    check(not full.icon._masks[full.IconMask] and full.icon._coords[1] == ns.ActionBars.CROP[1]
        and full.cooldown._points[1][2] == full.icon and full.cooldown._points[1][4] == 0,
        "its icon square and cropped, the cooldown over all of it")
    check(full:GetHighlightTexture()._colour and full:GetHighlightTexture()._blend == "ADD"
        and full:GetPushedTexture()._colour, "the mouse over it and a press: a flat wash")
    check(full._alpha == 1 and empty._alpha == 0, "a button that holds something shows; an empty one does not")
    W.Fire("ACTIONBAR_SHOWGRID")
    local slot
    for _, widget in ipairs(W.frames) do
        if widget._parent == empty and widget._colour and widget._colour[4] == ns.ActionBars.SLOT[4] then slot = widget end
    end
    check(empty._alpha == 1 and slot and slot._shown, "while something is dragged, the empty one shows as a dark square")
    W.Fire("ACTIONBAR_HIDEGRID")
    check(empty._alpha == 0 and not slot._shown, "dropped: out of sight again")
    W.actions[2] = { kind = "spell", id = 78 }
    empty:Update()
    check(empty._alpha == 1, "given an action, it shows (after the game's own update)")
    W.actions[2] = nil
    empty:Update()
    Core.Set(ns.name, "cleanBars", false)
    check(not ns.ActionBars.Clean() and bar.BorderArt._alpha == 1 and arrow._mouse == true and divider._alpha == 1
        and full.NormalTexture._alpha == 1 and full.icon._masks[full.IconMask] and full.icon._coords[2] == 1
        and full:GetHighlightTexture()._texture == "highlight" and full.cooldown._points[1][4] == 3 and empty._alpha == 1,
        "Clean action bars off: everything as the game had it")
    Core.Set(ns.name, "cleanBars", true)
    check(ns.ActionBars.Clean() and full.NormalTexture._alpha == 0 and empty._alpha == 0, "on again: clean")
end

-------------------------------------------------------------------------------
--  A window of ours this game has not (Combat.lua, ns.Serves): it alone is not there
-------------------------------------------------------------------------------
do
    local configs, keyOf = C_SpecializationInfo.GetCombatConfigIDForSpecGroup, GetBindingKey
    C_SpecializationInfo.GetCombatConfigIDForSpecGroup = nil -- talents not of two specializations, as Retail's
    GetBindingKey = function(action) return ({ TOGGLESPELLBOOK = "P", TOGGLETALENTS = "N" })[action] end
    ns.Keys.Bind()
    check(not Board.Present("talents") and Board.Present("spellbook") and ns.Serves(),
        "without the talents ours are made after, our talents are not there; our spellbook is")
    check(W.overrides[owner].P == ns.Keys.COMMANDS.spellbook and W.overrides[owner].N == nil
        and ns.Keys.Taken("TOGGLESPELLBOOK") and not ns.Keys.Taken("TOGGLETALENTS"),
        "the talents key opens the game's talents; the spellbook's key ours")
    local entries = Core.Classic.List(handle)
    check(#entries == 1 and entries[1].window == "spellbook", "Classic windows: the game's spellbook, not its talents")
    local first, listed = layouts.options.default(), {}
    for _, spec in ipairs(layouts.options.windows()) do listed[spec.key] = true end
    check(first and first.key == "spellbook" and listed.spellbook and not listed.talents,
        "the first layout is the spellbook alone, and the dropdown Windows has no talents")
    W.Play("retail")
    ns.Keys.Bind()
    check(not ns.Serves() and W.overrides[owner] == nil and not ns.Keys.Taken() and Core.Classic.List(handle) == nil,
        "with neither (Retail): no key of the game's runs ours, and no Classic windows of Combat's")
    W.Play("forever")
    C_SpecializationInfo.GetCombatConfigIDForSpecGroup, GetBindingKey = configs, keyOf
    ns.Keys.Bind()
    check(Board.Present("talents") and W.overrides[owner].P == ns.Keys.COMMANDS.spellbook, "back in Forever: both ours again")
end

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
ns.Window.Reboard()
W.Wait(0)
check(Core.Lent(planner), "seated before the module fails")
-- A step of the giving back fails (here the board's own): the others give back all the same, the keys first.
Board.layouts.Hide = function() error("the board failed") end
ns.StandDown("a test")
check(ns.off and not Core.Lent(planner) and not frame:IsShown(),
    "standing down, all is given back and the window goes, though a step of it failed")
check(W.overrides[owner] == nil, "and the game's keys open the game's windows again")
check(unitButtons.player._alpha == 0 and not unitButtons.player._shown and not watched[unitButtons.target]
    and PlayerFrame._mouse == true and PlayerFrame.PlayerFrameContent._alpha == 1 and FocusFrame._parent == UIParent,
    "our unit frames gone, the game's back")
check(not ns.ActionBars.Clean() and MainActionBar.BorderArt._alpha == 1 and MainActionBar.actionButtons[2]._alpha == 1,
    "the action bars as the game has them")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
check(not questMark._shown, "a plate the game shows after it gets no quest mark")

-- As Retail loads the module: this file once more, in a client of its own.
check(os.execute(("lua5.1 '%s/dev/tests/combat.lua' retail"):format(root)) == 0, "in Retail the module loads and runs as that game has it")

io.write(("Combat: all %d checks passed.\n"):format(passed))
