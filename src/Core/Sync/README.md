# Sane UI: Sync (part of Core)

**Status:** written and tested offline · **Since:** 2026-10-14 · **Addon:** `SaneUI` (Core), folder `src/Core/Sync/`

## TL;DR
The game keeps much of what you set for each character alone: the options you chose on its pages, the Edit
Mode layout in use, the chat windows, the channels you joined, the map filters, the tutorials you have seen.
A new character starts without them. Sync keeps them with Sane UI's settings instead, laid out as the game's
own options are, in the profile in use: they are the same on all your characters that use one profile. On
*Character specific* Sync does nothing, and a character turning to it gets the game's default CVars back. (Joining or leaving
the game's own chat channels on every character is the Social module's.)

## How to use
- **Its checkboxes are on the page *Profiles*** of the game's options (Esc > Options > AddOns > Sane UI >
  Profiles), in the tab *Game settings*; Sync has no page of its own.
- **Game settings:** a box for each of the game's groups of
  options pages, with a checkbox for each of its pages, named as the game names them; then a box for what is
  on none of its pages:
  - **Gameplay:** Controls, Interface, Action Bars, Combat, Social, Gamepad, Keybindings (only the modifier
    keys of clicks: to link in chat, to self cast, to split a stack; not the key bindings), Nameplates.
  - **Accessibility:** its pages with settings of their own (General, Colors, Audio).
  - **System:** Graphics (not the screen and its hardware), Audio (not the sound devices).
  - **Elsewhere in the game:** Edit Mode layout, your own chat channels, chat windows (tabs, what each shows,
    where they stand, the colours of the kinds of chat), other per-character settings (map and minimap
    filters, the quest log, the calendar, tutorials seen, and whatever else the game keeps per character).

  All are ticked at first. The mouse over a checkbox says what it holds. An unticked part is left to the
  game, which keeps it for each character. A ticked part is read into the profile in use when you log out
  (and when you make a new profile or use another), and set when a character comes into the game (and when
  another profile comes into use). Each profile keeps its own ticks.
- **The game shows chat windows and the extra action bars after a `/reload`,** and after another Edit Mode
  layout or chat colour a reload gives its frames back untainted. When a character got such changes, a
  dialog offers the reload (*Reload* / *Later*), once each time.
- **Whose settings:** the profile's in use (tab *Profiles*). The first character to log out after a part was
  ticked gives its settings to the others of that profile. On *Character specific* nothing is kept: each
  character has the game's own, per character.
- **Addons** (`Addons.lua`): which addons are switched on, in the box *Elsewhere in the game*. Written where the
  profile differs, for this character (`C_AddOns`), with the reload offered; never Sane UI itself, nor one this
  client lacks.
- **Key bindings** (`Keys.lua`, Saneroki, 2026-10-30): every key of the game's list by command, Sane UI's and other
  addons' too, written where they differ and saved in the game's binding set in use. A command this client does not
  list now keeps its keys in the profile. Turning to *Character specific*: the game's default keys (`part.Default`).
- **Edit Mode layouts** (`Layout.lua`): which one is in use and the layout itself, as the game's own text of it; a
  character that does not have it gets it, through `C_EditMode` alone (`Add`). The game's own account layouts are
  shared by the game as well.
- **All other CVars:** the part *All other game settings* takes every CVar the game stores for a character or an account,
  on no page (it was the character's alone before), not what a character tracks or last chose, nor this computer's.
- **Single CVars:** in the tab *CVars*, tick any CVar to keep it the same way.
- **Not keeping any:** untick every part (and no CVar ticked in the tab *CVars*): the game's settings stay as
  they are, each character with its own. Sync is part of Sane UI, so it is not in the addon list.

## Technical details
- **Part of Core,** not a module: its files are in Core's TOC and share `Core.Sync` (no `SaneUI.Sync`). Its
  settings are described to Core as a module's are, under the name `Sync` (`Core.Settings("Sync")`), with the
  hook `game = true`: they live in the profile in use only, never in a character's own (on *Character
  specific* they are a table of the session, and `Give` and `Capture` do nothing). Being no module, it
  gets no page of its own: the tab *Game settings* of the page Profiles (`Settings/Synced.lua`) shows a checkbox per part, a box per
  `Sync.GROUPS` entry. Its work starts from Core's events: its settings at Core's `ADDON_LOADED` (after
  `Saved.lua` and `Profiles.lua`, which come first in the TOC), the writing at `PLAYER_ENTERING_WORLD`.
  `Sync.Safe` notes a failure as `Sync: <step>`.
