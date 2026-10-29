local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Bar
--  A unit frame's bar, in the look of a nameplate's (the module Nameplates):
--  a rectangle round at its corners, framed by one thin border, the unit's
--  power a thin line along its bottom, inside it. The frame does not change
--  size with what it shows, so every piece is laid out for its size alone
--  (Bar.Fit, again when its size or scale changes).
--
--  How it is round: the fill and its background are masked at both ends by
--  Core's caps (Shape.CAP_LEFT, CAP_RIGHT), a quarter of the bar's height
--  wide, wrapped with white beyond them, so the fill keeps its round left end
--  however short it is and meets the right one when full. Every plate around
--  it (the border, the rank's line, the glow's bands) is two halves, each round
--  at its own two corners by Core's corner masks (a texture takes few masks),
--  its round fitting the bar's.
--
--  From the inside out:
--    the bar      health as the game gives it (a hidden value in a fight: the
--                 bar takes it as it is); a player's class colour, grey when
--                 tapped by others, a light yellow for a creature that does
--                 not attack on sight, red for one that does, the game's
--                 colour for friends
--    the power    the unit's mana, rage or energy, in the game's colour for it
--    the border   one screen pixel, black
--    the rank     behind the border, reaching farther: gold and thick on a
--                 boss, gold on an elite, silver on a rare
--    the glow     red, solid at the edge and fading outwards: you have the
--                 unit's aggro (your own frame: anything's), or it is a player
--                 who may attack you
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bar = {}
ns.UnitBar = Bar

Bar.FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" -- the game's raid frames' health fill
Bar.WHITE = "Interface\\Buttons\\WHITE8X8"
Bar.CAP = 1 / 4  -- a cap's width and every corner's round, a share of the bar's height
Bar.LINE = 1 / 4 -- the power line's height, a share of the bar's
Bar.BACKGROUND = { 0.07, 0.07, 0.09, 1 } -- where health is missing: solid, so nothing behind shows through
Bar.BORDER = { 0, 0, 0, 0.9 }
Bar.TAPPED = { 0.5, 0.5, 0.5 }
Bar.CALM = { 1, 0.93, 0.55 }
Bar.HOSTILE = { 1, 0, 0 }
Bar.GLOW = { 1, 0.08, 0.05 }
Bar.HALO = 6 -- the glow's bands, a screen pixel each, solid inside and fading out
local GOLD = { 1, 0.82, 0, 1 }
local gold = rawget(_G, "NORMAL_FONT_COLOR")
if type(gold) == "table" and type(gold.r) == "number" then GOLD = { gold.r, gold.g, gold.b, 1 } end
Bar.RANKS = {
    boss = { colour = GOLD, width = 4 },
    elite = { colour = GOLD, width = 2 },
    rare = { colour = { 0.8, 0.82, 0.88, 1 }, width = 2 },
}
Bar.PLAIN = { width = 1 } -- no rank: the border alone
local RANK_OF = { worldboss = "boss", elite = "elite", rare = "rare", rareelite = "rare" }

-- How solid the glow is in a band (1 the innermost, falling off softly), and so how strong that band's plate is
-- over the plates beyond it: each plate's strength is its vertex alpha.
local function Fade(band)
    local share = 1 - (band - 1) / Bar.HALO
    return share * share
end
local function Strength(band)
    local beyond = band < Bar.HALO and Fade(band + 1) or 0
    return 1 - (1 - Fade(band)) / (1 - beyond)
end

-- A plate of one colour around the frame, in two halves, each rounding its own two corners.
local Halves = {}
Halves.__index = Halves
function Halves:SetVertexColor(r, g, b, a)
    for _, half in ipairs(self) do half:SetVertexColor(r, g, b, a) end
end
function Halves:SetShown(on)
    for _, half in ipairs(self) do half:SetShown(on) end
end

