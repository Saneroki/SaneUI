local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Plate
--  Our dress on each plate the game shows: a frame of ours on the game's plate
--  (so it follows the plate's place, scale and fading), laid exactly over the
--  game's health bar row (HealthBarsContainer: its size is the game's nameplate
--  size and style), holding our bar (Bar.lua), the name above it, the auras
--  above the name (Auras.lua), the marks right of it (Marks.lua) and, on your
--  target, the combo points (Resource.lua).
--
--  The game's parts ours stand in for (its health bar row, name, auras, raid
--  marker and classification mark) go out of sight while ours shows: their
--  alpha 0, set by calls only, nothing of theirs written, and 1 again when the
--  plate goes, when its health bar goes (a friendly player shown by name only,
--  a plate of widgets only: the game's own plate then stays as it is) and when
--  the module stands down. The rest of the game's plate stays: its cast bar,
--  level box, threat glow, widgets and soft target icon, and what clicks it.
--
--  One dress per plate, made the first time the game shows it and kept: the
--  game hands its plates out again for other units, and takes its unit frames
--  from a pool (a plate can get another one each time). Each dress listens to
--  its own unit's events (RegisterUnitEvent: the game sends it that unit's
--  only), from NAME_PLATE_UNIT_ADDED to _REMOVED. Plates the game keeps from
--  addons (in some places) and your own have none.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Plate = {}
ns.Plate = Plate

-- The parts of the game's plate (keys of its unit frame) ours stand in for.
Plate.HIDDEN = { "HealthBarsContainer", "name", "AurasFrame", "RaidTargetFrame", "ClassificationFrame" }
-- The game's own: the gap between the health bar and the name above it, and its plates' font for names.
Plate.NAME_GAP = 2
Plate.FONTS = { "SystemFont_NamePlate_Outlined", "SystemFont_NamePlate", "GameFontHighlightSmall" }
-- What each dress hears of its own unit.
Plate.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_NAME_UPDATE", "UNIT_FACTION", "UNIT_FLAGS",
                 "UNIT_CLASSIFICATION_CHANGED" }

