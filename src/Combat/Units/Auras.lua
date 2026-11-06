local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Units - Auras
--  Above a unit frame, in one line over what stands on the frame now (its cast:
--  the containers stand on its roof, Bar.Fit), the auras that matter most,
--  four buffs, two crowd control and four debuffs at most, each kind a block of
--  icons that touch, no borders (Saneroki, 2026-10-31, 2026-11-02):
--    on the left, from its edge    buffs: on a foe those the game shows on its
--                                  own plates, on a friend (and you) any, big
--                                  defensives first
--    in the middle                 crowd control on it, by anyone
--    on the right, from its edge   debuffs: on a foe the ones you put on it, on
--                                  a friend (and you) any, the game's most
--                                  important first (its unit frames' order:
--                                  what you can dispel, a boss's)
--  A container is as wide as what it holds (the game sizes it), so the middle
--  one, standing by its bottom middle, stays centred however many it shows.
--  And before them, in front of the rest and with the game's golden outline, the ones you
--  marked Important (what no longer fits a line goes up: the kinds stay clear of
--  each other); never the ones marked Unimportant (Lists.lua keeps the lists).
--  Your marks of the unit frames alone go over those: Prioritize on unit frames in
--  front of the rest without a glow, Hide from unit frames never.
--
--  Out of a fight ours show them (AuraRow.lua), which the mouse can reach. In a
--  fight the game's own aura containers do (CustomAuraContainerTemplate), one
--  per kind and frame, as the nameplates' are. The game fills them, where aura
--  data is hidden from addons, and applies the lists itself
--  (an aura group's candidate filters: the spells to include, to exclude). It
--  lets the lists act where it lets addons tell spells apart: on the buffs of
--  you, your group and friendly units, and on the debuffs of foes; elsewhere it
--  decides alone (the window says so).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Auras = {}
ns.UnitAuras = Auras

Auras.SIZE = 22 -- an icon, square
Auras.GAP = 2   -- from the frame
-- A container's widest line for so many icons, a pixel to spare: what comes after goes up. Exactly as wide as they are would
-- lose the last to a rounding of the game's.
function Auras.Line(most)
    return most * Auras.SIZE + 1
end
Auras.CROP = { 0.08, 0.92, 0.08, 0.92 } -- an icon's picture without the edge it is drawn with
-- The kinds: how many at most (of each list too), their place on the frame's roof, the corner they grow from inside their
-- container and which way, their
-- filters on a foe and a friend, the order the game gives them, and whether the lists act on them (listed: the filter
-- of the group of your important ones).
Auras.KINDS = {
    { key = "buffs", most = 4, harmful = false, point = "BOTTOMLEFT", corner = "BOTTOMLEFT", growth = "Right", sort = "BigDefensive",
      foe = "HELPFUL|INCLUDE_NAME_PLATE_ONLY", friend = "HELPFUL", listed = "HELPFUL" },
    { key = "control", most = 2, harmful = true, point = "BOTTOM", corner = "BOTTOMLEFT", growth = "Right", sort = "Default",
      foe = "HARMFUL|CROWD_CONTROL", friend = "HARMFUL|CROWD_CONTROL" },
    { key = "debuffs", most = 4, harmful = true, point = "BOTTOMRIGHT", corner = "BOTTOMRIGHT", growth = "Left", sort = "UnitFrameDebuff",
      foe = "HARMFUL|PLAYER|!CROWD_CONTROL", friend = "HARMFUL|!CROWD_CONTROL", listed = "HARMFUL" },
}

local faces = {}                                   -- every face with containers

-- The two lists as the game's candidate filters take them: { [spell] = true }; nil where empty.
local function Set(...)
    local set = nil
    for index = 1, select("#", ...) do
        for id in pairs(select(index, ...) or {}) do
            id = tonumber(id)
            if id then
                set = set or {}
                set[id] = true
            end
        end
    end
    return set
end

local function Lists()
    local options = ns.options or {}
    return options.auraWhite or {}, options.auraBlack or {}, options.auraShow or {}, options.auraHide or {}
end

-- A set of Set's without what is in the other; nil where nothing is left.
local function Without(set, other)
    for id in pairs(set or {}) do
        if other and other[id] then set[id] = nil end
    end
    return set and next(set) ~= nil and set or nil
end

-- A group of the spells it holds, off while there are none.
local function Holds(container, key, spells)
    container:SetAuraGroupCandidateFilters(key, spells and { includeSpellIDs = spells } or nil)
    container:SetAuraGroupEnabled(key, spells ~= nil)
end

-- What an icon is made of, on a frame of the game's or ours: the picture cropped square, the swipe darkening the time gone
-- (it alone tells the time: no numbers), the stack count over it.
function Auras.Paint(frame)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)
    icon:SetTexCoord(Auras.CROP[1], Auras.CROP[2], Auras.CROP[3], Auras.CROP[4])
    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    cooldown:SetReverse(true)
    cooldown:SetSwipeColor(0, 0, 0, 0.5)
    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(frame)
    top:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetJustifyH("RIGHT")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    cooldown:SetHideCountdownNumbers(true) -- the darkening alone tells the time
    return { picture = icon, cooldown = cooldown, top = top, count = count }
end

-- One of the game's icons, in a frame its container makes (once per frame; the container keeps them); in the group of your
-- important ones the game's outline (BuffList.lua), so it needs no telling which an icon is in a fight. No script of ours
-- runs on it, nor on what stands in it: the outline's animation is started here.
local function Dress(frame, glowing)
    frame:SetSize(Auras.SIZE, Auras.SIZE)
    local parts = Auras.Paint(frame)
    local alert = glowing and ns.BuffList.Alert(parts.top, frame)
    if alert then
        alert:SetFrameLevel(parts.top:GetFrameLevel() + 3) -- it reaches over the icons beside it, which touch
        alert:Show()
        alert.ProcLoop:Play()
    end
    frame:SetIcon(parts.picture)
    frame:SetDurationCooldown(parts.cooldown)
    frame:SetApplicationCount(parts.count)
end

-- A container of the game's for one kind on the face: the group of your important ones first (where the lists act
-- on the kind), then the rest. nil where this client has none.
local function Container(face, kind)
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if not flow or Auras.missing then return nil end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, face, "CustomAuraContainerTemplate")
    if not ok or not container then
        Auras.missing = true -- asked once: the next frames do without
        ns.Report("unit frame auras", "this client has no aura container for addons; the unit frames show no auras")
        return nil
    end
    container:SetFlowLayoutAnchorPoint(kind.corner)
    container:SetFlowLayoutGrowthDirection(flow[kind.growth], flow.Up)
    container:SetFlowLayoutMaximumLineSize(Auras.Line(kind.most))
    -- guarded: the game calls these per icon
    local dressed = ns.Guard(function(frame) Dress(frame) end)
    local shining = ns.Guard(function(frame) Dress(frame, true) end)
    local sorts, ways = rawget(_G, "AuraContainerSortMethod"), rawget(_G, "AuraContainerSortDirection")
    local function Options(sort, initialize)
        return { maxFrameCount = kind.most, initializeFrame = initialize,
                 layout = { elementSpacing = 0, lineSpacing = 0, elementWidth = Auras.SIZE, elementHeight = Auras.SIZE },
                 sortMethod = sorts and sorts[sort] or nil, sortDirection = ways and ways.Normal or nil }
    end
    if kind.listed then
        container:AddAuraGroup("listed", kind.listed, Options("Default", shining))
        container:AddAuraGroup("shown", kind.listed, Options("Default", dressed))
    end
    container:AddAuraGroup("auto", kind.friend, Options(kind.sort, dressed))
    container.kind = kind
    return container
