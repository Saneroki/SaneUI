local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - GroupFace
--  What one member of your party or raid looks like: a nameplate's bar, a bit
--  shorter and taller, one height whatever it shows:
--    left    the raid marker, then the name, with as much room as the frame has
--            (Saneroki, 2026-10-30: little space at the ends and between the
--            pieces, Face.INSET, Face.GAP)
--    corner  a tiny mark of a tank's or healer's role in the frame's top left
--            corner, a shield or a plus, no golden circle, centred over where
--            the raid marker stands: in front of the bar, behind the name and
--            the raid marker
--    right   how much health is left ("85%"); nothing on a frame too narrow for
--            that as well (Face.BARE), so the name gets it; Dead or Offline always
--    over it an icon for each of your buffs the unit is missing (GroupBuffs.lua),
--            from the health leftwards; from the left, big so they are easy to
--            see (Face.Big), the ready check while one runs and its result for
--            a while after it (Face.READY_HOLD), the game's icon of an incoming
--            resurrection and the type icon of a dispellable debuff (Core's
--            HealthMarks.lua), each stepping aside for the one before it.
--            All float over the name and the raid marker, which stay where they
--            are and go on behind them
--    bottom  the mana of a tank or healer, a line inside the bar as on a
--            nameplate, so the frame is no taller for it
--  and on it Core's barrier and lost maximum health. Green for everyone, as every
--  unit frame; a dead unit's bar full and red, an offline one's full and grey.
--  Its border is black, solid red while the unit has an enemy's aggro.
--
--  Your own slot is a frame like all the others, with all of that (Saneroki,
--  2026-10-30). Two things differ: its name is the word Party or Raid, and at
--  its far right, in place of the health's words, a cog always stands, with the
--  tools' button on just that (GroupTools.lua).
--
--  The same face stands on a secure unit button of the game's group headers
--  (Face.Unit: it follows the button's unit), hearing that unit's events, and
--  in Edit Mode's preview as a plain frame filled with made-up values
--  (Face.Sample). It takes no mouse: the button under it keeps clicks, the
--  tooltip and @mouseover.
--
--  Who gets the mana line: the game's assigned role (tank, healer); without a
--  role (many groups set none) a main tank, or a class that can heal, so it
--  does not go missing there. A unit without mana shows its own power.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bar, Text = ns.UnitBar, ns.UnitText
local NONE = Core.HealthMarks.NONE
local Face = {}
ns.GroupFace = Face

Face.LINE, Face.LINE_MOST = 1 / 5, 8 -- the power line's height, a share of the bar's, and the most on a tall slot
Face.INSET, Face.GAP = 3, 2 -- the words from the bar's ends, and between two pieces
Face.BARE = 80       -- narrower than this: no health at all, the name has it all
Face.ICON = 14       -- one of your buffs' icons, and the cog, square
Face.ICON_GAP = 1    -- between two of your buffs' icons
Face.BIG_OFF, Face.BIG_MOST = 4, 32 -- the big icons are that much lower than the frame, and at most that high
Face.ROLE = 10       -- the role's mark, square
Face.FAR = 0.45      -- how solid a unit out of your reach is
Face.AGGRO = 2       -- the first of the game's threat kinds that is having aggro
Face.AGGRO_BORDER = { 1, 0, 0, 1 }  -- solid, saturated
Face.DEAD = { 0.8, 0, 0 }
Face.OFFLINE = { 0.5, 0.5, 0.5 }
Face.COG = "questlog-icon-setting"  -- the game's cog, as Core's windows have it
Face.REZ = "RaidFrame-Icon-Rez"     -- the game's raid frames' icon of an incoming resurrection
Face.ROLES = { TANK = "roleicon-tiny-tank", HEALER = "roleicon-tiny-healer" } -- the game's plain marks, without a ring
Face.HEALERS = { PRIEST = true, DRUID = true, SHAMAN = true, PALADIN = true, MONK = true, EVOKER = true }
Face.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
                "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_IN_RANGE_UPDATE", "UNIT_AURA",
                "UNIT_THREAT_SITUATION_UPDATE", "UNIT_THREAT_LIST_UPDATE", "INCOMING_RESURRECT_CHANGED" }
