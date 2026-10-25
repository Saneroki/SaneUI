local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Glints
--  The herbs and ore the minimap found (Found.lua) marked on the screen however
--  far they are: a column of gold light with sparkles drifting up it where one
--  stands, the picture of what it gives under it and how many yards away it is.
--  One outside the view stands at the screen's left or right edge instead, on
--  the side you would turn to, the game's navigation arrow pointing on. The
--  setting Sparkles on far herbs and ore.
--
--  Placed roughly, on purpose: the game tells no addon where its camera looks.
--  Sane UI takes it as it usually is: behind you as far as its zoom
--  (GetCameraZoom), looking the way you face (GetPlayerFacing), tilted down a
--  little (Glints.PITCH), through the angle of the game's setting cameraFov
--  (taken as the angle across a 16:9 screen, the height's angle kept on other
--  screens). A found place goes through that camera to the screen. The game
--  tells no height either, so a place lies at your own height, and the column
--  stands up through it: a hill or a hollow moves only its foot.
--
--  While the left mouse button turns the camera away from your facing they wait:
--  until the right button turns you with the camera, or you have moved on for a
--  while (the camera swings in behind you as you go). Within reach of the
--  interact key the close sparkles take over (Sparkles.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Nodes, Found = ns.Coords, ns.Nodes, ns.Found
local Glints = {}
ns.Glints = Glints

Glints.MOST = 8            -- marked at once, the nearest first
Glints.NEAR = 18           -- yards: nearer than this, the close sparkles take over
Glints.FULL = 40           -- yards: nearer than this a mark is at its full size, smaller with distance
Glints.SMALL = 0.5         -- the smallest size, of the farthest
Glints.PITCH = math.rad(12) -- the camera's tilt down taken (nothing tells it)
Glints.PIVOT = 2           -- yards over your feet that the camera turns about
Glints.ZOOM = 15           -- yards behind you, where the game tells no zoom
Glints.FOV = 90            -- degrees, where the game has no setting cameraFov
Glints.HOLD = 0.25         -- seconds the left button is down before it counts as turning the camera
Glints.SETTLE = 1.5        -- seconds of moving after which the camera is behind you again
Glints.HEIGHT = 120        -- a column's height at full size, a fifth of it below its foot
Glints.WIDTH = 3           -- and its width
Glints.SPARKS = 3          -- sparkles drifting up a column
Glints.RISE = 1.6          -- seconds a sparkle takes up it
Glints.STAR = 14           -- a sparkle's side at full size
Glints.ICON = 18           -- the picture's side at full size
Glints.EDGE = 40           -- an edge mark's distance from the screen's edge
Glints.STACK = 46          -- edge marks one under another, from the middle down

local STAR = "Interface\\Cooldown\\star4"            -- the game's four-pointed star (as the close sparkles)
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local ARROW = "Navigation-Tracked-Arrow"             -- the game's own arrow to what it leads to (it points up)
local GOLD = { 1, 0.82, 0 }                          -- the game's gold (NORMAL_FONT_COLOR)
local YARDS = Core.Word("IN_GAME_NAVIGATION_RANGE", "%d yd")
local FONT = "SaneUINavigationGlints"

local holder        -- our frame over the world, under every window; its OnUpdate runs while it shows
local marks = {}    -- the marks made: { frame, low, high, sparks, icon, arrow, text }
local list = {}     -- this frame's candidates: { entry, yards, x, y } or { entry, yards, side } (kept from frame to frame)
local turning = 0   -- seconds the left button has turned the camera
local stale = false -- the camera turned away from your facing, not yet behind you again
local settling = 0  -- seconds moved since

-------------------------------------------------------------------------------
--  The camera Sane UI takes
-------------------------------------------------------------------------------
-- The screen's scale for the camera: UIParent units per unit of the view's tangent, from the height's angle.
local function Scale(height)
    local fov = tonumber(Core.Plain(Core.Ask(C_CVar.GetCVar, "cameraFov"))) or Glints.FOV
    local across = math.tan(math.rad(fov) / 2)
    return (height / 2) / (across * 9 / 16)
end

-- A place du yards east and dv north of you, at your height, through the camera: x, y from the screen's middle
-- (UIParent units), or nil behind it. Facing as the game's: 0 north, turning to the left.
local function Project(du, dv, facing, zoom, scale)
    local au, av = -math.sin(facing), math.cos(facing) -- ahead
    local ru, rv = av, -au                            -- to the right
    local tc, ts = math.cos(Glints.PITCH), math.sin(Glints.PITCH)
    -- From the eye: behind the pivot by the zoom along the ground, above it by the tilt.
    local back = zoom * tc
    local qu, qv, qz = du + au * back, dv + av * back, -(Glints.PIVOT + zoom * ts)
    local along = qu * au + qv * av
    local depth = along * tc - qz * ts
    if depth < 1 then return nil end
    return scale * (qu * ru + qv * rv) / depth, scale * (along * ts + qz * tc) / depth
end

-- Whether your facing may stand for the camera's now: not while the left button turns the camera alone, nor after
-- it until the right button turns you with it or you have moved on a while.
local function Behind(elapsed)
    local left, right = IsMouseButtonDown("LeftButton"), IsMouseButtonDown("RightButton")
    if right then
        turning, stale = 0, false
        return true
    end
    if left then
        local foci = (GetMouseFoci and GetMouseFoci()) or (GetMouseFocus and { GetMouseFocus() }) or {}
        local world = foci[1] == WorldFrame
        if world or turning > 0 then turning = turning + elapsed end
        if turning >= Glints.HOLD then stale, settling = true, 0 end
    else
        turning = 0
    end
    if stale and not left then
        if (Core.Plain(Core.Ask(GetUnitSpeed, "player")) or 0) > 0 then settling = settling + elapsed end
        if settling >= Glints.SETTLE then stale = false end
    end
    return not stale
end

-------------------------------------------------------------------------------
--  The marks
-------------------------------------------------------------------------------
local function Gradient(texture, bottom, top)
    texture:SetColorTexture(1, 1, 1, 1)
    texture:SetGradient("VERTICAL", CreateColor(GOLD[1], GOLD[2], GOLD[3], bottom),
        CreateColor(GOLD[1], GOLD[2], GOLD[3], top))
end

local function Mark(index)
    local mark = marks[index]
    if mark then return mark end
    local frame = CreateFrame("Frame", nil, holder)
    frame:SetSize(1, 1)
    local low, high = frame:CreateTexture(nil, "BACKGROUND"), frame:CreateTexture(nil, "BACKGROUND")
    Gradient(low, 0, 0.5)
    Gradient(high, 0.5, 0)
    low:SetBlendMode("ADD")
    high:SetBlendMode("ADD")
    local sparks = {}
    for spark = 1, Glints.SPARKS do
        local star = frame:CreateTexture(nil, "ARTWORK")
        star:SetTexture(STAR)
        star:SetBlendMode("ADD")
        star:SetVertexColor(GOLD[1], GOLD[2], GOLD[3])
        -- Each its own way up the column, so they do not rise together.
        star.phase = (spark - 1) / Glints.SPARKS + math.random() * 0.1
        sparks[spark] = star
    end
    local icon = frame:CreateTexture(nil, "OVERLAY")
    local mask = frame:CreateMaskTexture()
    mask:SetTexture(ROUND, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    local arrow = frame:CreateTexture(nil, "OVERLAY")
    arrow:SetAtlas(ARROW, true)
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(Core.Font(FONT, "GameFontHighlightSmall", 11, "OUTLINE") or "GameFontHighlightSmall")
    mark = { frame = frame, low = low, high = high, sparks = sparks, icon = icon, arrow = arrow, text = text }
    marks[index] = mark
    return mark
end

-- A mark in the world: its column through x, y (its foot), the sparkles risen by now, its picture and yards under it.
local function Column(mark, x, y, size, rise)
    local frame, height = mark.frame, Glints.HEIGHT * size
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", holder, "CENTER", x, y)
    mark.low:ClearAllPoints()
    mark.low:SetPoint("TOP", frame, "CENTER")
    mark.low:SetSize(Glints.WIDTH, height * 0.2)
    mark.high:ClearAllPoints()
    mark.high:SetPoint("BOTTOM", frame, "CENTER")
    mark.high:SetSize(Glints.WIDTH, height * 0.8)
    mark.low:Show()
    mark.high:Show()
    for _, star in ipairs(mark.sparks) do
        local at = (star.phase + rise) % 1
        local side = Glints.STAR * size * (0.6 + 0.4 * math.sin(at * math.pi))
        star:SetSize(side, side)
        star:SetAlpha(math.sin(at * math.pi))
        star:ClearAllPoints()
        star:SetPoint("CENTER", frame, "CENTER", 0, height * (at * 0.8 - 0.1))
        star:Show()
    end
    mark.arrow:Hide()
end

-- A mark at the screen's edge: the arrow pointing out on that side, beside the picture.
local function Edge(mark, side, y)
    local frame = mark.frame
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", holder, "CENTER", side * (holder:GetWidth() / 2 - Glints.EDGE), y)
    mark.low:Hide()
    mark.high:Hide()
    for _, star in ipairs(mark.sparks) do star:Hide() end
    mark.arrow:SetRotation(-side * math.pi / 2)
    mark.arrow:ClearAllPoints()
    mark.arrow:SetPoint("CENTER", frame, "CENTER", side * Glints.ICON, 0)
    mark.arrow:Show()
end

-- Its picture, grey while your skill is too low for it, and its yards under it: under a column's foot, or in the
-- middle of an edge mark.
local function Label(mark, entry, yards, size, edge)
    local icon, side = mark.icon, Glints.ICON * math.max(size, 0.75)
    local file = entry.picture or Nodes.Picture(entry.node)
    entry.picture = file
    icon:SetSize(side, side)
    icon:ClearAllPoints()
    if edge then
        icon:SetPoint("CENTER", mark.frame, "CENTER")
    else
        icon:SetPoint("TOP", mark.frame, "CENTER", 0, -2)
    end
    icon:SetTexture(file or 134400) -- (the game's question mark, while the item is not known yet)
    icon:SetDesaturated(Nodes.TooHard(entry.node))
    icon:Show()
    mark.text:ClearAllPoints()
    mark.text:SetPoint("TOP", icon, "BOTTOM", 0, -1)
    mark.text:SetFormattedText(YARDS, math.floor(yards + 0.5))
    mark.text:Show()
    mark.frame:Show()
end

local function HideAll(from)
    for index = from or 1, #marks do marks[index].frame:Hide() end
end

-------------------------------------------------------------------------------
--  Each frame
-------------------------------------------------------------------------------
local function Nearer(a, b)
    return a.yards < b.yards
end

-- This frame's candidates in the list: each found one of a kind the pin filter shows, beyond the close sparkles'
-- reach, where the camera puts it (x, y), or, off the screen across or behind you, the side you would turn to.
local function Gather(found, plane, pu, pv, facing)
    local zoom = tonumber(Core.Plain(Core.Ask(rawget(_G, "GetCameraZoom")))) or Glints.ZOOM
    local edge = holder:GetWidth() / 2 - Glints.EDGE
    local scale = Scale(holder:GetHeight())
    local count = 0
    for _, entry in ipairs(found) do
        if entry.plane == plane and ns.Pins.Shows(Nodes.FOUND[entry.kind]) then
            local du, dv = entry.u - pu, entry.v - pv
            local yards = math.sqrt(du * du + dv * dv)
            if yards >= Glints.NEAR then
                count = count + 1
                local candidate = list[count] or {}
                list[count] = candidate
                candidate.entry, candidate.yards = entry, yards
                candidate.x, candidate.y = Project(du, dv, facing, zoom, scale)
                if not candidate.x or math.abs(candidate.x) > edge then
                    local across = math.cos(facing) * du + math.sin(facing) * dv
                    candidate.x, candidate.side = nil, across >= 0 and 1 or -1
                end
            end
        end
    end
    for index = count + 1, #list do list[index] = nil end
    table.sort(list, Nearer)
end

local function Update(_, elapsed)
    local behind = Behind(elapsed)
    local found = Found.Each()
    local plane, pu, pv = Coords.Player()
    local facing = behind and pu and #found > 0 and Core.Plain(Core.Ask(GetPlayerFacing))
    if not facing then return HideAll() end
    Gather(found, plane, pu, pv, facing)
    local rise = (GetTime() / Glints.RISE) % 1
    local shown, right, left = 0, 0, 0
    for _, candidate in ipairs(list) do
        if shown >= Glints.MOST then break end
        shown = shown + 1
        local mark = Mark(shown)
        if candidate.x then
            local size = math.max(Glints.SMALL, math.min(1, Glints.FULL / candidate.yards))
            Column(mark, candidate.x, candidate.y, size, rise)
            Label(mark, candidate.entry, candidate.yards, size)
        else
            local side = candidate.side
            Edge(mark, side, -(side == 1 and right or left) * Glints.STACK)
            if side == 1 then right = right + 1 else left = left + 1 end
            Label(mark, candidate.entry, candidate.yards, 1, true)
        end
    end
    HideAll(shown + 1)
end

-- Shown while the setting is on and the module is; nothing drawn and nothing asked otherwise.
function Glints.Update()
    if not holder then return end
    local on = ns.options.nodeGlints and not ns.off
    if not on then HideAll() end
    holder:SetShown(on)
end

function Glints.Start()
    holder = CreateFrame("Frame", nil, UIParent)
    Glints.frame = holder
    holder:SetAllPoints(UIParent)
    holder:SetFrameStrata("BACKGROUND")
    holder:SetScript("OnUpdate", ns.Guard(Update))
    Glints.Update()
end

-- The module stood down: nothing more drawn.
function Glints.Hide()
    if not holder then return end
    HideAll()
    holder:Hide()
end
