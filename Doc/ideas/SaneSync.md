# Sane Sync

Planning notes for **Sane Sync** (the name is Saneroki's, 2026-10-16; *the app* below): a small program
outside the game, for Windows, Linux and macOS, that keeps Sane UI up to date and, later, carries shared data
beyond the guild. Saneroki's wish (2026-10-16): it downloads new versions, can run in the background and start
when the player logs in to the computer, and also handles backups, rollbacks, choosing a version and some
other options. Everything here is a proposal for Saneroki to discuss; nothing is built yet.

Not to be confused with Core's **Sync** (`src/Core/Sync/`), which keeps the game's own per-character
settings with Sane UI's settings, inside the game.

## What it is for

- **Updates:** a new version of Sane UI is installed by itself (or after a yes, as the player chooses).
- **Choosing a version:** the stable or the test channel, or any older version, held there until unpinned.
- **Rollback:** back to the version before in one click, with the saved settings from before the update.
- **Backups:** Sane UI's saved files (settings, learned data, the characters' data, the auction history),
  kept daily and before every update, restored in one click.
- **In the background:** a tray icon, starting with the login to the computer if the player wants.
- **Later, beyond the guild:** shared data from every Sane UI player, not only guild members who are online
  at the same time (*Beyond the guild*).

## Words

| Word | Meaning |
| --- | --- |
| **Sane UI version** | Sane UI as published, with a number like 0.4.0: all its addon folders (Core, the modules, the data packs). The data plan's *release* (one compile of the packs, `Doc/ideas/Data.md`) is part of one. |
| **Channel** | *Stable* (the default) or *Test* (Saneroki's newest, for testers). |
| **Manifest** | The signed list of one Sane UI version: its number, channel and date; per game (Forever, later retail) the products and versions its build runs on and its interface; per addon folder its file, size and hash. |
| **Installation** | One World of Warcraft folder, with Battle.net's `.build.info` in it. A computer can have several (two drives, two Wine prefixes). |
| **Game version** | One game in an installation, in its own folder (`_forever_`, `_classic_beta_`), with its own addons and saved files: live, PTR or beta of Forever, later of retail. Battle.net's launcher calls it so too. |
| **Outbox** | What the addon leaves in its saved variable for the app to send (*Beyond the guild*). |

## The rules it keeps

- **It never touches the running game.** No reading the game's memory, no keys or clicks, no talking to the
  client: only files on disk, as a person with a file manager would. Blizzard forbids software that changes
  the client or facilitates gameplay; reading and writing an addon's own files stays clear of that, and is
  the usual way addons get data in and out. No Blizzard rule names this case: check the current terms
  before the app goes to anybody else.
- **Only Sane UI's own files:** the folders `SaneUI` and `SaneUI_*` in
  `Interface/AddOns`, and Sane UI's own saved files in `WTF`. It is not a manager for other addons, and never
  touches the game's list of switched-on addons (`AddOns.txt`): what the player switched off stays off.
- **It installs nothing unsigned** (*Trust*).
- **Sane UI never needs it.** The addon works the same without the app; the app only saves work.
- **No admin rights.** Everything is in the player's own folders and the game folder.

## Files are the only way in and out

An addon cannot reach the network or other programs. The app and the addon talk through files:

| Way | How | When the other side sees it |
| --- | --- | --- |
| Addon to app | The addon's saved variables, which the game writes at `/reload`, logout and exit. The app reads them as data, never runs them (like the data plan's *Harvest*). | As soon as the game wrote them |
| App to addon | A file in a Sane UI addon folder, listed in its TOC from the start. The game reads addon files at login and again at every `/reload`; a file newly added to a TOC needs a restart of the game (as `dev/build` says after every install). | At the next `/reload` or login |

- **Never into saved variables while the game runs:** the game writes its own copy over them at logout.
- So data is one session late both ways. For updates, backups and prices that is fine.

## Finding the game

Saneroki (2026-10-17): Sane Sync finds the game by itself, shows the player what it found and asks whether that
is the right installation. If it finds none, or the wrong one, the player gives the folder. The player
chooses which game versions get Sane UI: today only Forever's (live, PTR, beta), later also retail's. Several
are kept at once: who plays live and the PTR has Sane UI in both, each kept up to date.

### What a World of Warcraft folder holds

As found on Saneroki's computer (2026-10-17, Battle.net under Proton):

