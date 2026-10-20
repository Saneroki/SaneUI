local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Sidebar
--  A window's sidebar, at its left under the bar: a dark column of rows
--  (an icon, a name, a count) under a little head with its name; the names
--  always show. It scrolls with the wheel when its rows are more than its
--  height. The row shown is
--  lit, with a bar at its left in Sane UI's colour. Sidebar.New makes one for
--  a window; the window fills it (Begin, Row, Divider, Done) and answers its
--  clicks (its choose, drop, menu, add).
--
--  The bags' (ns.BagSidebar): at the top the three views (All Items, One
--  Bag, Each Bag; the one the window opens with first), then Pinned and
--  Recent, a line, every category in the categories' order with how many
--  cells it holds (a group: its name with its members set in under it, each
--  with its own count), Add Category at the foot. Every category switched
--  on is listed, empty ones too. A click shows that view, category or group; an item brought
--  over a row (picked up, or dragged) and let go there goes into that
--  category (over Pinned: pinned); a right click opens the row's menu
--  (Menus.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sidebar = {}
ns.Sidebars = Sidebar
local Bag = {}
ns.BagSidebar = Bag

Sidebar.WIDTH = 160
Sidebar.HEAD = 24
Sidebar.ROW, Sidebar.ROW_GAP = 26, 2
Sidebar.ICON, Sidebar.ICON_SMALL = 18, 16
Sidebar.INDENT = 16
Sidebar.STEP = 28          -- the wheel's step
Sidebar.SHADE = { 0, 0, 0, 0.25 }
Sidebar.MUTED = { 0.5, 0.5, 0.5 }
Sidebar.DIVIDER = { 0.2, 0.2, 0.2, 1 }
Sidebar.DIM = 0.75         -- a row's words while not shown
Sidebar.LIT = 0.1          -- the row shown, in Sane UI's colour
Sidebar.HOVER = 0.06

local Categories = ns.Categories
local Rail = {}            -- a sidebar's functions
Rail.__index = Rail

local function Fonts()
    return {
        label = Core.Font("SaneUIBagsSideLabel", "GameFontHighlightSmall", 11),
        count = Core.Font("SaneUIBagsSideCount", "GameFontHighlightSmall", 10),
    }
end

-------------------------------------------------------------------------------
--  A row
-------------------------------------------------------------------------------
-- A name cut short by the sidebar's width: whole in the tooltip.
local function RowTip(row)
    if not (row.word and row.label:IsTruncated()) then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.word .. (row.number and (" (" .. row.number .. ")") or ""), 1, 1, 1)
    GameTooltip:Show()
end

local function RowEnter(row)
    row.hover:Show()
    RowTip(row)
    if GetCursorInfo() == "item" and row.takes then row.hover:SetAlpha(2.5) else row.hover:SetAlpha(1) end
end

local function RowLeave(row)
    row.hover:Hide()
    GameTooltip:Hide()
end

-- A click: an item on the cursor goes into the row's category (pinned over Pinned); else the row is shown, and
-- a right click opens its menu.
local function RowClick(row, mouse)
    local rail = row.rail
    if GetCursorInfo() == "item" then
        if row.takes and rail.drop then rail.drop(row) end
        return
    end
    if mouse == "RightButton" then
        if rail.menu then rail.menu(row) end
        return
    end
    if row.add then
        if rail.add then rail.add(row) end
        return
    end
    if row.view == nil then return end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    if rail.choose then rail.choose(row.view) end
end

local function RowDrop(row)
    if row.takes and row.rail.drop then row.rail.drop(row) end
end

