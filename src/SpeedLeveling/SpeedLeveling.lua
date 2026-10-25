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
--  again and again: it loots the corpse beside you, finds what your quests and
--  your leveling guide want around you, puts a skull on it, and attacks it or
--  talks to it.
--    Wanted.lua  what is wanted around you, by name: your guide's step, your
--                quests' open objectives (Core's data), the creatures the game
--                marks for your quests, the NPCs your finished quests go to
--    Key.lua     the key: what one press does now, by the game's secure ways
-------------------------------------------------------------------------------
local Core = SaneUI.Core
ns.title = "Speed Leveling"
Core.NewModule(ADDON, "SpeedLeveling", ns)

ns.TEXT = {
    binding = "Loot, find and mark, then attack or talk",
    loot = "Loot first",
    lootTip = "A corpse with loot beside you is looted before anything is looked for: the game's interact key and its auto loot are switched on for it, and put back as they were when this is off.",
    skull = "Skull on what is found",
    skullTip = "What the key finds gets a skull over its head. In a group it shows for everybody; in a raid only an assistant may mark.",
    talk = "Talk to NPCs",
    talkTip = "A quest NPC the key found is talked to at the next press, as the game's Interact With Target does. Off: the key looks on for the next thing.",
    guide = "Your leveling guide's targets",
    guideTip = "What the step at hand of a leveling guide Sane UI knows wants killed or talked to comes first, while that guide is loaded.",
}

-- What is told when the module stands down (Core's StandDown).
ns.GIVEN_BACK = "the key is the game's own again"

local OPTIONS = {
    { key = "loot", default = true, text = ns.TEXT.loot, tip = ns.TEXT.lootTip },
    { key = "skull", default = true, text = ns.TEXT.skull, tip = ns.TEXT.skullTip },
    { key = "talk", default = true, text = ns.TEXT.talk, tip = ns.TEXT.talkTip },
    { key = "guide", default = true, text = ns.TEXT.guide, tip = ns.TEXT.guideTip },
    { key = "foundCVars", default = {} }, -- the game's settings as they were before the switch Loot first (Key.lua)
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
