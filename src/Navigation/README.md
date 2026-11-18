# Sane UI: Navigation

**Status:** the minimap and the map in one window, with pins (the game's and Core's data), the quest log, the bar over the full map and routes to the map pin on foot, by flight, by boat and zeppelin, by the Deeprun Tram, by lift, through portals and by the teleports a character has (the hearthstone told in the chat where it is quicker), on foot coloured by how dangerous they are, through waypoints dragged on the full map; the leveling guide comes later · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Sane UI's minimap and world map are one window. Small, in the screen's top right corner, it is the minimap;
move the mouse into that corner (or click there, or press a key) and it fills the screen as the map; a setup, step
by step, shows how the first time (`/sane setup navigation`). Both are the same map, drawn and handled
the same way, only larger, as the chat window is the same chat when it fills the screen. Each keeps its own
zoom and place. The map is drawn two ways at every zoom, from close up out to the whole world, both
continents always: *Parchment*, the world drawn by hand, Blizzard's zone maps in full joined into one map that
fades softly from zone to zone; or *Scrying*, the land as the minimap shows it, its water cut away to a calm sea
(the docks, piers and bridges standing on it kept); or *Blended*, the one far out fading into the other close in.
The game's own minimap lies over it for its live dots; the game's map stays closed, and its keys open ours.
That is WoW: Forever's map; in Retail the map is the game's own map tree, one map at a time, as the game's own map
shows it: a click into a map, the wheel within it, the bar's map selector up to the one over it.
On the map stand pins in the game's own looks (quests, flight points, rares, entrances, places, services, the
party), always over the map; the quest log, a window of its own over the full map and on the screen while the map
is small, and the maps of the dungeons and raids. A search in the full map's title bar finds NPCs (by name and by what
they are: *nearest warrior trainer*), items and where they come from, quests, places, zones and your guild and group,
and shows them on the map or puts the map pin there. The plan is in
`Doc/ideas/Navigation.md`.

