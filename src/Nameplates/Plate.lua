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
--  plate of widgets only: the game's own plate then stays as it is; friendly
--  players are not shown by name only while the module is on, Scale.ALWAYS)
--  and when the module stands down; its cast bar too, but for the setting
--  Cast bar off (the game's shows then, Cast.lua). Its aura icons, which take
--  the mouse (their tooltip would pop up beside our bar), lose it under ours
--  and get it back with the rest. The rest of the game's plate stays: its
--  widgets and soft target icon. What clicks it is our bar alone (Click), not
--  the game's area around its name and bar: the plates stack as close as
--  their bar and a row of auras (Scale.Stacking), and the game's would reach
--  over the next plate's bar.
--
--  A player's plate is dressed like any other (bar, power line, the line,
--  auras, cast bar) and shows while a fight with the player can start (the
--  player may attack you, or you the player) or while the player is in your
--  group, your guild or on your friends list, or is your target; any other
--  player's is out of sight altogether (the game's unit frame on it at alpha
--  0), and so is their pet's, guardian's or totem's, unless a fight with it
--  can start or it is your target. So is a critter's (wild and companion pets
--  too), and with it its name, unless it is your target or wanted for a quest
--  of yours, or the setting shows them.
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
                 "aggroHighlightAdditive", "CastBarsContainer" }
-- A bar wider than this is a measurement gone wrong; it gets Plate.PLAIN until it is measured again.
Plate.WIDEST, Plate.PLAIN = 1000, 120
-- What each dress hears of its own unit.
Plate.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_NAME_UPDATE", "UNIT_FACTION", "UNIT_FLAGS",
                 "UNIT_CLASSIFICATION_CHANGED", "UNIT_LEVEL", "UNIT_THREAT_LIST_UPDATE", "UNIT_POWER_UPDATE",
                 "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "UNIT_COMBAT" }
for _, event in ipairs(Core.HealthMarks.EVENTS) do Plate.EVENTS[#Plate.EVENTS + 1] = event end
-- Critters by the game's creature type (UnitCreatureType's ID, the same in both games): Critter, Non-combat Pet
-- (a companion), Wild Pet.
Plate.CRITTERS = { [8] = true, [12] = true, [14] = true }

