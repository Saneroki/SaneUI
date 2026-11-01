# Blizzard updates

What to do when the game gets a new build: extract Blizzard's interface code and art of that build, compare the
code with the build before it, and get a todo list of what in Sane UI has to change. Read this before taking a new
build's code in, or before changing `dev/tools/blizzard`.

The tool is a development tool only: Python in `dev/blizzard/`, run by `dev/tools/blizzard`, tested by
`dev/tests/blizzard.py`. Nothing of it ships with the addon.

## Sane UI's base: the newest export, a hard rule

Blizzard's code and art that Sane UI is built on, and that its tools read (the lab, the made files, the art tools),
are the **newest export**: of Forever's exports this computer keeps, the one with the highest version number.
Retail's exports stand beside them and are read only when asked for (*Forever and Retail*). Never `references/`:
that is an old in-game export, kept only to compare with (`git:<revision>`).

- Where they are kept: the folder `~/.config/saneui/blizzard.json` names (`{"exports": "<folder>"}`; or
  `$BLIZZARD_EXPORTS`). It holds one folder a build, `<product>-<version>/interface/`, with `BlizzardInterfaceCode/`
  and `BlizzardInterfaceArt/` in the layout of the game's own export (`Interface/AddOns/...`, `Interface/...`) and a
  note `.build` of the build.
- `dev/tools/blizzard where` prints the newest export's code and art folders and its build, Forever's and Retail's;
  `dev/blizzard/export.py` (`newest()`, `required()`) gives them to the tools. A tool that needs them and finds none
  says so and stops.
- They are read straight from the game's install, without starting the game; the in-game console's `exportInterfaceFiles code` and `art` write the same layout into the game
  folder, and either can stand in that folder.

## Forever and Retail

Saneroki (2026-10-25): Sane UI is made for WoW: Forever and Retail, English clients only. Forever's client is
Retail's (the family Mainline) with a layer of its own: the game type `camelot`, its `Camelot/` folders and
`*Overrides.lua`; Retail's game type is `standard`. Both share most of Blizzard's code, the API and its
restrictions; they differ in each game's own systems (Forever: Classic's mechanics such as spell ranks, ammo,
resistances, the swing timer; Retail: housing, delves, the encounter journal) and entirely in their data (maps,
quests, NPCs, routes).

- **Which game an export is:** its product (`.build`, or the game folder's `.flavor.info`): `wowf` is Forever,
  `wow` Retail (`GAMES` in `dev/blizzard/export.py`). Each is read as its own client loads it (`CLIENTS`): the load
  groups it is in, what `[Family]` and `[Game]` stand for, and which of an addon's TOCs it takes first.
- **Forever is the default:** `newest()`, `required()` and every tool that builds on Blizzard's code take Forever's
  newest export; Retail's version numbers (12.x) are higher than Forever's and never count as Forever's newest.
  `newest(kind, "retail")` gives Retail's.
- **Where they differ:** `dev/tools/blizzard games [--out FOLDER]` compares Forever's newest export with Retail's
  and writes lookup tables: `symbols.tsv` (every symbol that differs: forever-only, retail-only, calls-differ,
  code-differs), `files.tsv`, `addons.tsv` (whether each client loads an addon), `art.tsv` and `art-folders.tsv`
  (pictures by content key), a `README.md` of counts, and `uses.md`, the todo list of what of Sane UI's own uses
  Retail lacks or calls differently. Without `--out` they go to `dev/blizzard/reports/` (not committed). It also
  writes `dev/tests/games.lua`, what Retail lacks of Forever's as a module reaches it (globals, `C_X.Function`,
  `Enum` and `Constants` entries, events), which the tests' stand-in takes away when it plays Retail
  (`W.Play("retail")`): committed with Sane UI.
- **One symbol in both games:** `dev/tools/blizzard show <name> --retail`; `check --retail` writes the todo list
  alone.
