# Core, with its options (Settings)

## Responsibilities and entry points

| File under `src/` | Responsibility |
| --- | --- |
| `Core/Core.lua` | Shared table, events, module lifecycle, errors, slash dispatch |
| `Core/Saved.lua` | `SaneUIDB`, stores, character data, option descriptions/defaults |
| `Core/Profiles.lua` | Account vs character-specific settings (`SaneUICharDB`), named profiles |
| `Core/Window.lua` | Own windows (Edit Mode: its box to drag, the grip; `titleBar`: title, search box (`search`), buttons the game's window / full screen / close, drag at any time but at a screen edge; every full window has the bar; `Remember`/`Native`/`Open` for the game's triggers; `Attach` on the game's window) and low-level movers/sizers for Blizzard windows |
| `Core/Fuzzy.lua` | Forgiving search ranked in whole numbers by how a word was found (whole 600, text start 500, word start 400, initials 300, inside 200, spread letters 100, plus up to 90 for a close fit; every word must match, ranks add up): `Query`, `Match`, `Rank`, `Highlight` (`NORMAL_FONT_COLOR:WrapTextInColorCode`) |
| `Core/EditMode.lua` | `Core.EditMode.active`, `Watch(fn)`: Blizzard's Edit Mode open or closed (`EventRegistry` `EditMode.Enter`/`Exit`) |
| `Core/Dock.lua` | Nine snap zones (four corners, four edge middles, `CENTER`), pure `Find` arithmetic, drag preview |
| `Core/Shape.lua` | A window's plate: fill pieces with round corners (circle masks, `Art/circle*.blp` by `dev/tools/shape-art`), bronze trim; per-corner radius from `corners` % of the size at rest, square at screen edges with `squareEdges`; `Shape.Options` |
| `Core/Skin.lua` | The game's dark dialog tile (`Skin.TILE`, 32 units) and a bronze trim on a Shape; `skin:Rest()` on placement, refits on size changes |
| `Core/Bar.lua` | Progress bar in the game's experience bar atlases (`Bar.ART`): two StatusBars (fill over the part still to come), pip, dividers (`segments`, nil: `STATUS_BAR_NUM_SEGMENTS`), flipbook flare; gains rise in `RISE`..`RISE_WHOLE` s by size (`OutQuartic`), losses jump; `SetSize` moves by the kind of motion |
| `Core/Motion.lua` | Kinds of motion of a window's size on Blizzard's `EasingUtil` curves (`Motion.Ease`, linear without it): Glide 0.35 s OutQuartic (default), Swing 0.45 s OutBack, Even 0.5 s InOutCubic, Instant (key `off`, which Social passes); the general switch on Appearance (`Core.general.motion`), a window may have its own; unknown keys fall back |
| `Core/Edge.lua` | A docked window fills the screen when the mouse is pushed against its screen edge, back when pushed again; own background (square when full), takes the mouse; dropdown *Classic windows* while full (`classic`: the game's windows it stands for); section *Expand window* in the window's options (`Edge.Options`) |
| `Core/Expand.lua` | Opens after the mouse rests `DWELL` 0.2 s on it (or its `corner` spot; `hover = false`: never by the mouse), closes after `LINGER` 0.5 s away; a hidden-when-idle watch frame's OnUpdate looks every `STEP` 0.1 s (IsMouseOver with `MARGIN`, held left button counts); `expand:Stay(on)` keeps it open; size moves by the kind of motion |
| `Core/Demo.lua` | Lazy `/sane window` demonstration: opens on rest, *Keep open* box, a bar that *Add* fills (wraps to 0 at full) |
| `Core/Settings/Settings.lua` | `Core.Config` (`Config` locally): put up `Core.pages` at login (`PutUpPages`, `Core.Tabbed`), `Fill` them once on options `OnShow`/`Open` with Blizzard initializers; `/sane options`; compartment func |
| `Core/Settings/Panel.lua` | Canvas parts: header, MinimalTab tabs, scroll area, titled backdrop boxes, checks, sliders, dropdowns, colour swatches, buttons; `Panel.Refresh` |
| `Core/Settings/Tabbed.lua` | `Config.BuildTabbed`: a module's canvas page in tabs (`option.tab`), drawn from the option descriptions with Panel controls (a box per `header`, `inline` numbers on their parent's line) |
| `Core/Settings/Profiles.lua` | Canvas page *Profiles*: tabs; tab Profiles (All settings accountwide, profile dropdown + buttons, characters list with per-character profile/auto load/save), generic dialogs |
| `Core/Settings/Synced.lua` | Tab *Accountwide* (box Sane UI: `Profiles.Shared` per module; a box per `Sync.GROUPS` entry with its `Sync.parts`) |
| `Core/Settings/CVars.lua`, `CVars.xml` | Tab *CVars* of the page Profiles: search box + `WowStyle1FilterDropdownTemplate` (not at default, kept, kind; red cross resets), its own ScrollBox of two-line rows (keep tick, name/label, inline `InputBoxTemplate` value: Enter sets, Esc reverts; `common-icon-undo` reset while not default), details in the row tooltip, status + count under the list; labels `{ label, tip }` from `Data/CVarLabels.lua` (`dev/tools/cvar-labels [--check]`) |
| `Core/Settings/About.lua` | Page *Sane UI* under the banner: links (`About.LINKS`: Discord, website, GitHub, shown to copy) and feedback (bug, feature, note: a window that makes a report to copy, `About.Report`); `/sane feedback` |
| `Core/Settings/Banner.xml` | Banner row template; its mixin (in Settings.lua) hides the page title while shown |
| `Core/Sync/*` | `Core.Sync`: see [sync.md](sync.md) |

Core TOC order: Core → Motion → Saved → Profiles → Dock → EditMode → Fuzzy → Shape → Skin → Edge → Window → Expand → Bar → Demo → Sync/ (Sync,
Data/Pages, Layout, Chat, Game) → Settings/ (Settings, Panel, Tabbed, Profiles, Synced, About, Data/CVarLabels, CVars, XML).
Settings and Sync are no modules (no `SaneUI.Settings`/`SaneUI.Sync`, no TOC of their own); they hook Core's
events themselves, after Saved's and Profiles' handlers (TOC order).
Modules register via `Core.NewModule(ADDON, name, ns)` in their first file.
Core dispatches `OnLoad` on that addon's `ADDON_LOADED`, then `OnLogin` on `PLAYER_LOGIN`.
A module arriving after login gets both steps immediately; one whose `OnLoad` failed gets no `OnLogin`. Saved data is available from `OnLoad`;
`Core.class`, `charName`, `charKey` from login. Character identity is GUID (Forever names can collide),
with name/realm fallback. Forever names are first name + surname (`UnitName` returns both): show players
with `Core.FullName(unit)`; `charName` is the full name.

## Shared contracts

- `Core.On(event, fn)`: one shared event frame; event registration is lazy and skips unknown events.
  Listener failures go through `CallErrorHandler`; other listeners still run.
- `Core.Safe(label, fn, ...)`: catches/reports failure (`Core.Report`: one chat line per label, "problem in <label>,
  noted in the error log (/sane errors).", unless *Errors in chat* is off), returns only the first result. Module `Safe`
  prefixes its name. `Listen`/`Fire` are module-local messages, with each listener safe.
- `module.Guarded(fn, ...)`: on failure, `StandDown` sets `off` once, calls `GiveBack`, reports via
  `GIVEN_BACK`. Later guarded calls do nothing. Abilities's book has its own narrower fallback.
- `Core.Secret(v)` / `Plain(v)`: test secret values / return nil for them. `Ask(fn, ...)` calls via
  `pcall` and returns up to three plain answers; missing/failing function gives nils.
- `Core.Later(fn, delay)`: coalescing request function; only one pending timer. `fn` needs its own
  appropriate guard. `Points` / `Repoint` preserve anchors, including nil holes.
- `Core.Options(name, descriptions, changed)`: describe at file load; defaults repair wrong types
  and clamp numeric options. `Store(name)` returns the account store; `Character(name)` returns
  `modules[name].chars[charKey]`, annotating name/class.

Saved shape: `SaneUIDB = { modules = { Core = { options, demo }, <Module> = {...} }, errors, log, profiles, account }`;
per character `SaneUICharDB = { settings, profile, key }`.
Errors keyed by label contain `text/count/when`; chronological log entries also contain label,
version/build. Keep newest 100; consecutive identical failures coalesce. Uncaught SaneUI errors are
observed through `ScriptErrorsFrame.DisplayMessageInternal`. The client writes saved variables at
reload/logout, so run `dev/tools/errors` after that to see current disk evidence.

## Profiles

`modules.<M>.options` tables are held by modules (and Settings' AddOn settings) for the whole session:
never replace them, copy into them (`Profiles.lua` `Put`: copy, `Core.CheckOptions`, then `changed(key,
value)` per changed described key). `Arrange` keeps `using[module]` = nil (account's) | "own" |
"profile:<name>" and moves each module to `Wanted`: profile if this character's line in
`SaneUIDB.characters[key]` has `autoLoad` + an existing `profile`; else own if `SaneUIDB.separate` or
`SaneUIDB.perCharacter[M]`; else account. Leaving a source saves it (own → `SaneUICharDB.settings`,
profile with `autoSave`, account parked in `SaneUIDB.account`). Runs at Core `ADDON_LOADED` (key from
`SaneUICharDB.key` or GUID; leftover `account` restored first), on `SetAccountWide`, `SetShared`,
`SetCharacter` for the current key, `Delete`, and at `PLAYER_LOGOUT` (leaving: all back to account, after
capture + autoSave snapshot). `PLAYER_LOGIN` notes the character (name, realm, class) and `char.key`.
Profiles (`SaneUIDB.profiles[name][module]`) are snapshots of all modules' options; Load puts them into
whatever is in use. `Profiles.Copies(M)` lists every saved copy of M's options reachable now (in use,
parked account, each profile, this character's own) for one-time upgrades by a module once versions are handed out. `SaneUIDB.newCharacters` (key `Profiles.NEW` in `Character`/`SetCharacter`, `Line`) is copied
into an unseen character's line by `Register` at `ADDON_LOADED` before `Arrange` (and at `PLAYER_LOGIN` if no GUID
then); Rename/Delete walk `Lines()` (it plus every character). `Profiles.EMPTY` ("Empty") and `Profiles.DEFAULTS` ("SaneUI Defaults") are virtual, never in `SaneUIDB.profiles`
(`Exists` vs `Saved`; both `Fixed`: Save/Rename/Delete refuse). Empty = no profile (line `profile` nil; `Character`
reports it, with autoLoad/autoSave true); Load puts `Kept(name)` (account's aside or `char.settings`, per `Home`)
where a profile is in use; Duplicate = `KeptProfile()`. Defaults: Load = `Put(..., fresh)` (wipe, then
`CheckOptions`) for described modules except Sync (`GameSettings`); `Wanted` never gives Sync to it; `Arrange` to it
wipes the others (later addons get defaults from `Core.Options`); Duplicate writes `Defaults()`; never autoSaved. `Core.Copy` (Saved.lua): table defaults are copied, never shared. Settings' `Config.Refresh` re-notifies controls with the module callbacks muted (Core
already told them). `Core.Options(name, list, changed, capture)`: every `capture` runs before a snapshot;
options may have `header`/`headerTip` or no `text` (hidden, still saved). A table option is reported as
changed on every load (copies). Pages: `Core.pages.top` (logo only), `.Profiles` (canvas: frame
`Core.frames.Profiles`, filled by Settings' `Config.BuildProfiles` with tabs from `Panel.lua`), `[Core.name]`
(General), `.Appearance`, then `[module]` titled by `module.title`: a vertical page, or a canvas page of our own
(`Core.frames[module]`, `Config.BuildTabbed`) when one of its switches names a tab (`Core.Tabbed(name)`; Social's do)
(only `SaneUI[name]` modules: Sync's switches, described under `Sync`, get no page; the tab Accountwide shows them).

## Options trap

`Settings/Settings.lua` registers **empty pages at login**, because Blizzard chooses whether
to show its AddOns tab when options first open. Registering pages in a late-loaded module loses that
tab for the session. `Config.Fill` (options `OnShow`, `/sane options`) fills the existing `Core.pages`
once. Vertical pages use `RegisterInitializer` (`Settings.Create*Initializer`), never direct checkbox
creation; canvas pages (Profiles, a module's tabbed page) build their controls with `Panel.lua`. Opening
options in combat currently prints a message and returns; it does not queue an automatic opening.

## Window contracts

`Core.Window.New(frame, options)` supplies movement, optional sizing/docking/skin and saved placement.
Caller builds content, then calls `window:Place()`. Saved `place = {x,y,width,height,dock}` uses
the top-left corner measured from UIParent's bottom-left; dock names win over coordinates (`full`, `native`:
what it was left as). How every window is built, its states, taint rules for the game's own windows and
what is not built yet: [Doc/guides/windows.md](../guides/windows.md).
Docked windows grow away from their edge; grip corner and skin follow. `Dock.Anchor` hangs a window on
UIParent's point of its zone, with no offset, so it stays at its edge
when the UI scale or game window changes. A kept size is cut to the screen's. `window:Reset()` clears place, keeps `full` and `native`.
In a fight a window holding protected frames is not moved, shown or hidden (`window:Locked()`).
`options.docked(zone)` is called on placement, including initial placement.

For Blizzard windows use `Window.Mover`/`Sizer`, keeping state externally. `usable()` gates handling;
drag `started/stopped` callbacks let the caller preserve state. `Dock.REACH = 60`; `Find` is pure.
`Expand.New` opens to configured width/height after the mouse rests on it, remembers closed size, supports an
optional hot corner; the size moves as its kind of motion says (`Motion.KINDS`: glide, swing, even, off), the
general one or the window's own; its watch frame runs only from the mouse's coming until it is closed. A held
left button prevents closing; `Stay(true)` keeps it open.

Tests: `dev/tests/core.lua` and `window.lua`. Detailed API examples: `src/Core/README.md` and file heads.
