-- Runs the Nameplates module against the stand-in client (wowstub.lua): our dress on the game's plates as the
-- game shows and takes them back, the game's parts out of sight under it and back, a plate shown by name only,
-- the bar's health (hidden values passed on untouched), colours, the border lit on your target and focus, the rank's
-- line and the glow behind it, the power line, the line inside the bar and the bar's width from it, the raid marker,
-- the aura containers around the bar, the combo points on your target's bar, strangers' plates out of sight, the
-- scaling by distance, the settings, and standing down. The look can only be judged in the game.
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
-- A file of ours is found unless the test names it gone (W.gone).
function methods:SetTexture(file, wrapH, wrapV)
    self._texture, self._wrap = file, { wrapH, wrapV }
    return not (W.gone and W.gone[file])
end
function methods:UnregisterAllEvents() self._events, self._units = {}, nil end
function methods:SetFormattedText(form, ...)
    for index = 1, select("#", ...) do
        if type((select(index, ...))) == "table" then self._text = { form = form, ... } return end
    end
    self._text = form:format(...)
end
function methods:SetAlphaFromBoolean(value, yes, no) self._alpha = { from = value, yes = yes, no = no } end
function methods:SetFrameLevel(level) self._level = level end
function methods:SetBlendMode(mode) self._blend = mode end
-- Text measured as the game would, six wide a letter, ten high; a hidden value has no width the test can know.
function methods:GetStringWidth() return type(self._text) == "string" and #self._text * 6 or 0 end
methods.GetUnboundedStringWidth = methods.GetStringWidth
function methods:SetReverseFill(on) self._reverse = on end
function methods:SetFont(file, height, flags) self._font = { file, height, flags } return true end
-- The game's font for its plates' names: its face, height and outline.
SystemFont_NamePlate_Outlined = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "OUTLINE" end }
function methods:GetStringHeight() return 10 end
-- The game's animations, as far as the numbers use them: a group that plays until the test finishes it.
local Animation = {}
Animation.__index = Animation
for _, name in ipairs({ "SetDuration", "SetSmoothing", "SetFromAlpha", "SetToAlpha", "SetStartDelay", "SetOrigin" }) do
    Animation[name] = function() end
end
function Animation:SetOffset(x, y) self._offset = { x, y } end
function Animation:SetScale(x, y) self._scale = { x, y } end
local Group = {}
Group.__index = Group
function Group:CreateAnimation(kind) return setmetatable({ _kind = kind }, Animation) end
function Group:SetScript(name, fn) self["_" .. name] = fn end
function Group:GetParent() return self._parent end
function Group:Restart() self._playing = true end
function Group:Stop() self._playing = false end
function Group:Finish() self._playing = false; self._OnFinished(self) end
function methods:CreateAnimationGroup() return setmetatable({ _parent = self }, Group) end
CombatFeedbackText = { MISS = "Miss", DODGE = "Dodge", BLOCK = "Block" }

-- A hidden value of the game's: a table here, never compared (the game's own functions may look into it: the test says
-- what they see); the stand-in's own (W.Secret, which errors when compared or counted with) known as one too.
local stubSecret = issecretvalue
issecretvalue = function(value) return stubSecret(value) or (type(value) == "table" and value.secret == true) end
local function Secret() return { secret = true } end

-- The game's own colours and constants the module takes.
NamePlateConstants = { TARGET_BORDER_COLOR = { r = 1, g = 1, b = 1 }, FOCUS_TARGET_BORDER_COLOR = { r = 1, g = 0.49, b = 0.039 } }
NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
RAID_CLASS_COLORS = { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 } }
PowerBarColor = { COMBO_POINTS = { r = 1, g = 0.96, b = 0.41 }, MANA = { r = 0, g = 0, b = 1 }, RAGE = { r = 1, g = 0, b = 0 } }
UNIT_LEVEL_NON_ATTACKABLE = { r = 0.3, g = 0.3, b = 0.3 }
GetRelativeDifficultyColor = function(mine, theirs)
    return theirs - mine >= 5 and { r = 1, g = 0.1, b = 0.1 } or { r = 1, g = 1, b = 0 }
end
CurveConstants = { ScaleTo100 = {} }
AbbreviateNumbers = function(value) return { abbreviated = value } end
UnitHealthPercent = function(unit) return { percent = unit } end
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
UnitCreatureType = function(unit) local kind = Unit(unit).creature if kind then return "a type", kind end end
UnitIsFriend = function(_, unit) return Unit(unit).friend or false end
UnitCanAttack = function(a, b)
    if a == "player" then return not Unit(b).friend end
    return (not Unit(a).friend or Unit(a).hunts == true) and Unit(a).player == true -- a player who may attack you
end
UnitReaction = function(unit) return Unit(unit).reaction or 2 end
UnitIsBossMob = function(unit) return Unit(unit).boss or false end
UnitLevel = function(unit) if unit == "player" then return 20 end return Unit(unit).level end
UnitIsUnit = function(a, b) return b == "target" and plates[a] ~= nil and plates[a] == plates.target end
UnitInParty = function(unit) return Unit(unit).party or false end
local raidOf, groupOf = {}, {} -- [unit] = its index in your raid; [index] = that member's subgroup
UnitInRaid = function(unit) return raidOf[unit] end
GetRaidRosterInfo = function(index) return "Member", 0, groupOf[index] end
UnitIsInMyGuild = function(unit) return Unit(unit).guild or false end
UnitGUID = function(unit) return "Player-" .. unit end
local friendOf
C_FriendList = { IsFriend = function(guid) return guid == "Player-" .. (friendOf or "") end }
C_BattleNet = { GetAccountInfoByGUID = function() return nil end }
-- Quests: what the game says of a creature in its tooltip data.
Enum.TooltipDataLineType = { QuestTitle = 17, QuestObjective = 8 }
C_QuestLog = { UnitIsRelatedToActiveQuest = function(unit) return Unit(unit).quest ~= nil end }
C_TooltipInfo = { GetUnit = function(unit) return { lines = Unit(unit).quest or {} } end }
-- Your spellbook and the game's range checks: a strike, a shot that reaches with a bow, a heal, a passive one.
Enum.SpellBookSpellBank = { Player = 0 }
Enum.SpellBookItemType = { Spell = 1 }
local book = { { spellID = 100, itemType = 1 }, { spellID = 101, itemType = 1 }, { spellID = 102, itemType = 1 },
               { spellID = 103, itemType = 1, isPassive = true } }