## How to use
- **The map:** move the mouse all the way into the screen's top right corner and click there (at first; or only the
  mouse, as the setup's page *Into the corner* or the switch *Hotcorner requires leftclick* sets it); the corner again
  (move away from it first), Esc or the close button on its title bar brings it back. On the way the map grows and
  zooms with the window, from the small view to the full one. The game's map key (M) and quest log key (L), `/sane
  map`, and every other way to the game's map (the quest log button, a click on a quest, a chat link) open it too.
  The key **Sane UI's map** (the game's key bindings, under Sane UI; the setup's page *Or a key*) does the same; once
  it has a key, the game's map key (M) opens the game's own map again (Saneroki, 2026-11-18: "Give them options to put
  keybinds to open either the native map or our map"), and every other way still opens ours. The corner, its click
  and the keys all work together. Moved in Edit Mode, the map takes its hot corner along: docked in another corner,
  that corner; along an edge, that edge; away from the edges, none (a key opens it).
- **The setup, step by step** (Saneroki, 2026-11-18: "make a onboarding window for the navigation module"): the
  window of Sane UI's setups (the addon Onboarding), six pages: *Your map* (the minimap is the map), *Into the
  corner* (the mouse into it, or a left click in it), *Or a key* (Sane UI's map, the game's map, the map's search;
  all of them together), *Move it in Edit Mode* (the hot corner goes with the map), *The quest log* (a click opens a
  quest, a double click puts a route to it) and *On the map* (a double click puts the map pin and a route there, a
  right click often offers more). On the corner's page and Edit Mode's a **very big arrow** on the screen, the game's
  own tutorial arrow, points into your hot corner wherever the map stands, moving towards it again and again, with
  *All the way into the corner* (*, then click* where a click is wanted) beside it, and once the map fills the
  screen, that the corner brings it back; the mouse goes through it. It opens by itself the first time, a few
  seconds after the login; again with *Set up step by step* at the top of the module's options page, or `/sane
  setup navigation` (`/sane setup map`).
- **The same in both views:**
  - **drag** with the left button: the map moves, and stops following you; anywhere on the world map, at any
    zoom: dragged off a continent over the other (or Zephras Isle), the map goes on there, no continent to choose
    first;
  - **the mouse wheel** zooms around the point under the mouse; while the map follows you it walks the game's
    minimap's zoom steps first (its live dots show then), then goes on out to the whole continent and the
    world, and in past the game's nearest step four times nearer than it;
  - **right click:** zooms nothing and goes nowhere (Saneroki, 2026-11-18: "remove the rightclick that changes the
    zoom level or zooms out"): it is for what a thing offers, a pin's, a marker's or the map pin's (below); the wheel
    zooms;
  - **middle click:** back onto you, following you again, near enough for the game's minimap's dots: on the
    small map at the game's middle zoom step (of its six), on the full map where that step's square takes half the
    map's height (the game's dots show around you there too); in Retail on the map you are on;
  - **the mouse over a continent shown whole** lights up the zone under it in the game's own highlight; over
    the world the continent is only named, unlit; **a click** opens it, as on the game's map. On the full map its name stands at the
    top, under the bar, as the game's map writes it: the zone's levels after it, in the colour of how hard they are
    for you (where the game tells none, as in Forever, the levels of the enemies there, the bulk of them; none for a
    city or a sanctuary, whose creatures span too wide), and under it the fishing skill its waters ask, from the first catch to where no fish gets away
    (*Fishing 130-225*), red while you cannot fish there yet, yellow while fish get away, green past it (the original
    game's skill; no red mark of unconfirmed data on the label, by Saneroki's word);
  - **a click** where it opens nothing (in a zone) **pings** there: your party and raid see it on their minimaps,
    as a click on the game's minimap does (below: theirs). It goes out at once, in the click (the
    game takes a ping only from the click itself), so a double click pings too, with its first click. The game
    pings only as far as its minimap's widest view reaches around you, so a place farther off is not pinged;
  - **a double click:** the game's map pin there (on a pin: where the pin stands); **Ctrl and a click** puts it
    there too, as on the game's map. The pin has two states, as the game's own: *tracked* (gold, the game's
    arrow on the screen leads to it with its distance) and *untracked* (only on the map). A click on the pin
    switches between them, Ctrl and a click takes it away, Shift and a click writes it into the chat. Its tooltip
    says so, under the game's words: Ctrl and a click takes it away, a right click shares it, and a double click on
    the map puts it there, with a route to it.
  - **a right click on the map pin shares it** (Saneroki, 2026-11-16): *Party* (*Raid* in one), *Guild* (each greyed
    outside one) or *Someone...* (a player you name, as a marker's *Someone...*). Whoever gets it sees a small card
    (who shares it, the zone) and has it only with **Keep**: their map pin goes there, in place of their own, not yet
    followed by the game's arrow, and the golden line leads there. The setting *Markers and map pins others share*
    (on) lets nobody ask while off. Nothing goes out in a fight; it waits and goes after.
- **Pings of your party and raid** (and your own) show where the game's own minimap lies over the map (around you:
  the small map while it follows you at one of the game's zoom steps, the square around you on the full map), drawn
  by the game, with its sound. Farther out the map shows none: the game does not let an addon hear its pings.
- **Following you:** both views follow you by themselves (Saneroki, 2026-11-15: "Remove the "follow me" feature from
  the map and just follow the character automatically always when the character is moving and the map has not been
  draged around for 5s"; the box and the setting *Follow me* went). The full map opens on you and keeps you in its
  middle. Dragged away, zoomed, moved to a quest or to a map chosen on its bar, either map comes back to you as you
  walk once you left it alone for a moment: the small map after 2 seconds, the full map after 5 (standing still, you
  can look around as long as you like); the middle mouse button brings it back at once. Zoomed out farther than the
  game's own minimap goes, the small map zooms back in as you walk, after the same 2 seconds, to where the middle
  button brings it. In an instance the small window shows our map of the dungeon (below).
- **In a dungeon, a raid or a battleground** the game tells addons nobody's place (Blizzard's rule: our map cannot
  show you there; the game's own minimap, which the game draws itself, can). So inside a dungeon or raid we have a map
  of, the small window shows **our map of it first** (Saneroki, 2026-11-15: "Yes ours first"): its whole floor, its
  bosses, your markers and drawings, without an arrow for you. The **player's arrow** beside the satchel's bag (in
  sight with the face, under the mouse, and only there: "only show it on mouse over and in cases where it is
  neccessary like in instances"; "make the button that toggles it look like the players arrow") swaps to the game's
  minimap (it shows where you stand, with its own ground and dots; the wheel walks its zoom steps) and back; a notch
  out past the game's widest step brings ours back too. On our map the wheel zooms and a drag moves it, as on the full map, and a middle click
  shows the whole floor again (Saneroki, 2026-11-15: zoomed in, "the games minimap is forced on me and covers my own
  map"); the face (the time, the place, the bag and the arrow) shows while the mouse is anywhere on it. The choice is
  kept for your account, into the next dungeon. Elsewhere (a battleground, a dungeon we have no map of) the
  game's minimap alone. Out of it, our map is back.
- **What a thing gives.** Hover a rare, a chest, a herb or a vein, on the map or a found node: its tooltip lists what it gives, the
  likeliest first, each with how often: `Fang Charm 7.5% (3 of 40)`, `Moon Gem 1 of 40` while too few came, `12%` where only our data
  says so. So do the red dots of a dungeon's enemies; a boss's loot has it at each item's right. All of it is Core's `Data.Drops()`
  (what shipped, what you counted, what your guild and group counted); `PinView.Drops`, at most `PinView.DROPS` lines, and a gathered
  marker's inset under each name. An item only for those on a quest shows while you are.
- **A rare's tooltip, as a dungeon boss's.** Hover a rare on the map (or the Sane Rare tracker's notice): a creature's
  panel, its own 3D model in the portrait's place, a rare's silver dragon round it and its level on the plaque; its
  name in its side's colour, under it *Rare* or *Rare Elite*, its kind and when it comes back; then *Abilities* and its
  loot, each with the game's icons, and with Alt each one's details (an ability's description, an item's effects and
  stats). Core's NPCs tell what they know of it.
- **Sane Rare tracker.** A rare, a treasure, a book or an event near you is told the moment the game shows it: the game's war
  horn, and a notice at the screen's right edge under the minimap: the rare's own 3D model at its left (a treasure's or an event's: the game's icon of its mark), its
  name in gold, *Rare Elite, Level 24*, how far and which way (*85 m north-west*, kept up to date). Found by the game's
  marks on the minimap, and by the rare itself as soon as you see it (its nameplate, your target, the mouse on it), for
  the rares the game gives no mark. Forever's world has no such marks: there a chest is told when your interact key
  picks it (its soft target, what Core's data says the object is), and a book a librarian asks for as you come within
  100 yards of it (or your interact key picks it) while you still need it: not in your bags or bank, its quest not
  done, and one only for those on a quest while you are on it; in your bags or its loot window opened, it goes. The
  mouse on it: its tooltip as on the map. A double click puts the map pin on it
  and the golden line leads there, as on a pin; a right click sends it away; a drag with the left button moves the
  notices, kept where you let them go (`/sane testraretracker reset`: under the minimap again). It stays until you
  right click it, the rare is dead or the treasure taken (its mark gone or dead, or the creature seen dead: your
  target, the mouse on it, its nameplate), or you are 400 yards from it (another part of the world, an instance); a
  `/reload` clears them. A rare's notice follows its mark as it walks; one seen in person stands where you saw it from,
  where Core's data knows no point of it. Three at most, the newest nearest their place, the others under it (over it
  in the screen's lower half); seen again while its notice shows, that one stays, without a sound; the same one comes
  again after 5 minutes at the earliest; never inside an instance, never a dead one. Settings, page Navigation, section *Sane Rare tracker*: on or off, what it tells of (rares, treasures,
  events), its sound (*War horn*, *Find chime*, *Raid warning*, *None*). **`/sane testraretracker`** shows one as a find
  would: the nearest rare of Core's data on your map, else a made-up one ahead of you; `chest` a treasure's, `event` an
  event's.
- **Pins:** every kind of thing in its own icon, the game's map icons: no discs, no numbers. The game's own marks
  where it tells them (your quests: the yellow ? only where one ready to turn in is handed in; one still in progress
shows by its objectives' pins and its area, and where it has no objective's pin on the map, by the game's own mark of
a quest in progress, three yellow dots; the quest the arrow leads to glowing; flight points of your side,
  red while your character has not found them (the routes fly only the found ones), never the ones the game keeps
  but no longer uses (named *zz...*, as Forever's three *zzOLD* ones in the Riverglades: not on the map, in the
  search nor in a route);
  rares (a skull; hold Alt over one and its 3D model stands beside the tooltip) and treasures (a chest) nearby; the
  game's points and ways into other maps), and what Core's data
  knows: quest givers with a quest you can take (the yellow !), with a quest too low to give you experience (a grey
  !) or one you cannot take yet (its level, a quest first: a red ?), or with quests you have done only (grey, off
  at first); services, each its
  own (the innkeeper's mug, the banker's bags, a class trainer's book, a profession trainer's scroll, a merchant
  the game's anvil, one of food, reagents, poisons or ammunition the game's icon for those, of trade goods the
  vendor's bag of the game's gossip window, the auctioneer the golden hammer of its crafting orders; no NPC a gold
  coin or a yellow dot: those are the game's for what its own minimap finds, Saneroki, 2026-11-16), entrances, the docks of the boats (a boat) and zeppelins (an airship) with where they go, where
  herbs and ore grow (*Possible herbs*, *Possible ore*), books (an open book: those the librarians ask for, the book's
  name in the tooltip): as far as the data holds them; a place
  the game has not confirmed ends its tooltip with *! Unconfirmed Data !* (the marks red; in Sane UI's tooltips a
  quiet grey note at the bottom), and a red ! before the name of each thing in it that is not confirmed (the pin's
  own thing, a quest it offers, each of a gathered pin's), until the game confirms it in play: you or somebody of your guild or group sees
  the NPC at its place, talks to it, opens the mailbox there (Core's watchers), and the note goes. A tooltip says what it is: an NPC by what it is, never by its own name (Saneroki,
  2026-10-23): its title (*Warrior Trainer*, *Bowyer*, *Expert Blacksmith*), else its service (*Innkeeper*), else
  *Quest giver*; only a rare keeps its name; then its quests with their levels, and why a grey one is not for you
  yet. One pin per thing at each place it stands: the game's word hides the data's. Pins that would cover each other
  stand side by side, a cloud round their middle, each in the direction it lies: they lose a little of their place,
  pushed aside, and stand each at its own place again as you zoom in. Pins of one icon close together (trainers,
  vendors, portals; several spawns of one herb or creature) are one marker in that icon, its tooltip naming what is
  there once each, and part as you zoom in; quests, flight points and docks never combine, each to be hovered or
  clicked for itself. No tooltip says a word twice. Treasure, possible herbs and possible ore show only up close (the view at most `Pins.CLOSER`, 1500
  yards high). **A double click on any pin**, on the small map and the
  full one, puts the game's map pin where it stands (the golden line leads there; the tooltips do not say so). **A
  click** on a marker of one thing's spawns zooms in; on the full map a quest in your log leads the game's arrow to it and shows
  its text, and a quest giver's quests show in the quest log (below); on any other pin it is a click on the map
  there (a ping). Shift and a click on an entrance, a way or a dock with one destination opens its map. A continent
  whole shows only travel and places; the minimap no
  books or treasures, services only near you. The party and raid in their class colours, at every zoom and over
  the game's minimap too, largest far out and smaller as you zoom in, gliding smoothly as they move; the mouse on one
  names it (every member under the mouse, each in the class colour, *Guild* beside one of your guild, *Dead* beside
  one dead), and a click there is the map's. The map's search finds an NPC by what it is: a friendly one without a
  service the game's speech bubble, a hostile one the game's red dot.
- **The pin filter** (*Pins* on the full map's bar, or the setting *Pins on the map*): a checkmark per kind, each
  with its icon large before its words, in sections under their titles: *Around you* (the party and raid, your
  markers), *Quests*, *Travel*, *Towns and services*, *Gathering* (the possible herbs and ore), *Tracking* (the found
  herbs, ore and fishing pools, the rares, treasures and books); it
  scrolls on a screen lower than it. The quests each a row of their own: *Quests in your log*, *Quest offers*, *Low-level quests* (no
  experience for you any more), *Quests for later* (once you meet what they ask), *Done quests*, *Quest areas*, *Quest
  areas on the minimap* and *Quest objectives*. **At first** (Saneroki, 2026-11-15, for the first release) *Quest
  offers*, *Low-level quests*, *Quests for later*, *Done quests*, *Quest areas*, *Quest areas on the minimap*,
  *Rares*, *Treasures*, *Possible herbs* and *Possible ore* are off, every other kind on at 100 percent, *Books* too.
  At each kind's right a slider sets its size on the map, 50 to 200 percent (the party: its marks; the quest areas:
  their opacity, 10 to 100 percent), kept with the settings. **No switch for them** (Saneroki, 2026-11-15): the golden
  line to the map pin and what the game's minimap shows around you (players, tracked herbs and ore), on the small map
  and on the full map too, there around you at the full map's own scale (shown while it fits inside the map), are
  always there.
- **The small map's face:** while the mouse is on the small map (or the satchel is open) your local time stands at
  its top, in the middle, the name the game's minimap gives where you are (the area, else the zone) at its bottom in
  that minimap's colours (friendly, hostile, contested, a sanctuary), and the satchel in its corner; off the map, the
  map alone.
- **The satchel** (the leather satchel in the small map's lower corner at the screen's edge; the upper one where
  the window stands in the screen's lower half; in sight with the face): a click opens a page beside the map, in
  large cells easy to hit.
  Beside its X the button with the circling arrows, *Classic minimap*: the game's own minimap instead of this one
  (the switch *Show the game's minimap*), and the same button on the game's minimap, *Sane UI window*, brings this
  one back, so the two go back and forth:
  - **the zone you are in** (its title, with the subzone, as big as the numbers under it and centred, without a
    rule, in the colour the game's minimap gives it: friendly, hostile, contested, a sanctuary; a long one comes out
    smaller, on one line); under it four low boxes, a big number over its word: your local time, the realm's,
    the frames per second and the ping to the world (home and world on its tooltip); under them the time of day (in
    WoW: Forever), new mail and from whom, the calendar's invitations, all looked at again every second; then the
    game's **Calendar**, **Clock** (its alarm and settings; while the alarm sounds a
    click stops it) and **Stopwatch** (on the screen), each ticked while open. The calendar opens out of a fight
    only, as the game opens it only so for an addon;
  - **Sane UI:** first the line **Sound:** with the sound profile in use in a dropdown and a cogwheel beside it
    (Core's sound profiles: each game account keeps its own and sets its last one again at each login). The
    dropdown lists the profiles, the one in use first; choosing one sets it at once. **Disabled**, first of the
    others and in use at first, is no profile: Sane UI leaves the game's sounds as they are (its tooltip says so). *(changed)* after its name:
    the game's sound settings differ from it now. The cogwheel opens a menu with the game's sound settings: a
    checkbox and a slider for each of *All sound*, *Music*, *SFX*, *Dialogue* and *Ambience*, working at once (the
    profile keeps them only when saved), then **Save** (the settings now into the profile), **Load** (the profile
    set again), **New** (a profile of the settings now, its name asked) and **Delete** (the profile in use, asked
    first; Disabled in use then). While Disabled is in use the menu's title is *Sound settings*, and Save, Load and
    Delete are greyed out. Then the quick switches Sane UI's modules offer (`Core.Offer`): *Speed Leveling*, the
    same as the box at the foot of the bags; on is ticked, off is faint;
  - **AddOns:** the buttons other addons put round the game's minimap, gathered here (with our window as the
    minimap they would otherwise stand on our map only now and then, or nowhere), each its picture round, without
    the golden ring round it, with its addon's name under it, its clicks and tooltip its addon's; and the addons the game's addon compartment lists
    (the game's own button for them is out of sight with its minimap's frame), a click on one as in the game's
    menu. An addon with both shows once. With the game's own minimap chosen they are back round it. Only while
    there is one: with none the section is not there;
  - **Pins:** the pin filter's kinds the map can show, but its *Tracking*: a click shows one or not (as the pin
    filter; the sizes stay there);
  - **Tracking** (Saneroki, 2026-11-15: "trainers and auctioneer and flightmaster etc are not tracking abilities"):
    what is tracked, not standing where it stands: *Found herbs*, *Found ore* and *Found fishing pools* (Find Herbs,
    Find Minerals and Find Fish), *Rares*, *Treasures* and *Books*, then the game's own tracking spells (Track
    Humanoids, a hunter's beasts...), a click switching one. Not the game's townsfolk (flight masters, trainers,
    auctioneers, bankers...): the pins *Flight points* and *Services* show them.

  Compact: six cells a row, each picture straight on the paper (no pencil slot), the addons' twice as large. A cell that is on shows its
  picture whole with a pencil tick, one that is off faint and grey. It goes the first time the mouse leaves it,
  until the button is pressed again: the button counts as the page, the short way between the two is free, and a
  menu one of its cells opened holds it. The button again, its X or Esc closes it too, and so does the map filling
  the screen; the wheel scrolls it on a low screen.
- **Found herbs and ore** (the pin filter's *Found herbs* and *Found ore*; Saneroki, 2026-11-11):
  - **the same on both maps** (Saneroki, 2026-11-11: "I want to minimap and the world map work as similar as
    possible"): a place one can be is the picture of what it gives, round with a soft edge and half opaque, as wide
    as a found one's ring; a found one is whole in the leather ring. On the small view's game minimap Found.lua
    draws them at their exact places; on the full map (and the small view while the game's minimap does not show)
    they are pins of the pin filter's *Possible herbs* and *Possible ore* (in place of the game's gathering mark,
    which stays only where the picture is not known) and *Found herbs* and *Found ore*, gathered and combined as pins
    are (`Pins.lua`, `PinView.lua`). The places one can be lie under the game's minimap on both, so its dot stands
    on them; no place shows under a found one.
  - **where they can be:** every spawn of Core's data of a herb or an ore around you, while its kind is on and you
    have its finder, in the picture of what it gives with a soft edge (`Found.Soft`, `Art/mark-soft.blp`), half
    opaque (`Found.POSSIBLE`), under the game's minimap: its own yellow dot of one up now stands on the picture of
    what it is. In the small view and on the game's own minimap; the small view's pins *Possible herbs* and
    *Possible ore* give way to them there (`Found.Draws`).
  - **found:** the dot under your mouse, which the game's minimap names (its tooltip), is found, on the spawn of it
    nearest the mouse: drawn whole over its place and marked far away on the screen (below) until you gather it, go
    far from it or it is five minutes old; the mouse on its place again and the game naming nothing there (its
    finder on): gone. Forever from build 70862 on (2026-11-07) its minimap answers no point an addon asks, only what
    lies under the real mouse (`Found.SILENT`, `Found.Answers`), so this is how they are found there.
  - **before build 70862:** the herbs and ore the game's minimap
  shows around you now, each in the picture of what it gives (Peacebloom's flower, Copper Ore's lump) in a round
  ring of stitched leather (the far herbs and ore below wear it with a point), grey while your skill is too low for it; on our small map and on the game's
  own minimap alike. Each switch is also its finder: *Found herbs* on puts Find Herbs on, off takes it off (or
  Find Minerals in its place, while *Found ore* is on), and so on, without a sound; *Found fishing pools* is Find
  Fish, whose pools the game's minimap dots show (no picture of ours). The other way round, a finder switched on
  outside them (the game's tracking menu, the spell, a macro, or one still on from another character of the
  profile) switches its kind on, so the game's dots never show without our pictures and far ones (Saneroki,
  2026-11-11); one going off leaves its kind as it is. With two or more on and their spells known
  they take turns while you move, herbs, ore, fish and round again, those you do not know left out (the setting
  *Switch finders every*, a slider: 15 yards you move at first, 0 to 50, as fast as the global cooldown lets it, 0 never), silently
  too, and the ones of the finder that is off meanwhile stay on the map until you gather one, go far from it or it
  is five minutes old. Dying takes Forever's tracking: alive again (resurrected, at your corpse or by the spirit
  healer), the first finder wanted comes back on as soon as it can be cast, and the turns go on from it; one wanted
  alone comes back alone. As the pins do, each takes the mouse: its tooltip
  names it, a click pings it to your group and a double click puts the game's map pin where it is, so the game's
  arrow leads there.
- **Indoor maps:** inside a building or a cave, its indoor map lies over the map at the floor you stand on (the
  game's own indoor pictures, without their black), in every view: in the halls one may ride through too, which the
  game counts as outdoors (Ironforge's under its mountain, the Undercity, Timbermaw Hold, Booty Bay's tunnel), as its
  minimap shows their plan. Only inside buildings and caves, never on a street: Stormwind's
  and Orgrimmar's streets and squares keep the city's own map, though the game counts each city as one building.
- **Sparkles** (the setting *Sparkles on herbs and ore*, on at first): gold sparkles in the world on the herb or
  ore your interact key would gather now, hanging from the game's plate on it, so you see it among the grass and
  the rocks. They need the game's interact key: while they are on, *Enable Interact Key* is on and it looks all
  around you up to 20 yards (as the game sets it for a gamepad); switched off, those settings are as they were.
- **Far herbs and ore** (the setting *Far herbs and ore on the screen*, on at first): each herb and ore the minimap
  found farther away than the sparkles above reach shows on the screen in its direction: the picture of what it gives,
  round in a ring of stitched leather (the minimap's found ones wear it too, without the point) that runs out into a
  point the way to it (up: ahead, right: to your right, down: behind you), and how many yards away it is under it, the
  number alone; the nearest eight. One outside your view stands
  at the screen's left or right edge, on the side you would turn to. They are placed roughly: the game tells no addon where its camera looks, so they take it to be behind you, looking the way
  you face. While you turn the camera with the left mouse button they wait, until you ride on a moment or turn with
  the right button. They never touch the map pin.
- **Quest areas:** the quest the arrow leads to, or the one under the mouse in the quest log, shaded as the game
  shades it on its map, lightly, its edge clear. On the small map only with *Quest areas on the minimap* ticked
  in the pin filter or the satchel (off at first: no blue area and no white ring there), in place of the game's
  minimap's own (theirs too where its own ground shows: in a dungeon, in Retail).
- **Quest objectives:** where your quests' open objectives really are, not only their area: of each quest in your log
  that Sane UI's data holds, a pin at every spawn it knows of what is asked: the quest log's sword on a creature to
  kill, its sack on what gives an item to loot and on an object to use, the game's speech bubble on someone to speak
  to. They stand without a glow; **with the mouse on a quest in the quest log its pins glow a little**, its own mark
  too where it has one, so you see which pins are whose. Where they stand, the quest has no mark of its own: the ?
  is where a quest is turned in. An item many creatures may drop: only those that give it often, twelve
  at most. A pin's tooltip says what stands there, the quests it is for and what is left of the objective in the
  game's words; a click on the full map shows the quest in the log, as on its own mark. An objective done takes
  its pins away. What a quest asks for stands as that, not as the rare or the herb it is as well. A creature's spawns
  near each other are one marker in its picture; other things stand beside it in the cloud. A quest the data does not
  hold has the game's mark of a quest in progress (three yellow dots) and its area alone, and so has every quest in
  Retail until its data comes.
- **The quest log**, a window over the full map and on the screen while the map is small (**the button *Quest Log* on
  the full map's bar turns it on or off, in both**; no pin, no close button; drag its title bar to move it, dock it at
  a screen edge, size it by its corner). On the screen alone it stands in place of the game's quest tracker, which
  stays out of sight even with the log turned off, at a place and size of its own: at first where the game's quest
  tracker stands, under the minimap at the screen's right edge, reading from that edge inwards (Saneroki, 2026-11-18),
  without a background, a border or a line under its title, only the list over the game, clicked through but its
  title bar and its words. **Ours or the game's, never both:** with the game's quest log ticked in *Classic windows*
  (or *Show the game's map*) the game's quest tracker is back on the screen and ours leaves it (over the full map it
  stays, as its button says); unticked, ours again. **In Edit Mode** only that one is there to be placed: ours with its
  box, the game's quest tracker and its box out of sight, or the other way round (Saneroki, 2026-11-18). The Sane Rare
  tracker's notices, under the minimap too, draw over it while one shows.
  There it rests out of sight as your unit frames and action bars do (*Hide the quest log at rest*, off at first:
  Saneroki, 2026-11-15): it
  shows with the mouse on its words, title bar or items, while your health or resource is not full, in a fight and in a
  group (`Core.Rest`, the tray of its items with it); with *In a group too* under it (off at first) it rests in a
  group as well. Over the full map it always shows.
  **A timed quest's time left stands at its top,** under its title bar and over the list, a line for each, the soonest
  first: *2:05  Wolves Across the Border*, counting down, red in its last minute. It stays in sight while the rest of
  the log rests out of sight, is folded or switched off, so you always know a timer runs (the game's own timers go with
  its quest tracker).
  Its title bar says how many quests you have of how many you may, and how they are sorted:
  *Proximity* (the nearest first, at first), *Level*, *Zone* (the game's own, under its zones) or *Type* (under
  Elite, Group, Dungeon and the like; the rest Normal; a quest always shows under its zone, however the game's own log
  has its headers; over the full map a click on a zone folds it, kept); a click on those words sorts them the next way, kept. **A click
  on the title bar beside them hides the list,** so that only the title bar stays, and shows it again, kept. Your quests
  with their level, a **+** on it for one meant for a group (`[60+]`, as the game's own log writes it), no mark before them
  and no tick after them, their
  objectives under them, each with how many first, the game's sword (to kill) or sack (to loot or find) and what:
  *- 4/7 (sack): Nightstalker*; over the full map all of them, the done ones grey; on the screen alone only those still
  to do. A quest done keeps the one still to do, in the game's words (*Report back to ...*). No scroll bar: the mouse wheel scrolls it, and while the mouse is on a list longer
  than its room the game's thin scroll bar shows at the side the window stands at, over the full map and on the
  screen alone (docked at the left edge: its left; at the right edge: its right; Saneroki, 2026-11-15). **A click on a quest unfolds its story, its objectives and its rewards under it,** one quest's at a time, each
  under its heading in gold, on a dark panel with a thin gold line down its side; a click on it or on that text folds
  them away again. **Its rewards stand as big icons:** experience and gold in words, each thing with its name beside
  its icon, two side by side where they fit, those to choose from under them. The mouse on one shows the game's tooltip,
  compared with what you wear; the chat link's modifier links it. It also leads the arrow to it and moves the map to its objective (its question mark on the map, or the middle of the
  area where its foes are), at the zoom it has. **A double click does the same but for its text, and puts the game's
  map pin there, so the golden line leads you there.** A click waits a moment for a second one, so a double click
  leaves the text as it was. Shift and a click tracks it. **The item a quest wants used** (the one the game's
  tracker shows) stands at the far end of its row: a click uses it, in a fight too, any button of the mouse, as on the
  game's tracker. With the mouse on it you get its tooltip, as your tooltip settings show it (at first while Shift is
  held): what you carry, how it is bound, its charges, its cooldown. Shift and a click uses it as well; with the
  chat's box open it writes it into the chat instead. It comes, goes and counts its charges as your bags change. In a
  fight the items stay where they stood and follow once it is over; over the full map none shows in a fight, as the
  map may close then.
  **On the screen's right half the log mirrors itself:** its title and words right aligned, the items at the left.
  The
  right button: *Quest Details* (its text, as a click unfolds it), *Show Map* (the map at its objective), *Track*, *Share* and *Abandon*. A click on a quest's pin on
  the map shows its text too. **A click on a quest giver's exclamation mark on the map adds its quests as ghosts:** on
  top, under *Not in your log*, each between a red exclamation mark and a red X, which say so; the rest of it as any
  quest. That X or the right button takes one out at once, the red X over them all of them, and one you take from its
  giver goes by itself. Below a ghost what the data knows of it: why it is not for you yet,
  its level, who gives and takes it, its objectives and rewards, as big icons too. A click on one moves the map to its giver, a double
  click puts the map pin there.
  They stay until the next `/reload`.
- **The search** (Saneroki, 2026-11-15): the large field in the middle of the full map's title bar. Click into it (or
  press the key *Search the map*, Sane UI's section of the game's key bindings, or type `/sane map find <words>`) and
  type; a moment after the last key the finds stand under it, in groups (NPCs, places, items, quests, zones and
  dungeons, guild, group and friends, what trainers teach), each with its picture, its name (the letters you typed in
  gold), what it is and where (its zone, its levels) and at the right how far it is and an arrow the way to it from
  where you face. What it understands:
  - **names and kinds**, forgivingly: *hogger*, *linen cloth*, *warrior trainer*, *repair*, *inn*, *bank*, *ah*
    (an auction house's first letters), *mailbox*, *food*, *flight master*, *herbalist*, *miner*, *elwynn*; a short
    word also as the first letters of the words (*wt*: a Warrior Trainer). Every word must be found. An NPC hostile to
    your side shows only where you typed its name;
  - **nearest**, *closest* or *nearby* anywhere: one list, nearest first; Enter puts the map pin on the nearest (the
    golden line leads there). *nearest warrior trainer*, *nearest mailbox*, *repair nearby*;
  - **an item's sources:** *who sells X* (its vendors and their price), *what drops X* or *where does X drop* (the
    creatures and objects that give it, how often), *where to get X* (every way: vendors, creatures, objects, quests
    that reward it); where none sells or drops it, every way there is. A plain item's name, Enter: the same list;
  - **who teaches X** or *where to learn X*: the trainers of that spell or trade, nearest first;
  - **where to farm X** (also *farm X*, *X farming*, *where to mine*, *gather*, *pick* or *skin X*; Saneroki,
    2026-11-15): the places where what gives it stands thickest, the best first (with *nearest*: the nearest), each
    named by its zone and where in it (*Westfall (north west)*), with its main creatures or nodes, how many there are
    and about how many a round gives, their levels, how far. They glow on the full map at once, soft gold, as large
    as the place (so the glow grows as you zoom in), the busiest the strongest, a pin with the thing's picture in each
    one's middle; the route is left alone (Shift-Enter puts the map pin there if you want it). A dungeon where it drops
    is listed after them (Enter: its map). An item's *where to get* list starts with its best places to farm, and Enter
    on a herb, an ore or a chest in the list asks where to farm it. *in <zone>* keeps to one zone;
  - **in <zone>:** only what stands there (*vendor in elwynn*, *trainer in ironforge*);
  - **levels:** *level 30*, *lvl 20-30*, *level 40+*; *where should I level* and *zones for level 30*, *dungeons for
    my level*: the zones and dungeons as high as you are, the best fit first;
  - **my trainer** (your class's), **my corpse**, **unknown flight points** (those you have not found);
  - **a first word that keeps one kind:** *items*, *quests*, *zones*, *dungeons*, *raids*, *flights*, *mailboxes*,
    *guild*, *party*, *friends* (*dungeons* alone lists them all);
  - **not X** or **-X** without it, **X or Y** either, **"two words"** together;
  - **two numbers:** a point of the zone shown (*45 60*), or of a zone named (*elwynn 45.2 60.1*): the map pin there;
  - **a typo** is put right where nothing is found: *peaceblossom* searches for *peacebloom* and says so at the top.

  The keys in the field: **Up** and **Down** light a row (round at the ends; in the empty field Up brings back what you
  searched before), **Tab** the next, **Page Up**/**Page Down** a page; **Enter** takes the lit row, else the first,
  and lists **what to do with it** under it (Saneroki, 2026-11-15: "so you can first select the thing and then select
  what to do with the thing"), its places glowing on the map meanwhile: **Show on the map** (its places as pins, the map
  at the nearest; with *nearest* asked, the map pin there too), **Put the map pin there**, for an item **Where to get
  it**, **What drops it**, **Who sells it**, **Where to farm it** and **Link in the chat**, for a spell **Who teaches
  it**, for a herb, an ore or a chest **Where to farm it**, for a place **The map pin there, its link in the chat**,
  for a quest of the log **In the quest log**, for a member or a friend **Whisper** and **Invite**; the keys choose
  among them and Enter does it. A zone or a dungeon has one thing to do and does it at once (its map whole).
  **Shift-Enter** puts the game's map pin on a find's nearest at once; **Esc** goes back from what to do to the finds,
  then closes the list, then empties the field and takes the pins away. The mouse: a click or a right click is Enter,
  Shift and a click Shift-Enter (on an item, its link into the chat); resting on a row shows its places on the map
  without moving it. The row under the mouse, or lit by the arrow keys, shows its **tooltip** at the list's right, level
  with it (Saneroki, 2026-11-15: "When you mouse over an item or select it with the up and down arrows its tooltip
  should be shown"): an item's and a spell's the game's own, an NPC's as on the map's pins (its 3D model, its rank and
  kind, its abilities and what it drops), a herb's, an ore's or a chest's what it gives; under them what it is, where
  and how far. The list reaches down as far as the screen lets it, and where more finds are than fit,
  a **scroll bar** at its right (drag its thumb, click above or below it for a page; the wheel moves three lines).
  What you pick is remembered and comes a little higher the next time. A click anywhere else gives the keys back to
  your character. A search that runs into an error says so in the list and stops nothing: the map goes on, and the
  next key searches again (the error is in `/sane errors`).
- **Your own markers** (Saneroki, 2026-11-15): **Alt and a click** on the map (small or full) puts a marker there and
  opens its card: write its title and its description, pick its icon, the icons in groups each under its title
  (Saneroki, 2026-11-15: "grouping them up together so similar things like class and roll icons, raid marks, etc are
  grouped together to make it easier to find them"): *Raid marks*; *Roles and classes* (tank, healer, damage, the nine
  classes, in Forever's own look); *Calls* (the game's pings: attack, assist, on my way, warning, threat, safe; a
  target, an eye, turn, an arrow, yes, no); *Crowd control* (sleep, sheep, stun, kick); *The way through* (a boss, an
  elite, a skull, a door, stairs up and down, a jump, a portal, a trap, a chest, a locked chest, a key, the end);
  *What to mind* (fire, water, sneak, run, a bomb, a summoning stone, a rallying banner, a lookout, food, drink, a
  question); *The world* (a quest's !, a herb, an ore, an inn); all the game's own pictures. Save (Enter in the title too) or Cancel (a new one cancelled goes again). On the
  map it stands in its icon at every zoom, its title beside it on the full map; the mouse on it shows its title and
  description; **a click** opens its card again (its icon, title, description, the zone and the day you put it) with
  four buttons: Edit, Move (then click on the map where it should stand, a drawing tool on or not; a right click: it
  stays), the map pin on it
  (the golden line leads there) and Delete (asked first); a double click puts the map pin there at once. The pin
  filter's *Your markers* shows or hides them all; the map's search finds them by their titles and descriptions
  (*markers* as the first word lists them all). They are kept for your account.
- **Sketches** (Saneroki, 2026-11-15), the dropdown on the full map's bar (left of *Pins*; in place of the pencil
  button: "When it is not active it says Sketches and when you click it it shows all the sketches with a checkbox in
  front that toggle if the sketch is shown and the fold out to see more options"): it says *Sketches*, and while you
  draw *Drawing:* and the sketch you draw in. Its menu: every sketch with a checkbox (shown or hidden) and its own
  menu folding out (**Draw in it**, **Rename**, **Share**, **Delete**), then **Draw on the map** and **New sketch**.
  Draw on the map opens a small palette at the top right, under the bar (drag it by its head). Its tools: **Marker** (a click: a marker
  there, its card to write in), **Pen** (drag: a line as the mouse goes), **Line**, **Arrow** (drag: from where you
  begin to where you let go), **Circle** (drag: round where you begin, as wide as you drag), **Route** (clicks: a numbered
  stop at each, a line between them; the tool chosen again begins a new route: Saneroki, 2026-11-15, "activate it and
  click a couple of times on the map and it shows you the positions with the number and line inbetween"), **Text** (a
  click: words there, asked for, in the colour and width chosen: "I also want to be able to add plain text to the
  drawings") and **Eraser** (a click on a drawing or words: away). **Dragging:** while any other tool is on, a press
  on what stands on the map drags it to a new place, on the map and on a dungeon's floor ("While in edit mode I want
  to be able to drag the markers, texts, lines, etc to new positions ... without activating a specific move
  button"): a marker (pressed and let go without moving: its card), words, a route's stop (that stop alone), any
  drawing (all of it); the tool on is outlined, a click on it again puts it away. Under them eight colours and at the right
  three widths (thin, medium, thick, a line on each; a route's stops grow with them: Saneroki, 2026-11-16, "expand to 8
  colours and 3 lines and other stuff so we are as compatible as possible with their map sharing"); with the Text tool
  on, the same squares are four sizes of words (Small, Normal, Large, Huge, an A on each: "add a fourth text size so
  their smallest matches too"), chosen apart from the lines' width. While a tool is on the left button is the tool's
  and a **right-drag moves the map** (the wheel zooms). It all works the same on a dungeon's map: drawings and markers there stand on the
  floor's own map, move and zoom with it, and come back whenever that floor is opened.
  - **Sketches** (*plans* in the code; Saneroki, 2026-11-15: "I don't like the word "plan" in front of each drawing",
    *Sketch* his pick): what you draw and mark goes into the **sketch** chosen in the palette's dropdown (*My markers*
    at first; your earlier markers are in it). Each sketch in the dropdown has its own menu: **Shown** (its markers and drawings
    shown or hidden as one), **Rename**, **Share**: **Party** (**Raid** in a raid), **Guild** (each greyed outside one) or
    **Someone...**, which asks for a player (type a name: your group, guild, friends and those you spoke with show
    under the field as you type, the game's own search, Tab chooses) and sends the sketch to that player alone, **Delete**
    (with all it holds, asked first); **New sketch** makes another and chooses it. A sketch shared goes whole, its
    markers and drawings, and whoever gets it is asked (who shares which sketch, how many markers and drawings) and
    keeps it as a sketch of its own, from you; shared again (after changes), it replaces their copy.
  - **With a dungeon map addon's players** (Forever; Saneroki, 2026-11-16: "Yes, build it"; "make the map sharing as
    compatible as possible"): Sane UI also speaks the way of sharing map drawings of a dungeon map addon it knows, so
    its players and ours share both ways, whether that addon is installed or not. Its drawings shared in your group,
    guild or by whisper come as a sketch of ours does (the card names the addon they came with, and how many lay on
    maps Sane UI has no match for); a sketch or markers you share go in its format too, on the same channel, so its
    players get them as its own shares (and Sane UI's take only our copy). **Paste from ...** in the Sketches menu
    takes a drawing copied from it (its Export, or its Backup for all of them): each kept at once as a sketch, pasted
    again it replaces that copy. Its dungeon maps are ours where both draw the game's map art; Ruins of Lordaeron is
    fitted through the game's terrain; its maps of pictures of its own (Excavation Site, City of Dalaran, its Wailing
    Caverns) and the Hall of Thanes have no match, so what lies on them is left out and said. Its lines come as pens
    (its widest thick), its stops as a route with their words under them, its words as words, its marks as our markers
    (raid marks, classes, roles and every stamp of its one of our icons, a shield and a heal among them); its eight
    colours, three widths and four sizes of words are ours one to one, a stop's
    words that stop's again when they go back. Ours go as its nearest: a line, an arrow and a circle as its lines, a
    route as its stops (in the route's colour), a marker as its mark with the title (or the words) as its label. A
    stroke holds 400 points, a sketch 500 drawings and 150 markers, as many as its drawings hold.
  - **Undo** takes the active sketch's newest drawing away; **Clear** all its drawings on the map shown (the dungeon's
    floor, or the zone in the map's middle), asked first.
  - Closing the palette (its X, Esc, the map going small) puts the tool away; Alt and a click still puts a marker.
- **Sharing markers** (Saneroki, 2026-11-15): the card's fifth button, **Share**: this marker, or all of yours on its
  map, with your party (your raid in a raid), your guild (one you are not in is greyed) or **someone**: a player you
  name, asked for as a sketch's *Someone...* is. Whoever gets them sees a
  small card (who shares what, the first titles, the zone) and keeps them only with **Keep**; kept, they stand on
  their map like their own, *from* the one who shared them on their card and tooltip. A marker its maker shares again
  (after an edit or a move) changes the copy you kept, never adds a second one. The setting *Markers and map pins
  others share* (on) lets nobody ask while off. Nothing goes out in a fight; it waits and goes after.
- **The full map's title bar** (Saneroki, 2026-11-15: "Let the map view go to the very top behind the titleba so it is
  truely fullscreen"): the map fills the whole screen, up behind the title bar, which holds its controls with a soft
  shade behind them: at the left **Quest Log**, the view's button (right of it: Saneroki, 2026-11-15), the button
  **Dungeons** (and a dungeon's floors) and **Zone** (Dungeons left of it: Saneroki, 2026-11-15), the search in the middle, at the right **Sketches** and **Pins**, then *Classic windows* and the bar's own buttons. No title words, and on the full screen no X: the arrow down takes the map back to the corner.
- **Zone** on the bar: the world, then every continent (a click shows it whole) with its zones under it, A to Z, and
  Zephras Isle, at every zoom, the world's too (Saneroki, 2026-11-15: "make sure that the zone dropdown menu always
  has all zones listed"); it says the zone shown, else the continent or the world. (The dropdown of continents went:
  Saneroki, 2026-11-15.)
- **Dungeons** on the bar, a button (Saneroki, 2026-11-15: "I would like to have the drop down change to a button and
  when the button is pressed you can see all the dungeons and raids that are currently available in Forever ... sort
  them into dungeons and raids"): the dungeons and raids of Forever this year as banners over the map, under the bar
  and beside the quest log, in two sections, *Dungeons* and *Raids*, the lowest level first. The dungeons are those of
  the game's own group finder (the classic ones with their wings, Dire Maul's three and Blackrock Spire's two, and
  Forever's four new ones: City of Dalaran, Ruins of Lordaeron, Hall of Thanes, Excavation Site: Wetlands); the raids
  those Blizzard announced for this year, all opening on 9 December: The Barrow Deeps, Hyjal Summit and Onyxia's Lair
  (Molten Core, Blackwing Lair and Zul'Gurub, in the game's list but not announced, are left out; a raid shows from
  the year of its day on). Each banner is the game's own picture of it (the Encounter Journal's; Forever's own
  loading screens of its new dungeons; for the two raids the client does not hold yet, a great tree's glade for Hyjal
  Summit and a druids' barrow gate for The Barrow Deeps) with its name, its levels as the game's group finder shows
  them, how many of your quests lead inside (of your side, race and class: a creature to kill there, an item most of
  whose sources stand there; wings share their instance's count), a raid's players and the day it opens; a red ! before
  what the client does not hold yet. Its tooltip says more: its kind, levels, players and bosses, where its entrance
  is. Under it three grey buttons with the game's icons: the map pin (*Route*: the map pin at its entrance, the golden
  line leads there), the glass (*Show on the map*: its entrance; a raid whose entrance is not known yet, its zone) and
  the dungeon mark (*Its maps*); one that cannot act is greyed, its tooltip says why. Every dungeon has its maps and
  shows its place: Forever's four new ones have maps made from the game's own minimap of them (the game ships no map
  of them), Excavation Site: Wetlands and Ruins of Lordaeron their entrances where the game's world area of their name
  lies, City of Dalaran (Alterac Mountains, through the sewers) and the Hall of Thanes (beneath Ironforge) their zone
  only, as Blizzard names it, until their entrances' places are known. The Barrow Deeps and Hyjal Summit, not in the
  game until 9 December, show Mount Hyjal. A click on a banner opens its maps, else shows its entrance. The wheel scrolls, a
  right click goes back to the map, and so does the button again; while a dungeon's map shows, the button says its
  name and takes you back to the banners. Where Core's data is not there (Retail), the banners are the dungeons the
  game has maps of, A to Z, each with its maps.
- **A dungeon's maps** (its banner's *Its maps*, a click on its entrance with Shift, the full map opened inside it):
  its map over the map, and where it has several floors, big buttons in a column at the screen's right, one per floor
  with its name, all one size (Forever's character list's cards; Saneroki, 2026-11-15: "instead of the drop down to
  see different floors, it should be on the instance maps big buttons on the right side of the full screen where the
  name of the floor is listed as a button. All buttons have the same width and height"): a click shows that floor, the
  one shown is lit as the card picked. Each floor opens whole, under the bar, beside the quest log and left of the
  floors' buttons, so the farthest zoom always shows all of it. A floor the game has no map art of (Forever's four new
  dungeons) shows its ground in every view. Where the data knows them, each boss as its own 3D model where it stands
  (the game's model of the boss's look; the game's boss mark only where it has no look, or its model would reach
  past the view's edge). Its tooltip is a creature's: its name in a foe's red, under it the dungeon and *Boss*, its
  model in the portrait's place with the boss's dragon and *??* for its level (in Sane UI's tooltips); then the
  sections *Abilities* and *Loot*, each with its icon and name as the game has them (an item in its quality's
  colour; at most ten of each, then how many more; a red ! between the icon and the name of each one not yet
  confirmed), and *! Unconfirmed Data !* while any of them is not yet confirmed by the game (a boss's loot is confirmed by looting it after the kill, its abilities by seeing them cast,
  here or by the guild or the group); an item or ability confirmed so that the data does not name joins the list;
  an item the game keeps hidden shows its name and, with Alt, its stats as Core's data has them (learned in play); hold Alt for each ability's
  description and, under each item, *Uncollected* first while you lack its look, then its effects (Use, Equip,
  Chance on hit: a recipe's what it teaches), last its damage, speed and damage per second, armour and block and
  stats (no price, slot, binding, requirements, durability, set or lore). Where the data knows them, the
  enemies stand there too, each a small red dot under the bosses, its name in its tooltip (six dungeons so far). The wheel zooms it, a drag moves it, the bar's
  button goes back to the map it was opened from (a right click no longer does: Saneroki, 2026-11-18). Shift and a click on a dungeon's entrance opens it too, and inside a
  dungeon the full map opens on its map, at its lowest floor. Instance maps keep rules of their own, apart from the
  world map's and its indoor maps': Forever tells nobody's place inside an instance, so they show no arrow for you
  and no party or raid; what stands still there, the bosses, stands on them.
- **A dungeon's floor in Scrying and Blended** (Saneroki, 2026-11-15: "I want the terrain / Partchment toggle work for
  instance maps as well. We should have both."): the view's button on the bar works on a dungeon's floor as on the
  map. *Scrying* shows the instance as it truly lies, the game's own minimap pictures of its ground and of its halls on
  that floor; *Blended* the floor's map art over it while the whole floor is in view, fading to the ground as you zoom
  in; *Parchment* (in the settings) the map art alone. The floors of the 26 dungeons and raids have it, but where the
  game's minimap pictures would leave a boss or the enemies standing on nothing: the Deadmines' Ironclad Cove (its
  ship and docks have no minimap picture, only open water), the three floors of Blackfathom Deeps (halls Forever
  rebuilt in another shape) and the two of Blackrock Depths (the ramp to the Hall of Crafting, the Shrine of
  Thaurissan) show their map art in every view. The Wailing Caverns the other way round: its map art is older than
  the caverns Forever rebuilt east of it, so it shows its ground in every view, *Parchment* too. The bosses, the
  enemies, your drawings and markers stand where they stood.
- **Zephras Isle** is on the map as a continent is, a zone of its own: the map follows you there, its pins and the
  map pin stand on it, a click on it at the world opens it, and the wheel out goes on to the world (there is
  no continent between). *Parchment* shows the isle's own map and its stitched map, *Scrying* its terrain, the open
  sky around it cut away as the sea is, and routes there walk around what cannot be walked, as on the continents.
- **Routes:** put the game's map pin (a double click, on a quest in the quest log too, or Ctrl and a click; Speed Leveling's guide puts it on its places by itself) and a golden line leads you there from where you stand,
  pulsing towards it: around what cannot be walked (mountains, walls, deep water is swum), through gates and doors,
  into and out of caves, buildings and the cities in the mountains, on the floor you are on (a cave under a hill, a
  city in a mountain, a building's storeys), and by the flights your character has found where that is quicker:
  only those, as the game tells them at a flight master (it tells them once you have opened one, each session;
  until your first, the ones found before; a flight over many flight points is one, taking off once; with the Legacy
  perk *Frequent Flier* the flights count 20 % faster; the line white along them). The
  line always begins at your arrow: as you go, what lies behind you is gone, a short line runs from you to it, and
  leave it and it is planned again. A little beside it, that line does not turn across to it and then along it: it
  meets the line further on, as far ahead as you can walk straight (up to 60 yards), so you go there and stay on track. A pin on another continent or on Zephras Isle is reached by boat or zeppelin,
  over as many seas as it takes (by way of the other continent where that is quickest), your side's or both
  sides' (not the other side's harbours and zeppelin towers), the line light blue
  from pier to pier; between Stormwind and Ironforge the Deeprun Tram is taken where it is
  quicker, the line light blue from one city's entrance to it to the other's. The line never takes your hearthstone:
  it is yours to spend. Where it would bring you to the pin at least two minutes sooner, the chat says so once for
  that pin ("use your hearthstone (Auberdine) to get to the map pin about 7 min sooner."); once you are home, the
  line leads on from there (the map learns its place where you bind it, or the first time you use it; a shaman's
  Astral Recall, which brings you there too, is told the same way). The teleports your character has are taken
  where they are quickest, the line pale blue to where each brings you, then
  on foot: a mage's to the capitals and Dalaran (with a Rune of Teleportation in the bags), a druid's to Moonglade, an
  engineer's transporters to Gadgetzan, Everlook and Mount Hyjal and the Crumbling Hearthstone (while in the bags
  and usable; one cooling down counts its wait). Where one brings you the map knows from the original game (not yet confirmed by the
  game) or learns the first time it brings a character of yours there (the Dalaran, Darnassus and Mount Hyjal
  teleports, the Gnomish Transporter and the Crumbling Hearthstone until then are no way). Thunder Bluff's mesa and the
  Undercity are reached by their lifts, and the Great Lift is taken where it is quicker: on foot to the lift, up or
  down it, on foot on (and out again the same way); a pin over the Undercity is taken to be in the city (a pin put on
  Tirisfal Glades' map there, on the ruins). Darnassus and Rut'theran Village are reached through Teldrassil's portal
  between them (the line violet through it), Zephras Isle by its airships (the Alliance's from Dalaran, the Horde's
  from Mulgore), and Forever's portals (Stormwind's to Dalaran and back, Dalaran's Violet Citadel) where the walking
  data holds their rooms: those are the mages' own, and so are the pads of Stormwind's Wizard's Sanctum, so a character
  of another class goes without them (Teldrassil's, which everyone steps through, stays everyone's). A pin where nobody can walk (a tower, a plateau) gets its line as near
  as one walks, then straight to it. The lifts and portals are on the map too (not yet confirmed by the game). On a flight
  the line shows the flight's way on from where you are, pin or none, and from where it lands on to the pin; aboard
  a ship it waits until you have landed, and a pin set aboard is planned from the pier it comes to. The game tells
  no ship's timetable: its sailing comes from its way at the game's
  transports' speed, and once you have ridden a ship on your realm the map knows when it really sails there and
  counts the wait for the next one (until then half its time once round). It has no switch (Saneroki, 2026-11-15):
  no map pin, no line.
- **How dangerous the way is:** on foot the line shows it: golden where no enemy near it is far above you, orange
  where enemies that spawn near it are 3 or 4 levels above you, red where they are 5 or more above you (the game's own
  colours of those levels). Only creatures hostile to your side count (Core's data: where each spawns, its levels and
  its faction, and the client's own table of how each faction meets each side), no rares, critters or pets; after a
  level up the colours change with you.
- **Waypoints:** drag the golden line on the full map and let go: a waypoint stands there, and the line goes there
  first, then on to the map pin, so you lead it round a red stretch or along the way you like. While you drag, a grey
  pin follows the mouse and two faint lines show the new bend. Drag the line again for more waypoints (up to 8), each
  on the stretch you dragged. A waypoint is the map pin's art, small and grey: drag it to move it (on the small map
  too), right click it to take it away. It is gone once you have passed it, and all of them when the map pin moves.
- **At a flight master:** talking to one fills the screen with this map in place of the game's flight map, the full
  map as it always is (both continents, its view, the quest log), zoomed out to the whole world, with no pin on it
  but its flight points, your party and the ships' docks (no quests, services, places, tram, lifts, portals, quest
  areas or minimap dots, whatever the pin filter says; your arrow, the map pin and its golden line stay): the flight
  points large, the one you stand at glowing, at each one's right three lines (Saneroki, 2026-11-15): its place,
  its zone and what the flight there costs (*Refuge Pointe*, *Arathi*, the coins; the text larger the closer you zoom, under every pin so it never covers one or takes its
  click); the mouse on one draws the way there, hop by hop as the master flies it, and its tooltip says what the
  flight costs; a click on it flies
  there, as the game's flight map does. A flight point you cannot fly to from here is red, as one you have not found
  yet is everywhere on the map. Back to the corner (Esc)
  ends the talk. Hold Shift as you talk to the flight master for the game's own flight map (whatever *Show the
  game's map* says: that one is the world map's).
- **Back to your corpse:** when you die, the map pin moves to where you fell (the game's arrow on the screen leads
  to it), and once you have released your spirit, onto your corpse as the game tells it: the golden line leads you
  from the spirit healer back to it, on foot or by ship (a ghost takes no flight, teleport or hearthstone). Alive
  again, the pin you had before is back, followed or not as it was; without one before, none. A pin you set while
  dead stays yours. A `/reload` or a logout while dead keeps all of it.
- **Ship times at a dock:** at the dock of a boat or a zeppelin, or a station of the Deeprun Tram, the travel
  overlay (below) shows the next to come there: where it goes, the golden line filling as it nears, when it
  arrives (*Board now* while it is in) and when it leaves; the others that stop there in a line each below. A ship
  or the tram you have not ridden on this realm yet shows how often it comes; one ride teaches its times, kept on
  this computer for the realm and worked out anew from the clock each time, after a `/reload` or a login too; every
  ride corrects them (a restart of the realm starts its ships anew). Until a ride on a later trip teaches how long
  it takes once round (Forever's own boats and zeppelins), they hold only for its next three trips; then it says to
  ride it again. *Ship times at a dock* in the settings switches it off. On the map, the mouse over a dock's pin
  tells the same in its tooltip, counting down: when the ship next comes there and when it leaves (the tram's
  stations too); and draws its ship's whole way round over the map, light blue as on the ride (the tram's run from
  station to station). The mouse over a flight point's pin draws every flight of your side that leaves it, white
  as on a flight, fainter to a flight point you have not found. Flight points and the ways of travel (docks, the
  tram, lifts, portals) stand on the map at every zoom, out to the whole world (at a continent's zoom those of every
  continent in view), each a pin of its own (never
  gathered into a marker), so each can be hovered. On the full map a click on a flight point or a dock keeps its
  ways drawn after the mouse has left it, its pin glowing, as many as you click; a second click lets go of them, and
  all go when the full map goes back to its corner. A double click only puts the map pin there.
- **Your trip on screen:** on a flight, a boat, a zeppelin or the Deeprun Tram, the travel overlay high up
  the screen: where it began and where it goes at the ends of a fine golden line (the map route's art, its glint
  pulsing along) that fills smoothly as you go, the vehicle's icon riding at its tip, a flight point's mark at each
  stop on it (dim once passed); below it the time to the end, the next stop and the time to it, and the zone. The
  way out stands beside the line, in place of the game's button at the action bars: on any flight the game's *Request
  Stop* (you land at the next flight point, and the trip ends there), in a vehicle its *Leave Vehicle*, the button
  alone where the overlay stands. The game's button is out of sight only while this setting is on, and back in Edit
  Mode; a vehicle's own action bar keeps its own leave button. A flight's
  time comes from your own pace on it, before that from your character's last flights; a ship's from its
  timetable; the tram's from the game's own. A `/reload` in the air finds the flight again. *Your trip on screen*
  in the settings switches it off.
- **Map view** (the one button on the full map's bar, *Blended* and *Scrying* in turn: Saneroki, 2026-11-15, "Blended
  and scrying will be one button that just toggles the map views"; *Parchment* in the setting on the page
  *Navigation*): *Parchment*,
  *Blended* and *Scrying*, for both views and at every zoom (in the code `sketches`, `blend`, `terrain`). The map
  starts as *Scrying*. *Blended* is Parchment out to a zone's level and Scrying close in, the maps fading out over the
  land in between. A view not offered (*Overlay* and *Atlas*, which are gone) falls back to Scrying.
  In Retail, until its data comes, Parchment is the one view: the map simply is that, with no view button on the bar
  and no setting.
- **The game's own windows:** the full map's dropdown *Classic windows* offers the game's minimap, map and quest
  log, each kept once chosen (ticked; chosen again, ours comes back), the first two as the switches *Show the game's
  minimap* and *Show the game's map* on the page. **The game's quest log** (Saneroki, 2026-11-15: "so you can still
  see the native questlog even when you use our addon"): its key (the chat says which), its button and a click on a
  quest in the game's quest tracker open the game's map with its quest log beside it, while the map's key and
  everything else open ours; on the screen the game's quest tracker then stands in place of ours. With the game's minimap our small window rests out of sight; with the game's map
  its keys and buttons open the game's (chosen there, it is not opened at once: its key opens it, and the chat
  says which key). Either way the
  hot corner at the top right (a left click there, as *Hotcorner requires leftclick* says) still fills the screen
  with our map. The game's key to show or hide the minimap (in its key bindings) shows or hides our window. The
  game's map has the button *Sane UI* beside its close button, and the game's minimap one at its top right:
  ours is the one again (unticked), the map filling the screen.
- **Size the small window** by its corner away from the screen's edges (at first the lower left): with the mouse
  on the map the game's grip shows there; drag it. The size is kept. **Move and size it** in Edit Mode too, like
  every Sane UI window; the section *Expand window* on the page: whether the corner fills the screen, the
  animation, the background.
- `/sane map reset`: the window's first place and size.
- `/sane nodes`: what finding herbs and ore on the minimap sees now, step by step: the game's calls, our frame over
  its minimap, the pin filter and the finder on, Core's names, your place and the minimap's scale, what it answered
  since login (points asked, lines read, lines the game keeps secret, herbs and ore named, found and drawn) and a
  look over the whole minimap now; kept in Navigation's store (`nodes`) too, so the next `/reload` writes it to
  the saved settings.
- `/sane falls`: the fall meter on or off. After each fall the chat tells its time in the air, how far down that is
  and the health the landing took ("Fall: 2.0 s in the air, 35 m down: took 20% of your health"), so how high a
  fall the routes may take can be found in the game. Walk or jump off: a jump's way up is taken off. Off again after
  a `/reload`.

## How it works
- **Three spaces, converted in one file** (`Coords.lua`): a map's own (0 to 1), the world's yards (X to the
  north, Y to the west), and the plane the map is drawn in (u = -Y to the east, v = X to the north), so the
  screen is the plane times a zoom. A map's box in the world comes from the game, asked once a session. The
  map tree is found at run time: the world map, its continents, their zones; a continent's rectangle on the
  world map puts the other continents and the world map itself into its plane, so one view zooms from a zone
  out to the whole world. A map straight on the world map that is no continent but has a box and a place there
  (Zephras Isle, a zone of the world map) is a plane of its own, linked alike (`Coords.PlaneOf`,
  `Coords.Planes`), for the routes, the views and the pins alike; the map there is a zone, its own one
  (`Coords.Alone`, `Coords.ZoneAt`, `Coords.Zones`), and `Coords.PlaneAt` finds a continent or the isle under a
  point of the world map.
- **The camera** (`Camera.lua`), one for each view: the point in the middle, the zoom, whether it follows you,
  and the level the zoom shows (zone, continent, world), changing with some slack so it does not flicker. The
  wheel keeps the point under the mouse where it is; coming in over another continent (or Zephras Isle) at the
  world, the camera moves into its plane, at the same size on the screen. On the isle the zone's level reaches
  out to the world, with no continent's between; at the world off the isle (not following you) the camera goes
  into the plane under the middle at once, so over a continent the world is left at that continent's own zoom,
  as ever, not at the small isle's. Its middle may go anywhere on the world map (`Camera`'s `Clamp`: the world's
  box in its plane, at every level): dragged off its continent at a zone's or a continent's zoom (not following
  you), over another continent or the isle (`Coords.PlaneAt`), it moves into that plane, the same on the screen,
  at the level the zoom shows there; over the sea between them it stays in its own. A map pin set off its
  continent there goes on the one under the mouse (`Canvas`'s `Where`).
- **The canvas** (`Canvas.lua`), the same for both views: its layers hang on one holder frame, laid out around
  an origin. A drag or a step of following moves the holder only; a layout happens when the zoom changes, the
  holder has moved past a margin, or another zone is in the middle (asked of the game every `Canvas.LOOK` while
  the view moves, and once more a `Canvas.LOOK` after it stopped). The layers' textures come from pools by key, so
  what stays in view is not loaded again. The
  zoom changes at once, as on the game's map. Nothing runs at rest but the tracker: every frame while the view
  follows you (three questions to the game and one `SetPoint`), else a few times a second, and, while the mouse
  is over the map, a look at what is under it when it moved (the game's highlight,
  `C_Map.GetMapHighlightInfoAtPosition`). What the game tells of the pins (`LIVE`, a zone entered too) places
  the pins anew, not the whole map. On the window's way to the full screen and back the map goes with it
  (Core's option `moving`): laid out once at the start over what both views show, at the wider one's zoom, then
  only scaled and moved on each step from the view it leaves to the one it comes to (the middle straight, the
  zoom by equal factors); meanwhile nothing lays it out again (a refresh waits for the window to stand, the wheel
  and a press do nothing). The layers' frame levels are set from the canvas' at every layout. Where the game
  tells no place of yours (an instance), the small view draws nothing of ours but the sea (`Canvas.Laid` says
  no): the game's minimap is the map there (`Hybrid.lua`).
- **Terrain** (`Terrain.lua`): the game's own minimap textures, one per tile of a plane's 64 x 64 grid (Core's
  data, the set *Tiles* in the pack *World*, of the two continents and Zephras Isle, whose grid is its own map's,
  2991), up to 400 at once; under them, and alone further out,
  the module's overview of the same tiles, 64 texels a tile, 8 x 8 tiles a texture (`Art/Terrain/`). At the
  world, every plane's overview where the world map puts it, and at every zoom wherever it is in view. The
  water is cut away: the overview's alpha is
  the land (where the ground lies above the water's surface, read from the game's terrain files by
  `dev/tools/terrain-art`, fading out in the first yard under it so a beach one wades on stays; what stands on the
  water, a dock, a pier, a bridge, a ship, kept: where the minimap shows something brighter or warmer than the
  water around it; around the isle, which floats, the open sky: what the game's minimap leaves black, out
  to its grid's edge; no land along a tile's side that faces no tile, the world's rim, three map chunks deep, where
  the game left dry sea floor or a grey band of its minimap, lines in the open sea), and the same file is the mask of the game's tiles of its block (`Canvas.Masks`), so
  the coast is cut alike at every zoom; a tile on a coast (`Coasts.lua`) is cut by a mask of its own instead, at
  four times the overview's detail (`Art/Coasts/<key>.blp`, 128 x 128), so a pier a few yards wide is not lost up
  close; under it the canvas' sea: its colour, and over that its layers (`Canvas.SEA_LAYERS`), repeated over the
  plane, so they move with the land, each copy its size in units at every zoom, in the open sea, the lakes and the
  rivers alike: the waves (`Art/Sea.blp`: the game's own ocean texture, its light alone, softened by a pixel) twice,
  small and larger by no whole factor, shifted and turned half round, so the two grids never line up alike and no
  copy shows as a tile; over them a soft shade (`Art/SeaShade.blp`, a tileable noise) in slow patches of darker
  water; over those, in Forever, the Maelstrom's whirlpool where its world map paints it (`Canvas.WHIRLPOOL`,
  `Art/Whirlpool.blp`: that map's own spiral repainted as foam by an image model, 2048 x 2048, tinted as the waves'
  foam).
- **Blended** (`Canvas.lua`): the art of Parchment over the terrain of Scrying, its alpha by the view's height in
  yards (`Canvas.Blend`: whole from `Canvas.BLEND[1]` up, gone at `Canvas.BLEND[2]` and below, by the zoom's
  factor between), the sea's colour between Parchment's and Scrying's alike, the waves fading with it (Parchment's
  paper has none). Only a layer that shows is drawn:
  far out the art alone, close in the terrain alone.
- **Art** (`Art.lua`), the view *Parchment*: Blizzard's world map and every plane's (a continent's, the isle's
  own; `C_Map.GetMapArtLayers`, `GetMapArtLayerTextures`) over their boxes, their paper frames faded off
  (`Art/Edge.blp`), in textures of their own; over them the
  stitched map of every plane in view (`Art/Sketches/`, in the terrain's blocks: every zone's full map cut
  to its outline, made by `dev/tools/terrain-art`); up close every zone's own map in view, cut to its outline
  (`Art/Zones/<uiMapID>.blp`, listed in `Outlines.lua`: the zone's land and a little shore, whole up to its
  border and fading out past it, so the one over its neighbour fades into it). A zone's map is always the full
  one: its art and every part the game reveals once explored (Core's set *Overlays*), placed as Blizzard's
  exploration provider places them. Under the mouse, at a continent shown whole, the game's own highlight of the
  zone there; at the world the continent is only named, unlit (Retail's Cosmic map keeps the game's highlight of a
  world).
- **What stands on the map is always over it:** the canvas sets every layer's frame level from its own at each
  layout (`Canvas.LEVELS`): the map's own layers (terrain, art, the highlight) up to `Canvas.MAP`, then the
  quest areas, the route, the game's minimap (`Hybrid.LEVEL`), the pins and the marks on top; the bar over all.
- **And inside the canvas:** the game cuts the map's textures at the canvas' edge, but it drew the lines and
  buttons laid out past the view (`Canvas.MARGIN`) over the screen around the small window. So `Canvas.edge`
  is the canvas' rectangle in the holder's units, set at each layout, each step of the window's way and whenever
  the holder has moved `Canvas.REFIT` units: the route's segments are cut at it (`Route.Fit`, the lines'
  thickness inside; only a segment whose cut changed is placed anew), pins and marks show only while wholly
  inside it (`PinView.Fit`, `Marks.Fit`, `Canvas.Inside`), so none is seen or clicked past the window.
- **Pins** (`Pins.lua`, no frames): the pin records of each map in view, from what the game tells (`Live.lua`: its
  quests on the map and the next way of the quest the arrow leads to, flight points of the player's side (one the
  character has not found red, `Pins.RED` over its colour taken out: `Planner.Knows`), its vignettes, area points,
  map links, dungeon entrances where it has them) and from Core's data
  (`Data.Map():On`, `Core/Data/Map.lua`): an NPC with quests this character can take (`Pins.Offered`: not done,
  not in the log, level, side, race, class, the quests before) is a quest giver, else a rare, else its service in
  the game's town tracking atlas; objects, places and ways in the game's atlases; a boat's or zeppelin's dock
  (Core's set *Travel*, its `docks`) its own pin, its tooltip first when its ship next comes there and leaves, as the
  dock watch words it (`DockWatch.Timer`, white once known, grey while only how often; drawn again as its second
  turns, through the game's tooltip's own `UpdateTooltip` of its owner), then every port it calls at, numbered in the order it
  travels to them from there, that one last (`Pins.Ports`, by the stops of Core's timetable, `Data.Ships`; a port it
  stops at twice in a row once; the tram: its other station), in the game's names of each dock's area and zone
  (`C_Map.GetAreaInfo`, `C_Map.GetMapInfo`), a click opening the map where it is the
  only one, not marked unconfirmed (the game's own ways). A pin at each of a thing's points (a herb's every spawn:
  its key the thing's and the point's, its `thing` the thing's); the game's pin hides every one of the data's for
  the same thing (a vignette's GUID names its creature). Kept per map until the game says it changed (the message
  `LIVE`; the arrow's quest: the game's alone), Core's in parts: the quest givers' read again when the quests in the
  log are others (one taken, abandoned or handed in: `Goals.Log`, which counts `QUEST_TURNED_IN` too, for the log may
  list a quest handed in a moment longer) or the level changed, never at a kill that only counts on; the other NPCs'
  (`steady`), the objects', places' and ways' when Core's places change; at a zone's level every zone in view (on
  Zephras Isle the isle itself), further out the continent and its zones for travel and places only (only the
  places' and ways' part read). A pin's place is in its map's plane (`Coords.PlaneOf`: a continent's,
  or the isle's). At the world each plane in view and its zones (the docks stand on the zones' maps), `Pins.WORLD`'s
  kinds alone; at a continent's zoom every plane in view (`InView`). `Pins.CLOSE`'s kinds (treasure, herb, ore) only
  while `view.span` is at most `Pins.CLOSER`. `Pins.Spread` (Saneroki, 2026-11-11, in place of the gather's markers
  and their plus): first `Combine`, pins of one icon (`Icon`: atlas or picture, tint, grey) within `Pins.COMBINE`
  times its size of the first one in it one marker there (not `Apart`: quests, flight points, docks, a flight
  master's); then in the list's order (the higher kind first) each pin joins the first cloud whose outer ring and one
  size more it lies within (`Ring`), else makes its own; a cloud's middle the mean of its members' places, its step
  `Pins.SPACE` (0.85) times its largest member's size (`Pins.Size`); laid out (`Lay`) the first at the middle, the rest by
  their distance from it into rings of 6 r, each ring's in the order they lie round it; each pin's `sx`, `sy` the units
  it stands off its place (`PinView` adds them). Herbs, ore and a quest's creatures, a zone's thousands of places: one
  thing's spawns within `Pins.GATHER` units of each other (this cell of that grid or one beside it) ride with the first
  (its `with`) and are one marker of that thing, so never a plus.
  The filter is the multi-choice setting `pins`.
- **PinView** (`PinView.lua`): a pooled button per pin, kept by its key while it stays in view, at a fixed size, in
  the game's looks (its quest disc and marks, `UI-QuestPoi-*`, `Quest-In-Progress-Icon-*`); a higher kind over a
  lower one by its frame level (`PinView.TIERS`: kinds that share one may stand together in a cloud), all under the
  marks; a kept button's look made again only when its pin's changed, its shown state told the
  game only when it changed. A press on a pin is the map's (a drag moves the map,
  `Canvas.Press`/`Release`); a plain click is the pin's. Tooltips with a quest's objectives as the game tells them.
- **Goals** (`Goals.lua`): what the quests in the log still ask of the world: Core's set *Quests* (`objectives`) says
  what, the game (`C_QuestLog.GetQuestObjectives`, by `index`) which are open: a creature to kill or speak to, an object,
  or for an item to loot what gives it (`Drops:From`: the likeliest first, `Goals.GIVERS` at most, those under
  `Goals.UNLIKELY` of the likeliest left out, those of no known chance kept). A thing's points from *Spawns*, else
  *CreatureSpawns*, kept until Core's places change. Read when the log said it changed, the pins made again only when
  the open objectives did: a count going up is no such change, the tooltip asks the game for the words. `Pins.lua` makes
  them pins of the kind `goal` (the part `goal` of `data`; keys of their own, `goal:npc:69@1429:3`; in the cells of `MANY`,
  so a creature's hundred spawns cost what a herb's do). Core's own pin of a thing wanted stands aside, a quest offer's
  not, and the game's pins hide them as any data's. One creature's near spawns ride together (`MANY`, by its thing).
  `PinView.Light`, told by the log with `Areas.Hover` (`QuestLog.lua`, `Point`): a pin tied to the quest under the
  mouse, by its `quest` or its `goals`, or a marker with such a pin in it, has the fainter glow (`LIT`, `LIT_ALPHA`).
  No frames but those of the pins. A new kind of the filter, so `version` 5 of the settings puts it on.
- **Areas** (`Areas.lua`): the game's quest area frame (`QuestPOIFrame`, which the engine draws a quest's area
  into) over each zone in view, as large as its box, for the quest under the mouse in the log or the one the
  arrow leads to. Placed at once, drawn on the next frame: the engine shades into the frame's rectangle as it
  stands when asked, and a frame just placed or sized has its new one only once the game has laid it out (drawn
  at once, the area stood where the zoom before had put it). Filled at `Areas.FILL_ALPHA` 64, half the game's map's
  128 (over our darker ground that stood solid), the edge at its 192, times the pin filter's opacity. The game's
  minimap draws none of its own while our map lies under it (`Hybrid.AREAS`: its quest, bonus objective and dig site
  areas' fill, edge and ring at 0 with its ground off, `Hybrid.AREA` again with its ground on): its ring round its
  edge, made for the round minimap, stood as a white circle inside the square, whole or in part. On the small view
  (`Areas.Place`'s `onSmall`, from the canvas' camera) ours and the game's minimap's own only while the filter's kind
  `minimapArea` is on (off at first: a missing kind counts as off, so no upgrade); the full map's by `area`, whose
  slider sets the opacity of both.
- **A dungeon's floors' buttons** (`Dungeons.Cards`): on the full map, where the dungeon shown has several floors, a
  button per floor in a column at the view's right under the bar (and left of the quest log where it stands there:
  `Dungeons.Margins`), `Dungeons.CARD_WIDTH` by `CARD_HEIGHT` (the character list's card,
  `glues-characterselect-card-singles`, its hover `-hover`, the floor shown `-card-selected` laid round it as the
  character list lays it: `CardPicked`), all one size, lower where the column would reach past the room's foot (at
  least `CARD_LEAST`); over the floor's marks and models, under the bar. The floor's `Room` leaves their width free on
  the right (`Several`). Laid at each opening, size change and refit, hidden on closing and on the small map.
- **Floors the game has no art of** (Forever's new dungeons): Core's set *Dungeons* holds a floor each, made by
  `dev/tools/dungeon-ground` from their ground (no tiles, no bosses); `ArtOf` gives them art of no tiles (`bare`), and
  `Dungeons.Share` 0: their ground in every view. A floor of the set's is read at once while the set is still being
  walked (`Entry`), and the banners are listed anew once it is (`Walk`: `Instances.Refresh`).
- **Dungeons** (`Dungeons.lua`): the maps of kind *Dungeon* under the world map (`C_Map.GetMapChildrenInfo`), one
  entry per map group (`C_Map.GetMapGroupMembersInfo`: its floors, lowest first), drawn in a view of their own over
  the canvas, under the bar: the floor's art (`Art.Of`) fitted whole in a frame that is scaled to zoom (up to
  `Dungeons.NEAR` times) and moved by a drag (its step runs only while a drag goes on); fitted into the room the
  bar's row (`2 * TopBar.INSET + TopBar.BUTTON_HEIGHT`) and the quest log leave (`Room`: the log's side, its box
  `QuestLog.Box` and the bar's gap, at most `Dungeons.SIDE` of the width), measured as it opens, when its size
  changes and when the log comes or goes (`Dungeons.Refit`, from `Window.Lay`), not at each step of a drag; on
  the small map (`Dungeons.Small` at each layout inside an instance, first unless the game's minimap was chosen:
  `ns.store.instanceMap` "game"; `Dungeons.Swap` from the satchel's arrow, `Satchel.arrow`, shown where
  `Dungeons.Swappable`; a notch out past the game's step 0, `Dungeons.Whole`; looked at again when the list of
  dungeons is read in after the player was inside, `Dungeons.Arrived`, which shows the full map's floor too) the whole
  small view, zoomed by the wheel and dragged as on the full
  map (all the way out: the whole floor in the middle again; a right or a middle click the same), its marks, models
  and dots at `Dungeons.SMALL` of their size; the face kept while the mouse is anywhere over it (`Left`: off it by
  `IsMouseOver`, not by its frame's leave, which the dots, the models, the bag and the arrow on it cause); wished
  (kept through the full screen and back, `Dungeons.Small` at each layout of the small view, looked at anew after a
  loading screen) until the arrow (`Dungeons.Out`, the game's minimap kept as the choice), and the
  game's minimap out of sight under it meanwhile (`Hybrid.Hide`, `whole` in `Canvas.lua`); no player's arrow and no
  group (Forever tells no place inside an instance). `Canvas.Show` of a dungeon's map opens it; going small or the bar's button closes it (the map under it
  stays as it was). The list is kept once the game told of a dungeon map or the set was read. Core's set *Dungeons* (pack World)
  adds the dungeons the game has no map of: walked once it is there (`Each`), each floor keyed `"<instance>:<floor>"`
  (`Dungeons.Key(instance)` gives the lowest; an entrance's pin takes it as its `to`), its art from the set's tiles
  (the game's files), inside one its lowest floor (`Dungeons.Here`, the instance from `GetInstanceInfo`), the
  enemies (the set's `enemies`, `Dungeons.Enemies`, `Dungeons.PlaceEnemies`: `Dungeons.ENEMY` at `ENEMY_SIZE`, a
  level under the bosses' marks, named by the set *NPCs*), the bosses (`Dungeons.Bosses`) in
  `Dungeons.BOSS` over the art, the same size at every zoom (`Dungeons.PlaceBosses`), named by the set *Encounters*;
  a boss with a look (the set's `display`) gets a `PlayerModel` of it standing on its mark (`SetDisplayInfo`, as the
  game's guild news shows a boss; `Dungeons.MODEL_WIDTH` x `MODEL_HEIGHT` at the whole map's zoom, growing with the
  zoom as the art does, never taller than `Dungeons.MODEL_MOST` of the view: Saneroki, 2026-11-15, "so you can see a
  bigger model by zooming the map"; turned `Dungeons.FACING`), one lower on
  the screen in front (`Dungeons.SPREAD` levels, all under the bar), hidden while it would reach past the view's
  edge (models are not cut there), let go (`ClearModel`) when the view closes; the mark's icon and mouse only while
  no model stands on it. A boss's tooltip (`BossTip`) is drawn as a creature's by Sane UI's tooltips
  (`Core.TipLook`: its `display`, the `boss` dragon, `??`): its name (`Dungeons.FOE`), the dungeon (the set
  *Dungeons*' name of its encounter's instance) and *Boss*; each list headed by `Core.TipSection`; it lists the
  set *Bosses*' `abilities` and `loot` (`Listed`, at most `Dungeons.LINES` each; a set of their own, apart from the
  game's *Encounters*, so they stay unverified until the game confirms them): a spell by `C_Spell.GetSpellInfo`,
  an item by `C_Item.GetItemInfo` (asked for with `RequestLoadItemDataByID` while not loaded; drawn again once on
  `ITEM_DATA_LOAD_RESULT`), each with its icon (`Dungeons.ICON`). With Alt held (`IsAltKeyDown`; drawn again on
  `MODIFIER_STATE_CHANGED`) each line gets its details under it: a spell's `C_Spell.GetSpellDescription` (asked for
  with `RequestLoadSpellData`, drawn again on `SPELL_DATA_LOAD_RESULT`), an item's own tooltip lines, read from a
  hidden tooltip (`SaneUINavigationReader`, `SetItemByID`), only those `Dungeons.KEEP` finds (the game's damage,
  damage per second, armour and block sentences, a line starting with a number's sign) or that start with one of
  the game's effects (`Dungeons.EFFECTS`), in their colours, set in by four spaces: first *Uncollected* while the
  player lacks its appearance (`C_TransmogCollection.GetItemInfo`, `GetAppearanceInfoBySource`; else the game's
  line saying so), then the effects, last the stats. The last line, `Core.Unconfirmed`, says that it is not yet
  confirmed by the game (an enemy's too).
- **A floor's ground** (`Dungeons.lua`: `Dungeons.Ground`, `LayGround`, `Shade`, `Dungeons.Share`; Saneroki,
  2026-11-15): Core's set *DungeonGround* (made by `dev/tools/dungeon-ground` from the game's files; no art shipped)
  lists per floor the game's minimap textures of the instance by file ID, each with its middle in the world, its size
  and its turn: the terrain tiles that meet the floor's box (marked `terrain`) and the indoor minimap blocks of the
  building parts on that floor (which parts: the game's own map assignment, its floors told apart by their names where
  several share one box, else, for a building Forever rebuilt, the floor whose box holds the part and whose map art its
  walls agree with, at the heights of the parts the game names). A floor whose ground would leave a boss or more than
  5 % of its enemies on nothing (no part's texels, or the minimap's open water) has no rows: its art in every view
  (Ironclad Cove, Blackfathom Deeps, Blackrock Depths). A floor the set lists in `alone` (more than a quarter of its
  bosses and enemies on parts whose walls lie on no edge of its art: the Wailing Caverns) shows its ground in every
  view (`Dungeons.Ground`'s `alone`, `Dungeons.Share` 0; `Draw` loads none of its art's files). `Gather` keeps the
  floor's rows and its box
  from the set *Dungeons*; the first time a view shows the ground, `LayGround` lays them into the art's frame
  (`content`, its units the art's size across the box): a terrain tile cut at the floor's edges by its texture
  coordinates (draw layer `Dungeons.TERRAIN`), a building's block centred on its middle and turned as a whole
  (`SetRotation` by its yaw less 90 degrees; `Dungeons.PARTS`, its sublevel by its order, the lowest first). The art
  over it has the alpha `Dungeons.Share`: 1 in Parchment and on a floor without ground, 0 in Scrying, in Blended
  `Canvas.Blend` of the zoom between `Dungeons.BLEND` (whole at the whole floor, gone 2.5 times nearer); `Shade` sets
  it at each placement only when it changed, the ground shown while any of it shows through. A view change
  (`Window.Restyle`) calls `Dungeons.Restyle`; another floor drawn (`Draw`) and closing let the ground textures' files
  go.
- **Label** (`Label.lua`): where the highlight lights a zone up (`Art.Light`), on the full map only, its name at the
  canvas' top under the bar, as Blizzard's map writes it (`AreaLabelDataProvider.lua`: `WorldMapTextFont`,
  `SubZoneTextFont`, scale `Label.SCALE`): the zone (`C_Map.GetMapInfoAtPosition`) with its levels
  (`C_Map.GetMapLevels`; Forever gives none there and its client tables hold none, so `Enemies`: one walk over
  Core's *CreatureSpawns* (`Each`, a scheduler job, the first time a zone is named), each creature of *NPCs* that is
  no critter, of no rank in `Label.SKIP` and spans at most `Label.SPAN` levels counting its lowest and highest level
  once for each of its points on a map; a map's range cut by `Label.LOW` (10 %) of that count at its low end and
  `Label.HIGH` (20 %) at its high end, none wider than `Label.WIDE` (a city); worked out again when either set
  changes; the label named again once it is there) in the game's difficulty colours (below you as its highest less two, above you as its
  lowest, else yellow); under it the fishing skill of its area (Core's set *Zones*' `area`, then *Fishing*'s
  `skill`, the original game's base: a cast catches at it, every one `Label.SURE` points over it), from 1 at the
  least to that, coloured by your fishing skill line with its bonus (`Nodes.Reach`); no red mark on either line
  (Saneroki, 2026-11-11). Out with the highlight (`Art.Unlight`); told anew at a level or a skill.
- **Paths** (`Paths.lua`): kept drawn after a click on the full map (`Paths.Toggle` from `PinView.Act`; `Active`, by
  the pin's flight point or ship, `Key`; the pin glowing, `PinView.Relook`; let go by a second click, by the double
  click's second, `Canvas.lua`, and all by `Paths.Reset` when the full screen goes back or the window hides), and
  while the mouse is on a flight point's pin or a dock's (`PinView` Tip, Left), that pin's
  ways from Core's set *Travel* on a layer of their own (`Canvas.LEVELS.paths`, between the route and the pins):
  every flight of the player's side from that node (`byFromNode`; its path on the flight point's plane), fainter to
  one not found (`Planner.Knows`); a boat's or zeppelin's whole way round (its path's points on their worlds' planes,
  `Planner.Plane`, a leap no line); the tram's two stations straight. A boat's leaps (it sails out of sight, a
  loading screen, and comes in off the next dock; the step from its last point round to its first one too where it
  goes onto another plane or is longer than `Paths.LEAP`) follow its sea lanes (`Paths.LANES`, by its key in
  *Travel*: one a leap in order, or one for both ways; points on Forever's world map, empty in Retail): a Hermite
  curve from where it leaves through the lane's points (from the end nearer it) to where it comes in, on the game
  path's heading at both ends, `Paths.PIECES` pieces between two points (`Sail`, `Sailed`); the lanes share
  stretches where ships share a sea (`NORTH` round Kalimdor from Auberdine, `PART` north of the Maelstrom,
  `MENETHIL` into its bay), kept clear of the terrain's coasts, the world map's painted islands and its Maelstrom
  (centre 0.497, 0.509: 190 of 2004 pixels clear). A zeppelin flies over the land: the two whose straight line
  crossed the Maelstrom have a lane bent round it (Orgrimmar–Grom'gol 285 under it, Orgrimmar–the Undercity 302
  over it), the others none (as before). Straight lines from point to point, the dark edge and the route's art in
  `Route.COLOURS`, only near the view, cut at the canvas' edge (`Paths.Fit`), laid out again with the map.
- **Taxi** (`Taxi.lua`, no frames of its own): hooks after the game's flight maps' `OnShow` and `OnHide` (`TaxiFrame`;
  `FlightMapFrame` once `Blizzard_FlightMap` has loaded, `EventUtil.ContinueOnAddOnLoaded`), as the game shows them by
  its own code. Shown without Shift (the module up; `nativeMap` is the world map's, not looked at): made tiny and clear (`Core.Lend`,
  `Core.Holder.TINY`, alpha 0: never hidden, its `OnHide` would end the talk), the master's flight points read
  (`C_TaxiMap.GetAllTaxiNodes` of `GetTaxiMapID`: slot and state; `TaxiNodeCost`), `Pins.Changed("flights")`,
  and the window filled as always, at the world whole (`Window.OpenTo(Coords.WorldMap())`; never at the master's map
  in Forever: its flight maps are maps of their own, 1463, 1464, 2665, none of our planes; Retail, whose one map at a
  time shows no flight point at its world map: at the master's map). The flight pins then (`Pins.lua`, `Taxi.Node`): `taxi` (the
  node), `size` `Taxi.SIZE`, `here` (glowing, as the focused quest), red where not reachable (`Pins.RED`, its colour
  taken out first, as a flight point not found), their lines
  `Taxi.Lines`; shown whatever the pin filter says, and of the rest of it on the full map only `Taxi.KEEP`'s as it
  says: the party, and of the ways of travel a pin with `ship` (a boat's, a zeppelin's, a pier's: `Pins.For`)
  (`Taxi.Shows`, `Taxi.Over`, through `Pins.Showing`: `Pins.For`, the found herbs and ore, `Areas.Place`, the party's
  marks, `Hybrid.Place`'s minimap dots; the filter's own switches untouched, so the finders stay as they are), at the
  pins' top level (`PinView`), at each one's right its place, zone and price a line each
  (`Taxi.Label`: the game's name cut at its last comma, "Refuge Pointe, Arathi"; a font string, left aligned, on `PinView`'s layer of names, at the pins' layer's level so under every
  button, anchored to the button's right, `PinView.LABEL.GAP` apart; its size `LABEL.MAX` at a view `LABEL.AT` yards
  high, `LABEL.STEP` less for each doubling, `LABEL.MIN` at least, one of `Core.Font`'s per size; shown with its
  button, `PinView.Fit`); a click
  `Taxi.Fly` (`TakeTaxiNode` of its slot; on another a click does nothing, no ping). The mouse on one: `Paths.Show`
  draws `Taxi.Ways`, each hop of `GetNumRoutes`/`TaxiGetNodeSlot` (slots back to nodes) by its flight's path in
  *Travel* (`Paths.FromPath`), else straight between the two flight points where the plane of the pin's map has them
  (`Live.Flights`). Its `OnHide`: the lend returned, the
  pins as always, the window back to its corner (`Window.Back`). The window on its way back (`Filled`, Esc) while it
  is open: `CloseTaxiMap`, so the game closes its own. `Taxi.GiveBack` returns the lend, open.
- **Corpse** (`Corpse.lua`, no frames): dead (`PLAYER_DEAD`), the game's map pin one had (`Live.Waypoint`,
  `Live.Tracked`) kept as the character's `corpse` (once: a `/reload` while dead keeps it), the pin put where one
  stands, followed; a ghost (`PLAYER_ALIVE` with `UnitIsGhost`, a loading screen, and again `Corpse.AGAIN` later):
  the pin moved to `C_DeathInfo.GetCorpseMapPosition` on the map one died on, else the one one stands on, while the
  pin is still ours (within `Corpse.SAME`); alive again (`PLAYER_UNGHOST`, `PLAYER_ALIVE` alive, a login alive) the
  pin one had back as it was, or none, where the pin is still ours; a pin set since stays. `Corpse.GiveBack` does
  the same when the module stands down. The planner's journey for a ghost (`Planner.Ghost`) has no flight points,
  teleports or hearthstone.
- **Danger** (`Danger.lua`, no frames): how dangerous a place is for the player (Saneroki, 2026-11-11). Once, a job of
  Core's scheduler, when the route first asks (`Danger.Work`): every creature of Core's set *CreatureSpawns* that is
  hostile to the player's side (its faction template, *NPCs*' `faction`, and that template's reaction in the set
  *FactionTemplates*, which `dev/tools/game-data` works out from the client's table by the game's rule), no critter,
  no rare, rare elite, world boss or trivial one, whose levels span at most `Danger.SPAN` (3); each of its points marks
  the cells of a grid of `Danger.CELL` (50) yards on its plane within `Danger.REACH` (25) yards of it with its lowest
  level, a cell keeping the highest. `Danger.At(plane, u, v)` then gives the step against the player's level: 2 at
  `Danger.RED` (5) levels above or more, 1 at `Danger.ORANGE` (3), else 0, as the game's `DifficultyUtil` steps its
  colours. A level up colours the line anew a second later (`Route.Again`); the three sets' stamps work it out again.
  In Retail, without Core's data, every place is 0.
- **Route** (`Route.lua`): a way the planner gives, drawn with the game's `Line` widgets from a pool, only the parts
  in view, and from where the player is on (the way's cut, `Route.Cut`): the parts behind are not drawn, the one the
  player is on only from there, and a line of its own (the head) runs from the player's arrow to that point; the
  legs after the next fainter. A little off a walk the head meets the line further on (the plan's join, `Planner`'s
  `Join`), and the line is drawn from there: the parts between the cut and the join hidden, back again where the join
  goes (only the parts the cut passed are gone for good). A dark edge, the game's dependency bar art tinted gold, its glint moved along by a
  `TextureCoordTranslation` animation (no code of ours each frame); walks and lifts gold, flights white, ships and the
  tram light blue, portals violet, the hearthstone and the teleports pale blue (the art is grey, so each shows its colour as it is). The animation is the template of `Route.xml`: the game makes this kind only from XML (one made in Lua has no
  `SetOffset`); where the game has not read the file yet, the glint stands still. A corner that turns more than
  `Route.BEND` degrees is drawn as a curve, from a point before it to one after it with the corner its middle point
  (a curve of three points of the way, so short parts one after the other make one smooth line), in pieces turning
  about `Route.BEND` degrees each: it cuts the corner no deeper than `Route.STRAY` units at every zoom, never past
  the middle of a part. The art runs on from piece to piece and each glint starts at the pulse's moment
  (`Route.PULSE`), so the pieces pulse as one line; the head meets the line on the curve. A walk's pieces are cut
  where its danger changes (`Danger.At`, looked at every `Route.SAMPLE` yards, no piece shorter than 2 units): gold,
  or the game's `QuestDifficultyColors` of very difficult (orange) and impossible (red), `Route.DANGER` where it has
  none; the head takes the colour of the piece the player is on. `Route.Grab(x, y)` tells the stage of the line drawn
  within its edge and `Route.GRAB` units of a point (the waypoint its leg leads to, `leg.toward`, or `"pin"`);
  `Route.Bend` draws two faint lines from that stage's start (the player, on the stage they are on) and end to the
  mouse while it is dragged, `Route.Unbend` takes them away.
- **Dragging the line** (`Canvas.lua`; Saneroki, 2026-11-11: "if we drag the route on the map it will put a new
  waypoint there that the routing goes to first and then to the map pin"): a left press on the full map (not at the
  world, no modifier held) where `Route.Grab` finds the line is a drag of it, not of the map (`grab`): past
  `Canvas.DRAG` the map stays, a ghost of the waypoint stands under the mouse (`Marks.Ghost`) with the faint lines;
  let go, `Planner.Via` puts the waypoint there on that stage; not moved, it is a click as ever. A press on a
  waypoint's mark (`Canvas.Press` with its waypoint) drags that one, small map or full; a click on one is no click
  on the map. On the small map a drag on the line moves the map, as before.
- **QuestLog** (`QuestLog.lua`): a window of Core's of its own (title bar, docks, its grip seen while the mouse is
  on it), in two looks (`Dress`), each with its place and size (`window:Use`): over the full map
  (`store.questLogPlace`) in the layer `DIALOG` with its dark background, the mouse taken, every objective; and
  on the screen alone (`store.questLogSmallPlace`, at first at the screen's right edge `QuestLog.BELOW` under the
  minimap, where the game's quest tracker stands: `Small`, by `Window.Under`, the minimap measured as it stands; one
  moved into the screen's lower half counts as `Window.UNDER`; as high as leaves `QuestLog.FOOT` of the screen's bottom,
  `QuestLog.HEIGHT` at most; measured anew as it goes onto the screen alone, a place never moved follows) in the layer `LOW` without one (no skin, `barLine = false`), the frame without the mouse
  and each row's hit rect only its words (`Reach`), the mouse wheel
  the game's while the list fits, the objectives done left out, no fold marks. One switch for both, `store.questLog`
  (TopBar's button); no buttons on its low title bar (Core's `bare`, `barHeight`). The game's `ObjectiveTrackerFrame`
  lent to a hidden frame (`Core.Lend`; `QuestLog.Tracker`), the log shown or off, while `nativeMap` and
  `nativeQuestLog` are off; either on (`QuestLog.Game`), the game's tracker stays and ours is not shown on the screen
  alone (`QuestLog.Lay`; the switches call `QuestLog.Chosen`), over the full map as its button says; it is a
  managed frame, which the game's frame manager reparents whenever an Edit Mode layout is applied, so a hook after its
  `SetParent` puts it back at once. In Edit Mode too (Saneroki, 2026-11-18): only one quest log to place, so the game's
  stays lent while ours is chosen (its box of Edit Mode, `Selection`, a child of it; Edit Mode's magnets take only
  frames in sight), and with the game's chosen ours is hidden with Core's box over it. An objective's words made anew from the game's
  (`Objective`, `Asked`, `QuestLog.ASKS`). Sorted (`store.questLogSort`, by Core's `titleClick` on its
  title, `titleTip` its tip; the title `%d/%d <sorting>`): by `GetDistanceSqToQuest` (looked at again
  every `QuestLog.RESORT` seconds by a ticker while shown, drawn anew only once the order changed), by level, the
  game's own with its headers, or under `GetQuestTagInfo`'s tag. A `WowScrollBoxList` of rows read from
  `C_QuestLog` (Zone: the game's headers, not as the game keeps them folded, which a window of ours could not undo on
  the screen alone: a zone folded is ours, `store.questLogFolds`, over the full map only; quests with level, failed, watched; objectives; a done quest's turn in from
  `GetQuestLogCompletionText`, else `GetNextWaypointText`, else `QUEST_WATCH_QUEST_READY`, as the game's tracker),
  built again on `QUEST_LOG_UPDATE` once a frame and only while it shows; its `MinimalScrollBar` hidden but while the mouse is on the window and the list
  has more than its room (`HasScrollableExtent`), then at the docked side (`Side`: the window's dock zone, else the
  screen's half its middle is in), in both looks; on the screen alone the list's room at that side `QuestLog.EDGE`
  instead of `EDGE_SMALL` while it is longer than its room (`Margin`, `scrolled`, laid anew by `Scroller`); a click: the quest super-tracked,
  the map at `Where` (the game's quest on a map, `GetQuestsOnMap`; a preview's giver) through `Canvas.LookAt`, its zoom
  kept (`Look`), and its text in or out (`Unfold`, `QuestLog.Text`), once `Canvas.DOUBLE` seconds went by without a
  second click (`Pressed`: told by its own clock as a click on the map is, not by the game's `OnDoubleClick`, as the
  list is drawn anew between the clicks); two: the same without the text, and the map pin there through `PinView.Drop`
  (`Pin`). A quest's place (`Where`): the player's map, the one `GetQuestUiMapID` names, the zones, the next way. Folded (`store.questLogFolded`, by Core's
  `barClick` beside the title; `QuestLog.Fold`, `Body`): the panel and the background away, the frame without the
  mouse, no ticker, no items; a quest's text asked for opens it again. On the screen's right half (`Sided`, from Core's `docked`
  wherever it was put) every row is laid out from the right (`Draw`'s near and far), the title by `window:TitleAt`.
  **The quests' items** (`GetQuestLogSpecialItemInfo`, as the game's tracker; `Special`): `SecureActionButtonTemplate`
  buttons of type `item` on a tray of their own on `UIParent` (the game protects a secure button's parent, and the
  log has to come and go with the map in a fight), placed by the screen at the rows in sight (`Seat`, on the next
  frame after a refresh, a scroll or a move; out of a fight only: `Core.AfterCombat`). While the log is over the full
  map the tray is hidden in a fight by the game's state driver; it is out of sight while the log is carried (Core's
  `lifted`), and the log is not moved in a fight (`usable`). A click acts on the release (`AnyUp`, `useOnKeyDown`
  false, as the tracker), whatever the game's option for keys says; every button and modifier uses it by the template's
  `type`, but for the tracker's link: the link's modifier with the chat's box open (`Linking`) empties `type` in
  `PreClick` and links in `PostClick`, out of a fight only (locked, a click does both). The tooltip is the tracker's
  `SetQuestLogSpecialItem`, by the log's index of the quest now, `SetItemByID` once it left the log. The game sends no
  event for an item's charges: `BAG_UPDATE_DELAYED` compares `Special` with the rows.
  **The quest timers** (`Timers`, `Timed`, `Count`): a frame of their own on `UIParent` (not in `Core.Rest`'s set, so
  they stay seen while the log rests at alpha 0, is folded or hidden), at the panel's top between its margins, in the
  log's layer and above it (`QuestLog.OVER`), the list's top moved down by their height (`room`, `Room`). Read at every
  `QuestLog.Refresh`, the log shown or not, as the game's own read them: Forever's Quest Timers panel
  `C_QuestLog.GetQuestTimers` (the seconds left), else, as Retail's tracker, `C_QuestLog.GetTimeAllowed` of each quest
  neither done nor failed; kept as the `GetTime` each runs out. Shown only while the game's tracker is lent away
  (`lent`), so never beside the game's own (the game's quest log chosen, the module stood down; in Edit Mode they
  stay with ours). Counted down by a
  ticker of `QuestLog.CLOCK` seconds while they show (`DockWatch.Clock`), the last `QuestLog.HURRY` in Failed's red;
  the line mirrored with the log (the time at the screen's edge).
  A quest's text from `GetQuestLogQuestText`, its rewards by the quest's ID (`GetQuestLogRewardXP`,
  `GetQuestLogRewardMoney`, `GetNumQuestLogRewards`, `GetQuestLogRewardInfo`, `GetNumQuestLogChoices`,
  `GetQuestLogChoiceInfo`, `C_QuestInfoSystem`'s currencies and spells: no quest chosen for them), read only while the
  text shows, as rows of the list under the quest, a preview's too (kinds `section`, `text` and `reward`, each `part`;
  `AddText`: as high as `measure` says its words wrap at the list's width, drawn that wide, `row.wrap`, its font,
  wrap and spacing set before its words, `Draw`; `Reveal` brings them into sight), for the open
  quest alone (`open`: a click, the menu's *Quest Details*, a click on its pin). A reward is a cell of its row
  (`Rewards`, `RewardCell`), a plain button, its tooltip the game's by the quest's ID (`SetQuestLogItem`); an item the
  game does not know yet comes in by `ITEM_DATA_LOAD_RESULT` (`missing`). The lab's scene `questlog` shows it all; abandon
  after the game's own question (`GENERIC_CONFIRMATION`); never the quest panels of the game's map (their
  details window is opened by the game's panel manager, which our call would leave tainted).
- **TopBar** (`TopBar.lua`): the full map's controls in Core's title bar (`handle.bar`), made the first time the
  window fills the screen, a frame over the bar's own (its level + 5) with a shade (black, `TopBar.SHADE_ALPHA` at the
  top to none `TopBar.SHADE` units under the bar). The map reaches up behind it: Core's window option `under` (the
  content from the frame's top while full; the bar over it at `Core.Window.UNDER`), `untitled` (no title words), and
  `Window.FullSize` the screen's whole height. Left: the quest log's button, the view's button (`Other`: Blended and
  Scrying in turn, `Core.Set(ns.name, "view", ...)`; shown only while both are offered), the button Dungeons (right of
  the view's button, else of the quest log's: `Arrange`; `Instances.Toggle`; lit while the banners or a dungeon's map
  show, its words the dungeon's name while its map shows, cut short to the button; its floors: `Dungeons.Cards`), the
  zone dropdown right of it (radio entries of the world, then each plane, `Coords.Planes` and `Coords.Elsewhere`, with
  its zones under it, A to Z; never disabled, at the world too; its words the zone shown, else the map). Right, from Core's *Classic windows* (or its first
  button) leftwards (`Place`, anew each time it shows): the pin filter (checkboxes) and the dropdown Sketches
  (`DrawBar.Menu`). `TopBar.Gap()` is the room between, where the search stands
  (`FindBox.lua`); `TopBar.Top()` the bar's height, under which the zone's name (`Label.lua`), a dungeon's floor
  (`Dungeons.lua`, `Room`) and the palette (`DrawBar.lua`) stand. It says what the map shows after each layout.
- **The banners of the dungeons and raids** (`Instances.lua`; Saneroki, 2026-11-15): a view over the canvas as large
  as it, at a dungeon floor's level (`Dungeons.LEVEL`; never both: `Dungeons.Close` closes it, a floor shown or a zone
  shown by `Canvas.Show` too), its ground the sea's colour; a `ScrollFrameTemplate` in the room the bar and the quest log
  leave (`Dungeons.Margins`, which the floor's `Room` uses too), its sheet holding the sections' heads (`Look.Head`) and
  the banners in rows: as many a row as fit at `Instances.WIDTH` (the Encounter Journal's 174 × 96), as large as the
  row allows up to `Instances.LARGEST`, each row in the middle; laid out at each opening and when its size or the log
  changes (`Instances.Refit`, from `Window.Lay`). The list is Core's set *Instances* (`List`, made anew at each opening:
  a raid's day may have come): `byKind`, a raid only with its day (`opens`) in this year or before, "Opens 9 December"
  until that day (the realm's calendar, `C_DateAndTime.GetCurrentCalendarTime`); without the set, `Dungeons.List()`. A
  banner's picture is `Instances.ART` by the set's key (the Journal's buttons, `UI-EJ-DUNGEONBUTTON-<name>`, cut as
  `EncounterInstanceButtonTemplate` cuts them; loading screens cut to its shape), its outline the kit's thin golden line
  (`Look.Outline`, bright under the mouse), a dark shade under its words. Its entrances are Core's *Places* of its
  instance's map (`Entrances`), a find of the map's search made of them (`Found`: `Find.Show`, `Find.Pin`); its zone
  (`zone`) where none is known; its maps `Dungeons.Key` of its map where `Dungeons.Named` knows it. Its quests
  (`Count`) are counted once, as a job of Core's scheduler over *Quests* (after `Data.WhenReady` where they are not read
  yet): yours (side, races, classes) with an objective inside an instance of the list: a creature of its enemies (*Dungeons*)
  or one named as one of its bosses (*Encounters*), or an item more than half of whose sources (`Data.Drops():From`)
  stand inside; once per quest and instance.
- **The search** (`Find.lua`, no frames; `FindBox.lua`): what can be found is read once, at the first search (the field
  taken), a part per frame out of a fight, as Core's jobs over its sets: the NPCs that stand somewhere (their *Spawns*
  or *CreatureSpawns*), the objects with spawns, *Places*, the items that come from somewhere (sold: *Vendors*; given to
  loot or gathered: *Drops*; a reward: *Quests*), the quests of your side, what trainers teach (*Trainers*, named by
  *Spells*, its class by `C_CreatureInfo.GetClassInfo`, its trade by *SkillLines*); what the game tells (the zones and
  continents of the map tree, the dungeons' maps, the flight points of your side, the log, the guild's roster (Core's
  where the module Guild reads it, else asked of the game), the group, your friends, your corpse) at each search. Each
  find keeps its words lowered in three parts (its name, what it is, its further words: services, goods, a trainer's
  trade, a kind's words) and the first letters of its name's and what-it-is's words. A search is one pass: each word
  looked for whole in those lowered words (the game's string search), a word of up to `Find.SHORT` letters also in the
  first letters; only what holds every word is ranked, by Core's `Fuzzy.Rank` (a name whole, what it is at
  `Find.ROLE`, further words at `Find.MORE`), plus `Find.PICK` for each time it was picked before (kept for the
  character, `finds.picked`, at most `Find.KEPT`). The best `Find.RANKED` (with nearness `Find.NEAR`) are measured:
  their points (Core's spawns, a quest's givers, a log quest's place) put into your plane (`Coords.MapToPlane`), the
  yards to the nearest; between two alike the nearer first. Groups by kind, ordered by their best; with nearness one
  list, nearest first. Nothing found: a part per frame, the names that hold the words' letters in their order
  (`Find.CLOSE` of them). Shown (`Find.Show`): the find's points (an item's sources', a spell's trainers'), the nearest
  `Find.PLACES` of them all and at least `Find.EACH` of each, are pins of the kind `find` (`Pins.For` takes them in at
  every zoom, on the full map alone, over every other pin; `PinView` gives them the glow), the map at the nearest
  (`Canvas.LookAt`); the map pin by `PinView.Drop`. A guild member outside your group stands at the middle of the zone
  the roster names (the game tells an addon no other member's place); one in your group where the game tells it.
- **Farms** (`Farms.lua`, its glow on the canvas' layer `farms`, level 6, between the zone's light and the quest
  areas): what gives a thing (an item's creatures and objects by Core's drop counts, `Data.Drops():From`, the
  likeliest `Farms.SOURCES`; each weighed by its chance, an unknown creature's `Farms.UNKNOWN`, a node 1; quests' own
  drops and fishing left out; a creature or an object asked for itself weighs 1), their spawns in square cells of
  `Farms.CELL` yards on their plane, each cell's heat its worth and its eight neighbours'. The hottest cell makes a
  place of the spawns of its three by three cells (the weighed middle, a radius of `Farms.SPREAD` times their weighed
  spread, between `Farms.SMALL` and `Farms.LARGE`), the cells round it spent; then the next, while a cell holds
  `Farms.LEAST` of the hottest's heat and `Farms.FEW` spawns, `Farms.MOST` places at most. A dungeon's map (the game's
  map type) is one place, after those outside. Kept per thing (and zone) until Core's data changes. The glow: Art's
  `mark-soft` in Sane UI's gold, added, `Canvas.Put` over the place's square in yards, alpha `Farms.ALPHA` by heat; the
  full map alone. Each place's pin (Find's kind `find`, `Find.MARKER` large, the item's picture in the found ring).
  `Find.Farms` draws a thing's places (the field does at once when an answer has them), `Find.Show` of a place looks
  at it, of an item draws its places and pins only its vendors and quests. A typed word in no find's words (Find's
  vocabulary, made at the first need) is put right by the nearest word of the same first letter within
  `Find.SLIPS` edits (left out, added, changed, two swapped), and the search runs again.
- **Markers** (`Markers.lua`): kept in the module's saved settings for the account (`ns.store.markers`, a list of `{ id,
  map, x, y, title, text, icon, made }`, `markerNext` the next id; each game's in its own saved files), personal notes,
  never shared or shipped. Alt and a left click on the canvas (not on a pin) is `Markers.New(Where(x, y))` (no marker at
  the world: no zone there); while one waits for its new place (`Markers.Moving`, the card's Move) a left click puts it
  (`Markers.Put`), a right click leaves it (`Markers.Stay`). `Markers.Pins()` makes their pins
  anew after a change (kind `mark`, `Pins.SIZE.mark`, `ORDER.mark` under the search's, never combined: `Apart`;
  `pin.label` their title, drawn by `PinView`'s `Name` on the full map), `Pins.For` takes them in at every zoom on both
  maps while `Showing("mark")`; `PinView.Act` opens the card (`Markers.Open`). The card: Core's kit (`Look.Dress`, its
  grey squares and red buttons, the thin golden outlines round the boxes; the words in a scroll frame that keeps the
  cursor in sight), `DIALOG`, beside the mouse, dragged by its head, Esc through `Core.Escape`. The search's finds of
  kind `marker` (`Find.lua`'s `Marked`; Enter: the map there and its card). Settings' version 6 ticks *Your markers*
  in an older pin filter. Sharing: Core's wire, a block of kind `M` (`Markers.Send`: "1", then a row a marker cut by
  \030: origin, map, x, y, icon, title, words cut by \031; `Markers.BLOCK` bytes of rows a block, more in further
  blocks), to `RAID` or `PARTY` (`LE_PARTY_CATEGORY_HOME`) or `GUILD`; heard (`Markers.Heard`, `Wire.ListenBlock`):
  read (`Markers.Read`: `Markers.TAKE` rows at most, a map that is a number, a point on its map, a known icon or the
  first, the words cut to their most), queued (`Markers.WAITING`), asked one at a time on a card of the kit
  (`Look.Dress`, Keep and No the red buttons), kept by origin (`Markers.Keep`: the maker's character key and number,
  `marker.origin`; `marker.from` the sender) while the setting `markerShares` is on.
- **Drawing** (`Draw.lua`, `DrawBar.lua`, `Plans.lua`): drawings kept in `ns.store.drawings` (`{ id, plan, map,
  kind, colour, width, points }`, the points on their map to four places: a zone's, else a dungeon's floor, as
  `Dungeons.Shown` names it), plans in `ns.store.plans` (`{ id, name, shown, origin, from }`; `activePlan`; a
  marker's `plan`, none: the first). On the canvas the layer `sketch` (`Canvas.LEVELS.sketch`, over the paths, under
  the pins): each drawing's points to the holder's units (`Coords.MapToPlane` into the view's plane), its segments (a
  pen's strokes, a line, an arrow and its head, a circle of `Draw.SIDES`), each the game's line in its colour over a
  dark edge (`Draw.THICK`, `Draw.EDGE`), cut by hand at the canvas' edge (Liang-Barsky, again at `Canvas.Keep`:
  `Draw.Fit`). On a dungeon's floor (`Dungeons.lua`'s `Place` calls `Draw.Floor` at every step and zoom) the same in
  the view's units from its middle, cut at its frame, and your markers there as buttons with their titles (a click
  their card). The mouse: with a tool on, `Canvas`'s and `Dungeons`'s left press is `Draw.Press`/`PressFloor`, the
  right button drags (`Canvas.Under`, `Dungeons.Point`); a frame's `OnUpdate` follows while a drawing is under way (a
  pen's point every `Draw.STEP` units, `Plans.POINTS` at most), let go it is kept when it is long enough
  (`Draw.LEAST`). The eraser takes the drawing nearest within `Draw.REACH`. Sharing a plan (`Plans.Share`): Core's wire,
  kind `M`, version 2, in parts of `Plans.BLOCK` bytes (`Plans.PARTS` at most), each with the plan's origin and the
  share's own stamp; the points as three letters of base 36 each; heard (`Plans.Read`) the parts are put together by
  sender, origin and stamp (`Plans.GATHERING` at once), then asked about on Markers' card, kept by `Plans.Keep`.
- **A dungeon map addon's drawings** (`Exchange.lua`, Forever only: `Exchange.on`): its way of sharing from Core
  (`Core.Neighbours.Sketches("dungeonMaps")`: its prefix and message, its share string, its fields, its marks and
  colours, its dungeon maps as our floors). The string written and read by our own code (`Exchange.Pack`, `Unpack`:
  the table as text, its letters, its two sums; deflate by the game's `C_EncodingUtil` where that is shorter), its
  drawings read from both forms it has (as they travel; as a player keeps them, its backup) into one plain form, then
  a share of ours (`Exchange.Share`: points through `words.charts` onto our floors, or kept on the game's maps that
  have a box; `Thin` to `Plans.POINTS`; colours the nearest by their RGB; `share.left` what found no map), asked about
  by `Markers.Offer` or kept at once when pasted (`Exchange.Paste`, origin `x:` and its sum, or its id in a backup, so a
  second paste replaces). Ours out (`Exchange.Routes`: one of its drawings per dungeon key, one for the game's maps;
  an arrow's head `Exchange.HEAD`, a circle of `Exchange.SIDES`, the floor's art 1002 by 668 or the zone's box for
  their shape; our field `Exchange.MARK` in each) are sent by `Plans.Share` and `Markers.Send` on the same channel
  (`Exchange.Send`, its parts on its prefix by `Core.Wire.Say`, at most `Exchange.MOST_PARTS`), and heard
  (`Core.Wire.Hear`, `Exchange.Heard`: its parts per sender and number, `Exchange.GATHERING` at once, dropped after its
  own time; one with our field left, a Sane UI share came too). A group the game's group finder made shares on its
  own channel (`Markers.Group`: `INSTANCE_CHAT`).
- **The field** (`FindBox.lua`): built on the title bar of Core's window once it fills the screen (`Window.lua`'s
  docked hook, `FindBox.SetShown`), in the middle of the room the bar's controls leave (`TopBar.Gap`, laid anew when it
  changes), as wide as that room less `FindBox.ROOM` at each side (`FindBox.WIDTH` at most, `FindBox.LEAST` at least);
  on Core's skin (round ends, the gold trim); the list under it on the same skin, strata `DIALOG`, as many lines as fit
  down to the screen's bottom (`Room`: less `FindBox.MARGIN` and the foot), the wheel for more, and where they do not
  all fit a scroll bar at its right of the game's thin one's atlases (`minimal-scrollbar-track-*`,
  `minimal-scrollbar-small-thumb-*`: `Scroller`, `Scroll`; the thumb dragged in the list's `OnUpdate`, a click on the
  track a page); the distances and arrows looked at every `FindBox.TICK` while it shows. A find taken (`Take`) puts
  the list in its second state, `picked`: the find at its top, a title, and a row per thing to do (`Acts`: `{ act,
  text, icon, run }`, the game's icons `FindBox.ACT_ICONS`); `Chosen` runs a thing to do or takes a find, `Back` (Esc)
  goes back. Every door of the field and its list is `ns.Gently("map search", ...)` (Core's gentle guard: an error noted
  and told once, Navigation not stood down), the search itself runs in `ns.Safe` (`Ask`, `Answered`): one that fails
  shows `Core.SEARCH_FAILED` in the list (`Failed`); Core's jobs of the search tell their end also after an error
  (`Steps.Run`'s `done`), so the reading goes on with the next set and the close search's list says it failed. A key binding (`Bindings.xml`, `SANEUI_MAP_FIND`) and `/sane map find` fill the screen first and take
  the field once it stands. `GLOBAL_MOUSE_DOWN` elsewhere clears the field's focus.
- **Clicks and pings** (`Canvas.lua`, `Ping.lua`, no frames of its own): every click on the map and on a pin comes to
  `Canvas` (a pin's press and release are the map's, `Canvas.Release(button, pin)`): Ctrl puts the map pin at once;
  two plain left clicks on the same (a pin, or the map) within `Canvas.DOUBLE` seconds and `Canvas.NEAR` units are a
  double click, the map pin where the first was (the pin, or the map's place as it was: a first click may have
  opened a zone); one is the pin's own (`PinView.Act`), else opens the map under it (`Into`), else pings there at
  once (`Ping.Send`): the game takes `Minimap:PingLocation` only in the click's own handler, a ping from a timer it
  blocks as an action of its own (seen 2026-10-23, `UNKNOWN()`), so a double click's first click pings too. The
  game's one way to show a place to the group is its minimap's ping: `Ping.Send` takes the place's yards from the
  player and `Hybrid.PingAt` turns them into the minimap's units (its width over twice its view's radius,
  `C_Minimap.GetViewRadius`) and calls `Minimap:PingLocation`; where the
  view it has does not reach so far, at the nearest step measured that does, for the moment (its zoom set back at
  once; what the game says of it meanwhile is ours), and none past its widest. The pings that come are not heard:
  `MINIMAP_PING` is one of the game's callback events with restrictions (no frame's `RegisterEvent` takes it, and
  the game blocks an addon's `RegisterEventCallback` for it: a blocked action at every login, 2026-10-23), so only
  the game's minimap draws them, where it lies over ours. The game's own minimap turns with the player where its
  setting says so and it is the game's (ours holds it north up): a ping's place is turned with it. In an instance
  (our map not drawn) a click on the game's minimap pings it there itself (`Hybrid.Ping`).
- **The middle button** (`Canvas.Home`): the view follows again, on the player at once; its zoom `Hybrid.Home`'s:
  the small view at the game's step `Hybrid.HOME` (its middle one, 2), the full map where that step's square takes
  `Hybrid.ROOM` of its shorter side (so `Hybrid.Wide` shows that step around the player); where the game's minimap
  is not ours, `Canvas.HOME` yards across the view. One map at a time (Retail), the map the player is on.
- **Other addons' buttons** (`Strays.lua`, no frames but a hidden one to keep them in): while our window is the
  minimap, a frame hanging on `Minimap`, `MinimapBackdrop`, `MinimapCluster` or its `MinimapContainer` that has a
  name of its own whose global an addon set (`issecurevariable(name)` says not secure, and which addon; the game's
  own are secure, Sane UI's left), no larger than `Strays.LARGEST` (64) each way, taking the mouse and not
  protected, its name not ending in a number (one of a pool: an addon's marks of places in the world on the
  minimap, its quests', many at once, are no buttons and stay there; Saneroki, 2026-11-10), is held: its parent,
  points, scale, strata and level kept, and whether its addon fixed its strata and level, the clicks the cluster's
  hiding took from it given back (`Hybrid.Release`), then out of sight until the satchel lays it in a cell
  (`Strays.Place`, scaled to the cell's picture; its strata and level the cell's, free while it is held: one fixed
  stayed under the page and the cell took its clicks; fixed again when given back), unseen there (alpha 0) over
  the round picture the satchel draws of it: its own largest
  texture in the `ARTWORK` layer that shows (`Shows`: shown, not faded to 0, not a mask; a hidden or faded one is
  another state of it), else its normal texture (`Strays.Picture`), else its addon's own icon in the addon list (its
  TOC's `IconTexture` or `IconAtlas`, as the game's compartment takes it), else the game's question mark; a file cut
  inside its frame where it shows the whole of it (`Satchel.TRIM`), an atlas as the game cuts it (cut as a file it
  showed a part of another picture), and round (`Satchel.ROUND`); looked at again every `Satchel.EVERY` second while
  the page shows (an addon may change its picture); the ring and background the common buttons have lie in
  other layers and stay out. Hooks after its `SetPoint` and `SetAlpha` put it back whenever its addon places it
  again or shows it (a drag, its own update, a fade). Looked for at the login, on the next frame (the buttons addons make
  at the login itself, held before another addon that gathers minimap buttons takes them off the minimap a second
  later: `Strays.AGAIN`), 2 and 10 seconds after, a second after each addon that loads, and as the satchel opens. Given back exactly when the game's minimap is the game's again (`Hybrid.Update` tells it) or the
  module stands down. Its name in the satchel is its addon's title in the addon list (no colours), its addon the
  loaded one whose folder's name or title (letters and digits alone, at least `Strays.NAMED`) its own name holds,
  the one ending last in it, then the longest (`Owner`), else the one `issecurevariable` names: code addons share (a
  library the first of them loaded for all, or its event handling) runs in the name of that first one, so the game's
  word alone put one addon's picture under another's title (Saneroki, 2026-11-11). The game's addon
  compartment (`AddonCompartmentFrame.registeredAddons`, both games): each addon a cell of its own, its click
  `entry.func(nil, { buttonName })` and the mouse's coming and going its own, as the game's menu calls them, behind
  `pcall` (a failure there is that addon's: its stack would hold our file, which Core reads as ours). One of the
  same addon as a held button (its title or folder, letters and digits alone) is left out.
- **The satchel** (`Satchel.lua`): its button on the canvas (level `Canvas.LEVELS.satchel`, over the marks), in the
  corner `Satchel.Place` picks from where the window stands, shown only while the window stands small and is the
  minimap, inside the small map's face (`Satchel.face`, the canvas' whole rectangle: the time, `Core.ClockAt`, at its
  top; `GetMinimapZoneText` at its bottom in `Satchel.ZONE`'s colour, never as wide as to run under the button; read
  again every `Satchel.FACE_TICK` by a frame of its own while it shows), in sight only while the mouse is on the map
  (`Satchel.Hover`, from `Window.Hovered`) or the page is open. The canvas hears no `OnEnter` where the mouse comes
  onto the game's minimap over it (that frame takes the mouse for its dots' tooltips), so its tracker starts the look
  under the mouse itself when it sees the mouse on the canvas. The page is a frame of its own (strata `DIALOG`) in the kit's bronze (`Core.Look.Dress`: the heavy bronze frame,
  its title, the game's X; left of the X, at its level, `Satchel.swap`: Core's `Window.Swap`, whose click closes the page and
  sets `nativeMinimap`, as the dropdown *Classic windows* does), beside the window toward the screen's middle, a scroll frame in it no higher than
  `Satchel.ROOM` of the screen. Its sections, each a title over the thin golden line (the zone's: none, `Title`) and a grid
  of `Satchel.COLUMNS` cells, a section with no cells left out: *Sane UI* (first the sound line, `AudioLine.Place`,
  while the client has the game's sound settings, `AudioLine.Offered`; then `Core.Switches`, the modules' quick switches as offered; a
  click its module's `Click` with the mouse button and the cell; filled anew when `Core.OnSwitches` tells a change),
  *AddOns* (`Strays.List`, A to Z), *Pins* (`ns.KINDS` offered here but the section `ns.TRACKING`, in the
  pin filter's order; a click `ns.SwitchPin`, the pin filter's own), *Tracking* (the kinds of `ns.TRACKING` as Pins
  has them, then `C_Minimap.GetTrackingInfo`'s spells: the entries whose `C_Minimap.GetTrackingFilter` has a
  `spellID`, without one `type == "spell"`; not the finders `Nodes.KIND`, nor the townsfolk the game's menu lists
  beside them, `MinimapConstants.OPTIONAL_FILTERS`). A tracking entry is switched as the game's menu switches it
  (`MinimapUtil.SetTrackingFilterByFilterIndex`, else `C_Minimap.SetTracking`) and shown so at once until the game
  agrees (a spell's takes its cast); `MINIMAP_UPDATE_TRACKING` and a change of the setting *Pins on the map* fill it
  anew while it is open. Its first section, the zone's (`Zone`, `Lines`, `Tools`): its title the zone and subzone
  (`GetZoneText`, `GetSubZoneText`) in the minimap's colour for `C_PvP.GetZonePVPInfo` (`Satchel.ZONE`, made
  readable on the paper by `Journal.Ink`); its boxes (`Figures`, `Boxes`: `Satchel.BOX`, four filling the page's width,
  low to keep the page short, a `Journal.Box` with a bold number and a faint word a pixel or two under its digits, the two together in the box's
  middle by `Satchel.NUMBER_AT` and `Satchel.WORD_AT`; a number wider than
  `Satchel.NUMBER_ROOM`, a 12-hour clock's, comes out smaller) from `Core.ClockAt`, `GetGameTime` by `Core.Clock`,
  `GetFramerate` and `GetNetStats` (the world's latency, else home's; both on the box's tooltip); its lines in
  two columns, each a label and a value, from
  `C_DateAndTime.IsDayTime` (Forever only), `HasNewMail` with `GetLatestThreeSenders`, and
  `C_Calendar.GetNumPendingInvites`, each only where the client has it; looked at again every `Satchel.EVERY`
  second while the page shows (its `OnUpdate`), the page laid out anew where a box or a line comes or goes or the
  alarm starts or stops, and at each zone change. Then its cells: *Calendar* (the game's day-of-month atlas), covered out
  of a fight by a secure button of ours on `UIParent` (`SecureActionButtonTemplate`, `type` *click* on the game's
  `GameTimeFrame`, out of sight with the cluster but there), so the game opens its calendar panel as its own code
  (`Cover`: placed and shown only while its cell lies wholly in the page's view; at `PLAYER_REGEN_DISABLED` it lets
  go, so the page moves freely in a fight, where the cell's own click does nothing); *Clock* (the game's
  `TimeManager_Toggle`, a plain show, the satchel closing out of its way; while `TimeManager_IsAlarmFiring`,
  `TimeManager_TurnOffAlarm`); *Stopwatch* (`Stopwatch_Toggle`). The clock's and the stopwatch's cells only once
  the game has loaded its clock (never loaded by our code: that would taint it). The same `OnUpdate` closes the page
  each frame the mouse has left it (`Gone`): by `IsMouseOver`, not `OnLeave`, which also fires on the way into a cell
  (`Held`: the page, its button, or a menu by `Core.MenuOpen`, or a dialog of the sound line, `AudioLine.Held`); only
  once the mouse has been on them since it opened, and after `Satchel.LEAVE` seconds off them, so the way from the
  button to the page is free.
- **The sound line** (`AudioLine.lua`, over Core's `Core.Audio`): the word, a dropdown and a cogwheel, game
  `DropdownButton`s in pencil boxes (`Journal.Box`) whose menus are the game's own (`SetupMenu`): the profiles as
  radios, the one in use first (`Audio.Use`), Disabled's (`Audio.NONE`) with a tooltip; the cogwheel's a title (the
  profile's name, *Sound settings* while `Audio.Disabled`), a checkbox per sound this
  client has (`Audio.Kinds`, `Audio.Set`) with the game's `MinimalSliderWithSteppersTemplate` lent to its row as in the
  pin filter (0 to 100 % in `AudioLine.STEPS`, the game's 5 %), and the buttons Save and Load (the menu stays open,
  its rows read anew: `MenuResponse.Refresh`), New (`Core.AskText`) and Delete (`Core.Confirm`); Save, Load and Delete
  off while `Audio.Disabled`. The gear is the game's silver atlas `GM-icon-settings` as it draws it, else the icon `INV_Misc_Gear_01`. The
  dropdown's words follow `Audio.Watch`, *(changed)* while `Audio.Changed`.
- **Following again:** the tracker follows again where `Again` says, never with a mouse button held. Where the game
  tells no place of the player (an instance) the small view does at once, so the game's minimap is the map there.
  Else as the player walks (they moved since the last look), once the mouse last did something to the map (a drag,
  the wheel; a quest moved to, a map chosen on the bar or by the game count as that: `lastInput`) `Canvas.SOON` (2)
  seconds ago for the small view, `Canvas.AGAIN` (5) for the full map. Ticked, `Canvas.Center` puts the full camera on the
  player whenever the window fills the screen (but at a map the game was asked for, `Window.OpenTo`) and when the box
  is ticked; unticked, the full map no longer follows, and a small view that follows goes on following.
- **Zoomed in again** (`Far`, `Near`): the small view following a walking player, zoomed out past the game's widest
  minimap step (`camera.native` nil, `camera.k` below `Hybrid.Zoom(0)`) and the mouse last on it `Canvas.SOON` ago,
  comes back in at the middle click's zoom (`Near`, shared with `Canvas.Home`: `Hybrid.Home`, else `Canvas.HOME`
  yards). At the game's steps, nearer than its narrowest, on the full map, or before the steps are measured, the zoom
  stays.
- **The first view:** the option's first default is `ns.FALLBACK` (Scrying), so a first load starts there; `Offer`
  then sets the default to `ns.Fallback()` (Scrying where offered, else Parchment), so a reset, a profile read after
  login and a saved view not offered come to a view that can be drawn. `ns.Several` tells whether there is a choice
  at all.
- **Walk** (`Walk.lua`, no frames): Core's set *Walking* (read with Core at the login, as all its sets), made by
  `dev/tools/walk-data` from the game's terrain, buildings, doodads (fences, rocks, trees, piers, the game's invisible
  walls) and water: per terrain tile a block (base64, deflate, CBOR, read by the game's `C_EncodingUtil`) of surfaces
  and rectangles of floors, 2.08 yards a sample, each with its height, kind (the ground, water, a building's floor)
  and region, and the openings into its neighbours. Unpacked when first needed, the `Walk.KEEP` asked for last kept
  (in a job of Core's scheduler an unpacking may end the job's frame); its openings only the first time a search or
  the floor's following needs them (`Walk.Links`: looking up the floors at a place needs none, and they take most of
  an unpacking's time and memory): those of two rectangles of one surface that touch worked out from the rectangles,
  written ones once on their tile with their other way (each opening lies on the facing sides of its two rectangles
  and holds both ways, as `dev/tools/walk-data` makes them). `Under`,
  `Around`, `Nearest`, `Regions`, `Opening`, `Openings`, `Portal`, `Gap`. Floors lie one over the other, and the game
  tells no height of the player (`UnitPosition`'s is always 0): the floor a walker stands on is followed from the
  rectangle they stood on through the openings nearest the way they went (`Walk.Follow`: a cave's mouth, not the path
  up the hill over it), and chosen where it cannot be (`Walk.Floor`): near the height they had (within `Walk.RISE`),
  else outdoors the highest under them, indoors the lowest within `Walk.ROOF` yards, a building's floor before the
  ground (the game's indoors is inside a building or a cave: not the ground deep under Stormwind's buildings).
  **Drops** (format 2, 2026-11-18): one way down off a rectangle's side onto a lower one, off a deck, a cliff or a
  mountainside too steep to walk, with its height in whole yards (`Walk.Drops`, `Walk.Drop`; in the plane its way off
  and where it lands, `Walk.Fall`). A walk takes those up to `Walk.FALL` (54 yards, 49 metres: Saneroki measured a fall
  of 50 metres safe with `/sane falls`); the floor's following takes any (the walker fell); a straight walk none.
  **Hops** (format 3, 2026-11-18): over a step of a mountain's trail between two neighbouring floors on the ground, a
  steep triangle crossed level at most, both ways, with its rise: listed with the drops, marked (`Walk.Drop`'s seventh answer); a walk takes them
  at their yards and the climb's price, the coarse layer's parts and costs as openings.
- **Gates** (`Gates.lua`, no frames): the walking data's coarse layer, the set *Walking*'s field `gates`, made by
  `dev/tools/walk-gates` from its blocks: per terrain tile its gates, where one walks across its border into the next
  tile (the openings between a part of the tile and a part of the next, joined along the border and cut into pieces of
  at most 64 samples, each the same on both tiles: `Gates.Id`, `Gates.Ends`; a part: the rectangles one walks between
  without leaving the tile, `Gates.Parts`), and what the walk between each two gates of one part costs inside the tile
  (`Gates.Cost`: its yards on land, those swum at the walker's price, each yard up `Search.CLIMB` more, of the way on
  foot and the one a rider takes instead, where the one on foot swims, the cheaper). And the ways down a drop, one way
  (`gates.falls`, `gates.landed`, `Gates.Down`): from a gate to another of the tile (of its part or another) down its
  drops, where that saves 10 yards or more on the walk or the walk has none. Unpacked when first needed (some 16 KB a tile), the
  `Gates.KEEP` asked for last kept; a tile's layer made from another block than the one the game holds (another number
  of rectangles) is passed over there.
- **Search** (`Search.lua`, no frames): a walk between two points: A* over the rectangles through their openings
  and down their drops, one way (`Walk.FALL` high at most: to where the line crosses the way off, across to where it
  lands, each yard fallen `Search.DROP` yards more, so of two ways about as long the smaller fall; into another tile
  only where that one is searched rectangle by rectangle; the line pulled through its way off and where it lands)
  (from where a rectangle was entered to where the straight line on to the end crosses the next opening, so open
  ground costs its straight way; a yard swum at the character's own price, its speed on land over its speed in
  water, the planner's `Speeds`: on land the fastest it was seen riding, kept per character as `ride`, so a rider
  goes round where one on foot swims; and each yard up `Search.CLIMB` yards more, a little: the game runs as fast up a hill as on the flat, and the data holds no
  slope over 50 degrees, so a shorter way over a hill or a pass is taken, and Ironforge's mountain, steeper, is
  none), from the floor the start stands on (the player's, followed; where that is a guess, the other floors there
  too, `Search.ASIDE`
  yards more and not counted in its cost, so a walk is found where no way leaves that one: a guess that was wrong, a
  floor the walking data closes in), else from every floor under it and within
  `Walk.ROOF` yards, each over the lowest at the cost of the climb up to it (a place
  stands on its lowest floor rather than on the mountain over it; none: the nearest within `Search.REACH`, else
  within `Search.FAR`, a gap in the walking data), to any
  floor of the regions it starts in under the end or within `Search.NEAR` yards of it (its own floor may be missing
  there: Ironforge's city under its mountain), else the nearest within `Search.FAR` (a tower, a plateau no lift
  reaches). What lies off the walking data is drawn straight and costs `Search.STRAIGHT` times its yards,
  so the line runs from the start to the end itself; the search tells those yards at the end, and `"off"` where no
  floor lies near the start or the end at all (nothing to search). Then the line pulled straight through the openings (a funnel,
  each opening drawn in from its ends); the heap keeps each node's f as it was put in. In two steps over the coarse
  layer: first the price (`Search.Price`), rectangle by rectangle only on the tiles the walk starts and ends on, across
  every other by its gates (a gate reached where an opening crosses its stretch, from its middle held within the
  opening; across a tile to its part's other gates at their cost); where the start's tiles and the end's lie apart,
  guided out of the start's tiles by what the walk costs from each gate on, found back from the end first over the
  gates (`Back`, until every way out of them is reached or what is left costs `Search.SLACK` more than the cheapest),
  and a start priced again in one plan goes out of its tiles as the first time (`Out`, kept in the planner's memo);
  then the line (`Search.Walk`), rectangle by rectangle on the tiles that way crosses only, each step aimed at its next
  gate, what is left estimated along it (`Search.AIM` times: a little greedy), on every tile where it is not found so
  (a layer made from other blocks). A walk many times its straight line is priced at once, and a long one looks at a
  band of rectangles along its way, not at everything as near as its length.
- **Planner** (`Planner.lua`, no frames): the way to the map pin, a graph over the player, the pin, the known
  flight points, the docks, the tram's entrances, the lifts' and portals' ends and where the teleports bring one on
  every plane (the continents and
  Zephras Isle, so a journey may cross a third; the canvas' tracker hands it the player's place): walks (guessed,
  at least as long as the steepest floor needs to climb between them, `Planner.SLOPE`) between the places of one
  plane, `Planner.APART` seconds more between two that share no region of the walking
  data (a place's: its floor's where it is known, with every floor around a guess; the pin's those under it; any
  other's those under it and within `Planner.REGION` yards), the flights of Core's set
  *Travel* the player's side may take (a flight point twice, on the ground and in the air, the air reached by a
  flight only, taking off with the first: a flight over many takes off and lands once, `Planner.BOARD`, and is one
  leg, and one comes down at a flight point only after a flight: no walk follows another there, on from another of
  its floors; at `Planner.FLY` yards a second, `Planner.FASTER` times
  that with the Legacy perk Frequent Flier: `Planner.Pace`, its spell known or its aura on the character), the boats
  and zeppelins of
  *Travel* from dock to dock and its tram from entrance to entrance, those of the player's side or of both (*Travel*'s
  `side`: their towns', by the flight masters near their docks) (all from the game's tables, by
  `dev/tools/travel-data`), its portals (the game's area triggers, and its portal objects one uses: batch 13, their
  places as Forever's servers sent them) from their trigger to where they bring one, those of the player's side or
  of both (`Planner.PORTAL` seconds; with
  walking data only one with a floor at both ends, within `Planner.ARRIVE` yards at their height), the teleports this
  character has from the player to where each brings one (`Teleports`: Core's set *Travel*, kind `teleport`, of the
  player's side or of both; a spell it knows, `C_SpellBook.IsSpellKnown`, with its reagent in the bags, or one of its
  items in the bags that the game lets it use, `C_Item.IsUsableItem`; its cooldown, `C_Spell.GetSpellCooldown` or
  `C_Item.GetItemCooldown`, and `Planner.HEARTH`; where it brings one on its floor where its height is known,
  `Walk.Landing` within `Planner.ARRIVE` yards, a guess (the place is not yet the game's own, and Teleport:
  Stormwind's height is the Wizard's Sanctum's cellar's, closed in), else like the hearthstone's place; after the leap
  the floor followed is that one); the quickest chosen (Dijkstra; a place reached on foot is a node of its own, from which no walk
  goes on: the walk straight on is a way of its own; and no ride brings one back to where the rides since the last
  walk began, as up a lift and straight down again would let a walk follow a walk), the walks then priced by the coarse layer (`Search.Price`)
  (the first from the floor the player stands on: followed every `Planner.FOOT` seconds while there is a pin,
  `Walk.Follow`, else chosen, `Walk.Floor`, and chosen anew after a leap of `Planner.LEAP` yards between two looks,
  a portal; none on a flight, a boat, a zeppelin or the tram; one chosen among others under the player a guess, for which the
  journey counts the regions of every floor around them, until they stand where one floor alone lies under them;
  after a leap, or a hop faster than `Planner.HOP` yards a second (a portal a few yards across: the Wizard's
  Sanctum's, Dalaran's Violet Citadel's), to where a portal brings one, its floor there) and the journey chosen again, up to `Planner.TRIES`
  times while the plan's searches have looked at fewer than `Planner.BUDGET` nodes (`Search.looked`), when one is
  much dearer than guessed or not found (so a walk many times its straight line is never searched as a short one);
  of the journeys whose walks were all priced, the quickest stays (one chosen again by its guesses may come out
  dearer than one before it), its walks searched along their coarse ways for their lines (`Search.Walk`): a walk not
  found is none, and where its two places share
  no region, so is every walk between those regions, and one that ends only as near as one walks (Teldrassil's top
  and the shore under it: the portal is the way; where it stays the way, drawn as near as one walks, then straight); one without walking data at an end stays a guess, drawn straight:
  all one job of Core's scheduler, which a new pin stops; the line of the pin before goes at once. Where along the
  line the player is (the cut): at every step of the tracker, of the next `Planner.AHEAD` parts of it the first
  within `Planner.SLACK` yards of the nearest, never back on the part they are on; the line drawn from there
  (`Route.Cut`). Where the head meets it (the join, `Join`; Saneroki, 2026-11-16: "think a few stops ahead and say you
  need to go there to stay on track"): more than `Planner.BESIDE` yards off a walk, of the places along it from the cut
  up to `Planner.JOIN` yards on (every `Planner.STEP` yards and its corners, on the player's plane), the farthest a
  straight walk gets to from where they stand (`Walk.Straight`, from their floor, every `Planner.FOOT` seconds after
  it is followed: from rectangle to rectangle through the openings the line crosses, into water only where they swim);
  where no walking data lies round them, the farthest (a walk without it is one straight line); none (the cut) on the
  line, on a ride, where their floor is not known or no straight walk gets to any; gone once the cut passes it. The
  arrow of the way asked for turns to it too (`Ahead`). A ship (`Planner.Ship`): its docks and trips from Core's timetable of it (`Data.Ships`:
  the game's way and stays, its sailing at the game's transports' speed, stretched to its time once round where
  *Travel* has it, `wait`, or a ride taught it); the wait for it the time to its next departure where a ride on this
  realm taught its times, else half its round; then it sails to the dock (the stays between included). One boards
  and leaves at the pier, the land nearest where it stops (within `Planner.PIER` yards). The tram (`Tram`): boarded
  and left at the cities' entrances to it (its `docks` in *Travel*), its cost the walks down and up and the loading
  screens (`Planner.STATION`, a guess), half the time between two trains from a station (*Travel*'s `wait`; the
  time to its next train where a ride on this realm taught its times, `Trips:TramNext`) and its run (`time`); drawn
  red, straight from entrance to entrance (its tunnel's map has no plane; in it the line stays
  as it is). A lift (`Lifts.lua`, Core's set *Travel*): each end of its car at its landing (`Walk.Landing`: the
  floor within `Lifts.LANDING` yards of the end nearest it, a yard up or down `Walk.LEVEL` times one across: beside
  its shaft, not on the roof over it), only where both ends have one; its cost half
  the time between two departures from an end (`wait`) and its ride (`time`); drawn gold, straight from landing to
  landing. Between two levels a lift joins (its landings' regions), or a level and a place below it, no walk: the
  lift is the way; and a walk to a lift's end ends on its own level (`Lifts.Heights`: within `Walk.RISE` yards of its
  landing's height, nearer it than the other end's), never on the level over or under it. A place stands below a lift's upper level (`Lifts.Stand`) where its levels are stacked (on a ring
  `Lifts.RING` yards round its shaft a third of the lower level's points lie under the upper: the Undercity under
  the ruins; Thunder Bluff's mesa is beside the land at its foot) and the place lies over the lower level (its known
  floor under the upper's; else the lower level's floors under it; the pin on the lift's own map also over any other
  floor below there, or the nearest within `Lifts.RING` yards where its own is missing); by a lift side by side,
  where the upper landing overhangs the platform, on the upper. Where a lift's two landings lie in one region (the
  Undercity, joined to the ruins far off by its sewers), its levels are that region's floors round it, stacked,
  told apart by height (the upper from halfway between the landings up, the lower near its lower landing's
  height), and a place stands below them only round it: on a map its ends lie on (in that map's box: the
  Undercity's holds the whole city, its Royal Quarter too, which lies farther from the lifts than `Lifts.SPREAD`
  yards), or within `Lifts.SPREAD` yards of it; a place below a level and one on it
  are kept apart also where they share a region; a lift within one region whose levels lie side by side (the
  Great Lift) joins none. A walk's guess between two places
  of known heights (the player, a lift's or a portal's ends, a teleport's landing) counts the climb too. The floor after a ride (`Rode`): at a lift
  joining the line's lift's two levels (`Lifts.Near`, within `Lifts.NEAR` yards) as long as its ride takes, then on
  along the line past it, the player is on the landing at its other end. Planned again when the pin changes, after
  a landing (a flight's or a ship's), when the player is 40
  yards off the line (150 off a ship's way), and when the data arrives; aboard a ship a new pin is planned from
  where it lands (the ship of the plan, or the one Core's `Data.Trips` finds the player on, to the pier of its next
  dock): aboard the plan's ship within `Planner.DECK` yards of its way, where that lies more than `Planner.DOCK`
  yards along it from where it was boarded (`Along`; the town at its dock, by the way it comes in, is not aboard). The flight points the character has found are learnt at a flight master (`TAXIMAP_OPENED`, then
  `TAXI_NODE_STATUS_CHANGED`): its flight map's states (`Current`, `Reachable`; `Unreachable` not found, the game's
  flight map leaves those out) and every plane's as the game's maps mark them (`isUndiscovered`, which the game knows
  once a flight master was opened this session); kept per character as `flightPoints` (the older `flights` held every
  point a flight master listed, found or not, and goes), `Planner.Knows`; only those are flown, and the map's pins of
  the others are red (`Pins.lua`); a pin set before is planned again when they changed. The hearthstone's place is
  learnt where it is bound (`HEARTHSTONE_BOUND`) or where it (or Astral Recall) brought the character, kept per character. The hearthstone is no way of the line (Saneroki, 2026-11-06: the player's to spend): where it
  is in the bags and bound there (`GetBindLocation`), or Astral Recall known (`Planner.RECALL`; the sooner of their
  cooldowns, as a wait, and the cast, `Planner.HEARTH`), and that alone leaves time to reach the pin
  `Planner.SOONER` seconds sooner, a second journey is made with it a way from the player (`Quicker`: `Find` with
  `home`, priced only, no lines searched); where that one begins with it and is that much quicker, the chat tells
  once a pin (`Tell`, `Planner.TEXT.sooner`; `only` where nothing else goes). Where a teleport brings one is the set's: the original game's (batch 14, unverified) or where
  one brought a character, learnt by Core (`src/Core/Data/Teleports.lua`, Core's learned data); the plan is made
  again when Core learnt one (*Travel*'s stamp). Without walking data, straight lines. On a flight (Core's `Data.Trips`) its way on is the
  line's first leg, drawn anew from the player every `Planner.AGAIN` seconds, the plan from where it lands after
  it; without a pin that leg alone. **Waypoints** (`Planner.Via`, `Planner.Drop`, `Planner.Vias`, `Planner.After`):
  the pin's way keeps a list (`vias`, at most `Planner.VIAS`, 8), each a place in its plane; a new one goes on the
  stage dragged (before the waypoint that stage leads to, or last), and the way is planned anew at once. A plan with
  waypoints is a journey to each in turn and on to the pin (`Stages`: `Find` per stage; a waypoint no journey
  reaches is left out; no word of the hearthstone), each leg knowing the waypoint it leads to (`leg.toward`, false
  for the pin's stage, the leg in front the first's) and the plan the list it was made for (`plan.vias`, a copy), so
  one put or passed meanwhile mixes nothing up. Passed (`Passed`, at each step of the tracker): the next one within
  `Planner.THERE` yards, and those the plan led to before the leg the line is at; taken off, the plan going on as it
  is. The pin moved or gone: the list is emptied (`Planner.Update`).
- **Marks** (`Marks.lua`): the player's arrow (Blizzard's world map arrow, turned to your facing), the game's map
  pin, at a fixed size (a right click shares it: `Marks.Share`, `ShareMenu`, `SharePin`; the wire's kind `W`, one
  urgent message, its map, x and y; heard, `Marks.Heard` asks on the markers' card, `Markers.Offer` with `share.pin`,
  `share.same` against the same pin twice; Keep, `Marks.KeepPin`, `Live.SetWaypoint`), and the party and raid (each
  a frame of its own with the game's party blip in the class colour, only the mouse's motion taken: `MemberTip`
  names every member under the mouse, as the game's map does; four times a second, at
  every zoom: `Marks.MemberSize`, from `Marks.MEMBER`'s 44 out at a continent, `Marks.WIDE`, to 22 at the nearest
  zoom, the same step smaller at each notch in, the pin filter's slider on top; placed and sized anew as the view is
  laid out; over the game's minimap too, there every `Marks.OVER`, 0.1 seconds, so ours lie over its own dots of
  them, which it moves at every frame). Between two looks each glides at every frame from where it stands to the
  member's new place (`Marks.Glide`, a frame's `OnUpdate` set only while one is on its way), over the time since
  the place last changed, the time to the next look at least and `Marks.GLIDE` (1 second) at most, so a member the
  game tells of only now and then glides on too; at once where the mark stood for another member (`UnitGUID`), on
  another plane, or lies farther than `Marks.LEAP` (200 yards: a portal). The waypoints (`Marks.Vias`, at each
  layout and when the list changes): a button each, the map pin's art (`Waypoint-MapPin-Untracked`) desaturated at
  `Marks.VIA` (20), its tooltip `ns.TEXT.via`; the left button the map's (`Canvas.Press` with its waypoint: a drag
  moves it), a right click `Planner.Drop`. `Marks.Ghost`: the same art, faint, under the mouse while one is dragged.
- **Indoors** (`Indoors.lua`): inside a building or a cave (`Live.Indoors`: the game's `IsIndoors`, or its minimap
  showing its indoor plan, its view's radius under `Live.PLAN` of its step's outdoors, `Live.OUTDOORS`: the halls one
  may ride through, which the game's `WMOAreaTable` counts as outdoors, so `IsIndoors` says no there; Ironforge's
  35 halls, the Undercity's 191 parts, 358 of 23 buildings) the indoor map of the building
  you stand in lies over the map: the game's own indoor pictures with their black taken out (`Art/Indoors/`, made
  by `dev/tools/indoor-art` from the game's files), placed by Core's set *Indoors* (each part's picture, where it lies
  in the building, the building's place, turn and scale). The building: the one whose part holds your place
  (`UnitPosition`), of those on your terrain tile (`byTile`); its parts whose height reaches yours (from
  `Indoors.BELOW` under their floor to their top), the floor nearest below you on top; without a height every part
  with the game's indoor flag. Never on a street (Saneroki, 2026-10-21): a part under the sky that the game counts
  indoors (`open`: lit as outdoors, `EXTERIOR_LIT`, and its area outdoors in `WMOAreaTable`; Stormwind's 64 and
  Orgrimmar's 12) is not drawn, and where the part you stand in (the smallest holding your place and height) is one,
  that building is passed over. A picture is the square any texture is laid out in, its texture coordinates turned to
  the building's turn inside it and clear around it. Looked at again a few times a second (`Indoors.Track`).
- **The game's minimap** (`Hybrid.lua`): over our map while the view follows you at one of its zoom steps,
  square, as large as the view's shorter side, in its middle, cut by the game's own white square (the game draws
  its dots inside its mask only, whatever cuts its parent, so nothing of it shows past the window; in a window
  that is not square our map alone along the longer side's ends: bands of a texture of our own as its mask left
  it empty, no dots and no arrow); above the map's
  layers and under our marks (its layer and level set again each time it is placed), its ground off (as Blizzard's hybrid minimap does), so only its
  live dots and their tooltips show, indoors too (its own indoor plan on black stays off; our own indoor
  maps lie under its dots, `Indoors.lua`). Its
  clicks go through to our map (`SetMouseClickEnabled(false)`: its pass-through buttons the game blocks for addons); its border, zoom buttons and the rest of the game's minimap
  cluster are out of sight and take no clicks (Edit Mode's selection keeps its). Each step's radius is read
  from the game. Taken out of combat, every part kept first and given back exactly. On the full map it stands
  around the player at the map's own zoom (`Hybrid.Follow`, each step of the canvas' tracker): square, at its
  widest step whose square takes at most `Hybrid.ROOM` (half) of the canvas' shorter side (none at a zoom too
  close for its narrowest), shown while wholly inside the canvas (`Hybrid.Keep`); a click there pings as anywhere
  on the map (`Ping.lua`). Our player's arrow stands over it in both views (`Marks.Player`; the game's own arrow on
  its minimap, where it draws one, lies under ours): the arrow shows wherever the game tells your place. Only
  always, in both views (`Pins.ALWAYS`; but at a flight master, `Taxi.Shows`). In an instance, where the game tells no place of
  yours, the small view's game minimap is the map alone: in its middle at the view's step (the game's own while
  the view has none), its ground on (`C_Minimap.SetDrawGroundTextures`), whatever the pin filter says; off again
  once your place is known, and on, as the game has it, when given back.
- **The game's map** (`Native.lua`): the keys bound to the game's map, quest log and minimap click a button
  of ours (override bindings, out of combat, again when the bindings change). While our own key `SANEUI_MAP`
  (`Bindings.xml`, `Native.Own`: `Window.Toggle`) has a key (`Native.Split`), the game's map key is left to the
  game: its own binding runs `ToggleWorldMap` (secure, the game's; our code never opens its panels), and a hook after
  `ToggleWorldMap` that finds the game's map shown lets it stay (`kept` until it hides), while every other way to it
  still opens ours. Every other way to the game's
  map shows `WorldMapFrame`: a hook after its `OnShow` makes it unseen at once and hides it on the next frame
  by its own `Hide`, and ours opens at the map it was asked for; with the game's quest log chosen (`nativeQuestLog`,
  *Classic windows*) the quest log's key stays the game's, and a map that shows its quest log beside it on that next
  frame (`Native.GameQuestLog`: `WorldMapFrame.QuestLog`, the game's `QuestMapFrame`) stays. Never the game's `ShowUIPanel` or `HideUIPanel`:
  their manager keeps the open panels in slots of its own, which our call would leave written by our code until
  a `/reload`, and the game's next panel there (the character sheet) would open as ours and fail on a secret
  value; a panel hidden by its own `Hide` the manager mends by itself before it shows the next one
  (`RepairUIPanelState`). In a fight the game's map stays open as the game's (hidden by our code then, its
  `OnHide` would run as ours in the fight). To see it in the game: `/console taintLog 1`, `/reload`, a click on a
  quest in the objective tracker (our map opens), then C (the character sheet): `Logs/taint.log` has no line of
  Sane UI's for it.
- **The setup** (`Setup.lua`): the module's own steps, words and boards handed to Core (`Core.Onboarding.Add`,
  title *Map*); the window, its controls and keys are the addon Onboarding's (`src/Onboarding/README.md`). The hot
  corner's page words the Edge section's switch `expandClick` as two round buttons (a step's own entry `{ key, text,
  choices, column }`, `Controls.lua`); the keys' page binds `SANEUI_MAP`, the game's `TOGGLEWORLDMAP` and
  `SANEUI_MAP_FIND`. Each board is drawn on the window's grey box from the game's art (the tutorial arrows
  `NPE_ArrowRight` and its glow, turned by `SetRotation`; the cursor `Interface\CURSOR\Point`; the minimap's arrow;
  the tutorial mouse icons; the map pin `Waypoint-MapPin-Tracked`; the route's own line art) and Core's thin golden
  outline, anew at each change. The big arrow (`Setup.Point`): a frame of its own on `UIParent` at
  `FULLSCREEN_DIALOG`, no mouse, its middle `Setup.REACH` from the spot Core's `edge:Spot()` gives (the corner's
  square or the side's strip in sight: Edge.lua), turned that way (`Setup.ANGLES`), a Translation of `Setup.TRAVEL`
  bouncing towards it; looked at anew every `Setup.LOOK` seconds while it shows (Edit Mode docks the map elsewhere,
  the switch changes, the map fills the screen); shown by the corner's and Edit Mode's boards, gone with their
  `OnHide`.
- **What the game tells** (`Live.lua`): the player, the map pin, the group, the quests, the flight points,
  rares and chests nearby, the game's own points and the explored parts of a map, each read when the game says
  it changed (one message `LIVE` a frame). The player and the pin are drawn now; the rest is for the pins.
- **The window** (`Window.lua`): one of Core's (kind `screen`, docked `TOPRIGHT`, in the layer of the game's
  minimap), Edge fills the screen; laid out in its `docked` hook once it stands. Full, the quest log at the left
  (its width comes in with the window's motion), the canvas to its right, the bar over it. With the game's
  minimap chosen the small window rests (alpha 0, the canvas takes no mouse and holds no texture) while the
  corner's push still fills the screen; Edit Mode shows it. The Classic windows are kept choices (Core's
  `checked`, `back`).
- **Retail's map: the game's own map tree, one map at a time** (Saneroki, 2026-10-25; `Camera.Retail.lua`, read in
  Retail alone): where WoW: Forever's map is one world to roam, Retail's is the game's own maps, as its own map shows
  them. The map shown (`camera.shown`) fills the view whole at first; the wheel zooms in on it up to the largest
  scale of its art (as near as the game's own map comes, or `Camera.DEEP` units to a pixel of its art) and out to it
  whole; a click goes into the map the game says is under the mouse (`camera:Under`, as its `NavigateToCursor`), at
  every level, lit up before (`Art.Light` on the map shown); the bar's map selector goes up to the map over it: a zone,
  its continent, Azeroth, the Cosmic map of every world (`StepOut` the camera's way up; no click of ours since
  2026-11-18). Following the player, it shows the map the player is
  on (`Camera.Wanted`: the game's best map, or the first over it that can be shown). Only that map's art is drawn, in
  the layer its zoom asks for (`camera.layer`, as Blizzard's scroll controller picks the layers), with its explored
  parts; the pins and the quest areas are that map's (`Pins.For`, `Areas.Place`), at a continent only the continent's
  kinds. The spaces stay Forever's (`Coords.lua`): the map shown lies in its plane, in yards, so the pins, the party,
  the route and the game's minimap stand where they stand in both games; Azeroth is drawn in a continent's plane on
  it (`Coords.WorldBox`). Two answers of the map tree differ in Retail: a map whose box lies in another world than
  its continent's (a battleground, a dungeon's floor, an isle of its own) is a plane of its own, and the Cosmic map
  is a sheet of its own (`Coords.SHEET` wide, its art's shape). The map selector has the Cosmic map first.
- **Forever and Retail:** one code for both games. Retail has none of Core's data yet (Core refuses Forever's
  sets there), so what needs it stands down without a word, and what needs a system only Forever has too; the
  minimap and the map work from the game's own API (`ns.Has`: a set ready or still being read):
  - the views: Scrying and Blended need Core's terrain (`Terrain.Possible`, the set *Tiles*): not offered, and
    a view not offered falls back to Scrying or, without it, to Parchment (`ns.Fallback`), the game's own map
    art (one map at a time, above; no stitched map, no outlines: `Outlines.lua` and `Coasts.lua` are Forever's
    world, left out of Retail by their TOC lines). In the small view at the game's
    minimap's steps the game's minimap keeps its own ground there, the land as it lies (`Hybrid.Place`), the
    golden line over it (`Canvas.OVER_GROUND`; in Forever the line lies under the game's dots); past them, and on
    the full map, Parchment with its dots;
  - the game's minimap given back round where the game's code sets no mask (Retail: `Hybrid.ROUND`, the engine's
    own; Forever's `UpdateMinimapConfig` sets it there);
  - the continents beside the world map, under the map over it (Retail's Outland, Draenor, the Shadowlands:
    `Coords.Top`, `Coords.Elsewhere`): in the map selector after the world's, each a map of the tree (above); the
    dungeons listed from the top of the map tree;
  - the pin kinds only Core's data has (offers, low, later, done, services, possible herbs and ore, books: their
    `data` in `ns.KINDS`) are not in the pin filter nor the setting's list (`ns.KindOffered`); the game's own
    (the log, flight points, places, rares, treasures, entrances, links, the group, quest areas) show;
  - herbs and ore: Retail's tracking holds all finders at once and keeps them through death (`Nodes.TOGETHER`):
    each on while its kind is, no turns (the switch is not there); the found ones need the minimap's answers Retail does not give
    (`Found.Works`), the sparkles Core's herbs and ore (`Nodes.Known`): neither runs, the far ones neither, the
    game's interact settings are left as they are, and their switches (and the section's header) are not on the
    options page; a game that tells no skill line's rank greys no herb (`Nodes.TooHard`);
  - the trip on screen and the ship times need Core's set *Travel*: their switches are not there; the route to
    the map pin is a straight line, as anywhere without walking data; the indoor map needs the set *Indoors*.
- **When something fails:** the module stands down: the keys go back to the game, its minimap back where it
  was, our window goes (`ns.GiveBack`); what may not be done in a fight waits for its end.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Navigation.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Art/banner.blp`, `Art/icon.blp` | The module's logo (a compass rose; *Navigation* on its banner): one of Sane UI's family of logos (`dev/tools/logo-art`), its banner at the top of its options page, its icon in the addon list (the TOC's `IconTexture`). Original art of Sane UI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/Logos/maps-banner.png` and `maps-icon.png` |
| `Navigation.lua` | The module's table (`ns`), its texts and settings, `/sane map`, `GiveBack` |
| `Camera.Retail.lua` | Retail's camera: one map at a time from the game's map tree (into a map, out to the one over it, the wheel within it, its art's layer), following onto the map the player is on; Retail's two answers of the map tree (`Coords.PlaneOf`, `Coords.Box`). Read in Retail alone |
| `Coords.lua` | Map, world and plane; a map's box; the map tree, the planes (the continents, and a map of its own on the world map) and the links between them, the top of the tree and the continents beside the world map (Retail's); the terrain's grid; the player's place. No frames |
| `Camera.lua` | Where a view looks: middle, zoom, following, the level its zoom shows; drag, wheel, one map out. No frames |
| `Live.lua` | What the game tells while playing, read when it changes; the flight points without the retired ones (`Live.Retired`: a name *zz...*). No frames |
| `Ping.lua` | The game's minimap ping on our map: a click's ping sent by the place's yards from you (after a double click's time), the group's pings kept where they are. No frames |
| `Canvas.lua` | The frame the map is drawn in: holder, layers, pools, layout, the tracker, the mouse |
| `Terrain.lua` | The terrain layer: the game's minimap textures from Core's set *Tiles*, and the overview |
| `Outlines.lua` | The zones that have an outline, by their plane's instance (the isle's too): made by `dev/tools/terrain-art`, not by hand; Forever's world, read in Forever only (its TOC line) |
| `Coasts.lua` | The tiles on a coast, which have a finer mask of their own, by their plane's instance: made by `dev/tools/terrain-art`, not by hand; Forever's, read in Forever only |
| `Art.lua` | The view Parchment: Blizzard's world and continent maps, the stitched map, every zone's full map cut to its outline; the highlight under the mouse |
| `Pins.lua` | The pins as plain records: the game's and Core's data per map, one per thing, filtered, side by side in a cloud where they would cover each other. No frames |
| `Goals.lua` | What your quests still ask of the world and where exactly it stands: the open objectives' things at every spawn Core's data knows. No frames |
| `Walk.lua` | Core's walking data: a tile's block unpacked, its rectangles, regions, openings and drops (one way down, `Walk.FALL` high at most for a walk); the floor a walker stands on, followed or chosen; whether a straight walk from it gets to a place (`Walk.Straight`). No frames |
| `Gates.lua` | The walking data's coarse layer: each tile's gates into the next tiles, what the walks between two of them cost, the ways down a drop between them, the parts of a tile. No frames |
| `Search.lua` | A walk between two points over the walking data, from the floor the start stands on to a floor at the end, down drops one way: priced across the tiles by their gates, then drawn along that way. No frames |
| `Lifts.lua` | The lifts of Core's set *Travel* on the walking data: each end at its landing, the levels they join (stacked or side by side), where a place stands among them. No frames |
| `Taxi.lua` | At a flight master: our full map in place of the game's flight map (Shift held: the game's), its flight points large, a click flies there, the way there drawn. No frames of its own |
| `Falls.lua` | The fall meter (`/sane falls`): each fall's height from its time in the air (`Falls.Height`: the game's gravity up to its fastest fall, a jump's way up taken off) and the health the landing took, told in the chat. One frame, looking each frame only while on |
| `Corpse.lua` | While dead: the map pin at your corpse (where you fell, then where the game tells it), the one you had back once alive again. No frames |
| `Planner.lua` | The way to the map pin over every plane: on foot, by the flights this character knows, by boat and zeppelin, by the tram, by lift, through portals, by the teleports it has (the hearthstone told in the chat where it is quicker); where along it the player is. No frames |
| `Label.lua` | The zone under the mouse named at the top of the full map: its name, its levels, the fishing skill its waters ask (Core's set *Fishing*) |
| `Areas.lua` | A quest's areas, as the game shades them (`QuestPOIFrame`), over each zone in view |
| `Instances.lua` | The bar's Dungeons: the dungeons and raids of Forever this year (Core's set *Instances*) as banners over the full map, by level in two sections, each with its picture, levels, your quests, a raid's players and day; Route, Show on the map and Its maps; scrolled, beside the quest log |
| `Dungeons.lua` | The maps of the dungeons and raids, chosen in the bar: over the map in its place, by floor (big buttons at the right), whole beside the bar and the quest log, zoomed and dragged; inside one the small map's whole map, a wheel notch out past the game's minimap; each floor's ground under its art in Scrying and Blended (Core's set DungeonGround) |
| `Route.xml` | The glint's pulse along the golden line: an animation template (the game makes that kind only from XML) |
| `Danger.lua` | How dangerous a place is for you: a grid per plane of the highest level of the enemies of your side spawning near each cell (Core's *CreatureSpawns*, *NPCs*, *FactionTemplates*), stepped against your level as the game's colours are. No frames |
| `Route.lua` | The golden line of a way, from the player on, the parts in view: walks and lifts gold (a walk orange or red where enemies above you spawn near it), flights white, ships and the tram light blue, portals violet, the hearthstone and the teleports pale blue; the stage under the mouse and the bend while it is dragged |
| `Paths.lua` | The ways of the flight point or dock under the mouse: each flight of your side from it white, a ship's way round light blue, its leaps along our sea lanes round the Maelstrom |
| `PinView.lua` | The pins drawn: a pooled button each, in the game's looks, tooltips, clicks; a rare's tooltip as a dungeon boss's, its 3D model beside it with Alt |
| `RareTracker.lua` | The Sane Rare tracker: rares, treasures, books and events near you (the game's marks on the minimap; a rare's nameplate, target or mouseover; a chest or book the interact key picks; a book still needed within 100 yards) told at once by a notice at the screen's right edge under the minimap, dragged where you like (its model or icon, name, rank and level, how far and which way) and the game's war horn; a double click: the map pin there, a right click: away; `/sane testraretracker` |
| `Marks.lua` | The player's arrow, the map pin and its sharing, the waypoints (and the ghost of one dragged), the party and who each is, the pings |
| `Nodes.lua` | Herbs and ore: what one is by its name (Core's *Objects*, *Drops*), its picture, your skill for it; the finders (Find Herbs, Find Minerals, Find Fish) switched by the pin filter and in turn by yards moved, silently, and back on after you revive; one switched on outside the filter switches its kind on there. No frames |
| `Indoors.lua` | The indoor map of the building you are in: the game's indoor pictures without their black, at your floor |
| `Art/Indoors/*.blp` | The indoor pictures, one per part of a building, made by `dev/tools/indoor-art` |
| `Hybrid.lua` | The game's minimap over ours: taken, placed, given back |
| `Found.lua` | The herbs and ore the game's minimap shows: found by asking its tooltip at points of it, kept in yards, drawn over it in their pictures, each a button (tooltip; a click: a ping there, a double click: the map pin there); what is found goes to `Core.Sight` for the guide's detours; `/sane nodes`. Forever from build 70862 (`Found.SILENT`): found under the real mouse alone, on the spawn of Core's nearest it. Where herbs and ore can be: Core's spawns around you, half opaque, under the game's minimap's dots (`Found.Draws`) |
| `Sparkles.lua` | Gold sparkles on the plate of the herb or ore the interact key would gather; the game's interact key settings set and put back |
| `Glints.lua` | Far herbs and ore: the found ones beyond the sparkles' reach marked on the screen in their direction (their picture in the leather ring, turned so its point shows the way to them, their yards), through a camera taken to be behind you; those outside the view at the screen's edge |
| `Art/mark-pointed.blp`, `Art/mark-round.blp` | The leather ring with its point (the far herbs and ore) and round (the minimap's found ones): original art of Sane UI, from the render Saneroki picked (`assets/interface/far-marks/leather-ring.png`), made by `dev/tools/mark-art` (`assets/FarMarks/`) and `dev/tools/art` |
| `Art/mark-soft.blp` | The soft round mask of a herb's or ore's picture where it can be (Found.lua, PinView.lua): white, whole within half its radius and falling smoothly to clear at its edge, drawn by `dev/tools/mark-art --soft` (`assets/FarMarks/soft-mask.png`), made by `dev/tools/art FarMarks-soft` |
| `Strays.lua` | Other addons' buttons from round the game's minimap held for the satchel, and the addons of the game's addon compartment; given back with the minimap (no frames but a hidden one) |
| `Satchel.lua` | The small map's face under the mouse (the time at its top, the zone at its bottom, the satchel's button) and the satchel: its button on the small map and its page: the zone with the times, frame rate, latency, mail and the game's calendar, clock and stopwatch; Sane UI's sound line and quick switches, the addons' buttons, the pins, and the tracking (the pin filter's section Tracking and the game's tracking spells), in the kit's bronze |
| `AudioLine.lua` | The satchel's sound line: Core's sound profile in use in a dropdown, a cogwheel with the game's five sounds (checkbox and slider) and the profile's Save, Load, New and Delete |
| `Native.lua` | The game's map kept closed, but while it shows its quest log and the game's quest log is chosen (Classic windows); its keys |
| `QuestLog.lua` | The quest log, a window of its own over the full map; pinned, on the screen while the map is small too, in place of the game's quest tracker; sorted by proximity, level, zone or type |
| `DockWatch.lua` | At a dock or the tram's station: the ways waiting there, when each arrives and leaves (no frames) |
| `TripView.lua` | The travel overlay, high up the screen: the trip you are on (Core's `Data.Trips`), or the wait at a dock; a fine golden line moving smoothly; the way out of a flight or a vehicle, in place of the game's leave button |
| `TopBar.lua` | The bar over the full map: the quest log's button, the views, the button Dungeons, the map selector, the sketches, the pin filter |
| `Find.lua` | What the full map's search finds and where: Core's NPCs, objects, places, items and their sources, quests, what trainers teach; the game's zones, dungeons, flight points, log, guild, group, friends, corpse; the words typed read (nearest, who sells, in a zone, levels, not, or); the finds ranked and measured; their pins (kind `find`). No frames |
| `Plans.lua` | Your plans (*sketches* to players): markers and drawings grouped, the active one, shown or hidden, undo and clear, a plan shared in parts and kept whole (no frames) |
| `Draw.lua` | Your drawings drawn on the map (the canvas' layer `sketch`) and on a dungeon's floor, the palette's tools at work (pen, line, arrow, circle, eraser, marker), your markers on a floor |
| `Exchange.lua` | Sketches shared both ways with a dungeon map addon Sane UI knows, in its own way of sharing (Core's words for it): its share strings written and read, its drawings as ours and ours as its, its shares heard, ours sent in its format too; **Paste from ...** in the Sketches menu (no frames) |
| `DrawBar.lua` | The dropdown Sketches on the full map's bar (each sketch shown or hidden, its own menu) and the palette: the tools, the colours, the widths, the plan's dropdown and its menus, Undo and Clear |
| `Markers.lua` | Your own markers: put with Alt and a click, kept for the account; their pins (kind `mark`) and their card (a small window in the kit's bronze: reading and editing, Move, the map pin, Delete) |
| `Farms.lua` | Where to farm a thing: the places thickest with what gives it (its creatures by their chance, its nodes), clustered from Core's spawns on a grid of cells; their soft gold glow on the full map (the canvas' layer `farms`) |
| `FindBox.lua` | The search's field in the middle of the full map's title bar and the finds' list under it: groups, rows (picture, name, what and where, how far, the arrow), the keys, the menu, the tooltips, the words searched before; the key *Search the map* |
| `Bindings.xml` | The keys *Sane UI's map* (full screen and back; once bound, the game's map key opens the game's map) and *Search the map* (the full map, the cursor in its search), in Sane UI's section of the game's key bindings |
| `Window.lua` | Core's window: the top right corner, the full screen, the two cameras, the view buttons |
| `Setup.lua` | The setup, step by step: its six pages' words, switches and keys, their boards, the big arrow into the hot corner (the window is the addon Onboarding's) |
| `Art/Terrain/*.blp` | The terrain's overview: the game's minimap textures, smaller, the water cut away, made by `dev/tools/terrain-art` from the game's files |
| `Art/Zones/*.blp` | Each zone's outline over its map's box, made by `dev/tools/terrain-art` from the game's files |
| `Art/Sketches/*.blp` | The stitched map: every zone's full map on its continent (or the isle), in the terrain's blocks, made by `dev/tools/terrain-art` |
| `Art/Edge.blp` | A map's box with its paper frame faded off, for Blizzard's world, continent and isle maps |
| `Art/Sea.blp` | The sea's waves: the game's own ocean texture (its first frame), its light alone in white, made by `dev/tools/terrain-art --sea` |
| `Art/SeaShade.blp` | The sea's shade: a tileable soft noise, alpha only, made by `dev/tools/terrain-art --sea` |
| `Art/Whirlpool.blp` | The Maelstrom's whirlpool, 2048 x 2048: the spiral of Forever's world map art repainted as foam by Qwen-Image 2.1 (Saneroki's pick, `assets/Whirlpool/whirlpool-foam.png`), its foam alone in white, made by `dev/tools/terrain-art --whirlpool` |

Tests: `dev/tests/navigation.lua`.

## History
- **2026-11-18, the quest log under the minimap; ours or the game's:** Saneroki: "Can we put it underneath the minimap
  as default where the native questlog normally is? And make sure that you either see ours or the native one,
  depending on what you selected in the classic widnows." The log on the screen alone starts at the screen's right
  edge under the minimap (`QuestLog.Small`, `BELOW`, `FOOT`; the minimap's bottom measured by `Window.Under`, which the
  Sane Rare tracker's notices use too), where the game's quest tracker stands. The game's quest log chosen (ticked in
  *Classic windows*, or *Show the game's map*): the game's quest tracker on the screen and ours gone from it; before,
  ours still showed there and hid the game's (`QuestLog.Game`, `QuestLog.Chosen`). Then: "leave them [the rare
  notices] there and make sure it draws over the Questlog" (they stand in the layer `HIGH`, the log on the screen alone
  in `LOW`, now a test holds it); "When you are in edit mode, only one questlog that can be placed should be visible":
  the game's quest tracker stays out of sight in Edit Mode too while ours is chosen (`QuestLog.Tracker` no longer gives
  it back there), and ours is hidden with its box while the game's is.
- **2026-11-18, hops tightened:** Saneroki: "it does work now but the getting up on a steep slope or jumping up is a
  little to loose. There are areas where it thinks you can get up there but you can't". A hop now joins only a
  sample's neighbours (not over a whole steep sample), crosses at most one triangle over 50 degrees, and gains no
  height on it (crossed level or going down: nobody walks up ground that steep); the strictest rule that still climbs
  the ridge east of the Undercity (418 hops on its tile, 1,558 before). Rebuilt again: 107,512 hops (401,238), 32.4 MB of blocks; the climb east of the Undercity as it was (998 yards); offline, as many walks off the data as with the drops alone, and Bodley's journey flies again.
- **2026-11-18, hops: up a mountain's trail.** Saneroki: "it does not work. I know I can go over the right side of
  undercity from south to north by climbing up the mountain and then jump down the cliff but the route does not show
  that route." The ridge east of the Undercity's ruins was a region of its own (no walk up it in the walking data), so
  its drops were left out (a drop only within one region). On the game's own terrain the gentlest way up from the lake's
  shore is walkable all along but for eight triangles (the steepest 57 degrees, a few yards each); the walking data lost
  it twice: a sample stands for its cell's west or east triangle alone (the trail zigzags over the north and south
  ones), and steep bits a few yards wide split it into pockets. Now `dev/tools/walk-data` adds hops (format 3): between
  two ground floors up to 2 samples apart that the samples do not join, where the triangles of the cells round them
  make a way with at most 2 over 50 degrees, none over 60, nothing built there; both ways, joining regions as openings
  do. The search, the coarse layer and the floor's following take them. The walking data rebuilt as a correction of
  the day's version (`--build`: the master is a plain file near its host's 100 MB): 401,238 hops, 999,359 drops, 36.0 MB of blocks. That route now: 1,001 yards (2,316), up the valley along the ruins' east wall to about 110 yards, down a drop of 47.
- **2026-11-18, the setup step by step; no right click zoom:** Saneroki: "Can you make a onboarding window for the
  navigation module", with the hot corner one of the first pages (the mouse into it, or a click in it, or a key;
  "Remind people that it is possible to use a combination of things"), "a very big clear arror during the onbarding
  on the corner so people know that they should move the mouse all the way into the corner", keys for "either the
  native map or our map", Edit Mode moving the hot corner with the map, the quest log's click and double click, the
  map's double click and right click. So `Setup.lua`, six pages in the addon Onboarding's window, the big arrow over
  everything while the corner's and Edit Mode's pages show (Core's `edge:Spot()`), the key `SANEUI_MAP` and the game's
  map key left to the game once ours has one (`Native.Split`, a hook after `ToggleWorldMap`), the button *Set up step
  by step* on the options page (`ns.Offer` finds the view's switch by its key now). And "remove the rightclick that
  changes the zoom level or zooms out": a right click on the map steps out no more (`Canvas.lua`), nor on a dungeon's
  map (the whole floor again on the small map, back on the full one): the wheel zooms, the middle button and the
  bar's button stay.
- **2026-11-18, routes down drops:** Saneroki measured it with the fall meter: "A fall of 50 meters is safe". So the
  walking data has drops now (format 2, `dev/tools/walk-data`): one way down off a floor's edge where the ground falls
  away (an upright cliff, a deck, a mountainside too steep to walk, over at most 24 samples) onto the first floor more
  than 2.6 yards lower, up to 70 yards, nothing built on the way, no railing, no roof over the landing; each kept with
  its height, only within one region (regions stay two-way). A walk takes those up to `Walk.FALL`, 54 yards (49
  metres), never back up, each yard fallen a yard more (`Search.DROP`), the line drawn through where it leaves and
  where it lands; the coarse layer has the ways down a drop between a tile's gates, one way (`dev/tools/walk-gates`
  format 2); the floor a walker stands on is followed down a drop. Another height is a `walk-gates` run and
  `Walk.FALL` only. Rebuilt from the game files of 70707 (the world of 70938 the same; 70938's extraction lacks the
  buildings' group files, and `walk-data` refuses such a folder now): the rectangles and openings as before, tile for
  tile, and 822,719 drops (71 % of them under 10 yards, 6,870 of 50 yards and more); the blocks 31.0 MB (23.3) (card
  #559).
- **2026-11-16, the fall meter:** Saneroki: "The fall damage in this game is pretty low. You can fall quite far
  before you actually die. I want to make the routing allow for bigger fall downs so the routing can route over
  mountains". The walking data has no fall yet (two floors one way only within 2.6 yards, both ways), and how high a
  fall the routes may take is measured in the game first: `/sane falls` (`Falls.lua`) tells each fall's height, from
  its time in the air (the game tells no height of the player), and the health it took. The drops themselves wait
  for that number (card #559).
- **2026-11-16, no NPC a gold coin; the map pin shared; who the party's dots are:** Saneroki: "We need to give all
  npcs that use the yellow coin / dot as their pin a different icon. The yellow coin is researved for other stuff."
  The game's coins and its yellow dot (its `Gear`, `Auctioneer`, `Object`, `MonsterNeutral`, `ChatBallon`) are no
  NPC's pin: trade goods the vendor's bag (`VendorGossipIcon`, file 132060), the auctioneer the crafting orders'
  golden hammer (`Professions-Crafting-Orders-Icon`), a friendly NPC of the search without a service the speech
  bubble (`GossipGossipIcon`, 132053), each the same file in both games (`Pins.NPC_LOOKS`, `Pins.Picture`: a number a
  texture). "I also want to implement sharing map pins with party and guild members and with someone specific": a
  right click on the map pin (`Marks.Share`), the wire's kind `W`, asked on the markers' card, the setting now
  *Markers and map pins others share*. "Can we have a tooltip on guild members and party member points on the map
  so we can identify who it is on the map": each member's mark a frame that takes the mouse's motion only
  (`Marks.MemberTip`), the names of all under the mouse as the game's map gives them, *Guild* beside one of your
  guild. Guild members outside your group have no place the game tells, only their zone: the search shows one there,
  with its tooltip.
- **2026-11-16, four sizes of words:** Saneroki: "add a fourth text size so their smallest matches too". Words have a
  size of their own now, apart from the lines' width (`Draw.TextSize`, `Draw.SetTextSize`, `Draw.TextSizes`: 0 small,
  1 normal, 2 large, 3 huge, kept in a text drawing's `width`; `Draw.WORDS[0]` the game's 12 point outlined font). The
  palette's width squares are four (`DrawBar.SWATCH` 20, so eight colours and four squares share the row): three lines'
  widths, and with the Text tool on four sizes, each an A, the smallest only then. The dungeon map addon's four sizes
  of words are ours one to one, its smallest too.
- **2026-11-16, eight colours, three widths, one to one with the dungeon map addon:** Saneroki: "Can we expand to 8
  colours and 3 lines and other stuff so we are as compatible as possible with their map sharing?" The palette has
  eight colours (pink, the game's paladins', and teal added) and three widths (`Draw.THICK`, `Draw.STOPS`,
  `Draw.WORDS`: the game's 16, 20 and 24 point outlined fonts); the addon's colours, widths, marks (a shield and a
  heal added to the markers' icons) and its stops' words map one to one both ways, its four word sizes onto our three;
  a stroke takes 400 points (`Plans.POINTS`), a sketch shared 500 drawings (`Plans.TAKE`) and 150 markers
  (`Plans.MARKERS`). Its stamps' own colours stay theirs: our markers keep the game's icons in their own colours.
- **2026-11-16, sketches both ways with a dungeon map addon:** asked whether a share of that addon's map drawings could
  be received and ours reach its players, Saneroki: "Yes, build it", and "it would be nice to make the map sharing as
  compatible as possible were we can from out side". Its drawings shared in a group, guild or whisper are heard and
  asked about as a sketch; ours go in its format too, on every channel ours go (`Exchange.lua`); its copied drawings
  are pasted in the Sketches menu. Its dungeon maps lie on our floors (51 the same art, Ruins of Lordaeron fitted),
  what has no match left out and said. A group of the game's group finder shares on its own channel now, and a sketch
  kept from someone keeps the words of its text drawings (they were lost).
- **2026-11-16, the question mark only where a quest is turned in; the map pin's tooltip:** Saneroki: "Quest
  locations should not show the questionmark, The questionmark on the map are where you turn in quests, the quest
  objectives and quest areas are for questlocations." A quest of your log ready to turn in keeps the yellow ? where
  the game says (`Pins.QuestLook`); one still in progress has none: where its objectives' pins stand on the map no
  mark of its own (`Pins.For`, the goals' `quests`), elsewhere the game's mark of a quest in progress
  (`Quest-In-Progress-Icon-yellow`, its map legend's), in the search's finds too. And: "In the tooltip of the mappin
  show that pressing ctrl click will remove it and double clicking on the map will create a pin with a route": the
  game's *<Ctrl click to remove pin>* in green under its words, as its own map's pin says it, then ours for the
  double click (`ns.TEXT.pinDouble`).
- **2026-11-16, Disabled in the sound line:** Saneroki: "a preset called disabled that just don't interfere with the
  audio at all ... that should be the default". Core's sound profiles start on Disabled (`Core.Audio.NONE`); the line
  names it, its tooltip says Sane UI leaves the game's sounds alone, and the cogwheel greys out Save, Load and Delete
  while it is in use. The top right corner fills the screen at a left click now (Core's *Hotcorner requires leftclick*,
  on at first in every module).
- **2026-11-16, zoomed out too far, the small map comes back in as you walk:** Saneroki: "If you are zoomed out to
  much on the minimap, can you make it so it zooms in to a reasonable level when you start moving on the minimap?"
  Past the game's widest minimap step, a walk brings the small map in to the middle click's zoom once the mouse has
  left it alone for `Canvas.SOON` (`Far`, `Near` in `Canvas.lua`).
- **2026-11-16, the small map back on you after 2 seconds:** Saneroki: "make it so that the minimap automatically
  follows the player when the player is moving. I think right now we have a 5 second delay. Make it a 2s delay". The
  small map's own wait, `Canvas.SOON` (2); the full map keeps `Canvas.AGAIN` (5), so it can be looked around while
  walking.
- **2026-11-16, a little off the line, it meets you further on:** Saneroki: "if you are just a little bit to the side
  of the route it shows you a route 90degree to your left / right and then again a 90 degree to the route. ... It
  would be nice if the pathing / routing would think a little ahead and not put the 90 90 degree path but say okay
  lets not go to the imidiate next stop but think a few stops ahead and say you need to go there to stay on track."
  The head ran to the line's nearest point. It meets the line at the plan's join now: the farthest place up to
  `Planner.JOIN` (60) yards along the walk a straight walk gets to over the walking data (`Walk.Straight`: never
  through a wall, into water only while swimming), the line drawn from there; on the line (within 2 yards), on a
  ride, or where nothing is in reach straight, the nearest point as before. The guide's arrow turns to it too.
- **2026-11-15, every dungeon's floors gone through, their ground mended:** Saneroki: "Can you go through all the
  instance dungeons and raid maps and make sure they work correctly. I think the instances that have different layers
  are not all working correctly. For example deadmines, one of the layers shows enemies and bosses in the open where
  normally the map for the ship is drawn". Every floor's ground was drawn beside its art with its bosses and enemies.
  Ironclad Cove's ship and docks are outdoor parts of the Deadmines the game draws no minimap of (its terrain there
  open water), so in Scrying they stood on the water; Blackfathom Deeps' halls Forever rebuilt keep minimap pictures of
  another shape (left out); Blackrock Depths lacks the ramp to the Hall of Crafting and the Shrine of Thaurissan.
  Those six floors keep their art in every view now (`dev/tools/dungeon-ground` checks that a floor's ground holds its
  things). Shadowfang Keep's Vacant Den and its two observatories (one box, three heights) each showed all three
  floors' rooms: told apart by name now. Blackwing Lair's Halls of Strife showed two of Blackrock Mountain's halls
  some 190 yards below. A floor drawn after one with ground no longer keeps that ground's files. The Wailing Caverns'
  art is older than the caverns Forever rebuilt east of it (89 of its 241 enemies stood on blank parchment); asked
  whether it should show its terrain in Parchment too: "Yes, terrain there". Its ground shows in every view now (the
  set's `alone`, chosen by the tool: 45 % of its things on parts its art draws nothing of).
- **2026-11-15, a floor's marker pressed while drawing:** Saneroki: "i got a error" (`Draw.lua:385`, a call of `Hold`
  before it was made: the map stood down); the search list's scroll thumb had the same kind (`Drag`). Both named
  before their first use.
- **2026-11-15, the small map's face over our dungeon map:** Saneroki: "when i mouse over i don't see the time, area
  text and both the bag and arrow buttons" (the face stood in the canvas, whose children the game draws as one with it
  since it cuts them at its edges: our map of the dungeon beside it covered them; `Satchel.Build` puts it beside the
  canvas). "Instead of the blue, can you make it fully transparent background?" (the canvas' ground clear under it).
- **2026-11-15, every dungeon's maps and place; the floors as big buttons:** Saneroki: "I should be able to click on
  the banners to open its maps. Not all dungeons have a map, route or show on map option? Why not? everything of those
  should be available to you. Also instead of the drop down to see different floors, it should be on the instance maps
  big buttons on the right side of the full screen where the name of the floor is listed as a button. All buttons have
  the same width and height." The classic ones had all three; a banner made before the dungeons' set was walked lost
  its maps until the next opening (`Entry` reads a floor at once now, `Instances.Refresh` after the walk). Forever's four
  new dungeons: the game ships no map of them and no entrance's place (their portals are the server's), so their maps
  are made from their ground (`dev/tools/dungeon-ground`: the instance's own areas on its terrain, or its buildings'
  indoor minimaps), two entrances from the world areas that bear their names (`dev/tools/map-data`), the other two's
  zones from Blizzard's article (batch 26). The bar's floors' dropdown went (`TopBar`'s `FloorList`).
- **2026-11-15, the dungeon you are in, once the list is read:** Saneroki: "Nope. Does not work. The games minimap is
  now always visible, no arrow switch button on the minimap either and zooming out does not show our map either and
  in fullscreen the dungeon map is not shown at all." The list of dungeons is read a part per frame after Core's set
  arrives; inside one already, nothing looked again (only the bar), and the notch out that did was gone:
  `Dungeons.Arrived`, the notch out back.
- **2026-11-15, our dungeon map on the small view zoomed and dragged; the face over it:** Saneroki: "When I am zoomed
  out completly it only shows the map as I expect it but the hover for the minimap time, area text, arrow button and
  bag is not visible. Only when I zoom in are those elements visible but the games minimap is forced on me and covers
  my own map" (the face went at the dungeon frame's leave, onto its dots and bosses and onto the bag itself; a notch
  in was the game's minimap: now only the arrow swaps).
- **2026-11-15, our dungeon map first; the arrow beside the bag:** Saneroki, of the small map in a dungeon: "does the
  game draw its own minimap over our map in instances? ... Would love to see our own map and its drawings" (the game
  tells addons nobody's place inside; its minimap knows it), then "Yes ours first. Add a toggle button next to the
  bag icon ... only show it on mouse over and in cases where it is neccessary like in instances" and "make the button
  that toggles it look like the players arrow" (`Dungeons` `Wanted`, `Want`, `Swap`, `Swappable`; `Satchel.arrow`).
- **2026-11-15, the button Dungeons and its banners:** Saneroki: "I would like to have the drop down change to a button
  and when the button is pressed you can see all the dungeons and raids that are currently available in Forever.
  Filter out those that are not currently in Forever or are not part of the planed for the soon to be released raids
  ... When the button is pressed the map changes into a new content where you can press on the banners with name,
  level, amount of quests information on it. You have options to route to there, show it on the map and see its
  instance maps." The list is Core's new set *Instances*: the client's group finder (`LFGDungeons`, with
  `GroupFinderActivity`'s levels, players and maps, by `dev/tools/game-data`) and Blizzard's announcement of this
  year's raids (a batch of its own); left out for now, by his word, the five new dungeons the client's list does not
  hold (The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold, Shaper's Terrace). The dropdown and its
  list went (`TopBar`'s `DungeonList`); `Dungeons.Margins` is the room both views share.
- **2026-11-15, dragging in edit mode; the Text and Route tools; the icons in groups:** Saneroki, with another addon's
  marker icons and numbered route as input: "Can we also make it a little more userfriendly by grouping them up
  together"; "the option to activate a custom "route" where you activate it and click a couple of times on the map
  and it shows you the positions with the number and line inbetween"; "I also want to be able to add plain text";
  "While in edit mode I want to be able to drag the markers, texts, lines, etc to new positions" (the Move tool went:
  `Draw` `Grab`, `LabelAt`, `AddStop`, `AddWords`; `Plans.KINDS` route and text, a row's eighth field the words;
  `Markers.ICON_GROUPS`, 65 icons).
- **2026-11-15, the Move tool; more marker icons:** Saneroki: "can you make it possible that map markers are draggable
  so you can move them to a different position? the current move button on the map markers does not work" (with a
  tool on, the press was the tool's: the card's Move now takes the click first; `Draw` `Hold`, `Drag`, `MarkerAt`,
  `Nearest`). "Can you add more custom map marker pin icon options? like Doors, stairs, bosses, chests, jumps etc"
  (`Markers.ICONS`, 36, the game's atlases and spell icons, `cut`).
- **2026-11-15, Scrying and Blended on the dungeon maps:** Saneroki: "I want the terrain / Partchment toggle work for
  instance maps as well. We should have both." Each floor's ground is the game's own minimap textures of the
  instance, drawn by file ID from Core's new set *DungeonGround* (`dev/tools/dungeon-ground`): 1,945 textures on the
  68 floors of the 26 instances. The painted maps' terrain plan (`map-layers inputs`) had seemed not to line up with
  the Deadmines' art: its whole-instance plan (both floors' frame) had been set beside the first floor's art; each
  floor's own frame lines up with its art, bosses and enemies.
- **2026-11-15, the map follows you by itself:** Saneroki: "Remove the "follow me" feature from the map and just follow
  the character automatically always when the character is moving and the map has not been draged around for 5s"
  (`Canvas.lua`, `Again`: both views, `Canvas.AGAIN` 5; the box on the bar, the setting `followMap` and
  `Canvas.Following` went).
- **2026-11-15, the view's button by Quest Log; the zone dropdown at every zoom:** Saneroki: "Can you move the button
  scrying / blended to the right of Questlog and make sure that the zone dropdown menu always has all zones listed.
  Right now on the highest zoom level it doesn't show the zones to select anymore" (it was disabled at the world:
  `TopBar.Update`).
- **2026-11-15, the whirlpool in detail:** Saneroki: "can we have a ai upscale it and maybe add some details but use
  a model that does great alpha maps", then of round 1 at 1024: "big enough that when placed on the world map can look
  good on a 4k screen and still able to zoom a little into it". Round 2 at 2048, his pick "b1" (foam on black, its
  brightness the alpha): `Art/Whirlpool.blp` from `assets/Whirlpool/whirlpool-foam.png` (`terrain-art --whirlpool`,
  `dev/imagegen/sets/sea/whirlpool.txt`). Card #524.
- **2026-11-15, plans are sketches to players:** Saneroki: "I don't like the word "plan" in front of each drawing. Is
  sketch better or what else could it be instead of Plan?", then "Sketch": every word players read (the palette's
  dropdown, its menus, the default names, the share and delete words, the card of a shared one). The code keeps
  *plan*. Then: "The penciel icon should be replaced with a dropdown menu" (`DrawBar.Menu`, `SketchesMenu`).
- **2026-11-15, the search's tooltips; the bosses' models zoom:** Saneroki: "When you mouse over an item or select it
  with the up and down arrows its tooltip should be shown. For example for items and npcs their tooltip is then shown
  on the right of the search suggestions" (`FindBox` `Tip`, `Untip`; `PinView.Creature` for any NPC of Core's data).
  "When you zoom in in dungeon maps the 3d model of bosses should zoom with it" (`Stand`, `Dungeons.MODEL_MOST`).
- **2026-11-15, the title bar, the search's second step and its scroll bar, searches that stop nothing, sharing with
  someone:** Saneroki: "Let the map view go to the very top behind the titleba so it is truely fullscreen. Remove the
  Parchment button and the "Map" word from the titlebar. We don't need the drop down for "azeroth, Eastern Kingdom,
  Kalimdor" Put the dropdown for the zones, dungeons and pins and the questlog, blended scrying into the titlebar.
  Blended and scrying will be one button that just toggles the map views" (`TopBar.lua` in Core's title bar, Core's
  `under`, `untitled`). "The search fields everywhere in our addon needs to have a very greacefull error handeling.
  Right now I had issues that it does crash the entire navigation module" (a map told as words in `Coords.ContinentOf`
  made a search stand Navigation down; `ns.Gently`, `Core.SEARCH_FAILED`). "When you hit enter or click on a search
  item in the map search it should show as new selectables the options like: Show on map, put pin there, what drops
  it, where to get it etc" (`FindBox.Take`, `Acts`; the row menu went). "Share option should have the party, guild and
  someone options" (`Core.AskPlayer`, `Plans.Share(plan, "WHISPER", name)`). "The search field needs to show clearly
  that it is scrollable" (`FindBox.Scroller`, as tall as fits).
