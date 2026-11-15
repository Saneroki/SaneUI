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
--                  where it began, its edge where it is let go), eraser (a click on a drawing: away); in the
--                  palette's colour and width, into the active plan. While a tool is on the left button is the
--                  tool's, a drag with the right one moves the map (a right click still steps out)
--      on the map  the game's lines in the drawing's colour over a dark edge, as thick on the screen at every
--                  zoom; an arrow's head and a circle drawn of lines too; cut at the view's edge by hand (the game
--                  does not cut a line at a frame's edge)
--      a floor     the same over a dungeon's art, its points on the floor's own map (0 to 1), moved and zoomed
--                  with it; your markers on it in their icons with their titles, a click their card
--
--      Draw.Tool(), Draw.SetTool(key), Draw.Colour(), Draw.SetColour(key), Draw.Width(), Draw.SetWidth(1 | 2)
--      Draw.Build(holder), Draw.Place(view, small), Draw.Fit(edge), Draw.Clear()     the canvas' layer sketch
--      Draw.Floor(frame, map, art, scale, midX, midY, small), Draw.FloorClear()      a dungeon's floor
--      Draw.Press(), Draw.PressFloor(), Draw.Busy(), Draw.Release()                  the mouse (Canvas, Dungeons)
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Draw = {}
ns.Draw = Draw

Draw.TOOLS = { "marker", "pen", "line", "arrow", "circle", "move", "erase" }
Draw.THICK = { 3, 6 }   -- a drawing's thickness in units, thin and thick
Draw.EDGE = 2           -- units of dark edge round it
Draw.STEP = 4           -- units the mouse goes before a pen's next point
Draw.LEAST = 4          -- units a line, an arrow or a circle's radius is long at least
Draw.REACH = 8          -- units from a drawing the eraser takes it
Draw.HEAD = 12          -- units an arrow's head is long (and its width's share more)
Draw.SPREAD = 0.45      -- radians an arrow's head opens to each side
Draw.SIDES = 40         -- a circle's sides
Draw.PIN = 24           -- a marker on a dungeon's floor
Draw.GRAB = 14          -- units from a marker's middle the Move tool takes it
Draw.WHITE = "Interface\\Buttons\\WHITE8X8"
Draw.TEXT = {
    noPlace = "Nothing to draw on here: zoom in onto a zone.",
    full = "That is all a stroke takes: let go and begin another.",
}

