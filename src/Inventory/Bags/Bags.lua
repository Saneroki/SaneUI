local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Bags
--  Our bags: a window on the module's full screen (Board.lua, the key
--  "bags") that shows and handles everything the character carries. The
--  game's own bag windows stay as they are: our code neither opens nor closes
--  them.
--
--      the bar      on the window's title line, after its title: how many slots of the bags are
--                   taken of how many (every bag's in its tooltip); at the
--                   right, round buttons with a soft edge (Bags.Round), what can be done at a vendor or a banker
--                   (Foot.lua), the junk marker (a click, then clicks on
--                   items mark them as junk or not: Select.lua; an item
--                   brought to it is marked at once), the bags themselves (in
--                   a strip at the body's top at first; a click hides or shows
--                   it), the clean-up: in One Bag our own sort (Sort.lua:
--                   the items moved into the categories' order, the button
--                   locked while it runs), in the other views the game's
--                   (C_Container.SortBags, as the game's bag window's button
--                   does), the dropdown View: the display (Layout.LOOKS),
--                   what sorts the items (Contents.ORDERS), what is shown, the
--                   slider Item Size (Bags.SizeRow; kept: scale; the items
--                   shrink by themselves in a narrow window, Layout.Fit)
--      the sidebar  at the left: the views and the categories (Sidebar.lua); folded by its
--                   arrow to a narrow edge, the strip of the bags hidden with it (kept)
--      the body     a scroll area (no scroll bar: the wheel scrolls it) with the view chosen as its blocks laid out
--                   (Views.lua, Layout.lua) and drawn (Canvas.lua), each item
--                   the game's own item button (Cells.lua); the bank has a
--                   window of its own (Bank.lua)
--      the foot     a band at the bottom, a pencil rule over it: the currencies, the checkboxes
--                   Auto Sell and Auto Repair (Vendor.lua), the gold (Foot.lua)
--  On the title line too, after its title, the dropdown of the account's
--  characters (Roster.lua): the one logged in, the bags as they are; another,
--  its things as Core last saw them (Alts.lua), in this same window: its
--  sidebar (All Items, the categories and groups with that character's
--  counts), its display, order and item size, its heads; what only the bags
--  as they are can do (the strip of the bags, the clean-up, the junk marker,
--  selling, One Bag and Each Bag, Pinned and Recent, the "+" slots) stands
--  aside meanwhile (Saneroki, 2026-11-15: "keep our bags window but add the
--  search and dropdown menu to select other characters to the proper bags
--  window that we had before").
--
--  The search box on the title line (and the full window's, which it shows)
--  finds items by their name, their category or their item level: the views of
--  the bags as they are fade what it does not find, the others leave it out;
--  what is found is lit. Under the bags, Found elsewhere: each other character
--  that has any of it, and this one's bank as last seen while no banker is
--  open, with how many; a click shows them (Saneroki, 2026-11-15: "So the
--  search works across alts and banks as well").
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
Bags.SCROLL = 20     -- room at the right for the game's scroll bar (the bank's)
Bags.RIGHT = 6       -- room at the right of the bags' items (no scroll bar there)
Bags.BAR = 18        -- the bar on the title line, inside the label's pencil lines
Bags.PAGE_BAR = 35   -- a bar on the page (the bank's)
Bags.BAR_BUTTON = 24 -- a button on a bar of the page (the bank's)
Bags.TITLE_BUTTON = 15 -- a round button on the title line
Bags.BAR_GAP = 7
Bags.BAR_END = 2     -- from the title line's end (the panel's X left of it) to the bar's last button
Bags.SOFT = { 0.42, 0.2, 0.08 } -- a round button's soft edge: the ink's alpha one, two, three pixels out
Bags.MENU_WIDTH = 110
Bags.TITLE_MENU = 56   -- the dropdown View on the title line
Bags.COUNT_LEAST = 70  -- the least room for a title line's count: with less, it goes
Bags.SEARCH = 170      -- the search box on the title line at most (Saneroki, 2026-11-15), and at least
Bags.SEARCH_LEAST = 90
Bags.SEARCH_HEIGHT = 20
Bags.RULE = { ns.Style.INK[1], ns.Style.INK[2], ns.Style.INK[3], 0.3 } -- the line by the sidebar
Bags.COUNT_COLOR = ns.Style.SOFT    -- the bar's count
-- The window at its narrowest: the title line's word, the characters' dropdown, the search box and buttons; the strip
-- of the bags.
Bags.LEAST = { 420, 240 }
Bags.ELSEWHERE_ROW = 22   -- a line of what the search finds elsewhere (another character, the bank as last seen)
Bags.ELSEWHERE_GAP = 14   -- above those lines
Bags.FIRST = 560          -- how wide the first layout makes it
Bags.SIZER = 130          -- the slider Item Size in the dropdown View
Bags.SIZE_WORD = 80       -- the room for its word, at its left
Bags.SIZE_VALUE = 44      -- and for its percent, at its right
Bags.SIZE_ROW = 26
-- The settings that show Pinned and Recent (options.bags).
Bags.SHOW = { pinned = "showPinned", recent = "showRecent" }

local Contents, Layout, Cells, Foot = ns.Contents, ns.Layout, ns.Cells, ns.Foot
local Categories, Views, Menus, Sidebar, Select = ns.Categories, ns.Views, ns.Menus, ns.BagSidebar, ns.Select
local Columns, Sort = ns.Columns, ns.Sort

local panel, scroll, child, menu, sort, bar, strip, side, coin, columns, search, roster
local face            -- whose things the window shows: nil, the bags as they are; a character's key, as last seen (Alts)
local elsewhere       -- the lines of what the search finds elsewhere (Elsewhere)
local kept            -- options.bags: the display, the order, what is shown; the categories' choices
local query           -- what the search found by (Core.Fuzzy.Query), nil: nothing typed
local shown = false
local viewing         -- the view chosen in the sidebar while the window is open (nil: the first)
local width = 0       -- the panel's body width
local carried = { place = "bags", slots = {}, free = {} }
local sections = { carried }
local carriedBags = {}

-------------------------------------------------------------------------------
--  Reading the bags
-------------------------------------------------------------------------------
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
    Bags.Carried()
end
Bags.Clear = Clear

-------------------------------------------------------------------------------
--  The view
-------------------------------------------------------------------------------
-- The module's settings (Core's), the bags' among them; an empty table before they are there.
local function Options()
    return type(ns.options) == "table" and ns.options or {}
end

-- The views only the bags as they are have: their slots (One Bag, Each Bag), Pinned and Recent. Another character's
-- things show All Items in their place (Core keeps a bag's items, not the slots they lie in).
local LIVE = { [Views.ONE] = true, [Views.EACH] = true }
LIVE["cat:" .. Categories.PINNED], LIVE["cat:" .. Categories.RECENT] = true, true

-- The view shown: the one chosen in the sidebar, else the one the window opens with; one whose category is
-- off or gone, or whose group is no more, gives way to All Items.
local function View()
    local view = viewing or Options().first or Views.ALL
    if face and LIVE[view] then return Views.ALL end
    local key = view:match("^cat:(.+)$")
    if key and (not Categories.rank[key] or Categories.Off(key)) then return Views.ALL end
    if key and Bags.SHOW[key] and Options()[Bags.SHOW[key]] == false then return Views.ALL end
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
-- A round button on the paper (the bar's): its icon cut to a circle, a narrow edge of the pencil's ink fading out
-- round it (Bags.SOFT), the highlight and (checkable: a CheckButton) the checked light cut to the circle too.
function Bags.Round(parent, file, checkable, size)
    size = size or Bags.BAR_BUTTON
    local button = CreateFrame(checkable and "CheckButton" or "Button", nil, parent)
    button:SetSize(size, size)
    local ink = ns.Style.INK
    for step, alpha in ipairs(Bags.SOFT) do
        local ring = button:CreateTexture(nil, "BACKGROUND", nil, -step)
        ring:SetPoint("TOPLEFT", -step, step)
        ring:SetPoint("BOTTOMRIGHT", step, -step)
        ring:SetColorTexture(ink[1], ink[2], ink[3], alpha)
        Cells.Mask(button, Cells.CIRCLE, ring)
    end
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(file)
    icon:SetTexCoord(Cells.ZOOM, 1 - Cells.ZOOM, Cells.ZOOM, 1 - Cells.ZOOM)
    button.icon = icon
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    local light = button:GetHighlightTexture()
    if light then light:SetAllPoints() end
    local checked
    if checkable then
        button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
        checked = button:GetCheckedTexture()
        if checked then checked:SetAllPoints(); checked:SetBlendMode("ADD") end
    end
    Cells.Mask(button, Cells.CIRCLE, icon, light, checked)
    return button
end

-- The clean-up button, round, a broom (Bags.Round), for the bags or a bank (Bank.lua).
local function CleanButton(parent, click, enter, size)
    local button = Bags.Round(parent, "Interface\\Icons\\INV_Pet_Broom", false, size)
    button:SetScript("OnClick", function(self) ns.Safe("bags", click, self) end)
    button:SetScript("OnEnter", function(self) ns.Safe("bags", enter, self) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    return button
end
Bags.CleanButton = CleanButton

-- The font of the bar's count (and the foot's words).
local fonts
local function Fonts()
    if fonts then return fonts end
    fonts = { count = ns.Style.Font("SaneUIBagsBarCount", 15) }
    return fonts
end
Bags.Fonts = Fonts

-- The mouse on a list's item button: its line lit (the canvas's).
function Bags.Hover(button, on)
    if Bags.canvas then Bags.canvas:Hover(button, on) end
end

-- Shift and a click on a stack: our splitter in place of the game's (where the template opened its own: not when
-- the click linked the item into the chat), in the views without empty slots (always) or everywhere (the setting).
local function Splits(button, mouse)
    if mouse ~= "LeftButton" then return false end
    local record = Cells.Record(button)
    if not (record and record.item) then return false end
    local view = View()
    if (view == Views.ONE or view == Views.EACH) and not Options().splitter then return false end
    return ns.Split.Replace(button, record)
end

-- A click on an item button, after the game's own: Alt and the right button (which the game's button does
-- nothing with) open the item's menu; Shift and the left one our splitter; the middle one unpins it, takes it out
-- of the category it was put into, or pins it (a pinned item put into one shows only under Pinned: unpinned first).
function Bags.Clicked(button, mouse)
    local alt = rawget(_G, "IsAltKeyDown")
    if mouse == "RightButton" and alt and alt() then return Menus.Item(button) end
    if Splits(button, mouse) then return end
    if mouse ~= "MiddleButton" then return end
    local record = Cells.Record(button)
    if not (record and record.item) then return end
    local assigned = Categories.Assigned(record.item)
    if Categories.Pinned(record.item) then
        Categories.Pin(record.item, false)
    elseif assigned and assigned ~= Categories.JUNK then
        Categories.Assign(record.item, nil)
    else
        Categories.Pin(record.item, true)
    end
    Bags.Refresh()
    if ns.Bank then ns.Bank.Refresh() end -- the bank's items by category may hold it too
end

local how = {} -- how a cell is drawn (Cells.Draw), used again

-- How large the bags' items are in a room so wide (the slider's size, smaller in a narrow window: Layout.Fit); the
-- bank's with them.
function Bags.ItemSize(room)
    local bags = Options().bags
    return Layout.Fit(type(bags) == "table" and bags.scale or nil, room - ns.Canvas.INSET)
end

-- The dropdown of the characters as it is now: whose things are shown its word; while searching, how many each has
-- of what is found. Returns the characters (nil while Core's data is not loaded yet) and those counts.
local function People()
    local characters = ns.Snapshot.Characters()
    local counts
    if characters and query then
        counts = {}
        for _, who in ipairs(characters) do counts[who.key] = ns.Snapshot.Found(who.key, query) end
    end
    ns.Roster.Show(characters or {}, face or Core.charKey, counts)
    return characters, counts
end

-- How much of what is found this character's bank holds, as last seen.
local function BankFound()
    local count = 0
    for _, section in ipairs(ns.Snapshot.Sections(Core.charKey, query)) do
        if section.place == "bank" then
            for _, entry in ipairs(section.items) do count = count + (entry.count or 1) end
        end
    end
    return count
end

-- One line of Elsewhere: whose, how many; a click shows them, found (the bank's line: the one logged in as last seen).
local function Line(index)
    local lines = elsewhere.lines
    local line = lines[index]
    if line then return line end
    line = CreateFrame("Button", nil, elsewhere)
    line:SetHeight(Bags.ELSEWHERE_ROW)
    local lit = line:CreateTexture(nil, "HIGHLIGHT")
    lit:SetAllPoints()
    local shade = ns.Style.SHADE
    lit:SetColorTexture(shade[1], shade[2], shade[3], shade[4])
    line.words = line:CreateFontString(nil, "ARTWORK")
    ns.Style.SetFont(line.words, 13)
    line.words:SetPoint("LEFT", 6, 0)
    line.words:SetPoint("RIGHT", -6, 0)
    line.words:SetJustifyH("LEFT")
    line.words:SetWordWrap(false)
    line:SetScript("OnClick", ns.Gently("bags search", function(self) Bags.Face(self.key, self.stored) end))
    lines[index] = line
    return line
end

-- While searching, where else it is: under the items a line for each character not shown that has any of it (the one
-- logged in: its bags as they are), and while the bags are shown, for this one's bank as last seen while no banker is
-- open, with how many. Returns the height it takes (0: none).
local function Elsewhere(top, characters, counts)
    if not elsewhere then
        elsewhere = CreateFrame("Frame", nil, child)
        elsewhere.head = elsewhere:CreateFontString(nil, "ARTWORK")
        ns.Style.SetFont(elsewhere.head, 14, true, ns.Style.SOFT)
        elsewhere.head:SetPoint("TOPLEFT")
        elsewhere.head:SetText(ns.TEXT.bagsElsewhere)
        elsewhere.lines = {}
    end
    local found = {}
    if query and characters then
        local Alts, Roster = ns.Alts, ns.Roster
        for _, who in ipairs(characters) do
            local count, word
            if who.key == face then
                count = nil -- the one shown
            elseif who.key == Core.charKey and not face then
                if not Contents.bankOpen then count, word = BankFound(), Alts.TEXT.bank end
            else
                count = counts and counts[who.key]
            end
            if count and count > 0 then
                local name = who.key == ns.Snapshot.ACCOUNT and Alts.TEXT.account or who.name or "?"
                if who.key ~= ns.Snapshot.ACCOUNT then name = "|c" .. ns.Style.InkHex(Roster.Colour(who.class)) .. name .. "|r" end
                found[#found + 1] = { key = who.key, stored = word ~= nil,
                                      text = name .. (word and (" - " .. word) or "") .. "  (" .. count .. ")" }
            end
        end
    end
    for index = #found + 1, #elsewhere.lines do elsewhere.lines[index]:Hide() end
    if #found == 0 then
        elsewhere:Hide()
        return 0
    end
    local width = (child:GetWidth() or 0) - ns.Canvas.INSET
    local head = (elsewhere.head:GetStringHeight() or 16) + 6
    elsewhere:ClearAllPoints()
    elsewhere:SetPoint("TOPLEFT", child, "TOPLEFT", ns.Canvas.INSET, -(top + Bags.ELSEWHERE_GAP))
    elsewhere:SetSize(math.max(1, width), head + #found * Bags.ELSEWHERE_ROW)
    for index, entry in ipairs(found) do
        local line = Line(index)
        line.key, line.stored = entry.key, entry.stored
        line.words:SetText(entry.text)
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", 0, -(head + (index - 1) * Bags.ELSEWHERE_ROW))
        line:SetPoint("RIGHT")
        line:Show()
    end
    elsewhere:Show()
    return Bags.ELSEWHERE_GAP + head + #found * Bags.ELSEWHERE_ROW
end

local NOTHING = { count = 0 } -- no blocks: a canvas emptied
local drew    -- whose things the scroll area holds: nil the bags', a character's key (the other canvas emptied)

local function Draw()
    if not child then return end
    local room = child:GetWidth()
    if not room or room <= 0 then return end
    local options = Options()
    local size, view = Bags.ItemSize(room), View()
    how.bind, how.coin, how.grey, how.set = options.bind == true, options.coin == true, options.grey == true, options.setName == true
    how.level = options.itemLevel ~= false
    how.searching = query ~= nil -- what is found lit (Cells: how.found)
    local characters, counts = People()
    local height
    if face then -- another character's things in the bags' place, drawn by the bags' views (Alts.lua)
        if not drew then Bags.canvas:Draw(NOTHING, room, how, size) end
        drew = face
        local drawn, cells, sideCounts = ns.Alts.Draw(face, view, query, room, how, size)
        height = drawn
        Bags.blocks = NOTHING
        bar.count:SetText(ns.TEXT.bagsCells:format(cells))
        Sidebar.Refresh(sideCounts, view, options, true)
    else
        if drew then ns.Alts.Clear() end
        drew = nil
        local blocks = Views.Build(view, sections, query, kept.sort, options)
        Bags.blocks = blocks
        height = Bags.canvas:Draw(blocks, room, how, size)
        Bags.Count()
        coin:SetShown(Categories.Marker())
        Sidebar.Refresh(Views.Counts(carried, options), view, options)
    end
    local more = Elsewhere(height, characters, counts)
    if more > 0 and face then ns.Alts.note:Hide() end -- nothing found here: the lines say where it is
    height = height + more
    child:SetHeight(math.max(1, height))
    if Cells.short then Core.AfterCombat("inventory: bags", Bags.Refresh) end
end

-- Everything read anew and drawn (the foot is the bags' own: not while another character's things are shown).
function Bags.Refresh()
    if not shown then return end
    ns.Safe("bags", Read)
    ns.Safe("bags", Draw)
    if not face then ns.Safe("bags", Foot.Refresh, carried) end
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

-- Another profile came into use: what it keeps of the bags (a table of its own: the canvas draws by it), its
-- sidebar and strip as it keeps them, the items in the room left, read and drawn anew.
function Bags.Reload()
    if not kept then   -- no window built yet: the categories and columns still follow the new profile
        Bags.Store()
        return
    end
    kept = Bags.Store()
    Bags.canvas.owner.store = kept
    ns.Alts.Use(kept)
    Sidebar.Fold(kept.side == false)
    Bags.Restrip()
    Bags.Size()
    Bags.Refresh()
end

-- One of the bags' settings changed (Core's options page, the dropdown, a menu): the categories as the junk
-- marker has them, the window drawn anew.
function Bags.Settled()
    if not kept then return end
    Categories.Use(kept)
    Bags.Refresh()
end

-------------------------------------------------------------------------------
--  The game's events, while the panel is shown
-------------------------------------------------------------------------------
local Soon = Core.Later(Bags.Refresh)
Bags.Soon = Soon -- the window read and drawn anew a frame later, once however often it is asked (Recent's new items too)

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

-- An item's data came from the server: drawn anew if one of ours waited for it (its name, its item level). The
-- reading anew takes it off the list (Contents.Read), so the bank hears of it too.
local function Arrived(item)
    item = Core.Plain(item)
    if item and Contents.waiting[item] then Soon() end
end

local EVENTS = {
    BAG_UPDATE_DELAYED = Soon, BAG_NEW_ITEMS_UPDATED = Soon, BAG_CONTAINER_UPDATE = Soon,
    QUEST_ACCEPTED = Soon, QUEST_REMOVED = Soon, MERCHANT_SHOW = Soon, MERCHANT_CLOSED = Soon,
    MAIL_SHOW = Soon, MAIL_CLOSED = Soon, TRADE_SHOW = Soon, TRADE_CLOSED = Soon,
    AUCTION_HOUSE_SHOW = Soon, AUCTION_HOUSE_CLOSED = Soon, EQUIPMENT_SETS_CHANGED = Soon,
    PLAYER_EQUIPMENT_CHANGED = Soon, -- what is an upgrade changed
    BANKFRAME_OPENED = Soon, BANKFRAME_CLOSED = Soon,
    ITEM_LOCK_CHANGED = Locked, GET_ITEM_INFO_RECEIVED = Arrived,
    PLAYER_LEVEL_UP = function() Contents.Leveled(); Soon() end,
    BAG_UPDATE_COOLDOWN = function() Cells.Cooldowns() end,
    PLAYER_MONEY = function() Foot.Gold() end, CURRENCY_DISPLAY_UPDATE = function() Foot.Tokens() end,
}
local UNIT_EVENTS = { UNIT_QUEST_LOG_CHANGED = Soon }

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- What is kept of the window: its display and Sort By (sort; the categories' own order is theirs, order), each one
-- of those there are; the slider's size (scale, in percent); the categories' choices (Categories.lua checks them).
-- In the profile in use (options.bags); what the store holds from before starts a profile off.
local function Kept()
    local bags, before = ns.options.bags, ns.store.bags
    if not next(bags) and type(before) == "table" then
        for key, value in pairs(before) do bags[key] = Core.Copy(value) end
    end
    if not Layout.LOOK[bags.look] then bags.look = "grid" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == bags.sort end
    if not known then bags.sort = "default" end
    bags.scale = Layout.Scale(bags.scale)
    Categories.Use(bags)
    Columns.Use(bags)
    return bags
end
-- The bags' store, checked, the categories and the list's columns as it has them (the bank reads them too, the bags'
-- window perhaps not built yet).
Bags.Store = Kept

local function IsLook(key) return kept.look == key end
local function SetLook(key)
    kept.look = key
    Bags.Restrip()
    Bags.Redraw()
end
local function IsOrder(key) return kept.sort == key end
local function SetOrder(key)
    kept.sort = key
    Bags.Redraw()
end
local function IsOn(key) return Options()[key] ~= false end
local function Toggle(key)
    Core.Set(ns.name, key, not IsOn(key))
end
local function IsFirst(key) return (Options().first or Views.ALL) == key end
local function SetFirst(key)
    Core.Set(ns.name, "first", key)
end
local function SwitchOn(key)
    Categories.SwitchOff(key, false)
    Bags.Refresh()
end

-- The row Item Size of a window's dropdown View: the game's slider with its steppers (lent to the row by the menu
-- while it is open, as the map's pin filter has it), the percent at its right, the window drawn anew as it moves.
-- get() and set(percent) are the window's. A client without that slider: no row.
local OWNER = {} -- the sliders' callbacks are of this owner: a slider laid out anew replaces its last one
local function Sizer(frame, get, set)
    local mixin = MinimalSliderWithSteppersMixin
    local scale = Layout.SCALE
    local slider = frame:AttachTemplate("MinimalSliderWithSteppersTemplate")
    slider:SetWidth(Bags.SIZER)
    slider:ClearAllPoints()
    slider:SetPoint("RIGHT", -Bags.SIZE_VALUE, 0)
    slider:UnregisterCallback(mixin.Event.OnValueChanged, OWNER)
    slider:Init(get(), scale.low, scale.high, (scale.high - scale.low) / scale.step,
        { [mixin.Label.Right] = function(value) return ("%d%%"):format(value) end })
    slider:RegisterCallback(mixin.Event.OnValueChanged, ns.Guard(function(_, value) set(Layout.Scale(value)) end), OWNER)
    return Bags.SIZE_WORD + Bags.SIZER + Bags.SIZE_VALUE, Bags.SIZE_ROW
end

function Bags.SizeRow(root, get, set)
    if not rawget(_G, "MinimalSliderWithSteppersMixin") then return end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsItemSize):AddInitializer(ns.Guard(function(frame) return Sizer(frame, get, set) end))
end

local function GetScale() return kept.scale end
local function SetScale(percent)
    if percent == kept.scale then return end
    kept.scale = percent
    Bags.Redraw()
    if ns.Bank then ns.Bank.Redraw() end
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
    Bags.SizeRow(root, GetScale, SetScale)
end
local ViewMenu = ns.Guard(Menu)

-- The clean-up: in One Bag our own sort, by the categories and the window's order; else the game's.
local function Clean()
    if InCombatLockdown() then return end
    if View() == Views.ONE then return Sort.Start(kept.sort) end
    local api = rawget(_G, "C_Container")
    if not (api and api.SortBags) then return end
    Core.Sound("UI_BAG_SORTING_01")
    api.SortBags()
end

local function CleanTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    if View() == Views.ONE then
        GameTooltip:SetText(ns.TEXT.bagsSort, 1, 1, 1)
        GameTooltip:AddLine(Sort.Running() and ns.TEXT.bagsSorting or ns.TEXT.bagsSortTip, 1, 0.82, 0, true)
        return GameTooltip:Show()
    end
    GameTooltip:SetText(Core.Word("BAG_CLEANUP_BAGS", "Clean Up Bags"), 1, 1, 1)
    local about = rawget(_G, "BAG_CLEANUP_BAGS_DESCRIPTION")
    if about then GameTooltip:AddLine(about, 1, 0.82, 0, true) end
    GameTooltip:Show()
end

-- Our sort running or done: the clean-up button locked (greyed) meanwhile; the bags drawn as they are then.
function Bags.Sorting(on)
    if sort then
        sort:SetEnabled(not on)
        sort:SetAlpha(on and 0.4 or 1)
    end
    if not on then Bags.Refresh() end
end

-- The bar's count: in the views of every item, how many slots of the ordinary bags hold something, of how many;
-- in a category's or group's view, how many cells it shows.
function Bags.Count()
    if not bar or face then return end -- another character's: how many of its items are shown (Draw)
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

-- A band on the paper with a pencil rule at one edge (the bar's at its foot, the foot's at its top).
local function Band(frame, edge)
    return nil, ns.Style.Rule(frame, edge, "BORDER")
end
Bags.Band = Band

-- The strip of the bags themselves at the body's top, shown or hidden (kept; hidden too while the sidebar is
-- folded and while another character's things are shown); the sidebar and the scroll area under what shows.
local function Strip()
    local folded = kept.side == false
    local on = kept.strip ~= false and not folded and not face
    strip:SetShown(on)
    side:ClearAllPoints()
    if on then side:SetPoint("TOPLEFT", strip, "BOTTOMLEFT") else side:SetPoint("TOPLEFT", strip:GetParent(), "TOPLEFT") end
    side:SetPoint("BOTTOMLEFT", Foot.frame, "TOPLEFT")
    local list = kept.look == "list"
    columns:ClearAllPoints()
    columns:SetPoint("TOPLEFT", side, "TOPRIGHT", Bags.INSET, -Bags.EDGE)
    columns:SetPoint("RIGHT", strip, "RIGHT", -(Bags.RIGHT + Bags.INSET), 0)
    columns:SetShown(list)
    scroll:ClearAllPoints()
    if list then
        scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -(Bags.EDGE + Columns.HEAD + 2))
    else
        scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -Bags.EDGE)
    end
    scroll:SetPoint("BOTTOMRIGHT", Foot.frame, "TOPRIGHT", -Bags.RIGHT, Bags.EDGE)
    bar.bags:SetChecked(on)
    if list then columns:Refresh(math.max(1, (child:GetWidth() or 0) - Bags.INSET)) end
end

function Bags.Restrip()
    Strip()
end

-- The sidebar folded (kept.side false) or unfolded; the strip of the bags goes and comes with it.
function Bags.Fold(on)
    kept.side = not on
    Sidebar.Fold(on)
    Strip()
    Bags.Size()
end

-- The bags' button: the strip hidden or shown; while the sidebar is folded, the sidebar unfolded with the strip.
local function ToggleStrip()
    if kept.side == false then
        kept.strip = true
        Bags.Fold(false)
    else
        kept.strip = kept.strip == false
        Strip()
    end
    Core.Sound(kept.strip and "IG_BACKPACK_OPEN" or "IG_BACKPACK_CLOSE")
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
        Bags.Refresh()
        if ns.Bank then ns.Bank.Refresh() end -- the bank's items by category may hold it too
        return
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

-- A bar on a window's title line (its panel's title, the journal's), after the title's word: its count, what ends
-- the line left to the window. Returns the bar.
function Bags.TitleBar(owner, body)
    local title = owner.title
    local line = CreateFrame("Frame", nil, owner)
    if title then
        line:SetPoint("LEFT", title, "LEFT")
        line:SetPoint("RIGHT", title, "RIGHT", -Bags.BAR_END, 0)
    else
        line:SetPoint("TOPLEFT", body, "TOPLEFT", 0, Bags.BAR)
        line:SetPoint("TOPRIGHT", body, "TOPRIGHT", 0, Bags.BAR)
    end
    line:SetHeight(Bags.BAR)
    line:SetFrameLevel((owner.head and owner.head:GetFrameLevel() or owner:GetFrameLevel()) + 5)
    line.count = line:CreateFontString(nil, "ARTWORK")
    local font = Fonts()
    if font.count then line.count:SetFontObject(font.count) end
    line.count:SetTextColor(Bags.COUNT_COLOR[1], Bags.COUNT_COLOR[2], Bags.COUNT_COLOR[3], Bags.COUNT_COLOR[4])
    line.count:SetJustifyH("LEFT")
    line.count:SetWordWrap(false)
    line.words = (title and title.GetStringWidth and title:GetStringWidth() or 0) + 2 * Bags.BAR_GAP
    line.count:SetPoint("LEFT", line.words, 0)
    return line
end

-- The bar's count, after the characters' dropdown, ends at the search box; the box at the first thing right of it:
-- what can be done here (Foot.Act), else the junk marker (another character's things: the dropdown View, the bags'
-- own buttons standing aside). On a narrow title line the dropdown and the box grow narrower, down to their least,
-- and then the count goes (the sidebar and the strip of the bags say as much); a line's words, dropdowns, box and
-- buttons fit even then (Bags.LEAST).
local before  -- what the box ends at, nil: the junk marker
local function CountFit()
    local buttons = face and 0 or 3 * (Bags.TITLE_BUTTON + Bags.BAR_GAP)
    local room = (bar:GetWidth() or 0) - bar.words - Bags.TITLE_MENU - buttons
        - (not face and before and (before:GetWidth() or 0) + Bags.BAR_GAP or 0) - Bags.BAR_GAP
    local Roster = ns.Roster
    local people = math.max(Roster.LEAST, math.min(Roster.WIDTH, room - Bags.SEARCH_LEAST - 2 * Bags.BAR_GAP))
    roster:SetWidth(people)
    room = room - people - Bags.BAR_GAP
    local box = math.max(Bags.SEARCH_LEAST, math.min(Bags.SEARCH, room - Bags.COUNT_LEAST - Bags.BAR_GAP))
    search:SetWidth(box)
    bar.count:SetShown(room - box - Bags.BAR_GAP >= Bags.COUNT_LEAST)
end

function Bags.CountBefore(frame)
    before = frame
    search:ClearAllPoints()
    if face then
        search:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    else
        search:SetPoint("RIGHT", frame or coin, "LEFT", -Bags.BAR_GAP, 0)
    end
    bar.count:SetPoint("RIGHT", search, "LEFT", -Bags.BAR_GAP - 4, 0) -- (the box's frame reaches past its left)
    if bar:GetWidth() and bar:GetWidth() > 0 then CountFit() end
end

-- What is typed into the bags' search box (Saneroki, 2026-11-15: "a search bar in the titlebar of the bags where
-- you can search your inventory for items and the inventory highlights those items it finds"): the bags (or the
-- other character's things shown), the bank while it is open; the full screen's box tells the bags the same
-- (Bags.Search), which this box then shows.
local typed = "" -- the text searched last
local function Typed(text)
    text = text or ""
    if text == typed then return end
    Bags.Search(text)
    if ns.Bank and ns.Bank.Search then ns.Safe("bank", ns.Bank.Search, text) end
end

-- The free slots' tooltip over the count: the bags' alone.
local function CountTip(owner)
    if not face then Foot.FreeTip(owner) end
end

-- The bar on the title line: the dropdown of the characters, the count, the search box, then at the title line's end
-- the junk marker, the bags' button, the clean-up and the dropdown View; the strip of the bags at the body's top.
local function Bar(body)
    bar = Bags.TitleBar(panel, body)
    -- whose things are shown, after the title's word (Roster.lua: the one logged in, the bags as they are)
    roster = ns.Roster.Build(bar)
    roster:SetPoint("LEFT", bar.words, 0)
    bar.count:ClearAllPoints()
    bar.count:SetPoint("LEFT", roster, "RIGHT", Bags.BAR_GAP, 0)
    local hover = CreateFrame("Frame", nil, bar)
    hover:SetAllPoints(bar.count)
    hover:SetScript("OnEnter", function(self) ns.Safe("bags", CountTip, self) end)
    hover:SetScript("OnLeave", GameTooltip_Hide)
    menu = ns.Style.Dropdown(bar, Bags.TITLE_MENU, Bags.BAR)
    menu:SetPoint("RIGHT")
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(ViewMenu)
    Bags.viewMenu = menu
    sort = CleanButton(bar, Clean, CleanTip, Bags.TITLE_BUTTON)
    sort:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    bar.sort = sort
    local bags = Bags.Round(bar, "Interface\\Icons\\INV_Misc_Bag_08", true, Bags.TITLE_BUTTON)
    bags:SetPoint("RIGHT", sort, "LEFT", -Bags.BAR_GAP, 0)
    bags:SetScript("OnClick", function() ns.Safe("bags", ToggleStrip) end)
    bags:SetScript("OnEnter", function(self) ns.Safe("bags", BagsTip, self) end)
    bags:SetScript("OnLeave", GameTooltip_Hide)
    bar.bags = bags
    coin = Bags.Round(bar, "Interface\\Icons\\INV_Misc_Coin_02", true, Bags.TITLE_BUTTON)
    coin:SetPoint("RIGHT", bags, "LEFT", -Bags.BAR_GAP, 0)
    coin:SetScript("OnClick", function() ns.Safe("bags", CoinClick) end)
    coin:SetScript("OnReceiveDrag", function() ns.Safe("bags", CoinClick) end)
    coin:SetScript("OnEnter", function(self) ns.Safe("bags", CoinTip, self) end)
    coin:SetScript("OnLeave", GameTooltip_Hide)
    bar.coin = coin
    search = CreateFrame("EditBox", nil, bar, "SearchBoxTemplate")
    search:SetSize(Bags.SEARCH, Bags.SEARCH_HEIGHT)
    search:SetAutoFocus(false)
    Core.Look.Search(search)
    local hint = rawget(search, "Instructions") -- the game's grey words in the empty box
    if type(hint) == "table" and hint.SetText then hint:SetText(ns.TEXT.bagsSearch) end
    search:HookScript("OnTextChanged", ns.Gently("bags search", function(self) Typed(self:GetText()) end))
    Bags.searchBox = search
    Bags.CountBefore()
    bar:SetScript("OnSizeChanged", ns.Guard(CountFit))
    Bags.bar = bar
    strip = CreateFrame("Frame", nil, body)
    strip:SetPoint("TOPLEFT")
    strip:SetPoint("TOPRIGHT")
    strip:SetHeight(Foot.STRIP)
    Bags.strip = strip
end

-- An item let go anywhere over the window that takes nothing itself (the paper, the bar, the foot): into the bags,
-- in the category the rules give it (Menus.Home).
local function Home()
    if GetCursorInfo() == "item" then Menus.Home(true) end
end

-- The panel itself takes that: it lies under everything in it, so the item buttons, heads, rows and slots keep
-- the mouse for themselves.
local function Back()
    panel:EnableMouse(true)
    for _, frame in ipairs({ panel, panel.head }) do -- the head: the window's top, dragged by
        frame:HookScript("OnReceiveDrag", ns.Guard(Home))
        frame:HookScript("OnMouseUp", ns.Guard(Home))
    end
end

-- The wheel over a scroll area of items so large: a line of them up or down, never past the ends.
function Bags.Wheel(area, delta, size)
    local content = area:GetScrollChild()
    local most = area.GetVerticalScrollRange and area:GetVerticalScrollRange()
        or math.max(0, (content and content:GetHeight() or 0) - (area:GetHeight() or 0))
    local step = size + ns.Layout.Gap(size)
    area:SetVerticalScroll(math.max(0, math.min(most, area:GetVerticalScroll() - delta * step)))
end

local function Wheel(delta)
    Bags.Wheel(scroll, delta, Bags.ItemSize(child:GetWidth() or 0))
end

function Bags.Build(made)
    panel = made
    Back()
    kept = Kept()
    local body = panel.body
    Bar(body)
    Foot.Build(body, coin, strip)
    side = Sidebar.Build(body, strip, Foot.frame, kept)
    Sidebar.Fold(kept.side == false)
    columns = Columns.Build(body, function() Bags.Redraw() end)
    scroll = CreateFrame("ScrollFrame", nil, body)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) ns.Safe("bags", Wheel, delta) end)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    Cells.Build(child)
    Bags.canvas = ns.Canvas.New(child, { store = kept, redraw = function() Bags.Redraw() end, cells = Cells.bags,
        stow = true })
    Bags.rowOf = Bags.canvas.rowOf
    Bags.scroll = scroll
    Select.Build(scroll, { bar, strip, side, Foot.frame })
    -- another character's things, drawn in this scroll area by read-only buttons, their foot over the bags' (Alts.lua)
    ns.Safe("alts", ns.Alts.Build, child, body, Foot.frame, kept)
    Strip()
end

-- Whose things the window shows (Saneroki, 2026-11-15: "add the search and dropdown menu to select other characters
-- to the proper bags window that we had before"): the one logged in, the bags as they are (stored: its things as last
-- seen instead, its bank among them); another character, as Core last saw it (Alts.lua), in this same window, by its
-- sidebar, views, display and order. What only the bags as they are can do stands aside meanwhile: the bags' buttons
-- on the title line, their strip, their foot, the junk marker's mode. The dropdown of the characters (Alts.Choose) and
-- a line of what the search finds elsewhere choose; the window opens with the bags as they are.
function Bags.Face(key, stored)
    if key == Core.charKey and not stored then key = nil end
    face = key
    local own = key == nil
    for _, button in ipairs({ bar.bags, sort }) do button:SetShown(own) end
    coin:SetShown(own and Categories.Marker())
    if Foot.act then Foot.act:SetShown(own and Foot.Doing() ~= nil) end
    Foot.frame:SetShown(own)
    ns.Safe("alts", ns.Alts.Show, shown and key or nil)
    if not own then ns.Safe("bags", Select.Stop) end
    Strip()
    Bags.CountBefore(before)
    if scroll then scroll:SetVerticalScroll(0) end
    Bags.Refresh()
end

-- Whose things are shown now (nil: the bags as they are).
function Bags.Whose()
    return face
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
        if face then return Bags.Face(nil) end -- the window opens with the bags as they are (Face draws them)
        Bags.Refresh()
    else
        ns.Safe("alts", ns.Alts.Show, nil)
        for item in pairs(Views.split) do Views.split[item] = nil end
        -- What runs stops, each on its own: one that fails keeps none of the others going.
        for _, stop in ipairs({ Cells.Light, Select.Stop, Sort.Stop, Sidebar.Cancel, ns.Split.Stop }) do ns.Safe("bags", stop) end
    end
end

-- The panel's new size (its body's: Board.Body): the scroll area's child as wide as the area, laid out anew.
function Bags.Size(newWidth, newHeight)
    if newWidth then width = ns.Board.Body("bags", newWidth, newHeight or 0) end
    if not child then return end
    child:SetWidth(math.max(1, width - Sidebar.Width() - Bags.EDGE - Bags.RIGHT))
    if kept.look == "list" then columns:Refresh(math.max(1, child:GetWidth() - Bags.INSET)) end
    ns.Safe("bags", Foot.Room, width)
    Bags.Redraw()
end

-- The search: the bags' box shows it (the full screen's box tells it too), what is shown drawn by it.
function Bags.Search(text)
    typed = text or ""
    query = Core.Fuzzy.Query(typed)
    if search and search:GetText() ~= typed then search:SetText(typed) end
    Bags.Redraw()
end

-- The board's least: what the title line must hold, the panel's leather round it; the items make themselves smaller
-- to fit (Layout.Fit), the foot leaves out what does not (Foot.Room). The first layout makes it wider.
Bags.Width = ns.Board.Least("bags", Bags.FIRST, Bags.LEAST[2])[1]
ns.Board.Part("bags", ns.TEXT.bags, ns.Board.Least("bags", Bags.LEAST[1], Bags.LEAST[2]), Bags)
