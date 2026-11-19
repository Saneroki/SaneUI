# SaneUI Navigation: changelog

What changed in each version of SaneUI Navigation, newest first: a version's part is its file's changelog on CurseForge.
`saneui makechangelog` drafts a part from the commits; a person writes it for players.

## 0.3.7 (2026-11-19)

- Quest offers on the map are only quests you can really take right now: no more exclamation marks all year for
  holiday quests (Hallow's End at every innkeeper, Winter Veil, the Darkmoon Faire, Lunar Festival and the others show
  only while the game's calendar says the holiday runs), none for world events such as the war effort, and none for a
  profession you have not learnt, a breadcrumb to a quest you already have or one closed by a quest in your log.
- Quests for later (the red question mark) also wait for a reputation, a profession's skill or a quest you must have
  in your log; the tooltip names everything a quest still asks. Click it on the full map: the quest log shows every
  requirement in red and the chain of quests to do first, numbered, with who gives the first one.
- A quest giver shows as the first kind of quest the pin filter has ticked, and its tooltip names only those: with
  only Quests for later ticked, a giver of an offer and a later quest shows its red question mark.

## 0.3.6 (2026-11-19)

- Zephras Isle is on the map: zoomed out, the Skyborne's floating island lies over the sea north of the Maelstrom,
  between the two continents (the game's own world map has no place for it). Hover it for its name, click it or zoom
  in to open it. On the isle both maps follow you, with its pins and your party, and routes reach it by its airships.

## 0.3.5 (2026-11-18)

- A setup, step by step, the first time (again with `/sane setup navigation`): how to open the map (the mouse into
  the corner, a click there, a key, or all of them, on one page with the keys of SaneUI's map and the game's map),
  moving it in Edit Mode, the quest log and the map's clicks. A big arrow points into your own corner meanwhile. The
  hot corner can also be off: then the map's key opens it.
- A key for SaneUI's map (Key Bindings, under SaneUI); once it has one, the game's map key opens the game's own map.
  Click the map's box in Edit Mode to set it there, beside its hot corner's switches.
- A right click on the map no longer zooms out: the wheel zooms, a right click is for what a thing offers.
- The quest log on the screen is always in sight at first, docked in the screen's top left corner; the small map
  starts a little larger at the top right. The quest log can show only on mouseover, and still show in combat and in
  a group if you like: on the setup's quest log page, or its box in Edit Mode. Tick the quest log in *Classic
  windows* and the game's own quest tracker shows instead of ours; untick it, ours again.
- Share your map pin: right click it to send it to your party, raid, guild or someone. They are asked first; kept,
  their map pin goes there with the golden line to it.
- Sketches: eight colours, three widths and four sizes of words. Sketches shared by players of another map drawing
  addon arrive as sketches of yours, and yours reach them too.
- Hover a party or raid member's dot on the map to see who it is.
- Search the map for a guild member, or type Guild, to see where they are: members who run SaneUI show at their
  place, kept up to date while the search shows them. Each player can turn this off on the Navigation page.
- Trade goods vendors, auctioneers and other NPCs have clear pictures of what they do; no NPC is a gold coin any more.
- `/sane falls`: a fall meter. After each fall the chat tells how far down it was and how much health it took.
- Routes go down ledges and cliffs you land from alive (up to 50 m) and down mountainsides too steep to walk, never
  back up them: over the mountains instead of around.
- Working out a route no longer makes the game stutter: the work is spread over the frames, and the first route after
  logging in needs a fifth less of it.
- SaneUI is written as one word: Navigation stands under *SaneUI* in the game's addon list, beside the other SaneUI
  addons.

## 0.3.4 (2026-11-16)

- First public alpha of SaneUI Navigation: your minimap and world map in one window. Left-click the top right corner
  and the map fills the screen. The small map follows you again 2 seconds after you leave it alone.
- Pins in the game's own look for quests, flight points, rares, treasures, dungeon entrances and services, each
  kind on or off.
- Routes to your map pin on foot, by flight, boat, zeppelin and tram, orange or red where enemies far above your
  level roam.
- The quest log over the map, a search for NPCs, items, quests and places, and the maps of every dungeon and raid.
- Needs SaneUI Core, which the CurseForge app installs with it.
