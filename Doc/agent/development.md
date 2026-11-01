# Development: build, tests, tools

## Commands

Every script runs as `saneui <command>`: `saneui` lists them by group, `saneui help <command>` prints a command's own
help (a tool's docstring is its manual). The ones every session uses:

| Command | Effect |
| --- | --- |
| `saneui installdev` (`dev/build --install`) | `dev/tests/run`, then `BUILD/` from `src/*/*.toc` (one addon folder per TOC, with its art from `assets/optimized/<Module>/`, the Atlas only once `assets/optimized/Atlas/Index.lua` is there; Core's data sets compiled into `BUILD/SaneUI/Sets/` and listed at the end of its TOC), then the copy into both games at once, Forever's `_forever_` and Retail's `_retail_` (found by their `.flavor.info`; either missing: nothing is installed and it says which; `WOW_FOREVER` and `WOW_RETAIL` name them on another computer), each game with the sets of its own game version. Each built TOC gets `## X-SaneUI-Build: dev <commit>[ +changes]` or `release <tag> <commit>`; `saneui installed` shows it. LFS pointer files are refused (`git lfs pull` first). |
| `saneui build` | Tests and `BUILD/` only; `--check` is a dry run that writes nothing; `--release TAG` (default `current`) builds git's copy of a tag from `git archive` into `BUILD/release/<tag>` (installed with `saneui installrelease`, it takes our modules it lacks out of the game). |
| `saneui test` (`dev/tests/run`) | Lint, then every offline test; the first failure stops the run. Its header lists every test with what it covers. Run `lua5.1` under `ulimit -v 2000000` (a runaway test must fail, not take the machine down). |
| `saneui lint` (`dev/tests/lint`) | The TOCs (every file listed and there, one TOC per folder, the same version and interface in all), every Lua file parsed, no stray global, every door the game calls guarded (`Doc/guides/addon-standards.md`, section 10), Core's data sets compiled and checked. |
| `saneui snapshot X.Y.Z [--dry]` | A release, only when Saneroki says so: `## Version` in every TOC committed on main (a temporary index, compare-and-swap), tested on `git archive` of it, then the tag `vX.Y.Z`, the branch `release/X.Y` and the tag `current`; nothing pushed. |
| `saneui showerrors` (`dev/tools/errors [10\|30\|all\|short]`) | The game's saved error log (`SaneUIDB.log`, written at a `/reload` or logout; the game folder played last). |
| `saneui board`, `saneui showboard` | The task board: `list`, `show ID`, `add`, `edit`, `move ID COLUMN`, `start ID`, as far as In progress (Review and Finalized are Saneroki's to move, on the page; the command line refuses both); the page on 127.0.0.1 port 8768 (`/board/`). One file, `board.json`, in the private folder, written under a lock, `Backlog.md` beside it. |
| `saneui webpages` (`dev/tools/web-pages`) | The one server for every tool page, 127.0.0.1 port 8768, the user service `saneui-web-pages` (`saneui start\|stop\|status webpages`). A page is one line in its `PAGES` (a folder, or a tool with `web(request)`); pages outside the project from `~/.config/saneui/pages.json`; the ☰ menu is `dev/tools/web-nav.js`. In a session: `preview_start`, name `pages`; two sessions' lab scenes need a copy: `dev/tools/web-pages run --port N`. |
| `saneui showuilab`, `checkuilab` (`dev/tools/ui-lab serve\|check [scene]`) | The interface lab: Sane UI's Lua run under Lua 5.1 with a stand-in of the game and a fake server, drawn in the browser (`dev/uilab/`: scenes, worlds, drafts; `Doc/guides/ui-lab.md`). |
| `saneui showsections FILE [words]` | A long document's headings with lines and tokens, or the sections named. |
| `saneui data`, `readgamedata`, `readmapdata`, `readtraveldata`, `makewalkdata`, `makewalkgates`, `makecvarlabels`, `makesyncpages` | Core's data framework and the tools that stage data for it (`Doc/guides/data.md`, *Tools*). |
| `saneui patchday` (`dev/tools/patchday`) | A new game build beyond its interface, for the skill `/patchday`: the client's tables and the world against the build before, the patch notes, the map's repaint (`Doc/guides/blizzard-updates.md`, *Patch day*). |
| `saneui compareblizzard`, `readpatch`, `fixpatch` (`dev/tools/blizzard`) | A new game build's interface code against the one before, the patch notes and the fixing session (`Doc/guides/blizzard-updates.md`); `dev/tools/blizzard where\|show\|games\|uses\|adopt` (the map, *Blizzard's code*). |
| `saneui patchday` (`dev/tools/patchday`) | A new game build beyond its interface, for the skill `/patchday`: the client's tables and the world against the build before, the patch notes, the map's repaint (`Doc/guides/blizzard-updates.md`, *Patch day*). |
| The art, map, image and voice tools (`make…`, `show…`, `atlas`, `gpurunner`, `voicedb`, `makevoices`) | `saneui help <name>`; the guides `images.md`, `map-style.md`, `image-generation.md`, `voice-generation.md`. |

A new executable in `dev/`, `dev/tools/` or `Scripts/` needs its `GROUPS` entry in `dev/saneui` (and `BACKGROUND` for
`start|stop|status` verbs) in the same commit: `dev/tests/saneui.py` fails otherwise. Required on this computer and
in a cloud session: Bash, Python 3, `lua5.1`, `luac5.1`, `rsync`; the art and map tools also Pillow, NumPy and
ImageMagick. No package manager, no downloads for the offline tests.

## Tests and their limits

`dev/tests/*.lua` run a module against `dev/tests/wowstub.lua`, a stand-in of the game's widgets, events, timers,
cursor, spells and options; `dev/tests/games.lua` (made by `dev/tools/blizzard games`) takes Forever's extras away
when a test plays Retail (`W.Play("retail")`). Unknown widget methods succeed silently and nothing there is secure or
secret, so a green suite proves simulated behaviour, not the real client's API, rendering, protected calls or taint:
the game's own saved error log (`saneui showerrors`) is the first place to look after a failure in the game. The
Python tests cover the tools (`dev/tests/*.py`, `dev/tests/data/`, `dev/tests/blizzard/`). A test's name says what it
covers (`dev/tests/run`'s header); keep tests next to the logic they prove and let them fail when the fix is undone.
