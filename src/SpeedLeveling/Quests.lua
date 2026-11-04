local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling - Quests
--  What a quest giver does for your guide (Saneroki, 2026-10-25: one press at
--  the quest giver, and the guide's quests are taken and handed in): while you
--  talk to an NPC, the quests the steps at hand take are accepted (those of the
--  step after them too, which a quest giver often offers at once), those they
--  hand in are handed in, the reward chosen among several (Rewards.lua), and the
--  talk option a step names is chosen. An NPC with two of the guide's quests
--  gets the second with the talk that opens again, or the next press.
--  Only the guide's quests (Guide.Quests). The switches Take the guide's quests,
--  Hand in the guide's quests, Choose the guide's talk.
--
--  Shift (Saneroki, 2026-10-30) makes a talk yours: seen at any step of it,
--  nothing more is accepted, handed in, chosen or closed for you with that NPC,
--  held or let go, until the talk is over: you may let go to read what you opened.
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
--  changes or Quests.LEFT is over, unless your guide still wants a quest it
--  may have. A talk that comes up with nothing for you is closed: at once where
--  nothing can be chosen at all, and once within Quests.AFTER seconds of a
--  quest done there whatever else the NPC offers, the quests the guide does not
--  know included (Saneroki, 2026-10-30: those are ignored). A talk you open
--  yourself after that stays open for them.
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
Quests.OVER = 0.5  -- seconds after a window closed before the talk counts as over
Quests.WAIT = 0.2  -- seconds before the rewards are looked at again, while the game does not know them yet
Quests.TRIES = 10  -- how often, at most

local EMPTY = {}
local left = {}    -- the NPC you are through with: guid, when, looked (a talk found nothing), sure (its list showed no more)
local did = {}     -- the last quest done at an NPC, until a talk there came up again: guid, when
local more = 0     -- how many more of the guide's quests the NPC's list showed in this talk
local tries = 0    -- looks at the rewards on show
local held         -- whose talk is yours: Shift was seen in it (true: a quest that came without an NPC)

local function Talking()
    return Core.Ask(UnitGUID, "npc")
end

-- What the guide wants of quest givers now; nil when nothing may be done for you.
local function Wants()
    local who = Talking() or true
    if Core.Ask(rawget(_G, "IsShiftKeyDown")) then held = who end
    if ns.off or held == who then return nil end
    return ns.Guide.Quests()
end

local function Call(name, ...)
    local fn = rawget(_G, name)
    if type(fn) == "function" then return Core.Ask(fn, ...) end
end

-- A window closed: Shift's hold ends with the talk, not with the gossip window that made way for a quest.
local Closed = Core.Later(function()
    ns.Guarded(function()
        if not Talking() then held = nil end
    end)
end, Quests.OVER)

function Quests.Forget()
    left.guid = nil
    ns.Key.Refresh()
end

function Quests.Moved(thing, target)
    if left.guid and thing and thing ~= left.guid and target ~= left.guid then left.guid = nil end
end

-- Whether your guide still wants a quest: one to take that is not in your log (sure: that NPC showed no more), or a
-- finished one to hand in. The NPC may well be the one who has it.
local function Owed(sure)
    local wants = ns.Guide.Quests()
    if not wants then return false end
    if not sure then
        for id in pairs(wants.take) do
            if not ns.Lines.OnQuest(id) then return true end
        end
    end
    for id in pairs(wants.handin) do
        if ns.Lines.Ready(id) then return true end
    end
    return false
end

function Quests.Left(guid, wanted)
    if not ns.options.leave or guid == nil or guid ~= left.guid then return false end
    return left.looked or not (wanted or Owed(left.sure))
end

-- The name of the NPC the key leaves alone even where your guide wants it by name (a talk that found nothing to do),
-- so that Find does not target it again (Saneroki, 2026-11-04: a press at a quest hub found that NPC each time); nil:
-- none.
function Quests.LeftName()
    if not (left.guid and left.name and Quests.Left(left.guid, true)) then return nil end
    return left.name
end

local ForgetSoon = Core.Later(function() ns.Guarded(Quests.Forget) end, Quests.LEFT)

local function Through(guid, looked, sure)
    if type(guid) ~= "string" then return end
    left.guid, left.when, left.looked, left.sure = guid, GetTime(), looked, sure
    left.name = guid == Talking() and Core.Plain(Core.Ask(UnitName, "npc")) or nil
    ForgetSoon()
    ns.Guarded(ns.Key.Refresh)
end

-- A quest taken or handed in at that NPC. More of the guide's on its list: not through with it yet. taken: its list
-- showed no more, where a hand-in may open the next.
local function Done(guid, taken)
    did.guid, did.when = guid, GetTime()
    if more > 0 then
        more, left.guid = 0, nil
        return ns.Guarded(ns.Key.Refresh)
    end
    Through(guid, false, taken)
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
    local just = guid and did.guid == guid and GetTime() - did.when < Quests.AFTER
    did.guid = nil
    Through(guid, true)
    if not ns.options.leave then return end
    if just or (choices == 0 and not offers) then Bye() end
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
    local give, take, count = nil, nil, 0
    for _, quest in ipairs(active) do
        local id = Plain(quest.questID)
        if Plain(quest.isComplete) then
            offers = true
            if ns.options.handin and id and wants.handin[id] then give, count = give or id, count + 1 end
        end
    end
    if ns.options.take then
        for _, quest in ipairs(available) do
            local id = Plain(quest.questID)
            if id and wants.take[id] then take, count = take or id, count + 1 end
        end
    end
    more = math.max(count - 1, 0)
    if give then return Core.Ask(gossip.SelectActiveQuest, give) end
    if take then return Core.Ask(gossip.SelectAvailableQuest, take) end
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
    local available = Call("GetNumAvailableQuests") or 0
    local offers = available > 0
    local give, take, count = nil, nil, 0
    for index = 1, Call("GetNumActiveQuests") or 0 do
        local _, done = Call("GetActiveTitle", index)
        local id = Call("GetActiveQuestID", index)
        if done then
            offers = true
            if ns.options.handin and id and wants.handin[id] then give, count = give or index, count + 1 end
        end
    end
    if ns.options.take then
        for index = 1, available do
            -- Its fifth answer is the quest's ID.
            local answers = { pcall(rawget(_G, "GetAvailableQuestInfo") or error, index) }
            local id = answers[1] and Plain(answers[6]) or nil
            if id and wants.take[id] then take, count = take or index, count + 1 end
        end
    end
    more = math.max(count - 1, 0)
    if give then return Call("SelectActiveQuest", give) end
    if take then return Call("SelectAvailableQuest", take) end
    Nothing(offers, 0)
end

-- A quest offered: taken when the guide takes it; one the guide does not know is never taken, and closed when it comes
-- right after a quest done there.
local function Offered()
    local wants = Wants()
    local id = Call("GetQuestID")
    if not (wants and ns.options.take and id) then return end
    if not wants.take[id] then return Nothing(true, 1) end
    if Call("QuestFlagsPVP") then return end
    local guid = Talking()
    if Call("QuestGetAutoAccept") then Call("AcknowledgeAutoAcceptQuest") else Call("AcceptQuest") end
    Done(guid, true)
end

-- A quest's progress: on to its rewards when it can be handed in and the guide hands it in.
local function Progress()
    local wants = Wants()
    local id = Call("GetQuestID")
    if wants and ns.options.handin and id and wants.handin[id] and Call("IsQuestCompletable") then Call("CompleteQuest") end
end

-- A quest's rewards: the only one; of several the one Rewards.lua picks (the switch off: the one the step names); with
-- nothing to go by the choice is yours. While the game does not know them all yet, looked at again in a moment.
local RewardsSoon
local function Rewards()
    local wants = Wants()
    local id = Call("GetQuestID")
    if not (wants and ns.options.handin and id and wants.handin[id]) then return end
    local choices = Call("GetNumQuestChoices") or 0
    local named = wants.handin[id]
    local reward
    if choices <= 1 then
        reward = choices
    elseif ns.options.rewards then
        reward = ns.Rewards.Best(named, choices)
    elseif type(named) == "number" and named >= 1 and named <= choices then
        reward = named
    end
    if reward == false then
        tries = tries + 1
        if tries < Quests.TRIES then RewardsSoon() end
        return
    end
    if not reward then return end
    local guid = Talking()
    Call("GetQuestReward", reward)
    Done(guid)
end
RewardsSoon = Core.Later(function() ns.Guarded(Rewards) end, Quests.WAIT)

local function RewardsShown()
    tries = 0
    Rewards()
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
    ns.On("QUEST_COMPLETE", RewardsShown)
    ns.On("QUEST_LOG_UPDATE", LogChanged)
    ns.On("GOSSIP_CLOSED", Closed)
    ns.On("QUEST_FINISHED", Closed)
end
