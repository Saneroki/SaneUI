local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Resource
--  Your combo points inside your target's health bar, along its bottom: a
--  strip a third of the bar's height, one segment per point, lit in the
--  game's colour for combo points as you build them. In this client combo
--  points are the one class resource, kept on your target (GetComboPoints of
--  "player" on "target", as the game's own combo frame reads them; at most
--  five). So the strip is on your target's plate only, while you build them
--  (a rogue; a druid while energy is the power shown, in cat form) and the
--  target is one you can attack.
--
--  The count may be hidden from addons in a fight (a secret value): the strip
--  is one status bar from none to the most points, and takes it as it is; the
--  lines between the segments are drawn over it, at their places, from the
--  most (plain). Its bottom corners are the bar's own: the bar's caps mask it.
--  Only rogues and druids listen to anything here.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Resource = {}
ns.Resource = Resource

Resource.SHARE = 1 / 3 -- the strip's height, a share of the bar's
Resource.MOST = 5      -- the most points, as the game's own combo frame counts them
Resource.EMPTY = { 0, 0, 0, 0.55 } -- a point not built: the bar under it darkened
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

-- The lines between the segments and along the strip's top, as many and where they should be.
local function Lines(dress)
    local strip = dress.strip
    local width = (Plain(dress:GetWidth()) or 0) - 2 * dress.edge
    local line = Core.Pixels(dress, 1)
    local lines = strip.lines
    for index = 1, math.max(most - 1, #lines) do
        local texture = lines[index]
        if not texture and index < most then
            texture = strip:CreateTexture(nil, "OVERLAY")
            texture:SetTexture(ns.Bar.WHITE)
            texture:SetVertexColor(ns.Bar.BORDER[1], ns.Bar.BORDER[2], ns.Bar.BORDER[3], ns.Bar.BORDER[4])
            lines[index] = texture
        end
        if texture then
            texture:ClearAllPoints()
            texture:SetPoint("TOP", strip, "TOPLEFT", width * index / most, 0)
            texture:SetPoint("BOTTOM", strip, "BOTTOMLEFT", width * index / most, 0)
            texture:SetWidth(line)
            texture:SetShown(index < most)
        end
    end
    strip.top:SetHeight(line)
    strip.most = most
end

local function Make(dress)
    local health = dress.health
    local strip = CreateFrame("StatusBar", nil, health)
    strip:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
    strip:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    strip:SetStatusBarTexture(ns.Bar.FILL)
    strip:SetStatusBarColor(Colour())
    strip:SetMinMaxValues(0, most)
    strip:SetValue(0)
    local empty = strip:CreateTexture(nil, "BACKGROUND")
    empty:SetTexture(ns.Bar.WHITE)
    empty:SetVertexColor(Resource.EMPTY[1], Resource.EMPTY[2], Resource.EMPTY[3], Resource.EMPTY[4])
    empty:SetAllPoints(strip)
    -- The bar's own caps round the strip's bottom corners (masks of another frame, as the game's bars use them).
    for _, mask in ipairs(dress.caps) do
        strip:GetStatusBarTexture():AddMaskTexture(mask)
        empty:AddMaskTexture(mask)
    end
    local top = strip:CreateTexture(nil, "OVERLAY")
    top:SetTexture(ns.Bar.WHITE)
    top:SetVertexColor(ns.Bar.BORDER[1], ns.Bar.BORDER[2], ns.Bar.BORDER[3], ns.Bar.BORDER[4])
    top:SetPoint("TOPLEFT", strip, "TOPLEFT")
    top:SetPoint("TOPRIGHT", strip, "TOPRIGHT")
    strip.top, strip.lines = top, {}
    strip:Hide()
    dress.strip = strip
end

-- Laid out for the dress's size (Plate's Fit): a third of the bar's height, the lines at their places.
function Resource.Fit(dress)
    if not dress.strip then return end
    local height = (Plain(dress:GetHeight()) or 0) - 2 * dress.edge
    dress.strip:SetHeight(math.max(height * Resource.SHARE, 0.01))
    Lines(dress)
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
    if not dress.strip then
        Make(dress)
        Resource.Fit(dress)
    end
    local strip = dress.strip
    if Plain(UnitCanAttack("player", "target")) == false then return strip:Hide() end
    local ok, points = pcall(GetComboPoints, "player", "target")
    if not ok or type(points) == "nil" then return strip:Hide() end
    if strip.most ~= most then Lines(dress) end
    strip:SetMinMaxValues(0, most)
    strip:SetValue(points)
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
