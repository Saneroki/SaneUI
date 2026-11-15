# Core, with its options (Settings)

Core (`SaneUI`, `src/Core/`) is the main addon and every module's library. A line per file: `src/Core/README.md`,
section *Files*; the API of each file in its head comment; the rules in `Doc/guides/addon-standards.md`; windows in
`Doc/guides/windows.md`; the data framework in `Doc/guides/data.md`. Sync: [sync.md](sync.md).

## Responsibilities and entry points

In the TOC's order (`grep -v '^#' src/Core/SaneUI.toc`); the built TOC adds the set files `Sets/<Set>.lua` at its
end (`dev/build`, from `assets/data/`).

| File under `src/Core/` | What it does; the names it defines |
| --- | --- |
| `Core.lua` | Chat, events, errors, modules, `/sane`: `Core.Print`; `Secret`/`Plain`/`Ask`; `Surnames`/`FullName`/`PlayerKey`/`PlayerKeyOf`; `Coins`; `Points`/`Repoint`; `NoteError`/`Report`/`Safe`/`Guard`/`Later`/`AskReload`; `On`/`Off`/`OnUnit`/`OffUnit`; `Locked`/`Restricted`/`AfterCombat`/`Owed`; `NewModule`, `Command`; `TellGame`/`ForGame`/`ServesGame` (Forever, Retail); `NewerCoreWanted` (a module published with a newer Core) |
| `Kit.lua` | Small helpers: `Core.Word`, `RGB`/`Hex`, `Pixels`, `Tip`/`ShowTip`/`HideTip`, `Unconfirmed`/`TipLook`/`TipSection`/`LookOf`, `Pool`, `Confirm`/`AskText` (the game's dialogs), `Font`, `Caret` (a blinking cursor of ours in an edit box), `Sound`, `Lend`/`Lent` (a game frame changed for a while, given back exactly) |
| `Units.lua` | Distances and times as the setting *Units* says, the code keeping yards: `Core.Metric`, `Distance`/`DistanceNumber`/`DistanceText`, `Clock`/`ClockAt`/`GameClock` |
| `Serial.lua` | Plain values as one line of text and back (a profile exported, imported): `Core.Serial.Write`/`Read`; read letter by letter, never run |
| `Motion.lua` | Kinds of motion on the game's easing curves: `Core.Motion.KINDS` (glide, swing, even, off), `Kind`/`Ease`/`Share`/`Choices`, `Clock`, `Fade`/`Slide` |
| `Saved.lua` | `SaneUIDB`, the switches described and the settings in use: `Core.Store`/`StoreName`/`Character`, `Copy`/`Same`, `Settle`, `Options`/`Described`/`Settings`/`Set`/`Reset` |
| `Presets.lua` | What the profile Speedleveling sets over the defaults: `Core.Presets.profiles.Speedleveling` (our CVars as Sync's `named`, Speed Leveling's switches, Economy's `bankerAuto`; Accountwide none since 2026-11-15), `Presets.VERSION` |
| `Profiles.lua` | Where every module's settings live (*Profiles* below): `Core.Profiles.Enabled`/`SetEnabled`/`On`/`Arrive`/`Live`/`InUse`/`List`/`Fixed`/`Create`/`Use`/`Rename`/`Delete`/`CopyFrom`/`Reset`/`Export`/`Import`/`Character`/`Leveling`/`SetLeveling`; `VERSION` 3; `/sane profile [name|on|off]` |
| `Dock.lua` | Nine snap zones: `Core.Dock.ZONES`, `REACH` 60, pure `Find`/`Rect`/`Of`, `Anchor` (a frame hung on the screen's point of its zone), `Hold`/`Holder` (a zone holds one window), `Watch`/`Drop` (the shape while dragged) |
| `EditMode.lua` | Whether Blizzard's Edit Mode is open: `Core.EditMode.active`, `available`, `Watch(fn)` |
| `Escape.lua` | `Core.Escape(owner, close)`: one stand-in `SaneUIEscape` in `UISpecialFrames` for all of Sane UI; hidden by Esc, it runs every close and is shown again while any remain |
| `Watch.lua` | `Core.Watch(frame, every, fn, label)` (a child frame's OnUpdate, only while out and shown; an error stops it); `Core.Hover(frame, options)` (the mouse on a window: dwell, linger, margin; a held left button counts) |
| `Fuzzy.lua` | Forgiving search for the windows' search boxes: `Core.Fuzzy.Query`/`Match`/`Rank`/`Highlight`/`Plain`, `Filter` (≤ `AT_ONCE` 200 rows at once, else a `Core.Steps` job) |
| `Shape.lua` | A window's plate, round corners and trim: `Core.Shape.New`/`Options`/`Round`, `DEFAULTS` (`corners`, `squareEdges`), masks `CIRCLE`/`HOLE`/`CORNER`/`CAP_*` (`dev/tools/shape-art`) |
| `Skin.lua` | Background and border on a Shape, one with an edge it is docked to: `Core.Skin.New`, `TILE`/`TILES`, `Tile`/`Choices` |
| `Look.lua` | The kit (WoW: Forever's own parts, `Doc/guides/interface-style.md`, *The kit*): `Core.Look.Frame`/`Plate`/`Line`/`Square`/`Red`/`Search`/`Head`/`Band`/`Inset`/`Box`/`Headline`/`Slot`/`Tab`/`Outline`/`Rule`/`SetFont`/`Dress`/`Inner`/`Outer`, `Atlas` with `STAND_IN` for Retail, `Font`, colours `NAV`/`LINE`/`INK`/`GOLD`/`FAINT`/`SHADE`, `PX`, `HAND` (the loot feed's Kalam Bold) |
| `Edge.lua` | A docked window fills the screen when the mouse pushes its screen edge: `Core.Edge.New`/`Options` (section *Expand window*, `DEFAULTS`), `CLASSIC` (the dropdown *Classic windows*); `edge:Fill`/`Stop`/`Docked`/`Escapes` |
| `Window.lua` | Own windows (*Window contracts* below): `Core.Window.New`, `KINDS` (screen, panel, talk), `Mover`/`Sizer`/`Corner`, `CloseOf`/`Beside`, `All`/`ResetAll`/`PlaceAll` |
| `Classic.lua` | The game's windows ours stand for: `Core.Classic.Menu`/`List`/`Windows`/`Pick`/`Ticked`, `Attach`/`Button` (the button *Sane UI* on the game's window), `Press(what, binding)` (the key of a panel our code may not open) |
| `Views.lua` | Views behind the game's tabs (`TabSystemTemplate`) at the top of `window.inside`: `Window.Views(window)`, `TABS`/`TAB_INSET`/`TAB_WIDTHS` (the spellbook's) |
| `Selection.lua` | A window chosen in Edit Mode and Core's own dialog for it: `Core.Selection.Select`/`Clear`/`Moved`, `LEVEL` 200, `ANCHOR` |
| `Holder.lua` | The game's window kept out of sight while ours stands for it (`native.hold`): `Core.Holder.Take(window)`, `TINY`; `holder:Native`/`GiveBack` |
| `Seat.lua` | A window not ours seated in a room of a full window (place, scale, layer lent, never the parent): `Core.Seat.New(frame, { label, sized, gone })`, `seat:Hold`/`Free`/`Size` |
| `HealthMarks.lua` | What every health bar shows besides the health (barrier, lost maximum, dispellable): `Core.HealthMarks.New(host, health, options)`, `EVENTS`, `ICONS` |
| `Board.lua` | A module's full screen of windows as a tiling tree, layouts behind tabs: `Core.Board.New`, `Offer`/`Withdraw`/`Offered`/`Open`/`Standing`/`Close`/`Key`/`Alone`, pure `Lay`/`Least`/`Move`/`Beside`/`Swap`; `board:Show`/`Hide`/`Search`/`Has`/`Lift`/`Remove`/`Toggle`/`Forget`; a window of its own (`board:Own`/`Stand`/`Alone`), corners that size a panel as the mouse goes |
| `Icons.lua` | The icon chooser (`Core.Icons.Open`/`Close`/`Shown`): the game's icons by group, searched; a caller's chosen icon, its clear button and tick; the macros' picture window and Inventory's own categories |
| `Expand.lua` | A window that opens while the mouse rests on it: `Core.Expand.New`, `DWELL` 0.2, `LINGER` 0.5, `STEP` 0.1, `MARGIN` 4; `expand:Open`/`Close`/`Stay` |
| `Bar.lua` | A progress bar in the game's experience bar art: `Core.Bar.New(parent, options)`, `ART`, `CURVE` |
| `Neighbours.lua` | The known addons, the one file that names them: `Core.Neighbours.KNOWN`, `Window(key)`, `Format`, `Lock` |
| `Switches.lua` | Quick switches the modules offer: `Core.Offer(key, switch)`, `Switches()`, `OnSwitches(fn)`, `SwitchChanged` |
| `Ways.lua` | The way to a place, between a leader and a finder: `Core.Ways.Serve`/`Aim`/`Ahead` (Navigation serves; nobody asks since Speed Leveling's arrow points straight again, 2026-11-07) |
| `Sight.lua` | Herbs and ore in sight now: `Core.Sight.Serve`/`Nodes` (Navigation's Found, for Speed Leveling's detours) |
| `Spellbook.lua` | What a spellbook shows beyond the game's spells: `Core.Spellbook.Serve(module, offer)`/`Offer`/`Changed`/`Watch` (Abilities' spells still to learn, Home and menu lines in Combat's book; the offer's parts in the file's header) |
| `Stats.lua` | The stats' short words: `Core.StatWord`, `StatLine` |
| `Upgrade.lua` | Whether an item would make the character better: `Core.Upgrade(link, id)`, `WeighWith(fn)` |
| `Bindings.lua`, `Bindings.xml` | `BINDING_HEADER_SANEUI`, `BINDING_NAME_SANEUI_OPTIONS`; the key `SANEUI_OPTIONS` → `Core.Config.Open`; a module's keys stand in the same section |
| `Demo.lua` | `/sane window`: a panel to try what Core gives every window (`reset all` → `Window.ResetAll`) |
| `Data/Steps.lua` | The scheduler of all long work: `Core.Steps.Run`/`Stop`/`Check`/`Fresh`/`Spend`/`Running`/`Jobs`/`Paused`; 5 ms and a quarter of a frame at most, nothing while `Core.Restricted()` |
| `Data/Codec.lua` | Makes `Core.Data`; a set's row into a record and back: `Data.Codec.Decoder`/`Encoder`/`Build`/`Versions`; never raises, never runs what it reads |
| `Data/Data.lua` | The sets: `Data.Set(name)` handles, `WhenReady`, `Prepare`, `Saved`, `Game`, `Retell`, `Sharing`, `Learn`/`Learned`/`Unlearn`, `Add`, `Tampered`/`frozen` (tests); `SAVED`, `APART`; `/sane data` |
| `Data/Map.lua` | What the data puts on a map: `Data.Map()` → `On(map)`, `Spawns(key)`, `OnChange` (Spawns, Places, Travel) |
| `Data/Ships.lua` | Boats' and zeppelins' timetables, their realm times learnt: `Data.Ships()` → `Table`, `Next`, `Aboard`, `Near`, `Seen`, `OnLearn`; `Ships.Now`/`Timetable` |
| `Data/Trips.lua` | The trip underway (flight, boat, zeppelin, tram): `Data.Trips()` → `Now`, `CanLand`/`Land`, `NearTram`/`TramNext`, `OnChange` |
| `Data/Teleports.lua` | Where a teleport of *Travel* brought the player, learnt: `Data.Teleports` (`LOOK`, `WAIT`, `LEAP`) |
| `Data/Characters.lua` | What the account's characters have (`SaneUIData_Characters`): `Data.Characters`/`Character`/`Items`/`Worn`/`Count`, `CharactersStamp`/`OnCharacters`, `Forget` |
| `Data/Wire.lua` | Sane UI's addon messages, one prefix: `Core.Wire.Listen`/`Send`/`SendBlock`/`ListenBlock`, `Waiting`, `Drop` |
| `Data/Guild.lua` | The guild's records (`SaneUIData_Guild`, quiet until `Guild.Start`): `Data.Guild.Roster`/`Member`/`History`/`Record`/`Records`/`Publish`/`Rights`/`Watch`/`Sync`/`OnChange` |
| `Data/Confirm.lua` | What the game confirmed of unverified data, shared: `Data.Confirm`/`Confirmed`/`ConfirmedParts`/`OnConfirm`/`Share`; `Data.Confirmations` |
| `Data/Check.lua` | What the game told compared with a set field by field: `Data.Check(set, key, told)`; `Data.Checks` |
| `Data/Tally.lua` | What play counts per build period: `Data.Tally.Loot`/`Drop`/`Visit`/`Point`/`Cell`, `Of`/`Read`/`Counts`/`Keys`/`All`/`Id`/`Bundle`/`Sent` |
| `Data/Drops.lua` | How often things come, for every view: `Data.Drops()` → `Of`, `Rare`, `Chance`, `From`, … |
| `Data/Found.lua` | The discoveries and their chat line: `Data.Discovered`, `Data.Found(fromDay)`, `Data.Discoveries.Prices` |
| `Data/Watchers.lua` | Core's watchers: creatures, things, mailboxes, crossings, bosses' loot and casts, items' stats: `Data.Watchers` |
| `Data/Quests.lua` | The quest watchers (offered, taken, worked on, handed in): `Data.QuestWatch`, `Looted`, `Wanting` |
| `Data/Loot.lua` | Every loot window counted (corpses, skinning, pockets, nodes, fishing, where): `Data.Loot` |
| `Data/Facts.lua` | Creatures, services, vendors' goods, spells, tooltips' items compared: `Data.Facts` |
| `Data/Rhythm.lua` | An item's price with the clock, one line per item: `Data.Rhythm.Seen`/`Sold`/`Watched`/`Usual`/`Stretch`/`Read` |
| `Data/Prices.lua` | The one door to auction prices: `Data.Series("Prices")` → `Low`/`Last`/`Range`/`Outlook`/`Under`/`Usual`/`Scanned`/`OnSale`/`Stamp`/`OnChange`; `Prices.House`/`Within`/`See`/`Take`/`Heard`/`Forget`/`Account` |
| `Data/Fees.lua` | What the house takes, on `Prices`: `Cut`/`Sale`/`Deposit`/`Post`/`Step`/`PostAt`/`Later`/`Limit`/`Route`/`RouteUsual`/`Trip`; the client's own rates |
| `Data/Scan.lua` | The full scan while the house is open (`SaneUIData_Market`, the addon `SaneUI_AuctionData`): `Data.Scan.State`/`OnChange`/`Start`, `INTERVAL` 960 s |
| `Data/ScanBar.lua` | The scan's bar under the game's auction house window (`Core.Bar`) |
| `Data/Relay.lua` | A scan shared with the guild and the group (have, want, blocks, ask): `Data.Relay.Offer`/`Told`/`Block`/`ForgetAll` |
| `Data/Bundle.lua` | Counts and discoveries shared every 15 min (`SaneUIData_Shared`): `Data.Bundle.Note`/`Block`/`Voices`/`Each`/`Forget`, `Data.ForgetShared` |
| `People.lua` | Aliases and notes of players (`SaneUIDB.modules.Core.people`, the game's player menus): `Core.People.Key`/`Alias`/`Note`/`Shown`/`Set`/`Watch` |
| `Objectives.lua` | What is still to do about a creature for a quest in the log: `Core.UnitQuest(unit)` |
| `Inspect.lua` | A player's item level and talents, paced: `Core.Inspect.Level`/`Talents`/`Watch`, `GAP` 2 s |
| `Sync/Sync.lua` | `Core.Sync`: `GROUPS`, `Part`/`parts`, `PartKept`/`KeepPart`, `Kept`/`Keep`, `Capture`/`Give`/`Moved`, `OfferReload` ([sync.md](sync.md)) |
| `Sync/Data/Pages.lua` | `Sync.PAGES`, made by `dev/tools/sync-pages` |
| `Sync/Layout.lua`, `Addons.lua`, `Keys.lua`, `Chat.lua` | The parts `hudLayout`, `addons`, `keyBindings`, `ownChannels`/`chatFrames` |
| `Sync/Game.lua` | The page parts, Graphics/Audio/per-character CVars; `Sync.SetCVar`, `Lend`/`Return`/`Value`/`Settable`, `Leave` (a CVar another part keeps) |
| `Audio.lua` | Sound profiles per game account (`SaneUIDB.modules.Core.audio`), the last one set at each login: `Core.Audio.KINDS`/`Kinds`/`Names`/`Current`/`Use`/`Get`/`Set`/`Changed`/`Save`/`Load`/`New`/`Add`/`Delete`/`Watch`; its CVars `Sync.Leave`'s |
| `Settings/Settings.lua` | `Core.Config`: `Fill`/`Open`/`Show`/`Refresh`/`RefreshSoon`, `Kind`/`Hidden`/`Free`/`Getter`/`Setter`/`Enabled`; `Core.pages`, `Core.frames`, `Core.Tabbed`; `/sane options`; the compartment click |
| `Settings/Panel.lua` | Canvas parts from the game's templates: `Config.Panel.Header`/`Tabs`/`TabbedFrame`/`Scroll`/`Box`/`Check`/…, `Page`/`Refresh` |
| `Settings/Tabbed.lua` | A module's page in tabs from its descriptions: `Config.BuildTabbed(page, name, onPage, title)`; its own search (`Core.Fuzzy`) and *Defaults* |
| `Settings/Screen.lua` | The options over a full screen (the title bar's cog): `Config.Screen`, `STRATA` DIALOG |
| `Settings/Profiles.lua` | The page *Profiles*: `Config.BuildProfiles(page)` |
| `Settings/Synced.lua` | Its tab *Game settings*: `Config.AccountTab` (a box per `Sync.GROUPS` entry) |
| `Settings/About.lua` | The page *Sane UI*: `Config.About.LINKS`/`KINDS`/`ShowLink`/`Report`/`Open`/`Fill`; `/sane feedback` |
| `Settings/Data/CVarLabels.lua` | The CVars' labels, by `dev/tools/cvar-labels` |
| `Settings/CVars.lua`, `CVars.xml` | The tab *CVars*: `Config.CVarsTab`, `Config.CVars.All`/`Info`/`Shown`/`Set`/`Keep`; `SaneUISettingsCVarsTemplate`, `SaneUISettingsCVarRowTemplate` |
| `Settings/Banner.xml` | Our list row templates: `SaneUISettingsBannerTemplate`, `SaneUISettingsEntryTemplate` (a box to type into) |

Settings and Sync are no modules (no `SaneUI.Settings`/`SaneUI.Sync`, no TOC of their own); they hook Core's
events themselves, after Saved's and Profiles' handlers (TOC order).
Modules register via `Core.NewModule(ADDON, name, ns)` in their first file.
Core dispatches `OnLoad` on that addon's `ADDON_LOADED`, then `OnLogin` on `PLAYER_LOGIN`.
A module arriving after login gets both steps immediately; one that stood down, in whichever step or at whichever
door, gets no further step. Saved data is available from `OnLoad`; `Core.class`, `charName`, `realm`, `charKey`
from login. Character identity is the GUID (first names can be shared), with name-realm as the fallback; Profiles
keys a character by its GUID, else `SaneUICharDB.key`. Forever names are first name + surname (`UnitName` returns
both): show players with `Core.FullName(unit)`; `charName` is the full name. Any other player is keyed, compared
and shared by `Core.PlayerKey(unit)` / `Core.PlayerKeyOf(text)`: Forever `First Surname` (realm dropped,
regionally unique; never either part alone, nil without the surname), Retail `Name-Realm`; `Core.Surnames()` tells
which (Doc/guides/data.md, *Players*).

## Shared contracts

- `Core.On(event, fn)`: one shared event frame; event registration is lazy and skips an event this client lacks
  (noted in the log). A listener's failure goes to `Failed`: the module whose `AddOns/<folder>/` its error text
  names first stands down (`StandDown`), Core's own is reported under the event name; other listeners still run.
- Error doors (hard rule, `Doc/guides/addon-standards.md`, section 10): events, `Core.Later`, module start (`OnLoad`
  failure: not started further), `module.Guard(fn)` (closure for scripts/hooks/timers: no-op once `off`, all results
  passed) and `Core.Guard(label, fn)` (Core's own scripts: the owner found by the trace stands down, else
  `Report(label)`, retried next call) all go to `Failed`; `GameError` (hook on `ScriptErrorsFrame.DisplayMessageInternal`)
  catches what slipped past (messageType 1 = warning: noted only). Door errors also reach `CallErrorHandler` only
  when the CVar `scriptErrors` is on (the `showing` flag stops the echo). `module.On` is `Core.On`: listeners keep
  running after `off`.
- `Core.Safe(label, fn, ...)`: catches/reports failure (`Core.Report`: one chat line per label, "problem in <label>,
  noted in the error log (/sane errors).", unless *Errors in chat* is off), returns only the first result. Module `Safe`
  prefixes its name. `Listen`/`Fire` are module-local messages, with each listener safe.
- `module.Guarded(fn, ...)`: on failure, `StandDown` sets `off` once, calls `GiveBack`, reports via
  `GIVEN_BACK`. Later guarded calls do nothing.
- `Core.Secret(v)` / `Plain(v)`: test secret values / return nil for them. `Ask(fn, ...)` calls via
  `pcall` and returns up to three plain answers; a missing or failing function gives nils.
- `Core.Later(fn, delay, label)`: coalescing request function; only one pending timer. `fn` runs behind the
  door guard (`Failed`, under `label` when given, else "later": Core's own laters name theirs, so each failure is told once). `Points` / `Repoint` preserve anchors, including nil holes.
- `Core.Options(name, descriptions, hooks)`: describe at file load (hooks: a table of `changed`, `replaced`, `moved`,
  `capture`, `version`/`upgrade`, `game`, `tabs`, or only `changed`); returns the live settings once Core is loaded.
  `Core.Settle` makes a copy right whenever it comes into use (upgrade by `version`/`upgrade` first, then
  kinds/choices/validate/ends; keys no description has go, `_`-keys stay). `Core.Set(name, key, value)` for writes
  from menus/commands (checks, tells, reload offer, page refresh). `Store(name)` returns the module's store;
  `Character(name)` returns `modules[name].chars[charKey]`, annotating name/class.
- `Core.AfterCombat(key, fn, ...)` runs now or after the fight (the same key merges, the last arguments win);
  `Core.Locked(frame)`; `Core.Restricted()` (combat or `Core.RESTRICTIONS`, kept from
  `ADDON_RESTRICTION_STATE_CHANGED`'s payload, asked once at login); `Core.Off`, `Core.OnUnit`/`OffUnit`;
  `ADDON_ACTION_BLOCKED`/`FORBIDDEN` of ours go to the error log (`Report("blocked action")`).

Saved shape (v2): `SaneUIDB = { version, modules = { <Module> = { chars = { [key] = ... }, ... } }, profiles = { [name] =
{ <Module> = settings } }, characters = { [key] = { name, realm, class, profile, before } }, newProfile, presets, errors,
log }`; per character `SaneUICharDB = { settings, key, version }`. Each copy of a module's settings carries `_version`.
Errors keyed by label contain `text/count/when` (`ERRORS_MAX` 100 labels, the oldest goes); the chronological log
(`LOG_MAX` 100) also holds label, version and build; consecutive identical failures coalesce. The client writes saved
variables at reload/logout: `saneui showerrors` (`dev/tools/errors`) reads them after that.

## At rest out of sight

`Core.Rest` (`Rest.lua`) serves your unit frames and action bars (Combat) and the quest log (Navigation), which may
not know each other. Traps: the game hides your own health from addons at all times, not only in a fight, so `UnitHealth`
is never compared: health counts as not full for `Rest.HEALTH` seconds after `UNIT_HEALTH` (and after a fight or a
loading screen, which say nothing); a number the game does tell is used. Only alpha changes, and by one clock on a
frame of ours: alpha may change on protected frames in a fight, and it leaves them the mouse, which is how the mouse
is seen on them. A protected frame made out of sight is not made harmless: its clicks stay. `IsMouseOver` and
`IsVisible` may answer a secret (`SecretWhenAnchoringSecret`, the aspect Shown), and testing one in a condition is an
error: through `Core.Plain` every time, hidden meaning no.

## Profiles

Saneroki, 2026-10-17; the standard profiles 2026-10-30; off at first 2026-11-15. `SaneUIDB.profilesOn` (`Profiles.Enabled`,
`SetEnabled(on)`; the page's switch, `/sane profile on|off`, Onboarding): nil on a fresh install (never on), true on,
false turned off with the profiles kept. Off: `Want()` is nil for everyone (own settings), `Register` gives new lines
`OWN`, `Mend` makes no standard profile, `List()` is `{ OWN }`, `Settings(name)` nil (the save window saves to no
profile), Sync writes and reads nothing and `Sync.Moved` gives no defaults; a line still naming a profile copies that
profile's settings into its own at its load (`TakeOwn`). `TurnOn` the first time (`profilesOn` nil or Accountwide empty):
Accountwide = `Snapshot()`, the live tables re-homed into it untold (`Rehome`), Sync's session table reset and filled by
`Sync.Take` (`given` = true, `Sync.FindNow` finds the CVar parts' names at once, then `Capture`; nothing written),
`Standard(Speedleveling)`, `Unsaved.Moved` last; else `Move` onto the Accountwide kept. `TurnOff`: `Capture`, the
profile's settings of modules not on today copied into own, `Rehome(nil)`, Sync not told. Both wait for the save window
(`Turn`); `Use(name)` of a profile while off turns them on first (`Turn(true, name)`); `SetCharacter` of this character
is `Use`. Version 3 (`Upgrade`; the v1 step `First` only below 2): `profilesOn` = true when the file is a player's
(`Used`: a character line, or a profile holding something). Once on, each character uses a profile: *Accountwide* (new characters'
unless `newProfile` names another; given no preset) or *Speedleveling* (both always there while on, `Standard`: a missing one copied from Accountwide, its
preset given once per `Presets.VERSION`, `SaneUIDB.presets`), or one
the player made; or *Character specific* (`Profiles.OWN`): no profile, its own settings in `SaneUICharDB.settings`, the
game's left to the game (Sync's live table is a session table, hook `game = true`; `Profiles.On()` is false, `Give` and
`Capture` do nothing, `Sync.Moved` puts the CVars back to the game's defaults). `characters[key].profile` nil means
Accountwide; `before` the last profile that was not Speedleveling (`SetLeveling`).

Each module's live table (`Core.Settings`) is stored in exactly one place, the one in use (`Holder`); the game writes a
table once, so it is never also kept elsewhere (`store.options` is a metatable alias). `Move(to)`: `Capture`, copy the
live tables into the old place, wipe each and fill it from the new place (`Core.Settle`), tell (`changed` per differing
key by `Core.Same`, or `replaced`), then `moved` (Sync gives the game's settings), `Window.PlaceAll` (each profile keeps
its windows' places), `Core.SwitchChanged`. Load: Core's own `ADDON_LOADED` upgrades and mends the file (`Upgrade`, `UpgradeCharacter`, `Mend`;
the old switch Accountwide is dropped), registers the key (the GUID, else `SaneUICharDB.key`) and binds every
described module; later modules bind in `Core.Options` (`Arrive`). `PLAYER_LOGIN`: a different key registers and moves. `PLAYER_LOGOUT`: `Capture()` only, so logout
listeners see the right settings in any order. The v1 shape, brought over once (local `First`, run by `Upgrade` below version 2):
account options (and a parked `account`) → *Accountwide*, `store.version` → each copy's `_version`, a character's
profile kept only with `autoLoad`, `newCharacters` → `newProfile`, the rest dropped. Profile names unique
case-insensitively (`MAX_NAME` 32); Export/Import through `Core.Serial` (`{ kind = "Sane UI profile", version, name,
settings }`).
Pages: `Core.pages.top` (logo only), `.Profiles` (canvas: frame `Core.frames.Profiles`, built in its first `OnShow` by
`Config.BuildProfiles` with tabs from `Panel.lua`), `[Core.name]` (General), `.Appearance`, then `[module]` titled by
`module.title`: a vertical page (proxy settings reading `Core.Settings` at each call, writing through `Core.Set`), or a
canvas page of our own (`Core.frames[module]`, `Config.BuildTabbed`) when one of its switches names a tab or its
description has `tabs` (`Core.Tabbed(name)`; Social's do). Only `SaneUI[name]` modules get a page, none for the other
game's (`module.elsewhere`); Sync's switches, described under `Sync`, are shown by the tab *Game settings*.
`Config.Refresh` re-notifies controls, which only read then (Core already told the modules).

**Unsaved changes (built 2026-11-09, `Unsaved.lua`, `Settings/Save.lua`):** a change still counts at once; a change made
while a menu is open (the game's `SettingsPanel`, `AddonList`, Edit Mode, a full screen's options view) is compared with
the last save (a copy of every live table taken when a menu opens with nothing waiting; `Sync.Capture` first) and the
save window asks: *Yes* writes the differing paths into the profiles ticked, *No* puts the last save back through
`Profiles.Put` (= `Fill`: modules told, Sync's `moved` writes the game's). Traps: a menu counts only while its frame is
shown (the tests run `SettingsPanel`'s `OnShow` by hand with it hidden); only Sync's capture is read (another module's
`capture` would change its settings at each look); `Profiles.Use`/`SetCharacter`/`Delete` return false while changes
wait (`Answer`), so a caller that tests the result says why; unanswered at `PLAYER_LOGOUT` the changes are saved as
*Yes* saves them (2026-11-10, was: put back, which made every change pop back at a `/reload`), only an unticked profile
in use gets the last save back (Unsaved.lua's listener comes after Profiles' capture, by the TOC's order). A
`hooksecurefunc` on a global the game handed to a button in its `OnLoad` (`AddonList_OnOkay`) never runs on a click.

## Options trap

`Settings/Settings.lua` registers **empty pages at login** (`PutUpPages`), because Blizzard chooses whether to show
its AddOns tab when the options first open. Registering pages in a late-loaded module loses that tab for the session.
`Config.Fill` (`SettingsPanel`'s `OnShow`, `/sane options`) fills the existing vertical `Core.pages` once; a canvas
page (Profiles, a module's tabbed page) stays an empty frame until its first `OnShow`, then builds its controls with
`Panel.lua`. Vertical pages use `Settings.RegisterInitializer` (`Settings.Create*Initializer`,
`CreateControlInitializer` for our entry row). The game's search does not reach a
tabbed page, so those search themselves (`Tabbed.lua`, `Core.Fuzzy`). Opening the options in combat prints a line
and queues `Config.Open` with `Core.AfterCombat("options", …)`: they open when the fight ends.

## Window contracts

`Core.Window.New(frame, options)` supplies movement, optional sizing/docking/skin and the kept placement (its head
comment lists every option and method). The caller builds content in `window.inside`, then calls `window:Place()`.
The kept place `{ x, y, width, height, dock, full, native }` uses the top-left corner measured from UIParent's
bottom-left; a zone name wins over coordinates; `full`, `native`, `tab`: what it was left as (`Remember`/`Recall`;
`Remember` makes no place table for a nil value). It is kept in the profile in use (`Held`), `Window.PlaceAll()`
puts every window there when the profile changes. Every window's build, states and taint rules: [Doc/guides/windows.md](../guides/windows.md).
Docked windows grow away from their edge; grip corner and skin follow. `Dock.Anchor` hangs a window on UIParent's
point of its zone (offset only by its `insets`), so it stays at its edge when the UI scale or the game window
changes; a zone holds one window at a time (another shown there stands clear, `Clear`).
A kept size is cut to the screen's; when the screen's size or the UI scale changes (`DISPLAY_SIZE_CHANGED`,
`UI_SCALE_CHANGED`, one `Core.Later`), every shown window at rest is placed anew and one that stands full is told
`docked` once. `window:Reset()` clears the place, keeps `full`, `native` and `tab`. In a fight a window holding
protected frames is not moved, shown or hidden (`window:Locked()`): its placing waits for the fight's end, its close
and Esc wait (`Core.AfterCombat(window, ...)`), and Esc is the game's meanwhile. `window:Escapes(on)`: Esc given up
while a view over the window takes it (`Settings/Screen.lua`), taken again.
`window:Open()` answers `"native"`, `"ours"` or `"locked"`; `window:Native(on)` chooses the game's window or ours.
`options.docked(zone)` is called (guarded) on placement, including the first; `Moved`/`Sized` run once per drag
(`window.moving`/`sizing`), so Edit Mode closing mid-drag and the drag's own stop do not let go twice.

For Blizzard windows use `Window.Mover`/`Sizer`, keeping state externally. `usable()` gates handling;
`started`/`stopped` callbacks let the caller preserve state. `Dock.REACH = 60`; `Find` is pure.
`Expand.New` opens to its configured size after the mouse rests on it (`DWELL`), closes after `LINGER` away, optional
hot `corner` (`hover = false`: never by the mouse); the size moves as its kind of motion says (`Motion.KINDS`), the
general one or the window's own; its `Core.Hover` watch runs only from the mouse's coming until it is closed; a held
left button prevents closing; `Stay(true)` keeps it open and stops the watch.

Tests: `dev/tests/core.lua` and `window.lua`.