- **2026-11-15, the small map's face; the retired flight points:** Saneroki: "The current time, zone name / area name
  and the minimap bag should only be visible on the minimap on mouse over. Put the time at the top center of the
  minimap and the zone name in the center bottom" (`Satchel.face`, `Satchel.Hover`, the canvas' tracker). "There are
  old flightpath pins that are not used anymore. I found at least 2 called "zzOLD..." those are not used and should
  be removed from the map and search databases" (`Live.Retired`: Forever's nodes 3206 to 3208, the game's alone; Core's
  data had none).
- **2026-11-15, drawing on the map, and plans:** Saneroki: "Can we draw on the map too? I want a button somwhere that
  helps me to activate menues and helpers to drop pins and draw on the map and save those drawings and map pins
  together so they can be shared or grouped together. This will be especially helpful in instance maps". `Plans.lua`,
  `Draw.lua`, `DrawBar.lua`; the canvas' layer `sketch`, `Canvas.Under`; `Dungeons.Point`, `Dungeons.Named`, the floor's
  drawings and markers, Alt and a click there; markers in plans (`plan`), a plan shared whole (kind `M`, version 2).
  Card #481.
- **2026-11-15, the world map cleaned up:** Saneroki: "The continent hover over has a outline that i don't like and
  that is also wrong. So lets disable the continent highlighting [...] Keep the zone highlighting like it is now"
  (`Art.Light`: on a world map only named). "there are areas on the map that need to be cleaned off [...] only show
  like single lines" (`dev/tools/terrain-art`'s `RIM`: Kalimdor's north-east edge and the isle in its north-west
  corner). "we need to add a whirlpool into the middle of the sea like it is on the original maps"
  (`Canvas.WHIRLPOOL`, `Art/Whirlpool.blp`, `terrain-art --whirlpool`).