local harmful = { [100] = true, [101] = true, [103] = true }
local reach, watching = {}, {} -- [spell] = in range of your target (true, false, nil); [spell] = the game tells us
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #book } end,
    GetSpellBookItemInfo = function(index) return book[index] end,
}
-- How far each unit stands from your character, in yards (the test's world); the game answers range questions from it.
local yards = {}
local ranges = { [100] = { 0, 5 }, [101] = { 8, 30 }, [102] = { 0, 40 }, [103] = { 0, 5 } }
local helpful = { [102] = true }
C_Spell = {
    IsSpellHarmful = function(id) return harmful[id] == true end,
    IsSpellHelpful = function(id) return helpful[id] == true end,
    SpellHasRange = function() return true end,
    GetSpellInfo = function(id) return { minRange = ranges[id][1], maxRange = ranges[id][2] } end,
    IsSpellInRange = function(id, unit)
        if reach[id] ~= nil then return reach[id] end -- the test says
        local at = yards[unit]
        if not at then return nil end
        return at >= ranges[id][1] and at <= ranges[id][2]
    end,
}
local itemRange = {}
C_Item = {
    RequestLoadItemDataByID = function() end,
    IsItemInRange = function(item, unit)
        local at = yards[unit]
        if not at or not itemRange[item] then return nil end
        return at <= itemRange[item]
    end,
}
UnitExists = function(unit) return unit == "target" and plates.target ~= nil end
-- Casts: what each unit casts, as the game says it (times in milliseconds, as it gives them).
local casts = {}
UnitCastingInfo = function(unit)
    local cast = casts[unit]
    if not cast or cast.channel then return nil end
    return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, "cast", cast.locked, 133
end
UnitChannelInfo = function(unit)
    local cast = casts[unit]
    if not cast or not cast.channel then return nil end
    return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, cast.locked, 134
end
UnitShouldDisplaySpellTargetName = function(unit) return casts[unit] ~= nil and casts[unit].target ~= nil end
UnitSpellTargetName = function(unit) return casts[unit] and casts[unit].target end
-- Inspecting players: the questions asked, the item levels the server answers.
local inspected = {}
NotifyInspect = function(unit) inspected[#inspected + 1] = unit end
CanInspect = function(unit) return Unit(unit).player == true end
CheckInteractDistance = function() return true end
C_PaperDollInfo = { GetInspectItemLevel = function(unit) return Unit(unit).gear end }
ClearInspectPlayer = function() end
UnitDetailedThreatSituation = function(_, unit)
    local threat = Unit(unit).threat
    if not threat then return nil end
    return threat[1], threat[2], threat[3]
end
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
local power, combo, comboOn = 3, 2, nil -- comboOn: the unit your points are on
UnitPowerType = function(unit)
    if unit == "player" then return power end
    return 0, Unit(unit).powerToken
end
UnitPowerMax = function(unit, kind)
    if unit == "player" then return kind == Enum.PowerType.ComboPoints and 5 or 100 end
    return Unit(unit).powerMost or 0
end
UnitPower = function(unit) return Unit(unit).powerNow end
GetComboPoints = function(_, unit) return comboOn ~= nil and Unit(unit) == comboOn and combo or 0 end

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
    function widget:SetAuraGroupFilterString(key, filter) self._groups[key].filter = filter end
    function widget:UpdateAllAuras() self._updates = (self._updates or 0) + 1 end
    function widget:SetUnit(unit) self._unit = unit end
    function widget:SetFlowLayoutAnchorPoint(point) self._corner = point end
    function widget:SetFlowLayoutGrowthDirection(across, up) self._growth = { across, up } end
end

-- The mouse on a widget, as the game's aura icons have it (their tooltip).
function methods:EnableMouse(on) self._mouse = on end
function methods:IsMouseEnabled() return self._mouse ~= false end

-- The game's aura container of a unit frame: its icons from a pool, set out anew at each refresh (RefreshList, as the
-- game's), one out already as the plate shows; and its loss of control icon, always there. Each takes the mouse.
local function GameAuras(frame)
    local auras = W.NewWidget("Frame", nil, frame)
    local pool = { active = {} }
    function pool:EnumerateActive() return pairs(self.active) end
    function pool:Acquire()
        local icon = W.NewWidget("Frame", nil, auras)
        icon._mouse = true
        self.active[icon] = true
        auras.icons[#auras.icons + 1] = icon
        return icon
    end
    auras.icons, auras.auraItemFramePool = {}, pool
    function auras:RefreshList(count) for _ = 1, count do self.auraItemFramePool:Acquire() end end
    auras.LossOfControlFrame = W.NewWidget("Frame", nil, auras)
    auras.LossOfControlFrame.AuraItemFrame = W.NewWidget("Frame", nil, auras.LossOfControlFrame)
    auras.LossOfControlFrame.AuraItemFrame._mouse = true
    pool:Acquire()
    return auras
end

-- One of the game's plates, with the parts of its unit frame the module reads.
local function GamePlate()
    local plate = W.NewWidget("Frame", nil, UIParent)
    local frame = W.NewWidget("Button", nil, plate)
    frame.HealthBarsContainer = W.NewWidget("Frame", nil, frame)
    frame.HealthBarsContainer:SetSize(120, 20)
    frame.HealthBarsContainer.healthBar = W.NewWidget("StatusBar", nil, frame.HealthBarsContainer)
    for _, key in ipairs({ "RaidTargetFrame", "ClassificationFrame", "PlayerLevelDiffFrame", "LevelFrame", "CastBarsContainer" }) do
        frame[key] = W.NewWidget("Frame", nil, frame)
    end
    frame.AurasFrame = GameAuras(frame)
    frame.name = W.NewWidget("FontString", nil, frame)
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
    for _, key in ipairs({ "HealthBarsContainer", "name", "AurasFrame", "RaidTargetFrame", "ClassificationFrame",
                           "LevelFrame", "PlayerLevelDiffFrame" }) do
        if frame[key]._alpha ~= alpha then return false end
    end
    return true
end

for name, default in pairs({ nameplateMinScale = "1", nameplateMaxScale = "1", nameplateMaxScaleDistance = "10",
                             nameplateMinScaleDistance = "10", nameplateSelectedScale = "1.2", nameplateMaxDistance = "1000",
                             nameplateNotSelectedAlpha = "0.5", nameplateMinAlpha = "0.6",
                             floatingCombatTextCombatDamage_v2 = "1", floatingCombatTextCombatHealing_v2 = "1",
                             enableFloatingCombatText = "1", nameplateShowOnlyNameForFriendlyPlayerUnits = "1" }) do
    W.cvarInfo[name] = { default = default }
end
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Nameplates", "SaneUI_Nameplates")
W.Fire("ADDON_LOADED", "SaneUI_Nameplates")
W.Fire("PLAYER_LOGIN")
local Core = SaneUI.Core
local Bar, Auras, Resource, Text, Scale = ns.Bar, ns.Auras, ns.Resource, ns.Text, ns.Scale

check(Bar.FOCUS[2] == 0.49 and Bar.TARGET[1] == 0.5, "your focus's border the game's colour, your target's a quiet grey")
check(Core.Shape.CAP_LEFT:match("SaneUI\\Art\\cap%-left$") and Core.Shape.CAP_RIGHT:match("cap%-right$"), "Core names the caps' files")

-------------------------------------------------------------------------------
--  A creature's plate
-------------------------------------------------------------------------------
local wolf = Secret()
units.nameplate1 = { name = "Young Wolf", health = wolf, most = Secret(), reaction = 2, classification = "rare", level = 22,
                     powerMost = 100, powerNow = 40, powerToken = "MANA" }
plates.nameplate1 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
local dress = DressOf(plates.nameplate1)
check(dress and dress:IsShown() and dress.unit == "nameplate1", "the plate the game shows gets our dress")
check(Faded(plates.nameplate1, 0), "the game's bar row, name, auras, marks and level boxes go out of sight under it")
local row = plates.nameplate1.UnitFrame.HealthBarsContainer
local high = Text.Height(dress)
check(dress._points[1][1] == "CENTER" and dress._points[1][2] == row and dress._height == high
    and high == math.ceil(14 * Text.SMALLER) + 2 * Text.PAD + 2 * Core.Pixels(dress, 1),
    "centred on the game's health bar row, as high as its line: the font, a little over and under, the border")
check(dress.health._value == wolf and dress.health._max == units.nameplate1.most, "hidden health goes to the bar as the game gives it")
check(dress.health._barColor[1] == 1 and dress.health._barColor[2] == 0, "a creature that attacks on sight: red")
check(dress.name._text == "Young Wolf", "its name inside the bar")
check(dress.marks and dress.marks.lostEnd and dress.marks.container._groups.dispel.filter == Core.HealthMarks.FOE,
    "Core's marks on the bar: on a foe, what can be taken from it")
check(dress.marks.barrier._parent == dress.health and dress.marks:Reach(100) == 0, "no barrier and nothing lost: nothing shows")
GetUnitTotalModifiedMaxHealthPercent = function() return 0.25 end
dress:GetScript("OnEvent")(dress, "UNIT_MAX_HEALTH_MODIFIERS_CHANGED", "nameplate1")
check(dress.marks:Reach(100) == 25 and dress.health._points[2][4] < -20, "maximum health lost: the bar ends that much earlier")
GetUnitTotalModifiedMaxHealthPercent = function() return 0 end
dress:GetScript("OnEvent")(dress, "UNIT_MAX_HEALTH_MODIFIERS_CHANGED", "nameplate1")
check(dress.level._text == "22" and dress.level._color[2] == 1, "its level, in the game's colour for it")
check(dress.name._font[1] == "Fonts\\FRIZQT__.TTF" and dress.name._font[2] == 14 * Text.SMALLER and dress.name._font[3] == "OUTLINE"
    and dress.value._font[2] == 14 * Text.SMALLER and Text.size == math.floor(14 * Text.SMALLER * Text.ICON + 0.5),
    "the game's face and outline, smaller; the icons as high as it and a little more")
check(dress.threat._text == "" and dress.room.threat == nil and dress.room.quest == nil and dress.room.raid == nil
    and dress.room.gear == nil, "no threat, quest, marker or item level: they take no room")
check(type(dress.value._text) == "table" and dress.value._text.form == "%s | %d%%", "hidden health: the game's abbreviation and percent")
-- The line: level, name, health, one after the other; the bar as wide as it and its insets.
local function X(region) return region._points[1][4] end
local I, G = Text.INSET, Text.GAP
-- A text's room: six a letter; the name's with the slack and its spare.
local function L(letters) return letters * 6 end
local function N(letters) return Text.Spare(nil, letters * 6 + Text.SLACK, Text.SPARE) end
local NEAR = Text.NEAR
check(N(10) == 61 + 4 and Text.Spare(65, 61, Text.SPARE) == 65 and Text.Spare(65, 66, Text.SPARE) == 70
    and Text.Spare(70, 61, Text.SPARE) == 65 and Text.Spare(13, 12, 0) == 13 and Text.Spare(14, 12, 0) == 12,
    "the name's room: a little to spare, kept while it fits with at most twice that left over; the others' their width")
check(X(dress.level) == I and X(dress.name) == I + L(2) + NEAR and X(dress.value) == I + L(2) + NEAR + N(10) + G + L(11)
    and dress.value._points[1][1] == "RIGHT", "the level first, the name right after it, then the health at the bar's right end")
check(Text.Guess("nameplate1") == "8.8k" and dress.room.value == L(11),
    "the most hidden: room for a guess from its level and rank (22, a rare: about 4k)")
check(dress.want == I + L(2) + NEAR + N(10) + G + L(11) + I and dress._width == dress.want, "the bar as wide as its line, no wider")
check(dress.value._width == 0 and dress.level._width == 0 and dress.name._width == N(10),
    "the texts as wide as they are (never cut short), but the name: its room")
check(dress.now == 1 and dress.showing == 0 and dress._alpha == 0,
    "a plate that has just appeared: at its size at once (its distance not known: full), unseen at first")
units.guess = { level = -1 }
check(Text.Guess("guess") == "8.88m", "a boss's in millions")
units.guess = { level = 30, player = true }
check(Text.Guess("guess") == "8.8k", "a player's about a hundred a level")
units.guess = { level = 8 }
check(Text.Guess("guess") == "888", "a low creature's under a thousand")
check(dress.rankLine:IsShown() and dress.rankLine[1]._vertex[1] == 0.8 and dress.rank == Bar.RANKS.rare and dress.border[1]._vertex[1] == 0,
    "a rare: a thin silver line behind the black border")
check(not dress.raid:IsShown(), "no raid marker")
check(dress.power:IsShown() and dress.power._value == 40 and dress.power._max == 100 and dress.power._barColor[3] == 1,
    "its mana along the bar's bottom, in the game's colour")
check(dress.glow._alpha == 0, "no glow")
-- What the glow's plates add up to in each band: those reaching it and beyond, laid over each other.
local function Solid(band)
    local clear = 1
    for outer = band, #dress.halo do clear = clear * (1 - dress.halo[outer][1]._vertex[4]) end
    return 1 - clear
end
local fading = #dress.halo == Bar.HALO and math.abs(Solid(1) - 1) < 1e-9 and dress.halo[1][1]._blend ~= "ADD"
for band = 2, #dress.halo do
    fading = fading and Solid(band) < Solid(band - 1) and math.abs(Solid(band) - Bar.Fade(band)) < 1e-9
end
check(fading and Solid(#dress.halo) < 0.05, "the glow: solid at the border, fading to almost nothing outwards")
check(dress.halo[1][1]._parent == dress.glow and dress.border[1]._parent == dress.rankLine[1]._parent
    and dress.glow._level < dress.border[1]._parent._level and dress.border[1]._parent._level < dress.health._level,
    "each layer on a frame of its own: the glow under the outline, the outline under the bar")
check(dress.border[1]._vertex[1] == Bar.BORDER[1] and dress.border[1]._vertex[4] == Bar.BORDER[4], "the border black: not your target")
check(dress.background._vertex[4] == 1, "the bar's dark solid: the outline behind it never shows through, whatever its colour")
check(dress.health:GetStatusBarTexture()._masks and #dress.health:GetStatusBarTexture()._masks == 2
    and #dress.background._masks == 2 and #dress.border[1]._masks == 2 and #dress.border[2]._masks == 2
    and #dress.power:GetStatusBarTexture()._masks == 2,
    "the fill, its background and the power line cut at both ends; the border two halves, each at its two corners")
check(dress.border[1].corners[1]._texture == Core.Shape.CORNER.TOPLEFT and dress.border[2].corners[2]._texture == Core.Shape.CORNER.BOTTOMRIGHT,
    "by Core's corner masks")
check(dress.caps[1]._texture == Core.Shape.CAP_LEFT and dress.caps[1]._wrap[1] == "CLAMPTOWHITE"
    and dress.caps[2]._texture == Core.Shape.CAP_RIGHT, "by Core's caps, white beyond them")

local function Near(a, b) return math.abs(a - b) < 1e-6 end
-- Its size: the caps a quarter of each height, the bar a pixel inside its border.
dress:GetScript("OnSizeChanged")(dress)
local edge = Core.Pixels(dress, 1)
check(dress.border[1].corners[1]._width == high * Bar.CAP and dress.caps[2]._width == (high - 2 * edge) * Bar.CAP
    and Near(dress.border[1]._height, high / 2) and Near(dress.border[2]._height, high / 2),
    "the outline round by a quarter of the bar's height, its halves half of it each; the bar's caps a quarter of its own")
local reachOut = -dress.halo[3][1]._points[1][4] -- how far its top left corner stands out
check(Near(dress.halo[3][1].corners[1]._width, high * Bar.CAP + reachOut), "a band of the glow rounder by its reach: around the round")
check(dress.health._points[1][4] == edge and dress.health._points[2][4] == -edge, "the bar a pixel inside its border")
check(dress.power._height == (high - 2 * edge) * Bar.LINE, "the power line a third of the bar's height")
row:SetSize(120, 26)
dress:GetScript("OnSizeChanged")(dress)
check(dress._height == high and dress._width == dress.want, "the game's row higher (its style): ours as high as its line still")
row:SetSize(120, 20)
dress:GetScript("OnSizeChanged")(dress)

-- A boss: a thick golden border, the bar further in; a level too high to tell: the skull.
units.nameplate1.boss, units.nameplate1.level = true, -1
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
W.Fire("UNIT_LEVEL", "nameplate1")
-- How far a plate reaches beyond the dress (its top left corner's offset).
local function Reach(texture) return texture._points[1][5] end
check(dress.rank == Bar.RANKS.boss and dress.rankLine[1]._vertex[2] == 0.82 and Reach(dress.rankLine[1]) == 3 * edge
    and dress.health._points[1][4] == edge and Reach(dress.border[1]) == 0,
    "a boss: a thick golden line behind the border, from the same edge; the bar where it was")
check(Reach(dress.halo[1][1]) == 4 * edge and Reach(dress.halo[#dress.halo][1]) == (3 + #dress.halo) * edge, "the glow beyond the line")
check(dress.level._text == Text.SKULL, "the skull for its level")
units.nameplate1.boss, units.nameplate1.classification = false, "elite"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.RANKS.elite and dress.rankLine[1]._vertex[2] == 0.82 and Reach(dress.rankLine[1]) == edge
    and Reach(dress.halo[1][1]) == 2 * edge, "an elite: a thin golden line, a pixel past the border")
units.nameplate1.classification = "normal"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.PLAIN and not dress.rankLine:IsShown() and Reach(dress.halo[1][1]) == edge, "a plain one: the border only")
units.nameplate1.level = 22
W.Fire("UNIT_LEVEL", "nameplate1")

-- Health and name as they change.
units.nameplate1.health, units.nameplate1.most = 1325000, 1325000
W.Fire("UNIT_HEALTH", "nameplate1")
check(dress.health._value == 1325000 and dress.value._text == "1.32m | 100%", "health followed, short, and its percent")
check(dress.room.value == L(12) and dress._width == I + L(2) + NEAR + N(10) + G + L(12) + I, "its room the most it shows")
units.nameplate1.health = 4000
W.Fire("UNIT_HEALTH", "nameplate1")
check(dress.value._text == "4k | 1%" and dress.room.value == L(12), "health going down: the bar keeps its width")
units.nameplate1.health = 1325000
W.Fire("UNIT_HEALTH", "nameplate1")
check(Text.Short(850) == "850" and Text.Short(1250) == "1.2k" and Text.Short(12999) == "12.9k" and Text.Short(1000) == "1k"
    and Text.Short(2000000) == "2m" and Text.Short(1329999) == "1.32m" and Text.Short(1300000) == "1.3m",
    "under a thousand as it is, then thousands to one place, then millions to two, cut, no zeros at the end")
check(Text.Percent(1, 1000) == 1 and Text.Percent(999, 1000) == 99 and Text.Percent(0, 10) == 0, "whole percent, 1 while any is left")
units.nameplate1.name = Secret()
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
check(dress.name._text == units.nameplate1.name and dress.room.name == N(10), "a hidden name goes to the text as it is, in the room of the last")
units.nameplate1.name = "Archmage Ataeric the Unforgiving of the Blue Dragonflight"
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
check(dress.room.name == N(#units.nameplate1.name) and dress.name._width == dress.room.name and dress._width == dress.want,
    "a long name: all of its room, the bar longer for it")
units.nameplate1.name = "Young Wolf"
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
-- A level hidden the stand-in's way (W.Secret: an error when compared or counted with, so it must go through Core's
-- Plain): none shown, no room for it, the name first; said again: back in front of the name.
units.nameplate1.level = W.Secret()
W.Fire("UNIT_LEVEL", "nameplate1")
check(Core.Secret(units.nameplate1.level) and dress.level._text == "" and dress.room.level == nil and X(dress.name) == I,
    "a hidden level: none, no room for it, the name first")
units.nameplate1.level = 22
W.Fire("UNIT_LEVEL", "nameplate1")
check(dress.level._text == "22" and dress.room.level == L(2) and X(dress.name) == I + L(2) + NEAR, "said again: back in front of the name")
units.nameplate1.tapped = true
W.Fire("UNIT_FLAGS", "nameplate1")
check(dress.health._barColor[1] == Bar.TAPPED[1], "tapped by others: grey")
units.nameplate1.tapped, units.nameplate1.reaction = false, 4
W.Fire("UNIT_FLAGS", "nameplate1")
check(dress.health._barColor[3] == Bar.CALM[3], "one that does not attack on sight: light yellow")
units.nameplate1.reaction = 2
W.Fire("UNIT_FLAGS", "nameplate1")

-- Threat: grey, orange, red with the glow; a hidden answer goes to the glow as it is.
units.nameplate1.threat = { false, 0, 40 }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._text == "40%" and dress.threat._color[1] == Text.THREAT[0][1] and dress.glow._alpha == 0, "low threat: grey")
check(X(dress.threat) == I + L(2) + G and X(dress.name) == I + L(2) + G + L(4) + G, "on the list: the threat between the level and the name")
units.nameplate1.threat = { false, 1, 95 }
W.Fire("UNIT_THREAT_SITUATION_UPDATE", "player")
W.Wait(0)
check(dress.threat._text == "95%" and dress.threat._color[2] == Text.THREAT[1][2], "about to take its aggro: orange")
units.nameplate1.threat = { true, 3, 100 }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._color[2] == Text.THREAT[3][2] and dress.glow._alpha == 1, "aggro: red, and the bar glows")
local untouched = true
for _, layer in ipairs(dress.halo) do untouched = untouched and layer[1]._alpha == 1 and layer[2]._alpha == 1 end
check(untouched, "switched by its frame's alpha: the layers' own strengths never overwritten")
-- The game's colour from a hidden answer: it alone may look at the answer (here the test's secret says it).
CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a, GetRGB = function(self) return self.r, self.g, self.b end } end
C_CurveUtil = { EvaluateColorFromBoolean = function(value, yes, no) if value.truth then return yes end return no end }
local hidden = Secret()
hidden.truth = true
units.nameplate1.threat = { hidden, Secret(), Secret() }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._color[1] == Text.THREAT[Text.AGGRO][1] and dress.threat._color[2] == Text.THREAT[Text.AGGRO][2],
    "its kind hidden, the game says you have aggro: red")
local calm = Secret()
units.nameplate1.threat = { calm, Secret(), Secret() }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._color[1] == Text.THREAT[0][1], "its kind hidden, no aggro: grey")
units.nameplate1.threat = { hidden, Secret(), Secret() }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(type(dress.glow._alpha) == "table" and dress.glow._alpha.from == hidden and dress.glow._alpha.yes == nil,
    "a hidden answer: the glow takes it as it is, never compared, with the game's own alphas")
units.nameplate1.threat = nil
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._text == "" and dress.glow._alpha == 0 and dress.room.threat == nil and X(dress.name) == I + L(2) + NEAR,
    "off its list: none, and no room for it")

