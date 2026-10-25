local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Art
--  The map drawn by hand: Blizzard's zone maps made one map of the whole world,
--  both continents and Zephras Isle at every zoom (the view Parchment), from the
--  bottom up:
--
--      the world map and each plane's (a continent's, the isle's own), Blizzard's, their paper frames
--                  faded off (Art/Edge.blp): the sea between and around the zones
--      the stitched map   every zone's full map cut to its outline, laid where it lies on its
--                  continent (Art/Sketches/<continent>-<row>-<column>.blp, in the terrain's blocks,
--                  Terrain.Overview): the whole world at once, far out
--      the zones   up close, every zone's map in view itself, cut to its outline (Art/Zones/<uiMapID>.blp,
--                  listed in Outlines.lua), whole up to its border and fading out past it, so the one
--                  over its neighbour fades into it and no line shows; a zone without an outline in the
--                  middle of the view is drawn whole
--
--  Every outline and the stitched map are made by dev/tools/terrain-art from the
--  game's own map chunks, areas and map art. A zone's map is always the full one:
--  its art and every part the game reveals once explored, as Core's set Overlays
--  lists them (until it is there, the parts this character has explored), so the
--  map shows every detail everywhere.
--
--  A map's art is the game's (C_Map.GetMapArtLayers, GetMapArtLayerTextures): its
--  tiles row by row, the last ones reaching past the art's edge, as Blizzard's map
--  canvas lays them (Blizzard_MapCanvasDetailLayer.lua); here they are cut there.
--  A part over it is placed as Blizzard's exploration provider places it: in the
--  art's own pixels, cut into the layer's tiles (MapExplorationDataProvider.lua).
--
--  Under the mouse, a map the view shows whole lights up what a click opens, as
--  Blizzard's map does (MapHighlightDataProvider.lua): at a continent the zone,
--  at the world the continent, in the game's own highlight art
--  (C_Map.GetMapHighlightInfoAtPosition), added onto what is under it, in every view.
--
--  Retail shows one map at a time, as the game's own map does (Camera.Retail.lua,
--  view.shown): that map's art alone, in the layer the zoom asks for (a map may
--  have several, each more detailed: C_Map.GetMapArtLayers, as Blizzard's scroll
--  controller picks them), with its explored parts; what a click opens lights up
--  on it at every level.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Art = {}
ns.Art = Art

Art.OUTLINE = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Zones\\%d"
Art.SKETCH = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Sketches\\%d-%d-%d"
Art.EDGE = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Edge"

local Coords = ns.Coords
local arts = {} -- [uiMapID * 100 + layer] = that layer's art (tiles across and down, the layer's size and its tiles',
                -- the files), or false
local layered = {} -- [uiMapID] = its layers as the game lists them (sizes, scales), or false
local layer, pool, parts, stitched, outlines, glow, light
local Overlays = Core.Data.Set("Overlays")

function Art.Build(holder)
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    pool = ns.Canvas.Pool(layer, "ARTWORK")
    parts = ns.Canvas.Pool(layer, "ARTWORK")
    stitched = ns.Canvas.Pool(layer, "ARTWORK")
    outlines = ns.Canvas.Masks(layer)
    Overlays:OnStamp(ns.Guard(function() ns.Canvas.Refresh() end)) -- arrived: every part drawn
    -- The highlight on a frame of its own: over the map in every view, the art's or not.
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

-- A map's art layers as the game lists them (each { layerWidth, layerHeight, tileWidth, tileHeight, minScale,
-- maxScale }), asked once a session; false when it has none.
function Art.Layers(map)
    local list = layered[map]
    if list ~= nil then return list end
    list = map and Core.Ask(C_Map.GetMapArtLayers, map)
    list = type(list) == "table" and #list > 0 and list or false
    layered[map] = list
    return list
end

