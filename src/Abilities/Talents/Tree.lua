local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Talents - Tree
--  The talent frame itself: the game's shared talent frame (Blizzard_Shared-
--  TalentUI: TalentFrameBaseTemplate with its mixin, TalentFrameBaseMixin)
--  with the class talents' layer over it, as the game's ClassTalentsFrame-
--  Template is made (the shared ClassTalents/Blizzard_ClassTalentsFrame.lua,
--  Camelot's for this client): its keys (the trees' padding and place, the
--  commit's longest time, the grey's alpha, the commit's sound), its nodes
--  (Nodes.lua), its art and parts (Art, Headers, Specs, Foot, Commit), the
--  game's talent search (ClassTalentSearchMixin), and the methods by which the
--  game's shared frame asks the class frame: which config, which nodes are
--  made, where a node stands and how high, what an event means.
--
--  What the game's class frame asks of the game's window (the class, the
--  specialization, whether someone else is inspected) is answered here from
--  the player: the game's window is never asked. The template's zoom and pan
--  are left off: this client's trees are drawn at one zoom, so they would only
--  run a script every frame.
--
--  Events: the shared frame's and the class frame's, only while it is shown
--  (the three the shared frame keeps for good too); the player's auras, which
--  may let talents change, looked at once a frame and not in a fight. Every
--  method of ours stands behind the module's guard, and so do the scripts the
--  template gave the frame and its parts.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Class = Talents.Class
local Tree = {}
ns.TalentsTree = Tree

-- The class frame's keys (ClassTalentsFrameTemplate's KeyValues), over the template's: the trees 40 above the foot,
-- the commit's longest time, the grey's alpha, the flash and spinner of a commit, the tree loaded on every show. The
-- trees' place is the class's (Art.lua), the commit's bar ours (Commit.lua).
Tree.KEYS = {
    topPadding = 0, leftPadding = 0, bottomPadding = 40, rightPadding = 0,
    maximumCommitTime = 6, disabledOverlayAlpha = 0.5,
    enableCommitEndFlash = true, enableCommitCastBar = false, enableCommitSpinner = true,
    refreshOnShow = true, missingFromActionBarSuggested = false,
}
-- The events the class frame hears while shown (ClassTalentsFrameEvents and its own), the player's, and the three
-- the shared frame keeps for good (here: while shown).
Tree.EVENTS = { "ACTIVE_COMBAT_CONFIG_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_TALENT_UPDATE",
                "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" }
Tree.UNIT_EVENTS = { "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED" }
Tree.KEPT = { "TRAIT_CONFIG_UPDATED", "CONFIG_COMMIT_FAILED", "TRAIT_TREE_CHANGED" }
-- How the class frame layers its nodes, lower rows over higher ones (FrameLevelPerRow, TotalFrameLevelSpread,
-- BaseYOffset, BaseRowHeight).
Tree.PER_ROW, Tree.SPREAD, Tree.BASE_Y, Tree.ROW = 10, 500, 1500, 600

local frame       -- the one frame, once made
local wrapped = {} -- [gate] = true: the game's gates whose scripts we guarded

local function Base()
    return rawget(_G, "TalentFrameBaseMixin") or {}
end

local function Specs()
    return rawget(_G, "C_SpecializationInfo") or {}
end

-- The game's spell of a commit (Constants.TraitConsts.COMMIT_COMBAT_TRAIT_CONFIG_CHANGES_SPELL_ID).
local function CommitSpell()
    local constants = rawget(_G, "Constants")
    local traits = type(constants) == "table" and constants.TraitConsts
    return type(traits) == "table" and traits.COMMIT_COMBAT_TRAIT_CONFIG_CHANGES_SPELL_ID or nil
end

-- The player's auras changed: whether talents may change now, once a frame.
local Auras = Core.Later(function()
    if frame and frame:IsVisible() and not Talents.Fight() then
        frame:UpdateConfigButtonsState()
        frame:UpdateAllButtons()
    end
end)