-- The game's pictures of a ready check, by what GetReadyCheckStatus says; how long its result stays after it ended.
Face.READY = { ready = rawget(_G, "READY_CHECK_READY_TEXTURE_RAID") or "UI-LFG-ReadyMark-Raid",
               notready = rawget(_G, "READY_CHECK_NOT_READY_TEXTURE_RAID") or "UI-LFG-DeclineMark-Raid",
               waiting = rawget(_G, "READY_CHECK_WAITING_TEXTURE_RAID") or "UI-LFG-PendingMark-Raid" }
Face.READY_HOLD = rawget(_G, "CUF_READY_CHECK_DECAY_TIME") or 11

-- The icons over the name: from the health (on your own slot the cog) leftwards.
local function Roomed(face, right)
    local start = right + Face.GAP
    for index, icon in ipairs(face.icons) do
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", face.floating, "RIGHT", -(start + (index - 1) * (Face.ICON + Face.ICON_GAP)), 0)
    end
end

-- The big icons as high as the frame lets them be; one that shows that wide too.
function Face.Big(face, height)
    local big = math.max(math.min(height - Face.BIG_OFF, Face.BIG_MOST), Face.ICON)
    if big == face.big then return end
    face.big = big
    face.marks:Resize(big)
    for _, icon in ipairs({ face.ready, face.rez }) do
        icon:SetHeight(big)
        if icon:IsShown() then icon:SetWidth(big) end
    end
end

-- Laid out for its size: the border a screen pixel, the bar inside it (shorter where maximum health is lost), the
-- line along its bottom, the name's room; the health's words change where the frame turned narrow or wide.
function Face.Fit(face)
    local width, height = Plain(face:GetWidth()) or 0, Plain(face:GetHeight()) or 0
    if width <= 0 or height <= 0 then return end
    local pixel = Core.Pixels(face, 1)
    local radius = height * Bar.CAP
    local marks, health = face.marks, face.health
    Bar.Around(face.border, face, 0, height, 0, 0, radius)
    local inner = width - 2 * pixel
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", face, "TOPLEFT", pixel, -pixel)
    health:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -pixel - marks:Reach(inner), pixel)
    local tall, round = height - 2 * pixel, math.max(radius - pixel, 0.01)
    Bar.Ends(health, "both", round, tall)
    Bar.End(marks.lostEnd, marks.lost, "RIGHT", "both", round, tall)
    marks:Fit(inner)
    face.power:SetHeight(math.max(math.min(tall * Face.LINE, Face.LINE_MOST), pixel * 2))
    Face.Big(face, height)
    local bare = width < Face.BARE
    local turned = bare ~= face.bare
    face.bare = bare
    Text.Layout(face)
    if turned and face.unit then Text.Health(face, face.unit) end
end
local OnSizeChanged = ns.Guard(Face.Fit)