-- A quest: the sword outside the bar, left of it, the count first in the line; done, gone.
units.nameplate1.quest = { { type = 17, leftText = "Wolves Across the Border" }, { type = 8, leftText = "Young Wolf slain: 3/8" } }
W.Fire("QUEST_LOG_UPDATE")
W.Wait(0)
check(dress.quest:IsShown() and dress.quest._texture == Text.QUEST.kill and dress.count._text == "3/8"
    and dress.quest._points[1][1] == "RIGHT" and dress.quest._points[1][3] == "LEFT" and X(dress.quest) == -Text.OUTSIDE
    and X(dress.count) == I and X(dress.level) == I + L(3) + G
    and dress.foes._points[1][4] == -(Auras.GAP + Text.OUTSIDE + Text.size),
    "an objective to kill it: the sword left of the bar, 3/8 first inside it, the buffs past the sword")
units.nameplate1.quest[2] = { type = 8, leftText = "Wolf Pelt: 0/7" }
W.Fire("UNIT_QUEST_LOG_CHANGED", "player")
W.Wait(0)
check(dress.quest._texture == Text.QUEST.loot and dress.count._text == "0/7", "something to loot from it: the sack")
units.nameplate1.quest = nil
W.Fire("QUEST_LOG_UPDATE")
W.Wait(0)
check(not dress.quest:IsShown() and dress.room.quest == nil and dress.room.count == nil and X(dress.level) == I
    and dress.foes._points[1][4] == -Auras.GAP, "done: gone, no room, the buffs by the bar again")

-- Power that changes, and a unit without any.
units.nameplate1.powerNow = 70
W.Fire("UNIT_POWER_UPDATE", "nameplate1", "MANA")
check(dress.power._value == 70, "power followed")
units.nameplate1.powerMost = 0
W.Fire("UNIT_MAXPOWER", "nameplate1")
check(not dress.power:IsShown(), "no power: no line")
units.nameplate1.powerMost = 100
W.Fire("UNIT_MAXPOWER", "nameplate1")

-- Just after a /reload the game may measure texts endless: the bar gets a guess, never endless, and is measured
-- anew once the world shows.
local measure = methods.GetUnboundedStringWidth
methods.GetUnboundedStringWidth, methods.GetStringWidth = function() return math.huge end, function() return math.huge end
ns.Plate.Refresh()
check(dress._width > 0 and dress._width <= ns.Plate.WIDEST, "widths measured endless: the bar a sensible width all the same")
methods.GetUnboundedStringWidth, methods.GetStringWidth = measure, measure
W.Fire("PLAYER_ENTERING_WORLD")
W.Wait(1)
check(dress._width == dress.want and dress.room.name == N(10), "the world shown: every plate measured anew, right")

-------------------------------------------------------------------------------
--  The auras: the game's containers, set up once
-------------------------------------------------------------------------------
local own, foes, control = dress.own, dress.foes, dress.control
check(own and foes and control and own._groups.own.filter == Auras.OWN and foes._groups.foes.filter == Auras.FOES
    and control._groups.control.filter == Auras.CC, "your debuffs, a foe's buffs and crowd control, each in a container of the game's")
check(Auras.OWN:find("!CROWD_CONTROL", 1, true), "your crowd control shows once, with the others'")
check(own._points[1][1] == "BOTTOMLEFT" and own._points[1][2] == dress and own._points[1][3] == "TOPLEFT" and own._points[1][5] == 0,
    "your debuffs right above the bar, no gap")
check(foes._points[1][1] == "BOTTOMRIGHT" and foes._points[1][3] == "BOTTOMLEFT" and foes._growth[1] == AnchorUtil.FlowDirection.Left,
    "buffs left of the bar, growing away from it")
check(control._points[1][3] == "BOTTOMRIGHT" and control._points[1][2] == dress and control._growth[1] == AnchorUtil.FlowDirection.Right,
    "crowd control right of the bar")
check(own._unit == "nameplate1" and foes._unit == "nameplate1" and control._unit == "nameplate1", "set to the plate's unit")
local icon = own._groups.own.frames[1]
check(icon._icon and icon._cooldown and icon._count and icon._width == Auras.SIZE, "each frame the container makes gets its icon, time and count once")
check(Auras.Slots(190) == 8 and own._groups.own.most == Auras.Slots(dress._width) and foes._groups.foes.most == Auras.BUFFS,
    "as many debuffs as fit over the bar (eight over 190), three buffs")
Core.Set(ns.name, "buffs", false)
check(not foes:IsShown() and foes._unit == "none", "buffs off")
Core.Set(ns.name, "buffs", true)
Core.Set(ns.name, "debuffs", false)
check(not own:IsShown() and foes:IsShown(), "your debuffs off")
Core.Set(ns.name, "debuffs", true)
Core.Set(ns.name, "control", false)
check(not control:IsShown(), "crowd control off")
Core.Set(ns.name, "control", true)
-- The game's own aura icons under ours would take the mouse (their tooltip beside our bar): their mouse off, on the
-- ones the game sets out anew as well; on again when its parts come back in sight (below, and at the stand-down).
local gameAuras = plates.nameplate1.UnitFrame.AurasFrame
check(not gameAuras.icons[1]:IsMouseEnabled() and not gameAuras.LossOfControlFrame.AuraItemFrame:IsMouseEnabled(),
    "the game's aura icons under ours: their mouse off (the loss of control one too)")
gameAuras:RefreshList(2)
check(#gameAuras.icons == 3 and not gameAuras.icons[2]:IsMouseEnabled() and not gameAuras.icons[3]:IsMouseEnabled(),
    "icons the game sets out anew: off as well")

-------------------------------------------------------------------------------
--  A friend shown by name only, players, the raid marker, the border lit
-------------------------------------------------------------------------------
local bar = plates.nameplate1.UnitFrame.HealthBarsContainer.healthBar
bar:Hide() -- the game shows the plate by name only now
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "the game's health bar gone: its own plate as it is, ours away")
check(gameAuras.icons[1]:IsMouseEnabled() and gameAuras.icons[3]:IsMouseEnabled()
    and gameAuras.LossOfControlFrame.AuraItemFrame:IsMouseEnabled(), "its aura icons with the mouse again")
bar:Show()
check(dress:IsShown() and Faded(plates.nameplate1, 0), "back")
check(not gameAuras.icons[3]:IsMouseEnabled(), "its aura icons without the mouse again")

units.nameplate2 = { name = "Bran", surname = "Stoneheart", player = true, class = "WARRIOR", friend = true, health = 10,
                     most = 10, raid = 8, party = true, level = 20 }