local function Plate(host, sublevel)
    local plate = setmetatable({}, Halves)
    for index, corners in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" } }) do
        local half = host:CreateTexture(nil, "BACKGROUND", nil, sublevel)
        half:SetTexture(Bar.WHITE)
        half.corners = {}
        for _, corner in ipairs(corners) do
            local mask = host:CreateMaskTexture()
            mask:SetTexture(Core.Shape.CORNER[corner], "CLAMPTOWHITE", "CLAMPTOWHITE")
            mask:SetPoint(corner, half, corner)
            half:AddMaskTexture(mask)
            half.corners[#half.corners + 1] = mask
        end
        plate[index] = half
    end
    return plate
end

-- A plate reaching that far beyond the frame on every side, its corners round by radius and that reach.
local function Around(plate, frame, reach, height, radius)
    local half = (height + 2 * reach) / 2
    local upper, lower = plate[1], plate[2]
    upper:ClearAllPoints()
    upper:SetPoint("TOPLEFT", frame, "TOPLEFT", -reach, reach)
    upper:SetPoint("TOPRIGHT", frame, "TOPRIGHT", reach, reach)
    upper:SetHeight(half)
    lower:ClearAllPoints()
    lower:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -reach, -reach)
    lower:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", reach, -reach)
    lower:SetHeight(half)
    local round = math.max(math.min(radius + reach, half), 0.01)
    for _, piece in ipairs(plate) do
        for _, mask in ipairs(piece.corners) do mask:SetSize(round, round) end
    end
end

-- The bar's pieces on the frame, each layer on a frame of its own one level above the last: the glow, then the
-- rank's line and the border, then the health with its background and power line (the texts above it all).
function Bar.Make(frame)
    local level = Plain(frame:GetFrameLevel()) or 1
    local glow = CreateFrame("Frame", nil, frame)
    glow:SetAllPoints(frame)
    glow:SetFrameLevel(level + 1)
    glow:SetAlpha(0) -- only this frame's alpha switches the glow: its bands' strengths are their own alphas
    frame.glow, frame.halo = glow, {}
    for band = 1, Bar.HALO do
        local plate = Plate(glow, 0)
        plate:SetVertexColor(Bar.GLOW[1], Bar.GLOW[2], Bar.GLOW[3], Strength(band))
        frame.halo[band] = plate
    end
    local edges = CreateFrame("Frame", nil, frame)
    edges:SetAllPoints(frame)
    edges:SetFrameLevel(level + 2)
    frame.rankLine = Plate(edges, -4)
    frame.rankLine:SetShown(false)
    frame.border = Plate(edges, -3)
    frame.border:SetVertexColor(Bar.BORDER[1], Bar.BORDER[2], Bar.BORDER[3], Bar.BORDER[4])
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetFrameLevel(level + 3)
    health:SetStatusBarTexture(Bar.FILL)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    local background = health:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(Bar.WHITE)
    background:SetVertexColor(unpack(Bar.BACKGROUND))
    background:SetAllPoints(health)
    frame.health = health
    frame.caps = {}
    for index, file in ipairs({ Core.Shape.CAP_LEFT, Core.Shape.CAP_RIGHT }) do
        local mask = health:CreateMaskTexture()
        mask:SetTexture(file, "CLAMPTOWHITE", "CLAMPTOWHITE")
        local side = index == 1 and "LEFT" or "RIGHT"
        mask:SetPoint("TOP" .. side, health, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, health, "BOTTOM" .. side)
        health:GetStatusBarTexture():AddMaskTexture(mask)
        background:AddMaskTexture(mask)
        frame.caps[index] = mask
    end
    -- No background: where the unit's power is spent, the bar is seen through the line.
    local power = CreateFrame("StatusBar", nil, health)
    power:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
    power:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    power:SetStatusBarTexture(Bar.FILL)
    power:SetMinMaxValues(0, 1)
    power:SetValue(0)
    for _, mask in ipairs(frame.caps) do power:GetStatusBarTexture():AddMaskTexture(mask) end
    power:Hide()
    frame.power = power
    frame.rank = Bar.PLAIN
end

-- Laid out for the frame's size and the unit's rank: the bar a screen pixel inside its border, the rank's line
-- reaching out from the same edge, the glow beyond it, the caps a quarter of the bar's height.
function Bar.Fit(frame)
    local height = Plain(frame:GetHeight()) or 0
    local pixel = Core.Pixels(frame, 1)
    local radius = height * Bar.CAP
    Around(frame.border, frame, 0, height, radius)
    local reach = frame.rank.width - 1 -- the border is the rank's first pixel
    Around(frame.rankLine, frame, pixel * reach, height, radius)
    for band, plate in ipairs(frame.halo) do Around(plate, frame, pixel * (reach + band), height, radius) end
    local health = frame.health
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", frame, "TOPLEFT", pixel, -pixel)
    health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -pixel, pixel)
    local width = math.max((height - 2 * pixel) * Bar.CAP, 0.01)
    for _, mask in ipairs(frame.caps) do mask:SetWidth(width) end
    frame.power:SetHeight(math.max((height - 2 * pixel) * Bar.LINE, pixel * 2))
