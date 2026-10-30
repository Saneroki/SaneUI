local ADDON, ns = ...

-------------------------------------------------------------------------------
--  Sane UI - Speed Leveling
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_SpeedLeveling): it needs Core and nothing else,
--  and is switched on and off in the game's addon list.
--
--  One key for questing (Esc > Options > Keybindings, under Sane UI), pressed
--  again and again: it opens the loot of the corpse beside you, talks to the
--  quest giver in front of you, picks up what your quests want in front of
--  you, attacks your foe, else finds what your quests and your guide want
--  around you, puts a skull on it and attacks it; it hearths when your guide
--  says so, and uses a quest item when nothing wanted is around. At a quest
--  giver the guide's quests are taken and handed in. And your leveling guide
--  over the world, its steps at hand and the next ones (Saneroki, 2026-10-25),
--  run by Sane UI itself: guides pasted as text, and the guides you bought,
--  opened for your account. Nothing of another addon is needed.
--    Unlock.lua  the import string of bought guides, opened for your account
--    Format.lua  a guide written as text, read into our own shape
--    Lines.lua   what each line of a guide asks, and whether it is done
--    Run.lua     a guide run for the character: where you are, what is at hand
--    Guide.lua   the guide shown, its picture, the guides kept
--    Wanted.lua  what is wanted around you, by name: your guide's steps, your
--                quests' open objectives (Core's data, else the game's words),
--                the creatures the game marks for your quests, the NPCs your
--                finished quests go to; the thing in front of you
--    Items.lua   what the key uses: the hearth, one quest item
--    Key.lua     the key: what one press does now, by the game's secure ways
--    Rewards.lua which reward to take where a quest offers a choice
--    Quests.lua  what a quest giver does for your guide, a talk that is done closed
--    Errands.lua what would hold you up: all loot taken, the game's questions
--                on equipping and destroying answered, new upgrades put on
--    Rolls.lua   group rolls decided with the other Sane UI of your group
--    Steps.lua   the guide over the world
--    Arrow.lua   the way to the guide's place, a part of its own
--    Icons.lua   the items to use and the names to target, over the guide
--    Guides.lua  the window of the guides kept
-------------------------------------------------------------------------------
local Core = SaneUI.Core
ns.title = "Speed Leveling"
Core.NewModule(ADDON, "SpeedLeveling", ns)

