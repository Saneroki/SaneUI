local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Book layout
--  Where every icon of a spellbook tab goes: which page, which column, which row.
--
--  Nothing in here touches the game's frames: lists in, lists out. The numbers are the
--  game's own (Blizzard_PlayerSpells, the Forever variant): a page is 680 x 590,
--  three columns, 15 between columns and 10 between rows; a heading is 51 high,
--  a spell 60, the gap between two groups 20. The filling rule is the game's too
--  (Blizzard_PagedCondensedGridContentFrame): column by column, in as few rows
--  as the group needs.
-------------------------------------------------------------------------------
local L = {}
ns.BookLayout = L

L.VIEW_WIDTH, L.VIEW_HEIGHT = 680, 590
L.COLUMNS = 3
L.X_PAD, L.Y_PAD = 15, 10
L.HEADER, L.CELL, L.SPACER = 51, 60, 20
L.CELL_WIDTH = (L.VIEW_WIDTH - L.X_PAD * (L.COLUMNS - 1)) / L.COLUMNS

-- groups: { { header = item or nil, items = { item, ... } }, ... }
-- A header item may say its own height (.height), and a group how far it keeps from the
-- one before it (.gap), for a subsection that is smaller and closer than the game's groups.
-- Returns the pages ("views"): each a list of { item = , x = , y = , header = true or nil },
-- x and y measured from the page's top left corner, y downwards.
-- metrics: for a page that is not the game's own, any of
--   columns  how many entries stand side by side      cell   the height of an entry
--   xPad, yPad  the room between entries and between rows
function L.Paginate(groups, cellWidth, viewHeight, metrics)
    metrics = metrics or {}
    cellWidth = cellWidth or L.CELL_WIDTH
    viewHeight = viewHeight or L.VIEW_HEIGHT
    local columns, xPad, yPad = metrics.columns or L.COLUMNS, metrics.xPad or L.X_PAD, metrics.yPad or L.Y_PAD
    local rowStep = (metrics.cell or L.CELL) + yPad
    local views, view, used = {}, {}, 0

    local function nextView()
        views[#views + 1] = view
        view, used = {}, 0
    end

    for _, group in ipairs(groups) do
        local items = group.items or {}
        local count, placed = #items, 0
        local headerStep = (group.header and group.header.height or L.HEADER) + yPad
        local spacerStep = (group.gap or L.SPACER) + yPad

        if group.header or count > 0 then
            -- A group never starts with its heading alone at the foot of a page.
            local gap = #view > 0
            local need = (group.header and headerStep or 0) + (count > 0 and rowStep or 0) + (gap and spacerStep or 0)
            if gap and viewHeight - used < need then
                nextView()
                gap = false
            end
            if gap then used = used + spacerStep end
            if group.header then
                view[#view + 1] = { item = group.header, x = 0, y = used, header = true }
                used = used + headerStep
            end
        end

        while placed < count do
            local fit = math.floor((viewHeight - used) / rowStep)
            if fit < 1 then
                if used == 0 then break end -- a page that cannot hold one row: nothing sensible to do
                nextView()
            else
                -- As few rows as the rest of the group needs, at most what the page still holds.
                local rest = count - placed
                local rows = math.min(math.ceil(rest / columns), fit)
                local take = math.min(rest, rows * columns)
                for k = 0, take - 1 do
                    view[#view + 1] = {
                        item = items[placed + k + 1],
                        x = math.floor(k / rows) * (cellWidth + xPad),
                        y = used + (k % rows) * rowStep,
                    }
                end
                placed = placed + take
                used = used + rows * rowStep
                if placed < count then nextView() end
            end
        end
    end

    if #view > 0 or #views == 0 then views[#views + 1] = view end
    return views
end

-- table.sort order of items that each carry an entry: what you can learn now first, then the
-- level it comes at, then name and rank.
function L.ByLevel(a, b)
    local nowA, nowB = a.entry.state == "trainable", b.entry.state == "trainable"
    if nowA ~= nowB then return nowA end
    local levelA, levelB = a.entry.level or 999, b.entry.level or 999
    if levelA ~= levelB then return levelA < levelB end
    if a.entry.name ~= b.entry.name then return a.entry.name < b.entry.name end
    return (a.entry.rank or 0) < (b.entry.rank or 0)
end

-- A tab's icons in order: the spells you have ("natives", in the game's own order) first, then
-- the ones still to learn ("ghosts", each with .entry): what you can learn now, then the rest by
-- the level they come at (L.ByLevel).
function L.Order(natives, ghosts)
    local out = {}
    for _, native in ipairs(natives) do out[#out + 1] = native end
    local rest = {}
    for _, ghost in ipairs(ghosts) do rest[#rest + 1] = ghost end
    table.sort(rest, L.ByLevel)
    for _, ghost in ipairs(rest) do out[#out + 1] = ghost end
    return out
end
