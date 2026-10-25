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
--  again and again: it opens the loot of the corpse beside you, picks up what
--  your quests want beside you, finds what your quests and your leveling guide
--  want around you, puts a skull on it, and attacks it or talks to it; it
--  hearths when your guide says so, and uses a quest item when nothing wanted
--  is around. And your leveling guide over the world, its steps at hand and
--  the next ones (Saneroki, 2026-10-25): the guide Sane UI knows while it is
--  loaded, else a guide pasted as text.
--    Format.lua  a guide written as text, read into our own shape
--    Run.lua     a guide read from text, run: where you are, what is done
--    Guide.lua   the guide shown: the known guide's, else ours; its picture
--    Wanted.lua  what is wanted around you, by name: your guide's step, your
--                quests' open objectives (Core's data), the creatures the game
--                marks for your quests, the NPCs your finished quests go to;
--                the things of the world your quests want, by ID
--    Items.lua   what the key uses: the hearth, one quest item
--    Key.lua     the key: what one press does now, by the game's secure ways
--    Steps.lua   the guide over the world
--    Guides.lua  the window of the guides kept as text
-------------------------------------------------------------------------------
local Core = SaneUI.Core
ns.title = "Speed Leveling"
Core.NewModule(ADDON, "SpeedLeveling", ns)

