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
--  is around.
--    Wanted.lua  what is wanted around you, by name: your guide's step, your
--                quests' open objectives (Core's data), the creatures the game
--                marks for your quests, the NPCs your finished quests go to;
--                the things of the world your quests want, by ID
--    Items.lua   what the key uses: the hearth, one quest item
--    Key.lua     the key: what one press does now, by the game's secure ways
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
    guideTip = "What the step at hand of a leveling guide Sane UI knows wants killed, talked to or used comes first, while that guide is loaded.",
    hearth = "Hearthstone",
    hearthTip = "When your leveling guide's step says to hearth, the key uses your Hearthstone (a shaman's Astral Recall while the stone cools down), once nothing is to be looted, picked up, fought or talked to.",
    items = "Quest items",
    itemsTip = "When the key finds nothing wanted around you, it uses one item: of your guide's step first, then a quest item of your quest log, the first in your bags that is ready. Away from its place the game says so and nothing is used; one for a creature or a spot puts the game's targeting hand on the cursor.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the key is the game's own again"

local OPTIONS = {
    { key = "loot", default = true, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
    { key = "objects", default = true, text = ns.TEXT.objects, tip = ns.TEXT.objectsTip },
    { key = "skull", default = true, text = ns.TEXT.skull, tip = ns.TEXT.skullTip },
    { key = "talk", default = true, text = ns.TEXT.talk, tip = ns.TEXT.talkTip },
    { key = "guide", default = true, text = ns.TEXT.guide, tip = ns.TEXT.guideTip },
    { key = "hearth", default = true, text = ns.TEXT.hearth, tip = ns.TEXT.hearthTip },
    { key = "items", default = true, text = ns.TEXT.items, tip = ns.TEXT.itemsTip },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before Loot first, Quest objects (Key.lua)
    { key = "told", default = false },    -- told once how to give the key a key (Key.lua)
}
Core.Options(ns.name, OPTIONS, { changed = function(key)
    if key == "guide" then
        ns.Guarded(ns.Wanted.Changed)
    else
        ns.Guarded(ns.Key.Update)
    end
end })

-- Standing down: no override binding of ours on your keys, the game's settings as they were.
function ns.GiveBack()
    ns.Key.GiveBack()
end

function ns.OnLoad()
    ns.options = Core.Settings(ns.name)
end

function ns.OnLogin()
    ns.Wanted.Start()
    ns.Key.Start()
end
