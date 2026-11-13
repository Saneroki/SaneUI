local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Bar
--  A unit frame's bars, in the look of a nameplate's (the module Nameplates):
--  one rectangle round at its corners, framed by one thin border, holding a
--  stack of bars a screen pixel apart (the border's dark between them): the
--  unit's health, under it its power at half that height (your own druid's
--  mana always, Saneroki, 2026-11-13: in a form whose power is not mana your
--  mana first and the form's rage or energy under it, Core.FormPower; so your
--  own frame where you have mana beside another power), and, while it shows, a row
--  of its own (your target's target, your focus's target, your pet with its
--  resource under it: frame.rowPower), as a cast bar hangs under a nameplate's
--  bar. What runs only for a while stands above the health bar (frame.above:
--  the unit's cast right on it, the game's timers on you over that: Cast.lua,
--  Timers.lua; never a button of the game's, so it comes and goes in a fight
--  too), with the auras over all that
--  (frame.roof: they stand on it, Auras.lua); what runs over the health bar
--  lies on it, the same size (frame.over: your breath, Timers.lua). The
--  stack's first bar is round at its top, its last at its bottom. The health
--  bar is the anchor: whatever comes or goes around it, it stays exactly where
--  it is; only the outline reaches further up or down. The frame's
--  face is as high as the health bar; the rest hangs under it and stands on
--  it, inside the same outline; its button is as high as the health and the
--  power slots it keeps (frame.slots, Units.lua), and the row's button under
--  that. The frame is
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
--                 bar takes it as it is), green: the game's colour for health;
--                 on your target's and your focus's frames red while you
--                 can attack the unit (Bar.HOSTILE)
--    the powers   the unit's mana, rage or energy, in the game's colour for each;
--                 a druid's mana first, its form's under it
--    the row      health again, its own unit's: a target's target in the light
--                 yellow of a nameplate's neutral creature (Bar.CALM), your
--                 pet green, with its power under it in the game's colour
--    the rank     inside the border, between it and the bars: gold and thick
--                 on a boss, gold on an elite, silver on a rare
--    the border   one screen pixel, black, the frame's edge
--    the glow     red, solid at the edge and fading outwards: you have the
--                 unit's aggro (your own frame: anything's), or it is a player
--                 who may attack you
--  and on the health bar what Core's health marks show (frame.marks, Core's
--  HealthMarks.lua): the barrier and the lost maximum health (the health bar
--  ends earlier, Bar.Fit); the dispel type's icon floats big over its left end.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Bar = {}
ns.UnitBar = Bar

