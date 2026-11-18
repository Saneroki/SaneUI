local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Guild - Kit
--  The parts the guild window's views are built from, all of the game's own
--  (Doc/guides/gui-development.md): a sunken inset (InsetFrameTemplate), a
--  panel (an inset with a heading), a table (the game's scrolling list with
--  column heads to sort by), a class icon (the game's class circles), a class
--  colour, the guild's crest (its tabard, as the game's guild window draws it,
--  in a ring), a line of text that says a list is empty.
--
--      local panel = Kit.Panel(parent, "Who Is Where")   -- panel.body: what it holds; panel.tag: text at the right
--      local list = Kit.Table(parent, { columns = { { key, text, width, justify } }, row = 22,
--          init = function(row, element) end, click = function(row, element, button) end, sort = function(key) end })
--      list:Fill(elements, "Nobody here.")                -- the rows, and what is said while there are none
--      list:Sorted(key, descending)                       -- the column head that sorts, marked
--      Kit.ClassIcon(texture, "MAGE")   Kit.ClassColor("MAGE") -> r, g, b
--      local crest = Kit.Crest(parent, size)  crest:Update()   -- the guild's emblem in its ring
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout = ns.Layout
local Kit = {}
ns.Kit = Kit

-- A sunken area, as the game's windows have them; a plain dark fill where the client lacks the template.
function Kit.Inset(parent)
    local ok, inset = pcall(CreateFrame, "Frame", nil, parent, "InsetFrameTemplate")
    if ok and inset then return inset end
    inset = CreateFrame("Frame", nil, parent)
    local fill = inset:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(0, 0, 0, 0.35)
    return inset
end

