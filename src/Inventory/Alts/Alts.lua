local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Inventory - Alts
--  Another character's things, in the bags' own window (Bags.lua; Saneroki,
--  2026-11-15: "keep our bags window but add the search and dropdown menu to
--  select other characters to the proper bags window that we had before"):
--  what the account's characters have, as last seen, from Core's data
--  framework (Core.Data.Characters; read only), drawn by the bags' own parts,
--  so it looks and behaves as the bags do:
--      the views    the bags' (Views.lua): by their categories, groups and
--                   order as the player arranged them; All Items, a category
--                   or a group, chosen in the bags' sidebar (which lists them
--                   with this character's counts)
--      the look     the bags' display, Sort By and Item Size (their dropdown
--                   View, store.bags), a canvas of the bags' kind (Canvas.lua)
--                   in the bags' scroll area, with read-only buttons
--                   (Items.Button: the game's tooltip, a modified click links
--                   or tries on, Alt and a right click the item's menu)
--      the places   its bags, its bank as last seen and what it wears, each
--                   under a head; what it wears also as the paper doll below
--                   (Items.lua)
--      the foot     over the bags' own: its level, class and when it was
--                   seen, its gold (every character's in its tooltip)
--
--  The dropdown of the characters on the bags' title line (Roster.lua) chooses
--  (Alts.Choose, Bags.Face). The bags' search box finds an item across them
--  all (Snapshot.lua): the dropdown says how many each has, the window lists
--  only what is found. It listens while it is shown only: to Core's data
--  (Data.OnCharacters) and to the game telling an item's name it did not know.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Alts = {}
ns.Alts = Alts

-- The window's words; the game's own where it has them.
local DAYS = Core.Word("LASTONLINE_DAYS", "%d |4day:days;")
Alts.TEXT = {
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
}

Alts.NAMES = 0.2     -- names the game tells (by the hundred at a search's first look): drawn together, this much later
-- What the bags' views show of a character's things: no Pinned or Recent, no slots to put items into, every item once.
Alts.PLAIN = { showPinned = false, showRecent = false, plus = false, merge = false }

local Bags, Foot, Views, Contents = ns.Bags, ns.Foot, ns.Views, ns.Contents

local child, canvas, cells, doll, foot, note
local shown           -- whose things are shown (a character's key), nil: none
local about           -- the character the heads are for
local store = { blocks = {}, entries = {} } -- Views' blocks for these things
local how = { alt = true }                  -- how a cell is drawn (Cells.Draw): another character's
local NOTHING = { count = 0 }

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

-- The foot: the level line and when it was seen, its gold.
local function Footing(key)
    local who = key ~= ns.Snapshot.ACCOUNT and Core.Data.Character(key)
    if not who then
        foot.line:SetText("")
        foot.gold.text:SetText("")
        return
    end
    local seen = key == Core.charKey and Alts.TEXT.now or Seen(who.seen) or Alts.TEXT.unseen
    foot.line:SetText(Level(who) .. "  |c" .. ns.Style.FAINT_HEX .. seen .. "|r")
    foot.gold.text:SetText(type(who.money) == "number" and Core.Coins(who.money) or "")
    foot.gold:SetWidth((foot.gold.text:GetStringWidth() or 0) + 4)
end

-- A place's head, for Items.Sections: its words, the note beside it, what it says without items.
local function Head(which)
    local title = about == ns.Snapshot.ACCOUNT and Alts.TEXT.account or Alts.TEXT[which]
    if which ~= "bank" or about == ns.Snapshot.ACCOUNT then return title, nil, Alts.TEXT.empty end
    local who = Core.Data.Character(about)
    local seen = who and Seen(who.bankSeen)
    return title, seen, seen and Alts.TEXT.empty or Alts.TEXT.bankUnseen
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

-- This character's things drawn in the bags' scroll area (Bags.lua's Draw): the view chosen in the bags' sidebar
-- (All Items, "cat:<key>", "group:<group>"), only what query finds (Fuzzy.Query's words, nil: all), in a room so wide,
-- the bags' cells' choices (bags: their how), the items size large. Returns the height they take, how many items are
-- shown, and how many each category and group holds unsearched (the sidebar's counts: Items.Counts).
function Alts.Draw(key, view, query, room, bags, size)
    about = key
    local characters = ns.Snapshot.Characters()
    if not characters then -- Core's data not loaded yet
        Alts.Clear()
        note:SetText(Alts.TEXT.loading)
        note:Show()
        return 1, 0, { total = 0, places = {} }
    end
    Footing(key)
    local searching = query ~= nil
    local filtered = view ~= Views.ALL
    local sections, worn = ns.Items.Sections(ns.Snapshot.Sections(key, query), Head, searching, nil, filtered)
    local blocks = Views.Build(view, sections, searching and Contents.FOUND or nil, canvas.owner.store.sort, Alts.PLAIN, store)
    Tidy(blocks, searching or filtered)
    how.coin, how.grey, how.level = bags.coin, bags.grey, bags.level
    local height = canvas:Draw(blocks, room, how, size)
    if worn then
        doll:ClearAllPoints()
        doll:SetPoint("TOPLEFT", child, "TOPLEFT", ns.Canvas.INSET, -height)
        doll:SetSize(room - ns.Canvas.INSET, ns.Items.DOLL_HEIGHT)
        ns.Items.DrawDoll(doll, worn, room - ns.Canvas.INSET)
        height = height + ns.Items.DOLL_HEIGHT
    else
        doll:Hide()
    end
    local items = 0
    for index = 1, blocks.count do items = items + #blocks[index].entries end
    note:SetText(Alts.TEXT.none)
    note:SetShown(searching and blocks.count == 0 and not worn)
    return height, items, ns.Items.Counts(ns.Snapshot.Sections(key, nil))
end

-- The scroll area holds the bags' own again: these things gone from it.
function Alts.Clear()
    if not canvas then return end
    canvas:Draw(NOTHING, math.max(1, child:GetWidth() or 1), how)
    doll:Hide()
    note:Hide()
end

-- Core's data changed, a choice in another window, or the game told a name the window waits for: drawn anew a frame
-- later (names Alts.NAMES later), once however many come at once; while none are shown, nothing.
local Later = Core.Later(function() ns.Safe("alts", Bags.Redraw) end)
local Named = Core.Later(function() ns.Safe("alts", Bags.Redraw) end, Alts.NAMES)
local function Changed()
    if shown then Later() end
end
Alts.Changed = Changed

local function Learned(item)
    if ns.Snapshot.Learned(Core.Plain(item)) and shown then Named() end
end

-- The player chose whose things to show (the dropdown): the bags' window shows them (Bags.Face), the bags as they
-- are for the one logged in.
function Alts.Choose(key)
    Bags.Face(key)
end

-- Whose things are shown from now on (Bags.Face; nil: none): their foot over the bags', listening while shown.
function Alts.Show(key)
    local was = shown
    shown = key
    if foot then foot:SetShown(key ~= nil) end
    if (was ~= nil) == (key ~= nil) then return end
    for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
        if key then Core.On(event, Learned) else Core.Off(event, Learned) end
    end
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

-- The foot over the bags' own (under: theirs), as high: the level line at the left, the gold at the right (its
-- tooltip every character's).
local function MakeFoot(body, under)
    foot = CreateFrame("Frame", nil, body)
    foot:SetAllPoints(under)
    foot:SetFrameLevel(under:GetFrameLevel() + 2)
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
    foot:Hide()
end

-- Built with the bags' window (Bags.Build): a canvas in its scroll area's child (made), the read-only buttons, the
-- doll; the foot over the bags' (under) in their body; the word in the items' place (what is waited for, what was
-- not found). bags: the bags' store (store.bags: the display, the order, the folded categories).
function Alts.Build(made, body, under, bags)
    child = made
    cells = ns.Cells.New(child, Alts, ns.Items.Button)
    canvas = ns.Canvas.New(child, { store = bags, redraw = function() ns.Safe("alts", Bags.Redraw) end, cells = cells })
    doll = ns.Items.MakeDoll(child)
    MakeFoot(body, under)
    note = child:GetParent():CreateFontString(nil, "ARTWORK")
    note:SetFontObject(ns.Style.Font("SaneUIAltsWait", 16))
    note:SetTextColor(ns.Style.FAINT[1], ns.Style.FAINT[2], ns.Style.FAINT[3], ns.Style.FAINT[4])
    note:SetPoint("CENTER")
    note:Hide()
    Alts.canvas, Alts.cells, Alts.doll, Alts.foot, Alts.note = canvas, cells, doll, foot, note
    Core.Data.OnCharacters(Changed)
end

-- Another profile came into use: the bags' store it keeps (Bags.Reload).
function Alts.Use(bags)
    if canvas then canvas.owner.store = bags end
end