ns.TEXT = {
    solo = "Solo",
    soloTip = "On: all of Speed Leveling works, the key, the guide, the quest givers, the loot, the upgrades and the group rolls. Off: all of it rests until you tick it again: your key does nothing, the guide is hidden and what it changed in Loot is put back. For playing with others. Your own two characters together count as solo. On in the profile Speedleveling, off in the others. Also a box at the foot of the bags.",
    binding = "Loot, talk, pick up, attack, find and mark, use",
    hint = "Speed Leveling's key has no key on this account (the game keeps key bindings per account): give it one in Esc > Options > Keybindings, under Sane UI: Loot, talk, pick up, attack, find and mark, use.",
    -- /sane key: what the key sees now (Key.Check).
    keyCommand = "what Speed Leveling's key sees now: what it would do, what is in front of you, your target",
    keyNone = "Speed Leveling's key is not made yet.",
    keyState = "Key: state %s, a press does %s; its keys %s.",
    keyFront = "In front of you: %s; one to talk to %s, a thing your quests want %s.",
    keyTarget = "Your target: %s; wanted %s, its item %s.",
    keyCorpse = "Your target's corpse has loot %s; the interact key looks all around %s; the NPC in front left alone %s.",
    keyWalk ="Click-to-Move %s (lent by the key: %s); the guide %s.",
    keyUnit = "%s, a %s, %s",
    keyNobody = "nothing",
    keyNoKey = "none (Esc > Options > Keybindings, under Sane UI)",
    objects = "Quest objects",
    objectsTip = "A thing of the world your quests or your guide want, in front of you, is picked up, opened or used, as a right click on it does: a quest's chest or plant, what an item to loot comes from, the board a quest is handed in to. The game's interact key finds it and is switched on for it.",
    loot = "Loot first",
    lootTip = "A corpse with loot beside you is opened before anything else, as a right click on it does; what is taken is up to the loot window. The game's interact key is switched on for it, and put back as it was when this, Talk to NPCs and Quest objects are off.",
    corpses = "Walk to corpses",
    corpsesTip = "A corpse with loot away from you too: for a moment after a fight the game's interact key looks all around you, 30 yards far, and your target's corpse counts however far it is. While there is one the game's own Click-to-Move is switched on, so the key runs you to it and opens it; put back as it was after the last corpse, and in a fight. While it is on, a right click on the ground walks you there too.",
    skull ="Skull on what is found",
    skullTip = "What the key finds or attacks gets a skull over its head. In a group it shows for everybody; in a raid only an assistant may mark.",
    talk = "Talk to NPCs",
    talkTip = "A friendly NPC in front of you is talked to at once (after a corpse to loot); a quest NPC the key found, at the next press. Off: the key goes on to what is next.",
    walk = "Walk to the NPC found",
    walkTip = "While a quest NPC the key found is your target, the game's own Click-to-Move is switched on, so the key runs you to it and talks to it. It is put back as it was when that NPC is no longer your target, and in a fight. While it is on, a right click on the ground walks you there too. Only NPCs: the game lets no addon walk you to a place.",
    useOn = "Use items on what is found",
    useOnTip = "Out of a fight, when your target is the one a step's item is used on (the step says so: on a corpse, or on the creature or NPC it names), the key uses the item on it, before talking or fighting. A friendly NPC once it is within the item's reach. Never on a creature the step says to weaken first, and not again on one the game refused the item on.",
    guide = "Your guide's targets",
    guideTip = "What the steps at hand of your guide want talked to or killed come first.",
    hearth = "Hearthstone",
    hearthTip = "When your guide's step says to hearth, the key uses your Hearthstone (a shaman's Astral Recall while the stone cools down), once nothing is to be looted, talked to, picked up or fought.",
    items = "Quest items",
    itemsTip = "When the key finds nothing wanted around you, it uses one item: of your guide's step first, then a quest item of your quest log, the first in your bags that is ready. Away from its place the game says so and nothing is used; one for a creature or a spot puts the game's targeting hand on the cursor.",

    -- The quest givers (Quests.lua).
    questsHeader = "Quest givers",
    questsHeaderTip = "What talking to a quest giver does for your guide. Hold Shift during a talk and the rest of it is yours, nothing more is done for you with that NPC.",
    take = "Take the guide's quests",
    takeTip = "The quests the steps at hand of your guide take (and those of the step after them) are accepted as the quest giver offers them.",
    handin = "Hand in the guide's quests",
    handinTip = "The quests the steps at hand hand in are handed in. With several rewards to choose from, Choose quest rewards decides; with that off, the reward the guide names, and with none named the choice is yours.",
    rewards = "Choose quest rewards",
    rewardsTip = "With several rewards to choose from: the biggest upgrade for your gear; with no upgrade among them, the reward your guide names; else the one worth the most, what a vendor pays or what the auction house brings where it can go there and you saw a price (the module Tooltips notes those).",
    gossip = "Choose the guide's talk",
    gossipTip = "Where a step names what to say to an NPC (a gossip option), it is chosen.",
    leave = "Close the talk when it is done",
    leaveTip = "After a quest is taken or handed in, the key leaves that NPC alone and goes on to what is next, unless your guide still wants a quest there, and a talk that comes up with nothing for you closes by itself, quests your guide does not know included. Talk to the NPC yourself to take those. The key talks to that NPC again once you moved on, the quest log changed, or half a minute is over.",

    -- What would hold you up (Errands.lua).
    errandsHeader = "On the way",
    errandsHeaderTip = "What Speed Leveling does for you so that nothing holds you up.",
    lootAll = "Take all loot",
    lootAllTip = "Sets the module Loot to take everything at once: its Everything on, its Always show upgrades off, as Equip upgrades puts those on. The game's question on a thing that binds when picked up is answered too. What you change on Loot's page afterwards stays; this switch off puts back the rest. Things locked to a group's roll are not taken.",
    cinematics = "Skip cinematics",
    cinematicsTip = "Cinematics and the game's movies are skipped as they start, those the game lets you skip yourself.",
    rolls = "Roll on group loot",
    rollsTip = "When your group rolls for a thing, the Sane UI of each of your characters says what it would bring, and the one it brings the most Needs it; the others Greed. With nobody to agree with, Need on an upgrade, else Greed. In a fight it waits for the end of the fight, as long as the roll's clock allows.",
    noAsk = "Equip and delete without asking",
    noAskTip = "The game no longer asks before gear binds to you or loses its refund, or before an item is destroyed, whatever its quality: the moment you drop it, it is gone. Where the game keeps destroying for a click of your own, its question comes up with the word it wants already typed in.",
    equipUpgrades = "Equip upgrades",
    equipUpgradesTip = "Gear that comes into your bags, looted or a quest's reward, and is an upgrade is put on at once, or after a fight: anything you can wear for a place with nothing in it, else one worth more to you: its stats as your class and specialization want them (the module Inventory's weights), else its item level. What you took off yourself stays off. The chat says what was put on.",
    equipped = "Equipped %s.",

    -- The guide over the world (Guide.lua, Steps.lua, Guides.lua).
    guideHeader = "Guide",
    guideHeaderTip = "Your leveling guide over the world: the zone, the steps at hand and the next ones.",
    follow = "Your guide",
    followTip = "On: the guide shows over the world and moves on as you play; the key and the quest givers follow it. Paused: it holds where it is, its view shows only that it is paused (a click goes on), and nothing is done for it; what you did meanwhile counts once it goes on. Off: no guide is followed; the key looks for your quests alone. Also in the minimap's satchel.",
    followOn = "On",
    followPaused = "Paused",
    followOff = "Off",
    paused = "Paused. Click here to go on with the guide.",
    switchTitle = "Leveling guide",
    switchTip = "Click: pause the guide, or go on with it. Right click: on, paused or off.",
    showGuide = "Show the guide",
    showGuideTip = "The guide's steps straight on the world, where Edit Mode puts them, or where you drag them: a right click on the zone unlocks it. A click on a step at hand skips it, a right click goes back one; the wheel over the listed steps scrolls through the whole guide, done steps too; a right click on a listed step goes to it; a right click on the zone chooses the guide to follow.",
    gather = "Gathering for the next zone",
    gatherTip = "Under the guide's head, a warning while your Herbalism or Mining is lower than the next zone the guide goes to asks: the skill that gathers at least half of the herbs or the ore growing there (from Sane UI's data of the world; WoW: Forever).",
    gatherShort = "%s next: %s. Gather here a while first.",
    gatherSkill = "%s %d of %d",
    showArrow = "Show the arrow",
    showArrowTip = "The way to the guide's place, a part of its own placed in Edit Mode, or dragged: a right click on it unlocks it. The leather ring turned the way to go, in it a picture of what to do there, under it what to do and how far, and the time to get there.",
    icons = "Targets and items over the guide",
    iconsTip = "The items the guide's steps want used (the Hearthstone, quest items) and the NPCs and creatures to target, as icons in a row over the guide's top: a click uses the item or targets the name. Changed out of a fight only: the game holds such buttons in one.",
    ahead = "Steps listed ahead",
    aheadTip = "How many steps the list under those at hand shows; the wheel scrolls it through the whole guide.",
    unlock = "Unlock to drag",
    lock = "Lock in place",
    guidesButton = "Guides",
    guidesButtonTip = "The guides: those that come for this game and those you added. Paste the import string of the guides you bought, or a guide's text, and choose the one to follow.",
    guideView = "Guide",
    guides = "Guides",
    step = "Step %d",
    progress = "%d/%d \194\183 %d%%",
    paste = "All guides, or add one...",
    ungrouped = "Other guides",
    noneHere = "No guide for this character yet",
    pasteHint = "Or paste a guide's text here (Ctrl+V), then Read.",
    readButton = "Read",
    read = "Kept %d: %s.",
    unread = "%d lines could not be read and are left out:",
    noneRead = "No guide was found in that text.",
    noneKept = "No guide yet: paste the import string of your bought guides at the right, or a guide's text, then Read.",
    noGuide = "No guide yet. Click here to add one: the import string of the guides you bought, or a guide's text (/sane guides).",
    noGuideChosen = "No guide is followed. Click here, or right click the view, to choose one (/sane guides).",
    noGuideHere = "None of the guides is for this character or this game. Click here to add one (/sane guides).",
    forget = "Forget the guide %s?",
    command = "the guides: paste the import string of your bought guides or a guide's text, choose the one to follow",
    unnamed = "Guide",
    -- The import string of bought guides (Unlock.lua, Guides.lua).
    stringTitle = "The import string of the guides you bought, or a large guide's text",
    stringHint = "Click here and paste it (Ctrl+V): an import string is opened for the account you play.",
    pastedString = "%d characters pasted.",
    notString = "That is no import string, and its line breaks did not come through: paste a guide's text into the box below instead.",
    opening = "Opening your guides... %d%%",
    openingAlready = "Your guides are being opened already.",
    unlockBroken = "The import string is incomplete or broken: copy it again, whole.",
    unlockAccount = "That import string is for another account: it opens only with the BattleTag the guides were bought with.",
    unlockOffline = "Battle.net is not connected, so your BattleTag is not known yet: try again in a moment.",
    unlockOld = "That import string is of an older kind that can no longer be read: get it anew.",
    unlockGame = "This game cannot open import strings.",
    unlockEmpty = "That import string holds no guide.",
    -- Our words for a line a guide gives none (Lines.lua).
    quest = "Quest %d",
    item = "Item %d",
    spell = "Spell %d",
    acceptQuest = "Accept %s",
    handinQuest = "Hand in %s",
    abandon = "Abandon %s",
    level = "Reach level %d",
    levelShort = "Grind until you are %d experience away from level %d",
    levelInto = "Grind until you are %d experience into level %d",
    levelShare = "Grind until you are %d%% into level %d",
    learn = "Learn %s",
    skill = "Reach %d in %s",
    hearthTo = "Hearth to %s",
    hearthNow = "Hearth",
    bindTo = "Make %s your home",
    bindHere = "Make this inn your home",
    flightpathAt = "Get the flight path at %s",
    flightpath = "Get the flight path here",
    flyTo = "Fly to %s",
    fly = "Take a flight",
    goTo = "Go to %s",
    revive = "Die, and come back at the spirit healer",
    cast = "Cast %s",
    shop = "Sell junk and buy what you need",
    trainer = "Train your skills",
    stable = "Stable your pet",
    arrive = "Get there",
    destroy = "Throw away %s",
    bankIn = "Put %s into the bank",
    bankOut = "Take %s out of the bank",
    tame = "Tame the beast",
    -- The arrow and the icons (Arrow.lua, Icons.lua).
    arrowView = "Guide's arrow",
    yards = "%d yd",
    seconds = "%d s",
    minutes = "%d:%02d",
    goToStep = "Go to step %d",
    targetFriend = "Click: target it",
    targetFoe = "Click: target it",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the key is the game's own again, the guide hidden"

local OPTIONS = {
    { key = "solo", default = false, text = ns.TEXT.solo, tip = ns.TEXT.soloTip },
    { key = "loot", default = true, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
    { key = "corpses", default = true, text = ns.TEXT.corpses, tip = ns.TEXT.corpsesTip, parent = "loot" },
    { key = "talk", default = true, text = ns.TEXT.talk, tip = ns.TEXT.talkTip },
    { key = "walk", default = true, text = ns.TEXT.walk, tip = ns.TEXT.walkTip, parent = "talk" },
    { key = "objects", default = true, text = ns.TEXT.objects, tip = ns.TEXT.objectsTip },
    { key = "useOn", default = true, text = ns.TEXT.useOn, tip = ns.TEXT.useOnTip },
    { key = "skull", default = true, text = ns.TEXT.skull, tip = ns.TEXT.skullTip },
    { key = "guide", default = true, text = ns.TEXT.guide, tip = ns.TEXT.guideTip },
    { key = "hearth", default = true, text = ns.TEXT.hearth, tip = ns.TEXT.hearthTip },
    { key = "items", default = true, text = ns.TEXT.items, tip = ns.TEXT.itemsTip },
    { key = "take", default = true, text = ns.TEXT.take, tip = ns.TEXT.takeTip,
      header = ns.TEXT.questsHeader, headerTip = ns.TEXT.questsHeaderTip },
    { key = "handin", default = true, text = ns.TEXT.handin, tip = ns.TEXT.handinTip },
    { key = "rewards", default = true, text = ns.TEXT.rewards, tip = ns.TEXT.rewardsTip, parent = "handin" },
    { key = "gossip", default = true, text = ns.TEXT.gossip, tip = ns.TEXT.gossipTip },
    { key = "leave", default = true, text = ns.TEXT.leave, tip = ns.TEXT.leaveTip },
    { key = "lootAll", default = true, text = ns.TEXT.lootAll, tip = ns.TEXT.lootAllTip,
      header = ns.TEXT.errandsHeader, headerTip = ns.TEXT.errandsHeaderTip },
    { key = "noAsk", default = true, text = ns.TEXT.noAsk, tip = ns.TEXT.noAskTip },
    { key = "equipUpgrades", default = true, text = ns.TEXT.equipUpgrades, tip = ns.TEXT.equipUpgradesTip },
    { key = "rolls", default = true, text = ns.TEXT.rolls, tip = ns.TEXT.rollsTip },
    { key = "cinematics", default = true, text = ns.TEXT.cinematics, tip = ns.TEXT.cinematicsTip },
    { key = "follow", default = "on", text = ns.TEXT.follow, tip = ns.TEXT.followTip,
      choices = { { "on", ns.TEXT.followOn }, { "paused", ns.TEXT.followPaused }, { "off", ns.TEXT.followOff } },
      header = ns.TEXT.guideHeader, headerTip = ns.TEXT.guideHeaderTip },
    { key = "showGuide", default = true, text = ns.TEXT.showGuide, tip = ns.TEXT.showGuideTip },
    { key = "gather", default = true, text = ns.TEXT.gather, tip = ns.TEXT.gatherTip },
    { key = "showArrow", default = true, text = ns.TEXT.showArrow, tip = ns.TEXT.showArrowTip },
    { key = "icons", default = true, text = ns.TEXT.icons, tip = ns.TEXT.iconsTip },
    { key = "ahead", default = 5, min = 0, max = 12, step = 1, text = ns.TEXT.ahead, tip = ns.TEXT.aheadTip },
    { key = "guidesButton", text = ns.TEXT.guidesButton, tip = ns.TEXT.guidesButtonTip,
      button = function() ns.Guarded(ns.Guides.Open) end },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before the key lent them (Key.lua)
    { key = "lootLent", default = {} },   -- Loot's switches as they were before Take all loot set them (Errands.lua)
    { key = "deleteRefused", default = false }, -- the game refused to destroy an item without its question (Errands.lua)
}
-- The switches of the guide over the world: drawn anew; the guide's targets also change what the key wants; the quest
-- givers' switches and those of what is on the way are read when they are needed.
local VIEW = { showGuide = true, showArrow = true, icons = true, ahead = true, gather = true }
local QUESTS = { take = true, handin = true, rewards = true, gossip = true, leave = true, noAsk = true, equipUpgrades = true,
                 rolls = true, cinematics = true, lootLent = true, deleteRefused = true }
-- Solo off: all of the module rests until it is ticked again, as a module stood down but for good reason: ns.off is
-- what every part of it asks. The guide's run goes on knowing where it is, so that it catches up after.
local resting = false
local function Rest(on)
    if on == resting or (ns.off and not resting) then return end
    resting = on
    if on then
        ns.off = true
        ns.Steps.GiveBack()
        ns.Guides.GiveBack()
        ns.Key.GiveBack()
        ns.Errands.Update()
    else
        ns.off = nil
        ns.Key.Wake()
        ns.Errands.Update()
        ns.Guide.CheckSoon()
        ns.Steps.Update()
    end
    Core.SwitchChanged()
end

Core.Options(ns.name, OPTIONS, { changed = function(key, now)
    if key == "solo" then
        Rest(now == false)
    elseif VIEW[key] then
        ns.Guarded(ns.Steps.Update)
    elseif key == "lootAll" then
        ns.Guarded(ns.Errands.Update)
    elseif key == "guide" or key == "follow" then
        -- On, paused or off: what the key wants follows, the view is drawn anew, the satchel's switch told.
        if key == "follow" then ns.Guarded(ns.Guide.CheckSoon) end
        ns.Guarded(ns.Wanted.Changed)
        ns.Guarded(ns.Steps.Update)
        Core.SwitchChanged()
    elseif not QUESTS[key] then
        ns.Guarded(ns.Key.Update)
    end
end })

-- Standing down: no override binding of ours on your keys, the game's settings as they were, the guide hidden, Loot's
-- switches back.
function ns.GiveBack()
    ns.Guide.Stop()
    ns.Steps.GiveBack()
    ns.Guides.GiveBack()
    ns.Key.GiveBack()
    ns.Errands.Update()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Lines.Start()
    ns.Guide.Start()
    ns.Wanted.Start()
    ns.Key.Start()
    ns.Quests.Start()
    ns.Errands.Start()
    ns.Rolls.Start()
    -- A change of the guide: drawn anew; what the key wants follows.
    ns.Guide.Watch(ns.Steps.Update)
    ns.Guide.Watch(ns.Key.Refresh)
    ns.Steps.Update()
    if ns.options.solo == false then Rest(true) end
end

Core.Command("guides", ns.TEXT.command, function() ns.Guarded(ns.Guides.Open) end)
Core.Command("key", ns.TEXT.keyCommand, function() ns.Guarded(ns.Key.Check) end)

-- The guide on, paused or off, as a quick switch for a view that gathers them (Core.Offer: the minimap's satchel).
-- A click pauses it or goes on; a right click chooses on, paused or off.
local function Follow(value) Core.Set(ns.name, "follow", value) end
Core.Offer("speedleveling", {
    title = ns.TEXT.switchTitle, icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
    State = function()
        if ns.off or not ns.options then return nil end
        return ns.options.follow or "on"
    end,
    Tip = function() return ns.TEXT.switchTip end,
    Click = function(mouse, owner)
        local now = ns.options.follow or "on"
        if mouse ~= "RightButton" then return Follow(now == "on" and "paused" or "on") end
        local util = rawget(_G, "MenuUtil")
        if not (util and util.CreateContextMenu) then return end
        util.CreateContextMenu(owner, ns.Guard(function(_, root)
            root:CreateTitle(ns.TEXT.switchTitle)
            for _, choice in ipairs({ { "on", ns.TEXT.followOn }, { "paused", ns.TEXT.followPaused },
                                      { "off", ns.TEXT.followOff } }) do
                root:CreateRadio(choice[2], ns.Guard(function() return (ns.options.follow or "on") == choice[1] end),
                                 ns.Guard(function() Follow(choice[1]) end))
            end
        end))
    end,
})