-- An inset with a heading at its top (the game's gold), a tag at the heading's right, and a body under it.
function Kit.Panel(parent, title)
    local panel = Kit.Inset(parent)
    panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", 8, -6)
    panel.title:SetText(title or "")
    panel.tag = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    panel.tag:SetPoint("TOPRIGHT", -8, -7)
    panel.tag:SetJustifyH("RIGHT")
    panel.line = panel:CreateTexture(nil, "ARTWORK")
    panel.line:SetColorTexture(1, 1, 1, 0.08)
    panel.line:SetHeight(1)
    panel.line:SetPoint("TOPLEFT", 4, -Layout.PANEL_HEAD)
    panel.line:SetPoint("TOPRIGHT", -4, -Layout.PANEL_HEAD)
    panel.body = CreateFrame("Frame", nil, panel)
    panel.body:SetPoint("TOPLEFT", 4, -Layout.PANEL_HEAD - 2)
    panel.body:SetPoint("BOTTOMRIGHT", -4, 4)
    return panel
end

-- A line in a region's middle that says it holds nothing.
function Kit.Empty(parent, font)
    local text = parent:CreateFontString(nil, "ARTWORK", font or "GameFontDisable")
    text:SetPoint("LEFT", 12, 0)
    text:SetPoint("RIGHT", -12, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(true)
    return text
end

-- A class's colour as the game gives it (r, g, b); the game's grey for none.
function Kit.ClassColor(class)
    local colors = rawget(_G, "RAID_CLASS_COLORS")
    local color = class and colors and colors[class]
    if color then return color.r, color.g, color.b end
    return 0.62, 0.62, 0.62
end

-- A class's name in its colour.
function Kit.Colored(text, class)
    local r, g, b = Kit.ClassColor(class)
    return ("|cff%s%s|r"):format(Core.Hex(r, g, b), text or "")
end

-- The class's round icon (the game's class circles); a question mark for none.
function Kit.ClassIcon(texture, class)
    local coords = rawget(_G, "CLASS_ICON_TCOORDS")
    local where = class and coords and coords[class]
    if where then
        texture:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        texture:SetTexCoord(unpack(where))
    else
        texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-------------------------------------------------------------------------------
--  The guild's crest: its tabard's background, emblem and border, in a ring
-------------------------------------------------------------------------------
local crest = {}

function crest:Update()
    local drawn = IsInGuild and IsInGuild() and rawget(_G, "SetLargeGuildTabardTextures")
        and pcall(SetLargeGuildTabardTextures, "player", self.emblem, self.background, self.border)
    self.background:SetShown(drawn and true or false)
    self.border:SetShown(drawn and true or false)
    if not drawn then
        ns.Art.Set(self.emblem, "noEmblem")
    end
end

function Kit.Crest(parent, size)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    local inner = math.floor(size * Layout.EMBLEM / Layout.CREST)
    frame.background = frame:CreateTexture(nil, "BACKGROUND")
    frame.emblem = frame:CreateTexture(nil, "BORDER")
    frame.border = frame:CreateTexture(nil, "ARTWORK")
    for _, texture in ipairs({ frame.background, frame.emblem, frame.border }) do
        texture:SetSize(inner, inner)
        texture:SetPoint("CENTER")
    end
    frame.ring = frame:CreateTexture(nil, "OVERLAY")
    frame.ring:SetAllPoints()
    ns.Art.Set(frame.ring, "crestRing")
    for name, fn in pairs(crest) do frame[name] = fn end
    return frame
end

-------------------------------------------------------------------------------
--  Tables: the game's scrolling list, column heads above it
-------------------------------------------------------------------------------
local table_ = {}

-- Where each column starts and how wide it is, for a list that wide: fixed widths as given, the one without
-- a width takes the rest.
function Kit.Columns(columns, width)
    local fixed, flexible = 0, 0
    for _, column in ipairs(columns) do
        if column.width then fixed = fixed + column.width else flexible = flexible + 1 end
    end
    local gap = 6
    local rest = math.max(40, width - fixed - gap * (#columns + 1))
    local laid, x = {}, gap
    for index, column in ipairs(columns) do
        local wide = column.width or math.floor(rest / math.max(1, flexible))
        laid[index] = { x = x, width = wide }
        x = x + wide + gap
    end
    return laid
end

local function Cells(list, row)
    if row.cells then return end
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
    local highlight = row:GetHighlightTexture()
    if highlight then highlight:SetVertexColor(0.243, 0.570, 1) end -- the game's HIGHLIGHT_LIGHT_BLUE
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(Layout.ICON, Layout.ICON)
    row.cells = {}
    for index, column in ipairs(list.columns) do
        local cell = row:CreateFontString(nil, "ARTWORK", column.font or "GameFontHighlightSmall")
        cell:SetJustifyH(column.justify or "LEFT")
        cell:SetWordWrap(false)
        row.cells[index] = cell
        row.cells[column.key] = cell
    end
    row:SetScript("OnClick", ns.Guard(function(self, button)
        if list.click and self.element then list.click(self, self.element, button) end
    end))
end

-- A row laid out by the columns of the list's width now: each cell at its column, the icon before the first.
local function Place(list, row)
    local laid = list.laid
    if not laid then return end
    for index, cell in ipairs(row.cells) do
        local at = laid[index]
        cell:ClearAllPoints()
        local left = at.x + (index == 1 and list.iconRoom or 0)
        cell:SetPoint("LEFT", row, "LEFT", left, 0)
        cell:SetWidth(math.max(10, at.width - (index == 1 and list.iconRoom or 0)))
    end
    row.icon:ClearAllPoints()
    row.icon:SetPoint("LEFT", row, "LEFT", laid[1].x, 0)
end

-- A row drawn for its element: its cells made once, placed by the columns, filled by the list's init.
local function Draw(list, row, element)
    Cells(list, row)
    Place(list, row)
    row.element = element
    list.init(row, element)
end

-- The rows anew, the list left where it was scrolled to, as the game's own lists are refilled (a flush would
-- scroll it back to the top: ScrollBox's full update of an empty list).
function table_:Fill(elements, emptyText)
    self.provider = CreateDataProvider(elements)
    self.box:SetDataProvider(self.provider, ScrollBoxConstants.RetainScrollPosition)
    self.empty:SetText(emptyText or "")
    self.empty:SetShown(#elements == 0)
end

-- The column head of that key marked as the one the list is sorted by.
function table_:Sorted(key, descending)
    for _, head in ipairs(self.heads) do
        local text = head.column.text or ""
        if head.column.key == key then text = text .. (descending and " v" or " ^") end
        head.label:SetText(text)
    end
end

-- The list is that wide now: its columns laid out anew, the rows on show placed by them.
function table_:Fit(width)
    width = math.floor(width or self:GetWidth() or 0)
    if width <= 0 or width == self.width then return end
    self.width = width
    self.laid = Kit.Columns(self.columns, width - 16)
    for index, head in ipairs(self.heads) do
        local at = self.laid[index]
        head:ClearAllPoints()
        head:SetPoint("LEFT", self.head, "LEFT", at.x, 0)
        head:SetSize(at.width, Layout.HEADER)
    end
    if self.box.ForEachFrame then
        self.box:ForEachFrame(function(row) if row.cells then Place(self, row) end end)
    end
end

function Kit.Table(parent, options)
    local list = CreateFrame("Frame", nil, parent)
    for name, fn in pairs(table_) do list[name] = fn end
    list.columns, list.click, list.init = options.columns, options.click, options.init
    list.iconRoom = options.icon and (Layout.ICON + 4) or 0
    list.head = CreateFrame("Frame", nil, list)
    list.head:SetPoint("TOPLEFT")
    list.head:SetPoint("TOPRIGHT", -16, 0)
    list.head:SetHeight(Layout.HEADER)
    list.heads = {}
    for index, column in ipairs(options.columns) do
        local head = CreateFrame("Button", nil, list.head)
        head.column = column
        head.label = head:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        head.label:SetAllPoints()
        head.label:SetJustifyH(column.justify or "LEFT")
        head.label:SetText(column.text or "")
        if options.sort and column.sort ~= false then
            head:SetScript("OnClick", ns.Guard(function() options.sort(column.key) end))
            head:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
        end
        list.heads[index] = head
    end
    local box = CreateFrame("Frame", nil, list, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", list.head, "BOTTOMLEFT", 0, -2)
    box:SetPoint("BOTTOMRIGHT", -16, 0)
    local bar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 2)
    local view = CreateScrollBoxListLinearView(0, 0, 0, 0, 0)
    view:SetElementExtent(options.row or Layout.ROW)
    view:SetElementInitializer("Button", function(row, element) ns.Safe("list", Draw, list, row, element) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    list.box, list.bar = box, bar
    list.provider = CreateDataProvider()
    box:SetDataProvider(list.provider)
    list.empty = Kit.Empty(list)
    list:SetScript("OnSizeChanged", ns.Guard(function(self, width) self:Fit(width) end))
    return list
end

-- A row's zebra stripe: every other row a little lighter, as the game's lists.
function Kit.Stripe(row, index)
    row.back:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.03 or 0)
end