local function MakeRow(rail)
    local row = CreateFrame("Button", nil, rail.child)
    row.rail = rail
    row:SetHeight(Sidebar.ROW)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row.hover = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.hover:SetAllPoints()
    row.hover:SetColorTexture(1, 1, 1, Sidebar.HOVER)
    row.hover:Hide()
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("TOPLEFT")
    row.bar:SetPoint("BOTTOMLEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 8, 0)
    local font = Fonts()
    row.label = row:CreateFontString(nil, "ARTWORK")
    if font.label then row.label:SetFontObject(font.label) end
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetPoint("RIGHT", -30, 0)
    row.count = row:CreateFontString(nil, "ARTWORK")
    if font.count then row.count:SetFontObject(font.count) end
    row.count:SetTextColor(Sidebar.MUTED[1], Sidebar.MUTED[2], Sidebar.MUTED[3])
    row.count:SetPoint("RIGHT", -6, 0)
    row:SetScript("OnEnter", function(self) ns.Safe("bags", RowEnter, self) end)
    row:SetScript("OnLeave", function(self) ns.Safe("bags", RowLeave, self) end)
    row:SetScript("OnClick", function(self, mouse) ns.Safe("bags", RowClick, self, mouse) end)
    row:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", RowDrop, self) end)
    return row
end

-- An icon: an atlas where the game has it, else a texture, cut a little round its edge.
local function Icon(texture, file, atlas)
    texture:SetTexCoord(0, 1, 0, 1)
    if atlas and texture:SetAtlas(atlas) then return end
    texture:SetTexture(file)
    texture:SetTexCoord(ns.Cells.ZOOM, 1 - ns.Cells.ZOOM, ns.Cells.ZOOM, 1 - ns.Cells.ZOOM)
end

-------------------------------------------------------------------------------
--  A sidebar's rows, anew
-------------------------------------------------------------------------------
function Rail:Width()
    return Sidebar.WIDTH
end

function Rail:Begin()
    self.rows:Begin()
    self.dividers:Begin()
    self.y = 2
end

-- A row: its name, count (nil: none), icon (a texture, or an atlas first), how far set in, whether it is shown.
function Rail:Row(word, number, file, atlas, depth, shown)
    local row = self.rows:Take()
    local width = self:Width()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.child, "TOPLEFT", 0, -self.y)
    row:SetWidth(width - 1)
    row.word, row.number = word, number
    row.key, row.group, row.view, row.add, row.takes = nil, nil, nil, nil, false
    local size = depth > 0 and Sidebar.ICON_SMALL or Sidebar.ICON
    row.icon:SetSize(size, size)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", 8 + depth * Sidebar.INDENT, 0)
    Icon(row.icon, file, atlas)
    row.icon:SetAlpha(1)
    row.label:SetText(word)
    row.label:SetAlpha(shown and 1 or Sidebar.DIM)
    row.count:SetText(number and tostring(number) or "")
    local gold = Core.GOLD
    row.bar:SetColorTexture(gold[1], gold[2], gold[3], 1)
    row.bar:SetWidth(Core.Pixels(row, 2))
    row.bar:SetShown(shown)
    row.back:SetColorTexture(gold[1], gold[2], gold[3], Sidebar.LIT)
    row.back:SetShown(shown)
    row:Show()
    self.y = self.y + Sidebar.ROW + Sidebar.ROW_GAP
    return row
end

function Rail:Divider()
    local line = self.dividers:Take()
    local width = self:Width() - 1
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", self.child, "TOPLEFT", width * 0.08, -(self.y + 2))
    line:SetSize(width * 0.84, Core.Pixels(self.child, 1))
    line:Show()
    self.y = self.y + 6
end

function Rail:Done()
    self.rows:Done()
    self.dividers:Done()
    self.child:SetHeight(math.max(1, self.y))
end

-- The rows (the tests).
function Rail:Rows()
    local list = {}
    for index = 1, self.rows.taken do list[index] = self.rows[index] end
    return list
end

-------------------------------------------------------------------------------
--  A sidebar made
-------------------------------------------------------------------------------
local function Wheel(rail, delta)
    local most = math.max(0, rail.child:GetHeight() - rail.scroll:GetHeight())
    rail.scroll:SetVerticalScroll(math.max(0, math.min(most, rail.scroll:GetVerticalScroll() - delta * Sidebar.STEP)))
end

-- A sidebar in body, under top and above bottom. options: { word (its head's), choose(view), drop(row), menu(row),
-- add(row) }.
function Sidebar.New(body, top, bottom, options)
    local rail = setmetatable({ choose = options.choose, drop = options.drop, menu = options.menu, add = options.add }, Rail)
    local frame = CreateFrame("Frame", nil, body)
    frame:SetWidth(Sidebar.WIDTH)
    frame:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    frame:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT")
    rail.frame = frame
    local back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(Sidebar.SHADE[1], Sidebar.SHADE[2], Sidebar.SHADE[3], Sidebar.SHADE[4])
    local edge = frame:CreateTexture(nil, "BORDER")
    edge:SetColorTexture(ns.Bags.RULE[1], ns.Bags.RULE[2], ns.Bags.RULE[3], ns.Bags.RULE[4])
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetWidth(Core.Pixels(frame, 1))
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetHeight(Sidebar.HEAD)
    rail.head = head
    local label = head:CreateFontString(nil, "ARTWORK")
    label:SetFontObject(Core.Font("SaneUIBagsSideHead", "GameFontHighlightSmall", 10) or "GameFontHighlightSmall")
    label:SetTextColor(Sidebar.MUTED[1], Sidebar.MUTED[2], Sidebar.MUTED[3])
    label:SetPoint("LEFT", 8, 0)
    label:SetText(options.word or "")
    rail.label = label
    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", head, "BOTTOMLEFT")
    scroll:SetPoint("BOTTOMRIGHT")
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) ns.Safe("bags", Wheel, rail, delta) end)
    rail.scroll = scroll
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(Sidebar.WIDTH, 1)
    scroll:SetScrollChild(child)
    rail.child = child
    rail.rows = Core.Pool(function() return MakeRow(rail) end)
    rail.dividers = Core.Pool(function()
        local line = child:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(Sidebar.DIVIDER[1], Sidebar.DIVIDER[2], Sidebar.DIVIDER[3], Sidebar.DIVIDER[4])
        return line
    end)
    return rail
