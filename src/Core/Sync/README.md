# Sane UI: Sync (part of Core)

**Status:** written and tested outside the game; **not yet tried in the game** · **Since:** 2026-10-14 · **Addon:** `SaneUI` (Core), folder `src/Core/Sync/`

## TL;DR
The game keeps much of what you set for each character alone: the options you chose on its pages, the Edit
Mode layout in use, the chat windows, the channels you joined, the map filters, the tutorials you have seen.
A new character starts without them. Sync keeps them with Sane UI's settings instead, laid out as the game's
own options are, so they are the same on all your characters and part of your profiles. (Joining or leaving
the game's own chat channels on every character is the Social module's.)

## How to use
- **Its checkboxes are on the page *Profiles*** of the game's options (Esc > Options > AddOns > Sane UI >
  Profiles), in the tab *Accountwide*; Sync has no page of its own.
- **Accountwide:** after the box *Sane UI* (Sane UI's own modules), a box for each of the game's groups of
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
  game, which keeps it for each character. A ticked part is saved when you log out (and when you save a
  profile) and set when a character comes into the game (and when you load a profile).
- **The game shows chat windows and the extra action bars after a `/reload`,** and after another Edit Mode
  layout or chat colour a reload gives its frames back untainted. When a character got such changes, a
  dialog offers the reload (*Reload* / *Later*), once each time.
- **Whose settings:** the account's, which every character shares (*All settings accountwide*, tab
  *Profiles*); with that unticked, each character's own; or, for a character with a profile and *Load at
  login*, its profile's. The first character to log out after a part was ticked gives its settings to the
  others.
- **Single CVars:** in the tab *CVars*, tick any CVar to keep it the same way.
- **Not keeping any:** untick every part (and no CVar ticked in the tab *CVars*): the game's settings stay as
  they are, each character with its own. Sync is part of Sane UI, so it is not in the addon list.

## Technical details
- **Part of Core,** not a module: its files are in Core's TOC and share `Core.Sync` (no `SaneUI.Sync`). Its
  settings are described to Core as a module's are, under the name `Sync` (`SaneUIDB.modules.Sync.options`),
  so the account's, a character's own and the profiles hold them; being no module, it gets no page of its
  own: the tab *Accountwide* of the page Profiles (`Settings/Synced.lua`) shows a checkbox per part, a box per
  `Sync.GROUPS` entry. Its work starts from Core's events: its settings at Core's `ADDON_LOADED` (after
  `Saved.lua` and `Profiles.lua`, which come first in the TOC), the writing at `PLAYER_ENTERING_WORLD`.
  `Sync.Safe` notes a failure as `Sync: <step>`.
- **What is kept, where** (Sync's options, none with a control of the game's options):

  | Key | Holds |
  |---|---|
  | `off` | `[part id] = true` for each part left to the game; every part is kept at first, a new one too |
  | `taken` | `[part id] = data`: what each kept part read last |
  | `named` | `[CVar] = value`: single CVars kept by name (the tab *CVars*, `Sync.Keep`/`Sync.Kept`) |

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
  - These last two are found once a session when first wanted, in one pass (`Sync.CVarsOf(id)`). Never taken
    by them: a character's state (tracked, collapsed, last chosen or seen) and one computer's (`gx*`,
    drivers, devices, monitor, window mode, speech voices).
  - **Edit Mode layout** (`Layout.lua`), **your own chat channels** and **chat windows** (`Chat.lua`).
  - Each part reads only what this client has and writes only what differs; one the game does not answer
    (a flag, a modifier key) keeps what was kept. Data of a shape this version does not know is skipped.
- **Read** (`Sync.Capture`, given to `Core.Options` as its capture): Core calls it before Sane UI's settings
  are saved anywhere: a profile saved, the character's own switched, the logout. Kept parts are read from
  the game; the others are dropped. Nothing is read before this session wrote the settings into the game,
  so a character that leaves before then does not spread its own.
- **Written** (`Sync.Give`): 2 seconds after the first `PLAYER_ENTERING_WORLD` of a session once the game
  has its stored settings (`C_CVar.AreCVarsLoaded`, else 2 seconds after `VARIABLES_LOADED`), and when a
  profile was loaded or the character's own switched (the option `taken` changed: Core calls `changed`).
  Never in a fight: then at `PLAYER_REGEN_ENABLED`. Your own channels are joined before the chat windows are
  written (a join puts a channel into the first window). One reload dialog per writing (`Sync.OfferReload`,
  through `Core.AskReload`) names what the game shows only after one.
- **Through the game's stored settings, never its frames** (no taint):
  - CVars with `C_CVar.SetCVar`; game functions in pairs (`SetAutoDeclineGuildInvites`, ...); modifier keys
    with `SetModifiedClick`, the key bindings in use then saved with `SaveBindings`; the extra action bars
    with `SetActionBarToggles` (not where the game forces them), read by the bars at the next load.
  - Chat windows with `SetChatWindowName/Size/Color/Alpha/Shown/Locked/Docked/Uninteractable`,
    `Add/RemoveChatWindowMessages`, `Add/RemoveChatWindowChannel`, the places of the free ones (not the
    first's, which Edit Mode places) with `SetChatWindowSavedPosition/Dimensions`. The game's chat frames read
    these when the interface loads (`UPDATE_CHAT_WINDOWS`), hence the reload. Colours with `ChangeChatColor`
    and `SetChatColorNameByClass`, which the frames take at once from the game's own events, in our call.
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
      Edit Mode is open, not in a fight. Such a layout waits and is set when the manager has its layouts,
      Edit Mode closes (`EditMode.Exit`) or the fight is over; meanwhile it counts as the one in use. One
      that is not there (deleted, another character's own) leaves the layout in use.
- **Left out, and why:**
  - The game's System pages Languages, Network and Mac: they belong to one computer or installation.
  - Edit Mode per specialization, screen-resolution settings, import and export.
  - The zone map's place, the damage meter's windows, chat tab protection: they write into the game's own
    frames or saved tables, which taints them.
- **Globals:** none.
- **Tests:** `lua5.1 dev/tests/sync.lua` (65 checks), with a small model of the game's settings and the real
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
- 2026-10-17 — Laid out as the game's own options: a part per options page (Gameplay, Accessibility,
  System), named in the game's words, what each page sets made from Blizzard's options code by
  `dev/tools/sync-pages`; Edit Mode layout, own channels, chat windows (with their places) and other
  per-character settings under *Elsewhere in the game*. Its settings are `off`, `taken`, `named`; settings
  saved in the earlier shape are not read.
- 2026-10-15 — Edit Mode layout: read as seen in the world, not at the logout (each logout kept the first
  preset, so every login set it); a layout that cannot be set yet waits (no layouts yet, Edit Mode open, a fight).
- 2026-10-15 — Part of Core (`src/Core/Sync/`, `Core.Sync`), no addon of its own (was `SaneUI_Sync`); its saved
  settings keep their place and name. Sync is no module, so it gets no page.
- 2026-10-14 — The game's channels (join, leave) moved to the Chat module; the tab *Chat channels* is gone.
- 2026-10-14 — Every part ticked at first. The tab is called *Accountwide*.
- 2026-10-14 — First version: the game's per-character settings kept with Sane UI's settings (account,
  character's own, profiles); the game's chat channels joined or left on every character.
