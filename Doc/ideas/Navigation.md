# Navigation

The plan for the **Navigation** module (`SaneUI_Navigation`): the window, the map, the quest log, the pins,
the waypoint, the routes and the leveling guide. Built so far (2026-10-20): the window, both views, the canvas and
its controls, the terrain and the art at every zoom (the water cut away, the zones' maps cut to their outlines),
zones that light up and open by a click, the map moving with its window, the game's minimap over ours (cut to the
window's shape), the game's map kept closed; the pins of the game and of Core's data, quest areas, the party, the
quest log and the bar over the full map, routes to the map pin on foot, by flight, by boat and zeppelin and by the
hearthstone (`src/Navigation/README.md`). Not yet: trams, lifts and portals in the routes, the leveling guide,
dungeon maps, search, the minimap's small parts.

How to read this page:

- **Decisions** is what Saneroki decided: the *what*. It changes only with Saneroki.
- **Review** says what was checked against the game's code and what was corrected.
- **Design** is the *how*: the shape a building session follows, with the reasons. Facts marked
  *verified* were read in `references/` on 2026-10-16 (Blizzard's code for this client, which loads the
  Mainline map code as the game type `camelot`); *to try* needs the game.
- **Build order** cuts the work into steps that each end in something tried in the game.
- **Reference:** the pin catalogue, one pin per thing, dungeon maps, the map selector.
- **Open questions:** each has a proposal. What is not answered when its step comes is built as proposed.

The window system it stands on is described in `Doc/ideas/Windows.md` (the plan) and the window system
guide `Doc/guides/windows.md` (how to build a window); the data it reads in `Doc/ideas/Data.md`.

# Decisions (Saneroki)

## What it replaces

Navigation takes over three things of the default UI with one window of its own, designed from scratch:

- the **minimap**,
- the **world map**,
- the **quest log** (in this client the map and the quest log are one Blizzard window).

The native minimap and the native map/quest log window are **hidden by default**, because our window
takes their place. The module's settings page has one toggle for each (*Minimap*, *Map*) to show them
again, for players who want the originals next to ours.

Like every Sane UI module, when a part of Navigation errors or breaks, that part falls back to the
Blizzard default (CLAUDE.md, *Resilience*): if our window cannot be shown, the native minimap and map
come back.

## The window

One window on Core's window system, behaving like the Social module's chat window:

- **Docked in the top right corner** of the screen by default (Core's zone `TOPRIGHT`), arranged and
  sized in Blizzard's Edit Mode like every Sane UI window (`Doc/ideas/Windows.md`).
- **Fills the whole screen from its corner:** a left click into the top right corner of the screen (or
  only the mouse coming there, with *Click required to expand window* not ticked), and again to come
  back; Esc brings it back too. The small window is the minimap, the full screen is the map with the
  quest log.
- Its place, size and what it was left as are kept by Core.

## One map, two views

Minimap, world map and quest log are one window, so there is **one map**. The small docked window (the
minimap) and the full-screen window (the world map) show the same map with the same render.

- **Rendered as terrain plus Blizzard's map art:** a mix of the minimap look, which renders the terrain
  from the game's own minimap tiles, and the official native maps. Navigation is built with our own code
  and, where it needs data, our own data, kept and handled by Core's database system (*Our own data*).
- **Navigation as on Blizzard's map:** drag to pan, scroll wheel to zoom. On the small window the
  wheel zooms from the usual minimap range all the way out to the whole world and back in, so the
  minimap is already a world map.
- **Independent views:** the small window and the full screen each keep their own zoom and position.
  Expanding to full screen and back returns each to where it was.
- **The same look and behaviour (Saneroki, 2026-10-19):** the minimap and the full screen map look and behave
  exactly the same; the minimap is only a smaller part of the screen, as the chat window is the same chat when
  it fills the screen. So the small view draws our own map too, with the same views and the same mouse; the
  game's minimap lies over it only for its live dots, its own ground switched off.
- **Views at every zoom (Saneroki, 2026-10-19):** Blizzard maps, Terrain and Overlay can be chosen at any zoom,
  from close up out to the whole world; none of them changes into another by the zoom.
- **Zones as on Blizzard's map (Saneroki, 2026-10-19):** the zone under the mouse lights up and a click opens
  it; right click one map out.
- **Zone-shaped maps, the water cut away (Saneroki, 2026-10-19):** Blizzard's maps are cut to their zones'
  outlines, not drawn as squares; the terrain's water is cut away, so the land stands as a clean silhouette.
- **Always the full map (Saneroki, 2026-10-19, replacing *undiscovered parts dark* of the same day):** the
  terrain and the drawn maps always show every detail, discovered or not; nothing is hidden for now.
- **One map of the world (Saneroki, 2026-10-19):** both continents are visible at every zoom; the world and
  continent maps are our own, stitched from Blizzard's zone maps, their edges fading softly into each other so
  the whole reads as one coherent map. The view *Blizzard maps* is called **Sketches**: a hand-drawn world.
- **A painted third view (Saneroki, 2026-10-19, replacing *a reinterpretation* of the same day):** Sketches and
  Terrain stay exactly as they are; Blizzard's art and the game's terrain are not redrawn. The local image
  models paint a **third view of its own** instead of Overlay: one coherent map of the whole world, as by one
  hand, made from Sketches, Terrain and what the game's files say lies where (roads, buildings, the ground,
  the places' names) and the zones' briefs (their peoples, biomes and buildings). It looks like painted art, not
  like a screen capture of the terrain, and still shows clearly where the buildings and the roads are; the
  roads stand out above all, and the gates and buildings of Stormwind and Orgrimmar must be right.
- **The views' names (Saneroki, 2026-10-19):** immersive and true to the world, never technical words on the
  buttons: **Parchment** (Blizzard's maps, was *Sketches*), **Scrying** (the terrain), **Atlas** (the painted view).
- **Atlas, a module of its own; Overlay gone (Saneroki, 2026-10-19):** the painted view's art is the addon
  `SaneUI_Atlas` (`src/Atlas/`), loaded on demand. Navigation finds it at login without loading it: installed and
  switched on, the map offers **Parchment, Scrying, Atlas**; not found, **Parchment and Scrying**. The view
  *Overlay* is gone (its button, its choice, its code); the default view is Scrying, and a saved view that is not
  offered (Overlay, or Atlas without its module) falls back to it. The code's keys: `sketches`, `terrain`, `atlas`.
- **Life on the sea (Saneroki, 2026-10-19):** in the painted view the Maelstrom turns between the continents,
  and ships, giant turtles, sea dragons and squids roam the water, each a short looped animation, seen on the
  world map.
- **Close up and far out (Saneroki, 2026-10-19):** the painted view holds its quality and small details from a
  single building up close to the whole world far out: many small detailed pictures stitched together like the
  game's own tiles, with coarser levels for the far views, so it stays sharp up close and light on the whole world.
- **Entrances and ways out are pins (Saneroki, 2026-10-19, replacing the same day's ask to paint them):** caves,
  mines, the entrances of dungeons and raids and the ways from one zone into the next are shown by map pins, not
  painted into the view.
- **The look: a photorealistic render (Saneroki, 2026-10-19, after the five styles below):** a modern game
  engine's render of the land seen from straight above, a mix of detail and a precision a map can use. Within
  that one look **every zone has its own atmosphere**, from its lore: its light, air and colours and the state
  of what stands there (the volcano's land volatile, smouldering and dangerous; Stormwind and its farmland
  bright, safe and friendly; the haunted wood a cold dusk), and the buildings, roads and places stay exactly
  where the terrain has them.
- **Only what the game has (Saneroki, 2026-10-19):** what the originals (the game's terrain and files) show is
  painted, nothing more: the model put water around Blackrock Mountain, where there is ash and lava. So the
  words of a square say what the game has in it (its water, lava and slime, its ground), never a zone's
  features that lie elsewhere, and every painting is checked against the game's water and lava before it is
  taken.
- **Faithful above all: what cannot be walked looks it (Saneroki, 2026-10-19):** the painted view shows the world
  as the game has it, nothing added: no lake, village or forest where the terrain has none. Above all a mountain
  stays a mountain: where the terrain is too steep to walk, the painting shows bare rock and cliffs, so a player
  sees at once that the way is closed (a forest says "you can walk here"). Found and measured in the Atlas lab
  (*The lab* below), and kept by its words.
- **Three times closer (Saneroki, 2026-10-19):** the painted view zooms about three times closer than the map
  does now, single buildings large; zoomed out it is the same pictures, smaller. Quality before speed, but all of
  it made within a couple of days on this computer.
- **Full detail, 4x (Saneroki, 2026-10-19):** the finest level at 2048 pixels a tile, four times the terrain's
  detail (*Size* below).
- **Dark zones stay dark (Saneroki, 2026-10-19):** a zone as dark as the game has it (Duskwood's endless dusk)
  is painted that dark; its atmosphere is not brightened for the map's sake.
- **The look before: on the terrain, its style open (Saneroki, 2026-10-19):** of the five looks of the first pilot,
  *stylised game art* (bold, saturated colours, chunky trees, painted rocks, glossy water) came first; painted
  on the terrain close up it felt too cartoonish, like pixel art. Wanted: a rough, old, grimy, realistic look that
  stays true to the old World of Warcraft; five different styles on four subjects to choose from
  (`dev/imagegen/sets/maps-styles/`: grimy realism, the original game's painted textures, high-fantasy matte
  painting, an old oil painting, a photorealistic render; tried 2026-10-19: all five keep the layout up close; the
  whole world painted in one picture drew the continents larger than they are, so the far levels are made
  from the close ones, never painted on their own). The **terrain is the base**: the painted view is the terrain repainted in that look, every building, street,
  tree and shore where the terrain has it, so it serves as the map of one's close vicinity, zoomed in as close as
  the minimap, single buildings clear. The painted continent maps of the pilot work only far out.
- **Routes, later (Saneroki, 2026-10-19):** flight paths, and the ships' routes as a red dotted line, shown when
  one takes a ship or looks the routes up, the dots running from one harbour to the other. They are interactive
  parts of the map, drawn by code, never painted into the view's pictures. Not now: after the painted view.
- **The map moves with its window (Saneroki, 2026-10-19):** on the way to the full screen and back the map grows
  and zooms with the window, not hidden and shown; Core's windows let what they hold go with the motion.
- **Follows the player:** when the player moves, the map centres on the player.
- **The minimap fills its window (Saneroki, 2026-10-20):** the small window shows the map over its whole shape,
  not a square in it: our map fills it, and the game's minimap over it (for its live dots) is cut to the window's
  shape, so it covers all of it and nothing past it.

## Full screen

When the window fills the screen:

- **Classic windows** (Saneroki, 2026-10-16): Core's dropdown in the full screen's title bar lists the
  **native minimap** and the **native map and quest log** window. One chosen, the window goes back to the
  minimap and the native one is shown.
- **A classic window is kept, ours always in the corner (Saneroki, 2026-10-20):** a classic window chosen is kept
  (the game's map opens by its keys from then on, the game's minimap stands in the top right corner), ticked in the
  dropdown and chosen again to come back; whatever is chosen, the mouse pushed into the top right corner, where
  the minimap is docked, always fills the screen with our map.
- **Quest log on the left side** of the screen; the map takes the rest.
- **A bar on top** of the map with:
  - **Map selector:** pick a region or a dungeon, and the map shows it (*Map selector*). Dungeons are
    drawn the same way as the regions.
  - **Pin filter,** a dropdown with a checkmark per pin type. A checked type is shown on the map, an
    unchecked type is hidden.
  - **Three view buttons** next to the dropdown:
    1. **Sketches:** Blizzard's own map art (was *Blizzard maps*).
    2. **Terrain:** the terrain render.
    3. **Overlay:** the terrain, with the Blizzard maps drawn over it at 50% transparency; to be replaced by the
       painted view once its art is made (*A painted third view*).

  The Blizzard maps and the terrain must fit together exactly: the Blizzard map of Stormwind lies on
  Stormwind and its places in the terrain.

## Map pins

- **Our own database of map icons,** in Core's database system: quests, NPCs and objects, services,
  travel, places, rares, treasures and books. Shown on both views. The pin types and their data: *Pin
  catalogue*.
- **Herb and ore icons** are Blizzard's own profession tracking icons.
- **Rares:** Blizzard's own rare marker, and on a click the area where the rare can spawn.
- **One pin per thing (Saneroki, 2026-10-16):** the same quest, NPC or place can be known several ways
  (our shipped data, learned in play, shared by the guild, the game live). One pin is kept for it, not
  several (*One pin per thing*).
- Every pin type can be switched on and off with the pin filter (see *Full screen*).
- **Always on top (Saneroki, 2026-10-20):** pins, quest areas, the route and every other notation on the map
  stand over the map in every view and at every zoom, never behind it (the painted Atlas, the art, the terrain,
  the game's minimap all lie under them).

## Our own data

**Decision (Saneroki, 2026-10-16):** the map system works fully on its own: Sane UI's own database and art,
the game's own art and the game's own API.

- **Data in Core (Saneroki, 2026-10-16):** pin locations, spawn places, patrol paths, travel, places and
  the other map data are saved and handled by Core's database system (`Doc/ideas/Data.md`), not by
  Navigation: it ships them in its load-on-demand packs, and Navigation only reads them (`Data.Set`).
- **Route data on demand, by Core (Saneroki, 2026-10-16):** the walking data for routes is Core's data too,
  in a pack of its own that Core loads when the first route is asked for, never at login.
- **Art:** the game's own art first, loaded by path, atlas or file ID: its map legend's atlases for quests,
  rares and travel, its vignette atlases, its tracking icons. A picture of our own only where the game has
  none (a dungeon without a map, perhaps the meeting stone), drawn for Sane UI, kept in the module's own
  `Art/` folder and converted as `Doc/guides/images.md` says.
- **Living alongside:** other addons a player has installed keep working, and we leave their frames alone.
  Their own pins on Blizzard's world map simply are not seen, since that window stays closed.

## Waypoint and route

- **Blizzard's pin system:** the player drops a pin anywhere on the map (the game's own map pin, the
  same one the native map sets).
- **Route to the pin:** a path that correctly goes around obstacles such as mountains, and that uses
  **flight paths and ships**.
- **Look:** instead of a dotted line, a **thin golden line pulsing towards the pin**.

## Leveling guide

**Decision (Saneroki, 2026-10-16):** Navigation leads the player through leveling step by step, the fastest
way, built with our own code. The guides are data in Core's database framework (`Doc/ideas/Data.md`, set
*Guides*); Navigation reads them and shows them, as it does the rest of the map data (*Our own data*).

**What a guide is:** one leg of the way for one side, sometimes for one race or class, over a band of
levels in one region, naming the guide that follows. Each step says:

- **where:** a place on a map, and how near counts as there; several places for a way to walk;
- **what:** accept, complete or turn in a quest; talk to an NPC; kill creatures; collect items; train,
  buy, sell, repair; bind the hearthstone, use it, fly, learn a flight path; use an item or a spell;
- **for whom:** a class or race (a step, or one line of it);
- **done when:** the game says so: a quest in the log, done or turned in; a level or XP reached; items or
  money in the bags; a zone reached. A hint the game cannot check is ticked by hand.

*Proposal* of what Navigation does with it:

- **The current step and the next few:** full screen in the quest log's place on the left; small, a line
  at the minimap (open).
- **The step's place is the waypoint:** the golden route leads there, with flights and ships (*Waypoint
  and route*); the map shows the step's places, and the quest's givers and areas from the quest data.
- **Steps tick themselves** from the game's events; skip and back by hand.
- **The right guide** is chosen by side, race and class; at its end the next one follows by itself.
  One guide per leg: what differs between players (dungeons in the way or not) is a switch the steps read,
  not a guide of its own (open).
- **A button for the step's item** (a quest item to use), a secure button changed only out of combat.
- **Leveling figures:** XP per hour, time to the next level, time per guide (or in the planned library
  module for the character's journey, its name open).

**Step texts:** Navigation writes each step's text from the facts (*Talk to Kaltunk: accept Your Place
in the World*), with the names from Core's data and the game, so it can be in the game's language. Hints
the facts do not give (what to watch for, what to keep) are written for the step or left out (open).

**Feasibility (2026-10-16):** a guide is made by a tool of ours from Core's quest data (givers, takers,
objectives, levels, places, chains) and the map data, so it reaches as far as that data does, both sides
and every level. How good the tool's order of steps is, and how much needs a hand after it, is measured
once the tool exists (open question 13).

## Earlier notes (Doc/ideas/Maps.txt)

Older notes on the same idea, kept here so nothing is lost. Where they differ from the above, the above
is the newer decision:

- Minimap in the **top centre** (now: top right).
- **Hot corner:** moving the mouse to the top centre and holding it there for a few ms makes the minimap
  fill the screen (now: Core's corner of the top right, like Social).
- In that full-screen view a **right-click zooms out** from the minimap view to the zone map, a second
  right-click to the world map (now: the scroll wheel zooms; right-click as well: *Open questions*).
- **Black minimap:** if the map cannot show (no terrain or map for the place), the minimap is black.

# Review (2026-10-16)

A full pass over this page before any code, by a Claude session: every claim of the earlier feasibility
notes checked against Blizzard's code for this client (`references/BlizzardInterfaceCode`), against Core
and its window guide, and against the data plan.

## What holds

- **Everything asked for is doable;** nothing is blocked outright. The verdict per feature is below.
- **The game's API is all there** (*verified*, `Blizzard_APIDocumentationGenerated`), and none of the
  functions Navigation needs is protected or marked as giving secret values: `C_Map` (map and world
  positions, art layers, children, map links, the user waypoint), `C_MapExplorationInfo`, `C_SuperTrack`,
  `C_Navigation` (the game's on-screen marker), `C_QuestLog` (quests on a map, objectives, watch,
  abandon), `C_TaxiMap`, `C_AreaPoiInfo`, `C_VignetteInfo`, `C_Minimap` (`GetViewRadius`,
  `SetDrawGroundTextures`, `SetIgnoreRotateMinimap`, `IsInsideQuestBlob`, tracking), `UnitPosition`,
  `GetPlayerFacing`, `IsIndoors`, `GetInstanceInfo`, the `Line` widget and the `TextureCoordTranslation`
  animation. The few restricted ones nearby (`C_Map.OpenWorldMap`,
  `C_Navigation.GetNearestPartyMemberToken`) Navigation does not need.
- **The small view's trick is Blizzard's own** (*verified*, `Blizzard_HybridMinimap`): a map under the
  native `Minimap`, the minimap's ground switched off (`C_Minimap.SetDrawGroundTextures(false)`), its
  rotation ignored (`C_Minimap.SetIgnoreRotateMinimap(true)`), the scale matched each frame from
  `C_Minimap.GetViewRadius()`. The native minimap keeps drawing its live dots and the arrow.
- **Terrain from the game's minimap tiles** is doable: the tiles by FileDataID (paths to these files do
  not load on this client, only IDs; how many, our tool counts), placed by each map's corners in world
  yards (`C_Map.GetWorldPosFromMapPos` at 0,0 and 1,1, checked by a round trip).
- **Walking data shipped packed and opened per region on demand** is doable: the client can unpack
  (`C_EncodingUtil`), the search runs as a job in Core's scheduler and waits in a fight, and opened regions
  are let go when no route is asked for. It loads on demand, never at login. Its size is measured once our
  tool has made it.
- **The data side fits Core's plan:** the packs World, Spawns, Quests, Guides and Routes, and the readers
  `Data.Map` and `Data.Areas` (`Doc/ideas/Data.md`).
- **Taking over the game's frames is possible without changing them** (*verified*): every way the game
  opens its map ends in `ShowUIPanel(WorldMapFrame)`, so one `OnShow` hook sees them all; neither
  `WorldMapFrame` nor `Minimap` is a protected frame; Edit Mode moves only `MinimapCluster`, and no
  Blizzard code places `Minimap` itself.

## Corrected

1. **A canvas of our own, not Blizzard's map canvas.** The earlier notes put both views on
   `MapCanvasFrameTemplate` with Blizzard's pin providers. That would fail in a fight:
   - every pin the canvas takes from its pool calls `SetPassThroughButtons`, and the shared POI pins
     `SetPropagateMouseClicks` (*verified*: `Blizzard_MapCanvas.lua` `AcquirePin`,
     `MapCanvas_DataProviderBase.lua` `CheckMouseButtonPassthrough`, `SharedMapPoiTemplates.lua`). Both are
     protected functions with restrictions, and nothing guards them in combat. A canvas made by an
     addon runs its pins under the addon's taint, so in a fight the map would raise *action blocked*
     errors, and the map must work in fights.
   - Its zoom levels come from the map's art layers and are rebuilt on every map change; the seamless zoom
     from the minimap's range to a continent would mean bending it (levels appended, an unclamped call).
   - Its quest pins follow the world map's open quest (`QuestMapFrame_GetFocusedQuestID`), placing the
     waypoint needs a callback only the world map fires, and `MapCanvas.MapSet` is announced to everyone
     from every canvas.

   Navigation draws on a canvas of its own (*Design*, *The canvas*) and takes from Blizzard what is safe:
   the API for the data, the art by file ID and atlas, the templates for the controls.
2. **The wheel never steps to the parent map** on Blizzard's canvas: it only zooms; the parent map is a
   right-click, on the world map only. Our canvas steps from zone to continent to world by its zoom alone.
3. **Dungeon entrances** do not come from the game here: Blizzard's dungeon entrance provider is not
   loaded in this client (`EncounterJournalDataProvider.xml [ExcludeLoadGameType camelot]`), nor is the
   Adventure Guide. `C_EncounterJournal.GetDungeonEntrancesForMap` is documented but may give nothing
   (*to try*). Entrances come from Core's data (*Places*).
4. **No continent IDs are known in advance:** the client's code names none (no world, Kalimdor, Eastern
   Kingdoms or Zephras constants). Navigation finds them at run time from the root of the map tree
   (`C_Map.GetFallbackWorldMapID`, `C_Map.GetMapChildrenInfo(root, Enum.UIMapType.Continent, true)`) and
   hard-codes no map ID. In this client the root is a map of type *World*, not *Cosmic* (a Camelot
   override in `Blizzard_WorldMap`).
5. **Rotation:** the native minimap is told to ignore rotation while ours shows
   (`C_Minimap.SetIgnoreRotateMinimap`), as Blizzard's hybrid minimap does. The player's `rotateMinimap`
   setting is never changed (Sync keeps it).
6. **Values that may be hidden:** the API documentation marks none of the position functions secret, but
   positions, view radius and facing can come hidden on this client. Everything is read through
   `Core.Plain`, and the map has a state for *position unknown* (*Design*).
7. **Known flight points:** the map's taxi list calls every node known on this client; only the flight
   master's map is reliable (`TAXIMAP_OPENED`, `C_TaxiMap.GetAllTaxiNodes`), kept per character.
8. **The window** follows Core as it is now: nine zones, the kind `screen` (no title bar while small,
   Esc brings it back from full screen), a click into the corner by default (Core's *Click to expand*, not
   built yet: today the mouse's coming alone fills the screen).
9. **The leveling guide's item button** is a secure button: a window that holds one is locked in a fight
   (window guide, *Combat*). It must not be a child of, nor anchored to, the map window (*Design*,
   *Leveling guide*).

## Verdict

| Feature | Verdict | Main limit |
| --- | --- | --- |
| Docked window, resizing, full screen at the corner | Yes | None: Core does it for Social. |
| Hiding the native minimap and map/quest log, toggles | Yes, with care | In a fight the game's map can only be closed in a way still to try (*The game's map and minimap*). |
| One render for both views, drag and wheel zoom down to the world | Yes | Far out, terrain means many textures: Blizzard's art there. |
| Live minimap dots (tracked herbs and ore, party, town tracking) | Yes, in the small view only | The engine draws them only on the native minimap, which follows the player at its own zoom steps. |
| Map follows the player; separate zoom and position per view | Yes | Positions may be hidden in some places (*to try*). |
| Quest log on the left in full screen | Yes | Our own list; Blizzard's is bound to its map window. |
| Map selector for regions and dungeons | Yes | No terrain inside dungeons: Blizzard's map art only there. |
| Pin filter dropdown | Yes | None. |
| Three views, Blizzard maps fitting the terrain | Yes | Painted art is not exact to the yard; the overlay needs each zone cut out. |
| Our own pin database | Yes | Core's data framework must be built first. |
| Herb and ore icons | Yes | None: Blizzard's own icons. |
| Blizzard's map pin | Yes | None. |
| Route around obstacles, with flights and ships, golden pulsing line | Yes, the largest job | Walking data, made by our tool; its size to measure. |
| Leveling guide | Yes | Guides made by our tool from Core's quest data; the item button must stay out of the map window. |
| Minimap rotation | No, north-up only | Blizzard's own hybrid minimap does not rotate either. |

## Is it a good brief now?

Before this pass the page said well *what* to build and why, but not *how*: one coordinate system, the
layers and their order, what runs every frame and what may not, the contracts with Core's window and data
systems, the fallback, the tests, and an order of work that proves the risky parts first. The canvas
choice would have failed in a fight. *Design* and *Build order* below give those; a building session
follows them and corrects this page where the game disagrees.

# Design

## Rules this module keeps

The project's rules (CLAUDE.md, `Doc/guides/addon-standards.md`, `gui-development.md`, the window
guide), and these for Navigation in particular:

- **Logic knows no frames.** Coordinates, the camera, the pin index, gathering overlaps, the filter, the
  planner and the search are plain Lua over plain tables, tested outside the game. The views read them and
  draw; a click calls the logic.
- **One coordinate system** for everything drawn (*Coordinates*): converted in one file, nowhere else.
- **Nothing written into Blizzard's frames, functions or tables.** Their widget methods are called
  (place the `Minimap`, hide `MinimapCluster` by alpha), never their fields set; hooks only after
  (`hooksecurefunc`, `HookScript`); everything taken is given back by `GiveBack`.
- **Nothing at rest:** no `OnUpdate` while nothing moves. The one step that runs every frame is the small
  view following the player, and it is O(1) (*Performance*).
- **Draw only what is in view,** from pools, keyed so that what stays in view is not touched again.
- **Work in steps:** anything that can take more than a frame (an index, a route) runs as a job in Core's
  scheduler (`Doc/ideas/Data.md`, *Performance*: one budget for all, nothing in a fight), not in a
  scheduler of Navigation's own.
- **The game first:** what the game tells live beats the database (*One pin per thing*, point 6); names
  come from the game, so they are in the player's language.

## Shape and files

```
 Core: Window (kind screen, Edge, Edit Mode) Core.Data (World, Spawns, Quests, Guides, Routes)  the scheduler
            │                                         │                                            │
 ┌──────────┴─────────────────────────────────────────┴────────────────────────────────────────────┴──┐
 │ Navigation                                                                                          │
 │  logic, no frames:  Coords · Camera · Index · Cluster · Filter · Planner · Search · Guide           │
 │  sources:           Live (player, group, quests, flights, waypoint, vignettes, POIs) · Pins (data)  │
 │  views:             Canvas with its layers · QuestLog · TopBar · GuideView · Window                  │
 │  the game's frames: Hybrid (the native Minimap in the small view) · Native (the world map closed)    │
 └─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

| File | What it is | Frames |
| --- | --- | --- |
| `Navigation.lua` | The module's table, its switches, texts, `/sane map`, `GiveBack` | no |
| `Coords.lua` | Map ↔ world ↔ screen; world boxes of maps; the terrain grid; the map tree (continents found at run time) | no |
| `Camera.lua` | A view's state: centre, scale, follow; zoom around a point; which map is shown at a scale | no |
| `Index.lua` | Pins by area: the grid per continent, what lies in a rectangle | no |
| `Cluster.lua` | Pins on screen that overlap, gathered into one marker; the cap | no |
| `Live.lua` | What the game tells while playing (*Live*): the player, group, quests, flights, waypoint, vignettes, POIs | no |
| `Pins.lua` | Pin records from Core's data and from `Live`, merged, filtered | no |
| `Canvas.lua` | The canvas frame: holder, layers, input (drag, wheel, clicks), the per-frame step | yes |
| `Terrain.lua` | The terrain layer: tiles in view, pooled | yes |
| `Art.lua` | Blizzard's map art, explored areas, cut to the zones' outlines (the view Parchment) | yes |
| `Painted.lua` | The view Atlas: the module `SaneUI_Atlas` found, loaded when first drawn, its blocks by zoom | yes |
| `PinView.lua` | The pin layer: pin buttons, clusters, tooltips | yes |
| `Areas.lua` | Quest areas, spawn areas, patrol paths | yes |
| `Hybrid.lua` | The native `Minimap` in the small view, and back | yes |
| `Native.lua` | The game's world map kept closed, its openers caught, and back | yes |
| `QuestLog.lua` | The quest list on the left | yes |
| `TopBar.lua` | Map selector, pin filter, the three views | yes |
| `Planner.lua` | The journey: walking, flights, ships, hearthstone | no |
| `Search.lua` | The path search on Core's walking data, in steps | no |
| `Route.lua` | The golden line | yes |
| `Guide.lua`, `GuideView.lua` | The leveling guide: the step, its checks; its view | no; yes |
| `Window.lua` | The Core window: small and full, the two cameras, the layout of the full screen | yes |

One file per job; a file that grows past one job is split. The tests are `dev/tests/navigation.lua`.

## Coordinates

Three spaces, converted only in `Coords.lua`:

| Space | Units | Who uses it |
| --- | --- | --- |
| **Map** | `(uiMapID, x, y)`, 0 to 1 from the map's top left | the game's API, Core's data, the waypoint |
| **World** | `(continent, X, Y)` in yards: the continent (instance) and position `C_Map.GetWorldPosFromMapPos` gives | terrain, map art placement, pins of several maps at once, merging, routes |
| **Screen** | pixels in the canvas, from its centre | drawing only |

- **A map's world box:** its corners in world yards from `C_Map.GetWorldPosFromMapPos(map, 0,0)` and
  `(1,1)`, checked by a round trip through `C_Map.GetMapPosFromWorldPos`; kept for the session (a few
  numbers per map, asked once). A map without a box (some dungeons, the world map itself) is drawn in its
  own map space (*Maps without a world box*).
- **The axes:** world X grows to the north and Y to the west, so on screen *up* is +X and *right* is −Y.
  Written once, tested; never again anywhere else.
- **The terrain grid:** the client's own grid of minimap tiles, 64 × 64 per continent, each 1600/3 yards
  wide, the middle at 32; a tile's column and row from world position: `col = floor(32 − Y / tile)`,
  `row = floor(32 − X / tile)`. To be checked against the tool's table in step 0 before anything is built
  on it.
- **Continents** each have their own world space. The world view (all continents) is in the world map's
  own map space, with the continents placed by `C_Map.GetMapRectOnMap`.

## The canvas

### Camera

- A camera is a centre (continent, X, Y), a scale (yards per pixel) and `follow`. Each view has its own
  (the decision *Independent views*); the window swaps them when it fills the screen and back.
- **Which map is shown** (for the selector, the art and the live data) follows from the scale: the zone
  the centre lies in up close, its continent further out, the world beyond; with some slack (about 15 %)
  so that it does not flicker at the border. So the wheel walks from the minimap's range to the world
  without a jump, in one space per continent: that is what *zooming all the way out* means here.
- **Zoom:** the wheel multiplies the scale by about 1.25 per notch, around the point under the mouse
  (that point stays where it is), at once, as on Blizzard's map (built so: its world map zooms instantly).
  Nearest: the native minimap's nearest step. Farthest: the whole world.
- **Follow:** on in both views at first; a drag turns it off, as Social stops following new messages
  when scrolled up; it comes on again after some seconds without the mouse on the map (the setting *Follow
  again after*; in the full screen the mouse is always on the map, so there it stays where it was dragged).
- **Position unknown** (hidden, a place without a map): the camera stays where it was, the player arrow
  hides, and nothing errors.

### Layers and how they move

```
 canvas (clips its children)
  └─ holder (anchored to the canvas' centre; moved by the camera)
       ├─ 1 ground      black, or the sea's colour                 one texture
       ├─ 2 terrain     the game's minimap tiles                   pooled textures, keyed by tile
       ├─ 3 art         Blizzard's map art (and the overlay)       pooled textures, keyed by map and tile
       ├─ 4 explored    unexplored areas, darkened                 pooled textures
       ├─ 5 areas       quest areas, spawn areas, patrol paths     shaded cells, outlines, lines
       ├─ 6 route       the golden line                            pooled Lines
       ├─ (native Minimap: small view only, between 6 and 7, see *Small view*)
       ├─ 7 pins        database and live pins, gathered markers   pooled buttons
       └─ 8 player      group members, the player arrow            textures
```

- **Placing:** what is in view is placed relative to an *origin*, the camera's centre when the view was
  last laid out: `offset = (world − origin) / scale`, turned to screen axes. The holder stands at
  `(origin − centre) / scale`. So **a pan or a follow step moves one frame** (the holder: one `SetPoint`),
  whatever is drawn.
- **Laid out again** only when the scale changed, or the holder has drifted past a margin (a quarter of
  the view): then the origin becomes the centre, the holder goes back to zero, and each layer asks what is
  in view now (with a margin of one tile) and places it.
- **Pools, keyed:** a tile, an art tile or a pin that stays in view keeps its texture or frame and is only
  moved; a file is never loaded twice while in view (textures load late, and a reload shows as a flicker).
- **Clipping:** the canvas clips its children (`SetClipsChildren`), so nothing draws outside the window.
- **Frame levels** are set per layer once; pins stand above the native minimap so they can be clicked.

### Input

- **Drag** with the left button pans (and stops following). **Wheel** zooms. **Right-click** steps out
  one map, as Blizzard's map does (proposal, *Open questions*). **Ctrl-click** sets or clears the map pin,
  as on Blizzard's map. A click on a pin does the pin's thing.
- **Small view and the native minimap:** the native `Minimap` must keep the mouse's movement for its own
  tooltips over its dots, and our canvas needs the wheel and the drag. An overlay of our own above the
  minimap takes wheel and clicks and lets the movement through (`SetPropagateMouseMotion`,
  `SetPassThroughButtons`, set once on our own frame, out of combat). *To try.*

## Terrain

- **Which file is which tile:** a table of FileDataIDs per continent, tile and coast flag (its size to be
  measured), made by our tool from the client's files. It is map data, so it is Core's: a set *Tiles*
  in the pack World, which loads soon after login (`Doc/ideas/Data.md`).
- **Until it is there** (or if it is missing), the small view leaves the native minimap's own ground on:
  the player always sees a minimap, never black.
- **In view:** the tiles whose square meets the view plus a margin of one tile, keyed `continent:col:row`,
  `SetTexture(fileID, "CLAMP", "CLAMP", "TRILINEAR")`. Up close 4 to 9 tiles; at zone level some dozens.
- **Far out (built 2026-10-19):** past 400 tiles in view the game's tiles give way to an overview of them: the
  same tiles at 64 texels, 8 x 8 in one texture of the module's own (`Art/Terrain/`, made by
  `dev/tools/terrain-art` from the game's minimap textures, BLP2 DXT1 like theirs), a continent in a few dozen
  textures, the world in under fifty. It is drawn under the tiles at every zoom, so the land never goes black
  while they load (open question *Far zoom*, answered: terrain at every zoom).
- **Sea tiles** have no file: the ground shows, the sea's colour.
- **The water cut away (built 2026-10-19):** `dev/tools/terrain-art` reads the game's terrain files (each map
  chunk's heights, water and liquid type; magma and slime stay) and makes the overview's alpha the land: where
  the ground lies above the water's surface, sampled 2 yards apart, rivers and lakes too. The overview's colour
  comes from land alone (no dark rim at a coast). The same overview is the mask of the game's own tiles of its
  block (`Canvas.Masks`), so the coast is cut alike at every zoom; under it the canvas' sea colour.
- **Indoors, caves, dungeons:** the minimap tiles hold the outdoors only. There the small view lets the
  native minimap draw its own ground (`SetDrawGroundTextures(true)` while `IsIndoors()` or no tile lies
  under the player), and the full view shows Blizzard's map art of the place.

## Blizzard's map art and the three views

- **A map's art:** `C_Map.GetMapArtLayers(map)` gives each layer's size and tile size,
  `C_Map.GetMapArtLayerTextures(map, layer)` the file IDs, row by row; the tiles are laid over the map's
  world box. The layer is chosen by the scale, as Blizzard's canvas does (*verified*,
  `Blizzard_MapCanvasDetailLayer.lua`).
- **Blizzard view:** the art of the shown map (the zone up close, its continent further out, the world
  map last), as Blizzard's map shows it. Explored areas from `C_MapExplorationInfo.GetExploredMapTextures`
  (each overlay cut into the layer's tiles, as Blizzard's provider does).
- **Terrain view:** terrain only; far out, Blizzard's art (the same switch-over as in *Terrain*).
- **Overlay view (gone, Saneroki, 2026-10-19: the Atlas takes its place):** the terrain, with each zone in view drawn over it at 50 %, **cut to its zone**, so
  the parchment edge of one zone map does not cover the next. The cut is a mask on the zone's art tiles
  (one mask region over the zone's world box, added to each of its tiles: a mask works in screen space;
  `MaskTexture` ignores texture coordinates). Where the mask comes from, in order:
  1. Blizzard's own zone highlight of the continent map (`C_Map.GetMapHighlightInfoAtPosition` gives its
     file and where it lies, *verified* in `MapHighlightDataProvider.lua`): the zone's shape as the game
     draws it on hover. Tried 2026-10-19: these are 128 x 128, blurred and without alpha (drawn added), so no
     mask; they are the hover highlight (`Art.Light`).
  2. **Built (2026-10-19):** a mask per zone made by our tool from the game's area data, shipped in `Art/`:
     `dev/tools/terrain-art` reads each map chunk's area (a 16th of a tile), its zone through the game's
     tables (the area's top parent, the zone map assigned to it), softens the border on the whole grid (two
     zones that meet share it), and writes the alpha over the zone map's box (`Art/Zones/<uiMapID>.blp`,
     256 x 256; `Outlines.lua` lists them). Every zone in view is drawn cut to it, in both art views, the
     continent's art under them in Blizzard maps.
- **The full map (built 2026-10-19):** every part of a zone's art the game reveals once explored is Core's set
  *Overlays* (from the game's tables); all are always drawn, so a zone's map shows every detail.
- **The stitched map (built 2026-10-19):** `dev/tools/terrain-art` lays every zone's full map, cut by its
  outline, where it lies on its continent's grid, in the terrain's blocks (`Art/Sketches/`); the outlines keep a
  zone's land and a little shore (not the open sea, so no painted sea reaches out to a box's edge), whole up to
  the border and fading some 150 yards past it, and off the paper frame. Sketches draws Blizzard's world and
  continent maps under it (their frames faded off by `Art/Edge.blp`) and the zones' own maps over it up close;
  every continent's blocks wherever they are in view, at every zoom.
- **Hover and click (built 2026-10-19):** at a continent shown whole the zone under the mouse lights up in the
  game's highlight, at the world the continent; a click opens it.
- **Fit:** art, terrain and pins are all placed by the same world boxes, so Stormwind's map lies on
  Stormwind. Painted art is not exact to the yard; that is accepted.
- **Exceptions** with their own handling: a city under the ground (Undercity) has no terrain; a map
  whose box cannot be read is shown alone.

### The painted view (planned)

The third view (*A painted third view*), made by the local image models beside the game and shipped as art in
blocks like the terrain's, so the map draws it the way it draws the others.

- **The module (built 2026-10-19, *Atlas, a module of its own*):** `SaneUI_Atlas`, `## LoadOnDemand: 1`, every level in
  the one addon, Core its only dependency. `src/Atlas/` holds its code only (TOC, `Atlas.lua`, README); its art and index are made by
  `dev/tools/atlas` into `assets/optimized/Atlas/` (`Art/`, `Index.lua`), and `dev/build` builds the addon from
  both, only once the index is there (no art made, no module: the map shows two views). Navigation's `Painted.lua`
  finds it at login (`C_AddOns.GetAddOnInfo` and `GetAddOnEnableState`: there, switched on for this character,
  loadable), loads it the first time the view is drawn (`C_AddOns.LoadAddOn`, guarded) and reads it as
  `SaneUI.Atlas`; if it cannot be loaded or stands down, the button and the choice go and the view falls back
  to Scrying, the problem kept as every other.
- **The format (fixed, 2026-10-19):** blocks of 512 x 512 pixels, BLP2 DXT1 with mipmaps, at
  `Interface\AddOns\SaneUI_Atlas\Art\<continent>\<level>\<row>_<col>.blp`, the continent the map's instance
  (0, 1). Level 0 is the finest, 2048 pixels a tile, a block a quarter tile (`TILE / 4` yards); a block of
  level L spans `TILE / 4 * 2^L` yards; levels 0 to `levels - 1`. Row and column as the terrain's tiles, from
  the north-west corner of the 64 x 64 grid: `column = floor((HALF - y) / span)`, `row = floor((HALF - x) /
  span)`, `HALF = 32 * TILE`, `x`, `y` the world's yards. `Index.lua`: `ns.INDEX = { levels = n, [continent] =
  { [level] = { [row] = "c,c,a-b" } } }`, the columns of a row that have a block; a block not listed is not there
  (open sea, or not painted yet), and the terrain shows through.
- **Drawn (built 2026-10-19):** the terrain exactly as Scrying, the blocks over it from the canvas' pool, with the
  same margin: the coarsest level whose art still has as many pixels a yard as the screen shows (each continent
  at its own scale on the screen), never finer than 0, and the next coarser level under it; past 400 blocks of a
  level a continent (a long way of the window) a coarser one. The nearest zoom is three times the others' (6
  units a yard, `Camera.Near`); the game's minimap's steps work as before.

- **What the models get** (*The look*, *Only what the game has*, *Faithful above all*): the continents cut into
  squares of one tile that overlap by an eighth; for each, the terrain of that square as the one picture (its
  layout and everything on it, kept; the minimap textures softened a little first, or their fine dot pattern
  comes back in the painting; the game's water made flat dark navy, but not what stands in it, piers, stilt
  houses, bridges, domes and ice: a flat sheet over Booty Bay's boardwalk had erased it before the model saw it),
  and **words of an edit, not of a repaint** (`dev/imagegen/maps/atlas.toml`): make image 1 look like a
  photorealistic satellite photograph of exactly the same place; change only how things look; never where or what
  anything is, rock stays rock, bark stays bark; then its liquids as the game has them ("the flat dark navy areas
  are water, nowhere else"; under 1 % "only a little water, its few small patches"; or "there is no water anywhere
  in this picture"; "the flat bright orange areas are molten lava, glowing hot", never smoking: that drew a cloud
  of smoke over Burning Steppes), its main zone's colours and the quality of its
  light (the first sentence of its atmosphere without its clauses about colour or haze: those bleached Badlands
  beige, turned Felwood's sea green and Teldrassil's violet and drew steam clouds over Stranglethorn), "keep the
  colours of image 1; no clouds, fog, mist or smoke over the ground", and "add nothing and remove nothing". No
  sentence on the ground: the ground cover, read from the textures' names, called Darkshore's forest floor sand,
  and the model painted sand and channels. Never a zone's buildings, plants, places or props: the model painted orc
  forts, tents and pines from them into a square of empty ash. The minimap textures are softened by 2 pixels
  first (`SOFTEN`; at 0.8 their dot pattern came back as a grid in the rock and suggested a lake by Stormwind's
  cathedral). A picture of the look as a second reference did not work: it showed the same city from further out,
  and the model painted that instead.
- **The lab** (2026-10-19, `assets/generated/atlas-lab/`: 26 hard places painted by every method and scored
  against the game: the coarse and fine layout, the colour, the relief against the hillshade of the real
  heights, the share of ground too steep to walk painted green, the water added and lost):
  - "Repaint image 1 as a photorealistic render" with the zone's words: the layout held on 2 of 8 places; it
    built a village with fields on Elwynn's mountains, an elven island on Darnassus' bark, a lake in Redridge.
  - Starting from the terrain (img2img): either the minimap barely changed, blur and all, or, from a denoise
    of 0.97 up, the same as a repaint (the sampler counts in whole steps: `int(25 / 0.97)` is 25, nothing kept).
  - The Qwen-Image 2.1 Fun ControlNet: on the heights as depth, meadows over the mountains (it learnt depth
    from photographs at an angle); on the terrain's grey, the layout held but the colours went (bark grey or
    green), at 6.5 minutes a picture; on 12 GB of video memory too slow for the world.
  - FLUX.2 [klein] (33 s a picture at 2048): just as inventive (lakes and houses in Redridge, water lost at
    Booty Bay); FLUX.2 [dev] not needed after the edit words.
  - The terrain shaded by its heights with words about steep ground: a new valley of its own. The game's own
    ground textures laid into the minimap (sharper): helped FLUX.2, not needed by the edit words.
  - **Words of an edit:** the layout held on 8 of 8, the mountains bare rock (Elwynn's steep ground painted green
    5 %, the game 2 %, the repaint 31 %), Darnassus' bark, bridge and dome in place, Booty Bay's bay and town,
    photorealistic; with the zone's colours and light also its colours (Thousand Needles' sandstone, not grey).
  - Then on all 26 places (`final`): the layout held on all of them (coarse 0.94, fine 0.88 on average; the repaint
    words 0.46 and 0.29), one stray lake caught by the check; and the light's colour clauses left out (round 7):
    the colours closer to the game's on 9 places (109 against 126), the layout a little better.
  - The whole zones painted as one picture each, and both continents in pieces placed as the world map places
    them (`assets/generated/atlas-looks/`): the layouts held, the mountains bright rock; the open sea painted by
    the model grew land and showed each piece's blue, so far out the open sea is made by code (one even blue,
    blending into the painted shallows near the coasts).
  - Built from the game's data alone (the ground from its own textures, the tiling broken up, water by its real
    depth, the minimap's buildings and trees enlarged by an upscaling model): faithful by construction, but soft
    and game-like; kept as the way to fall back on.
- **Checked against the game:** every painting is compared with the game's water (its liquids, and the
  speckled blue-grey the minimap draws for a city's canals) and lava: broad sheets of water where the game has
  none, or of the game's water painted as land, fail it (a shore that strays a few yards does not), and the
  square is painted again with another seed, the best of up to three kept. Water is bluish, smooth, in sheets
  and bluer than the painting's own land, so a zone graded blue (Duskwood) and the blue shadows of snow are not
  taken for it. Tried on the five styles and the ten zones: it failed every Blackrock with false water (up to 8%
  of the picture), the pond added under Stormwind's hill and the sea square built over, and passed the rest.
- **The guides** (`dev/tools/map-meta`, from the game's files): the roads (the ground textures of roads and
  paving), the buildings' footprints as they stand, what covers the ground (meadow, forest floor, farmland,
  sand, rock, snow, swamp, ash, blight), and the places by name with their positions (the terrain's areas, the
  districts of the cities from the parts of their buildings, the flight masters, the entrances of dungeons and
  raids, the caves and mines under the ground, the exits where a zone's roads meet the next zone's).
- **Words without names:** the words describe what is where ("a village of half-timbered houses at the
  crossroads", "a mine mouth in the hills at the bottom left") but name nothing, and image 2 is softened so its
  labels cannot be read: in the pilot the model wrote every legible name into the picture, garbled.
- **One map, not tiles** (seams): the same look words and sun everywhere, each zone's atmosphere changing only
  where the zone does; every square painted on its own, and the overlaps (an eighth of a square, 67 yards) cut
  along the line where the two paintings differ least, softened a few pixels to either side: a cut, not a
  cross-fade, which would show two paintings of the same trees at once. A square with its painted neighbours
  pasted into its edges (tried 2026-10-19, to carry their colours on) came back with a garish strip of flowers
  at the wrong scale along the opposite edge, with or without words about it. Where the pilot shows
  the model losing roads, the guide's roads are drawn back over the painting in its colours.
- **The colour pass** (2026-10-20, `colour_of` in `dev/tools/atlas`): with the zone's light the model also paints
  the zone's own colours, more in some zones than others (the whole zones painted as one: Badlands' orange pale
  tan, Teldrassil's bark and forest violet, Burning Steppes' grey ash dark red). When the squares are joined,
  each painting's broad colour (its hue and saturation averaged over 48 pixels, 12 yards) is moved toward the
  game's, keeping a share of the model's own (`MOOD`, 0.5 until Saneroki chooses: at 0.3 the zones look much like
  the game's colours, at 1 as painted); its brightness, fine detail and light are kept, so a dark zone stays dark
  (*Dark zones stay dark*; the game's minimap is drawn without the zone's light, and moving brightness too
  lightened Duskwood); its water is pulled toward the open sea's colour whatever the mood (the sea is one sea),
  and halfway toward its brightness, so a dark zone's river stays darker than its land; its lava is left as
  painted. The paintings on disk stay as painted, so the mood can be
  changed without painting again (`join --mood`), and the same pull evens out neighbours painted a little apart,
  so far out no patchwork shows. About a second a square.
- **Levels of detail** (*Close up and far out*, *Three times closer*): the finest level is painted at 2048
  pixels a tile (a quarter of a yard a pixel, four times the minimap textures), with the full model, one
  square of one tile a picture (about two and a half minutes each): the model adds detail the terrain does not
  have (a bridge's chains, the stones of a wall) and keeps the layout. Painting at 1024 and enlarging it with an
  upscaling model (two tried, 2026-10-19) only sharpened what was there, the dot pattern too; the fast Turbo
  model kept the layout but painted soft, flat rock. Every coarser level is made from the finest, as a pyramid
  the map loads by zoom: only the tiles in view, at the level the zoom asks for; the map's nearest zoom
  (`Camera.NEAR`) goes about three times closer in this view.
- **The whole run** (`dev/tools/atlas paint`, in a terminal: a progress bar, the time left, `p` to pause and free
  the graphics card for the game, `q` to quit; it goes on where it stopped): 1,112 tiles hold land (472 of the
  Eastern Kingdoms, 640 of Kalimdor), 1,456 squares; with the squares painted again about 1,600 pictures, some
  3 to 3.5 days on this computer, started only when Saneroki says so. The 612 tiles of open sea
  are not painted by the model: their water is made by code from the sea floor's depth, in the look of the
  painted shores.
- **Size** (the 1,114 tiles with land, DXT1, the game's only kind of texture for this, with every coarser
  level): 512 pixels a tile (1x) 0.19 GB, 1024 (2x) 0.78 GB, 2048 (4x) 3.1 GB, of which the finest level alone
  is 2.3 GB; zipped for download hardly smaller (8 %). Seen side by side at the nearest zoom
  (`assets/generated/maps-pilot/sheets/zoom/`, 2026-10-19): 1x blurred, 2x soft, 4x sharp down to single carts
  and paving. 4x only where things are built saves little: 61 % of the land tiles hold buildings. Chosen: 4x
  (*Full detail, 4x*); the art may come as two addons, the view up to 2x and the finest level as an addon of
  its own, used when installed.
- **Packed** (2026-10-20, `dev/tools/atlas pack`): each continent joined in strips of squares from the north (cut
  where neighbours differ least, through the colour pass) and handed down the nine levels as it goes, a band of
  512 rows at a time, so it is never whole in memory; each level halves the one below. A pixel is painted, open
  sea (no square of the plan: the sea's one blue, made by code) or missing (land not painted yet); a block is
  written where it holds painted ground and nothing is missing, so a map painted in part has no holes and open
  sea alone makes no block. BLP2 DXT1 with mipmaps by ImageMagick (0.03 s a block), the index as `Index.lua`, in
  `assets/optimized/Atlas/`, where `dev/build` takes them from.
- **Light in the game at every zoom:** only the blocks in view are drawn (512 pixels, 128 KB each), from the
  level the zoom asks for, so a 4K screen needs some 40 to 60 blocks at any zoom, a few MB of video memory,
  whatever the package's size: the size costs disk, not frames. What costs frames is loading new blocks, so the
  textures come from the canvas' pools, a frame loads only a few new blocks, the ring around the view and the
  next level are loaded ahead, and the coarser level stays drawn under a finer one until it has loaded (never a
  hole). The blocks are compressed by a fast encoder when the art is built (ImageMagick's careful one took
  minutes for one tile).
- **Routes** (*Routes, later*): the game's own paths of ships and zeppelins (its taxi paths of the transports)
  and of flights.
- **Life on the sea:** each creature and ship a small top-down sprite with a short looped flipbook
  (`dev/tools/flipbook`), moved along paths over the open sea by code; the Maelstrom a painted whirl turned by
  code, with a flipbook of foam.
- **Order:** a pilot of five looks (`dev/imagegen/sets/maps-pilot/looks.txt`; chosen: stylised game art), then
  the close-up pilot on the terrain (`close.txt`: Stormwind, Goldshire, Westfall's edge, Orgrimmar, Razor Hill,
  and one tile at half a yard a pixel; tried 2026-10-19: the layout kept in 11 of 12 pictures, single houses,
  canals and trees clear at both scales; one of Orgrimmar's painted water where the canyon has land); then both
  continents; packing into the pyramid (`dev/tools/atlas join` stitches the squares; the levels, the blocks, the
  colour pass and the index still to come); then the sea's life; then the routes.

### Maps without a world box

The world map, dungeons, and any map the game gives no box for are drawn by themselves: the camera then
works in that map's own space (0 to 1), the art fills it, and pins come by map position. Switching between
such a map and a continent converts the centre by `C_Map.GetMapRectOnMap` where the game knows the link.

## Small view: the native minimap's live dots

As Blizzard's hybrid minimap does (*verified*), with our canvas under the native `Minimap`:

- **Taken:** the `Minimap` frame is given our small view as its parent and placed in its middle (out of
  combat, a frame after the decision, never inside a hook of one of Blizzard's panels: that gives *action
  blocked*). Its ground goes off (`C_Minimap.SetDrawGroundTextures(false)`), its rotation is ignored
  (`C_Minimap.SetIgnoreRotateMinimap(true)`), its mask is a square
  (`Minimap:SetMaskTexture`). `MinimapCluster` stays where Edit Mode puts it, out of sight (alpha 0, mouse
  off); it is not hidden, so Edit Mode keeps working on it. Its box in Edit Mode is faded too (*to try*).
- **The same scale:** our pixels per yard = (`Minimap:GetWidth()` / 2) / `C_Minimap.GetViewRadius()`; each
  frame while the small view follows and shows, the holder is moved so the player's world position lies
  in the middle (one `SetPoint`, as Blizzard's hybrid does in its `OnUpdate`).
- **The wheel:** in the small view it first walks the native minimap's zoom steps (`Minimap:SetZoom`,
  `MINIMAP_UPDATE_ZOOM`), so dots and ground stay together; past the widest step our camera goes on alone,
  and the native minimap is hidden (`Minimap:Hide()`: alpha does not hide the engine's dots) until the
  view is back in its range. A drag (follow off) hides it the same way.
- **Square:** the native minimap stays square (its projection and arrow need it). In a small view that
  is not square, the live dots cover the square in its middle; the rest shows our pins.
- **Our arrow** hides while the native minimap shows its own.
- **The full view** hides the native minimap (Edge's `filled`); the small view shows it again once back
  (`docked`).
- **What else is on the minimap** (zone text, clock, mail, tracking, difficulty): our own small parts
  around the small view, reading the game's API, not Blizzard's buttons moved (no Blizzard frame given a
  new parent, so no taint). Which ones: *Open questions*.
- **Watch for:** the game's skin of this client sets the minimap's mask again when `rotateMinimap`
  changes (`Blizzard_Minimap/Camelot/Skin.lua`): our mask is set again after (`CVAR_UPDATE`). The queue
  eye is anchored to `Minimap` in this client and moves with it: placed by us. The game's key *Toggle
  minimap* (`ToggleMinimap`) hides `Minimap`: Navigation takes that key, as it takes M and L.
- **Given back:** parent, points, size, strata and level, mask, `SetDrawGroundTextures(true)`,
  `SetIgnoreRotateMinimap(false)`, `MinimapCluster`'s alpha and mouse (kept with `Core.Points` before).

## Pins

- **Two sources:** Core's data (`Data.Map():On(map, kinds)`, per map in view, kept until the set's stamp
  moves) and the game, live (*Live*). Both become the same plain record: kind, key, world and map
  position, icon, state, roles.
- **Merged at run time** where the game knows better (*One pin per thing*, point 6): a live pin with the
  same key hides the database's. One thing with several roles shows its most important role the filter
  lets through.
- **Index:** per continent, a grid of cells (proposal: 256 yards); the view asks for the cells in view.
  Built in steps when a map's data arrives.
- **Gathering overlaps:** pins that would cover each other on screen become one marker with the number
  they hold, placed at their middle. A click on it zooms in until they part; where they share one spot even
  up close, it lists them. How near counts as covering, and the cap on pins drawn, are set by step 0's
  frame-time test. Worked out again when the scale changes, not on a pan.
- **Pin frames:** a pool of buttons (`CreateFramePool`), the same size on screen at any zoom, Blizzard's
  POI pins as the model (`SharedMapPoiTemplates`). Tooltip with `GameTooltip`, names asked of the game.
- **The filter's checkmarks are switches** in the module's settings, so profiles keep them.

## Live: what the game tells while playing

| What | From the game | When | Note |
| --- | --- | --- | --- |
| The player, the arrow | `C_Map.GetBestMapForUnit`, `C_Map.GetPlayerMapPosition`, `GetPlayerFacing` | each frame while the small view follows; else a few times a second while shown | through `Core.Plain`; nil: *position unknown* |
| The map the player is on | `ZONE_CHANGED`, `ZONE_CHANGED_INDOORS`, `ZONE_CHANGED_NEW_AREA`, `NEW_WMO_CHUNK` | events | |
| Group members | `C_Map.GetPlayerMapPosition(map, unit)` | a few times a second while shown | party and raid only (the game's rule) |
| Quests on the map | `C_QuestLog.GetQuestsOnMap(map)` | `QUEST_LOG_UPDATE`, `QUEST_POI_UPDATE`, map change | turn-ins, next steps |
| A quest's area as the game draws it | a `QuestPOIFrame` of our own over the zone | the same | *to try*; else Core's *QuestAreas* |
| Flight points | `C_TaxiMap.GetTaxiNodesForMap(map)`; known ones from the character's data | map change, `TAXIMAP_OPENED` | |
| The map pin | `C_Map.GetUserWaypoint`, `HasUserWaypoint` | `USER_WAYPOINT_UPDATED`, `SUPER_TRACKING_CHANGED` | |
| Rares and chests nearby | `C_VignetteInfo.GetVignettes`, `GetVignettePosition` | `VIGNETTES_UPDATED` | beats the database's pin |
| The game's own points | `C_AreaPoiInfo.GetAreaPOIForMap`, `C_Map.GetMapLinksForMap` | `AREA_POIS_UPDATED`, map change | |
| Explored areas | `C_MapExplorationInfo.GetExploredMapTextures` | `MAP_EXPLORATION_UPDATED` | |

A burst of events is handled once on the next frame (`Core.Later`); nothing is asked while the window is
hidden but what the small view needs.

## Quest log

- **Our own list** (Blizzard's belongs to its map window and calls it in about 25 places, *verified*):
  `WowScrollBoxList` with a tree view, zones as headers, quests under them, objectives under those; from
  `C_QuestLog.GetNumQuestLogEntries`, `GetInfo`, `GetQuestObjectives`; built again once a frame after
  `QUEST_LOG_UPDATE`.
- **Actions:** track (`AddQuestWatch`, `RemoveQuestWatch`), focus (`C_SuperTrack.SetSuperTrackedQuestID`),
  share, abandon (`SetAbandonQuest`, `AbandonQuest`, after a question of our own), show on the map (the
  camera goes to the quest: `GetQuestsOnMap`, `GetNextWaypoint`).
- **Never Blizzard's quest panel functions** (`QuestMapFrame_OpenToQuestDetails`, `ShowQuestComplete`):
  called from addon code they taint the map's pins.
- **A view of its own,** in its own file and frame, so it can stand on Core's full screen *board* once
  Core has one (window guide, *Not built yet*); until then the window lays out map and quest log in its
  `docked` hook.

## Top bar, map selector and search

- **Map selector:** a breadcrumb World › Continent ▾ › Zone ▾ (*Map selector*), menus by Blizzard's menu
  system (`MenuUtil`, `WowStyle1DropdownTemplate`). Continents and zones from the map tree at run time;
  dungeons from Core's data and the tree's maps of type *Dungeon*.
- **Pin filter:** a dropdown with a checkbox per kind (`CreateCheckbox`), grouped as the *Pin catalogue*.
- **Three views:** three buttons; the choice is a switch (profiles keep it).
- **Search:** the full screen's title bar has Core's search; it finds zones, dungeons, towns, services and
  the quests in the log (fuzzy, Core's `Fuzzy.lua`); a hit moves the camera there (proposal).

## The game's map and minimap: kept out of sight, given back

What opens the game's map (*verified*): the keys `TOGGLEWORLDMAP` and `TOGGLEQUESTLOG`
(`Bindings_Camelot.xml`), the micro menu's quest log button, the minimap's zone text, a click on a quest
in the objective tracker, chat links, the events `WORLD_MAP_OPEN` and `AJ_QUEST_LOG_OPEN`, and a few more.
All of them end in `ShowUIPanel(WorldMapFrame)`.

- **The keys first:** the keys bound to the game's map, quest log and minimap toggles open ours instead
  (override bindings on a named button of ours, set out of combat, again after `UPDATE_BINDINGS`). The
  most common way never opens the game's map at all.
- **All other ways:** a hook on `WorldMapFrame`'s `OnShow` sees every one. There Navigation reads what was
  asked (the map: `WorldMapFrame:GetMapID()`; a quest: a hook after `QuestMapFrame_OpenToQuestDetails`),
  opens ours to it (`window:Open()`), and closes the game's map on the next frame with
  `HideUIPanel(WorldMapFrame)`, out of combat.
- **In a fight** the panel manager refuses `HideUIPanel` from addon code (*verified*:
  `UIParentPanelManager.lua`, *We no longer allow addons to show or hide UI panels in combat*). Two ways,
  *to try* with the taint log on: a plain `WorldMapFrame:Hide()` (the frame is not protected, and the panel
  manager repairs a frame hidden that way at the next show, *verified* `RepairUIPanelState`; it may taint),
  or leaving the game's map open in a fight and ours closed (the window guide's `"locked"` answer). The
  second is the fallback if the first shows any blocked action.
- **Never:** `WorldMapFrame:SetParent`, fields written into it or `QuestMapFrame`, replaced functions,
  `SetAttribute` on it, opening Blizzard's quest panels from our code.
- **The toggles** *Minimap* and *Map* (and the dropdown *Classic windows*) stop the interception for that
  window and give it back; the game's own then works as if Navigation were not there.

## Waypoint and route

### The map pin

- Ctrl-click on our map sets the game's map pin (`C_Map.SetUserWaypoint` with
  `UiMapPoint.CreateFromCoordinates`, where `C_Map.CanSetUserWaypointOnMap` allows it) and tracks it
  (`C_SuperTrack.SetSuperTrackedUserWaypoint(true)`); the game's own on-screen marker follows it
  (`C_Navigation`). Navigation reads it on `USER_WAYPOINT_UPDATED`.
- **The player's pin is the player's:** the route only reads it. Where Navigation sets it for the player
  (a step of the guide, a click on *Route here*), it remembers what was there, gives it back when done,
  stops at once when the player sets another, and ignores the events of its own write (a flag while
  writing). The pin stays the player's.

### The planner

1. **The journey:** a small graph whose nodes are the known flight points, piers, portals, lifts, the
   hearthstone's place and the two ends; its edges are flights (times from Core's data), ships and
   zeppelins (their timetable: the wait and the trip), the hearthstone (its cooldown as a wait), and
   walking between nodes (estimated from the walking data's region graph). A few hundred nodes: a
   shortest-path search in well under a millisecond. Run speed from the game.
2. **The walking legs:** on Core's walking data, which our tool makes as a graph of walkable points and
   the walkable links between them (points sparse in open land, dense in towns, caves and tunnels), grouped
   into regions with the links between regions known in advance. The search finds the regions first,
   then the points inside only those regions, each region opened on first need.
3. **Drawn as soon as the journey is known;** the walking legs fill in as they are found.

- **In steps:** a job in Core's scheduler, so it shares the one frame budget and stops in a fight; the
  line stays drawn in a fight, only replanning waits.
- **Replanned** when the player has left the line, or has reached the end of a leg (a flight landed, a
  ship arrived); a new route replaces the shown one only when it is clearly better, so the line does not
  jump. How far off counts as left, and how much better is clearly better, are tuned in the game.
- **Without walking data** (the pack switched off, inside an instance): a straight line to the pin.
- **Built (2026-10-20, `Planner.lua`):** the journey on the player's continent over the start, the end and the
  flight points this character knows (read at the flight master, `C_TaxiMap.GetAllTaxiNodes`, else the older
  window's names; kept per character), the flights of Core's set *Travel* its side may take (each at its way's
  length over `Planner.FLY` yards a second and `Planner.BOARD` seconds), walks guessed at `Planner.DETOUR`
  times the straight line within one region of the walking data; Dijkstra. Then each walk searched
  (`Search.lua`, a job of Core's scheduler); one found `Planner.WORSE` times its guess or more puts in its true
  length and the journey is chosen once more. Planned again when the pin changes, after a flight landed, when
  the player is `Planner.OFF` yards off the line (at most every `Planner.AGAIN` seconds), and when the walking
  data or the flights arrive. The setting *Route to the map pin* (on).
- **Built (2026-10-20): boats, zeppelins and the hearthstone.** What the game's tables give and what they do not:
  - **The ways** (`dev/tools/travel-data`, Core's set *Travel*, keyed by the game's TaxiPath ID like the flights):
    the transports' paths in the client's TaxiPath tables (no flight point at either end), each one way round as
    the game moves it: its points in the world's yards, the map each lies on, its stops at docks with the seconds
    it stands there (the game's delay) and its leaps (the game's teleport, or a change of map; after its last point
    it starts again from its first). A boat when all its way lies at the sea's level, else a zeppelin. Kept are the
    paths that stop at two docks or more: twelve in build 70245 (Booty Bay and Ratchet; Menethil Harbor and
    Theramore; Menethil, Southshore and Auberdine; Rut'theran and Auberdine; Auberdine and Stormwind's harbour;
    Feathermoon and the Feralas coast; Tanaris and Powderfuse Port; the zeppelins between Orgrimmar, Grom'gol and
    the Undercity; two zeppelins to Zephras Isle). Left out: moving things with fewer than two stops, and the older
    Menethil to Auberdine way, whose docks the newer one by way of Southshore all has.
  - **On the map (2026-10-20):** each dock a pin of its own (*Pin catalogue*, *Travel*), also where a ship stops
    twice: the tool places the docks on their zone maps as every map point (`docks`, with the game's area each lies
    in, `dockAreas`, which names it in the other docks' tooltips).
  - **Not in the tables:** the ships' speed and timetable. So their times are estimates in code until they are
    learnt in play (Core's learned data, `Doc/ideas/Data.md`; the set's `wait`, a transport's time once round,
    is where they go): once round is the sailing at `Planner.SAIL` yards a second, the stays, and
    `Planner.LEAP` seconds a leap; one waits half of that for a ship, then sails to the dock (the stays between
    included). With a learnt time once round, its speed follows from it. Nothing guessed is in the master.
  - **In the journey:** each dock a place of the graph, boarded and left at its pier (the floor of land nearest
    where the ship stops), a way from every dock of a ship to every other; the graph spans the planes of the
    player and the pin (a continent, or Zephras Isle: below), each place in its own plane, walks only within one
    plane. The ship's leg
    is drawn red from pier to pier along its way, across its leap; the line moves on to the next leg when the player
    is nearer it, and aboard a ship (past its dock, within `Planner.ABOARD` yards of its way) it is not planned
    anew; a new pin is then planned from where the ship lands.
  - **The hearthstone:** its place is learnt per character where it is bound (`HEARTHSTONE_BOUND`) and where it
    brought the character, with the game's name of it (`GetBindLocation`, which tells when it was bound
    elsewhere since); a way from the player to it while it is in the bags, its cooldown and `Planner.HEARTH`
    seconds its cost; drawn pale blue, straight.
  - **Zephras Isle (built 2026-10-20):** its map (uiMap 2521, the world's map 2991) is a zone straight on the
    world map, not a continent. Every map straight on the world map that is no continent but has a box and a place
    there (`C_Map.GetMapRectOnMap`) is a plane of its own, linked through the world map like a continent
    (`Coords.PlaneOf`: a map's continent, else such a map; `Coords.Planes`: the continents, then those maps). The
    planner's pin, docks and player use these planes, so the two zeppelins to the isle (from the Eastern Kingdoms
    and from Kalimdor) are in the journey, and the map pin's mark shows there. The walking data
    (`dev/tools/walk-data`) covers the two continents only: walks on the isle are straight lines.
  - **The map on Zephras Isle (built 2026-10-20):** the canvas uses the planes too, so its views work on the isle
    as on a continent: they follow the player there (`Coords.Player` gives the isle's plane), come in over it from
    the world (`Coords.PlaneAt`, a continent or such a map under a point of the world map) and open it by a
    click, list it in the map selector after the continents and in the quest log's search, and draw its pins (its
    zeppelins' tower, the game's own) and the party there. A plane that is no continent is a zone, its own one
    (`Coords.Alone`; `Coords.ZoneAt` and `Coords.Zones` give the isle itself): its zone's level reaches out to the
    world with no continent's between, and a right click on it goes to the world. At the world off the isle the
    camera goes into the plane under the middle at once, so over a continent the world is left at the
    continent's own zoom, not at the isle's. The continents' levels and drawing are unchanged; *Parchment* draws
    the isle's own map, *Scrying* and *Atlas* only the sea there (no tiles, overview or painting of the isle).
  - **Not yet:** which side's town a dock stands in is not in the client's tables (a town's guards are the
    server's), so a route may lead through the other side's harbour; Zephras Isle's walking data, its terrain (the
    set *Tiles*, the overview and the stitched map of `dev/tools/terrain-art`) and its painting; trams, lifts and
    portals (the lifts' and the tram's motions are in the client, but not where they stand nor where a portal
    leads); a new route kept only when clearly better.

### The walking data

Core's (pack Routes, loaded on the first route, *Decisions*): per region a block, packed (the game's
`C_EncodingUtil` unpacks it), opened on first need, the opened ones capped (the cap measured with the first
real data) and let go when no route is asked for. The format, the tool and the checks are Core's data
framework's; this is the one set where its rule of plain text gives way, as `Doc/ideas/Data.md` foresees for
a cold, very large part.

**Built (2026-10-20, `dev/tools/walk-data`; open question 1 answered):** from the game's own files only: each
map chunk's heights (but its holes), every collision triangle of every building the object files place (their
group files, turned and moved as the game places them, cut into columns as a voxel field is made), and the
water (deeper than `DEEP` a floor to swim on; magma and slime close what lies under them). Sampled every 2.08
yards (256 a tile): a floor is the top of a column's span made by something not too steep (`SLOPE` 50°) with
`ROOM` (2 yards) free above it; two floors side by side are one way within `CLIMB` (2.6 yards); the ground is
judged on its heights smoothed over three samples, so its bumps make no specks.

- **Surfaces, then rectangles:** a flood joins floors into surfaces (one kind, at most one floor a column, every
  two neighbours one way), and each surface is cut by a quadtree into squares of up to `WIDEST` (32 samples, 67
  yards), neighbours of one size joined. At the ground's edges a square may take a share of steep samples
  (`TAKEN`: a half at 2 samples up to 95 % at 32; never a hole, water, a building or another surface's floor),
  walked over at the square's height; a lone sample among steep ground is left out. So the land is a few large
  rectangles, towns, caves and mountainsides many small ones.
- **Regions:** all rectangles one can walk or swim between share a number; a region under `SMALLEST` (3,000
  samples, rooftops, ledges, plateaus nobody walks onto) is left out.
- **The block** of a tile (CBOR, deflated, base64; the game's `C_EncodingUtil` reads it): its surfaces (count,
  kind, region), its rectangles (column, row, width, height, height in quarter yards) and the openings the game
  cannot work out itself: two rectangles of one surface that touch are open along all their edge (not
  written); every other opening is written (between surfaces, into the next tile, or only part of an edge), on
  its own tile once (`Walk.lua` adds the other way).
- **Size:** 1,724 tiles of both continents, 1.43 million rectangles, 10.7 MB in the master (the pack *Data:
  Routes*, loaded at the first route); about two minutes to make on this computer. Walks across a zone take
  20 to 65 ms of search, spread over frames by the scheduler.
- **The search** (`Search.lua`): A* over the rectangles from the one under the start (or the nearest within 40
  yards) to the one under the end in the same region (different regions: no walk, known at once); a step costs
  the way from where a rectangle was entered to the nearest point of the opening, swimming twice; the line then
  pulled straight through the openings passed, each drawn in 0.8 yards from its ends.
- **Not yet:** the doodads (trees, fences, rocks) are not read: a line may cross a fence; one-way drops (a
  ledge one can jump down but not climb) are no way.

### The golden line

- The path made short first: straight runs joined, corners cut where the walking data shows a clear way
  (it changes the drawing, never the cost); only the part in view is drawn.
- `CreateLine` segments from a pool, a few pixels thick, gold, a darker edge under it.
- **The pulse runs towards the pin without code each frame:** a repeating soft gradient on each line,
  moved by a `TextureCoordTranslation` animation (*verified* to exist; Blizzard moves lines this way in
  `PowerDependencyLine`). The animation runs in the game's engine; no `OnUpdate` of ours.
- The same line in both views; the canvas clips it.

## Leveling guide

- **Logic** (`Guide.lua`): which guide and step, checked by the game's events (quest accepted, done,
  turned in; level; items; zone), each check cheap and once a frame at most; skip and back by hand.
- **The step's place** is a pin and, when the player wants it, the map pin and the route (*The map pin*:
  given back when done).
- **The view** (`GuideView.lua`): in full screen in the quest log's place (a switch between the two, or both
  stacked: open); small, a line at the minimap (open).
- **The item button is not part of the map window.** A secure button makes the window that holds it, or
  that it is anchored to, protected, and a protected window cannot move, change size, show or hide in a
  fight (window guide, *Combat*). The map window must stay free in a fight, so the item button is a frame
  of its own on `UIParent`, placed near the minimap out of combat, its item changed only out of combat.
- **Quests taken and handed in by themselves** (open): the game's calls at the quest giver
  (`AcceptQuest`, `CompleteQuest`, `GetQuestReward`) are not in its API documentation (*to try*); a
  switch, off by default.

## Data from Core

What Navigation reads (`Doc/ideas/Data.md`); Navigation writes nothing there.

| Need | Set, reader | Pack | Loads |
| --- | --- | --- | --- |
| Pins: services, givers, rares, chests, herbs, ore, books, places | `Data.Map()`: `On`, `Near`, `Services` | Spawns, World | Navigation's `OnLogin` asks for it (`Prepare`): the minimap shows from login |
| Quest areas, spawn areas | `Data.Areas()`, *Spawns* | Spawns | the same |
| Patrol paths | *PatrolPaths* | Spawns | the same |
| Quests: available, requirements, chains | *Quests* | Quests | soon after login |
| Terrain tiles | *Tiles* (new, proposed) | World | soon after login |
| Zone levels, piers, ships, flight times | *Zones*, *Travel* | World | soon after login |
| Leveling guides | *Guides* | Guides | first guide shown |
| Walking data | *Walking* | Routes | first route |
| Known flight points, rares seen and killed | the character's data | Characters | soon after login |

- **A pack that is not there yet or switched off** leaves its pins out; the map works with the live
  sources alone. `Get` never loads a pack (Data.md, decision 20).
- **Told when data arrives:** by Core, not a look every frame: `Set:OnStamp(fn)` when a set arrives or
  changes, `Data.WhenReady(set, fn)` once it is there.
- **Map positions to world** are converted by Navigation once per map, kept with the map's pins.
- **A consequence for the data plan:** with Navigation on, the minimap shows from login, so the pack
  Spawns loads after every login, not at the first map opened. It should hold what the map shows and stay
  lean; every creature's spawns (Data.md, decision 18) would better be a pack of their own (*Open
  questions*). Decided so (Saneroki, 2026-10-17): every other creature's spawn points are the set
  *CreatureSpawns*, pack `SaneUI_Data_CreatureSpawns`, loaded when asked for.

## Settings and what is kept

- **Switches** (`Core.Options`, the page *Navigation*): *Minimap* and *Map* (the game's own shown, off),
  the view (Blizzard, Terrain, Overlay), the overlay's opacity (50 %), one switch per pin kind (the
  filter), the small view's pin distance, follow again after (seconds), quests taken and handed in by
  themselves (off), and the section *Expand window* (`Core.Edge.Options`).
- **Kept for the account** (`Core.Store`): the window's place (Core's).
- **Kept per character** (`Core.Character`): each view's last camera (map, centre, scale), the small view's
  native zoom step, the selector's last 30 maps, the guide and its step.
- **Core's character data**, not Navigation's: known flight points, rares seen and killed (Data.md,
  *Characters*).

## When something fails

Each part runs guarded (`module.Guarded`); an error stands the module down (`StandDown`), which gives
everything back (`GiveBack`) and says so once.

| Fails | What happens |
| --- | --- |
| The window, the canvas, taking a frame | Stand down: the game's minimap and map are back |
| Terrain (table missing, a file will not load) | The native minimap's own ground; Blizzard's art in the full view |
| A pack missing or switched off | Its pins are left out; live pins stay |
| Walking data missing | A straight line to the pin |
| The position is hidden or unknown | The map stays where it was; the arrow hides |
| Closing the game's map in a fight | Ours stays closed, the game's stays open until the fight ends |

**`GiveBack` undoes, in this order:** our key overrides cleared; the hooks do nothing more (they look at
`ns.off`); `Minimap` back to its parent, points, size, strata, level and mask; its ground on, rotation
not ignored; `MinimapCluster`'s alpha and mouse back; our window hidden. Done out of combat; asked in a
fight, it waits for `PLAYER_REGEN_ENABLED`.

## Performance

| Moment | Work | Budget |
| --- | --- | --- |
| Small view, following | read the position, move the holder (one `SetPoint`), turn the arrow; skip when nothing moved | under 0.1 ms a frame |
| Small view, still or full screen, still | nothing | 0 |
| Pan | the holder; a new layout past the margin | under 0.1 ms; a layout under 1 ms |
| Zoom step | every layer laid out (at most about 600 regions) | under 1 ms |
| A map's pins arrive, the filter changes | index, cluster | in steps, within the scheduler's budget |
| Route search | Core's scheduler | its budget (5 ms, out of combat) |

- **Caps** on terrain textures, art textures, pins, lines and opened walking regions, each set from step 0's
  frame-time test (f) and the first real data. Pools grow to their cap and are kept (a frame cannot be
  destroyed).
- **No garbage in what runs often:** no table, closure or string made in the frame step or a layout loop.
- **Measured** in the game with the client's addon profiler before anything is made faster.

## Tests

**Outside the game** (`dev/tests/navigation.lua`, the stand-in client with a small made-up world: two
continents, a few maps with world boxes, a few tiles):

- coordinates: map ↔ world ↔ screen round trips, the axes, tile from position;
- camera: zoom around the mouse point, the shown map by scale with its slack, follow on and off;
- what is in view: tiles and pins for a view, the margin;
- gathering overlaps: which pins cover each other, the marker's count and place, the cap;
- pins: live beats database, roles and the filter;
- planner and search: a made-up transit graph; a small made-up walking graph of two regions with a wall
  between them; a search in steps gives the same path as in one go; a fight parks it;
- the guide: a step ticks on its event;
- fallback: `StandDown` gives back the `Minimap` (the stand-in records the calls) and clears the keys.

**In the game:** the list of step 0 first, then each step's *done when*.

# Build order

Each step ends in something tried in the game, and in the module's README marking what is not.

| Step | What | Needs | Done when |
| --- | --- | --- | --- |
| **0. Proof** | A throwaway test behind `/sane map test`, to answer the *to try* points before building on them: (a) a tile by file ID shows and lies under the player; (b) the native `Minimap` in a frame of ours, ground off, rotation ignored: dots on our ground, in and out of a fight, after Edit Mode and a loading screen; (c) the map key opens ours and a fight after it shows no blocked action (taint log on); `WorldMapFrame:Hide()` in a fight; (d) positions in a city, a cave, a dungeon; (e) a `QuestPOIFrame` of ours draws a quest's area; the zone highlight as a mask; (f) many textures and pins on a full screen: the frame time, which sets the caps; (g) the overlay on the minimap: wheel and drag ours, the dots' tooltips the minimap's | the tile table (tool) | every point has its answer written into this page |
| **1. Minimap** | The window (kind `screen`, top right), canvas, camera, terrain, the native minimap's dots, the wheel through its steps, the toggle *Minimap*, `GiveBack` | Core's window | an hour of play: no error, no blocked action, dots on the ground |
| **2. Map** | Full screen, two cameras, zone to world, Blizzard's art, the three views and the cut, the selector, the game's map kept closed, *Map* toggle, *Classic windows* | step 1 | every way of step 0 (c) opens ours; Stormwind lies on Stormwind |
| **3. Live pins** | Player, group, quests on the map, flights, the map pin by Ctrl-click, vignettes, the game's points, explored areas; the filter | step 2 | pins match the game's own map |
| **4. Quest log** | The list on the left, its actions | step 2 | the game's quest log is not missed |
| **5. Database pins** | Pins, gathered overlaps, tooltips, rares and their spawn areas, quest areas, patrol paths | Core's data: World, Spawns, Quests | a zone's pins as the catalogue says, one per thing |
| **6. Routes** | Planner, search, the golden line | Core's data: World, Routes | a route across a continent with a flight, in steps, no hitch |
| **7. Leveling guide** | The step, its checks, its view, the item button | Core's data: Guides; step 6 | a starting area played through by the guide |
| **8. Dungeons and the rest** | Dungeon maps, floors, the minimap's own parts, polish | | |

**Where it stands (2026-10-20):** steps 1 and 2 built (2026-10-19); 3 and 4 built, the live pins and the quest log;
5 built as far as Core's data goes: the pins, gathered overlaps, tooltips and the quest areas the game shades are
there, and `Data.Map` reads Spawns, Places and Travel, of which Spawns and Places hold no entries yet, so the
database's pins come with the import; rares' spawn areas and patrol paths wait for their data. 6 built on foot, by
flight, by boat and zeppelin and by the hearthstone (the walking data, the flights and the ships' ways of the game's
tables, the planner, the search, the golden line); trams, lifts and portals not yet. Step 0's points are answered in play as each step is tried.

The hardest parts, in order: the walking data (its tool and size); keeping the game's map closed in a
fight; the small view's dots with our ground; the overlay's cut; the pin data (Core's).

# Reference

## Pin catalogue

The pin types for the pin filter, grouped as the dropdown could group them. *Live* means read from the
game while playing, without a database. Icons are the game's own wherever it has one: the atlases of its
map legend (`Blizzard_UIPanels_Game/Mainline/MapLegendFrameData.lua`), its vignettes and its tracking
icons. How many of each there are is measured from our data when the packs are built.

### Quests

| Pin | Icon | Shown when | Data |
| --- | --- | --- | --- |
| Quest offered | `QuestNormal`, as the game's map legend shows an offer | the character can take it: Core's `Quests:Missing` finds nothing lacking (level, race, class, quests before, reputation, skill) | Core's quest data |
| Repeatable quest | `UI-QuestPoiRecurring-QuestBang` | daily, weekly or repeatable | Core's quest data |
| Turn-in | `UI-QuestPoi-QuestBangTurnIn` | quest complete | live (`C_QuestLog.GetQuestsOnMap`), Core's quest data |
| Objective | the quest's number on the game's quest plate (`UI-QuestPoi-QuestNumber`), as the quest log numbers it | unfinished; the nearest few | Core's quest data, spawn points |
| Quest area | its cells, shaded as the game shades its own quest areas | unfinished | Core's *QuestAreas*; the game's own areas live |
| Elite warning | the game's elite frame on the objective's pin | an objective creature is elite | Core's quest data |

- **Quests for a dungeon** are the same pins at their givers, the dungeon named in the tooltip.
- **Forever replaced some quests:** a quest pin shows only once `C_QuestLog.RequestLoadQuestByID` confirms
  the quest exists.
- **Quest areas:** from Core's database (`Doc/ideas/Data.md`, *Quest areas*: the cells an objective's places
  cover, or the game's own area where it can be read). Drawn as their cells, in the tint the game uses for
  its own quest areas (matched in step 0 (e)), still, without a pulse.
- **Patrol paths:** the NPCs' patrol paths are kept in Core's database (Saneroki, 2026-10-16) and drawn as a
  pin type of their own, switched in the pin filter.

### Services

Flight master, innkeeper, mailbox, repair, class trainer, profession trainer, vendors (food, reagents,
poisons, ammunition, bags, trade goods, potions), banker, auction house, stable master, weapon master,
battlemaster, spirit healer, meeting stone.

- **Icons:** Blizzard's `Interface\Minimap\Tracking\*`, the same as the native minimap's town tracking;
  item icons for the vendor kinds; `Raid-Icon-Rez` or our own spirit healer icon for spirit healers.
- **Shown:** own faction by default. In the small view only within about 300 yards, so the minimap stays
  readable.
- **Data:** Core's *NPCs* (`services`), learned and checked when the player talks to them
  (`Doc/ideas/Data.md`, *Places on the map*); Core's *Places* for mailboxes, spirit healers and meeting
  stones.

### Travel

| Pin | Icon | Notes | Data |
| --- | --- | --- | --- |
| Flight point | `TaxiNode_*` atlas; grey when not known | live; the known ones are learnt at the flight master | Blizzard |
| Boat, zeppelin, tram, lift | `TaxiNode_Continent_*` | with destinations; right-click opens the destination map | Core's *Travel* |
| Portal | `TaxiNode_Continent_Neutral`, as the game's legend shows a teleport | the few portals and passages | Core's *Travel* |
| Zone crossing, cave entrance | `CaveUnderground-Up/Down` | where a path leaves the zone or goes underground | Core's *Places* |

### Places

- **Cities and towns:** `poi-majorcity`, `poi-town`.
- **Dungeon and raid entrances:** `Dungeon`, `Raid`; the level range coloured against the player's level;
  a click opens the dungeon's map. From Core's data (the game's own entrance pins are not in this client):
  every dungeon and raid of this client, Forever's own among them.

### Gathering

- **Herbs and ore:** Blizzard's tracking icons (`Professions_Tracking_Herb`, `Professions_Tracking_Ore`,
  or the item the node gives, such as `inv_misc_flower_02` for Peacebloom). Places from Core's *Spawns*
  and *Objects*. Live nodes from the minimap's tracking: optional, by probing (below).
- **Treasure chests:** the chest's own vignette atlas while the game shows it (`C_VignetteInfo`), else the
  game's chest icon; dimmed once this character opened it (Core's character data).
- **Live nodes on the full map (optional, later):** the native minimap can be probed point by point
  (`Minimap:UpdateMouseoverAtPoint`, then `C_TooltipInfo.GetMinimapMouseover`) while a tracking spell is
  on, a few points at a time as a job in Core's scheduler, never in a fight.
  The nodes found would stay on the map as discoveries (Core's).

### Rares

- **Marker:** the game's own: while the rare is near, its vignette and the atlas the game gives it
  (`C_VignetteInfo.GetVignetteInfo`); otherwise the map legend's `VignetteKill`, or `VignetteKillElite` for
  an elite, at its spawn area's middle.
- **Seen at:** the tooltip's own line of what this player's characters know of it: *Seen 2 days ago, near
  the Fargodeep Mine*; *Killed today*. From Core's character data, which notes each sighting (its
  vignette or a target) and each kill per character.
- **Where it can spawn:** a click on the marker outlines the rare's spawn area (Core's *Spawns*, cells as in
  *Quest areas*) in one quiet colour, with its spawn points as small dots; a click elsewhere hides it. One
  rare at a time.
- **Data:** Core's *NPCs* (rank, level, respawn, abilities) and *Spawns*; loot from Core's *Drops*.
- **Tooltip:** name, level, elite, *Seen at*, respawn where known, loot. Filters: elites only; killed today
  hidden (on).

### Collections

- **Library books:** the book's own item icon; dimmed once read (Core's character data). The
  **librarians** with the game's quest mark.

### Overlays

- **Unexplored areas** drawn darker than explored ones (a switch), from the client's own tables.
- **Zone borders** as gold lines (off by default).
- **A zone's level range** on hover, from Core's *Zones*.

## One pin per thing

This is the work of Core's data compiler and its learning (`Doc/ideas/Data.md`, *Keys*, *Learned*), written
here because Navigation is what needs it; point 6 is Navigation's, at run time.

A thing on the map can become known several ways: in the shipped data our tools made, learned in play,
shared by the guild, or told live by the game. Core keeps **one pin per thing and place** whichever way it
came.

**1. What counts as the same thing.** Each pin has a key:

| Pin | Key |
| --- | --- |
| Quest giver, turn-in | quest ID, role (gives / takes), NPC or object ID |
| Quest objective | quest ID, objective, NPC or object ID |
| Service (vendor, trainer, repair ...) | NPC ID, service |
| Herb, ore, chest, mailbox, meeting stone | object ID (or kind, where there is no ID) |
| Rare | NPC ID |
| Dungeon or raid entrance | instance ID (or LFG dungeon ID) |
| Flight point, pier, portal | taxi node ID, route; else kind and name |
| Book | item ID |

Things without IDs (spirit healers, piers, meeting stones) are matched by kind, name and distance.

**2. What counts as the same place.** Points with the same key are one place when they lie close
together, measured in world yards (each map's world box turns 0..1 into yards): closest for objects,
which do not move; wider for NPCs, which stand or wander a little; widest for large places such as towns,
dungeon entrances and piers. The distances are tuned on our data when the compiler first runs. The place
kept is one real point (point 4), never an average, so a pin never lands between two real spots.

**3. Different places stay.** The same key far apart is a real second place: an NPC with several
spawns, a quest given from two posters, a herb that grows in many spots. Those stay separate pins, and
overlaps are gathered as usual. An NPC with very many spawn points (wanderers, rares) keeps them as one pin
plus its points, not one pin per point: the points are what its spawn area and the quest area are drawn
from.

**4. Which place wins.** The game's own word first (a vignette, a flight point, a place seen within a few
yards), then what was learned on this client, then the shipped data. For facts (level, elite, respawn,
loot, faction) the newest version that has them (*Versions*). Names come from the game at runtime where it
can give them, so they are in the player's language.

**5. One place, several roles.** An NPC that gives a quest, sells food and repairs is one thing with
three roles. It shows the pin of its most important role that the pin filter lets through (quest before
service), and its tooltip lists all of them. Switching quests off in the filter then shows its service
pin instead.

**6. At runtime, against the game's own pins** (Navigation's `Pins.lua`). Some pins come live from the
game, and the game knows better than our database:
- Flight points (`C_TaxiMap`), quest turn-ins and quest areas (`C_QuestLog.GetQuestsOnMap`), the map pin,
  vignettes and Blizzard's own POIs: when a live pin and a database pin have the same key, only the live
  one shows.
- The native minimap's live dots in the small view: services the native minimap is tracking right now
  (`C_Minimap.GetTrackingInfo`) are not drawn by us as well while its dots show.

**7. Proof.** The compiler writes a short report: how many pins there are per kind, how many points were
joined into one place, and the conflicts (same key, places far apart or facts that disagree), so it can be
checked by eye. A test checks that no two pins in the shipped data have the same key and place.

## Dungeon maps

What a dungeon map shows:

| | Dungeon map |
| --- | --- |
| Which | every dungeon and raid of this client, with its floors, Forever's own among them |
| Art | Blizzard's own dungeon maps where the client has them (`C_Map.GetMapArtLayerTextures`); a picture of our own, made for Sane UI (`Doc/guides/images.md`), only where the client has none |
| On the map | bosses (the creature's portrait), entrances, floor links, quest items; player and party live |
| Floors | a menu that follows the player's floor; clickable floor links |

- **Plan:** Blizzard's own art first (it costs no space); our own pictures only for the maps the client
  lacks, each kept small.
- Bosses, entrances, floor links and quest items from Core's data.
- Drawn as *Maps without a world box* where the game gives none.

## Map selector

- A **breadcrumb** on the top bar: World › Continent ▾ › Zone ▾; inside a dungeon the last menu lists its
  floors.
- **Continents:** found at run time (in this client: Kalimdor, Eastern Kingdoms, Zephras), then Dungeons
  and Raids, PvP.
- **Zones** A–Z; the **dungeon list** with a search box.
- A **back button** that remembers the last 30 maps.

# Open questions

Each with a proposal; what is not answered when its step comes is built as proposed.

1. **Walking data:** how dense a graph of walkable points (and so how big), and made from what our tool can
   read of the client's terrain? *Proposal:* as sparse as still gives good routes in towns and tunnels,
   decided on the tool's first output and measured, in Core's pack format.
2. Answered (Saneroki, 2026-10-19: the views at every zoom): terrain everywhere, by the overview far out.
   **Far zoom:** Blizzard's art when zoomed far out (fast), or terrain everywhere (slower)?
3. **Dungeons:** Blizzard's map only in all three views, or a tool for the instances' own minimap tiles?
   *Proposal:* Blizzard's map only; the tool later if wanted.
4. **Spawn areas:** per rare by a click, or also a switch in the pin filter that outlines every rare's area
   at once? *Proposal:* by a click; the switch later.
5. **Small view pins:** which kinds show on the minimap at all, and how near? *Proposal:* quests (givers,
   turn-ins, areas), rares, gathering, services within 300 yards, the map pin and the route; no books,
   chests or patrol paths unless switched on.
6. **Minimap contents:** which of the native minimap's parts come along (tracking menu, zone text, clock,
   calendar, mail, instance difficulty, addon buttons)? *Proposal:* zone text, clock, mail, tracking and
   difficulty as small parts of our own around the small view; no addon buttons.
7. **Window shape:** square (fits the docking window and the native minimap) or round? *Proposal:* square,
   with Core's round corners.
8. **Right-click** as well as the wheel? *Proposal:* yes: right-click steps out one map (zone, continent,
   world), as on Blizzard's map and in the earlier notes.
9. **The game's own window button:** Navigation stands for two of the game's windows, but a window has one
   such button (window guide). *Proposal:* no button on the small window; in full screen the dropdown
   *Classic windows* lists both; the switches *Minimap* and *Map* on the page.
10. **Search in full screen:** zones, dungeons, towns, services and quests? *Proposal:* yes.
11. Answered (Saneroki, 2026-10-17, Data.md decision 18): as proposed.
    **Spawns pack at every login:** with Navigation on, the minimap is open from login, so Spawns loads
    after every login. *Proposal:* Spawns holds what the map shows and stays lean; every creature's spawn
    points (Data.md, decision 18) go into a pack of their own, loaded when asked for.
12. **The game's map in a fight** (when step 0 shows `WorldMapFrame:Hide()` taints): *Proposal:* in a fight
    the game's map opens as the game's, ours waits until the fight is over.
13. **Leveling guides:** made wholly by our tool from Core's quest data, or the tool's draft looked over and
    mended by hand, leg by leg?
14. **Leveling guide hints:** written for each step, or left out?
15. **Leveling guide in the small window:** the current step at the minimap, or only in full screen?
16. **Quests taken and handed in by themselves** on a guide's step? *Proposal:* a switch, off by default.
17. **Leveling figures** (XP per hour, time to level): Navigation's, or the library module's?
