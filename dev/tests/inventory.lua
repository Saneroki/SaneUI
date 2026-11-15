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
-- The game's dropdown says whether its menu is open (DropdownButtonMixin:IsMenuOpen): here a test opens it by _open.
function methods:IsMenuOpen() return self._open == true end
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:SetTexCoord(...) self._coords = { ... } end
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
function methods:RegisterForClicks(...) self._clicks = { ... } end
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
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92, colorStr = "ff3fc7eb" } }
PLAYER_LEVEL_NO_SPEC = "Level %s |c%s%s|r"
DressUpTexturePath = function(race) return "bg-" .. race end
function methods:SetHitRectInsets(left, right, top, bottom) self._hit = { left, right, top, bottom } end
function methods:SetClipsChildren(on) self._clips = on end
-- The game's model scene that takes the mouse: its orbit camera (scene 595's: looking level at 1.02 from 3.9), turned
-- by the left button's drag and zoomed by the wheel; its field of view; its projection (the test's own focal length,
-- FOCAL points at a distance of one, drawn in pixels from its bottom left at PIXELS a point, or as shares of its size,
-- or, untrusted, from the screen's corner); its actors as the scene for the character sheet makes them, one of them
-- given the character's model.
local FOV, FOCAL, PIXELS = 0.9, 760, 1.5
local projection = "pixels"
local actors = {}
local function Actor()
    local actor = { requested = 2, aggressiveness = 4.8, position = { 0, 0, 0.04 }, scale = 1, loaded = false, bottom = 0 }
    function actor:SetRequestedScale(scale) self.requested = scale end
    function actor:SetNormalizedScaleAggressiveness(share) self.aggressiveness = share end
    function actor:SetPosition(x, y, z) self.position = { x, y, z } end
    function actor:SetOnModelLoadedCallback(fn) self.onLoaded = fn end
    function actor:IsLoaded() return self.loaded end
    function actor:GetScale() return self.scale end
    function actor:GetActiveBoundingBox() return -0.5, -0.5, self.bottom, 0.5, 0.5, 2 end
    actors[actor] = true
    return actor
end
local empty, player = Actor(), Actor()
W.templates.ModelSceneMixinTemplate = function(widget)
    local camera = { target = 1.02, downs = 0, ups = 0, wheels = 0 }
    function camera:GetYaw() return self.yaw end
    function camera:SetYaw(yaw) self.yaw = yaw end
    function camera:GetZoomDistance() return self.zoom end
    function camera:SetZoomDistance(zoom) self.zoom = zoom end
    function camera:GetTarget() return 0, 0, self.target end
    function camera:SetTargetSpline(spline) self.spline = spline end
    function camera:GetMinZoomDistance() return 2 end
    widget._camera = camera
    function widget:GetActiveCamera() return camera.zoom and camera end -- none before the scene is set up
    function widget:GetCameraFieldOfView() return FOV end
    function widget:EnumerateActiveActors() return pairs(actors) end
    function widget:Transform3DPointTo2D(_, _, z)
        local width, height = self:GetSize()
        local x, y = width / 2, height / 2 + (z - camera.target) * FOCAL / camera.zoom
        if projection == "shares" then return x / width, y / height, camera.zoom end
        if projection == "screen" then return 600 + x * PIXELS, 300 + y * PIXELS, camera.zoom end
        return x * PIXELS, y * PIXELS, camera.zoom
    end
    widget:SetScript("OnMouseDown", function() camera.downs = camera.downs + 1 end)
    widget:SetScript("OnMouseUp", function() camera.ups = camera.ups + 1 end)
    widget:SetScript("OnMouseWheel", function(_, delta) camera.wheels = camera.wheels + 1 camera.zoom = camera.zoom - delta * 0.19 end)
end
-- The game's spline: its points kept.
CreateCatmullRomSpline = function(dimensions)
    local spline = { dimensions = dimensions, points = {} }
    function spline:AddPoint(...) self.points[#self.points + 1] = { ... } end
    return spline
end
local scenes = 0
ModelSceneUtil = { SetUpCharacterSheetScene = function(scene)
    scenes = scenes + 1
    local camera = scene._camera
    camera.yaw, camera.zoom = 1.8325957, 3.9
    for actor in pairs(actors) do actor.requested, actor.aggressiveness, actor.position = 2, 4.8, { 0, 0, 0.04 } end
end }

-- The stats' page scrolls; the stats' tabs are as wide as their words (six a letter).
W.methods.SetVerticalScroll = function(self, offset) self._scroll = offset end
W.methods.GetVerticalScroll = function(self) return self._scroll or 0 end
W.methods.GetUnboundedStringWidth = function(self) return #(self._text or "") * 6 end
-- A font string's font: the game refuses words on one without (the stats' lines are written before they are laid out).
W.methods.SetFontObject = function(self, font) self._font = font end
-- The game's side tabs (LargeSideTabButtonTemplate): an icon, checked or not, a handler for the left button let go.
W.templates.LargeSideTabButtonTemplate = function(widget)
    widget.Icon = W.NewWidget("Texture", nil, widget)
    function widget:SetCustomOnMouseUpHandler(fn) self._mouseUp = fn end
end
-- The game's stats: its table of stats, the resistances.
CreateScrollBoxListLinearView = function()
    local view = {}
    function view:SetElementFactory(fn) self.factory = fn end
    function view:SetElementExtentCalculator(fn) self.extent = fn end
    return view
end
ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, _, view) box.view = view end }
CreateDataProvider = function(elements) return { elements = elements } end
ScrollBoxConstants = { RetainScrollPosition = true }
local statValues, shield = { HEALTH = 120, MOVESPEED = 100, CRITCHANCE = 5, HASTE = 0, BLOCK = 4 }, false
local function Fill(name) return { updateFunc = function(frame) frame.Value:SetText(tostring(statValues[name])) return statValues[name] end } end
PAPERDOLL_STATINFO = { HEALTH = Fill("HEALTH"), MOVESPEED = Fill("MOVESPEED"), CRITCHANCE = Fill("CRITCHANCE"),
                       HASTE = Fill("HASTE"), BLOCK = Fill("BLOCK") }
PAPERDOLL_STATCATEGORIES = {
    { categoryName = "General", unit = "player", stats = { { stat = "HEALTH" }, { stat = "MOVESPEED" } } },
    { categoryName = "Modifiers", unit = "player", stats = { { stat = "CRITCHANCE", hideAt = 0 }, { stat = "HASTE", hideAt = 0 } } },
    { categoryName = "Defense", unit = "player", stats = { { stat = "BLOCK", hideAt = 0, showFunc = function() return shield end } } },
    { categoryName = "Pet", unit = "pet", stats = { { stat = "HEALTH" } } },
}
rawset(_G, "Enum", rawget(_G, "Enum") or {})
Enum.Damageclass = { Fire = 2, Nature = 3, Frost = 4, Shadow = 5, Arcane = 6 }
local resists = { [2] = 15 }
UnitResistance = function(_, class) return 0, 0, resists[class] or 0, 0 end
PaperDollFrame_SetResistanceTooltips = function(tips, name, value) tips.tooltip = name .. " " .. value end
BreakUpLargeNumbers = function(value) return tostring(value) end
PaperDollFrame_FormatBonusValue = function(text) return text end
STAT_CATEGORY_RESISTANCE, DAMAGE_SCHOOL3 = "Resistance", "Fire"

-- The other characters' window: the account's characters as Core keeps them (Core.Data, Characters.lua) before
-- the login: two others (one has never opened its bank) and the account's own bank. Item names the game knows.
SaneUIData_Characters = { forever = { format = 1, characters = {
    ["Player-70-0000BEEF"] = { name = "Droopy Fairwind", class = "WARRIOR", level = 30, money = 1234567, seen = 20740,
                               bankSeen = 20738, bags = "4500\0311\0302589\03120", bank = "4500\0318", worn = "1001\0311\0302589\0311" },
    ["Player-70-0000CAFE"] = { name = "Ann Brook", class = "PRIEST", level = 12, money = 9900, seen = 20743, bags = "4501\0313" },
}, account = { bank = "4502\0315" } } }
GetServerTime = function() return 20743 * 86400 + 3600 end -- the server's day 20743
W.items[2589] = { name = "Linen Cloth", quality = 1 }
W.items[4501] = { name = "Wool Cloth", quality = 1 }
W.items[4502] = { name = "Silk Cloth", quality = 1 }
local requested = {} -- [item] = how often its name was asked of the game
C_Item.RequestLoadItemDataByID = function(id) requested[id] = (requested[id] or 0) + 1 end
C_Item.GetItemQualityByID = function(id) return W.items[id] and W.items[id].quality end
GetItemInfo = function(id) local item = W.items[id] if item then return item.name, "|Hitem:" .. id .. "|h[" .. item.name .. "]|h" end end
function GameTooltip:SetItemByID(id) self._itemID = id end
GetClassAtlas = function(class) return "classicon-" .. class end
LOCALIZED_CLASS_NAMES_MALE = { MAGE = "Mage", WARRIOR = "Warrior", PRIEST = "Priest" }
RAID_CLASS_COLORS.WARRIOR = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc69b6d" }
ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [3] = { r = 0, g = 0.44, b = 0.87 } }
C_CurrencyInfo = { GetCoinTextureString = function(copper) return copper .. "c" end }
-- Its lists are the game's (WowScrollBoxList, a linear view with a factory of rows), as the sheet's tabs have them:
-- given what to show, the list makes a row for each and has it drawn.
local linear = rawget(_G, "CreateScrollBoxListLinearView") or function() return {} end
CreateScrollBoxListLinearView = function(...)
    local view = linear(...)
    view.SetElementFactory = view.SetElementFactory or function(self, fn) self.factory = fn end
    view.SetElementExtent = view.SetElementExtent or function(self, extent) self.extent = extent end
    view.SetElementExtentCalculator = view.SetElementExtentCalculator or function(self, fn) self.extent = fn end
    return view
end
W.templates.WowScrollBoxList = W.templates.WowScrollBoxList or function(box)
    function box:SetDataProvider(provider)
        self.provider, self.rows = provider, {}
        for index, element in ipairs(provider.elements) do
            self.view.factory(function(kind, init)
                self.rows[index] = W.NewWidget(kind, nil, self)
                init(self.rows[index], element)
            end, element)
        end
    end
end

-- The game's bag keys, its override bindings, its bag windows and bag buttons (Keys.lua).
W.overrides = {}
GetBindingKey = function(action)
    if action == "TOGGLEBACKPACK" then return "B" end
    if action == "OPENALLBAGS" then return "SHIFT-B" end
