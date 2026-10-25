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
--    Quests.lua  what a quest giver does for your guide
--    Steps.lua   the guide over the world
--    Arrow.lua   the way to the guide's place, a part of its own
--    Icons.lua   the items to use and the names to target, over the guide
--    Guides.lua  the window of the guides kept
-------------------------------------------------------------------------------
local Core = SaneUI.Core
ns.title = "Speed Leveling"
Core.NewModule(ADDON, "SpeedLeveling", ns)

ns.TEXT = {
    binding = "Loot, talk, pick up, attack, find and mark, use",
    hint = "Speed Leveling: give it a key in Esc > Options > Keybindings, under Sane UI.",
    objects = "Quest objects",
    objectsTip = "A thing of the world your quests or your guide want, in front of you, is picked up, opened or used, as a right click on it does: a quest's chest or plant, what an item to loot comes from, the board a quest is handed in to. The game's interact key finds it and is switched on for it.",
    loot = "Loot first",
    lootTip = "A corpse with loot beside you is opened before anything else, as a right click on it does; what is taken is up to the loot window. The game's interact key is switched on for it, and put back as it was when this, Talk to NPCs and Quest objects are off.",
    skull = "Skull on what is found",
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
    questsHeaderTip = "What talking to a quest giver does for your guide. Hold Shift while you talk to do it yourself.",
    take = "Take the guide's quests",
    takeTip = "The quests the steps at hand of your guide take (and those of the step after them) are accepted as the quest giver offers them.",
    handin = "Hand in the guide's quests",
    handinTip = "The quests the steps at hand hand in are handed in: the reward the guide names, else the only one. With several rewards to choose from and none named, the choice is yours.",
    gossip = "Choose the guide's talk",
    gossipTip = "Where a step names what to say to an NPC (a gossip option), it is chosen.",

    -- The guide over the world (Guide.lua, Steps.lua, Guides.lua).
    guideHeader = "Guide",
    guideHeaderTip = "Your leveling guide over the world: the zone, the steps at hand and the next ones.",
    showGuide = "Show the guide",
    showGuideTip = "The guide's steps straight on the world, where Edit Mode puts them. A click on a step at hand skips it, a right click goes back one; the wheel over the listed steps scrolls through the whole guide, done steps too; a right click on a listed step goes to it; a right click on the zone chooses the guide to follow.",
    showArrow = "Show the arrow",
    showArrowTip = "The way to the guide's place, a part of its own placed in Edit Mode: the leather ring turned the way to go, in it a picture of what to do there, under it what to do and how far, and the time to get there.",
    icons = "Targets and items over the guide",
    iconsTip = "The items the guide's steps want used (the Hearthstone, quest items) and the NPCs and creatures to target, as icons in a row over the guide's top: a click uses the item or targets the name. Changed out of a fight only: the game holds such buttons in one.",
    ahead = "Steps listed ahead",
    aheadTip = "How many steps the list under those at hand shows; the wheel scrolls it through the whole guide.",
    guidesButton = "Guides",
    guidesButtonTip = "The guides kept: paste the import string of the guides you bought, or a guide's text, and choose the one to follow.",
    guideView = "Guide",
    guides = "Guides",
    step = "Step %d",
    progress = "%d/%d \194\183 %d%%",
    paste = "Paste a guide...",
    pasteHint = "Or paste a guide's text here (Ctrl+V), then Read.",
    readButton = "Read",
    read = "Kept %d: %s.",
    unread = "%d lines could not be read and are left out:",
    noneRead = "No guide was found in that text.",
    noneKept = "No guide is kept yet: paste the import string of your bought guides at the right, or a guide's text, then Read.",
    forget = "Forget the guide %s?",
    command = "the guides kept: paste the import string of your bought guides or a guide's text, choose the one to follow",
    unnamed = "Guide",
    -- The import string of bought guides (Unlock.lua, Guides.lua).
    stringTitle = "The guides you bought: their import string",
    stringHint = "Click here and paste it (Ctrl+V): it is opened for the account you play.",
    pastedString = "%d characters pasted.",
    notString = "That is no import string: paste a guide's text into the box below instead.",
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
    { key = "loot", default = true, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
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
    { key = "gossip", default = true, text = ns.TEXT.gossip, tip = ns.TEXT.gossipTip },
    { key = "showGuide", default = true, text = ns.TEXT.showGuide, tip = ns.TEXT.showGuideTip,
      header = ns.TEXT.guideHeader, headerTip = ns.TEXT.guideHeaderTip },
    { key = "showArrow", default = true, text = ns.TEXT.showArrow, tip = ns.TEXT.showArrowTip },
    { key = "icons", default = true, text = ns.TEXT.icons, tip = ns.TEXT.iconsTip },
    { key = "ahead", default = 5, min = 0, max = 12, step = 1, text = ns.TEXT.ahead, tip = ns.TEXT.aheadTip },
    { key = "guidesButton", text = ns.TEXT.guidesButton, tip = ns.TEXT.guidesButtonTip,
      button = function() ns.Guarded(ns.Guides.Open) end },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before the key lent them (Key.lua)
    { key = "told", default = false },    -- told once how to give the key a key (Key.lua)
}
-- The switches of the guide over the world: drawn anew; the guide's targets also change what the key wants; the quest
-- givers' switches are read as a quest giver talks.
local VIEW = { showGuide = true, showArrow = true, icons = true, ahead = true }
local QUESTS = { take = true, handin = true, gossip = true }
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if VIEW[key] then
        ns.Guarded(ns.Steps.Update)
    elseif key == "guide" then
        ns.Guarded(ns.Wanted.Changed)
        ns.Guarded(ns.Steps.Update)
    elseif not QUESTS[key] then
        ns.Guarded(ns.Key.Update)
    end
end })

-- Standing down: no override binding of ours on your keys, the game's settings as they were, the guide hidden.
function ns.GiveBack()
    ns.Guide.Stop()
    ns.Steps.GiveBack()
    ns.Guides.GiveBack()
    ns.Key.GiveBack()
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
    -- A change of the guide: drawn anew; what the key wants follows.
    ns.Guide.Watch(ns.Steps.Update)
    ns.Guide.Watch(ns.Key.Refresh)
    ns.Steps.Update()
end

Core.Command("guides", ns.TEXT.command, function() ns.Guarded(ns.Guides.Open) end)