- **What is kept, where** (Sync's options, none with a control of the game's options):

  | Key | Holds |
  |---|---|
  | `off` | `[part id] = true` for each part left to the game; every part is kept at first, a new one too |
  | `taken` | `[part id] = data`: what each kept part read last |
  | `named` | `[CVar] = value`: single CVars kept by name (the tab *CVars*, `Sync.Keep`/`Sync.Kept`), our recommended ones among them (`Presets.lua`) |

  A character that comes over from another profile to one that holds nothing yet of a part with a `Default` (the key
  bindings) gets the game's own there, not what the profile it left had (`Sync.Moved`).

  Settings of an earlier version in another shape are not read: an unknown value counts as unset.
- **The parts** (`Sync.Part(id, group, part)`; `part.Read()`, `part.Write(data)`, `reload` words):
  - **A part per options page** of the game's groups Gameplay and Accessibility (`Game.lua`), its id the
    name of the game's string for the page (`CONTROLS_LABEL`), its words the game's. What a page sets comes
    from `Data/Pages.lua`, which `dev/tools/sync-pages` makes from Blizzard's options code in `references/`
    as this client loads it (`--check` says whether it is up to date): the CVars the page registers or
    writes (sorted by name; a CVar two pages have stays with the first), pairs of game functions its proxy
    settings read and write (`GetAutoDeclineGuildInvites` / `Set...`), the modifier keys of clicks it offers
    (the page Keybindings takes the rest of the client's bindings file), whether it switches the extra
    action bars. Left out by the tool: the computer's speech voices.
  - **Graphics and Audio** (group System): every CVar of the game's own kinds Graphics and Sound
    (`Enum.ConsoleCategory`), as the game lists them (`ConsoleGetAllCommands`).
  - **Other per-character settings:** every other CVar the game stores for each character
    (`C_CVar.GetCVarInfo`: stored for the character, not locked, not read only) that no page holds.
  - These last two are found once a session at the first writing, whatever the profile holds, in one pass that
    is a job of Core's scheduler (`Core.Steps`: a few milliseconds a frame, never in a fight); until then what was
    kept stays, and what is to be set is set once they are found. Never taken by them: a character's state (tracked, collapsed, last
    chosen or seen), one computer's (`gx*`, drivers, devices, monitor, window mode, speech voices), and a
    CVar the game does not let addons set (locked, secure or read only).
  - **Edit Mode layout** (`Layout.lua`), **your own chat channels** and **chat windows** (`Chat.lua`).
  - Each part reads only what this client has and writes only what differs; one the game does not answer
    (a flag, a modifier key) keeps what was kept. Data of a shape this version does not know is skipped:
    each value is checked for its kind first, so a chat window's switch, colour or place of an older shape,
    or a shorter list of the action bars, leaves that setting as the game has it.
- **Read** (`Sync.Capture`, given to `Core.Options` as its capture): Core calls it before Sane UI's settings
  are copied or saved anywhere: a new profile made, another one used, the logout. Kept parts are read from
  the game; the others are dropped. Nothing is read before this session wrote the settings into the game,
  so a character that leaves before then does not spread its own.
