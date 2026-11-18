local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Sheet - Statistics
--  The sheet's statistics tab, as the game's sheet has it (Camelot's
--  StatisticsFrame, from the game's addon Blizzard_Statistics), ours: over the
--  left pane the game's statistics (GetStatisticsCategoryList) as a tree: each
--  top-level category a header (Rows.lua; a click folds or unfolds it), each
--  category under another a sub-header with its fold button, set in by its
--  depth as the game sets it in, and under a category its statistics: the
--  name, and the value at the right ("--" for none yet). A name too long for
--  its row shows whole in a tooltip. The right pane shows nothing of its own,
--  as on the game's sheet.
--
--  The game folds its tree in its own list; ours keeps what is folded itself,
--  until a /reload. The statistics are drawn anew a frame after the game says
--  a criterion changed (it says so often), only while the tab shows.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Statistics = {}
ns.Statistics = Statistics

-- The game's numbers (StatisticsFrame.lua, .xml): the root's parent ID, how far each depth is set in, the rows'
-- heights, the value's width and place.
Statistics.ROOT = -1
Statistics.INDENT = 20
Statistics.HEADER, Statistics.SUBHEADER, Statistics.ENTRY = 26, 22, 24
Statistics.VALUE, Statistics.VALUE_RIGHT = 50, 12
Statistics.NONE = "--"

local list
local folded = {} -- [category ID] = true: folded in our list

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

-- The game's categories in its order (the list's numeric keys sorted), as a tree: each category with its depth,
-- children right after their parent (StatisticsFrame.lua's BuildCategoryEntriesFromSource).
local function Categories()
    local source = Game("GetStatisticsCategoryList")
    if type(source) ~= "table" then return {} end
    local keys = {}
    for key, id in pairs(source) do
        if id and type(key) == "number" then keys[#keys + 1] = key end
    end
    table.sort(keys)
    local roots, children = {}, {}
    for _, key in ipairs(keys) do
        local id = source[key]
        local _, parent = Game("GetCategoryInfo", id)
        if parent == Statistics.ROOT or parent == nil then
            roots[#roots + 1] = id
        else
            children[parent] = children[parent] or {}
            table.insert(children[parent], id)
        end
    end
    local ordered, seen = {}, {}
    local function Add(id, depth)
        if seen[id] then return end
        seen[id] = true
        ordered[#ordered + 1] = { id = id, depth = depth }
        for _, child in ipairs(children[id] or {}) do Add(child, depth + 1) end
    end
    for _, id in ipairs(roots) do Add(id, 1) end
    return ordered
end

-- The rows as the tree is folded now: a category, then (unless it or one above it is folded) its statistics and
-- the categories under it.
local function Elements()
    local elements = {}
    local hiddenBelow -- the depth under which rows are folded away
    for _, category in ipairs(Categories()) do
        if hiddenBelow and category.depth > hiddenBelow then
            -- under a folded category
        else
            hiddenBelow = nil
            local name = Game("GetCategoryInfo", category.id)
            elements[#elements + 1] = { isCategory = true, id = category.id, depth = category.depth,
                                        name = name or Core.Word("UNKNOWN", "Unknown") }
            if folded[category.id] then
                hiddenBelow = category.depth
            else
                for index = 1, Game("GetCategoryNumAchievements", category.id) or 0 do
                    local quantity, skip, statID = Game("GetStatistic", category.id, index)
                    if not skip and statID then
                        local value = tonumber(Core.Plain(quantity))
                        elements[#elements + 1] = {
                            isCategory = false, id = statID, depth = category.depth + 1,
                            name = select(2, Game("GetAchievementInfo", statID)) or Core.Word("UNKNOWN", "Unknown"),
                            value = (value and value > 0) and tostring(value) or Statistics.NONE,
                        }
                    end
                end
            end
        end
    end
    return elements
end

local function Kind(element)
    if not element.isCategory then return "entry" end
    if element.depth > 1 then return "subheader" end
    return "header"
end

local function Extent(element)
    local kind = Kind(element)
    if kind == "header" then return Statistics.HEADER end
    if kind == "subheader" then return Statistics.SUBHEADER end
    return Statistics.ENTRY
end

-- A name cut short by its row shows whole in a tooltip, as the game's does.
local function Truncated(row)
    if not (row.name.IsTruncated and row.name:IsTruncated()) then return end
    local text = row.name:GetText()
    if not text or text == "" then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(text)
    GameTooltip:Show()
end

local function Fold(row)
    local element = row.data
    if not element or not element.isCategory then return end
    folded[element.id] = not folded[element.id] or nil
    Statistics.Refresh()
end

local function Entered(row)
    if row.data and not row.data.isCategory then ns.Rows.Light(row, 0.10) end
    Truncated(row)
end

local function Left(row)
    if row.data and not row.data.isCategory then ns.Rows.Light(row, 0) end
    if GameTooltip:GetOwner() == row then GameTooltip_Hide() end
end

local OWNER = { click = Fold, fold = Fold, enter = Entered, leave = Left }

local function Draw(row, element)
    row.data = element
    local kind = Kind(element)
    local indent = (element.depth - 1) * Statistics.INDENT
    ns.Rows.Draw(row, kind, element.name, folded[element.id], OWNER, indent)
    row.bar:Hide()
    if not row.value then
        row.value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        row.value:SetJustifyH("RIGHT")
        row.value:SetSize(Statistics.VALUE, 15)
        row.value:SetPoint("RIGHT", -Statistics.VALUE_RIGHT, 0)
    end
    row.value:SetShown(kind == "entry")
    if kind == "header" then return end
    row.name:ClearAllPoints()
    if kind == "subheader" then
        row.name:SetPoint("LEFT", row.toggle, "RIGHT", 4, 0)
        row.name:SetPoint("RIGHT", -24, 0)
    else
        row.name:SetPoint("LEFT", 2 + indent, 0)
        row.name:SetPoint("RIGHT", row.value, "LEFT", -10, 0)
        row.value:SetText(element.value or Statistics.NONE)
    end
    ns.Rows.Light(row, 0)
end

function Statistics.Refresh()
    if list then ns.List.Fill(list, Elements()) end
end

local function Build(left)
    list = ns.List.New(left, { extent = Extent, draw = Draw })
end

local later = Core.Later(function() ns.Safe("character", Statistics.Refresh) end)

local function Show(on)
    if on then Core.On("CRITERIA_UPDATE", later) else Core.Off("CRITERIA_UPDATE", later) end
    if on then Statistics.Refresh() end
end

-- A window of its own on the board: the statistics' tree alone, as the game's tab has no side pane.
ns.Page.Part("statistics", Core.Word("STATISTICS", "Statistics"), ns.Page.Least(ns.List.LEAST, ns.List.LEAST_HEIGHT),
    { Build = Build, Show = Show })
