local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units
--  Our own frames for you, your target and your focus, each in place of the
--  game's own, in the look of a nameplate (Bar.lua, Text.lua): a round green
--  bar with the unit's power along the bottom; inside it the level and the
--  raid marker on the left, the name after them (a player's first name and
--  surname; none on your own frame), the health and how much is left on the
--  right. Under each, as a cast bar under a nameplate, a row while its unit is
--  there, with that unit's name alone: your target's target under your
--  target's frame, your focus's target under your focus's, your pet under
--  yours.
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
--  game's: the totems, the cast bar and a class's resource bar. The game's pet
--  frame, which its layout puts back under its own parent, by its alpha and
--  its clicks too.
--
--  Secure frames are made, shown, moved, sized and given back out of a fight
--  only: what is asked for in one waits for its end (Core.AfterCombat). Off
--  (each frame's and row's setting) or standing down, the game's frame is back.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Units = {}
ns.Units = Units

Units.WIDTH, Units.HEIGHT = 240, 26 -- a frame's size at 100 % (the setting Unit frame size scales it)
Units.ROW = 18   -- a row's height under it
Units.POLL = 0.2 -- seconds between two readings of a shown row's unit
-- Each frame: its unit, its setting, the game's frame it stands for and how that goes out of sight (Away), its place's
-- key and first place (from the screen's bottom middle, above the action bars: you left of the middle, your target
-- right, your focus above it), and its row: the same of the unit under it.
Units.KINDS = {
    { unit = "player", option = "unitPlayer", game = "PlayerFrame", away = "parts", noName = true,
      place = "playerPlace", first = { point = "BOTTOM", x = -190, y = 230 },
      row = { unit = "pet", option = "unitPet", game = "PetFrame", away = "fade" } },
    { unit = "target", option = "unitTarget", game = "TargetFrame", away = "parent",
      place = "targetPlace", first = { point = "BOTTOM", x = 190, y = 230 },
      row = { unit = "targettarget", option = "unitTargetTarget" } },
    { unit = "focus", option = "unitFocus", game = "FocusFrame", away = "parent",
      place = "focusPlace", first = { point = "BOTTOM", x = 190, y = 290 },
      row = { unit = "focustarget", option = "unitFocusTarget" } },
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
    ns.UnitBar.Power(face, unit)
    ns.UnitText.Set(face, unit, face.sample and ns.TEXT.samples[face.unit] or nil)
    Threat(face)
    Row(face)
end

local function Heard(face, event)
    if ns.off or face.sample then return end
    local unit = face.unit
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.UnitBar.Health(face.health, unit)
        ns.UnitText.Health(face, unit)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        ns.UnitBar.Power(face, unit)
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

-- A secure unit button for a unit: a click targets it, a right click opens the game's menu of it.
local function Button(parent, unit)
    local button = CreateFrame("Button", nil, parent, "SecureUnitButtonTemplate")
    button:SetAttribute("unit", unit)
    button:SetAttribute("*type1", "target")
    button:SetAttribute("*type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- A frame: the game's secure unit button, our face on it, a window of Core's to place it; its row's button under it.
local function Make(kind)
    local button = Button(UIParent, kind.unit)
    button:SetSize(Units.WIDTH, Units.HEIGHT)
    button:SetFrameStrata("LOW")
    local face = CreateFrame("Frame", nil, button)
    face:SetAllPoints(button)
    face.unit, face.noName = kind.unit, kind.noName
    ns.UnitBar.Make(face, Units.ROW)
    ns.UnitText.Make(face)
    for _, event in ipairs(Units.EVENTS) do pcall(face.RegisterUnitEvent, face, event, kind.unit) end
    face:SetScript("OnEvent", OnEvent)
    face:SetScript("OnSizeChanged", OnSizeChanged)
    button.face = face
    kind.button = button
    local row = Button(button, kind.row.unit)
    row:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, 0)
    row:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, 0)
    row:SetHeight(Units.ROW)
    row:Hide()
    -- Its row looked at as it shows or goes, and as the frame shows: the game may hide the row while the frame is
    -- out of sight (its target gone), and a frame out of sight hears no OnHide.
    local rowed = ns.Guard(function() Rowed(face) end)
    row:HookScript("OnShow", rowed)
    row:HookScript("OnHide", rowed)
    button:HookScript("OnShow", rowed)
    face.rowButton, face.rowUnit, face.rowShown = row, kind.row.unit, false
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
end

-- The game's frame out of sight (kind.away): "parts" your own frame's picture, bars and texts and its clicks;
-- "parent" your target's or focus's whole, in our hidden frame; "fade" the pet's by its alpha and its clicks.
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
    if kind.away == "parts" then
        for _, key in ipairs(Units.PLAYER_PARTS) do
            local part = rawget(game, key)
            if type(part) == "table" and part.SetAlpha then Lend(part, "SetAlpha", 0) end
        end
    else
        Lend(game, "SetAlpha", 0)
    end
    Lend(game, "SetMouse", false)
end

-- The game's frame back as it was.
local function Back(kind)
    local lends = kind.lends
    kind.lends = nil
    for index = #(lends or {}), 1, -1 do ns.Safe("unit frames", lends[index].Return, lends[index]) end
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

-- One frame and its row shown and the game's away, or ours hidden and the game's back, as their settings say; at
-- the size the setting Unit frame size says. Out of a fight.
local function Kind(kind)
    local row = kind.row
    local wanted = not ns.off and ns.options[kind.option] ~= false
    if not wanted then
        Unwatch(row.button)
        Unwatch(kind.button)
        Back(row)
        return Back(kind)
    end
    if not kind.button then Make(kind) end
    local button = kind.button
    button:SetScale((tonumber(ns.options.unitSize) or 100) / 100)
    Away(kind)
    Watch(button)
    if ns.options[row.option] ~= false then
        Away(row)
        Watch(row.button)
    else
        Unwatch(row.button)
        Back(row)
    end
    Rowed(button.face)
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

-- A frame's unit changed (whole: your target; or only its row's: your target's target, your pet).
local function Changed(unit, rowOnly)
    if ns.off then return end
    for _, kind in ipairs(Units.KINDS) do
        local face = kind.button and kind.button.face
        if face and kind.unit == unit then
            if rowOnly then Row(face) else Fill(face) end
        end
    end
end

function Units.Start()
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
            button:SetAlpha(0)
            Core.AfterCombat("unit frame " .. kind.unit, function()
                Unwatch(kind.row.button)
                Unwatch(button)
            end)
        end
        ns.Safe("unit frames", Back, kind.row)
        ns.Safe("unit frames", Back, kind)
    end
end
