# Sane UI: quick context for a new chat

Reviewed 2026-10-14 against source at `be710d5`. This is repository memory, not hidden chat memory.
Use current source and the user's instructions when they differ from a note.

## Read as little as needed

1. Read this page (and root `AGENTS.md` where there is one); check `git status --short` and `git log -5 --oneline`.
2. Read the relevant note below and the matching development guide: long ones by section (`saneui showsections FILE` lists them).
3. Read the current implementation and nearby tests for the requested behaviour.
4. Look up only the needed Blizzard APIs/templates locally. Avoid generated copies in `BUILD/`.

| Task | Next reading |
| --- | --- |
| Lifecycle, events, errors, saved variables, options, shared windows | [core.md](core.md) |
| Future spells, reservations, action layouts, Action Bar 1's page, spellbook/Home UI | [abilities.md](abilities.md) |
| Tooltip content, layout, live unit data, quests, prices | [tooltips.md](tooltips.md) |
| Messages, bubbles, native chat, input, filtering/fading | [social.md](social.md) |
| Navigation: minimap, world map, quest log, pins, routes, leveling guide (built: window, both views, canvas, terrain and art at every zoom, the game's minimap and map taken over; pins, quest log, top bar, routes, dungeon maps with their bosses; the guide to come; handoff) | [navigation.md](navigation.md), then `Doc/ideas/Navigation.md` |
| Combat: its window at the bottom middle, its full screen with our own spellbook and talents (built), as the game's; your spellbook and talents keys open them; your, your target's and your focus's frames in the nameplates' look, with power bars, the auras that matter most and your aura lists, their targets and your pet as rows under them, the casts and your timers part of the frames (built); the game's action bars clean (built); one frame for party and raid in place of the game's, sized and previewed in Edit Mode, your own slot a button to the group's tools in place of its raid manager (built); boss frames, party pets, your buffs (not built yet) | `src/Combat/README.md`, `Doc/ideas/Combat.md` |
| Nameplates: the game's plates in our dress (built: round-cornered health bar as wide as its one line inside (quest, raid marker, level, item level, threat, name, health), the unit's power and combo points along its bottom, border by rank, glow on aggro, own debuffs above, a foe's buffs left, crowd control right, raid marker; strangers' and critters' plates hidden; smaller far away; the combat text over plates and over your character, pencil drawings for misses, parries, blocks) | `src/Nameplates/README.md` |
| Speed Leveling: one questing key and your leveling guide over the world, independent of any other addon (built: the key loots the corpse beside you, talks to the quest giver in front of you and takes/hands in its quests (running you to the NPC found by the game's Click-to-Move), uses a step's item on the corpse or creature its words name, picks up quest objects, attacks your foe, else finds and marks what your quests and guide want around you nearest first, hearths when the guide says, uses a quest item when nothing is around; the game's secure state driver and override bindings, Find's macro chained for the 255-char limit; the loot itself is the Loot module's, set to take everything; the key runs you to corpses around you, leaves an NPC you are through with alone and closes a talk that is done; the game's questions on equipping and destroying answered; only the guide's quests taken, quest rewards chosen, new upgrades put on, group rolls agreed between your characters; your class's quest chains over the guide as your level reaches them; Solo rests it all. Your professions level along the guide: where it passes the most nodes, a check before a harder zone, a detour to a node the minimap shows close to your way, cloth while the kills pay. The guide runs by our own engine: the guides that come for each game (a guide pack per game, chosen by a right click on the view), guides you paste as text and the guides you bought, opened for your own account from the import string; on, paused or off, also in the minimap's satchel; a frameless view, arrow and icons placed in Edit Mode) | `src/SpeedLeveling/README.md`, then `Doc/ideas/Leveling.md` |
| Data: Auction House (`src/AuctionData/`) and Data: Auction Scans (`src/AuctionScans/`): no code, the files of the auction prices and of every scan whole; Core fills and reads them | [core.md](core.md) |
| Economy: the tab Deals on the game's auction house window, open first: what to buy and sell right now, a click each, the gold on sale (`src/Economy/README.md`, plan `Doc/ideas/Economy.md`); Core's prices, forecast and fees | `src/Economy/README.md` |
| Loot: the game's loot window and roll frames stood in for (built: the loot window with no window round it (a line a thing, a bar in its quality's colour, a quest's gold, and an A; Link and Close, bare off white words, at the foot; a thing taken, the next under the mouse) at the mouse or placed in Edit Mode, things taken at once as the loot is ready by switches of kinds (coins, currencies, quest items and junk at first) and the player's word on items, listed in the options' tab Your items, the game's Auto Loot lent off, the master looter's menu, a page that makes room when the bags are full, roll cards with who chose what, a feed of what you and your group receive, what was taken at once included; the game's `LootFrame` no longer hears `LOOT_OPENED`, its `GroupLootContainer` lent to a hidden frame) | `src/Loot/README.md` |
| Guild: the guild window on Social's full screen or alone (built: the page with all tabs, overview, roster, equipment, the guild key; Core's wire and guild records; the other views to come) | `src/Guild/README.md`, then `Doc/ideas/Guild.md` |
| Inventory: own character sheet, bags, alts' snapshots on its full screen (built: window in the bottom right corner, its full screen and board; the windows to come; never the game's panels, which taint the window manager) | `src/Inventory/README.md`, then `Doc/ideas/Inventory.md` |
| Lore: NPC talks as a scene (built: gossip and quests see-through over the world, the answers beside them, the quest under them, the interface faded out with its tooltips kept, each reward read for you: its gear kind, usable, sell value, what it changes; the words wait: a left click cycles them, a right click accepts or says goodbye, Space goes on; the game's windows held); books and letters, AI voice overs, a library of the world's lore, tidbits (ideas) | `src/Lore/README.md`, then `Doc/ideas/Dialogue.md`, `Doc/ideas/Lore.md` |
| Game settings kept per account/character/profile, chat windows, own channels | [sync.md](sync.md) |
| Core's data framework: the master (`assets/data/`), Core's set files, `Data.Set`, the scheduler, the characters (built: 1a, 1b, 1c.4 in part; Tooltips reads Quests, Drops, Characters) | [Doc/guides/data.md](../guides/data.md), then `Doc/ideas/Data-build.md` |
| Build, tests, generators, reference paths, documentation caveats | [development.md](development.md) |
| Locate a declaration or find changed files | `rg -n 'symbol' src dev`; `dev/tools/project-index --check` |

## What exists

Sane UI replaces or extends parts of WoW: Forever's UI. Version `0.3.0`, interface `16001` in all
nine TOCs. Modules are independent addons under category/group Sane UI; only Core is required.
Core holds the options (`src/Core/Settings/`, `Core.Config`: pages put up at login, filled when first
opened) and Sync (`src/Core/Sync/`, `Core.Sync`); neither is a module. Abilities extends the game's book with future spells,
reserves action slots and keeps Action Bar 1 on the page you chose. Tooltips draws panels over native tooltips. Social supplies a messenger-style
window and temporarily seats Blizzard's own chat edit boxes in it, and joins or leaves the game's chat
channels as chosen on its page. Nameplates (2026-10-20) dresses the game's own plates: a round-cornered
health bar over the game's, as wide as its one line inside (quest, raid marker, level, item level, threat, name, health), the unit's power and your combo points
along its bottom, a border by rank, a red glow on aggro; own debuffs above it, a foe's buffs left, crowd control
right, in the game's aura containers; the raid marker; strangers' player plates hidden; smaller far away (the
game's CVars); the game's parts under it at alpha 0 (`src/Nameplates/README.md`).
Combat (2026-10-16) is set up for unit frames, party, raid, buffs and pets; built (2026-10-20): its window at the bottom middle, whose full screen (the bottom edge's middle
half, or your spellbook and talents keys) holds our own spellbook and talents, as the game's, and a talent planner Sane UI
knows as a window of its own (the known addons, Core's `Neighbours.lua`) (`src/Combat/README.md`, plan `Doc/ideas/Combat.md`). Inventory (2026-10-20) is a window in
the bottom right corner whose corner fills the screen with its own character sheet, bags and alts' snapshots, being built (`src/Inventory/README.md`, plan `Doc/ideas/Inventory.md`). Navigation (2026-10-18) is the minimap and the map in one
window, without the map's data yet (`src/Navigation/README.md`, plan `Doc/ideas/Navigation.md`); its painted view
is the module Atlas (`src/Atlas/`, load on demand; its art and index made into `assets/optimized/Atlas/`, built only
once they are there). Sync keeps the game's per-character
settings (CVars, chat windows/channels, Edit Mode layout, action bars) in the profile in use (*Accountwide settings*
on, the profile *Accountwide* for every character at first; off, each character's own Sane UI settings and nothing
of the game's); its switches are in the tab Game settings of the options page Profiles, next to the CVar list.

All addon source is Lua and TOCs, plus XML templates (`Core/Settings/Banner.xml`, `Core/Settings/CVars.xml`: settings-list rows);
no package manager or compiled application. Original art ships in `<Module>/Art/`: banners as BLP, Tooltips' masks and shapes as TGA (`dev/tools/tooltip-art`).
Development scripts use Bash, Python 3 and Lua 5.1. Shared global `SaneUI`; account saved variable
`SaneUIDB` and per-character `SaneUICharDB`, declared only by Core. The game's `Settings` global is distinct from `Core.Config` (Sane UI's options).

`/sane` (`/saneui`) lists enabled modules and commands; Core owns `errors`, `options`
(`config`, `settings`), `window`; Abilities owns `spellbook` (`sb`); Social owns `social` (`chat`).
Tooltips has settings but no dedicated slash subcommand.

## Validation and scope of this review

`dev/tests/run` passed on 2026-10-17: lint (5 addons, 99 TOC files) and Lua suites of **1,985 checks**:
Core (with Settings and Profiles) 320; Abilities 339; Tooltips 363; Social 349; Sync 88; Windows 351; Data 175.
These numbers are a dated baseline; run the suite to obtain current results.

Review covered addon implementation, TOCs, module documentation, guides, development tools,
test harness/coverage and recent architectural history. Data tables were inspected by schema,
registration and provenance, rather than reproducing every numeric record in these notes.
The index fingerprints every project file in its scope, including complete data-file contents.
Generated build copies, personal saved settings, IDE metadata and the roughly 16 GB local external
reference library were not exhaustively read. There is no need for future chats to do that either.

The current module changes have substantial pending in-game QA. Earlier tooltip panels were tried;
that does not validate today's layouts. See module READMEs for detailed human QA lists.

## Keeping the memory useful

These notes contain stable architecture and traps, not a duplicate manual or task diary. Update the
affected note when a contract, file responsibility or workflow changes. Keep user-facing behaviour
in module READMEs and record actual changes in `Doc/Changed.md`.

`files.json` is a generated navigation index with SHA-256 hashes, sizes, source declaration line
numbers, Markdown headings and TOC load order. Do not read it whole. Use `--check` to identify stale
files, or query a selected entry with Python. After rereading changed source and updating prose,
run `dev/tools/project-index`; refreshing hashes alone does not refresh the notes.