local tool        -- the tool on (nil: none, the map's own mouse)
local current     -- the drawing under way: { surface, map, kind, colour, width, points, sx, sy (its last point on
                  -- the screen) }
local stroker     -- the frame whose OnUpdate follows the mouse while a drawing is under way, or one is dragged
local held        -- what the Move tool drags (Saneroki, 2026-11-15: "make it possible that map markers are draggable
                  -- so you can move them to a different position"): { surface, thing (a marker or a drawing), marker
                  -- (true for a marker), x, y (a drawing's: the mouse's last point on its map), sx, sy (a marker's last
                  -- place on the screen) }

-------------------------------------------------------------------------------
--  The palette's choices
-------------------------------------------------------------------------------
function Draw.Tool()
    return tool
end

-- A tool on (one of Draw.TOOLS), or none (nil): the map's mouse its own again.
function Draw.SetTool(key)
    tool = key
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

function Draw.Width()
    return ns.store.drawWidth == 2 and 2 or 1
end

function Draw.SetWidth(width)
    ns.store.drawWidth = width == 2 and 2 or 1
    if ns.DrawBar and ns.DrawBar.Update then ns.DrawBar.Update() end
end

-------------------------------------------------------------------------------
--  Lines on a surface
-------------------------------------------------------------------------------
-- A surface: the frame its lines are made in and anchored to (anchor: their points from its middle), its lines'
-- pool, and what was placed (each segment's ends on the screen, unclipped, its drawing, thickness and colour).
local function Surface(parent, anchor)
    return { frame = parent, anchor = anchor, lines = {}, used = 0, placed = {} }
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
end

-- A drawing's segments on the screen (ToScreen: a point of its map to the surface's units, nil off it): a pen's
-- strokes, a line, an arrow with its head, a circle of Draw.SIDES sides.
local function Segments(drawing, ToScreen, out)
    local points = drawing.points
    local screen = {}
    for index = 1, #points - 1, 2 do
        local x, y = ToScreen(drawing.map, points[index], points[index + 1])
        if not x then return end
        screen[#screen + 1] = x
        screen[#screen + 1] = y
    end
    local thick = Draw.THICK[drawing.width == 2 and 2 or 1]
    local rgb = ns.Plans.Colour(drawing.colour)
    local function Add(x1, y1, x2, y2)
        out[#out + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2, thick = thick, rgb = rgb, drawing = drawing }
    end
    local kind = drawing.kind
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
    for _, drawing in ipairs(Shown(nil)) do
        if type(drawing.map) == "number" then Segments(drawing, OnCanvas, canvas.placed) end
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
    -- with the Move tool on, pressed: dragged (Hold); let go: put down; else a click opens its card
    button:SetScript("OnMouseDown", ns.Guard(function(self, mouse)
        if mouse == "LeftButton" and tool == "move" and self.marker then Hold("floor", self.marker) end
    end))
    button:SetScript("OnMouseUp", ns.Guard(function(_, mouse)
        if mouse == "LeftButton" and held then Draw.Release() end
    end))
    button:SetScript("OnClick", ns.Guard(function(self)
        if tool == "move" then return end
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
    for _, drawing in ipairs(Shown(map)) do Segments(drawing, OnFloor, floor.placed) end
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

-- The eraser: the drawing nearest the mouse within Draw.REACH units, away.
local function Erase(surface, sx, sy)
    local best = Nearest(surface, sx, sy)
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
        held.sx, held.sy = sx, sy
        thing.map, thing.x, thing.y = spot.map, spot.x, spot.y
        return ns.Markers.Changed()
    end
    local x, y = MouseOn(held.surface, thing.map)
    if not x or (x == held.x and y == held.y) then return end
    local dx, dy, points = x - held.x, y - held.y, thing.points
    for index = 1, #points - 1, 2 do points[index], points[index + 1] = points[index] + dx, points[index + 1] + dy end
    held.x, held.y = x, y
    Redraw(held.surface)
end
local dragged = ns.Guard(Drag) -- made once

-- The Move tool takes a marker or a drawing on a surface; held until the button is let go (Draw.Release).
local function Hold(surface, marker, drawing)
    if not (marker or drawing) then return end
    held = { surface = surface, thing = marker or drawing, marker = marker ~= nil }
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
    if tool == "marker" then
        if map and x then return ns.Markers.New({ map = map, x = x, y = y }) end
        return UIErrorsFrame:AddMessage(Draw.TEXT.noPlace, 1, 0.1, 0.1)
    end
    if tool == "erase" or tool == "move" then
        local sx, sy
        if map and x then sx, sy = Screen(surface, map, x, y) end
        if not sx then return end
        if tool == "erase" then return Erase(surface, sx, sy) end
        -- the Move tool: the marker under the mouse first (they stand over the drawings), else the drawing
        local marker = MarkerAt(surface, sx, sy)
        Hold(surface, marker, not marker and Nearest(surface, sx, sy) or nil)
        return
    end
    if not (map and x) then return UIErrorsFrame:AddMessage(Draw.TEXT.noPlace, 1, 0.1, 0.1) end
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
        -- what the Move tool held: put down where the mouse let go of it (kept as it is: the saved settings hold it)
        Drag()
        local was = held
        held = nil
        if stroker then stroker:SetScript("OnUpdate", nil) end
        if was.marker then return ns.Markers.Changed() end
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
