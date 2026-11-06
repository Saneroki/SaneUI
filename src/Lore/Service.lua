local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Service
--  Straight to what an NPC is there for (Saneroki, 2026-11-06: past the
--  gossip of "I need a ride" and "Show me your wares", Shift for the choices):
--  a vendor's goods, a flight master's map, a trainer's lessons, the bank, the
--  auction house, a battlemaster, a tabard or a guild charter open at once,
--  without the talk before them, where that service is all the NPC has for
--  you: no quest to take, hand in or go on with, no other option but a
--  trainer's unlearning. So whether the talk is ours or the game's, and with
--  Speed Leveling or without it. An option is known by the game's own icon of
--  its kind.
--  Left a talk: Shift held as it opens (the talk and its choices), the talk
--  that opens again after a quest at that NPC (a quest handed in at a vendor
--  opens no shop), an only option the game takes by itself, gossip with a
--  window of its own (the game's custom gossip frames). Where the game does not
--  move on from the option taken, the talk shows after all.
--
--      Service.Start()           its events
--      Service.Take(kit, again)  the service taken for this gossip: true; again(kit, true) shows the talk
--                                when the game does not move on from it
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Service = {}
ns.Service = Service

Service.AFTER = 3  -- seconds after a quest window at an NPC closed in which its gossip opening again is a talk
Service.WAIT = 1   -- seconds the game has to move on from the option taken, else the talk shows

-- The game's icons of an option's kind (Interface\GossipFrame): the services, and what may stand beside one.
local SERVICE = {
    [132060] = true,  -- VendorGossipIcon
    [132057] = true,  -- TaxiGossipIcon
    [132058] = true,  -- TrainerGossipIcon
    [132050] = true,  -- BankerGossipIcon
    [528409] = true,  -- the auction house's
    [132051] = true,  -- BattleMasterGossipIcon
    [132056] = true,  -- TabardGossipIcon
    [132055] = true,  -- PetitionGossipIcon
}
local ASIDE = { [132059] = true }       -- UnlearnGossipIcon: a trainer's unlearning
local TALKS = { [3] = true, [4] = true } -- the game's interaction types of a talk (gossip, quest giver)

local quested = {}  -- the last quest window closed: guid (its NPC), when
local pending       -- the service taken, until the game moves on: kit, again, when

local function Npc()
    return Plain(Core.Ask(UnitGUID, "npc"))
end

local function AfterQuest()
    if not quested.when or GetTime() - quested.when > Service.AFTER then return false end
    return quested.guid == nil or quested.guid == Npc()
end

local function Open(option)
    local available = Enum and Enum.GossipOptionStatus and Enum.GossipOptionStatus.Available or 0
    return (option.status or available) == available
end

-- The option to take: the gossip's one service, with nothing else for you there; nil otherwise.
local function Only(gossip)
    if (Core.Ask(gossip.GetNumAvailableQuests) or 0) > 0 or (Core.Ask(gossip.GetNumActiveQuests) or 0) > 0 then
        return nil
    end
    local options = Core.Ask(gossip.GetOptions) or {}
    -- The game takes an only option it marks by itself.
    if #options == 1 and options[1].selectOptionWhenOnlyOption and not Core.Ask(gossip.ForceGossip) then return nil end
    local found
    for _, option in ipairs(options) do
        local icon = Plain(option.icon)
        if SERVICE[icon] and not found and Open(option) then
            found = option
        elseif not ASIDE[icon] then
            return nil
        end
    end
    return found and found.orderIndex
end

-- The game did not move on from the option taken (no window opened, the gossip still there): the talk after all.
local late
late = Core.Later(function()
    local was = pending
    if not was then return end
    if GetTime() - was.when < Service.WAIT then return late() end
    pending = nil
    ns.Guarded(was.again, was.kit, true)
end, Service.WAIT)

function Service.Take(kit, again)
    pending = nil
    local gossip = rawget(_G, "C_GossipInfo")
    if not ns.options.service or ns.off or not gossip then return false end
    if Core.Ask(rawget(_G, "IsShiftKeyDown")) or AfterQuest() then return false end
    local manager = rawget(_G, "CustomGossipFrameManager")
    if kit and manager and manager.GetHandler and manager:GetHandler(kit) then return false end
    local index = Only(gossip)
    if not index then return false end
    pending = { kit = kit, again = again, when = GetTime() }
    late()
    Core.Ask(gossip.SelectOptionByIndex, index)
    return true
end

function Service.Start()
    ns.On("GOSSIP_CLOSED", function() pending = nil end)
    ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(kind)
        if not TALKS[kind] then pending = nil end
    end)
    ns.On("QUEST_FINISHED", function()
        quested.guid, quested.when = Npc(), GetTime()
    end)
end
