# Sane UI: Core

**Status:** written and tested offline · **Since:** 2026-10-14 · **Addon:** `SaneUI`

## TL;DR
The main addon, the one every module needs: chat lines, game events, error catching, the list of modules,
the `/sane` command, the saved settings of all modules (each character's own at first; with the profiles turned on,
in profiles: *Speedleveling*, *Accountwide*, *Character specific*, your own), Sane UI's options (`Settings/`), Sync, which keeps the game's own per-character settings with
Sane UI's (`Sync/`), and what every window can use: moving, sizing,
docking to a screen edge, round corners, opening while the mouse rests on it, filling the screen, tabs
in the game's style, Esc, Edit Mode's dialog, and a progress bar. It does nothing you can see by itself,
but for a window to try those with (`/sane window`).

## How to use
- **In the addon list** it is the line *Sane UI*. The modules stand under it (*Social*,
  *Abilities*, *Tooltips*): tick or untick each one by itself. With *Sane UI* itself unticked no module loads.
- `/sane` says which modules are switched on and lists their commands. `/saneui` is the same.
- **Alias and note:** right click a player's name (in a chat, the friends list, the guild, the target or
  a group frame): under the game's own lines are *Set Alias* and *Set Note*. An alias is a name of your own
  for that character, shown by Sane UI in place of theirs (in its chat, friends list and tooltips): give
  all five alts of one friend the alias *Saneroki*, and each shows as *Saneroki*. A note is shown in the
  player's tooltip. While a player has one, *Remove Alias* or *Remove Note* takes it away. Kept for your
  account, never sent to anybody.
