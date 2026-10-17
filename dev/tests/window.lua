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
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local Dock, Window, Expand, Edge, Shape, Bar = Core.Dock, Core.Window, Core.Expand, Core.Edge, Core.Shape, Core.Bar

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
    store = store, title = "Test window", sizable = true, dock = true, skin = true,
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
bar:GetScript("OnEnter")(bar)
check(hover:IsShown() and title:IsShown() and hover._alpha == 0.4, "with the mouse on the box it is brighter, with the window's title")
bar:GetScript("OnLeave")(bar)
check(not hover:IsShown() and not title:IsShown(), "and as before when the mouse has left")

-- Dragged about
local ghost, watcher
for _, widget in ipairs(W.frames) do if widget._strata == nil and widget._scripts.OnUpdate then watcher = widget end end
check(watcher == nil, "nothing looks at the mouse before a window is dragged")
at(frame, 600, 400)
bar:GetScript("OnDragStart")(bar)
for _, widget in ipairs(W.frames) do if widget._scripts.OnUpdate then watcher = widget end end
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
    "the fill is the tile of the game's dark dialogs, each piece showing the tile where it lies so the pieces meet without a seam; the trim Sane UI's")

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
    check(not fading.playing and region._alpha == 0.5 and not sliding.playing, "with Sane UI's animations off nothing moves: it is there at once")
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
local wideWindow = Window.New(wide, {
    store = wideStore, sizable = true, dock = true, edge = true, content = list,
    classic = { { text = "Friends list", show = function() native = native + 1 end } },
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
check(#shown == 1 and along(strip) == "TOPLEFT BOTTOMLEFT" and math.abs(strip._width - 2 * 768 / 2160) < 1e-9 and strip._mouse == nil,
    "docked at the left edge, one strip along it, two of the screen's pixels wide, that takes no clicks")

at(wide, 0, 410)
strip:GetScript("OnEnter")(strip)
check(not edge.full, "a strip that came under the mouse a moment ago does nothing: the mouse has to come anew")
W.Wait(1)
W.held = true
strip:GetScript("OnEnter")(strip)
check(not edge.full, "nor while a button is held: something is dragged")
W.held = false
strip:GetScript("OnEnter")(strip)
local clock = wide._group
check(edge.full and edge.away and fills[1] == true and clock.playing and clock.duration == glide.time,
    "pushed against the screen's edge there, it begins to fill the screen, as the general kind of motion says")
local back = edge.back
local middle = back.fills[3]
check(wide._strata == "HIGH" and wide._level == 500 and wide._clamped == false and back.shown and middle._alpha == 0
    and back.trims[1]._alpha == 0 and wideWindow.grip._alpha == 0,
    "raised above the game's bars and the others of that layer, free to spring past the screen's edge, a background to come, its grip out of sight")
check(wide._mouse == true and wide._wheel == true, "it takes the mouse and its wheel: what is behind it cannot be clicked, nor the camera turned or zoomed")
check(middle._texture == "Interface\\Buttons\\WHITE8X8" and middle._vertex[1] == 0 and middle._vertex[2] == 0 and middle._vertex[3] == 0
    and middle._gradient == nil and back.trims[1]._vertex[1] == Core.GOLD[1],
    "without settings of its own its background is solid black, its trim Sane UI's bronze")
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
check(wideBar and wideBar:IsShown() and wideBar._points[1][1] == "TOPLEFT" and wideBar._height == Window.BAR
    and wideWindow.buttons:IsShown() and #wideWindow.buttons.list == 2 and wideWindow.full.isMinimized == false,
    "full, a window without a title bar of its own has one at its top: its buttons there, full screen offering the way back")
check(menu and menu:IsShown() and menu._override == Edge.CLASSIC and menu._parent == wide and menu._points[1][1] == "RIGHT"
    and menu._points[1][2] == wideWindow.buttons.first and #menu._items == 1 and menu._items[1].text == "Friends list",
    "and the dropdown Classic windows in the title bar, left of the buttons, with the game's windows it stands for")

at(wide, 0, 0)
strip:GetScript("OnEnter")(strip)
check(not edge.full and edge.away and fills[2] == false and clock.playing and edge.to[3] == 380 and edge.to[2] == 410,
    "pushed there again, it goes back to its size in its zone")
clock:Run(0.5)
local midway = wide._width
strip:GetScript("OnEnter")(strip)
check(edge.full and edge.from[3] == midway and edge.to[3] == 1920, "a change of mind on the way starts from where it is")
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

-- The section Expand window: a module's own settings ------------------------------------------------
local described = { { key = "first", default = true, text = "First" }, { key = "last", default = true, text = "Last" } }
Edge.Options(described, 2, "Appearance")
check(#described == 8 and described[1].key == "first" and described[2].key == "expand" and described[2].header == "Expand window"
    and described[3].key == "motion" and described[4].key == "expandOpacity" and described[5].key == "expandTexture"
    and described[6].key == "corners" and described[7].key == "squareEdges" and described[8].key == "last"
    and described[7].tab == "Appearance" and described[3].parent == "expand" and described[7].parent == "expand",
    "a module puts the section Expand window where it wants it: whether it fills the screen, how it moves, its background, its corners")
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
    check(list[3].key == "motion" and list[3].parent[1] == "expand" and list[3].parent[2] == "animations" and list[2].parent == nil
        and list[4].parent == "expand", "a module can put some of the section under switches of its own too")
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
    store = { place = { x = 0, y = 260, width = 380, height = 260, dock = "BOTTOMLEFT" } }, sizable = true, dock = true, skin = true, edge = true,
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
    store = traderStore, title = "Vendor", titleBar = true, sizable = true, dock = true, edge = true,
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
check(buttons:IsShown() and buttons._parent == titleBar and #buttons.list == 3 and full == traderWindow.full and toggle == traderWindow.toggle
    and buttons._points[1][1] == "RIGHT" and close._points[1][1] == "RIGHT" and full._points[1][2] == close
    and toggle._points[1][2] == full and buttons.first == toggle,
    "at its right, from the right: close, full screen, the game's own window")
check(full.isMinimized == true and toggle._Normal._texture:find("SquareButton") and next(traderWindow.edge.strips) == nil,
    "full screen offers to fill the screen; the game's window is the game's square button")

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
    and traderMenu._points[1][2] == toggle and box._points[2][2] == traderMenu,
    "full, its title bar is the full screen's: the dropdown Classic windows left of the buttons, the search box ending left of that")
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
    and back._Normal._texture == toggle._Normal._texture, "the game's window has the same button, beside its close button")
