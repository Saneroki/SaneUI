-- Runs the Lore module against the stand-in client (wowstub.lua): the game's gossip and quest windows held out of
-- sight and given back (a fight, the switch, a talk ours leaves to the game, standing down), a talk as the game tells
-- it (gossip turning into a quest, a greeting, an offer, progress, a hand-in) with its paragraphs and answers in our
-- order, Continue and what it does on the last paragraph, the words going on by themselves, the rewards read for you
-- (what each item is, whether you can use it, what it sells for, what it changes against what you wear, an empty
-- slot, a choice to make, a quest that costs money), the clicks (the left going round the words and never answering,
-- the right giving what needs no choosing and never a reward), the words waiting at reading speed 0, Speed Leveling's
-- quest givers (its own file) doing their quests beside the talk, the interface faded out and back with the game's
-- questions, error lines and the rewards' tooltips kept in sight, Space bound only while a talk shows, and the
-- settings. The look and the face can only be judged in the game.
-- Usage, from the project folder:  lua5.1 dev/tests/lore.lua

local root = arg[0]:match("^(.*)/dev/tests/") or "."
package.path = root .. "/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)

local passed = 0
local function check(condition, what)
    if not condition then error("FAILED: " .. what, 2) end
    passed = passed + 1
end

-------------------------------------------------------------------------------
--  What the module needs of the client
-------------------------------------------------------------------------------
local methods = W.methods
function methods:SetIgnoreParentAlpha(on) self._ignoreAlpha = on end
function methods:IsIgnoringParentAlpha() return self._ignoreAlpha == true end
function methods:GetFrameStrata() return self._strata or "MEDIUM" end
function methods:SetFrameStrata(strata) self._strata = strata end
function methods:SetUnit(unit) self._unit = unit end
function methods:SetAnimation(animation) self._animation = animation end
function methods:RegisterForClicks(...) self._clicks = table.concat({ ... }, " ") end

bit = { band = function(a, b) return (a % (2 * b) >= b) and b or 0 end }
ChatTypeInfo = { MONSTER_EMOTE = { r = 1, g = 0.5, b = 0.25 } }
GOODBYE, ACCEPT, DECLINE, COMPLETE_QUEST = "Goodbye", "Accept", "Decline", "Complete Quest"
INVTYPE_CHEST, INVTYPE_FINGER, INVTYPE_WEAPONMAINHAND, INVTYPE_WEAPON = "Chest", "Finger", "Main Hand", "One-Hand"
INVTYPE_RANGED = "Ranged"
INVSLOT_CHEST, INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_MAINHAND = 5, 11, 12, 16
ITEM_MOD_STAMINA_SHORT, ITEM_MOD_AGILITY_SHORT, RESISTANCE0_NAME = "Stamina", "Agility", "Armor"
GetCoinTextureString = function(copper) return copper .. "c" end

GossipFrame = W.NewWidget("Frame", "GossipFrame", UIParent)
QuestFrame = W.NewWidget("Frame", "QuestFrame", UIParent)
StaticPopup1 = W.NewWidget("Frame", "StaticPopup1", UIParent)
GossipFrame:Hide()   -- the game's windows are closed until a talk opens them
QuestFrame:Hide()
StaticPopup1:Hide()
UIParent:SetAlpha(1)