- **Written** (`Sync.Give`): 2 seconds after the first `PLAYER_ENTERING_WORLD` of a session once the game
  has its stored settings (`C_CVar.AreCVarsLoaded`, else 2 seconds after `VARIABLES_LOADED`), and when
  another profile came into use or *Accountwide settings* was switched on (Core's hook `moved`), once the
  first writing came due.
  Never in a fight: then at `PLAYER_REGEN_ENABLED`. Only in the game they were read in (`from`: `forever` or
  `retail`; those kept before Sane UI served two games are Forever's): each game has options, CVars, layouts and
  chat windows of its own, so another game's (a game folder's saved settings copied into the other's) are neither
  written nor handed out (`Sync.Taken`), and this game's take their place at the next reading. Your own channels are joined before the chat windows are
  written (a join puts a channel into the first window). One reload dialog per writing (`Sync.OfferReload`,
  through `Core.AskReload`) names what the game shows only after one. The same words as the session before are
  not offered again on that character (`chars[key].asked`, read at `Sync.Began`): that `/reload` settled nothing.
  What happened goes to the error log instead, *Sync: a /reload settled nothing*, for a layout with what the
  manager and the game said (`Sync.said`). Another profile brought in that session is new and offered as ever.
- **Through the game's stored settings, never its frames** (no taint):
  - CVars with `C_CVar.SetCVar` (`Sync.SetCVar`), only one the game lets addons set: not locked, not read
    only, a secure one not in a fight. One it does not take is noted once in the error log (`/sane errors`,
    *Sync: setting CVars*) and left alone for the session; the others are set all the same.
  - **A CVar a module lends** (`Sync.Lend(name, value, own)`, `Sync.Return(name)`; Loot lends the game's Auto
    Loot off): set the module's way for as long as it needs it. Sync writes it no more meanwhile: what it would
    write becomes the player's own value (`Sync.Value(name)`), and its readings take that value, not the lent
    one, so the profile keeps the player's. Given back, the player's own is set again, unless the game holds
    another than the lent one (the player changed it). Without it a profile's value, written a moment after the
    login, undid a lend made at the login.
  - Game functions in pairs (`SetAutoDeclineGuildInvites`, ...); modifier keys
    with `SetModifiedClick`, the key bindings in use then saved with `SaveBindings`; the extra action bars
    with `SetActionBarToggles` (not where the game forces them), read by the bars at the next load.
  - Chat windows with `SetChatWindowName/Size/Color/Alpha/Shown/Locked/Docked/Uninteractable`,
    `Add/RemoveChatWindowMessages`, `Add/RemoveChatWindowChannel`, the places of the free ones (not the
    first's, which Edit Mode places) with `SetChatWindowSavedPosition/Dimensions`. The game's chat frames read
    these when the interface loads (`UPDATE_CHAT_WINDOWS`), hence the reload. A window's channels are matched only for
    those the kept windows name and the character is in or joins in that writing, so what it left is not brought back
    and a new character's public channels, which Social leaves, are no change. Colours with `ChangeChatColor`
    and `SetChatColorNameByClass`, which the frames take at once from the game's own events, in our call. The
    game keeps a channel's colour by the channel's number, which differs between characters: it is kept by
    the channel's name and given to this character's channel of that name, whatever its number here. One the
    character is not in yet (its own channel joined in the same writing: the server answers a join later) gets
    it once the join is answered (`CHANNEL_UI_UPDATE`); until then, and for a channel the character is not in
    at all, the profile keeps the colour it had.
  - Your own channels with `JoinPermanentChannel` (into the first chat window, as `/join` does): those whose
    kind is *Custom* (`C_ChatInfo.GetChannelInfoFromIdentifier`), or, without that, not on offer from the
    game (`EnumerateServerChannels`); not a community's.
  - Edit Mode with `C_EditMode.SetActiveLayout`: the manager acts on the game's event itself. The layout is
    found by name and kind in the manager's list (`EditModeManagerFrame.layoutInfo`: presets first, then saved
    layouts, and the active one), which is only read.
    - **Read as seen in the world,** never at the logout: by then the game names its first preset whatever
      was in use. The layout in use is read a frame after the manager took new layouts
      (`EDIT_MODE_LAYOUTS_UPDATED`, `PLAYER_SPECIALIZATION_CHANGED`) and when the settings are read, only
      between `PLAYER_ENTERING_WORLD` and `PLAYER_LEAVING_WORLD`; after that the last one seen is read.
    - **Set when the game lets us:** not before the manager has its layouts (early in a login), not while
      Edit Mode is open (`Core.EditMode`), not in a fight. Such a layout waits and is set when the manager
      has its layouts, Edit Mode closes or the fight is over; meanwhile it counts as the one in use, and one
      the player picks meanwhile wins over it. One
      that is not there (deleted, another character's own) leaves the layout in use, and is still the one
      kept until a layout is picked in this session: a character that does not have it does not give its
      own to the others at its logout, and the character that has it finds it again.
- **Left out, and why:**
  - The game's System pages Languages, Network and Mac: they belong to one computer or installation.
  - Edit Mode per specialization, screen-resolution settings, import and export.
  - The zone map's place, the damage meter's windows, chat tab protection: they write into the game's own
    frames or saved tables, which taints them.
- **Globals:** none.
- **Tests:** `lua5.1 dev/tests/sync.lua`, with a small model of the game's settings and the real
  `Data/Pages.lua`.

## Files
| File | What it is |
|---|---|
| `Sync.lua` | `Core.Sync`, its groups and parts, reading and writing, single CVars kept by name, its settings |
| `Data/Pages.lua` | What each of the game's options pages sets, made by `dev/tools/sync-pages` (do not edit) |
| `Layout.lua` | The Edit Mode layout in use |
| `Chat.lua` | Your own chat channels; the chat windows, their places and the colours of the kinds of chat |
| `Game.lua` | The page parts, Graphics and Audio, other per-character settings |

## History

- 2026-10-25 — Per game (Saneroki): what was read in one game is written only there (`from`), never Forever's
  settings into Retail.
- 2026-10-17 — In the profile in use only (Saneroki): with *Accountwide settings* off Sync keeps, reads and writes nothing. The tab is *Game settings*; each profile keeps its own ticks. Written again when another profile comes into use (`moved`).
- 2026-10-17 — The CVars of Graphics, Audio and the other per-character settings are found in steps, a few
  milliseconds a frame (no stall when a character comes into the game). Only CVars the game lets addons set
  are written, each on its own: one it does not take is noted once, the others are set all the same. A kept
  Edit Mode layout a character does not have stays the kept one until a layout is picked. Settings kept in
  an older shape are left as the game has them.
- 2026-10-17 — Laid out as the game's own options: a part per options page (Gameplay, Accessibility,
  System), named in the game's words, what each page sets made from Blizzard's options code by
  `dev/tools/sync-pages`; Edit Mode layout, own channels, chat windows (with their places) and other
  per-character settings under *Elsewhere in the game*. Its settings are `off`, `taken`, `named`; settings
  saved in the earlier shape are not read.
- 2026-10-29 — CVars a module lends (`Sync.Lend`, `Return`, `Value`): the profile's Auto Loot on, written after
  the login, had undone Loot's lend on a second account, and everything was taken at once.
- 2026-10-15 — Edit Mode layout: read as seen in the world, not at the logout (each logout kept the first
  preset, so every login set it); a layout that cannot be set yet waits (no layouts yet, Edit Mode open, a fight).
- 2026-10-15 — Part of Core (`src/Core/Sync/`, `Core.Sync`), no addon of its own (was `SaneUI_Sync`); its saved
  settings keep their place and name. Sync is no module, so it gets no page.
- 2026-10-14 — The game's channels (join, leave) moved to the Chat module; the tab *Chat channels* is gone.
- 2026-10-14 — Every part ticked at first. The tab is called *Accountwide*.
- 2026-10-14 — First version: the game's per-character settings kept with Sane UI's settings (account,
  character's own, profiles); the game's chat channels joined or left on every character.
