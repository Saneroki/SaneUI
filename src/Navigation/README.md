# Sane UI: Navigation

**Status:** the minimap and the map in one window, with pins (the game's and Core's data), the quest log, the bar over the full map and routes to the map pin on foot, by flight, by boat and zeppelin and by the hearthstone; the leveling guide comes later · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever (interface 16001)

## TL;DR
Sane UI's minimap and world map are one window. Small, in the screen's top right corner, it is the minimap;
move the mouse into that corner and it fills the screen as the map. Both are the same map, drawn and handled
the same way, only larger, as the chat window is the same chat when it fills the screen. Each keeps its own
zoom and place. The map is drawn two ways at every zoom, from close up out to the whole world, both
continents always: *Parchment*, the world drawn by hand, Blizzard's zone maps in full joined into one map that
fades softly from zone to zone; or *Scrying*, the land as the minimap shows it, its water cut away to a calm sea.
With the module *Atlas* (`SaneUI_Atlas`, `src/Atlas/`) switched on there is a third, *Atlas*: the whole world
painted as one map, three times closer. The game's own minimap lies over it for its live dots; the game's map stays closed, and its keys open ours.
On the map stand pins in the game's own looks (quests, flight points, rares, entrances, places, services, the
party), always over the map, and the full map has the quest log at its left. The plan is in
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
    world;
  - **right click:** one map out (a zone, its continent, the world), as on the game's map;
  - **the mouse over a continent shown whole** lights up the zone under it in the game's own highlight, over
    the world the continent; **a click** opens it, as on the game's map;
  - **Ctrl and a click:** the game's map pin there; a click on the pin makes the game's arrow on the screen
    lead to it, Ctrl and a click takes it away, Shift and a click writes it into the chat;
  - **a click** on the game's minimap (while it shows) pings, as there.
- **Following you:** both views follow you at first; after a drag the map comes back to you once the mouse
  has been off it for a while (*Follow again after*).
- **Pins:** the game's own marks where it tells them (your quests on their discs, ready to turn in, the quest the
  arrow leads to on its brown disc; flight points of your side; rares and treasures nearby; the game's points and
  ways into other maps), and what Core's data knows (quest givers with a quest you can take, services, entrances,
  the docks of the boats and zeppelins with where they go, herbs, ore, books: as far as the data holds them; a
  place the game has not confirmed says so). One pin per thing: the game's word hides the data's. Pins that would
  cover each other show as one disc with their number: a click zooms in. A click on a quest's pin leads the game's
  arrow to it; on an entrance, a way or a dock with one destination, its map opens. A continent whole shows only
  travel and places; the minimap no books or treasures, services only near you. The party and raid in their class
  colours.
