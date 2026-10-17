local ADDON = ...

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings
--  The options of Sane UI in the game's own options (Esc > Options > AddOns >
--  Sane UI, /sane options, or the minimap's addon list):
--      Sane UI             Sane UI's banner, its links and feedback (About.lua)
--        Profiles          a page of our own with tabs (Profiles.lua): whose settings are in
--                          use and copies of them under names; Sync's switches (Synced.lua);
--                          every CVar of the game (CVars.lua)
--        General           the switches of no module
--        Appearance        the look of Sane UI as a whole: how its windows move
--        Social, Abilities one page per module that is switched on and has switches,
--        ...               its banner at the top
--
--  The pages are put up empty at login (Core.pages): the game only shows its
--  AddOns tab if an addon has a page when its options first open, and decides that
--  for the whole session. Their controls are made only when the options are first
--  opened (Config.Fill), so a session that never opens them builds nothing.
--
--  These files only show the switches. They are described by their modules and
--  kept by Core (Saved.lua), so a module that is switched off has no page here.
--
--  The pages are the game's own vertical lists, with their look and controls,
--  but for Profiles: a page of our own (a canvas), built from the game's parts
--  (Panel.lua). Drawn here besides is only the banner at the top of a page.
--
--  Called Config in these files (Core.Config): "Settings" is the game's own
--  options library.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Config = {}
Core.Config = Config

local filled -- the pages have their controls
local shown = {} -- every setting on the pages, to show values put in place by Core (Config.Refresh)
local quiet      -- Refresh is running: the modules were told of the changes already

-- Rows are handed to the game (Settings.RegisterInitializer) and put on the page by its own code.
-- Settings.CreateCheckbox would add them from ours, and the options' search reads every page.
local function Add(page, row)
    Settings.RegisterInitializer(page, row)
    return row
end

-- A setting whose control shows a value that can change under it (Config.Refresh).
function Config.Show(setting)
    shown[#shown + 1] = setting
end

-- The settings in use changed under the controls (a profile was loaded, the character's own
-- settings switched): every control reads its value again. As the game asks for a value that
-- changed from elsewhere (SettingMixin:NotifyUpdate); the controls of a page not open are made
-- anew when it is.
function Config.Refresh()
    quiet = true
    for _, setting in ipairs(shown) do Core.Safe("Settings: refresh", setting.NotifyUpdate, setting) end
    quiet = false
    Config.Panel.Refresh()
end

-------------------------------------------------------------------------------
--  The pages, put up at login, empty
-------------------------------------------------------------------------------
-- The pages of Sane UI in the game's options, empty until Config.Fill fills them:
--      Core.pages.top          "Sane UI": its logo, links and feedback
--      Core.pages.Profiles     the profiles, Sync's switches and the CVars: a page of our own (a
--                              canvas), its frame Core.frames.Profiles
--      Core.pages[Core.name]   "General": the switches of no module
--      Core.pages.Appearance   the look of Sane UI as a whole
--      Core.pages[module name] "Social", "Abilities", ...: that module's switches; a page of our own
--                              (Core.frames[module name]) if they are in tabs (their option.tab)
Core.pages = {}
Core.frames = {} -- the frame of a page of our own, filled by Config.Fill
local PAGES = { { "Profiles", "Profiles", canvas = true }, { Core.name, type(GENERAL) == "string" and GENERAL or "General" },
    { "Appearance", "Appearance" } }

-- Whether a module's switches are in tabs: one of them names its tab.
function Core.Tabbed(name)
    for _, option in ipairs(Core.described[name] and Core.described[name].list or {}) do
        if option.tab then return true end
    end
    return false
end

