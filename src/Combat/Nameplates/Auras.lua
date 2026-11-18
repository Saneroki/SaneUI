local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Combat - Nameplates - Auras
--  Around a plate's bar, each kind at one of eight places its setting
--  chooses (Saneroki, 2026-11-16: "choose where the spells are"; 2026-11-18:
--  "left, right, top left (above the healthbar but anchored to the left side
--  over the healthbar), top right, top center, bottom left, bottom center,
--  bottom right"; Auras.PLACES): over the bar from its left end, its middle
--  or its right end; at its left or right, growing away from it; under it
--  the same three, under the combo points and the cast bar's place (Bar.Outline:
--  dress.low), so a cast never moves them. At first:
--    top left  the debuffs and damage over time you put on the unit, as many
--              as fit over the bar (eight at most)
--    left      up to three of its buffs, on a unit you can attack, as the game
--              picks buffs for its own plates
--    right     the crowd control on it (stuns, fears, roots, by anyone), up to
--              two
--  How many of each at most are the settings Your debuffs, Buffs on foes and
--  Crowd control (Auras.Most; 0: none); where, Your debuffs: where and so on
--  (Auras.Where). Two kinds at one place stand in rows, the first nearest the
--  bar (debuffs, then buffs, then crowd control); kinds at different places
--  over or under the bar share its row, each with its share of the bar's
--  width (Auras.Layout). The icons are as high as the bar at first, a share
--  of it by the setting Spell icon size (Saneroki, 2026-11-16: "Make the
--  default size of the spells the same height as the nameplate bar"). Your
--  crowd control shows with the crowd control only.
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
--  (SetDurationText), which it fills itself, hidden values and all, written by
--  the game's own number formatter as we set it (Auras.Numbers): whole seconds
--  rounded up, no "s" or "m", never over 60, so more time left reads 60
--  (Saneroki, 2026-11-16: "don't show s or m on the nameplates just the
--  numbers and never more then 60"); as large and as see-through as the
--  settings say, by a colour curve on the time left that the game reads itself
--  (Auras.Curve). The swipe's own numbers are off then. A client without that
--  formatter shows the game's own words for the time, none over a minute; one
--  without that text keeps the swipe's numbers.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Auras = {}
ns.Auras = Auras

Auras.SIZE = 20 -- an icon as the containers make it, square; drawn at the setting's size by the container's scale
Auras.GAP = 2   -- between icons, and from the bar
Auras.BUFFS = 3 -- a foe's buffs at most, at first
Auras.CONTROL = 2 -- crowd control at most, at first
Auras.LONG = 60 -- the most seconds an icon's number says: more time left reads this
Auras.NUMBER = "NumberFontNormal" -- the font object whose face the seconds left take
Auras.OWN = "HARMFUL|PLAYER|!CROWD_CONTROL"       -- the debuffs you put on it, but your crowd control
Auras.FOES = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"    -- a foe's buffs, as the game's own plates pick them
Auras.CC = "HARMFUL|CROWD_CONTROL"                -- crowd control on it, by anyone
-- The kinds, nearest the bar first where two share a side: the dress's key, the filter, its count's and its place's
-- settings.
Auras.KINDS = {
    { key = "own", filter = Auras.OWN, count = "debuffCount", place = "debuffPlace", first = "topleft" },
    { key = "foes", filter = Auras.FOES, count = "buffCount", place = "buffPlace", first = "left" },
    { key = "control", filter = Auras.CC, count = "controlCount", place = "controlPlace", first = "right" },
}
-- The eight places: the band (over the bar, under it, at its left or right), the corner of a container and of an
-- icon that stands on the bar's (or, under the bar, on dress.low's) corner named by to, and which way the icons grow
-- along it (dir: 1 to the right, -1 to the left; middle: centred on it); side: away from the bar by Auras.GAP.
Auras.PLACES = {
    topleft = { band = "top", point = "BOTTOMLEFT", to = "TOPLEFT", dir = 1 },
    top = { band = "top", point = "BOTTOM", to = "TOP", dir = 1, middle = true },
    topright = { band = "top", point = "BOTTOMRIGHT", to = "TOPRIGHT", dir = -1 },
    left = { band = "left", point = "BOTTOMRIGHT", to = "BOTTOMLEFT", dir = -1, side = -1 },
    right = { band = "right", point = "BOTTOMLEFT", to = "BOTTOMRIGHT", dir = 1, side = 1 },
    bottomleft = { band = "bottom", point = "TOPLEFT", to = "TOPLEFT", dir = 1 },
    bottom = { band = "bottom", point = "TOP", to = "TOP", dir = 1, middle = true },
    bottomright = { band = "bottom", point = "TOPRIGHT", to = "TOPRIGHT", dir = -1 },
}
Auras.OLD = { above = "topleft" } -- a place kept by its earlier name
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

-- Where a kind stands (a key of Auras.PLACES), as its setting says.
function Auras.Where(kind)
    local place = (ns.options or {})[kind.place]
    place = Auras.OLD[place] or place
    return Auras.PLACES[place] and place or kind.first
end

-- Where each kind stands now, by its key: { place, look (its Auras.PLACES entry), band, row, share, shown }. A row
-- further out for each kind before it at the same place (0 nearest the bar); over and under the bar, kinds at
-- different places on one row split its width (share: two at its ends a half each; one in its middle with others a
-- third each, so none reaches into another). A kind that shows none (0, Health bar only) takes no row. Made anew
-- after a setting changed (Auras.Changed) or another profile came in.
local layout, laidFor
function Auras.Changed()
    layout = nil
end
function Auras.Layout()
    local options = ns.options or {}
    if layout and laidFor == options then return layout end
    local spots, taken, lines = {}, {}, {}
    local on = ns.Style() ~= "bar"
    for _, kind in ipairs(Auras.KINDS) do
        local place = Auras.Where(kind)
        local look = Auras.PLACES[place]
        local spot = { place = place, look = look, band = look.band, row = taken[place] or 0, share = 1,
                       shown = on and Auras.Most(kind.count) > 0 }
        if spot.shown then
            taken[place] = spot.row + 1
            if look.band == "top" or look.band == "bottom" then
                local line = look.band .. spot.row
                lines[line] = lines[line] or {}
                table.insert(lines[line], spot)
            end
        end
        spots[kind.key] = spot
    end
    for _, line in pairs(lines) do
        local middle = false
        for _, spot in ipairs(line) do middle = middle or spot.look.middle == true end
        for _, spot in ipairs(line) do spot.share = #line > 1 and middle and 3 or #line end
    end
    layout, laidFor = spots, options
    return spots
end

-- An icon's size, in the units of a dress that high: the setting Spell icon size, a share of the bar's height.
function Auras.Size(height)
    local share = (tonumber((ns.options or {}).auraSize) or 100) / 100
    return math.max((Plain(height) or 0) * share, 4)
end

-- The rows of icons in a band over a bar that high, or under it: their height and how many (Auras.Layout).
local function Rows(band, height)
    local rows = 0
    for _, spot in pairs(Auras.Layout()) do
        if spot.shown and spot.band == band then rows = math.max(rows, spot.row + 1) end
    end
    return rows * (Auras.Size(height) + Auras.GAP), rows
end

-- Over the bar (Scale.Stacking, the gold arrow); under it, from dress.low (Bar.Outline: the foot under them).
function Auras.Above(height) return Rows("top", height) end
function Auras.Below(height) return Rows("bottom", height) end

-- The seconds left's look: the face of the game's numbers, a share of the icon's height (Time left: size).
local function Font(timer)
    local object = rawget(_G, Auras.NUMBER)
    local file = type(object) == "table" and object.GetFont and object:GetFont()
    local share = (tonumber((ns.options or {}).durationSize) or 50) / 100
    timer:SetFont(type(file) == "string" and file or "Fonts\\ARIALN.TTF", math.max(Auras.SIZE * share, 4), "OUTLINE")
end

-- The game's number formatter for the seconds left (it runs it itself, hidden values and all): whole seconds rounded
-- up, no unit, never over Auras.LONG. Made once and tried on two numbers; nil where this client has none, or where it
-- writes them otherwise.
local numbers
function Auras.Numbers()
    if numbers ~= nil then return numbers or nil end
    numbers = false
    local util, enum = rawget(_G, "C_StringUtil"), rawget(_G, "Enum")
    if type(util) ~= "table" or type(util.CreateNumericRuleFormatter) ~= "function" then return nil end
    local rounding = type(enum) == "table" and type(enum.NumericRuleFormatRounding) == "table"
        and enum.NumericRuleFormatRounding.Up or 1
    for _, format in ipairs({ "%d", "%.0f" }) do
        local made = Core.Ask(util.CreateNumericRuleFormatter)
        local rule = { threshold = 0, step = 1, rounding = rounding, max = Auras.LONG, format = format }
        if made ~= nil and pcall(made.SetBreakpoints, made, { rule }) then
            if type(made.FormatNumber) ~= "function" or Core.Ask(made.FormatNumber, made, 4.2) == "5"
                and Core.Ask(made.FormatNumber, made, 600) == tostring(Auras.LONG) then
                numbers = made
                return made
            end
        end
    end
    return nil
end

-- The curve that colours the seconds left by the time left (the game reads it itself, hidden or not): white as
-- see-through as Time left: transparency says; gone with Time left in the icons off. Where this client writes the
-- time in its own words (no Auras.Numbers), gone above Auras.LONG seconds, so the number always fits. One for all
-- icons, its points made anew when a setting changed. nil where this client has none.
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
        if Auras.Numbers() then
            curve:AddPoint(1000000, make(1, 1, 1, alpha))
        else
            curve:AddPoint(Auras.LONG, make(1, 1, 1, alpha))
            curve:AddPoint(Auras.LONG + 0.5, make(1, 1, 1, 0))
            curve:AddPoint(1000000, make(1, 1, 1, 0))
        end
    end)
    return ok and curve or nil
