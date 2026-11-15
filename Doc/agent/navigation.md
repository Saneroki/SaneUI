# Navigation

`SaneUI_Navigation` (`src/Navigation/`): the minimap, the world map and the quest log in one window of Core's kind
`screen`. The plan is `Doc/ideas/Navigation.md` (*The planner*, *Map pins*, *Full screen*, ...); what was built day
by day is `src/Navigation/README.md`, section *History* (line 880). Read first: `Doc/guides/windows.md` and
`Doc/guides/data.md`.

## What it is

1. One window, docked `TOPRIGHT`, strata LOW like the game's minimap (`Window.lua`). Small: the minimap. Full screen
   (the corner filled by Core's Edge, Esc back): the map, the quest log beside it (`QuestLog.lua`; pinned on the screen
   while the map is small too, in place of the game's tracker; its quest timers at its top, in sight while it rests or
   is off) and a top bar (`TopBar.lua`: the log's button, the
   views, the map selector, the dungeons, *Follow me*, the pin filter). In the middle of Core's title bar over it the
   search (`FindBox.lua` the field and its list, `Find.lua` the finds: Core's NPCs, objects, places, items and where
   they come from, quests, what trainers teach; the game's zones, dungeons, flight points, log, guild, group, friends;
   "nearest", "who sells X", "in <zone>", levels; its places as pins of kind `find` on the full map, the map pin at the
   nearest; the key *Search the map*, `Bindings.xml`; 2026-11-15). *Where to farm X* (`Farms.lua`): the places thickest
   with what gives it, clustered from Core's spawns weighed by drop chance, glowing on the full map (the canvas' layer
   `farms`), a pin at each; a mistyped word put right.
8. Your own markers (`Markers.lua`, 2026-11-15): Alt and a click on the map puts one; a card (the kit's bronze) to
   write its title and description and pick its icon; pins of kind `mark` on both maps, the title beside them on the
   full map, a click opens the card (Edit, Move, the map pin, Delete); kept in `ns.store.markers` for the account,
   never shared (sharing and drawing: card #481); the pin filter's *Your markers*; found by the map's search.
2. One canvas of our own (`Canvas.lua`; never Blizzard's map canvas: its pins taint in a fight), the same in both
   cameras (`Camera.lua`; Retail's `Camera.Retail.lua`: one map at a time from the game's map tree): drag pans, the
   wheel zooms from the minimap's range to the world, follows the player, north-up only. The views (setting `view`,
   `ns.TEXT.views`): Parchment (`Art.lua`, the game's maps), Blended and Scrying (`Terrain.lua`, Core's set
   *Tiles*); the map starts as Scrying where it can be drawn, else Parchment (`ns.FALLBACK`, `Fallback`, `Several`).
3. The game's `Minimap` lies over our ground in the small view (`Hybrid.lua`), so its live dots stay; other addons'
   minimap buttons are held for the satchel (`Strays.lua`, `Satchel.lua`); all given back exactly. The satchel's
   section Sane UI starts with the line of Core's sound profiles (`AudioLine.lua`, `Core.Audio`). In an instance the
   game's minimap alone is the small map (`lost` in `Canvas.lua`); one wheel notch out past its widest step shows a
   dungeon's whole map there instead (`Dungeons.Whole`, `Dungeons.Small`; 2026-11-11). The dungeons' maps on the full
   map open whole under the bar and beside the quest log (`Dungeons.lua`, `Room`).
4. Pins (`Pins.lua`, no frames; `PinView.lua` draws them): the game's answers (`Live.lua`) and Core's data
   (`Data.Map():On`: Spawns, Places, Travel; the sets Quests, NPCs, Objects), one per thing, the game's word wins;
   filtered by the setting `pins` (multi) and the pin filter. The kind `goal` (`Goals.lua`): the exact spawns of the
   open objectives of the quests in the log, from Core's data; the mouse on a quest in the log makes its pins glow.
5. The map pin and the route (`Planner.lua`, `Search.lua`, `Walk.lua`, `Gates.lua`, `Lifts.lua`; `Route.lua` draws the
   golden pulsing line, always from the player): on foot over Core's set *Walking*, by the flights the character knows,
   boats, zeppelins, the tram, lifts, portals, the hearthstone and the teleports it has (Core's set *Travel*,
   `Data.Ships`, `Data.Trips`; a portal of one class, the mages' own, only for that class). A walk orange or red where
   enemies of your side well above your level spawn near it (`Danger.lua`: Core's *CreatureSpawns*, *NPCs*,
   *FactionTemplates*); the line dragged on the full map puts a waypoint it goes to first (`Planner.Via`, `Canvas.lua`,
   `Marks.Vias`). The trip underway and the
   docks' times: `TripView.lua`, `DockWatch.lua`. The mouse on a flight point's or a dock's pin draws its ways
   (`Paths.lua`); on a zone lit up the full map names it with its levels and fishing skill (`Label.lua`, Core's set
   *Fishing*); while dead the map pin stands at the corpse, the one before back once alive (`Corpse.lua`). At a
   flight master our full map stands in for the game's flight map, its flight points large to click (`Taxi.lua`;
   Shift held: the game's).
6. The leveling guide is not Navigation's: Speed Leveling runs text guides with its own engine
   (`src/SpeedLeveling/Guide.lua`, `Guides.lua`, `Run.lua`). Its arrow points straight at its place (2026-11-07); the
   planner still serves a way through `Core.Ways` (its second way, `guide`, never drawn; `Core.Ways.Serve` at its end),
   unasked now. Its detours go by Navigation's
   found herbs and ore through `Core.Sight` (`Found.lua`). Core's set *Guides* is unused (its folder holds only the
   schema).
7. The game's minimap and map are hidden by default (settings `nativeMinimap`, `nativeMap`, both off; `Native.lua`
   keeps the game's map closed and takes its keys). Any failure stands the module down: `ns.GiveBack`
   (`Navigation.lua`) gives them back, each step `Safe`, what a fight holds up after the fight.

## Parts, by file group

The file list with a line each: `src/Navigation/README.md`, section *Files* (line 828). The groups: the window and its
cameras (`Window`, `Camera`, `Camera.Retail`, `Coords`, `Canvas`); the views (`Terrain`, `Outlines`, `Coasts`, `Art`,
`Indoors`, `Dungeons`); the game's own parts (`Hybrid`, `Native`, `Strays`, `Satchel`, `AudioLine`); pins and marks
(`Pins`, `PinView`, `Marks`, `Areas`, `Live`, `Ping`, `Label`, `Paths`); the Sane Rare tracker (`RareTracker`: finds near
you told by a notice and a horn, `/sane testraretracker`); your markers (`Markers`); the map's search (`Find`, `FindBox`, `Farms`; `Search.lua` is the walking data's, not it); the routes (`Walk`, `Gates`, `Search`, `Lifts`,
`Planner`, `Corpse`, `Danger`, `Taxi`, `Route`, `Route.xml`, `DockWatch`, `TripView`); herbs and ore (`Nodes`, `Found`, `Sparkles`, `Glints`); the quest log
(`QuestLog`) and the bar (`TopBar`); `Navigation.lua` (texts, settings, `/sane map`, `GiveBack`). The art
(`Art/Terrain`, `Art/Zones`, `Art/Sketches`, `Art/Indoors`, the marks) is made by `dev/tools/terrain-art`,
`indoor-art` and `mark-art`, never by hand.

## Routing

The routing's constants and why they are what they are stand in the head comments of `Planner.lua` (the journey
graph over every plane, the walks priced by the coarse layer first, the floors, the line), `Search.lua`, `Walk.lua`,
`Gates.lua` and `Lifts.lua`; the plan's *The planner* and *The walking data* hold the decisions. Core's set *Walking*
is made by `dev/tools/walk-data` (`saneui makewalkdata`), its coarse layer `gates` by `dev/tools/walk-gates`
(`saneui makewalkgates`; `dev/tests/walk.py` fails on a stale layer); its master `assets/data/Walking/Walking.jsonl`
is about 43 MB. The flight points a character has found are Navigation's own (`Planner.lua`, `flightPoints` per
character, learnt at a flight master).

