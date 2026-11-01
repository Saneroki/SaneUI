local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Combat - Reminders - Clicks
--  A right click on one of the game's own buffs and debuffs at the top of the
--  screen opens a menu with Create reminder. The game's button cancels a buff
--  on a right click, in its own secure code that addons cannot stop or do
--  themselves (CancelAuraByInstanceID is closed to them). So a frame of ours
--  lies over each button and takes the clicks alone, the mouse's coming stays
--  the button's (its tooltip), and it lets the click through, to the game,
--  whenever a menu cannot serve: with Shift held (so Shift + right click
--  cancels), in a fight (the game hides auras: a right click cancels as ever),
--  in Edit Mode, and on a weapon enchant, which is no aura.
--
--  The menu's line for an aura is Clicks.Entry, for the unit frames' icons too.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Clicks = {}
ns.ReminderClicks = Clicks

local shields = {} -- [the game's aura button] = our frame over it

-- The aura a button of the game's shows, out of a fight: { id, name, icon, harmful, unit }.
local function Which(button)
    local info = button.buttonInfo
    if type(info) ~= "table" or Core.Restricted() then return nil end
    local harmful = Plain(button.auraType) ~= "Buff"
    local auras = C_UnitAuras
    local data = Core.Ask(auras.GetAuraDataByAuraInstanceID, "player", Plain(info.auraInstanceID))
        or Core.Ask(auras.GetAuraDataByIndex, "player", Plain(info.index), harmful and "HARMFUL" or "HELPFUL")
    local id, name = type(data) == "table" and Plain(data.spellId), type(data) == "table" and Plain(data.name)
    if not (id and name) then return nil end
    return { id = id, name = name, icon = Plain(data.icon), harmful = harmful, unit = "player" }
end

-- A menu's line for an aura ({ id, name, icon, harmful, unit }): make its reminder, or open the one it has.
function Clicks.Entry(root, spell)
    if ns.options.reminders == false then return end
    local word = ns.Reminders.Find(spell) and ns.TEXT.reminderEdit or ns.TEXT.reminderCreate
    root:CreateButton(word, ns.Guard(function() ns.ReminderEditor.Open(ns.Reminders.Make(spell)) end))
end

local function Clicked(shield, mouse)
    if mouse ~= "RightButton" then return end
    local spell = Which(shield:GetParent())
    if not spell then return end
    MenuUtil.CreateContextMenu(shield, ns.Guard(function(_, root)
        root:CreateTitle(spell.name)
        Clicks.Entry(root, spell)
        if not spell.harmful then root:CreateTitle(ns.TEXT.reminderCancel) end
    end))
end
local OnClicked = ns.Guard(Clicked)

-- Which shields take the click now.
function Clicks.Sync()
    local open = not ns.off and ns.options.reminders ~= false and not Core.Restricted() and not Core.EditMode.active
        and not IsShiftKeyDown()
    for button, shield in pairs(shields) do
        local kind = Plain(button.auraType)
        shield:SetMouseClickEnabled(open and (kind == "Buff" or kind == "Debuff" or kind == "DeadlyDebuff") or false)
    end
end
local Sync = ns.Guard(Clicks.Sync)

local function Cover(frame)
    if type(frame) ~= "table" or type(frame.auraFrames) ~= "table" then return end
    for _, button in ipairs(frame.auraFrames) do
        if not button.isAuraAnchor then
            local shield = CreateFrame("Frame", nil, button)
            shield:SetAllPoints(button)
            shield:SetScript("OnMouseUp", OnClicked)
            shield:SetMouseMotionEnabled(false)
            shield:SetMouseClickEnabled(false)
            shields[button] = shield
        end
    end
    hooksecurefunc(frame, "UpdateAuraButtons", Sync)
end

function Clicks.Start()
    Cover(rawget(_G, "BuffFrame"))
    Cover(rawget(_G, "DebuffFrame"))
    for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "MODIFIER_STATE_CHANGED",
                             "ADDON_RESTRICTION_STATE_CHANGED" }) do
        Core.On(event, Clicks.Sync)
    end
end
