local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Sidebar
--  A window's sidebar, at its left under the bar: a dark column of rows
--  (an icon, a name, a count) under a little head with its name; the names
--  always show. It scrolls with the wheel when its rows are more than its
--  height. The row shown is
--  lit, with a bar at its left in Sane UI's colour. Sidebar.New makes one for
--  a window; the window fills it (Begin, Row, Divider, Done) and answers its
--  clicks (its choose, drop, menu, add). A row the window marks (row.drag)
--  can be dragged: a ghost of it follows the cursor, a line in Sane UI's
--  colour shows where it would go (a row lit in that colour: into it), and
--  where it is let go the window's place puts it (its aim says where a row
--  may go, from how far down the row under the cursor is). A window that
--  answers its fold gets an arrow at the head's right: a click folds the
--  sidebar to a narrow edge with only the arrow, another unfolds it.
--
--  The bags' (ns.BagSidebar): at the top the three views (All Items, One
--  Bag, Each Bag; the one the window opens with first), then Pinned and
--  Recent, a line, every category in the categories' order with how many
--  cells it holds (a group: its name with its members set in under it, each
--  with its own count; on its row an arrow folds its members into it or
--  lists them again, and a box ticks whether All Items divides it into its
--  members or shows it whole), Add Category at the foot. Every category switched
--  on is listed, empty ones too. A click shows that view, category or group; an item brought
--  over a row (picked up, or dragged) and let go there goes into that
--  category (over Pinned: pinned); a right click opens the row's menu
--  (Menus.lua). A category or a group is dragged to another place (never
--  Pinned, Recent or Junk, which stay first and last): let go at a row's
--  top or foot it goes before or after it (between a group's members: into
--  that group; a group goes before or after another group as a whole), at
--  a row's middle it joins that row's group (or makes one with that
--  category: Categories.Join, GroupWith); kept by Categories (kept.order).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sidebar = {}
ns.Sidebars = Sidebar
local Bag = {}
ns.BagSidebar = Bag

Sidebar.WIDTH = 160
Sidebar.FOLDED = 24        -- a folded sidebar: the arrow alone
Sidebar.HEAD = 24
Sidebar.ROW, Sidebar.ROW_GAP = 26, 2
Sidebar.ICON, Sidebar.ICON_SMALL = 18, 16
Sidebar.INDENT = 16
Sidebar.STEP = 28          -- the wheel's step
Sidebar.MUTED = ns.Paper.FAINT  -- counts, the head's word
Sidebar.DIVIDER = { ns.Paper.INK[1], ns.Paper.INK[2], ns.Paper.INK[3], 0.25 }
Sidebar.DIM = 0.75         -- a row's words while not shown
Sidebar.LIT = ns.Paper.CHOSEN[4] -- the row shown: the pencil's shading
Sidebar.HOVER = ns.Paper.SHADE[4]
Sidebar.TAKES = 0.2        -- the shading of a row under the mouse that takes the item held
Sidebar.EDGE = 0.25        -- a row's top and foot quarter: before or after it; between: into it
Sidebar.GHOST = 0.85       -- the dragged row's ghost
Sidebar.LIFTED = 0.35      -- the dragged row itself meanwhile
Sidebar.INTO = 0.2         -- the row it would go into, shaded

local Categories = ns.Categories
local Rail = {}            -- a sidebar's functions
Rail.__index = Rail

local function Fonts()
    return {
        label = ns.Paper.Font("SaneUIBagsSideLabel", 15),
        count = ns.Paper.Font("SaneUIBagsSideCount", 13),
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
    if not (row.rail.tip and row.rail.tip(row)) then RowTip(row) end
    -- Brighter by its colour's alpha (a region's own alpha goes no higher than 1).
    local takes = GetCursorInfo() == "item" and row.takes
    local ink = ns.Paper.INK
    row.hover:SetColorTexture(ink[1], ink[2], ink[3], takes and Sidebar.TAKES or Sidebar.HOVER)
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

