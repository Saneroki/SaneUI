local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units
--  Our own frames for you, your target and your focus, each in place of the
--  game's own, in the look of a nameplate (Bar.lua, Text.lua): a round green
--  health bar, the level and the raid marker on its left, the name after them
--  (a player's first name and surname; none on your own frame), the health and
--  how much is left on its right; under it the unit's power at half its height
--  with the same words on the right (on your own frame, where you may have two
--  powers, a druid's in a form, two slots: mana always, the form's under it);
--  around it the auras that matter most (Auras.lua). Under each, as a cast bar
--  under a nameplate, a row while its unit is there, with that unit's name
--  alone: your target's target under your target's frame, your focus's target
--  under your focus's; under yours your pet, its power under its row. Directly
--  above each health bar its unit's cast while it casts (Cast.lua), over that
--  on your own frame the game's timers on you, your breath over the health bar
--  itself (Timers.lua).
--
--  Each frame and each row is the game's secure unit button
--  (SecureUnitButtonTemplate): a click targets the unit, a right click opens
--  the game's menu for it, as the game's frames do, in a fight too; the game's
--  unit watch shows it while the unit is there (RegisterUnitWatch, in a fight
--  too). A row's button is a child of its frame's, right under it. What both
--  show is a frame of ours on the frame's button (its face): it hears the
--  frame's unit's events (RegisterUnitEvent), and while the row shows, reads
--  the row's unit again every Units.POLL seconds (the game sends no events of
--  a target's target; it reads its own so). Each frame is a window of Core's
--  without a frame (Core.Window): placed in the game's Edit Mode, where a frame
--  or row whose unit is not there shows as a sample (your own, named for it).
--
--  The game's own frames go out of sight while ours show, nothing of theirs
--  written: your target's and focus's frame stand in a hidden frame of ours
--  (Core.Lend: their parent given back exactly), and with them what hangs on
--  them (their auras, cast bars and their own target's frames, Forever's combo
--  points: on its nameplate there); of your own frame only its picture, bars
--  and texts (their alpha) and its clicks, so what hangs on it stays the
--  game's: the totems and a class's resource bar. The game's pet frame, which
--  its layout puts back under its own parent, by its alpha and its clicks too.
--  What lies under those takes the mouse no more either (Unmouse): a frame at
--  alpha 0 still does, and the game's health and power bars would hold it off
--  the world. The game's cast bars and timers hear nothing while ours stand in
--  for them (Core.Lend's SetDeaf): the game shows and lays those out itself.
--
--  Out of sight at rest (Core.Rest, the setting Hide the unit frames at rest;
--  Saneroki, 2026-11-01): each frame goes by its alpha, its button still taking
--  the mouse, so the mouse on a frame, its row or its auras shows that frame
--  alone; a cast or a timer running on it shows it too (the game's own bars for
--  those are gone, and you need your breath under water). A fight, a group, your
--  health and your resource show them all.
--
--  Secure frames are made, shown, moved, sized and given back out of a fight
--  only: what is asked for in one waits for its end (Core.AfterCombat). Off
--  (each frame's and row's setting) or standing down, the game's frame is back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Units = {}
ns.Units = Units

Units.WIDTH, Units.HEIGHT = 240, 26 -- a frame's width and its health bar's height at 100 % (Unit frame size scales it)
Units.POWER = Units.HEIGHT / 2      -- a power bar's height under it
Units.ROW = 18   -- a row's height under them
Units.ROW_POWER = Units.ROW / 2 -- a row's power bar under it, half its height as a frame's is
Units.POLL = 0.2 -- seconds between two readings of a shown row's unit
-- Each frame: its unit, its setting, the game's frame it stands for and how that goes out of sight (Away), its place's
-- key and first place (from the screen's bottom middle, above the action bars: you left of the middle, your target
-- right, your focus above it; by the button's top: the health bar's, the same whatever height the button has), and its
-- row: the same of the unit under it, its bar's colour (none: green), and whether
-- its power shows under it. Your own frame's bars: the game's frames that go deaf for them, each with its setting and
-- what it no longer hears.
Units.KINDS = {
    { unit = "player", option = "unitPlayer", game = "PlayerFrame", away = "parts", noName = true,
      place = "playerPlace", first = { point = "TOP", relative = "BOTTOM", x = -190, y = 269 },
      row = { unit = "pet", option = "unitPet", game = "PetFrame", away = "fade", power = true },
      bars = { { option = "unitCast", game = "PlayerCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitCast", game = "OverlayPlayerCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitCast", game = "PetCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitBreath", game = "MirrorTimerContainer", away = "deaf", events = ns.UnitTimers.EVENTS } } },
    { unit = "target", option = "unitTarget", game = "TargetFrame", away = "parent",
      place = "targetPlace", first = { point = "TOP", relative = "BOTTOM", x = 190, y = 269 },
      row = { unit = "targettarget", option = "unitTargetTarget", colour = ns.UnitBar.CALM } },
    { unit = "focus", option = "unitFocus", game = "FocusFrame", away = "parent",
      place = "focusPlace", first = { point = "TOP", relative = "BOTTOM", x = 190, y = 371 },
      row = { unit = "focustarget", option = "unitFocusTarget", colour = ns.UnitBar.CALM } },
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

-- The row's unit as the game says it now, while the row shows; a sample in Edit Mode where it is not there.
local function Row(face)
    if not face.rowShown then return end
    local unit = face.rowUnit
    face.rowSample = Core.EditMode.active and not Core.Ask(UnitExists, unit)
    if face.rowSample then unit = "player" end
    if not face.rowSample and not Core.Ask(UnitExists, unit) then return end
    ns.UnitBar.Health(face.row, unit)
    ns.UnitText.RowPower(face, unit, ns.UnitBar.RowPower(face, unit))
    ns.UnitText.Row(face, unit, face.rowSample and ns.TEXT.samples[face.rowUnit] or nil)
end

-- Everything for the face's unit as the game says it now; in Edit Mode, a frame whose unit is not there shows your
-- own as a sample, named for what it stands for.
local function Fill(face)
    face.sample = Core.EditMode.active and not Core.Ask(UnitExists, face.unit)
    local unit = face.sample and "player" or face.unit
    if not face.sample and not Core.Ask(UnitExists, unit) then return end
    ns.UnitBar.Paint(face, unit)
    ns.UnitBar.Health(face.health, unit)
    face.marks:Set(unit)
    ns.UnitText.Powers(face, unit, ns.UnitBar.Powers(face, unit))
    ns.UnitText.Set(face, unit, face.sample and ns.TEXT.samples[face.unit] or nil)
    Threat(face)
    Row(face)
    ns.UnitAuras.Set(face, unit)
end

local function Heard(face, event)
    if ns.off or face.sample then return end
    local unit = face.unit
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.UnitBar.Health(face.health, unit)
        ns.UnitText.Health(face, unit)
        face.marks:Heard(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then
        face.marks:Heard(unit, event)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        ns.UnitText.Powers(face, unit, ns.UnitBar.Powers(face, unit))
    elseif event == "UNIT_NAME_UPDATE" then
        ns.UnitText.Name(face, unit)
    elseif event == "UNIT_LEVEL" then
        ns.UnitText.Level(face, unit)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        Threat(face)
    else -- friend or foe, its rank, online
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

-- The row's button shown or hidden (its unit came or went, by the game's unit watch, in a fight too): the outline
-- around the frame and its row, or the frame alone.
local function Rowed(face)
    local shown = face.rowButton:IsShown() == true
    if shown == face.rowShown then return end
    face.rowShown = shown
    ns.UnitBar.Fit(face)
    Row(face)
end

-- The game's tooltip for a button's unit, as its own frames show it; none for a sample.
local function Entered(button)
    if Core.EditMode.active then return end
    if GameTooltip_SetDefaultAnchor then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    GameTooltip:SetUnit(button:GetAttribute("unit"))
    GameTooltip:Show()
end
local OnEnter = ns.Guard(Entered)

-- A secure unit button answering as the game's frames do: a click targets its unit, a right click opens the game's
-- menu of it, the tooltip while the mouse is on it. The game takes it for the unit under the mouse (@mouseover).
function Units.Clicks(button)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

local function Button(parent, unit)
    local button = CreateFrame("Button", nil, parent, "SecureUnitButtonTemplate")
    button:SetAttribute("unit", unit)
    Units.Clicks(button)
    return button
end

-- Whether something runs on a frame that would be missed out of sight: its cast, your breath, your other timers.
local function Running(face)
    if face.breath and face.breath.on then return true end
    for _, bar in ipairs(face.above) do
        if bar.on then return true end
    end
    return false
end

-- A frame at rest out of sight (Core.Rest): the mouse on it, its row or its auras shows it. Bar.Fit looks again as a
-- cast or a timer comes or goes.
local function Rests(kind, face)
    local rest = Core.Rest.New({ label = "unit frames", frames = { kind.button },
                                 hold = function() return Running(face) end })
    rest:Hot(kind.button)
    rest:Hot(kind.row.button)
    for _, container in pairs(face.auras) do rest:Area(container) end -- the game's aura containers take no mouse
    kind.rest, face.rest = rest, rest
end

-- A frame: the game's secure unit button, our face on it (as high as the health bar, the rest hanging under it), a
-- window of Core's to place it; its row's button under it.
local function Make(kind)
    local button = Button(UIParent, kind.unit)
    button:SetSize(Units.WIDTH, Units.HEIGHT + Units.POWER)
    button:SetFrameStrata("LOW")
    local face = CreateFrame("Frame", nil, button)
    face:SetPoint("TOPLEFT", button, "TOPLEFT")
    face:SetPoint("TOPRIGHT", button, "TOPRIGHT")
    face:SetHeight(Units.HEIGHT)
    face.unit, face.noName = kind.unit, kind.noName
    ns.UnitBar.Make(face, { health = Units.HEIGHT, power = Units.POWER, row = Units.ROW,
                            rowPower = kind.row.power and Units.ROW_POWER or nil })
    ns.UnitText.Make(face)
    ns.UnitAuras.Make(face)
    ns.UnitCast.Make(face, Units.ROW)
    if kind.bars then ns.UnitTimers.Make(face, Units.POWER) end
    for _, event in ipairs(Units.EVENTS) do pcall(face.RegisterUnitEvent, face, event, kind.unit) end
    for _, event in ipairs(Core.HealthMarks.EVENTS) do pcall(face.RegisterUnitEvent, face, event, kind.unit) end
    face:SetScript("OnEvent", OnEvent)
    face:SetScript("OnSizeChanged", OnSizeChanged)
    button.face = face
    kind.button = button
    local row = Button(button, kind.row.unit)
    row:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    row:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, 0)
    row:SetHeight(Units.ROW + (kind.row.power and Units.ROW_POWER or 0))
    row:Hide()
    -- Its row looked at as it shows or goes, and as the frame shows: the game may hide the row while the frame is
    -- out of sight (its target gone), and a frame out of sight hears no OnHide.
    local rowed = ns.Guard(function() Rowed(face) end)
    row:HookScript("OnShow", rowed)
    row:HookScript("OnHide", rowed)
    button:HookScript("OnShow", rowed)
    face.rowButton, face.rowUnit, face.rowShown = row, kind.row.unit, false
    local colour = kind.row.colour
    if colour then face.row:SetStatusBarColor(colour[1], colour[2], colour[3]) end
    kind.row.button = row
    -- While the row shows (its bar with it), its unit read again now and then.
    local waited = 0
    face.row:SetScript("OnUpdate", ns.Guard(function(_, elapsed)
        waited = waited + elapsed
        if waited < Units.POLL or ns.off then return end
        waited = 0
        Row(face)
    end))
    kind.window = Core.Window.New(button, { store = ns.store, key = kind.place, title = ns.TEXT[kind.option],
                                            first = kind.first })
    kind.window:Place()
    Rests(kind, face)
end

-- What takes the mouse, a frame and all under it, no longer does (each by Lend): clicks and movement, or movement alone.
local function Unmouse(frame, Lend)
    if frame:IsForbidden() then return end
    if frame:IsMouseClickEnabled() then
        Lend(frame, "SetMouse", false)
    elseif frame:IsMouseMotionEnabled() then
        Lend(frame, "SetMotion", false)
    end
    for _, child in ipairs({ frame:GetChildren() }) do Unmouse(child, Lend) end
end

-- The game's frame out of sight (kind.away): "parts" your own frame's picture, bars and texts and its clicks;
-- "parent" your target's or focus's whole, in our hidden frame; "fade" the pet's by its alpha and its clicks; "deaf"
-- a bar of the game's by the events it no longer hears.
local function Away(kind)
    local game = kind.game and rawget(_G, kind.game)
    if kind.lends or type(game) ~= "table" then return end
    kind.lends = {}
    local function Lend(frame, change, ...)
        local lend = Core.Lend(frame)
        lend[change](lend, ...)
        kind.lends[#kind.lends + 1] = lend
    end
    if kind.away == "parent" then return Lend(game, "SetParent", box) end
    if kind.away == "deaf" then return Lend(game, "SetDeaf", kind.events) end
    if kind.away == "parts" then
        for _, key in ipairs(Units.PLAYER_PARTS) do
            local part = rawget(game, key)
            if type(part) == "table" and part.SetAlpha then
                Lend(part, "SetAlpha", 0)
                Unmouse(part, Lend)
            end
        end
        Lend(game, "SetMouse", false)
    else
        Lend(game, "SetAlpha", 0)
        Unmouse(game, Lend)
    end
end

-- The game's frame back as it was.
local function Back(kind)
    local lends = kind.lends
    kind.lends = nil
    for index = #(lends or {}), 1, -1 do ns.Safe("unit frames", lends[index].Return, lends[index]) end
end

-- A frame's cast on as its setting says; on your own frame your timers too, and the game's bars deaf for each; or off
-- and the game's hearing again.
local function Bars(kind, wanted)
    for _, bar in ipairs(kind.bars or {}) do
        if wanted and ns.options[bar.option] ~= false then Away(bar) else Back(bar) end
    end
    if not kind.button then return end
    ns.UnitCast.Set(kind.button.face, wanted and ns.options.unitCast ~= false)
    if kind.bars then ns.UnitTimers.Set(wanted and ns.options.unitBreath ~= false) end
end

-- A button shown by the game's unit watch, or, in Edit Mode, always (a sample where its unit is not there).
local function Watch(button)
    if Core.EditMode.active then
        UnregisterUnitWatch(button)
        button:Show()
    else
        RegisterUnitWatch(button)
    end
end

-- A button hidden and its unit watch off.
local function Unwatch(button)
    if not button then return end
    UnregisterUnitWatch(button)
    button:Hide()
end

-- Whether a frame keeps two power slots: your own, while you may have two powers (a druid, by its forms; in a
-- specialization whose power is not mana but who has mana too). Asked out of a fight: the slots are the button's size.
local function Alternate(kind)
    if kind.unit ~= "player" then return false end
    local _, class = Core.Ask(UnitClass, "player")
    if class == "DRUID" then return true end
    local power = Core.Ask(UnitPowerType, "player")
    local mana = Core.Ask(UnitPowerMax, "player", ns.UnitBar.MANA)
    return type(power) == "number" and power ~= ns.UnitBar.MANA and type(mana) == "number" and mana > 0
end

-- One frame and its row shown and the game's away, or ours hidden and the game's back, as their settings say; at
-- the size the setting Unit frame size says, with the power slots it keeps. Out of a fight.
local function Kind(kind)
    local row = kind.row
    local wanted = not ns.off and ns.options[kind.option] ~= false
    if not wanted then
        if kind.rest then kind.rest:Switch(false) end
        Unwatch(row.button)
        Unwatch(kind.button)
        Back(row)
        Bars(kind, false)
        return Back(kind)
    end
    if not kind.button then Make(kind) end
    local button = kind.button
    button:SetScale((tonumber(ns.options.unitSize) or 100) / 100)
    local face = button.face
    Units.Marks(face)
    face.alternate = Alternate(kind)
    face.slots = face.alternate and 2 or 1
    button:SetHeight(Units.HEIGHT + face.slots * Units.POWER)
    Away(kind)
    Watch(button)
    if ns.options[row.option] ~= false then
        Away(row)
        Watch(row.button)
    else
        Unwatch(row.button)
        Back(row)
    end
    Bars(kind, true)
    Rowed(button.face)
    Fit(button.face)
    Fill(button.face)
    kind.rest:Switch(ns.options.unitRest ~= false)
end

-- Core's marks on a face as the settings say.
function Units.Marks(face)
    local options = ns.options
    face.marks:Switch(options.unitBarrier, options.unitLost, options.unitDispel)
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

-- A frame's unit changed (whole: your target; or only its row's: your target's target, your pet).
local function Changed(unit, rowOnly)
    if ns.off then return end
    for _, kind in ipairs(Units.KINDS) do
        local face = kind.button and kind.button.face
        if face and kind.unit == unit then
            if rowOnly then
                Row(face)
            else
                Fill(face)
                ns.UnitCast.Anew(face)
            end
        end
    end
end

function Units.Start()
    ns.UnitTimers.Start()
    ns.On("PLAYER_TARGET_CHANGED", function() Changed("target") end)
    ns.On("PLAYER_FOCUS_CHANGED", function() Changed("focus") end)
    ns.On("UNIT_TARGET", function(unit) Changed(unit, true) end)
    ns.On("UNIT_PET", function(unit) if unit == "player" then Changed("player", true) end end)
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
    -- Another specialization may have another power: your frame's slots anew (after a fight).
    ns.On("PLAYER_SPECIALIZATION_CHANGED", Core.Later(Units.Apply))
    -- In Edit Mode every frame and row shows whether its unit is there or not (as a sample), to be placed; after it,
    -- as the game's unit watch says again.
    Core.EditMode.Watch(ns.Guard(Units.Apply))
    Units.Apply()
end

-- Standing down: ours out of sight at once (their alpha may change in a fight), hidden and their unit watch off
-- after it; the game's frames back (Core.Lend gives back after a fight what may not change in one).
function Units.GiveBack()
    for _, kind in ipairs(Units.KINDS) do
        local button = kind.button
        if button then
            ns.Safe("unit frames", kind.rest.Switch, kind.rest, false)
            button:SetAlpha(0)
            Core.AfterCombat("unit frame " .. kind.unit, function()
                Unwatch(kind.row.button)
                Unwatch(button)
            end)
        end
        ns.Safe("unit frames", Back, kind.row)
        ns.Safe("unit frames", Bars, kind, false)
        ns.Safe("unit frames", Back, kind)
        if button then
            ns.Safe("unit frames", ns.UnitAuras.Set, button.face, nil)
            ns.Safe("unit frames", button.face.marks.Set, button.face.marks, nil)
        end
    end
end
