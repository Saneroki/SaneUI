-- Lore: a talk with an innkeeper over the world, her services as big pictures over the talk, the answers beside it
-- Core and Lore from their TOCs, over a screenshot of the world. The gossip is the scene's own: the game's gossip calls
-- stand in for an innkeeper with a quest to hand in, a word to say, the hearthstone, her goods and the bank (refused
-- for now: its picture greyed, its tooltip says why); the answer given is printed in the log. No 3D in the lab: the
-- face is a dashed box. The module is LabTalk in the console: LabGossip(n) opens the talk again with the first n
-- options (LabGossip() all of them), LabGuard() a city guard's with fourteen places to ask the way to (its column lifted
-- onto the screen; SaneUI.Core.Set("Lore", "size", 150) makes it taller than the screen: the wheel and the arrows go
-- through it), LabQuest("detail"), ("progress") or ("complete") a quest at that screen, its rewards read,
-- LabTalk.Talk.Redraw() draws it anew.

-- The game's gossip and quest windows, closed, as Lore's Native.lua holds them (the lab loads neither).
CreateFrame("Frame", "GossipFrame", UIParent):Hide()
CreateFrame("Frame", "QuestFrame", UIParent):Hide()

-- The world under the talk, in sight while the interface fades out.
local world = CreateFrame("Frame", nil, UIParent)
world:SetAllPoints(UIParent)
world:SetFrameStrata("BACKGROUND")
world:SetIgnoreParentAlpha(true)
local ground = world:CreateTexture(nil, "BACKGROUND")
ground:SetAllPoints(world)
ground:SetTexture("assets/generated/ui-lab/backdrops/elwynn-forest")

local OPTIONS = {
    { name = "Make this inn your home.", icon = 132052 },                   -- the binder's: the hearthstone
    { name = "Let me browse your goods.", icon = 132060 },                  -- the vendor's
    { name = "What can I do in Goldshire?", icon = 132053 },                -- a word to say
    { name = "I would like to check my deposit box.", icon = 132050,        -- the banker's, refused for now
      status = 2, failureDescription = "The vault opens at dawn." },
    { name = "Train me.", icon = 132058 },                                  -- the trainer's
    { name = "I need a ride.", icon = 132057 },                             -- the flight master's
}
local shown = #OPTIONS
local PLACES = { "The bank", "The auction house", "The inn", "The gryphon master", "The guild master", "The mailbox",
                 "The stable master", "The weapon master", "The officers' lounge", "The battlemasters",
                 "A class trainer", "A profession trainer", "The barber", "The tram" }
local guard = false

local function Options()
    local list = {}
    if guard then
        for index, place in ipairs(PLACES) do
            list[index] = { name = place, icon = 132053, orderIndex = index, status = 0, flags = 0, rewards = {},
                            selectOptionWhenOnlyOption = false }
        end
        return list
    end
    for index = 1, shown do
        local option = OPTIONS[index]
        list[index] = { name = option.name, icon = option.icon, orderIndex = index, status = option.status or 0,
                        failureDescription = option.failureDescription, flags = 0, rewards = {},
                        selectOptionWhenOnlyOption = false }
    end
    return list
end

local ACTIVE = { { title = "Report to Goldshire", questID = 54, isComplete = true } }
C_GossipInfo = C_GossipInfo or {}
C_GossipInfo.GetText = function()
    if guard then return "How can I help you, citizen?" end
    return "Welcome to the Lion's Pride, traveller.\n\n<Farley wipes a mug.> Rooms are cheap, the ale is cold."
end
C_GossipInfo.GetOptions = Options
C_GossipInfo.GetAvailableQuests = function() return {} end
C_GossipInfo.GetActiveQuests = function() return guard and {} or ACTIVE end
C_GossipInfo.GetNumAvailableQuests = function() return 0 end
C_GossipInfo.GetNumActiveQuests = function() return guard and 0 or #ACTIVE end
C_GossipInfo.ForceGossip = function() return false end
C_GossipInfo.SelectOptionByIndex = function(index)
    print("Answered: " .. (guard and PLACES[index] or OPTIONS[index].name))
end
C_GossipInfo.SelectActiveQuest = function(id) print("Answered: the quest " .. id) end
C_GossipInfo.SelectAvailableQuest = function(id) print("Answered: the quest " .. id) end
C_GossipInfo.CloseGossip = function()
    GossipFrame:Hide()
    Lab.Fire("GOSSIP_CLOSED")
