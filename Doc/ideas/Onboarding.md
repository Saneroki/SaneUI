# Onboarding

Planning notes for the **Onboarding** module (`SaneUI_Onboarding`; the name, Saneroki, 2026-11-15). This is
not a spec yet: it holds what Saneroki asked for (2026-10-16, 2026-11-15, 2026-11-16) and proposals for him to discuss.
Built so far: the setup, step by step, and Nameplates' (*Built*, below); Welcome, What's new and the ? not yet.

It is for **later**: Sane UI is not given to other players yet, so nobody has an old version to update
from. It is worth building once others play it, and its first real use is the first version they get.

## What it is (Saneroki, 2026-10-16)

- **A module of its own**, an addon like every other (`SaneUI_Onboarding`), depending on Core only.
- **Shipped with Core** (Saneroki, 2026-11-16: "I think we should package onboarding together with Core. So
  both onboarding and core always ships together and lives in the same curseforge project."): its folder goes
  in Core's download, the CurseForge project *SaneUI Core*, beside Sane UI; never a project, a download or a
  stage of its own. So every player of any Sane UI addon has it, as Core is every module's required
  dependency. A change to it is a change to Core: a new SaneUI Core, its words in Core's CurseForge changelog
  (`Doc/curseforge/changelogs/Core.md`).
- **Loaded on demand:** its files are read only when a **new version** of Sane UI is found, never at a
  login where nothing is new.
- **It helps players understand Sane UI's features**: a welcome the first time, and what is new after an
  update.
- **After an update, What's new opens by itself** (Saneroki, 2026-10-16), unless the player switched that off
  on the module's own settings page (*Its settings page* below).
- **A ? in the title bar** (Saneroki, 2026-10-16) of Sane UI's windows, next to the button to the game's own
  window, for help with that window. Only on our window (the Sane UI view), never on the game's own
  window (the classic view) (*The ? in the title bar* below).

## Built (2026-11-16)

Saneroki, 2026-11-16: "Each module keeps its own words, start building it for the nameplates addon. I want a window
where it goes step by step through to explain the nameplates and where people can see a live preview of a fake
nameplate in the window where they can see one and configure it to their desire." And: "Make it a step by step
window so the player goes through each step where it can see a fake nameplate in the window and see how it looks
with their setting. Each page in the window groups together similar settings or information so each page has its
own purpose."

- **Core** (`src/Core/Onboarding.lua`): `Core.Onboarding.Add(name, guide)` (a module hands in its setup: its steps
  and its `Stage`, the sample drawn into the window), `Open(name, step)` (reads the addon, out of a fight),
  `/sane setup <module>`; the first time a module with a setup is on, it opens by itself a few seconds after the
  first loading screen, after the game's own What's new, one a session, kept as shown in
  `SaneUIDB.modules.Onboarding.shown` (per account, outside the profiles).
- **The addon** `SaneUI_Onboarding` (`src/Onboarding/`, load on demand, in Core's download: `dev/tools/release`'s
  `CORE` and `CORE_PROJECT`): the window in the bronze, the module's sample at its left, the step's head, words and
  controls at its right (the module's own switches, made from their descriptions and set through `Core.Set`),
  *Back* and *Next* in red with the game's arrows as Forever's character creation has them, *Step 2 of 9*.
- **Nameplates' setup** (`src/Nameplates/Setup.lua`, `Sample.lua`): nine steps, each with its own purpose (what
  plates show; what the bar says; the border; rank and danger; spells on it; casts and damage numbers; on the bar;
  which plates show; size and transparency), sample plates drawn by the plates' own code from made-up units. New
  settings for it: *Level*, *Health*, *Health in percent*, and how many debuffs, buffs and crowd controls show.
- **Second round (Saneroki, 2026-11-16):** the loading screen's bar for the progress (the stage over the world was
  tried and taken back: "make it solid not transparent. it gets to confusing if it is transparent actually"), keys as controls (`{ binding = ... }` in a step), choices side by side; Nameplates'
  setup in his order with a first page, short lines in gold, and the plates' new settings (icon size and places,
  time left, class colours, raid markers, cast bar height, how much by distance, transparency by kind).
