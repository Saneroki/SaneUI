# Sane UI: Navigation

**Status:** the minimap and the map in one window, with pins (the game's and Core's data), the quest log, the bar over the full map and routes to the map pin on foot, by flight, by boat and zeppelin, by the Deeprun Tram, by lift, through portals, by the hearthstone and by the teleports a character has; the leveling guide comes later · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever, Retail compatible (interface 16001, 120105)

## TL;DR
Sane UI's minimap and world map are one window. Small, in the screen's top right corner, it is the minimap;
move the mouse into that corner and it fills the screen as the map. Both are the same map, drawn and handled
the same way, only larger, as the chat window is the same chat when it fills the screen. Each keeps its own
zoom and place. The map is drawn two ways at every zoom, from close up out to the whole world, both
continents always: *Parchment*, the world drawn by hand, Blizzard's zone maps in full joined into one map that
fades softly from zone to zone; or *Scrying*, the land as the minimap shows it, its water cut away to a calm sea
(the docks, piers and bridges standing on it kept); or *Blended*, the one far out fading into the other close in.
With the module *Atlas* (`SaneUI_Atlas`, `src/Atlas/`) switched on there is a third, *Atlas*: the whole world
painted as one map, three times closer. The game's own minimap lies over it for its live dots; the game's map stays closed, and its keys open ours.
That is WoW: Forever's map; in Retail the map is the game's own map tree, one map at a time, as the game's own map
shows it: a click into a map, a right click out to the one over it, the wheel within it.
On the map stand pins in the game's own looks (quests, flight points, rares, entrances, places, services, the
party), always over the map; the full map has the quest log as a window of its own over it, which its pin keeps
on the screen while the map is small too, and the maps of the dungeons and raids. The plan is in
`Doc/ideas/Navigation.md`.

## How to use
- **The map:** move the mouse all the way into the screen's top right corner; the corner again (move away
  from it first), Esc or the close button on its title bar brings it back. On the way the map grows and zooms
  with the window, from the small view to the full one. The game's map key (M) and quest log key (L), `/sane map`,
  and every other way to the game's map (the quest log button, a click on a quest, a chat link) open it too.
- **The same in both views:**
  - **drag** with the left button: the map moves, and stops following you;
  - **the mouse wheel** zooms around the point under the mouse; while the map follows you it walks the game's
    minimap's zoom steps first (its live dots show then), then goes on out to the whole continent and the
    world, and in past the game's nearest step four times nearer than it;
  - **right click:** one map out (a zone, its continent, the world), as on the game's map;
  - **middle click:** back onto you, following you again, near enough for the game's minimap's dots: on the
    small map at the game's middle zoom step (of its six), on the full map where that step's square takes half the
    map's height (the game's dots show around you there too); in Retail on the map you are on;
  - **the mouse over a continent shown whole** lights up the zone under it in the game's own highlight, over
    the world the continent; **a click** opens it, as on the game's map;
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
- **Following you:** both views follow you at first; after a drag the map comes back to you once the mouse
  has been off it for a while (*Follow again after*). The full map, which the mouse never leaves, stays where you
  leave it, unless the box **Follow me** on its bar is ticked (left of *Pins*, off at first; also the setting
  *Follow me*): then it opens on you and keeps you in its middle as you move; dragged away or moved to a quest, it
  comes back to you as soon as you walk on (standing still, you can look around).