-------------------------------------------------------------------------------
--  Made with the panel (Talents.lua)
-------------------------------------------------------------------------------
local Shown = ns.Guard(function(self) return Class.OnShow(self) end)
local Hidden = ns.Guard(function(self) return Class.OnHide(self) end)
local Heard = ns.Guard(function(self, ...) return Class.OnEvent(self, ...) end)
local Template = ns.Guard(function(...) return ns.TalentsNodes.Template(...) end)
local Specialized = ns.Guard(function(...) return ns.TalentsNodes.Mixin(...) end)
local Chosen = ns.Guard(function(...) return ns.TalentsNodes.Choice(...) end)
local Edge = ns.Guard(function(...) return ns.TalentsNodes.Edge(...) end)

-- The game's shared talent frame, with our class layer; nil where this client has none.
function Tree.Make(holder)
    if frame then return frame end
    if not (rawget(_G, "TalentFrameBaseMixin") and rawget(_G, "TalentButtonUtil")) then return nil end
    local made, created = pcall(CreateFrame, "Frame", nil, holder, "TalentFrameBaseTemplate")
    if not (made and type(created) == "table" and created.ButtonsParent and created.DisabledOverlay) then return nil end
    frame = created
    frame:SetSize(Talents.WIDTH, Talents.HEIGHT)
    frame:SetPoint("BOTTOM")
    for key, value in pairs(Tree.KEYS) do frame[key] = value end
    frame.commitSound = (rawget(_G, "SOUNDKIT") or {}).UI_CLASS_TALENT_APPLY_CHANGES
    frame.getTemplateType, frame.getSpecializedMixin = Template, Specialized
    frame.getSpecializedChoiceMixin, frame.getEdgeTemplateType = Chosen, Edge
    local search = rawget(_G, "ClassTalentSearchMixin")
    if type(search) == "table" then
        for key, fn in pairs(search) do frame[key] = fn end
    end
    for name, fn in pairs(Class) do frame[name] = ns.Guard(fn) end
    frame:SetScript("OnShow", Shown)
    frame:SetScript("OnHide", Hidden)
    frame:SetScript("OnEvent", Heard)
    Talents.Wrap(frame.SelectionChoiceFrame)
    frame:Load()
    return frame
end

-- What the full window's search box holds, marked on the nodes as the game's search marks them.
function Tree.Search(made, text)
    if not (made.IsSearchInitialized and made:IsSearchInitialized()) then return end
    if text == "" then
        made:ClearActiveSearchState()
        made:DisplayFullSearchResults()
    else
        made:SetFullResultSearch(text)
    end
end

-- The module stood down: its guarded scripts do nothing now, so the frame's events and the bar go here.
function Tree.Leave(made)
    made:UnregisterAllEvents()
    made:SetScript("OnUpdate", nil)
    ns.TalentsCommit.Run(made, false)
end

-------------------------------------------------------------------------------
--  The frame's methods: made, shown, hidden, told
-------------------------------------------------------------------------------
-- After the template's own OnLoad: what the class frame's OnLoad does more (ClassTalentsFrameMixin:OnLoad).
function Class:Load()
    if self.DisabledOverlay.GrayOverlay then self.DisabledOverlay.GrayOverlay:SetAlpha(self.disabledOverlayAlpha) end
    self:UpdatePadding()
    self:DisableZoomAndPan()
    for _, event in ipairs(Tree.KEPT) do self:UnregisterEvent(event) end
    ns.TalentsArt.Build(self)
    ns.TalentsHeaders.Build(self)
    ns.TalentsSpecs.Build(self)
    ns.TalentsFoot.Build(self)
    ns.TalentsCommit.Build(self)
    if rawget(_G, "SpellSearchControllerMixin") and rawget(_G, "TraitSearchSourceMixin") and self.InitializeSearch then
        self:InitializeSearch()
    end
    self:UpdateClassVisuals()
    self:SetTab(self:GetActiveTab())
    self:UpdateTabs()
    self:InitializeActiveSpec()
    self:RefreshCurrencyDisplay()
end

