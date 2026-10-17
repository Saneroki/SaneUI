# Sane UI: Settings (part of Core)

**Status:** written and tested outside the game · **Since:** 2026-10-14 · **Addon:** `SaneUI` (Core), folder `src/Core/Settings/`

## TL;DR
Shows the switches of Sane UI in the game's own options: the page *Sane UI* with its logo, under it *Profiles*
(with the synced game settings and every CVar of the game), *General* and *Appearance*, then one page for
every module that is switched on.
Checkboxes, sliders for numbers, boxes to type words or a number into, dropdowns for one of a few (or several,
ticked), colours, buttons, and a list of the CVars. A module's page in tabs has a search box and *Defaults*.

## How to use
- **Open the options:** Esc > Options > AddOns > Sane UI, or `/sane options`, or click *Sane UI* in
  the minimap's addon list. In a fight the game does not let an addon open its options: chat says so, and
  they open by themselves once the fight is over.
- **Sane UI** itself shows only Sane UI's logo. Under it, in this order (the button in front of *Sane UI* folds
  them in and out):
  - *Profiles:* a page of its own: its title, the line *Profiles keep the settings of Sane UI and of the
    game...*, and tabs, each with titled boxes (Saneroki, 2026-10-17):
    - *Profiles:*
      - *Accountwide*: *Accountwide settings* (on at first) and what it means. On, every character uses a
        profile, Sane UI's settings and the game's; off, each character keeps its own Sane UI settings and the
        game's are left to the game. Switching it on asks first (the character takes its profile's settings).
      - *This character*: the profile it uses (a dropdown: choosing one uses it at once), the buttons *New*
        (asks for a name: a copy of the settings in use, used from then on), *Rename*, *Delete* (asks first;
        the characters that had it use *Accountwide*), *Defaults* (asks first: Sane UI's settings of the
        profile in use back to their defaults), then *Copy from* (a dropdown of the other profiles; asks
        first), *Export* (a window with the profile as a line of text, selected to copy) and *Import* (the same
        window, empty: paste, *Import*, a name). *Accountwide* cannot be renamed or deleted. Chat says what was
        done, and why a name was refused.
      - *Characters*: first *New Characters*, the profile a character not seen yet starts with; then every
        character seen on the account, this one marked, each with its profile (a dropdown) and, but this one,
        *Forget* (asks first). Everything here is switched off while *Accountwide settings* is off.
    - *Game settings:* which of the game's settings the profiles keep: a box per group of Sync's parts
      (`Sync.GROUPS`: the game's own options groups, then *Elsewhere in the game*), checkboxes in two columns,
      kept per profile. All ticked at first; switched off while *Accountwide settings* is off.
    - *CVars:* *Every console setting of the game. Enter sets a typed value; a tick keeps the CVar with Sane
      UI's settings.* Every CVar of the game in one list, to look up, change and keep:
      - Over the list a search box (a CVar's name, or the label the game's own options give it) and the game's
        filter button: *Not at their default*, *Kept with Sane UI*, and one *Kind* (Game, Graphics, Sound,
        Combat, Network, Other; *Every kind* at first). While a filter is set the button has its red cross,
        which clears them all.
      - Each row, two lines high: a tick to keep it with Sane UI's settings (by Sync: the same on every
        character, and in profiles); its name, and under it its label; at the right its value in a box: type
        a new one and press Enter (Esc, or clicking elsewhere, leaves it as it was). While it is not at its
        default the game's undo arrow stands beside it: a click gives it the default back. One the game does not
        let change cannot be typed into; a secure one is not changed in a fight.
      - The mouse on a row tells what it does, its default, where the game keeps it (for the character, the
        account, or on this computer) and what cannot be done with it.
      - Under the list: why the last change did not take (the game keeps another value, or will not change it
        now), and how many CVars are listed (*5 CVars*, or *1 matching* while searching or filtering).
  - *General:* the switches of no module (*Errors in chat*).
  - *Appearance:* the look of Sane UI as a whole. *Windows: Animation type* (Glide at first; Swing, Even,
    Instant): how a window docked to a screen edge grows to fill the screen when you push the mouse against that
    edge, and goes back; also how a window opens while the mouse rests on it. A window can have its own (Social).
  - *Social*, *Abilities*, *Tooltips*: one page per module that is switched on and has switches, called by its
    name, with the module's banner at the top in place of its title. A module that is switched off in the
    addon list has no page. A module whose switches are in tabs (*Social*) has over its tabs, at the right of
    its title, a search box and the button *Defaults*:
    - **Search:** type a few letters of a setting's words (or of its tab, its box or its tooltip): the settings
      found are listed under the box, best first, the letters found in gold, each with its tab and box. Click
      one, or press Enter for the first: its tab is shown, scrolled to it, its line marked. Esc closes the list.
    - **Defaults:** asks first, then sets every setting of the module back to its default, in all its tabs.
      The game's own *Defaults* button (on a list page) with *All settings* does the same for such a page.
