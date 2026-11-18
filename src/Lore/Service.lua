local _, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Lore - Service
--  Straight to what an NPC is there for (Saneroki, 2026-11-06: past the
--  gossip of "I need a ride" and "Show me your wares", Shift for the choices):
--  a vendor's goods, a flight master's map, a trainer's lessons, the bank, the
--  auction house, a battlemaster, a tabard or a guild charter open at once,
--  without the talk before them, where that service is the one the NPC has for
--  you: no quest to take, hand in or go on with, no other service. Beside it
--  may stand what is only talk (Saneroki, 2026-11-06: "Skip those too") and a
--  trainer's unlearning, never an option the game marks as a quest's. So
--  whether the talk is ours or the game's, and with Speed Leveling or without
--  it. An option is known by the game's own icon of its kind.
--  The option is taken a frame later, and not when something else answered the
--  gossip meanwhile (Speed Leveling's guide naming an option there, another
--  addon): the game's answers are hooked and counted.
--  Left a talk: Shift held as it opens (the talk and its choices), the talk
--  that opens again after a quest at that NPC (a quest handed in at a vendor
--  opens no shop), an only option the game takes by itself, gossip with a
--  window of its own (the game's custom gossip frames). Where the game does not
--  move on from the option taken, the talk shows after all.
--
--      Service.Start()           its events, the game's answers hooked
--      Service.Take(kit, again)  the service to be taken for this gossip: true; again(kit, true) shows the talk
--                                when the game does not move on from it
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Service = {}
ns.Service = Service

Service.AFTER = 5  -- seconds after a quest window at an NPC closed in which its gossip opening again is a talk
                   -- (as long as Speed Leveling closes such a talk)
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
local ASIDE = {
    [132053] = true,   -- GossipGossipIcon: talk
    [1019848] = true,  -- ChatBubbleGossipIcon: talk
    [132059] = true,   -- UnlearnGossipIcon: a trainer's unlearning
}
local TALKS = { [3] = true, [4] = true } -- the game's interaction types of a talk (gossip, quest giver)
local ANSWERS = { "SelectOption", "SelectOptionByIndex", "SelectAvailableQuest", "SelectActiveQuest", "CloseGossip" }

local quested = {}  -- the last quest window closed: guid (its NPC), when
local pending       -- the service to take, until the game moves on: kit, again, when, index, answered
local answered = 0  -- the gossip's answers given so far, by anyone

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

-- An option the game marks as a quest's (it writes "(Quest)" before it).
local function Quest(option)
    local flags = Enum and Enum.GossipOptionRecFlags
    local mark = flags and flags.QuestLabelPrepend
    return mark ~= nil and type(option.flags) == "number" and bit.band(option.flags, mark) ~= 0
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
        if Quest(option) then
            return nil
        elseif SERVICE[icon] and not found and Open(option) then
            found = option
        elseif not ASIDE[icon] then
            return nil
        end
    end
    return found and found.orderIndex
end

-- A frame later: taken, unless the gossip was answered meanwhile (or is gone, or another came).
local take = Core.Later(function()
    local was = pending
    if not was or was.answered ~= answered then return end
    local gossip = rawget(_G, "C_GossipInfo")
    if gossip then Core.Ask(gossip.SelectOptionByIndex, was.index) end
end)

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
    pending = { kit = kit, again = again, when = GetTime(), index = index, answered = answered }
    take()
    late()
    return true
end

local function Answered()
    answered = answered + 1
end

function Service.Start()
    local gossip = rawget(_G, "C_GossipInfo")
    for _, name in ipairs(ANSWERS) do
        if gossip and type(gossip[name]) == "function" then hooksecurefunc(gossip, name, ns.Guard(Answered)) end
    end
    ns.On("GOSSIP_CLOSED", function() pending = nil end)
    ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(kind)
        if not TALKS[kind] then pending = nil end
    end)
    ns.On("QUEST_FINISHED", function()
        quested.guid, quested.when = Npc(), GetTime()
    end)
end
