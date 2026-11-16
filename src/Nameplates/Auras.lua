local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Auras
--  Around a plate's bar, without a gap, each kind where its setting puts it
--  (Saneroki, 2026-11-16: "choose where the spells are"): above the bar,
--  growing right from its left end; at its left, growing away from it; or at
--  its right, growing away from it. At first:
--    above   the debuffs and damage over time you put on the unit, as many as
--            fit over the bar (eight at most)
--    left    up to three of its buffs, on a unit you can attack, as the game
--            picks buffs for its own plates
--    right   the crowd control on it (stuns, fears, roots, by anyone), up to
--            two
--  How many of each at most are the settings Your debuffs, Buffs on foes and
--  Crowd control (Auras.Most; 0: none); where, Your debuffs: where and so on
--  (Auras.Where). Two kinds on one side stand in rows, the first nearest the
--  bar (debuffs, then buffs, then crowd control). The icons are as high as
--  the bar at first, a share of it by the setting Spell icon size (Saneroki,
--  2026-11-16: "Make the default size of the spells the same height as the
--  nameplate bar"). Your crowd control shows with the crowd control only.
--
--  All are the game's own aura containers (CustomAuraContainerTemplate,
--  Blizzard_AuraContainer), one per kind and plate, made with the plate's
--  dress and kept with it. The game fills them: which auras, their icons,
--  times and stacks, in a fight too, where aura data is hidden from addons;
--  our code only says the filter, how many, where they start and which way
--  they grow, and draws each icon once, when the container makes its frame
--  (Dress): the icon cut by the mask of the game's own nameplate auras, their
--  border and their swipe, the stack count above the swipe, the seconds left.
--  The game lets no addon touch its icons later (in a fight their frames
--  refuse every call), so their size is the container's scale over the size
--  they were made at (Auras.SIZE), as Core's health marks size their icon.
--  Nothing runs per aura change. A plate the game reuses for another unit
--  gets its containers set to that unit. With the setting Plates show at
--  Health bar only there are none (ns.Style); at Spells only they stand
--  where they would, around the game's own bar's place (Text.Bare).
--
--  The seconds left: the game's own text for an aura button's time
--  (SetDurationText), which it fills itself, hidden values and all; shown
--  only while a minute or less is left (Saneroki, 2026-11-16: "everything
--  above 60s we just show the buff / debuff without its number"), by a colour
--  curve on the time left that the game reads itself (Auras.Curve), as large
--  and as see-through as the settings say. The swipe's own numbers are off
--  then. A client without that text keeps the swipe's numbers.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Auras = {}
ns.Auras = Auras

Auras.SIZE = 20 -- an icon as the containers make it, square; drawn at the setting's size by the container's scale
Auras.GAP = 2   -- between icons, and from the bar
Auras.BUFFS = 3 -- a foe's buffs at most, at first
Auras.CONTROL = 2 -- crowd control at most, at first
Auras.LONG = 60 -- seconds left above which an icon shows no number
Auras.NUMBER = "NumberFontNormal" -- the font object whose face the seconds left take
Auras.OWN = "HARMFUL|PLAYER|!CROWD_CONTROL"       -- the debuffs you put on it, but your crowd control
Auras.FOES = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"    -- a foe's buffs, as the game's own plates pick them
Auras.CC = "HARMFUL|CROWD_CONTROL"                -- crowd control on it, by anyone
-- The kinds, nearest the bar first where two share a side: the dress's key, the filter, its count's and its place's
-- settings.
Auras.KINDS = {
    { key = "own", filter = Auras.OWN, count = "debuffCount", place = "debuffPlace", first = "above" },
    { key = "foes", filter = Auras.FOES, count = "buffCount", place = "buffPlace", first = "left" },
    { key = "control", filter = Auras.CC, count = "controlCount", place = "controlPlace", first = "right" },
}
Auras.SIDES = { above = true, left = true, right = true }
-- The game's own nameplate auras' look: the icon's mask, its border (reaching past a 25-unit icon by these
-- shares), the swipe of the time gone.
Auras.MASK = "UI-HUD-CoolDownManager-Mask"
Auras.OVERLAY = "UI-HUD-CoolDownManager-IconOverlay"
Auras.REACH = { 6 / 25, 5 / 25 }
Auras.SWIPE = "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe"

local dressed = setmetatable({}, { __mode = "k" }) -- [an icon the game made] = { timer, cooldown }, once dressed

-- How many of a kind show at most, as its setting says ("debuffCount", "buffCount", "controlCount"; ns.AURAS at
-- first): a whole number, 0 for none.
function Auras.Most(key)
    local most = tonumber((ns.options or {})[key]) or ns.AURAS[key] or 0
    return math.max(math.floor(most), 0)
end

-- Where a kind stands ("above", "left", "right"), as its setting says.
function Auras.Where(kind)
    local place = (ns.options or {})[kind.place]
    return Auras.SIDES[place] and place or kind.first
end

