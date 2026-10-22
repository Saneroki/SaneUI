# Navigation

The plan for the **Navigation** module (`SaneUI_Navigation`): the window, the map, the quest log, the pins,
the waypoint, the routes and the leveling guide. Built so far (2026-10-21): the window, both views, the canvas and
its controls, the terrain and the art at every zoom (the water cut away, the zones' maps cut to their outlines),
zones that light up and open by a click, the map moving with its window, the game's minimap over ours (cut to the
window's shape), the game's map kept closed; the pins of the game and of Core's data in the game's quest marks,
quest areas, the party, the quest log and the bar over the full map (the pin filter in sections), the herbs and
ore the game's minimap finds, indoor maps, routes to the map pin on foot, by flight, by boat and zeppelin, by the
Deeprun Tram, by lift, through Teldrassil's portal, by the hearthstone and by the teleports a character has; the
classic dungeons' and raids' maps of
Core's set *Dungeons* in the game's map art, with their floors, bosses and the bosses' 3D models
(`src/Navigation/README.md`). Not yet: a travel pin's ways under the mouse (*Map pins*), the leveling guide, the
dungeons' three zooms, search, the minimap's small parts.

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
- **Zones and continents reimagined (Saneroki, 2026-10-21, replacing for the middle and far zooms "the far
  levels are made from the close ones" below):** the close zooms are unchanged: the accurate terrain
  repainted, square by square, as built (*The lab*, *The whole run*). The middle zoom (a whole zone) and the far zoom (the world) are a
  free, realistic fantasy painting of each zone by the image model: very cool to look at, the zone's mood and
  lore, its general layout and its major places (cities, landmarks, the great mountains, lakes and forests)
  where they lie, the game's own buildings and looks of the zone fed to the model as reference pictures of its
  3D world. They need not be accurate or useful for finding one's way, and need not be seen from straight
  above: a perspective angle is welcome, for the full freedom of the render. The zones' borders fit together,
  each zone clearly sectioned from the next, so the world reads as one picture. Parchment and Scrying keep
  their own views unchanged. Open: the switch-over zoom between the close squares and the zone paintings. (How the
  zone paintings meet: painted per zone, from straight above, and joined along the zones' outlines; below.)
  - **All three from straight above, the zones stitched (Saneroki, 2026-10-22; replacing the far zoom's view from
    a plane at an angle, and answering the open question above):** every level is seen straight from above in the
    same world coordinates, so the three lie over each other: every road, major place and pin is in the same spot
    in each, and one sees where one is in every view. Each zone is painted on its own (its middle and far levels in
    its own frame, 2048 pixels across) and the zones are joined along their outlines into the world
    (`dev/tools/map-layers stitch`, cut by Navigation's zone masks); no continent or world is painted as a whole.
    Each zone keeps its own mood, colours and light by its brief at the far level too; the middle level's
    parchment is each zone's own colour (greenish, yellowish, reddish, whitish by what the zone is: its land's
    colour turned into the game maps' yellow-orange).
  - **Strict maps, all three (Saneroki, 2026-10-21, last of the day; replacing the free paintings of this
    decision and the angled middle zoom below):** the close zoom the terrain, pixel-exact; the middle zoom a
    top-down map in Blizzard's style, in pencil on the interface's parchment, exactly over the terrain, looking much
    like the game's own maps (which are its input); the far zoom a photorealistic aerial render with a very strict
    harness: outlines, locations, biome, mood, atmosphere, lore and layout fitting the zones, the continent and the
    dungeons, not exact but with the major places (cities, landmarks) where they lie in the zone or instance, its
    borders and walls kept. Not free, creative concept art. One pipeline for zones and instances
    (`dev/tools/map-layers`, `Doc/guides/map-style.md`).
  - **The three levels' looks (Saneroki, 2026-10-21, later the same day; for the middle zoom replacing the free
    painting above; since made stricter, above):** the close zoom is the terrain, pixel-exact; the middle zoom is not drawn by code and not a
    free painting but rendered as a beautiful hand-drawn map in pencil on paper, in the interface's own paper and
    pencil (`Doc/guides/interface-style.md`), very strict: every wall, edge and walkable area traced exactly along
    the terrain map. The world's middle zoom keeps its perspective angle; an instance's is seen straight from
    above, in the floor's own frame, so it lies under the close zoom as its ground wherever the terrain has nothing
    to show (rather than black or paper, Saneroki); the far zoom is the free, realistic reimagination
    described here. Text, pins, the bosses' 3D models and every other mark are overlays drawn by code; the
    paintings are only the ground. The same three looks for the instance maps (*Instance maps as the world map,
    apart from it*). The style guide: `Doc/guides/map-style.md`.
  - **Three levels, no continent view (Saneroki, 2026-10-21):** the Atlas has only the terrain (close), the
    zone (middle) and the world (far); the world always shows both continents together, never one continent on
    its own. Only Scrying and Parchment have Blizzard's zone and continent maps and controls (the breadcrumb's
    continent and zone menus).
  - **One smooth world (Saneroki, 2026-10-21):** the Atlas is one continuous world; the wheel zooms smoothly
    from the terrain through the zone paintings out to the world, the map's style blending from one level into
    the next as it goes, never a step or a jump. No right-click steps out a level (*Open questions*, 8).
  - **Middle and far differ (Saneroki, 2026-10-21):** the middle zoom (a whole zone) shows the zone's major places:
    each city, landmark and great feature clearly where it lies (in the pencil drawing, exactly along the terrain:
    *The three levels' looks*). The far zoom
    (the world) is a realistic render of each zone with only a loose idea of its major places,
    the land and its mood first.
  - **No pins far out (Saneroki, 2026-10-21):** the middle and far zooms show no pins; pins are the close,
    accurate terrain view's.
  - **No names in the paintings:** the renders show no text. Names are an interactive overlay drawn by code,
    each kind its own switch: the zones' names and their major places' names on the zone and world views;
    on the world view, per zone, its level range (its enemies and its quests) and the skill it is meant for in
    fishing, herbalism and mining.
  - **Soft borders:** a zone's outline follows the game's only in general, never pixel by pixel, with natural
    transitions into the next: the game's harsh, straight lines and abrupt changes of biome are softened and
    made realistic.
  - **Lore over the open map:** where the game's zone is a cut-open view, the far zoom shows what stands there
    in the lore, while the middle zoom keeps the open view: Teldrassil and Darnassus the world tree itself, not
    its open crown; Ironforge an imagined open mountain with the city inside in the middle zoom, and the
    realistic full mountain landscape far out. The same for the other places under the ground or under a roof.
- **Dungeon, instance and raid maps in three zooms (Saneroki, 2026-10-21), as the world map:**
  - **close up:** the accurate terrain of the instance repainted, pixel-exact, as the Atlas' close squares;
  - **in between:** the rooms, corridors and walls exact in their shapes and sizes, so it is useful in the game.
    First planned as a clean map drawn by code; since (Saneroki, 2026-10-21) rendered as the world's middle zoom
    is: a top-down map in the manner of the game's dungeon maps, in pencil on parchment, exactly over the
    instance's terrain, the ground the close zoom lies over;
  - **zoomed out fully:** the instance as a whole, a photorealistic aerial render with its layout, halls and rooms
    where they lie (first planned as a free reimagination; made strict, Saneroki, 2026-10-21).

  Made after the zones. **The pipeline (2026-10-21):** `dev/tools/map-layers`, for zones and instances alike: an
  instance's terrain is its own map's tiles with the indoor maps of the buildings they place (extracted from the
  install into a folder of its own), painted at the close level by the Atlas' own code; its floors' middle maps
  from that terrain and the game's map art in the same frame; its far render from the terrain seen from a plane
  (a zone's with its heights standing up and the walking data's water, held by controls; 2026-10-22), and the
  close painting; each middle and far painting checked for its outlines and by a vision model. The briefs are
  `dev/imagegen/maps/dungeons.toml` (30 instances, researched from the game's lore texts and pictures and from
  play) and `zones.toml`; the shared words `levels.toml`. Samples painted (2026-10-21): Westfall and Tanaris, the
  Deadmines, Zul'Farrak and the Hall of Thanes, all three levels; the Eastern Kingdoms and Kalimdor whole, middle
  and far at an angle (2026-10-22, given up); then from straight above, each zone on its own, Westfall joined with
  Elwynn Forest and Duskwood (`stitch`); Duskwood, Ashenvale, the Deadmines and the Hall of Thanes compared with
  the game's terrain and maps, layer over layer.
  - **The world map of high resolution tiles (Saneroki, 2026-10-22, replacing for now the close and middle levels
    and their jobs):** the far renders are so precise that the world map is made of them: every terrain tile of
    the Atlas' grid painted with the far harness at 2048 pixels (3.84 a yard, eight times the game's minimap) for
    the closest zoom, the squares joined into one world; the final tiles of the game's map. Coarse to fine
    (`map-layers tiles`): each square's colour and light from the zones' far renders over it, its shapes from the
    game's terrain, its heights and water lines the controls, its zone's words, so neighbours share their light.
    The water dark blue, dark blue-green in the shallows (the bright blue stood out). The GPU job `worldtiles`
    (priority 10): the zones' far renders, then the 1456 squares of land. The instances: one large far render
    each, once the new game build's tables are in (1.60.1.70532 is installed; their terrain is extracted by build).
  - **The world map offline (Saneroki, 2026-10-22):** `dev/tools/world-map` (`saneui makeworldmap`,
    `showworldmap`): every layer laid where the game lays it and stacked in a web page, a slider each, from a whole
    continent down to the finest blocks: the game's terrain and zone maps, our zone renders and maps, our tiles
    packed by the Atlas' own pack, the Atlas' pack read by the Atlas module itself under Lua 5.1; the instances.
    For refining the world map outside the game.
- **Instance maps as the world map, apart from it (Saneroki, 2026-10-21):** the instance maps are completely
  independent of the world map and separate from it (their own view, data, pictures, packs and jobs; never part of
  the world's picture), but they work in the same way and are made in the same way: the same three levels, one
  smooth zoom through them, the same render pipeline, words, ComfyUI tools and terrain cleanups as the world map's
  layers (its softening, check against the game's water and lava, colour pass, pixels a yard, outlines clear
  around), so they are coherent with it in style and precision. The words they share are in
  `dev/imagegen/maps/levels.toml`; the briefs have the zone briefs' fields (`dungeons.toml`, `zones.toml`).
  Their own rules stay (*Instance maps keep rules of their own*: no players, the bosses in 3D in every zoom).
- **Dungeon maps now, with their bosses (Saneroki, 2026-10-20 and 21):** until the three zooms are made, every
  dungeon and raid (only those, no other instances) has a map in Blizzard's style: the game's own map art of it,
  floor by floor (Forever's client has none, so Core's set *Dungeons* holds them, from Blizzard's own tables; the
  art files are in Forever's install), each boss's icon where it stands, and the boss's 3D game model standing on
  that spot.
- **A boss's tooltip on its map (Saneroki, 2026-10-21):** its abilities and the items it drops, with their names
  and icons, from what is known of the dungeons (built: the set *Bosses*' `abilities` and `loot`, batch 11, used at once and shown as not yet confirmed until the
  client or the server confirms them (Saneroki, 2026-10-21); the
  names, icons and qualities the game's).
- **Instance maps keep rules of their own (Saneroki, 2026-10-21),** apart from the world map's and its indoor maps':
  - **No players on them:** Forever tells no player's place inside an instance (not in its current versions), so an
    instance's map shows neither the player nor the party or raid, and its floor is not chosen by where one stands.
  - **What stands still is shown:** the enemies' and the bosses' places are fixed, so they can stand on the map. Built
    2026-10-21: the bosses of 23 dungeons and raids, and the enemies of six (Ragefire Chasm, Wailing Caverns, the
    Deadmines, Shadowfang Keep, the Stockade, Blackfathom Deeps) as small red dots.
  - **The bosses in full 3D:** each boss as its 3D game model where it stands, in every zoom of the instance maps
    (the three zooms to come too).
- **Indoor maps only inside buildings and caves (Saneroki, 2026-10-21):** the world map's indoor maps lie over the
  map inside a building or a cave, never on a street; Stormwind's and Orgrimmar's streets and squares (each city is
  one building to the game) keep the city's own map.
- **Soft zone edges, exact inside (Saneroki, 2026-10-21):** the close terrain view stays as accurate as planned,
  down to the tiniest walkable places. Only the outermost outline of a zone, and only where the player cannot
  go (the mountains between zones, the edge of the world), is blended into a natural transition instead of the
  game's pixel-exact edge of the zone's terrain. Everything the player can walk or swim stays pixel-exact:
  every coast and shore into the water, piers, docks and bridges, and every pass from one zone into the next;
  nothing inside the zone is softened or moved.
- **Scrying and Parchment stay exact (Saneroki, 2026-10-21):** the soft borders and every reimagination are the
  painted Atlas' alone. Scrying (the terrain) and Parchment (Blizzard's maps) keep drawing the game's own files
  pixel for pixel, only cut so that neighbouring zones do not overlap, as they are built now.
- **A size budget (Saneroki, 2026-10-21):** before the big runs, each map pack's size is reckoned (the Atlas'
  close squares, the zone and continent paintings, the three zooms of every dungeon), for the player's disk, its
  memory and loading in the game, and Git LFS's space. That decides each level's pixels a tile, what loads only
  on demand and in which pack, and what is committed (only the chosen art, *Workflow*).
- **Stale paintings after a game update (Saneroki, 2026-10-21):** when a new Forever build changes the land
  (a new building, a moved road, a reworked zone), a comparison of its terrain and indoor files with the ones
  painted from (to be built: today `dev/tools/blizzard` compares only the interface) names the tiles and indoor
  maps that changed; the paintings made from them are marked stale and only those go to the GPU
  runner to be painted again (and into the review queue), never the whole map.
- **A review queue (Saneroki, 2026-10-21):** finished paintings (the Atlas' squares, the zones', the dungeons')
  go into a queue to review: a contact sheet where each is taken or sent back to be painted again, after the
  automatic checks (the game's water and lava). The GPU runner (`dev/tools/gpu-runner`) paints what is sent
  back; only what is taken goes into the packs and, once chosen, into Git.
- **Indoor maps are clear around, never black (Saneroki, 2026-10-21), very important:** every indoor map (the
  buildings and caves of the continents, Stormwind's districts and canals, Ironforge's halls, the dungeons'
  close-up and in-between maps) has a transparent background and is as accurate as the terrain views, in the
  same place and scale, so it lies seamlessly over the terrain view when the player goes inside. That holds for
  the painted versions too: a painting of an indoor map is cut to the game's own outline of it and keeps its
  alpha (`dev/tools/indoor-art` already makes the game's indoor maps so). Only the fully zoomed-out
  reimagination of an instance (above) is a picture of its own.
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
  from the close ones, never painted on their own; since 2026-10-21 only the close levels, *Zones and
  continents reimagined*). The **terrain is the base**: the painted view is the terrain repainted in that look, every building, street,
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
- **The quest log as Saneroki asked it (Saneroki, 2026-10-21):**
  - **No scroll bar:** the mouse over the list and its wheel scroll it. Only while the list is longer than fits
    and the mouse is on it, a scroll bar shows, on the side the window is docked to (at the left edge: its left).
  - **Each quest's icon at its left,** as its pin on the map has it.
  - **A click puts the game's map pin on the quest's objective:** the quest's mark on the map (its question mark)
    or the area where its foes are.
  - **The right button:** the quest's text (its dialogue: objectives and story), or the map moved to its
    objective (and the game's track, share and abandon).
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
- **Our own pin icons, to come (Saneroki, 2026-10-21):** the pins' icons get redesigns of our own in Sane UI's
  style (`Doc/guides/interface-style.md`, *To redesign*): coloured renders of our own pins, developed soon. Until
  they come, the game's icons below stay.
- **A travel pin's ways, to come (Saneroki, 2026-10-21):** the mouse over a flight point, a boat's or zeppelin's
  dock or the tram's entrance draws on the map, as elements of their own, the ways the character can take from
  there: the flights to the flight points it has found, the boats', zeppelins' and the tram's ways to their other
  docks. Flights from or to a flight point it has not found yet are drawn too, a little differently, so the map
  shows what is still to be found.
- **Herb and ore icons** are Blizzard's own profession tracking icons.
- **Quest marks as the game's (Saneroki, 2026-10-20):** a quest in the log the yellow question mark; one the
  character can take the standard yellow exclamation mark, opaque (no longer see-through); one too low to give
  experience grey; one whose requirements are not met yet a red question mark.
- **Tooltips without the click (Saneroki, 2026-10-20):** a pin's tooltip does not say that a click puts the map pin
  there.
- **The pin filter in sections (Saneroki, 2026-10-20):** the dropdown is laid out in titled sections and
  categories, easy to scan, with large icons.
- **A rare's 3D model with Alt (Saneroki, 2026-10-21):** Alt held over a rare enemy's map pin shows its 3D model
  beside the tooltip, as the tooltips show your character beside a piece of gear.
- **Every pin is clicked for the map pin, the minimap's too (Saneroki, 2026-10-21):** on the small map and on the
  game's own minimap the icons Sane UI draws, the gathering nodes found around the player among them, take a
  click and put the game's map pin there. (The game's own minimap dots take no clicks of an addon.)
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
  rares and travel, its vignette atlases, its tracking icons, until our own pin icons replace them (*Map pins*,
  Saneroki, 2026-10-21). A picture of our own only where the game has
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
- **Leather stitches, to come (Saneroki, 2026-10-21):** the route line is to look like leather stitches, in Sane
  UI's style (`Doc/guides/interface-style.md`, *To redesign*), and replaces the golden line.

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
  right-click to the world map (now: the scroll wheel zooms; no right-click, *Open questions*, 8).
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
7. **Known flight points:** the map's taxi list holds every node on this client, found or not; only the flight
   master's map is reliable (`TAXIMAP_OPENED`, `C_TaxiMap.GetAllTaxiNodes`), kept per character. Its nodes the
   character has not found are `Unreachable` (the game's flight map leaves them out), and the map's list marks each
   node `isUndiscovered` once a flight master was opened this session (the game knows them only then). Until
   2026-10-21 every node a flight master listed was taken as found, so routes flew from and to flight points the
   character never had: now only the found ones (`flightPoints`, `Planner.Knows`), and the map shows the others red
   (Saneroki, 2026-10-21).
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
| Live minimap dots (tracked herbs and ore, party, town tracking) | Yes, in both views (Saneroki, 2026-10-20: on the full map too, the native minimap around the player at the map's scale) | The engine draws them only on the native minimap, which follows the player at its own zoom steps. |
| Map follows the player; separate zoom and position per view | Yes | Positions may be hidden in some places (*to try*). |
| Quest log on the left in full screen | Yes | Our own list; Blizzard's is bound to its map window. |
| Map selector for regions and dungeons | Yes | Dungeons in three zooms (*Dungeon, instance and raid maps in three zooms*). |
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
| `DockWatch.lua` | At a dock: its ships' destinations and times; aboard, when it lands | yes |
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

- **Drag** with the left button pans (and stops following). **Wheel** zooms. No right-click to step
  out a map (Saneroki, 2026-10-21; built: `Canvas.lua` still steps out on a right-click, to be taken out). **Ctrl-click** sets or clears the map pin,
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
- **The open sky (built 2026-10-20):** Zephras Isle floats: around it lies no water but the void, the terrain's
  holes and the cliffs under its rim, which the game's minimap leaves pure black. The tool cuts that away as it
  cuts the sea: a sample the minimap texture leaves black is sky when black samples join it to a place of the
  grid with no tile (spread a sample a step from there). A dark place within the land (a city's tunnels) and a
  building over the void (the zeppelins' tower) stay; on the continents no black reaches their grid's edge, so
  nothing there changes. The outlines then keep the isle's land and a little sky, as a coast's shore.
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
  - The game's own textures without their repeats (Saneroki's idea, 2026-10-20): each ground texture laid 8 by 8
    times and painted by the edit model as one patch of the same ground (21 seconds each, all 421 in about two
    and a half hours). The repeats go and the materials stay, except Darnassus' bark (painted as pebbles; its
    planks are drawn by the blend maps, which keep them) and the game's two blank placeholder textures (left out).
    The map built from them: the best fine layout and the game's colours, still game-like; painted over with the
    edit words it drifts more than the chosen method (fine layout 0.82 against 0.90). Fixed on the way: texture
    pieces placed by the continent, not the tile, and blend maps enlarged per tile, not per chunk (both drew
    straight lines), heights interpolated smoothly and softened for the light (they drew stair steps).
  - A blind check (2026-10-20): 24 squares drawn at random from the plan, both continents: every one faithful in
    shape (layout on land 0.95, the hard places 0.98), 3 failing the water check (a lake painted dark teal; a
    bluish forest and snow shadows taken for water), repainted by the run. One invention: on Loch Modan's blank
    plateau beyond its mountains (one plain filler texture, out of the players' reach) a field and a row of pines
    on a narrow ridge. A sentence that plain areas stay plain did not help. Next to try: where the game's data
    says a chunk is that one plain filler, the map shows the game's own ground built from its data.
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
- **Gathering overlaps:** pins that would cover each other on screen become one marker in the icon of the first
  (drawn highest; no number, built 2026-10-20), placed at their middle. A click on it zooms in until they part; where they share one spot even
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
- **Actions:** a click puts the game's map pin on its objective (`GetQuestsOnMap`, else `GetNextWaypoint`; a
  preview's at its giver) and focuses it (`C_SuperTrack.SetSuperTrackedQuestID`), the camera staying; the right
  button: its text below the list (`GetQuestLogQuestText`, shown only once asked for), show on the map (the camera
  goes to the objective), track (`AddQuestWatch`, `RemoveQuestWatch`), share, abandon (`SetAbandonQuest`,
  `AbandonQuest`, after a question of our own). Built 2026-10-21.
- **No scroll bar at rest** (built 2026-10-21): the list's `MinimalScrollBar` shows only while the mouse is on
  the window and the list has more than its room (`HasScrollableExtent`), at the window's docked side.
- **Never Blizzard's quest panel functions** (`QuestMapFrame_OpenToQuestDetails`, `ShowQuestComplete`):
  called from addon code they taint the map's pins. Nor its quest details window (`QuestLogPopupDetailFrame`):
  it opens by `ShowUIPanel`, which our call would leave tainted (`Doc/guides/addon-standards.md`, *Known traps*);
  the quest's text is our own.
- **A view of its own,** in its own file and frame, so it can stand on Core's full screen *board* once
  Core has one (window guide, *Not built yet*); until then the window lays out map and quest log in its
  `docked` hook.

## Top bar, map selector and search

- **Map selector:** a breadcrumb World › Continent ▾ › Zone ▾ (*Map selector*), menus by Blizzard's menu
  system (`MenuUtil`, `WowStyle1DropdownTemplate`). Continents and zones from the map tree at run time;
  dungeons from Core's data and the tree's maps of type *Dungeon*.
- **Pin filter:** a dropdown with a checkbox per kind (`CreateCheckbox`), in titled sections (built 2026-10-20:
  `ns.PIN_SECTIONS`, each kind's `section`; around you, quests, travel, towns and services, rares and treasures,
  gathering), each kind's icon at 24 before its words and a slider for its size.
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
- **Built (2026-10-21): routes from the player, on their floor, over every plane.** Saneroki: a route that goes
  into a building or a cave and out again did not work, routes across the continents by tram, flight and ship not
  well, and the line should always run from the player to the pin.
  - **The floor:** the walking data holds floors one over the other (a cave under a hill, Ironforge under its
    mountain, a building's storeys), and the game tells no height (`UnitPosition`'s third answer is always 0).
    Every lookup took the first floor under a point: a way out of a cave could start on the hill over it, the
    tram's entrance in Ironforge lay on the mountain (the city's floor lies a yard off it in the data), and a
    place's region could come from the wrong floor, so that the planner ruled its walk out and drew no line at all. Now
    the player's floor is followed as they go (`Walk.Follow`: from the rectangle they stood on through the openings
    nearest the way they went, every quarter of a second while there is a pin) and chosen where it cannot be
    (`Walk.Floor`: near the height they had; else outdoors the highest under them, indoors the lowest within 6
    yards). The search starts on that floor and ends on any floor of its regions at the pin (*The walking data*,
    *The search*). A place's regions are those of every floor under it and within 20 yards (a zeppelin's tower
    and its foot); two places that share none are still a walk, 60 seconds dearer (a lift, a mesa: Thunder
    Bluff's flight point, the towers of the zeppelins to Zephras Isle stand on regions of their own).
  - **The line from the player:** where along it the player is (the cut) is found at every step of the canvas'
    tracker, from where they were on (a part from one plane onto another, the hearthstone's, at its end on theirs);
    the parts behind are not drawn, and a line runs from the arrow to it (`Route.Cut`).
  - **Every plane:** the graph holds every plane's known flight points, docks, the tram and the hearthstone, so a
    journey crosses a third plane where that is quickest (the hearthstone home, then a ship; Zephras Isle by way of
    a continent). A flight point is two places, on the ground and in the air (the air reached by a flight only since
    2026-10-22, *No walk after a walk at a flight point*): a flight over many takes off and lands once, and is one
    leg. Aboard a ship the plan does not have (Core's `Data.Trips`), a new pin is planned
    from the pier of the dock it comes to; a ship's landing plans anew. The tram's wait is the time to its next
    train where a ride taught its times (`Trips:TramNext`).
  - **One job:** the journey and its walks are one job of Core's scheduler (a place's floors looked up only for a
    walk that may still be part of a quicker journey, their regions kept since); Walk keeps the 48 tiles asked for
    last.
  - **Checked against the real data** (2026-10-21, the set *Walking* read outside the game): every dock's pier
    (within 60 yards) and both of the tram's entrances share the main region of their continent within 20 yards;
    the flight points that do not stand on mesas or where the data has no floor (Thunder Bluff, Freewind Post,
    Aerie Peak) or in Mount Hyjal's own region. In Ironforge the walk from the flight master to the tram's entrance
    is 327 yards through the city (it was 1,551 over the mountain: the entrance's own floor lies a yard off its
    point, under the mountain's), and back alike; from south of the city the walk comes in by the gate at the
    city's height. In Stormwind, from the flight master's platform down its ramp and through the streets.
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
  - **Not in the tables:** the ships' speed and timetable. **Built (2026-10-20): Core's timetables**
    (`Data.Ships`, `Doc/guides/data.md`, *The ships' times*): between two stops a ship sails at the game's
    transports' speed (speeding up and slowing down into a stop), a leap takes no time; the time once round is
    the set's `wait` where Forever has the original game's way (a batch, unverified), else the sailing and the
    stays, corrected by a second ride. When a ship really sails on a realm is learnt on a ride: the player's
    place in the world moving along its way at its speed says when it left its last stop; kept for the realm on
    this computer, trusted half a day. The planner's wait for a ship is the time to its next departure where
    that is known, else half its round; nothing guessed is in the master.
  - **At a dock (built 2026-10-20, `DockWatch.lua`):** within 60 yards of where a ship stops, under the game's
    widgets at the top of the screen, a row for each ship that stops there: its icon, where it goes, and when it
    arrives and leaves, counting down (grey, how often it sails, until a ride taught its times); aboard, when
    it lands. The setting *Ship times at a dock* (on); not while the map fills the screen.
  - **The trip on screen (built 2026-10-20, `TripView.lua`, Core's `Data.Trips`):** on a flight, a ship or the
    tram, two thirds up the screen (2026-10-21, Saneroki): the start and the end named above the ends of a fine
    golden line in the map route's art, filling smoothly (eased every frame between Core's looks), the vehicle's
    icon at its tip, a flight point's mark at each stop, the time to the end, the next stop and its time, the zone
    below; on a flight with a stop before its end the game's own *Request Stop* button
    (`TaxiRequestEarlyLanding`, its art and words). A flight's route is read at the flight master
    (`TakeTaxiNode`: its hops, each the set's flight), kept per character for a `/reload` in the air; how far
    along from the player's place on the hops' points, how long at the pace measured on this flight, before that
    the median of the character's last five. The setting *Your trip on screen* (on). While flying the planner
    draws the flight's way on as the line's first leg and plans from where it lands; without a pin, the flight's
    way alone.
  - **Waiting (built 2026-10-21):** at a dock or the tram's station the same overlay shows the next to come: the
    line filling from when it last left there to when it arrives, *Board now* while it is in, when it leaves, the
    others there below; how often it comes while its times on this realm are not known. The tram's times are
    learnt on a ride as the ships' are (Core's `Data.Trips`: when its train left its station, three looks that
    agree; a train leaves each station every `wait` seconds and stands there `wait` less its run).
  - **The tram (2026-10-20):** the Deeprun Tram is a way of Core's set *Travel* (kind `tram`), from the game's own
    tables (`dev/tools/travel-data`): its two stations (the triggers in its map where one leaves it), the run's
    seconds (its cars' motion, the same for every car), the time between two trains from a station (`wait`: its
    cars' motion once round, 143.333 seconds, over its two trains, which set out from the two stations together),
    the cities' entrances as its docks (pins).
  - **The tram in the journey (built 2026-10-20, `Planner.lua`, `Tram`):** its two entrances are docks of the graph
    on the Eastern Kingdoms' plane (`Coords.PlaneOf` of each entrance's city map), boarded and left right there
    (no pier); the way between them costs the walks down and up and the loading screens (`Planner.STATION`, 30
    seconds, a guess until timed in play), the wait (half of *Travel*'s `wait`) and the run (`time`). Its leg is
    drawn red, straight from entrance to entrance: the tunnel's own map (369) has no plane, so the game tells no
    place in it there and the line stays as it is until the player comes out at the other end.
  - **In the journey:** each dock a place of the graph, boarded and left at its pier (the floor of land nearest
    where the ship stops), a way from every dock of a ship to every other; the graph spans every plane (a
    continent, or Zephras Isle: below; until 2026-10-21 only the player's and the pin's), each place in its own
    plane, walks only within one plane. The ship's leg
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
    and from Kalimdor) are in the journey, and the map pin's mark shows there. The walking data covers the isle
    too (below, *The isle's terrain*).
  - **The map on Zephras Isle (built 2026-10-20):** the canvas uses the planes too, so its views work on the isle
    as on a continent: they follow the player there (`Coords.Player` gives the isle's plane), come in over it from
    the world (`Coords.PlaneAt`, a continent or such a map under a point of the world map) and open it by a
    click, list it in the map selector after the continents and in the quest log's search, and draw its pins (its
    zeppelins' tower, the game's own) and the party there. A plane that is no continent is a zone, its own one
    (`Coords.Alone`; `Coords.ZoneAt` and `Coords.Zones` give the isle itself): its zone's level reaches out to the
    world with no continent's between, and a right click on it goes to the world. At the world off the isle the
    camera goes into the plane under the middle at once, so over a continent the world is left at the
    continent's own zoom, not at the isle's. The continents' levels and drawing are unchanged.
  - **The isle's terrain (built 2026-10-20):** the isle has the continents' data, from the game's files of its own
    map (2991): its 72 tiles in Core's set *Tiles* (the game's minimap textures), its overview and stitched map
    (four blocks each) and its outline (`dev/tools/terrain-art --maps 2991`, the open sky around it cut away:
    *The open sky*), and its walking data (`dev/tools/walk-data --maps 2991`: 26 tiles with ground, the docks of
    both zeppelins on the island's own region). `Terrain.Overview`, Art's maps under the stitched map and
    Painted draw every plane (`Coords.Planes`), so *Scrying* and *Atlas* show its terrain and *Parchment* its own
    map, frame faded off, under its stitched map and, up close, its map cut to its outline over both (the maps
    under the stitched map have pool keys of their own, so one map can be drawn under it and over it).
    `--maps` leaves the other maps' files and lines as they are, so the continents' are not made again for the
    isle. Its minimap textures are the Forever beta client's, as the continents' were: the newer build (70450 over
    live's 70245, whose textures differ a little in many tiles; the isle's tiles and file IDs are the same in both),
    and the client the build installs into.
  - **Not yet:** Zephras Isle's painting (the Atlas); a new route kept only when clearly better. Which side's town a
    dock stands in is not in the client's tables (a town's guards are the server's); since 2026-10-21 a ship's side
    is its towns' by the flight masters near its docks (below, *the portals*).
- **Built (2026-10-21): the lifts.** Saneroki: a route into the Undercity or up Thunder Bluff's mesas should walk to
  the lift, ride it and walk on, not end as near as one walks and run straight to the pin.
  - **The data** (Core's set *Travel*, kind `lift`, `dev/tools/travel-data --lifts`): the client moves each lift's
    car (its `TransportAnimation`) but does not say where it stands; that is batch 10 of `sources.toml` (unverified),
    picked where every record of it agrees, the client moves it as the original game's does, and Forever's own world
    has a floor at both ends. The tool reads the motion: a car going straight up and down, standing once a round at
    each end and nowhere between, rising ten yards or more (a door less). A car is a record of its own (our own
    number from 1100001, kept for a car at the same place): its two ends in the world's yards with their heights
    (`path`, the lower first; the path's new part `z`), its slower ride (`time`), the time between two departures
    from an end (`wait`, its motion once round), its rise (`length`), its ends on the zone maps (`from`, `to`, the
    pins). Fourteen cars in build 70245: Thunder Bluff's four (two pairs side by side, 10 seconds a ride, 30 once
    round), the Undercity's three (3.5 and 16.7; Forever's own cars there, new IDs of the same motion), the Great
    Lift's two, Freewind Post's two, Gnomeregan's, and two small ones (Gnomeregan's surface, Azshara's coast).
  - **In the journey** (`Lifts.lua`, `Planner.lua`): each end of a car at its landing, the floor of the walking data
    beside its shaft nearest its height (`Walk.Landing`, within `Lifts.LANDING` yards), only a car both of whose
    ends have one (since 2026-10-21 all fourteen: the walking data keeps the regions lifts land on); the ride from
    one end to the other costs half the time between two departures and the ride.
    The ends' regions are their landings': the lower in the land or the city, the upper on the mesa or the ruins.
    Between two levels a lift joins there is no walk: the lift is the way (until then such a walk cost
    `Planner.APART` more, and a lift's level was reached as near as one walks). A walk's guess between places of
    known heights counts the climb (the Great Lift's two ends lie two yards apart, 130 over each other).
  - **Stacked and side by side:** the Undercity lies under the ruins of Lordaeron, whose floors the walking data
    holds over the whole city, so a pin there, or its flight master, had the ruins' region too and every walk to it
    stayed up there. Two levels are stacked where, on a ring `Lifts.RING` yards round their lifts' shafts, at least
    a third of the lower level's points lie under the upper (the Undercity: 58 %; Thunder Bluff's mesa beside the land
    at its foot: none). A place stands below a stacked lift's upper level (`Lifts.Stand`) where it lies over the
    lower level: its own floor known (the player's) under the upper's; else the lower level's floors under it; a pin
    on the lift's own map (the Undercity's) also over any floor below there, or the nearest within `Lifts.RING`
    yards (the city's lower parts; where its own floor is missing from the walking data); it stands on the floor
    below that showed it, and is reached from the upper level only by the lift. A pin on Tirisfal Glades' map stands
    on the ruins, but over the lower level's floors (the bank, whose floor the walking data holds since 2026-10-21).
    By a lift side by side the upper landing overhangs the platform at its foot: there a place stands on the upper.
  - **The floor after a ride** (`Rode`): the game tells no height and no opening leads through a shaft, so the floor
    followed would stay at the end one boarded. At a lift joining the line's lift's two levels (`Lifts.Near`,
    within `Lifts.NEAR` yards: the planned car or one beside it) as long as its ride takes, then on along the line
    past it, the player is on that lift's landing at the other end.
  - **On the map:** a lift is a pin at its shaft (`Data.Map`: a way's place at `from` and `to`), named a lift, not
    yet confirmed by the game.
  - **Checked against the real data** (2026-10-21, outside the game, the planner on the set *Walking* and the
    lifts): from Mulgore to Thunder Bluff's flight master, by either lift, and back; from the ruins of Lordaeron to
    the Undercity's flight master, its bank, the Magic Quarter, the Royal Quarter and the War Quarter, and out
    again: walk, lift, walk each.
  - **Built (2026-10-21): the walking data joins the city.** The Undercity's ring, its lower parts, quarters and
    sewers are one region, and the lifts' upper landings join the throne room through their arches; Freewind Post's
    mesa and Gnomeregan's landings are kept (*The walking data*, *What players walk between*). The sewers also lead
    out to a cave on the hillside west of the ruins, so the city and the ruins are one region too. **One region:**
    where a lift's two landings lie in one region, `Lifts.Levels` joins two levels there all the same where they are
    stacked round it (`level.alone`, that lift), told apart by height: the upper from halfway between the landings up
    (`level.split`), the lower within `Walk.RISE` yards of its lower landing's height (`level.low`); a place stands
    below them only round the lift: on a map its ends lie on (in that map's box: the Undercity's, the whole city),
    or within `Lifts.SPREAD` (250) yards of it (*The whole city below*), and such a level joins no two regions
    (`Lifts.Joined`). The planner keeps a place below a level and one on it apart also where they share a region
    (`Over`: the lift is the way; two places below one level are a walk apart). A lift within one region whose levels
    lie side by side (the Great Lift) joins none.
  - **Checked against the real data** (2026-10-21, the new walking data, outside the game): from the ruins to the
    city's flight master, bank, quarters and throne room and out again, from the canyon to Freewind Post's flight
    master and back, from Dun Morogh down Gnomeregan's lift: walk, lift, walk each; from the lift's lower landing
    into the Magic Quarter on foot all the way; Thunder Bluff's flight master to the Elder Rise over its bridge.
  - **Fixed (2026-10-22): the whole city below.** Found with the teleports on the real data: Teleport: Undercity
    lands near the lifts, below their upper level, while Sylvanas in the Royal Quarter stands 265 to 330 yards from
    the city's three lifts, beyond `Lifts.SPREAD`, so she counted as on the ruins: no walk between the two, and the
    route went up a lift, over the surface and down by the sewers (1,577 yards where one walk in the city is 881;
    the hearthstone bound there the same). From Sylvanas to the flight master, the inn or the bank the walk went to
    a lift's upper end but ended on the canal under it (the search ends on any floor of its regions there), and the
    line rode down from up there; from Brill, the zeppelin tower or the ruins the walk ended on the hill over her (33
    yards high, she at -60); the Magic Quarter's mage trainers (256 yards out) likewise. On the walking data the
    city's floors under the surface reach 344 yards from the nearest lift (9 % of them beyond `SPREAD`: the Royal
    Quarter, the Magic Quarter's far end, the sewers' tunnel out to the west), every one inside the Undercity map's
    box. So a place now stands below such a level on a map the lift's ends lie on (`Round`: in that map's box, the
    game's own bounds of the city), else within `SPREAD` yards of the lift (one on no map). Checked again: the
    teleport and the hearthstone one walk of 881 yards (52 to the mage trainers); from Sylvanas to the flight
    master, the inn and the bank on foot, to Brill on foot to a lift, up it and on; from Brill, the zeppelin tower
    and the ruins down a lift to her floor. The 200 journeys between NPCs' places, outdoors and indoors, are the
    same route for route; of the fixed journeys only Orgrimmar to Sylvanas changed (the zeppelin, then down a lift
    into the city). Levels of two regions (Thunder Bluff, Freewind Post, Gnomeregan) and the Great Lift are as they
    were. Left: the sewers' tunnel, where it runs under the hill below the split, is the city now, so from there to
    the surface the route goes back to a lift (1,239 yards and the ride) rather than out by the cave (1,088); and,
    not the lifts' rule, a flight point's place lets a walk go on from another of its floors (up and down at it,
    `Planner.BOARD` seconds): from the lift Orgrimmar to Sylvanas walks to the bat handler on the ring and on from
    the floor under it, and 7 of the 200 journeys walk twice in a row so (fixed since, below).
  - **Fixed (2026-10-22): no walk after a walk at a flight point.** A place reached on foot is a node of the journey
    of its own, from which no walk goes on; but at a flight point the journey went up into the air (`Planner.BOARD`
    seconds) and straight down again to the ground, from which walks leave, and those start on every floor at a
    place whose own floor is not known (the lowest first). So a route walked to a flight point on one floor and on
    from another where the walking data has no way between them (from the lift to Sylvanas: 78 yards to the bat
    handler on the ring, 588 on from the floor under it), and got round regions the search had found no walk
    between (from Rut'theran Village straight to Nighthaven's flight point, then on to Moonglade's other one). Now
    taking off is part of the first flight (the flights from a flight point on the ground, each with
    `Planner.BOARD`), so the air over a flight point is reached by a flight only and one comes down there only after
    a flight; a flight that lands still walks on, and walk, take off and fly cost what they did. Checked on the real
    data (outside the game, the walking data of 2026-10-22, the code before and after): of the 29 fixed journeys only
    Orgrimmar to Sylvanas changed (the zeppelin, down a lift, one walk of 748 yards), and of the Undercity's those
    from Brill, the zeppelin tower and the ruins to her the same way. Of the 200 journeys between NPCs' places the 7
    that walked twice in a row (8 with indoors in turn) no longer do; walks drawn straight 14 to 10 (the Horde's
    from Teldrassil now walk to Zoram'gar and fly); none, walks off the data and lines not from the player 0 as
    before; 619 ms a route (643), the slowest 4.3 s (5.8). One other journey changed by chance only: out of a place
    no walk is found from (Archmage Xylem's) every way costs the same, and another is drawn straight (488 yards to a
    flight point, where it was 9,495 to a portal).
- **Built (2026-10-21): the portals; routes checked on the whole real data.** Saneroki asked whether the routes are
  reliable, flexible and robust: checked outside the game, the planner, its search and Core's timetables over every
  walking tile, the game's flight points and the set *Travel*, on journeys through the cities and 200 between NPCs'
  places (both sides, both continents and the isle).
  - **The portals** (Core's set *Travel*, kind `portal`, `dev/tools/travel-data --portals`, batch 12 of
    `sources.toml`, unverified): the client holds a portal's trigger (its `AreaTrigger`), not where it brings one;
    picked where every record agrees, it asks nothing of who steps in, no door stands at it, there is a way back and
    Forever's world has a floor at both ends. Four in build 70245: Darnassus and Rut'theran Village (the only way
    between Teldrassil's top and its shore), Stormwind's Wizard's Sanctum up and down (its rooms in the walking
    data since 2026-10-22, closed off from the streets in the game's own walls: a route takes it for a pin in them,
    from Dalaran by the Skyborne portal; the map shows it). A record per trigger: its key 1200000 + the
    trigger's ID, `path` its place and where it brings one, each with its height, `length`, `from` and `to` (pins).
  - **In the journey:** a portal's two ends are places on their floors (`Walk.Landing` within `Planner.ARRIVE`
    yards), the way through `Planner.PORTAL` seconds, drawn violet; after the leap the floor followed is the one where
    it brings one (`Arrival`).
  - **Found and fixed:** aboard in the town at a ship's dock (`Planner.DECK`, `Along`); the floor guessed outdoors
    (the highest: Orgrimmar's rock overhangs, a rock's top) with no walk leaving it (`guess`, `Search.ASIDE`); the
    height from before a leap; a walk between places that share no region taken on its guess though the search
    finds none, drawn straight (Teldrassil's top to Moonglade): now none, and so every walk between those regions,
    and the journey is chosen again (`Planner.TRIES`, `Planner.BUDGET`); walks after walks (a place reached on foot is a
    node of its own), which let the choice wander. Straight walks in 200 journeys: 21 before, 10 after (most for one
    side deep in the other's lands, where the plan's budget ends the choosing).
  - **A ship's side** (Core's set *Travel*, `side` of a boat, zeppelin or the tram; `dev/tools/travel-data`,
    `side`): alliance or horde where its docks lie within `DOCKSIDE` (600) yards of that side's flight masters alone
    (its towns: Grom'gol's and the Horde's towers, Menethil, Theramore, Auberdine, Rut'theran, Feathermoon, Stormwind's
    harbour, the tram), none for both (Booty Bay and Ratchet, the goblins' ports; Dalaran's airship the Alliance's by
    batch 13, below); the planner takes only its own side's and both sides' (routes went through the other side's
    harbours and zeppelin towers).
  - **Forever's own ways** (2026-10-21: what its client holds and its beta servers sent, against Classic Era's):
    - **Ships:** Classic's five boats and three Horde zeppelins are all in Forever's client. Forever adds a boat from
      Menethil by Southshore to Auberdine, one from Auberdine to Stormwind's harbour (the *Mistbound*, which its
      servers sent), one from Tanaris' Steamwheedle Port to the Riverglades, and two airships to Zephras Isle, the
      Skycutters (both sent): Dalaran's from Lordamere Lake, the Alliance's (the Kirin Tor's and High Order's guards),
      and Mulgore's, the Horde's (the Windshapers'). Classic's older boat from Menethil to Auberdine is still in the
      client; the travel tool leaves it out as the one the three-stop boat replaced (the servers have shown neither).
    - **Portals:** Classic's area triggers (Teldrassil's, Stormwind's Wizard's Sanctum) are in the client. Forever adds
      portal objects (spellcasters one uses), as its servers placed them: Stormwind's Skyborne Portal to Dalaran (under
      the Mage Quarter) and Dalaran's back, Dalaran's Violet Citadel up and down, and on Zephras Isle portals to
      Valanaar and the Rohashi Spires (where those bring one is not known: left out). The mage's teleports and portals
      to the six capitals, a new Teleport: Dalaran (the Alliance's races, by its race mask), and the druid's Teleport:
      Moonglade are spells: ways of the routes since 2026-10-21 (*The teleports*, below), the portals not (a mage's own
      way is its teleport to the same place).
    - **The tram and lifts:** the Deeprun Tram with a second set of cars (the same run, 58.6 seconds, and round); the
      lifts as Classic's, the Undercity's three cars under new IDs (sent by its servers).
    - **Flights:** 74 flight masters (Classic's 67): Mount Hyjal's two, the Riverglades' Rog'mar and Farholde Keep.
  - **Batch 13** (`sources.toml`, unverified): the portal objects where a pair stands at both places as the servers
    placed them and each one's target lies beside the other (Stormwind and Dalaran; Dalaran's Citadel), keys 2000000 +
    the object's entry, with their side; and the sides of the ways whose ends show only one side's NPCs (Dalaran's
    Skycutter the Alliance's, Stormwind's Sanctum portals too; the Horde's zeppelins and Mulgore's Skycutter agree with
    the flight masters). The planner takes a portal only of the player's side or both; Stormwind's Skyborne room is in
    the walking data since 2026-10-22 (the Wizard's Sanctum's cellar), closed off from the streets in the game's own
    walls: routes take that pair for a pin in the Sanctum's rooms.
  - **Still found:** a few NPCs' places of Stormwind that Forever's rebuilt city has no floor near; small islands in
    the walking data where its tool wrote an opening between two floors one way only (0.1 % of the ground; gone since
    2026-10-22, *The walking data*).
- **Built (2026-10-21): the teleports a character has, and Frequent Flier.**
  - **The teleports** (Core's set *Travel*, kind `teleport`, key 3000000 + the spell's ID; `dev/tools/travel-data
    --teleports`): from Forever's client every class's spell that moves one to a place the server holds (the
    effect TELEPORT_UNITS to such a place: the mage's six capitals and Dalaran, the druid's Moonglade), each with its
    side by its race mask and its reagent (the Rune of Teleportation); and the items' of a short list (their spells
    are mostly the server's scripts): the engineers' transporters, Forever's new ones (EZ-Thro Field Transporter:
    Gadgetzan, SAF-T Emergency Ripper: Everlook, EZ and SAF Field Transporter: Mt. Hyjal, Dimensional Transporter -
    Mt. Hyjal; three charges, or Engineering 300, a four hours' cooldown) with Classic's two that cast the same
    spells, and the Crumbling Hearthstone (one use, gone after a day). Not the SAF-T Teleport (Tinker: Teleport, a
    few yards). The shaman's Astral Recall goes to the hearthstone's place and is the hearthstone's second way.
  - **Where they bring one** is no table of the client's. **Batch 14** (unverified): the original game's place for
    seven of them, where both records agree, it lies on a continent and Forever's own world has a floor there
    (Stormwind, Ironforge, the Undercity, Thunder Bluff, Orgrimmar, Moonglade, Everlook); Darnassus' left out (two
    places 13 yards apart). The others (Dalaran, Mount Hyjal, the Gnomish Transporter, whose place is a script's, the
    Crumbling Hearthstone) are **learnt in play** by Core (`src/Core/Data/Teleports.lua`): after the cast of a
    teleport's spell, a leap of `LEAP` (50) yards between two looks every quarter second, or onto another map after
    a loading screen, is the teleport, and where it ends its place (no height: the game tells none); kept as Core's
    learned data (`Data.Learn`, `SaneUIData_Learned`), the set's record with that place, read over the set at once
    and shared and harvested as learned data will be (*Doc/ideas/Data.md*, *Learned*). A cast that lands within
    `SAME` (2) yards of the set's place teaches nothing new; a confirmation is not kept yet (1c.1).
  - **In the journey** (`Teleports`): from the player to where each brings one, the teleports the character has now:
    a spell it knows (`C_SpellBook.IsSpellKnown`) with its reagent in the bags, or an item of its in the bags the game
    lets it use (`C_Item.IsUsableItem`: its level, its skill, its charges); of its side or of both; its cooldown
    (`C_Spell.GetSpellCooldown`, `C_Item.GetItemCooldown`) and `Planner.HEARTH` (the cast, 10 seconds for all of
    them, and the loading screen). Where its height is known, on its floor there (`Walk.Landing`), and after the leap
    the floor followed is that one (`Arrival`). Drawn pale blue, as the hearthstone's.
  - **Frequent Flier** (a Legacy perk of the adventure tree, spell 1225490: flights half price and 20 % faster):
    where the game tells the character has it (its spell known, or its aura on the character), the flights count
    `Planner.FASTER` (1.2) times as fast (`Planner.Pace`). A flight's time on screen (`Data.Trips`) is the character's
    own pace already.
  - **Checked on the real data** (the routes harness, its `teleports.lua`): a mage from Goldshire to the Cathedral by
    Teleport: Stormwind, from Kharanos to Ironforge's flight master, from the Crossroads to Thunder Bluff, a Horde mage
    from Orgrimmar into the Undercity; a druid from Stormwind to Nighthaven; an engineer from Orgrimmar to Everlook;
    no rune, no teleport. The 29 fixed journeys and 200 random ones give the same legs as before for a character
    with none.

### The walking data

Core's (pack Routes, loaded on the first route, *Decisions*): per region a block, packed (the game's
`C_EncodingUtil` unpacks it), opened on first need, the opened ones capped (the cap measured with the first
real data) and let go when no route is asked for. The format, the tool and the checks are Core's data
framework's; this is the one set where its rule of plain text gives way, as `Doc/ideas/Data.md` foresees for
a cold, very large part.

**Built (2026-10-20, `dev/tools/walk-data`; open question 1 answered):** from the game's own files only: each
map chunk's heights (but its holes), every collision triangle of every building the object files place (their
group files, turned and moved as the game places them, cut into columns as a voxel field is made) and, since
2026-10-21, of every doodad (*The doodads*, below), and the water (deeper than `DEEP` a floor to swim on; magma and slime close what lies under them). Sampled every 2.08
yards (256 a tile): a floor is the top of a column's span made by something not too steep (`SLOPE` 50°) with
`ROOM` (2 yards) free above it; two floors side by side are one way within `CLIMB` (2.6 yards); the ground is
judged by the game's own triangle under each sample (since 2026-10-21; before, on its heights smoothed over three
samples, *The ground as the game draws it*, below).

- **Surfaces, then rectangles:** a flood joins floors into surfaces (one kind, at most one floor a column, every
  two neighbours one way), and each surface is cut by a quadtree into squares of up to `WIDEST` (32 samples, 67
  yards), neighbours of one size joined. At the ground's edges a square may take a share of steep samples
  (`TAKEN`: a half at 2 samples up to 95 % at 32; never a hole, water, a building or another surface's floor),
  walked over at the square's height; a lone sample among steep ground is left out. So the land is a few large
  rectangles, towns, caves and mountainsides many small ones.
- **Regions:** all rectangles one can walk or swim between share a number; a region under `SMALLEST` (3,000
  samples, rooftops, ledges, plateaus nobody walks onto) is left out, and one with the sky over none of its floors or
  most of them buried (2026-10-21, below), but one a lift lands on (2026-10-21) or a portal (2026-10-22).
- **The block** of a tile (CBOR, deflated, base64; the game's `C_EncodingUtil` reads it): its surfaces (count,
  kind, region), its rectangles (column, row, width, height, height in quarter yards) and the openings the game
  cannot work out itself: two rectangles of one surface that touch are open along all their edge (not
  written); every other opening is written (between surfaces, into the next tile, or only part of an edge), on
  its own tile once (`Walk.lua` adds the other way).
- **Size:** 1,724 tiles of both continents and 26 of Zephras Isle, 3.03 million rectangles (2026-10-22, every
  opening on both its rectangles' sides; 2.83 million with the doodads and the ground's triangles, 1.65 million before
  them, 1.45 million the day before), 24.1 MB in the master (23.3 MB of blocks; 23.7 and 23.0 the day before, 12.6 and
  12.1 before the doodads; the master's sets 39 MB in all); about seven minutes to make on this computer, the isle
  alone (`--maps 2991`) a few seconds.
- **Region numbers** are given in the order of the tiles' keys (a run gives the same numbers again) and hold within
  one map: the planner and the search compare them only there, so the isle, made on its own, numbers from 1. Walks across a zone take
  20 to 65 ms of search, spread over frames by the scheduler.
- **The search** (`Search.lua`): A* over the rectangles from the floor the start stands on (the player's,
  followed; else every floor under it and within 6 yards, each over the lowest at the cost of the climb up to it,
  or the nearest within 40 yards) to any floor of the regions it starts in under the end or within 50 yards of it,
  else the nearest within 500, what lies off the walking data drawn straight at six times its yards (2026-10-21;
  before, the first floor under each end, and ends in different regions no walk at all); a step costs the way from
  where a rectangle was entered to the nearest point of the opening, swimming twice, and each yard up a quarter more
  (2026-10-21: the game runs as fast up a hill as on the flat, so the shorter way over a hill or a pass is taken; two
  more before, while the data held steep slopes as floors and a walk into Ironforge went over its mountain); the line
  then pulled straight through the openings passed, each drawn in 0.8 yards from its ends.
- **Built (2026-10-21): what players walk between, joined.** Found on the real data while adding the lifts: the
  Undercity's levels were regions apart, and the lifts' landings there, Freewind Post's and Gnomeregan's were left
  out.
  - **Slopes in yards:** a building's triangle was judged in the samples' space (2.08 yards across, a yard up), so
    `SLOPE`'s 50° was 30° for buildings, and the Undercity's ramps (27° to 39°, the building's collision-only
    triangles) were walls. Now in yards, as the ground's.
  - **Thin walls:** a wall anywhere in a sample's square took its floor, so a door or a bridge narrower than about
    two samples was closed by its sides (the lifts' upper landings open into the throne room through arches 3.9
    yards wide). Now a wall takes a floor only where it comes into the middle of the sample's square (`CORE`, half
    its side); off the middle it stands on each side whose way it crosses (from the sample's middle to that side's),
    and closes the way to the next sample there where it rises more than `STEP` (half a yard) over the higher floor
    of the two under its `ROOM` (a wall, a railing; not a sill), or more than `LEDGE` (1.5 yards) between them (a
    ledge; a stair's steps do not). The water's floors too: no more swimming through a wall that stands in water.
  - **The lifts' landings kept:** the region a lift of the master's set *Travel* lands on (as `Walk.Landing` finds
    it: of the floors within `LANDING`, 20 yards, of its end whose height lies within `RISE`, 12, the nearest by
    both) is kept however small: Freewind Post's mesa, two small lifts' platforms.
  - **What it joined:** the Undercity's ring, lower parts, quarters and sewers and the lifts' upper landings;
    Gnomeregan's lift's two ends; Thunder Bluff's Elder Rise to the main mesa by its bridge; towers, ramps and
    terraces to their land: Orgrimmar's flight tower, the Crossroads' tower, the zeppelin towers to Zephras Isle, the
    Caverns of Time, Jintha'Alor, Timbermaw Hold, the city behind Zul'Gurub's gate, the gates of Ahn'Qiraj. The
    Undercity's sewers lead out to a cave on the hillside west of the ruins, so the city and the ruins are one
    region (the lifts: one region). Regions: 108 on the Eastern Kingdoms (131 before), 219 on Kalimdor (221), 5 on
    the isle (6).
  - **Not joined:** Thunder Bluff's Spirit Rise and Hunter Rise: their bridge heads' stairs and posts are cut at two
    yards (the buildings' own, not doodads, as was thought first: *The doodads*); a small walled harbour far in the
    south west of the Eastern Kingdoms, reached before only by swimming through its wall, is a region of its own.
- **Built (2026-10-21): the doodads.** `dev/tools/walk-data` reads the collision of the doodads (the game's models:
  the collision triangles their header names) the object files place, and of those a placed building shows (its
  first, global doodad set and the placement's own; Zephras Isle's buildings show several), into the same columns as
  the buildings': fences, rocks, trunks, roots and the game's invisible walls stand as walls; piers, decks and the
  tops of rocks are floors.
  - **Placed as the game places them:** a building or a doodad is tilted as well as turned (the buildings were turned
    only, but 902 stand tilted: a capsized ship upside down, ruins on hillsides, the cave tunnels of Winterspring's
    mountains). Checked against the game's own files: every building's box as its object file keeps it (to a
    thousandth of a yard; turned only, 3.4 yards off on the median of the tilted ones, up to 61), the doodads each
    map chunk lists (99.9 % of 54,000 alike); a building's doodads turned by their quaternion as read (of 9,234 long
    turned ones, 921 have a wall of their building inside them, 1,252 when turned the other way).
  - **Left out:** a doodad no wider than `SMALL` (2 yards either way: a torch, a barrel, a crate, a post, a thin
    trunk; about 82,000 of the 235,000 with collision): one walks round it, where in the samples it took a floor or
    closed the way between two (the torches at the ruins' gate). What an outdoor doodad holds wholly under the
    ground (`sunken`: a tree's roots, a rock's foot) is inside the earth. A canopy or anything else high over the
    ground no longer counts as built there (`built`: only what comes near the ground), so the ground's ragged steep
    edges are still taken into its squares (`TAKEN`) under the forests.
  - **The lifts' landings** count a yard up or down three times (`LEVEL`, as Navigation's `Walk.Landing`): one gets
    off level with the car beside its shaft, not onto the roof over it (the Undercity's roofs over the shafts, 6.5
    yards up, became a region of their own with the doodads).
  - **Measured** (the doodads alone, 2026-10-21): 2.41 million rectangles, 17.9 MB of blocks (1.65 and 12.1
    before), about seven minutes to make. What it changed: the game's invisible wall on the ruins' rampart and a door
    close the roundabout way the data had into the inner ruins of Lordaeron (joined again by the same day's stair
    rule); Mount Hyjal is joined to Kalimdor by two cave tunnels that now lie as tilted as the game places them; a
    giant tree's roots, four yards high across a steep slope, cut Thousand Needles off Feralas (its only walking way
    in the data; Tanaris only round by Feralas). Thunder Bluff's rises: their bridge heads are the buildings' own
    stairs and posts, which the same day's stair rule and narrower `CORE` join.
- **Built (2026-10-21): the ground as the game draws it, the buildings' water, a building's floor.** Checked on the
  whole data outside the game: 53,000 creatures' spawn points, the lifts, walks across the zones and into the
  cities.
  - **The ground's triangles:** a sample's ground is too steep where the game's triangle under it is steeper than
    `SLOPE` (each cell four triangles meeting at its inner height; a sample's middle lies where two meet, it takes
    the one the ground's height is drawn from). The heights smoothed over three samples made a slope gentler than
    the game's: walks went up Ironforge's mountain and into the ground under Stormwind. A slope the game walks up
    is a floor, one it does not none, so routes take a hill or a pass where it is shorter (`Search.CLIMB` 0.25). Held
    against the gentlest way over the triangles themselves: the ground under Stormwind (55.6 degrees at its
    gentlest) and the plateau east of Ironforge (53.6) are no walk; Feralas' hills (47.9), Searing Gorge (48.3) and
    Silithus' hives (16), cut off before, are.
  - **Stairs and narrow stairwells:** the next piece of a stair or a ramp passing up through a sample within `STAIR`
    (a yard) over a floor is no ceiling (inns' upper storeys); a wall takes a floor only within `CORE` (0.3 of a
    sample, half before) of its sample's middle. Thunder Bluff's Spirit Rise and Hunter Rise are joined to the mesa
    by their bridge heads.
  - **The buildings' water:** their parts' liquids (MLIQ), the liquid type as the game takes it: Stormwind's canals
    are swum, the Undercity's slime and Ironforge's lava close what lies under them. Water drowns a floor only where
    nothing solid stands between them: a tunnel under a river stays dry, and so does the ground under a city's pool.
  - **A building's floor:** a floor on a building or a doodad is of a kind of its own (3, `BUILT`; the ground's land
    1, water 2; the block's format is the same). Indoors (the game's `IsIndoors`: a building's or a cave's) a walk
    whose floor is not followed starts on the lowest of a building's floors near the player before the ground or
    water under it (`Walk.Floor`): from inside Stormwind's buildings walks started on the ground forty yards under the
    streets.
  - **Regions left out** besides the small ones: one with the sky over none of its floors (a cellar the data closes:
    nobody gets in or out) and one most of whose floors are buried (the ground `DEPTH`, 10 yards, and more under a
    building: under Stormwind's streets, open only between its districts).
  - **Measured** (with the doodads): 160 regions on the Eastern Kingdoms, 240 on Kalimdor, 8 on the isle; of 53,000
    creatures' spawn points 71 % stand on a floor at their height (66 % before); indoors without a height the
    start lands within 3 yards of its floor for 82 % of those under a ceiling (80 %); all 14 lifts land (a landing's
    rise counted `LEVEL` times in `Walk.Landing` too); walks across hilly zones are as long at `CLIMB` 2 as at 0
    within 2 % on the mean, a walk across a zone 5 to 30 ms of search, across a continent up to half a second.
  - **Not joined:** the plateau east of Ironforge (with the area behind the city) and the lower halls of
    Blackfathom's ruins, reached only under water (diving is no walk).
- **Built (2026-10-22): every opening both ways, on both its rectangles' sides; the portals' rooms.** Checked on
  the whole data as `Walk.lua` reads it, and with the planner run over it outside the game.
  - **Both ways:** an opening was found from a rectangle's edge to the first floor beside it one way with its own,
    and on a tile the tool writes one once (`Walk.lua` adds the other way): where the sample beside held two floors (a
    stair's foot, a deck), the way back led to the other one and the opening was lost. 129,510 samples (0.14 % of the
    ground: Un'Goro's rock tops, huts) kept their region's number with no opening reaching them, 4,016 openings into
    the next tile had no way back. Now every floor beside an edge one way with its own is linked, so each opening is
    found from both.
  - **On both rectangles' sides:** an opening must lie on the facing sides of both its rectangles (`Walk.lua` sets
    its way back there, and the search pulls its line through it). 113,241 of 2.6 million (4 %) did not: a rectangle
    of another floor overlapping the first in plan (the ground going on under a deck or a stair's foot), or a pair
    written whole for an edge the two did not share (`Walk.lua`'s `Side` then took the west); lines drawn through them
    ran over no floor (7 walks in 200 journeys). Now a surface's rectangles end where one of its floors is one way with
    another surface's floor beside it while the surface goes on there (`cuts`), and only rectangles that meet along
    a side are linked there (`meets`).
  - **Not through a floor:** two floors of different surfaces side by side are no way where the higher one goes on
    into the lower one's sample over it (`through`: from a deck onto the ground under its next sample, from a stair's
    step onto the ground under the next step; the tool joined such floors all over wherever they lie 2 to 2.6 yards
    apart). Where a tile's floors would so come apart, it keeps one such way between the two parts (`bridges`):
    every join the data had stays (Saneroki, 2026-10-22), so a hall whose door is a wall in the walking data is
    still reached under its floor (Lakeshire's town hall, Booty Bay's shops), and the inner ruins of Lordaeron from
    the ground under their courtyard (apart, the Undercity's lifts no longer joined stacked levels). Into the next tile
    every way is taken: an opening on a tile's edge lies on both rectangles' sides however they lie.
  - **The portals' rooms kept** as the lifts' landings: the regions the ends of set *Travel*'s portals land on
    (`Walk.Landing` within `LANDING`, as `Planner.ARRIVE`), however small, closed or buried. All 8 portals and 14
    lifts land: the Wizard's Sanctum's cellar (the Skyborne portal's room too) and its top, the top of Dalaran's
    Violet Citadel. From Dalaran a route to a pin on the Sanctum goes through the Skyborne portal and trigger 702.
  - **Measured:** 412 regions, 3.03 million rectangles (2.83), 23.3 MB of blocks; the main regions one part each as
    `Walk.lua` reads them, no opening without its way back or off its rectangles; the two tiles of Zephras Isle the
    tool no longer writes marked gone in the master. 200 journeys between NPCs on the same code: none failing, 14
    walks drawn straight (14), none off the data (7), about 5 % slower (7 % more rectangles); of 53,551 creatures'
    spawn points 85.07 % stand on a floor at their height (84.95 %).
  - **Weighed and left:** every way through a floor dropped (the inner ruins and the halls behind doors cut off: 91
    spawn points without their floor); every one linked, the rectangles cut at each (22 % more rectangles, 18 % more
    data, routes 10 % slower, or 31 % with the searches' limits raised to find as many walks).
  - **Found:** the Sanctum's cellar and top are closed off from Stormwind's streets in the game's own walls (no stair
    down to the cellar; a wall 4 yards high between the top room and the tower's outer ramp at 130 yards): the
    portals join the two rooms and the cellar with Dalaran, and a route from the streets to a pin there ends on the
    street floor under it.
- **Not yet:** one-way drops (a ledge one can jump down but not climb) are no way; an instance's portal or a closed
  gate is no collision (the walking data goes through Zul'Gurub's gate); a doodad the game shows only at times (a
  door, a gate) is a wall all the time; the giant trees' roots are walls where they lie on steep ground; diving (a
  way under water); indoors without a height the lowest of a building's floors is taken, not its upper storeys.

### The golden line

- The path made short first: straight runs joined, corners cut where the walking data shows a clear way
  (it changes the drawing, never the cost); only the part in view is drawn.
- `CreateLine` segments from a pool, a few pixels thick, gold, a darker edge under it.
- **The pulse runs towards the pin without code each frame:** a repeating soft gradient on each line,
  moved by a `TextureCoordTranslation` animation (*verified* to exist; Blizzard moves lines this way in
  `PowerDependencyLine`). The animation runs in the game's engine; no `OnUpdate` of ours.
- The same line in both views; the canvas clips it.
- **To come:** leather stitches in place of the gold (Saneroki, 2026-10-21; *Waypoint and route*).

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

**Where it stands (2026-10-21):** steps 1 and 2 built (2026-10-19); 3 and 4 built, the live pins and the quest log;
5 built as far as Core's data goes: the pins, gathered overlaps, tooltips and the quest areas the game shades are
there, and `Data.Map` reads Spawns, Places and Travel, of which Spawns and Places hold no entries yet, so the
database's pins come with the import; rares' spawn areas and patrol paths wait for their data. 6 built on foot, by
flight, by boat and zeppelin, by the tram, by lift, through portals, by the hearthstone and by the teleports a character
has (the walking data, the flights, the ships' ways and the tram of the game's tables, the lifts', portals' and
teleports' places of batches and of play, the planner,
the search, the golden line), checked on the whole real data outside the game (2026-10-21). 8 begun
(2026-10-21): the dungeons' and raids' maps of Core's set *Dungeons*, their floors, bosses and the bosses' 3D
models; their three zooms and the minimap's own parts not yet. Step 0's points are answered in play as each step is tried.

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
- **Live nodes** (built 2026-10-20 on the minimap, `Found.lua`, the filter's *Found herbs* and *Found ore*): the
  native minimap probed point by point (`Minimap:UpdateMouseoverAtPoint`, then
  `C_TooltipInfo.GetMinimapMouseover`) while a finder is on, a few points a frame, never in a fight; each drawn
  in the picture of what it gives, a click puts the map pin there (2026-10-21). Kept as discoveries of Core's:
  not yet.

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
| On the map | bosses (the game's boss mark and the boss's 3D model, built), enemies (their fixed places: to come), entrances, floor links, quest items; never the player or the party (*Instance maps keep rules of their own*) |
| Floors | a menu that follows the player's floor; clickable floor links |

- **Plan:** Blizzard's own art first (it costs no space); our own pictures only for the maps the client
  lacks, each kept small.
- **Built (2026-10-21):** Forever's client has no dungeon maps (none of its map table's maps is of type
  *Dungeon*), but its install holds Blizzard's map art for them. Core's set *Dungeons* (pack World, keyed by the
  instance's map ID, `dev/tools/data` batch 9) holds 26 dungeons and raids: their floors (name, size, world box),
  the art's tiles and each boss (its encounter in the set *Encounters*, its place, its look), from Blizzard's
  retail tables where they match Forever's own encounters, unverified. The view (`Dungeons.lua`) draws the tiles,
  each boss's mark (the game's `vignettekillboss`) and its model (`PlayerModel`, `SetDisplayInfo`); the reworked
  dungeons (Deadmines, Shadowfang Keep, Gnomeregan and others) have their map without bosses. No player's arrow
  and no group (2026-10-21: the game tells no place inside an instance); the floors' world boxes stay in the set for
  the enemies' places to come; Core's spawns are keyed by the game's zone maps, which Forever lacks inside. Batch 11
  (2026-10-21) added 100 bosses (the rebuilt dungeons' too: their places agree across the records on the newest
  map art), each boss's abilities and loot (set *Bosses*), and the enemies of six dungeons (set *Dungeons*'
  `enemies`, on the floors' maps).
- Bosses, entrances, floor links and quest items from Core's data.
- Drawn as *Maps without a world box* where the game gives none.

## Map selector

- A **breadcrumb** on the top bar: World › Continent ▾ › Zone ▾; inside a dungeon the last menu lists its
  floors.
- **Continents:** found at run time (in this client: Kalimdor, Eastern Kingdoms, Zephras), then Dungeons
  and Raids, PvP.
- **Zones** A–Z; the **dungeon list** with a search box.
- **Dungeon maps chosen here (Saneroki, 2026-10-21):** the selector picks every dungeon, instance and raid
  (built: the bar's Dungeons menu, A to Z, and its floors), and the chosen one opens in its three zooms
  (*Dungeon, instance and raid maps in three zooms*): the wheel goes from its accurate close-up through the pencil
  drawing of its rooms out to its reimagined picture, the floor menu choosing the floor of the first two.
- A **back button** that remembers the last 30 maps.

# Open questions

Each with a proposal; what is not answered when its step comes is built as proposed.

1. **Walking data:** how dense a graph of walkable points (and so how big), and made from what our tool can
   read of the client's terrain? *Proposal:* as sparse as still gives good routes in towns and tunnels,
   decided on the tool's first output and measured, in Core's pack format.
2. Answered (Saneroki, 2026-10-19: the views at every zoom): terrain everywhere, by the overview far out.
   **Far zoom:** Blizzard's art when zoomed far out (fast), or terrain everywhere (slower)?
3. Answered (Saneroki, 2026-10-21: *Dungeon, instance and raid maps in three zooms*, picked in the *Map
   selector*). **Dungeons:** Blizzard's map only in all three views, or a tool for the instances' own minimap
   tiles?
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
8. Answered (Saneroki, 2026-10-21): no right-click to zoom out a level; the wheel alone zooms, and the Atlas is
   one smooth world (*One smooth world*). **Right-click** as well as the wheel?
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
18. Answered (Saneroki, 2026-10-21: *Indoor maps only inside buildings and caves*, built). **Indoor maps on city
    streets:** the game flags Stormwind's and Orgrimmar's streets as indoors, so the indoor plan would lie over them.