local dresses = {} -- [the game's plate] = our dress on it
local shown = {}   -- [unit token] = the dress on that unit's plate, while the game shows it
local owners = setmetatable({}, { __mode = "k" }) -- [the game's unit frame] = the dress over it now
local bars = setmetatable({}, { __mode = "k" })   -- [the game's health bar] = its unit frame, once followed

local function Font()
    for _, name in ipairs(Plate.FONTS) do
        if rawget(_G, name) then return name end
    end
    return nil
end

-- The game's plate for a unit, where addons may have it; nil for one it keeps from them.
local function PlateOf(unit)
    local plate = Core.Ask(C_NamePlate.GetNamePlateForUnit, unit)
    return type(plate) == "table" and plate or nil
end

-- The border's light for a plate: your target's, your focus's, or none.
local function Lit(plate, target, focus)
    if plate == target then return "target" end
    if plate == focus then return "focus" end
    return nil
end

local function Name(dress, unit)
    local text = Plain(UnitIsPlayer(unit)) and Core.FullName(unit)
    if type(text) ~= "string" then text = ns.Bar.Raw(UnitName, unit) end -- hidden or not: the text takes it
    if type(text) == "nil" then text = "" end
    dress.name:SetText(text)
end

-- Everything for the dress's unit, as the game says it now.
local function Fill(dress)
    local unit = dress.unit
    ns.Bar.Paint(dress, unit)
    ns.Bar.Health(dress, unit)
    ns.Bar.Border(dress, Lit(dress.plate, PlateOf("target"), PlateOf("focus")))
    Name(dress, unit)
    ns.Marks.Rare(dress, unit)
    ns.Marks.Raid(dress, unit)
    ns.Auras.Set(dress, unit)
end

-- Ours shown and the game's parts out of sight while the game shows its health bar on the plate; the game's
-- own plate as it is otherwise.
local function Wear(dress)
    local frame = dress.frame
    local row = frame and rawget(frame, "HealthBarsContainer")
    local bar = type(row) == "table" and rawget(row, "healthBar")
    local on = not ns.off and dress.unit ~= nil and type(bar) == "table" and Plain(bar:IsShown()) == true
    for _, key in ipairs(Plate.HIDDEN) do
        local part = rawget(frame, key)
        if type(part) == "table" and part.SetAlpha then part:SetAlpha(on and 0 or 1) end
    end
    dress:SetShown(on)
end

local function Heard(dress, event)
    local unit = dress.unit
    if not unit or ns.off then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.Bar.Health(dress, unit)
    elseif event == "UNIT_NAME_UPDATE" then
        Name(dress, unit)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        ns.Marks.Rare(dress, unit)
    else -- UNIT_FACTION, UNIT_FLAGS: friend or foe, tapped
        ns.Bar.Paint(dress, unit)
        ns.Auras.Set(dress, unit)
    end
end
local OnEvent = ns.Guard(Heard)

-- Laid out anew for its size: the bar, the strip, the room for auras.
local function Fit(dress)
    ns.Bar.Fit(dress)
    ns.Resource.Fit(dress)
    if dress.unit then ns.Auras.Set(dress, dress.unit) end
end
local OnSizeChanged = ns.Guard(Fit)

local function Make(plate)
    local dress = CreateFrame("Frame", nil, plate)
    dress.plate, dress.edge = plate, 0
    ns.Bar.Make(dress)
    local name = dress:CreateFontString(nil, "OVERLAY", Font())
    name:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", 0, Plate.NAME_GAP)
    name:SetPoint("BOTTOMRIGHT", dress, "TOPRIGHT", 0, Plate.NAME_GAP)
    name:SetJustifyH("CENTER")
    name:SetWordWrap(false)
    name:SetTextColor(1, 1, 1)
    dress.name = name
    ns.Marks.Make(dress)
    ns.Auras.Make(dress)
    dress:SetScript("OnEvent", OnEvent)
    dress:SetScript("OnSizeChanged", OnSizeChanged)
    dress:Hide()
    dresses[plate] = dress
    return dress
end

-- The game showed or hid its health bar on a plate (by name only, widgets only): ours follows.
local function Turned(bar)
    local frame = bars[bar]
    local dress = frame and owners[frame]
    if dress and dress.frame == frame then Wear(dress) end
end
local OnTurned = ns.Guard(Turned)

-- The game's health bar of a unit frame followed, once per bar (hooks after the game's own, nothing replaced).
local function Follow(frame, bar)
    if bars[bar] then return end
    bars[bar] = frame
    bar:HookScript("OnShow", OnTurned)
    bar:HookScript("OnHide", OnTurned)
end

-- The dress taken off its unit: its events, auras and strip off, the game's parts back in sight.
local function Off(dress)
    if dress.unit and shown[dress.unit] == dress then shown[dress.unit] = nil end
    dress:UnregisterAllEvents()
    local frame = dress.frame
    dress.unit = nil
    ns.Auras.Set(dress, nil)
    ns.Resource.Leave(dress)
    if frame then
        Wear(dress) -- with no unit: the game's parts at full alpha, ours hidden
        if owners[frame] == dress then owners[frame] = nil end
    end
    dress.frame = nil
    dress:Hide()
end

local function Added(unit)
    if ns.off or type(unit) ~= "string" then return end
    local plate = PlateOf(unit)
    if not plate or plate == PlateOf("player") then return end
    local frame = rawget(plate, "UnitFrame")
    local row = type(frame) == "table" and rawget(frame, "HealthBarsContainer")
    local bar = type(row) == "table" and rawget(row, "healthBar")
    if type(bar) ~= "table" then return end -- not the plate this module knows: the game's own stays
    local dress = dresses[plate] or Make(plate)
    if dress.unit then Off(dress) end
    if shown[unit] and shown[unit] ~= dress then Off(shown[unit]) end
    dress.unit, dress.frame = unit, frame
    shown[unit], owners[frame] = dress, dress
    Follow(frame, bar)
    dress:ClearAllPoints()
    dress:SetAllPoints(row)
    for _, event in ipairs(Plate.EVENTS) do pcall(dress.RegisterUnitEvent, dress, event, unit) end
    Fit(dress)
    Fill(dress)
    Wear(dress)
    ns.Resource.Again()
end

local function Removed(unit)
    local dress = type(unit) == "string" and shown[unit]
    if not dress then return end
    Off(dress)
    ns.Resource.Again()
end

-- Target or focus changed: every border as it is now.
local function Borders()
    if ns.off then return end
    local target, focus = PlateOf("target"), PlateOf("focus")
    for _, dress in pairs(shown) do ns.Bar.Border(dress, Lit(dress.plate, target, focus)) end
end

local function Raids()
    if ns.off then return end
    for unit, dress in pairs(shown) do ns.Marks.Raid(dress, unit) end
end

-- The dress showing on a plate now; nil where there is none.
function Plate.Of(plate)
    local dress = plate and dresses[plate]
    if dress and dress.unit and dress:IsShown() then return dress end
    return nil
end

-- Every dress filled anew (a setting changed).
function Plate.Refresh()
    for _, dress in pairs(shown) do Fill(dress) end
end

-- The game's plates as they were: every dress off.
function Plate.GiveBack()
    for _, dress in pairs(dresses) do
        if dress.unit then Off(dress) end
    end
end

function Plate.Start()
    ns.On("NAME_PLATE_UNIT_ADDED", Added)
    ns.On("NAME_PLATE_UNIT_REMOVED", Removed)
    ns.On("PLAYER_TARGET_CHANGED", Borders)
    ns.On("PLAYER_FOCUS_CHANGED", Borders)
    ns.On("RAID_TARGET_UPDATE", Raids)
    -- The plates the game shows already (after a /reload they are there before us).
    local plates = Core.Ask(C_NamePlate.GetNamePlates)
    for _, plate in ipairs(type(plates) == "table" and plates or {}) do
        local unit = rawget(plate, "unitToken") or rawget(plate, "namePlateUnitToken")
        if type(unit) == "string" then Added(unit) end
    end
end
