local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Route
--  The way to the map pin drawn on the map: a thin golden line, pulsing towards
--  the pin, on a layer of the canvas under the pins (Canvas.LEVELS), in both views.
--  The way itself is the planner's (Planner.lua); this draws what it gives:
--
--      Route.Show(way)   way = { legs = { { kind = "walk" | "flight" | "boat" | "zeppelin" | ...,
--                                           points = { { map = continent, u, v }, ... } }, ... }, at, cut }
--      Route.Show(nil)   no way: the line goes
--      Route.Cut(way)    the player moved along it: drawn from them on
--
--  Always from the player: the way's cut (Planner.lua) says where along it the
--  player is, the leg, the part and the share of it; the parts before it are not
--  drawn, the one it is on only from there, and a line of its own (the head) runs
--  from the player's arrow to that point. The legs after the next are fainter.
--
--  Each leg's points are joined by the game's Line widgets from a pool, only the
--  parts in view, cut at the canvas' edge (Canvas.edge: the game does not cut a
--  line there; Fit): under them a dark edge, over them the game's dependency bar art
--  tinted gold, and over that its glint, moved along the line by the engine (a
--  TextureCoordTranslation animation from Route.xml, as the game's talent lines
--  move theirs), so nothing of ours runs every frame for the pulse. A walk and a
--  lift are golden; a flight white; a boat's, a zeppelin's and the tram's way light
--  blue; a portal's violet; the hearthstone's and the teleports' pale blue,
--  straight to where they bring one (the art is grey: each shows its colour as it is).
--
--  A corner of a leg that turns more than Route.BEND degrees is drawn as a curve:
--  from a point before it to one after it, the corner its middle point (a curve of
--  the corner and its two neighbours, so short parts one after the other make one
--  smooth line), in pieces of the game's lines. It cuts the corner no deeper than
--  Route.STRAY units, at every zoom, and never past the middle of either part. The
--  art runs on from piece to piece, and every glint is started at the pulse's
--  moment (Route.PULSE), so the pieces pulse as one line.
-------------------------------------------------------------------------------
local Coords = ns.Coords
local Route = {}
ns.Route = Route

