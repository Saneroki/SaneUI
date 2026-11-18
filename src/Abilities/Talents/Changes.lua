local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Talents - Changes
--  Buying, refunding, applying, undoing and resetting talents, as the game's
--  class talents frame does them (the shared ClassTalents/Blizzard_Class-
--  TalentsFrame.lua over Blizzard_SharedTalentFrame.lua's TalentFrameBaseMixin;
--  Camelot's Blizzard_ClassTalentsFrame.lua for what this client changes):
--    - a click on a node stages the change in the game (C_Traits.PurchaseRank,
--      RefundRank and SetSelection; with shift, a refund takes the nodes that
--      hang on it too), as the game's shared node buttons ask our frame to
--    - Apply Changes applies them: the game's commit (C_ClassTalents.CommitConfig),
--      a cast the game runs (Commit.lua shows it); Undo throws them away
--      (C_Traits.RollbackConfig); the Reset menu stages a reset of the class's
--      or the specialization's tree, or both (C_Traits.ResetTreeByCurrency),
--      never the whole config at once, as the game's
--    - what may be done is the game's to say: the nodes take changes while the
--      shown specialization is the active one (this client's rule) and no
--      fight is on (the shared frame's rule, which this client's leaves to the
--      server); Apply while C_ClassTalents.CanChangeTalents says so, with its
--      reason when not
--  What the game's frame does about loadouts, the starter build, hero talents
--  and inspecting another player is not here: this client's talents window
--  hides its loadouts, and has no starter build and no hero talents.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talents = ns.Talents
local Class = Talents.Class

local function Base()
    return rawget(_G, "TalentFrameBaseMixin") or {}
end

local function Traits()
    return rawget(_G, "C_Traits") or {}
end

-- With shift held, a refund takes what hangs on the node too (ClassTalentUtil.ShouldRefundClearEdges).
local function ClearEdges()
    return Core.Ask(rawget(_G, "IsShiftKeyDown")) == true
end

-------------------------------------------------------------------------------
--  Staging a change
-------------------------------------------------------------------------------
function Class:AttemptConfigOperation(operation, ...)
    if type(operation) ~= "function" then return false end -- a client without it: nothing staged
    local done = Base().AttemptConfigOperation(self, operation, ...)
    self:UpdateConfigButtonsState()
    return done
end

function Class:RefundRank(nodeID)
    return self:AttemptConfigOperation(Traits().RefundRank, nodeID, ClearEdges())
end

function Class:SetSelection(nodeID, entryID)
    return self:AttemptConfigOperation(Traits().SetSelection, nodeID, entryID, ClearEdges())
end

-- Changes are staged only on the active specialization, and not in a fight (Camelot's IsLocked, and the shared
-- frame's fight).
function Class:IsLocked()
    if Talents.Fight() then return true, Talents.TEXT.fight end
    return not self:IsActiveTabSelected()
end

-------------------------------------------------------------------------------
--  What waits to be applied
-------------------------------------------------------------------------------
function Class:HasValidConfig()
    return self:GetConfigID() ~= nil and self:GetTalentTreeID() ~= nil
end

function Class:HasAnyConfigChanges()
    if self:IsCommitInProgress() then return false end
    return self:HasValidConfig() and Core.Ask(Traits().ConfigHasStagedChanges, self:GetConfigID()) == true
end

function Class:HasAnyRefundInvalidNodes()
    for button in self:EnumerateAllTalentButtons() do
        if button.IsRefundInvalid and button:IsRefundInvalid() then return true end
    end
    return false
end

-- Whether the changes can be applied now, and why not (ClassTalentsFrameMixin:CanChangeTalents).
function Class:CanChangeTalents()
    if self:HasAnyRefundInvalidNodes() then return false, false, Talents.TEXT.refundInvalid end
    if self:IsCommitInProgress() then return false, false end
    local talents = rawget(_G, "C_ClassTalents") or {}
    if not talents.CanChangeTalents then return false, false end
    return Core.Ask(talents.CanChangeTalents)
end

-- Changes waiting, whether they can be applied, and why not.
function Class:GetConfigApplicationState()
    local canChange, canAdd, reason = self:CanChangeTalents()
    local pending = self.isConfigReadyToApply or self:HasAnyConfigChanges()
    local canApply = pending and (canChange or canAdd) or false
    return pending, canApply, pending and not canChange and reason or nil
end

-------------------------------------------------------------------------------
--  Applying, undoing, resetting
-------------------------------------------------------------------------------
function Class:ApplyConfig()
    self.isConfigReadyToApply = false
    if self:HasAnyConfigChanges() then
        self:CommitConfig()
    else
        self:UpdateConfigButtonsState()
    end
end

-- The game's commit, into the active config: this client's window keeps no loadouts to save into.
function Class:CommitConfigInternal()
    local talents = rawget(_G, "C_ClassTalents") or {}
    return talents.CommitConfig and talents.CommitConfig(nil)
end

function Class:CanCommitInstantly()
    return false
end

function Class:GetConfigCommitErrorString()
    return Talents.TEXT.tooFast
end

function Class:RollbackConfig(...)
    Base().RollbackConfig(self, ...)
    self:UpdateTreeCurrencyInfo()
    self:UpdateConfigButtonsState()
end

-- A commit begins or ends: whether ranks were bought, for the sound when it is done (SetCommitStarted).
function Class:SetCommitStarted(configID, reason, skipAnimation)
    if configID then
        local purchases, _, swaps = Core.Ask(Traits().GetStagedChanges, self:GetConfigID())
        self.bought = (type(purchases) == "table" and #purchases > 0) or (type(swaps) == "table" and #swaps > 0)
    end
    Base().SetCommitStarted(self, configID, reason, skipAnimation)
    self:UpdateConfigButtonsState()
end

-- The reset menu: by the tree's currencies, the class's first and the specialization's second.
local function Reset(frame, index)
    local currency = frame.treeCurrencyInfo and frame.treeCurrencyInfo[index]
    local id = currency and currency.traitCurrencyID
    if id == nil then return end
    frame:AttemptConfigOperation(Traits().ResetTreeByCurrency, frame:GetTalentTreeID(), id)
end

function Class:ResetClassTalents()
    Reset(self, 1)
end

function Class:ResetSpecTalents()
    Reset(self, 2)
end

function Class:ResetTree()
    self:ResetClassTalents()
    self:ResetSpecTalents()
end
