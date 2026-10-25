# Sane UI: Speed Leveling

**Status:** built · **Since:** 2026-10-25 · **Addon:** `SaneUI_SpeedLeveling` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

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

**And your leveling guide over the world** (Saneroki, 2026-10-25): no window, outlined words straight on the game,
the guide's zone and how far you are, the steps at hand, the next steps greyed out; over it the items to use and the
names to target as icons; and an arrow of its own to the step's place, with a picture and words of what to do there. Its steps come from the leveling
guide Sane UI knows while it is loaded (the guide it has loaded for you; its own window is made unseen meanwhile),
else from a guide you pasted as text, which Sane UI runs itself. The key finds what the guide's steps at hand name.

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
| *Guide:* Show the guide | on | The guide's steps over the world (*The guide over the world*) |
| Your leveling guide's own guide | on | While the leveling guide Sane UI knows is loaded, its loaded guide is shown and followed; off: the guide you pasted |
| Hide its own window | on | While its guide is shown here, that guide's own window is unseen (see-through and small); back as it was when this is off |
| Show the arrow | on | The way to the guide's place, a part of its own placed in Edit Mode (*The arrow*) |
| Targets and items over the guide | on | The items the steps want used and the names to target, as icons over the guide's top (*The icons*); the known guide's own boxes put away meanwhile |
| Steps listed ahead | 5 | How many next steps stand under those at hand (0 to 12) |
| Guides | | Opens the window of the guides kept as text (also `/sane guides`) |

## What it looks for
In this order, the NPCs before the creatures (Saneroki, 2026-10-25); the key takes the first it finds around you (as
far as the game shows creatures by name):

1. The NPCs the steps at hand of your leveling guide name: quest givers and takers (the guide Sane UI knows,
   `Core.Neighbours.Targets("guide")`, while it is loaded; else the guide you pasted, `Guide.Targets`).
2. The NPCs your finished quests are handed in to, of your side.
3. The creatures the guide's step names.
4. The creatures of your quests' open objectives, from Core's data (the sets *Quests* and *NPCs*): those to kill,
   then those that drop an item to loot (*Drops*: the likeliest three an item).
5. Creatures the game itself marks for a quest of yours on their nameplates (`Core.UnitQuest`): what Core's data
   does not know.

Core's names are English: on a client in another language the key finds what 1, 3 and 5 name. Retail has none of
Core's quest data yet: there too the key finds what 1, 3 and 5 name, and no thing of the world by its ID; looting,
fighting, talking, the hearth and the game's own quest items work as in Forever.

**The things of the world** go by the game's object ID, on any client: those of your quests' open objectives, those
an item to loot comes from (*Drops*), and those a finished quest is handed in to, of your side. The game tells no
addon where they are; the key knows the one its interact key would use (`PLAYER_SOFT_INTERACT_CHANGED`, the soft
target's GUID), so a thing counts once you stand beside it.

**What it uses** (`Items.lua`): the Hearthstone (item 6948) when the guide's step lists it (or a shaman's Astral
Recall, spell 556), in your bags and off its cooldown; else, when nothing is found, the first ready item of the
guide's step's items (`Guide.Uses`: the known guide's, else the pasted guide's) and of the game's own quest items of
your quests not yet done (`GetQuestLogSpecialItemInfo`, the item a quest shows as a button). One a press: two would be
used at once. Such an item is often for a place or a creature: away from it the game says so and nothing is used; one
that wants a target puts the game's targeting hand on the cursor. An item to use on a creature you found is the
player's click.

## The guide over the world
- **What it shows,** from the top, in Expressway with a thin dark outline (Saneroki's pick of font for it, shipped in
  the module's `Fonts/`), where Edit Mode puts it (at first at the screen's right, a little down; it grows down):
  - the guide's zone, its levels after it, and at the right how far you are (*12/84 · 14%*), a thin rule under;
  - each step at hand on a faint dark shade: *Step 12* small, its first words large (what to do), its things to do
    (*Mottled Boar slain* with *2/4* at the right and a thin bar under it, a hand-drawn tick once done), its other
    words smaller, *!* before a warning, *i* before the rest; what is done is faint;
  - the next steps, greyed out (no colours in them), a line each with its number, each a little fainter (all clear
    while the mouse is on them).
- **Names in colour,** as the guide's words mark them, in the game's own font colours: NPCs green, creatures red,
  things to loot light blue, things to pick up orange, things to buy light yellow, warnings gold.
- **The mouse:** a click on a step at hand skips it (the guide goes on past it), a right click goes back one step;
  the wheel over the next steps scrolls them, a double click goes to one; a right click on the zone or on the next
  steps opens the known guide's own menu (its guides, its options) while its guide is shown, else a menu of the
  guides kept (choose the one to follow) and *Paste a guide...*.

### The arrow
A part of its own (`Arrow.lua`), placed in Edit Mode apart from the guide (at first over the middle of the screen),
shown while the guide is and has a place to go to:

- **Sane UI's leather ring that runs out into a point** (the far herbs' mark, `Art/mark-pointed`), turned the way to
  the place (up: ahead), a step every 0.05 s.
- **In its hole, what to do there** (`Guide.Doing`), the game's own cursor pictures: a speech bubble to talk, a sword
  to kill, a bag to loot, an open hand to use or click something, the quest's yellow *!* to take one and *?* to hand
  one in, a coin bag to buy, a book to train, the Hearthstone at an inn or to hearth, a winged boot to fly, a map when
  getting there is all. The step's first thing not yet done decides by its command (an objective by the game's kind
  of it: a creature, an item, a thing of the world), else the first name its words colour (a creature, a thing to
  loot, to pick up, an NPC, a vendor).