- **2026-11-15, markers shared:** Saneroki: "Can we share markers with party and guild members?" The card's Share
  (`Markers.Share`, `Send`), the wire's kind `M`, the card that asks (`Heard`, `Read`, `Keep`), `origin` and `from`,
  the setting *Markers others share* (*Markers and map pins others share* since 2026-11-16). Card #481.
- **2026-11-15, your own markers:** Saneroki: "Can we have a system where we can place our own custom map markers on
  maps with our own text and description when you click on them?" `Markers.lua`; Alt and a click on the map, the
  card, the pins of kind `mark` (`Pins.For`, `Apart`, `PinView.Act`, `Name`'s label), the pin filter's *Your
  markers* (settings' version 6), the search's finds of kind `marker`. Card #481 (sharing and drawing to come).
- **2026-11-15, where to farm a thing:** Saneroki: "Could it be possible to write something like "where to farm Silk
  cloth" or "peaceblossom" and it will show dense areas were you could farm them on the map or put custom map pins
  there that are not tied to the routing but just shows where a lot of enemies are dense clustered that drop those
  things or zones where these nodes are plenty in". `Farms.lua` (the places, the glow; the canvas' layer `farms`),
  `Find.lua` (the words, the farm answer, an item's best places first, `Find.Farms`, the typo put right),
  `FindBox.lua` (the glow at once, Enter on a herb, *Searched for*). Card #487.
- **2026-11-15, the search in the full map's title bar:** Saneroki: "At the top of the map fullscreen, can you put a big
  searchfield in the title bar up there where you can search for stuff. Like NPC names, Guild member names, Vendors,
  class trainers, items etc and it will show it to you or put a pin on the map. For items for example it could drop a
  pin on the map where it drops and for guild members you will be able to see them on the map. You can write things
  like nearest warrior trainer for example and it puts a pin down on the map." `Find.lua`, `FindBox.lua`,
  `Bindings.xml`; the pins of kind `find` (`Pins.For`, `PinView`'s glow), `Pins.LookOf`, `ObjectLook`, `PlaceLook`,
  `Label.Range`, `QuestLog.Place`, `Window.Full`, `/sane map find`. The lab's scene `mapsearch`. Card #487.
- **2026-11-13, the party and the ships at a flight master too:** Saneroki: "keep them but still show party members
  and ships" (the arrow, the map pin and its line). `Taxi.KEEP`, `Taxi.Over`; a pin's `ship` (boats, zeppelins,
  piers): the tram, lifts, portals and the game's ways into another map stay off there.
- **2026-11-13, at a flight master its flight points alone:** Saneroki: "can you remove all pins other then the
  flightpath pins when the flightpath map is open". `Taxi.Shows`, `Pins.Showing`: quests, services, docks, places,
  rares, herbs and ore, quest areas, the party and the minimap dots off the full map while the master's is open; the
  arrow, the map pin and the golden line stay.
- **2026-11-11, the line coloured by its danger; waypoints dragged:** Saneroki: "Color the golden routing line in
  depending on how dangerous it is. So we know where which enemies spawn and what their level is. Can we make a
  routing show fx red if the enemies level range is clearly above me. Can we also implement it to make it possible to
  drag the route to reroute around? So that if we drag the route on the map it will put a new waypoint there that the
  routing goes to first and then to the map pin". `Danger.lua` (Core's new set *FactionTemplates*, the client's
  reactions, so friendly guards are no danger), the walks' pieces by danger (`Route.lua`); the line dragged on the full
  map (`Canvas.lua`'s `grab`, `Route.Grab`, `Route.Bend`), the waypoints (`Planner.Via`, `Stages`, `Passed`;
  `Marks.Vias`, `Marks.Ghost`). Cards #464, #465.
- **2026-11-11, the party's marks glide, smaller in close:** Saneroki: "can the movement of them become smoother?
  right now they jitter to the new position all the time", then "it should be smaller when you are zoomed in
  closer". `Marks.Glide`, `Aim`, `Along`; `Marks.MEMBER` 44 far out to 22 in close.
- **2026-11-11, a dungeon's map whole in view, on both maps:** Saneroki: the dungeon and raid maps with the bosses' 3D
  models and loot still in the game, and "make the minimap and the fullscreen map fit the entire map in the view. So the
  zoomlevel is adjusted so it is always possible to see the entire dungeon map". The full map fits a floor into the
  room under its bar and beside the quest log (`Dungeons.lua`: `Room`, `Dungeons.Refit`, `Dungeons.SIDE`; `QuestLog.Box`);
  inside a dungeon the small map shows its whole map one wheel notch out past the game's widest step
  (`Dungeons.Whole`, `Dungeons.Small`, `Dungeons.SMALL`; `Canvas.lua`'s `whole`), kept until wheeled in or clicked away.
- **2026-11-11, the party's marks much bigger, with the zoom, at every zoom:** Saneroki: "The party members on the
  map, can you make its icons much bigger, scale with the zoom level on the map and is always visible on all zoom
  levels". `Marks.MemberSize` (22 to 44 in place of 14), `Marks.Group` at once from `Canvas.lua`'s `Draw`; no longer
  standing down under the game's minimap (`Hybrid.Square` gone), looked at every `Marks.OVER` there instead.
- **2026-11-11, books and chests for the rare tracker in Forever:** Saneroki: "Does that work also with things like
  treasures and other things like for example the books that are spread in the world that you need to gather", then
  "Yes, build it". Forever's client has no marks for them; the 36 books the librarians ask for are books in Core's
  data now (`assets/data/Objects/fixes.jsonl`), on the map too (*Books*). `RareTracker.lua`: `Soft`, `Scan`, `Book`,
  `Needed`, `Looted`.
- **2026-11-11, the rare tracker's notices stay:** Saneroki: "it should not remove the tracker window when you double
  click on it. Only right click, the rare dead or rightclicking it will remove the window. Reload and moving far enough
  away from it will also remove it eventually" (`RareTracker.lua`: `Over`, `Dead`, `Follow`; `FAR`, 400 yards).
- **2026-11-11, the travel overlay a little higher:** Saneroki: "move both widgets a little more up", kept for the
  travel overlay once the Sane Rare tracker went under the minimap: its words over the line `TripView.HIGHER` (60)
  over a toast's height, no longer level with the toast of a new level.
- **2026-11-11, the Sane Rare tracker under the minimap:** Saneroki: "Can you make a rightclick will remove it and a
  left double click will put a map marker on him", then "move the rare tracker to the right edge of the screen
  underneath the minimap. A leftclick drag will move the window around" (`RareTracker.lua`: `Place`, `Dragged`).
- **2026-11-11, pins of one icon combined, a smaller gap:** Saneroki: "map pins that share the same icon, for example
  all trainers, vendors, portals etc should be combined into one icon and split if you zoom in close enough. Right
  now the pins have to big of a gap between them and show to many." (`Pins.lua` `Combine`, `Pins.COMBINE`;
  `Pins.SPACE` 0.85).
- **2026-11-11, the Sane Rare tracker; a rare's tooltip as a boss's:** Saneroki: a rare's tooltip on the map with "the
  icons like the bosses tooltip we had in instances", and a warning that shows "a widget on screen when it finds a rare,
  chest or other things" and "plays a little trumpet horn sound"; "give me a command /sane testraretracker"; its name is
  the Sane Rare tracker. Card #108 (`RareTracker.lua`; `PinView.lua`'s rare tooltip; `Core.TipLook`'s `creature`).
- **2026-11-11, the ships' ways through the sea:** Saneroki: "Right now the shiping routes are streight blue lines.
  Can you make the blue lines more accurately where the ships go. I know they ship a little bit and then go into a
  loading screen." Then: "The routes we draw for our ships should avoid the big whirlwind in the middle and sail
  around it. Ships also sometimes travel to several ports in a loop. It would be nice to see all the ship route the
  ship goes [...] while its map pin is hovered or clicked." (`Paths.LANES`; the loop Menethil Harbor, Southshore,
  Auberdine an outer and an inner way; every boat of *Travel* checked against the routes Forever has. Card #461.)
  Asked whether the zeppelins' lines should bend round the Maelstrom too: "Yes, bend them" (the two that crossed
  it; the others fly far from it).
- **2026-11-11, the sea less tiled:** Saneroki: "so instead of a blurr, can we do something else to make the ocean
  less repetitive? it is very tiled", then, of two layers and of two layers and a soft shade on a 4K mock-up: "two
  layers and shade" (`Canvas.SEA_LAYERS`, `Art/SeaShade.blp`).
- **2026-11-11, the sea's waves:** Saneroki: "The map shows atm a solid color as the water. Can we make it a ocean
  like texture" (`Art/Sea.blp` from the game's own ocean texture, `Canvas.lua`'s `Waves`).
- **2026-11-11, the flight points' names at a flight master:** Saneroki: "On the right of the big Flightpath icons,
  can you write the name of the flightpath lockation and its price and the size of the text adjusts to the zoomlevel
  and is always behind the flightpath icons" (`Taxi.Label`, `PinView.LABEL`: a layer of its own under the pins').
- **2026-11-11, a cloud of pins in place of the plus; ships at the world; treasure, herbs and ore up close:** Saneroki:
  "when you zoom out on the map to the farthest level the ships are not visible anymore." "Instead of the maps + that
  combines map pins, can we have a system where it shows the icons next to each other in a cluster [...] like a
  cloud of pins and when you zoom in they become more accurate." "Map pins for Treasure, possible ore and herbs
  should only be visible when you are really cloasly zoomed in." `Pins.Spread`, the world's zones in `Maps`,
  `Pins.CLOSE`.
- **2026-11-11, the flight master's map zoomed out; every continent's pins at the middle zoom:** Saneroki: "When we
  opent he flightmaster map, can you make sure that it is fully zoomed out to max level where we can see both
  continents": it opens at the world whole (and a view at the world whole stays so at a new size, `Camera:Frame`).
  Then: "The big icons disappear when you zoom a little to far in. They are only visible in the near and far view,
  not in the middle view": at a continent's zoom only the continent under the view's middle gave its pins, the other
  one drawn bare; now every continent in view gives its own map's (`Pins.lua` `Maps`, `InView`).
- **2026-11-11, the flight master's map the full map as always; the zones' levels from their enemies:** Saneroki:
  "the actuall skrying map is not visible and it only shows one continent. Ideally I want the exact same map as our
  normal fullscreen map": it opened at the master's map, in Forever a map of its own (1463, 1464, 2665), shown alone;
  now `Window.OpenTo()`. Then: "can you make the zone level the range of the enemies, not the quests? and remove the
  !. That is not needed here." (`Label.lua` `Enemies`; no red mark on the label's two lines).
- **2026-11-11, the zones' levels from their quests; the flight master's map whatever the world map's switch says:**
  Forever tells no zone's level range (above), and Saneroki chose "Forever's quest levels": `Label.lua`'s
  `FromQuests`. Then: "the flightmaster still opens only the native window normally": his *Show the game's map* was
  on, and `Taxi.lua` stood aside for it; now only Shift does.
- **2026-11-11, flight points and docks at every zoom, their ways kept by a click:** Saneroki: "can you make sure
  that when you zoom all the way out of the map that all ship and flightpath icons are still fully visible so we can
  hover over them to see where they go. Can you also make them so that a single click will make them "active" [...]
  This "active" state should deactivate when you close the fullscreen". `Pins.WORLD`: at the world the planes' own
  pins of those kinds, and never gathered. He also found the zone label without levels: Forever tells none
  (`C_Map.GetMapLevels` empty, no level range in its client tables).
- **2026-11-10, the flight master's map:** Saneroki: "When we open the flightpath master window, can you make it so
  that shiftclicking will open it normally but if you open it normally it shows our own fullscreen map instead but
  where the flightpath icons are huge and you can click them to fly there like the normal flightpath window"
  (`Taxi.lua`): the game's flight map stays open tiny and clear, so the talk goes on and `TakeTaxiNode` flies.
  2026-11-11: "Flightpaths you don't know yet are on our map normally red. So instead of dimming them, make them the
  same red icons."
- **2026-11-10, the zone's name, the ways under the mouse, the mages' portals, back to the corpse:** Saneroki: "When
  you hover over a zone it gets highlighted, right? When that happens, can you show a overlay of what Level range
  and fishing range that zone is and the name of the zone." The full map names it at its top (`Label.lua`), the
  levels the game's, the fishing skill from Core's new set *Fishing* (the original game's, where both its records
  agree: unconfirmed). "When you hover over a boat or flightpath, can you overlay the paths they go around? you know
  the blue and white lines you normally see when you take those rides." (`Paths.lua`). "Only Mages can use portals.
  So if I am on a druid the routing needs to find another route without portals": Core's set *Travel* gives the
  portal objects a class (`class` 8, by hand), the planner takes one only for that class; Teldrassil's, a trigger
  everyone steps into, has none. Asked about the Wizard's Sanctum's pads in Stormwind: "Yes, mages only" (`class` 8
  too). Then: "While you are dead, can you put the routing to your place of death [...]
  once you live again your map pin changes to where it has been before." (`Corpse.lua`; a ghost's route neither
  flies nor casts).
