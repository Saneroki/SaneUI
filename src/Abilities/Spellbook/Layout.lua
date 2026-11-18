local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Book layout
--  Where each entry of the spellbook stands: which view (a page of the book),
--  which row and column, and where that is. Lists in, lists out: nothing here
--  touches a frame.
--
--  The rules are the game's own spellbook's (Blizzard_PagedContent:
--  PagedContentFrameBaseMixin:ProcessElement and the condensed vertical grid,
--  Blizzard_PagedCondensedGridContentFrame.lua), its numbers Camelot's
--  (Blizzard_PlayerSpells, Camelot/SpellBook/Blizzard_SpellBookTemplates.xml
--  and SpellBook/Blizzard_SpellBookFrame.xml):
--    - a view is 680 x 590, in 3 columns 15 apart, rows 10 apart; a heading
--      is a whole row 60 high, an entry 60, the gap between two groups 20
--    - a group's entries go column by column, in as few rows as the group
--      needs (ceil(count / 3)); a column ends at that count or where the view
--      has no room for the next entry, and the next one starts at the group's
--      top again; when the last column is full, the rest goes to a new view,
--      its rows counted anew for what is left
--    - a heading never stands alone at a view's foot: it needs room for itself
--      and one entry; a group after another on the same view keeps the gap
--
--      local views = Layout.Split(groups)    -- groups: { { header = h, elements = { e, ... } }, ... }
--      views[i] = { { kind = "header" | "spacer" | "entry", data = h or e, row = r, column = c }, ... }
--      Layout.Place(view, width)             -- x, y (from the view's top left, down), width, height on each
-------------------------------------------------------------------------------
local Layout = {}
ns.SpellbookLayout = Layout

Layout.WIDTH, Layout.HEIGHT = 680, 590 -- a view (Camelot: PagedSpellsView1Template)
Layout.COLUMNS = 3
Layout.X_PAD, Layout.Y_PAD = 15, 10
Layout.HEADER, Layout.ENTRY, Layout.SPACER = 60, 60, 20 -- SpellBookHeaderSizeTemplate, SpellBookItemTemplate, spacerSize

-- The heights of what stands in a row, by kind.
local HEIGHT = { header = Layout.HEADER, entry = Layout.ENTRY, spacer = Layout.SPACER }

-- A group's run of entries in the view it is in (the game's ElementSet): how many rows it may take, which
-- column it fills, how full each column is, and the room there was where it began and where it ends.
local function Set(count)
    return { rows = math.ceil(count / Layout.COLUMNS), column = 1, filled = { [1] = 0 }, startRow = 0,
             startRoom = 0, endRoom = 0 }
end

local function Placed(set)
    return set.column > 1 or set.filled[set.column] > 0
end

function Layout.Split(groups)
    local entryStep, spacerStep = Layout.ENTRY + Layout.Y_PAD, Layout.SPACER + Layout.Y_PAD
    local views, view = {}, {}
    local room, rows = Layout.HEIGHT, 0
    local set, left -- the run of entries now, and how many of the group's entries are not placed yet

    local function NewView()
        views[#views + 1] = view
        view, room, rows = {}, Layout.HEIGHT, 0
        if left and left > 0 then set = Set(left) end
    end

    for _, group in ipairs(groups) do
        local elements = group.elements or {}
        left, set = #elements, Set(#elements)
        local first = true
        local function Add(kind, data, index)
            local step = (kind == "header" and Layout.HEADER or Layout.ENTRY) + Layout.Y_PAD
            local spacer = first and #view > 0
            local need = step + (spacer and spacerStep or 0)
            local nextStep = 0
            if (kind == "header" and #elements > 0) or (kind == "entry" and index < #elements) then nextStep = entryStep end
            if kind == "header" and #elements > 0 then need = need + nextStep end
            -- The game's ShouldStartNewView: no room here (or this column is full), and either nothing of the
            -- run is placed yet or there is no column left to go on in.
            local blocked = room < need or set.filled[set.column] >= set.rows
            if blocked and (not Placed(set) or set.column >= Layout.COLUMNS) then
                NewView()
                spacer = false
            end
            if spacer then
                rows = rows + 1
                view[#view + 1] = { kind = "spacer", row = rows, column = 1 }
                room = room - spacerStep
            end
            first = false
            room = room - step
            if kind == "header" then
                rows = rows + 1
                view[#view + 1] = { kind = "header", data = data, row = rows, column = 1 }
                return
            end
            if not Placed(set) then
                set.startRow, set.startRoom = rows, room + step
            end
            if set.column == 1 then rows = rows + 1 end
            left = left - 1
            set.filled[set.column] = set.filled[set.column] + 1
            view[#view + 1] = { kind = "entry", data = data, column = set.column, row = set.startRow + set.filled[set.column] }
            local ends = left == 0 or room < nextStep or set.filled[set.column] >= set.rows
            if ends then
                if set.column == 1 or room < set.endRoom then set.endRoom = room end
                if left > 0 and set.column < Layout.COLUMNS then
                    set.column = set.column + 1
                    set.filled[set.column] = 0
                    room = set.startRoom
                else
                    room = set.endRoom
                end
            end
        end
        if group.header then Add("header", group.header) end
        for index, element in ipairs(elements) do Add("entry", element, index) end
    end
    views[#views + 1] = view
    return views
end

-- Where each of a view's rows starts, from its top, and each cell: x, y, width, height. width: the view's (the
-- entries share it, the headers take it whole).
function Layout.Place(view, width)
    width = width or Layout.WIDTH
    local cell = (width - Layout.X_PAD * (Layout.COLUMNS - 1)) / Layout.COLUMNS
    local heights = {}
    for _, item in ipairs(view) do
        heights[item.row] = math.max(heights[item.row] or 0, HEIGHT[item.kind])
    end
    local tops, y = {}, 0
    for row = 1, #heights do
        tops[row] = y
        y = y + (heights[row] or 0) + Layout.Y_PAD
    end
    for _, item in ipairs(view) do
        item.y, item.height = tops[item.row] or 0, HEIGHT[item.kind]
        if item.kind == "entry" then
            item.x, item.width = (item.column - 1) * (cell + Layout.X_PAD), cell
        else
            item.x, item.width = 0, width
        end
    end
    return view
end
