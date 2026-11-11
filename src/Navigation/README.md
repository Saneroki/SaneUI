# Sane UI: Navigation

**Status:** the minimap and the map in one window, with pins (the game's and Core's data), the quest log, the bar over the full map and routes to the map pin on foot, by flight, by boat and zeppelin, by the Deeprun Tram, by lift, through portals and by the teleports a character has (the hearthstone told in the chat where it is quicker), on foot coloured by how dangerous they are, through waypoints dragged on the full map; the leveling guide comes later · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Sane UI's minimap and world map are one window. Small, in the screen's top right corner, it is the minimap;
move the mouse into that corner and it fills the screen as the map. Both are the same map, drawn and handled
the same way, only larger, as the chat window is the same chat when it fills the screen. Each keeps its own
zoom and place. The map is drawn two ways at every zoom, from close up out to the whole world, both
continents always: *Parchment*, the world drawn by hand, Blizzard's zone maps in full joined into one map that
fades softly from zone to zone; or *Scrying*, the land as the minimap shows it, its water cut away to a calm sea
(the docks, piers and bridges standing on it kept); or *Blended*, the one far out fading into the other close in.
The game's own minimap lies over it for its live dots; the game's map stays closed, and its keys open ours.
That is WoW: Forever's map; in Retail the map is the game's own map tree, one map at a time, as the game's own map
shows it: a click into a map, a right click out to the one over it, the wheel within it.
On the map stand pins in the game's own looks (quests, flight points, rares, entrances, places, services, the
party), always over the map; the quest log, a window of its own over the full map and on the screen while the map
is small, and the maps of the dungeons and raids. The plan is in
`Doc/ideas/Navigation.md`.

## How to use
- **The map:** move the mouse all the way into the screen's top right corner; the corner again (move away
  from it first), Esc or the close button on its title bar brings it back. On the way the map grows and zooms
  with the window, from the small view to the full one. The game's map key (M) and quest log key (L), `/sane map`,
  and every other way to the game's map (the quest log button, a click on a quest, a chat link) open it too.
- **The same in both views:**
  - **drag** with the left button: the map moves, and stops following you; anywhere on the world map, at any
    zoom: dragged off a continent over the other (or Zephras Isle), the map goes on there, no continent to choose
    first;
  - **the mouse wheel** zooms around the point under the mouse; while the map follows you it walks the game's
    minimap's zoom steps first (its live dots show then), then goes on out to the whole continent and the
    world, and in past the game's nearest step four times nearer than it;
  - **right click:** one map out (a zone, its continent, the world), as on the game's map;
  - **middle click:** back onto you, following you again, near enough for the game's minimap's dots: on the
    small map at the game's middle zoom step (of its six), on the full map where that step's square takes half the
    map's height (the game's dots show around you there too); in Retail on the map you are on;
  - **the mouse over a continent shown whole** lights up the zone under it in the game's own highlight, over
    the world the continent; **a click** opens it, as on the game's map. On the full map its name stands at the
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
    switches between them, Ctrl and a click takes it away, Shift and a click writes it into the chat.
- **Pings of your party and raid** (and your own) show where the game's own minimap lies over the map (around you:
  the small map while it follows you at one of the game's zoom steps, the square around you on the full map), drawn
  by the game, with its sound. Farther out the map shows none: the game does not let an addon hear its pings.
- **Following you:** both views follow you at first. The box **Follow me** on the full map's bar (left of *Pins*, on
  at first; also the setting *Follow me*) says whether the map comes back to you. Ticked, the minimap you dragged
  away snaps back the moment you walk; the full map opens on you and keeps you in its middle, and dragged away, moved
  to a quest or to a map chosen on its bar, it comes back as you walk once you left it alone for 10 seconds (standing
  still, you can look around). Not ticked, the full map stays where you leave it, and the minimap stays where you
  moved it until the middle mouse button brings it back; one still on you keeps following. In an instance the small
  window shows the game's own minimap, ticked or not.
