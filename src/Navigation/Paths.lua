local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Paths
--  The ways of the flight point or dock under the mouse, drawn over the map while
--  the mouse is on its pin (Saneroki, 2026-11-10): at a flight point every flight
--  of your side that leaves it, white as a flight's line (Route.lua), fainter to a
--  flight point you have not found; at a boat's or a zeppelin's dock its whole way
--  round, light blue, and the tram's run from station to station. The ways are the
--  game's own (Core's set Travel, from its TaxiPath tables), on a layer of the
--  canvas between the golden line and the pins (Canvas.LEVELS), in both views.
--  At a flight master (Taxi.lua) a flight point's pin draws the way there from
--  where you stand instead, hop by hop as the master flies it.
--  A click on one of those pins on the full map keeps its ways drawn (active)
--  after the mouse has left it, its pin glowing, as many as are clicked; a second
--  click lets go of them, and all go when the full screen closes (Saneroki,
--  2026-11-11).
--
--      Paths.Show(pin)    the pin's ways under the mouse, where it has any (none: as Hide)
--      Paths.Hide()       none under the mouse (the active ones stay)
--      Paths.Toggle(pin)  a click: its ways kept drawn, or no more; false where it has none
--      Paths.Active(pin)  whether its ways are kept drawn
--      Paths.Reset()      none kept (the full screen closed)
--
--  Each way is a run of the game's Line widgets from a pool, straight from point
--  to point (the game's paths are fine enough): a dark edge, over it the golden
--  line's art in the way's colour; only the parts in view, cut at the canvas'
--  edge (Canvas.edge: the game does not cut a line there; Fit).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Paths = {}
ns.Paths = Paths

Paths.THICK = 4    -- the line's thickness in units (at the route's size in the pin filter); its edge a little thicker
Paths.FAINT = 0.45 -- a flight to a flight point you have not found: so opaque
Paths.ALPHA = 0.9  -- every other way: so opaque

local Travel = Core.Data.Set("Travel")
local SHIPS = { boat = true, zeppelin = true }