- **One addon folder for both:** a TOC can name both Interface numbers (`## Interface: 16001, 120105`); a file
  line for one game ends in `[AllowLoadGameType standard]` (Retail's) or `[ExcludeLoadGameType standard]`
  (Forever's), never `camelot`, which Retail's client may not know (`addon-standards.md`, *Forever and Retail*);
  `_Mainline` is the family of both games.

## After a patch

Run `saneui readpatch` (`dev/tools/blizzard patch [forever|retail]`) every time a game was patched, once the
launcher has updated it. It looks which game's installed build (`.build.info`) is newer than its newest export,
and for that game:

1. **Exports the new build** with this computer's command for it (the settings' `extract`, called with the
   product), into the exports' folder.
2. **Writes our own patch notes**, the new export against the one before it, into the reports' folder
   (`patches/<game>-<old>-to-<new>/`): `notes.md` (what Blizzard changed in the interface, kind by kind, in
   words: Blizzard's addons, the API by namespace, events, widgets, enums, structures, CVars, templates,
   Blizzard's Lua, the code files per addon, the art per folder), the tables of every change (`symbols.tsv`,
   `files.tsv`, `addons.tsv`, `art.tsv`, `art-folders.tsv`, sides old and new), and `todo.md` and `todo.json`,
   what of it reaches Sane UI (the check's todo list below).
3. **Makes the Forever-Retail lookup anew** for the two games' newest exports, and the tests' list of what Retail
   lacks (`dev/tests/games.lua`: commit it with the fixes).
4. **Prepares the session that fixes Sane UI:** `session.md`, its brief (the steps, the rules for both games,
   the todo list's head), and a card on the board for it (`--no-card` leaves it out).

Then `saneui fixpatch` starts Claude Code in the project on the newest brief (`--print` gives its prompt to
paste into another session). `--again` writes a patch's folder anew from the newest two exports without
exporting. A game's first export has nothing before it: its notes come with its next patch.

**The game's facts** are the other half of a patch: `readpatch` reads the interface, not the master's items, spells and
world. For a new build of Forever, with its client tables as CSV (hotfixes laid on) and its terrain files at hand:

1. Its line in `assets/data/builds.toml`, then `dev/tools/game-data forever <build> <tables> <hotfixes> <day>` and
   `dev/tools/data import dev/data/staging/game-forever.jsonl`: read the report, then `--apply`.
2. `BUILD` in `dev/tools/map-data`, `travel-data`, `walk-data` and `walk-gates`, then the first two as `dev/tools/data`
   takes them in (`travel-data` with the batches' `--lifts`, `--portals` and `--teleports`).
3. The walking data only if the world moved (compare the terrain, the object files, the buildings and the models).
   `dev/tools/walk-data --maps <map> --processes 3`, one map at a time: a whole run holds more memory than a Claude
   session may. Each map's staging is taken in with `--apply --take`, then `dev/tools/walk-gates`.

The settings (`~/.config/saneui/blizzard.json`): `exports` (the exports' folder), `install` (the game's World
of Warcraft folder; the same default as `dev/build`), `extract` (the command that exports a product's build
there), `reports` (where the patches' folders and the lookup go; without it `dev/blizzard/reports/`, not
committed), `tables` (each build's client tables as CSV, `<product>-<version>[-laid]`, for `saneui patchday`).

## Patch day

The skill `/patchday` takes a new build the whole way, for each game whose installed build is newer than its last export,
Forever first: everything of *After a patch*, then the facts, the world, and patch notes in Blizzard's layout. Its steps
stand in the skill; what they run beyond the tools above is `saneui patchday` (`dev/tools/patchday`, with
`dev/blizzard/world.py`, `clienttables.py` and `patchnotes.py`, tested by `dev/tests/patchday.py`). Each command works on
the game's newest patch and writes into its folder:

| `saneui patchday` | Writes | Does |
| --- | --- | --- |
| `check [--json]` | nothing | Which game's installed build is newer than its last export; what the newest patch still lacks, read from what stands there, so a stopped run goes on where it was |
| `bump <game>` | `builds.toml`, `BUILD` of the data tools | The new build's line; `BUILD` is Forever's alone |
| `tables <game>` | `tables.tsv`, `tables/<Table>.tsv` | Every client table against the build before, by topic: what the master does not hold is seen too (a race's abilities); a table the client numbers anew is compared by what its rows hold |
| `world <game>` | `world.md`, `world.json` | The terrain and the map tables against the build before |
| `draft <game>` | `facts.md`, `facts.json`, `patchnotes.json` | What the master took from the game at this build; empty notes in Blizzard's layout |
| `rerender <game>` | `rerender.json`, `dev/imagegen/jobs.toml` | The repaint queued; below |
| `paint <patch>` | the paintings | The job's own command |
| `page <game>` | `patchnotes.md`, `Patchnotes/<Game>-<version>.html` | The notes checked, as text beside the patch and as a build's own page: a plain file to open, every level folded shut, one dark theme whatever the computer's is, nothing it needs outside itself. Never a page of the tools' server |
| `store <game>` | the set `PatchNotes` | The notes into the database, key the build, for a view in the game: their points, and every entry the game changed tied to the point that tells of it (`Doc/guides/data.md`, *The patch notes*); refused until they are compared with Blizzard's, or Blizzard is found to have published none: then ours stand as they are |

**What counts as moved:** the terrain is read as the game reads it, a file that only changed its bytes is no change. The
ground counts by its heights with the base added, inside a chunk and from `GROUND` yards: the game bakes a chunk's base
and its outer ring anew at times (a tile's edge on the deep sea floor jumped 500 yards while no ground moved). A placement
counts without its number, which the game renumbers at will. `walk_maps` names the maps whose walking data is made anew:
all a change reaches but an area alone. `squares` names the Atlas' squares to paint again: only what they are made from,
the ground, holes, water and minimap textures; a building moved alters the walking data, not a painting, until its
minimap texture changes.

**The repaint:** `rerender` moves the painted squares and the far paintings of zones a quarter of whose tiles changed in what a painting
is made from into
`assets/generated/replaced/<build>/`, points the maps' `state.json` at the new build's terrain, and adds the job
`patch-<build>` to the queue at priority 11, above the world's tiles. It starts nothing; the runner takes it up. A square
of the list not painted yet stays the world's tiles' own. Long jobs go into the file on Saneroki's word: running the skill
is that word. The Atlas' pack comes after the job, by Saneroki's choice.

**The notes:** `patchnotes.json`, its form in `dev/blizzard/patchnotes.py`: Blizzard's sections, groups and subgroups, "(was
X)" after what changed. Each point says where it stands: `both` (Blizzard says it and the client shows it), `client`, or
`blizzard` (what the server holds). A point Blizzard lists takes its names, numbers and scope and links to its place;
the sentence stays ours, and what we saw beyond it is its `extra`. The page's foot holds every change the master took, closed.

**Retail:** its data waits (`.claude/rules/code.md`), so `tables`, `world` and the notes only read: nothing of its facts
goes into the master, its terrain is not extracted and it has no routes or Atlas. Its notes do go into the set, which is
the one set Retail has so far.

## The pipeline

1. **Extract the new build's interface** into the exports' folder, as above. It becomes the newest export at once.
2. **Check.** `dev/tools/blizzard check` compares the newest export with the one before it and writes the todo list
   to `dev/blizzard/reports/<old build>-to-<new build>.md`, with the same as JSON beside it (not committed), and a
   summary on the screen. `--old` gives another export to compare with (its folder, or `git:<revision>` for
   `references/` as a commit has it); a path as the first argument checks another export than the newest. It takes
   about ten seconds.
3. **Work the list from the top**, ticking each item. `dev/tools/blizzard show <name>` shows a symbol in both
   exports with the diff of its code (`show C_Spell.GetSpellInfo`, `show FCF_OpenTemporaryWindow`,
   `show lua:ChatFrameMixin:AddMessage`).
4. **Adopt.** `dev/tools/blizzard adopt` makes the files that come from Blizzard's code again from the newest export
   (`dev/tools/cvar-labels`, `dev/tools/sync-pages`). Then `saneui installdev`, try it in the game, and commit the
   made files with the fixes.

The build of an export comes from its `.build` note, or from the game folder it was exported into (`.flavor.info`
names the product, `.build.info` one folder up gives its version); `--build 1.60.2.71000` gives it by hand. It names
the report and gives the TOCs' Interface number (1.60.2 is 16002).

## The todo list

| Section | Means | What to do |
| --- | --- | --- |
| Broken | Sane UI uses something the new export no longer has: a function, an API, an event, a template, an addon; or a name Blizzard's code mentions nowhere any more (a parentKey, a menu's tag, a callback's name, a mixin's method). *Maybe now* names where it may have gone: the same name elsewhere, a close new name. | Change Sane UI. |
| Deprecated | It lives on only in one of Blizzard's deprecated addons, which a later build removes. The hint is what the stand-in calls: its replacement, as a rule. | Move to the replacement now. |
| Changed | It is called differently: parameters, the API's arguments and returns, its flags (protected, secret values, restrictions), an event's payload, a structure an API returns, a template's parents, mixin or keys, an enum's values. | Check each call and handler. |
| Review | Sane UI hooks it and its code changed (the diff is in the list), or Sane UI builds on a Blizzard function or template whose code changed, or an atlas or file Blizzard's code no longer names. | Read the diff; change Sane UI if its hook or its use no longer fits. |
| Housekeeping | The TOCs' `## Interface` number, files made from Blizzard's code that would change, notes in `src/` and `Doc/` that cite a Blizzard file that changed, and last the adopt. | Do them. |

Only what Sane UI uses is listed. *For information* at the end lists the API new in the namespaces Sane UI calls.

## How it reads an export

It reads the export as this client loads it: each Blizzard addon's TOC for game type `camelot`, which also counts
the load group `mainline` (`standard` is the main game's), `[Family]` read as `Mainline` and `[Game]` as
`Camelot`; lines for the login screen and other languages left out; XML files with what they include. A file
this client does not load is not compared. The API documentation (`Blizzard_APIDocumentationGenerated`) is read
whole: it describes this client's own functions, widgets, events, enums and structures.

Every definition becomes a symbol with an id, a signature and a hash:

| Id | What |
| --- | --- |
| `lua:<chain>` | What the Lua defines at a file's top level: `Name`, `A.B`, methods `A:B`, keys of the tables it makes there. |
| `xml:<name>` | Named XML objects: templates, frames (a child's `$parent` name filled in), fonts. |
| `frame:<name>` | Frames and fonts the Lua makes with a global name. |
| `api:<chain>`, `widget:<object>:<method>` | The client's functions and the widgets' methods, from the documentation. |
| `event:<NAME>`, `enum:Enum.<name>[.<value>]`, `const:Constants.<name>.<value>`, `struct:<name>` | The documentation's events, enums, constants and structures. |
| `addon:<name>` | Blizzard's addons: whether this client loads them, on demand or not, their dependencies. |
| `cvar:<name>` | CVars Blizzard's code names. |

The signature is what a caller depends on; the hash covers the whole definition, its tokens without comments
and spaces, so a change of words or layout alone is no change. A symbol whose hash changed and whose
signature did not is called the same way but works differently inside. Besides the symbols, every name and
name-like string an export mentions is kept, so a name Sane UI uses that the new code no longer mentions at all
is found even where no symbol defines it.

## How it reads Sane UI

From `src/`: the globals each file reads (by `luac5.1`'s listing, so a local with a Blizzard name is no use of
Blizzard's), with what is reached through them (`C_Spell.GetSpellInfo`, `GameTooltip:AddLine`,
`Enum.SpellBookSpellBank.Player`); every string, with the call it is given to; what `hooksecurefunc` hooks;
methods called and keys read by name; attributes of the XML. The names Sane UI defines itself (`function A:Name`,
`A.Name =`, a table's keys, XML `parentKey`) are its own: a method or key of such a name is not taken as
Blizzard's. `dev/tools/blizzard uses` counts what Sane UI takes from the newest export; `--list` names it all;
`--unknown` names the globals Sane UI reads that Blizzard's code never mentions (the client's own functions the
documentation leaves out, or functions an older client had).

**Cite Blizzard's files so the tool can follow them:** `Blizzard_ChatFrameBase/Shared/ChatFrame.lua 120-140`
(in backticks or not; `:120` for one line), the path from the addon's folder. Such a note is listed when those
lines changed, and when they only moved, where they are now; without lines, whenever the file changed.
`Doc/Changed.md` and `Doc/changelog.txt` are history and are not followed.

## Limits

- What the client does in its own code is not in the export: a function the documentation does not list (and the
  global strings) is only seen by its name, and a change inside the client is seen only where the
  documentation's signature or flags change.
- A method hooked or called on an object, or a key read from one, is matched by its name, since which object it
  is is not known here. A hooked method of a common name (`Show`) is one line naming the Blizzard methods of that
  name that changed; one with few is shown with each diff.
- Names made at run time (`_G["ChatFrame" .. i]`) are not followed. Atlases and textures are compared as names
  Blizzard's code mentions; whether the game still has one is only known in the game.
- An empty list is no proof that Sane UI works with the new build. It is tried in the game as always.