-- A row held (dragged) and let go (Rail:Lift, Rail:Land below).
local function Lift(row)
    row.rail:Lift(row)
end

local function Land(row)
    row.rail:Land()
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
    row.hover:SetColorTexture(ns.Paper.INK[1], ns.Paper.INK[2], ns.Paper.INK[3], Sidebar.HOVER)
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
    row.count:SetTextColor(Sidebar.MUTED[1], Sidebar.MUTED[2], Sidebar.MUTED[3], Sidebar.MUTED[4])
    row.count:SetPoint("RIGHT", -6, 0)
    row:SetScript("OnEnter", function(self) ns.Safe("bags", RowEnter, self) end)
    row:SetScript("OnLeave", function(self) ns.Safe("bags", RowLeave, self) end)
    row:SetScript("OnClick", function(self, mouse) ns.Safe("bags", RowClick, self, mouse) end)
    row:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", RowDrop, self) end)
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function(self) ns.Safe("bags", Lift, self) end)
    row:SetScript("OnDragStop", function(self) ns.Safe("bags", Land, self) end)
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
    return self.folded and (self.narrow or Sidebar.FOLDED) or Sidebar.WIDTH
end

-- Folded to its narrow edge (the arrow alone) or unfolded; the window is told (its fold).
function Rail:Fold(on)
    self.folded = on and true or false
    self.frame:SetWidth(self:Width())
    self.scroll:SetShown(not on)
    self.label:SetShown(not on)
    if self.arrow then
        self.arrow.text:SetText(on and ">" or "<")
        self.arrow:ClearAllPoints()
        if on then
            self.arrow:SetPoint("TOP", self.frame, "TOP", 0, -2)
        else
            self.arrow:SetPoint("RIGHT", self.head, "RIGHT", -4, 0)
        end
    end
end

local function ArrowEnter(arrow)
    arrow.text:SetAlpha(1)
    GameTooltip:SetOwner(arrow, "ANCHOR_RIGHT")
    GameTooltip:SetText(arrow.rail.folded and ns.TEXT.sideUnfold or ns.TEXT.sideFold, 1, 1, 1)
    GameTooltip:Show()
end

-- A click: folded or unfolded by the window, the tooltip saying what the next click does.
local function ArrowClick(arrow)
    local rail = arrow.rail
    rail.fold(not rail.folded)
    if GameTooltip:IsOwned(arrow) then ArrowEnter(arrow) end
end

local function ArrowLeave(arrow)
    arrow.text:SetAlpha(0.6)
    GameTooltip:Hide()
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
    row.drag, row.inside, row.last = false, nil, nil
    row.depth, row.file, row.atlas, row.top = depth, file, atlas, self.y
    row:SetAlpha(1)
    local size = depth > 0 and Sidebar.ICON_SMALL or Sidebar.ICON
    row.icon:SetSize(size, size)
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", 8 + depth * Sidebar.INDENT, 0)
    Icon(row.icon, file, atlas)
    row.icon:SetAlpha(1)
    row.label:SetText(word)
    row.label:SetAlpha(shown and 1 or Sidebar.DIM)
    row.label:SetPoint("RIGHT", -30, 0)
    if row.arrow then row.arrow:Hide(); row.box:Hide() end
    row.count:SetText(number and tostring(number) or "")
    local ink = ns.Paper.INK
    row.bar:SetColorTexture(ink[1], ink[2], ink[3], 0.8)
    row.bar:SetWidth(Core.Pixels(row, 2))
    row.bar:SetShown(shown)
    row.back:SetColorTexture(ink[1], ink[2], ink[3], Sidebar.LIT)
    row.back:SetShown(shown)
    row:Show()
    self.y = self.y + Sidebar.ROW + Sidebar.ROW_GAP
    return row
end

-- A group's row: its arrow (folded: its members not listed) and its box (ticked: divided into its members in All
-- Items); fold(row) and tick(row) answer their clicks.
local function ArrowOf(button) button.row.rail.folder(button.row) end
local function BoxOf(button) button.row.rail.ticker(button.row) end
local function ToggleTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(button.tip, 1, 1, 1)
    GameTooltip:Show()
