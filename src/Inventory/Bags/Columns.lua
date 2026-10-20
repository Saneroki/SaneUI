local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Columns
--  The list display's columns: which there are, which are shown and in what
--  order, how wide, what each shows of an item, and the head over the list
--  that arranges them:
--      icon       the item's button
--      name       its name in its quality's colour, as wide as the room left
--      level      its item level (gear)
--      required   the level it needs
--      kind       the game's word for its kind
--      bind       how it binds: BoP, BoE, BoU, Quest; SB for gear that bound
--                 when worn or used
--      count      how many (the stacks merged: of them all)
--      sell       what the vendor pays for them
--  On the head: a click on a column sorts the list by it (numbers high to low
--  first), a second click the other way; a column dragged sideways moves
--  among the others; the edge at a column's right makes it wider or
--  narrower; a right click chooses the columns shown, moves one, makes the
--  icons round, or puts it all back as it was. Kept in store.bags:
--      columns { key, ... }   shown, in order (icon and name first at first)
--      widths  { [key] = width }
--      listSort, listDown     the column the list is sorted by, which way
--      round                  round icons in the list
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Columns = {}
ns.Columns = Columns

Columns.HEAD = 20          -- the head's height
Columns.GAP = 6            -- between two columns
Columns.LEAST = 20         -- the least a column is made
Columns.NAME_LEAST = 60    -- the least the name keeps
Columns.DRAG = 6           -- how far a column is moved before it is dragged
Columns.GRIP = 6           -- the edge at a column's right that sizes it
Columns.MUTED = { 0.6, 0.6, 0.6 }
Columns.VALUE = { 0.85, 0.85, 0.85 }

local BIND = Enum and Enum.ItemBind or {}

-- Every column, in the order the right click's menu lists them.
Columns.LIST = {
    { key = "icon", word = "", width = 26, fixed = true },
    { key = "name", word = Core.Word("NAME", "Name"), flex = true },
    { key = "level", word = ns.TEXT.bagsLevel, width = 36, number = true },
    { key = "required", word = ns.TEXT.bagsRequired, width = 32, number = true },
    { key = "kind", word = Core.Word("TYPE", "Type"), width = 96 },
    { key = "bind", word = ns.TEXT.bagsBind, width = 40 },
    { key = "count", word = "#", width = 40, number = true },
    { key = "sell", word = ns.TEXT.bagsSell, width = 100, number = true },
}
Columns.DEF = {}
for _, column in ipairs(Columns.LIST) do Columns.DEF[column.key] = column end
Columns.FIRST = { "icon", "name", "level", "count", "sell" }

local kept = {}

