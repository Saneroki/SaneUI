local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Spirit
--  Resurrecting at the spirit healer without being asked (Saneroki,
--  2026-11-11: a "Don't ask me again" on the second window, counting for
--  both). The game asks in one window of two steps (its XP_LOSS: what
--  resurrecting here costs, then whether you are sure of the Resurrection
--  Sickness), below the level of the sickness in one step
--  (XP_LOSS_NO_SICKNESS_NO_DURABILITY). Under its last step stands a tick of
--  ours, the game's own checkbox: Don't ask me again. Accepted with it ticked,
--  the setting Ask at the spirit healer goes off; from then on, the moment the
--  game shows its window, it is answered as its last step would be (the
--  spirit healer confirmed, the interaction cleared: the window's own calls)
--  and hidden, so choosing the resurrection resurrects you at once. The setting
--  on Lore's page brings the questions back. Nothing of the game's window is
--  changed: the tick is a frame of ours under it, the window's functions are
--  only followed (hooksecurefunc).
--
--      Spirit.Start()   the game's windows followed
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Spirit = {}
ns.Spirit = Spirit

Spirit.TWO_STEPS = "XP_LOSS"                            -- its first step's accept keeps it open for the second
Spirit.ONE_STEP = "XP_LOSS_NO_SICKNESS_NO_DURABILITY"   -- below the sickness's level
Spirit.TICK = 26 -- the checkbox, wide

local tick   -- the checkbox under the window's last step, made when first needed
local owner  -- the window it stands under

local function Ask(name, ...)
    return Core.Ask(rawget(_G, name), ...)
end

-- The window's own answer on its last step: the spirit healer confirmed, the interaction cleared; then hidden.
local function Resurrect()
    local manager = rawget(_G, "C_PlayerInteractionManager")
    local kinds = Enum and Enum.PlayerInteractionType
    local kind = kinds and kinds.SpiritHealer
    if type(manager) ~= "table" or not kind then return end
    manager.ConfirmationInteraction(kind)
    manager.ClearInteraction(kind)
    Ask("StaticPopup_Hide", Spirit.TWO_STEPS)
    Ask("StaticPopup_Hide", Spirit.ONE_STEP)
end

local function Gone()
    if not tick then return end
    tick:SetChecked(false)
    tick:Hide()
    owner = nil
end

-- With its window: gone the moment that window shows something else or nothing.
local function Watch()
    if not owner or not owner:IsShown() or (owner.which ~= Spirit.TWO_STEPS and owner.which ~= Spirit.ONE_STEP) then
        Gone()
    end
end

local function Tick()
    if tick then return tick end
    tick = CreateFrame("CheckButton", nil, UIParent, "UICheckButtonTemplate")
    tick:SetSize(Spirit.TICK, Spirit.TICK)
    tick:SetFrameStrata("DIALOG")
    -- In sight while the talk fades the interface out (Quiet.lua), as the game's windows are.
    if tick.SetIgnoreParentAlpha then tick:SetIgnoreParentAlpha(true) end
    local label = tick.Text -- the template's own label, right of the box
    if not label then
        label = tick:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", tick, "RIGHT", 2, 0)
    end
    label:SetFontObject("GameFontHighlight")
    label:SetText(ns.TEXT.dontAsk)
    tick.label = label
    tick:SetScript("OnUpdate", ns.Guard(Watch))
    tick:Hide()
    return tick
end

-- Under the window's last step, its middle under the window's.
local function Show(dialog)
    if type(dialog) ~= "table" or not dialog.IsShown then return end
    Tick()
    owner = dialog
    tick:SetChecked(false)
    tick:ClearAllPoints()
    local wide = Spirit.TICK + (Core.Plain(tick.label:GetStringWidth()) or 0)
    tick:SetPoint("TOPLEFT", dialog, "BOTTOM", -wide / 2, -2)
    tick:SetFrameLevel((Core.Plain(dialog:GetFrameLevel()) or 0) + 5)
    tick:Show()
end

-- The last step accepted: with the tick ticked, never asked again.
local function Accepted()
    if tick and tick:IsShown() and tick:GetChecked() then Core.Set(ns.name, "spiritAsk", false) end
    Gone()
end

local function Shown(which)
    if which ~= Spirit.TWO_STEPS and which ~= Spirit.ONE_STEP then return end
    if ns.off then return end
    if ns.options.spiritAsk == false then return Resurrect() end
    if which == Spirit.ONE_STEP then
        local _, dialog = Ask("StaticPopup_Visible", which)
        Show(dialog)
    end
end

function Spirit.Start()
    if type(rawget(_G, "StaticPopup_Show")) == "function" then hooksecurefunc("StaticPopup_Show", ns.Guard(Shown)) end
    local dialogs = rawget(_G, "StaticPopupDialogs")
    local two = type(dialogs) == "table" and dialogs[Spirit.TWO_STEPS]
    if type(two) == "table" and type(two.OnAccept) == "function" then
        -- Its first step's accept turns it to the second (with its data); the second's resurrects.
        hooksecurefunc(two, "OnAccept", ns.Guard(function(dialog, data)
            if ns.off then return end
            if data ~= nil then Show(dialog) else Accepted() end
        end))
    end
    local one = type(dialogs) == "table" and dialogs[Spirit.ONE_STEP]
    if type(one) == "table" and type(one.OnAccept) == "function" then
        hooksecurefunc(one, "OnAccept", ns.Guard(function() if not ns.off then Accepted() end end))
    end
end

-- Standing down: the tick out of sight (the hooks only follow and do nothing while the module stands down).
function Spirit.GiveBack()
    Gone()
end
