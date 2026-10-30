local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Asks
--  Equip and delete without asking (Saneroki, 2026-10-30; on at first, in every
--  profile): the game's questions before gear binds to you or ends a refund, and
--  before an item is destroyed, answered as its own Yes would. Destroying is held
--  back by the game for a click of the player's: where it refuses, its question
--  stands as ever with the word it wants typed in, and the next item is tried
--  again.
--
--      Asks.Start()   listens for the game's questions, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Asks = {}
ns.Asks = Asks

Asks.CHECK = 0.3 -- seconds after an item was destroyed before the cursor shows whether the game let it

local QUESTIONS = { EQUIP_BIND = true, EQUIP_BIND_TRADEABLE = true, EQUIP_BIND_REFUNDABLE = true, DELETE_ITEM = true,
                    DELETE_QUEST_ITEM = true, DELETE_GOOD_ITEM = true, DELETE_GOOD_QUEST_ITEM = true }

local deleting -- the question an item was just destroyed for

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
        TypeWord(dialog)
    end)
end, Asks.CHECK)

-- A question of the game's has come up: answered as its own Yes would.
local function Answer(which)
    if not QUESTIONS[which] or ns.off or not ns.options.noAsk then return end
    local dialogs, find = rawget(_G, "StaticPopupDialogs"), rawget(_G, "StaticPopup_FindVisible")
    local info = type(dialogs) == "table" and dialogs[which]
    local dialog = info and find and Core.Ask(find, which)
    if not dialog or type(info.OnAccept) ~= "function" then return end
    if not which:find("^DELETE") then
        Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
        return Core.Ask(rawget(_G, "StaticPopup_Hide"), which)
    end
    -- The game's question hides itself once the item is off the cursor.
    deleting = which
    Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
    CheckDeleted()
end

function Asks.Start()
    if rawget(_G, "StaticPopup_Show") then hooksecurefunc("StaticPopup_Show", ns.Guard(Answer)) end
end
