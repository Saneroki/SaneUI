local Config = SaneUI.Core.Config -- Settings.lua

-------------------------------------------------------------------------------
--  Sane UI - Core - Settings - CVars
--  The tab "CVars" on the page Profiles: every CVar of the game in one list,
--  to look up, change, and keep with Sane UI's settings.
--      over the list  a search box (a CVar's name, or the label the game's own
--                     options give it) and the game's filter button: only those
--                     not at their default, only kept ones, one kind of CVar
--                     (the game's kinds); its red cross clears them all
--      a row          a tick to keep it, its name with that label under it, its
--                     value in a box (type a new one, Enter sets it, Esc leaves
--                     it), and while it is not at its default the game's undo
--                     arrow, which gives it the default back
--      a row's tip    what it does, its default, where the game keeps it, and
--                     what cannot be done with it
--      under the list why the last change did not take, and how many are listed
--  Kept CVars are Sync's (Core.Sync.Keep).
--
--  The whole list is one frame (CVars.xml) filling the tab, with a scroll box of
--  its own, all of the game's parts (SearchBoxTemplate, WowStyle1FilterDropdownTemplate,
--  WowScrollBoxList, MinimalScrollBar; a row: UICheckButtonTemplate, InputBoxTemplate).
--  It is filled each time the tab is shown; what was searched and filtered is
--  kept here meanwhile.
--
--  The CVars come from the game (ConsoleGetAllCommands, the commands of the
--  kind CVar), when the list is first shown; their labels from its own options
--  (Data/CVarLabels.lua).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain

local TEXT = {
    header = "CVars",
    intro = "Every console setting of the game. Enter sets a typed value; a tick keeps the CVar in the profile in use.",
    notDefault = "Not at their default",
    kept = "Kept with Sane UI",
    kind = "Kind",
    everyKind = "Every kind",
    kinds = { game = "Game", graphics = "Graphics", sound = "Sound", combat = "Combat", net = "Network", other = "Other" },
    total = "%d CVars",
    matching = "%d matching",
    keep = "Keep with Sane UI's settings",
    keepTip = "Kept in the profile in use: the same on every character that uses it. Taken when you log out, set when a character comes into the game. Not with Accountwide settings off.",
    reset = "Back to the default",
    resetTip = "The game's default: %s",
    defaultIs = "Default: %s",
    character = "The game keeps it for this character.",
    account = "The game keeps it for your account.",
    computer = "The game keeps it on this computer.",
    fixed = "It cannot be changed.",
    secure = "Not in a fight.",
    inCombat = "The game does not let this one change in a fight.",
    heldAt = "The game keeps it at %s.",
    said = "%s: %s",
}

local CVars = {}
Config.CVars = CVars

-- The game's kinds of CVar (Enum.ConsoleCategory, by name) that the filter offers; the rest is "other".
local GROUPS = { Game = "game", Graphics = "graphics", Sound = "sound", Combat = "combat", Net = "net" }
local ORDER = { "game", "graphics", "sound", "combat", "net", "other" }

local all     -- every CVar: { name, lower, help, kind, label, tip, find }, by name; made when first shown
local byName  -- [lower name] = its entry
local filters = { search = "", kind = nil, notDefault = false, kept = false } -- kept between showings
local shown   -- the list's frame while the page shows it

-- A string of the game's by its name (Data/CVarLabels.lua); nil if this client has none.
local function GameString(name)
    local text = name and rawget(_G, name)
    return type(text) == "string" and text ~= "" and text or nil
end

