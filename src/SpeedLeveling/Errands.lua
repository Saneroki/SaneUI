local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Errands
--  What would hold you up on the way, done for you (Saneroki, 2026-10-30), each
--  with a switch of its own, on in the profile Speedleveling:
--    Take all loot    the module Loot set to take everything at once (its
--                     switches Everything on, Always show upgrades off: what
--                     is an upgrade goes on by Equip upgrades). Each set once:
--                     what you change on Loot's page after that stays, and this
--                     switch off puts back what you did not change. The game's
--                     question on a thing that binds when picked up is answered.
--    Equip upgrades   gear that just came into your bags and is an upgrade
--                     (Core.Upgrade; the game's own flag of a new item, so what
--                     you took off yourself stays off) is put on, one at a time
--                     so that the next is measured against it, out of a fight.
--                     The game's question on a piece that binds when put on is
--                     answered; one that ends a trade or a refund is yours.
--    Skip cinematics  the game's cinematics and movies stopped as they start, a
--                     frame later when the game has them going, as Esc does.
--                     One the game does not let you leave plays on.
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Errands = {}
ns.Errands = Errands

Errands.EQUIP = 0.3   -- seconds after the bags changed, or a piece went on, before the next new upgrade is put on

local LOOT = "Loot"   -- the module whose switches Take all loot sets
local LENT = { takeAll = true, showUpgrades = false }

local tried = {}      -- the upgrades put on or tried (links): one the game refuses is not tried again

-------------------------------------------------------------------------------
--  Take all loot
-------------------------------------------------------------------------------
local function Lend()
    local loot, lent = Core.Settings(LOOT), ns.options.lootLent
    if not (loot and Core.Described(LOOT, "takeAll")) then return end
    for key, value in pairs(LENT) do
        if not lent[key] then
            lent[key] = { was = loot[key], set = value }
            Core.Set(LOOT, key, value)
        end
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
--  The game's questions on binding
-------------------------------------------------------------------------------
-- Each answered as its own Yes would, while the switch it belongs to is on: on a thing that binds when picked up (Take
-- all loot), and on a piece that binds when put on (Equip upgrades: the game asks before it puts on what PutOn asked
-- for, so without the answer the question would stay up and the chat's "Equipped" be wrong). One that ends a trade or
-- a refund stays yours.
local QUESTIONS = { LOOT_BIND = "lootAll", EQUIP_BIND = "equipUpgrades" }

local function Answer(which)
    local switch = QUESTIONS[which]
    if not switch or ns.off or not ns.options[switch] then return end
    local dialogs, find = rawget(_G, "StaticPopupDialogs"), rawget(_G, "StaticPopup_FindVisible")
    local info = type(dialogs) == "table" and dialogs[which]
    local dialog = info and find and Core.Ask(find, which)
    if not dialog or type(info.OnAccept) ~= "function" then return end
    Core.Ask(info.OnAccept, dialog, dialog.data, dialog.data2)
    Core.Ask(rawget(_G, "StaticPopup_Hide"), which)
end

-------------------------------------------------------------------------------
--  Equip upgrades
-------------------------------------------------------------------------------
-- The bags carried: the backpack and the bags, and the reagent bag where the game has one (Retail; Forever has none).
local function BagCount()
    local constants = rawget(_G, "Constants")
    constants = type(constants) == "table" and constants.InventoryConstants or nil
    local bags = constants and constants.NumBagSlots or rawget(_G, "NUM_BAG_SLOTS") or 4
    return bags + (constants and constants.NumReagentBagSlots or 0)
end

-- The first new item in your bags that is an upgrade, and the place it goes.
local function NewUpgrade()
    local bags, new = rawget(_G, "C_Container"), rawget(_G, "C_NewItems")
    if not (bags and new) then return nil end
    for bag = 0, BagCount() do
        for slot = 1, Core.Ask(bags.GetContainerNumSlots, bag) or 0 do
            if Core.Ask(new.IsNewItem, bag, slot) then
                local link = Core.Ask(bags.GetContainerItemLink, bag, slot)
                if type(link) == "string" and not tried[link] then
                    local kind, _, place = Core.Upgrade(link)
                    if kind then return link, place end
                end
            end
        end
    end
    return nil
end

local PutOnSoon
local function PutOn()
    if ns.off or not ns.options.equipUpgrades or InCombatLockdown() then return end
    if Core.Ask(rawget(_G, "CursorHasItem")) or Core.Ask(rawget(_G, "UnitIsDeadOrGhost"), "player") then return end
    local link, place = NewUpgrade()
    if not link then return end
    tried[link] = true
    Core.Ask(rawget(_G, "C_Item") and C_Item.EquipItemByName or rawget(_G, "EquipItemByName"), link, place)
    ns.Print(ns.TEXT.equipped:format(link))
    PutOnSoon()
end
PutOnSoon = Core.Later(function() ns.Guarded(PutOn) end, Errands.EQUIP)

-------------------------------------------------------------------------------
--  Skip cinematics
-------------------------------------------------------------------------------
local stoppable       -- the cinematic starting can be stopped as such; else only a scene that lets you

local SkipScene = Core.Later(function()
    ns.Guarded(function()
        if ns.off or not ns.options.cinematics then return end
        if stoppable then
            Core.Ask(rawget(_G, "StopCinematic"))
        elseif Core.Ask(rawget(_G, "CanCancelScene")) then
            Core.Ask(rawget(_G, "CancelScene"))
        end
    end)
end)

local SkipMovie = Core.Later(function()
    ns.Guarded(function()
        local movie = rawget(_G, "MovieFrame")
        if ns.off or not ns.options.cinematics or not movie then return end
        Core.Ask(movie.FinishMovie, movie)
    end)
end)

function Errands.Start()
    Errands.Update()
    ns.On("CINEMATIC_START", function(canStop)
        stoppable = Core.Plain(canStop) and true or false
        SkipScene()
    end)
    ns.On("PLAY_MOVIE", SkipMovie)
    if rawget(_G, "StaticPopup_Show") then hooksecurefunc("StaticPopup_Show", ns.Guard(Answer)) end
    ns.On("BAG_UPDATE_DELAYED", PutOnSoon)
    ns.On("PLAYER_REGEN_ENABLED", PutOnSoon)
end
