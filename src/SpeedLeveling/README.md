# Sane UI: Speed Leveling

**Status:** built · **Since:** 2026-10-25 · **Addon:** `SaneUI_SpeedLeveling` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
One key for questing, pressed again and again, and your leveling guide over the world, run by Sane UI itself. It
needs no other addon: it reads leveling guides written as text (the guides you bought, opened for your own account,
and guides you paste) and runs them with an engine of its own.

Each press of the key does the first of these that is due (the order the game's own gamepad interact button keeps):

1. **Loot:** a corpse with loot beside you is opened, as a right click does. What is taken is up to the game's loot
   window (and later Sane UI's loot module).
2. **Fight in a fight:** your target is a living foe and you are in a fight: it gets a skull and is attacked.
3. **Use the step's item on your target:** out of a fight, your target is the one a step's item is used on, as the
   step's own words say — a corpse ("use the dust on their corpses"), or the creature or NPC they name ("use the cage
   on a worg pup"): the item is used on it. A friendly NPC only once it is within the item's reach; never a creature
   the words say to weaken first, and not again on a target the game refused the item on.
4. **Talk:** a friendly NPC stands right in front of you (the one the game's interact key would pick): you talk to
   it, with one press. At a quest giver, your guide's quests are taken and handed in (below).
5. **Pick up:** a thing of the world your quests or your guide want is in front of you (a quest's chest or plant, the
   crate an item to loot comes from, the board a quest is handed in to): it is picked up, opened or used.
6. **Fight:** your target is a living foe that is wanted: it gets a skull and is attacked.
7. **Talk to a wanted NPC:** your target is a quest NPC: you talk to it. Far away, the game's own Click-to-Move runs
   you to it first (*Walk to the NPC found*).
8. **Hearth:** your guide's step says to hearth: your Hearthstone (a shaman's Astral Recall while the stone cools
   down).
9. **Find:** else the key looks around you for what is wanted, targets the first it finds, marks it with a skull, and
   starts the attack on a foe. When it finds nothing wanted, it uses one quest item instead.

So: kill, press to loot, press to find the next one, press to attack; press to find the NPC, press again to run to
it and take its quests; walk over the quest's plant, press to pick it; press on the corpse to use the step's item.
The game lets no addon walk you to a place on the map: only to a target, by its own Click-to-Move.

**Independent (Saneroki, 2026-10-25).** The leveling guide Sane UI knows is needed for nothing: Sane UI reads only
the words of its text format and the recipe its bought guides are locked by (`Core.Neighbours.Format`,
`Core.Neighbours.Lock`, copies — nothing of the addon is called at runtime), and runs the guides itself.

## How to use
- **Give it a key:** Esc > Options > Keybindings, under *Sane UI*: *Loot, talk, pick up, attack, find and mark, use*.
  Any key will do (E, for one). Until it has one, the module says so once in chat.
- **Add your guides:** open *Guides* (`/sane guides`, or the button on the options page). Paste the **import string**
  of the guides you bought into the line at the top — it is opened for the account you are playing, and no other —
  or paste a guide's **text** into the box below and press *Read*. A character without a guide takes the first one
  whose head names its race or class.
- **Switch it on or off:** tick or untick *Speed Leveling* under *Sane UI* in the game's addon list.
- **Its page** in Sane UI's options, *Speed Leveling*:

| Setting | Default | What it does |
| --- | --- | --- |
| Loot first | on | A corpse with loot beside you is opened before anything is looked for. The game's interact key (`softTargetInteract`) is switched on for it |
| Talk to NPCs | on | A friendly NPC right in front of you is talked to at once (after a corpse to loot); a quest NPC the key found, at the next press. Off: the key looks on |
| Walk to the NPC found | on | While a quest NPC the key found is your target, the game's Click-to-Move (`autointeract`) is lent, so the key runs you to it and talks; put back as it was when that NPC is no longer your target, and in a fight. While it is lent, a right click on the ground walks you there too |
| Use items on what is found | on | Out of a fight, a step's item is used on your target when the step's words say it is for that one (a corpse, or the creature or NPC they name); before talking and fighting |
| Quest objects | on | A thing of the world your quests or your guide want, in front of you, is picked up, opened or used. It needs the game's interact key too |
| Skull on what is found | on | What the key finds or attacks gets a skull. In a group everybody sees it; in a raid only an assistant may mark |
| Your guide's targets | on | What the steps at hand of your guide name to kill or talk to comes first |
| Hearthstone | on | When the guide's step says to hearth, the key hearths once nothing is to be looted, talked to, picked up or fought |
| Quest items | on | When the key finds nothing wanted around you, it uses one item: the guide's step's first, then a quest item of your quest log; the first in your bags that is ready |
| *Quest givers:* Take the guide's quests | on | The quests the steps at hand take (and the step after them) are accepted as the quest giver offers them. Hold Shift while you talk to do it yourself |
| Hand in the guide's quests | on | The quests the steps at hand hand in are handed in, with the reward the guide names, else the only one |
| Choose the guide's talk | on | Where a step names a gossip option, it is chosen |
| *Guide:* Show the guide | on | The guide's steps over the world (*The guide over the world*) |
| Show the arrow | on | The way to the guide's place, a part of its own placed in Edit Mode (*The arrow*) |
| Targets and items over the guide | on | The items the steps want used and the names to target, as icons over the guide's top (*The icons*) |
| Steps listed ahead | 5 | How many steps the list under those at hand shows (0 to 12); the wheel scrolls it through the whole guide |
| Guides | | Opens the window of the guides kept (also `/sane guides`) |

## What it looks for
In this order, the NPCs before the creatures (Saneroki, 2026-10-25); the key takes the first it finds around you (as
far as the game shows creatures by name):

1. The NPCs the steps at hand of your guide name (quest givers and takers; while the switch is on).
2. The NPCs your finished quests are handed in to, of your side (Core's sets *Quests* and *NPCs*), nearest first.
3. The creatures the guide's steps name.
4. Creatures the game itself marks for a quest of yours on their nameplates (`Core.UnitQuest`): they are near.
5. The creatures of your quests' open objectives, from Core's data: those to kill, then those that drop an item to
   loot (*Drops*: the likeliest three an item). Of those Core knows where they live (the set *Spawns*), only those in
   the zone you are in, nearest first, then those it knows no place of.
6. For a quest Core's data does not hold (Retail has no data yet), the creature its objective names in the game's own
   words ("Mottled Boar slain: 2/10").

Core's names are English: on a client in another language the key finds what 1, 3, 4 and 6 name.

**The things of the world** go by the game's object ID, on any client: those of your quests' open objectives, those
an item to loot comes from (*Drops*), and those a finished quest is handed in to, of your side; else by the game's
own word that a thing belongs to a quest of yours, or by its name where your guide or an objective names it. The game
tells no addon where they are; the key knows the one its interact key would use (`PLAYER_SOFT_INTERACT_CHANGED`), so a
thing counts once you stand in front of it.

**What it uses** (`Items.lua`): the Hearthstone (item 6948) when the guide's step lists it (or a shaman's Astral
Recall, spell 556), in your bags and off its cooldown; else, when nothing is found, the first ready item of the
guide's step's items and of the game's own quest items of your quests not yet done, but one the game says is in range
of what it is for. One a press.

## The guides
Speed Leveling keeps the guides for the account (`Core.Store`, each packed with the game's own deflate), and for each
character which guide it follows and where it is in each (`Core.Character`). A guide comes from one of two places,
both read by our own reader (`Format.lua`) and run by our own engine (`Run.lua`):

- **The guides you bought** (`Unlock.lua`): a bought guide of the leveling guide Sane UI knows comes as an import
  string that is locked to the buyer's account. Sane UI opens it with the BattleTag of the account you are playing
  and no other (the key is made from the tag in memory and never kept; base64 and zlib are the game's own,
  `C_EncodingUtil`), and a string bought for another account stays shut. The work runs in steps over frames
  (`Core.Steps`), so a string of megabytes does not hold the game up. No guide's text ships with Sane UI.
- **A guide pasted as text** (`Format.lua`): written in the text format the leveling guide Sane UI knows uses (its
  words for commands, step marks, colours and game tags are Core's to know, `Core.Neighbours.Format`; everything else
  is ours). A head (name, group, the guides after it, who starts with it, which games it is for), then steps, each
  with lines to do, to know or to check, each kept or left out for your side, race, class and level as the line says.

## The guide over the world
- **What it shows,** from the top, in Expressway with a thin dark outline (Saneroki's pick of font, shipped in the
  module's `Fonts/`), where Edit Mode puts it (at first at the screen's right, a little down; it grows down):
  - the guide's zone, its levels after it, and at the right how far you are (*12/84 · 14%*), a thin rule under;
  - each step at hand on a faint dark shade: *Step 12* small, its first words large (what to do), its things to do
    (*Mottled Boar slain* with *2/4* at the right and a thin bar under it, a hand-drawn tick once done), its other
    words smaller, *!* before a warning, *i* before the rest; what is done is faint;
  - the next steps greyed out, a line each with its number, fading as they go down; the wheel scrolls the list through
    every step of the guide, the done ones above (the game's tick before each). When the guide moves on, the list
    starts after the steps at hand again.
- **Names in colour,** as the guide's words mark them, in the game's own font colours: NPCs green, creatures red,
  things to loot light blue, things to pick up orange, things to buy light yellow, warnings gold.
- **No guide yet:** the view stays, its head and one line saying so (none kept, none chosen, or none of those kept
  is for this character or game); a click on that line opens *Guides*.
- **The mouse:** a click on a step at hand skips it, a right click goes back one step. The wheel over the list scrolls
  it; a double click on a listed step goes to it; a right click on it opens its menu (*Go to step*, the guides kept);
  a right click on the zone chooses the guide to follow, or *Paste a guide...*.

### The arrow
A part of its own (`Arrow.lua`), placed in Edit Mode apart from the guide (at first over the middle of the screen),
shown while the guide is and has a place to go to:

- **Sane UI's leather ring that runs out into a point** (the far herbs' mark, `Art/mark-pointed`), turned the way to
  the place (up: ahead), a step every 0.05 s.
- **In its hole, what to do there** (`Guide.Doing`), the game's own cursor pictures: a speech bubble to talk, a sword
  to kill, a bag to loot, an open hand to use or pick something, the quest's yellow *!* to take one and *?* to hand
  one in, a coin bag to buy, a book to train, the Hearthstone at an inn or to hearth, a winged boot to fly, a map when
  getting there is all. The step's first thing not yet done decides by its command, else the first name its words
  colour.
- **Under it, words at a glance:** what to do there (the step's first words, names in colour), then how far (*177 yd*)
  and the time to get there at the pace you have been closing in (*177 yd · 0:25*; none while you stand or walk away).
  Within the place's reach the ring and the yards go, the words stay.
- **Where it points:** the first place of the steps at hand not yet passed, the step you are at first (a point on the
  way, or a place to get to, is passed once you were within its reach; `Run.Target`).

### The icons
Over the guide's top, a row of icons only (`Icons.lua`): first the items the steps want used (the Hearthstone while a
step hearths, the steps' items, the game's own quest items of your quests — only what can actually be used, never the
gear or the loot a step merely mentions), then the NPCs and the creatures to target, eight at most. Each in Sane UI's
round leather ring (`Art/mark-round`): an item its picture, cooldown and count; a target the game's speech bubble or
sword, its portrait once you have seen it (its nameplate, your target). A click uses the item, or targets the name
(with the skull while *Skull on what is found* is on); the mouse on one says what it is. They are Sane UI's own secure
buttons: set out of a fight only (in one the row stays as it was and follows once it is over), placed by the screen
where the guide's top is.

### The guides kept as text
*Guides* (`/sane guides`, or the menu): at the left the guides kept, a click follows one (those for another side,
race, class or game greyed), the cross beside one forgets it (asked first); at the right, at the top, a line for the
import string of your bought guides or a large guide's text (what is pasted there is gathered as it comes, so
megabytes do not hold the game up, then opened for your account or read as a guide; a guide whose line breaks did
not come through is sent to the box below), and under it a box to paste a guide's text into, with *Read*. It says how many were kept and which lines could not be
read. Kept for the account; which guide a character follows and where it is in each, per character.

## How a guide is run
`Run.lua` runs a guide read from text (`Format.lua`) for the character, asking the game what each line's thing is done
through `Lines.lua`:

- **A step is done** when each of its things to do is done, as the game tells: a quest taken, an objective or a
  quest's items, a quest handed in, a level (or so many points short of one), a spell learnt, a skill reached, a
  zone or subzone reached, a place reached (when its line gives a reach), a home bound, a hearth, a flight path, a
  flight, a vendor's or trainer's window, the spirit healer, a spell cast, an aura, an item worn or thrown away; a
  thing marked to do by hand only by a click. A step with nothing to do is done at once.
- **A step is passed by** while one of its tests says it is not for now: on a quest or not, a quest ready, handed in
  or open, money, an item count, a zone or subzone, a level, a cooldown, an aura, a skill, a group or solo, the level
  it is over; or when it needs a step you skipped.
- **The steps at hand:** the one you are at, and before it a step that stays until done (`#sticky`), and one that
  goes along with the next step or up to a named one (`#completewith`). You go on past each step done, and past one
  that only goes along.
- **Back and Go** hold you at that step until you go on, or until something of it gets done.
- **Through:** on to the guide its head names next (`#next`), the first one kept that is for you.
- What the game tells only as it happens (a hearth, a flight, a vendor's window, the spirit healer, a spell cast)
  counts for the steps at hand while it happens; a place is looked at once a second while a step waits for one.

## The key, by the game's secure ways
An addon may target, mark, attack, interact and use items only by the game's secure ways and on a key press, so every
choice is made by those, in a fight too (`Key.lua`):

- **A state driver** (the game's `RegisterStateDriver`) reads the macro conditions five times a second: a corpse with
  loot, a living foe in a fight, a living friendly NPC right in front of you, a living foe, a living friend, or none
  of these.
- **The header** (`SaneUISpeedLevelingKey`, `SecureHandlerAttributeTemplate`) then puts that state's action on the
  key's keys as override bindings of its own: *Interact With Target* (`INTERACTTARGET`, the game's own) to loot, pick
  up or talk, the button *Fight* (`/startattack`), the button *Use* (`/use item:<ID>` on your target) or the button
  *Find*. A foe or friend counts only when the module said it is wanted (out of a fight), a thing only when the
  interact key's thing is a wanted one, *Use* only while the module said your target is the one the step's item is
  for (the attribute `use`, set out of a fight, a friendly target's reach looked at again three times a second while
  it waits; cleared as a fight begins). A cast of the item the game refuses (`UNIT_SPELLCAST_FAILED`, not one too
  far) keeps the item off that target.
- **Walking:** while your target is a living friendly NPC the key wants, the game's Click-to-Move (`autointeract`)
  is lent, so *Interact With Target* runs you there before it talks; given back when that is over, and as a fight
  begins. The game offers no way for an addon to walk you to a place on the map.
- **Find** (`SaneUISpeedLevelingFind`, the key's own binding in `Bindings.xml`) runs a macro: the hearth alone when it
  is due; else `/cleartarget`, then `/targetexact [noexists][dead] <name>` for each wanted name, the first first, a
  skull on the one found and the attack on a foe, with an item ready when none was found. The game runs only the first
  255 characters of a button's macro, so the names go into a **chain**: Find holds the first names and its ending, and
  while nothing is found it clicks the next button of the chain (`/click`), which holds the next names. It is written
  out of a fight only, anew the moment before each press.
- **The quest givers** (`Quests.lua`): while you talk to an NPC, the quests the steps at hand take are accepted and
  those they hand in are handed in, by the game's own gossip and quest-frame functions; only the guide's quests, and
  only with the switches on and Shift not held.
- **Nothing else is automatic:** each press does one thing, the player's.

## Files
| File | What it holds |
| --- | --- |
| `SpeedLeveling.lua` | The module's table, words, settings (`Core.Options`), standing down, `/sane guides` |
| `Unlock.lua` | The import string of bought guides, opened for the account you play (`Unlock.Open`, over frames) |
| `Format.lua` | A guide written as text read into our shape (`Format.Head`, `Format.Read`, `Format.For`, `Format.Plays`) |
| `Lines.lua` | What the game says about the things a guide's lines ask (quests, items, spells, skills, auras, the level, where you are) |
| `Run.lua` | A guide run for the character: the steps at hand, what is done, skip, back, go, the places, the quest givers' wants |
| `Guide.lua` | The guide shown: its picture, the player's ways, the guides kept (packed), what the steps want for the key |
| `Wanted.lua` | What is wanted around you, by name and in order; the things of the world by ID (read anew when the quest log changes) |
| `Items.lua` | What the key uses: `Items.Hearth`, `Items.Pick` (each a macro line or nil), `Items.OnTarget` (the step's item for your target) |
| `Key.lua` | The key: the buttons Find (and its chain), Fight and Use, the header and its snippets, the state driver, the game's settings lent (the interact key, Click-to-Move) |
| `Quests.lua` | What a quest giver does for your guide: takes and hands in its quests |
| `Steps.lua` | The guide over the world: drawn from the picture, its clicks, its menu |
| `Arrow.lua` | The arrow, a part of its own: where it points, what to do there, its words |
| `Icons.lua` | The icons over the guide: items to use and names to target, Sane UI's own secure buttons |
| `Guides.lua` | The window of the guides kept: the list, the import line, the box to paste into, *Read* |
| `Bindings.xml` | The key in the game's key bindings |

## Errors
A failure stands the module down (`ns.GiveBack`): the state driver stops, no override binding of ours stays on your
keys, the macros are emptied, and the game's interact key goes back as it was (out of a fight; in one, once it is
over); the guide is hidden. The key then does nothing until the next `/reload`.
