local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Draw
--  Drawing on the map (Saneroki, 2026-11-15: "Can we draw on the map too? ... draw on the map and save those
--  drawings and map pins together so they can be shared or grouped together. This will be especially helpful in
--  instance maps"): the drawings of the plans shown (Plans.lua) on the full and the small map and on a dungeon's
--  floor (Dungeons.lua), the tools of the palette (DrawBar.lua) at work, and your markers on a dungeon's floor.
--
--      the tools   marker (a click: a marker there, Markers.New), pen (a drag: a stroke as the mouse goes), line
--                  and arrow (a drag: from where it began to where it is let go), circle (a drag: its middle
--                  where it began, its edge where it is let go), route (clicks: a numbered stop at each, a line
--                  between; Saneroki, 2026-11-15, "activate it and click a couple of times on the map and it shows
--                  you the positions with the number and line inbetween"), text (a click: words there, asked for;
--                  "I also want to be able to add plain text to the drawings"), eraser (a click on a drawing or
--                  words: away); in the palette's colour and width, into the active plan. While a tool is on the
--                  left button is the tool's, a drag with the right one moves the map (a right click still steps
--                  out)
--      dragging    while a tool is on (the eraser's aside), a press on what stands there drags it to a new place
--                  ("While in edit mode I want to be able to drag the markers, texts, lines, etc to new positions
--                  ... without activating a specific move button"): a marker (onto the zone under the mouse), words,
--                  a route's stop (that stop alone), a drawing (every point along); a marker pressed and let go
--                  without moving opens its card
--      on the map  the game's lines in the drawing's colour over a dark edge, as thick on the screen at every
--                  zoom; an arrow's head and a circle drawn of lines too; cut at the view's edge by hand (the game
--                  does not cut a line at a frame's edge)
--      a floor     the same over a dungeon's art, its points on the floor's own map (0 to 1), moved and zoomed
--                  with it; your markers on it in their icons with their titles, a click their card
--
--      Draw.Tool(), Draw.SetTool(key), Draw.Colour(), Draw.SetColour(key), Draw.Width(), Draw.SetWidth(1 | 2 | 3)
--      Draw.TextSize(), Draw.SetTextSize(0 | 1 | 2 | 3)   words' size, apart from the lines' width (0 small, 3 huge)
--      Draw.Build(holder), Draw.Place(view, small), Draw.Fit(edge), Draw.Clear()     the canvas' layer sketch
--      Draw.Floor(frame, map, art, scale, midX, midY, small), Draw.FloorClear()      a dungeon's floor
--      Draw.Press(), Draw.PressFloor(), Draw.Busy(), Draw.Release()                  the mouse (Canvas, Dungeons)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Draw = {}
ns.Draw = Draw

Draw.TOOLS = { "marker", "pen", "line", "arrow", "circle", "route", "text", "erase" }
Draw.THICK = { 3, 6, 10 } -- a drawing's thickness in units, thin, medium and thick (Saneroki, 2026-11-16: "expand to 8
                        -- colours and 3 lines", as the dungeon map addon Sane UI knows draws them)
Draw.EDGE = 2           -- units of dark edge round it
Draw.STEP = 4           -- units the mouse goes before a pen's next point
Draw.LEAST = 4          -- units a line, an arrow or a circle's radius is long at least
Draw.REACH = 8          -- units from a drawing the eraser takes it
Draw.HEAD = 12          -- units an arrow's head is long (and its width's share more)
Draw.SPREAD = 0.45      -- radians an arrow's head opens to each side
Draw.SIDES = 40         -- a circle's sides
Draw.PIN = 24           -- a marker on a dungeon's floor
Draw.GRAB = 14          -- units from a marker's middle a press takes it (to drag it)
Draw.STOPS = { 18, 22, 26 } -- a route's numbered stop across, thin, medium and thick
Draw.STOP = Draw.STOPS[1]
Draw.ROUND = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask" -- (the game's round picture: a stop)
-- Words on the map by their size (a text drawing's width): small, normal, large and huge, the game's 12, 16, 20 and 24
-- point outlined fonts (Saneroki, 2026-11-16: "add a fourth text size so their smallest matches too").
Draw.WORDS = { [0] = "GameFontNormalOutline", "GameFontNormalLargeOutline", "GameFontNormalHugeOutline",
               "GameFontNormalHuge2Outline" }
Draw.WORDS_HIGH = { [0] = 14, 18, 24, 28 } -- their line's height, should the game not tell
Draw.WORDS_MOST = 80    -- letters of words on the map at most
Draw.WHITE = "Interface\\Buttons\\WHITE8X8"
Draw.TEXT = {
    noPlace = "Nothing to draw on here: zoom in onto a zone.",
    full = "That is all a stroke takes: let go and begin another.",
    wordsAsk = "The words on the map:",
}

local tool        -- the tool on (nil: none, the map's own mouse)
local current     -- the drawing under way: { surface, map, kind, colour, width, points, sx, sy (its last point on
                  -- the screen) }
local stroker     -- the frame whose OnUpdate follows the mouse while a drawing is under way, or one is dragged
local held        -- what a press drags (Saneroki, 2026-11-15: "make it possible that map markers are draggable so
                  -- you can move them to a different position"): { surface, thing (a marker or a drawing), marker
                  -- (true for a marker), stop (a route's stop: its number), x, y (a drawing's: the mouse's last point
                  -- on its map), sx, sy (a marker's last place on the screen), moved (it went somewhere) }
local route, routeOn -- the route under way (its drawing, kept in the plans) and its surface; nil while none

-------------------------------------------------------------------------------
--  The palette's choices
-------------------------------------------------------------------------------
function Draw.Tool()
    return tool
end

-- A tool on (one of Draw.TOOLS), or none (nil): the map's mouse its own again.
function Draw.SetTool(key)
    tool = key
    route = nil -- (a route goes on only while its tool stays on: chosen again, a new one)
    if not key then current, held = nil, nil end
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

function Draw.Colour()
    local key = ns.store.drawColour
    for _, colour in ipairs(ns.Plans.COLOURS) do
        if colour.key == key then return key end
    end
    return ns.Plans.COLOURS[1].key
end

function Draw.SetColour(key)
    ns.store.drawColour = key
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

-- A width as one of the three (1 thin, 2 medium, 3 thick); 1 for one not known.
function Draw.Widths(width)
    return (width == 2 or width == 3) and width or 1
end

function Draw.Width()
    return Draw.Widths(ns.store.drawWidth)
end

-- A text drawing's size as one of the four (0 small, 1 normal, 2 large, 3 huge); 1 for one not known.
function Draw.TextSizes(size)
    return (size == 0 or size == 2 or size == 3) and size or 1
end

function Draw.TextSize()
    return Draw.TextSizes(ns.store.textSize)
end

function Draw.SetTextSize(size)
    ns.store.textSize = Draw.TextSizes(size)
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

function Draw.SetWidth(width)
    ns.store.drawWidth = Draw.Widths(width)
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

-------------------------------------------------------------------------------
--  Lines on a surface
-------------------------------------------------------------------------------
-- A surface: the frame its lines are made in and anchored to (anchor: their points from its middle), its lines'
-- pool, and what was placed (each segment's ends on the screen, unclipped, its drawing, thickness and colour).
local function Surface(parent, anchor)
    return { frame = parent, anchor = anchor, lines = {}, used = 0, placed = {}, labels = {}, words = {}, stops = {} }
end

local canvas, floor -- the canvas' surface, the floor's

local function Line(surface)
    surface.used = surface.used + 1
    local entry = surface.lines[surface.used]
    if entry then return entry end
    local frame = surface.frame
    entry = { edge = frame:CreateLine(nil, "ARTWORK", nil, 0), fill = frame:CreateLine(nil, "ARTWORK", nil, 1) }
    entry.edge:SetTexture(Draw.WHITE)
    entry.fill:SetTexture(Draw.WHITE)
    entry.edge:SetVertexColor(0, 0, 0, 0.6)
    surface.lines[surface.used] = entry
    return entry
end

-- Where a segment's part inside the rectangle (left, right, bottom, top) begins and ends along it (0 to 1); nil
-- when none of it is inside.
local function Clip(x1, y1, x2, y2, left, right, bottom, top)
    local from, to = 0, 1
    local dx, dy = x2 - x1, y2 - y1
    local function Edge(p, q)
        if p == 0 then return q >= 0 end
        local t = q / p
        if p < 0 then
            if t > to then return false end
            if t > from then from = t end
        else
            if t < from then return false end
            if t < to then to = t end
        end
        return true
    end
    if Edge(-dx, x1 - left) and Edge(dx, right - x1) and Edge(-dy, y1 - bottom) and Edge(dy, top - y1) then
        return from, to
    end
    return nil
end

-- The surface's lines laid anew from what was placed, each cut to the rectangle; the lines left over hidden.
local function Lay(surface, left, right, bottom, top)
    surface.used = 0
    for _, seg in ipairs(surface.placed) do
        local from, to = Clip(seg.x1, seg.y1, seg.x2, seg.y2, left, right, bottom, top)
        if from and to > from then
            local x1, y1 = seg.x1 + (seg.x2 - seg.x1) * from, seg.y1 + (seg.y2 - seg.y1) * from
            local x2, y2 = seg.x1 + (seg.x2 - seg.x1) * to, seg.y1 + (seg.y2 - seg.y1) * to
            local entry = Line(surface)
            for _, line in ipairs({ entry.edge, entry.fill }) do
                line:SetStartPoint("CENTER", surface.anchor, x1, y1)
                line:SetEndPoint("CENTER", surface.anchor, x2, y2)
                line:Show()
            end
            entry.edge:SetThickness(seg.thick + 2 * Draw.EDGE)
            entry.fill:SetThickness(seg.thick)
            entry.fill:SetVertexColor(seg.rgb[1], seg.rgb[2], seg.rgb[3], 1)
        end
    end
    for index = surface.used + 1, #surface.lines do
        surface.lines[index].edge:Hide()
        surface.lines[index].fill:Hide()
    end
    -- the words and the routes' numbered stops, over the lines, those whose point is inside the rectangle
    local words, stops = 0, 0
    for _, label in ipairs(surface.labels) do
        if label.x >= left and label.x <= right and label.y >= bottom and label.y <= top then
            local rgb = label.rgb
            if label.stop then
                stops = stops + 1
                local stop = surface.stops[stops]
                if not stop then
                    stop = { ring = surface.frame:CreateTexture(nil, "OVERLAY", nil, 1),
                             fill = surface.frame:CreateTexture(nil, "OVERLAY", nil, 2),
                             number = surface.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline") }
                    stop.ring:SetTexture(Draw.ROUND)
                    stop.ring:SetVertexColor(0, 0, 0, 0.75)
                    stop.fill:SetTexture(Draw.ROUND)
                    stop.number:SetDrawLayer("OVERLAY", 3)
                    surface.stops[stops] = stop
                end
                local size = Draw.STOPS[label.size] or Draw.STOP
                stop.ring:SetSize(size + 2 * Draw.EDGE, size + 2 * Draw.EDGE)
                stop.fill:SetSize(size, size)
                stop.fill:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
                stop.number:SetText(label.stop)
                for _, part in ipairs({ stop.ring, stop.fill, stop.number }) do
                    part:ClearAllPoints()
                    part:SetPoint("CENTER", surface.anchor, "CENTER", label.x, label.y)
                    part:Show()
                end
                label.w, label.h = size, size
            else
                words = words + 1
                local text = surface.words[words]
                if not text then
                    text = surface.frame:CreateFontString(nil, "OVERLAY", Draw.WORDS[1])
                    surface.words[words] = text
                end
                text:SetFontObject(Draw.WORDS[label.size] or Draw.WORDS[1])
                text:SetText(label.text)
                text:SetTextColor(rgb[1], rgb[2], rgb[3], 1)
                text:ClearAllPoints()
                text:SetPoint("CENTER", surface.anchor, "CENTER", label.x, label.y)
                text:Show()
                local wide = Core.Plain(text:GetStringWidth())
                label.w = type(wide) == "number" and wide > 0 and wide or #label.text * (4 + 3 * (label.size or 1))
                label.h = Draw.WORDS_HIGH[label.size] or Draw.WORDS_HIGH[1]
            end
        end
    end
    for index = words + 1, #surface.words do surface.words[index]:Hide() end
    for index = stops + 1, #surface.stops do
        local stop = surface.stops[index]
        stop.ring:Hide()
        stop.fill:Hide()
        stop.number:Hide()
    end
end

-- A drawing's segments on the screen (ToScreen: a point of its map to the surface's units, nil off it): a pen's
-- strokes, a line, an arrow with its head, a circle of Draw.SIDES sides, a route's legs; and into labels its words,
-- or a route's numbered stops.
local function Segments(drawing, ToScreen, out, labels)
    local points = drawing.points
    local screen = {}
    for index = 1, #points - 1, 2 do
        local x, y = ToScreen(drawing.map, points[index], points[index + 1])
        if not x then return end
        screen[#screen + 1] = x
        screen[#screen + 1] = y
    end
    local size = Draw.Widths(drawing.width)
    local thick = Draw.THICK[size]
    local textSize = Draw.TextSizes(drawing.width)
    local rgb = ns.Plans.Colour(drawing.colour)
    local function Add(x1, y1, x2, y2)
        out[#out + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, thick = thick, rgb = rgb, drawing = drawing }
    end
    local kind = drawing.kind
    if kind == "text" then
        if labels and #screen >= 2 then
            labels[#labels + 1] = { x = screen[1], y = screen[2], text = drawing.text or "", rgb = rgb,
                                    size = textSize, drawing = drawing }
        end
        return
    end
    if kind == "route" and labels then
        for index = 1, #screen - 1, 2 do
            labels[#labels + 1] = { x = screen[index], y = screen[index + 1], stop = (index + 1) / 2, rgb = rgb,
                                    size = size, drawing = drawing }
        end
    end
    if kind == "circle" and #screen >= 4 then
        local cx, cy = screen[1], screen[2]
        local r = math.sqrt((screen[3] - cx) ^ 2 + (screen[4] - cy) ^ 2)
        local step = 2 * math.pi / Draw.SIDES
        for side = 0, Draw.SIDES - 1 do
            local a, b = side * step, (side + 1) * step
            Add(cx + r * math.cos(a), cy + r * math.sin(a), cx + r * math.cos(b), cy + r * math.sin(b))
        end
        return
    end
    for index = 1, #screen - 3, 2 do Add(screen[index], screen[index + 1], screen[index + 2], screen[index + 3]) end
    if kind == "arrow" and #screen >= 4 then
        local n = #screen
        local x2, y2, x1, y1 = screen[n - 1], screen[n], screen[n - 3], screen[n - 2]
        local angle = math.atan2(y2 - y1, x2 - x1)
        local head = Draw.HEAD + thick
        for _, side in ipairs({ -1, 1 }) do
            local a = angle + math.pi + side * Draw.SPREAD
            Add(x2, y2, x2 + head * math.cos(a), y2 + head * math.sin(a))
        end
    end
end

-- The drawings of the plans shown on a map (or every map: nil) and the one under way, for a surface.
local function Shown(onFloor)
    local list = {}
    for _, drawing in ipairs(ns.Plans.Drawings()) do
        if ns.Plans.Visible(drawing.plan) and (onFloor == nil or drawing.map == onFloor) then list[#list + 1] = drawing end
    end
    if current and (onFloor == nil and current.surface == "canvas" or onFloor ~= nil and current.map == onFloor) then
        list[#list + 1] = current
    end
    return list
end

-------------------------------------------------------------------------------
--  On the map (the canvas)
-------------------------------------------------------------------------------
local view   -- the canvas' view as it was last laid out (Canvas.view)
local small  -- whether that was the small one

function Draw.Build(canvasHolder)
    local layer = CreateFrame("Frame", nil, canvasHolder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    canvas = Surface(layer, canvasHolder)
    return layer
end

-- A point of a map in the canvas' holder's units, as the view was laid out; nil where the map is in no plane linked
-- to the view's (a dungeon's floor, another continent in Retail).
local function OnCanvas(map, x, y)
    if type(map) ~= "number" or not view then return nil end
    local u, v = Coords.MapToPlane(map, x, y, view.map)
    if not u then return nil end
    return (u - view.u) * view.k, (v - view.v) * view.k
end

-- The drawings of the plans shown, in view (the canvas laying out; small: the small map too).
function Draw.Place(laidView, onSmall)
    if not canvas then return end
    view, small = laidView, onSmall
    wipe(canvas.placed)
    wipe(canvas.labels)
    for _, drawing in ipairs(Shown(nil)) do
        if type(drawing.map) == "number" then Segments(drawing, OnCanvas, canvas.placed, canvas.labels) end
    end
    Draw.Fit(ns.Canvas.edge)
end

-- Cut at the canvas' edge anew (the holder moved: Canvas.Keep).
function Draw.Fit(edge)
    if not canvas or not edge then return end
    Lay(canvas, edge.left, edge.right, edge.bottom, edge.top)
end

function Draw.Clear()
    if not canvas then return end
    wipe(canvas.placed)
    wipe(canvas.labels)
    Lay(canvas, 0, 0, 0, 0)
end

-- A drawing of the plans changed (Plans.Changed): the floor shown drawn again (the canvas is, by its refresh).
function Draw.Changed()
    if floor and floor.shown then Draw.Floor(floor.dungeon, floor.shown, floor.art, floor.scale, floor.midX, floor.midY,
        floor.small) end
end

-------------------------------------------------------------------------------
--  On a dungeon's floor
-------------------------------------------------------------------------------
local pins = {}   -- your markers' buttons on the floor
local Hold        -- (below, The tools at work: a press takes a marker to drag it; the floor's pins press it too)
local pinFrame    -- their frame, over the lines

local function PinTip(button)
    local marker = button.marker
    if not marker then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(marker.title or ns.Markers.TEXT.untitled, 1, 1, 1)
    if marker.text and marker.text ~= "" then GameTooltip:AddLine(marker.text, 1, 1, 1, true) end
    if marker.from then GameTooltip:AddLine(ns.Markers.TEXT.from:format(marker.from), 0.6, 0.6, 0.6) end
    GameTooltip:AddLine(ns.Markers.TEXT.hintFloor, 0.5, 0.5, 0.5, true)
    GameTooltip:Show()
end

local function Pin(index)
    local button = pins[index]
    if button then return button end
    button = CreateFrame("Button", nil, pinFrame)
    button:SetSize(Draw.PIN, Draw.PIN)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    button.label:SetPoint("LEFT", button, "RIGHT", 4, 0)
    -- with a tool on (the eraser's aside), pressed: dragged (Hold); let go: put down (not moved: its card); else a click
    -- opens its card
    button:SetScript("OnMouseDown", ns.Guard(function(self, mouse)
        if mouse == "LeftButton" and tool and tool ~= "erase" and self.marker then Hold("floor", self.marker) end
    end))
    button:SetScript("OnMouseUp", ns.Guard(function(_, mouse)
        if mouse == "LeftButton" and held then Draw.Release() end
    end))
    button:SetScript("OnClick", ns.Guard(function(self)
        if tool and tool ~= "erase" then return end -- (Draw.Release opened it)
        if self.marker then ns.Markers.Open(self.marker) end
    end))
    button:SetScript("OnEnter", ns.Guard(PinTip))
    button:SetScript("OnLeave", GameTooltip_Hide)
    pins[index] = button
    return button
end

-- A dungeon's floor laid out (Dungeons.lua, at each move and zoom): its drawings and your markers on it, where the
-- art stands (its middle midX, midY from the frame's, the art's scale), cut at the frame's edge. Small: no labels.
function Draw.Floor(dungeon, map, art, scale, midX, midY, onSmall)
    if not dungeon or not art then return end
    if not floor or floor.dungeon ~= dungeon then
        local sketch = CreateFrame("Frame", nil, dungeon)
        sketch:SetAllPoints()
        sketch:SetFrameLevel(dungeon:GetFrameLevel() + 2)
        floor = Surface(sketch, dungeon)
        floor.dungeon = dungeon
        pinFrame = CreateFrame("Frame", nil, dungeon)
        pinFrame:SetAllPoints()
        pinFrame:SetFrameLevel(dungeon:GetFrameLevel() + 6)
    end
    floor.shown, floor.art, floor.scale, floor.midX, floor.midY, floor.small = map, art, scale, midX, midY, onSmall
    local function OnFloor(_, x, y)
        return midX + (x - 0.5) * art.width * scale, midY - (y - 0.5) * art.height * scale
    end
    floor.ToScreen = OnFloor
    wipe(floor.placed)
    wipe(floor.labels)
    for _, drawing in ipairs(Shown(map)) do Segments(drawing, OnFloor, floor.placed, floor.labels) end
    local width, height = dungeon:GetSize()
    width, height = width or 0, height or 0
    Lay(floor, -width / 2, width / 2, -height / 2, height / 2)
    local count = 0
    for _, marker in ipairs(ns.Markers.List()) do
        if marker.map == map and ns.Plans.Visible(marker.plan) then
            local x, y = OnFloor(map, marker.x or 0, marker.y or 0)
            if math.abs(x) <= width / 2 and math.abs(y) <= height / 2 then
                count = count + 1
                local button = Pin(count)
                button.marker = marker
                ns.Markers.Paint(button.icon, marker.icon)
                button.label:SetText(not onSmall and marker.title or "")
                button:ClearAllPoints()
                button:SetPoint("CENTER", dungeon, "CENTER", x, y)
                button:Show()
            end
        end
    end
    for index = count + 1, #pins do
        pins[index]:Hide()
        pins[index].marker = nil
    end
end

-- The floor's view gone (Dungeons.Close).
function Draw.FloorClear()
    if not floor then return end
    floor.shown = nil
    wipe(floor.placed)
    wipe(floor.labels)
    Lay(floor, 0, 0, 0, 0)
    for _, button in ipairs(pins) do
        button:Hide()
        button.marker = nil
    end
end

-------------------------------------------------------------------------------
--  The tools at work
-------------------------------------------------------------------------------
-- The mouse now: on the canvas (the view's plane point and the spot under it) or on the floor (its map's point).
local function Mouse(surface)
    if surface == "floor" then
        local map, x, y = ns.Dungeons.Point()
        return map, x, y
    end
    local u, v, spot = ns.Canvas.Under()
    return spot, u, v
end

-- A point of the view's plane on a map of the canvas (the drawing's own: its first point's map).
local function Onto(map, u, v)
    local home = Coords.PlaneOf(map)
    local link = home and Coords.Link(view.map, home)
    local box = Coords.Box(map)
    if not (link and box) then return nil end
    return Coords.ToMap(box, link.du + link.su * u, link.dv + link.sv * v)
end

-- The drawing under way's point on the screen now (its surface's units).
local function Screen(surface, map, x, y)
    if surface == "floor" then
        if floor and floor.ToScreen then return floor.ToScreen(map, x, y) end
        return nil
    end
    return OnCanvas(map, x, y)
end

local function Redraw(surface)
    if surface == "floor" then return Draw.Changed() end
    if view then Draw.Place(view, small) end
end

-- The drawing nearest a point of the screen within Draw.REACH units (the eraser's, the Move tool's), nil where none.
local function Nearest(surface, sx, sy)
    local placed = surface == "floor" and floor and floor.placed or canvas.placed
    local best, bestReach
    for _, seg in ipairs(placed) do
        local dx, dy = seg.x2 - seg.x1, seg.y2 - seg.y1
        local length = dx * dx + dy * dy
        local t = length > 0 and math.max(0, math.min(1, ((sx - seg.x1) * dx + (sy - seg.y1) * dy) / length)) or 0
        local reach = math.sqrt((seg.x1 + t * dx - sx) ^ 2 + (seg.y1 + t * dy - sy) ^ 2)
        if reach <= Draw.REACH + seg.thick / 2 and (not bestReach or reach < bestReach) and seg.drawing ~= current then
            best, bestReach = seg.drawing, reach
        end
    end
    return best
end

-- The words or the route's stop at a point of the screen (as they were laid: their place and size), the topmost; nil
-- where none.
local function LabelAt(surface, sx, sy)
    local labels = surface == "floor" and floor and floor.labels or canvas.labels
    for index = #labels, 1, -1 do
        local label = labels[index]
        local w, h = label.w or Draw.STOP, label.h or Draw.STOP
        if math.abs(label.x - sx) <= w / 2 + 2 and math.abs(label.y - sy) <= h / 2 + 2 then return label end
    end
    return nil
end

-- The eraser: the words or the drawing under the mouse (within Draw.REACH units of a line), away.
local function Erase(surface, sx, sy)
    local label = LabelAt(surface, sx, sy)
    local best = label and label.drawing or Nearest(surface, sx, sy)
    if best then ns.Plans.Erase(best) end
end

-- The marker nearest a point of the screen within Draw.GRAB units of its middle (shown: its sketch shown; on the
-- floor: on the floor's map), nil where none.
local function MarkerAt(surface, sx, sy)
    local best, bestReach
    for _, marker in ipairs(ns.Markers.List()) do
        local here = surface ~= "floor" or (floor and marker.map == floor.shown)
        if here and ns.Plans.Visible(marker.plan) then
            local mx, my = Screen(surface, marker.map, marker.x or 0, marker.y or 0)
            local reach = mx and math.sqrt((mx - sx) ^ 2 + (my - sy) ^ 2)
            if reach and reach <= Draw.GRAB and (not bestReach or reach < bestReach) then best, bestReach = marker, reach end
        end
    end
    return best
end

-- The mouse on a map now: its point there (x, y; on the floor only on the floor's own map), nil off it.
local function MouseOn(surface, map)
    if surface == "floor" then
        local at, x, y = Mouse("floor")
        if at == map then return x, y end
        return nil
    end
    local _, u, v = Mouse("canvas")
    if not u then return nil end
    return Onto(map, u, v)
end

-- Each frame while the Move tool holds something: a marker goes where the mouse is (onto the zone under it, on the
-- map; on its floor, on a dungeon's), a drawing goes along with the mouse, every point by as much.
local function Drag()
    if not held then return end
    local thing = held.thing
    if held.marker then
        local spot
        if held.surface == "floor" then
            local map, x, y = Mouse("floor")
            if map ~= thing.map or not x then return end
            spot = { map = map, x = x, y = y }
        else
            spot = Mouse("canvas")
            if type(spot) ~= "table" or not spot.map or not spot.x then return end
        end
        local sx, sy = Screen(held.surface, spot.map, spot.x, spot.y)
        if sx and held.sx and math.abs(sx - held.sx) + math.abs(sy - held.sy) < 1 then return end
        held.sx, held.sy, held.moved = sx, sy, true
        thing.map, thing.x, thing.y = spot.map, spot.x, spot.y
        return ns.Markers.Changed()
    end
    local x, y = MouseOn(held.surface, thing.map)
    if not x or (x == held.x and y == held.y) then return end
    local points = thing.points
    if held.stop then
        -- a route's stop alone: onto the mouse
        points[2 * held.stop - 1], points[2 * held.stop] = x, y
    else
        local dx, dy = x - held.x, y - held.y
        for index = 1, #points - 1, 2 do points[index], points[index + 1] = points[index] + dx, points[index + 1] + dy end
    end
    held.x, held.y, held.moved = x, y, true
    Redraw(held.surface)
end
local dragged = ns.Guard(Drag) -- made once

-- A press takes a marker or a drawing (or a route's stop) on a surface; held until the button is let go (Draw.Release).
function Hold(surface, marker, drawing, stop)
    if not (marker or drawing) then return end
    held = { surface = surface, thing = marker or drawing, marker = marker ~= nil, stop = stop }
    if marker then
        -- where it was pressed: a marker goes only once the mouse goes from there (pressed and let go: its card)
        local a, b, c = Mouse(surface)
        local map, x, y
        if surface == "floor" then map, x, y = a, b, c else map, x, y = a and a.map, a and a.x, a and a.y end
        if map and x then held.sx, held.sy = Screen(surface, map, x, y) end
    end
    if drawing then
        held.x, held.y = MouseOn(surface, drawing.map)
        if not held.x then
            held = nil
            return
        end
    end
    stroker = stroker or CreateFrame("Frame")
    stroker:SetScript("OnUpdate", dragged)
    Draw.stroker = stroker -- (for the tests)
end

-- What stands at a point of the screen, taken to be dragged: a marker first (they stand over all), then words or a
-- route's stop, then a drawing's line. True when something was taken.
local function Grab(surface, sx, sy)
    local marker = MarkerAt(surface, sx, sy)
    if marker then
        Hold(surface, marker)
        return true
    end
    local label = LabelAt(surface, sx, sy)
    if label then
        Hold(surface, nil, label.drawing, label.stop)
        return held ~= nil
    end
    local drawing = Nearest(surface, sx, sy)
    if drawing then
        Hold(surface, nil, drawing)
        return held ~= nil
    end
    return false
end

-- The press on a pin of the map with a tool on (Canvas.lua): what stands under the mouse taken to be dragged (a
-- marker's pin: the marker); false where nothing is (the pin's own click goes on).
function Draw.Grab()
    if not tool or tool == "erase" then return false end
    local spot = Mouse("canvas")
    if type(spot) ~= "table" or not spot.map or not spot.x then return false end
    local sx, sy = Screen("canvas", spot.map, spot.x, spot.y)
    return sx ~= nil and Grab("canvas", sx, sy)
end

local function Round(value) return math.floor(value * 10000 + 0.5) / 10000 end

-- The route tool's click: a stop more on the route under way (on its own map, wherever the mouse is in its plane),
-- else a route begun there, its first stop.
local function AddStop(surface, map, x, y)
    if route then
        local kept = false
        for _, drawing in ipairs(ns.Plans.Drawings()) do kept = kept or drawing == route end
        if not kept or routeOn ~= surface then route = nil end
    end
    if route then
        local rx, ry = MouseOn(surface, route.map)
        if rx then
            local points = route.points
            if #points >= ns.Plans.POINTS * 2 then return UIErrorsFrame:AddMessage(Draw.TEXT.full, 1, 0.82, 0) end
            points[#points + 1], points[#points + 2] = Round(rx), Round(ry)
            return Redraw(surface)
        end
    end
    route = ns.Plans.Add({ map = map, kind = "route", colour = Draw.Colour(), width = Draw.Width(), points = { x, y } })
    routeOn = surface
end

-- The text tool's click: the words asked for (the game's box), then put there in the palette's colour and words' size.
local function AddWords(map, x, y)
    local colour, width, plan = Draw.Colour(), Draw.TextSize(), ns.Plans.Active().id
    Core.AskText(Draw.TEXT.wordsAsk, nil, nil, "", ns.Guard(function(text)
        text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return end
        ns.Plans.Add({ map = map, kind = "text", colour = colour, width = width, plan = plan, points = { x, y },
                       text = text:sub(1, Draw.WORDS_MOST) })
    end), Draw.WORDS_MOST)
end

-- Each frame while the button is held: the drawing under way follows the mouse.
local function Follow()
    if not current then return end
    local surface = current.surface
    local first, x, y
    if surface == "floor" then
        first, x, y = Mouse("floor")
        if first ~= current.map then return end
    else
        local _, u, v = Mouse("canvas")
        if not u then return end
        x, y = Onto(current.map, u, v)
    end
    if not x then return end
    local points = current.points
    if current.kind == "pen" then
        local sx, sy = Screen(surface, current.map, x, y)
        if not sx or (current.sx and math.abs(sx - current.sx) + math.abs(sy - current.sy) < Draw.STEP) then return end
        if #points >= ns.Plans.POINTS * 2 then return UIErrorsFrame:AddMessage(Draw.TEXT.full, 1, 0.82, 0) end
        points[#points + 1], points[#points + 2] = x, y
        current.sx, current.sy = sx, sy
    else
        points[3], points[4] = x, y
    end
    Redraw(surface)
end
local following = ns.Guard(Follow) -- made once

-- A drawing begun on a surface at a point of a map.
local function Begin(surface, map, x, y)
    current = { surface = surface, map = map, kind = tool, colour = Draw.Colour(), width = Draw.Width(),
                points = { x, y }, plan = ns.Plans.Active().id }
    if tool ~= "pen" then current.points[3], current.points[4] = x, y end
    current.sx, current.sy = Screen(surface, map, x, y)
    stroker = stroker or CreateFrame("Frame")
    stroker:SetScript("OnUpdate", following)
    Draw.stroker = stroker -- (for the tests)
end

-- The left button pressed with a tool on: on the map (Canvas.lua) or on a dungeon's floor (Dungeons.lua).
local function Press(surface)
    if not tool then return end
    local a, b, c = Mouse(surface)
    local map, x, y
    if surface == "floor" then map, x, y = a, b, c else map, x, y = a and a.map, a and a.x, a and a.y end
    local sx, sy
    if map and x then sx, sy = Screen(surface, map, x, y) end
    if tool == "erase" then
        if sx then Erase(surface, sx, sy) end
        return
    end
    -- what stands there already is dragged to a new place, whatever the tool (Saneroki, 2026-11-15)
    if sx and Grab(surface, sx, sy) then return end
    if not (map and x) then return UIErrorsFrame:AddMessage(Draw.TEXT.noPlace, 1, 0.1, 0.1) end
    if tool == "marker" then return ns.Markers.New({ map = map, x = x, y = y }) end
    if tool == "route" then return AddStop(surface, map, x, y) end
    if tool == "text" then return AddWords(map, x, y) end
    Begin(surface, map, x, y)
    Redraw(surface)
end

function Draw.Press()
    return Press("canvas")
end

function Draw.PressFloor()
    return Press("floor")
end

function Draw.Busy()
    return current ~= nil or held ~= nil
end

-- Let go: the drawing kept in the active plan where it is long enough (a pen's two points, the others Draw.LEAST
-- units on the screen), else let go of.
function Draw.Release()
    if held then
        -- what a press held: put down where the mouse let go of it (kept as it is: the saved settings hold it); a
        -- marker pressed and let go without going anywhere: its card
        Drag()
        local was = held
        held = nil
        if stroker then stroker:SetScript("OnUpdate", nil) end
        if was.marker then
            if not was.moved then return ns.Markers.Open(was.thing) end
            return ns.Markers.Changed()
        end
        return Redraw(was.surface)
    end
    local drawing = current
    current = nil
    if stroker then stroker:SetScript("OnUpdate", nil) end
    if not drawing then return end
    local points = drawing.points
    local long = #points >= 4
    if long and drawing.kind ~= "pen" then
        local x1, y1 = Screen(drawing.surface, drawing.map, points[1], points[2])
        local x2, y2 = Screen(drawing.surface, drawing.map, points[3], points[4])
        long = x1 and x2 and math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) >= Draw.LEAST or false
    end
    if long then
        ns.Plans.Add(drawing)
    else
        Redraw(drawing.surface)
    end
end
