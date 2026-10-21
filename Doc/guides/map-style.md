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

The wheel zooms smoothly through them, each level's look blending into the next, never a step.

| Level | What it shows | Look | Made from |
| --- | --- | --- | --- |
| **Close** | the terrain, exact: every rock, wall, building, shore and walkable spot where the game has it | a photorealistic satellite photograph of exactly that ground, seen straight down | the game's terrain and indoor maps, repainted with the Atlas' words (`dev/imagegen/maps/atlas.toml`) |
| **Middle** | a zone or one floor of an instance, its walls and walkable ground traced exactly | a beautiful hand-drawn map in pencil on paper, seen straight from above | the close level's terrain, drawn anew (`levels.toml`, `[middle]`) |
| **Far** | the world with both continents, or an instance as a whole | a free, realistic fantasy painting, seen from high above at an angle | the zones' or the instance's layout and brief (`levels.toml`, `[far]`) |

### Close: pixel-exact

- Nothing is moved, added or taken away: the painting changes only how things look (materials, texture, fine
  detail, light), never where or what anything is. The game's water and lava are where the game has them, and each
  painting is checked against them.
- The colours stay the game's: the colour pass moves each painting's broad colour back toward the game's terrain;
  the light is the zone's (or the instance's), its brief's first sentence of atmosphere.
- **Soft edges only where nobody walks:** a zone's outermost outline, where the player cannot go (the mountains
  between zones, the edge of the world), blends into a natural transition. Every coast and shore, every pier,
  dock and bridge, every pass into the next zone stays pixel-exact.
- **Indoor maps are clear around, never black:** buildings, caves, city districts and the instances' floors have a
  transparent background, in the same place and scale as the terrain, so they lie seamlessly over what is under
  them.
- **The middle level is under it:** where the close level has nothing to show (around an instance's halls and
  caves, the void the game's textures leave black), its own middle level's drawing shows, never black or an empty
  colour.

### Middle: pencil on paper, strict

- Drawn in the interface's own paper and pencil ([interface-style.md](interface-style.md), *Paper*, *Pencil*):
  loose, clean graphite pencil lines on cream parchment with soft faint clouds and an extremely subtle grain.
- **Strict:** every wall, cliff, shore, edge of water and outline of every hall, room, corridor and walkable ground
  is traced exactly along the terrain, with the same shape and size. The walkable ground stays clean paper; solid
  rock and ground nobody walks are shaded lightly with hatching; water is drawn with fine pencil ripples.
- Graphite grey only; plain calm paper: no stains, no sketches painted in.
- Seen straight from above, in the map's own frame, so the close level lies exactly over it.
- In the world it is a whole zone, showing its open view (a city under a roof or a tree is drawn as the game opens
  it); in an instance one floor.

### Far: reimagined, realistic

- A free, realistic fantasy painting like cinematic concept art: very cool to look at, the place's mood and lore
  first. It need not be exact or useful for finding one's way; a perspective angle is welcome.
- **The world:** both continents always together (no view of one continent alone), each zone a realistic render of
  its land and mood with only a loose idea of its major places, the borders fitting together and softened, each
  zone clearly sectioned from the next. What stands there in the lore is shown, not the game's open view:
  Teldrassil the world tree itself, Ironforge the full mountain.
- **An instance:** the whole instance in one view, its halls and rooms where they lie, the roofs and the rock above
  cut away, seen at a steep angle like a detailed model on a table.

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
- Middle and far: `dev/imagegen/maps/levels.toml`, shared by the world and the instances, with each brief's mood,
  places, colours and atmosphere (`zones.toml` for the zones, `dungeons.toml` for the instances, the same fields).
- No names anywhere the model can read them: a name in the words, or a label in image 1, comes back as garbled
  lettering. Describe, never name.
- A change to the shared words changes every painting of that level: the runs show it and are painted anew.

## Choosing

Finished paintings go into a review queue (a contact sheet each run makes): Saneroki takes or sends back each one.
Only what is taken goes into the packs and, once chosen, into Git. Pictures not taken are not part of the style.
