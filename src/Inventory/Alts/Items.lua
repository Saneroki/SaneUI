local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Items
--  What the chosen character has, as last seen (Snapshot.lua), in one list
--  that scrolls (the game's WowScrollBoxList and MinimalScrollBar): a head per
--  place (Bags, Bank, Equipped), the items of a bag or bank place as a grid of
--  the game's item buttons in the order Core keeps them, what is worn as a list
--  (its icon, its name in its quality's colour). Core keeps items and counts per
--  place, not the slots they lie in: the grid holds no empty slots.
--
--  Read only: nothing here moves an item. An item's tooltip is the game's
--  (GameTooltip:SetItemByID); a modified click links it or tries it on
--  (HandleModifiedItemClick), as on the game's own buttons. While searching,
--  only what is found is listed, and a place without any of it is left out.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Items = {}
ns.Items = Items

Items.SIZE, Items.GAP = 37, 4 -- an item button, as the game's, and the room between two
Items.HEAD = 26               -- a place's head
Items.LINE = 24               -- a line of the list of what is worn
Items.ICON = 20               -- its icon
Items.NOTE = 22               -- a line that says why a place shows nothing
Items.BAR = 14                -- the room right of the list for its scroll bar

local box, bar, view
local columns = 1

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

local function Enter(button)
    if not button.item then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(button.item)
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

-- An item drawn on a button as the game draws one: its icon, count and quality border.
local function Fill(button, entry)
    button.item = entry.item
    Game("SetItemButtonTexture", button, ItemAPI("GetItemIconByID", entry.item))
    Game("SetItemButtonCount", button, entry.count)
    Game("SetItemButtonQuality", button, ItemAPI("GetItemQualityByID", entry.item), entry.item)
    button:Show()
end

-- A line of the list of what is worn: a button over its whole row.
local function Line(row)
    local line = CreateFrame("Button", nil, row)
    line:SetAllPoints()
    line.icon = line:CreateTexture(nil, "ARTWORK")
    line.icon:SetSize(Items.ICON, Items.ICON)
    line.icon:SetPoint("LEFT", 2, 0)
    line.text = line:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    line.text:SetPoint("LEFT", line.icon, "RIGHT", 6, 0)
    line.text:SetPoint("RIGHT", -4, 0)
    line.text:SetJustifyH("LEFT")
    line.text:SetWordWrap(false)
    local light = line:CreateTexture(nil, "HIGHLIGHT")
    light:SetAllPoints()
    light:SetAtlas("Options_List_Hover")
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
    if colour then line.text:SetTextColor(colour.r, colour.g, colour.b) else line.text:SetTextColor(1, 1, 1) end
    line:Show()
end

-- A row of the list, made anew for whatever it holds now (the list reuses its rows): a head, a row of
-- the grid, a line of what is worn, or a note.
local function Draw(row, element)
    if not row.buttons then
        row.buttons = {}
        row.title = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        row.title:SetPoint("BOTTOMLEFT", 2, 4)
        row.note = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        row.rule = row:CreateTexture(nil, "ARTWORK")
        row.rule:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.25)
        row.rule:SetPoint("BOTTOMLEFT", 0, 1)
        row.rule:SetPoint("BOTTOMRIGHT", 0, 1)
        row.rule:SetHeight(1)
    end
    local kind = element.kind
    row.title:SetShown(kind == "head")
    row.rule:SetShown(kind == "head")
    row.note:SetShown(kind == "head" or kind == "note")
    row.note:ClearAllPoints()
    if kind == "head" then
        row.title:SetText(element.text)
        row.note:SetPoint("BOTTOMRIGHT", -2, 5)
        row.note:SetText(element.note or "")
    elseif kind == "note" then
        row.note:SetPoint("LEFT", 2, 0)
        row.note:SetText(element.text)
    end
    local count = kind == "grid" and element.to - element.from + 1 or 0
    for index = 1, math.max(count, #row.buttons) do
        local button = row.buttons[index]
        if index <= count then
            if not button then
                button = Button(row)
                button:SetPoint("TOPLEFT", (index - 1) * (Items.SIZE + Items.GAP), 0)
                row.buttons[index] = button
            end
            Fill(button, element.items[element.from + index - 1])
        else
            button.item = nil
            button:Hide()
        end
    end
    if kind == "gear" then
        row.line = row.line or Line(row)
        Wear(row.line, element.entry)
    elseif row.line then
        row.line.item = nil
        row.line:Hide()
    end
end

local HEIGHTS = { head = Items.HEAD, grid = Items.SIZE + Items.GAP, gear = Items.LINE, note = Items.NOTE }
local function Height(_, element)
    return HEIGHTS[element.kind] or Items.NOTE
end

-- The list's rows, made and drawn by the game's list: each drawn apart from the others.
local function Init(row, element)
    ns.Safe("alts", Draw, row, element)
end
local function Factory(factory)
    factory("Frame", Init)
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

-- How many item buttons a row of the grid holds at this width.
function Items.Fit(width)
    local fit = math.max(1, math.floor((width + Items.GAP) / (Items.SIZE + Items.GAP)))
    local changed = fit ~= columns
    columns = fit
    return changed
end

-- The list's elements for these sections (Snapshot.Sections): a head per place, rows of the grid, lines of
-- what is worn; a note where a place shows nothing. Head(place) gives the head's words, the note beside it
-- and what a place without items says. searching: a place where nothing is found is left out.
function Items.Elements(sections, Head, searching)
    local elements = {}
    for _, section in ipairs(sections) do
        local items = section.items
        if not (searching and #items == 0) then
            local title, note, empty = Head(section.place)
            elements[#elements + 1] = { kind = "head", text = title, note = note }
            if #items == 0 then
                elements[#elements + 1] = { kind = "note", text = empty }
            elseif section.place == "worn" then
                for _, entry in ipairs(items) do elements[#elements + 1] = { kind = "gear", entry = entry } end
            else
                for from = 1, #items, columns do
                    elements[#elements + 1] = { kind = "grid", items = items, from = from, to = math.min(from + columns - 1, #items) }
                end
            end
        end
    end
    return elements
end

function Items.Show(elements, keep)
    box:SetDataProvider(CreateDataProvider(elements), keep and ScrollBoxConstants.RetainScrollPosition or nil)
end
