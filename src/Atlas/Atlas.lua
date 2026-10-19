local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Atlas
--  The painted map of the whole world, for Navigation's view Atlas: its art,
--  in blocks, and the index of the blocks there are. An addon of its own
--  (SaneUI_Atlas), loaded on demand: Navigation loads it the first time the
--  view is drawn, not at login. It needs Core only and does nothing by itself.
--
--  The art and its index are made by dev/tools/atlas into assets/optimized/Atlas/
--  (Art/ and Index.lua); dev/build puts them into this addon. A block:
--
--      file         Art\<continent>\<level>\<row>_<column>.blp, 512 x 512 pixels, BLP2 DXT1 with mipmaps
--      continent    the map's instance (0 the Eastern Kingdoms, 1 Kalimdor)
--      level        0 the finest, 2048 pixels a terrain tile (TILE, 1600/3 yards): a block is a quarter
--                   tile; a level up a block spans twice the yards, TILE / 4 * 2^level
--      row, column  counted as the terrain's tiles, from the north-west corner of the continent's grid of
--                   64 x 64 tiles, its middle at the world's 0, 0: row = floor((HALF - x) / span),
--                   column = floor((HALF - y) / span), HALF = 32 * TILE, x (north) and y (west) in yards
--
--  The index (Index.lua, ns.INDEX): per continent, per level, per row a string of
--  the columns that have a block, single ones and ranges ("3,5-9,12"); a block not
--  listed is not there (open sea, or not painted yet). Read once, when the addon is
--  loaded, into a set of the blocks by a number each (Key); its strings are let go.
--
--  What Navigation asks (SaneUI.Atlas, Painted.lua there):
--      Ready()                         whether the index was read and holds blocks
--      Levels()                        how many levels the art has (0 to Levels() - 1)
--      Span(level), Cells(level)       a block's side in yards; blocks along a side of the grid
--      Cell(level, x, y)               the row and column of the block at a world position
--      Corner(level, row, column)      the world position (x, y) of a block's north-west corner
--      Key(continent, level, row, column), Has(key), File(continent, level, row, column)
--      PIXELS                          a block's side in pixels
-------------------------------------------------------------------------------
local Core = SaneUI.Core
Core.NewModule(ADDON, "Atlas", ns)

ns.PIXELS = 512        -- a block's side in pixels
ns.TILE = 1600 / 3     -- a terrain tile's side in yards
ns.HALF = 32 * ns.TILE -- from a continent's middle to the edge of its grid, in yards
ns.CELLS = 256         -- blocks along a side of the grid at level 0: four a tile
ns.PATH = "Interface\\AddOns\\" .. ADDON .. "\\Art\\%d\\%d\\%d_%d"
local LEVELS = 16      -- levels a key has room for: from the ninth on a block holds the whole grid

local floor = math.floor
local blocks       -- [Key] = true: every block the art has; nil until the index is read
local levels = 0

function ns.Span(level)
    return ns.TILE / 4 * 2 ^ level
end

function ns.Cells(level)
    return math.max(1, math.ceil(ns.CELLS / 2 ^ level))
end

function ns.Cell(level, x, y)
    local span = ns.Span(level)
    return floor((ns.HALF - x) / span), floor((ns.HALF - y) / span)
end

function ns.Corner(level, row, column)
    local span = ns.Span(level)
    return ns.HALF - row * span, ns.HALF - column * span
end

-- One number per block: room for every row and column of level 0, and for LEVELS levels a continent.
function ns.Key(continent, level, row, column)
    return ((continent * LEVELS + level) * ns.CELLS + row) * ns.CELLS + column
end

function ns.Has(key)
    return blocks ~= nil and blocks[key] == true
end

function ns.File(continent, level, row, column)
    return ns.PATH:format(continent, level, row, column)
end

function ns.Levels()
    return levels
end

-- Whether a value is a whole number from first to last.
local function Whole(value, first, last)
    return type(value) == "number" and value == floor(value) and value >= first and value <= last
end

-- One row's columns ("3,5-9,12") into the set; what is no column or range of them is passed over, and what
-- lies past the grid is cut off.
local function Columns(base, text, last)
    for item in text:gmatch("[^,]+") do
        local first, final = item:match("^%s*(%d+)%s*%-%s*(%d+)%s*$")
        if not first then
            first = item:match("^%s*(%d+)%s*$")
            final = first
        end
        first, final = tonumber(first), tonumber(final)
        if first and final then
            for column = first, math.min(final, last) do blocks[base + column] = true end
        end
    end
end

-- The index read into the set, once; made by a tool, but read as anything might be there.
local function Read()
    if blocks then return end
    blocks = {}
    local index = ns.INDEX
    ns.INDEX = nil
    if type(index) ~= "table" or not Whole(index.levels, 1, LEVELS) then return end
    for continent, byLevel in pairs(index) do
        if Whole(continent, 0, 2 ^ 20) and type(byLevel) == "table" then
            for level = 0, index.levels - 1 do
                local rows, last = byLevel[level], ns.Cells(level) - 1
                if type(rows) == "table" then
                    for row, text in pairs(rows) do
                        if Whole(row, 0, last) and type(text) == "string" then
                            Columns(ns.Key(continent, level, row, 0), text, last)
                        end
                    end
                end
            end
        end
    end
    levels = index.levels
end

function ns.Ready()
    Read()
    return levels > 0 and next(blocks) ~= nil
end

-- Loaded (on demand): the index is read now.
ns.OnLoad = Read