-- A face on parent, each layer on a frame of its own one level above the last, as a unit frame's: the outline, then the
-- bars, then the words. sample: a plain one for the preview, which never shows a live unit.
function Face.Make(parent, sample)
    local face = CreateFrame("Frame", nil, parent)
    local level = Plain(face:GetFrameLevel()) or 1
    local edges = CreateFrame("Frame", nil, face)
    edges:SetAllPoints(face)
    edges:SetFrameLevel(level + 2)
    face.border = Bar.Plate(edges, -4)
    face.border:SetVertexColor(Bar.BORDER[1], Bar.BORDER[2], Bar.BORDER[3], Bar.BORDER[4])
    local health = Bar.Strip(face, level + 3)
    face.health = health
    local power = CreateFrame("StatusBar", nil, health)
    power:SetFrameLevel(level + 5)
    power:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
    power:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    power:SetStatusBarTexture(Bar.FILL)
    power:SetMinMaxValues(0, 1)
    power:SetValue(0)
    for _, mask in ipairs(health.ends) do power:GetStatusBarTexture():AddMaskTexture(mask) end
    power:Hide()
    face.power = power
    face.marks = Core.HealthMarks.New(face, health, {
        masks = health.ends, size = Face.ICON, sample = sample, above = level + 8, fit = function() Face.Fit(face) end })
    Text.MakeLine(face, Face.INSET, Face.GAP)
    face.compact = true
    -- Over the words, what floats on them: from the left the ready check, the resurrection, then the dispel icon, last
    -- because it stands by them: the game lets nothing of ours stand by its container (HealthMarks.lua).
    face.floating = CreateFrame("Frame", nil, face)
    face.floating:SetAllPoints(face)
    face.floating:SetFrameLevel(level + 7)
    face.big = Face.ICON
    local ready = face.floating:CreateTexture(nil, "OVERLAY")
    ready:SetSize(NONE, face.big)
    ready:SetPoint("LEFT", face.floating, "LEFT", Face.INSET, 0)
    ready:Hide()
    local rez = face.floating:CreateTexture(nil, "OVERLAY")
    rez:SetSize(NONE, face.big)
    rez:SetPoint("LEFT", ready, "RIGHT", 0, 0)
    rez:SetAtlas(Face.REZ)
    rez:Hide()
    face.ready, face.rez = ready, rez
    face.marks:Place("LEFT", rez, "RIGHT", 0, 0)
    -- Your own slot's cog, at its far right.
    local cog = face.floating:CreateTexture(nil, "OVERLAY")
    cog:SetSize(Face.ICON, Face.ICON)
    cog:SetPoint("RIGHT", face.floating, "RIGHT", -Face.INSET, 0)
    cog:SetAtlas(Face.COG)
    cog:Hide()
    face.cog = cog
    -- The role's mark in the corner, centred on the raid marker's place: on the frame of the words, under them.
    local role = face.top:CreateTexture(nil, "BACKGROUND")
    role:SetSize(Face.ROLE, Face.ROLE)
    role:SetPoint("TOPLEFT", face, "TOPLEFT", Face.INSET + Face.GAP + (face.markSize - Face.ROLE) / 2, -Face.GAP)
    role:Hide()
    face.role = role
    face.icons, face.missing, face.roomed = {}, {}, Roomed
    face:SetScript("OnSizeChanged", OnSizeChanged)
    return face
end

