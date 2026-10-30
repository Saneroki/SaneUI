local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Errands
--  What would hold you up on the way, done for you (Saneroki, 2026-10-30), each
--  with a switch of its own, on at first:
--    Take all loot    the module Loot set to take everything at once (its
--                     switches Everything on, Always show upgrades off, which
--                     would keep an upgrade waiting in its window). Set once:
--                     what you change on Loot's page after that stays, and this
--                     switch off puts back what you did not change. The game's
--                     question on a thing that binds when picked up is answered.
--    Equip and delete without asking
--                     the game's questions before gear binds to you or ends a
--                     refund, and before an item is destroyed, answered as its
--                     own Yes would. Destroying is held back by the game for a
--                     click of the player's: where it refuses, its question
--                     comes up as ever with the word it wants typed in, and is
--                     not tried again (options.deleteRefused).
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Errands = {}
ns.Errands = Errands

Errands.CHECK = 0.3   -- seconds after an item was destroyed before the cursor shows whether the game let it

local LOOT = "Loot"   -- the module whose switches Take all loot sets
local LENT = { takeAll = true, showUpgrades = false }
-- The game's questions, each with the switch that answers it.
local ASKS = {
    LOOT_BIND = "lootAll",
    EQUIP_BIND = "noAsk", EQUIP_BIND_TRADEABLE = "noAsk", EQUIP_BIND_REFUNDABLE = "noAsk",
    DELETE_ITEM = "noAsk", DELETE_QUEST_ITEM = "noAsk", DELETE_GOOD_ITEM = "noAsk", DELETE_GOOD_QUEST_ITEM = "noAsk",
}

local deleting        -- the question an item was just destroyed for

-------------------------------------------------------------------------------
--  Take all loot
-------------------------------------------------------------------------------
local function Lend()
    local loot, lent = Core.Settings(LOOT), ns.options.lootLent
    if next(lent) or not (loot and Core.Described(LOOT, "takeAll")) then return end
    for key, value in pairs(LENT) do
        lent[key] = { was = loot[key], set = value }
        Core.Set(LOOT, key, value)
    end
end

local function PutBack()
    local loot, lent = Core.Settings(LOOT), ns.options.lootLent
    for key, entry in pairs(lent) do
        if loot and loot[key] == entry.set then Core.Set(LOOT, key, entry.was) end
        lent[key] = nil
    end
end

function Errands.Update()
    if ns.off or not ns.options.lootAll then PutBack() else Lend() end
end

-------------------------------------------------------------------------------
--  The game's questions
-------------------------------------------------------------------------------
-- The word the game wants typed for a good item, typed in; its Yes is then one click.
local function TypeWord(dialog)
    local box = dialog.GetEditBox and Core.Ask(dialog.GetEditBox, dialog) or dialog.editBox
    local word = rawget(_G, "DELETE_ITEM_CONFIRM_STRING")
    if box and box.SetText and word and Core.Ask(box.IsShown, box) then Core.Ask(box.SetText, box, word) end
end

-- A moment after the item was destroyed: gone, or the game refused and the question stands.
local CheckDeleted = Core.Later(function()
    ns.Guarded(function()
        local which = deleting
        deleting = nil
        local find = rawget(_G, "StaticPopup_FindVisible")
        local dialog = which and find and Core.Ask(find, which)
        if not dialog or not Core.Ask(rawget(_G, "CursorHasItem")) then return end
        ns.options.deleteRefused = true
        TypeWord(dialog)
    end)
end, Errands.CHECK)

-- A question of the game's has come up: answered as its own Yes would.
local function Answer(which)
    local switch = ASKS[which]
    if not switch or ns.off or not ns.options[switch] then return end
    local dialogs, find = rawget(_G, "StaticPopupDialogs"), rawget(_G, "StaticPopup_FindVisible")
    local info = type(dialogs) == "table" and dialogs[which]
    local dialog = info and find and Core.Ask(find, which)
    if not dialog or type(info.OnAccept) ~= "function" then return end
    if not which:find("^DELETE") then
        Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
        return Core.Ask(rawget(_G, "StaticPopup_Hide"), which)
    end
    if ns.options.deleteRefused then return TypeWord(dialog) end
    -- The game's question hides itself once the item is off the cursor.
    deleting = which
    Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
    CheckDeleted()
end

function Errands.Start()
    Errands.Update()
    if rawget(_G, "StaticPopup_Show") then hooksecurefunc("StaticPopup_Show", ns.Guard(Answer)) end
end
