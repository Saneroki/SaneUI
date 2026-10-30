local _, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Lore - Talk
--  The talk with an NPC as the game tells it (its own events and calls), shown
--  by our parts in place of the game's gossip and quest windows, which
--  Native.lua holds out of sight meanwhile:
--    - gossip (GOSSIP_SHOW) and a quest giver's greeting (QUEST_GREETING): the
--      NPC's words and the answers: quests to hand in, quests offered, the NPC's
--      other options, quests not done yet, Goodbye;
--    - a quest offered (QUEST_DETAIL): its words, objectives and rewards;
--      Accept, Decline;
--    - a quest in progress (QUEST_PROGRESS): what it asks for; Complete Quest
--      (greyed out while not done), Goodbye;
--    - a quest handed in (QUEST_COMPLETE): its rewards, the one chosen; Complete
--      Quest (Choose a reward first, while there is a choice), Goodbye.
--  The words a paragraph at a time, where the game's text breaks (Saneroki,
--  2026-10-30: they wait for you, you go on). A left click in the talk shows the
--  next one and after the last the first again; it never answers (Talk.Cycle). A
--  right click gives the answer that needs no choosing, on whichever paragraph,
--  and nothing where the choice is yours: several answers, a reward to choose, a
--  quest that costs money (Talk.Reply). Space shows the next one and on the last
--  gives that same answer (Talk.Continue).
--  With Words go on by themselves, a paragraph gives way to the next once it is
--  read, at the reading speed set (0, as at first: never); the last one waits.
--  Left to the game's own: a talk while Talks as a scene is off, one begun in a
--  fight, gossip with a window of its own (the game's custom gossip frames), an
--  only option the game takes by itself, an offer the game turns into a popup
--  in its quest tracker (from an item, an area). A fight ends ours (the game
--  says so before it locks): the talk is closed, the interface back at once.
--  Another kind of window opening (a vendor, a trainer) ends it too. Esc ends it.
--
--      Talk.Start()       its events; the game's windows held
--      Talk.Continue()    the next paragraph, or the answer that needs no choosing
--      Talk.Cycle()       the next paragraph, after the last the first
--      Talk.Reply()       the answer that needs no choosing, on any paragraph
--      Talk.Click(button, entry)  a click in the talk; entry: the reward clicked
--      Talk.Answer(a)     an answer given
--      Talk.Choose(index, handIn)  a reward chosen (and handed in with it)
--      Talk.Switched(), Talk.Quieted(), Talk.Redraw()  a setting changed
--      Talk.GiveBack()    ours hidden, no talk of ours
-------------------------------------------------------------------------------
local Core = SaneUI.Core
local Talk = {}
ns.Talk = Talk

Talk.WAIT = 0.3        -- a talk ended by the game: ours goes after so long, unless the next one comes (a
                       -- gossip turning into a quest, a quest handed in and the NPC's gossip again)
Talk.READ_MIN = 2.5    -- seconds at least a paragraph is shown before it goes on by itself
Talk.READ_PAUSE = 0.8  -- and so much longer than reading it takes
Talk.SETTLE = 0.4      -- seconds a talk new or just answered takes no right click: the second click of a double
                       -- click (on the NPC, on the answer before) gives nothing that was not read

local FAMILY = { gossip = "gossip", greeting = "quest", detail = "quest", progress = "quest", complete = "quest" }
local INTERACTIONS = { [3] = true, [4] = true } -- the game's interaction types of a talk (gossip, quest giver)

local talk         -- the talk shown, nil while none
local count = 0    -- counts each talk shown and ended: a timer of an older one knows it is late

local function Gossip() return rawget(_G, "C_GossipInfo") end

local function Number(fn, ...)
    local value = Core.Ask(rawget(_G, fn), ...)
    return type(value) == "number" and value or 0
end

-- The NPC's words in paragraphs, where the game's text breaks.
function Talk.Paragraphs(text)
    local list = {}
    if type(text) == "string" then
        for line in text:gmatch("[^\r\n]+") do
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then list[#list + 1] = line end
        end
    end
    if #list == 0 then list[1] = "" end
    return list
end

local function Name(unit)
    return Core.Ask(UnitName, unit) or ""
end

-- The game's talk of that family ends (its windows then close by its own code).
local function Close(family)
    if family == "gossip" then
        local gossip = Gossip()
        if gossip then gossip.CloseGossip() end
    else
        CloseQuest()
    end
end

local function Leave()
    if not talk then return end
    talk.leaving = true
    Core.Sound("IG_QUEST_CANCEL")
    Close(FAMILY[talk.kind])
end

-------------------------------------------------------------------------------
--  The talks
-------------------------------------------------------------------------------
-- A quest in a list of answers, by what the game tells of it.
local function QuestAnswer(title, act, info)
    return { text = title, quest = true, act = act, offer = info.offer, complete = info.complete,
             trivial = info.trivial, repeatable = info.repeatable, legend = info.legend }
end

local function Append(list, more)
    for _, entry in ipairs(more) do list[#list + 1] = entry end
end

-- The answers in our order: to hand in, offered, the NPC's options, not done yet, Goodbye.
local function Ordered(done, offered, options, open)
    local list = {}
    Append(list, done)
    Append(list, offered)
    Append(list, options)
    Append(list, open)
    list[#list + 1] = { text = ns.TEXT.goodbye, goodbye = true, act = Leave }
    return list
end

local function OptionText(option)
    local flags = Enum and Enum.GossipOptionRecFlags
    local prepend = rawget(_G, "QUEST_PREPEND")
    local form = rawget(_G, "GOSSIP_OPTION_PREPEND")
    if flags and flags.QuestLabelPrepend and type(option.flags) == "number" and prepend and form
        and bit.band(option.flags, flags.QuestLabelPrepend) ~= 0 then
        return form:format(prepend, option.name or "")
    end
    return option.name or ""
end

local function GossipTalk(options)
    local gossip = Gossip()
    local done, offered, open, choices = {}, {}, {}, {}
    for _, quest in ipairs(Core.Ask(gossip.GetActiveQuests) or {}) do
        local id = quest.questID
        local answer = QuestAnswer(quest.title, function() gossip.SelectActiveQuest(id) end, {
            complete = quest.isComplete, trivial = quest.isTrivial, legend = quest.isLegendary,
            repeatable = quest.repeatable or (quest.frequency or 0) > 0 })
        if quest.isComplete then done[#done + 1] = answer else open[#open + 1] = answer end
    end
    for _, quest in ipairs(Core.Ask(gossip.GetAvailableQuests) or {}) do
        local id = quest.questID
        offered[#offered + 1] = QuestAnswer(quest.title, function() gossip.SelectAvailableQuest(id) end, {
            offer = true, trivial = quest.isTrivial, legend = quest.isLegendary,
            repeatable = quest.repeatable or (quest.frequency or 0) > 0 })
    end
    table.sort(options, function(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end)
    for _, option in ipairs(options) do
        local index = option.orderIndex
        choices[#choices + 1] = { text = OptionText(option), icon = option.overrideIconID or option.icon,
                                  act = function() gossip.SelectOptionByIndex(index) end }
    end
    return { kind = "gossip", unit = "npc", name = Name("npc"), paragraphs = Talk.Paragraphs(Core.Ask(gossip.GetText)),
             answers = Ordered(done, offered, choices, open) }
end

local function GreetingTalk()
    local done, offered, open = {}, {}, {}
    for index = 1, Number("GetNumActiveQuests") do
        local title, complete = Core.Ask(GetActiveTitle, index)
        local answer = QuestAnswer(title, function() SelectActiveQuest(index) end,
                                   { complete = complete, trivial = Core.Ask(rawget(_G, "IsActiveQuestTrivial"), index) })
        if complete then done[#done + 1] = answer else open[#open + 1] = answer end
    end
    for index = 1, Number("GetNumAvailableQuests") do
        local ok, trivial, frequency, repeatable, legend = pcall(GetAvailableQuestInfo, index)
        if not ok then trivial, frequency, repeatable, legend = nil, nil, nil, nil end
        offered[#offered + 1] = QuestAnswer(Core.Ask(GetAvailableTitle, index), function() SelectAvailableQuest(index) end, {
            offer = true, trivial = trivial, legend = legend, repeatable = repeatable or (frequency or 0) > 0 })
    end
    return { kind = "greeting", unit = "questnpc", name = Name("questnpc"),
             paragraphs = Talk.Paragraphs(Core.Ask(GetGreetingText)), answers = Ordered(done, offered, {}, open) }
end

local function QuestTalk(kind, text)
    return { kind = kind, unit = "questnpc", name = Name("questnpc"), title = Core.Ask(GetTitleText),
             paragraphs = Talk.Paragraphs(Core.Ask(text)), quest = {} }
end

-- Accepted as the game's own Accept button does: a quest of the PvP asks first, an offer the game made
-- by itself is acknowledged.
local function Accept()
    if Core.Ask(rawget(_G, "QuestFlagsPVP")) then
        StaticPopup_Show("CONFIRM_ACCEPT_PVP_QUEST")
        return
    end
    local frame = rawget(_G, "QuestFrame")
    local acknowledge = rawget(_G, "AcknowledgeAutoAcceptQuest")
    if frame and frame.autoQuest and acknowledge then acknowledge() else AcceptQuest() end
end

local function DetailTalk()
    local talked = QuestTalk("detail", GetQuestText)
    local log = rawget(_G, "C_QuestLog")
    local shown = log and Core.Ask(log.ShouldShowQuestRewards, Core.Ask(GetQuestID))
    talked.quest.objectives = Core.Ask(GetObjectiveText)
    talked.quest.group = Number("GetSuggestedGroupSize")
    talked.quest.rewards = ns.Rewards.Read(shown ~= false)
    talked.answers = {
        { text = ns.TEXT.accept, default = true, act = Accept },
        { text = ns.TEXT.decline, goodbye = true, act = Leave },
    }
    return talked
end

local function ProgressTalk()
    local talked = QuestTalk("progress", GetProgressText)
    talked.quest.required = ns.Rewards.Required()
    local done = Core.Ask(IsQuestCompletable) == true
    talked.answers = {
        done and { text = ns.TEXT.complete, default = true, act = function()
            Core.Sound("IG_QUEST_LIST_OPEN")
            CompleteQuest()
        end } or { text = ns.TEXT.notDone, disabled = true },
        { text = ns.TEXT.goodbye, goodbye = true, default = not done, act = Leave },
    }
    return talked
end

-- The answer that hands the quest in, as the choice stands now: a quest that costs money says so and is
-- handed in only by its answer (as the game asks first).
local function HandIn(talked)
    local choices = Number("GetNumQuestChoices")
    if choices > 1 and not talked.choice then return { text = ns.TEXT.choose, disabled = true } end
    local money = Number("GetQuestMoneyToGet")
    local choice = talked.choice or (choices == 1 and 1) or 0
    return { text = money > 0 and ns.TEXT.pay:format(ns.Look.Coins(money)) or ns.TEXT.complete, handIn = true,
             default = money == 0, act = function() GetQuestReward(choice) end }
end

local function CompleteAnswers(talked)
    talked.answers = { HandIn(talked), { text = ns.TEXT.goodbye, goodbye = true, act = Leave } }
end

local function CompleteTalk()
    local talked = QuestTalk("complete", GetRewardText)
    talked.quest.rewards = ns.Rewards.Read(true)
    CompleteAnswers(talked)
    return talked
end

-------------------------------------------------------------------------------
--  Showing, going on, ending
-------------------------------------------------------------------------------
local function Draw()
    ns.Box.Draw(talk)
    ns.Quest.Draw(talk)
    ns.Answers.Draw(talk)
end

local function Onward()
    local speed = ns.options.speed or 0
    if not talk or not ns.options.onward or speed <= 0 or talk.at >= #talk.paragraphs then return end
    local words = 0
    for _ in talk.paragraphs[talk.at]:gmatch("%S+") do words = words + 1 end
    local seconds = math.max(Talk.READ_MIN, words / speed * 60 + Talk.READ_PAUSE)
    local mine, at = count, talk.at
    C_Timer.After(seconds, ns.Guard(function()
        if talk and mine == count and talk.at == at then Talk.Next() end
    end))
end

local function EscClose() Leave() end

local function Show(talked)
    count = count + 1
    talked.at = 1
    talked.ready = GetTime() + Talk.SETTLE
    talk = talked
    ns.Look.Show()
    ns.Quiet.On()
    ns.Keys.On()
    Core.Escape(Talk, EscClose)
    Draw()
    Onward()
end

-- Ours goes: faded, or at once.
local function Gone(now)
    if now then ns.Look.Gone() else ns.Look.Hide() end
    ns.Quiet.Off(now)
end

-- The game ended the talk of that family (nil: whichever). Left by the player, ours goes at once; else
-- after a moment, unless the next talk came meanwhile.
local function Ended(family)
    if not talk or (family and FAMILY[talk.kind] ~= family) then return end
    local left = talk.leaving
    talk = nil
    count = count + 1
    local mine = count
    ns.Keys.Off()
    Core.Escape(Talk, nil)
    if left then return Gone(false) end
    C_Timer.After(Talk.WAIT, ns.Guard(function() if mine == count then Gone(false) end end))
end

function Talk.Next()
    if not talk or talk.at >= #talk.paragraphs then return end
    talk.at = talk.at + 1
    ns.Box.Words(talk)
    Onward()
end

function Talk.Cycle()
    if not talk or #talk.paragraphs < 2 then return end
    talk.at = talk.at % #talk.paragraphs + 1
    ns.Box.Words(talk)
    Onward()
end

-- What Continue gives on the last paragraph, and a right click on any: the answer marked so, or in a gossip and a
-- greeting the one answer there is (Goodbye when there is none); nothing where there is a choice to make.
local function Default()
    local only, given, goodbye = nil, 0, nil
    for _, answer in ipairs(talk.answers) do
        if answer.default and not answer.disabled then return answer end
        if answer.goodbye then goodbye = answer
        elseif not answer.disabled then only, given = answer, given + 1 end
    end
    if talk.kind ~= "gossip" and talk.kind ~= "greeting" then return nil end
    if given == 0 then return goodbye end
    if given == 1 then return only end
    return nil
end

function Talk.Continue()
    if not talk then return end
    if talk.at < #talk.paragraphs then return Talk.Next() end
    local answer = Default()
    if answer then Talk.Answer(answer) end
end

function Talk.Reply()
    if not talk or GetTime() < talk.ready then return end
    talk.ready = GetTime() + Talk.SETTLE
    local answer = Default()
    if answer then Talk.Answer(answer) end
end

-- On a reward to choose from at the hand-in the left button chooses it and the right gives nothing: a right click
-- never takes a reward it stands on, not even the one chosen before.
function Talk.Click(button, entry)
    if talk and talk.kind == "complete" and entry and entry.kind == "choice" then
        if button == "LeftButton" then Talk.Choose(entry.index) end
    elseif button == "RightButton" then
        Talk.Reply()
    else
        Talk.Cycle()
    end
end

function Talk.Answer(answer)
    if not talk or not answer or answer.disabled or not answer.act then return end
    if FAMILY[talk.kind] == "gossip" and not answer.goodbye then Core.Sound("IG_QUEST_LIST_SELECT") end
    answer.act()
end

function Talk.Choose(index, handIn)
    if not talk or talk.kind ~= "complete" then return end
    talk.choice = index
    CompleteAnswers(talk)
    ns.Quest.Draw(talk)
    ns.Answers.Draw(talk)
    if handIn then Talk.Answer(talk.answers[1]) end
end

-------------------------------------------------------------------------------
--  The game's events
-------------------------------------------------------------------------------
-- Ours shows the talks of that family now: on, out of a fight, the game's window held.
local function Ours(family)
    return ns.options.talk and not ns.off and not InCombatLockdown() and ns.Native.Held(family)
end

-- After the game's own handler: its window for a talk ours does not show is given back into sight.
local function Check(family)
    ns.Native.Check(family, talk ~= nil and FAMILY[talk.kind] == family)
end
local checkGossip = Core.Later(function() Check("gossip") end)
local checkQuest = Core.Later(function() Check("quest") end)
local closed = Core.Later(function() ns.Native.Closed() end)

-- The game told more of an item: the quest's rewards and what it asks for read anew.
local function Refresh()
    if not talk or not talk.quest then return end
    local quest = talk.quest
    if quest.rewards then quest.rewards = ns.Rewards.Read(quest.rewards.shown) end
    if quest.required then quest.required = ns.Rewards.Required() end
    if talk.kind == "complete" then CompleteAnswers(talk) end
    ns.Quest.Draw(talk)
    ns.Answers.Draw(talk)
end
local refresh = Core.Later(Refresh, 0.1)

local function GossipShow(kit)
    checkGossip()
    if not Ours("gossip") then return end
    local gossip = Gossip()
    local manager = rawget(_G, "CustomGossipFrameManager")
    if kit and manager and manager.GetHandler and manager:GetHandler(kit) then return end
    local options = Core.Ask(gossip.GetOptions) or {}
    -- The game takes an only option by itself, with no window.
    if (Core.Ask(gossip.GetNumAvailableQuests) or 0) == 0 and (Core.Ask(gossip.GetNumActiveQuests) or 0) == 0
        and #options == 1 and not Core.Ask(gossip.ForceGossip) and options[1].selectOptionWhenOnlyOption then
        return
    end
    Show(GossipTalk(options))
    Core.Sound("IG_QUEST_LIST_OPEN")
end

local function QuestShow(make, ...)
    checkQuest()
    if not Ours("quest") then return end
    Show(make(...))
end

local function Detail(item)
    checkQuest()
    if not Ours("quest") then return end
    -- What the game turns into a popup in its quest tracker, or shows elsewhere.
    if Core.Ask(rawget(_G, "QuestIsFromAdventureMap")) then return end
    if item ~= nil and item ~= 0 then return end
    if Core.Ask(rawget(_G, "QuestGetAutoAccept")) and Core.Ask(rawget(_G, "QuestIsFromAreaTrigger")) then return end
    Show(DetailTalk())
end

local function Fight()
    if talk then
        talk.leaving = true
        Close(FAMILY[talk.kind])
        Ended()
    end
    Gone(true)
    ns.Native.Release()
end

function Talk.Start()
    if ns.options.talk and not InCombatLockdown() then ns.Native.Hold() end
    ns.On("GOSSIP_SHOW", GossipShow)
    ns.On("GOSSIP_CLOSED", function()
        Ended("gossip")
        closed()
    end)
    ns.On("QUEST_GREETING", function() QuestShow(GreetingTalk) end)
    ns.On("QUEST_DETAIL", Detail)
    ns.On("QUEST_PROGRESS", function() QuestShow(ProgressTalk) end)
    ns.On("QUEST_COMPLETE", function() QuestShow(CompleteTalk) end)
    ns.On("QUEST_FINISHED", function()
        Ended("quest")
        closed()
    end)
    ns.On("QUEST_ITEM_UPDATE", function() if talk and talk.quest then refresh() end end)
    ns.On("GET_ITEM_INFO_RECEIVED", function() if talk and talk.quest then refresh() end end)
    ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(kind)
        if talk and not INTERACTIONS[kind] then
            talk.leaving = true
            Ended()
        end
    end)
    ns.On("PLAYER_REGEN_DISABLED", Fight)
    ns.On("PLAYER_REGEN_ENABLED", function()
        if ns.options.talk then ns.Native.Hold() end
    end)
end

-------------------------------------------------------------------------------
--  The settings
-------------------------------------------------------------------------------
function Talk.Switched()
    if ns.options.talk then
        if not InCombatLockdown() then ns.Native.Hold() end
        return
    end
    if talk then
        talk.leaving = true
        Close(FAMILY[talk.kind])
        Ended()
    end
    ns.Native.Release()
end

function Talk.Quieted()
    if not talk then return end
    if ns.options.quiet then ns.Quiet.On() else ns.Quiet.Off() end
end

function Talk.Redraw()
    ns.Look.Update()
    if talk then Draw() end
end

function Talk.GiveBack()
    talk = nil
    count = count + 1
    Core.Escape(Talk, nil)
    ns.Look.Gone()
end