## What is not there yet

- Core's data: step 1a is built (the sets part of Core, `Data.Set`, history, `OnStamp`, the scheduler), and so are
  1b (the Quests master), 1c.4 (`Data/Characters.lua`; its auction log and own auctions still open) and 1d.4
  (`src/Core/Data/Quests.lua`, the quest watchers), with `Data.Map()` and the learnt teleports (`Data/Teleports.lua`)
  (`Doc/ideas/Data-build.md`). Not built: `Data.Areas()` (1d.5, *Areas and the map*).
- The sets: every set Navigation reads has entries (Zones, Places, Travel, NPCs, Objects, Quests, Spawns, Walking,
  Tiles, Indoors, Overlays, Dungeons, Bosses, Encounters, Items, FactionTemplates), and QuestAreas, PatrolPaths and CreatureSpawns are
  filled too (`ls -la assets/data/`); only Guides is empty, and no tool writes it.
- Core's windows: the holder (`src/Core/Holder.lua`), the board (`Board.lua`) and the Edit Mode box and dialog
  (`Selection.lua`) are built. Navigation needs neither the holder nor the board: it keeps the game's map itself
  (`Native.lua`) and lays out its full screen in `docked`.
- Not built: a travel pin's ways under the mouse (the plan, *Map pins*); exact places of guild members outside your
  group (the search shows the zone the roster names; card #38); the dungeons' three zooms and our own art where the game
  has none (the plan, *Dungeon, instance and raid maps in three zooms*; `dev/tools/map-layers` makes the levels); rares' spawn
  areas and patrol paths on the map (the sets are there, Navigation does not read them).

## Open questions without a proposal

13 (guides wholly by the tool, or mended by hand), 14 (step hints), 15 (the step at the minimap), 17 (leveling
figures: Navigation or the library module), in `Doc/ideas/Navigation.md` after *Map selector*. The other open
questions are built as proposed when their step comes.

Tests: `dev/tests/navigation.lua`, `dev/tests/walk.py`; the lab's scenes `far-sparkles`, `questlog`, `satchel`
(`dev/uilab/scenes/`).
