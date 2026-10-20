-- Runs Combat's own talents window (src/Combat/Talents/) against the stand-in client (wowstub.lua): the part on the
-- module's board, built on a stand-in of the game's shared talent frame (its mixin as small as the window needs, the
-- node buttons, tabs, red and round buttons, cast bar), fitted and centred in its panel, the three trees' heads with
-- their points and the unspent points, the nodes' templates and the class's glow, buying and refunding through the
-- nodes, applying (the commit and its cast bar of ours), undoing and resetting through the game's API, the primary
-- and secondary specialization, a fight, the search, events only while shown, and standing down. The look can only
-- be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/talents.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

-------------------------------------------------------------------------------
--  What the module needs of the client (as dev/tests/combat.lua)
-------------------------------------------------------------------------------
local methods = W.methods
UIParent._width, UIParent._height = 1920, 1080
function methods:GetLeft() return self._left end
function methods:GetBottom() return self._bottom end
function methods:GetTop() return self._bottom and self._bottom + self._height end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameLevel(level) self._level = level end
function methods:GetFrameLevel() return self._level or 1 end
function methods:SetClampedToScreen(on) self._clamped = on end
function methods:EnableMouse(on) self._mouse = on end
function methods:IsMouseEnabled() return self._mouse or false end
function methods:SetTexture(texture) self._texture = texture return true end
function methods:SetAtlas(atlas, own) self._atlas, self._own = atlas, own end
function methods:SetBlendMode(mode) self._blend = mode end
function methods:SetDesaturated(on) self._desaturated = on end
function methods:SetVertexColor(r, g, b, a) self._vertex = { r, g, b, a } end
function methods:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function methods:GetAttribute(name) return self._attributes and self._attributes[name] end
function methods:RegisterForClicks(...) self._clicks = { ... } end
function methods:RegisterForDrag(...) self._drag = { ... } end
function methods:UnregisterAllEvents() self._events = {} end
function methods:IsProtected() return false end
function methods:SetFont(file, size, flags) self._font = { file, size, flags } end
function methods:GetFont() return "font", 16, "" end
function methods:AddMaskTexture(mask) self._masks = self._masks or {}; self._masks[#self._masks + 1] = mask end
function methods:SetTextColor(r, g, b) self._color = { r, g, b } end
-- An animation group: played, stopped; its steps kept as made.
local function noop() end
function methods:CreateAnimationGroup()
    local group = { scripts = {}, playing = false, steps = {} }
    function group:SetScript(name, fn) self.scripts[name] = fn end
    function group:Play() self.playing = true end
    function group:Stop() self.playing = false end
    function group:IsPlaying() return self.playing end
    function group:Finish()
        self.playing = false
        if self.scripts.OnFinished then self.scripts.OnFinished(self) end
    end
    group.SetLooping, group.SetToFinalAlpha = function(self, how) self.looping = how end, noop
    function group:CreateAnimation(kind)
        local step = setmetatable({ kind = kind }, { __index = function() return noop end })
        function step:SetTarget(target) self.target = target end
        self.steps[#self.steps + 1] = step
        return step
    end
    self._groups = self._groups or {}
    self._groups[#self._groups + 1] = group
    return group
end
EasingUtil = { OutQuartic = function(p) return 1 - (1 - p) ^ 4 end }
IsMouseButtonDown = function() return false end
GetBindingKey = function() return nil end
ClearOverrideBindings, SetOverrideBinding = noop, noop
EventUtil = { ContinueOnAddOnLoaded = function() end }
local shift = false
IsShiftKeyDown = function() return shift end
UnitAffectingCombat = function() return W.combat end
CreateAtlasMarkup = function(atlas) return "|A:" .. atlas .. "|a" end
GREEN_FONT_COLOR = { GetRGB = function() return 0.1, 1, 0.1 end, GetRGBA = function() return 0.1, 1, 0.1, 1 end }
GRAY_FONT_COLOR = { GetRGBA = function() return 0.5, 0.5, 0.5, 1 end }
HIGHLIGHT_FONT_COLOR = { r = 1, g = 1, b = 1 }
GameFontHighlight, GameFontNormal = { name = "GameFontHighlight" }, { name = "GameFontNormal" }
UnitClass = function() return "Mage", "MAGE", 8 end
SOUNDKIT.UI_CLASS_TALENT_NODE_SPEND, SOUNDKIT.UI_CLASS_TALENT_NODE_SPEND_MAJOR = 11, 12
SOUNDKIT.UI_CLASS_TALENT_NODE_REFUND, SOUNDKIT.UI_CLASS_TALENT_APPLY_CHANGES = 13, 14
SOUNDKIT.UI_CLASS_TALENT_APPLY_COMPLETE = 15
local played = {}
PlaySound = function(kit) played[#played + 1] = kit end
local known = {} -- the atlases the client has
C_Texture = { GetAtlasInfo = function(atlas) return known[atlas] and { width = 1, height = 1 } or nil end }
known["talent-background-mage"], known["talents-animations-class-mage"] = true, true
Constants = { LevelConstsExposed = { MIN_TALENT_LEVEL = 10 }, TraitConsts = { COMMIT_COMBAT_TRAIT_CONFIG_CHANGES_SPELL_ID = 384255 } }

-------------------------------------------------------------------------------
--  The talents as the game holds them: three trees (groups) of one tree, a few nodes, two specializations
-------------------------------------------------------------------------------
Enum.TraitNodeEntryType = { SpendSquare = 1, SpendCircle = 2, SpendCapstoneCircle = 5, SpendCapstoneSquare = 6 }
Enum.TraitNodeType = { Single = 0, Tiered = 1, Selection = 2, SubTreeSelection = 3 }
Enum.TraitNodeFlag = { ShowMultipleIcons = 1, ShowTierTrack = 4 }
Enum.TraitEdgeVisualStyle = { None = 0, Straight = 1 }
local TREE, CURRENCY = 900, 77
local groups = { { groupID = 11, displayName = "Arcane", icon = 101 }, { groupID = 12, displayName = "Fire", icon = 102 },
                 { groupID = 13, displayName = "Frost", icon = 103 } }
local nodes = {
    [1] = { group = 11, posX = 1000, posY = 1500, maxRanks = 5, ranksPurchased = 2, kind = 1 },
    [2] = { group = 11, posX = 1000, posY = 2100, maxRanks = 3, ranksPurchased = 0, kind = 2 },
    [3] = { group = 12, posX = 5000, posY = 1500, maxRanks = 1, ranksPurchased = 1, kind = 2 },
    [4] = { group = 13, posX = 9000, posY = 1500, maxRanks = 2, ranksPurchased = 0, kind = 1, needs = 2 },
    [5] = { group = 13, posX = 9000, posY = 2700, maxRanks = 1, ranksPurchased = 0, kind = 2, choice = true },
    [6] = { group = 13, posX = 9000, posY = 3300, maxRanks = 1, ranksPurchased = 0, kind = 2, subTreeID = 40 },
}
local unspent, staged, calls = 4, {}, {}
local activeGroup, groups2, earned = 1, 2, true
local function Call(name, ...) calls[#calls + 1] = { name, ... } end
local function Staged()
    for _, count in pairs(staged) do if count ~= 0 then return true end end
    return false
end
local function Ranks(id) return nodes[id].ranksPurchased + (staged[id] or 0) end
local function Spent(group)
    local spent = 0
    for id, node in pairs(nodes) do if node.group == group then spent = spent + Ranks(id) end end
    return spent
end
local function Info(id)
    local node = nodes[id]
    local ranks = Ranks(id)
    local free = unspent - (function() local s = 0 for _, c in pairs(staged) do s = s + c end return s end)()
    local meets = not node.needs or Ranks(node.needs) > 0
    return { ID = id, posX = node.posX, posY = node.posY, maxRanks = node.maxRanks, ranksPurchased = ranks,
             activeRank = ranks, currentRank = ranks, isVisible = true, meetsEdgeRequirements = meets,
             canPurchaseRank = meets and ranks < node.maxRanks and free > 0, canRefundRank = ranks > 0,
             type = node.choice and Enum.TraitNodeType.Selection or Enum.TraitNodeType.Single,
             flags = node.choice and Enum.TraitNodeFlag.ShowMultipleIcons or 0, subTreeID = node.subTreeID,
             activeEntry = { entryID = id * 10 }, groupIDs = { node.group }, visibleEdges = {} }
end
C_Traits = {
    GetConfigInfo = function(configID) return { ID = configID, treeIDs = { TREE } } end,
    GetTreeInfo = function(_, treeID) return { ID = treeID, gates = {} } end,
    GetTreeNodes = function() return { 1, 2, 3, 4, 5, 6 } end,
    GetNodeInfo = function(_, id) return Info(id) end,
    GetEntryInfo = function(_, entryID) return { type = nodes[entryID / 10].kind, definitionID = entryID } end,
    GetDefinitionInfo = function(id) return { spellID = id } end,
    GetTreeCurrencyInfo = function()
        local spent = 0
        for _, count in pairs(staged) do spent = spent + count end
        return { { traitCurrencyID = CURRENCY, quantity = unspent - spent, spent = 3 + spent } }
    end,
    GetGroupDisplayInfoByTreeID = function() return groups end,
    GetGroupCurrencyInfo = function(_, ids)
        local list = {}
        for index, id in ipairs(ids) do list[index] = { traitNodeGroupID = id, currencyInfos = { { spent = Spent(id) } } } end
        return list
    end,
    PurchaseRank = function(configID, id) Call("PurchaseRank", configID, id) staged[id] = (staged[id] or 0) + 1 return true end,
    RefundRank = function(configID, id, clear) Call("RefundRank", configID, id, clear) staged[id] = (staged[id] or 0) - 1 return true end,
    SetSelection = function(configID, id, entryID) Call("SetSelection", configID, id, entryID) return true end,
    ConfigHasStagedChanges = function() return Staged() end,
    RollbackConfig = function(configID) Call("RollbackConfig", configID) staged = {} return true end,
    ResetTreeByCurrency = function(configID, treeID, currency)
        Call("ResetTreeByCurrency", configID, treeID, currency)
        for id in pairs(nodes) do staged[id] = -nodes[id].ranksPurchased end
        return true
    end,
    GetStagedChanges = function()
        local bought = {}
        for id, count in pairs(staged) do if count > 0 then bought[#bought + 1] = id end end
        return bought, {}, {}
    end,
}
C_ClassTalents = {
    GetActiveConfigID = function() return 100 + activeGroup end,
    CanChangeTalents = function()
        if W.combat then return false, false, "You can't do that in combat." end
        return Staged(), Staged(), nil
    end,
    CommitConfig = function(saved)
        Call("CommitConfig", saved)
        for id, count in pairs(staged) do nodes[id].ranksPurchased = nodes[id].ranksPurchased + count unspent = unspent - count end
        staged = {}
        return true
    end,
}
C_SpecializationInfo = {
    GetActiveSpecGroup = function() return activeGroup end,
    GetCombatConfigIDForSpecGroup = function(group) return group <= groups2 and 100 + group or nil end,
    SetActiveSpecGroup = function(group) Call("SetActiveSpecGroup", group) end,
    HasPlayerEarnedATalentPoint = function() return earned end,
    GetSpecialization = function() return 1 end,
    GetSpecializationInfo = function() return 1482 end,
}
GetNumSpecGroups = function() return groups2 end

-------------------------------------------------------------------------------
--  The game's shared talent frame, as small as the window needs (Blizzard_SharedTalentUI's TalentFrameBaseMixin)
-------------------------------------------------------------------------------
local Base = {}
Base.CommitUpdateReasons = { CommitStarted = 1, CommitSucceeded = 2, CommitFailed = 3, InstantCommit = 4 }
Base.VisualsUpdateReasons = { FrameHidden = 1, CommitOngoing = 2, CommitStoppedComplete = 3, CommitStoppedIncomplete = 4 }
local BASE_EVENTS = { "TRAIT_NODE_CHANGED", "TRAIT_NODE_CHANGED_PARTIAL", "TRAIT_NODE_ENTRY_UPDATED",
                      "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_SUB_TREE_CHANGED" }
local STANDARD = { "OnLoad", "OnShow", "OnHide", "OnEvent", "OnEnter", "OnLeave", "OnClick", "OnDragStart", "OnReceiveDrag" }
-- A frame made with a specialization, as the game's pools make them (FrameUtil.SpecializeFrameWithMixins).
local function Specialize(widget, mixin)
    for key, value in pairs(mixin) do widget[key] = value end
    for _, name in ipairs(STANDARD) do if widget[name] then widget:SetScript(name, widget[name]) end end
    if widget.OnLoad then widget:OnLoad() end
end
function Base:OnLoad()
    self.buttons, self.order = {}, {}
    self.panOffsetX, self.panOffsetY = 0, 0
    self.gatePool = { EnumerateActive = function() return function() return nil end end }
    self:SetBasePanOffset(self.basePanOffsetX or 0, self.basePanOffsetY or 0)
    self:RegisterEvent("TRAIT_CONFIG_UPDATED")
    self:RegisterEvent("CONFIG_COMMIT_FAILED")
    self:RegisterEvent("TRAIT_TREE_CHANGED")
end
function Base:RegisterOnUpdate() self:SetScript("OnUpdate", self.OnUpdate) end
function Base:OnUpdate()
    self:SetScript("OnUpdate", nil)
    if self.treeIsDirty then return self:LoadTalentTree() end
    for _, button in pairs(self.buttons) do button:UpdateNodeInfo() end
end
function Base:OnShow()
    for _, event in ipairs(BASE_EVENTS) do self:RegisterEvent(event) end
    if self.refreshOnShow or self.treeIsDirty then self:LoadTalentTree() end
    if self:IsCommitInProgress() then
        self:SetCommitVisualsActive(true, Base.VisualsUpdateReasons.CommitOngoing, true)
    else
        self:SetCommitVisualsActive(false, Base.VisualsUpdateReasons.CommitStoppedIncomplete)
    end
end
function Base:OnHide()
    for _, event in ipairs(BASE_EVENTS) do self:UnregisterEvent(event) end
    self:SetCommitVisualsActive(false, Base.VisualsUpdateReasons.FrameHidden)
    self:SetCommitCompleteVisualsActive(false)
end
function Base:OnEvent(event, ...)
    if event == "TRAIT_NODE_CHANGED" then
        self:RegisterOnUpdate()
    elseif event == "TRAIT_TREE_CURRENCY_INFO_UPDATED" then
        if (...) == self:GetTalentTreeID() and not self:IsCommitInProgress() then self:UpdateTreeCurrencyInfo() end
    elseif event == "TRAIT_CONFIG_UPDATED" then
        self:OnTraitConfigUpdated((...))
    elseif event == "CONFIG_COMMIT_FAILED" then
        if self:IsCommitInProgress() then
            self:SetCommitStarted(nil, Base.CommitUpdateReasons.CommitFailed)
            self:UpdateTreeCurrencyInfo()
        end
    elseif event == "TRAIT_TREE_CHANGED" then
        if (...) == self:GetTalentTreeID() then self:MarkTreeDirty() end
    end
end
function Base:OnTraitConfigUpdated() end
function Base:SetBasePanOffset(x, y) self.basePanOffsetX, self.basePanOffsetY = x, y end
function Base:GetPanOffset() return self.basePanOffsetX + self.panOffsetX, self.basePanOffsetY + self.panOffsetY end
function Base:UpdatePadding() self._padded = { self.leftPadding, self.topPadding, self.rightPadding, self.bottomPadding } end
function Base:DisableZoomAndPan()
    self.ButtonsParent:SetScript("OnUpdate", nil)
    self.ButtonsParent:SetScript("OnMouseWheel", nil)
    self.ButtonsParent:EnableMouse(false)
end
function Base:UpdateAllTalentButtonPositions()
    for _, button in pairs(self.buttons) do self:UpdateTalentButtonPosition(button) end
end
function Base:SetConfigID(configID, forceUpdate)
    if not forceUpdate and configID == self:GetConfigID() then return end
    local info = configID and C_Traits.GetConfigInfo(configID)
    if not info then return end
    self.configurationInfo = info
    self:SetTalentTreeID(info.treeIDs[1], true)
end
function Base:GetConfigID() return self.configurationInfo and self.configurationInfo.ID or nil end
function Base:SetTalentTreeID(treeID, forceUpdate)
    if not forceUpdate and treeID == self.talentTreeID then return false end
    self.talentTreeID = treeID
    self:LoadTalentTree()
    return true
end
function Base:GetTalentTreeID() return self.talentTreeID end
function Base:MarkTreeDirty() self.treeIsDirty = true self:RegisterOnUpdate() end
function Base:LoadTalentTree()
    if not (self:GetConfigID() and self:GetTalentTreeID()) then return end
    if not self:IsVisible() then return self:MarkTreeDirty() end
    self:UpdateTreeInfo(true)
    self:LoadTalentTreeInternal()
end
function Base:UpdateTreeInfo(skipButtonUpdates)
    self.talentTreeInfo = C_Traits.GetTreeInfo(self:GetConfigID(), self:GetTalentTreeID())
    self:UpdateTreeCurrencyInfo(skipButtonUpdates)
    if not skipButtonUpdates then self:RefreshGates() end
end
function Base:UpdateTreeCurrencyInfo(skipButtonUpdates)
    self.treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(self:GetConfigID(), self:GetTalentTreeID())
    if not skipButtonUpdates then self:UpdateAllButtons() end
end
function Base:GetTreeInfo() return self.talentTreeInfo end
function Base:LoadTalentTreeInternal()
    for _, button in pairs(self.buttons) do button:Hide() end
    self.buttons = {}
    self.loads = (self.loads or 0) + 1
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(self:GetTalentTreeID())) do
        local nodeInfo = self:GetAndCacheNodeInfo(nodeID)
        if nodeInfo.isVisible and self:ShouldInstantiateNode(nodeID, nodeInfo) then
            local entry = self:GetAndCacheEntryInfo(nodeInfo.activeEntry.entryID)
            local template = self.getTemplateType(nodeInfo, entry.type)
            local button = CreateFrame("Button", nil, self.ButtonsParent, template)
            Specialize(button, self.getSpecializedMixin(nodeInfo, entry.type))
            button:Init(self)
            button:SetNodeID(nodeID)
            self:UpdateTalentButtonPosition(button)
            button:SetFrameLevel(self:GetFrameLevelForButton(nodeInfo))
            self.buttons[nodeID] = button
        end
    end
    self:RefreshGates()
    self.treeIsDirty = nil
end
function Base:RefreshGates() self.gatesRefreshed = (self.gatesRefreshed or 0) + 1 end
function Base:ShouldDisplayGate(_, condInfo) return not condInfo.isMet end
function Base:RefreshConditionsCache() self:RefreshGates() end
function Base:UpdateAllButtons() for _, button in pairs(self.buttons) do button:FullUpdate() end end
function Base:EnumerateAllTalentButtons()
    local list = {}
    for _, button in pairs(self.buttons) do list[#list + 1] = button end
    local index = 0
    return function() index = index + 1 return list[index] end
end
function Base:GetAndCacheNodeInfo(nodeID) return C_Traits.GetNodeInfo(self:GetConfigID(), nodeID) end
function Base:GetAndCacheEntryInfo(entryID) return C_Traits.GetEntryInfo(self:GetConfigID(), entryID) end
function Base:GetAndCacheDefinitionInfo(id) return C_Traits.GetDefinitionInfo(id) end
function Base:GetAndCacheSubTreeInfo() return nil end
function Base:HasAnyPurchasedRanks()
    for _, button in pairs(self.buttons) do if button.nodeInfo and button.nodeInfo.ranksPurchased > 0 then return true end end
    return false
end
function Base:AreSelectionsOpen(button) return self.selectionsOf == button end
function Base:IsCommitInProgress() return self.commitedConfigID ~= nil end
function Base:CheckAndReportCommitOperation()
    if self:IsCommitInProgress() then
        W.errors[#W.errors + 1] = self:GetConfigCommitErrorString()
        return false
    end
    return self:GetConfigID() ~= nil
end
function Base:AttemptConfigOperation(operation, ...)
    if not self:CheckAndReportCommitOperation() then return false end
    if not operation(self:GetConfigID(), ...) then return false end
    return true
end
function Base:PurchaseRank(nodeID) return self:AttemptConfigOperation(C_Traits.PurchaseRank, nodeID) end
function Base:SetCommitStarted(configID, reason)
    local started, was = configID ~= nil, self:IsCommitInProgress()
    self.commitedConfigID = configID
    if reason == Base.CommitUpdateReasons.CommitFailed then
        self:SetCommitVisualsActive(false, Base.VisualsUpdateReasons.CommitStoppedIncomplete)
    elseif started ~= was then
        self:SetCommitVisualsActive(started, started and Base.VisualsUpdateReasons.CommitOngoing or Base.VisualsUpdateReasons.CommitStoppedComplete)
    end
    if reason == Base.CommitUpdateReasons.CommitSucceeded then self:SetCommitCompleteVisualsActive(true) end
end
function Base:CommitConfig()
    if self:IsCommitInProgress() or not self:CheckAndReportCommitOperation() then return end
    played[#played + 1] = self.commitSound
    self:SetCommitStarted(self:GetConfigID(), Base.CommitUpdateReasons.CommitStarted)
    return self:CommitConfigInternal()
end
function Base:RollbackConfig()
    if not self:CheckAndReportCommitOperation() then return end
    return C_Traits.RollbackConfig(self:GetConfigID())
end
function Base:SetDisabledOverlayShown(shown) self.DisabledOverlay:SetShown(shown) end
function Base:SetCommitCompleteVisualsActive(active) self.endFlash = active and self.enableCommitEndFlash end
TalentFrameBaseMixin = nil -- not loaded yet: the first panel finds no talent frame of the game's

W.templates.TalentFrameBaseTemplate = function(frame)
    for key, value in pairs(TalentFrameBaseMixin) do frame[key] = value end
    frame.ButtonsParent = W.NewWidget("Frame", nil, frame)
    frame.ButtonsParent:EnableMouse(true)
    frame.ButtonsParent:SetScript("OnUpdate", noop)
    frame.DisabledOverlay = W.NewWidget("Frame", nil, frame)
    frame.DisabledOverlay.GrayOverlay = W.NewWidget("Texture", nil, frame.DisabledOverlay)
    frame.DisabledOverlay:Hide()
    frame.DisabledOverlay._level = 4000
    frame.CommitSpinner = W.NewWidget("Frame", nil, frame)
    frame.CommitSpinner:SetScript("OnShow", noop)
    frame.CommitSpinner:Hide()
    frame.SelectionChoiceFrame = W.NewWidget("Frame", nil, frame)
    frame.SelectionChoiceFrame:SetScript("OnShow", noop)
    frame.BackgroundFlash = W.NewWidget("Texture", nil, frame)
    -- The template's keys, before the class frame's.
    frame.buttonSize, frame.topPadding, frame.leftPadding, frame.bottomPadding, frame.rightPadding = 40, 0, 0, 0, 0
    frame.basePanOffsetX, frame.basePanOffsetY, frame.maximumCommitTime, frame.disabledOverlayAlpha = 0, 0, 3, 0.4
    frame.enableZoomAndPan, frame.enableCommitEndFlash = true, false
    frame:SetScript("OnShow", frame.OnShow)
    frame:SetScript("OnHide", frame.OnHide)
    frame:SetScript("OnEvent", frame.OnEvent)
    frame:OnLoad()
end
TalentButtonUtil = {
    BaseVisualState = { Normal = 1, Gated = 2, Disabled = 3, Locked = 4, Selectable = 5, Maxed = 6 },
    ApplyPosition = function(button, frame, x, y)
        local panX, panY = frame:GetPanOffset()
        button._at = { x / 10 - panX, -y / 10 + panY }
    end,
}
local State = TalentButtonUtil.BaseVisualState

-- The game's node buttons: their art (TalentButtonArtTemplate) and their mixins, as small as the window needs.
for _, name in ipairs({ "TalentButtonSquareTemplate", "TalentButtonCircleTemplate", "TalentButtonChoiceTemplate" }) do
    W.templates[name] = function(button)
        button.template = name
        button.artSet = { glow = name == "TalentButtonSquareTemplate" and "talents-node-square-greenglow" or "talents-node-circle-greenglow" }
        button.Glow = W.NewWidget("Texture", nil, button)
        button.SearchIcon = W.NewWidget("Frame", nil, button)
    end
end
TalentDisplayMixin = {
    OnEnter = function(self) self._entered = true end,
    OnLeave = function(self) self._entered = false end,
    Init = function(self, talentFrame) self.talentFrame = talentFrame end,
    SetSearchMatchType = function(self, match) self.matchType = match end,
}
TalentButtonArtMixin = {
    UpdateStateBorder = function(self, state) self._border = state end,
    UpdateGlow = function(self) self.Glow:SetShown(self.shouldGlow or false) end,
}
local Button = CreateFromMixins(TalentDisplayMixin)
function Button:OnLoad() self:RegisterForDrag("LeftButton") end
function Button:GetTalentFrame() return self.talentFrame end
function Button:SetNodeID(nodeID) self.nodeID = nodeID self:UpdateNodeInfo() end
function Button:GetNodeID() return self.nodeID end
function Button:GetNodeInfo() return self.nodeInfo end
function Button:UpdateNodeInfo()
    self.nodeInfo = self.talentFrame:GetAndCacheNodeInfo(self.nodeID)
    self:UpdateEntryInfo()
    self:FullUpdate()
end
function Button:UpdateEntryInfo() self.entryInfo = self.talentFrame:GetAndCacheEntryInfo(self.nodeInfo.activeEntry.entryID) end
function Button:IsLocked() return not self.nodeInfo.meetsEdgeRequirements or self.talentFrame:IsLocked() end
function Button:IsRefundInvalid() return false end
function Button:CanPurchaseRank() return not self:IsLocked() and self.nodeInfo.canPurchaseRank end
function Button:CanRefundRank() return not self:IsLocked() and self.nodeInfo.canRefundRank end
function Button:FullUpdate()
    local state = (self:IsLocked() and State.Locked) or (self:CanPurchaseRank() and State.Selectable) or State.Normal
    self.visualState = state
    self:UpdateStateBorder(state)
    self:UpdateGlow()
end
function Button:OnClick(button)
    if button == "LeftButton" and self:CanPurchaseRank() then
        played[#played + 1] = self.selectSound
        self.talentFrame:PurchaseRank(self.nodeID)
    elseif button == "RightButton" and self:CanRefundRank() then
        played[#played + 1] = self.deselectSound
        self.talentFrame:RefundRank(self.nodeID)
    end
end
TalentButtonSpendMixin = CreateFromMixins(Button)
TalentButtonSelectMixin = CreateFromMixins(Button, {
    OnUpdate = function(self) self._updated = true end,
    ShowSelections = function(self) self.talentFrame.selectionsOf = self end,
    ClearSelections = function(self) self.talentFrame.selectionsOf = nil end,
})
TalentButtonSplitSelectMixin = CreateFromMixins(TalentButtonSelectMixin)
TalentSelectionChoiceArtMixin = { SetSelectionInfo = function(self, info) self.entryInfo = info end, UpdateSpendText = noop }
-- The game's search (ClassTalentSearchMixin, on Blizzard_SpellSearch): a node named like the text is marked.
SpellSearchControllerMixin, TraitSearchSourceMixin = {}, {}
ClassTalentSearchMixin = {
    InitializeSearch = function(self) self.searching = true end,
    IsSearchInitialized = function(self) return self.searching end,
    SetFullResultSearch = function(self, text) self.searchText = text self:DisplayFullSearchResults() end,
    ClearActiveSearchState = function(self) self.searchText = nil end,
    DisplayFullSearchResults = function(self)
        for button in self:EnumerateAllTalentButtons() do
            button:SetSearchMatchType(self.searchText and tostring(button.nodeID) == self.searchText and 3 or nil)
        end
    end,
    UpdateFullSearchResults = function(self) self:DisplayFullSearchResults() end,
}

-- The game's tabs (TabSystemTemplate, its top tabs) and buttons (red, round, the reset's dropdown), and its cast bar.
CreateFramePool = function(kind, parent, template)
    return { template = template, Acquire = function() return CreateFrame(kind, nil, parent, template) end }
end
W.templates.TabSystemTemplate = function(tabs)
    tabs.tabs = {}
    tabs.tabPool = CreateFramePool("BUTTON", tabs, "TabSystemButtonTemplate")
    function tabs:AddTab(text)
        local tab = self.tabPool:Acquire()
        local id = #self.tabs + 1
        self.tabs[id] = tab
        tab:Init(id, text)
        return id
    end
    function tabs:SetTabSelectedCallback(fn) self.callback = fn end
    function tabs:SetTab(id) if not self.callback(id, true) then self:SetTabVisuallySelected(id) end end
    function tabs:SetTabVisuallySelected(id)
        self.selectedTabID = id
        for index, tab in ipairs(self.tabs) do tab:SetTabSelected(index == id) end
    end
    function tabs:SetTabEnabled(id, enabled, reason) self.tabs[id]:SetTabEnabled(enabled, reason) end
    function tabs:GetTabButton(id) return self.tabs[id] end
end
TabSystemButtonMixin = { GetTabText = function(tab) return tab.tabText end }
W.templates.TabSystemTopButtonTemplate = function(tab)
    tab.Text = W.NewWidget("FontString", nil, tab)
    tab.isTabOnTop = true
    function tab:Init(id, text) self.tabID, self.tabText = id, text self:SetTabSelected(false) self:UpdateTabText() end
    function tab:SetTabSelected(on) self.isSelected = on self:SetEnabled(not on and not self.forceDisabled) end
    function tab:SetTabEnabled(on, reason) self.forceDisabled, self.errorReason = not on, reason self:SetEnabled(on and not self.isSelected) self:UpdateTabText() end
    function tab:IsForceDisabled() return self.forceDisabled end
    function tab:UpdateTabText() self.Text:SetText(self:GetTabText()) end
    tab:SetScript("OnClick", function(self) self:GetParent():SetTab(self.tabID) end)
end
local function RedButton(button)
    function button:SetOnClickHandler(fn) self.onClickHandler = fn end
    function button:SetOnEnterHandler(fn) self.onEnterHandler = fn end
    function button:SetDisabledTooltip(tip) self.disabledTooltip = tip end
    function button:SetEnabledState(on) self:SetEnabled(on) end
    button:SetScript("OnClick", function(self, ...)
        if self:IsEnabled() and self.onClickHandler then self.onClickHandler(self, ...) end
    end)
end
W.templates["UIPanelButtonNoTooltipTemplate, UIButtonTemplate"] = RedButton
W.templates.IconButtonTemplate = function(button)
    button.Icon = W.NewWidget("Texture", nil, button)
    RedButton(button)
end
W.templates.CastingBarFrameTemplate = function(bar)
    bar.Icon = W.NewWidget("Texture", nil, bar)
    bar.showCastbar = true
    function bar:SetUnit(unit) self.unit = unit if not unit then self:Hide() end end
    function bar:SetAndUpdateShowCastbar(on) self.showCastbar = on if not on then self:Hide() end end
    function bar:SetLook(look) self.look = look end
    bar:SetScript("OnEvent", noop)
    bar:Hide()
end
CastingBarType = { ApplyingTalents = "applyingtalents" }
GAME_TOOLTIP_BACKDROP_STYLE_CLASS_TALENT = { style = "class talents" }

W.LoadCore(root)
local Core = SaneUI.Core
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Combat", "SaneUI_Combat")
W.Fire("ADDON_LOADED", "SaneUI_Combat")
W.Fire("PLAYER_LOGIN")
check(SaneUI.Combat == ns and not ns.off, "the module is made and started")
local Talents, Tree = ns.Talents, ns.TalentsTree

-------------------------------------------------------------------------------
--  The part on the board
-------------------------------------------------------------------------------
local spec
for _, each in ipairs(ns.Board.layouts.options.windows()) do if each.key == "talents" then spec = each end end
local edge, head = Core.Board.EDGE, Core.Board.HEAD
check(spec and spec.title == ns.TEXT.talents and spec.least[1] == math.floor(1212 * 0.4) + 2 * edge
    and spec.least[2] == math.floor(701 * 0.4) + head + 2 * edge,
    "the talents registered with the board: its title, as small as 40 % of the game's art with the panel round it")
local first = ns.Board.layouts.options.default()
check(first and first.parts and first.parts[1].key == "talents" and first.shares[1] == 1218,
    "the first layout: the talents at the left, as wide as the game's window's share")

-- A panel of the board's, as Core's board makes it: hidden while it is built.
local function Panel()
    local panel = W.NewWidget("Frame", nil, UIParent)
    panel.body = W.NewWidget("Frame", nil, panel)
    panel.title = W.NewWidget("FontString", nil, panel)
    panel:Hide()
    return panel
end
local function Note(panel)
    for _, widget in ipairs(W.frames) do
        if widget._parent == panel.body and widget._kind == "FontString" then return widget end
    end
end

-- Without the game's shared talent frame: the panel says so, and nothing fails.
local bare = Panel()
spec.build(bare)
check(not ns.off and Talents.frame == nil and Note(bare):IsShown() and Note(bare)._text == Talents.TEXT.missing,
    "without the game's talent frame the panel says so, and nothing breaks")
spec.size(bare, 900, 500)
spec.search(bare, "frost")
check(not ns.off, "sizing and searching it change nothing")

-- With it.
TalentFrameBaseMixin = Base
local panel = Panel()
spec.build(panel)
local frame = Talents.frame
check(frame and frame._parent == Talents.holder and Talents.holder._parent == panel.body and Talents.holder._width == 1212
    and Talents.holder._height == 701 and frame._width == 1212 and frame._height == 681 and frame._points[1][1] == "BOTTOM",
    "built on the game's shared talent frame, at the game's size, at the foot of the game's art")
check(frame.bottomPadding == 40 and frame.maximumCommitTime == 6 and frame.disabledOverlayAlpha == 0.5
    and frame.refreshOnShow and frame._padded[4] == 40 and frame.commitSound == 14 and not frame.ButtonsParent._mouse
    and frame.ButtonsParent:GetScript("OnUpdate") == nil and frame.basePanOffsetX == -11 and frame.basePanOffsetY == -7,
    "the class frame's keys over the template's, its padding, its sound, the trees' place; no zoom or pan running")
check(next(frame._events) == nil, "hidden: no event of the game's is heard, not even the three the template keeps")

-- The art: the stone, the class picture, the frame round it.
check(frame.Background._atlas == "Talents-Background-c60" and frame.Background._height == 701
    and frame.ClassBackground._atlas == "talent-background-mage" and frame.BackgroundBorder._atlas == "Talents-inner-frame-c60"
    and frame.BackgroundFlash._atlas == "talent-background-mage", "the game's stone, your class's picture and the frame round it")

-- Fitted into its panel's body, centred, never larger than the game's.
spec.size(panel, 1300, 900)
check(Talents.holder._scale == 1 and Talents.holder._points[1][1] == "CENTER", "a large panel: the game's size, centred")
spec.size(panel, 700, 500)
check(near(Talents.holder._scale, math.min((700 - 2 * edge) / 1212, (500 - head - 2 * edge) / 701)),
    "a small panel: as large as fits in its body")

-- Shown: the panel comes, the frame's OnShow runs (the stand-in knows no parent's show).
local function Open()
    panel:Show()
    spec.show(panel, true)
    frame._shown = false
    frame:Show()
end
local function Close()
    frame:Hide()
    panel:Hide()
    spec.show(panel, false)
end
Open()
local buttons = frame.buttons
check(buttons[1] and buttons[5] and not buttons[6] and frame.loads >= 1, "shown: the tree loaded, every node but a hero talent's")
check(frame._events.TRAIT_NODE_CHANGED and frame._events.TRAIT_CONFIG_UPDATED and frame._events.PLAYER_REGEN_DISABLED
    and frame._events.UNIT_AURA and frame._units.UNIT_AURA[1] == "player", "shown: the game's events heard, the player's")

-------------------------------------------------------------------------------
--  The trees' heads and the unspent points
-------------------------------------------------------------------------------
local heads = ns.TalentsHeaders.Heads(frame)
check(#heads == 3 and heads[1].name._text == "Arcane" and heads[3].name._text == "Frost" and heads[2].icon._texture == 102,
    "a head over each tree: its name and icon")
check(heads[1].spent._text == 2 and heads[2].spent._text == 1 and heads[3].spent._text == 0, "each with the points spent in it")
check(heads[1]._points[1][2] == frame.BackgroundBorder and heads[1]._points[1][4] == 140 and heads[2]._points[1][4] == 540
    and heads[3]._points[1][5] == -100 and heads[1]._level == 1010, "placed as the game's: 140, then every 400, 100 down")
local purse = ns.TalentsHeaders.Unspent(frame)
check(purse.amount._text == 4 and purse.amount._color[2] == 1 and purse.label._text == Talents.TEXT.unspent,
    "the unspent points, green while there are any")

-------------------------------------------------------------------------------
--  The nodes
-------------------------------------------------------------------------------
check(buttons[1].template == "TalentButtonSquareTemplate" and buttons[2].template == "TalentButtonCircleTemplate"
    and buttons[5].template == "TalentButtonChoiceTemplate", "each node in the game's template for its kind")
check(buttons[1].tooltipBackdropStyle == GAME_TOOLTIP_BACKDROP_STYLE_CLASS_TALENT and buttons[1].selectSound == 11
    and buttons[1].deselectSound == 13 and buttons[5].selectSound == 12, "the class talents' tooltip and sounds")
check(buttons[1]._at[1] == 1000 / 10 + 11 and buttons[1]._at[2] == -1500 / 10 - 7 and buttons[1]._level == 500
    and buttons[2]._level == 490, "placed as the game's, lower rows layered over higher ones")
local onClick = buttons[2]:GetScript("OnClick")
check(onClick and onClick ~= Button.OnClick and buttons[2]:GetScript("OnLeave") ~= TalentDisplayMixin.OnLeave,
    "the game's scripts on a node stand behind our guard")
local function Glowing(button)
    for _, widget in ipairs(W.frames) do
        if widget._parent == button and widget._atlas == button.artSet.glow and widget._blend == "ADD" then
            return widget:IsShown() and widget._groups[1].playing, widget
        end
    end
end
local glowing, glow = Glowing(buttons[2])
check(glowing and glow._width == 61 and buttons[2].visualState == State.Selectable,
    "the class's green glow pulses on a node you can buy")
check(not Glowing(buttons[4]) and buttons[4].visualState == State.Locked, "none on a node whose way there is not open")

-------------------------------------------------------------------------------
--  Buying, refunding, applying
-------------------------------------------------------------------------------
local foot = ns.TalentsFoot.Parts(frame)
check(not foot.apply:IsEnabled() and foot.reset:IsShown() and not foot.undo:IsShown() and foot.reset:IsEnabled(),
    "nothing staged: Apply off, Reset there and enabled (ranks were bought), no Undo")
calls = {}
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
check(calls[1][1] == "PurchaseRank" and calls[1][2] == 101 and calls[1][3] == 2 and played[#played] == 11,
    "a left click buys a rank, through the game, with the game's sound")
check(foot.apply:IsEnabled() and foot.apply.YellowGlow:IsShown() and foot.undo:IsShown() and not foot.reset:IsShown(),
    "a change staged: Apply on and glowing yellow, Undo in place of Reset")
W.Fire("TRAIT_TREE_CURRENCY_INFO_UPDATED", TREE)
check(purse.amount._text == 3 and heads[1].spent._text == 3, "the points anew as the game tells them")
shift = true
buttons[1]:GetScript("OnClick")(buttons[1], "RightButton")
shift = false
check(calls[2][1] == "RefundRank" and calls[2][3] == 1 and calls[2][4] == true and played[#played] == 13,
    "a right click refunds, with shift the nodes that hang on it too")

-- Apply: the commit, a cast of the game's shown over the trees on our own cast bar.
calls = {}
foot.apply:GetScript("OnClick")(foot.apply, "LeftButton")
local bar = ns.TalentsCommit.Bar(frame)
check(calls[1][1] == "CommitConfig" and calls[1][2] == nil and frame:IsCommitInProgress() and played[#played] == 14,
    "Apply Changes commits them into the active config, with the game's sound")
check(frame.DisabledOverlay:IsShown() and bar.unit == "player" and bar.showCastbar and bar.look == "OVERLAY"
    and bar:GetEffectiveType() == "applyingtalents" and not bar.Icon:IsShown() and bar._parent == frame.DisabledOverlay,
    "the trees greyed, our cast bar following your cast in the game's look for it")
check(not frame.CommitSpinner:IsShown(), "no spinner at once")
W.Wait(0.5)
check(frame.CommitSpinner:IsShown(), "no cast shown in half a second: the game's spinner")
bar:Show()
check(not frame.CommitSpinner:IsShown(), "the cast shows: the spinner goes")
foot.apply:GetScript("OnClick")(foot.apply, "LeftButton")
check(#calls == 1, "nothing applied twice while it runs")
W.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 384255)
check(not frame.DisabledOverlay:IsShown() and bar.unit == nil and not bar:IsShown(), "the cast done: the grey and the bar go")
W.Fire("TRAIT_CONFIG_UPDATED", 101)
check(not frame:IsCommitInProgress() and frame.endFlash and not foot.undo:IsShown(), "the game says the config changed: applied")
W.Wait(1.2)
check(played[#played] == 15, "a moment later the game's sound of ranks bought")
buttons = frame.buttons -- the config anew: the tree's nodes made anew
check(buttons[2].nodeInfo.ranksPurchased == 1 and buttons[1].nodeInfo.ranksPurchased == 1 and purse.amount._text == 4,
    "the bought and the refunded rank on their nodes, the points as they are")

-- Undo, and the reset menu.
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
calls = {}
foot.undo:GetScript("OnClick")(foot.undo)
check(calls[1][1] == "RollbackConfig" and calls[1][2] == 101 and not foot.undo:IsShown() and foot.reset:IsShown(),
    "Undo throws the staged changes away")
local items = foot.reset._items
check(items[1].title == Talents.TEXT.resetTitle and items[2].text == Talents.TEXT.resetClass and items[4].text == Talents.TEXT.resetAll,
    "the reset menu as the game's")
calls = {}
items[2].fn()
check(calls[1][1] == "ResetTreeByCurrency" and calls[1][3] == TREE and calls[1][4] == CURRENCY, "reset by the class's currency")
items[3].fn()
check(#calls == 1, "this tree has no second currency: reset the specialization's does nothing")
foot.undo:GetScript("OnClick")(foot.undo)

-------------------------------------------------------------------------------
--  A fight
-------------------------------------------------------------------------------
W.Fire("PLAYER_REGEN_DISABLED")
check(frame:IsLocked() and buttons[2].visualState == State.Locked and not Glowing(buttons[2]),
    "a fight begins: the nodes locked at once, no glow")
calls = {}
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
check(#calls == 0, "a click in a fight changes nothing")
W.combat = true
W.Fire("PLAYER_REGEN_ENABLED")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(not frame:IsLocked() and buttons[2].visualState == State.Selectable, "the fight over: they take changes again")
W.Fire("UNIT_AURA", "player")
W.Wait(0)
check(not ns.off, "auras looked at once a frame")

-------------------------------------------------------------------------------
--  The primary and the secondary specialization
-------------------------------------------------------------------------------
local specs = ns.TalentsSpecs.Parts(frame)
local tabs = specs.tabs
local primary, secondary = tabs:GetTabButton(specs.primary), tabs:GetTabButton(specs.secondary)
check(tabs.tabPool.template == "TabSystemTopButtonTemplate" and tabs._level == 1010 and tabs._points[1][4] == 70,
    "the game's top tabs over the trees' top left")
check(primary.Text._text == Talents.TEXT.primary .. " |A:Talents-Checkmark-c60|a" and secondary.Text._text == Talents.TEXT.secondary
    and specs.label:IsShown() and not specs.button:IsShown() and specs.active:IsShown(),
    "Primary marked active, Secondary to look at; the active one says so")
secondary:GetScript("OnClick")(secondary)
check(frame:GetConfigID() == 102 and frame:GetTab() == specs.secondary and frame:IsLocked() and specs.button:IsShown()
    and not specs.label:IsShown(), "the secondary's talents, to look at only, with Activate")
calls = {}
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
check(#calls == 0, "no change to the specialization that is not active")
specs.button:GetScript("OnClick")(specs.button, "LeftButton")
check(calls[1][1] == "SetActiveSpecGroup" and calls[1][2] == 2 and frame.DisabledOverlay:IsShown() and bar.unit == "player",
    "Activate switches to it, a cast of the game's shown over the greyed trees")
activeGroup = 2
W.Fire("ACTIVE_COMBAT_CONFIG_CHANGED", 102)
W.Fire("PLAYER_TALENT_UPDATE")
check(not frame.DisabledOverlay:IsShown() and bar.unit == nil and frame:IsActiveTabSelected() and not frame:IsLocked()
    and secondary.Text._text:find("Checkmark") and not primary.Text._text:find("Checkmark"),
    "switched: the secondary is the active one, its talents take changes")
groups2, activeGroup = 1, 1
W.Fire("PLAYER_TALENT_UPDATE")
check(secondary.forceDisabled and secondary.errorReason == Talents.TEXT.locked and secondary.Text._text:find("lock")
    and not specs.active:IsShown(), "without a second specialization: its tab locked with the game's reason, no Activate")
groups2, activeGroup = 2, 1
W.Fire("PLAYER_TALENT_UPDATE")

-------------------------------------------------------------------------------
--  The search, events only while shown, a low level
-------------------------------------------------------------------------------
buttons = frame.buttons
spec.search(panel, "3")
check(buttons[3].matchType == 3 and buttons[1].matchType == nil, "the full window's search marks the talents it names")
spec.search(panel, "")
check(buttons[3].matchType == nil, "and nothing once it is empty")

Close()
check(next(frame._events) == nil, "hidden: none of the game's events heard")
check(not frame.DisabledOverlay:IsShown(), "and nothing of a switch left over")
Open()
check(frame:GetTab() == specs.primary and frame:GetConfigID() == 101, "opened again: the active specialization")

earned = false
spec.show(panel, true)
check(not frame:IsShown() and Note(panel):IsShown() and Note(panel)._text == Talents.TEXT.later:format(10),
    "before your first talent point: from which level, as the game says it")
earned = true
W.Fire("PLAYER_LEVEL_UP", 10)
check(frame:IsShown() and not Note(panel):IsShown(), "a level later the trees are there")

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
local kept = {}
for _, entry in ipairs(Core.log) do kept[#kept + 1] = tostring(entry.label) .. ": " .. tostring(entry.text) end
check(#kept == 0, "no problem on the way: " .. table.concat(kept, "\n"))
buttons = frame.buttons
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
foot.apply:GetScript("OnClick")(foot.apply, "LeftButton")
check(bar.unit == "player", "a commit under way")
ns.StandDown("a test")
check(ns.off and bar.unit == nil and next(frame._events) == nil and frame:GetScript("OnUpdate") == nil,
    "standing down: the bar stopped, no event heard any more")
calls = {}
buttons[2]:GetScript("OnClick")(buttons[2], "LeftButton")
check(#calls == 0, "and its nodes do nothing")

io.write(("Talents: all %d checks passed.\n"):format(passed))
