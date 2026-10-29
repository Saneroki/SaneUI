local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units
--  Our own frames for you, your target and your focus, each in place of the
--  game's own, in the look of a nameplate (Bar.lua, Text.lua): a round bar in
--  the unit's colour with its power along the bottom; inside it the level and
--  the raid marker on the left, the name in the middle (a player's first name
--  and surname), the health and how much is left on the right.
--
--  Each is the game's secure unit button (SecureUnitButtonTemplate): a click
--  targets the unit, a right click opens the game's menu for it, as the game's
--  frames do, in a fight too; the game's unit watch shows it while the unit is
--  there (RegisterUnitWatch: your target's and focus's frames come and go with
--  them, in a fight too). What it shows is a frame of ours on it (its face),
--  which hears its unit's events (RegisterUnitEvent). Each is a window of
--  Core's without a frame (Core.Window): placed in the game's Edit Mode, where
--  a frame whose unit is not there shows as a sample (your own, named for it).
--
--  The game's own frames go out of sight while ours show, nothing of theirs
--  written: your target's and focus's frame stand in a hidden frame of ours
--  (Core.Lend: their parent given back exactly), and with them what hangs on
--  them (their auras, cast bar and the target's target, Forever's combo points:
--  on its nameplate there); of your own frame only its picture, bars and texts
--  (their alpha) and its clicks, so what hangs on it stays the game's: the pet's
--  frame, the totems, the cast bar and a class's resource bar.
--
--  Secure frames are made, shown, moved, sized and given back out of a fight
--  only: what is asked for in one waits for its end (Core.AfterCombat). Off
--  (each frame's setting) or standing down, the game's frame is back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Units = {}
ns.Units = Units

Units.WIDTH, Units.HEIGHT = 240, 26 -- a frame's size at 100 % (the setting Unit frame size scales it)
-- Each frame: its unit, its setting, the game's frame it stands for, its place's key and first place (from the
-- screen's bottom middle, above the action bars: you left of the middle, your target right, your focus above it).
Units.KINDS = {
    { unit = "player", option = "unitPlayer", game = "PlayerFrame", place = "playerPlace",
      first = { point = "BOTTOM", x = -190, y = 230 } },
    { unit = "target", option = "unitTarget", game = "TargetFrame", place = "targetPlace",
      first = { point = "BOTTOM", x = 190, y = 230 } },
    { unit = "focus", option = "unitFocus", game = "FocusFrame", place = "focusPlace",
      first = { point = "BOTTOM", x = 190, y = 272 } },
}
-- Of your own frame (PlayerFrame), the parts out of sight: its picture, and its bars and texts.
Units.PLAYER_PARTS = { "PlayerFrameContainer", "PlayerFrameContent" }
-- What each face hears of its unit.
Units.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
                 "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_CLASSIFICATION_CHANGED",
                 "UNIT_CONNECTION", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE" }
Units.AGGRO = 2 -- the first of the game's threat kinds that is having aggro

local box -- the hidden frame the game's target and focus frames stand in while ours show

-- Your threat: on your own frame, whether anything is after you; on another, whether you have its aggro (the game's
-- answer as it is, hidden or not: the glow takes it).
local function Threat(face)
    if face.sample then return ns.UnitBar.Glow(face, false) end
    local unit = face.unit
    if unit == "player" then
        local status = Core.Ask(UnitThreatSituation, "player")
        return ns.UnitBar.Glow(face, type(status) == "number" and status >= Units.AGGRO)
    end
    local ok, tanking = pcall(UnitDetailedThreatSituation, "player", unit)
    if not ok or type(tanking) == "nil" then tanking = false end
    ns.UnitBar.Glow(face, tanking)
end

-- Everything for the face's unit as the game says it now; in Edit Mode, a frame whose unit is not there shows your
-- own as a sample, named for what it stands for.
local function Fill(face)
    face.sample = Core.EditMode.active and not Core.Ask(UnitExists, face.unit)
    local unit = face.sample and "player" or face.unit
    if not face.sample and not Core.Ask(UnitExists, unit) then return end
    ns.UnitBar.Paint(face, unit)
    ns.UnitBar.Health(face, unit)
    ns.UnitBar.Power(face, unit)
    ns.UnitText.Set(face, unit, face.sample and ns.TEXT.samples[face.unit] or nil)
    Threat(face)
end

local function Heard(face, event)
    if ns.off or face.sample then return end
    local unit = face.unit
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.UnitBar.Health(face, unit)
        ns.UnitText.Health(face, unit)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        ns.UnitBar.Power(face, unit)
    elseif event == "UNIT_NAME_UPDATE" then
        ns.UnitText.Name(face, unit)
    elseif event == "UNIT_LEVEL" then
        ns.UnitText.Level(face, unit)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        Threat(face)
    else -- friend or foe, tapped, its rank, online
        Fill(face)
    end
end
local OnEvent = ns.Guard(Heard)

-- Laid out anew for its size and scale: its border a screen pixel, the name's room.
local function Fit(face)
    ns.UnitBar.Fit(face)
    ns.UnitText.Layout(face)
end
local OnSizeChanged = ns.Guard(Fit)

-- The game's tooltip for the unit, as its own frames show it.
local function Entered(button)
    local face = button.face
    if not face or face.sample then return end
    if GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    GameTooltip:SetUnit(face.unit)
    GameTooltip:Show()
end
local OnEnter = ns.Guard(Entered)

-- A frame: the game's secure unit button, our face on it, a window of Core's to place it.
local function Make(kind)
    local button = CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate")
    button:SetSize(Units.WIDTH, Units.HEIGHT)
    button:SetFrameStrata("LOW")
    button:SetAttribute("unit", kind.unit)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
    local face = CreateFrame("Frame", nil, button)
    face:SetAllPoints(button)
    face.unit = kind.unit
    ns.UnitBar.Make(face)
    ns.UnitText.Make(face)
    for _, event in ipairs(Units.EVENTS) do pcall(face.RegisterUnitEvent, face, event, kind.unit) end
    face:SetScript("OnEvent", OnEvent)
    face:SetScript("OnSizeChanged", OnSizeChanged)
    button.face = face
    kind.button = button
    kind.window = Core.Window.New(button, { store = ns.store, key = kind.place, title = ns.TEXT[kind.option],
                                            first = kind.first })
    kind.window:Place()
end

-- The game's frame out of sight: your own frame's parts and its clicks; your target's and focus's whole.
local function Away(kind)
    local game = rawget(_G, kind.game)
    if kind.lends or type(game) ~= "table" then return end
    kind.lends = {}
    local function Lend(frame, change, ...)
        local lend = Core.Lend(frame)
        lend[change](lend, ...)
        kind.lends[#kind.lends + 1] = lend
    end
    if kind.unit == "player" then
        for _, key in ipairs(Units.PLAYER_PARTS) do
            local part = rawget(game, key)
            if type(part) == "table" and part.SetAlpha then Lend(part, "SetAlpha", 0) end
        end
        Lend(game, "SetMouse", false)
    else
        Lend(game, "SetParent", box)
    end
end

-- The game's frame back as it was.
local function Back(kind)
    local lends = kind.lends
    kind.lends = nil
    for index = #(lends or {}), 1, -1 do ns.Safe("unit frames", lends[index].Return, lends[index]) end
end

-- One frame shown and the game's away, or ours hidden and the game's back, as its setting says; at the size the
-- setting Unit frame size says. Out of a fight.
local function Kind(kind)
    local wanted = not ns.off and ns.options[kind.option] ~= false
    local button = kind.button
    if not wanted then
        if button then
            UnregisterUnitWatch(button)
            button:Hide()
        end
        return Back(kind)
    end
    if not button then Make(kind) end
    button = kind.button
    button:SetScale((tonumber(ns.options.unitSize) or 100) / 100)
    Away(kind)
    if Core.EditMode.active then
        UnregisterUnitWatch(button)
        button:Show()
    else
        RegisterUnitWatch(button)
    end
    Fit(button.face)
    Fill(button.face)
end

local function Apply()
    if not box then
        box = CreateFrame("Frame", nil, UIParent)
        box:Hide()
    end
    for _, kind in ipairs(Units.KINDS) do ns.Guarded(Kind, kind) end
end

-- As the settings say, now or once the fight is over.
function Units.Apply()
    Core.AfterCombat("unit frames", Apply)
end

-- Every frame filled anew, each that is shown (the world shown, a level gained).
local function Again()
    if ns.off then return end
    for _, kind in ipairs(Units.KINDS) do
        if kind.button and kind.button:IsShown() then Fill(kind.button.face) end
    end
end

-- A frame's unit changed: filled anew.
local function Changed(unit)
    if ns.off then return end
    for _, kind in ipairs(Units.KINDS) do
        if kind.unit == unit and kind.button then Fill(kind.button.face) end
    end
end

function Units.Start()
    ns.On("PLAYER_TARGET_CHANGED", function() Changed("target") end)
    ns.On("PLAYER_FOCUS_CHANGED", function() Changed("focus") end)
    ns.On("RAID_TARGET_UPDATE", function()
        for _, kind in ipairs(Units.KINDS) do
            local face = kind.button and kind.button.face
            if face and not face.sample and not ns.off then ns.UnitText.Raid(face, kind.unit) end
        end
    end)
    ns.On("PLAYER_LEVEL_UP", Core.Later(Again))
    -- Once the world shows (the game's fonts and scales set up, also after a /reload), every frame measured anew.
    ns.On("PLAYER_ENTERING_WORLD", Core.Later(function()
        if ns.off then return end
        for _, kind in ipairs(Units.KINDS) do
            if kind.button then Fit(kind.button.face) end
        end
        Again()
    end, 0.5))
    ns.On("UI_SCALE_CHANGED", Core.Later(Units.Apply))
    -- In Edit Mode a frame shows whether its unit is there or not (as a sample), to be placed; after it, as the
    -- game's unit watch says again.
    Core.EditMode.Watch(ns.Guard(Units.Apply))
    Units.Apply()
end

-- Standing down: ours out of sight at once (their alpha may change in a fight), hidden and their unit watch off
-- after it; the game's frames back (Core.Lend gives back after a fight what may not change in one).
function Units.GiveBack()
    for _, kind in ipairs(Units.KINDS) do
        local button = kind.button
        if button then
            button:SetAlpha(0)
            Core.AfterCombat("unit frame " .. kind.unit, function()
                UnregisterUnitWatch(button)
                button:Hide()
            end)
        end
        ns.Safe("unit frames", Back, kind)
    end
end