end
-- A quest of Eagan Peltskinner's at each of its screens, LabQuest("detail"), ("progress") or ("complete"): its words,
-- what it asks for, three rewards to choose from (leather, mail, a sword) and three potions besides, experience and
-- money; the items are the game's own from the data master.
local QUEST = {
    id = 33, giver = "Eagan Peltskinner", title = "Wolves Across the Border",
    text = "Hey there, friend. The wolves have grown bold of late, coming down from the hills to prey on our "
        .. "livestock.\n\n<Eagan points to the tree line.> Bring me their meat and I'll see you rewarded. "
        .. "Mind the big ones near the river.",
    objectives = "Bring 8 Tough Wolf Meat to Eagan Peltskinner in Northshire.",
    progress = "Have you brought the meat? The farmers are counting on us.",
    reward = "Fine work! That will keep the wolves away for a while. Take one of these, as promised.",
    required = { { 750, 8 } }, choices = { { 7280, 1 }, { 4946, 1 }, { 1161, 1 } }, rewards = { { 118, 3 } },
    xp = 450, money = 1500,
}
local stage -- the screen shown: "detail", "progress" or "complete"
local function Things(kind)
    return kind == "choice" and QUEST.choices or kind == "reward" and QUEST.rewards or QUEST.required
end
GetQuestID = function() return QUEST.id end
GetTitleText = function() return QUEST.title end
GetQuestText = function() return QUEST.text end
GetObjectiveText = function() return QUEST.objectives end
GetProgressText = function() return QUEST.progress end
GetRewardText = function() return QUEST.reward end
GetSuggestedGroupSize = function() return 0 end
IsQuestCompletable = function() return true end
GetQuestMoneyToGet = function() return 0 end
GetNumQuestChoices = function() return stage == "progress" and 0 or #QUEST.choices end
GetNumQuestRewards = function() return stage == "progress" and 0 or #QUEST.rewards end
GetNumQuestItems = function() return stage == "progress" and #QUEST.required or 0 end
GetQuestItemInfo = function(kind, index)
    local thing = Things(kind)[index]
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(thing[1])
    return name, icon, thing[2], quality, true, thing[1]
end
GetQuestItemLink = function(kind, index)
    local _, link = C_Item.GetItemInfo(Things(kind)[index][1])
    return link
end
GetRewardMoney = function() return QUEST.money end
GetRewardXP = function() return QUEST.xp end
GetRewardHonor = function() return 0 end
GetRewardTitle = function() return nil end
C_QuestLog = C_QuestLog or {}
C_QuestLog.ShouldShowQuestRewards = function() return true end
local function Finished(what)
    print("Answered: " .. what)
    QuestFrame:Hide()
    Lab.Fire("QUEST_FINISHED")
end
AcceptQuest = function() Finished("accept") end
CompleteQuest = function() Finished("complete") end
GetQuestReward = function(choice) Finished("the reward " .. choice) end
CloseQuest = function() Finished("goodbye") end

-- Space bound while the talk shows (Keys.lua): the lab has no key bindings.
SetOverrideBindingClick = SetOverrideBindingClick or function() end
ClearOverrideBindings = ClearOverrideBindings or function() end
local named = UnitName
UnitName = function(unit, ...)
    if unit == "npc" then return guard and "Stormwind City Guard" or "Innkeeper Farley" end
    if unit == "questnpc" then return QUEST.giver end
    return named(unit, ...)
end

Lab.TOC("src/Core/SaneUI.toc")
LabTalk = Lab.TOC("src/Lore/SaneUI_Lore.toc")

function LabGossip(count)
    guard = false
    shown = math.max(0, math.min(count or #OPTIONS, #OPTIONS))
    GossipFrame:Show()
    Lab.Fire("GOSSIP_SHOW")
end

function LabGuard()
    guard = true
    GossipFrame:Show()
    Lab.Fire("GOSSIP_SHOW")
end

function LabQuest(screen)
    stage = screen or "detail"
    if GossipFrame:IsShown() then C_GossipInfo.CloseGossip() end
    QuestFrame:Show()
    Lab.Fire(stage == "detail" and "QUEST_DETAIL" or stage == "progress" and "QUEST_PROGRESS" or "QUEST_COMPLETE", 0)
end

Lab.OnLogin(function()
    C_Timer.After(0.2, function() LabGossip() end) -- the modules' logins run first
end)
