local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - GroupFace
--  What one member of your party or raid looks like: a nameplate's bar, a bit
--  shorter and taller, one height whatever it shows:
--    left    the raid marker, then the name, with as much room as the frame
--            has (Saneroki, 2026-10-30: little space at the ends and between
--            the pieces, Face.INSET, Face.GAP)
--    right   how much health is left ("85%"); nothing on a frame too narrow for
--            that as well (Face.BARE), so the name gets it; Dead or Offline always
--    over it an icon for each of your buffs the unit is missing (GroupBuffs.lua),
--            the dispel icon on the first: they float over the name, which goes
--            on behind them and takes no room from it
--    bottom  the mana of a tank or healer, a line inside the bar as on a
--            nameplate, so the frame is no taller for it
--  and on it Core's health marks (the barrier, the lost maximum health, the ring
--  of what can be dispelled: along the bar's edge, inside it, as these frames
--  stand edge to edge). Green for everyone, as every unit frame.
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
local Face = {}
ns.GroupFace = Face

Face.LINE = 1 / 5    -- the power line's height, a share of the bar's
Face.INSET, Face.GAP = 3, 2 -- the words from the bar's ends, and between two pieces
Face.BARE = 80       -- narrower than this: no health at all, the name has it all
Face.ICON = 14       -- an icon beside the name, square
Face.ICON_GAP = 1    -- between them
Face.FAR = 0.45      -- how solid a unit out of your reach is
Face.RING = 2        -- how many screen pixels thick the ring of what can be dispelled is
Face.HEALERS = { PRIEST = true, DRUID = true, SHAMAN = true, PALADIN = true, MONK = true, EVOKER = true }
Face.EVENTS = { "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
                "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_FLAGS", "UNIT_IN_RANGE_UPDATE", "UNIT_AURA" }

-- The icons over the name: from the health leftwards, the dispel icon on the first.
local function Roomed(face, right)
    local start = right + Face.GAP
    for index, icon in ipairs(face.icons) do
        icon:ClearAllPoints()
        icon:SetPoint("RIGHT", face.floating, "RIGHT", -(start + (index - 1) * (Face.ICON + Face.ICON_GAP)), 0)
    end
    face.marks:Place(face.floating, "RIGHT", -start, -Face.ICON / 2)
end

-- The ring of what can be dispelled: four strips along the bar's edge, rounded by the bar's own ends, coloured as one.
local Strips = {}
Strips.__index = Strips
function Strips:SetVertexColor(r, g, b, a)
    for _, strip in ipairs(self) do strip:SetVertexColor(r, g, b, a) end
end

local function Ring(host, health)
    local ring = setmetatable({}, Strips)
    for index = 1, 4 do
        local strip = host:CreateTexture(nil, "OVERLAY")
        strip:SetTexture(Bar.WHITE)
        for _, mask in ipairs(health.ends) do strip:AddMaskTexture(mask) end
        ring[index] = strip
    end
    return ring
end

-- The strips inside the face's border, a pixel in on every side.
local function LayRing(ring, face, pixel)
    local thick = pixel * Face.RING
    for index, sides in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" },
                                 { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local strip = ring[index]
        strip:ClearAllPoints()
        for _, side in ipairs(sides) do
            strip:SetPoint(side, face, side, side:find("LEFT") and pixel or -pixel, side:find("TOP") and -pixel or pixel)
        end
        if index <= 2 then strip:SetHeight(thick) else strip:SetWidth(thick) end
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
    for _, ring in ipairs(marks.rings) do LayRing(ring, face, pixel) end
    local inner = width - 2 * pixel
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", face, "TOPLEFT", pixel, -pixel)
    health:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -pixel - marks:Reach(inner), pixel)
    local tall, round = height - 2 * pixel, math.max(radius - pixel, 0.01)
    Bar.Ends(health, "both", round, tall)
    Bar.End(marks.lostEnd, marks.lost, "RIGHT", "both", round, tall)
    marks:Fit(inner)
    face.power:SetHeight(math.max(tall * Face.LINE, pixel * 2))
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
    Text.MakeLine(face, Face.INSET, Face.GAP)
    face.compact = true
    -- Over the words: what floats on them.
    face.floating = CreateFrame("Frame", nil, face)
    face.floating:SetAllPoints(face)
    face.floating:SetFrameLevel(level + 7)
    face.marks = Core.HealthMarks.New(face, health, {
        masks = health.ends, size = Face.ICON, sample = sample, inside = true, above = level + 8,
        ring = function(host) return Ring(host, health) end, fit = function() Face.Fit(face) end })
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
            icon:SetTexCoord(unpack(Core.HealthMarks.CROP))
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

-- Whether the unit gets the power line: by its role, without one a main tank or a class that heals.
function Face.WantsPower(unit)
    local role = Core.Ask(UnitGroupRolesAssigned, unit)
    if role == "TANK" or role == "HEALER" then return true end
    if role == "DAMAGER" then return false end
    if Core.Ask(rawget(_G, "GetPartyAssignment"), "MAINTANK", unit) then return true end
    local _, class = Core.Ask(UnitClass, unit)
    return Face.HEALERS[class] == true
end

local KIND = { type = Bar.MANA, token = "MANA" } -- read again each time: the power line's kind

-- The power line as the unit's role says: its mana, or its own power where it has none.
local function Power(face, unit)
    local on = Face.WantsPower(unit)
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

-- Everything for the face's unit, as the game says it now.
function Face.Fill(face)
    local unit = face.unit
    if ns.off or not unit or not Core.Ask(UnitExists, unit) then return end
    Bar.Health(face.health, unit)
    face.marks:Set(unit)
    Power(face, unit)
    Range(face, unit)
    Text.Raid(face, unit)
    Text.Name(face, unit)
    Text.Health(face, unit)
    Buffs(face, unit)
end

local function Heard(face, event)
    local unit = face.unit
    if ns.off or not unit then return end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        Bar.Health(face.health, unit)
        Text.Health(face, unit)
        face.marks:Heard(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then
        face.marks:Heard(unit, event)
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        Power(face, unit)
    elseif event == "UNIT_IN_RANGE_UPDATE" then
        Range(face, unit)
    elseif event == "UNIT_AURA" then
        if ns.GroupBuffs.Any() and not Core.Restricted() then Buffs(face, unit) end
    elseif event == "UNIT_NAME_UPDATE" then
        Text.Name(face, unit)
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
    if not unit then return face.marks:Set(nil) end
    for _, event in ipairs(Face.EVENTS) do pcall(face.RegisterUnitEvent, face, event, unit) end
    for _, event in ipairs(Core.HealthMarks.EVENTS) do pcall(face.RegisterUnitEvent, face, event, unit) end
    face:SetScript("OnEvent", OnEvent)
    Face.Fill(face)
end

-- Made-up values instead of a unit (the preview): sample = { name, health (a share), most, mana (a share, or nil),
-- mark (a raid marker's number, or nil), icons, barrier, lost (shares), dispel (a kind), word (Dead, Offline) }.
function Face.Sample(face, sample)
    face.health:SetMinMaxValues(0, 1)
    face.health:SetValue(sample.health)
    face.marks:Sample(sample)
    face.power:SetShown(sample.mana ~= nil)
    if sample.mana then
        face.power:SetStatusBarColor(0, 0.55, 1)
        face.power:SetValue(sample.mana)
    end
    Text.Mark(face, sample.mark)
    face.name:SetText(sample.name)
    Text.Sample(face, math.floor(sample.most * sample.health), sample.most, sample.word)
    Icons(face, sample.icons, #sample.icons)
end
