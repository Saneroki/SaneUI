local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Bar
--  The health bar of our dress on a plate: a rectangle round at its corners,
--  as large as the game's own health bar under it (the game's nameplate size
--  and style), framed by one thin border, with the unit's power as a thin
--  line along its bottom, inside it.
--
--  How it is round: the bar's fill, its background and the lines inside it
--  are masked at both ends (Bar.End): by Core's caps (Shape.CAP_LEFT,
--  CAP_RIGHT), a quarter of the bar's height wide, or, while its cast bar is
--  under it, by Core's corner masks at its top alone (Shape.CORNER); wrapped
--  with white beyond them, so the fill keeps its round left corners however
--  short it is and meets the right ones when full. Every plate around it (the
--  border, the rank's line, the glow) is two halves, each round at its own
--  corners by corner masks, so its round is the same whatever its height; the
--  rounds fit each other (Bar.Radius).
--
--  From the inside out:
--    the bar      health as the game gives it (a secret value in a fight: the
--                 bar takes it as it is, nothing is computed with it); a
--                 player's class colour, grey when tapped by others, a light
--                 yellow for a creature that does not attack on sight, red
--                 for one that does, the game's colour for friends
--    the power    the unit's mana, rage or energy, a thin line along the bar's
--                 bottom, in the game's colour for that power; no background:
--                 spent power shows nothing
--    the border   one pixel: black; white on your target, orange on your
--                 focus (the game's colours for them); red on a foe out of
--                 reach of all your attacks (Range.lua)
--  and behind the border, from the same inner edge but reaching farther:
--    the rank     a line in the rank's colour: gold and thick on a boss, gold
--                 on an elite, silver on a rare
--    the glow     red, solid at the bar's edge and fading out beyond the
--                 rank's line: you have the unit's aggro (Text.lua says), or
--                 it is a player who may attack you
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bar = {}
ns.Bar = Bar

Bar.FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" -- the game's raid frames' health fill
Bar.WHITE = "Interface\\Buttons\\WHITE8X8"
Bar.CAP = 1 / 4 -- a cap's width, as a share of the height of what it rounds
Bar.LINE = 1 / 3 -- the power line's height (and the combo points'), a share of the bar's
Bar.BACKGROUND = { 0.07, 0.07, 0.09, 1 } -- where health is missing: solid, so the outline behind the bar never shows
                                             -- through it (nor through the fill's soft top and bottom rows)
Bar.BORDER = { 0, 0, 0, 0.9 }
Bar.TAPPED = { 0.5, 0.5, 0.5 }      -- tapped by others
Bar.CALM = { 1, 0.93, 0.55 }        -- a creature that does not attack on sight (neutral to you)
Bar.HOSTILE = { 1, 0, 0 }           -- one that does
Bar.GLOW = { 1, 0.08, 0.05 }
-- The glow: a red edge around the bar, solid where it meets the border and fading to nothing outwards. Drawn as
-- Bar.HALO round plates a screen pixel apart, each reaching a pixel farther; Bar.Fade says how solid the glow is in
-- each pixel's band (1 the innermost, falling off softly), and each plate is as strong as that band needs over the
-- plates beyond it. The plates' strengths are their vertex colours' alpha, which a texture's own alpha would
-- replace: so they stand on a frame of their own (dress.glow), under the outline's, and only that frame's alpha
-- switches the glow.
Bar.HALO = 6
function Bar.Fade(band)
    local share = 1 - (band - 1) / Bar.HALO
    return share * share
end
-- How strong the plate of a band is, so that it and those beyond it together are as solid as Bar.Fade says.
function Bar.Strength(band)
    local beyond = band < Bar.HALO and Bar.Fade(band + 1) or 0
    return 1 - (1 - Bar.Fade(band)) / (1 - beyond)
end

-- A colour of the game's as { r, g, b, 1 }; ours where it has none.
local function GameColour(colour, r, g, b)
    if type(colour) == "table" and type(colour.r) == "number" then return { colour.r, colour.g, colour.b, 1 } end
    return { r, g, b, 1 }
end
local constants = rawget(_G, "NamePlateConstants")
constants = type(constants) == "table" and constants or {}
Bar.TARGET = GameColour(constants.TARGET_BORDER_COLOR, 1, 1, 1)
Bar.FOCUS = GameColour(constants.FOCUS_TARGET_BORDER_COLOR, 1, 0.49, 0.04)
local GOLD = GameColour(rawget(_G, "NORMAL_FONT_COLOR"), 1, 0.82, 0)
local SILVER = { 0.8, 0.82, 0.88, 1 }

-- A unit's rank, by the line behind the border: its colour and how many screen pixels it reaches from the bar's edge
-- (the border covers the first).
Bar.RANKS = {
    boss = { colour = GOLD, width = 4 },
    elite = { colour = GOLD, width = 2 },
    rare = { colour = SILVER, width = 2 },
}
Bar.PLAIN = { width = 1 } -- no line: only the border
local RANK_OF = { worldboss = "boss", elite = "elite", rare = "rare", rareelite = "rare" }

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

-- One end's mask (the left or right one of Caps) laid over rect for what that end of it should be:
--   "both"    round at its top and bottom (a cap, a quarter of the height wide: its round is a quarter of the height)
--   "top"     round at its top alone, by radius (a corner mask): square below, where something meets it
--   "bottom"  round at its bottom alone
--   "none"    square (the mask white all over)
function Bar.End(mask, rect, side, mode, radius, height)
    local shape = Core.Shape
    mask:ClearAllPoints()
    if mode == "both" then
        mask:SetTexture(side == "LEFT" and shape.CAP_LEFT or shape.CAP_RIGHT, "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint("TOP" .. side, rect, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, rect, "BOTTOM" .. side)
        mask:SetWidth(math.max((height or 0) * Bar.CAP, 0.01))
    elseif mode == "top" or mode == "bottom" then
        local corner = (mode == "top" and "TOP" or "BOTTOM") .. side
        mask:SetTexture(shape.CORNER[corner], "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint(corner, rect, corner)
        mask:SetSize(math.max(radius, 0.01), math.max(radius, 0.01))
    else
        mask:SetTexture(Bar.WHITE, "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint("TOP" .. side, rect, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, rect, "BOTTOM" .. side)
        mask:SetWidth(1)
    end
end

-- Both ends of rect (its Caps, rect that high): left as left says, right as right says.
function Bar.Ends(caps, rect, left, right, radius, height)
    Bar.End(caps[1], rect, "LEFT", left, radius, height)
    Bar.End(caps[2], rect, "RIGHT", right, radius, height)
end

-- A plate of one colour around the dress (the border, the rank's line, a band of the glow), in two halves, each
-- rounding its own two corners by a corner mask: its round the same, however tall the plate (the bar alone, or the
-- bar and its cast bar). Coloured and shown as one.
local Halves = {}
Halves.__index = Halves
function Halves:SetVertexColor(r, g, b, a)
    for _, half in ipairs(self) do half:SetVertexColor(r, g, b, a) end
end
function Halves:SetShown(on)
    for _, half in ipairs(self) do half:SetShown(on) end
end
function Halves:Show() self:SetShown(true) end
function Halves:Hide() self:SetShown(false) end
function Halves:IsShown() return self[1]:IsShown() end

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

-- A plate reaching that far beyond the dress on every side, down to the bottom of below (the dress, or its cast bar
-- under it while a cast shows), tall high from the dress's top to below's bottom: its halves each half of it, its
-- corners round by radius and the reach (around a round edge, the round grows by what lies between).
local function Around(plate, dress, reach, tall, below, radius)
    local half = (tall + 2 * reach) / 2
    local upper, lower = plate[1], plate[2]
    upper:ClearAllPoints()
    upper:SetPoint("TOPLEFT", dress, "TOPLEFT", -reach, reach)
    upper:SetPoint("TOPRIGHT", dress, "TOPRIGHT", reach, reach)
    upper:SetHeight(half)
    lower:ClearAllPoints()
    lower:SetPoint("BOTTOMLEFT", below or dress, "BOTTOMLEFT", -reach, -reach)
    lower:SetPoint("BOTTOMRIGHT", below or dress, "BOTTOMRIGHT", reach, -reach)
    lower:SetHeight(half)
    local round = math.min(radius + reach, half)
    for _, piece in ipairs(plate) do
        for _, mask in ipairs(piece.corners) do mask:SetSize(round, round) end
    end
end

-- The bar's pieces on the dress, each layer on a frame of its own one level above the last, so none can cover the
-- one meant above it: the glow, then the rank's line and the border, then the status bar with its background, fill
-- and power line (and the line of texts above it all, Text.lua).
function Bar.Make(dress)
    local level = Plain(dress:GetFrameLevel()) or 1
    -- The glow: its plates' strengths are their vertex alpha, so only its frame's alpha switches it.
    local holder = CreateFrame("Frame", nil, dress)
    holder:SetAllPoints(dress)
    holder:SetFrameLevel(level + 1)
    holder:SetAlpha(0)
    dress.glow, dress.halo = holder, {}
    for band = 1, Bar.HALO do
        local glow = Plate(holder, 0)
        glow:SetVertexColor(Bar.GLOW[1], Bar.GLOW[2], Bar.GLOW[3], Bar.Strength(band))
        dress.halo[band] = glow
    end
    -- The outline over the glow: the rank's line behind the border.
    local edges = CreateFrame("Frame", nil, dress)
    edges:SetAllPoints(dress)
    edges:SetFrameLevel(level + 2)
    dress.rankLine = Plate(edges, -4)
    dress.rankLine:Hide()
    dress.border = Plate(edges, -3)
    local health = CreateFrame("StatusBar", nil, dress)
    health:SetFrameLevel(level + 3)
    health:SetStatusBarTexture(Bar.FILL)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    local background = health:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(Bar.WHITE)
    background:SetVertexColor(unpack(Bar.BACKGROUND))
    background:SetAllPoints(health)
    dress.health, dress.background = health, background
    dress.caps = Caps(health, health, health:GetStatusBarTexture(), background)
    -- The unit's power: a line along the bar's bottom, inside it, its corners the bar's own.
    local power = CreateFrame("StatusBar", nil, health)
    power:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
    power:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
    power:SetStatusBarTexture(Bar.FILL)
    power:SetMinMaxValues(0, 1)
    power:SetValue(0)
    -- No background: where the unit's power is spent, the bar is seen through the line.
    for _, mask in ipairs(dress.caps) do power:GetStatusBarTexture():AddMaskTexture(mask) end
    power:Hide()
    dress.power = power
    dress.rank = Bar.PLAIN
    Bar.Border(dress, nil)
end

-- Laid out for the dress's size and the unit's rank: the bar a pixel inside its border, the rank's line reaching
-- out from the same edge, the glow beyond it, the power line a third of the bar's height, every cap a quarter of what
-- it rounds.
function Bar.Fit(dress)
    local height = Plain(dress:GetHeight()) or 0
    local pixel = Core.Pixels(dress, 1)
    local edge = pixel
    dress.edge = edge
    Bar.Outline(dress)
    local inner = height - 2 * edge
    dress.line = math.max(inner * Bar.LINE, pixel * 2)
    dress.power:SetHeight(dress.line)
end

-- The outline (the border, the rank's line, the glow) around the bar, and around its cast bar too while a cast
-- shows (Cast.lua calls it as one shows or goes): one frame for both, nothing of it between them. Every round fits
-- the outline's (Bar.Radius): the outline's corners a quarter of the bar's height, the plates beyond them that much
-- rounder by their reach, the bar inside a pixel less; the bar round at its bottom only while nothing is under it.
function Bar.Radius(dress)
    return (Plain(dress:GetHeight()) or 0) * Bar.CAP
end

function Bar.Outline(dress)
    local height = Plain(dress:GetHeight()) or 0
    local pixel = Core.Pixels(dress, 1)
    local below = dress.cast and dress.cast:IsShown() and dress.cast or dress
    local tall = height + (below ~= dress and (Plain(below:GetHeight()) or 0) or 0)
    local radius = Bar.Radius(dress)
    Around(dress.border, dress, 0, tall, below, radius)
    local reach = dress.rank.width - 1 -- the rank's line beyond the dress (the border is its first pixel)
    Around(dress.rankLine, dress, pixel * reach, tall, below, radius)
    for band, glow in ipairs(dress.halo) do Around(glow, dress, pixel * (reach + band), tall, below, radius) end
    -- The bar a pixel inside the outline; down to the cast bar while one shows, square there, so nothing of the
    -- outline shows between them.
    local casting = below ~= dress
    local health = dress.health
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", dress, "TOPLEFT", pixel, -pixel)
    health:SetPoint("BOTTOMRIGHT", dress, "BOTTOMRIGHT", -pixel, casting and 0 or pixel)
    local mode = casting and "top" or "both"
    Bar.Ends(dress.caps, health, mode, mode, math.max(radius - pixel, 0.01), height - (casting and 1 or 2) * pixel)
    dress.outlined = below
end

-- A unit's rank as its border shows it ("boss", "elite", "rare"), or nil.
function Bar.Rank(unit)
    if Core.Ask(rawget(_G, "UnitIsBossMob"), unit) then return "boss" end
    local classification = Plain(UnitClassification(unit))
    return type(classification) == "string" and RANK_OF[classification] or nil
end

-- The bar's colour for a unit: r, g, b.
function Bar.Colour(unit)
    if Plain(UnitIsPlayer(unit)) then
        local _, class = UnitClass(unit)
        class = Plain(class)
        local colours = rawget(_G, "RAID_CLASS_COLORS")
        local colour = type(class) == "string" and colours and colours[class]
        if colour then return colour.r, colour.g, colour.b end
    elseif Plain(UnitIsTapDenied(unit)) then
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

-- A player who may attack you: the glow, as when you have aggro.
function Bar.Danger(unit)
    return Plain(UnitIsPlayer(unit)) == true and Core.Ask(UnitCanAttack, unit, "player") == true
end

-- The bar's colour, the border's rank and the glow of a player who may attack you, as the unit is now.
function Bar.Paint(dress, unit)
    dress.health:SetStatusBarColor(Bar.Colour(unit))
    local rank = Bar.RANKS[Bar.Rank(unit)] or Bar.PLAIN
    if rank ~= dress.rank then
        dress.rank = rank
        Bar.Fit(dress)
    end
    local colour = rank.colour
    if colour then dress.rankLine:SetVertexColor(colour[1], colour[2], colour[3], colour[4]) end
    dress.rankLine:SetShown(colour ~= nil)
    dress.danger = Bar.Danger(unit)
    Bar.Glow(dress, dress.aggro)
end

-- The glow on while you have the unit's aggro (true, false, or the game's answer hidden: the textures take it as it
-- is, never compared: a hidden boolean in a comparison is an error) or while the unit is a player who may attack you.
function Bar.Glow(dress, aggro)
    dress.aggro = aggro
    local glow = dress.glow
    if dress.danger then
        glow:SetAlpha(1)
    elseif Core.Secret(aggro) then
        -- The game's own alphas for true and false (full, none).
        if not pcall(glow.SetAlphaFromBoolean, glow, aggro) then glow:SetAlpha(0) end
    else
        glow:SetAlpha(aggro and 1 or 0)
    end
end

-- A game function's first answer as it is, hidden (a secret value) or not; nil where it failed (a unit
-- the game keeps from addons in some places). Tested with type() only: a secret is never compared.
local function Raw(fn, ...)
    local ok, value = pcall(fn, ...)
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

-- The game's colour for a power, by its token ("MANA", "RAGE", "ENERGY"); ours where it has none.
local function PowerColour(token)
    local colours = rawget(_G, "PowerBarColor")
    local colour = type(colours) == "table" and type(token) == "string" and colours[token]
    if type(colour) == "table" and type(colour.r) == "number" then return colour.r, colour.g, colour.b end
    return 0, 0.55, 1
end

-- The unit's power along the bar's bottom, as the game gives it; none where the unit has none (a most of 0, as
-- far as can be told: a hidden most shows the line) or the setting is off. Tells the combo points when the line
-- came or went: they stand on it.
function Bar.Power(dress, unit)
    local power = dress.power
    local most = nil
    if unit and (ns.options or {}).power ~= false then most = Raw(UnitPowerMax, unit) end
    local on = type(most) ~= "nil" and Plain(most) ~= 0
    if on then
        local _, token = Core.Ask(UnitPowerType, unit)
        power:SetStatusBarColor(PowerColour(token))
        power:SetMinMaxValues(0, most)
        local now = Raw(UnitPower, unit)
        if type(now) ~= "nil" then power:SetValue(now) end
    end
    if power:IsShown() ~= on then
        power:SetShown(on)
        ns.Resource.Again()
    end
end

-- The bar as made, full, without power, glow or rank: a plate the game hands out again never shows the last
-- unit's, even where the next unit's cannot be read.
function Bar.Clear(dress)
    dress.health:SetMinMaxValues(0, 1)
    dress.health:SetValue(1)
    dress.power:Hide()
    dress.danger = false
    Bar.Glow(dress, false)
end

-- The border: white on your target, orange on your focus ("target", "focus"), else black (nil); red on any of them
-- while the unit is out of your reach (out).
Bar.FAR = { 1, 0.12, 0.08, 1 }
function Bar.Border(dress, lit, out)
    local colour = out and Bar.FAR or lit == "target" and Bar.TARGET or lit == "focus" and Bar.FOCUS or Bar.BORDER
    dress.border:SetVertexColor(colour[1], colour[2], colour[3], colour[4])
end
