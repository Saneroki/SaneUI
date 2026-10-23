local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Layout
--  Where the blocks of a view (Views.lua) go, as plain numbers, in one of
--  three looks: no frame here, the window (Bags.lua) puts its buttons and
--  lines where these say.
--      grid     each block under its head (its name, how many), its cells in
--               lines as wide as the room, then its "+" (to put an item in),
--               the last line made whole with pads (empty slots: an item let
--               go on one goes into the block's category); an empty block a
--               line of pads
--      list     each block under its head, a line per cell: the item at the
--               left, its words in columns
--      compact  the blocks side by side in bands, its name over each: which
--               blocks share a band, and how wide each is, planned so that
--               the whole takes the fewest lines (a block that is not the
--               last of its band at least three cells wide)
--  A part's head (the bags, the bank) goes over the whole width.
--
--      local count, height = Layout.Lay(look, blocks, width, out)
--      out: the places, used again: out[i] = { kind = "head" | "cell" | "plus" | "pad" | "row" | "label", x, y,
--           width, height, size (a cell's, a row's item), entry (a cell's or row's), block (a head's,
--           a label's, a cell's), level (a head's: 1 a part, 2 a block, 3 a group's member) }
-------------------------------------------------------------------------------
local Layout = {}
ns.Layout = Layout

Layout.SIZE = 34         -- an item button
Layout.GAP = 4           -- between two
Layout.ROW = 24          -- a list's line
Layout.ICON = 20         -- its item button
Layout.HEAD = 20         -- a head line
Layout.HEAD_GAP = 2      -- under it
Layout.APART = 6         -- room after a block
Layout.MEMBER = 16       -- a group's member's head
Layout.BAND_GAP = 14     -- between two blocks side by side (compact)
Layout.LABEL = 15        -- a block's name over it (compact)
Layout.LABEL_GAP = 3

Layout.LOOKS = {
    { key = "grid", word = ns.TEXT.bagsGrid },
    { key = "list", word = ns.TEXT.bagsList },
    { key = "compact", word = ns.TEXT.bagsCompact },
}
Layout.LOOK = {}
for _, look in ipairs(Layout.LOOKS) do Layout.LOOK[look.key] = look end

local out, count, y
local NONE = {}

local function Place(kind)
    count = count + 1
    local place = out[count]
    if not place then
        place = {}
        out[count] = place
    end
    place.kind, place.entry, place.block, place.level, place.size = kind, nil, nil, nil, nil
    return place
end

local function Head(block, width)
    local place = Place("head")
    local height = block.level == 3 and Layout.MEMBER or Layout.HEAD
    place.x, place.y, place.width, place.height = 0, y, width, height
    place.block, place.level = block, block.level
    y = y + height + Layout.HEAD_GAP
end

-- A block's cells in lines from x, columns to a line, the last one made whole with pads (pads: whether);
-- returns the lines taken.
local function Cells(block, x, columns, pads)
    local step = Layout.SIZE + Layout.GAP
    local n = #block.entries
    local column, line = 0, 0
    for _, entry in ipairs(block.entries) do
        if column >= columns then
            column = 0
            line = line + 1
        end
        local place = Place("cell")
        place.x, place.y, place.width, place.height = x + column * step, y + line * step, Layout.SIZE, Layout.SIZE
        place.size, place.entry, place.block = Layout.SIZE, entry, block
        column = column + 1
    end
    if pads and block.plus then
        if column >= columns then
            column = 0
            line = line + 1
        end
        local place = Place("plus")
        place.x, place.y, place.width, place.height = x + column * step, y + line * step, Layout.SIZE, Layout.SIZE
        place.size, place.block = Layout.SIZE, block
        column = column + 1
    end
    if pads then
        while column < columns do
            local place = Place("pad")
            place.x, place.y, place.width, place.height = x + column * step, y + line * step, Layout.SIZE, Layout.SIZE
            place.size, place.block = Layout.SIZE, block
            column = column + 1
        end
    end
    return (n > 0 or pads) and line + 1 or 0
end

local function Columns(width)
    return math.max(1, math.floor((width + Layout.GAP) / (Layout.SIZE + Layout.GAP)))
end
Layout.Columns = Columns

local function Grid(blocks, width)
    local columns = Columns(width)
    local step = Layout.SIZE + Layout.GAP
    for index = 1, blocks.count do
        local block = blocks[index]
        Head(block, width)
        if block.level ~= 1 then
            local lines = Cells(block, 0, columns, true)
            y = y + lines * step - (lines > 0 and Layout.GAP or 0) + Layout.APART
        end
    end
end

local function List(blocks, width)
    for index = 1, blocks.count do
        local block = blocks[index]
        Head(block, width)
        for _, entry in ipairs(block.folded and NONE or block.entries) do
            local place = Place("row")
            place.x, place.y, place.width, place.height, place.size = 0, y, width, Layout.ROW, Layout.ICON
            place.entry, place.block = entry, block
            y = y + Layout.ROW
        end
        if block.level ~= 1 then y = y + Layout.APART end
    end
end

-- A block's width and height in cells: near square, at least three wide (when it has three), never wider than
-- the room.
function Layout.Shape(n, columns)
    if n <= 0 then return 0, 0 end
    local wide = math.max(math.ceil(math.sqrt(n)), math.min(3, n))
    wide = math.min(wide, columns)
    return wide, math.ceil(n / wide)
end

-- A block's width in cells for so many lines; not the last of its band: at least three (when it has three).
local function Wide(n, lines, last)
    local wide = math.ceil(n / lines)
    if not last then wide = math.max(wide, math.min(3, n)) end
    return wide
end

-- The fewest lines the blocks run[first..last] take side by side in a room so wide (nil: they do not fit).
local function Lines(run, first, last, width)
    local step = Layout.SIZE + Layout.GAP
    local most = 0
    for index = first, last do most = math.max(most, #run[index].entries) end
    for lines = 1, most do
        local total = Layout.BAND_GAP * (last - first)
        for index = first, last do
            total = total + Wide(#run[index].entries, lines, index == last) * step - Layout.GAP
        end
        if total <= width then return lines end
    end
    return nil
end

-- A run of blocks (no part's head among them) planned into bands: best[i] the least height from block i on,
-- cut[i] where its band ends, lines[i] that band's lines.
local best, cut, lined = {}, {}, {}
local function Plan(run, width)
    local step = Layout.SIZE + Layout.GAP
    local n = #run
    best[n + 1] = 0
    for first = n, 1, -1 do
        best[first], cut[first], lined[first] = math.huge, first, 1
        for last = first, n do
            local lines = Lines(run, first, last, width)
            if not lines then break end
            local height = Layout.LABEL + Layout.LABEL_GAP + lines * step - Layout.GAP + Layout.APART + best[last + 1]
            if height <= best[first] then best[first], cut[first], lined[first] = height, last, lines end
        end
    end
end

local run = {}
local function Bands(width)
    if #run == 0 then return end
    Plan(run, width)
    local step = Layout.SIZE + Layout.GAP
    local first = 1
    while first <= #run do
        local last, lines = cut[first], lined[first]
        local top, x = y, 0
        for index = first, last do
            local block = run[index]
            local wide = Wide(#block.entries, lines, index == last)
            local label = Place("label")
            label.x, label.y, label.width, label.height, label.block = x, top, wide * step - Layout.GAP, Layout.LABEL, block
            y = top + Layout.LABEL + Layout.LABEL_GAP
            Cells(block, x, wide, false)
            x = x + wide * step - Layout.GAP + Layout.BAND_GAP
        end
        y = top + Layout.LABEL + Layout.LABEL_GAP + lines * step - Layout.GAP + Layout.APART
        first = last + 1
    end
    for index = #run, 1, -1 do run[index] = nil end
end

local function Compact(blocks, width)
    for index = 1, blocks.count do
        local block = blocks[index]
        if block.level == 1 then
            Bands(width)
            Head(block, width)
        elseif #block.entries > 0 then
            run[#run + 1] = block
        end
    end
    Bands(width)
end

-- The places of the blocks in a look ("grid", "list", "compact") in a room so wide; how many and how high.
function Layout.Lay(look, blocks, width, places)
    out, count, y = places, 0, 0
    width = math.max(width, Layout.SIZE)
    if look == "list" then List(blocks, width)
    elseif look == "compact" then Compact(blocks, width)
    else Grid(blocks, width) end
    for index = count + 1, #places do places[index].kind = nil end
    return count, y
end
