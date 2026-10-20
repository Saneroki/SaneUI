-- Runs the Combat module against the stand-in client (wowstub.lua): its window docked at the bottom middle, the
-- middle half of the bottom edge filling the screen, its windows there on Core's board (our own talents and
-- spellbook side by side, each as wide as its share of the game's sizes), a planner Sane UI knows as a window of
-- its own (listed only while it is there, seated in its panel, opened and closed with it), the quest marks beside
-- nameplates, and giving everything back. Our spellbook itself is tried in dev/tests/book.lua, our talents in
-- dev/tests/talents.lua. The look can only be judged in the game.
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

-- The game's override bindings (Keys.lua): kept per owner, to look at.
W.overrides = {}
ClearOverrideBindings = function(owner) W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end

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
ns.Window.Reboard()
W.Wait(0)
check(Core.Lent(planner), "seated before the module fails")
ns.StandDown("a test")
check(ns.off and not Core.Lent(planner) and not frame:IsShown(),
    "standing down, all is given back and the window goes")
check(W.overrides[owner] == nil, "and the game's keys open the game's windows again")

io.write(("Combat: all %d checks passed.\n"):format(passed))
