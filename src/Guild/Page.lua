local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Guild - Page
--  The guild window's page, whichever window it stands in (Window.lua): the
--  head with the guild's crest at its left, the guild's name and realm, how
--  many are online, when the guild's records were last asked for, the gear
--  (the options page Guild) and Sync; the row of the game's tabs, one per
--  section; under them the view's title with a line of context and, where a
--  section has several views, the game's small tabs; the view; at the bottom
--  a status line that says what just happened and fades.
--
--  A view is a table of its file (Views/): Build(frame) the first time it is
--  shown, Show(on), Refresh() when the guild's data changed while it is on
--  show, Title() its context line, Search(text) what is typed into the search.
--  The section and view last chosen are kept.
--
--      Page.Build(parent)   the page in that frame (once; Page.Into moves it)
--      Page.Into(parent)    the page fills that frame now
--      Page.Show(on)        it is on show, or not: it listens to the guild's data only while shown
--      Page.Choose(section, view)   that view on show
--      Page.Status(text)    a line in the status line; false while the page is not on show
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Layout, Kit, TEXT = ns.Layout, ns.Kit, ns.TEXT
local Page = {}
ns.Page = Page
ns.Views = {} -- [key] = a view (Views/), and Views.Later(name) for one still to come

-- Every section and its views, in the order of the tabs. officer: shown only to the guild's officers.
local function Sections()
    local V = ns.Views
    return {
        { key = "overview", text = TEXT.overview, views = { { key = "overview", text = TEXT.overview, view = V.overview } } },
        { key = "guild", text = TEXT.guild, views = {
            { key = "roster", text = TEXT.roster, view = V.roster },
            { key = "equipment", text = TEXT.equipment, view = V.equipment },
            { key = "bank", text = TEXT.bank, view = V.Later(TEXT.bank) },
            { key = "handbook", text = TEXT.handbook, view = V.Later(TEXT.handbook) } } },
        { key = "quests", text = TEXT.quests, views = { { key = "quests", text = TEXT.quests, view = V.Later(TEXT.quests) } } },
        { key = "dungeons", text = TEXT.dungeons, views = {
            { key = "runs", text = TEXT.runs, view = V.Later(TEXT.runs) },
            { key = "together", text = TEXT.together, view = V.Later(TEXT.together) } } },
        { key = "loot", text = TEXT.loot, views = {
            { key = "session", text = TEXT.session, view = V.Later(TEXT.session) },
            { key = "history", text = TEXT.history, view = V.Later(TEXT.history) },
            { key = "wishlist", text = TEXT.wishlist, view = V.Later(TEXT.wishlist) },
            { key = "rules", text = TEXT.rules, view = V.Later(TEXT.rules) } } },
        { key = "professions", text = TEXT.professions, views = { { key = "professions", text = TEXT.professions, view = V.Later(TEXT.professions) } } },
        { key = "raid", text = TEXT.raid, views = {
            { key = "plan", text = TEXT.plan, view = V.Later(TEXT.plan) },
            { key = "numbers", text = TEXT.numbers, view = V.Later(TEXT.numbers) } } },
        { key = "officers", text = TEXT.officers, officer = true, views = {
            { key = "mains", text = TEXT.mains, view = V.Later(TEXT.mains) },
            { key = "promotions", text = TEXT.promotions, view = V.Later(TEXT.promotions) },
            { key = "notices", text = TEXT.notices, view = V.Later(TEXT.notices) } } },
    }
end

local page, sections
local chosen, shownView -- the section's index; the view entry on show
local listening = false

