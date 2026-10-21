-- Runs the Nameplates module against the stand-in client (wowstub.lua): our dress on the game's plates as the
-- game shows and takes them back, the game's parts out of sight under it and back, a plate shown by name only,
-- the bar's health (hidden values passed on untouched), colours and border, the name, the rare's mark and the
-- raid marker, the aura containers and their room, the combo points on your target's bar, the settings, and
-- standing down. The look can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/nameplates.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:SetMinMaxValues(low, high) self._min, self._max = low, high end
function methods:SetValue(value) self._value = value end
function methods:SetStatusBarColor(r, g, b) self._barColor = { r, g, b } end
function methods:SetStatusBarTexture(file) self._barTexture = file end
function methods:GetStatusBarTexture()
    self._fill = self._fill or W.NewWidget("Texture", nil, self)
    return self._fill
end
function methods:AddMaskTexture(mask) self._masks = self._masks or {}; self._masks[#self._masks + 1] = mask end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetSpriteSheetCell(cell, rows, columns) self._cell = { cell, rows, columns } end
function methods:SetTexture(file, wrapH, wrapV) self._texture, self._wrap = file, { wrapH, wrapV } end
function methods:UnregisterAllEvents() self._events, self._units = {}, nil end

-- A hidden value of the game's: a table here, never compared.
issecretvalue = function(value) return type(value) == "table" and value.secret == true end
local function Secret() return { secret = true } end

-- The game's own colours and constants the module takes.
NamePlateConstants = { TARGET_BORDER_COLOR = { r = 1, g = 1, b = 1 }, FOCUS_TARGET_BORDER_COLOR = { r = 1, g = 0.49, b = 0.039 } }
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
PowerBarColor = { COMBO_POINTS = { r = 1, g = 0.96, b = 0.41 } }
AnchorUtil = { FlowDirection = { Left = -1, Right = 1, Up = 1, Down = -1 } }
Enum.PowerType = { Mana = 0, Energy = 3, ComboPoints = 4 }
W.cvars.nameplateShowClassColor, W.cvars.nameplateShowFriendlyClassColor = "1", "1"

-- Units as the game describes them, by token; "target" and "focus" are aliases set by the test.
local units, plates = {}, {}
local function Unit(unit) return units[unit] or {} end
C_NamePlate = {
    GetNamePlateForUnit = function(unit) return plates[unit] end,
    GetNamePlates = function() return {} end,
}
UnitName = function(unit) return Unit(unit).name, Unit(unit).surname end
UnitIsPlayer = function(unit) return Unit(unit).player or false end
UnitIsFriend = function(_, unit) return Unit(unit).friend or false end
UnitCanAttack = function(_, unit) return not Unit(unit).friend end
UnitIsTapDenied = function(unit) return Unit(unit).tapped or false end
UnitSelectionColor = function(unit) local c = Unit(unit).colour or { 1, 0, 0 } return c[1], c[2], c[3], 1 end
UnitClassification = function(unit) return Unit(unit).classification or "normal" end
UnitClass = function(unit)
    if unit == "player" then return "Rogue", "ROGUE" end
    return Unit(unit).className, Unit(unit).class
end
UnitHealth = function(unit) return Unit(unit).health end
UnitHealthMax = function(unit) return Unit(unit).most end
GetRaidTargetIndex = function(unit) return Unit(unit).raid end
local power, combo = 3, 2
UnitPowerType = function() return power end
UnitPowerMax = function(_, kind) return kind == Enum.PowerType.ComboPoints and 5 or 100 end
GetComboPoints = function() return combo end

-- The game's container of auras for addons: it calls back for each frame it makes, records what it is told.
W.templates.CustomAuraContainerTemplate = function(widget)
    widget._groups = {}
    function widget:AddAuraGroup(key, filter, options)
        local group = { filter = filter, most = options.maxFrameCount, frames = {} }
        self._groups[key] = group
        for index = 1, 2 do -- a batch made up front
            local frame = W.NewWidget("AuraButton", nil, self)
            function frame:SetIcon(texture) self._icon = texture end
            function frame:SetDurationCooldown(cooldown) self._cooldown = cooldown end
            function frame:SetApplicationCount(text) self._count = text end
            options.initializeFrame(frame)
            group.frames[index] = frame
        end
    end
    function widget:SetAuraGroupMaxFrameCount(key, most) self._groups[key].most = most end
    function widget:SetUnit(unit) self._unit = unit end
    function widget:SetFlowLayoutAnchorPoint(point) self._corner = point end
    function widget:SetFlowLayoutGrowthDirection(across, up) self._growth = { across, up } end
end

-- One of the game's plates, with the parts of its unit frame the module reads.
local function GamePlate()
    local plate = W.NewWidget("Frame", nil, UIParent)
    local frame = W.NewWidget("Button", nil, plate)
    frame.HealthBarsContainer = W.NewWidget("Frame", nil, frame)
    frame.HealthBarsContainer.healthBar = W.NewWidget("StatusBar", nil, frame.HealthBarsContainer)
    for _, key in ipairs({ "AurasFrame", "RaidTargetFrame", "ClassificationFrame", "PlayerLevelDiffFrame" }) do
        frame[key] = W.NewWidget("Frame", nil, frame)
    end
    frame.name = W.NewWidget("FontString", nil, frame)
    frame.PlayerLevelDiffFrame:Hide()
    plate.UnitFrame = frame
    return plate
end

local function DressOf(plate)
    for _, widget in ipairs(W.frames) do
        if widget._parent == plate and widget.health then return widget end
    end
    return nil
end

-- Whether every part of the game's plate ours stands in for is at that alpha.
local function Faded(plate, alpha)
    local frame = plate.UnitFrame
    for _, key in ipairs({ "HealthBarsContainer", "name", "AurasFrame", "RaidTargetFrame", "ClassificationFrame" }) do
        if frame[key]._alpha ~= alpha then return false end
    end
    return true
end

W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Nameplates", "SaneUI_Nameplates")
W.Fire("ADDON_LOADED", "SaneUI_Nameplates")
W.Fire("PLAYER_LOGIN")
local Core = SaneUI.Core
local Bar, Auras, Marks, Resource = ns.Bar, ns.Auras, ns.Marks, ns.Resource

check(Bar.FOCUS[2] == 0.49 and Bar.TARGET[1] == 1, "the border's colours for your target and focus are the game's")
check(Core.Shape.CAP_LEFT:match("SaneUI\\Art\\cap%-left$") and Core.Shape.CAP_RIGHT:match("cap%-right$"), "Core names the caps' files")

-------------------------------------------------------------------------------
--  A creature's plate
-------------------------------------------------------------------------------
local wolf = Secret()
units.nameplate1 = { name = "Young Wolf", health = wolf, most = Secret(), colour = { 1, 0, 0 }, classification = "rare" }
plates.nameplate1 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local dress = DressOf(plates.nameplate1)
check(dress and dress:IsShown() and dress.unit == "nameplate1", "the plate the game shows gets our dress")
check(Faded(plates.nameplate1, 0), "the game's bar row, name, auras and marks go out of sight under it")
check(plates.nameplate1.UnitFrame.PlayerLevelDiffFrame._alpha == 1, "its level box stays as the game has it")
check(dress._points[1][2] == plates.nameplate1.UnitFrame.HealthBarsContainer and dress._points[2][2] == plates.nameplate1.UnitFrame.HealthBarsContainer,
    "laid exactly over the game's health bar row")
check(dress.health._value == wolf and dress.health._max == units.nameplate1.most, "hidden health goes to the bar as the game gives it")
check(dress.health._barColor[1] == 1 and dress.health._barColor[2] == 0, "a foe in the game's colour for what it is to you")
check(dress.name._text == "Young Wolf", "its name above the bar")
check(dress.rare:IsShown() and dress.rare._atlas == Marks.ATLAS.rare, "a rare: the game's star")
check(dress.rare._points[1][2] == dress and not dress.raid:IsShown(), "right of the bar; no raid marker")
check(dress.health:GetStatusBarTexture()._masks and #dress.health:GetStatusBarTexture()._masks == 2
    and #dress.background._masks == 2 and #dress.border._masks == 2, "the fill, its background and the border each cut at both ends")
check(dress.caps[1]._texture == Core.Shape.CAP_LEFT and dress.caps[1]._wrap[1] == "CLAMPTOWHITE"
    and dress.caps[2]._texture == Core.Shape.CAP_RIGHT, "by Core's caps, white beyond them")

-- Its size: the caps a quarter of each height, the bar a pixel inside its border.
dress:SetSize(190, 20)
dress:GetScript("OnSizeChanged")(dress)
local edge = Core.Pixels(dress, 1)
check(dress.outerCaps[1]._width == 20 * Bar.CAP and dress.caps[2]._width == (20 - 2 * edge) * Bar.CAP,
    "each cap as wide as a quarter of what it rounds")
check(dress.health._points[1][4] == edge and dress.health._points[2][4] == -edge, "the bar a pixel inside its border")

-- Health and name as they change.
units.nameplate1.health = 40
W.Fire("UNIT_HEALTH", "nameplate1")
check(dress.health._value == 40, "health followed")
units.nameplate1.name = Secret()
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
check(dress.name._text == units.nameplate1.name, "a hidden name goes to the text as it is")
units.nameplate1.tapped = true
W.Fire("UNIT_FLAGS", "nameplate1")
check(dress.health._barColor[1] == Bar.TAPPED[1], "tapped by others: grey, as the game's plates")

-------------------------------------------------------------------------------
--  The auras: the game's containers, set up once
-------------------------------------------------------------------------------
local own, foes = dress.own, dress.foes
check(own and foes and own._groups.own.filter == Auras.OWN and foes._groups.foes.filter == Auras.FOES,
    "your debuffs and a foe's buffs, each in a container of the game's with its filter")
check(own._corner == "BOTTOMLEFT" and own._growth[1] == AnchorUtil.FlowDirection.Right
    and foes._corner == "BOTTOMRIGHT" and foes._growth[1] == AnchorUtil.FlowDirection.Left, "debuffs from the left, buffs from the right")
check(own._points[1][2] == dress.name and own._points[1][3] == "TOPLEFT" and foes._points[1][3] == "TOPRIGHT", "above the name")
check(own._unit == "nameplate1" and foes._unit == "nameplate1" and own:IsShown() and foes:IsShown(), "set to the plate's unit")
local icon = own._groups.own.frames[1]
check(icon._icon and icon._cooldown and icon._count and icon._width == Auras.SIZE, "each frame the container makes gets its icon, time and count once")
check(Auras.Slots(190) == 8 and own._groups.own.most == 5 and foes._groups.foes.most == Auras.BUFFS,
    "eight over a bar 190 wide: three for buffs, five for your debuffs")
Core.Set(ns.name, "buffs", false)
check(not foes:IsShown() and foes._unit == "none" and own._groups.own.most == 8, "buffs off: your debuffs have the whole row")
Core.Set(ns.name, "buffs", true)
Core.Set(ns.name, "debuffs", false)
check(not own:IsShown() and foes:IsShown(), "your debuffs off")
Core.Set(ns.name, "debuffs", true)

-------------------------------------------------------------------------------
--  A friend shown by name only, a player, the raid marker, the border
-------------------------------------------------------------------------------
local bar = plates.nameplate1.UnitFrame.HealthBarsContainer.healthBar
bar:Hide() -- the game shows the plate by name only now
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "the game's health bar gone: its own plate as it is, ours away")
bar:Show()
check(dress:IsShown() and Faded(plates.nameplate1, 0), "back")

units.nameplate2 = { name = "Bran", surname = "Stoneheart", player = true, class = "WARRIOR", friend = true, health = 10, most = 10, raid = 8 }
plates.nameplate2 = GamePlate()
plates.nameplate2.UnitFrame.PlayerLevelDiffFrame:Show()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
local friend = DressOf(plates.nameplate2)
check(friend.health._barColor[1] == 0.78 and friend.name._text == "Bran Stoneheart", "a player: the class colour, first name and surname")
check(not friend.foes:IsShown() and friend.own:IsShown(), "no buffs on someone you cannot attack")
check(friend.raid:IsShown() and friend.raid._cell[1] == 8 and friend.raid._cell[2] == 4 and friend.raid._cell[3] == 4,
    "a raid marker: the game's icon at its index")
check(friend.raid._points[1][2] == plates.nameplate2.UnitFrame.PlayerLevelDiffFrame, "right of the game's level box where there is one")
units.nameplate2.raid = Secret()
W.Fire("RAID_TARGET_UPDATE")
check(friend.raid:IsShown() and friend.raid._cell[1] == units.nameplate2.raid, "an index hidden from addons goes to the icon as it is")
units.nameplate2.raid = nil
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown(), "no marker: none")
units.nameplate2.raid, units.nameplate2.friend = 8, false
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown(), "a player you could fight shows none, as on the game's plates")
units.nameplate2.friend = true