back:GetScript("OnClick")(back)
check(oursShown == 1 and traderStore.place.native == nil and traderWindow:Attach() == back, "it brings ours back, kept so; it is put there once")
at(trader, 760, 390)
titleBar:GetScript("OnDragStart")(titleBar)
titleBar:GetScript("OnDragStop")(titleBar)
check(traderStore.place.dock == "CENTER" and traderStore.place.x == 760, "a new place keeps what it was left as")
traderWindow.edge.settings = { expand = false, motion = "off", expandOpacity = 50, expandTexture = "solid", corners = 10, squareEdges = true }
traderWindow.edge:Update()
check(not full:IsShown() and toggle._points[1][2] == close and buttons.first == toggle, "a window that may not fill the screen has no full screen button")

-- Without a title bar
local plain = CreateFrame("Frame", nil, UIParent)
local plainWindow = Window.New(plain, { store = {}, first = { point = "CENTER", x = 0, y = 0 }, edge = true })
plainWindow:Place()
check(plainWindow.bar == nil and plainWindow.buttons == nil and not plainWindow:Draggable(),
    "a kind of window without a title bar (the small chat) has none, and nothing to move it by but Edit Mode")
at(plain, 860, 490)
plainWindow.edge:Fill(true)
plain._group:Run(1)
local plainBar = plainWindow.bar
check(plainBar and plainBar:IsShown() and #plainWindow.buttons.list == 2 and not plainBar.glass:IsShown(),
    "filling the screen it has the title bar at its top; without search, no magnifier")
plainBar.find:GetScript("OnClick")(plainBar.find)
check(not plainBar.box:IsShown(), "and its title opens no search")
plainWindow.buttons.list[1]:GetScript("OnClick")(plainWindow.buttons.list[1])
check(not plain:IsShown() and not plainWindow.edge.away and not plainBar:IsShown(), "its close button hides it: back at its size, without the bar")

