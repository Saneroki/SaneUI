local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Plate
--  Our dress on each plate the game shows: a frame of ours on the game's plate
--  (so it follows the plate's place, scale and fading), centred on the game's
--  health bar row (HealthBarsContainer), as high as the line inside it needs
--  and as wide as that line wants (Plate.Place),
--  holding our bar (Bar.lua), the line inside it (Text.lua, the raid marker
--  in it from Marks.lua), the auras around it (Auras.lua) and, on your
--  target, the combo points (Resource.lua).
--
--  The game's parts ours stand in for (its health bar row, name, auras, raid
--  marker, classification mark, level boxes, selection and threat glow) go out
--  of sight while ours shows: their alpha 0, set by calls only, nothing of
--  theirs written, and 1 again when the plate goes, when its health bar goes (a
--  friendly player shown by name only, a plate of widgets only: the game's own
--  plate then stays as it is) and when the module stands down. The rest of the
--  game's plate stays: its cast bar, widgets and soft target icon, and what
--  clicks it.
--
--  The plate of a player you cannot attack is out of sight altogether (the
--  game's unit frame on it at alpha 0) unless the player is in your group,
--  your guild or on your friends list, or is your target. Players you can
--  attack keep theirs.
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
Plate.HIDDEN = { "HealthBarsContainer", "name", "AurasFrame", "RaidTargetFrame", "ClassificationFrame", "LevelFrame",
                 "PlayerLevelDiffFrame", "selectionHighlight", "aggroHighlight", "aggroHighlightBase",
                 "aggroHighlightAdditive" }
-- What each dress hears of its own unit.
Plate.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_NAME_UPDATE", "UNIT_FACTION", "UNIT_FLAGS",
                 "UNIT_CLASSIFICATION_CHANGED", "UNIT_LEVEL", "UNIT_THREAT_LIST_UPDATE", "UNIT_POWER_UPDATE",
                 "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER" }

