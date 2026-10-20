-- Runs the Inventory module against the stand-in client (wowstub.lua): its window docked in the bottom right
-- corner, the corner's square filling the screen, the module's windows on Core's board (parts that register
-- themselves), and giving everything back. The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/inventory.lua

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
--  What the module needs of the client (as dev/tests/combat.lua)
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

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Inventory", "SaneUI_Inventory")
W.Fire("ADDON_LOADED", "SaneUI_Inventory")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")
local Board, Edge = ns.Board, Core.Edge

-------------------------------------------------------------------------------
--  The window, docked in the bottom right corner
-------------------------------------------------------------------------------
local handle = ns.Window.handle
local frame = handle.frame
check(handle.zone == "BOTTOMRIGHT" and frame._width == ns.Window.WIDTH and not frame._mouse,
    "its window is docked in the bottom right corner at first, and takes no click while small")
frame._left, frame._bottom = 1920 - ns.Window.WIDTH, 0
local square = handle.edge.strips.corner
check(square and square:IsShown() and square._points[1][1] == "BOTTOMRIGHT" and near(square._width, 4 * 768 / 2160)
    and square._strata == "DIALOG", "the corner's square, four of the screen's pixels, fills the screen")
for _, side in ipairs({ "left", "right", "top", "bottom" }) do
    check(not (handle.edge.strips[side] and handle.edge.strips[side]:IsShown()), "no strip along a side: only the corner (" .. side .. ")")
end

-------------------------------------------------------------------------------
--  The full screen: the parts there are, on Core's board
-------------------------------------------------------------------------------
-- A part as a part's file registers it: what the board asks of it is noted.
local function Part(key, least)
    local part = { built = 0, shown = nil, size = nil, searched = nil }
    function part.Build(panel) part.built, part.panel = part.built + 1, panel end
    function part.Show(on) part.shown = on end
    function part.Size(width, height) part.size = { width, height } end
    function part.Search(text) part.searched = text end
    Board.Part(key, key:upper(), least, part)
    return part
end
local sheet = Part("character", { 600, 400 })

local function Push()
    W.Wait(1) -- a while after the square came under the mouse
    square:GetScript("OnEnter")(square)
    W.cursorX, W.cursorY = 960, 500 -- the mouse goes away again: the next push counts
    W.Wait(Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end
W.cursorX, W.cursorY = 1920, 0
Push()
check(handle.edge.full, "the mouse pushed into the corner fills the screen")
Stand()
check(sheet.built == 1 and sheet.shown == true and sheet.panel and sheet.panel:IsShown() and sheet.size,
    "standing full, the one part there is fills the board: built, shown, told its size")
check(Board.layouts:Has("character"), "the first layout holds it")

-- A second part comes: side by side, the first as wide as it asks.
local bags = Part("bags", { 500, 300 })
ns.Window.Reboard()
check(bags.built == 1 and bags.shown == true and Board.layouts:Has("bags"), "a part that registers later is laid out too")
local rects = Board.layouts.rects
check(rects.character and rects.bags and rects.character[1] < rects.bags[1] and rects.character[3] == 600,
    "side by side, in the board's order, the first as wide as its least width")

-- The search box: every part hears it.
Board.Search("linen")
check(sheet.searched == "linen" and bags.searched == "linen", "what is typed into the search box goes to every part")

-- Pushed again: back, every panel hidden.
Push()
check(not handle.edge.full and sheet.shown == false and bags.shown == false, "pushed again: back, the windows go at once")
Stand()

-- A part that fails is noted; the others and the module go on.
local broken = { Build = function() error("a broken part") end }
Board.Part("alts", "ALTS", { 300, 200 }, broken)
W.caught = {}
Push()
Stand()
check(not ns.off and handle.edge.full and bags.shown == true, "a part that fails to build: the others are there, the module goes on")
W.caught = nil
Push()
Stand()

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
Push()
Stand()
ns.StandDown("a test")
check(ns.off and not frame:IsShown() and not handle.edge.full and sheet.shown == false,
    "standing down: the windows go and the window with them")

io.write(("Inventory: all %d checks passed.\n"):format(passed))
