local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Bar
--  The health bar of our dress on a plate: a rectangle round at its corners,
--  as large as the game's own health bar under it (the game's nameplate size
--  and style), with a thin border around it.
--
--  How it is round: the bar's fill, its background and a strip inside it are
--  masked at both ends by Core's caps (Shape.CAP_LEFT, CAP_RIGHT), a quarter
--  of the bar's height wide, wrapped with white beyond them, so the fill keeps
--  its round left corners however short it is and meets the right ones when
--  full. The border is a plate one pixel larger, cut by caps of its own size.
--
--  Health goes to the bar as the game gives it (a secret value in a fight:
--  the bar takes it as it is, nothing is computed with it). The colours are
--  the game's: a player's class colour where the game's nameplate settings
--  colour by class, grey for a creature tapped by others, else the game's
--  colour for what the unit is to you (UnitSelectionColor). The border is lit
--  on your target and your focus, in the game's colours for them.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bar = {}
ns.Bar = Bar

Bar.FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" -- the game's raid frames' health fill
Bar.WHITE = "Interface\\Buttons\\WHITE8X8"
Bar.CAP = 1 / 4 -- a cap's width, as a share of the height of what it rounds
Bar.BACKGROUND = { 0.07, 0.07, 0.09, 0.85 } -- where health is missing
Bar.BORDER = { 0, 0, 0, 0.9 }
Bar.TAPPED = { 0.9, 0.9, 0.9 } -- as the game's own plates colour a creature tapped by others

-- The game's colours for the border of your target's plate and your focus's; ours where it has none.
local function GameColour(name, r, g, b)
    local constants = rawget(_G, "NamePlateConstants")
    local colour = type(constants) == "table" and constants[name]
    if type(colour) == "table" and type(colour.r) == "number" then return { colour.r, colour.g, colour.b, 1 } end
    return { r, g, b, 1 }
end
Bar.TARGET = GameColour("TARGET_BORDER_COLOR", 1, 1, 1)
Bar.FOCUS = GameColour("FOCUS_TARGET_BORDER_COLOR", 1, 0.49, 0.04)

-- Two caps on host, at the left and right ends of rect, over each of the textures. They are sized by Fit.
local function Caps(host, rect, ...)
    local caps = {}
    for index, file in ipairs({ Core.Shape.CAP_LEFT, Core.Shape.CAP_RIGHT }) do
        local mask = host:CreateMaskTexture()
        mask:SetTexture(file, "CLAMPTOWHITE", "CLAMPTOWHITE")
        local side = index == 1 and "LEFT" or "RIGHT"
        mask:SetPoint("TOP" .. side, rect, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, rect, "BOTTOM" .. side)
        for texture = 1, select("#", ...) do select(texture, ...):AddMaskTexture(mask) end
        caps[index] = mask
    end
    return caps
end
Bar.Caps = Caps

-- The caps as wide as they should be for something that high.
function Bar.SizeCaps(caps, height)
    local width = math.max((Plain(height) or 0) * Bar.CAP, 0.01)
    for _, mask in ipairs(caps) do mask:SetWidth(width) end
end

-- The bar's pieces on the dress: the border behind, the status bar inside it, its background and fill.
function Bar.Make(dress)
    local border = dress:CreateTexture(nil, "BACKGROUND", nil, -8)
    border:SetTexture(Bar.WHITE)
    border:SetAllPoints(dress)
    local health = CreateFrame("StatusBar", nil, dress)
    health:SetStatusBarTexture(Bar.FILL)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    local background = health:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(Bar.WHITE)
    background:SetVertexColor(unpack(Bar.BACKGROUND))
    background:SetAllPoints(health)
    dress.border, dress.health, dress.background = border, health, background
    dress.outerCaps = Caps(dress, dress, border)
    dress.caps = Caps(health, health, health:GetStatusBarTexture(), background)
    Bar.Border(dress, nil)
end

-- Laid out for the dress's size: the bar a pixel inside its border, the caps a quarter of each height.
function Bar.Fit(dress)
    local height = Plain(dress:GetHeight()) or 0
    local edge = Core.Pixels(dress, 1)
    dress.edge = edge
    local health = dress.health
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", dress, "TOPLEFT", edge, -edge)
    health:SetPoint("BOTTOMRIGHT", dress, "BOTTOMRIGHT", -edge, edge)
    Bar.SizeCaps(dress.outerCaps, height)
    Bar.SizeCaps(dress.caps, height - 2 * edge)
end

-- Whether the game's nameplate settings colour this player's bar by class (for friends, for foes).
local function ByClass(unit)
    if Plain(UnitIsFriend("player", unit)) then return GetCVarBool("nameplateShowFriendlyClassColor") end
    return GetCVarBool("nameplateShowClassColor")
end

-- The bar's colour for a unit, as the game's own plates choose it: r, g, b.
function Bar.Colour(unit)
    if Plain(UnitIsPlayer(unit)) and ByClass(unit) then
        local _, class = UnitClass(unit)
        class = Plain(class)
        local colours = rawget(_G, "RAID_CLASS_COLORS")
        local colour = type(class) == "string" and colours and colours[class]
        if colour then return colour.r, colour.g, colour.b end
    end
    if Plain(UnitIsTapDenied(unit)) then return Bar.TAPPED[1], Bar.TAPPED[2], Bar.TAPPED[3] end
    local r, g, b = Core.Ask(UnitSelectionColor, unit, true)
    if r and g and b then return r, g, b end
    return 1, 0, 0
end

function Bar.Paint(dress, unit)
    dress.health:SetStatusBarColor(Bar.Colour(unit))
end

-- A game function's first answer as it is, hidden (a secret value) or not; nil where it failed (a unit
-- the game keeps from addons in some places). Tested with type() only: a secret is never compared.
local function Raw(fn, unit)
    local ok, value = pcall(fn, unit)
    if ok then return value end
    return nil
end
Bar.Raw = Raw

-- Health as the game gives it, hidden or not: the bar takes it as it is.
function Bar.Health(dress, unit)
    local most, now = Raw(UnitHealthMax, unit), Raw(UnitHealth, unit)
    if type(most) == "nil" or type(now) == "nil" then return end
    local health = dress.health
    health:SetMinMaxValues(0, most)
    health:SetValue(now)
end

-- The bar as made, full: a plate the game hands out again never shows the last unit's health, even where the
-- next unit's cannot be read.
function Bar.Clear(dress)
    dress.health:SetMinMaxValues(0, 1)
    dress.health:SetValue(1)
end

-- The border: "target", "focus" or nil (dark).
function Bar.Border(dress, lit)
    local colour = lit == "target" and Bar.TARGET or lit == "focus" and Bar.FOCUS or Bar.BORDER
    dress.border:SetVertexColor(colour[1], colour[2], colour[3], colour[4])
end
