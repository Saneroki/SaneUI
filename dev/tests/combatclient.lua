-- What the Combat module's unit frames (Units/) and clean action bars (ActionBars.lua) need of the stand-in client
-- (wowstub.lua), for every test that loads the module (combat.lua, book.lua, talents.lua): the game's widgets as
-- they use them, its unit functions for the units a test names, its unit watch, the game's frames ours stand for,
-- and its main action bar with two buttons (a test puts an action on one: W.actions).
-- Usage, before the module is loaded:  local fight = require("combatclient").Install(W)
-- Run on its own (lua5.1 dev/tests/combatclient.lua) it tries its stand-ins under the stand-in client's rules, with
-- Core loaded: a hidden value, a fight, a frame shown with its row.

local Client = {}

function Client.Install(W)
    local methods = W.methods
    local texture = methods.CreateTexture
    function methods:CreateTexture(name, layer, ...)
        local made = texture(self, name, layer, ...)
        made._layer = layer
        return made
    end
    function methods:SetMinMaxValues(low, high) self._min, self._max = low, high end
    function methods:SetValue(value) self._value = value end
    function methods:SetStatusBarColor(r, g, b, a) self._barColor = { r, g, b, a } end
    function methods:SetStatusBarTexture(texture) self._barTexture = texture end
    function methods:SetReverseFill(on) self._reverse = on end
    function methods:SetFrameLevel(level) self._level = level end
    function methods:GetFrameLevel() return self._level or 1 end
    function methods:GetStatusBarTexture()
        self._fill = self._fill or W.NewWidget("Texture", nil, self)
        return self._fill
    end
    function methods:AddMaskTexture(mask) self._masks = self._masks or {}; self._masks[mask] = true end
    function methods:RemoveMaskTexture(mask) if self._masks then self._masks[mask] = nil end end
    function methods:SetSpriteSheetCell(cell) self._cell = cell end
    function methods:SetFormattedText(form, ...)
        for index = 1, select("#", ...) do
            if type((select(index, ...))) == "table" then self._text = { form = form, ... } return end
        end
        self._text = form:format(...)
    end
    function methods:SetAlphaFromBoolean(value, yes, no) self._alpha = { from = value, yes = yes, no = no } end
    function methods:GetStringWidth() return type(self._text) == "string" and #self._text * 6 or 0 end
    methods.GetUnboundedStringWidth = methods.GetStringWidth
    function methods:SetFont(file, height, flags) self._font = { file, height, flags } return true end
    function methods:SetTexCoord(...) self._coords = { ... } end
    function methods:SetColorTexture(r, g, b, a) self._colour = { r, g, b, a } end
    function methods:GetAtlas() return self._atlas end
    function methods:SetBlendMode(mode) self._blend = mode end
    function methods:SetJustifyH(justify) self._justify = justify end
    function methods:GetBlendMode() return self._blend or "BLEND" end
    -- The game's unit functions for the units a test names (units.target = { name = , health = , ... }); for one it
    -- names not, the stand-in's own (your character: a Forever name, a mage, W.level).
    local units = {}
    local function Unit(unit) return units[unit] or {} end
    local function Named(name, answer)
        local own = rawget(_G, name)
        _G[name] = function(unit, ...)
            if units[unit] then return answer(units[unit], unit, ...) end
            if own then return own(unit, ...) end
        end
    end
    Named("UnitName", function(u) return u.name, u.surname end)
    Named("UnitIsPlayer", function(u) return u.player or false end)
    Named("UnitClass", function(u) return "Warrior", u.class end)
    Named("UnitLevel", function(u) return u.level end)
    UnitExists = function(unit) return units[unit] ~= nil or unit == "player" end
    UnitHealth = function(unit) return Unit(unit).health end
    UnitHealthMax = function(unit) return Unit(unit).most end
    -- A unit's own power (power, powerMost, powerType and its token, rage at first), and its mana (mana, manaMost).
    UnitPower = function(unit, kind)
        if kind == 0 and Unit(unit).powerType ~= 0 then return Unit(unit).mana end
        return Unit(unit).power
    end
    UnitPowerMax = function(unit, kind)
        if kind == 0 and Unit(unit).powerType ~= 0 then return Unit(unit).manaMost or 0 end
        return Unit(unit).powerMost or 0
    end
    UnitPowerType = function(unit) return Unit(unit).powerType or 1, Unit(unit).powerToken or "RAGE" end
    UnitClassification = function(unit) return Unit(unit).classification or "normal" end
    UnitIsTapDenied = function() return false end
    UnitReaction = function(unit) return Unit(unit).reaction or 5 end
    UnitSelectionColor = function() return 0, 1, 0, 1 end
    UnitCanAttack = function(a, b) return Unit(a == "player" and b or a).foe or false end
    UnitIsDeadOrGhost = function(unit) return Unit(unit).dead or false end
    UnitIsConnected = function(unit) return not Unit(unit).offline end
    UnitThreatSituation = function() return W.threat end
    UnitDetailedThreatSituation = function(_, unit) return Unit(unit).tanking end
    GetRaidTargetIndex = function(unit) return Unit(unit).raid end
    AbbreviateNumbers = function(value) return { abbreviated = value } end
    RAID_CLASS_COLORS = rawget(_G, "RAID_CLASS_COLORS")
        or { WARRIOR = { r = 0.78, g = 0.61, b = 0.43 }, MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
    SystemFont_NamePlate_Outlined = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "OUTLINE" end }
    -- The game's aura containers for addons (CustomAuraContainerTemplate): their groups as given, one icon made for
    -- each group (its initializeFrame), what they are set to. The unit's auras by index (W.auras[unit][filter]).
    AnchorUtil = { FlowDirection = { Left = "Left", Right = "Right", Up = "Up", Down = "Down" } }
    AuraContainerSortMethod = { Default = 0, BigDefensive = 1, UnitFrameDebuff = 2 }
    AuraContainerSortDirection = { Normal = 0, Reverse = 1 }
    W.templates.CustomAuraContainerTemplate = function(container)
        container._groups = {}
        container._flow = {}
        function container:SetFlowLayoutAnchorPoint(corner) self._flow.corner = corner end
        function container:SetFlowLayoutGrowthDirection(across, up) self._flow.across, self._flow.up = across, up end
        function container:SetFlowLayoutMaximumLineSize(line) self._flow.line = line end
        function container:AddAuraGroup(key, filter, options)
            local icon = W.NewWidget("Button", nil, self)
            self._groups[key] = { filter = filter, options = options, enabled = true, icon = icon }
            if options.initializeFrame then options.initializeFrame(icon) end
        end
        function container:SetAuraGroupFilterString(key, filter) self._groups[key].filter = filter end
        function container:SetAuraGroupCandidateFilters(key, filters) self._groups[key].candidates = filters end
        function container:SetAuraGroupEnabled(key, on) self._groups[key].enabled = on end
        function container:SetUnit(unit) self._unit = unit end
        function container:UpdateAllAuras() self._updates = (self._updates or 0) + 1 end
    end
    for _, name in ipairs({ "SetIcon", "SetDurationCooldown", "SetApplicationCount", "SetSpellName" }) do
        methods[name] = function(self, region) self["_" .. name] = region end
    end
    W.auras = {}
    C_UnitAuras = rawget(_G, "C_UnitAuras") or {}
    C_UnitAuras.GetAuraDataByIndex = function(unit, index, filter)
        local list = W.auras[unit] and W.auras[unit][filter]
        return list and list[index]
    end
    -- The game's unit watch (RegisterUnitWatch): a watched frame is shown while its unit is there and hidden while it
    -- is not, as it is registered and at every tick of the watch, in a fight too (the game's own secure code does it).
    -- The game ticks every 0.2 seconds; here the test does, fight.Watch(), once it changed a unit.
    local watched, watching = {}, {} -- the frames, as a set to ask and in the order they registered
    local function Seen(frame)
        local exists = UnitExists(frame:GetAttribute("unit"))
        local combat = W.combat
        W.combat = false -- the stand-in refuses a touch of a secure frame in a fight; the game's own watch is let
        if exists then frame:Show() else frame:Hide() end
        W.combat = combat
    end
    RegisterUnitWatch = function(frame)
        if not watched[frame] then watching[#watching + 1] = frame end
        watched[frame] = true
        Seen(frame)
    end
    UnregisterUnitWatch = function(frame)
        watched[frame] = nil
        for index = #watching, 1, -1 do
            if watching[index] == frame then table.remove(watching, index) end
        end
    end
    local function Watch()
        for _, frame in ipairs({ unpack(watching) }) do -- a copy: a frame registered by a script waits for the next tick
            if watched[frame] then Seen(frame) end
        end
    end
    -- The game's state driver (what a frame's visibility hangs on: W.drivers[frame]), and its secure group headers: a
    -- header makes its buttons when told to start below its first, and gives them the units a test says (W.members
    -- [group] = { unit, ... }) whenever it is told anything.
    -- The game's heal prediction: what a test puts on W.calculator is what it says of any unit.
    W.calculator = { amount = 0, clamped = false, total = 0 }
    function W.calculator:GetDamageAbsorbs() return self.amount, self.clamped end
    function W.calculator:GetTotalDamageAbsorbs() return self.total end
    function W.calculator:SetDamageAbsorbClampMode(mode) self.mode = mode end
    CreateUnitHealPredictionCalculator = function() return W.calculator end
    UnitGetDetailedHealPrediction = function() end
    W.drivers, W.members = {}, {}
    SecureHandlerSetFrameRef = function(frame, label, ref)
        frame._refs = frame._refs or {}
        frame._refs[label] = ref
    end
    W.ready = {} -- what the game says of each unit in a ready check
    GetReadyCheckStatus = function(unit) return W.ready[unit] end
    W.threat = {}
    UnitThreatSituation = function(unit) return W.threat[unit] end
    UnitIsUnit = function(a, b) return a == b end
    UnitIsGroupLeader, UnitIsGroupAssistant = function() return true end, function() return false end
    IsInGroup, IsInRaid = function() return false end, function() return false end
    GetNumGroupMembers = function() return 0 end
    RegisterStateDriver = function(frame, state, values) W.drivers[frame] = { state = state, values = values } end
    UnregisterStateDriver = function(frame) W.drivers[frame] = nil end
    W.templates.SecureGroupHeaderTemplate = function(header)
        function header:SetAttribute(name, value)
            W.methods.SetAttribute(self, name, value)
            if name == "startingIndex" and value < 1 then
                for child = 1, 1 - value do
                    self[child] = self[child] or CreateFrame("Button", nil, self, self:GetAttribute("template"))
                end
            end
            local list = W.members[tonumber(self:GetAttribute("groupFilter"))] or {}
            for child = 1, 5 do
                local button = self[child]
                if button then
                    button:SetAttribute("unit", list[child])
                    local hook = button:GetScript("OnAttributeChanged")
                    if hook then hook(button, "unit", list[child]) end
                end
            end
        end
    end
    -- The game's frames ours stand for. Its unit frames are its secure unit buttons, protected: the stand-in refuses a
    -- touch of one in a fight, as the game does.
    PlayerFrame = W.NewWidget("Button", "PlayerFrame", UIParent)
    PlayerFrame._protected = true
    PlayerFrame.PlayerFrameContainer = W.NewWidget("Frame", nil, PlayerFrame)
    PlayerFrame.PlayerFrameContent = W.NewWidget("Frame", nil, PlayerFrame)
    PlayerFrame._mouse = true
    -- As in the game, its health bar takes no click but holds the mouse moving over it.
    PlayerFrame.PlayerFrameContent.HealthBar = W.NewWidget("StatusBar", nil, PlayerFrame.PlayerFrameContent)
    PlayerFrame.PlayerFrameContent.HealthBar._motion = true
    TargetFrame = W.NewWidget("Button", "TargetFrame", UIParent)
    TargetFrame._protected = true
    FocusFrame = W.NewWidget("Button", "FocusFrame", UIParent)
    FocusFrame._protected = true
    PetFrame = W.NewWidget("Button", "PetFrame", PlayerFrame)
    PetFrame._protected = true
    PetFrame._mouse = true
    PetFrameHappiness = W.NewWidget("Frame", "PetFrameHappiness", PetFrame)
    PetFrameHappiness._mouse, PetFrameHappiness._motion = true, true
    -- The game's bars that go (GameBars.lua), the menu bar with a button of it.
    StatusTrackingBarManager = W.NewWidget("Frame", "StatusTrackingBarManager", UIParent)
    StanceBar = W.NewWidget("Frame", "StanceBar", UIParent)
    MicroMenu = W.NewWidget("Frame", "MicroMenu", UIParent)
    MicroMenu.Button = W.NewWidget("Button", nil, MicroMenu)
    -- The game's cast bars and its timers' bars, hearing what its code registers. Your cast (W.cast, W.channel: name,
    -- icon, starts, ends, id, spell, locked, craft; a channel's empowered, stages), another unit's (W.casts[unit]) and
    -- your timers (W.mirror[index]: as the game gives them; W.mirrorLeft[timer]: milliseconds).
    for _, name in ipairs({ "PlayerCastingBarFrame", "OverlayPlayerCastingBarFrame", "PetCastingBarFrame" }) do
        _G[name] = W.NewWidget("StatusBar", name, UIParent)
        for _, event in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_INTERRUPTIBLE" }) do
            _G[name]:RegisterUnitEvent(event, "player")
        end
        _G[name]:RegisterEvent("PLAYER_ENTERING_WORLD")
    end
    MirrorTimerContainer = W.NewWidget("Frame", "MirrorTimerContainer", UIParent)
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "MIRROR_TIMER_START", "MIRROR_TIMER_STOP", "MIRROR_TIMER_PAUSE" }) do
        MirrorTimerContainer:RegisterEvent(event)
    end
    W.casts = {}
    UnitCastingInfo = function(unit)
        local cast = W.casts[unit]
        if unit == "player" then cast = W.cast end
        if cast and not cast.channel then
            return cast.name, cast.name, cast.icon, cast.starts, cast.ends, cast.craft or false, cast.id, cast.locked or false, cast.spell
        end
    end
    UnitChannelInfo = function(unit)
        local cast = W.casts[unit]
        if unit == "player" then cast = W.channel end
        if cast and (unit == "player" or cast.channel) then
            return cast.name, cast.name, cast.icon, cast.starts, cast.ends, cast.craft or false, cast.locked or false, cast.spell,
                cast.empowered or false, cast.stages or 0
        end
    end
    W.mirror, W.mirrorLeft = {}, {}
    GetMirrorTimerInfo = function(index)
        local timer = W.mirror[index]
        if timer then return unpack(timer) end
        return "UNKNOWN", 0, 0, 0, 0, ""
    end
    GetMirrorTimerProgress = function(timer) return W.mirrorLeft[timer] end
    -- The game's main action bar: its art, a divider, two buttons, the first holding an action, the second empty.
    -- Its buttons are secure (the game's action buttons): a touch of one in a fight is refused.
    local function GameButton(slot)
        local button = W.NewWidget("CheckButton", nil, UIParent)
        button._protected = true
        button.action, button.icon, button.IconMask = slot, W.NewWidget("Texture", nil, button), W.NewWidget("MaskTexture")
        button.icon:AddMaskTexture(button.IconMask)
        for _, key in ipairs({ "NormalTexture", "SlotArt", "SlotBackground", "Border" }) do
            button[key] = W.NewWidget("Texture", nil, button)
        end
        button.cooldown = W.NewWidget("Cooldown", nil, button)
        button.cooldown:SetPoint("TOPLEFT", button.icon, "TOPLEFT", 3, -3)
        button:SetHighlightTexture("highlight")
        button:SetPushedTexture("pushed")
        return button
    end
    local divider = W.NewWidget("Frame")
    MainActionBar = W.NewWidget("Frame", "MainActionBar", UIParent)
    MainActionBar.BorderArt, MainActionBar.EndCaps = W.NewWidget("Texture"), W.NewWidget("Frame")
    MainActionBar.ActionBarPageNumber = W.NewWidget("Frame")
    MainActionBar.ActionBarPageNumber.UpButton = W.NewWidget("Button")
    MainActionBar.ActionBarPageNumber.UpButton._mouse = true
    MainActionBar.HorizontalDividersPool = { EnumerateActive = function() return pairs({ [divider] = true }) end }
    MainActionBar.actionButtons = { GameButton(1), GameButton(2) }
    return { units = units, Unit = Unit, watched = watched, Watch = Watch, divider = divider, UnitName = UnitName,
             UnitIsPlayer = UnitIsPlayer }
end

-- Run on its own, the client tries its stand-ins under the stand-in client's rules, with Core loaded (what the module
-- reads the game through): a hidden value a test gives a unit reaches the module as the game's secret; a secure group
-- header is refused in a fight and told after it; the unit watch shows a frame and its row, the row's OnShow with its
-- frame's, and a frame out of sight hears nothing of its row.
local function SelfCheck()
    local root = arg[0]:match("^(.*)/dev/tests/") or "."
    package.path = root .. "/dev/tests/?.lua;" .. package.path
    local W = require("wowstub")
    W.Install(_G)
    local passed = 0
    local function check(condition, what)
        if not condition then error("FAILED: " .. what, 2) end
        passed = passed + 1
    end
    local fight = Client.Install(W)
    local units = fight.units
    W.LoadCore(root)
    local Core = SaneUI.Core
    W.Fire("ADDON_LOADED", "SaneUI")

    -- A value the game hides in a fight (health, threat), given to a unit: the module reads every unit value through
    -- Core.Plain and Core.Ask (Units/Bar.lua, Units/GroupFace.lua): nil for the hidden one, the plain ones beside it.
    local hidden = W.Secret()
    units.target = { name = "Kobold Miner", health = hidden, most = 120, tanking = hidden }
    local health, most = Core.Ask(UnitHealth, "target"), Core.Ask(UnitHealthMax, "target")
    check(issecretvalue(UnitHealth("target")) and health == nil and most == 120 and Core.Plain(UnitHealth("target")) == nil
        and Core.Ask(UnitDetailedThreatSituation, "player", "target") == nil and Core.Plain(UnitName("target")) == "Kobold Miner",
        "a hidden value reaches the module as the game's secret: nil through Core.Plain and Core.Ask, the plain ones beside it")

    -- A secure group header (Units/Group.lua makes them out of a fight): told to start in a fight, the game refuses and
    -- no button is made; asked through Core.AfterCombat it waits for the fight's end, then makes its buttons with the
    -- group's units.
    W.members[1] = { "player", "party1" }
    local header = CreateFrame("Frame", nil, UIParent, "SecureGroupHeaderTemplate")
    header:SetAttribute("template", "SecureUnitButtonTemplate")
    header:SetAttribute("groupFilter", "1")
    W.Combat(true)
    local ok, err = pcall(header.SetAttribute, header, "startingIndex", -1)
    local now = Core.AfterCombat("the header", header.SetAttribute, header, "startingIndex", -1)
    check(not ok and tostring(err):find("ADDON_ACTION_BLOCKED") and header[1] == nil and not now and Core.Owed("the header"),
        "in a fight the header cannot be told to start: the game refuses, no button is made; asked after the fight it waits")
    W.Combat(false)
    check(not Core.Owed("the header") and header[1]._template == "SecureUnitButtonTemplate"
        and header[1]:GetAttribute("unit") == "player" and header[2]:GetAttribute("unit") == "party1" and header[3] == nil,
        "after the fight it is told: two buttons made from the template, each with its unit")

    -- A frame and its row as Units/Units.lua makes them: the game's secure unit buttons, the row a child of the frame,
    -- hidden, both on the game's unit watch, the frame's first. What each hears of its showing and hiding.
    local heard = {}
    local function Heard()
        local words = table.concat(heard, ", ")
        heard = {}
        return words
    end
    local function Hears(frame, word)
        frame:HookScript("OnShow", function() heard[#heard + 1] = word .. " shown" end)
        frame:HookScript("OnHide", function() heard[#heard + 1] = word .. " hidden" end)
    end
    units.target = nil
    local frame = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    frame:SetAttribute("unit", "target")
    local row = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate")
    row:SetAttribute("unit", "targettarget")
    row:Hide()
    Hears(frame, "frame")
    Hears(row, "row")
    RegisterUnitWatch(frame)
    RegisterUnitWatch(row)
    check(fight.watched[frame] and not frame._shown and not row._shown and Heard() == "frame hidden",
        "registered with no target: the frame hidden at once and hears it; the row was hidden already")
    units.target = { name = "Kobold Miner", health = 40, most = 120 }
    units.targettarget = { name = "Droopy", surname = "Fairwind", player = true, health = 600, most = 1000 }
    W.Combat(true)
    fight.Watch()
    check(frame._shown and row._shown and Heard() == "frame shown, row shown",
        "the watch's tick, in a fight too: the frame shown, then its row, each hearing it")
    W.Combat(false)
    units.target, units.targettarget = nil, nil
    fight.Watch()
    check(not frame._shown and not row._shown and Heard() == "frame hidden, row hidden",
        "the target gone: the frame hidden with its row, which hears it with its frame; hidden then itself, out of sight, it hears nothing")
    row:Show() -- the game's watch may show the row before its frame
    units.target = { name = "Kobold Miner", health = 40, most = 120 }
    units.targettarget = { name = "Droopy", surname = "Fairwind", player = true, health = 600, most = 1000 }
    local before = Heard()
    fight.Watch()
    check(before == "" and frame._shown and row._shown and Heard() == "frame shown, row shown",
        "a row shown while its frame is out of sight hears nothing; as the frame shows, the row's OnShow runs with its frame's")
    UnregisterUnitWatch(row)
    UnregisterUnitWatch(frame)
    units.target = nil
    fight.Watch()
    check(not fight.watched[frame] and frame._shown and Heard() == "", "off the watch, a frame keeps its state")
    io.write(("Combat client: all %d checks passed.\n"):format(passed))
end

if (...) ~= "combatclient" then SelfCheck() end

return Client
