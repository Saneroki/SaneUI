-- Runs the Combat module against the stand-in client (wowstub.lua): its window docked at the bottom middle, the
-- middle half of the bottom edge filling the screen, the panels there (talents, spellbook) with the game's own
-- window seated in the one of the tab it shows, a planner Sane UI knows as the Talents panel, the open buttons
-- (a secure click on the game's micro menu button), fights, and giving everything back. Core's Seat and its
-- strip of a share of the screen's side are tried here too. The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/combat.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
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

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Board, Edge = ns.Board, Core.Edge

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

-- Board.Layout: side by side, each as wide as its share of what both want
local rects = Board.Layout(0, 1048, 1920, 1048, { talents = Board.TALENTS, spellbook = Board.SPELLBOOK })
local free = 1920 - 2 * Board.MARGIN - Board.GAP
local talentsWidth = math.floor(free * Board.TALENTS[1] / (Board.TALENTS[1] + Board.SPELLBOOK[1]) + 0.5)
check(rects.talents[1] == Board.MARGIN and rects.talents[2] == 1048 - Board.MARGIN and rects.talents[3] == talentsWidth
    and rects.spellbook[1] == Board.MARGIN + talentsWidth + Board.GAP and rects.spellbook[3] == free - talentsWidth
    and rects.talents[4] == 1048 - 2 * Board.MARGIN, "the talents at the left, the spellbook at the right, the wider the more it wants")

-------------------------------------------------------------------------------
--  The full screen, nothing open
-------------------------------------------------------------------------------
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
Push()
check(handle.edge.full, "the mouse pushed against the middle of the bottom edge fills the screen")
local talentsPlate, bookPlate
for _, widget in ipairs(W.frames) do
    if widget.skin and widget.title and widget.title._text == ns.TEXT.talents then talentsPlate = widget end
    if widget.skin and widget.title and widget.title._text == ns.TEXT.spellbook then bookPlate = widget end
end
check(talentsPlate and bookPlate and talentsPlate:IsShown() and bookPlate:IsShown(), "both panels are there, empty: the game's window is closed")
local talentsButton, bookButton
for _, widget in ipairs(W.frames) do
    local clicks = widget._attributes and widget._attributes.clickbutton
    if clicks == TalentMicroButton then talentsButton = widget end
    if clicks == SpellbookMicroButton then bookButton = widget end
end
check(talentsButton and bookButton and not bookButton:IsShown(), "each has its open button, out of sight while the window is on its way")
Stand()
check(bookButton:IsShown() and bookButton._parent == UIParent and bookButton._strata == "DIALOG"
    and bookButton._attributes.type == "click" and bookButton._attributes.useOnKeyDown == false
    and bookButton._points[1][2] == UIParent, "standing, the open button shows: a secure click on the game's micro menu button, on UIParent above the window")
check(bookPlate.hint._text == ns.TEXT.hint:format("P") and talentsPlate.hint._text == ns.TEXT.hint:format(ns.TEXT.noKey),
    "each panel says what opens it: the game's key, or where to set one")

-------------------------------------------------------------------------------
--  The game's window seated
-------------------------------------------------------------------------------
-- The game's talents and spellbook, one window, loaded when first wanted; the spellbook tab shown.
local game = W.NewWidget("Frame", "PlayerSpellsFrame", UIParent)
game:Hide()
game:SetSize(809, 720)
game._strata, game._level = "MEDIUM", 5000
game.SpecFrame = W.NewWidget("Frame", nil, game)
game.TalentsFrame = W.NewWidget("Frame", nil, game)
game.SpellBookFrame = W.NewWidget("Frame", nil, game)
game.SpecFrame:Hide()
game.TalentsFrame:Hide()
local function Placed(at) game:ClearAllPoints() game:SetPoint("TOP", UIParent, "TOP", 0, at or -41) end
Placed()
PlayerSpellsFrame = game
W.loaded.Blizzard_PlayerSpells = true
waiting.Blizzard_PlayerSpells()
check(not Core.Lent(game), "nothing of the game's window is lent before it opens")

game:Show() -- the open button clicked the game's micro menu button: the game opens its window
W.Wait(0)
local room = Board.Layout(0, 1080 - Core.Window.BAR, 1920, 1080 - Core.Window.BAR, { talents = Board.TALENTS, spellbook = { 809, 720 } }).spellbook
local scale = math.min(room[3] / 809, room[4] / 720, 1)
local point = game._points[1]
check(Core.Lent(game) and near(game._scale, scale) and #game._points == 1 and point[1] == "TOPLEFT" and point[2] == UIParent
    and near(point[4] * scale, room[1] + (room[3] - 809 * scale) / 2) and near(point[5] * scale, room[2] - (room[4] - 720 * scale) / 2),
    "the game's window showing the spellbook stands in the Spellbook panel, as large as fits, in its middle")
check(game._parent == UIParent and game._strata == "HIGH" and game._level == 5000,
    "its parent stays its own; it stands over the full window, at its own level, which is above already")
check(not bookPlate:IsShown() and not bookButton:IsShown() and talentsPlate:IsShown() and talentsButton:IsShown(),
    "its plate and open button go; the Talents panel stays empty")

Placed(-80) -- the game places it anew (its panels make room for each other)
check(game._points[1][1] == "TOPLEFT" and near(game._points[1][4] * scale, room[1] + (room[3] - 809 * scale) / 2), "the game placing it anew: back in its panel")
game:SetScale(0.7) -- the game scales it to fit the screen
check(near(game._scale, scale), "the game scaling it anew: ours again")

-- Another tab: the talents, another size, the other panel.
game.SpellBookFrame:Hide()
game:SetSize(1218, 708)
game.TalentsFrame:Show()
W.Wait(0)
local talentsRoom = Board.Layout(0, 1048, 1920, 1048, { talents = { 1218, 708 }, spellbook = Board.SPELLBOOK }).talents
local talentsScale = math.min(talentsRoom[3] / 1218, talentsRoom[4] / 708, 1)
check(near(game._scale, talentsScale) and near(game._points[1][4] * talentsScale, talentsRoom[1] + (talentsRoom[3] - 1218 * talentsScale) / 2)
    and bookPlate:IsShown() and not talentsPlate:IsShown(), "showing your talents, it stands in the Talents panel; the Spellbook panel is empty again")

-- Closed by the game (its close button, its key): given back.
game:Hide()
W.Wait(0)
check(not Core.Lent(game) and game._scale == 1 and game._points[1][1] == "TOP" and game._points[1][5] == -41
    and game._strata == "MEDIUM" and game._level == 5000 and talentsPlate:IsShown(),
    "closed, it is given back exactly as it was lent: its place, scale and layer; its panel is empty again")

-------------------------------------------------------------------------------
--  Going back, and opened by the game while small
-------------------------------------------------------------------------------
game.TalentsFrame:Hide()
game.SpellBookFrame:Show()
game:SetSize(809, 720)
game:Show()
W.Wait(0)
check(Core.Lent(game), "opened again while the screen is full: seated again")
Push()
check(not handle.edge.full and not Core.Lent(game) and game:IsShown() and game._points[1][1] == "TOP",
    "the bottom edge again: the window goes back, the game's window stays open at its own place")
check(not talentsPlate:IsShown() and not bookPlate:IsShown() and not talentsButton:IsShown(), "the panels and the open buttons go with the full screen")
frame._group:Run(1)
handle:Place()
frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0
game:Hide()
game:Show() -- its key, while the window is small
W.Wait(0)
check(handle.edge.full and Core.Lent(game), "the game's window opened by its key fills the screen too, and stands in its panel")

-- A fight: the open buttons go as it begins, and come back after it.
game:Hide()
Stand()
check(bookButton:IsShown(), "standing, the empty panel's open button is there")
W.Fire("PLAYER_REGEN_DISABLED")
W.combat = true
W.Wait(0)
check(not bookButton:IsShown() and not talentsButton:IsShown() and bookPlate.hint._text == ns.TEXT.hintFight:format("P"),
    "a fight begins: the open buttons go at once, the panel says what opens it meanwhile")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(bookButton:IsShown() and bookPlate.hint._text == ns.TEXT.hint:format("P"), "the fight is over: they are back")
Push()
check(not handle.edge.full, "back to its size")
frame._group:Run(1)
handle:Place()
frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0

-------------------------------------------------------------------------------
--  A talent planner Sane UI knows
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

Push()
check(handle.edge.full and opens == 1 and planner and planner:IsShown(), "the full screen comes: the planner opens with it")
Stand()
local plannerRoom = Board.Layout(0, 1048, 1920, 1048, { talents = { 1000, 640 }, spellbook = Board.SPELLBOOK }).talents
local plannerScale = math.min(plannerRoom[3] / 1000, plannerRoom[4] / 640, 1)
check(Core.Lent(planner) and near(planner._scale, plannerScale) and planner._points[1][1] == "TOPLEFT"
    and planner._level == 500 + Board.LEVEL and not talentsPlate:IsShown() and not talentsButton:IsShown(),
    "it stands in the Talents panel, raised over the full window")

-- The game's window, on its talents tab: the Spellbook panel, since the planner holds the Talents panel.
game.SpellBookFrame:Hide()
game.TalentsFrame:Show()
game:SetSize(1218, 708)
game:Show()
W.Wait(0)
check(Core.Lent(game) and Core.Lent(planner) and not bookPlate:IsShown(),
    "the game's window, whatever it shows, takes the Spellbook panel while the planner holds the Talents panel")
game:Hide()
W.Wait(0)

-- Closed by its own close button: its plate, with our open button (its own function opens it again).
planner:Hide()
W.Wait(0)
check(not Core.Lent(planner) and talentsPlate:IsShown() and talentsPlate.hint._text == ns.TEXT.hintPlanner
    and talentsPlate.open and talentsPlate.open:IsShown() and not talentsButton:IsShown(),
    "closed, the Talents panel offers to open it again, by our own button")
talentsPlate.open:GetScript("OnClick")(talentsPlate.open)
W.Wait(0)
check(opens == 2 and planner:IsShown() and Core.Lent(planner) and not talentsPlate:IsShown(), "opened again, it is back in its panel")

Push()
check(not handle.edge.full and closes >= 1 and not planner:IsShown() and not Core.Lent(planner),
    "the window goes back: the planner is given back and closes")
frame._group:Run(1)
handle:Place()
frame._left, frame._bottom = (1920 - ns.Window.WIDTH) / 2, 0

_G[known.api].UI[known.open]() -- opened by its own command while the window is small
W.Wait(0)
check(handle.edge.full and Core.Lent(planner), "opened any way of its own, the full screen comes with it")

-------------------------------------------------------------------------------
--  A protected window in a fight is left as it is
-------------------------------------------------------------------------------
planner:Hide()
W.Wait(0)
game._protected, W.combat = true, true
game:Show()
W.Wait(0)
check(not Core.Lent(game), "a protected game's window is not seated in a fight")
game:Hide()
game._protected, W.combat = false, false
W.Wait(0)

-------------------------------------------------------------------------------
--  Quest marks beside nameplates: as the game says it in the creature's tooltip data
-------------------------------------------------------------------------------
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
    Core.Set(ns.name, "questMarks", true)
    check(kobold._shown, "on again: there")
end

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
game:Show()
W.Wait(0)
check(Core.Lent(game), "seated before the module fails")
ns.StandDown("a test")
check(ns.off and not Core.Lent(game) and game:IsShown() and not frame:IsShown() and not bookButton:IsShown(),
    "standing down, all is given back and the window goes; the game's window stays as the game has it")
local before = Core.Lent(game)
game:Hide()
game:Show()
W.Wait(0)
check(not Core.Lent(game) and not before, "after that, the game's window opening seats nothing")

io.write(("Combat: all %d checks passed.\n"):format(passed))
