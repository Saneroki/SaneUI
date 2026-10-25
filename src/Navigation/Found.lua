local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Found
--  The herbs and ore the game's minimap shows as dots, found and drawn over it
--  in their own pictures: what each gives (its herb, its ore) in a round ring of
--  stitched leather, the far sparkles' (Glints.lua) without their point, grey
--  while your skill is too low for it. The
--  pin filter's kinds Found herbs and Found ore, each its own size there; the
--  same on our small map (Hybrid.lua lays the game's minimap over it) and on the
--  game's own minimap (the switch Show the game's minimap).
--
--  Finding them: the game tells no addon where its dots are, but it answers
--  what its minimap's tooltip would say at any point of it (with its soft
--  cursor on, Minimap:UpdateMouseoverAtPoint, then
--  C_TooltipInfo.GetMinimapMouseover). A sweep asks over the whole minimap,
--  row by row, each row shifted by half a step (every point has six neighbours
--  at one distance), Found.ASKS points a frame, out of combat and never while
--  the mouse is over the minimap (its tooltip is yours then). A point that
--  names a herb or ore (Nodes.Find) is narrowed to its dot's middle: the way
--  out to where the answer stops halved a few times, to the left and right,
--  then down and up from between them. How far a dot answers is learnt from
--  those edges, and the sweep's step follows it.
--
--  A sweep done, the dots of the kind whose finder is on are what the game
--  shows now: one it covered and found no more is gone. Those it did not cover,
--  and those of the other kind (the finders take turns, Nodes.lua), are kept,
--  until you loot a node beside one, go far from it, or it is Found.KEEP
--  seconds old.
--
--  Kept in yards in the player's plane (Coords.lua), so they stay put while you
--  move; drawn at their distance from you (the minimap's middle) times the
--  minimap's units per yard, turned with it where the game's own minimap turns,
--  each frame you or its zoom moved.
--
--  Each picture takes the mouse, as the pins do: its tooltip names the herb or
--  ore, a click pings it to the group as a click on the game's minimap there
--  would (Ping.lua), and a double click puts the game's map pin where it is (its
--  zone's map) too, so the game's arrow leads there.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords, Nodes = ns.Coords, ns.Nodes
local Found = {}
ns.Found = Found

Found.ASKS = 40     -- points asked at most in a frame
Found.REST = 0.4    -- seconds between the end of a sweep and the next
Found.KEEP = 300    -- seconds one of the kind whose finder is off is kept
Found.FAR = 2       -- and how far it may be: so many of the minimap's radii
Found.LOOTED = 10   -- yards: a looted node takes the nearest found one this near with it
Found.MOST = 60     -- pictures drawn at most
-- The leather ring Saneroki picked for the found ones (dev/tools/mark-art), round here; the far sparkles have it with
-- its point (Glints.lua). Its picture is drawn round the middle of its hole; in the picture's side, the hole's radius
-- and the ring's outer one (the art tool keeps 2 of 256 texels clear round it).
Found.RING = "Interface\\AddOns\\SaneUI_Navigation\\Art\\mark-round"
Found.HOLE = 0.2293 * 252 / 256
Found.OUTER = 0.2942 * 252 / 256
Found.TRIM = 0.12   -- of an item's picture cut off at each side: its own frame and the dark band inside it
Found.FILL = 1.16   -- the round picture's width over the hole's: its edge under the leather, never in sight
local ROUND = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local SHAPE = { "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE" }

local reach = 10     -- how far from its middle a dot answers, in the minimap's units (learnt)
local REACH_LOW, REACH_HIGH = 4, 30
local STEP = 1.5     -- the sweep's step in reaches: a spot is at most step / sqrt(3) from a point, inside reach
local HALVINGS = 4   -- how often the way to a dot's edge is halved

local overlay        -- our frame over the game's minimap, its child
local pictures = {}  -- the textures drawn: { icon, mask, ring }
local found = {}     -- { u, v, plane, kind, node, picture, seen, swept }
local sweep          -- the sweep going on: { points, at, kind, plane, half, round, number }
local sweeps = 0     -- sweeps made, a number for each
local nextSweep = 0  -- when the next may begin
local drawn = {}     -- what the pictures were last drawn for: plane, u, v, scale, facing, count

local function Minimap()
    return overlay and overlay:GetParent()
end

-- Whether the game's minimap turns with you: its own setting, while it is not ours (ours is north up).
local function Turned()
    return not ns.Hybrid.Taken() and Core.Plain(Core.Ask(C_CVar.GetCVar, "rotateMinimap")) == "1"
end

-- The game's minimap is round where it is its own (the game's mask), square on our map (Hybrid.MASK).
local function Round()
    return not ns.Hybrid.Taken()
