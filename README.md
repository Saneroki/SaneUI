# Sane UI

**Status:** 0.3.0, written and tested outside the game; the split into five addons is **not yet tried in the game** · **Since:** 2026-10-14 · **Game:** WoW: Forever (interface 16001)

## TL;DR
A user interface addon for World of Warcraft: Forever, built in modules. Each module is an addon of its
own that you switch on and off in the game's addon list. The first one is **Abilities**: the spells
you have not learned yet are listed in your spellbook in grey, you can reserve action bar buttons for
them, and you see what you can train and what it costs.

## How to use
- **Install:** copy the folders in `BUILD` (`SaneUI`, `SaneUI_Abilities`, `SaneUI_Tooltips`, `SaneUI_Social`,
  `SaneUI_Combat`) into `World of Warcraft/_forever_/Interface/AddOns` and restart the game. Their data is
  Forever live's: the beta's client (`_classic_beta_`) does not use it, so a copy there goes without its data
  (`saneui installdev` puts the beta's own in).
- **Switch modules on and off:** in the addon list, under the category *Sane UI*, the line *Sane UI* has
  the modules under it. Tick or untick each one by itself. *Sane UI* itself must stay ticked.
- **In the game:** `/sane` says which modules are on and lists their commands. The options are under
  Esc > Options > AddOns > Sane UI: under it the pages Profiles, General and Appearance, and a page per
  module that is switched on.
- **What changed between versions:** [Doc/changelog.txt](Doc/changelog.txt).

| Module | Addon | What it does | Details |
|---|---|---|---|
| Core | `SaneUI` | Chat lines, game events, error catching, `/sane`, saved settings and profiles, windows. Needed by all others. Holds the options and Sync (below) | [README](src/Core/README.md) |
| Core: Settings | `SaneUI` | The options pages | [README](src/Core/Settings/README.md) |
| Core: Sync | `SaneUI` | The settings the game keeps for each character (Edit Mode layout, chat windows and channels, camera, nameplates, ...) the same on all characters and in profiles. Its switches are on the options page *Profiles*, tab *Accountwide* | [README](src/Core/Sync/README.md) |
| Abilities | `SaneUI_Abilities` | Unlearned spells in the spellbook, reserved buttons, a Home page with what you can learn now | [README](src/Abilities/README.md) |
| Tooltips | `SaneUI_Tooltips` | The game's tooltips drawn anew: items (with which of your characters have them), spells, units (bars, target, buffs), buffs, quests; every section under its name, other addons' lines in one section of their own (*Addons*), 3D models of units, mounts, pets and gear; can follow the mouse | [README](src/Tooltips/README.md) |
| Social | `SaneUI_Social` | A chat window in the style of a messenger, in place of the game's chat: bubbles, yours on the right, a line to write in. Also joins or leaves the game's chat channels on every character. A prototype | [README](src/Social/README.md) |
| Combat | `SaneUI_Combat` | Frames for the fight: your own, target, pet, party, raid, buffs, nameplates. Set up, nothing built yet | [README](src/Combat/README.md) |

## Building
Every script is under one command, `saneui`, by a name that says what it does (`dev/saneui`; `saneui` alone
lists them all, the Konsole greeting shows the main ones). Once on a computer: `dev/saneui --link` makes
`~/bin/saneui`.

```bash
saneui installdev          # the dev build into the game: the working tree, tested and built
saneui installrelease      # the release into the game: the tag current, or one named (installrelease v0.3.0)
saneui build               # test and build into BUILD only (--release TAG: a release, into BUILD/release/TAG)
saneui installed           # which build the game has
```
Then `/reload` in the game (a new file or a first install needs a game restart). The installs go into both
games at once, Forever's `_forever_` and Retail's `_retail_`, each with the data sets of its own game version (a
client does not use another's); if either folder is missing, nothing is installed. `WOW_FOREVER` and `WOW_RETAIL`
name the folders elsewhere.

- **The dev build** is the default: the working tree as it is, with every change not yet committed. Its TOCs
  say `## X-SaneUI-Build: dev <commit>` (`+changes` when the tree differs from the commit).
- **A release** is a snapshot of the dev build that git keeps under a version tag (`v0.3.0`, ...), on its
  release branch; the tag `current` names the newest. It is built from git's copy of the tag, never from the
  working tree, so nothing unfinished goes in, and it goes into the game whole: a module of the dev build it
  does not have leaves the game until the next `installdev`. Its TOCs say `release <tag> <commit>`.
- **Making a release:** `saneui snapshot 0.4.0` (`dev/snapshot`, `--dry` to see first) sets the version in
  every TOC and commits it on main, runs the tests on that commit, then names it: the tag `v0.4.0`, the
  branch `release/0.4`, and `current` moved to it. Only what is committed goes in. Nothing is pushed.
- **A new script** gets its command in `dev/saneui` (its name, what it does, and its words on the greeting
  card if it is in daily use); the tests fail on a script without one.
- **Background work** has verbs: `saneui start|pause|resume|stop|status gpurunner` (the queue of ComfyUI
  renders by priority while the graphics card is idle; `saneui gpuqueue` lists it, `saneui switch <job>` runs
  another job now, `saneui rebuildstart <job>` rebuilds a job's plan and runs it now),
  `saneui start|stop|status comfyui`.

## Trying what is on GitHub, such as a Claude cloud session's work
```bash
Scripts/update                      # the branch you are on
Scripts/update --latest             # the cloud session's branch (claude/...) pushed to last
Scripts/update claude/<name>        # that branch; Scripts/update main goes back
```
It fetches from GitHub, switches to the branch, pulls it, then runs `dev/installdev`: the game has it after a
`/reload`. It never merges and stops on changes not committed. A cloud session's branch that GitHub has
started anew is taken as it is there; commits only on this computer are first kept on a branch `saved/...`.
`Scripts/update --list` lists GitHub's branches, newest first.

## Technical details
- **One addon per module.** `src` has one folder per module, each with its own TOC. Core is the addon
  `SaneUI`; every other module is `SaneUI_<Module>`, depends on Core only and is grouped under it in the
  addon list (`## Dependencies: SaneUI`, `## Group: SaneUI`). They share one global table, `SaneUI`.
  The options (`src/Core/Settings/`) and Sync (`src/Core/Sync/`) are folders of Core, in its TOC: no modules.
- **The build** (`BUILD`) has one addon folder per module, named after its TOC (`src/Core` becomes
  `BUILD/SaneUI`): the module's folder without the READMEs, plus the licence. It is made by `dev/build`
  (a release's in `BUILD/release/<tag>`) and never edited by hand.
- **Copy, not symlink:** the game runs in Steam's container, which cannot see `/data`.
- **Tests** (`dev/tests/run`) run without the game, against a small stand-in for the client:
  a lint (TOCs, syntax, stray globals), Core with its options, Sync, Abilities, Tooltips, Social and the
  windows. They prove the rules, not the look.
- **Blizzard's interface code is in the repository:** `references/BlizzardInterfaceCode/` (46 MB), the base the
  addon is built on and the ground truth it follows. The rest of `references/`, such as Blizzard's interface
  art (11 GB), stays local.
- **Licence:** MIT, one licence (`LICENSE`) for Core and every module with its data; the build gives each
  addon a copy.

## Files
| Path | What it is |
|---|---|
| `src/` | The modules: `Core/` (with `Settings/` and `Sync/` inside), `Abilities/`, `Tooltips/`, `Social/`, `Combat/`, each with a TOC and a README |
| `references/BlizzardInterfaceCode/` | Blizzard's interface code as the client ships it: the API and templates the addon builds on |
| `BUILD/` | The build to hand out, one addon folder per module; also what is copied into the game |
| `dev/saneui` | The one command of all scripts (`saneui`), by expressive names |
| `dev/build` | Tests and builds into `BUILD` (`--install`: into the game too; `--release TAG`: a release) |
| `dev/installdev`, `dev/installrelease` | The dev build or a release, tested, built and copied into the game |
| `dev/snapshot` | A release: the version in every TOC, the tag, the release branch, `current` |
| `Scripts/update` | Fetches and pulls from GitHub (the branch you are on, one named, or the newest cloud session's), then `dev/installdev` |
| `assets/` | The original art (banners, icons, logo); `assets/optimized/` the game's textures made from it by `dev/tools/art` |
| `dev/tests/` | `run` (everything), `lint`, `core.lua`, `sync.lua`, `abilities.lua`, `tooltips.lua`, `social.lua`, `window.lua`, `voices.py`, `wowstub.lua` (the stand-in client) |
| `dev/tools/` | `art` and `tooltip-art` (the game's textures), `errors` (prints the error log), `cvar-labels` (the shipped CVar names), `sync-pages` (what each of the game's options pages sets, for Sync), `project-index` (the index in `Doc/agent/`) |
| `Doc/changelog.txt` | What changed, for users |
| `Doc/Changed.md` | What changed, for developers: everything |
| `Doc/guides/` | How to design and build: Blizzard's design principles, addon standards, GUI development, images |
| `Doc/agent/` | Notes for a new chat: a map of the project, one page per module |
| `Doc/ideas/` | Ideas for later modules |
| `Doc/KnownIssues.md` | Issues found in QA, per module |
| `CLAUDE.md` | The project's rules for Claude: kept on this computer only, not in the repository |

## History
- 2026-10-15 — Settings and Sync are part of Core (`src/Core/Settings/`, `src/Core/Sync/`): no addons of their
  own any more. Four addons: Sane UI, Spellbook, Tooltips, Chat.
- 2026-10-14 — New module: Chat, a first prototype.
- 2026-10-14 — Sane UI 0.3.0: the spellbook's Home page and marks; the old training list is gone. Modules are
  called by their plain name (*Settings*, *Spellbook*, *Tooltips*); Settings is only loaded when the options
  are opened.
- 2026-10-14 — New module: Tooltips.
- 2026-10-14 — Sane UI 0.2.0: every module is an addon of its own, switched on and off in the addon list.
  Settings became the options module; the options have a general page and a page per module.
- 2026-10-14 — Sane UI 0.1.0: Core, Settings, and the addon *Actionbar Organizer* rewritten as the
  Spellbook module.
