-- Runs the Nameplates module against the stand-in client (wowstub.lua): our dress on the game's plates as the
-- game shows and takes them back, the game's parts out of sight under it and back, a plate shown by name only,
-- the bar's health (hidden values passed on untouched), colours, the border by rank, the ring on your target and
-- focus, the glow, the power line, the texts inside the bar (level, threat, name, health), the raid marker, the
-- aura containers around the bar, the combo points on your target's bar, strangers' plates out of sight, the
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
function methods:SetTexture(file, wrapH, wrapV) self._texture, self._wrap = file, { wrapH, wrapV } end
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
                             nameplateMinScaleDistance = "10", nameplateSelectedScale = "1.2", nameplateMaxDistance = "1000" }) do
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
check(dress._points[1][2] == plates.nameplate1.UnitFrame.HealthBarsContainer and dress._points[2][2] == plates.nameplate1.UnitFrame.HealthBarsContainer,
    "laid exactly over the game's health bar row")
check(dress.health._value == wolf and dress.health._max == units.nameplate1.most, "hidden health goes to the bar as the game gives it")
check(dress.health._barColor[1] == 1 and dress.health._barColor[2] == 0, "a creature that attacks on sight: red")
check(dress.name._text == "Young Wolf", "its name inside the bar")
check(dress.name._points[1][1] == "CENTER", "in the bar's middle")
check(dress.level._text == 22 and dress.level._color[2] == 1, "its level at the left, in the game's colour for it")
check(dress.level._points[1][1] == "LEFT" and dress.threat._points[1][2] == dress.level, "the threat next to the level")
check(dress.threat._text == "", "no threat while you are not on its list")
check(type(dress.value._text) == "table" and dress.value._text.form == "%s | %d%%", "hidden health: the game's abbreviation and percent")
check(dress.value._points[1][1] == "RIGHT", "health at the right")
check(dress.border._vertex[1] == 0.8 and dress.rank == Bar.RANKS.rare, "a rare: a thin silver border")
check(not dress.raid:IsShown(), "no raid marker")
check(dress.power:IsShown() and dress.power._value == 40 and dress.power._max == 100 and dress.power._barColor[3] == 1,
    "its mana along the bar's bottom, in the game's colour")
check(dress.halo[1]._alpha == 0, "no glow")
local fading = #dress.halo == #Bar.HALO and #dress.halo >= 5
for index, glow in ipairs(dress.halo) do
    fading = fading and glow._blend == "ADD" and (index == 1 or glow._vertex[4] < dress.halo[index - 1]._vertex[4])
end
check(fading, "the glow: thin layers, each fainter outwards, added light")
check(not dress.ring:IsShown(), "no ring: not your target")
check(dress.health:GetStatusBarTexture()._masks and #dress.health:GetStatusBarTexture()._masks == 2
    and #dress.background._masks == 2 and #dress.border._masks == 2 and #dress.power:GetStatusBarTexture()._masks == 2,
    "the fill, its background, the power line and the border each cut at both ends")
check(dress.caps[1]._texture == Core.Shape.CAP_LEFT and dress.caps[1]._wrap[1] == "CLAMPTOWHITE"
    and dress.caps[2]._texture == Core.Shape.CAP_RIGHT, "by Core's caps, white beyond them")

-- Its size: the caps a quarter of each height, the bar a pixel inside its border.
dress:SetSize(190, 20)
dress:GetScript("OnSizeChanged")(dress)
local edge = Core.Pixels(dress, 1)
check(dress.border.caps[1]._width == 20 * Bar.CAP and dress.caps[2]._width == (20 - 2 * edge) * Bar.CAP,
    "each cap as wide as a quarter of what it rounds")
check(dress.health._points[1][4] == edge and dress.health._points[2][4] == -edge, "the bar a pixel inside its border")
check(dress.power._height == (20 - 2 * edge) * Bar.LINE, "the power line a fifth of the bar's height")
check(dress.name._width == 190 * Text.NAME, "the name's room")

-- A boss: a thick golden border, the bar further in; a level too high to tell: the skull.
units.nameplate1.boss, units.nameplate1.level = true, -1
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
W.Fire("UNIT_LEVEL", "nameplate1")
check(dress.rank == Bar.RANKS.boss and dress.border._vertex[2] == 0.82 and dress.health._points[1][4] == 3 * edge,
    "a boss: thick and golden")
