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
--  for the whole session. The controls of the game's lists are handed to it when
--  the options are first opened (Config.Fill); a page of our own is built the first
--  time it is shown. So a session that never opens them builds nothing, and one
--  that opens only the game's own pages builds none of ours.
--
--  These files only show the switches. They are described by their modules and
--  kept by Core (Saved.lua), so a module that is switched off has no page here.
--  Every change goes through Core.Set: checked, told to the module, a /reload
--  offered where one is needed.
--
--  The pages are the game's own vertical lists, with their look and controls,
--  but for Profiles and a module whose switches are in tabs: a page of our own
--  (a canvas), built from the game's parts (Panel.lua, Tabbed.lua). Drawn here
--  besides are only the banner at the top of a page and a row to type into.
--
--  Called Config in these files (Core.Config): "Settings" is the game's own
--  options library.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Config = {}
Core.Config = Config

local TEXT = {
    open = "open the options",
    afterFight = "you are in combat: the options open after the fight.",
}

local filled -- the pages have their controls
local shown = {} -- every setting on the pages, to show values put in place by Core (Config.Refresh)

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

-- The settings in use changed under the controls (a profile was loaded, a switch set elsewhere):
-- every control reads its value again. As the game asks for a value that changed from elsewhere
-- (SettingMixin:NotifyUpdate); the controls of a list page not open are made anew when it is, a
-- page of our own that is hidden shows them once it is shown (Panel.Refresh). The settings only read
-- their values here: the modules were told by Core already.
function Config.Refresh()
    for _, setting in ipairs(shown) do Core.Safe("Settings: refresh", setting.NotifyUpdate, setting) end
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
Core.frames = {} -- the frame of a page of our own, built the first time it is shown
local PAGES = { { "Profiles", "Profiles", canvas = true }, { Core.name, type(GENERAL) == "string" and GENERAL or "General" },
    { "Appearance", "Appearance" } }

-- Whether a module's switches are in tabs: one of them names its tab.
function Core.Tabbed(name)
    for _, option in ipairs(Core.described[name] and Core.described[name].list or {}) do
        if option.tab then return true end
    end
    return false
end

-- A page of our own: one empty frame, which the game shows in place of its list when the page is
-- chosen. What it holds is made the first time it is shown (build(frame, name)), not when the options
-- open: a player who opens only the game's own pages makes none of it.
local function OwnPage(top, name, title, build)
    local frame = CreateFrame("Frame")
    frame:Hide()
    frame:SetScript("OnShow", function(self)
        if self.built then return end
        self.built = true
        Core.Safe("Settings: " .. name, build, self, name)
    end)
    Core.frames[name] = frame
    return Settings.RegisterCanvasLayoutSubcategory(top, frame, title)
end

-- The game's options window decides the first time it opens whether it has the tabs "Game" and
-- "AddOns", by whether an addon has a page by then, and keeps that for the session
-- (SettingsPanelMixin:OnShow). So the pages are put up at login, empty: a few small tables, an
-- empty frame for a page of our own. The game makes a page's controls only when it is shown.
local function PutUpPages()
    if not (Settings and Settings.RegisterVerticalLayoutSubcategory and Settings.RegisterAddOnCategory) then return end
    local top = Settings.RegisterVerticalLayoutCategory(Core.TITLE)
    Core.pages.top = top
    local canvas = Settings.RegisterCanvasLayoutSubcategory
    -- Under it, in this order (the game keeps it): Sane UI's own pages, then one per module, called
    -- by its name, also the title at the top of the page.
    for _, page in ipairs(PAGES) do
        if page.canvas and canvas then
            Core.pages[page[1]] = OwnPage(top, page[1], page[2], function(frame) Config.BuildProfiles(frame) end)
        else
            Core.pages[page[1]] = Settings.RegisterVerticalLayoutSubcategory(top, page[2])
        end
    end
    -- Sync describes its switches as a module does, but is part of Core (no SaneUI.Sync): they are
    -- on the page Profiles.
    for _, name in ipairs(Core.optionOrder) do
        local module = SaneUI[name]
        if module and name ~= Core.name then
            if Core.Tabbed(name) and canvas then
                -- Switches in tabs: a page of our own, as Profiles is. The game's Defaults (All settings)
                -- sets the switches of a page of our own through its OnDefault.
                Core.pages[name] = OwnPage(top, name, module.title, Config.BuildTabbed)
                Core.frames[name].OnDefault = function() Core.Safe("Settings: defaults of " .. name, Core.Reset, name) end
            else
                Core.pages[name] = Settings.RegisterVerticalLayoutSubcategory(top, module.title)
            end
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