end

function Auras.Make(face)
    face.auras = {}
    for _, kind in ipairs(Auras.KINDS) do
        local container = Container(face, kind)
        face.auras[kind.key] = container
        if container then container:SetPoint(kind.point, face.roof, kind.point, 0, Auras.GAP) end
    end
    -- Over the row above the frame and one more: at rest what keeps the frame in sight between the icons. It takes no mouse.
    face.aurasArea = CreateFrame("Frame", nil, face)
    face.aurasArea:SetPoint("BOTTOMLEFT", face.roof, "BOTTOMLEFT", 0, 0)
    face.aurasArea:SetPoint("BOTTOMRIGHT", face.roof, "BOTTOMRIGHT", 0, 0)
    face.aurasArea:SetHeight(2 * Auras.SIZE + Auras.GAP)
    faces[#faces + 1] = face
    Auras.Listed(face)
end

-- Every face with auras.
function Auras.Each(fn)
    for _, face in ipairs(faces) do ns.Safe("unit frame auras", fn, face) end
end

-- What your marks say of the unit frames: the important (glowing), those of Prioritize on unit frames, what never shows. The
-- marks of the unit frames alone go first: Hide takes an important one off, Show brings an unimportant one, no glow.
function Auras.Sets()
    local white, black, shown, hide = Lists()
    return Without(Set(white), Set(hide)), Without(Set(shown), Set(white)), Without(Set(black, hide), Set(shown))
end

-- The lists into a face's containers: those groups their spells, the rest without those and without what never shows;
-- crowd control without what never shows.
function Auras.Listed(face)
    local first, second, never = Auras.Sets()
    for _, container in pairs(face.auras or {}) do
        local exclude = never
        if container.kind.listed then
            Holds(container, "listed", first)
            Holds(container, "shown", second)
            exclude = Set(first, second, never)
        end
        container:SetAuraGroupCandidateFilters("auto", exclude and { excludeSpellIDs = exclude } or nil)
    end
end

-- Every face's auras anew (a list changed).
function Auras.Refresh()
    Auras.Each(Auras.Listed)
    Auras.Each(ns.AuraRow.Fill)
end

-- A face's auras for its unit (or none, nil: out of sight): our row while the game tells them (AuraRow.lua), else its
-- containers, with the filters of a foe or a friend, asked to read the auras again (another unit behind the same
-- token: a new target).
function Auras.Set(face, unit)
    local on = unit ~= nil and not ns.off and (ns.options or {}).unitAuras ~= false
    local foe = on and Core.Ask(UnitCanAttack, "player", unit) == true
    local game = on and not ns.AuraRow.Open()
    face.auraAsked, face.auraUnit, face.auraFoe = unit, on and unit or nil, foe
    for _, container in pairs(face.auras or {}) do
        if on then container:SetAuraGroupFilterString("auto", foe and container.kind.foe or container.kind.friend) end
        if game then
            container:SetUnit(unit)
            container:UpdateAllAuras()
        else
            container:SetUnit("none")
        end
        container:SetEnabled(game)
        container:SetShown(game)
    end
    ns.AuraRow.Fill(face)
end
