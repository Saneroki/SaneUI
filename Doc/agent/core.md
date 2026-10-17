# Core, with its options (Settings)

## Responsibilities and entry points

| File under `src/` | Responsibility |
| --- | --- |
| `Core/Core.lua` | Shared table, events, module lifecycle, errors, slash dispatch |
| `Core/Saved.lua` | `SaneUIDB`, stores (`store.options`: the live settings, found, never kept there), character data, option descriptions (`Core.Options` hooks: changed, replaced, moved, capture, version/upgrade, game), `Core.Settle` (upgrade, check, drop undescribed), `Core.Set`/`Reset`/`Described`/`Settings`/`Same` |
| `Core/Kit.lua` | `Core.Word`, `RGB`/`Hex`, `Pixels`, `Tip`/`ShowTip`/`HideTip`, `Pool`, `Confirm`/`AskText` (the game's generic dialogs), `Font`, `Sound`, `Lend` (a game frame changed for a while and given back exactly) |
| `Core/Serial.lua` | `Core.Serial.Write/Read`: plain values as one line of text (profile export/import); read letter by letter, never run |
| `Core/Profiles.lua` | Where each module's settings live (the profile in use, or with Accountwide off the character's own), `Move` between places, the profiles, the first shape brought over (v1 → v2), `/sane profile` |
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
| `Core/Data/Steps.lua` | `Core.Steps`, the data framework's scheduler: jobs as coroutines (`Run(name, fn, ...)`, `Check`, `Fresh`, `Spend`, `Running`, `Jobs`), at most 5 ms and a quarter of a frame (`GetFramerate`) for all, by `debugprofilestop`; nothing in combat or under a restriction (Combat, Encounter, ChallengeMode, PvPMatch, Map; not Chat); a failing job dropped and reported; its frame has an `OnUpdate` only while there is work. The framework: `Doc/guides/data.md` |
| `Core/Data/Codec.lua` | Makes `Core.Data`; `Data.Codec`: a pack's row into a record (`Decoder(fields, types)`, `Cut`, `Build`, `Versions`): tab between fields, characters 30 and 31 inside one, an empty part no value, a build and a day only a gone version; never raises on a broken row, never runs what it reads |
| `Core/Data/Data.lua` | `Core.Data`: packs found by their TOC lines (`Find`), the client's game version (`Game`: `WOW_PROJECT_ID`, `IsBetaBuild`, `IsTestBuild`/`IsPublicTestClient`; none told: every pack refused), `Set(name)` handles (`Get`, `At`, `History`, `Versions`, `Changes`, `Keys`, `Each`, `Stamp`, `OnStamp`, `State`, `Ready`, `hash`, `build`; the versions the client's build has reached, records with their patch), `Prepare` (the scheduler's job *data: packs*: after `LOADING_SCREEN_DISABLED`, one pack a frame, out of combat), `Add` (called by a pack's set file), records made on first ask and kept weakly, `frozen`/`Tampered` for the tests; failures said once; `/sane data [show <set> <key>]` |
| `Core/Settings/Settings.lua` | `Core.Config` (`Config` locally): put up `Core.pages` at login (`PutUpPages`, `Core.Tabbed`), `Fill` them once on options `OnShow`/`Open` with Blizzard initializers; `/sane options`; compartment func |
| `Core/Settings/Panel.lua` | Canvas parts: header, MinimalTab tabs, scroll area, titled backdrop boxes, checks, sliders, dropdowns, colour swatches, buttons; `Panel.Refresh` |
| `Core/Settings/Tabbed.lua` | `Config.BuildTabbed`: a module's canvas page in tabs (`option.tab`), drawn from the option descriptions with Panel controls (a box per `header`, `inline` numbers on their parent's line) |
| `Core/Settings/Profiles.lua` | Canvas page *Profiles*: tabs; tab Profiles (Accountwide settings; this character's profile + New/Rename/Delete/Defaults, Copy from, Export/Import in a text window `SaneUIProfileText`; characters with their profile and Forget, New Characters first) |
| `Core/Settings/Synced.lua` | Tab *Game settings*: a box per `Sync.GROUPS` entry with its `Sync.parts` (`Sync.PartKept`/`KeepPart`, per profile), off with Accountwide off |
| `Core/Settings/CVars.lua`, `CVars.xml` | Tab *CVars* of the page Profiles: search box + `WowStyle1FilterDropdownTemplate` (not at default, kept, kind; red cross resets), its own ScrollBox of two-line rows (keep tick, name/label, inline `InputBoxTemplate` value: Enter sets, Esc reverts; `common-icon-undo` reset while not default), details in the row tooltip, status + count under the list; labels `{ label, tip }` from `Data/CVarLabels.lua` (`dev/tools/cvar-labels [--check]`) |
| `Core/Settings/About.lua` | Page *Sane UI* under the banner: links (`About.LINKS`: Discord, website, GitHub, shown to copy) and feedback (bug, feature, note: a window that makes a report to copy, `About.Report`); `/sane feedback` |
| `Core/Settings/Banner.xml` | Banner row template; its mixin (in Settings.lua) hides the page title while shown |
| `Core/Sync/*` | `Core.Sync`: see [sync.md](sync.md) |

Core TOC order: Core → Kit → Serial → Motion → Saved → Profiles → Dock → EditMode → Fuzzy → Shape → Skin → Edge → Window → Expand → Bar → Demo → Data/ (Steps, Codec, Data) → Sync/ (Sync,
Data/Pages, Layout, Chat, Game) → Settings/ (Settings, Panel, Tabbed, Profiles, Synced, About, Data/CVarLabels, CVars, XML).
Settings and Sync are no modules (no `SaneUI.Settings`/`SaneUI.Sync`, no TOC of their own); they hook Core's
events themselves, after Saved's and Profiles' handlers (TOC order).
Modules register via `Core.NewModule(ADDON, name, ns)` in their first file.
Core dispatches `OnLoad` on that addon's `ADDON_LOADED`, then `OnLogin` on `PLAYER_LOGIN`.
A module arriving after login gets both steps immediately; one whose `OnLoad` failed gets no `OnLogin`. Saved data is available from `OnLoad`;
`Core.class`, `charName`, `charKey` from login. Character identity is GUID (first names can be shared),
with name/realm fallback; Profiles keys a character by its GUID, else `SaneUICharDB.key`. Forever names are first name + surname (`UnitName` returns both): show players
with `Core.FullName(unit)`; `charName` is the full name. Any other player is keyed, compared and shared by
`Core.PlayerKey(unit)` / `Core.PlayerKeyOf(text)`: Forever `First Surname` (realm dropped, regionally
unique; never either part alone, nil without the surname), Retail `Name-Realm`; `Core.Surnames()` tells
which (Doc/guides/data.md, *Players*).

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
- `Core.Options(name, descriptions, hooks)`: describe at file load (hooks: a table, or only `changed`); returns the
  live settings once Core is loaded. `Core.Settle` makes a copy right whenever it comes into use (upgrade by
  `version`/`upgrade` first, then kinds/choices/validate/ends; keys no description has go, `_`-keys stay).
  `Core.Set(name, key, value)` for writes from menus/commands (checks, tells, reload offer, page refresh).
  `Store(name)` returns the module's store; `Character(name)` returns `modules[name].chars[charKey]`,
  annotating name/class.
- `Core.AfterCombat(key, fn, ...)` runs now or after the fight (same key merges); `Core.Locked(frame)`;
  `Core.Restricted()` (combat or `Core.RESTRICTIONS`, kept from `ADDON_RESTRICTION_STATE_CHANGED`'s payload);
  `Core.Off`, `Core.OnUnit`/`OffUnit`; `ADDON_ACTION_BLOCKED`/`FORBIDDEN` of ours go to the error log.
  `modules[name].chars[charKey]`, annotating name/class.

Saved shape (v2): `SaneUIDB = { version, modules = { <Module> = { chars, ... } }, profiles = { Accountwide = { <Module> = options }, ... },
accountwide (false: off), characters = { [key] = { name, realm, class, profile } }, newProfile, ownSince, errors, log }`;
per character `SaneUICharDB = { settings, since, key, version }`.
Errors keyed by label contain `text/count/when` (at most 100 labels); chronological log entries also contain label,
version/build. Keep newest 100; consecutive identical failures coalesce. Uncaught SaneUI errors are
observed through `ScriptErrorsFrame.DisplayMessageInternal`. The client writes saved variables at
reload/logout, so run `dev/tools/errors` after that to see current disk evidence.

## Profiles

Saneroki, 2026-10-17. **Accountwide settings** (`SaneUIDB.accountwide ~= false`, on at first): every character uses
a profile (`characters[key].profile`, nil = *Accountwide*, always there, not renamed or deleted), holding every
module's settings and Sync's (the game's). Off: each character's own (`SaneUICharDB.settings`, re-seeded from its
profile when `since ~= ownSince`), the game's settings untouched (Sync's live table is a session table; Give and
Capture do nothing).

Each module's live table (`Core.Settings`) is stored in exactly one place, the one in use; the game writes a table
once, so it is never also kept elsewhere (`store.options` is a metatable alias). `Move(to)`: capture, copy the live
tables into the old place, wipe each live table and fill it from the new place (`Core.Settle`), store it there, tell
(`changed` per differing key by `Core.Same`, or `replaced`), then `moved` (Sync gives the game's settings). Load:
`ADDON_LOADED` binds every described module; later modules bind in `Core.Options`. `PLAYER_LOGIN`: a different key
(no GUID at load) registers and moves. `PLAYER_LOGOUT`: `Capture()` only, so logout listeners see the right
settings in any order. Upgrade v1 → v2 once (`Profiles.Upgrade`): account options (and a parked `account`) →
*Accountwide*; module `store.version` stamped as each copy's `_version`; a line's profile kept only with
`autoLoad`; `separate` → off with `ownSince = 1` (v1 own settings kept); `perCharacter`, `account`, `newCharacters`
(→ `newProfile`) dropped. Profile names unique case-insensitively; Export/Import through `Core.Serial`
(`{ kind = "Sane UI profile", version, name, settings }`).

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