- **The pin filter** (*Pins* on the full map's bar, or the setting *Pins on the map*): a checkmark per kind.
- **Quest areas:** the quest the arrow leads to, or the one under the mouse in the quest log, shaded as the game
  shades it on its map.
- **The quest log** at the full map's left (*Quest Log* on the bar puts it in or out): your quests by zone with
  their level and state, their objectives under them. A click: the arrow leads to it, the map shows where it is,
  its text below with *Track*, *Share* and *Abandon*. Shift and a click tracks it; the right button opens a menu.
- **The map selector** on the bar: the world, a continent or Zephras Isle, then a zone of it.
- **Zephras Isle** is on the map as a continent is, a zone of its own: the map follows you there, its pins and the
  map pin stand on it, a click on it at the world opens it, and a right click on it goes out to the world (there is
  no continent between). *Parchment* shows the isle's own map; *Scrying* and *Atlas* show only the sea there, as
  the terrain's data and the painted map cover the two continents.
- **Routes:** put the game's map pin (Ctrl and a click) and a golden line leads you there, pulsing towards it,
  around what cannot be walked (mountains, walls, deep water is swum), through gates and doors, and by the flights
  your character knows where that is quicker (visit a flight master once for the map to know yours). A pin on
  the other continent or on Zephras Isle is reached by boat or zeppelin, the line red from pier to pier, and the
  hearthstone is taken where it is quickest (the map learns its place where you bind it, or the first time you use
  it). Leave the line and it is planned again; after a flight it goes on from where you landed; aboard a ship it
  waits until you have landed. The ships' timetables are not in the game's data: how long one waits for a ship and
  how long it sails are guessed from its way. The setting *Route to the map pin* switches it off.
- **Map view** (the buttons on the full map's bar, or the setting on the page *Navigation*): *Parchment* or
  *Scrying* (the default), and *Atlas* while that module is switched on in the addon list; for both views and at
  every zoom (in the code `sketches`, `terrain`, `atlas`). A view not offered (the module switched off or
  failed, or *Overlay*, which is gone) falls back to Scrying.
- **The game's own windows:** the full map's dropdown *Classic windows* offers the game's minimap and map, each
  kept once chosen (ticked; chosen again, ours comes back), as the switches *Show the game's minimap* and *Show
  the game's map* on the page. With the game's minimap our small window rests out of sight; with the game's map
  its keys open the game's. Either way the mouse pushed into the top right corner still fills the screen with
  our map. The game's key to show or hide the minimap (in its key bindings) shows or hides our window.
- **Move and size it** in Edit Mode like every Sane UI window; the section *Expand window* on the page: whether
  the corner fills the screen, the animation, the background.
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
  holder has moved past a margin, or another zone is in the middle. The layers' textures come from pools by
  key, so what stays in view is not loaded again. The zoom changes at once, as on the game's map. Nothing runs
  at rest but the tracker: every frame while the view follows you (two questions to the game and one
  `SetPoint`), else a few times a second, and, while the mouse is over the map, a look at what is under it
  when it moved (the game's highlight, `C_Map.GetMapHighlightInfoAtPosition`). On the window's way to the full
  screen and back the map goes with it (Core's option `moving`): laid out once at the start over what both
  views show, at the wider one's zoom, then only scaled and moved on each step from the view it leaves to the
  one it comes to (the middle straight, the zoom by equal factors). The layers' frame levels are set from the
  canvas' at every layout.
- **Terrain** (`Terrain.lua`): the game's own minimap textures, one per tile of a continent's 64 x 64 grid
  (Core's data, the set *Tiles* in the pack *World*, of the two continents; Zephras Isle has none yet), up to 400
  at once; under them, and alone further out,
  the module's overview of the same tiles, 64 texels a tile, 8 x 8 tiles a texture (`Art/Terrain/`). At the
  world, every continent's overview where the world map puts it, and at every zoom wherever it is in view. The
  water is cut away: the overview's alpha is
  the land (where the ground lies above the water's surface, read from the game's terrain files by
  `dev/tools/terrain-art`), and the same file is the mask of the game's tiles of its block (`Canvas.Masks`), so
  the coast is cut alike at every zoom; under it the canvas' sea colour.
- **Art** (`Art.lua`), the view *Parchment*: Blizzard's world and continent maps (`C_Map.GetMapArtLayers`,
  `GetMapArtLayerTextures`) over their boxes, their paper frames faded off (`Art/Edge.blp`); over them the
  stitched map of every continent in view (`Art/Sketches/`, in the terrain's blocks: every zone's full map cut
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
- **Pins** (`Pins.lua`, no frames): the pin records of each map in view, from what the game tells (`Live.lua`: its
  quests on the map and the next way of the quest the arrow leads to, flight points of the player's side, its
  vignettes, area points, map links, dungeon entrances where it has them) and from Core's data
  (`Data.Map():On`, `Core/Data/Map.lua`): an NPC with quests this character can take (`Pins.Offered`: not done,
  not in the log, level, side, race, class, the quests before) is a quest giver, else a rare, else its service in
  the game's town tracking atlas; objects, places and ways in the game's atlases; a boat's or zeppelin's dock
  (Core's set *Travel*, its `docks`) its own pin, its tooltip where it goes from there (the game's names of each
  other dock's area and zone, `C_Map.GetAreaInfo`, `C_Map.GetMapInfo`), a click opening the map where it is the
  only one, not marked unconfirmed (the game's own ways). One pin per key: the game's hides the data's (a
  vignette's GUID names its creature). Kept per map until the game says it changed (the message `LIVE`), or Core's
  places change; at a zone's level every zone in view (on Zephras Isle the isle itself), further out the continent
  and its zones for travel and places only. A pin's place is in its map's plane (`Coords.PlaneOf`: a continent's,
  or the isle's). `Pins.Gather`: pins nearer than `Pins.GATHER` units on the screen are one marker, a quest never.
  The filter is the multi-choice setting `pins`.
- **PinView** (`PinView.lua`): a pooled button per pin, kept by its key while it stays in view, at a fixed size, in
  the game's looks (its quest disc and marks, `UI-QuestPoi-*`, `Quest-In-Progress-Icon-*`); a higher kind over a
  lower one by its frame level, all under the marks. A press on a pin is the map's (a drag moves the map,
  `Canvas.Press`/`Release`); a plain click is the pin's. Tooltips with a quest's objectives as the game tells them.
- **Areas** (`Areas.lua`): the game's quest area frame (`QuestPOIFrame`, which the engine draws a quest's area
  into) over each zone in view, as large as its box, for the quest under the mouse in the log or the one the
  arrow leads to.
- **Route** (`Route.lua`): a way the planner gives, drawn with the game's `Line` widgets from a pool, only the parts
  in view: a dark edge, the game's dependency bar art tinted gold, its glint moved along by a
  `TextureCoordTranslation` animation (no code of ours each frame); walks gold, flights pale, ships red.
- **QuestLog** (`QuestLog.lua`): a `WowScrollBoxList` of rows read from `C_QuestLog` (the game's headers, folded
  as the game keeps them; quests with level, state, watched; objectives), built again on `QUEST_LOG_UPDATE` once
  a frame and only while it shows; the chosen quest's text from `GetQuestLogQuestText` with its buttons; abandon
  after the game's own question (`GENERIC_CONFIRMATION`); never the quest panels of the game's map.
- **TopBar** (`TopBar.lua`): over the full map's top: the quest log's button, the views, the map selector (the
  game's dropdowns, radio entries of the world, its continents and Zephras Isle, the zones of the one shown A to
  Z, the isle itself on the isle) and the pin filter
  (checkboxes); it says what the map shows after each layout.
- **Walk** (`Walk.lua`, no frames): Core's set *Walking* (pack *Data: Routes*, asked for at the first route),
  made by `dev/tools/walk-data` from the game's terrain, buildings and water: per terrain tile a block (base64,
  deflate, CBOR, read by the game's `C_EncodingUtil`) of surfaces and rectangles of floors, 2.08 yards a sample,
  each with its height, kind (land, water) and region, and the openings into its neighbours. Unpacked when first
  needed, the last `Walk.KEEP` kept; the openings of two rectangles of one surface that touch are worked out from
  the rectangles, written ones once on their tile get their other way. `Under`, `Nearest`, `Openings`, `Portal`.
- **Search** (`Search.lua`, no frames): a walk between two points: A* over the rectangles through their openings
  (from where a rectangle was entered to the nearest point of the next opening, swimming twice the cost), ends
  in different regions refused at once, then the line pulled straight through the openings (a funnel, each
  opening drawn in from its ends). `Search.Start` runs it as a job of Core's scheduler.
- **Planner** (`Planner.lua`, no frames): the way to the map pin, a graph over the player, the pin, the known
  flight points, the docks and the hearthstone's place on both their planes (a continent, or Zephras Isle; the
  canvas' tracker hands it the player's place): walks within one region of the
  walking data (guessed), the flights of Core's set *Travel* the player's side may take, the boats and zeppelins of
  *Travel* from dock to dock (both from the game's tables, by `dev/tools/travel-data`), the hearthstone from the
  player; the quickest chosen (Dijkstra), the walks then searched and the journey chosen once more when one is
  much longer than guessed. A ship (`Planner.Ship`): its way once round is its sailing at `Planner.SAIL` yards a
  second, its stays at the docks (the game's) and `Planner.LEAP` seconds a leap, or its time once round when
  *Travel* has it learnt (`wait`); one waits half of that for it, then sails to the dock (the stays between
  included). One boards and leaves at the pier, the land nearest where it stops. Planned again when the pin
  changes, after a landing, when the player is 40 yards off the line (150 off a ship's way), and when the data
  arrives; aboard a ship a new pin is planned from where it lands. The known flight points are read at the flight
  master, the hearthstone's place where it is bound (`HEARTHSTONE_BOUND`) or where it brought the character, both
  kept per character; the hearthstone counts while it is in the bags and bound there (`GetBindLocation`), its
  cooldown as a wait. Without walking data (and on Zephras Isle, which it does not cover), straight lines.
- **Marks** (`Marks.lua`): the player's arrow (Blizzard's world map arrow, turned to your facing), the game's map
  pin, at a fixed size, and the party and raid (the game's party blip in the class colour, four times a second).
- **The game's minimap** (`Hybrid.lua`): over our map while the view follows you at one of its zoom steps,
  square, as large as the view's longer side so it covers all of it, cut to the window's shape by a mask (the game
  draws its dots inside its mask only, whatever cuts its parent): a band through the square as tall (or wide) as
  the window's shorter side, rounded down to a 32nd (`Hybrid.Mask`, `Art/Masks/`, made by
  `dev/tools/minimap-masks`), so its dots cover the whole window and nothing past it; above the map's
  layers and under our marks (its layer and level set again each time it is placed), its ground off (as Blizzard's hybrid minimap does), so only its
  live dots and their tooltips show; indoors it draws its own ground, which our terrain does not have. Its
  left and right clicks go through to our map; its border, zoom buttons and the rest of the game's minimap
  cluster are out of sight and take no clicks (Edit Mode's selection keeps its). Each step's radius is read
  from the game. Taken out of combat, every part kept first and given back exactly.
- **The game's map** (`Native.lua`): the keys bound to the game's map, quest log and minimap click a button
  of ours (override bindings, out of combat, again when the bindings change). Every other way to the game's
  map shows `WorldMapFrame`: a hook after its `OnShow` hides it at once and closes it on the next frame with
  the game's `HideUIPanel`, and ours opens at the map it was asked for. In a fight the game refuses an addon
  that closes a panel, so there the game's map stays open as the game's.
- **What the game tells** (`Live.lua`): the player, the map pin, the group, the quests, the flight points,
  rares and chests nearby, the game's own points and the explored parts of a map, each read when the game says
  it changed (one message `LIVE` a frame). The player and the pin are drawn now; the rest is for the pins.
- **The window** (`Window.lua`): one of Core's (kind `screen`, docked `TOPRIGHT`, in the layer of the game's
  minimap), Edge fills the screen; laid out in its `docked` hook once it stands. Full, the quest log at the left
  (its width comes in with the window's motion), the canvas to its right, the bar over it. With the game's
  minimap chosen the small window rests (alpha 0, the canvas takes no mouse and holds no texture) while the
  corner's push still fills the screen; Edit Mode shows it. The Classic windows are kept choices (Core's
  `checked`, `back`).
- **When something fails:** the module stands down: the keys go back to the game, its minimap back where it
  was, our window goes (`ns.GiveBack`); what may not be done in a fight waits for its end.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Navigation.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Navigation.lua` | The module's table (`ns`), its texts and settings, `/sane map`, `GiveBack` |
| `Coords.lua` | Map, world and plane; a map's box; the map tree, the planes (the continents, and a map of its own on the world map) and the links between them; the terrain's grid; the player's place. No frames |
| `Camera.lua` | Where a view looks: middle, zoom, following, the level its zoom shows; drag, wheel, one map out. No frames |
| `Live.lua` | What the game tells while playing, read when it changes. No frames |
| `Canvas.lua` | The frame the map is drawn in: holder, layers, pools, layout, the tracker, the mouse |
| `Terrain.lua` | The terrain layer: the game's minimap textures from Core's set *Tiles*, and the overview |
| `Outlines.lua` | The zones that have an outline, by continent: made by `dev/tools/terrain-art`, not by hand |
| `Art.lua` | The view Parchment: Blizzard's world and continent maps, the stitched map, every zone's full map cut to its outline; the highlight under the mouse |
| `Painted.lua` | The view Atlas: the module SaneUI_Atlas found at login, loaded when first drawn, its blocks at the level the zoom asks for |
| `Pins.lua` | The pins as plain records: the game's and Core's data per map, one per thing, filtered, gathered. No frames |
| `Walk.lua` | Core's walking data: a tile's block unpacked, its rectangles, regions and openings. No frames |
| `Search.lua` | A walk between two points over the walking data, as a job of Core's scheduler. No frames |
| `Planner.lua` | The way to the map pin: on foot, by the flights this character knows, by boat and zeppelin, by the hearthstone. No frames |
| `Areas.lua` | A quest's areas, as the game shades them (`QuestPOIFrame`), over each zone in view |
| `Route.lua` | The golden line of a way, the parts in view: walks gold, flights pale, ships red |
| `PinView.lua` | The pins drawn: a pooled button each, in the game's looks, tooltips, clicks |
| `Marks.lua` | The player's arrow, the map pin, the party |
| `Hybrid.lua` | The game's minimap over ours: taken, placed, given back |
| `Native.lua` | The game's map kept closed; its keys |
| `QuestLog.lua` | The quest log at the full map's left |
| `TopBar.lua` | The bar over the full map: the quest log's button, the views, the map selector, the pin filter |
| `Window.lua` | Core's window: the top right corner, the full screen, the two cameras, the view buttons |
| `Art/Terrain/*.blp` | The terrain's overview: the game's minimap textures, smaller, the water cut away, made by `dev/tools/terrain-art` from the game's files |
| `Art/Zones/*.blp` | Each zone's outline over its map's box, made by `dev/tools/terrain-art` from the game's files |
| `Art/Sketches/*.blp` | The stitched map: every zone's full map on its continent, in the terrain's blocks, made by `dev/tools/terrain-art` |
| `Art/Edge.blp` | A map's box with its paper frame faded off, for Blizzard's world and continent maps |
| `Art/Masks/*.blp` | The bands that cut the game's minimap to a window that is not square, made by `dev/tools/minimap-masks` |

Tests: `dev/tests/navigation.lua`.

## History
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
