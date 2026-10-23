local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Nameplates - Auras
--  Around a plate's bar, without a gap:
--    above   the debuffs and damage over time you put on the unit, from the
--            bar's left, as many as fit over its width
--    left    up to three of its buffs, on a unit you can attack, as the game
--            picks buffs for its own plates, past the quest's icon and the
--            raid marker, growing away from the bar
--    right   the crowd control on it (stuns, fears, roots, by anyone),
--            growing away from the bar
--  Your crowd control shows on the right only, not twice.
--
--  All are the game's own aura containers (CustomAuraContainerTemplate,
--  Blizzard_AuraContainer), one per place and plate, made with the plate's
--  dress and kept with it. The game fills them: which auras, their icons,
--  times and stacks, in a fight too, where aura data is hidden from addons;
--  our code only says the filter, how many, where they start and which way
--  they grow, and draws each icon once, when the container makes its frame
--  (Dress): the icon cut by the mask of the game's own nameplate auras, their
--  border and their swipe, the stack count above the swipe. Nothing runs per
--  aura change. A plate the game reuses for another unit gets its containers
--  set to that unit.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Auras = {}
ns.Auras = Auras

Auras.SIZE = 20 -- an icon, square
Auras.GAP = 2   -- between icons
Auras.BUFFS = 3 -- a foe's buffs at most
Auras.CONTROL = 2 -- crowd control at most
Auras.OWN = "HARMFUL|PLAYER|!CROWD_CONTROL"       -- the debuffs you put on it, but your crowd control
Auras.FOES = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"    -- a foe's buffs, as the game's own plates pick them
Auras.CC = "HARMFUL|CROWD_CONTROL"                -- crowd control on it, by anyone
-- The game's own nameplate auras' look: the icon's mask, its border (reaching past a 25-unit icon by these
-- shares), the swipe of the time gone.
Auras.MASK = "UI-HUD-CoolDownManager-Mask"
Auras.OVERLAY = "UI-HUD-CoolDownManager-IconOverlay"
Auras.REACH = { 6 / 25, 5 / 25 }
Auras.SWIPE = "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe"

-- One icon, drawn into a frame the container makes (once per frame; the container keeps them).
local function Dress(frame)
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
    -- The count over the swipe: in a frame of its own above the cooldown's.
    local top = CreateFrame("Frame", nil, frame)
    top:SetAllPoints(frame)
    top:SetFrameLevel(cooldown:GetFrameLevel() + 1)
    local count = top:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    count:SetJustifyH("RIGHT")
    count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -1)
    frame:SetIcon(icon)
    frame:SetDurationCooldown(cooldown)
    frame:SetApplicationCount(count)
end
local Dressed = ns.Guard(Dress) -- the container calls it, for each frame it makes

-- A container of the game's on the dress, its icons starting at that corner and growing that way (and up).
-- nil where this client has none.
local function Container(dress, corner, growth, key, filter, most)
    local flow = rawget(_G, "AnchorUtil") and AnchorUtil.FlowDirection
    if not flow or Auras.missing then return nil end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, dress, "CustomAuraContainerTemplate")
    if not ok or not container then
        Auras.missing = true -- asked once: the next plates do without
        ns.Report("auras", "this client has no aura container for addons; the plates show no auras")
        return nil
    end
    container:SetFlowLayoutAnchorPoint(corner)
    container:SetFlowLayoutGrowthDirection(flow[growth], flow.Up)
    container:AddAuraGroup(key, filter, { maxFrameCount = most, initializeFrame = Dressed,
                                          layout = { elementSpacing = Auras.GAP } })
    container.key, container.most = key, most
    return container
end

function Auras.Make(dress)
    dress.own = Container(dress, "BOTTOMLEFT", "Right", "own", Auras.OWN, 0)
    dress.foes = Container(dress, "BOTTOMRIGHT", "Left", "foes", Auras.FOES, Auras.BUFFS)
    dress.control = Container(dress, "BOTTOMLEFT", "Right", "control", Auras.CC, Auras.CONTROL)
    if dress.own then dress.own:SetPoint("BOTTOMLEFT", dress, "TOPLEFT", 0, 0) end
    Auras.Place(dress)
end

-- A foe's buffs left of the bar, past the icons outside it (Text.Layout); the crowd control right of the bar.
function Auras.Place(dress)
    local foes, control = dress.foes, dress.control
    if foes then
        foes:ClearAllPoints()
        foes:SetPoint("BOTTOMRIGHT", dress, "BOTTOMLEFT", -(Auras.GAP + (dress.outside or 0)), 0)
    end
    if not control then return end
    control:ClearAllPoints()
    control:SetPoint("BOTTOMLEFT", dress, "BOTTOMRIGHT", Auras.GAP, 0)
end

-- How many icons fit side by side over a bar that wide.
function Auras.Slots(width)
    width = Plain(width) or 0
    return math.max(math.floor((width + Auras.GAP) / (Auras.SIZE + Auras.GAP)), 0)
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

-- The containers set for the dress's unit (or none), each as its switch and the unit say.
function Auras.Set(dress, unit)
    local options = ns.options or {}
    local foe = unit and Plain(UnitCanAttack("player", unit)) ~= false
    Most(dress.own, Auras.Slots(dress:GetWidth()))
    Shown(dress.own, unit, unit ~= nil and options.debuffs ~= false)
    Shown(dress.foes, unit, unit ~= nil and foe and options.buffs ~= false)
    Shown(dress.control, unit, unit ~= nil and options.control ~= false)
end