end

-- Its units per yard, nil while the game does not say how far it shows.
local function Scale(minimap)
    local radius = Core.Plain(Core.Ask(C_Minimap.GetViewRadius))
    local width = minimap:GetWidth()
    if not radius or radius <= 0 or not width or width <= 0 then return nil end
    return width / 2 / radius
end

-- Whether the pin filter shows a kind's found ones.
local function Shown(kind)
    return ns.Pins.Shows(Nodes.FOUND[kind])
end

-------------------------------------------------------------------------------
--  Asking the minimap
-------------------------------------------------------------------------------
local cx, cy, pixels -- the minimap's middle on the screen and its scale, for one frame's asks

-- The first herb or ore a tooltip's line names: its names without colours and pictures, one per line.
local function Named(text)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|n", "\n")
    for name in text:gmatch("[^\n]+") do
        local node = Nodes.Find(name:match("^%s*(.-)%s*$"))
        if node then return node end
    end
    return nil
end

-- The first herb or ore the minimap's tooltip names at x, y units from its middle, or nil.
local function Ask(minimap, x, y)
    minimap:UpdateMouseoverAtPoint((cx + x) * pixels, (cy + y) * pixels)
    local data = Core.Ask(C_TooltipInfo.GetMinimapMouseover)
    local lines = type(data) == "table" and data.lines
    if type(lines) ~= "table" then return nil end
    for _, line in ipairs(lines) do
        local text = type(line) == "table" and Core.Plain(line.leftText)
        local node = type(text) == "string" and Named(text)
        if node then return node end
    end
    return nil
end

-- How far out from x, y (inside the dot) along dx, dy the dot of that node still answers.
local function Edge(minimap, node, x, y, dx, dy)
    local inside, outside = 0, reach * 2
    local asked = Ask(minimap, x + dx * outside, y + dy * outside)
    if asked and asked.key == node.key then return outside, 1 end
    for _ = 1, HALVINGS do
        local middle = (inside + outside) / 2
        asked = Ask(minimap, x + dx * middle, y + dy * middle)
        if asked and asked.key == node.key then inside = middle else outside = middle end
    end
    return (inside + outside) / 2, HALVINGS + 1
end

-- A dot's middle from a point inside it, and the asks it took. Its half width, where both ways agree on it
-- (two dots side by side do not), is learnt as how far a dot answers.
local function Middle(minimap, node, x, y)
    local left, a = Edge(minimap, node, x, y, -1, 0)
    local right, b = Edge(minimap, node, x, y, 1, 0)
    x = x + (right - left) / 2
    local down, c = Edge(minimap, node, x, y, 0, -1)
    local up, d = Edge(minimap, node, x, y, 0, 1)
    y = y + (up - down) / 2
    local wide, high = (left + right) / 2, (down + up) / 2
    if math.abs(wide - high) < 0.25 * math.max(wide, high) then
        reach = math.min(math.max(reach + ((wide + high) / 2 - reach) / 4, REACH_LOW), REACH_HIGH)
    end
    return x, y, a + b + c + d
end

-------------------------------------------------------------------------------
--  The places
-------------------------------------------------------------------------------
-- A point of the minimap (units from its middle) in the plane, and back; facing: the way you face where it turns.
local function ToPlane(x, y, pu, pv, scale, facing)
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        x, y = x * c - y * s, x * s + y * c
    end
    return pu + x / scale, pv + y / scale
end

local function ToMinimap(u, v, pu, pv, scale, facing)
    local x, y = (u - pu) * scale, (v - pv) * scale
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        x, y = x * c + y * s, -x * s + y * c
    end
    return x, y
