# Onboarding

Planning notes for the **Onboarding** module (`SaneUI_Onboarding`, working name). This is not a spec yet: it
holds what Saneroki asked for (2026-10-16) and proposals for him to discuss. Nothing is built.

It is for **later**: Sane UI is not given to other players yet, so nobody has an old version to update
from. It is worth building once others play it, and its first real use is the first version they get.

## What it is (Saneroki, 2026-10-16)

- **A module of its own**, an addon like every other (`SaneUI_Onboarding`), depending on Core only.
- **Loaded on demand:** its files are read only when a **new version** of Sane UI is found, never at a
  login where nothing is new.
- **It helps players understand Sane UI's features**: a welcome the first time, and what is new after an
  update.
- **After an update, What's new opens by itself** (Saneroki, 2026-10-16), unless the player switched that off
  on the module's own settings page (*Its settings page* below).
- **A ? in the title bar** (Saneroki, 2026-10-16) of Sane UI's windows, next to the button to the game's own
  window, for help with that window. Only on our window (the Sane UI view), never on the game's own
  window (the classic view) (*The ? in the title bar* below).

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
- **The words live in the module,** not in the others: everything it shows is read only when it loads, so
  no module carries pages of help at every login.

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
   switch; tests. Onboarding at first only prints a chat line with the version.
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
meeting (was question 4).