local layer, holder
local ways         -- the ways under the mouse: { { kind, faint, points = { { map, u, v, jump }, ... } }, ... }, or nil
local owner        -- the pin they are of
local active = {}  -- [a pin's thing: Key] = its ways, kept drawn after a click (Toggle)
local lines, used = {}, 0 -- the pool: { edge, fill } each
local parts, count = {}, 0 -- the pieces laid out: { x1, y1, x2, y2, length, along, entry, from, to }

function Paths.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    return layer
end

local function Next()
    used = used + 1
    local entry = lines[used]
    if entry then return entry end
    entry = { edge = layer:CreateLine(nil, "ARTWORK", nil, 0), fill = layer:CreateLine(nil, "ARTWORK", nil, 1) }
    entry.edge:SetTexture(ns.Route.EDGE, "REPEAT", "CLAMP")
    entry.fill:SetTexture(ns.Route.FILL, "REPEAT", "CLAMP")
    entry.edge:SetVertexColor(0, 0, 0, 0.8)
    lines[used] = entry
    return entry
end

local function Hide(entry)
    entry.edge:Hide()
    entry.fill:Hide()
end

-------------------------------------------------------------------------------
--  The ways of a pin
-------------------------------------------------------------------------------
-- A way's points from the game's path (the world's yards: x to the north, y to the west; the plane: u = -y, v = x),
-- each on map (a flight's: its start's plane), or on the plane of the world's map its point lies on (a ship's: map
-- given at its first point and where it comes onto another); jump: it leaps to that point. A ship's way runs round:
-- after its last point again its first.
local function FromPath(path, map, round)
    local points, world = {}, nil
    for _, point in ipairs(path) do
        world = point.map or world
        local plane = map or (world and ns.Planner.Plane(world))
        if plane and point.x and point.y then
            points[#points + 1] = { map = plane, u = -point.y, v = point.x, jump = point.jump or nil }
        end
    end
    if round and #points > 2 then
        local first = points[1]
        points[#points + 1] = { map = first.map, u = first.u, v = first.v, jump = first.jump }
    end
    return points
end
Paths.FromPath = FromPath -- (Taxi.lua: a hop's way at a flight master)

-- Every flight of the player's side (or of both) from a flight point, in its plane.
local function Flights(node, map)
    local found, plane = {}, Coords.PlaneOf(map)
    if not node or not plane then return found end
    local side = Core.Plain(UnitFactionGroup("player"))
    side = type(side) == "string" and side:lower() or nil
    for _, key in ipairs(Travel:Keys("byFromNode", node)) do
        local flight = Travel:Get(key)
        local path = flight and flight.kind == "flight" and (not flight.side or flight.side == side) and flight.path
        if type(path) == "table" and #path >= 2 then
            found[#found + 1] = { kind = "flight", faint = not ns.Planner.Knows(flight.toNode), points = FromPath(path, plane) }
        end
    end
    return found
end

-- A boat's or zeppelin's whole way round; the tram's two stations (its tunnel's map has no plane), straight.
local function Ship(key)
    local way = key and Travel:Get(key)
    if not way then return {} end
    if SHIPS[way.kind] and type(way.path) == "table" then
        return { { kind = way.kind, points = FromPath(way.path, nil, true) } }
    end
    if way.kind == "tram" and type(way.docks) == "table" and #way.docks == 2 then
        local points = {}
        for _, dock in ipairs(way.docks) do
            local plane = Coords.PlaneOf(dock.map)
            local u, v
            if plane and dock.x and dock.y then u, v = Coords.MapToPlane(dock.map, dock.x / 100, dock.y / 100, plane) end
            if not u then return {} end
            points[#points + 1] = { map = plane, u = u, v = v }
        end
        return { { kind = "tram", points = points } }
    end
    return {}
end

-------------------------------------------------------------------------------
--  Drawn
-------------------------------------------------------------------------------
-- The share of a piece between lo and hi along one axis (its start a, its way d there), within from..to.
local function Between(a, d, lo, hi, from, to)
    if d == 0 then
        if a < lo or a > hi then return 1, 0 end
        return from, to
    end
    local enter, leave = (lo - a) / d, (hi - a) / d
    if enter > leave then enter, leave = leave, enter end
    return math.max(from, enter), math.min(to, leave)
end

-- A piece's lines cut at the canvas' rectangle (edge, in the holder's units; the lines' own thickness inside it), or
-- out of sight where none of it is inside.
local function Refit(part, edge, thick)
    local inset = thick / 2
    local from, to = Between(part.x1, part.x2 - part.x1, edge.left + inset, edge.right - inset, 0, 1)
    from, to = Between(part.y1, part.y2 - part.y1, edge.bottom + inset, edge.top - inset, from, to)
    if to <= from then from, to = 0, 0 end
    if from == part.from and to == part.to then return end
    part.from, part.to = from, to
    local entry = part.entry
    if to <= from then return Hide(entry) end
    local dx, dy = part.x2 - part.x1, part.y2 - part.y1
    local left = (part.along + from * part.length) / ns.Route.PERIOD
    local right = (part.along + to * part.length) / ns.Route.PERIOD
    for _, line in pairs(entry) do
        line:SetStartPoint("CENTER", holder, part.x1 + dx * from, part.y1 + dy * from)
        line:SetEndPoint("CENTER", holder, part.x1 + dx * to, part.y1 + dy * to)
        line:SetTexCoord(left, right, 0, 1)
        line:Show()
    end
end

local thickness = { edge = Paths.THICK + 3, fill = Paths.THICK }

-- Every piece kept inside the canvas' rectangle as it is now (Canvas.edge).
function Paths.Fit(edge)
    for index = 1, count do Refit(parts[index], edge, thickness.edge) end
end

local Key -- (below)

-- The ways of one list laid out: the pieces near the view (its rectangle with its margin), each way's points on planes
-- linked to the view's; a leap no line.
local function Lay(list, view, left, right, bottom, top)
    for _, way in ipairs(list) do
        local colour = ns.Route.COLOURS[way.kind] or ns.Route.COLOURS.flight
        local alpha = way.faint and Paths.FAINT or Paths.ALPHA
        local px, py, along = nil, nil, 0
        for _, point in ipairs(way.points) do
            local link = Coords.Link(point.map, view.map)
            local x, y
            if link then
                x = (link.du + link.su * point.u - view.u) * view.k
                y = (link.dv + link.sv * point.v - view.v) * view.k
            end
            if x and px and not point.jump then
                local length = math.sqrt((x - px) ^ 2 + (y - py) ^ 2)
                if length >= 1 and math.max(x, px) >= left and math.min(x, px) <= right
                    and math.max(y, py) >= bottom and math.min(y, py) <= top then
                    local entry = Next()
                    entry.fill:SetVertexColor(colour[1], colour[2], colour[3], alpha)
                    entry.edge:SetAlpha(alpha)
                    entry.edge:SetThickness(thickness.edge)
                    entry.fill:SetThickness(thickness.fill)
                    count = count + 1
                    local part = parts[count] or {}
                    parts[count] = part
                    part.x1, part.y1, part.x2, part.y2, part.length, part.along = px, py, x, y, length, along
                    part.entry, part.from, part.to = entry, nil, nil
                end
                along = along + length
            end
            px, py = x, y
        end
    end
end

-- Laid out for the view as the canvas laid it out: the active ways, and those of the pin under the mouse.
function Paths.Place(view)
    used, count = 0, 0
    if (ways or next(active)) and view and view.map then
        local scale = ns.PinScale("route")
        thickness.edge, thickness.fill = (Paths.THICK + 3) * scale, Paths.THICK * scale
        local left, right = (view.left - view.u) * view.k, (view.right - view.u) * view.k
        local bottom, top = (view.bottom - view.v) * view.k, (view.top - view.v) * view.k
        for _, list in pairs(active) do Lay(list, view, left, right, bottom, top) end
        -- (the pin under the mouse an active one: drawn once)
        if ways and not active[Key(owner)] then Lay(ways, view, left, right, bottom, top) end
    end
    for index = used + 1, #lines do Hide(lines[index]) end
    Paths.Fit(ns.Canvas.edge)
end

local function Redraw()
    if ns.Canvas.Laid() then Paths.Place(ns.Canvas.view) else Paths.Clear() end
end

-- A pin's ways: a flight point's flights (at a flight master the way there, hop by hop: Taxi.lua), a dock's ship's way
-- round; nil for any other pin.
local function Of(pin)
    if not pin or pin.gathered then return nil end
    local found
    if pin.kind == "flight" then
        found = ns.Taxi.Ways(pin.taxi) or Flights(pin.id, pin.map)
    elseif pin.way and pin.dock then
        found = Ship(pin.way)
    end
    return found and #found > 0 and found or nil
end

-- What a pin's ways are kept by: its flight point, or its ship (its docks on two maps are one), else the pin.
function Key(pin)
    if not pin then return nil end
    if pin.kind == "flight" and pin.id then return "flight:" .. tostring(pin.id) end
    if pin.way then return "way:" .. tostring(pin.way) end
    return pin.key
end

function Paths.Show(pin)
    if not layer then return end
    if pin and pin == owner and ways then return end -- drawn already (a dock's tooltip is drawn again each second)
    local found = Of(pin)
    if not found then return Paths.Hide() end
    ways, owner = found, pin
    Redraw()
end

function Paths.Hide()
    if not ways then return end
    ways, owner = nil, nil
    Redraw()
end

function Paths.Active(pin)
    local key = Key(pin)
    return key ~= nil and active[key] ~= nil
end

function Paths.Toggle(pin)
    local key = layer and Key(pin)
    if not key then return false end
    if active[key] then
        active[key] = nil
    else
        local found = Of(pin)
        if not found then return false end
        active[key] = found
    end
    Redraw()
    ns.Safe("pins", ns.PinView.Relook) -- its pin's glow
    return true
end

function Paths.Reset()
    local had = next(active) ~= nil
    wipe(active)
    ways, owner = nil, nil
    Paths.Clear()
    if had then ns.Safe("pins", ns.PinView.Relook) end
end

-- Out of sight (the window hidden, the pins laid out anew): the lines go.
function Paths.Clear()
    for _, entry in ipairs(lines) do Hide(entry) end
    used, count = 0, 0
end