Route.EDGE = "Interface\\Artifacts\\_Artifacts-DependencyBar-BG"
Route.FILL = "Interface\\Artifacts\\_Artifacts-DependencyBar-Fill"
Route.GLINT = "Interface\\Artifacts\\_Artifacts-DependencyBar-FillScroll1"
Route.THICK = 6     -- the line's thickness in units; its edge a little thicker
Route.PERIOD = 48   -- units along the line one repeat of the art takes
Route.BEND = 10     -- degrees: a corner turning more is a curve, in pieces turning about so much each
Route.STRAY = 6     -- units at most the curve passes inside the corner it rounds (about the line's thickness)
Route.PIECE = 2     -- units a curve's pieces are long, at least
-- The glint's pulse (Route.xml: one repeat in Route.PULSE seconds). The game makes this animation only from
-- XML; until it has read the file (a restart after it came) the glint stands still.
Route.GLINT_PULSE = "SaneUINavigationGlintTemplate"
Route.PULSE = 1.2
Route.COLOURS = {
    walk = { 1, 0.78, 0.25 }, flight = { 1, 1, 1 },
    boat = { 0.4, 0.75, 1 }, zeppelin = { 0.4, 0.75, 1 }, tram = { 0.4, 0.75, 1 },
    lift = { 1, 0.78, 0.25 }, portal = { 0.7, 0.5, 1 }, hearth = { 0.6, 0.8, 1 }, teleport = { 0.6, 0.8, 1 },
}

-- The lines' thickness, at the size the pin filter's slider for the route asks (set at each layout, Place).
local THICKNESS = { edge = Route.THICK + 3, fill = Route.THICK, glint = Route.THICK }

local layer, holder
local way
local lines, used = {}, 0 -- the pool: { edge, fill, glint, group } each
-- The pieces near the view, in the holder's units, in the way's order: { x1, y1, x2, y2, length, entry (its
-- lines), leg, index (its leg and the way's part it stands for: from point index to the next), t0, t1 (the share of
-- that part it stands for), along (units along its leg where it starts: its art's place), from, to (the share of it
-- drawn, as last placed) }
local parts, count = {}, 0
local first = 1    -- the first part the player has not passed
local on           -- the piece the player is on (where along the way they are), as last fitted; nil: none in view
local head = {}    -- the line from the player to where along the way they are: a part of its own (entry nil: none)
local laid         -- the view the parts were laid out for (the canvas'), and the leg the player was on then
local laidAt
local pulse -- whether the game has the pulse's template, asked once

local sqrt, min, max, floor, ceil = math.sqrt, math.min, math.max, math.floor, math.ceil

function Route.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    return layer
end

local function Line(file, sublevel, add)
    local line = layer:CreateLine(nil, "ARTWORK", nil, sublevel)
    line:SetTexture(file, "REPEAT", "CLAMP")
    if add then line:SetBlendMode("ADD") end
    return line
end

-- The pool's next line, made when there is none.
local function Next()
    used = used + 1
    local entry = lines[used]
    if entry then return entry end
    entry = { edge = Line(Route.EDGE, 0), fill = Line(Route.FILL, 1), glint = Line(Route.GLINT, 2, true) }
    entry.edge:SetVertexColor(0, 0, 0, 0.8)
    if pulse == nil then
        pulse = C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(Route.GLINT_PULSE) ~= nil or false
    end
    entry.group = pulse and entry.glint:CreateAnimationGroup(nil, Route.GLINT_PULSE) or nil
    lines[used] = entry
    return entry
end

local function Hide(entry)
    entry.edge:Hide()
    entry.fill:Hide()
    entry.glint:Hide()
    if entry.group then entry.group:Stop() end
end

local function Colour(entry, colour, faint)
    entry.fill:SetVertexColor(colour[1], colour[2], colour[3], faint and 0.5 or 0.9)
    entry.glint:SetVertexColor(colour[1], colour[2], colour[3], faint and 0.4 or 1)
end

-- One piece, x, y units from the holder's middle, length units long, in a leg's colour: its lines from the pool,
-- placed by Fit. leg, index, t0, t1: where it lies on the way; along: where along its leg it starts.
local function Segment(x1, y1, x2, y2, length, colour, faint, leg, index, t0, t1, along)
    if length < 1 then return end
    local entry = Next()
    Colour(entry, colour, faint)
    count = count + 1
    local part = parts[count] or {}
    parts[count] = part
    part.x1, part.y1, part.x2, part.y2, part.length, part.entry = x1, y1, x2, y2, length, entry
    part.leg, part.index, part.t0, part.t1, part.along, part.from, part.to = leg, index, t0, t1, along, nil, nil
end

-- A piece's lines from the share from to the share to of it (the art stays where it is on the way when the
-- piece is cut, and runs on from the piece before), or out of sight when nothing of it is drawn.
local function Draw(part)
    local entry = part.entry
    if part.to <= part.from then return Hide(entry) end
    local dx, dy = part.x2 - part.x1, part.y2 - part.y1
    local x1, y1 = part.x1 + dx * part.from, part.y1 + dy * part.from
    local x2, y2 = part.x1 + dx * part.to, part.y1 + dy * part.to
    local along = part.along or 0
    local left, right = (along + part.from * part.length) / Route.PERIOD, (along + part.to * part.length) / Route.PERIOD
    for name, thickness in pairs(THICKNESS) do
        local line = entry[name]
        line:SetStartPoint("CENTER", holder, x1, y1)
        line:SetEndPoint("CENTER", holder, x2, y2)
        line:SetThickness(thickness)
        line:SetTexCoord(left, right, 0, 1)
        line:Show()
    end
    -- At the pulse's moment (the time since a whole number of its repeats), so every glint moves in step.
    if entry.group and not entry.group:IsPlaying() then entry.group:Play(false, GetTime() % Route.PULSE) end
end

-- The share of a segment between lo and hi along one axis (its start a, its way d there), within from..to.
local function Between(a, d, lo, hi, from, to)
    if d == 0 then
        if a < lo or a > hi then return 1, 0 end
        return from, to
    end
    local enter, leave = (lo - a) / d, (hi - a) / d
    if enter > leave then enter, leave = leave, enter end
    return math.max(from, enter), math.min(to, leave)
end

-- Where a piece lies against the cut: -1 before it (passed), 0 the piece the player is on, 1 after it. The pieces
-- of one part of the way share it out (t0 to t1, in order), the last one up to its end.
local function Against(part, cut)
    if not cut or part.leg > cut.leg then return 1 end
    if part.leg < cut.leg then return -1 end
    if part.index ~= cut.index then return part.index > cut.index and 1 or -1 end
    if cut.t < part.t0 then return 1 end
    return (cut.t < part.t1 or part.t1 >= 1) and 0 or -1
end

-- The share of a piece the cut lies at (0 to 1).
local function Share(part, cut)
    local span = part.t1 - part.t0
    return span > 0 and max(0, min(1, (cut.t - part.t0) / span)) or 0
end

-- A piece placed anew where what of it is drawn changed: cut at the canvas' rectangle (edge, in the holder's units;
-- the lines' own thickness inside it) and, on the piece the player is on, from where they are; a piece passed, not.
local function Refit(part, edge, against)
    local inset = THICKNESS.edge / 2
    local from, to = 0, 0
    if against >= 0 then
        from, to = Between(part.x1, part.x2 - part.x1, edge.left + inset, edge.right - inset, 0, 1)
        from, to = Between(part.y1, part.y2 - part.y1, edge.bottom + inset, edge.top - inset, from, to)
        if against == 0 then from = max(from, Share(part, way.cut)) end
        if to <= from then from, to = 0, 0 end
    end
    if from ~= part.from or to ~= part.to then
        part.from, part.to = from, to
        Draw(part)
    end
end

-- A point of a plane in the holder's units as the parts were laid out; nil when the planes are not linked.
local function Spot(map, u, v)
    local link = Coords.Link(map, laid.map)
    if not link then return nil end
    return (link.du + link.su * u - laid.u) * laid.k, (link.dv + link.sv * v - laid.v) * laid.k
end

-- The head: from where the player is to where along the way that is (the cut), in the colour of the leg they are on:
-- to that place on the piece they are on (on a curve, a little off the way's corner), so it meets the line, its art
-- running on into it.
local function Head(edge)
    if not head.entry then return end
    local cut = way and way.cut
    local x1, y1, x2, y2, along
    if cut and cut.u and cut.pu then
        x1, y1 = Spot(cut.map, cut.pu, cut.pv)
        if on then
            local share = Share(on, cut)
            x2, y2 = on.x1 + (on.x2 - on.x1) * share, on.y1 + (on.y2 - on.y1) * share
            along = on.along + share * on.length
        else
            x2, y2 = Spot(cut.map, cut.u, cut.v)
        end
    end
    local length = x1 and x2 and sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) or 0
    if length < 1 then
        head.length = 0
        if head.to ~= 0 then
            head.from, head.to = 0, 0
            Hide(head.entry)
        end
        return
    end
    head.x1, head.y1, head.x2, head.y2, head.length, head.from = x1, y1, x2, y2, length, nil
    head.along = (along or length) - length
    Refit(head, edge, 1)
end

-- Every piece kept inside the canvas' rectangle as it is now (Canvas.edge, in the holder's units): only a piece whose
-- share inside changed is placed anew, so a step of following moves those at the edge alone.
function Route.Fit(edge)
    local cut = way and way.cut
    on = nil
    for index = first, count do
        local part = parts[index]
        local against = Against(part, cut)
        if against == 0 then on = part end
        Refit(part, edge, against)
    end
    if head.entry and head.length and head.length >= 1 then
        head.from = nil
        Refit(head, edge, 1)
    end
