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

-- A hidden value of the game's: a table here, never compared.
issecretvalue = function(value) return type(value) == "table" and value.secret == true end
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
UnitIsFriend = function(_, unit) return Unit(unit).friend or false end
UnitCanAttack = function(a, b)
    if a == "player" then return not Unit(b).friend end
    return not Unit(a).friend and Unit(a).player == true -- a player who may attack you
end
UnitReaction = function(unit) return Unit(unit).reaction or 2 end
UnitIsBossMob = function(unit) return Unit(unit).boss or false end
UnitLevel = function(unit) if unit == "player" then return 20 end return Unit(unit).level end
UnitIsUnit = function(a, b) return b == "target" and plates[a] ~= nil and plates[a] == plates.target end
UnitInParty = function(unit) return Unit(unit).party or false end
UnitInRaid = function() return nil end
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
local power, combo = 3, 2
UnitPowerType = function(unit)
    if unit == "player" then return power end
    return 0, Unit(unit).powerToken
end
UnitPowerMax = function(unit, kind)
    if unit == "player" then return kind == Enum.PowerType.ComboPoints and 5 or 100 end
    return Unit(unit).powerMost or 0
end
UnitPower = function(unit) return Unit(unit).powerNow end
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
    frame.HealthBarsContainer:SetSize(120, 20)
    frame.HealthBarsContainer.healthBar = W.NewWidget("StatusBar", nil, frame.HealthBarsContainer)
    for _, key in ipairs({ "AurasFrame", "RaidTargetFrame", "ClassificationFrame", "PlayerLevelDiffFrame", "LevelFrame" }) do
        frame[key] = W.NewWidget("Frame", nil, frame)
    end
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
                             enableFloatingCombatText = "1" }) do
    W.cvarInfo[name] = { default = default }
end
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Nameplates", "SaneUI_Nameplates")
W.Fire("ADDON_LOADED", "SaneUI_Nameplates")
W.Fire("PLAYER_LOGIN")
local Core = SaneUI.Core
local Bar, Auras, Resource, Text, Scale = ns.Bar, ns.Auras, ns.Resource, ns.Text, ns.Scale

check(Bar.FOCUS[2] == 0.49 and Bar.TARGET[1] == 1, "the border's colours for your target and focus are the game's")
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
local function L(letters) return letters * 6 + Text.SLACK end -- a text's room: six a letter, and the slack
check(X(dress.level) == I and X(dress.name) == I + L(2) + G and X(dress.value) == I + L(2) + G + L(10) + G,
    "the level first, then the name, then the health")
check(Text.Guess("nameplate1") == "8.8k" and dress.room.value == L(11),
    "the most hidden: room for a guess from its level and rank (22, a rare: about 4k)")
check(dress.want == I + L(2) + G + L(10) + G + L(11) + I and dress._width == dress.want, "the bar as wide as its line, no wider")
check(dress.value._width == 0 and dress.name._width == L(10), "the health as wide as it is (never cut short), the others their room")
check(dress.now == 0 and dress.showing == 0 and dress._alpha == 0, "a plate that has just appeared: it springs in from nothing, unseen at first")
units.guess = { level = -1 }
check(Text.Guess("guess") == "8.88m", "a boss's in millions")
units.guess = { level = 30, player = true }
check(Text.Guess("guess") == "8.8k", "a player's about a hundred a level")
units.guess = { level = 8 }
check(Text.Guess("guess") == "888", "a low creature's under a thousand")
check(dress.rankLine:IsShown() and dress.rankLine._vertex[1] == 0.8 and dress.rank == Bar.RANKS.rare and dress.border._vertex[1] == 0,
    "a rare: a thin silver line behind the black border")
check(not dress.raid:IsShown(), "no raid marker")
check(dress.power:IsShown() and dress.power._value == 40 and dress.power._max == 100 and dress.power._barColor[3] == 1,
    "its mana along the bar's bottom, in the game's colour")
check(dress.glow._alpha == 0, "no glow")
-- What the glow's plates add up to in each band: those reaching it and beyond, laid over each other.
local function Solid(band)
    local clear = 1
    for outer = band, #dress.halo do clear = clear * (1 - dress.halo[outer]._vertex[4]) end
    return 1 - clear
