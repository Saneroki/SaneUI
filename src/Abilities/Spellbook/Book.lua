local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Book
--  Our own spellbook, a window on the full screen (Board.lua: the part
--  spellbook), that looks and works as the game's own book in this client
--  (Blizzard_PlayerSpells: SpellBook/Blizzard_SpellBookFrame.xml and .lua, the
--  Camelot templates and SpellBookFrame overrides):
--    - the open book at the game's size, 1612 x 702, its two pages in the
--      game's art (spellbook-Page-Left-C60, -Right-C60), scaled to fit its
--      panel (never larger than it is) and centred; one page, 806 wide, where
--      the panel is too narrow for both at a good size (the game's book
--      minimized)
--    - an icon tab per skill line, and the pet's (Data.lua), at the top left,
--      in the game's square tabs (spellbook-Tab-Frame-C60), with the skill
--      line's name as their tooltip and the game's sound
--    - the pages: each tab's spells under its heading, laid out by the game's
--      rules (Layout.lua), an entry each (Item.lua); the game's own paging
--      controls (PagingControlsHorizontalTemplate) at the bottom right, the
--      mouse wheel paging as in the game's book
--    - the game's settings at the top right: Hide passives, and Show all ranks
--      (not for rogues and warriors), the game's own options (its CVars), so
--      both books show alike
--    - the full window's search box finds spells of every tab (Data.Search)
--  A click casts out of a fight, by the game's secure buttons over the icons
--  (Casts.lua); a drag puts a spell on an action bar, as in the game's book.
--
--  What a module offers beyond the game's spells (Core.Spellbook; Saneroki,
--  2026-11-06: Abilities' spells still to learn, its weapon skills, Home and
--  reservations) stands in it too: the offer's entries among the tab's, in
--  frames the offer makes and draws (its look, tooltip, drag and clicks), no
--  secure button over them; its Home tab first, whose page the offer draws on
--  the book's views (a pane of ours, shown only while Home is chosen), the book
--  opening on it while the offer says so; its lines in the settings menu; its
--  switch beside the page controls. It is drawn anew whenever the offer says
--  it changed (Core.Spellbook.Watch).
--
--  Events only while it is shown, a burst laid out once (Core.Later): what the
--  book holds anew on SPELLS_CHANGED, LEARNED_SPELL_IN_SKILL_LINE, the pet
--  changing; the entries on the page anew on cooldowns, shapeshift forms, the
--  action bars and the cursor changing, and the pet's autocast.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Data, Layout, Item, Casts = ns.SpellbookData, ns.SpellbookLayout, ns.SpellbookItem, ns.SpellbookCasts
local Book = {}
ns.Spellbook = Book

-- The game's sizes and places (Camelot/Blizzard_PlayerSpellsFrame.xml, SpellBook templates).
Book.WIDE, Book.NARROW, Book.HIGH = 1612, 806, 702
Book.TWO = 0.85 -- both pages, while they can be at least this share of one page's size in the panel
Book.PAGES_TOP = -50
Book.VIEW_LEFT, Book.VIEW_RIGHT, Book.VIEW_TOP = 85, -50, -45
Book.TABS = { 70, -26 }
Book.TAB_WIDTH, Book.TAB_HEIGHT, Book.TAB_ICON = 44, 32, { 36, 35 } -- a square tab: its icon and 8 beside
Book.SETTINGS = { -30, -27 }
Book.PAGER = { -75, 40 }
Book.HEADER = { text = { -8, 14, -60 }, border = { -32, -60, 11 }, plate = { 416, 106, -77, -4 } }
Book.LEVEL = 30 -- the secure buttons above the panel they stand over

Book.TEXT = {
    passives = Core.Word("SPELLBOOK_FILTER_PASSIVES", "Hide Passives"),
    ranks = Core.Word("SHOW_ALL_SPELL_RANKS", "Show All Spell Ranks"),
    none = "Nothing found.",
}

local holder, pages, views, pager, row, settings, empty, body -- what is built once (Build)
local homePane, homeSurface, toggle                           -- the offer's Home page and its switch (Build)
local tabs, chosen, search = {}, nil, ""                       -- the tabs there are, the one shown, the search
local spreads = {}                                             -- the views of what is shown (Layout.Split)
local two = true                                               -- both pages, or one
local shown = false
local items, headers, buttons, futures                         -- pools: entries, headings, tab buttons, the offer's

local function Colour(name, r, g, b)
    local colour = rawget(_G, name)
    if type(colour) == "table" and colour.GetRGB then return colour:GetRGB() end
    return r, g, b
