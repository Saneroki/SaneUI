local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Navigation - Paths
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
--
--  The sea lanes (Saneroki, 2026-11-11): a boat sails a little way out of its
--  dock, then leaps (a loading screen) to the sea off the next; the game's path
--  has nothing between. There each boat's way follows a lane of ours (LANES)
--  through the open sea alone, round the Maelstrom, as a smooth curve joined to
--  the game's path where the boat leaves and where it comes in, so the whole
--  round shows, every port of a loop. A zeppelin flies over the land: the two
--  whose straight line crossed the Maelstrom have a lane bent round it, the
--  others none. A way with no lane is drawn as before.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Paths = {}
ns.Paths = Paths

Paths.THICK = 4    -- the line's thickness in units (at the route's size in the pin filter); its edge a little thicker
Paths.FAINT = 0.45 -- a flight to a flight point you have not found: so opaque
Paths.ALPHA = 0.9  -- every other way: so opaque
Paths.LEAP = 1500  -- yards: a ship's step from its last point round to its first so long (or onto another plane) leaps
Paths.PIECES = 8   -- pieces of a lane's curve between two of its points

-- The sea lanes, by the boat's way (its key in the set Travel): one a leap, in the order the boat leaps (a way of two
-- docks: one lane, sailed there and back). Each is points on WoW: Forever's world map (0 to 1, as Coords.ToWorldMap),
-- from the sea off one dock to the sea off the other; a leap takes it from the end nearer where the boat leaves. Kept
-- clear of the coasts (the terrain's), the Maelstrom and the islands the world map paints; a zeppelin's of the
-- Maelstrom alone. Forever's alone: the world maps differ.
-- Stretches several lanes share, so ships on one sea draw one line: from Auberdine round Kalimdor's north; where the
-- ways from there part, north of the Maelstrom; from there into Menethil Harbor's bay.
local NORTH = { { 0.1627, 0.2530 }, { 0.1926, 0.2193 }, { 0.2255, 0.1916 }, { 0.2869, 0.1662 }, { 0.3643, 0.1961 },
                { 0.4391, 0.2582 } }
local PART = { 0.5190, 0.3181 }
local MENETHIL = { { 0.5938, 0.3780 }, { 0.6537, 0.4491 }, { 0.6986, 0.4596 } }

-- One lane of points and lists of points, in order.
local function Lane(...)
    local lane = {}
    for index = 1, select("#", ...) do
        local part = select(index, ...)
        if type(part[1]) == "number" then
            lane[#lane + 1] = part
        else
            for _, at in ipairs(part) do lane[#lane + 1] = at end
        end
    end
    return lane
end

local function Backwards(list)
    local found = {}
    for index = #list, 1, -1 do found[#found + 1] = list[index] end
    return found
end

Paths.LANES = Core.FOREVER and {
    -- Ratchet - Booty Bay: south-east, west of the island off Dustwallow, over the South Seas
    [241] = { { { 0.3518, 0.5913 }, { 0.3443, 0.6587 }, { 0.3618, 0.7186 }, { 0.4142, 0.7784 }, { 0.4990, 0.8196 },
                { 0.5888, 0.8346 }, { 0.6487, 0.8308 }, { 0.6737, 0.8234 } } },
    -- Menethil Harbor - Theramore: out of the bay, round the Maelstrom's north and west
    [292] = { Lane(Backwards(MENETHIL), PART, { { 0.4491, 0.3578 }, { 0.3942, 0.4192 }, { 0.3593, 0.5090 },
                                                 { 0.3443, 0.5913 } }) },
    -- Menethil Harbor, Southshore, Auberdine and round: from Southshore the outer way across the north, from Auberdine
    -- back to Menethil the inner one, so the loop shows
    [11167] = {
        { { 0.7275, 0.4192 }, { 0.7186, 0.4476 }, { 0.6961, 0.4513 }, { 0.6437, 0.4207 }, { 0.5988, 0.3458 },
          { 0.5389, 0.2784 }, { 0.4641, 0.2186 }, { 0.3892, 0.1751 }, { 0.3194, 0.1497 }, { 0.2570, 0.1497 },
          { 0.2196, 0.1841 }, { 0.1946, 0.2208 }, { 0.1647, 0.2545 } },
        Lane(NORTH, PART, MENETHIL, { 0.7211, 0.4491 }),
    },
    -- Steamwheedle Port - Riverglades: over the South Seas, round the Eastern Kingdoms' south, up the east coast
    [11391] = { { { 0.3518, 0.7747 }, { 0.4291, 0.8234 }, { 0.5190, 0.8683 }, { 0.6238, 0.8817 }, { 0.7186, 0.8683 },
                  { 0.7834, 0.8308 }, { 0.8283, 0.7784 }, { 0.8683, 0.7111 }, { 0.8957, 0.6437 } } },
    -- Auberdine - Stormwind Harbor: round Kalimdor's north, past the Maelstrom's north-east, down the coast
    [11616] = { Lane(NORTH, PART, { { 0.5838, 0.3892 }, { 0.6312, 0.4716 }, { 0.6562, 0.5614 }, { 0.6662, 0.6250 } }) },
    -- The zeppelin Orgrimmar - Grom'gol: under the Maelstrom
    [285] = { { { 0.3792, 0.5352 }, { 0.4466, 0.6452 }, { 0.5289, 0.6774 }, { 0.6238, 0.7186 } } },
    -- The zeppelin Orgrimmar - the Undercity: over the Maelstrom
    [302] = { { { 0.4092, 0.3518 }, { 0.5040, 0.2994 }, { 0.5988, 0.2507 } } },
} or {}

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
-- A point of a way in another plane's yards, through the world map; nil where the two are not linked.
local function In(point, plane)
    local link = point and Coords.Link(point.map, plane)
    if link then return link.du + link.su * point.u, link.dv + link.sv * point.v end
end

-- A direction (du, dv) made so long; the fallback where it has none.
local function Stretched(du, dv, length, fallback)
    local size = math.sqrt(du * du + dv * dv)
    if size < 1e-6 then return fallback end
    return { du / size * length, dv / size * length }
end

-- A leap's curve along its lane, in the plane of a (where the boat leaves): from a to b through the lane's points,
-- leaving a on the heading it came from before, coming into b on the heading it sails on to after (either may be nil:
-- straight at the next point). A Hermite curve through them all, Paths.PIECES pieces between two; returns the pieces'
-- ends but b's, in order, or nil where the planes are not linked.
local function Sail(a, b, before, after, lane)
    local plane = a.map
    local bu, bv = In(b, plane)
    if not bu then return nil end
    local through = {}
    for index, at in ipairs(lane) do
        local u, v = Coords.FromWorldMap(plane, at[1], at[2])
        if not u then return nil end
        through[index] = { u, v }
    end
    local function Gap(p, u, v) return math.sqrt((p[1] - u) ^ 2 + (p[2] - v) ^ 2) end
    local first, last = through[1], through[#through]
    local backwards = Gap(last, a.u, a.v) + Gap(first, bu, bv) < Gap(first, a.u, a.v) + Gap(last, bu, bv)
    local spots = { { a.u, a.v } }
    for index = 1, #through do spots[#spots + 1] = through[backwards and #through + 1 - index or index] end
    spots[#spots + 1] = { bu, bv }
    local n = #spots
    local tangents = {}
    for k = 2, n - 1 do
        tangents[k] = { (spots[k + 1][1] - spots[k - 1][1]) / 2, (spots[k + 1][2] - spots[k - 1][2]) / 2 }
    end
    local chord = { spots[2][1] - a.u, spots[2][2] - a.v }
    local pu, pv = In(before, plane)
    tangents[1] = pu and Stretched(a.u - pu, a.v - pv, Gap(spots[2], a.u, a.v), chord) or chord
    chord = { bu - spots[n - 1][1], bv - spots[n - 1][2] }
    local nu, nv = In(after, plane)
    tangents[n] = nu and Stretched(nu - bu, nv - bv, Gap(spots[n - 1], bu, bv), chord) or chord
    local curve = {}
    for k = 1, n - 1 do
        local p0, p1, m0, m1 = spots[k], spots[k + 1], tangents[k], tangents[k + 1]
        for step = 1, k == n - 1 and Paths.PIECES - 1 or Paths.PIECES do -- (a is there already, b comes after)
            local t = step / Paths.PIECES
            local t2, t3 = t * t, t * t * t
            local h00, h10, h01, h11 = 2 * t3 - 3 * t2 + 1, t3 - 2 * t2 + t, 3 * t2 - 2 * t3, t3 - t2
            curve[#curve + 1] = { map = plane, u = h00 * p0[1] + h10 * m0[1] + h01 * p1[1] + h11 * m1[1],
                                  v = h00 * p0[2] + h10 * m0[2] + h01 * p1[2] + h11 * m1[2] }
        end
    end
    return curve
end

-- A boat's way round with its leaps sailed along its lanes (lanes: Paths.LANES' list of the way); a leap whose
-- lane cannot be laid stays a leap.
local function Sailed(points, lanes)
    local found, leaps = {}, 0
    for index, point in ipairs(points) do
        if point.jump and index > 1 then
            leaps = leaps + 1
            local lane = lanes[leaps] or lanes[#lanes]
            local curve = lane and Sail(points[index - 1], point, points[index - 2], points[index + 1] or points[2], lane)
            if curve then
                for _, piece in ipairs(curve) do found[#found + 1] = piece end
                point.jump = nil
            end
        end
        found[#found + 1] = point
    end
    return found
end

-- lanes: a boat's lanes (Paths.LANES), its leaps drawn along them; its step from its last point round to its first
-- then a leap too where it is one (onto another plane, or longer than Paths.LEAP).
local function FromPath(path, map, round, lanes)
    local points, world = {}, nil
    for _, point in ipairs(path) do
        world = point.map or world
        local plane = map or (world and ns.Planner.Plane(world))
        if plane and point.x and point.y then
            points[#points + 1] = { map = plane, u = -point.y, v = point.x, jump = point.jump or nil }
        end
    end
    if round and #points > 2 then
        local first, last = points[1], points[#points]
        local back = { map = first.map, u = first.u, v = first.v, jump = first.jump }
        if lanes and (first.map ~= last.map or (first.u - last.u) ^ 2 + (first.v - last.v) ^ 2 > Paths.LEAP ^ 2) then
            back.jump = true
        end
        points[#points + 1] = back
    end
    if lanes and #lanes > 0 then points = Sailed(points, lanes) end
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

-- A boat's or zeppelin's whole way round, a boat's leaps along its lanes; the tram's two stations (its tunnel's map has
-- no plane), straight.
local function Ship(key)
    local way = key and Travel:Get(key)
    if not way then return {} end
    if SHIPS[way.kind] and type(way.path) == "table" then
        return { { kind = way.kind, points = FromPath(way.path, nil, true, Paths.LANES[key]) } }
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
        found = ns.Taxi.Ways(pin.taxi, pin.map) or Flights(pin.id, pin.map)
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
