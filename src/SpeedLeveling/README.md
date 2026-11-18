# SaneUI: Speed Leveling

**Status:** built · **Since:** 2026-10-25 · **Addon:** `SaneUI_SpeedLeveling` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
One key for questing, pressed again and again, and your leveling guide over the world, run by SaneUI itself. It
needs no other addon: it reads leveling guides written as text (the guides that come for each game in its guide
pack, the guides you bought, opened for your own account, and guides you paste) and runs them with an engine of its
own. A right click on the guide's zone chooses the one to follow; with none followed, *Select a guide* and its button.
A click on a step pauses it (it stays in sight, the guide goes on with the next, and what depends on it waits), a click
again takes it up, a right click skips it, a middle click anywhere on the guide opens its settings. In a
party, those of you on the same guide follow it as one: the same steps by the same numbers for each, read for all your
classes, a class's own steps only for it, and whoever is through with a step first waits for the others.

Each press of the key does the first of these that is due (the order the game's own gamepad interact button keeps):

1. **Loot:** a corpse with loot beside you is opened, as a right click does. What is taken is up to the game's loot
   window, or SaneUI's Loot module where it is switched on (its rules may take some of it at once; *Take all loot*
   sets it to everything). A corpse away from you the key runs you to first (*Walk to corpses*).
2. **Fight in a fight:** your target is a living foe and you are in a fight: it gets a skull and is attacked.
3. **Use the step's item on your target:** out of a fight, your target is the one a step's item is used on, as the
   step's own words say — a corpse ("use the dust on their corpses"), or the creature or NPC they name ("use the cage
   on a worg pup"): the item is used on it. A friendly NPC only once it is within the item's reach; never a creature
   the words say to weaken first, and not again on a target the game refused the item on.
