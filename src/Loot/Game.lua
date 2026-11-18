local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Loot - Game
--  The game's own parts this module stands in for, kept out of the way while
--  ours are chosen, and given back (Doc/guides/windows.md, Taint and the game's
--  own windows: nothing of Blizzard's is written, no function replaced):
--    - the game's loot window (LootFrame) is lent deaf to LOOT_OPENED (Core's
--      lend, which notes what it heard and gives it back): it is no longer
--      told that loot opened, so it never opens and never takes its place
--      among the game's panels. The rest it hears it still hears; the
--      game's own questions (a thing that binds when picked up, a master
--      looter's choice) are the game's event handlers', not the window's;
--    - the game's own Auto Loot (its setting autoLootDefault, Esc > Options >
--      Controls) is lent off while our window is on (Core's Sync.Lend): the
--      player's switches Taken at once decide what is taken at once, not the
--      game. Sync then writes it no more from the profile (it did, a moment
--      after the login, and Auto Loot was on again where the profile had it on)
--      and keeps the player's own value in the profile. What it was is kept here
--      too (options.lent), for the next session's lend; given back when our
--      window goes, unless the player changed it meanwhile. The game's key for
--      it (Shift while looting) still takes everything;
--    - the game's roll frames (GroupLootContainer) are lent to a hidden frame
--      of ours (Core.Lend): the game still adds, times and removes its rolls by
--      its own code, unseen, so switched back they stand as they should.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Game = {}
ns.Game = Game

local DEAF = { "LOOT_OPENED" } -- what the game's loot window is lent deaf to
local deaf         -- the game's loot window, lent deaf to that (Core.Lend) while ours stands in for it
local lent         -- the game's roll frames, lent to hidden
local hidden

local AUTO_LOOT = "autoLootDefault"

local function Same(a, b) return tostring(a) == tostring(b) end

-- The game's Auto Loot lent off, through Core's Sync (which then leaves it alone); what it was kept the first
-- time, to be given back. Lent at every login, even while it is off already: the profile may hold it on.
local function Lend()
    local kept = ns.options.lent
    local now = Core.Plain(Core.Ask(C_CVar.GetCVar, AUTO_LOOT))
    if now == nil then return end
    if not kept[AUTO_LOOT] and not Same(now, "0") then kept[AUTO_LOOT] = { was = now, set = "0" } end
    local own = kept[AUTO_LOOT] and kept[AUTO_LOOT].was or now
    local sync = Core.Sync
    if sync and sync.Lend then
        sync.Lend(AUTO_LOOT, "0", own)
    elseif not Same(now, "0") then
        Core.Ask(C_CVar.SetCVar, AUTO_LOOT, "0")
    end
end

-- The game's Auto Loot back as it was (Sync's own value of it, which the profile may have set meanwhile), unless
-- the player set it otherwise.
local function PutBack()
    local kept = ns.options.lent
    local entry = type(kept) == "table" and kept[AUTO_LOOT]
    local sync = Core.Sync
    if sync and sync.Return then
        sync.Return(AUTO_LOOT)
    elseif type(entry) == "table" and Same(Core.Ask(C_CVar.GetCVar, AUTO_LOOT), entry.set) then
        Core.Ask(C_CVar.SetCVar, AUTO_LOOT, entry.was)
    end
    if type(kept) == "table" then kept[AUTO_LOOT] = nil end
end

-- Whether our loot window and our roll cards stand in for the game's now.
function Game.Window() return deaf ~= nil end
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
    if window and ours and not deaf then
        local lend = Core.Lend(window)
        if lend:SetDeaf(DEAF) then deaf = lend end
    elseif not ours and deaf then
        deaf:Return()
        deaf = nil
        ns.Safe("window", ns.Window.Close)
    end
    if deaf then ns.Safe("auto loot", Lend) else ns.Safe("auto loot", PutBack) end
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
    if deaf then
        ns.Safe("loot window", deaf.Return, deaf)
        deaf = nil
    end
    ns.Safe("auto loot", PutBack)
    if lent then
        lent:Return()
        lent = nil
    end
end