- **2026-11-10, the satchel swaps the minimaps:** Saneroki: "The little button on the native minimap to go back to our
  own minimap. Can you also add that one to our own minimap bag window so we have a toggle so we can go back and
  forth". The satchel's page has the same button beside its X (`Satchel.swap`, Core's `Window.Swap`).
- **2026-11-09, ship times kept, ports in order, quest areas off the minimap, the map across continents:** Saneroki
  found the travel overlay's ship times gone after a reload or a login: Core dropped a ride's times half a day after
  it (`Ships.TRUST`). Now a known round's are kept for good, worked out anew from the clock, every ride correcting
  them; an estimated one's (a boat ridden once) hold `Ships.GUESS` rounds, then *ride it again* (his pick). A dock's
  pin lists every port of its ship in the order it travels to them (`Pins.Ports`). The quest areas, "the blue bubble
  and the white ring", are off on the minimap at first, *Quest areas on the minimap* in the pin filter brings them
  (ours and the game's minimap's own). "There is a limit how far you can pan and you have to select the other
  continent": the camera's middle now goes anywhere on the world map and into the other continent's plane as it
  is dragged over it. Then: "If I mouse over a boat on the map, can it then show the current timer? Like when it
  arives or leaves?" A dock's pin's tooltip now counts it down (`DockWatch.Timer`).
