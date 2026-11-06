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
--                   buff that can be taken from it): the game's icon of its
--                   type (a green drop for poison ...), never the spell's
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
--  filled by the game, in a fight too. Its one frame shows nothing but a dispel
--  type texture in the game's Icon style, which the game sets and shows itself.
--  It floats over the words. In a fight addons cannot tell whether it is there,
--  and the game refuses anything of an addon's anchored to the container once
--  it has an aura group (its forbidden aspect UntrustedLayoutScriptExecution:
--  it sizes itself by what it shows), so nothing can step aside for it: what
--  shares its line stands before it, and it stands by that (marks:Place).
--  Its frame refuses every call of an addon's while auras are secret, so a
--  new size is the container's scale (marks:Resize).
--  No mouse on any of it: the unit's button under it keeps clicks and @mouseover.
--
--      local marks = Core.HealthMarks.New(host, health, {
--          masks = { ... },          -- the masks that round the bar's ends
--          fit = function() ... end, -- lay it all out: the bar (by marks:Reach), marks:Fit
--          size = 14,                -- the icon, square
--          above = level,            -- the icon's frame level, where it should stand over more than the bars
--          sample = true,            -- never for a live unit: no container
--      })
--      marks:Set(unit)               -- all of it for the unit; nil: none
--      marks:Heard(unit, event)      -- one of Marks.EVENTS, or the unit's health changed
--      marks:Switch(barrier, lost, dispel)
--      marks:Place(point, relative, relativePoint, x, y)   -- where the icon stands
--      marks:Resize(size)            -- the icon's size anew
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
Marks.NONE = 0.01       -- as wide as nothing: a frame that stands in a line of anchors
Marks.FRIEND = "HARMFUL|RAID_PLAYER_DISPELLABLE"
Marks.FOE = "HELPFUL|RAID_PLAYER_DISPELLABLE"
Marks.GROUP = "dispel" -- the container's one aura group
-- A kind's icon, for a sample: the game sets it itself on a live aura.
Marks.ICONS = { Magic = "RaidFrame-Icon-DebuffMagic", Curse = "RaidFrame-Icon-DebuffCurse",
                Disease = "RaidFrame-Icon-DebuffDisease", Poison = "RaidFrame-Icon-DebuffPoison" }

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

-- The frame the container makes for its aura: above the words, the type's icon alone, set and shown by the game. Here
-- only: right after this the game locks it from addon code while auras are secret (its access restriction
-- DenyTaintedAccessWhenAurasAreSecret, in a fight), so it keeps the size it was made at and marks:Resize scales
-- the container instead.
local function Dress(marks, frame)
    local size = marks.base
    frame:SetSize(size, size)
    pcall(frame.EnableMouse, frame, false)
    frame:SetFrameLevel(marks.above)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    local styles = rawget(_G, "Enum") and Enum.CustomAuraButtonDispelTypeTextureStyle
    if styles then
        pcall(frame.AddDispelTypeTexture, frame, icon, { style = styles.Icon, showWhenHarmful = true, showWhenHelpful = true })
    end
end

-- The container of the marks: one icon at most. nil where this client has none.
local function Container(marks)
    if Marks.missing then return nil end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, marks.host, "CustomAuraContainerTemplate")
    if not ok or not container then
        Marks.missing = true -- asked once: the next frames do without
        return nil
    end
    container:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if flow then container:SetFlowLayoutGrowthDirection(flow.Right, flow.Up) end
    local dressed = Core.Guard("health marks", function(frame) Dress(marks, frame) end)
    local sorts, ways = rawget(_G, "AuraContainerSortMethod"), rawget(_G, "AuraContainerSortDirection")
    container:AddAuraGroup(Marks.GROUP, Marks.FRIEND, {
        maxFrameCount = 1, initializeFrame = dressed, layout = { elementSpacing = 0 },
        sortMethod = sorts and sorts.UnitFrameDebuff or nil, sortDirection = ways and ways.Normal or nil })
    return container
end

-- What stands where the container would, for a sample or a client without one: as wide as nothing until it shows.
local function Stand(marks)
    local size = marks.options.size or Marks.SIZE
    local stand = CreateFrame("Frame", nil, marks.host)
    stand:SetSize(Marks.NONE, size)
    stand:SetFrameLevel(marks.above)
    local icon = stand:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", stand, "LEFT")
    icon:SetSize(size, size)
    icon:Hide()
    marks.icon = icon
    return stand
end

function Marks.New(host, health, options)
    local level = Plain(health:GetFrameLevel()) or 1
    local marks = setmetatable({ host = host, health = health, options = options, width = 0, share = 0,
                                 base = options.size or Marks.SIZE, barrierOn = true, lostOn = true, dispelOn = true, above = options.above or level + 4 },
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
    marks.lead = marks.container or Stand(marks)
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

-- Where the icon stands.
function methods:Place(point, relative, relativePoint, x, y)
    self.lead:ClearAllPoints()
    self.lead:SetPoint(point, relative, relativePoint, x, y)
end

-- The icon's size anew, in a fight too: the container's scale over the size its frame was made at (Dress), which the
-- game lets no addon touch then.
function methods:Resize(size)
    self.options.size = size
    if self.container then return self.container:SetScale(size / self.base) end
    self.icon:SetSize(size, size)
    self.lead:SetHeight(size)
    if self.icon:IsShown() then self.lead:SetWidth(size) end
end

-- Made-up marks, for a look at them without a unit: shares of the bar, and a kind of aura.
function methods:Sample(sample)
    Share(self, sample.lost or 0)
    self.barrier:SetMinMaxValues(0, 1)
    self.barrier:SetValue(sample.barrier or 0)
    self.over:SetMinMaxValues(0, 1)
    self.over:SetValue(0)
    self.over:SetAlpha(0)
    local atlas = sample.dispel and Marks.ICONS[sample.dispel]
    if atlas then self.icon:SetAtlas(atlas) end
    self.icon:SetShown(atlas ~= nil)
    self.lead:SetWidth(atlas and (self.options.size or Marks.SIZE) or Marks.NONE)
end