-------------------------------------------------------------------------------
--  A row to type into (Banner.xml: SaneUISettingsEntryTemplate), for words
--  and for a number with entry = true: the game's own row of a setting
--  (SettingsControlMixin: its words at the left, its tooltip, greyed out under
--  the switch above it, the game's Defaults) with the game's input box where
--  its other rows have their control. Enter sets what was typed, Esc or a
--  click elsewhere leaves the value as it was.
-------------------------------------------------------------------------------
local Base = rawget(_G, "SettingsControlMixin")
local Mixins = rawget(_G, "CreateFromMixins")
SaneUISettingsEntryMixin = Base and Mixins and Mixins(Base) or {}
local Entry = SaneUISettingsEntryMixin

function Entry:OnLoad()
    Base.OnLoad(self)
    local box = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetHeight(20)
    box:SetPoint("LEFT", self, "CENTER", -74, 0)
    box:SetScript("OnEnterPressed", function() self:Enter() end)
    box:SetScript("OnEscapePressed", function(edit) edit:ClearFocus() end)
    box:HookScript("OnEditFocusLost", function()
        if self.option then self:SetValue(self:GetSetting():GetValue()) end
    end)
    self.Box = box
    self.Unit = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.Unit:SetPoint("LEFT", box, "RIGHT", 8, 0)
end

-- The switch's description is the row's options (Switch below); the row keeps it while it shows it.
function Entry:Init(initializer)
    Base.Init(self, initializer)
    local option = initializer:GetOptions()
    local number = type(option.default) == "number"
    self.option = option
    self.Box:SetWidth(number and 70 or 214)
    self.Unit:SetText(number and option.unit or "")
    self:SetValue(self:GetSetting():GetValue())
    self:EvaluateState()
end

-- What was typed: a number for a number (on its step, within its ends: Panel.Number), set if it is
-- one and not the value there already.
function Entry:Enter()
    local option, setting = self.option, self:GetSetting()
    if not option then return end
    local value = self.Box:GetText() or ""
    if type(option.default) == "number" then value = Config.Panel.Number(option, value) end
    if value ~= nil and value ~= setting:GetValue() then setting:SetValue(value) end
    self.Box:ClearFocus()
    self:SetValue(setting:GetValue())
end

-- The game shows a value (its own, or one set elsewhere); not over what is being typed.
function Entry:SetValue(value)
    if not self.option or self.Box:HasFocus() then return end
    self.Box:SetText(Config.Panel.Written(self.option, value))
end

function Entry:EvaluateState()
    Base.EvaluateState(self)
    local enabled = self:IsEnabled()
    self.Box:SetEnabled(enabled)
    self:DisplayEnabled(enabled)
end

-- The game lets the row go (another page, scrolled away): what was being typed is dropped.
function Entry:Release()
    self.option = nil
    self.Box:ClearFocus()
    Base.Release(self)
end

-------------------------------------------------------------------------------
--  The switches on the game's lists
-------------------------------------------------------------------------------
-- What control a switch has, by its description: "button" (an action), "color" (six hex digits),
-- "multi" (several of a few), "choice" (one of a few), "slider" (a number between two ends),
-- "number" (a number typed: entry = true, or one without ends), "text" (words typed), "check" (on or
-- off); nil: none (no text, no default, or a value no control shows: a table).
function Config.Kind(option)
    if not option.text then return nil end
    if option.button then return "button" end
    if option.default == nil then return nil end
    if option.color then return "color" end
    if option.choices then return option.multi and "multi" or "choice" end
    local kind = type(option.default)
    if kind == "number" then return (option.max and not option.entry) and "slider" or "number" end
    if kind == "string" then return "text" end
    if kind == "boolean" then return "check" end
    return nil
end

-- Whether a switch's control is away now: its hidden(settings) says so. One that fails is noted,
-- and the control stays.
function Config.Hidden(name, option)
    if not option.hidden then return false end
    return Core.Safe(name .. ": hidden", option.hidden, Core.Settings(name) or {}) and true or false
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

-- The keys a switch is directly under: its parent, or each of its list.
local function Parents(option)
    local up = option.parent
    if type(up) == "table" then return up end
    return up ~= nil and { up } or {}
end

-- Every key a switch is under, its parents' parents too, nearest first; each once.
local function Above(option, byKey)
    local keys, seen, at = {}, {}, 1
    for _, key in ipairs(Parents(option)) do keys[#keys + 1] = key end
    while keys[at] do
        local key = keys[at]
        if seen[key] then
            table.remove(keys, at)
        else
            seen[key] = true
            local up = byKey[key]
            for _, more in ipairs(up and Parents(up) or {}) do keys[#keys + 1] = more end
            at = at + 1
        end
    end
    return keys
end

-- The game's name of a switch's setting.
local function Variable(name, key)
    return "SaneUI_" .. name .. "_" .. key
end

-- Several of a few (multi) as the game's dropdown of checkboxes keeps them: a number with a bit per
-- choice, the first choice the lowest (Settings.CreateDropdownOptionInserter); and back.
local function Mask(option, chosen)
    local mask = 0
    if type(chosen) ~= "table" then return mask end
    for index, choice in ipairs(option.choices) do
        if chosen[choice[1]] then mask = mask + 2 ^ (index - 1) end
    end
    return mask
end

local function Unmask(option, mask)
    local chosen = {}
    for index, choice in ipairs(option.choices) do
        if math.floor((tonumber(mask) or 0) / 2 ^ (index - 1)) % 2 == 1 then chosen[choice[1]] = true end
    end
    return chosen
end

-- One switch's control on a list page: a checkbox, a slider for a number between two ends (its
-- value written with Panel's format: decimals for small steps, its unit), a dropdown for one of a few
-- (option.choices) or several of them (multi: a dropdown of checkboxes), a box to type words or a
-- number into (the row above), a colour's swatch, a button for an action. The game makes the control
-- itself, and only when the page is opened. Its setting reads the module's settings and writes them
-- through Core.Set.
local function Switch(page, name, option)
    local kind, Panel = Config.Kind(option), Config.Panel
    local function Get()
        local settings = Core.Settings(name)
        return settings and settings[option.key]
    end
    local function Set(value) Core.Set(name, option.key, value) end
    local function Setting(variableKind, default, get, set)
        local setting = Settings.RegisterProxySetting(page, Variable(name, option.key), variableKind, option.text, default, get, set)
        Config.Show(setting)
        return setting
    end
    if kind == "button" then
        -- An action: the game's button row, without words of its own beside the button.
        return Add(page, CreateSettingsButtonInitializer("", option.text, function()
            Core.Safe(name .. ": " .. option.key, option.button)
        end, option.tip, true))
    elseif kind == "slider" then
        local setting = Setting("number", option.default, Get, function(value) Set(Panel.Step(option, value)) end)
        local slider = Settings.CreateSliderOptions(option.min or 0, option.max, option.step or 1)
        if MinimalSliderWithSteppersMixin then
            slider:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
                return Panel.Format(value, option.step, option.unit)
            end)
        end
        return Add(page, Settings.CreateSliderInitializer(setting, slider, option.tip))
    elseif kind == "choice" then
        local setting = Setting(type(option.default), option.default, Get, Set)
        return Add(page, Settings.CreateDropdownInitializer(setting, function()
            local container = Settings.CreateControlTextContainer()
            for _, choice in ipairs(option.choices) do container:Add(choice[1], choice[2]) end
            return container:GetData()
        end, option.tip))
    elseif kind == "multi" then
        local setting = Setting("number", Mask(option, option.default), function() return Mask(option, Get()) end,
            function(mask) Set(Unmask(option, mask)) end)
        return Add(page, Settings.CreateDropdownInitializer(setting, function()
            local container = Settings.CreateControlTextContainer()
            for index, choice in ipairs(option.choices) do container:AddCheckbox(index, choice[2]) end
            return container:GetData()
        end, option.tip))
    elseif kind == "text" or kind == "number" then
        if not (Base and Settings.CreateControlInitializer) then return nil end
        local setting = Setting(type(option.default), option.default, Get, Set)
        return Add(page, Settings.CreateControlInitializer("SaneUISettingsEntryTemplate", setting, option, option.tip))
    elseif kind == "color" then
        -- The game's swatch keeps a colour with its alpha in front ("FF26262B"); ours has none.
        if not Settings.CreateColorSwatchInitializer then return nil end
        local function Argb()
            local hex = Get()
            return "FF" .. (Core.RGB(hex) and hex or "FFFFFF")
        end
        local setting = Setting("string", "FF" .. tostring(option.default), Argb, function(value)
            if type(value) == "string" and #value == 8 then Set(value:sub(3):upper()) end
        end)
        return Add(page, Settings.CreateColorSwatchInitializer(setting, nil, option.tip))
    elseif kind == "check" then
        local setting = Setting("boolean", option.default, Get, Set)
        return Add(page, Settings.CreateCheckboxInitializer(setting, nil, option.tip))
    end
    return nil
end

-- A row under other switches (option.parent) is drawn under the first of them on its page (the
-- game's SetParentInitializer, indented) and greyed out while any switch above it is off
-- (Config.Free). The game looks at a row again only when the row it is drawn under changes: so it
-- also listens to every other switch above it (one more parent, a parent's parent), on any page.
-- One with hidden(settings) is not on the page while that says so (the game asks again after every
-- change, and closes the gap).
local function Wire(row, name, option, byKey, rows)
    if option.hidden and row.AddShownPredicate then
        row:AddShownPredicate(function() return not Config.Hidden(name, option) end)
    end
    if option.parent == nil or not row.AddModifyPredicate then return end
    local function Free() return Config.Free(Core.Settings(name) or {}, byKey, option) end
    local under, underKey
    for _, key in ipairs(Parents(option)) do
        if rows[key] then
            under, underKey = rows[key], key
            break
        end
    end
    if under and row.SetParentInitializer then
        row:SetParentInitializer(under, Free)
    else
        row:AddModifyPredicate(Free)
    end
    if not row.AddEvaluateStateCVar then return end -- by a setting's name, not only a CVar's
    for _, key in ipairs(Above(option, byKey)) do
        local up = byKey[key]
        local kind = up and Config.Kind(up)
        if key ~= underKey and kind and kind ~= "button" then row:AddEvaluateStateCVar(Variable(name, key)) end
    end
end

-- The controls of one module's switches. A switch with a header starts a section above it; one
-- without text is kept with the settings but has no control. One with parent is drawn under that
-- switch. (A module whose switches are in tabs has a page of our own instead: Tabbed.lua.)
-- onPage: only the switches that name that page (option.page; Core's: "Appearance"); nil, those that name none.
local function Fill(page, name, onPage)
    local list = Core.described[name].list
    local byKey, rows = {}, {}
    for _, option in ipairs(list) do byKey[option.key] = option end
    for _, option in ipairs(list) do
        local here = option.page == onPage
        if here and option.header then Add(page, CreateSettingsListSectionHeaderInitializer(option.header, option.headerTip)) end
        local row = here and Config.Kind(option) and Switch(page, name, option)
        if row then
            rows[option.key] = row
            Wire(row, name, option, byKey, rows)
        end
    end
end

-- The controls of the game's lists, made the first time the options are opened (long after the login,
-- when every module has described its switches and the pages are up):
--      Sane UI      its banner, its links and feedback (About.lua)
--      General      the switches of no module
--      Appearance   the look of Sane UI as a whole: the general switches that name it
--      Social, ...  a module's banner and switches
-- A page of our own (Profiles, a module's in tabs) is built when it is first shown (OwnPage).
function Config.Fill()
    local pages = Core.pages
    local top, profiles, general = pages.top, pages.Profiles, pages[Core.name]
    if filled or not top then return end
    filled = true
    Core.Safe("Settings: banner", AddBanner, top, ADDON)
    Core.Safe("Settings: about", Config.About.Fill, top)
    Core.Safe("Settings: " .. Core.name, Fill, general, Core.name)
    Core.Safe("Settings: Appearance", Fill, pages.Appearance, Core.name, "Appearance")
    local own = { [top] = true, [profiles] = true, [general] = true, [pages.Appearance] = true }
    for _, name in ipairs(Core.optionOrder) do
        local page = pages[name]
        if page and not own[page] and not Core.frames[name] then
            Core.Safe("Settings: banner of " .. name, AddBanner, page, SaneUI[name].addon)
            Core.Safe("Settings: " .. name, Fill, page, name)
        end
    end
end

-- The options, at Sane UI. The game does not let an addon open them in a fight: then they open
-- once it is over.
function Config.Open()
    local category = Core.pages.top
    if not category then return end
    if InCombatLockdown() then
        Core.Print(TEXT.afterFight)
        Core.AfterCombat("options", Config.Open)
        return
    end
    Core.Safe("options", Config.Fill)
    Settings.OpenToCategory(category:GetID())
end

Core.Command("options", TEXT.open, Config.Open, "config", "settings")

-- The minimap's addon list (## AddonCompartmentFunc in the TOC).
function SaneUI_OnAddonCompartmentClick()
    Config.Open()
end
