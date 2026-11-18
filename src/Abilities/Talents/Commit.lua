local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Abilities - Talents - Commit
--  The cast that applies your changes, or switches your specialization, as the
--  game's class talents frame shows it over the trees (the shared
--  ClassTalents/Blizzard_ClassTalentsFrame.lua: SetCommitVisualsActive,
--  SetCommitCompleteVisualsActive, SetCommitCastBarActive; Camelot's:
--  SetSpecSwitchCastBarActive, its DisabledOverlay over the class picture;
--  Blizzard_SharedTalentFrame.lua's commit visuals):
--    - the trees greyed (the shared frame's DisabledOverlay) and over them the
--      game's cast bar with your cast, in the look the game gives it there
--      (CastingBarType.ApplyingTalents, the OVERLAY look, no icon)
--    - if no cast shows within half a second, the game's spinner turns there
--      instead (the shared frame's CommitSpinner)
--    - once applied, the class's light flashes (Art.lua) with the game's flash
--      over the trees, and a moment later the game's sound if ranks were bought
--  The game moves its own overlay cast bar (OverlayPlayerCastingBarFrame) into
--  its window and hides your cast bar meanwhile. Ours is a cast bar of our
--  own, made from the game's template (CastingBarFrameTemplate) and run by the
--  game's own code with your casts while a commit or a switch is under way,
--  and never else: no casting bar of the game's is touched, and your own shows
--  the cast as it shows any other.
-------------------------------------------------------------------------------
local Talents = ns.Talents
local Class = Talents.Class
local Commit = {}
ns.TalentsCommit = Commit

Commit.LEVEL = 10   -- the bar over the grey, as the game puts its bar over its parent
Commit.DELAY = 0.5  -- the spinner only if no cast showed by then (CommitSpinnerWithBarDelay)
Commit.SOUND = 1.2  -- the sound of ranks bought, that long after the flash (PurchaseFXDelay)

local bars = {}  -- [frame] = its cast bar
local turns = {} -- [frame] = the commit the spinner waits for (a count: an older wait finds it changed)

function Commit.Build(frame)
    local overlay = frame.DisabledOverlay
    if not overlay then return end
    -- Over the class's picture, as this client puts it (Camelot's InitializeOther).
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", frame.ClassBackground, "TOPLEFT")
    overlay:SetPoint("BOTTOMRIGHT", frame.ClassBackground, "BOTTOMRIGHT")
    Talents.Wrap(frame.CommitSpinner)
    local made, bar = pcall(CreateFrame, "StatusBar", nil, overlay, "CastingBarFrameTemplate")
    if not (made and type(bar) == "table" and bar.SetUnit and bar.SetAndUpdateShowCastbar) then return end
    bar:SetFrameLevel(overlay:GetFrameLevel() + Commit.LEVEL)
    bar:SetPoint("CENTER", overlay, "CENTER")
    local kinds = rawget(_G, "CastingBarType")
    local kind = type(kinds) == "table" and kinds.ApplyingTalents or nil
    bar.GetEffectiveType = ns.Guard(function() return kind end)
    if bar.SetLook then bar:SetLook("OVERLAY") end
    if bar.Icon then bar.Icon:Hide() end
    bar:SetAndUpdateShowCastbar(false)
    Talents.Wrap(bar)
    bar:HookScript("OnShow", ns.Guard(function()
        if frame.CommitSpinner then frame.CommitSpinner:Hide() end
    end))
    bars[frame] = bar
end

-- The bar follows your casts while a commit or a switch is under way, and nothing at all else.
function Commit.Run(frame, on)
    local bar = bars[frame]
    if not bar then return end
    if on then
        bar:SetUnit("player", true, false)
        bar:SetAndUpdateShowCastbar(true)
    else
        bar:SetAndUpdateShowCastbar(false)
        bar:SetUnit(nil)
    end
end

function Commit.Bar(frame)
    return bars[frame]
end

-------------------------------------------------------------------------------
--  The frame's methods: the shared frame's commit visuals with our bar in place of the game's overlay bar
-------------------------------------------------------------------------------
function Class:IsCommitCastBarActive()
    local bar = bars[self]
    return bar ~= nil and bar:IsShown()
end

function Class:SetCommitCastBarActive(active)
    Commit.Run(self, active)
end

function Class:SetCommitSpinnerShown(shown)
    local spinner = self.CommitSpinner
    if not spinner then return end
    spinner:SetShown(shown and not self:IsCommitCastBarActive() and self:IsVisible())
end

function Class:SetCommitVisualsActive(active, _, skipSpinnerDelay)
    if active and not self:IsVisible() then return end
    if self.areBaseCommitVisualsActive == active then return end
    self.areBaseCommitVisualsActive = active
    self:SetDisabledOverlayShown(active)
    self:SetCommitCastBarActive(active)
    turns[self] = (turns[self] or 0) + 1
    if not (active and not self:IsCommitCastBarActive()) then return self:SetCommitSpinnerShown(false) end
    if skipSpinnerDelay then return self:SetCommitSpinnerShown(true) end
    local turn = turns[self]
    C_Timer.After(Commit.DELAY, ns.Guard(function()
        if turns[self] == turn and self.areBaseCommitVisualsActive then self:SetCommitSpinnerShown(true) end
    end))
end

-- Applied: the game's flash over the trees, the class's light, and the sound of ranks bought.
function Class:SetCommitCompleteVisualsActive(active)
    local base = rawget(_G, "TalentFrameBaseMixin")
    if base and base.SetCommitCompleteVisualsActive then base.SetCommitCompleteVisualsActive(self, active) end
    if (active and not self:IsVisible()) or self.flashing == active then return end
    self.flashing = active
    ns.TalentsArt.Flash(self, active)
    if not active then
        self.bought = nil
        return
    end
    local bought = self.bought
    self.bought = nil
    C_Timer.After(Commit.SOUND, ns.Guard(function()
        self.flashing = false
        local sounds = rawget(_G, "SOUNDKIT") or {}
        if bought and sounds.UI_CLASS_TALENT_APPLY_COMPLETE then PlaySound(sounds.UI_CLASS_TALENT_APPLY_COMPLETE) end
    end))
end
