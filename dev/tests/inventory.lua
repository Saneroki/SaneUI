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

-- The game's side tabs (LargeSideTabButtonTemplate): an icon, checked or not, a handler for the left button let go.
W.templates.LargeSideTabButtonTemplate = function(widget)
    widget.Icon = W.NewWidget("Texture", nil, widget)
    function widget:SetCustomOnMouseUpHandler(fn) self._mouseUp = fn end
end
-- The game's stats list (the right pane): its scrolling list and rows, its table of stats, the resistances.
W.templates.CharacterStatsPaneScrollBoxTemplate = function(widget)
    widget.ScrollBox = W.NewWidget("Frame", nil, widget)
    widget.ScrollBox.sets = 0
    function widget.ScrollBox:SetDataProvider(provider) self.provider, self.sets = provider, self.sets + 1 end
    widget.ScrollBar = W.NewWidget("Frame", nil, widget)
end
W.templates.CharacterStatFrameTemplate = function(widget)
    widget.Label, widget.Value = W.NewWidget("FontString", nil, widget), W.NewWidget("FontString", nil, widget)
end
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
ClearOverrideBindings = function(owner) W.overrides[owner] = nil end
SetOverrideBinding = function(owner, _, key, command)
    W.overrides[owner] = W.overrides[owner] or {}
    W.overrides[owner][key] = command
end
NUM_CONTAINER_FRAMES = 2
ContainerFrameCombinedBags = W.NewWidget("Frame", "ContainerFrameCombinedBags", UIParent)
ContainerFrame1 = W.NewWidget("Frame", "ContainerFrame1", UIParent)
ContainerFrame2 = W.NewWidget("Frame", "ContainerFrame2", UIParent)
for _, bagFrame in ipairs({ ContainerFrameCombinedBags, ContainerFrame1, ContainerFrame2 }) do bagFrame:Hide() end
MainMenuBarBackpackButton = W.NewWidget("Button", "MainMenuBarBackpackButton", UIParent)
OpenAllBags = function() ContainerFrameCombinedBags:Show() end
CloseAllBags = function() ContainerFrameCombinedBags:Hide() end
local cursorItem = false
CursorHasItem = function() return cursorItem end

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
worn[1].locked, worn[1].broken = false, true
W.Fire("UPDATE_INVENTORY_DURABILITY")
check(drawn[head].tint[1] == Slots.RED[1] and drawn[head].tint[2] == 0 and drawn[head].grey == false, "a broken item: red, as the game tints it")
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
check(Slots.main._points[1][4] == -60 and Slots.Button(0):IsShown(), "a character that uses ammo: the ammo slot beside the ranged slot")
ammoUser = false
Slots.Place()

-------------------------------------------------------------------------------
--  The stats
-------------------------------------------------------------------------------
local list
for _, widget in ipairs(W.frames) do
    if rawget(widget, "unit") == "player" and type(rawget(widget, "ScrollBox")) == "table" then list = widget end
end
check(list and list._points[1][1] == "TOPLEFT" and list._points[1][2]._atlas == "UI-Character-Info-Stat-StoneBG3",
    "the game's stats list under the stone of the stats' window")