-- The window's store, its columns checked: known keys once each, the icon and name always there.
function Columns.Use(bags)
    kept = bags
    local list, seen = {}, {}
    if type(bags.columns) == "table" then
        for _, key in ipairs(bags.columns) do
            if Columns.DEF[key] and not seen[key] then
                list[#list + 1] = key
                seen[key] = true
            end
        end
    end
    if #list == 0 then
        for _, key in ipairs(Columns.FIRST) do list[#list + 1] = key end
    else
        if not seen.name then table.insert(list, 1, "name") end
        if not seen.icon then table.insert(list, 1, "icon") end
    end
    bags.columns = list
    if type(bags.widths) ~= "table" then bags.widths = {} end
    for key, width in pairs(bags.widths) do
        if not (Columns.DEF[key] and not Columns.DEF[key].flex and type(width) == "number") then bags.widths[key] = nil end
    end
    if not Columns.DEF[bags.listSort] or bags.listSort == "icon" then bags.listSort = nil end
end

function Columns.Shown()
    return kept.columns or Columns.FIRST
end

-------------------------------------------------------------------------------
--  Where each column stands, what it shows
-------------------------------------------------------------------------------
local placed = {} -- [key] = { x, width }, used again

-- The columns' places in a line so wide: the fixed ones as wide as kept (narrower together if the name would
-- keep less than its least), the name the rest.
function Columns.Place(width)
    local shown = Columns.Shown()
    local fixed, count = 0, #shown
    for _, key in ipairs(shown) do
        local def = Columns.DEF[key]
        if not def.flex then fixed = fixed + (kept.widths and kept.widths[key] or def.width) end
    end
    local room = width - Columns.GAP * (count - 1)
    local scale = 1
    if room - fixed < Columns.NAME_LEAST and fixed > 0 then scale = math.max(0.1, (room - Columns.NAME_LEAST) / fixed) end
    local x = 0
    for _, key in ipairs(shown) do
        local def = Columns.DEF[key]
        local wide = def.flex and math.max(Columns.NAME_LEAST, room - fixed * scale) or math.floor((kept.widths and kept.widths[key] or def.width) * scale)
        placed[key] = placed[key] or {}
        placed[key].x, placed[key].width = x, wide
        x = x + wide + Columns.GAP
    end
    return placed
end

-- How an item binds, in short: SB once gear bound when worn or used.
local function Bind(record)
    local bind = record.bind
    if bind == (BIND.OnAcquire or 1) then return ns.TEXT.bagsBoP end
    if bind == (BIND.OnEquip or 2) then return record.bound and ns.TEXT.bagsSoulbound or ns.TEXT.bagsBoE end
    if bind == (BIND.OnUse or 3) then return record.bound and ns.TEXT.bagsSoulbound or ns.TEXT.bagsBoU end
    if bind == (BIND.Quest or 4) then return ns.TEXT.bagsQuest end
    return ""
end

-- What a column shows for an entry (a record and its merged count): the words, and their colour.
function Columns.Value(key, entry)
    local record = entry.record
    if not record.item then
        if key == "name" then return Core.Word("EMPTY", "Empty"), 0.4, 0.4, 0.4 end
        return ""
    end
    local value = Columns.VALUE
    if key == "name" then
        local color = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[record.quality]
        if color then return record.name or "", color.r, color.g, color.b end
        return record.name or "", 1, 1, 1
    end
    local count = entry.count or record.count or 1
    local text
    if key == "level" then text = record.level and tostring(record.level) or ""
    elseif key == "required" then text = record.required and record.required > 1 and tostring(record.required) or ""
    elseif key == "kind" then text = record.subName or record.kindName or ""
    elseif key == "bind" then text = Bind(record)
    elseif key == "count" then text = count > 1 and tostring(count) or ""
    elseif key == "sell" then text = record.sell and record.sell > 0 and (Core.Coins(record.sell * count) or "") or ""
    else text = "" end
    return text, value[1], value[2], value[3]
end

-- A column's value for sorting.
local function Sorted(key, entry)
    local record = entry.record
    if key == "name" then return record.name or "" end
    if key == "level" then return record.level or 0 end
    if key == "required" then return record.required or 0 end
    if key == "kind" then return record.subName or record.kindName or "" end
    if key == "bind" then return Bind(record) end
    if key == "count" then return entry.count or record.count or 0 end
    if key == "sell" then return (record.sell or 0) * (entry.count or record.count or 1) end
    return 0
end

-- The entries of a block sorted by the column chosen (nil: as the view sorted them).
function Columns.Sort(entries)
    local key = kept.listSort
    if not key then return entries end
    local down = kept.listDown == true
    table.sort(entries, function(a, b)
        local va, vb = Sorted(key, a), Sorted(key, b)
        if va ~= vb then
            if down then return va > vb end
            return va < vb
        end
        a, b = a.record, b.record
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return entries
end

-------------------------------------------------------------------------------
--  The head
-------------------------------------------------------------------------------
local head, cells, grips -- the head over the list, its cells and grips ([key] = frame)
local width = 0
local dragging           -- { key, x } while a column is held

local function Changed()
    Columns.Refresh(width)
    ns.Bags.Redraw()
end

-- A click on a column: sorted by it, or the other way.
local function SortBy(key)
    if key == "icon" then return end
    if kept.listSort == key then
        kept.listDown = not kept.listDown
    else
        kept.listSort, kept.listDown = key, Columns.DEF[key].number == true
    end
    Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    Changed()
end

local function Move(key, step)
    local list = kept.columns
    for index, other in ipairs(list) do
        if other == key then
            local target = index + step
            if target >= 1 and target <= #list then list[index], list[target] = list[target], list[index] end
            return Changed()
        end
    end
end

-- A held column moved to where the cursor is: past the middle of the next one, it takes that one's place.
local function Drag()
    if not dragging then return end
    local x = GetCursorPosition() / head:GetEffectiveScale()
    if not dragging.moved and math.abs(x - dragging.x) < Columns.DRAG then return end
    dragging.moved = true
    local left = head:GetLeft() or 0
    local list = kept.columns
    for index, key in ipairs(list) do
        local spot = placed[key]
        if key ~= dragging.key and spot and math.abs(x - left - (spot.x + spot.width / 2)) < spot.width / 2 then
            for at, other in ipairs(list) do
                if other == dragging.key then
                    table.remove(list, at)
                    table.insert(list, index, dragging.key)
                    return Changed()
                end
            end
        end
    end
end

local Dragged = ns.Guard(Drag)

local function CellDown(cell, mouse)
    if mouse ~= "LeftButton" then return end
    dragging = { key = cell.key, x = GetCursorPosition() / head:GetEffectiveScale() }
    head:SetScript("OnUpdate", Dragged)
end

local function CellUp(cell, mouse)
    if mouse == "RightButton" then return Columns.Menu(cell) end
    local held = dragging
    dragging = nil
    head:SetScript("OnUpdate", nil)
    if held and not held.moved then SortBy(cell.key) end
end

-- A column's right edge held: as wide as the cursor makes it.
local function Size()
    if not dragging or not dragging.size then return end
    local x = GetCursorPosition() / head:GetEffectiveScale()
    local key = dragging.key
    kept.widths[key] = math.max(Columns.LEAST, math.floor(dragging.width + x - dragging.x))
    Changed()
end

local Sized = ns.Guard(Size)

local function GripDown(grip, mouse)
    if mouse ~= "LeftButton" then return end
    local key = grip.key
    dragging = { key = key, size = true, x = GetCursorPosition() / head:GetEffectiveScale(),
                 width = kept.widths[key] or Columns.DEF[key].width }
    head:SetScript("OnUpdate", Sized)
end

local function GripUp()
    dragging = nil
    head:SetScript("OnUpdate", nil)
end

local function MakeCell(key)
    local cell = CreateFrame("Button", nil, head)
    cell.key = key
    cell:SetHeight(Columns.HEAD)
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell.text = cell:CreateFontString(nil, "ARTWORK")
    cell.text:SetFontObject(Core.Font("SaneUIBagsColumn", "GameFontHighlightSmall", 10) or "GameFontHighlightSmall")
    cell.text:SetAllPoints()
    cell.text:SetWordWrap(false)
    cell.text:SetJustifyH(Columns.DEF[key].number and "RIGHT" or "LEFT")
    cell:SetScript("OnMouseDown", function(self, mouse) ns.Safe("bags", CellDown, self, mouse) end)
    cell:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", CellUp, self, mouse) end)
    cells[key] = cell
    if not Columns.DEF[key].flex and key ~= "icon" then
        local grip = CreateFrame("Frame", nil, head)
        grip.key = key
        grip:SetSize(Columns.GRIP, Columns.HEAD)
        grip:EnableMouse(true)
        grip:SetScript("OnMouseDown", function(self, mouse) ns.Safe("bags", GripDown, self, mouse) end)
        grip:SetScript("OnMouseUp", function() ns.Safe("bags", GripUp) end)
        grips[key] = grip
    end
    return cell
end

-- The head as the columns stand in a line so wide.
function Columns.Refresh(newWidth)
    if not head then return end
    width = newWidth or width
    Columns.Place(width)
    for _, cell in pairs(cells) do cell:Hide() end
    for _, grip in pairs(grips) do grip:Hide() end
    for _, key in ipairs(Columns.Shown()) do
        local cell = cells[key] or MakeCell(key)
        local spot = placed[key]
        cell:ClearAllPoints()
        cell:SetPoint("LEFT", head, "LEFT", spot.x, 0)
        cell:SetWidth(spot.width)
        local word = Columns.DEF[key].word
        if kept.listSort == key then word = word .. (kept.listDown and " v" or " ^") end
        cell.text:SetText(word)
        cell.text:SetTextColor(Columns.MUTED[1], Columns.MUTED[2], Columns.MUTED[3])
        cell:Show()
        local grip = grips[key]
        if grip then
            grip:ClearAllPoints()
            grip:SetPoint("LEFT", head, "LEFT", spot.x + spot.width + (Columns.GAP - Columns.GRIP) / 2, 0)
            grip:Show()
        end
    end
end

-------------------------------------------------------------------------------
--  The head's menu
-------------------------------------------------------------------------------
local about -- the column the menu was opened on

local function IsShown(key)
    for _, other in ipairs(kept.columns) do
        if other == key then return true end
    end
    return false
end
local function Toggle(key)
    if IsShown(key) then
        for index, other in ipairs(kept.columns) do
            if other == key then table.remove(kept.columns, index) break end
        end
    else
        kept.columns[#kept.columns + 1] = key
    end
    Changed()
end
local function IsRound() return kept.round == true end
local function ToggleRound()
    kept.round = not kept.round
    Changed()
end
local function Reset()
    kept.columns, kept.widths, kept.listSort, kept.listDown, kept.round = nil, nil, nil, nil, nil
    Columns.Use(kept)
    Changed()
end
local Shown = ns.Guard(IsShown)
local Switch = ns.Guard(Toggle)
local Rounded = ns.Guard(IsRound)
local Round = ns.Guard(ToggleRound)
local Back = ns.Guard(Reset)
local Left = ns.Guard(function() Move(about, -1) end)
local Right = ns.Guard(function() Move(about, 1) end)

local function Fill(_, root)
    root:CreateTitle(ns.TEXT.bagsColumns)
    for _, column in ipairs(Columns.LIST) do
        if column.key ~= "icon" and column.key ~= "name" then root:CreateCheckbox(column.word, Shown, Switch, column.key) end
    end
    root:CreateDivider()
    if about then
        root:CreateButton(ns.TEXT.bagsMoveLeft, Left)
        root:CreateButton(ns.TEXT.bagsMoveRight, Right)
    end
    root:CreateCheckbox(ns.TEXT.bagsRound, Rounded, Round)
    root:CreateButton(ns.TEXT.bagsResetColumns, Back)
end
local Menu = ns.Guard(Fill)

function Columns.Menu(cell)
    if not rawget(_G, "MenuUtil") then return end
    about = cell and cell.key
    MenuUtil.CreateContextMenu(cell or head, Menu)
end

-- The head in the body, its place set by the window (Bags.lua).
function Columns.Build(parent)
    head = CreateFrame("Frame", nil, parent)
    head:SetHeight(Columns.HEAD)
    cells, grips = {}, {}
    head:Hide()
    Columns.head = head
    return head
end

-- For the tests: a column's cell on the head.
function Columns.Cell(key)
    return cells and cells[key]
end