check(dress.level._text == Text.SKULL, "the skull for its level")
units.nameplate1.boss, units.nameplate1.classification = false, "elite"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.RANKS.elite and dress.border._vertex[2] == 0.82 and dress.health._points[1][4] == edge, "an elite: thin and golden")
units.nameplate1.classification = "normal"
W.Fire("UNIT_CLASSIFICATION_CHANGED", "nameplate1")
check(dress.rank == Bar.PLAIN and dress.border._vertex[1] == 0, "a plain one: black")

-- Health and name as they change.
units.nameplate1.health, units.nameplate1.most = 1325000, 1325000
W.Fire("UNIT_HEALTH", "nameplate1")
check(dress.health._value == 1325000 and dress.value._text == "1.32m | 100%", "health followed, short, and its percent")
check(Text.Short(850) == "850" and Text.Short(1250) == "1.2k" and Text.Short(12999) == "12.9k" and Text.Short(1000) == "1k"
    and Text.Short(2000000) == "2m" and Text.Short(1329999) == "1.32m" and Text.Short(1300000) == "1.3m",
    "under a thousand as it is, then thousands to one place, then millions to two, cut, no zeros at the end")
check(Text.Percent(1, 1000) == 1 and Text.Percent(999, 1000) == 99 and Text.Percent(0, 10) == 0, "whole percent, 1 while any is left")
units.nameplate1.name = Secret()
W.Fire("UNIT_NAME_UPDATE", "nameplate1")
check(dress.name._text == units.nameplate1.name, "a hidden name goes to the text as it is")
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
check(dress.threat._text == "40%" and dress.threat._color[1] == Text.THREAT[0][1] and dress.halo[1]._alpha == 0, "low threat: grey")
units.nameplate1.threat = { false, 1, 95 }
W.Fire("UNIT_THREAT_SITUATION_UPDATE", "player")
W.Wait(0)
check(dress.threat._text == "95%" and dress.threat._color[2] == Text.THREAT[1][2], "about to take its aggro: orange")
units.nameplate1.threat = { true, 3, 100 }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._color[2] == Text.THREAT[3][2] and dress.halo[1]._alpha == 1 and dress.halo[3]._alpha == 1, "aggro: red, and the bar glows")
local hidden = Secret()
units.nameplate1.threat = { hidden, Secret(), Secret() }
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(type(dress.halo[1]._alpha) == "table" and dress.halo[1]._alpha.from == hidden and dress.halo[1]._alpha.yes == nil,
    "a hidden answer: the glow takes it as it is, never compared, with the game's own alphas")
units.nameplate1.threat = nil
W.Fire("UNIT_THREAT_LIST_UPDATE", "nameplate1")
check(dress.threat._text == "" and dress.halo[1]._alpha == 0, "off its list: none")

-- Power that changes, and a unit without any.
units.nameplate1.powerNow = 70
W.Fire("UNIT_POWER_UPDATE", "nameplate1", "MANA")
check(dress.power._value == 70, "power followed")
units.nameplate1.powerMost = 0
W.Fire("UNIT_MAXPOWER", "nameplate1")
check(not dress.power:IsShown(), "no power: no line")
units.nameplate1.powerMost = 100
W.Fire("UNIT_MAXPOWER", "nameplate1")

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
check(Auras.Slots(190) == 8 and own._groups.own.most == 8 and foes._groups.foes.most == Auras.BUFFS, "eight debuffs over a bar 190 wide, three buffs")
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
--  A friend shown by name only, players, the raid marker, the ring
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
check(friend.level._color[1] == 0.3, "the level of someone you cannot attack in the game's colour for that")
check(not friend.foes:IsShown() and friend.own:IsShown(), "no buffs on someone you cannot attack")
check(friend.raid:IsShown() and friend.raid._cell[1] == 8 and friend.raid._cell[2] == 4 and friend.raid._cell[3] == 4,
    "a raid marker: the game's icon at its index")
