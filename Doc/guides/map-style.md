# Map style

The look of Navigation's painted maps: the Atlas (the world) and the instance maps (the dungeons and raids). Both are
made in three levels, from close up to far out, and both levels look the same in the world and in an instance, made
by one pipeline with the same words, tools and cleanups, so they are one look and one precision (Saneroki,
2026-10-21). Saneroki decides the looks; every decision is written here the moment it is taken. The plans with the
reasons and the details are in [Navigation.md](../ideas/Navigation.md) (*Zones and continents reimagined*,
*Instance maps as the world map, apart from it*); how the pictures are made is in
[image-generation.md](image-generation.md), *Maps*.

## Scope

- **The Atlas** is the painted view of the world map. Scrying (the terrain) and Parchment (Blizzard's maps) are
  the game's own files, drawn pixel for pixel, and keep their own looks.
- **The instance maps** are apart from the world map: their own view, data, pictures and jobs, never part of the
  world's picture. Only their looks and how they are made are the world's.

## The three levels

The wheel zooms smoothly through them, each level's look blending into the next, never a step. All three are
strict (Saneroki, 2026-10-21, replacing the free concept-art paintings of the earlier plan): actual maps of the
layout, not mood pictures. Each subject (a zone, an instance, an instance's floor) has one frame, its box in the
world, that all three share, so they lie over each other exactly.

| Level | What it shows | Look | Made from |
| --- | --- | --- | --- |
| **Close** | the terrain, pixel-exact: every rock, wall, building, shore and walkable spot where the game has it | a photorealistic satellite photograph of exactly that ground, seen straight down | the game's terrain (an instance's own, with its buildings' indoor maps laid over it), repainted with the Atlas' words (`dev/imagegen/maps/atlas.toml`) |
| **Middle** | a zone, or one floor of an instance: a top-down map in the manner of the game's own maps, exactly over the terrain | drawn by hand in graphite pencil on the interface's parchment, straight from above | the terrain plan of the frame and the game's map art of it in the same frame (`levels.toml`, `[middle]`) |
| **Far** | a zone or an instance as a whole, its layout kept, its major places where they lie | a photorealistic aerial render, nearly straight down, realistic fantasy | the terrain plan, the middle level's drawing and a piece of the close level (`levels.toml`, `[far]`) |

### Close: pixel-exact

- Nothing is moved, added or taken away: the painting changes only how things look (materials, texture, fine
  detail, light), never where or what anything is. The game's water and lava are where the game has them, and each
  painting is checked against them.
- The colours stay the game's: the colour pass moves each painting's broad colour back toward the game's terrain;
  the light is the zone's (or the instance's), its brief's first sentence of atmosphere.
- **An instance's terrain is the world's kind:** its own map's terrain tiles, with the indoor maps of the buildings
  they place laid over them, as the game's minimap draws them; painted by the same code and words as the Atlas.
- **Soft edges only where nobody walks:** a zone's outermost outline, where the player cannot go (the mountains
  between zones, the edge of the world), blends into a natural transition. Every coast and shore, every pier,
  dock and bridge, every pass into the next zone stays pixel-exact.
- **Indoor maps are clear around, never black:** buildings, caves, city districts and the instances' floors have a
  transparent background, in the same place and scale as the terrain, so they lie seamlessly over what is under
  them.
