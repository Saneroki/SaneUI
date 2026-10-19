local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Art
--  Blizzard's map art, laid over its map's box in the view's plane, by the
--  level the zoom shows (Camera.lua):
--
--      world       the world map (its box in the plane: Coords.WorldBox)
--      continent   the continent's map
--      zone        the continent's, and over it every zone's in view, each cut to its zone's
--                  outline (Art/Zones/<uiMapID>.blp, listed in Outlines.lua, both made by
--                  dev/tools/terrain-art from the game's own map chunks and areas), so the zones
--                  meet as on the land and no map stands as a square over another; a zone without
--                  an outline in the middle of the view is drawn whole
--
--  A map's art is the game's (C_Map.GetMapArtLayers, GetMapArtLayerTextures): its
--  tiles row by row, the last ones reaching past the art's edge, as Blizzard's map
--  canvas lays them (Blizzard_MapCanvasDetailLayer.lua); here they are cut there.
--  Over a map's art lie its explored parts (C_MapExplorationInfo), placed as
--  Blizzard's exploration provider places them: in the art's own pixels, cut into
--  the layer's tiles (MapExplorationDataProvider.lua).
--
--  As on the game's map, a zone's map shows the parts explored in detail; the
--  parts not yet explored are dark (Art.FOG) until they are: every part the game
--  has for the map is Core's set Overlays, the game says which it has revealed.
--  Over the terrain (the overlay) the art is half see-through: the zones' maps then
--  stand alone, without the continent's under them, and the land shows around
--  their outlines.
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
Art.FOG = { 0.03, 0.03, 0.04, 0.88 } -- a part of a map not yet explored: nearly black, the land faintly under it
Art.OUTLINE = "Interface\\AddOns\\SaneUI_Navigation\\Art\\Zones\\%d"

local Coords = ns.Coords
local arts = {} -- [uiMapID] = its art (tiles across and down, the layer's size and its tiles', the files), or false
local layer, pool, explored, fog, outlines, glow, light
local Overlays = Core.Data.Set("Overlays")

function Art.Build(holder)
    layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
    pool = ns.Canvas.Pool(layer, "ARTWORK")
    explored = ns.Canvas.Pool(layer, "ARTWORK")
    fog = ns.Canvas.Pool(layer, "ARTWORK")
    outlines = ns.Canvas.Masks(layer)
    Overlays:OnStamp(ns.Guard(function() ns.Canvas.Refresh() end)) -- arrived: the dark parts drawn
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

-- One map's art over its box: the tiles that meet the view, at sublevel; cut by mask, if given.
local function Draw(map, box, sublevel, view, mask)
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
                    ns.Canvas.Put(pool:Get(map * 1000 + index, file, sublevel, mask), u, v, width, height,
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
-- part's first texture's key in the pool; tint: its colour, if given. Placed as Blizzard's exploration
-- provider places it: in the art's own pixels, cut into the art's tiles, each texture's file a power of two
-- (MapExplorationDataProvider.lua).
local function Lay(from, key, art, box, x, y, width, height, files, level, view, mask, tint)
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
                if tint then texture:SetVertexColor(tint[1], tint[2], tint[3], tint[4]) end
                local fileWide, fileHigh = FileSide(pixelsWide), FileSide(pixelsHigh)
                ns.Canvas.Put(texture, u, v, wide * fileWide / pixelsWide, high * fileHigh / pixelsHigh,
                    pixelsWide / fileWide, pixelsHigh / fileHigh)
            end
        end
    end
end

-- A map's explored parts over its art, at sublevel (one higher for those the game draws on top), cut by
-- mask, if given; and the parts not yet explored, dark (Art.FOG): every part the game has for the map
-- (Core's set Overlays) but those it says are explored, known by their first texture. Those the game shows
-- only under the mouse are left out.
local function Explore(map, box, sublevel, view, mask)
    local art = Of(map)
    if not art or not box then return end
    local seen = {}
    for number, part in ipairs(ns.Live.Explored(map)) do
        local files = part.fileDataIDs
        if type(files) == "table" and files[1] then seen[files[1]] = true end
        if not part.isShownByMouseOver and type(files) == "table" and (part.textureWidth or 0) > 0 then
            Lay(explored, map * 100000 + number * 100, art, box, part.offsetX, part.offsetY, part.textureWidth,
                part.textureHeight, files, sublevel + (part.isDrawOnTopLayer and 1 or 0), view, mask)
        end
    end
    if not Overlays:Ready() then return Core.Data.Prepare("Overlays") end
    for _, key in ipairs(Overlays:Keys("byMap", map)) do
        local part = Overlays:Get(key)
        if part and part.files and part.files[1] and not seen[part.files[1]] then
            Lay(fog, key * 100, art, box, part.x, part.y, part.width, part.height, part.files, sublevel, view, mask,
                Art.FOG)
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
            Draw(zone, box, 3, view, mask)
            Explore(zone, box, 4, view, mask)
        end
    end
    local zone = view.zone
    if zone and not listed[zone] then
        local box = Coords.Box(zone)
        Draw(zone, box, 3, view)
        Explore(zone, box, 4, view)
    end
end

-- The art in view (view: Canvas.view): "full" over everything, "half" see-through over the terrain, nil none.
function Art.Place(view, mode)
    pool:Begin()
    explored:Begin()
    fog:Begin()
    outlines:Begin()
    if mode then
        layer:SetAlpha(mode == "half" and Art.HALF or 1)
        local full = mode == "full"
        if view.level == "world" then
            Draw(Coords.WorldMap(), Coords.WorldBox(view.map), 0, view)
        else
            local box = Coords.Box(view.map)
            if full or view.level == "continent" then
                Draw(view.map, box, 0, view)
                if full then Explore(view.map, box, 1, view) end
            end
            if view.level == "zone" then Zones(view) end
        end
    end
    pool:End()
    explored:End()
    fog:End()
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
    fog:Begin()
    fog:End()
    outlines:Begin()
    outlines:End()
    explored:Begin()
    explored:End()
end
