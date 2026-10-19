# Navigation: handoff for the session that builds it

Written 2026-10-18, before any code; what is built since is under *Built*, below. The plan is [Doc/ideas/Navigation.md](../ideas/Navigation.md);
where this note and the plan differ, the plan wins. Read the plan's *Design* and *Build order* first, then
the window guide ([windows.md](../guides/windows.md)) and the data guide ([data.md](../guides/data.md)).

## What it is

`SaneUI_Navigation` (`src/Navigation/`, its README says what is built). One window of Core's kind
`screen`, docked `TOPRIGHT`, takes the place of the minimap, the world map and the quest log:

1. Small: the minimap. Full screen (a click into the corner, Esc back): the map, the quest log on the left,
   a top bar (map selector, pin filter, the views Blizzard / Terrain / Overlay at 50 %).
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
| 2 | Map: full screen, zone to world, Blizzard's art, views, selector, the game's map kept closed | step 1; Terrain and Overlay need *Tiles* |
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

Not yet: pins of Live and of Core's data, the quest log, the top bar (selector, filter), search, routes, the
guide, dungeon maps and floors, the minimap's small parts (zone text, clock, mail, tracking). Tests:
`dev/tests/navigation.lua` (98 checks).

## What is not there yet

1. **Core's data framework** has only step 1a (`Doc/ideas/Data-build.md`): packs, `Data.Set`, `Get`,
   history, `OnStamp`, the scheduler. Not built: `Data.Map()` and `Data.Areas()` (1d.5), the Quests reader
   (1b, 1d.4), the characters' data such as known flight points and rares seen (1c.4).
2. **Every set Navigation reads has a schema and no entries:** Zones, Places, Travel, NPCs, Objects, Quests,
   Spawns, QuestAreas, PatrolPaths, CreatureSpawns, Guides, Walking. The import (*Three prompts*, 2) is next.
3. **Set *Tiles*:** built (2026-10-18), in the pack World: 736 tiles of the Eastern Kingdoms, 988 of Kalimdor,
   read from the game's own continent files; key continent × 4096 + row × 64 + column.
4. **The walking data tool** (pack Routes): not written; its format is still open (open question 1).
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