-- A map's art: one layer of it (the first unless said), asked of the game once a session; false when it has none.
-- { across, down: its tiles; width, height: the layer's pixels; tileWidth, tileHeight; files: the tiles' files,
-- row by row }
local function Of(map, layer)
    layer = layer or 1
    local key = map and map * 100 + layer
    local art = key and arts[key]
    if art ~= nil then return art end
    art = false
    local list = key and Art.Layers(map)
    local info = list and list[layer]
    local files = info and Core.Ask(C_Map.GetMapArtLayerTextures, map, layer)
    if type(files) == "table" and (info.tileWidth or 0) > 0 and (info.tileHeight or 0) > 0
        and (info.layerWidth or 0) > 0 and (info.layerHeight or 0) > 0 then
        art = { across = math.ceil(info.layerWidth / info.tileWidth), down = math.ceil(info.layerHeight / info.tileHeight),
                width = info.layerWidth, height = info.layerHeight, tileWidth = info.tileWidth,
                tileHeight = info.tileHeight, files = files }
    end
    if key then arts[key] = art end
    return art
end
Art.Of = Of -- the dungeons' maps too (Dungeons.lua), and Retail's camera (its nearest zoom)

-- One map's art over its box: the tiles that meet the view, at sublevel; cut by mask, if given. under: drawn under
-- the stitched map (Under), in textures of its own, so the same map can be drawn over it too (the isle, a zone).
-- layer: which of its layers (the first unless said).
local function Draw(map, box, sublevel, view, mask, under, layer)
    local art = Of(map, layer)
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
                    local key = (map * 1000 + index) * 10 + (layer or 1) - 1
                    ns.Canvas.Put(pool:Get(under and -key or key, file, sublevel, mask), u, v, width, height,
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

-- One part of a map's art (x, y: its top left corner, width and height: its size, in the art's pixels;
-- files: its textures, row by row) over the map's box, from a pool at level, cut by mask, if given; key: the
-- part's first texture's key in the pool. Placed as Blizzard's exploration provider places it: in the art's
-- own pixels, cut into the art's tiles, each texture's file a power of two (MapExplorationDataProvider.lua).
local function Lay(from, key, art, box, x, y, width, height, files, level, view, mask)
    local scaleU, scaleV = box.width / art.width, box.height / art.height -- yards per pixel of the art
    local across, down = math.ceil(width / art.tileWidth), math.ceil(height / art.tileHeight)
    for row = 1, down do
        local pixelsHigh = art.tileHeight
        if row == down then pixelsHigh = height % art.tileHeight end
        if pixelsHigh == 0 then pixelsHigh = art.tileHeight end
        local v = box.v - (y + art.tileHeight * (row - 1)) * scaleV
        for column = 1, across do
            local pixelsWide = art.tileWidth
            if column == across then pixelsWide = width % art.tileWidth end
            if pixelsWide == 0 then pixelsWide = art.tileWidth end
            local u = box.u + (x + art.tileWidth * (column - 1)) * scaleU
            local file = files[(row - 1) * across + column]
            local wide, high = pixelsWide * scaleU, pixelsHigh * scaleV
            if file and u < view.right and u + wide > view.left and v > view.bottom and v - high < view.top then
                local texture = from:Get(key + (row - 1) * across + column, file, level, mask)
                local fileWide, fileHigh = FileSide(pixelsWide), FileSide(pixelsHigh)
                ns.Canvas.Put(texture, u, v, wide * fileWide / pixelsWide, high * fileHigh / pixelsHigh,
                    pixelsWide / fileWide, pixelsHigh / fileHigh)
            end
        end
    end
end

