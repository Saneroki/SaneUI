local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Sidebar
--  The bag window's sidebar, at its left under the bar: what the window
--  shows. At the top the three views (All Items, One Bag, Each Bag; the one
--  the window opens with first), then Pinned and Recent, a line, every
--  category in the categories' order with how many cells it holds (a group:
--  its name with its members set in under it, each with its own count), Add
--  Category at the foot. A category with nothing in it is left out, unless it
--  is the player's own (Bags' setting). A click shows that view, category or
--  group; the row shown is lit, with a bar at its left in Sane UI's colour.
--
--  An item brought over a row (picked up, or dragged) and let go there is put
--  into that category (over Pinned: pinned); a right click opens the row's
--  menu (Menus.lua). The arrow at the top folds the sidebar to its icons,
--  each with its name and count in its tooltip. It scrolls with the wheel
--  when its rows are more than its height.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sidebar = {}
ns.BagSidebar = Sidebar

Sidebar.WIDTH, Sidebar.NARROW = 160, 32
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
local frame, scroll, child, head, arrow, label
local rows, dividers   -- pools
local kept             -- store.bags
local wide = true

local function Fonts()
    return {
        label = Core.Font("SaneUIBagsSideLabel", "GameFontHighlightSmall", 11),
        count = Core.Font("SaneUIBagsSideCount", "GameFontHighlightSmall", 10),
    }
end

-------------------------------------------------------------------------------
--  A row
-------------------------------------------------------------------------------
local function RowTip(row)
    if wide or not row.word then return end
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
    if GetCursorInfo() == "item" then
        if row.takes then ns.Menus.Drop(row.key) end
        return
    end
    if mouse == "RightButton" then
        if row.key or row.group then ns.Menus.Row(row, row.key, row.group) end
        return
    end
    if row.add then return ns.Menus.Add(row) end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    ns.Bags.Choose(row.view)
end

local function RowDrop(row)
    if row.takes then ns.Menus.Drop(row.key) end
end

local function MakeRow()
    local row = CreateFrame("Button", nil, child)
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

local function MakeDivider()
    local line = child:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(Sidebar.DIVIDER[1], Sidebar.DIVIDER[2], Sidebar.DIVIDER[3], Sidebar.DIVIDER[4])
    return line
end

-- An icon: an atlas where the game has it, else a texture, cut a little round its edge.
local function Icon(texture, file, atlas)
    texture:SetTexCoord(0, 1, 0, 1)
    if atlas and texture:SetAtlas(atlas) then return end
    texture:SetTexture(file)
    texture:SetTexCoord(ns.Cells.ZOOM, 1 - ns.Cells.ZOOM, ns.Cells.ZOOM, 1 - ns.Cells.ZOOM)
end

-------------------------------------------------------------------------------
--  The rows, anew
-------------------------------------------------------------------------------
local y

local function Row(word, number, file, atlas, depth, shown)
    local row = rows:Take()
    local width = wide and Sidebar.WIDTH or Sidebar.NARROW
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
    row:SetWidth(width - 1)
    row.word, row.number = word, number
    row.key, row.group, row.view, row.add, row.takes = nil, nil, nil, nil, false
    local size = depth > 0 and Sidebar.ICON_SMALL or Sidebar.ICON
    row.icon:SetSize(size, size)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", wide and (8 + depth * Sidebar.INDENT) or (width - size) / 2, 0)
    Icon(row.icon, file, atlas)
    row.icon:SetAlpha(1)
    row.label:SetText(wide and word or "")
    row.label:SetAlpha(shown and 1 or Sidebar.DIM)
    row.count:SetText(wide and number and tostring(number) or "")
    local gold = Core.GOLD
    row.bar:SetColorTexture(gold[1], gold[2], gold[3], 1)
    row.bar:SetWidth(Core.Pixels(row, 2))
    row.bar:SetShown(shown)
    row.back:SetColorTexture(gold[1], gold[2], gold[3], Sidebar.LIT)
    row.back:SetShown(shown)
    row:Show()
    y = y + Sidebar.ROW + Sidebar.ROW_GAP
    return row
end

local function Divider()
    local line = dividers:Take()
    local width = (wide and Sidebar.WIDTH or Sidebar.NARROW) - 1
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", child, "TOPLEFT", width * 0.08, -(y + 2))
    line:SetSize(width * 0.84, Core.Pixels(child, 1))
    line:Show()
    y = y + 6
end