- A change counts at once. One the game shows only after a `/reload` offers it (the game's dialog: *Reload*,
  *Later*).
- Words or a number in a box: Enter sets what was typed, Esc (or a click elsewhere) leaves the value as it was.
  A number is kept within its ends; words the module refuses get the default back.

## Technical details
- **Part of Core,** not a module: its files are in Core's TOC, after Sync, and share `Core.Config` (called
  `Config` in them: `Settings` is the game's own options library). It cannot be switched off.
- **The pages are put up at login, empty** (`Core.pages`, `PutUpPages` at `PLAYER_LOGIN`): the game's options
  window shows its *AddOns* tab only if an addon has a page the first time it opens, and decides that for the
  whole session. The rows of the game's lists are handed to it the first time the options open (`Config.Fill`,
  from the options window's `OnShow` or `/sane options`; the game makes their frames only when a page is
  shown). A page of our own (a canvas: *Profiles*, a module's page in tabs) is an empty frame until the game
  first shows it: then it is built (its `OnShow`, `OwnPage`). So a session that never opens the options builds
  no frame, and one that opens only the game's own pages (*Graphics*) builds none of ours. A module whose
  switches fail to go on its page does not keep the others from theirs.
- **`/sane options`** (`config`, `settings`) and the minimap's addon list (`## AddonCompartmentFunc` in Core's
  TOC: `SaneUI_OnAddonCompartmentClick`) open the options (`Config.Open`); in a fight once it is over
  (`Core.AfterCombat("options", Config.Open)`: asked twice, it opens once).
