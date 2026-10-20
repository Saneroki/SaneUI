local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Layout
--  Where everything a view of the bags shows goes, as plain numbers: cells
--  (an item button), rows (a list's line with its item button at the left)
--  and heads (a line of words over a part). No frame: the window (Bags.lua)
--  puts its buttons and lines where these say.
--
--  The views:
--      slots    every slot, item or empty, in the bags' order: the game's
--               own order, at the game's size; a bag for one kind of item
--               (a quiver, the reagent bag, the keyring) a part of its own;
--               an item the search does not find is dimmed
--      groups   the items in their groups (Contents.GROUPS), each under a
--               head with its name and how many, sorted inside; the free
--               slots last, a cell for each kind of bag with how many
--      list     the same as lines: the item, its name in its quality's
--               colour, its item level, its count
--      compact  the items in their groups' order without heads, smaller,
--               the free slots last
--  In every view but slots, what the search does not find is left out. The
--  bank, while it is open, follows the bags, each of its parts under a head.
--
--      local count, height = Layout.Lay(view, sections, width, query, order, out)
--      sections: { { word, place, slots = { record, ... }, free = tally }, ... } (Contents.Scan)
--      out: the places, used again: out[i] = { kind = "cell" | "row" | "head", x, y, width, height,
--           record, free (a free slots' tally entry), scale, dim, word, number, spare (the number is of
--           free slots), level (1 a part, 2 a group), section (a part's head: its section) }
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = {}
ns.Layout = Layout

Layout.SIZE = 37         -- an item button, the game's (ContainerFrameItemButtonTemplate)
Layout.GAP = 5           -- between two, as the game's bags space them
Layout.SMALL = 30        -- an item button in the compact view
Layout.SMALL_GAP = 3
Layout.ROW = 26          -- a list's line
Layout.ICON = 22         -- its item button
Layout.ROW_GAP = 2
Layout.HEAD = 20         -- a head line
Layout.APART = 8         -- room above a head that follows something

Layout.VIEWS = {
    { key = "slots", word = ns.TEXT.bagsSlots },
    { key = "groups", word = ns.TEXT.bagsGroups },
    { key = "list", word = ns.TEXT.bagsList },
    { key = "compact", word = ns.TEXT.bagsCompact },
}
Layout.VIEW = {}
for _, view in ipairs(Layout.VIEWS) do Layout.VIEW[view.key] = view end

local Contents = ns.Contents

-------------------------------------------------------------------------------
--  Flowing cells into lines
-------------------------------------------------------------------------------
local out, count       -- the places of this laying out, how many
local width, y         -- the room's width, the top of the line being filled
local size, gap, column, columns -- the cells' size and gap, the next cell's column, how many fit a line
local started          -- something is placed already: a head keeps room above it

local function Place(kind)
    count = count + 1
    local place = out[count]
    if not place then
        place = {}
        out[count] = place
    end
    place.kind, place.record, place.free, place.dim, place.word, place.number, place.spare, place.level =
        kind, nil, nil, false, nil, nil, false, nil
    place.scale, place.section = 1, nil
    return place
end

-- The line being filled ends: the next one starts below it.
local function Break()
    if column > 0 then
        y = y + size + gap
        column = 0
    end
end

local function Cells(cellSize, cellGap)
    Break()
    size, gap = cellSize, cellGap
    columns = math.max(1, math.floor((width + gap) / (size + gap)))
end

local function Head(word, number, level, spare)
    Break()
    if started then y = y + Layout.APART end
    local place = Place("head")
    place.x, place.y, place.width, place.height = 0, y, width, Layout.HEAD
    place.word, place.number, place.level, place.spare = word, number, level, spare or false
    y = y + Layout.HEAD
    started = true
    return place
end

local function Cell(record, free, dim)
    if column >= columns then
        y = y + size + gap
        column = 0
    end
    local place = Place("cell")
    place.x, place.y, place.width, place.height = column * (size + gap), y, size, size
    place.record, place.free, place.dim, place.scale = record, free, dim or false, size / Layout.SIZE
    column = column + 1
    started = true
    return place
end

local function Row(record, free)
    Break()
    local place = Place("row")
    place.x, place.y, place.width, place.height = 0, y, width, Layout.ROW
    place.record, place.free, place.scale = record, free, Layout.ICON / Layout.SIZE
    y = y + Layout.ROW + Layout.ROW_GAP
    started = true
    return place
end

-------------------------------------------------------------------------------
--  The views
-------------------------------------------------------------------------------
-- slots: every slot by kind of bag, each kind under a head when there are several.
local function Slots(section, query)
    local kinds = section.free.kinds
    for _, kind in ipairs(kinds) do
        local entry = section.free[kind]
        if #kinds > 1 then Head(Contents.KindWord(kind), entry.count, 2, true) end
        Cells(Layout.SIZE, Layout.GAP)
        for _, record in ipairs(section.slots) do
            if record.kind == kind then Cell(record, nil, query ~= nil and record.item ~= nil and not Contents.Found(record, query)) end
        end
    end
end

local found = {} -- the items found, sorted: used again
local inGroup = {} -- [group] = how many found

local function Found(section, query, order)
    for index = #found, 1, -1 do found[index] = nil end
    for key in pairs(inGroup) do inGroup[key] = nil end
    for _, record in ipairs(section.slots) do
        if record.item and Contents.Found(record, query) then
            found[#found + 1] = record
            inGroup[record.group] = (inGroup[record.group] or 0) + 1
        end
    end
    return Contents.Sort(found, order, true)
end

-- How many slots of a section are free, of every kind.
local function Spare(section)
    local total = 0
    for _, kind in ipairs(section.free.kinds) do total = total + section.free[kind].count end
    return total
end

-- The free slots, a cell (or row) for each kind of bag that has any; not while searching. how: "rows",
-- "cells" (under a head of their own) or "flow" (on after the items, the compact view).
local function Free(section, query, how)
    if query then return end
    local total = Spare(section)
    if total == 0 then return end
    if how ~= "flow" then Head(Core.Word("EMPTY", "Empty"), total, 2, true) end
    if how == "cells" then Cells(size, gap) end
    for _, kind in ipairs(section.free.kinds) do
        local entry = section.free[kind]
        if entry.count > 0 then
            local record = Contents.Record(entry.bag, entry.slot)
            if how == "rows" then Row(record, entry) else Cell(record, entry) end
        end
    end
end

local function Groups(section, query, order, rows)
    local group
    for _, record in ipairs(Found(section, query, order)) do
        if record.group ~= group then
            group = record.group
            Head(Contents.GROUP[group].word, inGroup[group], 2)
            if not rows then Cells(Layout.SIZE, Layout.GAP) end
        end
        if rows then Row(record) else Cell(record) end
    end
    Free(section, query, rows and "rows" or "cells")
end

local function Compact(section, query, order)
    Cells(Layout.SMALL, Layout.SMALL_GAP)
    for _, record in ipairs(Found(section, query, order)) do Cell(record) end
    Free(section, query, "flow")
end

-- Every section (the bags, then the bank's parts) as the view shows them; returns how many places and the
-- height they take.
function Layout.Lay(view, sections, room, query, order, places)
    out, count, width, y, column, started = places, 0, math.max(room, Layout.SIZE), 0, 0, false
    size, gap, columns = Layout.SIZE, Layout.GAP, 1
    for _, section in ipairs(sections) do
        if section.word then Head(section.word, Spare(section), 1, true).section = section end
        if view == "groups" then Groups(section, query, order, false)
        elseif view == "list" then Groups(section, query, order, true)
        elseif view == "compact" then Compact(section, query, order)
        else Slots(section, query) end
    end
    Break()
    for index = count + 1, #places do places[index].kind = nil end
    return count, y
end
