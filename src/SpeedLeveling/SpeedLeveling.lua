local ADDON, ns = ...

-------------------------------------------------------------------------------
--  SaneUI - Speed Leveling
--  The module's own table (ns in all its files), its words, its settings, and
--  how it stands down.
--
--  An addon of its own (SaneUI_SpeedLeveling): it needs Core and nothing else,
--  and is switched on and off in the game's addon list.
--
--  One key for questing (Esc > Options > Keybindings, under SaneUI), pressed
--  again and again: it opens the loot of the corpse beside you, talks to the
--  quest giver in front of you, picks up what your quests want in front of
--  you, attacks your foe, else finds what your quests and your guide want
--  around you, puts a skull on it and attacks it; it hearths when your guide
--  says so, and uses a quest item when nothing wanted is around. At a quest
--  giver the guide's quests are taken and handed in. And your leveling guide
--  over the world, its steps at hand and the next ones (Saneroki, 2026-10-25),
--  run by SaneUI itself: guides pasted as text, and the guides you bought,
--  opened for your account. Nothing of another addon is needed.
--    Unlock.lua  the import string of bought guides, opened for your account
--    Format.lua  a guide written as text, read into our own shape
--    Lines.lua   what each line of a guide asks, and whether it is done
--    Run.lua     a guide run for the character: where you are, what is at hand
--    Party.lua   the party on one guide, read together: who is through with a step waits for the rest
--    Guide.lua   the guide shown, its picture, the guides kept
--    ClassQuests.lua  your class's quest chains over the guide, by your level
--    Gathering.lua, Grind.lua, Detours.lua  your professions along the guide
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
--    Rolls.lua   group rolls decided with the other SaneUI of your group
--    Steps.lua   the guide over the world
--    Arrow.lua   the way to the guide's place, a part of its own
--    Icons.lua   the items to use and the names to target, past the guide's head
--    Guides.lua  the window of the guides kept
-------------------------------------------------------------------------------
local Core = SaneUI.Core
ns.title = "Speed Leveling"
Core.NewModule(ADDON, "SpeedLeveling", ns)

