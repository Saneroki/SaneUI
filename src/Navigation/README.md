# Sane UI: Navigation

**Status:** the minimap and the map in one window, without the map's data yet (pins, quest log, top bar, routes and the leveling guide come later) · **Since:** 2026-10-18 · **Addon:** `SaneUI_Navigation` · **Game:** WoW: Forever (interface 16001)

## TL;DR
Sane UI's minimap and world map are one window. Small, in the screen's top right corner, it is the minimap;
move the mouse into that corner and it fills the screen as the map. Both are the same map, drawn and handled
the same way, only larger, as the chat window is the same chat when it fills the screen. Each keeps its own
zoom and place. The map is drawn three ways at every zoom, from close up out to the whole world, both
continents always: *Parchment*, the world drawn by hand, Blizzard's zone maps in full joined into one map that
fades softly from zone to zone; *Scrying*, the land as the minimap shows it, its water cut away to a calm sea;
or *Overlay*, the old maps laid over the land. The game's own
minimap lies over it for its live dots; the game's map stays closed, and its keys open ours. The plan is in
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
- **Map view** (the buttons at the full map's top left, or the setting on the page *Navigation*): *Parchment*,
  *Scrying* or *Overlay*, for both views and at every zoom (in the code `sketches`, `terrain`, `overlay`).
- **The game's own windows:** the switches *Show the game's minimap* and *Show the game's map* on the page
  bring them back next to ours; the full map's dropdown *Classic windows* offers them too. The game's key to
  show or hide the minimap (in its key bindings) shows or hides our window.
- **Move and size it** in Edit Mode like every Sane UI window; the section *Expand window* on the page: whether
  the corner fills the screen, the animation, the background.
- `/sane map reset`: the window's first place and size.

## How it works
- **Three spaces, converted in one file** (`Coords.lua`): a map's own (0 to 1), the world's yards (X to the
  north, Y to the west), and the plane the map is drawn in (u = -Y to the east, v = X to the north), so the
  screen is the plane times a zoom. A map's box in the world comes from the game, asked once a session. The
  map tree is found at run time: the world map, its continents, their zones; a continent's rectangle on the
  world map puts the other continents and the world map itself into its plane, so one view zooms from a zone
  out to the whole world.
- **The camera** (`Camera.lua`), one for each view: the point in the middle, the zoom, whether it follows you,
  and the level the zoom shows (zone, continent, world), changing with some slack so it does not flicker. The
  wheel keeps the point under the mouse where it is; coming in over another continent at the world, the camera
  moves into that continent's plane, at the same size on the screen.
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
  (Core's data, the set *Tiles* in the pack *World*), up to 400 at once; under them, and alone further out,
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
  exploration provider places them. Over the terrain (*Overlay*) half see-through: far out the stitched map,
  up close the zones' maps. Under the mouse, at a continent or the world shown whole, the game's own highlight
  of the zone or continent there.
- **Marks** (`Marks.lua`): the player's arrow (Blizzard's world map arrow, turned to your facing) and the
  game's map pin, at a fixed size.
- **The game's minimap** (`Hybrid.lua`): over our map while the view follows you at one of its zoom steps,
  square, as large as the view's longer side so it covers all of it (the canvas cuts the rest), above the map's
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
  minimap), Edge fills the screen; laid out in its `docked` hook once it stands.
- **When something fails:** the module stands down: the keys go back to the game, its minimap back where it
  was, our window goes (`ns.GiveBack`); what may not be done in a fight waits for its end.

## Files

| File | What it holds |
|---|---|
| `SaneUI_Navigation.toc` | The addon: needs Core (`SaneUI`), stands under Sane UI in the addon list |
| `Navigation.lua` | The module's table (`ns`), its texts and settings, `/sane map`, `GiveBack` |
| `Coords.lua` | Map, world and plane; a map's box; the map tree and the links between continents; the terrain's grid; the player's place. No frames |
| `Camera.lua` | Where a view looks: middle, zoom, following, the level its zoom shows; drag, wheel, one map out. No frames |
| `Live.lua` | What the game tells while playing, read when it changes. No frames |
| `Canvas.lua` | The frame the map is drawn in: holder, layers, pools, layout, the tracker, the mouse |
| `Terrain.lua` | The terrain layer: the game's minimap textures from Core's set *Tiles*, and the overview |
| `Outlines.lua` | The zones that have an outline, by continent: made by `dev/tools/terrain-art`, not by hand |
| `Art.lua` | The view Parchment: Blizzard's world and continent maps, the stitched map, every zone's full map cut to its outline; the highlight under the mouse |
| `Marks.lua` | The player's arrow and the map pin |
| `Hybrid.lua` | The game's minimap over ours: taken, placed, given back |
| `Native.lua` | The game's map kept closed; its keys |
| `Window.lua` | Core's window: the top right corner, the full screen, the two cameras, the view buttons |
| `Art/Terrain/*.blp` | The terrain's overview: the game's minimap textures, smaller, the water cut away, made by `dev/tools/terrain-art` from the game's files |
| `Art/Zones/*.blp` | Each zone's outline over its map's box, made by `dev/tools/terrain-art` from the game's files |
| `Art/Sketches/*.blp` | The stitched map: every zone's full map on its continent, in the terrain's blocks, made by `dev/tools/terrain-art` |
| `Art/Edge.blp` | A map's box with its paper frame faded off, for Blizzard's world and continent maps |

Tests: `dev/tests/navigation.lua`.

## History
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
