local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Rolls
--  Group rolls decided for you (the switch Roll on group loot, in the profile
--  Speedleveling; Saneroki, 2026-10-30): each character on its own Needs what
--  is an upgrade to it (Core.Upgrade), where the game lets it, and Greeds the
--  rest. Nobody Passes: without Greed it takes what the game offers, Need last.
--  Switch off: nothing is rolled, the rolls stay yours. The game's question on a
--  thing that binds is answered for the rolls made here.
--
--      Rolls.Start()   listens, from the login on
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Rolls = {}
ns.Rolls = Rolls

Rolls.LAST = 10000   -- milliseconds left on a roll's clock at which it is rolled, the item described or not
Rolls.TICK = 0.5     -- seconds between looks at a roll whose item the game has not described yet

local NEED, GREED, DISENCHANT, TRANSMOG = 1, 2, 3, 4

local open = {}      -- [rollID] = { link, item, need, greed, disenchant, transmog }: waiting for the item's description
local mine = {}      -- [rollID] = true: rolled here, the game's question is ours to answer
local Look

-- What you roll on what is no upgrade, the best first; Need last, for a thing that offers nothing else.
local function Any(roll)
    if roll.greed then return GREED end
    if roll.transmog then return TRANSMOG end
    if roll.disenchant then return DISENCHANT end
    return roll.need and NEED or nil
end

-- Whether the game can say yet what the item is.
local function Described(roll)
    return Core.Ask(rawget(_G, "C_Item") and C_Item.GetItemInfo or rawget(_G, "GetItemInfo"), roll.link) ~= nil
end

local function Decide(rollID, roll)
    open[rollID] = nil
    local choice = roll.need and Core.Upgrade(roll.link, roll.item) and NEED or Any(roll)
    if not choice then return end
    mine[rollID] = true
    Core.Ask(rawget(_G, "RollOnLoot"), rollID, choice)
end

local function Tick()
    local any = false
    for rollID, roll in pairs(open) do
        local left = Plain(Core.Ask(rawget(_G, "GetLootRollTimeLeft"), rollID))
        if ns.off or not ns.options.rolls or type(left) ~= "number" or left <= 0 then
            open[rollID] = nil
        elseif Described(roll) or left <= Rolls.LAST then
            Decide(rollID, roll)
        else
            any = true
        end
    end
    if any then Look() end
end
Look = Core.Later(function() ns.Guarded(Tick) end, Rolls.TICK)

local function Started(rollID)
    rollID = Plain(rollID)
    if ns.off or not ns.options.rolls or open[rollID] then return end
    local link = Plain(Core.Ask(rawget(_G, "GetLootRollItemLink"), rollID))
    local ok, _, _, _, _, _, canNeed, canGreed, canDisenchant, _, _, _, _, canTransmog = pcall(GetLootRollItemInfo, rollID)
    if not ok or type(link) ~= "string" then return end
    open[rollID] = { link = link, item = tonumber(link:match("item:(%d+)")), need = Plain(canNeed) and true or false,
                     greed = Plain(canGreed) and true or false, disenchant = Plain(canDisenchant) and true or false,
                     transmog = Plain(canTransmog) and true or false }
    Tick()
end

-- The game asks whether a thing may bind: yes, for a roll made here. Its dialog goes a frame later: the game shows it
-- after telling us.
local HideQuestion = Core.Later(function()
    ns.Guarded(function() Core.Ask(rawget(_G, "StaticPopup_Hide"), "CONFIRM_LOOT_ROLL") end)
end)
local function Asked(rollID, choice)
    rollID = Plain(rollID)
    if not mine[rollID] then return end
    Core.Ask(rawget(_G, "ConfirmLootRoll"), rollID, Plain(choice))
    HideQuestion()
end

function Rolls.Start()
    ns.On("START_LOOT_ROLL", Started)
    ns.On("CONFIRM_LOOT_ROLL", Asked)
    ns.On("CONFIRM_DISENCHANT_ROLL", Asked)
    ns.On("CANCEL_LOOT_ROLL", function(rollID)
        rollID = Plain(rollID)
        open[rollID], mine[rollID] = nil, nil
    end)
end