end

-- Laying a leg out (Place). A run of its points on the view's plane, in the holder's units, each with its number
-- in the leg; at each corner how far its curve reaches along the two parts (0: none), in how many pieces, and its
-- ends there (a, the end on the part before; b, on the part after). Reused.
local xs, ys, numbers, reaches, pieces, ax, ay, bx, by = {}, {}, {}, {}, {}, {}, {}, {}, {}
local box = {}      -- the view's rectangle with its margin, in the holder's units
local laying = {}   -- the leg being laid out: number, colour, faint, from (the first of its parts not passed)
local along = 0     -- units along that leg laid out so far

-- One piece of the leg's line, in the way's order: made where it is not passed and may reach into the view. index,
-- t0, t1: the way's part it stands for (from point index to the next), and the share of it.
local function Piece(x1, y1, x2, y2, index, t0, t1)
    local length = sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    local start = along
    along = along + length
    if index < laying.from or max(x1, x2) < box.left or min(x1, x2) > box.right or max(y1, y2) < box.bottom
        or min(y1, y2) > box.top then
        return
    end
    Segment(x1, y1, x2, y2, length, laying.colour, laying.faint, laying.number, index, t0, t1, start)
end

-- The curve at the run's corner j, at s (0 at its end on the part before, 1 on the part after): the corner its
-- middle point.
local function Curve(j, s)
    local r = 1 - s
    return r * r * ax[j] + 2 * s * r * xs[j] + s * s * bx[j], r * r * ay[j] + 2 * s * r * ys[j] + s * s * by[j]
