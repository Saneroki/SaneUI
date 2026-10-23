local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Resource
--  Your combo points in a row of their own under the health bar of the unit
--  you have them on,
--  inside the plate's one outline (Bar.Outline: the bar, this row, the cast
--  bar under it while a cast shows; nothing between them): Resource.SHARE of
--  the bar's height, one segment per point a pixel apart, lit in the game's
--  colour for combo points as you build them, the bar's dark where a point is
--  not built; round at its bottom corners only while nothing is under it
--  (Resource.Shape). In this client combo
--  points are the one class resource, kept on one unit (the game's own combo
--  frame reads them as GetComboPoints of "player" on "target"; at most five).
--  Every plate of a unit you can attack is asked the same of its own unit, so
--  the row shows on whichever plate holds at least one point, your target's
--  or not, and on none while you have none; only while you build them (a
--  rogue; a druid while energy is the power shown, in cat form).
--
--  The count may be hidden from addons (a secret value, where the game
--  restricts units' power): whether it is more than none cannot be told then,
--  so a hidden count shows on your target's plate alone, as it is. Each
--  segment is a status bar of its own, from its point less one to its point,
--  and takes the count as it is: the bar clamps it, so a segment is full from
--  its point on and empty below it, and nothing is computed with the count.
--  The segments stand a pixel apart, as many as the most points (plain); the
--  row's caps mask them all (the first's and the last's outer corners).
--  Only rogues and druids listen to anything here.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Resource = {}
ns.Resource = Resource

Resource.MOST = 5      -- the most points, as the game's own combo frame counts them
Resource.SHARE = 1 / 3 -- the row's height, a share of the bar's (Saneroki, 2026-10-23: as thin as the power line)
Resource.CLASSES = { ROGUE = true, DRUID = true }

local most = Resource.MOST

-- The game's colour for combo points; ours where it has none.
local function Colour()
    local colours = rawget(_G, "PowerBarColor")
    local colour = type(colours) == "table" and colours.COMBO_POINTS
    if type(colour) == "table" and type(colour.r) == "number" then return colour.r, colour.g, colour.b end
    return 1, 0.96, 0.41
end

-- Whether you build combo points now: the game gives you some, and energy is the power shown (a rogue;
-- a druid in cat form). The most of them kept as the game says it (plain), no more than the game shows.
local function Building()
    local types = rawget(_G, "Enum") and Enum.PowerType
    if not types then return false end
    local top = Plain(UnitPowerMax("player", types.ComboPoints))
    if type(top) == "number" and top > 0 then most = math.min(top, Resource.MOST) end
    local shown = Plain(UnitPowerType("player"))
    return type(top) ~= "number" or top > 0 and shown == types.Energy
end
Resource.Building = Building

-- The segments, as many as the most points and where they should be: side by side over the strip's width, a
-- pixel apart.
local function Segments(dress)
    local strip = dress.strip
    local inner = strip.inner
    local width = (Plain(dress:GetWidth()) or 0) - 2 * dress.edge
    local gap = Core.Pixels(dress, 1)
    local segments = strip.segments
    for index = 1, math.max(most, #segments) do
        local segment = segments[index]
        if not segment and index <= most then
            segment = CreateFrame("StatusBar", nil, inner)
            segment:SetStatusBarTexture(ns.Bar.FILL)
            segment:SetStatusBarColor(Colour())
            -- The row's caps round the first and the last (masks of another frame, as the game's bars use them).
            for _, mask in ipairs(strip.caps) do segment:GetStatusBarTexture():AddMaskTexture(mask) end
            segments[index] = segment
        end
        if segment then
            local left = width * (index - 1) / most + (index > 1 and gap / 2 or 0)
            local right = width * index / most - (index < most and gap / 2 or 0)
            segment:ClearAllPoints()
            segment:SetPoint("TOPLEFT", inner, "TOPLEFT", left, 0)
            segment:SetPoint("BOTTOMRIGHT", inner, "BOTTOMLEFT", right, 0)
            segment:SetMinMaxValues(index - 1, index) -- full from this point on, empty below it
            segment:SetShown(index <= most)
        end
    end
    strip.most = most
end

local Outline = ns.Guard(function(strip) ns.Bar.Outline(strip.dress) end)

-- The row under the dress: inside it (a pixel in from the outline at its ends, and at its bottom while nothing is
-- under it) the bar's dark and the segments over it, cut round by the row's caps.
local function Make(dress)
    local strip = CreateFrame("Frame", nil, dress)
    strip:SetPoint("TOPLEFT", dress, "BOTTOMLEFT", 0, 0)
    strip:SetPoint("TOPRIGHT", dress, "BOTTOMRIGHT", 0, 0)
    strip:SetFrameLevel((Plain(dress:GetFrameLevel()) or 1) + 3)
    local inner = CreateFrame("Frame", nil, strip)
    local back = inner:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(ns.Bar.WHITE)
    back:SetVertexColor(ns.Bar.BACKGROUND[1], ns.Bar.BACKGROUND[2], ns.Bar.BACKGROUND[3], ns.Bar.BACKGROUND[4])
    back:SetAllPoints(inner)
    strip.inner, strip.back, strip.segments, strip.dress = inner, back, {}, dress
    strip.caps = ns.Bar.Caps(inner, inner, back)
    -- The plate's one outline around it too while it shows, and the cast bar under it (Bar.Outline).
    strip:SetScript("OnShow", Outline)
    strip:SetScript("OnHide", Outline)
    strip:Hide()
    dress.strip = strip
end

-- Laid out for the dress's size (Plate's Fit): Resource.SHARE of its height; the segments at their places.
function Resource.Fit(dress)
    local strip = dress.strip
    if not strip then return end
    strip:SetHeight(math.max((Plain(dress:GetHeight()) or 0) * Resource.SHARE, 1))
    Resource.Shape(dress, not (dress.cast and dress.cast:IsShown()))
    Segments(dress)
