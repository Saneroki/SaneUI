local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Art
--  Blizzard's map art, laid over its map's box in the plane: the continent's,
--  and up close the zone's in the middle of the view, over it. A map's art is
--  the game's (C_Map.GetMapArtLayers, GetMapArtLayerTextures): its tiles row by
--  row, the last ones reaching past the art's edge, as Blizzard's map canvas
--  lays them (Blizzard_MapCanvasDetailLayer.lua); here they are cut there.
--
--  Over the terrain (the overlay) the art is half see-through, and the zone's
--  map then stands alone, so the continent's does not show through it twice.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Art = {}
ns.Art = Art

Art.ZONE = 9000 -- the view's height in yards below which the zone in its middle shows its own map
Art.HALF = 0.5  -- the art's opacity over the terrain

local Coords = ns.Coords
local layers = {} -- [uiMapID] = its art (tiles across and down, a tile's part of the map, the files), or false
local layer, pool

function Art.Build(holder)
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    layer:SetFrameLevel(holder:GetFrameLevel() + 2) -- over the terrain
    pool = ns.Canvas.Pool(layer, "ARTWORK")
end

-- A map's art: its first layer, asked of the game once a session; false when it has none.
local function Of(map)
    local art = layers[map]
    if art ~= nil then return art end
    art = false
    local list = Core.Ask(C_Map.GetMapArtLayers, map)
    local info = type(list) == "table" and list[1]
    local files = info and Core.Ask(C_Map.GetMapArtLayerTextures, map, 1)
    if type(files) == "table" and (info.tileWidth or 0) > 0 and (info.tileHeight or 0) > 0
        and (info.layerWidth or 0) > 0 and (info.layerHeight or 0) > 0 then
        art = { across = math.ceil(info.layerWidth / info.tileWidth), down = math.ceil(info.layerHeight / info.tileHeight),
                x = info.tileWidth / info.layerWidth, y = info.tileHeight / info.layerHeight, files = files }
    end
    layers[map] = art
    return art
end

-- One map's art: the tiles that meet the view, at sublevel (the zone's over the continent's).
local function Draw(map, sublevel, view)
    local art, box = Of(map), Coords.Box(map)
    if not art or not box then return end
    local width, height = art.x * box.width, art.y * box.height -- a tile's size in yards
    local right, bottom = box.u + box.width, box.v - box.height
    for row = 1, art.down do
        local v = box.v - (row - 1) * height
        if v > view.bottom and v - height < view.top then
            for column = 1, art.across do
                local u = box.u + (column - 1) * width
                local index = (row - 1) * art.across + column
                local file = art.files[index]
                if file and u < view.right and u + width > view.left then
                    local partX = math.min(1, (right - u) / width)
                    local partY = math.min(1, (v - bottom) / height)
                    ns.Canvas.Put(pool:Get(map * 1000 + index, file, sublevel), u, v, width, height, partX, partY)
                end
            end
        end
    end
end

-- The zone in the middle of the view, close enough: the continent's map says which it is.
local function Zone(view)
    if view.span > Art.ZONE then return nil end
    local box = Coords.Box(view.map)
    local x, y = Coords.ToMap(box, view.u, view.v)
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    local info = Core.Ask(C_Map.GetMapInfoAtPosition, view.map, x, y)
    if type(info) == "table" and info.mapType == Coords.ZONE and info.mapID ~= view.map then return info.mapID end
    return nil
end

-- The art in view (view: Canvas.view): "full" over everything, "half" see-through over the terrain, nil none.
function Art.Place(view, mode)
    pool:Begin()
    if mode then
        layer:SetAlpha(mode == "half" and Art.HALF or 1)
        local zone = Zone(view)
        if not (zone and mode == "half") then Draw(view.map, 0, view) end
        if zone then Draw(zone, 1, view) end
    end
    pool:End()
end

-- Every tile let go.
function Art.Clear()
    pool:Begin()
    pool:End()
end
