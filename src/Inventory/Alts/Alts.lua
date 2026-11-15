local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts
--  The window of the other characters on the module's full screen (Board.lua,
--  the key "alts"): what the account's characters have, as last seen, from
--  Core's data framework (Core.Data.Characters; read only), in the bags' look
--  and by the bags' parts (Saneroki, 2026-10-30), so what is learned in the one
--  holds in the other:
--      the bar      on the window's title line, after its title: the dropdown
--                   of the characters, whose things are shown (Roster.lua), how
--                   many items are shown, at the line's end the dropdown View:
--                   the display (Grid, List, Compact, the bags' Layout.LOOKS),
--                   Sort By (Contents.ORDERS), the slider Item Size
--      the sidebar  Storage, at the left, the bags' own (Sidebar.lua): the
--                   places (All Places, Bags, Bank, Equipped), then All
--                   Categories and the bags' categories and groups as the
--                   player arranged them, with how many of the character's
--                   items each holds; a click shows only that place, that
--                   category or that group, the place and the category
--                   together; a group's arrow, its box, a row's right click, a
--                   row dragged and the sidebar's fold are the bags', and so
--                   they count for the bags too
--      the body     a scroll area (no scroll bar: the wheel scrolls it): each
--                   place under its head, its items by the bags' categories
--                   (Views.lua), laid out and drawn as the bags' (Layout.lua,
--                   Canvas.lua, the size by Layout.Fit), each a read-only
--                   button (Items.Button); under them the paper doll of what is
--                   worn; in the list the bags' columns, a head of its own
--      the foot     a band at the bottom, a pencil rule over it: the character's
--                   level and class and when it was seen, its gold (every
--                   character's in its tooltip)
--  The bags' settings that say how an item looks hold here too: Show Item
--  Level, Coin on Junk, Grey Junk. Alt and a right click on an item opens its
--  menu (Put Into ...), the category's head its own. Kept for the account in
--  store.alts: look, sort, scale, folded (a list's folded categories), side
--  (the sidebar).
--
--  Every character of the account is in the dropdown, the one logged in first
--  (its bank as last seen is worth a look away from the bank too). Shown at
--  first: the first of the others by name; the one logged in when there is no
--  other. The choice holds until the next /reload.
--
--  The full window's search box finds an item across them all (Snapshot.lua):
--  the dropdown says how many each has, the window lists only what is found,
--  and if the chosen character has none of it, the first that has is shown
--  until the search is cleared. It listens while its panel is shown only: to
--  Core's data (Data.OnCharacters) and to the game telling an item's name it
--  did not know; a change while hidden is drawn when it is shown again.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Alts = {}
ns.Alts = Alts

-- The window's words; the game's own where it has them.
local DAYS = Core.Word("LASTONLINE_DAYS", "%d |4day:days;")
Alts.TEXT = {
    title = "Alts",
    bags = Core.Word("HUD_EDIT_MODE_BAGS_LABEL", "Bags"),
    bank = Core.Word("BANK", "Bank"),
    worn = Core.Word("EQUIPPED", "Equipped"),
    account = Core.Word("ACCOUNT_BANK_PANEL_TITLE", "Account Bank"),
    level = Core.Word("PLAYER_LEVEL_NO_SPEC", "Level %s |c%s%s|r"),
    total = Core.Word("TOTAL", "Total"),
    empty = Core.Word("EMPTY", "Empty"),
    none = Core.Word("BROWSE_NO_RESULTS", "No items found"),
    loading = Core.Word("SEARCH_LOADING_TEXT", "Loading..."),
    today = "Seen today",
    ago = "Seen %s ago",
    unseen = "Not seen yet",
    bankUnseen = "Not seen yet: open the bank with this character",
    now = "Logged in now",
    storage = "Storage",
    places = "All Places",
    categories = "All Categories",
}
-- The pictures of Storage's places (the bags' own, Categories.Art).
Alts.ICONS = {
    places = ns.Categories.Art("all"), bags = ns.Categories.Art("one"),
    bank = ns.Categories.Art("containers"), worn = ns.Categories.Art("chest"),
}

Alts.LEAST = { 372, 240 } -- the window at its narrowest: the title line's word and dropdowns
Alts.NAMES = 0.2     -- names the game tells (by the hundred at a search's first look): drawn together, this much later
-- What the bags' views show of a character's things: no Pinned or Recent, no slots to put items into, every item once.
Alts.PLAIN = { showPinned = false, showRecent = false, plus = false, merge = false }

local Bags, Foot, Views, Layout = ns.Bags, ns.Foot, ns.Views, ns.Layout
local Categories, Canvas, Columns, Contents = ns.Categories, ns.Canvas, ns.Columns, ns.Contents

local panel, body, bar, rail, side, scroll, child, canvas, cells, columns, foot, doll
local kept            -- store.alts
local place, filter   -- the sidebar's choice: a place ("bags", "bank", "worn"; nil: all), a view ("cat:<key>", "group:<group>"; nil: all)
local chosen          -- the key of the character the player chose (nil: the first choice, Default)
local query, typed    -- the search: Fuzzy.Query's words (nil: none), and what was typed
local shown = false
local width = 0       -- the panel's body width
local store = { blocks = {}, entries = {} } -- Views' blocks for this window
local how = { alt = true }                  -- how a cell is drawn (Cells.Draw): another character's

-- Seen: "Seen today", "Seen 3 days ago"; nil for a day not known.
local function Seen(day)
    local ago = ns.Snapshot.Ago(day)
    if not ago then return nil end
    if ago == 0 then return Alts.TEXT.today end
    return Alts.TEXT.ago:format(DAYS:format(ago))
end

-- A class's name in the player's language. Core checks only a character's name and places: its class, level and
-- realm are read as what they should be, and left out when they are not (a hand edit, an older version).
local function ClassName(class)
    if type(class) ~= "string" then return "" end
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    return names and names[class] or class
end

local function Level(who)
    local colours = rawget(_G, "RAID_CLASS_COLORS")
    local colour = colours and type(who.class) == "string" and colours[who.class]
    local level = type(who.level) == "number" and who.level or "?"
    local ink = colour and ns.Style.InkHex(colour.r, colour.g, colour.b) or "ff1e1711"
    return Alts.TEXT.level:format(level, ink, ClassName(who.class))
end

-- The lines of a character's tooltip in the dropdown: { text, r, g, b }.
function Alts.About(who)
    if who.key == ns.Snapshot.ACCOUNT then return { { Alts.TEXT.account, 1, 1, 1 } } end
    local r, g, b = ns.Roster.Colour(who.class)
    local lines = { { who.name or "?", r, g, b }, { Level(who), 1, 1, 1 } }
    if type(who.realm) == "string" then lines[#lines + 1] = { who.realm, 0.5, 0.5, 0.5 } end
    local seen = who.key == Core.charKey and Alts.TEXT.now or Seen(who.seen)
    if seen then lines[#lines + 1] = { seen, 0.5, 0.5, 0.5 } end
    if type(who.money) == "number" then lines[#lines + 1] = { Core.Coins(who.money) or "", 1, 1, 1 } end
    return lines
end

-- The first choice: the first of the others; the one logged in when there is none.
local function Default(characters)
    for _, who in ipairs(characters) do
        if who.key ~= Core.charKey and who.key ~= ns.Snapshot.ACCOUNT then return who.key end
    end
    return characters[1] and characters[1].key
end

local function Has(characters, key)
    for _, who in ipairs(characters) do
        if who.key == key then return true end
    end
    return false
end

-- Whose things are shown: the chosen; while searching, the first that has something found if the chosen
-- has none of it. counts: [key] = how many the search finds, or nil.
local function Whose(characters, counts)
    local key = Has(characters, chosen) and chosen or Default(characters)
    if counts and key and counts[key] == 0 then
        for _, who in ipairs(characters) do
            if counts[who.key] > 0 then return who.key end
        end
    end
    return key
end

-- The foot: the level line and when it was seen, its gold.
local function Footing(key)
    if key == ns.Snapshot.ACCOUNT then
        foot.line:SetText("")
        foot.gold.text:SetText("")
        return
    end
    local who = Core.Data.Character(key)
    if not who then return end
    local seen = key == Core.charKey and Alts.TEXT.now or Seen(who.seen) or Alts.TEXT.unseen
    foot.line:SetText(Level(who) .. "  |c" .. ns.Style.FAINT_HEX .. seen .. "|r")
    foot.gold.text:SetText(type(who.money) == "number" and Core.Coins(who.money) or "")
    foot.gold:SetWidth((foot.gold.text:GetStringWidth() or 0) + 4)
end

-- A place's head, for Items.Sections: its words, the note beside it, what it says without items.
local about -- the character the heads are for
local function Head(which)
    local title = about == ns.Snapshot.ACCOUNT and Alts.TEXT.account or Alts.TEXT[which]
    if which ~= "bank" or about == ns.Snapshot.ACCOUNT then return title, nil, Alts.TEXT.empty end
    local who = Core.Data.Character(about)
    local seen = who and Seen(who.bankSeen)
    return title, seen, seen and Alts.TEXT.empty or Alts.TEXT.bankUnseen
end

-- The sidebar Storage as it is for these sections (the character's, unsearched).
local PLACES = { { nil, "places" }, { "bags", "bags" }, { "bank", "bank" }, { "worn", "worn" } }
local function Storage(sections)
    local counts = ns.Items.Counts(sections)
    rail:Begin()
    for _, entry in ipairs(PLACES) do
        local key, word = entry[1], Alts.TEXT[entry[2]]
        local row = rail:Row(word, key and counts.places[key] or nil, Alts.ICONS[key or "places"], nil, 0, place == key)
        row.view = "place:" .. (key or "")
    end
    rail:Divider()
    local row = rail:Row(Alts.TEXT.categories, counts.total, Alts.ICONS.places, nil, 0, filter == nil)
    row.view = "cat:"
    ns.BagSidebar.Categories(rail, counts, filter, false)
    rail:Done()
end

-- A click in Storage: a place, a category or a group shown alone, or all again.
local function Choose(view)
    local kind, key = view:match("^(%a+):(.*)$")
    if kind == "place" then
        place = key ~= "" and key or nil
    else
        filter = key ~= "" and view or nil
    end
    Alts.Refresh(false)
end

-- What the bags' views left that is not shown here: a category without items; a place's head says how many it holds,
-- and with nothing under it goes too while only some is shown (drop). Blocks swap their places: each stays one table,
-- as Views uses them again.
local function Tidy(blocks, drop)
    local out, head, held = 0, nil, 0
    local function Close()
        if not head then return end
        local items = head.section.doll and head.section.total or held
        head.number = items > 0 and items or nil
        if held == 0 and drop and not head.section.doll then out = out - 1 end
    end
    for index = 1, blocks.count do
        local block = blocks[index]
        if block.level == 1 then
            Close()
            head, held = block, 0
        end
        if block.level == 1 or block.title or #block.entries > 0 then
            out = out + 1
            blocks[index], blocks[out] = blocks[out], block
            held = held + #block.entries
        end
    end
    Close()
    blocks.count = out
    return held
end

-- A category or group switched off or gone since it was chosen: all again.
local function Filter()
    local key = filter and filter:match("^cat:(.+)$")
    if key and (not Categories.rank[key] or Categories.Off(key)) then filter = nil end
    local group = filter and filter:match("^group:(.+)$")
    if group and #Categories.Members(group) < 2 then filter = nil end
    return filter
end

-- How large the items are in a room so wide: the slider's size, smaller in a narrow window.
local function Side(room)
    return Layout.Fit(kept.scale, room - Canvas.INSET)
end

-- This character's things in the body, as the sidebar and the search say.
local function Draw(key)
    local room = child:GetWidth()
    if not room or room <= 0 then return end
    local searching = query ~= nil
    local sections, worn = ns.Items.Sections(ns.Snapshot.Sections(key, query), Head, searching, place, filter ~= nil)
    local blocks = Views.Build(filter or Views.ALL, sections, searching and Contents.FOUND or nil, kept.sort, Alts.PLAIN, store)
    Tidy(blocks, searching or filter ~= nil)
    local options = ns.options
    how.coin, how.grey = options.coin == true, options.grey == true
    how.level = options.itemLevel ~= false
    local height = canvas:Draw(blocks, room, how, Side(room))
    if worn then
        doll:ClearAllPoints()
        doll:SetPoint("TOPLEFT", child, "TOPLEFT", Canvas.INSET, -height)
        doll:SetSize(room - Canvas.INSET, ns.Items.DOLL_HEIGHT)
        ns.Items.DrawDoll(doll, worn, room - Canvas.INSET)
        height = height + ns.Items.DOLL_HEIGHT
    else
        doll:Hide()
    end
    child:SetHeight(math.max(1, height))
    local items = 0
    for index = 1, blocks.count do items = items + #blocks[index].entries end
    bar.count:SetText(ns.TEXT.bagsCells:format(items))
    body.none:SetShown(searching and blocks.count == 0 and not worn)
end

-- Nothing to show: the body empty.
local function Empty()
    store.blocks.count = 0
    canvas:Draw(store.blocks, math.max(1, child:GetWidth() or 1), how)
    doll:Hide()
    child:SetHeight(1)
    bar.count:SetText("")
    foot.line:SetText("")
    foot.gold.text:SetText("")
    body.none:Hide()
end

-- Everything drawn as it is now; keep: the items stay where they were scrolled to.
local function Refresh(keep)
    local characters = ns.Snapshot.Characters()
    body.wait:SetShown(characters == nil)
    if not characters then
        ns.Roster.Show({}, nil, nil)
        return Empty()
    end
    local counts
    if query then
        counts = {}
        for _, who in ipairs(characters) do counts[who.key] = ns.Snapshot.Found(who.key, query) end
    end
    local key = Whose(characters, counts)
    ns.Roster.Show(characters, key, counts)
    if not key then return Empty() end
    Footing(key)
    about = key
    Filter()
    Storage(ns.Snapshot.Sections(key, nil))
    if not keep then scroll:SetVerticalScroll(0) end
    Draw(key)
end
Alts.Refresh = Refresh

-- Core's data changed, a choice in another window, or the game told a name the window waits for: drawn anew a frame
-- later (names Alts.NAMES later), once however many come at once; while hidden, nothing (it is drawn when shown).
local Later = Core.Later(function() ns.Safe("alts", Refresh, true) end)
local Named = Core.Later(function() ns.Safe("alts", Refresh, true) end, Alts.NAMES)
local function Changed()
    if shown then Later() end
end
Alts.Changed = Changed

local function Learned(item)
    if ns.Snapshot.Learned(Core.Plain(item)) and shown then Named() end
end

-- The player chose whose things to show (the dropdown).
function Alts.Choose(key)
    chosen = key
    ns.Safe("alts", Refresh, false)
end

-- The mouse on an item button's line (the list); a click after its own: Alt and the right button open the item's
-- menu, as in the bags.
function Alts.Hover(button, on)
    if canvas then canvas:Hover(button, on) end
end

function Alts.Clicked(button, mouse)
    local alt = rawget(_G, "IsAltKeyDown")
    if mouse == "RightButton" and alt and alt() then ns.Menus.Item(button) end
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
-- The list's head over the scroll area while the list is shown, the scroll area under it.
local function Arrange()
    local list = kept.look == "list"
    columns:ClearAllPoints()
    columns:SetPoint("TOPLEFT", side, "TOPRIGHT", Bags.INSET, -Bags.EDGE)
    columns:SetPoint("RIGHT", body, "RIGHT", -(Bags.RIGHT + Bags.INSET), 0)
    columns:SetShown(list)
    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, -(Bags.EDGE + (list and Columns.HEAD + 2 or 0)))
    scroll:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -Bags.RIGHT, Bags.EDGE)
    if list then columns:Refresh(math.max(1, (child:GetWidth() or 0) - Bags.INSET)) end
end

local function IsLook(key) return kept.look == key end
local function SetLook(key)
    kept.look = key
    Arrange()
    Refresh(false)
end
local function IsOrder(key) return kept.sort == key end
local function SetOrder(key)
    kept.sort = key
    Refresh(false)
end
local function GetScale() return kept.scale end
local function SetScale(percent)
    if percent == kept.scale then return end
    kept.scale = percent
    Refresh(true)
end
local Looked = ns.Guard(IsLook)
local Ordered = ns.Guard(IsOrder)
-- A choice drawn anew apart from the module's other windows: an error in it is noted, nothing more.
local function Look(key) ns.Safe("alts", SetLook, key) end
local function Order(key) ns.Safe("alts", SetOrder, key) end

local Menu = ns.Guard(function(_, root)
    root:CreateTitle(ns.TEXT.bagsLook)
    for _, look in ipairs(Layout.LOOKS) do root:CreateRadio(look.word, Looked, Look, look.key) end
    root:CreateDivider()
    root:CreateTitle(ns.TEXT.bagsOrder)
    for _, order in ipairs(Contents.ORDERS) do root:CreateRadio(order.word, Ordered, Order, order.key) end
    Bags.SizeRow(root, GetScale, SetScale)
end)

local function Kept()
    local stored = ns.store
    if type(stored.alts) ~= "table" then stored.alts = {} end
    local alts = stored.alts
    if not Layout.LOOK[alts.look] then alts.look = "grid" end
    local known = false
    for _, order in ipairs(Contents.ORDERS) do known = known or order.key == alts.sort end
    if not known then alts.sort = "default" end
    alts.scale = Layout.Scale(alts.scale)
    if type(alts.folded) ~= "table" then alts.folded = nil end
    return alts
end

-- The sidebar folded to its narrow edge (kept.side false) or unfolded.
function Alts.Fold(on)
    kept.side = not on
    rail:Fold(on)
    Alts.Size()
end

-- The wheel over the items: a line of them up or down, never past the ends.
local function Wheel(delta)
    Bags.Wheel(scroll, delta, Side(child:GetWidth() or 0))
end

-- The foot: the level line at the left, the gold at the right (its tooltip every character's).
local function MakeFoot()
    foot = CreateFrame("Frame", nil, body)
    foot:SetPoint("BOTTOMLEFT")
    foot:SetPoint("BOTTOMRIGHT")
    foot:SetHeight(Foot.HEIGHT)
    Bags.Band(foot, "TOP")
    local font, ink = Bags.Fonts().count, ns.Style.INK
    foot.gold = CreateFrame("Frame", nil, foot)
    foot.gold:SetHeight(Foot.HEIGHT)
    foot.gold:SetPoint("RIGHT", -(Bags.INSET + Bags.EDGE), 0)
    foot.gold.text = foot.gold:CreateFontString(nil, "ARTWORK")
    if font then foot.gold.text:SetFontObject(font) end
    foot.gold.text:SetTextColor(ink[1], ink[2], ink[3])
    foot.gold.text:SetPoint("RIGHT")
    foot.gold:SetScript("OnEnter", function(self) ns.Safe("alts", Foot.GoldTip, self) end)
    foot.gold:SetScript("OnLeave", GameTooltip_Hide)
    foot.line = foot:CreateFontString(nil, "ARTWORK")
    if font then foot.line:SetFontObject(font) end
    foot.line:SetTextColor(ink[1], ink[2], ink[3])
    foot.line:SetPoint("LEFT", Bags.INSET + Bags.EDGE, 0)
    foot.line:SetPoint("RIGHT", foot.gold, "LEFT", -Bags.BAR_GAP, 0)
    foot.line:SetJustifyH("LEFT")
    foot.line:SetWordWrap(false)
end

-- The title line as wide as the window: the dropdown of the characters narrower on a narrow one, the count only where
-- there is room for it.
local function BarFit()
    local room = (bar:GetWidth() or 0) - bar.words - Bags.TITLE_MENU - Bags.BAR_GAP
    ns.Roster.menu:SetWidth(math.max(ns.Roster.LEAST, math.min(ns.Roster.WIDTH, room)))
    bar.count:SetShown(room - ns.Roster.WIDTH - Bags.BAR_GAP >= Bags.COUNT_LEAST)
end

-- The bar on the title line: the characters' dropdown after the title's word, how many items, the dropdown View.
local function MakeBar()
    bar = Bags.TitleBar(panel, body)
    local roster = ns.Roster.Build(bar)
    roster:SetPoint("LEFT", bar.words, 0)
    bar:SetScript("OnSizeChanged", ns.Guard(BarFit))
    local menu = ns.Style.Dropdown(bar, Bags.TITLE_MENU, Bags.BAR)
    menu:SetPoint("RIGHT")
    menu:OverrideText(ns.TEXT.bagsView)
    menu:SetupMenu(Menu)
    Alts.menu = menu
    bar.count:ClearAllPoints()
    bar.count:SetPoint("LEFT", roster, "RIGHT", Bags.BAR_GAP, 0)
    bar.count:SetPoint("RIGHT", menu, "LEFT", -Bags.BAR_GAP, 0)
    Alts.bar = bar
end

-- A word in the items' place: what is waited for, what was not found.
local function Said(word)
    local text = body:CreateFontString(nil, "ARTWORK")
    text:SetFontObject(ns.Style.Font("SaneUIAltsWait", 16))
    text:SetTextColor(ns.Style.FAINT[1], ns.Style.FAINT[2], ns.Style.FAINT[3], ns.Style.FAINT[4])
    text:SetPoint("CENTER")
    text:SetText(word)
    text:Hide()
    return text
end

function Alts.Build(made)
    panel = made
    kept = Kept()
    Bags.Store()
    body = CreateFrame("Frame", nil, panel.body)
    body:SetPoint("TOPLEFT")
    body:SetPoint("BOTTOMRIGHT")
    MakeFoot()
    MakeBar()
    local top = CreateFrame("Frame", nil, body) -- the sidebar's top hangs on this mark of no height
    top:SetPoint("BOTTOMLEFT", body, "TOPLEFT")
    top:SetSize(1, 1)
    rail = ns.Sidebars.New(body, top, foot, {
        word = Alts.TEXT.storage,
        choose = function(view) Choose(view) end,
        menu = function(row) if row.key or row.group then ns.Menus.Row(row, row.key, row.group) end end,
        aim = ns.BagSidebar.Aim,
        place = ns.BagSidebar.Place,
        fold = function(on) Alts.Fold(on) end,
    })
    rail:Fold(kept.side == false)
    side = rail.frame
    Alts.rail = rail
    columns = Columns.Build(body, function() ns.Safe("alts", Refresh, true) end)
    scroll = CreateFrame("ScrollFrame", nil, body)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta) ns.Safe("alts", Wheel, delta) end)
    child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)
    cells = ns.Cells.New(child, Alts, ns.Items.Button)
    canvas = Canvas.New(child, { store = kept, redraw = function() ns.Safe("alts", Refresh, true) end, cells = cells })
    doll = ns.Items.MakeDoll(child)
    Arrange()
    body.wait = Said(Alts.TEXT.loading)
    body.none = Said(Alts.TEXT.none)
    Alts.body, Alts.foot, Alts.cells, Alts.canvas, Alts.doll, Alts.columns = body, foot, cells, canvas, doll, columns
    Core.Data.OnCharacters(Changed)
end

function Alts.Show(on)
    shown = on
    for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
        if on then Core.On(event, Learned) else Core.Off(event, Learned) end
    end
    if on then
        Refresh(true)
    else
        rail:Cancel()
    end
end

-- The panel's body is that wide (nil: as it was): the items in the room the sidebar leaves.
function Alts.Size(w, h)
    if w then width = ns.Board.Body("alts", w, h or 0) end
    if not child then return end
    child:SetWidth(math.max(1, width - rail:Width() - Bags.EDGE - Bags.RIGHT))
    if kept.look == "list" then columns:Refresh(math.max(1, child:GetWidth() - Bags.INSET)) end
    if shown then Refresh(true) end
end

function Alts.Search(text)
    text = text or ""
    if text == typed then return end
    typed = text
    query = Core.Fuzzy.Query(text)
    if shown then Refresh(false) end
end

-- The board's least: what the title line must hold, the panel's leather round it; the items make themselves smaller to
-- fit (Layout.Fit).
ns.Board.Part("alts", Alts.TEXT.title, ns.Board.Least("alts", Alts.LEAST[1], Alts.LEAST[2]), Alts)
