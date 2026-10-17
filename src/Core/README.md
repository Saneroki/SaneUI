# Sane UI: Core

**Status:** written and tested outside the game; the split into several addons is **not yet tried in the game** · **Since:** 2026-10-14 · **Addon:** `SaneUI`

## TL;DR
The main addon, the one every module needs: chat lines, game events, error catching, the list of modules,
the `/sane` command, the saved settings of all modules (the account's, or a character's own, and profiles
of them), Sane UI's options (`Settings/`), Sync, which keeps the game's own per-character settings with
Sane UI's (`Sync/`), and what every window can use: moving, sizing,
docking to a screen edge, round corners, opening while the mouse rests on it, filling the screen, and
a progress bar. It does nothing you can see by itself, but for a
window to try those with (`/sane window`).

## How to use
- **In the addon list** it is the line *Sane UI*. The modules stand under it (*Social*,
  *Abilities*, *Tooltips*): tick or untick each one by itself. With *Sane UI* itself unticked no module loads.
- `/sane` says which modules are switched on and lists their commands. `/saneui` is the same.
- `/sane errors` lists the error log, one line per problem; `/sane errors clear` empties it. When something
  fails, one line in chat says where (*problem in ..., noted in the error log*), once per kind of problem.
- **The error log.** Every problem is also kept in a log, in the order it happened, with the place it
  happened. It is in the saved settings file (`WTF/Account/<account>/SavedVariables/SaneUI.lua`, under
  `log`), which the game writes at a `/reload` and when you log out. `dev/tools/errors` prints it.
- `/sane arrange` moves and sizes Sane UI's windows as Edit Mode does, only in a game without Blizzard's Edit
  Mode (there: Esc > Edit Mode).
- `/sane window` shows a small window to try what every Sane UI window can do (again: hides it;
  `/sane window reset`: its first place):
  - **Title bar:** its name at the left, its buttons at the right. Drag the title bar to move it, at any
    time (a window docked at a screen edge only in Edit Mode). A window whose content can be searched has a
    magnifier before its name: a click there opens a search box over the bar (this one has nothing to
    search).
  - **Move in Edit Mode** (Esc > Edit Mode), as the game's own frames: there it shows Edit Mode's blue box
    (its name on it while the mouse is on it); drag the box. Sizing is only there: a window that can be
    sized has its grip only in Edit Mode.
  - **Dock:** in Edit Mode, let it go near a corner of the screen, the middle of one of its edges (top, bottom,
    left, right) or the middle of the screen. A tinted shape
    shows where it will land. Docked, it is one with the edge: its corners there are square and its
    bronze trim is out of the screen; the corners away from the edges are round. Drag it away and it is
    free again, round all around. Let it go with its middle near the screen's middle and it docks there,
    centred: the place for windows you talk to (a vendor, a trainer, the auction house). Dragged by its
    title bar outside Edit Mode it docks only there, in the middle.
  - **Buttons** in the title bar, as the game's windows have them: full screen (and back) and close. A
    window that stands for one of the game's own windows (a module's vendor, later) has a third, left of
    them: the game's own window instead; the game's window then has the same button beside its close
    button, to come back. Filling the screen, every window has the title bar at its top.
  - **Open:** rest the mouse on it a moment and it opens; take the mouse away and it closes a moment later.
    Open, it explains itself, and *Keep open* keeps it open until unticked.
  - **The bar** at its bottom, in the art of the game's own experience bar: *Add* fills it a step at a time
    (the fill rises to its new length with the game's flare at its end), a paler part ahead of the fill
    marks what is still to come, and full it starts again from nothing. It stretches as the window opens.
  - **Fill the screen:** docked, push the mouse against that screen edge (the game window's very edge, where
    the window touches it; docked in a corner, all the way into that corner): it grows to fill the whole screen, on a background that hides the game
    as much as set (half, in solid black, at first), and nothing behind it takes the mouse. On the way its
    corners start as round as the window's and flatten, so the full screen is square. In its top right
    corner the dropdown *Classic windows* lists the game's own windows it stands for (a window that has
    some; this one has none): one chosen, the window goes back and the game's own comes. Move away and push
    there again: it goes back to its size and its zone. Each such window has a section *Expand window*
    in its settings: whether it can, how it moves, the background's opacity and texture, and how round
    the small window's corners are: *Corner radius* (0 to 100 % of half the window's shorter side at rest,
    a tenth at first; at 100 % a square window is a circle) and *Don't round corners on screen edges* (on;
    off: every corner is round, also on the screen's edges). Full, it is square either way.
