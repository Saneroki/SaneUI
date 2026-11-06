local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Indoors
--  Inside a building or a cave (Live.Indoors: the game's IsIndoors, or its
--  minimap showing its indoor plan, as in Ironforge's halls and the Undercity,
--  which the game counts as outdoors), its indoor map over our map, whatever
--  the view: the game's own indoor pictures with their black taken out (made by
--  dev/tools/indoor-art into Art/Indoors/), placed by Core's set Indoors (where
--  each part's picture lies in the building, where each building stands, its
--  turn and scale; the set's schema has the formula).
--
--      which building   the one whose part holds the player's place (UnitPosition), of those on the
--                       terrain tile the player stands on (the set's index byTile). Only inside buildings
--                       and caves, never on a street (Saneroki, 2026-10-21): where the part the player
--                       stands in (the smallest that holds their place and height) is one under the sky
--                       though the game counts it indoors (open: Stormwind's and Orgrimmar's streets and
--                       squares, the cities being one building each), that building is passed over
--      which parts      those whose height reaches the player's (from Indoors.BELOW under their floor
--                       to their top), the one whose floor lies nearest below the player drawn on top;
--                       without the player's height, every part with the game's indoor flag; never an
--                       open one (a street keeps the map's own art)
--      turned           a picture is drawn as the square the canvas lays out any texture in (its box in
--                       the plane), its texture coordinates turned inside it to the building's turn, and
--                       what lies outside the picture clear (the texture's wrap)
--
--  Laid out with the map (Place); the tracker's steps (Track) look again a few
--  times a second whether the player has gone to another building or floor (not
--  while the player stands still). Outdoors nothing is drawn, nor on the view of
--  another continent than the one the player is on. Knows the canvas' view, as
--  the other layers do.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Coords = ns.Coords
local Indoors = {}
ns.Indoors = Indoors

Indoors.PATH = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Indoors\\%s"
Indoors.BELOW = 1    -- yards under a part's floor the player still stands on it (the box is the part's walls)
Indoors.LOOK = 0.25  -- seconds between two looks at where the player is inside
Indoors.DRAW = "ARTWORK"

local SET = Core.Data.Set("Indoors")
local layer, holder
local used, free = {}, {} -- [key] = texture while drawn; textures let go
local seen = {}
local shown          -- what is drawn: the building's key and placement, and the parts, as one word (Track)
local nextLook = 0
local lastX, lastY, lastZ, lastInstance -- where the player was at the tracker's last look: no look while still there

function Indoors.Build(canvasHolder)
    holder = canvasHolder
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    SET:OnStamp(ns.Guard(function() ns.Canvas.Refresh() end)) -- arrived: drawn if the player is inside
    return layer
end

-- The player in the world: x (north), y (west), the height and the instance (the continent's), from the game; the
-- height nil where it tells none, the instance nil where it does not say.
local function Here()
    local position = rawget(_G, "UnitPosition")
    if not position then return nil end
    local ok, x, y, z, instance = pcall(position, "player") -- four answers: Core.Ask hands on three
    if not ok then return nil end
    x, y, z, instance = Core.Plain(x), Core.Plain(y), Core.Plain(z), Core.Plain(instance)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end
    if type(z) ~= "number" or z == 0 then z = nil end
    return x, y, z, type(instance) == "number" and instance or nil
end

-- A world point (x, y, z) in a placed building's own space: bx, by, and bz when z is known.
local function Local(placed, x, y, z)
    local turn = math.rad(placed.yaw or 0)
    local cos, sin, scale = math.cos(turn), math.sin(turn), placed.scale or 1
    local a, b = (placed.x - x) / scale, (placed.y - y) / scale
    return a * cos + b * sin, -a * sin + b * cos, z and placed.z and (z - placed.z) / scale or nil
end

-- A building's own point (bx, by) in the plane: u (east), v (north).
local function Plane(placed, bx, by)
    local turn = math.rad(placed.yaw or 0)
    local cos, sin, scale = math.cos(turn), math.sin(turn), placed.scale or 1
    local x = placed.x - scale * (bx * cos - by * sin)
    local y = placed.y - scale * (bx * sin + by * cos)
    return -y, x
end

local function Within(part, bx, by)
    return bx >= part.left and bx <= part.right and by >= part.bottom and by <= part.top
end

-- The part the player stands in: the smallest whose square holds their place and, where their height is known,
-- whose height does; nil for none.
local function Standing(record, bx, by, bz)
    local best, least
    for _, part in ipairs(record.groups or {}) do
        if Within(part, bx, by) and (not bz or (bz >= part.low - Indoors.BELOW and bz <= part.high)) then
            local size = (part.right - part.left) * (part.top - part.bottom)
            if not least or size < least then best, least = part, size end
        end
    end
    return best
end

-- The floor nearest below the player last, so it is drawn over the others.
local function Lower(one, other)
    return one.low < other.low
end

-- The building the player stands in on the view's continent, and the parts to draw: placed, parts (in drawing
-- order, the one on top last), or nil outdoors, off the data, on another continent, or in none of its buildings.
function Indoors.Inside(continent)
    if not ns.Live.Indoors() or not SET:Ready() then return nil end
    local x, y, z, instance = Here()
    if not x or (instance and instance ~= continent) then return nil end
    local column, row = Coords.Tile(-y, x)
    for _, key in ipairs(SET:Keys("byTile", Coords.TileKey(continent, column, row))) do
        local record = SET:Get(key)
        for _, placed in ipairs(record and record.placed or {}) do
            if placed.map == continent then
                local bx, by, bz = Local(placed, x, y, z)
                local holds
                for _, part in ipairs(record.groups or {}) do
                    if Within(part, bx, by) then holds = true break end
                end
                local here = holds and Standing(record, bx, by, bz)
                if holds and not (here and here.open) then
                    local parts = {}
                    for _, part in ipairs(record.groups or {}) do
                        if part.open then -- a street keeps the map's own art, also seen from a building
                        elseif bz then
                            if bz >= part.low - Indoors.BELOW and bz <= part.high then parts[#parts + 1] = part end
                        elseif not part.outdoor then
                            parts[#parts + 1] = part
                        end
                    end
                    table.sort(parts, Lower)
                    return placed, parts, key
                end
            end
        end
    end
    return nil
end

-- A part's texture, its square in the plane and the texture coordinates of that square's corners: the picture
-- turned inside it, clear around it.
local function Draw(view, placed, part, sublevel, key)
    local corners = { { part.left, part.top }, { part.left, part.bottom }, { part.right, part.top }, { part.right, part.bottom } }
    local left, right, bottom, top
    for _, corner in ipairs(corners) do
        local u, v = Plane(placed, corner[1], corner[2])
        left, right = math.min(left or u, u), math.max(right or u, u)
        bottom, top = math.min(bottom or v, v), math.max(top or v, v)
    end
    local texture = used[key]
    if not texture then
        texture = table.remove(free) or layer:CreateTexture(nil, Indoors.DRAW)
        texture:SetTexture(Indoors.PATH:format(part.file), "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "TRILINEAR")
        used[key] = texture
    end
    seen[key] = true
    texture:SetDrawLayer(Indoors.DRAW, sublevel)
    local k = view.k
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", holder, "CENTER", (left - view.u) * k, (top - view.v) * k)
    texture:SetSize((right - left) * k, (top - bottom) * k)
    -- Each corner of the square in the picture's coordinates (0 to 1 across it, its top row 0).
    local width, height = part.right - part.left, part.top - part.bottom
    local function Coord(u, v)
        local bx, by = Local(placed, v, -u)
        return (bx - part.left) / width, (part.top - by) / height
    end
    local ulx, uly = Coord(left, top)
    local llx, lly = Coord(left, bottom)
    local urx, ury = Coord(right, top)
    local lrx, lry = Coord(right, bottom)
    texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
    texture:Show()
end

local function Release()
    for key, texture in pairs(used) do
        if not seen[key] then
            texture:Hide()
            texture:SetTexture(nil)
            used[key] = nil
            free[#free + 1] = texture
        end
    end
end

-- Drawn for the view as the canvas laid it out: the building the player is in, the parts at the player's height.
function Indoors.Place(view)
    wipe(seen)
    shown = nil
    if view.continent and not SET:Ready() and ns.Live.Indoors() then Core.Data.Prepare("Indoors") end
    local placed, parts, building
    if view.continent then placed, parts, building = Indoors.Inside(view.continent) end
    if placed then
        local words = { building, placed.x, placed.y }
        for index, part in ipairs(parts) do
            -- The draw layer's sublevels: the last part on top, the others under it.
            Draw(view, placed, part, math.max(-8, 7 - (#parts - index)), building .. ":" .. part.group)
            words[#words + 1] = part.group
        end
        shown = table.concat(words, ":")
    end
    Release()
end

-- A step of the canvas' tracker: whether the player went into another building or onto another floor, a few
-- times a second while the player moves; then drawn anew.
function Indoors.Track(view, now)
    if now < nextLook or not view.continent then return end
    nextLook = now + Indoors.LOOK
    local x, y, z, instance = Here()
    if x == lastX and y == lastY and z == lastZ and instance == lastInstance then return end
    lastX, lastY, lastZ, lastInstance = x, y, z, instance
    local placed, parts, building = Indoors.Inside(view.continent)
    local words
    if placed then
        words = { building, placed.x, placed.y }
        for _, part in ipairs(parts) do words[#words + 1] = part.group end
        words = table.concat(words, ":")
    end
    if words ~= shown then Indoors.Place(view) end
end

-- Every picture let go (the window hidden).
function Indoors.Clear()
    wipe(seen)
    shown = nil
    Release()
end