-- The rows as they are now: counts are Views.Counts', viewing the view shown, options the module's settings.
function Sidebar.Refresh(counts, viewing, options)
    if not frame then return end
    options = options or {}
    rows:Begin()
    dividers:Begin()
    y = 2
    local default = options.first or "all"
    local fixed = {}
    for _, view in ipairs(ns.Views.FIXED) do
        if view.key == default then table.insert(fixed, 1, view) else fixed[#fixed + 1] = view end
    end
    for _, view in ipairs(fixed) do
        Row(view.word, nil, view.icon, nil, 0, viewing == view.key).view = view.key
    end
    local shownFixed = false
    for _, key in ipairs({ Categories.PINNED, Categories.RECENT }) do
        if options[ns.Bags.SHOW[key]] ~= false then
            local file, atlas = Categories.Icon(key)
            local row = Row(Categories.Word(key), counts[key] or 0, file, atlas, 0, viewing == "cat:" .. key)
            row.view, row.key, row.takes = "cat:" .. key, key, key == Categories.PINNED
            shownFixed = true
        end
    end
    if shownFixed then Divider() end
    local done = {}
    local hideEmpty = options.hideEmpty ~= false
    for _, key in ipairs(Categories.order) do
        local def = Categories.DEF[key]
        local group = Categories.GroupOf(key)
        if not (def and def.fixed) and not Categories.Off(key) then
            if group and not done[group] then
                done[group] = true
                local total = counts["group:" .. group] or 0
                local own = false
                for _, member in ipairs(Categories.Members(group)) do own = own or Categories.Own(member) end
                if total > 0 or not hideEmpty or own then
                    local first = Categories.Members(group)[1]
                    local file, atlas = Categories.Icon(first)
                    local row = Row(Categories.GroupWord(group), total, file, atlas, 0, viewing == "group:" .. group)
                    row.view, row.group = "group:" .. group, group
                    for _, member in ipairs(Categories.Members(group)) do
                        local number = counts[member] or 0
                        if number > 0 or not hideEmpty or Categories.Own(member) then
                            local mfile, matlas = Categories.Icon(member)
                            local memberRow = Row(Categories.Word(member), number, mfile, matlas, 1, viewing == "cat:" .. member)
                            memberRow.view, memberRow.key, memberRow.takes = "cat:" .. member, member, Categories.Takes(member)
                        end
                    end
                end
            elseif not group then
                local number = counts[key] or 0
                if number > 0 or not hideEmpty or Categories.Own(key) then
                    local file, atlas = Categories.Icon(key)
                    local row = Row(Categories.Word(key), number, file, atlas, 0, viewing == "cat:" .. key)
                    row.view, row.key, row.takes = "cat:" .. key, key, Categories.Takes(key)
                end
            end
        end
    end
    if options.addCategory ~= false then
        local row = Row(ns.TEXT.bagsAddCategory, nil, Categories.OWN_ICON, nil, 0, false)
        row.add = true
        row.icon:SetAlpha(0.5)
        row.label:SetAlpha(0.4)
    end
    rows:Done()
    dividers:Done()
    child:SetHeight(math.max(1, y))
end

-------------------------------------------------------------------------------
--  Built once
-------------------------------------------------------------------------------
local function Width()
    return wide and Sidebar.WIDTH or Sidebar.NARROW
end
Sidebar.Width = Width

-- The sidebar as wide as it is now (wide, or folded to its icons).
local function Apply()
    frame:SetWidth(Width())
    label:SetShown(wide)
    arrow:ClearAllPoints()
    if wide then arrow:SetPoint("RIGHT", head, "RIGHT", -6, 0) else arrow:SetPoint("CENTER", head) end
    arrow.icon:SetRotation(wide and 0 or math.pi)
    child:SetWidth(Width())
end

local function Fold()
    wide = not wide
    kept.narrow = not wide
    Apply()
    ns.Bags.Resized()
end

local function ArrowEnter(button)
    button.icon:SetAlpha(0.9)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(wide and ns.TEXT.bagsFold or ns.TEXT.bagsUnfold, 1, 1, 1)
    GameTooltip:Show()
end

local function ArrowLeave(button)
    button.icon:SetAlpha(0.4)
    GameTooltip:Hide()
end

local function Wheel(_, delta)
    local most = math.max(0, child:GetHeight() - scroll:GetHeight())
    scroll:SetVerticalScroll(math.max(0, math.min(most, scroll:GetVerticalScroll() - delta * Sidebar.STEP)))
end

-- The sidebar in the body, under top (the bar) and above bottom (the foot); bags: store.bags.
function Sidebar.Build(body, top, bottom, bags)
    kept = bags
    wide = kept.narrow ~= true
    frame = CreateFrame("Frame", nil, body)
    frame:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    frame:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT")
    frame:SetWidth(Width())
    local back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(Sidebar.SHADE[1], Sidebar.SHADE[2], Sidebar.SHADE[3], Sidebar.SHADE[4])
    local edge = frame:CreateTexture(nil, "BORDER")
    edge:SetColorTexture(ns.Bags.RULE[1], ns.Bags.RULE[2], ns.Bags.RULE[3], ns.Bags.RULE[4])
    edge:SetPoint("TOPRIGHT")
    edge:SetPoint("BOTTOMRIGHT")
    edge:SetWidth(Core.Pixels(frame, 1))
    head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetHeight(Sidebar.HEAD)
    label = head:CreateFontString(nil, "ARTWORK")
    label:SetFontObject(Core.Font("SaneUIBagsSideHead", "GameFontHighlightSmall", 10) or "GameFontHighlightSmall")
    label:SetTextColor(Sidebar.MUTED[1], Sidebar.MUTED[2], Sidebar.MUTED[3])
    label:SetPoint("LEFT", 8, 0)
    label:SetText(ns.TEXT.bagsCategories)
    arrow = CreateFrame("Button", nil, head)
    arrow:SetSize(12, 12)
    arrow.icon = arrow:CreateTexture(nil, "ARTWORK")
    arrow.icon:SetAllPoints()
    arrow.icon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    arrow.icon:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    arrow.icon:SetAlpha(0.4)
    arrow:SetScript("OnClick", function() ns.Safe("bags", Fold) end)
    arrow:SetScript("OnEnter", function(self) ns.Safe("bags", ArrowEnter, self) end)
    arrow:SetScript("OnLeave", function(self) ns.Safe("bags", ArrowLeave, self) end)
    scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", head, "BOTTOMLEFT")
    scroll:SetPoint("BOTTOMRIGHT")
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta) ns.Safe("bags", Wheel, self, delta) end)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(Width(), 1)
    scroll:SetScrollChild(child)
    rows = Core.Pool(MakeRow)
    dividers = Core.Pool(MakeDivider)
    Apply()
    Sidebar.frame = frame
    return frame
end

-- The rows (the tests).
function Sidebar.Rows()
    local list = {}
    for index = 1, rows.taken do list[index] = rows[index] end
    return list
end
