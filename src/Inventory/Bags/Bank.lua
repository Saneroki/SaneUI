local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags - Bank
--  The bank: a window of its own on the module's full screen (Board.lua, the
--  key "bank"), there while the character is at a banker (its part's
--  Present): the tabs of each bank the game lets the player see
--  (Contents.Banks: the character's own, then the account's), in the bags'
--  flat look. The game's own bank window stays as it is: our code neither
--  opens nor closes it.
--
--      the bar      a dark band: the bank's slots taken of how many; at the
--                   right Deposit All Reagents (where the bank takes them),
--                   the game's clean-up of the bank shown (C_Container.
--                   SortBank), the dropdown View: the display (as the bags'),
--                   Group by Category, the order
--      the sidebar  All Bank Tabs (each tab under its head, every slot), One
--                   Bank (each bank's slots together), then each tab by its
--                   name with how many of its slots are taken
--      the body     the slots as the view says (with Group by Category: the
--                   items by the bags' categories instead), each the game's
--                   own item button (Cells.lua, a pool of its own): click,
--                   drag, right click into the bags, the tooltip, all the
--                   game's
--      the foot     the character's gold
--  An item: Alt and a right click its menu, a middle click pins it, Shift and
--  a click the splitter (with Stack Splitter Everywhere), as in the bags. The
--  search box of the full window fades what it does not find (with Group by
--  Category: leaves it out). The window opens with All Bank Tabs; the view
--  chosen holds while it is open. Kept in store.bank: look, order, group,
--  folded, narrow.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bank = {}
ns.Bank = Bank

Bank.LEAST = { 460, 300 }
Bank.TABS, Bank.ONE = "tabs", "onebank"
Bank.ICON = "Interface\\Icons\\INV_Misc_Bag_09"

local Contents, Cells, Views, Layout, Categories = ns.Contents, ns.Cells, ns.Views, ns.Layout, ns.Categories
local Menus, Foot, Columns, Bags = ns.Menus, ns.Foot, ns.Columns, ns.Bags

local panel, scroll, child, bar, menu, sort, deposit, foot, gold, side
local canvas, cells, rail
local kept            -- store.bank
local query, shown, viewing, width = nil, false, nil, 0
local sections, banked, kinds = {}, {}, {}
local store = { blocks = {}, entries = {} } -- Views' blocks for the bank
local how = {}

local function Options()
    return type(ns.options) == "table" and ns.options or {}
end

-------------------------------------------------------------------------------
--  Reading the bank
-------------------------------------------------------------------------------
local function Section(kind)
    local section = banked[kind.kind]
    if not section then
        section = { place = kind.kind, word = kind.word, slots = {}, free = {}, bank = kind.type }
        banked[kind.kind] = section
    end
    return section
end

local function Read()
    for index = #sections, 1, -1 do sections[index] = nil end
    Contents.Sets()
    for _, kind in ipairs(Contents.Banks(kinds)) do
        local section = Section(kind)
        Bags.Clear(section)
        Contents.Scan(kind.bags, kind.kind, section.slots, section.free)
        sections[#sections + 1] = section
    end
end

-- The view shown: the one chosen, else All Bank Tabs; a tab no more there gives way to it.
local function View()
    local view = viewing or Bank.TABS
    local bag = tonumber(view:match("^tab:(%-?%d+)$") or "")
    if bag then
        for _, section in ipairs(sections) do
            for _, record in ipairs(section.slots) do
                if record.bag == bag then return view end
            end
        end
        return Bank.TABS
    end
    return view
end

function Bank.Viewing()
    return View()
end

-- One tab's section: the slots of that tab only (used again).
local tabbed = { slots = {}, free = {} }
local function Tab(bag)
    for index = #tabbed.slots, 1, -1 do tabbed.slots[index] = nil end
    for _, section in ipairs(sections) do
        for _, record in ipairs(section.slots) do
            if record.bag == bag then
                tabbed.place, tabbed.word, tabbed.bank = section.place, nil, section.bank
                tabbed.slots[#tabbed.slots + 1] = record
            end
        end
    end
    return tabbed
end

-------------------------------------------------------------------------------
--  Drawing
-------------------------------------------------------------------------------
local shownSections, plain = {}, { showPinned = false, showRecent = false, plus = false }

-- The blocks of the view: the tabs each by itself, each bank together, one tab; by category with Group by Category.
local function Blocks()
    local view = View()
    local options = Options()
    plain.merge = options.merge
    local bag = tonumber(view:match("^tab:(%-?%d+)$") or "")
    for index = #shownSections, 1, -1 do shownSections[index] = nil end
    if bag then
        shownSections[1] = Tab(bag)
    else
        for index, section in ipairs(sections) do shownSections[index] = section end
    end
    if kept.group then return Views.Build(Views.ALL, shownSections, query, kept.order, plain, store) end
    local as = (view == Bank.ONE) and Views.ONE or Views.EACH
    return Views.Build(as, shownSections, query, kept.order, plain, store)
end

-- The bar's count: the slots taken of how many in the bank or tab shown.
local function Count()
    local taken, all = 0, 0
    local view = View()
    local bag = tonumber(view:match("^tab:(%-?%d+)$") or "")
    for _, section in ipairs(sections) do
        for _, record in ipairs(section.slots) do
            if not bag or record.bag == bag then
                all = all + 1
                if record.item then taken = taken + 1 end
            end
        end
    end
    bar.count:SetText(ns.TEXT.bagsItems:format(taken, all))
end

local function Sidebar()
    local view = View()
    rail:Begin()
    rail:Row(ns.TEXT.bankTabs, nil, Bank.ICON, nil, 0, view == Bank.TABS).view = Bank.TABS
    rail:Row(ns.TEXT.bankOne, nil, "Interface\\Icons\\INV_Misc_Bag_08", nil, 0, view == Bank.ONE).view = Bank.ONE
    for _, section in ipairs(sections) do
        rail:Divider()
        local seen = {}
        for _, record in ipairs(section.slots) do
            local tab = record.bag
            if not seen[tab] then
                seen[tab] = { taken = 0, all = 0, order = #seen + 1 }
                seen[#seen + 1] = tab
            end
            seen[tab].all = seen[tab].all + 1
            if record.item then seen[tab].taken = seen[tab].taken + 1 end
        end
        for _, tab in ipairs(seen) do
            local row = rail:Row(Contents.BagWord(tab, section.place), seen[tab].taken, Bank.ICON, nil, 0, view == "tab:" .. tab)
            row.view = "tab:" .. tab
        end
    end
    rail:Done()
end

local function Draw()
    if not child then return end
    local room = child:GetWidth()
    if not room or room <= 0 then return end
    local options = Options()
    local blocks = Blocks()
    Bank.blocks = blocks
    how.bind, how.coin, how.grey, how.set = options.bind == true, options.coin == true, options.grey == true, options.setName == true
    how.level, how.plain = options.itemLevel ~= false, options.borders == false
    child:SetHeight(math.max(1, canvas:Draw(blocks, room, how)))
    Count()
    Sidebar()
    deposit:SetShown(Foot.Deposits())
    if cells.short then Core.AfterCombat("inventory: bank", Bank.Refresh) end
end

function Bank.Refresh()
    if not shown then return end
    ns.Safe("bank", Read)
    ns.Safe("bank", Draw)
    if gold then gold:SetText(Core.Coins(Core.Plain(Core.Ask(GetMoney)) or 0) or "") end
end

function Bank.Redraw()
    if shown then ns.Safe("bank", Draw) end
end

function Bank.Choose(view)
    viewing = view
    if scroll then scroll:SetVerticalScroll(0) end
    Bank.Redraw()
end

-- The mouse on an item button's line (the list); a click after the game's own: the item's menu (Alt and the
-- right button), the splitter (Shift, with Stack Splitter Everywhere), a pin (the middle button).
function Bank.Hover(button, on)
    if canvas then canvas:Hover(button, on) end
end

function Bank.Clicked(button, mouse)
    local alt = rawget(_G, "IsAltKeyDown")
    if mouse == "RightButton" and alt and alt() then return Menus.Item(button) end
    local record = Cells.Record(button)
    if not (record and record.item) then return end
    local modified = rawget(_G, "IsModifiedClick")
    if mouse == "LeftButton" and modified and modified("SPLITSTACK") and Options().splitter and (record.count or 1) > 1 then
        local game = rawget(_G, "StackSplitFrame")
        if type(game) == "table" and game.IsShown and game:IsShown() then game:Hide() end
        return ns.Split.Open(button, record)
    end
    if mouse ~= "MiddleButton" then return end
    Categories.Pin(record.item, not Categories.Pinned(record.item))
    Bank.Refresh()
    if ns.Bags.Refresh then ns.Bags.Refresh() end
end

-------------------------------------------------------------------------------
--  The game's events
-------------------------------------------------------------------------------
local Soon = Core.Later(Bank.Refresh)

local function Locked(bag, slot)
    bag, slot = Core.Plain(bag), Core.Plain(slot)
    local slots = Contents.records[bag]
    local record = slots and slot and slots[slot]
    if not record then return end
    local api = rawget(_G, "C_Container")
    local info = api and Core.Ask(api.GetContainerItemInfo, bag, slot)
    record.locked = type(info) == "table" and Core.Plain(info.isLocked) == true
    cells:Lock(record)
end

local EVENTS = {
    BAG_UPDATE_DELAYED = Soon, PLAYERBANKSLOTS_CHANGED = Soon, BANK_TABS_CHANGED = Soon,
    PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = Soon, GET_ITEM_INFO_RECEIVED = Soon, EQUIPMENT_SETS_CHANGED = Soon,
    ITEM_LOCK_CHANGED = Locked, BAG_UPDATE_COOLDOWN = function() cells:Cooldowns() end, PLAYER_MONEY = Soon,
}

-- At a banker or away from one, from the login on: the full screen lays its windows out anew, with the bank
-- or without.
local function Banker(open)
    Contents.bankOpen = open
    ns.Window.Reboard()
end

function Bank.Start()
    Core.On("BANKFRAME_OPENED", function() Banker(true) end)
    Core.On("BANKFRAME_CLOSED", function() Banker(false) end)
    Contents.bankOpen = Foot.Talking("Banker")
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
local function Kept()
    local stored = ns.store
    if type(stored.bank) ~= "table" then stored.bank = {} end
    local bank = stored.bank
    if not Layout.LOOK[bank.look] or bank.look == "list" then bank.look = "grid" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == bank.order end
    if not known then bank.order = "default" end
    bank.group = bank.group == true or nil
    return bank
end

local function IsLook(key) return kept.look == key end
local function SetLook(key)
    kept.look = key
    Bank.Redraw()
end
local function IsOrder(key) return kept.order == key end
local function SetOrder(key)
    kept.order = key
    Bank.Redraw()
end
local function IsGrouped() return kept.group == true end
local function ToggleGroup()
    kept.group = not kept.group or nil
    Bank.Redraw()
end
local Looked = ns.Guard(IsLook)
local Look = ns.Guard(SetLook)
local Ordered = ns.Guard(IsOrder)
local Order = ns.Guard(SetOrder)
local Grouped = ns.Guard(IsGrouped)
local Group = ns.Guard(ToggleGroup)

local function Menu(_, root)
    root:CreateTitle(ns.TEXT.bagsLook)
    for _, look in ipairs(Layout.LOOKS) do
        if look.key ~= "list" then root:CreateRadio(look.word, Looked, Look, look.key) end
    end
    root:CreateCheckbox(ns.TEXT.bankGroup, Grouped, Group)
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsOrder)
    for _, order in ipairs(Contents.ORDERS) do root:CreateRadio(order.word, Ordered, Order, order.key) end
end

-- The bank shown now: the tab's, else the character's own.
local function Kind()
    local bag = tonumber(View():match("^tab:(%-?%d+)$") or "")
    for _, section in ipairs(sections) do
        for _, record in ipairs(section.slots) do
            if record.bag == bag then return section.bank end
        end
    end
    return Enum and Enum.BankType and Enum.BankType.Character
end

local function Clean()
    local api = rawget(_G, "C_Container")
    local kind = Kind()
    if not (api and api.SortBank and kind) or InCombatLockdown() then return end
    Core.Sound("UI_BAG_SORTING_01")
    api.SortBank(kind)
end

local function CleanTip(button)
    local word = Kind() == (Enum and Enum.BankType and Enum.BankType.Account) and "BAG_CLEANUP_ACCOUNT_BANK" or "BAG_CLEANUP_BANK"
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(Core.Word(word, "Clean Up Bank"), 1, 1, 1)
    GameTooltip:Show()
end

local function Deposit()
    if InCombatLockdown() or not Foot.Deposits() then return end
    C_Bank.AutoDepositItemsIntoBank(Enum.BankType.Character)
end

function Bank.Build(made)
    panel = made
    kept = Kept()
    local body = panel.body
    bar = CreateFrame("Frame", nil, body)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(Bags.BAR)
    Bags.Band(bar, "BOTTOM")
    bar.count = bar:CreateFontString(nil, "ARTWORK")
    local font = Bags.Fonts().count
    if font then bar.count:SetFontObject(font) end
    bar.count:SetTextColor(Bags.COUNT_COLOR[1], Bags.COUNT_COLOR[2], Bags.COUNT_COLOR[3])
    bar.count:SetPoint("LEFT", Bags.INSET + Bags.EDGE, 0)
    menu = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    menu:SetPoint("RIGHT", -Bags.EDGE, 0)
    menu:SetWidth(Bags.MENU_WIDTH)
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(Menu)
    sort = Bags.CleanButton(bar, Clean, CleanTip)
    sort:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    deposit = CreateFrame("Button", nil, bar)
    deposit:SetHeight(Foot.ACT)
    deposit:SetPoint("RIGHT", sort, "LEFT", -Bags.BAR_GAP, 0)
    local back = deposit:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.4)
    deposit.text = deposit:CreateFontString(nil, "ARTWORK")
    deposit.text:SetFontObject(Core.Font("SaneUIBagsAct", "GameFontHighlightSmall", 10) or "GameFontHighlightSmall")
    deposit.text:SetPoint("CENTER")
    deposit.text:SetText(Core.Word("REAGENTBANK_DEPOSIT", "Deposit All Reagents"))
    deposit.text:SetTextColor(Foot.ACT_COLOR[1], Foot.ACT_COLOR[2], Foot.ACT_COLOR[3])
    deposit:SetWidth(math.max(58, (deposit.text:GetStringWidth() or 0) + 14))
    deposit:SetScript("OnClick", function() ns.Safe("bank", Deposit) end)
    deposit:Hide()
    Bank.deposit = deposit
    foot = CreateFrame("Frame", nil, body)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetPoint("BOTTOMRIGHT")
    foot:SetHeight(Foot.HEIGHT)
    Bags.Band(foot, "TOP")
    gold = foot:CreateFontString(nil, "ARTWORK")
    if font then gold:SetFontObject(font) end
    gold:SetPoint("RIGHT", -(Bags.INSET + Bags.EDGE), 0)
    rail = ns.Sidebars.New(body, bar, foot, {
        store = kept, narrow = "narrow", word = ns.TEXT.bankTabsHead,
        choose = function(view) Bank.Choose(view) end,
        resized = function() Bank.Size(width) end,
    })
    side = rail.frame
    scroll = CreateFrame("ScrollFrame", nil, body, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -Bags.EDGE)
    scroll:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -Bags.SCROLL, Bags.EDGE)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    cells = Cells.New(child, Bank)
    canvas = ns.Canvas.New(child, { store = kept, redraw = function() Bank.Redraw() end, cells = cells })
    Bank.cells, Bank.rail = cells, rail
end

function Bank.Show(on)
    shown = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    if on then
        viewing = nil
        Bank.Refresh()
    else
        cells:HideAll()
    end
end

function Bank.Size(newWidth)
    width = newWidth or width
    if not child then return end
    child:SetWidth(math.max(1, width - rail:Width() - Bags.EDGE - Bags.SCROLL))
    Bank.Redraw()
end

function Bank.Search(text)
    query = Core.Fuzzy.Query(text)
    Bank.Redraw()
end

-- There only while the character is at a banker.
function Bank.Present()
    return Contents.bankOpen == true
end

local edge, head = Core.Board.EDGE, Core.Board.HEAD
ns.Board.Part("bank", Core.Word("BANK", "Bank"), { Bank.LEAST[1] + 2 * edge, Bank.LEAST[2] + head + 2 * edge }, Bank)