-- Those icons over the name (count of them).
local function Icons(face, list, count)
    for index = 1, math.max(count, #face.icons) do
        local icon = face.icons[index]
        if not icon then
            icon = face.floating:CreateTexture(nil, "OVERLAY")
            icon:SetSize(Face.ICON, Face.ICON)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            face.icons[index] = icon
        end
        icon:SetTexture(list[index])
        icon:SetShown(index <= count)
    end
    Roomed(face, face.room.right)
end

-- Your buffs the unit is missing, as far as can be told: what a fight hides stays as it was.
local function Buffs(face, unit)
    local on = (ns.options or {}).groupBuffs ~= false and ns.GroupBuffs.Any()
    local count = 0
    if on then
        count = ns.GroupBuffs.Missing(unit, face.missing)
        if not count then return end
    end
    Icons(face, face.missing, count)
end

-- The unit's role, as far as the game tells it: the one it was assigned, or TANK for a raid's main tank.
local function RoleOf(unit)
    local role = Core.Ask(UnitGroupRolesAssigned, unit)
    if (role == nil or role == "NONE") and Core.Ask(rawget(_G, "GetPartyAssignment"), "MAINTANK", unit) then return "TANK" end
    return role
end

-- That role's tiny mark: a tank's or a healer's, none for the rest.
local function RoleIcon(face, role)
    local atlas = Face.ROLES[role]
    if atlas then face.role:SetAtlas(atlas) end
    face.role:SetShown(atlas ~= nil)
end

-- Whether a unit of that role gets the power line: a tank, a healer, without a role a class that heals.
local function WantsPower(unit, role)
    if role == "TANK" or role == "HEALER" then return true end
    if role == "DAMAGER" then return false end
    local _, class = Core.Ask(UnitClass, unit)
    return Face.HEALERS[class] == true
end

local KIND = { type = Bar.MANA, token = "MANA" } -- read again each time: the power line's kind

-- The power line as the unit's role says: its mana, or its own power where it has none.
local function Power(face, unit)
    local on = WantsPower(unit, RoleOf(unit))
    if on then
        local mana = Bar.Raw(UnitPowerMax, unit, Bar.MANA)
        KIND.type, KIND.token = Bar.MANA, "MANA"
        if type(mana) == "nil" or Plain(mana) == 0 then KIND.type, KIND.token = Core.Ask(UnitPowerType, unit) end
        on = Bar.Power(face.power, unit, KIND)
    end
    face.power:SetShown(on)
end

-- Fainter while the unit is out of your reach; the game's answer may be hidden, and the alpha takes it as it is.
local function Range(face, unit)
    local ok, near, checked = pcall(UnitInRange, unit)
    if not ok then return face:SetAlpha(1) end
    if Core.Secret(near) then
        if not pcall(face.SetAlphaFromBoolean, face, near, 1, Face.FAR) then face:SetAlpha(1) end
    else
        face:SetAlpha((near == false and Plain(checked) ~= false) and Face.FAR or 1)
    end
end

-- The border: red while the unit has an enemy's aggro. A fight may hide that from addons: black then.
local function Border(face, aggro)
    local colour = aggro and Face.AGGRO_BORDER or Bar.BORDER
    face.border:SetVertexColor(colour[1], colour[2], colour[3], colour[4])
end

local function Aggro(face, unit)
    local status = Core.Ask(UnitThreatSituation, unit)
    Border(face, type(status) == "number" and status >= Face.AGGRO)
end

local function Colour(face, colour)
    if face.colour == colour then return end
    face.colour = colour
    face.health:SetStatusBarColor(colour[1], colour[2], colour[3])
end

-- The bar: its health in green, or full, red for the dead and grey for who is offline.
local function Health(face, unit)
    local offline = Core.Ask(UnitIsConnected, unit) == false
    local gone = offline or Core.Ask(UnitIsDeadOrGhost, unit) == true
    Colour(face, offline and Face.OFFLINE or gone and Face.DEAD or Bar.GREEN)
    if gone then
        face.health:SetMinMaxValues(0, 1)
        face.health:SetValue(1)
    else
        Bar.Health(face.health, unit)
    end
end

-- That ready check's picture on the line, or none: as wide as nothing then.
local function ReadyIcon(face, status)
    local atlas = status and Face.READY[status]
    face.readyStatus = atlas and status or nil
    if atlas then face.ready:SetAtlas(atlas) end
    face.ready:SetShown(atlas ~= nil)
    face.ready:SetWidth(atlas and face.big or NONE)
end

-- The ready check as the game says it now; while its result stays (Face.holding), that.
function Face.Ready(face)
    if Face.holding or not face.unit then return end
    ReadyIcon(face, Core.Ask(GetReadyCheckStatus, face.unit))
end

-- It ended: who has not answered is not ready, as the game has it.
function Face.ReadyEnded(face)
    if face.readyStatus == "waiting" then ReadyIcon(face, "notready") end
end

function Face.ReadyGone(face)
    ReadyIcon(face, nil)
end

-- An incoming resurrection's icon, or none: as wide as nothing then.
local function RezIcon(face, on)
    face.rez:SetShown(on)
    face.rez:SetWidth(on and face.big or NONE)
end

local function Rez(face, unit)
    RezIcon(face, Core.Ask(rawget(_G, "UnitHasIncomingResurrection"), unit) == true)
end

-- Whether this is your own slot: the cog on it, and no health in words, that room the cog's.
local function Yours(face, mine)
    face.mine = mine
    face.cog:SetShown(mine)
    face.noHealth = mine and Face.ICON + Face.GAP or nil
end

-- The unit's name; on your own slot the word for your group in its place.
local function Name(face, unit)
    if not face.mine then return Text.Name(face, unit) end
    face.name:SetText(Core.Ask(IsInRaid) and ns.TEXT.groupRaid or ns.TEXT.groupParty)
end

-- Everything for the face's unit, as the game says it now.
function Face.Fill(face)
    local unit = face.unit
    if ns.off or not unit or not Core.Ask(UnitExists, unit) then return end
    Yours(face, Core.Ask(UnitIsUnit, unit, "player") == true)
    Health(face, unit)
    face.marks:Set(unit)
    Power(face, unit)
    RoleIcon(face, RoleOf(unit))
    Range(face, unit)
    Aggro(face, unit)
    Face.Ready(face)
    Rez(face, unit)
    Text.Raid(face, unit)
    Name(face, unit)
    Text.Health(face, unit)
    Buffs(face, unit)
end

-- Whether an aura update (UNIT_AURA's info) may have changed which of your buffs the unit has: all of them anew, a
-- helpful aura added (which one is not looked at), or any aura gone (what kind it was is not told); not one that only
-- refreshed what is there (a stack, a duration). An answer the game hides counts as a change.
local function Buffed(info)
    if type(info) ~= "table" or Plain(info.isFullUpdate) ~= false then return true end
    local removed = info.removedAuraInstanceIDs
    if type(removed) == "table" and next(removed) ~= nil then return true end
    local added = info.addedAuras
    if type(added) == "table" then
        for _, aura in ipairs(added) do
            if type(aura) ~= "table" or Plain(aura.isHelpful) ~= false then return true end
        end
    end
    return false
end

-- The face's unit's event (its unit, then the event's own: an aura update's info).
local function Heard(face, event, _, info)
    local unit = face.unit
    if ns.off or not unit then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        Health(face, unit)
        Text.Health(face, unit)
        face.marks:Heard(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then
        face.marks:Heard(unit, event)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        Power(face, unit)
    elseif event == "UNIT_IN_RANGE_UPDATE" then
        Range(face, unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
        Aggro(face, unit)
    elseif event == "INCOMING_RESURRECT_CHANGED" then
        Rez(face, unit)
    elseif event == "UNIT_AURA" then
        if ns.GroupBuffs.Any() and not Core.Restricted() and Buffed(info) then Buffs(face, unit) end
    elseif event == "UNIT_NAME_UPDATE" then
        Name(face, unit)
    else -- gone offline, come back, dead or alive
        Face.Fill(face)
    end
end
local OnEvent = ns.Guard(Heard)

-- The face follows its button's unit (nil: none): that unit's events alone are heard.
function Face.Unit(face, unit)
    if face.unit == unit then return end
    face:UnregisterAllEvents()
    face.unit = unit
    Yours(face, false)
    if not unit then return face.marks:Set(nil) end
    for _, event in ipairs(Face.EVENTS) do pcall(face.RegisterUnitEvent, face, event, unit) end
    for _, event in ipairs(Core.HealthMarks.EVENTS) do pcall(face.RegisterUnitEvent, face, event, unit) end
    face:SetScript("OnEvent", OnEvent)
    Face.Fill(face)
end

-- Made-up values instead of a unit (the preview): sample = { you (your own slot), raid, name, health (a share), most, mana (a share, or nil),
-- role, mark (a raid marker's number, or nil), icons, barrier, lost (shares), dispel (a kind), ready (a ready check's
-- answer), rez, aggro, word (Dead, Offline), colour }.
function Face.Sample(face, sample)
    face.marks:Sample(sample)
    Yours(face, sample.you == true)
    Colour(face, sample.colour or Bar.GREEN)
    face.health:SetMinMaxValues(0, 1)
    face.health:SetValue(sample.colour and 1 or sample.health)
    face.power:SetShown(sample.mana ~= nil)
    if sample.mana then
        face.power:SetStatusBarColor(0, 0.55, 1)
        face.power:SetValue(sample.mana)
    end
    Border(face, sample.aggro)
    ReadyIcon(face, sample.ready)
    RezIcon(face, sample.rez == true)
    RoleIcon(face, sample.role)
    Text.Mark(face, sample.mark)
    face.name:SetText(sample.you and (sample.raid and ns.TEXT.groupRaid or ns.TEXT.groupParty) or sample.name)
    Text.Sample(face, math.floor(sample.most * sample.health), sample.most, sample.word)
    Icons(face, sample.icons, #sample.icons)
end