-- A window that holds the game's protected frames, in a fight ---------------------------------------
wide:Hide() -- (they hold the left zone and the middle; a zone holds one window at a time)
trader:Hide()
function methods:IsProtected() return self._protected or false end
local secure = CreateFrame("Frame", nil, UIParent)
local secureStore = { place = { x = 0, y = 690, width = 400, height = 300, dock = "LEFT", full = true } }
local secureWindow = Window.New(secure, {
    store = secureStore, title = "Spellbook", titleBar = true, sizable = true, dock = true, edge = true,
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
secure:Hide()
check(secureWindow:Open() == "locked" and not secure:IsShown(), "asked for (the game's key), it says it may not be shown: the module lets the game's own")
secure:Show()
W.combat = false
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
local guardClose = guardedWindow.buttons.list[1]
guardClose:GetScript("OnClick")(guardClose)
check(guarded:IsShown() and guardedClosed == 0, "in a fight its close button does not hide it: nothing of ours hides it then")
guardStand:Hide()
check(guarded:IsShown(), "nor does Esc")
W.Wait(0.1)
check(guardStand:IsShown(), "and Esc stays ours while it is shown: the stand-in is back a moment later")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(not guarded:IsShown() and guardedClosed == 1, "the fight over, it closes, once")
W.Wait(0.1)
check(not guardStand:IsShown(), "and Esc is the game's again")
end

-- Esc closes a window made so, small or full, as the game's panels close
local talked = CreateFrame("Frame", nil, UIParent)
local talkStore, talkClosed = {}, 0
local talkWindow = Window.New(talked, {
    store = talkStore, title = "Vendor", titleBar = true, dock = true, edge = true, escape = "close",
    first = { point = "CENTER", x = 0, y = 0, width = 400, height = 300 },
    close = function() talkClosed = talkClosed + 1; talked:Hide() end,
})
talkWindow:Place()
local stand = SaneUIEscape
local ours = 0
for _, name in ipairs(UISpecialFrames) do if name:find("^SaneUI") then ours = ours + 1 end end
check(stand and stand:IsShown() and ours == 1,
    "shown, a window Esc closes has the stand-in of ours shown, the one frame Sane UI puts into the game's list of what Esc closes")
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
local spareWindow = Window.New(spare, { store = {}, edge = true, sizable = true,
    first = { point = "CENTER", x = 0, y = 0, width = 200, height = 100 } })
spareWindow:Place()
at(spare, 860, 490)
spareWindow.edge:Fill(true)
spare._group:Run(1)
stand:Hide()
check(talkClosed == 2 and not talked:IsShown() and talkStore.place.full == true,
    "Esc closes it full as it is: not made small first, so it opens full again")
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
    local insetWindow = Window.New(inset, { store = insetStore, sizable = true, dock = true, edge = true, insets = room,
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
local demo = W.frames[before + 1]
check(demo._parent == UIParent and demo:IsShown() and demo._points[1][1] == "CENTER" and demo._group, "/sane window makes a window to try it with")
local keepBox, addButton, demoWatch, demoFill
for index = before + 1, #W.frames do
    local widget = W.frames[index]
    if widget._kind == "CheckButton" and widget.Text and widget.Text._text == "Keep open" then keepBox = widget end
    if widget._kind == "Button" and widget._text == "Add" then addButton = widget end
    if widget._parent == demo and widget._scripts.OnUpdate then demoWatch = widget end
    if widget._kind == "StatusBar" and widget._bar == Bar.ART.fill then demoFill = widget end
end
check(keepBox and addButton and demoWatch and demoFill and not keepBox:IsShown() and not addButton:IsShown(),
    "with a box Keep open and a button Add, out of sight while it is small, and a bar")
demo._mouseOver = true
demo:GetScript("OnEnter")(demo)
demoWatch:GetScript("OnUpdate")(demoWatch, 1)
check(keepBox:IsShown() and addButton:IsShown(), "the mouse rests on it: it opens, and shows them")
keepBox:SetChecked(true)
keepBox:GetScript("OnClick")(keepBox)
demo._mouseOver = false
demoWatch:GetScript("OnUpdate")(demoWatch, 5)
check(addButton:IsShown(), "Keep open keeps it open when the mouse goes")
addButton:GetScript("OnClick")(addButton)
demoFill._parent._groups[1]:Run(1)
check(demoFill._value == 0.15, "Add fills the bar a step")
for _ = 1, 6 do addButton:GetScript("OnClick")(addButton) end
demoFill._parent._groups[1]:Run(1)
check(demoFill._value == 1, "up to full")
addButton:GetScript("OnClick")(addButton)
check(demoFill._value == 0, "and full, it starts again from nothing, at once")
keepBox:SetChecked(false)
keepBox:GetScript("OnClick")(keepBox)
check(not addButton:IsShown(), "let go with the mouse away, it closes")
SlashCmdList.SANEUI("window")
check(not demo:IsShown(), "typed again it hides it")
SlashCmdList.SANEUI("window reset")
check(demo:IsShown() and SaneUIDB.modules.Core.demo == nil, "and reset shows it at its first place")
check(next(Core.errors) == nil, "nothing went wrong on the way")

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

print = nil -- the stand-in's print; use the real one for the summary
io.write(("Windows: all %d checks passed.\n"):format(passed))
