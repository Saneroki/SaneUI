# Sane UI: Atlas

**Status:** built with the world's tiles painted so far (2026-11-06: the Eastern Kingdoms whole, Kalimdor down to the row of squares 45; the rest shows the terrain until the job `worldtiles` has painted it and the pack is made again); not yet chosen art · **Since:** 2026-10-19 · **Addon:** `SaneUI_Atlas` · **Game:** WoW: Forever only (`X-SaneUI-Games: forever`: its painted world is Forever's; interface 16001, 120105)

## TL;DR
The painted map of the whole world for Navigation: both continents painted as one map, every road, building and
shore where the game has it, from a single house up close out to the whole world. With this module switched on,
Navigation's map has a third view, *Atlas*, next to *Parchment* and *Scrying*; without it, those two. It is
large (about 3 GB of art), so it is an addon of its own, loaded only when the view is first shown. The plan is
`Doc/ideas/Navigation.md`, *The painted view*.

**Planned (2026-10-21):** one smooth world in three levels, its style blending with the wheel: the terrain
repainted up close (built), every zone a free realistic painting of its mood and major places in the middle, and
the world (both continents, never one alone) a realistic render far out; no pins and no names in the paintings
(names are an overlay with switches); zone edges soft only where the player cannot go; dungeons in three zooms
(*Zones and continents reimagined*, *Dungeon, instance and raid maps in three zooms*).

## How to use
- **Switch it on or off:** tick or untick *Atlas* under *Sane UI* in the game's addon list; Navigation shows it.
  Switched off, the map offers Parchment and Scrying, and a map left in Atlas shows Scrying.
- **Nothing to set up:** choose *Atlas* with the buttons at the full map's top left, or the setting *Map view* on
  the page *Navigation*. It zooms three times closer than the other views.

## How it works
- **Loaded on demand** (`## LoadOnDemand: 1`): Navigation finds it in the addon list at login without loading it
  (there, switched on for this character, loadable) and loads it the first time the view is drawn. If it
  cannot be loaded, or fails later, its button and its choice go, the map shows Scrying, and the problem is in
  the error log (`/sane errors`).
- **The art:** blocks of 512 x 512 pixels, BLP2 DXT1 with mipmaps, at
  `Interface\AddOns\SaneUI_Atlas\Art\<continent>\<level>\<row>_<col>.blp`; the continent is the map's
  instance (0 the Eastern Kingdoms, 1 Kalimdor). Level 0 is the finest, 2048 pixels a terrain tile, so a block
  is a quarter tile (`TILE / 4` yards, `TILE` = 1600/3); each level up a block spans twice the yards. Rows and
  columns are counted as the terrain's tiles, from the north-west corner of the continent's grid of 64 x 64
  tiles: `column = floor((HALF - y) / span)`, `row = floor((HALF - x) / span)`, `HALF = 32 * TILE`, with `x`
  (north) and `y` (west) the world's yards.
- **The index** (`Index.lua`): `ns.INDEX = { levels = n, [continent] = { [level] = { [row] = "c,c,a-b" } } }`,
  the columns of a row that have a block; a block not listed is not there (open sea, or not painted yet), and
  the terrain shows. Read once when the addon is loaded into a set of the blocks, a number each; its strings
  are let go. What does not fit (a level past `levels`, a row or column past the grid, words) is passed over.
- **What Navigation asks** (`SaneUI.Atlas`, the module's table as Core's modules share them; `Painted.lua` in
  Navigation draws it): `Ready()`, `Levels()`, `Span(level)`, `Cells(level)`, `Cell(level, x, y)` (row,
  column), `Corner(level, row, column)` (x, y of the north-west corner), `Key(continent, level, row, column)`,
  `Has(key)`, `File(continent, level, row, column)`, `PIXELS`.
- **Where the art lives:** `dev/tools/atlas pack` writes the blocks and the index into `assets/optimized/Atlas/`
  (`Art/`, `Index.lua`) from a run's squares, never into `src/`: this folder holds the code only. Since 2026-11-06
  the run is the world's tiles (`dev/tools/map-layers tiles`, the GPU job `worldtiles`, in
  `assets/generated/world-tiles`), packed as painted, as the world viewer shows them:
  `dev/tools/atlas pack --out assets/generated/world-tiles --as-painted` with the game's files of map-layers' run
  (`--adt`, `--tables`, `--minimap` from `assets/generated/map-layers/state.json`, the first time). A square not
  painted yet has no block, and the terrain shows there; packed again, the blocks it no longer writes go.
  `dev/build` makes the addon from both (`BUILD/SaneUI_Atlas/`), and only once the index is there; rsync copies
  only what changed.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Atlas.toc` | The addon: needs Core (`SaneUI`), loaded on demand, stands under Sane UI in the addon list |
| `Atlas.lua` | The module's table: the index read into a set of the blocks, and what Navigation asks |
| `Index.lua` | Which blocks there are: made by `dev/tools/atlas` with the art, in `assets/optimized/Atlas/`, put here by `dev/build` |
| `Art/<continent>/<level>/<row>_<col>.blp` | The painted blocks: in `assets/optimized/Atlas/Art/`, put here by `dev/build` |

Tests: `dev/tests/navigation.lua` (the index, the grid, the level a zoom draws, loading it and falling back).

## History
- **2026-10-19:** the module: its format, the index read, what Navigation asks; Navigation offers the view Atlas
  while it is switched on and loads it when the view is first drawn.
- **2026-11-06:** the world's tiles packed in place of the lab's test pack: 1212 of 1456 squares, 20,977 blocks
  over the nine levels, 3.4 GB.
