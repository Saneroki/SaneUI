local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Quests
--  What a quest giver does for your guide (Saneroki, 2026-10-25: one press at
--  the quest giver, and the guide's quests are taken and handed in): while you
--  talk to an NPC, the quests the steps at hand take are accepted (those of the
--  step after them too, which a quest giver often offers at once), those they
--  hand in are handed in, with the reward the step names, else the only one (a
--  choice of several is yours), and the talk option a step names is chosen.
--  Only the guide's quests (Guide.Quests); with Shift held, nothing: the game's
--  windows as they are. The switches Take the guide's quests, Hand in the
--  guide's quests, Choose the guide's talk.
--
--  The game's own ways (its quest and gossip windows' functions): its gossip
--  window's quests and options (C_GossipInfo), the older greeting of a quest
--  giver with several quests, a quest's offer, its progress, its rewards. A
--  quest that asks for a confirmation (one for PvP) is left to the player.
--
--  A talk that is done (Saneroki, 2026-10-30: the key talked again after the
--  quest was taken and stayed on the goodbye screen; the switch Close the talk
--  when it is done): an NPC you took or handed in a quest at, or whose talk
--  had nothing for your guide, is one you are through with, and the key leaves
--  it alone (Quests.Left) until you move on to something else, the quest log
--  changes or Quests.LEFT is over. A talk that comes up with nothing for you
--  is closed: at once where nothing can be chosen at all, and for Quests.AFTER
--  seconds after a quest done there whatever else the NPC offers. Quests the
--  guide does not know keep a talk open: those are yours to choose.
--
--      Quests.Left(guid, wanted)  whether the key leaves that NPC alone; wanted: your guide still wants it by name
--      Quests.Moved(thing, target)  what the key sees now; another thing: the NPC is forgotten
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Quests = {}
ns.Quests = Quests

Quests.AFTER = 5   -- seconds after a quest done at an NPC in which a talk that opens again is closed
Quests.SETTLE = 2  -- seconds the quest log goes on changing after that quest
Quests.LEFT = 30   -- seconds the key leaves an NPC alone, at most

local EMPTY = {}
local left = {}    -- the NPC you are through with: guid, when, did (when a quest was done there), looked (a talk found nothing)

-- What the guide wants of quest givers now; nil when nothing may be done for you.
local function Wants()
    if ns.off or Core.Ask(rawget(_G, "IsShiftKeyDown")) then return nil end
    return ns.Guide.Quests()
end