- **In a dungeon, a raid or a battleground,** where the game tells no place of yours on our map, the small window
  shows the game's own minimap alone, with its own ground and dots, as the game's would; the wheel walks its zoom
  steps. Out of it, our map is back.
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
  herbs and ore grow (*Possible herbs*, *Possible ore*), books (an open book): as far as the data holds them; a place
  the game has not confirmed ends its tooltip with *! Unconfirmed Data !* (the marks red; in Sane UI's tooltips a
  quiet grey note at the bottom), and a red ! before the name of each thing in it that is not confirmed (the pin's
  own thing, a quest it offers, each of a gathered pin's), until the game confirms it in play: you or somebody of your guild or group sees
  the NPC at its place, talks to it, opens the mailbox there (Core's watchers), and the note goes. A tooltip says what it is: an NPC by what it is, never by its own name (Saneroki,
  2026-10-23): its title (*Warrior Trainer*, *Bowyer*, *Expert Blacksmith*), else its service (*Innkeeper*), else
  *Quest giver*; only a rare keeps its name; then its quests with their levels, and why a grey one is not for you
  yet. One pin per thing at each place it stands: the game's word hides the data's. Pins that would cover each other
  show as one: in their icon where all have the same (two trainers: the trainer's), else the game's round plus;
  its tooltip what is there, each with its own pin's icon before its name, each name once (two Priest Trainers:
  one line); no tooltip says a word twice. **A double click on any pin**, on the small map and the
  full one, puts the game's map pin where it stands (the golden line leads there; the tooltips do not say so). **A
  click** on a gathered one zooms in; on the full map a quest in your log leads the game's arrow to it and shows
  its text, and a quest giver's quests show in the quest log (below); on any other pin it is a click on the map
  there (a ping). Shift and a click on an entrance, a way or a dock with one destination opens its map. A continent
  whole shows only travel and places; the minimap no
  books or treasures, services only near you. The party and raid in their class colours.
- **The pin filter** (*Pins* on the full map's bar, or the setting *Pins on the map*): a checkmark per kind, each
  with its icon large before its words, in sections under their titles: *Around you* (the route, the minimap's
  dots, the party and raid), *Quests*, *Travel*, *Towns and services*, *Rares and treasures*, *Gathering*; it
  scrolls on a screen lower than it. The quests each a row of their own: *Quests in your log*, *Quest offers*, *Low-level quests* (no
  experience for you any more), *Quests for later* (once you meet what they ask) and *Done quests*. Its
  first two are no pins: *Route to the map pin* (the golden line) and *Minimap dots*: what the game's minimap
  shows around you (players, tracked herbs and ore, quest areas), on the small map and on the full map too, there
  around you at the full map's own scale (shown while it fits inside the map). Both are on at first. At each kind's
  right a slider sets its size on the map, 50 to 200 percent (the route: its line's thickness; the party: its
  marks; the quest areas: their opacity, 10 to 100 percent), kept with the settings.
- **The satchel** (the leather satchel in the small map's lower corner at the screen's edge; the upper one where
  the window stands in the screen's lower half): a click opens a page beside the map, in large cells easy to hit:
  - **AddOns:** the buttons other addons put round the game's minimap, gathered here (with our window as the
    minimap they would otherwise stand on our map only now and then, or nowhere), each its picture round, without
    the golden ring round it, with its addon's name under it, its clicks and tooltip its addon's; and the addons the game's addon compartment lists
    (the game's own button for them is out of sight with its minimap's frame), a click on one as in the game's
    menu. An addon with both shows once. With the game's own minimap chosen they are back round it;
  - **Pins:** every kind of pin the map can show, a click shows it or not (as the pin filter; the sizes stay there);
  - **Tracking:** what the game's own minimap tracks, as its tracking menu lists it (the townsfolk, a hunter's
    beasts, Find Fish...), a click switches it; Find Herbs and Find Minerals are *Found herbs* and *Found ore*.

  Compact: six cells a row, each picture straight on the paper (no pencil slot), the addons' twice as large. A cell that is on shows its
  picture whole with a pencil tick, one that is off faint and grey. The button
  again, its X or Esc closes it, and so does the map filling the screen; the wheel scrolls it on a low screen.
- **Found herbs and ore** (the pin filter's *Found herbs* and *Found ore*): the herbs and ore the game's minimap
  shows around you now, each in the picture of what it gives (Peacebloom's flower, Copper Ore's lump) in a round
  ring of stitched leather (the far herbs and ore below wear it with a point), grey while your skill is too low for it; on our small map and on the game's
  own minimap alike. Each switch is also its finder: *Found herbs* on puts Find Herbs on, off takes it off (or
  Find Minerals in its place, while *Found ore* is on), and so on, without a sound. With both on and both spells
  known they take turns while you move (the setting *Find Herbs and Find Minerals in turn*: every 6 seconds of
  moving at first, 0 never), silently too, and the ones of the finder that is off meanwhile stay on the map until
  you gather one, go far from it or it is five minutes old. As the pins do, each takes the mouse: its tooltip
  names it, a click pings it to your group and a double click puts the game's map pin where it is, so the game's
  arrow leads there.
- **Indoor maps:** inside a building or a cave, its indoor map lies over the map at the floor you stand on (the
  game's own indoor pictures, without their black). Only inside buildings and caves, never on a street: Stormwind's
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
  shades it on its map.
- **The quest log**, a window over the full map (*Quest Log* on the bar puts it in or out; drag its title bar to
  move it, dock it at a screen edge, size it by its corner): the pin on its title bar keeps it on the screen while
  the map is small too, there without a background, a border or a line under its title, only the list over the
  game; its close button takes it out of both. Your quests by zone with
  their level and state, each with its mark at the left as its pin on the map has it (the yellow question mark),
  their objectives under them. No scroll bar: the mouse wheel scrolls it, and while the mouse is on a list longer
  than its room the game's thin scroll bar shows at the side the window stands at (docked at the left edge: its
  left). A click leads the arrow to the quest and moves the map to its objective (its question mark on the map, or
  the middle of the area where its foes are), at the zoom it has; a double click puts the game's map pin there too.
  Shift and a click tracks it. The
  right button: *Quest Details* (its objectives and story below the list, with *Track*, *Share* and *Abandon*; its
  X closes it), *Show Map* (the map at its objective), *Track*, *Share* and *Abandon*. A click on a quest's pin on
  the map shows its text too. A quest giver's pin clicked: its quests on top, under *Not in your log*, greyed out,
  each with its giver's mark (the yellow exclamation mark, grey for a quest too low, the red question mark for one
  for later) and a red X that takes it out again; below what the data knows of it: why it is not for you yet,
  its level, who gives and takes it, its objectives and rewards. A click on one moves the map to its giver, a double
  click puts the map pin there.
  They stay until the next `/reload`.
- **The map selector** on the bar: the world, a continent or Zephras Isle, then a zone of it.
- **Dungeons** on the bar: every dungeon and raid the game has a map of, and those Core's data has a map of
  (26 of Forever's: the classic dungeons and raids, each floor in the game's own map art), A to Z; chosen, its map
  over the map, and beside it its floors. Where the data knows them, each boss as its own 3D model where it stands
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
  no continent between). *Parchment* shows the isle's own map and its stitched map, *Scrying* and *Atlas* its
  terrain, the open sky around it cut away as the sea is, and routes there walk around what cannot be walked, as on
  the continents. The painted map does not cover the isle yet: *Atlas* shows the terrain there.