end
-- Protected in the game: refused in a fight.
local function Fighting(name) if W.combat then error("ADDON_ACTION_BLOCKED: " .. name .. "() in combat", 3) end end
ClearOverrideBindings = function(owner) Fighting("ClearOverrideBindings") W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    Fighting("SetOverrideBinding")
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end
NUM_CONTAINER_FRAMES = 2
ContainerFrameCombinedBags = W.NewWidget("Frame", "ContainerFrameCombinedBags", UIParent)
ContainerFrame1 = W.NewWidget("Frame", "ContainerFrame1", UIParent)
ContainerFrame2 = W.NewWidget("Frame", "ContainerFrame2", UIParent)
for _, bagFrame in ipairs({ ContainerFrameCombinedBags, ContainerFrame1, ContainerFrame2 }) do bagFrame:Hide() end
BagsBar = W.NewWidget("Frame", "BagsBar", UIParent)
MainMenuBarBackpackButton = W.NewWidget("Button", "MainMenuBarBackpackButton", BagsBar)
OpenAllBags = function() ContainerFrameCombinedBags:Show() end
CloseAllBags = function() ContainerFrameCombinedBags:Hide() end
local cursorItem = false
CursorHasItem = function() return cursorItem end

-- The game's chat windows, and its toast in the middle of the screen (Blizzard_FrameXML/EventToastManager.lua)
CHAT_FRAMES = { "ChatFrame1", "ChatFrame2" }
for _, name in ipairs(CHAT_FRAMES) do _G[name] = W.NewWidget("Frame", name, UIParent) end
for _, event in ipairs({ "PLAYER_LEVEL_UP", "PLAYER_LEVEL_CHANGED", "TIME_PLAYED_MSG" }) do ChatFrame1:RegisterEvent(event) end
ChatFrame1:SetScript("OnEvent", function(_, event) W.chatHeard = W.chatHeard or {}; W.chatHeard[event] = true end)
Enum.EventToastEventType = { LevelUp = 0, LevelUpSpell = 1 }
EventToastManagerFrame = W.NewWidget("Frame", "EventToastManagerFrame", UIParent)
function EventToastManagerFrame:DisplayToast(firstToast) self.toastsShown = (self.toastsShown or 0) + (firstToast and 1 or 0) end
local timeAsked = 0
RequestTimePlayed = function() timeAsked = timeAsked + 1 end

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
check(Slots.main._points[1][1] == "CENTER" and Slots.ranged:IsShown(), "the weapons in their slots on the doll, the ranged slot shown")
check(drawn[head].texture == "helm" and drawn[head].quality == 3 and drawn[head].count == 1 and drawn[head].grey == false,
    "a slot with an item: its icon, quality and count")
check(drawn[neck].texture == nil, "an empty slot: no picture, the doll's own sketch in its slot shows")
local level
for _, widget in ipairs(W.frames) do
    if widget._kind == "FontString" and type(widget._text) == "string" and widget._text:match("^Level 1 |cff%x%x%x%x%x%xMage|r$")
        and widget._text ~= "Level 1 |cff3fc7ebMage|r" then level = widget end