end

-------------------------------------------------------------------------------
--  The bags' sidebar
-------------------------------------------------------------------------------
local rail -- the bags' (Bag.Build)

-- The rows as they are now: counts are Views.Counts', viewing the view shown, options the module's settings.
function Bag.Refresh(counts, viewing, options)
    if not rail then return end
    options = options or {}
    rail:Begin()
    local default = options.first or "all"
    local fixed = {}
    for _, view in ipairs(ns.Views.FIXED) do
        if view.key == default then table.insert(fixed, 1, view) else fixed[#fixed + 1] = view end
    end
    for _, view in ipairs(fixed) do
        rail:Row(view.word, nil, view.icon, nil, 0, viewing == view.key).view = view.key
    end
    local shownFixed = false
    for _, key in ipairs({ Categories.PINNED, Categories.RECENT }) do
        if options[ns.Bags.SHOW[key]] ~= false then
            local file, atlas = Categories.Icon(key)
            local row = rail:Row(Categories.Word(key), counts[key] or 0, file, atlas, 0, viewing == "cat:" .. key)
            row.view, row.key, row.takes = "cat:" .. key, key, key == Categories.PINNED
            shownFixed = true
        end
    end
    if shownFixed then rail:Divider() end
    local done = {}
    for _, key in ipairs(Categories.order) do
        local def = Categories.DEF[key]
        local group = Categories.GroupOf(key)
        if not (def and def.fixed) and not Categories.Off(key) then
            if group and not done[group] then
                done[group] = true
                local first = Categories.Members(group)[1]
                local file, atlas = Categories.Icon(first)
                local row = rail:Row(Categories.GroupWord(group), counts["group:" .. group] or 0, file, atlas, 0,
                    viewing == "group:" .. group)
                row.view, row.group = "group:" .. group, group
                for _, member in ipairs(Categories.Members(group)) do
                    if not Categories.Off(member) then
                        local mfile, matlas = Categories.Icon(member)
                        local memberRow = rail:Row(Categories.Word(member), counts[member] or 0, mfile, matlas, 1,
                            viewing == "cat:" .. member)
                        memberRow.view, memberRow.key, memberRow.takes = "cat:" .. member, member, Categories.Takes(member)
                    end
                end
            elseif not group then
                local file, atlas = Categories.Icon(key)
                local row = rail:Row(Categories.Word(key), counts[key] or 0, file, atlas, 0, viewing == "cat:" .. key)
                row.view, row.key, row.takes = "cat:" .. key, key, Categories.Takes(key)
            end
        end
    end
    if options.addCategory ~= false then
        local row = rail:Row(ns.TEXT.bagsAddCategory, nil, Categories.OWN_ICON, nil, 0, false)
        row.add = true
        row.icon:SetAlpha(0.5)
        row.label:SetAlpha(0.4)
    end
    rail:Done()
end

function Bag.Width()
    return rail and rail:Width() or Sidebar.WIDTH
end

-- The bags' sidebar in the body, under top (the bar) and above bottom (the foot); bags: store.bags.
function Bag.Build(body, top, bottom, bags)
    rail = Sidebar.New(body, top, bottom, {
        word = ns.TEXT.bagsCategories,
        choose = function(view) ns.Bags.Choose(view) end,
        drop = function(row) ns.Menus.Drop(row.key) end,
        menu = function(row) if row.key or row.group then ns.Menus.Row(row, row.key, row.group) end end,
        add = function(row) ns.Menus.Add(row) end,
    })
    Bag.frame = rail.frame
    return rail.frame
end

-- The rows (the tests).
function Bag.Rows()
    return rail and rail:Rows() or {}
end
