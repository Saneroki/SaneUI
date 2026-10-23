local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Items
--  What the chosen character has, as last seen (Snapshot.lua), in one list
--  that scrolls (the game's WowScrollBoxList and MinimalScrollBar), in the
--  bags' flat look: a head per place (Bags, Bank, Equipped) with how many
--  items it holds, then its items in one of the bags' displays:
--      grid     the items as squares in the order Core keeps them (with
--               Group by Category: under a head per category, in the
--               categories' order)
--      list     a line per item, in the bags' list columns (Columns.lua)
--      compact  the categories side by side, each as near square as it can
--               be (Layout.lua), a place's in one piece
--  What is worn is the game's paper doll. Core keeps a bag's items and
--  counts, not the slots they lie in: no empty slots are shown. An item's
--  category is the bags' (Categories.Classify on what the game tells of the
--  item: Items.Record).
--
--  The paper doll: the gear in its slots as our character sheet has them
--  (Sheet/Slots.lua: its columns, sizes and slot frames), as wide as the grid
--  and at most as the sheet's, the weapons' row in the middle below; an empty
--  slot shows its own picture. The bags worn in their slots follow as a row of
--  the grid. A character Core has not read slot by slot yet (it has not logged
--  in since) has what it wears as a list instead: its icon, its name in its
--  quality's colour.
--
--  Read only: nothing here moves an item. An item's tooltip is the game's
--  (GameTooltip:SetItemByID), an empty slot's its name; a modified click links
--  it or tries it on (HandleModifiedItemClick), as on the game's own buttons.
--  While searching, only what is found is listed, and a place without any of
--  it is left out; a doll with something found in it stays whole, what it
--  holds that is not found dimmed as the game's bags dim it.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Items = {}
ns.Items = Items

Items.SIZE, Items.GAP = 34, 4 -- an item's square, as the bags', and the room between two
Items.HEAD = 26               -- a place's head
Items.SUB = 22                -- a category's head
Items.LINE = 24               -- a line of the list, of what is worn
Items.ICON = 20               -- its icon
Items.NOTE = 22               -- a line that says why a place shows nothing
Items.BAR = 14                -- the room right of the list for its scroll bar
local Slots = ns.Slots        -- the sheet's slots: their columns, sizes and frames
Items.DOLL = ns.Sheet.LEFT - Slots.LEFT - Slots.RIGHT -- the doll at most as wide as the sheet's columns stand apart
Items.DOLL_EDGE = Slots.GAP / 2 -- round the doll: its slots' frames stand out of their buttons
local STEP = Slots.SIZE + Slots.GAP -- from a slot to the one below it

local Cells, Categories, Columns = ns.Cells, ns.Categories, ns.Columns
local box, bar, view
local columns, width = 1, 0
local dollSlots, dolled -- the doll's slots ({ name, id, picture, column, index }), and [slot ID] = true; asked once
local looks = {}        -- [button] = ours on an item's square (its border, its item level)

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function ItemAPI(name, item)
    local items = rawget(_G, "C_Item")
    return Core.Ask(items and items[name], item)
end

-- An item's link, for a modified click: the game's GetItemInfo knows it once the item is cached.
local function Link(item)
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    local _, link = Core.Ask(info, item)
    return link
end

-------------------------------------------------------------------------------
--  What an item is (as the bags' records have it)
-------------------------------------------------------------------------------
local records = {} -- [item] = its record, once the game told what it is (static facts)

-- An item as a record of the bags' kind (Contents.lua): its name, quality, class, level, bind, price; its
-- category the bags' (Categories.Classify). nil fields while the game does not know it yet. What the game told is
-- kept; the category is worked out each time, as the player may have moved the item, deleted or switched off its
-- category since.
function Items.Record(item)
    local record = records[item]
    if record and record.known then
        Categories.Classify(record)
        return record
    end
    record = record or { bag = 0, slot = item, item = item }
    records[item] = record
    record.name = ns.Snapshot.Name(item) or record.name
    record.quality = ItemAPI("GetItemQualityByID", item)
    record.icon = ItemAPI("GetItemIconByID", item)
    local instant = rawget(_G, "C_Item") and C_Item.GetItemInfoInstant or rawget(_G, "GetItemInfoInstant")
    local ok, _, _, _, equip, _, class, subclass = pcall(instant or error, item)
    if ok then record.equip, record.class, record.subclass = Core.Plain(equip), Core.Plain(class), Core.Plain(subclass) end
    local info = rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo")
    local got, name, link, _, _, required, kindName, subName, _, _, _, sell, _, _, bind = pcall(info or error, item)
    if got and Core.Plain(name) then
        record.link, record.required, record.kindName, record.subName = Core.Plain(link), Core.Plain(required), Core.Plain(kindName), Core.Plain(subName)
        record.sell, record.bind = Core.Plain(sell), Core.Plain(bind)
        record.worthless = (record.sell or 0) == 0
        record.name = record.name or Core.Plain(name)
        record.known = record.name ~= nil
    end
    if ns.Contents.GEAR[record.class] then
        local level = ItemAPI("GetDetailedItemLevelInfo", record.link or item)
        record.level = type(level) == "number" and level > 0 and level or nil
    end
    record.reagentBag, record.special, record.set, record.bound = false, false, nil, false
    record.loot = ns.Contents.OPENS[item] or false
    Categories.Classify(record)
    return record
end

-------------------------------------------------------------------------------
--  The buttons
-------------------------------------------------------------------------------
local function Enter(button)
    if not (button.item or button.slotName) then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.item then
        GameTooltip:SetItemByID(button.item)
    else
        GameTooltip:SetText(Core.Word(button.slotName:upper(), button.slotName))
    end
    GameTooltip:Show()
end

local function Click(button)
    local link = button.item and IsModifiedClick() and Link(button.item)
    if link then Game("HandleModifiedItemClick", link) end
end

-- The window runs apart from the module's other windows (Board.lua): an error here is noted, nothing more.
local function OnEnter(button) ns.Safe("alts", Enter, button) end
local function OnClick(button) ns.Safe("alts", Click, button) end

-- What every item button and line does: the game's tooltip, a modified click.
local function Mouse(button)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", OnClick)
end

-- One of the game's item buttons, read only.
local function Button(row)
    local made, button = pcall(CreateFrame, "ItemButton", nil, row)
    if not made then button = CreateFrame("Button", nil, row, "ItemButtonTemplate") end
    button:SetSize(Items.SIZE, Items.SIZE)
    Mouse(button)
    return button
end

-- An item's square in the bags' look: a pencil slot on the paper, the icon in it cut round its edge, its corners
-- rounded (Cells.ROUNDED), no border, its count and item level in the bags' fonts; plain (a list's line): the icon
-- alone.
local function Square(row, plain)
    local button = Button(row)
    local face = button
    if not plain then
        local inset = Items.SIZE * Core.Journal.SLOT_ICON
        Core.Journal.Slot(button, 1, "BACKGROUND")
        face = CreateFrame("Frame", nil, button)
        face:SetPoint("TOPLEFT", inset, -inset)
        face:SetPoint("BOTTOMRIGHT", -inset, inset)
    end
    local icon = Cells.Part(button, "icon")
    if icon then
        icon:ClearAllPoints()
        icon:SetAllPoints(face)
        icon:SetTexCoord(Cells.ZOOM, 1 - Cells.ZOOM, Cells.ZOOM, 1 - Cells.ZOOM)
    end
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local border = Cells.Part(button, "IconBorder")
    if border then border:SetAlpha(0) end
    local font = Cells.Fonts()
    local count = Cells.Part(button, "Count")
    if count and font.count then
        count:SetFontObject(font.count)
        count:ClearAllPoints()
        count:SetPoint("BOTTOMRIGHT", face, "BOTTOMRIGHT", -1, 1)
    end
    if not plain then Cells.Mask(button, Cells.ROUNDED, icon) end
    local mine = {}
    mine.level = button:CreateFontString(nil, "OVERLAY", nil, 7)
    if font.level then mine.level:SetFontObject(font.level) end
    mine.level:SetPoint("TOPLEFT", face, "TOPLEFT", 1, -1)
    looks[button] = mine
    return button
end

-- An item drawn on its square: its icon, count, the item level of gear in its quality's colour.
local function Fill(button, entry)
    button.item = entry.item
    local record = Items.Record(entry.item)
    Game("SetItemButtonTexture", button, record.icon)
    Game("SetItemButtonCount", button, entry.count)
    Game("SetItemButtonQuality", button, record.quality, entry.item)
    local border = Cells.Part(button, "IconBorder")
    if border then border:Hide() end
    local mine = looks[button]
    if mine then
        local colors = rawget(_G, "ITEM_QUALITY_COLORS")
        local color = colors and record.quality and colors[record.quality]
        mine.level:SetText(record.level or "")
        if color then mine.level:SetTextColor(color.r, color.g, color.b) end
    end
    button:Show()
end

-- A line of the list of what is worn: a button over its whole row.
local function Line(row)
    local line = CreateFrame("Button", nil, row)
    line:SetAllPoints()
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Items.ICON, Items.ICON)
    line.icon:SetPoint("LEFT", 2, 0)
    line.text = line:CreateFontString(nil, "ARTWORK")
    line.text:SetFontObject(ns.Canvas.Fonts().row)
    line.text:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.text:SetPoint("RIGHT", -4, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    local shade = ns.Paper.SHADE
    local light = line:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
    Mouse(line)
    return line
end

local function Wear(line, entry)
    line.item = entry.item
    line.icon:SetTexture(ItemAPI("GetItemIconByID", entry.item))
    local name = ns.Snapshot.Name(entry.item) or ("item:" .. entry.item)
    if entry.count > 1 then name = ("%s (%d)"):format(name, entry.count) end
    line.text:SetText(name)
    local colours = rawget(_G, "ITEM_QUALITY_COLORS")
    local colour = colours and colours[ItemAPI("GetItemQualityByID", entry.item) or -1]
    local fonts = ns.Canvas.Fonts()
    ns.Paper.Color(line.text, colour and colour.r, colour and colour.g, colour and colour.b, fonts.row, fonts.rowColored)
    line:Show()
end

-- A line of the list display: the item's square at the left, a word for each column shown (Columns.lua).
local function ListRow(row)
    local line = CreateFrame("Button", nil, row)
    line:SetAllPoints()
    line.back = line:CreateTexture(nil, "BACKGROUND")
    line.back:SetAllPoints()
    local zebra, shade = ns.Paper.ZEBRA, ns.Paper.SHADE
    line.back:SetColorTexture(zebra[1], zebra[2], zebra[3], zebra[4])
    local light = line:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
    line.square = Square(line, true)
    line.square:SetSize(Items.ICON, Items.ICON)
    line.cells = {}
    Mouse(line)
    return line
end

local function List(line, element)
    local entry = element.entry
    line.item = entry.item
    local record = Items.Record(entry.item)
    Fill(line.square, entry)
    line.back:SetShown(element.even)
    local spots = Columns.Place(width)
    for _, cell in pairs(line.cells) do cell:Hide() end
    for _, key in ipairs(Columns.Shown()) do
        local spot = spots[key]
        if key == "icon" then
            line.square:ClearAllPoints()
            line.square:SetPoint("LEFT", spot.x + (spot.width - Items.ICON) / 2, 0)
        else
            local cell = line.cells[key]
            if not cell then
                cell = line:CreateFontString(nil, "ARTWORK")
                cell:SetFontObject(ns.Canvas.Fonts().row)
                cell:SetWordWrap(false)
                cell:SetJustifyH(Columns.DEF[key].number and "RIGHT" or "LEFT")
                line.cells[key] = cell
            end
            cell:ClearAllPoints()
            cell:SetPoint("LEFT", spot.x, 0)
            cell:SetWidth(spot.width)
            local text, r, g, b = Columns.Value(key, { record = record, count = entry.count })
            cell:SetText(text)
            ns.Paper.Color(cell, r, g, b, ns.Canvas.Fonts().row, ns.Canvas.Fonts().rowColored)
            cell:Show()
        end
    end
    line:Show()
end

-------------------------------------------------------------------------------
--  The paper doll
-------------------------------------------------------------------------------

-- The doll's slots: the sheet's columns (Slots.COLUMNS), then the ammo; each slot's ID and its picture
-- for empty as the game tells them (GetInventorySlotInfo).
local function DollSlots()
    if dollSlots then return dollSlots end
    dollSlots, dolled = {}, {}
    local paperDoll = rawget(_G, "C_PaperDollInfo")
    local Info = paperDoll and paperDoll.GetInventorySlotInfo or rawget(_G, "GetInventorySlotInfo")
    local function Add(name, column, index)
        local id, picture = Core.Ask(Info, name)
        if type(id) ~= "number" then return end
        dollSlots[#dollSlots + 1] = { name = name, id = id, picture = picture, column = column, index = index }
        dolled[id] = true
    end
    for _, column in ipairs({ "left", "right", "bottom" }) do
        for index, name in ipairs(Slots.COLUMNS[column]) do Add(name, column, index) end
    end
    Add("AmmoSlot", "ammo", 1)
    return dollSlots
end

-- A slot of the doll: one of the game's item buttons in a pencil slot on the paper (Core.Journal).
local function DollSlot(doll, slot)
    local button = Button(doll)
    local small = slot.column == "ammo"
    button:SetSize(small and Slots.AMMO or Slots.SIZE, small and Slots.AMMO or Slots.SIZE)
    button.slotName, button.picture = slot.name, slot.picture
    Core.Journal.Slot(button, 3, "BACKGROUND")
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    return button
end

local function MakeDoll(row)
    local doll = CreateFrame("Frame", nil, row)
    doll:SetAllPoints()
    doll.buttons = {}
    for index, slot in ipairs(DollSlots()) do doll.buttons[index] = DollSlot(doll, slot) end
    return doll
end

-- A slot drawn: what is worn in it as the game draws an item, or the slot's own picture; while searching,
-- dimmed if what it holds is not found (found: [item] = true).
local function Wearing(button, item, found)
    button.item = item
    local texture = nil -- empty: the pencil slot on the paper alone
    if item then texture = ItemAPI("GetItemIconByID", item) end
    Game("SetItemButtonTexture", button, texture)
    Game("SetItemButtonCount", button, 0)
    Game("SetItemButtonQuality", button, item and ItemAPI("GetItemQualityByID", item), item)
    if button.SetMatchesSearch then button:SetMatchesSearch(not (found and item and not found[item])) end
end

-- The doll drawn for a character: the columns as far apart as the grid is wide (at most the sheet's), the
-- weapons' row in the middle below them. The ranged slot where the game shows one or something is in it,
-- the ammo beside it where some is worn.
local function DrawDoll(doll, element)
    local slots, found, edge = element.slots, element.found, Items.DOLL_EDGE
    local wide = math.min(columns * (Items.SIZE + Items.GAP) - Items.GAP, Items.DOLL)
    local paperDoll = rawget(_G, "C_PaperDollInfo")
    local ranged = paperDoll and Core.Ask(paperDoll.IsRangedSlotShown) -- the game shows a ranged slot
    local weapons, span = {}, 0
    for index, slot in ipairs(DollSlots()) do
        local button, item = doll.buttons[index], slots[slot.id]
        local shown = true
        button:ClearAllPoints()
        if slot.column == "left" or slot.column == "right" then
            local x = slot.column == "left" and edge or wide - edge - Slots.SIZE
            button:SetPoint("TOPLEFT", x, -edge - (slot.index - 1) * STEP)
        else
            if slot.name == "RangedSlot" then
                shown = (ranged or item ~= nil) and true or false
                ranged = shown
            elseif slot.column == "ammo" then
                shown = (item ~= nil and ranged) and true or false
            end
            if shown then
                local gap = #weapons == 0 and 0 or slot.column == "ammo" and Slots.AMMO_GAP or Slots.GAP
                weapons[#weapons + 1] = { button = button, x = span + gap }
                span = span + gap + button:GetWidth()
            end
        end
        button:SetShown(shown)
        if shown then Wearing(button, item, found) end
    end
    local left, top = (wide - span) / 2, -edge - 8 * STEP
    for _, weapon in ipairs(weapons) do
        local button = weapon.button
        button:SetPoint("TOPLEFT", left + weapon.x, top - (Slots.SIZE - button:GetHeight()) / 2)
    end
    doll:Show()
end

-------------------------------------------------------------------------------
--  The rows
-------------------------------------------------------------------------------
-- A head in the bags' style: its words and number in grey, a thin line from them to the right edge.
local function Head(row, element)
    if not row.head then
        local head = CreateFrame("Frame", nil, row)
        head:SetAllPoints()
        head.word = head:CreateFontString(nil, "ARTWORK")
        head.word:SetPoint("BOTTOMLEFT", 2, 4)
        head.number = head:CreateFontString(nil, "ARTWORK")
        head.number:SetPoint("LEFT", head.word, "RIGHT", 4, 0)
        head.note = head:CreateFontString(nil, "ARTWORK")
        head.note:SetFontObject(ns.Paper.Font("SaneUIAltsNote", 13))
        head.note:SetTextColor(ns.Paper.FAINT[1], ns.Paper.FAINT[2], ns.Paper.FAINT[3], ns.Paper.FAINT[4])
        head.note:SetPoint("BOTTOMRIGHT", -2, 5)
        head.line = Core.Journal.Rule(head)
        head.line:SetPoint("BOTTOMLEFT", 0, 1)
        head.line:SetPoint("BOTTOMRIGHT", 0, 1)
        row.head = head
    end
    local head = row.head
    local sub = element.kind == "sub"
    local fonts = ns.Canvas.Fonts()
    local object = sub and fonts.head or fonts.part
    if object then head.word:SetFontObject(object); head.number:SetFontObject(object) end
    local color, ink, faint = ns.Canvas.HEAD_COLOR, ns.Paper.INK, ns.Paper.FAINT
    if sub then head.word:SetTextColor(color[1], color[2], color[3], color[4]) else head.word:SetTextColor(ink[1], ink[2], ink[3]) end
    head.number:SetTextColor(faint[1], faint[2], faint[3], faint[4])
    head.word:SetText(element.text or "")
    head.number:SetText(element.number and "(" .. element.number .. ")" or "")
    head.note:SetText(element.note or "")
    head.line:SetAlpha(sub and 0.5 or ns.Paper.RULE_ALPHA)
    head:Show()
end

-- A place's compact display: its categories side by side, the places Layout.lua gives them.
local function Compact(row, element)
    row.compact = row.compact or { squares = {}, labels = {} }
    local compact = row.compact
    local squares, labels = 0, 0
    for _, place in ipairs(element.places) do
        if place.kind == "cell" then
            squares = squares + 1
            local button = compact.squares[squares]
            if not button then
                button = Square(row)
                compact.squares[squares] = button
            end
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", place.x, -place.y)
            Fill(button, place.entry.entry)
        elseif place.kind == "label" then
            labels = labels + 1
            local label = compact.labels[labels]
            if not label then
                label = row:CreateFontString(nil, "ARTWORK")
                label:SetFontObject(ns.Canvas.Fonts().member)
                label:SetJustifyH("LEFT")
                label:SetWordWrap(false)
                compact.labels[labels] = label
            end
            local color = ns.Canvas.HEAD_COLOR
            label:SetTextColor(color[1], color[2], color[3], color[4])
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", place.x, -place.y)
            label:SetWidth(place.width)
            label:SetText(place.block.word or "")
            label:Show()
        end
    end
    for index = squares + 1, #compact.squares do
        compact.squares[index].item = nil
        compact.squares[index]:Hide()
    end
    for index = labels + 1, #compact.labels do compact.labels[index]:Hide() end
end

local function HideCompact(row)
    if not row.compact then return end
    for _, button in ipairs(row.compact.squares) do
        button.item = nil
        button:Hide()
    end
    for _, label in ipairs(row.compact.labels) do label:Hide() end
end

-- A row of the list, made anew for whatever it holds now (the list reuses its rows): a head, a category's
-- head, a row of the grid, a line of the list display, a place's compact display, the paper doll, a line of
-- what is worn, or a note.
local function Draw(row, element)
    if not row.buttons then
        row.buttons = {}
        row.note = row:CreateFontString(nil, "ARTWORK")
        row.note:SetFontObject(ns.Paper.Font("SaneUIAltsNote", 13))
        row.note:SetTextColor(ns.Paper.FAINT[1], ns.Paper.FAINT[2], ns.Paper.FAINT[3], ns.Paper.FAINT[4])
    end
    local kind = element.kind
    if kind == "head" or kind == "sub" then Head(row, element) elseif row.head then row.head:Hide() end
    row.note:SetShown(kind == "note")
    if kind == "note" then
        row.note:ClearAllPoints()
        row.note:SetPoint("LEFT", 2, 0)
        row.note:SetText(element.text)
    end
    local count = kind == "grid" and element.to - element.from + 1 or 0
    for index = 1, math.max(count, #row.buttons) do
        local button = row.buttons[index]
        if index <= count then
            if not button then
                button = Square(row)
                button:SetPoint("TOPLEFT", (index - 1) * (Items.SIZE + Items.GAP), 0)
                row.buttons[index] = button
            end
            Fill(button, element.items[element.from + index - 1])
        else
            button.item = nil
            button:Hide()
        end
    end
    if kind == "row" then
        row.list = row.list or ListRow(row)
        List(row.list, element)
    elseif row.list then
        row.list.item = nil
        row.list:Hide()
    end
    if kind == "compact" then Compact(row, element) else HideCompact(row) end
    if kind == "gear" then
        row.line = row.line or Line(row)
        Wear(row.line, element.entry)
    elseif row.line then
        row.line.item = nil
        row.line:Hide()
    end
    if kind == "doll" then
        row.doll = row.doll or MakeDoll(row)
        DrawDoll(row.doll, element)
    elseif row.doll then
        row.doll:Hide()
    end
end

-- The doll: eight slots down, the weapons' row below them, the room round them.
local HEIGHTS = { head = Items.HEAD, sub = Items.SUB, grid = Items.SIZE + Items.GAP, gear = Items.LINE, row = Items.LINE,
                  note = Items.NOTE, doll = 2 * Items.DOLL_EDGE + 9 * STEP }
local function Measured(element)
    return element.height or HEIGHTS[element.kind]
end
-- The game's list asks it for every row: it always gets a number, also after a failure.
local function Height(_, element)
    return ns.Safe("alts", Measured, element) or Items.NOTE
end

-- The list's rows, made and drawn by the game's list: each drawn apart from the others.
local function Init(row, element)
    ns.Safe("alts", Draw, row, element)
end
local function Factory(factory)
    ns.Safe("alts", factory, "Frame", Init)
end

function Items.Build(parent)
    box = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    box:SetPoint("TOPLEFT")
    box:SetPoint("BOTTOMRIGHT", -Items.BAR, 0)
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 0)
    view = CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(Height)
    view:SetElementFactory(Factory)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    Items.box = box
end

-- How many item squares a row of the grid holds at this width (the list and compact displays take the width as
-- it is); whether that changed.
function Items.Fit(room)
    local fit = math.max(1, math.floor((room + Items.GAP) / (Items.SIZE + Items.GAP)))
    local changed = fit ~= columns
    columns, width = fit, room
    return changed
end

-------------------------------------------------------------------------------
--  The elements
-------------------------------------------------------------------------------
-- Rows of the grid for these items.
local function Grid(elements, items)
    for from = 1, #items, columns do
        elements[#elements + 1] = { kind = "grid", items = items, from = from, to = math.min(from + columns - 1, #items) }
    end
end

-- What is worn, slot by slot (section.slots): the doll, then what is worn in no slot of it (the bags) as
-- rows of the grid, in their slots' order. searching (section.items: what is found): the doll only if
-- something in it is found, of the rest only what is found.
local function Doll(elements, section, searching)
    local found, ids, lit, rest = {}, {}, false, {}
    for _, entry in ipairs(section.items) do found[entry.item] = true end
    for slot in pairs(section.slots) do ids[#ids + 1] = slot end
    table.sort(ids)
    DollSlots()
    for _, slot in ipairs(ids) do
        local item = section.slots[slot]
        if dolled[slot] then
            lit = lit or found[item] == true
        elseif found[item] then
            rest[#rest + 1] = { item = item, count = 1 }
        end
    end
    if lit or not searching then
        elements[#elements + 1] = { kind = "doll", slots = section.slots, found = searching and found or nil }
    end
    Grid(elements, rest)
end

-- A place's items by category, in the categories' order: { { key, word, items }, ... }.
local function ByCategory(items)
    local lists = {}
    for _, entry in ipairs(items) do
        local key = Items.Record(entry.item).category or Categories.CATCH_ALL
        lists[key] = lists[key] or {}
        table.insert(lists[key], entry)
    end
    local groups = {}
    for _, key in ipairs(Categories.order) do
        if lists[key] then groups[#groups + 1] = { key = key, word = Categories.Word(key), items = lists[key] } end
    end
    return groups
end

-- The entries of a list sorted by the list's column chosen (as the bags' list), else as Core keeps them.
local function Sorted(items)
    local entries = {}
    for index, entry in ipairs(items) do entries[index] = { record = Items.Record(entry.item), count = entry.count, entry = entry } end
    return Columns.Sort(entries)
end

-- A place's items as the display says: rows of the grid (by category with Group by Category), lines of the
-- list, or one compact piece.
local function Shown(elements, items, options)
    local look, groups = options.look, options.group and ByCategory(items) or { { items = items } }
    if look == "compact" then
        local blocks = { count = 0 }
        for _, group in ipairs(options.group and groups or ByCategory(items)) do
            blocks.count = blocks.count + 1
            local entries = {}
            for index, entry in ipairs(group.items) do entries[index] = { entry = entry } end
            blocks[blocks.count] = { word = group.word, level = 2, entries = entries }
        end
        local places = {}
        local count, height = ns.Layout.Lay("compact", blocks, width, places)
        for index = count + 1, #places do places[index] = nil end
        elements[#elements + 1] = { kind = "compact", places = places, height = height + Items.GAP }
        return
    end
    local even = false
    for _, group in ipairs(groups) do
        if group.word then elements[#elements + 1] = { kind = "sub", text = group.word, number = #group.items } end
        if look == "list" then
            for _, entry in ipairs(Sorted(group.items)) do
                even = not even
                elements[#elements + 1] = { kind = "row", entry = entry.entry, even = even }
            end
        else
            Grid(elements, group.items)
        end
    end
end

-- The list's elements for these sections (Snapshot.Sections): a head per place, its items as the display
-- says, the doll or lines of what is worn; a note where a place shows nothing. Head(place) gives the head's
-- words, the note beside it and what a place without items says. searching: a place where nothing is found
-- is left out. options: { look, group, places (a set of the places shown; nil: all), category (only its items;
-- nil: all) }.
function Items.Elements(sections, Head, searching, options)
    options = options or {}
    local elements = {}
    for _, section in ipairs(sections) do
        local items = section.items
        if options.category then
            local only = {}
            for _, entry in ipairs(items) do
                if Items.Record(entry.item).category == options.category then only[#only + 1] = entry end
            end
            items = only
        end
        local wanted = (not options.places or options.places[section.place]) and not (options.category and section.place == "worn")
        if wanted and not ((searching or options.category) and #items == 0) then
            local title, note, empty = Head(section.place)
            local total = 0
            for _, entry in ipairs(items) do total = total + 1 end
            elements[#elements + 1] = { kind = "head", text = title, note = note, number = total > 0 and total or nil }
            if #items == 0 then
                elements[#elements + 1] = { kind = "note", text = empty }
            elseif section.place == "worn" and section.slots and not options.category then
                Doll(elements, { items = items, slots = section.slots }, searching)
            elseif section.place == "worn" then
                for _, entry in ipairs(items) do elements[#elements + 1] = { kind = "gear", entry = entry } end
            else
                Shown(elements, items, options)
            end
        end
    end
    return elements
end

-- How many of a character's items each category holds in these sections (for the sidebar): [key] = count,
-- total = all of them.
function Items.Counts(sections)
    local counts = { total = 0 }
    for _, section in ipairs(sections) do
        if section.place ~= "worn" then
            for _, entry in ipairs(section.items) do
                local key = Items.Record(entry.item).category or Categories.CATCH_ALL
                counts[key] = (counts[key] or 0) + 1
                counts.total = counts.total + 1
            end
        end
    end
    return counts
end

function Items.Show(elements, keep)
    box:SetDataProvider(CreateDataProvider(elements), keep and ScrollBoxConstants.RetainScrollPosition or nil)
end

-- For the tests: the records made so far are forgotten (the game learned more).
function Items.Forget(item)
    if item then records[item] = nil else
        for key in pairs(records) do records[key] = nil end
    end
end
