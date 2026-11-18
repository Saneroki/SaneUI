local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Units
--  Our own frames for you, your target and your focus, each in place of the
--  game's own, in the look of a nameplate (Bar.lua, Text.lua): a round green
--  health bar (your target's and your focus's red while you can attack it),
--  the level and the raid marker on its left, the name after them
--  (a player's first name and surname; none on your own frame), the health and
--  how much is left on its right; under it the unit's power at half its height
--  with the same words on its left (your own druid's mana always, Saneroki,
--  2026-11-13: in a form whose power is not mana your mana first and the
--  form's rage or energy under it, Core.FormPower; so your own where you have
--  mana beside another power; the frame keeps a slot for each, Slots; the game
--  tells another druid's mana in a form to nobody else, so its frame shows
--  the one power it shows now);
--  around it the auras that matter most (Auras.lua). Under each, as a cast bar
--  under a nameplate, a row while its unit is there, with that unit's name
--  alone: your target's target under your target's frame, your focus's target
--  under your focus's; under yours your pet, its power under its row. Directly
--  above each health bar its unit's cast while it casts (Cast.lua), over that
--  on your own frame the game's timers on you, your breath over the health bar
--  itself (Timers.lua). Floating over the name, from the health leftwards, the
--  icons of your auras shown on the health bars (Reminders/Group.lua, as on the
--  party and raid frames), read at each fill and at each UNIT_AURA of its unit.
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
--  without a frame (Core.Window): placed in the game's Edit Mode, where a click
--  on its box opens its dialog (Core's Selection.lua) with its width and what it
--  shows, a tick each (Saneroki, 2026-11-18: "options there where you can
--  define the width of the unit frames and where you can define in edit mode
--  what each frame includes"; each frame its own: Settings, face.show,
--  Text.lua), and every frame and row shows a made-up preview, a real unit
--  there or not ("show how the frames look as preview with target of target,
--  pets, fatigue, breath and if you are a druid show 2 class resource
--  previews"; Preview): a foe of yours a level above you, elite, a skull on it,
--  its target you; a player as your focus, with an item level, its target a
--  creature; your own frame with your pet, your cast, your breath and fatigue,
--  and your two powers where you may have two (a druid's mana and energy).
--  The setup's samples are the same faces (Units.Sample; Saneroki, 2026-11-18:
--  the setup's preview "does not represent the unit frames at all"): on a
--  plain frame of its board, no button, no events, no window, filled as that
--  preview fills them.
--
--  The game's own frames go out of sight while ours show, nothing of theirs
--  written: your target's and focus's frame stand in a hidden frame of ours
--  (Core.Lend: their parent given back exactly), and with them what hangs on
--  them (their auras, cast bars and their own target's frames, Forever's combo
--  points: on its nameplate there); of your own frame only its picture, bars
--  and texts (their alpha) and its clicks; what hangs under it stays the
--  game's, the totems and a class's resource bar, and follows ours: their
--  holder anchored under our frame (Hang; Saneroki, 2026-11-18). The game's pet
--  frame, which its layout puts back under its own parent, by its alpha and
--  its clicks too. What lies under those takes the mouse no more either
--  (Unmouse): a frame at alpha 0 still does, and the game's health and power
--  bars would hold it off the world. Your own frame's and the pet frame's
--  boxes in Edit Mode too: they ignore their frame's alpha, so they would stand
--  there to be placed for nothing (Unbox); ours are placed instead, and the
--  totems with ours. The game's own frame stays where it was. The game's cast
--  bars and timers hear nothing while ours stand in for them (Core.Lend's
--  SetDeaf): the game shows and lays those out itself.
--
--  Out of sight at rest (Core.Rest; Saneroki, 2026-11-01), each frame by its
--  own three (Saneroki, 2026-11-18): Show only on mouseover (off at first:
--  always in sight), and under it Always show in combat and Always show in a
--  group (on at first). Chosen in its Edit Mode dialog and the setup. Each
--  frame goes by its alpha, its button still taking the mouse, so the mouse on
--  a frame, its row or its auras shows that frame alone; a cast or a timer
--  running on it shows it too (the game's own bars for those are gone, and you
--  need your breath under water). In combat: a fight, your health and your
--  resource not full, death.
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
Units.ICON = 16  -- an aura's icon over the name, square
-- Each frame: its unit, its setting, the game's frame it stands for and how that goes out of sight (Away), its place's
-- key and first place (from the screen's bottom middle, above the action bars, side by side: you in the middle, your
-- focus left of you, your target right, as Saneroki arranged them, 2026-11-18; by the button's top: the health bar's,
-- the same whatever height the button has), whether
-- its health is red on a foe (foes), and its row: the same of the unit under it, its bar's colour (none: green), and
-- whether its power shows under it. Your own frame's bars: the game's frames that go deaf for them, each with its setting and
-- what it no longer hears.
Units.KINDS = {
    { unit = "player", option = "unitPlayer", game = "PlayerFrame", away = "parts",
      place = "playerPlace", first = { point = "TOP", relative = "BOTTOM", x = 0, y = 249.5 },
      row = { unit = "pet", option = "unitPet", game = "PetFrame", away = "fade", power = true },
      bars = { { option = "unitCast", game = "PlayerCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitCast", game = "OverlayPlayerCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitCast", game = "PetCastingBarFrame", away = "deaf", events = ns.UnitCast.GAME },
               { option = "unitBreath", game = "MirrorTimerContainer", away = "deaf", events = ns.UnitTimers.EVENTS } } },
    { unit = "target", option = "unitTarget", game = "TargetFrame", away = "parent", foes = true,
      place = "targetPlace", first = { point = "TOP", relative = "BOTTOM", x = 240, y = 249.5 },
      row = { unit = "targettarget", option = "unitTargetTarget", colour = ns.UnitBar.CALM } },
    { unit = "focus", option = "unitFocus", game = "FocusFrame", away = "parent", foes = true,
      place = "focusPlace", first = { point = "TOP", relative = "BOTTOM", x = -240, y = 249.5 },
      row = { unit = "focustarget", option = "unitFocusTarget", colour = ns.UnitBar.CALM } },
}
-- Of your own frame (PlayerFrame), the parts out of sight: its picture, and its bars and texts.
Units.PLAYER_PARTS = { "PlayerFrameContainer", "PlayerFrameContent" }
-- What each face hears of its unit.
Units.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
                 "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_FACTION", "UNIT_FLAGS", "UNIT_CLASSIFICATION_CHANGED",
                 "UNIT_CONNECTION", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_AURA" }
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

-- What Edit Mode shows on each frame and its row, made up (Units.Preview): a share of health of the most, the powers
-- (each { token, share }; the player's own: its power, and as a druid or where it may have two, mana first), the
-- level (above: that much over yours; mine: yours), the rank, the raid marker, a player's item level and class, and the
-- row's (its name: your own, a foe, your pet's; a pet's power).
Units.PREVIEW = {
    player = { mine = true, health = 0.82, most = 4200, row = { pet = true, health = 0.9, most = 1200, power = { "FOCUS", 0.6 } } },
    target = { foe = true, above = 1, rank = "elite", mark = 8, health = 0.62, most = 1850, powers = { { "RAGE", 0.35 } },
               row = { you = true, health = 0.82 } },
    focus = { player = true, class = "PRIEST", gear = 32, health = 0.94, most = 3100, powers = { { "MANA", 0.7 } },
              row = { foe = true, health = 0.45 } },
}
Units.SECOND = "ENERGY" -- a druid's second power in the preview: its Cat Form's

-- The made-up row under the frame (its name, health and its pet's power), as it shows in Edit Mode.
local function RowPreview(face)
    local spec = Units.PREVIEW[face.unit]
    local row = spec and spec.row
    if not row then return end
    local names = ns.TEXT.groupSamples
    local name = row.you and Core.FullName("player") or row.foe and names.foes[1] or row.pet and names.pets[1] or ""
    face.row:SetMinMaxValues(0, 1)
    face.row:SetValue(row.health or 1)
    ns.UnitText.Row(face, nil, type(name) == "string" and name or "")
    local bar = face.rowPower
    if not bar then return end
    local on = row.power ~= nil
    if on then
        local most = row.most or 1
        local now = math.floor(most * row.power[2])
        bar:SetStatusBarColor(ns.UnitBar.PowerColour(row.power[1]))
        bar:SetMinMaxValues(0, most)
        bar:SetValue(now)
        ns.UnitText.PowerSample(face, 0, now, most)
    end
    if on ~= bar.on then
        bar.on = on
        ns.UnitBar.Fit(face)
    end
end

-- The row's unit as the game says it now, while the row shows; in Edit Mode its preview.
local function Row(face)
    if not face.rowShown then return end
    local unit = face.rowUnit
    face.rowSample = face.board or Core.EditMode.active -- a setup's sample (Units.Sample): always made up
    if face.rowSample then return RowPreview(face) end
    if not Core.Ask(UnitExists, unit) then return end
    ns.UnitBar.Health(face.row, unit)
    ns.UnitText.RowPower(face, unit, ns.UnitBar.RowPower(face, unit))
    ns.UnitText.Row(face, unit)
end

-- Your auras on the health bars over the face, as its unit has them: those shown on your unit frames
-- (Reminders/Group.lua, Unit frames); none on a sample.
local function Buffs(face)
    if ns.off or not face.icons then return end
    local real = not face.sample and Core.Ask(UnitExists, face.unit)
    ns.GroupReminders.Show(face, real and face.unit or nil, ns.Reminders.FRAMES)
end
Units.Buffs = Buffs

-- Every frame's face, each with its fn.
function Units.Each(fn)
    for _, kind in ipairs(Units.KINDS) do
        if kind.button then fn(kind.button.face) end
    end
end

-- The power slots a frame keeps under its health bar, and its button's height with them: two on your own while you may
-- have two powers (Alternate), else as many as its unit shows now (you as your own target or focus, a druid in a form:
-- your mana and the form's). A secure button changes its size out of a fight only: in one the bars show at once, and
-- the button (with the row's under it) follows once the fight is over.
local function Wanted(face)
    return face.alternate and 2 or math.max(face.powersShown or 1, 1)
end
local function Slots(face)
    if Wanted(face) == face.slots then return end
    if face.board then -- a setup's sample (Units.Sample): no button to size, nothing secure
        face.slots = Wanted(face)
        return ns.UnitBar.Fit(face)
    end
    Core.AfterCombat("unit frame slots " .. face.unit, function()
        face.slots = Wanted(face)
        face:GetParent():SetHeight(Units.HEIGHT + face.slots * Units.POWER)
        ns.UnitBar.Fit(face)
    end)
end

-- The unit's powers, their words, and the slots for them.
local function Powers(face, unit)
    ns.UnitText.Powers(face, unit, ns.UnitBar.Powers(face, unit))
    Slots(face)
end

-- The made-up powers of a frame's preview: its own, or for your frame your power, as a druid (or where you may have
-- two) your mana first and the second under it.
local function PreviewPowers(face, spec)
    if not spec.mine then return spec.powers or {} end
    local _, token = Core.Ask(UnitPowerType, "player")
    token = type(token) == "string" and token or "MANA"
    if not face.alternate then return { { token, 0.6 } } end
    local _, class = Core.Ask(UnitClass, "player")
    local second = class == "DRUID" and Units.SECOND or (token ~= "MANA" and token or Units.SECOND)
    return { { "MANA", 0.7 }, { second, 0.55 } }
end

-- Every frame in Edit Mode, a real unit there or not: made up as Units.PREVIEW says, every piece it shows (face.show),
-- so a choice in its dialog shows at once. Your own frame keeps your level, name and item level.
local function Preview(face)
    local spec = Units.PREVIEW[face.unit]
    if not spec then return end
    local Bar, Text = ns.UnitBar, ns.UnitText
    local names = ns.TEXT.groupSamples
    local mine = Core.Ask(UnitLevel, "player")
    mine = type(mine) == "number" and mine or 1
    local health = spec.foe and Bar.HOSTILE or Bar.GREEN
    face.health:SetStatusBarColor(health[1], health[2], health[3])
    local rank = Bar.RANKS[spec.rank] or Bar.PLAIN
    if rank ~= face.rank then
        face.rank = rank
        Bar.Fit(face)
    end
    local colour = rank.colour
    if colour then face.rankLine:SetVertexColor(colour[1], colour[2], colour[3], colour[4]) end
    face.rankLine:SetShown(colour ~= nil)
    face.danger = false
    Bar.Glow(face, false)
    local most = spec.most or 1
    local now = math.floor(most * (spec.health or 1))
    face.health:SetMinMaxValues(0, most)
    face.health:SetValue(now)
    face.marks:Set("player") -- barriers, lost health and dispels as yours are, as the samples always had them
    local powers = PreviewPowers(face, spec)
    for index, power in ipairs(powers) do
        local bar = face.powers[index]
        if bar then
            local full = 100
            local value = math.floor(full * power[2])
            bar:SetStatusBarColor(Bar.PowerColour(power[1]))
            bar:SetMinMaxValues(0, full)
            bar:SetValue(value)
            Text.PowerSample(face, index, value, full)
        end
    end
    if #powers ~= face.powersShown then
        face.powersShown = #powers
        Bar.Fit(face)
    end
    Slots(face)
    Text.ShowLevel(face, spec.mine and mine or math.min(mine + (spec.above or 0), Text.MaxLevel()), spec.foe == true)
    Text.Mark(face, Text.Shows(face, "mark") and spec.mark or nil)
    local name, gear
    if spec.mine then
        name = Core.FullName("player")
        gear = Core.Inspect.Level("player", Core.Ask(UnitGUID, "player"))
    elseif spec.player then
        name, gear = names.first[2] .. " " .. names.last[3], spec.gear
    else
        name = names.foes[3]
    end
    Text.ShowGear(face, Text.Shows(face, "gear") and gear or nil)
    Text.Name(face, nil, type(name) == "string" and name or "")
    Text.Sample(face, now, most)
    Row(face)
    if face.board then return end -- a setup's sample: the frame's bars and words, no auras
    ns.UnitAuras.Set(face, "player")
    Buffs(face)
end

-- Everything for the face's unit as the game says it now; in Edit Mode its preview.
local function Fill(face)
    face.sample = Core.EditMode.active
    if face.sample then return Preview(face) end
    local unit = face.unit
    if not Core.Ask(UnitExists, unit) then return end
    ns.UnitBar.Paint(face, unit)
    ns.UnitBar.Health(face.health, unit)
    face.marks:Set(unit)
    Powers(face, unit)
    ns.UnitText.Set(face, unit)
    Threat(face)
    Row(face)
    ns.UnitAuras.Set(face, unit)
    Buffs(face)
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
        Powers(face, unit)
    elseif event == "UNIT_NAME_UPDATE" then
        ns.UnitText.Name(face, unit)
    elseif event == "UNIT_LEVEL" then
        ns.UnitText.Level(face, unit)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        Threat(face)
    elseif event == "UNIT_AURA" then
        ns.GroupReminders.Heard(unit) -- in a fight: when its auras changed, for your cast
        Buffs(face)
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
    rest:Area(face.aurasArea) -- the game's aura containers take no mouse, and it may hide their size
    kind.rest, face.rest = rest, rest
    ns.AuraRow.Doors(face)
end

-- A frame's settings in its Edit Mode dialog (Core's Selection.lua): its width and what it shows, each a key of the
-- module's settings (Combat.lua, ns.FRAME_SHOWS: the frame's setting and the suffix), the level's top under the level.
local function Settings(kind)
    local list = {}
    for _, entry in ipairs(ns.FRAME_SHOWS) do
        local text = entry.text
        if entry.top then text = text:format(ns.UnitText.MaxLevel()) end
        list[#list + 1] = { key = kind.option .. entry.suffix, text = text, min = entry.min, max = entry.max,
                            step = entry.step, check = entry.min == nil or nil,
                            parent = entry.under and (kind.option .. entry.under) or nil }
    end
    return list
end

-- What a frame shows, as its settings say (Text.lua reads it; face.show).
local function Shows(kind)
    local show, options = {}, ns.options
    for _, entry in ipairs(ns.FRAME_SHOWS) do
        if entry.show then show[entry.show] = options[kind.option .. entry.suffix] end
    end
    return show
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
    face.unit, face.foes = kind.unit, kind.foes
    ns.UnitBar.Make(face, { health = Units.HEIGHT, power = Units.POWER, row = Units.ROW,
                            rowPower = kind.row.power and Units.ROW_POWER or nil })
    ns.UnitText.Make(face)
    face.floating = CreateFrame("Frame", nil, face) -- over the words: your auras' icons
    face.floating:SetAllPoints(face)
    face.floating:SetFrameLevel((Core.Plain(face.top:GetFrameLevel()) or 1) + 1)
    face.icons, face.missing, face.iconSize, face.roomed = {}, {}, Units.ICON, ns.GroupFace.Roomed
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
                                            first = kind.first, settings = Settings(kind),
                                            get = function(key) return ns.options[key] end,
                                            set = function(key, value) Core.Set(ns.name, key, value) end })
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

-- A frame's box in Edit Mode (its Selection, EditModeSystemSelectionBaseTemplate) unseen and taking no click: it
-- ignores its frame's alpha, so it would stand there to be placed for nothing. Ours is placed there instead.
local function Unbox(game, Lend)
    local selection = rawget(game, "Selection")
    if type(selection) ~= "table" or not selection.SetAlpha then return end
    Lend(selection, "SetAlpha", 0)
    Unmouse(selection, Lend)
end

-- What the game hangs under your own frame (its totems, a class's resource bar: each laid out by the game in its
-- holder there, PlayerBottomManagedFrameContainer) under ours instead, by the holder's anchor and its scale alone:
-- as large as ours (the setting Unit frame size; Saneroki, 2026-11-18), whatever size the game's own frame has
-- (Size). What it holds stays the game's, its clicks too. The game anchors it under its own frame again
-- (PlayerFrame_ToPlayerArt at each loading screen, a vehicle's art): under ours again at once (Moved), or once the
-- fight is over where the holder is protected then (with the game's pet frame in it).
Units.UNDER = "PlayerBottomManagedFrameContainer"
local under, beneath, hooked -- the holder's lend while ours stands in, our button it hangs under, its hook made

local function Under(holder)
    holder:ClearAllPoints()
    holder:SetPoint("TOP", beneath, "BOTTOM", 0, 0)
end

local function Moved()
    if not under then return end
    local ok, _, relative = pcall(under.frame.GetPoint, under.frame, 1)
    if ok and relative == beneath then return end -- ours, or already under ours
    if not under:SetPoints(Under) then Core.AfterCombat("unit frame totems", Moved) end
end

-- The holder's scale in its parent's (the game's frame, at the size Edit Mode gives it): ours on the screen.
local function Size()
    if not under then return end
    local holder = under.frame
    local parent = holder:GetParent()
    local ours = tonumber(Core.Plain(beneath:GetEffectiveScale()))
    local theirs = parent and tonumber(Core.Plain(parent:GetEffectiveScale()))
    if not ours or not theirs or theirs <= 0 then return end
    local scale = ours / theirs
    if math.abs((tonumber(Core.Plain(holder:GetScale())) or 1) - scale) < 0.001 then return end
    if not under:SetScale(scale) then Core.AfterCombat("unit frame totems size", Size) end
end

local function Hang(kind, Lend)
    local holder = rawget(_G, Units.UNDER)
    if type(holder) ~= "table" or not holder.SetPoint or not kind.button then return end
    beneath = kind.button
    under = Lend(holder, "SetPoints", Under)
    Size()
    if not hooked then
        hooked = true
        hooksecurefunc(holder, "SetPoint", ns.Guard(Moved))
    end
end

-- The game's frame out of sight (kind.away): "parts" your own frame's picture, bars and texts and its clicks;
-- "parent" your target's or focus's whole, in our hidden frame; "fade" the pet's by its alpha and its clicks; "deaf"
-- a bar of the game's by the events it no longer hears. With "parts" and "fade" its box in Edit Mode too (Unbox).
local function Away(kind)
    local game = kind.game and rawget(_G, kind.game)
    if kind.lends or type(game) ~= "table" then return end
    kind.lends = {}
    local function Lend(frame, change, ...)
        local lend = Core.Lend(frame)
        lend[change](lend, ...)
        kind.lends[#kind.lends + 1] = lend
        return lend
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
        Unbox(game, Lend)
        Hang(kind, Lend)
    else
        Lend(game, "SetAlpha", 0)
        Unbox(game, Lend)
        Unmouse(game, Lend)
    end
end

-- The game's frame back as it was.
local function Back(kind)
    local lends = kind.lends
    kind.lends = nil
    if kind.away == "parts" then under = nil end -- the holder no longer kept under ours, given back as it was
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

-- Whether a frame keeps two power slots and shows your mana beside another power: your own, while you may have two
-- powers (a druid, by its forms; in a specialization whose power is not mana but who has mana too); you as your target
-- or focus show both too (Core.FormPower). Asked out of a fight.
local function Alternate(kind)
    if kind.unit ~= "player" then return false end
    local _, class = Core.Ask(UnitClass, "player")
    if class == "DRUID" then return true end
    local power = Core.Ask(UnitPowerType, "player")
    local mana = Core.Ask(UnitPowerMax, "player", ns.UnitBar.MANA)
    return type(power) == "number" and power ~= ns.UnitBar.MANA and type(mana) == "number" and mana > 0
end

-- One frame and its row shown and the game's away, or ours hidden and the game's back, as their settings say; at
-- the size the setting Unit frame size says. Out of a fight.
local function Kind(kind)
    local row = kind.row
    local wanted = not ns.off and ns.options.units ~= false and ns.options[kind.option] ~= false -- the part, then the frame
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
    button:SetWidth(tonumber(ns.options[kind.option .. "Width"]) or Units.WIDTH) -- its own (Edit Mode's dialog)
    local face = button.face
    face.show = Shows(kind)
    ns.UnitText.PowerSide(face) -- its resource numbers at the left or the right, as its tick says
    Units.Marks(face)
    face.alternate = Alternate(kind)
    Slots(face)
    Away(kind)
    if kind.away == "parts" then Size() end -- the totems as large as your frame, also when its size changes
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
    local options, key = ns.options, kind.option -- when it shows: its own three (Combat.lua, ns.FRAME_SHOWS)
    kind.rest:InGroup(options[key .. "Group"] == false)
    kind.rest:Fight(options[key .. "Fight"] ~= false)
    kind.rest:Switch(options[key .. "Mouseover"] == true)
end

-- Core's marks on a face as the settings say.
function Units.Marks(face)
    local options = ns.options
    face.marks:Switch(options.unitBarrier, options.unitLost, options.unitDispel)
end

-- A frame as it looks, for the setup's board (Setup.lua): our face on a plain frame of the board's, made once a board
-- and unit (no button, no events, no window, no rest), at the frame's own width, showing what its settings show, its
-- resource numbers on their side, your two powers where you may have two, and its row under it while that is on (your
-- pet, your target's target, your focus's target), filled as Edit Mode's preview fills it (Preview). Nil for a unit
-- with no frame of ours.
function Units.Sample(parent, unit)
    local kind
    for _, each in ipairs(Units.KINDS) do
        if each.unit == unit then kind = each end
    end
    if not kind then return nil end
    parent.unitSamples = parent.unitSamples or {}
    local face = parent.unitSamples[unit]
    if not face then
        face = CreateFrame("Frame", nil, parent)
        face:SetSize(Units.WIDTH, Units.HEIGHT)
        face.unit, face.foes, face.board, face.sample = kind.unit, kind.foes, true, true
        ns.UnitBar.Make(face, { health = Units.HEIGHT, power = Units.POWER, row = Units.ROW,
                                rowPower = kind.row.power and Units.ROW_POWER or nil })
        ns.UnitText.Make(face)
        face:SetScript("OnSizeChanged", OnSizeChanged)
        parent.unitSamples[unit] = face
    end
    face:SetWidth(tonumber(ns.options[kind.option .. "Width"]) or Units.WIDTH)
    face.show = Shows(kind)
    ns.UnitText.PowerSide(face)
    Units.Marks(face)
    face.alternate = Alternate(kind)
    face.rowShown = ns.options[kind.row.option] ~= false
    Fit(face)
    Preview(face)
    return face
end

local function Apply()
    if not box then
        box = CreateFrame("Frame", nil, UIParent)
        box:Hide()
    end
    for _, kind in ipairs(Units.KINDS) do ns.Guarded(Kind, kind) end
    ns.Guarded(ns.LookOut.Apply) -- in your focus's place while you have none (LookOut.lua)
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
    ns.AuraRow.Start()
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
    -- A player's item level came (inspected): on the frames of that player, where they show it.
    Core.Inspect.Watch(ns.Guard(function(guid)
        if ns.off or Core.EditMode.active then return end
        for _, kind in ipairs(Units.KINDS) do
            local face = kind.button and kind.button.face
            if face and Core.Ask(UnitGUID, kind.unit) == guid then ns.UnitText.Gear(face, kind.unit) end
        end
    end))
    -- Once the world shows (the game's fonts and scales set up, also after a /reload), every frame measured anew.
    ns.On("PLAYER_ENTERING_WORLD", Core.Later(function()
        if ns.off then return end
        for _, kind in ipairs(Units.KINDS) do
            if kind.button then Fit(kind.button.face) end
        end
        Again()
    end, 0.5))
    ns.On("UI_SCALE_CHANGED", Core.Later(Units.Apply))
    -- Another specialization may have another power: whether your frame shows your mana beside it, anew (after a fight).
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
    ns.Safe("look out", ns.LookOut.GiveBack)
end
