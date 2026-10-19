local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Art
--  Blizzard's map art, laid over its map's box in the view's plane, by the
--  level the zoom shows (Camera.lua):
--
--      world       the world map (its box in the plane: Coords.WorldBox)
--      continent   the continent's map
--      zone        the continent's, and the zone's in the middle of the view over it
--
--  A map's art is the game's (C_Map.GetMapArtLayers, GetMapArtLayerTextures): its
--  tiles row by row, the last ones reaching past the art's edge, as Blizzard's map
--  canvas lays them (Blizzard_MapCanvasDetailLayer.lua); here they are cut there.
--  Over a map's art lie its explored parts (C_MapExplorationInfo), placed as
--  Blizzard's exploration provider places them: in the art's own pixels, cut into
--  the layer's tiles (MapExplorationDataProvider.lua).
--
--  Over the terrain (the overlay) the art is half see-through: the zone's map then
--  stands alone, without the continent's under it or its explored parts over it,
--  so nothing shows through twice.
--
--  Under the mouse, a map the view shows whole lights up what a click opens, as
--  Blizzard's map does (MapHighlightDataProvider.lua): at a continent the zone,
--  at the world the continent, in the game's own highlight art
--  (C_Map.GetMapHighlightInfoAtPosition), added onto what is under it, in every view.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Art = {}
ns.Art = Art

Art.HALF = 0.5 -- the art's opacity over the terrain

local Coords = ns.Coords
local arts = {} -- [uiMapID] = its art (tiles across and down, the layer's size and its tiles', the files), or false
local layer, pool, explored, glow, light

function Art.Build(holder)
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    pool = ns.Canvas.Pool(layer, "ARTWORK")
    explored = ns.Canvas.Pool(layer, "ARTWORK")
    -- The highlight on a frame of its own: not half see-through with the art over the terrain.
    glow = CreateFrame("Frame", nil, holder)
    glow:SetSize(1, 1)
    glow:SetPoint("CENTER")
    light = glow:CreateTexture(nil, "ARTWORK")
    if light.SetSnapToPixelGrid then
        light:SetSnapToPixelGrid(false)
        light:SetTexelSnappingBias(0)
    end
    light:SetBlendMode("ADD")
    light:Hide()
    return layer, glow
end

-- A map's art: its first layer, asked of the game once a session; false when it has none.
local function Of(map)
    local art = arts[map]
    if art ~= nil then return art end
    art = false
    local list = Core.Ask(C_Map.GetMapArtLayers, map)
    local info = type(list) == "table" and list[1]
    local files = info and Core.Ask(C_Map.GetMapArtLayerTextures, map, 1)
    if type(files) == "table" and (info.tileWidth or 0) > 0 and (info.tileHeight or 0) > 0
        and (info.layerWidth or 0) > 0 and (info.layerHeight or 0) > 0 then
        art = { across = math.ceil(info.layerWidth / info.tileWidth), down = math.ceil(info.layerHeight / info.tileHeight),
                width = info.layerWidth, height = info.layerHeight, tileWidth = info.tileWidth,
                tileHeight = info.tileHeight, files = files }
    end
    arts[map] = art
    return art
end

-- One map's art over its box: the tiles that meet the view, at sublevel.
local function Draw(map, box, sublevel, view)
    local art = Of(map)
    if not art or not box then return end
    local width, height = art.tileWidth / art.width * box.width, art.tileHeight / art.height * box.height
    local right, bottom = box.u + box.width, box.v - box.height
    for row = 1, art.down do
        local v = box.v - (row - 1) * height
        if v > view.bottom and v - height < view.top then
            for column = 1, art.across do
                local u = box.u + (column - 1) * width
                local index = (row - 1) * art.across + column
                local file = art.files[index]
                if file and u < view.right and u + width > view.left then
                    ns.Canvas.Put(pool:Get(map * 1000 + index, file, sublevel), u, v, width, height,
                        math.min(1, (right - u) / width), math.min(1, (v - bottom) / height))
                end
            end
        end
    end
end

-- The smallest power of two of at least 16 that holds n pixels: the size of an explored part's file.
local function FileSide(n)
    local side = 16
    while side < n do side = side * 2 end
    return side
end

