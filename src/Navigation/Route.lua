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
--  lift are golden; a flight pale gold; a boat's, a zeppelin's and the tram's way
--  red, as the plan has the ships' routes; a portal's violet; the hearthstone's and
--  the teleports' pale blue, straight to where they bring one.
-------------------------------------------------------------------------------
local Coords = ns.Coords
local Route = {}
ns.Route = Route

Route.EDGE = "Interface\\Artifacts\\_Artifacts-DependencyBar-BG"
Route.FILL = "Interface\\Artifacts\\_Artifacts-DependencyBar-Fill"
Route.GLINT = "Interface\\Artifacts\\_Artifacts-DependencyBar-FillScroll1"
Route.THICK = 6     -- the line's thickness in units; its edge a little thicker
Route.PERIOD = 48   -- units along the line one repeat of the art takes
-- The glint's pulse (Route.xml: one repeat in 1.2 seconds). The game makes this animation only from
-- XML; until it has read the file (a restart after it came) the glint stands still.
Route.GLINT_PULSE = "SaneUINavigationGlintTemplate"
Route.COLOURS = {
    walk = { 1, 0.78, 0.25 }, flight = { 1, 0.92, 0.6 },
    boat = { 0.95, 0.3, 0.2 }, zeppelin = { 0.95, 0.3, 0.2 }, tram = { 0.95, 0.3, 0.2 },
    lift = { 1, 0.78, 0.25 }, portal = { 0.7, 0.5, 1 }, hearth = { 0.6, 0.8, 1 }, teleport = { 0.6, 0.8, 1 },
}

-- The lines' thickness, at the size the pin filter's slider for the route asks (set at each layout, Place).
local THICKNESS = { edge = Route.THICK + 3, fill = Route.THICK, glint = Route.THICK }

local layer, holder
local way
local lines, used = {}, 0 -- the pool: { edge, fill, glint, group } each
-- The segments near the view, in the holder's units, in the way's order: { x1, y1, x2, y2, length, entry (its
-- lines), leg, index (its leg and the point it starts at), from, to (the share of it drawn, as last placed) }
local parts, count = {}, 0
local first = 1    -- the first part the player has not passed
local head = {}    -- the line from the player to where along the way they are: a part of its own (entry nil: none)
local laid         -- the view the parts were laid out for (the canvas'), and the leg the player was on then
local laidAt
local pulse -- whether the game has the pulse's template, asked once

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

-- One segment, x, y units from the holder's middle, in a leg's colour: its lines from the pool, placed by Fit. leg,
-- index: where it lies on the way.
local function Segment(x1, y1, x2, y2, colour, faint, leg, index)
    local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    if length < 1 then return end
    local entry = Next()
    Colour(entry, colour, faint)
    count = count + 1
    local part = parts[count] or {}
    parts[count] = part
    part.x1, part.y1, part.x2, part.y2, part.length, part.entry = x1, y1, x2, y2, length, entry
    part.leg, part.index, part.from, part.to = leg, index, nil, nil
end

-- A segment's lines from the share from to the share to of it (the art stays where it is on the way when the
-- segment is cut), or out of sight when nothing of it is drawn.
local function Draw(part)
    local entry = part.entry
    if part.to <= part.from then return Hide(entry) end
    local dx, dy = part.x2 - part.x1, part.y2 - part.y1
    local x1, y1 = part.x1 + dx * part.from, part.y1 + dy * part.from
    local x2, y2 = part.x1 + dx * part.to, part.y1 + dy * part.to
    local repeats = part.length / Route.PERIOD
    for name, thickness in pairs(THICKNESS) do
        local line = entry[name]
        line:SetStartPoint("CENTER", holder, x1, y1)
        line:SetEndPoint("CENTER", holder, x2, y2)
        line:SetThickness(thickness)
        line:SetTexCoord(part.from * repeats, part.to * repeats, 0, 1)
        line:Show()
    end
    if entry.group and not entry.group:IsPlaying() then entry.group:Play() end
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

-- Where a part lies against the cut: -1 before it (passed), 0 the part the player is on, 1 after it.
local function Against(part, cut)
    if not cut or part.leg > cut.leg then return 1 end
    if part.leg < cut.leg then return -1 end
    if part.index < cut.index then return -1 end
    return part.index > cut.index and 1 or 0
end

-- A part placed anew where what of it is drawn changed: cut at the canvas' rectangle (edge, in the holder's units;
-- the lines' own thickness inside it) and, on the part the player is on, from where they are; a part passed, not.
local function Refit(part, edge, against)
    local inset = THICKNESS.edge / 2
    local from, to = 0, 0
    if against >= 0 then
        from, to = Between(part.x1, part.x2 - part.x1, edge.left + inset, edge.right - inset, 0, 1)
        from, to = Between(part.y1, part.y2 - part.y1, edge.bottom + inset, edge.top - inset, from, to)
        if against == 0 then from = math.max(from, way.cut.t) end
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

-- The head: from where the player is to where along the way that is (the cut), in the colour of the leg they are on.
local function Head(edge)
    if not head.entry then return end
    local cut = way and way.cut
    local x1, y1, x2, y2
    if cut and cut.u and cut.pu then
        x1, y1 = Spot(cut.map, cut.pu, cut.pv)
        x2, y2 = Spot(cut.map, cut.u, cut.v)
    end
    local length = x1 and x2 and math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) or 0
    if length < 1 then
        head.length = 0
        if head.to ~= 0 then
            head.from, head.to = 0, 0
            Hide(head.entry)
        end
        return
    end
    head.x1, head.y1, head.x2, head.y2, head.length, head.from = x1, y1, x2, y2, length, nil
    Refit(head, edge, 1)
end

-- Every part kept inside the canvas' rectangle as it is now (Canvas.edge, in the holder's units): only a part whose
-- share inside changed is placed anew, so a step of following moves those at the edge alone.
function Route.Fit(edge)
    local cut = way and way.cut
    for index = first, count do
        local part = parts[index]
        Refit(part, edge, Against(part, cut))
    end
    if head.entry and head.length and head.length >= 1 then
        head.from = nil
        Refit(head, edge, 1)
    end
end

-- Whether a segment of the view's plane may reach into the view (its box against the view's, with its margin).
local function Near(view, u1, v1, u2, v2)
    return math.max(u1, u2) >= view.left and math.min(u1, u2) <= view.right
        and math.max(v1, v2) >= view.bottom and math.min(v1, v2) <= view.top
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
        for index, leg in ipairs(way.legs) do
            if index >= fromLeg then
                local colour = Route.COLOURS[leg.kind] or Route.COLOURS.walk
                local faint = index > (way.at or 1) + 1 -- the legs after the next are drawn fainter
                local lastU, lastV
                for number, point in ipairs(leg.points) do
                    local link = Coords.Link(point.map, view.map)
                    local u, v = link and link.du + link.su * point.u, link and link.dv + link.sv * point.v
                    if u and lastU and (index > fromLeg or number > fromIndex) and Near(view, lastU, lastV, u, v) then
                        Segment((lastU - view.u) * view.k, (lastV - view.v) * view.k, (u - view.u) * view.k,
                            (v - view.v) * view.k, colour, faint, index, number - 1)
                    end
                    lastU, lastV = u, v
                end
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
    for index = first, count do
        local part = parts[index]
        local against = Against(part, cut)
        if against > 0 then break end
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
    used, count, first = 0, 0, 1
    head.entry, laid = nil, nil
end