end

local function PerPage()
    return two and 2 or 1
end

local function Pages()
    return math.max(math.ceil(#spreads / PerPage()), 1)
end

-- The offer's Home is the page shown: its tab chosen, no search on.
local function OnHome()
    return search == "" and chosen == "home"
end

-------------------------------------------------------------------------------
--  The page shown
-------------------------------------------------------------------------------
local function MakeHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    local spec = Book.HEADER
    local text = header:CreateFontString(nil, "ARTWORK", "SystemFont_Huge2")
    text:SetJustifyH("LEFT")
    text:SetPoint("LEFT", spec.text[1], spec.text[2])
    text:SetPoint("RIGHT", spec.text[3], spec.text[2])
    text:SetTextColor(Colour("SPELLBOOK_FONT_COLOR", 0.24, 0.15, 0.06))
    local border = header:CreateTexture(nil, "ARTWORK")
    border:SetAtlas("spellbook-divider")
    border:SetHeight(spec.border[3])
    border:SetPoint("BOTTOMLEFT", spec.border[1], 0)
    border:SetPoint("BOTTOMRIGHT", spec.border[2], 0)
    local plate = header:CreateTexture(nil, "BACKGROUND")
    plate:SetAtlas("spellbook-list-backplate")
    plate:SetAlpha(0.65)
    plate:SetSize(spec.plate[1], spec.plate[2])
    plate:SetPoint("LEFT", text, "LEFT", spec.plate[3], spec.plate[4])
    header.Text = text
    return header
end

-- A heading for the offer's Home page, in the book's look, as wide as a view.
local function HomeHeader(parent)
    local header = MakeHeader(parent)
    header:SetSize(Layout.WIDTH, Layout.HEADER)
    header:Hide()
    return header
end

-- A frame of the offer's for one of its entries; a blank one where it makes none (its module stood down meanwhile).
local function MakeFuture()
    local offer = Core.Spellbook.Offer()
    return offer and offer.Make and offer.Make(holder) or CreateFrame("Frame", nil, holder)
end

-- The offer's switch beside the page controls, as it is now: not on Home.
local function Switch()
    if not toggle then return end
    local offer = Core.Spellbook.Offer()
    local switch = offer and offer.Switch
    toggle:SetShown(switch ~= nil and not OnHome())
    if switch then
        toggle.Text:SetText(switch.text or "")
        toggle:SetChecked(switch.On() and true or false)
    end
end

-- The secure buttons over the entries the page shows, above the panel (out of a fight).
local function Cover()
    if not (shown and body) then return Casts.Clear() end
    local list = {}
    for index = 1, items.taken do list[index] = items[index] end
    Casts.Cover(list, body:GetFrameStrata(), body:GetFrameLevel() + Book.LEVEL)
end
local Recover = Core.Later(function() ns.Safe("spellbook", Cover) end) -- once the page stands where it goes

-- The views of a page in the book's views, each element in its place; or the offer's Home on them.
local function ShowPage()
    if not holder then return end
    local page = pager and pager:GetCurrentPage() or 1
    local offer = Core.Spellbook.Offer()
    items:Begin()
    headers:Begin()
    futures:Begin()
    for index = 1, 2 do
        local view = views[index]
        view:SetShown(index <= PerPage())
        local spread = index <= PerPage() and spreads[(page - 1) * PerPage() + index]
        if spread then
            Layout.Place(spread)
            for _, element in ipairs(spread) do
                local frame
                local future = element.kind == "entry" and element.data.future
                if element.kind == "header" then
                    frame = headers:Take()
                    frame.Text:SetText(element.data.text or "")
                elseif future then
                    if offer and offer.Set then frame = futures:Take() end
                elseif element.kind == "entry" then
                    frame = items:Take()
                end
                if frame then
                    frame:SetParent(view)
                    frame:ClearAllPoints()
                    frame:SetPoint("TOPLEFT", view, "TOPLEFT", element.x, -element.y)
                    frame:SetSize(element.width, element.height)
                    frame:Show()
                    if future then
                        offer.Set(frame, future, element.width)
                    elseif element.kind == "entry" then
                        Item.Set(frame, element.data)
                    end
                end
            end
        end
    end
    items:Done()
    headers:Done()
    futures:Done()
    local home = OnHome() and offer and offer.Home
    homePane:SetShown(home and true or false)
    if home then
        homeSurface = homeSurface or home.Surface(homePane, HomeHeader)
        if homeSurface then home.Draw(homeSurface, views[1], PerPage() == 2 and views[2] or nil) end
    end
    empty:SetShown(not home and (#spreads == 0 or (#spreads == 1 and #spreads[1] == 0)))
    if pager then pager:SetShown(not home) end
    Switch()
    Recover()
end

-- What the book shows: the chosen tab's spells, or what the search finds in every tab.
local function Fill(keepPage)
    tabs = Data.Tabs()
    local tab
    for _, each in ipairs(tabs) do
        if each.key == chosen then tab = each end
    end
    if not tab then
        tab = tabs[1]
        chosen = tab and tab.key or nil
        keepPage = false
    end
    local groups
    if search ~= "" then
        groups = Data.Search(tabs, search)
    elseif tab and tab.home then
        groups = {} -- the offer's Home draws its own page (ShowPage)
    else
        groups = tab and Data.Groups(tab, tabs) or {}
    end
    spreads = #groups > 0 and Layout.Split(groups) or {}
    Book.Tabs()
    if pager then
        local page = keepPage and pager:GetCurrentPage() or 1
        pager:SetMaxPages(Pages())
        pager.currentPage = math.min(page, Pages()) -- set without its callback: the page is drawn just below
        pager:UpdateControls()
    end
    ShowPage()
end
local Refill = Core.Later(function() ns.Safe("spellbook", Fill, true) end)

-- The entries on the page anew, where something of theirs changed (a cooldown, the bars, a form).
local function Touch(what)
    for index = 1, items.taken do
        local item = items[index]
        if what == "cooldown" then Item.Cooldown(item)
        elseif what == "icon" then Item.Icon(item)
        elseif what == "autocast" then Item.AutoCast(item)
        else Item.Status(item) end
    end
end
local Cooldowns = Core.Later(function() ns.Safe("spellbook", Touch, "cooldown") end)
local Statuses = Core.Later(function() ns.Safe("spellbook", Touch, "status") end)
local Icons = Core.Later(function() ns.Safe("spellbook", Touch, "icon") end)
local AutoCasts = Core.Later(function() ns.Safe("spellbook", Touch, "autocast") end)

-------------------------------------------------------------------------------
--  The tabs
-------------------------------------------------------------------------------
-- The search left, as the game's book leaves it when a tab is chosen: the full screen's search box emptied too.
local function Unsearch()
    if search == "" then return end
    search = ""
    ns.Screen.ClearSearch()
end

local function Choose(key)
    if key == chosen and search == "" then return end
    chosen = key
    Unsearch()
    local sound = rawget(_G, "SOUNDKIT")
    if sound and sound.IG_SPELLBOOK_OPEN then PlaySound(sound.IG_SPELLBOOK_OPEN) end
    Fill(false)
end

-- The book at that tab ("pet", or a skill line's key), from elsewhere (the pet book's key): the search cleared.
function Book.Choose(key)
    Unsearch()
    chosen = key
    if holder and shown then Fill(false) end
end

-- The tab the book shows ("pet", or a skill line's key); nil while it shows what a search found.
function Book.Chosen()
    if search ~= "" then return nil end
    return chosen
end

local TabClick = ns.Guard(function(tab) if tab.key then Choose(tab.key) end end)
local TabEnter = ns.Guard(function(tab)
    if not tab.name then return end
    GameTooltip:SetOwner(tab, "ANCHOR_RIGHT", -12, -6)
    GameTooltip:SetText(tab.name, 1, 1, 1)
    if tab.tip then GameTooltip:AddLine(tab.tip, nil, nil, nil, true) end
    GameTooltip:Show()
end)
local TabLeave = ns.Guard(function(tab) if GameTooltip:GetOwner() == tab then GameTooltip:Hide() end end)

-- A square tab of the game's (TabSystemButtonArtMixin:SetSquareMode): its frame, lit when chosen, the icon.
local function Tab(_, index)
    local tab = CreateFrame("Button", nil, row)
    tab:SetSize(Book.TAB_WIDTH, Book.TAB_HEIGHT)
    local frame = tab:CreateTexture(nil, "ARTWORK", nil, 1)
    frame:SetAtlas("spellbook-Tab-Frame-C60", true)
    frame:SetPoint("BOTTOM", 0, 1)
    local lit = tab:CreateTexture(nil, "ARTWORK", nil, 1)
    lit:SetAtlas("spellbook-Tab-Frame-Glow-C60", true)
    lit:SetPoint("BOTTOM", 0, 1)
    local glow = tab:CreateTexture(nil, "ARTWORK", nil, 1)
    glow:SetAtlas("spellbook-Tab-Frame-glow-gradient-C60", true)
    glow:SetPoint("BOTTOM", 0, 0)
    local icon = tab:CreateTexture(nil, "ARTWORK")
    icon:SetSize(Book.TAB_ICON[1], Book.TAB_ICON[2])
    icon:SetPoint("CENTER")
    local mask = tab:CreateMaskTexture()
    mask:SetAtlas("SquareMask")
    mask:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, -2)
    mask:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 0)
    icon:AddMaskTexture(mask)
    tab.Frame, tab.Lit, tab.Glow, tab.Icon = frame, lit, glow, icon
    tab:SetPoint("TOPLEFT", row, "TOPLEFT", (index - 1) * Book.TAB_WIDTH, 0)
    tab:SetMotionScriptsWhileDisabled(true) -- the chosen tab, disabled, still says its name
    tab:SetScript("OnClick", TabClick)
    tab:SetScript("OnEnter", TabEnter)
    tab:SetScript("OnLeave", TabLeave)
    return tab
end

function Book.Tabs()
    if not buttons then return end
    buttons:Begin()
    for _, each in ipairs(tabs) do
        local tab = buttons:Take()
        tab.key, tab.name, tab.tip = each.key, each.name, each.tip
        tab.Icon:SetTexture(each.icon)
        local on = search == "" and each.key == chosen
        tab.Frame:SetShown(not on)
        tab.Lit:SetShown(on)
        tab.Glow:SetShown(on)
        tab:SetEnabled(not on)
        tab:Show()
    end
    buttons:Done()
end

-------------------------------------------------------------------------------
--  The game's settings for its book
-------------------------------------------------------------------------------
local function Flip(cvar)
    SetCVar(cvar, GetCVarBool(cvar) and "0" or "1")
    Fill(true)
end
local HidePassives = ns.Guard(function() return GetCVarBool("spellBookHidePassives") end)
local ToggleHidePassives = ns.Guard(function() Flip("spellBookHidePassives") end)
local AllRanks = ns.Guard(function() return GetCVarBool("ShowAllSpellRanks") end)
local ToggleAllRanks = ns.Guard(function() Flip("ShowAllSpellRanks") end)

-- The game's two, then the offer's lines (Core.Spellbook).
local Menu = ns.Guard(function(_, root)
    root:CreateCheckbox(Book.TEXT.passives, HidePassives, ToggleHidePassives)
    local class = Core.class
    if class ~= "ROGUE" and class ~= "WARRIOR" then root:CreateCheckbox(Book.TEXT.ranks, AllRanks, ToggleAllRanks) end
    local offer = Core.Spellbook.Offer()
    if offer and offer.Menu then offer.Menu(root) end
end)

-- The offer's switch: set through the offer, which says when what it shows changed (the book is drawn anew then).
local ToggleClick = ns.Guard(function(box)
    local offer = Core.Spellbook.Offer()
    local switch = offer and offer.Switch
    if not switch then return end
    local on = box:GetChecked() and true or false
    Core.Sound(on and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
    switch.Set(on)
    box:SetChecked(switch.On() and true or false)
end)
local ToggleEnter = ns.Guard(function(box)
    local offer = Core.Spellbook.Offer()
    local switch = offer and offer.Switch
    if not switch then return end
    GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
    GameTooltip:SetText(switch.text or "", 1, 1, 1)
    if switch.tip then GameTooltip:AddLine(switch.tip, nil, nil, nil, true) end
    GameTooltip:Show()
end)
local ToggleLeave = ns.Guard(function(box) if GameTooltip:GetOwner() == box then GameTooltip:Hide() end end)

-------------------------------------------------------------------------------
--  The part
-------------------------------------------------------------------------------
local Book_ = {}

local OnWheel = ns.Guard(function(_, delta)
    if pager then pager:OnMouseWheel(delta) end
end)

function Book_.Build(panel)
    body = panel.body
    holder = CreateFrame("Frame", nil, body)
    holder:SetSize(Book.WIDE, Book.HIGH)
    holder:SetPoint("CENTER")
    local left = holder:CreateTexture(nil, "BACKGROUND", nil, 1)
    left:SetAtlas("spellbook-Page-Left-C60")
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMRIGHT", holder, "BOTTOM")
    local right = holder:CreateTexture(nil, "BACKGROUND", nil, 1)
    right:SetAtlas("spellbook-Page-Right-C60")
    right:SetPoint("TOPLEFT", holder, "TOP")
    right:SetPoint("BOTTOMRIGHT")
    local halved = holder:CreateTexture(nil, "BACKGROUND", nil, 1)
    halved:SetAtlas("spellbook-Page-Right-C60")
    halved:SetAllPoints()
    halved:Hide()
    holder.Left, holder.Right, holder.Halved = left, right, halved

    row = CreateFrame("Frame", nil, holder)
    row:SetSize(1, Book.TAB_HEIGHT)
    row:SetPoint("TOPLEFT", Book.TABS[1], Book.TABS[2])

    pages = CreateFrame("Frame", nil, holder)
    pages:SetPoint("TOPLEFT", 0, Book.PAGES_TOP)
    pages:SetPoint("BOTTOMRIGHT")
    pages:EnableMouseWheel(true)
    pages:SetScript("OnMouseWheel", OnWheel)
    views = {}
    for index = 1, 2 do
        local view = CreateFrame("Frame", nil, pages)
        view:SetSize(Layout.WIDTH, Layout.HEIGHT)
        if index == 1 then
            view:SetPoint("TOPLEFT", Book.VIEW_LEFT, Book.VIEW_TOP)
        else
            view:SetPoint("TOPRIGHT", Book.VIEW_RIGHT, Book.VIEW_TOP)
        end
        views[index] = view
    end
    empty = pages:CreateFontString(nil, "ARTWORK", "SystemFont_Large")
    empty:SetPoint("TOP", views[1], "TOP", 0, -60)
    empty:SetTextColor(Colour("SPELLBOOK_FONT_COLOR", 0.24, 0.15, 0.06))
    empty:SetText(Book.TEXT.none)
    empty:Hide()

    -- The game's own paging controls: they ask the frame they stand in to show the page (OnPageChanged). Only with their
    -- code (PagingControlsMixin): a template there without it (the interface lab, a client that changed) leaves the book
    -- without controls, its first page shown, rather than failing at every page.
    local ok, controls = pcall(CreateFrame, "Frame", nil, pages, "PagingControlsHorizontalTemplate")
    if ok and controls and not controls.UpdateControls then controls:Hide() end
    if ok and controls and controls.UpdateControls then
        controls:SetPoint("BOTTOMRIGHT", Book.PAGER[1], Book.PAGER[2])
        controls.spacing = 8
        if controls.PageText then
            controls.PageText:SetFontObject("SystemFont_Med3")
            controls.PageText:SetTextColor(Colour("SPELLBOOK_FONT_COLOR", 0.24, 0.15, 0.06))
        end
        local sound = rawget(_G, "SOUNDKIT")
        controls.prevPageSound = sound and sound.IG_ABILITY_PAGE_TURN
        controls.nextPageSound = sound and sound.IG_ABILITY_PAGE_TURN
        pages.OnPageChanged = ns.Guard(function() ShowPage() end)
        pager = controls
        pager:UpdateControls()
        -- The offer's switch, left of the controls, its words left of its box (shown while there is one: Switch).
        local made, box = pcall(CreateFrame, "CheckButton", nil, pages, "UICheckButtonTemplate")
        if made and box then
            box:SetSize(24, 24)
            box:SetPoint("RIGHT", controls, "LEFT", -14, 0)
            box.Text:ClearAllPoints()
            box.Text:SetPoint("RIGHT", box, "LEFT", -2, 0)
            box.Text:SetFontObject("SystemFont_Med3")
            box.Text:SetTextColor(Colour("SPELLBOOK_FONT_COLOR", 0.24, 0.15, 0.06))
            box:SetScript("OnClick", ToggleClick)
            box:SetScript("OnEnter", ToggleEnter)
            box:SetScript("OnLeave", ToggleLeave)
            box:Hide()
            toggle = box
        end
    else
        ns.Report("spellbook", "this client has no paging controls for addons; the book shows its first page only")
    end

    local ok2, dropdown = pcall(CreateFrame, "DropdownButton", nil, holder, "UIPanelArrowDropdownButtonTemplate")
    if ok2 and dropdown then
        dropdown:SetPoint("TOPRIGHT", Book.SETTINGS[1], Book.SETTINGS[2])
        dropdown:SetupMenu(Menu)
        settings = dropdown
    end

    -- The offer's Home: a pane over the views, its page drawn by the offer (shown only while Home is chosen).
    homePane = CreateFrame("Frame", nil, pages)
    homePane:SetAllPoints(pages)
    homePane:Hide()

    items = Core.Pool(function() return Item.Make(holder) end)
    headers = Core.Pool(function() return MakeHeader(holder) end)
    buttons = Core.Pool(Tab)
    futures = Core.Pool(MakeFuture)
end

-- One page or both: both while they can be at least Book.TWO of one page's size; then scaled to fit the body
-- (Core's board gives the panel's size: its head and edges taken off).
function Book_.Size(width, height)
    if not holder then return end
    local edge = Core.Board.EDGE
    width = (Plain(width) or 0) - 2 * edge
    height = (Plain(height) or 0) - Core.Board.HEAD - 2 * edge
    local one = math.min(1, width / Book.NARROW, height / Book.HIGH)
    local both = math.min(1, width / Book.WIDE, height / Book.HIGH)
    local wasTwo = two
    two = both >= Book.TWO * one
    holder:SetSize(two and Book.WIDE or Book.NARROW, Book.HIGH)
    holder:SetScale(math.max(two and both or one, 0.01))
    holder.Left:SetShown(two)
    holder.Right:SetShown(two)
    holder.Halved:SetShown(not two)
    if two ~= wasTwo and pager then
        -- The same spells stay in sight: the page that holds the first view shown.
        local first = (pager:GetCurrentPage() - 1) * (wasTwo and 2 or 1) + 1
        pager:SetMaxPages(Pages())
        pager.currentPage = math.min(math.floor((first - 1) / PerPage()) + 1, Pages())
        pager:UpdateControls()
    end
    ShowPage()
end

local function Spells() Refill() end
local function Pet(unit) if unit == "player" then Refill() end end
local function Cooldown() Cooldowns() end
local function Bars() Statuses() end
-- The cursor changed: what a drag held is let go, then the glows anew. The event comes inside the game's pickup
-- itself, before a drag marks its entry held (Item.Drag), as the game's book has it.
local function Cursor()
    for index = 1, items and items.taken or 0 do items[index].grabbed = false end
    Statuses()
end
local function Forms() Icons() end
local function PetBar() AutoCasts() Statuses() end
local function Fight() Casts.Fight() end
local function Peace()
    Casts.Peace()
    Recover()
end

local EVENTS = {
    SPELLS_CHANGED = Spells, LEARNED_SPELL_IN_SKILL_LINE = Spells, PLAYER_SPECIALIZATION_CHANGED = Spells,
    UNIT_PET = Pet, SPELL_UPDATE_COOLDOWN = Cooldown, ACTIONBAR_SLOT_CHANGED = Bars, CURSOR_CHANGED = Cursor,
    UPDATE_SHAPESHIFT_FORM = Forms, PET_BAR_UPDATE = PetBar, PLAYER_REGEN_DISABLED = Fight, PLAYER_REGEN_ENABLED = Peace,
}

function Book_.Show(on)
    if on == shown then return end
    shown = on
    for event, fn in pairs(EVENTS) do
        if on then Core.On(event, fn) else Core.Off(event, fn) end
    end
    if on then
        if InCombatLockdown() then Casts.Fight() else Casts.Peace() end
        -- Opened, it shows the offer's Home first while the offer says so (a key's tab is chosen after: Window.lua).
        local offer = Core.Spellbook.Offer()
        local home = offer and offer.Home
        if home and home.First and home.First() and search == "" then chosen = "home" end
        Fill(true)
    else
        Casts.Clear()
        if GameTooltip:IsShown() then GameTooltip:Hide() end
    end
end

function Book_.Search(text)
    text = type(text) == "string" and text or ""
    if text == search then return end
    search = text
    if holder and shown then Fill(false) end
end

-- Whether it is there: in the game whose book it is made after (its art, its flyouts' spells loose in it: Abilities.lua,
-- ns.Serves); in Retail the game's own spellbook stays, and its spellbook and pet book keys open it.
function Book_.Present()
    return ns.Serves("spellbook")
end

function Book_.Leave()
    Book_.Show(false)
    Core.AfterCombat("Abilities: spellbook casts", Casts.Clear)
end

-- What the offer shows changed: drawn anew while the book is shown, else when it is.
Core.Spellbook.Watch(function()
    if holder and shown then Refill() end
end)

Book.Part = Book_
ns.Board.Part("spellbook", ns.TEXT.spellbook, { math.floor(Book.NARROW * 0.4), math.floor(Book.HIGH * 0.4) }, Book_,
    { Book.WIDE, Book.HIGH })
