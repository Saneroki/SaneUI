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
--  The water is cut away, to the canvas' sea: the overview's alpha is the land
--  (the tool reads where the ground lies above the water's surface, fading out
--  in the first yard under it, and keeps what the minimap shows standing on the
--  water: docks, piers, bridges, ships), and the same file is the mask of the
--  game's own tiles of its block, so the coast is cut alike at every zoom. A
--  tile on a coast (Coasts.lua) has a mask of its own at four times that detail
--  (Art/Coasts/<key>.blp), so a pier a few yards wide is not lost up close.
--
--  Every plane's overview (the continents and Zephras Isle, Coords.Planes) is
--  laid where the world map puts it (Coords.Link), at every zoom: the other
--  continent and the isle are there whenever they are in view. Around the isle
--  floats open sky, cut away as the sea is (the tool's alpha). The
--  stitched map of Blizzard's zone maps (Art.lua) is cut into the same blocks
--  and drawn by the same code (Terrain.Overview). Until the set Tiles is there
--  the layer draws nothing, and draws once it arrives.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Terrain = {}
ns.Terrain = Terrain

Terrain.CAP = 400  -- the most tiles drawn at once (each a texture of 512 x 512, loaded while in view)
Terrain.BLOCK = 8  -- tiles along each side of one texture of the overview
Terrain.PATH = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Terrain\\%d-%d-%d"
Terrain.COAST = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Coasts\\%d"
local OVERVIEW = 100000 -- the overview's keys in the pool, past every tile's

local Coords = ns.Coords
local Tiles = Core.Data.Set("Tiles")
local files = {}  -- [tile key] = its texture's file ID, or false: none; asked of the set once a tile
local blocks = {} -- [overview key] = its file's path, or false: the block holds no tile
local pool, masks

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
    pool = ns.Canvas.Pool(layer, "BACKGROUND")
    masks = ns.Canvas.Masks(layer)
    Tiles:OnStamp(ns.Guard(Arrived))
    return layer
end

local function File(key)
    local file = files[key]
    if file == nil then
        file = Tiles:Get(key, "minimap") or false
        files[key] = file
    end
    return file
end

-- Whether a block of tiles holds one (its overview textures exist then), and its key in a pool.
local function Block(continent, row, column)
    local key = OVERVIEW + continent * 64 + row * Terrain.BLOCK + column
    local held = blocks[key]
    if held == nil then
        held = false
        local size = Terrain.BLOCK
        for r = row * size, row * size + size - 1 do
            for c = column * size, column * size + size - 1 do
                if File(Coords.TileKey(continent, c, r)) then
                    held = true
                    break
                end
            end
            if held then break end
        end
        blocks[key] = held
    end
    return held, key
end

-- The range of a continent's grid a rectangle of its plane covers: left, right, top, bottom, clamped.
local function Range(left, right, top, bottom, side)
    local last = Coords.GRID / side - 1
    local c0, r0 = Coords.Tile(left, top)
    local c1, r1 = Coords.Tile(right, bottom)
    return math.max(0, math.floor(c0 / side)), math.min(last, math.floor(c1 / side)),
           math.max(0, math.floor(r0 / side)), math.min(last, math.floor(r1 / side))
end

-- Every plane's blocks in view (the continents and Zephras Isle), laid by link into the view's plane, from a pool
-- at sublevel: the files of path (with the plane's instance, the block's row and column), the terrain's overview
-- or the stitched map's.
function Terrain.Overview(view, from, path, sublevel)
    local side = Coords.TILE * Terrain.BLOCK
    for _, plane in ipairs(Coords.Planes()) do
        local box, link = Coords.Box(plane), Coords.Link(plane, view.map)
        if box and link then
            local su, sv = link.su, link.sv
            -- The view in that plane's own space.
            local left, right = (view.left - link.du) / su, (view.right - link.du) / su
            local top, bottom = (view.top - link.dv) / sv, (view.bottom - link.dv) / sv
            local c0, c1, r0, r1 = Range(left, right, top, bottom, Terrain.BLOCK)
            for row = r0, r1 do
                for column = c0, c1 do
                    local held, key = Block(box.continent, row, column)
                    if held then
                        local u, v = Coords.Corner(column * Terrain.BLOCK, row * Terrain.BLOCK)
                        ns.Canvas.Put(from:Get(key, path:format(box.continent, row, column), sublevel),
                            link.du + su * u, link.dv + sv * v, side * su, side * sv)
                    end
                end
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
    local side, size = Coords.TILE, Terrain.BLOCK
    local coasts = ns.COASTS and ns.COASTS[view.continent] or {}
    for row = r0, r1 do
        for column = c0, c1 do
            local key = Coords.TileKey(view.continent, column, row)
            local file = File(key)
            if file then
                local u, v = Coords.Corner(column, row)
                local mask
                if coasts[key] then
                    -- On a coast: cut by its own mask, over the tile alone.
                    mask = masks:Get(key, Terrain.COAST:format(key), u, v, side, side)
                else
                    -- Else by its block's overview (wholly land or sea), laid over the whole block.
                    local blockRow, blockColumn = math.floor(row / size), math.floor(column / size)
                    local held, blockKey = Block(view.continent, blockRow, blockColumn)
                    if held then
                        local bu, bv = Coords.Corner(blockColumn * size, blockRow * size)
                        mask = masks:Get(blockKey, Terrain.PATH:format(view.continent, blockRow, blockColumn), bu, bv,
                            side * size, side * size)
                    end
                end
                ns.Canvas.Put(pool:Get(key, file, 1, mask), u, v, side, side)
            end
        end
    end
    return true
end

-- The terrain in view (view: Canvas.view), if shown: every plane's overview in view, and, but at the world, the
-- view's continent's (or isle's) own tiles over it when close enough.
function Terrain.Place(view, shown)
    pool:Begin()
    masks:Begin()
    if shown and not Tiles:Ready() then
        Core.Data.Prepare("Tiles")
    elseif shown then
        Terrain.Overview(view, pool, Terrain.PATH, 0)
        if view.level ~= "world" then Detail(view) end
    end
    pool:End()
    masks:End()
end

-- Whether the blocks are known (the set Tiles is there); asked for if not.
function Terrain.Ready()
    if Tiles:Ready() then return true end
    Core.Data.Prepare("Tiles")
    return false
end

-- Every texture let go.
function Terrain.Clear()
    pool:Begin()
    pool:End()
    masks:Begin()
    masks:End()
end