-- Every part of a map's art the game reveals once explored, over its art at sublevel, cut by mask, if given:
-- the full map, whatever this character has explored (Core's set Overlays). Until the set is there, the
-- parts the game says are explored (but those it shows only under the mouse).
local function Parts(map, box, sublevel, view, mask)
    local art = Of(map)
    if not art or not box then return end
    if Overlays:Ready() then
        for _, key in ipairs(Overlays:Keys("byMap", map)) do
            local part = Overlays:Get(key)
            if part and part.files then
                Lay(parts, key * 100, art, box, part.x, part.y, part.width, part.height, part.files, sublevel, view, mask)
            end
        end
        return
    end
    Core.Data.Prepare("Overlays")
    for number, part in ipairs(ns.Live.Explored(map)) do
        local files = part.fileDataIDs
        if not part.isShownByMouseOver and type(files) == "table" and (part.textureWidth or 0) > 0 then
            Lay(parts, map * 100000 + number * 100, art, box, part.offsetX, part.offsetY, part.textureWidth,
                part.textureHeight, files, sublevel + (part.isDrawOnTopLayer and 1 or 0), view, mask)
        end
    end
end

-- Whether a box meets what the view lays out.
local function Meets(box, view)
    return box.u < view.right and box.u + box.width > view.left and box.v > view.bottom and box.v - box.height < view.top
end

-- The zones' art at the zone's level: each zone with an outline that meets the view, cut to it; the zone in
-- the middle whole if it has none.
local function Zones(view)
    local listed = ns.OUTLINES and ns.OUTLINES[view.continent] or {}
    for zone in pairs(listed) do
        local box = Coords.Box(zone)
        if box and box.continent == view.continent and Meets(box, view) then
            local mask = outlines:Get(zone, Art.OUTLINE:format(zone), box.u, box.v, box.width, box.height)
            Draw(zone, box, 4, view, mask)
            Parts(zone, box, 5, view, mask)
        end
    end
    local zone = view.zone
    if zone and not listed[zone] then
        local box = Coords.Box(zone)
        Draw(zone, box, 4, view)
        Parts(zone, box, 5, view)
    end
end

-- A box of a continent's plane in the view's plane, by link.
local function Linked(box, link)
    return { u = link.du + link.su * box.u, v = link.dv + link.sv * box.v, width = link.su * box.width,
             height = link.sv * box.height }
end

-- One plane's map, linked into the view's plane, if it meets the view: its paper frame faded off.
local function Plane(plane, view)
    local box, link = Coords.Box(plane), Coords.Link(plane, view.map)
    box = box and link and Linked(box, link)
    if box and Meets(box, view) then
        Draw(plane, box, 1, view, outlines:Get(-plane, Art.EDGE, box.u, box.v, box.width, box.height), true)
    end
end

-- Under the stitched map: the world map, and every plane's map that meets the view (a continent's, the isle's
-- own), their paper frames faded off; the sea between the zones and around them. A view's plane not on the world
-- map (Retail's Outland, Coords.Elsewhere) has its own map alone.
local function Under(view)
    local world = Coords.WorldBox(view.map)
    if world and Meets(world, view) then
        Draw(Coords.WorldMap(), world, 0, view, outlines:Get("world", Art.EDGE, world.u, world.v, world.width, world.height), true)
    end
    local own = false
    for _, plane in ipairs(Coords.Planes()) do
        own = own or plane == view.map
        Plane(plane, view)
    end
    if not own then Plane(view.map, view) end
end

-- The art in view (view: Canvas.view), if shown (the view Parchment): the world's and the continents' maps,
-- the stitched map over them, up close every zone's own over that. One map at a time (Retail, view.shown): that
-- map's art alone, in the layer the zoom asks for, with its explored parts.
function Art.Place(view, shown)
    pool:Begin()
    parts:Begin()
    stitched:Begin()
    outlines:Begin()
    if shown and view.shown then
        Draw(view.shown, view.box, 1, view, nil, nil, view.layer)
        if (view.layer or 1) == 1 then Parts(view.shown, view.box, 2, view) end
    elseif shown then
        Under(view)
        if ns.Terrain.Ready() then ns.Terrain.Overview(view, stitched, Art.SKETCH, 2) end
        if view.level == "zone" then Zones(view) end
    end
    pool:End()
    parts:End()
    stitched:End()
    outlines:End()
end

-- The highlight out of sight.
function Art.Unlight()
    light:Hide()
end

-- The game's highlight of what is under a point of the view's plane (u, v), on a map the view shows whole:
-- at a continent the zone there, at the world the continent; none at a zone, nor where the game has none.
function Art.Light(view, u, v)
    local map, box
    if view.shown then
        map, box = view.shown, view.box -- one map at a time: on it, whatever its level (Retail)
    elseif view.level == "world" then
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
    parts:Begin()
    parts:End()
    stitched:Begin()
    stitched:End()
    outlines:Begin()
    outlines:End()
end