| Where | What |
| --- | --- |
| `World of Warcraft/` | The installation: the launcher, `.build.info`, one folder per game version |
| `.build.info` | A table, one row per installed game version: its product (`wowf`), version (`1.60.1.70245`), region and system |
| `_forever_/` | Forever: product `wowf`, program `Wow.exe`; `.flavor.info` names the product; `Interface/AddOns` and `WTF` appear at the first start |
| `_classic_beta_/` | Forever's beta: product `wow_classic_beta`, program `WowB.exe`, version `1.60.1.70450` |

- **Every game version has its own addons and saved files** (`Interface/AddOns`, `WTF` in its folder).
  Sane UI in Forever puts nothing into the beta, and the other way round.
- **The game is told by the version, the kind by the product.** A beta or PTR product serves whichever game is
  tested in it: `wow_classic_beta` holds Forever's beta today. So the manifest names, per game, the products and
  the version numbers its build runs on (Forever: `wowf`, and any PTR or beta product on 1.60.x); the product
  says live, PTR or beta. Known products today: `wowf`; `wow`, `wowt`, `wow_beta` (retail); `wow_classic`,
  `wow_classic_era` and their `_ptr` and `_beta`. One not known is shown with its folder and version, never
  switched on.
- **The interface from the version:** 1.60.1 is interface 16001 (major × 10000 + minor × 100 + patch), the
  number a TOC's `## Interface` carries. When a PTR runs a newer one than the Sane UI version was made for,
  Sane Sync says so; the game would show the addon as out of date.
- **Saved files:** `WTF/Account/<account>/SavedVariables/` and per character
  `WTF/Account/<account>/<realm>/<character>/SavedVariables/` of each game version, for every WoW account
  found.

### Finding it

