local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Sheet - Sidebar
--  The stats' window: the right pane of the game's character sheet as a window
--  of its own on the module's full screen (Board.lua, the key "stats"), at the
--  game's width and as high as its window, in its middle. At its top the
--  game's stone with the game's sidebar tabs on it (Camelot's PaperDollSidebar
--  Tabs): Stats (your portrait), Equipment Manager, Titles, and Pet while you
--  have one, the three centred without it, as the game centres them; a tab the
--  game has nothing for is greyed with the game's words why. Under the stone
--  what the tab chosen shows: your stats (Stats.lua), your gear sets
--  (Gear.lua), your titles (Titles.lua), your pet's stats (Stats.lua). The
--  panel's head says the tab's name.
--
--  The game's own sidebar tabs are wired to its sheet (their click shows its
--  panes), so ours are our own buttons in the game's art.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Sidebar = {}
ns.Sidebar = Sidebar

-- The game's sizes (CharacterFrame.xml, PaperDollFrame.xml): the pane's width, a tab, the tabs below the top, how
-- small the window may be made.
Sidebar.WIDTH = 233
Sidebar.TAB = 42
Sidebar.TABS_Y = -9 -- the game's tabs frame 4 below the pane's top, its tabs 5 below that
Sidebar.LEAST = 360
-- The portrait's and the game's sidebar icons' texture coordinates (PaperDollFrameConstants.lua).
Sidebar.PORTRAIT = { 0.109375, 0.890625, 0.09375, 0.90625 }
Sidebar.ICONS = "Interface\\PaperDollInfoFrame\\PaperDollSidebarTabs"

local column, stone, panel
local tabs      -- in the game's order: stats, gear, titles, pet
local chosen    -- the tab shown
local shown = false