- **Navigation's setup (Saneroki, 2026-11-18):** "Can you make a onboarding window for the navigation module" —
  `src/Navigation/Setup.lua`, six pages: what the map is; the hot corner (the mouse into it, or a left click in it,
  the switch `expandClick` as round buttons: a step may word a switch its own way), with a very big arrow of the
  game's on the screen pointing into the player's own hot corner (Core's `edge:Spot()`); the keys for Sane UI's map
  and the game's map (once ours has a key, the game's map key opens the game's map) and the search, all of them
  together; Edit Mode moving the hot corner with the map; the quest log's click and double click; the map's double
  click and right click.
- **Tooltips' setup (Saneroki, 2026-11-18):** "a very simple onboarding for the Tooltip window where we basically
  only have Show tooltip while x held, Show at mouse cursor yes / no, 3d model yes / no, opacity slider with a life
  preview" — `src/Tooltips/Setup.lua`, one page: *Show tooltips* (always, or while a key is held), *at the mouse*
  and *3D model* as Yes or No, *Opacity*; the sample is the player's own tooltip, drawn by the panels' own code over
  Forever's loading screen, beside the game's mouse pointer or in the corner. Each module now draws into a frame of
  its own over the stage (`Window.lua`, `StageOf`).
- **Still to come:** the Welcome (one card per module), What's new after an update, the ? in the title bar and its
  help plates, the module's own options page with *Show what's new after an update*; Setup's Core questions (the
  character setup) and the other modules' setups.

## Its three parts (Saneroki, 2026-11-15)

The module is called **Onboarding** and stays load on demand. It has three parts:

- **Setup:** a guided tour through setting up and configuring Sane UI to the player's liking. It could
  grow out of the Welcome below (proposal). What it asks (Saneroki, 2026-11-15: "The tooltips, Character
  setup and other things need to be part of the onboarding"): the choices of taste a new player makes once,
  in place of a default picked for them: when tooltips show (always, or while a key is held), the character
  setup (whether characters share one setup or each keeps its own; the bars and keys), and the others the
  public release leaves to the player (chat channels, what is done for the player at vendors, bags and loot).
  Customizing itself stays on the parts: a right click on them, Edit Mode.
- **What's new:** what is new in Sane UI since the version last seen (*What's new: the words* below).
- **Tutorials:** learn about the different parts of Sane UI, one tutorial per feature: the map, the bags
  and so on.

Loaded on demand still means read only when needed: when a new version is found, and when the player opens
Setup or a tutorial. How Setup and the Tutorials look, and where they are opened from, is still open.

## When it shows (proposal)

| Moment | How Core knows | What the player sees |
| --- | --- | --- |
| **First time** | No version of Sane UI seen on this account | **Welcome:** what Sane UI is, then one card per module that is switched on |
| **Update** | Core or a module has a newer version than the one last seen, and *Show what's new after an update* is on | **What's new** in that version (and in the versions skipped since) |
| **A module switched on for the first time** | Sane UI was seen, this module never | Welcome, with only that module's card |
| **Asked for** | `/sane new` (also `/sane welcome`); a button on the module's settings page | What's new of the current version; Welcome from a button in its window |
| **The ? of a window** | A click on it | The help of that window, over it |

- A new player sees no history: Welcome, never What's new.
- Shown **once per account**, not again on each character.
- Nothing new: nothing is shown, nothing is loaded.

## Finding a new version: Core's job (proposal)

