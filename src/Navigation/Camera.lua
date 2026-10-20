local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Camera
--  Where a view looks. Each view has its own (the small window and the full
--  screen keep their own zoom and place). Knows no frames: the canvas gives it
--  the mouse's moves in its units, x to the right and y up, and draws what it
--  says.
--
--      map          the plane it looks in (Coords.lua): a continent's, or a plane of its own (Zephras Isle)
--      u, v, k      the point in the view's middle, and the zoom: the canvas' units per yard
--      follow       it keeps the player in the middle; a drag turns it off, some time without the
--                   mouse on the map on again (Canvas.lua)
--      native       the game's minimap's zoom step while the view shows it (Hybrid.lua), else nil
--      level        "zone", "continent" or "world": which map the zoom shows
--
--  Zoomed out past its continent the view shows the whole world, in the same
--  plane (the world map's box in it, Coords.WorldBox); zoomed in again over
--  another continent, it moves into that continent's plane (Settle). The levels
--  change with some slack, so the view does not flicker between two at a
--  border. A plane of its own (Coords.Alone: Zephras Isle) is a zone: its
--  zone's level reaches out to the world, with no continent's between.
-------------------------------------------------------------------------------
local Coords = ns.Coords
local Camera = {}
ns.Camera = Camera

Camera.STEP = 1.25   -- the wheel zooms by so much per notch
Camera.NEAR = 2      -- the nearest zoom of its own: so many units per yard (the game's minimap goes nearer)
Camera.CLOSER = 3    -- the view Atlas goes so many times nearer: its art has four times the terrain's detail
Camera.FIT = 0.9     -- a whole map, stepped out to, in so much of the view
Camera.START = 3000  -- yards the view is high when it first looks at a continent: most of a zone
Camera.ZONE = 9000   -- below so many yards in view's height the zone in the middle is the map shown
Camera.SLACK = 0.15  -- a level is left only so far past where it is entered

local methods = {}

-- The nearest zoom of its own in the view the map is drawn in (Navigation.lua, View).
function Camera.Near()
    if ns.View() == "atlas" then return Camera.NEAR * Camera.CLOSER end
    return Camera.NEAR
end

function Camera.New()
    return setmetatable({ u = 0, v = 0, k = 0.1, width = 1, height = 1, far = 0.001, fit = 0.001, follow = true,
                          level = "continent" }, { __index = methods })
end

-- The farthest zoom and the zoom that fits the continent, from the view's size and the boxes.
local function Limits(self)
    local box = self.map and Coords.Box(self.map)
    if not box then return end
    self.box, self.world, self.alone = box, Coords.WorldBox(self.map), Coords.Alone(self.map)
    self.fit = math.min(self.width / box.width, self.height / box.height) * Camera.FIT
    local whole = self.world
    self.far = whole and math.min(self.width / whole.width, self.height / whole.height) * Camera.FIT or self.fit
end

-- The level the zoom shows, with slack at each border.
local function Level(self)
    local span = self.height / self.k
    if self.world and (self.k < self.fit * (1 - Camera.SLACK) or (self.level == "world" and self.k < self.fit)) then
        return "world"
    end
    if self.alone or span < Camera.ZONE or (self.level == "zone" and span < Camera.ZONE * (1 + Camera.SLACK)) then
        return "zone"
    end
    return "continent"
end

-- The zoom within its bounds, the middle on the map shown (the plane's, or the world).
local function Clamp(self)
    local box = self.level == "world" and self.world or self.box
    if not box then return end
    local near = self.native and self.k or Camera.Near()
    self.k = math.max(self.far, math.min(near, self.k))
    self.u = math.max(box.u, math.min(box.u + box.width, self.u))
    self.v = math.min(box.v, math.max(box.v - box.height, self.v))
end

-- Into another plane, keeping the view's place and size on the screen.
function methods:Move(map)
    local link = Coords.Link(self.map, map)
    if not link or not Coords.Box(map) then return false end
    self.u, self.v = link.du + link.su * self.u, link.dv + link.sv * self.v
    self.k = self.k / math.sqrt(link.su * link.sv) -- the world map draws a continent alike both ways
    self.map = map
    Limits(self)
    return true
end

-- Whether a point of the plane lies in a box.
local function Over(box, u, v)
    return u >= box.u and u <= box.u + box.width and v <= box.v and v >= box.v - box.height
end

-- After every change: the level, and coming in from the world over another continent or a plane of its own, its
-- plane. At the world off a plane of its own (not while following the player, who is on it), the plane under the
-- middle at once: over a continent the world is left at that continent's zoom, not at the isle's.
function methods:Settle()
    local level = Level(self)
    local away = self.alone and not self.follow and self.level == "world" and not Over(self.box, self.u, self.v)
    if self.level == "world" and (level ~= "world" or away) then
        local under = Coords.PlaneAt(self.map, self.u, self.v)
        if under and under ~= self.map and self:Move(under) then
            if not away then self.level = nil end -- coming in: its own level, as if come to anew
            level = Level(self)
        end
    end
    self.level = level
    Clamp(self)
end

-- The view's size in units: the zoom that fits a whole continent, and the world, follows from it.
function methods:Frame(width, height)
    self.width, self.height = width, height
    Limits(self)
    self:Settle()
end

-- Looks at a point of the plane (k optional: as it is).
function methods:Look(u, v, k)
    self.u, self.v = u, v
    if k then self.k = k end
    self:Settle()
end

-- Looks at a plane: there, at that zoom (default: as it is, or about a zone the first time).
function methods:Show(map, u, v, k)
    local box = Coords.Box(map)
    if not box then return false end
    local first = not self.map
    self.map = map
    Limits(self)
    self.level = "continent"
    self:Look(u or box.u + box.width / 2, v or box.v - box.height / 2, k or (first and self.height / Camera.START) or self.k)
    return true
end

-- Looks at a whole map: a continent or a zone fitted into the view (in its plane), the world map fitted too.
function methods:Fit(map)
    if map == Coords.WorldMap() then
        if not self.world then return false end
        local box = self.world
        self.follow, self.native = false, nil
        self.level = "world"
        self:Look(box.u + box.width / 2, box.v - box.height / 2, self.far)
        return true
    end
    local box, plane = Coords.Box(map), Coords.PlaneOf(map)
    if not box or not plane then return false end
    if plane ~= self.map then
        self.map = plane
        Limits(self)
    end
    local u, v = Coords.ToPlane(box, 0.5, 0.5)
    self.follow, self.native = false, nil
    self.level = map == plane and not self.alone and "continent" or "zone"
    self:Look(u, v, math.min(self.width / box.width, self.height / box.height) * Camera.FIT)
    return true
end

-- The map dragged by dx, dy units: what was under the mouse stays under it; the view stops following (a
-- step of the game's minimap stays: it shows again once the view follows again).
function methods:Pan(dx, dy)
    self.follow = false
    self.u, self.v = self.u - dx / self.k, self.v - dy / self.k
    self:Settle()
end

-- Zoomed by notches of the wheel (up: nearer) around the point dx, dy units from the view's middle; a view
-- that follows zooms around its middle, the player.
function methods:ZoomAt(notches, dx, dy)
    self.native = nil
    if self.follow then dx, dy = 0, 0 end
    local u, v = self.u + dx / self.k, self.v + dy / self.k
    local k = math.max(self.far, math.min(Camera.Near(), self.k * Camera.STEP ^ notches))
    self.u, self.v, self.k = u - dx / k, v - dy / k, k
    self:Settle()
end

-- One map out (the game's right click on its map): from a zone its continent whole, from a continent (or a
-- plane of its own) the world whole. False at the world.
function methods:StepOut()
    if self.level == "zone" and not self.alone then
        self.native = nil
        local box = self.box
        self.follow = false
        self.level = "continent"
        self:Look(box.u + box.width / 2, box.v - box.height / 2, self.fit)
        return true
    elseif self.level ~= "world" and self.world then
        self.native, self.follow = nil, false
        local box = self.world
        self.level = "world"
        self:Look(box.u + box.width / 2, box.v - box.height / 2, self.far)
        return true
    end
    return false
end

-- What is in view, and margin units past it on every side: left, right, top, bottom in the plane.
function methods:View(margin)
    local across, high = (self.width / 2 + margin) / self.k, (self.height / 2 + margin) / self.k
    return self.u - across, self.u + across, self.v + high, self.v - high
end
