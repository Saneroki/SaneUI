# Sane UI: Navigation

**Status:** the first step: the full screen map, dragged, zoomed, drawn three ways · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever (interface 16001)

## TL;DR
Sane UI's map, to take the place of the game's minimap, world map and quest log in one window. Built so
far: a window docked in the screen's top right corner; the mouse in that corner makes it fill the screen,
with the map of the continent you are on. Drag it, zoom it with the wheel, and choose how it is drawn:
Blizzard's map art, the terrain as the minimap shows it, or Blizzard's maps laid over the terrain. The plan
is in `Doc/ideas/Navigation.md`.

## How to use
- **Open the map:** move the mouse all the way into the screen's top right corner. The corner again, Esc,
  or the close button on its title bar brings it back. `/sane map` does the same.
- **Move and zoom:** drag with the left mouse button; the wheel zooms around the point under the mouse,
  from about the size of a tile of the terrain out to the whole continent.
- **Map view** (the buttons at the map's top left, or the setting *Map view* on the page *Navigation*):
  - *Blizzard maps*: the game's own map art: the continent, and up close the zone in the middle over it.
  - *Terrain*: the land as the minimap shows it. Far out, where it would be too much to load, Blizzard's map.
  - *Overlay*: the terrain with Blizzard's maps over it, half see-through.
- **Small, the window shows nothing yet:** the game's own minimap under it works as before. Move and size
  it in Edit Mode like every Sane UI window.
- **The section *Expand window*** on the page: whether the corner fills the screen, the animation, the
  background.
- `/sane map reset`: the window's first place and size.

## How it works
- **Three spaces, converted in one file** (`Coords.lua`): a map's own (0 to 1), the world's yards (X to the
  north, Y to the west), and the plane the map is drawn in (u = -Y to the east, v = X to the north), so the
  screen is the plane times a zoom. A map's box in the world comes from the game, asked once a session.
- **The camera** (`Camera.lua`): the point in the middle and the zoom; the wheel keeps the point under the
  mouse where it is; it stays on the continent.
- **The canvas** (`Canvas.lua`): the layers hang on one holder frame, laid out around an origin. A drag moves
  the holder only; a layout happens only when the zoom changes or the holder has moved past a margin. The
  layers' textures come from pools by key, so a tile that stays in view is not loaded again. Nothing runs at
  rest: the per-frame step exists only while the left button drags.
- **Terrain** (`Terrain.lua`): the game's own minimap textures, one per tile of the continent's 64 x 64 grid.
  Which file each tile shows is Core's data, the set *Tiles* in the pack *World* (read from the game's own
  continent files). Past 400 tiles in view the layer steps aside for Blizzard's art.
- **Art** (`Art.lua`): the game's map art (`C_Map.GetMapArtLayers`, `GetMapArtLayerTextures`) laid over the
  map's box, the last tiles cut at the art's edge.
- **The window** (`Window.lua`): one of Core's (kind `screen`, docked `TOPRIGHT`, Edge fills the screen),
  laid out in its `docked` hook once it stands.
- **When something fails:** the module stands down and the window goes (`ns.GiveBack`); nothing of the
  game's is taken yet.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Navigation.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Navigation.lua` | The module's table (`ns`), its texts, the setting *Map view*, `/sane map`, `GiveBack` |
| `Coords.lua` | Map, world and plane; a map's box; the terrain's grid and its keys; the player's place. No frames |
| `Camera.lua` | Where the view looks: middle, zoom, bounds; drag and wheel. No frames |
| `Canvas.lua` | The frame the map is drawn in: holder, layers, pools, layout, the mouse |
| `Terrain.lua` | The terrain layer: the game's minimap textures from Core's set *Tiles* |
| `Art.lua` | Blizzard's map art: the continent's, and the zone's up close |
| `Window.lua` | Core's window: the top right corner, the full screen, the view buttons |

Tests: `dev/tests/navigation.lua`.

## History
- **2026-10-18:** the first step: the full screen map from the top right corner, drag and zoom, the views
  Blizzard maps, Terrain and Overlay; Core's set *Tiles*.
