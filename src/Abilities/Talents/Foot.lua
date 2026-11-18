local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Abilities - Talents - Foot
--  At the foot of our talent trees what the game's class talents frame has
--  there (Camelot: ClassTalents/Blizzard_ClassTalentsFrame.xml: ApplyButton,
--  ResetButton, UndoButton; their states as the shared Blizzard_Class-
--  TalentsFrame.lua sets them, UpdateConfigButtonsState, and this client's
--  glow, Blizzard_SharedTalentOverrides.lua):
--    - Apply Changes, the game's red button in the middle of the foot: enabled
--      while changes wait and the game says they can be applied (else its
--      reason under the mouse), its yellow glow while they can
--    - right of it, the game's Undo while changes wait, else its Reset button
--      with the game's menu: reset the class's talents, the specialization's,
--      or all; enabled while there is anything to reset and nothing is being
--      applied
-------------------------------------------------------------------------------
local Talents = ns.Talents
local Class = Talents.Class
local Foot = {}
ns.TalentsFoot = Foot

-- The game's sizes and places (ClassTalentsFrameTemplate): Apply over the stone's foot, the round buttons beside it.
Foot.APPLY = { 164, 22 }
Foot.APPLY_AT = 8
Foot.ROUND = 25
Foot.RESET_AT = 14

local parts = {} -- [frame] = { apply, reset, undo }

-- An icon button of the game's with its atlas, lit by the same atlas under the mouse (IconButtonMixin:OnLoad with
-- iconAtlas, useAtlasSize and useIconAsHighlight, which the game's XML sets before that runs).
local function Icon(button, atlas)
    if not button.Icon then return end
    button.Icon:SetAtlas(atlas, true)
    button:SetHighlightAtlas(atlas, "ADD")
    local light = button:GetHighlightTexture()
    if light then
        light:ClearAllPoints()
        light:SetPoint("TOPLEFT", button.Icon, "TOPLEFT")
        light:SetPoint("BOTTOMRIGHT", button.Icon, "BOTTOMRIGHT")
    end
end

function Foot.Build(frame)
    local apply = Talents.Button(frame, Talents.TEXT.apply, Foot.APPLY[1], Foot.APPLY[2],
        ns.Guard(function() frame:ApplyConfig() end))
    apply:SetPoint("BOTTOM", frame.Background, "BOTTOM", 0, Foot.APPLY_AT)
    apply.YellowGlow = Talents.YellowGlow(apply)
    if apply.SetOnEnterHandler then apply:SetOnEnterHandler(ns.Guard(function() frame:UpdateConfigButtonsState() end)) end

    local made, reset = pcall(CreateFrame, "DropdownButton", nil, frame, "IconButtonTemplate")
    if not (made and type(reset) == "table") then reset = CreateFrame("Button", nil, frame, "IconButtonTemplate") end
    reset:SetSize(Foot.ROUND, Foot.ROUND)
    reset:SetPoint("LEFT", apply, "RIGHT", Foot.RESET_AT, 0)
    Icon(reset, "talents-button-reset")
    reset.menuPoint, reset.menuRelativePoint, reset.menuPointX, reset.menuPointY = "BOTTOMLEFT", "TOPRIGHT", 0, 0
    local ResetClass = ns.Guard(function() frame:ResetClassTalents() end)
    local ResetSpec = ns.Guard(function() frame:ResetSpecTalents() end)
    local ResetAll = ns.Guard(function() frame:ResetTree() end)
    if reset.SetupMenu then
        reset:SetupMenu(ns.Guard(function(_, root)
            root:CreateTitle(Talents.TEXT.resetTitle)
            root:CreateButton(Talents.TEXT.resetClass, ResetClass)
            root:CreateButton(Talents.TEXT.resetSpec, ResetSpec)
            root:CreateButton(Talents.TEXT.resetAll, ResetAll)
        end))
    end
    Talents.Wrap(reset)

    local undo = CreateFrame("Button", nil, frame, "IconButtonTemplate")
    undo:SetSize(Foot.ROUND, Foot.ROUND)
    undo:SetPoint("CENTER", reset, "CENTER")
    Icon(undo, "talents-button-undo")
    undo.tooltipText = Talents.TEXT.undo
    undo.tooltipTextColor = rawget(_G, "HIGHLIGHT_FONT_COLOR")
    if undo.SetOnClickHandler then undo:SetOnClickHandler(ns.Guard(function() frame:RollbackConfig() end)) end
    Talents.Wrap(undo)
    parts[frame] = { apply = apply, reset = reset, undo = undo }
end

function Foot.Parts(frame)
    return parts[frame]
end

-------------------------------------------------------------------------------
--  The frame's methods
-------------------------------------------------------------------------------
-- The foot as the changes stand (ClassTalentsFrameMixin:UpdateConfigButtonsState); Activate with it.
function Class:UpdateConfigButtonsState()
    local part = parts[self]
    if not part then return end
    local pending, canApply, reason = self:GetConfigApplicationState()
    part.apply:SetEnabled(canApply == true)
    if part.apply.SetDisabledTooltip then part.apply:SetDisabledTooltip(reason) end
    if pending then
        self:ShowOrHideGlowOnChangesPending()
    else
        part.apply.YellowGlow:Hide()
    end
    local undoing = self:HasAnyConfigChanges() and not self.isConfigReadyToApply
    part.undo:SetShown(undoing)
    local cannotRefund = self.talentTreeInfo and self.talentTreeInfo.cannotRefund
    part.reset:SetShown(not undoing and not cannotRefund)
    local resettable = self:HasValidConfig() and self:HasAnyPurchasedRanks() and not self:IsCommitInProgress()
    if part.reset.SetEnabledState then part.reset:SetEnabledState(resettable) else part.reset:SetEnabled(resettable) end
    ns.TalentsSpecs.Refresh(self)
end

-- This client's glow on Apply: yellow while the changes can be applied (Blizzard_SharedTalentOverrides.lua).
function Class:ShowOrHideGlowOnChangesPending()
    local part = parts[self]
    if not part then return end
    local _, canApply = self:GetConfigApplicationState()
    part.apply.YellowGlow:SetShown(canApply == true)
end
