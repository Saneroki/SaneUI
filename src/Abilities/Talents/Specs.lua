local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Talents - Specs
--  Your primary and secondary specialization, as the game's class talents
--  frame offers them in this client (Camelot: ClassTalents/Blizzard_Class-
--  TalentsFrame.xml, its TabSystem with ClassTalentsFrameTabTemplate and
--  ClassTalentActiveSpecTemplate; their code in Camelot's Blizzard_Class-
--  TalentsFrame.lua):
--    - two of the game's tabs over the trees' top left corner (Primary,
--      Secondary; the game's top tabs, 150 to 200 wide): the active one marked
--      with the game's check, the secondary locked (the game's lock and its
--      reason) until you have learned a second specialization
--    - a tab shows that specialization's talents (C_SpecializationInfo's
--      config of that group); the inactive one only to look at
--    - in the top middle: Active over the active one, else the game's Activate
--      button, which switches to it (C_SpecializationInfo.SetActiveSpecGroup,
--      a cast: the trees are greyed and its bar shown over them until the game
--      says the switch is done); not in a fight, where the game switches none
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Class = Talents.Class
local Specs = {}
ns.TalentsSpecs = Specs

-- The game's places and sizes (ClassTalentsFrameTemplate's TabSystem, ClassTalentActiveSpecTemplate): the tabs from
-- the border's top left corner, their widths, their words' height in them; Active and Activate under the border's
-- top; the game's frame levels for them; the marks after a tab's name.
Specs.TABS_AT = { 70, -4 }
Specs.TAB_LEAST, Specs.TAB_MOST = 150, 200
Specs.TAB_TEXT_Y = -4
Specs.ACTIVE = { 164, 24 }
Specs.ACTIVATE = { 164, 22 }
Specs.ACTIVE_AT = -20
Specs.LEVEL, Specs.BUTTON_LEVEL = 1010, 4001
Specs.CHECK = { "Talents-Checkmark-c60", 20, 15 }
Specs.LOCK = { "Talents-lock-c60", 10, 14 }

local parts = {} -- [frame] = { tabs, primary, secondary, active, label, button }

local function SpecInfo()
    return rawget(_G, "C_SpecializationInfo") or {}
end

-- Whether a second specialization is learned (GetNumSpecGroups).
local function Unlocked()
    local groups = Core.Ask(rawget(_G, "GetNumSpecGroups"))
    return type(groups) == "number" and groups > 1
end

local function Markup(mark)
    local markup = rawget(_G, "CreateAtlasMarkup")
    return markup and markup(mark[1], mark[2], mark[3]) or ""
end

-------------------------------------------------------------------------------
--  The tabs (ClassTalentsFrameTabMixin)
-------------------------------------------------------------------------------
local TextOffset = ns.Guard(function() return Specs.TAB_TEXT_Y end)

-- A tab's name, with the game's check after the active one's and its lock after a locked one's.
local TabText = ns.Guard(function(tab)
    local mixin = rawget(_G, "TabSystemButtonMixin")
    local text = (mixin and mixin.GetTabText and mixin.GetTabText(tab)) or tab.tabText or ""
    if tab.isActive then return text .. " " .. Markup(Specs.CHECK) end
    -- Locked: the game asks whether the tab is enabled, which a chosen tab is not either; the lock is for a locked one.
    local locked
    if tab.IsForceDisabled then locked = tab:IsForceDisabled() else locked = not tab:IsEnabled() end
    if locked then return text .. " " .. Markup(Specs.LOCK) end
    return text
end)

local SetIsActive = ns.Guard(function(tab, active)
    tab.isActive = active
    tab:UpdateTabText()
end)

-- A tab as the game's class frame has it: its fonts, its words a little low, its marks.
local function Dress(tab)
    tab.selectedFontObject = rawget(_G, "GameFontHighlight")
    tab.unselectedFontObject = rawget(_G, "GameFontNormal")
    if tab.SetHighlightFontObject and rawget(_G, "GameFontHighlight") then tab:SetHighlightFontObject(GameFontHighlight) end
    tab.GetTextYOffset = TextOffset
    tab.GetTabText = TabText
    tab.SetIsActive = SetIsActive
    Talents.Wrap(tab)
    tab:SetTabSelected(false)
    tab:UpdateTabText()
end

-------------------------------------------------------------------------------
--  Active, or Activate (ClassTalentActiveSpecMixin)
-------------------------------------------------------------------------------
local function Refresh(frame)
    local part = parts[frame]
    if not part then return end
    local active = frame:IsActiveTabSelected()
    part.button:SetShown(not active)
    part.label:SetShown(active)
    local fight = Talents.Fight()
    part.button:SetEnabled(not fight)
    if part.button.SetDisabledTooltip then part.button:SetDisabledTooltip(fight and Talents.TEXT.fight or nil) end
end
Specs.Refresh = Refresh

local function Glow(frame, on)
    local part = parts[frame]
    if part then part.button.YellowGlow:SetShown(on) end
end