-- An icon's size, in the units of a dress that high: the setting Spell icon size, a share of the bar's height.
function Auras.Size(height)
    local share = (tonumber((ns.options or {}).auraSize) or 100) / 100
    return math.max((Plain(height) or 0) * share, 4)
end

-- The rows of icons above a bar that high, and their height: one per kind above it that shows at all (Scale.Stacking,
-- the gold arrow).
function Auras.Above(height)
    if ns.Style() == "bar" then return 0, 0 end
    local rows = 0
    for _, kind in ipairs(Auras.KINDS) do
        if Auras.Where(kind) == "above" and Auras.Most(kind.count) > 0 then rows = rows + 1 end
    end
    return rows * (Auras.Size(height) + Auras.GAP), rows
end

-- The seconds left's look: the face of the game's numbers, a share of the icon's height (Time left: size).
local function Font(timer)
    local object = rawget(_G, Auras.NUMBER)
    local file = type(object) == "table" and object.GetFont and object:GetFont()
    local share = (tonumber((ns.options or {}).durationSize) or 50) / 100
    timer:SetFont(type(file) == "string" and file or "Fonts\\ARIALN.TTF", math.max(Auras.SIZE * share, 4), "OUTLINE")
end

-- The curve that colours the seconds left by the time left (the game reads it itself, hidden or not): white as
-- see-through as Time left: transparency says up to Auras.LONG seconds, gone above; gone with Time left in the
-- icons off. One for all icons, its points made anew when a setting changed. nil where this client has none.
local curve
function Auras.Curve()
    local util, make = rawget(_G, "C_CurveUtil"), rawget(_G, "CreateColor")
    if type(util) ~= "table" or not util.CreateColorCurve or not make then return nil end
    curve = curve or Core.Ask(util.CreateColorCurve)
    if not curve then return nil end
    local options = ns.options or {}
    local alpha = options.duration == false and 0 or 1 - (tonumber(options.durationTransparency) or 0) / 100
    local ok = pcall(function()
        curve:ClearPoints()
        curve:AddPoint(0, make(1, 1, 1, alpha))
        curve:AddPoint(Auras.LONG, make(1, 1, 1, alpha))
        curve:AddPoint(Auras.LONG + 0.5, make(1, 1, 1, 0))
        curve:AddPoint(1000000, make(1, 1, 1, 0))
    end)
    return ok and curve or nil
end

-- The seconds left on an icon the game made: its own text through our curve, the swipe's numbers off; where this
-- client has no such text, the swipe's numbers as before (none with the setting off).
local function Timer(frame, timer, cooldown)
    Font(timer)
    local shape = Auras.Curve()
    local enum = rawget(_G, "Enum")
    local remaining = type(enum) == "table" and enum.DurationTextBindingProperty
        and enum.DurationTextBindingProperty.RemainingDuration
    if shape and remaining and type(frame.SetDurationText) == "function"
        and pcall(frame.SetDurationText, frame, timer, { textColor = { curve = shape, property = remaining } }) then
        timer:Show()
        pcall(cooldown.SetHideCountdownNumbers, cooldown, true)
        return
    end
    timer:Hide()
    pcall(cooldown.SetHideCountdownNumbers, cooldown, (ns.options or {}).duration == false)
end

-- One icon's look on a frame: the icon cut by the mask of the game's nameplate auras, their border, the swipe of the
-- time gone, the stack count above it and the seconds left in its middle. Returns the icon, the swipe, the count and
-- the seconds left. The setup's sample plates draw theirs with it too (Sample.lua).
function Auras.Look(frame)
    local size = Auras.SIZE
    frame:SetSize(size, size)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    local mask = frame:CreateMaskTexture()
    mask:SetAtlas(Auras.MASK)
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    local overlay = frame:CreateTexture(nil, "OVERLAY")
    overlay:SetAtlas(Auras.OVERLAY)
    local x, y = size * Auras.REACH[1], size * Auras.REACH[2]
    overlay:SetPoint("TOPLEFT", frame, "TOPLEFT", -x, y)
    overlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x, -y)
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(true)
    cooldown:SetSwipeTexture(Auras.SWIPE)
    cooldown:SetSwipeColor(0, 0, 0, 0.5)
    -- The count and the seconds left over the swipe: in a frame of their own above the cooldown's.
    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(frame)
    top:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetJustifyH("RIGHT")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -1)
    local timer = top:CreateFontString(nil, "OVERLAY")
    Font(timer)
    timer:SetPoint("CENTER", frame, "CENTER", 0, 0)
    return icon, cooldown, count, timer
end

-- One icon, drawn into a frame the container makes (once per frame; the container keeps them).
local function Dress(frame)
    local icon, cooldown, count, timer = Auras.Look(frame)
    frame:SetIcon(icon)
    frame:SetDurationCooldown(cooldown)
    frame:SetApplicationCount(count)
    Timer(frame, timer, cooldown)
    dressed[frame] = { timer = timer, cooldown = cooldown }
end
local Dressed = ns.Guard(Dress) -- the container calls it, for each frame it makes

