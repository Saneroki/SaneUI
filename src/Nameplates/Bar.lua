local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Bar
--  The health bar of our dress on a plate: a rectangle round at its corners,
--  as large as the game's own health bar under it (the game's nameplate size
--  and style), framed by one thin border, with the unit's power as a thin
--  line along its bottom, inside it.
--
--  How it is round: the bar's fill, its background and the lines inside it
--  are masked at both ends by Core's caps (Shape.CAP_LEFT, CAP_RIGHT), a
--  quarter of the bar's height wide, wrapped with white beyond them, so the
--  fill keeps its round left corners however short it is and meets the right
--  ones when full. Every plate around it (the border, the rank's line, the
--  glow) is cut by caps of its own size.
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
--    the border   one pixel: black; white on your target (red while it is
--                 out of reach of all your attacks: Range.lua), orange on
--                 your focus (the game's colours for them)
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
Bar.LINE = 1 / 5 -- the power line's height (and the combo points'), a share of the bar's
Bar.BACKGROUND = { 0.07, 0.07, 0.09, 0.85 } -- where health is missing
Bar.BORDER = { 0, 0, 0, 0.9 }
Bar.TAPPED = { 0.5, 0.5, 0.5 }      -- tapped by others
Bar.CALM = { 1, 0.93, 0.55 }        -- a creature that does not attack on sight (neutral to you)
Bar.HOSTILE = { 1, 0, 0 }           -- one that does
Bar.GLOW = { 1, 0.08, 0.05 }
-- The glow: a red edge around the bar, solid where it meets the border and fading to nothing outwards. Drawn as
-- Bar.HALO round plates a screen pixel apart, each reaching a pixel farther; Bar.Fade says how solid the glow is in
-- each pixel's band (1 the innermost, falling off softly), and each plate is as strong as that band needs over the
-- plates beyond it. The plates' strengths are their vertex colours' alpha, which a texture's own alpha would
-- replace: so they stand on a frame of their own (dress.glow), and only that frame's alpha switches the glow.
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

-- A plate of one colour on the dress, behind the bar, cut round by caps of its own.
local function Plate(host, sublevel)
    local texture = host:CreateTexture(nil, "BACKGROUND", nil, sublevel)
    texture:SetTexture(Bar.WHITE)
    texture.caps = Caps(host, texture, texture)
    return texture
end

-- A plate reaching that far beyond the dress on every side, its caps sized for it.
local function Around(texture, dress, reach, height)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", dress, "TOPLEFT", -reach, reach)
    texture:SetPoint("BOTTOMRIGHT", dress, "BOTTOMRIGHT", reach, -reach)
    Bar.SizeCaps(texture.caps, height + 2 * reach)
end

-- The bar's pieces on the dress: the glow, the rank's line and the border behind, the status bar inside them with
-- its background, fill and power line.
function Bar.Make(dress)
    -- The glow's frame, a level under the dress's: behind the border and the bar.
    local holder = CreateFrame("Frame", nil, dress)
    holder:SetAllPoints(dress)
    holder:SetFrameLevel(math.max((Plain(dress:GetFrameLevel()) or 1) - 1, 0))
    holder:SetAlpha(0)
    dress.glow, dress.halo = holder, {}
    for band = 1, Bar.HALO do
        local glow = Plate(holder, 0)
        glow:SetVertexColor(Bar.GLOW[1], Bar.GLOW[2], Bar.GLOW[3], Bar.Strength(band))
        dress.halo[band] = glow
    end
    dress.rankLine = Plate(dress, -4)
    dress.rankLine:Hide()
    dress.border = Plate(dress, -3)
    local health = CreateFrame("StatusBar", nil, dress)
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
-- out from the same edge, the glow beyond it, the power line a fifth of the bar's height, every cap a quarter of what
-- it rounds.
function Bar.Fit(dress)
    local height = Plain(dress:GetHeight()) or 0
    local pixel = Core.Pixels(dress, 1)
    local edge = pixel
    dress.edge = edge
    local health = dress.health
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", dress, "TOPLEFT", edge, -edge)
    health:SetPoint("BOTTOMRIGHT", dress, "BOTTOMRIGHT", -edge, edge)
    Around(dress.border, dress, 0, height)
    local reach = dress.rank.width - 1 -- the rank's line beyond the dress (the border is its first pixel)
    Around(dress.rankLine, dress, pixel * reach, height)
    for band, glow in ipairs(dress.halo) do Around(glow, dress, pixel * (reach + band), height) end
    local inner = height - 2 * edge
    Bar.SizeCaps(dress.caps, inner)
    dress.line = math.max(inner * Bar.LINE, pixel * 2)
    dress.power:SetHeight(dress.line)
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

-- The border: white on your target, red on your target out of your reach, orange on your focus ("target", "far",
-- "focus"), else black (nil).
Bar.FAR = { 1, 0.12, 0.08, 1 }
function Bar.Border(dress, lit)
    local colour = lit == "target" and Bar.TARGET or lit == "far" and Bar.FAR or lit == "focus" and Bar.FOCUS
        or Bar.BORDER
    dress.border:SetVertexColor(colour[1], colour[2], colour[3], colour[4])
end
