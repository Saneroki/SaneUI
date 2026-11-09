# Map style

The look of Navigation's painted instance maps (the dungeons and raids), made in three levels, from close up to far
out, by one pipeline (`dev/tools/map-layers`) with the same words, tools and cleanups for every instance (Saneroki,
2026-10-21). Saneroki decides the looks; every decision is written here the moment it is taken. The plans with the
reasons and the details are in [Navigation.md](../ideas/Navigation.md) (*Instance maps, apart from the world map*);
how the pictures are made is in [image-generation.md](image-generation.md), *Maps*.

## Scope

- **The instance maps** are apart from the world map: their own view, data, pictures and jobs. They are not in the
  addon yet; Navigation's dungeon maps show the game's own floor maps until they are chosen.
- **The world map** draws the game's own files: Scrying (the terrain) and Parchment (Blizzard's maps), pixel for
  pixel, in their own looks. The painted world, the Atlas, is gone (Saneroki, 2026-11-09: "It has to many
  disadvangages without much benefit").

## The three levels

The wheel zooms smoothly through them, each level's look blending into the next, never a step. All three are
strict (Saneroki, 2026-10-21, replacing the free concept-art paintings of the earlier plan): actual maps of the
layout, not mood pictures. Each subject (an instance, an instance's floor) has one frame, its box in the world, that
all three share, so they lie over each other exactly.

| Level | What it shows | Look | Made from |
| --- | --- | --- | --- |
| **Close** | the terrain, pixel-exact: every rock, wall, building, shore and walkable spot where the game has it | a photorealistic satellite photograph of exactly that ground, seen straight down | the instance's own terrain, with its buildings' indoor maps laid over it, repainted in squares with the close level's words (`dev/imagegen/maps/close.toml`; `dev/tools/map-squares`) |
| **Middle** | one floor of an instance: a top-down map in the manner of the game's own maps, exactly over the terrain | drawn by hand in pencil and brown ink on parchment in the colour of its game map, straight from above | the terrain plan of the frame and the game's map art of it in the same frame (`levels.toml`, `[middle]`) |
| **Far** | an instance as a whole, its layout kept, its major places where they lie | a photograph of the land straight down from high above, realistic fantasy | its plan lightly blurred, a piece of the close level, and a control for its layout (`levels.toml`, `[far]`) |

### Close: pixel-exact

- Nothing is moved, added or taken away: the painting changes only how things look (materials, texture, fine
  detail, light), never where or what anything is. The game's water and lava are where the game has them, and each
  painting is checked against them.
- The colours stay the game's: the colour pass moves each painting's broad colour back toward the game's terrain;
  the light is the instance's, its brief's first sentence of atmosphere.
- **An instance's terrain:** its own map's terrain tiles, with the indoor maps of the buildings they place laid
  over them, as the game's minimap draws them.
- **Indoor maps are clear around, never black:** the instances' floors have a transparent background, in the same
  place and scale as the terrain, so they lie seamlessly over what is under them.
- **In an instance, the middle level is under it:** where the close level has nothing to show (around the halls
  and caves, the void the game's textures leave black), the floor's middle drawing shows, never black or an empty
  colour.

### Middle: the game's kind of map, in pencil on parchment

- **A top-down map like the game's own maps** (Saneroki, 2026-10-21): a floor's map as the game draws its dungeon
  maps, its rooms, halls, roads, coasts and rivers shown as the game's map shows them, laid exactly over the
  terrain: every outline, wall, cliff and shore where the terrain has it, the same shape and size, straight from
  above.
- **Pencil on parchment in the colour of its game map** (Saneroki, 2026-10-22: "the yellow / orange that the
  blizzard maps are, instead of the white background"): the house paper's grain in the colour of the instance's game
  map. Pencil and brown ink, clean outlines, light hatching on rock, cliffs and ground nobody walks, the water a
  faded grey-blue wash with fine ripples, small careful pencil drawings of props where they stand; the walkable
  ground plain parchment. (It was graphite on the interface's cream paper until then.)
- **Its pictures:** image 1 the game's own map art of it in the frame, which it is drawn again from (its frame,
  title banner and ornaments made parchment first), image 2 the terrain plan of the same frame (the exact outlines),
  image 3 a piece of the parchment. Where the game has no map of the place, image 1 is the terrain plan and another
  instance's map gives only its manner. It takes no words of the brief: they drew what they named.

### Far: a photograph straight down, its layout kept

- **A photograph of the place taken straight down from high above** (Saneroki, 2026-10-22: all three levels from
  straight above, in the same place, so the maps fit together), in natural light: a realistic fantasy world, not a
  map and not concept art.
- **Its layout kept, with a little leeway,** so it lies over the middle and close levels: its halls and rooms,
  water, cliffs and the ground nobody can cross where the plan has them, at their sizes; in its own mood, colours,
  light and lore by its brief.
- **Its pictures:** image 1 the instance's plan in its frame, lightly blurred and toned down (its textures gone), so
  the model paints the detail as a photograph shows it and not the game's textures; image 2 a piece of the close
  level's painting (how the ground looks). Its layout is held by a control: the plan's clearest edges.
- **The whole instance in one view,** its halls and rooms where they lie, the rock and the roofs over them cut away.

## Strict to its words and pictures

A painting must show the place its brief describes and the layout its pictures give (Saneroki, 2026-10-21: "much
more strict"). So:

- **Researched briefs:** each instance's brief is written from the game's own lore texts and pictures of
  the place and from what is known of it in play: what kind of place it is (`biome`), its architecture and what
  fills it (`buildings`), how its parts and major places lie (`places`), who holds it and how it feels (`mood`), its
  colours and its light (`atmosphere`).
- **The layout is always image 1:** the place's own terrain in the painting's frame, so every level keeps it.
- **Checked twice, painted again when it fails:**
  - its outlines against image 1's: how well its edges agree with the terrain's, measured against how well the
    game's own map agrees with it (a middle level must come close to the game's map, a far one less);
  - by a vision model: no writing, a pencil map seen from above (middle); no panels, seen straight down, of the
    brief's kind (far; the model calls every photograph straight down a map, so that answer is not asked of it).

## What is drawn over them, never painted

The paintings show no text, no names, no marks. Everything else is drawn over them by code, each kind its own
switch where it makes sense:

- the names of places and rooms;
- pins (on the close level only), the route, quest and spawn areas;
- the bosses' 3D models where they stand (in every level), the enemies, entrances and floor links.

## The words

- Close: `dev/imagegen/maps/close.toml` with each instance's colours and light.
- Middle and far: `dev/imagegen/maps/levels.toml`, with each brief's biome, land, plants, buildings, roads, places,
  colours and light (`dungeons.toml`), put together by `dev/tools/map-layers`.
- No names anywhere the model can read them: a name in the words, or a label in image 1, comes back as garbled
  lettering. Describe, never name.
- A change to the shared words changes every painting of that level: the runs show it and are painted anew.

## Choosing

Finished paintings go into a review queue (a contact sheet each run makes): Saneroki takes or sends back each one.
Only what is taken goes into the packs and, once chosen, into Git. Pictures not taken are not part of the style.
