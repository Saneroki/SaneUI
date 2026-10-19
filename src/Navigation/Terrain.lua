local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Terrain
--  The land as the minimap shows it, at every zoom, in two levels of detail:
--
--      tiles      the game's own minimap textures, one of 512 x 512 per tile of a continent's
--                 grid (Coords.lua); which file a tile shows is Core's data, the set Tiles (pack
--                 World). Drawn while at most Terrain.CAP of them are in view.
--      overview   the same tiles at 64 x 64 texels, eight by eight in one texture of the module's
--                 own (Art/Terrain/<continent>-<row>-<column>.blp, made by dev/tools/terrain-art):
--                 a whole continent in a few dozen textures. Always drawn, under the tiles, so the
--                 land never goes black while the tiles load; far out it is the terrain alone.
--
--  Zoomed out to the world, every continent's overview is laid where the world
--  map puts it (Coords.Link). Until the set Tiles is there the layer draws
--  nothing, and draws once it arrives.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Terrain = {}
ns.Terrain = Terrain

Terrain.CAP = 400  -- the most tiles drawn at once (each a texture of 512 x 512, loaded while in view)
Terrain.BLOCK = 8  -- tiles along each side of one texture of the overview
Terrain.PATH = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Terrain\\%d-%d-%d"
local OVERVIEW = 100000 -- the overview's keys in the pool, past every tile's

local Coords = ns.Coords
local Tiles = Core.Data.Set("Tiles")
local files = {}  -- [tile key] = its texture's file ID, or false: none; asked of the set once a tile
local blocks = {} -- [overview key] = its file's path, or false: the block holds no tile
local pool

-- The set arrived (or changed): asked anew, drawn anew.
local function Arrived()
    wipe(files)
    wipe(blocks)
    ns.Canvas.Refresh()
end

function Terrain.Build(holder)
    local layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    layer:SetFrameLevel(holder:GetFrameLevel() + 1)
    pool = ns.Canvas.Pool(layer, "BACKGROUND")
    Tiles:OnStamp(ns.Guard(Arrived))
end

local function File(key)
    local file = files[key]
    if file == nil then
        file = Tiles:Get(key, "minimap") or false
        files[key] = file
    end
    return file
end

-- The overview's texture of a block of tiles: its path, or false when the block holds no tile.
local function Block(continent, row, column)
    local key = OVERVIEW + continent * 64 + row * Terrain.BLOCK + column
    local path = blocks[key]
    if path == nil then
        path = false
        local size = Terrain.BLOCK
        for r = row * size, row * size + size - 1 do
            for c = column * size, column * size + size - 1 do
                if File(Coords.TileKey(continent, c, r)) then
                    path = Terrain.PATH:format(continent, row, column)
                    break
                end
            end
            if path then break end
        end
        blocks[key] = path
    end
    return path, key
end

-- The range of a continent's grid a rectangle of its plane covers: left, right, top, bottom, clamped.
local function Range(left, right, top, bottom, side)
    local last = Coords.GRID / side - 1
    local c0, r0 = Coords.Tile(left, top)
    local c1, r1 = Coords.Tile(right, bottom)
    return math.max(0, math.floor(c0 / side)), math.min(last, math.floor(c1 / side)),
           math.max(0, math.floor(r0 / side)), math.min(last, math.floor(r1 / side))
end

-- One continent's overview, laid by link into the view's plane.
local function Overview(view, continentMap, link)
    local box = Coords.Box(continentMap)
    if not box then return end
    local su, sv = link.su, link.sv
    -- The view in that continent's own plane.
    local left, right = (view.left - link.du) / su, (view.right - link.du) / su
    local top, bottom = (view.top - link.dv) / sv, (view.bottom - link.dv) / sv
    local c0, c1, r0, r1 = Range(left, right, top, bottom, Terrain.BLOCK)
    local side = Coords.TILE * Terrain.BLOCK
    for row = r0, r1 do
        for column = c0, c1 do
            local path, key = Block(box.continent, row, column)
            if path then
                local u, v = Coords.Corner(column * Terrain.BLOCK, row * Terrain.BLOCK)
                ns.Canvas.Put(pool:Get(key, path, 0), link.du + su * u, link.dv + sv * v, side * su, side * sv)
            end
        end
    end
end

-- The game's own tiles of the view's continent, if few enough are in view; true when drawn.
local function Detail(view)
    local c0, c1, r0, r1 = Range(view.left, view.right, view.top, view.bottom, 1)
    local count = 0
    for row = r0, r1 do
        for column = c0, c1 do
            if File(Coords.TileKey(view.continent, column, row)) then count = count + 1 end
        end
        if count > Terrain.CAP then return false end
    end
    local side = Coords.TILE
    for row = r0, r1 do
        for column = c0, c1 do
            local key = Coords.TileKey(view.continent, column, row)
            local file = File(key)
            if file then
                local u, v = Coords.Corner(column, row)
                ns.Canvas.Put(pool:Get(key, file, 1), u, v, side, side)
            end
        end
    end
    return true
end

-- The terrain in view (view: Canvas.view), if shown. At the world, every continent's overview; else the
-- view's continent, its overview and, close enough, its tiles over it.
function Terrain.Place(view, shown)
    pool:Begin()
    if shown and not Tiles:Ready() then
        Core.Data.Prepare("Tiles")
    elseif shown then
        if view.level == "world" then
            for _, continent in ipairs(Coords.Continents()) do
                local link = Coords.Link(continent, view.map)
                if link then Overview(view, continent, link) end
            end
        else
            Overview(view, view.map, Coords.Link(view.map, view.map))
            Detail(view)
        end
    end
    pool:End()
end

-- Every texture let go.
function Terrain.Clear()
    pool:Begin()
    pool:End()
end
