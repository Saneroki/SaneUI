local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Camera
--  Where a view looks: the point of the plane in its middle (u, v), its zoom
--  (k: the canvas' units per yard) and its bounds (a continent's box, the
--  view's size). Knows no frames: the canvas gives it the mouse's moves in its
--  units, x to the right and y up, and draws what it says.
--
--      local camera = ns.Camera.New()
--      camera:Frame(box, width, height)   -- the continent it looks at, the view's size: its bounds
--      camera:Look(u, v, k)               -- there, at that zoom (k optional)
--      camera:Pan(dx, dy)                 -- the map dragged by so much
--      camera:ZoomAt(notches, dx, dy)     -- the wheel: the point under the mouse stays where it is
--      camera:View(margin)                -- left, right, top, bottom of what is in view, in the plane
-------------------------------------------------------------------------------
local Camera = {}
ns.Camera = Camera

Camera.STEP = 1.25   -- the wheel zooms by so much per notch
Camera.NEAR = 2      -- the nearest zoom: so many units per yard (a terrain tile, 533 yards, about 1000 units)
Camera.FIT = 0.9     -- the farthest: the whole continent, in so much of the view
Camera.START = 3000  -- yards the view is high when it first looks at a continent: most of a zone

local methods = {}

function Camera.New()
    return setmetatable({ u = 0, v = 0, k = 0.1, width = 1, height = 1, far = 0.001 }, { __index = methods })
end

-- The zoom within its bounds, and the middle on the continent.
function methods:Clamp()
    self.k = math.max(self.far, math.min(Camera.NEAR, self.k))
    local box = self.box
    if box then
        self.u = math.max(box.u, math.min(box.u + box.width, self.u))
        self.v = math.min(box.v, math.max(box.v - box.height, self.v))
    end
end

-- The continent it looks at (its box) and the view's size in units: the farthest zoom shows all of it.
function methods:Frame(box, width, height)
    self.box, self.width, self.height = box, width, height
    self.far = math.min(width / box.width, height / box.height) * Camera.FIT
    self:Clamp()
end

function methods:Look(u, v, k)
    self.u, self.v = u, v
    if k then self.k = k end
    self:Clamp()
end

-- The map dragged by dx, dy units: what was under the mouse stays under it.
function methods:Pan(dx, dy)
    self.u, self.v = self.u - dx / self.k, self.v - dy / self.k
    self:Clamp()
end

-- Zoomed by notches of the wheel (up: nearer) around the point dx, dy units from the view's middle.
function methods:ZoomAt(notches, dx, dy)
    local u, v = self.u + dx / self.k, self.v + dy / self.k
    local k = math.max(self.far, math.min(Camera.NEAR, self.k * Camera.STEP ^ notches))
    self.u, self.v, self.k = u - dx / k, v - dy / k, k
    self:Clamp()
end

-- What is in view, and margin units past it on every side: left, right, top, bottom in the plane.
function methods:View(margin)
    local across, high = (self.width / 2 + margin) / self.k, (self.height / 2 + margin) / self.k
    return self.u - across, self.u + across, self.v + high, self.v - high
end