units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
check(friend.border._vertex[1] == 1 and friend.border._vertex[2] == 1 and dress.border._vertex[1] == Bar.BORDER[1],
    "your target's border lit, the others' dark")
units.focus, plates.focus = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_FOCUS_CHANGED")
check(dress.border._vertex[2] == 0.49, "your focus's in the game's colour for it")

-------------------------------------------------------------------------------
--  Combo points in your target's bar
-------------------------------------------------------------------------------
units.target, plates.target = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_TARGET_CHANGED")
W.Wait(0)
local strip = dress.strip
check(strip and strip:IsShown() and strip._value == 2 and strip._min == 0 and strip._max == 5, "on your target's bar: two of five")
check(strip._points[1][2] == dress.health and strip._height == (20 - 2 * edge) * Resource.SHARE, "along the bar's bottom, a third of its height")
check(#strip:GetStatusBarTexture()._masks == 2 and strip:GetStatusBarTexture()._masks[1] == dress.caps[1], "its corners the bar's own")
local lines = 0
for _, line in ipairs(strip.lines) do if line:IsShown() then lines = lines + 1 end end
check(lines == 4, "a line between each two of the five")
combo = Secret()
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
check(strip._value == combo, "a hidden count goes to the strip as it is")
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
W.Wait(0)
check(not strip:IsShown() and not (friend.strip and friend.strip:IsShown()), "a target you cannot attack: none anywhere")
units.target, plates.target = units.nameplate1, plates.nameplate1
power = Enum.PowerType.Mana
W.Fire("UNIT_DISPLAYPOWER", "player")
W.Wait(0)
check(not strip:IsShown(), "not building them (a druid out of cat form): none")
power = Enum.PowerType.Energy
W.Fire("UNIT_DISPLAYPOWER", "player")
W.Wait(0)
check(strip:IsShown(), "in cat form again")
Core.Set(ns.name, "resource", false)
W.Wait(0)
check(not strip:IsShown(), "the setting off: none")
Core.Set(ns.name, "resource", true)
W.Wait(0)

-------------------------------------------------------------------------------
--  Plates going, plates the game keeps, standing down
-------------------------------------------------------------------------------
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
check(not friend:IsShown() and Faded(plates.nameplate2, 1) and friend.unit == nil and next(friend._events) == nil,
    "the plate taken back: ours off, the game's parts in sight again, nothing listened to")
check(friend.own._unit == "none", "its containers let go of the unit")
check(friend.health._max == 1 and friend.health._value == 1, "its bar as made again: nothing of that unit's health is left on it")
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate3") -- a plate the game keeps from addons: none for us
check(units.nameplate3 == nil and plates.nameplate3 == nil, "a plate the game does not give: nothing made")
units.nameplate4 = { name = "Kobold", health = 5, most = 5 }
plates.nameplate4 = plates.nameplate2 -- the game hands the plate out again, for another unit
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate4")
check(DressOf(plates.nameplate2) == friend and friend:IsShown() and friend.name._text == "Kobold", "a plate handed out again keeps its dress")

-- Standing down while a step of ours fails (here the game's aura container, which a client update may change): the
-- game's parts come back first all the same, on every plate, and on every unit frame of the game's ours lay over.
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate4")
plates.nameplate2.UnitFrame.name:SetAlpha(0) -- a unit frame of the game's pool, left out of sight
dress.own.SetUnit = function() error("the game's container changed") end
ns.StandDown("a test")
check(ns.off and not dress:IsShown() and not friend:IsShown() and Faded(plates.nameplate1, 1) and Faded(plates.nameplate2, 1),
    "standing down, every plate is the game's own again, though a step of ours failed")
check(Core.errors["Nameplates: auras"] ~= nil, "the step that failed is noted")
bar:Hide()
bar:Show()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "after that, nothing is dressed")

io.write(("Nameplates: all %d checks passed.\n"):format(passed))