Bar.FILL = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" -- the game's raid frames' health fill
Bar.WHITE = "Interface\\Buttons\\WHITE8X8"
Bar.CAP = 1 / 4  -- a cap's width and every corner's round, a share of the health bar's height
Bar.MANA = rawget(_G, "Enum") and Enum.PowerType and Enum.PowerType.Mana or 0 -- the game's number for mana
Bar.BACKGROUND = { 0.07, 0.07, 0.09, 1 } -- where health is missing: solid, so nothing behind shows through
Bar.BORDER = { 0, 0, 0, 0.9 }
Bar.GLOW = { 1, 0.08, 0.05 }
Bar.HALO = 6 -- the glow's bands, a screen pixel each, solid inside and fading out
Bar.DISPEL = 22 -- the dispel type's icon on a frame, square
-- Every bar's health in the game's green for it (its compact frames' health, set by the client); plain green where
-- it has none.
Bar.GREEN = { 0, 1, 0 }
local green = rawget(_G, "COMPACT_UNIT_FRAME_FRIENDLY_HEALTH_COLOR")
if type(green) == "table" and type(green.r) == "number" then Bar.GREEN = { green.r, green.g, green.b } end
Bar.CALM = { 1, 0.93, 0.55 } -- a target's target: the light yellow of a nameplate's creature that does not attack on sight
Bar.HOSTILE = { 1, 0, 0 } -- a foe's health where the frame tells foes (frame.foes: target, focus), a nameplate's red
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
Bar.Plate = Plate -- for what is made of the same pieces (the group's frames)

-- A plate reaching that far beyond the frame on every side (inside it where reach is less than 0), up to above over
-- its top and down to below under its bottom (what stands on it and hangs under it now), its corners round by radius
-- and that reach.
local function Around(plate, frame, reach, height, above, below, radius)
    local half = (height + above + below + 2 * reach) / 2
    local upper, lower = plate[1], plate[2]
    upper:ClearAllPoints()
    upper:SetPoint("TOPLEFT", frame, "TOPLEFT", -reach, reach + above)
    upper:SetPoint("TOPRIGHT", frame, "TOPRIGHT", reach, reach + above)
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
Bar.Around = Around

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
    health.background = background
    health.ends = {}
    for index = 1, 2 do
        local mask = health:CreateMaskTexture()
        health:GetStatusBarTexture():AddMaskTexture(mask)
        background:AddMaskTexture(mask)
        health.ends[index] = mask
    end
    return health
end
Bar.Strip = Health -- a bar of the stack, for what hangs in it (frame.under)

-- One end's mask over a bar for what that end should be: "both" round at its top and bottom (a cap a quarter of the
-- height wide), "top" or "bottom" round at that corner alone (a corner mask of that radius), "none" square.
local function End(mask, bar, side, mode, radius, height)
    local shape = Core.Shape
    mask:ClearAllPoints()
    if mode == "both" then
        mask:SetTexture(side == "LEFT" and shape.CAP_LEFT or shape.CAP_RIGHT, "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint("TOP" .. side, bar, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, bar, "BOTTOM" .. side)
        mask:SetWidth(math.max(height * Bar.CAP, 0.01))
    elseif mode == "none" then
        mask:SetTexture(Bar.WHITE, "CLAMPTOWHITE", "CLAMPTOWHITE")
        mask:SetPoint("TOP" .. side, bar, "TOP" .. side)
        mask:SetPoint("BOTTOM" .. side, bar, "BOTTOM" .. side)
        mask:SetWidth(1)
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
Bar.End, Bar.Ends = End, Ends

-- The bar's pieces on the frame, each layer on a frame of its own one level above the last: the glow, then the
-- rank's line and the border, then the bars (the texts above it all). sizes: how high the health bar, a power bar and
-- the row and its power (rowPower, where its unit has one) are; the frame says how many power slots it keeps
-- (frame.slots: its button's), how many powers show (frame.powersShown) and whether the row does (frame.rowShown).
function Bar.Make(frame, sizes)
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
    frame.healthHeight, frame.powerHeight, frame.rowHeight = sizes.health, sizes.power, sizes.row
    frame.slots, frame.powersShown, frame.powers = 1, 1, {}
    for index = 1, 2 do
        local power = Health(frame, level + 3)
        power:SetValue(0)
        power:Hide()
        frame.powers[index] = power
    end
    frame.row = Health(frame, level + 3)
    frame.row:Hide()
    if sizes.rowPower then
        frame.rowPower, frame.rowPowerHeight = Health(frame, level + 3), sizes.rowPower
        frame.rowPower:SetValue(0)
        frame.rowPower:Hide()
    end
    frame.above = {} -- bars of the stack above the health bar, nearest first, each with its height (tall) and whether it shows now (on)
    frame.over = {}  -- bars over the health bar, each anchored to it, with whether it shows now (on)
    frame.roof = CreateFrame("Frame", nil, frame) -- the stack's top: moved in a fight too, so what stands on it is not
    frame.roof:SetHeight(1)
    frame.rank = Bar.PLAIN
    frame.marks = Core.HealthMarks.New(frame, frame.health, {
        masks = frame.health.ends, size = Bar.DISPEL, fit = function() Bar.Fit(frame) end })
end

-- Laid out for the frame's sizes, the unit's rank, its powers and the row, all inside the frame's edge: the border on
-- it, the rank's line a pixel inside it, the bars inside both, one under the other a pixel apart: what stands above
-- the health bar while it shows, the health, each power shown, the row while it shows and its power; what lies over
-- the health bar round as it is; the glow beyond the edge; every round a quarter of the health bar's height. The row
-- stands under the power slots the frame keeps, where its button is, or under the powers shown where there are more
-- (a druid as your target in a fight: the slots grow once it is over, Units.lua).
function Bar.Fit(frame)
    local height, powerHeight, rowHeight = frame.healthHeight, frame.powerHeight, frame.rowHeight
    local pixel = Core.Pixels(frame, 1)
    local radius = height * Bar.CAP
    local inset = pixel * frame.rank.width -- the border and the rank's line
    local shown = math.min(frame.powersShown or 0, #frame.powers)
    local rowTop = height + math.max(frame.slots or 1, shown) * powerHeight
    -- The stack, top to bottom: { bar, its top and its height below the frame's top }. What stands above the health bar
    -- rests on it, a pixel over it, wherever the rank's line has put its top.
    local stack, rest = {}, inset - pixel
    for _, bar in ipairs(frame.above) do
        if bar.on then
            rest = rest - bar.tall
            table.insert(stack, 1, { bar, rest, bar.tall })
        else
            bar:Hide()
        end
    end
    local above = math.max(-rest, 0)
    stack[#stack + 1] = { frame.health, 0, height }
    for index = 1, shown do stack[#stack + 1] = { frame.powers[index], height + (index - 1) * powerHeight, powerHeight } end
    if frame.rowShown then stack[#stack + 1] = { frame.row, rowTop, rowHeight } end
    local bottom = frame.rowShown and (rowTop + rowHeight) or (height + shown * powerHeight)
    local rowPower = frame.rowPower
    if rowPower and frame.rowShown and rowPower.on then
        stack[#stack + 1] = { rowPower, bottom, frame.rowPowerHeight }
        bottom = bottom + frame.rowPowerHeight
    elseif rowPower then
        rowPower:Hide()
    end
    local below = bottom - height
    Around(frame.border, frame, 0, height, above, below, radius)
    Around(frame.rankLine, frame, -pixel, height, above, below, radius)
    for band, plate in ipairs(frame.halo) do Around(plate, frame, pixel * band, height, above, below, radius) end
    local marks = frame.marks
    local inner = (Plain(frame:GetWidth()) or 0) - 2 * inset
    local reach = marks:Reach(inner)
    frame.roof:ClearAllPoints()
    frame.roof:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, above)
    frame.roof:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, above)
    for index, piece in ipairs(stack) do
        local bar, top, tall = piece[1], piece[2], piece[3]
        local first, last, anchor = index == 1, index == #stack, bar == frame.health
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -top - ((first or anchor) and inset or pixel))
        bar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -inset - (anchor and reach or 0), -top - tall + (last and inset or 0))
        local mode = first and last and "both" or first and "top" or last and "bottom" or "none"
        local round = math.max(math.min(radius - inset, tall - pixel - inset), 0.01)
        Ends(bar, mode, round, tall - pixel - inset)
        if anchor then
            End(marks.lostEnd, marks.lost, "RIGHT", mode, round, tall - pixel - inset)
            for _, over in ipairs(frame.over) do
                Ends(over, mode, round, tall - pixel - inset)
                over:SetShown(over.on == true)
            end
        end
        bar:Show()
    end
    for index = shown + 1, #frame.powers do frame.powers[index]:Hide() end
    if not frame.rowShown then frame.row:Hide() end
    marks:Fit(inner)
    if frame.rest then frame.rest:Look() end -- what stands on it changed: at rest it may have to show (Units.lua)
end

-- A unit's rank by the line behind the border ("boss", "elite", "rare"), or nil.
function Bar.Rank(unit)
    if Core.Ask(rawget(_G, "UnitIsBossMob"), unit) then return "boss" end
    local classification = Core.Ask(UnitClassification, unit)
    return type(classification) == "string" and RANK_OF[classification] or nil
end

-- The health's colour, the rank's line and the glow of a player who may attack you, as the unit is now. On a frame
-- that tells foes (frame.foes) the health is red while you can attack the unit, else green (its answer hidden: green).
function Bar.Paint(frame, unit)
    local foe = frame.foes and Core.Ask(UnitCanAttack, "player", unit) == true
    local health = foe and Bar.HOSTILE or Bar.GREEN
    frame.health:SetStatusBarColor(health[1], health[2], health[3])
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
Bar.PowerColour = PowerColour -- a power's colour by its token, as the game has it

-- A power of the unit, now and most, as the game gives them (hidden or not; tested with type() only). kind: { type,
-- token }.
function Bar.Read(unit, kind)
    if kind.type == nil then return nil, nil end
    if kind.type == Bar.MANA then return Core.Mana(unit) end
    return Raw(UnitPower, unit, kind.type), Raw(UnitPowerMax, unit, kind.type)
end

-- One power on its bar, as the game gives it (hidden or not), in the game's colour; an empty bar where the unit has
-- none (a most of 0, as far as can be told). kind: { type = the game's number, token = its name }. Whether it has one.
local function Power(bar, unit, kind)
    local now, most = Bar.Read(unit, kind)
    if type(most) ~= "nil" and Plain(most) ~= 0 then
        bar:SetStatusBarColor(PowerColour(kind.token))
        bar:SetMinMaxValues(0, most)
        if type(now) ~= "nil" then bar:SetValue(now) end
        return true
    end
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    return false
end

Bar.Power = Power

-- The powers a frame shows: the unit's own; you as a druid in a form whose power is not mana (Core.FormPower), and on a
-- frame that tells it (frame.alternate: your mana beside another power), mana first and the unit's own under it. Each
-- { type = the game's number, token = its name }; a unit without a power has an empty slot. Kept on the frame
-- (frame.kinds), made anew only when the unit's power changed: asked at every beat of a power.
function Bar.Kinds(frame, unit)
    local kind, token = Core.Ask(UnitPowerType, unit)
    local top = Core.FormPower(unit)
    if not top and frame.alternate == true and type(kind) == "number" and kind ~= Bar.MANA then top = kind end
    local kinds = frame.kinds
    if kinds and frame.kindsType == kind and frame.kindsToken == token and frame.kindsTop == top then return kinds end
    if top then
        kinds = { { type = Bar.MANA, token = "MANA" }, { type = kind, token = token } }
    else
        kinds = { { type = kind, token = token } }
    end
    frame.kinds, frame.kindsType, frame.kindsToken, frame.kindsTop = kinds, kind, token, top
    return kinds
end

-- The unit's powers in their bars. Laid out anew when their number changed.
function Bar.Powers(frame, unit)
    local kinds = Bar.Kinds(frame, unit)
    for index, kind in ipairs(kinds) do Power(frame.powers[index], unit, kind) end
    if #kinds ~= frame.powersShown then
        frame.powersShown = #kinds
        Bar.Fit(frame)
    end
    return kinds
end

-- The row's unit's power under it (your pet's), shown while it has one; the kind, for its words. nil on a row without.
function Bar.RowPower(frame, unit)
    local bar = frame.rowPower
    if not bar then return nil end
    local kind = {}
    kind.type, kind.token = Core.Ask(UnitPowerType, unit)
    local on = Power(bar, unit, kind)
    if on ~= bar.on then
        bar.on = on
        Bar.Fit(frame)
    end
    return kind
end