end

local function Toggle(row, click, size)
    local button = CreateFrame("Button", nil, row)
    button:SetSize(size, size)
    button.row = row
    button:SetScript("OnClick", function(self) ns.Safe("bags", click, self) end)
    button:SetScript("OnEnter", function(self) ns.Safe("bags", ToggleTip, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

function Rail:Toggles(row, folded, ticked, fold, tick)
    self.folder, self.ticker = fold, tick
    if not row.arrow then
        local ink = ns.Paper.INK
        row.arrow = Toggle(row, ArrowOf, 13)
        -- the game's small arrow, in graphite
        row.arrow.mark = row.arrow:CreateTexture(nil, "ARTWORK")
        row.arrow.mark:SetAllPoints()
        row.arrow.mark:SetDesaturated(true)
        row.arrow.mark:SetVertexColor(ink[1], ink[2], ink[3], 0.85)
        row.box = Toggle(row, BoxOf, 14)
        local box = Core.Journal.Box(row.box, 0.4)
        box:SetStrong(true)
        row.box.check = row.box:CreateTexture(nil, "OVERLAY")
        row.box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row.box.check:SetDesaturated(true)
        row.box.check:SetVertexColor(ink[1], ink[2], ink[3], 0.9)
        row.box.check:SetPoint("TOPLEFT", -2, 2)
        row.box.check:SetPoint("BOTTOMRIGHT", 2, -2)
        row.box:SetPoint("RIGHT", row.count, "LEFT", -6, 0)
        row.arrow:SetPoint("RIGHT", row.box, "LEFT", -3, 0)
    end
    row.arrow.mark:SetTexture(folded and "Interface\\Buttons\\Arrow-Down-Up" or "Interface\\Buttons\\Arrow-Up-Up")
    row.arrow.mark:SetDesaturated(true)
    row.arrow.tip = folded and ns.TEXT.bagsGroupUnfold or ns.TEXT.bagsGroupFold
    row.box.check:SetShown(ticked)
    row.box.tip = ticked and ns.TEXT.bagsGroupWhole or ns.TEXT.bagsGroupDivide
    row.arrow:Show()
    row.box:Show()
    row.label:SetPoint("RIGHT", row.arrow, "LEFT", -2, 0)
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
--  Dragging a row to another place
-------------------------------------------------------------------------------
-- The row under the cursor and how far down it the cursor is (0 its top, 1 its foot); nil off the rows.
function Rail:Under()
    if not self.frame:IsMouseOver() then return nil end
    local top = self.child:GetTop()
    if not top then return nil end
    local _, y = GetCursorPosition()
    y = top - y / self.child:GetEffectiveScale()
    local half = Sidebar.ROW_GAP / 2
    for index = 1, self.rows.taken do
        local row = self.rows[index]
        if row:IsShown() and y >= row.top - half and y < row.top + Sidebar.ROW + half then
            return row, math.max(0, math.min(1, (y - row.top) / Sidebar.ROW))
        end
    end
end

-- Where the row held would go now: the window's aim says (row held, row under the cursor, how far down it) where
-- ("before", "after", "into"), whether into a group (the line set in) and perhaps another row to show it at.
local aimed = {}
function Rail:Aim()
    local over, part = self:Under()
    if not (over and self.aim and self.lifted) then return nil end
    local where, inside, at = self.aim(self.lifted, over, part)
    if not where then return nil end
    aimed.row, aimed.where, aimed.inside = at or over, where, inside
    return aimed
end

-- The line where the row held would go, or the row it would go into lit.
function Rail:Show(target)
    self.line:Hide()
    self.mark:Hide()
    if not target then return end
    local row = target.row
    if target.where == "into" then
        self.mark:ClearAllPoints()
        self.mark:SetAllPoints(row)
        self.mark:Show()
        return
    end
    local y = target.where == "before" and row.top - Sidebar.ROW_GAP / 2 or row.top + Sidebar.ROW + Sidebar.ROW_GAP / 2
    local indent = 4 + (target.inside and Sidebar.INDENT or 0)
    local thick = Core.Pixels(self.child, 2)
    self.line:ClearAllPoints()
    self.line:SetPoint("TOPLEFT", self.child, "TOPLEFT", indent, -(y - thick / 2))
    self.line:SetSize(self:Width() - indent - 5, thick)
    self.line:Show()
end

-- The ghost follows the cursor, the line shows where the row would go (looked at again only when the cursor moved).
local function Follow(ghost)
    local rail = ghost.rail
    local button = rawget(_G, "IsMouseButtonDown")
    if not rail.lifted or button and not button("LeftButton") then return rail:Cancel() end
    local x, y = GetCursorPosition()
    if x == ghost.x and y == ghost.y then return end
    ghost.x, ghost.y = x, y
    local scale = UIParent:GetEffectiveScale()
    ghost:ClearAllPoints()
    ghost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", x / scale + 12, y / scale)
    rail:Show(rail:Aim())
end
local Following = ns.Guard(Follow)

-- The ghost of a row held, the line and the light; made at the first drag.
local function Ghost(rail)
    local ghost = CreateFrame("Frame", nil, UIParent)
    ghost.rail = rail
    ghost:SetSize(Sidebar.WIDTH, Sidebar.ROW)
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetAlpha(Sidebar.GHOST)
    local back = ghost:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(220 / 255, 204 / 255, 178 / 255, 0.95) -- a scrap of the page
    local gold = ns.Paper.INK
    ns.Cells.Edge(ns.Cells.Border(ghost), gold[1], gold[2], gold[3], 0.8, Core.Pixels(ghost, 1))
    ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
    ghost.icon:SetSize(Sidebar.ICON, Sidebar.ICON)
    ghost.icon:SetPoint("LEFT", 8, 0)
    ghost.label = ghost:CreateFontString(nil, "ARTWORK")
    local font = Fonts()
    if font.label then ghost.label:SetFontObject(font.label) end
    ghost.label:SetPoint("LEFT", ghost.icon, "RIGHT", 6, 0)
    ghost.label:SetPoint("RIGHT", -6, 0)
    ghost.label:SetJustifyH("LEFT")
    ghost.label:SetWordWrap(false)
    ghost:SetScript("OnUpdate", Following)
    ghost:Hide()
    rail.ghost = ghost
    rail.line = rail.child:CreateTexture(nil, "OVERLAY")
    rail.line:SetColorTexture(gold[1], gold[2], gold[3], 1)
    rail.line:Hide()
    rail.mark = rail.child:CreateTexture(nil, "OVERLAY")
    rail.mark:SetColorTexture(gold[1], gold[2], gold[3], Sidebar.INTO)
    rail.mark:Hide()
    return ghost
end

-- A row marked to be dragged (row.drag) held: its ghost on the cursor (not while an item is on it).
function Rail:Lift(row)
    if not (row.drag and self.aim and self.place) or GetCursorInfo() then return end
    self.lifted = row
    local ghost = self.ghost or Ghost(self)
    Icon(ghost.icon, row.file, row.atlas)
    ghost.label:SetText(row.word or "")
    ghost.x, ghost.y = nil, nil
    row:SetAlpha(Sidebar.LIFTED)
    ghost:Show()
    self:Show(self:Aim())
end

-- The row held let go: put where the line showed, if anywhere.
function Rail:Land()
    local lifted = self.lifted
    if not lifted then return end
    local target = self:Aim()
    local over, where = target and target.row, target and target.where
    self:Cancel()
    if over then
        Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
        self.place(lifted, over, where)
    end
end

-- No row held any more: the ghost, the line and the light gone.
function Rail:Cancel()
    if self.lifted then self.lifted:SetAlpha(1) end
    self.lifted = nil
    if self.ghost then
        self.ghost:Hide()
        self.line:Hide()
        self.mark:Hide()
    end
end

-------------------------------------------------------------------------------
--  A sidebar made
-------------------------------------------------------------------------------
local function Wheel(rail, delta)
    local most = math.max(0, rail.child:GetHeight() - rail.scroll:GetHeight())
    rail.scroll:SetVerticalScroll(math.max(0, math.min(most, rail.scroll:GetVerticalScroll() - delta * Sidebar.STEP)))
end

-- A sidebar in body, under top and above bottom. options: { word (its head's), choose(view), drop(row), menu(row),
-- add(row), tip(row) (a row's own tooltip: true when it showed one), aim(held, over, part) and place(held, over,
-- where) for rows dragged, fold(on) (the arrow's click: the window folds it, Rail:Fold), narrow (its width
-- folded: Sidebar.FOLDED, or more for what stands at its foot) }.
function Sidebar.New(body, top, bottom, options)
    local rail = setmetatable({ choose = options.choose, drop = options.drop, menu = options.menu, add = options.add,
                                tip = options.tip, aim = options.aim, place = options.place,
                                narrow = options.narrow }, Rail)
    local frame = CreateFrame("Frame", nil, body)
    frame:SetWidth(Sidebar.WIDTH)
    frame:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    frame:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT")
    rail.frame = frame
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
    label:SetFontObject(ns.Paper.Font("SaneUIBagsSideHead", 14, true))
    label:SetTextColor(ns.Paper.SOFT[1], ns.Paper.SOFT[2], ns.Paper.SOFT[3], ns.Paper.SOFT[4])
    label:SetPoint("LEFT", 8, 0)
    label:SetText(options.word or "")
    rail.label = label
    if options.fold then
        rail.fold = options.fold
        local arrow = CreateFrame("Button", nil, frame)
        arrow:SetSize(Sidebar.FOLDED - 4, Sidebar.HEAD - 4)
        arrow:SetFrameLevel(head:GetFrameLevel() + 2)
        arrow.rail = rail
        arrow.text = arrow:CreateFontString(nil, "ARTWORK")
        arrow.text:SetFontObject(ns.Paper.Font("SaneUIBagsSideArrow", 16, true))
        arrow.text:SetTextColor(ns.Paper.INK[1], ns.Paper.INK[2], ns.Paper.INK[3])
        arrow.text:SetAlpha(0.6)
        arrow.text:SetPoint("CENTER")
        arrow:SetScript("OnClick", function(self) ns.Safe("bags", ArrowClick, self) end)
        arrow:SetScript("OnEnter", function(self) ns.Safe("bags", ArrowEnter, self) end)
        arrow:SetScript("OnLeave", function(self) ns.Safe("bags", ArrowLeave, self) end)
        rail.arrow = arrow
    end
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
    rail:Fold(false)
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
                row.view, row.group, row.drag = "group:" .. group, group, true
                row.takes = ns.Menus.Takes("group:" .. group)
                local folded = Categories.Folded(group)
                rail:Toggles(row, folded, Categories.Divided(group), Bag.FoldGroup, Bag.DivideGroup)
                for _, member in ipairs(Categories.Members(group)) do
                    if not Categories.Off(member) and not folded then
                        local mfile, matlas = Categories.Icon(member)
                        local memberRow = rail:Row(Categories.Word(member), counts[member] or 0, mfile, matlas, 1,
                            viewing == "cat:" .. member)
                        memberRow.view, memberRow.key, memberRow.takes = "cat:" .. member, member, Categories.Takes(member)
                        memberRow.drag, memberRow.inside = true, group
                        row.last = memberRow
                    end
                end
            elseif not group then
                local file, atlas = Categories.Icon(key)
                local row = rail:Row(Categories.Word(key), counts[key] or 0, file, atlas, 0, viewing == "cat:" .. key)
                row.view, row.key, row.takes = "cat:" .. key, key, Categories.Takes(key)
                row.drag = Categories.Movable(key)
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

-- A group's arrow: its members folded into its row, or listed again (kept).
function Bag.FoldGroup(row)
    Categories.Fold(row.group, not Categories.Folded(row.group))
    ns.Bags.Refresh()
end

-- A group's box: All Items divides it into its members, or shows it whole (kept).
function Bag.DivideGroup(row)
    Categories.Divide(row.group, not Categories.Divided(row.group))
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    ns.Bags.Refresh()
    if ns.Bank then ns.Bank.Refresh() end
end

-- Room kept free at the sidebar's foot (the bags' waste bin stands there), its rows scrolling above it.
function Bag.Room(bottom)
    if rail then rail.scroll:SetPoint("BOTTOMRIGHT", 0, bottom) end
end

-- Folded or unfolded (Bags.Fold keeps it).
function Bag.Fold(on)
    if rail then rail:Fold(on) end
end

-------------------------------------------------------------------------------
--  Dragging a category or a group
-------------------------------------------------------------------------------
-- Where a row held (lifted) would go over another row, part of the way down it: "before", "after" or "into" (its
-- group, or a new one with it), whether that is inside a group, and the row to show it at; nil: nowhere. Pinned
-- and Recent take nothing; Junk only before it; a group goes before or after a group as a whole.
function Bag.Aim(lifted, over, part)
    if over == lifted or not (over.key or over.group) then return nil end
    local def = over.key and Categories.DEF[over.key]
    if def and def.fixed then return nil end
    if def and def.last then return "before", false end
    local group = lifted.group
    if group then
        if over.group == group or over.inside == group then return nil end
        if over.inside then
            for _, row in ipairs(rail:Rows()) do
                if row.group == over.inside then return "after", false, row.last end
            end
            return nil
        end
        if over.group and part >= 0.5 then return "after", false, over.last or over end
        return part < 0.5 and "before" or "after", false
    end
    local key = lifted.key
    if over.key == key then return nil end
    local edge = Sidebar.EDGE
    if part > edge and part < 1 - edge and Categories.Groupable(key) and (over.group or Categories.Groupable(over.key)) then
        return "into", false
    end
    local where = part < 0.5 and "before" or "after"
    return where, over.inside ~= nil or over.group ~= nil and where == "after"
end

-- The row held let go there: the category or group put in its new place (Categories.Place, PlaceGroup), or into a
-- group (Join, GroupWith); the window drawn anew.
function Bag.Place(lifted, over, where)
    local key, group = lifted.key, lifted.group
    local def = over.key and Categories.DEF[over.key]
    local target, after, into
    if def and def.last then
        target, after = nil, true
    elseif over.group then
        local members = Categories.Members(over.group)
        if where == "before" then
            target, after = members[1], false
        elseif group then
            target, after = members[#members], true
        else
            target, after, into = members[1], false, over.group
        end
    else
        target, after, into = over.key, where == "after", over.inside
    end
    if group then
        Categories.PlaceGroup(group, target, after)
    elseif where == "into" then
        local theirs = over.group or Categories.GroupOf(over.key)
        if theirs then Categories.Join(key, theirs) else Categories.GroupWith(key, over.key) end
    else
        Categories.Place(key, target, after, into)
    end
    ns.Bags.Refresh()
end

-- A drag under way given up (the window hidden).
function Bag.Cancel()
    if rail then rail:Cancel() end
end

-- The bags' sidebar in the body, under top (the bar) and above bottom (the foot); bags: store.bags.
function Bag.Build(body, top, bottom, bags)
    rail = Sidebar.New(body, top, bottom, {
        word = ns.TEXT.bagsCategories,
        choose = function(view) ns.Bags.Choose(view) end,
        drop = function(row) ns.Menus.Drop(row.key or row.group and ("group:" .. row.group), true) end,
        menu = function(row) if row.key or row.group then ns.Menus.Row(row, row.key, row.group) end end,
        add = function(row) ns.Menus.Add(row) end,
        aim = Bag.Aim,
        place = Bag.Place,
        fold = function(on) ns.Bags.Fold(on) end,
        narrow = ns.Bags.TRASH_FOLDED,
    })
    Bag.frame = rail.frame
    return rail.frame
end

-- The rows (the tests).
function Bag.Rows()
    return rail and rail:Rows() or {}
end