-------------------------------------------------------------------------------
--  The head
-------------------------------------------------------------------------------
local function Head()
    local Guild = Core.Data.Guild
    local info = Guild.Info()
    local inGuild = Core.Ask(rawget(_G, "IsInGuild")) == true
    page.crest:Update()
    page.name:SetText(inGuild and info.name or TEXT.title)
    page.realm:SetText(inGuild and (info.realm and "· " .. info.realm or "") or "")
    page.online:SetText(inGuild and TEXT.online:format(math.max(0, (info.online or 0))) or "")
    page.dot:SetShown(inGuild)
    local peers, newest = Guild.Peers(), nil
    for _, peer in pairs(peers) do
        if not newest or peer.seen > newest then newest = peer.seen end
    end
    local now = Core.Ask(GetServerTime) or 0
    local synced = newest and TEXT.synced:format(Layout.SinceText(now - newest)) or TEXT.neverSynced
    page.synced:SetText(inGuild and synced or "")
    page.sync:SetEnabled(inGuild)
    page.empty:SetShown(not inGuild)
    page.body:SetShown(inGuild)
    page.subs:SetShown(inGuild)
    page.tool:SetShown(inGuild)
    page.viewTitle:SetShown(inGuild)
    page.context:SetShown(inGuild)
    if page.tabs then
        page.tabs:SetShown(inGuild)
        local officer = inGuild and Guild.Rights().officer
        for index, section in ipairs(sections) do
            if section.officer then page.tabs:SetTabShown(index, officer and true or false) end
        end
    end
end

local function BuildHead()
    page.crest = Kit.Crest(page, Layout.CREST)
    page.crest:SetPoint("TOPLEFT", Layout.EDGE, -2)
    page.crest:SetFrameLevel(page:GetFrameLevel() + 20)
    page.name = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    page.name:SetPoint("TOPLEFT", Layout.TAB_LEFT, -8)
    page.realm = page:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    page.realm:SetPoint("LEFT", page.name, "RIGHT", 6, 0)
    page.sync = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    page.sync:SetSize(72, Layout.BUTTON)
    page.sync:SetPoint("TOPRIGHT", -Layout.EDGE, -9)
    page.sync:SetText(TEXT.sync)
    page.sync:SetScript("OnClick", ns.Guard(function()
        Core.Data.Guild.Sync()
        Page.Status(TEXT.syncTip)
    end))
    Core.Tip(page.sync, TEXT.sync, TEXT.syncTip)
    page.gear = CreateFrame("Button", nil, page)
    page.gear:SetSize(Layout.BUTTON, Layout.BUTTON)
    page.gear:SetPoint("RIGHT", page.sync, "LEFT", -6, 0)
    page.gear:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    page.gear:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    page.gear:SetScript("OnClick", ns.Guard(function() Page.Options() end))
    Core.Tip(page.gear, TEXT.settings)
    page.synced = page:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    page.synced:SetPoint("RIGHT", page.gear, "LEFT", -10, 0)
    page.online = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    page.online:SetPoint("RIGHT", page.synced, "LEFT", -12, 0)
    page.dot = page:CreateTexture(nil, "ARTWORK")
    page.dot:SetSize(12, 12)
    page.dot:SetPoint("RIGHT", page.online, "LEFT", -3, 0)
    page.dot:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
end