- **Sound profiles** (`Audio.lua`; their line is in Navigation's satchel): the game's five sounds (All sound,
  Music, SFX, Dialogue, Ambience), each on or off with its volume, kept under a name: *All sound on*, *Music off*,
  *Music and Ambience off* and *All sound off* at first (Saneroki, 2026-11-04), more by *New*. Choosing one sets it at once. Each game account keeps its
  own profiles and the one it used last, and sets that one again at each login, so two clients of two accounts on
  one computer can sit on different profiles at the same time (the game itself keeps one file of these settings
  for the whole installation, written by the client that closes last). The login screen sounds as that file says.
- `/sane errors` lists the error log, one line per problem; `/sane errors clear` empties it. When something
  fails, one line in chat says where (*problem in ..., noted in the error log*), once per kind of problem.
  A module that fails steps aside: what it stands in for is the game's own again until the next `/reload`
  (`/sane` lists it as *stopped*). The game's own error window shows Sane UI's errors only when it shows Lua
  errors at all (`/console scriptErrors 1`).
- **The error log.** Every problem is also kept in a log, in the order it happened, with the place it
  happened. It is in the saved settings file (`WTF/Account/<account>/SavedVariables/SaneUI.lua`, under
  `log`), which the game writes at a `/reload` and when you log out. `dev/tools/errors` prints it.
- `/sane arrange` moves and sizes Sane UI's windows as Edit Mode does, only in a game without Blizzard's Edit
  Mode (there: Esc > Edit Mode).
- `/sane window` shows a small window to try what every Sane UI window can do, a panel as the spellbook
  will be (again: hides it; `/sane window reset`: its first place; `/sane window reset all`: every window of
  Sane UI at its first place and size, the chat's too):
  - **Title bar:** its name at the left, its buttons at the right. Drag the title bar to move it, at any
    time (a window docked at a screen edge only in Edit Mode). A window whose content can be searched has a
    magnifier before its name: a click there opens a search box over the bar (this one has nothing to
    search). A click anywhere on a panel brings it to the front, over the other panels; Esc closes it.
  - **Move in Edit Mode** (Esc > Edit Mode), as the game's own frames: there it shows Edit Mode's blue box
    (its name on it while the mouse is on it); drag the box. Sizing is only there: a window that can be
    sized has its grip only in Edit Mode. A click on the box selects it, as one of the game's frames: the
    box turns yellow and a small dialog in Edit Mode's look names it, with *Reset To Default Position*
    (its first place and size). With Edit Mode's *Snap* on, a free window let go near a line of its grid
    (or the screen's middle) lines up with it.
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
    button, to come back. A module can put its own buttons before them (this one: *Start again*, the bar
    back to nothing). Filling the screen, every window has the title bar at its top.
  - **Open:** rest the mouse on it a moment and it opens; take the mouse away and it closes a moment later.
    Open, it has two tabs under its title bar, in the game's style (as the spellbook's): *Window* explains
    it, and *Keep open* keeps it open until unticked; *Bar* holds the bar. The tab last chosen is the one
    shown the next time.
  - **The bar**, in the art of the game's own experience bar: *Add* fills it a step at a time
    (the fill rises to its new length with the game's flare at its end), a paler part ahead of the fill
    marks what is still to come, and full it starts again from nothing. It stretches as the window opens.
  - **Fill the screen:** docked, push the mouse against that screen edge (the game window's very edge, where
    the window touches it; docked in a corner, all the way into that corner): it grows to fill the whole screen, on a background that hides the game
    as much as set (half, in solid black, at first), and nothing behind it takes the mouse. On the way its
    corners start as round as the window's and flatten, so the full screen is square. In its top right
    corner the dropdown *Classic windows* lists the game's own windows it stands for (a window that has
    some; this one has none): one chosen, the window goes back and the game's own comes. Move away and push
    there again: it goes back to its size and its zone. One push is one change: the mouse resting in the
    corner does nothing more until it has gone some way from it. What the window holds fades out on the way
    and comes in once it stands; a window whose content can go with it (the map) keeps it in sight, growing
    and zooming with the window. Each such window has a section *Expand window*
    in its settings: whether it can, how it moves, the background's opacity and texture, and how round
    the small window's corners are: *Corner radius* (0 to 100 % of half the window's shorter side at rest,
    a tenth at first; at 100 % a square window is a circle) and *Don't round corners on screen edges* (on;
    off: every corner is round, also on the screen's edges). Full, it is square either way.
- **Keys:** in the game's key bindings (Esc > Options > Keybindings) a section *Sane UI* has a key for
  Sane UI's options (none set at first), and a key for each module that has one (Social: the chat window).
- **The options** (Esc > Options > AddOns > Sane UI, see [Settings' README](Settings/README.md)): *Sane UI* itself shows only
  its logo; under it are Sane UI's own pages *Profiles*, *General* and *Appearance*, then a page per module
  (*Social*, *Abilities*, *Tooltips*). On every full screen the cog in its title bar shows them there too
  (*General*, *Appearance* and the modules' pages, the full screen's own module first); the question mark beside
  it will hold a tour of that full screen.
- **General switches:** on the page *General*: *Errors in chat* (on): a line in chat for each kind of problem.
  On the page *Appearance*, under *Windows*: *Animation type* (Glide): how every window docked to a screen
  edge fills the screen and goes back, and how a window opens while the mouse rests on it: *Glide* (quick,
  settling softly), *Swing* (a little past, then back), *Even* (a gentle start and end), *Instant* (no motion). A window can have its own type,
  in its section *Expand window* (Social, tab *Appearance*), which can be *Use global type*: this one.
- **Profiles,** on the page *Profiles* (the options show them; `Profiles.lua` keeps them), Saneroki, 2026-10-17:
  - **Off on a fresh install** (Saneroki, 2026-11-15: "the whole profiles should be disabled by default and can be
    activated in the settings or during the onboarding procedure"): every character keeps its own settings (*Character
    specific*), Sync writes nothing into the game and gives no defaults, no preset is given. The page shows only the
    switch *Share settings between characters* at its top and a line saying why the rest is not there.
    Turned on (that switch, `/sane profile on`, Onboarding through `Core.Profiles.SetEnabled(true)`, or a profile chosen
    by name, the box *Speed Leveling* in the bags too), the first time, this character's settings as they are become
    *Accountwide*: a copy of Sane UI's and the game's as Sync reads them that moment (`Sync.Take`), nothing written into
    the game, no `/reload` offered. This character uses it, characters not seen yet start on the profile for new
    characters (*Accountwide* unless chosen otherwise), the others keep their own until moved on the page. Turned off
    (the switch, `/sane profile off`), the profiles are kept for later, every character keeps the settings it had as its
    own (this one at once, another at its next login) and the game's stay as they are. Saved settings from before
    (a character seen, or settings in a profile) count as on and stay as they were.
  - Once on, every character uses one of three standard profiles, or one you made. None is made for a character by itself.
    - *Speedleveling*: all of Speed Leveling's switches on but *Professions along the way* (Saneroki, 2026-11-05), our
      recommended CVars and some more that keep you moving (`Presets.lua`), the key E, and Economy's *Send by itself*: with
      *Send to banker* ticked, the mail to the banker is sent as the mailbox opens (Saneroki, 2026-11-09). The box *Speed Leveling* at the foot of
      the bags is this profile (`Profiles.SetLeveling`): ticked, the character uses it; unticked, the one it used before
      (`line.before`), *Accountwide* if it had no other.
    - *Accountwide*: made from the settings of the character that turned the profiles on (Saneroki, 2026-11-15:
      "Accountwide profile should be generated from the users current settings instead of my generic defaults"), none
      of our presets; every change shared by all the characters on it. Where every new character starts.
    - *Character specific*: no shared profile. Sane UI at its defaults and each character keeping its own, the game's
      settings left to the game, as a fresh install. A character turning to it gets the game's default CVars back
      (they stay in the profile it left).
  - **What Speedleveling sets** (`Presets.lua`, Saneroki, 2026-10-30; Accountwide no longer, 2026-11-15): the game's CVars as single
    CVars of Sync's (`named`, ticked in the tab *CVars*), written last at the login. 115 frames a second in front,
    behind and as a target, the camera out as far as it goes, the finest screenshots, how far the world shows, its
    grass, weather, shadows and ambient occlusion at their finest, loading screens that do not wait for what is not
    needed at once. Never water detail: water 3 crashed Forever's client in the Ruins of Lordaeron, and Sync never
    sets, reads or keeps it (`Sync.Barred`, Saneroki, 2026-11-06). Speedleveling also
    takes off the grey blur at death, the tutorials, the quest text word by word and the voice on errors, and takes
    you down when you cast in the air. A CVar one of the two games lacks is passed over. Given once for
    each `Presets.VERSION`, and only what the profile does not have: a player's change stays, and what they unticked
    stays out until the version is raised. The game's own combat text is no CVar of the profiles: Nameplates switches
    it off while its own shows and gives it back when it stops.
  - A profile is a named set of the settings of every module, where the windows stand, the bags' layout, and the game's
    own (its options, CVars, key bindings, Edit Mode layouts, chat windows, addons switched on: as far as the tab
    *Game settings* ticks them): the game's are set from it a moment after a character comes into the world, and read
    back into it when the character leaves (logout, `/reload`). What is no setting (a module's `Core.Store`: guides
    added, prices, notes on characters; also the full screen's layouts and the quest log's sort) is the account's, the
    same for every profile.
  - *This character:* the profile it uses (choose another: its settings, Sane UI's and the game's, are that
    profile's at once). *New* makes a copy of the settings in use under a name and uses it; *Rename*, *Delete*
    (every character that had it uses *Accountwide*); *Defaults* sets Sane UI's settings of the profile in use
    back to their defaults (the game's stay); *Copy from* takes another profile's settings; *Export* shows the
    profile as a line of text to copy, *Import* makes a profile from one (of the single CVars it keeps, only
    those the game's options set). The three standard ones cannot be renamed or deleted. `/sane profile` lists the
    profiles, `/sane profile <name>` uses one, `/sane profile on` and `off` turn them on or off.
  - *Characters:* every character seen on the account, each with its profile (for another character it counts
    at its next login) and *Forget* (its line and what Sane UI keeps for it: for a character deleted or moved).
    The first line, *New Characters*, is the profile a character Sane UI has not seen yet starts with: *Accountwide*
    at first.
  - Every change on any options page goes into the profile in use, for every character that uses it. Nothing
    is copied at a logout: the settings live in their profile, and only the game's are read into it.
  - **The save window** (`Unsaved.lua`, `Settings/Save.lua`; Saneroki, 2026-11-09): a change made in a menu (the
    game's options with Sane UI's pages, its own pages, key bindings and the CVar list; Edit Mode; the addon list;
    Sane UI's options over a full screen) counts at once, and a window beside the menu asks *Save the changes?*
    until it is answered, the menu closed too: what changed since the last save, *Save to* (a tick per profile,
    the one in use at first, the others as ticked the last time), *Yes* (saved into every profile ticked; the one
    in use, unticked, gets its settings back) and *No* (every change since the last save taken back, the game's
    too). The page Profiles has the same as *Save* and *Load last settings*. Another profile chosen (also the box
    *Speed Leveling* in the bags) waits for the answer. A /reload or logout unanswered saves the changes as *Yes*
    does, the addon list's *Reload UI* and the *Reload* Sane UI offers too (Saneroki, 2026-11-10: a change must not
    pop back at a /reload): only *No* and *Load last settings* take changes back.

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
  | `SaneUIDB.modules.<Module>` | What that module keeps besides its settings: `Core.Store(name)`, from `OnLoad` on (`Core.StoreName(store)`: whose it is) |
  | `SaneUIDB.modules.<Module>.chars[GUID]` | Its notes per character: `Core.Character(name)`, from `OnLogin` on |
  | `SaneUIDB.profilesOn` | The profiles on (`true`), turned off and kept for later (`false`), or never on (nil: a fresh install) |
  | `SaneUIDB.profiles.<Profile>.<Module>` | A module's settings in a profile; `Accountwide` and `Speedleveling` are always there while the profiles are on |
  | `SaneUIDB.characters[key]` | Every character seen: `name`, `realm`, `class`, its `profile` (a name, *Character specific* for none; nil: Accountwide) |
  | `SaneUIDB.newProfile` | *New Characters*: the profile a character not seen yet starts with (nil: Accountwide; with the profiles off every new character starts on its own) |
  | `SaneUIDB.version` | The shape of these settings (`Profiles.VERSION`, 3) |
  | `SaneUIDB.saveTo` | `[profile] = true`: the profiles ticked under *Save to* besides the one in use (the save window, `Unsaved.lua`) |
  | `SaneUIDB.errors` | What went wrong (`Core.errors`), for `/sane errors` |
  | `SaneUIDB.log` | The same, every time it happened: the error log (`Core.log`) |
  | `SaneUICharDB` | Per character (`WTF/Account/<account>/<realm>/<character>/SavedVariables/SaneUI.lua`): `settings.<Module>` (its own, with *Accountwide settings* off), `since` (the `ownSince` they were made under), `key` (its key in `characters`, to find it before the login) |

- **Profiles (`Profiles.lua`).** Each module's settings live in one place only, the one in use: a profile,
  or the character's own (`SaneUICharDB.settings`, *Character specific*). The module holds that
  table for the whole session (`Core.Settings(name)`, also `Core.Store(name).options`, which is found through
  the store but never kept there).
  - **Moving** (`Move`): another profile used, *Character specific* chosen, the profile in use deleted.
    The modules that hold something of the game's bring it up to date first (`capture`); what each module
    holds stays in the old place as a copy of its own; the table it holds takes what the new place has
    (`Core.Settle` makes it right) and lives there now; each module is told what differs (`changed`, or
    `replaced` once), then `moved`. The options page shows it a frame later.
  - **At the load** (Core's `ADDON_LOADED`, before any module reads its settings): the place is the
    character's profile (its line's, if that is there, else *Accountwide*) or its own; with the profiles off always its
    own, and a line that still names a profile (the character was not played since they were turned off) takes a copy
    of that profile's settings as its own first (`TakeOwn`), then names *Character specific*. The character's
    key is its GUID, else `SaneUICharDB.key`; at `PLAYER_LOGIN` a character the game names only then (or
    another one) moves to its profile. A module's settings come into use when it describes them
    (`Core.Options`), from the place in use; a place that has none for it gives its defaults.
  - **At the logout** nothing moves: only `capture` runs (Sync reads the game's settings into the profile).
  - **Own settings** start at the defaults, as a fresh install, and stay the character's whenever it comes back.
  - **Where the windows stand** is kept in the profile too (`Core.general.places`, `Window.lua`'s `Held`, by module and
    key); what a module's store holds from before starts each profile off. `Fill` ends with `Window.PlaceAll`.
  - **Standard profiles** (`Standard`, in `Mend` while the profiles are on, and when they are turned on): *Speedleveling*
    is made once if it is not there: a copy of *Accountwide*'s, so that an account with settings loses nothing by using
    it, with `Profiles.PRESET` over it, which *Defaults* sets again. *Accountwide* is given no preset.
  - **On and off** (`SetEnabled`, `Turn`; Saneroki, 2026-11-15): turned on the first time (`profilesOn` nil, or
    *Accountwide* empty), *Accountwide* is a copy of the settings this character has now (`Snapshot`), the tables the
    modules hold live in it from then on (`Rehome`: nobody is told, nothing changed), Sync's session table is read
    from the game (`Sync.Take`) and *Speedleveling* is made; otherwise the character moves onto the *Accountwide* kept,
    as `Use` does. Turned off, the game's settings are read into the profile left (`capture`), the tables live in
    the character's own settings, with copies of the profile's for modules not on today (`Rehome`), and Sync is told
    nothing (no `ToDefaults`). With changes unsaved, both wait for the save window's answer; unanswered at a /reload
    or logout they are done then. `Use(name)` of a profile while off turns them on first.
  - **The game's settings** (Sync's, `game = true`) live in profiles only; on *Character specific* and with the
    profiles off they are kept nowhere (a table of the session) and Sync reads and writes nothing. Turning a
    character to *Character specific* while the profiles are on, what the last capture read goes back to
    `C_CVar.GetCVarDefault` (`ToDefaults`); turning the profiles off leaves the game's settings as they are.
  - **The first shape** (version 1: the account's settings in `modules.<Module>.options` or kept aside in
    `account`, profiles copied in and out with `autoLoad`/`autoSave`, `separate`, `perCharacter`,
    `newCharacters`) is brought over once: the account's settings are *Accountwide* (a profile of the player's
    called so keeps its under *Accountwide (old)*), a character's line keeps its profile where it loaded it at
    login, `separate` is *Accountwide settings* off (each character's own kept), `perCharacter` goes.
  - **Version 3** (`Upgrade`): `profilesOn` is true for settings saved before that are a player's (a character seen,
    or settings in a profile), so they work as they did; a fresh install starts with the profiles off.
  - `Core.Profiles`: `Enabled()` (the profiles on at all), `SetEnabled(on)` (the switch, `/sane profile on`/`off`,
    Onboarding), `On()` (this character uses a profile), `InUse()` (the profile in use, *Character specific* too),
    `List()` (Speedleveling, Accountwide, Character specific first; only Character specific while off),
    `Fixed(name)` (the three standard ones), `Create(name, from)` (a copy of the settings in use, or of
    profile `from`), `Use(name)`, `Rename(name, as)`, `Delete(name)`, `CopyFrom(name)`, `Reset()` (Sane UI's
    settings in use at their defaults), `Export(name)` (a line of text, `Core.Serial`), `Import(text, as)`,
    `Characters()`, `Character(key)` (`Profiles.NEW`: *New Characters*), `SetCharacter(key, name)`,
    `Forget(key)`, `Capture()`. A step returns true, or false and a line for chat saying why not. Names are up
    to `MAX_NAME` (32) letters, unique in any letter case. `/sane profile [name | on | off]`. For the save window:
    `Settings(name)` (a saved profile's table; none while the profiles are off), `Put(fill)` (the settings in use filled anew, as a profile used:
    `fill(module)` its new settings, false leaves it). With changes unsaved, `Use`, `SetCharacter` of this
    character, `SetEnabled` and `Delete` of the one in use wait for the answer (`Core.Unsaved.Wait`) and return false meanwhile;
    a /reload or logout unanswered does their lasting part (the character's line names the profile chosen, or the
    profile deleted is gone, for the next login). `Rename` and `Delete` move or drop the profile's tick under *Save
    to* (`Unsaved.Renamed`).
- **Unsaved changes** (`Unsaved.lua`, `Core.Unsaved`): the last save is a copy of every module's settings, taken
  when a menu opens with nothing waiting (`Open(menu, frame)`, `Close(menu)`: the game's `SettingsPanel` and
  `AddonList`, Edit Mode by `Core.EditMode.Watch`, a full screen's options view). While a menu is open a change
  is looked at at most every 0.3 s (`Soon`: `Panel.Refresh`, `CVAR_UPDATE`, `UPDATE_BINDINGS`,
  `EDIT_MODE_LAYOUTS_UPDATED`, `AddonList_Update`): Sync's capture reads the game's settings in, then each
  described setting that differs is a path into its module's settings (down into tables of names; a list, as the
  chat windows or a command's keys, counts as one), but where the windows stand and Sync's `from`. `Pending()`,
  `Changes()` (in words: *General: Errors in chat*, *Game settings: Controls*), `Targets()`, `Ticked(name)`,
  `Tick(name, on)`, `Any()`, `Save()` (each path written into every other profile ticked, Sync's only into one
  of this game; the one in use unticked gets them back), `Undo()` (`Profiles.Put` with the last save's values:
  the modules told, Sync writing the game's; an Edit Mode layout takes its own text again, `Sync.ExactLayout`),
  `Wait(words, fn, last)`, `Next()`, `Watch(fn)`, `Moved()` (another profile in use: a new last save),
  `Renamed(old, new)` (a profile's tick follows its new name; nil: deleted). At
  `PLAYER_LOGOUT`, after Profiles' capture: unanswered, the changes are saved as *Yes* saves them (Saneroki,
  2026-11-10), into every profile ticked; only the one in use, unticked, takes the last save's values, in the
  saved settings only (the game gets them at the next login, Sync's writing); a step that waited has its `last`
  done. A hook after `AddonList_OnOkay`
  would never run: the addon list's `OnLoad` gave its button the game's function itself, so no hook is needed
  or made (its Cancel resets the addons in its `OnHide`, which the look at its closing then finds unchanged).

- **A switch is described once,** by its module, while its files are read:
  `Core.Options(name, { { key, default, text, tip }, ... }, hooks)`, hooks a table (`changed(key, value)`,
  `replaced()`, `moved()`, `capture()`, `version` and `upgrade(values, from)`, `game`, `tabs`: tabs the module
  fills itself after its switches', `{ name, build = function(child) return height end }`) or only `changed`.
  Core gives it its default and keeps it. The options (`Settings/`) show it as a checkbox and call
  `changed(key, value)` after a tick; Core calls it too when a profile changed it. A number is described the
  same way with its ends (`min`, `max`, `step`) and is shown as a slider; one of a few with its `choices`, as a
  dropdown. `header` (and `headerTip`) starts a section of the page above the switch. `tab = "Appearance"`
  makes the module's page one of our own in tabs, as Profiles (`Core.Tabbed`; the frame is
  `Core.frames[module]`), the switch in that tab, those that name none in a first tab *General*;
  `parent = "key"` puts it under an earlier switch, greyed out while that one, or one above it, is off;
  `inline` draws a number on its parent switch's line; `unit` follows its value; `validate`, `reload`,
  `button`, `multi`: see `Saved.lua`. Core's own switches name the page they are on with
  `page = "Appearance"` (none: *General*). One without `text` has no control but is kept with the settings and
  in profiles (Sync keeps what it took from the game so).
- **Settings made right** (`Core.Settle`), whenever a copy comes into use: the module's `upgrade` for a copy of
  an older `version` (each copy carries its own, `_version`), so a value whose kind changed is brought over
  before it is checked; then every switch of the wrong kind, no choice of its own or refused by `validate` gets
  its default, a number is cut to its ends, and what no description has any more goes (keys beginning with
  `_` are Core's). A description that cannot be right (a key twice, a parent that does not come before it) is
  noted in the error log.
- **A switch set from elsewhere** (a menu, a command): `Core.Set(name, key, value)` writes it, makes it right,
  tells the module, offers a `/reload` for a `reload` switch and refreshes the options page; `Core.Reset(name)`
  sets every switch of a module back to its default so. `Core.Described(name, key)` finds a description.
- **Load little, start late.** A file only defines things when it is read. Work starts in `OnLoad` or
  `OnLogin`, or later, when what it serves is first used (a window when it is opened). A game event is only
  asked of the game once somebody listens (`Core.On`).
- **Errors are handled, always (a hard rule).** Every piece of Sane UI's code the game calls runs behind a
  guard, and no error of ours breaks the game or leaves a broken part of it on screen
  ([addon standards](../../Doc/guides/addon-standards.md), *Errors and resilience*):
  - **Steps.** `Safe(label, fn, ...)` runs one step that may fail alone: its error is told once in chat and
    kept in `Core.errors`, the rest goes on. `module.Guarded(fn, ...)` runs a step whose error stands the
    module down.
  - **Doors**, where the game comes in: a game event (each listener on its own: one's error keeps no other
    from the event), `Core.Later`, a module's `OnLoad`/`OnLogin`/`OnLogout` (one that stood down, in any of
    them or at any door before, is not started further), `module.Guard(fn)` for anything else the game
    calls later of a module (a frame's script, a hook, a timer, a menu's function), and
    `Core.Guard(label, fn)` for the same in Core (its windows, the options, Sync, the scheduler). An error at
    a door that no step caught stands its module down; the
    module is the first whose folder the error's place or trace names (`Interface/AddOns/SaneUI_Social/...`),
    so an error in a step of Core that a module called is that module's. Core's own is told once under the
    door's name (the event, or `Core.Guard`'s label), and Core goes on: the next call tries again.
    `dev/tests/lint` fails on a script, hook, timer or menu function without a guard, here and in every module.
  - **What slipped past every guard** (a script without one) reaches the game's own error handler. Core
    listens at the game's error window (`hooksecurefunc` on `ScriptErrorsFrame.DisplayMessageInternal`,
    which leaves the game's handling as it is) and treats those of Sane UI as at a door; a Lua warning is
    only noted.
  - **The game's error window** shows an error caught at a door only when the game shows Lua errors at all
    (the CVar `scriptErrors`, `/console scriptErrors 1`): as it does every addon's, and during development.
    Without it nothing pops up; the line in chat and the log say what happened.
- **The error log** (`Core.log`, saved as `SaneUIDB.log`). `Core.NoteError` adds an entry for every
  problem: time, label, text with the place it happened, the addon's version, the game's build. The same
  problem twice in a row is one entry that counts; the log keeps the newest 100. An addon cannot write a file of its
  own: the saved settings file is the log file, and it is written at a `/reload` or a logout.
- **Falling back to Blizzard.** A module that changes something of the game's must be able to give it back
  when it fails (`GiveBack`, below; Abilities' book has a narrower one of its own, `Book.StandDown`). Game
  updates change Blizzard's code under us.
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
- **A module that stands in for something of the game's** (its tooltips, its chat, its spellbook) says how
  to give it back: `module.GiveBack()` and `module.GIVEN_BACK` (a few words for chat). An error at one of its
  doors, or in a `Guarded` step, calls `module.StandDown(problem)`: once, it sets `module.off`, gives the
  game's own back, keeps the problem and says so. From then on its `Guarded` steps and `Guard` functions do
  nothing. Its event listeners still hear their events: what works beside the game's own (a switch, the
  channels a character is in) goes on, and runs `Safe`. `Guarded`, `Safe`, `Ask` and a `Guard` function make
  no table and no closure when they run (the game's `xpcall` hands arguments on), so they are cheap enough for
  what runs many times a second.

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
| `module.Guard(fn)` | `fn` guarded, for the game to call later (a script, a hook, a timer): its error stands the module down; nothing once it stood down; all results passed on |
| `Core.Guard(label, fn)` | The same for Core's own code: an error that ran into a module's code stands that module down, Core's own is told once under `label`; tried again at the next call |
| `Core.Gently(label, fn)`, `module.Gently(label, fn)` | A search field's door (its keys, its list, its answers; Saneroki, 2026-11-15: "The search fields everywhere in our addon needs to have a very greacefull error handeling"): its error stands no module down, Core's or one named in its trace; it is kept and told once under `label` (the module's name before it), `fn` answers nil, the next key tries again. `Core.SEARCH_FAILED`: the words a search's list shows where its search failed |
| `Core.Later(fn, delay, label)` | Returns a function that asks `fn` to run once, `delay` seconds later (none: the next frame); `fn` runs guarded, its error told under `label` (none: "later") |
| `Core.Plain(value)`, `Core.Secret(value)` | Secret values (see above) |
| `Core.Ask(fn, ...)` | `fn(...)`'s first three answers, each nil when hidden; all nil when `fn` is missing or fails |
| `Core.MenuOpen()` | Whether a menu is open, the game's own kind or the older dropdown list: for a view that goes when the mouse leaves it and stays for a menu it opened |
| `Core.FullName(unit)` | A unit's whole name as the game shows it: a Forever character's first name and surname (`UnitName` gives both), joined by the game's separator; nil when hidden. Use it wherever a player's name is shown |
| `Core.PlayerKey(unit)`, `Core.PlayerKeyOf(text)` | A player's key, the one name that tells players apart: on Forever first name and surname as one (`Droopy Fairwind`, any realm dropped: the whole name is unique across the region), elsewhere `Name-Realm`; nil for a name that is not whole (a first name alone). Use it wherever a player is kept, counted, compared or shared ([Doc/guides/data.md](../../Doc/guides/data.md), *Players*) |
| `Core.Surnames()` | Whether this client names players by first name and surname (Forever, or `RegionalUniqueNamesEnabled`) |
| `Core.GAME`, `Core.FOREVER`, `Core.RETAIL` | The game this client is: `"forever"` or `"retail"` (nil on another client), by `WOW_PROJECT_ID`; Sane UI is one code for both ([Doc/guides/addon-standards.md](../../Doc/guides/addon-standards.md), *Forever and Retail*) |
| `Core.ForGame(choices)` | This game's one of a choice made per game: `Core.ForGame({ forever = 6, retail = 8 })`; nil for a game not named |
| `Core.ServesGame(addon)` | Whether an addon of Sane UI serves this game: its TOC's `## X-SaneUI-Games: forever` names its games, without it both. A module made for the other game only is off from the start (`module.elsewhere`), without a word and without an options page |
| `Core.NewerCoreWanted(addon)` | The Sane UI an addon of ours was published with (its packaged TOC's `## X-SaneUI-Core`, written by `dev/tools/release`) when this Core is older; nil when Core is new enough or the TOC names none (a build made here). Each module is a download of its own beside Core, so a player may update one and not the other: Core says so once in chat as the addon loads ("Navigation was made with Sane UI 0.3.2, and this is 0.3.1: update Sane UI too"); the module runs on |
| `Core.Data.Set(name)` and its handle | Sane UI's databases, part of Core (its set files, `Sets/`, read with it at the login); a module only reads ([Doc/guides/data.md](../../Doc/guides/data.md)) |
| `Core.Data.Map()`: `On(map)`, `Spawns(key)`, `OnChange(fn)` | What the data puts on a map: the places of Spawns, Places and Travel per map, each with what it is ([Doc/guides/data.md](../../Doc/guides/data.md), *What a map shows*) |
| `Core.Data.Ships()`: `Table(key)`, `Next(key, stop, at)`, `Aboard()`, `Near(yards)`, `Seen(key)`, `OnLearn(fn)` | The boats' and zeppelins' timetables, when they sail on this realm (learnt on a ride, kept on this computer per realm), aboard one, the stops near the player ([Doc/guides/data.md](../../Doc/guides/data.md), *The ships' times*) |
| `Core.Data.Trips()`: `Now()`, `CanLand()`, `Land()`, `OnChange(fn)`, `NearTram(yards)`, `TramNext(key, at)` | The trip the player is on (a flight, a boat or zeppelin, the tram): its stops, how far along (and its pace, to move it on between looks), how long; a flight's early landing; the tram's next train at a station, learnt on a ride ([Doc/guides/data.md](../../Doc/guides/data.md), *The trip underway*) |
| `Core.Data.Set(name):Unverified(key, part)`, `Core.Data.Confirm(set, key, part)`, `Core.Data.OnConfirm(fn)` | Whether an entry (or a boss's item or ability) is not yet confirmed by the game; Core's watchers confirm it in play, here or by the guild and the group, and the views say *! Unconfirmed Data !* no more ([Doc/guides/data.md](../../Doc/guides/data.md), *Verified*) |
| `Core.Data.Check(set, key, told)` | Core's own watchers only: what the game told of an entry compared field by field (the schema's `play` list says how each is told): what agrees confirmed (`name`, a member `startNPCs=69`), what differs or is missing learned with the parts the game told; a quest or creature only Forever has learned whole ([Doc/guides/data.md](../../Doc/guides/data.md), *Checked in play*) |
| `Core.Data.Tally`: `Loot`, `Drop`, `Point`, `Cell`, `Here`, `Of` | Core's own watchers only: what play counts per build period (loots and what they gave, places seen from up close merged by yards, cells where things were looted), for the harvest to add up over every player ([Doc/guides/data.md](../../Doc/guides/data.md), *Counted in play*) |
| `Core.Data.Learn(set, key, record)` | Core's own watchers only: an entry learnt in play (where a teleport brought the player, `Data/Teleports.lua`), kept as a whole row of the set in `SaneUIData_Learned` and read over the set's own while it is newer ([Doc/guides/data.md](../../Doc/guides/data.md), *Learned*) |
| `Core.Data.Characters()`, `Character(key)`, `Items(key, place)`, `Worn(key)`, `Count(item)`, `OnCharacters(fn)` | What the account's characters have: each by its GUID with its whole name, its bags, bank and what it wears (item by item, `Items`; slot by slot, `Worn`); where the account has an item and how many ([Doc/guides/data.md](../../Doc/guides/data.md), *Characters*) |
| `Core.People.Alias(key)`, `Note(key)`, `Shown(name)`, `Set(key, what, value)`, `Watch(fn)` | The alias and the note the player gave a player (by `Core.PlayerKeyOf`); what to show for a name; `Watch` tells a view to draw its names anew |
| `Core.Audio`: `KINDS`, `Kinds()`, `Names()`, `Current()`, `Use(name)`, `Get(key)`, `Set(key, on, volume)`, `Changed()`, `Save()`, `Load()`, `New(name)`, `Add(name, off)`, `Delete()`, `Watch(fn)` | The sound profiles (`Audio.lua`): the account's, in `SaneUIDB.modules.Core.audio` (`profiles = { { name, sounds = { [key] = { on, volume } } } }`, `current`); the game's sound settings now read and set through `C_CVar` (not Sync, which leaves these ten CVars alone: `Sync.Leave`); the profile in use set at each login (`PLAYER_ENTERING_WORLD` with `isInitialLogin`, not at a `/reload`); `Watch` tells a view on the next frame after a change, the game's own (`CVAR_UPDATE`) too |
| `Core.Coins(copper)` | Money as the game writes it, with coin icons; nil if it cannot |
| `Core.Points(region)`, `Core.Repoint(region, points)` | Keep a region's anchors and put them back |
| `Core.pages`, `Core.frames` | The options' pages, from login on, and the frame of a page of our own (`Settings/`) |
| `Core.Command(word, about, fn, ...)` | `/sane <word> <rest>` runs `fn(rest)`; further words are short forms |
| `Core.Store(name)`, `Core.Character(name)` | What a module keeps, for the account and for the character |
| `Core.Options(name, list, changed)` | Describes a module's switches |
| `Core.Settle(name, values)` | A module's settings made right for this version: its upgrade, then each switch its default where it has none or a spoiled one, what no description has gone |
| `Core.Profiles` | Where the settings in use live, and the profiles (see above) |
| `Core.Settings(name)`, `Core.Set(name, key, value)`, `Core.Reset(name, only)`, `Core.Described(name, key)` | A module's settings in use; one set from elsewhere than its page; all back to their defaults (`only(option)`: just those it says, one page of Core's own); a description |
| `Core.AfterCombat(key, fn, ...)`, `Core.Owed(key)`, `Core.Locked(frame)`, `Core.Restricted()` | Run now, or once the fight is over (the same key once); a protected frame in a fight; a fight or a restriction of the game's |
| `Core.Off(event, fn)`, `Core.OnUnit(event, unit, fn)`, `Core.OffUnit(event, unit, fn)` | Stop listening; an event of one unit only |
| `Core.Config` | The options (`Settings/`): `Fill()` makes the pages' controls (once), `Open()` opens them |
| `Core.Sync` | Sync (`Sync/`): the game's own settings kept with Sane UI's |
| `Core.Data` | Sane UI's own databases (`Data/`): a set's handle (`Data.Set(name)`: `Get`, `History`, `Each`, `OnStamp`, ...), `Data.Prepare(name)`, `Data.WhenReady(set, fn)` ([Doc/guides/data.md](../../Doc/guides/data.md)) |
| `Core.Steps` | The scheduler of long work (`Data/Steps.lua`): `Run(name or options, fn, ...)` gives a job's handle (`:Stop()`); a job asks `Check()` between pieces and goes on in the next frame when the frame's few milliseconds are spent; nothing in a fight or under a restriction |
| `Core.Copy(value)` | A copy of a value that shares no table with it |
| `Core.described`, `Core.optionOrder` | The described switches, for whoever shows them (Settings) |
| `Core.class`, `Core.charName`, `Core.realm`, `Core.charKey` | The character, from login on (`charName` is first name and surname, `charKey` the GUID) |
| `Core.TITLE`, `Core.VERSION`, `Core.GOLD` | Name, version from the TOC, the addon's colour |

- **Windows** (`Dock.lua`, `EditMode.lua`, `Escape.lua`, `Watch.lua`, `Rest.lua`, `Fuzzy.lua`, `Shape.lua`, `Skin.lua`,
  `Edge.lua`, `Window.lua`, `Views.lua`, `Selection.lua`, `Holder.lua`, `Seat.lua`, `Board.lua`, `Expand.lua`, `Bar.lua`, `Motion.lua`):
  a library for the modules' windows. Each file's head says how to call it; `Doc/guides/windows.md` is the
  guide for a module that builds one.

  | Call | What it gives |
  |---|---|
  | `Core.Window.New(frame, options)` | A window of our own, of a kind (`kind` = `"screen"`, `"panel"`, `"talk"`: `Window.KINDS` gives its options, the module's own win, a table such as `first` merged): in Blizzard's Edit Mode dragged by its box (`window.box`, `title` on it) and sized by a grip (`sizable`); a title bar (`titleBar`, `title`, `search`, `dragDocked`) with its buttons (`close`, `buttons` = the module's own `{ atlas, tip, text, click }` (or `texture`) left of Core's, `native = { frame, show, back, hold, addon, unseen }`); docking (`dock`, `insets`: docked, the room it keeps from the screen's edges), with a skin (`skin`, its corners as `corners` says, else as `edge`), filling the screen from its screen edge or its button (`edge`, with `motion`, `content`, `filled`); `first = { point, x, y, width, height, dock }` (`dock`: docked in that zone at first; the talk kind's `CENTER`); `toplevel` (a click brings it to the front: panel, talk); `tabs` (`Views.lua`). Its place and what it was left as are kept in `options.store.place` as `{ x, y, width, height, dock, full, native, tab }`. `window:Place()`, `window:Reset()`, `window:Open()` (the game asked for it), `window:Native(on)`, `window:Remember(what, value)`, `window:Recall(what)`, `window:Refresh()` (bar and buttons as the window is now), `window:SetTitle(text)`, `window:Draggable()`, `window:Attach()` (our button onto the game's window, once it is there), `window:GiveBack()` (the holder's game window back for good), `window:Selected(on)` (its box in Edit Mode's selected look), `window:Escapes(on)` (Esc given up while a view over it takes Esc, as Core's options on a full screen, and taken again), `window.inside` (what the window holds stands in it: under the title bar while there is one; `window.top` its height; with `under`, from the frame's top while the window fills the screen, the bar over it at `Window.UNDER`: Navigation's map), `untitled` (the bar without its title's words), on a full screen no X (the arrow down takes it back; Saneroki, 2026-11-15: "Remove the x on the fullscreens"), the X, the arrow down and the module's buttons `Window.BUTTON` square, `window.zone`, `window.grip`, `window.skin`, `window.edge`, `window.bar`, `window.buttons`, `window.holder` |
  | `Core.Window.All()`, `Core.Window.ResetAll()` | Every window made by `New`, in the order made; each at its first place and size (`/sane window reset all`) |
  | `Core.Board.New(window, options)` | A module's full screen of windows (`Board.lua`): `options = { store, key, label, windows = fn → { { key, title, least, build, show, size, search, present, fit, icon, coords } }, default = fn(width, height) → layout, changed = fn, occasions = { [name] = { title, default = fn(width, height) → layout } } }`. `board:Show(inside, width, height)` lays out the layout chosen and returns each window's rect (`[key] = { left, top, width, height }`); `board:Hide()`, `board:Search(text)`, `board:Has(key)`, `board:Forget(key)`, `board.panels[key]`. A talk's layout (a vendor, a banker, a trainer): `board:Occasion(name)` (nil: the talk ended) stands that occasion's layout instead of the tab chosen while it is on (the module's `default` for it until changed, then kept in `store[key].occasions[name]`), behind a tab of its own first in the title bar (a right click resets it); another tab chosen sets it aside until the talk ends, its tab brings it back; `board:Talking()` names the one standing. The player arranges it on the full screen: tabs for layouts after the title (`+`, a right click renames, resets, deletes), the dropdown *Windows*, a window's head dragged, the lines between windows dragged, its X; a window with an `icon` (a texture or file ID with its `coords`, or `function(texture)` that draws it) also has a tab of its own after the layouts' tabs, lit while it is in the layout, a click adds it or takes it off. A window of another module (a module depends on Core only): `Core.Board.Offer(label, spec)` (the board of that label lists it, in place of a window of its own of that key; Guild's on Social's), `Board.Withdraw(label, key)` (either way a board that stands lays out anew, and the window that now has the key a panel of its own), `Board.Offered(label, key)`, `Board.Told(label)` (what an offered window wants changed: a board that stands lays out anew), `Board.Open(label, key)` (its full screen, that window put into the layout chosen; false when that cannot come now: its window closed, Edit Mode, *Can expand to fullscreen* off), `Board.Standing(label)`, `Board.Close(label)`. A panel's two corners at its right (the kit's brackets) size it as the mouse goes: on the full screen the lines along its sides, laid out at every step. A window of its own: the game's minimize beside a panel's X makes it one (the full screen goes back, it stays by itself, moved by its head, sized by its corners, Esc closes it; its maximize puts it back on the full screen), `board:Own(key, on)`, `board:Stand(key, on)` (shown, closed, nil toggles), `board:Alone(key)`; a module's key asks `Core.Board.Key(label, key)` first (true: it was one of its own, opened or closed so, and whether it stands now; false: the module opens its full screen), `Core.Board.Alone(label, key)`; kept in `store[key].alone`; none for `fit` or `apart = false`. A window as large as what it holds (`fit` → `{ width, height }` of its panel in UIParent's units, nil: as the layout gives; Combat's action bars): along its split it takes that size, its neighbours share the rest and no line stands between them; across, the room beside it stays empty. Plain functions for layouts: `Board.Lay` (with `fit(key)`), `Beside`, `Without`, `Swap`, `Move`, `Present`, `Least`, `Holds`, `Copy` |
| `Core.Icons.Open(options)` | The icon chooser (`Icons.lua`; the macros' picture window until 2026-11-15, Core's for every module): over whatever shows, the full screen too; the game's icons (Core's set Icons, else the game's macro icons) by group (all, in the game, each class, weapons, armor, consumables, trade goods, other items, spells, mounts, achievements, other), searched by name and group; a click gives `options.pick(file)` and closes it. `options = { label, title, chosen = file (marked), pick = fn(file or nil), clear = { word, tip } (a button that gives nil), tick = { word, tip, on, set = fn(on) } (the caller's tick), chosenWord, clickWord }`; `Core.Icons.Close()`, `Core.Icons.Shown()`. Combat's macros and Inventory's own categories use it |
  | `Core.Fuzzy.Query(text)`, `Fuzzy.Match(query, ...)`, `Fuzzy.Rank(word, text, lower, spots)`, `Fuzzy.Highlight(text, spots)`, `Fuzzy.Plain(text)` | Forgiving search: the typed words; whether every word is in one of the texts (the sum of their ranks); one word's rank in one text, a whole number whose hundreds say how it was found (600 the whole text, 500 its beginning, 400 a word's beginning, 300 its words' first letters, 200 inside, 100 letters spread out in order) and up to 90 more for a close fit, and the bytes it took; the text with those letters in the game's gold (`NORMAL_FONT_COLOR`); a text of the game's as it reads (no colour, link or icon codes). One pass through a text per look, no table without spots, each text lowered once per `Match` |
  | `Core.Fuzzy.Filter(rows, query, fields, done)` | The rows every word is found in (`fields`: keys of a row, or functions of it), ranked best first: `done(found, ranks)`. Up to `Fuzzy.AT_ONCE` (200) rows at once; a longer list a part per frame on `Core.Steps`, a newer search stopping an older one (a counter); a row's texts lowered once while they stay the same |
  | `Core.Fuzzy.Keys(box)`, `keys:Rows(list)`, `keys:Take()` | The keys over a search box's fly-out of finds (the aura search's box, a settings page's search; Saneroki, 2026-11-09): Up and Down light one of the rows it shows now (`Rows`, in order; nil: none), round at the ends as the game's name completion, as the mouse would (`LockHighlight`, its `OnEnter`: a tooltip; `OnLeave` when it goes); `Take()` first in the box's Enter clicks the lit one (true), else false and Enter does what it did. New rows: none lit |
  | `Core.Escape(owner, close)` | Esc runs `close(owner)` from now on (nil: no more): one stand-in of ours, `SaneUIEscape`, the only entry of Sane UI's in the game's `UISpecialFrames`, for every window, Edge's full screen and the feedback window |
  | `Core.Watch(frame, every, fn, label)`, `Core.Hover(frame, options)` | A look every `every` seconds while it is out and its frame is shown (`watch:Start()`, `Stop()`, `IsRunning()`); the mouse on a window: `hot` (whose `OnEnter` starts it), `dwell`, `linger`, `margin`, `every`, `keep`, `enter`, `leave`; `hover.over`, `hover:Start(over)`, `hover:Stop()`. The window takes only the mouse's coming, clicks go through |
  | `Core.Window.Mover(handle, frame, hooks)`, `Core.Window.Sizer(frame, hooks)` | Only the dragging and the grip, for a window that is not ours to keep (the game's spellbook). Nothing is written into the frame |
  | `Core.Window.Corner(grip, corner)` | Moves a grip to another corner and mirrors its art |
  | `Core.EditMode.active`, `Core.EditMode.Watch(fn)` | Whether Blizzard's Edit Mode is open; `fn(active)` when it opens or closes (`EventRegistry`'s `EditMode.Enter`, `EditMode.Exit`) |
  | `Core.Dock.ZONES`, `Core.Dock.Find(left, bottom, width, height, screenWidth, screenHeight, only, insets)` | The nine zones (four corners, the middle of each edge, `CENTER` in the screen's middle), and which one a window would dock to (plain numbers; `Dock.REACH` = 60; `insets`: the room kept from the screen's edges) |
  | `Core.Dock.Rect(zone, width, height, screenWidth, screenHeight, insets)` | Where a window of that size stands docked there: its lower left corner |
  | `Core.Dock.Hold(frame, zone)`, `Core.Dock.Holder(zone, frame)` | A zone holds one window at a time: the window docked there now; the shown one other than `frame` holding it. A drag offers no zone another holds; a window opening with such a zone kept stands clear that time, where it stood or beside the zone, `Window.CASCADE` (32) down and to the side of each window already there (`Window.lua`) |
  | `Core.Shape.New(host, settings, rect)` | A plate with round corners and a trim: `settings.radius` (a fixed radius in UI units: a chat's bubble) or `corners` %, `settings.trim` (the trim's width in UI units; `Shape.TRIM` at first), `shape:Look({ file, size, top, bottom, trim, alpha })` (trims and holes only made for a look with a trim), `shape:Fit(left, bottom, width, height)` (or the frame's own place), `shape:Follow()` (fitted to its frame at every size), `shape:Base(width, height)`, `shape:Flatten(share)` (that far to square), `shape:SetAlpha(fill, trim)`, `shape:SetShown(on)`, `shape.radii`. `Shape.Round(texture)`: an icon or portrait cut round (the circle mask, else the game's portrait mask). `Shape.CAP_LEFT`, `Shape.CAP_RIGHT`: the masks of a bar's round ends (`Art/cap-*.blp`; a quarter of the bar's height wide, `CLAMPTOWHITE`; Nameplates' bar). `Shape.SOFT_CORNER`: the top left corner of a plate whose edge fades out softly (`Art/soft-corner.blp`), a texture laid as nine pieces, the corners turned by their texture coordinates, the sides its last column or row stretched (Lore's talk, `Look.Plate`). `Shape.CORNER.TOPLEFT`, `TOPRIGHT`, `BOTTOMLEFT`, `BOTTOMRIGHT`: one corner cut round (`Art/corner-*.blp`), laid over that corner as large as the radius with `CLAMPTOWHITE`: that corner alone round, at any radius and height (Nameplates' outline and its cast bar). `Shape.Bar(frame, height)`: a thing's bar as the nameplates draw theirs (the game's raid health fill in a colour, a border of one screen pixel nearly black, round a quarter of its height; `bar:Paint(r, g, b)`, `bar:SetLit(on)` grey, `bar:SetChosen(on)` gold; `bar.fill`, `bar.inner`, `bar.pixel`), with `Shape.Caps(texture, anchor, height)` (a texture's ends round as such a bar), `Shape.BarFont(fontString, size)` (the game's outlined nameplate font, size in 1080p pixels), `Shape.Quality(quality)`, `Shape.Gold()`: Loot's lines and rolls and Lore's quest rewards, so rolling on loot and choosing a quest's reward look the same. `Shape.Options(list, at, tab, parent)`: the switches *Corner radius* and *Don't round corners on screen edges* (`corners`, `squareEdges`; `Shape.DEFAULTS`, `Shape.KEYS`) |
  | `Core.Skin.New(frame, settings)` | The tile of the game's dark dialogs (`Skin.TILE`) and a trim in Sane UI's colour on a Shape; `skin:Rest()` (placed: corners measured on this size), `skin:Fit(...)`, `skin:Hold(on)` (while a motion sizes the window: no refit at every size, the motion fits it once a step) |
  | `Core.Skin.TILES`, `Skin.Tile(key)`, `Skin.Choices(solid)` | The game's quiet background tiles a window or a chat's bubbles can stand on (Marble, Rock, Slate, Iron, Night: `{ key, text, file, size }`); one by its key; the choices for a dropdown, `solid` (a colour of its own) first |
  | `Core.Expand.New(frame, options)` | Opens to `width` × `height` once the mouse has rested on it `Expand.DWELL` (0.2 s; anywhere, or only in `corner`; not with `hover = false`), closes once it has been away `Expand.LINGER` (0.5 s), on `Core.Hover`; `expand:Stay(on)` keeps it open (a control of the window's own; nothing watches the mouse meanwhile); `motion` its own kind, `still` while another part has its size. `expand:Open()`, `expand:Close()`, `expand:Stay(on)`, `expand.open`, `expand.stays` |
  | `Core.Bar.New(parent, options)` | A progress bar in the art of the game's experience bar (`Bar.ART`: background, fill, the part still to come, its pip, the dividers, the flare): `bar:SetValue(value, most, ahead)` (a gain rises in `Bar.RISE` to `Bar.RISE_WHOLE` seconds by its size, with the game's flare; a loss is there at once), `bar:SetSize(width, height)` (moves there); `width`, `height`, `segments` (nil: the game's own count), `fill`, `flare`, `motion`, `moved` (the value the fill stands for, on its way too); `bar.frame` |
  | `Core.Edge.New(window)` | Made by `Window.New` with `edge`: docked, the window fills the screen when the mouse is pushed against that screen edge, and goes back when pushed there again; full, the dropdown *Classic windows* (`classic`) in its title bar. `edge:Fill(on)`, `edge.full`, `edge.away`, `edge.classic`. Not in Edit Mode. With the window's option `strip` (a share, 0.5: Combat) and docked at an edge's middle, the strip is that share of the screen's side, in its middle, whatever the window's width; its length follows the screen's size and the UI's scale |
  | `Core.Motion.Kind(key)`, `Motion.Share(kind, progress)`, `Motion.Ease(curve, progress)`, `Motion.Choices(own)`, `Motion.Clock(frame, step, failed)` | The kinds of motion (`Motion.KINDS`: glide, swing, even, off (*Instant*); each a `time` and the name of one of the game's easing curves, `EasingUtil`); the kind for a window's own setting (nil, `"global"` or unknown: the general one, `Core.general.motion`); the share of the way; a curve by name (straight without the game's); the choices for a dropdown; a clock that runs only while something moves (its frame hidden mid-way: at its end at once) |
  | `Core.Motion.Fade(region)`, `Core.Motion.Slide(region, seconds)` | A region's fade, one of the game's animations: `fade:To(alpha, seconds, from)`, `Stop()`, `IsPlaying()`; its slide to its place: `slide:From(x, y)` (put back by that much, it slides home; one on its way is taken into the new one), `SetTime(seconds)`, `Stop()`, `IsPlaying()`. Both at once with all animations off (`Core.general.animations`) or the region out of sight |
  | `Core.Rest.New(options)`, `rest:Hot(frame)`, `rest:Area(frame)`, `rest:Door(frame)`, `rest:Enter()`, `rest:Switch(on)`, `rest:InGroup(on)`, `rest:Look()`, `rest:Resting()`, `Core.Rest.Busy(inGroup)` | A set of frames out of sight while you are at rest, by their alpha alone: in sight with the mouse on it, while something goes on (a fight, a group, dead, your health or resource not full) and in Edit Mode. `rest:InGroup(true)`: a group counts for nothing (the modules' *In a group too*). `options`: `label`, `frames`, `hold` (a function: the module keeps it in sight). What a player sees of it stands in the module; why health is told from its changes in `Rest.lua` |
  | `Window.Views(window)` (`tabs`) | The views behind the game's tabs (`TabSystemTemplate`, `TabSystemTopButtonTemplate`, as wide as the spellbook's: `Window.TAB_WIDTHS` 100 to 150, `Window.TAB_INSET` 22, `Window.TABS` 32 high) at the top of `window.inside`; a view built when its tab is first chosen; `window:Tab(index)`, `window.views`, `window.view`, `window.tabs`; the tab last chosen kept (`tab`) |
  | `Core.HealthMarks.New(host, health, options)`, `marks:Set(unit)`, `marks:Heard(unit, event)`, `marks:Reach(width)`, `marks:Fit(width)`, `marks:Switch`, `marks:Place`, `marks:Sample` | What every health bar shows besides the health, the same in Combat and Nameplates: a barrier in the game's shield art, drawn from its heal prediction calculator so hidden numbers are never computed; the part of the bar lost with maximum health, hatched; and in one aura container of the game's the type icon of what can be dispelled, floating over the words (nothing of an addon's may be anchored to the container, so it stands by what shares its line, `marks:Place`; its frame takes no call of an addon's while auras are secret, so `marks:Resize` scales the container). No mouse on any of it |
  | `Core.AuraLog.Entries()`, `Core.AuraLog.Live(entry)`, `Core.AuraLog.Listen(fn)`, `Core.AuraLog.Clear()`, `Core.AuraLog.Share(on)` | The buffs and debuffs seen on whoever you can attack, kept as a history for a view to show (`AuraLog.lua`; Combat's aura history, Saneroki, 2026-11-11): an entry per aura come on a unit (GUID and aura instance): its spell, `harmful`, `on` and `boss`, `from`, `stamp` (`time()`), `lasts`, `ends`, `gone`, `stacks`, `dispel`, `steal`, and `cast` (whether the cast that gave it could be interrupted, where seen; `instant`). The target, focus, mouseover, soft target, boss1-5 and every nameplate's unit, each by its own `UNIT_AURA` a frame later. In a fight the game hides auras from addons: only plain ones are kept, nothing is closed, and every unit is looked at again once the game tells them again (an aura still on came at its end less its duration). What a fight hides comes in two more kinds (`kind`): `"cast"`, your own casts in a fight of a spell that puts an aura on (`AuraLog.Leaves`, Core's data), on whom, when, its aura found after the fight folded in; `"fight"`, after each fight the spells of the game's damage meter (`C_DamageMeter`, plain then): each member's damage, healing, damage taken, dispels and interrupts (`what`), whom from and on, the fight's name, `hits`. And a member's: after each fight your casts of it go to your party or raid by `Core.Wire` (the kind `AuraLog.KIND`, the server's time), theirs come in as `"cast"` entries `shared` from them, while `Share(on)` says so (Combat's switch). Per character, the last `AuraLog.MOST` (1000) |
  | `Core.Mana(unit)`, `Core.FormPower(unit)` | Your druid's mana beside a form's power (`Kit.lua`, Saneroki, 2026-11-13): `Mana` a unit's mana now and most as the game gives it, hidden or not; `FormPower` the power you show as a druid in a form whose power is not mana (number and token), while the game gives your mana; nil for anyone else (the game tells a druid's mana in a form to that druid alone, so another druid shows one power) |
  | `Core.Secrecy.Start()`, `Core.Secrecy.Clear()` (`/sane secrets`, `/sane secrets clear`) | Which spells the game hides from addons, asked of the game itself for the developer's lists (`Secrecy.lua`, Saneroki, 2026-11-11; `saneui showsecrets` prints them): every spell number to `Secrecy.TOP` that `C_Spell.DoesSpellExist` knows, `Secrecy.STEP` a frame, paused in a fight, asked `C_Secrets.GetSpellAuraSecrecy` and `GetSpellCastSecrecy` (the game's base secrecy: 0 never hidden, 1 always, 2 while a restriction is on). Kept in `Core.Store(Core.name).secrecy`: the first two kinds by number with their names, the third counted; the build, game and day |
  | `window:GrowFromBottom(width, height)`, `options.settings` with `options.get`, `options.set` | A window that grows from its bottom left corner; rows in Edit Mode's dialog: the game's slider with its steppers, or a field to type a number into (`input = true`) |
  | `Core.Selection.Select(window)`, `Selection.Clear()`, `Selection.window` | In Edit Mode, the window chosen by a click on its box: the box in Edit Mode's selected look (`editmode-actionbar-selected`), and Core's dialog in Edit Mode's look (`DialogBorderTranslucentTemplate`, `Selection.WIDTH` 370, at `Selection.ANCHOR`, strata `DIALOG` level 200) with its name and *Reset To Default Position* (the game's `HUD_EDIT_MODE_RESET_POSITION`; `window:Reset()`, only for a window moved or sized). Taken off when one of the game's frames is selected or Edit Mode closes |
  | `Core.Holder.Take(window)` (`native.hold`) | Ours or the game's, never both: the game's window held out of sight under a frame of ours (`Core.Lend`) while it is closed and ours is chosen; opened by the game's own code, it opens ours. `holder:Native(on)` (from `window:Native`), `holder:GiveBack()`, `holder.held`, `holder.off`; `native.addon` (held once that addon is loaded), `native.unseen` (closed unseen before it is given back), `Holder.TINY` (0.001: made tiny, not hidden, while the game still has it open) |
  | `Core.Seat.New(frame, options)` | A window that is not ours (the game's spellbook, a known addon's) seated in a room of a full window: `seat:Hold(left, top, width, height, strata, level)` (UIParent's units, from its bottom left; in that strata, at least at that level; false: closed, or protected in a fight), `seat:Free()`, `seat:Size()` (its own size, unseated), `seat.held`; `options.label`, `sized`, `gone`. As large as fits, never larger than it is, in the room's middle; only its place, scale and layer lent (`Core.Lend`), never its parent; hooks after its `SetPoint` and `SetScale` put it back, after its `SetFrameStrata` and `SetFrameLevel` its layer (the game's action bars set their own strata at every drag onto them; a protected one in a fight after it), a new size fits it anew, closed it is given back; its parts the game pinned above it in a strata of their own (the trainer window's list and scroll bar on HIGH, the window on MEDIUM) lent too, lifted in the room's strata above every other part of it, given back after it (its strata given back drags theirs along) |
  | `Core.Seat.Part(options)` | A window not ours as a part of a module's board (the game's vendor, trainer and Profession windows): `options = { frame (its global name), addon (loaded by the game on demand), label, level, width, opened = fn(frame), closed = fn(frame) }`; the part's `Build`, `Show`, `Size`, `Present` (while the window is open), `Leave`, and `part.Frame()`, `part.Width()` (its own width, UIParent's units), `part.Follow()` (hooks after its `OnShow` and `OnHide`, now or once its addon has loaded). Seated in its panel's body while both are shown; the game opens and closes it, our code only follows |
  | `Core.Lend(frame)`, `Core.Lent(frame)` | A frame of the game's changed for a while and given back exactly (`lent:SetParent`, `SetPoints(fn)`, `SetLayer`, `SetAlpha`, `SetScale`, `SetMouse`, `SetShown`, `Lent()`, `Return()`); whether a frame is lent now, to any module (Abilities leaves the spellbook's place alone while Combat holds it) |
  | `Core.Neighbours.Window(key)` | The known addons (Saneroki, 2026-10-20), named in `Neighbours.lua` only: a handle on one while it is loaded (`"talents"`: a talent planner), nil otherwise: `handle.title`, `handle:Frame()`, `Shown()`, `Open()`, `Close()` (by its own functions), `Follow(fn)` (after each opening of it, a hook after its opening function, made once) |
  | `Core.Neighbours.Format(key)` | A known leveling guide's text format (`"guide"`, Saneroki, 2026-10-25): its command words, step marks, colour words and game tags, each by Sane UI's own word for it (`commands`, `marks`, `modes`, `colours`, `gameTags`), copies; nil for one without. Speed Leveling runs guides written in it with an engine of its own, so nothing of the addon is read or called at runtime |
  | `Core.Neighbours.Lock(key)` | The recipe a known guide's bought import strings are locked to the buyer's account by (`"guide"`): a copy of `{ account, tag, width, taps, mark, close, version }`; nil for one without. Speed Leveling (`Unlock.lua`) opens the guides bought for the player's own account with it |
  | `Core.Metric()`, `Core.Distance(yards)`, `Core.DistanceNumber(yards)`, `Core.DistanceText(text)`, `Core.Clock(hour, minute, second)`, `Core.ClockAt(stamp, seconds)`, `Core.GameClock()` | Distances and the time of day as the setting *Units* says (`Units.lua`, Saneroki, 2026-10-30; page General, Metric at first): `"27 m"`, `"23:59"`, or Imperial `"30 yd"`, `"11:59 PM"`. The game counts in yards, so all of Sane UI keeps yards (settings too) and only what a player reads comes through here, at 0.9144 m to the yard, rounded to whole meters. `DistanceText` turns the yards a text of the game's names (a spell's description, *8-25 yd*); `Clock` takes an hour and minute (and a second: `"23:59:07"`), `ClockAt` a moment (with its second where `seconds`); `GameClock` sets the game's own 24-hour switch (`timeMgrUseMilitaryTime`) at the login and when the setting changes. An option `distance = true` is a slider of yards shown this way |
  | `Core.TOAST_TOP` | How far below the screen's top what tells something over the world stands, where the game's own toast stands (`Kit.lua`): the toast of a new level (right of the middle, beside the guide's arrow) and the travel overlay keep this height |
  | `Core.TellsAtTop(frame)`, `Core.TopTaken()`, `Core.OnTopTaken(fn)` | What tells something at that height for a while says so once (`Kit.lua`): while one of those frames shows, `TopTaken()` is true and what only stands there makes way (Speed Leveling's arrow); `fn()` whenever one came or went |
  | `Core.Ways.Serve(finder)`, `Core.Ways.Aim(map, x, y)`, `Core.Ways.Ahead()` | The way to a place, between a module that leads the player and the one that finds ways (Saneroki, 2026-10-31), so neither needs the other (`Ways.lua`). Navigation serves; nobody asks since 2026-11-07, when Speed Leveling's arrow went back to pointing straight at its place. Whoever asks: `Aim` once for each place (a map of the game's, x and y 0 to 1; none: nowhere), `Ahead()` as often as it likes: `{ way, yards, ride, to, here }` (the way to turn, as the game's facing; the yards along the line to the next ride or the end; that ride; where it brings one; whether it starts where the player stands), a reused table, or nil while no way is known |
  | `Core.Sight.Serve(finder)`, `Core.Sight.Nodes()` | The herbs and ore in sight now, what a place of Core's data cannot say: each `{ node, map, x, y, seen }`. Navigation's `Found.lua` serves it, the guide's detours ask it, neither needs the other; with nobody to find them, none |
  | `Core.Spellbook.Serve(module, offer)`, `Core.Spellbook.Offer()`, `Core.Spellbook.Changed()`, `Core.Spellbook.Watch(fn)` | What a spellbook shows beyond the game's own spells, between the module that knows it and the one whose book shows it (Saneroki, 2026-11-06), so neither needs the other (`Spellbook.lua`). Abilities serves (`Book/Offer.lua`, Forever), Combat's spellbook draws it: `Spells(line, showRanks)` the entries still to learn of a tab, `Sections(line, lines, hidePassives, showRanks)` sections of their own under them, `Search(words, lines, showRanks)` the finds by tab, `Make(parent)` and `Set(frame, entry, width)` the offer's own frame for an entry, `Home` a tab and page of its own (`Surface`, `Draw` on the book's two pages, `First`), `Menu(root)` lines in the book's settings menu, `Switch` one switch beside its page controls. `Offer()` is nil while nobody serves or the serving module stood down; `Changed()` tells the watchers on the next frame |
  | `Core.StatWord(word)`, `Core.StatLine(line)` | The stats as players write them (`Stats.lua`, Saneroki, 2026-10-30): `"Strength"` is `"Str"`, a line of a number and a stat `"+8 Stam"` (a coloured number too); a word that is no stat and a sentence stay as they came. The one place the short words are kept: every view that names a stat goes through these. The game's own windows keep its words |
  | `Core.Upgrade(link, id)`, `Core.WeighWith(fn)` | Whether an item would make the character better (`Upgrade.lua`): gear wearable now, with nothing worn in its place or something worth less there, never lighter armour than worn. Worth: its stats (`GetItemStats`) by the character's weights, a two-handed weapon against both hands, else its item level. On a shield build (`shield` in the weights) never a two-hander, and one held counts as nothing; a one-hander against the main hand alone, only a shield in the off hand. `"empty"` or `"better"`, what it brings and the place it goes (of two the empty or the weaker one); nil: no upgrade. `fn()` gives the weights, `{ [the game's stat key] = worth, ranged = worth of a ranged weapon's damage per second, shield = true on a shield build }`: Inventory's (`src/Inventory/Weights.lua`); with Inventory off item levels decide |
  | `Core.Offer(key, switch)`, `Core.Switches()`, `Core.SwitchChanged()`, `Core.OnSwitches(fn)` | Quick switches the modules offer, for a view that gathers them (Saneroki, 2026-10-26: the minimap's satchel), so neither knows the other (`Switches.lua`). `switch = { title, icon, State, Tip, Click }`: `State()` says `"on"`, `"paused"` or `"off"` (nil: not offered now, its module off), `Tip()` its tooltip's words, `Click(mouseButton, owner)` what a click does. `Core.Switches()` lists those offered, in the order offered, with their state and tip as now; a module calls `Core.SwitchChanged()` when one changed, and the views given to `Core.OnSwitches` are told on the next frame |

  - **The title bar** (`Window.lua`, `Bar`, `Refresh`): with `titleBar` (a kind of window that has one; the
    small chat, unit frames have none), and on every window while it fills the screen. Across its top,
    `Window.BAR` (32) high, `Window.BAR_LEVEL` (20) above it, a thin bronze line under it. At its left a
    button: with `search`, the game's magnifier (`common-search-magnifyingglass`) and the `title`
    (`GameFontNormal`): a click opens the search box (the game's `SearchBoxTemplate`) over the bar up to what
    stands at its right (the buttons, or Edge's dropdown at full screen), the cursor in it; every change goes
    to `options.search(text)`; Esc, or the cursor leaving it empty, closes it, emptied (`search("")` told), and
    so does `window:EndSearch()`, for a module that leaves the search itself (a tab of Combat's book chosen).
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
    kept in our own table (nothing written into the game's frame), once per window. `Window.Swap(parent, text,
    tip, click)` gives that button, unplaced, to a module's own frame (Navigation's satchel). Not in Edit Mode. Shown
    buttons stand side by side; `buttons.first` is the leftmost. A free or centred window fills the screen by
    its button (Edge's `placed`), and goes back to where it stood.
  - **What a window was left as** (`Remember`, kept in its place table, carried over by every new place;
    `Recall` reads it): `full` (`Edge.Fill` notes it), `native` (`window:Native`), `tab` (`Views.lua`).
    `window:Open()`, for a module when the game asks
    for the window (its key, an NPC): `native.show()` if the game's own was chosen, else the window shown,
    filling the screen again if it was left so; returns `"native"` or `"ours"`. Catching the game's own
    triggers is the modules' (`Doc/ideas/Windows.md`, *The game's own triggers*).
  - **In a fight** (`window:Locked()`): a window that holds the game's protected frames is protected itself
    (`IsProtected`'s first value counts protected children), and addon code may not move, size, show or hide
    it while `InCombatLockdown()`. Then no drag, no sizing (`usable`, `Draggable`), no full screen
    (`Edge.Fill`), `Place` waits for `PLAYER_REGEN_ENABLED` (`Later`), a full screen motion on its way is put at
    its end at `PLAYER_REGEN_DISABLED` (before the game locks), and `Open` returns `"locked"` for a hidden one.
    Its close button and Esc close it once the fight is over (`Core.AfterCombat`); meanwhile Esc is the game's.
  - **Esc** (`escape = "close"`, `Escape.lua`): one stand-in of ours, `SaneUIEscape`, Sane UI's only entry in
    the game's `UISpecialFrames`, is shown while anything of ours is to be closed by Esc (`Core.Escape`); when
    the game hides it (Esc), each one closes (`options.close`, else hidden), a full one as it is (Edge leaves it:
    no `Fill(false)`, so `full` stays kept); a moment later the stand-in is shown again while one still is (one
    its module closes later: a talk). A protected window in a fight closes after it, and gives Esc to the game
    meanwhile. Without `escape`, Esc only brings a full window back (Edge). A view over a window that takes Esc
    for itself (Core's options on a full screen) calls `window:Escapes(false)`, and `true` once it has gone.
    `Reset` keeps `full`, `native` and `tab`.
  - **To the front** (`toplevel`, the panel and talk kinds, as the game's own panels): a click on the window
    raises it above the others of its strata (`SetToplevel`).
  - **The first place** (`first`): `first.dock` docks it in that zone at first (Social's chat: `BOTTOMLEFT`; a
    talk window: `CENTER`), else `first.point`, `x`, `y`, else the screen's middle. A zone another shown window
    holds is not taken: the window stands clear of it. `insets` keeps a docked window that far from the
    screen's edges (its strips for filling the screen stay on the edge).
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
    it closes is let go and kept, once (letting go twice does nothing), as is one hidden in the middle of a drag
    or a sizing (a hidden frame hears no end of either). The place is kept at once, as before:
    not in Edit Mode's layouts. A click on the box selects the window (`Selection.lua`, above); with Edit
    Mode's *Snap* on (`EditModeManagerFrame:IsSnapEnabled()`, only read), a free window let go with an edge
    within `REACH` (8, Edit Mode's magnetism) of a line of its grid (`manager.Grid`'s spacing, from the
    screen's middle) lines up with it.
  - **Docked means hanging on the zone,** not on a place: the window is anchored by the point that
    touches the edge, so it stays there at any size and grows away from the edge. Its grip moves to a
    corner that is not at a screen edge. When the screen's size or the UI's scale changes, every shown window
    at rest is placed anew (no larger than the screen now), and one that stands full lays out what it holds
    anew, once (`docked`).
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
    window was placed (a window let go at the edge, under the mouse), not while a button is held with nothing
    on the cursor (a window moved, the camera turned; with an item, spell or macro on it, `GetCursorInfo`, it
    is a drag to drop it: the full bags go back for the action bars), not while
    `usable` says no. Then size and place go, frame by frame, from where the window is to the whole screen
    (anchored to it at the end, `SetAllPoints(UIParent)`) or back to `Dock.Rect` of its zone at the size it
    had (then `window:Place()`). One window fills the screen at a time: as one begins to, every other shown
    window that fills it, or is on its way there, goes back (`Others`); unclamped on the way, strata `HIGH` and raised above the rest of it until
    it is back (the window's own layer and level after). Until then it takes the mouse and the wheel (as the
    game's map does while it is locked): nothing behind it is clicked, nor the camera turned or zoomed. Under
    it all its background, a Shape in the window (solid black, `Edge.SOLID`, or one of `Skin.TILES`,
    repeated at its size; the trim bronze), whose alpha follows the way up to the opacity set, and whose
    corners are measured on the window at rest and flatten as it comes (`Flatten(cover)`: full, square, the
    trim out of the screen, whatever `corners` and `squareEdges` say); a skin of the window fades out as it
    comes (held meanwhile: `skin:Hold`, one fit a step). What it holds (`content`) fades out in `Edge.OUT` and
    comes in once it stands, in `Edge.IN` (0.4 s) from `Edge.DROP` (10) above, as a panel's intro
    (`Motion.Fade`, `Motion.Slide`). `docked` is called at the end, so the window lays out what it holds for its
    new size once. Not in Edit Mode. A module's hooks (`docked`, `filled`, `motion`) run guarded (`Core.Safe`):
    one that fails leaves the window as it should be.
    While `away` it is neither dragged nor sized, its grip out of sight. `window:Place()` from elsewhere (a
    reset), hiding it, or a failing step bring it back at once; a failing step also stops the feature for
    that window (`edge.off`). Nothing of it is kept: after a `/reload` it is in its zone.
  - **Classic windows** (`Classic.lua`): a window's option `classic` (a list, or a function giving one, of
    `{ text, show }`) names the game's own windows it stands for. While it stands full (not on the way) the
    dropdown *Classic windows* (`WowStyle1DropdownTemplate`, its words fixed by `OverrideText`,
    `Edge.MENU_WIDTH` 180) sits in the title bar, `Edge.MENU_INSET` (10) left of its buttons, above what it
    holds (`Edge.MENU_LEVEL`, 50 over the window) and above the title bar (`Edge.MENU_OVER`, 10 over it, as each
    time it shows: the full map's bar stands over the map, `Window.UNDER`, and carries its controls 5 over it):
    every window's entries (`Window.All`), each under its window's title (`CreateTitle`), this one's
    first. One chosen: `edge:Fill(false)`, then the entry's `show()`. The other way, an entry with `frame`
    puts the button *Sane UI* onto the game's window (`Window.Beside`, beside its close button or left of its
    sizing button, `MaximizeMinimizeButton`/`MaximizeMinimizeFrame`): pressed, the game's goes, a kept choice
    is ours again (`back`), ours is shown (`ours`, else `Native(false)` and `Show`) and with `full` fills the
    screen. On a panel of the game's (it has a close button, no `plain`) the button is a
    `SecureActionButtonTemplate` on UIParent (`type` `click`, `clickbutton` the close button, `useOnKeyDown`
    false: on the release, whatever the game's key-down setting): the game closes its own window, our part runs
    in `PostClick`; it is made, shown, hidden and raised out of a fight only (`PLAYER_REGEN_ENABLED` catches up).
    In a fight it is only made clear while the game's window is gone, and a press then does nothing of ours. A
    `plain` window (the bags, the minimap) has a plain button, and our
    code hides it (`hide`). Shown while the game's window is visible and `ready()` says yes; a window loaded on
    demand (`addon`) gets it at `EventUtil.ContinueOnAddOnLoaded`. An entry for a panel our code may not open
    says its key instead (`Classic.Press(what, binding)`). What the window holds should start
    `Window.BAR` below its top while full, under the title bar.
  - **The section *Expand window*:** `Edge.Options(list, at, tab, under)` puts it into a module's switches
    (`Core.Options`) at that place: *Can expand to fullscreen* (on; off: no strips), *Hotcorner requires leftclick* (off; on:
    the strips take a left click instead of the mouse's coming, each click one change), *Animation type* (Use
    global type), *Background opacity* (0 to 100 %, 50), *Background texture* (Solid black, or one of
    `Skin.TILES`: Marble, Rock, Slate, Iron, Night, as Social's bubbles choose from them), *Corner radius*
    and *Don't round corners on screen edges* (`Shape.Options`, under the first). `under` names switches of
    the module's own each one stands under too (Social: `{ motion = "animations" }`, its *Animation type*
    greyed out while all its animations are off). The window reads them by `Window.New`'s
    `edge = ns.options`; `edge = true` takes `Edge.DEFAULTS`; `motion` overrides the section's type. A change
    of one (`Edge.KEYS`), from the options or a profile: `edge:Update()` of each window with those settings,
    by Core itself before the module's `changed` is told (seen at once, also while the window fills the
    screen); the module need do nothing.
  - **Cost:** while a window is dragged its place is looked at every frame (for the tinted shape); from the
    mouse's coming onto a window that opens under it until it is closed again, ten times a second for the
    mouse (Expand's `Core.Hover`; none while it is kept open); a size change is one of
    the game's animations (`Motion.Clock`), its skin fitted once a step; a bar's rise moves only its fill
    and flare. The push against a screen edge is an event. A long search goes a part per frame
    (`Fuzzy.Filter`). Otherwise nothing runs.
  - The look and the motion: square at the screen edge, round elsewhere, the tile of the game's dark dialogs
    with a bronze trim; the motions are the game's own easing curves (`EasingUtil`) with times set here.
- **Tests:** `lua5.1 dev/tests/core.lua` (Core with its options), `lua5.1 dev/tests/sync.lua` (Sync) and
  `lua5.1 dev/tests/window.lua` (the windows).

## Files
| File | What it is |
|---|---|
| `SaneUI.toc` | The addon `SaneUI` |
| `Core.lua` | Chat, events, errors, modules, `/sane` |
| `Saved.lua` | The saved settings and the description of the switches |
| `Presets.lua` | What the profile Speedleveling sets over the defaults: our recommended CVars, Speed Leveling's switches (`Core.Presets`) |
| `Profiles.lua` | Where every module's settings live: the character's own (the profiles off, at first) or a profile; the profiles turned on (Accountwide made from this character's settings) and off |
| `Unsaved.lua` | Changes made in the menus kept or taken back: the last save, what differs from it, Yes into the profiles ticked, No, a step waiting for the answer (`Core.Unsaved`; its window is `Settings/Save.lua`) |
| `Serial.lua` | Plain values as a line of text and back (`Core.Serial.Write`, `Read`): a profile exported and imported |
| `Kit.lua` | Small helpers for every module: `Core.Word`, `RGB`/`Hex`, `Pixels`, `FormPower` (your druid's power in a form, shown beside your mana; `Core.MANA`), `Mana` (a unit's mana as the game gives it), `Tip`, `Unconfirmed` (the line *! Unconfirmed Data !*; `UNCONFIRMED_MARK`, the red ! before each such thing's name), `TipLook`/`TipSection`/`LookOf` (a creature on a map, drawn by the Tooltips module like a unit), `Pool`, `Confirm`, `AskText`, `AskPlayer` (a small card of the kit asking for a player: its field searches the players the game knows as the name is typed, the game's own list under it, `C_AutoComplete` through `AutoCompleteEditBoxTemplate`; Share in red, Cancel; `done(name)`; `Core.ASK_PLAYER` its words), `Font`, `Sound`, `Lend` |
| `Dock.lua` | The zones at the screen's edges, and the shape that shows where a dragged window docks |
| `Shape.lua` | A plate with round corners and a trim, square where it touches the screen's edge |
| `Skin.lua` | A round dark plate on a Shape, one with an edge it is docked to (a window's with `skin = "round"`; the options' screen, small fields) |
| `Look.lua` | The kit (`Core.Look`, `Doc/guides/interface-style.md`, *The kit*): Sane UI's windows of WoW: Forever's own parts by their atlas names, a stand-in where a game lacks one: the heavy bronze frame (`Look.Frame`, every window's skin and the board's panels), its plate, the thin golden line, the grey square and the red buttons, the character list's search box, the character window's heads, bands and gear slots, the inside frame, the grey box, the loading bar's frame, the top bar's tabs, Friz Quadrata (`Look.Font`) |
| `Motion.lua` | The kinds of motion (Glide, Swing, Even, Instant) on the game's easing curves, and a clock that runs only while something moves |
| `Window.lua` | Moving and sizing a window (in Edit Mode), keeping its place |
| `EditMode.lua` | Whether Blizzard's Edit Mode is open |
| `Escape.lua` | Esc: one stand-in in the game's list for everything of Sane UI's it closes |
| `Watch.lua` | A look a few times a second while there is something to see; the mouse on a window |
| `Rest.lua` | What shows only while it is needed: a set of frames out of sight while you are at rest |
| `Fuzzy.lua` | Forgiving search of typed words in texts, ranked, for the windows' search; a long list a part per frame; Up, Down and Enter over a search box's fly-out |
| `Edge.lua` | A docked window that fills the screen when the mouse is pushed against its screen edge |
| `Classic.lua` | The game's windows Sane UI's stand for: the dropdown *Classic windows* across modules, the button *Sane UI* on the game's windows |
| `Views.lua` | A window's views behind the game's tabs |
| `Selection.lua` | A window chosen in Edit Mode, and its dialog, with the settings a window brings |
| `HealthMarks.lua` | What every health bar shows besides the health: the barrier, the lost maximum health, what can be dispelled |
| `AuraLog.lua` | The buffs and debuffs seen on whoever you can attack, kept as a history for a view to show (`Core.AuraLog`) |
| `Secrecy.lua` | Which spells the game hides from addons, asked of the game for the developer's lists (`/sane secrets`, `saneui showsecrets`) |
| `Holder.lua` | The game's window kept out of sight while ours stands for it |
| `Seat.lua` | A window not ours seated in a room of a full window: its place, scale and layer lent (its pinned parts' layer too), followed, given back |
| `Board.lua` | A module's full screen of windows, laid out as the player arranges them, in layouts behind tabs |
| `Icons.lua` | The icon chooser: the game's icons by group, searched, for every module that lets the player pick one |
| `Neighbours.lua` | The other addons Sane UI knows and adapts to when they are installed: the one file that names them |
| `Switches.lua` | The quick switches the modules offer, for a view that gathers them (`Core.Offer`) |
| `Ways.lua` | The way to a place, between a module that leads the player and the one that finds ways (`Core.Ways`) |
| `Sight.lua` | The herbs and ore in sight now, between the module that finds them and one that leads the player (`Core.Sight`) |
| `Spellbook.lua` | What a spellbook shows beyond the game's spells, between the module that knows it and the one whose book shows it (`Core.Spellbook`) |
| `Units.lua` | Distances and the time of day as the setting *Units* says (`Core.Distance`, `Core.Clock`) |
| `Stats.lua` | The stats as players write them (`Core.StatWord`, `Core.StatLine`) |
| `Upgrade.lua` | Whether an item would make the character better (`Core.Upgrade`), for the loot, the bags and quest rewards |
| `Expand.lua` | A window that opens while the mouse rests on it, and can be kept open |
| `Bar.lua` | A progress bar whose value and size move |
| `Bindings.lua`, `Bindings.xml` | Sane UI's section in the game's key bindings, and its key for the options |
| `Demo.lua` | `/sane window` |
| `Objectives.lua` | `Core.UnitQuest(unit)`: what is still to do about a creature for a quest in your log, as the game says it in its tooltip data (`C_QuestLog.UnitIsRelatedToActiveQuest`, then `C_TooltipInfo.GetUnit`'s lines of the kind `QuestObjective`): `"kill"` or `"loot"` and the count of the first objective still open; `false` while the game hides it. Read by Nameplates and Combat's quest marks |
| `Inspect.lua` | `Core.Inspect`: a player's item level and talents for every view (`Level`, `Talents`, `Watch(fn)`; Forever's talents as a spec with its points per group, Retail's the specialization alone), by paced inspections: out of a fight, `CanInspect` and `CheckInteractDistance`, the game's inspect window closed, one question at a time 2 seconds after anybody's last (`NotifyInspect` hooked), the same player not again for 15 seconds, an answer kept 5 minutes. Read by Tooltips and Nameplates |
| `Audio.lua` | The sound profiles (`Core.Audio`): the game's five sounds on or off with their volumes under a name, the account's last one set again at each login; the defaults *All sound on*, *Music off*, *Music and Ambience off*, *All sound off*; `Add` for other code |
| `People.lua` | Aliases and notes of players: *Set Alias* and *Set Note* (and *Remove Alias*, *Remove Note* for one that is there) in the game's menu of a player (`Menu.ModifyMenu` on its `MENU_UNIT_*` tags), kept in `SaneUIDB.modules.Core.people` by the player's key |
| `Data/` | The data framework: `Steps.lua` (the scheduler), `Codec.lua` (a set's row into a record, and a record learned into a row), `Data.lua` (the sets, the answers, the data's saved variables, what Core learns in play), `Map.lua` (what the data puts on a map), `Ships.lua` (the ships' timetables and times), `Trips.lua` (the trip underway), `Teleports.lua` (where a teleport of *Travel* brought the player, learnt), `Characters.lua` (what the account's characters have), `Wire.lua` (Sane UI's addon messages: messages and blocks, the queue that keeps to the game's budget, the inbox), `Guild.lua` (the guild's records: the roster, its history, what members share with the guild), `Confirm.lua` (what the game confirmed in play of the data not yet verified, kept and shared with the guild and the group), `Check.lua` (what the game told compared with the sets field by field: confirmed or learned), `Tally.lua` (what play counts per build period: loots, visits, places seen, cells), `Drops.lua` (how often things come, for every view: the set Drops, this account's counts, the members'), `Found.lua` (the discoveries and their chat lines), `Watchers.lua` (Core's watchers: creatures, things, mailboxes, crossings, a boss's loot and casts, the stats of the items the character has), `Quests.lua` (the quest watchers: offered, taken, worked on, handed in), `Loot.lua` (every loot window counted: corpses, skinning, pockets, nodes, fishing, quest items, where), `Facts.lua` (creatures, their services, vendors' goods, spells and the tooltips' items, compared), `Rhythm.lua` (how an item's price goes with the clock and how it sells, one short line per item, for a forecast), `Prices.lua` (what a thing fetches at the auction house, for every view: what it lists now, else the last scan), `Fees.lua` (what the auction house takes and what that leaves, by the game's own rates), `Scan.lua` (the full scan of the auction house while it is open, every 16 minutes, kept per house in `SaneUIData_Market`, the file of its own of `SaneUI_AuctionData`), `ScanBar.lua` (its bar under the game's auction house window), `Relay.lua` (a scan shared with the guild and the group: have, want, blocks, the login's question), `Bundle.lua` (counts and discoveries shared with the guild and the group every 15 minutes, kept apart in `SaneUIData_Shared`) ([Doc/guides/data.md](../../Doc/guides/data.md)) |
| `Sync/` | Sync: the game's own per-character settings kept with Sane UI's ([README](Sync/README.md)) |
| `Settings/` | The options: the pages, their controls, `/sane options` ([README](Settings/README.md)) |
| `Art/banner.blp`, `Art/icon.blp` | Sane UI's logo (the S), the banner on the options' page *Sane UI*: one of Sane UI's family of logos (`dev/tools/logo-art`), its banner at the top of its options page, its icon in the addon list (the TOC's `IconTexture`). Original art of Sane UI (see the project's `LICENSE`), made by `dev/tools/art` from `assets/Logos/core-banner.png` and `core-icon.png` |
| `Art/circle.blp`, `Art/circle-hole.blp` | The masks round corners are cut with: a white disc, and a white square with the disc taken out (256 × 256, DXT5 with mipmaps). Made by `dev/tools/shape-art`, drawn by code |
| `Art/ring.blp`, `Art/ring-wide.blp` | White rings as large as the picture (`Shape.RING`, `RING_WIDE`, the wide one the thicker band), for the game's Cooldown widget to sweep: Combat's rings around the mouse (256 × 256, DXT5 with mipmaps). Made by `dev/tools/shape-art`, drawn by code |
| `Art/corner-tl.blp`, `Art/corner-tr.blp`, `Art/corner-bl.blp`, `Art/corner-br.blp` | One corner of a rectangle (`Shape.CORNER`): white but for the corner it is named for, cut away outside a quarter circle as wide as the picture (64 × 64, DXT5 with mipmaps), laid over that corner as large as the radius with `CLAMPTOWHITE`. Made by `dev/tools/shape-art`, drawn by code |
| `Art/soft-corner.blp` | The top left corner of a plate whose edge fades out softly (`Shape.SOFT_CORNER`): white, its alpha whole inside a round corner (three eighths of the picture) whose arc is centred seven eighths in, fading smoothly to nothing over half of the picture towards its edges; its last column and row the straight edge's fade (64 × 64, DXT5 with mipmaps). A texture, not a mask: Lore's plates are nine pieces of it. Made by `dev/tools/shape-art`, drawn by code |
| `Art/cap-left.blp`, `Art/cap-right.blp` | A bar's two ends (`Shape.CAP_LEFT`, `CAP_RIGHT`; Nameplates' health bar): white but for the two corners on the outer side, cut round with a radius as wide as the end; a quarter as wide as high (64 × 256, DXT5 with mipmaps), laid over a quarter of the bar's height at each end with `CLAMPTOWHITE`. Made by `dev/tools/shape-art`, drawn by code |

## History
- 2026-11-15 — Profiles off at first (Saneroki: "the whole profiles should be disabled by default and can be activated
  in the settings or during the onboarding procedure"): a fresh install keeps every character's own settings, Sync
  writes nothing and no preset is given; the switch *Share settings between characters* on the page Profiles,
  `/sane profile on`/`off`, `Core.Profiles.Enabled`/`SetEnabled` (Onboarding). Turned on the first time, *Accountwide*
  is the character's settings as they are, the game's read by `Sync.Take`, nothing written; *Accountwide* is given no
  preset any more (*Speedleveling* keeps its). Turned off, the profiles are kept, each character keeps its settings
  as its own, the game's stay. `Profiles.VERSION` 3: settings saved before count as on.
- 2026-11-15 — The kit (Saneroki: "I want to restyle windows fullscreens now ... closer to Wow Forever styling with
  its native elements"): `Look.lua`, Forever's own parts for every window; a window's skin and the board's panels
  the heavy bronze frame (what they hold inside its band: `Board.BAND`, `HEAD` 40, `EDGE` 12), the board's layout
  tabs the character screen's top bar, a full window's title bar 44 high (`Window.FULL_BAR`, the tabs in its middle; the shop's strip taken off again), the title
  bar's buttons the grey square ones and its search box the character list's; the journal's dress gone from the
  board. Then the rest: Navigation's satchel and audio line, the combat text (the game's font and words, its
  drawings and their setting gone), the bar font's fallback; `Journal.lua` and `Art/Journal` gone (the loot feed keeps
  its hand-drawn Kalam Bold, `Look.HAND`, by Saneroki's word).
- 2026-11-15 — Every element's options, built 2026-11-14 and taken out again (Saneroki: "Remove all those options again
  for now", to come back "only within the edit mode", which is to be redone: board #488): `Element.lua` is gone, the
  right clicks of the elements and the action bars are as before; `Doc/ideas/Windows.md`, *Every element's options*.
- 2026-11-13 — A druid's mana for its group, tried and taken back (Saneroki: "let my druid send its mana to the
  party", then, as it never came through, "revert back to how it was with only one class bar"): `Mana.lua` and the
  wire's live messages are gone; `Core.FormPower` answers for yourself alone.
- 2026-11-11 — A seated window's pinned parts (`Seat.lua`, Saneroki: the trainer's window "is empty" the first time on
  the full screen): the parts the game pinned above it in a strata of their own are lent too, lifted above the rest of
  it in the room's strata, and given back after it, at their own strata and level.
- 2026-11-09 — A talk's layout on the board (`Board.lua`, Saneroki): `occasions`, `board:Occasion(name)`, `board:Talking()`,
  its tab first in the title bar while the talk is on; and `Core.Seat.Part` (`Seat.lua`), the game's window as a board's
  part. Inventory's full screen comes at a vendor and a banker, Combat's at a trainer.
- 2026-11-07 — Rest in a group too (`Rest.lua`, Saneroki): `rest:InGroup(on)` keeps a set at rest in a party or raid;
  `Core.Rest.Busy(inGroup)`. Combat's unit frames and action bars and Navigation's quest log offer it.
- 2026-11-06 — Spellbook offers (`Spellbook.lua`, Saneroki): the module that knows what a spellbook shows beyond the
  game's spells serves it (`Core.Spellbook.Serve`), the book that shows it lays it out and is told of a change
  (`Watch`); Abilities' spells still to learn, weapon skills, Home and reservations in Combat's spellbook.
- 2026-11-04 — Sound profiles (`Audio.lua`, Saneroki): the game's five sounds on or off with their volumes under a
  name, per game account, its last one set again at each login (two clients of one installation on different
  profiles at once); Sync leaves their CVars alone (`Sync.Leave`). Shown in Navigation's satchel (`AudioLine.lua`).
- 2026-10-26 — Quick switches (Saneroki): a module offers a switch (`Core.Offer`), a view lists them
  (`Core.Switches`) and is told of a change (`Core.OnSwitches`); Navigation's satchel shows them, Speed Leveling
  offers its guide on, paused or off.
- 2026-10-25 — Forever and Retail (Saneroki): Core tells the games apart (`Core.GAME`, `Core.ForGame`,
  `Core.ServesGame` and `## X-SaneUI-Games` for a module of one game). In Retail: Sync writes only the game's
  settings read in that game (`Sync.options.from`: a game folder's saved settings copied into the other's no longer
  carry Forever's options, layout, chat windows and bars into Retail); the data framework says nothing of a set it
  lacks where the game version has no data at all; `Core.Inspect.Talents` gives the specialization, without points;
  the bar's dividers are a thin line of ours where the client lacks their art.
- 2026-10-24 — The data made better by play (Saneroki): `Data.Check` compares what the game tells with the sets field
  by field (confirmed where it agrees, learned where it differs or the set lacks the entry, the parts told kept for
  the harvest); `Data.Tally` counts loots, places and cells per build period. Watchers: quests offered, taken, worked
  on and handed in (`Data/Quests.lua`; a quest only Forever has learned whole), every loot window (`Data/Loot.lua`),
  creatures, services, vendors' goods, spells and tooltips (`Data/Facts.lua`); spawns confirmed point by point. The
  harvest adds every player's counts up in a ledger and stages chances, narrowed points and areas once enough agree.
- 2026-10-23 — What the game confirms in play (`Data/Confirm.lua`, `Data/Watchers.lua`; Saneroki): the set files
  list the entries a batch alone says, and `Handle:Unverified` asks; creatures seen or talked to near their spawn,
  mailboxes, crossings, a boss's loot and casts confirm them; the items the character has teach their stats; all of
  it kept, shared with the guild and the group (out of fights and instances), and harvested into the master
  (`dev/tools/data harvest`). `Core.Unconfirmed`, `Core.TipLook` (a creature on a map drawn like a unit).
- 2026-10-21 — What Core learns in play (`Data.Learn`, the saved variable `SaneUIData_Learned`; a whole row of the
  set, read over its own while newer, dropped once a release is as new) and its first watcher (`Data/Teleports.lua`:
  where a teleport of *Travel* brought the player, for Navigation's routes); `Codec.Encoder` ([Doc/guides/data.md](../../Doc/guides/data.md), *Learned*).
- 2026-10-21 — The data packs are gone: every set of Core's data is one of Core's own files (`Sets/<Set>.lua`,
  made by `dev/tools/data` and listed at the end of the built TOC), read with Core at the login, so the addon list
  shows only the modules; the data's saved variables (`SaneUIData_Characters`, `SaneUIData_Guild`) are Core's
  (`Data.SAVED`, `Data.Saved`), and `/sane data` lists the sets and the saved parts (Saneroki).
- 2026-10-20 — Sane UI's addon messages (`Data/Wire.lua`, `Core.Wire`: the prefix `SaneUI`, messages and packed blocks,
  a queue that keeps to the game's budget, an inbox the scheduler takes in) and the guild's records (`Data/Guild.lua`,
  `Data.Guild`: the roster and its history, members' records shared with the guild, this character's card; the pack
  *Guild*), for the module Guild; a module's window on another module's board (`Core.Board.Offer`, `Withdraw`,
  `Offered`, `Open`, `Standing`, `Close`; Saneroki).
- 2026-10-20 — The board's icon tabs (`Board.lua`): a window whose spec has an `icon` gets a tab of its own after
  the layouts' tabs and `+`, its icon in place of words (`MinimalTabTemplate`), lit while it is in the layout
  chosen; a click puts it in or takes it off, as its tick in the dropdown *Windows* does (Saneroki).
- 2026-10-20 — `Data.Worn(key)` (`Data/Characters.lua`): what a character wears slot by slot, by the game's inventory
  slot IDs, kept beside the place `worn` (packed, `slots`); for a paper doll of an alt in Inventory (Saneroki).
- 2026-10-20 — `Data.Items(key, place)` (`Data/Characters.lua`): what a character keeps in a place, or the account's
  bank, item by item in the order kept; for Inventory's window of the other characters (Saneroki).
- 2026-10-20 — The board (`Board.lua`, `Core.Board`): a module's full screen of windows that share it as the player
  arranges them, in layouts behind tabs in the title bar; the title bar's search box ends left of its dropdown
  *Windows* (Saneroki).
- 2026-10-20 — The seat (`Seat.lua`, `Core.Seat`): a window not ours on a full screen, placed, never shown or hidden
  by our code (Combat's talents and spellbook). `Core.Lent(frame)`. The known addons (`Neighbours.lua`,
  `Core.Neighbours`). Edge's strip of a share of the screen's side (`strip`).
- 2026-10-20 — The trip underway (`Data/Trips.lua`, `Data.Trips()`): a flight read at the flight master and followed
  by the player's place, a boat or a zeppelin aboard, the tram; its stops and times, a flight's early landing; for
  Navigation's trip view and its line while flying.
- 2026-10-20 — The ships' times (`Data/Ships.lua`, `Data.Ships()`): the boats' and zeppelins' timetables from *Travel*
  (the game's transports' speed, the set's `wait`), and when each sails on this realm, learnt on a ride and kept
  per realm on this computer; for Navigation's routes and its dock watch.
- 2026-10-20 — What the data puts on a map (`Data/Map.lua`, `Data.Map()`): the places of Spawns, Places and Travel
  per map, for Navigation's pins. The dropdown *Classic windows* takes kept choices: a checkbox, ticked while the
  game's own window is the one chosen, chosen again to come back.
- 2026-10-18 — Aliases and notes of players (`People.lua`): *Set Alias* and *Set Note* in the game's menu of
  a player, wherever it opens; kept for the account by the player's key, personal, never shared. Social's
  chat and friends list and the Tooltips' player tooltip show them.
- 2026-10-17 — What the account's characters have (`Data/Characters.lua`): each character by its GUID with
  its whole name (first name and surname), its bags, what it wears, its bank, and the account's bank, kept in
  the saved file of the pack *Data: Characters*; `Data.Count(item)` says where the account has an item.
  Packs of saved data (`Data.Saved`), and a warning when such a pack's saved file was lost.
- 2026-10-17 — The windows, finished and filled in: closing and Esc wait for a fight's end; a first zone
  (`first.dock`: the talk kind in the middle) and standing clear of a window that holds it (`Window.CASCADE`);
  a motion whose frame is hidden is at its end at once; no full screen in Edit Mode; every module hook
  guarded. One Esc stand-in for all of Sane UI (`Core.Escape`, `SaneUIEscape`). `Core.Watch`, `Core.Hover`
  (Expand on them), `Motion.Fade`, `Motion.Slide`, `Fuzzy.Filter`, `Skin.TILES` (was `Edge.TEXTURES`),
  `Shape`'s fixed radius, `Follow`, `alpha` and `Shape.Round`. `Edge.Options` takes the module's own parents,
  and a change of the section is followed by Core. New for windows: `inside`, `SetTitle`, module buttons,
  tabs in the game's style (`Views.lua`), to the front (`toplevel`), `insets`, `Window.All`, `ResetAll`
  (`/sane window reset all`), the holder (`Holder.lua`), and in Edit Mode a click on a box selects it, with a
  dialog *Reset To Default Position* (`Selection.lua`) and the grid's snap. Key bindings: a section *Sane UI*
  and a key for the options (`Bindings.xml`). `/sane window` is a panel with two tabs and a button of its own.
- 2026-10-17 — Profiles anew (Saneroki): *Accountwide settings* (on at first) with the profile *Accountwide* for every character, the game's settings in profiles only, each module's settings in one place (the profile in use or, off, the character's own) and moved, never copied at the logout; *Empty*, *SaneUI Defaults*, *Load at login*, *Save at logout* and the per-module switches gone (the first shape brought over once). New: *Copy from*, *Defaults*, *Export*/*Import* (`Core.Serial`), *Forget*, `/sane profile`. Settings carry their version (`version`, `upgrade`), are made right whenever they come into use (`Core.Settle`), and can be set from elsewhere (`Core.Set`). Core: `AfterCombat`, `Locked`, `Restricted`, `Off`, `OnUnit`, blocked actions in the error log, the kit (`Kit.lua`).
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
- 2026-10-23 — What the game says about a unit, for every view (Saneroki: data is Core's): a creature's quest
  objective (`Objectives.lua`, from Combat's quest marks) and players' item level and talents by paced inspections
  (`Inspect.lua`, from Tooltips).
- 2026-10-23 — Corner masks (`Shape.CORNER`, `Art/corner-*.blp` by `dev/tools/shape-art`): one corner round at any
  radius and height, for Nameplates' outline around its bar and cast bar.