-- Opened: the active specialization, the tree loaded anew, the frame's events on (ClassTalentsFrameMixin:OnShowBase).
function Class:OnShow()
    Talents.Fighting(InCombatLockdown() or Core.Ask(rawget(_G, "UnitAffectingCombat"), "player") == true)
    self:UpdateSpecBackground()
    local activeTab = self:GetActiveTab()
    if self.tab ~= activeTab then self:SetTab(activeTab) end
    Base().OnShow(self)
    for _, event in ipairs(Tree.EVENTS) do self:RegisterEvent(event) end
    for _, event in ipairs(Tree.KEPT) do self:RegisterEvent(event) end
    for _, event in ipairs(Tree.UNIT_EVENTS) do self:RegisterUnitEvent(event, "player") end
    self:UpdateConfigButtonsState()
    self:UpdateAllButtons()
    self:SetBackgroundAnimationsPlaying(true)
end

function Class:OnHide()
    Base().OnHide(self)
    for _, event in ipairs(Tree.EVENTS) do self:UnregisterEvent(event) end
    for _, event in ipairs(Tree.KEPT) do self:UnregisterEvent(event) end
    for _, event in ipairs(Tree.UNIT_EVENTS) do self:UnregisterEvent(event) end
    self:SetBackgroundAnimationsPlaying(false)
    self:HideSpecChangeElements()
end

-- The class frame's events, then the shared frame's (ClassTalentsFrameMixin:OnEvent).
function Class:OnEvent(event, ...)
    if event == "ACTIVE_COMBAT_CONFIG_CHANGED" then
        self:OnConfigChanged((...))
    elseif event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdateSpecBackground()
        self:MarkTreeDirty()
    elseif event == "PLAYER_TALENT_UPDATE" then
        self:HandlePlayerTalentUpdate()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        Talents.Fighting(event == "PLAYER_REGEN_DISABLED")
        self:UpdateConfigButtonsState()
        self:UpdateAllButtons()
    elseif event == "UNIT_AURA" then
        if not Talents.Fight() then Auras() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local spellID = Core.Plain((select(3, ...)))
        if spellID ~= nil and spellID == CommitSpell() then
            local reasons = Base().VisualsUpdateReasons or {}
            self:SetCommitVisualsActive(false, reasons.CommitStoppedComplete)
            self:SetCommitCompleteVisualsActive(true)
        end
    end
    Base().OnEvent(self, event, ...)
end

-- The template's dirty marks done, then the search's marks and the foot (ClassTalentsFrameMixin:OnUpdate).
function Class:OnUpdate()
    Base().OnUpdate(self)
    if self.UpdateFullSearchResults then self:UpdateFullSearchResults() end
    self:UpdateConfigButtonsState()
end

-- A config of ours changed (TRAIT_CONFIG_UPDATED): it anew, and a commit into it done.
function Class:OnTraitConfigUpdated(configID)
    if configID == nil or configID ~= self:GetConfigID() then return end
    self:SetConfigID(configID, true)
    local reasons = Base().CommitUpdateReasons or {}
    self:SetCommitStarted(nil, reasons.CommitSucceeded)
    self:UpdateTreeCurrencyInfo(true)
end

-------------------------------------------------------------------------------
--  The frame's methods: the config and the tree
-------------------------------------------------------------------------------
function Class:SetConfigID(configID, forceUpdate)
    if configID then return Base().SetConfigID(self, configID, forceUpdate) end
    if not forceUpdate and configID == self:GetConfigID() then return end
    self.configurationInfo = nil
    self:SetTalentTreeID(nil, true)
end

function Class:UpdateTreeInfo(skipButtonUpdates)
    Base().UpdateTreeInfo(self, skipButtonUpdates)
    self:UpdateConfigButtonsState()
end

function Class:UpdateTreeCurrencyInfo(skipButtonUpdates)
    Base().UpdateTreeCurrencyInfo(self, skipButtonUpdates)
    self:RefreshCurrencyDisplay()
    self:RefreshTreeHeaders()
    if not skipButtonUpdates then self:RefreshConditionsCache() end
end

function Class:LoadTalentTreeInternal()
    Base().LoadTalentTreeInternal(self)
    self:UpdateConfigButtonsState()
end

