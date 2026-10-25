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

Decided 2026-10-21, not built (`Doc/ideas/Navigation.md`, *Zones and continents reimagined* and the points after
it): the Atlas is one smooth world of three levels, terrain (the close squares, as built), zone and world (both
continents, no continent level), its style blending as the wheel zooms, no right-click step out (`Canvas.lua`
still has one). Zone and world are free realistic paintings by the image model (the zone's major places in the
middle, only loosely far out; the lore's view where the game's zone is cut open: Teldrassil's tree, Ironforge's
mountain), with no pins and no names (an overlay drawn by code: names, level ranges, gathering skills, each its
switch). Close up, only edges the player cannot reach are blended; coasts, piers and passes stay exact. Scrying
and Parchment stay the game's files, pixel for pixel. Dungeons, instances and raids get three zooms (terrain,
a room plan drawn by code, a free reimagination), picked in the map selector; indoor maps are clear around,
never black, to lie over the terrain. Around the paintings: a review queue, a size budget, repainting only what
a game update changed; the paintings run on `dev/tools/gpu-runner`.

## Built (2026-10-20): pins, the quest log, the bar

Saneroki's asks of 2026-10-20 (`Doc/ideas/Navigation.md`, *A classic window is kept*, *The minimap fills its
window*, *Always on top*):

- `Pins.lua` (no frames) and `PinView.lua`: the game's pins per map (quests, the arrow's quest's next way, flight
  points of the player's side, vignettes, area points, map links, entrances) and Core's (`Data.Map():On`, new in
  `Core/Data/Map.lua`: Spawns, Places, Travel; filled 2026-10-20), one per key, filtered (setting
  `pins`, multi), gathered (`Pins.Gather`), in the game's atlases; `Canvas.Press`/`Release` share drags and clicks.
- `Areas.lua`: the game's `QuestPOIFrame` per zone in view (the quest under the mouse in the log, else the arrow's).
- `Marks.Group`: the party and raid. `Route.lua`: the golden line's drawing (`Route.Show(way)`, the planner's way);
  corners turning more than `Route.BEND` degrees as curves (`Route.STRAY` units deep at most), one pulse along them.
- `QuestLog.lua` at the full map's left, `TopBar.lua` over the map (log button, views, map selector, pin filter);
  `Window.lua` lays them out (the log comes in with the motion; `Window.FullSize`).
- Stacking: `Canvas.LEVELS` (map up to `Canvas.MAP` 5, areas 6, route 7, the game's minimap 10, pins 12, marks 20,
  the bar 30), set at every layout.
- The game's minimap square, as large as the window's shorter side, cut by the game's own white square (`Hybrid.Side`).
- Classic windows kept (Core's Edge: entries with `checked`/`back`); with the game's minimap chosen the small
  window rests out of sight (`Window.lua`, `Rest`), the corner still fills the screen with ours.

Routes (the same day): `dev/tools/walk-data` makes Core's set *Walking* (1,724 tiles of the continents
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

Trips (2026-10-20, 21): `TripView.lua` (settings `tripView`, `dockTimes`) is the travel overlay two thirds up the
screen: Core's `Data.Trips` (flight, ship, tram) or the wait at a dock or the tram's station (`DockWatch.Rows()`,
no frames): a fine golden line of Route.lua's art (Line widgets, the glint template), eased every frame (OnUpdate
only while shown), the vehicle's icon at its tip, stop marks (`TaxiNode_Neutral`), the game's leave button art for
Request Stop; `Planner.lua` draws a flight's way on as the first leg (`Flying`, `Fly`, `Trips:OnChange`). The Deeprun Tram
is Travel's key 1000369 (kind `tram`, `dev/tools/travel-data`); the planner takes it between its two entrances
(`Tram` in `Planner.lua`: `Planner.STATION` + half of Travel's `wait` + `time`, a straight red leg).

Routes, the quality pass (2026-10-21): floors lie one over the other and the game tells no height, so
`Walk.Follow` follows the player's floor through the openings nearest their way (every `Planner.FOOT` seconds while
there is a pin) and `Walk.Floor` chooses one where that cannot be done (near the height they had; outdoors the
highest, indoors the lowest within `Walk.ROOF`). `Search.Walk(continent, u1, v1, u2, v2, from, check)`: from the
player's floor (`from`), else every floor under the start and within `Walk.ROOF` (each over the lowest at the cost of
the climb), to any floor of its regions under the end or within `Search.NEAR`, else the nearest within `Search.FAR`;
straight off the data at `Search.STRAIGHT` times, each yard up `Search.CLIMB` more; `Search.Start` went. A step
aims where the straight line on to the end crosses the next opening (`Through`, 2026-10-22); a yard swum costs the
walk's `water` (the planner's: the character's speed on land over its speed in water; else `Search.WATER`, 1 / 0.6).
`Planner.lua`: every plane's places (a third plane: the hearthstone, then a ship), a flight point twice (ground and
air, the air reached by a flight only: one take-off with the first flight, the flights one leg, no walk on after a
walk there), the regions of a place's floors within `Planner.REGION` (sharing none:
`Planner.APART` more), the plan one job of Core's scheduler (`Make`, `Find`), the cut (`Follow`: where along the
line the player is) drawn by `Route.Cut` (the parts passed gone, a head from the arrow), a ship boarded without the
plan (`Riding`), the tram's next train (`Trips:TramNext`). Walk's tiles: the 48 asked for last. Walks timed at
the character's own speeds (`Speeds`, each plan: `GetUnitSpeed`, on land at least the fastest seen riding, kept per
character as `ride` by `Ridden` at each floor look; else `Planner.RUN`, `Planner.SWIM`).