- **In an instance, the middle level is under it:** where the close level has nothing to show (around the halls
  and caves, the void the game's textures leave black), the floor's middle drawing shows, never black or an empty
  colour.

### Middle: the game's kind of map, in pencil on parchment

- **A top-down map like the game's own maps** (Saneroki, 2026-10-21): a zone's or a floor's map as the game draws
  its zone and dungeon maps, its rooms, halls, roads, towns, coasts and rivers shown as the game's map shows them,
  laid exactly over the terrain: every outline, wall, cliff and shore where the terrain has it, the same shape and
  size. The world's zones and the instances' floors alike, straight from above.
- **Drawn in the interface's paper and pencil** ([interface-style.md](interface-style.md), *Paper*, *Pencil*):
  graphite pencil on the cream parchment; clean outlines, light hatching on rock, cliffs and ground nobody walks,
  fine ripples on water, small careful pencil drawings of trees, houses, towers and props where they stand; the
  walkable ground clean paper. Graphite grey only.
- **Its pictures:** image 1 the terrain plan of the frame (the exact outlines), image 2 the game's own map art of
  it in the same frame (what a map of it shows; a dungeon floor's title banner painted over), image 3 a piece of the
  parchment. Where the game has no map of the place, another place's map gives only its manner.

### Far: photorealistic, its layout kept

- **A photorealistic aerial render** of the place, nearly straight down, in natural light: a realistic fantasy
  world, not a map and not concept art. Strict, though less precise than the other two: every coast, river, lake,
  mountain, forest edge, road and wall where the terrain has it, and the major places (cities, towns, landmarks,
  an instance's halls and rooms) where the middle level draws them, at their sizes; the biome, mood, atmosphere and
  lore of its brief; the borders of zones and continents and the walls of an instance where they are.
- **Its pictures:** image 1 the terrain plan, image 2 the middle level's drawing (an instance's floors laid where
  they lie), image 3 a piece of the close level's painting (how the ground looks). So it is painted after them.
- **The world:** both continents always together (no view of one continent alone); each zone clearly sectioned from
  the next, the borders softened where nobody walks. What stands there in the lore is shown, not the game's open
  view: Teldrassil the world tree itself, Ironforge the full mountain.
- **An instance:** the whole instance in one view, its halls and rooms where they lie, the rock and the roofs over
  them cut away.

## Strict to its words and pictures

A painting must show the place its brief describes and the layout its pictures give (Saneroki, 2026-10-21: "much
more strict"). So:

- **Researched briefs:** each zone's and instance's brief is written from the game's own lore texts and pictures of
  the place and from what is known of it in play: what kind of place it is (`biome`), its architecture and what
  fills it (`buildings`), how its parts and major places lie (`places`), who holds it and how it feels (`mood`), its
  colours and its light (`atmosphere`).
- **The layout is always image 1:** the place's own terrain in the painting's frame, so every level keeps it.
- **Checked twice, painted again when it fails:**
  - its outlines against image 1's: how well its edges agree with the terrain's, measured against how well the
    game's own map agrees with it (a middle level must come close to the game's map, a far one less);
  - by a vision model: no writing, a pencil map seen from above (middle); a real place, not a map or panels, seen
    from above, of the brief's kind (far).

## What is drawn over them, never painted

The paintings show no text, no names, no marks. Everything else is drawn over them by code, each kind its own
switch where it makes sense:

- the names of zones, major places and rooms; on the world, a zone's level range and the skills it is meant for
  (fishing, herbalism, mining);
- pins (on the close level only), the route, quest and spawn areas;
- in an instance, the bosses' 3D models where they stand (in every level), the enemies, entrances and floor links.

## The words

- Close: `dev/imagegen/maps/atlas.toml` (the Atlas' words, chosen in its lab) with each zone's or instance's
  colours and light.
- Middle and far: `dev/imagegen/maps/levels.toml`, shared by the world and the instances, with each brief's biome,
  land, plants, buildings, roads, places, colours and light (`zones.toml` for the zones, `dungeons.toml` for the
  instances, the same fields), put together by `dev/tools/map-layers`.
- No names anywhere the model can read them: a name in the words, or a label in image 1, comes back as garbled
  lettering. Describe, never name.
- A change to the shared words changes every painting of that level: the runs show it and are painted anew.

## Choosing

Finished paintings go into a review queue (a contact sheet each run makes): Saneroki takes or sends back each one.
Only what is taken goes into the packs and, once chosen, into Git. Pictures not taken are not part of the style.
