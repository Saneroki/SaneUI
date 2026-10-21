# Development, data and reference lookup

## Commands

| Command | Effect |
| --- | --- |
| `dev/tests/run` | Lua 5.1 syntax/global/TOC lint, then all offline tests |
| `dev/saneui` (`saneui`) | One command for every script by expressive names (`saneui` lists them; `--card` feeds the Konsole greeting, `--names` fish's completion, `--link` makes `~/bin/saneui`); `start\|pause\|resume\|stop\|status gpurunner\|comfyui`; the GPU queue's `gpuqueue`, `switch`, `rebuildstart`, `rebuild`, `hold`, `unhold` |
| `dev/build [--install] [--release [TAG]]` | Tests (a release: its own), rsync source into the `BUILD/` addon folders (one per `src/*/*.toc`; `SaneUI_Atlas` with `assets/optimized/Atlas/`, only once its `Index.lua` is there), compile the data packs (`BUILD/SaneUI_Data_*`, Forever live's); with `--install` copies into the game (the packs of the game folder's own game version, by its `.flavor.info`); without it nothing goes into the game. Each built TOC gets `## X-SaneUI-Build: dev <commit>[ +changes]` or `release <tag> <commit>`. `--release TAG` (default `current`) builds git's copy of the tag (`git archive`, LFS art smudged) into `BUILD/release/<tag>`; installed, it takes our modules it lacks out of the game. |
| `dev/installdev` / `dev/installrelease [TAG]` | `dev/build --install` / `dev/build --release TAG --install` (`saneui installdev`, `saneui installrelease`) |
| `dev/build --check` | Tests and rsync dry-run; writes nothing |
| `dev/snapshot X.Y.Z [--dry]` (`saneui snapshot`) | A release from main's newest commit: `## Version` in every TOC committed (temp index, CAS on main), tested on `git archive` of it, then tag `vX.Y.Z`, branch `release/X.Y` (new or fast-forward), tag `current` moved; working-tree TOCs get only the version line; nothing pushed |
| New scripts | Every executable in `dev/`, `dev/tools/`, `Scripts/` needs a `dev/saneui` entry (`GROUPS`: name, words, card words or None; `BACKGROUND` for verbs); `dev/tests/saneui.py` checks it |
| `Scripts/update [branch\|--latest\|--list] [--no-install\|--check]` | `git fetch --prune`, switch to the branch (a `claude/` one only on GitHub is made tracking; `--latest` = newest `claude/`), fast-forward only, then `exec dev/build`. Stops on tracked changes and on a non-`claude/` branch that has diverged; a diverged `claude/` branch is reset to GitHub's after its commits never seen on GitHub (remote branches before the fetch, the remote ref's reflog) go to `saved/<branch>-<hash>` |
| `dev/tools/errors [10\|30\|all\|short]` | Read client's saved error log after reload/logout |
| `dev/tools/tooltip-art` | Regenerate six original white/alpha TGA shapes in Tooltips/Art |
| `dev/tools/art` | `assets/*.png` → BLP2 DXT5 with mipmaps, sized for 4K from the drawn size, in `assets/optimized/`; banners also to `<Module>/Art/banner.blp`; kind `sheet` keeps a flipbook whole (needs Pillow, NumPy, ImageMagick; see `Doc/guides/images.md`) |
| `dev/tools/art-measure [png] [w] [h]` | Re-measure texture sizes and filters for a picture (the numbers in `Doc/guides/images.md`) |
| `dev/tools/terrain-art <textures> <terrain> <tables> <map art> [--maps instances]` | The game's minimap textures (`<file ID>.blp`, every file the set *Tiles* names), its terrain files (root ADTs named `<tile key>.adt`), client tables (CSV) and map art (`<file ID>.blp`) → Navigation's terrain overview with the water cut away (64 texels a tile, 8 x 8 tiles a texture, `assets/optimized/Navigation/Art/Terrain/`), the zones' outlines (`Art/Zones/`, `Outlines.lua`), the stitched map of the zone maps (`Art/Sketches/`) and `Art/Edge.blp`, the open sky around Zephras Isle cut away as the sea is; `--maps 2991` draws one map and leaves the others' files; BLP2 DXT5 with mipmaps (Pillow, NumPy, ImageMagick; about 4 minutes) |
| `dev/tools/walk-data <game files> <tables> [--maps instances] [--only keys] [--pictures folder]` | The walking data of Navigation's routes from the game's terrain (root ADTs), buildings (obj0 ADTs, WMO roots and every group file) and water: 2.08-yard floors, surfaces, rectangles, openings, regions, one block a tile (CBOR, deflate, base64) → `dev/data/staging/walking.jsonl` for Core's set *Walking* (`dev/tools/data import`); about two minutes on 28 processes |
| `dev/tools/indoor-art <game files> <tables> [--only ids] [--check folder minimap]` | The game's indoor minimap textures (its table WMOMinimapTexture, extracted into the game files' `wmo-minimap/`), buildings (obj0 ADTs, WMO roots) → Navigation's indoor maps: one picture per part of a building, the black taken out (`assets/optimized/Navigation/Art/Indoors/`, BLP2 DXT5 with mipmaps) and `dev/data/staging/indoors.jsonl` for Core's set *Indoors*; `--check` draws them over the terrain's tiles to see they sit on their roofs (Pillow, NumPy, ImageMagick) |
| `dev/tools/map-data <tables> <terrain>` | The game's zones (UiMap, UiMapAssignment, AreaTable) and the entrances of dungeons and raids (Map's corpse points) → `dev/data/staging/map-game.jsonl` for Core's sets *Zones* and *Places*; its `Placer` puts world positions on zone maps by the game's areas (terrain chunks of the root ADTs, building parts of WMOAreaTable), its `PlaceKeys` numbers *Places*: both used by every tool that writes map points |
| `dev/tools/travel-data <tables>` | The flights of the game's flight masters from its client tables (TaxiNodes, TaxiPath, TaxiPathNode) → `dev/data/staging/travel.jsonl` for Core's set *Travel*: nodes, side, cost, length, path |
| `dev/tools/map-meta <game files> <tables> <file names> [--texels N]` | The game's terrain files (`adt/`, `adt-tex0/`, `adt-obj0/` named `<tile key>.adt`, buildings `wmo/<file ID>.wmo` and the large ones' parts `<file ID>_<part>.wmo`), client tables (CSV) and file names (`<file ID>;<path>`) → the guides of the painted map view in `assets/generated/maps/meta/`: roads, standing buildings and ground cover of both continents (128 texels a tile), `places.json` (every zone's areas, city districts, flight masters, dungeon and raid entrances, caves and mines, exits to the next zone, with positions in zone percent); NumPy, Pillow, about 25 seconds |
| `dev/tools/atlas paint\|status\|join` | Paints the Atlas (the painted map view) square by square in a local ComfyUI: both continents' land in squares of one tile at 2048 pixels, each from the game's terrain with words from `dev/imagegen/maps/zones.toml` and `atlas.toml` and what the game has in it, checked against the game's water (up to three seeds); resumable, a terminal screen with progress, time left, `p` pause (frees the graphics card) and `q` quit; `--near` a few squares around a point, `--dry` without painting; `join` stitches painted squares, cut along the line of least difference. The game's folders as for `map-meta` the first time; the run in `assets/generated/atlas/`; NumPy, Pillow |
| `dev/tools/imagegen <list.txt> [--count N] [--only a,b] [--dry-run]` | Run a prompt list through a local ComfyUI (`comfyui start`): the list includes a recipe from `dev/imagegen/recipes/` (workflow by name, settings, fixed words) and the house style `dev/imagegen/style.txt`; saves `<name>-<seed>.png` (clips: a folder of frames and a `.gif`), `contact.png` and `imagegen.jsonl` in its `out:` (stdlib; Pillow for BLP references, flatten, previews; see `Doc/guides/image-generation.md`) |
| `dev/tools/flipbook <clip> <sheet.png> [--frames N] [--drawn UNITS] [--loop fade:8\|drop-last] [--glow]` | A clip's frames → a power-of-two flipbook sheet, a `.gif` preview and the FlipBook numbers; the sheet goes through `dev/tools/art` as kind `sheet` (Pillow, NumPy) |
| `dev/tools/voicedb build\|stats\|show\|request\|batch\|names\|check` | The voice database: every game text that gets a voice, its speaker, preset and direction, in `dev/voices/build/` (see `Doc/guides/voice-generation.md`) |
| `dev/tools/voicegen key\|account\|design\|pick\|names\|say\|sound\|ogg` | Send the voice database's lines, the cast's designs and the names to the cloud voice service; master WAVs and game Ogg files in `dev/voices/sound/`, every file made in `dev/voices/made.jsonl`; short UI sounds as candidates in `assets/generated/sounds/`. Key and service config in `~/.config/saneui/voice-service.json`, never in the repository (stdlib and ffmpeg; see `Doc/guides/voice-generation.md`) |
| `dev/tools/project-index [--check]` | Regenerate navigation hashes/index, or report stale files |
| `dev/tools/cvar-labels [--check]` | Regenerate `src/Core/Settings/Data/CVarLabels.lua` (CVar → game string names) from `references/` options code; `--staging [file] [--build N]` writes the same as staging for the data set *CVarLabels* (`dev/data/staging/cvar-labels.jsonl`) |
| `dev/tools/data check\|import\|compile\|game\|show\|diff\|stats` | Core's data framework (`Doc/guides/data.md`): check the master in `assets/data/` (run by `dev/tests/run`); `import <staging> [--apply] [--take]` takes staging in, the report first (new, agreeing, changed, older, gone, conflicts; `--take` writes conflicts in as corrections); `compile <folder> [--game G]` the packs; `game <folder>` a game folder's game version; `show <set> <key>`, `diff <set> [--patch P]`, `stats` for people; `--master <folder>` for another master (tests); Python in `dev/data/` |
| `dev/tools/sync-pages [--check]` | Regenerate `src/Core/Sync/Data/Pages.lua` (what each of the game's options pages sets) from `references/` options code |
| `dev/tools/blizzard check\|show\|uses\|adopt` | A new build's Blizzard interface code (the game's `exportInterfaceFiles code`) against `references/`: `check [<new>] [--old <export>\|git:<rev>] [--build V]` writes the todo list of what reaches Sane UI (broken, deprecated, changed, review, housekeeping) to `dev/blizzard/reports/`; `show <name>` a symbol in both with its diff; `uses [--list] [--unknown]` what Sane UI takes from Blizzard; `adopt` makes the new export `references/` and remakes CVarLabels and Pages; Python in `dev/blizzard/` (see `Doc/guides/blizzard-updates.md`) |

Required build tools: Bash, Python 3, `lua5.1`, `luac5.1`, `rsync`. No dependencies need downloading
for existing offline tests. `WOW_FOREVER` overrides all tools' default Steam/Proton game folder;
check `dev/build` for the literal machine path. Copy rather than symlink: Steam container cannot
see `/data`. Build discovers `src/*/*.toc`, excludes Markdown, supplies the root `LICENSE` as `LICENSE.txt`,
deletes stale owned build directories and rsyncs installed module contents. New files/addons need
game restart; changed known files need reload. Preserve unrelated `BUILD/SaneUI.zip` and local WTF.

## Tests and their limits

`dev/tests/lint` checks every `src/` folder: one TOC each, listed/missing source, matching versions/interface,
dependency/group metadata, Lua 5.1 parsing, and bytecode `SETGLOBAL` names; and the data packs, compiled for every game
version into a scratch folder (TOC lines, files, Lua that writes no global). It is not a full API lint.
`wowstub.lua` supplies events/timers/actions/cursor/spells/options and generic widgets; unknown
PascalCase widget methods silently succeed. Tests extend this with tooltip/chat/book fixtures.
WoW's argument-passing `xpcall` is shimmed because stock Lua 5.1 lacks it.

| Test | Coverage |
| --- | --- |
| `core.lua` | Lifecycle/isolation, options pages (put up at login, filled on open), defaults, profiles, errors, guards, helpers |
| `spellbook.lua` | Lazy sources/trainer, page merge/folding/Home, reservations/pushes/combat/cursor, presets, UI restoration |
| `tooltips.lua` | Reader output, model redraw, live values, quests (on sample packs, before and after they load)/cache/prices, the Inventory section (Core's characters), other addons' lines in their own section, native restoration/anchors/secrets, per-kind/module fallback |
| `social.lua` | Event decoding, width/wrapping, native input/restoration, filtering, fading, lockdown and fallback, game channels join/leave |
| `sync.lua` | Sync parts capture/apply, scope and state filters, reload dialog, combat wait, kept CVars, profiles, per-character CVars, the generated page lists |
| `window.lua` | Dock arithmetic, movement/sizing/skin, expansion/demo |
| `data.lua` | The data framework in the game: the scheduler's budget, pauses (combat, restrictions), failing jobs, `Fresh`/`Spend`; the sample packs (compiled by `data/sample.py` into a temporary folder) read back by the codec as the tools meant them, packs found, loaded one a frame after the loading screen and out of combat, missing, switched off or refused (format, game version, not loadable, a file that does not run), `Get` never loading, frozen records, the client's game version, `/sane data`; `History`, `At`, `Versions`, `Changes`, `Keys` and `Each`, also from a pack newer than the client; packs of saved data (`Data.Saved`, a part per game version, a wrong format set aside, the lost file) |
| `data/packs.py` (Python) | A module's sample lines (`data/tooltips/`) on the real schemas, checked and compiled into packs for that module's test |
| `data/sample.py` (Python) | Compiles `data/sample/` for `forever` and `forever-beta` into a folder given, with `expected-<game version>.lua` (every version of every entry as Lua tables) beside the packs: what `data.lua` compares with |
| `data/tools.py` (Python) | The data tools on `data/sample/`: every rule of the check, every case of the import within its game version (and `--take`), `show`, `diff` and `stats`, compiling (same bytes, game versions apart, rows read back by Lua 5.1), CVarLabels up to date, every set of the plan with its schema in its pack |
| `blizzard.py` (Python) | `dev/tools/blizzard` on a small export (`blizzard/old`) and a new build made from it in the test with one change of each kind, against a small module (`blizzard/src`): Lua tokens and definitions, TOC conditions, XML and documentation symbols, every section of the todo list, hints, diffs, cited lines, the Markdown and JSON; Sane UI's own source read by `luac5.1` without problems |

A green suite does not prove native API availability, rendering, protected calls or taint.
For in-game failures inspect saved errors first. Debugger-driven runtime investigation should use
the applicable available debugging skill; source-obvious/documentation tasks need no debugger.

## Reference search routes

Start at `references/BlizzardInterfaceCode/Interface/AddOns/` and restrict `rg` to the relevant addon:

| Need | Reference addon/directory |
| --- | --- |
| The game's own spellbook, its frame/search/tab/pager behaviour | `Blizzard_PlayerSpells` and `Blizzard_PagedContent` |
| Chat edit boxes, slash/security flow, docking/minimizing | `Blizzard_ChatFrame` |
| Tooltip processor, comparisons, line kinds | Tooltip-related addons and SharedXML tooltip files |
| Menus | `Blizzard_Menu` (implementation guide) |
| Options lifecycle | `Blizzard_Settings_Shared` (implementation README) |
| Scroll boxes, fonts, frame templates, pools | `Blizzard_SharedXML`, `Blizzard_SharedXMLBase`, `Blizzard_Fonts_Shared` |
| API signatures/enums | `Blizzard_APIDocumentationGenerated` |
| Native images | `references/BlizzardInterfaceArt` (lookup a known path, do not inventory all art) |

Check flavour directories (`Camelot/Classic/Mainline/Shared`) and adjacent TOC conditions before
assuming a file loads in this client. References are uncommitted.

## Data and licensing

Trainer data has nine class files and quest rewards. Keep costs as copper and
prerequisites/race/faction filters. Tests use synthetic trainer data, so inspect real rows separately
when changing the database.

`src/Tooltips/Data/Quests.lua` is the module's own quest database; its header describes the format,
and changes are made in it. One licence, the root `LICENSE`, covers Core and every module with its data; no
module or data file has a licence of its own. Original art/name terms differ from MIT code in root
`LICENSE`; these notes are a map, not legal reinterpretation.

## Existing documentation caveats

Observed on 2026-10-14, checked again on 2026-10-16; do not mistake older text for current behaviour:

- Source has nine addons (2026-10-20): Core (`SaneUI`), Abilities, Tooltips, Social, Combat, Navigation, Atlas, Inventory,
  Nameplates, besides the data packs `dev/tools/data` compiles. Older text saying fewer (or an addon *Settings* or *Sync*)
  is stale.
- Tooltips README's “Not there yet” sub-bullet on a player's specialisation (`src/Tooltips/README.md`,
  section *Not there yet*) conflicts with the spec its Player row and `Inspect.Talents` show; delete
  that sub-bullet there.
- Historical `Doc/Changed.md` entries describe removed implementations, including former external
  addon integrations; current source and newest review sections win.
- `Doc/ideas/Maps.txt` is a proposal (top-centre minimap hot corner, expand/zoom out), no Maps module.
