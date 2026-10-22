# Blizzard updates

What to do when the game gets a new build: extract Blizzard's interface code and art of that build, compare the
code with the build before it, and get a todo list of what in Sane UI has to change. Read this before taking a new
build's code in, or before changing `dev/tools/blizzard`.

The tool is a development tool only: Python in `dev/blizzard/`, run by `dev/tools/blizzard`, tested by
`dev/tests/blizzard.py`. Nothing of it ships with the addon.

## Sane UI's base: the newest export, a hard rule

Blizzard's code and art that Sane UI is built on, and that its tools read (the lab, the made files, the art tools),
are the **newest export**: of the exports this computer keeps, the one with the highest version number. Never
`references/`: that is an old in-game export, kept only to compare with (`git:<revision>`).

- Where they are kept: the folder `~/.config/saneui/blizzard.json` names (`{"exports": "<folder>"}`; or
  `$BLIZZARD_EXPORTS`). It holds one folder a build, `<product>-<version>/interface/`, with `BlizzardInterfaceCode/`
  and `BlizzardInterfaceArt/` in the layout of the game's own export (`Interface/AddOns/...`, `Interface/...`) and a
  note `.build` of the build.
- `dev/tools/blizzard where` prints the newest export's code and art folders and its build; `dev/blizzard/export.py`
  (`newest()`, `required()`) gives them to the tools. A tool that needs them and finds none says so and stops.
- They are read straight from the game's install, without starting the game; the in-game console's `exportInterfaceFiles code` and `art` write the same layout into the game
  folder, and either can stand in that folder.

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