ns.TEXT = {
    binding = "Loot, talk, pick up, attack, find and mark, use",
    hint = "Speed Leveling's key has no key on this account (the game keeps key bindings per account): give it one in Esc > Options > Keybindings, under SaneUI: Loot, talk, pick up, attack, find and mark, use.",
    keyFirst = "Speed Leveling's key is %s: loot, talk, pick up, attack, find and mark, use. Change it in Esc > Options > Keybindings, under SaneUI.",
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
    keyNoKey = "none (Esc > Options > Keybindings, under SaneUI)",
    objects = "Quest objects",
    objectsTip = "A thing of the world your quests or your guide want, in front of you, is picked up, opened or used, as a right click on it does: a quest's chest or plant, what an item to loot comes from, the board a quest is handed in to. The game's interact key finds it and is switched on for it.",
    loot = "Loot first",
    lootTip = "A corpse with loot beside you is opened before anything else, as a right click on it does; what is taken is up to the loot window. The game's interact key is switched on for it, and put back as it was when this, Talk to NPCs and Quest objects are off.",
    corpses = "Walk to corpses",
    corpsesTip = "A corpse with loot away from you too: for a moment after a fight the game's interact key looks all around you, " .. Core.Distance(30) .. " far, and your target's corpse counts however far it is. While there is one the game's own Click-to-Move is switched on, so the key runs you to it and opens it; put back as it was after the last corpse, and in a fight. While it is on, a right click on the ground walks you there too.",
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
    rollsTip = "When your group rolls for a thing: Need if it is an upgrade to you, else Greed. Nobody Passes. Off: nothing is rolled for you.",
    equipUpgrades = "Equip upgrades",
    equipUpgradesTip = "Gear that comes into your bags, looted or a quest's reward, and is an upgrade is put on at once, or after a fight: anything you can wear for a place with nothing in it, else one worth more to you: its stats as your class and specialization want them (the module Inventory's weights), else its item level. What you took off yourself stays off. The chat says what was put on.",
    equipped = "Equipped %s.",

    -- The guide over the world (Guide.lua, Steps.lua, Guides.lua).
    guideHeader = "Guide",
    guideHeaderTip = "Your leveling guide over the world: the zone, the steps at hand and the next ones.",
    follow = "Your guide",
    followTip = "On: the guide shows over the world and moves on as you play; the key and the quest givers follow it. Paused: it holds where it is, its view shows only that it is paused (a click goes on), and nothing is done for it; what you did meanwhile counts once it goes on. Off: no guide is followed; the key looks for your quests alone.",
    followOn = "On",
    followPaused = "Paused",
    followOff = "Off",
    paused = "Paused. Click here to go on with the guide.",
    party = "Together with the party",
    partyTip = "In a group, those of you who follow the same guide follow it as one: the same steps by the same numbers for each of you, every step of any of your classes, and the quests the guide gives only some classes, while others see to their own, for all of you. What only one class does (its trainer, its class quests) only that one does: the others go past it, faint in the list, to the next step you share and wait there. Whoever is through with a step first waits on it, its targets still wanted, until the others are through with it too, and then all of you go on together; one busy with its class quests is waited for as well. Your company is remembered for this character while the others are offline. Only members with SaneUI who follow that guide count. A right click on the step you wait on goes on without them.",
    waitFor = "Waiting for %s",
    onChain = "%s (class quests)",
    theirs = "%s: %s",
    switchTitle = "Speed Leveling",
    switchTip = "On: this character uses the profile Speedleveling, with all of Speed Leveling's automation and its guide. Off: it goes back to the profile it used before, Accountwide if it had no other, and the guide is gone.",
    showGuide = "Show the guide",
    showGuideTip = "The guide's steps straight on the world, where Edit Mode puts them, or where you drag them: a right click on the zone unlocks it. Only the steps show: the mouse on them brings the zone, how far you are and the icons. In the upper half of the screen the guide grows down from its top, these under the steps; in the lower half up from its bottom, these over them. A click on a step at hand pauses it: it stays, faint, and the guide, its arrow, map pin and key go on with the next step; a click on it again takes it up and goes to it. A right click skips it. A middle click on the guide opens its settings: Your guide, the guide's switches, and all settings. With no guide followed, Select a guide and its button choose one. The wheel over the guide shows the list of its steps in their place, your step in the middle, and scrolls it from the guide's first step to its last; the red cross, or 10 seconds without the mouse on it, brings the steps back; a double click on a listed step goes to it, a right click offers to; a right click on the zone chooses the guide to follow.",
    gather = "Professions along the way",
    gatherTip = "Your professions level up where your guide takes you anyway. Mining and Herbalism: a step where the guide passes the most nodes in a zone, a check before it leaves that zone, and a step with the map pin on a herb or ore the minimap shows close enough to your way, for as long as the steps ahead still want more. Tailoring and First Aid: after killing humanoids, a step to kill on for their cloth while they are worth the experience. Crafts and the rest: a step before a harder zone. All from SaneUI's data of the world (WoW: Forever). A right click on a step skips it; the others are for the professions you have.",
    raiseSkill = "Level %s to %d",
    skillBefore = "Before %s",
    skillHere = "Around here",
    detour = "On the way",
    gatherHerb = "Pick the %s",
    gatherOre = "Mine the %s",
    grind = "Kill on here for cloth: worth it until level %d",
    classQuests = "Class quests",
    classQuestsTip = "When your level reaches a quest chain of your class, for your race and side (Bear Form at 10, a warlock's pets, a shaman's totems), its next step stands over the guide, and the arrow, the map pin and the key go by it until the chain is done. Your guide goes on under it, and what your guide does itself is left to it. A click on the step pauses that chain: it stays in sight, faint, your guide and its arrow go on, and the steps of your guide that wait on its quests wait with it; a click again takes it up. A right click leaves the chain; a right click on the zone brings it back.",
    classStep = "%s: %d of %d",
    classAt = "%s %s",
    classAtIn = "%s %s in %s",
    classTalk = "Talk to",
    classGo = "Go to",
    classUse = "Use %s",
    classBack = "Bring back the class quests you left",
    showArrow = "Show the arrow",
    showArrowTip = "The way to the guide's place, a part of its own placed in Edit Mode, or dragged: a right click on it unlocks it. The leather ring turned the way to go, along Navigation's route wherever your map pin stands, in it a picture of what to do there, under it what to do and how far, and the time to get there. It stands where the toast of a new level and the travel overlay stand, and makes way for them.",
    mapPin = "Map pin on the guide's place",
    mapPinTip = "The game's map pin goes on each place the guide sends you to, as soon as it comes up, so the golden line on Navigation's map leads there. A pin you put yourself stays until the guide goes on to its next place.",
    icons = "Targets and items with the guide",
    iconsTip = "The items the guide's steps want used (the Hearthstone, quest items) and the NPCs and creatures to target, as icons in a row past the guide's head, with the mouse on the guide: a click uses the item or targets the name. Changed out of a fight only: the game holds such buttons in one.",
    ahead = "Steps in the list",
    aheadTip = "How many steps the list shows at least that the wheel brings up over the guide; it fills the steps' place and scrolls from the guide's first step to its last.",
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
    -- The view while no guide is followed (Saneroki, 2026-11-09), and its middle click's settings.
    selectGuide = "Select a guide",
    howTo = "Middle click for settings.\nLeft click pauses and resumes a step.\nRight click skips a step.",
    settings = "Guide settings",
    allSettings = "All settings...",
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
    seconds = "%d s",
    minutes = "%d:%02d",
    goToStep = "Go to step %d",
    targetFriend = "Click: target it",
    targetFoe = "Click: target it",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the key is the game's own again, the guide hidden"

-- Every switch off at first: all of them are on in the profile Speedleveling alone (Core's Presets.lua).
local OPTIONS = {
    { key = "loot", default = false, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
    { key = "corpses", default = false, text = ns.TEXT.corpses, tip = ns.TEXT.corpsesTip, parent = "loot" },
    { key = "talk", default = false, text = ns.TEXT.talk, tip = ns.TEXT.talkTip },
    { key = "walk", default = false, text = ns.TEXT.walk, tip = ns.TEXT.walkTip, parent = "talk" },
    { key = "objects", default = false, text = ns.TEXT.objects, tip = ns.TEXT.objectsTip },
    { key = "useOn", default = false, text = ns.TEXT.useOn, tip = ns.TEXT.useOnTip },
    { key = "skull", default = false, text = ns.TEXT.skull, tip = ns.TEXT.skullTip },
    { key = "guide", default = false, text = ns.TEXT.guide, tip = ns.TEXT.guideTip },
    { key = "hearth", default = false, text = ns.TEXT.hearth, tip = ns.TEXT.hearthTip },
    { key = "items", default = false, text = ns.TEXT.items, tip = ns.TEXT.itemsTip },
    { key = "take", default = false, text = ns.TEXT.take, tip = ns.TEXT.takeTip,
      header = ns.TEXT.questsHeader, headerTip = ns.TEXT.questsHeaderTip },
    { key = "handin", default = false, text = ns.TEXT.handin, tip = ns.TEXT.handinTip },
    { key = "rewards", default = false, text = ns.TEXT.rewards, tip = ns.TEXT.rewardsTip, parent = "handin" },
    { key = "gossip", default = false, text = ns.TEXT.gossip, tip = ns.TEXT.gossipTip },
    { key = "leave", default = false, text = ns.TEXT.leave, tip = ns.TEXT.leaveTip },
    { key = "lootAll", default = false, text = ns.TEXT.lootAll, tip = ns.TEXT.lootAllTip,
      header = ns.TEXT.errandsHeader, headerTip = ns.TEXT.errandsHeaderTip },
    { key = "equipUpgrades", default = false, text = ns.TEXT.equipUpgrades, tip = ns.TEXT.equipUpgradesTip },
    { key = "rolls", default = false, text = ns.TEXT.rolls, tip = ns.TEXT.rollsTip },
    { key = "cinematics", default = false, text = ns.TEXT.cinematics, tip = ns.TEXT.cinematicsTip },
    { key = "follow", default = "off", text = ns.TEXT.follow, tip = ns.TEXT.followTip,
      choices = { { "on", ns.TEXT.followOn }, { "paused", ns.TEXT.followPaused }, { "off", ns.TEXT.followOff } },
      header = ns.TEXT.guideHeader, headerTip = ns.TEXT.guideHeaderTip },
    { key = "party", default = false, text = ns.TEXT.party, tip = ns.TEXT.partyTip },
    { key = "showGuide", default = false, text = ns.TEXT.showGuide, tip = ns.TEXT.showGuideTip },
    { key = "gather", default = false, text = ns.TEXT.gather, tip = ns.TEXT.gatherTip },
    { key = "classQuests", default = false, text = ns.TEXT.classQuests, tip = ns.TEXT.classQuestsTip },
    { key = "showArrow", default = false, text = ns.TEXT.showArrow, tip = ns.TEXT.showArrowTip },
    { key = "mapPin", default = false, text = ns.TEXT.mapPin, tip = ns.TEXT.mapPinTip },
    { key = "icons", default = false, text = ns.TEXT.icons, tip = ns.TEXT.iconsTip },
    { key = "ahead", default = 10, min = 1, max = 20, step = 1, text = ns.TEXT.ahead, tip = ns.TEXT.aheadTip },
    { key = "guidesButton", text = ns.TEXT.guidesButton, tip = ns.TEXT.guidesButtonTip,
      button = function() ns.Guarded(ns.Guides.Open) end },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before the key lent them (Key.lua)
    { key = "lootLent", default = {} },   -- Loot's switches as they were before Take all loot set them (Errands.lua)
    { key = "keyGiven", default = false }, -- the key was given its first key (Key.lua)
}
-- The switches of the guide over the world: drawn anew; the guide's targets also change what the key wants; the quest
-- givers' switches and those of what is on the way are read when they are needed.
local VIEW = { showGuide = true, showArrow = true, mapPin = true, icons = true, ahead = true }
local QUESTS = { take = true, handin = true, rewards = true, gossip = true, leave = true, equipUpgrades = true,
                 rolls = true, cinematics = true, lootLent = true }
-- Nothing of the module is wanted in the settings in use: it rests until a switch is on again, as a module stood down
-- but for good reason: ns.off is what every part of it asks. The guide's run goes on knowing where it is, so that it
-- catches up after.
local function Idle()
    if ns.Guide.State() ~= "off" then return false end
    for _, option in ipairs(OPTIONS) do
        if option.text and option.default == false and ns.options[option.key] then return false end
    end
    return true
end

local resting = false
local function Rest(on)
    if on == resting or (ns.off and not resting) then return end
    resting = on
    if on then
        ns.off = true
        ns.Steps.GiveBack()
        ns.Guides.GiveBack()
        ns.Key.GiveBack()
        ns.Party.GiveBack()
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

-- Another profile: what depends on which it is follows, also where no setting differs between the two.
local function Moved()
    Rest(Idle())
    ns.Guarded(ns.Key.First)
    if ns.off then return end
    ns.Guarded(ns.Guide.CheckSoon)
    ns.Guarded(ns.Steps.Update)
end

Core.Options(ns.name, OPTIONS, { moved = Moved, changed = function(key)
    Rest(Idle())
    if ns.off then return end
    if VIEW[key] then
        ns.Guarded(ns.Steps.Update)
    elseif key == "lootAll" then
        ns.Guarded(ns.Errands.Update)
    elseif key == "party" then
        ns.Guarded(ns.Guide.Reread) -- read together with the party or alone: its steps numbered anew
        ns.Guarded(ns.Guide.CheckSoon)
    elseif key == "gather" or key == "classQuests" then
        ns.Guarded(ns.Guide.CheckSoon) -- the steps of the professions or a class quest come or go: the view with them
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
    ns.Party.GiveBack()
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
    ns.Party.Start()
    -- A change of the guide: drawn anew; what the key wants follows; the party told where you are.
    ns.Guide.Watch(ns.Steps.Update)
    ns.Guide.Watch(ns.Key.Refresh)
    ns.Guide.Watch(ns.Party.Tell)
    ns.Steps.Update()
    if Idle() then Rest(true) end
end

Core.Command("guides", ns.TEXT.command, function() ns.Guarded(ns.Guides.Open) end)
Core.Command("key", ns.TEXT.keyCommand, function() ns.Guarded(ns.Key.Check) end)

-- Speed Leveling on or off, as a quick switch for a view that gathers them (Core.Offer: the minimap's satchel): the box
-- at the foot of the bags in another place, the profile Speedleveling or the one used before. Offered while the module
-- rests too: that is how it comes back.
Core.Offer("speedleveling", {
    title = ns.TEXT.switchTitle, icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath",
    State = function()
        if not ns.options or (ns.off and not resting) then return nil end
        return Core.Profiles.Leveling() and "on" or "off"
    end,
    Tip = function() return ns.TEXT.switchTip end,
    Click = function(mouse)
        if mouse ~= "RightButton" then Core.Profiles.SetLeveling(not Core.Profiles.Leveling()) end
    end,
})