-- A map's explored parts over its art, at sublevel (one higher for those the game draws on top). Those the
-- game shows only under the mouse are left out.
local function Explore(map, box, sublevel, view)
    local art = Of(map)
    if not art or not box then return end
    local scaleU, scaleV = box.width / art.width, box.height / art.height -- yards per pixel of the art
    for number, part in ipairs(ns.Live.Explored(map)) do
        local files = part.fileDataIDs
        if not part.isShownByMouseOver and type(files) == "table" and (part.textureWidth or 0) > 0 then
            local across = math.ceil(part.textureWidth / art.tileWidth)
            local down = math.ceil(part.textureHeight / art.tileHeight)
            local level = sublevel + (part.isDrawOnTopLayer and 1 or 0)
            for row = 1, down do
                local pixelsHigh = art.tileHeight
                if row == down then pixelsHigh = part.textureHeight % art.tileHeight end
                if pixelsHigh == 0 then pixelsHigh = art.tileHeight end
                local v = box.v - (part.offsetY + art.tileHeight * (row - 1)) * scaleV
                for column = 1, across do
                    local pixelsWide = art.tileWidth
                    if column == across then pixelsWide = part.textureWidth % art.tileWidth end
                    if pixelsWide == 0 then pixelsWide = art.tileWidth end
                    local u = box.u + (part.offsetX + art.tileWidth * (column - 1)) * scaleU
                    local file = files[(row - 1) * across + column]
                    local wide, high = pixelsWide * scaleU, pixelsHigh * scaleV
                    if file and u < view.right and u + wide > view.left and v > view.bottom and v - high < view.top then
                        local texture = explored:Get(map * 100000 + number * 100 + (row - 1) * across + column, file, level)
                        local fileWide, fileHigh = FileSide(pixelsWide), FileSide(pixelsHigh)
                        ns.Canvas.Put(texture, u, v, wide * fileWide / pixelsWide, high * fileHigh / pixelsHigh,
                            pixelsWide / fileWide, pixelsHigh / fileHigh)
                    end
                end
            end
        end
    end
end

-- The art in view (view: Canvas.view): "full" over everything, "half" see-through over the terrain, nil none.
function Art.Place(view, mode)
    pool:Begin()
    explored:Begin()
    if mode then
        layer:SetAlpha(mode == "half" and Art.HALF or 1)
        local full = mode == "full"
        if view.level == "world" then
            Draw(Coords.WorldMap(), Coords.WorldBox(view.map), 0, view)
        else
            local zone = view.zone
            local box = Coords.Box(view.map)
            if full or not zone then
                Draw(view.map, box, 0, view)
                if full then Explore(view.map, box, 1, view) end
            end
            if zone then
                local zoneBox = Coords.Box(zone)
                Draw(zone, zoneBox, 3, view)
                if full then Explore(zone, zoneBox, 4, view) end
            end
        end
    end
    pool:End()
    explored:End()
end

-- The highlight out of sight.
function Art.Unlight()
    light:Hide()
end

-- The game's highlight of what is under a point of the view's plane (u, v), on a map the view shows whole:
-- at a continent the zone there, at the world the continent; none at a zone, nor where the game has none.
function Art.Light(view, u, v)
    local map, box
    if view.level == "world" then
        map, box = Coords.WorldMap(), Coords.WorldBox(view.map)
    elseif view.level == "continent" then
        map, box = view.map, Coords.Box(view.map)
    end
    if not map or not box then return Art.Unlight() end
    local x, y = Coords.ToMap(box, u, v)
    if x < 0 or x > 1 or y < 0 or y > 1 then return Art.Unlight() end
    -- Eight answers: Core.Ask hands on three.
    local ok, file, atlas, partX, partY, wide, high, left, top = pcall(C_Map.GetMapHighlightInfoAtPosition, map, x, y)
    if not ok or type(wide) ~= "number" or type(high) ~= "number" or type(left) ~= "number" or type(top) ~= "number" then
        return Art.Unlight()
    end
    if atlas then
        -- An atlas at its own size, in the map art's pixels, centred where the game puts it.
        local info, art = C_Texture.GetAtlasInfo(atlas), Of(map)
        if not info or not art then return Art.Unlight() end
        light:SetAtlas(atlas)
        local across, down = info.width * box.width / art.width, info.height * box.height / art.height
        local u0 = box.u + (left + wide / 2) * box.width - across / 2
        local v0 = box.v - (top + high / 2) * box.height + down / 2
        ns.Canvas.Put(light, u0, v0, across, down)
        light:SetTexCoord(info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord)
    elseif type(file) == "number" and file > 0 and wide > 0 and high > 0 and (partX or 0) > 0 and (partY or 0) > 0 then
        light:SetTexture(file, "CLAMP", "CLAMP", "TRILINEAR")
        ns.Canvas.Put(light, box.u + left * box.width, box.v - top * box.height, wide * box.width / partX,
            high * box.height / partY, partX, partY)
    else
        return Art.Unlight()
    end
    light:Show()
end

-- Every texture let go.
function Art.Clear()
    light:Hide()
    pool:Begin()
    pool:End()
    explored:Begin()
    explored:End()
end