- **The pages, in this order** (`Config.Fill`):
  - *Sane UI* (`Core.pages.top`): the banner, then `About.lua`'s rows (the game's section headers and button
    rows): *Community* (Discord, Website, GitHub: *Copy link* shows the address selected in the game's
    `GENERIC_INPUT_BOX`; an address left empty in `About.LINKS` shows *Coming soon*, its button off) and
    *Feedback* (*Report a bug*, *Suggest a feature*, *General feedback*: each opens the feedback window).
    An addon can open no web page, copy nothing to the clipboard (`CopyToClipboard` is the game's own) and
    send nothing out of the game, so the player copies with Ctrl+C.
- **The feedback window** (`About.lua`, `SaneUIFeedbackFrame`, made when first opened; also `/sane feedback`
  [`bug`|`idea`|`note`], `/sane bug`): a `ButtonFrameTemplate` over the options (strata DIALOG), Esc closes
  it, with the kind's question and an `InputScrollFrameTemplate` box. *Make report* puts the report in the
  box, selected to copy (`About.Report`: Sane UI's version, the game's version, build and language, the
  modules switched on, the class and level but no name, what was written, and for a bug the 5 newest
  entries of Core's error log); *Back to writing* returns. What was written is kept per kind for the
  session, not saved.
  - *Profiles*: a page of our own (a canvas, `Core.frames.Profiles`), built by `Config.BuildProfiles` the first
    time it is shown: the title over the game's divider, a line, the tabs (`MinimalTabTemplate`, the options
    window's own tabs, in a radio group), and under them a box with one part per tab, each but *CVars* in a
    scroll area (`ScrollFrameTemplate`, the game's thin scroll bar). Tabs: *Profiles* (`Profiles.lua`), *Game
    settings* (`Synced.lua`: Sync's parts by `Sync.GROUPS`, a box each), *CVars* (`CVars.lua`). A character's
    line in *Characters* has its own dropdown and a button *Forget*.
  - **The parts of such a page** (`Panel.lua`): the tabs over their box (`Panel.TabbedFrame(page, tabs, top)`:
    each tab `{ name, build, scroll, label }`, its part in a scroll area unless `scroll = false`), titled boxes
    (`BackdropTemplate` with the tooltip border, as boxes in the game's options have had; a box's tip is the
    tooltip of its title), checkboxes (`UICheckButtonTemplate`) in two columns, sliders, dropdowns of one or
    several (`WowStyle1DropdownTemplate`; several: a checkbox each), boxes to type words or a number into
    (`InputBoxTemplate`), colours, buttons (`UIPanelButtonTemplate`). Each control reads its value from a
    function and is kept by its page (`Panel.Page`): a click shows its own page anew; the game's `OnRefresh`
    shows a page anew when it shows it; `Config.Refresh` shows anew the pages shown then, and a hidden one once
    it is shown. One that cannot be used now is switched off with grey words.
  - *General* and *Appearance*: Core's switches, each on the page its `page` names (`Fill(page, name, onPage)`;
    none: *General*).
  - A module's page, called by its name (*Abilities*).
- **The banners:** at the top of a page, in place of its title, the banner of the addon it belongs to:
  `Interface\AddOns\<addon>\Art\banner` (a module may ship its own; the page *Sane UI* has Sane UI's, which
  is Core's; Abilities and Social ship none, their pages keep the game's title). It is a row of the game's own list (`Settings.CreateElementInitializer` with
  `SaneUISettingsBannerTemplate` from `Banner.xml`), so the game makes it only when the page is shown and
  lets it go when another page is shown or it is scrolled out of sight; the game's title of the page is
  hidden (alpha 0) only for that long. An addon without a banner gets none (`SetTexture` says whether the
  game found the file, as Blizzard's own `LFGFrame.lua` asks it), and its page keeps the game's title.
  The banners are BLP2 with DXT5 and mipmaps, 1024 x 256 for a 4K screen, drawn at 300 x 100 (3 : 1) from
  the file's left 768 texels (`BANNER_RIGHT`), with the game's own filter; read from disk only when their
  page is opened. Made from the drawings in `assets/` by `dev/tools/art`
  ([the images guide](../../../Doc/guides/images.md)).
- **It only shows.** The switches are described by their modules and kept by Core
  (`Core.Options`, `Core.Store`; see [Core's README](../README.md)). The pages are filled from Core's list when
  the options first open, long after every addon that is switched on has been read. So a module needs nothing
  from the options, and the order in which the game reads the addons does not matter.
- **The pages are Blizzard's** vertical settings lists: `Settings.RegisterVerticalLayoutCategory` for
  *Sane UI*, `Settings.RegisterVerticalLayoutSubcategory` for each module, `Settings.RegisterProxySetting` for a
  switch (it reads the module's settings, `Core.Settings`, and writes them through `Core.Set`: checked, told to
  the module, a `/reload` offered for `reload = true`, the page shown anew); the game makes the controls only
  when a page is opened. *Profiles* and a module's page in tabs are pages of our own
  (`Settings.RegisterCanvasLayoutSubcategory`), built from the game's parts the first time they are shown.
  The game's search (`SettingsPanelMixin:FindInitializersMatchingSearchText`) reads only vertical lists, so a
  page in tabs has a search of its own.
- **Rows go in through `Settings.RegisterInitializer`,** which lets the game's own code put them on the
  page. `Settings.CreateCheckbox` would add them from addon code, and the options' search reads every page.
- **The name:** the table is `Core.Config`; inside these files it is called `Config`, because `Settings` is
  the game's own options library.
- **Profiles (`Profiles.lua`):** only shown here; Core keeps them and does the work (`Core.Profiles`, see
  [Core's README](../README.md)).
  - Names and every question go through the dialogs the game keeps for addons (`Core.AskText`,
    `Core.Confirm`: `GENERIC_INPUT_BOX`, `GENERIC_CONFIRMATION` with `StaticPopup_Show`): nothing is written
    into the game's `StaticPopupDialogs`. Should a client update take one away, it is noted and nothing happens.
  - Export and import show a window of ours (`SaneUIProfileText`, `ButtonFrameTemplate` with an
    `InputScrollFrameTemplate` box; Esc closes it): the text of `Core.Profiles.Export`, or a box to paste into.
  - **Shown anew:** when values change under the controls (another profile used, Accountwide switched, a
    switch set elsewhere with `Core.Set`), `Config.Refresh`, a frame later, asks each setting of the list pages
    to show its value again (`SettingMixin:NotifyUpdate`, what the game does for a value changed elsewhere) and
    the pages of our own to show theirs (`Panel.Refresh`). The settings only read their values then: nothing is
    told to the modules twice (Core told them). A list page that is not open makes its controls anew when it is.
- **Kinds of switches** (`Config.Kind`, from the description `Core.Options` keeps; the same on a list page and a
  page in tabs):

  | Description | Control |
  | --- | --- |
  | no `text` (or no `default`, or a table that is no `multi`) | none: kept with the settings, in profiles too |
  | `default` true or false | a checkbox |
  | a number with `min` and `max` (`step`, `unit`) | a slider, its value written right of it: two decimals for steps below 1, then `unit` |
  | a number with `entry = true`, or without `max` | a box to type it into (Enter sets, Esc leaves it), kept within `min`/`max`, on its `step`; `unit` beside it |
  | words (a string `default`, no `choices`) | a box to type them into (Enter sets, Esc leaves it); a `validate` that refuses them gives the default back |
  | `choices` (`{ value, words }`) | a dropdown of one of them |
  | `choices` with `multi = true` (`default` a table `{ [value] = true }`) | a dropdown with a checkbox per choice; on a list page the game's own (a setting with a bit per choice) |
  | `color = true` (six hex digits) | a swatch that opens the game's colour picker (on a list page the game's own swatch row) |
  | `button = fn` (no `default`) | a button that runs it; nothing is kept |

  Besides: `header` (and `headerTip`, its tooltip) starts a section (a list page) or a titled box (in tabs).
  `parent` (a key, or a list of keys) draws it under that switch and greys it out while any switch above it is
  off, a parent's parent too (`Config.Free`); `parentValue` while the first parent is not set to that value.
  On a list page it is drawn under the first parent on the page (`SetParentInitializer`, indented, as the
  game's own options do); the game looks at a row again only when that one changes, so the row also listens to
  every other switch above it (`AddEvaluateStateCVar`, by a setting's name). `hidden = fn(settings)`: the
  control is not there while it returns true (a list page: `AddShownPredicate`, the game asks after every
  change and closes the gap; in tabs the lines under it close up when the page shows its values anew).
  `reload = true`: a change offers a `/reload` (`Core.Set`). `validate`: `Core.Set` gives the default for a value
  it refuses. On a list page the words and number boxes are a row of ours (`SaneUISettingsEntryTemplate` in
  `Banner.xml`, `SaneUISettingsEntryMixin`): the game's own row of a setting (`SettingsControlMixin`, its words,
  tooltip, greying and *Defaults*) with the game's `InputBoxTemplate`; a button is the game's
  `CreateSettingsButtonInitializer`, a colour its `CreateColorSwatchInitializer` (it keeps `FF` in front).
- **A module's page in tabs** (`Tabbed.lua`): when a module's switches name a `tab`, its page is one of our
  own (a canvas, `Core.frames[module]`), built the first time it is shown, drawn as Profiles is
  (`Panel.TabbedFrame`): the title, the game's tabs (*General* first, for the switches that name none; a tab
  without a control is none), each a scroll area of titled boxes, one per `header` (an empty one is not drawn).
  A line is a checkbox, or words with its control in a column right of them: a slider (`Panel.Slider`: the
  game's `MinimalSliderWithSteppersTemplate`, its value and `unit` at its right), a dropdown (`Panel.Dropdown`),
  a box to type into (`Panel.Edit`), a colour (`Panel.Color`, the game's `ColorSwatchTemplate`; a click opens the
  game's `ColorPickerFrame`, each move there is set at once, Cancel sets the one before); or a button. A number
  with `inline` is drawn on the line of its parent switch (the first of a list) when that is a checkbox of the
  same tab, one number per checkbox; any other on a line of its own.
  - **Over the tabs:** a search box (`SearchBoxTemplate`) and *Defaults* (`SETTINGS_DEFAULTS`, where the game's
    list pages have theirs). The search ranks every setting of the page at every key with `Core.Fuzzy`: its
    words in any of Fuzzy's ways, or else the start of a word of its tab, box title or tooltip (300 lower); a
    setting hidden now is not found. Up to 8 are listed under the box in the look of the game's search
    suggestions (`search-highlight`), the letters found in gold (`Fuzzy.Highlight`), with tab and box; *Nothing
    found* (`SETTINGS_SEARCH_NOTHING_FOUND`) if none. A choice selects its tab, scrolls to its line and marks it
    (until the words change or the lines move). *Defaults* asks with `Core.Confirm`, then `Core.Reset(module)`;
    the page's `OnDefault` (`Settings.lua`, set when the page is put up) does it for the game's *All settings*.
- **The CVar list (`CVars.lua`, `CVars.xml`):**
  - One frame filling the tab *CVars* (`SaneUISettingsCVarsTemplate`), with a scroll box of its own, built in
    its `OnLoad` from the game's parts: `SearchBoxTemplate`, `WowStyle1FilterDropdownTemplate` (checkboxes and
    radios; `SetIsDefaultCallback`, `SetDefaultCallback` for its red cross), `WowScrollBoxList` with
    `MinimalScrollBar` and a linear view of `SaneUISettingsCVarRowTemplate` rows (`UICheckButtonTemplate`,
    `InputBoxTemplate`, a button with the atlas `common-icon-undo`).
  - It is made the first time the tab is shown (the page's other tabs do not need it), filled each time the
    tab is shown and let go when it is hidden: what was searched and filtered is kept in the file (`filters`),
    not on the frame. The search box tells of every `SetText` too (the list's own, writing back what was
    searched; its clear button's): the list is filtered anew only when the words differ from those it was
    filtered by. A row sets every field (rows are used again); what is being typed into a row stays while it
    shows the same CVar (a CVar changed elsewhere does not overwrite it).
  - The CVars come from the game (`ConsoleGetAllCommands`, those of `Enum.ConsoleCommandType.Cvar`, once each
    whatever the case of their letters; their kind from `Enum.ConsoleCategory`), when the list is first shown; their values from `C_CVar.GetCVarInfo`, which also says the
    default, where the game keeps it, and whether it is locked, secure or read-only. Search waits 0.15 s after
    the last key. A CVar changed elsewhere (`CVAR_UPDATE`) is shown anew.
  - Setting one: `C_CVar.SetCVar`, then read back; not when it is read-only or locked, nor a secure one in a
    fight.
  - **Labels** (`Data/CVarLabels.lua`, written by `dev/tools/cvar-labels`; `--check` says whether it is up to
    date): for the CVars the game's own options show, `{ label = , tip = }` with the *names* of the game's
    strings, read from Blizzard's options code in `references/` (`Settings.SetupCVarCheckbox/Slider/Dropdown`,
    `RegisterCVarSetting`). The text is looked up in the game, in its language; a string this client lacks is
    left out.
  - Keeping one is Sync's (`Core.Sync.Keep`).
- **Globals:** `SaneUI_OnAddonCompartmentClick`, `SaneUISettingsBannerMixin`, `SaneUISettingsEntryMixin`, `SaneUIFeedbackFrame`,
  `SaneUISettingsCVarsMixin`, `SaneUISettingsCVarRowMixin` (the templates' mixins: XML
  finds it by name).
- **Tests:** `lua5.1 dev/tests/core.lua` (Core with its options, 317 checks; two modules only its options
  tests see, one with a switch of every kind on a list page, one in tabs); Sync's sections in
  `dev/tests/sync.lua`, the page Social in `dev/tests/social.lua`.

## Files
| File | What it is |
|---|---|
| `Settings.lua` | The pages (put up at login; the lists filled when the options first open, a page of our own built when first shown), the kinds of switches and their rows on the game's lists, the row to type into, the banners, `/sane options` |
| `Panel.lua` | The parts of a page of our own: header, tabs over their box, scroll area, titled boxes, checkboxes, sliders, dropdowns (one or several), boxes to type into, colours, buttons; each page's controls shown anew together |
| `Tabbed.lua` | A module's page in tabs, drawn from its switches' descriptions (`tab`, `header`, `headerTip`, `parent`, `parentValue`, `inline`, `unit`, `hidden`, the kinds), its search and *Defaults* |
| `Profiles.lua` | The page *Profiles*: its tabs, the tab *Profiles*, the export/import window |
| `Synced.lua` | The tab *Game settings*: Sync's parts, kept per profile |
| `CVars.lua` | The tab *CVars* on the page *Profiles*: the list of the game's CVars |
| `CVars.xml` | The list's frame, and one CVar's row in it |
| `Data/CVarLabels.lua` | The names of the game's strings for the CVars its options show; made by `dev/tools/cvar-labels` |
| `About.lua` | The page *Sane UI* under its banner: the links (`About.LINKS`), the feedback buttons, the feedback window and its report, `/sane feedback` |
| `Banner.xml` | Our rows in the game's lists: the one a banner is drawn in (its height, the art's size and place), and the one to type into |

Sane UI's banner, for the page *Sane UI*, is Core's: `src/Core/Art/banner.blp` (original art of Sane UI, see
the project's `LICENSE`; made by `dev/tools/art` from `assets/SaneUI-banner.png`).

## History

- 2026-10-17 — The page *Profiles* anew (Saneroki): *Accountwide settings*; *This character* with its profile and *New*, *Rename*, *Delete*, *Defaults*, *Copy from*, *Export*, *Import*; *Characters* with a profile each and *Forget*. *Load*, *Save*, *Duplicate*, *Load at login*, *Save at logout*, *Empty* and *SaneUI Defaults* are gone. The tab *Accountwide* is *Game settings*, without the box of modules.
- 2026-10-17 — Every kind of switch on both kinds of page: words and numbers typed into a box (`entry`), several
  of a few in a dropdown of checkboxes (`multi`), a button (`button`), a colour on a list page too; `hidden`
  takes a control away while it says so. Every change goes through `Core.Set` (checked, a `/reload` offered,
  the page shown anew). A list page's row under two switches, or under one two steps up, is greyed out as soon
  as any of them changes. A module's page in tabs: a search box and *Defaults*, `headerTip` as its box's tooltip,
  the game's *All settings* reaches it (`OnDefault`); a number inline whose switch is no checkbox of its tab is
  on a line of its own (was: not drawn, or the tab empty). Pages of our own are built when first shown (was: when
  the options opened), each click shows only its own page anew, the CVar list is made when its tab is first
  shown and filtered once per showing (was: twice). `/sane options` in a fight opens the options once it is over.
- 2026-10-15 — *Empty* in the profile lists, chosen at first (was *None* on a character's line): with it a
  line's checkboxes are ticked and switched off.
- 2026-10-15 — Part of Core (`src/Core/Settings/`), no addon of its own: the pages are put up here at login (was
  Core.lua), their controls made when the options first open (`Config.Fill`, was `Config.OnLogin` of the
  load-on-demand addon `SaneUI_Settings`). `Core.Config`; `Core.LoadSettings` is gone. The banner is Core's.
  The CVar list always has its ticks and *Kept*, the tab *Accountwide* always Sync's boxes.
- 2026-10-15 — *Characters*: a first line *New Characters*, for characters not seen yet.
- 2026-10-15 — The profile *SaneUI Defaults*, always first in the list: *Rename* and *Delete* are switched off
  for it, *Save* offers no name, and *Save at logout* is switched off for a character that has it.
- 2026-10-15 — The page *Appearance* has Core's switch *Animation type* (was a line saying there is nothing to
  set yet; `Note.xml` is gone).
- 2026-10-14 — The tab *Chat channels* is gone from the page *Profiles*: the game's channels are on the page
  *Chat* now (the Chat module's switches, the game's own dropdowns).
- 2026-10-14 — The tab *Profiles*: *All settings accountwide*, and a list of every character with its profile,
  *Load at login* and *Save at logout*. The tab *Sync settings* is now *Accountwide*, with a box *Sane UI*
  for the modules.
- 2026-10-14 — The page *Profiles* is a page of our own with tabs (*Profiles*, *Sync settings*, *Chat
  channels*, *CVars*) and titled boxes; a line says settings are saved account
  wide by default, and one over the CVar list what its ticks do.
- 2026-10-14 — The pages: *Sane UI* shows only its banner; under it *Profiles* (profiles, the Sync module's
  sections, CVars), *General*, *Appearance* (nothing yet), then the modules' pages by their plain names.
- 2026-10-14 — The general page: *Load at login* and *Save at logout* under the profile; the Sync module's
  sections; the section *CVars*, a list of every CVar of the game to find, change and keep.
- 2026-10-14 — Profiles: the section *Profiles* on the general page, with *Character specific settings*, a
  dropdown of the profiles and the buttons *Load*, *Save*, *Duplicate*, *Rename*, *Delete*.
- 2026-10-14 — Banners: each page shows the banner of its module at the top in place of its title;
  the general page Sane UI's, above *General*.
- 2026-10-14 — Fills the pages Core puts up at login, instead of making them when it is read: the
  game's options had lost their *AddOns* tab when Sane UI was the only addon with options.
- 2026-10-14 — 0.3.0: loaded on demand; called *Settings* in the addon list; a module's page is called
  *Sane* and its name. `/sane options` moved to Core.
- 2026-10-14 — 0.2.0: an addon of its own. A general page with one page per module under it (was: one
  page with a heading per module). Keeping the saved settings moved to Core.
- 2026-10-14 — First version (Sane UI 0.1.0).