-------------------------------------------------------------------------------
--  Made with the frame (Tree.lua)
-------------------------------------------------------------------------------
function Specs.Build(frame)
    local part = {}
    -- The tabs: the game's tab system, its tabs the ones that hang from the top.
    local made, tabs = pcall(CreateFrame, "Frame", nil, frame, "TabSystemTemplate")
    if made and type(tabs) == "table" and tabs.AddTab then
        tabs.minTabWidth, tabs.maxTabWidth = Specs.TAB_LEAST, Specs.TAB_MOST
        local pool = rawget(_G, "CreateFramePool")
        if pool then tabs.tabPool = pool("BUTTON", tabs, "TabSystemTopButtonTemplate") end
        tabs:SetFrameLevel(Specs.LEVEL)
        tabs:SetPoint("BOTTOMLEFT", frame.BackgroundBorder, "TOPLEFT", Specs.TABS_AT[1], Specs.TABS_AT[2])
        tabs:SetTabSelectedCallback(ns.Guard(function(tabID) frame:SetTab(tabID) end))
        part.tabs = tabs
        part.primary = tabs:AddTab(Talents.TEXT.primary)
        part.secondary = tabs:AddTab(Talents.TEXT.secondary)
        for _, tabID in ipairs({ part.primary, part.secondary }) do Dress(tabs:GetTabButton(tabID)) end
    else
        part.primary, part.secondary = 1, 2 -- no tabs of the game's: the active specialization only
    end

    local active = CreateFrame("Frame", nil, frame)
    active:SetSize(Specs.ACTIVE[1], Specs.ACTIVE[2])
    active:SetFrameLevel(Specs.LEVEL)
    active:SetPoint("TOP", frame.BackgroundBorder, "TOP", 0, Specs.ACTIVE_AT)
    local label = active:CreateFontString(nil, "OVERLAY", "GameFontNormalLargeLeft")
    label:SetText(Talents.TEXT.active)
    label:SetPoint("CENTER")
    local green = rawget(_G, "GREEN_FONT_COLOR")
    if green and green.GetRGB then label:SetTextColor(green:GetRGB()) end
    local button = Talents.Button(active, Talents.TEXT.activate, Specs.ACTIVATE[1], Specs.ACTIVATE[2],
        ns.Guard(function() frame:ActivateSpec() end))
    button:SetPoint("CENTER")
    button:SetFrameLevel(Specs.BUTTON_LEVEL)
    button.YellowGlow = Talents.YellowGlow(button)
    active:SetScript("OnShow", ns.Guard(function()
        Glow(frame, false)
        Refresh(frame)
    end))
    part.active, part.label, part.button = active, label, button
    parts[frame] = part
end

-- What a frame's specializations are made of.
function Specs.Parts(frame)
    return parts[frame]
end

-------------------------------------------------------------------------------
--  The frame's methods (Camelot's ClassTalentsFrameMixin)
-------------------------------------------------------------------------------
function Class:GetActiveTab()
    local part = parts[self] or { primary = 1, secondary = 2 }
    local group = Core.Ask(SpecInfo().GetActiveSpecGroup)
    if group ~= nil and group ~= 1 then return part.secondary end
    return part.primary
end

function Class:GetTab()
    return self.tab
end

function Class:IsActiveTabSelected()
    return self:GetActiveTab() == self.tab
end

-- A tab chosen: that specialization's talents; with none yet (not learned), the trees greyed and Activate lit.
function Class:SetTab(tabID)
    self.tab = tabID
    local part = parts[self]
    if part and part.tabs then part.tabs:SetTabVisuallySelected(tabID) end
    local configID = Core.Ask(SpecInfo().GetCombatConfigIDForSpecGroup, tabID)
    if configID then
        self:SetConfigID(configID)
        Glow(self, false)
        self:HideSpecChangeElements()
    else
        self:SetDisabledOverlayShown(true)
        Glow(self, true)
    end
    Refresh(self)
end

function Class:UpdateTabs()
    local part = parts[self]
    if not (part and part.tabs) then return end
    part.tabs:SetTabEnabled(part.secondary, Unlocked(), Talents.TEXT.locked)
    local activeTab = self:GetActiveTab()
    for _, tabID in ipairs({ part.primary, part.secondary }) do
        local tab = part.tabs:GetTabButton(tabID)
        if tab and tab.SetIsActive then tab:SetIsActive(activeTab == tabID) end
    end
end

function Class:InitializeActiveSpec()
    local part = parts[self]
    if part then part.active:SetShown(Unlocked()) end
end

function Class:HandlePlayerTalentUpdate()
    self:UpdateTabs()
    self:InitializeActiveSpec()
end

-- The active specialization changed (ACTIVE_COMBAT_CONFIG_CHANGED): its talents, the switch's bar gone.
function Class:OnConfigChanged(configID)
    Refresh(self)
    self:HideSpecChangeElements()
    self:SetConfigID(configID, true)
end

function Class:HideSpecChangeElements()
    self:SetDisabledOverlayShown(false)
    self:SetSpecSwitchCastBarActive(false)
end

function Class:SetSpecSwitchCastBarActive(active)
    ns.TalentsCommit.Run(self, active)
end

-- Activate: the switch to the tab's specialization, a cast of the game's.
function Class:ActivateSpec()
    if Talents.Fight() then return end
    self:SetDisabledOverlayShown(true)
    self:SetSpecSwitchCastBarActive(true)
    local set = SpecInfo().SetActiveSpecGroup
    if set then set(self:GetTab()) end
end
