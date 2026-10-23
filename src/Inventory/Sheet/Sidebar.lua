local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Sidebar
--  The stats' window: what the right pane of the game's character sheet holds,
--  as a window of its own on the module's full screen (Board.lua, the key
--  "stats"), on the journal's page (Doc/guides/interface-style.md), as wide
--  and high as the board makes it. At its top a row of tabs drawn in pencil
--  for the game's sidebar tabs: Stats, Equipment Manager, Titles, and Pet
--  while you have one; the chosen one's box drawn stronger and shaded, a tab
--  the game has nothing for faded, with the game's words why in its tooltip.
--  Under them what the tab chosen shows: your stats (Stats.lua), your gear
--  sets (Gear.lua), your titles (Titles.lua), your pet's stats (Stats.lua).
--  The panel's head says the tab's name. The tabs share the row's width when
--  it is narrow, their words cut short where they must.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local J = Core.Journal
local Paper = ns.Paper
local Sidebar = {}
ns.Sidebar = Sidebar

local Fit = Paper.Fit
Sidebar.TAB = Fit(28)       -- a tab's height
Sidebar.TAB_PAD = Fit(12)   -- room at each side of a tab's word
Sidebar.TAB_GAP = Fit(4)    -- between two tabs
Sidebar.TABS_X = Fit(10)    -- the row's margin at the page's sides
Sidebar.TABS_Y = Fit(6)     -- above the row
Sidebar.UNDER = Fit(6)      -- between the row's rule and what the tab shows
Sidebar.LEAST = 360         -- how low the window may be made

local body, row, rule
local tabs      -- in the game's order: stats, gear, titles, pet
local chosen    -- the tab shown
local shown = false

local TabFont = Paper.Font("SaneUIStatsTab", 14)

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Pet()
    return Game("HasPetUI") and true or false
end

-- The game's word without its colon ("Stats:").
local function Bare(word)
    return (tostring(word or ""):gsub("%s*[:：]%s*$", ""))
end

-- The game's sidebar tabs: their words, their names (the head's), whether the game has something for them, why
-- not, what each shows.
local function Tabs()
    return {
        { key = "stats", word = Bare(Core.Word("STATS_LABEL", "Stats")),
          name = Core.Word("PAPERDOLL_SIDEBAR_STATS", "Character Stats"),
          active = function() return true end, show = function(on) ns.Stats.Show(on) end },
        { key = "gear", name = Core.Word("PAPERDOLL_EQUIPMENTMANAGER", "Equipment Manager"),
          active = function() return ns.Gear.Usable() end,
          why = function()
              local lfg = rawget(_G, "C_LFGInfo")
              return lfg and lfg.CanPlayerUseLFD and select(2, Core.Ask(lfg.CanPlayerUseLFD)) or nil
          end,
          show = function(on) ns.Gear.Show(on) end },
        { key = "titles", name = Core.Word("PAPERDOLL_SIDEBAR_TITLES", "Titles"),
          active = function() return ns.Titles.Any() end, why = function() return Core.Word("NO_TITLES_TOOLTIP", nil) end,
          show = function(on) ns.Titles.Show(on) end },
        { key = "pet", name = Core.Word("PET", "Pet"),
          active = Pet, why = function() return Core.Word("ERR_NO_PET", nil) end,
          show = function(on) ns.Stats.Show(on) end },
    }
end

local function Find(key)
    for _, tab in ipairs(tabs or {}) do
        if tab.key == key then return tab end
    end
end

-- The game's tooltip for a tab: its name, and why it is faded while it is.
local function Tip(tab)
    GameTooltip:SetOwner(tab.button, "ANCHOR_BOTTOM")
    Game("GameTooltip_SetTitle", GameTooltip, tab.name)
    if not tab.button:IsEnabled() and tab.why then
        local why = tab.why()
        if why then Game("GameTooltip_AddErrorLine", GameTooltip, why, true) end
    end
    GameTooltip:Show()
end

-- A tab drawn as it stands: the chosen one's box strong and shaded, one under the mouse strong, a faded one light.
local function Look(tab)
    local button = tab.button
    local on, enabled = tab.key == chosen, button:IsEnabled()
    button.box:SetStrong(on or (enabled and button:IsMouseOver()))
    if not enabled then
        for _, part in ipairs(button.box.parts) do part:SetAlpha(0.35) end
    end
    button.shade:SetShown(on)
    button.text:SetAlpha(enabled and 1 or 0.45)
end

