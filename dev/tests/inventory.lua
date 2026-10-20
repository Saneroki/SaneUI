-- Runs the Inventory module against the stand-in client (wowstub.lua): its window docked in the bottom right
-- corner, the corner's square filling the screen, the module's windows on Core's board (parts that register
-- themselves), our character sheet (its slots, level line, model, the game's events while shown), and giving
-- everything back. The look can only be judged in the game.
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
function methods:SetID(id) self._id = id end
function methods:GetID() return self._id end
function methods:SetFormattedText(format, ...) self._text = format:format(...) end
W.modifier = false -- no modifier key held (the stand-in's IsModifiedClick compares with it)

-- The character's items, as the game tells them: [slot ID] = { texture, count, quality, id, link, broken, locked }.
local SLOT_IDS = { HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4, ChestSlot = 5, WaistSlot = 6, LegsSlot = 7,
                   FeetSlot = 8, WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12, Trinket0Slot = 13,
                   Trinket1Slot = 14, BackSlot = 15, MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18,
                   TabardSlot = 19, AmmoSlot = 0 }
local worn = { [1] = { texture = "helm", count = 1, quality = 3, id = 1001, link = "|Hitem:1001|h[Helm]|h" } }
local rangedShown, ammoUser = true, false
C_PaperDollInfo = { GetInventorySlotInfo = function(name) return SLOT_IDS[name], "empty-" .. name, name == "RangedSlot" end,
                    IsRangedSlotShown = function() return rangedShown end }
UnitUsesAmmo = function() return ammoUser end
UnitHasRelicSlot = function() return false end
GetInventoryItemTexture = function(_, id) return worn[id] and worn[id].texture end
GetInventoryItemCount = function(_, id) return worn[id] and worn[id].count or 0 end
GetInventoryItemBroken = function(_, id) return worn[id] and worn[id].broken or false end
GetInventoryItemEquippedUnusable = function() return false end
GetInventoryItemQuality = function(_, id) return worn[id] and worn[id].quality end
GetInventoryItemID = function(_, id) return worn[id] and worn[id].id end
GetInventoryItemLink = function(_, id) return worn[id] and worn[id].link end
IsInventoryItemLocked = function(id) return worn[id] and worn[id].locked or false end
-- What the game's item button functions were told, per button.
local drawn = setmetatable({}, { __index = function(t, button) t[button] = {} return t[button] end })
SetItemButtonTexture = function(button, texture) drawn[button].texture = texture end
SetItemButtonCount = function(button, count) drawn[button].count = count end
SetItemButtonQuality = function(button, quality) drawn[button].quality = quality end
SetItemButtonTextureVertexColor = function(button, r, g, b) drawn[button].tint = { r, g, b } end
SetItemButtonNormalTextureVertexColor = function() end
SetItemButtonDesaturated = function(button, on) drawn[button].grey = on end
local picked, linked = {}, nil
PickupInventoryItem = function(id) picked[#picked + 1] = id end
HandleModifiedItemClick = function(link) linked = link end
function GameTooltip:SetInventoryItem(_, id) self._item = id return worn[id] ~= nil end
UnitPVPName = function() return "Tester Stub, the Patient" end
UnitSex = function() return 2 end
UnitEffectiveLevel = function() return W.level end
RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" } }
PLAYER_LEVEL_NO_SPEC = "Level %s |c%s%s|r"
DressUpTexturePath = function(race) return "bg-" .. race end
local scenes = 0
ModelSceneUtil = { SetUpCharacterSheetScene = function() scenes = scenes + 1 end }

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Inventory", "SaneUI_Inventory")
W.Fire("ADDON_LOADED", "SaneUI_Inventory")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Inventory == ns and not ns.off, "the module is made and started")
local Board, Edge, Slots = ns.Board, Core.Edge, ns.Slots

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

local function Push()
    W.Wait(1) -- a while after the square came under the mouse
    W.cursorX, W.cursorY = 1920, 0
    square:GetScript("OnEnter")(square)
    W.cursorX, W.cursorY = 960, 500 -- the mouse goes away again: the next push counts
    W.Wait(Edge.LOOK)
end
local function Stand()
    frame._group:Run(1)
    W.Wait(0)
end

-------------------------------------------------------------------------------
--  The character sheet
-------------------------------------------------------------------------------
check(Slots.Button(1) == nil, "the sheet is built the first time its window is shown, not at login")
Push()
check(handle.edge.full, "the mouse pushed into the corner fills the screen")
Stand()
check(Board.layouts:Has("character"), "the first layout holds the character sheet")
local panel = Board.Panel("character")
check(panel and panel:IsShown() and panel.title._text == "Tester Stub, the Patient", "its panel is headed with the character's name and title")
local head, neck = Slots.Button(1), Slots.Button(2)
check(head and neck and head:GetID() == 1, "its slots are made, each by the game's slot ID")
local count = 0
for name, id in pairs(SLOT_IDS) do
    local button = Slots.Button(id)
    if button and button:IsShown() then count = count + 1 end
end
check(count == 19 and Slots.Button(0) and not Slots.Button(0):IsShown(),
    "nineteen slots shown, the ammo slot hidden for a character that uses none")
check(Slots.main._points[1][4] == -40 and Slots.ranged:IsShown(), "the weapons' row as the game places it, the ranged slot shown")
check(drawn[head].texture == "helm" and drawn[head].quality == 3 and drawn[head].count == 1 and drawn[head].grey == false,
    "a slot with an item: its icon, quality and count")
check(drawn[neck].texture == "empty-NeckSlot", "an empty slot: the slot's own picture")
local level
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and widget._text == "Level 1 |cff3fc7ebMage|r" then level = widget end
end
check(level, "the level line, the class in its colour, as the game writes it")
check(scenes == 1, "the game's scene for the character sheet is set up when shown")
local scene
for _, widget in ipairs(W.frames) do
    if widget._kind == "ModelScene" then scene = widget end
end
check(scene, "the character's model scene stands in the left pane")

-- The game tells of changes while it is shown.
worn[2] = { texture = "amulet", count = 1, quality = 4, id = 1002, link = "|Hitem:1002|h[Amulet]|h" }
W.Fire("PLAYER_EQUIPMENT_CHANGED", 2, false)
check(drawn[neck].texture == "amulet" and drawn[neck].quality == 4, "an item put on: its slot is drawn anew")
worn[1].locked = true
W.Fire("ITEM_LOCK_CHANGED", 1, nil)
check(drawn[head].grey == true, "an equipped item locked (on the cursor): grey")
worn[1].locked, worn[1].broken = false, true
W.Fire("UPDATE_INVENTORY_DURABILITY")
check(drawn[head].tint[1] == Slots.RED[1] and drawn[head].tint[2] == 0 and drawn[head].grey == false, "a broken item: red, as the game tints it")
W.Fire("UNIT_MODEL_CHANGED", "player")
check(scenes == 2, "the character's model changed: set up anew")

-- Clicks and the tooltip, as on the game's sheet.
head:GetScript("OnClick")(head, "LeftButton")
check(picked[1] == 1, "a click picks the item up (or puts the cursor's there)")
head:GetScript("OnDragStart")(head)
check(picked[2] == 1, "a drag the same")
head:GetScript("OnClick")(head, "RightButton")
check(#picked == 2, "a right click calls nothing: using an equipped item is the game's own")
W.modifier = nil
head:GetScript("OnClick")(head, "LeftButton")
W.modifier = false
check(linked == "|Hitem:1001|h[Helm]|h" and #picked == 2, "a modified click links the item")
head:GetScript("OnEnter")(head)
check(GameTooltip._item == 1, "its tooltip is the game's for that slot")

-- A character that uses ammo: the weapons move left, the ammo slot shows.
ammoUser = true
Slots.Place()
check(Slots.main._points[1][4] == -60 and Slots.Button(0):IsShown(), "a character that uses ammo: the ammo slot beside the ranged slot")
ammoUser = false
Slots.Place()

-------------------------------------------------------------------------------
--  The board: more parts
-------------------------------------------------------------------------------
-- A part as a part's file registers it: what the board asks of it is noted.
local function Part(key, least)
    local part = { built = 0, shown = nil, size = nil, searched = nil }
    function part.Build(made) part.built, part.panel = part.built + 1, made end
    function part.Show(on) part.shown = on end
    function part.Size(width, height) part.size = { width, height } end
    function part.Search(text) part.searched = text end
    Board.Part(key, key:upper(), least, part)
    return part
end

-- A second part comes: side by side, the sheet as wide as it asks.
local bags = Part("bags", { 500, 300 })
ns.Window.Reboard()
check(bags.built == 1 and bags.shown == true and bags.size and Board.layouts:Has("bags"), "a part that registers later is laid out too")
local rects = Board.layouts.rects
check(rects.character and rects.bags and rects.character[1] < rects.bags[1]
    and rects.character[3] == ns.Sheet.LEFT + ns.Sheet.RIGHT + 2 * Core.Board.EDGE,
    "side by side, in the board's order, the sheet as wide as the game's sheet and its panel's edges")

-- The search box: every part hears it.
Board.Search("linen")
check(bags.searched == "linen", "what is typed into the search box goes to the parts")

-- Pushed again: back, every panel hidden, the sheet deaf to the game.
Push()
check(not handle.edge.full and bags.shown == false and not panel:IsShown(), "pushed again: back, the windows go at once")
Stand()
worn[2].texture = "other"
W.Fire("PLAYER_EQUIPMENT_CHANGED", 2, false)
check(drawn[neck].texture == "amulet", "hidden, the sheet does not listen to the game")

-- A part that fails is noted; the others and the module go on.
local broken = { Build = function() error("a broken part") end }
Board.Part("alts", "ALTS", { 300, 200 }, broken)
W.caught = {}
Push()
Stand()
check(not ns.off and handle.edge.full and bags.shown == true and drawn[neck].texture == "other",
    "a part that fails to build: the others are there (the sheet drawn as it is now), the module goes on")
W.caught = nil
Push()
Stand()

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
Push()
Stand()
ns.StandDown("a test")
check(ns.off and not frame:IsShown() and not handle.edge.full and bags.shown == false and not panel:IsShown(),
    "standing down: the windows go and the window with them")

io.write(("Inventory: all %d checks passed.\n"):format(passed))
