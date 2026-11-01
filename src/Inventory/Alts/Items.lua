local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts - Items
--  What the chosen character has, as last seen (Snapshot.lua), made into what
--  the bags draw with, so that it looks and behaves as they do: an item as a
--  record of the bags' kind (Items.Record), a place as a section for the bags'
--  views (Items.Sections: Views.Build lays it out by the bags' categories,
--  groups and order, Canvas.lua draws it in the bags' displays), a read-only
--  button for the bags' cells (Items.Button). Core keeps a bag's items and
--  counts, not the slots they lie in: no empty slots are shown, and an item
--  stands once in a place.
--
--  What is worn is the paper doll, below the items: the gear in its slots as
--  our character sheet has them (Sheet/Slots.lua: its columns, sizes and slot
--  frames), as wide as the items' room and at most as the sheet's, the
--  weapons' row in the middle below; an empty slot is its pencil slot alone.
--  The bags worn in their slots stand as items under Equipped's head. A
--  character Core has not read slot by slot yet (it has not logged in since)
--  has what it wears by category, as its bags.
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

local Slots = ns.Slots        -- the sheet's slots: their columns, sizes and frames
Items.DOLL = ns.Sheet.LEFT - Slots.LEFT - Slots.RIGHT -- the doll at most as wide as the sheet's columns stand apart
Items.DOLL_EDGE = Slots.GAP / 2 -- round the doll: its slots' frames stand out of their buttons
local STEP = Slots.SIZE + Slots.GAP -- from a slot to the one below it
Items.DOLL_HEIGHT = 2 * Items.DOLL_EDGE + 9 * STEP -- eight slots down, the weapons' row below them, the room round them

local Cells, Categories = ns.Cells, ns.Categories
local dollSlots, dolled -- the doll's slots ({ name, id, picture, column, index }), and [slot ID] = true; asked once

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

-- What one place has of an item: the item's record, with that place's count.
local Held = { __index = function(held, key) return rawget(held, "record")[key] end }
local function Have(entry)
    return setmetatable({ record = Items.Record(entry.item), count = entry.count }, Held)
end

-------------------------------------------------------------------------------
--  The buttons
-------------------------------------------------------------------------------
-- The item a button shows: the doll's own, or the record the bags' cells draw on it.
local function Shows(button)
    local record = Cells.Record(button)
    return button.item or record and record.item
end

local function Enter(button)
    local item = Shows(button)
    if not (item or button.slotName) then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if item then
        GameTooltip:SetItemByID(item)
    else
        GameTooltip:SetText(Core.Word(button.slotName:upper(), button.slotName))
    end
    GameTooltip:Show()
end

local function Click(button, mouse)
    local item = Shows(button)
    local link = mouse == "LeftButton" and item and IsModifiedClick() and Link(item)
    if link then Game("HandleModifiedItemClick", link) end
end

-- The window runs apart from the module's other windows (Board.lua): an error here is noted, nothing more.
local function OnEnter(button) ns.Safe("alts", Enter, button) end
local function OnClick(button, mouse) ns.Safe("alts", Click, button, mouse) end

-- One of the game's item buttons, read only: the game's tooltip, a modified click. In parent; also what the window's
-- pool of cells makes its buttons with (Cells.New).
function Items.Button(parent)
    local made, button = pcall(CreateFrame, "ItemButton", nil, parent)
    if not made then button = CreateFrame("Button", nil, parent, "ItemButtonTemplate") end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", OnClick)
    return button
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
    local button = Items.Button(doll)
    local small = slot.column == "ammo"
    button:SetSize(small and Slots.AMMO or Slots.SIZE, small and Slots.AMMO or Slots.SIZE)
    button.slotName, button.picture = slot.name, slot.picture
    Core.Journal.Slot(button, 3, "BACKGROUND")
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local border = Cells.Part(button, "IconBorder")
    if border then border:SetAlpha(0) end
    local icon = Cells.Part(button, "icon")
    if icon then -- as the sheet's: the whole slot, its corners rounded, no border
        icon:ClearAllPoints()
        icon:SetAllPoints(button)
        icon:SetTexCoord(Cells.ZOOM, 1 - Cells.ZOOM, Cells.ZOOM, 1 - Cells.ZOOM)
        Cells.Mask(button, Cells.ROUNDED, icon)
    end
    return button
end

-- The doll, in parent; the window gives it its place.
function Items.MakeDoll(parent)
    local doll = CreateFrame("Frame", nil, parent)
    doll.buttons = {}
    for index, slot in ipairs(DollSlots()) do doll.buttons[index] = DollSlot(doll, slot) end
    doll:Hide()
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

-- The doll drawn for what a character wears (Items.Sections: slots, found) in a room so wide: the columns as far apart
-- as that (at most the sheet's), the weapons' row in the middle below them. The ranged slot where the game shows one
-- or something is in it, the ammo beside it where some is worn.
function Items.DrawDoll(doll, worn, room)
    local slots, found, edge = worn.slots, worn.found, Items.DOLL_EDGE
    local wide = math.min(room, Items.DOLL)
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
--  The sections
-------------------------------------------------------------------------------
-- What is worn slot by slot (section.slots): what is worn in no slot of the doll (the bags), in their slots' order, and
-- the doll ({ slots, found }; nil while searching if nothing in it is found). section.items: what is found.
local function Worn(section, searching)
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
    if lit or not searching then return rest, { slots = section.slots, found = searching and found or nil } end
    return rest, nil
end

-- A place's head: its words, and what is said beside them (faint) in the same line.
local function Word(title, note, empty, none)
    local said = none and (note and note .. ": " .. empty or empty) or note
    return said and title .. "  |c" .. ns.Paper.FAINT_HEX .. said .. "|r" or title
end

-- A character's places (Snapshot.Sections) as sections for Views.Build, and the doll to draw (nil: none). Each section:
-- { word (its head), slots (what it holds), doll (the doll stands under it), total (how many items, the doll's too),
-- kind (its place) }; its place is none of the bags' own, so Views gives it only what it holds. Head(place) gives a head's words, the note beside them and what
-- a place without items says. searching: a place where nothing is found is left out. only: that place alone (nil:
-- all); filtered: one category or group is shown, of the bags and the bank.
function Items.Sections(snapshot, Head, searching, only, filtered)
    local sections, doll = {}, nil
    for _, section in ipairs(snapshot) do
        local worn = section.place == "worn"
        if (not only or only == section.place) and not (filtered and worn) then
            local items, drawn = section.items, nil
            if worn and section.slots and #items > 0 then items, drawn = Worn(section, searching) end
            if #items > 0 or drawn or not searching then
                local title, note, empty = Head(section.place)
                local shown = { place = "alts", kind = section.place, slots = {}, doll = drawn ~= nil,
                                total = #section.items, word = Word(title, note, empty, #items == 0 and not drawn) }
                for index, entry in ipairs(items) do shown.slots[index] = Have(entry) end
                sections[#sections + 1] = shown
                doll = drawn or doll
            end
        end
    end
    return sections, doll
end

-- How many of a character's items each place, category and group holds in these sections (for the sidebar): [key] and
-- ["group:<group>"] = count, total = all that the categories hold (what is worn is no one's), places = { [place] = count }.
function Items.Counts(sections)
    local counts = { total = 0, places = {} }
    for _, section in ipairs(sections) do
        counts.places[section.place] = #section.items
        if section.place ~= "worn" then
            for _, entry in ipairs(section.items) do
                local key = Items.Record(entry.item).category or Categories.CATCH_ALL
                counts[key] = (counts[key] or 0) + 1
                counts.total = counts.total + 1
                local group = Categories.GroupOf(key)
                if group then counts["group:" .. group] = (counts["group:" .. group] or 0) + 1 end
            end
        end
    end
    return counts
end