end

-- Half of the curve at corner j, as pieces of the part index from t0 to t1: up to its middle (on the part before the
-- corner) or from there on (on the part after).
local function Half(j, second, index, t0, t1)
    local half = pieces[j] / 2
    local s = second and 0.5 or 0
    local x1, y1 = Curve(j, s)
    for k = 1, half do
        local x2, y2 = Curve(j, s + 0.5 * k / half)
        Piece(x1, y1, x2, y2, index, t0 + (t1 - t0) * (k - 1) / half, t0 + (t1 - t0) * k / half)
        x1, y1 = x2, y2
    end
end

-- The curve at the run's corner j: none where it turns Route.BEND degrees or less. Else it reaches as far along
-- both parts as cuts the corner stray units deep (its middle that far inside it: half its reach times the sine of
-- half the turn), at most to the middle of either part, in pieces turning about Route.BEND degrees each (an even
-- number, half on either part), none shorter than piece units.
local function Bend(j, stray, piece)
    local x1, y1, x2, y2 = xs[j] - xs[j - 1], ys[j] - ys[j - 1], xs[j + 1] - xs[j], ys[j + 1] - ys[j]
    local before, after = sqrt(x1 * x1 + y1 * y1), sqrt(x2 * x2 + y2 * y2)
    local turn = math.acos(max(-1, min(1, (x1 * x2 + y1 * y2) / (before * after))))
    local bend = math.rad(Route.BEND)
    reaches[j], pieces[j] = 0, 0
    if turn <= bend then return end
    local reach = min(before / 2, after / 2, 2 * stray / math.sin(turn / 2))
    local steps = 2 * min(ceil(turn / (2 * bend)), floor(reach / piece))
    if steps < 2 then return end
    reaches[j], pieces[j] = reach, steps
    ax[j], ay[j] = xs[j] - x1 * (reach / before), ys[j] - y1 * (reach / before)
    bx[j], by[j] = xs[j] + x2 * (reach / after), ys[j] + y2 * (reach / after)
end

-- A run of n points laid out: each part of the way from where the curve before it ends to where the one after it
-- begins, straight, and the curves' halves at its ends.
local function Run(n, stray, piece)
    reaches[1], reaches[n] = 0, 0
    for j = 2, n - 1 do Bend(j, stray, piece) end
    for j = 1, n - 1 do
        local index, length = numbers[j], sqrt((xs[j + 1] - xs[j]) ^ 2 + (ys[j + 1] - ys[j]) ^ 2)
        local t0, t1 = reaches[j] / length, 1 - reaches[j + 1] / length
        if reaches[j] > 0 then Half(j, true, index, 0, t0) end
        local x1, y1 = xs[j], ys[j]
        if reaches[j] > 0 then x1, y1 = bx[j], by[j] end
        local x2, y2 = xs[j + 1], ys[j + 1]
        if reaches[j + 1] > 0 then x2, y2 = ax[j + 1], ay[j + 1] end
        Piece(x1, y1, x2, y2, index, t0, t1)
        if reaches[j + 1] > 0 then Half(j + 1, false, index, t1, 1) end
    end
