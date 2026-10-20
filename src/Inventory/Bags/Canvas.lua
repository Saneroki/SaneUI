local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Canvas
--  Where a window of items (the bags, the bank) draws what Layout.lua laid
--  out, in its scroll area's child: the heads (a part's, a block's, a group
--  member's: its words and number, a thin line to the right edge), the
--  compact display's labels, the "+" cells, the list's lines (a word for
--  each column shown, Columns.lua), the pads and the item buttons (the
--  window's pool, Cells.lua). Each window has its own (Canvas.New).
--
--  A block's head takes an item let go over it and opens the category's menu
--  at a right click (Menus.lua); in the list a click folds the block, Shift
--  and a click every block (kept in the window's store: folded). A "+" takes
--  an item brought to it, or (the bags) starts choosing one by a click
--  (Select.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Canvas = {}
ns.Canvas = Canvas
local Sheet = {}   -- a canvas's functions
Sheet.__index = Sheet

Canvas.INSET = 8   -- from the scroll area's left to the items
Canvas.HEAD_COLOR = { 0.7, 0.7, 0.7 }
Canvas.MEMBER_COLOR = { 0.55, 0.55, 0.55 }
Canvas.HEAD_LINE = { 0.7, 0.7, 0.7, 0.2 }

local Layout, Cells, Columns, Menus, Categories = ns.Layout, ns.Cells, ns.Columns, ns.Menus, ns.Categories

-- The fonts of a canvas's words: a category's head, a group member's, a part's.
local fonts
local function Fonts()
    if fonts then return fonts end
    fonts = {
        head = Core.Font("SaneUIBagsHead", "GameFontHighlightSmall", 11),
        member = Core.Font("SaneUIBagsMember", "GameFontHighlightSmall", 10),
        part = Core.Font("SaneUIBagsPart", "GameFontHighlight", 13),
    }
    return fonts
end

-- What a block folds by in the list (its category, its group, else its name).
local function Fold(block)
    return block.key or block.group and ("group:" .. block.group) or block.word
end
Canvas.Fold = Fold

-------------------------------------------------------------------------------
--  Heads
-------------------------------------------------------------------------------
-- A head clicked in the list: its block folded or unfolded; with Shift every block.
local function Folded(head)
    local canvas, key = head.canvas, head.fold
    if not key then return end
    local store = canvas.owner.store
    store.folded = type(store.folded) == "table" and store.folded or {}
    local fold = not store.folded[key]
    local shift = rawget(_G, "IsShiftKeyDown")
    if shift and shift() then
        local blocks = canvas.blocks
        for index = 1, blocks and blocks.count or 0 do store.folded[Fold(blocks[index])] = fold or nil end
    else
        store.folded[key] = fold or nil
    end
    Core.Sound(fold and "IG_MAINMENU_OPTION_CHECKBOX_OFF" or "IG_MAINMENU_OPTION_CHECKBOX_ON")
    canvas.owner.redraw()
end

-- A right click opens the category's menu, an item let go over the head is put into it; in the list a click
-- folds.
local function HeadUp(head, mouse)
    if mouse == "RightButton" then
        Menus.Row(head, head.key, head.group)
    elseif mouse == "LeftButton" and GetCursorInfo() then
        Menus.Drop(head.key)
    elseif mouse == "LeftButton" and head.fold then
        Folded(head)
    end
end

local function HeadDrop(head)
    Menus.Drop(head.key)
end

local function HeadEnter(head)
    head.lit:SetShown(GetCursorInfo() == "item" and Menus.Takes(head.key))
    if head.key or head.group then Menus.Tip(head, head.key, head.group) end
end

local function HeadLeave(head)
    head.lit:Hide()
    GameTooltip:Hide()
end

local function MakeHead(canvas)
    local head = CreateFrame("Frame", nil, canvas.child)
    head.canvas = canvas
    head.lit = head:CreateTexture(nil, "BACKGROUND")
    head.lit:SetAllPoints()
    head.lit:SetColorTexture(1, 1, 1, 0.08)
    head.lit:Hide()
    head.arrow = head:CreateTexture(nil, "ARTWORK")
    head.arrow:SetSize(12, 12)
    head.arrow:SetPoint("LEFT")
    head.arrow:SetAlpha(0.6)
    head.word = head:CreateFontString(nil, "ARTWORK")
    head.word:SetPoint("LEFT")
    head.word:SetJustifyH("LEFT")
    head.number = head:CreateFontString(nil, "ARTWORK")
    head.number:SetPoint("LEFT", head.word, "RIGHT", 4, 0)
    head.line = head:CreateTexture(nil, "ARTWORK")
    head.line:SetPoint("LEFT", head.number, "RIGHT", 6, 0)
    head.line:SetPoint("RIGHT", -Layout.GAP, 0)
    head:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", HeadUp, self, mouse) end)
    head:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", HeadDrop, self) end)
    head:SetScript("OnEnter", function(self) ns.Safe("bags", HeadEnter, self) end)
    head:SetScript("OnLeave", function(self) ns.Safe("bags", HeadLeave, self) end)
    return head
end

function Sheet:Head(place)
    local head = self.heads:Take()
    local block = place.block
    local font, line = Fonts(), Canvas.HEAD_LINE
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    head:SetSize(place.width, place.height)
    local object = place.level == 1 and font.part or place.level == 3 and font.member or font.head
    if object then head.word:SetFontObject(object); head.number:SetFontObject(object) end
    head.word:SetText(block.word or "")
    local color = place.level == 3 and Canvas.MEMBER_COLOR or Canvas.HEAD_COLOR
    if place.level == 1 then head.word:SetTextColor(1, 1, 1) else head.word:SetTextColor(color[1], color[2], color[3]) end
    head.number:SetTextColor(color[1], color[2], color[3], 0.9)
    head.number:SetText(block.number and "(" .. tostring(block.number) .. ")" or "")
    head.line:SetColorTexture(line[1], line[2], line[3], place.level == 3 and line[4] / 2 or line[4])
    head.line:SetHeight(Core.Pixels(head, 1))
    head.key, head.group = block.key, block.group
    local list = self.owner.store.look == "list" and place.level ~= 1
    head.fold = list and Fold(block) or nil
    head.arrow:SetShown(list)
    if list then
        head.arrow:SetTexture(block.folded and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    end
    head.word:ClearAllPoints()
    head.word:SetPoint("LEFT", list and 16 or 0, 0)
    head:EnableMouse(block.key ~= nil or block.group ~= nil or list)
    head.lit:Hide()
    head:Show()
end

-------------------------------------------------------------------------------
--  Labels and "+"
-------------------------------------------------------------------------------
-- A block's name over it in the compact display, cut short with its whole name in the tooltip.
local function LabelEnter(label)
    if not label.text:IsTruncated() then return end
    GameTooltip:SetOwner(label, "ANCHOR_TOP")
    GameTooltip:SetText(label.text:GetText() or "", 1, 1, 1)
    GameTooltip:Show()
end

local function MakeLabel(canvas)
    local label = CreateFrame("Frame", nil, canvas.child)
    label.canvas = canvas
    label.text = label:CreateFontString(nil, "ARTWORK")
    label.text:SetPoint("LEFT")
    label.text:SetPoint("RIGHT")
    label.text:SetJustifyH("LEFT")
    label.text:SetWordWrap(false)
    label:SetScript("OnEnter", function(self) ns.Safe("bags", LabelEnter, self) end)
    label:SetScript("OnLeave", GameTooltip_Hide)
    label:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", HeadUp, self, mouse) end)
    label:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", HeadDrop, self) end)
    return label
end

function Sheet:Label(place)
    local label = self.labels:Take()
    local block, color = place.block, Canvas.HEAD_COLOR
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    label:SetSize(place.width, place.height)
    local object = Fonts().member
    if object then label.text:SetFontObject(object) end
    label.text:SetTextColor(color[1], color[2], color[3])
    label.text:SetText(block.word or "")
    label.key, label.group = block.key, block.group
    label:Show()
end

-- A block's "+": an item brought to it (picked up and clicked here, or dragged here) goes into its category
-- (Pinned's: pinned); clicked with nothing, the next item clicked does (Select.lua).
local function PlusClick(plus)
    if GetCursorInfo() == "item" then return Menus.Drop(plus.key) end
    ns.Select.Start("put", plus.key)
end

local function PlusEnter(plus)
    plus.sign:SetAlpha(1)
    GameTooltip:SetOwner(plus, "ANCHOR_TOP")
    GameTooltip:SetText(Categories.Word(plus.key), 1, 0.82, 0)
    Menus.Hint(GameTooltip, ns.TEXT.bagsPlusTip)
    GameTooltip:Show()
end

local function PlusLeave(plus)
    plus.sign:SetAlpha(0.5)
    GameTooltip:Hide()
end

local function MakePlus(canvas)
    local plus = CreateFrame("Button", nil, canvas.child)
    local back = plus:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.4)
    plus.sign = plus:CreateFontString(nil, "ARTWORK")
    plus.sign:SetFontObject(Core.Font("SaneUIBagsPlus", "GameFontHighlightLarge", 18, "OUTLINE") or "GameFontHighlightLarge")
    plus.sign:SetPoint("CENTER")
    plus.sign:SetText("+")
    plus.sign:SetAlpha(0.5)
    plus:SetScript("OnClick", function(self) ns.Safe("bags", PlusClick, self) end)
    plus:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", PlusClick, self) end)
    plus:SetScript("OnEnter", function(self) ns.Safe("bags", PlusEnter, self) end)
    plus:SetScript("OnLeave", function(self) ns.Safe("bags", PlusLeave, self) end)
    return plus
end

function Sheet:Plus(place)
    local plus = self.pluses:Take()
    plus:ClearAllPoints()
    plus:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    plus:SetSize(place.size, place.size)
    plus:SetFrameLevel(self.child:GetFrameLevel() + 3)
    plus.key = place.block.key
    plus:Show()
end

-------------------------------------------------------------------------------
--  The list's lines
-------------------------------------------------------------------------------
-- A line: behind its item button, which reaches over it; a word for each column shown (Columns.lua).
local function MakeRow(canvas)
    local row = CreateFrame("Frame", nil, canvas.child)
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row.back:SetColorTexture(1, 1, 1, 0.03)
    row.lit = row:CreateTexture(nil, "BORDER")
    row.lit:SetAllPoints()
    row.lit:SetColorTexture(1, 1, 1, 0.08)
    row.lit:Hide()
    row.cells = {}
    return row
end

local function Cell(row, key)
    local cell = row.cells[key]
    if not cell then
        cell = row:CreateFontString(nil, "ARTWORK")
        cell:SetFontObject(Core.Font("SaneUIBagsRow", "GameFontHighlightSmall", 11) or "GameFontHighlightSmall")
        cell:SetWordWrap(false)
        cell:SetJustifyH(Columns.DEF[key].number and "RIGHT" or "LEFT")
        row.cells[key] = cell
    end
    return cell
end

function Sheet:Row(place, button)
    local row = self.rows:Take()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    row:SetSize(place.width, place.height)
    row:SetFrameLevel(self.child:GetFrameLevel() + 1)
    row.back:SetShown(self.rows.taken % 2 == 0)
    row.lit:Hide()
    local entry = place.entry
    local spots = Columns.Place(place.width)
    for _, cell in pairs(row.cells) do cell:Hide() end
    for _, key in ipairs(Columns.Shown()) do
        if key ~= "icon" then
            local cell, spot = Cell(row, key), spots[key]
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", spot.x, 0)
            cell:SetWidth(spot.width)
            local text, r, g, b = Columns.Value(key, entry)
            cell:SetText(text)
            cell:SetTextColor(r or 1, g or 1, b or 1)
            cell:Show()
        end
    end
    row:SetAlpha(entry.faded and Cells.FADED or 1)
    self.rowOf[button] = row
    row:Show()
end

-- The mouse on a list's item button: its line lit.
function Sheet:Hover(button, on)
    local row = self.rowOf[button]
    if row and row:IsShown() then row.lit:SetShown(on) end
end

-------------------------------------------------------------------------------
--  A drawing
-------------------------------------------------------------------------------
-- The blocks of a view drawn in a room so wide, in the window's display (store.look), each cell as how says
-- (Cells.Draw); returns the height they take.
function Sheet:Draw(blocks, room, how)
    local store = self.owner.store
    local look = store.look
    self.blocks = blocks
    local list = look == "list"
    local folded = type(store.folded) == "table" and store.folded or {}
    for index = 1, blocks.count do
        local block = blocks[index]
        block.folded = list and folded[Fold(block)] == true
        if list then Columns.Sort(block.entries) end
    end
    local places = self.places
    local count, height = Layout.Lay(look, blocks, room - Canvas.INSET, places)
    local cells = self.cells
    self.heads:Begin()
    self.rows:Begin()
    self.labels:Begin()
    self.pluses:Begin()
    cells:Begin()
    for button in pairs(self.rowOf) do self.rowOf[button] = nil end
    local x = Canvas.INSET
    for index = 1, count do
        local place = places[index]
        if place.kind == "head" then
            self:Head(place)
        elseif place.kind == "label" then
            self:Label(place)
        elseif place.kind == "pad" then
            cells:Pad(place.x + x, place.y, place.size)
        elseif place.kind == "plus" then
            self:Plus(place)
        else
            local entry = place.entry
            local button = cells:Take()
            if button then
                how.faded, how.count = entry.faded, entry.count
                cells:Draw(button, entry.record, how)
                if place.kind == "row" then
                    -- The button in the icon's column, in the line's middle; its click over the rest of the line.
                    local spot = Columns.Place(place.width).icon
                    local inset = (place.height - place.size) / 2
                    local left = spot and spot.x + (spot.width - place.size) / 2 or inset
                    cells:Place(button, place.x + x + left, place.y + inset, place.size, place.width - left)
                    Cells.Round(button, Columns.Rounded())
                    self:Row(place, button)
                else
                    cells:Place(button, place.x + x, place.y, place.size)
                    Cells.Round(button, false)
                end
            end
        end
    end
    cells:Done()
    self.heads:Done()
    self.rows:Done()
    self.labels:Done()
    self.pluses:Done()
    return height + Canvas.INSET
end

-- A canvas in a scroll area's child; owner: { store (look, folded), redraw(), cells (its pool) }.
function Canvas.New(child, owner)
    local canvas = setmetatable({ child = child, owner = owner, rowOf = {}, places = {} }, Sheet)
    canvas.cells = owner.cells
    canvas.heads = Core.Pool(function() return MakeHead(canvas) end)
    canvas.rows = Core.Pool(function() return MakeRow(canvas) end)
    canvas.labels = Core.Pool(function() return MakeLabel(canvas) end)
    canvas.pluses = Core.Pool(function() return MakePlus(canvas) end)
    return canvas
end