end
local fading = #dress.halo == Bar.HALO and math.abs(Solid(1) - 1) < 1e-9 and dress.halo[1]._blend ~= "ADD"
for band = 2, #dress.halo do
    fading = fading and Solid(band) < Solid(band - 1) and math.abs(Solid(band) - Bar.Fade(band)) < 1e-9
end
check(fading and Solid(#dress.halo) < 0.05, "the glow: solid at the border, fading to almost nothing outwards")
check(dress.halo[1]._parent == dress.glow and dress.border._parent == dress.rankLine._parent
    and dress.glow._level < dress.border._parent._level and dress.border._parent._level < dress.health._level,
    "each layer on a frame of its own: the glow under the outline, the outline under the bar")
check(dress.border._vertex[1] == Bar.BORDER[1] and dress.border._vertex[4] == Bar.BORDER[4], "the border black: not your target")
check(dress.health:GetStatusBarTexture()._masks and #dress.health:GetStatusBarTexture()._masks == 2
    and #dress.background._masks == 2 and #dress.border._masks == 2 and #dress.power:GetStatusBarTexture()._masks == 2,
    "the fill, its background, the power line and the border each cut at both ends")
check(dress.caps[1]._texture == Core.Shape.CAP_LEFT and dress.caps[1]._wrap[1] == "CLAMPTOWHITE"
    and dress.caps[2]._texture == Core.Shape.CAP_RIGHT, "by Core's caps, white beyond them")

-- Its size: the caps a quarter of each height, the bar a pixel inside its border.
dress:GetScript("OnSizeChanged")(dress)
local edge = Core.Pixels(dress, 1)
check(dress.border.caps[1]._width == high * Bar.CAP and dress.caps[2]._width == (high - 2 * edge) * Bar.CAP,
    "each cap as wide as a quarter of what it rounds")
check(dress.health._points[1][4] == edge and dress.health._points[2][4] == -edge, "the bar a pixel inside its border")
check(dress.power._height == (high - 2 * edge) * Bar.LINE, "the power line a fifth of the bar's height")
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
check(dress.rank == Bar.RANKS.boss and dress.rankLine._vertex[2] == 0.82 and Reach(dress.rankLine) == 3 * edge
    and dress.health._points[1][4] == edge and Reach(dress.border) == 0,
    "a boss: a thick golden line behind the border, from the same edge; the bar where it was")
check(Reach(dress.halo[1]) == 4 * edge and Reach(dress.halo[#dress.halo]) == (3 + #dress.halo) * edge, "the glow beyond the line")
check(dress.level._text == Text.SKULL, "the skull for its level")
units.nameplate1.boss, units.nameplate1.classification = false, "elite"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.RANKS.elite and dress.rankLine._vertex[2] == 0.82 and Reach(dress.rankLine) == edge
    and Reach(dress.halo[1]) == 2 * edge, "an elite: a thin golden line, a pixel past the border")
units.nameplate1.classification = "normal"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.PLAIN and not dress.rankLine:IsShown() and Reach(dress.halo[1]) == edge, "a plain one: the border only")
units.nameplate1.level = 22
W.Fire("UNIT_LEVEL", "nameplate1")

-- Health and name as they change.
units.nameplate1.health, units.nameplate1.most = 1325000, 1325000
W.Fire("UNIT_HEALTH", "nameplate1")
check(dress.health._value == 1325000 and dress.value._text == "1.32m | 100%", "health followed, short, and its percent")
check(dress.room.value == L(12) and dress._width == I + L(2) + G + L(10) + G + L(12) + I, "its room the most it shows: the bar narrower")
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
check(dress.name._text == units.nameplate1.name and dress.room.name == L(10), "a hidden name goes to the text as it is, in the room of the last")
units.nameplate1.name = "Archmage Ataeric the Unforgiving of the Blue Dragonflight"
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
check(dress.room.name == L(#units.nameplate1.name) and dress.name._width == dress.room.name and dress._width == dress.want,
    "a long name: all of its room, the bar longer for it")
units.nameplate1.name = "Young Wolf"
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
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
for _, layer in ipairs(dress.halo) do untouched = untouched and layer._alpha == 1 end
check(untouched, "switched by its frame's alpha: the layers' own strengths never overwritten")
local hidden = Secret()
units.nameplate1.threat = { hidden, Secret(), Secret() }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(type(dress.glow._alpha) == "table" and dress.glow._alpha.from == hidden and dress.glow._alpha.yes == nil,
    "a hidden answer: the glow takes it as it is, never compared, with the game's own alphas")
units.nameplate1.threat = nil
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._text == "" and dress.glow._alpha == 0 and dress.room.threat == nil and X(dress.name) == I + L(2) + G,
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
check(dress._width == dress.want and dress.room.name == L(10), "the world shown: every plate measured anew, right")

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

-------------------------------------------------------------------------------
--  A friend shown by name only, players, the raid marker, the border lit
-------------------------------------------------------------------------------
local bar = plates.nameplate1.UnitFrame.HealthBarsContainer.healthBar
bar:Hide() -- the game shows the plate by name only now
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "the game's health bar gone: its own plate as it is, ours away")
bar:Show()
check(dress:IsShown() and Faded(plates.nameplate1, 0), "back")

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
check(friend.gear._text == "i32" and X(friend.gear) == X(friend.level) + L(2) + G and X(friend.name) == X(friend.gear) + L(3) + G,
    "the answer: i32 between the level and the name")
Core.Set(ns.name, "gear", false)
check(friend.room.gear == nil and friend.gear._text == "", "the setting off: none, no room")
Core.Set(ns.name, "gear", true)
check(friend.gear._text == "i32", "on again: from what was kept")
check(friend.level._color[1] == 0.3, "the level of someone you cannot attack in the game's colour for that")
check(not friend.foes:IsShown() and friend.own:IsShown(), "no buffs on someone you cannot attack")
check(friend.raid:IsShown() and friend.raid._cell[1] == 8 and friend.raid._cell[2] == 4 and friend.raid._cell[3] == 4,
    "a raid marker: the game's icon at its index")
check(friend.raid._points[1][1] == "RIGHT" and X(friend.raid) == -Text.OUTSIDE and X(friend.level) == I
    and friend.control._points[1][2] == friend, "left of the bar, outside it; the line inside unmoved; the crowd control right")
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
Core.Set(ns.name, "players", false)
check(friend:IsShown(), "the setting off: every player's plate")
Core.Set(ns.name, "players", true)
units.target, plates.target = units.nameplate2, plates.nameplate2
W.Fire("PLAYER_TARGET_CHANGED")
check(friend:IsShown() and friend.border._vertex[1] == 1 and friend.border._vertex[4] == 1 and dress.border._vertex[1] == 0,
    "your target: shown, its border white, the others' black")
units.focus, plates.focus = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_FOCUS_CHANGED")
check(dress.border._vertex[2] == 0.49, "your focus's border in the game's colour for it")
units.nameplate2.friend, units.nameplate2.raid = false, 8
W.Fire("UNIT_FACTION", "nameplate2")
check(friend:IsShown() and friend.glow._alpha == 1, "a player who may attack you: shown, glowing")
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown(), "and no raid marker, as on the game's plates")
units.nameplate2.friend, units.nameplate2.party = true, true
W.Fire("UNIT_FACTION", "nameplate2")
check(friend.glow._alpha == 0, "a friend again: no glow")

-------------------------------------------------------------------------------
--  Combo points in your target's bar
-------------------------------------------------------------------------------
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
check(strip._points[1][2] == dress.power and strip._points[1][3] == "TOPLEFT" and strip._height == dress.line,
    "right on top of the power line, as high as it")
check(#strip.segments[1]:GetStatusBarTexture()._masks == 2 and strip.segments[5]:GetStatusBarTexture()._masks[2] == dress.caps[2],
    "the outer corners the bar's own")
check(strip.segments[1]._points[2][4] < strip.segments[2]._points[1][4] and strip.segments[1]._points[1][4] == 0,
    "a pixel apart, the first from the strip's left")
local function Backgrounds(frame)
    local count = 0
    for _, widget in ipairs(W.frames) do
        if widget._parent == frame and widget ~= frame._fill and widget:GetObjectType() == "Texture" then count = count + 1 end
    end
    return count
end
check(Backgrounds(dress.health) == 1 and Backgrounds(dress.power) == 0 and Backgrounds(strip) == 0 and Backgrounds(strip.segments[1]) == 0,
    "no background behind the power line or the points: empty shows nothing")
units.nameplate1.powerMost = 0
W.Fire("UNIT_MAXPOWER", "nameplate1")
W.Wait(0)
check(strip._points[1][2] == dress.health and strip._points[1][3] == "BOTTOMLEFT", "no power line: along the bar's bottom")
units.nameplate1.powerMost = 100
W.Fire("UNIT_MAXPOWER", "nameplate1")
W.Wait(0)
combo = Secret()
W.Fire("UNIT_POWER_UPDATE", "player", "COMBO_POINTS")
W.Wait(0)
check(strip.segments[1]._value == combo and strip.segments[5]._value == combo, "a hidden count goes to every segment as it is")
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
-- Walking away: the plate follows evenly, never past its size, the same pace all the way.
yards.nameplate1 = 22
local even, last, steps = true, dress._scale, {}
for _ = 1, 500 do
    tick(Scale.driver, 0.02)
    if dress._scale > last + 1e-9 then even = false end
    if dress._scale ~= last then steps[#steps + 1] = last - dress._scale end
    last = dress._scale
end
check(even and Near(dress._scale, full * Scale.Size(20)) and #steps > 10 and Near(steps[2], steps[5])
    and Near(steps[2], full * Scale.SPEED * 0.02), "22 yards (past the 20 yard rung): smaller evenly, at its pace, never past its size")
yards.nameplate1 = 27
Settle()
check(Near(dress._scale, full * Scale.Size(25)), "27 yards: past the 25 yard rung, so at 25 for sure")
check(Near(dress.edge, Core.Pixels(dress, 1)) and dress.fitted == dress.now,
    "settled at its size: laid out anew, the border one screen pixel at it")
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
check(dress.border._vertex[1] == 1 and dress.border._vertex[2] == 1, "the shot reaches it: your target's border white")
yards.nameplate1 = 38
Settle()
check(dress.out == true and dress.border._vertex[2] == Bar.FAR[2] and Near(dress._scale, full),
    "38 yards: out of reach of all your attacks, red; your target still full size")
units.target, plates.target = nil, nil
W.Fire("PLAYER_TARGET_CHANGED")
check(dress.border._vertex[2] == Bar.FAR[2], "not your target, still out of reach: red over the black")
yards.nameplate1 = 3
Settle()
check(dress.out == false and dress.border._vertex[1] == Bar.BORDER[1], "in reach of the strike: black again")
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
check(dress.out == false and dress.border._vertex[1] == Bar.BORDER[1], "the red border switched off: black")
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
Core.Set(ns.name, "distance", true)
check(CVar("nameplateSelectedScale") == "1", "on again")

-------------------------------------------------------------------------------
--  Combat text over a plate and over your character
-------------------------------------------------------------------------------
;(function()
    local CombatText = ns.CombatText
    check(CVar("floatingCombatTextCombatDamage_v2") == "0" and CVar("floatingCombatTextCombatHealing_v2") == "0"
        and CVar("enableFloatingCombatText") == "0", "the game's own combat text off while ours shows")
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
end)()

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
check(C_CVar.GetCVar("nameplateSelectedScale") == "1.2" and plates.nameplate1.UnitFrame._scale == 1,
    "the game's scaling by distance its own again, its unit frames at their own scale")
check(C_CVar.GetCVar("floatingCombatTextCombatDamage_v2") == "1" and C_CVar.GetCVar("enableFloatingCombatText") == "1",
    "the game's combat text back")
bar:Hide()
bar:Show()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "after that, nothing is dressed")

io.write(("Nameplates: all %d checks passed.\n"):format(passed))
