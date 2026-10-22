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
--                   SortBank), the dropdown View: the display (as the bags':
--                   grid, list, compact), Group by Category, the order
--      the sidebar  All Bank Tabs (each tab under its head, every slot), One
--                   Bank (each bank's slots together), then each tab by its
--                   name and icon with how many of its slots are taken (its
--                   tooltip what it takes; a right click its settings: its
--                   name, what it takes, whether the clean-up leaves it be,
--                   by the game's C_Bank.UpdateBankTabSettings where the
--                   client has it), and Buy Tab where the game sells one:
--                   over that row lies, unseen, the game's own button for
--                   buying a tab (BankPanelPurchaseButtonScriptTemplate), so
--                   a click on it is the game's: its question, its purchase;
--                   our code never buys
--      the body     the slots as the view says (with Group by Category: the
--                   items by the bags' categories instead), each the game's
--                   own item button (Cells.lua, a pool of its own): click,
--                   drag, right click into the bags, the tooltip, all the
--                   game's; in the list a line per item under the bags'
--                   column head (Columns.lua: one of its own, the bags'
--                   columns)
--      the foot     the character's gold
--  An item: Alt and a right click its menu, a middle click pins it, Shift and
--  a click the splitter (with Stack Splitter Everywhere), as in the bags. The
--  search box of the full window fades what it does not find (with Group by
--  Category: leaves it out). The window opens with All Bank Tabs; the view
--  chosen holds while it is open. Kept in store.bank: look, order, group,
--  folded (the list's columns are the bags', store.bags).
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
local canvas, cells, rail, columns
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

-------------------------------------------------------------------------------
--  A tab's settings, buying a tab
-------------------------------------------------------------------------------
Bank.LETTERS = 16 -- the most a tab's name may have (the game's own box)
local FLAGS = Enum and Enum.BagSlotFlags or {}
-- What a tab may take, in the game's order and words; and the game's switch that keeps the clean-up out of it.
Bank.TAKES = {
    { flag = FLAGS.ClassEquipment or 2, word = Core.Word("BAG_FILTER_EQUIPMENT", "Equipment") },
    { flag = FLAGS.ClassConsumables or 4, word = Core.Word("BAG_FILTER_CONSUMABLES", "Consumables") },
    { flag = FLAGS.ClassProfessionGoods or 8, word = Core.Word("BAG_FILTER_PROFESSION_GOODS", "Profession Goods") },
    { flag = FLAGS.ClassReagents or 128, word = Core.Word("BAG_FILTER_REAGENTS", "Reagents") },
    { flag = FLAGS.ClassJunk or 16, word = Core.Word("BAG_FILTER_JUNK", "Junk") },
}
Bank.UNSORTED = FLAGS.DisableAutoSort or 1

-- Whether a flag is set in a tab's flags; the flags with it set or not (each flag a power of two).
local function Has(flags, flag)
    return flags % (flag * 2) >= flag
end
local function With(flags, flag, on)
    if Has(flags, flag) == on then return flags end
    return on and flags + flag or flags - flag
end
Bank.Has, Bank.With = Has, With

local function Banks()
    return rawget(_G, "C_Bank") or {}
end

-- A tab as the game keeps it (C_Bank.FetchPurchasedBankTabData): { ID, name, icon, depositFlags }; nil: not known.
local function TabData(kind, tab)
    local api = Banks()
    if not (kind and api.FetchPurchasedBankTabData) then return nil end
    for _, data in ipairs(Core.Ask(api.FetchPurchasedBankTabData, kind) or {}) do
        if type(data) == "table" and Core.Plain(data.ID) == tab then return data end
    end
end
Bank.TabData = TabData

-- Whether a tab's settings can be changed here (the client has the game's call).
local function Settable()
    return Banks().UpdateBankTabSettings ~= nil
end

-- A tab's settings set by the game's own call: a new name (nil: as it is), new flags (nil: as they are); its icon
-- stays.
local function Settle(kind, tab, name, flags)
    local data = TabData(kind, tab)
    if not (data and Settable()) then return end
    local icon = Core.Plain(data.icon) or rawget(_G, "QUESTION_MARK_ICON") or Categories.OWN_ICON
    Banks().UpdateBankTabSettings(kind, tab, name or Core.Plain(data.name) or "", icon,
        flags or Core.Plain(data.depositFlags) or 0)
end

local about = {} -- the tab the open menu is about: kind, tab, name

local function IsTaken(flag)
    local data = TabData(about.kind, about.tab)
    return data ~= nil and Has(Core.Plain(data.depositFlags) or 0, flag)
end
local function Take(flag)
    local data = TabData(about.kind, about.tab)
    if not data then return end
    local flags = Core.Plain(data.depositFlags) or 0
    Settle(about.kind, about.tab, nil, With(flags, flag, not Has(flags, flag)))