check(friend.raid._points[1][2] == friend and friend.control._points[1][2] == friend.raid, "right of the bar, the crowd control after it")
units.nameplate2.raid = Secret()
W.Fire("RAID_TARGET_UPDATE")
check(friend.raid:IsShown() and friend.raid._cell[1] == units.nameplate2.raid, "an index hidden from addons goes to the icon as it is")
units.nameplate2.raid = nil
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown() and friend.control._points[1][2] == friend, "no marker: none, the crowd control by the bar")

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
check(friend:IsShown() and friend.ring:IsShown() and friend.ring._vertex[1] == 1 and not dress.ring:IsShown(),
    "your target: shown, its ring lit, the others' not")
units.focus, plates.focus = units.nameplate1, plates.nameplate1
W.Fire("PLAYER_FOCUS_CHANGED")
check(dress.ring:IsShown() and dress.ring._vertex[2] == 0.49, "your focus's ring in the game's colour for it")
units.nameplate2.friend, units.nameplate2.raid = false, 8
W.Fire("UNIT_FACTION", "nameplate2")
check(friend:IsShown() and friend.halo[1]._alpha == 1, "a player who may attack you: shown, glowing")
W.Fire("RAID_TARGET_UPDATE")
check(not friend.raid:IsShown(), "and no raid marker, as on the game's plates")
units.nameplate2.friend, units.nameplate2.party = true, true
W.Fire("UNIT_FACTION", "nameplate2")
check(friend.halo[1]._alpha == 0, "a friend again: no glow")

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
--  Smaller far away: the game's CVars, its defaults back when off
-------------------------------------------------------------------------------
check(W.cvars.nameplateMinScale == "0.25" and C_CVar.GetCVar("nameplateMaxScale") == "1" and W.cvars.nameplateMinScaleDistance == "0"
    and W.cvars.nameplateMaxScaleDistance == "0" and W.cvars.nameplateSelectedScale == "1",
    "the game's scaling a straight line from full size at your feet to a quarter at the farthest, nothing else in it")
local function Near(a, b) return math.abs(a - b) < 1e-6 end
check(Near(Scale.Size(0), 2) and Near(Scale.Size(20), 1.5) and Near(Scale.Size(40), 1) and Near(Scale.Size(50), 0.75)
    and Near(Scale.Size(60), 0.5) and Near(Scale.Size(500), 0.5), "our curve: twice, its own size at 40 yards, half at 60")
check(Near(Scale.Distance(1, 60), 0) and Near(Scale.Distance(0.625, 60), 30) and Near(Scale.Distance(0.25, 60), 60)
    and Near(Scale.Distance(0.1, 60), 60), "the distance read back from the game's scale")
-- The game puts the wolf 30 yards away (its scale 0.625): the plate at 1.25 of its size, so scaled by 2.
plates.nameplate1:SetScale(0.625)
Scale.driver:GetScript("OnUpdate")(Scale.driver, 1)
check(Scale.driver:IsShown() and Near(dress._scale, 1.25 / 0.625) and Near(plates.nameplate1.UnitFrame._scale, 2),
    "a plate scaled from the game's size to ours: our dress and the game's unit frame alike")
plates.nameplate1:SetScale(0.25) -- at the farthest reach (the CVar's 1000 is held to the game's 60)
Scale.driver:GetScript("OnUpdate")(Scale.driver, 1)
check(Near(dress._scale, 2), "at 60 yards: half its size")
W.combat = true
Core.Set(ns.name, "distance", false)
check(W.cvars.nameplateMinScale == "0.25" and dress._scale == 1 and plates.nameplate1.UnitFrame._scale == 1 and not Scale.driver:IsShown(),
    "off in a fight: the plates at the game's scale at once, the CVars wait")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(W.cvars.nameplateMinScale == "1" and W.cvars.nameplateMinScaleDistance == "10" and W.cvars.nameplateSelectedScale == "1.2",
    "after it: the game's defaults")
Core.Set(ns.name, "distance", true)
check(W.cvars.nameplateMinScale == "0.25" and Scale.driver:IsShown(), "on again")

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
check(W.cvars.nameplateMinScale == "1" and plates.nameplate1.UnitFrame._scale == 1 and dress._scale == 1,
    "the game's scaling by distance its own again, every plate at the game's scale")
bar:Hide()
bar:Show()
W.Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
check(not dress:IsShown() and Faded(plates.nameplate1, 1), "after that, nothing is dressed")

io.write(("Nameplates: all %d checks passed.\n"):format(passed))
