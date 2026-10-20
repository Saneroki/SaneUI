local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - List
--  The scrolling list a tab of the sheet shows over the left pane, in the
--  game's look (its tabs' lists: WowScrollBoxList, MinimalScrollBar, the
--  game's long lines at its top and bottom). Its rows are plain buttons the
--  tab draws itself; a row may be drawn for another element kind than it was
--  last, so a tab's draw sets up every part it uses.
--
--      local list = ns.List.New(parent, {
--          inset = { left, top, right, bottom },  -- from the parent's sides (the game's: 10, 40, 25, 15)
--          extent = function(element) return 30 end,  -- a row's height
--          draw = function(row, element) end,         -- a row drawn for its element
--      })
--      ns.List.Fill(list, elements)   -- what it lists now, its scroll position kept
--      ns.List.Redraw(list)           -- the rows on screen drawn anew (a choice or highlight changed)
--  Each step of the game's list into our code runs ns.Safe: a row that fails is
--  noted, the list goes on.
-------------------------------------------------------------------------------
local List = {}
ns.List = List

List.ROW = 30 -- a row's height when its tab cannot say

local function Line(box, point)
    local holder = CreateFrame("Frame", nil, box)
    holder:SetSize(1, 1)
    holder:SetPoint(point)
    holder:SetFrameLevel(box:GetFrameLevel() + 6)
    local line = holder:CreateTexture(nil, "OVERLAY")
    line:SetAtlas("UI-Character-Info-ScrollLine-Long", true)
    line:SetPoint("CENTER")
end

local function Make(list, factory)
    factory("Button", list.init)
end

function List.New(parent, options)
    local list = { options = options }
    local inset = options.inset or { 10, 40, 25, 15 }
    local box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", inset[1], -inset[2])
    box:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset[3], inset[4])
    local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 5, -2)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 5, 4)
    Line(box, "TOP")
    Line(box, "BOTTOM")
    list.init = function(row, element) ns.Safe("character", options.draw, row, element) end
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(_, element)
        return ns.Safe("character", options.extent, element) or List.ROW
    end)
    view:SetElementFactory(function(factory) ns.Safe("character", Make, list, factory) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    list.box, list.bar, list.view = box, bar, view
    return list
end

function List.Fill(list, elements)
    list.box:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
end

function List.Redraw(list)
    list.box:ForEachFrame(list.init)
end
