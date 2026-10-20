# Navigation: handoff for the session that builds it

Written 2026-10-18, before any code; what is built since is under *Built*, below. The plan is [Doc/ideas/Navigation.md](../ideas/Navigation.md);
where this note and the plan differ, the plan wins. Read the plan's *Design* and *Build order* first, then
the window guide ([windows.md](../guides/windows.md)) and the data guide ([data.md](../guides/data.md)).

## What it is

`SaneUI_Navigation` (`src/Navigation/`, its README says what is built). One window of Core's kind
`screen`, docked `TOPRIGHT`, takes the place of the minimap, the world map and the quest log:

1. Small: the minimap. Full screen (a click into the corner, Esc back): the map, the quest log on the left,
   a top bar (map selector, pin filter, the views Parchment / Scrying, and Atlas while its module is there).
2. One canvas of our own (not Blizzard's map canvas: its pins taint in a fight), terrain from the game's
   minimap tiles plus Blizzard's map art; drag pans, the wheel zooms from minimap range to the world; two
   cameras, one per view; follows the player; north-up only.
3. The small view puts the native `Minimap` over our ground, as Blizzard's hybrid minimap does, so the
   game's live dots stay.
4. Pins from Core's data plus the game's live answers (the game's word wins, one pin per thing).
5. The game's map pin, a route with flights and ships, a golden pulsing line.
6. A leveling guide read from Core's set *Guides*; its item button is a secure frame on `UIParent`, never in
   the map window.
7. The game's minimap and map hidden by default, switches *Minimap* and *Map*; on any failure `StandDown`
   gives them back.

## Build order (the plan's)

| Step | What | Blocked by |
| --- | --- | --- |
| 0 | Proof behind `/sane map test`: the seven *to try* points (a–g) | the game; (a) needs the tile table |
| 1 | Minimap: window, canvas, camera, native dots, `GiveBack` | nothing (terrain waits for *Tiles*; the native ground shows until then) |
| 2 | Map: full screen, zone to world, Blizzard's art, views, selector, the game's map kept closed | step 1; Terrain needs *Tiles* |
| 3 | Live pins | step 2 |
| 4 | Quest log | step 2 |
| 5 | Database pins, areas, rares | Core's data (below) |
| 6 | Routes | Core's data, the walking data tool |
| 7 | Leveling guide | Core's data, the guide tool, step 6 |
| 8 | Dungeons, the minimap's own parts, polish | |

**Steps 0 to 4 can start now:** they need Core's window system and the game's API only.

## Built (2026-10-19): the module without the map's data

Steps 1 and 2 of the plan's build order, and the parts of 3 that are no pins (`src/Navigation/README.md` in
full):

- the window (Core's kind `screen`, `TOPRIGHT`, strata LOW like the game's minimap), two cameras (small, full),
  the same canvas and controls in both (Saneroki, 2026-10-19: the minimap and the map look and behave exactly
  the same): drag, wheel around the mouse (instant, as Blizzard's map), right click one map out, Ctrl-click the
  game's map pin, a click on the game's minimap pings;
- levels zone, continent, world in one plane per continent, linked through the world map's rectangles
  (`Coords.Link`, `Coords.WorldBox`); the camera moves into another continent's plane coming in at the world;
- the views at every zoom (Saneroki, 2026-10-19): terrain from *Tiles* (up to 400 tiles) over the module's
  overview (`Art/Terrain/`, `dev/tools/terrain-art`, 45 textures), art of world, continent, zone, explored parts;
- the game's minimap over ours for its live dots (`Hybrid.lua`): ground off, square, rotation ignored, while
  the view follows at one of its steps; its cluster out of sight without clicks; given back exactly;
- the game's map kept closed and its keys (`Native.lua`); the switches *Show the game's minimap* / *map*,
  *Classic windows*; *Follow again after*;
- `Live.lua`: player, pin, group, quests, flights, vignettes, area POIs, explored, with the message `LIVE`.

Later the same day (Saneroki's asks): zones light up under the mouse and open by a click; the map grows and
zooms with its window (Core's option `moving`); the game's minimap covers the small window, above the map;
the corner fills the screen once a visit (Core's Edge); the terrain's water cut away and the zones' maps cut to
their outlines (`dev/tools/terrain-art` reads the game's terrain files: `Art/Terrain/`, `Art/Zones/`,
`Outlines.lua`). Then: the view *Sketches* (was *Blizzard maps*), one stitched map of both continents at every
zoom (`Art/Sketches/`), every zone's map in full (Core's set *Overlays*: every part, explored or not), outlines
fading softly into each other; the dark undiscovered parts taken out again. Decided next: Sketches and Terrain
stay as they are; the local image models paint a third view of its own in Overlay's place, with the Maelstrom
and looped sea creatures and ships (`Doc/ideas/Navigation.md`, *The painted view*). Its guides from the game's
files are made by `dev/tools/map-meta` (roads, buildings, ground cover, places with districts and flight
masters), the zones' briefs are `dev/imagegen/maps/zones.toml`; the pilot lists are in
`dev/imagegen/sets/maps-pilot/`.

The Atlas, a module of its own (Saneroki, 2026-10-19): *Overlay* is gone (default Scrying; a saved Overlay falls
back to it). The painted map is the addon `SaneUI_Atlas` (`src/Atlas/`: TOC, `Atlas.lua`, README; load on
demand). Its art and index are made by `dev/tools/atlas` into `assets/optimized/Atlas/` (`Art/<continent>/<level>/
<row>_<col>.blp`, `Index.lua`), never into `src/`; `dev/build` builds the addon from both, only once
`assets/optimized/Atlas/Index.lua` exists (the lint accepts the TOC's `Index.lua` there or missing). Navigation's
`Painted.lua` finds it at login without loading it (offered: a third button, a third choice), loads it when the
view is first drawn and reads it as `SaneUI.Atlas`; on a failure the view falls back to Scrying and its button
and choice go (`ns.Offer`). The view: the terrain as Scrying, the blocks over it at the coarsest level with
enough pixels a yard for the screen, the next coarser one under them; `Camera.Near()` 6 units a yard there.

## Built (2026-10-20): pins, the quest log, the bar

Saneroki's asks of 2026-10-20 (`Doc/ideas/Navigation.md`, *A classic window is kept*, *The minimap fills its
window*, *Always on top*):

- `Pins.lua` (no frames) and `PinView.lua`: the game's pins per map (quests, the arrow's quest's next way, flight
  points of the player's side, vignettes, area points, map links, entrances) and Core's (`Data.Map():On`, new in
  `Core/Data/Map.lua`: Spawns, Places, Travel; filled 2026-10-20), one per key, filtered (setting
  `pins`, multi), gathered (`Pins.Gather`), in the game's atlases; `Canvas.Press`/`Release` share drags and clicks.
- `Areas.lua`: the game's `QuestPOIFrame` per zone in view (the quest under the mouse in the log, else the arrow's).
- `Marks.Group`: the party and raid. `Route.lua`: the golden line's drawing (`Route.Show(way)`); no planner yet.
- `QuestLog.lua` at the full map's left, `TopBar.lua` over the map (log button, views, map selector, pin filter);
  `Window.lua` lays them out (the log comes in with the motion; `Window.FullSize`).
- Stacking: `Canvas.LEVELS` (map up to `Canvas.MAP` 5, areas 6, route 7, the game's minimap 10, pins 12, marks 20,
  the bar 30), set at every layout.
- The game's minimap square, as large as the window's shorter side, cut by the game's own white square (`Hybrid.Side`).
- Classic windows kept (Core's Edge: entries with `checked`/`back`); with the game's minimap chosen the small
  window rests out of sight (`Window.lua`, `Rest`), the corner still fills the screen with ours.

Routes (the same day): `dev/tools/walk-data` makes Core's set *Walking* (pack Routes, 1,724 tiles of the continents
and 26 of Zephras Isle, 10.9 MB) from the
game's terrain, buildings' collision and water (2.08-yard samples, surfaces, rectangles, regions; block format in
the tool's header and `Doc/ideas/Navigation.md`, *The walking data*); `dev/tools/travel-data` the flights of
Core's set *Travel* (296, from the client's TaxiPath tables: nodes, cost, length, path); `Walk.lua` unpacks a tile,
`Search.lua` walks (A*, funnel, a job of Core's scheduler), `Planner.lua` plans walk/flight/walk to the map pin
(known flight points per character, `Core.Character`), `Route.lua` draws. Inputs of the tools: the extracted game
files of the private baseline (`adt/`, `adt-obj0/`, `wmo/` with every group file, the client tables as CSV).

Ships (2026-10-20): `Planner.Ship(way, key)` from Core's timetables (`Data.Ships`), the wait for a ship the time to
its next departure once a ride on the realm taught its times (`Ships:Next`), else half its round; `DockWatch.lua`
(setting `dockTimes`) shows at a dock where its ships go and when they arrive and leave, aboard when it lands
(under `UIWidgetTopCenterContainerFrame`, a guarded 1-2 s chain). Ship periods: Travel's `wait` from batch 6.

Trips (2026-10-20): `TripView.lua` (setting `tripView`) draws Core's `Data.Trips` (flight, ship, tram) under the
top-centre widgets with Core's bar, stop marks (`TaxiNode_Neutral`) and the game's leave button art for Request
Stop; `Planner.lua` draws a flight's way on as the first leg (`Flying`, `Fly`, `Trips:OnChange`). The Deeprun Tram
is Travel's key 1000369 (kind `tram`, `dev/tools/travel-data`).

Not yet: portals and lifts in routes, doodads in the walking data (fences, trees), search, the guide, dungeon maps and floors, the minimap's small parts
(zone text, clock, mail, tracking), rares' spawn areas, patrol paths. Tests: `dev/tests/navigation.lua` (210
checks), `dev/tests/walk.py` (28).

## What is not there yet

1. **Core's data framework** has only step 1a (`Doc/ideas/Data-build.md`): packs, `Data.Set`, `Get`,
   history, `OnStamp`, the scheduler. Not built: `Data.Map()` and `Data.Areas()` (1d.5), the Quests reader
   (1b, 1d.4), the characters' data such as known flight points and rares seen (1c.4).
2. **Sets Navigation reads with entries** (2026-10-20): Zones, Places, Travel, NPCs, Objects, Quests (the old
   facts), Spawns, Walking (`dev/tools/map-data`, `travel-data`, `walk-data` and picked batches, `sources.toml`);
   **still empty:** QuestAreas, PatrolPaths, CreatureSpawns, Guides.
3. **Set *Tiles*:** built (2026-10-18), in the pack World: 736 tiles of the Eastern Kingdoms, 988 of Kalimdor,
   72 of Zephras Isle (2026-10-20, its own map 2991), read from the game's own map files; key continent × 4096 +
   row × 64 + column. The isle has its overview, outline, stitched map and walking data too (`--maps 2991` of
   `dev/tools/terrain-art` and `dev/tools/walk-data`).
4. **The walking data tool** (pack Routes): written (2026-10-20, `dev/tools/walk-data`), the set filled.
5. **The guide tool** that writes *Guides* from Core's quest data: not written.
6. **Core's windows:** click to expand (`Edge.lua` still fills on the mouse's coming), the holder, the board
   and Edit Mode layouts are not built. Navigation does not need the holder or the board: it catches the
   game's map itself (plan, *The game's map and minimap*) and lays out its full screen in `docked`.
7. **Art of our own** where the game has none (dungeon maps it lacks): not made.

## Open questions without a proposal

13 (guides wholly by the tool, or mended by hand), 14 (step hints), 15 (the step at the minimap), 17 (leveling
figures: Navigation or the library module). The other open questions are built as proposed when their step
comes.

## For a cloud session

- `lua5.1`, `luac5.1` and `rsync` must be installed before `dev/tests/run` or `dev/build --no-install` run.
- There is no game: every step's *done when* is Saneroki's; the session lists what the game needs
  (`/reload`, or a restart for a new addon folder or TOC change).
- Commits go to `main` (`CLAUDE.md`, *Workflow*).
