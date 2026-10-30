local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Glints
--  The herbs and ore the minimap found (Found.lua) marked on the screen however
--  far they are: the picture of what each gives, round in a ring of stitched
--  leather that runs out into a point the way to it (up: ahead, right: to your
--  right, down: behind you), and how far away it is under it. One
--  you can see stands where it is on the screen; one outside the view stands at
--  the screen's left or right edge, on the side you would turn to. The setting
--  Far herbs and ore on the screen.
--
--  Placed roughly, on purpose: the game tells no addon where its camera looks.
--  Sane UI takes it as it usually is: behind you as far as its zoom
--  (GetCameraZoom), looking the way you face (GetPlayerFacing), tilted down a
--  little (Glints.PITCH), through the angle of the game's setting cameraFov
--  (taken as the angle across a 16:9 screen, the height's angle kept on other
--  screens). A found place goes through that camera to the screen, at your own
--  height (the game tells no height either).
--
--  While the left mouse button turns the camera away from your facing they wait:
--  until the right button turns you with the camera, or you have moved on for a
--  while (the camera swings in behind you as you go). Within reach of the
--  interact key the close sparkles take over (Sparkles.lua).
--
--  Only where the minimap's herbs and ore are found (Found.Works, Nodes.Known):
--  not in Retail, whose minimap tells no addon what its dots are; nothing runs there.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Nodes, Found = ns.Coords, ns.Nodes, ns.Found
local Glints = {}
ns.Glints = Glints

Glints.MOST = 8            -- marked at once, the nearest first
Glints.NEAR = 18           -- yards: nearer than this, the close sparkles take over
Glints.FULL = 40           -- yards: nearer than this a mark is at its full size, smaller with distance
Glints.SMALL = 0.8         -- the smallest size, of the farthest
Glints.PITCH = math.rad(12) -- the camera's tilt down taken (nothing tells it)
Glints.PIVOT = 2           -- yards over your feet that the camera turns about
Glints.ZOOM = 15           -- yards behind you, where the game tells no zoom
Glints.FOV = 90            -- degrees, where the game has no setting cameraFov
Glints.HOLD = 0.25         -- seconds the left button is down before it counts as turning the camera
Glints.SETTLE = 1.5        -- seconds of moving after which the camera is behind you again
Glints.ICON = 32           -- the ring's hole's width at full size (the picture a little wider, under the leather)
-- The ring: the leather one of the found ones on the minimap (Found.RING, Found.Ring), with its point at the top
-- (dev/tools/mark-art), drawn round the middle of its hole, so it turns about the picture's middle.
Glints.RING = "Interface\\AddOns\\SaneUI_Navigation\\Art\\mark-pointed"
Glints.TIP = 510 / 1040 * 252 / 256 -- its point's tip from the middle, in the picture's side (dev/tools/mark-art's canvas)
Glints.EDGE = 44           -- an edge mark's distance from the screen's edge
Glints.STACK = 58          -- edge marks one under another, from the middle down
Glints.TEXT = 12           -- the yards' letters' size

local FONT = "SaneUINavigationGlints"

local holder        -- our frame over the world, under every window; its OnUpdate runs while it shows
local marks = {}    -- the marks made: { frame, icon, ring, text }
local list = {}     -- this frame's candidates: { entry, yards, way, x, y } or { entry, yards, way, side }
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
local function Mark(index)
    local mark = marks[index]
    if mark then return mark end
    local frame = CreateFrame("Frame", nil, holder)
    frame:SetSize(1, 1)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", frame, "CENTER")
    Found.Round(icon, frame:CreateMaskTexture())
    local ring = frame:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(Glints.RING)
    -- How far: the number alone, as the setting Units has it, under the ring, outlined so it reads on any ground.
    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(Core.Font(FONT, "GameFontHighlight", Glints.TEXT, "OUTLINE") or "GameFontHighlight")
    mark = { frame = frame, icon = icon, ring = ring, text = text }
    marks[index] = mark
    return mark
end

-- A mark: its picture (grey while your skill is too low for it) in the ring at x, y, the ring turned so its point shows
-- the way (0 up, turning to the right), its yards under it (under the point too, while that points down).
local function Draw(mark, candidate, x, y, size)
    local entry, side = candidate.entry, Glints.ICON * size
    local file = entry.picture or Nodes.Picture(entry.node)
    entry.picture = file
    mark.frame:ClearAllPoints()
    mark.frame:SetPoint("CENTER", holder, "CENTER", x, y)
    mark.icon:SetTexture(file or 134400) -- (the game's question mark, while the item is not known yet)
    mark.icon:SetDesaturated(Nodes.TooHard(entry.node))
    Found.Ring(mark.ring, mark.icon, side)
    mark.ring:SetRotation(-candidate.way)
    local whole = mark.ring:GetWidth()
    local low = math.max(Found.OUTER, -math.cos(candidate.way) * Glints.TIP) * whole
    mark.text:ClearAllPoints()
    mark.text:SetPoint("TOP", mark.frame, "CENTER", 0, -low - 1)
    mark.text:SetFormattedText("%d", Core.DistanceNumber(candidate.yards))
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
-- reach, with the way to it from your facing, and where the camera puts it (x, y) or, off the screen across or
-- behind you, the side you would turn to.
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
                local across = math.cos(facing) * du + math.sin(facing) * dv
                local ahead = -math.sin(facing) * du + math.cos(facing) * dv
                candidate.entry, candidate.yards, candidate.way = entry, yards, math.atan2(across, ahead)
                candidate.x, candidate.y = Project(du, dv, facing, zoom, scale)
                if not candidate.x or math.abs(candidate.x) > edge then
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
    local top = holder:GetHeight() / 2 - Glints.EDGE
    local shown, right, left = 0, 0, 0
    for _, candidate in ipairs(list) do
        if shown >= Glints.MOST then break end
        shown = shown + 1
        local mark = Mark(shown)
        if candidate.x then
            local size = math.max(Glints.SMALL, math.min(1, Glints.FULL / candidate.yards))
            Draw(mark, candidate, candidate.x, math.max(-top, math.min(top, candidate.y)), size)
        else
            local side = candidate.side
            local x = side * (holder:GetWidth() / 2 - Glints.EDGE)
            Draw(mark, candidate, x, -(side == 1 and right or left) * Glints.STACK, 1)
            if side == 1 then right = right + 1 else left = left + 1 end
        end
    end
    HideAll(shown + 1)
end

-- Shown while the setting is on, the module is and herbs and ore are found; nothing drawn and nothing asked otherwise.
function Glints.Update()
    if not holder then return end
    local on = ns.options.nodeGlints and not ns.off and Found.Works() and Nodes.Known()
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