end

-- The row's inside as the outline has it (Bar.Outline): a pixel in at its ends; at its bottom too and round there
-- (a pixel less than the outline) while it is the lowest, square and down to what is under it otherwise.
function Resource.Shape(dress, lowest)
    local strip = dress.strip
    if not strip then return end
    local edge = Core.Pixels(dress, 1)
    local inner = strip.inner
    inner:ClearAllPoints()
    inner:SetPoint("TOPLEFT", strip, "TOPLEFT", edge, 0)
    inner:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", -edge, lowest and edge or 0)
    local height = (Plain(strip:GetHeight()) or 0) - (lowest and edge or 0)
    local mode = lowest and "bottom" or "none"
    ns.Bar.Ends(strip.caps, inner, mode, mode, math.max(ns.Bar.Radius(dress) - edge, 0.01), height)
end

-- One plate's row: shown with its unit's points while you have at least one on it (a hidden count: on your target's
-- plate only), hidden otherwise.
local function One(unit, dress, on)
    local points
    if on and Plain(UnitCanAttack("player", unit)) ~= false then
        local ok, count = pcall(GetComboPoints, "player", unit)
        if ok then points = count end
    end
    local plain = Plain(points)
    local show
    if type(points) == "nil" then
        show = false
    elseif plain == nil then
        show = Plain(UnitIsUnit(unit, "target")) == true
    else
        show = type(plain) == "number" and plain > 0
    end
    if not show then
        if dress.strip then dress.strip:Hide() end
        return
    end
    if not dress.strip then
        Make(dress)
        Resource.Fit(dress)
    end
    local strip = dress.strip
    if strip.most ~= most then Segments(dress) end
    for index = 1, most do strip.segments[index]:SetValue(points) end -- each clamps it to its own point
    strip:Show()
end

-- Every plate's row, its unit's points as the game gives them.
function Resource.Update()
    local options = ns.options or {}
    local on = not ns.off and options.resource ~= false and Resource.CLASSES[Core.class] and Building()
    for unit, dress in pairs(ns.Plate.shown) do One(unit, dress, on) end
end

-- A plate the game takes back loses its row.
function Resource.Leave(dress)
    if dress.strip then dress.strip:Hide() end
end

local again = Core.Later(Resource.Update) -- once a frame, however many of these come together
-- A plate came or went (Plate.lua): its unit may hold points.
function Resource.Again()
    if Resource.CLASSES[Core.class] then again() end
end

local function Power(_, token)
    token = Plain(token)
    if token == nil or token == "COMBO_POINTS" then again() end
end

function Resource.Start()
    if not Resource.CLASSES[Core.class] then return end
    Core.OnUnit("UNIT_POWER_UPDATE", "player", Power)
    Core.OnUnit("UNIT_MAXPOWER", "player", again)
    Core.OnUnit("UNIT_DISPLAYPOWER", "player", again)
    ns.On("PLAYER_TARGET_CHANGED", again)
    ns.On("COMBO_TARGET_CHANGED", again)
    again()
end