local function Game(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return fn(...) end
end

local function Pet()
    return Game("HasPetUI") and true or false
end

-- The game's sidebar tabs: their names, icons, whether the game has something for them, why not, what each shows.
local function Tabs()
    return {
        { key = "stats", name = Core.Word("PAPERDOLL_SIDEBAR_STATS", "Character Stats"), portrait = true,
          active = function() return true end, show = function(on) ns.Stats.Show(on) end },
        { key = "gear", name = Core.Word("PAPERDOLL_EQUIPMENTMANAGER", "Equipment Manager"),
          icon = Sidebar.ICONS, coords = { 0.015625, 0.53125, 0.46875, 0.60546875 },
          active = function() return ns.Gear.Usable() end,
          why = function()
              local lfg = rawget(_G, "C_LFGInfo")
              return lfg and lfg.CanPlayerUseLFD and select(2, Core.Ask(lfg.CanPlayerUseLFD)) or nil
          end,
          show = function(on) ns.Gear.Show(on) end },
        { key = "titles", name = Core.Word("PAPERDOLL_SIDEBAR_TITLES", "Titles"),
          icon = Sidebar.ICONS, coords = { 0.015625, 0.53125, 0.32421875, 0.4609375 },
          active = function() return ns.Titles.Any() end, why = function() return Core.Word("NO_TITLES_TOOLTIP", nil) end,
          show = function(on) ns.Titles.Show(on) end },
        { key = "pet", name = Core.Word("PET", "Pet"), atlas = "paw-icon",
          active = Pet, why = function() return Core.Word("ERR_NO_PET", nil) end,
          show = function(on) ns.Stats.Show(on) end },
    }
end

local function Find(key)
    for _, tab in ipairs(tabs or {}) do
        if tab.key == key then return tab end
    end
end

-- The game's tooltip for a tab: its name, and why it is greyed while it is.
local function Tip(tab)
    GameTooltip:SetOwner(tab.button, "ANCHOR_RIGHT")
    Game("GameTooltip_SetTitle", GameTooltip, tab.name)
    if not tab.button:IsEnabled() and tab.why then
        local why = tab.why()
        if why then Game("GameTooltip_AddErrorLine", GameTooltip, why, true) end
    end
    GameTooltip:Show()
end

-- The tabs as the game shows them: the pet's only with a pet, the others centred without it; greyed where the
-- game has nothing for them; the chosen one checked.
local function Layout()
    local pet = Pet()
    local stats, gear, titles, petTab = tabs[1].button, tabs[2].button, tabs[3].button, tabs[4].button
    for _, button in ipairs({ stats, gear, titles, petTab }) do button:ClearAllPoints() end
    petTab:SetShown(pet)
    if pet then
        gear:SetPoint("TOPRIGHT", column, "TOP", 0, Sidebar.TABS_Y)
        titles:SetPoint("LEFT", gear, "RIGHT")
        stats:SetPoint("RIGHT", gear, "LEFT")
        petTab:SetPoint("LEFT", titles, "RIGHT")
    else
        gear:SetPoint("TOP", column, "TOP", 0, Sidebar.TABS_Y)
        stats:SetPoint("RIGHT", gear, "LEFT")
        titles:SetPoint("LEFT", gear, "RIGHT")
    end
    for _, tab in ipairs(tabs) do
        local active = tab.active()
        tab.button:SetEnabled(active and true or false)
        tab.button:SetAlpha(active and 1 or 0.5)
        tab.button.icon:SetDesaturation(active and 0 or 1)
        tab.button:SetChecked(tab.key == chosen)
    end
end

-- A tab chosen: the one before hidden and deaf, this one shown and drawn, the head says its name. The one shown
-- already stays as it is (its button, which unchecked itself, checked again).
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
    if panel and panel.title then panel.title:SetText(tab.name) end
    Layout()
    if shown then ns.Safe("character", tab.show, true) end
end

local function Clicked(tab)
    if tab.key ~= chosen then Core.Sound("IG_MAINMENU_OPTION_CHECKBOX_OFF") end
    Sidebar.Choose(tab.key)
end

-- A tab of the game's look (PaperDollSidebarTabTemplate), ours: its icon, the tab's frame, checked while chosen.
local function Button(tab)
    local button = CreateFrame("CheckButton", nil, column)
    button:SetSize(Sidebar.TAB, Sidebar.TAB)
    button:SetMotionScriptsWhileDisabled(true)
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(Sidebar.TAB, Sidebar.TAB)
    button.icon:SetPoint("CENTER")
    if tab.portrait then
        Game("SetPortraitTexture", button.icon, "player")
        button.icon:SetTexCoord(unpack(Sidebar.PORTRAIT))
    elseif tab.atlas then
        button.icon:SetAtlas(tab.atlas)
    else
        button.icon:SetTexture(tab.icon)
        button.icon:SetTexCoord(unpack(tab.coords))
    end
    local frame = button:CreateTexture(nil, "BORDER")
    frame:SetAtlas("UI-Character-Info-StatTab", true)
    frame:SetPoint("CENTER")
    button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local checked = button:GetCheckedTexture()
    if checked then
        checked:SetAtlas("UI-Character-Info-StatTab-Selected", true)
        checked:ClearAllPoints()
        checked:SetPoint("CENTER")
    end
    button:SetScript("OnClick", function() ns.Safe("character", Clicked, tab) end)
    button:SetScript("OnEnter", function() ns.Safe("character", Tip, tab) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    tab.button = button
end

-- Under the stone, to the column's foot: where a tab's content stands.
local function Pane()
    local pane = CreateFrame("Frame", nil, column)
    pane:SetPoint("TOPLEFT", stone, "BOTTOMLEFT")
    pane:SetPoint("BOTTOMRIGHT", column, "BOTTOMRIGHT")
    pane:Hide()
    return pane
end

function Sidebar.Build(made)
    panel = made
    column = CreateFrame("Frame", nil, panel.body)
    column:SetPoint("TOP")
    column:SetPoint("BOTTOM")
    column:SetWidth(Sidebar.WIDTH)
    local back = column:CreateTexture(nil, "BACKGROUND")
    back:SetAtlas("UI-Character-Info-Stat-BG")
    back:SetAllPoints()
    stone = column:CreateTexture(nil, "ARTWORK")
    stone:SetAtlas("UI-Character-Info-Stat-StoneBG3", true)
    stone:SetPoint("TOPLEFT")
    tabs = Tabs()
    for _, tab in ipairs(tabs) do Button(tab) end
    local player = ns.Stats.Build(column, stone, "player")
    if player then player:Hide() end
    tabs[1].pane = player or Pane()
    tabs[2].pane = Pane()
    ns.Gear.Build(tabs[2].pane)
    tabs[3].pane = Pane()
    ns.Titles.Build(tabs[3].pane)
    local pet = ns.Stats.Build(column, stone, "pet")
    if pet then pet:Hide() end
    tabs[4].pane = pet or Pane()
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

ns.Board.Part("stats", Core.Word("PAPERDOLL_SIDEBAR_STATS", "Character Stats"), ns.Page.Least(Sidebar.WIDTH, Sidebar.LEAST), Sidebar)
