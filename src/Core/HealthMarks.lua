local Core = SaneUI.Core

-------------------------------------------------------------------------------
--  Sane UI - Core - HealthMarks
--  What every health bar of ours shows of a unit besides its health, the same
--  on all of them (Combat's unit and group frames, Nameplates' plates):
--
--    the barrier    what absorbs damage on the unit, as long as it is, in the
--                   game's own shield art: right after the health while it
--                   fits into what is missing, pushed back against the bar's
--                   right end, over the health, once it does not
--    the lost part  maximum health taken away for a while: the health bar ends
--                   that much earlier (Marks:Reach, the owner's Fit), and the
--                   rest of its length shows the game's hatching for it
--    dispellable    what you or your group can take off the unit (on a foe, a
--                   buff that can be taken from it): a coloured ring around the
--                   whole frame in the colour of its kind, and the aura's icon
--
--  Barrier: in a fight the game hides health and absorbs from addons, so
--  nothing here is ever computed. A calculator of the game's says how much of
--  the barrier fits (clamped to the missing health), all of it, and whether it
--  was cut (UnitGetDetailedHealPrediction): the first goes on a status bar that
--  starts at the end of the health's fill, as long as a whole bar and with the
--  same most; the second on one that fills backwards from the bar's right end,
--  seen only while the barrier was cut (SetAlphaFromBoolean). So it is always
--  as long as it should be, wherever it stands.
--
--  Dispellable: one aura container of the game's (CustomAuraContainerTemplate)
--  filled by the game, in a fight too. Its one icon carries the ring as its
--  dispel type textures, which the game colours and shows itself. The icon's
--  frame stands under the outline, so the ring lies behind the black border and
--  is seen beyond it, even around a green bar and a poison's green; the picture
--  stands in a frame of its own above the bars. Frames that stand edge to edge
--  (options.inside) have the ring in that frame too, along the bar's own edge,
--  as a neighbour would cover it outside. No mouse on any of it: the unit's
--  button under it keeps clicks and @mouseover.
--
--      local marks = Core.HealthMarks.New(host, health, {
--          masks = { ... },          -- the masks that round the bar's ends
--          ring = function(parent) ... return plate end,   -- a round plate on parent, the owner's
--          fit = function() ... end, -- lay it all out: the bar (by marks:Reach), each of marks.rings, marks:Fit
--          size = 14,                -- the icon, square
--          inside = true,            -- the ring lies over the bars, not behind the outline (frames edge to edge)
--          above = level,            -- the icon's frame level, where it should stand over more than the bars
--          sample = true,            -- never for a live unit: no container
--      })
--      marks:Set(unit)               -- all of it for the unit; nil: none
--      marks:Heard(unit, event)      -- one of Marks.EVENTS, or the unit's health changed
--      marks:Switch(barrier, lost, dispel)
--      marks:Sample({ barrier = share, lost = share, dispel = "Magic" })  -- made up, without a unit
-------------------------------------------------------------------------------
local Plain = Core.Plain
local Marks = {}
Core.HealthMarks = Marks

Marks.EVENTS = { "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" }
Marks.SHIELD = "Interface\\RaidFrame\\Shield-Fill"
Marks.HATCH = "Interface\\RaidFrame\\RaidFrameMaximumHealthReductionOverlay"
Marks.GROUND = { 0.16, 0.05, 0.05 } -- under the hatching
Marks.WHITE = "Interface\\Buttons\\WHITE8X8"
Marks.MOST_LOST = 0.9   -- the share of the bar the lost part takes at most: some health always shows
Marks.SIZE = 14         -- the icon, square
Marks.CROP = { 0.08, 0.92, 0.08, 0.92 }
Marks.FRIEND = "HARMFUL|RAID_PLAYER_DISPELLABLE"
Marks.FOE = "HELPFUL|RAID_PLAYER_DISPELLABLE"
Marks.GROUP = "dispel" -- the container's one aura group
-- Each kind's colour, for a sample: the game's own for a live aura.
Marks.KINDS = {
    Magic = { 0.2, 0.6, 1 }, Curse = { 0.6, 0, 1 }, Disease = { 0.6, 0.4, 0 }, Poison = { 0, 0.6, 0 },
}
Marks.SAMPLE_ICONS = {
    Magic = "Interface\\Icons\\Spell_Holy_DispelMagic", Curse = "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
    Disease = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", Poison = "Interface\\Icons\\Spell_Nature_CorrosiveBreath",
}

local methods = {}

-- The game's calculator: one is enough, it is read right after each use. nil where this client has none.
local calculator
local function Calculator()
    if calculator == nil then
        local make = rawget(_G, "CreateUnitHealPredictionCalculator")
        local ok, made = pcall(make)
        calculator = ok and made or false
        local modes = rawget(_G, "Enum") and Enum.UnitDamageAbsorbClampMode
        if calculator and modes then
            pcall(calculator.SetDamageAbsorbClampMode, calculator, modes.MissingHealthWithoutIncomingHeals)
        end
    end
    return calculator or nil
end

local function Read(calc, unit)
    UnitGetDetailedHealPrediction(unit, nil, calc)
    local amount, clamped = calc:GetDamageAbsorbs()
    return amount, clamped, calc:GetTotalDamageAbsorbs()
end

-- A game function's first answer as it is, hidden or not; nil where it failed. Tested with type() only.
local function Raw(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
    return nil
end

-- A bar of the barrier on the health bar, rounded by its masks.
local function Strip(health, masks)
    local bar = CreateFrame("StatusBar", nil, health)
    bar:SetStatusBarTexture(Marks.SHIELD)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    for _, mask in ipairs(masks or {}) do bar:GetStatusBarTexture():AddMaskTexture(mask) end
    return bar
end

-- The lost part: a frame of its own right after the health bar, at its level, over the outline.
local function Lost(host, health, level)
    local lost = CreateFrame("Frame", nil, host)
    lost:SetFrameLevel(level)
    lost:SetPoint("TOPLEFT", health, "TOPRIGHT")
    lost:SetPoint("BOTTOMLEFT", health, "BOTTOMRIGHT")
    lost:Hide()
    local ground = lost:CreateTexture(nil, "BACKGROUND")
    ground:SetAllPoints(lost)
    ground:SetTexture(Marks.WHITE)
    ground:SetVertexColor(Marks.GROUND[1], Marks.GROUND[2], Marks.GROUND[3], 1)
    local hatch = lost:CreateTexture(nil, "ARTWORK")
    hatch:SetAllPoints(lost)
    hatch:SetTexture(Marks.HATCH, "REPEAT", "REPEAT")
    hatch:SetHorizTile(true)
    hatch:SetVertTile(true)
    local mask = lost:CreateMaskTexture() -- its right end, the owner's to round (marks.lostEnd)
    ground:AddMaskTexture(mask)
    hatch:AddMaskTexture(mask)
    return lost, mask
end

-- One icon, drawn into the frame the container makes: its picture above the bars, the ring (the owner's plate) on the
-- frame itself, under the outline; the game colours and shows both by the aura's kind.
local function Dress(marks, frame)
    local size = marks.options.size or Marks.SIZE
    frame:SetSize(size, size)
    pcall(frame.EnableMouse, frame, false)
    frame:SetFrameLevel(marks.under)
    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(frame)
    top:SetFrameLevel(marks.above)
    local edge = top:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints(top)
    edge:SetTexture(Marks.WHITE)
    local icon = top:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", top, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", top, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(unpack(Marks.CROP))
    local cooldown = CreateFrame("Cooldown", nil, top, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.5)
    frame:SetIcon(icon)
    frame:SetDurationCooldown(cooldown)
    local styles = rawget(_G, "Enum") and Enum.CustomAuraButtonDispelTypeTextureStyle
    local ring = marks.options.ring(marks.options.inside and top or frame)
    if styles then
        local style = { style = styles.PreserveAsset, showWhenHarmful = true, showWhenHelpful = true }
        pcall(frame.AddDispelTypeTexture, frame, edge, style)
        for _, half in ipairs(ring) do pcall(frame.AddDispelTypeTexture, frame, half, style) end
    end
    marks.rings[#marks.rings + 1] = ring
    if marks.ready then marks.options.fit() end -- else the owner lays it out as it is made
end

-- The container of the marks: one icon at most. nil where this client has none.
local function Container(marks)
    if Marks.missing then return nil end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, marks.host, "CustomAuraContainerTemplate")
    if not ok or not container then
        Marks.missing = true -- asked once: the next frames do without
        return nil
    end
    container:SetFlowLayoutAnchorPoint("BOTTOMRIGHT")
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if flow then container:SetFlowLayoutGrowthDirection(flow.Left, flow.Up) end
    local dressed = Core.Guard("health marks", function(frame) Dress(marks, frame) end)
    local sorts, ways = rawget(_G, "AuraContainerSortMethod"), rawget(_G, "AuraContainerSortDirection")
    container:AddAuraGroup(Marks.GROUP, Marks.FRIEND, {
        maxFrameCount = 1, initializeFrame = dressed, layout = { elementSpacing = 0 },
        sortMethod = sorts and sorts.UnitFrameDebuff or nil, sortDirection = ways and ways.Normal or nil })
    return container
end

function Marks.New(host, health, options)
    local level = Plain(health:GetFrameLevel()) or 1
    local marks = setmetatable({ host = host, health = health, options = options, width = 0, share = 0, rings = {},
                                 barrierOn = true, lostOn = true, dispelOn = true,
                                 under = (Plain(host:GetFrameLevel()) or 1) + 1, above = options.above or level + 4 },
                               { __index = methods })
    local fill = health:GetStatusBarTexture()
    local barrier = Strip(health, options.masks)
    barrier:SetPoint("TOPLEFT", fill, "TOPRIGHT")
    barrier:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT")
    local over = Strip(health, options.masks)
    over:SetAllPoints(health)
    over:SetReverseFill(true)
    over:SetAlpha(0)
    marks.barrier, marks.over = barrier, over
    marks.lost, marks.lostEnd = Lost(host, health, level)
    if not options.sample then marks.container = Container(marks) end
    marks.ready = true
    return marks
end

-- How far the health bar's right end stands in on a bar that wide: what the owner's Fit keeps free.
function methods:Reach(width)
    return (Plain(width) or 0) * self.share
end

-- Laid out for a bar that wide (the owner's Fit, after it has placed the bar by Reach).
function methods:Fit(width)
    width = Plain(width) or 0
    self.width = width
    local reach = self:Reach(width)
    self.barrier:SetWidth(math.max(width - reach, 1))
    self.lost:SetWidth(math.max(reach, 1))
    self.lost:SetShown(reach > 0)
end

-- How much of the bar is lost now; the owner lays it out where that changed.
local function Share(marks, share)
    share = math.max(math.min(share, Marks.MOST_LOST), 0)
    if math.abs(share - marks.share) < 0.001 then return end
    marks.share = share
    marks.options.fit()
end

function methods:Lose(unit)
    local share = 0
    if unit and self.lostOn then share = Core.Ask(rawget(_G, "GetUnitTotalModifiedMaxHealthPercent"), unit) end
    Share(self, Plain(share) or 0)
end

-- The barrier off: nothing of it shows.
local function Bare(marks)
    marks.barrier:SetValue(0)
    marks.over:SetValue(0)
    marks.over:SetAlpha(0)
end

-- The barrier's two bars, as the game says it now; the bars take hidden numbers as they are.
function methods:Barrier(unit)
    local calc = unit and self.barrierOn and Calculator()
    local most = calc and Raw(UnitHealthMax, unit)
    if type(most) == "nil" then return Bare(self) end
    local ok, amount, clamped, total = pcall(Read, calc, unit)
    if not ok or type(amount) == "nil" or type(total) == "nil" then return Bare(self) end
    self.barrier:SetMinMaxValues(0, most)
    self.barrier:SetValue(amount)
    self.over:SetMinMaxValues(0, most)
    self.over:SetValue(total)
    if Core.Secret(clamped) then
        if not pcall(self.over.SetAlphaFromBoolean, self.over, clamped, 1, 0) then self.over:SetAlpha(0) end
    else
        self.over:SetAlpha(clamped and 1 or 0)
    end
end

-- The container set for the unit: what a friend has to lose, or a foe; none for nil.
function methods:Dispel(unit)
    local container = self.container
    if not container then return end
    local on = unit ~= nil and self.dispelOn
    if on then
        local foe = Core.Ask(UnitCanAttack, "player", unit) == true
        container:SetAuraGroupFilterString(Marks.GROUP, foe and Marks.FOE or Marks.FRIEND)
        container:SetUnit(unit)
        container:UpdateAllAuras()
    else
        container:SetUnit("none")
    end
    container:SetEnabled(on)
    container:SetShown(on)
end

function methods:Set(unit)
    self.unit = unit
    self:Lose(unit)
    self:Barrier(unit)
    self:Dispel(unit)
end

-- A unit event of Marks.EVENTS, or the unit's health or most changed (what fits of the barrier changes with it).
function methods:Heard(unit, event)
    if event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then return self:Lose(unit) end
    self:Barrier(unit)
end

-- Each part on or off, as its owner's settings say; seen with the next Set.
function methods:Switch(barrier, lost, dispel)
    self.barrierOn, self.lostOn, self.dispelOn = barrier ~= false, lost ~= false, dispel ~= false
end

-- Where the icon stands: its bottom right corner there.
function methods:Place(relative, relativePoint, x, y)
    self.spot = { relative, relativePoint, x, y }
    for _, frame in ipairs({ self.container or false, self.parts and self.parts.top or false }) do
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMRIGHT", relative, relativePoint, x, y)
        end
    end
end

-- The icon's size, for its owner's sums.
function methods:IconSize()
    return self.options.size or Marks.SIZE
end

-- The ring and the icon of a sample: frames of their own, made when first shown.
local function SampleParts(marks)
    local parts = marks.parts
    if parts then return parts end
    parts = CreateFrame("Frame", nil, marks.host)
    parts:SetFrameLevel(marks.under)
    parts:SetAllPoints(marks.host)
    local top = CreateFrame("Frame", nil, parts)
    local size = marks.options.size or Marks.SIZE
    top:SetSize(size, size)
    top:SetFrameLevel(marks.above)
    local edge = top:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints(top)
    edge:SetTexture(Marks.WHITE)
    local icon = top:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", top, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", top, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(unpack(Marks.CROP))
    parts.top, parts.edge, parts.icon = top, edge, icon
    marks.parts = parts
    parts.ring = marks.options.ring(marks.options.inside and top or parts)
    marks.rings[#marks.rings + 1] = parts.ring
    marks.options.fit()
    if marks.spot then marks:Place(unpack(marks.spot)) end
    return parts
end

-- Made-up marks, for a look at them without a unit: shares of the bar, and a kind of aura.
function methods:Sample(sample)
    Share(self, sample.lost or 0)
    self.barrier:SetMinMaxValues(0, 1)
    self.barrier:SetValue(sample.barrier or 0)
    self.over:SetMinMaxValues(0, 1)
    self.over:SetValue(0)
    self.over:SetAlpha(0)
    local colour = sample.dispel and Marks.KINDS[sample.dispel]
    if not colour then
        if self.parts then self.parts:Hide() end
        return
    end
    local parts = SampleParts(self)
    parts:Show()
    parts.edge:SetVertexColor(colour[1], colour[2], colour[3], 1)
    parts.icon:SetTexture(Marks.SAMPLE_ICONS[sample.dispel])
    parts.ring:SetVertexColor(colour[1], colour[2], colour[3], 1)
end