Onboarding cannot see that it is needed while it is not loaded, so Core does that part. It is a few lines
(a small file of Core's own, such as `src/Core/Seen.lua`), and costs one look per addon at login.

- **The versions:** every TOC has `## Version` (all five are `0.3.0` today). Core has its own already
  (`Core.VERSION`, `src/Core/Core.lua`); `C_AddOns.GetAddOnMetadata(addon, "Version")` gives any other
  addon's, loaded or not. Core asks for itself and every module in `Core.modules` (the ones switched on).
- **Compared as numbers,** part by part at the dots: `0.10.0` is newer than `0.9.0`.
- **Kept per account, outside the options:** `SaneUIDB.seen = { SaneUI = "0.3.0", SaneUI_Abilities =
  "0.3.0", ... }`. Not under `modules.<M>.options`: a profile, or *SaneUI Defaults*, only copies options,
  so loading one never shows the news again (`src/Core/Profiles.lua`). Like the error log, it is
  Core's own; Onboarding only asks Core to mark a version seen.
- **When:** the first `PLAYER_ENTERING_WORLD` of the session, a few seconds after the loading screen. In a
  fight it waits for `PLAYER_REGEN_ENABLED`. If the game's own What's new (`SplashFrame`) is open, ours
  waits until it closes.
- **Then** `C_AddOns.LoadAddOn("SaneUI_Onboarding")`. If it does not load (switched off in the addon list,
  not there: `LoadAddOn` returns `loaded, reason`), Core does nothing more and says nothing.
- **Switched off** (*Show what's new after an update* not ticked): Core does not load the module after an
  update; it only marks the new versions seen, so ticking it again later does not bring a pile of old
  news. The first time's Welcome still comes, as the switch is about updates.
- **Marked seen once shown,** not once read to the end: it never comes back at each login, and `/sane new`
  brings it back at any time.
- **Development:** the version only changes at a release, so Saneroki's own builds (`dev/build`) never show
  it. `/sane new` shows it to check the pages.

## The module (proposal)

- `src/Onboarding/SaneUI_Onboarding.toc` with `## LoadOnDemand: 1`, `## Dependencies: SaneUI`, category
  and group like the others, so it stands in the addon list under Sane UI and can be switched off there.
- It registers with `Core.NewModule` as every module does; one that arrives after login gets its
  `OnLoad` and `OnLogin` at once (Core already does this).
- **Stores no game data** (CLAUDE.md, *Backend and views*): `seen` is a setting, kept by Core.
- **The words live with each addon** (Saneroki, 2026-11-16: "Each module keeps its own words"; this plan said
  before that they all live in Onboarding, read only when it loads): Onboarding is the machinery (the window, Setup's steps, What's new's
  pages, the tutorials' callouts, *Show me*, how far the player got); each module carries its own words in a
  small file of its own (`Onboarding.lua` in its folder: its Setup questions, its news per version, its
  tutorial steps), handed to Core at login and only drawn by Onboarding. Core's own words (its Setup
  questions: the character setup, when tooltips show; its news) stay in Onboarding, which always ships with
  Core. Why:
  - each module is a CurseForge project of its own with its own version, so its news ships with it; all in
    Onboarding, Core's download would need a new version for every module's news, and would carry the words
    of addons the player does not have, also of those not public;
  - a tutorial names the module's own parts, which change with its code: in the same folder, the module's
    tests check that each part still exists;
  - every part explains itself where it stands (CLAUDE.md).

  The cost: a few kilobytes of text per module at login; the window, its art and its drawing stay unloaded.
  Keeping a module's words load on demand too would take a second addon per module in the addon list.

### Its settings page (Saneroki, 2026-10-16: the switch is on it; how, a proposal)

- **A page of its own,** under Sane UI, titled by the module's name, like every module's: the switch
  **Show what's new after an update** (on), and buttons *What's new* and *Welcome* to open them now.
- **Put up by Core:** pages are put up at login, empty, before a load-on-demand addon is there, and a page
  put up later is lost for the session (`src/Core/Settings/Settings.lua`, `PutUpPages`;
  `Doc/guides/gui-development.md`). So Core describes the module's switch itself (it reads it at login,
  before the module loads, as it does for Sync's) and puts up its page when the addon is switched on in the
  addon list (`C_AddOns.GetAddOnEnableState`). Its controls are made when the options first open, as on
  every page. A small addition to `PutUpPages`, which today only puts up pages of loaded modules.

Files (proposal):

| File | What it holds |
| --- | --- |
| `SaneUI_Onboarding.toc` | The addon, `LoadOnDemand` |
| `Onboarding.lua` | What to show (Welcome, which versions), the slash commands |
| `Window.lua` | The window and its pages, made the first time it is shown |
| `Welcome.lua` | One card per module: its few key features, each with *Show me* |
| `News.lua` | What's new, one entry per version, newest first |
| `Help.lua` | The help of each window, for its ? (*The ? in the title bar* below) |
| `Art/` | The pictures, made as `Doc/guides/images.md` says |
| `README.md` | As every module has |

With *The words live with each addon* above, `Welcome.lua`, `News.lua` and `Help.lua` hold Core's words
alone; each module's stand in its own `Onboarding.lua`, in the same shape.

## What's new: the words (proposal)

`Doc/changelog.txt` is already *Sane UI: what is new*, the bigger changes of each version in plain
words. `News.lua` takes its features, shorter, and adds what a window needs and a text file does not
have: the module, a picture, and what *Show me* does.

```lua
ns.News["0.3.0"] = {
    date = "2026-10-14",
    { module = "Social", title = "Smileys and emotes",
      text = "A smiley at the end of the line you write in: raid marks and the emotes played most.",
      picture = "Smiley", show = { window = "Social", help = "smiley" } },
    { module = "Core", title = "Round corners",
      text = "Sane UI's windows have round corners and a bronze trim.",
      show = { options = "Appearance" } },
}
```

- **Written by hand,** not made from `changelog.txt` by a tool: the picture and *Show me* have to be
  chosen anyway.
- **A test keeps both in step:** every version in `changelog.txt` (from Onboarding's first one on) has an
  entry in `News.lua`, and so does the version in the TOCs. A release without its news fails the build.
- **Only the modules switched on:** a feature of Social is not shown to a player without Social.

## The window (proposal)

- **A Sane UI window** (`Core.Window.New`, `Doc/guides/windows.md`): skinned, in the middle (`CENTER`),
  with a title bar (*What's new*, *Welcome*), Esc closes it (`escape = "close"`). It stands for no game
  window. It never blocks the game: the player can move and play while it is open.
- **Laid out like Blizzard's own What's new** (`SplashFrame`,
  `Blizzard_SplashFrame/Mainline/SplashFrame.xml`): a header with the version, three features (one large,
  two small), each a picture, a title and a few lines, and a close button at the bottom. More than three:
  pages, turned by Blizzard's `PagingControlsHorizontalTemplate` (`Blizzard_PagedContent`). Sounds as the
  splash plays them (`SOUNDKIT.IG_MAINMENU_OPEN`, `IG_MAINMENU_QUIT`).
- **Versions skipped:** each one its pages, newest first.
- **Show me** on every feature: opens the thing (its window, the spellbook) and shows its help (*The ? in
  the title bar*), or opens the options at the page of its switch. The last needs a small addition to Core: `Config.Open`
  only opens the top page today; it would take a page (`Settings.OpenToCategory(Core.pages[name]:GetID())`).
- **Welcome:** the same window. One card per module switched on: its icon and its words come from its TOC
  (`IconTexture`, `Notes`: written for players already), then its key features from `Welcome.lua`, each
  with *Show me*. Modules installed but switched off get one line: where to switch them on.
- **Pictures:** a game icon or atlas where one says it; an own picture or screenshot only for the large
  feature. They are only read when the window shows, so they cost disk, not memory.

## The ? in the title bar (Saneroki, 2026-10-16; how, a proposal)

Help comes when the player asks for it, on the window it is about. No tips pop up by themselves at the
first meeting with a window.

- **Where:** at the right end of the title bar, left of the button to the game's own window:
  **[?] [the game's own window] [full screen / back] [X close]**. A window that stands for no game window
  has it left of its full screen button. The title bar is Core's, so every Sane UI window gets it the same
  way: Core makes it with the other buttons (`Buttons` in `src/Core/Window.lua`).
- **Only in the Sane UI view:** on our window, small or full screen. Not on the game's own window, where
  only the button back to ours stands (`window:Attach()`). Not in Edit Mode, where the title bar has no
  buttons.
- **Only where there is help:** a window shows it when it has help (a new window option, `help = "<key>"`,
  its page in `Help.lua`) and the Onboarding addon is switched on in the addon list. Otherwise there is no
  ?, and no gap where it would be.
- **Already on every full screen (Saneroki, 2026-10-21):** Core puts the ? in each full screen's title bar now,
  left of the options' cog, doing nothing yet; later it shows a tour of that view or information about it. Its
  click calls the window's option `help` (a function, `Window.lua`), the seam this module plugs into (loading
  itself, then the window's help plates); a full screen without `help` keeps the ? and its tooltip says the
  tour is not ready yet.
- **A click** loads Onboarding if it is not loaded yet (`C_AddOns.LoadAddOn`), then shows the window's help
  over it. A second click, Esc or closing the window hides it. Nothing is loaded until the first click.
- **Blizzard's help plates** (`Blizzard_HelpPlate`): the window's parts each in a box with a button; the
  mouse on one tells what that part does. Our windows are sized by the player, so the boxes are measured
  from the window's parts at the click, as Blizzard's spellbook does
  (`SpellBookFrameTutorialsMixin:UpdateHelpPlates`). Below them a line to the module's Welcome card and its
  What's new.
- **This client hides Blizzard's own ?:** on WoW: Forever every `MainHelpPlateButton` hides itself when
  shown (`Blizzard_HelpPlate/Camelot/HelpPlateOverrides.lua`). So our ? is a title bar button of our own,
  the size of the others (`Window.BUTTON`); its look is chosen with them in the GUI work (Blizzard's own
  help button shows an *i*, `Interface\common\help-i`). The help plates themselves are not changed by the
  override and work.
- **The game's tutorial switch does not stop it:** the player asked for it. `HelpPlate.Show` does not look
  at the CVar `hideHelptips`; `HelpTip:Show` does, and would show nothing. So the help plates, not
  `HelpTip`, and nothing to keep as seen.
- **Out of a fight only** at first (the ? greyed in a fight), until it is tried that loading the module and
  showing Blizzard's plates there brings no taint.
- **Show me** uses the same help: it opens the window and shows its plates, with the feature's box first.

## Rules it keeps

- **Resilience:** if any part fails (`Core.Safe`), the window is not shown and the game goes on untouched;
  the failure goes to Core's error log. Nothing of the game's own UI is changed by this module.
- **Quiet:** at most one window per session, never in a fight, never over the game's own splash.

## Tests (proposal)

`dev/tests/onboarding.lua`: the version comparison; what Core decides (first time, update, versions
skipped, a module newly on, nothing new, Onboarding switched off in the addon list, *Show what's new after
an update* off: nothing loaded, the versions marked seen); `seen` not touched by loading a profile; the
module's page put up at login only when the addon is switched on; the ? only with help and the addon on,
on our window small and full, not on the game's window, not in Edit Mode; the news test above; every
`show` and `help` names a window, page or help that exists.

## Order of work (proposal)

1. **Core:** `SaneUIDB.seen`, the comparison, the load after login, `/sane new`, the module's page with its
   switch; tests. Onboarding at first only prints a chat line with the version. In `dev/tools/release`,
   Onboarding goes into `CORE` and `CORE_PROJECT`, and its folder counts with Core's in `core_tree` (a
   change to it, a new SaneUI Core).
2. **The window** with What's new and its pages.
3. **Welcome,** with the cards from the TOCs.
4. **The ? and Show me:** the window option `help` and the ? in Core's title bar, the help plates in
   Onboarding, `Config.Open` to a page.

## Open questions for Saneroki

1. **The name** in the addon list. A module is titled by its plain name: *Onboarding* is a developer's
   word. Proposal: *What's New*. (*Guide* is taken by Navigation's leveling guides.)
2. **The first time:** the Welcome window, or only a chat line? Proposal: the window: the first login is
   when a new player is lost.
3. **Screenshots:** worth their disk space, and for which features?
4. **Per account** (proposal) **or per character:** should an alt see Welcome again?

Answered (Saneroki, 2026-10-16): after an update the window opens by itself unless its switch is off (was
question 2); help comes from a ? in the title bar, in the Sane UI view only, instead of tips at the first
meeting (was question 4). Answered (Saneroki, 2026-11-15): the module is called *Onboarding* (was question 1).
Decided (Saneroki, 2026-11-16): Onboarding ships with Core, in Core's CurseForge project (*What it is*); each module
keeps its own words (*The module*).