1. **Battle.net's own list of installed games,** `product.db` in Battle.net's `Agent` folder: on Windows
   `C:\ProgramData\Battle.net\Agent\`, on macOS `/Users/Shared/Battle.net/Agent/`, under Wine or Proton the
   Windows path inside the prefix's `drive_c`. It names every installed product with its installation's path
   (on Saneroki's computer `wowf` and `wow_classic_beta` in `C:/Program Files (x86)/World of Warcraft`). Read by
   a small reader of its format (protocol buffers), tested on real copies.
2. **The usual places,** for what that list does not name: Windows `\Program Files (x86)\World of Warcraft\`
   on every drive; macOS `/Applications/World of Warcraft/`; Linux every Wine prefix: Steam's
   (`steamapps/compatdata/*/pfx` in every library its `libraryfolders.vdf` names, also Steam as a Flatpak),
   Lutris, Bottles and `~/.wine`.
3. **Checked:** a folder counts as an installation only with a `.build.info`, and a game version only with
   its `.flavor.info` and a row in `.build.info`.

### Asking the player

- **At the first start:** *Sane Sync found World of Warcraft in `<path>`: Forever 1.60.1, Forever beta
  1.60.1. Is this your game?* with **Yes** and **Another folder**. Several found (two prefixes, two drives): a
  list, and the player ticks the ones they play.
- **None found, or the wrong one:** the player picks the folder (the system's folder picker) or types its
  path. Picking the installation, a game version's folder or even its `AddOns` folder all work: Sane Sync goes
  up to the installation. A folder without `.build.info` is refused with one line why: *This is not a World
  of Warcraft folder (it has no .build.info).*
- **Later:** *Add an installation* and *Remove* in the window (removing asks whether Sane UI is taken out of
  it too, or left). At every start Sane Sync looks again, and tells the player of a new game version in a
  known installation (a PTR installed since); it never switches one on by itself.

### Which game versions get Sane UI

- **The window lists every installation with its game versions:** name (*Forever*, *Forever PTR*, *Forever
  beta*; later *Retail*, *Retail PTR*), version, folder, and a switch for Sane UI.
- **Only game versions Sane UI is made for** can be switched on: today Forever's. The others stand greyed:
  *Sane UI is not made for this game yet.* A retail Sane UI later is a build of its own in the same manifest;
  Sane Sync gives each game version the build of its game.
- **Several at once, each on its own:** any number of game versions in any number of installations. Each has
  its own channel and pin (*proposal:* live on *Stable*, PTR and beta on *Test*), installed version, rollback,
  backups and line in the window. One download serves every game version that takes the same build.
- **Each game version gets its own data packs** (`Doc/ideas/Data.md`, *Game versions kept apart*). The code
  is the same for all of them; the packs (`SaneUI_Data_*`) are made per game version, so that live never
  holds a fact of the PTR or the beta. The manifest lists the packs per game version, and Sane Sync installs
  into a folder only the packs of that folder's game version (its product in `.flavor.info`).
- **Running, per game version:** a process whose program lies in that game version's folder (under Wine and
  Proton the Windows path in its command line). An update waits only for the game version that runs: the
  PTR is updated while live is played.
- **Sane UI already there, not put there by Sane Sync** (by hand, or by `dev/build`): Sane Sync asks before it
  takes that game version over, and leaves it alone until then. The beta folder that `dev/build` fills on
  Saneroki's computer stays his.

## Updates

### Giving out a version

- **`dev/tools/publish`** (new, later): after `dev/build`, zips each addon folder of `BUILD/` by itself,
  writes the manifest and signs it with Saneroki's key. Only Saneroki publishes.
- **One zip per addon folder:** the data packs are big (the walking data alone may be several megabytes),
  and the data plan makes the same master give the same bytes. A folder whose hash did not change is not
  downloaded again, so most updates are a few hundred KB.
- **Voice packs** are not part of a version: they are offered on their own (*Voice packs* below).
- **Where** (*proposal*): GitHub Releases of the public repository: the manifests, the zips and a small index
  of versions per channel. Any static web host would do as well: the host is not trusted (*Trust*).

### Trust

The app puts code into the player's game. A host that is broken into could ship anything to everybody, so:

- Every manifest is **signed with an Ed25519 key** that lives on Saneroki's computer only: never in the
  repository, never on the host, never in a build service. The app carries the public key, checks the
  signature, then every zip's hash, and installs nothing that does not match.
- **The code being public is no weakness:** the trust lies in the private key, not in hidden code. (The data
  plan's *Poisoning* already assumes that everybody can read our code.)
- A signed list of **withdrawn versions** (one with a bad bug) that the app does not offer or install.
- **The app's own updates** are checked with the same key.

### Installing

1. **Only while that game version is closed.** If it runs, its update waits for it to close, and says so;
   other game versions are updated meanwhile. (Files swapped while the game runs would be read half old, half
   new at the next `/reload`.)
2. **A backup first** of Sane UI's saved files (*Backups*).
3. **Unpacked beside the old folder, then swapped by renaming,** folder by folder, so the game never sees a
   half-written addon. The old version is kept on disk (*Choosing a version*).
4. **A Sane UI folder that the new version no longer has** (a module renamed or removed) is taken out, as
   `dev/build` does. Only folders the app itself installed, which it records.
5. **In the game,** Core finds the new version at the next login and Onboarding shows *What's new*
   (`Doc/ideas/Onboarding.md`). After a rollback the version last seen is newer than the one installed:
   that shows nothing, only a newer version does.

### Choosing a version

- **Channel:** *Stable* or *Test*.
- **Any older version** from the list; **pinned**, it gets no updates until the player unpins it.
- **Rollback:** back to the version before in one click. The last three versions (*proposal*) stay on disk,
  so it needs no download.
- **Settings and rollback:** Core replaces a saved value of the wrong kind instead of trusting it
  (`src/Core/Saved.lua`), so an older Core would replace settings that a newer one saved in a new shape, and
  write that at logout. A rollback therefore **restores the saved files from the backup made just before
  that update**, by default; the player may keep the current ones instead.

### Voice packs

The voices of the Lore module (`SaneUI_Voice_*`, Saneroki 2026-10-16, `Doc/ideas/Lore.md`, *Voice packs*) are
about 2 GB of sound, so they are no part of a Sane UI version:

- **Offered one by one,** each with what it holds and its size, and installed only when the player picks it.
  The app knows the characters' levels from the saved files and puts the packs of their level bands first.
- **Updated file by file:** each pack has a manifest of its own that lists every sound file with its hash, so
  a few new voices are a small download, not the whole pack again. Signed and checked as everything else
  (*Trust*).

#### Hear a sample (Saneroki, 2026-10-17)

So that a player knows what the voices sound like before downloading a gigabyte or two:

- **One button, *Hear a sample*,** above the list of voice packs. It holds **five samples**; each press plays
  the next one, and after the fifth it starts again with the first. A press while a sample plays stops it and
  plays the next.
- **Five different voices** (Saneroki): the narrator, and speakers of different races, both sides, men and
  women. *Proposal:* the narrator reading a place; a human innkeeper (`human-female-common`, Alliance) and a
  gnome scholar (`gnome-male-refined`, Alliance) giving a quest; an undead soldier (`undead-male-martial`,
  Horde) and an orc matron (`orc-female-elder`, Horde) talking. Each a real line of its pack, some 10 to 20
  seconds.
- **While one plays,** the button says which (*2 of 5*), and under it stand the speaker, the pack it comes
  from, and the words: *Gnome scholar, Voices: Lands 1–20: "..."*.
- **The very sound of the packs:** the samples are made by the voice tool with the packs, from the same lines
  and with the same encoding, so the player hears what they get. Saneroki picks the five after the trial
  (`Doc/ideas/Lore.md`, *The service*); they are named in the cast's file and made again when the cast changes.
- **Small:** five files of about 80 KB, listed with the voice packs' manifests and fetched when the list is
  first shown, then kept. The window's web view plays them: Linux's does (measured 2026-10-17); *to check:*
  macOS's and Windows' (macOS's may not; then an MP3 made from the same master, or `rodio`).
- **No volume of its own:** the system's sound.

## Backups

- **What:** Sane UI's saved files only: `SaneUI*.lua` in every account's and character's `SavedVariables`,
  with the game's `.bak` copies. Sync keeps the game's own per-character settings inside Sane UI's saved
  settings, so they come along.
- **When:** before every update, and once a day after the game closed (*proposal*: the last 14 days kept,
  and the backups made before the last three updates).
- **Where:** zipped, in the app's own folder, or in a folder the player picks (one synced to a cloud drive
  gives a backup on another computer).
- **Restore:** only while that game version is closed, a whole backup or one account. The current files are backed up
  first, so a restore can be undone. A backup goes back only into the game version it was made from, never
  into another (a beta backup into live would bring the beta's data along).
- **With the data plan:** Core warns when a pack's saved data is gone (*A lost file*); the backup is the way
  back. The auction history grows to about 45 MB a year (`Doc/ideas/Economy.md`); text zips well.

## Other options

| Option | Choices |
| --- | --- |
| Start with the computer | on, off (asked at the first start) |
| Updates | install by themselves, ask first, only when I click |
| Notices | on, off (an update installed or waiting for the game to close, a backup that failed) |
| Installations and game versions | which get Sane UI, each with its own channel (*Finding the game*) |
| Backups | how many, where |
| Check now, open the log, the app's version | |

Later, if wanted:

- **Show Sane UI's error log** (Core keeps it in the saved settings; today `dev/tools/errors`), so a player
  can copy it into a bug report. Nothing is sent by itself.
- **Move settings to another computer or WoW account:** a backup taken here, restored there.

## In the background

| System | Start with the login | Tray icon |
| --- | --- | --- |
| Windows | A value under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` | Notification area |
| macOS | A launch agent in `~/Library/LaunchAgents/` (or the newer login items for a signed app) | Menu bar |
| Linux | A `.desktop` file in `~/.config/autostart/` | KDE shows it; GNOME only with the AppIndicator extension. Without a tray the app still runs and speaks through notices. |

- **Idle, it costs nothing to notice:** it sleeps, looks for a new version every six hours (*proposal*) and
  at the start, and hears from the system when a saved file changes. About 25 MB of memory, as measured
  (*How it is built*, *Two processes*).
- **Without the background:** the player opens the app, it checks, updates, backs up, and can be closed.
- **The same on all three systems** (Saneroki asked, 2026-10-17): one program for Windows, macOS and Linux, each
  with the background process, its icon (on macOS in the menu bar, without a Dock icon) and the start with the
  login. World of Warcraft has a Mac client, Forever's too, so Mac players are players like the others.
- **Tried for real before players get it:** Saneroki's computer runs Linux. The Windows and macOS programs are
  built by GitHub's build service and must be tried on a real Windows computer and a real Mac (a borrowed one
  or a virtual Windows) before a version goes out.

## How it is built

*Proposal* (2026-10-17): **Rust with Tauri 2**. Tauri is stable (2.11 in mid-2026) and its own plugins already
do most of what the app needs on all three systems; the window is the system's own web view, so nothing big
is shipped beside the app.

| Need | Takes | Notes |
| --- | --- | --- |
| Window | Tauri 2, the system's web view (WebView2 on Windows, WebKit on macOS and Linux) | Plain HTML, CSS and JavaScript from a folder: no Node, no npm, no framework. Four pages: versions, backups, voice packs, options. Its own process, ended when the window closes (*Two processes*). |
| Tray icon | Tauri's tray | Linux: needs `libayatana-appindicator` (*In the background*) |
| Start with the login | `tauri-plugin-autostart` | The Run key, a launch agent, XDG autostart: the table in *In the background* |
| The app's own updates | `tauri-plugin-updater` | Signed (minisign, Ed25519), from the same GitHub Releases |
| One app at a time; folder picker; notices; log | `tauri-plugin-single-instance`, `-dialog`, `-notification`, `-log` | A second start tells the background process, which opens the window |
| Downloads | `reqwest` with rustls (no OpenSSL) | Resumable (HTTP ranges), for the voice packs |
| Signatures and hashes | `minisign-verify`, `sha2` | The same signature format as the app's updater: one tool (`minisign`) and Saneroki's key sign the manifests and the app |
| Zips (versions, backups) | `zip` | |
| Watching the saved files | `notify` (the system's file events) | Polling once a minute only as a fallback |
| Is a game version running | `sysinfo` | The program's path; under Wine and Proton the Windows path in the command line |
| Battle.net's list of games | a small reader of protocol buffers | `product.db` (*Finding it*) |
| Reading saved files | a small reader of our own for Lua table text | Data only, never run (a Lua interpreter would run it); tested on real saved files |
| Sound (*Hear a sample*) | the web view; `rodio` if a system's web view does not play Ogg Vorbis | Linux's plays it (measured); `rodio` plays it the same on every system |

- **Weight, measured** (2026-10-17, Saneroki's computer: Linux, KDE on Wayland, an NVIDIA card; a test program
  with the tray, the plugins and the crates above): the program 7.5 MB with the size settings below, 2.4 MB
  packed as in an installer. Memory as the system shares it out (PSS):

  | State | Memory |
  | --- | --- |
  | A process that never made a web view: tray only | about 25 MB |
  | The window open | about 220 MB (the program 110, the web view's two helper processes 91 and 18) |
  | The window closed, same process | about 145 MB: WebKit's helper processes stay |

- **Two processes, one program:** so the background process **never makes a web view**. Opening the window
  starts the same program a second time in window mode; that process ends when its window closes, and all the
  web view's memory goes with it. A start from the menu or the desktop finds the background process (the
  single-instance plugin) and asks it to open the window. The window process does the work it shows by asking
  the background process, so only one of them writes the game's files.
- **Known pitfalls** (met in the test):
  - Linux with an NVIDIA card on Wayland: WebKit's DMA-BUF renderer breaks the window (*Error 71 (Protocol
    error) dispatching to Wayland display*). The app sets `WEBKIT_DISABLE_DMABUF_RENDERER=1` for itself on
    Linux, before the window starts, unless the player set it.
  - Tauri ends the program when its last window closes; the background process keeps running
    (`RunEvent::ExitRequested`, `prevent_exit`, unless the exit has a code).
  - The updater plugin needs its settings (`plugins.updater`: the public key, the addresses) even before it
    is used, or the app stops at the start.
  - `reqwest` 0.13 names its TLS feature `rustls` (no longer `rustls-tls`).
  - Size settings for the release build: `[profile.release]` with `codegen-units = 1`, `lto = true`,
    `opt-level = "s"`, `panic = "abort"`, `strip = true` (24 MB without them).
- **Packages:** Windows an installer (NSIS); macOS a `.dmg` with one app for Intel and Apple chips; Linux
  `.deb` and `.rpm` (an AppImage carries its own libraries and is much bigger); on Arch built from source.
- **Not chosen:** Go with Wails would be as small and easier to read, but its tray needs Wails 3, still in beta
  (2026-10); worth another look when 3.0 is out. A tray without a window (Go and a tray library) is the
  smallest, but versions, backups and the voice samples want a window. A bundled browser (100 MB and more),
  Flutter, .NET or Qt (tens of MB, heavier tools) and Python (needs bundling) do not fit *tiny*.
- **Built on each system:** the tray and the web view need the system's own libraries, so the Windows and
  macOS files are built there: GitHub's build service (free for a public repository) or by hand. Saneroki's
  computer builds Linux. The build service only builds: its files are hashed and signed on Saneroki's computer
  before the app offers them (*Trust*).
- **Signing the app itself** (apart from signing the addon): unsigned, Windows warns before the first start
  and macOS blocks it until it is allowed in System Settings. Signed needs an Apple developer account
  (USD 99 a year) for macOS, and a code-signing certificate (a yearly cost) for Windows. For Saneroki and a
  few testers, unsigned with a line on how to allow it is enough.
- **Tests:** the parts without a window (finding folders, reading saved files as data, the manifest, the
  signature, swapping folders, backups, rollback) are tested on made-up game folders, offline, like the
  addon's own tests, with copies of real `.build.info`, `.flavor.info` and `product.db` files: `cargo test`, which `dev/tests/run` runs where Rust is installed.
- **Layout** (with the folder question below): `app/ui/` the window's pages, `app/src-tauri/` the Rust code.

## Setting up a computer

What working on the app needs. Saneroki's computer was set up and checked on 2026-10-17 (a test program built
and ran with the tray, the window and every plugin and crate above).

| System | Needs |
| --- | --- |
| Arch Linux (Saneroki's) | `sudo pacman -S --needed rust base-devel webkit2gtk-4.1 libayatana-appindicator xdotool librsvg cargo-tauri minisign` (Arch packages the Tauri command line as `cargo-tauri`; `gst-plugins-base` and `-good` for the web view's sound) |
| Debian, Ubuntu | `libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev`, Rust from `rustup`, then `cargo install tauri-cli --version "^2" --locked` |
| Fedora | `webkit2gtk4.1-devel openssl-devel curl wget file libappindicator-gtk3-devel librsvg2-devel libxdo-devel` and the group *C Development Tools and Libraries*, Rust from `rustup`, the Tauri command line as above |
| macOS | Xcode's command line tools (`xcode-select --install`), Rust from `rustup`, the Tauri command line as above |
| Windows | Microsoft's C++ Build Tools (*Desktop development with C++*), WebView2 (in Windows 10 and 11 already), Rust from `rustup` (the MSVC toolchain), the Tauri command line as above |

- **`minisign`** signs the manifests and the app (*Trust*). Saneroki's key is made once, with a password, when
  publishing starts (step 2 of *The order of work*): `minisign -G` writes the secret key to
  `~/.minisign/minisign.key`, which never enters the repository.
- **Try it:** `cargo tauri dev` in `app/` runs the app from its sources; `cargo tauri build` makes the
  packages; `cargo test` runs the tests.

## Beyond the guild

Guild sharing (`Doc/ideas/Data.md`, *Sharing in the game*) reaches only guild members online at the same
time. Getting data from everybody else has three ways, smallest first. Whichever is taken, the data keeps
its game version, and a game version gets only its own (`Doc/ideas/Data.md`, *Game versions kept apart*).

### 1. Blizzard's web API

Blizzard's web API (its developer portal, *Game Data APIs*) gives the auction houses of other WoW flavours,
per connected realm, every hour. If it covers this game's auction houses (to check: nothing found yet), the
app or a small server takes prices straight from Blizzard: complete, hourly, and nobody can poison them. That
is the principle *take more from Blizzard directly*, and for prices it beats any crowd. It needs a key from
Blizzard, which cannot be kept secret inside an app: so a small server fetches, or each player uses a key of
their own.

### 2. A realm channel, no server

The game's addon messages also go over a custom chat channel. A hidden channel that every Sane UI player on
the realm joins would reach past the guild with no server and no app. Against it: anybody can join a channel,
so the first layer of the data plan's *Poisoning* (only the guild) falls away and the others carry it all;
players still have to be online at the same time; and whether an addon may still join a channel by itself
on this client, under its chat restrictions, is to check. Worth checking before any server is built.

### 3. A server, through the app

1. With the switch **Share data beyond my guild** on (off by default, next to the data plan's switches), the
   addon writes an **outbox** into its saved variable: only what guild sharing would send (prices,
   discoveries, counts), never anything of the player or the characters. The addon decides what leaves; the
   app only carries it.
2. After a `/reload` or logout the app reads the outbox and sends it, if its own switch is on as well.
3. The server merges what everybody sent: the game's facts once for all realms, prices per auction house
   (game version, region, realm, side; `Doc/ideas/Data.md`, *Realms and regions*).
4. The app downloads its realm's merged data and writes it into one file of an addon folder of its own,
   `SaneUI_Data_Shared` (load on demand, no shipped data, written only by the app), so an update never
   overwrites it.
5. At the next `/reload` or login the addon takes it in **like a message from one more guild member**: into
   quarantine, then the game's own checks, several senders, medians, the player's own data first, and
   *Forget shared data* takes it out again (*Poisoning*, layers 2 to 10).

- **The server never sends code.** The app writes that file itself, all the data in one string, which Core
  reads with its strict reader. A server that is broken into can send wrong data, which the checks catch,
  but never code that runs in the game.
- **The server stays small:** two calls (send a bundle; fetch a realm's data since a time). Prices: per item
  and day the median of everybody who sent. A fact the game cannot check is given out only after several
  different senders sent it.
- **Who is who:** no accounts. Each app makes its own key pair and signs what it sends; that proves *the same
  app as before* (for limits and strikes), not honesty. Made-up senders are cheap, so the server's medians,
  its rules of several senders and the game's checks carry the weight. A Battle.net login would tie a sender
  to a real WoW account (if Blizzard's login allows this use): stronger, but more to build and a login for
  the player.
- **Private:** no character names, only the app's key, a realm and the data. Addresses kept only as long as
  the limits need them.
- **Cost:** a small server or a few serverless functions and storage: a running cost, and somebody has to
  keep it running for as long as players use it. That is why it comes last.

## Open source

Saneroki (2026-10-16): the repository is public and fully open source. Anybody may fork it, add code, and use
the code and the data themselves under the project's `LICENSE`. For Sane Sync that means:

- **Only Saneroki's versions carry Saneroki's signature.** Code from others comes in as pull requests; it
  reaches players once Saneroki has taken it in and published a version. Publishing stays on Saneroki's
  computer, where the key is.
- **A fork gives out its own versions** with its own app: its own key, its own host, and its own name. The
  `LICENSE` keeps the names *Sane UI* and *Sane Sync* to Saneroki (section 2; Saneroki, 2026-10-16), so a
  fork's addon and app carry other names.
- **Blizzard's addon policy** (free, readable code) fits open source as it is.

What changes once players install versions through the app: **old players' copies.** So far no player but
Saneroki is known to have a copy installed, so nothing upgrades old saved settings or folders. Once players
install versions, every saved shape that was ever published needs its way forward, and rollbacks need the
rule above (*Choosing a version*).

## The order of work

| Step | What | Needs from the addon |
| --- | --- | --- |
| 1 | Backups and restore, on Saneroki's computer | nothing |
| 2 | `dev/tools/publish`, signing, the manifest; the app installs, with channels, pinning and rollback | nothing |
| 3 | Background, start with the login, notices; the app updates itself | nothing |
| 4 | The app signed for Windows and macOS | nothing; only when players beyond Saneroki use it |
| 5 | Beyond the guild: check Blizzard's API and the realm channel first; the server last | the outbox and the shared file's reader, after Core's data framework and guild sharing stand |

## Open questions

- Decided (Saneroki, 2026-10-16): the name **Sane Sync**, in the `LICENSE`'s name section with *Sane UI*; the
  repository is public and fully open source.
- Saneroki to decide (2026-10-16):
  - **Where it lives:** the app is a program of its own, neither an addon (`src/` holds addons, one TOC each)
    nor a development tool (`dev/`). *Proposal:* a new root folder `app/`, in this repository, so it is open
    source with the rest.
  - **Language:** Rust with Tauri 2 (*proposal*, 2026-10-17, *How it is built*), or Go with Wails once Wails 3
    is stable.
  - **Hosting:** GitHub Releases of the public repository (*proposal*), or web space of Saneroki's own.
  - **Defaults:** start with the computer on or off; updates by themselves or after a yes.
  - **Beyond the guild:** which of the three ways; for a server, who pays and runs it, and whether senders
    log in with Battle.net.
- To check in the game and on the systems: the game's process names; whether Blizzard's web API covers this
  game's auction houses; whether an addon may still join a custom channel on this client; whether the game
  folder on Windows can be written without admin rights.