local function Call(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return Core.Ask(fn, ...) end
end

local function Talking()
    return Core.Ask(UnitGUID, "npc")
end

function Quests.Forget()
    left.guid = nil
    ns.Key.Refresh()
end

function Quests.Moved(thing, target)
    if left.guid and thing and thing ~= left.guid and target ~= left.guid then left.guid = nil end
end

function Quests.Left(guid, wanted)
    return guid ~= nil and guid == left.guid and (left.looked or not wanted) and true or false
end

local ForgetSoon = Core.Later(function() ns.Guarded(Quests.Forget) end, Quests.LEFT)

local function Through(guid, looked)
    if type(guid) ~= "string" then return end
    left.guid, left.when, left.looked = guid, GetTime(), looked
    ForgetSoon()
    ns.Guarded(ns.Key.Refresh)
end

-- A quest taken or handed in at that NPC.
local function Done(guid)
    left.did = GetTime()
    Through(guid, false)
end

-- The talk closed a frame later: the game's own window has heard of it by then.
local Bye = Core.Later(function()
    ns.Guarded(function()
        local gossip = rawget(_G, "C_GossipInfo")
        if gossip then Core.Ask(gossip.CloseGossip) end
        Call("CloseQuest")
    end)
end)

-- The talk has nothing for your guide. offers: quests of the NPC's that are yours to choose; choices: its other options.
local function Nothing(offers, choices)
    local guid = Talking()
    local just = guid == left.guid and left.did and GetTime() - left.did < Quests.AFTER
    local wanted = ns.Wanted.Unit("npc")
    Through(guid, true)
    if not ns.options.leave or offers then return end
    if choices == 0 or (just and not wanted) then Bye() end
end

-- The gossip window: a quest to hand in that is done, else one to take, else the option a step names.
local function Gossip()
    local wants = Wants()
    local gossip = rawget(_G, "C_GossipInfo")
    if not wants or not gossip then return end
    local active = Core.Ask(gossip.GetActiveQuests) or EMPTY
    local available = Core.Ask(gossip.GetAvailableQuests) or EMPTY
    local options = Core.Ask(gossip.GetOptions) or EMPTY
    local offers = available[1] ~= nil
    for _, quest in ipairs(active) do
        local id = Plain(quest.questID)
        if Plain(quest.isComplete) then
            if ns.options.handin and id and wants.handin[id] then return Core.Ask(gossip.SelectActiveQuest, id) end
            offers = true
        end
    end
    if ns.options.take then
        for _, quest in ipairs(available) do
            local id = Plain(quest.questID)
            if id and wants.take[id] then return Core.Ask(gossip.SelectAvailableQuest, id) end
        end
    end
    if ns.options.gossip then
        for _, wanted in ipairs(wants.gossip) do
            for index, option in ipairs(options) do
                local id = Plain(option.gossipOptionID)
                if (wanted.id and id == wanted.id) or (wanted.index and index == wanted.index) then
                    return Core.Ask(gossip.SelectOption, id)
                end
            end
        end
    end
    Nothing(offers, #options)
end

-- The older greeting of a quest giver with several quests: as the gossip window, by the game's numbers of them.
local function Greeting()
    local wants = Wants()
    if not wants then return end
    local count = Call("GetNumAvailableQuests") or 0
    local offers = count > 0
    for index = 1, Call("GetNumActiveQuests") or 0 do
        local _, done = Call("GetActiveTitle", index)
        local id = Call("GetActiveQuestID", index)
        if done then
            if ns.options.handin and id and wants.handin[id] then return Call("SelectActiveQuest", index) end
            offers = true
        end
    end
    if ns.options.take then
        for index = 1, count do
            -- Its fifth answer is the quest's ID.
            local answers = { pcall(rawget(_G, "GetAvailableQuestInfo") or error, index) }
            local id = answers[1] and Plain(answers[6]) or nil
            if id and wants.take[id] then return Call("SelectAvailableQuest", index) end
        end
    end
    Nothing(offers, 0)
end

-- A quest offered: taken when the guide takes it.
local function Offered()
    local wants = Wants()
    local id = Call("GetQuestID")
    if not (wants and ns.options.take and id and wants.take[id]) then return end
    if Call("QuestFlagsPVP") then return end
    local guid = Talking()
    if Call("QuestGetAutoAccept") then Call("AcknowledgeAutoAcceptQuest") else Call("AcceptQuest") end
    Done(guid)
end

-- A quest's progress: on to its rewards when it can be handed in and the guide hands it in.
local function Progress()
    local wants = Wants()
    local id = Call("GetQuestID")
    if wants and ns.options.handin and id and wants.handin[id] and Call("IsQuestCompletable") then Call("CompleteQuest") end
end

-- A quest's rewards: the one the step names, else the only one; with several and none named, the choice is yours.
local function Rewards()
    local wants = Wants()
    local id = Call("GetQuestID")
    if not (wants and ns.options.handin and id and wants.handin[id]) then return end
    local choices = Call("GetNumQuestChoices") or 0
    local named = wants.handin[id]
    local reward
    if type(named) == "number" and named >= 1 and named <= choices then
        reward = named
    elseif choices <= 1 then
        reward = choices
    end
    if not reward then return end
    local guid = Talking()
    Call("GetQuestReward", reward)
    Done(guid)
end

-- The quest log changed after the quest done has settled: that NPC may be wanted again.
local function LogChanged()
    if left.guid and GetTime() - left.when > Quests.SETTLE then Quests.Forget() end
end

function Quests.Start()
    ns.On("GOSSIP_SHOW", Gossip)
    ns.On("QUEST_GREETING", Greeting)
    ns.On("QUEST_DETAIL", Offered)
    ns.On("QUEST_PROGRESS", Progress)
    ns.On("QUEST_COMPLETE", Rewards)
    ns.On("QUEST_LOG_UPDATE", LogChanged)
end
