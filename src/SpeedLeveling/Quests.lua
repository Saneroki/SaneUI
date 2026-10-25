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
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Plain = Core.Plain
local Quests = {}
ns.Quests = Quests

local EMPTY = {}

-- What the guide wants of quest givers now; nil when nothing may be done for you.
local function Wants()
    if ns.off or Core.Ask(rawget(_G, "IsShiftKeyDown")) then return nil end
    return ns.Guide.Quests()
end

local function Call(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return Core.Ask(fn, ...) end
end

-- The gossip window: a quest to hand in that is done, else one to take, else the option a step names.
local function Gossip()
    local wants = Wants()
    local gossip = rawget(_G, "C_GossipInfo")
    if not wants or not gossip then return end
    if ns.options.handin then
        for _, quest in ipairs(Core.Ask(gossip.GetActiveQuests) or EMPTY) do
            local id = Plain(quest.questID)
            if id and wants.handin[id] and Plain(quest.isComplete) then
                return Core.Ask(gossip.SelectActiveQuest, id)
            end
        end
    end
    if ns.options.take then
        for _, quest in ipairs(Core.Ask(gossip.GetAvailableQuests) or EMPTY) do
            local id = Plain(quest.questID)
            if id and wants.take[id] then return Core.Ask(gossip.SelectAvailableQuest, id) end
        end
    end
    if ns.options.gossip then
        local options = Core.Ask(gossip.GetOptions) or EMPTY
        for _, wanted in ipairs(wants.gossip) do
            for index, option in ipairs(options) do
                local id = Plain(option.gossipOptionID)
                if (wanted.id and id == wanted.id) or (wanted.index and index == wanted.index) then
                    return Core.Ask(gossip.SelectOption, id)
                end
            end
        end
    end
end

-- The older greeting of a quest giver with several quests: as the gossip window, by the game's numbers of them.
local function Greeting()
    local wants = Wants()
    if not wants then return end
    if ns.options.handin then
        for index = 1, Call("GetNumActiveQuests") or 0 do
            local _, done = Call("GetActiveTitle", index)
            local id = Call("GetActiveQuestID", index)
            if id and wants.handin[id] and done then return Call("SelectActiveQuest", index) end
        end
    end
    if ns.options.take then
        for index = 1, Call("GetNumAvailableQuests") or 0 do
            -- Its fifth answer is the quest's ID.
            local answers = { pcall(rawget(_G, "GetAvailableQuestInfo") or error, index) }
            local id = answers[1] and Plain(answers[6]) or nil
            if id and wants.take[id] then return Call("SelectAvailableQuest", index) end
        end
    end
end

-- A quest offered: taken when the guide takes it.
local function Offered()
    local wants = Wants()
    local id = Call("GetQuestID")
    if not (wants and ns.options.take and id and wants.take[id]) then return end
    if Call("QuestFlagsPVP") then return end
    if Call("QuestGetAutoAccept") then return Call("AcknowledgeAutoAcceptQuest") end
    Call("AcceptQuest")
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
    if type(named) == "number" and named >= 1 and named <= choices then return Call("GetQuestReward", named) end
    if choices <= 1 then Call("GetQuestReward", choices) end
end

function Quests.Start()
    ns.On("GOSSIP_SHOW", Gossip)
    ns.On("QUEST_GREETING", Greeting)
    ns.On("QUEST_DETAIL", Offered)
    ns.On("QUEST_PROGRESS", Progress)
    ns.On("QUEST_COMPLETE", Rewards)
end