end

-- A leg's points on the view's plane, as runs (a point on a plane not linked to it ends one), each laid out; a point
-- in the place of the one before it is that one (the part from it is the later one's).
local function Lay(points, view, stray, piece)
    local n = 0
    along = 0
    for number, point in ipairs(points) do
        local link = Coords.Link(point.map, view.map)
        if link then
            local x = (link.du + link.su * point.u - view.u) * view.k
            local y = (link.dv + link.sv * point.v - view.v) * view.k
            if n > 0 and (x - xs[n]) ^ 2 + (y - ys[n]) ^ 2 < 1e-4 then
                numbers[n] = number
            else
                n = n + 1
                xs[n], ys[n], numbers[n] = x, y, number
            end
        else
            if n >= 2 then Run(n, stray, piece) end
            n = 0
        end
    end
    if n >= 2 then Run(n, stray, piece) end
end

-- Drawn for the view as the canvas laid it out: only the parts in view from where the player is on, cut at the
-- canvas' edge; the head from the player to them.
function Route.Place(view)
    used, count, first = 0, 0, 1
    head.entry, head.length, head.from, head.to = nil, 0, nil, nil
    laid, laidAt = view, way and way.at
    local scale = ns.PinScale("route")
    THICKNESS.edge, THICKNESS.fill, THICKNESS.glint = (Route.THICK + 3) * scale, Route.THICK * scale, Route.THICK * scale
    if way and view.map then
        local cut = way.cut
        local fromLeg, fromIndex = cut and cut.leg or 1, cut and cut.index or 1
        box.left, box.right = (view.left - view.u) * view.k, (view.right - view.u) * view.k
        box.bottom, box.top = (view.bottom - view.v) * view.k, (view.top - view.v) * view.k
        for index, leg in ipairs(way.legs) do
            if index >= fromLeg then
                laying.number, laying.colour = index, Route.COLOURS[leg.kind] or Route.COLOURS.walk
                laying.faint = index > (way.at or 1) + 1 -- the legs after the next are drawn fainter
                laying.from = index == fromLeg and fromIndex or 1
                Lay(leg.points, view, Route.STRAY * scale, Route.PIECE * scale)
            end
        end
        local leg = cut and way.legs[cut.leg]
        if leg then
            head.entry = Next()
            Colour(head.entry, Route.COLOURS[leg.kind] or Route.COLOURS.walk, false)
            Hide(head.entry)
            head.to = 0
        end
    end
    for index = used + 1, #lines do Hide(lines[index]) end
    Route.Fit(ns.Canvas.edge)
    Head(ns.Canvas.edge)
end

-- The way to draw (Planner.lua), or none; drawn at once if the map is laid out.
function Route.Show(newWay)
    way = newWay
    if ns.Canvas.Laid() then Route.Place(ns.Canvas.view) end
end

-- The player moved along the way (its cut, Planner.Track): the parts passed go, the one they are on is drawn from
-- where they are, the head runs from them to it. Onto another leg: drawn anew (its colours, which legs are fainter).
function Route.Cut(newWay)
    if newWay ~= way or not laid or not ns.Canvas.Laid() then return end
    if way.at ~= laidAt then return Route.Place(ns.Canvas.view) end
    local cut, edge = way.cut, ns.Canvas.edge
    on = nil
    for index = first, count do
        local part = parts[index]
        local against = Against(part, cut)
        if against > 0 then break end
        if against == 0 then on = part end
        Refit(part, edge, against)
        if against < 0 then first = index + 1 end
    end
    Head(edge)
end

-- A step of the canvas' tracker (the player's place): the planner sees where along the way the player is.
function Route.Track(map, u, v, now)
    if ns.Planner and ns.Planner.Track then ns.Planner.Track(map, u, v, now) end
end

-- Out of sight (the window hidden): the lines go, the way is kept.
function Route.Clear()
    for _, entry in ipairs(lines) do Hide(entry) end
    used, count, first, on = 0, 0, 1, nil
    head.entry, laid = nil, nil
end
