# SaneUI Navigation: the CurseForge project

What goes into the project's fields on CurseForge (authors.curseforge.com). The file uploads come from
`saneui publish` (`dev/tools/release`); their changelog is this project's own,
[changelogs/Navigation.md](changelogs/Navigation.md).

| Field | Value |
| --- | --- |
| Name | SaneUI Navigation |
| Folder in the game | `SaneUI_Navigation` (listed under *SaneUI* as *Navigation*) |
| Summary | Your minimap and world map in one window, with quest pins, a search and routes to your map pin. |
| Category | Map & Minimap (and Quests & Leveling) |
| Avatar | `maps-avatar.png` of `saneui makelogos` (400 x 400) |
| Banner | `maps-banner.png`, at the top of the description: after the project is made, uploaded under its Images and put in by its address (Markdown: `![SaneUI Navigation](<address>)`) |
| Relations | SaneUI Core: Required Dependency (each upload sends it too) |
| Release type | Alpha, by the module's stage |

## Description

The editor set to *Markdown* when the project is made.

```markdown
**SaneUI Navigation** puts your minimap and your world map into one window. Small, in the top right
corner of the screen, it is your minimap. Left-click that corner and it fills the screen as the
world map: the same map, handled the same way, only bigger.

Made for **WoW: Forever** (English client). It is part of **SaneUI**, a set of interface addons you can
take one by one. It needs **SaneUI Core**, which the CurseForge app installs with it.

## What it does

- **One map, small and large.** Drag it, zoom with the mouse wheel from close up out to the whole world,
  right click for the map above, click to ping a spot to your group, double click to set the map pin.
- **The world drawn your way.** *Parchment* joins the game's zone maps into one seamless world map,
  *Scrying* shows the land as the minimap draws it, and *Blended* fades from one to the other as you zoom.
- **Pins in the game's own look.** Quests, flight points, rares, treasures, dungeon entrances, trainers
  and other services, and your party. The *Pins* button on the map turns each kind on or off.
- **Routes to your map pin.** A golden line leads the way on foot, by flight, by boat, zeppelin and tram,
  through portals and with the teleports your character has. On foot it turns orange or red where enemies
  far above your level roam. Drag the line on the full map to add a waypoint.
- **Your quests on the map.** The quest log opens over the full map, and stays on your screen while the
  map is small. Quest areas and open objectives are shaded where they really are.
- **Search.** The field at the top of the full map finds NPCs by name or by what they are ("nearest warrior
  trainer"), items and where they come from, quests, places and zones, and shows them on the map.
- **Dungeons and raids.** Every dungeon and raid as a banner by level, with its maps, its floors and the
  way to its entrance.
- **Your own markers.** Alt and a click puts a marker on the map. Draw lines, routes and words, and share
  your markers with your group.
- **Herbs and ore.** Gold sparkles on the nodes near you, far nodes shown on your screen, and the
  nodes you have found remembered on the map.
- **Rares and treasures.** A rare, a treasure or an event near you is told the moment the game shows it.
  Hover one on the map to see what it gives.
- **Travel.** At a flight master the full map shows where you can fly. At a dock or a tram station you see
  when the next boat, zeppelin or tram leaves, and on the trip where you are.

## How to use

- **The map:** left-click the screen's top right corner.
- **Zoom:** the mouse wheel. **One map out:** right click. **Map pin:** double click.
- **Options:** Esc > Options > AddOns > SaneUI > Navigation.
- **Size:** drag the small map's free corner.
- The game's own minimap and map are still there: *Classic windows* on the full map's bar.

## Alpha

SaneUI Navigation is in alpha: it works, but it is still changing, and you may find bugs. If a part of it ever
runs into an error, SaneUI gives that part back to the game's own map until your next `/reload`, so your
game keeps working. `/sane errors` lists what went wrong.

## Feedback and bug reports

- GitHub: https://github.com/Saneroki/SaneUI/issues
- Discord: https://discord.gg/saneui
```

## Gallery

Real screenshots from the game only, no edited or generated pictures (CurseForge's moderation policies ask
for a visible note on any AI-made showcase image):

1. The small map in the corner with pins and the golden route line.
2. The full map in *Parchment*, the quest log open.
3. The same place in *Scrying*.
4. The search with a result on the map.
5. A dungeon's banner and its floor map.
6. A flight master's map.