-- Every CVar of the game, once.
function CVars.All()
    if all then return all end
    all, byName = {}, {}
    local ok, commands = pcall(ConsoleGetAllCommands)
    if not ok or type(commands) ~= "table" then return all end
    local isCVar, groups = Enum.ConsoleCommandType.Cvar, {}
    for category, group in pairs(GROUPS) do
        local value = Enum.ConsoleCategory[category]
        if value then groups[value] = group end
    end
    local labels = Config.CVAR_LABELS or {}
    for _, command in ipairs(commands) do
        local name = command.commandType == isCVar and command.command
        local lower = type(name) == "string" and name:lower()
        if lower and not byName[lower] and Plain(C_CVar.GetCVar(name)) ~= nil then
            local strings = labels[lower] or {}
            local entry = { name = name, lower = lower, kind = groups[command.category] or "other",
                help = type(command.help) == "string" and command.help ~= "" and command.help or nil,
                label = GameString(strings.label), tip = GameString(strings.tip) }
            entry.find = lower .. "\n" .. (entry.label and entry.label:lower() or "")
            all[#all + 1], byName[lower] = entry, entry
        end
    end
    table.sort(all, function(a, b) return a.lower < b.lower end)
    return all
end

-- What the game says of a CVar: value, default, kept for the account, for the character, locked,
-- secure (not in a fight), read-only. nil when there is no such CVar.
function CVars.Info(name)
    local ok, value, default, account, character, locked, secure, readOnly = pcall(C_CVar.GetCVarInfo, name)
    value = ok and Plain(value)
    if value == nil then return nil end
    return value, Plain(default), account, character, locked, secure, readOnly
end

local function NotDefault(name)
    local value, default = CVars.Info(name)
    return value ~= nil and value ~= default
end

-- Sync keeps CVars by name (none if it failed to load its settings).
local function Kept(name)
    local sync = Core.Sync
    return sync.options ~= nil and sync.Kept(name)
end

-- Whether a filter is set (the filter button's red cross is shown then).
local function Filtered()
    return filters.notDefault or filters.kept or filters.kind ~= nil
end

-- The CVars the search and the filters let through, in order.
function CVars.Shown()
    local search, list = filters.search:lower(), {}
    for _, entry in ipairs(CVars.All()) do
        if (search == "" or entry.find:find(search, 1, true)) and (not filters.kind or entry.kind == filters.kind)
            and (not filters.kept or Kept(entry.name)) and (not filters.notDefault or NotDefault(entry.name)) then
            list[#list + 1] = entry
        end
    end
    return list
end

-- Gives a CVar a value. Returns the value the game holds then, and a line why it is not the one
-- asked for (nil if it is).
function CVars.Set(name, value)
    local now, _, _, _, locked, secure, readOnly = CVars.Info(name)
    if now == nil then return nil end
    if locked or readOnly then return now, TEXT.fixed end
    if secure and InCombatLockdown() then return now, TEXT.inCombat end
    pcall(C_CVar.SetCVar, name, value)
    now = Plain(C_CVar.GetCVar(name))
    if now ~= value and not (tonumber(now) and tonumber(now) == tonumber(value)) then
        return now, TEXT.heldAt:format(tostring(now))
    end
    return now
end

function CVars.Keep(name, on)
    local sync = Core.Sync
    if sync.options then sync.Keep(name, on) end
end

-------------------------------------------------------------------------------
--  The list (CVars.xml): its frame, and its rows
-------------------------------------------------------------------------------
local Refilter = Core.Later(function()
    if shown then Core.Safe("Settings: CVars", shown.Refilter, shown) end
end, 0.15)
local Reread = Core.Later(function()
    if shown then Core.Safe("Settings: CVars", shown.Reread, shown) end
end, 0.1)
-- A CVar changed elsewhere (the game's options, a command): the values shown follow.
Core.On("CVAR_UPDATE", function()
    if shown then Reread() end
end)

-- The filter button's menu: two checkboxes, then the kinds.
local function FilterMenu(_, root)
    local function Flip(key) return function() filters[key] = not filters[key]; Refilter() end end
    root:CreateCheckbox(TEXT.notDefault, function() return filters.notDefault end, Flip("notDefault"))
    root:CreateCheckbox(TEXT.kept, function() return filters.kept end, Flip("kept"))
    root:CreateDivider()
    root:CreateTitle(TEXT.kind)
    local function IsKind(value) return filters.kind == (value ~= "" and value or nil) end
    local function SetKind(value)
        filters.kind = value ~= "" and value or nil
        Refilter()
    end
    root:CreateRadio(TEXT.everyKind, IsKind, SetKind, "")
    for _, value in ipairs(ORDER) do root:CreateRadio(TEXT.kinds[value], IsKind, SetKind, value) end
end

SaneUISettingsCVarsMixin = {}

function SaneUISettingsCVarsMixin:OnLoad()
    local search = CreateFrame("EditBox", nil, self, "SearchBoxTemplate")
    search:SetSize(210, 20)
    search:SetPoint("TOPLEFT", 6, -4)
    -- The game tells of every SetText too, ours in Init and its clear button's (without userInput):
    -- the list is filtered anew only when the words are other than those it was filtered by.
    search:HookScript("OnTextChanged", function(box)
        local text = box:GetText() or ""
        if text == filters.search then return end
        filters.search = text
        Refilter()
    end)
    self.Search = search

    local filter = CreateFrame("DropdownButton", nil, self, "WowStyle1FilterDropdownTemplate")
    filter:SetPoint("LEFT", search, "RIGHT", 12, 0)
    filter:SetupMenu(FilterMenu)
    if filter.SetIsDefaultCallback then
        filter:SetIsDefaultCallback(function() return not Filtered() end)
        filter:SetDefaultCallback(function()
            filters.notDefault, filters.kept, filters.kind = false, false, nil
            Refilter()
        end)
    end
    self.Filter = filter

    -- The list, with a scroll bar of its own.
    local box = CreateFrame("Frame", nil, self, "WowScrollBoxList")
    box:SetPoint("TOPLEFT", 0, -30)
    box:SetPoint("BOTTOMRIGHT", -16, 22)
    local back = box:CreateTexture(nil, "BACKGROUND")
    back:SetAllPoints()
    back:SetColorTexture(0, 0, 0, 0.25)
    local bar = CreateFrame("EventFrame", nil, self, "MinimalScrollBar")
    bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, 0)
    bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 4, 0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("SaneUISettingsCVarRowTemplate", function(row, entry) row:Init(entry) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(box, bar, view)
    self.List = box

    -- Under it: what the game said to the last change, and how many are listed.
    self.Count = self:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    self.Count:SetPoint("BOTTOMRIGHT", -4, 4)
    self.Status = self:CreateFontString(nil, "ARTWORK", "GameFontRedSmall")
    self.Status:SetPoint("BOTTOMLEFT", 4, 4)
    self.Status:SetPoint("RIGHT", self.Count, "LEFT", -12, 0)
    self.Status:SetJustifyH("LEFT")
end

-- The game shows the tab: what was searched and filtered before is back.
function SaneUISettingsCVarsMixin:Init()
    shown = self
    self.Search:SetText(filters.search)
    self.Status:SetText("")
    self:Refilter()
end

function SaneUISettingsCVarsMixin:Release()
    if shown == self then shown = nil end
end

function SaneUISettingsCVarsMixin:Refilter()
    local list = CVars.Shown()
    self.List:SetDataProvider(CreateDataProvider(list), ScrollBoxConstants.RetainScrollPosition)
    local filtered = Filtered() or filters.search ~= ""
    self.Count:SetText((filtered and TEXT.matching or TEXT.total):format(#list))
    if self.Filter.ValidateResetState then self.Filter:ValidateResetState() end
end

-- The values shown are read again (a CVar changed).
function SaneUISettingsCVarsMixin:Reread()
    self.List:ForEachFrame(function(row) row:Init(row.entry) end)
end

-- Why a change did not take (nil: it did).
function SaneUISettingsCVarsMixin:Say(name, why)
    self.Status:SetText(why and TEXT.said:format(name, why) or "")
end

-- Where the game keeps a CVar, its default, and what cannot be done with it, for its tip.
local function Details(name)
    local _, default, account, character, locked, secure, readOnly = CVars.Info(name)
    local lines = { TEXT.defaultIs:format(default or "?"), character and TEXT.character or account and TEXT.account or TEXT.computer }
    if locked or readOnly then lines[#lines + 1] = TEXT.fixed elseif secure then lines[#lines + 1] = TEXT.secure end
    return lines
end

SaneUISettingsCVarRowMixin = {}

function SaneUISettingsCVarRowMixin:OnLoad()
    self.Keep:SetScript("OnClick", function(box)
        if self.entry then CVars.Keep(self.entry.name, box:GetChecked()) end
        if filters.kept then Refilter() end
    end)
    self.Keep:SetScript("OnEnter", function(box)
        GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, TEXT.keep)
        GameTooltip_AddNormalLine(GameTooltip, TEXT.keepTip)
        GameTooltip:Show()
    end)
    self.Keep:SetScript("OnLeave", GameTooltip_Hide)

    local value = self.Value
    value:SetScript("OnEnterPressed", function(box) self:Give(box:GetText()) end)
    value:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
    value:SetScript("OnEditFocusLost", function() if self.entry then self:Init(self.entry) end end)
    value:SetScript("OnEnter", function() self:OnEnter() end)
    value:SetScript("OnLeave", GameTooltip_Hide)

    self.Reset:SetScript("OnClick", function()
        if self.entry then self:Give(select(2, CVars.Info(self.entry.name))) end
    end)
    self.Reset:SetScript("OnEnter", function(button)
        local default = self.entry and select(2, CVars.Info(self.entry.name))
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip_SetTitle(GameTooltip, TEXT.reset)
        GameTooltip_AddNormalLine(GameTooltip, TEXT.resetTip:format(tostring(default or "?")))
        GameTooltip:Show()
    end)
    self.Reset:SetScript("OnLeave", GameTooltip_Hide)
end

-- Every field is set: rows are used again for other CVars. What is being typed stays while the row
-- shows the same CVar.
function SaneUISettingsCVarRowMixin:Init(entry)
    if entry ~= self.entry and self.Value:HasFocus() then self.Value:ClearFocus() end
    self.entry = entry
    local value, default, _, _, locked, _, readOnly = CVars.Info(entry.name)
    local free = value ~= nil and not locked and not readOnly
    self.Name:SetText(entry.name)
    self.Label:SetText(entry.label or "")
    if not self.Value:HasFocus() then self.Value:SetText(value or "") end
    self.Value:SetEnabled(free)
    self.Reset:SetShown(free and value ~= default)
    self.Keep:SetChecked(Kept(entry.name))
    -- Kept CVars are the profile's: with Accountwide settings off there is none, and nothing is kept.
    self.Keep:SetEnabled(SaneUI.Core.Profiles.On())
end

-- Gives the row's CVar that value, and says under the list if the game keeps another.
function SaneUISettingsCVarRowMixin:Give(value)
    local entry = self.entry
    if not entry or value == nil then return end
    local _, why = CVars.Set(entry.name, value)
    if shown then shown:Say(entry.name, why) end
    self.Value:ClearFocus()
    self:Init(entry)
    if filters.notDefault then Refilter() end
end

-- A click on the row is a click into its value.
function SaneUISettingsCVarRowMixin:OnClick()
    if self.Value:IsEnabled() then self.Value:SetFocus() end
end

function SaneUISettingsCVarRowMixin:OnEnter()
    local entry = self.entry
    if not entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, entry.label or entry.name)
    if entry.label then GameTooltip_AddNormalLine(GameTooltip, entry.name) end
    local about = entry.tip or entry.help
    if about then GameTooltip_AddHighlightLine(GameTooltip, about, true) end
    for _, line in ipairs(Details(entry.name)) do GameTooltip_AddNormalLine(GameTooltip, line, true) end
    GameTooltip:Show()
end

function SaneUISettingsCVarRowMixin:OnLeave()
    GameTooltip_Hide()
end

-- The tab is shown: the list, made the first time (the page's other tabs do not need it), is shown anew.
local function ShowList(part)
    local list = part.list
    if not list then
        list = CreateFrame("Frame", nil, part, "SaneUISettingsCVarsTemplate")
        list:SetPoint("TOPLEFT", 8, -40)
        list:SetPoint("BOTTOMRIGHT", -8, 8)
        part.list = list
    end
    list:Init()
end

-- The tab CVars on the page Profiles: a line on what it is for, the list under it.
function Config.CVarsTab()
    return { name = TEXT.header, scroll = false, build = function(part)
        Config.Panel.Text(part, TEXT.intro, "GameFontHighlight", 12, -12)
        part:SetScript("OnShow", function() Core.Safe("Settings: CVars", ShowList, part) end)
        part:SetScript("OnHide", function()
            if part.list then part.list:Release() end
        end)
    end }
end