end
local function RenameTab()
    local kind, tab, name = about.kind, about.tab, about.name
    Core.AskText(ns.TEXT.bankRenameAsk, name, Core.Word("ACCEPT", "Accept"), name, function(text)
        text = type(text) == "string" and text:match("^%s*(.-)%s*$"):sub(1, Bank.LETTERS):match("^(.-)%s*$") or ""
        if text ~= "" then Settle(kind, tab, text) end
    end, Bank.LETTERS)
end
local Taken = ns.Guard(IsTaken)
local Took = ns.Guard(Take)
local Renamed = ns.Guard(RenameTab)

local function FillTab(_, root)
    root:CreateTitle(about.name)
    root:CreateButton(ns.TEXT.bagsRename, Renamed)
    root:CreateDivider()
    root:CreateTitle(Core.Word("BAG_FILTER_ASSIGN_TO", "Assign To:"))
    for _, take in ipairs(Bank.TAKES) do root:CreateCheckbox(take.word, Taken, Took, take.flag) end
    root:CreateDivider()
    root:CreateCheckbox(Core.Word("BANK_TAB_IGNORE_IN_CLEANUP_CHECKBOX", "Ignore in Clean Up"), Taken, Took, Bank.UNSORTED)
end
local TabMenu = ns.Guard(FillTab)

-- A tab's row clicked with the right button: its settings, where the client can change them.
local function RowMenu(row)
    if not (row.tab and Settable() and TabData(row.bank, row.tab) and rawget(_G, "MenuUtil")) then return end
    about.kind, about.tab, about.name = row.bank, row.tab, row.word
    MenuUtil.CreateContextMenu(row, TabMenu)
end

