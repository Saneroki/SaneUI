local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Loot - Game
--  The game's own parts this module stands in for, kept out of the way while
--  ours are chosen, and given back (Doc/guides/windows.md, Taint and the game's
--  own windows: nothing of Blizzard's is written, no function replaced):
--    - the game's loot window (LootFrame) is no longer told that loot opened:
--      it does not hear LOOT_OPENED, so it never opens and never takes its
--      place among the game's panels. The rest it hears it still hears; the
--      game's own questions (a thing that binds when picked up, a master
--      looter's choice) are the game's event handlers', not the window's;
--    - the game's roll frames (GroupLootContainer) are lent to a hidden frame
--      of ours (Core.Lend): the game still adds, times and removes its rolls by
--      its own code, unseen, so switched back they stand as they should.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Game = {}
ns.Game = Game

local deaf = false -- the game's loot window does not hear LOOT_OPENED
local lent         -- the game's roll frames, lent to hidden
local hidden

-- Whether our loot window and our roll cards stand in for the game's now.
function Game.Window() return deaf end
function Game.Rolls() return lent ~= nil end

local function Hidden()
    if not hidden then
        hidden = CreateFrame("Frame", nil, UIParent)
        hidden:Hide()
    end
    return hidden
end

-- Ours or the game's, as the switches say (and the game's for good once the module stood down).
function Game.Update()
    local window = rawget(_G, "LootFrame")
    local ours = not ns.off and ns.options.window and true or false
    if window and ours ~= deaf then
        if ours then window:UnregisterEvent("LOOT_OPENED") else window:RegisterEvent("LOOT_OPENED") end
        deaf = ours
        if not ours then ns.Safe("window", ns.Window.Close) end
    end
    local container = rawget(_G, "GroupLootContainer")
    local rolls = not ns.off and ns.options.rolls and true or false
    if container and rolls and not lent then
        local lend = Core.Lend(container)
        if lend:SetParent(Hidden()) then lent = lend end
    elseif not rolls and lent then
        lent:Return()
        lent = nil
    end
    ns.Safe("rolls", ns.Rolls.Refresh)
end

function Game.GiveBack()
    local window = rawget(_G, "LootFrame")
    if window and deaf then window:RegisterEvent("LOOT_OPENED") end
    deaf = false
    if lent then
        lent:Return()
        lent = nil
    end
end