- **The options** (Esc > Options > AddOns > Sane UI, see [Settings' README](Settings/README.md)): *Sane UI* itself shows only
  its logo; under it are Sane UI's own pages *Profiles*, *General* and *Appearance*, then a page per module
  (*Social*, *Abilities*, *Tooltips*).
- **General switches:** on the page *General*: *Errors in chat* (on): a line in chat for each kind of problem.
  On the page *Appearance*, under *Windows*: *Animation type* (Glide): how every window docked to a screen
  edge fills the screen and goes back, and how a window opens while the mouse rests on it: *Glide* (quick,
  settling softly), *Swing* (a little past, then back), *Even* (a gentle start and end), *Instant* (no motion). A window can have its own type,
  in its section *Expand window* (Social, tab *Appearance*), which can be *Use global type*: this one.
- **Profiles,** on the page *Profiles* (the options show them; `Profiles.lua` keeps them):
  - *All settings accountwide* (ticked at first): every character uses the same settings, the account's.
    Unticked, every character keeps all its settings to itself.
  - In the tab *Accountwide*, box *Sane UI*: a checkbox per module (General, Social, Abilities, Tooltips):
    unticked, that module's settings are each character's own while the others stay the account's.
  - *Saved profiles:* settings of every module kept under a name, for all characters of the account. Choose
    one, then *Load* it (every module takes its settings), *Save* (the settings in use, under the chosen name
    or a new one), *Duplicate*, *Rename* or *Delete* it.
  - Two profiles are always first in the list. Both can be loaded, duplicated (a profile of your own to
    start from) and given to a character; neither can be saved over, renamed or deleted:
    - *Empty*, the one every character has at first: no profile, the settings as they are kept (the
      account's, with *All settings accountwide*, or each character's own), loaded at every login and saved
      at every logout and `/reload`, the game's settings Sync keeps too. Loading it puts those back in use
      where a profile is in use.
    - *SaneUI Defaults*: every setting of Sane UI's own as it is at first (every checkbox, slider and choice
      of the modules switched on, and the general ones), not the game's settings that Sync keeps nor which of
      them it keeps: loading it leaves those as they are. *Save at logout* does not save into it.
  - *Characters:* every character seen on the account (learned at its login), each with *Load at login*,
    *Save at logout* and its profile (*Empty* at first: ticked, switched off). A character with a profile and *Load at login* uses its profile
    instead of the account's settings, for itself only; with *Save at logout* its changes go back into the
    profile. Several characters can share one profile that way. Any character can set them for any other.
    The first line, *New Characters*, is what a character Sane UI has not seen yet starts with at its first
    login (a new one, or one not logged in since Sane UI came): its profile, *Load at login* and *Save at
    logout*, which count from that very login.
  - The settings hold the game's own settings too, as far as Sync's parts are ticked (see
    [Sync's README](Sync/README.md)).

## Technical details
- **Several addons, one shared table.** The game gives every addon a table only its own files see, so what
  the addons share is one global table, `SaneUI`: Core is `SaneUI.Core`, a module `SaneUI.<Name>`.
- **A module** is an addon of its own. Its TOC says `## Dependencies: SaneUI` and `## Group: SaneUI`, and its
  first file makes it: `local ADDON, ns = ...` then `Core.NewModule(ADDON, "Abilities", ns)`. `ns` is the
  module's own table, the same one in all its files. It gets `Print`, `Plain`, `On`, `Safe` and messages of
  its own (`Listen`, `Fire`).
  Core calls its `OnLoad()` when the module's addon is loaded (`ADDON_LOADED` with its name) and its
  `OnLogin()` when the character is there (`PLAYER_LOGIN`).
- **A module depends on Core only,** never on another module: that is what lets each one be switched off.
  The game reads Core first; the order of the modules after it must not matter.
- **Saved settings (`Saved.lua`).** One table, `SaneUIDB`, in
  `WTF/Account/<account>/SavedVariables/SaneUI.lua`. It is Core's, so a module finds its settings whichever
  other modules are on, and keeps them while it is switched off itself.

  | Where | What |
  |---|---|
  | `SaneUIDB.modules.<Module>` | What that module keeps: `Core.Store(name)`, from `OnLoad` on |
  | `SaneUIDB.modules.<Module>.options` | Its switches |
  | `SaneUIDB.modules.<Module>.chars[GUID]` | Its notes per character: `Core.Character(name)`, from `OnLogin` on |
  | `SaneUIDB.modules.Core.options` | The general switches (`Core.general`) |
  | `SaneUIDB.errors` | What went wrong (`Core.errors`), for `/sane errors` |
  | `SaneUIDB.log` | The same, every time it happened: the error log (`Core.log`) |
  | `SaneUIDB.profiles.<Name>.<Module>` | A profile: the switches of every module, under a name |
  | `SaneUIDB.account.<Module>` | The account's switches, kept aside while this character uses other ones |
  | `SaneUIDB.separate` | true: *All settings accountwide* is unticked |
  | `SaneUIDB.perCharacter.<Module>` | true: that module's settings are each character's own |
  | `SaneUIDB.characters[key]` | Every character seen: `name`, `realm`, `class`, its `profile`, `autoLoad`, `autoSave` |
  | `SaneUIDB.newCharacters` | *New Characters*: `profile`, `autoLoad`, `autoSave`, copied into a character's line when it is first seen |
  | `SaneUICharDB` | Per character (`WTF/Account/<account>/<realm>/<character>/SavedVariables/SaneUI.lua`): `settings.<Module>` (its own, as at its last logout), `profile` (the one chosen in the options, for their buttons), `key` (its key in `characters`, to find it before the login) |

- **Profiles (`Profiles.lua`).** *The settings in use* are `SaneUIDB.modules.<Module>.options` of every
  module, the general ones too. The modules hold on to those tables for the session, so they are never
  replaced: what is loaded is copied into them (`Core.CheckOptions` puts a spoiled value right), and each
  module is told of every switch that changed, through the `changed` it gave `Core.Options`, as after a tick
  on its page.
  - **Where they come from** (`Arrange`), for each module: the account's (by default); the character's own
    (`separate`, or the module in `perCharacter`); a profile (the character's line has one, with
    `autoLoad`: for every module, before the others). `Arrange` moves a module from where its settings came
    from to where they should: what it used goes back first (the character's own to `SaneUICharDB.settings`,
    a profile's into the profile with `autoSave`, the account's aside into `SaneUIDB.account`), then the new
    ones are copied in, and the modules are told. It runs at Core's `ADDON_LOADED` (before any module reads
    its settings, without telling), whenever one of those switches changes (at once, telling), and at
    `PLAYER_LOGOUT`, which brings every module back to the account's so the shared file holds them for every
    other character. Account's still aside at a login (a logout that did not finish) are put back first.
    The character's key at `ADDON_LOADED` is the one its last login noted (`SaneUICharDB.key`) or its GUID.
  - **A profile** holds the switches of every module there are saved settings for, also of those switched
    off for this character; loading one (*Load*) sets what it has in the settings in use, wherever those come
    from, and leaves the rest. Renamed, it stays every character's that had it; deleted, no character's.
  - **Empty** (`Profiles.EMPTY`) is no profile: a character's line with none (`profile` nil) shows it, and
    `SetCharacter(key, "profile", Empty)` sets none. Its settings are where they come from without a profile
    (`Home`: the account's, or the character's own). `Load` puts those (`Kept`: the account's kept aside, or
    `SaneUICharDB.settings`) into the settings in use where a profile is in use; `Duplicate` copies them
    (`KeptProfile`). `Character` reports *Load at login* and *Save at logout* for it.
  - **SaneUI Defaults** (`Profiles.DEFAULTS`) is never saved: it is made from the modules' descriptions, so
    it follows every new version. It leaves out Sync's settings (`GameSettings`): they stay where they were,
    also with *Load at login* (`Wanted`). `Load` empties the settings in use of every other module switched on
    and gives each switch its default (`Put`'s `fresh`); with *Load at login* `Arrange` empties every other
    module's, and one whose addon is read later gets its defaults when it describes its switches. `Duplicate`
    writes those defaults (`Defaults`).
  - Both are `Fixed`: `Save`, `Rename` and `Delete` refuse them, no other profile takes their names, and no
    logout saves into them. A saved profile of either name from before is moved to *Empty (old)*, *SaneUI
    Defaults (old)* at the login.
  - **Brought up to date before saving:** a module whose settings hold something of the game's own (Sync)
    gives `Core.Options` a `capture` function; Core calls every one before the settings in use are saved
    anywhere: a profile saved, a module moved, the logout (`Snapshot`). At `PLAYER_LOGOUT`: capture, then
    *Save at logout* into this character's profile, then `Arrange`.
  - `Core.Profiles`: `AccountWide()`, `SetAccountWide(on)`, `Shared(module)`, `SetShared(module, on)`,
    `Characters()`, `Character(key)`, `SetCharacter(key, field, value)` (`"profile"`, `"autoLoad"`,
    `"autoSave"`; `Profiles.NEW` as the key: the line *New Characters*), `List()`, `Chosen()`, `Choose(name)`, `Save(name)`, `Load(name)`, `Duplicate(name, as)`,
    `Rename(name, as)`, `Delete(name)`, `Fixed(name)` (Empty, SaneUI Defaults: cannot be changed). A step returns
    true, or false and a line for chat saying why not (a name that is taken or empty, a fixed profile). Names up to `MAX_NAME` (32) letters. `Copies(module)`: every saved copy of
    a module's switches this character can reach (in use, the account's kept aside, each profile's, its own),
    for a module that brings what an earlier version saved up to date (Social does).

- **A switch is described once,** by its module, while its files are read:
  `Core.Options(name, { { key, default, text, tip }, ... }, changed, capture)`. Core gives it its default and
  keeps it. The options (`Settings/`) show it as a checkbox and call `changed(key, value)` after a
  tick; Core calls it too when a profile changed it. A number is described the same way with its ends (`min`,
  `max`, `step`) and is shown as a slider; one of a few with its `choices`, as a dropdown. `header` (and
  `headerTip`) starts a section of the page above the switch. `tab = "Appearance"` makes the module's page one of
  our own in tabs, as Profiles (`Core.Tabbed`; the frame is `Core.frames[module]`), the switch in that tab, those
  that name none in a first tab *General*; `parent = "key"` puts it under an earlier switch, greyed out while that
  one, or one above it, is off; `inline` draws a number on its parent switch's line; `unit` follows its value.
  Core's own switches name the page they are on with `page = "Appearance"` (none: *General*). One without `text` has no control but is kept
  with the settings and in profiles (Sync keeps what it took from the game so). `capture`: see Profiles.
  A module may show the same switches elsewhere (Abilities does, in the spellbook's menu) by reading and
  writing `options[key]` directly.
- **Load little, start late.** A file only defines things when it is read. Work starts in `OnLoad` or
  `OnLogin`, or later, when what it serves is first used (a window when it is opened). A game event is only
  asked of the game once somebody listens (`Core.On`).
- **Errors stay where they happen.** `Safe(label, fn, ...)` runs one step; an error is told once in chat and
  kept in `Core.errors`. A failing event listener does not keep the next one from the event; the game's
  own error handler still gets the error (`CallErrorHandler`).
- **The error log** (`Core.log`, saved as `SaneUIDB.log`). `Core.NoteError` adds an entry for every
  problem: time, label, text with the place it happened, the addon's version, the game's build. The same
  problem twice in a row is one entry that counts; the log keeps the newest 100. Errors that no `Safe`
  caught (in a frame's script, a timer, a hook) go to the game's own error handler; those that name a
  Sane UI addon are noted from the game's error window (`hooksecurefunc` on
  `ScriptErrorsFrame.DisplayMessageInternal`, which only listens). An addon cannot write a file of its
  own: the saved settings file is the log file, and it is written at a `/reload` or a logout.
- **Falling back to Blizzard.** A module that changes something of the game's must be able to give it back
  when a step fails (Abilities: `Book.StandDown`). Game updates change Blizzard's code under us.
- **Secret values.** In combat the client hides some values from addons; comparing one is an error.
  Everything read from the game goes through `Core.Plain(value)` (nil when hidden).
- **Globals:** `SaneUI`, `SaneUIDB`, `SaneUICharDB`, `SLASH_SANEUI1/2`. `dev/tests/lint` fails on any
  global a file writes that does not start with `SaneUI`.
- **A module that is only loaded when it is wanted** (`## LoadOnDemand: 1`) is started when it arrives:
  `OnLoad`, then `OnLogin` at once, because the login is long past.
- **The options (`Settings/`) and Sync (`Sync/`) are part of Core,** folders listed in its TOC after the
  rest: no modules (no `SaneUI.Settings`, `SaneUI.Sync`), not in the addon list, always there. Their tables
  are `Core.Config` and `Core.Sync`. The options' pages are put up at login, empty (`Core.pages`): the game's
  options window decides the first time it opens whether it has the tabs *Game* and *AddOns*, only if an
  addon has a page by then, and keeps that for the session. Their controls are made when the options first
  open (`Core.Config.Fill`). Sync's switches are kept as a module's, under the name `Sync`. Details:
  [Settings' README](Settings/README.md), [Sync's README](Sync/README.md).
- **A module that stands in for something of the game's** (its tooltips, its chat) says how to give it
  back: `module.GiveBack()` and `module.GIVEN_BACK` (a few words for chat). `module.Guarded(fn, ...)` runs
  a step, and its error calls `module.StandDown(problem)`: once, it sets `module.off`, gives the game's own
  back, keeps the problem and says so. `Guarded`, `Safe` and `Ask` make no table and no closure (the game's
  `xpcall` hands arguments on), so they are cheap enough for what runs many times a second.

| Function | What it does |
|---|---|
| `Core.NewModule(addon, name, table)` | Makes a module of that addon and returns its table |
| `Core.Print(text)` | A chat line with the Sane UI prefix |
| `Core.On(event, fn)` | Listen to a game event |
| `Core.Safe(label, fn, ...)` | Run a step; an error is caught, told once, kept |
| `Core.Report(label, text)` | Keep a problem a module found itself and tell it once |
| `Core.NoteError(label, text)` | Keep an error a module caught itself, without telling it |
| `Core.Trace(message)` | The error handler for `xpcall`: the error and the place it happened |
| `module.Guarded(fn, ...)`, `module.StandDown(problem)` | A step that gives the game's own back when it fails (see above) |
| `Core.Later(fn, delay)` | Returns a function that asks `fn` to run once, `delay` seconds later (none: the next frame) |
| `Core.Plain(value)`, `Core.Secret(value)` | Secret values (see above) |
| `Core.Ask(fn, ...)` | `fn(...)`'s first three answers, each nil when hidden; all nil when `fn` is missing or fails |
| `Core.FullName(unit)` | A unit's whole name as the game shows it: a Forever character's first name and surname (`UnitName` gives both), joined by the game's separator; nil when hidden. Use it wherever a player's name is shown |
| `Core.PlayerKey(unit)`, `Core.PlayerKeyOf(text)` | A player's key, the one name that tells players apart: on Forever first name and surname as one (`Droopy Fairwind`, any realm dropped: the whole name is unique across the region), elsewhere `Name-Realm`; nil for a name that is not whole (a first name alone). Use it wherever a player is kept, counted, compared or shared ([Doc/guides/data.md](../../Doc/guides/data.md), *Players*) |
| `Core.Surnames()` | Whether this client names players by first name and surname (Forever, or `RegionalUniqueNamesEnabled`) |
| `Core.Coins(copper)` | Money as the game writes it, with coin icons; nil if it cannot |
| `Core.Points(region)`, `Core.Repoint(region, points)` | Keep a region's anchors and put them back |
| `Core.pages`, `Core.frames` | The options' pages, from login on, and the frame of a page of our own (`Settings/`) |
| `Core.Command(word, about, fn, ...)` | `/sane <word> <rest>` runs `fn(rest)`; further words are short forms |
| `Core.Store(name)`, `Core.Character(name)` | What a module keeps, for the account and for the character |
| `Core.Options(name, list, changed)` | Describes a module's switches |
| `Core.CheckOptions(name)` | Gives a module's switches their defaults where they have none or a spoiled one |
| `Core.Profiles` | Whose settings are in use, and the profiles (see above) |
| `Core.Config` | The options (`Settings/`): `Fill()` makes the pages' controls (once), `Open()` opens them |
| `Core.Sync` | Sync (`Sync/`): the game's own settings kept with Sane UI's |
| `Core.Data` | Sane UI's own databases (`Data/`): a set's handle (`Data.Set(name)`: `Get`, `History`, `Each`, `OnStamp`, ...), `Data.Prepare(name)`, `Data.WhenReady(set, fn)` ([Doc/guides/data.md](../../Doc/guides/data.md)) |
| `Core.Steps` | The scheduler of long work (`Data/Steps.lua`): `Run(name or options, fn, ...)` gives a job's handle (`:Stop()`); a job asks `Check()` between pieces and goes on in the next frame when the frame's few milliseconds are spent; nothing in a fight or under a restriction |
| `Core.Copy(value)` | A copy of a value that shares no table with it |
| `Core.described`, `Core.optionOrder` | The described switches, for whoever shows them (Settings) |
| `Core.class`, `Core.charName`, `Core.realm`, `Core.charKey` | The character, from login on (`charName` is first name and surname, `charKey` the GUID) |
| `Core.TITLE`, `Core.VERSION`, `Core.GOLD` | Name, version from the TOC, the addon's colour |

- **Windows** (`Window.lua`, `EditMode.lua`, `Dock.lua`, `Shape.lua`, `Skin.lua`, `Edge.lua`, `Expand.lua`,
  `Bar.lua`, `Motion.lua`): a library for the modules' windows, **not yet tried in the game**. Each file's head says how
  to call it.

  | Call | What it gives |
  |---|---|
  | `Core.Window.New(frame, options)` | A window of our own, of a kind (`kind` = `"screen"`, `"panel"`, `"talk"`: `Window.KINDS` gives its options, the module's own win): in Blizzard's Edit Mode dragged by its box (`window.box`, `title` on it) and sized by a grip (`sizable`); a title bar (`titleBar`, `title`, `search`, `dragDocked`) with its buttons (`close`, `native = { frame, show, back }`); docking (`dock`), with a skin (`skin`, its corners as `corners` says, else as `edge`), filling the screen from its screen edge or its button (`edge`, with `motion`, `content`, `filled`); its place and what it was left as are kept in `options.store.place` as `{ x, y, width, height, dock, full, native }`. `window:Place()`, `window:Reset()`, `window:Open()` (the game asked for it), `window:Native(on)`, `window:Remember(what, value)`, `window:Refresh()` (bar and buttons as the window is now), `window:Draggable()`, `window:Attach()` (our button onto the game's window, once it is there), `window.zone`, `window.grip`, `window.skin`, `window.edge`, `window.bar`, `window.buttons` |
  | `Core.Fuzzy.Query(text)`, `Fuzzy.Match(query, ...)`, `Fuzzy.Rank(word, text, lower, spots)`, `Fuzzy.Highlight(text, spots)` | Forgiving search: the typed words; whether every word is in one of the texts (the sum of their ranks); one word's rank in one text, a whole number whose hundreds say how it was found (600 the whole text, 500 its beginning, 400 a word's beginning, 300 its words' first letters, 200 inside, 100 letters spread out in order) and up to 90 more for a close fit, and the bytes it took; the text with those letters in the game's gold (`NORMAL_FONT_COLOR`). One pass through a text per look, no table without spots, each text lowered once per `Match` |
  | `Core.Window.Mover(handle, frame, hooks)`, `Core.Window.Sizer(frame, hooks)` | Only the dragging and the grip, for a window that is not ours to keep (the game's spellbook). Nothing is written into the frame |
  | `Core.Window.Corner(grip, corner)` | Moves a grip to another corner and mirrors its art |
  | `Core.EditMode.active`, `Core.EditMode.Watch(fn)` | Whether Blizzard's Edit Mode is open; `fn(active)` when it opens or closes (`EventRegistry`'s `EditMode.Enter`, `EditMode.Exit`) |
  | `Core.Dock.ZONES`, `Core.Dock.Find(left, bottom, width, height, screenWidth, screenHeight)` | The nine zones (four corners, the middle of each edge, `CENTER` in the screen's middle), and which one a window would dock to (plain numbers; `Dock.REACH` = 60) |
  | `Core.Dock.Rect(zone, width, height, screenWidth, screenHeight)` | Where a window of that size stands docked there: its lower left corner |
  | `Core.Dock.Hold(frame, zone)`, `Core.Dock.Holder(zone, frame)` | A zone holds one window at a time: the window docked there now; the shown one other than `frame` holding it. A drag offers no zone another holds; a window opening with such a zone kept stands free that time (`Window.lua`) |
  | `Core.Shape.New(host, settings, rect)` | A plate with round corners and a trim: `shape:Look({ file, size, top, bottom, trim })`, `shape:Fit(left, bottom, width, height)` (or the frame's own place), `shape:Base(width, height)`, `shape:Flatten(share)` (that far to square), `shape:SetAlpha(fill, trim)`, `shape:SetShown(on)`, `shape.radii`. `Shape.Options(list, at, tab, parent)`: the switches *Corner radius* and *Don't round corners on screen edges* (`corners`, `squareEdges`; `Shape.DEFAULTS`, `Shape.KEYS`) |
  | `Core.Skin.New(frame, settings)` | The tile of the game's dark dialogs (`Skin.TILE`) and a trim in Sane UI's colour on a Shape; `skin:Rest()` (placed: corners measured on this size), `skin:Fit(...)` |
  | `Core.Expand.New(frame, options)` | Opens to `width` × `height` once the mouse has rested on it `Expand.DWELL` (0.2 s; anywhere, or only in `corner`; not with `hover = false`), closes once it has been away `Expand.LINGER` (0.5 s); `expand:Stay(on)` keeps it open (a control of the window's own); `motion` its own kind, `still` while another part has its size. `expand:Open()`, `expand:Close()`, `expand:Stay(on)`, `expand.open`, `expand.stays` |
  | `Core.Bar.New(parent, options)` | A progress bar in the art of the game's experience bar (`Bar.ART`: background, fill, the part still to come, its pip, the dividers, the flare): `bar:SetValue(value, most, ahead)` (a gain rises in `Bar.RISE` to `Bar.RISE_WHOLE` seconds by its size, with the game's flare; a loss is there at once), `bar:SetSize(width, height)` (moves there); `width`, `height`, `segments` (nil: the game's own count), `fill`, `flare`, `motion`, `moved` (the value the fill stands for, on its way too); `bar.frame` |
  | `Core.Edge.New(window)` | Made by `Window.New` with `edge`: docked, the window fills the screen when the mouse is pushed against that screen edge, and goes back when pushed there again; full, the dropdown *Classic windows* (`classic`) in its title bar. `edge:Fill(on)`, `edge.full`, `edge.away`, `edge.classic` |
  | `Core.Motion.Kind(key)`, `Motion.Share(kind, progress)`, `Motion.Ease(curve, progress)`, `Motion.Choices(own)`, `Motion.Clock(frame, step, failed)` | The kinds of motion (`Motion.KINDS`: glide, swing, even, off (*Instant*); each a `time` and the name of one of the game's easing curves, `EasingUtil`); the kind for a window's own setting (nil, `"global"` or unknown: the general one, `Core.general.motion`); the share of the way; a curve by name (straight without the game's); the choices for a dropdown; a clock that runs only while something moves |

  - **The title bar** (`Window.lua`, `Bar`, `Refresh`): with `titleBar` (a kind of window that has one; the
    small chat, unit frames have none), and on every window while it fills the screen. Across its top,
    `Window.BAR` (32) high, `Window.BAR_LEVEL` (20) above it, a thin bronze line under it. At its left a
    button: with `search`, the game's magnifier (`common-search-magnifyingglass`) and the `title`
    (`GameFontNormal`): a click opens the search box (the game's `SearchBoxTemplate`) over the bar up to what
    stands at its right (the buttons, or Edge's dropdown at full screen), the cursor in it; every change goes
    to `options.search(text)`; Esc, or the cursor leaving it empty, closes it, emptied (`search("")` told).
    The bar is the handle `Window.Mover` drags, the title too (a press that became a drag opens no search):
    `window:Draggable()`: only with `titleBar`, not in Edit Mode, not while away, docked at a screen edge only
    with `dragDocked`; such a drag docks only in `Window.DRAG_ZONES` (`CENTER`; `Dock.Watch`'s `only`). A bar
    that goes closes its search.
  - **The buttons**, at the bar's right (`Buttons`), from the right: the game's close button
    (`UIPanelCloseButtonNoScripts`; `options.close`, else it hides the window); with `edge` and its switch
    *Can expand to fullscreen* on, the game's `MaximizeMinimizeButtonFrameTemplate` (`edge:Fill(true)` /
    `Fill(false)`, its look set without a callback whenever the window fills the screen or goes back, however
    that came: `Refresh` from `Edge.Fill`, `Place`, `Edge:Update`); with `options.native`, the game's square
    button (`UI-SquareButton-*`, `Window.BUTTON` 24) with its circling arrows (`UI-RefreshButton`, as its
    group finder's refresh), tip *Classic window*: `window:Native(true)`. `window:Attach()` puts the same
    button (tip *Sane UI window*, `window:Native(false)`) on the game's window, `RIGHT` of its close button
    (`CloseButton`, or the global *name*`CloseButton`, read raw), at that button's level: a frame of ours,
    kept in our own table (nothing written into the game's frame), once per window. Not in Edit Mode. Shown
    buttons stand side by side; `buttons.first` is the leftmost. A free or centred window fills the screen by
    its button (Edge's `placed`), and goes back to where it stood.
  - **What a window was left as** (`Remember`, kept in its place table, carried over by every new place):
    `full` (`Edge.Fill` notes it), `native` (`window:Native`). `window:Open()`, for a module when the game asks
    for the window (its key, an NPC): `native.show()` if the game's own was chosen, else the window shown,
    filling the screen again if it was left so; returns `"native"` or `"ours"`. Catching the game's own
    triggers is the modules' (`Doc/ideas/Windows.md`, *The game's own triggers*).
  - **In a fight** (`window:Locked()`): a window that holds the game's protected frames is protected itself
    (`IsProtected`'s first value counts protected children), and addon code may not move, size, show or hide
    it while `InCombatLockdown()`. Then no drag, no sizing (`usable`, `Draggable`), no full screen
    (`Edge.Fill`), `Place` waits for `PLAYER_REGEN_ENABLED` (`Later`), a full screen motion on its way is put at
    its end at `PLAYER_REGEN_DISABLED` (before the game locks), and `Open` returns `"locked"` for a hidden one.
  - **Esc** (`escape = "close"`): a stand-in of ours, `SaneUIWindowEscape`, in the game's `UISpecialFrames`, is
    shown while such a window is shown; when the game hides it (Esc), each one closes (`options.close`, else
    hidden), a full one as it is (Edge's own stand-in leaves it: no `Fill(false)`, so `full` stays kept); a
    moment later the stand-in is shown again while one still is. Without `escape`, Esc only brings a full window
    back (Edge). `Reset` keeps `full` and `native`.
  - **Arranged in Edit Mode** (`EditMode.lua`, `Window.lua`), as the game's own frames are; sized only there,
    moved also by a title bar (above). The
    game calls its event registry's callbacks sealed off (`securecallfunction`), so ours carry no taint into
    Edit Mode; its manager is only read (open at login?) and followed when it hides its frames' boxes for a
    while without closing (hooks after `ShowSystemSelections`, `HideSystemSelections`): ours hide with them. When it opens, each window made by `New` gets its
    box (made then, once): a frame `Window.BOX_LEVEL` (100) above the window with Edit Mode's own art
    (Blizzard's `EditModeSystemSelectionLayout`, copied as it is local there, in the kit
    `editmode-actionbar-highlight`, by `NineSliceUtil.ApplyLayout` on our frame; not Blizzard's selection
    template, which would select our frame in Edit Mode's manager), a brighter copy (0.4, added) and the
    `title` while the mouse is on it. The box is the handle `Window.Mover` drags; the grip lies over it and
    is shown only then. `window.usable` (box, grip) is false outside Edit Mode. A window that fills the screen is back in its
    zone when Edit Mode opens, and the screen's edge does nothing in it (`Edge` `Pushed`); one in hand when
    it closes is let go and kept. The place is kept at once, as before: not yet in Edit Mode's layouts.
  - **Docked means hanging on the zone,** not on a place: the window is anchored by the point that
    touches the edge, so it stays there at any size and grows away from the edge. Its grip moves to a
    corner that is not at a screen edge.
  - **Round corners, square at the edge** (`Shape.lua`): a window's plate is a fill of up to five strips
    and a square piece in each corner, cut by a circle mask (`Art/circle.blp`, twice the radius wide, on the
    arc's centre: a mask is stretched whole and a texture takes three at most). The pieces are painted alike
    (the gradient's colours where each lies, or the tile's coordinates from the window's top left), so they
    meet without a seam. The trim (`Shape.TRIM`, 2) lies over the fill: strips along the sides, and in a
    round corner an arc, the corner's piece cut by the circle and by a hole (`Art/circle-hole.blp`) the trim's
    width smaller. A corner's radius is `corners` % of half the shorter side of the size it was measured on
    (`Base`: the window at rest), no more than half its shorter side now, and with `squareEdges` no more than
    its gaps to the screen's edges: docked, the corners there are square; on the way to an edge they flatten
    out, and a side's trim slides out of the screen in its last two units. Without the mask files (a game
    started before they were there) every corner is square.
  - **Filling the screen** (`Edge.lua`): docked along a screen edge, along that side, inside the window, lies
    a strip two of the screen's own pixels wide (`GetPhysicalScreenSize`); docked in a corner, only a square
    of `Edge.CORNER` (4) pixels in that corner, so a corner's two edges do not set it off. Strata `DIALOG`,
    fixed, it only takes the mouse's
    coming (`SetMouseMotionEnabled`): its `OnEnter` is the push. Not within `Edge.QUIET` (0.25 s) after the
    window was placed (a window let go at the edge, under the mouse), not while a button is held, not while
    `usable` says no. Then size and place go, frame by frame, from where the window is to the whole screen
    (anchored to it at the end, `SetAllPoints(UIParent)`) or back to `Dock.Rect` of its zone at the size it
    had (then `window:Place()`); unclamped on the way, strata `HIGH` and raised above the rest of it until
    it is back (the window's own layer and level after). Until then it takes the mouse and the wheel (as the
    game's map does while it is locked): nothing behind it is clicked, nor the camera turned or zoomed. Under
    it all its background, a Shape in the window (`Edge.TEXTURES`: solid black, or one of Blizzard's tiles,
    repeated at its size; the trim bronze), whose alpha follows the way up to the opacity set, and whose
    corners are measured on the window at rest and flatten as it comes (`Flatten(cover)`: full, square, the
    trim out of the screen, whatever `corners` and `squareEdges` say); a skin of the window fades out as it comes. What it holds (`content`) fades out in
    `Edge.OUT` and comes in once it stands, in `Edge.IN` (0.4 s) from `Edge.DROP` (10) above, as a panel's intro. `docked` is called at the end, so the window lays out what it holds for its new size once.
    While `away` it is neither dragged nor sized, its grip out of sight. `window:Place()` from elsewhere (a
    reset), hiding it, or a failing step bring it back at once; a failing step also stops the feature for
    that window (`edge.off`). Nothing of it is kept: after a `/reload` it is in its zone.
  - **Classic windows:** a window's option `classic` (a list, or a function giving one, of `{ text, show }`)
    names the game's own windows it stands for. While it stands full (not on the way) the dropdown
    *Classic windows* (`WowStyle1DropdownTemplate`, its words fixed by `OverrideText`, `Edge.MENU_WIDTH` 180)
    sits in the title bar, `Edge.MENU_INSET` (10) left of its buttons, above what it holds; a button per
    entry. One chosen: `edge:Fill(false)`, then the entry's `show()`. What the window holds should start
    `Window.BAR` below its top while full, under the title bar.
  - **The section *Expand window*:** `Edge.Options(list, at, tab)` puts it into a module's switches
    (`Core.Options`) at that place: *Can expand to fullscreen* (on; off: no strips), *Animation type* (Use
    global type), *Background opacity* (0 to 100 %, 50), *Background texture* (Solid black, or one of
    Blizzard's tiles, named as Social's bubbles name them: Marble, Rock, Slate, Iron, Night), *Corner radius*
    and *Don't round corners on screen edges* (`Shape.Options`, under the first). The window reads them by `Window.New`'s
    `edge = ns.options`; `edge = true` takes `Edge.DEFAULTS`; `motion` overrides the section's type. A change
    of one (`Edge.KEYS`): `edge:Update()`, seen at once, also while the window fills the screen.
  - **Cost:** while a window is dragged its place is looked at every frame (for the tinted shape); from the
    mouse's coming onto a window that opens under it until it is closed again, ten times a second for the
    mouse (Expand's watch); a size change is one of
    the game's animations (`Motion.Clock`). The push against a screen edge is an event. Otherwise nothing runs.
  - The look and the motion: square at the screen edge, round elsewhere, the tile of the game's dark dialogs
    with a bronze trim; the motions are the game's own easing curves (`EasingUtil`) with times set here.
- **Tests:** `lua5.1 dev/tests/core.lua` (Core with its options, 210 checks), `lua5.1 dev/tests/sync.lua`
  (Sync, 81 checks) and
  `lua5.1 dev/tests/window.lua` (the windows, 256 checks).

## Files
| File | What it is |
|---|---|
| `SaneUI.toc` | The addon `SaneUI` |
| `Core.lua` | Chat, events, errors, modules, `/sane` |
| `Saved.lua` | The saved settings and the description of the switches |
| `Profiles.lua` | Whose settings are in use (the account's or the character's own), and the profiles |
| `Dock.lua` | The zones at the screen's edges, and the shape that shows where a dragged window docks |
| `Shape.lua` | A plate with round corners and a trim, square where it touches the screen's edge |
| `Skin.lua` | A window's background and border on a Shape, one with an edge it is docked to |
| `Motion.lua` | The kinds of motion (Glide, Swing, Even, Instant) on the game's easing curves, and a clock that runs only while something moves |
| `Window.lua` | Moving and sizing a window (in Edit Mode), keeping its place |
| `EditMode.lua` | Whether Blizzard's Edit Mode is open |
| `Fuzzy.lua` | Forgiving search of typed words in texts, ranked, for the windows' search |
| `Edge.lua` | A docked window that fills the screen when the mouse is pushed against its screen edge |
| `Expand.lua` | A window that opens while the mouse rests on it, and can be kept open |
| `Bar.lua` | A progress bar whose value and size move |
| `Demo.lua` | `/sane window` |
| `Data/` | The data framework: the scheduler (`Steps.lua`), a pack's row into a record (`Codec.lua`), the packs and the answers (`Data.lua`); [Doc/guides/data.md](../../Doc/guides/data.md) |
| `Sync/` | Sync: the game's own per-character settings kept with Sane UI's ([README](Sync/README.md)) |
| `Settings/` | The options: the pages, their controls, `/sane options` ([README](Settings/README.md)) |
| `Art/banner.blp` | Sane UI's banner, at the top of the options' page *Sane UI*. Original art of Sane UI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/SaneUI-banner.png` |
| `Art/circle.blp`, `Art/circle-hole.blp` | The masks round corners are cut with: a white disc, and a white square with the disc taken out (256 × 256, DXT5 with mipmaps). Made by `dev/tools/shape-art`, drawn by code |

## History
- 2026-10-17 — Players' keys: `Core.PlayerKey(unit)`, `Core.PlayerKeyOf(text)` and `Core.Surnames()`. A
  Forever player is first name and surname as one, never either alone; `Core.FullName` no longer shows a
  Retail realm as a surname.
- 2026-10-17 — The kinds of motion are Glide (at first), Swing, Even and Instant, each a time and one of the
  game's easing curves (`EasingUtil`). `Expand` opens once the mouse has rested on a window and closes a moment
  after it has gone, a watch frame looking at the mouse only meanwhile; `expand:Stay(on)` keeps it open (`click`
  and `expand:Pin` are gone). `Bar.lua` is drawn with the game's experience bar art (fill, the part still to
  come and its pip, dividers, the flare) and rises for longer the more was gained. The skin stands on the tile
  of the game's dark dialogs. `/sane window` has *Keep open* and a bar that *Add* fills. `Fuzzy.lua` ranks in
  whole numbers by how a word was found (`Rank`, `Highlight`, were `Score`, `Mark`). The line in chat for a
  problem says where it was and where to read it.
- 2026-10-16 — Kinds of window (`kind`: `screen`, `panel`, `talk`; `Window.KINDS`), and a dock zone holds one
  window at a time (`Dock.Hold`, `Dock.Holder`): a drag offers no zone another shown window holds, and one
  opening with such a zone kept stands free that time (Saneroki's decisions).
- 2026-10-16 — After a review of the window system ([Doc/guides/windows.md](../../Doc/guides/windows.md), new): a
  window holding protected frames is left alone in a fight (`window:Locked()`); Esc closes a window made with
  `escape = "close"`, full as it is; `Reset` keeps what a window was left as; without Blizzard's Edit Mode,
  `/sane arrange` (`Core.EditMode.available`); fuzzy scoring makes no tables without places.
- 2026-10-16 — Nine dock zones: the corners, the middle of each edge and of the screen. The places at a
  quarter and three quarters of the top and bottom are gone; `TOP2` and `BOTTOM2` are now `TOP` and `BOTTOM`.
- 2026-10-16 — Title bars (`titleBar`): the window's name, a search box behind a click on its left
  (`search`; fuzzy finding in `Fuzzy.lua`), the buttons at its right (they left the window's corner;
  `chrome` is gone); it moves the window at any time, but docked at a screen edge (Edit Mode's, unless
  `dragDocked`), docking only in the middle. Every full screen has it at its top, the dropdown *Classic
  windows* in it (`Edge.MENU_ROOM` gone). A window remembers whether it filled the screen and whether the
  game's own window was chosen (`Remember`, `Native`), and `window:Open()` opens it so when the game asks.
- 2026-10-16 — A dock zone in the screen's middle (`CENTER`), for windows the player talks to. A window free or
  docked there has buttons in its top right corner: the game's own window (`native`, with the same button put
  onto the game's window by `window:Attach()`), full screen and back (Blizzard's maximize/minimize button), close
  (`close`). Such a window fills the screen by that button and goes back to where it stood.
- 2026-10-16 — Windows are moved and sized only in Blizzard's Edit Mode (`EditMode.lua`): there they get Edit
  Mode's box to be dragged by and their grip; outside it no grip and no drag (`Window.New`'s `bar` is gone,
  `title` names the box). Edit Mode brings a full window back and the screen's edge does nothing in it.
- 2026-10-16 — A window that fills the screen has the dropdown *Classic windows* (`classic`, `Edge.lua`): the
  game's own windows it stands for; one chosen, the window goes back and the game's comes. A full screen
  background is always square: its corners flatten as it comes (`Shape:Flatten`), even with *Don't round
  corners on screen edges* off.
- 2026-10-16 — Round corners for every window (`Shape.lua`): a window's plate has a corner radius of its own,
  square on the screen's edges (switches *Corner radius* and *Don't round corners on screen edges*, in the
  section *Expand window*), corners that flatten out as they come to an edge, and a bronze trim that follows
  them. The skin is a Shape (was the game's tooltip border, `skin:Dock` gone: `skin:Rest`, `skin:Fit`); the
  full screen background is one (was a texture); a skin fades out while the window fills the screen.
  `Expand` opens with a click too (`click`, `expand:Pin`) and may leave the mouse out (`hover = false`). A
  progress bar (`Bar.lua`), shown in `/sane window` with your experience.
- 2026-10-15 — After a review. Fixed: a character's line naming *Empty* lost the session's changes at every
  logout; a profile moved to *(old)* whose name was taken is kept under the next free one. Docked windows
  hang on the screen's point of their zone and stay at their edge when the UI scale or the game window
  changes; a kept size larger than the screen is cut to it. A module whose `OnLoad` failed gets no
  `OnLogin`; an error text the game hides is noted without it. Sync: Edit Mode layouts and chat colours
  offer the reload too (the game's answer runs in our call); given only once the game has its stored
  settings; a failing game function no longer saves nothing over what was kept; channels are joined before
  the chat windows are given.
- 2026-10-15 — Profiles: *Empty* (`Profiles.EMPTY`), no profile as one in the lists, at first for every
  character: the kept settings, loaded at every login, saved at every logout and `/reload`. *SaneUI Defaults*
  leaves out the game's settings that Sync keeps.
- 2026-10-15 — The options (`Settings/`, was the addon `SaneUI_Settings`, loaded on demand) and Sync (`Sync/`,
  was `SaneUI_Sync`) are part of Core: `Core.Config`, `Core.Sync`. The pages are put up by `Settings/Settings.lua`
  (was Core.lua), `/sane options` is its command; `Core.LoadSettings` and `module.optionsPage` are gone.
- 2026-10-15 — Profiles: *New Characters* (`SaneUIDB.newCharacters`, `Profiles.NEW`): a character not seen yet
  gets a copy of it as its line at `ADDON_LOADED` (or at `PLAYER_LOGIN` when the game had no GUID yet), before
  `Arrange`, so its profile counts from its first login. Rename and Delete change it too.
- 2026-10-15 — The profile *SaneUI Defaults*: always there, every switch at its default; loaded, duplicated,
  given to a character, never changed. A table's default is copied into the settings (`Core.Copy`), so what is
  kept in it no longer changes the description.
- 2026-10-15 — Docked in a corner, a window fills the screen only from a square of four pixels in that corner
  (was a strip along both its edges). Full, a window takes the mouse and its wheel: nothing behind it is
  clicked or scrolled. The section
  *Expand window* (`Edge.Options`): can it, its animation type, the background's opacity (half at first, was
  solid) and texture (Blizzard's tiles). `Window.New`'s `edge` takes the module's settings.
- 2026-10-15 — A docked window fills the screen when the mouse is pushed against its screen edge, and goes back
  when pushed there again (`Edge.lua`, `Window.New`'s `edge`); kinds of motion (`Motion.lua`),
  one of them the general switch *Animation type* on the page *Appearance* (`page = "Appearance"`); `Expand`
  moves by it too (was a spring of its own, `Expand.Spring`, `Expand.TIME`). `/sane window` fills the screen too.
- 2026-10-14 — `Core.FullName(unit)`; `Core.charName` (and so the list of characters) is the whole name, first name and surname.
- 2026-10-14 — `Core.Profiles.Copies(module)`: every saved copy of a module's switches, to bring them up to date.
- 2026-10-14 — Profiles: *All settings accountwide* for the account (was *Character specific settings* per
  character), a module's settings account wide or each character's own, a list of every character with its
  profile, *Load at login* and *Save at logout* (was this character's only). `Arrange` moves each module's
  settings to where they come from.
- 2026-10-14 — The page *Profiles* is a canvas (`Core.frames.Profiles`) that the Settings module fills with tabs.
- 2026-10-14 — The options' pages: *Sane UI* with only its logo; under it *Profiles*, *General*, *Appearance*,
  then the modules' pages by their plain names (*Chat*, was *Sane Chat*). `/sane options` opens *Sane UI*.
- 2026-10-14 — Profiles: *Load at login* and *Save at logout*; a module's `capture` brings its settings up to
  date before they are saved. `Core.Options`: section headers, switches kept without a control. A module can
  have its switches on one of Sane UI's own pages (`optionsPage`). The general switch is called *Errors in chat*.
- 2026-10-14 — Profiles: a character can have settings of its own (`SaneUICharDB`, per character); the
  settings of every module can be kept under a name and loaded, duplicated, renamed and deleted
  (`Profiles.lua`).
- 2026-10-14 — The options' pages are put up at login, so the game's options keep their AddOns tab;
  Settings fills them. Shared tools for the modules: `Report`, `Trace`, `Guarded`/`StandDown`, `Later`,
  `Ask`, `Coins`, `Points`/`Repoint`; `Safe` makes no garbage. Saved settings of the wrong shape are
  replaced, a switch of the wrong kind gets its default, a number is kept within its ends.
- 2026-10-14 — The error log: every problem with time and place, also those the game's error handler got; `dev/tools/errors` prints it.
- 2026-10-14 — Windows: moving, sizing, docking to twelve zones at the screen's edges, a skin, opening
  under the mouse; `/sane window`. Social and Spellbook move and size through it.
- 2026-10-14 — 0.3.0: loads Settings on demand and owns `/sane options`; starts a module that arrives after
  the login. The key binding header is gone with the last binding.
- 2026-10-14 — 0.2.0: Core is the main addon and every module an addon of its own. The saved settings
  moved here from Settings (`Saved.lua`). First general switch.
- 2026-10-14 — First version (Sane UI 0.1.0). The tools came out of Actionbar Organizer's `Core.lua`.
