local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Bar
--  A unit frame's bar, in the look of a nameplate's (the module Nameplates):
--  a rectangle round at its corners, framed by one thin border, the unit's
--  power a thin line along its bottom, inside it; and under it, while it
--  shows, a row of its own (your target's target, your focus's target, your
--  pet), as a cast bar hangs under a nameplate's bar: inside the same outline,
--  the bar square at its bottom then, the row round at its own. The frame is
--  always as wide as it is: nothing it shows changes its size, and its border
--  and rank's line lie inside it (a nameplate's rank line reaches outwards), so
--  an elite's or a boss's frame is no wider than another's; every piece is laid
--  out for its size, its rank and the row alone (Bar.Fit, again when one
--  changes). Only the glow reaches beyond it.
--
--  How it is round: the bar's fill and background are masked at both ends,
--  by Core's caps (Shape.CAP_LEFT, CAP_RIGHT, a quarter of the bar's height
--  wide) or, while the row is under it, by Core's corner masks at its top
--  alone (Shape.CORNER); the row's at its bottom corners. Every plate around
--  them (the border, the rank's line, the glow's bands) is two halves, each
--  round at its own two corners by corner masks (a texture takes few masks),
--  its round fitting the bar's.
--
--  From the inside out:
--    the bar      health as the game gives it (a hidden value in a fight: the
--                 bar takes it as it is), green: the game's colour for health
--    the row      the same, its own unit's, a screen pixel under the bar (the
--                 border's dark between them)
--    the power    the unit's mana, rage or energy, in the game's colour for it
--    the rank     inside the border, between it and the bars: gold and thick
--                 on a boss, gold on an elite, silver on a rare
--    the border   one screen pixel, black, the frame's edge
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
Bar.GLOW = { 1, 0.08, 0.05 }
Bar.HALO = 6 -- the glow's bands, a screen pixel each, solid inside and fading out
-- Every bar's health in the game's green for it (its compact frames' health, set by the client); plain green where
-- it has none.
Bar.GREEN = { 0, 1, 0 }
local green = rawget(_G, "COMPACT_UNIT_FRAME_FRIENDLY_HEALTH_COLOR")
if type(green) == "table" and type(green.r) == "number" then Bar.GREEN = { green.r, green.g, green.b } end
local GOLD = { 1, 0.82, 0, 1 }
local gold = rawget(_G, "NORMAL_FONT_COLOR")
if type(gold) == "table" and type(gold.r) == "number" then GOLD = { gold.r, gold.g, gold.b, 1 } end
-- A unit's rank: its line's colour, and how many screen pixels the border and the line take inside the frame's edge.
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

-- A plate reaching that far beyond the frame on every side (inside it where reach is less than 0), down to below under
-- its bottom (the row, while it shows), its corners round by radius and that reach.
local function Around(plate, frame, reach, height, below, radius)
    local half = (height + below + 2 * reach) / 2
    local upper, lower = plate[1], plate[2]
    upper:ClearAllPoints()
    upper:SetPoint("TOPLEFT", frame, "TOPLEFT", -reach, reach)
    upper:SetPoint("TOPRIGHT", frame, "TOPRIGHT", reach, reach)
    upper:SetHeight(half)
    lower:ClearAllPoints()
    lower:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -reach, -reach - below)
    lower:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", reach, -reach - below)
    lower:SetHeight(half)
    local round = math.max(math.min(radius + reach, half), 0.01)
    for _, piece in ipairs(plate) do
        for _, mask in ipairs(piece.corners) do mask:SetSize(round, round) end
    end
end

-- A status bar of health on host, its background behind it, and a mask at each end over both (sized by End).
local function Health(host, level)
    local health = CreateFrame("StatusBar", nil, host)
    health:SetFrameLevel(level)
    health:SetStatusBarTexture(Bar.FILL)
    health:SetStatusBarColor(Bar.GREEN[1], Bar.GREEN[2], Bar.GREEN[3])
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    local background = health:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(Bar.WHITE)
    background:SetVertexColor(unpack(Bar.BACKGROUND))
    background:SetAllPoints(health)
    health.ends = {}
    for index = 1, 2 do
        local mask = health:CreateMaskTexture()
        health:GetStatusBarTexture():AddMaskTexture(mask)
        background:AddMaskTexture(mask)
        health.ends[index] = mask
    end
    return health
end