- **2026-11-09, the Atlas gone:** as Saneroki asked ("too many disadvantages without much benefit"), the painted map
  and its module `SaneUI_Atlas` are gone, with `Painted.lua`, its layer and its nearer zoom: the map offers
  *Parchment*, *Blended* and *Scrying* and starts as Scrying; a saved *Atlas* falls back to Scrying.
- **2026-11-07, the quest log at rest in a group too:** Saneroki found the quest log, unit frames and action bars hidden
  alone but always in sight in a party. *In a group too* under *Hide the quest log at rest* (`questLogRestGroup`, off
  at first) keeps it out of sight there as well, by Core's `rest:InGroup`.
- **2026-11-06, quest timers always in sight:** Saneroki asked whether the quest log shows a timed quest's time. It
  showed none, and it hides the game's quest tracker, on which Forever's own Quest Timers panel stands, so no timer
  showed anywhere until *Failed*. His word: "The timer should always show even when the quest tracker / log is hidden.
  Because I like things hidden unless moused over. But i need to know when i have a timer". Now a strip at the log's
  top counts each down, in sight while the log rests, is folded or switched off.
- **2026-11-06, a button made at the login in the satchel:** Saneroki found no button of the guild addon Sane UI knows
  in the satchel. That addon makes its button only at the login, and another addon of his gathers minimap buttons
  into a bar of its own a second after the login; the satchel looked again only after three seconds (its 2 seconds
  went through a second's wait), so that bar had it first and it was no longer on the minimap. Now the satchel also
  looks on the next frame after the login, and its 2 and 10 seconds are 2 and 10 (`Strays.AGAIN`).
- **2026-11-06, the hearthstone told, not taken:** Saneroki stood in the middle of Stormwind with the map pin in
  Darkshore: the line in Darkshore was right, but "it shows the blue route from the middle of the city where I
  stand"; he expected "a golden route to the ship, a blue ship line and a golden route in darkdshore from the boat
  to the marker". Both his characters are bound at Auberdine, so the planner took the hearthstone (ready, or ready
  within about five minutes), its pale blue line straight from him to the inn. Run on the real data, the boat came
  out as he expected once the hearthstone was further off. His word: "Turn it off but just show a ingame message to
  use the heartstone to speed it up." Now the line never takes the hearthstone (nor Astral Recall); where it would
  be `Planner.SOONER` (two minutes) quicker, the chat tells once a pin (`Quicker`, `Tell`).
