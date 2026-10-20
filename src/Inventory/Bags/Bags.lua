local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags
--  Our bags: a window on the module's full screen (Board.lua, the key
--  "bags") that shows and handles everything the character carries, and the
--  bank while it is open. The game's own bag windows stay as they are: our
--  code neither opens nor closes them, nor the bank's.
--
--      the head     the clean-up of the game (C_Container.SortBags: the
--                   items moved in the bags, as the game's bag window's
--                   button does), the dropdown View: how the bags are shown
--                   (Layout.VIEWS) and what sorts them inside their groups
--                   (Contents.ORDERS); both kept (store.bags)
--      the body     a scroll area with the items as the view lays them out
--                   (Layout.lua), each the game's own item button (Cells.lua);
--                   the bank's parts follow the bags while it is open, each
--                   under a head with its own clean-up (C_Container.SortBank)
--      the foot     the bags themselves, the free slots, the currencies, the
--                   gold; on the head, what can be done at a vendor or a
--                   banker (Foot.lua)
--  The search box of the full window finds items by their name, their
--  group or their item level; what it does not find is dimmed in the view
--  of every slot and left out of the others.
--
--  New items: what the game marks as new comes first, in the group New, and
--  stays there while the window is open, even after the mouse took the
--  game's mark off it; the next time it opens they are in their own groups.
--
--  It listens to the game only while its panel is shown, and draws once a
--  burst of bag events is over (BAG_UPDATE_DELAYED, a frame later).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bags = {}
ns.Bags = Bags

Bags.EDGE = 6        -- from the panel's sides to what is in it
Bags.SCROLL = 20     -- room at the right for the game's scroll bar
Bags.HEAD_BUTTON = 26 -- the clean-up's button, as the game's
Bags.MENU_WIDTH = 120
Bags.LEAST = { 420, 320 }

local Contents, Layout, Cells, Foot = ns.Contents, ns.Layout, ns.Cells, ns.Foot

local panel, scroll, child, menu, sort
local kept            -- store.bags: { view, order }
local query           -- what the search found by (Core.Fuzzy.Query), nil: nothing typed
local shown = false
local carried = { place = "bags", slots = {}, free = {} }
local sections = { carried }
local banked = {}     -- [kind] = a bank's section
local bankList = {}
local carriedBags = {}
local places = {}
local fresh = {}      -- [record] = the item that was new in it while the window is open
local heads, rows     -- pools (Core.Pool)

-------------------------------------------------------------------------------
--  Reading the bags
-------------------------------------------------------------------------------
local function Section(kind)
    local section = banked[kind.kind]
    if not section then
        section = { place = kind.kind, word = kind.word, slots = {}, free = {}, bank = kind.type }
        banked[kind.kind] = section
    end
    return section
end

local function Clear(section)
    for index = #section.slots, 1, -1 do section.slots[index] = nil end
    Contents.ClearFree(section.free)
end

-- What was new while the window is open stays new until it closes.
local function Fresh(slots)
    for _, record in ipairs(slots) do
        if record.item and record.new then fresh[record] = record.item end
        if record.item and fresh[record] == record.item then
            record.group = "new"
        elseif fresh[record] then
            fresh[record] = nil
        end
    end
end

