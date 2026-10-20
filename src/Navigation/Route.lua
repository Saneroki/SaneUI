local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Route
--  The way to the map pin drawn on the map: a thin golden line, pulsing towards
--  the pin, on a layer of the canvas under the pins (Canvas.LEVELS), in both views.
--  The way itself is the planner's (Planner.lua); this draws what it gives:
--
--      Route.Show(way)   way = { legs = { { kind = "walk" | "flight" | "boat" | "zeppelin" | ...,
--                                           points = { { map = continent, u, v }, ... } }, ... } }
--      Route.Show(nil)   no way: the line goes
--
--  Each leg's points are joined by the game's Line widgets from a pool, only the
--  parts in view: under them a dark edge, over them the game's dependency bar art
--  tinted gold, and over that its glint, moved along the line by the engine (a
--  TextureCoordTranslation animation from Route.xml, as the game's talent lines
--  move theirs), so nothing of ours runs every frame for the pulse. A walk is
--  golden; a flight pale gold; a boat's or zeppelin's way red, as the plan has the
--  ships' routes; the hearthstone's pale blue, straight to its place.
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
    lift = { 1, 0.78, 0.25 }, portal = { 0.7, 0.5, 1 }, hearth = { 0.6, 0.8, 1 },
}

local THICKNESS = { edge = Route.THICK + 3, fill = Route.THICK, glint = Route.THICK }

local layer, holder
local way
local lines, used = {}, 0 -- the pool: { edge, fill, glint, group } each
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

-- One segment, x, y units from the holder's middle, in a leg's colour.
local function Segment(x1, y1, x2, y2, colour, faint)
    local length = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
    if length < 1 then return end
    local entry = Next()
    local repeats = length / Route.PERIOD
    for name, thickness in pairs(THICKNESS) do
        local line = entry[name]
        line:SetStartPoint("CENTER", holder, x1, y1)
        line:SetEndPoint("CENTER", holder, x2, y2)
        line:SetThickness(thickness)
        line:SetTexCoord(0, repeats, 0, 1)
        line:Show()
    end
    entry.fill:SetVertexColor(colour[1], colour[2], colour[3], faint and 0.5 or 0.9)
    entry.glint:SetVertexColor(colour[1], colour[2], colour[3], faint and 0.4 or 1)
    if entry.group and not entry.group:IsPlaying() then entry.group:Play() end
end

-- Whether a segment of the view's plane may reach into the view (its box against the view's, with its margin).
local function Near(view, u1, v1, u2, v2)
    return math.max(u1, u2) >= view.left and math.min(u1, u2) <= view.right
        and math.max(v1, v2) >= view.bottom and math.min(v1, v2) <= view.top
end

-- Drawn for the view as the canvas laid it out; only the parts in view.
function Route.Place(view)
    used = 0
    if way and view.map then
        for index, leg in ipairs(way.legs) do
            local colour = Route.COLOURS[leg.kind] or Route.COLOURS.walk
            local faint = index > (way.at or 1) + 1 -- the legs after the next are drawn fainter
            local lastU, lastV
            for _, point in ipairs(leg.points) do
                local link = Coords.Link(point.map, view.map)
                local u, v = link and link.du + link.su * point.u, link and link.dv + link.sv * point.v
                if u and lastU and Near(view, lastU, lastV, u, v) then
                    Segment((lastU - view.u) * view.k, (lastV - view.v) * view.k, (u - view.u) * view.k,
                        (v - view.v) * view.k, colour, faint)
                end
                lastU, lastV = u, v
            end
        end
    end
    for index = used + 1, #lines do
        local entry = lines[index]
        entry.edge:Hide()
        entry.fill:Hide()
        entry.glint:Hide()
        if entry.group then entry.group:Stop() end
    end
end

-- The way to draw (Planner.lua), or none; drawn at once if the map is laid out.
function Route.Show(newWay)
    way = newWay
    if ns.Canvas.Laid() then Route.Place(ns.Canvas.view) end
end

function Route.Way()
    return way
end

-- A step of the canvas' tracker (the player's place): the planner sees whether the player left the way.
function Route.Track(map, u, v, now)
    if ns.Planner and ns.Planner.Track then ns.Planner.Track(map, u, v, now) end
end

-- Out of sight (the window hidden): the lines go, the way is kept.
function Route.Clear()
    for _, entry in ipairs(lines) do
        entry.edge:Hide()
        entry.fill:Hide()
        entry.glint:Hide()
        if entry.group then entry.group:Stop() end
    end
    used = 0
end