end

-- The game's own text for an icon's seconds left, through our curve, written by our formatter (none: the game's
-- words). Whether the game took it.
local function Text(frame, timer, written)
    local shape, enum = Auras.Curve(), rawget(_G, "Enum")
    local remaining = type(enum) == "table" and enum.DurationTextBindingProperty
        and enum.DurationTextBindingProperty.RemainingDuration
    return shape ~= nil and remaining ~= nil and type(frame.SetDurationText) == "function" and pcall(frame.SetDurationText,
        frame, timer, { textFormatter = written, textColor = { curve = shape, property = remaining } })
end

-- The seconds left on an icon the game made: its own text, the swipe's numbers off. Where the game refuses our
-- formatter, its own words from then on (the curve then hides them over a minute); where this client has no such
-- text, the swipe's numbers as before, by our formatter where it takes one (none with the setting off).
local function Timer(frame, timer, cooldown)
    Font(timer)
    local written = Auras.Numbers()
    local shown = Text(frame, timer, written)
    if not shown and written and type(frame.SetDurationText) == "function" then
        numbers = false
        written = nil
        shown = Text(frame, timer, nil)
    end
    if shown then
        timer:Show()
        pcall(cooldown.SetHideCountdownNumbers, cooldown, true)
        return
    end
    timer:Hide()
    if written and cooldown.SetCountdownFormatter then pcall(cooldown.SetCountdownFormatter, cooldown, written) end
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

