local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Resource
--  Your combo points inside your target's health bar, along its bottom: a
--  thin line, as high as the power line (Bar.lua) and right on top of it
--  where the unit has power, one segment per point, lit in the game's colour
--  for combo points as you build them; a point not built shows nothing, the
--  bar is seen through it. In this client combo
--  points are the one class resource, kept on your target (GetComboPoints of
--  "player" on "target", as the game's own combo frame reads them; at most
--  five). So the strip is on your target's plate only, while you build them
--  (a rogue; a druid while energy is the power shown, in cat form) and the
--  target is one you can attack.
--
--  The count may be hidden from addons in a fight (a secret value): each
--  segment is a status bar of its own, from its point less one to its point,
--  and takes the count as it is: the bar clamps it, so a segment is full from
--  its point on and empty below it, and nothing is computed with the count.
--  The segments stand a pixel apart, as many as the most points (plain); the
--  first's and the last's outer corners are the bar's own (its caps mask them).
--  Only rogues and druids listen to anything here.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Resource = {}
ns.Resource = Resource

Resource.MOST = 5      -- the most points, as the game's own combo frame counts them
Resource.CLASSES = { ROGUE = true, DRUID = true }

local holder -- the dress the strip shows on now (your target's)
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
    local width = (Plain(dress:GetWidth()) or 0) - 2 * dress.edge
    local gap = Core.Pixels(dress, 1)
    local segments = strip.segments
    for index = 1, math.max(most, #segments) do
        local segment = segments[index]
        if not segment and index <= most then
            segment = CreateFrame("StatusBar", nil, strip)
            segment:SetStatusBarTexture(ns.Bar.FILL)
            segment:SetStatusBarColor(Colour())
            -- The bar's own caps round the first and the last (masks of another frame, as the game's bars use them).
            for _, mask in ipairs(dress.caps) do segment:GetStatusBarTexture():AddMaskTexture(mask) end
            segments[index] = segment
        end
        if segment then
            local left = width * (index - 1) / most + (index > 1 and gap / 2 or 0)
            local right = width * index / most - (index < most and gap / 2 or 0)
            segment:ClearAllPoints()
            segment:SetPoint("TOPLEFT", strip, "TOPLEFT", left, 0)
            segment:SetPoint("BOTTOMRIGHT", strip, "BOTTOMLEFT", right, 0)
            segment:SetMinMaxValues(index - 1, index) -- full from this point on, empty below it
            segment:SetShown(index <= most)
        end
    end
    strip.most = most
end

local function Make(dress)
    local strip = CreateFrame("Frame", nil, dress.health)
    strip.segments = {}
    strip:Hide()
    dress.strip = strip
end

-- Laid out for the dress's size (Plate's Fit): as high as the power line, on top of it while it shows, else
-- along the bar's bottom; the segments at their places.
function Resource.Fit(dress)
    local strip = dress.strip
    if not strip then return end
    local below = dress.power:IsShown() and dress.power or dress.health
    local edge = below == dress.power and "TOP" or "BOTTOM"
    strip:ClearAllPoints()
    strip:SetPoint("BOTTOMLEFT", below, edge .. "LEFT")
    strip:SetPoint("BOTTOMRIGHT", below, edge .. "RIGHT")
    strip:SetHeight(dress.line or 1)
    Segments(dress)
end

-- The strip on your target's plate, its points as the game gives them; off everywhere else.
function Resource.Update()
    local options = ns.options or {}
    local on = not ns.off and options.resource ~= false and Resource.CLASSES[Core.class] and Building()
    local plate = on and Core.Ask(C_NamePlate.GetNamePlateForUnit, "target")
    local dress = plate and ns.Plate.Of(plate)
    if dress ~= holder then
        if holder and holder.strip then holder.strip:Hide() end
        holder = dress
    end
    if not dress then return end
    if not dress.strip then Make(dress) end
    Resource.Fit(dress) -- the power line may have come or gone under it
    local strip = dress.strip
    if Plain(UnitCanAttack("player", "target")) == false then return strip:Hide() end
    local ok, points = pcall(GetComboPoints, "player", "target")
    if not ok or type(points) == "nil" then return strip:Hide() end
    if strip.most ~= most then Segments(dress) end
    for index = 1, most do strip.segments[index]:SetValue(points) end -- each clamps it to its own point
    strip:Show()
end

-- Whether the strip is on that dress now (a plate the game takes back loses it).
function Resource.Leave(dress)
    if holder == dress then holder = nil end
    if dress.strip then dress.strip:Hide() end
end

local again = Core.Later(Resource.Update) -- once a frame, however many of these come together
-- A plate came or went (Plate.lua): your target's may be among them.
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
