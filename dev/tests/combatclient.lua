-- What the Combat module's unit frames (Units/) and clean action bars (ActionBars.lua) need of the stand-in client
-- (wowstub.lua), for every test that loads the module (combat.lua, book.lua, talents.lua): the game's widgets as
-- they use them, its unit functions for the units a test names, its unit watch, the game's frames ours stand for,
-- and its main action bar with two buttons (a test puts an action on one: W.actions).
-- Usage, before the module is loaded:  local fight = require("combatclient").Install(W)

local Client = {}

function Client.Install(W)
    local methods = W.methods
    function methods:SetMinMaxValues(low, high) self._min, self._max = low, high end
    function methods:SetValue(value) self._value = value end
    function methods:SetStatusBarColor(r, g, b) self._barColor = { r, g, b } end
    function methods:SetStatusBarTexture(texture) self._barTexture = texture end
    function methods:SetReverseFill(on) self._reverse = on end
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
    function methods:SetAlphaFromBoolean(value) self._alpha = { from = value } end
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
    local watched = {}
    RegisterUnitWatch = function(frame) watched[frame] = true end
    UnregisterUnitWatch = function(frame) watched[frame] = nil end
    PlayerFrame = W.NewWidget("Button", "PlayerFrame", UIParent)
    PlayerFrame.PlayerFrameContainer = W.NewWidget("Frame", nil, PlayerFrame)
    PlayerFrame.PlayerFrameContent = W.NewWidget("Frame", nil, PlayerFrame)
    PlayerFrame._mouse = true
    TargetFrame = W.NewWidget("Button", "TargetFrame", UIParent)
    FocusFrame = W.NewWidget("Button", "FocusFrame", UIParent)
    PetFrame = W.NewWidget("Button", "PetFrame", PlayerFrame)
    PetFrame._mouse = true
    -- The game's cast bars and its timers' bars, hearing what its code registers. Your cast (W.cast, W.channel: name,
    -- icon, starts, ends, id, spell; a channel's empowered, stages) and your timers (W.mirror[index]: as the game gives
    -- them; W.mirrorLeft[timer]: milliseconds).
    for _, name in ipairs({ "PlayerCastingBarFrame", "OverlayPlayerCastingBarFrame" }) do
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
    UnitCastingInfo = function()
        local cast = W.cast
        if cast then return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, cast.id, false, cast.spell end
    end
    UnitChannelInfo = function()
        local cast = W.channel
        if cast then
            return cast.name, cast.name, cast.icon, cast.starts, cast.ends, false, false, cast.spell, cast.empowered or false,
                cast.stages or 0
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
    local function GameButton(slot)
        local button = W.NewWidget("CheckButton", nil, UIParent)
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
    return { units = units, Unit = Unit, watched = watched, divider = divider, UnitName = UnitName,
             UnitIsPlayer = UnitIsPlayer }
end

return Client