-- The tabs in their row: the pet's only with a pet, each as wide as its word while they fit, else the row's width
-- shared out by their words' widths; faded where the game has nothing for them; the chosen one drawn so.
local function Layout()
    if not tabs then return end
    local list = {}
    tabs[4].button:SetShown(Pet())
    for _, tab in ipairs(tabs) do
        if tab.button:IsShown() then list[#list + 1] = tab end
    end
    local room = (row:GetWidth() or 0) - (#list - 1) * Sidebar.TAB_GAP
    local wanted = 0
    for _, tab in ipairs(list) do
        tab.want = tab.button.text:GetUnboundedStringWidth() + 2 * Sidebar.TAB_PAD
        wanted = wanted + tab.want
    end
    local squeeze = (room > 0 and wanted > room) and room / wanted or 1
    local x = 0
    for _, tab in ipairs(list) do
        local width = math.floor(tab.want * squeeze)
        tab.button:ClearAllPoints()
        tab.button:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", x, 0)
        tab.button:SetSize(width, Sidebar.TAB)
        x = x + width + Sidebar.TAB_GAP
    end
    for _, tab in ipairs(tabs) do
        local active = tab.active()
        tab.button:SetEnabled(active and true or false)
        Look(tab)
    end
end

-- A tab chosen: the one before hidden and deaf, this one shown and drawn, the head says its name. The one shown
-- already stays as it is.
function Sidebar.Choose(key)
    local tab = Find(key) or tabs[1]
    if tab.key == chosen then return Layout() end
    local before = Find(chosen)
    if before and before ~= tab then
        before.pane:Hide()
        if shown then ns.Safe("character", before.show, false) end
    end
    chosen = tab.key
    tab.pane:Show()
    if Sidebar.panel and Sidebar.panel.title then Sidebar.panel.title:SetText(tab.name) end
    Layout()
    if shown then ns.Safe("character", tab.show, true) end
end

local function Clicked(tab)
    if tab.key ~= chosen then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF") end
    Sidebar.Choose(tab.key)
end

-- A tab drawn in pencil (the style's drawn tabs): a pencil box, its word in Kalam, shaded while chosen.
local function Button(tab)
    local button = CreateFrame("Button", nil, row)
    button:SetMotionScriptsWhileDisabled(true)
    button.shade = button:CreateTexture(nil, "BACKGROUND")
    button.shade:SetPoint("TOPLEFT", Fit(2), -Fit(2))
    button.shade:SetPoint("BOTTOMRIGHT", -Fit(2), Fit(2))
    button.shade:SetColorTexture(Paper.CHOSEN[1], Paper.CHOSEN[2], Paper.CHOSEN[3], Paper.CHOSEN[4])
    button.box = J.Box(button, 0.5)
    button.text = button:CreateFontString(nil, "ARTWORK")
    button.text:SetFontObject(TabFont)
    button.text:SetPoint("LEFT", Fit(4), 0)
    button.text:SetPoint("RIGHT", -Fit(4), 0)
    button.text:SetWordWrap(false)
    button.text:SetText(tab.word or tab.name)
    button:SetScript("OnClick", ns.Guard(function() Clicked(tab) end))
    button:SetScript("OnEnter", ns.Guard(function() Look(tab) Tip(tab) end))
    button:SetScript("OnLeave", ns.Guard(function() Look(tab) GameTooltip:Hide() end))
    tab.button = button
end

-- Under the tabs' rule, to the page's foot: where a tab's content stands.
local function Pane()
    local pane = CreateFrame("Frame", nil, body)
    pane:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", -Sidebar.TABS_X, -Sidebar.UNDER)
    pane:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT")
    pane:Hide()
    return pane
end

function Sidebar.Build(made)
    Sidebar.panel = made
    body = made.body
    row = CreateFrame("Frame", nil, body)
    row:SetPoint("TOPLEFT", Sidebar.TABS_X, -Sidebar.TABS_Y)
    row:SetPoint("TOPRIGHT", -Sidebar.TABS_X, -Sidebar.TABS_Y)
    row:SetHeight(Sidebar.TAB)
    row:SetScript("OnSizeChanged", ns.Guard(function() Layout() end))
    rule = Paper.Rule(row, "BOTTOM")
    rule:ClearAllPoints()
    rule:SetPoint("TOPLEFT", row, "BOTTOMLEFT")
    rule:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT")
    tabs = Tabs()
    for _, tab in ipairs(tabs) do Button(tab) end
    tabs[1].pane = Pane()
    ns.Stats.Build(tabs[1].pane, "player")
    tabs[2].pane = Pane()
    ns.Gear.Build(tabs[2].pane)
    tabs[3].pane = Pane()
    ns.Titles.Build(tabs[3].pane)
    tabs[4].pane = Pane()
    ns.Stats.Build(tabs[4].pane, "pet")
    Sidebar.Choose("stats")
end

-- A pet came or went: the tabs anew; the pet's tab chosen without a pet goes back to the stats.
local function Petted()
    if chosen == "pet" and not Pet() then return Sidebar.Choose("stats") end
    Layout()
    ns.Stats.Refresh()
end

local later = Core.Later(function() ns.Safe("character", Petted) end)

-- Shown or hidden: the player's pet listened to while shown (UNIT_PET names the pet's owner); the pet gone while
-- hidden, shown again with the stats, as when it goes while shown (Petted).
function Sidebar.Show(on)
    shown = on
    if on then Core.OnUnit("UNIT_PET", "player", later) else Core.OffUnit("UNIT_PET", "player", later) end
    local tab = Find(chosen)
    if not tab then return end
    if on and chosen == "pet" and not Pet() then return Sidebar.Choose("stats") end
    if on then Layout() end
    ns.Safe("character", tab.show, on)
end

-- The tab shown now; a tab's button by its key (stats, gear, titles, pet).
function Sidebar.Chosen()
    return chosen
end

function Sidebar.Button(key)
    local tab = Find(key)
    return tab and tab.button
end

ns.Board.Part("stats", Core.Word("PAPERDOLL_SIDEBAR_STATS", "Character Stats"),
    ns.Board.Least("stats", ns.Stats.COLUMN + 2 * ns.Stats.PAD, Sidebar.LEAST), Sidebar)