local dresses = {} -- [the game's plate] = our dress on it
local shown = {}   -- [unit token] = the dress on that unit's plate, while the game shows it
Plate.shown = shown -- read by Scale.lua and Range.lua (never written there)
local owners = setmetatable({}, { __mode = "k" }) -- [the game's unit frame] = the dress over it now
local bars = setmetatable({}, { __mode = "k" })   -- [the game's health bar] = its unit frame, once followed
local containers = setmetatable({}, { __mode = "k" }) -- [the game's aura container] = its unit frame, once followed
local muted = setmetatable({}, { __mode = "k" })  -- [the game's unit frame] = { [aura icon] = true }: the mouse taken
local gear -- asks for players' item levels again, a little later (made below, with Gear)

-- The game's plate for a unit, where addons may have it; nil for one it keeps from them.
local function PlateOf(unit)
    local plate = Core.Ask(C_NamePlate.GetNamePlateForUnit, unit)
    return type(plate) == "table" and plate or nil
end

-- The border's light for a plate: your target's, your focus's, else how you know its player (dress.kin, Plate.Kin)
-- or none (red over any of them while the unit is out of your reach: Range.lua, dress.out).
local function Lit(dress, target, focus)
    if dress.plate == target then return "target" end
    if dress.plate == focus then return "focus" end
    return dress.kin
end

-- Everything for the dress's unit, as the game says it now.
local function Fill(dress)
    local unit = dress.unit
    ns.Bar.Paint(dress, unit)
    ns.Bar.Health(dress, unit)
    local options, style = ns.options or {}, ns.Style()
    -- The barrier and lost health lie on the bar (none in Spells only), the dispel type is an aura's (none in Health
    -- bar only).
    dress.marks:Switch(options.barrier ~= false and style ~= "spells", options.lost ~= false and style ~= "spells",
        options.dispel ~= false and style ~= "bar")
    dress.marks:Set(unit)
    ns.Bar.Power(dress, unit)
    ns.Bar.Border(dress, Lit(dress, PlateOf("target"), PlateOf("focus")), dress.out)
    ns.Text.Set(dress, unit)
    ns.Marks.Raid(dress, unit)
    ns.Cast.Update(dress, unit)
    ns.Auras.Set(dress, unit)
end

-- Whether a unit is a critter, a wild pet or a companion pet; not where the game does not say.
local function Critter(unit)
    local _, kind = Core.Ask(UnitCreatureType, unit)
    return Plate.CRITTERS[kind or 0] == true
end
Plate.Critter = Critter

-- The subgroup of your raid that a member at that index of it is in; nil where the game does not say.
local function Subgroup(index)
    if type(index) ~= "number" then return nil end
    local _, _, group = Core.Ask(rawget(_G, "GetRaidRosterInfo"), index)
    return group
end

-- How you know a player, the closest first (its border's colour, Bar.KIN): "guild"; "party" (your group, or your own
-- subgroup of a raid); "raid"; "friend" (on your friends list, or a friend of your account); nil for a stranger and
-- for a creature.
function Plate.Kin(unit)
    if Plain(UnitIsPlayer(unit)) ~= true then return nil end
    if Core.Ask(UnitIsInMyGuild, unit) == true then return "guild" end
    local index = Core.Ask(UnitInRaid, unit)
    if index then
        local own = Subgroup(Core.Ask(UnitInRaid, "player"))
        return (own ~= nil and Subgroup(index) == own) and "party" or "raid"
    end
    if Core.Ask(UnitInParty, unit) == true then return "party" end
    local guid = Core.Ask(UnitGUID, unit)
    local friends = rawget(_G, "C_FriendList")
    if guid and friends and Core.Ask(friends.IsFriend, guid) then return "friend" end
    local bnet = rawget(_G, "C_BattleNet")
    local account = guid and bnet and Core.Ask(bnet.GetAccountInfoByGUID, guid)
    if type(account) == "table" and account.isFriend == true then return "friend" end
    return nil
end

-- The player a pet, guardian, totem or charmed creature is under (UnitOwnerGUID): a unit token of theirs ("player" for
-- your own; their plate, your group, your target) and their GUID; only the GUID where the player has no token now (no
-- plate of theirs yet); nil for a unit no player owns, and where the game does not say.
function Plate.Owner(unit)
    local guid = Core.Ask(rawget(_G, "UnitOwnerGUID"), unit)
    if type(guid) ~= "string" or not guid:find("^Player%-") then return nil end
    if guid == Core.Ask(UnitGUID, "player") then return "player", guid end
    return Core.Ask(rawget(_G, "UnitTokenFromGUID"), guid), guid
end

-- Whether a fight with a unit can start: it may attack you, or you it. Where the game does not say, it can.
local function Fight(unit)
    return Core.Ask(UnitCanAttack, "player", unit) ~= false or Core.Ask(UnitCanAttack, unit, "player") == true
end

-- Which transparency a plate has (Scale.Seen): "known" a player you know (kin: Plate.Kin), "stranger" a friendly
-- player you do not know, "critter"; nil for any other (creatures, players you could fight).
function Plate.Kind(unit, kin)
    if Plain(UnitIsPlayer(unit)) == true then
        if kin then return "known" end
        return not Fight(unit) and "stranger" or nil
    end
    return Critter(unit) and "critter" or nil
end

-- Whether a unit's plate shows: every plate but that of a player who is a stranger to you (not in your guild, group
-- or raid, not a friend: Plate.Kin; not your target) and with whom no fight can start (who may not attack you, nor
-- you them), that of such a player's pet, guardian or totem (Plate.Owner) with which no fight can start either and
-- which is not your target, and that of a critter (not your target, not one your quest wants: the dress's quest
-- piece) unless the setting shows them. Where the game does not say, it shows; so does a pet whose player has no
-- token yet, noted on its dress (dress.stray, worn anew when that player's plate comes: Strays). A dress's player as
-- Wear last found it (dress.kin).
function Plate.Wanted(unit, dress)
    local options = ns.options or {}
    local player = Plain(UnitIsPlayer(unit)) == true
    local critter = not player and Critter(unit)
    local owner, guid
    if not player and not critter then owner, guid = Plate.Owner(unit) end
    if not player and not guid then -- a creature
        if options.critters or not critter or (dress and dress.room.quest) then return true end
        return Plain(UnitIsUnit(unit, "target")) ~= false
    end
    if options.players == false or Fight(unit) or Plain(UnitIsUnit(unit, "target")) ~= false then return true end
    if player then
        if dress then return dress.kin ~= nil end
        return Plate.Kin(unit) ~= nil
    end
    -- A player's pet: shown where its player's plate is (yours always).
    if owner == "player" then return true end
    if not owner then
        if dress then dress.stray = guid end
        return true
    end
    return Fight(owner) or Plain(UnitIsUnit(owner, "target")) ~= false or Plate.Kin(owner) ~= nil
end

-- The game's aura icons on a unit frame as it shows them now (its container's pooled items, its loss of control one)
-- take the mouse, and their tooltip would pop up beside our bar while they are out of sight under it: their mouse
-- off while ours shows, each noted so it gets the mouse back (Unmute).
local function Mute(frame)
    local auras = rawget(frame, "AurasFrame")
    if type(auras) ~= "table" then return end
    local icons = muted[frame]
    if not icons then
        icons = {}
        muted[frame] = icons
    end
    local pool = rawget(auras, "auraItemFramePool")
    if type(pool) == "table" and pool.EnumerateActive then
        for icon in pool:EnumerateActive() do
            if not icons[icon] and icon.EnableMouse then
                icons[icon] = true
                icon:EnableMouse(false)
            end
        end
    end
    local control = rawget(auras, "LossOfControlFrame")
    local icon = type(control) == "table" and rawget(control, "AuraItemFrame")
    if type(icon) == "table" and icon.EnableMouse and not icons[icon] then
        icons[icon] = true
        icon:EnableMouse(false)
    end
end

-- Every aura icon of a unit frame whose mouse was taken: the mouse back (the game's parts in sight again).
local function Unmute(frame)
    local icons = muted[frame]
    if not icons then return end
    muted[frame] = nil
    for icon in pairs(icons) do icon:EnableMouse(true) end
end

-- The game's parts of a unit frame ours stand in for at that alpha: 0 out of sight under ours (its aura icons without
-- the mouse), 1 as the game has them. Its cast bar is left alone while the setting Cast bar is off: the game's shows
-- then (Cast.lua), and this would hide it anew at every change of target, roster or quest log.
local function Parts(frame, alpha)
    local castOff = alpha == 0 and (ns.options or {}).castBar == false
    for _, key in ipairs(Plate.HIDDEN) do
        if not (castOff and key == "CastBarsContainer") then
            local part = rawget(frame, key)
            if type(part) == "table" and part.SetAlpha then part:SetAlpha(alpha) end
        end
    end
    if alpha == 0 then Mute(frame) else Unmute(frame) end
end

-- A plate of a stranger or a critter out of sight altogether; else ours shown and the game's parts out of sight
-- while the game shows its health bar on the plate, the game's own plate as it is otherwise. Ours filled anew when
-- it comes back in sight: its texts measured while they show (a hidden one may not measure). How you know its
-- player found anew, the border lit anew where that changed. Ours and the rest of the game's unit frame under it
-- (its widgets, its cast bar with the setting Cast bar off) as transparent as the setting says (Scale.Seen: your
-- target's whole, so this runs at each change of target too).
local function Wear(dress)
    local frame = dress.frame
    local row = frame and rawget(frame, "HealthBarsContainer")
    local bar = type(row) == "table" and rawget(row, "healthBar")
    local kin = dress.unit and not ns.off and Plate.Kin(dress.unit) or nil
    local relit = kin ~= dress.kin
    dress.kin = kin
    dress.kind = dress.unit and not ns.off and Plate.Kind(dress.unit, kin) or nil
    if relit then Plate.Light(dress) end
    dress.stray = nil -- found anew by Plate.Wanted
    local wanted = ns.off or dress.unit == nil or Plate.Wanted(dress.unit, dress)
    local on = wanted and not ns.off and dress.unit ~= nil and type(bar) == "table" and Plain(bar:IsShown()) == true
    if frame then
        frame:SetAlpha(wanted and (on and ns.Scale.Seen(dress) or 1) or 0)
        Parts(frame, on and 0 or 1)
    end
    local back = on and dress.away
    dress.away = not on
    dress:SetShown(on)
    if on then ns.Scale.Fade(dress) end
    ns.Marks.Spells(dress) -- the arrow on your target (Spells only)
    if back then Fill(dress) end
end

local function Heard(dress, event, _, ...)
    local unit = dress.unit
    if not unit or ns.off then return end
    if event == "UNIT_COMBAT" then -- what it took: kind, flags, amount, school
        ns.CombatText.Hit(dress, ...)
    elseif ns.Cast.Heard[event] then
        ns.Cast.Update(dress, unit, event, ...) -- with the event's cast, spell and who interrupted it
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        ns.Bar.Health(dress, unit)
        ns.Text.Health(dress, unit)
        dress.marks:Heard(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then
        dress.marks:Heard(unit, event)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        ns.Bar.Power(dress, unit)
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        ns.Text.Threat(dress, unit)
    elseif event == "UNIT_NAME_UPDATE" then
        ns.Text.Name(dress, unit)
    elseif event == "UNIT_LEVEL" then
        ns.Text.Level(dress, unit)
        ns.Text.Health(dress, unit, true) -- its guess at the most anew, by its level
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        ns.Bar.Paint(dress, unit)
        ns.Text.Health(dress, unit, true) -- and by its rank
    else -- UNIT_FACTION, UNIT_FLAGS: friend or foe, tapped
        ns.Bar.Paint(dress, unit)
        ns.Text.Level(dress, unit)
        ns.Auras.Set(dress, unit)
        dress.marks:Dispel(unit)
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
    if ours and theirs and ours > 0.01 and theirs > 0 then width = width * theirs / ours end
    width = dress.want or width
    -- None, endless or absurd (the game not set up yet, just after a /reload): a plain width until it is.
    if width ~= width or width <= 0 or width > Plate.WIDEST then width = Plate.PLAIN end
    local height = ns.Text.Height(dress)
    if dress.row == row and dress.wide and math.abs(dress.wide - width) < 0.01 and math.abs(dress.high - height) < 0.01 then
        return
    end
    dress.row, dress.wide, dress.high = row, width, height
    dress:ClearAllPoints()
    dress:SetPoint("CENTER", row, "CENTER")
    dress:SetSize(width, height)
end

-- What the setting Plates show leaves of the dress (ns.Style; Saneroki, 2026-11-09). Spells only: no bar (its fill,
-- power line and barrier) and no line of texts (the name, the quest's icon outside), the outline around the rows under
-- it alone (Bar.Outline), no rank's line nor glow (Bar.Paint, Bar.Glow); the auras, the raid marker (Text.Bare), the
-- combo points, the cast bar and the combat text stay, and the dot and the arrow come (Marks.Spells). Health bar only:
-- no auras (Auras.Set, the dispel type in Fill) and nothing under the plate from elsewhere: the foot, which Combat's
-- tracked auras stand on (Plate.Foot), out of sight with them; the cast bar stays. Run as a dress is made and before
-- every plate is filled anew (Plate.Refresh), so its line shows again before it is measured.
local function Style(dress)
    local style = ns.Style()
    dress.health:SetShown(style ~= "spells")
    dress.top:SetShown(style ~= "spells")
    dress.foot:SetShown(style ~= "bar")
    ns.Bar.Outline(dress)
end

-- Laid out anew for its size: its place over the game's row, the bar, the strip, the room for auras.
local function Fit(dress)
    Plate.Place(dress)
    ns.Bar.Fit(dress)
    ns.Resource.Fit(dress)
    ns.Cast.Fit(dress)
    if dress.unit then ns.Auras.Set(dress, dress.unit) end
end
local OnSizeChanged = ns.Guard(Fit)
-- Laid out anew at the scale it shows at now (Scale.lua, as a plate grows or shrinks): its border one screen pixel.
Plate.Refit = Fit

-- The frame right under a plate's lowest row (the bar, the combo points, a cast's bar: Bar.Outline) while our dress is on
-- the plate's unit, for what another module shows right under the plate (Combat's tracked auras), so it follows the
-- plate's size and fading, and goes out of sight with it while the plates show the health bar only (Style); nil
-- otherwise.
function Plate.Foot(plate)
    local dress = dresses[plate]
    if ns.off or not dress or not dress.unit then return nil end
    return dress.foot
end

local function Make(plate)
    local dress = CreateFrame("Frame", nil, plate)
    dress.plate, dress.edge = plate, 0
    dress:SetScale(ns.Scale.Full()) -- its size by distance once Scale.lua has looked
    ns.Bar.Make(dress)
    ns.Text.Make(dress)
    ns.Marks.Make(dress)
    ns.Cast.Make(dress)
    ns.Auras.Make(dress)
    dress:SetScript("OnEvent", OnEvent)
    dress:SetScript("OnSizeChanged", OnSizeChanged)
    dress:Hide()
    Style(dress)
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

-- The game set a unit frame's aura icons out anew (its container's RefreshList: new ones from its pool): their mouse
-- off too while ours shows over them.
local function Shuffled(auras)
    if ns.off then return end
    local frame = containers[auras]
    local dress = frame and owners[frame]
    if dress and dress.frame == frame and dress.away == false then Mute(frame) end
end
local OnShuffled = ns.Guard(Shuffled)

-- What clicks a plate (Saneroki, 2026-11-13): our dress alone (the bar and its border), anchored to it, so it follows
-- its size and scale by itself. The game lets an addon set it in a fight only on the tick it hands the plate its unit
-- and right after its own code set it, so it is set as the dress comes on its unit (Added) and right after the game
-- set its own (UpdateHitTestArea, hooked: Clicked). Never where the game made the plate not clickable (no points: by
-- name only, widgets only).
local function Click(dress)
    local plate = dress.plate
    if ns.off or not dress.unit or not Core.Ask(plate.CanChangeHitTestPoints, plate) then return end
    local theirs = Core.Ask(plate.GetHitTestPoints, plate)
    if type(theirs) ~= "table" or #theirs == 0 then return end
    plate:SetAllHitTestPoints(dress)
end

-- The game set its click area on a unit frame's plate anew: ours again over it.
local function Clicked(frame)
    local dress = owners[frame]
    if dress and dress.frame == frame then ns.Safe("clicks", Click, dress) end
end
local OnClicked = ns.Guard(Clicked)

-- The game's own click area on the plate again (its own code, with its options) where a fight lets; else ours stays,
-- over the game's bar, until the game sets the plate up for its next unit.
local function Unclick(dress)
    local plate, frame = dress.plate, dress.frame
    local options = rawget(_G, "NamePlateSetupOptions")
    if not frame or type(options) ~= "table" or type(frame.UpdateHitTestArea) ~= "function" then return end
    if Core.Ask(plate.CanChangeHitTestPoints, plate) then frame:UpdateHitTestArea(options) end
end

-- The game's health bar, aura container and click area of a unit frame followed, once per bar (hooks after the game's
-- own, nothing replaced; a hook stays, and does nothing once the module stood down).
local function Follow(frame, bar)
    if bars[bar] then return end
    bars[bar] = frame
    bar:HookScript("OnShow", OnTurned)
    bar:HookScript("OnHide", OnTurned)
    if type(frame.UpdateHitTestArea) == "function" then hooksecurefunc(frame, "UpdateHitTestArea", OnClicked) end
    local auras = rawget(frame, "AurasFrame")
    if type(auras) == "table" and type(auras.RefreshList) == "function" then
        containers[auras] = frame
        hooksecurefunc(auras, "RefreshList", OnShuffled)
    end
end

-- The dress taken off its unit: its events off, the game's parts back in sight and ours hidden first, its bar as
-- made (a plate handed out again shows nothing of this unit); then its auras and strip, each by itself, so a step
-- of ours that fails (the game's aura containers) still leaves the game's plate as it is.
local function Off(dress)
    if dress.unit and shown[dress.unit] == dress then shown[dress.unit] = nil end
    dress:UnregisterAllEvents()
    ns.Safe("scale", ns.Scale.Leave, dress) -- the game's unit frame at its own scale, before it is let go
    dress.out, dress.kin, dress.stray = nil, nil, nil -- the next unit's reach, kin and owner are its own
    local frame = dress.frame
    dress.unit, dress.frame, dress.away = nil, nil, nil
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
    ns.Safe("combat text", ns.CombatText.Clear, dress)
    ns.Safe("cast", ns.Cast.Update, dress, nil)
end

-- A player's plate came: the plates of their pets that came before it (dress.stray: no token of theirs then) worn anew.
local function Strays(guid)
    if not guid then return end
    for _, dress in pairs(shown) do
        if dress.stray == guid then Wear(dress) end
    end
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
    for _, event in ipairs(ns.Cast.EVENTS) do pcall(dress.RegisterUnitEvent, dress, event, unit) end
    Fit(dress)
    ns.Safe("clicks", Click, dress) -- on this tick the game lets it, in a fight too
    Wear(dress) -- shown before it is filled: its texts measured while they show
    Fill(dress)
    Wear(dress)
    ns.Scale.Born(dress) -- it grows in
    ns.Resource.Again()
    if Plain(UnitIsPlayer(unit)) then
        if dress.room.gear == nil then gear() end
        Strays(Core.Ask(UnitGUID, unit))
    end
end

local function Removed(unit)
    local dress = type(unit) == "string" and shown[unit]
    if not dress then return end
    Off(dress)
    ns.Resource.Again()
    ns.Scale.Again()
end

-- Target or focus changed: every ring as it is now, and every plate shown or not (your target always is).
local function Borders()
    if ns.off then return end
    local target, focus = PlateOf("target"), PlateOf("focus")
    for _, dress in pairs(shown) do
        ns.Bar.Border(dress, Lit(dress, target, focus), dress.out)
        Wear(dress)
    end
end

Plate.Borders = Borders

-- One plate's border anew (its unit came in or went out of your reach: Range.lua).
function Plate.Light(dress)
    if ns.off or not dress.unit then return end
    ns.Bar.Border(dress, Lit(dress, PlateOf("target"), PlateOf("focus")), dress.out)
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

-- The quest log changed: every creature's quest piece as the game says now, and every plate shown or not (a critter
-- your quest wants).
local function Quests()
    if ns.off then return end
    for unit, dress in pairs(shown) do
        ns.Text.Quest(dress, unit)
        Wear(dress)
    end
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

-- Every dress filled anew (a setting changed); every one made is as Plates show says (those shown no more too: the
-- game hands its plates out again).
function Plate.Refresh()
    for _, dress in pairs(dresses) do Style(dress) end
    for _, dress in pairs(shown) do
        Fit(dress) -- the cast bar's height, the icons' size and places as the settings say now
        Fill(dress)
        Wear(dress)
    end
end

-- The game's plates as they were: every unit frame ours ever lay over and its parts in sight again, its aura icons
-- with the mouse (the game hands them out again from its pool, and sets their alpha nowhere), then every dress off,
-- each by itself, its plate's click area the game's own first (Unclick).
function Plate.GiveBack()
    for _, frame in pairs(bars) do
        ns.Safe("give back", frame.SetAlpha, frame, 1)
        ns.Safe("give back", frame.SetScale, frame, 1)
        ns.Safe("give back", Parts, frame, 1)
    end
    for _, dress in pairs(dresses) do
        if dress.unit then
            ns.Safe("give back", Unclick, dress)
            ns.Safe("give back", Off, dress)
        end
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
    -- Once the world shows (the game's fonts and scales set up, also after a /reload), every plate measured anew.
    ns.On("PLAYER_ENTERING_WORLD", Core.Later(Plate.Refresh, 0.5))
    -- The plates the game shows already (after a /reload they are there before us).
    local plates = Core.Ask(C_NamePlate.GetNamePlates)
    for _, plate in ipairs(type(plates) == "table" and plates or {}) do
        local unit = rawget(plate, "unitToken") or rawget(plate, "namePlateUnitToken")
        if type(unit) == "string" then Added(unit) end
    end
end
