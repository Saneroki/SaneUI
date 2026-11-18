-- Runs what Core gives every window (Dock, Shape, Skin, Window, Expand, Edge, Bar and the window to try them with)
-- against the stand-in client (wowstub.lua): a screen of 1920 x 1080 and frames that know their place.
-- Usage, from the project folder:  lua5.1 dev/tests/window.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-- A frame's place is its lower left corner; the test puts it there as the mouse would.
local methods = W.methods
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetRight() return self._left and self._left + self._width end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetResizeBounds(...) self._bounds = { ... } end
function methods:SetTexCoord(...) self._coords = { ... } end
function methods:StartMoving() self._moving = true end
function methods:StartSizing(corner) self._sizing = corner end
function methods:StopMovingOrSizing() self._moving, self._sizing = nil, nil end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata end
function methods:SetClampedToScreen(clamped) self._clamped = clamped end
function methods:EnableMouse(on) self._mouse, self._motion = on, on end
function methods:SetMouseClickEnabled(on) self._mouse = on end
function methods:SetMouseMotionEnabled(on) self._motion = on end
function methods:IsMouseClickEnabled() return self._mouse or false end
function methods:IsMouseMotionEnabled() return self._motion or false end
function methods:EnableMouseWheel(on) self._wheel = on end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:IsMouseWheelEnabled() return self._wheel or false end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:Raise() self._level = 500 end -- above the others of its layer
function methods:SetColorTexture(r, g, b, a) self._texture = { r, g, b, a } end
function methods:SetTexture(texture, wrap) self._texture, self._wrap = texture, wrap return true end -- found
function methods:SetHorizTile(on) self._tiled = on end
function methods:SetVertexColor(r, g, b, a) self._vertex, self._gradient = { r, g, b, a }, nil end
function methods:SetGradient(orientation, low, high) self._gradient = { orientation, low, high } end
function methods:SetBlendMode(mode) self._blend = mode end
function methods:OverrideText(text) self._override = text end
function methods:SetUserPlaced(placed) self._userPlaced = placed end
function methods:SetToplevel(on) self._toplevel = on end
function methods:GetName() return self._name end
function methods:SetText(text) -- an edit box tells of its new text, as the game's does
    self._text = text
    if self._kind == "EditBox" and self._scripts.OnTextChanged then self._scripts.OnTextChanged(self, false) end
end
function methods:SetFocus() self._focus = true end
function methods:ClearFocus()
    if not self._focus then return end -- (the game tells of a lost focus only when there was one)
    self._focus = false
    if self._scripts.OnEditFocusLost then self._scripts.OnEditFocusLost(self) end
end
-- Blizzard's maximize and minimize button: a callback for each, and the state it shows.
W.templates.MaximizeMinimizeButtonFrameTemplate = function(widget)
    function widget:SetOnMaximizedCallback(fn) self.maximized = fn end
    function widget:SetOnMinimizedCallback(fn) self.minimized = fn end
    function widget:Maximize(_, skip)
        if not skip then self.maximized(self) end
        self.isMinimized = false
    end
    function widget:Minimize(_, skip)
        if not skip then self:minimized() end
        self.isMinimized = true
    end
