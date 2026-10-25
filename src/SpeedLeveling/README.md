# Sane UI: Speed Leveling

**Status:** built · **Since:** 2026-10-25 · **Addon:** `SaneUI_SpeedLeveling` · **Game:** WoW: Forever (interface 16001)

## TL;DR
One key for questing, pressed again and again. Each press does the first of these that is due:

1. **Loot:** a corpse with loot beside you is opened, as a right click on it does. What is taken is up to the
   game's loot window (and later Sane UI's loot module).
2. **Fight in a fight:** your target is a living foe and you are in a fight: it gets a skull and is attacked.
3. **Pick up:** a thing of the world your quests want is beside you (a quest's chest or plant, the crate an item to
   loot comes from, the board a quest is handed in to): it is picked up, opened or used, as a right click does.
4. **Fight:** your target is a living foe your quests want: it gets a skull and is attacked.
5. **Talk:** your target is a quest NPC: you talk to it.
6. **Hearth:** your leveling guide's step says to hearth: your Hearthstone (a shaman's Astral Recall while the stone
   cools down).
7. **Find:** else the key looks around you for what is wanted, targets the first it finds, puts a skull over it, and
   starts the attack on a foe. When it finds nothing wanted, it uses one quest item instead.

So: kill, press to loot, press to find the next one, press to attack; walk up to the NPC it found, press to talk;
walk over the quest's plant, press to pick it.

## How to use
- **Give it a key:** Esc > Options > Keybindings, under *Sane UI*: *Loot, pick up, find and mark, attack or talk,
  use*. Any key will do (E, for one). Until it has one, the module says so once in chat.
- **Switch it on or off:** tick or untick *Speed Leveling* under *Sane UI* in the game's addon list.
- **Its page** in Sane UI's options, *Speed Leveling*:

| Setting | Default | What it does |
| --- | --- | --- |
| Loot first | on | A corpse with loot beside you is opened before anything is looked for. The game's interact key (`softTargetInteract`) is switched on for it, and put back as it was when this and Quest objects are off |
| Quest objects | on | A thing of the world your quests want, beside you, is picked up, opened or used. It needs the game's interact key too |
| Skull on what is found | on | What the key finds gets a skull. In a group everybody sees it; in a raid only an assistant may mark |
| Talk to NPCs | on | A quest NPC the key found is talked to at the next press. Off: the key looks on for the next thing |
| Your leveling guide's targets | on | What the step at hand of a leveling guide Sane UI knows names to kill, talk to or use comes first, while that guide is loaded |
| Hearthstone | on | When the guide's step says to hearth, the key hearths once nothing is to be looted, picked up, fought or talked to |
| Quest items | on | When the key finds nothing wanted around you, it uses one item: the guide's step's first, then a quest item of your quest log; the first in your bags that is ready |

## What it looks for
In this order, the NPCs before the creatures (Saneroki, 2026-10-25); the key takes the first it finds around you (as
far as the game shows creatures by name):

1. The NPCs the step at hand of your leveling guide names: quest givers and takers (a guide Sane UI knows,
   `Core.Neighbours.Targets("guide")`, while it is loaded).
2. The NPCs your finished quests are handed in to, of your side.
3. The creatures the guide's step names.
4. The creatures of your quests' open objectives, from Core's data (the sets *Quests* and *NPCs*): those to kill,
   then those that drop an item to loot (*Drops*: the likeliest three an item).
5. Creatures the game itself marks for a quest of yours on their nameplates (`Core.UnitQuest`): what Core's data
   does not know.

Core's names are English: on a client in another language the key finds what 1, 3 and 5 name.

**The things of the world** go by the game's object ID, on any client: those of your quests' open objectives, those
an item to loot comes from (*Drops*), and those a finished quest is handed in to, of your side. The game tells no
addon where they are; the key knows the one its interact key would use (`PLAYER_SOFT_INTERACT_CHANGED`, the soft
target's GUID), so a thing counts once you stand beside it.

**What it uses** (`Items.lua`): the Hearthstone (item 6948) when the guide's step lists it (or a shaman's Astral
Recall, spell 556), in your bags and off its cooldown; else, when nothing is found, the first ready item of the
guide's step's items (`Core.Neighbours.Uses("guide")`) and of the game's own quest items of your quests not yet done
(`GetQuestLogSpecialItemInfo`, the item a quest shows as a button). One a press: two would be used at once. Such an
item is often for a place or a creature: away from it the game says so and nothing is used; one that wants a target
puts the game's targeting hand on the cursor. An item to use on a creature you found is the player's click.

## How it works
An addon may target, mark, attack, interact and use items only by the game's secure ways and on a key press, so
every choice is made by those, in a fight too (`Key.lua`):

- **A state driver** (the game's `RegisterStateDriver`) reads the macro conditions five times a second:
  `[@softinteract,exists,dead]` (a corpse the game's interact key would use: one with loot), a living foe in a
  fight, a living foe, a living friend, or none of these.
- **The header** (`SaneUISpeedLevelingKey`, `SecureHandlerAttributeTemplate`) then puts that mode's action on the
  key's keys as override bindings of its own, above other overrides: *Interact With Target* (`INTERACTTARGET`, the
  game's own) to loot, pick up or talk, the button *Fight* (`/tm [harm,nodead] !8`, `/startattack`) or the button
  *Find*. A foe or friend counts only when the module said it is wanted (the attribute `wanted`), a thing only when
  it said the interact key's thing is a wanted one (the attribute `object`); both are set out of a fight, at every
  change of target, of the interact key's thing and of the quests. In a fight every living foe is fought.
- **Find** (`SaneUISpeedLevelingFind`, the key's own binding in `Bindings.xml`) runs a macro: the hearth alone when
  it is due; else `/cleartarget`, then `/targetexact [noexists][dead] <name>` for each wanted name, the first first
  (a dead one is passed over; up to 1023 characters), `/cleartarget [dead]`, `/tm [exists] !8`,
  `/startattack [harm,nodead]`, and with an item ready `/stopmacro [exists]` and `/use item:<ID>`. It is written out
  of a fight, anew the moment before each press (`PreClick`) and when the quests change; as a fight begins
  (`PLAYER_REGEN_DISABLED`) without the hearth and the item, and in a fight the last one runs.
- **Nothing else is automatic:** each press does one thing, the player's.

## Files
| File | What it holds |
| --- | --- |
| `SpeedLeveling.lua` | The module's table, words, settings (`Core.Options`), standing down |
| `Wanted.lua` | What is wanted, by name and in order (`Wanted.Names()`, `Wanted.Unit(unit)`), and the things of the world by ID (`Wanted.Object(guid)`); read anew when the quest log changes |
| `Items.lua` | What the key uses: `Items.Hearth(items, spells)`, `Items.Pick(items)`, each a macro line or nil |
| `Key.lua` | The key: the buttons Find and Fight, the header and its snippets, the state driver, Find's macro (`Key.Find()`), the game's settings for Loot first and Quest objects |
| `Bindings.xml` | The key in the game's key bindings: a click on Find |

## Errors
A failure stands the module down (`ns.GiveBack`): the state driver stops, no override binding of ours stays on your
keys, the macros are emptied, and the interact key goes back as it was (out of a fight; in one, once it is over).
The key then does nothing until the next `/reload`.