-- The game's options window decides the first time it opens whether it has the tabs "Game" and
-- "AddOns", by whether an addon has a page by then, and keeps that for the session
-- (SettingsPanelMixin:OnShow). So the pages are put up at login, empty: a few small tables, no
-- frames. The game makes a page's controls only when it is shown.
local function PutUpPages()
    if not (Settings and Settings.RegisterVerticalLayoutSubcategory and Settings.RegisterAddOnCategory) then return end
    local top = Settings.RegisterVerticalLayoutCategory(Core.TITLE)
    Core.pages.top = top
    -- Under it, in this order (the game keeps it): Sane UI's own pages, then one per module, called
    -- by its name, also the title at the top of the page.
    for _, page in ipairs(PAGES) do
        if page.canvas and Settings.RegisterCanvasLayoutSubcategory then
            -- One empty frame: the game shows it in place of its list when the page is chosen.
            local frame = CreateFrame("Frame")
            frame:Hide()
            Core.frames[page[1]] = frame
            Core.pages[page[1]] = Settings.RegisterCanvasLayoutSubcategory(top, frame, page[2])
        else
            Core.pages[page[1]] = Settings.RegisterVerticalLayoutSubcategory(top, page[2])
        end
    end
    -- Sync describes its switches as a module does, but is part of Core (no SaneUI.Sync): they are
    -- on the page Profiles.
    for _, name in ipairs(Core.optionOrder) do
        local module = SaneUI[name]
        if module and name ~= Core.name then
            local own
            if Core.Tabbed(name) and Settings.RegisterCanvasLayoutSubcategory then
                -- Switches in tabs: a page of our own, as Profiles is.
                local frame = CreateFrame("Frame")
                frame:Hide()
                Core.frames[name] = frame
                own = Settings.RegisterCanvasLayoutSubcategory(top, frame, module.title)
            end
            Core.pages[name] = own or Settings.RegisterVerticalLayoutSubcategory(top, module.title)
        end
    end
    Settings.RegisterAddOnCategory(top)
end

-- Core's own login step (Core.lua) has started every module by now, and every module that is
-- switched on has described its switches.
Core.On("PLAYER_LOGIN", function()
    Core.Safe("options", PutUpPages)
    -- What is on the pages is only needed once the game's options are open.
    if SettingsPanel then
        SettingsPanel:HookScript("OnShow", function() Core.Safe("options", Config.Fill) end)
    end
end)

-------------------------------------------------------------------------------
--  The banners: the picture of the addon a page belongs to, at its top, in
--  place of the page's title. Each addon ships its own as Art\banner.blp
--  (made by dev/tools/art); the page Sane UI has Sane UI's, which is Core's. A row of the page (Banner.xml), so the game makes it only when the
--  page is shown and lets it go when another page is, or when it is scrolled
--  out of sight: the game's title of the page is hidden only for that long.
-------------------------------------------------------------------------------
local BANNER = "Interface\\AddOns\\%s\\Art\\banner"
local BANNER_RIGHT = 0.75 -- the banner's box fills the file's left 768 of 1024 texels (Doc/guides/images.md)

local function ShowTitle(shown)
    local list = SettingsPanel and SettingsPanel.GetSettingsList and SettingsPanel:GetSettingsList()
    local title = list and list.Header and list.Header.Title
    if title then title:SetAlpha(shown and 1 or 0) end
end

SaneUISettingsBannerMixin = {}

function SaneUISettingsBannerMixin:Init(initializer)
    -- The game's own filter: "TRILINEAR" blurs art drawn near its file's size (Doc/guides/images.md).
    local found = self.Art:SetTexture(initializer:GetData().file)
    self.Art:SetTexCoord(0, BANNER_RIGHT, 0, 1)
    ShowTitle(not found)
end

function SaneUISettingsBannerMixin:Release()
    ShowTitle(true)
end

-- The banner's row for a page, if the addon has one: SetTexture says whether the game found the
-- file (as Blizzard's own code asks). Without it the page keeps the game's title.
local probe
local function AddBanner(page, addon)
    local file = BANNER:format(addon)
    probe = probe or CreateFrame("Frame"):CreateTexture()
    local found = probe:SetTexture(file)
    probe:SetTexture(nil)
    if found then Add(page, Settings.CreateElementInitializer("SaneUISettingsBannerTemplate", { file = file })) end
end

-- One switch's control: a checkbox, a slider for a number (option.min, max, step), or a dropdown for
-- one of a few (option.choices). The game makes the control itself, and only when the page is opened.
local function Switch(page, name, options, changed, option)
    local setting = Settings.RegisterAddOnSetting(page, "SaneUI_" .. name .. "_" .. option.key, option.key,
        options, type(option.default), option.text, option.default)
    Config.Show(setting)
    if changed then
        setting:SetValueChangedCallback(function(_, value)
            if not quiet then Core.Safe(name .. ": option", changed, option.key, value) end
        end)
    end
    if option.max then
        -- A number between two ends: a slider, its value written beside it.
        local slider = Settings.CreateSliderOptions(option.min, option.max, option.step)
        -- Steps below 1 (0.05 seconds) are written with two decimals, not as the float they are.
        local decimals = option.step < 1 and function(value) return ("%.2f"):format(value) end or nil
        if MinimalSliderWithSteppersMixin then slider:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, decimals) end
        return Add(page, Settings.CreateSliderInitializer(setting, slider, option.tip))
    elseif option.choices then
        -- One of a few: a dropdown of their words.
        return Add(page, Settings.CreateDropdownInitializer(setting, function()
            local container = Settings.CreateControlTextContainer()
            for _, choice in ipairs(option.choices) do container:Add(choice[1], choice[2]) end
            return container:GetData()
        end, option.tip))
    else
        return Add(page, Settings.CreateCheckboxInitializer(setting, nil, option.tip))
    end