-- The options page Guild (Core's), or Sane UI's options where the game cannot open it now.
function Page.Options()
    local category = Core.pages and Core.pages[ns.name]
    local settings = rawget(_G, "Settings")
    if not category or InCombatLockdown() or not (settings and settings.OpenToCategory) then return Core.Config.Open() end
    Core.Safe("options", Core.Config.Fill)
    settings.OpenToCategory(category:GetID())
end

-------------------------------------------------------------------------------
--  Tabs and views
-------------------------------------------------------------------------------
local function Context()
    local view = shownView and shownView.view
    local text = view and view.Title and ns.Safe("view", view.Title) or ""
    page.viewTitle:SetText(shownView and shownView.text or "")
    page.context:SetText(text or "")
end

local function SubTabs(section)
    for _, tab in ipairs(page.subTabs) do tab:Hide() end
    local many = #section.views > 1
    page.subs:SetShown(many)
    if not many then return end
    local previous
    for index, entry in ipairs(section.views) do
        local tab = page.subTabs[index]
        if not tab then
            tab = CreateFrame("Button", nil, page.subs, "MinimalTabTemplate")
            tab:SetHeight(Layout.SUB)
            tab:SetScript("OnClick", ns.Guard(function(self)
                Core.Sound("IG_CHARACTER_INFO_TAB")
                Page.Choose(chosen, self.index)
            end))
            page.subTabs[index] = tab
        end
        tab.index = index
        tab.Text:SetText(entry.text)
        tab:SetWidth(math.max(70, tab.Text:GetStringWidth() + 32))
        tab:ClearAllPoints()
        if previous then tab:SetPoint("LEFT", previous, "RIGHT", 2, 0) else tab:SetPoint("BOTTOMLEFT", page.subs, "BOTTOMLEFT", 0, 0) end
        tab:Show()
        previous = tab
    end
end

local function Body(sub)
    page.body:ClearAllPoints()
    page.body:SetPoint("TOPLEFT", Layout.EDGE, -Layout.ViewTop(sub))
    page.body:SetPoint("BOTTOMRIGHT", -Layout.EDGE, Layout.STATUS + 2)
end

-- That view on show: its section's tab chosen, its small tab chosen, built if it never was.
function Page.Choose(index, viewIndex)
    if not page then return end
    local section = sections[index] or sections[1]
    index = sections[index] and index or 1
    if section.officer and not Core.Data.Guild.Rights().officer then return Page.Choose(1) end
    viewIndex = viewIndex or section.last or 1
    local entry = section.views[viewIndex] or section.views[1]
    section.last = viewIndex
    if shownView and shownView ~= entry and shownView.frame then
        shownView.frame:Hide()
        if shownView.view.Show then ns.Safe("view", shownView.view.Show, false) end
    end
    chosen, shownView = index, entry
    if page.tabs then page.tabs:SetTabVisuallySelected(index) end
    SubTabs(section)
    for i, tab in ipairs(page.subTabs) do
        if tab.SetSelected then tab:SetSelected(i == viewIndex) end
    end
    Body(#section.views > 1)
    if not entry.frame then
        entry.frame = CreateFrame("Frame", nil, page.body)
        entry.frame:SetAllPoints()
        if entry.view.Build then ns.Safe("view: " .. entry.key, entry.view.Build, entry.frame) end
    end
    entry.frame:Show()
    if entry.view.Show then ns.Safe("view: " .. entry.key, entry.view.Show, true) end
    Context()
    ns.store.section, ns.store.view = section.key, entry.key
end

local function Tabs()
    local ok, row = pcall(CreateFrame, "Frame", nil, page, "TabSystemTemplate")
    if not ok or not row then return nil end
    local pool = rawget(_G, "CreateFramePool")
    if pool then row.tabPool = pool("BUTTON", row, "TabSystemTopButtonTemplate") end
    row.minTabWidth, row.maxTabWidth = 70, 140
    row:SetPoint("TOPLEFT", page, "TOPLEFT", Layout.TAB_LEFT, -Layout.HEAD)
    row:SetTabSelectedCallback(function(index)
        ns.Safe("tabs", Page.Choose, index)
        return true
    end)
    for _, section in ipairs(sections) do row:AddTab(section.text) end
    return row
end

-------------------------------------------------------------------------------
--  The status line
-------------------------------------------------------------------------------
local fadeAt

local function Fade()
    if not fadeAt then return end
    local left = fadeAt - (Core.Ask(GetTime) or 0)
    if left > 1 then return end
    page.status:SetAlpha(math.max(0, left))
    if left <= 0 then
        fadeAt = nil
        page.statusFrame:SetScript("OnUpdate", nil)
        page.statusFrame:Hide()
    end
end
local fading = ns.Guard(Fade)

function Page.Status(text)
    if not (page and page:IsVisible()) then return false end
    page.status:SetText(text or "")
    page.status:SetAlpha(1)
    page.statusFrame:Show()
    fadeAt = (Core.Ask(GetTime) or 0) + Layout.STATUS_TIME
    page.statusFrame:SetScript("OnUpdate", fading)
    return true
end

-------------------------------------------------------------------------------
--  The page
-------------------------------------------------------------------------------
-- The guild's data changed: the head and the view on show drawn anew (once a frame at most).
local Redraw = Core.Later(function()
    if not (page and page:IsVisible()) then return end
    Head()
    if shownView and shownView.view.Refresh then ns.Safe("view: " .. shownView.key, shownView.view.Refresh) end
    Context()
end)

-- Who was heard lately shows only in the head: a hello heard redraws the head alone.
local Rehead = Core.Later(function()
    if page and page:IsVisible() then Head() end
end)

local function Changed(what)
    if what == "peers" then Rehead() else Redraw() end
end

function Page.Build(parent)
    if page then return page end
    sections = Sections()
    page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    BuildHead()
    page.tabs = Tabs()
    page.viewTitle = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    page.viewTitle:SetPoint("TOPLEFT", Layout.EDGE + 6, -(Layout.HEAD + Layout.TABS + 6))
    page.context = page:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    page.context:SetPoint("BOTTOMLEFT", page.viewTitle, "BOTTOMRIGHT", 10, 0)
    page.tool = CreateFrame("Frame", nil, page)
    page.tool:SetPoint("TOPLEFT", 0, -(Layout.HEAD + Layout.TABS))
    page.tool:SetPoint("TOPRIGHT", 0, -(Layout.HEAD + Layout.TABS))
    page.tool:SetHeight(Layout.TOOL)
    page.subs = CreateFrame("Frame", nil, page)
    page.subs:SetPoint("TOPLEFT", Layout.EDGE, -(Layout.HEAD + Layout.TABS + Layout.TOOL))
    page.subs:SetPoint("TOPRIGHT", -Layout.EDGE, -(Layout.HEAD + Layout.TABS + Layout.TOOL))
    page.subs:SetHeight(Layout.SUB)
    page.subTabs = {}
    page.body = CreateFrame("Frame", nil, page)
    Body(false)
    page.empty = Kit.Empty(page, "GameFontNormalLarge") -- out of a guild: said in place of the tabs and the view
    page.empty:SetPoint("LEFT", Layout.EDGE, 20)
    page.empty:SetPoint("RIGHT", -Layout.EDGE, 20)
    page.empty:SetText(TEXT.noGuild .. "\n\n|cffb0b0b0" .. TEXT.noGuildHint .. "|r")
    page.statusFrame = CreateFrame("Frame", nil, page)
    page.statusFrame:SetPoint("BOTTOMLEFT", Layout.EDGE, 2)
    page.statusFrame:SetPoint("BOTTOMRIGHT", -Layout.EDGE, 2)
    page.statusFrame:SetHeight(Layout.STATUS - 2)
    local edge = page.statusFrame:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT")
    edge:SetPoint("BOTTOMLEFT")
    edge:SetWidth(3)
    edge:SetColorTexture(Core.GOLD[1], Core.GOLD[2], Core.GOLD[3], 1)
    page.status = page.statusFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    page.status:SetPoint("LEFT", 10, 0)
    page.status:SetPoint("RIGHT", -6, 0)
    page.status:SetJustifyH("LEFT")
    page.statusFrame:Hide()
    -- The view last chosen, else the overview.
    local index, viewIndex = 1, 1
    for i, section in ipairs(sections) do
        if section.key == ns.store.section then
            index = i
            for j, entry in ipairs(section.views) do
                if entry.key == ns.store.view then viewIndex = j end
            end
        end
    end
    Head()
    Page.Choose(index, viewIndex)
    return page
end

-- The page fills that frame now.
function Page.Into(parent)
    if not page then return Page.Build(parent) end
    page:SetParent(parent)
    page:ClearAllPoints()
    page:SetAllPoints(parent)
    page:Show()
    return page
end

-- While on show the roster is asked of the game anew, whenever it lets (Core.Data.Guild.Watch).
function Page.Show(on)
    if not page then return end
    if on and not listening then
        listening = true
        Core.Data.Guild.OnChange(Changed)
        Core.Data.Guild.Sync()
    end
    Core.Data.Guild.Watch(on)
    page.active = on
    if on then
        Head()
        if shownView and shownView.view.Show then ns.Safe("view: " .. shownView.key, shownView.view.Show, true) end
        Context()
    elseif shownView and shownView.view.Show then
        ns.Safe("view: " .. shownView.key, shownView.view.Show, false)
    end
end

-- What is typed into the window's search: to the view on show.
function Page.Search(text)
    local view = shownView and shownView.view
    if view and view.Search then ns.Safe("view: search", view.Search, text or "") end
end

function Page.Shown()
    return page ~= nil and page:IsVisible() and page.active == true
end

function Page.Frame()
    return page
end