end

-- A unit's rank by the line behind the border ("boss", "elite", "rare"), or nil.
function Bar.Rank(unit)
    if Core.Ask(rawget(_G, "UnitIsBossMob"), unit) then return "boss" end
    local classification = Core.Ask(UnitClassification, unit)
    return type(classification) == "string" and RANK_OF[classification] or nil
end

-- The bar's colour for a unit: r, g, b.
function Bar.Colour(unit)
    if Core.Ask(UnitIsPlayer, unit) then
        local _, class = Core.Ask(UnitClass, unit)
        local colours = rawget(_G, "RAID_CLASS_COLORS")
        local colour = type(class) == "string" and type(colours) == "table" and colours[class]
        if colour then return colour.r, colour.g, colour.b end
    elseif Core.Ask(UnitIsTapDenied, unit) then
        return Bar.TAPPED[1], Bar.TAPPED[2], Bar.TAPPED[3]
    else
        local reaction = Core.Ask(UnitReaction, unit, "player")
        if reaction == 4 then return Bar.CALM[1], Bar.CALM[2], Bar.CALM[3] end
        if reaction and reaction < 4 then return Bar.HOSTILE[1], Bar.HOSTILE[2], Bar.HOSTILE[3] end
    end
    local r, g, b = Core.Ask(UnitSelectionColor, unit, true)
    if r and g and b then return r, g, b end
    return Bar.HOSTILE[1], Bar.HOSTILE[2], Bar.HOSTILE[3]
end

-- The bar's colour, the rank's line and the glow of a player who may attack you, as the unit is now.
function Bar.Paint(frame, unit)
    frame.health:SetStatusBarColor(Bar.Colour(unit))
    local rank = Bar.RANKS[Bar.Rank(unit)] or Bar.PLAIN
    if rank ~= frame.rank then
        frame.rank = rank
        Bar.Fit(frame)
    end
    local colour = rank.colour
    if colour then frame.rankLine:SetVertexColor(colour[1], colour[2], colour[3], colour[4]) end
    frame.rankLine:SetShown(colour ~= nil)
    frame.danger = Core.Ask(UnitIsPlayer, unit) == true and Core.Ask(UnitCanAttack, unit, "player") == true
    Bar.Glow(frame, frame.aggro)
end

-- The glow on while you have aggro (true, false, or the game's answer hidden: the frame's alpha takes it as it is,
-- never compared) or while the unit is a player who may attack you.
function Bar.Glow(frame, aggro)
    frame.aggro = aggro
    local glow = frame.glow
    if frame.danger then
        glow:SetAlpha(1)
    elseif Core.Secret(aggro) then
        if not pcall(glow.SetAlphaFromBoolean, glow, aggro) then glow:SetAlpha(0) end
    else
        glow:SetAlpha(aggro and 1 or 0)
    end
end

-- A game function's first answer as it is, hidden or not; nil where it failed. Tested with type() only.
local function Raw(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
    return nil
end
Bar.Raw = Raw

-- Health as the game gives it, hidden or not; none (empty) for a dead unit.
function Bar.Health(frame, unit)
    local most, now = Raw(UnitHealthMax, unit), Raw(UnitHealth, unit)
    if type(most) == "nil" or type(now) == "nil" then return end
    frame.health:SetMinMaxValues(0, most)
    frame.health:SetValue(now)
end

-- The game's colour for a power, by its token ("MANA", "RAGE", "ENERGY").
local function PowerColour(token)
    local colours = rawget(_G, "PowerBarColor")
    local colour = type(colours) == "table" and type(token) == "string" and colours[token]
    if type(colour) == "table" and type(colour.r) == "number" then return colour.r, colour.g, colour.b end
    return 0, 0.55, 1
end

-- The unit's power along the bar's bottom, as the game gives it; none where the unit has none (a most of 0, as
-- far as can be told: a hidden most shows the line).
function Bar.Power(frame, unit)
    local most = Raw(UnitPowerMax, unit)
    local on = type(most) ~= "nil" and Plain(most) ~= 0
    local power = frame.power
    if on then
        local _, token = Core.Ask(UnitPowerType, unit)
        power:SetStatusBarColor(PowerColour(token))
        power:SetMinMaxValues(0, most)
        local now = Raw(UnitPower, unit)
        if type(now) ~= "nil" then power:SetValue(now) end
    end
    power:SetShown(on)
end