end

-- Whether a switch under others (option.parent) can be changed: every one it is under is on, and so
-- on up. parent is a key, or a list of keys that must all be on (Social's Animation type is under
-- Can expand to fullscreen and All animations and fades). A switch under one of a few (parentValue)
-- is free while that one (the first parent) is set to that value.
local function On(options, byKey, key, value)
    if value ~= nil then
        if options[key] ~= value then return false end
    elseif not options[key] then
        return false
    end
    local above = byKey[key]
    return above == nil or Config.Free(options, byKey, above)
end

function Config.Free(options, byKey, option)
    local up = option.parent
    if up == nil then return true end
    if type(up) ~= "table" then return On(options, byKey, up, option.parentValue) end
    for index, key in ipairs(up) do
        if not On(options, byKey, key, index == 1 and option.parentValue or nil) then return false end
    end
    return true
end

-- The controls of one module's switches. A switch with a header starts a section above it; one
-- without text is kept with the settings but has no control. One with parent is drawn under that
-- switch. (A module whose switches are in tabs has a page of our own instead: Tabbed.lua.)
-- onPage: only the switches that name that page (option.page; Core's: "Appearance"); nil, those that name none.
local function Fill(page, name, onPage)
    local options, changed = Core.Store(name).options, Core.described[name].changed
    local byKey, rows = {}, {}
    for _, option in ipairs(Core.described[name].list) do
        byKey[option.key] = option
        local here = option.page == onPage
        if here and option.header then Add(page, CreateSettingsListSectionHeaderInitializer(option.header, option.headerTip)) end
        if here and option.text and not option.color then -- a colour only on a page of our own (Tabbed.lua)
            local row = Switch(page, name, options, changed, option)
            rows[option.key] = row
            local up = type(option.parent) == "table" and option.parent[1] or option.parent -- the list pages know one
            local parent = up and rows[up]
            if parent and row and row.SetParentInitializer then
                row:SetParentInitializer(parent, function() return Config.Free(options, byKey, option) end)
            end
        end
    end
end

-- The controls of every page, made the first time the options are opened (long after the login,
-- when every module has described its switches and the pages are up):
--      Sane UI      its banner, its links and feedback (About.lua)
--      Profiles     a page of our own, with tabs (Profiles.lua): the profiles, Sync's switches
--                   (Synced.lua), the CVars (CVars.lua)
--      General      the switches of no module
--      Appearance   the look of Sane UI as a whole: the general switches that name it
--      Social, ...  a module's banner and switches
function Config.Fill()
    local pages = Core.pages
    local top, profiles, general = pages.top, pages.Profiles, pages[Core.name]
    if filled or not top then return end
    filled = true
    Core.Safe("Settings: banner", AddBanner, top, ADDON)
    Core.Safe("Settings: about", Config.About.Fill, top)
    Core.Safe("Settings: profiles", Config.BuildProfiles, Core.frames.Profiles)
    Core.Safe("Settings: " .. Core.name, Fill, general, Core.name)
    Core.Safe("Settings: Appearance", Fill, pages.Appearance, Core.name, "Appearance")
    local own = { [top] = true, [profiles] = true, [general] = true, [pages.Appearance] = true }
    for _, name in ipairs(Core.optionOrder) do
        local page = pages[name]
        if Core.frames[name] then
            Core.Safe("Settings: " .. name, Config.BuildTabbed, Core.frames[name], name)
        elseif page and not own[page] then
            Core.Safe("Settings: banner of " .. name, AddBanner, page, SaneUI[name].addon)
            Core.Safe("Settings: " .. name, Fill, page, name)
        end
    end
end

function Config.Open()
    local category = Core.pages.top
    if not category then return end
    -- The game does not let an addon open its options in a fight.
    if InCombatLockdown() then
        Core.Print("you are in combat: the options open after the fight.")
        return
    end
    Core.Safe("options", Config.Fill)
    Settings.OpenToCategory(category:GetID())
end

Core.Command("options", "open the options", Config.Open, "config", "settings")

-- The minimap's addon list (## AddonCompartmentFunc in the TOC).
function SaneUI_OnAddonCompartmentClick()
    Config.Open()
end