end

local function Remove(index)
    table.remove(found, index)
    drawn.count = nil
end

-- A dot found in this sweep: the one kept of that node this near is moved there, else it is new.
local function Note(node, u, v, plane, near)
    local now = GetTime()
    for _, kept in ipairs(found) do
        if kept.node.key == node.key and kept.plane == plane and (kept.u - u) ^ 2 + (kept.v - v) ^ 2 < near * near then
            kept.u, kept.v, kept.seen, kept.swept = u, v, now, sweep.number
            drawn.count = nil
            return
        end
    end
    found[#found + 1] = { u = u, v = v, plane = plane, kind = node.kind, node = node, seen = now, swept = sweep.number }
    drawn.count = nil
end

-- Whether a point of the plane lies in what the sweep covered around pu, pv (half: its half side in yards).
local function Covered(entry, pu, pv, half, round)
    local du, dv = entry.u - pu, entry.v - pv
    if round then return du * du + dv * dv < half * half end
    return math.abs(du) < half and math.abs(dv) < half
end

-- A sweep done: of its kind, what it covered and did not find is gone; the rest, of either kind, once it is too
-- old or too far (what it found now is neither).
local function Settle(plane, pu, pv, scale)
    local now, half = GetTime(), (Minimap():GetWidth() / 2) / scale
    for index = #found, 1, -1 do
        local entry = found[index]
        if entry.plane ~= plane then
            Remove(index)
        elseif entry.kind == sweep.kind and entry.swept ~= sweep.number
            and Covered(entry, pu, pv, half * 0.9, sweep.round) then
            Remove(index)
        elseif now - entry.seen > Found.KEEP or not Covered(entry, pu, pv, half * Found.FAR, true) then
            Remove(index)
        end
    end
end

-------------------------------------------------------------------------------
--  The sweep
-------------------------------------------------------------------------------
-- A new sweep's points over a minimap of that half side: rows a step's sqrt(3)/2 apart, every other one
-- shifted by half a step; within the circle where the minimap is round.
local function Begin(kind, plane, half, round)
    sweeps = sweeps + 1
    local step = reach * STEP
    local points, row = {}, 0
    for y = -half, half, step * math.sqrt(3) / 2 do
        local shift = row % 2 == 1 and step / 2 or 0
        for x = -half + shift, half, step do
            if not round or x * x + y * y <= half * half then
                points[#points + 1] = x
                points[#points + 1] = y
            end
        end
        row = row + 1
    end
    sweep = { points = points, at = 1, kind = kind, plane = plane, round = round, number = sweeps }
end

-- Whether a point is inside a dot this sweep found already (at the player's place now).
local function Known(x, y, pu, pv, scale, facing)
    local near = reach * reach
    for _, entry in ipairs(found) do
        if entry.swept == sweep.number then
            local ex, ey = ToMinimap(entry.u, entry.v, pu, pv, scale, facing)
            if (ex - x) ^ 2 + (ey - y) ^ 2 < near then return true end
        end
    end
    return false
end

-- One frame of the sweep: up to Found.ASKS asks, a dot found narrowed at once.
local function Sweep(minimap, plane, pu, pv, scale, facing)
    cx, cy = minimap:GetCenter()
    pixels = minimap:GetEffectiveScale()
    if not cx then return end
    minimap:SetUsingSoftCursor(true)
    local points, asks = sweep.points, 0
    while asks < Found.ASKS and sweep.at < #points do
        local x, y = points[sweep.at], points[sweep.at + 1]
        sweep.at = sweep.at + 2
        if not Known(x, y, pu, pv, scale, facing) then
            local node = Ask(minimap, x, y)
            asks = asks + 1
            if node then
                local mx, my, more = Middle(minimap, node, x, y)
                asks = asks + more
                local u, v = ToPlane(mx, my, pu, pv, scale, facing)
                Note(node, u, v, plane, reach * 1.5 / scale)
            end
        end
    end
    minimap:SetUsingSoftCursor(false)
    if sweep.at >= #points then
        Settle(plane, pu, pv, scale)
        sweep = nil
        nextSweep = GetTime() + Found.REST
    end
end

-- Whether a sweep may go on or begin now, and for which kind: its finder on and its kind shown, out of a
-- fight, the mouse elsewhere.
local function SweepKind(minimap)
    if InCombatLockdown() or minimap:IsMouseOver() then return nil end
    local kind = Nodes.Active()
    if kind and Shown(kind) then return kind end
    return nil
end

-------------------------------------------------------------------------------
--  The pictures
-------------------------------------------------------------------------------
-- Where a found one is on its zone's map (0 to 1), for the game's map pin; nil where the game knows no zone there.
local function OnMap(entry)
    local zone = Coords.ZoneAt(entry.plane, entry.u, entry.v)
    local box = zone and Coords.Box(zone)
    if not box then return nil end
    local x, y = Coords.ToMap(box, entry.u, entry.v)
    return zone, x, y
end

-- A click on a picture: a ping there, at once (the game takes one only in the click). A double click: the game's map
-- pin where it is too (PinView.Drop says so where the game takes none); the game's button tells the second click as
-- one of its own, after the first's OnClick.
local function Clicked(button)
    local entry = button.entry
    if entry then ns.Ping.Send(entry.plane, entry.u, entry.v) end
end

local function DoubleClicked(button)
    local entry = button.entry
    if not entry then return end
    local map, x, y = OnMap(entry)
    ns.PinView.Drop({ map = map, x = x, y = y })
end

-- Its tooltip: the herb's or ore's name, grey while your skill is too low for it (as its picture is).
local function Tip(button)
    local entry = button.entry
    if not entry then return end
    local low = Nodes.TooHard(entry.node)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(entry.node.name or "", low and 0.6 or 1, low and 0.6 or 1, low and 0.6 or 1)
    GameTooltip:Show()
end

-- The ring round a picture, its hole side wide: the picture Found.FILL times that, its edge under the leather; the far
-- sparkles lay theirs so too.
function Found.Ring(ring, icon, side)
    icon:SetSize(side * Found.FILL, side * Found.FILL)
    local whole = side / (Found.HOLE * 2)
    ring:SetSize(whole, whole)
    ring:ClearAllPoints()
    ring:SetPoint("CENTER", icon, "CENTER")
end

-- An item's picture, round, cut inside its own frame (Found.Ring makes it wider than the hole besides).
function Found.Round(icon, mask)
    icon:SetTexCoord(Found.TRIM, 1 - Found.TRIM, Found.TRIM, 1 - Found.TRIM)
    mask:SetTexture(ROUND, SHAPE[1], SHAPE[2])
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
end

local function Picture(index)
    local picture = pictures[index]
    if picture then return picture end
    local icon = overlay:CreateTexture(nil, "ARTWORK")
    local mask = overlay:CreateMaskTexture()
    Found.Round(icon, mask)
    local ring = overlay:CreateTexture(nil, "OVERLAY")
    ring:SetTexture(Found.RING)
    local button = CreateFrame("Button", nil, overlay)
    button:SetAllPoints(icon)
    button:SetScript("OnClick", ns.Guard(Clicked))
    button:SetScript("OnDoubleClick", ns.Guard(DoubleClicked))
    button:SetScript("OnEnter", ns.Guard(Tip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    picture = { icon = icon, mask = mask, ring = ring, button = button }
    pictures[index] = picture
    return picture
end

local function Hide(picture)
    picture.icon:Hide()
    picture.ring:Hide()
    picture.button:Hide()
    picture.button.entry = nil
end

local function Draw(plane, pu, pv, scale, facing)
    local half, round, shown = Minimap():GetWidth() / 2, Round(), 0
    for _, entry in ipairs(found) do
        if shown >= Found.MOST then break end
        local file = entry.picture or Nodes.Picture(entry.node)
        entry.picture = file
        if entry.plane == plane and file and Shown(entry.kind) then
            local x, y = ToMinimap(entry.u, entry.v, pu, pv, scale, facing)
            local kind = Nodes.FOUND[entry.kind]
            local side = ns.Pins.SIZE[kind] * ns.PinScale(kind)
            local edge = half - side / 2
            if (round and x * x + y * y <= edge * edge) or (not round and math.abs(x) <= edge and math.abs(y) <= edge) then
                shown = shown + 1
                local picture = Picture(shown)
                local icon, ring = picture.icon, picture.ring
                icon:SetTexture(file)
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", overlay, "CENTER", x, y)
                icon:SetDesaturated(Nodes.TooHard(entry.node))
                Found.Ring(ring, icon, side)
                icon:Show()
                ring:Show()
                picture.button.entry = entry
                picture.button:Show()
            end
        end
    end
    for index = shown + 1, #pictures do Hide(pictures[index]) end
end

-------------------------------------------------------------------------------
--  Each frame
-------------------------------------------------------------------------------
local function Update()
    local minimap = Minimap()
    local plane, pu, pv = Coords.Player()
    local scale = pu and Scale(minimap)
    if not scale then
        for _, picture in ipairs(pictures) do Hide(picture) end
        drawn.count = nil
        return
    end
    local facing = Turned() and Core.Plain(Core.Ask(GetPlayerFacing)) or nil
    if sweep and (sweep.plane ~= plane or sweep.kind ~= SweepKind(minimap)) then sweep = nil end
    -- (a level the game's minimap was given since, Hybrid.lua: ours over it again)
    if overlay:GetFrameLevel() <= minimap:GetFrameLevel() then overlay:SetFrameLevel(minimap:GetFrameLevel() + 2) end
    if not sweep and GetTime() >= nextSweep then
        local kind = SweepKind(minimap)
        -- None now (no finder on, a fight, the mouse on the minimap): looked at again after a rest, not each frame.
        if kind then Begin(kind, plane, Minimap():GetWidth() / 2, Round()) else nextSweep = GetTime() + Found.REST end
    end
    if sweep then Sweep(minimap, plane, pu, pv, scale, facing) end
    if drawn.count == #found and drawn.plane == plane and drawn.u == pu and drawn.v == pv and drawn.scale == scale
        and drawn.facing == facing then return end
    drawn.count, drawn.plane, drawn.u, drawn.v, drawn.scale, drawn.facing = #found, plane, pu, pv, scale, facing
    Draw(plane, pu, pv, scale, facing)
end

-- You looted a node: the found one nearest you (within Found.LOOTED yards) is gathered.
local function Looted()
    local source = Core.Plain(Core.Ask(GetLootSourceInfo, 1))
    if type(source) ~= "string" or not source:find("^GameObject%-") then return end
    local plane, pu, pv = Coords.Player()
    if not pu then return end
    local best, nearest = nil, Found.LOOTED * Found.LOOTED
    for index, entry in ipairs(found) do
        local distance = (entry.u - pu) ^ 2 + (entry.v - pv) ^ 2
        if entry.plane == plane and distance < nearest then best, nearest = index, distance end
    end
    if best then Remove(best) end
end

-- The found ones, read only (each { u, v, plane, kind, node, picture, ... }): for the far sparkles (Glints.lua).
function Found.Each()
    return found
end

-- Shown while the module is on and the filter shows either kind; it runs only while the game's minimap shows.
function Found.Update()
    if not overlay then return end
    local wanted = not ns.off and (Shown("herb") or Shown("ore"))
    overlay:SetShown(wanted)
    if not wanted then sweep = nil end
    drawn.count = nil
end

function Found.Start()
    local minimap = rawget(_G, "Minimap")
    if overlay or not minimap or not minimap.UpdateMouseoverAtPoint or not minimap.SetUsingSoftCursor
        or not (C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover) then return end
    overlay = CreateFrame("Frame", nil, minimap)
    overlay:SetAllPoints(minimap)
    overlay:SetFrameLevel(minimap:GetFrameLevel() + 2)
    overlay:SetScript("OnUpdate", ns.Guard(Update))
    ns.On("LOOT_READY", Looted)
    ns.On("PLAYER_ENTERING_WORLD", function()
        wipe(found)
        sweep = nil
        drawn.count = nil
    end)
    Found.Update()
end

-- The module stood down: nothing more drawn, the minimap's soft cursor as the game had it.
function Found.Hide()
    if not overlay then return end
    overlay:Hide()
    Minimap():SetUsingSoftCursor(false)
end
