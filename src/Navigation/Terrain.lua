local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Navigation - Terrain
--  The land as the minimap shows it: the game's own minimap textures, one per
--  tile of the continent's grid (Coords.lua), laid out where they are in view.
--  Which file a tile shows is Core's data, the set Tiles (pack World); until it
--  is there the layer draws nothing, and draws once it arrives.
--
--  Far out more tiles would be in view than is wise to load (each is a large
--  texture): past Terrain.CAP the layer draws nothing and says so, and
--  Blizzard's map art carries the view (Canvas.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Terrain = {}
ns.Terrain = Terrain

Terrain.CAP = 400 -- the most tiles drawn at once (each a texture of 512 x 512, loaded while in view)

local Coords = ns.Coords
local Tiles = Core.Data.Set("Tiles")
local files = {} -- [tile key] = its texture's file ID, or false: none; asked of the set once a tile
local pool

-- The set arrived (or changed): asked anew, drawn anew.
local function Arrived()
    wipe(files)
    ns.Canvas.Refresh()
end

function Terrain.Build(holder)
    local layer = CreateFrame("Frame", nil, holder)
    layer:SetSize(1, 1)
    layer:SetPoint("CENTER")
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

-- The tiles in view (view: Canvas.view), if shown; true when they are drawn, false when the layer shows
-- nothing (not chosen, the data not there yet, too many tiles in view).
function Terrain.Place(view, shown)
    pool:Begin()
    local drawn = false
    if shown and not Tiles:Ready() then
        Core.Data.Prepare("Tiles")
    elseif shown then
        local last = Coords.GRID - 1
        local left, top = Coords.Tile(view.left, view.top)
        local right, bottom = Coords.Tile(view.right, view.bottom)
        left, right = math.max(0, left), math.min(last, right)
        top, bottom = math.max(0, top), math.min(last, bottom)
        -- Only tiles that have a texture count (the sea has none); past the cap, none is drawn.
        local count = 0
        for row = top, bottom do
            for column = left, right do
                if File(Coords.TileKey(view.continent, column, row)) then count = count + 1 end
            end
            if count > Terrain.CAP then break end
        end
        if count <= Terrain.CAP then
            drawn = true
            local side = Coords.TILE
            for row = top, bottom do
                for column = left, right do
                    local key = Coords.TileKey(view.continent, column, row)
                    local file = File(key)
                    if file then
                        local u, v = Coords.Corner(column, row)
                        ns.Canvas.Put(pool:Get(key, file), u, v, side, side)
                    end
                end
            end
        end
    end
    pool:End()
    return drawn
end

-- Every tile let go.
function Terrain.Clear()
    pool:Begin()
    pool:End()
end