local function Names()
    local names = {}
    for _, element in ipairs(list.ScrollBox.provider.elements) do
        names[#names + 1] = element.isHeader and ("[" .. element.name .. "]") or (element.name or element.labelText)
    end
    return table.concat(names, " ")
end
check(Names() == "[General] HEALTH MOVESPEED [Modifiers] CRITCHANCE [Resistance] Arcane Fire Frost Nature Shadow",
    "the game's categories for the player, a stat at the value it hides at left out, a category with none shown left out, then the resistances: " .. Names())
local fire = list.ScrollBox.provider.elements[8]
check(fire.atlas == "UI-Character-Info-Resistance-Fire" and fire.valueText == "15" and fire.tooltip == "Fire 15",
    "a resistance: the game's atlas, value and tooltip")
-- The rows are the game's: the list makes each with the game's template for it, and the game's Init fills it.
local made = {}
local function Factory(template, init)
    local row = { inits = 0 }
    function row:Init(element) self.inits, self.element = self.inits + 1, element end
    init(row, list.ScrollBox.provider.elements[#made + 1])
    made[#made + 1] = { template = template, row = row }
end
for _, element in ipairs(list.ScrollBox.provider.elements) do list.ScrollBox.view.factory(Factory, element) end
check(made[1].template == "CharacterStatFrameCategoryScrollBoxElementTemplate" and made[2].template == "CharacterStatFrameScrollBoxLabelElementTemplate"
    and made[7].template == "CharacterStatFrameScrollBoxIconElementTemplate" and made[2].row.inits == 1,
    "each row the game's template for it: a category's head, a stat, a resistance with its icon; filled by the game's Init")

-- A stat changes: drawn anew a frame later, once however many events come.
local sets = list.ScrollBox.sets
statValues.HASTE, shield = 3, true
W.Fire("UNIT_STATS", "player")
W.Fire("COMBAT_RATING_UPDATE")
W.Wait(0)
check(list.ScrollBox.sets == sets + 1 and Names():find("HASTE") and Names():find("%[Defense%] BLOCK"),
    "a stat changed: the list drawn anew, once, a frame later")
-- Under a restriction the stats are secret to addon code: the list waits, and is drawn once it is over.
sets = list.ScrollBox.sets
W.combat = true
statValues.CRITCHANCE = 0
W.Fire("UNIT_STATS", "player")
W.Wait(0)
check(list.ScrollBox.sets == sets and ns.Stats.Owed(), "in a fight the list stays as it was")
local laidOut = made[2].row.inits
list.ScrollBox.view.factory(function(_, init) init(made[2].row, made[2].row.element) end, made[2].row.element)
check(made[2].row.inits == laidOut, "a row the list lays out again in a fight is left as it is: its stat is secret then")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
W.Wait(0)
check(list.ScrollBox.sets == sets + 1 and not ns.Stats.Owed() and not Names():find("CRITCHANCE"), "the fight over: drawn anew")

-------------------------------------------------------------------------------
--  The other characters
-------------------------------------------------------------------------------
local Alts, Snapshot, Items, Roster = ns.Alts, ns.Snapshot, ns.Items, ns.Roster
local alts = Board.Panel("alts")
check(alts and alts:IsShown() and alts.title._text == "Alts" and not Alts.body.wait:IsShown(),
    "the other characters' window is on the full screen at first; Core's data of them is there from the login")
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
local people = Roster.box.rows
local function Names()
    local names = {}
    for index = 1, #Roster.box.provider.elements do names[index] = people[index].name._text end
    return table.concat(names, ", ")
end
check(not Alts.body.wait:IsShown() and Names() == "Tester Stub, Ann Brook, Droopy Fairwind, Account Bank",
    "Core's data there: the roster, you first, the others by name, the account's own bank last: " .. Names())
check(people[3].icon._atlas == "classicon-warrior" and people[3].name._color[1] == 0.78 and people[3].right._text == "1230000c"
    and Roster.foot.gold._text == "1244467c", "each in its class's colour with its icon and its whole gold; under them the gold of them all")
check(people[2].lit:IsShown() and not people[1].lit:IsShown() and Alts.head.name._text == "Ann Brook",
    "shown at first: the first of the others")
local function Elements() return ns.Items.box.provider.elements end
check(Elements()[1].text == "Bags" and Elements()[2].kind == "grid" and Elements()[3].text == "Bank"
    and Elements()[4].text == "Not seen yet: open the bank with this character" and Elements()[5].text == "Equipped"
    and Elements()[6].text == "Empty", "its bags; a bank never opened says so; nothing worn: empty")

-- Another one chosen: its things.
people[3]:GetScript("OnClick")(people[3], "LeftButton")
people = Roster.box.rows
check(people[3].lit:IsShown() and not people[2].lit:IsShown() and Alts.head.name._text == "Droopy Fairwind"
    and Alts.head.gold._text == "1234567c" and Alts.head.line._text == "Level 30 |cffc69b6dWarrior|r  |cff808080Seen 3 |4day:days; ago|r",
    "a click in the roster: that one's head, its gold, its level and class as the sheet writes them, when it was seen")
local things = ns.Items.box.rows
local grid = things[2]
check(Elements()[1].kind == "head" and grid.buttons[1].item == 2589 and grid.buttons[2].item == 4500
    and drawn[grid.buttons[1]].count == 20 and drawn[grid.buttons[1]].texture == 2000 + 2589 and drawn[grid.buttons[1]].quality == 1,
    "its bags a grid of the game's item buttons in the order kept (by item ID): icon, count, quality")
check(Elements()[3].text == "Bank" and Elements()[3].note == "Seen 5 |4day:days; ago" and Elements()[4].items[1].count == 8,
    "its bank as last seen, and when")
check(Elements()[5].text == "Equipped" and Elements()[6].kind == "gear" and things[6].line.text._text == "item:1001"
    and things[7].line.text._text == "Linen Cloth" and requested[1001] == 1,
    "what it wears a list (Core has not read it slot by slot: it has not logged in since); a name the game does not know yet is asked for")
things[7].line:GetScript("OnEnter")(things[7].line)
check(GameTooltip._itemID == 2589, "its tooltip is the game's for the item")
W.items[1001] = { name = "Helm", quality = 3 }
W.Fire("GET_ITEM_INFO_RECEIVED", 1001, true)
W.Wait(0)
check(ns.Items.box.rows == things, "a name that comes waits a moment for the others that come with it")
W.Wait(Alts.NAMES)
things = ns.Items.box.rows
check(things[6].line.text._text == "Helm" and things[6].line.text._color[3] == 0.87 and requested[1001] == 1,
    "the name comes: drawn anew, in its quality's colour; asked once only")
check(Snapshot.Learned(1001) == false, "a name the window does not wait for draws nothing anew")
grid = things[2]
local was = linked
grid.buttons[1]:GetScript("OnClick")(grid.buttons[1], "LeftButton")
check(linked == was and W.cursor == nil and #picked == 2, "a click moves nothing: an alt's things are only looked at")
W.modifier = nil
grid.buttons[1]:GetScript("OnClick")(grid.buttons[1], "LeftButton")
W.modifier = false
check(linked == "|Hitem:2589|h[Linen Cloth]|h", "a modified click links it")

-- The grid as wide as there is room for.
check(Items.Fit(6 * (Items.SIZE + Items.GAP) - Items.GAP) and not Items.Fit(6 * (Items.SIZE + Items.GAP)),
    "six items fit in six buttons and their gaps")
local eight = {}
for index = 1, 8 do eight[index] = { item = index, count = 1 } end
local laid = Items.Elements({ { place = "bags", items = eight } }, function() return "Bags" end, false)
check(#laid == 3 and laid[2].to == 6 and laid[3].from == 7 and laid[3].to == 8, "eight items, six to a row: two rows")
Alts.Size(0)
Alts.Size(Board.layouts.rects.alts[3]) -- as wide as its panel again

-- The search: across every character.
local row = things[2] -- Droopy's grid of two, drawn again with Ann's: the game's list reuses its rows
people[2]:GetScript("OnClick")(people[2], "LeftButton")
ns.Items.box.view.factory(function(_, init) init(row, Elements()[2]) end, Elements()[2])
check(row.buttons[1].item == 4501 and not row.buttons[2]:IsShown() and row.buttons[2].item == nil,
    "a row the list reuses draws all of itself anew: a button it does not need now hidden")
ns.Items.box.view.factory(function(_, init) init(row, Elements()[1]) end, Elements()[1])
check(row.head:IsShown() and row.head.word._text == "Bags" and not row.buttons[1]:IsShown(), "a grid's row reused for a head")
Board.Search("linen")
people = Roster.box.rows
check(people[3].right._text == 21 and people[2]:GetAlpha() == Roster.DIM and people[2].right._text == "" and people[1]:GetAlpha() == Roster.DIM,
    "the roster says how many each has of what is found; one without any of it dimmed")
check(Alts.head.name._text == "Droopy Fairwind" and people[3].lit:IsShown() and #Elements() == 4
    and Elements()[1].text == "Bags" and Elements()[2].items[1].item == 2589 and #Elements()[2].items == 1 and Elements()[3].text == "Equipped",
    "the chosen one has none: the first that has is shown, only what is found, a place without it left out")
Board.Search("4502")
check(Alts.head.name._text == "Account Bank" and Elements()[2].items[1].item == 4502, "an item's ID finds it too: in the account's bank")
Board.Search("zzz")
check(Alts.head.name._text == "Ann Brook" and #Elements() == 1 and Elements()[1].text == "No items found", "nothing found: says so")
Board.Search("")
people = Roster.box.rows
check(Alts.head.name._text == "Ann Brook" and Elements()[1].text == "Bags" and people[2]:GetAlpha() == 1,
    "the search cleared: the chosen one again, everything")
check(requested[4500] == 1 and Snapshot.Name(4500) == nil, "a name the game never tells is asked for once")

-- Storage: the places and the bags' categories, a click shows one alone.
people[3]:GetScript("OnClick")(people[3], "LeftButton")
local function StorageRow(word)
    for _, storageRow in ipairs(Alts.rail:Rows()) do
        if storageRow.word == word and storageRow:IsShown() then return storageRow end
    end
end
check(StorageRow("All Places").bar:IsShown() and StorageRow("Bank") and StorageRow("All Categories").count._text == "3"
    and StorageRow("Miscellaneous") and StorageRow("Miscellaneous").count._text == "3",
    "Storage: the places, every category with how many of the character's items it holds")
local storageRow = StorageRow("Bank")
storageRow:GetScript("OnClick")(storageRow, "LeftButton")
check(Elements()[1].text == "Bank" and #Elements() == 2, "a place alone")
storageRow = StorageRow("All Places")
storageRow:GetScript("OnClick")(storageRow, "LeftButton")
storageRow = StorageRow("Miscellaneous")
storageRow:GetScript("OnClick")(storageRow, "LeftButton")
check(Elements()[1].text == "Bags" and Elements()[3].text == "Bank" and #Elements() == 4, "a category alone: its items in each place")
storageRow = StorageRow("All Categories")
storageRow:GetScript("OnClick")(storageRow, "LeftButton")
-- The displays, by category.
local altsMenu = Alts.menu
local function AltsPick(text)
    altsMenu:GenerateMenu()
    for _, line in ipairs(altsMenu._items) do
        if line.text == text then return line.fn(line.data) end
    end
end
AltsPick("List")
check(Elements()[2].kind == "row" and Elements()[3].kind == "row" and Elements()[4].kind == "head", "the list: a line per item")
AltsPick("Compact")
check(Elements()[2].kind == "compact" and #Elements()[2].places > 0, "compact: the categories side by side")
AltsPick("Grid")
AltsPick("Group by Category")
check(Elements()[2].kind == "sub" and Elements()[2].text == "Miscellaneous" and Elements()[3].kind == "grid", "grouped by the bags' categories")
ns.Categories.Assign(2589, "trade") -- the player puts an item into another category in the bags
Alts.Refresh(false)
check(Items.Record(2589).category == "trade" and Elements()[2].text == ns.Categories.Word("trade"),
    "an item put into another category in the bags: shown under that one at once")
ns.Categories.Assign(2589, nil)
Alts.Refresh(false)
AltsPick("Group by Category")
check(Elements()[2].kind == "grid", "not grouped again")

-- Hidden, it listens to nothing; shown, it is as Core's data is now.
Push()
local before = ns.Items.box.provider
worn[3] = { texture = "spaulders", count = 1, quality = 2, id = 1003 }
W.Fire("PLAYER_EQUIPMENT_CHANGED", 3, false)
Steps()
check(ns.Items.box.provider == before and Core.Data.Items(Core.charKey, "worn")[3].item == 1003, "hidden: Core's data changes, nothing is drawn")
Stand()
Push()
Stand()
people = Roster.box.rows
people[1]:GetScript("OnClick")(people[1], "LeftButton")
check(Alts.head.line._text:find("Logged in now", 1, true) and Elements()[2].text == "Empty" and Elements()[6].kind == "doll"
    and Elements()[6].slots[3] == 1003, "shown again: drawn as it is now; you too, what you wear as Core last read it")
people[3]:GetScript("OnEnter")(people[3])
check(GameTooltip._lines and GameTooltip._lines[#GameTooltip._lines] == "1234567c", "a character's tooltip: the rest of what is known of it")
-- A character's facts of a wrong kind (a hand edit, an older version) are left out; nothing fails.
do
    local odd, line = { key = "odd", name = "Odd Entry", class = 7, level = {}, realm = true, money = "lots" }, nil
    Roster.box.view.factory(function(kind, init)
        line = W.NewWidget(kind, nil, Roster.box)
        init(line, odd)
    end)
    local about = Alts.About(odd)
    check(line.name._text == "Odd Entry" and #about == 2 and about[2][1] == "Level ? |cffffffff|r" and not Core.errors["Inventory: alts"],
        "a character's class, level and realm of a wrong kind: left out of its line and its tooltip, nothing fails")
end

-- What you wear, read by Core slot by slot (Core.Data.Worn): the game's paper doll, its slots as our sheet has
-- them, as wide as the grid (here six items), the weapons' row in the middle below.
function methods:SetMatchesSearch(on) self._matches = on end
SHIRTSLOT = "Shirt"
W.items[1002] = { name = "Amulet", quality = 4 }
Items.Fit(6 * (Items.SIZE + Items.GAP) - Items.GAP)
people[1]:GetScript("OnClick")(people[1], "LeftButton")
things = ns.Items.box.rows
local function Worn(doll, name)
    for _, button in ipairs(doll.buttons) do
        if button.slotName == name then return button end
    end
end
local doll = things[6].doll
local edge, wide, step = Items.DOLL_EDGE, 6 * (Items.SIZE + Items.GAP) - Items.GAP, Slots.SIZE + Slots.GAP
local helm, amulet, shirt, hands = Worn(doll, "HeadSlot"), Worn(doll, "NeckSlot"), Worn(doll, "ShirtSlot"), Worn(doll, "HandsSlot")
check(#doll.buttons == 20 and doll:IsShown() and helm.item == 1001 and drawn[helm].texture == 3001 and drawn[helm].quality == 3
    and amulet.item == 1002 and drawn[amulet].texture == 3002 and shirt.item == nil and drawn[shirt].texture == "empty-ShirtSlot",
    "your gear in its slots, drawn as the game draws an item; an empty slot its own picture")
check(helm._points[1][4] == edge and helm._points[1][5] == -edge and shirt._points[1][5] == -edge - 5 * step
    and hands._points[1][4] == wide - edge - Slots.SIZE and hands._points[1][5] == -edge,
    "eight down the left, eight down the right, as far apart as the grid is wide")
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
local element = { kind = "doll", slots = { [0] = 2512, [1] = 1001 } }
local function Redraw() ns.Items.box.view.factory(function(_, init) init(things[6], element) end, element) end
Redraw()
local row = weapons + Slots.AMMO_GAP + Slots.AMMO
check(ammo:IsShown() and ammo.item == 2512 and ammo._width == Slots.AMMO and main._points[1][4] == (wide - row) / 2
    and ammo._points[1][4] == (wide - row) / 2 + weapons + Slots.AMMO_GAP and amulet.item == nil and drawn[amulet].texture == "empty-NeckSlot",
    "ammo worn: its slot beside the ranged one, smaller, the row still in the middle; a doll drawn anew is drawn whole")
rangedShown = false
Redraw()
check(not ranged:IsShown() and not ammo:IsShown(), "a client that shows no ranged slot: none, and no ammo beside it")
element.slots[18] = 2504
Redraw()
check(ranged:IsShown() and ranged.item == 2504 and ammo:IsShown(), "unless something is in it")
rangedShown = true
ns.Items.box.view.factory(function(_, init) init(things[6], Elements()[5]) end, Elements()[5])
check(not doll:IsShown() and things[6].head.word._text == "Equipped", "a doll's row reused for a head")
-- The bags worn in their slots: a row of the grid under the doll. While searching, the doll only if something in
-- it is found.
local function Equipped() return "Equipped" end
local bagWorn = { item = 4500, count = 1 }
laid = Items.Elements({ { place = "worn", items = { { item = 1001, count = 1 }, bagWorn }, slots = { [1] = 1001, [20] = 4500 } } }, Equipped, false)
check(#laid == 3 and laid[2].kind == "doll" and laid[2].found == nil and laid[3].kind == "grid" and laid[3].items[1].item == 4500,
    "the bags worn: a row of the grid under the doll")
laid = Items.Elements({ { place = "worn", items = { bagWorn }, slots = { [1] = 1001, [20] = 4500 } } }, Equipped, true)
check(#laid == 2 and laid[2].kind == "grid", "a bag found: its row, no doll")
Board.Search("helm")
things = ns.Items.box.rows
doll = things[2].doll
check(Alts.head.name._text == "Tester Stub" and Elements()[1].text == "Equipped" and Elements()[2].found[1001]
    and Worn(doll, "HeadSlot")._matches == true and Worn(doll, "NeckSlot")._matches == false and Worn(doll, "ShirtSlot")._matches == true,
    "searching: the doll whole, what is found lit, the rest dimmed as the game's bags dim it; an empty slot not")
Board.Search("")
Alts.Size(0)
Alts.Size(Board.layouts.rects.alts[3]) -- as wide as its panel again

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
check(rects.character and rects.bags and rects.character[1] < rects.bags[1]
    and rects.character[3] == ns.Page.Least(math.floor(ns.Sheet.WIDTH * ns.Sheet.LEAST), 0)[1],
    "side by side, in the board's order, the paper doll's window as wide as it asks")

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
sets = list.ScrollBox.sets
W.Fire("UNIT_STATS", "player")
W.Wait(0)
check(list.ScrollBox.sets == sets, "hidden, the stats do not listen either")

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
MainMenuBarBackpackButton:GetScript("PreClick")(MainMenuBarBackpackButton, "LeftButton")
MainMenuBarBackpackButton:GetScript("OnClick")(MainMenuBarBackpackButton, "LeftButton")
Stand()
check(handle.edge.full, "a click on the game's backpack button: ours too")
Keys.Press()
Stand()
cursorItem = true
MainMenuBarBackpackButton:GetScript("PreClick")(MainMenuBarBackpackButton, "LeftButton")
cursorItem = false
MainMenuBarBackpackButton:GetScript("OnClick")(MainMenuBarBackpackButton, "LeftButton")
check(not handle.edge.full, "a click that put an item into the backpack opens nothing")
-- The game's bags chosen in Classic windows: they show, until they are all closed.
Keys.GameBags(true)
OpenAllBags()
check(ContainerFrameCombinedBags:GetParent() == UIParent and ContainerFrameCombinedBags:IsVisible(), "the game's bags chosen: they show")
CloseAllBags()
check(ContainerFrameCombinedBags:GetParent() ~= UIParent, "all closed: hidden again, ours are the bags")
Core.Set(ns.name, "bagKeys", false)
check(next(Overrides()) == nil and ContainerFrameCombinedBags:GetParent() == UIParent, "the setting off: the game's keys and bags are the game's")
Core.Set(ns.name, "bagKeys", true)
check(Overrides().B == Keys.COMMAND and ContainerFrameCombinedBags:GetParent() ~= UIParent, "on again")
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
MainMenuBarBackpackButton:GetScript("PreClick")(MainMenuBarBackpackButton, "LeftButton")
MainMenuBarBackpackButton:GetScript("OnClick")(MainMenuBarBackpackButton, "LeftButton")
Keys.Press()
Stand()
check(not handle.edge.full, "nor does ours come by the game's bag button or our own key")
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
CloseAllBags()
EventRegistry:TriggerEvent("EditMode.Exit")
check(Overrides().B == Keys.COMMAND and ContainerFrameCombinedBags:GetParent() ~= UIParent, "Edit Mode closed: ours again")

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
Push()
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

io.write(("Inventory: all %d checks passed.\n"):format(passed))
