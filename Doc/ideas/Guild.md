# Guild

The plan for the **Guild** module (`SaneUI_Guild`, Saneroki, 2026-10-20): everything a guild needs in one window,
on Social's full screen. Decided by Saneroki: its own module, its window a window of Social's board in place of the
game's guild window there (a window of its own while Social is off), its data Core's (CLAUDE.md, *Backend and
views*), shared with the guild as **guild records** (CLAUDE.md, *Game facts, not people*: people information is
built locally for each user, never shipped). Placeholders stand where its pictures go until they are drawn
(*Pictures*); the sketches of the look are `dev/imagegen/sets/guild/`.

## The window

```
+- Guild ------------------------------------------------------------------------------- X -+
| (CREST)  <Guild name>  · <realm>               [● 12 online]  Synced 2 min ago  (⚙) [Sync] |
| (     )  Overview  Guild  Quests  Dungeons  Loot  Professions  Raid  Officers              |
|  Roster   60 members · 12 online                                                           |
|  [Roster] [Equipment] [Guild Bank] [Handbook]                                              |
|  +------------------------------------ the view --------------------------------------+   |
|  | ▌a line that says what just happened, and fades                                     |   |
+--------------------------------------------------------------------------------------------+
```

- **The head:** the guild's own emblem (the game's tabard, `GetGuildLogoInfo`) in a round crest ring that reaches
  down over the tabs; the guild's name and realm; how many are online; when the guild's records were last brought
  up to date; the gear opens the options page *Guild*; *Sync* asks the guild for what is newer.
- **The tabs** (the game's top tabs): Overview, Guild, Quests, Dungeons, Loot, Professions, Raid, Officers (only
  for the officers the guild master names). Under a tab with several views, the game's small tabs.
- **The status line** at the bottom of a view: what just happened (a note saved, an award given), for a few
  seconds; in chat while the window is closed.
- **Where:** a window of Social's full screen (Core's board, the key `guild`), the guild key opening it there; with
  Social off, a panel of its own (`Core.Window.New`, kind `panel`). It lays out down to 860 x 560: on a small
  screen its columns fold.

## The views

