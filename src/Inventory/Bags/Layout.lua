local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Layout
--  Where the blocks of a view (Views.lua) go, as plain numbers, in one of
--  three looks: no frame here, the window (Bags.lua) puts its buttons and
--  lines where these say.
--      grid     the blocks side by side in bands, as many as fit across the
--               room, each under its head (its name, how many): its cells,
--               then one empty slot (block.plus: an item let go on it goes
--               into the block's category); a block takes as much room as its
--               cells or its head's words (measure), whichever is wider,
--               never more than the room (more cells: more lines). A group's
--               title (block.title) goes over the whole width, its members'
--               blocks side by side under it, then its one empty slot (a
--               bare block: no head, its slot level with the members' cells)
--      list     each block under its head, a line per cell: the item at the
--               left, its words in columns
--      compact  the blocks side by side in bands, its name over each: which
--               blocks share a band, and how wide each is, planned so that
--               the whole takes the fewest lines (a block that is not the
--               last of its band at least three cells wide), its empty slot
--               after its cells as in the grid, a group's title over the
--               whole width
--  A part's head (the bags, the bank) goes over the whole width.
--
--      local count, height = Layout.Lay(look, blocks, width, out, measure)
--      measure(block): how wide its head's words are (the grid; nil: as wide as its cells)
--      out: the places, used again: out[i] = { kind = "head" | "cell" | "bin" | "plus" | "row" | "label", x, y,
--           width, height, size (a cell's, a row's item), entry (a cell's or row's), block (a head's,
--           a label's, a cell's), level (a head's: 1 a part, 2 a block, 3 a group's member) }
-------------------------------------------------------------------------------
local Layout = {}
ns.Layout = Layout

Layout.SIZE = 51         -- an item button, an empty slot (Saneroki, 2026-10-23: half again the game's 34)
Layout.GAP = 5           -- between two
Layout.ROW = ns.Paper.Fit(24)     -- a list's line (its words' size: ns.Paper.WORDS)
Layout.ICON = 20         -- its item button
Layout.HEAD = ns.Paper.Fit(20)    -- a head line
Layout.HEAD_GAP = 2      -- under it
Layout.APART = 6         -- room after a block
Layout.MEMBER = ns.Paper.Fit(16)  -- a group's member's head
Layout.BAND_GAP = 14     -- between two blocks side by side
Layout.LABEL = ns.Paper.Fit(15)   -- a block's name over it (compact)
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

-- How many cells a block shows: its items, and its first empty slot (block.plus).
local function Slots(block)
    return #block.entries + (block.plus and 1 or 0) + (block.bin and 1 or 0)
end

-- A block's cells in lines from x and top, columns to a line (Junk's waste bin before them, block.bin), then its
-- empty slot (block.plus); returns the lines taken.
local function Cells(block, x, top, columns)
    local step = Layout.SIZE + Layout.GAP
    local column, line = 0, 0
    if block.bin then -- Junk's waste bin, first
        local place = Place("bin")
        place.x, place.y, place.width, place.height = x, top, Layout.SIZE, Layout.SIZE
        place.size, place.block = Layout.SIZE, block
        column = 1
    end
    for _, entry in ipairs(block.entries) do
        if column >= columns then
            column = 0
            line = line + 1
        end
        local place = Place("cell")
        place.x, place.y, place.width, place.height = x + column * step, top + line * step, Layout.SIZE, Layout.SIZE
        place.size, place.entry, place.block = Layout.SIZE, entry, block
        column = column + 1
    end
    if block.plus then
        if column >= columns then
            column = 0
            line = line + 1
        end
        local place = Place("plus")
        place.x, place.y, place.width, place.height = x + column * step, top + line * step, Layout.SIZE, Layout.SIZE
        place.size, place.block = Layout.SIZE, block
        column = column + 1
    end
    return (column > 0 or line > 0) and line + 1 or 0
end

local function Columns(width)
    return math.max(1, math.floor((width + Layout.GAP) / (Layout.SIZE + Layout.GAP)))
end
Layout.Columns = Columns

-- The grid's band under way: its top, where its next block goes, its lines of cells, its heads' height.
local top, across, lines, high = 0, 0, 0, 0

local function Close()
    if across > 0 then y = top + high + Layout.HEAD_GAP + lines * (Layout.SIZE + Layout.GAP) - Layout.GAP + Layout.APART end
    top, across, lines, high = y, 0, 0, 0
end

local function Grid(blocks, width, measure)
    local columns = Columns(width)
    local step = Layout.SIZE + Layout.GAP
    top, across, lines, high = y, 0, 0, 0
    local member = false -- the band under way holds a group's members
    for index = 1, blocks.count do
        local block = blocks[index]
        local slots = Slots(block)
        if block.level == 1 or block.title then
            Close()
            Head(block, width)
            top, member = y, false
        elseif slots > 0 then
            if block.level ~= 3 and member then Close() end -- a group's members keep their lines to themselves
            member = block.level == 3
            local wide = math.min(columns, slots)
            local words = not block.bare and measure and measure(block) or 0
            local room = math.min(width, math.max(wide * step - Layout.GAP, words))
            if across > 0 and across + room > width then Close() end
            local height = block.level == 3 and Layout.MEMBER or Layout.HEAD
            if block.bare and across == 0 then height = 0 end -- alone on its line: no room for heads above it
            if not block.bare then
                local place = Place("head")
                place.x, place.y, place.width, place.height = across, top, room, height
                place.block, place.level = block, block.level
            end
            lines = math.max(lines, Cells(block, across, top + height + Layout.HEAD_GAP, wide))
            high = math.max(high, height)
            across = across + room + Layout.BAND_GAP
        end
    end
    Close()
end

local function List(blocks, width)
    local hiding = false -- under a folded group's title: its members left out
    for index = 1, blocks.count do
        local block = blocks[index]
        if block.level ~= 3 then hiding = block.title and block.folded or false end
        if not (hiding and block.level == 3) and not block.bare then
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
    for index = first, last do most = math.max(most, Slots(run[index])) end
    for lines = 1, most do
        local total = Layout.BAND_GAP * (last - first)
        for index = first, last do
            total = total + Wide(Slots(run[index]), lines, index == last) * step - Layout.GAP
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
            local wide = Wide(Slots(block), lines, index == last)
            if not block.bare then
                local label = Place("label")
                label.x, label.y, label.width, label.height, label.block = x, top, wide * step - Layout.GAP, Layout.LABEL, block
            end
            Cells(block, x, top + Layout.LABEL + Layout.LABEL_GAP, wide)
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
        if block.level == 1 or block.title then
            Bands(width)
            Head(block, width)
        elseif Slots(block) > 0 then
            run[#run + 1] = block
        end
    end
    Bands(width)
end

-- The places of the blocks in a look ("grid", "list", "compact") in a room so wide; how many and how high.
function Layout.Lay(look, blocks, width, places, measure)
    out, count, y = places, 0, 0
    width = math.max(width, Layout.SIZE)
    if look == "list" then List(blocks, width)
    elseif look == "compact" then Compact(blocks, width)
    else Grid(blocks, width, measure) end
    for index = count + 1, #places do places[index].kind = nil end
    return count, y
end
