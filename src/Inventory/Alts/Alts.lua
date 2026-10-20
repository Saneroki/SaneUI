local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Alts
--  The window of the other characters on the module's full screen (Board.lua,
--  the key "alts"): what the account's characters have, as last seen, from
--  Core's data framework (Core.Data.Characters; read only). The roster down the
--  left chooses whose things are shown (Roster.lua); the rest of the window
--  shows them: a head with the name, level, class, gold and the day it was
--  last seen, then its bags, its bank and what it wears (Items.lua).
--
--  Every character of the account is in the roster, the one logged in first
--  (its bank as last seen is worth a look away from the bank too). Shown at
--  first: the first of the others by name; the one logged in when there is no
--  other. The choice holds until the next /reload.
--
--  The full window's search box finds an item across them all (Snapshot.lua):
--  the roster says how many each has, the window lists only what is found, and
--  if the chosen character has none of it, the first that has is shown until
--  the search is cleared. It listens while its panel is shown only: to Core's
--  data (Data.OnCharacters) and to the game telling an item's name it did not
--  know; a change while hidden is drawn when it is shown again.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Alts = {}
ns.Alts = Alts

-- The window's words; the game's own where it has them.
local DAYS = Core.Word("LASTONLINE_DAYS", "%d |4day:days;")
Alts.TEXT = {
    title = "Characters",
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

Alts.ROSTER_GAP = 16 -- between the roster and the items, its scroll bar in it
Alts.HEAD = 46       -- the head over the items: the name, the level line
Alts.ROWS = 5        -- the grid's rows the window has room for at least
local EDGE = Core.Board.EDGE -- from the panel's edge to what is in it

local body, head
local chosen          -- the key of the character the player chose (nil: the first choice, Default)
local query, typed    -- the search: Fuzzy.Query's words (nil: none), and what was typed
local shown = false
local width = 0       -- the items' width the grid was laid out for

-- Seen: "Seen today", "Seen 3 days ago"; nil for a day not known.
local function Seen(day)
    local ago = ns.Snapshot.Ago(day)
    if not ago then return nil end
    if ago == 0 then return Alts.TEXT.today end
    return Alts.TEXT.ago:format(DAYS:format(ago))
end

-- A class's name in the player's language.
local function ClassName(class)
    local names = rawget(_G, "LOCALIZED_CLASS_NAMES_MALE")
    return names and class and names[class] or class or ""
end

local function Level(who)
    local colours = rawget(_G, "RAID_CLASS_COLORS")
    local colour = colours and who.class and colours[who.class]
    return Alts.TEXT.level:format(who.level or "?", colour and colour.colorStr or "ffffffff", ClassName(who.class))
end

-- The lines of a character's tooltip in the roster: { text, r, g, b }.
function Alts.About(who)
    if who.key == ns.Snapshot.ACCOUNT then return { { Alts.TEXT.account, 1, 1, 1 } } end
    local r, g, b = ns.Roster.Colour(who.class)
    local lines = { { who.name or "?", r, g, b }, { Level(who), 1, 1, 1 } }
    if who.realm then lines[#lines + 1] = { who.realm, 0.5, 0.5, 0.5 } end
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

-- The head over the items: the name in its class's colour, its gold, the level line and when it was seen.
local function Head(key)
    if key == ns.Snapshot.ACCOUNT then
        head.name:SetText(Alts.TEXT.account)
        head.name:SetTextColor(1, 1, 1)
        head.gold:SetText("")
        head.line:SetText("")
        return
    end
    local who = Core.Data.Character(key)
    if not who then return end
    head.name:SetText(who.name or "?")
    head.name:SetTextColor(ns.Roster.Colour(who.class))
    head.gold:SetText(type(who.money) == "number" and Core.Coins(who.money) or "")
    local seen = key == Core.charKey and Alts.TEXT.now or Seen(who.seen) or Alts.TEXT.unseen
    head.line:SetText(Level(who) .. "  |cff808080" .. seen .. "|r")
end

-- A place's head, for Items.Elements: its words, the note beside it, what it says without items.
local about -- the character the heads are for
local function Place(place)
    local title = about == ns.Snapshot.ACCOUNT and Alts.TEXT.account or Alts.TEXT[place]
    if place ~= "bank" or about == ns.Snapshot.ACCOUNT then return title, nil, Alts.TEXT.empty end
    local who = Core.Data.Character(about)
    local seen = who and Seen(who.bankSeen)
    return title, seen, seen and Alts.TEXT.empty or Alts.TEXT.bankUnseen
end

-- Everything drawn as it is now; keep: the lists stay where they were scrolled to.
local function Refresh(keep)
    local characters = ns.Snapshot.Characters()
    body.wait:SetShown(characters == nil)
    if not characters then
        ns.Roster.Show({}, nil, nil)
        ns.Items.Show({})
        head:Hide()
        return
    end
    local counts
    if query then
        counts = {}
        for _, who in ipairs(characters) do counts[who.key] = ns.Snapshot.Found(who.key, query) end
    end
    local key = Whose(characters, counts)
    ns.Roster.Show(characters, key, counts)
    head:SetShown(key ~= nil)
    if not key then
        ns.Items.Show({})
        return
    end
    Head(key)
    about = key
    local elements = ns.Items.Elements(ns.Snapshot.Sections(key, query), Place, query ~= nil)
    if query and #elements == 0 then elements[1] = { kind = "note", text = Alts.TEXT.none } end
    ns.Items.Show(elements, keep)
end
Alts.Refresh = Refresh

-- Core's data changed, or the game told a name the window waits for: drawn anew a frame later, once
-- however many come at once; while hidden, nothing (it is drawn when shown).
local Later = Core.Later(function() ns.Safe("alts", Refresh, true) end)
local function Changed()
    if shown then Later() end
end

local function Learned(item)
    if ns.Snapshot.Learned(Core.Plain(item)) then Changed() end
end

-- The player chose whose things to show (a click in the roster).
function Alts.Choose(key)
    chosen = key
    ns.Safe("alts", Refresh, false)
end

-------------------------------------------------------------------------------
--  The part (Board.lua)
-------------------------------------------------------------------------------
function Alts.Build(made)
    local panel = made
    body = CreateFrame("Frame", nil, panel.body)
    body:SetPoint("TOPLEFT", EDGE, -EDGE)
    body:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    local roster = CreateFrame("Frame", nil, body)
    roster:SetPoint("TOPLEFT")
    roster:SetPoint("BOTTOMLEFT")
    roster:SetWidth(ns.Roster.WIDTH)
    ns.Roster.Build(roster)

    local right = CreateFrame("Frame", nil, body)
    right:SetPoint("TOPLEFT", roster, "TOPRIGHT", Alts.ROSTER_GAP, 0)
    right:SetPoint("BOTTOMRIGHT")
    head = CreateFrame("Frame", nil, right)
    head:SetPoint("TOPLEFT")
    head:SetPoint("TOPRIGHT")
    head:SetHeight(Alts.HEAD)
    head.name = head:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    head.name:SetPoint("TOPLEFT", 2, -4)
    head.gold = head:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    head.gold:SetPoint("TOPRIGHT", -2, -6)
    head.name:SetPoint("RIGHT", head.gold, "LEFT", -8, 0)
    head.name:SetJustifyH("LEFT")
    head.name:SetWordWrap(false)
    head.line = head:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    head.line:SetPoint("TOPLEFT", head.name, "BOTTOMLEFT", 0, -4)
    head.line:SetJustifyH("LEFT")
    local items = CreateFrame("Frame", nil, right)
    items:SetPoint("TOPLEFT", head, "BOTTOMLEFT")
    items:SetPoint("BOTTOMRIGHT")
    ns.Items.Build(items)

    body.wait = body:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    body.wait:SetPoint("CENTER")
    body.wait:SetText(Alts.TEXT.loading)
    body.wait:Hide()
    Alts.body, Alts.head = body, head
    Core.Data.OnCharacters(Changed)
end

function Alts.Show(on)
    shown = on
    for _, event in ipairs({ "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT" }) do
        if on then Core.On(event, Learned) else Core.Off(event, Learned) end
    end
    if on then Refresh(true) end
end

-- The panel's body is that wide: the grid as many items wide as fit (the roster, its gap and the scroll
-- bar left out).
function Alts.Size(w)
    local inner = w - 2 * EDGE - ns.Roster.WIDTH - Alts.ROSTER_GAP - ns.Items.BAR
    if inner == width then return end
    width = inner
    if ns.Items.Fit(inner) and shown then Refresh(true) end
end

function Alts.Search(text)
    text = text or ""
    if text == typed then return end
    typed = text
    query = Core.Fuzzy.Query(text)
    if shown then Refresh(false) end
end

-- The board's least: the roster, the gap, a grid six items wide with its scroll bar, a few rows of it under
-- the head, the panel's head and edges.
local step = ns.Items.SIZE + ns.Items.GAP
ns.Board.Part("alts", Alts.TEXT.title, {
    ns.Roster.WIDTH + Alts.ROSTER_GAP + 6 * step + ns.Items.BAR + 2 * EDGE,
    Alts.HEAD + ns.Items.HEAD + Alts.ROWS * step + Core.Board.HEAD + 2 * EDGE,
}, Alts)