end
-- Blizzard's tab system (TabSystemTemplate): a tab button for each AddTab; a click asks the callback, which
-- may show the choice itself (true).
W.templates.TabSystemTemplate = function(widget)
    widget.tabs = {}
    function widget:SetTabSelectedCallback(fn) self.callback = fn end
    function widget:SetTabVisuallySelected(id) self.selected = id end
    function widget:AddTab(text)
        local tab = CreateFrame("Button", nil, self)
        tab._text = text
        self.tabs[#self.tabs + 1] = tab
        local id = #self.tabs
        tab:SetScript("OnClick", function() if not self.callback(id, true) then self:SetTabVisuallySelected(id) end end)
        return id
    end
end
-- Blizzard's nine-slice: a texture per piece the layout names, in the kit's atlases.
NineSliceUtil = { ApplyLayout = function(container, layout, kit)
    for name in pairs(layout) do
        local piece = rawget(container, name) or container:CreateTexture()
        piece._atlas = kit
        rawset(container, name, piece)
    end
end }
function methods:AddMaskTexture(mask) self._masks = self._masks or {} self._masks[#self._masks + 1] = mask end
-- An animation: the test moves its clock. A frame's first group is its _group, all of them its _groups.
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, progress = 0, plays = 0, moves = {} }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing, self.progress, self.plays = true, 0, self.plays + 1 end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    group.SetToFinalAlpha = noop
    function group:CreateAnimation(kind)
        local animation = setmetatable({ kind = kind, SetSmoothing = noop, SetToAlpha = noop }, { __index = function() return noop end })
        function animation:SetDuration(seconds) group.duration, self.duration = seconds, seconds end
        function animation:GetProgress() return group.progress end
        function animation:SetOffset(_, y) self.y = y end
        function animation:SetFromAlpha(alpha) self.from = alpha end
        function animation:GetSmoothProgress() return self.progress or 0 end
        group.moves[#group.moves + 1] = animation
        return animation
    end
    function group:Run(progress)
        self.progress = progress
        if progress < 1 then return self.scripts.OnUpdate() end
        self.playing = false
        self.scripts.OnFinished()
    end
    self._group = self._group or group
    self._groups = self._groups or {}
    self._groups[#self._groups + 1] = group
    return group
end
CreateColor = function(r, g, b, a) return { r, g, b, a } end
IsMouseButtonDown = function() return W.held or false end
GetCursorPosition = function() return W.cursorX or 0, W.cursorY or 0 end
-- A status bar of the game's: its picture and its value.
function methods:SetStatusBarTexture(asset) self._bar = asset end
function methods:SetMinMaxValues(low, high) self._min, self._max = low, high end
function methods:SetValue(value) self._value = value end
function methods:GetValue() return self._value end
-- The game's easing curves (Blizzard_SharedXML's EasingUtil), those Motion.lua names.
EasingUtil = {
    OutQuartic = function(p) return 1 - (1 - p) ^ 4 end,
    InOutCubic = function(p) if p < 0.5 then return (p * 2) ^ 3 / 2 end return 1 - ((1 - p) * 2) ^ 3 / 2 end,
    OutBack = function(p) return 1 + 2.70158 * (p - 1) ^ 3 + 1.70158 * (p - 1) ^ 2 end,
}
UIParent._width, UIParent._height = 1920, 1080
local function at(frame, left, bottom) frame._left, frame._bottom = left, bottom end
local function near(a, b) return math.abs(a - b) < 1e-9 end
-- A plate's four corners' radii (Shape.lua): top left, top right, bottom left, bottom right.
local function round(shape, tl, tr, bl, br)
    local radii = shape.radii
    return near(radii[1], tl) and near(radii[2], tr) and near(radii[3], bl) and near(radii[4], br)
end
-- Whether the frame hangs by that point at x, y from the screen's lower left corner (on whichever
-- of the screen's points: a docked one hangs on the screen's point of its zone).
local function stands(frame, point, x, y)
    local is = frame._points[1]
    if not (#frame._points == 1 and is[1] == point and is[2] == UIParent) then return false end
    local at = is[3]
    local right = at:find("LEFT") and 0 or at:find("RIGHT") and 1 or 0.5
    local up = at:find("BOTTOM") and 0 or at:find("TOP") and 1 or 0.5
    return right * UIParent._width + is[4] == x and up * UIParent._height + is[5] == y
end

W.LoadCore(root)
-- Where the demo window's place is kept: in the profile in use; an empty one is none.
function W.DemoPlace()
    local place = SaneUI.Core.general.places["Core:demo"]
    return place and next(place) and place or nil
end
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local Dock, Window, Expand, Edge, Shape, Bar = Core.Dock, Core.Window, Core.Expand, Core.Edge, Core.Shape, Core.Bar
-- The section's switches with Hotcorner requires leftclick off: the mouse pushed against the edge is enough. Most
-- windows here are tried that way (edge = W.HOVER: the main chunk is at Lua's 200 locals); every module's is on at first
-- (Saneroki, 2026-11-16), tried below.
W.HOVER = {}
for key, value in pairs(Edge.DEFAULTS) do W.HOVER[key] = value end
W.HOVER.expandClick = false

-- The zones --------------------------------------------------------------------------------------
local count, top, bottom, corners = 0, 0, 0, 0
for _, zone in pairs(Dock.ZONES) do
    count = count + 1
    if zone.top then top = top + 1 end
    if zone.bottom then bottom = bottom + 1 end
    if (zone.left or zone.right) and (zone.top or zone.bottom) then corners = corners + 1 end
end
check(count == 9 and corners == 4 and top == 3 and bottom == 3, "a zone in each corner, one in the middle of each edge, one in the middle of the screen")
local middle = Dock.ZONES.CENTER
check(middle[1] == "CENTER" and not (middle.left or middle.right or middle.top or middle.bottom),
    "the middle of the screen touches no screen edge")
check(Dock.Find(770, 400, 400, 300, 1920, 1080) == "CENTER" and Dock.Find(760, 390, 400, 300, 1920, 1080) == "CENTER"
    and Dock.Find(500, 400, 400, 300, 1920, 1080) == nil, "a window let go with its middle near the screen's docks in the middle")
local x, y = Dock.Rect("CENTER", 400, 300, 1920, 1080)
check(x == 760 and y == 390, "docked in the middle it stands centred")
check(Dock.ZONES.LEFT.left and not Dock.ZONES.LEFT.top and not Dock.ZONES.LEFT.right and Dock.ZONES.TOP.top and not Dock.ZONES.TOP.left,
    "a zone knows the screen edges a window touches there")
check(Dock.Find(10, 770, 400, 300, 1920, 1080) == "TOPLEFT", "a window let go near a corner docks to it")
check(Dock.Find(1500, 20, 400, 300, 1920, 1080) == "BOTTOMRIGHT", "its own corner counts, not its place: the lower right one")
check(Dock.Find(770, 775, 400, 300, 1920, 1080) == "TOP" and Dock.Find(770, 5, 400, 300, 1920, 1080) == "BOTTOM", "at the middle of the top and of the bottom edge, by the middle of its own edge")
check(Dock.Find(290, 5, 400, 300, 1920, 1080) == nil and Dock.Find(1230, 780, 400, 300, 1920, 1080) == nil, "not at a quarter of an edge any more")
check(Dock.Find(0, 400, 400, 300, 1920, 1080) == "LEFT" and Dock.Find(1510, 380, 400, 300, 1920, 1080) == "RIGHT", "at the middle of the left and of the right edge")
check(Dock.Find(400, 400, 400, 300, 1920, 1080) == nil and Dock.Find(200, 780, 400, 300, 1920, 1080) == nil, "and nowhere else: not in the open, not somewhere along an edge")
check(Dock.Find(Dock.REACH + 1, 780, 400, 300, 1920, 1080) == nil and Dock.Find(Dock.REACH, 780, 400, 300, 1920, 1080) == "TOPLEFT", "a zone reaches so far and no further")

-- A window of our own ------------------------------------------------------------------------------
local store, docked = {}, "never"
local frame = CreateFrame("Frame", nil, UIParent)
frame:SetFrameLevel(3)
local usable = true
local window = Window.New(frame, {
    store = store, title = "Test window", sizable = true, dock = true, skin = "round",
    first = { point = "LEFT", x = 40, y = 0, width = 380, height = 260 }, minWidth = 180, minHeight = 130,
    usable = function() return usable end,
    docked = function(zone) docked = zone end,
})
check(#frame._points == 0, "a new window is not placed before it is built")
window:Place()
local first = frame._points[1]
check(frame._width == 380 and frame._height == 260 and first[1] == "LEFT" and first[3] == "LEFT" and first[4] == 40, "placed, it is at its first place and size")
check(window.zone == nil and docked == nil and window.grip.corner == "BOTTOMRIGHT", "free, with its grip in the lower right corner")
local skin = window.skin
check(skin._parent == frame and skin._points[1][4] == 0 and skin._points[2][4] == 0, "its skin is as large as the window")
check(skin:GetFrameLevel() == frame:GetFrameLevel() - 1, "and one level under it: the window's own texts and textures are drawn over the fill")
local plate = skin.shape
check(#plate.fills == 9 and #plate.trims == 8 and plate.fills[6]._masks[1] == plate.circles[1] and plate.fills[1]._masks == nil
    and plate.trims[5]._masks[1] == plate.circles[1] and plate.trims[5]._masks[2] == plate.holes[1] and not plate.square,
    "its plate: five strips and four corners, each corner cut by a circle; the trim's arcs by the circle and a hole")
check(plate.circles[1]._texture == Shape.CIRCLE and plate.circles[1]._wrap == "CLAMPTOBLACKADDITIVE" and plate.holes[1]._wrap == "CLAMPTOWHITE",
    "outside the circle nothing is seen, outside the hole all is")

-- Moved and sized only in Blizzard's Edit Mode
check(not window.grip:IsShown() and window.box == nil and frame._scripts.OnDragStart == nil and not frame._mouse,
    "outside Edit Mode it has no grip and nothing to drag it by, and takes no click: it stays where it is")
EventRegistry:TriggerEvent("EditMode.Enter")
local bar = window.box -- what it is dragged by in Edit Mode
check(Core.EditMode.active and bar and bar:IsShown() and bar._parent == frame and bar._level == frame:GetFrameLevel() + Window.BOX_LEVEL
    and bar.Center._atlas == "editmode-actionbar-highlight" and bar.TopLeftCorner and window.grip:IsShown() and window.grip._level > bar._level,
    "Blizzard's Edit Mode opens: a box in Edit Mode's look lies over the window, its grip over the box")
local hover, title
for _, widget in ipairs(W.frames) do
    if widget._parent == bar and widget._kind == "Frame" then hover = widget end
    if widget._parent == bar and widget._kind == "FontString" then title = widget end
end
check(not hover:IsShown() and not title:IsShown() and title._text == "Test window", "the window's title waits for the mouse")
check(bar.Center._alpha == 0 and bar.TopLeftCorner._alpha == 0 and bar.RightEdge._alpha == 0 and bar:IsShown(),
    "its blue frame out of sight until the mouse is on it: the window as it looks, the box still there to take the mouse")
bar:GetScript("OnEnter")(bar)
check(hover:IsShown() and title:IsShown() and hover._alpha == 0.4 and bar.Center._alpha == 1 and bar.TopLeftCorner._alpha == 1,
    "with the mouse on the box its blue frame, brighter, with the window's title")
bar:GetScript("OnLeave")(bar)
check(not hover:IsShown() and not title:IsShown() and bar.Center._alpha == 0, "and out of sight when the mouse has left")

-- Dragged about
local ghost, watcher
for _, widget in ipairs(W.frames) do if widget._strata == nil and widget._scripts.OnUpdate then watcher = widget end end
check(watcher == nil, "nothing looks at the mouse before a window is dragged")
at(frame, 600, 400)
bar:GetScript("OnDragStart")(bar)
-- Dock's (the guide lines' watch, Arrange.lua, stands in the layer HIGH)
for _, widget in ipairs(W.frames) do if widget._scripts.OnUpdate and widget._strata == nil then watcher = widget end end
for index, widget in ipairs(W.frames) do if widget == watcher then ghost = W.frames[index - 2] end end
check(frame._moving and watcher:IsShown() and not ghost:IsShown(), "dragged by its box it moves, and its place is watched")
at(frame, 20, 800)
watcher:GetScript("OnUpdate")(watcher)
check(ghost:IsShown() and ghost._width == 380 and stands(ghost, "TOPLEFT", 0, 1080), "near a zone a shape shows where it would dock")
at(frame, 600, 400)
watcher:GetScript("OnUpdate")(watcher)
check(not ghost:IsShown(), "away from it the shape goes")
bar:GetScript("OnDragStop")(bar)
check(not frame._moving and not watcher:IsShown(), "let go, nothing is watched any more")
check(store.place.x == 600 and store.place.y == 660 and store.place.width == 380 and store.place.dock == nil and stands(frame, "TOPLEFT", 600, 660),
    "let go in the open it stays there, and that is kept")
check(round(plate, 13, 13, 13, 13) and plate.fills[3]._points[1][4] == 0 and plate.fills[3]._points[1][5] == 13 and plate.fills[3]._height == 234,
    "free, all its corners are round: a tenth of half its shorter side at first; the middle strip leaves them out")
local tl = plate.circles[1]._points[1]
check(tl[1] == "CENTER" and tl[3] == "BOTTOMLEFT" and near(tl[4], 13) and near(tl[5], 247) and near(plate.circles[1]._width, 26)
    and near(plate.holes[1]._width, 22) and near(plate.fills[6]._width, 13),
    "a corner's circle is centred on its arc's centre, twice the radius wide; the hole the trim's width smaller")
local middle = plate.fills[3]
check(middle._texture == Core.Skin.TILE.file and middle._wrap == "REPEAT" and near(middle._coords[1], 0) and near(middle._coords[2], 380 / 32)
    and near(middle._coords[3], 13 / 32) and near(middle._coords[4], 247 / 32) and plate.trims[1]._vertex[1] == Core.GOLD[1],
    "the fill is the tile of the game's dark dialogs, each piece showing the tile where it lies so the pieces meet without a seam; the trim SaneUI's")

-- Docked
bar:GetScript("OnDragStart")(bar)
at(frame, 1530, 12)
bar:GetScript("OnDragStop")(bar)
check(store.place.dock == "BOTTOMRIGHT" and window.zone == "BOTTOMRIGHT" and docked == Dock.ZONES.BOTTOMRIGHT, "let go near a corner it docks there, and that is kept")
check(stands(frame, "BOTTOMRIGHT", 1920, 0), "it hangs on the corner, not on a place of its own")
check(frame._points[1][3] == "BOTTOMRIGHT" and frame._points[1][4] == 0 and frame._points[1][5] == 0,
    "on the screen's own corner: it stays there when the game window's size or the UI scale changes")
at(frame, 1540, 0)
skin:Fit()
local trims = plate.trims
check(round(plate, 13, 0, 0, 0) and trims[2]._points[1][4] == 380 and trims[3]._points[1][5] == -2 and trims[1]._points[1][4] == 0,
    "docked, its corners on the screen's edges are square, and the trim of the sides there is out of the screen")
check(window.grip.corner == "TOPLEFT" and window.grip._points[1][1] == "TOPLEFT" and window.grip._Normal._coords[1] == 1 and window.grip._Normal._coords[3] == 1,
    "and its grip is in the corner away from the screen's, its art mirrored")
at(frame, 1540, 0)
window.grip:GetScript("OnMouseDown")(window.grip)
check(frame._sizing == "TOPLEFT" and stands(frame, "BOTTOMRIGHT", 1920, 0) and frame._bounds[1] == 180 and frame._bounds[3] == 1920,
    "sized by it, the corner across stays where it is; no smaller than its smallest size, no larger than the screen")
frame._width, frame._height = 500, 320
window.grip:GetScript("OnMouseUp")(window.grip)
check(store.place.width == 500 and store.place.height == 320 and store.place.dock == "BOTTOMRIGHT" and stands(frame, "BOTTOMRIGHT", 1920, 0), "the new size is kept, and it is still docked")
bar:GetScript("OnDragStart")(bar)
at(frame, 760, 760)
bar:GetScript("OnDragStop")(bar)
check(window.zone == "TOP" and stands(frame, "TOP", 960, 1080) and round(plate, 0, 0, 16, 16),
    "at the top's middle only its top edge is one with the screen's; the corners are measured on its new size")
check(window.grip.corner == "BOTTOMRIGHT", "and the grip is back at the bottom")
bar:GetScript("OnDragStart")(bar)
at(frame, 700, 300)
bar:GetScript("OnDragStop")(bar)
check(window.zone == nil and store.place.dock == nil and docked == nil and round(plate, 16, 16, 16, 16), "dragged away it is free again, round all around")
at(frame, 0, 300)
skin:Fit()
check(round(plate, 0, 16, 0, 16), "at the screen's edge without being docked its corners there are square too")
at(frame, 6, 300)
skin:Fit()
check(round(plate, 6, 16, 6, 16) and trims[1]._points[1][4] == 0, "near the edge they are no rounder than the gap: a corner flattens as it comes")
at(frame, 1, 300)
skin:Fit()
check(trims[1]._points[1][4] == -1, "and the trim slides out of the screen the last units of the way")

-- When it may not be handled, and what is kept
usable = false
bar:GetScript("OnDragStart")(bar)
window.grip:GetScript("OnMouseDown")(window.grip)
check(not frame._moving and not frame._sizing, "a window that may not be handled right now is neither moved nor sized")
bar:GetScript("OnDragStop")(bar)
window.grip:GetScript("OnMouseUp")(window.grip)
check(store.place.x == 700, "and a drag that never began keeps nothing")
usable = true
store.place = { x = 100, y = 900, width = 20, height = "wide", dock = "NOWHERE" }
window:Place()
check(frame._width == 180 and frame._height == 260 and stands(frame, "TOPLEFT", 100, 900) and window.zone == nil,
    "a kept place is read with care: too small a size, a size that is no number, a zone that is none")
store.place = { x = 0, y = 1080, width = 2600, height = 1400 }
window:Place()
check(frame._width == 1920 and frame._height == 1080, "and a size larger than the screen is now (another UI scale) is the screen's")
store.place = "broken"
window:Place()
check(frame._points[1][1] == "LEFT" and frame._width == 380, "and one that cannot be read at all gives the first place")
store.place = { x = 1, y = 2, dock = "LEFT" }
window:Place()
check(window.zone == "LEFT" and stands(frame, "LEFT", 0, 540), "a docked window is docked again at the next login")
window:Reset()
check(store.place == nil and frame._points[1][1] == "LEFT" and window.zone == nil, "reset, it is at its first place again")
at(frame, 300, 300)
bar:GetScript("OnDragStart")(bar)
EventRegistry:TriggerEvent("EditMode.Exit")
check(not Core.EditMode.active and not frame._moving and not window.moving and store.place.x == 300 and store.place.y == 560,
    "Edit Mode closes while it is in hand: it is let go there, and that is kept")
check(not bar:IsShown() and not window.grip:IsShown(), "Edit Mode closed, box and grip are gone")
EventRegistry:TriggerEvent("EditMode.Enter")
bar:GetScript("OnDragStart")(bar)
at(frame, 0, 410)
EventRegistry:TriggerEvent("EditMode.Exit")
check(store.place.dock == "LEFT" and window.zone == "LEFT", "(Edit Mode closes while it is in hand at the left edge: it docks there)")
bar:GetScript("OnDragStop")(bar)
check(store.place.dock == "LEFT" and window.zone == "LEFT" and stands(frame, "LEFT", 0, 540),
    "the game's end of that drag, coming after, changes nothing: it is let go once, and its zone stays kept")
window:Reset()

-- A module's hook that fails stops nothing of the window's own
do
local brokenFrame = CreateFrame("Frame", nil, UIParent)
local brokenStore = {}
local brokenWindow = Window.New(brokenFrame, { store = brokenStore, title = "Broken", dock = true, sizable = true,
    first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 }, docked = function() error("the module's own") end })
brokenWindow:Place()
check(Core.errors.window and brokenFrame._points[1][1] == "CENTER" and brokenFrame._width == 200,
    "a module's hook that fails is noted, and the window is placed all the same")
EventRegistry:TriggerEvent("EditMode.Enter")
at(brokenFrame, 500, 500)
brokenWindow.box:GetScript("OnDragStart")(brokenWindow.box)
brokenWindow.box:GetScript("OnDragStop")(brokenWindow.box)
check(not brokenWindow.moving and not brokenFrame._moving and brokenStore.place.x == 500 and brokenStore.place.y == 600,
    "dragged and let go, it is out of hand and kept where it was let go, though the hook fails again")
brokenWindow.grip:GetScript("OnMouseDown")(brokenWindow.grip)
brokenWindow.grip:GetScript("OnMouseUp")(brokenWindow.grip)
check(not brokenWindow.sizing and not brokenFrame._sizing, "and so is a sizing")
EventRegistry:TriggerEvent("EditMode.Exit")
brokenFrame:Hide()
brokenWindow.options.docked = nil
Core.errors.window = nil
end

-- The parts, for a window that is not ours ------------------------------------------------------
local theirs, handle, told = CreateFrame("Frame", "TheGamesWindow", UIParent), CreateFrame("Frame"), {}
Window.Mover(handle, theirs, { stopped = function() told[#told + 1] = "moved" end })
local grip = Window.Sizer(theirs, { name = "SaneUITestGrip", minWidth = 100, minHeight = 100, insetX = 4, insetY = 6,
    tip = "Drag to resize", started = function() told[#told + 1] = "sizing" end, stopped = function() told[#told + 1] = "sized" end })
check(SaneUITestGrip == grip and grip._points[1][4] == -4 and grip._points[1][5] == 6, "a grip can have a name and its own distance from the corner")
at(theirs, 40, 300)
theirs._width, theirs._height = 800, 600
handle:GetScript("OnDragStart")(handle)
handle:GetScript("OnDragStop")(handle)
grip:GetScript("OnMouseDown")(grip)
check(stands(theirs, "TOPLEFT", 40, 900) and theirs._sizing == "BOTTOMRIGHT", "the grip holds the top left corner and drags the lower right one")
grip:GetScript("OnMouseUp")(grip)
check(table.concat(told, " ") == "moved sizing sized" and store.TheGamesWindow == nil, "the parts move and size and tell of it; keeping the place is the caller's")
grip:GetScript("OnEnter")(grip)
check(GameTooltip._text == "Drag to resize" and GameTooltip._owner == grip and W.cursorArt == "UI_RESIZE_CURSOR", "the grip says what it is for, and the mouse shows it")
grip:GetScript("OnLeave")(grip)
check(W.cursorArt == nil, "until it leaves")

-- The kinds of motion ----------------------------------------------------------------------------------
local Motion = Core.Motion
local glide, swing, even, off = Motion.Kind("glide"), Motion.Kind("swing"), Motion.Kind("even"), Motion.Kind("off")
check(glide.time == 0.35 and swing.time == 0.45 and even.time == 0.5 and off.time == 0 and off.text == "Instant",
    "four kinds of motion: three that move and one that does not, each with its time")
check(Motion.Kind().key == "glide" and Motion.Kind("global").key == "glide" and Motion.Kind("nonsense").key == "glide",
    "a window without a kind of its own moves as the general one says: Glide at first; a key nobody knows is the general one")
check(Motion.Ease("OutQuartic", 0.5) == EasingUtil.OutQuartic(0.5) and Motion.Ease("OutQuartic", 0) == 0 and Motion.Ease("OutBack", 1) == 1,
    "a curve is one of the game's own (EasingUtil), from nothing to the whole way")
local curves = EasingUtil
EasingUtil = nil
check(Motion.Ease("OutQuartic", 0.3) == 0.3, "without the game's curves a motion goes at an even pace")
EasingUtil = curves
local furthest, steady, last = 0, true, 0
for step = 1, 99 do
    furthest = math.max(furthest, Motion.Share(swing, step / 100))
    local share = Motion.Share(even, step / 100)
    if share < last or share > 1 then steady = false end
    last = share
end
check(Motion.Share(swing, 0) == 0 and Motion.Share(swing, 1) == 1 and furthest > 1.08 and furthest < 1.11,
    "Swing starts at nothing, goes about a tenth past the mark on the way, and ends at the whole way")
check(steady and Motion.Share(glide, 0.5) > 0.9 and Motion.Share(off, 0) == 1,
    "Even never goes too far; Glide is nearly there half way; Instant is there at once")
local choices = Motion.Choices(true)
check(#choices == 5 and choices[1][1] == "global" and choices[1][2] == "Use global type" and choices[2][1] == "glide" and #Motion.Choices() == 4,
    "a window's own setting has Use global type first")

-- A region's fade and slide
do
    local region = CreateFrame("Frame", nil, UIParent)
    local fade, slide = Motion.Fade(region), Motion.Slide(region, 0.3)
    local fading, sliding = region._groups[1], region._groups[2]
    fade:To(0, 0.2)
    check(fading.playing and fading.moves[1].duration == 0.2, "a fade is the game's own animation, as long as it is asked to be")
    fade:To(1)
    check(not fading.playing and region._alpha == 1, "with no time it is there at once")
    slide:From(0, -12)
    check(sliding.playing and sliding.moves[1].y == -12 and sliding.moves[2].y == 12 and sliding.moves[2].duration == 0.3,
        "a slide shows the region that far off at once and moves it back in its time")
    sliding.moves[2].progress = 0.25
    slide:From(0, -8)
    check(sliding.moves[2].y == 8 + 12 * 0.75, "one still on its way adds what it had left")
    slide:SetTime(0.6)
    check(sliding.moves[2].duration == 0.6, "its time can be set anew")
    slide:Stop()
    Core.general.animations = false
    fade:To(0.5, 1)
    slide:From(0, 20)
    check(not fading.playing and region._alpha == 0.5 and not sliding.playing, "with SaneUI's animations off nothing moves: it is there at once")
    Core.general.animations = true
    region:Hide()
    fade:To(0.25, 1)
    check(not fading.playing and region._alpha == 0.25, "nor out of sight")
end

-- Opening while the mouse rests on it ---------------------------------------------------------------
local opener, changes = CreateFrame("Frame", nil, UIParent), {}
opener:SetSize(240, 44)
local expand = Expand.New(opener, { width = 420, height = 200, changed = function(open) changes[#changes + 1] = open end })
local clock, watch = opener._group, expand.watch
local function look(seconds) watch:GetScript("OnUpdate")(watch, seconds or Expand.STEP) end
check(not expand.open and not clock.playing and not watch:IsShown() and opener._motion and not opener._mouse,
    "a window that opens under the mouse is closed at first, nothing runs, and it takes the mouse's coming, not its clicks")
opener._mouseOver = true
opener:GetScript("OnEnter")(opener)
check(watch:IsShown() and not expand.open, "the mouse comes: the watch is out, but nothing opens yet")
look()
check(not expand.open, "a moment is not enough")
look()
check(expand.open and clock.playing and changes[1] == true and clock.duration == glide.time,
    "the mouse has rested on it: it begins to open, as the general kind of motion says")
clock:Run(0.5)
check(opener._width > 240 and opener._width < 421 and opener._height > 44, "its size follows the curve")
clock:Run(1)
check(opener._width == 420 and opener._height == 200 and not clock.playing, "and ends at its open size")
look(1)
check(expand.open and watch:IsShown(), "it stays open while the mouse is on it")
opener._mouseOver, W.held = false, true
look(1)
check(expand.open, "and while a button is held: it is being dragged")
W.held = false
look()
check(expand.open, "the mouse just gone, it waits a moment")
look(Expand.LINGER)
check(not expand.open and not watch:IsShown() and clock.playing and changes[2] == false,
    "gone long enough: it begins to close, and the watch goes in")
clock:Run(0.5)
local midway = opener._width
opener._mouseOver = true
opener:GetScript("OnEnter")(opener)
look()
look()
clock:Run(0)
check(expand.open and opener._width == midway, "a change of mind on the way starts from where it is")
clock:Run(1)
expand:Close()
clock:Run(1)
check(opener._width == 240 and opener._height == 44 and not watch:IsShown(),
    "closed, it has the size it had before it opened, not the one it was caught at")
opener:GetScript("OnEnter")(opener)
opener._mouseOver = false
look()
check(not expand.open and not watch:IsShown(), "the mouse only passing over it: nothing opens, and the watch goes in")
local held = false
local stiff = CreateFrame("Frame", nil, UIParent)
stiff:SetSize(100, 50)
local stiffExpand = Expand.New(stiff, { width = 200, height = 100, motion = function() return "off" end, still = function() return held end })
stiffExpand:Open()
check(stiff._width == 200 and not stiff._group.playing, "a window can have its own kind of motion: Instant opens it at once")
held = true
stiff._mouseOver = false
stiffExpand.watch:GetScript("OnUpdate")(stiffExpand.watch, 5)
stiffExpand:Close()
check(stiffExpand.open and stiff._width == 200, "while another part has its size (it fills the screen) it neither closes nor opens")
held = false
stiffExpand:Close()
opener:Hide()
expand:Open()
check(opener._width == 420 and not clock.playing, "out of sight it does not move: it has its new size at once")
expand:Close()
opener:Show()
expand:Open()
clock:Run(0.5)
opener:Hide()
check(opener._width == 420 and not clock.playing, "hidden while it opens, it is open at once: nothing waits half way out of sight")
expand:Close()
check(opener._width == 240, "and closes to its own small size, not one it was caught at")
opener:Show()
expand:Open()
clock:Run(1)
expand:Close()
clock:Run(1)
check(opener._width == 240 and opener._height == 44, "opened again, it closes to that size: the half way one was never taken for it")
do
local fragile = CreateFrame("Frame", nil, UIParent)
fragile:SetSize(100, 50)
local fragileExpand = Expand.New(fragile, { width = 200, height = 100, changed = function() error("the module's own") end,
    motion = function() return "off" end })
fragileExpand:Open()
check(fragileExpand.open and fragile._width == 200 and Core.errors.expand, "a module's hook that fails is noted, and it opens all the same")
fragileExpand:Close()
Core.errors.expand = nil
end
local cornered = CreateFrame("Frame", nil, UIParent)
local before = #W.frames
local corneredExpand = Expand.New(cornered, { width = 300, height = 300, corner = "BOTTOMLEFT" })
local spot = corneredExpand.hot
check(spot ~= cornered and spot._parent == cornered and spot._points[1][1] == "BOTTOMLEFT" and spot._width == 24
    and cornered:GetScript("OnEnter") == nil and spot:GetScript("OnEnter"), "with a corner named, only the mouse in that corner opens it")
local taken = false
local shared = CreateFrame("Frame", nil, UIParent)
shared:SetSize(100, 50)
local sharedExpand = Expand.New(shared, { width = 300, height = 150, still = function() return taken end })
local sharedWatch = sharedExpand.watch
sharedExpand:Open()
local sharedClock = shared._group
sharedClock:Run(0.5)
local caught = shared._width
taken = true
sharedClock:Run(0.75)
check(sharedExpand.open and not sharedClock.playing and shared._width == caught,
    "another part takes its size on the way (it begins to fill the screen): the opening stops where it is and leaves the size to that part")
shared._mouseOver = false
sharedWatch:GetScript("OnUpdate")(sharedWatch, 5)
check(sharedExpand.open and sharedWatch:IsShown(), "the mouse has left, but it is not closed while that part has the size")
taken = false
sharedWatch:GetScript("OnUpdate")(sharedWatch, 5)
sharedClock:Run(1)
check(not sharedExpand.open and shared._width == 100 and shared._height == 50, "the size its own again, it closes to the size it had before it opened")
local faulty = CreateFrame("Frame", nil, UIParent)
local faultyExpand = Expand.New(faulty, { width = 10, height = 10 })
faulty:GetScript("OnEnter")(faulty)
faultyExpand.hover.hot = 5 -- (a look that cannot be done)
faultyExpand.watch:GetScript("OnUpdate")(faultyExpand.watch, 1)
check(not faultyExpand.watch:IsShown() and Core.errors.expand, "a look that fails takes the watch in, and is noted")
Core.errors.expand = nil

-- Kept open
local kept = CreateFrame("Frame", nil, UIParent)
kept:SetSize(100, 40)
local keptExpand = Expand.New(kept, { width = 300, height = 120, hover = false, motion = function() return "off" end })
check(kept:GetScript("OnEnter") == nil and not kept._motion and not keptExpand.open, "without hover the mouse's coming does nothing")
keptExpand:Stay(true)
check(keptExpand.open and keptExpand.stays and kept._width == 300, "kept open, it opens")
check(not keptExpand.watch:IsShown(), "and nothing looks at the mouse while it is kept open")
kept._mouseOver = false
keptExpand.watch:GetScript("OnUpdate")(keptExpand.watch, 5)
check(keptExpand.open, "and stays open when the mouse is away")
keptExpand:Stay(false)
check(not keptExpand.open and not keptExpand.stays and kept._width == 100, "let go, it closes")
local both = CreateFrame("Frame", nil, UIParent)
both:SetSize(100, 40)
local bothExpand = Expand.New(both, { width = 300, height = 120, motion = function() return "off" end })
both._mouseOver = true
both:GetScript("OnEnter")(both)
bothExpand.watch:GetScript("OnUpdate")(bothExpand.watch, 1)
bothExpand:Stay(true)
check(bothExpand.open and bothExpand.stays and not bothExpand.watch:IsShown(), "with hover too: the mouse opens it, and it can be kept open, unwatched")
bothExpand:Stay(false)
check(bothExpand.open and not bothExpand.stays and bothExpand.watch:IsShown(), "let go, it stays open while the mouse is on it, watched again")
both._mouseOver = false
bothExpand.watch:GetScript("OnUpdate")(bothExpand.watch, 1)
check(not bothExpand.open, "and closes once the mouse has gone")

-- A watch, and the mouse on a window
do
    local watched, looks = CreateFrame("Frame", nil, UIParent), {}
    local watch = Core.Watch(watched, 0.2, function(passed) looks[#looks + 1] = passed end)
    check(not watch:IsRunning() and not watch.frame:IsShown() and watch.frame._parent == watched,
        "a watch is a small frame of its own in the frame it watches, hidden: nothing runs at first")
    watch:Start()
    watch.frame:GetScript("OnUpdate")(watch.frame, 0.1)
    check(#looks == 0, "out, it looks only every so many seconds")
    watch.frame:GetScript("OnUpdate")(watch.frame, 0.15)
    check(#looks == 1 and near(looks[1], 0.25), "then it looks, told how long it waited")
    check(watch.frame:IsVisible(), "it runs while the frame it watches is shown")
    watched:Hide()
    check(not watch.frame:IsVisible(), "and not while it is hidden (the game runs no OnUpdate of a frame out of sight)")
    watched:Show()
    watch:Stop()
    check(not watch:IsRunning(), "taken in, it is hidden again")
    local broken = Core.Watch(watched, 0, function() error("broken") end, "test watch")
    broken:Start()
    broken.frame:GetScript("OnUpdate")(broken.frame, 1)
    check(not broken:IsRunning() and Core.errors["test watch"], "a look that fails stops it, and is noted")
    Core.errors["test watch"] = nil

    local told = {}
    local spot = CreateFrame("Frame", nil, UIParent)
    local hover = Core.Hover(spot, { linger = 0.4, every = 0.2,
        enter = function() told[#told + 1] = "enter" end, leave = function() told[#told + 1] = "leave" end })
    check(spot._motion and not spot._mouse and not hover.watch:IsRunning(), "the mouse on a window: it takes only the mouse's coming, and nothing runs")
    spot._mouseOver = true
    spot:GetScript("OnEnter")(spot)
    check(hover.over and told[1] == "enter" and hover.watch:IsRunning(), "the mouse comes: it is there at once, and from then it is watched")
    spot._mouseOver = false
    hover.watch.frame:GetScript("OnUpdate")(hover.watch.frame, 0.2)
    check(hover.over and #told == 1, "a moment away is not gone")
    hover.watch.frame:GetScript("OnUpdate")(hover.watch.frame, 0.2)
    check(not hover.over and told[2] == "leave" and not hover.watch:IsRunning(), "gone long enough it is told, and the watch is in")
    spot:Hide()
end

-- Filling the screen from its edge ------------------------------------------------------------------
local wide = CreateFrame("Frame", nil, UIParent)
local wideBar, list = CreateFrame("Frame", nil, wide), CreateFrame("Frame", nil, wide)
wide:SetFrameStrata("MEDIUM")
local wideStore, fills, placed, own, native = {}, {}, 0, nil, 0
local kept, keptShown = false, 0 -- a kept choice of the game's own window (its checkbox)
local wideWindow = Window.New(wide, {
    store = wideStore, sizable = true, dock = true, edge = W.HOVER, content = list,
    classic = { { text = "Friends list", show = function() native = native + 1 end },
                { text = "Guild", show = function() kept, keptShown = true, keptShown + 1 end,
                  checked = function() return kept end, back = function() kept = false end } },
    first = { point = "CENTER", x = 0, y = 0, width = 380, height = 260 }, minWidth = 180, minHeight = 130,
    motion = function() return own end,
    filled = function(full) fills[#fills + 1] = full end,
    docked = function() placed = placed + 1 end,
})
local edge = wideWindow.edge
local function strips()
    local found = {}
    for _, widget in ipairs(W.frames) do
        if widget._parent == wide and widget ~= wideWindow.grip and widget._scripts.OnEnter and widget:IsShown() then found[#found + 1] = widget end
    end
    return found
end
local function along(strip) return strip._points[1][1] .. " " .. strip._points[2][1] end
wideWindow:Place()
check(edge and not edge.full and #strips() == 0, "a window that stands free has nothing at the screen's edge")
wideStore.place = { x = 0, y = 0, width = 380, height = 260, dock = "TOPLEFT" }
wideWindow:Place()
local square = strips()
check(#square == 1 and #square[1]._points == 1 and square[1]._points[1][1] == "TOPLEFT" and square[1]._strata == "DIALOG"
    and math.abs(square[1]._width - 4 * 768 / 2160) < 1e-9 and square[1]._height == square[1]._width,
    "docked in a corner, only a square of four of the screen's pixels in that corner, above everything: the mouse has to go all the way into it")
wideStore.place.dock = "TOP"
wideWindow:Place()
local top = strips()
check(#top == 1 and along(top[1]) == "TOPLEFT TOPRIGHT" and math.abs(top[1]._height - 2 * 768 / 2160) < 1e-9,
    "docked along the top, a strip along the window's top side")
wideStore.place.dock = "LEFT"
wideWindow:Place()
local shown = strips()
local strip = shown[1]
check(#shown == 1 and along(strip) == "TOPLEFT BOTTOMLEFT" and math.abs(strip._width - 2 * 768 / 2160) < 1e-9 and not strip._mouse,
    "docked at the left edge, one strip along it, two of the screen's pixels wide, that takes no clicks")

at(wide, 0, 410)
strip:GetScript("OnEnter")(strip)
check(not edge.full, "a strip that came under the mouse a moment ago does nothing: the mouse has to come anew")
W.Wait(1)
W.held = true
strip:GetScript("OnEnter")(strip)
check(not edge.full, "nor while a button is held with nothing on the cursor: a window is moved")
W.held = false
strip:GetScript("OnEnter")(strip)
local clock = wide._group
check(edge.full and edge.away and fills[1] == true and clock.playing and clock.duration == glide.time,
    "pushed against the screen's edge there, it begins to fill the screen, as the general kind of motion says")
W.cursorX, W.cursorY = 0, 410
strip:GetScript("OnEnter")(strip)
W.Wait(Edge.LOOK)
check(edge.full and edge.pushed == "left", "the mouse stays at the edge: the strip coming under it again is no new push")
W.cursorX = 900
W.Wait(Edge.LOOK)
check(edge.full and edge.pushed == nil, "once the mouse has gone some way from the edge a push counts again")
local back = edge.back
local middle = back.fills[3]
check(wide._strata == "HIGH" and wide._level == 500 and wide._clamped == false and back.shown and middle._alpha == 0
    and back.trims[1]._alpha == 0 and wideWindow.grip._alpha == 0,
    "raised above the game's bars and the others of that layer, free to spring past the screen's edge, a background to come, its grip out of sight")
check(wide._mouse == true and wide._wheel == true, "it takes the mouse and its wheel: what is behind it cannot be clicked, nor the camera turned or zoomed")
check(middle._texture == "Interface\\Buttons\\WHITE8X8" and middle._vertex[1] == 0 and middle._vertex[2] == 0 and middle._vertex[3] == 0
    and middle._gradient == nil and back.trims[1]._vertex[1] == Core.GOLD[1],
    "without settings of its own its background is solid black, its trim SaneUI's bronze")
local out, come = list._groups[1], list._groups[2]
check(out.playing and not come.playing, "what it holds fades out")
check(round(back, 0, 13, 0, 13), "at first its corners away from the screen's edge are as round as the window's at rest")
clock:Run(0.1)
local flat = 13 * (1 - edge.cover)
check(edge.cover > 0 and edge.cover < 1 and round(back, 0, flat, 0, flat) and middle._alpha > 0 and middle._alpha < 0.5,
    "on the way the background comes, and its corners flatten as it comes")
clock:Run(0.5)
local point = wide._points[1]
check(point[1] == "BOTTOMLEFT" and point[4] == 0 and point[5] < 410 and wide._width > 380 and middle._alpha > 0,
    "it grows away from its edge, which it never leaves")
local before = placed
clock:Run(1)
check(wide._points[1][1] == "TOPLEFT" and wide._points[1][2] == UIParent and wide._points[2][1] == "BOTTOMRIGHT"
    and wide._width == 1920 and wide._height == 1080 and middle._alpha == 0.5 and back.trims[1]._alpha == 1 and round(back, 0, 0, 0, 0),
    "and ends filling the whole screen, hanging on the screen, the background half see-through, every corner square at the screen's")
check(placed == before + 1 and come.playing and come.moves[1].y == Edge.DROP and come.moves[2].y == -Edge.DROP,
    "what it holds is laid out for the new size, and comes in from a little above")
local menu, wideBar = edge.classic, wideWindow.bar
check(wideBar and wideBar:IsShown() and wideBar._points[1][1] == "TOPLEFT" and wideBar._height == Window.FULL_BAR
    and wideWindow.buttons:IsShown() and #wideWindow.buttons.list == 4 and wideWindow.full.isMinimized == false,
    "full, a window without a title bar of its own has one at its top: its buttons there, full screen offering the way back")
check(wideWindow.settings:IsShown() and wideWindow.help:IsShown() and wideWindow.settings.picture._atlas == Window.SETTINGS
    and wideWindow.help.picture._text == "?" and wideWindow.buttons.first == wideWindow.help,
    "and, left of them, the game's cog (SaneUI's options over the full screen) and the question mark (its tour)")
check(menu and menu:IsShown() and menu._override == Edge.CLASSIC and menu._parent == wide and menu._points[1][1] == "RIGHT"
    and menu._points[1][2] == wideWindow.buttons.first and #menu._items == 2 and menu._items[1].text == "Friends list",
    "and the dropdown Classic windows in the title bar, left of the buttons, with the game's windows it stands for")
check(menu._items[1].checked == nil and type(menu._items[2].checked) == "function" and menu._items[2].checked() == false,
    "a kept choice is a checkbox, not ticked while ours is the one")

at(wide, 0, 0)
W.held, W.cursor = true, { kind = "item", id = 159 }
strip:GetScript("OnEnter")(strip)
W.held, W.cursor = false, nil
check(not edge.full and edge.away and fills[2] == false and clock.playing and edge.to[3] == 380 and edge.to[2] == 410,
    "pushed there again with an item dragged out of it (a button held, the item on the cursor), it goes back to its size in its zone: the bars are free for the drop")
clock:Run(0.5)
local midway = wide._width
W.Wait(Edge.LOOK)
strip:GetScript("OnEnter")(strip)
check(edge.full and edge.from[3] == midway and edge.to[3] == 1920, "a change of mind on the way starts from where it is")
W.Wait(Edge.LOOK)
strip:GetScript("OnEnter")(strip)
clock:Run(1)
check(not edge.away and stands(wide, "LEFT", 0, 540) and wide._width == 380 and wide._height == 260,
    "back, it hangs on its zone again, at its size")
check(wide._strata == "MEDIUM" and wide._level == 1 and wide._clamped == true and not back.shown and not middle:IsShown() and wideWindow.grip._alpha == 1
    and #strips() == 1,
    "in its own layer, kept on the screen, without the background, its grip back, its strip at the edge")
check(wide._mouse == false and wide._wheel == false, "the mouse goes through it again, as before")

-- Esc brings it back, as it closes the game's windows
W.Wait(1)
strip:GetScript("OnEnter")(strip)
clock:Run(1)
local escape = SaneUIEscape
check(edge.full and escape and escape:IsShown() and UISpecialFrames[#UISpecialFrames] == "SaneUIEscape",
    "full, a frame of ours stands shown in the game's list of what Esc closes")
escape:Hide()
check(not edge.full and edge.away and clock.playing and fills[#fills] == false, "the game hides it (Esc): the window goes back")
clock:Run(1)
check(not edge.away and stands(wide, "LEFT", 0, 540) and wide._width == 380 and not escape:IsShown(),
    "back in its zone, and the frame is out of the way: Esc is the game's again")

-- Edit Mode: windows are arranged, not filled
W.Wait(1)
strip:GetScript("OnEnter")(strip)
clock:Run(1)
EventRegistry:TriggerEvent("EditMode.Enter")
check(not edge.away and stands(wide, "LEFT", 0, 540) and wideWindow.box:IsShown() and wideWindow.grip:IsShown(),
    "Edit Mode opens while the window fills the screen: it is back in its zone at once, to be arranged")
W.Wait(1)
strip:GetScript("OnEnter")(strip)
check(not edge.full, "in Edit Mode the screen's edge does nothing")
at(wide, 0, 410)
wideWindow.box:GetScript("OnDragStart")(wideWindow.box)
check(wide._moving, "there it is dragged by its box")
wideWindow.box:GetScript("OnDragStop")(wideWindow.box)
check(wideStore.place.dock == "LEFT" and stands(wide, "LEFT", 0, 540), "let go at the left edge, it is docked there again")
EventRegistry:TriggerEvent("EditMode.Exit")

-- The dropdown Classic windows
W.Wait(1)
strip:GetScript("OnEnter")(strip)
check(not menu:IsShown(), "on its way to full the dropdown is not there")
clock:Run(1)
check(menu:IsShown(), "it comes when the window stands")
menu._items[2].fn()
check(kept and keptShown == 1 and not edge.full and menu._items[2].checked() == true,
    "a kept choice chosen: the window goes back, the game's own comes and is ticked")
clock:Run(1)
W.Wait(1)
strip:GetScript("OnEnter")(strip)
clock:Run(1)
menu._items[2].fn()
check(not kept and keptShown == 1 and edge.full and menu:IsShown(),
    "chosen again while ticked: ours is the one again, and the window stays full")
menu._items[1].fn()
check(not edge.full and clock.playing and native == 1 and not menu:IsShown(),
    "one chosen: the window goes back to its zone, and the game's own window comes")
clock:Run(1)
check(not edge.away and wide._width == 380 and not menu:IsShown(), "back, no dropdown")

own = "off"
W.Wait(1)
strip:GetScript("OnEnter")(strip)
check(edge.full and not clock.playing and wide._width == 1920 and list._alpha == 1, "a window of its own kind Off fills the screen at once")
wide:Hide()
check(not edge.away and stands(wide, "LEFT", 0, 540) and wide._width == 380 and wide._strata == "MEDIUM", "hidden, it is back in its zone at once")
wide:Show()
W.Wait(1)
strip:GetScript("OnEnter")(strip)
wideWindow:Reset()
check(not edge.away and wide._points[1][1] == "CENTER" and #strips() == 0, "reset while it fills the screen, it is at its first place, free")
edge:Fill(true)
check(edge.full and wide._width == 1920 and wideWindow.full.isMinimized == false, "free, it fills the screen too (by its button), which then offers the way back")
edge:Fill(false)
check(not edge.away and wide._points[1][1] == "CENTER" and wideWindow.full.isMinimized == true, "and goes back to where it stood")

own = nil
wideStore.place = { x = 0, y = 0, width = 380, height = 260, dock = "LEFT" }
wideWindow:Place()
W.Wait(1)
at(wide, 0, 410)
strip:GetScript("OnEnter")(strip)
rawset(edge.back, "SetAlpha", function() error("broken") end)
clock:Run(0.5)
check(edge.off and not edge.away and stands(wide, "LEFT", 0, 540) and #strips() == 0 and Core.errors["full screen"],
    "a step that fails puts the window back in its zone, where it stays from now on; the problem is kept")
wipe(Core.errors)

-- What a window holds can go with the motion (moving): in sight the whole way, placed at every step
do
    local roomy = CreateFrame("Frame", nil, UIParent)
    local held = CreateFrame("Frame", nil, roomy)
    local shares, going = {}, nil
    local roomyStore = {}
    local roomyWindow = Window.New(roomy, {
        store = roomyStore, dock = true, edge = W.HOVER, content = held,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 },
        filled = function(on, width, height) going = { on, width, height } end,
        moving = function(share) shares[#shares + 1] = share end,
    })
    roomyStore.place = { x = 0, y = 0, width = 300, height = 200, dock = "RIGHT" } -- the left holds the window above
    roomyWindow:Place()
    W.Wait(1)
    local push
    for _, widget in ipairs(W.frames) do
        if widget._parent == roomy and widget._scripts.OnEnter and widget:IsShown() then push = widget end
    end
    at(roomy, 1620, 440)
    push:GetScript("OnEnter")(push)
    local way = roomy._group
    check(going and going[1] == true and going[2] == 1920 and going[3] == 1080, "it is told where the window goes: the whole screen")
    way:Run(0.5)
    check(#shares > 0 and shares[#shares] > 0 and shares[#shares] < 1 and held._groups == nil and held._alpha ~= 0,
        "on the way what it holds is placed at each step by the share of the way, never faded out")
    way:Run(1)
    check(shares[#shares] == 1 and held._groups == nil and roomyWindow.edge.full, "at the end the whole way, and it comes in from nowhere")
    roomy:Hide()
end

-- The section Expand window: a module's own settings ------------------------------------------------
local described = { { key = "first", default = true, text = "First" }, { key = "last", default = true, text = "Last" } }
Edge.Options(described, 2, "Appearance")
check(#described == 10 and described[1].key == "first" and described[2].key == "expand" and described[2].header == "Expand window"
    and described[3].key == "expandCorner" and described[3].parent == "expand" and described[3].default == true
    and described[3].text == "Hotcorner"
    and described[4].key == "expandClick" and described[4].parent[1] == "expand" and described[4].parent[2] == "expandCorner"
    and described[4].default == true and described[4].text == "Hotcorner requires leftclick"
    and table.remove(described, 3) and table.remove(described, 3)
    and described[3].key == "motion" and described[4].key == "expandOpacity" and described[5].key == "expandTexture"
    and described[6].key == "corners" and described[7].key == "squareEdges" and described[8].key == "last"
    and described[7].tab == "Appearance" and described[3].parent == "expand" and described[7].parent == nil
    and described[6].header == "Window corners",
    "a module puts the section Expand window where it wants it: whether it fills the screen, whether its edge does (Hotcorner) and wants a click, how it moves, its background; then its corners, a section of their own")
check(described[6].min == 0 and described[6].max == 100 and described[6].unit == "%" and described[6].default == 10
    and described[6].text == "Corner radius" and described[7].default == true and described[7].text == "Don't round corners on screen edges",
    "the corner radius is a share, a tenth at first; the corners on the screen's edges are square at first")
check(described[3].choices[1][1] == Core.Motion.GLOBAL and described[4].min == 0 and described[4].max == 100 and described[4].unit == "%"
    and described[4].default == 50 and described[5].default == "solid" and #described[5].choices == #Core.Skin.TILES + 1 and described[5].choices[1][2] == Edge.SOLID,
    "the animation type may be the general one, the opacity is a share, half by default, the texture solid black or one of Blizzard's")

do -- A module's section, followed by itself
    local list = { { key = "animations", default = true, text = "Animations" } }
    Edge.Options(list, 2, nil, { motion = "animations" })
    local heard = {}
    Core.Options("EdgeTest", list, function(key) heard[#heard + 1] = key end)
    check(list[5].key == "motion" and list[5].parent[1] == "expand" and list[5].parent[2] == "animations" and list[2].parent == nil
        and list[3].parent == "expand" and list[4].parent[2] == "expandCorner" and list[6].parent == "expand",
        "a module can put some of the section under switches of its own too")
    W.Fire("ADDON_LOADED", "SaneUI_EdgeTest")
    local own = CreateFrame("Frame", nil, UIParent)
    local ownWindow = Window.New(own, { store = { place = { x = 0, y = 0, width = 200, height = 100, dock = "BOTTOM" } }, sizable = true,
        dock = true, edge = Core.Settings("EdgeTest"), first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
    ownWindow:Place()
    check(ownWindow.edge.strips.bottom:IsShown(), "(docked at the bottom, its strip there)")
    Core.Set("EdgeTest", "expand", false)
    check(not ownWindow.edge.strips.bottom:IsShown() and heard[1] == "expand",
        "a switch of the section changed: the window takes it in by itself, and the module still hears of it")
    Core.Set("EdgeTest", "expand", true)
    check(ownWindow.edge.strips.bottom:IsShown(), "and back")
    own:Hide()
end

do -- Hotcorner requires leftclick: the edge fills the screen by a left click only
    local click = CreateFrame("Frame", nil, UIParent)
    local clickWindow = Window.New(click, { store = { place = { x = 0, y = 0, width = 200, height = 100, dock = "BOTTOM" } }, sizable = true,
        dock = true, edge = { expand = true, expandClick = false, motion = "off", expandOpacity = 50, expandTexture = "solid" },
        first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
    local clickEdge = clickWindow.edge
    clickWindow:Place()
    W.Wait(1)
    at(click, 860, 0)
    local bottom = clickEdge.strips.bottom
    clickEdge.settings.expandClick = true
    clickEdge:Update()
    check(bottom._mouse == true, "with the window's Hotcorner requires leftclick its strip takes clicks")
    bottom:GetScript("OnEnter")(bottom)
    check(not clickEdge.full, "the mouse reaching the edge does nothing then")
    bottom:GetScript("OnMouseDown")(bottom, "RightButton")
    check(not clickEdge.full, "nor a right click")
    bottom:GetScript("OnMouseDown")(bottom, "LeftButton")
    check(clickEdge.full, "a left click there fills the screen")
    bottom:GetScript("OnMouseDown")(bottom, "LeftButton")
    check(not clickEdge.full, "and another brings it back")
    clickEdge.settings.expandClick = false
    clickEdge:Update()
    check(not bottom._mouse, "switched off, clicks go through the strip again")
    bottom:GetScript("OnMouseDown")(bottom, "LeftButton")
    check(not clickEdge.full, "and a click there does nothing")
    clickWindow:Place()
    click:Hide()
end

do -- Hotcorner off (Saneroki, 2026-11-18: the hot corner "not at all", for every module): the edge does nothing, a key still fills
    local quiet = CreateFrame("Frame", nil, UIParent)
    local settings = { expand = true, expandCorner = true, expandClick = false, motion = "off", expandOpacity = 50, expandTexture = "solid" }
    local quietWindow = Window.New(quiet, { store = { place = { x = 0, y = 0, width = 200, height = 100, dock = "BOTTOMLEFT" } },
        sizable = true, dock = true, edge = settings, first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
    local quietEdge = quietWindow.edge
    quietWindow:Place()
    W.Wait(1)
    at(quiet, 0, 0)
    check(quietEdge.strips.corner and quietEdge.strips.corner:IsShown() and quietEdge:Spot() ~= nil, "(docked in a corner: its square there)")
    settings.expandCorner = false
    quietEdge:Update()
    check(not quietEdge.strips.corner:IsShown() and quietEdge:Spot() == nil, "Hotcorner off: no square, the corner does nothing")
    quietEdge:Fill(true)
    check(quietEdge.full, "its key or its button still fills the screen")
    quietEdge:Fill(false)
    quietWindow:Place()
    check(not quietEdge.full and not quietEdge.strips.corner:IsShown(), "back, still no hot corner")
    settings.expandCorner = true
    quietEdge:Update()
    check(quietEdge.strips.corner:IsShown(), "on again: the square is back")
    check(Edge.DEFAULTS.expandCorner == true and Edge.KEYS.expandCorner, "Hotcorner is on by default, a switch of the section")
    quiet:Hide()
end

do -- Every module's at first (Saneroki, 2026-11-16: "Make on all modules the hotcorner require a left click")
    check(Edge.DEFAULTS.expandClick == true, "Hotcorner requires leftclick is on by default")
    local frame = CreateFrame("Frame", nil, UIParent)
    local handle = Window.New(frame, { store = { place = { x = 0, y = 0, width = 200, height = 100, dock = "BOTTOM" } }, sizable = true,
        dock = true, edge = true, first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
    handle:Place()
    W.Wait(1)
    at(frame, 860, 0)
    local bottom = handle.edge.strips.bottom
    bottom:GetScript("OnEnter")(bottom)
    check(bottom._mouse == true and not handle.edge.full, "a window on the defaults: its strip takes clicks, the mouse's coming does nothing")
    bottom:GetScript("OnMouseDown")(bottom, "LeftButton")
    check(handle.edge.full, "a left click there fills the screen")
    bottom:GetScript("OnMouseDown")(bottom, "LeftButton")
    handle:Place()
    frame:Hide()
end

local tall = CreateFrame("Frame", nil, UIParent)
local tallSettings = { expand = true, motion = "off", expandOpacity = 100, expandTexture = "rock", corners = 10, squareEdges = true }
local tallWindow = Window.New(tall, {
    store = { place = { x = 0, y = 1080, width = 300, height = 200, dock = "TOPLEFT" } }, sizable = true, dock = true, edge = tallSettings,
    first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, minWidth = 100, minHeight = 100,
})
local tallEdge = tallWindow.edge
tallWindow:Place()
W.Wait(1)
at(tall, 0, 880)
tallEdge.strips.corner:GetScript("OnEnter")(tallEdge.strips.corner)
local tallMiddle = tallEdge.back.fills[3]
check(tallEdge.full and tall._width == 1920 and tallMiddle._alpha == 1 and tallMiddle._texture == Core.Skin.Tile("rock").file
    and tallMiddle._wrap == "REPEAT" and near(tallMiddle._coords[2], 1920 / 512) and near(tallMiddle._coords[4], 1080 / 512),
    "with settings of its own it moves as they say (Off: at once), its background as opaque as set, a tile of Blizzard's, repeated at its size")
tallSettings.expandOpacity, tallSettings.expandTexture = 25, "solid"
tallEdge:Update()
check(tallMiddle._alpha == 0.25 and tallMiddle._texture == "Interface\\Buttons\\WHITE8X8",
    "a change of the background is seen at once, while it fills the screen")
tallSettings.squareEdges = false
tallEdge:Update()
tallSettings.corners = 100
tallEdge:Update()
local tallTrims = tallEdge.back.trims
check(round(tallEdge.back, 0, 0, 0, 0) and tallTrims[1]._points[1][4] == -2 and tallTrims[4]._points[1][5] == 1080,
    "full, it is square even with round corners everywhere and at 100 %: its trim is out of the screen")
tallSettings.corners, tallSettings.squareEdges = 10, true
tallEdge:Update()
tallSettings.expand = false
tallEdge:Update()
check(not tallEdge.away and stands(tall, "TOPLEFT", 0, 1080) and tall._mouse == false and not tallEdge.strips.corner:IsShown(),
    "switched off, it is back in its zone at once, taking no click as before, and the screen's edge does nothing")
tallEdge:Fill(true)
check(not tallEdge.full, "nor does anything else make it fill the screen")
tallSettings.expand = true
tallEdge:Update()
check(tallEdge.strips.corner:IsShown() and not tallEdge.strips.left, "switched on again, its square is back")
tall:SetMouseClickEnabled(false)
tall:SetMouseMotionEnabled(true)
W.Wait(1)
tallEdge.strips.corner:GetScript("OnEnter")(tallEdge.strips.corner)
check(tallEdge.full and tall._mouse == true, "a window that takes only the mouse's coming takes clicks too while it fills the screen")
tallWindow:Place()
check(not tallEdge.away and tall._mouse == false and tall._motion == true, "back in its zone it takes the mouse's coming as before, and no clicks")

-- A window with a skin fills the screen: its skin goes as the background comes
local skinned = CreateFrame("Frame", nil, UIParent)
local skinnedWindow = Window.New(skinned, {
    store = { place = { x = 0, y = 260, width = 380, height = 260, dock = "BOTTOMLEFT" } }, sizable = true, dock = true, skin = "round", edge = W.HOVER,
    first = { point = "CENTER", x = 0, y = 0, width = 380, height = 260 },
})
at(skinned, 0, 0)
skinnedWindow:Place()
local skinnedSkin, skinnedEdge = skinnedWindow.skin, skinnedWindow.edge
check(round(skinnedSkin.shape, 0, 13, 0, 0), "docked in a corner, only the corner away from the screen's edges is round")
W.Wait(1)
skinnedEdge.strips.corner:GetScript("OnEnter")(skinnedEdge.strips.corner)
skinned._group:Run(0.1)
check(skinnedSkin._alpha < 1 and skinnedSkin._alpha > 0 and near(skinnedSkin._alpha, 1 - skinnedEdge.cover) and round(skinnedSkin.shape, 0, 13, 0, 0),
    "on its way its skin fades as the background comes, and follows its size")
local stepWidth, kept = skinnedSkin.shape.width, skinned._width
skinned._width = 999
skinnedSkin:GetScript("OnSizeChanged")(skinnedSkin)
check(skinnedSkin.shape.width == stepWidth, "fitted once per step (by the motion): its own size change fits nothing then")
skinned._width = kept
skinned._group:Run(1)
check(skinnedSkin._alpha == 0 and skinnedEdge.cover == 1, "full, only the background is there")
skinnedWindow:Place()
check(skinnedSkin._alpha == 1 and not skinnedEdge.back.shown, "back at rest, its skin is there again")

-- A window with a title bar: its title, a search, three buttons; moved by it -------------------------
local merchant = CreateFrame("Frame", "TestMerchantFrame", UIParent) -- a window of the game's
local merchantClose = CreateFrame("Button", "TestMerchantFrameCloseButton", merchant)
merchantClose:SetFrameLevel(510)
local nativeShown, oursShown, closed, searched = 0, 0, 0, {}
local trader = CreateFrame("Frame", nil, UIParent)
local traderStore = {}
local traderWindow = Window.New(trader, {
    store = traderStore, title = "Vendor", titleBar = true, sizable = true, dock = true, edge = W.HOVER,
    first = { point = "CENTER", x = 0, y = 0, width = 400, height = 300 },
    classic = { { text = "Vendor", show = function() end } },
    close = function() closed = closed + 1 end,
    search = function(text) searched[#searched + 1] = text end,
    native = { frame = function() return merchant end,
               show = function() nativeShown = nativeShown + 1 end, back = function() oursShown = oursShown + 1 end },
})
at(trader, 760, 390)
traderWindow:Place()
local titleBar, buttons = traderWindow.bar, traderWindow.buttons
local close, full, toggle = buttons.list[1], buttons.list[2], buttons.list[3]
local find, box = titleBar.find, titleBar.box
check(titleBar:IsShown() and titleBar._height == Window.BAR and titleBar._points[1][1] == "TOPLEFT" and titleBar._points[2][1] == "TOPRIGHT"
    and titleBar.title._text == "Vendor" and titleBar.glass:IsShown() and titleBar._level == trader:GetFrameLevel() + Window.BAR_LEVEL,
    "a kind of window with a title bar has it across its top, above what it holds: a magnifier and its title at the left")
check(buttons:IsShown() and buttons._parent == titleBar and #buttons.list == 5 and full == traderWindow.full and toggle == traderWindow.toggle
    and buttons._points[1][1] == "RIGHT" and close._points[1][1] == "RIGHT" and full._points[1][2] == close
    and toggle._points[1][2] == full and buttons.first == toggle,
    "at its right, from the right: close, full screen, the game's own window")
check(not traderWindow.settings:IsShown() and not traderWindow.help:IsShown(),
    "the options and the question mark are not there while it is small: only on its full screen")
check(full.isMinimized == true and toggle._Normal._texture._atlas == "common-button-square-gray-up"
    and next(traderWindow.edge.strips) == nil,
    "full screen offers to fill the screen; the game's window is the kit's grey square button")

-- The search
check(not box:IsShown() and box._points[2][1] == "RIGHT" and box._points[2][2] == toggle, "the search box waits; it would end left of the buttons")
find:GetScript("OnMouseDown")(find)
find:GetScript("OnClick")(find)
check(box:IsShown() and not find:IsShown() and box._focus, "a click on the title opens the search box over the bar but its buttons, the cursor in it")
box:SetText("tra")
check(searched[#searched] == "tra", "what is typed goes to the module at every change")
box:GetScript("OnEscapePressed")(box)
check(not box:IsShown() and find:IsShown() and searched[#searched] == "" and box._text == "", "Esc closes it: emptied, the module told, the title back")
find:GetScript("OnMouseDown")(find)
find:GetScript("OnClick")(find)
box:ClearFocus()
check(not box:IsShown() and find:IsShown(), "left empty, it closes when the cursor leaves it")
find:GetScript("OnMouseDown")(find)
find:GetScript("OnClick")(find)
box:SetText("tra")
traderWindow:EndSearch()
check(not box:IsShown() and find:IsShown() and searched[#searched] == "" and box._text == "" and not box._focus,
    "a module that leaves the search itself closes it as Esc does: emptied, the module told, the title back")

-- Moved by the title bar
check(traderWindow:Draggable(), "free, its title bar moves it at any time")
titleBar:GetScript("OnDragStart")(titleBar)
check(trader._moving, "dragged by its title bar it moves")
titleBar:GetScript("OnDragStop")(titleBar)
check(traderStore.place.dock == "CENTER" and stands(trader, "CENTER", 960, 540), "let go in the middle of the screen it docks there")
find:GetScript("OnMouseDown")(find)
find:GetScript("OnDragStart")(find)
check(trader._moving, "a drag of the title moves it too")
at(trader, 0, 390)
find:GetScript("OnDragStop")(find)
find:GetScript("OnClick")(find)
check(not box:IsShown() and traderStore.place.dock == nil and traderStore.place.x == 0,
    "and opens no search; let go at a screen edge it does not dock there outside Edit Mode: it stands free")
traderStore.place = { x = 1520, y = 690, width = 400, height = 300, dock = "RIGHT" } -- (the wide window holds the left one)
traderWindow:Place()
check(titleBar:IsShown() and buttons:IsShown() and not traderWindow:Draggable(),
    "docked at a screen edge it keeps its title bar and buttons, but the bar does not move it: that is Edit Mode's")
traderWindow.options.dragDocked = true
check(traderWindow:Draggable(), "unless the window says so")
traderWindow.options.dragDocked = nil

-- In Edit Mode
EventRegistry:TriggerEvent("EditMode.Enter")
check(not buttons:IsShown() and not traderWindow:Draggable() and traderWindow.box:IsShown(), "in Edit Mode its box moves it, and the buttons are not there")
traderWindow.edge:Fill(true)
traderStore.place.full = true
check(traderWindow:Open() == "ours" and not traderWindow.edge.full and not traderWindow.edge.away,
    "in Edit Mode nothing fills the screen, not even a window asked for that was left full: windows are arranged at their size")
traderStore.place.full = nil
at(trader, 760, 390)
traderWindow.box:GetScript("OnDragStart")(traderWindow.box)
traderWindow.box:GetScript("OnDragStop")(traderWindow.box)
EventRegistry:TriggerEvent("EditMode.Exit")
check(traderStore.place.dock == "CENTER" and buttons:IsShown(), "let go in the middle there, it docks there; Edit Mode closed, the buttons are back")

-- Full screen by its button, kept for the next time
full.maximized(full)
local traderClock = trader._group
check(traderWindow.edge.full and traderClock.playing and full.isMinimized == false and traderStore.place.full == true,
    "its full screen button fills the screen, offers the way back, and that is kept")
traderClock:Run(1)
local traderMenu = traderWindow.edge.classic
check(trader._width == 1920 and titleBar:IsShown() and traderMenu:IsShown() and traderMenu._points[1][1] == "RIGHT"
    and traderMenu._points[1][2] == traderWindow.help and traderWindow.help._points[1][2] == traderWindow.settings
    and traderWindow.settings._points[1][2] == toggle and box._points[2][2] == traderMenu,
    "full, its title bar is the full screen's: the options and the question mark, the dropdown Classic windows left of them, the search box ending left of that")
trader:Hide()
trader:Show()
check(not traderWindow.edge.away and trader._width == 400, "hidden, it is back at its size")
check(traderWindow:Open() == "ours" and traderWindow.edge.full, "asked for again (the game's key), it fills the screen again, as it was left")
full.minimized(full)
traderClock:Run(1)
check(not traderWindow.edge.away and stands(trader, "CENTER", 960, 540) and trader._width == 400 and full.isMinimized == true
    and traderStore.place.full == nil, "minimized, it is back in the middle at its size, and that is kept")

-- Close, and the game's own window
close:GetScript("OnClick")(close)
check(closed == 1, "the close button does what the module says closing is")
toggle:GetScript("OnClick")(toggle)
check(nativeShown == 1 and traderStore.place.native == true, "the toggle: the game's own window instead of ours, and that is kept")
check(traderWindow:Open() == "native" and nativeShown == 2, "asked for again, the game's own window comes")
local back
for _, widget in ipairs(W.frames) do
    if widget._parent == merchant and widget._kind == "Button" and widget ~= merchantClose then back = widget end
end
check(back and back._points[1][1] == "RIGHT" and back._points[1][2] == merchantClose and back._level == 510
    and back._Normal._texture._atlas == toggle._Normal._texture._atlas,
    "the game's window has the same button, beside its close button")
back:GetScript("OnClick")(back)
check(oursShown == 1 and traderStore.place.native == nil and traderWindow:Attach() == back, "it brings ours back, kept so; it is put there once")
at(trader, 760, 390)
titleBar:GetScript("OnDragStart")(titleBar)
titleBar:GetScript("OnDragStop")(titleBar)
check(traderStore.place.dock == "CENTER" and traderStore.place.x == 760, "a new place keeps what it was left as")
traderWindow.edge.settings = { expand = false, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true }
traderWindow.edge:Update()
check(not full:IsShown() and toggle._points[1][2] == close and buttons.first == toggle, "a window that may not fill the screen has no full screen button")

-- A module's own button in the title bar: its picture, whatever words its tip has
;(function()
    local held = CreateFrame("Frame", nil, UIParent)
    local heldWindow = Window.New(held, { store = {}, title = "Held", titleBar = true,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 },
        buttons = { { atlas = "common-icon-undo", tip = "Start again", text = "Every row as it came.", click = function() end } } })
    heldWindow:Place()
    local own = heldWindow.own and heldWindow.own[1]
    check(own and own.picture._kind == "Texture" and own.picture._atlas == "common-icon-undo",
        "a module's own button shows its picture; the words of its tip stay in its tip")
end)()

-- A click on the title of a window without search: the module's; its title bar bare while the module says so; a
-- second place, kept under another name, with a first place of its own.
;(function()
    local looked = CreateFrame("Frame", nil, UIParent)
    local clicks, bare = 0, false
    local store = {}
    local lookedWindow = Window.New(looked, { store = store, key = "wide", title = "Log", titleBar = true,
        first = { point = "TOPLEFT", x = 12, y = -84, width = 300, height = 200 },
        titleClick = function() clicks = clicks + 1 end, titleTip = { "Sorted", function() return "A click: the next" end },
        bare = function() return bare end })
    lookedWindow:Place()
    local find = lookedWindow.bar.find
    find._scripts.OnMouseDown(find)
    find._scripts.OnClick(find)
    check(clicks == 1 and not lookedWindow.bar.box._shown, "a click on its title: the module's, no search")
    find.dragged = true
    find._scripts.OnClick(find)
    check(clicks == 1, "a drag by its title: no click")
    bare = true
    lookedWindow:Refresh()
    check(not lookedWindow.buttons._shown, "bare while the module says so: no buttons")
    bare = false
    lookedWindow:Refresh()
    check(lookedWindow.buttons._shown, "and its buttons again")
    lookedWindow:Use("small", { point = "TOPLEFT", x = 0, y = 0, width = 300, height = 200 })
    local point = looked._points[1]
    check(lookedWindow.options.key == "small" and point[1] == "TOPLEFT" and point[4] == 0 and point[5] == 0,
        "another place: at its own first place")
    looked:ClearAllPoints()
    looked._left, looked._top = 400, 700
    lookedWindow.bar._scripts.OnDragStart(lookedWindow.bar)
    lookedWindow.bar._scripts.OnDragStop(lookedWindow.bar)
    lookedWindow:Use("wide", { point = "TOPLEFT", x = 12, y = -84, width = 300, height = 200 })
    point = looked._points[1]
    check(store.small and store.small.x == 400 and not store.wide and point[4] == 12 and point[5] == -84,
        "moved there, kept under its own name; the first place stands where it stood")
    -- Its title at the right, left of its buttons or at the bar's end; a drag tells that it begins.
    lookedWindow:TitleAt("RIGHT", 4)
    local find, title = lookedWindow.bar.find, lookedWindow.bar.title
    check(find._points[1][1] == "RIGHT" and find._points[1][2] == lookedWindow.buttons.first and #find._points == 1
        and title._points[1][1] == "RIGHT" and title._points[1][4] == -4, "its title at the right, left of its buttons")
    bare = true
    lookedWindow:Refresh()
    check(find._points[1][1] == "RIGHT" and find._points[1][2] == nil and #find._points == 1, "bare: at the bar's right end")
    bare = false
    lookedWindow:TitleAt("LEFT")
    check(find._points[1][1] == "TOPLEFT" and #find._points == 2 and title._points[1][1] == "LEFT"
        and title._points[1][4] == Window.TEXT_INSET, "and back at its left, where every title stands")
    local beside = 0
    local barred = CreateFrame("Frame", nil, UIParent)
    local barredWindow = Window.New(barred, { store = {}, titleBar = true, first = { point = "CENTER", x = 0, y = 0 },
        barClick = function() beside = beside + 1 end })
    barredWindow:Place()
    local line = barredWindow.bar
    line._mouseOver = true
    line._scripts.OnMouseDown(line, "LeftButton")
    line._scripts.OnMouseUp(line, "LeftButton")
    check(beside == 1, "a click on the bar beside its title: the module's")
    line._scripts.OnMouseUp(line, "RightButton")
    line._mouseOver = false
    line._scripts.OnMouseUp(line, "LeftButton")
    check(beside == 1, "not with the other button, nor let go off the bar")
    line._mouseOver = true
    line._scripts.OnMouseDown(line, "LeftButton")
    line._scripts.OnDragStart(line)
    line._scripts.OnDragStop(line)
    line._scripts.OnMouseUp(line, "LeftButton")
    check(beside == 1, "a press that was a drag is no click")
    check(not lookedWindow.bar._scripts.OnMouseUp, "without it the bar has no click")
    local lifted = 0
    lookedWindow.options.lifted = function() lifted = lifted + 1 end
    lookedWindow.bar._scripts.OnDragStart(lookedWindow.bar)
    check(lifted == 1, "a drag begins: the module told")
    lookedWindow.bar._scripts.OnDragStop(lookedWindow.bar)
end)()

-- Without a title bar
local plain = CreateFrame("Frame", nil, UIParent)
local plainWindow = Window.New(plain, { store = {}, first = { point = "CENTER", x = 0, y = 0 }, edge = W.HOVER })
plainWindow:Place()
check(plainWindow.bar == nil and plainWindow.buttons == nil and not plainWindow:Draggable(),
    "a kind of window without a title bar (the small chat) has none, and nothing to move it by but Edit Mode")
at(plain, 860, 490)
plainWindow.edge:Fill(true)
plain._group:Run(1)
local plainBar = plainWindow.bar
check(plainBar and plainBar:IsShown() and #plainWindow.buttons.list == 4 and not plainBar.glass:IsShown(),
    "filling the screen it has the title bar at its top; without search, no magnifier")
plainBar.find:GetScript("OnClick")(plainBar.find)
check(not plainBar.box:IsShown(), "and its title opens no search")
plainWindow.buttons.list[1]:GetScript("OnClick")(plainWindow.buttons.list[1])
check(not plain:IsShown() and not plainWindow.edge.away and not plainBar:IsShown(), "its close button hides it: back at its size, without the bar")

-- A window that holds the game's protected frames, in a fight ---------------------------------------
wide:Hide() -- (they hold the left zone and the middle; a zone holds one window at a time)
trader:Hide()
local secure = CreateFrame("Frame", nil, UIParent)
local secureStore = { place = { x = 0, y = 690, width = 400, height = 300, dock = "LEFT", full = true } }
local secureWindow = Window.New(secure, {
    store = secureStore, title = "Spellbook", titleBar = true, sizable = true, dock = true, edge = W.HOVER,
    first = { point = "CENTER", x = 0, y = 0, width = 400, height = 300 },
})
secure._protected = true
at(secure, 0, 390)
secureWindow:Place()
check(not secureWindow:Locked() and secureWindow.zone == "LEFT", "out of a fight a protected window is placed as any other")
W.combat = true
secureStore.place.dock = "CENTER"
secureWindow:Place()
check(secureWindow:Locked() and secureWindow.zone == "LEFT", "in a fight it is not placed: nothing of ours moves it")
check(not secureWindow:Draggable() and not secureWindow.usable(), "nor dragged, nor sized")
secureWindow.edge:Fill(true)
check(not secureWindow.edge.full, "nor does it fill the screen")
-- Hidden by the game's own key in the fight (secure code, which the game does not block; the stand-in blocks
-- every call on a protected frame in one): the test lifts the fight around the game's own call.
W.combat = false; secure:Hide(); W.combat = true
check(secureWindow:Open() == "locked" and not secure:IsShown(), "asked for (the game's key), it says it may not be shown: the module lets the game's own")
W.combat = false
secure:Show()
W.Fire("PLAYER_REGEN_ENABLED")
check(secureWindow.zone == "CENTER", "the fight over, the placing it waited for is done")
at(secure, 760, 390)
secureWindow.edge:Fill(true)
secure._group:Run(0.3)
W.Fire("PLAYER_REGEN_DISABLED")
check(not secure._group.playing and secure._width == 1920 and secureWindow.edge.full,
    "a fight begins while it is on its way: it is at the end of the way at once, so nothing moves it in the fight")
secureWindow:Place()
secure:Hide()

-- A protected window Esc closes is not hidden in a fight: it closes once the fight is over
do
local guarded = CreateFrame("Frame", nil, UIParent)
local guardedClosed = 0
local guardedWindow = Window.New(guarded, {
    store = {}, title = "Spellbook", titleBar = true, escape = "close",
    first = { point = "CENTER", x = 0, y = 0, width = 400, height = 300 },
})
guardedWindow:Place()
guarded._protected = true
guarded:HookScript("OnHide", function() guardedClosed = guardedClosed + 1 end)
local guardStand = SaneUIEscape
W.combat = true
check(guardStand:IsShown(), "shown, Esc is ours for it")
guardStand:Hide()
check(guarded:IsShown() and guardedClosed == 0, "in a fight Esc does not hide it: nothing of ours hides it then")
W.Wait(0.1)
check(not guardStand:IsShown(), "and Esc is the game's again meanwhile: the stand-in would take every Esc of the fight")
local guardClose = guardedWindow.buttons.list[1]
guardClose:GetScript("OnClick")(guardClose)
check(guarded:IsShown() and guardedClosed == 0, "nor does its close button")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(not guarded:IsShown() and guardedClosed == 1, "the fight over, it closes, once")
W.Wait(0.1)
check(not guardStand:IsShown(), "and Esc stays the game's")
end

-- Esc closes a window made so, small or full, as the game's panels close
local talked = CreateFrame("Frame", nil, UIParent)
local talkStore, talkClosed = {}, 0
local talkWindow = Window.New(talked, {
    store = talkStore, title = "Vendor", titleBar = true, dock = true, edge = W.HOVER, escape = "close",
    first = { point = "CENTER", x = 0, y = 0, width = 400, height = 300 },
    close = function() talkClosed = talkClosed + 1; talked:Hide() end,
})
talkWindow:Place()
local stand = SaneUIEscape
local ours = 0
for _, name in ipairs(UISpecialFrames) do if name:find("^SaneUI") then ours = ours + 1 end end
check(stand and stand:IsShown() and ours == 1,
    "shown, a window Esc closes has the stand-in of ours shown, the one frame SaneUI puts into the game's list of what Esc closes")
stand:Hide()
check(talkClosed == 1 and not talked:IsShown(), "Esc: it closes, as its module says")
W.Wait(0.1)
check(not stand:IsShown(), "and the stand-in stays hidden while no such window is shown")
talked:Show()
at(talked, 760, 390)
talkWindow.edge:Fill(true)
talked._group:Run(1)
check(stand:IsShown(), "full, the same stand-in is shown")
local spare = CreateFrame("Frame", nil, UIParent)
local spareWindow = Window.New(spare, { store = {}, edge = W.HOVER, sizable = true,
    first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
spareWindow:Place()
at(spare, 860, 490)
stand:Hide()
check(talkClosed == 2 and not talked:IsShown() and talkStore.place.full == true,
    "Esc closes it full as it is: not made small first, so it opens full again")
spareWindow.edge:Fill(true)
spare._group:Run(1)
stand:Hide()
check(not spareWindow.edge.full and spareWindow.edge.away and spare:IsShown(), "and a full window Esc does not close goes back, by the same Esc")
spare._group:Run(1)
spare:Hide()
check(talkWindow:Open() == "ours" and talkWindow.edge.full, "the next time it is asked for, it is full again")
talkWindow:Place()

-- Reset keeps what a window was left as
talkStore.place.native = true
talkWindow:Reset()
check(talkStore.place and talkStore.place.full == true and talkStore.place.native == true and talkStore.place.x == nil,
    "reset, it is at its first place and size, and still opens as it was left")

-- Without the game's Edit Mode
check(Core.EditMode.available == false, "(this stand-in game has no Edit Mode manager)")
SlashCmdList.SANEUI("arrange")
check(Core.EditMode.active and talkWindow.box and talkWindow.box:IsShown(), "/sane arrange then gives our windows the same mode")
SlashCmdList.SANEUI("arrange")
check(not Core.EditMode.active and not talkWindow.box:IsShown(), "and closes it again")

-- Edit Mode hiding its frames' boxes for a while (a window over it), without leaving
local manager = { IsEditModeActive = function() return false end }
function manager:ShowSystemSelections() end
function manager:HideSystemSelections() end
rawset(_G, "EditModeManagerFrame", manager)
W.Fire("PLAYER_LOGIN")
check(Core.EditMode.available and not Core.EditMode.active, "a game with an Edit Mode: it is followed, /sane arrange is not needed")
EventRegistry:TriggerEvent("EditMode.Enter")
manager:HideSystemSelections()
check(not Core.EditMode.active and not talkWindow.box:IsShown(), "Edit Mode hides its boxes for a while: ours hide with them")
manager:ShowSystemSelections()
check(Core.EditMode.active and talkWindow.box:IsShown(), "and come back with them")
EventRegistry:TriggerEvent("EditMode.Exit")
check(not Core.EditMode.active and not talkWindow.box:IsShown(), "Edit Mode closed, they are gone")

-- The game's own frames' boxes: their blue frame too only under the mouse (EditMode.lua), the one chosen in sight
do
    local system = CreateFrame("Frame", nil, UIParent)
    local selection = CreateFrame("Frame", nil, system)
    system.Selection = selection
    NineSliceUtil.ApplyLayout(selection, { Center = true, TopEdge = true, BottomLeftCorner = true }, "editmode-actionbar-highlight")
    function selection:ShowHighlighted() self.isSelected = false end
    function selection:ShowSelected() self.isSelected = true end
    function selection:ShowEditInstructions(shown) self.instructionsShown = shown end
    manager.registeredSystemFrames = { system }
    local function Art() return selection.Center._alpha, selection.TopEdge._alpha, selection.BottomLeftCorner._alpha end
    check(Art() ~= 0, "before Edit Mode opens nothing of the game's box is touched")
    EventRegistry:TriggerEvent("EditMode.Enter")
    selection:ShowHighlighted()
    local center, edge, corner = Art()
    check(center == 0 and edge == 0 and corner == 0, "Edit Mode open: a frame of the game's without its blue frame")
    selection:ShowEditInstructions(true)
    check(Art() == 1 and select(3, Art()) == 1, "the mouse on its box: its blue frame")
    selection:ShowEditInstructions(false)
    check(Art() == 0, "the mouse gone: gone")
    selection:ShowSelected()
    check(Art() == 1, "chosen: its yellow frame stays in sight")
    selection:ShowHighlighted()
    check(Art() == 0, "another chosen: out of sight again")
    EventRegistry:TriggerEvent("EditMode.Exit")
    EventRegistry:TriggerEvent("EditMode.Enter")
    selection:ShowEditInstructions(true)
    selection:ShowEditInstructions(false)
    check(Art() == 0, "opened again: hooked once, followed as before")
    EventRegistry:TriggerEvent("EditMode.Exit")
    manager.registeredSystemFrames = nil
end

-- Chosen in Edit Mode: its box in the selected look, and a small dialog of Core's; free, it snaps to Edit
-- Mode's grid while the game snaps
do
    local grid = CreateFrame("Frame", nil, UIParent)
    grid.gridSpacing = 50
    local snapping = true
    manager.IsSnapEnabled = function() return snapping end
    manager.Grid = grid
    local picked = CreateFrame("Frame", nil, UIParent)
    local pickedStore = {}
    local pickedWindow = Window.New(picked, { store = pickedStore, title = "Auction House", dock = true, sizable = true,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    pickedWindow:Place()
    local small = CreateFrame("Frame", nil, UIParent)
    small.GetEffectiveScale = function() return 0.5 end -- half the screen's scale (Combat's unit frames)
    small:SetSize(200, 100)
    local smallStore = {}
    local smallWindow = Window.New(small, { store = smallStore, title = "Player", first = { point = "CENTER", x = 0, y = 0 } })
    smallWindow:Place()
    EventRegistry:TriggerEvent("EditMode.Enter")
    local pickedBox = pickedWindow.box
    pickedBox:GetScript("OnMouseDown")(pickedBox)
    local selection = Core.Selection
    local dialog = selection.window == pickedWindow and talkWindow.box.Center._atlas == "editmode-actionbar-highlight"
    local panel
    for _, widget in ipairs(W.frames) do
        if widget._parent == UIParent and widget._strata == "DIALOG" and rawget(widget, "reset") then panel = widget end
    end
    check(pickedBox.Center._alpha == 1 and talkWindow.box.Center._alpha == 0,
        "the one chosen keeps its yellow frame in sight, the others only under the mouse")
    check(dialog and pickedBox.Center._atlas == "editmode-actionbar-selected" and panel and panel:IsShown()
        and panel.title._text == "Auction House" and not panel.reset:IsEnabled() and panel._level == 200,
        "a click on its box in Edit Mode chooses it: the box in Edit Mode's selected look, a dialog of Core's that names it; at its first place, nothing to reset")
    at(picked, 113, 497)
    pickedBox:GetScript("OnDragStart")(pickedBox)
    pickedBox:GetScript("OnDragStop")(pickedBox)
    check(pickedStore.place.x == 110 and pickedStore.place.y == 690 and stands(picked, "TOPLEFT", 110, 690),
        "let go free near a line of Edit Mode's grid while the game snaps to it, its edges are put on the lines")
    check(panel.reset:IsEnabled(), "moved, the dialog can put it back")
    -- A window of another scale than the screen's is snapped in the screen's units (its edges where they are on
    -- the screen) and kept in its own: at 226, 994 of its own it stands at 113, 497 of the screen's
    picked:Hide() -- its edges would draw guide lines for this one (below): here the grid alone
    at(small, 226, 994)
    smallWindow.box:GetScript("OnDragStart")(smallWindow.box)
    smallWindow.box:GetScript("OnDragStop")(smallWindow.box)
    check(smallStore.place.x == 220 and smallStore.place.y == 1080 and stands(small, "TOPLEFT", 220, 1080),
        "a scaled window snaps where its edges are on the screen, and is kept in its own units")
    picked:Show()
    snapping = false
    at(picked, 113, 497)
    pickedBox:GetScript("OnDragStart")(pickedBox)
    pickedBox:GetScript("OnDragStop")(pickedBox)
    check(pickedStore.place.x == 113, "with the game's snapping off it stays where it was let go")
    panel.reset:GetScript("OnClick")(panel.reset)
    check(pickedStore.place == nil and picked._points[1][1] == "CENTER" and not panel.reset:IsEnabled(),
        "Reset To Default Position puts it at its first place and size")

    -- SaneUI's panel in Edit Mode, its two ticks, and the red guide lines while a window is dragged, as the game's own
    -- frames have them (Arrange.lua; Saneroki, 2026-11-18). A function of its own: the main chunk's locals.
    ;(function()
        local Arrange = Core.Arrange
        local snap = Arrange.Panel()
        check(snap and snap:IsShown() and snap.title._text == "SaneUI" and snap.corners:GetChecked() == true
            and snap.grid:GetChecked() == false, "Edit Mode open: SaneUI's panel, Snap to hot corners ticked, Snap to grid not")
        snapping = true
        small:Hide()
        local function Drag(left, bottom)
            at(picked, left, bottom)
            pickedBox:GetScript("OnDragStart")(pickedBox)
            Arrange.Look()
            return Arrange.Lines()
        end
        local function Drop() pickedBox:GetScript("OnDragStop")(pickedBox) end
        local lines = Drag(960 - 150 + 5, 300) -- its middle 5 right of the screen's
        check(lines.x:IsShown() and lines.x._points[1][4] == 960 and lines.x._texture[1] == 1 and lines.x._texture[2] == 0
            and lines.x._width > 0, "its middle near the screen's: a thin red line down the screen's middle")
        Drop()
        check(pickedStore.place.x == 810 and not Arrange.Lines().x:IsShown(), "let go: its middle on the screen's, the line gone")
        small:Show()
        at(small, 400, 200) -- half the screen's scale: its left at 200 of the screen's
        lines = Drag(203, 300)
        check(lines.x:IsShown() and lines.x._points[1][4] == 200, "near another window's left edge: a line along it")
        Drop()
        check(pickedStore.place.x == 200, "let go: on it")
        small:Hide()
        local system = CreateFrame("Frame", nil, UIParent) -- a frame of the game's in Edit Mode, with its box
        system._left, system._bottom, system._width, system._height = 1500, 700, 100, 100
        system.Selection = CreateFrame("Frame", nil, system)
        manager.registeredSystemFrames = { system }
        lines = Drag(1500 - 300 - 4, 300)
        check(lines.x:IsShown() and lines.x._points[1][4] == 1500, "its right edge near a frame of the game's: a line along that frame's left")
        Drop()
        check(pickedStore.place.x == 1200, "let go: beside it")
        manager.registeredSystemFrames = nil
        snapping = false
        lines = Drag(815, 300)
        check(not lines.x:IsShown(), "the game's Snap off: no lines, as the game's own frames")
        Drop()
        check(pickedStore.place.x == 815, "and it stays where it was let go")
        snap.grid:SetChecked(true)
        snap.grid:GetScript("OnClick")(snap.grid)
        check(Core.general.snapGrid == true, "Snap to grid ticked: kept in Core's settings")
        Drag(833, 300)
        Drop()
        check(pickedStore.place.x == 810 and pickedStore.place.y == 490,
            "Snap to grid: let go anywhere, onto the nearest lines of the grid, the game's Snap off and all")
        snap.grid:SetChecked(false)
        snap.grid:GetScript("OnClick")(snap.grid)
        Drag(1920 - 300 - 5, 3)
        Drop()
        check(pickedStore.place.dock == "BOTTOMRIGHT", "near the screen's lower right corner it docks there")
        snap.corners:SetChecked(false)
        snap.corners:GetScript("OnClick")(snap.corners)
        Drag(1920 - 300 - 5, 3)
        Drop()
        check(Core.general.snapCorners == false and pickedStore.place.dock == nil and pickedStore.place.x == 1615,
            "Snap to hot corners off: it stays exactly where it was let go")
        Core.Set(Core.name, "snapCorners", true)
        check(snap.corners:GetChecked() == true, "set elsewhere: the tick follows")
        panel.reset:GetScript("OnClick")(panel.reset)
    end)()

    -- A window with a hot corner: its module's Can expand to fullscreen, Hotcorner and Hotcorner requires leftclick in
    -- its dialog, and its key (Selection.lua; Saneroki, 2026-11-18).
    ;(function()
        local list = {}
        Core.Edge.Options(list, 1)
        Core.Options("Lantern", list)
        local settings = Core.Settings("Lantern")
        local lantern = CreateFrame("Frame", nil, UIParent)
        lantern:SetSize(200, 200)
        local lanternWindow = Window.New(lantern, { store = {}, title = "Lantern", edge = settings, binding = "SANEUI_LANTERN",
            first = { dock = "TOPRIGHT" } })
        lanternWindow:Place()
        EventRegistry:TriggerEvent("EditMode.Exit")
        EventRegistry:TriggerEvent("EditMode.Enter")
        lanternWindow.box:GetScript("OnMouseDown")(lanternWindow.box)
        local rows = Core.Selection.Extra(lanternWindow)
        check(#rows == 4 and rows[1].key == "expand" and rows[1].text == Core.Described("Lantern", "expand").text
            and rows[2].key == "expandCorner" and rows[2].text == "Hotcorner" and rows[2].parent == "expand"
            and rows[3].key == "expandClick" and rows[3].parent[2] == "expandCorner" and rows[4].binding == "SANEUI_LANTERN",
            "its dialog: Can expand to fullscreen, Hotcorner under it, requires leftclick under that, then its key")
        local made = lanternWindow.settingRows
        check(made and made:IsShown() and #made.shows == 4, "the rows made as it is chosen")
        local function Box(index)
            for _, widget in ipairs(W.frames) do
                if widget._template == "UICheckButtonTemplate" and widget._parent and widget._parent._parent == made then
                    index = index - 1
                    if index == 0 then return widget end
                end
            end
        end
        local corner, click = Box(2), Box(3)
        check(corner:GetChecked() == true and click:IsEnabled(), "at first the hot corner on, its left click open")
        corner:SetChecked(false)
        corner:GetScript("OnClick")(corner)
        check(settings.expandCorner == false and not click:IsEnabled(), "Hotcorner off: set in the module's settings, its left click greyed out")
        Core.Set("Lantern", "expandCorner", true)
        lantern:Hide()
        Core.Selection.Clear()
    end)()
    talkWindow.box:GetScript("OnMouseDown")(talkWindow.box)
    check(selection.window == talkWindow and pickedBox.Center._atlas == "editmode-actionbar-highlight"
        and talkWindow.box.Center._atlas == "editmode-actionbar-selected" and panel.title._text == "Vendor",
        "another chosen, the first is not any more")
    check(pickedBox.Center._alpha == 0 and talkWindow.box.Center._alpha == 1, "its yellow frame goes to the one chosen now")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(not panel:IsShown() and selection.window == nil and talkWindow.box.Center._atlas == "editmode-actionbar-highlight",
        "Edit Mode closed, nothing is chosen and the dialog is gone")
    check(not Core.Arrange.Panel():IsShown(), "and SaneUI's panel with it")
    picked:Hide()
    small:Hide()
    manager.IsSnapEnabled, manager.Grid = nil, nil
end
rawset(_G, "EditModeManagerFrame", nil)

-- One window to a zone at a time (Saneroki, 2026-10-16)
secure:Hide() -- (it holds the middle)
local zoneStore = { a = { x = 810, y = 640, dock = "CENTER" }, b = { x = 810, y = 640, dock = "CENTER" } }
local one, two = CreateFrame("Frame", nil, UIParent), CreateFrame("Frame", nil, UIParent)
one:SetSize(300, 200)
two:SetSize(300, 200)
local oneWindow = Window.New(one, { store = zoneStore, key = "a", title = "Vendor", dock = true, first = { point = "CENTER", x = 0, y = 0 } })
local twoWindow = Window.New(two, { store = zoneStore, key = "b", title = "Bank", dock = true, first = { point = "CENTER", x = 0, y = 0 } })
oneWindow:Place()
twoWindow:Place()
check(oneWindow.zone == "CENTER" and twoWindow.zone == nil and stands(two, "TOPLEFT", 810 + Window.CASCADE, 640 - Window.CASCADE)
    and zoneStore.b.dock == "CENTER",
    "a zone holds one window at a time: the second opens free, a step aside of the first so it covers none of it; its zone kept for the next time")
one:Hide()
twoWindow:Place()
check(twoWindow.zone == "CENTER", "a window not shown holds nothing: the talk windows share the middle")
one:Show()
check(oneWindow.zone == nil and stands(one, "TOPLEFT", 810 + Window.CASCADE, 640 - Window.CASCADE) and zoneStore.a.dock == "CENTER",
    "shown again while another holds its zone, it stands free this time, clear of it")
do
local three = CreateFrame("Frame", nil, UIParent)
three:SetSize(300, 200)
local threeWindow = Window.New(three, { store = { place = { x = 810, y = 640, dock = "CENTER" } }, title = "Trainer", dock = true,
    first = { point = "CENTER", x = 0, y = 0 } })
threeWindow:Place()
check(stands(three, "TOPLEFT", 810 + 2 * Window.CASCADE, 640 - 2 * Window.CASCADE),
    "a third one there stands a step further aside: a step for every window of ours that starts where it would")
three:Hide()
local corner = CreateFrame("Frame", nil, UIParent)
corner:SetSize(300, 200)
local cornerWindow = Window.New(corner, { store = { place = { x = 1620, y = 200, dock = "CENTER" } }, title = "Bank", dock = true,
    first = { point = "TOP", x = 0, y = -50 } })
local cornerOther = Window.New(CreateFrame("Frame", nil, UIParent), { store = { place = { x = 1620, y = 200 } }, title = "Other",
    first = { point = "CENTER", x = 0, y = 0 } })
cornerOther:Place()
cornerWindow:Place()
check(stands(corner, "TOP", 960, 1030), "where no step aside stays on the screen, it stands at its first place")
corner:Hide()
cornerOther.frame:Hide()
end
EventRegistry:TriggerEvent("EditMode.Enter")
local oneBox = oneWindow.box
oneBox:GetScript("OnDragStart")(oneBox)
at(one, 810, 440)
watcher:GetScript("OnUpdate")(watcher)
check(one._moving and not ghost:IsShown(), "dragged onto the zone another window holds, no shape shows there")
oneBox:GetScript("OnDragStop")(oneBox)
check(oneWindow.zone == nil and zoneStore.a.dock == nil, "let go there it does not dock: it stands free")
oneBox:GetScript("OnDragStart")(oneBox)
at(one, 1610, 870)
watcher:GetScript("OnUpdate")(watcher)
check(ghost:IsShown(), "a zone nobody holds is offered as before")
oneBox:GetScript("OnDragStop")(oneBox)
check(oneWindow.zone == "TOPRIGHT" and zoneStore.a.dock == "TOPRIGHT", "and it docks there")
EventRegistry:TriggerEvent("EditMode.Exit")
one:Hide()
two:Hide()

-- Kinds of window
local kindFrame = CreateFrame("Frame", nil, UIParent)
local kindWindow = Window.New(kindFrame, { store = {}, kind = "panel", title = "Guild", sizable = false,
    first = { point = "CENTER", x = 0, y = 0 } })
local given = kindWindow.options
check(given.titleBar and given.dock and given.skin and given.edge and given.escape == "close" and kindWindow.skin and kindWindow.edge,
    "a kind gives a window its options: a panel has a title bar, a skin, full screen, Esc closes it")
check(given.sizable == false and kindWindow.grip == nil, "what the module gives itself wins")
check(kindFrame._toplevel and kindFrame._mouse, "a panel comes to the front when clicked, as the game's own panels do, and takes the click")

-- A grip that sizes the window outside Edit Mode too (grip = "hover", the minimap's): there while the window rests
-- in its zone, seen while the mouse is on the window or on the grip, gone while its module says no.
do
    local miniFrame, miniStore, allowed = CreateFrame("Frame", nil, UIParent), {}, true
    local mini = Window.New(miniFrame, { store = miniStore, kind = "screen", title = "Map", grip = "hover",
        first = { dock = "TOPRIGHT", width = 200, height = 200 }, minWidth = 100, minHeight = 100,
        usable = function() return allowed end })
    mini:Place()
    check(mini.grip:IsShown() and mini.grip._alpha == 0 and mini.grip.corner == "BOTTOMLEFT",
        "outside Edit Mode its grip is there, unseen, in the corner away from the screen's")
    mini:Hover(true)
    check(mini.grip._alpha == 1, "the mouse on the window: the grip is seen")
    mini:Hover(false)
    mini.grip._mouseOver = true
    mini.grip:GetScript("OnEnter")(mini.grip)
    check(mini.grip._alpha == 1 and W.cursorArt == "UI_RESIZE_CURSOR", "on the grip itself: seen, the mouse shows what it does")
    mini.grip:GetScript("OnMouseDown")(mini.grip)
    check(miniFrame._sizing == "BOTTOMLEFT", "and it sizes the window outside Edit Mode")
    miniFrame._width, miniFrame._height = 260, 240
    mini.grip:GetScript("OnMouseUp")(mini.grip)
    check(miniStore.place.width == 260 and miniStore.place.height == 240 and miniStore.place.dock == "TOPRIGHT"
        and mini.zone == "TOPRIGHT", "the new size is kept, and it is still docked")
    mini.grip._mouseOver = false
    mini.grip:GetScript("OnLeave")(mini.grip)
    check(mini.grip._alpha == 0, "the mouse gone: unseen again")
    allowed = false
    mini:Hover(true)
    check(not mini.grip:IsShown(), "while its module says no (resting out of sight), no grip")
    miniFrame:Hide()
end
traderWindow:SetTitle("Merchant")
check(traderWindow.bar.title._text == "Merchant" and traderWindow.box.title._text == "Merchant" and traderWindow.options.title == "Merchant",
    "a window's name can be set anew: on its title bar and on its box in Edit Mode")
check(Window.KINDS.screen.titleBar == nil and Window.KINDS.screen.skin == nil and Window.KINDS.talk.escape == "close",
    "the chat's kind has no title bar and no skin; a talk closes with Esc")
kindFrame:Hide()
do
local talkFrame = CreateFrame("Frame", nil, UIParent)
local talkKindStore = {}
local talkKind = Window.New(talkFrame, { store = talkKindStore, kind = "talk", title = "Vendor",
    first = { width = 400, height = 300 } })
talkKind:Place()
check(talkKind.zone == "CENTER" and stands(talkFrame, "CENTER", 960, 540) and talkKind.options.first.width == 400 and talkKindStore.place == nil,
    "a talk window stands docked in the middle at first, at the size its module gives it")
check(Window.KINDS.talk.first.width == nil, "(the kind's own first place is not changed by a module's)")
skinned:Hide() -- (it holds the lower left corner)
local chatFrame = CreateFrame("Frame", nil, UIParent)
local chatStore = {}
local chatKind = Window.New(chatFrame, { store = chatStore, kind = "screen", title = "Chat",
    first = { dock = "BOTTOMLEFT", width = 380, height = 260 } })
chatKind:Place()
check(chatKind.zone == "BOTTOMLEFT" and stands(chatFrame, "BOTTOMLEFT", 0, 0), "a window can start docked: its first place is a zone")
chatStore.place = { x = 500, y = 600 }
chatKind:Place()
chatKind:Reset()
check(chatKind.zone == "BOTTOMLEFT" and chatStore.place == nil, "reset, it is docked in its first zone again")
talkFrame:Hide()
chatFrame:Hide()
end

-- A window that keeps a room from the screen's edges
do
    local room = { right = 10, top = 20 }
    local inset = CreateFrame("Frame", nil, UIParent)
    local insetStore = { place = { x = 0, y = 0, width = 300, height = 200, dock = "TOPRIGHT" } }
    local insetWindow = Window.New(inset, { store = insetStore, sizable = true, dock = true, edge = W.HOVER, insets = room,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    insetWindow:Place()
    check(stands(inset, "TOPRIGHT", 1910, 1060), "docked, a window with insets keeps that room from the edges it touches")
    local left, low = Dock.Rect("TOPRIGHT", 300, 200, 1920, 1080, room)
    check(left == 1610 and low == 860 and Dock.Find(1610, 860, 300, 200, 1920, 1080, nil, room) == "TOPRIGHT"
        and Dock.Rect("TOPRIGHT", 300, 200, 1920, 1080) == 1620, "its zone's place counts that room; without insets it is flush")
    local square = insetWindow.edge.strips.corner
    check(square._points[1][1] == "TOPRIGHT" and square._points[1][4] == 10 and square._points[1][5] == 20,
        "the square the mouse fills the screen from lies in the screen's very corner, out of the window by that room")
    W.Wait(1)
    at(inset, 1610, 860)
    square:GetScript("OnEnter")(square)
    inset._group:Run(1)
    W.Wait(1)
    square:GetScript("OnEnter")(square)
    check(insetWindow.edge.to[1] == 1610 and insetWindow.edge.to[2] == 860, "and its way back from full screen ends at that room from the edges")
    inset._group:Run(1)
    check(stands(inset, "TOPRIGHT", 1910, 1060), "where it hangs again")
    inset:Hide()
end

-- The holder: ours or the game's, never both -------------------------------------------------------
do
    local game = CreateFrame("Frame", "TestFriendsFrame", UIParent)
    game:Hide()
    game:SetFrameStrata("MEDIUM")
    game:SetFrameLevel(7)
    local ours = CreateFrame("Frame", nil, UIParent)
    ours:Hide()
    local oursStore, shows, backs = {}, 0, 0
    local held = Window.New(ours, { store = oursStore, kind = "panel", title = "Friends", sizable = false,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 300 },
        native = { frame = game, hold = true, show = function() shows = shows + 1 end, back = function() backs = backs + 1 end } })
    local holder = held.holder
    local box = game._parent
    check(holder and holder.held and box ~= UIParent and not box:IsShown(), "while ours is chosen the game's window has a hidden frame of ours as its parent")
    game:Show()
    check(game:IsShown() and not game:IsVisible() and ours:IsShown(), "the game opens its window: it counts as shown but is not in sight; ours opens instead")
    game:Hide()
    check(not ours:IsShown() and holder.held, "the game closes it: ours closes, the game's stays held")
    game:Show()
    held:Native(true)
    check(game._parent == UIParent and game:IsVisible() and not ours:IsShown() and shows == 1 and oursStore.place.native == true
        and not holder.held and game._strata == "MEDIUM" and game._level == 7,
        "switched to the game's: its window is back where it was and as it was, in sight; ours closes")
    game:Hide()
    game:Show()
    check(game:IsVisible() and not ours:IsShown(), "the game's chosen, the game opens it as always")
    held:Native(false)
    check(ours:IsShown() and game:IsShown() and game._scale == Core.Holder.TINY and game._alpha == 0 and holder.shrunk and backs == 1,
        "back to ours while the game's is open: ours opens at once, the game's is made tiny and clear, not hidden")
    game:Hide()
    check(game._scale == 1 and game._alpha == 1 and holder.held and game._parent == box and not ours:IsShown(),
        "the game closes it: it is as it was, and held again")
    game:Show()
    ours:Hide()
    check(not game:IsShown() and holder.held, "ours closed while the game's is held open: the game's closes too, unseen")
    held.options.native.unseen = true
    game:Show()
    held:Native(true)
    check(game._parent == UIParent and not game:IsShown(), "a window whose own opening must not run from ours is closed unseen first, then given back")
    held.options.native.unseen = nil
    held:Native(false)
    check(holder.held and ours:IsShown(), "(held again, ours open)")
    held.options.native.frame = function() error("gone") end
    game:Hide()
    check(holder.off and game._parent == UIParent and Core.errors["window holder"],
        "a step of the holder that fails gives the game's window back at once, and it is held no more")
    Core.errors["window holder"] = nil
    held:GiveBack()
    ours:Hide()
end

-- Fuzzy finding, for the search ------------------------------------------------------------------------
local Fuzzy = Core.Fuzzy
local spots = {}
local whole, front, start, initials, inside, spread = Fuzzy.Rank("darnassus", "Darnassus"), Fuzzy.Rank("iron", "Ironforge"),
    Fuzzy.Rank("city", "Stormwind City"), Fuzzy.Rank("tb", "Thunder Bluff"), Fuzzy.Rank("forge", "Ironforge"), Fuzzy.Rank("gsr", "Goldshire")
check(whole == 690 and front > start and start > initials and initials > inside and inside > spread and spread >= 100,
    "a rank says how the word was found: the whole text, its beginning, a word's beginning, the first letters, inside, spread out")
check(math.floor(front / 100) == 5 and math.floor(start / 100) == 4 and math.floor(initials / 100) == 3 and math.floor(inside / 100) == 2
    and math.floor(spread / 100) == 1, "each kind in hundreds of its own, a close fit adding less than a hundred")
check(Fuzzy.Rank("xyz", "Ironforge") == nil and Fuzzy.Rank("rsg", "Goldshire") == nil, "letters it has not, or not in that order: nothing")
check(Fuzzy.Rank("tb", "Thunder Bluff", nil, spots) and spots[1] == 1 and spots[2] == 9 and spots[3] == nil,
    "the first letters of its words, and where they are")
check(Fuzzy.Rank("sg", "Stormwind Old Gate", nil, spots) and spots[2] == 15, "a word may be left out between them")
check(Fuzzy.Rank("hs", "Hero's Shield", nil, spots) and spots[2] == 8 and Fuzzy.Rank("lf", "LootFrame", nil, spots) and spots[2] == 5,
    "an apostrophe belongs to its word; a capital after a small letter starts one")
check(Fuzzy.Rank("ab", "axaxb", nil, spots) and spots[1] == 3 and spots[2] == 5, "letters spread out are taken as close together as they come")
check(Fuzzy.Rank("gate", "Old Gate Road") > Fuzzy.Rank("gate", "Old Mill Gate") and Fuzzy.Rank("bay", "Booty Bay") > Fuzzy.Rank("bay", "Booty Bay Docks"),
    "of the same kind, found earlier and in a shorter text ranks higher")
check(Fuzzy.Match(Fuzzy.Query("ston gate"), "Stonewall Gate", "Redridge") and not Fuzzy.Match(Fuzzy.Query("ston xyz"), "Stonewall Gate")
    and Fuzzy.Query("  ") == nil, "every word typed must be found, in one of the texts; nothing typed is no search")
check(Fuzzy.Match(Fuzzy.Query("iron gate"), "Ironforge", "Old Mill Gate") == Fuzzy.Rank("iron", "Ironforge") + Fuzzy.Rank("gate", "Old Mill Gate"),
    "the words' ranks add up, each from the text it fits best")
local gold = rawget(_G, "NORMAL_FONT_COLOR")
NORMAL_FONT_COLOR = { WrapTextInColorCode = function(_, text) return "<" .. text .. ">" end }
check(Fuzzy.Highlight("a|b", { 2 }) == "a<||>b" and Fuzzy.Highlight("Gate", { 1, 2 }) == "<Ga>te",
    "the letters found in the game's gold, a run of them in one piece; a | of the text is doubled")
check(Fuzzy.Highlight("Caf\195\169s", { 4 }) == "Caf<\195\169>s" and Fuzzy.Highlight("Caf\195\169s", { 5 }) == "Caf<\195\169>s",
    "a letter of two bytes is marked whole, by either byte")
NORMAL_FONT_COLOR = gold
local same = true
for _, case in ipairs({ { "rge", "Ironforge" }, { "gsr", "Goldshire" }, { "tb", "Thunder Bluff" }, { "ab", "axaxb" }, { "wind", "Stormwind City" } }) do
    if Fuzzy.Rank(case[1], case[2]) ~= Fuzzy.Rank(case[1], case[2], nil, {}) then same = false end
end
check(same, "the rank alone (no tables made) is the rank with the spots")

-- A list filtered by the search, a long one a part per frame
do
    local rows = {}
    for index = 1, 30 do rows[index] = { name = index % 3 == 0 and "Stormwind Guard" or "Goldshire Farmer", zone = "Elwynn" } end
    local got, ranked
    Fuzzy.Filter(rows, "guard", { "name", "zone" }, function(found, ranks) got, ranked = found, ranks end)
    check(got and #got == 10 and got[1] == rows[3] and ranked[1] == Fuzzy.Rank("guard", "Stormwind Guard"),
        "a short list is filtered at once: the rows every word is in, in their order, with their ranks")
    Fuzzy.Filter(rows, "elw farm", { "name", function(row) return row.zone end }, function(found) got = found end)
    check(#got == 20, "every word in one of the fields: a key, or what a function says of the row")
    rows[1].name = "Stormwind Guard"
    Fuzzy.Filter(rows, "guard", { "name" }, function(found) got = found end)
    check(#got == 11 and got[1] == rows[1], "a row whose text changed is found by its new text")
    Fuzzy.Filter(rows, nil, { "name" }, function(found) got = found end)
    check(#got == 30, "nothing typed: every row")

    local long = {}
    for index = 1, 500 do long[index] = { name = index == 500 and "Thunder Bluff" or "Ironforge " .. index } end
    local clock, frames = debugprofilestop, 0
    debugprofilestop = function() W.ms = W.ms + 0.05; return W.ms end -- every look takes its time
    local older, newer
    local jobs = #Core.Steps.Jobs() -- Core's own since the login (the characters read)
    Fuzzy.Filter(long, "iron", { "name" }, function(found) older = found end)
    check(older == nil and #Core.Steps.Jobs() == jobs + 1, "a long list is not filtered in the call: it is a job of the scheduler")
    local step = Core.Steps.frame:GetScript("OnUpdate")
    step()
    frames = frames + 1
    Fuzzy.Filter(long, "tb", { "name" }, function(found) newer = found end)
    while #Core.Steps.Jobs() > 0 and frames < 100 do
        step()
        frames = frames + 1
    end
    debugprofilestop = clock
    check(newer and #newer == 1 and newer[1] == long[500] and frames > 2, "it is filtered a part per frame, and told once it is done")
    check(older == nil, "a newer search makes the older one stop: its rows never come")
end

-- The keys over a fly-out: Up and Down light a find as the mouse would, round at the ends; Enter takes the lit one
do
    local box, told, rows = CreateFrame("EditBox", nil, UIParent), {}, {}
    for index = 1, 3 do
        local row = CreateFrame("Button", nil, UIParent)
        row.LockHighlight = function(self) self.held = true end
        row.UnlockHighlight = function(self) self.held = false end
        row.Click = function(self) self:GetScript("OnClick")(self, "LeftButton", false) end
        row:SetScript("OnEnter", function() told[#told + 1] = "tip " .. index end)
        row:SetScript("OnLeave", function() told[#told + 1] = "gone " .. index end)
        row:SetScript("OnClick", function() told[#told + 1] = "took " .. index end)
        rows[index] = row
    end
    local keys = Fuzzy.Keys(box)
    local function Arrow(key) box:GetScript("OnArrowPressed")(box, key) end
    Arrow("DOWN")
    check(keys:Take() == false and #told == 0, "no finds shown: the arrows light nothing, Enter takes nothing")
    keys:Rows(rows)
    Arrow("DOWN")
    check(rows[1].held and told[1] == "tip 1", "Down: the first lit, its tooltip shown as the mouse on it shows it")
    Arrow("DOWN")
    Arrow("DOWN")
    Arrow("DOWN")
    check(rows[1].held and not rows[3].held and told[#told] == "tip 1" and told[#told - 1] == "gone 3",
        "Down on the last: round to the first, the last's tooltip gone")
    Arrow("UP")
    check(rows[3].held and not rows[1].held, "Up on the first: round to the last")
    Arrow("LEFT")
    check(rows[3].held and told[#told] == "tip 3", "Left and Right are the cursor's")
    check(keys:Take() == true and told[#told] == "took 3", "Enter: the lit one, as a click on it")
    keys:Rows(nil)
    check(not rows[3].held and told[#told] == "gone 3" and keys:Take() == false, "the finds gone: nothing lit")
    keys:Rows(rows)
    Arrow("UP")
    check(rows[3].held, "Up with none lit: the last, next to the box when the finds fly out over it")
    keys:Rows(rows)
    check(not rows[3].held and keys:Take() == false, "new finds: none lit, Enter does what the box's own does")
end

-- The bar ----------------------------------------------------------------------------------------------
STATUS_BAR_NUM_SEGMENTS = 8 -- the pieces the game cuts its own bar into
local counted = {}
local bar = Bar.New(UIParent, { width = 200, height = 14, moved = function(value) counted[#counted + 1] = value end })
STATUS_BAR_NUM_SEGMENTS = nil
local rise = bar.frame._groups[1]
check(bar.filled._bar == Bar.ART.fill and bar.coming._bar == Bar.ART.ahead and bar.filled._level > bar.coming._level,
    "the game's own experience bar: its fill over the part still to come")
check(#bar.dividers == 7 and bar.dividers[1]._atlas == Bar.ART.divider and bar.dividers[1]._points[1][4] == 25
    and bar.dividers[1]._width == 14 * 0.3, "the game's dividers cut it into as many pieces as the game cuts its own bar into")
bar:SetValue(500, 1000, 250)
check(bar.filled._value == 0.5 and bar.coming._value == 0.75 and not rise.playing and counted[1] == 500,
    "a bar's first value is there at once, the part still to come after it")
check(bar.pip:IsShown() and bar.pip._atlas == Bar.ART.pip and bar.pip._points[1][4] == 150 and near(bar.pip._width, 10) and bar.pip._height == 14,
    "the game's pip marks where that part ends, as large as the game draws it on a bar this high")
bar:SetValue(800, 1000, 100)
local seconds = Bar.RISE + (Bar.RISE_WHOLE - Bar.RISE) * 0.3
check(rise.playing and near(rise.duration, seconds) and bar.flare:IsShown() and bar.flaring.playing and near(bar.flaring.duration, seconds),
    "a gain rises, for longer the more was gained, the game's flare running with it")
check(near(bar.coming._value, 0.9), "what is still to come is at its new place at once")
rise:Run(0.2)
check(bar.filled._value > 0.5 and bar.filled._value < 0.8 and counted[#counted] > 500 and counted[#counted] < 800
    and near(bar.flare._points[1][4], 200 * bar.shown + 1), "on its way the fill rises, the number counts along, the flare at its end")
do
    local laid, divider = 0, bar.dividers[1]
    divider.SetPoint = function(self, ...) laid = laid + 1; return methods.SetPoint(self, ...) end
    rise:Run(0.3)
    check(laid == 0 and bar.pip._points[1][4] == 180, "on every step only the fill and its flare move: the dividers and the pip stay as they are")
    divider.SetPoint = nil
end
rise:Run(1)
check(bar.filled._value == 0.8 and not bar.flare:IsShown() and counted[#counted] == 800, "and settles at its value")
bar:SetValue(850, 1000)
check(rise.playing and near(rise.duration, Bar.RISE + (Bar.RISE_WHOLE - Bar.RISE) * 0.05) and rise.duration < seconds and not bar.pip:IsShown(),
    "a small gain is quick; with nothing still to come there is no pip")
rise:Run(1)
bar:SetValue(100, 2000)
check(not rise.playing and bar.filled._value == 0.05, "a loss (a new level) is there at once")
bar:SetValue(0, 0)
check(bar.filled._value == 1, "with nothing more to reach it is full")
Core.general.motion = "off"
bar:SetValue(100, 1000)
bar:SetValue(200, 1000)
check(not rise.playing and bar.filled._value == 0.2, "with the motion Instant a gain is there at once too")
Core.general.motion = "glide"
check(#Bar.New(UIParent, { segments = 1 }).dividers == 0, "one piece: no dividers")
do -- a client without the dividers' art (Retail): a thin dark line of ours for each
    local texture = rawget(_G, "C_Texture")
    C_Texture = { GetAtlasInfo = function(name) if name ~= Bar.ART.divider then return {} end end }
    local plain = Bar.New(UIParent, { segments = 4 }).dividers
    check(#plain == 3 and plain[1]._atlas == nil, "without the dividers' art, each divider is a line of ours")
    C_Texture = texture
end
do
local told = Bar.New(UIParent, { moved = function() error("the module's own") end })
told:SetValue(5, 10)
check(told.filled._value == 0.5 and Core.errors.bar, "a module's hook that fails is noted; the bar shows its value all the same")
Core.errors.bar = nil
end
local sizer = bar.frame._groups[2]
bar:SetSize(302, 16)
check(sizer.playing, "a new size moves there")
sizer:Run(1)
check(bar.frame._width == 302 and bar.frame._height == 16, "and ends at it")

-- The window to try it all with -------------------------------------------------------------------
W.Fire("PLAYER_LOGIN")
before = #W.frames
SlashCmdList.SANEUI("window")
do
    local demo = W.frames[before + 1]
    check(demo._parent == UIParent and demo:IsShown() and demo._points[1][1] == "CENTER" and demo._group, "/sane window makes a window to try it with")
    local demoWindow
    for _, known in ipairs(Window.All()) do if known.frame == demo then demoWindow = known end end
    check(demoWindow and demoWindow.options.kind == "panel" and demoWindow.options.escape == "close" and demoWindow.bar:IsShown()
        and demo._mouse and demoWindow.top == Window.BAR + Core.Look.BAND
        and demoWindow.inside._points[1][5] == -(Window.BAR + Core.Look.BAND),
        "a panel: its title bar, Esc closes it, a click on it is its own; what it holds stands under the bar (window.inside), inside the bronze band")
    local tabs, views = demoWindow.tabs, demoWindow.views
    check(tabs and #tabs.tabs == 2 and tabs.tabs[1]._text == "Window" and tabs.selected == 1 and views[1] and views[1]:IsShown() and not views[2]
        and views[1]._parent == demoWindow.inside and views[1]._points[1][5] == -Window.TABS,
        "two views behind the game's tabs, on top of them: the first chosen, built and shown, the second not built yet")
    local own = demoWindow.buttons.list[3]
    check(#demoWindow.buttons.list == 5 and demoWindow.buttons.first == own and own._points[1][2] == demoWindow.full,
        "a button of its module's own, left of Core's (the options and the question mark only on its full screen)")
    local keepBox, demoWatch
    for index = before + 1, #W.frames do
        local widget = W.frames[index]
        if widget._kind == "CheckButton" and widget.Text and widget.Text._text == "Keep open" then keepBox = widget end
        if widget._parent == demo and widget._scripts.OnUpdate then demoWatch = widget end
    end
    check(keepBox and keepBox._parent == views[1] and demoWatch, "the first view: a box Keep open")
    demo._mouseOver = true
    demo:GetScript("OnEnter")(demo)
    demoWatch:GetScript("OnUpdate")(demoWatch, 1)
    check(demo._width == 380 or demo._group.playing, "the mouse rests on it: it opens")
    demo._group:Run(1)
    keepBox:SetChecked(true)
    keepBox:GetScript("OnClick")(keepBox)
    demo._mouseOver = false
    demoWatch:GetScript("OnUpdate")(demoWatch, 5)
    check(demo._width == 380 and not demoWatch:IsShown(), "Keep open keeps it open when the mouse goes")
    local made = #W.frames
    tabs.tabs[2]:GetScript("OnClick")(tabs.tabs[2])
    local addButton, demoFill
    for index = made + 1, #W.frames do
        local widget = W.frames[index]
        if widget._kind == "Button" and widget._text == "Add" then addButton = widget end
        if widget._kind == "StatusBar" and widget._bar == Bar.ART.fill then demoFill = widget end
    end
    check(views[2] and views[2]:IsShown() and not views[1]:IsShown() and tabs.selected == 2 and addButton and demoFill
        and W.DemoPlace().tab == 2, "the second tab: its view is built now, and shown; the tab chosen is kept")
    addButton:GetScript("OnClick")(addButton)
    demoFill._parent._groups[1]:Run(1)
    check(demoFill._value == 0.15, "Add fills the bar a step")
    for _ = 1, 6 do addButton:GetScript("OnClick")(addButton) end
    demoFill._parent._groups[1]:Run(1)
    check(demoFill._value == 1, "up to full")
    addButton:GetScript("OnClick")(addButton)
    check(demoFill._value == 0, "and full, it starts again from nothing, at once")
    addButton:GetScript("OnClick")(addButton)
    demoFill._parent._groups[1]:Run(1)
    own:GetScript("OnClick")(own)
    check(demoFill._value == 0, "the module's button starts it again too")
    tabs.tabs[1]:GetScript("OnClick")(tabs.tabs[1])
    keepBox:SetChecked(false)
    keepBox:GetScript("OnClick")(keepBox)
    demo._group:Run(1)
    check(demo._width == 260, "let go with the mouse away, it closes")
    SlashCmdList.SANEUI("window")
    check(not demo:IsShown(), "typed again it hides it")
    SlashCmdList.SANEUI("window reset")
    check(demo:IsShown() and W.DemoPlace() == nil, "and reset shows it at its first place (its first tab is no more to keep)")
    W.printed = {}
    at(demo, 100, 100)
    demoWindow.bar:GetScript("OnDragStart")(demoWindow.bar)
    demoWindow.bar:GetScript("OnDragStop")(demoWindow.bar)
    check(W.DemoPlace().x == 100, "(moved)")
    SlashCmdList.SANEUI("window reset all")
    check(W.DemoPlace() == nil and demo._points[1][1] == "CENTER" and W.printed[1]:find("first place"),
        "/sane window reset all puts every window of SaneUI at its first place and size")
    check(next(Core.errors) == nil, "nothing went wrong on the way")
end

-- SaneUI's keys -----------------------------------------------------------------------------------
do
    local file = assert(io.open(root .. "/src/Core/Bindings.xml", "r"))
    local xml = file:read("*a")
    file:close()
    local keys = 0
    for name, category, body in xml:gmatch('<Binding name="([%w_]+)" category="([%w_]+)">(.-)</Binding>') do
        keys = keys + 1
        check(category == "BINDING_HEADER_SANEUI" and type(_G[category]) == "string" and type(_G["BINDING_NAME_" .. name]) == "string",
            "a key of SaneUI's is in its section of the game's key bindings, named in the game's way: " .. name)
        W.options.opened = nil
        assert(loadstring(body))()
        check(W.options.opened ~= nil, "and what it runs does what it says: " .. name)
    end
    check(keys == 1 and BINDING_HEADER_SANEUI == "SaneUI", "Core has one key: the options")
end

-- A plate of one radius that follows its frame (a chat's bubble), and a round icon ----------------
do
    local bubble = CreateFrame("Frame", nil, UIParent)
    local plate = Shape.New(bubble, { radius = 8 })
    plate:Look({ top = { 0.2, 0.2, 0.25 }, alpha = 0.5 })
    plate:Follow()
    check(#plate.fills == 9 and #plate.trims == 0 and #plate.holes == 0, "a plate without a trim has no trim made, nor its holes")
    bubble._width, bubble._height = 100, 40
    bubble:GetScript("OnSizeChanged")(bubble, 100, 40)
    check(round(plate, 8, 8, 8, 8) and plate.fills[3]._vertex[4] == 0.5 and near(plate.fills[3]._vertex[3], 0.25),
        "its size changed, it lays itself out: every corner that round wherever it is, the fill as solid as asked")
    bubble._width, bubble._height = 12, 10
    bubble:GetScript("OnSizeChanged")(bubble, 12, 10)
    check(round(plate, 5, 5, 5, 5), "no rounder than half its shorter side")
    plate:Look({ file = Core.Skin.Tile("marble").file, size = 256, alpha = 0.25 })
    check(plate.fills[3]._texture == Core.Skin.Tile("marble").file and plate.fills[3]._vertex[4] == 0.25, "or one of the game's tiles, as solid")
    local icon = bubble:CreateTexture()
    local mask = Shape.Round(icon)
    check(mask._texture == Shape.CIRCLE and icon._masks[#icon._masks] == mask and mask._points[1][2] == icon,
        "a round icon: the same circle as a mask over the whole of it")
    bubble:Hide()
end

-- A plate round everywhere, flattened -------------------------------------------------------------
local loose = CreateFrame("Frame", nil, UIParent)
local looseShape = Shape.New(loose, { corners = 50, squareEdges = false })
looseShape:Look({ top = { 0, 0, 0 } , trim = Core.GOLD })
looseShape:Fit(0, 0, 200, 100)
check(round(looseShape, 25, 25, 25, 25) and looseShape.trims[1]._points[1][4] == 0,
    "with round corners everywhere a window at the screen's corner is round there too, its trim inside")
looseShape:Flatten(0.5)
looseShape:Fit()
check(round(looseShape, 12.5, 12.5, 12.5, 12.5) and looseShape.trims[1]._points[1][4] == -1, "half way to flat, half as round")
looseShape:Flatten(1)
looseShape:Fit()
check(round(looseShape, 0, 0, 0, 0) and looseShape.trims[1]._points[1][4] == -2 and looseShape.trims[2]._points[1][4] == 198,
    "flat, square, the trim out of the screen on its sides there, in sight on the others")

-- One full screen at a time ----------------------------------------------------------------------
local function screen(key)
    local frame = CreateFrame("Frame", nil, UIParent)
    local handle = Window.New(frame, { store = {}, key = key, dock = true, edge = W.HOVER,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    handle:Place()
    at(frame, 300, 300)
    frame:Show()
    return handle
end
local talks, map = screen("talks"), screen("map")
talks.edge:Fill(true)
check(talks.edge.full and not map.edge.full, "one window fills the screen")
map.edge:Fill(true)
check(map.edge.full and not talks.edge.full and talks.edge.away, "another begins to fill it: the first goes back to its zone")
talks.frame:Hide()
talks.edge:Fill(false)
map.edge:Fill(false)
W.Wait(1)

-- The game's windows of every module, both ways -----------------------------------------------------------
do
    local running, shown = true, {}
    W.templates.SecureActionButtonTemplate = function(widget)
        widget._attributes = {}
        function widget:SetAttribute(key, value) self._attributes[key] = value end
    end
    local gameMap = CreateFrame("Frame", "SaneTestGameMap", UIParent)
    gameMap.CloseButton = CreateFrame("Button", nil, gameMap)
    gameMap:Hide()
    local function framed(key, title, list)
        local frame = CreateFrame("Frame", nil, UIParent)
        local handle = Window.New(frame, { store = {}, key = key, title = title, dock = true, edge = W.HOVER, classic = list,
            first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
        handle:Place()
        at(frame, 300, 300)
        frame:Show()
        return handle
    end
    local chat = framed("chat", "Chat", { { text = "Friends list", show = function() shown[#shown + 1] = "friends" end } })
    local atlas = framed("atlas", "Map", { { text = "World map", show = function() shown[#shown + 1] = "map" gameMap:Show() end,
        frame = "SaneTestGameMap", full = true, ready = function() return running end } })
    chat.edge:Fill(true)
    chat.frame._group:Run(1)
    local menu = chat.edge.classic
    menu:GenerateMenu()
    local items, mapAt = menu._items, nil
    for index, item in ipairs(items) do if item.title == "Map" then mapAt = index end end
    check(items[1].title == "Chat" and items[2].text == "Friends list" and mapAt and items[mapAt + 1].text == "World map",
        "the dropdown Classic windows: every module's game windows, each under its name, this one's first")
    items[mapAt + 1].fn()
    check(shown[#shown] == "map" and not chat.edge.full and gameMap:IsShown(), "another module's chosen: the full window goes back, the game's comes")
    local button = Core.Classic.Button(gameMap)
    check(button and button:IsShown() and button._points[1][2] == gameMap.CloseButton and button._parent == UIParent
        and button._attributes.type == "click" and button._attributes.clickbutton == gameMap.CloseButton,
        "the game's panel has the button SaneUI beside its close button: a secure one on UIParent that clicks that close button")
    check(button._attributes.useOnKeyDown == false,
        "on its release, as it is registered, whatever the game's key-down setting says (else it would click nothing)")
    W.Wait(1)
    gameMap:Hide() -- the game's close button, clicked by the secure button: the game closes its own window
    check(not button:IsShown(), "the game's window closed, the button goes with it")
    button:GetScript("PostClick")(button)
    check(atlas.frame:IsShown() and atlas.edge.full, "then ours fills the screen")
    atlas.edge:Fill(false)
    W.Wait(1)
    -- In a fight the secure button is neither shown nor hidden: clear while the game's window is gone, and a press
    -- on it then brings nothing of ours.
    atlas.frame:Hide()
    gameMap:Show()
    W.Combat(true)
    check(button:IsProtected(), "(the button is protected, by its template: the stand-in refuses every Show and Hide of it in the fight)")
    gameMap:Hide()
    check(button:IsShown() and button:GetAlpha() == 0, "in a fight the game's window closed: its button stays, clear")
    button:GetScript("PreClick")(button)
    button:GetScript("PostClick")(button)
    check(not atlas.frame:IsShown(), "and a press on it then brings nothing of ours")
    gameMap:Show()
    check(button:GetAlpha() == 1, "the game's window back in the fight: its button is seen again")
    button:GetScript("PreClick")(button)
    gameMap:Hide() -- the secure click closes the game's window before ours comes
    button:GetScript("PostClick")(button)
    check(atlas.frame:IsShown(), "pressed while seen, ours comes, though the game's window is gone by then")
    W.Combat(false)
    check(not button:IsShown() and button:GetAlpha() == 1, "the fight over, it goes with the game's window, seen when it comes")
    atlas.frame:Hide()
    W.Wait(1)
    running = false
    gameMap:Show()
    check(not button:IsShown(), "while its module does not run, the game's window has no such button")
    gameMap:Hide()
    chat.frame:Hide()
    atlas.frame:Hide()
end

-- The board (Board.lua): its full screen opens only on a shown window that may fill the screen; a key another
-- window takes gets a panel of its own; a line let go unchanged lays nothing out; a kept layout a hand spoiled is
-- mended, not trusted (in a function of its own: the main chunk is at Lua's 200 locals) -------------------------
;(function()
    local frame = CreateFrame("Frame", nil, UIParent)
    local store, built, told, sized = {}, {}, {}, 0
    local settings = { expand = false, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true }
    local function Spec(title)
        return { key = "guild", title = title, build = function() built[#built + 1] = title end,
                 show = function(_, on) told[#told + 1] = title .. (on and " shown" or " hidden") end,
                 size = function() sized = sized + 1 end }
    end
    local own, guest = Spec("own"), Spec("guest")
    local talks = { key = "talks", title = "Talks", size = function() sized = sized + 1 end }
    local board, handle
    local function Lay() if handle.edge.full then board:Show(handle.inside, 1920, 1048) else board:Hide() end end
    handle = Window.New(frame, { store = store, key = "boarded", title = "Boarded", dock = true, edge = settings,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, docked = function() if board then Lay() end end })
    board = Core.Board.New(handle, { store = store, key = "layouts", label = "Boarded",
        windows = function() return { own, talks } end, changed = Lay,
        default = function() return { split = "x", parts = { { key = "guild" }, { key = "talks" } }, shares = { 1, 1 } } end })
    handle:Place()
    at(frame, 810, 440)
    frame:Hide()
    check(Core.Board.Open("Boarded", "guild") == false and not handle.edge.full and board.wanted == nil,
        "a board whose window is closed opens nothing: the caller shows that window elsewhere")
    frame:Show()
    check(Core.Board.Open("Boarded", "guild") == false and not handle.edge.full and board.wanted == nil,
        "nor one whose window may not fill the screen now (Can expand to fullscreen off)")
    settings.expand = true
    check(Core.Board.Open("Boarded", "guild") == true and handle.edge.full and Core.Board.Standing("Boarded")
        and built[1] == "own" and told[#told] == "own shown", "else its full screen comes, with its windows")

    local first = board.panels.guild
    Core.Board.Offer("Boarded", guest)
    local second = board.panels.guild
    check(second ~= first and second.spec == guest and not first:IsShown() and second:IsShown() and built[#built] == "guest"
        and told[#told - 1] == "own hidden" and told[#told] == "guest shown",
        "another window offered under that key: the one before is told it is hidden, the new one has a panel of its own")
    Core.Board.Withdraw("Boarded", "guild")
    check(board.panels.guild == first and first:IsShown() and not second:IsShown() and built[#built] == "guest"
        and told[#told - 1] == "guest hidden" and told[#told] == "own shown",
        "withdrawn, the board's own stands there again, in the panel built for it before, not one built anew")
    local builds = #built
    Core.Board.Offer("Boarded", guest)
    check(board.panels.guild == second and second:IsShown() and not first:IsShown() and #built == builds and told[#told] == "guest shown",
        "offered again, the guest has its own panel again")
    Core.Board.Withdraw("Boarded", "guild")
    check(board.panels.guild == first and #built == builds, "two panels in all, however often the key changes hands")

    local strip, line = board.strips[1], board.strips[1].of
    local before, watching = #W.frames, nil
    strip:GetScript("OnMouseDown")(strip, "LeftButton")
    for index = before + 1, #W.frames do
        if W.frames[index]._parent == nil and W.frames[index]._scripts.OnUpdate then watching = W.frames[index] end
    end
    local laid = sized
    W.cursorX, W.cursorY = line[3] + 100, 0
    watching:GetScript("OnUpdate")(watching) -- the one watcher, made when something was first held
    local dragged = strip._points[1][4]
    Core.Board.Release(true)
    check(dragged ~= line[3] and strip._points[1][4] == line[3] and sized == laid,
        "a line let go as it was: only its strip goes back over the gap, nothing is laid out anew")
    W.cursorX, W.cursorY = 0, 0

    -- A head held: where it would go is looked for every frame, its shape drawn anew only when that changes (the
    -- ghost's level is read from the board's inside each time it is drawn); let go in another window's middle, the two swap
    local talksRect, looks, level = board.rects.talks, 0, handle.inside.GetFrameLevel
    handle.inside.GetFrameLevel = function(self) looks = looks + 1 return level(self) end
    board:Lift(board.panels.guild)
    W.cursorX, W.cursorY = talksRect[1] + talksRect[3] * 0.9, -(talksRect[2] + talksRect[4] / 2)
    watching:GetScript("OnUpdate")(watching)
    watching:GetScript("OnUpdate")(watching)
    check(looks == 1, "the shape of where a held window would go is drawn once while that stays the same")
    W.cursorX = talksRect[1] + talksRect[3] / 2
    watching:GetScript("OnUpdate")(watching)
    check(looks == 2, "and anew when it changes")
    handle.inside.GetFrameLevel = nil
    Core.Board.Release(false)
    local kept = store.layouts
    local tree = kept.tabs[kept.chosen].tree
    check(tree.parts[1].key == "talks" and tree.parts[2].key == "guild", "let go in the other window's middle, the two swap places")
    W.cursorX, W.cursorY = 0, 0

    store.layouts = { chosen = 2, tabs = { true, { name = 5, tree = { split = "x", parts = { "junk", { key = 7 }, { key = "guild" } } } } } }
    Lay()
    check(type(store.layouts.tabs[1]) == "table" and board.rects.guild and board.rects.guild[3] == 1920 - 2 * Core.Board.PAD
        and board.strip.tabs[2].Text._text == "Layout 2",
        "a kept layout a hand spoiled (a tab that is no table, parts that are none, no shares, a name that is no word) is mended")
    handle.edge:Fill(false)
    frame:Hide()
end)()

-- A window of its own and the corners (Board.lua, Saneroki 2026-11-15): the button beside the X makes the window its
-- own (the full screen goes back, the window stands by itself on the screen, marked); its key toggles it then, and the
-- full screen that comes takes it back; a corner held on the full screen moves the line along its side at every step,
-- kept when let go; its own window's corner sizes it as the game does, told at every step (in a function of its own:
-- the main chunk is at Lua's 200 locals) ------------------------------------------------------------------------------
;(function()
    local frame = CreateFrame("Frame", nil, UIParent)
    local store, sizes, shown = {}, {}, {}
    local settings = { expand = true, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true }
    local function Spec(key)
        return { key = key, title = key, least = { 200, 150 }, show = function(_, on) shown[key] = on end,
                 size = function(_, width, height) sizes[key] = { width, height } end }
    end
    local bags, bank, seat = Spec("bags"), Spec("bank"), Spec("seat")
    seat.apart = false
    local board, handle
    local function Lay() if handle.edge.full then board:Show(handle.inside, 1920, 1048) else board:Hide() end end
    handle = Window.New(frame, { store = store, key = "owned", title = "Owned", dock = true, edge = settings,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, docked = function() if board then Lay() end end })
    board = Core.Board.New(handle, { store = store, key = "layouts", label = "Owned", changed = Lay,
        windows = function() return { bags, bank, seat } end,
        default = function() return { split = "x", parts = { { key = "bags" }, { key = "bank" }, { key = "seat" } }, shares = { 1, 1, 1 } } end })
    handle:Place()
    at(frame, 810, 440)
    frame:Show()
    -- the watcher that runs while something is held: the board's one, shown by what takes hold
    local function Watcher(take)
        local hidden = {}
        for _, made in ipairs(W.frames) do
            if made._parent == nil and made._scripts.OnUpdate and not made._shown then hidden[made] = true end
        end
        take()
        for made in pairs(hidden) do if made._shown then return made end end
    end
    check(Core.Board.Open("Owned", "bags") and handle.edge.full and not Core.Board.Key("Owned", "bags") and handle.edge.full,
        "(its full screen stands; a window not made its own leaves its key to the module)")
    local panel = board.panels.bags
    check(panel.own and panel.own._parent == panel.close and panel.own.normal._atlas == "RedButton-Condense"
        and board.panels.seat.own == nil, "beside the X the game's minimize, a child of the X; none where a window may not be its own")

    local grip, rect = panel.corners.BOTTOMRIGHT, board.rects.bags
    local width, bankWidth = rect[3], board.rects.bank[3]
    check(panel.corners.TOPRIGHT and grip:GetFrameLevel() < panel.close:GetFrameLevel(), "two corners at its right, under the X")
    W.cursorX, W.cursorY = rect[1] + rect[3], -(rect[2] + rect[4])
    local watcher = Watcher(function() grip:GetScript("OnMouseDown")(grip, "LeftButton") end)
    W.cursorX = rect[1] + rect[3] + 100
    watcher:GetScript("OnUpdate")(watcher)
    check(board.rects.bags[3] == width + 100 and board.rects.bank[3] == bankWidth - 100 and sizes.bags[1] == width + 100
        and sizes.bank[1] == bankWidth - 100, "a corner held on the full screen: the line at its right goes with the mouse, both laid out at once")
    grip:GetScript("OnMouseUp")(grip)
    check(store.layouts.tabs[1].tree and board.rects.bags[3] == width + 100, "let go, the layout is kept as it was moved")
    W.cursorX, W.cursorY = 0, 0

    panel.own:GetScript("OnClick")(panel.own)
    check(not handle.edge.full and panel.alone and panel._parent == UIParent and panel:IsShown() and shown.bags == true
        and store.layouts.alone.bags.on == true and panel.own.normal._atlas == "RedButton-Expand" and panel._clamped,
        "its minimize: the full screen goes back, the window stands by itself on the screen, marked; its button the maximize now")
    local own, standing = Core.Board.Key("Owned", "bags")
    check(own and not standing and not panel:IsShown() and shown.bags == false, "its key closes it by itself now")
    own, standing = Core.Board.Key("Owned", "bags")
    check(own and standing and panel:IsShown() and not handle.edge.full, "and opens it again, without the full screen")

    local sizing = Watcher(function() grip:GetScript("OnMouseDown")(grip, "LeftButton") end)
    check(panel._sizing == "BOTTOMRIGHT", "its own window's corner: the game sizes it from there")
    panel:SetSize(400, 500)
    sizing:GetScript("OnUpdate")(sizing)
    check(sizes.bags[1] == 400 and sizes.bags[2] == 500, "told its size at every step")
    panel._left, panel._bottom = 100, 200 -- where the game left it
    grip:GetScript("OnMouseUp")(grip)
    local place = store.layouts.alone.bags
    check(not panel._sizing and place.width == 400 and place.height == 500 and place.x == 100 and place.y == 700,
        "let go, its size and place are kept")
    panel.head:GetScript("OnDragStart")(panel.head)
    check(panel._moving, "held by its head it moves")
    panel._left, panel._bottom = 300, 100
    panel.head:GetScript("OnDragStop")(panel.head)
    check(not panel._moving and place.x == 300 and place.y == 600, "and stays where it was let go, kept")

    handle.edge:Fill(true)
    check(handle.edge.full and not panel.alone and panel._parent == handle.inside and panel:IsShown() and board.rects.bags,
        "the full screen that comes takes it back onto its layout")
    own, standing = Core.Board.Key("Owned", "bags")
    check(own and not standing and not handle.edge.full and not panel:IsShown(),
        "its key while the full screen stands with it: the full screen goes back, as the game's keys toggle")
    Core.Board.Key("Owned", "bags")
    local point = panel._points[1]
    check(panel.alone and point[1] == "TOPLEFT" and point[4] == 300 and point[5] == 600 and panel._width == 400,
        "again: by itself at its kept place and size")
    _G.SaneUIEscape:Hide()
    check(not panel.alone and not panel:IsShown(), "Esc closes it")
    Core.Board.Key("Owned", "bags")
    panel.own:GetScript("OnClick")(panel.own)
    check(not store.layouts.alone.bags.on and not panel.alone and handle.edge.full and board:Has("bags") and panel:IsShown(),
        "its maximize: back onto the full screen, which comes with it")
    check(not Core.Board.Key("Owned", "bags"), "and its key is the module's again (its full screen)")
    handle.edge:Fill(false)
    board:Own("bags", true)
    check(panel.alone and panel:IsShown(), "(its own again)")
    frame:Hide()
    check(not panel.alone and not panel:IsShown(), "the module's window gone (it stood down): its windows of their own go with it")
end)()

-- A talk's layout on the board (Board.lua, occasions): an unknown talk counts as none; one on stands instead of the tab
-- chosen, its changes kept as its own, a kept one a hand spoiled mended; a window forgotten leaves it too; Reset makes
-- it the module's again (in a function of its own: the main chunk is at Lua's 200 locals) ---------------------------
;(function()
    local frame = CreateFrame("Frame", nil, UIParent)
    local store, defaults = {}, 0
    local settings = { expand = true, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true }
    local function Spec(key) return { key = key, title = key } end
    local specs = { Spec("one"), Spec("two"), Spec("shop") }
    local board, handle
    local function Lay() if handle.edge.full then board:Show(handle.inside, 1920, 1048) else board:Hide() end end
    handle = Window.New(frame, { store = store, key = "talked", title = "Talked", dock = true, edge = settings,
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, docked = function() if board then Lay() end end })
    board = Core.Board.New(handle, { store = store, key = "layouts", label = "Talked",
        windows = function() return specs end, changed = Lay,
        default = function() return { key = "one" } end,
        occasions = { shop = { title = "Shop", default = function()
            defaults = defaults + 1
            return { split = "x", parts = { { key = "shop" }, { key = "two" } }, shares = { 1, 3 } }
        end } } })
    handle:Place()
    at(frame, 810, 440)
    handle.edge:Fill(true)
    check(board.rects.one and not board.rects.shop, "(its first layout)")
    board:Occasion("market")
    check(board.occasion == nil and board.rects.one, "a talk the module has no layout for counts as none")
    board:Occasion("shop")
    check(board:Talking() == "shop" and board.rects.shop and board.rects.two and not board.rects.one and defaults == 1
        and board.rects.shop[3] < board.rects.two[3], "a talk on: its layout stands instead of the tab chosen, the module's for it")
    board:Remove("two")
    check(store.layouts.occasions.shop.tree.key == "shop" and store.layouts.tabs[1].tree == nil,
        "changed, it is kept as the talk's; the first tab still the module's default")
    board:Forget("shop")
    check(store.layouts.occasions.shop.tree == false, "a window that is no more leaves the talk's layout too")
    store.layouts.occasions = "spoiled"
    Lay()
    check(board.rects.shop and defaults == 2, "a kept talk's layout a hand spoiled: the module's for it again")
    board:Remove("two")
    local MenuUtil_ = MenuUtil
    local reset
    MenuUtil = { CreateContextMenu = function(_, fn)
        local root = { CreateTitle = function() end, CreateButton = function(_, text, click) if text == Core.Board.TEXT.reset then reset = click end end }
        fn(nil, root)
    end }
    local confirm = Core.Confirm
    Core.Confirm = function(_, _, yes) yes() end
    local tab = board.strip.tabs[1]
    tab:GetScript("OnClick")(tab, "RightButton")
    reset()
    Core.Confirm, MenuUtil = confirm, MenuUtil_
    check(store.layouts.occasions.shop.tree == nil and board.rects.shop and board.rects.two and defaults == 3,
        "its tab's Reset: the module's own layout for it again")
    board:Occasion(nil)
    check(board:Talking() == nil and board.rects.one and not board.rects.shop and board.strip.tabs[1].talk == nil,
        "the talk over: the tab chosen stands again, and the talk's tab is gone")
    handle.edge:Fill(false)
    frame:Hide()
end)()

-- Let go when hidden mid-drag, Esc given up and taken again, the screen's size changed, a window not ours seated
-- (in a function of its own: the main chunk is at Lua's 200 locals) ------------------------------------------------
;(function()
    -- Hidden in the middle of a drag or a sizing (closed by its module, the game, Esc), a window is let go where it is.
    local dragged, dragStore = CreateFrame("Frame", nil, UIParent), {}
    local dragWindow = Window.New(dragged, { store = dragStore, key = "dragged", title = "Dragged", titleBar = true,
        dock = true, dragDocked = true, sizable = true, grip = "hover",
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    dragWindow:Place()
    local zone
    for name in pairs(Dock.ZONES) do if not zone and not Dock.Holder(name, dragged) then zone = name end end
    at(dragged, Dock.Rect(zone, 300, 200, 1920, 1080))
    dragWindow.bar:GetScript("OnDragStart")(dragWindow.bar)
    watcher:GetScript("OnUpdate")(watcher)
    check(dragged._moving and dragWindow.moving and watcher:IsShown() and ghost:IsShown(), "(dragged by its title bar to a zone)")
    dragged:Hide()
    check(not dragged._moving and not dragWindow.moving and not watcher:IsShown() and not ghost:IsShown()
        and dragStore.dragged.dock == zone, "hidden in the middle of a drag, it is let go where it is: the dock's shape goes")
    dragged:Show()
    dragWindow.grip:GetScript("OnMouseDown")(dragWindow.grip)
    check(dragged._sizing and dragWindow.sizing, "(sized by its grip)")
    dragged:Hide()
    check(not dragged._sizing and not dragWindow.sizing and dragStore.dragged.width == 300,
        "and hidden in the middle of a sizing, it is let go at its size")

    -- Esc given up while a view lies over a window (Core's options on a full screen), and taken again after it.
    local escaped = CreateFrame("Frame", nil, UIParent)
    local escapedWindow = Window.New(escaped, { store = {}, key = "escaped", title = "Escaped", titleBar = true,
        escape = "close", first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    escapedWindow:Place()
    escapedWindow:Escapes(false)
    SaneUIEscape:Hide()
    check(escaped:IsShown(), "a window Esc closes is not closed by it while a view over it takes Esc for itself")
    escapedWindow:Escapes(true)
    check(SaneUIEscape:IsShown(), "the view gone, Esc is the window's again")
    SaneUIEscape:Hide()
    check(not escaped:IsShown(), "and closes it")
    escapedWindow:Escapes(true)
    W.Wait(0.1)
    check(not SaneUIEscape:IsShown(), "a window that is closed takes no Esc again")

    -- A protected window closed in a fight that its module closes later (a talk): Esc's again after the fight.
    local talk = CreateFrame("Frame", nil, UIParent)
    local talkWindow = Window.New(talk, { store = {}, key = "talk", title = "Talk", titleBar = true, escape = "close",
        close = function() end, first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    talkWindow:Place()
    talk._protected = true
    W.combat = true
    SaneUIEscape:Hide()
    W.Wait(0.1)
    check(talk:IsShown() and not SaneUIEscape:IsShown(), "(in a fight Esc waits for its end, and is the game's meanwhile)")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(talk:IsShown() and SaneUIEscape:IsShown(), "the fight over, one its module closes later is Esc's again while it is shown")
    talk._protected = nil
    talk:Hide()

    -- The screen's size or the UI's scale changed: a shown window at rest is placed anew, no larger than the screen;
    -- one that stands full lays out what it holds anew, once.
    local big = CreateFrame("Frame", nil, UIParent)
    local bigWindow = Window.New(big, { store = {}, key = "big", title = "Big", sizable = true,
        first = { point = "CENTER", x = 0, y = 0, width = 1800, height = 1000 } })
    bigWindow:Place()
    local laid, full = 0, CreateFrame("Frame", nil, UIParent)
    local fullWindow = Window.New(full, { store = {}, key = "fully", title = "Fully", dock = true,
        edge = { expand = true, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true },
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 }, docked = function() laid = laid + 1 end })
    fullWindow:Place()
    at(full, 810, 440)
    fullWindow.edge:Fill(true)
    local was = laid
    UIParent._width, UIParent._height = 1280, 720
    W.Fire("DISPLAY_SIZE_CHANGED")
    W.Fire("UI_SCALE_CHANGED")
    W.Wait(0.1)
    check(big._width == 1280 and big._height == 720, "the screen smaller: a shown window at rest is placed anew, no larger than it")
    check(fullWindow.edge.full and laid == was + 1, "and one that stands full lays out what it holds anew, once for both changes")
    UIParent._width, UIParent._height = 1920, 1080
    W.Fire("UI_SCALE_CHANGED")
    W.Wait(0.1)
    fullWindow.edge:Fill(false)
    big:Hide()
    full:Hide()

    -- A window not ours seated in a room of a full window (Seat.lua): its place, scale and layer lent and followed,
    -- given back exactly; closed, given back and told.
    local game = CreateFrame("Frame", "SaneTestSeated", UIParent)
    game:SetSize(400, 300)
    game:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    game:SetFrameStrata("MEDIUM")
    game:SetFrameLevel(10)
    local gone = 0
    local seat = Core.Seat.New(game, { label = "test: seat", gone = function() gone = gone + 1 end })
    check(seat:Hold(100, 900, 200, 600, "HIGH", 50) and seat.held and Core.Lent(game), "a shown window is seated")
    local point = game._points[1]
    check(game:GetScale() == 0.5 and #game._points == 1 and point[1] == "TOPLEFT" and point[2] == UIParent and point[3] == "BOTTOMLEFT"
        and point[4] == 200 and point[5] == 1350 and game._strata == "HIGH" and game._level == 50,
        "as large as fits there and never larger than it is, in the room's middle, in that layer")
    game:SetPoint("CENTER")
    check(#game._points == 1 and game._points[1][1] == "TOPLEFT" and game._points[1][4] == 200,
        "placed anew by the game, it is put back in its room at once (its own placing passes the hook)")
    game:SetScale(1)
    check(game:GetScale() == 0.5, "scaled anew by the game, likewise")
    -- The game's action bars set their own strata at every drag onto them (MEDIUM; TOOLTIP while a spell is dragged),
    -- which put them behind the full screen, dark and out of the mouse's reach (Saneroki, 2026-11-09).
    game:SetFrameStrata("MEDIUM")
    check(game._strata == "HIGH" and game._level == 50, "its own code sets its strata anew: its layer is put back at once")
    game:SetFrameLevel(3)
    check(game._strata == "HIGH" and game._level == 50, "its level too")
    game._protected = true
    W.combat = true
    game:SetFrameStrata("MEDIUM")
    check(game._strata == "MEDIUM", "a protected one in a fight waits")
    W.Combat(false)
    check(game._strata == "HIGH" and game._level == 50, "and has its layer again once the fight is over")
    game._protected = nil
    seat:Free()
    point = game._points[1]
    check(not seat.held and not Core.Lent(game) and game:GetScale() == 1 and #game._points == 1 and point[1] == "TOPLEFT"
        and point[3] == "TOPLEFT" and point[4] == 16 and point[5] == -116 and game._strata == "MEDIUM" and game._level == 10,
        "freed, it is given back exactly: its place, scale and layer as they were")
    game:SetPoint("CENTER")
    check(#game._points == 2, "and left alone then: the game places it as it likes")
    game:ClearAllPoints()
    game:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    seat:Hold(100, 900, 200, 600, "HIGH", 50)
    game:Hide()
    check(gone == 1 and not seat.held and game:GetScale() == 1 and game._strata == "MEDIUM" and game._points[1][4] == 16,
        "closed while seated, it is given back, and that is told")
    check(seat:Hold(100, 900, 200, 600, "HIGH", 50) == false, "a closed window is not seated")

    -- Its parts the game pinned above it in a strata of their own (the trainer window's list and scroll bar on HIGH,
    -- the window on MEDIUM) keep that strata's level, which the window's never moves: seated on the full screen's
    -- strata they stood behind it, and the trainer's list was empty the first time (Saneroki, 2026-11-11). The game
    -- drags a frame's parts along to its new strata, as this window does.
    local trainer = CreateFrame("Frame", "SaneTestTrainer", UIParent)
    trainer:SetSize(338, 424)
    trainer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
    trainer:SetFrameStrata("MEDIUM")
    trainer:SetFrameLevel(10)
    rawset(trainer, "SetFrameStrata", function(self, strata)
        self._strata = strata
        for _, part in ipairs(self._children) do part._strata = strata end
    end)
    rawset(trainer, "GetChildren", function(self) return unpack(self._children) end)
    local inset = CreateFrame("Frame", nil, trainer)
    inset:SetFrameStrata("MEDIUM")
    inset:SetFrameLevel(11)
    rawset(inset, "GetChildren", function(self) return unpack(self._children) end)
    local train = CreateFrame("Button", nil, inset) -- deep in the window, high up: the pinned ones go above it
    train:SetFrameStrata("MEDIUM")
    train:SetFrameLevel(60)
    local list = CreateFrame("Frame", nil, trainer)
    list:SetFrameStrata("HIGH")
    list:SetFrameLevel(3)
    local bar = CreateFrame("Frame", nil, trainer)
    bar:SetFrameStrata("HIGH")
    bar:SetFrameLevel(4)
    local seated = Core.Seat.New(trainer, { label = "test: pinned" })
    for visit = 1, 2 do
        check(seated:Hold(100, 900, 200, 600, "HIGH", 50) and trainer._strata == "HIGH" and trainer._level == 50,
            "visit " .. visit .. ": the trainer window seated in the room's strata")
        check(list._strata == "HIGH" and list._level == 61 and bar._strata == "HIGH" and bar._level == 61 and Core.Lent(list),
            "visit " .. visit .. ": its pinned list and scroll bar above every part of it, in front of the full screen")
        seated:Free()
        check(trainer._strata == "MEDIUM" and trainer._level == 10 and list._strata == "HIGH" and list._level == 3
            and bar._strata == "HIGH" and bar._level == 4 and inset._strata == "MEDIUM" and not Core.Lent(list),
            "visit " .. visit .. ": given back, after the window: the list and scroll bar on HIGH again at their own levels")
    end
    seated:Hold(100, 900, 200, 600, "HIGH", 50)
    trainer:Hide()
    check(not seated.held and list._strata == "HIGH" and list._level == 3, "closed while seated: its pinned parts given back too")
end)()

-- A module's window keeps its place in the profile in use, each profile its own.
do
    local store = Core.Store("Places")
    store.seen = { x = 10, y = 20 }
    local free = CreateFrame("Frame", "ProfiledWindow", UIParent)
    free:SetSize(100, 100)
    local profiled = Window.New(free, { store = store, key = "seen", title = "Seen", first = { point = "TOP", x = 0, y = 0 } })
    profiled:Place()
    check(Core.general.places["Places:seen"].x == 10, "what the store held from before starts the profile off")
    profiled:Reset()
    check(type(Core.general.places["Places:seen"]) == "table" and Core.general.places["Places:seen"].x == nil, "reset: empty, not filled again from the store")
    Core.general.places["Places:seen"] = { x = 40, y = 50 }
    check(pcall(Window.PlaceAll), "another profile: every window is placed anew")
    Core.general.places["Places:seen"] = nil
end

-- Unlocked: its box outside Edit Mode, dragged by it, its place kept; locked again it stays there.
do
    local free = CreateFrame("Frame", "UnlockedWindow", UIParent)
    free:SetSize(100, 100)
    local store, menus = {}, 0
    local unlocked = Window.New(free, { store = store, key = "free", title = "Free", first = { point = "TOP", x = 0, y = 0 },
                                        unlockedMenu = function() menus = menus + 1 end })
    unlocked:Place()
    check(not unlocked.usable(), "at rest it cannot be moved")
    unlocked:Unlock(true)
    check(unlocked.box:IsShown() and unlocked.usable(), "unlocked: its box over it, to drag it")
    local box = unlocked.box
    box._scripts.OnDragStart(box)
    check(free._moving, "dragged by the box")
    box._scripts.OnDragStop(box)
    check(not free._moving and type(store.free) == "table", "let go: its place kept")
    box._scripts.OnMouseUp(box, "RightButton")
    check(menus == 1, "a right click on the box: its menu")
    unlocked:Unlock(false)
    check(not box:IsShown() and not unlocked.usable(), "locked again")
end

-- A window that grows from its bottom left corner (Combat's group frames): what is kept is its top left corner, so
-- that moves up by the growth and the bottom stays. Its height hidden from addons (a secret, through Core.Plain):
-- the growth is taken from the height given, nothing of ours computes with the secret.
do
    local grown = CreateFrame("Frame", "GrownWindow", UIParent)
    grown:SetSize(200, 100)
    local grownStore = { place = { x = 100, y = 300 } }
    local grownWindow = Window.New(grown, { store = grownStore, title = "Party", first = { point = "CENTER", x = 0, y = 0 } })
    grownWindow:Place()
    grownWindow:GrowFromBottom(200, 150)
    check(grownStore.place.y == 350 and stands(grown, "TOPLEFT", 100, 350) and grown:GetHeight() == 150,
        "grown from its bottom: its top left corner, the kept one, moves up by the growth, so its bottom stays")
    grown.GetHeight = function() return W.Secret() end -- hidden from addons in a fight (a secret)
    grownWindow:GrowFromBottom(200, 200)
    check(grownStore.place.y == 350 and stands(grown, "TOPLEFT", 100, 350) and grown._height == 200,
        "its height a secret, the growth is taken from the height given: nothing of ours computes with the secret")
end

-- The game hides its whole interface for a movie (UIParent): every window hears its OnHide with it, and the stand-in
-- for Esc goes with it, still shown itself, so it closes nothing; the interface back, a window shown throughout
-- hears its OnShow with its parent's and is Esc's again.
do
    local scene = CreateFrame("Frame", "MovieWindow", UIParent)
    scene:SetSize(100, 100)
    local closed = 0
    local movie = Window.New(scene, { store = {}, key = "scene", title = "Scene", first = { point = "TOP", x = 0, y = 0 },
                                      escape = "close", close = function() closed = closed + 1; scene:Hide() end })
    movie:Place()
    check(SaneUIEscape:IsShown(), "shown, the window is Esc's")
    UIParent:Hide()
    check(closed == 0 and scene:IsShown() and not SaneUIEscape:IsShown(),
        "the game's interface hidden for a movie: the stand-in for Esc is hidden with its parent, not by Esc, and closes nothing")
    UIParent:Show()
    check(closed == 0 and scene:IsShown() and SaneUIEscape:IsShown(), "the interface back, the window is Esc's again")
    SaneUIEscape:Hide()
    check(closed == 1 and not scene:IsShown(), "and Esc closes it")
end

-- What shows only while it is needed: out of sight at rest, in sight while something goes on (Core.Rest). A function
-- of its own: the main chunk stands at Lua's 200 locals.
(function()
    local Rest = Core.Rest
    local animations = Core.general.animations
    Core.general.animations = false -- each change where it goes at once
    local first, second = CreateFrame("Frame", nil, UIParent), CreateFrame("Frame", nil, UIParent)
    local door = CreateFrame("Button", nil, UIParent)
    second:SetAlpha(0.5)
    local held = false
    local rest = Rest.New({ label = "test", frames = { first, second }, hold = function() return held end })
    rest:Hot(first)
    rest:Door(door)
    local function Rested() return first._alpha == 0 and second._alpha == 0 and rest:Resting() end
    local function Seen() return first._alpha == 1 and second._alpha == 1 and not rest:Resting() end
    check(first._alpha ~= 0 and not rest:Resting(), "a set not switched on leaves its frames alone")
    rest:Switch(true)
    check(Rested(), "switched on and nothing going on: every frame of the set out of sight")

    W.Combat(true)
    check(Seen(), "in a fight in sight")
    W.Combat(false)
    check(Rested(), "and out of it again")

    local grouped = IsInGroup
    IsInGroup = function() return true end
    W.Fire("GROUP_ROSTER_UPDATE")
    check(Seen(), "in a group in sight")
    check(Rest.Busy() and not Rest.Busy(true), "a group goes on, but not for a set at rest in a group too")
    rest:InGroup(true)
    check(Rested(), "at rest in a group too: the group counts for nothing, at once")
    W.Combat(true)
    check(Seen(), "a fight in a group in sight still")
    W.Combat(false)
    check(Rested(), "and after it at rest again")
    rest:InGroup(false)
    check(Seen(), "back to in sight in a group, at once")
    IsInGroup = grouped
    W.Fire("GROUP_ROSTER_UPDATE")
    check(Rested(), "and alone again out of it")

    local dead = UnitIsDeadOrGhost
    UnitIsDeadOrGhost = function() return true end
    W.Fire("PLAYER_DEAD")
    check(Seen(), "dead in sight")
    UnitIsDeadOrGhost = dead
    W.Fire("PLAYER_ALIVE")
    check(Rested(), "alive again out of it")

    -- Your health: its numbers where the game tells them, else by its last change.
    local health = UnitHealth
    UnitHealth = function() return 60 end
    W.Fire("UNIT_HEALTH", "player")
    check(Seen(), "health a number under the most: in sight")
    UnitHealth = health
    W.Fire("UNIT_HEALTH", "player")
    check(Rested(), "full again: out of sight")
    UnitHealth = function() return W.Secret() end
    W.Fire("UNIT_HEALTH", "player")
    check(Seen(), "the game hides your health: changed just now, it counts as not full")
    W.Wait(Rest.HEALTH - 1)
    W.Fire("UNIT_HEALTH", "player")
    W.Wait(Rest.HEALTH - 1)
    check(Seen(), "and while it goes on changing, as it comes back step by step")
    W.Wait(Rest.HEALTH)
    check(Rested(), "unchanged for a while: taken for full")
    W.Combat(true)
    W.Combat(false)
    check(Seen(), "after a fight the same, the game telling nothing of what it left")
    W.Wait(Rest.HEALTH + Rest.AGAIN)
    check(Rested(), "and out of sight once that time is up")
    UnitHealth = health

    -- Your resource: where each rests.
    local kind, power, most = UnitPowerType, UnitPower, UnitPowerMax
    local has = {}
    UnitPowerType = function() return has.kind end
    UnitPower = function(_, each) return has[each] or 0 end
    UnitPowerMax = function(_, each) return has[each] and 100 or 0 end
    local function Power(what, each, amount)
        has.kind, has[each] = each, amount
        W.Fire("UNIT_POWER_UPDATE", "player")
        check(what(), ("power %d at %s"):format(each, tostring(amount)))
        has[each] = nil
    end
    Power(Seen, Enum.PowerType.Mana, 40)
    Power(Rested, Enum.PowerType.Mana, 100)
    Power(Seen, Enum.PowerType.Energy, 40)
    Power(Rested, Enum.PowerType.Energy, 100)
    Power(Seen, Enum.PowerType.Rage, 30)
    Power(Rested, Enum.PowerType.Rage, 0)
    has[Enum.PowerType.Mana] = 50 -- a druid in a form: full energy, mana not
    Power(Seen, Enum.PowerType.Energy, 100)
    has[Enum.PowerType.Mana] = nil
    Power(Rested, Enum.PowerType.Energy, 100)
    has[Enum.PowerType.ComboPoints] = 2
    Power(Seen, Enum.PowerType.Energy, 100)
    has[Enum.PowerType.ComboPoints] = nil
    UnitPower = function() return W.Secret() end
    has.kind, has[Enum.PowerType.Mana] = Enum.PowerType.Mana, 50
    W.Fire("UNIT_POWER_UPDATE", "player")
    check(Rested(), "a resource the game hides tells nothing, and shows nothing")
    UnitPowerType, UnitPower, UnitPowerMax = kind, power, most
    W.Fire("UNIT_POWER_UPDATE", "player")

    -- The mouse: a door brings it in, the hot frames keep it.
    local function Look(seconds)
        local watch = rest.hover.watch.frame
        watch:GetScript("OnUpdate")(watch, seconds)
    end
    door:GetScript("OnEnter")(door)
    check(Seen(), "the mouse in by a door: the whole set in sight")
    Look(1)
    check(Seen(), "and while it stays on that door")
    door:GetScript("OnLeave")(door)
    first._mouseOver = true
    Look(1)
    check(Seen(), "and while the mouse is on a hot frame")
    first._mouseOver = false
    Look(Rest.LINGER / 2)
    check(Seen(), "a moment off it, on its way to the next")
    Look(Rest.LINGER)
    check(Rested(), "off it for longer: out of sight")
    first:GetScript("OnEnter")(first)
    check(Seen(), "a hot frame is a door too")
    first:GetScript("OnLeave")(first)
    first:Hide()
    first._mouseOver = true
    Look(1)
    check(Rested(), "a hot frame out of sight holds nothing")
    first._mouseOver = false
    first:Show()
    door:GetScript("OnEnter")(door)
    door:Hide()
    Look(1)
    check(Rested(), "and a door that went out of sight without a word no longer does")
    door:Show()
    door:GetScript("OnLeave")(door)

    -- Where the game hides a frame's place or showing, its answers are secrets, and no condition may test one: hidden
    -- is no. A secret tests true in the stand-in, where the game fails: held in sight here means a bare test.
    local placed, shown = first.IsMouseOver, first.IsVisible
    rawset(first, "IsMouseOver", function() return W.Secret() end)
    door:GetScript("OnEnter")(door)
    door:GetScript("OnLeave")(door)
    Look(1)
    check(Rested(), "a hidden answer to where the mouse is: not on it")
    rawset(first, "IsVisible", function() return W.Secret() end)
    rawset(first, "IsMouseOver", placed)
    door:GetScript("OnEnter")(door)
    door:GetScript("OnLeave")(door)
    first._mouseOver = true
    Look(1)
    check(Rested(), "and a hidden answer to whether it shows")
    first._mouseOver = false
    rawset(first, "IsVisible", shown)
    rawset(door, "IsVisible", function() return W.Secret() end)
    door:GetScript("OnEnter")(door)
    Look(1)
    check(Seen(), "a door keeps it while the mouse is on it, though the game hides whether the door shows")
    door:GetScript("OnLeave")(door)
    Look(1)
    check(Rested(), "and lets go as the mouse leaves it")
    rawset(door, "IsVisible", shown)

    -- An area alone: no hook on a frame that may have no such script (the game's aura containers).
    local area = CreateFrame("Frame", nil, UIParent)
    rest:Area(area)
    check(not area:GetScript("OnEnter") and not area:GetScript("OnLeave"), "an area takes no hook")
    door:GetScript("OnEnter")(door)
    door:GetScript("OnLeave")(door)
    area._mouseOver = true
    Look(1)
    check(Seen(), "and holds the set while the mouse is on it")
    area._mouseOver = false
    Look(1)
    check(Rested(), "and lets it go")

    held = true
    rest:Look()
    check(Seen(), "its module holds it in sight")
    held = false
    rest:Look()
    check(Rested(), "and lets it go")
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(Seen(), "in Edit Mode in sight, to be placed")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(Rested(), "and at rest again after it")

    -- A fade, by one clock that touches no frame's animations.
    Core.general.animations = true
    W.Combat(true)
    check(first._alpha == 0 and rest.clock:IsRunning(), "coming into sight takes a moment")
    rest.clock.group:Run(0.5)
    check(first._alpha == 0.5 and second._alpha == 0.5, "every frame of the set at the same step")
    W.Combat(false)
    rest.clock.group:Run(0.5)
    check(first._alpha == 0.25, "turned back half way: from where it stands")
    rest.clock.group:Run(1)
    check(first._alpha == 0 and first._groups == nil, "and none of it an animation on a frame of the set")
    Core.general.animations = false

    rest:Switch(false)
    check(first._alpha == 1 and second._alpha == 0.5 and not rest:Resting(), "switched off: each frame as it was")
    door:GetScript("OnEnter")(door)
    door:GetScript("OnLeave")(door)
    W.Combat(true)
    W.Combat(false)
    check(first._alpha == 1 and not rest.hover.watch:IsRunning(), "and the mouse and the game's events change nothing then")

    -- One that fails stays in sight.
    rest:Switch(true)
    check(first._alpha == 0, "on again")
    rawset(second, "SetAlpha", function() error("broken") end)
    W.Combat(true)
    rawset(second, "SetAlpha", nil)
    check(not rest.on and first._alpha == 1 and first._alpha == 1 and Core.errors.test and Core.errors.test.text:find("broken"),
        "a set whose alpha fails is off and noted, its frames given back")
    W.Combat(false)
    Core.general.animations = animations
end)()

-- The dropdown Classic windows on a title bar over what its window holds (under: the full map) -------------------
;(function()
    -- Frame levels kept, for this check only (the stand-in has every frame at level 1).
    W.methods.SetFrameLevel = function(self, level) self._level = level end
    W.methods.GetFrameLevel = function(self) return self._level or 1 end
    local frame = CreateFrame("Frame", nil, UIParent)
    local handle = Window.New(frame, { store = {}, key = "under", title = "Map", dock = true, edge = W.HOVER, under = true,
        untitled = true, classic = { { text = "World map", show = function() end } },
        first = { point = "CENTER", x = 0, y = 0, width = 300, height = 200 } })
    handle:Place()
    at(frame, 300, 300)
    frame:Show()
    handle.edge:Fill(true)
    frame._group:Run(1)
    local menu, bar = handle.edge.classic, handle.bar
    check(handle.edge.full and menu and menu:IsShown() and bar and bar:GetFrameLevel() == frame:GetFrameLevel() + Window.UNDER
        and menu:GetFrameLevel() > bar:GetFrameLevel() + 5 and menu._points[1][2] == handle.buttons.first,
        "full, the dropdown Classic windows stands over a title bar that stands over what its window holds, and over what a module lays on that bar (the full map's controls): its clicks are its own")
    handle.edge:Stop()
    W.methods.SetFrameLevel, W.methods.GetFrameLevel = nil, function() return 1 end
end)()

-- Sized by its corners and sides in Edit Mode (option resize; Saneroki, 2026-11-18: "a dragable corner to resize it by
-- draging corners or sides"): a grip at each corner, a handle along each side, each sizing from its own point with the
-- one across held; the module told at every step and once let go, the place kept where it stands then.
do
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(300, 100)
    local told, store = {}, {}
    local resized = Window.New(frame, { store = store, title = "Party", first = { point = "BOTTOMLEFT", x = 16, y = 340 },
        resize = { sized = function(width, height, done) told[#told + 1] = { width, height, done } end,
                   minWidth = 100, minHeight = 30, maxWidth = 2000, maxHeight = 800 } })
    frame._left, frame._bottom = 16, 340
    local edges = resized.edges
    local function Shown()
        local count = 0
        for _, handle in ipairs(edges) do if handle:IsShown() then count = count + 1 end end
        return count
    end
    check(edges and #edges == 8 and Shown() == 0 and not resized.grip, "eight handles, none in sight outside Edit Mode, no grip of sizable")
    EventRegistry:TriggerEvent("EditMode.Enter")
    check(Shown() == 8, "in Edit Mode: a grip at each corner and a handle along each side")
    local by = {}
    for _, handle in ipairs(edges) do by[handle.point] = handle end
    check(by.TOPLEFT and by.BOTTOMRIGHT and by.TOP and by.LEFT._width == Window.SIDE and by.TOP._height == Window.SIDE
        and by.TOPLEFT._width == 16 and by.TOPLEFT.corner == "TOPLEFT", "the corners the game's grip, the sides thin handles")
    by.LEFT._scripts.OnMouseDown(by.LEFT)
    check(frame._sizing == "LEFT" and frame._points[1][1] == "TOPRIGHT" and frame._points[1][4] == 316
        and frame._bounds[1] == 100 and frame._bounds[4] == 800, "the left side sizes it from there, its right side held, within its bounds")
    frame._width = 420
    frame._scripts.OnSizeChanged(frame)
    check(told[1] and told[1][1] == 420 and told[1][3] == false, "the module told of the size at every step")
    frame._left = 316 - 420
    by.LEFT._scripts.OnMouseUp(by.LEFT)
    check(frame._sizing == nil and told[2] and told[2][1] == 420 and told[2][3] == true and store.place
        and store.place.x == 316 - 420, "let go: the place kept where it stands, then the module takes the size")
    by.TOPRIGHT._scripts.OnMouseDown(by.TOPRIGHT)
    check(frame._sizing == "TOPRIGHT" and frame._points[1][1] == "BOTTOMLEFT", "a corner holds the corner across")
    EventRegistry:TriggerEvent("EditMode.Exit")
    check(frame._sizing == nil and Shown() == 0 and told[3] and told[3][3] == true, "Edit Mode closed while sizing: let go, the handles gone")
end

-- The ticks of Edit Mode's window for what a module stands in for (Saneroki, 2026-11-18: "Can you remove them when they
-- are replaced by our own addons"): out of sight as the game shows them, so its own layout leaves them out.
do
    local ticks = {}
    for _, key in ipairs({ "PartyFrames", "CastBar", "BossFrames" }) do ticks[key] = CreateFrame("Frame") end
    rawset(_G, "EditModeManagerFrame", { AccountSettings = { settingsCheckButtons = ticks } })
    local ours = true
    Core.EditMode.Replace("PartyFrames", function() return ours end)
    Core.EditMode.Replace("CastBar", function() return false end)
    ticks.PartyFrames:Show()
    ticks.CastBar:SetShown(true)
    ticks.BossFrames:Show()
    check(not ticks.PartyFrames:IsShown() and ticks.CastBar:IsShown() and ticks.BossFrames:IsShown()
        and Core.EditMode.Replaced("PartyFrames") and not Core.EditMode.Replaced("CastBar"),
        "a tick a module stands in for goes as the game shows it; one it does not, and one nobody claims, stay")
    ours = false
    ticks.PartyFrames:SetShown(true)
    check(ticks.PartyFrames:IsShown(), "the module's part switched off: its tick shows again at the game's next layout")
    rawset(_G, "EditModeManagerFrame", nil)
end

-- SaneUI's layout of the game's Edit Mode (Saneroki, 2026-11-18, GameLayout.lua): made once for an account over the
-- game's first preset, by the game's enum words, and in use on a character on a preset.
do
    local GameLayout = Core.GameLayout
    local enum = rawget(_G, "Enum") or {}
    rawset(_G, "Enum", enum)
    enum.EditModeLayoutType = { Preset = 0, Account = 1, Character = 2 }
    enum.EditModeSystem = { ActionBar = 0, ChatFrame = 8 }
    enum.EditModeActionBarSystemIndices = { MainBar = 1, ExtraBar1 = 6 }
    enum.EditModeActionBarSetting = { IconSize = 3, NumIcons = 4 }
    enum.EditModeChatFrameSetting = { WidthHundreds = 0 }
    local function Preset()
        return { layoutName = "Modern", layoutType = 0, systems = {
            { system = 0, systemIndex = 1, isInDefaultPosition = true, anchorInfo = { point = "BOTTOM" },
              settings = { { setting = 3, value = 9 }, { setting = 4, value = 6 } } },
            { system = 0, systemIndex = 6, isInDefaultPosition = true, settings = {} },
            { system = 8, isInDefaultPosition = true, settings = { { setting = 0, value = 3 } } } } }
    end
    local manager = { layoutInfo = { activeLayout = 1, layouts = { { layoutName = "Modern", layoutType = 0 },
                                                                   { layoutName = "Classic", layoutType = 0 } } } }
    rawset(_G, "EditModeManagerFrame", manager)
    rawset(_G, "EditModePresetLayoutManager", { GetCopyOfPresetLayouts = function() return { Preset(), Preset() } end })
    local saved, added, active
    rawset(_G, "C_EditMode", { GetLayouts = function() return { layouts = {}, activeLayout = 1 } end,
        SaveLayouts = function(all) saved = all end,
        OnLayoutAdded = function(index, activate) added = { index, activate } end,
        SetActiveLayout = function(index) active = index end })
    local store, char = Core.Store(Core.name), Core.Character(Core.name)
    store.gameLayoutMade, char.gameLayoutSet = nil, nil
    check(GameLayout.Make() and saved and #saved.layouts == 1, "made: one layout more in the account's list")
    local layout = saved.layouts[1]
    local main, extra, chat = layout.systems[1], layout.systems[2], layout.systems[3]
    check(layout.layoutName == "SaneUI" and layout.layoutType == 1 and main.isInDefaultPosition == false
        and main.anchorInfo.point == "BOTTOM" and main.anchorInfo.offsetY == 2 and main.settings[1].value == 5
        and main.settings[2].value == 12 and extra.anchorInfo.offsetY == 137 and chat.anchorInfo.offsetX == -697
        and chat.settings[1].value == 4, "an account layout named SaneUI: the game's preset with each system as listed, "
        .. "by the game's words (the bars' rows, the chat's place and size)")
    check(added and added[1] == 3 and added[2] == true and store.gameLayoutMade and char.gameLayoutSet,
        "after the presets, and in use: this character was on a preset")
    saved, added = nil, nil
    manager.layoutInfo.layouts[3] = { layoutName = "SaneUI", layoutType = 1 }
    manager.layoutInfo.activeLayout = 2
    char.gameLayoutSet = nil
    check(GameLayout.Make() and saved == nil and active == 3, "there already: not made again; another character on a "
        .. "preset gets it in use, once")
    active = nil
    manager.layoutInfo.activeLayout = 3
    table.remove(manager.layoutInfo.layouts, 3)
    manager.layoutInfo.activeLayout = 1
    check(GameLayout.Make() and saved == nil and active == nil, "taken away by the player: not made again")
    W.Combat(true)
    store.gameLayoutMade = nil
    check(GameLayout.Make() == false and saved == nil, "in a fight it waits for the fight's end")
    W.Combat(false)
    check(saved ~= nil, "then it is made")
    rawset(_G, "EditModeManagerFrame", nil)
    rawset(_G, "EditModePresetLayoutManager", nil)
    rawset(_G, "C_EditMode", nil)
end

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Windows: all %d checks passed.\n"):format(passed))