-- One end's mask over a bar for what that end should be: "both" round at its top and bottom (a cap a quarter of the
-- height wide), "top" or "bottom" round at that corner alone (a corner mask of that radius).
local function End(mask, bar, side, mode, radius, height)
    local shape = Core.Shape
    mask:ClearAllPoints()
    if mode == "both" then
        mask:SetTexture(side == "LEFT" and shape.CAP_LEFT or shape.CAP_RIGHT, "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint("TOP" .. side, bar, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, bar, "BOTTOM" .. side)
        mask:SetWidth(math.max(height * Bar.CAP, 0.01))
    else
        local corner = (mode == "top" and "TOP" or "BOTTOM") .. side
        mask:SetTexture(shape.CORNER[corner], "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint(corner, bar, corner)
        mask:SetSize(math.max(radius, 0.01), math.max(radius, 0.01))
    end
end
local function Ends(bar, mode, radius, height)
    End(bar.ends[1], bar, "LEFT", mode, radius, height)
    End(bar.ends[2], bar, "RIGHT", mode, radius, height)
end

-- The bar's pieces on the frame, each layer on a frame of its own one level above the last: the glow, then the
-- rank's line and the border, then the health with its power line and the row (the texts above it all). How high
-- the row is: row (in the frame's units); the frame says while it shows (face.rowShown).
function Bar.Make(frame, row)
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
    frame.border = Plate(edges, -4)
    frame.rankLine = Plate(edges, -3) -- over the border, a pixel inside it
    frame.rankLine:SetShown(false)
    frame.border:SetVertexColor(Bar.BORDER[1], Bar.BORDER[2], Bar.BORDER[3], Bar.BORDER[4])
    frame.health = Health(frame, level + 3)
    -- No background: where the unit's power is spent, the bar is seen through the line.
    local power = CreateFrame("StatusBar", nil, frame.health)
    power:SetPoint("BOTTOMLEFT", frame.health, "BOTTOMLEFT")
    power:SetPoint("BOTTOMRIGHT", frame.health, "BOTTOMRIGHT")
    power:SetStatusBarTexture(Bar.FILL)
    power:SetMinMaxValues(0, 1)
    power:SetValue(0)
    for _, mask in ipairs(frame.health.ends) do power:GetStatusBarTexture():AddMaskTexture(mask) end
    power:Hide()
    frame.power = power
    if row then
        frame.rowHeight = row
        frame.row = Health(frame, level + 3)
        frame.row:Hide()
    end
    frame.rank = Bar.PLAIN
end

-- Laid out for the frame's size, the unit's rank and the row, all inside the frame's edge: the border on it, the
-- rank's line a pixel inside it, the bar inside both (down to the row, square there, while it shows), the row a pixel
-- under the bar; the glow beyond the edge; every round a quarter of the bar's height.
function Bar.Fit(frame)
    local height = Plain(frame:GetHeight()) or 0
    local pixel = Core.Pixels(frame, 1)
    local radius = height * Bar.CAP
    local row = frame.row and frame.rowShown and frame.rowHeight or 0
    local inset = pixel * frame.rank.width -- the border and the rank's line
    Around(frame.border, frame, 0, height, row, radius)
    Around(frame.rankLine, frame, -pixel, height, row, radius)
    for band, plate in ipairs(frame.halo) do Around(plate, frame, pixel * band, height, row, radius) end
    local health, inner = frame.health, math.max(radius - inset, 0.01)
    health:ClearAllPoints()
    health:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
    health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, row > 0 and 0 or inset)
    Ends(health, row > 0 and "top" or "both", inner, height - 2 * inset)
    frame.power:SetHeight(math.max((height - 2 * inset) * Bar.LINE, pixel * 2))
    if frame.row then
        frame.row:ClearAllPoints()
        frame.row:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", inset, -pixel)
        frame.row:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset - frame.rowHeight)
        Ends(frame.row, "bottom", math.max(math.min(inner, frame.rowHeight - pixel - inset), 0.01), frame.rowHeight)
        frame.row:SetShown(row > 0)
    end
end

-- A unit's rank by the line behind the border ("boss", "elite", "rare"), or nil.
function Bar.Rank(unit)
    if Core.Ask(rawget(_G, "UnitIsBossMob"), unit) then return "boss" end
    local classification = Core.Ask(UnitClassification, unit)
    return type(classification) == "string" and RANK_OF[classification] or nil
end

-- The rank's line and the glow of a player who may attack you, as the unit is now.
function Bar.Paint(frame, unit)
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

-- Health as the game gives it, hidden or not, on a bar (the frame's own, or its row's).
function Bar.Health(bar, unit)
    local most, now = Raw(UnitHealthMax, unit), Raw(UnitHealth, unit)
    if type(most) == "nil" or type(now) == "nil" then return end
    bar:SetMinMaxValues(0, most)
    bar:SetValue(now)
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