-- What a tab takes, in the game's words (nil: anything).
local takes = {}
local function Takes(flags)
    for index = #takes, 1, -1 do takes[index] = nil end
    for _, take in ipairs(Bank.TAKES) do
        if Has(flags, take.flag) then takes[#takes + 1] = take.word end
    end
    return #takes > 0 and table.concat(takes, ", ") or nil
end
Bank.Takes = Takes

-- Whether a bank sells another tab now; what it costs and whether the character can pay it.
local function Buyable(kind)
    local api = Banks()
    if not (kind and api.CanPurchaseBankTab) or Core.Ask(api.CanPurchaseBankTab, kind) ~= true then return false end
    return not (api.HasMaxBankTabs and Core.Ask(api.HasMaxBankTabs, kind) == true)
end
local function Cost(kind)
    local api = Banks()
    local data = api.FetchNextPurchasableBankTabData and Core.Ask(api.FetchNextPurchasableBankTabData, kind)
    if type(data) ~= "table" then return nil end
    return Core.Plain(data.tabCost), Core.Plain(data.canAfford) ~= false
end

-- A tab's tooltip (what it takes, its settings by a right click), Buy Tab's (its cost).
local function Tip(row)
    local tip = GameTooltip
    if row.tab then
        local data = TabData(row.bank, row.tab)
        tip:SetOwner(row, "ANCHOR_RIGHT")
        tip:SetText(row.word or "", 1, 1, 1)
        local list = data and Takes(Core.Plain(data.depositFlags) or 0)
        if list then tip:AddLine(Core.Word("BANK_TAB_DEPOSIT_ASSIGNMENTS", "Assigned To: %s"):format(list), 1, 0.82, 0, true) end
        if data and Settable() then Menus.Hint(tip, ns.TEXT.bankTabTip) end
        tip:Show()
        return true
    end
    if row.buy then
        local cost, afford = Cost(row.buy)
        tip:SetOwner(row, "ANCHOR_RIGHT")
        tip:SetText(row.word or "", 1, 1, 1)
        if cost then
            local red = not afford
            tip:AddLine(Core.Word("COSTS_LABEL", "Cost:") .. " " .. (Core.Coins(cost) or tostring(cost)), 1, red and 0.1 or 1, red and 0.1 or 1)
        end
        Menus.Hint(tip, ns.TEXT.bankBuyTip)
        tip:Show()
        return true
    end
end

-- The game's own button for buying a tab of a bank (its template's click opens the game's question; the purchase is
-- the game's), made once per bank, laid unseen over our row; false where the client has no such template.
local buyers, buyerRow = {}, {}
local function BuyEnter(button)
    local row = buyerRow[button]
    if row then
        row.hover:Show()
        Tip(row)
    end
end
local function BuyLeave(button)
    local row = buyerRow[button]
    if row then row.hover:Hide() end
    GameTooltip:Hide()
end
local BoughtEnter = ns.Guard(BuyEnter)
local BoughtLeave = ns.Guard(BuyLeave)

local function Buyer(kind)
    if buyers[kind] == nil then
        local made, button = pcall(CreateFrame, "Button", nil, rail.child, "BankPanelPurchaseButtonScriptTemplate")
        buyers[kind] = made and button or false
        if made then
            button:SetAttribute("overrideBankType", kind)
            button:SetScript("OnEnter", BoughtEnter)
            button:SetScript("OnLeave", BoughtLeave)
        end
    end
    return buyers[kind] or nil
end

-- Each bank's buyer over its Buy Tab row (rows: [kind] = row), or hidden.
local function Lay(rows)
    for _, kind in ipairs(Contents.BANKS) do
        local row, button = kind.type and rows[kind.type], kind.type and buyers[kind.type]
        if row then button = Buyer(kind.type) end
        if button then
            buyerRow[button] = row
            button:ClearAllPoints()
            if row then
                button:SetAllPoints(row)
                button:SetFrameLevel(row:GetFrameLevel() + 2)
            end
            button:SetShown(row ~= nil)
        end
    end
end

-------------------------------------------------------------------------------
--  The sidebar
-------------------------------------------------------------------------------
local buyRows = {} -- [bank type] = its Buy Tab row now

-- A bank's Buy Tab row, where the game sells another tab and the client has its button for that.
local function BuyRow(kind)
    if not (kind and Buyable(kind)) or Buyer(kind) == nil then return end
    local row = rail:Row(ns.TEXT.bankBuy, nil, "Interface\\Buttons\\UI-PlusButton-Up", nil, 0, false)
    row.buy, row.tab, row.bank = kind, nil, nil -- a row used again: no tab of what it showed before
    row.label:SetAlpha(0.6)
    buyRows[kind] = row
end

local function Sidebar()
    local view = View()
    for kind in pairs(buyRows) do buyRows[kind] = nil end
    rail:Begin()
    rail:Row(ns.TEXT.bankTabs, nil, Bank.ICON, nil, 0, view == Bank.TABS).view = Bank.TABS
    rail:Row(ns.TEXT.bankOne, nil, "Interface\\Icons\\INV_Misc_Bag_08", nil, 0, view == Bank.ONE).view = Bank.ONE
    local character = Enum and Enum.BankType and Enum.BankType.Character
    local own = false
    for _, section in ipairs(sections) do
        rail:Divider()
        own = own or section.bank == character
        -- The section's tabs in their order, and each one's slots taken: two tables, as tab IDs are small numbers
        -- that a list's places would meet.
        local tabs, taken = {}, {}
        for _, record in ipairs(section.slots) do
            local tab = record.bag
            if not taken[tab] then
                taken[tab] = 0
                tabs[#tabs + 1] = tab
            end
            if record.item then taken[tab] = taken[tab] + 1 end
        end
        for _, tab in ipairs(tabs) do
            local data = TabData(section.bank, tab)
            local icon = data and Core.Plain(data.icon) or Bank.ICON
            local row = rail:Row(Contents.BagWord(tab, section.place), taken[tab], icon, nil, 0, view == "tab:" .. tab)
            row.view, row.tab, row.bank, row.buy = "tab:" .. tab, tab, section.bank, nil
        end
        BuyRow(section.bank)
    end
    if not own and Buyable(character) then
        rail:Divider()
        BuyRow(character)
    end
    rail:Done()
    Lay(buyRows)
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

-- The character's gold at the foot.
local function Gold()
    if gold then gold:SetText(Core.Coins(Core.Plain(Core.Ask(GetMoney)) or 0) or "") end
end

function Bank.Refresh()
    if not shown then return end
    ns.Safe("bank", Read)
    ns.Safe("bank", Draw)
    Gold()
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
    if mouse == "LeftButton" and Options().splitter and ns.Split.Replace(button, record) then return end
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

-- An item's data came from the server: drawn anew only if one of ours waited for it (Contents.waiting), not for
-- every item another window asked about.
local function Arrived(item)
    item = Core.Plain(item)
    if item and Contents.waiting[item] then Soon() end
end

local EVENTS = {
    BAG_UPDATE_DELAYED = Soon, PLAYERBANKSLOTS_CHANGED = Soon, BANK_TABS_CHANGED = Soon, BANK_TAB_SETTINGS_UPDATED = Soon,
    PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = Soon, GET_ITEM_INFO_RECEIVED = Arrived, EQUIPMENT_SETS_CHANGED = Soon,
    ITEM_LOCK_CHANGED = Locked, BAG_UPDATE_COOLDOWN = function() cells:Cooldowns() end, PLAYER_MONEY = Gold,
}

-- At a banker or away from one, from the login on: the full screen lays its windows out anew, with the bank
-- or without.
local function Banker(open)
    Contents.bankOpen = open
    ns.Window.Reboard()
end

-- The game's kinds of banker: its bank opens for each (one this client lacks is not asked).
Bank.BANKERS = { "Banker", "CharacterBanker", "AccountBanker" }

function Bank.Start()
    Core.On("BANKFRAME_OPENED", function() Banker(true) end)
    Core.On("BANKFRAME_CLOSED", function() Banker(false) end)
    local open = false
    for _, kind in ipairs(Bank.BANKERS) do open = open or Foot.Talking(kind) end
    Contents.bankOpen = open
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
local function Kept()
    local stored = ns.store
    if type(stored.bank) ~= "table" then stored.bank = {} end
    local bank = stored.bank
    if not Layout.LOOK[bank.look] then bank.look = "grid" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == bank.order end
    if not known then bank.order = "default" end
    bank.group = bank.group == true or nil
    return bank
end

-- The list's head over the scroll area while the list is shown, the scroll area under it.
local function Place()
    local list = kept.look == "list"
    columns:ClearAllPoints()
    columns:SetPoint("TOPLEFT", side, "TOPRIGHT", Bags.INSET, -Bags.EDGE)
    columns:SetPoint("RIGHT", bar, "RIGHT", -(Bags.SCROLL + Bags.INSET), 0)
    columns:SetShown(list)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -(Bags.EDGE + (list and Columns.HEAD + 2 or 0)))
    scroll:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -Bags.SCROLL, Bags.EDGE)
    if list then columns:Refresh(math.max(1, (child:GetWidth() or 0) - Bags.INSET)) end