4. **Talk:** a friendly NPC stands right in front of you (the one the game's interact key would pick): you talk to
   it, with one press. At a quest giver, your guide's quests are taken and handed in (below). Once that is done the
   key leaves that NPC alone and goes on, and a talk that comes up with nothing for you closes by itself.
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

**Independent (Saneroki, 2026-10-25).** The leveling guide SaneUI knows is needed for nothing: SaneUI reads only
the words of its text format and the recipe its bought guides are locked by (`Core.Neighbours.Format`,
`Core.Neighbours.Lock`, copies — nothing of the addon is called at runtime), and runs the guides itself.

## How to use
- **Its key:** on the profile *Speedleveling*, where it has none it gets E, once, in place of the game's Strafe Right, and
  the chat says so. The other profiles have key bindings of their own, without it. Change it in Esc > Options > Keybindings, under *SaneUI*: *Loot, talk, pick up, attack, find and mark,
  use*. Taken off again, it stays off, and the module says so in chat at every login. The game keeps key
  bindings per account: on a new account give it one again (a key there may still be bound to a button that is gone,
  and then does nothing). `/sane key` shows the keys it has.
- **Choose a guide:** right click the guide's zone over the world: the guides for this character, by group, each
  group a menu of its own; a click follows one. While none is followed, the button after *Select a guide* opens that
  menu (Saneroki, 2026-11-09). The guides that come for each game are there from the start (the guide pack of the
  game, *The guides*). A character without a guide takes the first one whose head names its race or class.
- **Its settings at hand:** a middle click anywhere on the guide (Saneroki, 2026-11-09): *Your guide* on, paused or off,
  *Professions along the way*, *Together with the party*, *Class quests*, *Show the arrow*, *Map pin on the guide's
  place*, *Targets and items with the guide* (`Steps.SETTINGS`), each with the options page's words and tip, and *All
  settings...* for the options page.
- **Add your guides:** open *Guides* (`/sane guides`, the last line of that menu, or the button on the options page).
  Paste the **import string** of the guides you bought into the line at the top — it is opened for the account you
  are playing, and no other — or paste a guide's **text** into the box below and press *Read*.
- **Pause it, or switch it off:** *Your guide* on the options page.
- **Switch it on or off:** tick or untick *Speed Leveling* under *SaneUI* in the game's addon list.
- **On or off:** the box *Speed Leveling* at the foot of the bags and the switch of that name in the minimap's satchel
  (Saneroki, 2026-10-30) are one and the same: off, nothing of the guide is to be seen, whatever *Your guide* says (`Guide.State`). Each is the profile: ticked, this
  character uses *Speedleveling*; unticked, it goes back to the profile it used before, *Accountwide* if it had no other.
  Every switch below is off at first and on in *Speedleveling* alone (Core's `Presets.lua`), so a switch ticked in another
  profile works there by itself; with none on, all of the module rests: the key does nothing, the guide is hidden.
- **Its page** in SaneUI's options, *Speed Leveling*:

| Setting | In *Speedleveling* | What it does |
| --- | --- | --- |
| Loot first | on | A corpse with loot beside you is opened before anything is looked for. The game's interact key (`softTargetInteract`) is switched on for it |
| Walk to corpses | on | For a moment after a fight the interact key looks all around you and 30 yards far, your target's corpse counts however far it is, and the game's Click-to-Move (`autointeract`) is lent while there is a corpse, so the key runs you to it and opens it; all put back after the last corpse, and in a fight. While it is lent, a right click on the ground walks you there too |
| Talk to NPCs | on | An NPC right in front of you that is no foe (friendly or neutral) is talked to at once (after a corpse to loot); a quest NPC the key found or you targeted, at the next press. Off: the key looks on |
| Walk to the NPC found | on | While a quest NPC the key found is your target, the game's Click-to-Move (`autointeract`) is lent, so the key runs you to it and talks; put back as it was when that NPC is no longer your target, and in a fight. While it is lent, a right click on the ground walks you there too |
| Use items on what is found | on | Out of a fight, a step's item is used on your target when the step's words say it is for that one (a corpse, or the creature or NPC they name); before talking and fighting |
| Quest objects | on | A thing of the world your quests or your guide want, in front of you, is picked up, opened or used. It needs the game's interact key too |
| Skull on what is found | on | What the key finds or attacks gets a skull. In a group everybody sees it; in a raid only an assistant may mark |
| Your guide's targets | on | What the steps at hand of your guide name to kill or talk to comes first |
| Hearthstone | on | When the guide's step says to hearth, the key hearths once nothing is to be looted, talked to, picked up or fought |
| Quest items | on | When the key finds nothing wanted around you, it uses one item: the guide's step's first, then a quest item of your quest log; the first in your bags that is ready |
| *Quest givers:* Take the guide's quests | on | The quests the steps at hand take (and the step after them) are accepted as the quest giver offers them. Hold Shift during a talk and the rest of it is yours |
| Hand in the guide's quests | on | The quests the steps at hand hand in are handed in |
| Choose quest rewards | on | With several rewards to choose from: the biggest upgrade for your gear (`Core.Upgrade`, the most it gains), else the reward the guide names, else the one worth the most: what a vendor pays, or what the auction house brings after its cut where the thing does not bind when picked up and Core knows a price (`Data.Series("Prices")`). Off: the reward the guide names; with none named the choice is yours |
| Choose the guide's talk | on | Where a step names a gossip option, it is chosen |
| Close the talk when it is done | on | After a quest is taken or handed in the key leaves that NPC alone, unless your guide still wants a quest there, and a talk that comes up with nothing for you closes by itself (*The key*). Quests your guide does not know are ignored: never taken, and right after a quest done there the talk closes over them. A talk you open yourself after that stays open for them |
| *On the way:* Take all loot | on | Sets the module Loot to take everything at once (its *Everything* on, its *Always show upgrades* off, as *Equip upgrades* puts those on) and answers the game's question on a thing that binds when picked up. Each set once: what you change on Loot's page afterwards stays; this switch off puts back the rest. Things locked to a group's roll are not taken |
| Skip cinematics | on | The game's cinematics and movies stopped as they start (`StopCinematic`, `CancelScene`, `MovieFrame:FinishMovie`), but one the game does not let you leave |
| Equip upgrades | on | Gear that comes into your bags, looted or a quest's reward, and is an upgrade (`Core.Upgrade`: anything you can wear for a place with nothing in it, else one worth more by your class's and specialization's weights, Inventory's `Weights.lua`, else a higher item level) is put on, one at a time, out of a fight; the chat says what. Only what the game flags as new (`C_NewItems`), so what you took off yourself stays off, and an item the game refused is not tried again. Nothing goes into the off hand while a two-hander is held: a shield build's shield waits, still new, and goes on after a one-hander (Saneroki, 2026-11-04) |
| *Guide:* Your guide | On | On: the guide shows and moves on as you play, the key and the quest givers follow it. Paused: it holds where it is and its view says so (a click there goes on); nothing is done for it, and what you did meanwhile counts once it goes on. Off: no guide is followed. Also the switch *Leveling guide* in the minimap's satchel |
| Together with the party | on | In a group, those who follow the same guide follow it as one: the same steps by the same numbers for each, read for all your classes (a class's own steps only for it, faint in the others' list); whoever is through with a step first waits on it, its creatures still wanted (its NPCs no more), and its card says for whom, until the others are through with it too; then all go on together. A right click on it goes on without them (*In a party*, below) |
| Show the guide | on | The guide's steps over the world (*The guide over the world*) |
| Professions along the way | off | Your professions level up where the guide takes you anyway: where it passes the most nodes, a check before a harder zone, a detour to a node close to your way, a little more killing for cloth (*Professions along the way*, below). Off in *Speedleveling* too (Saneroki, 2026-11-05: "don't do the profession steps") |
| Show the arrow | on | The way to the guide's place, straight at it, a part of its own placed in Edit Mode (*The arrow*) |
| Map pin on the guide's place | on | The game's map pin on each place the guide sends you to, so Navigation's golden line leads there (*The map pin*) |
| Targets and items with the guide | off | The items the steps want used and the names to target, as icons past the guide's head, with the mouse on the guide (*The icons*) |
| Steps in the list | 10 | How many steps the list shows at least that the wheel brings up over the guide (1 to 20); it fills the steps' place and scrolls through the whole guide |
| Guides | | Opens the window of the guides (also `/sane guides`) |

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
Speed Leveling keeps the guides you add for the account (`Core.Store`, each packed with the game's own deflate), and
for each character which guide it follows and where it is in each (`Core.Character`). A guide comes from one of three
places, all read by our own reader (`Format.lua`) and run by our own engine (`Run.lua`):

- **The guides you bought** (`Unlock.lua`): a bought guide of the leveling guide SaneUI knows comes as an import
  string that is locked to the buyer's account. SaneUI opens it with the BattleTag of the account you are playing
  and no other (the key is made from the tag in memory and never kept; base64 and zlib are the game's own,
  `C_EncodingUtil`), and a string bought for another account stays shut. The work runs in steps over frames
  (`Core.Steps`), so a string of megabytes does not hold the game up.
- **The guides that come for each game** (Saneroki, 2026-10-26): a guide pack, an addon of its own for one game
  (*Guides: Forever*, `SaneUI_GuidesForever`; *Guides: Retail*, `SaneUI_GuidesRetail`), made apart from SaneUI's
  code and put into the game (no guide's text is in SaneUI's repository). Its TOC says `## X-SaneUI-Guides: 1`,
  its game (`## X-SaneUI-Games`) and `## LoadOnDemand: 1`; Speed Leveling loads the one for the game at the start
  (`Guide.LoadPacks`), and the pack hands over each guide's head and its text, zlib-packed in base64
  (`SaneUI.SpeedLeveling.TakeGuides`). They are not kept: the pack holds them. A guide you add under the same group
  and name goes before the pack's; a new character takes the first default guide of those you added, then of the
  pack in its own order. `dev/build` leaves a guide pack in the game. A pack may hold guides you bought as well
  (marked bought, for that game only), put there on this computer so they need no paste (Saneroki, 2026-10-29).
- **A guide pasted as text** (`Format.lua`): written in the text format the leveling guide SaneUI knows uses (its
  words for commands, step marks, colours and game tags are Core's to know, `Core.Neighbours.Format`; everything else
  is ours). A head (name, group, the guides after it, who starts with it, which games it is for; a part of a longer
  way, reached only as another guide's next, is not listed; a divider of a list is no guide), then steps, each with
  lines to do, to know or to check, each kept or left out for your side, race, class and level as the line says.

A guide is known by its group, its name and, when its head keeps it for some characters only, for whom: guides of one
name for different characters stand apart, and the guide named next is the one for this character.

## The guide over the world
- **What it shows,** in Expressway with a thin dark outline (Saneroki's pick of font, shipped in the module's `Fonts/`),
  only the steps (Saneroki, 2026-11-01):
  - each step at hand on a dark shade that alone sets it apart, its corners round, no border (Core's `Shape`; Saneroki,
    2026-11-01): *Step 12* small at its top right, its first words large
    (what to do), its things to do, each with its count once, before its words (*2/4 Mottled Boar slain*, the game's
    tick once done), its other words a little smaller, *!* before a warning, *i* before the rest; what is done is a little
    faint.
  - a step you paused (Saneroki, 2026-11-04) stays among them in the guide's order, the whole card faint and the game's
    own pause button (its stopwatch's) after *Step 12*: it counts for nothing until you take it up again (*The mouse*).
    Three at most, those nearest your place (`Run.PAUSED`); the rest of them are in the list.
- **The list of steps** comes with the wheel, nothing stands under the steps at hand (Saneroki, 2026-10-31: "I need to
  focus on the steps"). A turn of the wheel anywhere over the view puts the list of the whole guide in their place, on the
  same shade, the step you are at in its middle (Saneroki, 2026-11-01): a line each with its number, those at hand white
  on a gold band with a gold line at its left, the rest a little grey, a tick for the number of a step done as the game
  knows it, wherever it stands (*How a guide is run*), the pause button for that of a step you paused, which is faint,
  and so is a step on hold. The wheel scrolls it a line at a time from the guide's first step to its last
  (`Guide.Listed`, every step it can show). The steps come back at the red cross in the top right corner, or
  after 10 seconds without the mouse on the view or a menu of a line open (`Steps.LINGER`).
- **Names in colour,** as the guide's words mark them, in the game's own font colours: NPCs green, creatures red,
  things to loot light blue, things to pick up orange, things to buy light yellow, warnings gold.
- **With the mouse on the steps,** and for a moment after it left them (`Steps.PEEK`), the rest comes: the head (the
  guide's zone, its levels after it, and at the right how far you are, *12/84 · 14%*) and past it the icons (*The icons*).
  A menu of the head's keeps them; so does Edit Mode, or the box over the view unlocked; a view with no steps to show keeps
  its head. Out of sight the head does not take the mouse, so a click there reaches the world.
- **Which way it goes,** by where it stands (Saneroki, 2026-11-01): in the screen's upper half its top stays, it grows down,
  the head and the icons under the steps; in the lower half its bottom stays, it grows up, they over the steps; the
  steps stay in their order. Edit Mode moves its place (`Steps.PLACE`, the window's frame), a box of one size, at first
  at the screen's right, a little down: the steps hang from its top or stand on its bottom, so that edge never moves
  whatever the steps' height, and its middle says which half it is in.
- **No guide yet** (Saneroki, 2026-11-09): the view stays, a card on the steps' shade in their place: *Select a guide*
  and a button after it, *Guides*, on a gold band of round corners (a step at hand's in the list), and under them what
  the mouse does: *Middle click for settings. Left click pauses and resumes a step. Right click skips a step.* The button
  (or a click on the card) opens the menu of the guides for this character, as a right click on the zone; with none for
  this character or game (none there, or all for others), *Guides*, to add one (`Guide.Empty`: `none`, `unchosen`,
  `elsewhere`). Its head with the mouse on it.
- **Paused** (*Your guide*): a line saying so on the same card, its head with the mouse on it; a click on the line goes
  on. Off: nothing is shown.
- **The mouse** (Saneroki, 2026-11-04: "leftclick will pause / resume the steps still showing them but ignores of the
  process and rightclick skip them"):
  - a click on a step at hand **pauses** it: it stays in sight, faint, but the guide goes on past it as past a done step
    (it is not ticked), and the arrow, Navigation's route, the map pin, the guide's targets and things for the key and
    Find, the quest givers, the icons and the Hearthstone go by the next step (what the key finds for the quests in
    your log stays as ever). Kept for the character, over a `/reload` and the next
    login. It stays until you take it up again, or until the game knows it is done (then it goes, as any done step).
    What waits on it is on hold (*How a guide is run*);
  - a click on a paused step **takes it up again** and goes to it: it is the step at hand, as a step you went back to;
  - a **right click skips** a step at hand, paused or not (one the game knows is done, or one you went back to, only
    goes on, back to your place), and ticks a thing marked to do by hand;
  - **back to an earlier step:** a double click on it in the list (the wheel), or a right click on it there, *Go to
    step*;
  - a detour's step (*Professions along the way*) is left by either click;
  - a **middle click** anywhere on the view, a step, a line of the list, the head or the card with no guide, opens its
    settings (Saneroki, 2026-11-09; *How to use*, *Its settings at hand*);
  - a right click on the zone chooses the guide to follow: the guides for this character by group, each group a menu of
    its own with its subgroups as titles (a long one scrolls), then *All guides, or add one...*.

### The arrow
A part of its own (`Arrow.lua`), placed in Edit Mode apart from the guide, at first where the travel overlay stands
(`Core.TOAST_TOP`), out of sight while it shows (`Core.TopTaken`); the toast of a new level stands right of it and the
arrow stays in sight (Saneroki, 2026-11-04). Shown while the guide is and has a place to go to:

- **SaneUI's leather ring that runs out into a point** (the far herbs' mark, `Art/mark-pointed`), turned the way to
  the place (up: ahead), a step every 0.05 s.
- **Straight at the place, as the crow flies** (Saneroki, 2026-11-07: "back to where it points towards the end goal
  instead of following the route"): the ring turns to the guide's place and the yards are the straight line to it,
  wherever the way there runs. From 2026-10-31 it went by Navigation's route (`Core.Ways`), ride by ride; now the way
  there is the golden line to the map pin the guide puts on the place (*The map pin*).
- **In its hole, what to do there** (`Guide.Doing`), the game's own cursor pictures: a speech bubble to talk, a sword
  to kill, a bag to loot, an open hand to use or pick something, the quest's yellow *!* to take one and *?* to hand
  one in, a coin bag to buy, a book to train, the Hearthstone at an inn or to hearth, a winged boot to fly, a map when
  getting there is all. The step's first thing not yet done decides by its command, else the first name its words
  colour.
- **Under it, words at a glance:** what to do there (the step's first words, names in colour), then how far (*177 yd*)
  and the time to get there at the pace you have been closing in (*162 m · 0:25*, as the setting *Units* says; none while you stand or walk away).
  Within the place's reach the ring and the yards go, the words stay.
- **Where it points:** the first place of the steps at hand not yet passed, the step you are at first (a point on the
  way, or a place to get to, is passed once you were within its reach; `Run.Target`).

### The map pin
`Pin.lua` (Saneroki, 2026-10-30): as soon as the guide sends you to a new place, the game's own map pin goes there, so
Navigation's golden line leads you there, by flight and boat too, and the game's map shows it as well. It is the game's
pin: Speed Leveling asks nothing of Navigation, whose route follows it as it follows any pin. The place is the one the
arrow points to (`Run.Target`, looked at every `Pin.ASK` seconds, with the arrow switched off too), put on a map by
`Run.Point` (a place written in the world: `GetMapPosFromWorldPos`).

Set once for each place: a pin you put yourself, or took away, stays until the guide goes on to its next place, whose
pin takes its place. Once the guide has no place to go to, or is paused, off or resting, the pin goes if it still stands
where the guide put it; a pin of yours stays. A place the game takes no pin on (a dungeon, a whole continent) has none.

### Professions along the way
Your professions level up where the guide takes you anyway (Saneroki, 2026-10-29; as steps of the guide 2026-10-30; where
the guide passes the nodes, detours and cloth 2026-10-31), once you tick the switch: it is off in every profile
(Saneroki, 2026-11-05: "Also don't do the profession steps"). All of it is worked out by itself, for any race and any
professions: the steps are the same for every character, and each is passed by unless it is yours. A right click skips
any of them, a click pauses it, the switch off takes them all away.

**Mining and Herbalism, where it costs least** (`Gathering.lua`). As a guide is taken up (`Run.Use`, `Gathering.Weave`) it
is walked once, with the guides after it (`Guide.After`, `Gathering.AHEAD`). A zone counts where the guide spends
`Gathering.STAY` steps (10) and enough of that kind grows (`Gathering.RICH`, 30: a city is no place to level). Of the steps
there, the one with the most nodes within `Gathering.NEAR` yards (150, at least `Gathering.FEW`, 5) gets a step after it:
*Level Mining to 16*, *Around here*, your skill's count and bar under it, the arrow and the map pin on those nodes. How
far: to what the next harder zone asks, as far as the nodes around still teach (`Gathering.TEACHES`: a skill point at 40 %
or better; from `yellowAt` and `greyAt` of *Objects*, a node without them counts as the weakest kind). So a spot of weak
nodes asks less and a later one of better nodes asks the rest. For a Night Elf: 16 in the Shadowthread Cave after the
guide's spider (Chunk of Amber), 65 at Fel Rock (Large Chunk of Amber), the rest on Darkshore's copper.

Before the guide goes on to the harder zone a second step checks the same again, *Before Redridge Mountains*: so you need
not come back. It stays out where a spot stands just before it (`Gathering.CLOSE`) and where the next zone teaches that
too. A zone where nothing of a kind grows asks nothing of it, and a step is passed by once you left its zone (`unless`
`inZone`, `away`), so you are never sent back. A step only stops you while your skill is lower than it asks.

**A node close to your way, right now** (`Detours.lua`). Between those steps, whatever the game's minimap really shows
(`Core.Sight`, from Navigation's `Found.lua`: a node seen, not a place one can stand) is fetched when it is worth it: you
have the profession, a step ahead still asks more of it (`Gathering.Goal`), the node can teach you, it was seen in the
last `Detours.FRESH` seconds, and the way round it adds at most `Detours.FAR` yards (60) to your way to the guide's next
place, less the less likely a skill point is (`Gathering.Chance`). Not in a fight, dead or in flight. A step stands over the
guide's, *On the way*, *Mine the Copper Vein*, with the arrow, the map pin and the key on that node.

It ends by itself as soon as the node is gone, whoever took it (the minimap no longer shows it), and you are back on the
guide where you were; also once your skill got there, after `Detours.WAIT` seconds beside a node that does not go, after
`Detours.LONG` seconds at most, or with a click. A node it ended on is left alone for `Detours.AGAIN` seconds. It stands at
`Detours.STEP`, outside the guide's numbers, as a class quest does (`ClassQuests.STEP`), so your place in the guide stays.
Without Navigation, or where the minimap does not answer (Retail), there are none.

**Cloth where you kill anyway** (`Grind.lua`). After a step that has you kill humanoids (the quest's objective, or the
creatures that drop what it asks; *Quests*, *Drops*, *NPCs*), Tailoring and First Aid get a step to kill on for the cloth of
their level (`Grind.CLOTH`): *Kill on here for cloth: worth it until level 12*, the cloth's count and bar under it. Only
while your skill still works with that cloth, and only where there are more of them (`Grind.MANY` spawn points: a quest's
one boss is none). Each stop asks `Grind.STOP` more, up to `Grind.STACK`, so it stays a little at each place. It is passed
by once you are more than `Grind.OUTLEVEL` levels over them, once you carry what it asks, or once you left the zone; skip
the first one and the others of that zone go with it.

**The crafts and the rest** keep their step before the first step into a zone that asks more than the guide's zones so
far: *Level Blacksmithing to 65*, *Before the Barrens*. Each goes by what it works with (`Gathering.PROFESSIONS`):
Blacksmithing and Engineering by the ore, Alchemy by the herbs, the others by the higher of the two. A point on the way is
no visit, a town or cave counts as its zone, and whoever is known to have come past the step (a quest further on is done)
is moved past it: a profession's step never stops the guide working out by itself where you are.

What a zone asks is worked out from the game's own facts in Core's sets: each herb's and ore's skill (*Objects*) and where
they grow (*Spawns*): per zone and kind, the lowest skill that gathers at least half of its spawns (`Gathering.SHARE`;
Durotar 1 and 1, the Barrens 50 and 65, Stranglethorn Vale 170 and 125, Felwood 260 and 230).

The steps are woven in for every profession, also those the character lacks (`step.woven`; `Run.Listed` leaves those out),
so the steps of a guide stay the same whatever is learnt, and so does your place in it, which is kept by number. The view
keeps the guide's own numbers (`step.shown`, `guide.total`): a profession's step bears the number of the step it stands by.
Without Core's data (Retail, for now) none are woven.

### The icons
Past the guide's head, a row of icons only (`Icons.lua`): first the items the steps want used (the Hearthstone while a
step hearths, the steps' items, the game's own quest items of your quests — only what can actually be used, never the
gear or the loot a step merely mentions), then the NPCs and the creatures to target, eight at most. Each in SaneUI's
round leather ring (`Art/mark-round`): an item its picture, cooldown and count; a target the game's speech bubble or
sword, its portrait once you have seen it (its nameplate, your target). A click uses the item, or targets the name
(with the skull while *Skull on what is found* is on); the mouse on one says what it is. They are SaneUI's own secure
buttons: set out of a fight only (in one the row stays as it was and follows once it is over), placed by the screen
where the guide's head ends. They show with the mouse on the guide, by how see-through they are: that alone the game lets
change in a fight. Out of sight they are out of the mouse's way, a click there reaches the world; a fight begins with
them open to the mouse (`PLAYER_REGEN_DISABLED`, the moment before the lock), so in one the row comes when the mouse is on
its place.

### The guides window
*Guides* (`/sane guides`, or the menu): at the left the guides, the pack's and those you added, under their groups'
headings (by name, or by title where the head gives one, the subgroup after it); a click follows one (those for
another side, race, class or game greyed), the cross beside one you added forgets it (asked first); at the right, at the top, a line for the
import string of your bought guides or a large guide's text (what is pasted there is gathered as it comes, so
megabytes do not hold the game up, then opened for your account or read as a guide; a guide whose line breaks did
not come through is sent to the box below), and under it a box to paste a guide's text into, with *Read*. It says how many were kept and which lines could not be
read. Kept for the account; which guide a character follows and where it is in each, per character.

### Class quests
`ClassQuests.lua` (Saneroki, 2026-10-31): the guide knows who plays. When your level reaches a quest chain of your class,
for your race and side, its next step stands on top of the steps at hand, *Bear Form: 2 of 4* in place of a step's
number, and the arrow, the map pin and the key go by it until the chain is done: *Talk to Mathrengyl Bearwalker in
Darnassus*, then what the quest asks, in the game's own words and counts, then the NPC who takes it and the next quest.
Every class of WoW: Forever has its chains (118, in Core's set *ClassQuests*): a druid's Bear Form at 10, Cure Poison at
14, Aquatic Form at 16, Cat Form at 20; a warrior's at 10, 20, 30 and 50; a warlock's pets, a shaman's totems, a
hunter's taming, a paladin's Redemption, a priest's spells of its race, each race's own way to them, Skyborne's and
Horde paladins' and Alliance shamans' too. Nothing is set up: the class, race, side and level are read from the game.

- **The guide is not touched:** the step stands outside its numbers (`ClassQuests.STEP`, `Run.Hand`, `Run.Target`), so
  your place in it, and its count, stay the same, and it goes on under the class quest.
- **One step at a time,** made as it comes up from Core's *Quests* and *Spawns*; a quest in your log or handed in tells
  how far the chain is, and what lies before it is behind you. A quest's own higher level holds its chain back, and
  the next chain that is due comes up meanwhile. Of several NPCs who give a quest, the nearest. Where a chain's first
  quest can be had from others too (a priest's spells, a warlock's Felsteed; the set's `also`), any one of them will do.
- **What your guide does itself stays your guide's:** a quest it hands in shows nothing here, and one it only takes
  shows from there on. So does what a guide further on your way does (`Guide.Later`, the guides its heads name, each
  text looked over by `Format.Quests`; Saneroki, 2026-11-04): a druid's Trial of the Sea Lion, taken at 16, waits for
  the guide that does it at 24 instead of pulling you off your way before.
- **A click pauses the chain** (Saneroki, 2026-11-04: "I can put class quests to later to do them when I feel ready"):
  its step stays in sight, faint, after the one that is due (`ClassQuests.PAUSED`), whatever part of the chain it comes
  to, but the arrow, the map pin and the key go by your guide, the next chain that is due comes up meanwhile, and the
  steps of your guide that have to do with its quests wait with it, on hold (*How a guide is run*; `ClassQuests.Holds`:
  its quests from where it is, in your log too, until handed in). Kept per character and chain (`classPaused`). **A
  click on it again** takes it up: on top again, before a chain that came up meanwhile.
- **A right click leaves the chain** for this character (`Core.Character`, its `classLeft`), paused or not, and your
  guide goes on; take one of its quests yourself and it is back; a right click on the zone brings back all you left. The
  switch *Class quests*.

Without Core's data (Retail, for now) there are none.

## How a guide is run
**Dungeons** (Saneroki, 2026-10-31): a normal guide has none: a step marked for a dungeon is left out as the guide is read,
and one marked for skipping that dungeon stays. Only a guide of a dungeon group runs them, and the other way round
(`Format.DungeonStep`). A normal guide's text may still take a dungeon quest without marking it, to hand in should you
do the dungeon anyway (Saneroki, 2026-11-03): Core's data knows those (a quest it files under a dungeon or a raid,
`Lines.InDungeon`), so each line that takes, works on or hands one in is left out too, and a step left without a quest
of its own goes with them (`Format.NoDungeonQuests`). The breadcrumbs that lead to a dungeon go as well: your quest log
holds no dungeon's quest unless you follow a dungeon guide. Without Core's data (Retail, for now) only the marks count.

`Run.lua` runs a guide read from text (`Format.lua`) for the character, asking the game what each line's thing is done
through `Lines.lua`:

- **A step is done** when each of its things to do is done, as the game tells: a quest taken, an objective or a
  quest's items, a quest handed in, a level (or so many points short of one), a spell learnt, a skill reached, a
  zone or subzone reached, a place reached (when its line gives a reach), a home bound, a hearth, a flight path, a
  flight, a vendor's or trainer's window, the spirit healer, a spell cast, an aura, an item worn or thrown away; a
  thing marked to do by hand only by a right click. A step with nothing to do is done at once.
- **A step is passed by** while one of its tests says it is not for now: on a quest or not, a quest ready, handed in
  or open, money, an item count, a zone or subzone, a level, a cooldown, an aura, a skill, a group or solo, the level
  it is over; or while it is on hold (below).
- **The steps at hand:** the one you are at, and before it a step that stays until done (`#sticky`), and one that
  goes along with the next step or up to a named one (`#completewith`). You go on past each step done, and past one
  that only goes along.
- **What the game knows** (Saneroki, 2026-10-30): the guide works out by itself what is done, at login, when a guide
  is picked or loaded partway, at each change the game tells, and after a click back. A quest taken or handed in, an
  objective, a quest's items, a level, a spell and a skill the game can judge at any time: while one is not done, the
  step stops you, whatever is done after it. The rest (a hearth, a flight, a vendor's or trainer's window, a place,
  a thing to tick by hand, an item carried for no quest) it tells only as it happens, so such a step waits for you,
  until a step after it is known done by a quest line the guide had not asked before: you came that way, so the step
  lies behind you. A level or a spell proves no such thing (they can be had ahead of the guide), nor does a line the
  guide asks a second time, nor a step that only goes along. A right click still does any step by hand. A quest line the
  guide marks to tick by hand counts as done once the game says its quest is handed in, so a place worked out again
  (a guide picked partway, a place the game did not save) goes past it.
- **The ticks** are what the game knows, wherever a step stands: ahead of your place a step shows as done once every
  thing to do of it is done (or you skipped it; one with nothing to do is not done, only easy); behind your place it
  does unless the game says it is open (a quest you abandoned, a step you jumped over).
- **Going back** (*Go to step*, a double click on an earlier step in the list) looks, and keeps your place: the step
  is shown and held, the arrow and the key follow it, the head still says how far you are. Done as it is, it stays for
  you to read; with something left, you can do it again. Once what was left is done, or a click goes on (a click
  pauses it again, a right click skips it), you are back at your place and on past whatever got done meanwhile; the
  click marks nothing on a step the game knows is done. A `/reload` comes back to your place.
- **Going to a step after your place** makes it your place; what you jumped over stays open. Going to a step you paused
  or skipped takes it up again.
- **Paused** (Saneroki, 2026-11-04; a click, *The mouse*): you are moved on past it as past a done step, it is no step
  at hand (`Run.Hand`; the view's `Run.Shown` has it), and nothing that happens counts for it, until you take it up
  again (`Run.Pause`, then as `Run.Go`) or the game knows it is done. Kept per character and guide (`paused`).
- **On hold** (Saneroki, 2026-11-04: "if I pause the start of a class quest that all following steps that require the
  start will also be skipped and the next step that is not depending on that step is resumed there"): what a step you
  paused or skipped takes is on hold while it is not taken, with what a class chain you paused has still to do (*Class
  quests*), and so, down the chain, is each quest your guide takes that Core's *Quests* says needs one of those done
  first (its `requires`: one it needs done, or every one of those of which it needs one; not one it is closed by). A line
  about a quest on hold (to take it, work on it, carry its items, hand it in) drops out of what its step asks; a step with
  nothing else to do with quests is on hold itself, as is one that needs (`#requires`) a step you skipped or paused: it is
  passed by, not done, not at hand, not shown, faint in the list. So the step at hand is the next one that does not
  depend on it. Once the game knows a quest on hold is taken (you took it anyway), or the step that held it is taken up
  again or done, what waited is free at once: the guide goes back to each step of it you were moved past, one by one as
  each is done, your place kept (`parked`, per character and guide), and then on from your place. Without Core's data
  (Retail, for now) only the quest itself and `#requires` count.
- **In a party** (Saneroki, 2026-11-05: "I play on 2 characters and the order in which they choose the next quest is a
  little random. Can you make sure that the 2 characters in the party are synced with the quest order?"; `Party.lua`):
  each character runs the guide by its own quest log, so the one whose drop came first was on to the next quest. Now
  each tells the others of the party or raid where it is in the guide it follows (Core's wire, kind `S`: the guide's
  key, the step's row, `w` waiting there, `a` asking for theirs after a login, a `/reload` or joining), and you are not
  moved on past a step you are through with while a member on the same guide is not (`Run.Waiting`, `Party.Holding`):
  you wait on it, ticked, with a last line *Waiting for* and their names; its creatures stay wanted for the key, so you
  help them, its NPCs no more. Once they are through with it too, all go on together. A step is known by the line of
  the guide's text it begins at (`step.row`), the same for every class and race whatever steps the guide keeps for
  each: a druid's training a warrior lacks holds the warrior at the step before it. Not waited on: a step you paused
  or skipped, one passed by, one that only goes along, a profession's (it counts as the guide's step before it). Only
  members who follow that guide count, while they are online and in the group; one whose guide is paused or off, or
  whose Speed Leveling rests, tells the others so, and nobody waits for them. The switch *Together with the party*; a
  right click on the step you wait on goes on without them. The wire sends nothing in a fight: a place told after it.
- **One guide for the party** (Saneroki, 2026-11-05: "I need them both to follow the same steps. So each step of both
  the warrior and the druid have the exact same thing to do at each step ... Make one merged guide. Include the class
  quests but since they are different classes, they need to wait until the class quest chain is completed for that
  level bracket and then both continue on the same steps again"): the guide keeps steps of its own for each class, so
  a druid and a warrior had different steps under different numbers. Now the classes and races of the members on your
  guide are kept for the character (`Core.Character`, its `with`: learned from the party, `Party.Learn`, kept while
  they are offline or apart, made anew when other members are on your guide), and the guide, and each guide after it
  to the last, is read together with them (`Format.Read` with `who.with`, then `Format.Together`): every step of any
  of your classes, the same steps by the same numbers for each of you, kept under a key of its own (the guide's and
  the company's). What of the others' is yours too: a step that names a quest Core's *Quests* has open to your class
  and race (the quests the guide gives the others while you were busy with your class's: a warrior's *The Great Tree
  Provides* while the druid goes to Moonglade, the druid's *Eyes of the Sentinels* while the warrior does his own),
  without what only a class does (its trainer, spells, a hunter's pets) and the quests not open to you; and in a step
  for all of you, such a quest's line the guide writes for the others only. A line of the others' way about a quest
  you never took asks nothing of you (to take one, while one it needs done first is neither done nor in your log).
  What stays theirs is their class's own (its trainer, its class quests, its way there and back): passed by, never at
  hand, faint in your list with its class before its words (*Druid: Talk to Mathrengyl Bearwalker*). While they do
  it you wait before the next step you share, not yet through with it: its card says *Waiting for* and their names,
  the key leaves it alone (`Run.Waiting`, `Party.Busy`), and once they are at it too you do it together. So too for
  one busy with a quest of its class's on top of the guide (*Class quests*; the wire's letter `c`), named *(class
  quests)*. Steps of your own class alone (`step.alone`) run beside theirs: nobody waits before those. Read anew for other company, or with the switch, your place and what you skipped, paused or passed
  by on hold go with you by the steps' rows (`Run.Use`, `Guide.Reread`). Without Core's data (Retail, for now) none of
  the others' is yours: their steps are theirs. Checked on the real guides from Shadowglen to 60 for a night elf
  warrior and druid: the same steps, row for row, in each.
- **The cost:** a check reads the step you are at, and only while the game cannot judge it the way ahead, a step at a
  time to the first one it can, at most `Run.PROOF` steps; the list asks only for the steps it shows. The whole guide
  is read only when it is picked or loaded.
- **Through:** on to the guide its head names next (`#next`), the first one kept that is for you. A bare name is looked
  for in the guide's own group first: one there for somebody else (a hunter's) sends it on to the next name, never to
  another group's guide of that name, so a normal guide never leads into the dungeon guide (Saneroki, 2026-11-04).
  Another group's guide comes by its group's name ("Group\Name"), or where the guide's own group has none of that name.
- What the game tells only as it happens (a hearth, a flight, a vendor's window, the spirit healer, a spell cast)
  counts for the steps at hand while it happens; a place is looked at once a second while a step waits for one.

## The key, by the game's secure ways
An addon may target, mark, attack, interact and use items only by the game's secure ways and on a key press, so every
choice is made by those, in a fight too (`Key.lua`):

- **Two state drivers** (the game's `RegisterStateDriver`) read the macro conditions five times a second, apart (Saneroki,
  2026-11-04: an NPC in front of you the key was through with hid your target): what is in front of you (`front`: a
  corpse with loot, a living friendly NPC, or none) and your target (`mode`: a living foe in a fight, a living foe, a
  living target that is no foe (`noharm`), a corpse, or none of these); the snippet weighs them in the order above. Not `help`: it holds only for one your spells could help, which many quest
  givers are not (Saneroki, 2026-10-26: in Retail the key talked to none). So the module tells the header out of a
  fight whether the interact key's pick is an NPC to talk to (the attribute `npc`: a creature, alive, no foe).
- **The header** (`SaneUISpeedLevelingKey`, `SecureHandlerAttributeTemplate`) then puts that state's action on the
  key's keys as override bindings of its own: *Interact With Target* (`INTERACTTARGET`, the game's own) to loot, pick
  up or talk, the button *Fight* (`/startattack`), the button *Use* (`/use item:<ID>` on your target) or the button
  *Find*. A foe or friend counts only when the module said it is wanted (out of a fight: of the names wanted, or one
  the game marks for a quest of yours, a creature to kill or loot or an NPC to hand a quest in to or speak to,
  `C_QuestLog.UnitIsRelatedToActiveQuest`), a thing only when the
  interact key's thing is a wanted one, *Use* only while the module said your target is the one the step's item is
  for (the attribute `use`, set out of a fight, a friendly target's reach looked at again three times a second while
  it waits; cleared as a fight begins). A cast of the item the game refuses (`UNIT_SPELLCAST_FAILED`, not one too
  far) keeps the item off that target.
- **Walking:** while your target is a living NPC that is no foe (friendly or neutral) and the key wants it, the game's
  Click-to-Move (`autointeract`)
  is lent, so *Interact With Target* runs you there before it talks; given back when that is over, and as a fight
  begins. The game offers no way for an addon to walk you to a place on the map.
- **Corpses:** the interact key's pick is normally in front of you and close, so for a moment after a fight
  (`Key.LOOK` seconds, on while it finds corpses, `Key.LOOKS` at most) it looks further and all around you
  (`Key.REACH`: `SoftTargetInteractArc`, `SoftTargetInteractRange`). Click-to-Move is lent while its pick is a corpse
  or your target's corpse has loot (`CanLootUnit`, the attribute `corpse`, read anew as a loot closes), so
  *Interact With Target* runs you there and opens it. While it looks that far, the NPCs and things it picks count for
  nothing (the attribute `left`, `npc` and `object` false): they may be far away. Given back as a fight begins.
- **Find** (`SaneUISpeedLevelingFind`, the key's own binding in `Bindings.xml`) runs a macro: the hearth alone when it
  is due; else `/cleartarget`, then `/targetexact [noexists][dead] <name>` for each wanted name, the first first, a
  skull on the one found and the attack on a foe, with an item ready when none was found. The game runs only the first
  255 characters of a button's macro, so the names go into a **chain**: Find holds the first names and its ending, and
  while nothing is found it clicks the next button of the chain (`/click`), which holds the next names. It is written
  out of a fight only, anew the moment before each press.
- **The quest givers** (`Quests.lua`): while you talk to an NPC, the quests the steps at hand take are accepted and
  those they hand in are handed in, by the game's own gossip and quest-frame functions; only the guide's quests, and
  only with the switches on. Shift seen at any step of a talk makes the rest of it yours, held or let go (`held`, by
  the NPC's GUID): nothing more is accepted, handed in, chosen or closed until the talk is over, `Quests.OVER` seconds
  after a window closed with no NPC left (the game closes the gossip window for a quest's, which is the same talk). An
  NPC you did a quest at, or whose talk had nothing for your guide,
  is one you are through with (`Quests.Left`): the key leaves it alone (the attribute `left`), and Find leaves its name
  out where the guide wants it by name and its talk had nothing (`Quests.LeftName`), until the interact key
  picks something else, the quest log changes after the quest has settled, or `Quests.LEFT` seconds are over. An NPC
  with two of the guide's quests: both are taken, by the talk that opens again or by the next press (its list showed
  more, so the key is not through with it). After a hand-in, while the guide still wants a quest to take or a finished
  one handed in (or names the NPC), the key may talk once more: the next quest of a chain may be there. A talk that
  comes up with nothing to do is closed a frame later (`Bye`): at once where nothing can be chosen (the goodbye
  screen), and once within `Quests.AFTER` seconds of a quest done there whatever else the NPC offers, a quest the guide
  does not know included. Only the guide's quests are ever taken.
- **Group rolls** (`Rolls.lua`, the switch *Roll on group loot*): each character on its own, nothing said between them: Need on what is an upgrade to it (`Core.Upgrade`) where the game lets it, else Greed. Nobody Passes: without Greed it takes Transmog or Disenchant, then Need, and a roll that offers nothing is left alone. It rolls as soon as the game has described the item, at the latest with `Rolls.LAST` left on the clock, in a fight too. The game's question on a thing that binds is answered for the rolls made here, none other. Switch off, and on every profile but Speedleveling: nothing is rolled, the game's rolls are yours.
- **Nothing else is automatic:** each press does one thing, the player's.
- **Moving the guide and the arrow:** a right click on the zone, or on the arrow, has *Unlock to drag*: `window:Unlock`, the box Edit Mode shows, outside it; dragged, the place is kept as in Edit Mode; a right click on the box, or the same line, locks it again.
- **`/sane key`** says in chat what the key sees now: its state and what a press does, the NPC or thing in front of
  you and your target as the game judges them (a foe or not, friendly, helpable), whether it is wanted, the item for
  it, Click-to-Move; kept for the account too (`keyCheck`), so it can be read after a `/reload`.

## Files
| File | What it holds |
| --- | --- |
| `SpeedLeveling.lua` | The module's table, words, settings (`Core.Options`), standing down, `/sane guides` |
| `Unlock.lua` | The import string of bought guides, opened for the account you play (`Unlock.Open`, over frames) |
| `Format.lua` | A guide written as text read into our shape (`Format.Head`, `Format.Read`, `Format.For`, `Format.Plays`), also together with the party (`Format.Together`) |
| `Lines.lua` | What the game says about the things a guide's lines ask (quests, items, spells, skills, auras, the level, where you are) |
| `Run.lua` | A guide run for the character: the steps at hand, what is done and what the game knows of each step, pause, skip, back, go, what is on hold, waiting for the party, the places, the quest givers' wants |
| `Party.lua` | The party on one guide: where each member is (Core's wire, kind `S`), who holds you at a step you are through with (`Party.Holding`), who you read the guide together with (`Party.With`) |
| `Guide.lua` | The guide shown: its picture, the player's ways, the guides kept (packed) and the guide pack's, what the steps want for the key |
| `Gathering.lua` | The steps of your professions woven into the guide, where it passes the most nodes and before each harder zone (Core's *Objects* and *Spawns*) |
| `Grind.lua` | Cloth: a step to kill on after the guide's humanoids, while it pays (Core's *Quests*, *NPCs*, *Drops*) |
| `Detours.lua` | A herb or ore the minimap shows close to your way right now: a step over the guide's until it is gone (`Core.Sight`) |
| `ClassQuests.lua` | Your class's quest chains over the guide, by your level: who plays, how far a chain is, its step (Core's *ClassQuests*, *Quests* and *Spawns*) |
| `Wanted.lua` | What is wanted around you, by name and in order; the things of the world by ID (read anew when the quest log changes) |
| `Items.lua` | What the key uses: `Items.Hearth`, `Items.Pick` (each a macro line or nil), `Items.OnTarget` (the step's item for your target) |
| `Key.lua` | The key: the buttons Find (and its chain), Fight and Use, the header and its snippets, the state driver, the game's settings lent (the interact key and how far it looks, Click-to-Move) |
| `Rewards.lua` | Which reward to take where a quest offers a choice (`Rewards.Best`) |
| `Quests.lua` | What a quest giver does for your guide: takes and hands in its quests, closes a talk that is done, the NPC you are through with |
| `Errands.lua` | What would hold you up: Loot's switches set for all loot, the game's questions on binding and destroying answered (a hook on `StaticPopup_Show`), new upgrades put on |
| `Rolls.lua` | Group rolls: Need on an upgrade, else Greed, `RollOnLoot`, the game's question on a roll answered |
| `Steps.lua` | The guide over the world: drawn from the picture, its clicks, its menus (the guides, its settings), its card with no guide |
| `Arrow.lua` | The arrow, a part of its own: where it points, what to do there, its words |
| `Pin.lua` | The game's map pin on the guide's place |
| `Icons.lua` | The icons past the guide's head: items to use and names to target, SaneUI's own secure buttons |
| `Guides.lua` | The window of the guides: the list by group, the import line, the box to paste into, *Read* |
| `Bindings.xml` | The key in the game's key bindings |

## Errors
A failure stands the module down (`ns.GiveBack`): the state driver stops, no override binding of ours stays on your
keys, the macros are emptied, and the game's interact key goes back as it was (out of a fight; in one, once it is
over); the guide is hidden. The key then does nothing until the next `/reload`.
