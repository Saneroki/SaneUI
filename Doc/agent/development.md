# Development, data and reference lookup

## Commands

| Command | Effect |
| --- | --- |
| `dev/tests/run` | Lua 5.1 syntax/global/TOC lint, then all offline tests |
| `dev/build` | Tests, rsync source into five `BUILD/` addon folders (one per `src/*/*.toc`), compile the data packs (`BUILD/SaneUI_Data_*`, Forever live's), install copies in game (the packs of the game folder's own game version, by its `.flavor.info`) |
| `dev/build --no-install` | Tests/build only |
| `dev/build --check` | Tests and rsync dry-run; writes nothing |
| `dev/tools/errors [10\|30\|all\|short]` | Read client's saved error log after reload/logout |
| `dev/tools/tooltip-art` | Regenerate six original white/alpha TGA shapes in Tooltips/Art |
| `dev/tools/art` | `assets/*.png` → BLP2 DXT5 with mipmaps, sized for 4K from the drawn size, in `assets/optimized/`; banners also to `<Module>/Art/banner.blp`; kind `sheet` keeps a flipbook whole (needs Pillow, NumPy, ImageMagick; see `Doc/guides/images.md`) |
| `dev/tools/art-measure [png] [w] [h]` | Re-measure texture sizes and filters for a picture (the numbers in `Doc/guides/images.md`) |
| `dev/tools/imagegen <list.txt> [--count N] [--only a,b] [--dry-run]` | Run a prompt list through a local ComfyUI (`comfyui start`): the list includes a recipe from `dev/imagegen/recipes/` (workflow by name, settings, fixed words) and the house style `dev/imagegen/style.txt`; saves `<name>-<seed>.png` (clips: a folder of frames and a `.gif`), `contact.png` and `imagegen.jsonl` in its `out:` (stdlib; Pillow for BLP references, flatten, previews; see `Doc/guides/image-generation.md`) |
| `dev/tools/flipbook <clip> <sheet.png> [--frames N] [--drawn UNITS] [--loop fade:8\|drop-last] [--glow]` | A clip's frames → a power-of-two flipbook sheet, a `.gif` preview and the FlipBook numbers; the sheet goes through `dev/tools/art` as kind `sheet` (Pillow, NumPy) |
| `dev/tools/voicedb build\|stats\|show\|request\|batch\|names\|check` | The voice database: every game text that gets a voice, its speaker, preset and direction, in `dev/voices/build/` (see `Doc/guides/voice-generation.md`) |
| `dev/tools/voicegen key\|account\|design\|pick\|names\|say\|sound\|ogg` | Send the voice database's lines, the cast's designs and the names to the cloud voice service; master WAVs and game Ogg files in `dev/voices/sound/`, every file made in `dev/voices/made.jsonl`; short UI sounds as candidates in `assets/generated/sounds/`. Key and service config in `~/.config/saneui/voice-service.json`, never in the repository (stdlib and ffmpeg; see `Doc/guides/voice-generation.md`) |
| `dev/tools/project-index [--check]` | Regenerate navigation hashes/index, or report stale files |
| `dev/tools/cvar-labels [--check]` | Regenerate `src/Core/Settings/Data/CVarLabels.lua` (CVar → game string names) from `references/` options code; `--staging [file] [--build N]` writes the same as staging for the data set *CVarLabels* (`dev/data/staging/cvar-labels.jsonl`) |
| `dev/tools/data check\|import\|compile\|game\|show\|diff\|stats` | Core's data framework (`Doc/guides/data.md`): check the master in `assets/data/` (run by `dev/tests/run`); `import <staging> [--apply] [--take]` takes staging in, the report first (new, agreeing, changed, older, gone, conflicts; `--take` writes conflicts in as corrections); `compile <folder> [--game G]` the packs; `game <folder>` a game folder's game version; `show <set> <key>`, `diff <set> [--patch P]`, `stats` for people; `--master <folder>` for another master (tests); Python in `dev/data/` |
| `dev/tools/sync-pages [--check]` | Regenerate `src/Core/Sync/Data/Pages.lua` (what each of the game's options pages sets) from `references/` options code |

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
| `tooltips.lua` | Reader output, model redraw, live values, quests/cache/prices, native restoration/anchors/secrets, per-kind/module fallback |
| `social.lua` | Event decoding, width/wrapping, native input/restoration, filtering, fading, lockdown and fallback, game channels join/leave |
| `sync.lua` | Sync parts capture/apply, scope and state filters, reload dialog, combat wait, kept CVars, profiles, per-character CVars, the generated page lists |
| `window.lua` | Dock arithmetic, movement/sizing/skin, expansion/demo |
| `data.lua` | The data framework in the game: the scheduler's budget, pauses (combat, restrictions), failing jobs, `Fresh`/`Spend`; the sample packs (compiled by `data/sample.py` into a temporary folder) read back by the codec as the tools meant them, packs found, loaded one a frame after the loading screen and out of combat, missing, switched off or refused (format, game version, not loadable, a file that does not run), `Get` never loading, frozen records, the client's game version, `/sane data`; `History`, `At`, `Versions`, `Changes`, `Keys` and `Each`, also from a pack newer than the client |
| `data/sample.py` (Python) | Compiles `data/sample/` for `forever` and `forever-beta` into a folder given, with `expected-<game version>.lua` (every version of every entry as Lua tables) beside the packs: what `data.lua` compares with |
| `data/tools.py` (Python) | The data tools on `data/sample/`: every rule of the check, every case of the import within its game version (and `--take`), `show`, `diff` and `stats`, compiling (same bytes, game versions apart, rows read back by Lua 5.1), CVarLabels up to date, every set of the plan with its schema in its pack |

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

- Source has five addons: Core (`SaneUI`), Abilities, Tooltips, Social, Combat (2026-10-16). Older text saying three, four or
  six (and an addon *Settings* or *Sync*) is stale.
- Tooltips README's “Not there yet” sub-bullet on a player's specialisation (`src/Tooltips/README.md`,
  section *Not there yet*) conflicts with the spec its Player row and `Inspect.Talents` show; delete
  that sub-bullet there.
- Historical `Doc/Changed.md` entries describe removed implementations, including former external
  addon integrations; current source and newest review sections win.
- `Doc/ideas/Maps.txt` is a proposal (top-centre minimap hot corner, expand/zoom out), no Maps module.