-- Where a container's icons start and which way they grow, for its place: from its own corner on the bar (its
-- point; in the middle from its left, the container as wide as its icons and centred), left or right as its place
-- grows, up over the bar and beside it, down under it. Told the game only when it changed.
local function Flow(container, place)
    if container.place == place then return end
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    local look = Auras.PLACES[place]
    if not flow or not look then return end
    local start = look.middle and (look.band == "bottom" and "TOPLEFT" or "BOTTOMLEFT") or look.point
    if pcall(container.SetFlowLayoutAnchorPoint, container, start)
        and pcall(container.SetFlowLayoutGrowthDirection, container, look.dir < 0 and flow.Left or flow.Right,
            look.band == "bottom" and flow.Down or flow.Up) then
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

-- Where an icon or a container of a kind stands (spot: Auras.Layout's) on a dress: the frame and its corner it
-- stands on, and how far from it; along: how far along its row (0 for a container: the game lays its icons out).
-- Over the bar and beside it a row further up for each before it; under it a row further down, from dress.low.
function Auras.Spot(dress, spot, along, row)
    local look = spot.look
    local out = spot.row * row
    local x = (look.side or 0) * Auras.GAP + look.dir * along
    if look.band == "bottom" then return dress.low or dress, look.to, x, -(out + Auras.GAP) end
    return dress, look.to, x, out
end

-- The rows over the bar on a dress, and of them those at its right end: the gold arrow over your target (Spells
-- only) above them all, the dispel type's icon (Core.HealthMarks) above the bar's right end and the icons there.
function Auras.Over(dress, spots, row)
    local top, right = 0, 0
    for _, spot in pairs(spots) do
        if spot.shown and spot.band == "top" then
            top = math.max(top, spot.row + 1)
            if spot.place == "topright" then right = math.max(right, spot.row + 1) end
        end
    end
    if dress.arrow then
        dress.arrow:ClearAllPoints()
        dress.arrow:SetPoint("BOTTOM", dress, "TOP", 0, math.max(top, 1) * row)
    end
    if dress.marks then dress.marks:Place("BOTTOMRIGHT", dress, "TOPRIGHT", 0, 2 + right * row) end
    return top
end

-- Each kind's container at its place, at the setting's size (Auras.Layout, Auras.Spot); the arrow and the dispel
-- type's icon over them (Auras.Over). dress.auraSize: the icons' size now; dress.auraRows: the rows over and under it.
function Auras.Place(dress)
    local height = Plain(dress:GetHeight()) or 0
    local size = Auras.Size(height)
    local scale, row = size / Auras.SIZE, size + Auras.GAP
    local spots = Auras.Layout()
    for _, kind in ipairs(Auras.KINDS) do
        local spot = spots[kind.key]
        local container = dress[kind.key]
        if container then
            container:SetScale(scale)
            Flow(container, spot.place)
            container:ClearAllPoints()
            local on, to, x, y = Auras.Spot(dress, spot, 0, row)
            container:SetPoint(spot.look.point, on, to, x / scale, y / scale) -- a container's own units are its scale's
        end
    end
    dress.auraSize = size
    dress.auraRows = { top = Auras.Over(dress, spots, row), bottom = select(2, Auras.Below(height)) }
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

-- How many icons of a kind a dress shows at most: its setting's; over and under the bar no more than fit in its
-- share of the bar's width (Auras.Layout).
function Auras.Count(dress, kind)
    local most = Auras.Most(kind.count)
    local spot = Auras.Layout()[kind.key]
    if spot.band == "top" or spot.band == "bottom" then
        local width = (Plain(dress:GetWidth()) or 0) / spot.share
        most = math.min(Auras.Slots(width, dress.auraSize or Auras.Size(dress:GetHeight())), most)
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