ns.TEXT = {
    binding = "Loot, pick up, find and mark, attack or talk, use",
    objects = "Quest objects",
    objectsTip = "A thing of the world your quests want, beside you, is picked up, opened or used, as a right click on it does: a quest's chest or plant, what an item to loot comes from, the board a quest is handed in to. The game's interact key finds it and is switched on for it.",
    loot = "Loot first",
    lootTip = "A corpse with loot beside you is opened before anything is looked for, as a right click on it does; what is taken is up to the loot window. The game's interact key is switched on for it, and put back as it was when this is off.",
    skull = "Skull on what is found",
    skullTip = "What the key finds gets a skull over its head. In a group it shows for everybody; in a raid only an assistant may mark.",
    talk = "Talk to NPCs",
    talkTip = "A quest NPC the key found is talked to at the next press, as the game's Interact With Target does. Off: the key looks on for the next thing.",
    guide = "Your leveling guide's targets",
    guideTip = "What the steps at hand of your guide want killed, talked to or used come first: the leveling guide Sane UI knows while it is loaded, else the guide you pasted.",
    hearth = "Hearthstone",
    hearthTip = "When your leveling guide's step says to hearth, the key uses your Hearthstone (a shaman's Astral Recall while the stone cools down), once nothing is to be looted, picked up, fought or talked to.",
    items = "Quest items",
    itemsTip = "When the key finds nothing wanted around you, it uses one item: of your guide's step first, then a quest item of your quest log, the first in your bags that is ready. Away from its place the game says so and nothing is used; one for a creature or a spot puts the game's targeting hand on the cursor.",

    -- The guide over the world (Guide.lua, Steps.lua, Guides.lua).
    guideHeader = "Guide",
    guideHeaderTip = "Your leveling guide over the world: the zone, the steps at hand and the next ones.",
    showGuide = "Show the guide",
    showGuideTip = "The guide's steps straight on the world, where Edit Mode puts them, with an arrow to the step's place. A click on a step at hand skips it, a right click goes back one; the wheel over the next steps scrolls them, a double click goes to one; a right click on the zone or the next steps opens your leveling guide's own menu (or chooses a pasted guide).",
    knownGuide = "Your leveling guide's own guide",
    knownGuideTip = "While the leveling guide Sane UI knows is loaded, its guide is shown and followed, the one it has loaded for you. Off: the guide you pasted.",
    knownWindow = "Hide its own window",
    knownWindowTip = "While its guide is shown here, that guide's own window is made unseen; it comes back as it was when this is off.",
    knownBoxes = "Gather its targets and items",
    knownBoxesTip = "While its guide is shown here, that guide's boxes of targets and items stand in a row under it, so they need no placing; they go back where they were when this is off. Placed out of a fight: the game holds them in one.",
    ahead = "Steps listed ahead",
    aheadTip = "How many of the next steps stand under those at hand.",
    guidesButton = "Guides",
    guidesButtonTip = "The guides kept as text: paste a guide's text to keep it, choose the one to follow.",
    guideView = "Guide",
    guides = "Guides",
    step = "Step %d",
    progress = "%d/%d \194\183 %d%%",
    knownShown = "Your leveling guide's own guide is shown",
    paste = "Paste a guide...",
    pasteHint = "Paste a guide's text here (Ctrl+V), then Read.",
    readButton = "Read",
    read = "Kept %d: %s.",
    unread = "%d lines could not be read and are left out:",
    noneRead = "No guide was found in that text.",
    noneKept = "No guide is kept yet: paste a guide's text at the right, then Read.",
    forget = "Forget the guide %s?",
    command = "the guides kept as text: paste one, choose the one to follow",
    unnamed = "Guide",
    -- Our words for a line a guide gives none (Run.lua).
    quest = "Quest %d",
    item = "Item %d",
    spell = "Spell %d",
    take = "Accept %s",
    handin = "Hand in %s",
    level = "Reach level %d",
    learn = "Learn %s",
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
    shop = "Visit the vendor",
    trainer = "Visit the trainer",
    arrive = "Get there",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the key is the game's own again, the guide hidden"

local OPTIONS = {
    { key = "loot", default = true, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
    { key = "objects", default = true, text = ns.TEXT.objects, tip = ns.TEXT.objectsTip },
    { key = "skull", default = true, text = ns.TEXT.skull, tip = ns.TEXT.skullTip },
    { key = "talk", default = true, text = ns.TEXT.talk, tip = ns.TEXT.talkTip },
    { key = "guide", default = true, text = ns.TEXT.guide, tip = ns.TEXT.guideTip },
    { key = "hearth", default = true, text = ns.TEXT.hearth, tip = ns.TEXT.hearthTip },
    { key = "items", default = true, text = ns.TEXT.items, tip = ns.TEXT.itemsTip },
    { key = "showGuide", default = true, text = ns.TEXT.showGuide, tip = ns.TEXT.showGuideTip,
      header = ns.TEXT.guideHeader, headerTip = ns.TEXT.guideHeaderTip },
    { key = "knownGuide", default = true, text = ns.TEXT.knownGuide, tip = ns.TEXT.knownGuideTip },
    { key = "knownWindow", default = true, text = ns.TEXT.knownWindow, tip = ns.TEXT.knownWindowTip,
      parent = "knownGuide" },
    { key = "knownBoxes", default = true, text = ns.TEXT.knownBoxes, tip = ns.TEXT.knownBoxesTip,
      parent = "knownGuide" },
    { key = "ahead", default = 5, min = 0, max = 12, step = 1, text = ns.TEXT.ahead, tip = ns.TEXT.aheadTip },
    { key = "guidesButton", text = ns.TEXT.guidesButton, tip = ns.TEXT.guidesButtonTip,
      button = function() ns.Guarded(ns.Guides.Open) end },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before Loot first, Quest objects (Key.lua)
    { key = "told", default = false },    -- told once how to give the key a key (Key.lua)
}
-- The switches of the guide over the world: drawn anew; the known guide's switch also changes what the key wants.
local VIEW = { showGuide = true, knownWindow = true, knownBoxes = true, ahead = true }
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if VIEW[key] then
        ns.Guarded(ns.Steps.Update)
    elseif key == "guide" or key == "knownGuide" then
        ns.Guarded(ns.Wanted.Changed)
        ns.Guarded(ns.Steps.Update)
    else
        ns.Guarded(ns.Key.Update)
    end
end })

-- Standing down: no override binding of ours on your keys, the game's settings as they were, the guide hidden and
-- the known guide's own window as it was.
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
    ns.Guide.Start()
    ns.Wanted.Start()
    ns.Key.Start()
    -- A change of the guide: drawn anew; what the key wants follows.
    ns.Guide.Watch(ns.Steps.Update)
    ns.Guide.Watch(ns.Key.Refresh)
    ns.Steps.Update()
end

Core.Command("guides", ns.TEXT.command, function() ns.Guarded(ns.Guides.Open) end)