Lifts (2026-10-21): Travel's kind `lift`, one record per car (keys from 1100001, `dev/tools/travel-data --lifts
<places> <batch>`: the motion from the client's TransportAnimation, the places a batch file of our picking, batch
10). `Lifts.lua` (no frames): each end at its landing (`Walk.Landing`), `Lifts.Levels` (two landings' regions;
stacked or side by side by a ring round the shaft), `Lifts.Joined`, `Lifts.Stand` (where a place stands: below a
stacked upper level, the Undercity under the ruins), `Lifts.Near`, `Lifts.Heights` (2026-10-22: the heights of an
end's own level, for the walks to it). `Planner.lua`: lift ends are places (`lift`,
`floor`, `z`), the ride costs `wait / 2 + time`, no walk between two joined levels or into a place below one, walks
start on known floors (`step.floor`), `Rode` puts the floor on the far landing after a ride; the pin keeps its map
(`target.at`). Checked offline on the real data: Walk, Search, Lifts and Planner under lua5.1 with stubs, the tiles
decoded from `Walking.jsonl` in Python.

Walking data joined (2026-10-21): `dev/tools/walk-data` judges a building's slope in yards (it was 30° in the
samples' space), lets a wall take a sample's floor only in its middle (`CORE`) and else close the ways it crosses
(`walls[(row, column, side)]`, `stands`, `walled`: `STEP`, `LEDGE`), and keeps the regions the master's lifts land
on (`lifts`, `landings`): 1.65 million rectangles, 12.6 MB. The Undercity and the ruins are one region (its sewers):
`Lifts.Levels` makes stacked levels within one region (`level.alone`, `low`, `split`, `Lifts.SPREAD`), and
`Planner.lua`'s `Over` keeps a place below a level from one on it also where they share a region. The whole city
(2026-10-22): within one region a place stands below a level on a map the lift's ends lie on (`Round`: in that map's
box, in the lift's plane; the Undercity's holds its Royal Quarter, up to 344 yards from the nearest lift), or within
`Lifts.SPREAD` yards of the lift; before, the Royal Quarter (beyond `SPREAD`) counted as on the
ruins, so routes from near the lifts went up and round, and walks from the surface ended on the hill over it. No walk
after a walk at a flight point (2026-10-22): `Journey` takes off with the first flight (`Flights` from the ground
node, `Planner.BOARD` with it; no `"up"` way), so the air over a flight point (`-node`) is reached by a flight only
and `"down"` is a landing; before, up and straight down let a walk follow the walk there, on from another of its
floors (`Search`'s sources: every floor at a place without its own), as from the lift to Sylvanas by the bat handler.
No ride straight back (2026-10-22): `Journey` keeps, per node reached by a ride, the place the rides since the last
walk began (`boarded`; `origin` while a node is looked at) and lets no ride (nor `"down"`) reach it, so a lift's end
walked to is not ridden up and straight down again to walk on (5 of 200 routes did, at the Undercity's lifts and
Gnomeregan's); a walk to a lift's end ends on its own level (`step.level` = `Lifts.Heights`: within `Walk.RISE` of
its landing's height, at most half way to the other's; `Search.Price`'s `level` keeps `Goals` to those heights, none
else), as the walk to the Undercity's upper landings ended in the city under them; and `Find` draws the quickest of
the journeys priced whole (`kept`: Journey's seconds with each walk's price in place of its guess and
`Planner.APART`), as one chosen again could be dearer than one before it (a walk up to `Planner.WORSE` times its
guess stays; after `Planner.TRIES` the last stayed: Ironforge to the Undercity by Dalaran, 910 s for 650).

Doodads in the walking data (2026-10-21): `dev/tools/walk-data` reads the doodads' collision (`model`: the M2 header's
collision triangles; `placements`: the object files' MDDF and each building's doodad sets, `doodads`, set 0 and the
placement's own, MWDR/MWDS), places buildings and doodads tilted as the game does (`placed`: the full turn, checked
against the object files' boxes), leaves out doodads no wider than `SMALL` (2 yards) and what lies wholly under the
ground (`sunken`), counts a column as built only where something comes near the ground, and picks a lift's landing
with the rise counted `LEVEL` (3) times, as `Walk.Landing` must too. The models are the game's own, in `m2/` beside
`wmo/` in the game files' folder. Doodads alone: 2.41 million rectangles, 17.9 MB of blocks.

The ground as the game draws it (2026-10-21): `dev/tools/walk-data` judges the ground by the game's triangle under each
sample (`steepness`, from `ground`; it was the heights smoothed over three samples, which walked up Ironforge's
mountain), reads the buildings' own liquids (`pools`, `liquid`: MLIQ; the canals of Stormwind swum, slime and lava
closed), drowns a floor only with nothing solid between it and the surface (`overs`), lets the next piece of a stair
pass over a floor (`roomy`, `STAIR`), takes a floor by a wall only within `CORE` 0.3, marks a floor on a building or a
doodad `BUILT` (kind 3) and each floor's sky (`SKY`, `COVERED`, `BURIED`: the ground `DEPTH` yards under a building),
and leaves out regions with no sky or mostly buried (the ground under Stormwind). The set made with the doodads: 2.83
million rectangles, 23.7 MB in the master. Navigation: `Walk.Floor` indoors takes a building's floor before the
ground under it, `Walk.Landing` the rise `Walk.LEVEL` times, `Search.CLIMB` 0.25, the planner's walk guess at least
the way the steepest floor needs (`Planner.SLOPE`). Checked offline on the whole data: 53,000 creatures'
spawn points (71 % on a floor at their height), the lifts, walks into the cities and across hilly zones, and the gentlest
way over the game's triangles where regions part.

Openings both ways (2026-10-22): `dev/tools/walk-data` links every floor beside a rectangle's edge one way with its own
(`openings`, `across`; it took the first, so a way back went to another floor and was lost: small islands), only
between rectangles that meet along that side (`meets`; a surface's rectangles end where one of its floors is one way
with another surface's beside it while the surface goes on, `cuts`; `shared` asks the same of a pair written whole),
so `Walk.lua`'s way back and the search's line lie on both rectangles. A way through another floor is none
(`through`), but a tile keeps one where its parts would come apart (`bridges`, `plan`: halls whose doors are walls in
the data, Lordaeron's inner ruins). The regions portals land on are kept as the lifts' are (`ends`, `landings`). The
set: 3.03 million rectangles, 24.1 MB in the master. Checked offline: no islands, no opening without its way back or
off its rectangles, all lifts and portals land, 200 journeys as before but none off the data, about 5 % slower.

## Built (2026-10-20, 21): quest marks, the filter's sections, dungeon maps, the quest log's clicks

Saneroki's asks (`Doc/ideas/Navigation.md`, *Map pins*, *Full screen*, *Dungeon maps now*; README *History*):

- **Quest marks** (`Pins.lua`, `Pins.ICONS`, `Pins.RED`; `PinView.lua` tints): in the log the yellow `questturnin`,
  to take the opaque `questnormal`, too low the grey `trivialquests`, for later the yellow mark tinted red. Tooltips
  no longer tell the click (the text `drop` went). The pin filter (`TopBar.lua`, `ns.PIN_SECTIONS`, each kind's
  `section` in `Navigation.lua`): titled sections, icons of `TopBar.ICON` (24), rows of 30, `SetScrollMode`.
- **Dungeon maps of Core's set *Dungeons*** (batch 9 of `sources.toml`, from Blizzard's retail
  tables; Forever's client has no dungeon maps but has their art): `Dungeons.lua` lists them with the game's own (`Dungeons.List`, `Entry`, `Key(instance)`), builds the
  art from the set's tiles (`ArtOf`), finds the floor by the world position (`Here`, `OnFloor`), places each boss's
  mark and its `PlayerModel` (`PlaceBosses`, `Stand`: `SetDisplayInfo`, hidden past the view's edge). An entrance's
  pin opens its dungeon (`Data/Map.lua` passes the place's `instance`).
- **The map pin, safely** (`Live.SetWaypoint`): refused off the map, where the game allows none, or when the game
  refuses it, with `ns.TEXT.noPin`; it once stood the module down.
- **The quest log's clicks** (`QuestLog.lua`): a click the map pin on the objective (`Pin`, `Where`, `PinView.Drop`),
  the map staying; the menu *Quest Details* (`QuestLog.Text`, `open`) and *Show Map*; each quest's mark (`Mark`);
  no scroll bar but while the mouse is on a list longer than its room, at the docked side (`Scroller`, `Side`).
- **Found herbs and ore clicked** (`Found.lua`): each picture a button, its tooltip the node's name, a click the map
  pin on its zone's map (`OnMap`).
- **Far sparkles** (2026-10-25, `Glints.lua`, setting `nodeGlints`): the found ones (`Found.Each`) beyond 18 yards
  marked on the screen through a camera taken to be behind the player (`Project`: `GetCameraZoom`, `GetPlayerFacing`,
  `cameraFov`; no map pin, no `C_Navigation`, Saneroki), the item's picture in the minimap's gold ring (`Found.Ring`)
  running out into a point of two slices of its art (`Point`, `Lay`), the yards; off the view at the screen's edge; waiting
  while the left button turns the camera (`Behind`). Lab scene `far-sparkles`.
- **Indoor maps off the streets** (2026-10-21): Core's set *Indoors* marks a part `open` (the game's part flag
  `EXTERIOR_LIT` and its area outdoors in `WMOAreaTable`, read by `dev/tools/indoor-art`); `Indoors.lua` never draws
  one and passes over a building whose part you stand in (`Standing`) is open.
- **Instance maps without players** (2026-10-21, Forever tells no place inside): `Dungeons.lua` has no arrow, no
  group, `Dungeons.Here` gives the lowest floor; the drag's step runs only while dragging.
- **Boss tooltips with abilities and loot; enemies** (2026-10-21, batch 11 of `sources.toml`): `Dungeons.lua`'s
  `BossTip` lists Core's set *Bosses*' `abilities` and `loot` (kept apart from the game's *Encounters*: unverified
  until the game confirms them) (the game's names and icons, items asked for and
  drawn again on `ITEM_DATA_LOAD_RESULT`); `PlaceEnemies` draws the set *Dungeons*' `enemies` (six dungeons).
- **A rare's model with Alt** (`PinView.lua`, `Model`, `Stage`): a `PlayerModel` by `SetCreature(npc)` beside
  `GameTooltip`, following `MODIFIER_STATE_CHANGED`.
- **Core's options on the full screen** (Core, `Settings/Screen.lua`): the title bar's cog and question mark stand
  on the map's full screen too; the view covers the map and the quest log (layer `DIALOG`).

Flight points (2026-10-21): only those the character has found are flown (`flightPoints` per character, learnt at a
flight master from its flight map's states and the maps' `isUndiscovered`; `Planner.Knows`); the map's others are red
(`Pins.lua`, `Pins.RED`).

Routes on the real data (2026-10-21): the planner, its search and Core's timetables can be run outside the game over
every walking tile, the game's flight points and Core's set *Travel* (a harness of the session's own, not in the
project); 200 journeys between NPCs' places found faults fixed here: aboard a ship by standing in the town at its
dock (`Aboard`: now within `Planner.DECK` yards of its way, past `Planner.DOCK` yards along it), and the player's floor
guessed (outdoors the highest: Orgrimmar's rock overhangs, a roof) with no walk leaving it (`Footing`'s `guess`, the
search's other floors at `Search.ASIDE`, a leap of `Planner.LEAP` yards chooses it anew); Teldrassil's top had no way
down (portals: Core's set *Travel*, kind `portal`, batch 12; `Portals`, `Ends`, `Arrival`); a walk between regions
the search finds none of was drawn straight (now none, its regions cut for the plan, the journey chosen again,
`Planner.TRIES`; a place reached on foot is a node of its own; `Search.Walk` tells `"off"` and the yards off the data
at the end); one side routed through the other's harbours and zeppelin towers (a ship's `side` now: its towns', by
the flight masters near its docks; batch 13: Forever's portal objects, Stormwind and Dalaran and Dalaran's Citadel,
and the sides its servers' NPCs show, Dalaran's airship the Alliance's). Forever's ways against Classic's: the plan,
*The planner*, *Forever's own ways*. The walking data's one-way openings: fixed 2026-10-22 (below).

The teleports a character has (2026-10-21; the plan, *Built: the teleports a character has, and Frequent Flier*):
Core's set *Travel*, kind `teleport` (key 3000000 + the spell; fields `spell`, `items`, `reagent`; `dev/tools/
travel-data --teleports`): the class teleports of Forever's client (mage, druid) and the engineers' transporters and
the Crumbling Hearthstone; where they bring one from batch 14 (seven, unverified) or learnt in play by Core
(`src/Core/Data/Teleports.lua`, a watcher: the leap after the cast; kept by `Data.Learn` in `SaneUIData_Learned`,
the first piece of the data plan's learned data, 1c.1, built ahead). `Planner.lua`: `Teleports` (known spell and
reagent, or an item held that `C_Item.IsUsableItem` allows; its cooldown and `Planner.HEARTH`; its floor by
`Walk.Landing`, `landings`, and `Arrival` after the leap), `Hearth` with Astral Recall (`Planner.RECALL`), Frequent
Flier's faster flights (`Planner.Pace`, `Planner.FASTER`). The routes harness has `teleports.lua` for them.

The routing finalized (2026-10-22; the plan, *Built: the routing finalized*): read through with its docs and set
right. `Footing` keeps `seen` (the last look: map, u, v, at); a step faster than `Planner.HOP` yards a second is a
hop, and `Arrival(map, u, v, fu, fv, fz)` takes the portal whose trigger lay at the player's last place and height
(the Wizard's Sanctum's and Dalaran's Violet Citadel's portals cross 6 to 42 yards, under `Planner.LEAP`); after a
leap `Arrival` takes the nearest end or landing. A teleport's landing floor is a guess (`guess = true` in
`landings`): Teleport: Stormwind's lies in the Sanctum's closed cellar. `Find` keeps a walk between places apart
that ends only near as `{ near = points }`: none for the journey (`Measured`), drawn where it stays. `Walk.Forget`
runs when the route is switched off and on the walking data's stamp; both stamps' listeners are `ns.Guard`ed.

The coarse layer (2026-10-22; the plan, *The walking data*, *Built: the coarse layer*, and *The planner*, *Built:
walks priced by the coarse layer first*): far pins took seconds to plan, a walk many times its straight line given up
after `Search.MOST` rectangles. `dev/tools/walk-gates` (`saneui makewalkgates`) makes the set *Walking*'s field
`gates` from its blocks (each tile's gates into the next, the costs between two gates of a part; its check the CRC of
the blocks it was made from: `dev/tests/walk.py` fails on a stale layer, so after `dev/tools/walk-data` run it and
`dev/tools/data import dev/data/staging/walking-gates.jsonl --apply --take` too). `Gates.lua` reads it (`Gates.Tile`,
`Cost`, `Parts`, `Edges`, `Id`, `Ends`). `Search.lua`'s `Run` takes options: the two-level price (`near`: the start's
and the end's tiles rectangle by rectangle, gates elsewhere; `guide` from `Back`, the costs back from the end;
`exits` from `Out` for a start priced again, the plan's `memo`), the line along the coarse way (`way`: its tiles
only, steps aimed at its next gate, `Search.AIM`). `Search.Price` gives cost, rest and what `Search.Walk` needs;
`Planner.lua`'s `Find` prices the chosen journey's walks first and draws them once it stays. `Walk.lua` unpacks a tile
without its openings (`Walk.Links` works them out when needed; a rectangle's `surface` kept for the parts). Measured
with the routes harness outside the project (as 2026-10-21, above).

Clicks, pings and following (2026-10-23; the plan, *Follow me on the full map*, *Pings as on the game's minimap*, *A
double click for the map pin*): every click on the map and on a pin goes through `Canvas.lua`'s `Clicked` (a pin's
own first, `PinView.Act`; a double click within `Canvas.DOUBLE`, the map pin; else the map under it opens, else
`Ping.Send` at once, in the click: the game blocks a ping from a timer). `Ping.lua` (no frames) sends a place by its yards from the player through `Hybrid.PingAt`
(`Minimap:PingLocation`, a wider step for the moment where needed); the group's pings are not heard (the game
blocks an addon's callback for `MINIMAP_PING`), only the game's minimap draws them. The quest log's click moves the map (`Canvas.LookAt`), its `OnDoubleClick` pins. *Follow me*
(`followMap`): the box on the bar, `Canvas.Following`, `Canvas.Center`, the tracker's `Again`.

Not yet: a travel pin's ways under the mouse, search, the guide, the dungeons' three zooms, the
minimap's small parts (zone text, clock, mail, tracking), rares' spawn areas, patrol paths. Tests: `dev/tests/navigation.lua` (468
checks; 524 with the 2026-10-21 changes; 527 with the whole city below; 528 with no walk after a walk at a flight
point; 530 with the routing finalized; 551 with the coarse layer; 555 with no ride straight back; 584 with pings,
double clicks and Follow me; 599 with far sparkles), `dev/tests/walk.py`
(125; 130 with the
teleports' tool; 147 with the walking data's openings; 159 with the coarse layer).

## What is not there yet

1. **Core's data framework** has step 1a (`Doc/ideas/Data-build.md`): the sets (part of Core since 2026-10-21), `Data.Set`, `Get`,
   history, `OnStamp`, the scheduler; besides, `Data.Map()` (the places of Spawns, Places and Travel on a map)
   and the first learned data (`Data.Learn`: where a teleport brought one, 1c.1). Not built: `Data.Areas()`
   (1d.5), the Quests reader (1b, 1d.4), the characters' data such as rares seen (1c.4); the flight points a
   character found are Navigation's own (`Planner.lua`).
2. **Sets Navigation reads with entries** (2026-10-20): Zones, Places, Travel, NPCs, Objects, Quests (the old
   facts), Spawns, Walking (`dev/tools/map-data`, `travel-data`, `walk-data` and picked batches, `sources.toml`);
   **still empty:** QuestAreas, PatrolPaths, CreatureSpawns, Guides.
3. **Set *Tiles*:** built (2026-10-18): 736 tiles of the Eastern Kingdoms, 988 of Kalimdor,
   72 of Zephras Isle (2026-10-20, its own map 2991), read from the game's own map files; key continent × 4096 +
   row × 64 + column. The isle has its overview, outline, stitched map and walking data too (`--maps 2991` of
   `dev/tools/terrain-art` and `dev/tools/walk-data`).
4. **The walking data tool** (the set *Walking*): written (2026-10-20, `dev/tools/walk-data`), the set filled.
5. **The guide tool** that writes *Guides* from Core's quest data: not written.
6. **Core's windows:** click to expand (`Edge.lua` still fills on the mouse's coming), the holder, the board
   and Edit Mode layouts are not built. Navigation does not need the holder or the board: it catches the
   game's map itself (plan, *The game's map and minimap*) and lays out its full screen in `docked`.
7. **Art of our own** where the game has none: not made; planned as the dungeons' three zooms (2026-10-21,
   above). The dungeons' maps of today are the game's own art (Core's set *Dungeons*); their three levels and the
   zones' are made by `dev/tools/map-layers` (samples 2026-10-21: Westfall, Tanaris, the Deadmines, Zul'Farrak, the
   Hall of Thanes), the whole run queued once Saneroki has seen them. To come as well (Saneroki, 2026-10-21): our
   own pin icons (coloured renders) in place of the game's, and the route line as leather stitches in place of the
   golden line (`Doc/guides/interface-style.md`, *To redesign*).
8. **A travel pin's ways** (Saneroki, 2026-10-21, to come soon): the mouse over a flight point, a boat's or
   zeppelin's dock or the tram's entrance draws the ways from there on the map: the flights to the flight points
   the character has found (`Planner.Knows`), the boats', zeppelins' and the tram's ways; the flights from or to
   one not found yet a little differently (`Doc/ideas/Navigation.md`, *Map pins*).

## Open questions without a proposal

13 (guides wholly by the tool, or mended by hand), 14 (step hints), 15 (the step at the minimap), 17 (leveling
figures: Navigation or the library module). The other open questions are built as proposed when their step
comes.

## For a cloud session

- `lua5.1`, `luac5.1` and `rsync` must be installed before `dev/tests/run` or `dev/build --no-install` run.
- There is no game: every step's *done when* is Saneroki's; the session lists what the game needs
  (`/reload`, or a restart for a new addon folder or TOC change).
- Commits go to `main` (`CLAUDE.md`, *Workflow*).
