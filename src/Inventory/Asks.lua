local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Inventory - Asks
--  Equip and delete without asking (Saneroki, 2026-10-30; on at first, in every
--  profile): the game's questions before gear binds to you or ends a refund, and
--  before an item is destroyed, answered as its own Yes would.
--
--  Destroying is held back by the game for a press of the player's own
--  (DeleteCursorItem has restrictions), and the drop that brings up its
--  question is no such press for an addon: the game refused it there every
--  time. So the question comes up with the word it wants typed in, and the
--  item goes at the player's next key, as Make Room's (Bags/Room.lua) does:
--  out of a fight, any key but Escape, which is the game's No; a click on Yes
--  does it at once. Where the game refuses even that, the question stands, and
--  the next item is tried again.
--
--      Asks.Start()   listens for the game's questions, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Asks = {}
ns.Asks = Asks

Asks.CHECK = 0.3 -- seconds after an item was destroyed before the cursor shows whether the game let it

local QUESTIONS = { EQUIP_BIND = true, EQUIP_BIND_TRADEABLE = true, EQUIP_BIND_REFUNDABLE = true, DELETE_ITEM = true,
                    DELETE_QUEST_ITEM = true, DELETE_GOOD_ITEM = true, DELETE_GOOD_QUEST_ITEM = true }

local waiting  -- the question whose item goes at the next key
local deleting -- the question an item was just destroyed for
local catcher  -- the frame that hears the next key, shown only while a question waits

local function Listen(on)
    if catcher then catcher:SetShown(on and true or false) end
end

-- The game's question of that kind on the screen, with its item still on the cursor: its dialog and its entry.
local function Standing(which)
    local dialogs, find = rawget(_G, "StaticPopupDialogs"), rawget(_G, "StaticPopup_FindVisible")
    local info = type(dialogs) == "table" and dialogs[which]
    local dialog = info and find and Core.Ask(find, which)
    if not dialog or type(info.OnAccept) ~= "function" then return nil end
    return dialog, info
end

-- The word the game wants typed for a good item, typed in; its Yes is then one click.
local function TypeWord(dialog)
    local box = dialog.GetEditBox and Core.Ask(dialog.GetEditBox, dialog) or dialog.editBox
    local word = rawget(_G, "DELETE_ITEM_CONFIRM_STRING")
    if box and box.SetText and word and Core.Ask(box.IsShown, box) then Core.Ask(box.SetText, box, word) end
end

-- A moment after the item was destroyed: gone, or the game refused and the question stands as ever.
local CheckDeleted = Core.Later(function()
    ns.Guarded(function()
        local which = deleting
        deleting = nil
        local dialog = which and Standing(which)
        if not dialog or not Core.Ask(rawget(_G, "CursorHasItem")) then return end
        TypeWord(dialog)
    end)
end, Asks.CHECK)

-- A key was pressed, and the game takes that for the player's word.
local function Pressed(_, key)
    local which = waiting
    waiting = nil
    Listen(false)
    if not which or key == "ESCAPE" or ns.off or not ns.options.noAsk or InCombatLockdown() then return end
    local dialog, info = Standing(which)
    if not dialog or not Core.Ask(rawget(_G, "CursorHasItem")) then return end
    deleting = which
    Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
    CheckDeleted()
end

-- A question of the game's has come up: answered as its own Yes would.
local function Answer(which)
    if not QUESTIONS[which] or ns.off or not ns.options.noAsk then return end
    local dialog, info = Standing(which)
    if not dialog then return end
    if not which:find("^DELETE") then
        Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
        return Core.Ask(rawget(_G, "StaticPopup_Hide"), which)
    end
    -- The game's question hides itself once the item is off the cursor.
    TypeWord(dialog)
    if InCombatLockdown() then return end
    if not catcher then
        -- Made out of a fight: the keyboard is not the addon's to take in one.
        catcher = CreateFrame("Frame", nil, UIParent)
        catcher:EnableKeyboard(true)
        catcher:SetPropagateKeyboardInput(true) -- every key goes on to the game as ever
        catcher:SetScript("OnKeyDown", ns.Guard(Pressed))
        Asks.catcher = catcher
    end
    waiting = which
    Listen(true)
end

function Asks.Start()
    if rawget(_G, "StaticPopup_Show") then hooksecurefunc("StaticPopup_Show", ns.Guard(Answer)) end
end

-- Off (the module stood down): nothing waits for a key.
function Asks.GiveBack()
    waiting = nil
    Listen(false)
end
