# Sane UI: Speed Leveling

**Status:** built · **Since:** 2026-10-25 · **Addon:** `SaneUI_SpeedLeveling` · **Game:** WoW: Forever (interface 16001)

## TL;DR
One key for questing, pressed again and again. Each press does the first of these that is due:

1. **Loot:** a corpse with loot beside you is looted, all of it.
2. **Fight:** your target is a living foe your quests want (or you are in a fight): it gets a skull and is attacked.
3. **Talk:** your target is a quest NPC: you talk to it.
4. **Find:** else the key looks around you for what your quests and your leveling guide want, targets the first it
   finds, puts a skull over it, and starts the attack on a foe.

So: kill, press to loot, press to find the next one, press to attack; walk up to the NPC it found, press to talk.

## How to use
- **Give it a key:** Esc > Options > Keybindings, under *Sane UI*: *Loot, find and mark, then attack or talk*. Any
  key will do (E, for one). Until it has one, the module says so once in chat.
- **Switch it on or off:** tick or untick *Speed Leveling* under *Sane UI* in the game's addon list.
- **Its page** in Sane UI's options, *Speed Leveling*:

| Setting | Default | What it does |
| --- | --- | --- |
| Loot first | on | A corpse with loot beside you is looted before anything is looked for. The game's interact key (`softTargetInteract`) and its auto loot (`autoLootDefault`) are switched on for it, and put back as they were when this goes off |
| Skull on what is found | on | What the key finds gets a skull. In a group everybody sees it; in a raid only an assistant may mark |
| Talk to NPCs | on | A quest NPC the key found is talked to at the next press. Off: the key looks on for the next thing |
| Your leveling guide's targets | on | What the step at hand of a leveling guide Sane UI knows names comes first, while that guide is loaded |

## What it looks for
In this order; the key takes the first it finds around you (as far as the game shows creatures by name):

1. What the step at hand of your leveling guide names: its creatures, then its NPCs (a guide Sane UI knows,
   `Core.Neighbours.Targets("guide")`, while it is loaded).
2. The creatures of your quests' open objectives, from Core's data (the sets *Quests* and *NPCs*): those to kill,
   then those that drop an item to loot (*Drops*: the likeliest three an item).
3. Creatures the game itself marks for a quest of yours on their nameplates (`Core.UnitQuest`): what Core's data
   does not know.
4. The NPCs your finished quests are handed in to, of your side.

Core's names are English: on a client in another language the key finds what 1 and 3 name.

## How it works
An addon may target, mark, attack and interact only by the game's secure ways and on a key press, so every choice
is made by those, in a fight too (`Key.lua`):

- **A state driver** (the game's `RegisterStateDriver`) reads the macro conditions five times a second:
  `[@softinteract,exists,dead]` (a corpse the game's interact key would use: one with loot), a living foe in a
  fight, a living foe, a living friend, or none of these.
- **The header** (`SaneUISpeedLevelingKey`, `SecureHandlerAttributeTemplate`) then puts that mode's action on the
  key's keys as override bindings of its own, above other overrides: *Interact With Target* (`INTERACTTARGET`, the
  game's own) to loot or talk, the button *Fight* (`/tm [harm,nodead] !8`, `/startattack`) or the button *Find*.
  A foe or friend counts only when the module said it is wanted (the attribute `wanted`, set out of a fight at every
  change of target and of the quests); in a fight every living foe is fought.
- **Find** (`SaneUISpeedLevelingFind`, the key's own binding in `Bindings.xml`) runs a macro: `/cleartarget`, then
  `/targetexact [noexists][dead] <name>` for each wanted name, the first first (a dead one is passed over; up to
  1023 characters), `/cleartarget [dead]`, `/tm [exists] !8`, `/startattack [harm,nodead]`. It is written out of a
  fight, anew the moment before each press (`PreClick`) and when the quests change; in a fight the last one runs.
- **Nothing else is automatic:** each press does one thing, the player's.

## Files
| File | What it holds |
| --- | --- |
| `SpeedLeveling.lua` | The module's table, words, settings (`Core.Options`), standing down |
| `Wanted.lua` | What is wanted, by name and in order: `Wanted.Names()`, `Wanted.Unit(unit)`, read anew when the quest log changes |
| `Key.lua` | The key: the buttons Find and Fight, the header and its snippets, the state driver, the game's settings for Loot first |
| `Bindings.xml` | The key in the game's key bindings: a click on Find |

## Errors
A failure stands the module down (`ns.GiveBack`): the state driver stops, no override binding of ours stays on your
keys, the macros are emptied, and the interact key and auto loot go back as they were (out of a fight; in one, once
it is over). The key then does nothing until the next `/reload`.
