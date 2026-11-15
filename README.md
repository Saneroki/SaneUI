# Sane UI

**Version:** 0.3.0 · **Since:** 2026-10-14 · **Game:** WoW: Forever, English client (officially supported
there only, for now; Retail is the developers' testing platform; interface 16001, 120105) · **By:** Saneroki

## TL;DR
A user interface for World of Warcraft, built in modules. Core (`SaneUI`) is the main addon; every other
module is an addon of its own (`SaneUI_<Module>`), switched on and off in the game's addon list under
*Sane UI*. One interface for both games, made for WoW: Forever first and kept compatible with Retail.

## How to use
- **Install:** `saneui installdev` builds it and puts it into both games (*Building*); by hand, copy the
  folders of `BUILD` into `World of Warcraft/_forever_/Interface/AddOns` and restart the game (Retail needs
  Core's data sets compiled for it, which `saneui installdev` does).
- **Switch modules on and off:** in the addon list, under *Sane UI*, tick or untick each module by itself.
  *Sane UI* itself must stay ticked.
- **In the game:** `/sane` says which modules are on and lists their commands. The options are under
  Esc > Options > AddOns > Sane UI: the page *Sane UI*, under it *Profiles* (its tab *Game settings*: the
  game's own per-character settings your profile keeps), *General* and *Appearance*, then a page per
  module that is switched on.
- **What changed between versions:** [Doc/changelog.txt](Doc/changelog.txt).

## The modules
| Module | What it gives you |
|---|---|
| [Core](src/Core/README.md) (`SaneUI`) | The part every module needs: game events, error catching, `/sane`, every module's settings in profiles, the options, and Sync, which keeps the game's own per-character settings in your profile. |
| [Abilities](src/Abilities/README.md) | Your spellbook also lists the spells you have not learned yet, in grey; drag one onto an action bar button to reserve it until you learn it. A Home page says what your trainer can teach you now. |
| [Auction Data](src/AuctionData/README.md) | The auction house's prices and daily history in a file of their own; no code, Core fills and reads it. Switched off, Sane UI neither scans the auction house nor shows prices. |
| [Auction Scans](src/AuctionScans/README.md) | Every full scan of the auction house, every auction in it, in a file of its own, read only when the auction house opens. |
| [Combat](src/Combat/README.md) | Frames of our own for you, your target, focus and pet, in a nameplate's look with power bars and the auras that matter; a window at the bottom middle fills the screen with our own spellbook and talents. |
| [Economy](src/Economy/README.md) | A tab *Deals* on the auction house: what to buy and what to sell right now, from the prices your full scans gather, each a click away. |
| [Guild](src/Guild/README.md) | The guild in one window on Social's full screen: the overview (who is where, news, chat), the roster and everybody's gear; the other views come later. |
| [Inventory](src/Inventory/README.md) | What you carry and wear: push the mouse into the bottom right corner and the screen fills with your character sheet, your bags and your other characters' things. |
| [Loot](src/Loot/README.md) | In place of the game's loot window and roll frames: the loot stands at the mouse, a line a thing, a click takes it; what is taken at once is yours to say; paper cards for your group's rolls. |
| [Lore](src/Lore/README.md) | Talks with NPCs as a scene: the NPC's 3D face, name and words low on the screen, straight on the world, the interface faded out meanwhile; a quest's rewards read for you. |
| [Nameplates](src/Nameplates/README.md) | The game's plates in Sane UI's dress: a round-cornered health bar with level, threat, name and health inside it, the unit's power along its bottom, your debuffs above; strangers' and critters' plates hidden. |
| [Navigation](src/Navigation/README.md) | The minimap and the world map as one window: small in the top right corner, it fills the screen as the map when the mouse pushes into that corner; drawn as *Parchment* or *Scrying*, with pins, the quest log and routes to your map pin on foot, by flight, boat, tram and portal. |
| [Social](src/Social/README.md) | A chat window in the style of a messenger: every message in a bubble, yours on the right, a line to write in; while open it stands in for the game's chat. |
| [Speed Leveling](src/SpeedLeveling/README.md) | One key for questing, pressed again and again: it loots, fights, talks, picks up or hearths, whichever is due; and your leveling guide over the world, run by Sane UI's own engine. |
| [Tooltips](src/Tooltips/README.md) | The game's tooltips drawn anew on dark round-cornered panels in the colour of what they are about; an item also shows the quests that need it, which of your characters have it and what it is worth. |

## Building
Every script runs as `saneui <command>` (`dev/saneui`; `saneui help` lists them; `dev/saneui --link` makes
`~/bin/saneui` once).

```bash
saneui installdev          # tests, builds BUILD and puts it into both games at once
saneui installrelease      # the release into both games: the tag current, or one named (installrelease v0.3.0)
saneui build               # tests and builds into BUILD only (--release TAG: a release, into BUILD/release/TAG)
saneui test                # every check and test (dev/tests/run)
saneui installed           # which build each game has
saneui update              # pull from GitHub (main, fast-forward only), then installdev
```
Then `/reload` in the game (a new file or a first install needs a game restart). Every install goes into both
games at once, Forever's `_forever_` and Retail's `_retail_`; if either folder is missing, nothing is
installed. `WOW_FOREVER` and `WOW_RETAIL` name the folders on another computer. Needed: Bash, Python 3,
`lua5.1`, `luac5.1`, `rsync`; the art is in Git LFS (`git lfs install` once, before the clone).

- **The dev build** is the default: the working tree as it is, changes not yet committed included. Its TOCs
  say `## X-SaneUI-Build: dev <commit>` (`+changes` when the tree differs from the commit).
- **A release** is a snapshot of the dev build kept in git under a version tag (`v0.3.0`, ...) on its release
  branch; the tag `current` names the newest. It is built from git's copy of the tag, never from the working
  tree, and goes into the game whole: a module it does not have leaves the game until the next `installdev`.
  Its TOCs say `release <tag> <commit>`.
- **Making a release:** `saneui snapshot 0.4.0` (`--dry` to see first) sets the version in every TOC and
  commits it on main, runs the tests on that commit, then names it: the tag `v0.4.0`, the branch
  `release/0.4`, and `current` moved to it. Nothing is pushed.
- **Stages and public packages:** every module goes through the stages dev, alpha, beta and release; dev is for
  development and testing only, and a version goes up a stage only by its developer's word (`saneui promote
  Navigation alpha`: the tag `Navigation/0.3.1-alpha`; `saneui showstages` lists them). Core has no stage.
  Each module is a CurseForge project of its own, and so is Core: a module's upload names Core's project its
  required dependency, so the CurseForge app installs Core with it. `saneui makepackage beta [Module ...]` makes
  from git a zip per addon in `BUILD/packages/`: Core's (`SaneUI-<version>-beta.zip`, from main's newest commit)
  and of each module its newest version at beta or higher (`SaneUI_<Module>-<version>-beta.zip`), a newer alpha
  or dev version left out. `saneui publish beta [Module ...]` uploads what is not on CurseForge yet, Core first,
  as betas, and tags each `published/<Module>/<version>-beta`; the players' words come from `Doc/changelog.txt`
  (a part per addon and version), the projects and the token from `~/.config/saneui/curseforge.json`. A module's
  TOC names the Core it was tested with, and Core says in chat when it is older. `saneui checkcurseforge` tries
  the token and lists CurseForge's game versions. The projects' texts, logos and CurseForge's rules: `Doc/curseforge/`.
  Packages are WoW: Forever's.
- **A new script** gets its command in `dev/saneui`; the tests fail on a script without one.

## Technical details
- **One addon per module.** Every module is `SaneUI_<Module>`, depends on Core only and is grouped under it
  in the addon list (`## Dependencies: SaneUI`, `## Group: SaneUI`); all share one global table, `SaneUI`.
  The options (`src/Core/Settings/`) and Sync (`src/Core/Sync/`) are folders of Core, no modules.
- **Core is the backend:** every data set is Core's; the modules are the views on top and gather no game
  data of their own. **Two games, one code:** what differs between Forever and Retail is told apart in the
  code or by a file's load condition in its TOC; the data and art packages per game are planned: today Core
  carries Forever's sets, Retail runs without data.
- **The build** (`BUILD`) has one addon folder per module, named after its TOC (`src/Core` becomes
  `BUILD/SaneUI`), with its textures from `assets/optimized/`, Core's data sets compiled from `assets/data/`
  and the licence, without the READMEs. A copy, not a symlink: the game runs in Steam's container, which
  cannot see `/data`.
- **Tests** (`dev/tests/run`): a lint (TOCs, syntax, stray globals, the guards) and every offline test, the
  Lua ones against a small stand-in for the client (`dev/tests/wowstub.lua`); no game needed.
- **Errors handled gracefully:** everything the game calls runs behind a guard; a caught error goes into
  Sane UI's error log (`saneui showerrors`) and the module gives the game's own part back until the next
  `/reload`.
- **Blizzard's code** is the ground truth: the project is built against the newest export of the game's
  interface code, Forever's with Retail's beside it, which is not in the repository.
- **Licence:** `LICENSE`, one for Core and every module; the build gives each addon a copy.

## Folders
| Path | What it is |
|---|---|
| `src/` | The modules, one folder each with its TOC and README; `Core/` holds `Settings/` and `Sync/` |
| `BUILD/` | Generated by `dev/build`, what is copied into the game; a release's in `BUILD/release/<tag>` |
| `dev/` | The scripts: `saneui`, `build`, `installdev`, `installrelease`, `snapshot`; `tests/` (`run`, `lint`, the tests); `tools/` (the scripts behind the commands) |
| `assets/` | The art sources and the textures made from them (`optimized/`), in Git LFS; the fonts; the data master (`data/`) |
| `Doc/guides/` | How to design and build: addon standards, Blizzard's design principles, windows, data, images, styles, game updates |
| `Doc/agent/` | The project map: every module in one table with its plan, notes and tests |
| `Doc/ideas/` | The plans of the modules |
| `Doc/KnownIssues.md` | Known issues, per module |
| `Doc/changelog.txt` | What changed, for players |
| `Doc/Changed.md` | What changed, for developers: everything |