-- The settings of the seconds left changed: the curve made anew, every icon made so far told again (each by itself:
-- one the game refuses now keeps what it had until it is made again).
function Auras.Restyle()
    Auras.Curve()
    for frame, parts in pairs(dressed) do
        pcall(Timer, frame, parts.timer, parts.cooldown)
    end
end

-- Where a container's icons start and which way they grow, for its side: above and at the right from the bottom left
-- corner rightwards, at the left from the bottom right corner leftwards (and up). Told the game only when it changed.
local function Flow(container, place)
    if container.place == place then return end
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if not flow then return end
    local left = place == "left"
    if pcall(container.SetFlowLayoutAnchorPoint, container, left and "BOTTOMRIGHT" or "BOTTOMLEFT")
        and pcall(container.SetFlowLayoutGrowthDirection, container, left and flow.Left or flow.Right, flow.Up) then
        container.place = place
    end
end

-- A container of the game's on the dress for a kind (Auras.KINDS), at most that many icons. nil where this client has
-- none.
local function Container(dress, kind, most)
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if not flow or Auras.missing then return nil end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, dress, "CustomAuraContainerTemplate")
    if not ok or not container then
        Auras.missing = true -- asked once: the next plates do without
        ns.Report("auras", "this client has no aura container for addons; the plates show no auras")
        return nil
    end
    Flow(container, Auras.Where(kind))
    container:AddAuraGroup(kind.key, kind.filter, { maxFrameCount = most, initializeFrame = Dressed,
                                                    layout = { elementSpacing = Auras.GAP } })
    container.key, container.most = kind.key, most
    return container
end

function Auras.Make(dress)
    local most = { own = 0, foes = Auras.BUFFS, control = Auras.CONTROL }
    for _, kind in ipairs(Auras.KINDS) do dress[kind.key] = Container(dress, kind, most[kind.key]) end
    Auras.Place(dress)
end

-- Each kind's container at its side, at the setting's size, a row further out for each kind before it on that side;
-- the gold arrow over your target (Spells only) above the rows over the bar. dress.auraSize: the icons' size now.
function Auras.Place(dress)
    local height = Plain(dress:GetHeight()) or 0
    local size = Auras.Size(height)
    local scale, row = size / Auras.SIZE, size + Auras.GAP
    local rows = { above = 0, left = 0, right = 0 }
    local on = ns.Style() ~= "bar"
    for _, kind in ipairs(Auras.KINDS) do
        local place = Auras.Where(kind)
        local out = rows[place]
        if on and Auras.Most(kind.count) > 0 then rows[place] = out + 1 end
        local container = dress[kind.key]
        if container then
            container:SetScale(scale)
            Flow(container, place)
            container:ClearAllPoints()
            local up = out * row / scale -- a container's own units are its scale's
            if place == "above" then
                container:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", 0, up)
            elseif place == "left" then
                container:SetPoint("BOTTOMRIGHT", dress, "BOTTOMLEFT", -Auras.GAP / scale, up)
            else
                container:SetPoint("BOTTOMLEFT", dress, "BOTTOMRIGHT", Auras.GAP / scale, up)
            end
        end
    end
    dress.auraSize, dress.auraRows = size, rows
    if dress.arrow then
        dress.arrow:ClearAllPoints()
        dress.arrow:SetPoint("BOTTOM", dress, "TOP", 0, math.max(rows.above, 1) * row)
    end
end

-- How many icons of that size (Auras.SIZE at first) fit side by side over a bar that wide.
function Auras.Slots(width, size)
    width = Plain(width) or 0
    return math.max(math.floor((width + Auras.GAP) / ((size or Auras.SIZE) + Auras.GAP)), 0)
end

local function Most(container, most)
    if not container or container.most == most then return end
    container.most = most
    container:SetAuraGroupMaxFrameCount(container.key, most)
end

local function Shown(container, unit, on)
    if not container then return end
    container:SetUnit(on and unit or "none")
    container:SetEnabled(on)
    container:SetShown(on)
end

-- How many icons of a kind a dress shows at most: its setting's; above the bar no more than fit over it.
function Auras.Count(dress, kind)
    local most = Auras.Most(kind.count)
    if Auras.Where(kind) == "above" then
        most = math.min(Auras.Slots(dress:GetWidth(), dress.auraSize or Auras.Size(dress:GetHeight())), most)
    end
    return most
end

-- The containers placed and set for the dress's unit (or none), each as its settings and the unit say: a foe's buffs
-- on a unit you can attack alone; none while the plates show the health bar only (ns.Style).
function Auras.Set(dress, unit)
    Auras.Place(dress)
    local on = unit ~= nil and ns.Style() ~= "bar"
    local foe = unit and Plain(UnitCanAttack("player", unit)) ~= false
    for _, kind in ipairs(Auras.KINDS) do
        local container = dress[kind.key]
        local most = Auras.Count(dress, kind)
        Most(container, most)
        Shown(container, unit, on and most > 0 and (kind.key ~= "foes" or foe))
    end
end