local dresses = {} -- [the game's plate] = our dress on it
local shown = {}   -- [unit token] = the dress on that unit's plate, while the game shows it
local owners = setmetatable({}, { __mode = "k" }) -- [the game's unit frame] = the dress over it now
local bars = setmetatable({}, { __mode = "k" })   -- [the game's health bar] = its unit frame, once followed
local gear -- asks for players' item levels again, a little later (made below, with Gear)

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

-- Everything for the dress's unit, as the game says it now.
local function Fill(dress)
    local unit = dress.unit
    ns.Bar.Paint(dress, unit)
    ns.Bar.Health(dress, unit)
    ns.Bar.Power(dress, unit)
    ns.Bar.Border(dress, Lit(dress.plate, PlateOf("target"), PlateOf("focus")))
    ns.Text.Set(dress, unit)
    ns.Marks.Raid(dress, unit)
    ns.Auras.Set(dress, unit)
end

-- Whether a unit's plate shows: every plate but that of a player you cannot attack who is a stranger to you (not
-- in your group or guild, not on your friends list, not your target). Where the game does not say, it shows.
function Plate.Wanted(unit)
    if (ns.options or {}).players == false or Plain(UnitIsPlayer(unit)) ~= true then return true end
    if Core.Ask(UnitCanAttack, "player", unit) ~= false then return true end
    if Plain(UnitIsUnit(unit, "target")) ~= false then return true end
    if Core.Ask(UnitInParty, unit) or Core.Ask(UnitInRaid, unit) or Core.Ask(UnitIsInMyGuild, unit) then return true end
    local guid = Core.Ask(UnitGUID, unit)
    local friends = rawget(_G, "C_FriendList")
    if guid and friends and Core.Ask(friends.IsFriend, guid) then return true end
    local bnet = rawget(_G, "C_BattleNet")
    local account = guid and bnet and Core.Ask(bnet.GetAccountInfoByGUID, guid)
    return type(account) == "table" and account.isFriend == true
end

-- The game's parts of a unit frame ours stand in for at that alpha: 0 out of sight under ours, 1 as the game has them.
local function Parts(frame, alpha)
    for _, key in ipairs(Plate.HIDDEN) do
        local part = rawget(frame, key)
        if type(part) == "table" and part.SetAlpha then part:SetAlpha(alpha) end
    end
end

-- A plate of a stranger out of sight altogether; else ours shown and the game's parts out of sight while the
-- game shows its health bar on the plate, the game's own plate as it is otherwise.
local function Wear(dress)
    local frame = dress.frame
    local row = frame and rawget(frame, "HealthBarsContainer")
    local bar = type(row) == "table" and rawget(row, "healthBar")
    local wanted = ns.off or dress.unit == nil or Plate.Wanted(dress.unit)
    local on = wanted and not ns.off and dress.unit ~= nil and type(bar) == "table" and Plain(bar:IsShown()) == true
    if frame then
        frame:SetAlpha(wanted and 1 or 0)
        Parts(frame, on and 0 or 1)
    end
    dress:SetShown(on)
end

local function Heard(dress, event)
    local unit = dress.unit
    if not unit or ns.off then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.Bar.Health(dress, unit)
        ns.Text.Health(dress, unit)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        ns.Bar.Power(dress, unit)
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        ns.Text.Threat(dress, unit)
    elseif event == "UNIT_NAME_UPDATE" then
        ns.Text.Name(dress, unit)
    elseif event == "UNIT_LEVEL" then
        ns.Text.Level(dress, unit)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        ns.Bar.Paint(dress, unit)
    else -- UNIT_FACTION, UNIT_FLAGS: friend or foe, tapped
        ns.Bar.Paint(dress, unit)
        ns.Text.Level(dress, unit)
        ns.Auras.Set(dress, unit)
        Wear(dress)
    end
end
local OnEvent = ns.Guard(Heard)

-- The dress centred on the game's health bar row, as high as its line needs (Text.Height) and as wide as it wants
-- (Text.Layout; the row's width, read in the dress's own units, before the line is laid out). Placed anew only when
-- that changed.
function Plate.Place(dress)
    local row = dress.frame and rawget(dress.frame, "HealthBarsContainer")
    if type(row) ~= "table" then return end
    local width = Plain(row:GetWidth()) or 0
    local ours, theirs = Plain(dress:GetEffectiveScale()), Plain(row:GetEffectiveScale())
    if ours and theirs and ours > 0 then width = width * theirs / ours end
    width = dress.want or width
    local height = ns.Text.Height(dress)
    if dress.row == row and dress.wide and math.abs(dress.wide - width) < 0.01 and math.abs(dress.high - height) < 0.01 then
        return
    end
    dress.row, dress.wide, dress.high = row, width, height
    dress:ClearAllPoints()
    dress:SetPoint("CENTER", row, "CENTER")
    dress:SetSize(width, height)
end

-- Laid out anew for its size: its place over the game's row, the bar, the strip, the room for auras.
local function Fit(dress)
    Plate.Place(dress)
    ns.Bar.Fit(dress)
    ns.Resource.Fit(dress)
    if dress.unit then ns.Auras.Set(dress, dress.unit) end
end
local OnSizeChanged = ns.Guard(Fit)

local function Make(plate)
    local dress = CreateFrame("Frame", nil, plate)
    dress.plate, dress.edge = plate, 0
    ns.Bar.Make(dress)
    ns.Text.Make(dress)
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

-- The dress taken off its unit: its events off, the game's parts back in sight and ours hidden first, its bar as
-- made (a plate handed out again shows nothing of this unit); then its auras and strip, each by itself, so a step
-- of ours that fails (the game's aura containers) still leaves the game's plate as it is.
local function Off(dress)
    if dress.unit and shown[dress.unit] == dress then shown[dress.unit] = nil end
    dress:UnregisterAllEvents()
    local frame = dress.frame
    dress.unit, dress.frame = nil, nil
    dress:Hide()
    if frame then
        frame:SetAlpha(1)
        Parts(frame, 1)
        if owners[frame] == dress then owners[frame] = nil end
    end
    ns.Bar.Clear(dress)
    ns.Text.Set(dress, nil)
    ns.Safe("auras", ns.Auras.Set, dress, nil)
    ns.Safe("combo points", ns.Resource.Leave, dress)
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
    dress.row, dress.want = nil, nil -- placed anew over this row, as wide as its line once laid out
    for _, event in ipairs(Plate.EVENTS) do pcall(dress.RegisterUnitEvent, dress, event, unit) end
    Fit(dress)
    Fill(dress)
    Wear(dress)
    ns.Resource.Again()
    if dress.room.gear == nil and Plain(UnitIsPlayer(unit)) then gear() end
end

local function Removed(unit)
    local dress = type(unit) == "string" and shown[unit]
    if not dress then return end
    Off(dress)
    ns.Resource.Again()
end

-- Target or focus changed: every ring as it is now, and every plate shown or not (your target always is).
local function Borders()
    if ns.off then return end
    local target, focus = PlateOf("target"), PlateOf("focus")
    for _, dress in pairs(shown) do
        ns.Bar.Border(dress, Lit(dress.plate, target, focus))
        Wear(dress)
    end
end

-- Your group, guild or friends changed: every plate shown or not.
local function People()
    if ns.off then return end
    for _, dress in pairs(shown) do Wear(dress) end
end
local people = Core.Later(People)

-- Your threat changed somewhere (or a fight ended, or you went up a level): every plate's threat and level.
local function Threats()
    if ns.off then return end
    for unit, dress in pairs(shown) do
        ns.Text.Threat(dress, unit)
        ns.Text.Level(dress, unit)
    end
end
local threats = Core.Later(Threats)

-- The quest log changed: every creature's quest piece as the game says now.
local function Quests()
    if ns.off then return end
    for unit, dress in pairs(shown) do ns.Text.Quest(dress, unit) end
end
local quests = Core.Later(Quests)

-- Players' item levels: asked for again (Core paces the questions) while some shown player has none, a little
-- after the next question may go; nothing more once all have one or none is left to ask for.
local function Gear()
    if ns.off then return end
    local missing = false
    for unit, dress in pairs(shown) do
        if dress.room.gear == nil and Plain(UnitIsPlayer(unit)) and not ns.Text.Gear(dress, unit) then missing = true end
    end
    if missing then gear() end
end
gear = Core.Later(Gear, Core.Inspect.GAP + 0.25)

-- A player's item level came: their plate's piece.
local function Arrived(guid)
    if ns.off then return end
    for unit, dress in pairs(shown) do
        if Core.Ask(UnitGUID, unit) == guid then ns.Text.Gear(dress, unit) end
    end
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
    for _, dress in pairs(shown) do
        Fill(dress)
        Wear(dress)
    end
end

-- The game's plates as they were: every unit frame ours ever lay over and its parts in sight again (the game hands
-- them out again from its pool, and sets their alpha nowhere), then every dress off, each by itself.
function Plate.GiveBack()
    for _, frame in pairs(bars) do
        ns.Safe("give back", frame.SetAlpha, frame, 1)
        ns.Safe("give back", Parts, frame, 1)
    end
    for _, dress in pairs(dresses) do
        if dress.unit then ns.Safe("give back", Off, dress) end
    end
end

function Plate.Start()
    ns.On("NAME_PLATE_UNIT_ADDED", Added)
    ns.On("NAME_PLATE_UNIT_REMOVED", Removed)
    ns.On("PLAYER_TARGET_CHANGED", Borders)
    ns.On("PLAYER_FOCUS_CHANGED", Borders)
    ns.On("RAID_TARGET_UPDATE", Raids)
    ns.On("GROUP_ROSTER_UPDATE", people)
    ns.On("FRIENDLIST_UPDATE", people)
    ns.On("GUILD_ROSTER_UPDATE", people)
    ns.On("BN_FRIEND_INFO_CHANGED", people)
    ns.On("UNIT_THREAT_SITUATION_UPDATE", threats)
    ns.On("PLAYER_REGEN_ENABLED", threats)
    ns.On("PLAYER_LEVEL_UP", threats)
    ns.On("PLAYER_REGEN_ENABLED", gear)
    ns.On("QUEST_LOG_UPDATE", quests)
    ns.On("UNIT_QUEST_LOG_CHANGED", quests)
    Core.Inspect.Watch(ns.Guard(Arrived))
    -- The plates the game shows already (after a /reload they are there before us).
    local plates = Core.Ask(C_NamePlate.GetNamePlates)
    for _, plate in ipairs(type(plates) == "table" and plates or {}) do
        local unit = rawget(plate, "unitToken") or rawget(plate, "namePlateUnitToken")
        if type(unit) == "string" then Added(unit) end
    end
end
