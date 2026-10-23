local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Canvas
--  Where a window of items (the bags, the bank) draws what Layout.lua laid
--  out, in its scroll area's child: the heads (a part's and a group's title
--  with a pencil rule under them, a block's and a group member's: its words
--  and number), the
--  compact display's labels, a block's empty slots (a "+" in each), the
--  list's lines (a word for each column shown, Columns.lua) and the item
--  buttons (the window's pool, Cells.lua). Each window has its own
--  (Canvas.New).
--
--  A block's head takes an item let go over it and opens the category's menu
--  at a right click (Menus.lua); in the list a click folds the block, Shift
--  and a click every block (kept in the window's store: folded). An empty
--  slot takes an item brought to it (lit while one is held over it), or (the
--  bags) clicked with nothing starts choosing one by a click (Select.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Canvas = {}
ns.Canvas = Canvas
local Sheet = {}   -- a canvas's functions
Sheet.__index = Sheet

Canvas.INSET = 8   -- from the scroll area's left to the items
Canvas.HEAD_COLOR = ns.Paper.SOFT     -- a category's head: graphite; a group's member as dark, smaller and not bold
Canvas.MEMBER_COLOR = ns.Paper.SOFT   -- (Saneroki, 2026-10-23: darker, to be read)

local Layout, Cells, Columns, Menus, Categories = ns.Layout, ns.Cells, ns.Columns, ns.Menus, ns.Categories

-- The fonts of a canvas's words, Kalam (ns.Paper): a category's head, a group member's, a part's; a list's line,
-- plain and in a game colour.
local fonts
local function Fonts()
    if fonts then return fonts end
    local Paper = ns.Paper
    fonts = {
        head = Paper.Font("SaneUIBagsHead", 16, true),
        member = Paper.Font("SaneUIBagsMember", 13),
        part = Paper.Font("SaneUIBagsPart", 19, true),
        row = Paper.Font("SaneUIBagsRow", 14),
        rowColored = Paper.Outlined("SaneUIBagsRowColored", 14),
    }
    return fonts
end
Canvas.Fonts = Fonts

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
        Menus.Drop(head.key, head.canvas.owner.stow)
    elseif mouse == "LeftButton" and head.fold then
        Folded(head)
    end
end

local function HeadDrop(head)
    Menus.Drop(head.key or head.group and ("group:" .. head.group), head.canvas.owner.stow)
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
    local shade = ns.Paper.SHADE
    head.lit:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
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
    -- the pencil rule under the head's words, across the block
    head.line = Core.Journal.Rule(head)
    head.line:SetPoint("BOTTOMLEFT", 0, 0)
    head.line:SetPoint("BOTTOMRIGHT", -Layout.GAP, 0)
    head:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", HeadUp, self, mouse) end)
    head:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", HeadDrop, self) end)
    head:SetScript("OnEnter", function(self) ns.Safe("bags", HeadEnter, self) end)
    head:SetScript("OnLeave", function(self) ns.Safe("bags", HeadLeave, self) end)
    return head
end

function Sheet:Head(place)
    local head = self.heads:Take()
    local block = place.block
    local font = Fonts()
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    head:SetSize(place.width, place.height)
    local object = place.level == 1 and font.part or place.level == 3 and font.member or font.head
    if object then head.word:SetFontObject(object); head.number:SetFontObject(object) end
    head.word:SetText(block.word or "")
    local color = place.level == 3 and Canvas.MEMBER_COLOR or Canvas.HEAD_COLOR
    local ink = ns.Paper.INK
    if place.level == 1 then head.word:SetTextColor(ink[1], ink[2], ink[3]) else head.word:SetTextColor(color[1], color[2], color[3], color[4]) end
    head.number:SetTextColor(ns.Paper.FAINT[1], ns.Paper.FAINT[2], ns.Paper.FAINT[3], ns.Paper.FAINT[4])
    head.number:SetText(block.number and "(" .. tostring(block.number) .. ")" or "")
    -- the pencil rule only under a part's head; a group's title (Saneroki, 2026-10-23) and a category's name stand
    -- right over what they hold
    head.line:SetShown(place.level == 1)
    head.line:SetAlpha(ns.Paper.RULE_ALPHA)
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
    label.text:SetTextColor(color[1], color[2], color[3], color[4])
    label.text:SetText(block.word or "")
    label.key, label.group = block.key, block.group
    label:Show()
end

-- A block's empty slot, drawn as any empty slot (no sign in it, Saneroki, 2026-10-23), its category's drawing (a
-- group's) in its middle, faded to a subtle grey on the paper (Saneroki, 2026-10-23): an item brought to it (picked
-- up and clicked here, or dragged here) goes into its category (Pinned's: pinned; Junk's: marked as junk); clicked
-- with nothing, the next item clicked does (Select.lua).
Canvas.SLOT_ICON = 0.6    -- the drawing against the slot's side
Canvas.SLOT_FADE = 0.18   -- and how much of it shows
local function PlusClick(plus)
    if GetCursorInfo() == "item" then return Menus.Drop(plus.key, plus.canvas.owner.stow) end
    ns.Select.Start("put", plus.key)
end

local function PlusEnter(plus)
    plus.lit:SetShown(GetCursorInfo() == "item")
    GameTooltip:SetOwner(plus, "ANCHOR_TOP")
    local group = plus.key:match("^group:(.+)$")
    GameTooltip:SetText(group and Categories.GroupWord(group) or Categories.Word(plus.key), 1, 0.82, 0)
    Menus.Hint(GameTooltip, ns.TEXT.bagsPlusTip)
    GameTooltip:Show()
end

local function PlusLeave(plus)
    plus.lit:Hide()
    GameTooltip:Hide()
end

local function MakePlus(canvas)
    local plus = CreateFrame("Button", nil, canvas.child)
    plus.canvas = canvas
    Core.Journal.Slot(plus, 1, "BACKGROUND"):SetAlpha(Cells.EMPTY_SLOT)
    local shade = ns.Paper.SHADE
    plus.lit = plus:CreateTexture(nil, "BORDER")
    plus.lit:SetAllPoints()
    plus.lit:SetColorTexture(shade[1], shade[2], shade[3], 0.25)
    plus.lit:Hide()
    plus.icon = plus:CreateTexture(nil, "ARTWORK")
    plus.icon:SetPoint("CENTER")
    plus.icon:SetAlpha(Canvas.SLOT_FADE)
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
    plus.key = place.block.drop or place.block.key
    -- ours whole and in graphite; one of the game's icons a player chose for a category of their own grey, cut a
    -- little round its edge
    local group = plus.key:match("^group:(.+)$")
    local file = group and Categories.GroupIcon(group) or Categories.Icon(plus.key)
    local zoom = Categories.Drawn(file) and 0 or Cells.ZOOM
    plus.icon:SetTexture(file)
    plus.icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
    plus.icon:SetDesaturated(zoom > 0)
    plus.icon:SetSize(place.size * Canvas.SLOT_ICON, place.size * Canvas.SLOT_ICON)
    plus.lit:Hide()
    plus:Show()
end

-- Junk's first slot, the waste bin: the bin's drawing alone, no pencil slot around it, at full strength and a little
-- larger than the slot (into the gaps round it; the slot is what takes the clicks); an item let go there (or clicked
-- onto it) is offered to be destroyed in the game's own dialog (Menus.Destroy).
Canvas.BIN = 1.2       -- the drawing against the slot's size (Saneroki, 2026-10-23: bigger, plain to see)
local function BinDrop()
    Menus.Destroy()
end

local function BinEnter(bin)
    bin.lit:SetShown(GetCursorInfo() == "item")
    GameTooltip:SetOwner(bin, "ANCHOR_TOP")
    GameTooltip:SetText(ns.TEXT.bagsTrash, 1, 1, 1)
    GameTooltip:AddLine(ns.TEXT.bagsTrashTip, 1, 0.82, 0, true)
    GameTooltip:Show()
end

local function BinLeave(bin)
    bin.lit:Hide()
    GameTooltip:Hide()
end

local function MakeBin(canvas)
    local bin = CreateFrame("Button", nil, canvas.child)
    local shade = ns.Paper.SHADE
    bin.lit = bin:CreateTexture(nil, "BORDER")
    bin.lit:SetAllPoints()
    bin.lit:SetColorTexture(shade[1], shade[2], shade[3], 0.25)
    bin.lit:Hide()
    bin.picture = Core.Journal.Texture(bin, "trash", "ARTWORK")
    bin.picture:SetPoint("CENTER")
    bin:SetScript("OnClick", ns.Guard(BinDrop))
    bin:SetScript("OnReceiveDrag", ns.Guard(BinDrop))
    bin:SetScript("OnEnter", ns.Guard(BinEnter))
    bin:SetScript("OnLeave", ns.Guard(BinLeave))
    return bin
end

function Sheet:Bin(place)
    local bin = self.bins:Take()
    bin:ClearAllPoints()
    bin:SetPoint("TOPLEFT", self.child, "TOPLEFT", place.x + Canvas.INSET, -place.y)
    bin:SetSize(place.size, place.size)
    bin:SetFrameLevel(self.child:GetFrameLevel() + 3)
    bin.picture:SetSize(place.size * Canvas.BIN, place.size * Canvas.BIN)
    bin.lit:Hide()
    bin:Show()
end

-------------------------------------------------------------------------------
--  The list's lines
-------------------------------------------------------------------------------
-- A line: behind its item button, which reaches over it; a word for each column shown (Columns.lua).
local function MakeRow(canvas)
    local row = CreateFrame("Frame", nil, canvas.child)
    local zebra, shade = ns.Paper.ZEBRA, ns.Paper.SHADE
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row.back:SetColorTexture(zebra[1], zebra[2], zebra[3], zebra[4])
    row.lit = row:CreateTexture(nil, "BORDER")
    row.lit:SetAllPoints()
    row.lit:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
    row.lit:Hide()
    row.cells = {}
    return row
end

local function Cell(row, key)
    local cell = row.cells[key]
    if not cell then
        cell = row:CreateFontString(nil, "ARTWORK")
        cell:SetFontObject(Fonts().row)
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
            ns.Paper.Color(cell, r, g, b, Fonts().row, Fonts().rowColored)
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
-- How wide a block's head's words are (its name and how many), so that the grid makes the block as wide.
local function Measure(canvas, block)
    local text = canvas.measure
    if not text then
        text = canvas.child:CreateFontString(nil, "ARTWORK")
        text:Hide()
        canvas.measure = text
    end
    local font = Fonts()
    local object = block.level == 3 and font.member or font.head
    if object then text:SetFontObject(object) end
    text:SetText((block.word or "") .. (block.number and " (" .. tostring(block.number) .. ")" or ""))
    return (text:GetStringWidth() or 0) + 4
end

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
    local count, height = Layout.Lay(look, blocks, room - Canvas.INSET, places, self.measurer)
    local cells = self.cells
    self.heads:Begin()
    self.rows:Begin()
    self.labels:Begin()
    self.pluses:Begin()
    self.bins:Begin()
    cells:Begin()
    for button in pairs(self.rowOf) do self.rowOf[button] = nil end
    local x = Canvas.INSET
    for index = 1, count do
        local place = places[index]
        if place.kind == "head" then
            self:Head(place)
        elseif place.kind == "label" then
            self:Label(place)
        elseif place.kind == "plus" then
            self:Plus(place)
        elseif place.kind == "bin" then
            self:Bin(place)
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
    self.bins:Done()
    return height + Canvas.INSET
end

-- A canvas in a scroll area's child; owner: { store (look, folded), redraw(), cells (its pool), stow (the bags':
-- an item let go over a head or a slot goes into them) }.
function Canvas.New(child, owner)
    local canvas = setmetatable({ child = child, owner = owner, rowOf = {}, places = {} }, Sheet)
    canvas.cells = owner.cells
    canvas.heads = Core.Pool(function() return MakeHead(canvas) end)
    canvas.rows = Core.Pool(function() return MakeRow(canvas) end)
    canvas.labels = Core.Pool(function() return MakeLabel(canvas) end)
    canvas.pluses = Core.Pool(function() return MakePlus(canvas) end)
    canvas.bins = Core.Pool(function() return MakeBin(canvas) end)
    canvas.measurer = function(block) return Measure(canvas, block) end
    return canvas
end