- **In a dungeon, a raid or a battleground,** where the game tells no place of yours on our map, the small window
  shows the game's own minimap alone, with its own ground and dots, as the game's would; the wheel walks its zoom
  steps. One notch out past its widest step shows a dungeon's or raid's whole map there instead (where we have one),
  its bosses as on the full map, smaller; a notch in, a right or a middle click brings the game's minimap back at its
  widest step. Left so, it stays through the full screen and back and into the next dungeon. Out of it, our map is back.
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
  where it tells them (your quests: the yellow ?, the quest the arrow leads to glowing; flight points of your side,
  red while your character has not found them (the routes fly only the found ones);
  rares (a skull; hold Alt over one and its 3D model stands beside the tooltip) and treasures (a chest) nearby; the
  game's points and ways into other maps), and what Core's data
  knows: quest givers with a quest you can take (the yellow !), with a quest too low to give you experience (a grey
  !) or one you cannot take yet (its level, a quest first: a red ?), or with quests you have done only (grey, off
  at first); services, each its
  own (the innkeeper's mug, the banker's bags, a class trainer's book, a profession trainer's scroll, a merchant
  the game's anvil, one of food, reagents, poisons or ammunition the game's icon for those...), entrances, the docks of the boats (a boat) and zeppelins (an airship) with where they go, where
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
  the game's minimap too, largest far out and smaller as you zoom in, gliding smoothly as they move.
- **The pin filter** (*Pins* on the full map's bar, or the setting *Pins on the map*): a checkmark per kind, each
  with its icon large before its words, in sections under their titles: *Around you* (the route, the minimap's
  dots, the party and raid), *Quests*, *Travel*, *Towns and services*, *Rares and treasures*, *Gathering*; it
  scrolls on a screen lower than it. The quests each a row of their own: *Quests in your log*, *Quest offers*, *Low-level quests* (no
  experience for you any more), *Quests for later* (once you meet what they ask), *Done quests*, *Quest areas*, *Quest
  areas on the minimap* (off at first) and *Quest objectives*. Its
  first two are no pins: *Route to the map pin* (the golden line) and *Minimap dots*: what the game's minimap
  shows around you (players, tracked herbs and ore), on the small map and on the full map too, there
  around you at the full map's own scale (shown while it fits inside the map). Both are on at first. At each kind's
  right a slider sets its size on the map, 50 to 200 percent (the route: its line's thickness; the party: its
  marks; the quest areas: their opacity, 10 to 100 percent), kept with the settings.
- **The satchel** (the leather satchel in the small map's lower corner at the screen's edge; the upper one where
  the window stands in the screen's lower half): a click opens a page beside the map, in large cells easy to hit.
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
    dropdown lists the profiles, the one in use first; choosing one sets it at once. *(changed)* after its name:
    the game's sound settings differ from it now. The cogwheel opens a menu with the game's sound settings: a
    checkbox and a slider for each of *All sound*, *Music*, *SFX*, *Dialogue* and *Ambience*, working at once (the
    profile keeps them only when saved), then **Save** (the settings now into the profile), **Load** (the profile
    set again), **New** (a profile of the settings now, its name asked) and **Delete** (the profile in use, asked
    first; not the last one). Then the quick switches Sane UI's modules offer (`Core.Offer`): *Speed Leveling*, the
    same as the box at the foot of the bags; on is ticked, off is faint;
  - **AddOns:** the buttons other addons put round the game's minimap, gathered here (with our window as the
    minimap they would otherwise stand on our map only now and then, or nowhere), each its picture round, without
    the golden ring round it, with its addon's name under it, its clicks and tooltip its addon's; and the addons the game's addon compartment lists
    (the game's own button for them is out of sight with its minimap's frame), a click on one as in the game's
    menu. An addon with both shows once. With the game's own minimap chosen they are back round it. Only while
    there is one: with none the section is not there;
  - **Pins:** every kind of pin the map can show, a click shows it or not (as the pin filter; the sizes stay there);
  - **Tracking:** what the game's own minimap tracks, as its tracking menu lists it (the townsfolk, a hunter's
    beasts...), a click switches it; Find Herbs, Find Minerals and Find Fish are *Found herbs*, *Found ore* and
    *Found fishing pools*.

  Compact: six cells a row, each picture straight on the paper (no pencil slot), the addons' twice as large. A cell that is on shows its
  picture whole with a pencil tick, one that is off faint and grey. It goes the first time the mouse leaves it,
  until the button is pressed again: the button counts as the page, the short way between the two is free, and a
  menu one of its cells opened holds it. The button again, its X or Esc closes it too, and so does the map filling
  the screen; the wheel scrolls it on a low screen.
- **Found herbs and ore** (the pin filter's *Found herbs* and *Found ore*; Saneroki, 2026-11-11):
  - **where they can be:** every spawn of Core's data of a herb or an ore around you, while its kind is on and you
    have its finder, in the picture of what it gives in the leather ring, half opaque (`Found.POSSIBLE`), under the
    game's minimap: its own yellow dot of one up now stands on the picture of what it is. In the small view and on
    the game's own minimap; the small view's pins *Possible herbs* and *Possible ore* give way to them there
    (`Found.Draws`), the full map keeps its own.
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
  to. They stand without a glow; **with the mouse on a quest in the quest log its pins glow a little**, its question
  mark too, so you see which pins are whose. An item many creatures may drop: only those that give it often, twelve
  at most. A pin's tooltip says what stands there, the quests it is for and what is left of the objective in the
  game's words; a click on the full map shows the quest in the log, as on its question mark. An objective done takes
  its pins away. What a quest asks for stands as that, not as the rare or the herb it is as well. A creature's spawns
  near each other are one marker in its picture; other things stand beside it in the cloud. A quest the data does not
  hold has the game's question mark and area alone, and so has every quest in Retail until its data comes.
- **The quest log**, a window over the full map and on the screen while the map is small (**the button *Quest Log* on
  the full map's bar turns it on or off, in both**; no pin, no close button; drag its title bar to move it, dock it at
  a screen edge, size it by its corner). On the screen alone it stands in place of the game's quest tracker, which
  stays out of sight even with the log turned off (*Show the game's map* brings it back), at a place and size of its own (at first the screen's top left corner), without a background, a
  border or a line under its title, only the list over the game, clicked through but its title bar and its words.
  There it rests out of sight as your unit frames and action bars do (*Hide the quest log at rest*, on at first): it
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
  than its room the game's thin scroll bar shows at the side the window stands at (docked at the left edge: its
  left). **A click on a quest unfolds its story, its objectives and its rewards under it,** one quest's at a time, each
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
- **The map selector** on the bar: the world, a continent or Zephras Isle, then a zone of it.
- **Dungeons** on the bar: every dungeon and raid the game has a map of, and those Core's data has a map of
  (26 of Forever's: the classic dungeons and raids, each floor in the game's own map art), A to Z; chosen, its map
  over the map, and beside it its floors; each floor opens whole, under the bar and beside the quest log, so the
  farthest zoom always shows all of it. Where the data knows them, each boss as its own 3D model where it stands
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
  enemies stand there too, each a small red dot under the bosses, its name in its tooltip (six dungeons so far). The wheel zooms it, a drag moves it, a right
  click goes back to the map it was opened from. Shift and a click on a dungeon's entrance opens it too, and inside a
  dungeon the full map opens on its map, at its lowest floor. Instance maps keep rules of their own, apart from the
  world map's and its indoor maps': Forever tells nobody's place inside an instance, so they show no arrow for you
  and no party or raid; what stands still there, the bosses, stands on them.
- **Zephras Isle** is on the map as a continent is, a zone of its own: the map follows you there, its pins and the
  map pin stand on it, a click on it at the world opens it, and a right click on it goes out to the world (there is
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
  leave it and it is planned again. A pin on another continent or on Zephras Isle is reached by boat or zeppelin,
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
  counts the wait for the next one (until then half its time once round). *Route to the map pin* in the pin
  filter switches it off.
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
  map as it always is (both continents, its view, every pin, the quest log), zoomed out to the whole world: its
  flight points large, over every other pin, the one you stand at glowing, at each one's right its name and what the
  flight there costs (the text larger the closer you zoom, under every pin so it never covers one or takes its
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
- **Map view** (the buttons on the full map's bar, or the setting on the page *Navigation*): *Parchment*,
  *Blended* and *Scrying*, for both views and at every zoom (in the code `sketches`, `blend`, `terrain`). The map
  starts as *Scrying*. *Blended* is Parchment out to a zone's level and Scrying close in, the maps fading out over the
  land in between. A view not offered (*Overlay* and *Atlas*, which are gone) falls back to Scrying.
  In Retail, until its data comes, Parchment is the one view: the map simply is that, with no view buttons on the bar
  and no setting.
- **The game's own windows:** the full map's dropdown *Classic windows* offers the game's minimap and map, each
  kept once chosen (ticked; chosen again, ours comes back), as the switches *Show the game's minimap* and *Show
  the game's map* on the page. With the game's minimap our small window rests out of sight; with the game's map
  its keys and buttons open the game's (chosen there, it is not opened at once: its key opens it, and the chat
  says which key). Either way the
  mouse pushed into the top right corner still fills the screen with
  our map. The game's key to show or hide the minimap (in its key bindings) shows or hides our window. The
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
  to its grid's edge), and the same file is the mask of the game's tiles of its block (`Canvas.Masks`), so
  the coast is cut alike at every zoom; a tile on a coast (`Coasts.lua`) is cut by a mask of its own instead, at
  four times the overview's detail (`Art/Coasts/<key>.blp`, 128 x 128), so a pier a few yards wide is not lost up
  close; under it the canvas' sea: its colour, and over that its layers (`Canvas.SEA_LAYERS`), repeated over the
  plane, so they move with the land, each copy its size in units at every zoom, in the open sea, the lakes and the
  rivers alike: the waves (`Art/Sea.blp`: the game's own ocean texture, its light alone, softened by a pixel) twice,
  small and larger by no whole factor, shifted and turned half round, so the two grids never line up alike and no
  copy shows as a tile; over them a soft shade (`Art/SeaShade.blp`, a tileable noise) in slow patches of darker
  water.
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
  exploration provider places them. Under the mouse, at a continent or the world shown whole, the game's own highlight
  of the zone or continent there.
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
  `LIVE`; the arrow's quest: the game's alone), Core's in parts: the NPCs' read again when the log or the level
  changed, the objects', places' and ways' when Core's places change; at a zone's level every zone in view (on
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
- **Dungeons** (`Dungeons.lua`): the maps of kind *Dungeon* under the world map (`C_Map.GetMapChildrenInfo`), one
  entry per map group (`C_Map.GetMapGroupMembersInfo`: its floors, lowest first), drawn in a view of their own over
  the canvas, under the bar: the floor's art (`Art.Of`) fitted whole in a frame that is scaled to zoom (up to
  `Dungeons.NEAR` times) and moved by a drag (its step runs only while a drag goes on); fitted into the room the
  bar's row (`2 * TopBar.INSET + TopBar.BUTTON_HEIGHT`) and the quest log leave (`Room`: the log's side, its box
  `QuestLog.Box` and the bar's gap, at most `Dungeons.SIDE` of the width), measured as it opens, when its size
  changes and when the log comes or goes (`Dungeons.Refit`, from `Window.Lay`), not at each step of a drag; on
  the small map (`Dungeons.Whole`: in an instance, `Canvas.lua`'s `Wheel` one notch out at the game's step 0) the
  whole small view, the floor never zoomed or dragged there, its marks, models and dots at `Dungeons.SMALL` of
  their size; wished (kept through the full screen and back, `Dungeons.Small` at each layout of the small view,
  looked at anew after a loading screen) until a notch in, a right or a middle click (`Dungeons.Out`), and the
  game's minimap out of sight under it meanwhile (`Hybrid.Hide`, `whole` in `Canvas.lua`); no player's arrow and no
  group (Forever tells no place inside an instance). `Canvas.Show` of a dungeon's map opens it; going small or a right click closes it (the map under it
  stays as it was). The list is kept once the game told of a dungeon map or the set was read. Core's set *Dungeons* (pack World)
  adds the dungeons the game has no map of: walked once it is there (`Each`), each floor keyed `"<instance>:<floor>"`
  (`Dungeons.Key(instance)` gives the lowest; an entrance's pin takes it as its `to`), its art from the set's tiles
  (the game's files), inside one its lowest floor (`Dungeons.Here`, the instance from `GetInstanceInfo`), the
  enemies (the set's `enemies`, `Dungeons.Enemies`, `Dungeons.PlaceEnemies`: `Dungeons.ENEMY` at `ENEMY_SIZE`, a
  level under the bosses' marks, named by the set *NPCs*), the bosses (`Dungeons.Bosses`) in
  `Dungeons.BOSS` over the art, the same size at every zoom (`Dungeons.PlaceBosses`), named by the set *Encounters*;
  a boss with a look (the set's `display`) gets a `PlayerModel` of it standing on its mark (`SetDisplayInfo`, as the
  game's guild news shows a boss; `Dungeons.MODEL_WIDTH` x `MODEL_HEIGHT`, turned `Dungeons.FACING`), one lower on
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
  `Taxi.Lines`; shown whatever the pin filter says, at the pins' top level (`PinView`), at each one's right its name
  and price (`Taxi.Label`: a font string on `PinView`'s layer of names, at the pins' layer's level so under every
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
  legs after the next fainter. A dark edge, the game's dependency bar art tinted gold, its glint moved along by a
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
  on the screen alone (`store.questLogSmallPlace`, at first
  the screen's top left corner) in the layer `LOW` without one (no skin, `barLine = false`), the frame without the mouse
  and each row's hit rect only its words (`Reach`), the mouse wheel
  the game's while the list fits, the objectives done left out, no fold marks. One switch for both, `store.questLog`
  (TopBar's button); no buttons on its low title bar (Core's `bare`, `barHeight`). The game's `ObjectiveTrackerFrame`
  lent to a hidden frame (`Core.Lend`; `QuestLog.Tracker`), the log shown or off, while `nativeMap` is off; it is a
  managed frame, which the game's frame manager reparents whenever an Edit Mode layout is applied, so a hook after its
  `SetParent` puts it back at once. An objective's words made anew from the game's
  (`Objective`, `Asked`, `QuestLog.ASKS`). Sorted (`store.questLogSort`, by Core's `titleClick` on its
  title, `titleTip` its tip; the title `%d/%d <sorting>`): by `GetDistanceSqToQuest` (looked at again
  every `QuestLog.RESORT` seconds by a ticker while shown, drawn anew only once the order changed), by level, the
  game's own with its headers, or under `GetQuestTagInfo`'s tag. A `WowScrollBoxList` of rows read from
  `C_QuestLog` (Zone: the game's headers, not as the game keeps them folded, which a window of ours could not undo on
  the screen alone: a zone folded is ours, `store.questLogFolds`, over the full map only; quests with level, failed, watched; objectives; a done quest's turn in from
  `GetQuestLogCompletionText`, else `GetNextWaypointText`, else `QUEST_WATCH_QUEST_READY`, as the game's tracker),
  built again on `QUEST_LOG_UPDATE` once a frame and only while it shows; its `MinimalScrollBar` hidden but while the mouse is on the window and the list
  has more than its room (`HasScrollableExtent`), then at the docked side (`Side`: the window's dock zone, else the
  screen's half its middle is in; on the screen alone the other side, `Margin`); a click: the quest super-tracked,
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
  (`lent`), so never beside the game's own (Edit Mode, *Show the game's map*, the module stood down). Counted down by a
  ticker of `QuestLog.CLOCK` seconds while they show (`DockWatch.Clock`), the last `QuestLog.HURRY` in Failed's red;
  the line mirrored with the log (the time at the screen's edge).
  A quest's text from `GetQuestLogQuestText`, its rewards by the quest's ID (`GetQuestLogRewardXP`,
  `GetQuestLogRewardMoney`, `GetNumQuestLogRewards`, `GetQuestLogRewardInfo`, `GetNumQuestLogChoices`,
  `GetQuestLogChoiceInfo`, `C_QuestInfoSystem`'s currencies and spells: no quest chosen for them), read only while the
  text shows, as rows of the list under the quest, a preview's too (kinds `section`, `text` and `reward`, each `part`;
  `AddText`: as high as `measure` says its words wrap at the list's width, `Reveal` brings them into sight), for the open
  quest alone (`open`: a click, the menu's *Quest Details*, a click on its pin). A reward is a cell of its row
  (`Rewards`, `RewardCell`), a plain button, its tooltip the game's by the quest's ID (`SetQuestLogItem`); an item the
  game does not know yet comes in by `ITEM_DATA_LOAD_RESULT` (`missing`). The lab's scene `questlog` shows it all; abandon
  after the game's own question (`GENERIC_CONFIRMATION`); never the quest panels of the game's map (their
  details window is opened by the game's panel manager, which our call would leave tainted).
- **TopBar** (`TopBar.lua`): over the full map's top: the quest log's button, the views, the map selector (the
  game's dropdowns, radio entries of the world, its continents and Zephras Isle, the zones of the one shown A to
  Z, the isle itself on the isle), the dungeons and the floors of the one shown, the box *Follow me* (the game's
  `UICheckButtonTemplate`, its words between it and the pin filter; the setting `followMap`) and the pin filter
  (checkboxes); it says what the map shows after each layout. With one view alone (`ns.Several`) it has no view
  buttons, the map selector right of the quest log's. The view buttons are `TopBar.VIEW_WIDTH` wide and the
  pin filter `TopBar.PINS_WIDTH`, so the whole bar fits a screen 1366 units wide (1080p at the game's scale).
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
  minimap. The page is a frame of its own (strata `DIALOG`) in Core's journal (`Core.Journal.Dress`: paper, leather
  top, its X; left of the X, at its level, `Satchel.swap`: Core's `Window.Swap`, whose click closes the page and
  sets `nativeMinimap`, as the dropdown *Classic windows* does), beside the window toward the screen's middle, a scroll frame in it no higher than
  `Satchel.ROOM` of the screen. Its sections, each a title over a pencil rule (the zone's: none, `Title`) and a grid
  of `Satchel.COLUMNS` cells, a section with no cells left out: *Sane UI* (first the sound line, `AudioLine.Place`,
  while the client has the game's sound settings, `AudioLine.Offered`; then `Core.Switches`, the modules' quick switches as offered; a
  click its module's `Click` with the mouse button and the cell; filled anew when `Core.OnSwitches` tells a change),
  *AddOns* (`Strays.List`, A to Z), *Pins* (`ns.KINDS` offered here, in the
  pin filter's order; a click `ns.SwitchPin`, the pin filter's own), *Tracking* (`C_Minimap.GetTrackingInfo`, the
  entries the game's tracking menu lists: a spell's, or one of its optional filters, Forever's
  `MinimapConstants.OPTIONAL_FILTERS`, else Blizzard's list of them by `Enum.MinimapTrackingFilter` names; not the
  finders `Nodes.KIND`). A tracking entry is switched as the game's menu switches it
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
  radios, the one in use first (`Audio.Use`); the cogwheel's a title (the profile's name), a checkbox per sound this
  client has (`Audio.Kinds`, `Audio.Set`) with the game's `MinimalSliderWithSteppersTemplate` lent to its row as in the
  pin filter (0 to 100 % in `AudioLine.STEPS`, the game's 5 %), and the buttons Save and Load (the menu stays open,
  its rows read anew: `MenuResponse.Refresh`), New (`Core.AskText`) and Delete (`Core.Confirm`; off for the last
  profile). The gear is the game's silver atlas `GM-icon-settings` as it draws it, else the icon `INV_Misc_Gear_01`. The
  dropdown's words follow `Audio.Watch`, *(changed)* while `Audio.Changed`.
- **Following again:** the tracker follows again where `Again` says, never with a mouse button held. Where the game
  tells no place of the player (an instance) the small view does at once, ticked or not, so the game's minimap is the
  map there. Else only with *Follow me* ticked: the small view as soon as the player moved since the last look; the
  full map also only `Canvas.AGAIN` (10) seconds after the mouse last did something to it (a quest moved to, a map
  chosen on the bar or by the game count as that: `lastInput`). Ticked, `Canvas.Center` puts the full camera on the
  player whenever the window fills the screen (but at a map the game was asked for, `Window.OpenTo`) and when the box
  is ticked; unticked, the full map no longer follows, and a small view that follows goes on following.
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
- **Gates** (`Gates.lua`, no frames): the walking data's coarse layer, the set *Walking*'s field `gates`, made by
  `dev/tools/walk-gates` from its blocks: per terrain tile its gates, where one walks across its border into the next
  tile (the openings between a part of the tile and a part of the next, joined along the border and cut into pieces of
  at most 64 samples, each the same on both tiles: `Gates.Id`, `Gates.Ends`; a part: the rectangles one walks between
  without leaving the tile, `Gates.Parts`), and what the walk between each two gates of one part costs inside the tile
  (`Gates.Cost`: its yards on land, those swum at the walker's price, each yard up `Search.CLIMB` more, of the way on
  foot and the one a rider takes instead, where the one on foot swims, the cheaper). Unpacked when first needed (some
  16 KB a tile), the `Gates.KEEP` asked for last kept; a tile's layer made from another block than the one the game
  holds (another number of rectangles) is passed over there.
- **Search** (`Search.lua`, no frames): a walk between two points: A* over the rectangles through their openings
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
  (`Route.Cut`). A ship (`Planner.Ship`): its docks and trips from Core's timetable of it (`Data.Ships`:
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
  pin, at a fixed size, and the party and raid (the game's party blip in the class colour, four times a second, at
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
  while the pin filter's *Minimap dots* is on, in both views. In an instance, where the game tells no place of
  yours, the small view's game minimap is the map alone: in its middle at the view's step (the game's own while
  the view has none), its ground on (`C_Minimap.SetDrawGroundTextures`), whatever the pin filter says; off again
  once your place is known, and on, as the game has it, when given back.
- **The game's map** (`Native.lua`): the keys bound to the game's map, quest log and minimap click a button
  of ours (override bindings, out of combat, again when the bindings change). Every other way to the game's
  map shows `WorldMapFrame`: a hook after its `OnShow` makes it unseen at once and hides it on the next frame
  by its own `Hide`, and ours opens at the map it was asked for. Never the game's `ShowUIPanel` or `HideUIPanel`:
  their manager keeps the open panels in slots of its own, which our call would leave written by our code until
  a `/reload`, and the game's next panel there (the character sheet) would open as ours and fail on a secret
  value; a panel hidden by its own `Hide` the manager mends by itself before it shows the next one
  (`RepairUIPanelState`). In a fight the game's map stays open as the game's (hidden by our code then, its
  `OnHide` would run as ours in the fight). To see it in the game: `/console taintLog 1`, `/reload`, a click on a
  quest in the objective tracker (our map opens), then C (the character sheet): `Logs/taint.log` has no line of
  Sane UI's for it.
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
  every level, lit up before (`Art.Light` on the map shown); a right click goes up to the map over it: a zone, its
  continent, Azeroth, the Cosmic map of every world (`StepOut`). Following the player, it shows the map the player is
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
| `Navigation.lua` | The module's table (`ns`), its texts and settings, `/sane map`, `GiveBack` |
| `Camera.Retail.lua` | Retail's camera: one map at a time from the game's map tree (into a map, out to the one over it, the wheel within it, its art's layer), following onto the map the player is on; Retail's two answers of the map tree (`Coords.PlaneOf`, `Coords.Box`). Read in Retail alone |
| `Coords.lua` | Map, world and plane; a map's box; the map tree, the planes (the continents, and a map of its own on the world map) and the links between them, the top of the tree and the continents beside the world map (Retail's); the terrain's grid; the player's place. No frames |
| `Camera.lua` | Where a view looks: middle, zoom, following, the level its zoom shows; drag, wheel, one map out. No frames |
| `Live.lua` | What the game tells while playing, read when it changes. No frames |
| `Ping.lua` | The game's minimap ping on our map: a click's ping sent by the place's yards from you (after a double click's time), the group's pings kept where they are. No frames |
| `Canvas.lua` | The frame the map is drawn in: holder, layers, pools, layout, the tracker, the mouse |
| `Terrain.lua` | The terrain layer: the game's minimap textures from Core's set *Tiles*, and the overview |
| `Outlines.lua` | The zones that have an outline, by their plane's instance (the isle's too): made by `dev/tools/terrain-art`, not by hand; Forever's world, read in Forever only (its TOC line) |
| `Coasts.lua` | The tiles on a coast, which have a finer mask of their own, by their plane's instance: made by `dev/tools/terrain-art`, not by hand; Forever's, read in Forever only |
| `Art.lua` | The view Parchment: Blizzard's world and continent maps, the stitched map, every zone's full map cut to its outline; the highlight under the mouse |
| `Pins.lua` | The pins as plain records: the game's and Core's data per map, one per thing, filtered, side by side in a cloud where they would cover each other. No frames |
| `Goals.lua` | What your quests still ask of the world and where exactly it stands: the open objectives' things at every spawn Core's data knows. No frames |
| `Walk.lua` | Core's walking data: a tile's block unpacked, its rectangles, regions and openings; the floor a walker stands on, followed or chosen. No frames |
| `Gates.lua` | The walking data's coarse layer: each tile's gates into the next tiles, what the walks between two of them cost, the parts of a tile. No frames |
| `Search.lua` | A walk between two points over the walking data, from the floor the start stands on to a floor at the end: priced across the tiles by their gates, then drawn along that way. No frames |
| `Lifts.lua` | The lifts of Core's set *Travel* on the walking data: each end at its landing, the levels they join (stacked or side by side), where a place stands among them. No frames |
| `Taxi.lua` | At a flight master: our full map in place of the game's flight map (Shift held: the game's), its flight points large, a click flies there, the way there drawn. No frames of its own |
| `Corpse.lua` | While dead: the map pin at your corpse (where you fell, then where the game tells it), the one you had back once alive again. No frames |
| `Planner.lua` | The way to the map pin over every plane: on foot, by the flights this character knows, by boat and zeppelin, by the tram, by lift, through portals, by the teleports it has (the hearthstone told in the chat where it is quicker); where along it the player is. No frames |
| `Label.lua` | The zone under the mouse named at the top of the full map: its name, its levels, the fishing skill its waters ask (Core's set *Fishing*) |
| `Areas.lua` | A quest's areas, as the game shades them (`QuestPOIFrame`), over each zone in view |
| `Dungeons.lua` | The maps of the dungeons and raids, chosen in the bar: over the map in its place, by floor, whole beside the bar and the quest log, zoomed and dragged; inside one the small map's whole map, a wheel notch out past the game's minimap |
| `Route.xml` | The glint's pulse along the golden line: an animation template (the game makes that kind only from XML) |
| `Danger.lua` | How dangerous a place is for you: a grid per plane of the highest level of the enemies of your side spawning near each cell (Core's *CreatureSpawns*, *NPCs*, *FactionTemplates*), stepped against your level as the game's colours are. No frames |
| `Route.lua` | The golden line of a way, from the player on, the parts in view: walks and lifts gold (a walk orange or red where enemies above you spawn near it), flights white, ships and the tram light blue, portals violet, the hearthstone and the teleports pale blue; the stage under the mouse and the bend while it is dragged |
| `Paths.lua` | The ways of the flight point or dock under the mouse: each flight of your side from it white, a ship's way round light blue, its leaps along our sea lanes round the Maelstrom |
| `PinView.lua` | The pins drawn: a pooled button each, in the game's looks, tooltips, clicks; a rare's tooltip as a dungeon boss's, its 3D model beside it with Alt |
| `RareTracker.lua` | The Sane Rare tracker: rares, treasures, books and events near you (the game's marks on the minimap; a rare's nameplate, target or mouseover; a chest or book the interact key picks; a book still needed within 100 yards) told at once by a notice at the screen's right edge under the minimap, dragged where you like (its model or icon, name, rank and level, how far and which way) and the game's war horn; a double click: the map pin there, a right click: away; `/sane testraretracker` |
| `Marks.lua` | The player's arrow, the map pin, the waypoints (and the ghost of one dragged), the party, the pings |
| `Nodes.lua` | Herbs and ore: what one is by its name (Core's *Objects*, *Drops*), its picture, your skill for it; the finders (Find Herbs, Find Minerals, Find Fish) switched by the pin filter and in turn by yards moved, silently, and back on after you revive; one switched on outside the filter switches its kind on there. No frames |
| `Indoors.lua` | The indoor map of the building you are in: the game's indoor pictures without their black, at your floor |
| `Art/Indoors/*.blp` | The indoor pictures, one per part of a building, made by `dev/tools/indoor-art` |
| `Hybrid.lua` | The game's minimap over ours: taken, placed, given back |
| `Found.lua` | The herbs and ore the game's minimap shows: found by asking its tooltip at points of it, kept in yards, drawn over it in their pictures, each a button (tooltip; a click: a ping there, a double click: the map pin there); what is found goes to `Core.Sight` for the guide's detours; `/sane nodes`. Forever from build 70862 (`Found.SILENT`): found under the real mouse alone, on the spawn of Core's nearest it. Where herbs and ore can be: Core's spawns around you, half opaque, under the game's minimap's dots (`Found.Draws`) |
| `Sparkles.lua` | Gold sparkles on the plate of the herb or ore the interact key would gather; the game's interact key settings set and put back |
| `Glints.lua` | Far herbs and ore: the found ones beyond the sparkles' reach marked on the screen in their direction (their picture in the leather ring, turned so its point shows the way to them, their yards), through a camera taken to be behind you; those outside the view at the screen's edge |
| `Art/mark-pointed.blp`, `Art/mark-round.blp` | The leather ring with its point (the far herbs and ore) and round (the minimap's found ones): original art of Sane UI, from the render Saneroki picked (`assets/interface/far-marks/leather-ring.png`), made by `dev/tools/mark-art` (`assets/FarMarks/`) and `dev/tools/art` |
| `Strays.lua` | Other addons' buttons from round the game's minimap held for the satchel, and the addons of the game's addon compartment; given back with the minimap (no frames but a hidden one) |
| `Satchel.lua` | The satchel: its button on the small map and its page: the zone with the times, frame rate, latency, mail and the game's calendar, clock and stopwatch; Sane UI's sound line and quick switches, the addons' buttons, the pins and the game's tracking, in Core's journal |
| `AudioLine.lua` | The satchel's sound line: Core's sound profile in use in a dropdown, a cogwheel with the game's five sounds (checkbox and slider) and the profile's Save, Load, New and Delete |
| `Native.lua` | The game's map kept closed; its keys |
| `QuestLog.lua` | The quest log, a window of its own over the full map; pinned, on the screen while the map is small too, in place of the game's quest tracker; sorted by proximity, level, zone or type |
| `DockWatch.lua` | At a dock or the tram's station: the ways waiting there, when each arrives and leaves (no frames) |
| `TripView.lua` | The travel overlay, high up the screen: the trip you are on (Core's `Data.Trips`), or the wait at a dock; a fine golden line moving smoothly; the way out of a flight or a vehicle, in place of the game's leave button |
| `TopBar.lua` | The bar over the full map: the quest log's button, the views, the map selector, the dungeons, the box Follow me, the pin filter |
| `Window.lua` | Core's window: the top right corner, the full screen, the two cameras, the view buttons |
| `Art/Terrain/*.blp` | The terrain's overview: the game's minimap textures, smaller, the water cut away, made by `dev/tools/terrain-art` from the game's files |
| `Art/Zones/*.blp` | Each zone's outline over its map's box, made by `dev/tools/terrain-art` from the game's files |
| `Art/Sketches/*.blp` | The stitched map: every zone's full map on its continent (or the isle), in the terrain's blocks, made by `dev/tools/terrain-art` |
| `Art/Edge.blp` | A map's box with its paper frame faded off, for Blizzard's world, continent and isle maps |
| `Art/Sea.blp` | The sea's waves: the game's own ocean texture (its first frame), its light alone in white, made by `dev/tools/terrain-art --sea` |
| `Art/SeaShade.blp` | The sea's shade: a tileable soft noise, alpha only, made by `dev/tools/terrain-art --sea` |

Tests: `dev/tests/navigation.lua`.

## History
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