- **Routes:** put the game's map pin (a double click, or Ctrl and a click) and a golden line leads you there from where you stand,
  pulsing towards it: around what cannot be walked (mountains, walls, deep water is swum), through gates and doors,
  into and out of caves, buildings and the cities in the mountains, on the floor you are on (a cave under a hill, a
  city in a mountain, a building's storeys), and by the flights your character has found where that is quicker:
  only those, as the game tells them at a flight master (it tells them once you have opened one, each session;
  until your first, the ones found before; a flight over many flight points is one, taking off once; with the Legacy
  perk *Frequent Flier* the flights count 20 % faster; the line white along them). The
  line always begins at your arrow: as you go, what lies behind you is gone, a short line runs from you to it, and
  leave it and it is planned again. A pin on another continent or on Zephras Isle is reached by boat or zeppelin,
  over as many seas as it takes (by way of the other continent, or the hearthstone home first, where that is
  quickest), your side's or both sides' (not the other side's harbours and zeppelin towers), the line light blue
  from pier to pier; between Stormwind and Ironforge the Deeprun Tram is taken where it is
  quicker, the line light blue from one city's entrance to it to the other's; and the hearthstone is taken where it is
  quickest (the map learns its place where you bind it, or the first time you use it; a shaman's Astral Recall
  brings you there too). So are the teleports your character has, the line pale blue to where each brings you, then
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
  data holds their rooms. A pin where nobody can walk (a tower, a plateau) gets its line as near
  as one walks, then straight to it. The lifts and portals are on the map too (not yet confirmed by the game). On a flight
  the line shows the flight's way on from where you are, pin or none, and from where it lands on to the pin; aboard
  a ship it waits until you have landed, and a pin set aboard is planned from the pier it comes to. The game tells
  no ship's timetable: its sailing comes from its way at the game's
  transports' speed, and once you have ridden a ship on your realm the map knows when it really sails there and
  counts the wait for the next one (until then half its time once round). *Route to the map pin* in the pin
  filter switches it off.
- **Ship times at a dock:** at the dock of a boat or a zeppelin, or a station of the Deeprun Tram, the travel
  overlay (below) shows the next to come there: where it goes, the golden line filling as it nears, when it
  arrives (*Board now* while it is in) and when it leaves; the others that stop there in a line each below. A ship
  or the tram you have not ridden on this realm yet shows how often it comes; one ride teaches its times (kept on
  this computer for the realm, half a day). *Ship times at a dock* in the settings switches it off.
- **Your trip on screen:** on a flight, a boat, a zeppelin or the Deeprun Tram, the travel overlay two thirds up
  the screen: where it began and where it goes at the ends of a fine golden line (the map route's art, its glint
  pulsing along) that fills smoothly as you go, the vehicle's icon riding at its tip, a flight point's mark at each
  stop on it (dim once passed); below it the time to the end, the next stop and the time to it, and the zone. On a flight with a stop before its
  end, the game's own *Request Stop* button: you land at the next flight point, and the trip ends there. A flight's
  time comes from your own pace on it, before that from your character's last flights; a ship's from its
  timetable; the tram's from the game's own. A `/reload` in the air finds the flight again. *Your trip on screen*
  in the settings switches it off.
- **Map view** (the buttons on the full map's bar, or the setting on the page *Navigation*): *Parchment*,
  *Blended* or *Scrying* (the default), and *Atlas* while that module is switched on in the addon list; for both
  views and at every zoom (in the code `sketches`, `blend`, `terrain`, `atlas`). *Blended* is Parchment out to a
  zone's level and Scrying close in, the maps fading out over the land in between. A view not offered (the module
  switched off or failed, or *Overlay*, which is gone) falls back to Scrying.
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
  as ever, not at the small isle's.
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
  close; under it the canvas' sea colour.
- **Blended** (`Canvas.lua`): the art of Parchment over the terrain of Scrying, its alpha by the view's height in
  yards (`Canvas.Blend`: whole from `Canvas.BLEND[1]` up, gone at `Canvas.BLEND[2]` and below, by the zoom's
  factor between), the sea's colour between Parchment's and Scrying's alike. Only a layer that shows is drawn:
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
- **Painted** (`Painted.lua`), the view *Atlas*: the terrain as Scrying draws it, and over it the painted map
  of the module Atlas (`SaneUI_Atlas`, `src/Atlas/`; its art made into `assets/optimized/Atlas/` and put in by
  `dev/build`). At login it is looked for in the addon list without being loaded (there, switched on for this
  character, loadable: `C_AddOns.GetAddOnInfo`, `GetAddOnEnableState`); only then is the view offered, its
  button after Scrying's and its choice in the setting. The first time the view is drawn it is loaded
  (`C_AddOns.LoadAddOn`, guarded) and answers as `SaneUI.Atlas`; if it cannot be loaded, or stands down later,
  the map shows Scrying at once, and on the next frame its button and choice go and the setting is Scrying
  (`Offer` in `Navigation.lua`), the problem kept and told once. Its blocks (512 pixels, level 0 at 2048 pixels a
  tile, each level up half the detail) are drawn at the coarsest level whose art still has as many pixels a
  yard as the screen shows (each continent at its own scale on the screen), so about the same number of blocks
  at every zoom, and the next coarser level under them, so a block still loading leaves no hole; where the index
  has none (sea, not painted yet) the terrain shows. At most `Painted.CAP` (400) blocks of a level a continent:
  past it a coarser level (the window on its way). The nearest zoom is three times the others'
  (`Camera.Near`: 6 units a yard, else 2).
- **What stands on the map is always over it:** the canvas sets every layer's frame level from its own at each
  layout (`Canvas.LEVELS`): the map's own layers (terrain, Atlas, art, the highlight) up to `Canvas.MAP`, then the
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
  (Core's set *Travel*, its `docks`) its own pin, its tooltip where it goes from there (the game's names of each
  other dock's area and zone, `C_Map.GetAreaInfo`, `C_Map.GetMapInfo`), a click opening the map where it is the
  only one, not marked unconfirmed (the game's own ways). A pin at each of a thing's points (a herb's every spawn:
  its key the thing's and the point's, its `thing` the thing's); the game's pin hides every one of the data's for
  the same thing (a vignette's GUID names its creature). Kept per map until the game says it changed (the message
  `LIVE`; the arrow's quest: the game's alone), Core's in parts: the NPCs' read again when the log or the level
  changed, the objects', places' and ways' when Core's places change; at a zone's level every zone in view (on
  Zephras Isle the isle itself), further out the continent and its zones for travel and places only (only the
  places' and ways' part read). A pin's place is in its map's plane (`Coords.PlaneOf`: a continent's,
  or the isle's). `Pins.Gather`: pins nearer than `Pins.GATHER` units on the screen are one marker, a quest never
  (its grid's cells by number). Herbs and ore, a zone's thousands of places: of each kind at most one in a cell of
  that grid is sorted and gathered, the others there ride with it (its `with`), counted and named in its marker.
  The filter is the multi-choice setting `pins`.
- **PinView** (`PinView.lua`): a pooled button per pin, kept by its key while it stays in view, at a fixed size, in
  the game's looks (its quest disc and marks, `UI-QuestPoi-*`, `Quest-In-Progress-Icon-*`); a higher kind over a
  lower one by its frame level (`PinView.TIERS`: kinds that share one are gathered where they would cover each
  other), all under the marks; a kept button's look made again only when its pin's changed, its shown state told the
  game only when it changed. A press on a pin is the map's (a drag moves the map,
  `Canvas.Press`/`Release`); a plain click is the pin's. Tooltips with a quest's objectives as the game tells them.
- **Areas** (`Areas.lua`): the game's quest area frame (`QuestPOIFrame`, which the engine draws a quest's area
  into) over each zone in view, as large as its box, for the quest under the mouse in the log or the one the
  arrow leads to. Placed at once, drawn on the next frame: the engine shades into the frame's rectangle as it
  stands when asked, and a frame just placed or sized has its new one only once the game has laid it out (drawn
  at once, the area stood where the zoom before had put it).
- **Dungeons** (`Dungeons.lua`): the maps of kind *Dungeon* under the world map (`C_Map.GetMapChildrenInfo`), one
  entry per map group (`C_Map.GetMapGroupMembersInfo`: its floors, lowest first), drawn in a view of their own over
  the canvas, under the bar: the floor's art (`Art.Of`) fitted whole in a frame that is scaled to zoom (up to
  `Dungeons.NEAR` times) and moved by a drag (its step runs only while a drag goes on); no player's arrow and no
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
  (`Route.PULSE`), so the pieces pulse as one line; the head meets the line on the curve.
- **QuestLog** (`QuestLog.lua`): a window of Core's of its own (title bar, docks, its grip seen while the mouse is
  on it; place and size in `store.questLogPlace`), over the full map in the layer `DIALOG` with its dark background,
  and pinned (`store.questLogPinned`, its title bar's pin) on the screen alone in the layer `LOW` without one (no
  skin, `barLine = false`); a `WowScrollBoxList` of rows read from `C_QuestLog` (the game's headers, folded
  as the game keeps them: a folded one's quests, which the game still lists, left out; quests with level, state,
  watched; objectives), built again on `QUEST_LOG_UPDATE` once
  a frame and only while it shows; its `MinimalScrollBar` hidden but while the mouse is on the window and the list
  has more than its room (`HasScrollableExtent`), then at the docked side (`Side`: the window's dock zone, else the
  screen's half its middle is in); a click: the quest super-tracked and the map at `Where` (the game's quest on a
  map, `GetQuestsOnMap`; a preview's giver) through `Canvas.LookAt`, its zoom kept; the button's `OnDoubleClick`
  (the game sends the second click there, after the first's `OnClick`): the map pin there through `PinView.Drop`;
  a quest's text from `GetQuestLogQuestText`
  with its buttons, shown only once asked for (`open`: the menu's *Quest Details*, a click on its pin); abandon
  after the game's own question (`GENERIC_CONFIRMATION`); never the quest panels of the game's map (their
  details window is opened by the game's panel manager, which our call would leave tainted).
- **TopBar** (`TopBar.lua`): over the full map's top: the quest log's button, the views, the map selector (the
  game's dropdowns, radio entries of the world, its continents and Zephras Isle, the zones of the one shown A to
  Z, the isle itself on the isle), the dungeons and the floors of the one shown, the box *Follow me* (the game's
  `UICheckButtonTemplate`, its words between it and the pin filter; the setting `followMap`) and the pin filter
  (checkboxes); it says what the map shows after each layout. The view buttons are `TopBar.VIEW_WIDTH` wide and the
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
  protected, is held: its parent, points, scale, strata and level kept, the clicks the cluster's hiding took from
  it given back (`Hybrid.Release`), then out of sight until the satchel lays it in a cell (`Strays.Place`, scaled to
  the cell's picture), unseen there (alpha 0) over the round picture the satchel draws of it: its own largest
  texture in the `ARTWORK` layer, else its normal texture (`Strays.Picture`), cut inside its frame where it shows its
  whole file (`Satchel.TRIM`) and cut round (`Satchel.ROUND`); the ring and background the common buttons have lie in
  other layers and stay out. Hooks after its `SetPoint` and `SetAlpha` put it back whenever its addon places it
  again or shows it (a drag, its own update, a fade). Looked for at the login, 2 and 10 seconds after, a second after each addon that loads, and as the
  satchel opens. Given back exactly when the game's minimap is the game's again (`Hybrid.Update` tells it) or the
  module stands down. Its name in the satchel is its addon's title in the addon list (no colours). The game's addon
  compartment (`AddonCompartmentFrame.registeredAddons`, both games): each addon a cell of its own, its click
  `entry.func(nil, { buttonName })` and the mouse's coming and going its own, as the game's menu calls them, behind
  `pcall` (a failure there is that addon's: its stack would hold our file, which Core reads as ours). One of the
  same addon as a held button (its title or folder, letters and digits alone) is left out.
- **The satchel** (`Satchel.lua`): its button on the canvas (level `Canvas.LEVELS.satchel`, over the marks), in the
  corner `Satchel.Place` picks from where the window stands, shown only while the window stands small and is the
  minimap. The page is a frame of its own (strata `DIALOG`) in Core's journal (`Core.Journal.Dress`: paper, leather
  top, its X), beside the window toward the screen's middle, a scroll frame in it no higher than
  `Satchel.ROOM` of the screen. Three sections, each a title over a pencil rule and a grid of `Satchel.COLUMNS`
  cells: *AddOns* (`Strays.List`, A to Z; a note while it holds nothing), *Pins* (`ns.KINDS` offered here, in the
  pin filter's order; a click `ns.SwitchPin`, the pin filter's own), *Tracking* (`C_Minimap.GetTrackingInfo`, the
  entries the game's tracking menu lists: a spell's, or one of its optional filters, Forever's
  `MinimapConstants.OPTIONAL_FILTERS`, else Blizzard's list of them by `Enum.MinimapTrackingFilter` names; not the
  finders `Nodes.FINDERS`). A tracking entry is switched as the game's menu switches it
  (`MinimapUtil.SetTrackingFilterByFilterIndex`, else `C_Minimap.SetTracking`) and shown so at once until the game
  agrees (a spell's takes its cast); `MINIMAP_UPDATE_TRACKING` and a change of the setting *Pins on the map* fill it
  anew while it is open.
- **Following on the full map:** the tracker follows again where `Again` says: the small view once the mouse has
  been off it for *Follow again after*; the full map only with *Follow me* ticked, as soon as the player moved since
  the last look and no button is held (a quest moved to counts as a drag). Ticked, `Canvas.Center` puts the full camera on the player whenever the window fills the screen (but at
  a map the game was asked for, `Window.OpenTo`) and when the box is ticked; unticked, it no longer follows.
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
  flight points, the docks, the tram's entrances, the lifts' and portals' ends and the hearthstone's place on every
  plane (the continents and
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
  walking data only one with a floor at both ends, within `Planner.ARRIVE` yards at their height), the hearthstone
  from the player (its cooldown, or Astral Recall's, `Planner.RECALL`, whichever is sooner), the teleports this
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
  learnt where it is bound (`HEARTHSTONE_BOUND`) or where it (or Astral Recall) brought the character, kept per character; the hearthstone counts while it is in the bags and bound there (`GetBindLocation`), its
  cooldown as a wait. Where a teleport brings one is the set's: the original game's (batch 14, unverified) or where
  one brought a character, learnt by Core (`src/Core/Data/Teleports.lua`, Core's learned data); the plan is made
  again when Core learnt one (*Travel*'s stamp). Without walking data, straight lines. On a flight (Core's `Data.Trips`) its way on is the
  line's first leg, drawn anew from the player every `Planner.AGAIN` seconds, the plan from where it lands after
  it; without a pin that leg alone.
- **Marks** (`Marks.lua`): the player's arrow (Blizzard's world map arrow, turned to your facing), the game's map
  pin, at a fixed size, and the party and raid (the game's party blip in the class colour, four times a second).
- **Indoors** (`Indoors.lua`): inside a building or a cave (the game's `IsIndoors`) the indoor map of the building
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
  maps are to come). Its
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
    minimap's steps the game's minimap keeps its own ground there, the land as it lies (`Hybrid.Place`); past
    them, and on the full map, Parchment with its dots;
  - the game's minimap given back round where the game's code sets no mask (Retail: `Hybrid.ROUND`, the engine's
    own; Forever's `UpdateMinimapConfig` sets it there);
  - the continents beside the world map, under the map over it (Retail's Outland, Draenor, the Shadowlands:
    `Coords.Top`, `Coords.Elsewhere`): in the map selector after the world's, each a map of the tree (above); the
    dungeons listed from the top of the map tree;
  - the pin kinds only Core's data has (offers, low, later, done, services, possible herbs and ore, books: their
    `data` in `ns.KINDS`) are not in the pin filter nor the setting's list (`ns.KindOffered`); the game's own
    (the log, flight points, places, rares, treasures, entrances, links, the group, quest areas) show;
  - herbs and ore: Retail's tracking holds both finders at once (`Nodes.TOGETHER`): each on while its kind is,
    no turns (the switch is not there); the found ones need the minimap's answers Retail does not give
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
| `Painted.lua` | The view Atlas: the module SaneUI_Atlas found at login, loaded when first drawn, its blocks at the level the zoom asks for |
| `Pins.lua` | The pins as plain records: the game's and Core's data per map, one per thing, filtered, gathered. No frames |
| `Walk.lua` | Core's walking data: a tile's block unpacked, its rectangles, regions and openings; the floor a walker stands on, followed or chosen. No frames |
| `Gates.lua` | The walking data's coarse layer: each tile's gates into the next tiles, what the walks between two of them cost, the parts of a tile. No frames |
| `Search.lua` | A walk between two points over the walking data, from the floor the start stands on to a floor at the end: priced across the tiles by their gates, then drawn along that way. No frames |
| `Lifts.lua` | The lifts of Core's set *Travel* on the walking data: each end at its landing, the levels they join (stacked or side by side), where a place stands among them. No frames |
| `Planner.lua` | The way to the map pin over every plane: on foot, by the flights this character knows, by boat and zeppelin, by the tram, by lift, through portals, by the hearthstone, by the teleports it has; where along it the player is. No frames |
| `Areas.lua` | A quest's areas, as the game shades them (`QuestPOIFrame`), over each zone in view |
| `Dungeons.lua` | The maps of the dungeons and raids, chosen in the bar: over the map in its place, by floor, zoomed and dragged |
| `Route.xml` | The glint's pulse along the golden line: an animation template (the game makes that kind only from XML) |
| `Route.lua` | The golden line of a way, from the player on, the parts in view: walks and lifts gold, flights white, ships and the tram light blue, portals violet, the hearthstone and the teleports pale blue |
| `PinView.lua` | The pins drawn: a pooled button each, in the game's looks, tooltips, clicks; a rare's 3D model beside its tooltip with Alt |
| `Marks.lua` | The player's arrow, the map pin, the party, the pings |
| `Nodes.lua` | Herbs and ore: what one is by its name (Core's *Objects*, *Drops*), its picture, your skill for it; the finders switched by the pin filter and in turn, silently. No frames |
| `Indoors.lua` | The indoor map of the building you are in: the game's indoor pictures without their black, at your floor |
| `Art/Indoors/*.blp` | The indoor pictures, one per part of a building, made by `dev/tools/indoor-art` |
| `Hybrid.lua` | The game's minimap over ours: taken, placed, given back |
| `Found.lua` | The herbs and ore the game's minimap shows: found by asking its tooltip at points of it, kept in yards, drawn over it in their pictures, each a button (tooltip; a click: a ping there, a double click: the map pin there) |
| `Sparkles.lua` | Gold sparkles on the plate of the herb or ore the interact key would gather; the game's interact key settings set and put back |
| `Glints.lua` | Far herbs and ore: the found ones beyond the sparkles' reach marked on the screen in their direction (their picture in the leather ring, turned so its point shows the way to them, their yards), through a camera taken to be behind you; those outside the view at the screen's edge |
| `Art/mark-pointed.blp`, `Art/mark-round.blp` | The leather ring with its point (the far herbs and ore) and round (the minimap's found ones): original art of Sane UI, from the render Saneroki picked (`assets/interface/far-marks/leather-ring.png`), made by `dev/tools/mark-art` (`assets/FarMarks/`) and `dev/tools/art` |
| `Strays.lua` | Other addons' buttons from round the game's minimap held for the satchel, and the addons of the game's addon compartment; given back with the minimap (no frames but a hidden one) |
| `Satchel.lua` | The satchel: its button on the small map and its page of the addons' buttons, the pins and the game's tracking, in Core's journal |
| `Native.lua` | The game's map kept closed; its keys |
| `QuestLog.lua` | The quest log, a window of its own over the full map; pinned, on the screen while the map is small too |
| `DockWatch.lua` | At a dock or the tram's station: the ways waiting there, when each arrives and leaves (no frames) |
| `TripView.lua` | The travel overlay, two thirds up the screen: the trip you are on (Core's `Data.Trips`), or the wait at a dock; a fine golden line moving smoothly, *Request Stop* on a flight |
| `TopBar.lua` | The bar over the full map: the quest log's button, the views, the map selector, the dungeons, the box Follow me, the pin filter |
| `Window.lua` | Core's window: the top right corner, the full screen, the two cameras, the view buttons |
| `Art/Terrain/*.blp` | The terrain's overview: the game's minimap textures, smaller, the water cut away, made by `dev/tools/terrain-art` from the game's files |
| `Art/Zones/*.blp` | Each zone's outline over its map's box, made by `dev/tools/terrain-art` from the game's files |
| `Art/Sketches/*.blp` | The stitched map: every zone's full map on its continent (or the isle), in the terrain's blocks, made by `dev/tools/terrain-art` |
| `Art/Edge.blp` | A map's box with its paper frame faded off, for Blizzard's world, continent and isle maps |

Tests: `dev/tests/navigation.lua`.

## History
- **2026-10-25, the satchel and the middle click:** as Saneroki asked, a middle click brings the map back onto you,
  following, near enough for the game's minimap's dots (`Canvas.Home`, `Hybrid.HOME`); and one button on the small
  map, the satchel, opens a page of the buttons other addons put round the minimap, gathered there
  (`Strays.lua`), with the addons of the game's addon compartment, the kinds of pin and what the game's minimap
  tracks, in large cells that switch at a click (`Satchel.lua`).
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
- **2026-10-21, the travel overlay:** at Saneroki's ask the trip view stands two thirds up the screen, a fine
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