local function Read()
    for index = #sections, 2, -1 do sections[index] = nil end
    Clear(carried)
    Contents.Scan(Contents.Carried(carriedBags), "bags", carried.slots, carried.free)
    Fresh(carried.slots)
    for _, kind in ipairs(Contents.Banks(bankList)) do
        local section = Section(kind)
        Clear(section)
        Contents.Scan(kind.bags, kind.kind, section.slots, section.free)
        Fresh(section.slots)
        sections[#sections + 1] = section
    end
    carried.word = #sections > 1 and ns.TEXT.bags or nil
end

-------------------------------------------------------------------------------
--  Drawing what the layout says
-------------------------------------------------------------------------------
local function CleanBank(button)
    local api = rawget(_G, "C_Container")
    local kind = Bags.headOf and Bags.headOf[button]
    if not (api and api.SortBank and kind) or InCombatLockdown() then return end
    Core.Sound("UI_BAG_SORTING_01")
    api.SortBank(kind)
end

local function CleanBankTip(button)
    local kind = Bags.headOf and Bags.headOf[button]
    local word = kind == (Enum and Enum.BankType and Enum.BankType.Account) and "BAG_CLEANUP_ACCOUNT_BANK" or "BAG_CLEANUP_BANK"
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(Core.Word(word, "Clean Up Bank"), 1, 1, 1)
    GameTooltip:Show()
end

-- The game's clean-up button (its art and sound), for the bags or a bank.
local function CleanButton(parent, click, enter)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(Bags.HEAD_BUTTON + 2, Bags.HEAD_BUTTON)
    button:SetNormalAtlas("bags-button-autosort-up")
    button:SetPushedAtlas("bags-button-autosort-down")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", function(self) ns.Safe("bags", click, self) end)
    button:SetScript("OnEnter", function(self) ns.Safe("bags", enter, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- A head over a part (level 1: the bags, a bank) or a group (level 2): its words at the left, its number at the
-- right, a thin line under a part's.
local function MakeHead()
    local head = CreateFrame("Frame", nil, child)
    head.word = head:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    head.word:SetPoint("LEFT")
    head.number = head:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    head.number:SetPoint("RIGHT", -2, 0)
    head.line = head:CreateTexture(nil, "ARTWORK")
    head.line:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 0.35)
    head.line:SetPoint("BOTTOMLEFT")
    head.line:SetPoint("BOTTOMRIGHT")
    head.line:SetHeight(1)
    head.clean = CleanButton(head, CleanBank, CleanBankTip)
    head.clean:SetScale(0.75)
    head.clean:SetPoint("RIGHT", head.number, "LEFT", -6, 0)
    return head
end

local function DrawHead(place)
    local head = heads:Take()
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", child, "TOPLEFT", place.x, -place.y)
    head:SetSize(place.width, place.height)
    head.word:SetFontObject(place.level == 1 and "GameFontNormalMed2" or "GameFontNormal")
    head.word:SetText(place.word or "")
    local number = place.number
    head.number:SetText(number and (place.spare and ns.TEXT.bagsFree:format(number) or tostring(number)) or "")
    head.line:SetShown(place.level == 1)
    local bank = place.level == 1 and place.section and place.section.bank
    Bags.headOf = Bags.headOf or {}
    Bags.headOf[head.clean] = bank
    head.clean:SetShown(bank ~= nil)
    head:Show()
end

-- A list's line: behind its item button, which reaches over it; the item's name in its quality's colour, its
-- item level, its count (a free slots' line: the kind of bag and how many are free).
local function MakeRow()
    local row = CreateFrame("Frame", nil, child)
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row.back:SetColorTexture(1, 1, 1, 0.04)
    row.lit = row:CreateTexture(nil, "BORDER")
    row.lit:SetAllPoints()
    row.lit:SetColorTexture(1, 1, 1, 0.08)
    row.lit:Hide()
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.name:SetPoint("LEFT", Layout.ICON + 8, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.count = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.count:SetPoint("RIGHT", -6, 0)
    row.count:SetWidth(44)
    row.count:SetJustifyH("RIGHT")
    row.level = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.level:SetPoint("RIGHT", row.count, "LEFT", -6, 0)
    row.level:SetWidth(36)
    row.level:SetJustifyH("RIGHT")
    row.name:SetPoint("RIGHT", row.level, "LEFT", -6, 0)
    return row
end

local rowOf = {} -- [button] = the row it stands on now
Bags.rowOf = rowOf

local function DrawRow(place, button)
    local row = rows:Take()
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", child, "TOPLEFT", place.x, -place.y)
    row:SetSize(place.width, place.height)
    row:SetFrameLevel(child:GetFrameLevel() + 1)
    row.back:SetShown(rows.taken % 2 == 1)
    row.lit:Hide()
    local record = place.record
    if place.free then
        row.name:SetText(Contents.KindWord(place.free.kind))
        row.name:SetTextColor(0.6, 0.6, 0.6)
        row.level:SetText("")
        row.count:SetText(ns.TEXT.bagsFree:format(place.free.count))
    else
        local color = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[record.quality]
        row.name:SetText(record.name or "")
        if color then row.name:SetTextColor(color.r, color.g, color.b) else row.name:SetTextColor(1, 1, 1) end
        row.level:SetText(record.level or "")
        row.count:SetText(record.count and record.count > 1 and record.count or "")
    end
    rowOf[button] = row
    row:Show()
end

-- The mouse on a list's item button: its line lit.
function Bags.Hover(button, on)
    local row = rowOf[button]
    if row and row:IsShown() then row.lit:SetShown(on) end
end

local function Draw()
    if not child then return end
    local width = child:GetWidth()
    if not width or width <= 0 then return end
    local count, height = Layout.Lay(kept.view, sections, width, query, kept.order, places)
    heads:Begin()
    rows:Begin()
    Cells.Begin()
    for button in pairs(rowOf) do rowOf[button] = nil end
    for index = 1, count do
        local place = places[index]
        if place.kind == "head" then
            DrawHead(place)
        else
            local record = place.record
            local button = Cells.Button(record.bag, record.slot)
            if button then
                if place.free then Cells.DrawFree(button, record, place.free) else Cells.Draw(button, record, place.dim) end
                if place.kind == "row" then
                    -- The button at the line's left, in its middle; its click over the rest of the line.
                    local inset = (place.height - Layout.ICON) / 2
                    Cells.Place(button, place.x + inset, place.y + inset, place.scale, place.width - inset)
                    DrawRow(place, button)
                else
                    Cells.Place(button, place.x, place.y, place.scale)
                end
            end
        end
    end
    Cells.Done()
    heads:Done()
    rows:Done()
    child:SetHeight(math.max(1, height))
    if Cells.short then Core.AfterCombat("inventory: bags", Bags.Refresh) end
end

-- Everything read anew and drawn.
function Bags.Refresh()
    if not shown then return end
    ns.Safe("bags", Read)
    ns.Safe("bags", Draw)
    ns.Safe("bags", Foot.Refresh, carried.free)
end

-- Drawn anew as it was read (the view, the order, the search or the width changed).
function Bags.Redraw()
    if shown then ns.Safe("bags", Draw) end
end

-------------------------------------------------------------------------------
--  The game's events, while the panel is shown
-------------------------------------------------------------------------------
local Soon = Core.Later(Bags.Refresh)

local function Banker(open)
    Contents.bankOpen = open
    Soon()
end

-- A slot's lock changed (an item on the cursor): only its grey.
local function Locked(bag, slot)
    bag, slot = Core.Plain(bag), Core.Plain(slot)
    local slots = Contents.records[bag]
    local record = slots and slot and slots[slot]
    if not record then return end
    local api = rawget(_G, "C_Container")
    local info = api and Core.Ask(api.GetContainerItemInfo, bag, slot)
    record.locked = type(info) == "table" and Core.Plain(info.isLocked) == true
    Cells.Lock(record)
end

-- An item's data came from the server: drawn anew if one of ours waited for it (its name, its item level).
local function Arrived(item)
    item = Core.Plain(item)
    if item and Contents.waiting[item] then
        Contents.waiting[item] = nil
        Soon()
    end
end

local EVENTS = {
    BAG_UPDATE_DELAYED = Soon, BAG_NEW_ITEMS_UPDATED = Soon, BAG_CONTAINER_UPDATE = Soon,
    QUEST_ACCEPTED = Soon, QUEST_REMOVED = Soon, MERCHANT_SHOW = Soon, MERCHANT_CLOSED = Soon,
    PLAYERBANKSLOTS_CHANGED = Soon, BANK_TABS_CHANGED = Soon, PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = Soon,
    BANKFRAME_OPENED = function() Banker(true) end, BANKFRAME_CLOSED = function() Banker(false) end,
    ITEM_LOCK_CHANGED = Locked, GET_ITEM_INFO_RECEIVED = Arrived,
    BAG_UPDATE_COOLDOWN = function() Cells.Cooldowns() end,
    PLAYER_MONEY = function() Foot.Gold() end, CURRENCY_DISPLAY_UPDATE = function() Foot.Tokens() end,
}
local UNIT_EVENTS = { UNIT_QUEST_LOG_CHANGED = Soon }

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- What is kept of the window: its view and its order, each one of those there are.
local function Kept()
    local store = ns.store
    if type(store.bags) ~= "table" then store.bags = {} end
    local bags = store.bags
    if not Layout.VIEW[bags.view] then bags.view = "groups" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == bags.order end
    if not known then bags.order = "quality" end
    return bags
end

local function IsView(key) return kept.view == key end
local function SetView(key)
    kept.view = key
    Bags.Redraw()
end
local function IsOrder(key) return kept.order == key end
local function SetOrder(key)
    kept.order = key
    Bags.Redraw()
end
local Viewed = ns.Guard(IsView)
local Choose = ns.Guard(SetView)
local Ordered = ns.Guard(IsOrder)
local Order = ns.Guard(SetOrder)

local function Menu(_, root)
    root:CreateTitle(ns.TEXT.bagsView)
    for _, view in ipairs(Layout.VIEWS) do root:CreateRadio(view.word, Viewed, Choose, view.key) end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsOrder)
    for _, order in ipairs(Contents.ORDERS) do root:CreateRadio(order.word, Ordered, Order, order.key) end
end

local function Clean()
    local api = rawget(_G, "C_Container")
    if not (api and api.SortBags) or InCombatLockdown() then return end
    Core.Sound("UI_BAG_SORTING_01")
    api.SortBags()
end

local function CleanTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(Core.Word("BAG_CLEANUP_BAGS", "Clean Up Bags"), 1, 1, 1)
    local about = rawget(_G, "BAG_CLEANUP_BAGS_DESCRIPTION")
    if about then GameTooltip:AddLine(about, 1, 0.82, 0, true) end
    GameTooltip:Show()
end

function Bags.Build(made)
    panel = made
    kept = Kept()
    local body = panel.body
    menu = CreateFrame("DropdownButton", nil, panel.head, "WowStyle1DropdownTemplate")
    menu:SetPoint("RIGHT", -Bags.EDGE, 0)
    menu:SetWidth(Bags.MENU_WIDTH)
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(Menu)
    sort = CleanButton(panel.head, Clean, CleanTip)
    sort:SetPoint("RIGHT", menu, "LEFT", -6, 0)

    scroll = CreateFrame("ScrollFrame", nil, body, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", Bags.EDGE, -Bags.EDGE)
    scroll:SetPoint("BOTTOMRIGHT", -(Bags.EDGE + Bags.SCROLL), Foot.HEIGHT + Bags.EDGE)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    Cells.Build(child)
    heads = Core.Pool(MakeHead)
    rows = Core.Pool(MakeRow)
    Foot.Build(body, sort)
end

function Bags.Show(on)
    shown = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    for event, fn in pairs(UNIT_EVENTS) do
        if on then Core.OnUnit(event, "player", fn) else Core.OffUnit(event, "player", fn) end
    end
    if on then
        Contents.bankOpen = Foot.Talking("Banker")
        Bags.Refresh()
    else
        for record in pairs(fresh) do fresh[record] = nil end
        Cells.Light(nil)
    end
end

-- The panel's new size: the scroll area's child as wide as the area, laid out anew.
function Bags.Size(width)
    if not child then return end
    child:SetWidth(math.max(1, width - 2 * Bags.EDGE - Bags.SCROLL))
    Bags.Redraw()
end

function Bags.Search(text)
    query = Core.Fuzzy.Query(text)
    Bags.Redraw()
end

-- The board's least: room for some of the game's item buttons in a line, the foot, the panel's head and edges.
local edge, head = Core.Board.EDGE, Core.Board.HEAD
ns.Board.Part("bags", ns.TEXT.bags, { Bags.LEAST[1] + 2 * edge, Bags.LEAST[2] + head + 2 * edge }, Bags)