- **2026-11-06, quest areas on the small map ours alone, lighter:** Saneroki saw a white circle on the small map,
  "sometimes shows, sometimes not and sometimes only partly", with the quest areas, and an area "way to opaque.
  Much more solid than it normally is"; "I thought we replaced the native blobs with our own so we have more control
  over it?" Ours drew the quest's area under the game's minimap, and the game's minimap drew its own over it: its
  outline and the ring round its edge (the circle). Now its own are off while our map lies under it (`Hybrid.AREAS`,
  back with its ground: in an instance, given back), and ours fill at half the game's map's alpha.
- **2026-11-06, indoor maps in Ironforge and the Undercity:** Saneroki: inside Ironforge the map showed the zone,
  "just the top of the mountain", not its halls; "Maps that are indoor including ironforge need to always show the
  indoor map ontop the zonemap". The indoor layer went by the game's `IsIndoors`, which is false wherever one may ride
  (the game's `WMOAreaTable` marks those halls outdoors), though the game's minimap shows their plan. Now the layer
  goes by `Live.Indoors`: `IsIndoors`, or the minimap's view at its indoor radius. The game's minimap's measured
  steps (`Hybrid.lua`) and the floor the route guesses under you (`Planner.lua`: a building's lowest, not the
  mountain over the city) go by it too.
- **2026-11-04, sound profiles in the satchel:** Saneroki plays two clients of one installation at once and
  wants to hear one, the other or neither, the recording keeping the chosen one's sound. The game keeps its sound
  settings in one file for both, so the profiles are Core's, per game account, the last one set again at each
  login (`Core.Audio`); the satchel's section *Sane UI* starts with their line, `Sound: <profile> <cogwheel>`
  (`AudioLine.lua`), as asked: the profile in use first, the cogwheel with the game's five sounds and Save,
  Load, New and Delete.
- **2026-11-02, pins at the exact spawns of your quests' objectives:** Saneroki wanted the places themselves on the
  map, not only the question mark and the area, with no glow at rest; "when you mouse over a quest in the questlog it
  will make the map icons glow a little so you know which pins tie to which quests". Built from Core's *Quests*,
  *Spawns*, *CreatureSpawns* and *Drops* (`Goals.lua`), in the quest log's own pictures, a row of its own in the pin
  filter. The game's question mark and the area stay beside them.
- **2026-11-02, the golden line on Retail's small map:** Saneroki saw it on the full map only. Where our map has no
  land (`Terrain.Possible`: Retail, until its data comes) the game's minimap keeps its own ground in the small view,
  and at its level (10) that covered the line (8). The route now stands at `Canvas.OVER_GROUND` (11) there, over that
  ground, under the pins; with land the game's dots stay over the line, as its ground is off.
- **2026-11-02, the satchel goes with the mouse, its numbers in boxes:** as Saneroki asked, the satchel closes the
  first time the mouse leaves it, until its button is pressed again; and the times, the frames per second and the
  ping stand at its top in four boxes, a big number over its word, low rectangles rather than squares so they take
  little of the page's height (`Satchel.lua`). Then each number and its word together in the middle of the box, the
  word right under the digits, and the zone's name as big as the numbers, centred, with no lines under it.
- **2026-11-01, the quests' items rechecked:** as Saneroki asked, the click run through the game's own code of both
  games: every mouse button and modifier uses the item once, in and out of a fight. The tooltip is now what you carry,
  as on the game's tracker; a click acts on the release; with the chat's box open Shift and a click links the item and
  no longer uses it up; an item follows your bags. And Shift and a click on a quest tracks it again: the link's
  modifier, Shift too, had taken the click even where nothing took the link.
- **2026-10-30, Atlas first, Follow me a tick:** as Saneroki asked, the map starts as Atlas where it can be drawn, else
  as Scrying, and in Retail its one view stands without buttons or a setting. *Follow again after* is gone: *Follow
  me*, on at first, says whether the map comes back; ticked, the minimap snaps back the moment you walk, the full map
  as you walk 10 seconds after you last touched it.
- **2026-10-28, the finders every 15 yards:** as Saneroki asked, the finders switch every 15 yards at first, set by
  the slider *Switch finders every* (0 to 50 yards) on Navigation's options page, under *Herbs and ore*.
- **2026-10-28, the finders by yards, Find Fish, and back after death:** as Saneroki asked, the finders take turns
  every 7 yards you move (the setting *Finders in turn*, in yards, was seconds), Find Fish among them (the pin
  filter's new *Found fishing pools*), only those you know; and alive again after dying, the finder wanted comes
  back on by itself (`Nodes.lua`: `PLAYER_ALIVE`, `PLAYER_UNGHOST`).
- **2026-10-26, the satchel's switches:** as Saneroki asked, the satchel has a section *Sane UI* with the modules'
  quick switches (Speed Leveling's guide on, paused or off), the latency home and to the world on one line, and no
  *AddOns* section while no other addon has a button for it.
- **2026-10-25, the satchel and the middle click:** as Saneroki asked, a middle click brings the map back onto you,
  following, near enough for the game's minimap's dots (`Canvas.Home`, `Hybrid.HOME`); and one button on the small
  map, the satchel, opens a page of the buttons other addons put round the minimap, gathered there
  (`Strays.lua`), with the addons of the game's addon compartment, the kinds of pin and what the game's minimap
  tracks, in large cells that switch at a click (`Satchel.lua`).
- **2026-10-25, the satchel's zone and clock:** as Saneroki asked, the satchel opens on the zone you are in, with
  your local and the realm's time, the frame rate, the latency home and to the world, the time of day, new mail and
  the calendar's invitations, and the game's calendar, clock (alarm) and stopwatch.
- **2026-10-25, the satchel's addons round:** as Saneroki asked, the addons' pictures round, without the golden
  ring round them: their buttons lie unseen over our round picture of them.
- **2026-10-25, the satchel's addons larger:** as Saneroki asked, the addons' pictures twice the size of the
  pins' and tracking's.
- **2026-10-25, the satchel compact:** as Saneroki asked, six smaller cells a row, the pictures without their pencil
  slots, less room between the sections.
- **2026-10-25, the Cosmic map's highlight:** a world under the mouse on Retail's Cosmic map (and Argus' maps,
  the Broken Isles on Azeroth) lights up in its whole piece of the game's atlas: the piece is set last, as the
  game's own highlight does, since a texture's coordinates after its atlas cut within the piece.
- **2026-10-25, Retail's own maps (Saneroki):** in Retail the map is the game's own map tree, one map at a time: a
  click into the map under the mouse, a right click up to the map over it (zone, continent, Azeroth, the Cosmic
  map), the wheel within the map shown, its art's layers by the zoom, its pins alone; following, the map the player
  is on; the full map opens on it whole (`Camera.Retail.lua`). Forever's map is as it was.
- **2026-10-25, in Retail:** the module runs in Retail too, where Core has no data yet: the map is drawn as
  Parchment (Scrying and Blended stand down without Core's terrain), the small view at the game's minimap's steps
  shows the game's own ground, the game's minimap is given back round, the continents beside the world map
  (Outland, Draenor, the Shadowlands) are in the map selector and drawn, the dungeons of the whole map tree listed;
  the pin kinds, switches and sparkles that need Core's data or Forever's minimap stand down; Retail's two finders
  are on together. Forever's outlines and coasts are read in Forever only.
- **2026-10-25, no square edges in the ring:** the item picture's straight edges showed inside the leather: it is now
  cut 12 % in at each side (past its own frame and the dark band inside it, `Found.TRIM`), cut round, and 16 % wider
  than the ring's hole (`Found.FILL`), its edge under the leather; on the screen and on the minimap alike, the rings
  as large as before.
- **2026-10-25, the yards as a number:** as Saneroki asked, a far herb's or ore's distance is the number alone (no
  *yds*), under the ring (`Glints.TEXT`), and under the point too while that points down (a node behind you); centred
  in the ring over the picture was tried first.
- **2026-10-25, the leather ring:** as Saneroki chose (the ring \#6 of eight rendered: five gold, leather, pencil and
  parchment), the found herbs and ore wear a ring of stitched leather: on the screen with its point, turned toward the
  node about the middle of its hole (`Art/mark-pointed.blp`), on the minimap perfectly round (`Art/mark-round.blp`), so
  both look alike; the item's own dark frame is trimmed off its picture (`Found.Round`). The yards stand on the side
  away from the point. `dev/tools/mark-art` makes both rings from the picked render, the round one from its own
  leather with its edges laid on exact circles.
- **2026-10-25, far herbs and ore as pictures:** as Saneroki asked, no column: each found herb and ore far away is
  the picture of what it gives, round in the gold ring of the minimap's pictures (`Found.Ring`), the ring running out
  into a point the way to it from where you face (two slices of the ring's own art, from where they leave the ring to
  the tip), and its yards under it; at the screen's edge the same. The setting is *Far herbs and ore on the screen*.
  The interface lab shows it over the world (scene `far-sparkles`). One cohesive painted ring with its point is to
  replace the slices: candidates in gold, leather, pencil and parchment from `dev/imagegen/sets/far-marks/`.
- **2026-10-25, far sparkles:** as Saneroki asked, every herb and ore the minimap found shows on the screen however
  far it is: a column of gold sparkles in its direction, the picture of what it gives and its yards under it, and one
  outside the view at the screen's edge, the game's navigation arrow pointing on (`Glints.lua`, the setting *Sparkles
  on far herbs and ore*). Roughly placed and without the map pin (Saneroki): the camera is taken to be behind you, at
  the game's zoom and field of view, and the marks wait while the left mouse button turns it.
- **2026-10-23, a red ! for each:** in a tooltip the red ! stands before the name of each thing not yet confirmed (a
  boss's ability or item, an enemy, a pin's thing, its quests), so *! Unconfirmed Data !* says which (Saneroki).
- **2026-10-23, confirmed in play:** a pin's and a boss's *Unconfirmed Data* follow Core's marks and what the
  game confirmed in play, here or by the guild or the group (`Pins.Unverified`, `Bosses:Unverified` per item and
  ability); a boss's items and abilities confirmed that the data lacks join its lists; an item the game keeps hidden
  shows as Core's data has it, its stats with Alt (Saneroki).
- **2026-10-23, a plus for mixed pins:** pins with different icons that cover each other show as one plus, their
  tooltip each one's icon and name (Saneroki).
- **2026-10-23, no word twice:** a gathered marker's tooltip names what is there, without the sentence about a
  click, and a pin's tooltip says no words twice (Saneroki).
- **2026-10-23, tooltips by role; bosses as creatures:** as Saneroki asked, an NPC's pin is named by what it is
  (*Bowyer*, *Warrior Trainer*, *Quest giver*), not by its name; *! Unconfirmed Data !* in place of the old sentence,
  a divider in Sane UI's tooltips; a boss's tooltip is a creature's (its model, the boss's dragon, *??*), its abilities
  and loot sections of their own; an item's details with Alt: *Uncollected*, its effects, then its stats.
- **2026-10-22, no ride straight back:** 5 of 200 routes between NPCs rode a lift up and straight down again (the
  Undercity's, Gnomeregan's), only so that a walk could follow a walk: a place reached on foot lets no walk go on,
  one reached by a ride does. Three things made it pay: a walk to a lift's upper end could end on the city under it,
  at the lift's foot, as though it had come down already; a journey chosen again by its guesses could come out
  dearer than one priced before it (a walk found up to 1.6 times its guess stays, and after eight tries the last
  stays whatever it costs: from Ironforge to the Undercity by Dalaran's portals, 910 seconds where 650 were known);
  and nothing kept the ride from going back. Now no ride brings one back to where the rides since the last walk
  began, a walk to a lift's end ends on its own level (within 12 yards of its landing's height), and of the journeys
  whose walks were all priced the quickest is drawn. The five go by one walk or another real way (from the Undercity
  to the Bulwark one walk of 2,102 yards); the walks drawn straight, off the walking data or not from the player stay
  as they were, and so do the 29 fixed journeys and the teleports'.
- **2026-10-22, long walks found fast:** a far pin took the planner seconds: each walk was searched rectangle by
  rectangle as far as its length reached, and one many times its straight line (a Horde character deep in the
  Alliance's lands) was tried as a short one and given up after 200,000 rectangles, then drawn straight. The walking
  data has a coarse layer now (`Gates.lua`, `dev/tools/walk-gates`): per tile its gates into the next and what the
  walks between them cost. A walk is priced over it first (only the tiles it starts and ends on rectangle by
  rectangle) and drawn along that way; the planner prices the walks of the journey it chose before it searches any.
  Offline over 200 routes between NPCs: 119 ms a route (505), the slowest 0.7 s (3.4), one walk drawn straight (nine),
  none given up; a walk costs as before within a few percent (two tenths on the median). A tile's openings are worked
  out only when a search needs them (looking up the floors at a place needs none).
- **2026-10-22, water is slow:** a route to Stormwind harbor's boat swam 942 yards along the coast at Longshore, as a
  yard swum cost only twice a yard walked. Walks are now timed at the character's own speeds (as the game tells
  them, riding where it was seen riding), so a rider keeps to land where one on foot swims across; and each step aims
  along the straight line to the walk's end, so open ground costs its straight way, not a stair of nearest points.
- **2026-10-22, the golden line curved:** its corners were sharp, so a way round many corners showed as short
  straight lines. A corner turning more than 10 degrees is now a curve of the corner and the points before and after
  it, never more than 6 units inside the corner; the glint flows on from piece to piece in one pulse.
- **2026-10-22, no walk after a walk at a flight point:** a route that walked to a flight point could take off and
  come straight down again there and walk on, from another of its floors where the walking data has no way between
  them (from the Undercity's lift to Sylvanas by the bat handler on the ring, on from the floor under it), or round
  ground no walk was found over (the Horde's from Teldrassil, a walk drawn straight to Moonglade); 7 of 200
  journeys between NPCs walked twice in a row so. Now one comes down at a flight point only after a flight: from
  the lift to Sylvanas is one walk of 748 yards, and the walks drawn straight in those 200 journeys went from 14 to
  10.
- **2026-10-22, the walking data both ways; the portals' rooms:** every way between two floors the walking data holds
  now holds both ways and lies where the two meet, so routes no longer start or end on small floors no way led back
  from (rock tops, huts: 0.14 % of the ground), and no line runs over ground without a floor where a walk turned
  through a way set beside its floors (7 of 200 journeys between NPCs). A deck and the ground under its next step are
  no way, but a hall whose door is a wall in the walking data keeps the way under its floor that reached it, and so
  do the inner ruins of Lordaeron. The rooms the portals bring one to are kept however small: the Wizard's Sanctum's
  cellar and top, the Skyborne portal's room under the Mage Quarter, the top of Dalaran's Violet Citadel. In the
  game's own walls the Sanctum's two rooms are closed off from Stormwind's streets, so routes take those portals for a
  pin in them, from Dalaran by the Skyborne portal.
- **2026-10-21, the teleports a character has; Frequent Flier:** routes take the teleports the character has where
  they are quicker, from where it stands to where each brings it (`Teleports`, Core's set *Travel*, kind `teleport`:
  the mage's to the capitals and Dalaran, the druid's to Moonglade, the engineers' transporters, the Crumbling
  Hearthstone; a spell known with its reagent, or an item held that the game lets the character use; its cooldown
  and `Planner.HEARTH`), drawn pale blue like the hearthstone's; Astral Recall brings the character to the
  hearthstone's place too (`Planner.RECALL`). Where a teleport brings one: the original game's for seven of them
  (batch 14, unverified), else learnt by Core where one brought a character (`src/Core/Data/Teleports.lua`). With the
  Legacy perk Frequent Flier the flights count 20 % faster (`Planner.Pace`, `Planner.FASTER`).
- **2026-10-21, the ground as the game draws it; water in buildings; indoors on a building's floor:** the walking
  data judges the ground by the game's own triangles (it smoothed the heights, so walks went up Ironforge's mountain
  and into the ground under Stormwind), so a hill or a pass a player walks up is taken where it is shorter
  (`Search.CLIMB` a quarter, it was two) and a steeper one never; the buildings' water, slime and lava count
  (Stormwind's canals are swum), stairs and narrow stairwells join their storeys (Thunder Bluff's rises join the
  mesa), the ground buried under Stormwind's streets is left out, and a floor on a building is of its own kind:
  indoors a route whose floor is not known starts on the lowest of a building's floors near you, not on the ground
  under the city. With the doodads the set is 23.7 MB (12.6 before).
- **2026-10-21, fences, rocks and trees:** the walking data knows the game's doodads: routes go round fences, rocks,
  tree trunks and the game's invisible walls and over piers and decks; buildings lie tilted as the game places them
  (Winterspring's cave tunnels, ruins on hillsides); a lift's landing is the floor beside its shaft at the car's
  height, never the roof over it (the Undercity's).
- **2026-10-21, only the flight points found:** at a flight master the planner took every flight point the game's
  flight map listed as one the character knew, also those it leaves out as not found (`Unreachable`), so routes flew
  from and to flight points the character had never found. Now only those found count (its flight map's states, and
  every plane's as the game's maps mark them once a flight master was opened this session), kept anew per character
  (`flightPoints`; the older list goes), and the map shows the others red, their tooltip saying so; a pin set before is
  planned again when they change.
- **2026-10-21, the walking data joins what players walk between:** the Undercity is one city: its ring, lower
  parts, quarters and sewers, and the lifts' upper landings with the throne room (`dev/tools/walk-data` judged the
  buildings' slopes too steep from 30 degrees on, and closed doors and bridges narrower than two samples by their
  sides: now a wall closes the way between two samples instead of taking a sample whose middle it keeps out of).
  Freewind Post's and Gnomeregan's lifts land (the regions lifts land on are kept however small), Thunder Bluff's
  Elder Rise is joined to the main mesa by its bridge, and many towers, ramps and terraces to their land (Orgrimmar's
  flight tower, the Crossroads, the zeppelin towers to Zephras Isle, the Caverns of Time). The Undercity's sewers
  lead out to a cave on the hillside west of the ruins, so the city and the ruins are one region; a lift within one
  region still joins two levels where they lie one over the other (`Lifts.Levels`, told apart by height), so routes
  from the ruins into the city still take the lift.
- **2026-10-21, bosses with their abilities and loot; enemies:** the dungeon maps' boss tooltips list what the boss
  casts and drops, with their icons, from the game; Core's sets gained them (batch 11: the new set *Bosses*,
  `abilities` and `loot`, apart from the game's *Encounters*; *Dungeons* 100 more bosses, in the dungeons Blizzard rebuilt too, and `enemies` in six dungeons), and the
  enemies stand on the maps as small red dots.
- **2026-10-21, indoor maps off the streets; instance maps without players; a rare's model:** as Saneroki decided,
  the indoor maps only inside buildings and caves (Core's set *Indoors* marks the open parts, `open`, from the game's
  part flags and its `WMOAreaTable`); instance maps keep rules of their own: no arrow, no group, no floor by place
  (Forever tells none inside an instance), the bosses on them; Alt over a rare's pin shows its 3D model beside the
  tooltip (`PinView`, `SetCreature`).
- **2026-10-21, lifts in the routes:** Thunder Bluff's mesa and the Undercity are reached by their lifts, and the
  Great Lift between the Barrens and Thousand Needles is taken where it is quicker: on foot to the lift, up or down,
  on foot on, instead of as near as one walks and straight on. The lifts are fourteen cars of Core's set *Travel*
  (kind `lift`, batch 10 of `sources.toml`, their motion from the game's client by `dev/tools/travel-data`); each end
  of a car at its landing, the floor beside its shaft at its height (`Walk.Landing`); no walk between two levels a lift
  joins. A place under the ruins over the Undercity stands in the city (`Lifts.Stand`: the levels stacked there, side
  by side at Thunder Bluff); after a ride on the line's lift the floor followed is the landing at its other end
  (`Rode`). The lifts are on the map, named, not yet confirmed by the game. Freewind Post's, Gnomeregan's and two small
  ones are on the map only: the walking data has no floor at an end of theirs.
- **2026-10-21, routes from the player, through caves and cities, over every sea:** the line always begins at the
  player's arrow, what lies behind them gone (the planner's cut, `Route.Cut`). The floor the player stands on is
  followed through the openings they walk by (`Walk.Follow`), so a way out of a cave, a city in a mountain or an
  upper storey starts on their floor, not on the hill or the mountain over it; the search ends on any floor at the
  pin, near it, or as near as one walks, then straight to it (a pin on a floor of another region had no line at
  all), and keeps to the valleys and the roads (each yard up costs two more): in Ironforge, from the flight master to
  the tram, 327 yards through the city where it took 1,551 over the mountain. The graph spans every plane (the hearthstone home, then a ship; the
  isle by way of a continent), a flight over many flight points takes off once and is one leg, a pin set aboard a
  ship is planned from the pier it comes to, the tram's wait is the time to its next train where a ride taught its
  times, and places that share no region of the walking data are a walk at a cost (a zeppelin's tower, a mesa)
  instead of none. The plan is one job of Core's scheduler; Walk keeps the tiles asked for last.
- **2026-10-21, the game's map hidden, never closed; instances:** a map the game opened is hidden by its own `Hide`,
  not the game's panel functions (which left the character sheet to open as ours); the game's map chosen in
  *Classic windows* opens by its key. In an instance the small window shows the game's minimap with its own ground.
  The button *Sane UI* only on the game's own minimap and map; dungeon lists kept, boss models under the bar, a
  right click back to the map it was opened from; the canvas asks for the zone a few times a second, places only
  the pins on what the game tells, and lays nothing out on the window's way.
- **2026-10-30, one switch:** no pin and no close button on the quest log: the button *Quest Log* on the full map's bar turns it on
  or off in both its looks; its title bar lower, its first row right under its words; objectives with their count and the
  game's sword or sack first.
- **2026-10-30, ghosts:** a quest's story comes first in its text; the quests of a giver's exclamation mark stand in the log
  as ghosts, a red exclamation mark and a red X saying so, their titles normal, out by that X, the right button or the X
  over them all. A + on the level of a quest meant for a group (`ForGroup`, `Title`).
- **2026-10-30, an open quest's text and rewards:** its text in rows of the list under headings, on a dark panel; its
  rewards as big icons with their names and the game's tooltip, currencies and spells too, a preview's as well; a
  quest's gold shows at last (`Core.Coins`).
- **2026-10-30, the quest log leaner, its items, a click for the pin:** no question mark before a quest, no tick
  after it, its title only the count and the sorting, rows closer to the screen's edge (pinned too its list and
  title); the items of quests at the far end of their rows, secure buttons on a tray of their own; mirrored on the
  screen's right half. Same day: a click on a quest unfolds its objectives, rewards and story under it, as a row of
  the list in place of the panel below it (its buttons are in the right button's menu), and folds them away; a double
  click puts the map pin there; a click on the title bar beside its words hides the list.
- **2026-10-29, the quest log sorted, two looks:** its title bar says the quests of how many and the sorting
  (Proximity first, Level, Zone, Type), a click there sorts the next way; no *Complete* at a quest's right, a done
  quest's turn in kept as an objective; pinned on the screen alone at a place of its own (the screen's top left
  corner at first), without its pin and close button, clicked through but its title bar and words, the objectives
  done and the fold marks left out, the game's quest tracker out of sight meanwhile.
- **2026-10-21, the quest log as Saneroki asked; found herbs clicked:** no scroll bar at rest (the wheel scrolls;
  the bar shows while the mouse is on a list longer than its room, at the window's docked side); each quest's mark at
  its row's left as on the map; a click puts the game's map pin on its objective (`QuestLog.Pin`, `PinView.Drop`)
  and leaves the map as it is; the right button's menu has *Quest Details* (the text below, closed by its X) and
  *Show Map*. The found herbs and ore on the minimap take the mouse: a tooltip and the map pin on a click.
- **2026-10-20, the tram in the routes:** the planner takes the Deeprun Tram between Stormwind and Ironforge where
  it is quicker: from one city's entrance to it to the other's, its cost the walks down and up and the loading
  screens (`Planner.STATION`), half the time between two trains and the run (Core's set *Travel*: `wait`, `time`);
  drawn red, straight from entrance to entrance.
- **2026-10-21, dungeon maps of Core's data, with their bosses:** Forever's client has no maps of its dungeons, so
  the view's list takes Core's new set *Dungeons* too (the classic dungeons' and raids' floors in the game's own map
  art, their world boxes, where each boss stands and its look), with the game's boss mark per boss and the boss's
  3D model standing on it.
- **2026-10-20, quest marks as the game's, the filter in sections:** quests in your log the yellow ?, quests to
  take the yellow ! (no longer see-through), too low the grey !, for later a red ? (`Pins.RED` over the game's
  mark); the tooltips no longer say that a click puts the map pin there; the pin filter in titled sections
  (`ns.PIN_SECTIONS`, each kind's `section`) with icons of 24 (`TopBar.ICON`), rows 30 high.
- **2026-10-20, coasts and Blended:** the coast keeps what stands on the water (docks, piers, bridges, ships, as the
  minimap shows them) and the shallows of a beach, and a tile on a coast is cut by a finer mask of its own
  (`Art/Coasts/`, `Coasts.lua`); the new view *Blended* fades Parchment far out into Scrying close in.
- **2026-10-20, indoor maps:** inside a building or a cave, its indoor map over ours, from the game's indoor
  pictures with their black taken out, the floor at your height (Core's set *Indoors*, `dev/tools/indoor-art`).
- **2026-10-20, herbs and ore found:** the pin filter's herbs and ore of Core's data are *Possible herbs* and
  *Possible ore*; new are *Found herbs* and *Found ore* (`Found.lua`): what the game's minimap shows now, each in
  its own picture, the switches doubling as Find Herbs and Find Minerals, which take turns while you move, without a
  sound (`Nodes.lua`); and sparkles on the herb or ore your interact key would gather (`Sparkles.lua`).
- **2026-10-30, at a toast's height:** at Saneroki's ask the overlay stands level with the toast of a new level: the words
  over its line at `Core.TOAST_TOP` below the screen's top, wherever the screen's height (was a share of it).
- **2026-10-31, a way asked for:** at Saneroki's ask the planner finds a second way, for Speed Leveling's arrow through
  Core (`Core.Ways`): to the guide's place, whatever the map pin says and with *Route to the map pin* off, followed by
  the arrow's asks (the canvas may not be up) and never drawn. `Planner.lua`'s state went into two ways, `pin` and
  `guide`; where the pin stands on the place asked for, the pin's way is the one and no second search runs (`Settle`).
  `Ahead` tells the arrow the line `Planner.LEAD` yards on, the yards to the next ride or the end, that ride and where
  it brings one. The overlay tells Core when it shows (`Core.TellsAtTop`): the arrow stands at its place and makes way.
- **2026-10-30, the way out:** at Saneroki's ask the overlay stands a little higher (`TripView.UP` 0.72, just under
  the game's error messages) and holds the way out of every flight and vehicle (what the game's own button asks,
  `CanExitVehicle`), alone in a vehicle. The game's `MainMenuBarVehicleLeaveButton` is lent (`Core.Lend`: alpha 0, no
  mouse), never hidden by us: its OnHide has Edit Mode's manager lay out the action bars, which would run tainted.
- **2026-10-21, the travel overlay:** at Saneroki's ask the trip view stood two thirds up the screen, a fine
  golden line in the map route's art (its glint pulsing along) in place of Core's bar, eased every frame between
  Core's looks (`TripView.EASE`; Data.Trips gives each trip's `pace` and `t`), the vehicle's icon at its tip, the
  ends' names above the line's ends. Waiting at a dock or the tram's station it shows the next to come there
  (DockWatch.lua now only finds the rows, with `arrive`, `leave`, `last`, `every`); the tram's times are learnt on
  a ride (Core's `Trips:NearTram`, `Trips:TramNext`).
- **2026-10-20, the trip on screen:** `TripView.lua` (setting *Your trip on screen*) shows the trip Core's
  `Data.Trips` finds: a flight (its route read at the flight master), a boat or a zeppelin, the Deeprun Tram (Core's
  set *Travel*, from the game's tables); the game's *Request Stop* button on a flight. While flying, the planner
  draws the flight's way on from the player (`Planner.lua`, `Fly`) and plans from where it lands; without a map
  pin, the flight's way alone; a leg in front stays drawn when no way on is found. The dock watch steps aside on a
  trip.
- **2026-10-20, ship times:** the planner takes its ships from Core's timetables (`Data.Ships`, `Planner.SAIL` and
  `Planner.LEAP` gone): the game's transports' speed, the time once round of the ways Forever has as the original
  game's, and when each really sails on this realm, learnt on a ride; the wait for a ship is then the time to its
  next departure. The dock watch (`DockWatch.lua`, setting *Ship times at a dock*) shows at a dock where its ships
  go and when they arrive and leave, and aboard when it lands.
- **2026-10-20, indoors without black:** the game's minimap keeps its own ground off indoors too (it drew the indoor
  plan on black over our map); the spirit healers in the game's spirit icon.
- **2026-10-20, a click on a pin:** the game's map pin where it stands, on both maps; on the full map a quest also in
  the quest log; Shift and a click opens a pin's map.
- **2026-10-20, the game's minimap square again:** in a window that is not square its band masks left the game's
  minimap empty (no dots, no arrow); it is now as large as the window's shorter side, cut by the game's own square.
  The masks and their tool are gone.
- **2026-10-20, icons and quests:** every kind of pin in its own icon from the game's map icons (no discs or
  numbers, a gathered marker in its first pin's icon), the filter's rows with their icons; the quests split in the
  filter (in your log, offers, low-level, for later, done), grey ! for those too low or for later with why in the
  tooltip, a quest giver's quests shown in the quest log as previews with a red X; NPC titles in the tooltips; the
  quest areas' slider their opacity.
- **2026-10-20, pin sizes and quests:** a size slider per kind in the pin filter (the setting `pinSizes`, per
  profile), givers of quests you can take see-through, and the kind *Done quests* for givers of quests you have
  done.
- **2026-10-20, the route and the minimap's dots in the pin filter:** the switch *Route to the map pin* became the
  pin filter's first kind, and *Minimap dots* the second: the game's minimap shows on the full map too, around the
  player at the map's scale. Settings of before are taken over (the module's settings version 1).
- **2026-10-20, inside the window; the corner sizes it:** the route, the pins and the marks keep inside the canvas
  by themselves (`Canvas.edge`); they were drawn over the screen around the small window. The small window's
  corner away from the screen's edges sizes it outside Edit Mode too (Core's window option `grip = "hover"`).
- **2026-10-20, the golden line drawn:** the line's first segment stopped the module (the map window closed, the
  game's own minimap and map back): the glint's pulse was made in Lua, and the game gives a `TextureCoordTranslation`
  made there no `SetOffset`. The pulse is now a template in `Route.xml`, as the game's own lines have theirs.
- **2026-10-20, Zephras Isle's terrain:** the isle has the continents' data: its tiles in Core's set *Tiles*, its
  overview, outline and stitched map (`dev/tools/terrain-art --maps 2991`, the open sky around it cut away), and
  its walking data (`dev/tools/walk-data --maps 2991`). *Scrying* and *Atlas* draw its terrain, *Parchment* its
  own map under the stitched one, and routes there walk around what cannot be walked. Terrain, Art and Painted
  draw every plane (`Coords.Planes`); Art's maps under the stitched map have textures of their own.
- **2026-10-20, the map on Zephras Isle:** the views work on the isle as on a continent: they follow the player
  there, draw its pins (its zeppelins' tower) and the party, list it in the map selector and the quest log's search,
  open it from the world by a click and put the map pin on it. The isle is its own zone, with no continent's level
  (`Coords.Alone`); `Coords.PlaneAt` replaces `Coords.ContinentAt`, and `Live.Player` gives the isle's plane
  without being asked (its `anyPlane` gone). The continents' zoom levels and drawing are as they were.
- **2026-10-20, docks on the map:** each dock of the boats and zeppelins is a pin (`TaxiNode_Continent_*`), one per
  dock also where a ship stops twice, its tooltip where it goes from there; the docks' map points written by
  `dev/tools/travel-data` from the game's tables (Core's set *Travel*, `docks` and `dockAreas`).
- **2026-10-20, Zephras Isle:** the routes reach it: a map straight on the world map with a box of its own is a
  plane for the planner (`Coords.PlaneOf`, `Coords.Planes`), so its two zeppelins carry the line there, and the
  map pin's mark shows on it; walks there stay straight (no walking data of the isle).
- **2026-10-20, across the sea:** routes by boat and zeppelin, from dock to dock on the game's own ways of them
  (`dev/tools/travel-data`, Core's set *Travel*: twelve ways, their docks and stays), the wait and the trip guessed
  from the way until learnt; the line stays while aboard; the hearthstone, its place learnt per character.
- **2026-10-20, routes:** the golden line to the map pin, on foot and by the flights this character knows, over the
  walking data made from the game's own terrain, buildings and water (`dev/tools/walk-data`, Core's set *Walking*)
  and the flights of the game's tables (`dev/tools/travel-data`, Core's set *Travel*).
- **2026-10-20, pins and the quest log:** the pins of the game and of Core's data (`Data.Map`), one per thing,
  filtered and gathered, always over the map; quest areas; the party; the quest log at the full map's left and the
  bar over the full map (views, map selector, pin filter); the golden line's drawing. The Classic windows are kept
  choices and the corner always opens our map; the game's minimap cut to the window's shape.
- **2026-10-19, the Atlas:** the view *Overlay* is gone (the default view is Scrying; a saved Overlay falls back to
  it); the painted map *Atlas* is a module of its own, `SaneUI_Atlas`, found at login and loaded when its view is
  first drawn, three times closer; without it the map offers two views.
- **2026-10-19, later:** a zone lights up under the mouse and opens by a click (a continent at the world); the
  map grows and zooms with its window on the way to the full screen and back; the game's minimap covers the
  whole small window, always above the map; the corner fills the screen once a visit. The terrain's water cut
  away; Blizzard's maps cut to their zones' outlines, every zone in view in its own map. Then, at Saneroki's ask:
  the view *Sketches*, one stitched map of both continents at every zoom, every zone's map in full, the
  outlines fading softly into each other (the dark undiscovered parts taken out again).
- **2026-10-19:** the whole module but the map's data: the minimap and the map the same map, each view with its
  own camera; the views at every zoom out to the world, the terrain's overview; right click, Ctrl-click and
  the map pin; the game's minimap over ours for its live dots; the game's map and its keys taken over; the
  switches for the game's own; what the game tells (`Live.lua`).
- **2026-10-18:** the first step: the full screen map from the top right corner, drag and zoom, the views
  Blizzard maps, Terrain and Overlay; Core's set *Tiles*.
