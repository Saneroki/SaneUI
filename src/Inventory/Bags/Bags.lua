local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Bags
--  Our bags: a window on the module's full screen (Board.lua, the key
--  "bags") that shows and handles everything the character carries, and the
--  bank while it is open. The game's own bag windows stay as they are: our
--  code neither opens nor closes them, nor the bank's.
--
--      the bar      a dark band at the top: how many slots of the bags are
--                   taken of how many (every bag's in its tooltip); at the
--                   right what can be done at a vendor or a banker
--                   (Foot.lua), the junk marker (a click, then clicks on
--                   items mark them as junk or not: Select.lua; an item
--                   brought to it is marked at once), the bags themselves (a
--                   click shows or hides them in a strip under the bar), the
--                   clean-up of the game
--                   (C_Container.SortBags, as the game's bag window's button
--                   does), the dropdown View: the display (Layout.LOOKS),
--                   what sorts the items (Contents.ORDERS), what is shown
--      the sidebar  at the left: the views and the categories (Sidebar.lua)
--      the body     a scroll area with the view chosen as its blocks laid out
--                   (Views.lua, Layout.lua), each item the game's own item
--                   button (Cells.lua); the bank's parts follow the bags
--                   while it is open, each under a head with its own clean-up
--                   (C_Container.SortBank)
--      the foot     a dark band at the bottom: the currencies, the gold
--                   (Foot.lua)
--  The search box of the full window finds items by their name, their
--  category or their item level: the views of the bags as they are fade what
--  it does not find, the others leave it out.
--
--  An item: Alt and a right click opens its menu (Menus.lua); a middle click
--  pins it or unpins it (an item put into a category is taken out of it
--  instead). A category's head takes an item let go over it and opens the
--  category's menu at a right click. A category's "+" (and Pinned's) takes an
--  item brought to it; clicked with nothing, the next item clicked goes in.
--
--  The window opens with the view the player chose for that (All Items at
--  first); the view chosen in the sidebar holds while the window is open. It
--  listens to the game only while its panel is shown, and draws once a burst
--  of bag events is over (BAG_UPDATE_DELAYED, a frame later).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Bags = {}
ns.Bags = Bags

Bags.EDGE = 6        -- from the panel's sides to what is in it
Bags.INSET = 8       -- from the scroll area's left to the items
Bags.SCROLL = 20     -- room at the right for the game's scroll bar
Bags.BAR = 35        -- the dark band at the top
Bags.BAR_BUTTON = 24 -- a button on it
Bags.BAR_GAP = 6
Bags.MENU_WIDTH = 110
Bags.SHADE = { 0, 0, 0, 0.5 }        -- the bar's band
Bags.RULE = { 0.15, 0.15, 0.15, 1 }  -- the line under the bar, over the foot, by the sidebar
Bags.HEAD_COLOR = { 0.7, 0.7, 0.7 }  -- a category's head
Bags.MEMBER_COLOR = { 0.55, 0.55, 0.55 }
Bags.HEAD_LINE = { 0.7, 0.7, 0.7, 0.2 }
Bags.COUNT_COLOR = { 0.6, 0.6, 0.6 } -- the bar's count
Bags.LEAST = { 560, 320 }
-- The settings that show Pinned and Recent (store.bags).
Bags.SHOW = { pinned = "showPinned", recent = "showRecent" }

local Contents, Layout, Cells, Foot = ns.Contents, ns.Layout, ns.Cells, ns.Foot
local Categories, Views, Menus, Sidebar, Select = ns.Categories, ns.Views, ns.Menus, ns.BagSidebar, ns.Select

local panel, scroll, child, menu, sort, bar, strip, side, coin
local kept            -- store.bags: the display, the order, what is shown; the categories' choices
local query           -- what the search found by (Core.Fuzzy.Query), nil: nothing typed
local shown = false
local viewing         -- the view chosen in the sidebar while the window is open (nil: the first)
local width = 0       -- the panel's body width
local carried = { place = "bags", slots = {}, free = {} }
local sections = { carried }
local banked = {}     -- [kind] = a bank's section
local bankList = {}
local carriedBags = {}
local places = {}
local heads, rows, labels, pluses -- pools (Core.Pool)

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

-- The bags carried, read anew; their section (also for selling the junk: the bags may have changed since they
-- were drawn).
function Bags.Carried()
    Clear(carried)
    Contents.Sets()
    Contents.Scan(Contents.Carried(carriedBags), "bags", carried.slots, carried.free)
    return carried
end

local function Read()
    for index = #sections, 2, -1 do sections[index] = nil end
    Bags.Carried()
    for _, kind in ipairs(Contents.Banks(bankList)) do
        local section = Section(kind)
        Clear(section)
        Contents.Scan(kind.bags, kind.kind, section.slots, section.free)
        sections[#sections + 1] = section
    end
    carried.word = #sections > 1 and ns.TEXT.bags or nil
end

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
-- The view shown: the one chosen in the sidebar, else the one the window opens with; one whose category is
-- off or gone, or whose group is no more, gives way to All Items.
local function View()
    local view = viewing or kept.first or Views.ALL
    local key = view:match("^cat:(.+)$")
    if key and (not Categories.rank[key] or Categories.Off(key)) then return Views.ALL end
    if key and Bags.SHOW[key] and kept[Bags.SHOW[key]] == false then return Views.ALL end
    local group = view:match("^group:(.+)$")
    if group and #Categories.Members(group) < 2 then return Views.ALL end
    return view
end

function Bags.Viewing()
    return View()
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
    button:SetSize(Bags.BAR_BUTTON, Bags.BAR_BUTTON)
    button:SetNormalAtlas("bags-button-autosort-up")
    button:SetPushedAtlas("bags-button-autosort-down")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnClick", function(self) ns.Safe("bags", click, self) end)
    button:SetScript("OnEnter", function(self) ns.Safe("bags", enter, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end

-- The fonts of the window's words: a category's head, a group member's, a part's, the bar's count.
local fonts
local function Fonts()
    if fonts then return fonts end
    fonts = {
        head = Core.Font("SaneUIBagsHead", "GameFontHighlightSmall", 11),
        member = Core.Font("SaneUIBagsMember", "GameFontHighlightSmall", 10),
        part = Core.Font("SaneUIBagsPart", "GameFontHighlight", 13),
        count = Core.Font("SaneUIBagsBarCount", "GameFontHighlightSmall", 11),
    }
    return fonts
end
Bags.Fonts = Fonts

-- A category's head: a right click opens its menu, an item let go over it is put into it (Menus.lua); lit while
-- the mouse brings an item it takes.
local function HeadUp(head, mouse)
    if mouse == "RightButton" then
        Menus.Row(head, head.key, head.group)
    elseif mouse == "LeftButton" and GetCursorInfo() then
        Menus.Drop(head.key)
    end
end

local function HeadDrop(head)
    Menus.Drop(head.key)
end

local function HeadEnter(head)
    head.lit:SetShown(GetCursorInfo() == "item" and Menus.Takes(head.key))
    Menus.Tip(head, head.key, head.group)
end

local function HeadLeave(head)
    head.lit:Hide()
    GameTooltip:Hide()
end

-- A head over a part (the bags, a bank), a block (a category, a group) or a group's member: its words and
-- number at the left, a thin line from them to the right edge (a bank's clean-up at its end).
local function MakeHead()
    local head = CreateFrame("Frame", nil, child)
    head.lit = head:CreateTexture(nil, "BACKGROUND")
    head.lit:SetAllPoints()
    head.lit:SetColorTexture(1, 1, 1, 0.08)
    head.lit:Hide()
    head.word = head:CreateFontString(nil, "ARTWORK")
    head.word:SetPoint("LEFT")
    head.word:SetJustifyH("LEFT")
    head.number = head:CreateFontString(nil, "ARTWORK")
    head.number:SetPoint("LEFT", head.word, "RIGHT", 4, 0)
    head.clean = CleanButton(head, CleanBank, CleanBankTip)
    head.clean:SetScale(0.75)
    head.clean:SetPoint("RIGHT", -2, 0)
    head.line = head:CreateTexture(nil, "ARTWORK")
    head.line:SetPoint("LEFT", head.number, "RIGHT", 6, 0)
    head.line:SetPoint("RIGHT", -Layout.GAP, 0)
    head:SetScript("OnMouseUp", function(self, mouse) ns.Safe("bags", HeadUp, self, mouse) end)
    head:SetScript("OnReceiveDrag", function(self) ns.Safe("bags", HeadDrop, self) end)
    head:SetScript("OnEnter", function(self) ns.Safe("bags", HeadEnter, self) end)
    head:SetScript("OnLeave", function(self) ns.Safe("bags", HeadLeave, self) end)
    return head
end

local function DrawHead(place)
    local head = heads:Take()
    local block = place.block
    local font, line = Fonts(), Bags.HEAD_LINE
    head:ClearAllPoints()
    head:SetPoint("TOPLEFT", child, "TOPLEFT", place.x + Bags.INSET, -place.y)
    head:SetSize(place.width, place.height)
    local object = place.level == 1 and font.part or place.level == 3 and font.member or font.head
    if object then head.word:SetFontObject(object); head.number:SetFontObject(object) end
    head.word:SetText(block.word or "")
    local color = place.level == 3 and Bags.MEMBER_COLOR or Bags.HEAD_COLOR
    if place.level == 1 then head.word:SetTextColor(1, 1, 1) else head.word:SetTextColor(color[1], color[2], color[3]) end
    head.number:SetTextColor(color[1], color[2], color[3], 0.9)
    head.number:SetText(block.number and "(" .. tostring(block.number) .. ")" or "")
    head.line:SetColorTexture(line[1], line[2], line[3], place.level == 3 and line[4] / 2 or line[4])
    head.line:SetHeight(Core.Pixels(head, 1))
    local bank = place.level == 1 and block.section and block.section.bank
    Bags.headOf = Bags.headOf or {}
    Bags.headOf[head.clean] = bank
    head.clean:SetShown(bank ~= nil)
    head.line:SetPoint("RIGHT", bank ~= nil and head.clean or head, bank ~= nil and "LEFT" or "RIGHT", -Layout.GAP, 0)
    head.key, head.group = block.key, block.group
    head:EnableMouse(block.key ~= nil or block.group ~= nil)
    head.lit:Hide()
    head:Show()
end

-- A block's name over it in the compact display, cut short with its whole name in the tooltip.
local function LabelEnter(label)
    if not label.text:IsTruncated() then return end
    GameTooltip:SetOwner(label, "ANCHOR_TOP")
    GameTooltip:SetText(label.text:GetText() or "", 1, 1, 1)
    GameTooltip:Show()
end

local function MakeLabel()
    local label = CreateFrame("Frame", nil, child)
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

local function DrawLabel(place)
    local label = labels:Take()
    local block, color = place.block, Bags.HEAD_COLOR
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", child, "TOPLEFT", place.x + Bags.INSET, -place.y)
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
    Select.Start("put", plus.key)
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

local function MakePlus()
    local plus = CreateFrame("Button", nil, child)
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

local function DrawPlus(place)
    local plus = pluses:Take()
    plus:ClearAllPoints()
    plus:SetPoint("TOPLEFT", child, "TOPLEFT", place.x + Bags.INSET, -place.y)
    plus:SetSize(place.size, place.size)
    plus:SetFrameLevel(child:GetFrameLevel() + 3)
    plus.key = place.block.key
    plus:Show()
end

-- A list's line: behind its item button, which reaches over it; the item's name in its quality's colour, its
-- item level, its count.
local function MakeRow()
    local row = CreateFrame("Frame", nil, child)
    row.back = row:CreateTexture(nil, "BACKGROUND")
    row.back:SetAllPoints()
    row.back:SetColorTexture(1, 1, 1, 0.03)
    row.lit = row:CreateTexture(nil, "BORDER")
    row.lit:SetAllPoints()
    row.lit:SetColorTexture(1, 1, 1, 0.08)
    row.lit:Hide()
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", Layout.ICON + 8, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.count = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.count:SetPoint("RIGHT", -6, 0)
    row.count:SetWidth(40)
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
    row:SetPoint("TOPLEFT", child, "TOPLEFT", place.x + Bags.INSET, -place.y)
    row:SetSize(place.width, place.height)
    row:SetFrameLevel(child:GetFrameLevel() + 1)
    row.back:SetShown(rows.taken % 2 == 0)
    row.lit:Hide()
    local entry = place.entry
    local record = entry.record
    if record.item then
        local color = rawget(_G, "ITEM_QUALITY_COLORS") and ITEM_QUALITY_COLORS[record.quality]
        row.name:SetText(record.name or "")
        if color then row.name:SetTextColor(color.r, color.g, color.b) else row.name:SetTextColor(1, 1, 1) end
        row.level:SetText(record.level or "")
        local count = entry.count or record.count
        row.count:SetText(count and count > 1 and count or "")
    else
        row.name:SetText(Core.Word("EMPTY", "Empty"))
        row.name:SetTextColor(0.4, 0.4, 0.4)
        row.level:SetText("")
        row.count:SetText("")
    end
    row.level:SetTextColor(0.85, 0.85, 0.85)
    row.count:SetTextColor(0.85, 0.85, 0.85)
    row:SetAlpha(entry.faded and Cells.FADED or 1)
    rowOf[button] = row
    row:Show()
end

-- The mouse on a list's item button: its line lit.
function Bags.Hover(button, on)
    local row = rowOf[button]
    if row and row:IsShown() then row.lit:SetShown(on) end
end

-- A click on an item button, after the game's own: Alt and the right button (which the game's button does
-- nothing with) open the item's menu; the middle one pins it, unpins it, or takes it out of the category it
-- was put into.
function Bags.Clicked(button, mouse)
    local alt = rawget(_G, "IsAltKeyDown")
    if mouse == "RightButton" and alt and alt() then return Menus.Item(button) end
    if mouse ~= "MiddleButton" then return end
    local record = Cells.Record(button)
    if not (record and record.item) then return end
    local assigned = Categories.Assigned(record.item)
    if assigned and assigned ~= Categories.JUNK then
        Categories.Assign(record.item, nil)
    else
        Categories.Pin(record.item, not Categories.Pinned(record.item))
    end
    Bags.Refresh()
end

local how = {} -- how a cell is drawn (Cells.Draw), used again

local function Draw()
    if not child then return end
    local room = child:GetWidth()
    if not room or room <= 0 then return end
    local blocks = Views.Build(View(), sections, query, kept.order, kept)
    Bags.blocks = blocks
    local count, height = Layout.Lay(kept.look, blocks, room - Bags.INSET, places)
    heads:Begin()
    rows:Begin()
    labels:Begin()
    pluses:Begin()
    Cells.Begin()
    for button in pairs(rowOf) do rowOf[button] = nil end
    local x = Bags.INSET
    how.bind, how.coin, how.grey, how.set = kept.bind == true, kept.coin == true, kept.grey == true, kept.setName == true
    for index = 1, count do
        local place = places[index]
        if place.kind == "head" then
            DrawHead(place)
        elseif place.kind == "label" then
            DrawLabel(place)
        elseif place.kind == "pad" then
            Cells.Pad(place.x + x, place.y, place.size)
        elseif place.kind == "plus" then
            DrawPlus(place)
        else
            local entry = place.entry
            local button = Cells.Take()
            if button then
                how.faded, how.count = entry.faded, entry.count
                Cells.Draw(button, entry.record, how)
                if place.kind == "row" then
                    -- The button at the line's left, in its middle; its click over the rest of the line.
                    local inset = (place.height - place.size) / 2
                    Cells.Place(button, place.x + x + inset, place.y + inset, place.size, place.width - inset)
                    DrawRow(place, button)
                else
                    Cells.Place(button, place.x + x, place.y, place.size)
                end
            end
        end
    end
    Cells.Done()
    heads:Done()
    rows:Done()
    labels:Done()
    pluses:Done()
    child:SetHeight(math.max(1, height + Bags.INSET))
    Bags.Count()
    coin:SetShown(Categories.Marker())
    Sidebar.Refresh(Views.Counts(carried), View())
    if Cells.short then Core.AfterCombat("inventory: bags", Bags.Refresh) end
end

-- Everything read anew and drawn.
function Bags.Refresh()
    if not shown then return end
    ns.Safe("bags", Read)
    ns.Safe("bags", Draw)
    ns.Safe("bags", Foot.Refresh, carried)
end

-- Drawn anew as it was read (the view, the display, the order, the search or the width changed).
function Bags.Redraw()
    if shown then ns.Safe("bags", Draw) end
end

-- A view chosen in the sidebar (nil: the one the window opens with); the items from the top.
function Bags.Choose(view)
    viewing = view
    if scroll then scroll:SetVerticalScroll(0) end
    Bags.Redraw()
end

-- One of the window's settings changed (store.bags), the window drawn anew.
function Bags.SetOption(key, value)
    kept[key] = value
    Categories.Use(kept)
    Bags.Refresh()
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
    MAIL_SHOW = Soon, MAIL_CLOSED = Soon, TRADE_SHOW = Soon, TRADE_CLOSED = Soon,
    AUCTION_HOUSE_SHOW = Soon, AUCTION_HOUSE_CLOSED = Soon, EQUIPMENT_SETS_CHANGED = Soon,
    PLAYERBANKSLOTS_CHANGED = Soon, BANK_TABS_CHANGED = Soon, PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = Soon,
    BANKFRAME_OPENED = function() Banker(true) end, BANKFRAME_CLOSED = function() Banker(false) end,
    ITEM_LOCK_CHANGED = Locked, GET_ITEM_INFO_RECEIVED = Arrived,
    PLAYER_LEVEL_UP = function() Contents.Leveled(); Soon() end,
    BAG_UPDATE_COOLDOWN = function() Cells.Cooldowns() end,
    PLAYER_MONEY = function() Foot.Gold() end, CURRENCY_DISPLAY_UPDATE = function() Foot.Tokens() end,
}
local UNIT_EVENTS = { UNIT_QUEST_LOG_CHANGED = Soon }

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- What is kept of the window: its display and order, each one of those there are; the categories' choices
-- (Categories.lua checks them).
local function Kept()
    local store = ns.store
    if type(store.bags) ~= "table" then store.bags = {} end
    local bags = store.bags
    if not Layout.LOOK[bags.look] then bags.look = "grid" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == bags.order end
    if not known then bags.order = "default" end
    local first = false
    for _, view in ipairs(Views.FIXED) do first = first or view.key == bags.first end
    if not first then bags.first = nil end
    Categories.Use(bags)
    Bags.options = bags
    return bags
end

local function IsLook(key) return kept.look == key end
local function SetLook(key)
    kept.look = key
    Bags.Redraw()
end
local function IsOrder(key) return kept.order == key end
local function SetOrder(key)
    kept.order = key
    Bags.Redraw()
end
local function IsOn(key) return kept[key] ~= false end
local function Toggle(key)
    kept[key] = not IsOn(key)
    Bags.Refresh()
end
local function IsFirst(key) return (kept.first or Views.ALL) == key end
local function SetFirst(key)
    kept.first = key ~= Views.ALL and key or nil
    Bags.Redraw()
end
local function SwitchOn(key)
    Categories.SwitchOff(key, false)
    Bags.Refresh()
end
local Looked = ns.Guard(IsLook)
local Look = ns.Guard(SetLook)
local Ordered = ns.Guard(IsOrder)
local Order = ns.Guard(SetOrder)
local On = ns.Guard(IsOn)
local Switch = ns.Guard(Toggle)
local Firsted = ns.Guard(IsFirst)
local First = ns.Guard(SetFirst)
local Unoff = ns.Guard(SwitchOn)

local function Menu(_, root)
    root:CreateTitle(ns.TEXT.bagsLook)
    for _, look in ipairs(Layout.LOOKS) do root:CreateRadio(look.word, Looked, Look, look.key) end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsOrder)
    for _, order in ipairs(Contents.ORDERS) do root:CreateRadio(order.word, Ordered, Order, order.key) end
    root:CreateDivider()
    root:CreateCheckbox(ns.TEXT.bagsShowPinned, On, Switch, Bags.SHOW.pinned)
    root:CreateCheckbox(ns.TEXT.bagsShowRecent, On, Switch, Bags.SHOW.recent)
    root:CreateCheckbox(ns.TEXT.bagsHideEmpty, On, Switch, "hideEmpty")
    root:CreateCheckbox(ns.TEXT.bagsMerge, On, Switch, "merge")
    local first = root:CreateButton(ns.TEXT.bagsFirst)
    for _, view in ipairs(Views.FIXED) do first:CreateRadio(view.word, Firsted, First, view.key) end
    local off = {}
    for _, key in ipairs(Categories.order) do
        if Categories.Off(key) then off[#off + 1] = key end
    end
    if #off > 0 then
        local list = root:CreateButton(ns.TEXT.bagsOn)
        for _, key in ipairs(off) do list:CreateButton(ns.TEXT.bagsSwitchOn:format(Categories.Word(key)), Unoff, key) end
    end
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

-- The bar's count: in the views of every item, how many slots of the ordinary bags hold something, of how many;
-- in a category's or group's view, how many cells it shows.
function Bags.Count()
    if not bar then return end
    local view = View()
    if view == Views.ALL or view == Views.ONE or view == Views.EACH then
        local free = carried.free
        bar.count:SetText(ns.TEXT.bagsItems:format((free.total or 0) - (free.count or 0), free.total or 0))
    else
        local cells = 0
        local blocks = Bags.blocks
        for index = 1, blocks and blocks.count or 0 do cells = cells + #blocks[index].entries end
        bar.count:SetText(ns.TEXT.bagsCells:format(cells))
    end
end

-- A dark band with a thin line at one edge (the bar's at its foot, the foot's at its top).
local function Band(frame, edge)
    local back = frame:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(Bags.SHADE[1], Bags.SHADE[2], Bags.SHADE[3], Bags.SHADE[4])
    local line = frame:CreateTexture(nil, "BORDER")
    line:SetColorTexture(Bags.RULE[1], Bags.RULE[2], Bags.RULE[3], Bags.RULE[4])
    line:SetPoint(edge .. "LEFT")
    line:SetPoint(edge .. "RIGHT")
    line:SetHeight(Core.Pixels(frame, 1))
    return back, line
end
Bags.Band = Band

-- The strip of the bags themselves under the bar, shown or hidden (kept); the sidebar and the scroll area under
-- what shows.
local function Strip()
    local on = kept.strip == true
    strip:SetShown(on)
    local above = on and strip or bar
    side:ClearAllPoints()
    side:SetPoint("TOPLEFT", above, "BOTTOMLEFT")
    side:SetPoint("BOTTOMLEFT", Foot.frame, "TOPLEFT")
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -Bags.EDGE)
    scroll:SetPoint("BOTTOMRIGHT", Foot.frame, "TOPRIGHT", -Bags.SCROLL, Bags.EDGE)
    bar.bags:SetChecked(on)
end

local function ToggleStrip()
    kept.strip = not kept.strip
    Core.Sound(kept.strip and "IG_BACKPACK_OPEN" or "IG_BACKPACK_CLOSE")
    Strip()
end

local function BagsTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(ns.TEXT.bagsShow, 1, 1, 1)
    GameTooltip:Show()
end

-- The junk marker: an item brought to it is marked as junk (or unmarked) at once; else the mode where clicks
-- mark items begins, or ends.
local function CoinClick()
    local kind, id = Core.Ask(rawget(_G, "GetCursorInfo"))
    id = Core.Plain(id)
    if kind == "item" and type(id) == "number" then
        local record
        for _, slot in ipairs(carried.slots) do
            if slot.item == id then record = slot break end
        end
        Categories.MarkJunk(id, not Categories.Junk(id, record and record.quality), record and record.quality)
        ClearCursor()
        return Bags.Refresh()
    end
    if Select.Mode() == "junk" then return Select.Stop() end
    Select.Start("junk")
end

local function CoinTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(ns.TEXT.bagsMarker, 1, 1, 1)
    GameTooltip:AddLine(ns.TEXT.bagsMarkerTip, 1, 0.82, 0, true)
    GameTooltip:Show()
end

-- The junk marker's mode on or off (Select.lua): its button checked while on.
function Bags.Marked(on)
    if coin then coin:SetChecked(on) end
end

local function Bar(body)
    bar = CreateFrame("Frame", nil, body)
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(Bags.BAR)
    Band(bar, "BOTTOM")
    bar.count = bar:CreateFontString(nil, "ARTWORK")
    local font = Fonts()
    if font.count then bar.count:SetFontObject(font.count) end
    bar.count:SetTextColor(Bags.COUNT_COLOR[1], Bags.COUNT_COLOR[2], Bags.COUNT_COLOR[3])
    bar.count:SetPoint("LEFT", Bags.INSET + Bags.EDGE, 0)
    local hover = CreateFrame("Frame", nil, bar)
    hover:SetAllPoints(bar.count)
    hover:SetScript("OnEnter", function(self) ns.Safe("bags", Foot.FreeTip, self) end)
    hover:SetScript("OnLeave", GameTooltip_Hide)
    menu = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    menu:SetPoint("RIGHT", -Bags.EDGE, 0)
    menu:SetWidth(Bags.MENU_WIDTH)
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(Menu)
    sort = CleanButton(bar, Clean, CleanTip)
    sort:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    local bags = CreateFrame("CheckButton", nil, bar)
    bags:SetSize(Bags.BAR_BUTTON, Bags.BAR_BUTTON)
    bags:SetNormalAtlas("bag-main")
    bags:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    bags:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
    local checked = bags:GetCheckedTexture()
    if checked then checked:SetBlendMode("ADD") end
    bags:SetPoint("RIGHT", sort, "LEFT", -Bags.BAR_GAP, 0)
    bags:SetScript("OnClick", function() ns.Safe("bags", ToggleStrip) end)
    bags:SetScript("OnEnter", function(self) ns.Safe("bags", BagsTip, self) end)
    bags:SetScript("OnLeave", GameTooltip_Hide)
    bar.bags = bags
    coin = CreateFrame("CheckButton", nil, bar)
    coin:SetSize(Bags.BAR_BUTTON - 2, Bags.BAR_BUTTON - 2)
    local icon = coin:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    icon:SetSize(Bags.BAR_BUTTON, Bags.BAR_BUTTON)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if coin.CreateMaskTexture then
        local round = coin:CreateMaskTexture()
        round:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        round:SetAllPoints(icon)
        icon:AddMaskTexture(round)
    end
    coin:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    coin:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
    local lit = coin:GetCheckedTexture()
    if lit then lit:SetBlendMode("ADD") end
    coin:SetPoint("RIGHT", bags, "LEFT", -Bags.BAR_GAP, 0)
    coin:SetScript("OnClick", function() ns.Safe("bags", CoinClick) end)
    coin:SetScript("OnReceiveDrag", function() ns.Safe("bags", CoinClick) end)
    coin:SetScript("OnEnter", function(self) ns.Safe("bags", CoinTip, self) end)
    coin:SetScript("OnLeave", GameTooltip_Hide)
    bar.coin = coin
    Bags.bar = bar
    strip = CreateFrame("Frame", nil, body)
    strip:SetPoint("TOPLEFT", bar, "BOTTOMLEFT")
    strip:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT")
    strip:SetHeight(Foot.STRIP)
    Bags.strip = strip
end

function Bags.Build(made)
    panel = made
    kept = Kept()
    local body = panel.body
    Bar(body)
    Foot.Build(body, coin, strip)
    side = Sidebar.Build(body, bar, Foot.frame, kept)
    scroll = CreateFrame("ScrollFrame", nil, body, "ScrollFrameTemplate")
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    Cells.Build(child)
    heads = Core.Pool(MakeHead)
    rows = Core.Pool(MakeRow)
    labels = Core.Pool(MakeLabel)
    pluses = Core.Pool(MakePlus)
    Bags.scroll = scroll
    Select.Build(scroll, { bar, strip, side, Foot.frame })
    Strip()
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
        viewing = nil
        Contents.bankOpen = Foot.Talking("Banker")
        Bags.Refresh()
    else
        for item in pairs(Views.split) do Views.split[item] = nil end
        Cells.Light(nil)
        Select.Stop()
    end
end

-- The panel's new size: the scroll area's child as wide as the area, laid out anew.
function Bags.Size(newWidth)
    width = newWidth or width
    if not child then return end
    child:SetWidth(math.max(1, width - Sidebar.Width() - Bags.EDGE - Bags.SCROLL))
    Bags.Redraw()
end

-- The sidebar folded or unfolded: the items laid out in the room left.
function Bags.Resized()
    Bags.Size(width)
end

function Bags.Search(text)
    query = Core.Fuzzy.Query(text)
    Bags.Redraw()
end

-- The board's least: the sidebar and some item buttons in a line, the foot, the panel's head and edges.
local edge, head = Core.Board.EDGE, Core.Board.HEAD
ns.Board.Part("bags", ns.TEXT.bags, { Bags.LEAST[1] + 2 * edge, Bags.LEAST[2] + head + 2 * edge }, Bags)