plates.nameplate2 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate2")
local friend = DressOf(plates.nameplate2)
check(friend:IsShown() and plates.nameplate2.UnitFrame._alpha == 1, "a player in your group: shown")
check(friend.health._barColor[1] == 0.78 and friend.name._text == "Bran Stoneheart", "a player: the class colour, first name and surname")
-- Its item level: asked for (Core paces it), shown when the server answered, after the level.
units.nameplate2.gear = 32
check(inspected[#inspected] == "nameplate2" and friend.room.gear == nil, "a player: inspected, nothing shown before the answer")
W.Fire("INSPECT_READY", "Player-nameplate2")
local B = Text.BESIDE
check(friend.gear._text == "i32" and X(friend.gear) == X(friend.level) + L(2) + B + Text.size + B
    and X(friend.name) == X(friend.gear) + L(3) + G, "the answer: i32 between the level (and its raid marker) and the name")
Core.Set(ns.name, "gear", false)
check(friend.room.gear == nil and friend.gear._text == "", "the setting off: none, no room")
Core.Set(ns.name, "gear", true)
check(friend.gear._text == "i32", "on again: from what was kept")
-- A player's plate appearing in a fight (W.Combat: the stand-in's own, with the game's events): dressed as any, but
-- the game refuses the question then (Core.Inspect); asked once the fight ends, shown when the server answered.
local asks = #inspected
W.Combat(true)
units.nameplate7 = { name = "Edda", surname = "Ironvale", player = true, class = "WARRIOR", friend = true, party = true,
                     health = 10, most = 10, level = 20, gear = 41 }
plates.nameplate7 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate7")
local edda = DressOf(plates.nameplate7)
W.Wait(Core.Inspect.GAP + 0.3)
check(edda:IsShown() and Faded(plates.nameplate7, 0) and #inspected == asks and edda.room.gear == nil,
    "a player's plate in a fight: dressed; the item level not asked for (the game refuses it then)")
W.Combat(false)
W.Wait(Core.Inspect.GAP + 0.3)
check(#inspected == asks + 1 and inspected[#inspected] == "nameplate7", "the fight over: asked once")
W.Fire("INSPECT_READY", "Player-nameplate7")
check(edda.gear._text == "i41", "and shown when the server answered")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate7")
units.nameplate7, plates.nameplate7 = nil, nil
check(friend.level._color[1] == 0.3, "the level of someone you cannot attack in the game's colour for that")
check(not friend.foes:IsShown() and friend.own:IsShown(), "no buffs on someone you cannot attack")
check(friend.raid:IsShown() and friend.raid._cell[1] == 8 and friend.raid._cell[2] == 4 and friend.raid._cell[3] == 4,
    "a raid marker: the game's icon at its index")
check(friend.raid._points[1][1] == "LEFT" and friend.raid._points[1][2] == friend.top and X(friend.level) == I
    and X(friend.raid) == I + L(2) + B and friend.control._points[1][2] == friend,
    "in the line right after the level, as on the unit frames; the crowd control right")
units.nameplate2.raid = Secret()
W.Fire("RAID_TARGET_UPDATE")
check(friend.raid:IsShown() and friend.raid._cell[1] == units.nameplate2.raid, "an index hidden from addons goes to the icon as it is")
units.nameplate2.raid = nil
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown() and friend.room.raid == nil and X(friend.level) == I, "no marker: none")

-- A stranger: out of sight, unless a friend, guild member or your target; a player you can fight: shown, glowing.
units.nameplate2.party = false
W.Fire("GROUP_ROSTER_UPDATE")
W.Wait(0)
check(not friend:IsShown() and plates.nameplate2.UnitFrame._alpha == 0, "a player you do not know: no plate at all")
units.nameplate2.guild = true
W.Fire("GUILD_ROSTER_UPDATE")
W.Wait(0)
check(friend:IsShown() and plates.nameplate2.UnitFrame._alpha == 1, "in your guild: shown")
units.nameplate2.guild = false
friendOf = "nameplate2"
W.Fire("FRIENDLIST_UPDATE")
W.Wait(0)
check(friend:IsShown(), "on your friends list: shown")
friendOf = nil
W.Fire("FRIENDLIST_UPDATE")
W.Wait(0)
check(not friend:IsShown(), "not any more")
units.nameplate2.hunts = true
W.Fire("UNIT_FLAGS", "nameplate2")
check(friend:IsShown() and friend.glow._alpha == 1, "a player who may attack you though you may not attack it: shown, glowing")
units.nameplate2.hunts = nil
W.Fire("UNIT_FLAGS", "nameplate2")
check(not friend:IsShown(), "no fight possible either way: out of sight again")
Core.Set(ns.name, "players", false)
check(friend:IsShown(), "the setting off: every player's plate")
Core.Set(ns.name, "players", true)
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
check(friend:IsShown() and friend.border[1]._vertex[1] == 0.5 and friend.border[1]._vertex[4] == 1 and dress.border[1]._vertex[1] == 0,
    "your target: shown, its border white, the others' black")
units.focus, plates.focus = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_FOCUS_CHANGED")
check(dress.border[1]._vertex[2] == 0.49, "your focus's border in the game's colour for it")
units.nameplate2.friend, units.nameplate2.raid = false, 8
W.Fire("UNIT_FACTION", "nameplate2")
check(friend:IsShown() and friend.glow._alpha == 1, "a player who may attack you: shown, glowing")
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown(), "and no raid marker, as on the game's plates")
units.nameplate2.friend, units.nameplate2.party = true, true
W.Fire("UNIT_FACTION", "nameplate2")
check(friend.glow._alpha == 0, "a friend again: no glow")
-- The border of a player you know by how, the closest first: your guild, your party, your raid, a friend.
local wasTarget, wasFocus = plates.target, plates.focus
units.target, plates.target, units.focus, plates.focus = nil, nil, nil, nil
W.Fire("PLAYER_TARGET_CHANGED")
W.Fire("PLAYER_FOCUS_CHANGED")
local function Edge(kin) return friend.border[1]._vertex[1] == Bar.KIN[kin][1] and friend.border[1]._vertex[3] == Bar.KIN[kin][3] end
local function Roster(event) W.Fire(event) W.Wait(0) end
check(Edge("party"), "in your party: blue")
units.nameplate2.guild = true
Roster("GUILD_ROSTER_UPDATE")
check(Edge("guild"), "in your guild and your party: green, the guild first")
units.nameplate2.guild, units.nameplate2.party = false, false
raidOf.nameplate2, raidOf.player, groupOf[5], groupOf[1] = 5, 1, 2, 1
friendOf = "nameplate2"
Roster("GROUP_ROSTER_UPDATE")
check(Edge("raid"), "in your raid, another subgroup, and a friend: purple, the raid before the friend")
groupOf[5] = 1
Roster("GROUP_ROSTER_UPDATE")
check(Edge("party"), "in your own subgroup of the raid: your party, blue")
raidOf.nameplate2, raidOf.player = nil, nil
Roster("GROUP_ROSTER_UPDATE")
check(Edge("friend") and friend:IsShown(), "only a friend: pink")
units.nameplate2.guild = true
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
check(friend.border[1]._vertex[1] == Bar.TARGET[1] and friend.border[1]._vertex[2] == Bar.TARGET[2],
    "your target: its grey over the guild's green")
units.target, plates.target = nil, nil
W.Fire("PLAYER_TARGET_CHANGED")
check(Edge("guild"), "let go: green again")
units.nameplate2.guild, units.nameplate2.party, friendOf = false, true, nil
Roster("GROUP_ROSTER_UPDATE")
units.target, plates.target, plates.focus = units.nameplate2, wasTarget, wasFocus
units.focus = plates.focus and units.nameplate1 or nil
W.Fire("PLAYER_TARGET_CHANGED")
W.Fire("PLAYER_FOCUS_CHANGED")

-- A critter: no plate and so no name, unless your target, wanted for a quest, or the setting on.
units.nameplate6 = { name = "Rabbit", creature = 8, health = 5, most = 5, reaction = 4, level = 1 }
plates.nameplate6 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate6")
local rabbit = DressOf(plates.nameplate6)
check(rabbit and not rabbit:IsShown() and plates.nameplate6.UnitFrame._alpha == 0, "a critter: no plate at all")
units.target, plates.target = units.nameplate6, plates.nameplate6
W.Fire("PLAYER_TARGET_CHANGED")
check(rabbit:IsShown() and plates.nameplate6.UnitFrame._alpha == 1 and rabbit.name._text == "Rabbit", "your target: shown, filled")
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
check(not rabbit:IsShown() and plates.nameplate6.UnitFrame._alpha == 0, "not any more")
units.nameplate6.quest = { { type = 17, leftText = "Rabbit Stew" }, { type = 8, leftText = "Rabbit slain: 0/3" } }
W.Fire("QUEST_LOG_UPDATE")
W.Wait(0)
check(rabbit:IsShown() and rabbit.count._text == "0/3", "a quest of yours wants it: shown with the count")
units.nameplate6.quest = nil
W.Fire("QUEST_LOG_UPDATE")
W.Wait(0)
check(not rabbit:IsShown(), "done: gone")
Core.Set(ns.name, "critters", true)
check(rabbit:IsShown() and plates.nameplate6.UnitFrame._alpha == 1, "the setting on: every critter's plate")
Core.Set(ns.name, "critters", false)
check(not rabbit:IsShown(), "off again: none")
units.nameplate6.creature = 12
check(not ns.Plate.Wanted("nameplate6"), "a companion pet: none")
units.nameplate6.creature = 14
check(not ns.Plate.Wanted("nameplate6"), "a wild pet: none")
units.nameplate6.creature = Secret()
check(ns.Plate.Wanted("nameplate6"), "where the game hides the type: shown")
units.nameplate6.creature = 1
check(ns.Plate.Wanted("nameplate6"), "a beast: shown")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate6")
check(plates.nameplate6.UnitFrame._alpha == 1, "taken back: the game's own again")
units.nameplate6, plates.nameplate6 = nil, nil

-- A player's pet: out of sight with its stranger's plate, shown with a known one's, your target's or one you can fight.
UnitOwnerGUID = function(unit) return Unit(unit).owner end
UnitTokenFromGUID = function(guid)
    local token = type(guid) == "string" and guid:match("^Player%-(nameplate%d+)$")
    return token and plates[token] and token or nil
end
units.nameplate8 = { name = "Wolf", creature = 1, health = 50, most = 50, friend = true, reaction = 5, level = 20,
                     owner = "Player-nameplate7" }
plates.nameplate8 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate8")
local wolf = DressOf(plates.nameplate8)
check(wolf:IsShown() and plates.nameplate8.UnitFrame._alpha == 1, "a pet before its player's plate came: shown")
units.nameplate7 = { name = "Odo", player = true, class = "WARRIOR", friend = true, health = 90, most = 90, level = 20 }
plates.nameplate7 = GamePlate()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate7")
check(not DressOf(plates.nameplate7):IsShown() and not wolf:IsShown() and plates.nameplate8.UnitFrame._alpha == 0,
    "its player a stranger: both out of sight once the player's plate came")
units.nameplate7.guild = true
Roster("GUILD_ROSTER_UPDATE")
check(wolf:IsShown() and plates.nameplate8.UnitFrame._alpha == 1 and wolf.border[1]._vertex[1] == 0,
    "its player in your guild: shown, its border no kin's")
units.nameplate7.guild = false
Roster("GUILD_ROSTER_UPDATE")
check(not wolf:IsShown(), "not any more: gone with its player")
local before, beforePlate = units.target, plates.target
units.target, plates.target = units.nameplate7, plates.nameplate7
W.Fire("PLAYER_TARGET_CHANGED")
check(wolf:IsShown(), "its player your target: shown too")
units.target, plates.target = units.nameplate8, plates.nameplate8
W.Fire("PLAYER_TARGET_CHANGED")
check(wolf:IsShown(), "the pet your target: shown")
units.target, plates.target = before, beforePlate
W.Fire("PLAYER_TARGET_CHANGED")
check(not wolf:IsShown(), "neither: gone")
units.nameplate8.friend = false
W.Fire("UNIT_FACTION", "nameplate8")
check(wolf:IsShown(), "a pet you may attack: shown")
units.nameplate8.friend = true
W.Fire("UNIT_FACTION", "nameplate8")
Core.Set(ns.name, "players", false)
check(wolf:IsShown(), "the setting off: every pet's plate")
Core.Set(ns.name, "players", true)
check(not wolf:IsShown(), "on again: gone")
units.nameplate8.owner = "Player-player"
check(ns.Plate.Wanted("nameplate8"), "your own pet: shown")
units.nameplate8.owner = Secret()
check(ns.Plate.Wanted("nameplate8"), "where the game hides its owner: shown")
units.nameplate8.owner = "Creature-0-1-2-3-4-5"
check(ns.Plate.Wanted("nameplate8"), "a creature's guardian: shown as any creature")
units.nameplate8.owner, units.nameplate8.creature = "Player-nameplate7", 12
Core.Set(ns.name, "critters", true)
check(ns.Plate.Wanted("nameplate8"), "a stranger's companion with critters shown: a critter, shown")
Core.Set(ns.name, "critters", false)
units.nameplate7.guild = true
check(not ns.Plate.Wanted("nameplate8"), "a guild member's companion with critters hidden: a critter, hidden")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate8")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate7")
check(plates.nameplate8.UnitFrame._alpha == 1 and plates.nameplate7.UnitFrame._alpha == 1, "both taken back")
units.nameplate7, plates.nameplate7, units.nameplate8, plates.nameplate8 = nil, nil, nil, nil
UnitTokenFromGUID = nil

-------------------------------------------------------------------------------
--  Combo points under the bar of the unit you have them on
-------------------------------------------------------------------------------
check(not (dress.strip and dress.strip:IsShown()), "no points anywhere: no row")
comboOn = units.nameplate1
units.target, plates.target = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_TARGET_CHANGED")
W.Wait(0)
local strip = dress.strip
local function Lit()
    local lit = 0
    for index, segment in ipairs(strip.segments) do
        if segment:IsShown() and segment._value >= index then lit = lit + 1 end
    end
    return lit