- **Under it, words at a glance:** what to do there (the step's first words, names in colour), then how far (*177 yd*)
  and the time to get there at the pace you have been closing in (*177 yd · 0:25*; none while you stand or walk
  away). Within the place's reach the ring and the yards go, the words stay.
- **Where it points:** for a pasted guide, the first place of the steps at hand not yet passed, the step you are at
  first (a point on the way, or a place to get to, is passed once you were within its reach; `Run.Target`); for the
  known guide, where its own arrow points (`Core.Neighbours.Pointing`), its own arrow put away meanwhile.

### The icons
Over the guide's top, a row of icons only (`Icons.lua`): first the items the steps want used (the Hearthstone while
a step hearths, the steps' items, the game's own quest items of your quests), then the NPCs and the creatures to
target, eight at most. Each in Sane UI's round leather ring (`Art/mark-round`): an item its picture, cooldown and
count; a target the game's speech bubble or sword, its portrait once you have seen it (its nameplate, your target). A
click uses the item, or targets the name (with the skull while *Skull on what is found* is on); the mouse on one says
what it is. They are Sane UI's own secure buttons: set out of a fight only (in one the row stays as it was and
follows once it is over), placed by the screen where the guide's top is. While they show for the known guide, its own
boxes of targets and items are put away.
- **The guides kept as text** (`/sane guides`, or the menu): at the left the guides kept, a click follows one (those
  for another side, race or class greyed), the cross beside one forgets it (asked first); at the right a box to
  paste a guide's text into, and *Read*, which keeps each guide of it (a file with several guides in long brackets
  is fine) and says which lines could not be read. Kept for the account; which guide a character follows and where
  it is in each, per character. A character without a guide takes the first one whose head names its race or class.

### A guide pasted as text
Written in the text format of the leveling guide Sane UI knows (its words for commands and step marks are Core's,
`Core.Neighbours.Format`): a head (name, group, the guide after it, who starts with it), then steps, each with lines
to do, to know or to check, each kept or left out for your side, race and class as the line says. Sane UI reads
it into a shape of its own (`Format.lua`) and runs it (`Run.lua`):

- **A step is done** when each of its things to do is done, as the game tells: a quest taken, an objective or a
  quest's items, a quest handed in, a level (or so many points short of one), a spell learnt, a zone or subzone
  reached, a place reached (when its line gives a reach), a home bound, a hearth, a flight path, a flight, a vendor's
  or trainer's window, the spirit healer, a spell cast; a thing marked to do by hand only by a click. A step with
  nothing to do is done at once.
- **A step is passed by** while one of its tests says it is not for now: on a quest or not, a quest ready, handed in
  or open, money, an item count, a zone or subzone, a level; or when it needs a step you skipped.
- **The steps at hand:** the one you are at, and before it a step that stays until done, and one that goes along with
  the next step or up to a named one. You go on past each step done, and past one that only goes along.
- **Back and Go** hold you at that step until you go on, or until something of it gets done.
- **Through:** on to the guide its head names next, the first one kept that is for you.
- What the game tells only as it happens counts for the steps at hand while it happens; a place is looked at once a
  second while a step waits for one.

### The known guide's loaded guide
While the leveling guide Sane UI knows is loaded and shows its own window, the view shows the guide it has loaded,
which it unlocks for your own account itself (`Core.Neighbours.Book`): its title, the step it is at, its steps at
hand with their words, what is done, and its next steps; a count is read from a line's words. A click goes on by
its own function (`Core.Neighbours.GoTo`), a right click back. Its colours of names become ours. What the view stands
in for is lent (`Core.Lend`) and given back as it was when its switch is off, when its window is closed, and when the
module stands down: its window (see-through and small), its arrow (put into a hidden frame of ours while our arrow
points to its place), and its boxes of targets and items (put away the same way while our icons show, out of a fight
only: they hold the game's secure buttons). Its import strings are locked to the buyer's account: Sane UI never reads them; it shows
only what that guide has loaded itself.

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
| `SpeedLeveling.lua` | The module's table, words, settings (`Core.Options`), standing down, `/sane guides` |
| `Format.lua` | A guide written as text read into our shape for one character (`Format.Parts`, `Format.Read`, `Format.For`) |
| `Run.lua` | A guide read from text run for the character: where you are, the steps at hand, what is done, skip, back, go |
| `Guide.lua` | The guide shown: the known guide's while loaded, else the one pasted; its picture, colours, the guides kept |
| `Wanted.lua` | What is wanted, by name and in order (`Wanted.Names()`, `Wanted.Unit(unit)`), and the things of the world by ID (`Wanted.Object(guid)`); read anew when the quest log changes |
| `Items.lua` | What the key uses: `Items.Hearth(items, spells)`, `Items.Pick(items)`, each a macro line or nil |
| `Key.lua` | The key: the buttons Find and Fight, the header and its snippets, the state driver, Find's macro (`Key.Find()`), the game's settings for Loot first and Quest objects |
| `Steps.lua` | The guide over the world: drawn from the picture, its clicks, its menu, the known guide's window lent |
| `Arrow.lua` | The arrow, a part of its own: where it points, what to do there, its words, the known guide's arrow put away |
| `Icons.lua` | The icons over the guide: items to use and names to target, secure buttons; the known guide's boxes put away |
| `Guides.lua` | The window of the guides kept as text: the list, the box to paste into, *Read* |
| `Bindings.xml` | The key in the game's key bindings: a click on Find |

## Errors
A failure stands the module down (`ns.GiveBack`): the state driver stops, no override binding of ours stays on your
keys, the macros are emptied, and the interact key goes back as it was (out of a fight; in one, once it is over);
the guide is hidden and the known guide's own window, arrow and boxes given back as they were. The key then does nothing until the next
`/reload`.