-- The nodes made: all but those of hero talents, which this client has not (ShouldInstantiateNode).
function Class:ShouldInstantiateNode(_, nodeInfo)
    local enum = rawget(_G, "Enum") or {}
    local kinds = enum.TraitNodeType or {}
    return nodeInfo ~= nil and nodeInfo.subTreeID == nil
        and (kinds.SubTreeSelection == nil or nodeInfo.type ~= kinds.SubTreeSelection)
end

-- A node at its place among the trees (UpdateTalentButtonPosition).
function Class:UpdateTalentButtonPosition(button)
    local nodeInfo = button:GetNodeInfo()
    if not nodeInfo then return end
    if button:GetParent() ~= self.ButtonsParent then button:SetParent(self.ButtonsParent) end
    button:ClearAllPoints()
    button:SetPoint("CENTER", self.ButtonsParent, "TOPLEFT")
    rawget(_G, "TalentButtonUtil").ApplyPosition(button, self, nodeInfo.posX, nodeInfo.posY)
end

-- Lower rows over higher ones, so that the nodes' shadows and the arrows lie right (GetFrameLevelForButton).
function Class:GetFrameLevelForButton(nodeInfo)
    local rows = ((nodeInfo.posY or 0) - Tree.BASE_Y) / Tree.ROW * Tree.PER_ROW
    return Tree.SPREAD - math.floor(rows + 0.5)
end

-- The gates (a tree's points needed further down), one per currency, at the node's left; their scripts guarded.
function Class:RefreshGates()
    self.traitCurrencyIDToGate = {}
    Base().RefreshGates(self)
    if not (self.gatePool and self.gatePool.EnumerateActive) then return end
    for gate in self.gatePool:EnumerateActive() do
        if not wrapped[gate] then
            Talents.Wrap(gate)
            wrapped[gate] = true
        end
    end
end

function Class:ShouldDisplayGate(firstButton, condInfo)
    local gates = self.traitCurrencyIDToGate or {}
    return Base().ShouldDisplayGate(self, firstButton, condInfo)
        and (not condInfo.traitCurrencyID or not gates[condInfo.traitCurrencyID])
end

function Class:OnGateDisplayed(gate, _, condInfo)
    if condInfo.traitCurrencyID then
        self.traitCurrencyIDToGate = self.traitCurrencyIDToGate or {}
        self.traitCurrencyIDToGate[condInfo.traitCurrencyID] = gate
    end
end

function Class:AnchorGate(gate, button)
    gate:SetPoint("RIGHT", button, "LEFT")
end

-------------------------------------------------------------------------------
--  The frame's methods: what the class frame asks of the game's window, from the player
-------------------------------------------------------------------------------
function Class:IsInspecting()
    return false
end

function Class:GetInspectUnit()
    return nil
end

function Class:GetClassID()
    return select(3, UnitClass("player"))
end

function Class:GetClassName()
    return (UnitClass("player"))
end

function Class:GetSpecID()
    local index = Core.Ask(Specs().GetSpecialization)
    if not index then return nil end
    return (Core.Ask(Specs().GetSpecializationInfo, index))
end

-- The tree's name for the conditions in a node's tooltip: the group's name (Camelot's GetTraitTreeName).
function Class:GetTraitTreeName(treeID, groupIDs)
    if not groupIDs then return "" end
    local traits = rawget(_G, "C_Traits") or {}
    local displays = Core.Ask(traits.GetGroupDisplayInfoByTreeID, treeID)
    if type(displays) ~= "table" then return "" end
    for _, display in pairs(displays) do
        for _, groupID in ipairs(groupIDs) do
            if display.groupID == groupID then return display.displayName end
        end
    end
    return ""
end

-- What the game's search reads of a node's entry (ClassTalentsFrameMixin's).
function Class:GetDefinitionInfoForEntry(entryID)
    local entry = self:GetAndCacheEntryInfo(entryID)
    return entry and entry.definitionID and self:GetAndCacheDefinitionInfo(entry.definitionID) or nil
end

function Class:GetSubTreeInfoForEntry(entryID)
    local entry = self:GetAndCacheEntryInfo(entryID)
    return entry and entry.subTreeID and self:GetAndCacheSubTreeInfo(entry.subTreeID) or nil
end