end
check(strip and strip:IsShown() and #strip.segments == 5 and Lit() == 2, "on your target's bar: two of five")
check(strip.segments[3]._min == 2 and strip.segments[3]._max == 3, "each segment a status bar of its own point")
check(strip._points[1][2] == dress and strip._points[1][3] == "BOTTOMLEFT" and strip._height == dress._height * Resource.SHARE,
    "a row of its own under the bar, a third as high")
check(#strip.segments[1]:GetStatusBarTexture()._masks == 2 and strip.segments[5]:GetStatusBarTexture()._masks[2] == strip.caps[2]
    and strip.caps[1]._texture == Core.Shape.CORNER.BOTTOMLEFT and strip.caps[2]._texture == Core.Shape.CORNER.BOTTOMRIGHT,
    "the lowest row: round at its bottom corners alone")
check(dress.border[2]._points[1][2] == strip and dress.health._points[2][5] == 0 and dress.caps[1]._texture == Core.Shape.CORNER.TOPLEFT,
    "inside the one outline, the bar square where the row meets it")
check(strip.segments[1]._points[2][4] < strip.segments[2]._points[1][4] and strip.segments[1]._points[1][4] == 0,
    "a pixel apart, the first from the strip's left")
local function Backgrounds(frame)
    local count = 0
    for _, widget in ipairs(W.frames) do
        if widget._parent == frame and widget ~= frame._fill and widget:GetObjectType() == "Texture" then count = count + 1 end
    end
    return count
end
check(Backgrounds(dress.health) == 1 and Backgrounds(dress.power) == 0 and Backgrounds(strip.inner) == 1 and Backgrounds(strip.segments[1]) == 0,
    "no background behind the power line; the points' row the bar's dark where a point is not built")
combo = Secret()
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
check(strip.segments[1]._value == combo and strip.segments[5]._value == combo, "a hidden count goes to every segment as it is")
casts.nameplate1 = { name = "Fireball", icon = 135812, starts = (W.clock - 1) * 1000, ends = (W.clock + 2) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(dress.cast:IsShown() and dress.cast._points[1][2] == strip and dress.cast._points[1][3] == "BOTTOMLEFT"
    and dress.border[2]._points[1][2] == dress.cast, "a cast too: under the points, inside the outline")
check(strip.caps[1]._texture ~= Core.Shape.CORNER.BOTTOMLEFT and strip.inner._points[2][5] == 0, "the points square then, the cast the lowest")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_FAILED", "nameplate1")
check(not dress.cast:IsShown() and dress.border[2]._points[1][2] == strip and strip.caps[1]._texture == Core.Shape.CORNER.BOTTOMLEFT,
    "the cast gone: the points the lowest again")
combo = 3
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
W.Wait(0)
check(strip:IsShown() and strip.segments[3]._value == 3 and not (friend.strip and friend.strip:IsShown()),
    "your points on a foe you no longer target: still on its plate; none on a friend's")
combo = Secret()
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
check(not strip:IsShown(), "a hidden count: on your target's plate only")
combo = 0
units.target, plates.target = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_TARGET_CHANGED")
W.Wait(0)
check(not strip:IsShown(), "no points: no row, on your target's plate too")
combo = 2
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
check(strip:IsShown() and Lit() == 2, "the first point: the row")
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
comboOn = nil
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
-- Retail keeps the points on your character whatever you target, and gives up to seven: on your target's plate alone
do
    W.Play("retail")
    local asked, most, targeted, targetPlate = GetComboPoints, UnitPowerMax, units.target, plates.target
    GetComboPoints = function() return combo end -- the same for every unit: they are yours
    UnitPowerMax = function(unit, kind)
        if unit == "player" and kind == Enum.PowerType.ComboPoints then return 7 end
        return most(unit, kind)
    end
    combo = 6
    units.target, plates.target = units.nameplate1, plates.nameplate1
    W.Fire("PLAYER_TARGET_CHANGED")
    W.Wait(0)
    check(strip:IsShown() and strip.most == 7 and Lit() == 6, "Retail: on your target's plate, six of seven")
    units.target, plates.target = units.nameplate2, plates.nameplate2
    W.Fire("PLAYER_TARGET_CHANGED")
    W.Wait(0)
    check(not strip:IsShown(), "Retail: a foe you no longer target shows none, though the game counts them for it too")
    GetComboPoints, UnitPowerMax, combo = asked, most, 2
    W.Play("forever")
    units.target, plates.target = targeted, targetPlate
    W.Fire("PLAYER_TARGET_CHANGED")
    W.Wait(0)
end

-------------------------------------------------------------------------------
--  Distance from your character: size by it alone, on a spring; out of reach: red
-------------------------------------------------------------------------------
local Range = ns.Range
for _, list in ipairs({ Range.ENEMY, Range.FRIEND }) do
    for _, entry in ipairs(list) do itemRange[entry[2]] = entry[1] end
end
local CVar = C_CVar.GetCVar
check(CVar("nameplateMinScale") == "1" and CVar("nameplateMaxScale") == "1" and CVar("nameplateSelectedScale") == "1"
    and CVar("nameplateNotSelectedAlpha") == "1" and CVar("nameplateMinAlpha") == "1",
    "the game's own scaling and fading off: nothing but the distance sizes a plate")
check(CVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "0" and ns.options.foundCVars.nameplateShowOnlyNameForFriendlyPlayerUnits == "1",
    "friendly players not by name only while the module is on (their plates whole, dressed), yours kept")
local function Near(a, b) return math.abs(a - b) < 1e-6 end
check(Near(Scale.Size(0), 1) and Near(Scale.Size(10), 1) and Near(Scale.Size(25), 0.75) and Near(Scale.Size(40), 0.5)
    and Near(Scale.Size(50), 0.375) and Near(Scale.Size(60), 0.25) and Near(Scale.Size(500), 0.25),
    "full within 10 yards, half at 40, a quarter at 60, straight between")
-- The ladders: items and your spells, the shortest first; a spell with a least range stays out.
Range.Rebuild()
units.nameplate1.friend, units.target, plates.target, units.focus, plates.focus = nil, nil, nil, nil, nil
reach[100], reach[101] = nil, nil
local function Between(unit) local least, most, reach = Range.Check(unit) return least, most, reach end
yards.nameplate1 = 22
local least, most, inReach = Between("nameplate1")
check(least == 20 and most == 25 and inReach == true, "22 yards: between the 20 and 25 yard items; the shot (8 to 30) reaches it")
yards.nameplate1 = 3
least, most = Between("nameplate1")
check(least == 0 and most == 5, "3 yards: within the 5 yard rung")
yards.nameplate1 = 45
least, most, inReach = Between("nameplate1")
check(least == 40 and most == 60 and inReach == false, "45 yards: past the last rung (40), up to 60; none of your attacks reaches it")
units.nameplate2.friend = true
yards.nameplate2 = 47
least, most, inReach = Between("nameplate2")
check(least == 45 and most == 50 and inReach == nil, "a friend: on the friends' ladder (45, 50), no reach of attacks")
-- In a fight no item is asked about any unit, foe or friend (the game blocks it): the spells alone.
local asked = {}
local itemAsk = C_Item.IsItemInRange
C_Item.IsItemInRange = function(item, unit) asked[unit] = (asked[unit] or 0) + 1 return itemAsk(item, unit) end
W.combat = true
yards.nameplate1 = 22
least, most, inReach = Between("nameplate1")
check(not asked.nameplate1 and inReach == true, "a foe in a fight: no item asked, your shot still says it reaches")
Between("nameplate2")
check(not asked.nameplate2, "a friend in a fight: no item asked either")
W.combat = false
-- Another of the game's restrictions (an encounter) out of a fight: no item either, till it ends.
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 2)
Between("nameplate1")
Between("nameplate2")
check(not asked.nameplate1 and not asked.nameplate2, "in an encounter: no item asked about a foe or a friend")
W.Fire("ADDON_RESTRICTION_STATE_CHANGED", 1, 0)
asked = {}
Between("nameplate1")
Between("nameplate2")
check((asked.nameplate1 or 0) > 0 and (asked.nameplate2 or 0) > 0, "out of the fight and the encounter: the items again")
C_Item.IsItemInRange = itemAsk
-- The distance kept: in the middle at first, where it was while within the rungs, at the rung just passed.
check(Range.Settle(nil, 20, 25) == 22.5 and Range.Settle(22.5, 20, 25) == 22.5 and Range.Settle(22.5, 25, 30) == 25
    and Range.Settle(25, 20, 25) == 25 and Range.Settle(25, 15, 20) == 20 and Range.Settle(30, nil, nil) == 30,
    "a distance known for sure only where its unit passed a rung")
-- No spell can say, the ladder puts it beyond your farthest attack: out of reach too.
reach[100], reach[101] = nil, nil
local shot = ranges[101]
local strike = ranges[100]
ranges[101], ranges[100] = { 8, 30 }, { 0, 5 }
local said = C_Spell.IsSpellInRange
C_Spell.IsSpellInRange = function() return nil end
yards.nameplate1 = 38
least, most, inReach = Between("nameplate1")
check(least == 35 and inReach == false, "38 yards, none of your spells can say: beyond the farthest (30), out of reach")
yards.nameplate1 = 22
least, most, inReach = Between("nameplate1")
check(inReach == nil, "22 yards, none can say: not out of reach")
C_Spell.IsSpellInRange, ranges[101], ranges[100] = said, shot, strike
-- The driver: distances looked at, each plate moving evenly to its size, ours alone deciding.
local tick = Scale.driver:GetScript("OnUpdate")
local function Settle() for _ = 1, 500 do tick(Scale.driver, 0.02) end end
yards.nameplate1 = 3
plates.nameplate1:SetScale(1)
Settle()
local full = Scale.Full()
check(Near(dress._scale, full) and Near(plates.nameplate1.UnitFrame._scale, 1) and dress._alpha == 1 and dress.showing == nil,
    "3 yards: full size, seen, settled")
check(full == 1.25, "full: the setting Nameplate size, 125% at first")
-- A plate appearing: its unit asked at once, at the size of its distance, never larger; unseen, fading in evenly.
units.nameplate7 = { name = "Far Wolf", health = 50, most = 100, reaction = 2, level = 20 }
plates.nameplate7 = GamePlate()
yards.nameplate7 = 50
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate7")
local far = DressOf(plates.nameplate7)
local born, larger, alphas = far._scale, false, {}
check(far._alpha == 0 and far.yards == 50, "a plate appearing 50 yards off (past the last rung, up to 60): unseen, its distance known")
for _ = 1, 10 do
    tick(Scale.driver, 0.02)
    if far._scale > born + 1e-9 then larger = true end
    alphas[#alphas + 1] = far._alpha
end
check(Near(born, full * Scale.Size(50)) and not larger, "at the size of its distance at once, never larger")
check(Near(alphas[1], 0.02 / Scale.SHOW) and Near(alphas[10], 10 * 0.02 / Scale.SHOW)
    and Near(alphas[10] - alphas[9], alphas[2] - alphas[1]), "fading in from unseen in a straight line")
check(Near(Scale.SHOW * 7, 5), "within the time a run takes from 60 yards to 55")
Settle()
check(far._alpha == 1 and far.showing == nil, "then seen")
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate7")
-- The setting Nameplate transparency: every plate but your target's that much seen through, the game's unit frame
-- under ours too; a plate appearing fades in up to it; your target's whole.
;(function()
    Core.Set(ns.name, "transparency", 40)
    check(Near(dress._alpha, 0.6) and Near(plates.nameplate1.UnitFrame._alpha, 0.6),
        "40%: a plate and the game's unit frame under it seen through")
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate7")
    check(far._alpha == 0, "a plate appearing: unseen")
    for _ = 1, 5 do tick(Scale.driver, 0.02) end
    check(Near(far._alpha, 0.6 * 5 * 0.02 / Scale.SHOW), "fading in towards the setting's")
    Settle()
    check(Near(far._alpha, 0.6) and far.showing == nil, "then at the setting's")
    units.target, plates.target = units.nameplate1, plates.nameplate1
    W.Fire("PLAYER_TARGET_CHANGED")
    check(dress._alpha == 1 and plates.nameplate1.UnitFrame._alpha == 1 and Near(far._alpha, 0.6),
        "your target's plate whole, the others still seen through")
    units.target, plates.target = nil, nil
    W.Fire("PLAYER_TARGET_CHANGED")
    check(Near(dress._alpha, 0.6), "let go: seen through again")
    Core.Set(ns.name, "distance", false)
    check(Near(dress._alpha, 0.6) and Near(far._alpha, 0.6), "without size by distance too")
    Core.Set(ns.name, "distance", true)
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate7")
    Core.Set(ns.name, "transparency", 0)
    Settle()
    check(dress._alpha == 1 and plates.nameplate1.UnitFrame._alpha == 1, "0%: solid")
end)()
units.nameplate7, plates.nameplate7, yards.nameplate7 = nil, nil, nil
-- Walking away: the plate follows eased, quick at first and slower as it arrives, never past its size, there in a moment.
yards.nameplate1 = 22
local never, last, steps, there = true, dress._scale, {}, nil
for index = 1, 500 do
    tick(Scale.driver, 0.02)
    if dress._scale > last + 1e-9 or dress._scale < full * Scale.Size(20) - 1e-9 then never = false end
    if dress._scale ~= last then steps[#steps + 1] = last - dress._scale end
    if not there and dress._scale == full * Scale.Size(20) then there = index * 0.02 end
    last = dress._scale
end
check(never and Near(dress._scale, full * Scale.Size(20)) and #steps > 3 and steps[2] < steps[1] and steps[3] < steps[2]
    and there and there <= 0.5, "22 yards (past the 20 yard rung): smaller, eased, never past its size, there within half a second")
-- Past the next rung (from 20 to 25): at that rung, then on at a run's pace (none known yet), every frame, never past
-- the rung beyond (30), where it waits for the unit to pass it.
yards.nameplate1 = 27
for _ = 1, 10 do tick(Scale.driver, 0.02) end
local walked = dress.yards
for _ = 1, 5 do tick(Scale.driver, 0.02) end
check(dress.yards > 25 and dress.yards < 30 and Near(dress.yards - walked, ns.Range.RUN * 0.1) and dress.pace == ns.Range.RUN,
    "27 yards, past the 25 yard rung: from it on at a run's pace, every frame")
Settle()
check(dress.yards == 30 and dress.pace == 0 and Near(dress._scale, full * Scale.Size(30)), "never past the 30 yard rung: it waits there")
-- Its own pace from the two rungs it passed last: in past 25, half a second later past 20: 10 yards a second, in.
local function Walk(seconds)
    for _ = 1, math.floor(seconds / 0.02 + 0.5) do
        W.clock = W.clock + 0.02
        tick(Scale.driver, 0.02)
    end
end
yards.nameplate1 = 24
Walk(0.1)
local crossed = dress.markAt
check(dress.mark == 25 and dress.pace == -ns.Range.RUN, "in past the 25 yard rung (it passed 25 going out long ago): on in at a run's pace")
Walk(0.4)
yards.nameplate1 = 19
Walk(0.1)
check(dress.mark == 20 and Near(dress.pace, -5 / (dress.markAt - crossed)) and dress.pace < -ns.Range.RUN,
    "half a second later past the 20 yard rung: on at its own pace, from the two")
local was = dress.yards
Walk(0.1)
check(dress.yards < was and dress.yards >= 15 and Near(dress._scale, full * Scale.Size(dress.yards)) == false
    and dress.aim == Scale.Size(dress.yards), "its size aimed at that distance every frame, eased after it")
-- Between two looks: the two rungs around it asked, nothing more.
local questions = 0
local itemAsk, spellAsk = C_Item.IsItemInRange, C_Spell.IsSpellInRange
C_Item.IsItemInRange = function(...) questions = questions + 1 return itemAsk(...) end
local least, most, _, at = ns.Range.Check("nameplate1", dress.rung)
C_Item.IsItemInRange = itemAsk
check(least == 15 and most == 20 and at == dress.rung and questions <= 2, "still between the 15 and 20 yard rungs: two questions")
-- A jump past several rungs at once (a charge): at the nearer of them, no pace.
yards.nameplate1 = 3
Walk(0.1)
check(dress.yards == 5 and dress.pace == 0, "from 18 to 3 yards at once: at the 5 yard rung, no pace")
yards.nameplate1 = 27
Settle()
check(Near(dress.edge, Core.Pixels(dress, 1)) and dress.fitted == dress.now,
    "settled at its size: laid out anew, the border one screen pixel at it")
-- Its texts measured anew as it grows or shrinks (the game draws small letters a little wider or narrower): within
-- their spare the bar keeps its width; past it the bar widens; narrower only with more than twice the spare left.
local drawn, wide = methods.GetUnboundedStringWidth, 1
methods.GetUnboundedStringWidth = function(self) return drawn(self) * (self == dress.name and wide or 1) end
local room, want = dress.room.name, dress.want
check(room == N(10) and dress.measured == dress.now, "settled: its texts measured at its size")
wide = 1.05
yards.nameplate1 = 32
Settle()
check(dress.yards > 30 and Near(dress._scale, full * Scale.Size(dress.yards)) and dress.measured == dress.now
    and dress.room.name == room and dress.want == want, "smaller, its name drawn a little wider: within its spare, the bar as wide as it was")
wide = 1.15
yards.nameplate1 = 22
Settle()
check(dress.room.name == Text.Spare(nil, math.ceil(60 * 1.15) + Text.SLACK, Text.SPARE) and dress.want > want
    and dress.name._width == dress.room.name and dress._width == dress.want,
    "drawn wider still: the name never cut short, the bar wider for it, with its spare again")
wide = 1
yards.nameplate1 = 32
Settle()
check(Near(dress._scale, full * Scale.Size(30)) and dress.room.name == room and dress.want == want,
    "smaller again, drawn as wide as at first: the bar back to its width")
methods.GetUnboundedStringWidth = drawn
yards.nameplate1 = 27
Settle()
-- Your target: always full, whatever its distance, reached quickly.
units.target, plates.target = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_TARGET_CHANGED")
for _ = 1, 40 do tick(Scale.driver, 0.02) end
check(Near(dress._scale, full), "your target at 27 yards: full size, within a moment")
plates.nameplate1:SetScale(1.3) -- whatever the game still does to a selected plate
Settle()
check(Near(dress._scale * 1.3, full) and Near(plates.nameplate1.UnitFrame._scale * 1.3, 1), "a scale the game still gives a plate: undone")
plates.nameplate1:SetScale(1)
Settle()
check(dress.border[1]._vertex[1] == 0.5 and dress.border[1]._vertex[2] == 0.5, "the shot reaches it: your target's border grey")
yards.nameplate1 = 38
Settle()
check(dress.out == true and dress.border[1]._vertex[2] == Bar.FAR[2] and dress.border[1]._vertex[4] == 0.5
    and Near(dress._scale, full), "38 yards: out of reach of all your attacks, red at half strength; your target still full size")
units.target, plates.target = nil, nil
W.Fire("PLAYER_TARGET_CHANGED")
check(dress.border[1]._vertex[2] == Bar.FAR[2], "not your target, still out of reach: red over the black")
yards.nameplate1 = 3
Settle()
check(dress.out == false and dress.border[1]._vertex[1] == Bar.BORDER[1], "in reach of the strike: black again")
Core.Set(ns.name, "plateSize", 300)
Settle()
check(Near(dress._scale, 3), "the setting Nameplate size: 300%")
Core.Set(ns.name, "plateSize", 125)
yards.nameplate1 = 6
Settle()
check(dress.out == true, "6 yards: out of the strike's reach, inside the shot's least: red")
harmful[100] = nil -- a character with only a shot (least 8): its no at 6 yards says nothing
Range.Rebuild()
Settle()
check(dress.out == false, "only a spell with a least range, too close for it: not red")
harmful[100] = true
Range.Rebuild()
units.target, plates.target = units.nameplate1, plates.nameplate1
SlashCmdList.SANEUI("range")
check(not ns.off, "/sane range tells what the game answers")
units.target, plates.target = nil, nil
yards.nameplate1 = 38
Core.Set(ns.name, "range", false)
Settle()
check(dress.out == false and dress.border[1]._vertex[1] == Bar.BORDER[1], "the red border switched off: black")
Core.Set(ns.name, "range", true)
yards.nameplate1 = 3
Settle()
W.combat = true
Core.Set(ns.name, "distance", false)
check(CVar("nameplateSelectedScale") == "1" and Near(dress._scale, full) and plates.nameplate1.UnitFrame._scale == 1,
    "size by distance off in a fight: the plates at full size at once, the CVars wait")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(CVar("nameplateSelectedScale") == "1.2" and CVar("nameplateNotSelectedAlpha") == "0.5", "after it: the game's defaults")
check(CVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "0", "friendly players' plates whole with the setting off too")
Core.Set(ns.name, "distance", true)
check(CVar("nameplateSelectedScale") == "1", "on again")
-- The game's stored settings or a profile put one back after the login: ours again a little later.
C_CVar.SetCVar("nameplateSelectedScale", "1.2")
W.Fire("CVAR_UPDATE", "nameplateSelectedScale", "1.2")
W.Wait(Scale.AGAIN + 0.1)
check(CVar("nameplateSelectedScale") == "1", "a CVar of ours changed by something else: set again a little later")
C_CVar.SetCVar("nameplateNotSelectedAlpha", "0.5")
W.Fire("PLAYER_ENTERING_WORLD")
W.Wait(Scale.AGAIN + 0.1)
check(CVar("nameplateNotSelectedAlpha") == "1", "the world shown: ours again a little later")
-- Switched off: what was there before ours back once, then the CVars left alone (your own value, a profile's).
Core.Set(ns.name, "distance", false)
C_CVar.SetCVar("nameplateMinAlpha", "0.7")
W.Fire("CVAR_UPDATE", "nameplateMinAlpha", "0.7")
W.Wait(Scale.AGAIN + 0.1)
check(CVar("nameplateMinAlpha") == "0.7", "off: a value of yours left alone")
Core.Set(ns.name, "distance", true)
check(CVar("nameplateMinAlpha") == "1" and ns.options.foundCVars.nameplateMinAlpha == "0.7", "on: ours, yours kept")
ns.OnLogout()
check(CVar("nameplateMinAlpha") == "0.7" and CVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "1"
    and next(ns.options.foundCVars) == nil, "the game about to write its settings: yours back, so a module gone leaves them alone")
W.Fire("CVAR_UPDATE", "nameplateMinAlpha", "0.7")
W.Wait(Scale.AGAIN + 0.1)
check(CVar("nameplateMinAlpha") == "0.7", "and nothing of ours sets them again before the next login")
Core.Set(ns.name, "distance", false)
Core.Set(ns.name, "distance", true)
check(CVar("nameplateMinAlpha") == "1", "the next start: ours again")
-- A value of yours that is already ours (the selected plate not larger): found as it is, and yours again at the
-- logout, not the game's default.
ns.OnLogout()
C_CVar.SetCVar("nameplateSelectedScale", "1") -- your own choice, the same as ours
Core.Set(ns.name, "distance", false)
Core.Set(ns.name, "distance", true)
check(ns.options.foundCVars.nameplateSelectedScale == "1" and CVar("nameplateSelectedScale") == "1",
    "a value of yours already at ours: found too")
ns.OnLogout()
check(CVar("nameplateSelectedScale") == "1", "and at the logout it stays yours, not the game's default")
C_CVar.SetCVar("nameplateSelectedScale", "1.2")
Core.Set(ns.name, "distance", false)
Core.Set(ns.name, "distance", true) -- ours again, as at the next login, the game's own found
check(CVar("nameplateSelectedScale") == "1" and ns.options.foundCVars.nameplateSelectedScale == "1.2", "(ours again)")

-------------------------------------------------------------------------------
--  Combat text over a plate and over your character
-------------------------------------------------------------------------------
;(function()
    local CombatText = ns.CombatText
    CombatText.Update() -- as at a login: ours set (a logout above, if any, put the game's back)
    check(CVar("floatingCombatTextCombatDamage_v2") == "0" and CVar("floatingCombatTextCombatHealing_v2") == "0"
        and CVar("enableFloatingCombatText") == "0", "the game's own combat text off while ours shows")
    check(ns.options.combatPictures == false, "what did no harm: no drawings by default, in both profiles (none sets them)")
    W.Fire("UNIT_COMBAT", "nameplate1", "PARRY", "", 0, 1)
    local parry = dress.numbers[1]
    check(parry.text:IsShown() and not parry.picture:IsShown() and parry.text._text == "parry"
        and parry.text._color[2] == 1, "a parry by default: the game's word, white")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 0, 1)
    check(dress.numbers[2].text._text == "Miss" and not dress.numbers[2].picture:IsShown(), "a hit of nothing by default: the word too")
    CombatText.Clear(dress)
    Core.Set(ns.name, "combatPictures", true) -- the drawings, from here on
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "CRITICAL", 1234, 4)
    local hit = dress.numbers and dress.numbers[1]
    check(hit and hit._parent == dress and hit.text._text[1].abbreviated == 1234 and hit.text._font[2] == CombatText.HEIGHT * CombatText.CRIT,
        "a critical hit rises over the plate, larger, in the game's abbreviation")
    check(hit.text._font[1] == Core.Journal.FONT_BOLD and hit.text._font[3] == "OUTLINE", "in Kalam Bold, outlined")
    check(hit.text._color[1] == 1 and hit.text._color[2] == 0.1 and hit.motion._playing and hit.swell._scale[1] == CombatText.SWELL,
        "a spell's damage (fire) red, and it swells once")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 0, 1)
    local miss = dress.numbers[2]
    check(miss.picture:IsShown() and not miss.text:IsShown() and miss.picture._texture == CombatText.ART .. "miss"
        and miss.picture._width == CombatText.PICTURE, "a hit of nothing: the drawing of a miss, not a word")
    check(miss._points[1][4] ~= hit._points[1][4], "two at once stand side by side")
    W.Fire("UNIT_COMBAT", "nameplate1", "PARRY", "", 0, 1)
    check(dress.numbers[3].picture._texture == CombatText.ART .. "parry", "a parry: its drawing")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "BLOCK", 0, 1)
    check(dress.numbers[4].picture._texture == CombatText.ART .. "block" and dress.numbers[4].picture._vertex[2] == 1,
        "a blow blocked whole: the shield, white")
    W.Fire("UNIT_COMBAT", "nameplate1", "IMMUNE", "", 0, 1)
    check(dress.numbers[5].picture._texture == CombatText.ART .. "immune" and dress.numbers[5].picture._vertex[1] == 1
        and dress.numbers[5].picture._vertex[2] < 0.5, "an immunity: the bubble, bright red")
    W.Fire("UNIT_COMBAT", "nameplate1", "RESIST", "", 0, 1)
    check(dress.numbers[6].text:IsShown() and dress.numbers[6].text._text == "resist", "no drawing for a resist: the game's word")
    Core.Set(ns.name, "combatPictures", false)
    W.Fire("UNIT_COMBAT", "nameplate1", "PARRY", "", 0, 1)
    local word = dress.numbers[#dress.numbers]
    check(word.text:IsShown() and not word.picture:IsShown() and word.text._text == "parry", "drawings off: the game's word")
    Core.Set(ns.name, "combatPictures", true)
    W.gone = { [CombatText.ART .. "evade"] = true }
    W.Fire("UNIT_COMBAT", "nameplate1", "EVADE", "", 0, 1)
    check(dress.numbers[#dress.numbers].text:IsShown() and dress.numbers[#dress.numbers].text._text == "evade"
        and not dress.numbers[#dress.numbers].picture:IsShown(), "a drawing's file missing: the word")
    W.gone = nil
    CombatText.Clear(dress)
    W.Fire("UNIT_COMBAT", "nameplate1", "HEAL", "", 80, 2)
    check(dress.numbers[1].text._text.form == "+%s" and dress.numbers[1].text._color[2] == 1 and dress.numbers[1].text._color[1] < 0.5
        and not dress.numbers[1].picture:IsShown(), "a heal: green, with a plus, no picture left from before")
    W.Fire("UNIT_COMBAT", "nameplate1", Secret(), Secret(), Secret(), Secret())
    check(#dress.numbers == 2 and dress.numbers[2].text._color[3] == 1, "a hidden hit: written as it is, white, nothing compared")
    -- Forever's own amount hidden (since 70755), the kind and flags plain: W.Secret errors when compared.
    local blow = W.Secret()
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", blow, 1)
    check(#dress.numbers == 3 and dress.numbers[3].text._text[1].abbreviated == blow, "a hidden amount: the game's abbreviation of it, never compared")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "BLOCK", W.Secret(), 1)
    check(#dress.numbers == 4 and dress.numbers[4].picture._texture == CombatText.ART .. "block",
        "a hidden amount blocked whole: the shield, no number")
    dress.numbers[4].motion:Finish()
    dress.numbers[3].motion:Finish()
    W.Fire("UNIT_COMBAT", "nameplate1", "ENERGIZE", "", 10, 0)
    check(#dress.numbers == 2, "power gained: nothing")
    local first = dress.numbers[1]
    first.motion:Finish()
    check(#dress.numbers == 1 and not first:IsShown(), "a number done goes back to the pool")
    for _ = 1, CombatText.MOST + 2 do W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 5, 1) end
    check(#dress.numbers == CombatText.MOST and dress.numbers[1].text._text[1].abbreviated == 5, "no more than CombatText.MOST on a plate: the oldest go")
    Core.Set(ns.name, "combatHeals", false)
    local last = dress.numbers[#dress.numbers]
    W.Fire("UNIT_COMBAT", "nameplate1", "HEAL", "", 80, 2)
    check(dress.numbers[#dress.numbers] == last, "heals switched off: none")
    Core.Set(ns.name, "combatHeals", true)
    Core.Set(ns.name, "combatText", false)
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 7, 1)
    check(dress.numbers[#dress.numbers] == last and CVar("floatingCombatTextCombatDamage_v2") == "1"
        and CVar("enableFloatingCombatText") == "0", "over plates off: none there, the game's numbers over units back, its text about you still off")
    Core.Set(ns.name, "combatText", true)
    CombatText.Clear(dress)
    check(#dress.numbers == 0, "the plate going takes its numbers")

    -- Your own character: no plate, a point under the screen's middle, about at its feet.
    W.Fire("UNIT_COMBAT", "player", "WOUND", "", 42, 1)
    local you = W.frames[#W.frames]
    for _, frame in ipairs(W.frames) do
        if frame.numbers and frame ~= dress and frame.numbers[1] then you = frame end
    end
    local mine = you.numbers and you.numbers[1]
    check(mine and you._points[1][1] == "CENTER" and you._points[1][5] == CombatText.SELF and mine.text._text.form == "-%s"
        and mine.text._color[2] == 1 and mine.text._color[3] == 1, "a blow on you: white with a minus, about at your feet")
    W.Fire("UNIT_COMBAT", "player", "WOUND", "", 42, 32)
    check(you.numbers[2].text._color[1] == 1 and you.numbers[2].text._color[2] == 0.1, "a spell on you (shadow): red")
    W.Fire("UNIT_COMBAT", "player", "WOUND", "", 42, 33)
    check(you.numbers[3].text._color[2] == 0.1, "physical and a spell school at once: red")
    W.Fire("UNIT_COMBAT", "player", "DODGE", "", 0, 1)
    check(you.numbers[4].picture._texture == CombatText.ART .. "dodge", "your dodge: its drawing")
    Core.Set(ns.name, "combatSelf", false)
    W.Fire("UNIT_COMBAT", "player", "WOUND", "", 42, 1)
    check(#you.numbers == 0 and CVar("enableFloatingCombatText") == "1", "over your character off: none, the game's text about you back")
    Core.Set(ns.name, "combatSelf", true)
    Core.Set(ns.name, "combatGame", false)
    check(CVar("floatingCombatTextCombatDamage_v2") == "1" and CVar("enableFloatingCombatText") == "1", "Instead of the game's off: both of the game's back")
    Core.Set(ns.name, "combatGame", true)
    W.combat = true
    Core.Set(ns.name, "combatGame", false)
    check(CVar("enableFloatingCombatText") == "0", "in a fight no CVar is set")
    W.combat = false
    W.Fire("PLAYER_REGEN_ENABLED")
    check(CVar("enableFloatingCombatText") == "1", "the fight over: set")
    Core.Set(ns.name, "combatGame", true)
    -- Something else turns the game's heal numbers back on (a profile's settings, the game's stored ones): ours again.
    C_CVar.SetCVar("floatingCombatTextCombatHealing_v2", "1")
    W.Fire("CVAR_UPDATE", "floatingCombatTextCombatHealing_v2", "1")
    check(CVar("floatingCombatTextCombatHealing_v2") == "1", "not at once")
    W.Wait(CombatText.AGAIN + 0.1)
    check(CVar("floatingCombatTextCombatHealing_v2") == "0", "a little later the game's heal numbers are off again")
    C_CVar.SetCVar("floatingCombatTextCombatDamage_v2", "1")
    W.Fire("PLAYER_ENTERING_WORLD")
    W.Wait(CombatText.AGAIN + 0.1)
    check(CVar("floatingCombatTextCombatDamage_v2") == "0", "after entering the world, set once more")
    -- The game about to write its settings: what was there before ours goes back, so the profiles keep their own.
    C_CVar.SetCVar("floatingCombatTextCombatHealing_v2", "1")
    C_CVar.SetCVar("enableFloatingCombatText", "1")
    Core.Set(ns.name, "combatText", false)
    Core.Set(ns.name, "combatText", true) -- found anew: the healing CVar at 1
    C_CVar.SetCVar("floatingCombatTextCombatHealing_v2", "0")
    ns.OnLogout()
    check(CVar("floatingCombatTextCombatHealing_v2") == "1" and CVar("floatingCombatTextCombatDamage_v2") == "1"
        and next(ns.options.combatFoundCVars) == nil, "at the logout the values found before ours go back, nothing kept")
    C_CVar.SetCVar("floatingCombatTextCombatDamage_v2", "0") -- the player's own choice, after it
    Core.Set(ns.name, "combatGame", false)
    check(CVar("floatingCombatTextCombatDamage_v2") == "0", "after that, switched off: left alone")
    Core.Set(ns.name, "combatGame", true)
    -- A value of yours that is already ours (the numbers over units off): found as it is, and yours again at the
    -- logout, not the game's default.
    check(ns.options.combatFoundCVars.floatingCombatTextCombatDamage_v2 == "0", "ours again: a value of yours already at ours is found too")
    ns.OnLogout()
    check(CVar("floatingCombatTextCombatDamage_v2") == "0" and CVar("floatingCombatTextCombatHealing_v2") == "1",
        "at the logout it stays yours, not the game's default")
    C_CVar.SetCVar("floatingCombatTextCombatDamage_v2", "1")
    Core.Set(ns.name, "combatGame", false)
    Core.Set(ns.name, "combatGame", true) -- ours again, as at the next login, the game's own found
    check(CVar("floatingCombatTextCombatDamage_v2") == "0" and ns.options.combatFoundCVars.floatingCombatTextCombatDamage_v2 == "1",
        "(ours again)")
    Core.Set(ns.name, "combatPictures", false)

    -- A school the game hides, as the game has it: written into a text it stays hidden, and nothing else works on it.
    local hidden = {}
    local function Hidden(value) return setmetatable({ secret = true, value = value }, hidden) end
    local function Open(value)
        if type(value) == "table" and value.secret then return value.value, true end
        return value, false
    end
    hidden.__concat = function(a, b) return Hidden(Open(a) .. Open(b)) end
    hidden.__lt = function() error("a hidden value compared") end
    hidden.__eq = hidden.__lt
    local format, abbreviate = string.format, AbbreviateNumbers
    string.format = function(form, ...)
        local values, told = { ... }, false
        for index = 1, select("#", ...) do
            local value, secret = Open(values[index])
            values[index], told = value, told or secret
        end
        local text = format(form, unpack(values, 1, select("#", ...)))
        return told and Hidden(text) or text
    end
    AbbreviateNumbers = function(value) return value end
    local function Written(host) return host.numbers[#host.numbers].text._text[1].value end
    CombatText.Clear(dress)
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", Hidden("1.2k"), Hidden(1))
    check(Written(dress) == "|cffffffff1.2k|r", "a hidden school, physical: white")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 900, Hidden(8))
    check(Written(dress) == "|cffff0000900|r" and dress.numbers[#dress.numbers].text._color[2] == 1,
        "a hidden school, a spell (nature): red, in the text")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "CRITICAL", 900, Hidden(4))
    check(dress.numbers[#dress.numbers].text._font[2] == CombatText.HEIGHT * CombatText.CRIT, "a hidden school loses nothing of a critical hit")
    W.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "BLOCK_REDUCED", 900, Hidden(4))
    check(Written(dress) == "|cffff0000" .. Core.Word("COMBAT_TEXT_BLOCK_REDUCED", "%s (blocked)"):format("900") .. "|r",
        "a blow partly blocked: its form inside the colour")
    local reds = true
    for mask = 2, 127 do
        local red = CombatText.Hued("%s", "9", Hidden(mask)).value
        reds = reds and red:find("^|cffff[01]%x[01]%x9|r$") ~= nil
    end
    check(reds and CombatText.Hued("%s", "9", Hidden(1)).value == "|cffffffff9|r", "every spell school red, physical alone white")
    check(CombatText.Hued("%s", "9", Hidden(0)).value:find("^|cffff%x%x%x%x9|r$") ~= nil, "no school told: still a whole colour, not a broken one")
    W.Fire("UNIT_COMBAT", "nameplate1", Hidden("WOUND"), Hidden(""), Hidden("7"), Hidden(32))
    check(Written(dress) == "|cffff00007|r", "the kind hidden too, over a foe: damage, by its school")
    -- The game raises on a boolean test of a hidden value; the stand-in cannot, but a hidden value that is false
    -- shows one (an and/or would drop it for the physical school): the school goes on as it came.
    local secret, hued, given = issecretvalue, CombatText.Hued, nil
    issecretvalue = function(value) return value == false or secret(value) end
    CombatText.Hued = function(form, value, school) given = school return hued(form, value, school) end
    W.Fire("UNIT_COMBAT", "nameplate1", Hidden("WOUND"), Hidden(""), Hidden("7"), false)
    issecretvalue, CombatText.Hued = secret, hued
    check(given == false, "a hidden kind's school meets no boolean test: handed on as it came")
    local kept = units.nameplate1
    units.nameplate1 = { friend = true }
    CombatText.Clear(dress)
    W.Fire("UNIT_COMBAT", "nameplate1", Hidden("HEAL"), Hidden(""), Hidden("7"), Hidden(32))
    check(dress.numbers[1].text._text[1].value == "7" and dress.numbers[1].text._color[2] == 1, "over a friend it may be a heal: white")
    units.nameplate1 = kept
    W.Fire("UNIT_COMBAT", "player", Hidden("HEAL"), Hidden(""), Hidden("7"), Hidden(32))
    local yours
    for _, frame in ipairs(W.frames) do
        if frame.numbers and frame ~= dress and frame.numbers[1] then yours = frame end
    end
    check(Written(yours) == "7" and yours.numbers[#yours.numbers].text._color[2] == 1, "over your character too")
    W.Fire("UNIT_COMBAT", "player", "WOUND", "", 42, Hidden(32))
    check(Written(yours) == "|cffff0000-42|r", "a hidden spell on you: red, with its minus")
    string.format, AbbreviateNumbers = format, abbreviate
    CombatText.Clear(dress)
    CombatText.Clear(yours)
end)()

-------------------------------------------------------------------------------
--  A unit's cast: under its bar, as high, the seconds in the icon, the spell and its target cut to fit
-------------------------------------------------------------------------------
local Cast = ns.Cast
local castBar = dress.cast
local gameCast = plates.nameplate1.UnitFrame.CastBarsContainer
-- How far a status bar is filled, as a share.
local function Share(bar) return (bar._value - bar._min) / (bar._max - bar._min) end
casts.nameplate1 = { name = "Fireball", icon = 135812, starts = (W.clock - 1) * 1000, ends = (W.clock + 2) * 1000, target = "Bran Stoneheart" }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(castBar:IsShown() and castBar._points[1][2] == dress and castBar._points[1][3] == "BOTTOMLEFT" and castBar._points[1][5] == 0,
    "a cast: under the bar, no gap")
check(castBar._height == dress._height and castBar.icon._width == castBar.icon._height and castBar.icon._width < castBar._height,
    "as high as the bar, its icon square inside its border")
check(castBar.icon._texture == 135812 and castBar.text._text == "Fireball  Bran Stoneheart" and (castBar.text._width or 0) == 0
    and castBar.text._points[2][3] == "RIGHT", "the spell's icon; its name, then its target's, cut where the bar ends")
local function Atlas(bar) return bar._barTexture end
check(Atlas(castBar.fill) == Cast.ART.cast and castBar.fill._min == casts.nameplate1.starts and castBar.fill._max == casts.nameplate1.ends
    and Near(Share(castBar.fill), 1 / 3) and castBar.timer._text == "2.0" and castBar.lock._alpha == 0,
    "from its start to its end, a third done, two seconds left in the icon, in the game's golden cast art")
check(dress.border[2]._points[1][2] == castBar and dress.halo[1][2]._points[1][2] == castBar and dress.rankLine[2]._points[1][2] == castBar
    and Near(dress.border[1].corners[1]._width, dress._height * Bar.CAP) and Near(dress.border[2]._height, dress._height),
    "one outline, glow and rank line around the bar and the cast bar, as round as around the bar alone")
check(dress.health._points[2][5] == 0 and dress.caps[1]._texture == Core.Shape.CORNER.TOPLEFT
    and dress.caps[2]._texture == Core.Shape.CORNER.TOPRIGHT, "the bar down to the cast bar, round only at its top: nothing between them")
local inner = dress._height * Bar.CAP - Core.Pixels(dress, 1)
check(castBar.caps[1]._texture == Bar.WHITE and castBar.caps[2]._texture == Core.Shape.CORNER.BOTTOMRIGHT
    and Near(castBar.caps[2]._width, inner) and castBar.corner._texture == Core.Shape.CORNER.BOTTOMLEFT and Near(castBar.corner._width, inner),
    "the cast bar round only at its bottom: the icon's left corner, the fill's right one, a pixel less than the outline")
check(castBar.timer._points[1][2] == castBar.icon, "the seconds inside the icon")
check(gameCast._alpha == 0, "the game's own cast bar out of sight under ours")
W.clock = W.clock + 1
castBar:GetScript("OnUpdate")(castBar, 1)
check(Near(Share(castBar.fill), 2 / 3) and castBar.timer._text == "1.0", "on its way: two thirds, a second left")
W.clock = W.clock + 1.1
castBar:GetScript("OnUpdate")(castBar, 1.1)
check(castBar:IsShown() and Share(castBar.fill) == 1 and castBar.timer._text == "", "done: full, no seconds, still there")
W.clock = W.clock + Cast.HOLD
castBar:GetScript("OnUpdate")(castBar, Cast.HOLD)
check(not castBar:IsShown(), "half a second later: gone")
casts.nameplate1 = { name = "Drain Life", channel = true, locked = true, starts = W.clock * 1000, ends = (W.clock + 4) * 1000 }
W.Fire("UNIT_SPELLCAST_CHANNEL_START", "nameplate1")
check(castBar:IsShown() and castBar.fill._reverse and castBar.background._atlas == Cast.ART.channel and castBar.lock._alpha == 1
    and castBar.lockBack._atlas == Cast.ART.locked and Share(castBar.fill) == 0 and castBar.text._text == "Drain Life",
    "a channel that cannot be interrupted: grey over it, emptying from its end; no target")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_CHANNEL_STOP", "nameplate1")
check(castBar:IsShown() and Share(castBar.fill) == 1 and castBar.fill._reverse, "the channel ended: empty, staying")
W.clock = W.clock + Cast.HOLD + 0.1
castBar:GetScript("OnUpdate")(castBar, 0.5)
check(not castBar:IsShown(), "then gone")
-- Interrupted: full and red, saying so and by whom, for half a second.
casts.nameplate1 = { name = "Fireball", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(Atlas(castBar.fill) == Cast.ART.cast and not castBar.fill._reverse and castBar.lock._alpha == 0, "an interruptible cast: golden")
UnitTokenFromGUID = function(guid) return guid == "Player-party1" and "party1" or nil end
local unitName = UnitName
UnitName = function(unit) if unit == "party1" then return "Bran" end return unitName(unit) end
W.Fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate1", "cast", 133, "Player-party1")
check(Atlas(castBar.fill) == Cast.ART.broken and Share(castBar.fill) == 1 and castBar.text._text == Cast.INTERRUPTED .. ": Bran",
    "interrupted: full and red, saying so, and by whom")
UnitName = unitName
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_STOP", "nameplate1")
check(castBar:IsShown() and Atlas(castBar.fill) == Cast.ART.broken, "its stop after: still red")
W.clock = W.clock + Cast.HOLD + 0.01
castBar:GetScript("OnUpdate")(castBar, 1)
check(not castBar:IsShown(), "gone after half a second")
check(dress.border[2]._points[1][2] == dress and Near(dress.border[1].corners[1]._width, dress._height * Bar.CAP),
    "no cast: the outline around the bar alone again")
check(dress.health._points[2][5] == Core.Pixels(dress, 1) and dress.caps[1]._texture == Core.Shape.CAP_LEFT,
    "and the bar a pixel inside it all round, round at both ends")
-- Interrupted by someone with no unit token (not in your group): named by what the game knows of the player by GUID.
casts.nameplate1 = { name = "Fireball", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
local playerInfo = rawget(_G, "GetPlayerInfoByGUID")
GetPlayerInfoByGUID = function(guid)
    if guid == "Player-far" then return "Mage", "MAGE", "Gnome", "Gnome", 2, "Fizzle", "Realm", 20 end
end
W.Fire("UNIT_SPELLCAST_INTERRUPTED", "nameplate1", "cast", 133, "Player-far")
check(castBar.text._text == Cast.INTERRUPTED .. ": Fizzle", "interrupted by someone without a unit token: named by the game's player info")
rawset(_G, "GetPlayerInfoByGUID", playerInfo)
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_STOP", "nameplate1")
W.clock = W.clock + Cast.HOLD + 0.01
castBar:GetScript("OnUpdate")(castBar, 1)
check(not castBar:IsShown(), "(gone)")
-- Stopped early by the game (cast done): stays half a second; failed: at once.
casts.nameplate1 = { name = "Frostbolt", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_STOP", "nameplate1")
check(castBar:IsShown() and Share(castBar.fill) == 1, "stopped: done, full, staying")
casts.nameplate1 = { name = "Frostbolt", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(castBar:IsShown() and Share(castBar.fill) < 1, "a new cast at once: shown from its start")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_FAILED", "nameplate1")
check(not castBar:IsShown(), "failed: gone at once")
-- Its times and its lock hidden from addons: ours all the same, the game drawing its progress; the seconds reckoned.
C_Spell.GetSpellInfo = function(id) if id == 133 then return { castTime = 2500 } end return { minRange = 0, maxRange = 5 } end
local starts, ends, lockedHidden = Secret(), Secret(), Secret()
casts.nameplate1 = { name = Secret(), icon = Secret(), starts = starts, ends = ends, locked = lockedHidden }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(castBar:IsShown() and gameCast._alpha == 0 and castBar.fill._min == starts and castBar.fill._max == ends
    and castBar.fill._value == W.clock * 1000, "its times hidden: ours, from its start to its end as the game has them")
check(type(castBar.lock._alpha) == "table" and castBar.lock._alpha.from == lockedHidden, "whether it can be interrupted: as the game says, hidden")
check(castBar.timer._text == "2.5", "the seconds reckoned from the spell's cast time")
W.clock = W.clock + 2.5 + Cast.WAIT + 0.1
castBar:GetScript("OnUpdate")(castBar, 0.1)
check(castBar.cast.held, "no word from the game long past its reckoned end: done all the same")
casts.nameplate1 = nil
W.clock = W.clock + Cast.HOLD + 0.1
castBar:GetScript("OnUpdate")(castBar, 0.1)
casts.nameplate1 = { name = "Frostbolt", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
Core.Set(ns.name, "castBar", false)
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(not castBar:IsShown() and gameCast._alpha == 1, "the setting off: the game's own cast bar")
W.Fire("PLAYER_TARGET_CHANGED") -- every plate worn anew
check(gameCast._alpha == 1, "and it stays in sight as the plates are worn anew (a change of target)")
Core.Set(ns.name, "castBar", true)
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(castBar:IsShown() and gameCast._alpha == 0, "on again: ours")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_FAILED", "nameplate1")
check(not castBar:IsShown(), "failed: gone")
-- A cast beginning while the game shows the plate by name only (its bar gone, ours away): ours drawn under the hidden
-- dress, where no OnShow runs (the game runs none under a hidden parent); the game's bar back: the dress shown runs
-- the cast bar's OnShow with it, and the one outline goes around both.
local shows, outlined = 0, dress.outlined
castBar:HookScript("OnShow", function() shows = shows + 1 end)
bar:Hide()
casts.nameplate1 = { name = "Frostbolt", starts = W.clock * 1000, ends = (W.clock + 3) * 1000 }
W.Fire("UNIT_SPELLCAST_START", "nameplate1")
check(not dress:IsShown() and castBar:IsShown() and not castBar:IsVisible() and shows == 0 and dress.outlined == outlined,
    "a cast while the plate is by name only: ours under the hidden dress, no OnShow, the outline as it was")
bar:Show()
check(dress:IsShown() and shows == 1 and dress.outlined == castBar and dress.border[2]._points[1][2] == castBar,
    "the game's bar back: the dress shown runs the cast bar's OnShow with it, one outline around both")
casts.nameplate1 = nil
W.Fire("UNIT_SPELLCAST_FAILED", "nameplate1")
check(not castBar:IsShown() and dress.outlined == outlined, "failed: gone, the outline as before")

-------------------------------------------------------------------------------
--  Retail: what it lacks of Forever's hidden, a plate dressed and filled as in Forever
-------------------------------------------------------------------------------
do
    W.Play("retail")
    local before = 0
    for _ in pairs(Core.errors) do before = before + 1 end
    units.nameplate5 = { name = "Kobold Miner", health = 30, most = 60, reaction = 2, level = 12 }
    plates.nameplate5 = GamePlate()
    W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate5")
    local miner = DressOf(plates.nameplate5)
    check(miner and miner:IsShown() and Faded(plates.nameplate5, 0) and miner.name._text == "Kobold Miner"
        and miner.level._text == "12" and miner.health._value == 30, "Retail: the plate dressed and filled")
    units.nameplate5.health = 20
    W.Fire("UNIT_HEALTH", "nameplate5")
    W.Fire("UNIT_COMBAT", "nameplate5", "WOUND", "", 10, 1)
    check(miner.health._value == 20 and #miner.numbers == 1, "Retail: its health followed, what it took rising over it")
    W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate5")
    check(not miner:IsShown() and Faded(plates.nameplate5, 1), "Retail: taken back, the game's own again")
    local after = 0
    for _ in pairs(Core.errors) do after = after + 1 end
    check(after == before and not ns.off, "Retail: no error noted, nothing stood down")
    units.nameplate5, plates.nameplate5 = nil, nil
    W.Play("forever")
end

-------------------------------------------------------------------------------
--  Plates going, plates the game keeps, standing down
-------------------------------------------------------------------------------
W.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
check(not friend:IsShown() and Faded(plates.nameplate2, 1) and friend.unit == nil and next(friend._events) == nil,
    "the plate taken back: ours off, the game's parts in sight again, nothing listened to")
check(friend.own._unit == "none" and friend.name._text == "" and friend.value._text == "", "its containers and texts let go of the unit")
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
plates.nameplate2.UnitFrame:SetAlpha(0)
dress.own.SetUnit = function() error("the game's container changed") end
ns.StandDown("a test")
check(ns.off and not dress:IsShown() and not friend:IsShown() and Faded(plates.nameplate1, 1) and Faded(plates.nameplate2, 1)
    and plates.nameplate2.UnitFrame._alpha == 1, "standing down, every plate is the game's own again, though a step of ours failed")
check(Core.errors["Nameplates: auras"] ~= nil, "the step that failed is noted")
check(gameAuras.icons[1]:IsMouseEnabled() and gameAuras.icons[3]:IsMouseEnabled()
    and gameAuras.LossOfControlFrame.AuraItemFrame:IsMouseEnabled(), "the game's aura icons with the mouse again")
gameAuras:RefreshList(1)
check(gameAuras.icons[4]:IsMouseEnabled(), "and the hook on the game's refresh does nothing any more")
check(C_CVar.GetCVar("nameplateSelectedScale") == "1.2" and plates.nameplate1.UnitFrame._scale == 1,
    "the game's scaling by distance its own again, its unit frames at their own scale")
check(C_CVar.GetCVar("floatingCombatTextCombatDamage_v2") == "1" and C_CVar.GetCVar("enableFloatingCombatText") == "1",
    "the game's combat text back")
bar:Hide()
bar:Show()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "after that, nothing is dressed")

io.write(("Nameplates: all %d checks passed.\n"):format(passed))
