# Navigation: handoff for the session that builds it

Written 2026-10-18, before any code. The plan is [Doc/ideas/Navigation.md](../ideas/Navigation.md);
where this note and the plan differ, the plan wins. Read the plan's *Design* and *Build order* first, then
the window guide ([windows.md](../guides/windows.md)) and the data guide ([data.md](../guides/data.md)).

## What it is

`SaneUI_Navigation`, a module that does not exist yet (no `src/Navigation/`). One window of Core's kind
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

## What is not there yet

1. **Core's data framework** has only step 1a (`Doc/ideas/Data-build.md`): packs, `Data.Set`, `Get`,
   history, `OnStamp`, the scheduler. Not built: `Data.Map()` and `Data.Areas()` (1d.5), the Quests reader
   (1b, 1d.4), the characters' data such as known flight points and rares seen (1c.4).
2. **Every set Navigation reads has a schema and no entries:** Zones, Places, Travel, NPCs, Objects, Quests,
   Spawns, QuestAreas, PatrolPaths, CreatureSpawns, Guides, Walking. The import (*Three prompts*, 2) is next.
3. **Set *Tiles*** (the minimap tiles' file IDs per continent and tile): no schema, no pack, no tool. The
   tool needs the game client's own files.
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