end

local function IsLook(key) return kept.look == key end
local function SetLook(key)
    kept.look = key
    Place()
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
    for _, look in ipairs(Layout.LOOKS) do root:CreateRadio(look.word, Looked, Look, look.key) end
    root:CreateCheckbox(ns.TEXT.bankGroup, Grouped, Group)
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsOrder)
    for _, order in ipairs(Contents.ORDERS) do root:CreateRadio(order.word, Ordered, Order, order.key) end
end
local ViewMenu = ns.Guard(Menu)

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
    bar.count:SetTextColor(Bags.COUNT_COLOR[1], Bags.COUNT_COLOR[2], Bags.COUNT_COLOR[3], Bags.COUNT_COLOR[4])
    bar.count:SetPoint("LEFT", Bags.INSET + Bags.EDGE, 0)
    menu = ns.Paper.Dropdown(bar, Bags.MENU_WIDTH, Bags.BAR_BUTTON)
    menu:SetPoint("RIGHT", -Bags.EDGE, 0)
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(ViewMenu)
    sort = Bags.CleanButton(bar, Clean, CleanTip)
    sort:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    deposit = CreateFrame("Button", nil, bar)
    deposit:SetHeight(Foot.ACT)
    deposit:SetPoint("RIGHT", sort, "LEFT", -Bags.BAR_GAP, 0)
    deposit.text = deposit:CreateFontString(nil, "ARTWORK")
    ns.Paper.Leather(deposit, deposit.text, Foot.ACT)
    deposit.text:SetPoint("CENTER")
    deposit.text:SetText(Core.Word("REAGENTBANK_DEPOSIT", "Deposit All Reagents"))
    deposit.text:SetTextColor(Foot.ACT_COLOR[1], Foot.ACT_COLOR[2], Foot.ACT_COLOR[3])
    deposit:SetWidth(math.max(58, (deposit.text:GetStringWidth() or 0) + 24))
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
        word = ns.TEXT.bankTabsHead,
        choose = function(view) Bank.Choose(view) end,
        menu = RowMenu,
        tip = Tip,
    })
    side = rail.frame
    columns = Columns.Build(body, function() Bank.Redraw() end)
    scroll = CreateFrame("ScrollFrame", nil, body, "ScrollFrameTemplate")
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    cells = Cells.New(child, Bank)
    canvas = ns.Canvas.New(child, { store = kept, redraw = function() Bank.Redraw() end, cells = cells })
    Bank.cells, Bank.rail, Bank.columns = cells, rail, columns
    Place()
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
        -- Each on its own: the splitter stops even if the buttons could not be hidden.
        ns.Safe("bank", cells.HideAll, cells)
        ns.Safe("bank", ns.Split.Stop)
    end
end

function Bank.Size(newWidth, newHeight)
    if newWidth then width = ns.Board.Body("bank", newWidth, newHeight or 0) end
    if not child then return end
    child:SetWidth(math.max(1, width - rail:Width() - Bags.EDGE - Bags.SCROLL))
    if kept.look == "list" then columns:Refresh(math.max(1, child:GetWidth() - Bags.INSET)) end
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

ns.Board.Part("bank", Core.Word("BANK", "Bank"), ns.Board.Least("bank", Bank.LEAST[1], Bank.LEAST[2]), Bank)