| Tab › view | What it shows | Its parts |
| --- | --- | --- |
| **Overview** | the guild at a glance | three columns: quest requests over planned runs; news of the guild over its chat; who is where, items offered to the guild, the race to the highest level |
| Guild › **Roster** | the members | a head (name, counts, message of the day, *Invite*, *Guild info*, the game's guild window); the members' table (class, name, level, rank, zone, note, what they do now), online and offline apart, searched and sorted; a member's page at the right (rank up and down, note, history, alts, *Whisper*, *Invite*, *Player*) |
| Guild › **Equipment** | everybody's gear | the characters at the left (level, item level, points); at the right the doll: the character's model between its slots, the item level large, its history as a chart; worn, best in slot, or both; its achievements |
| Guild › **Guild Bank** | the guild's stock | its tabs, a search, every item with its count, the bank's gold, a savings goal |
| Guild › **Handbook** | the guild's notes and links | link tags over a board of notes (important first); a note opened large; an editor for those the guild master allows |
| **Quests** | who needs help with a quest | the requests (quest, objectives, zone, level, who looks), filtered and searched; a request's page with its objectives, the others who look, *Invite*; post one from the quest log |
| Dungeons › **Runs** | runs at a time | today's and later runs as cards (time, dungeon, leader, a place for each role); a form to post one |
| Dungeons › **Together** | what can be done now | groups of members online that fit a dungeon; quests several hold |
| Loot › **Session** | giving out loot | the items of the session, the candidates by their answer with votes, the decision |
| Loot › **History**, **Wishlist**, **Rules** | every award with its proof; wishes and best in slot; how loot is given (council, reserves, rolls, points) | |
| **Professions** | who can make it | the professions, the crafters with their skill, a person's recipes, a search by item |
| Raid › **Plan**, **Numbers** | the raid's plan: groups, sign-ups, bosses and their reminders; loot and attendance in numbers | |
| Officers › **Mains and alts**, **Promotions**, **Notices** | which characters are one player; time in rank and the guild's rules for it; notices to the guild | |

Windows besides: a player's page, a member's talents, the bid window of a loot session, the points. On screen: the
level bar, a banner at a level up, the camp bar, the raid's reminders, the ready check, notices, a strip of news at the
minimap, members on the world map, the guild's lines in item and player tooltips.

## The data: Core's, as guild records

| Part (Core) | What |
| --- | --- |
| **The wire** (`Data/Wire.lua`) | Sane UI's addon messages: the prefix `SaneUI`, messages and blocks (*Messages*, `Doc/guides/data.md`), a queue that keeps to the game's budget, nothing sent in a fight or a lockdown, every sender by its key |
| **The guild** (`Data/Guild.lua`, the pack *Guild*'s saved variable) | the game's roster read and its history kept (who joined, left, went up or down a rank, reached a level); every member's records, newest by its stamp; this character's own, published to the guild |
| **Records** | per member and kind: `card` (class, race, level, gear, item level, talents, professions, played), and more kinds as the views come (requests, runs, wishes, awards, plans, notes) |

- **Published by their owner only:** a member's records come from that member (the server names the sender); the
  guild's shared records (the handbook, the rules) from those the guild master allows.
- **Each kind behind a switch** on the page *Guild*, tab *Sharing*: off, nothing of that kind is sent.
- **Asked for, not pushed to all:** each member says now and then which stamps it has (*hello*); who has an older one
  asks the owner by a whisper; the owner answers with a block.
- **Kept per guild** (realm and guild), so an alt in another guild has its own; places and camp states only in memory.

## Build order

| Step | What |
| --- | --- |
| 1 | Core: the wire, the guild's records, a module's window on another module's board |
| 2 | The module, its window, the placeholders; the roster; the overview's *who is where* |
| 3 | Character cards: equipment, talents, professions, mains and alts |
| 4 | Quests and dungeons, the overview's other panels, the news strip |
| 5 | Loot |
| 6 | Officers: promotions, notices; the guild bank and its goal |
| 7 | The level bar, the level-up banner, the race, the camp bar, members on the map, highlighting |
| 8 | The handbook; the guild's achievements (our own) |
| 9 | Raid: plans and sign-ups, the ready check; reminders and their displays |

## Pictures

Blizzard's art first (the window's plate and trim are Core's skin; tabs, buttons, class and role icons, raid
markers, paper-doll slots, achievement shields, the guild's emblems, the level-up art, parchment). Ours, in the
house style, made with ComfyUI as one set (`dev/imagegen/sets/guild/`), each with a transparent background; until
drawn, a placeholder of the game's art or a plain shape stands in (`src/Guild/Art.lua`):

| Picture | Drawn at (units) | Texture | Placeholder |
| --- | --- | --- | --- |
| Guild icon: a shield with a banner | 40 | 128 x 128 | the game's guild icon |
| Options banner: a plaque, the middle empty for the words | 300 x 100 | 1024 x 256 | none (the page's title) |
| Crest ring around the guild's emblem | 58 | 256 x 256 | the minimap's tracking ring |
| Laurel (item level, guild firsts) | 84 | 256 x 256 | a plain ring |
| Medals: gold, silver, bronze | 24 | 64 x 64 | round tinted plates |
| Ring for an icon in the news | 50 | 128 x 128 | the minimap's tracking ring |
| Best-in-slot star | 14 | 64 x 64 | the game's star |
| Level-up shield and star | 78 x 98, 30 | 256 x 256, 128 x 128 | the game's level-up art |
| Raid movement glyphs (arrow, dodge, spread, stack) and their ring | 84, 116 | 256 x 256, 512 x 512 | the game's arrows |
| Note pin, chain link, map-pin ring | 26, 14, 18 | 64 x 64 | plain shapes |
| Divider | 300 x 14 | 1024 x 64 | a line |