-- The talk the game holds now, and what was asked of it.
local said = {}
local function Said(what) said[#said + 1] = what end
local gossip = { text = "", options = {}, available = {}, active = {} }
C_GossipInfo = {
    GetText = function() return gossip.text end,
    GetOptions = function()
        local copy = {}
        for index, option in ipairs(gossip.options) do copy[index] = option end
        return copy
    end,
    GetAvailableQuests = function() return gossip.available end,
    GetActiveQuests = function() return gossip.active end,
    GetNumAvailableQuests = function() return #gossip.available end,
    GetNumActiveQuests = function() return #gossip.active end,
    ForceGossip = function() return false end,
    SelectOptionByIndex = function(index) Said("option " .. index) end,
    SelectAvailableQuest = function(id) Said("offered " .. id) end,
    SelectActiveQuest = function(id) Said("active " .. id) end,
    CloseGossip = function() Said("close gossip") end,
}
local quest = { title = "", text = "", objectives = "", progress = "", reward = "", completable = true, money = 0,
                choices = {}, rewards = {}, required = {}, xp = 0, cash = 0 }
GetQuestID = function() return 77 end
GetTitleText = function() return quest.title end
GetQuestText = function() return quest.text end
GetObjectiveText = function() return quest.objectives end
GetProgressText = function() return quest.progress end
GetRewardText = function() return quest.reward end
GetGreetingText = function() return quest.text end
GetSuggestedGroupSize = function() return 0 end
IsQuestCompletable = function() return quest.completable end
GetQuestMoneyToGet = function() return quest.money end
GetNumQuestChoices = function() return #quest.choices end
GetNumQuestRewards = function() return #quest.rewards end
GetNumQuestItems = function() return #quest.required end
GetRewardMoney = function() return quest.cash end
GetRewardXP = function() return quest.xp end
GetRewardHonor = function() return 0 end
GetRewardTitle = function() return nil end
local function Kind(kind)
    return kind == "choice" and quest.choices or kind == "reward" and quest.rewards or quest.required
end
GetQuestItemInfo = function(kind, index)
    local item = Kind(kind)[index]
    return item.name, item.icon, item.count, item.quality, item.usable, item.id
end
GetQuestItemLink = function(kind, index) return Kind(kind)[index].link end
GetNumActiveQuests = function() return 0 end
GetNumAvailableQuests = function() return 1 end
GetAvailableTitle = function() return "The Lost Pages" end
GetAvailableQuestInfo = function() return false, 0, false, false, 90 end
SelectAvailableQuest = function(index) Said("greeting offered " .. index) end
AcceptQuest = function() Said("accept") end
CompleteQuest = function() Said("complete") end
GetQuestReward = function(choice) Said("reward " .. choice) end
CloseQuest = function() Said("close quest") end
StaticPopup_Show = function(which) Said("popup " .. which) end
UnitExists = function() return true end
UnitGUID = function() return "Creature-0-1-2-3-4-5" end
local names = { npc = "Marshal Dughan", questnpc = "Marshal Dughan" }
UnitName = function(unit) return names[unit] or "Tester" end

-- The items the game knows: what C_Item.GetItemInfo answers, and what you wear.
local items = {
    ["item:1"] = { "Ranger's Vest", 2, 20, "Armor", "Leather", "INVTYPE_CHEST", 1450, 4, 2 },
    ["item:2"] = { "Band of Thorns", 2, 18, "Armor", "Miscellaneous", "INVTYPE_FINGER", 900, 4, 0 },
    ["item:3"] = { "Militia Shortsword", 2, 17, "Weapon", "One-Handed Swords", "INVTYPE_WEAPONMAINHAND", 700, 2, 7 },
    ["item:4"] = { "Plate Girdle", 2, 19, "Armor", "Plate", "INVTYPE_CHEST", 1200, 4, 4 },
    ["item:5"] = { "Healing Potion", 1, 5, "Consumable", "Potion", "", 25, 0, 1 },
    ["item:6"] = { "Old Bow", 1, 12, "Weapon", "Bows", "INVTYPE_RANGED", 300, 2, 2 },
    ["item:worn chest"] = { "Worn Vest", 1, 16, "Armor", "Leather", "INVTYPE_CHEST", 100, 4, 2 },
    ["item:worn ring"] = { "Copper Ring", 1, 10, "Armor", "Miscellaneous", "INVTYPE_FINGER", 50, 4, 0 },
}
local worn = { [5] = "item:worn chest", [11] = "item:worn ring" }
C_Item.GetItemInfo = function(link)
    local item = items[link]
    if not item then return nil end
    local name, quality, level, kind, subKind, slot, price, class, subclass = unpack(item)
    return name, link, quality, level, 1, kind, subKind, 1, slot, 0, price, class, subclass
end
C_Item.GetDetailedItemLevelInfo = function(link) return items[link] and items[link][3] end
C_Item.GetItemStatDelta = function(new, old)
    Said("delta " .. new .. " " .. old)
    return { ITEM_MOD_STAMINA_SHORT = 3, ITEM_MOD_AGILITY_SHORT = -2, RESISTANCE0_NAME = 12, ITEM_MOD_NOTHING = 0 }
end
GetInventoryItemLink = function(_, slot) return worn[slot] end
local rangedSlot = 18
GetInventorySlotInfo = function(name)
    if name == "RangedSlot" and rangedSlot then return rangedSlot end
    error("no such slot")
end

-- Every override binding set and cleared.
local bindings = {}
SetOverrideBindingClick = function(owner, _, key, name) bindings[key] = name end
ClearOverrideBindings = function() bindings = {} end

-- The frames' OnUpdate scripts run as time passes (a fade).
local function Frames(seconds)
    for _ = 1, 20 do
        W.clock = W.clock + seconds / 20
        for _, frame in ipairs(W.frames) do
            local update = frame._scripts and frame._scripts.OnUpdate
            if update then update(frame, seconds / 20) end
        end
    end
end

-------------------------------------------------------------------------------
--  The module
-------------------------------------------------------------------------------
W.LoadCore(root)
W.Fire("ADDON_LOADED", "SaneUI")
local ns = W.LoadAddon(root, "Lore", "SaneUI_Lore")
W.Fire("ADDON_LOADED", "SaneUI_Lore")
W.Fire("PLAYER_LOGIN")
check(ns.options.talk == true and ns.options.quiet == true and ns.options.space == true, "the switches are on at first")
check(ns.options.speed == 0 and ns.options.onward == true, "at first the reading speed is 0, the switch under it stays on")
check(SaneUI.Core.Described(ns.name, "speed").min == 0, "and 0 is on its slider")

-- The game's windows are held out of sight, their layer noted.
local holder = GossipFrame:GetParent()
check(holder ~= UIParent and holder == QuestFrame:GetParent(), "the game's gossip and quest windows are held")
check(not holder:IsShown(), "in a hidden frame of ours")
check(ns.Native.Held("gossip") and ns.Native.Held("quest"), "both are held")

-- Paragraphs where the game's text breaks; empty lines dropped.
local parts = ns.Talk.Paragraphs("First words.\n\n  Second words.  \r\nThird.")
check(#parts == 3 and parts[2] == "Second words.", "paragraphs where the text breaks")
check(#ns.Talk.Paragraphs("") == 1, "a talk without words has one empty paragraph")

-------------------------------------------------------------------------------
--  A gossip
-------------------------------------------------------------------------------
gossip.text = "Hello there.\n\n<Dughan nods.> The roads are dangerous."
gossip.options = { { name = "Train me.", orderIndex = 2, icon = 132058 }, { name = "Tell me more.", orderIndex = 1, icon = 132053 } }
gossip.available = { { title = "Wolves Across the Border", questID = 33, isTrivial = false, frequency = 0 } }
gossip.active = { { title = "A Threat Within", questID = 31, isComplete = true },
                  { title = "Kobold Camp Cleanup", questID = 32, isComplete = false } }
GossipFrame:Show()
W.Fire("GOSSIP_SHOW")
local talkRoot = ns.Look.Root()
check(talkRoot:IsShown() and talkRoot._ignoreAlpha == true, "our talk shows, in sight over the interface")
check(ns.Box.Frame():IsShown(), "the box shows")
-- The answers' lines in the order they stand: each hangs under the one before it.
local function Order()
    local lines = {}
    for _, frame in ipairs(W.frames) do
        if frame.answer and frame:IsShown() then lines[#lines + 1] = frame end
    end
    local below = {}
    for _, line in ipairs(lines) do
        local _, above = line:GetPoint(1)
        below[above] = line
    end
    local first
    for _, line in ipairs(lines) do
        local _, above = line:GetPoint(1)
        if not above.answer then first = line end
    end
    local order = {}
    while first do
        order[#order + 1] = first.text._text
        first = below[first]
    end
    return order
end
local order = Order()
check(table.concat(order, "|") == "A Threat Within|Wolves Across the Border|Tell me more.|Train me.|Kobold Camp Cleanup|Goodbye",
      "answers: to hand in, offered, the options in the game's order, not done yet, Goodbye (" .. table.concat(order, "|") .. ")")

-- The words: the first paragraph, the face talking, which of how many.
local words
for _, frame in ipairs(W.frames) do
    if frame._text == "Hello there." then words = frame end
end
check(words ~= nil, "the first paragraph shows")
check(bindings.SPACE == ns.Keys.BUTTON, "Space goes on while the talk shows")

-- The interface fades out; the game's questions and error lines stay in sight.
Frames(1)
check(UIParent:GetAlpha() == 0, "the interface faded out")
check(StaticPopup1._ignoreAlpha == true and UIErrorsFrame._ignoreAlpha == true, "the game's questions and errors stay in sight")
check(GameTooltip._ignoreAlpha ~= true, "the tooltip is not kept while nothing of the talk shows one")

-- Continue: the next paragraph; on the last, with a choice to make, nothing.
ns.Talk.Continue()
check(words._text:find("|cff") and words._text:find("The roads are dangerous."), "the next paragraph, its action in the emote colour")
said = {}
ns.Talk.Continue()
check(#said == 0, "on the last paragraph with several answers Continue waits for a click")

-- A left click on the words: the next paragraph, after the last the first again.
local box = ns.Box.Frame()
local function Click(frame, button) frame._scripts.OnClick(frame, button) end
Click(box, "LeftButton")
check(words._text == "Hello there.", "a left click after the last paragraph shows the first again")
Click(box, "LeftButton")
check(words._text:find("The roads are dangerous."), "and then the next one")
check(#said == 0, "a left click answers nothing")

-- A click on the offered quest selects it with the game's own call.
for _, frame in ipairs(W.frames) do
    if frame.answer and frame.answer.text == "Wolves Across the Border" then frame._scripts.OnClick(frame) end
end
check(said[1] == "offered 33", "an offered quest is selected by its ID")

-------------------------------------------------------------------------------
--  It turns into a quest offered
-------------------------------------------------------------------------------
GossipFrame:Hide()
W.Fire("GOSSIP_CLOSED", true)
quest.title, quest.text, quest.objectives = "Wolves Across the Border", "The wolves grow bold.", "Kill 8 wolves."
quest.choices = {
    { name = "Ranger's Vest", icon = 1, count = 1, quality = 2, usable = true, link = "item:1" },
    { name = "Plate Girdle", icon = 4, count = 1, quality = 2, usable = false, link = "item:4" },
    { name = "Band of Thorns", icon = 2, count = 1, quality = 2, usable = true, link = "item:2" },
}
quest.rewards = { { name = "Healing Potion", icon = 5, count = 3, quality = 1, usable = true, link = "item:5" } }
quest.xp, quest.cash = 450, 1500
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 0)
W.Wait(1)
check(talkRoot:IsShown() and UIParent:GetAlpha() == 0, "a gossip turning into a quest keeps the talk and the faded interface")
local rewards = ns.Rewards.Read(true)
local vest, plate, ring = rewards.choices[1], rewards.choices[2], rewards.choices[3]
check(vest.what == "Leather \194\183 Chest", "armour says its kind and slot (" .. tostring(vest.what) .. ")")
check(ring.what == "Finger", "a ring says its slot alone")
check(rewards.items[1].what == "Potion", "anything else says its kind")
check(vest.value == 1450 and rewards.items[1].value == 75, "what a vendor pays, for all of them")
check(plate.cantUse == true and plate.changes == nil, "what you cannot use says so, with nothing to compare")
check(vest.level == 20 and vest.worn == 16, "its item level and the one worn")
check(vest.changes[1].key == "RESISTANCE0_NAME" and vest.changes[2].name == "Stamina" and vest.changes[3].amount == -2
      and #vest.changes == 3, "the stats that change: armour first, then by how much, no zeros")
check(ring.empty == true, "an empty slot (the second ring) says so")
check(rewards.xp == 450 and rewards.money == 1500, "experience and money")

-- The bow: the ranged slot where the game has one, else the main hand.
quest.choices[4] = { name = "Old Bow", icon = 6, count = 1, quality = 1, usable = true, link = "item:6" }
said = {}
local bow = ns.Rewards.Read(true).choices[4]
check(bow.empty == true, "a bow against the ranged slot, empty here")
check(bow.what == "Bows", "a weapon says its kind")
table.remove(quest.choices, 4)

-- A tooltip of a reward shows over the faded interface, and only while the mouse is on it.
local row
for _, frame in ipairs(W.frames) do
    if frame.entry and frame.entry.name == "Ranger's Vest" and frame:IsShown() then row = frame end
end
check(row ~= nil, "the rewards are drawn under the words")
check(row.what._text == "Leather \194\183 Chest" and row.value._text == "1450c", "a reward's line says what it is and what it sells for")
check(row.change._text:find("iLvl 20") and row.change._text:find("%(%+4%)") and row.change._text:find("%+3 Stamina")
      and row.change._text:find("%-2 Agility"), "and what it changes (" .. tostring(row.change._text) .. ")")
row._scripts.OnEnter(row)
check(GameTooltip._ignoreAlpha == true and GameTooltip._owner == row, "its tooltip is in sight over the faded interface")
row._scripts.OnLeave(row)
check(GameTooltip._ignoreAlpha == false, "and not once the mouse left it")

-- Continue on the last paragraph accepts.
said = {}
ns.Talk.Continue()
check(said[1] == "accept", "Continue accepts the quest offered")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
check(talkRoot:IsShown(), "the talk waits a moment for the next one")
W.Wait(1)
Frames(1)
check(not talkRoot:IsShown(), "then it is gone")
check(UIParent:GetAlpha() == 1, "the interface is back")
check(StaticPopup1._ignoreAlpha == false, "the questions follow their parent again")
check(bindings.SPACE == nil, "Space jumps again")
W.Wait(1)
check(QuestFrame:GetParent() == holder and GossipFrame:GetParent() == holder, "the game's windows are held again")

-------------------------------------------------------------------------------
--  A greeting, and its paragraphs going on by themselves
-------------------------------------------------------------------------------
quest.text = "Welcome, traveller.\n\nThe library needs help."
local after, endless = C_Timer.After, false
C_Timer.After = function(seconds, fn)
    endless = endless or not (seconds < math.huge)
    return after(seconds, fn)
end
QuestFrame:Show()
W.Fire("QUEST_GREETING")
C_Timer.After = after
check(not endless, "at reading speed 0 no timer of endless length is asked of the game")
local shown
for _, frame in ipairs(W.frames) do
    if frame._text == "Welcome, traveller." then shown = frame end
end
check(shown ~= nil, "a greeting's words")
W.Wait(600)
check(shown._text == "Welcome, traveller.", "at reading speed 0 a paragraph never goes on by itself")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
Frames(1)
check(SaneUI.Core.Set(ns.name, "speed", 230) == 230, "the reading speed raised")
QuestFrame:Show()
W.Fire("QUEST_GREETING")
check(shown._text == "Welcome, traveller.", "the first paragraph again")
W.Wait(5)
check(shown._text == "The library needs help.", "at a raised speed a paragraph goes on by itself once read")
check(SaneUI.Core.Set(ns.name, "speed", 0) == 0, "and back to 0")
said = {}
ns.Talk.Continue()
check(said[1] == "greeting offered 1", "Continue takes the one answer there is")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
Frames(1)

-------------------------------------------------------------------------------
--  A hand-in with a choice
-------------------------------------------------------------------------------
quest.reward = "Well done."
QuestFrame:Show()
W.Fire("QUEST_COMPLETE")
said = {}
ns.Talk.Continue()
check(#said == 0, "with a choice to make, Continue hands nothing in")
local first
for _, frame in ipairs(W.frames) do
    if frame.answer and frame:IsShown() and frame.answer.disabled then first = frame end
end
check(first and first.text._text == ns.TEXT.choose, "the hand-in asks for a choice first")
ns.Talk.Choose(3)
ns.Talk.Continue()
check(said[1] == "reward 3", "once chosen, Continue hands it in with that reward")
-- A double click on a choice hands it in at once.
said = {}
for _, frame in ipairs(W.frames) do
    if frame.entry and frame.entry.name == "Ranger's Vest" and frame:IsShown() then
        frame._scripts.OnDoubleClick(frame, "LeftButton")
    end
end
check(said[1] == "reward 1", "a double click hands in with that reward")

-- A quest that costs money is handed in only by its answer, which says the price.
quest.money = 2500
ns.Talk.Choose(1)
said = {}
ns.Talk.Continue()
check(#said == 0, "Continue does not pay for a quest")
local pay
for _, frame in ipairs(W.frames) do
    if frame.answer and frame:IsShown() and frame.answer.handIn then pay = frame end
end
check(pay.text._text == ns.TEXT.pay:format("2500c"), "its answer says the price")
pay._scripts.OnClick(pay)
check(said[1] == "reward 1", "and pays when clicked")
quest.money = 0

-------------------------------------------------------------------------------
--  The clicks: the left goes round the words, the right gives what needs no choosing
-------------------------------------------------------------------------------
local function Reward(name)
    for _, frame in ipairs(W.frames) do
        if frame.entry and frame.entry.name == name and frame:IsShown() then return frame end
    end
end
local under = row:GetParent()
check(box._clicks == "LeftButtonUp RightButtonUp" and under._clicks == box._clicks and row._clicks == box._clicks,
      "the words, the quest under them and its rewards take both buttons")
for _, frame in ipairs(W.frames) do
    if frame.answer then check(frame._clicks == nil, "an answer takes the left button alone, as the game's default") end
end

-- A hand-in with a choice to make: no right click takes a reward, wherever it lands.
W.Fire("QUEST_COMPLETE")
W.Wait(1)
said = {}
local vestRow = Reward("Ranger's Vest")
Click(box, "RightButton")
W.Wait(1)
Click(under, "RightButton")
W.Wait(1)
Click(vestRow, "RightButton")
W.Wait(1)
vestRow._scripts.OnDoubleClick(vestRow, "RightButton")
check(#said == 0, "with a reward to choose no right click hands anything in")
check(not vestRow.mark:IsShown(), "nor chooses one")
Click(box, "LeftButton")
check(#said == 0, "a left click on the words hands nothing in")
Click(vestRow, "LeftButton")
check(vestRow.mark:IsShown() and #said == 0, "a left click on a reward chooses it, and only that")
W.Wait(1)
Click(Reward("Band of Thorns"), "RightButton")
Click(vestRow, "RightButton")
check(#said == 0, "a right click on a reward takes none, not even the one chosen")
Click(box, "RightButton")
check(said[1] == "reward 1", "beside the rewards it hands in with the one you chose")

-- A quest that costs money is paid by its answer alone.
quest.money = 2500
W.Fire("QUEST_COMPLETE")
W.Wait(1)
ns.Talk.Choose(1)
said = {}
Click(box, "RightButton")
check(#said == 0, "a right click does not pay for a quest")
quest.money = 0

-- The one reward there is: no choice. A talk just shown waits: the second click of a double click on the NPC.
local three = quest.choices
quest.choices = { three[1] }
W.Fire("QUEST_COMPLETE")
said = {}
Click(box, "RightButton")
check(#said == 0, "a talk just shown takes no right click")
W.Wait(ns.Talk.SETTLE)
Click(box, "RightButton")
check(said[1] == "reward 1", "a moment later the one reward there is is taken")
quest.choices = three

-- An offer of three paragraphs: left clicks go round wherever they land, and accept nothing.
quest.text = "One.\n\nTwo.\n\nThree."
W.Fire("QUEST_DETAIL", 0)
W.Wait(1)
said = {}
for _ = 1, 7 do Click(box, "LeftButton") end
check(words._text == "Two." and #said == 0, "left clicks go round the words and accept nothing")
Click(under, "LeftButton")
check(words._text == "Three.", "a left click on the quest under the words too")
Click(Reward("Ranger's Vest"), "LeftButton")
check(words._text == "One." and #said == 0, "and on a reward while there is nothing to choose")

-- A right click accepts, from the first paragraph on; the second of a double click gives nothing more.
Click(box, "RightButton")
Click(box, "RightButton")
check(#said == 1 and said[1] == "accept", "a right click accepts, once")
W.Wait(1)
said = {}
Click(under, "RightButton")
check(said[1] == "accept", "under the words too")
W.Wait(1)
said = {}
Click(Reward("Ranger's Vest"), "RightButton")
check(said[1] == "accept", "and on the rewards offered, which are not chosen so")

-- A quest of the PvP asks first, as the game's Accept button does.
QuestFlagsPVP = function() return true end
W.Wait(1)
said = {}
Click(box, "RightButton")
check(said[1] == "popup CONFIRM_ACCEPT_PVP_QUEST", "a PvP quest asks first")
QuestFlagsPVP = nil

-- A quest in progress: on to its rewards when done, else Goodbye.
quest.progress = "Have you got them?"
W.Fire("QUEST_PROGRESS")
W.Wait(1)
said = {}
Click(box, "RightButton")
check(said[1] == "complete", "a right click hands in a quest in progress that is done")
quest.completable = false
W.Fire("QUEST_PROGRESS")
W.Wait(1)
said = {}
Click(box, "RightButton")
check(said[1] == "close quest", "not done, it says goodbye")
quest.completable = true
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
Frames(1)

-- A gossip: several answers wait for a click, the one answer is taken, the goodbye screen closes.
local options = gossip.options
gossip.text = "Well met."
gossip.available, gossip.active = {}, {}
gossip.options = { { name = "Hello.", orderIndex = 1 }, { name = "Bye.", orderIndex = 2 } }
GossipFrame:Show()
W.Fire("GOSSIP_SHOW")
W.Wait(1)
said = {}
Click(box, "RightButton")
check(#said == 0, "with several answers a right click waits")
gossip.options = { { name = "Hello.", orderIndex = 1 } }
W.Fire("GOSSIP_SHOW")
W.Wait(1)
said = {}
Click(box, "RightButton")
check(said[1] == "option 1", "the one answer there is is taken")
gossip.options = {}
W.Fire("GOSSIP_SHOW")
W.Wait(1)
said = {}
Click(box, "RightButton")
check(said[1] == "close gossip", "on the goodbye screen a right click closes the talk")
GossipFrame:Hide()
W.Fire("GOSSIP_CLOSED")
W.Wait(1)
Frames(1)
gossip.options = options

QuestFrame:Show()
W.Fire("QUEST_COMPLETE")

-------------------------------------------------------------------------------
--  A fight ends the talk; a talk in a fight is the game's own
-------------------------------------------------------------------------------
said = {}
W.Fire("PLAYER_REGEN_DISABLED")
check(said[1] == "close quest", "a fight closes the talk")
check(not talkRoot:IsShown() and UIParent:GetAlpha() == 1, "the talk is gone and the interface back at once")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
check(QuestFrame:GetParent() == UIParent and GossipFrame:GetParent() == UIParent, "the game's windows are its own in a fight")
W.combat = true
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 0)
check(not talkRoot:IsShown(), "a talk begun in a fight is the game's")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.combat = false
W.Fire("PLAYER_REGEN_ENABLED")
check(QuestFrame:GetParent() == holder, "held again after the fight")

-- A held window the game shows for a talk ours leaves to it comes into sight at once.
QuestIsFromAdventureMap = function() return true end
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 0)
W.Wait(0.1)
check(not talkRoot:IsShown(), "ours does not show that talk")
check(QuestFrame:GetParent() == UIParent, "the game's window is given back into sight")
QuestIsFromAdventureMap = nil
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
check(QuestFrame:GetParent() == holder, "and held again once closed")

-- An offer from an item is the game's popup: ours shows nothing.
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 12345)
check(not talkRoot:IsShown(), "an offer from an item is left to the game")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)

-- Another kind of window (a vendor) ends the talk.
GossipFrame:Show()
gossip.options = { { name = "Let me browse your goods.", orderIndex = 1 } }
gossip.available, gossip.active = {}, {}
W.Fire("GOSSIP_SHOW")
check(talkRoot:IsShown(), "a vendor's gossip shows")
W.Fire("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", 5)
Frames(1)
check(not talkRoot:IsShown(), "the vendor's window ends ours")
GossipFrame:Hide()
W.Fire("GOSSIP_CLOSED", true)
W.Wait(1)
Frames(1)
check(UIParent:GetAlpha() == 1, "and the interface is back")

-- The only option the game takes by itself shows nothing.
gossip.options = { { name = "Fly.", orderIndex = 1, selectOptionWhenOnlyOption = true } }
W.Fire("GOSSIP_SHOW")
check(not talkRoot:IsShown(), "an only option the game takes by itself shows nothing")

-------------------------------------------------------------------------------
--  The settings
-------------------------------------------------------------------------------
SaneUI.Core.Set(ns.name, "talk", false)
check(QuestFrame:GetParent() == UIParent and GossipFrame:GetParent() == UIParent, "Talks as a scene off: the game's windows")
GossipFrame:Show()
gossip.options = { { name = "Hello.", orderIndex = 1 }, { name = "Bye.", orderIndex = 2 } }
W.Fire("GOSSIP_SHOW")
check(not talkRoot:IsShown(), "and no talk of ours")
GossipFrame:Hide()
W.Fire("GOSSIP_CLOSED")
SaneUI.Core.Set(ns.name, "talk", true)
check(GossipFrame:GetParent() == holder, "on again: held again")

SaneUI.Core.Set(ns.name, "quiet", false)
GossipFrame:Show()
W.Fire("GOSSIP_SHOW")
Frames(1)
check(talkRoot:IsShown() and UIParent:GetAlpha() == 1, "Hide the interface off: the interface stays")
SaneUI.Core.Set(ns.name, "quiet", true)
Frames(1)
check(UIParent:GetAlpha() == 0, "on again during a talk: it fades out")
SaneUI.Core.Set(ns.name, "space", false)
check(bindings.SPACE == nil, "Space goes on off: no binding")
SaneUI.Core.Set(ns.name, "space", true)
check(bindings.SPACE == ns.Keys.BUTTON, "on again: bound")

-------------------------------------------------------------------------------
--  Standing down
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--  Retail: the same talk, the same rewards
-------------------------------------------------------------------------------
GossipFrame:Hide()
W.Fire("GOSSIP_CLOSED")
W.Wait(1)
Frames(1)
W.Play("retail")
quest.text = "Retail's words."
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 0)
check(talkRoot:IsShown(), "Retail: an offer shows as ours")
local retailRewards = ns.Rewards.Read(true)
check(retailRewards.choices[1].what == "Leather \194\183 Chest" and retailRewards.choices[1].value == 1450,
      "Retail: its rewards read the same")
said = {}
ns.Talk.Continue()
check(said[1] == "accept", "Retail: Continue accepts")
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
Frames(1)
W.Play("forever")

-------------------------------------------------------------------------------
--  Speed Leveling's quest givers beside the talk (its own file): the game's calls at the game's events
-------------------------------------------------------------------------------
local wants = { take = { [77] = true }, handin = { [77] = 2 }, gossip = {} }
local leveling = { On = SaneUI.Core.On, Guarded = function(fn, ...) return fn(...) end,
                   options = { take = true, handin = true, rewards = false, gossip = false, leave = false },
                   Key = { Refresh = function() end }, Guide = { Quests = function() return wants end } }
assert(loadfile(root .. "/src/SpeedLeveling/Quests.lua"))("SaneUI_SpeedLeveling", leveling)
leveling.Quests.Start()
local function Asked(what)
    for _, line in ipairs(said) do if line == what then return true end end
    return false
end

quest.text = "A long tale.\n\nWith a second paragraph."
said = {}
QuestFrame:Show()
W.Fire("QUEST_DETAIL", 0)
check(talkRoot:IsShown() and Asked("accept"), "Take the guide's quests: accepted at once, the words waiting or not, no click")
said = {}
W.Fire("QUEST_PROGRESS")
check(Asked("complete"), "Hand in the guide's quests: on from its progress")
said = {}
W.Fire("QUEST_COMPLETE")
check(Asked("reward 2"), "and handed in with the reward the guide names")

-- The switches off: the talk is yours, and it waits for you.
leveling.options.take, leveling.options.handin = false, false
said = {}
W.Fire("QUEST_DETAIL", 0)
W.Wait(600)
check(not Asked("accept") and words._text == "A long tale.", "nothing taken, the words wait")
Click(box, "RightButton")
check(Asked("accept"), "until a right click accepts")
leveling.off = true
QuestFrame:Hide()
W.Fire("QUEST_FINISHED")
W.Wait(1)
Frames(1)

GossipFrame:Show()
gossip.options = { { name = "Hello.", orderIndex = 1 }, { name = "Bye.", orderIndex = 2 } }
W.Fire("GOSSIP_SHOW")
Frames(1)

local told = {}
for _, line in ipairs(W.printed) do if line:find("problem") then told[#told + 1] = line end end
check(#told == 0, "no problem was told on the way: " .. table.concat(told, " / "))
check(#(SaneUI.Core.errors or {}) == 0, "and none is in the error log")

W.caught = {}
ns.StandDown("a test")
check(ns.off == true, "the module stood down")
check(UIParent:GetAlpha() == 1 and StaticPopup1._ignoreAlpha == false, "the interface as it was")
check(bindings.SPACE == nil, "no binding of ours")
check(not talkRoot:IsShown(), "our talk hidden")
check(GossipFrame:GetParent() == UIParent and GossipFrame:IsShown(), "the game's open gossip window back into sight")
check(QuestFrame:GetParent() == UIParent, "the quest window the game's again")
W.caught = nil

io.write(("Lore: all %d checks passed.\n"):format(passed))