end
check(level, "the level line, the class in its colour as ink on the paper, as the game writes it")
-- The specialization on it: in WoW: Forever only where the game says the class chooses one; in Retail, which has no
-- such call, always (as each game's own sheet writes it).
do
    local specs = rawget(_G, "C_SpecializationInfo")
    PLAYER_LEVEL = "Level %s |c%s%s %s|r"
    C_SpecializationInfo = { GetSpecialization = function() return 1 end,
                             GetSpecializationInfo = function() return 62, "Arcane" end,
                             IsSpecSelectionEnabled = function() return false end }
    W.Fire("PLAYER_LEVEL_UP")
    check(level._text:match("^Level 1 |cff%x+Mage|r$"), "WoW: Forever, a class that chooses none: the class alone: " .. level._text)
    W.Play("retail")
    C_SpecializationInfo.IsSpecSelectionEnabled = nil
    W.Fire("PLAYER_LEVEL_UP")
    check(level._text:match("^Level 1 |cff%x+Arcane Mage|r$"), "Retail: the specialization before the class: " .. level._text)
    W.Play("forever")
    C_SpecializationInfo, PLAYER_LEVEL = specs, nil
    W.Fire("PLAYER_LEVEL_UP")
    check(level._text:match("^Level 1 |cff%x+Mage|r$"), "back in WoW: Forever, without a specialization: as it was")
end
-- The weights go by the same name: a druid of the tree WoW: Forever names Feral Combat gets the feral line.
do
    local Weights, class, specs = ns.Weights, UnitClass, rawget(_G, "C_SpecializationInfo")
    UnitClass = function() return "Druid", "DRUID", 11 end
    C_SpecializationInfo = { GetSpecialization = function() return 2 end, GetSpecializationInfo = function() return 0, "Feral Combat" end }
    W.Fire("PLAYER_TALENT_UPDATE") -- the character's weights are asked for anew
    check(Weights.Now() == Weights.For("forever", "DRUID", "feral"), "a feral druid of WoW: Forever: the feral line, by the tree's name")
    UnitClass, C_SpecializationInfo = class, specs
    W.Fire("PLAYER_TALENT_UPDATE")
end
check(scenes == 1, "the game's scene for the character sheet is set up when shown")
local scene
for _, widget in ipairs(W.frames) do
    if widget._kind == "ModelScene" then scene = widget end
end
check(scene, "the character's model scene stands in the left pane")
local place = scene:GetParent()
do
    local Doll, PX, Model = ns.Doll, ns.Style.PX, ns.Model
    check(scene._template == "ModelSceneMixinTemplate" and near(scene:GetWidth(), Model.SIZE[1] * PX)
        and near(scene:GetHeight(), Model.SIZE[2] * PX) and scene:IsMouseEnabled() and scene:IsMouseWheelEnabled(),
        "the model turned by a drag and zoomed by the wheel (the game's scene that takes the mouse), at its one size")
    local point = place._points[1]
    check(point[1] == "TOPLEFT" and near(point[5], -Doll.MODEL_TOP * PX)
        and near(place:GetHeight(), (Doll.GROUND - Doll.MODEL_TOP) * PX),
        "the model's place: from under the level line down to the ground")
    local even = true
    for actor in pairs(actors) do
        even = even and actor.requested == 1 and actor.aggressiveness == 0 and actor.position[3] == 0 and actor.onLoaded ~= nil
    end
    check(even, "every race at one scale on the floor: the scene's own sizes, scaling and lifts per race taken out")
    local width, height = scene:GetSize()
    local function Feet(below)
        local at = scene._points[1]
        return at[1] == "BOTTOM" and at[2] == place and at[3] == "BOTTOM" and at[4] == 0 and near(at[5], -(height / 2 - below))
    end
    check(Feet(1.02 * FOCAL / 3.9), "before its model is loaded: the floor where the scene draws it (measured in pixels)")
    player.loaded, player.bottom = true, -0.05
    player.onLoaded(player)
    check(Feet(1.07 * FOCAL / 3.9), "its model loaded: the bottom of the model on the place's foot")
    local spline = scene._camera.spline
    check(spline and spline.dimensions == 3 and #spline.points == 2 and spline.points[1][3] == 0
        and spline.points[2][1] == 0 and spline.points[2][2] == 0, "the zoom moves the camera's target (a spline)")
    -- all the way in (2 from 3.9): the model's top (2 high) drawn at the top of its place, under the level line
    local target, below = 1.02 + spline.points[2][3], 1.07 * FOCAL / 3.9
    check(near((2 - target) * FOCAL / 2, place:GetHeight() - below),
        "zoomed all the way in, the camera has moved into the head: the model's top at the top of its place")
    local cover = Doll.covered
    check(not place._clips and not scene._clips and cover and near(cover._points[1][5], -Doll.FOOT * PX)
        and cover:GetParent():GetFrameLevel() > scene:GetFrameLevel(),
        "no clipping frame: the bronze plate again below the hero's place, over the model, hides its legs there")
    local hit = scene._hit
    check(near(hit[1], (width - place:GetWidth()) / 2) and near(hit[1], hit[2]) and near(hit[4], height / 2 - 1.07 * FOCAL / 3.9)
        and near(height - hit[3] - hit[4], place:GetHeight()), "it takes the mouse only over its place, though drawn larger")
    projection = "shares"
    player.onLoaded(player)
    check(Feet(1.07 * FOCAL / 3.9), "measured the same when the scene answers in shares of its size")
    projection = "screen"
    player.onLoaded(player)
    local ruled = 1.07 / 3.9 * math.sqrt(width * width + height * height) / (2 * math.tan(FOV / 2)) + height * Model.LOWER
    check(Feet(ruled), "an answer it cannot read: by the rule, its field of view across its diagonal, a little lower")
    projection = "pixels"
end
-- Turned or zoomed, the model goes back to how it stood once left alone for Model.REST seconds; never while dragged.
do
    local camera, Model = scene:GetActiveCamera(), ns.Model
    scene:GetScript("OnMouseDown")(scene, "LeftButton")
    camera.yaw = 1.8325957 + 2 * math.pi + 0.5 -- dragged once round and a little more
    W.Wait(Model.REST * 2)
    check(camera.downs == 1 and near(camera.yaw, 1.8325957 + 2 * math.pi + 0.5),
        "the game's own drag goes on under ours; while the button is held the model stays as turned")
    scene:GetScript("OnMouseUp")(scene, "LeftButton")
    check(camera.ups == 1, "the button let go: the game's camera told so too")
    W.Wait(Model.REST - 0.5)
    scene:GetScript("OnMouseWheel")(scene, 1)
    check(camera.wheels == 1 and near(camera.zoom, 3.9 - 0.19), "the wheel zooms, as the game's camera does")
    W.Wait(Model.REST - 0.5)
    check(near(camera.zoom, 3.9 - 0.19) and near(camera.yaw, 1.8325957 + 2 * math.pi + 0.5),
        "a turn of the wheel starts the wait anew")
    W.Wait(1)
    check(near(camera.zoom, 3.9) and near(camera.yaw, 1.8325957 + 2 * math.pi),
        "left alone: back to its first distance, turned the short way round to its first side")
end
do
    local controls
    for _, widget in ipairs(W.frames) do
        if widget._template == "ModelSceneControlFrameTemplate" then controls = widget end
    end
    check(not controls, "no turn, zoom or reset buttons")
    local stats = rawget(_G, "GetItemStats")
    GetItemStats = function()
        return { ITEM_MOD_STAMINA_SHORT = 8, RESISTANCE0_NAME = 62, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 12.46,
            ITEM_MOD_CRIT_RATING_SHORT = 1, ITEM_MOD_INTELLECT_SHORT = 3 }
    end
    ITEM_MOD_STAMINA_SHORT, RESISTANCE0_NAME, ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "Stamina", "Armor", "Damage Per Second"
    ITEM_MOD_CRIT_RATING_SHORT, ITEM_MOD_INTELLECT_SHORT, STAT_DPS_SHORT = "Critical Strike", "Intellect", "DPS"
    check(table.concat(ns.Slots.Stats("|Hitem:1|h[x]|h"), ",") == "12.5 DPS,62 Arm,+8 Stam,+3 Int,+1 Crit",
        "a strip's stats: DPS, armor, the primary stats, then the rest")
    GetItemStats = stats
end
-- An item let go over the model is put on, as on the game's sheet: by the left button or a drop, where it can be.
do
    local equipped = 0
    AutoEquipCursorItem = function() equipped = equipped + 1 end
    C_PaperDollInfo.CanAutoEquipCursorItem = function() return true end
    cursorItem = true
    scene:GetScript("OnMouseUp")(scene, "RightButton")
    check(equipped == 0, "the right button let go over the model puts nothing on")
    scene:GetScript("OnMouseUp")(scene, "LeftButton")
    scene:GetScript("OnReceiveDrag")(scene)
    check(equipped == 2, "the left button let go over the model, or a drop: the item on the cursor put on")
    C_PaperDollInfo.CanAutoEquipCursorItem = function() return false end
    scene:GetScript("OnMouseUp")(scene, "LeftButton")
    check(equipped == 2, "an item the game says cannot be put on is not")
    cursorItem, C_PaperDollInfo.CanAutoEquipCursorItem = false, nil
end

-- The game tells of changes while it is shown.
worn[2] = { texture = "amulet", count = 1, quality = 4, id = 1002, link = "|Hitem:1002|h[Amulet]|h" }
W.Fire("PLAYER_EQUIPMENT_CHANGED", 2, false)
check(drawn[neck].texture == "amulet" and drawn[neck].quality == 4, "an item put on: its slot is drawn anew")
worn[1].locked = true
W.Fire("ITEM_LOCK_CHANGED", 1, nil)
check(drawn[head].grey == true, "an equipped item locked (on the cursor): grey")
-- The inventory's events come in bursts: the slots are drawn once, on the next frame, however many came.
do
    local draws, texture = 0, SetItemButtonTexture
    SetItemButtonTexture = function(...) draws = draws + 1; return texture(...) end
    Slots.Update()
    local once = draws
    worn[1].locked, worn[1].broken, draws = false, true, 0
    W.Fire("UPDATE_INVENTORY_DURABILITY")
    W.Fire("UPDATE_INVENTORY_ALERTS")
    W.Fire("UNIT_INVENTORY_CHANGED", "player")
    check(draws == 0 and drawn[head].grey == true, "a burst of the inventory's events: nothing is drawn before the next frame")
    W.Wait(0)
    check(draws == once and drawn[head].tint[1] == Slots.RED[1] and drawn[head].tint[2] == 0 and drawn[head].grey == false,
        "then the slots once: a broken item red, as the game tints it: " .. draws .. " of " .. once)
    SetItemButtonTexture = texture
end
W.Fire("UNIT_MODEL_CHANGED", "player")
check(scenes == 2, "the character's model changed: set up anew")
UnitPVPName = function() return "Tester Stub, the Bold" end
W.Fire("UNIT_NAME_UPDATE", "target")
check(panel.title._text == "Tester Stub, the Patient", "another unit's name changed: the head as it was (the player's only)")
W.Fire("UNIT_NAME_UPDATE", "player")
check(panel.title._text == "Tester Stub, the Bold", "the player's: the head with the new title")
UnitPVPName = function() return "Tester Stub, the Patient" end
W.Fire("UNIT_NAME_UPDATE", "player")

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
check(Slots.Button(0):IsShown(), "a character that uses ammo: the ammo slot beside the ranged slot")
ammoUser = false
Slots.Place()

-------------------------------------------------------------------------------
--  The stats
-------------------------------------------------------------------------------
local Stats = ns.Stats
local view = Stats.View("player")
check(view and view.scroll:IsVisible(), "the stats' page in the stats' window, under the tabs")
local function Names()
    local names = {}
    for _, section in ipairs(view.sections) do
        names[#names + 1] = "[" .. section.name .. "]"
        for _, row in ipairs(section.rows) do names[#names + 1] = row.stat or row.Label._text end
    end
    return table.concat(names, " ")
end
check(Names() == "[General] HEALTH MOVESPEED [Modifiers] CRITCHANCE [Resistance] Arcane Fire Frost Nature Shadow",
    "the game's categories for the player, a stat at the value it hides at left out, a category with none shown left out, then the resistances: " .. Names())
local fire = view.sections[3].rows[2]
check(fire.Value._text == "15" and fire.tooltip == "Fire 15", "a resistance: the game's value and tooltip")
-- The lines are ours, filled by the game's function for their stat; the tooltip is the game's.
local health = view.sections[1].rows[1]
check(health.Value._text == "120" and health:GetParent() == view.child, "a stat's line filled by the game's function for it")
check(health.Label._font and health.Value._font, "its words have their font from the start: the game writes before the layout")
health.onEnterFunc = function(row) GameTooltip._stat = row end
health:GetScript("OnEnter")(health)
check(GameTooltip._stat == health and health.shade:IsShown(), "its tooltip the game's own, the line shaded under the mouse")
health:GetScript("OnLeave")(health)

-- The layout: one list in a narrow window, columns in a wide one, as even as the order lets them be.
local function Columns()
    local xs, seen = {}, {}
    for index in ipairs(view.sections) do
        local x = view.heads[index]._points[1][4]
        if not seen[x] then seen[x] = true xs[#xs + 1] = x end
    end
    return #xs
end
view.scroll:SetWidth(Stats.COLUMN + 2 * Stats.PAD)
view.scroll:GetScript("OnSizeChanged")(view.scroll)
check(Columns() == 1, "a narrow window: one list")
view.scroll:SetWidth(3 * Stats.COLUMN + 2 * Stats.GAP + 2 * Stats.PAD)
view.scroll:GetScript("OnSizeChanged")(view.scroll)
check(Columns() == 3 and view.heads[2]._points[1][4] > view.heads[1]._points[1][4], "a wide one: as many columns as fit, in the game's order")
view.scroll:SetWidth(10 * Stats.COLUMN)
view.scroll:GetScript("OnSizeChanged")(view.scroll)
check(Columns() == 3, "never more columns than sections")
check(health._width == view.heads[1]._width and health._height == Stats.ROW, "a line as wide as its column")

-- A stat changes: drawn anew a frame later, once however many events come.
statValues.HASTE, shield = 3, true
W.Fire("UNIT_STATS", "player")
W.Fire("COMBAT_RATING_UPDATE")
W.Wait(0)
check(Names():find("HASTE") and Names():find("%[Defense%] BLOCK"), "a stat changed: the page drawn anew a frame later")
-- Under a restriction the stats are secret to addon code: the page waits, and is drawn once it is over.
local before = Names()
W.combat = true
statValues.CRITCHANCE = 0
W.Fire("UNIT_STATS", "player")
W.Wait(0)
check(Names() == before and ns.Stats.Owed(), "in a fight the page stays as it was")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(not ns.Stats.Owed() and not Names():find("CRITCHANCE"), "the fight over: drawn anew")
-- Retail: its categories named by the frames they stand in on its sheet, a stat at the value it hides at known by the
-- number its function leaves on the line (it answers nothing), no resistances and no pet's stats (it has neither,
-- nor the pet's event: listening to it would fail).
do
    W.Play("retail")
    local categories, info = PAPERDOLL_STATCATEGORIES, PAPERDOLL_STATINFO
    local function Retail(name)
        return { updateFunc = function(frame) frame.Value:SetText(tostring(statValues[name])) frame.numericValue = statValues[name] end }
    end
    PAPERDOLL_STATINFO = { HEALTH = Retail("HEALTH"), CRITCHANCE = Retail("CRITCHANCE"), HASTE = Retail("HASTE") }
    PAPERDOLL_STATCATEGORIES = {
        { categoryFrame = "AttributesCategory", stats = { { stat = "HEALTH" } } },
        { categoryFrame = "EnhancementsCategory", stats = { { stat = "CRITCHANCE", hideAt = 0 }, { stat = "HASTE", hideAt = 0 } } },
    }
    CharacterStatsPane = { AttributesCategory = { titleText = "Attributes" }, EnhancementsCategory = { titleText = "Enhancements" } }
    Stats.Show(false)
    Stats.Show(true)
    check(Names() == "[Attributes] HEALTH [Enhancements] HASTE",
        "Retail: its categories by its frames' titles, a stat at its hide value left out, no resistances: " .. Names())
    check(not Core.errors["event PET_STATS_UPDATE"], "Retail: the pet's stats' event not listened to")
    W.Play("forever")
    PAPERDOLL_STATCATEGORIES, PAPERDOLL_STATINFO, CharacterStatsPane = categories, info, nil
    Stats.Show(false)
    Stats.Show(true)
    check(Names():find("[General] HEALTH", 1, true) and Names():find("[Resistance] Arcane", 1, true),
        "back in WoW: Forever: its categories and the resistances again: " .. Names())
end

-------------------------------------------------------------------------------
--  The other characters
-------------------------------------------------------------------------------
local Alts, Snapshot, Items, Roster = ns.Alts, ns.Snapshot, ns.Items, ns.Roster
CreateAtlasMarkup = function(atlas) return "[" .. atlas .. "]" end
MenuResponse = MenuResponse or { Close = 3 }
local bagsPanel = Board.Panel("bags")
check(bagsPanel and bagsPanel:IsShown() and not Board.Panel("alts") and ns.Bags.Whose() == nil and not Alts.foot:IsShown()
    and ns.Foot.frame:IsShown() and not Alts.note:IsShown(),
    "the other characters' things are the bags' own window's (Saneroki, 2026-11-15): the bags as they are at first")
-- The scheduler's frames (Core's Steps.lua): the characters' data read.
local function Steps()
    local steps = Core.Steps.frame
    for _ = 1, 10 do
        W.ms = W.ms + 20
        if steps:IsShown() and steps._scripts.OnUpdate then steps._scripts.OnUpdate(steps, 0.016) end
    end
    W.Wait(0)
end
W.Fire("LOADING_SCREEN_DISABLED")
Steps()
-- The dropdown of the characters: its lines, one by a part of its name.
local characters = Roster.menu
local function Lines()
    characters:GenerateMenu() -- as the game's dropdown makes its menu when it is opened
    local lines = {}
    for _, line in ipairs(characters._items) do
        if line.data then lines[#lines + 1] = line end
    end
    return lines
end
local function Names()
    local names = {}
    for index, line in ipairs(Lines()) do names[index] = line.text:match("|c%x%x%x%x%x%x%x%x(.-)|r") end
    return table.concat(names, ", ")
end
local function Character(part)
    for _, line in ipairs(Lines()) do
        if line.text:find(part, 1, true) then return line end
    end
end
local function Pick(part)
    local line = Character(part)
    line.fn(line.data)
end
-- What stands at a line's right, and how wide it makes the line.
-- The font string stands in for one of the menu's pool, as another line left it: 300 wide, its words at its left.
local function Right(line)
    local right = { width = 300, justify = "LEFT", points = {} }
    function right.ClearAllPoints(self) self.points = {} end
    function right.SetPoint(self, point, ...) self.points[#self.points + 1] = { point, ... } end
    function right.SetFontObject() end
    function right.SetJustifyH(self, justify) self.justify = justify end
    function right.SetHeight(self, height) self.height = height end
    function right.SetTextToFit(self, text) self.text, self.width = text, 40 end
    function right.GetUnboundedStringWidth() return 40 end
    local button = { AttachFontString = function() return right end,
                     fontString = { GetUnboundedStringWidth = function() return 100 end } }
    local wide, high = line.inits[1](button)
    return right.text, wide, high, right
end
local function Blocks()
    local list, blocks = {}, Alts.canvas.blocks
    for index = 1, blocks.count do
        local block = blocks[index]
        local word = (block.word or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        list[index] = block.level == 1 and word .. (block.number and " (" .. block.number .. ")" or "") or word .. "=" .. #block.entries
    end
    return table.concat(list, ", ")
end
local function Shown()
    local list = {}
    for index, button in ipairs(Alts.cells:Each()) do list[index] = ns.Cells.Record(button) end
    return list
end
-- The lines of what the search finds elsewhere (Bags.lua's Elsewhere), shown now.
local function ElsewhereLines()
    local lines = {}
    for _, widget in ipairs(W.frames) do
        if widget.key and widget.words and widget._parent and widget._parent.head and widget:IsVisible() then
            lines[#lines + 1] = widget
        end
    end
    return lines
end
local function ElsewhereLine(part)
    for _, line in ipairs(ElsewhereLines()) do
        if line.words._text:find(part, 1, true) then return line end
    end
end
check(not Alts.note:IsShown() and Names() == "Tester Stub, Ann Brook, Droopy Fairwind, Account Bank",
    "Core's data there: the dropdown, you first, the others by name, the account's own bank last: " .. Names())
check(Roster.WIDTH < 230 and not Alts.roster, "a dropdown on the title line, no column down the window's side")
do
    local droopy = Character("Droopy")
    local gold, wide, high, right = Right(droopy)
    check(right.width == 40 and right.justify == "RIGHT" and #right.points == 1 and right.points[1][1] == "RIGHT"
        and right.height == Roster.ROW,
        "the gold at the line's right end, as wide as its words: a font string of the menu's pool keeps no other line's width")
    check(droopy.text:find("[classicon-warrior]", 1, true) and droopy.text:find("|cffc79c6e", 1, true) and gold == "1230000c"
        and wide == 100 + 40 + Roster.CHECK + Roster.APART and high == Roster.ROW and droopy.response == MenuResponse.Close,
        "each by its class's icon, in its class's colour, its whole gold at the right: " .. droopy.text)
    local total
    for _, line in ipairs(characters._items) do total = total or line.title end
    check(total == "Total: 1244467c", "under them the gold of them all")
end
check(Character("Tester").checked(Character("Tester").data) and characters.word:find("Tester Stub", 1, true)
    and not Alts.foot:IsShown(), "the bags as they are at first: the one logged in the dropdown's word")
-- The bags' sidebar: its rows by their words.
local function SideRow(word)
    for _, row in ipairs(ns.BagSidebar.Rows()) do
        if row.word == word and row:IsShown() then return row end
    end
end
local function Click(word)
    local row = SideRow(word)
    row:GetScript("OnClick")(row, "LeftButton")
end
local PINNED, RECENT = ns.Categories.Word(ns.Categories.PINNED), ns.Categories.Word(ns.Categories.RECENT)
check(SideRow(ns.TEXT.bagsOneBag) and SideRow(PINNED) and SideRow(ns.TEXT.bagsAddCategory), "(the bags' sidebar: its views, Pinned, Add Category)")
Pick("Ann")
check(Character("Ann").checked(Character("Ann").data) and not Character("Tester").checked(Character("Tester").data)
    and characters.word:find("Ann Brook", 1, true) and Alts.foot.gold.text._text == "9900c" and Alts.foot:IsShown()
    and not ns.Foot.frame:IsShown() and not ns.Bags.strip:IsShown() and not ns.Bags.bar.sort:IsShown()
    and not ns.Bags.bar.bags:IsShown() and not ns.Bags.bar.coin:IsShown() and ns.Bags.searchBox:IsShown(),
    "another chosen: its things in the bags' own window, its name the dropdown's word, its gold at the foot; the bags' own buttons, strip and foot aside, the search stays")
check(SideRow(ns.TEXT.bagsAllItems) and not SideRow(ns.TEXT.bagsOneBag) and not SideRow(ns.TEXT.bagsEachBag)
    and not SideRow(PINNED) and not SideRow(RECENT) and not SideRow(ns.TEXT.bagsAddCategory) and SideRow("Miscellaneous"),
    "the bags' own sidebar: All Items and the categories (no slots, Pinned or Recent are kept of another)")
check(Blocks() == "Bags (1), Miscellaneous=1, Bank  Not seen yet: open the bank with this character, Equipped  Empty",
    "its bags by category; a bank never opened says so; nothing worn: empty: " .. Blocks())

-- Another one chosen: its things.
Pick("Droopy")
check(characters.word == "|c" .. ns.Style.InkHex(0.78, 0.61, 0.43) .. "Droopy Fairwind|r" and Alts.foot.gold.text._text == "1234567c"
    and Alts.foot.line._text == "Level 30 |c" .. ns.Style.InkHex(0.78, 0.61, 0.43) .. "Warrior|r  |c" .. ns.Style.FAINT_HEX .. "Seen 3 |4day:days; ago|r",
    "a click in the dropdown: that one's name in its class's colour, its gold, its level and class, when it was seen")
check(Blocks() == "Bags (2), Miscellaneous=2, Bank  Seen 5 |4day:days; ago (1), Miscellaneous=1, Equipped (2), Armor=1, Miscellaneous=1"
    or Blocks():find("^Bags %(2%), Miscellaneous=2, Bank  Seen 5 |4day:days; ago %(1%)"), "each place under its head with how many, by category: " .. Blocks())
check(ns.Bags.bar.count._text == ns.TEXT.bagsCells:format(5), "the title line's count: how many of its items are shown")
local shown = Shown()
local first = Alts.cells:Each()[1]
check(shown[1].item == 2589 and shown[2].item == 4500 and shown[3].count == 8 and drawn[first].count == 20
    and drawn[first].texture == 2000 + 2589 and drawn[first].quality == 1 and first._kind == "ItemButton",
    "each the game's item button, sorted as the bags sort: icon, count, quality; a place's own count")
check(requested[1001] == 1, "what it wears shown as items (Core has not read it slot by slot); a name the game does not know yet is asked for")
first:GetScript("OnEnter")(first)
check(GameTooltip._itemID == 2589, "its tooltip is the game's for the item")
local draws, draw = 0, Alts.canvas.Draw
Alts.canvas.Draw = function(...) draws = draws + 1 return draw(...) end
W.items[1001] = { name = "Helm", quality = 3 }
W.Fire("GET_ITEM_INFO_RECEIVED", 1001, true)
W.Wait(0)
check(draws == 0, "a name that comes waits a moment for the others that come with it")
W.Wait(Alts.NAMES)
check(draws == 1 and Items.Record(1001).name == "Helm" and requested[1001] == 1, "the name comes: drawn anew; asked once only")
Alts.canvas.Draw = nil
check(Snapshot.Learned(1001) == false, "a name the window does not wait for draws nothing anew")
local was = linked
first = Alts.cells:Each()[1]
first:GetScript("OnClick")(first, "LeftButton")
check(linked == was and W.cursor == nil and #picked == 2, "a click moves nothing: an alt's things are only looked at")
W.modifier = nil
first:GetScript("OnClick")(first, "LeftButton")
W.modifier = false
check(linked == "|Hitem:2589|h[Linen Cloth]|h", "a modified click links it")
check(Alts.cells.make == Items.Button and Alts.cells ~= ns.Cells.bags, "read-only buttons of its own, not the bags' pool")
do
    local menus = #W.menus
    Alts.Clicked(first, "RightButton")
    check(#W.menus == menus, "a right click alone: nothing")
    IsAltKeyDown = function() return true end
    Alts.Clicked(first, "RightButton")
    IsAltKeyDown = nil
    check(#W.menus == menus + 1, "Alt and a right click: the item's menu, as in the bags")
end

-- The search: across every character.
Pick("Ann")
Board.Search("linen")
check((Right(Character("Droopy"))) == "21" and (Right(Character("Ann"))) == "" and Character("Ann").text:find("|cff808080", 1, true)
    and Character("Tester").text:find("|cff808080", 1, true),
    "the dropdown says how many each has of what is found; one without any of it greyed")
local total
for _, line in ipairs(characters._items) do total = total or line.title end
check(not total, "no total while searching")
check(characters.word:find("Ann Brook", 1, true) and Alts.canvas.blocks.count == 0 and ElsewhereLine("Droopy Fairwind")
    and ElsewhereLine("Droopy Fairwind").words._text:find("(21)", 1, true) and not ElsewhereLine("Ann Brook") and not Alts.note:IsShown(),
    "the chosen one has none: Found elsewhere says who has it")
ElsewhereLine("Droopy Fairwind"):GetScript("OnClick")(ElsewhereLine("Droopy Fairwind"))
check(characters.word:find("Droopy", 1, true) and Blocks():find("^Bags %(1%), Miscellaneous=1, Equipped %(1%)") and Shown()[1].item == 2589 and #Shown() == 2,
    "a click on it: that one's things, only what is found, a place without it left out: " .. Blocks())
Board.Search("4502")
Pick("Account")
check(characters.word:find("Account Bank", 1, true) and Shown()[1].item == 4502, "an item's ID finds it too: in the account's bank")
Pick("Ann")
Board.Search("zzz")
check(characters.word:find("Ann Brook", 1, true) and Alts.canvas.blocks.count == 0 and Alts.note:IsShown()
    and #ElsewhereLines() == 0, "found nowhere: says so")
Board.Search("")
check(characters.word:find("Ann Brook", 1, true) and Blocks():find("^Bags %(1%)") and not Alts.note:IsShown()
    and (Right(Character("Ann"))) == "9900c" and ns.Bags.searchBox:GetText() == "",
    "the search cleared: everything again, the bags' box empty too")
check(requested[4500] == 1 and Snapshot.Name(4500) == nil, "a name the game never tells is asked for once")

-- The bags' sidebar for another: All Items and the bags' categories with its counts; a click shows one alone.
Pick("Droopy")
check(SideRow(ns.TEXT.bagsAllItems).bar:IsShown() and SideRow(ns.TEXT.bagsAllItems).count._text == "3"
    and SideRow("Miscellaneous").count._text == "3",
    "All Items lit, every category with how many of the character's items it holds")
check(SideRow("The Armory") and SideRow("Consumables") and not SideRow("Head") and not SideRow("Potions")
    and SideRow("The Armory").arrow:IsShown() and SideRow("The Armory").box:IsShown(),
    "the bags' groups, folded at first, with their arrow and box")
do
    local armory = SideRow("The Armory")
    armory.arrow:GetScript("OnClick")(armory.arrow)
    W.Wait(0)
    check(SideRow("Head") and not ns.Categories.Folded("armory"), "a group's arrow lists its members, the bags' own")
    armory = SideRow("The Armory")
    armory.arrow:GetScript("OnClick")(armory.arrow)
    W.Wait(0)
    check(not SideRow("Head"), "and folds them again")
end
Click("Miscellaneous")
check(Blocks():find("^Bags %(2%), Miscellaneous=2, Bank[^,]*%(1%), Miscellaneous=1$") ~= nil, "a category alone: its items in each place, no doll or worn: " .. Blocks())
check(SideRow("Miscellaneous").bar:IsShown() and not SideRow(ns.TEXT.bagsAllItems).bar:IsShown(), "the category lit")
Click("Trade Goods")
check(Blocks() == "" and not Alts.note:IsShown(), "a category with nothing of this one: nothing, no heads")
Click(ns.TEXT.bagsAllItems)
Click("Consumables")
check(Blocks() == "", "a group: its members' items")
Click(ns.TEXT.bagsAllItems)
-- The dropdown View: the bags' own, their displays, Sort By, the item size.
local viewMenu = ns.Bags.viewMenu
local function ViewPick(text)
    viewMenu:GenerateMenu()
    for _, line in ipairs(viewMenu._items) do
        if line.text == text then return line.fn(line.data) end
    end
    error("no line " .. text)
end
local function Kinds()
    local kinds = {}
    for index = 1, 40 do
        local place = Alts.canvas.places[index]
        if place and place.kind then kinds[place.kind] = (kinds[place.kind] or 0) + 1 end
    end
    return kinds
end
local look, order = ns.options.bags.look, ns.options.bags.sort
ViewPick("Grid")
check(Kinds().cell == 5, "the grid: its items as cells")
ViewPick("List")
check(ns.options.bags.look == "list" and Kinds().row == 5, "the list, the bags' choice: a line per item")
ViewPick("Compact")
check(Kinds().cell == 5 and Kinds().label ~= nil, "compact: the categories' names over them")
ViewPick("Grid")
ViewPick("Name")
check(ns.options.bags.sort == "name" and Shown()[1].item == 4500, "Sort By, the bags': a name not known yet first")
ViewPick("Default")
ns.Categories.Assign(2589, "trade") -- the player puts an item into another category in the bags
ns.Bags.Redraw()
check(Items.Record(2589).category == "trade" and Blocks():find("Trade Goods=1", 1, true), "an item put into another category in the bags: shown under that one at once")
ns.Categories.Assign(2589, nil)
ns.options.coin, ns.options.itemLevel = true, false
Core.Set(ns.name, "grey", false)
W.Wait(0)
ns.options.coin, ns.options.itemLevel = nil, nil
-- The item size: the bags' slider; a narrow window makes the items smaller by itself.
do
    local Layout = ns.Layout
    MinimalSliderWithSteppersMixin = { Event = { OnValueChanged = 1 }, Label = { Right = 1 } }
    viewMenu:GenerateMenu()
    local row
    for _, line in ipairs(viewMenu._items) do
        if line.title == ns.TEXT.bagsItemSize then row = line end
    end
    check(row, "the row Item Size in the dropdown")
    local told
    local slider = { SetWidth = function() end, ClearAllPoints = function() end, SetPoint = function() end, UnregisterCallback = function() end,
                     Init = function(self, value, low, high, steps, labels) self.value, self.low, self.high, self.steps, self.labels = value, low, high, steps, labels end,
                     RegisterCallback = function(_, _, fn) told = fn end }
    row.inits[1]({ AttachTemplate = function() return slider end })
    local scale = ns.options.bags.scale
    told(nil, 100)
    ns.Bags.Size(1200)
    local function SizeOf()
        for index = 1, 40 do
            local place = Alts.canvas.places[index]
            if place and place.kind == "cell" then return place.size end
        end
    end
    check(SizeOf() == Layout.SIZE, "wide enough: the items as large as chosen")
    told(nil, 73)
    check(ns.options.bags.scale == 75 and SizeOf() == math.floor(Layout.SIZE * 0.75 + 0.5), "the slider moved: the bags' size, drawn at once")
    told(nil, 100)
    ns.Bags.Size(ns.Bags.LEAST[1] + 30)
    check(SizeOf() < Layout.SIZE and SizeOf() >= Layout.SMALLEST, "a narrow window: its items smaller by themselves: " .. tostring(SizeOf()))
    told(nil, scale)
end
ns.options.bags.look, ns.options.bags.sort = look, order
ns.Bags.Size(Board.layouts.rects.bags[3]) -- as wide as its panel again
check(not Board.layouts.rects.alts, "no window of its own on the full screen: the bags' window holds it")

-- Hidden, it listens to nothing; opened again, the bags as they are.
Push()
worn[3] = { texture = "spaulders", count = 1, quality = 2, id = 1003 }
W.Fire("PLAYER_EQUIPMENT_CHANGED", 3, false)
Steps()
check(Core.Data.Items(Core.charKey, "worn")[3].item == 1003, "hidden: Core's data changes, nothing is drawn")
Stand()
Push()
Stand()
check(ns.Bags.Whose() == nil and ns.Foot.frame:IsShown() and not Alts.foot:IsShown() and characters.word:find("Tester Stub", 1, true),
    "the window opened again: the bags as they are")
Pick("Tester")
check(ns.Bags.Whose() == nil, "you chosen in the dropdown: your bags as they are")
ns.Bags.Face(Core.charKey, true) -- your things as last seen (a line of what the search finds elsewhere shows them)
check(Alts.foot.line._text:find("Logged in now", 1, true) and Blocks():find("^Bags  Empty") and Alts.doll:IsShown()
    and Blocks():find("Equipped"), "you as last seen: what you wear as Core last read it: " .. Blocks())
Character("Droopy").tooltip(GameTooltip)
check(GameTooltip._lines and GameTooltip._lines[#GameTooltip._lines] == "1234567c", "a character's tooltip: the rest of what is known of it")
-- A character's facts of a wrong kind (a hand edit, an older version) are left out; nothing fails.
do
    local odd = { key = "odd", name = "Odd Entry", class = 7, level = {}, realm = true, money = "lots" }
    Roster.Show({ odd }, "odd", nil)
    local about = Alts.About(odd)
    check(characters.word:find("Odd Entry", 1, true) and #about == 2 and about[2][1] == "Level ? |cff1e1711|r" and not Core.errors["Inventory: alts"],
        "a character's class, level and realm of a wrong kind: left out of its line and its tooltip, nothing fails")
    ns.Bags.Redraw()
end
-- Its menu is made anew only while it is open: the game's dropdown makes it afresh when it is opened.
do
    local generate, made = characters.GenerateMenu, 0
    characters.GenerateMenu = function(self) made = made + 1; return generate(self) end
    ns.Bags.Redraw()
    check(made == 0, "the window drawn anew while its menu is closed: the menu waits for its opening")
    characters._open = true
    ns.Bags.Redraw()
    characters._open, characters.GenerateMenu = nil, nil
    check(made == 1, "its menu open: made anew with the window: " .. made)
end

-- What you wear, read by Core slot by slot (Core.Data.Worn): the game's paper doll, its slots as our sheet has
-- them, as wide as the items' room, the weapons' row in the middle below.
function methods:SetMatchesSearch(on) self._matches = on end
SHIRTSLOT = "Shirt"
W.items[1002] = { name = "Amulet", quality = 4 }
ns.Bags.Face(Core.charKey, true) -- your things as last seen
local function Worn(doll, name)
    for _, button in ipairs(doll.buttons) do
        if button.slotName == name then return button end
    end
end
local doll = Alts.doll
local edge, wide, step = Items.DOLL_EDGE, 228, Slots.SIZE + Slots.GAP
Items.DrawDoll(doll, { slots = { [1] = 1001, [2] = 1002 } }, wide)
local helm, amulet, shirt, hands = Worn(doll, "HeadSlot"), Worn(doll, "NeckSlot"), Worn(doll, "ShirtSlot"), Worn(doll, "HandsSlot")
check(#doll.buttons == 20 and doll:IsShown() and helm.item == 1001 and drawn[helm].texture == 3001 and drawn[helm].quality == 3
    and amulet.item == 1002 and drawn[amulet].texture == 3002 and shirt.item == nil and drawn[shirt].texture == nil,
    "your gear in its slots, drawn as the game draws an item; an empty slot its pencil slot alone")
check(helm._points[1][4] == edge and helm._points[1][5] == -edge and shirt._points[1][5] == -edge - 4 * step
    and hands._points[1][4] == edge and hands._points[1][5] == -edge - 7 * step
    and amulet._points[1][4] == wide - edge - Slots.SIZE and amulet._points[1][5] == -edge,
    "eight down the left, eight down the right, as far apart as the room is wide")
local main, off, ranged, ammo = Worn(doll, "MainHandSlot"), Worn(doll, "SecondaryHandSlot"), Worn(doll, "RangedSlot"), Worn(doll, "AmmoSlot")
local weapons = 3 * Slots.SIZE + 2 * Slots.GAP
check(main._points[1][4] == (wide - weapons) / 2 and main._points[1][5] == -edge - 8 * step
    and off._points[1][4] == (wide - weapons) / 2 + step and ranged:IsShown() and not ammo:IsShown(),
    "the weapons' row in the middle below them, the ranged slot as the game shows one; no ammo worn: no ammo slot")
helm:GetScript("OnEnter")(helm)
check(GameTooltip._itemID == 1001, "a slot's tooltip: the game's for the item")
shirt:GetScript("OnEnter")(shirt)
check(GameTooltip._text == "Shirt", "an empty slot's: its name")
was = linked
helm:GetScript("OnClick")(helm, "LeftButton")
check(linked == was and #picked == 2 and W.cursor == nil, "a click moves nothing")
W.modifier = nil
helm:GetScript("OnClick")(helm, "LeftButton")
W.modifier = false
check(linked == "|Hitem:1001|h[Helm]|h", "a modified click links it")
-- Ammo worn: its slot beside the ranged one; a client without a ranged slot: neither.
local element = { slots = { [0] = 2512, [1] = 1001 } }
local function Redraw() Items.DrawDoll(doll, element, wide) end
Redraw()
local line = weapons + Slots.AMMO_GAP + Slots.AMMO
check(ammo:IsShown() and ammo.item == 2512 and ammo._width == Slots.AMMO and main._points[1][4] == (wide - line) / 2
    and ammo._points[1][4] == (wide - line) / 2 + weapons + Slots.AMMO_GAP and amulet.item == nil and drawn[amulet].texture == nil,
    "ammo worn: its slot beside the ranged one, smaller, the row still in the middle; a doll drawn anew is drawn whole")
rangedShown = false
Redraw()
check(not ranged:IsShown() and not ammo:IsShown(), "a client that shows no ranged slot: none, and no ammo beside it")
element.slots[18] = 2504
Redraw()
check(ranged:IsShown() and ranged.item == 2504 and ammo:IsShown(), "unless something is in it")
rangedShown = true
-- The bags worn in their slots: items under Equipped's head, the doll below. While searching, the doll only if
-- something in it is found.
local function Equipped() return "Equipped" end
local bagWorn = { item = 4500, count = 1 }
local sections, wornDoll = Items.Sections({ { place = "worn", items = { { item = 1001, count = 1 }, bagWorn }, slots = { [1] = 1001, [20] = 4500 } } }, Equipped, false)
check(#sections == 1 and wornDoll.slots[1] == 1001 and wornDoll.found == nil and sections[1].doll and #sections[1].slots == 1
    and sections[1].slots[1].item == 4500 and sections[1].slots[1].count == 1, "the bags worn: items under the head, the doll below")
sections, wornDoll = Items.Sections({ { place = "worn", items = { bagWorn }, slots = { [1] = 1001, [20] = 4500 } } }, Equipped, true)
check(#sections == 1 and not wornDoll and #sections[1].slots == 1, "a bag found: it alone, no doll")
Board.Search("helm")
check(characters.word:find("Tester Stub", 1, true) and Blocks():find("^Equipped") and Alts.doll:IsShown()
    and Worn(doll, "HeadSlot")._matches == true and Worn(doll, "NeckSlot")._matches == false and Worn(doll, "ShirtSlot")._matches == true,
    "searching: the doll whole, what is found lit, the rest dimmed as the game's bags dim it; an empty slot not")
Board.Search("")
ns.Bags.Size(Board.layouts.rects.bags[3]) -- as wide as its panel again

-- One search for both (Saneroki, 2026-11-15: "So the search works across alts and banks as well"): with the bags shown,
-- the bags' box lists under them each other character that has any of it, with how many; a click shows that one's
-- things, found; from there, a line takes you back to your bags.
do
    local Bags = ns.Bags
    Pick("Tester")
    local box = Bags.searchBox
    box:SetText("linen")
    box:GetScript("OnTextChanged")(box, true)
    local droopy = ElsewhereLine("Droopy Fairwind")
    check(Bags.Whose() == nil and droopy and droopy.words._text:find("%(21%)") and characters.word:find("Tester Stub", 1, true),
        "the bags shown, searching: under them a line for another that has any of it, how many")
    droopy:GetScript("OnClick")(droopy)
    check(Bags.Whose() ~= nil and Alts.foot:IsShown() and characters.word:find("Droopy Fairwind", 1, true)
        and Blocks():find("^Bags %(%d+%)") and box:GetText() == "linen" and not ElsewhereLine("Droopy Fairwind"),
        "a click: that one's things shown, found, the search kept: " .. Blocks())
    box:SetText("")
    box:GetScript("OnTextChanged")(box, true)
    Pick("Tester")
    check(Bags.Whose() == nil and ns.Foot.frame:IsShown() and Bags.bar.sort:IsShown() and #Alts.cells:Each() == 0,
        "(the bags again: their buttons and foot back, the other's things gone from the scroll area)")
end

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

-- A part comes later (one more key in the board's order: the module's own parts are all there): side by side,
-- the sheet as wide as it asks.
Board.ORDER[#Board.ORDER + 1] = "later"
Board.FIRST.later = true -- and in the first layout, as the module's first windows are
local bags = Part("later", { 160, 160 })
ns.Window.Reboard()
check(bags.built == 1 and bags.shown == true and bags.size and Board.layouts:Has("later"), "a part that registers later is laid out too")
local rects = Board.layouts.rects
local asks = Board.Least("character", math.floor(ns.Doll.WIDTH * ns.Sheet.LEAST), 0)[1]
check(rects.character and rects.bags and rects.character[1] < rects.bags[1]
    and rects.character[3] <= asks and rects.character[3] > 0.85 * asks,
    "side by side, in the board's order, the doll's window as wide as it asks (squeezed with the others on a small screen)")

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
local firstLine = view.sections[1].rows[1]
statValues.HEALTH = 999
W.Fire("UNIT_STATS", "player")
W.Wait(0)
check(firstLine.Value._text ~= "999", "hidden, the stats do not listen either")

-- A part that fails is noted; the others and the module go on.
local broken = { Build = function() error("a broken part") end, Show = function() error("a broken part") end }
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
--  The bag keys
-------------------------------------------------------------------------------
local Keys = ns.Keys
local function Overrides()
    for _, list in pairs(W.overrides) do return list end
    return {}
end
check(Overrides().B == Keys.COMMAND and Overrides()["SHIFT-B"] == Keys.COMMAND,
    "your bag keys run ours (the game's override bindings, your key bindings as they are)")
check(ContainerFrameCombinedBags:GetParent() ~= UIParent and ContainerFrame1:GetParent() == ContainerFrameCombinedBags:GetParent()
    and not ContainerFrameCombinedBags:GetParent():IsShown(), "the game's bag windows stand in a hidden frame of ours")
OpenAllBags()
check(not ContainerFrameCombinedBags:IsVisible(), "opened by the game (a vendor, the bank): nothing of them shows")
CloseAllBags()
check(not handle.edge.full, "the full screen small before the key")
Keys.Press()
Stand()
check(handle.edge.full and Board.Has("bags") and Board.Panel("bags"):IsShown(), "the bag key: the full screen with the bags on it")
Keys.Press()
check(not handle.edge.full, "pressed again: back to its size")
Stand()
check(BagsBar:GetParent() ~= UIParent and not BagsBar:IsVisible() and not MainMenuBarBackpackButton:IsVisible(),
    "the game's bag bar is gone: nothing of it to see or click")
-- Your bag key changed in a fight: the game refuses override bindings until it is over, so ours waits for its end
-- (Core.AfterCombat), and the old key runs ours meanwhile.
do
    W.Combat(true)
    local bindings = GetBindingKey
    GetBindingKey = function(action) if action == "TOGGLEBACKPACK" then return "F" end end
    W.Fire("UPDATE_BINDINGS")
    local waited = Overrides().B == Keys.COMMAND and Overrides().F == nil and Core.Owed("Inventory: keys")
    W.Combat(false)
    check(waited and Overrides().F == Keys.COMMAND and Overrides().B == nil and not Core.Owed("Inventory: keys") and not ns.off,
        "your bag key changed in a fight: ours waits for the fight's end, the old key runs ours meanwhile; over, the new key does")
    GetBindingKey = bindings
    W.Fire("UPDATE_BINDINGS")
end
-- The game's bags chosen in Classic windows: they show, until they are all closed. Opened by the game while they stand
-- in our hidden frame (a vendor), they come into sight only once given back, and their OnShow runs then: the game runs
-- it when a frame starts being seen, by its parent as by itself.
do
    local seen = 0
    ContainerFrameCombinedBags:HookScript("OnShow", function() seen = seen + 1 end)
    OpenAllBags()
    local unseen = seen == 0 and ContainerFrameCombinedBags:IsShown() and not ContainerFrameCombinedBags:IsVisible()
    Keys.GameBags(true)
    check(unseen and seen == 1, "opened in our hidden frame (shown, unseen, its OnShow not run), then chosen: its OnShow ran as it came into sight")
end
check(ContainerFrameCombinedBags:GetParent() == UIParent and ContainerFrameCombinedBags:IsVisible(), "the game's bags chosen: they show")
check(not BagsBar:IsVisible(), "its bag bar stays gone meanwhile")
CloseAllBags()
check(ContainerFrameCombinedBags:GetParent() ~= UIParent, "all closed: hidden again, ours are the bags")
Core.Set(ns.name, "bagKeys", false)
check(next(Overrides()) == nil and ContainerFrameCombinedBags:GetParent() == UIParent and BagsBar:GetParent() == UIParent,
    "the setting off: the game's keys, bags and bag bar are the game's")
Core.Set(ns.name, "bagKeys", true)
check(Overrides().B == Keys.COMMAND and ContainerFrameCombinedBags:GetParent() ~= UIParent and BagsBar:GetParent() ~= UIParent, "on again")
-- Can expand to fullscreen off: the full screen never comes, so the bag keys and bags are the game's, and a key
-- pressed then wishes for nothing later (the bags taken off the layout first, to see that they stay off).
Push()
Stand()
Board.layouts:Toggle("bags")
Push()
Stand()
Core.Set(ns.name, "expand", false)
OpenAllBags()
check(next(Overrides()) == nil and ContainerFrameCombinedBags:GetParent() == UIParent and ContainerFrameCombinedBags:IsVisible(),
    "Can expand to fullscreen off: your bag keys are the game's, and the game's bags show")
local classic = handle.options.classic
check(not classic[1].ready() and not classic[2].ready(), "nor is there the button Sane UI on the game's sheet and bags then")
CloseAllBags()
check(BagsBar:GetParent() == UIParent, "its bag bar is back: the only way to its bags")
Keys.Press()
Stand()
check(not handle.edge.full, "nor does ours come by our own key")
Core.Set(ns.name, "expand", true)
check(Overrides().B == Keys.COMMAND and ContainerFrameCombinedBags:GetParent() ~= UIParent and classic[1].ready()
    and classic[2].ready(), "on again: ours, and the button Sane UI on the game's sheet and bags")
Push()
Stand()
check(handle.edge.full and not Board.Has("bags"), "a key pressed while the full screen could not come wishes for nothing later")
Board.layouts:Toggle("bags")
Push()
Stand()
-- Edit Mode open: the full screen cannot come until it closes, so the bag keys and bags are the game's meanwhile.
EventRegistry:TriggerEvent("EditMode.Enter")
OpenAllBags()
check(next(Overrides()) == nil and ContainerFrameCombinedBags:GetParent() == UIParent and ContainerFrameCombinedBags:IsVisible(),
    "Edit Mode open: your bag keys are the game's, and the game's bags show")
check(BagsBar:GetParent() ~= UIParent, "but not its bag bar: nothing to place there")
CloseAllBags()
EventRegistry:TriggerEvent("EditMode.Exit")
check(Overrides().B == Keys.COMMAND and ContainerFrameCombinedBags:GetParent() ~= UIParent, "Edit Mode closed: ours again")

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
Push()
-- The stats' short words (Core), and a new level: the middle of the screen says it, in place of the game's toast and
-- its lines in the chat.
do
    local LevelUp, game = ns.LevelUp, EventToastManagerFrame
    local view
    local function Said()
        for _, widget in ipairs(W.frames) do
            if widget._kind == "Frame" and widget._width == LevelUp.WIDTH then view = widget end
        end
        local texts = {}
        for _, part in ipairs(W.frames) do
            if part._parent == view and part._kind == "FontString" and part._shown and part._text then texts[#texts + 1] = part._text end
        end
        return table.concat(texts, "/")
    end
    local function Toast(kind)
        game.currentDisplayingToast = kind and { toastInfo = { eventType = kind } } or nil
        game:DisplayToast()
    end
    local LEVEL = Enum.EventToastEventType.LevelUp

    check(Core.StatWord("Strength") == "Str" and Core.StatWord("critical strike") == "Crit" and Core.StatWord("Crit Chance") == "Crit"
        and Core.StatWord("Crit Damage") == "Crit dmg" and Core.StatWord("Armor") == "Arm" and Core.StatWord("Fire Resistance") == "Fire Res"
        and Core.StatWord("Block Value") == "BVal" and Core.StatWord("Bonus Armor") == "Bonus Arm" and Core.StatWord("Spell Damage") == "SDmg"
        and Core.StatWord("Attack Speed") == "ASpd" and Core.StatWord("Armor Penetration") == "APen",
        "the stats' short words, in any case")
    check(Core.StatWord("Spellbook") == "Spellbook" and Core.StatWord(nil) == nil, "a word that is no stat stays as it came")
    check(Core.StatLine("+8 Stamina") == "+8 Stam" and Core.StatLine("62 Armor") == "62 Arm" and Core.StatLine("-2 Agility") == "-2 Agi"
        and Core.StatLine("|cff00ff00+2.2|r damage per second") == "|cff00ff00+2.2|r DPS",
        "a line of a number and a stat is shortened, a coloured number too")
    check(Core.StatLine("Increases Stamina by 26.") == "Increases Stamina by 26." and Core.StatLine("12 Goblins") == "12 Goblins"
        and Core.StatLine("Equip: +20 Attack Power.") == "Equip: +20 Attack Power.", "a sentence stays as it is")

    check(LevelUp.Took(40) == "40s" and LevelUp.Took(35 * 60 + 20) == "35m" and LevelUp.Took(7 * 3600 + 12 * 60 + 5) == "7h 12m"
        and LevelUp.Took(3600) == "1h 0m",
        "how long a level took, as short as the toast has it")

    W.Fire("PLAYER_ENTERING_WORLD")
    check(not ChatFrame1:IsEventRegistered("PLAYER_LEVEL_UP") and not ChatFrame1:IsEventRegistered("PLAYER_LEVEL_CHANGED"),
        "the chat windows no longer hear a level: Retail's event too")
    check(ChatFrame1:IsEventRegistered("TIME_PLAYED_MSG"), "they do hear /played")
    ChatFrame1:RegisterEvent("PLAYER_LEVEL_UP") -- the player chose what the window shows: the game adds its events again
    W.Fire("PLAYER_XP_UPDATE", "player")
    check(not ChatFrame1:IsEventRegistered("PLAYER_LEVEL_UP"), "the game added it again: at the next XP it goes")

    W.Wait(LevelUp.ASK_AFTER + LevelUp.ASK_MOST)
    local asked = timeAsked
    check(asked == 1, "the time is asked once after the login")
    check(ChatFrame1:IsEventRegistered("TIME_PLAYED_MSG"), "no answer: the chat hears /played again all the same")
    LevelUp.Ask()
    check(timeAsked == asked + 1 and not ChatFrame1:IsEventRegistered("TIME_PLAYED_MSG"), "asked with the chat deaf to that one answer")
    LevelUp.Ask()
    check(timeAsked == asked + 1, "and not again while it is on its way")
    W.Fire("TIME_PLAYED_MSG", 90000, 7 * 3600 - 100)
    W.Wait(0.1)
    check(ChatFrame1:IsEventRegistered("TIME_PLAYED_MSG") and not (W.chatHeard or {}).TIME_PLAYED_MSG, "the answer went by, the chat hears /played again")
    LevelUp.Ask()
    check(timeAsked == asked + 1, "the game has said: not asked again")

    W.Wait(100)
    W.chatHeard = nil -- what it heard of the levels of the tests above, before it was made deaf
    W.Fire("PLAYER_LEVEL_UP", 22, 18, 20, 1, 0, 2, 0, 1, 0, 0)
    check(Said() == "Level 22!/HP |cff6fe06f+18|r/Mana |cff6fe06f+20|r/Str |cff6fe06f+2|r/Stam |cff6fe06f+1|r/Talent |cff6fe06f+1|r/Leveled 7h 0m",
        "the level, what it brought, how long it took (" .. Said() .. ")")
    check(view._shown and not (W.chatHeard or {}).PLAYER_LEVEL_UP, "in the middle of the screen, nothing in the chat")
    local point, _, relative, x, y = view:GetPoint(1)
    check(point == "TOP" and relative == "TOP" and x == LevelUp.RIGHT and x >= 120 + LevelUp.EDGE + LevelUp.WIDTH / 2
        and y == -Core.TOAST_TOP, "at the toast's height, right of the middle: beside the guide's arrow (240 wide)")
    check(not Core.TopTaken(), "it leaves the middle free: the guide's arrow there stays")
    W.Wait(LevelUp.FADE_IN + LevelUp.HOLD + LevelUp.FADE_OUT + 0.1)
    check(not view._shown, "and it goes by itself")

    W.Fire("PLAYER_LEVEL_UP", 23, 18, 0, 0, 0, 0, 0, 0, 0)
    check(Said() == "Level 23!/HP |cff6fe06f+18|r/Leveled 6s",
        "a line only for what grew, in Retail's shorter event too; the next level's time counts from this one (" .. Said() .. ")")
    W.Fire("PLAYER_LEVEL_UP", 24, 0, 0, 0, 0, 0, 0, 0, 0, 3)
    check(Said() == "Level 24!/Spi |cff6fe06f+3|r/Leveled 0s", "a level on top of the last: the toast anew")
    W.Wait(LevelUp.FADE_IN + LevelUp.HOLD - 1)
    check(view._shown, "with its own time, the last one's end keeps away")
    W.Wait(LevelUp.FADE_OUT + 1.1)
    check(not view._shown, "till its own end")
    -- A value the game keeps secret (the 12.x client): a level it hides is not told, a gain it hides is left out.
    W.Fire("PLAYER_LEVEL_UP", W.Secret(), 18, 0, 0, 0, 0, 0, 0, 0, 0)
    local quiet = not view._shown
    W.Fire("PLAYER_LEVEL_UP", 25, W.Secret(), 20, 0, 0, 0, 0, 0, 0, 0)
    check(quiet and Said() == "Level 25!/Mana |cff6fe06f+20|r/Leveled 0s" and not ns.off,
        "a level the game keeps secret is not told, a gain it keeps secret is left out, the rest said (" .. Said() .. ")")

    local parent = game:GetParent()
    Toast(LEVEL)
    check(game:GetParent() ~= parent and game:GetParent()._alpha == 0, "the game's toast of a level runs on under a frame of ours, unseen")
    Toast(Enum.EventToastEventType.LevelUpSpell)
    check(game:GetParent() == parent, "any other toast of the game's is seen")
    Toast(LEVEL)
    Toast(nil)
    check(game:GetParent() == parent, "no toast left: it stands where it stood")

    Toast(LEVEL)
end

Stand()
-- Each step of giving back by itself: one that fails stops none of the others.
local hide = ns.Board.Hide
ns.Board.Hide = function()
    hide()
    error("a step that fails")
end
ns.StandDown("a test")
ns.Board.Hide = hide
check(ns.off and not frame:IsShown() and not handle.edge.full and bags.shown == false and not panel:IsShown(),
    "standing down: the windows go and the window with them, a step that fails stopping none of the others")
check(next(Overrides()) == nil and ContainerFrameCombinedBags:GetParent() == UIParent and ContainerFrame1:GetParent() == UIParent,
    "and the bag keys and the game's bag windows are the game's again")
check(ChatFrame1:IsEventRegistered("PLAYER_LEVEL_UP") and EventToastManagerFrame:GetParent() == UIParent, "and a new level is the game's to tell again")

-- The weights: every line of both games reads, by the game's stat keys; the stat a character builds on is 1.
do
    local Weights = ns.Weights
    local lines = 0
    for game, classes in pairs({ forever = Weights.FOREVER, retail = Weights.RETAIL }) do
        for class, specs in pairs(classes) do
            check(specs.early, class .. " has a line for a character without a specialization")
            for spec in pairs(specs) do
                check(Weights.For(game, class, spec), game .. " " .. class .. " " .. spec)
                lines = lines + 1
            end
        end
    end
    check(lines >= 70, "a line for every specialization: " .. lines)
    local arms = Weights.For("forever", "WARRIOR", "arms")
    check(arms.ITEM_MOD_STRENGTH_SHORT == 1 and arms.ITEM_MOD_DAMAGE_PER_SECOND_SHORT == 7 and arms.ITEM_MOD_ATTACK_POWER_SHORT == 0.5,
        "a warrior: 2 Attack Power to Strength, 14 to a point of damage per second")
    local feral = Weights.For("retail", "DRUID", "feral")
    check(feral.ITEM_MOD_AGILITY_SHORT == 1 and feral.ITEM_MOD_HASTE_RATING_SHORT == Weights.LADDER[1]
        and feral.ITEM_MOD_MASTERY_RATING_SHORT == Weights.LADDER[4] and feral.ITEM_MOD_DAMAGE_PER_SECOND_SHORT, "Retail: the main stat, then the ladder")
    check(Weights.For("retail", "PRIEST", "shadow").ITEM_MOD_DAMAGE_PER_SECOND_SHORT == nil, "a caster's weapon damage counts for nothing")
    check(Weights.For("forever", "WARRIOR", "no such") == arms or Weights.For("forever", "WARRIOR", "no such").ITEM_MOD_STRENGTH_SHORT == 1,
        "a specialization without a line: its class's first")
    check(Weights.For("forever", "NOBODY", "arms") == nil, "a class without lines: none")
    check(Weights.For("forever", "DRUID", "feral combat") == Weights.For("forever", "DRUID", "feral")
        and Weights.For("forever", "DRUID", "feral").ITEM_MOD_AGILITY_SHORT == 1,
        "a druid of the tree WoW: Forever names Feral Combat: the feral line, not its class's first")
    local feral = Weights.For("forever", "DRUID", "feral")
    check(feral.ITEM_MOD_DAMAGE_PER_SECOND_SHORT == 7 * feral.ITEM_MOD_STRENGTH_SHORT,
        "a feral druid of WoW: Forever: forms swing the weapon, so its damage per second by the warrior's rule")
    -- As Speed Leveling's rewards judge, through Core.Upgrade: the mace worn of 10.1 damage per second and 3 Strength
    -- more, one offered of 13.6; a feral druid takes the one that hits harder.
    local maces = {
        ["item:5001"] = { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 10.1, ITEM_MOD_STRENGTH_SHORT = 4, ITEM_MOD_STAMINA_SHORT = 2 },
        ["item:5002"] = { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 13.6, ITEM_MOD_STRENGTH_SHORT = 1, ITEM_MOD_STAMINA_SHORT = 1 },
    }
    local stats, mainHand, info = rawget(_G, "GetItemStats"), rawget(_G, "INVSLOT_MAINHAND"), C_Item.GetItemInfo
    INVSLOT_MAINHAND, worn[16] = 16, { link = "item:5001" }
    GetItemStats = function(link) return maces[link] end
    C_Item.GetItemInfo = function(link)
        if maces[link] then return "Mace", link, 2, 22, 1, "Weapon", "One-Handed Maces", 1, "INVTYPE_WEAPON", 1, 1, 2, 4 end
    end
    Core.WeighWith(function() return feral end)
    local kind, gain = Core.Upgrade("item:5002")
    check(kind == "better" and gain > 20, "a feral druid of WoW: Forever: the mace that hits harder, though of less Strength")
    Core.WeighWith(function() return Weights.For("forever", "DRUID", "balance") end)
    check(Core.Upgrade("item:5002") == nil, "a balance druid, who weighs no weapon damage: the worn one stays")
    Core.WeighWith(Weights.Now)
    GetItemStats, INVSLOT_MAINHAND, worn[16], C_Item.GetItemInfo = stats, mainHand, nil, info
end

-- A shield build: a warrior whose talents work only with a shield. Protection the game's primary talent tree, or a
-- talent with a rank whose spell's tooltip asks for a shield in the game's words; a druid never.
do
    local Weights, class, specs = ns.Weights, UnitClass, rawget(_G, "C_SpecializationInfo")
    local traits, talents, tips = rawget(_G, "C_Traits"), rawget(_G, "C_ClassTalents"), rawget(_G, "C_TooltipInfo")
    local subclass, form = C_Item.GetItemSubClassInfo, rawget(_G, "SPELL_EQUIPPED_ITEM")
    local tree
    UnitClass = function() return "Warrior", "WARRIOR", 1 end
    C_SpecializationInfo = { GetSpecialization = function() return tree and 1 or nil end,
                             GetSpecializationInfo = function() return 0, tree end }
    tree = "Arms"
    W.Fire("PLAYER_TALENT_UPDATE")
    check(Weights.Now() == Weights.For("forever", "WARRIOR", "arms") and not Weights.Now().shield, "an Arms warrior: no shield build")
    tree = "Protection"
    W.Fire("PLAYER_SPECIALIZATION_CHANGED")
    local prot, line = Weights.Now(), Weights.For("forever", "WARRIOR", "protection")
    check(prot.shield and not line.shield and prot.ITEM_MOD_DAMAGE_PER_SECOND_SHORT == line.ITEM_MOD_DAMAGE_PER_SECOND_SHORT
        and prot.ITEM_MOD_BLOCK_VALUE_SHORT == line.ITEM_MOD_BLOCK_VALUE_SHORT, "Protection, the primary talent tree: the protection line, on a shield build")
    W.Fire("PLAYER_TALENT_UPDATE")
    check(Weights.Now() == prot, "asked anew: the same table, made once (the scores kept)")
    -- The talents: one with three ranks, one with none; the game's tooltip of each one's spell.
    local lines = {}
    SPELL_EQUIPPED_ITEM = "Requires %s"
    C_Item.GetItemSubClassInfo = function(itemClass, kind) if itemClass == 4 and kind == 6 then return "Shields", false end end
    C_ClassTalents = { GetActiveConfigID = function() return 7 end }
    C_Traits = {
        GetConfigInfo = function(config) return config == 7 and { treeIDs = { 1117 } } or nil end,
        GetTreeNodes = function(id) return id == 1117 and { 1, 2 } or {} end,
        GetNodeInfo = function(_, node)
            return { activeRank = node == 1 and 3 or 0, activeEntry = { entryID = node * 10, rank = node == 1 and 3 or 0 } }
        end,
        GetEntryInfo = function(_, entry) return { definitionID = entry + 1 } end,
        GetDefinitionInfo = function(definition) return { spellID = definition * 100 } end,
    }
    C_TooltipInfo = { GetSpellByID = function(spell) return { lines = lines[spell] or {} } end }
    tree = "Arms"
    lines[1100] = { { leftText = "Two-Handed Weapon Specialization" }, { leftText = "Requires Two-Handed Swords" } }
    lines[2100] = { { leftText = "Defiance" }, { leftText = "Requires Shield" } }
    W.Fire("TRAIT_CONFIG_UPDATED")
    check(not Weights.Now().shield, "an Arms warrior: a talent asking for a two-hander, one asking for a shield without a rank: none")
    lines[1100] = { { leftText = "Defiance" }, { leftText = "Requires Shield" } }
    W.Fire("TRAIT_CONFIG_UPDATED")
    check(Weights.Now().shield and Weights.Now().ITEM_MOD_DAMAGE_PER_SECOND_SHORT == 7,
        "a talent with a rank whose tooltip asks for a shield (the game writes Shield or Shields): a shield build, on the Arms line")
    lines[1100] = { { leftText = "Shield Slam" }, { leftText = "Requires Shields" } }
    W.Fire("TRAIT_CONFIG_UPDATED")
    check(Weights.Now().shield, "Requires Shields, the game's name for the kind")
    UnitClass, tree = function() return "Druid", "DRUID", 11 end, "Feral Combat"
    W.Fire("TRAIT_CONFIG_UPDATED")
    check(Weights.Now() == Weights.For("forever", "DRUID", "feral"), "a druid: never a shield build, whatever its talents' words")
    W.Play("retail")
    UnitClass, tree = function() return "Warrior", "WARRIOR", 1 end, "Protection"
    lines[1100] = nil
    W.Fire("PLAYER_TALENT_UPDATE")
    check(Weights.Now().shield and Weights.Now().ITEM_MOD_STRENGTH_SHORT == 1, "Retail: a Protection warrior on a shield build too, on Retail's line")
    W.Play("forever")
    tree = "Protection"
    W.Fire("PLAYER_TALENT_UPDATE")
    check(Weights.Now() == prot, "back in WoW: Forever: the shield build's weights as before")

    -- Through Core.Upgrade, as Speed Leveling's rewards and rolls and the bags' arrows judge. Worn: a mace and a shield.
    local gear = {
        ["item:6001"] = { "INVTYPE_WEAPON", 2, 4, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 10, ITEM_MOD_STRENGTH_SHORT = 3 } },
        ["item:6002"] = { "INVTYPE_SHIELD", 4, 6, { RESISTANCE0_NAME = 500, ITEM_MOD_STAMINA_SHORT = 2 } },
        ["item:6003"] = { "INVTYPE_2HWEAPON", 2, 5, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 20, ITEM_MOD_STRENGTH_SHORT = 8 } },
        ["item:6004"] = { "INVTYPE_WEAPON", 2, 4, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 12, ITEM_MOD_STRENGTH_SHORT = 3 } },
        ["item:6005"] = { "INVTYPE_SHIELD", 4, 6, { RESISTANCE0_NAME = 700, ITEM_MOD_BLOCK_VALUE_SHORT = 12, ITEM_MOD_STAMINA_SHORT = 3 } },
        ["item:6006"] = { "INVTYPE_WEAPONOFFHAND", 2, 15, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 8 } },
        ["item:6007"] = { "INVTYPE_2HWEAPON", 2, 5, { ITEM_MOD_DAMAGE_PER_SECOND_SHORT = 18, ITEM_MOD_STRENGTH_SHORT = 6 } },
    }
    local stats, mainHand, offHand, info = rawget(_G, "GetItemStats"), rawget(_G, "INVSLOT_MAINHAND"), rawget(_G, "INVSLOT_OFFHAND"), C_Item.GetItemInfo
    INVSLOT_MAINHAND, INVSLOT_OFFHAND = 16, 17
    GetItemStats = function(link) return gear[link] and gear[link][4] end
    C_Item.GetItemInfo = function(link)
        local item = gear[link]
        if item then return "Gear", link, 2, 30, 1, "", "", 1, item[1], 1, 1, item[2], item[3] end
    end
    -- The reward Speed Leveling takes: the biggest gain (Rewards.Best).
    local function Pick()
        local best, most
        for _, link in ipairs({ "item:6003", "item:6004", "item:6005" }) do
            local _, gain = Core.Upgrade(link)
            if gain and gain > (most or 0) then best, most = link, gain end
        end
        return best
    end
    local function Near(a, b) return type(a) == "number" and math.abs(a - b) < 1e-6 end
    worn[16], worn[17] = { link = "item:6001" }, { link = "item:6002" }
    check(Core.Upgrade("item:6003") == nil, "Protection: a two-hander of twice the damage is no upgrade over the mace and the shield")
    local kind, gain, place = Core.Upgrade("item:6004")
    check(kind == "better" and Near(gain, 5 * 2) and place == 16, "a mace that hits harder: against the main hand alone")
    kind, gain, place = Core.Upgrade("item:6005")
    check(kind == "better" and Near(gain, 0.02 * 200 + 0.3 * 12 + 1) and place == 17, "a better shield: in the off hand, by armour, block value and stats")
    check(Core.Upgrade("item:6006") == nil, "an off-hand weapon: the off hand is the shield's")
    check(Pick() == "item:6004", "of a two-hander, a mace and a shield offered: the mace")
    -- From before the talents: a two-hander worn. It counts as nothing: a mace and a shield take both hands.
    worn[16], worn[17] = { link = "item:6007" }, nil
    kind, gain, place = Core.Upgrade("item:6004")
    check(kind == "empty" and Near(gain, 5 * 12 + 0.8 * 3) and place == 16, "a two-hander worn: the mace goes into the main hand")
    kind, gain, place = Core.Upgrade("item:6005")
    check(kind == "empty" and place == 17, "and the shield into the off hand")
    check(Core.Upgrade("item:6003") == nil, "a two-hander for a two-hander: none")
    -- An Arms warrior keeps today's way: a two-hander against both hands, by its damage.
    tree = "Arms"
    lines[1100] = nil
    W.Fire("PLAYER_TALENT_UPDATE")
    check(not Weights.Now().shield, "Arms again: no shield build")
    kind, gain = Core.Upgrade("item:6003")
    check(kind == "better" and Near(gain, 7 * 2 + 2), "Arms, a two-hander worn: the harder hitting two-hander")
    check(Core.Upgrade("item:6004") == nil and Core.Upgrade("item:6005") == nil,
        "Arms, a two-hander worn: a mace is worth less, a shield cannot go with it")
    worn[16], worn[17] = { link = "item:6001" }, { link = "item:6002" }
    kind, gain = Core.Upgrade("item:6003")
    check(kind == "better" and Near(gain, 7 * 20 + 8 - (7 * 10 + 3) - (0.01 * 500 + 0.6 * 2)),
        "Arms, a mace and a shield worn: the two-hander against both hands")
    check(Core.Upgrade("item:6006") ~= nil, "Arms: an off-hand weapon in place of a weaker shield, as before")
    check(Pick() == "item:6003", "of a two-hander, a mace and a shield offered: the two-hander")

    worn[16], worn[17] = nil, nil
    GetItemStats, INVSLOT_MAINHAND, INVSLOT_OFFHAND, C_Item.GetItemInfo = stats, mainHand, offHand, info
    UnitClass, C_SpecializationInfo, C_Traits, C_ClassTalents, C_TooltipInfo = class, specs, traits, talents, tips
    C_Item.GetItemSubClassInfo, SPELL_EQUIPPED_ITEM = subclass, form
    W.Fire("PLAYER_TALENT_UPDATE")
end

io.write(("Inventory: all %d checks passed.\n"):format(passed))
