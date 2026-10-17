# Sane UI: developer changelog

Every change, newest first. The short version for users is [changelog.txt](changelog.txt).

## 0.3.0 (2026-10-14)
The Home page, the marks, Settings on demand, the Tooltips module and the Social module are not yet tried in the game.
Tests: lint, 195 checks (Core, with its options), 280 checks (Spellbook), 328 checks (Tooltips), 332 checks (Social), 62 checks (Sync), 234 checks (windows).

### Guides: no "not yet tried in the game" (Saneroki, 2026-10-17)
- `Doc/guides/windows.md`: the README no longer has to say *not yet tried in the game* until the taint log is clean.

### New designs across the modules (Saneroki, 2026-10-17)
- **Abilities, trainer data:** `Data/Classes/*.lua` are hand-edited in a new format: one string per spell
  family with its ranks in order (`"spell:level:copper"`; a bare spell is a rank the trainer does not sell),
  ordered by first level, then spell ID, plus a small conditions table per class (`talent`, `after`,
  `alone`, `side`, `raceIDs`) that holds from its rank to the end of the family.
- Abilities: `Data/Trainer.lua` reads the families at login into one list, `D.spells`, filtered by faction
  and race, and links each rank to the next. `D.Learned` counts a rank as learned when it or a later rank
  is known, for every class. `D.FamilyName` (numerals I-XX checked against the rank line) replaces
  `D.BaseName`. Dire Bear Form is Bear Form's next rank.
- Abilities: spell states are `trainable`, `level`, `talentfirst`, `spellfirst`, `quest`, `talent` and
  `other`, checked level first as in the game's spellbook. A spell that needs another spell first names it.
  Shift-click links use the game's spell link only. Quest reward rows use `raceIDs`.
- Abilities, fixed: the hunter's trainer list held 45 pet abilities, shown as grey hunter spells. An unused
  field on rogue poisons is gone.
- **Tooltips, palette:** built from the game's font colours by one mixing rule (`ns.COLOR`, `ns.Mix`,
  `ns.Like`). Spell schools take the combat log's colours. The background is the game's tooltip ground
  tinted by the panel's colour.
- Tooltips: a spell's first strip shows only the facts its tooltip states, read through the game's own
  sentences (every language), in the game's order. The computed numbers are in a second strip, with a cell
  only for a known value.
- Tooltips, layout in four steps (Measure, Picture, Lay, Finish):
  - width in steps of 8 (224-432), wrapping at 22 ems;
  - a row's right side gives way to its left;
  - strip cells sized by their words;
  - section names left-aligned with a rule;
  - hairlines from `PixelUtil`.
- Tooltips: `Native.lua` is now `Host.lua` (`ns.Host`), and a comparison's panel stands beside the other
  by the game's side.
- Tooltips: a description is found by its line type, else as a gold sentence, and only its digits are
  coloured. Auras are found through a getter table and coloured by what removes them.
- Tooltips: a player's side is a word on the race line (the emblem is gone). Rank words come from the
  game's strings, and a rare elite shows both. The target's name follows "Target". Pools are `{ taken }`
  lists with one `Take`. Quest icons are named `available` and `active`, after the game's gossip icons.
- **Tooltips, quest facts:** `ns.QuestFacts` has a new shape:
  - one record per quest, `levels;rule;races;classes;title`;
  - prerequisite signs `+` (done), `/` (one of) and `!` (closed);
  - the game's race and class IDs;
  - NPC and item records as lettered groups;
  - 546 KB instead of 686.

  Drop chances are whole percent, `<1%` below one. Quests the game repeats are offered by no NPC. An item's
  quest list names each quest once.
- Tooltips, quest availability: the game's class and race IDs, its trivial range for grey quests, and the
  quest's own min level. Fixed: Skyborne characters now get the quests meant for their race alone.
- Tooltips, spell numbers: the description is read as numbers with the words between them. Per second
  means cast again and again, and the spell's own global cooldown counts where the game gives it. Crit is
  the one spell chance this client has. Kill experience comes from one table by level. The kills line
  reads "Next level in N".
- **Core, motion:** the kinds are Glide (default), Swing, Even and Instant, each a time and one of
  Blizzard's easing curves (`EasingUtil`). An unknown saved kind falls back to the general one.
- Core, Expand: a window opens once the mouse has rested on it (0.2 s) and closes 0.5 s after it has gone.
  A watch frame checks the mouse only in between. `expand:Stay(on)` keeps it open.
- Core, Bar: drawn with the game's experience bar atlases (the fill over the part still to come, its pip,
  dividers, the flare flipbook). A gain rises for 0.35 to 1.1 s, depending on its size.
- Core, Skin: windows stand on the tile of the game's dark dialogs, under the bronze trim. `/sane window`
  opens on rest, has a *Keep open* box, and a bar that *Add* fills.
- Core, Fuzzy: ranks are whole numbers, from 600 for the whole text down to 100 for spread letters, plus up
  to 90 for a close fit. One pass through the text. The API is `Rank` and `Highlight` (in
  `NORMAL_FONT_COLOR`).
- Core, CVars tab:
  - over the list: a search box and the game's filter button;
  - two-line rows, the value edited in place, an undo arrow back to the default;
  - details in the row tooltip; status and count under the list.

  `CVarLabels.lua` holds `{ label, tip }` entries written by `dev/tools/cvar-labels`.
- Core, errors: the chat line reads "problem in <label>, noted in the error log (/sane errors)."
- **Sync:** one part per options page of the game (Gameplay, Accessibility, System), named in the game's
  words. Edit Mode layout, own channels, chat windows (now with their places) and the other per-character
  settings are under "Elsewhere in the game".
- Sync: what each page sets is generated from Blizzard's options code by the new `dev/tools/sync-pages`
  into `src/Core/Sync/Data/Pages.lua` (`--check`). "Other per-character settings" keeps every CVar the
  game stores per character that no page holds (`C_CVar.GetCVarInfo`).
- Sync: settings are `off` / `taken` / `named`; settings saved in the earlier shape are not read. Files:
  `Sync.lua`, `Layout.lua`, `Chat.lua`, `Game.lua`, `Data/Pages.lua`. `Parts.lua` and `Switches.lua` are
  removed.
- **Social, game channels:** set in the list on the chat's name ("On every character": The game decides /
  Always in it / Never in it), listed from the game; setting `presence`. A channel is joined only where the
  game offers it (`EnumerateServerChannels`), asked once per zone, and joining reacts to the game's channel
  notices.
- **Plans (`Doc/ideas/`):**
  - Economy: market value from prices seen selling between two scans, else the median of the days' lowest
    offers, with far days left out by the median absolute deviation. Days of stock. Views Buy, Sell,
    Auctions, Movement, Sales. Post next and Reprice, one click each.
  - Data: the characters' data grouped by when it is read; the auction log (`Data.AuctionLog`); quest
    areas grouped by touching cells; sizes left to measure.
  - Navigation: Blizzard's map-legend and vignette atlases for quests, rares and chests; a "Seen at" line
    for rares; overlapping pins gathered into one marker; walking data as a graph of points by region;
    guides made by our tool; the section *One pin per thing*.
  - Lore: a library of what the player read and heard (Tales, Writings, Overheard, Lands, Peoples, Halls,
    Cinematics), search over it, voice packs by level band, rules of its own.
  - Dialogue: one Continue binding while the box shows, paragraphs at a reading speed, answers under the
    words, rewards compared inline, a veil instead of hiding frames.
  - Windows and Sane Sync: Blizzard's own panel backgrounds as a background choice; sample voices taken
    from the cast.
- Repository: `references/BlizzardInterfaceCode/` (Blizzard's interface code, 46 MB) is committed, the rest of
  `references/` stays local. `.gitignore` keeps all of `.claude/` and Python's `__pycache__/` out, and `*.zip`. The root
  README lists five addons and links the Social README.
- Not yet tried in the game: everything above. The in-game checks are listed in each module's README.

### Images: one pipeline for concept art, interface parts and animations
- Saneroki asked (2026-10-17) for a pipeline on this computer's ComfyUI that keeps Sane UI's art alike.
  New `dev/imagegen/`:
  - `style.txt`, the house style: the look of the concept art in words; its picture, the anchor, is
    `assets/Concept art/Elements.png`.
  - `recipes/`: one per step, each a workflow by name, its settings and its fixed words: `concept` (from
    the anchor), `concept-free`, `part` (cut out of the set's concept), `part-new`, `part-clean`, `anim`
    (Wan 2.2 14B, a loop on the part), `anim-5b`, `effect` (Wan-Alpha, transparent).
  - `sets/example/`: a set from concept to parts to an animation, to copy for a new set.
- `dev/tools/imagegen`: a list can `include:` a recipe and name its `workflow:` (looked up by name in
  `dev/imagegen/workflows/`, then in ComfyUI's folder), `set:`, `count:`, `seed:`, `out:`, `fps:`,
  `flatten:` (references with transparency laid on a colour) and `before:` (text before each prompt).
  It saves a clip as a folder of frames with a `.gif` preview, and writes `contact.png` (a row per prompt,
  a column per seed) and `imagegen.jsonl` (how each picture was made). The old form, workflow first, stays.
- New `dev/tools/flipbook`: a clip's frames as a flipbook sheet, its sides powers of two, the frame's
  side from the drawn size as `Doc/guides/images.md` sizes it; loops by fading the end into the start or
  dropping a repeated last frame; `--glow` keeps only the added light, for additive blending over the still
  part; a `.gif` preview and the FlipBook's numbers.
- `dev/tools/art`: kind `sheet`, a flipbook kept whole (power-of-two sides, TexCoords 0-1).
- `Doc/guides/image-generation.md` rewritten: the pipeline, what keeps a set alike, ComfyUI and the models
  as installed and timed here, the house style, the recipes and the words found for them, a set step by
  step, the list, animation and flipbooks. Licence notes left out.
- New `dev/tests/imagegen.py` in `dev/tests/run`: the list's lines, every recipe and set, the flipbook's
  grid, sizes and loops (no ComfyUI needed).
- Tried with the example set: a concept, parts cut out of it, a looping glow packed as a flipbook, and an
  effect. Not tried yet: a flipbook in the game.

### Voices: the voice tool, and short sounds
- New `dev/tools/voicegen` (Saneroki, 2026-10-17): the voice tool of the Lore plan, Python's standard library
  and `ffmpeg` only.
  - `design` and `pick`: a preset's voice from its design prompt in `dev/voices/cast.md`, three previews to
    listen to, the one picked kept as a voice of our account and noted in `dev/voices/voices.json`.
  - `names`: `dev/voices/names.md` as two pronunciation dictionaries (respellings for every model, the sounds
    for the models that read them), sent again as a new version only when the list changed.
  - `say`: the voice database's lines, 3 requests at a time, with a dry run, a guard above 20,000 characters,
    and a stop when the key is wrong or the credits run out. Each file is known by the hash of all that shapes
    its sound, so nothing is paid for twice; `dev/voices/made.jsonl` notes each file's request and characters.
    The service's sound is kept as it came (`dev/voices/sound/master/`, with the timing of each character),
    and the game's file is cut to the speech, evened to -18 LUFS, and made Ogg Vorbis at 22.05 kHz.
  - `sound` and `ogg --ui`: short sounds for windows as candidates in `assets/generated/sounds/`, and the
    game's file of the one chosen (starting at once, short fades, the peak at -1 dB, 44.1 kHz).
  - `key` and `account`: the key is asked for without being shown and kept in
    `~/.config/saneui/voice-service.json`, readable by its owner only, with the service's address and models;
    nothing of it is in the repository.
- `dev/tools/voicedb`: `requests` gives the requests as data for the voice tool; `request` prints them as before.
- `Doc/guides/voice-generation.md`: new sections *The voice tool* (setting it up, the models, making the
  voices, what is kept) and *Short sounds* (the game's own first, then the service, a local model or
  `ffmpeg`, and the game's file); `Doc/guides/gui-development.md`: a sound of our own only where the game has
  none.
- `.gitignore`: `dev/voices/sound/` and `dev/voices/design/`.
- Tests: 17 checks of the voice tool in `dev/tests/voices.py` (what is sent per model, the hash, the
  dictionaries, the part kept); the whole flow tried against a stand-in for the service.

### Ideas: prices per auction house, the game's facts for every realm
- `Doc/ideas/Data.md`, new section *Realms and regions* (Saneroki, 2026-10-17).
  - **For every realm, kept once:** the game's facts (items, quests, NPCs, spells, places, vendors' fixed
    prices, drop chances), per game version only.
  - **Per auction house:** what players make (scans, the price series, sales). A house is named by game
    version, region, realm (or its group of connected realms) and side. No price of one house is used, shown
    or averaged into another's.
  - A realm's kind (PvP, roleplay, hardcore) needs nothing of its own. A self-found character scans
    nothing.
  - *To check in the game:* split by faction, neutral houses, connected realms.
  - *Series*, the API comment, *Saved variables*, *Messages* and *Tests* follow it.
- `Doc/ideas/Data-build.md`: 1c.2, 1e.1 and 1f.2 carry it.
- `Doc/ideas/Economy.md`, *The history*: per auction house.
- `Doc/ideas/SaneSync.md`, *A server*: facts merged once, prices per auction house.

### Ideas: data of game versions kept apart
- `Doc/ideas/Data.md`, new section *Game versions kept apart* (Saneroki, 2026-10-17): Forever live uses only
  what Forever live showed, never a discovery of its PTR or beta.
  - Every fact belongs to one game version (`forever`, `forever-ptr`, `forever-beta`).
  - The master keeps the PTR's and the beta's versions in files of their own.
  - Packs are compiled and installed per game version, by the folder's product.
  - Core refuses a pack of another game version.
  - Saved data is keyed by game version first.
  - The harvest, messages and backups keep it apart.
  - The clock is the reason: the beta's builds (70450) are higher than live's (70245), so a beta fact would
    have become a live version, and live's patch check would have stopped.
  - *Words*, *Files*, *Staging*, *Import*, *The patch check*, *Tests* and *Contracts* follow it.
  - New decision 27: data gathered on the beta counts as live's base (`since` 0); the rest of the beta's
    own data stays the beta's.
- `Doc/ideas/Data-build.md`: the commits that touch facts carry it (1a.2, 1a.3, 1a.5, 1a.6, 1c.1, 1c.3,
  1f.1).
- `Doc/ideas/SaneSync.md`: each game version gets its own data packs; a backup goes back only into its own
  game version; data from beyond the guild keeps its game version.

### Ideas: Sane Sync: finding the game, several game versions
- `Doc/ideas/SaneSync.md`, new part *Finding the game* (Saneroki, 2026-10-17), from the game folder on
  Saneroki's computer: an installation (`.build.info`, one row per game version) holds game versions in
  folders of their own (`_forever_`, product `wowf`; `_classic_beta_`, Forever's beta), each with its own
  addons and saved files. The game told by the version, live, PTR or beta by the product; the interface
  worked out from the version.
- Found through Battle.net's own list of installed games (`product.db`), then the usual places (every drive,
  every Wine prefix); shown to the player to confirm; otherwise a folder the player picks or types, checked.
- The player chooses which game versions get Sane UI (Forever's now, retail's later), any number at once in
  any number of installations, each with its own channel, pin, rollback and backups; an update waits only
  for the game version that runs. Sane UI put there by hand or by `dev/build` is taken over only after a yes.
- *In the background:* the same program and background work on Windows, macOS and Linux; tried on real
  Windows and Mac computers before players get it.

### Voices: how lore names are said
- `dev/voices/names.md` (new): 247 lore names (77 places, 96 people, 45 peoples and gods, 29 words), each with
  a respelling for the voice service's dictionary, its IPA and a note; 61 marked unsure, to be checked by ear
  in the trial. `dev/tools/voicedb` matches a name with an *'s* after it too, and its `names` command lists
  the names the texts have and the list lacks, without everyday contractions. Tests: 97 checks (voices).

### Ideas: Sane Sync: the computer set up, measured, two processes
- Saneroki's computer set up for the app (2026-10-17): the web view, the tray menu's library, `minisign` and
  the Tauri command line from Arch's own packages. A test program (tray, window, every planned plugin and
  crate) built and ran.
- `Doc/ideas/SaneSync.md`, *How it is built*: what was measured (the program 7.5 MB, 2.4 MB packed; a tray
  process that never made a web view about 25 MB; the window open about 220 MB; WebKit's helpers stay after
  the window closes). So **two processes, one program**: the background one never makes a web view, the
  window is the same program started again and ends with its window. Known pitfalls met in the test (NVIDIA
  on Wayland, the last window ending the program, the updater's settings, `reqwest`'s TLS feature, the size
  settings). Linux's web view plays Ogg Vorbis.
- New part *Setting up a computer*: what Arch, Debian and Ubuntu, Fedora, macOS and Windows need; the signing
  key made once when publishing starts.

### Voices: the voice database, the cast, the directions
- `dev/tools/voicedb` (new), the voice database: a workbench for making the voice overs, apart from the
  game's data and never shipped (`Doc/guides/voice-generation.md`, new; asked for by Saneroki, 2026-10-17).
  It reads its staging files (`dev/voices/staging/`), the cast, the names, the fixes and the directions, and
  writes `dev/voices/build/` (`lines.jsonl`, `voices.sqlite`): every text in parts, who says it (race and
  sex from the speaker's model, the kind from its name, title or class), its preset, the words ready to say
  (placeholders, stage directions, the player's sex), its tone, intensity, pace, volume, register, tags,
  stability and direction, and what a person should look at. Commands `stats`, `show`, `request` (what would
  be sent to the voice service), `batch` (lines for a language model to direct), `names`, `check`.
- `dev/voices/cast.md` (new): 98 voice presets (4 narrators; 64 for the playable races, by sex and by the
  kinds common, martial, refined and elder; 30 for other peoples and creatures), each with its design prompt
  and design text for the voice service, its settings, its delivery and what to avoid.
- `dev/voices/analysis/northshire.jsonl` (new): the 53 parts of Northshire's quests, directed by a language
  model with the guide's prompt.
- The numbers today: 26,229 parts voiced, 4.31 million characters, about 80 hours of speech, about $345 on
  the newest model and $172 on the fast one.
- `dev/tests/voices.py` (new, run by `dev/tests/run`): 94 checks of the cast, the words, the parts, the tone
  and the presets. `.gitignore`: the build, the staging files and the voice packs. `Doc/ideas/Lore.md` points
  to the guide.

### Ideas: Sane Sync: built with Rust and Tauri 2
- `Doc/ideas/SaneSync.md`, *How it is built*: the proposal is now Rust with Tauri 2 (stable; its own plugins
  give the tray, the start with the login, the app's own signed updates, one app at a time, the folder picker
  and notices), a window of plain HTML, CSS and JavaScript in the system's web view (no Node), and a table of
  what does what: downloads, minisign signatures for the manifests and the app alike, zips, file events for
  the saved files, the game's process, a reader of our own for saved files (never run), sound for the
  samples. Weight, what Saneroki's computer needs, the packages, and why not Go with Wails (its tray needs
  Wails 3, still in beta), a tray without a window, a bundled browser or others.

### Ideas: Sane Sync: hear a sample of the voices
- `Doc/ideas/SaneSync.md`, new *Voice packs* under *Updates* (what was a line in *Giving out a version*): the
  packs offered one by one and updated file by file; and Saneroki's button *Hear a sample* (2026-10-17): five
  samples, one per press, in a circle, the narrator and four voices of different races, sides and sexes, with
  the speaker, the pack and the words shown while it plays; made by the voice tool with the packs, about 80 KB
  each. `Doc/ideas/Lore.md`, *Downloading and updating*, points to it.

### Ideas: Lore: the voices are downloads of their own
- `Doc/ideas/Lore.md`, *Voice packs*: Saneroki (2026-10-16): the voices are Sane UI packages of their own,
  downloaded separately; Lore plays a voice only when it finds its package installed.
  - Packs titled *Voices: ...*; each holds its sound files and the index of its own lines (the `Voices`
    set is gone from `SaneUI_Data_Lore`).
  - Found at login from the addon list and the packs' TOC lines (`X-SaneUI-Voices`, `X-SaneUI-Format`) without
    loading them; a missing pack is silent, listed on Lore's page, no popups.
  - Not in git: built into `BUILD/SaneUI_Voice_*/` (ignored), left alone by `dev/build`, the sound kept safe
    outside the repository; the cast, the names list and the list of what was made are committed.
- `Doc/ideas/SaneSync.md`, *Giving out a version*: the app offers the voice packs one by one, installs only
  those picked, and updates them file by file.

### Ideas: Lore: what the voices cost and weigh
- `Doc/ideas/Lore.md`, *The estimate*: the game's texts (5.9 million characters, 100 to 125 hours) about $470
  on the newest model or $240 on its fast version, 1.8 to 2.2 GB as mono Ogg Vorbis at about 40 kbps
  (22.05 kHz, silence cut); with our own places and library about $590 / $300 and 2.2 to 2.8 GB. Sizes at
  other rates.

### Ideas: Lore: where the texts come from, the voice service
- `Doc/ideas/Lore.md`: Saneroki chose a cloud voice service for the AI voices (2026-10-16);
  `dev/tools/voicegen` sends the texts through its API. New parts *The texts* and *The service: cost and
  form*, researched today:
  - Almost every text comes from the server, not from the client's files. The original world's texts are
    Blizzard's own (Blizzard's IDs); Forever's own from a quest sweep (`RequestLoadQuestByID` over
    `QuestV2`'s 6,614 IDs, read back from `questcache.wdb`, whose layout was checked here), the hotfix cache,
    the client's `MailTemplate` and `ConversationLine`, and in play (progress and hand-in texts are sent only at
    the NPC).
  - About 6 million characters, about 100 hours of speech: about $480 on the newest model, $240 on its fast
    version, about 2.2 GB as mono Ogg Vorbis; a trial of a few hundred lines first.
  - Placeholders, male and female texts, racial languages, lines Blizzard already voiced.

### Ideas: Lore
- `Doc/ideas/Lore.md` (new): Saneroki's idea of a module **Lore** (2026-10-16): voice overs with AI voices, a
  library about the world and its lore, and lore tidbits in tooltips and other places.
  - Data is Core's (`SaneUI_Data_Lore`: the sets `Lore` and `Voices`; Core's watchers keep the books, talk
    and movies the player saw); each module shows tidbits in its own views; everything by the game's IDs.
  - The library: chapters by kind of lore, filled by playing, no spoilers.
  - AI voices made before on this computer (`dev/tools/voicegen`) and shipped as sound packs, about 2 GB;
    played only while the game's text still matches its hash, in parts, one queue, a voice bar; the game's
    text to speech as the fallback.
  - Open questions for Saneroki at the end.

### The page Sane UI: links and feedback
- `Settings/About.lua` (new, in Core's TOC after `Synced.lua`): under the banner of the page *Sane UI*,
  the sections *Community* (Discord, Website, GitHub) and *Feedback* (Report a bug, Suggest a feature,
  General feedback), the game's own section headers and button rows (`Config.Fill` calls `About.Fill`).
  - A link's *Copy link* shows its address selected in the game's `GENERIC_INPUT_BOX` (an addon cannot
    open a browser; `CopyToClipboard` is restricted). The addresses (`About.LINKS`) are empty for now:
    their rows say *Coming soon*, the button off.
  - A feedback button opens `SaneUIFeedbackFrame` (`ButtonFrameTemplate`, `InputScrollFrameTemplate`, made
    when first opened, Esc closes it). *Make report* turns what was written into a report to copy and
    paste on GitHub or Discord: versions, language, modules, class and level (no name), and for a bug the
    5 newest errors. Writing is kept per kind for the session.
  - `/sane feedback [bug|idea|note]`, `/sane bug`.
- `Settings/Settings.lua`: calls it; heads say so. `Settings/README.md`, `Doc/agent/core.md`.
- `dev/tests/wowstub.lua`: `ButtonFrameTemplate`, `InputScrollFrameTemplate`, `CLOSE`, `GetLocale`,
  `tinsert`, `ButtonFrameTemplate_HidePortrait`, `InputScrollFrame_SetInstructions`, two sounds.
- Tests: 207 checks (Core).

### Social: the button Sane UI on the game's chat; no title on the small window
- `Social.lua`: `ns.NATIVE` now has `frame` (the strip of buttons left of the game's chat,
  `ChatFrame1ButtonFrame`), `back` (ours shown again, the switch *Chat window* on) and `anchor`.
  - Core's button *Sane UI* stands just above the game's chat menu button and fades with the game's buttons.
  - A click brings our window back.
  - The line said when ours is put away names the button.
- `Window.lua` (Social):
  - The button is shown only while our window is away (`Back`).
  - Off at login, the window is made out of sight, so the button is there (`Window.Away`).
  - The small window's bar has no title *Social* any more (Saneroki).
- `Core/Window.lua`: `native.anchor(button)` says where `Attach` puts the button, for a game window
  without a close button. `Doc/guides/windows.md` says so too.
- Tests: 336 checks (Social).

### The name Sane Sync in the licence; licensing left to Saneroki
- `LICENSE`, section 2: *Sane Sync* is a name kept to Saneroki like *Sane UI*; an addon or app built from the
  code carries another name (Saneroki, 2026-10-16). The builds' `LICENSE.txt` follow.
- `AGENTS.md`: the licence rule is replaced by Saneroki's new one: agents do not handle licensing unless
  Saneroki asks (it stands over every earlier licensing note).
- `Doc/ideas/SaneSync.md`: the licence questions taken out; the name in the `LICENSE` noted as decided.

### Ideas: the app is Sane Sync; Sane UI is open source
- `Doc/ideas/App.md` renamed `Doc/ideas/SaneSync.md` (Saneroki, 2026-10-16: the app is called **Sane Sync**;
  not Core's Sync). Saneroki: the repository is public and fully open source, anybody may fork it and add
  code. New part *Open source*: only Saneroki's versions carry his signature, code from others comes in by
  pull request, a fork gives out its own versions with its own key, host and name; GitHub Releases and
  GitHub's build service as the proposal, the build service only building, signing on Saneroki's computer.
- Open question: *Sane Sync* in the `LICENSE`'s name section.

### Ideas: Onboarding: the switch and the ?
- `Doc/ideas/Onboarding.md`: Saneroki answered two questions. After an update What's new opens by itself,
  unless *Show what's new after an update* is off on the module's own page (put up by Core at login, as the
  module loads on demand). Help comes from a ? in a window's title bar, before the button to the game's
  own window, only in the Sane UI view: Blizzard's help plates over the window (this client hides
  Blizzard's own ? buttons); no tips by themselves, no `HelpTip`. `Doc/ideas/Windows.md`, *Title bars*:
  the ? noted.

### Ideas: the Sane UI app
- `Doc/ideas/App.md`, new (Saneroki, 2026-10-16): a small program for Windows, Linux and macOS, outside the
  game, that keeps Sane UI up to date. Proposals: versions given out as one signed zip per addon folder
  (Ed25519, the key only on Saneroki's computer; a folder that did not change is not downloaded again),
  installed only while the game is closed; channels, pinning and rollback with the saved files from before
  the update; daily backups of Sane UI's saved files; a tray icon and the start with the login per system;
  Go. It only reads and writes Sane UI's own files and never touches the running game.
- **Beyond the guild,** smallest first: Blizzard's web API for prices (to check for this game), a hidden
  realm channel, then a server through the app. Data goes out through an outbox the addon fills and comes
  back as a data file the app writes (never code), taken in like one more guild member's.
- The order of work and Saneroki's open questions (name, folder, hosting, defaults).

### Windows: Saneroki's answers to the review
- **Kinds of window** (Core, `Window.KINDS`): `kind = "screen"` (the chat, the minimap), `"panel"` (the
  spellbook, the guild, the bags), `"talk"` (a vendor, the bank) gives a window its kind's options; the
  module's own win. What the Combat module shows (unit frames, nameplates, buffs, action bars) is no window.
- **A dock zone holds one window at a time** (Core, `Dock.Hold`, `Dock.Holder`): while a window is docked
  there and shown, a drag offers the zone to no other (no shape; let go, it stays free), and a window opening
  with that zone kept stands free that time. Windows not shown hold nothing, so the talk windows share the
  middle.
- **Ours or the game's, never both** (the plan and the guide): a window does not replace the game's; it is
  set to one of the two and only that one is seen. Core keeps the game's out of sight by Economy's holder,
  made one way for every window (to build): held under a hidden frame while closed, the game opens and
  closes it unseen, Core follows by hooks after its `Show` and `Hide`. Override bindings, buttons over the
  micro menu and `RegisterPlayerInteraction` are not taken (the last needs a `/reload` to give back).
- **Full screen views:** the board per module, as proposed, is decided.
- Tests: 234 checks (windows).

### Windows reviewed: the guide, and what the review fixed
- **`Doc/guides/windows.md`**, new: how every window of Sane UI is built, for whoever builds the next one.
  The kinds (HUD, panel, talk) and their options, Core's parts and the module's share, the states and the
  invariants that keep them apart, what is kept, the recipe, the rules (taint with the game's own windows,
  combat, performance, resilience, look), what is not built yet in order, and every fact it rests on with
  the Blizzard file it was checked in. Linked from `AGENTS.md` and `Doc/agent/core.md`.
- **Core, fixed by the review:** a window holding the game's protected frames is not moved, sized, shown or
  hidden in a fight (`window:Locked()`: no drag, no sizing, no full screen, `Place` waits for the fight's
  end, a full screen motion on its way is finished as the fight begins, `Open` says `"locked"`). Esc closes
  a window made so (`escape = "close"`, one stand-in in `UISpecialFrames` for all). `Reset` keeps what a
  window was left as (full screen, the game's own). Without the game's Edit Mode `/sane arrange` gives our
  windows the same mode. Edit Mode's boxes of ours hide and show with Blizzard's when Edit Mode hides them
  for a while without closing (hooks after `ShowSystemSelections`/`HideSystemSelections`). Fuzzy: a score
  makes no tables (two kept rows) and each text is lowered once per match, about 10 µs a match.
- **Social:** the game's friends list in *Classic windows* is not asked for in a fight (the game refuses an
  addon then, "Interface action failed"); a line says to use the game's own key.
- **The plan (`Doc/ideas/Windows.md`) corrected:** Edit Mode's layouts are followed by one hook after
  `UpdateLayoutInfo`, keyed by preset number or type and name (a character's by the character too); Core
  never calls `SetHasActiveChanges` (its flag would be tainted) and enables *Save* and *Revert Changes*
  itself; Edit Mode works in a fight. The nine places, the middle, the title bars and Esc said one way
  throughout.

### Ideas: Onboarding
- `Doc/ideas/Onboarding.md`, new (Saneroki, 2026-10-16): a module of its own, loaded on demand when a new
  version of Sane UI is found, that helps players understand its features. Proposals: Core finds the new
  version at login (`SaneUIDB.seen`, per account, outside the profiles) and loads the module only then;
  Welcome the first time, What's new after an update, laid out like Blizzard's own splash; *Show me* per
  feature, one-time tips with `HelpTip`; the words in `News.lua`, kept in step with `changelog.txt` by a
  test. For later: Sane UI is not given to others yet. Six open questions, among them the name.

### The Navigation plan reviewed, and how it is built
- `Doc/ideas/Navigation.md` reordered: Saneroki's decisions, a review, the design, the build order, the
  reference, open questions with proposals (built as proposed if not answered). Every claim checked
  against `references/`. No code yet.
- **Corrected:** a canvas of our own instead of Blizzard's map canvas, whose pins call protected functions
  without a combat guard (a canvas made by an addon would raise blocked actions in a fight); the wheel
  never steps to the parent map there; no dungeon entrance pins from the game in this client; continents
  found at run time (the client's code names none); the native minimap's rotation ignored, not the CVar
  changed; positions read as possibly hidden; known flight points only from the flight master.
- **New in the design:** the three coordinate spaces; the layers and a holder that makes a pan one
  `SetPoint`; the small view on Blizzard's own hybrid minimap pattern; how the game's map and minimap are
  kept out of sight and given back, with the fight left to try; the planner and walking data in Core's
  scheduler and pack; the golden line's pulse as an engine animation; the leveling guide's secure item
  button kept out of the map window; what Navigation reads from Core; budgets, caps, tests, fallback.
- **Build order:** step 0 proves the risky parts in the game first (tiles, the native minimap's dots, the
  map key and a fight, hidden positions, the quest area frame, the frame time).

### Ideas: the Tooltips redesign reviewed, and how it is built
- `Doc/ideas/Tooltips/Build.md`, new: the review of the plan in `Types.md` and the plan for building it,
  checked against the module's code, the guides and Blizzard's API in `references/`. The pipeline (facts
  in the model, a pure `Look.lua`, the art as data in `Looks.lua`), every fact with its source, the
  rules and their order, the layers as drawn, falling back layer by layer, time and memory (about
  12 MB for all the art), the tests (every value has a look, no missing or dead art), the steps, what only
  the game can show, five choices open for Saneroki.
- `Doc/ideas/Tooltips/Types.md` corrected:
  - Things are known by IDs, not by their words: a creature type through `C_CreatureInfo`, an NPC's role
    and an object's kind from Core's World pack; the English words only until that pack exists.
  - The frame split into a border (stretched, corners kept) and a socket (fixed, round the picture);
    a unit's rank is its socket, which also covers the live model's square corners.
  - The ground a band at the top that fits every panel size; borders and sockets neutral metal for the
    accent; dead, ghost and offline desaturated.
  - One order of rules for items and a default for every item class; Mailbox and Holiday lose their
    grounds; the images counted again (still about 80).

### Ideas: Economy reviewed: checked against the code, a plan for building it
- `Doc/ideas/Economy.md` checked against Core's code, Blizzard's code in `references/` and
  `Doc/ideas/Data.md`. Corrected:
  - Hiding Blizzard's window: alpha 0 left its buttons taking the mouse and its place in the panel layout.
    Now a hidden parent set between talks, so the window never comes into sight and its `OnShow` and
    `OnHide` never run; tiny and clear in the middle of a talk; *Classic* gives it back to UIParent.
  - The talk's own events (`MERCHANT_SHOW`, ...) start a window: on this client the trainer and the auction
    house also open without the interaction manager.
  - Core already keeps *Classic* and full screen (`window:Open`, `Native`, `Remember`), and its title bar
    moves a window at any time; Esc closing a full window is Core's `escape = "close"`, being added.
  - Pets' species come from the link; the bank is this client's own `Camelot/BankFrame.lua`; the mailbox is
    not loaded on demand; the trainer's filters are shared with Blizzard's window.
- Added: the game's own item key for prices; links only for weapons, armour and pets; the scan's time in
  the server's clock; the size of a full history (about 45 MB a year) and what *kept in full* can mean in
  the game; market value and price to post; *sold between two scans* as an experiment checked against the
  player's own sales; buying only from the server's answer, the throttle, one click per post.
- New part *Building it*: who does what, a window's life as a table of states, what Economy needs from
  Core and the database (with what is done), rules for the code, the tests, the files, and the order of
  work with when each step is done (the vendor first, to prove the hiding).
- New wishes to the database (the scan's state, a stamp for series, one item key, a day's point from
  several scans) and a new open question (*kept in full*).

### The data plan: second pass, contracts and the build in commits
- `Doc/ideas/Data.md`, *Review*, new part *Second pass*. The formats, the limits of Lua and the client,
  and the rules that keep wrong data from staying, measured with Lua 5.1 where it says so. Corrected in
  the page's own sections:
  - rows cut by tab and ASCII 30/31, which no game text holds, instead of commas and `=`;
  - every version whole in the pack;
  - records kept weakly;
  - Lua's constant limit is per function: the compiler cuts rows into functions, and every saved variable
    keeps a budget of values;
  - compiling gives the same bytes for the same master: hashes instead of a dated release. The first
    of these corrections went in with commit 36c9f65;
  - learned data wins only while it is newer;
  - an empty answer is no fact;
  - days from the server's clock;
  - drop chances per corpse looted (`GetLootSourceInfo` is not in the client's code: to check first);
  - sharing: 90 messages a minute per sender, a random wait before *want*, the packed block capped, facts
    of a newer build wait, shared counts bounded;
  - jobs as coroutines, which never yield inside `pcall` (there is no `Core.Guarded`);
  - no licence line in a schema.
- New section *Contracts*: a master's line, a pack's TOC and Lua file, the answers' shapes, the saved
  variables, messages, clocks and jobs. Step 1a carries it into the guide.
- New `Doc/ideas/Data-build.md`: prompt 1's six steps cut into 25 commits, each with its tests and
  Saneroki's checks in the game, and how a session goes on where the last one stopped.

### Ideas: Navigation: leveling guide
- `Doc/ideas/Navigation.md`, new section *Leveling guide* (Saneroki, 2026-10-16): Navigation leads through
  leveling step by step, with the guides as Core's data (`Doc/ideas/Data.md`: set *Guides*, pack
  `SaneUI_Data_Guides`). What a guide and a step are, what Navigation does with them (proposal), step texts
  of our own, and the feasibility. Five new open questions, among them how the guides are made.

### Dialogue planned
- Saneroki's answers are in the page (2026-10-16):
  - Dialogue is a feature of Social, not a module of its own;
  - it stands in the middle of the screen (`CENTER`);
  - the rest of the interface is hidden by default, with a setting to keep it;
  - combat closes the dialogue;
  - books and letters (`ItemTextFrame`) are part of it.

  `Doc/ideas/Social.md` lists it.
- `Doc/ideas/Dialogue.md`: a new module (working name *Dialogue*) for talking to an NPC as a scene,
  standing for the game's gossip and quest windows. It covers:
  - the NPC's face, its words, and the answers;
  - quests and their rewards;
  - the keyboard, only while the talk is in sight and never in combat;
  - Economy's holder, with the way back to the game's windows.

  No code yet; the open questions are for Saneroki.
- `Doc/agent/README.md`: the page is listed.

### The data plan reviewed
- Saneroki agreed to decisions 19 to 26, and to English only (decision 7). The answers are written into the
  page's own sections: *Versions*, *Import*, *Loading*, *The game's own data*, *Learned*, *Performance*, *Files* and prompt 1's six steps.
- `Doc/ideas/Data.md`, section *Review*: the plan was checked against `references/` and Core. Corrected:
  - packed messages are made text (`EncodeBase64`) before sending, and the scan's cost is updated;
  - the send budget of 10 messages, then one a second, is Blizzard's own plan, not the server's limit.
- New decisions 19 to 26, built as proposed if not answered:
  - where learned data waits while its pack is not loaded;
  - `Get` never loads a pack;
  - hotfixes without a new build;
  - other languages;
  - items in tooltips;
  - domain code with its pack instead of Core;
  - the frame budget at high frame rates;
  - prompt 1 split into six steps.

### Nine dock zones
- `Core/Dock.lua`: the zones are the four corners, the middle of each edge (`TOP`, `BOTTOM`, `LEFT`, `RIGHT`)
  and `CENTER` (Saneroki, 2026-10-16). `TOP1`, `TOP3`, `BOTTOM1`, `BOTTOM3` are gone; `TOP2` and `BOTTOM2` are
  renamed `TOP` and `BOTTOM`. A window saved at an old name stands at its kept coordinates. `Dock.Anchor`
  needs no offset any more. Tests: 202 checks (windows).

### No banners for Abilities and Social
- `src/Abilities/Art/banner.blp` and `src/Social/Art/banner.blp` are gone, so the two modules' options pages
  show the game's own title instead of a picture (Settings looks for a banner and keeps the title without
  one). `dev/tools/art` still makes them in `assets/optimized/` but ships them to no module. The pictures
  in `assets/` stay. Social's smiley stays.

### Ideas: Economy: Hide Blizzard's window per window, Esc closes, mailbox, guild bank and bags
- `Doc/ideas/Economy.md` (Saneroki, 2026-10-16): moving, sizing and docking are Core's window system's, not
  the module's. *Hide Blizzard's window* is one switch per window. Esc closes a window, also in full screen,
  so the remembered view stays (Core needs a window option for it; `Edge` brings a full window back today).
  New section *More windows*: mailbox, guild bank and bags. Open: the two wishes to the database, and which
  module holds the bags.

### Ideas: quests, creatures and the map in the data plan
- **`Doc/ideas/Data.md`:** quests (requirements, chains, stages, breadcrumbs, places of the steps, quest
  areas as cells, the game's own area read by its point test), creatures (stats, abilities, buffs,
  services; what the game hides in combat), places on the map (spawns, services, rares, treasures, herbs
  and ore, flight points; one list per map), what every kill teaches (where, for which quest), and the
  beta's auction history pruned once on 1 November 2026, by hand with a prompt (no function of the addon).

### Ideas: Combat's first decisions
- `Doc/ideas/Combat.md` (Saneroki, 2026-10-16): Combat's frames are our own windows on Core's window system
  (unit frames and buffs without a title bar); the look is developed along the way; floating combat text,
  raid warnings, threat and the swing timers are Combat's too, each on demand (how, developed further);
  party style and click casting are decided during development. Their parts, the game's frames and what
  the reference says of them (combat text's event info is secret; the swing timers are this client's own);
  a window holding secure buttons moves and changes size only out of combat (for Core, to build). No code.

### Windows: title bars with a fuzzy search; what a window was left as
Tests: 330 checks (Social), 202 checks (windows). Not tried in the game. New file: restart the game.
- **Title bars** (Saneroki, 2026-10-16; `Window.lua`): `titleBar` (per kind of window; the small chat, unit
  frames have none) puts a bar `Window.BAR` (32) high across the window's top, `Window.BAR_LEVEL` above it, a
  thin bronze line under it: at its left a button with the game's magnifier (with `search`) and the
  `title`; at its right the buttons, which moved there from the window's corner (`chrome` and
  `Window.TITLED` are gone; the buttons show with the bar, not in Edit Mode). Every window that fills the
  screen has the bar at its top. A click on the title opens the game's `SearchBoxTemplate` over the bar up
  to the buttons (or Edge's dropdown), the cursor in it; every change goes to `options.search(text)`; Esc,
  or the cursor leaving it empty, closes and empties it (`search("")`). The bar (and the title: a press
  that became a drag opens no search) is `Window.Mover`'s handle: `window:Draggable()` (only with
  `titleBar`; not in Edit Mode, not while away; docked at a screen edge only with `dragDocked`), and such a
  drag docks only in `Window.DRAG_ZONES` (`CENTER`): `Dock.Watch(frame, only)`, `Dock.Find`/`Of` take `only`.
- **Fuzzy finding** (`src/Core/Fuzzy.lua`, new): `Query(text)` (the typed words), `Match(query, ...)`
  (every word in one of the texts: the total; nil), `Score(word, text, lower, places)`, `Mark(text,
  places)`.
- **What a window was left as** (Saneroki: every window remembers maximized or small, place, size, the game's
  own window or ours): `window:Remember(what, value)` in its place table (carried over by `Keep`): `full`
  (`Edge.Fill`), `native` (`window:Native(on)`, which the toggle buttons call now). `window:Open()`, for a
  module when the game asks for the window: `native.show()` if the game's was chosen, else ours shown and
  full again if it was left so (`"native"`, `"ours"`).
- **Edge:** the dropdown *Classic windows* in the title bar left of the buttons (`Edge.MENU_ROOM` gone);
  `Stand` refreshes the bar once the dropdown is there.
- **Social:** no title bar while small (Core's buttons left the small window); full, Core's title bar at the
  top (`search`: `Window.Search`, `Visible` keeps the messages `Core.Fuzzy.Match` finds every word in: their
  readable text, the speaker's name, the chat's), its own bar hidden (`Chrome`), the list under the title bar
  (`Top`).
- **`/sane window`:** a title bar (`titleBar`; its own title text gone), 60 high.
- Docs: Core's and Social's READMEs, `Doc/agent/core.md`, `Doc/guides/gui-development.md`, `Doc/ideas/Windows.md`
  (*Title bars*, *Full screen views*, *The game's own triggers*, the spellbook to be rebuilt on Core's window).

### Art: making pictures with image models
- `Doc/guides/image-generation.md` (Saneroki asked, 2026-10-16): local, free image generation for Sane UI's
  art. ComfyUI installed by hand (Python 3.13, CUDA 13), five models for a 12 GB card (Qwen-Image 2.1 as
  the main one: references and transparent pictures; FLUX.2 [klein]; Z-Image Turbo; SDXL; FLUX.2 [dev]),
  how to ask for interface art, and how a frame becomes pieces the game stretches (slice margins, nine
  pieces as in Blizzard's frame files). Researched, nothing installed or tried yet.
- `dev/tools/imagegen`: queues a whole set in ComfyUI from a workflow (API form, `{prompt}` and `{name}`
  in it) and a list (`name: prompt`, `style:`, `ref:`), the same seeds for every part; uploads the
  references (BLP turned into PNG), waits and saves `<name>-<seed>.png` with `--out`. Tried against a
  stand-in server only, not against ComfyUI yet.
- `.gitignore`: `assets/generated/` (what the models make). `AGENTS.md`, `Doc/agent/development.md`: the
  guide and the tool.

### Combat: a new module, set up
- Saneroki, 2026-10-16: a module **Combat** for everything about party, raid, buffs, unit frames, nameplates
  and pets. `src/Combat/`, addon `SaneUI_Combat` (`SaneUI_Combat.toc`, title *Combat* in the addon list,
  under Sane UI, needs Core only), first file `Combat.lua`: `Core.NewModule(ADDON, "Combat", ns)` and nothing
  else. It loads and changes nothing; no options page until its first part has switches. Module README.
- The plan: `Doc/ideas/Combat.md`: its parts and the game's frames each stands for in this client
  (camelot), the game's Edit Mode settings for them, what is secret in a fight, party and raid headers,
  buffs, nameplates; how every part works (the game's frame parented away, fallback, combat lock, present
  never compute, reads only, cheap, Edit Mode, one tabbed page); an order to build; open questions.
- `Doc/ideas/Windows.md`: the top left place (party and raid) is Combat's.
- `Doc/guides/addon-standards.md`, *Secret values*: corrected from the reference. `SetShown` and
  `Cooldown:SetCooldown` take no secret from addon code (`SecretArguments = "AllowedWhenUntainted"`); which
  widgets do (`AllowedWhenTainted`), and the game's duration objects for swirls and timer bars.
- `AGENTS.md`, `Doc/agent/README.md`, `Doc/agent/development.md`: five addons.

### Ideas: every look of a tooltip, from layers
- `Doc/ideas/Tooltips/Types.md`, section *Looks* (a proposal, after Saneroki, 2026-10-16: looks by element,
  creature type, class, race, rarity, kind of item, gatherables, chests): a look is put together from
  layers, each chosen by one thing: a ground (an element, a material, a creature type, a homeland, a
  profession), a frame (quality, rank, buff or debuff), the game's picture, an accent (the game's
  colour), marks (side, class, role, state, quest, a profession needed). Every dimension with all its
  values, the layer it chooses and how the module knows it (or that it does not read it yet), for items,
  spells, units, buffs, quests, world objects (herbs, veins, chests, mailboxes: a layout to come) and the
  rest; where a tooltip is shown changes rows, not looks. The list of images: about 80 (63 grounds, 16
  frames, a few marks) for every combination. No code.

### Ideas: Economy's windows, Classic remembered, the history in Core's database
- `Doc/ideas/Economy.md` (Saneroki, 2026-10-16): *Classic* is remembered per window, also across sessions;
  every Blizzard trade window has a button beside its close button back to ours (Core's `native` and
  `window:Attach()`). The windows open in the middle of the screen (`CENTER`) with Core's window handling;
  Economy fills them and sets their size; they are dragged, snap to the dock zones and keep place and dock.
  The full history is kept: the scan and the series *Prices* are Core's database's (`Doc/ideas/Data.md`),
  Economy only reads; its `Scan.lua`, `History.lua`, the size worries and *Keep history* are gone. Two wishes
  to the database (the last scan whole, sold between scans) and new open questions (dragging outside Edit
  Mode, a grip).

### Tooltips: live 3D portraits
Tests: 328 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **A unit's portrait is its live 3D model** (Saneroki, 2026-10-16: the first step of the redesign with templates per
  tooltip type, `Doc/ideas/Tooltips/Types.md`): `Figure` in `Panel.lua`, a `PlayerModel` in the portrait's place,
  64 large, `SetUnit` and `SetPortraitZoom(1)`. One per panel, made for its first unit; given the unit only when
  the GUID changes (again would reload the model and restart its animation), forgotten on hide. Where `SetUnit`
  does not return true (out of sight, hidden identity, an error: `Core.Ask`) or the client has no `PlayerModel`
  (`pcall`, not tried again), the flat `SetPortraitTexture` as before.
- The dragon, the plaque and the level stand on `panel.front`, a frame over the figure (a frame draws over its
  parent's regions); the level's pool text is lifted onto it (`Pools.Lift`) and put back on the panel when the
  pool uses it again. Frame levels each draw: figure the panel's + 1, front + 2.
- `Panel.Strength` sets the panel's alpha and the figure's by itself (a model frame need not follow its
  parent's); `Gate` in `Tooltips.lua` uses it.
- New option `models` (*Live 3D portraits*, on at first) on the page Tooltips.
- Docs: the module's README (setting, technical details, to check in the game, history),
  `Doc/agent/tooltips.md`, the plan in `Doc/ideas/Tooltips/Types.md`.

### Ideas: every tooltip type and portrait type, for the redesign
- `Doc/ideas/Tooltips/Types.md` (Saneroki, 2026-10-16): the Tooltips module is to get a new look from
  AI-generated art, keeping its data and layout. The page lists every type the module draws (items,
  spells, buffs, quests, the rest), how each is known, its look now and what it shows; the parts every
  design restyles; and, for units only, a table of portrait types (player, enemy, elite, rare, boss,
  pet, corpse, ...) with what the game says of each: race, gender, creature type and family, faction,
  reaction, rank, class, level. No code.

### Spellbook is Abilities
- The Spellbook module is renamed **Abilities**: its features will go beyond the spellbook. Folder
  `src/Abilities`, addon `SaneUI_Abilities` (`SaneUI_Abilities.toc`, title *Abilities* in the addon list and
  on its options page), first file `Abilities.lua`, `Core.NewModule(ADDON, "Abilities", ns)`. Commands
  `/sane abilities` and `/sane ab`; `/sane spellbook` and `/sane sb` stay as further words. Error labels
  `Abilities: ...`.
- Core (`Saved.lua`): `RENAMED` has `Spellbook = "Abilities"`, so everything kept under the old name
  (store, profiles, the account's and the character's settings) moves to the new one once at load.
- `dev/build` removes the old `SaneUI_Spellbook` folder from the game's AddOns folder; `dev/tools/art`
  writes the banner into `src/Abilities/Art`. The art files keep their names (`SaneSpellbook-*.png`).
- Unchanged on purpose: the spellbook's frames (`SaneUISpellbook`, `SaneUISpellbookHome`, ...) and
  texts about the game's spellbook; they name the spellbook, not the module.
- Tests: `dev/tests/spellbook.lua` is `dev/tests/abilities.lua`; it checks the move of the old saved
  settings and the old command words. Docs: READMEs, `AGENTS.md`, `Doc/agent/abilities.md` (was
  `spellbook.md`), the guides. 298 checks (Abilities).

### Windows: a dock place in the middle; buttons on free and centred windows
Tests: 327 checks (Social), 178 checks (windows). Not tried in the game. `/reload` is enough.
- **`Dock.ZONES.CENTER`** (Saneroki, 2026-10-16): the middle of the screen, touching no edge; a window let go
  with its middle within `Dock.REACH` of the screen's docks there, anchored by its centre. For the windows
  the player talks to (vendor, trainer, auction house: `Doc/ideas/Economy.md`).
- **Buttons** (`Window.lua`): a window free or docked in a zone of `Window.TITLED` (`CENTER`), Edit Mode
  closed, has a frame `Window.BUTTON_INSET` (4) from its top right corner, its parent `options.chrome` or the
  window, holding from the right: the game's close button (`UIPanelCloseButtonNoScripts`; `options.close`,
  else the window is hidden); with `edge` and *Can expand to fullscreen* on, the game's
  `MaximizeMinimizeButtonFrameTemplate` (`edge:Fill`; its look follows the window however it fills the
  screen or goes back: `window:Refresh()` from `Place`, `Edge.Fill`, `Edge:Update`, Edit Mode); with
  `options.native = { frame, show, back }`, the game's square button (`UI-SquareButton-*`) with its circling
  arrows (`UI-RefreshButton`), tip *Classic window*: `native.show()`. `window:Attach()` (also at `New`)
  puts the same button (tip *Sane UI window*: `native.back()`) on the game's window, beside its close button
  (`CloseButton` or the global *name*`CloseButton`, read raw), at its level: our frame, kept in our own
  table. Shown buttons stand side by side (`buttons.first`: the leftmost).
- **Edge:** a free or centred window fills the screen by its button (`placed`, was: only docked windows)
  and goes back to where it stood (`edge.left`, `edge.bottom`); full, the dropdown *Classic windows* stands
  left of the buttons.
- **Social:** `native = ns.NATIVE` (the game's chat: our window put away, as *Chat* in *Classic windows*),
  `close = ns.Close` (the same), `chrome = bar` (the buttons come with the mouse, as the bar); free or in the
  middle the list starts under them (`Top`).
- **`/sane window`:** its help names the middle and the buttons.
- Docs: Core's and Social's READMEs, `Doc/agent/core.md`, `Doc/ideas/Windows.md` (*The middle, and windows
  not docked*), `Doc/ideas/Economy.md`.

### Windows: moved and sized only in Blizzard's Edit Mode
Tests: 322 checks (Social), 158 checks (windows). Not tried in the game. New file: restart the game.
- **`Core.EditMode`** (`src/Core/EditMode.lua`, new, in the TOC before `Window.lua`): `active` and
  `Watch(fn)`, from the game's event registry (`EditMode.Enter`, `EditMode.Exit`, whose callbacks it runs
  through `securecallfunction`, so ours carry no taint into Edit Mode); at login it reads
  `EditModeManagerFrame:IsEditModeActive()` once (a `/reload` in Edit Mode). Edit Mode is never written.
- **`Window.New`:** no drag and no grip outside Edit Mode (`window.usable` is false there; the frame takes
  no mouse of its own: `bar` is gone, nothing calls `Window.Mover` on it). When Edit Mode opens, each window
  gets its box (`window.box`, made once): `Window.BOX_LEVEL` (100) above it, Edit Mode's art
  (`EditModeSystemSelectionLayout` from `Blizzard_EditMode`, copied, as it is local there; kit
  `editmode-actionbar-highlight`; `NineSliceUtil.ApplyLayout` on our own frame, not Blizzard's selection
  template, which would hand our frame to Edit Mode's manager), a copy at 0.4 added and the window's
  `title` (new option) while the mouse is on it. The box is what `Window.Mover` drags; the grip lies one
  level over it and is shown only in Edit Mode. A window filling the screen goes back when Edit Mode opens;
  one in hand when it closes is let go and kept (`Moved`, `Sized`). Without `NineSliceUtil` the box is
  there unseen.
- **Edge:** the screen's edge does nothing while Edit Mode is open (`Pushed`).
- **Social:** the bar is only the title (it takes no mouse); the grip left the chrome (Core shows it in
  Edit Mode); `title` names its box. Its tests move and size the window in Edit Mode.
- **`/sane window`:** its help and the command's line say *In Edit Mode*; `title` names its box.
- The place is kept at once when let go, as before: not yet in Edit Mode's layouts (`Doc/ideas/Windows.md`).
  The Spellbook module's own moving and sizing of the game's spellbook (`Window.Mover`, `Window.Sizer`) is
  as it was.

### Ideas: the Economy module
- `Doc/ideas/Economy.md` (new; Saneroki, 2026-10-16): a module *Economy* with windows of its own for the
  auction house, vendor, trainer and bank. *Hide Blizzard's windows* (ticked by default) and a *Classic*
  button on every window, always; expand and collapse, the last view remembered; Core's motion on
  opening. A full scan of the auction house every time it opens (the server allows one per 15 minutes,
  `C_AuctionHouse.ReplicateItems`), kept in a growing database of our own. Proposals: hiding Blizzard's
  windows without ending the talk with the NPC (their `OnHide` closes it), the database's three layers and
  its size, prices from the history, each window's views, settings, files, order of work; open questions.
  No code yet.

### Social: open points written down
- `src/Social/README.md`: *To check in the game* has the full screen without the bubbles going, marks in a
  channel of your own, and joins and leaves (FGLayer) hidden also from the saved history; *Not there yet* no
  longer names the saved history, which is there. `Doc/ideas/Social.md`: what Saneroki is to decide (banner,
  smiley art, wrapping at full screen, a player's old `SaneUI_Chat` folder).

### Social: the messages stay in sight while the window fills the screen
Tests: 320 checks (Social). Not tried in the game; `/reload` is enough.
- Fixed (Saneroki, 2026-10-16): the bubbles went out of sight and came in again on the way to the full screen
  and back. `Window.lua` no longer gives the list to Core as the window's `content` (Core's `Edge.lua` fades
  that out and in); `Sized` puts the messages at the list's bottom on every frame of the way too (`Resettle`,
  no measuring: their wrapping stays), and `Placed` wraps them for the new width once the window stands.
  Core is unchanged: `content` stays an option for other windows.

### Social: a smiley with icons and emotes
Tests: 319 checks (Social). Not tried in the game. New files: restart the game.
- **Picker** (`src/Social/Picker.lua`, new, in the TOC after `Menu.lua`): a smiley button right of the line
  to write in, before the grip (`Layout.GRIP_ROOM` 18, `Layout.FACE` 24; the line now ends at
  `Layout.INPUT_RIGHT` = 44), shown by `Input` whenever the line is dressed (`Picker.Show`), hidden when it
  rests, closes or is given back; made with the line's plate (`Picker.Take`). Tooltip *Icons and emotes*.
- Its list is the game's menu: *Icons*, a row of the eight raid marks (a `CreateFrame` line whose initializer
  attaches eight `MenuTemplates.AttachBasicButton`s with the game's `UI-RaidTargetingIcon_<n>` and the name
  `RAID_TARGET_<n>` as tooltip, and returns the row's size); a click inserts `{rt<n>}` at the cursor and closes
  the menu. The game's chat draws no other pictures from what players write, and none in its public channels
  (`suppressRaidIcons`): while the line writes in a *Zone* channel (`GetChannelInfoFromIdentifier`) the row
  is a disabled line *No icons in the game's public channels*. Then *Emotes*: `Picker.EMOTES` (hello, wave,
  bye, thank, welcome, cheer, applaud, congratulate, laugh, dance, bow, hug) by their command in the game's
  language (`EMOTE<n>_CMD1`), done with `C_ChatInfo.PerformEmote` (or `DoEmote`) as the game's chat menu does.
- Art: the game has no smiley. `dev/tools/smiley-art` (new) draws `assets/SaneSocial-Smiley.png`;
  `dev/tools/art` has the kind `button` (24 x 24 units, 64 x 64 texels) and ships a picture under a name of
  its own (`src/Social/Art/smiley.blp`, the fifth field of `PICTURES`). Missing, the button shows the game's
  chat button art.
- Tests: the stand-in menu has `CreateFrame` lines and buttons with data and `SetEnabled`; checks for the
  smiley's place, the list in a public channel and elsewhere, a mark, an emote, the smiley going with the line.

### Full screen: the dropdown Classic windows; a full screen is square
Tests: 311 checks (Social), 148 checks (windows). Not tried in the game. `/reload` is enough.
- **Classic windows** (Saneroki, 2026-10-16; `Edge.lua`): a window's option `classic` (`{ text, show }` entries, or
  a function giving them) names the game's own windows it stands for. While the window stands full, the
  game's dropdown (`WowStyle1DropdownTemplate`, words fixed by `OverrideText`: *Classic windows*,
  `Edge.MENU_WIDTH` 180) sits `Edge.MENU_INSET` (10) from its top right corner, 50 levels above it; not on
  the way. One chosen: `edge:Fill(false)`, then `show()`. `Edge.MENU_ROOM` (48): where a full window's
  content should start to stand clear of it.
- **Social:** `ns.CLASSIC` (`Social.lua`): *Chat*: the switch *Chat window* off (`Shown(false)`, the window
  hidden, the game's chat back, an open options page follows) and a line saying `/sane social` or the
  switch brings it again; *Friends list*: `ToggleFriendsFrame(FRIEND_TAB_FRIENDS)`, as the game's key opens
  it, only if `FriendsFrame` is not shown (nothing if the game has no such function). Full, the list starts
  under the dropdown (`Top` in `Placed`; `Layout.ListHeight` takes the list's `top`).
- **Square full screen** (`Shape:Flatten(share)`): the full screen background's corners shrink as it comes
  (`edge.cover`) and its trim on the screen's edges slides out, so the full window is square whatever
  *Corner radius* and *Don't round corners on screen edges* say; only a window at rest is round. The two
  switches' tips say so.
- Ideas: `Doc/ideas/Windows.md` (*Classic windows*), `Navigation.md` (its full screen lists the native minimap
  and the native map and quest log), `Social.md`.

### One licence; data in Core; Actionbar Organizer gone
Tests: lint, all checks of every module.
- **One licence (Saneroki, 2026-10-16):** the project's `LICENSE` covers Core and every module with all their
  data (its point 1 now says so). Gone: `src/Tooltips/LICENSE` and the trainer data's own notice
  (`Abilities/Data/LICENSE-trainer-data.txt`); the Tooltips TOC's `X-License` is MIT like the others';
  `dev/build` gives every addon the project's `LICENSE.txt`. README, AGENTS.md, the agent map, the Tooltips
  and Abilities READMEs, `Data/Quests.lua`, `Data/Trainer.lua` and the public changelog no longer speak of
  a licence of a module's own.
- **Abilities:** no warning any more about Actionbar Organizer, the module's obsolete former addon (and
  its test check).
- **Navigation plan:** pin locations, spawns, patrol paths and the other map data are saved and handled by
  Core's database system, which Navigation only reads; route data loads on demand, by Core (Saneroki,
  2026-10-16). `Doc/ideas/Data.md` has *PatrolPaths* in the Spawns pack and a pack `SaneUI_Data_Routes`.
  Two open questions answered.

### Tooltips: a lighter Gold section
Tests: lint, 297 checks (Spellbook), 319 checks (Tooltips).
- **`CLAUDE.md`** is a local file now (`.gitignore`).
- **Tooltips:** `Addons/` (13 files) is gone, with the Loot, Guild and Inventory sections, *Crafted by* and
  *Disenchants into*, the Disenchant row, market odds and fair prices and the price chart (`Panel.lua`,
  `Pools.lua`). Lines other addons add still show, small, at a panel's end. The Gold section is the vendor's
  price and the AH profit by the prices you saw yourself (`Auction.lua`), with one advice line; with Alt the
  lowest price, the cut and the deposit (new check). `Data/Quests.lua` is the module's own data: its format is
  in its header, changes are made in it. Planned: auction prices from the Economy module's own database.
- **Spellbook** finds other bars' buttons only by the slot they carry; it warns only of its own former
  addon.
- `dev/tools/project-index` no longer indexes `CLAUDE.md` or `Scripts/`.

### Windows: round corners and a trim, opened by a click, a progress bar
Tests: 305 checks (Social), 141 checks (windows). Not tried in the game. New files: restart the game (a
`/reload` does not find them).
- **Round corners** (`src/Core/Shape.lua`, new): a window's plate is a fill with round corners and a bronze
  trim, `Shape.TRIM` (2) wide, that follows them. Each corner is a square piece cut by a circle mask twice
  its radius wide on the arc's centre (a mask is stretched whole and a texture takes three at most; a
  quarter picked by texture coordinates does not work, as Social's `Plate.lua` found); the rest of the fill
  is up to five strips that leave the corners out. All are painted alike (the gradient's colours where each
  lies, or the tile's coordinates from the top left), so they meet without a seam. The trim lies over the
  fill: strips along the sides, and in a round corner an arc, the corner's piece cut by the circle and by a
  hole mask the trim's width smaller. `shape:Look`, `Fit`, `Base`, `SetAlpha`, `SetShown`, `shape.radii`.
- **The switches** (`Shape.Options`, `Shape.DEFAULTS`, `Shape.KEYS`): *Corner radius* (`corners`, 0 to
  100 % of half the window's shorter side at rest, 10) and *Don't round corners on screen edges*
  (`squareEdges`, on). With it on a corner's radius is no larger than its gaps to the screen's edges:
  docked, the corners there are square; on the way to an edge a corner flattens out, and a side's trim
  slides out of the screen in its last two units. Off: every corner is round (at 100 % a square window is
  a circle).
- **Masks** `src/Core/Art/circle.blp`, `circle-hole.blp` (256 × 256, DXT5 with mipmaps): a white disc, and a
  white square with the disc taken out, drawn by code (`dev/tools/shape-art`, new). Without them (a game
  started before they were there) every corner is square.
- **Skin** (`Skin.lua`) is a Shape: the dark gradient as before, a bronze trim and round corners (was the
  game's tooltip border on `BackdropTemplate`, pushed out of the screen on docked sides). `skin:Dock(zone)`
  is gone: `skin:Rest()` (placed: the corners are measured on this size), `skin:Fit(...)`; it fits itself
  when its size changes. `Window.New`'s `corners` names the settings it is rounded by (else `edge`'s table).
- **Edge**: the full screen background is a Shape in the window (was one texture): corners measured on the
  window at rest, the tile repeated at its size (`Edge.TEXTURES` have `size`), the trim bronze. `edge.cover`
  says how far it has come (the fill's alpha is that times the opacity, the trim's that alone); a skin of
  the window fades out as it comes; while full a frame of its own refits it to a new screen size. The
  section *Expand window* has the two corner switches under *Can expand to fullscreen* (`Edge.DEFAULTS`,
  `Edge.KEYS`).
- **Expand**: `click = true`: a click opens it and pins it (it stays when the mouse leaves), a click again
  lets it go (with hover: it closes once the mouse has left); a press and a release more than
  `Expand.SLIP` (4) apart are a drag. `hover = false`: the mouse's coming does nothing. `expand:Pin()`,
  `expand.pinned`; `expand:Close()` unpins.
- **Bar** (`src/Core/Bar.lua`, new): a progress bar for any module, with a second fill after the first; a
  gain eases in, a loss is there at once; `count` gets the value on its way, for a number that counts up.
  `bar:SetSize(width, height)` moves as the kind of motion says. Nothing runs while it stands still.
- **`/sane window`** (`Demo.lua`): a window to try it all; a click keeps it open.
- **Social**: the section *Expand window* is first in the tab *Appearance* again, above *Messages* (asked
  for on 2026-10-15; a review had put it after *Animations*), now with the corner switches; a change of one
  goes to `Window.Expand` (`edge:Update`).
- Docs: Core's and Social's READMEs, `Doc/guides/gui-development.md` (the skin), `Doc/guides/images.md`
  (masks drawn by code), `Doc/agent/core.md`.

### Chat is Social
- The Chat module is renamed **Social** (`Doc/ideas/Social.md`): folder `src/Social`, addon
  `SaneUI_Social` (`SaneUI_Social.toc`), its first file `Social.lua`, module and title *Social* (addon
  list, options page, the window's bar). `/sane social`, and `/sane chat` as its second word.
- Core (`Saved.lua`): what was kept under a module's old name (`RENAMED`, `Chat = "Social"`) moves to its
  new one once at load, wherever a module's name is a key: `SaneUIDB.modules`, `perCharacter`, `account`,
  each profile, and the character's `SaneUICharDB.settings`. What the new name already has stays.
- `dev/build` removes the old `SaneUI_Chat` folder from the game's AddOns folder; a player's old copy is
  still to be handled (open).
- Tests: `dev/tests/chat.lua` is `dev/tests/social.lua`; Core checks the move of the saved settings.
- Docs: `Doc/agent/chat.md` is `Doc/agent/social.md`; READMEs, AGENTS.md, CLAUDE.md's example, the
  agent docs and `dev/tools/art` (the banner ships in `src/Social`) name Social. The banner drawing still
  reads *Sane Chat*.

### Navigation: our own data
- `Doc/ideas/Navigation.md`, new section *Our own data* (Saneroki, 2026-10-16): the module's data is in its
  own data files and `Art/`, and the map system works fully on its own. No code yet.

### Navigation: one pin per thing
- `Doc/ideas/Navigation.md`, new section *One pin per thing* (Saneroki, 2026-10-16): one pin per thing and
  place, by a key per pin kind and a distance per kind in world yards; one NPC with several roles is one
  pin; live game pins win over database pins of the same key; a test checks no duplicates ship. No code
  yet.

### Navigation: every kind of pin
- `Doc/ideas/Navigation.md`: Saneroki's decision on more pins: rares and where they spawn, quest and guide
  pins. New sections: a pin catalogue for the pin filter, dungeon maps and a map selector. No code yet.

### Ideas: one toggle, Click required to expand window
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): the setting is one toggle, *Click required to expand
  window* (ticked: a click is required; not ticked: hover is enough), in Core's *Hotcorners* for all
  modules and in each module for its own windows; changing Core's sets every module's to the same. The
  open question of a third state ("as Core's") is gone.

### Ideas: Expand on hover in Core's Hotcorners and in each module
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): *Expand on hover* is set in a section *Hotcorners* of Core's
  settings for the windows of all modules, and in each module's settings for its own windows, overriding
  Core's; each module handles hover and click only for its own windows, and the tooltips say so. Open:
  how a module's setting follows Core's until overridden (proposed: a dropdown with *Use global setting*,
  like *Animation type*), and the page of *Hotcorners*.

### Ideas: windows in Edit Mode's layouts; chat views as windows and tabs
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): Edit Mode's layouts keep the size and place of every Sane UI
  window, each layout its own, switching with Blizzard's frames; moves count as layout changes until
  *Save*, and Revert puts the windows on their default position, all as Edit Mode does it. Notes for
  building it (our places kept per layout in Sane UI's settings, Blizzard's events and hooks, enabling
  Blizzard's *Save* button, a dialog with *Reset To Default Position*). A window still saved in a removed
  quarter zone needs nothing (Core ignores a zone it does not know).
- `Doc/ideas/Social.md`: a chat view can be a window of its own and a tab of the small Social window, like
  the game's chat windows. The old `SaneUI_Chat` folder is deleted (gone from the game, `src/` and
  `BUILD/`); Sane UI is not given out yet, so no player's old copy is to be handled.

### Ideas: expand by a left click; Expand on hover
- `Doc/ideas/Windows.md` (Saneroki, 2026-10-16): a docked window fills the screen only on a left click on its
  trigger area, not when the mouse merely reaches it; right and middle click stay free for later functions.
  A checkbox *Expand on hover* in the section *Expand window* (off by default, on for a window designed for
  hover) brings back today's expanding by the mouse alone. Notes for `Edge.lua` (the strip also takes the
  left button). `Doc/ideas/Navigation.md` points to it. No code yet.

### Ideas: the screen layout of docked windows; Chat becomes Social
- `Doc/ideas/Windows.md` (2026-10-16): Saneroki's plan for how the windows share the screen: only eight
  places (three at the top, one on each side, three at the bottom; Core's quarter zones go), full screen
  only from a place where a window is docked, the default window of each place (top left party and raid,
  tentative; top middle journal and progress; top right Navigation; bottom left Social; bottom middle
  Spellbook with action bars, talents and legacy; bottom right character sheet and bags; left and right to
  be decided), and moving and sizing only while Blizzard's Edit Mode is open. No code yet.
- `Doc/ideas/Social.md`: the Chat module is to be renamed Social and hold chat, more chat views with their
  own channel filters, guild, group finder and friends list. `Doc/ideas/Navigation.md` points to the plan.

### Navigation: feasibility, full screen, pins and routes
- `Doc/ideas/Navigation.md`: Saneroki's new decisions (quest log on the left in full screen; separate zoom and
  position per view; following the player; map selector, pin filter and three views on a top bar; own pin
  database, herb and ore icons; Blizzard's map pin with a route drawn as a pulsing
  golden line) and a feasibility analysis against Blizzard's code: all doable, north-up
  only, live minimap dots in the small view only, no terrain in dungeons, walking data to decide. No code
  yet.

### Navigation: planning notes
- `Doc/ideas/Navigation.md` (2026-10-16): what Saneroki has decided so far for the Navigation module, which
  replaces minimap, world map and quest log with one Core-docked window (top right, expands to the whole
  screen like Chat) that renders one map, zoomed by the wheel from minimap to world.
  Earlier notes from `Doc/ideas/Maps.txt` are folded in; open questions listed. No code yet.

### Tooltips: comparisons at absolute places; Press ALT for +N more
Tests: 347 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Comparisons still flickered.** The second panel hung on the first only while the first was shown;
  the game hides and refills the first several times a second, and a placement in such a moment put
  the second beside the main panel, where the first stands. Relative points also took over any wobble of
  what they hung on. `Native.lua` now pins each comparison panel to an absolute place on `UIParent`
  (`Pin`, only when the place changes; `Release` and `Stay` forget the pin), worked out by `Place` from
  steady values kept per main tooltip (`layouts`): the main panel's left, right and top, taken for a new
  thing (owner and item, `Thing`) and afterwards only once it has stood still for `STILL` (0.12 s)
  in a new place (`Native.Follow`, called every frame from the main panel's `Watch` in `Tooltips.lua`);
  the side (`Side`), once per thing; each comparison's slot width, the widest its panel has been for the
  thing. Gap 12, tops in a line.
- `TEXT.ALT_MORE` (*Press ALT for +%d more*) where Alt shows more: the Quest section, the Loot
  section's sources, the Guild section (under the names, which no longer carry the count).

### Tooltips: comparisons in one place, a gap apart; Questlog over the quests' standing
Tests: 342 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Flicker of comparisons:** their panels copied the game's points (`Beside`), and the game re-anchors
  its two comparisons several times a second, now the first on the second, now the other way round; a
  panel that could not hang on the other's (it would hang on itself), or whose other panel was hidden for
  a refresh, fell back to its own tooltip's corner, elsewhere by the size the game's tooltip has. Two
  places in turn. `Native.lua` now places the `shoppingTooltips` of `GameTooltip` and `ItemRefTooltip`
  itself (`Compare`): the first on the main panel, the second on the first, `COMPARE_GAP` (12) apart,
  tops in a line, on a side decided once per owner and item (`Side`: right where they fit, else left,
  else the roomier; the game's side, `GameSide`, where nothing can be measured).
- `Kinds/Item.lua`: *Starts* and *Needed for* have *Questlog* (`TEXT.QUESTLOG`) at the right.
- The chart's words have no dark plates (`Pools.ChartText`); they stay on their own frame over the lines.

### Tooltips: a Quest section with where you stand with each quest; the chart's words readable
Tests: 338 checks (Tooltips). Not tried in the game. `/reload` is enough.
- `Quests.lua`: `Quests.Item` lists the quest the item starts, then every quest for you that asks for
  it, by where you stand (`Standing`: active, offer, later, done; nil for another class, race or side, a
  closed quest, one no longer in the game; `Closed`), each once; entries carry `state`.
- `Kinds/Item.lua`: the quests under the caption *Quest* (`TEXT.QUEST`), *Starts* and *Needed for* small
  over them; each row: an icon (?, !, none, tick), the name in its standing's colour, its level small
  after it, *In log 1/4* / *Available* / *Not yet* / *Done* at the right; three not in your log without
  Alt, then *+N more*. A quest reward stays a source under *Loot*.
- `Kinds/Unit.lua`: the caption *Quest* over a creature's quests (put up by the first quest name).
- The chart's words (`Pools.ChartText`) stand on a frame of their own over the panel (its level two
  above), the ones inside the chart on a dark plate.

### Tooltips: gold for one item, the vendor price everywhere, captions Loot and Inventory
Tests: 332 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Gold** (`Kinds/Gold.lua`) works for one of the item: `Work(id, vendor, bound, facts, tooltip)`, `Sale`
  without a count; the vendor's price is `Gold.VendorEach` (`GetItemInfo`'s sell price, asked for when the
  game lacks the item; the price line only stands in meanwhile), on every item, *Can't be sold* (`NO_VENDOR`)
  at 0. A comparison's vendor row too. `TEXT.EACH` gone.
- The advice row has no coin (`PICTURE.coin` gone); the chart no dark ground.
- `Kinds/Item.lua`: caption *Loot* (`TEXT.LOOT`, was *Gear*; `LootSection`), caption *Inventory* over *You
  have*; the level it needs and the other requirements at the right, one under the other (the kind and
  slot at the left of the first).

### Tooltips: gold advice; item quests
Tests: 328 checks (Tooltips). Not tried in the game. New files: **restart the game** (a `/reload` does not
read them).
- **Item panel** (`Kinds/Item.lua`): requirements (class, races, skill, reputation, spell:
  `PATTERN.REQUIRES`) in the header under the level it needs; the game's lines (`Read.Rest("own")`), the
  durability bar, the item's quests, then Gear, Professions, Guild under captions, *You have*, other
  addons' lines (`Read.Rest("added")`), Gold. A comparison: its vendor price only. Alt: more in each.
- **Gold** (`Kinds/Gold.lua`): Vendor, Disenchant (materials × chance × average count × price, less 5%),
  AH profit (list price less 5% and the expected lost deposit: 60% of the vendor price for a 48 h auction,
  by the odds of a sale), a chart row, and the advice (`ah`, `de`, `vendor`; `buy` for a tooltip filled with
  `GetItemKey`), the better way needing 5% more; Alt: prices, listed, fees, source. Replaces the *Auction*
  row; `Auction.lua` is the last price source.
- **Panel:** a `chart` row kind (`Model` key `points`), drawn with `Pools.Segment` (Line objects); a `coin`
  picture.
- **Quests:** the quest data has `ITEMS` (quests asking for an item; the quest it starts) and `STARTERS`
  (creatures dropping a quest-starting item, with chance). `Quests.Item`,
  `Quests.ItemName`, `Quests.Level`, `Quests.Heading` (a quest's name with its level, coloured); `Offered` can
  take a trivial quest (an item's). `Kinds/Unit.lua`: every quest name with its level (by the game's line's
  quest id), a creature's quest-starting drops (the !, the item, its chance).

### Tooltips: drop chances on a creature's loot objectives
Tests: 296 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Data:** each drop has its chance, at most 100. A `DROPS` entry is `quest:item:objective[:chance]` now.
- **Shown:** `Quests.Of` gives a loot entry its chance (`extra`); `Kinds/Unit.lua` puts it after the item's
  name as the row's `label` (`TEXT.CHANCE`, *33%*), on the game's own objective line too (found by its
  words), and a drop the database knows has a sack even when its words name the creature.
- **Panel:** a row's `label` is drawn also when the row has a right text (`WordsAndAfter`).

### Spellbook: a reservation dragged off the bars is removed
- A reservation picked up from a button and let go where there is no button is taken off (`Drag.Stop`:
  `Engine.Clear` of the slot it came from), as the game does with a real action. Was: it stayed.
  Not tried in the game. Tests: 297 checks (Spellbook).

### Spellbook: a carried spell finds every action button
- **Dropping a grey spell missed some of a bar addon's buttons.** The drag knew buttons by a fixed list of
  names and slots, and trusted a hidden button to report its place. New `Buttons.lua`: every action
  button is found by what it is (a Button or CheckButton that carries an action slot, `EnumerateFrames`
  when a drag starts; by name where that is missing), so bars 9 and 10, paged bars and other bar addons
  count too; a hidden button's place is worked out from its first anchor when `GetRect` gives none
  (`Buttons.Rect`); shown buttons are tried before hidden ones; the gold frame is placed by that place.
  The bar ghosts use the same list (looked for again 5 seconds after each loading screen).
- Native drag with a stand-in macro on the game's cursor was offered and declined (it costs a character
  macro per reserved spell).
- Tests: the stand-in client walks its frames and knows a frame's kind. 297 checks (Spellbook).

### Spellbook: moving a reservation from button to button
- **A reservation's grey icon on the bar can be dragged to another button**, like a real action: where the
  game allows that (bars unlocked, or the pick-up key held). On a reserved button the two change places,
  on a real action that action goes onto the cursor; let go elsewhere and nothing changes. New
  `Engine.Move(from, to)` and `Drag.StartMove(slot)`. Hooks after the button's `OnDragStart`, `OnDragStop`,
  `OnShow` and `OnHide`. Where the bar hides the empty button, the grey icon takes the mouse itself (its
  tooltip and the drag) and carries its slot as `.action` for the drop; over a shown button it takes none.
- Not tried in the game. Tests: 295 checks (Spellbook).

### Spellbook: hidden empty buttons, and the order in a tab
- **A grey spell could not be dropped on an empty button its bar hides** (a bar addon set to hide empty
  buttons): a bar shows its empty buttons only while the game's own cursor carries something. The drag now
  also knows that addon's buttons of every slot the module looks after, and a hidden one counts when the
  mouse is inside its place (`Drag.lua`, `Under`: `GetRect`, the cursor in the button's scale), on a bar
  that is visible. Shown buttons are still asked `IsMouseOver`.
- **The grey icon on the bars hangs on the button's bar** in the button's place (was: on the button), so a
  reservation also shows on a hidden empty button; it follows the button to another bar out of combat.
- **Order in a tab:** the spells you have first (the game's order), then those you can learn now, then the
  rest by level, name and rank. `Layout.Order` replaces `Layout.Merge` (which filed new spells by name
  among the learned ones); `Layout.Compare` is gone; `Layout.ByLevel` puts what you can learn now first.
- Not tried in the game. Tests: 285 checks (Spellbook).

### Spellbook: reserving on a bar addon's bars
- **Dragging a grey spell onto a bar addon's action bar did nothing.** That addon makes buttons of its own
  for every bar, keeps their slot only in the secure attribute `action`, and hides the game's buttons. The
  drag read only the field `button.action` and scanned the game's (hidden) buttons, so it found no slot.
  New `ns.ActionOf(frame)`: the attribute first, then the field, inside a `pcall`; used by the drag,
  `ns.SlotOf` and `ns.Bar1Offset` (which reads that addon's first button when the game's is hidden). The
  grey icons are now put on that addon's buttons of every slot the module looks after, not only on those
  of bars 9 and 10. Not tried in the game.

### Review: settings texts, bugs, performance and documentation across every module
From a full QA, bug-hunt, performance and reasoning pass over the whole project (review agents per module and
lens, each finding checked against the code). Not tried in the game. Tests: 194 checks (Core), 281 (Spellbook),
293 (Tooltips), 304 (Chat), 62 (Sync), 105 (windows). The pass was cut short before Core's options pages, the
Tooltips module and the structural Spellbook performance items were done: see the orchestrator's report.
- **Settings texts, every module:** every switch, slider and dropdown has a tooltip that says in one or two
  sentences what it does and what "Off" means (the Spellbook's *Say in chat when a reserved button is filled*
  had none). Labels say what they are: Chat's *Fade in*, *Fade out*, *Slide up* (were "... speed" on a yes/no),
  *Fade-in time*, *Fade-out time*, *Slide time*, *Faded messages stay visible* (was *Opacity*), *All animations
  and fades*, *Show the game's chat too* (was *Show native chat*), *Bubble opacity* (100 solid; was
  *Transparency*, 0 solid, the opposite of every other opacity slider; a kept value is turned round once,
  `bubbleOpacity`), *Bubble colour*, *Solid colour*; Spellbook's *Show unlearned spells* (was *Show hidden
  spells*, which read as the opposite of the game's *Hide Passives* beside it), *Move and resize the spellbook*,
  *Show reservations on the action bars*, *Sane UI lays out the spellbook pages*; the Expand window section's
  tips; Sync's part tips name only what a part holds. British spelling throughout.
- **Spellbook, options:** the master switch *Sane UI lays out the spellbook pages* is first, under a header
  *Spellbook*, and the four switches that do nothing without it are under it, greyed out while it is off; the
  action bar switches under *Action bars*. Flipping it offers the /reload in the game's dialog (`Core.AskReload`)
  besides the chat line. The in-book checkbox has a tooltip. The spellbook's menu has the three switches about
  the book too, then the bar switches; its *Show unlearned spells* is greyed out while the pages are the game's,
  with the reason in its tooltip (`B.Why`). *Delete* of a layout asks first. A grey entry's click hints are the
  game's green instruction lines, not grey.
- **Spellbook, bugs:** a saved layout made in a fight recorded every hidden slot as "other", and *Load* then
  never restored those buttons: `RealEntry` gives nil for a hidden slot, and `Presets.Save` refuses in a fight.
  `Presets.List` passes over a hand-edited key that is no name (it broke the whole settings menu). A
  reservation's or layout's icon of another kind is left out (`ns.Texture`), and `S.Icon` never hands one on.
- **Spellbook, performance:** a resize drag redraws the pages ten times a second, not every frame, and once
  more at the end; `I.Set` makes no tables per entry, reads *Show all spell ranks* once per build, and keeps an
  entry's status words; `ScanBook` makes no table per spellbook item; a drag asks the mouse's foci before
  scanning 96 buttons and moves the gold frame only when the button under the mouse changes.
- **Chat:** a switch *Chat window* on the General tab shows or hides the window (`/sane chat` flips it; a kept
  `store.hidden` is moved into it once); the ticks of the list on the chat's name are a setting (`mute`, moved
  from `store.mute` once), so profiles and a character's own settings carry them; the four groups with a switch
  have the same words on the page and in the list; *Messages kept* starts at 10 (0 did what unticking does);
  each game channel's tip says "in a city" only for Trade and Services; the Appearance tab reads Messages,
  Animations, Expand window; the Expand window's *Animation type* is greyed out while *All animations and
  fades* is off (`Config.Free` takes a list of parents); a tick flipped in the list refreshes the open options
  page. The TOC's description and the README say the game's chat stays next to the window (the default).
- **Chat, performance:** the window lays nothing out while it fills the screen or goes back (`Sized` returns
  while `edge.away`; `Placed` does the work once at the end); a message's fading out walks only the messages
  that are due, with one fixed timer function (was: every message twice and a new closure per timer); the
  history is restored in O(n), not O(n^2).
- **Core:** a module step `OnLogout`, run before Profiles puts the account's settings back, so a module reads
  its own settings at logout (Chat's history saving still uses PLAYER_LOGOUT: to move). `Core.On` notes an
  event this client does not know (log and `/sane errors`). The game's error window is hooked at Core's
  `ADDON_LOADED`, so an error while a module's files are read is noted. `/sane errors clear` tells a recurring
  problem again; `/sane` marks a module that failed to start. `Core.AskReload(names)`: the game's dialog
  offering a /reload. `module.Safe` builds its label only on a failure; `module.Fire` makes each listener's
  label once; `Core.errors` keeps a text's first line (the log keeps the trace). `/sane window` builds into
  locals and publishes only on success; `/sane window reset` typed first in a session resets; the window is
  `SaneUIDemoWindow` and Esc hides it.
- **Windows:** the skin stands one frame level under its window, so the window's own regions (the demo's text,
  Edge's full-screen background) draw over its fill, not under it. Esc brings a full window back
  (`SaneUIEdgeEscape` in `UISpecialFrames`). Expand's size motion stops while Edge owns the size.
- **Sync:** the Graphics part takes *Texture Detail* again ("resolution" is out of `NEVER`; the screen's
  resolution is `gx*`); `characterFrameCollapsed` left the interface part's list (NEVER dropped it anyway); a
  channel's kind is asked of `C_ChatInfo.GetChannelInfoFromIdentifier` first, `EnumerateServerChannels` second, and what
  was kept stays when neither can tell (every joined channel counted as the player's own without the latter);
  the /reload dialog is offered once per giving, not once per session; `PLAYER_REGEN_ENABLED` only settles a
  waiting Edit Mode layout; the console list is resolved into every part's names in one pass and let go
  (`Resolve`, `part.has`).
- **Tooltips data:** quest 8315 (*The Calling*) has its next quest 8316 again; `Quests.lua` regenerated.
- **Dev:** the stand-in client loads every TOC line (Lua and XML with `Script`/`Include`) and errors on one it
  cannot, as the lint and the game accept them; `dev/build` prints its whole usage; `Scripts/addon-categories`
  repairs an orphan group for every addon.
- **Documentation:** the guides say what the code does on purpose (Sync's `VARIABLES_LOADED` and Edit Mode
  part, `GetFont`/`SetFont` to change a size, Core's skin and bronze border, Chat's fade `OnUpdate`, saved data
  checked by shape, the Settings API, globals the client demands, `Core.Later`, `GiveBack`, tables of
  functions, the checklist for a part that stays, small captions, the shipped pictures, the NineSliceLayouts
  path); the agent notes, the root README, AGENTS.md, CLAUDE.md's folder rows and the module READMEs no
  longer say "Settings module", "three addons", "six folders", and carry the current test counts.

### Review: Spellbook, Tooltips and Chat bugs, hardening, performance
From a full review of the three modules. Not tried in the game. Tests: 280 checks (Spellbook), 293 (Tooltips), 304 (Chat).
- **Spellbook, bug:** made small or large without a kept size of its own, the spellbook kept the height a kept
  size of the other gave it (the game sets only the book's width), stood out of the window and laid its pages
  out for that height. `Window.lua` fits the book to the window whenever it looks after it (at the game's own
  sizes that is the game's 1612 x 702 / 806 x 702).
- **Spellbook, performance:** Home was filled on every update while the spellbook was closed (its pane stays
  shown in the hidden book): `IsVisible`, not `IsShown`. It is filled when the book opens.
- **Spellbook, bug:** a rank named with a numeral (*Instant Poison II*, rank line *Rank 2*) is the trainer's
  *Instant Poison*. `ScanBook` knows it by both names (`D.BaseName`), the book's entries are grouped by the
  trainer's name (they fold with their grey ranks), and a rank the game pushes finds the button reserved
  for it by that name (`UndoPushes`). Was: a grey duplicate, and the new rank moved off its own button.
- **Spellbook, hardening:** reservations with a slot that is none (not 1 to 180, not whole) or an ID or name of
  another kind, a layout's slots likewise, and a kept window size or place that is no numbers are left out
  (the game's action functions fail on them, in every update). Giving the game's size back while the talents
  are shown leaves the window to the game's next tab change.
- **Tooltips, bug:** with *Show the icon* off (or no icon) an item's and a unit's level were gone with the
  plaque: they stand right of the name now. A line of the game's data without text (it adds no line, yet gets
  the index of the last one: `TooltipDataHandler`) took that line's type: the first line of data marks it.
- **Tooltips, inspect:** an answer read no longer clears an inspection another addon asked for since
  (`ClearInspectPlayer` only when nobody called `NotifyInspect` after us); talents kept without an item level
  are asked for again (paced as before) instead of five minutes without one.
- **Tooltips:** a spell's school is not kept before its description came; of several auction rows of one item
  (its kinds) the lowest price counts, also over rows that come later in the same list; a failing live value
  (health, power, target, buffs: `Live.Start`, `Live.Update`) is noted once and switches the live values off,
  not the module; a boolean mouse switch of version 2 is put right in every copy (`Profiles.Copies`).
- **Tooltips, performance:** another addon's unseen tooltip (owned, placed nowhere) is only made invisible on a
  fill (`Native.Veil`), not part by part (`FadeParts`) and given back each frame.
- **Chat, bug:** the edit box's insets and its label's height are read plain (`Insets`): a name the game hides
  would make them hidden, and growing the line stood the module down. Scrolled up, the oldest messages leaving
  a full log moved the reader on by their rows (the list keeps its offset from its top): `ScrollToOffset`
  back by their height. The button on the chat's name of a line at rest (IM style) took clicks, unseen.
- **Chat:** raid marks (`{skull}`) are their icons (`C_ChatInfo.ReplaceIconAndGroupExpressions`, as the game's
  chat, with arg17 and the group's expansion); a letterbox's message (arg16) is not shown, as in the game's
  chat. The game's channels are joined or left again when chat's lockdown ends (`ADDON_RESTRICTION_STATE_CHANGED`).
- **Chat, history:** a message with a Battle.net friend's name or link is not saved (it stands for the friend in
  that session only); a player's link is saved without its line number. `Log.Restore` mends a message without
  its time, with a tie or class that is none (`Bubble` would fail on them while drawing).
- **Chat, resilience and performance:** `Native.Show` gives each frame back by itself; a measured message's
  height is known without a guard (`Bubble.Known`: every message made the list ask for all heights, each in an
  `xpcall`); `Untimed` makes no closure per printed line; the speakers' caches count each by itself (the
  group's changes no longer emptied the classes too).
- **Tests:** the stub's spellbook items have their rank line (`subName`); the tooltip stub can give a line of
  data without text (`nothing`); the chat stub's list has a scroll offset, and the game's channel functions
  from the start.

### Review: Core and Sync bugs, hardening, performance
From a full review of Core, Settings and Sync. Not tried in the game. Tests: 194 checks (Core), 62 (Sync), 98 (windows).
- **Bug, Profiles:** a character's line that names *Empty* (an older version moved a saved profile called so,
  or a hand edit) counted as a profile with nothing saved: every change of the session was thrown away at the
  logout. `Wanted` now takes Empty as no profile. A saved profile called Empty or SaneUI Defaults whose
  *(old)* name is taken is moved to the next free one (*(old 2)*, ...) instead of being lost.
- **Bug, docked windows:** `Dock.Anchor` hung a window on the screen's lower left corner, at offsets worked
  out from the screen's size then: after a change of the UI scale or of the game window's size it stood away
  from its edge (and its edge strip with it). It now hangs on the screen's point of its zone (`TOPRIGHT` on
  `TOPRIGHT`, ...). A kept size larger than the screen is now is cut to the screen's; a window without a
  smallest size no longer breaks `SetResizeBounds`.
- **Edge:** a full window gives back clicks and the mouse's coming apart (`SetMouseClickEnabled`,
  `SetMouseMotionEnabled`), not as one. **Motion:** a clock's last `OnUpdate` at 1 no longer ends the motion
  twice (`OnFinished` does): Chat's layout after filling the screen ran twice.
- **Core:** a module whose `OnLoad` failed is not given `OnLogin` (it would fail on what was not made).
  `NoteError` copes with an error text the game hides (secret: it could not be compared nor saved) and
  counts in place; `/sane errors` skips saved entries it cannot read.
- **Sync, taint:** the game answers a new Edit Mode layout (`EDIT_MODE_LAYOUTS_UPDATED`) and a new chat colour
  (`UPDATE_CHAT_COLOR`) with events that run inside our call (synchronous), so its manager and chat frames ran
  under Sane UI's taint until a `/reload`. The Edit Mode part (`reload`, also when a waiting layout is set
  later: `Sync.AskReload`) and a chat colour alone now offer the reload, as the chat windows did. The dialog
  says the game "takes them over fully" after it.
- **Sync, timing:** given only once the game has its stored settings (`C_CVar.AreCVarsLoaded`, else on
  `VARIABLES_LOADED`): on a slow login the server's would have overwritten them, and the logout kept the old.
- **Sync, resilience:** when the game cannot list its CVars (`ConsoleGetAllCommands` failed or gone), the CVar
  parts keep what was saved instead of saving nothing over it; the list is asked again later. A flag part
  whose getter does not answer keeps what was saved (was saved as off).
- **Sync:** the chat channels of your own are joined before the chat windows are given (a join puts the channel
  into the first window, which the windows' part then puts right; it spread to every character). Edit Mode
  looks again on `PLAYER_SPECIALIZATION_CHANGED` of the player only. Building the CVar parts' lists makes no
  table nor string per CVar.
- **Settings, CVar list:** what the game said of a change ("The game keeps it at ...") stays while that CVar is
  shown; the redraw that follows the game's own `CVAR_UPDATE` wiped it a tenth of a second later.

### Windows: Expand window; the full window takes the mouse; a corner's square
Not tried in the game. Tests: 94 checks (windows), 294 checks (Chat).
- **Core, `Edge.lua`:** full (and on the way), a window is raised above the rest of its strata and takes the
  mouse and its wheel (`EnableMouse`, `EnableMouseWheel`, as the game's map does while locked): nothing behind
  it is clicked, nor the camera turned or zoomed; its layer, level and mouse are as before once it is back.
  Its background is half opaque at first (was solid) and may be one of Blizzard's tiles (`Edge.TEXTURES`:
  Solid black, Marble, Rock, Slate, Iron, Night, named as Chat's bubbles name them; tiled with
  `SetHorizTile`/`SetVertTile`). Docked in a corner, only a square of `Edge.CORNER` (4) of the screen's pixels
  in that corner sets it off (was a strip along both its edges); along an edge, the strip as before.
- **Core, the section *Expand window*** (`Edge.Options(list, at, tab)`): *Can expand to fullscreen* (on; off:
  no strips), *Animation type* (moved here from Chat's *Animations*), *Background opacity* (0 to 100 %, 50),
  *Background texture* (Solid black). `Window.New`'s `edge` takes the module's settings (`edge = ns.options`;
  `true`: `Edge.DEFAULTS`); a change of one (`Edge.KEYS`): `edge:Update()`, seen at once, also while full;
  it does not make the edge quiet.
- **Chat:** the section at the top of the tab *Appearance* (`Edge.Options(OPTIONS, 1, LOOK)`); `Window.Expand`.
  *Enable all Animations and Fades* off still makes it fill the screen at once.

### Profiles: Empty; SaneUI Defaults only Sane UI's own settings
Not tried in the game. Tests: 190 checks (Core).
- **Empty** (`Profiles.EMPTY`): no profile, as a profile in the lists (first, chosen at first; was *None* on a
  character's line). The settings as they are kept, the account's (or each character's own), loaded at every
  login and saved at every logout and `/reload`, as before. Loaded, it puts those back in use where a profile is
  in use (`Kept`); duplicated, it copies them (`KeptProfile`). Fixed with SaneUI Defaults: not saved over,
  renamed or deleted; on a character's line both checkboxes ticked and switched off. A saved profile called
  Empty is moved to *Empty (old)*.
- **SaneUI Defaults** leaves out the game's settings that Sync keeps (`GameSettings`): loading it (or duplicating
  it) changes only Sane UI's modules and general switches; with *Load at login* Sync's settings stay where they
  were (`Wanted`).
- `Home(name)` (where a module's settings come from without a profile) split out of `Wanted`.

### Sync: the Edit Mode layout is kept again
Not tried in the game. Tests: 57 checks (Sync).
- **Bug:** every login set the Edit Mode layout Modern, whichever one the player had chosen. The layout in use
  was read at the logout (`C_EditMode.GetLayouts().activeLayout`), when the game no longer says it: it said
  Modern (seen in the saved settings: Modern kept at a logout a minute after the game's own cache had the
  player's layout), and the next login gave that back.
- **Now** (`Sync/Parts.lua`): read from Edit Mode's manager (`layoutInfo`) while the character is in the world
  (`PLAYER_ENTERING_WORLD` to `PLAYER_LEAVING_WORLD`), a frame after it took new layouts and when the settings
  are taken; at the logout the last one seen. A layout that cannot be set yet (the manager without layouts
  early in a login, Edit Mode open, a fight) waits and is set as soon as it can (`EDIT_MODE_LAYOUTS_UPDATED`,
  `EditMode.Exit`, `PLAYER_REGEN_ENABLED`); meanwhile it is the one taken. Profiles save and load it the same way.
- **Tests:** the model's manager has `layoutInfo` and fires its event at once on `SetActiveLayout`, and says
  Modern after the logout, as the game; checks for waiting, Edit Mode open, a fight, a profile.

### Chat: no white ghost of a message in the window's corner
Seen in the game (a screenshot): a white copy of a message stood at the window's upper left, its second line
centred. It was the text that measures the messages (`Bubble.Ruler`), hidden only by its own alpha: a
FontString takes its alpha anew from its font object when that changes (the text size). Both rulers (the
messages', the line's in `Input.lua`) are now made by `ns.Ruler`: inside a frame of their own at alpha 0.
Tests: Chat 295 checks.

### Chat: an older history sorted anew, so the ticks hide it too
Seen in the game: loot, skill ups and a channel's joins and leaves from the saved history stayed in the window with
their ticks off; they had been saved as prints. Tests: Chat 289 checks.
- `Log.Restore(saved, version)`: a history without `historyVersion` = `Log.HISTORY` (2) has its prints sorted
  anew (`Guess`: a channel's link a notice, white a print, else by the kinds of chat of that very colour, the
  system's first) and its duplicate guild message of the day once. `History` saves `historyVersion`.
- `Group(kind, event, text)`: a line with neither kind nor event but a channel's link is a channel's notice.

### Chat: loot, skill ups and channel joins in their own groups in every client
Seen in the game (the saved history): this client's chat writes loot, skill and channel join lines without the
chat type number, so they went with *Addon messages* and their ticks did nothing. Tests: Chat 285 checks.
- `Log.Before`/`Log.After`: a filter (`ChatFrameUtil.AddMessageEventFilter`, or `ChatFrame_AddMessageEventFilter`)
  on every chat event we do not read (`Log.Unread`: from `ChatTypeInfo` and `ChatTypeGroup`) notes the window
  and event right before that window writes the line; each chat window's `OnEvent` (hooked) clears it. It
  returns `false` only: nothing is filtered or changed. `Group(kind, event)` takes the event first.
- An unknown chat type number is learned anew once (`learned`); the game's timestamp is taken off every line
  (`Untimed`, also the Classic `GetChatTimestampFormat`/`BetterDate`).
- The guild's message of the day was there twice (the game's line and ours): `Log.Motd` takes the game's line
  of the same moment as the guild's, and `Log.Line` leaves out one written after ours.

### Chat: a channel's tick hides all its messages
Tests: Chat 279 checks.
- `Log.Line`: a line of a channel's kind (`CHANNELn`) that comes with a message event we do not read (a
  community's channel, `CHAT_MSG_COMMUNITIES_CHANNEL`) is that channel's (`CHANNEL:n`), so its tick hides it; it
  went with the notices. Without an event, or with `CHAT_MSG_CHANNEL_JOIN`/`_LEAVE`/`_NOTICE...`, a notice.
- Test: every tick of the list, one after the other, takes exactly its messages out and brings them back.

### Chat: chat history; switches for system, creature, addon messages and channel joins; closer bubbles
Not tried in the game. Tests: Chat 276 checks.
- **Save chat history** (`history`, on) and *Messages kept* (`historySize`, 0 to 500, 100): `Log.Saved` at
  `PLAYER_LOGOUT` into `Core.Character("Chat").history`, `Log.Restore` at the login before the window shows,
  the messages a day old so they are faded out. `Log.Keep`: the log keeps max(200, history) messages.
- **Messages to show** (page Chat, General): `showSystem`, `showCreatures`, `showAddons` (on), `showJoins`
  (off). `ns.SHOWS` maps their groups to them; `Channels.Shown` and the new `Channels.Flip` (the list's
  ticks) use the setting for these, `mute` for the rest.
- **Channel joins and leaves** are a group of their own (`CHANNEL_NOTICES`: `CHANNEL_JOIN`, `CHANNEL_LEAVE`,
  `CHANNEL_NOTICE(_USER)`, `CHANNEL_LIST`, and every line of a `CHANNELn` kind without its event), hidden at
  first; they went with *System* or with the channel before.
- **Closer bubbles:** `Layout.SPACING` 3 (was 8).

### Chat: all bubbles alike, on a color or a game texture; Settings: a color swatch
Not tried in the game. Tests: Chat 264 checks.
- **One fill for every bubble**, yours too, and for the line to write in (`Bubble.Paint`); `Layout.THEIRS` and
  `YOURS` are gone. Only the text's color differs by kind of message.
- **Bubble background** (`bubbleBack`): *Solid color* or one of five quiet tiles of the game's own windows
  (`ns.BACKS`: Marble, Rock, Slate, Iron, Night). A plate can be tiled (`plate:Tile(file, size, alpha)`,
  `Plate.lua`): each of its seven pieces gets the texture coordinates of where it lies, from the plate's top
  left, measured anew on `OnSizeChanged`, so the tiling runs on without seams; Transparency is its alpha.
- **Bubble color** (`bubbleColor`, hex, at first `26262B`): a swatch, greyed out unless the background is solid.
- **Settings:** `Panel.Color` (the game's `ColorSwatchTemplate`, a click opens `ColorPickerFrame`, every move
  is set at once, Cancel sets the one before; `Panel.Hex`, `Panel.RGB`); `color = true` options in tabbed pages
  (`Tabbed.lua`; list pages skip them); `parentValue` greys a line out while a dropdown is not set to that value
  (`Config.Free`).

### Chat: every line the game's chat shows; the line to write in is grey
Not tried in the game. Tests: 258 checks (Chat).
- **Every other line** (`Log.Line`, was `Log.Note` for prints only): a hook on `AddMessage` of each of the
  game's chat windows (`CHAT_FRAMES` but the combat log) takes every line that is not of an event or a kind
  of chat we read ourselves (the chat type number, fifth value, and the event, eighth value). So the
  system's lines without an event (`DisplaySystemMessageInPrimary`), pings, loot, money, experience,
  reputation, battlegrounds, pet battles, boss emotes, channel notices and Battle.net toasts are notes now,
  worded as the game's chat has them. `CHAT_MSG_SYSTEM` is no longer read from its event. One line in two
  windows is taken once (`Fresh`, per frame). The time in front of a ping is taken off.
- **New groups to show:** *Pings*, *Loot, money and experience*, *Battlegrounds*, *Pet battles*; AFK and DND
  with whispers, boss emotes with creatures, channel and Battle.net notices with *System*. A channel's notices
  (`CHANNELn`) go with that channel.
- **The line to write in** has the others' grey fill (`Bubble.Paint`, was `Bubble.Yours` with the blue).

### Settings and Sync are part of Core
Not tried in the game. Tests: lint (4 addons), 183 checks (Core), 47 checks (Sync), 274 checks (Spellbook).
- **No addons of their own any more:** `src/Settings/` is `src/Core/Settings/`, `src/Sync/` is `src/Core/Sync/`,
  listed in Core's TOC after its other files; their TOCs are gone. Four addons: `SaneUI`, `SaneUI_Spellbook`,
  `SaneUI_Tooltips`, `SaneUI_Chat`. The folders `SaneUI_Settings` and `SaneUI_Sync` must go from the game's
  AddOns folder (the old Sync would load next to Core's).
- **Settings → `Core.Config`** (was the module `SaneUI.Settings`, load-on-demand). `Settings/Settings.lua` now
  puts up the pages at login (`PutUpPages`, `Core.pages`, `Core.frames`, `Core.Tabbed`, moved from Core.lua),
  hooks the options window's `OnShow` and owns `/sane options`; the controls are still made only when the
  options first open (`Config.Fill`, was `Config.OnLogin`). `Core.LoadSettings` is gone, and so is the message
  that the options are switched off. `## AddonCompartmentFunc` is in Core's TOC. Sane UI's banner is Core's
  (`src/Core/Art/banner.blp`, `Interface\AddOns\SaneUI\Art\banner`; `dev/tools/art` writes it there).
- **Sync → `Core.Sync`** (was the module `SaneUI.Sync`). Its switches keep the name `Sync`
  (`SaneUIDB.modules.Sync`): nothing saved changes. `Sync.Safe` notes as `Sync: <step>`; `Sync.OnLoad` runs
  at Core's `ADDON_LOADED` after Saved's and Profiles' handlers; the giving at `PLAYER_ENTERING_WORLD`.
  `module.optionsPage` is gone: Sync, no module, gets no page anyway. The CVar list always has its ticks and
  the filter *Kept*; the tab *Accountwide* always Sync's boxes.
- **Load cost:** the options' code (with the CVar labels) is read at login now, not when the options open;
  nothing of it runs or builds a frame before then.
- **Tests:** `W.LoadCore` reads Core's subfolders; `W.LoadSettings` and the Spellbook run `--no-settings`
  are gone; `core.lua` loads all of Core.
- **Tools:** `dev/tools/cvar-labels` writes `src/Core/Settings/Data/CVarLabels.lua`.

### Profiles: New Characters
Not tried in the game. Tests: 182 checks (Core and Settings).
- **Settings, tab *Profiles*, box *Characters*:** a first line *New Characters* with *Load at login*, *Save at
  logout* and a profile, gold, above the characters seen.
- **Core, `Profiles.lua`:** kept in `SaneUIDB.newCharacters`; `Profiles.Character(Profiles.NEW)` and
  `SetCharacter(Profiles.NEW, ...)` read and set it. A character with no line yet gets a copy of it
  (`Register`) at `ADDON_LOADED`, before `Arrange`, so *Load at login* counts from its first login; at
  `PLAYER_LOGIN` if the game gave no GUID before (then `Arrange` at once). Rename and Delete change it like
  every character's line (`Lines`).

### Profiles: SaneUI Defaults, always there and never changed
Not tried in the game. Tests: 175 checks (Core and Settings).
- **Core, `Profiles.lua`:** the profile *SaneUI Defaults* (`Profiles.DEFAULTS`) is always first in `List()` and
  never saved: made from the modules' descriptions (`Defaults`), it holds every switch at its default (the
  checkboxes, sliders and choices; Sync's: every part ticked, no CVar kept by name, nothing taken from the game)
  and follows each new version by itself. `Load` empties the settings in use of every module switched on and
  gives each switch its default (`Put`'s `fresh`), telling the modules; a module switched off keeps its own.
  With *Load at login* `Arrange` empties every module's, and one read later gets its defaults from
  `Core.Options`. `Duplicate` makes a profile of your own from it. `Save`, `Rename` and `Delete` refuse it
  (`Fixed`), no other profile takes its name, *Save at logout* never saves into it (`Character` reports
  `autoSave` false). `Exists` (any profile) is apart from `Saved` (a saved one). A saved profile of that name
  from before is moved to *SaneUI Defaults (old)*. Sane UI sets no CVar values of its own, so loading it leaves
  the game's values as they are.
- **Core, `Saved.lua`:** a table's default (Sync's `cvars`, `saved`) is copied into the settings, not shared
  with the description: what the module kept in it changed the default (`Core.Copy`, now also Profiles').
- **Settings, `Profiles.lua`:** with *SaneUI Defaults* chosen, *Rename* and *Delete* are switched off and *Save*
  offers no name; *Save at logout* is switched off on the line of a character that has it. Tooltips say so.

### Core: a docked window fills the screen from its screen edge; the kinds of motion; Chat: full screen
Not tried in the game. Tests: 161 checks (Core and Settings), 83 checks (windows), 254 checks (Chat).
- **Core, `Edge.lua` (new):** a window made with `Window.New(frame, { edge = true, ... })` and docked fills the
  screen when the mouse is pushed against that screen edge (a strip two physical pixels wide along each docked
  side, inside the window, strata `DIALOG`, only the mouse's coming: `OnEnter`), and goes back when pushed there
  again. Size and place spring from where the window is to the whole screen (then `SetAllPoints(UIParent)`) or
  back to its zone (`Dock.Rect`, new; then `window:Place()`); strata `HIGH`, unclamped and a solid black
  background (alpha with the way) while it is away; grip out of sight, no dragging or sizing. Its `content`
  fades out (0.15 s) and comes in once it stands (0.4 s, from 10 above); `docked`
  is called at the end, `filled(full)` at the start. Not within 0.25 s of a placing, not with a button held.
  `Place()` (a reset), hiding it, or a failing step bring it back at once; a failing step also switches it off
  for that window.
- **Core, `Motion.lua` (new):** kinds of motion, each a time and a curve, and one without motion;
  `Motion.Kind(key)` (nil or `"global"`: the general one), `Share`, `Choices`, and `Clock` (an animation group as a clock, as `Expand` had
  it, its step guarded). `Expand` moves by it (`Expand.Spring` and `Expand.TIME` are gone) and has `motion` and
  `still`.
- **Core, general switch** *Animation type* (`motion`) on the page *Appearance* under *Windows*: Core's
  switches name their page with `page = "Appearance"`. **Settings:** `Fill(page, name, onPage)` puts each on
  its page; the line that said *Appearance* had nothing yet is gone (`Note.xml`, `SaneUISettingsNoteMixin`).
- **Chat:** the window has `edge`; tab *Appearance*, under *Animations*: *Animation type* (`motion`, *Use global
  type* or one of Core's kinds), greyed out and without motion while all animations are off. Full, every message is
  there to read; the list is the content; the line to write in follows the window's layer (`Input.Layer`).
- `/sane window` fills the screen too. Tests: `wowstub` has `GetPhysicalScreenSize`; `core.lua` and
  `tooltips.lua` load `Motion.lua`.

### Chat: the animation lines renamed; Settings: room between a checkbox and its words
- **Chat, tab Appearance:** *Enable all Animations and Fades* (was *All animations*), *Opacity fade in speed*,
  *Opacity fade out speed* (were *Fade in*, *Fade out*), *Fade messages after* (was *Display messages for*).
  The keys stay.
- **Settings, `Panel.Check`:** the words 4 pixels right of the box (the game's template has them 2 into it), on
  every page of our own, Profiles too; in a tabbed page they line up with the words of a line without a box.

### Chat: its page in tabs, General and Appearance; Settings: a module's page in tabs
Not tried in the game. Tests: 246 checks (Chat), 160 checks (Core and Settings).
- **Settings, `Tabbed.lua`:** a module whose switches name a `tab` gets a page of our own drawn as Profiles is
  (title, the game's tabs, titled boxes per `header`), from its switches' descriptions: checkboxes, sliders
  (`Panel.Slider`, the game's `MinimalSliderWithSteppersTemplate`, value and `unit` beside it), dropdowns
  (`Panel.Dropdown`); `inline` puts a number on its parent switch's line; `parent` greys out (`Config.Free`).
  Replaces the sub-page of the entry below (`page`, gone again). Core: `Core.Tabbed`, the canvas page in
  `PutUpPages`.
- **Chat:** tab *General* (*Show native chat*, the channels), tab *Appearance*: *Messages* (*Text size*,
  *Transparency*, *Short names*) and *Animations*: *All animations*; *Fade in* and *Fade out* with a speed
  (0 to 2 s); *Display messages for* (s); *Opacity* of faded messages (new, `fadeFloorOn`, `fadeFloor`:
  faded messages fade to it, not to nothing); *Slide up speed* (0 to 2 s). New keys `fadeInOn`, `fadeInTime`,
  `fadeOutTime` (`fadeIn`, `fadeOut` are no longer read). All animations off now leaves every message on show.

### Chat: a page Appearance with the animations; Core: switches on a page under a module's, under another switch
Not tried in the game. Tests: 241 checks (Chat), 160 checks (Core and Settings).
- **Core/Settings:** an option's `page` puts it on a page of that name under the module's page (Core puts it up
  at login, `Core.pages["Chat/Appearance"]`); `parent` draws it under an earlier switch
  (`SetParentInitializer`), greyed out while any switch above it is off. Sliders with steps below 1 show two
  decimals. `Add` returns the initializer.
- **Chat, page Appearance** (Esc > Options > AddOns > Sane UI > Chat > Appearance): text size, bubble
  transparency and short names (moved from Chat), *Fade messages out* and its seconds (moved), and new:
  *All animations*, *Fade in (seconds)*, *Fade out (seconds)*, *Slide animation*, *Slide time (seconds)*.
  `Fade.Times`, `Window.Animate`; with no time a fade is at once, and `Refade` paints at once.

### Chat: gone messages stay gone when a new one comes; the fade-in shows
Not tried in the game. Tests: 229 checks (Chat).
- **Bug:** a new message brought gone ones back for a moment (to about a fifth). While a message is added the
  list keeps its scroll offset and is for a moment not at its end; its `OnScroll` counted as a scroll of
  yours and revealed every message, until the mouse ticker ended it. Only the wheel reveals now.
- **Fade-in** 0.4 s (`Layout.APPEAR`, was 0.25) and **slide** 0.3 s (`Layout.SLIDE`, was 0.2): a new message
  slides in from the list's bottom edge and is seen fading in on the way, not only once it is in.

### Chat: every message fades by itself, apart from the slide
Not tried in the game. Tests: 228 checks (Chat).
- **Fades kept on the message** (new `Fade.lua`): from, to, since and span on the entry; a row only shows
  `Fade.Alpha`. Before, the fades were animation groups on the list's rows, which the list hands to other
  messages when it lays them out: a new message coming while others faded out cut off or restarted
  their fades. Turning back starts from where it is.
- **Painting** (`Window` `Paint`, `Step`): `OnUpdate` on the window only while a message in view fades; one
  timer for the next message whose time is over (`Schedule`, `Due`).
- `Bubble.Fade`, `Bubble.Appear` and the rows' animation groups are gone. Fading in 0.25 s
  (`Layout.APPEAR`, was 0.15), out 1 s (`Layout.FADE`, was 2), eased.

### Chat: faded messages stay faded under the mouse; fade in, slide up, smooth scrolling
Not tried in the game. Tests: 217 checks (Chat).
- **Reveal** (`Window`): the mouse over the window no longer brings faded messages back; a turn of the mouse
  wheel over the list, or a scroll up, does, until the mouse is away at the newest message.
- **Fade in** (`Bubble.Appear`, `Layout.APPEAR` 0.15 s): a new message, and one shown again, on the row's body.
- **Slide** (`Window` `Slide`, `Layout.SLIDE` 0.2 s): two Translation animations on the list's `ScrollTarget`
  when the messages move up for a new one or for the line to write in.
- **Smooth scrolling:** `SetInterpolateScroll` on the list and its scroll bar.

### Chat: notes in bubbles, achievements and the guild's message of the day
Not tried in the game. Tests: 210 checks (Chat).
- **Notes** (the system's, emotes, printed lines) are bubbles too: in the middle of the row, in the others'
  fill, nothing above them, the text in the game's colour (`Bubble.Init`; the row's centred text is gone).
  `Layout.TextWidth` gives them a share of the row, `Layout.RowHeight` the bubble's height.
- **Achievements:** `CHAT_MSG_ACHIEVEMENT` (group System) and `CHAT_MSG_GUILD_ACHIEVEMENT` (group Guild) as
  notes, the name the player's link in brackets as in the game's chat.
- **The guild's message of the day** (`GUILD_MOTD`, `Log.Motd`): a note of the guild, in `GUILD_MOTD_TEMPLATE`.

### Chat: clicks go through, the scroll bar only scrolled up, a click on a name whispers
Not tried in the game. Tests: 206 checks (Chat).
- **Clickthrough:** the window takes no mouse any more (no `SetMouseMotionEnabled`, no `OnEnter`). The bar to
  move it by joins the grip and the chat button in `chrome`, hidden without the mouse over the window, so then
  only links and names take the mouse. A ticker (0.2 s, while the window is shown) asks `IsMouseOver` instead.
- **Scroll bar** (`Window` `Bar`): shown only while the list is scrolled up from the newest message, not with
  the mouse.
- **Names** are the game's link to the speaker (`Log` `Link`, `entry.link`: `GetPlayerLink`, or
  `GetBNPlayerLink` for Battle.net whispers): a click whispers to them, a right click opens their menu.

### Player names: first name and surname
Not tried in the game. Tests: 160 checks (Core and Settings), 276 checks (Tooltips), 274 (Spellbook).
- A Forever name is a first name and a surname; `UnitName` gives both (two values). Sane UI kept only the first.
  New `Core.FullName(unit)` (as the game's Camelot `NameUtil.FormatUnitNameForDisplay`: the separator is
  `Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR`). `Core.charName` is the whole name,
  so the Characters list of the page Profiles shows it (a character listed before updates at its next login).
- Tooltips: the target in a unit's panel and who cast a buff by the whole name; a player's title is found in
  `UnitPVPName` with the whole name, else the first name.
- Tests: the stand-in player is "Tester Stub"; Jaina is "Jaina Proudmoore" in the Tooltips suite.

### Game chat channels on the page Chat; Sync parts ticked in older saved settings
Not tried in the game. Tests: 194 checks (Chat), 47 checks (Sync), 160 checks (Core and Settings).
- **The game's chat channels** moved from the Sync module to the **Chat module**: a choice per channel under
  a header *Chat channels* on the page *Chat* (`ns.GAME_CHANNELS` and the switches in `Chat.lua`, the joining in the new
  `Join.lua`, through `ns.Safe` so an error there does not close the window). The tab *Chat channels* of the
  page Profiles is gone, and with it `Panel.Radio` (no other use).
- **Sync `Upgrade`** (at its `OnLoad`): saved settings of the first Sync version still had action bars, chat
  window places, graphics, sound and modifier keys unticked (the in-game settings showed them off). Every copy
  (`Core.Profiles.Copies`: in use, the account's kept aside, the profiles', this character's own) without
  `version` 2 gets those five ticked and its old `channel<id>` switches dropped, once.
- **Core:** `Core.Profiles.Copies(module)`.

### Profiles: All settings accountwide, modules account wide or not, a profile per character
Not tried in the game. Tests: 160 checks (Core and Settings), 53 checks (Sync).
- **All settings accountwide** (ticked at first, `SaneUIDB.separate` when not): for the account, replacing the
  per-character *Character specific settings*. Under it: *Ticked will sync all settings accountwide by
  default. Profiles overwrites the setting on a per character basis.*
- **Tab Accountwide** (was *Sync settings*): a first box *Sane UI* with a checkbox per module (General, Chat,
  Spellbook, Tooltips; `SaneUIDB.perCharacter`): unticked, that module's settings are each character's own.
  The tab's checkboxes are switched off while all settings are each character's. It is there without the Sync
  module too.
- **Characters** (tab Profiles): every character seen on the account (`SaneUIDB.characters`, noted at login),
  each on a line with *Load at login*, *Save at logout* and its profile. A character with a profile and Load
  at login uses it for itself only, not changing the account's; Save at logout puts its changes back into
  the profile. Set for any character from any character. The old per-character Load at login / Save at
  logout under the profile are gone.
- **Core `Arrange`:** each module's settings in use come from the account, the character's own or a profile,
  and are moved between them at login, when a switch changes and at logout. `Core.Profiles`: `AccountWide`,
  `SetAccountWide`, `Shared`, `SetShared`, `Characters`, `Character`, `SetCharacter` (were `Own`, `SetOwn`,
  `AutoLoad`, `AutoSave`, ...). `Core.realm`.
- **Sync:** every part ticked at first (also action bars, chat window places, graphics, sound, modifier keys).
- Tests: the Chat suite finds its window's title on the window itself (the options now have a "Chat" too).

### Profiles: a page with tabs and boxes; Sync in fine-grained parts
Not tried in the game. Tests: 156 checks (Core and Settings), 53 checks (Sync).
- **The page Profiles** is a page of our own (a canvas: `Settings.RegisterCanvasLayoutSubcategory`, one empty
  frame Core puts up at login, `Core.frames.Profiles`): its title, the line
  *Settings are saved account wide by default*, and tabs (`MinimalTabTemplate`, as the window's Game/AddOns)
  over a box: *Profiles* (boxes *Account or character* and *Saved profiles*: dropdown, Load, Save, Duplicate,
  Rename, Delete, Load at login, Save at logout), *Sync settings* (a titled box per group, checkboxes in two
  columns), *Chat channels* (a choice per channel), *CVars* (a line
  on what the ticks do, then the list). New `Settings/Panel.lua` (the parts) and `Settings/Synced.lua`; the
  list-page rows of the profiles (proxy settings, button rows) are gone.
- **Sync, fine-grained:** parts in groups: CVar parts by names, name prefixes or the game's own kind of
  CVar (Graphics, Sound), with hardware and character state never taken; plus chat window
  places and sizes, modifier keys (with `SaveBindings`), declined guild invitations, location for recent
  allies. Every CVar of a ticked part is kept, whoever the game keeps it for (was: only those it keeps per
  character). Off at first: action bars, chat window places, graphics, sound, modifier keys. New
  `Sync/Switches.lua` describes the switches in group order; `ns.Part`, `ns.GROUPS`, `ns.CVarsOf`.
- The test stand-in has canvas pages, tab groups, dropdown menus and the templates' parts.

### Options: Sane UI with only its logo, then Profiles, General, Appearance, the modules
Not tried in the game (the layout it replaces was). Tests: 150 checks (Core and Settings); the Spellbook, Chat
and Sync suites follow the new page names.
- **The pages:** *Sane UI* shows only its banner. Under it, in this order: *Profiles* (the profile rows
  without a header, the Sync module's sections, the CVar list), *General* (*Errors in chat*), *Appearance*
  (one line: nothing to set yet), then the modules' pages by their plain names: *Chat*, *Spellbook*,
  *Tooltips* (were *Sane Chat*, ...). `/sane options` and the minimap's addon list open *Sane UI*.
- **Core:** `Core.pages.top`, `.Profiles`, `[Core.name]` (*General*), `.Appearance`, then a page per module
  titled `module.title`; the game keeps that order (it sorts sub-pages only when asked). A module's
  `optionsPage` names one of Sane UI's own pages for its switches; Sync's is `"Profiles"` (was
  `onGeneralPage`).
- **Settings:** `Note.xml` (`SaneUISettingsNoteTemplate`), a line of text as a row.
- `CLAUDE.md`, the root README and the Spellbook and Tooltips READMEs name the pages as they are now.

### Sync, the game's CVars, and profiles loaded and saved by themselves
Not tried in the game. Tests: lint, 146 checks (Core and Settings), 43 checks (Sync, new), the other suites
unchanged.
- **New module Sync (`SaneUI_Sync`):** keeps the settings the game saves for each character with Sane UI's
  settings: the account's, a character's own, profiles. Parts, each a switch: Edit Mode layout (by name),
  chat windows (names, text size, colour, shown/locked/docked, message groups, channels; chat colours), your
  own chat channels, camera, nameplates, other game settings (the rest of the per-character CVars, without
  tracked/collapsed/counted/last-chosen state; guild invitations), action bars shown (off at first).
  - Taken when Sane UI's settings are saved (logout, profile save: Core's new `capture`), and only after the
    session gave them; given 2 s after entering the world, after a fight if in one, and when a profile is
    loaded. Only what differs is set.
  - Only CVars the game keeps per character (`GetCVarInfo`), found at run time (`ConsoleGetAllCommands`): no
    lists of CVar names; the account's and the computer's are shared by the game already.
  - All through the game's stored settings (C_CVar, `SetChatWindow*`, `Add/RemoveChatWindow*`,
    `ChangeChatColor`, `C_EditMode.SetActiveLayout`, `SetActionBarToggles`), never its frames: no taint. Chat
    windows and action bars show after a `/reload`; a dialog offers one when they changed.
  - The game's chat channels joined or left on every character as chosen; nothing while chat is locked
    down.
  - Its switches are sections of the general options page (`module.onGeneralPage`), not a page of its own.
  - Left out: graphics, sound and modifier keys (shared by the game already), and whatever would write into
    the game's frames or tables.
- **Settings, section *CVars*:** every CVar of the game in one list on the general page, searchable, each
  with a tick to keep it (Sync), its help, its default and its value. Read-only and locked ones are not changed, secure ones not in a fight. One row of the settings
  list with its own scroll box (`CVars.lua`, `CVars.xml`).
  - Labels: `Data/CVarLabels.lua`, made by the new `dev/tools/cvar-labels` from Blizzard's options code in
    `references/`: names of the game's strings only (239 CVars), the text comes from the game.
- **Profiles:** *Load at login* and *Save at logout*, this character's, for the chosen profile (children of
  the dropdown). Loading happens at Core's `ADDON_LOADED` before any module reads its settings (also at a
  `/reload`); saving at `PLAYER_LOGOUT` after the capture.
- **Core:** `Core.Options(name, list, changed, capture)`; options may carry `header`/`headerTip` (a section
  on the page) or no `text` (kept, without a control). `Core.pages` gives a module with `onGeneralPage` the
  general page. The general switch is now called *Errors in chat*.
- **Settings:** the general page in the order General, Profiles, the Sync module's sections, CVars; `Fill`
  makes section headers and skips switches without text.
- **Tests:** `dev/tests/sync.lua` (new), with a model of the game's chat windows, channels, Edit Mode and
  action bars. The stand-in has CVars (`W.cvarInfo`: default, where kept, secure, read-only, kind),
  `ConsoleGetAllCommands`, header tooltips, rows that can be children, and `W.LoadAddon` (a module by its
  TOC, folders too).

### Profiles: the account's settings or a character's own, and named copies of them
Not tried in the game. Tests: lint, 121 checks (Core and Settings), the other suites unchanged.
- **New section *Profiles*** on the general page *Sane UI*, under *General* (Settings, new `Profiles.lua`):
  - *Character specific settings* (checkbox): ticked, the character has settings of its own, at first a
    copy of the account's; unticked, it is back on the account's and keeps its own for the next time.
    Modelled on the game's *Character Specific Key Bindings* (a proxy setting without a default, so the
    options' *Defaults* button leaves it alone).
  - *Profile* (dropdown) with the buttons *Load*, *Save*, *Duplicate*, *Rename* and *Delete* under it,
    drawn as its children (indented; switched off while there is no profile). Names are asked for in the
    game's own `GENERIC_INPUT_BOX`, deleting is confirmed in `GENERIC_CONFIRMATION`; nothing is added to
    `StaticPopupDialogs`. Save offers the chosen profile's name; a taken or empty name for Duplicate or
    Rename is refused with a line in chat.
- **Core, new `Profiles.lua`:** `Core.Profiles` keeps and does all of it. A profile
  (`SaneUIDB.profiles[name][module]`) holds the switches of every module there are saved settings for,
  for all characters. Loading copies into the tables the modules hold (never replaced), puts spoiled
  values right (`Core.CheckOptions`, the old `Defaults` of `Saved.lua`) and calls each module's
  `changed(key, value)` for every switch that changed.
- **Per-character saved settings:** Core declares `SaneUICharDB` (`own`, `settings`, `profile`). With
  own settings, the account's are copied aside into `SaneUIDB.account` at Core's `ADDON_LOADED` and put
  back at `PLAYER_LOGOUT`, so the shared file always holds the account's for other characters; a leftover
  from a logout that did not finish is put back at the next login. With the account's settings in use
  nothing is copied.
- **Settings:** `Config.Refresh` shows values changed under the controls (`NotifyUpdate`), with the
  modules' callbacks muted, as Core told them already. The test stand-in has proxy settings, button rows,
  `NotifyUpdate` and the game's two generic dialogs; `W.LoadSettings` reads the Settings module by its
  TOC (the Spellbook and Chat suites use it too).

### Images: a guide, and the textures sized for 4K
Not tried in the game. Tests: lint, 85 checks (Core and Settings), the other suites unchanged.
- **New guide `Doc/guides/images.md`:** how a picture becomes a texture (format, size for 4K, encoder,
  drawing it), with the measurements behind each choice and what was tried and rejected, so it need not
  be looked up again. Listed in `CLAUDE.md`, `AGENTS.md` and the GUI guide. `dev/tools/art-measure`
  repeats its measurements (the graphics card's sampler simulated, PSNR against a perfect resize).
- **Sized for 4K:** `dev/tools/art` takes the size a picture is drawn at (UI units) and makes each side
  the power of two that holds 85 % of what a 4K screen at UI scale 1 shows (2.81 pixels a unit). The
  picture keeps its proportions in the texture (no longer squeezed in); the rest is cut off with
  `SetTexCoord`. Banners are now 1024 x 256 (342 KB; the 3 : 1 box fills the left 768), icons 128 x 128,
  the logo 256 x 256: 1.5 MB in all. Measured against the old 512 x 256: 2.8 dB closer to the drawing
  on 4K, 2.7 dB on 1440p.
- **The game's own filter for the banners,** not `TRILINEAR`: art drawn between half and full size of its
  file came out up to 5 dB blurrier with it. The banner sets its texture coordinates after `SetTexture`.

### Art and banners in the options
Not tried in the game. Tests: lint, 84 checks (Core and Settings), the other suites unchanged.
- **The art:** the banners, icons and logo drawn for Sane UI (PNGs in `assets/`, 1.6-1.9 MB each) are
  made into game textures by the new `dev/tools/art`: BLP2 with DXT5 and a full chain of mipmaps, as
  Blizzard's own logos are, in `assets/optimized/`. Banners 512 x 256 (171 KB), icons 128 x 128
  (22 KB), the big logo 256 x 256 (86 KB): 864 KB in all, from 15.3 MB. On the way the drawings' solid
  parts (alpha 252-253, a left-over of cutting them out) become fully solid, and the edge colour is
  carried into the clear pixels, so no dark seam shows. The DXT5 blocks come from ImageMagick's cluster
  fit: Pillow's own writer washed out the letters.
- **Banners in the options:** each page shows the banner of the addon it belongs to at the top, in place
  of the page's title: the general page Sane UI's (above *General*), *Sane Spellbook*, *Sane Chat* and
  *Sane Tooltips* their module's. A module ships its own as `Art/banner.blp`; Sane UI's is the Settings
  module's. The banner is a row of the game's own list (`Banner.xml`, `SaneUISettingsBannerTemplate`):
  made only when its page is shown, drawn at 300 x 100 with `TRILINEAR` filtering; the game's title is
  hidden only while the row is there (another page or scrolling it away brings it back). An addon
  without a banner file keeps the game's title (`SetTexture` reports the missing file).
- **Docs:** the GUI guide says how own pictures ship; `assets/` is listed in `CLAUDE.md` and the README.
  The original PNGs in `assets/` are not committed.

### Project: context for future coding chats
- Added `AGENTS.md` and compact notes in `Doc/agent/`: task routing, module architecture, saved data,
  secure execution and fallback contracts, development commands and pending client QA.
- Added `dev/tools/project-index` and its generated file index: hashes detect source changes,
  declarations/headings and TOC order help find the relevant files without rereading the project.
- Recorded existing documentation discrepancies; no addon behaviour changed. Offline suite passed:
  lint and 1,117 checks. External reference libraries and personal state stay outside the index.

### Tooltips: review fixes
Not tried in the game. Tests: 252 checks (Tooltips).
- **Fixed:**
  - Debuff panels take their kind's colour: `DebuffTypeColor` does not exist in this client; the colours
    come from `AuraUtil.GetDebuffDisplayInfoTable()` (the test no longer stubs the missing global).
  - A unit's panel freezes while its tooltip fades after the mouse left (it kept reading "mouseover":
    bars dropped to 0, or another unit's numbers showed). The unit's GUID is kept in the model's head.
  - Sizes measured through a hidden (secret) anchor: the panel's points are cleared before it is
    measured; a size the game hides spoils only that draw, and that tooltip is the game's this time.
    `GetFrameLevel` and `GetEffectiveScale` go through `Plain`.
  - The comparison tooltips can no longer anchor in a circle: `Release` clears points, `Beside` falls
    back to the corner if the game refuses an anchor.
  - Other addons' tooltips that nobody sees (owned, placed nowhere) get no panel, and a panel whose
    tooltip is no longer placed is released, which also stops its `OnUpdate`.
  - Releasing gives the tooltip its alpha first, then each part on its own.
- **A part fails, not the whole:** each kind's reader runs on its own; a reader that fails (a renamed
  game function) makes that kind's tooltips the game's own and says so once, the others are still drawn.
  The mouse switch is `Safe`, so it works after a stand-down. Core's `Guarded`, `StandDown` and
  `GiveBack` replace the module's own copies.
- **Lighter:** what your quests want from a creature or NPC is kept per NPC until your quest log or
  level changes (it was worked out at every read, five times a second on a unit frame), with no tables
  made; no substrings per line; the tooltip's named parts are looked up once; panels are made when first
  needed, not at login; the inspect list and the auction prices (older than 30 days) are pruned.
- **Tidier:** the pools in their own file (`Pools.lua`; `Panel.lua` 771 → 596 lines), one palette
  (`ns.COLOR`, the "done" green is the unit section's), one colour code helper, one font helper, one NPC
  id, prose and rank check each; dead code removed; three different "Numbers" renamed.
- The quest database stays loaded at login: it costs about 5 ms and 1–1.6 MB and is needed on the first
  creature you hover, so a load-on-demand addon would gain nothing noticeable.

### Chat: review fixes
Not tried in the game. Tests: 185 checks (Chat).
- **Fixed:**
  - Party and raid rings: `C_PartyInfo.IsGUIDInGroup` (the global `IsGUIDInGroup` is only a deprecated
    wrapper that may be missing, and every stranger's message raised a caught error).
  - A minimised undocked chat window (`ChatFrame<n>Minimized`) is hidden with the game's chat too; a frame
    the game moved to another parent meanwhile is left where the game put it when ours goes.
  - Errors keep the place they happened (`ns.Guarded`, Core's, instead of a plain `pcall`).
  - Giving the edit box back undoes its strata, level, alpha and mouse; anchors are put back with
    `Core.Repoint` (no `unpack` hole).
  - Community channels show their names (`ChatFrameUtil.ResolveChannelName`).
  - **Chat in a fight or a dungeon:** while chat is locked down (`C_ChatInfo.InChatMessagingLockdown`,
    `ADDON_RESTRICTION_STATE_CHANGED`) addons get no messages to show, so the game's own chat is on show
    for that time even with *Show native chat* off. Before, chat could vanish entirely.
- **Less taint:** our code no longer hides the game's edit box; the game puts it to rest itself, and in
  IM style a hook after its `Deactivate` makes it invisible. The chat picker still sets the chat type
  from our code: documented in the README, to be checked with `/console taintLog 1`.
- **Lighter:** a full log drops 25 messages at once with one list update (was two full rebuilds per
  message); a channel's short name, a sender's class and what a speaker is to you are cached (capped,
  cleared when friends, guild or group change); typing re-anchors only when the line's height changes;
  while the window is sized only the edit box follows, the bubbles rewrap once at the end; no closures
  per wake or fade.
- **Hardening:** `ns.GiveBack` gives back step by step (edit boxes and their anchors first), each step on
  its own; an unreadable message is left out and noted instead of closing the window; the
  `EventRegistry` callbacks are unregistered on a stand-down; menu callbacks, wake and fit are guarded.
- **Tidier:** one list of chat kinds (`Log.GROUPS`) and one visibility check (`Channels.Shown`); one
  round mask (`ns.Round`); the chat picker in its own file (`Menu.lua`); `Core.charKey`, `Window.Reset`
  and `RGBToColorCode` instead of copies.

### Spellbook: review fixes, lighter at login
Not tried in the game. Tests: 274 checks (Spellbook) and 270 with the Settings module switched off.
- **Fixed:**
  - A takeover that failed half way (a template missing) no longer leaves the column 60000 high: our
    frames are made into locals and kept only when all could be made; a failed `Arm` stands the book
    down and gives back what was taken; the column's own height is only noted below `TALL`.
  - Home no longer draws itself again over the game's page after `SetHome` fell back; its tab and cover
    clicks run through `Safe`.
  - A spell the game pushed onto a bar is taken off only the slot the game used
    (`SPELL_PUSHED_TO_ACTIONBAR` gives spell, slot and page); your own copy elsewhere stays.
  - A window reset or fallback in a fight is done when the fight ends; the small spellbook's inset is 3
    (809 against 806 in the game's XML), the open one's 6.
  - The tab row moved for Home is put back after a fight if a fight kept it; the search box beside it is
    sized like the game sizes it (`FitSearchBox`), without calling the game's code.
  - A hidden (secret) action slot is "unknown": a reservation is neither ended nor filled on a guess.
  - Saved data of the wrong shape (reservations, layouts, trainer rows, extras) is dropped or skipped.
- **Talents:** the game's own talent tree stays. `## OptionalDeps` is gone from the TOC.
- **Lighter:**
  - The trainer data is filled at login for your class only (`D.Class`, `D.AtLogin`, `D.Fill`); the
    other eight classes' tables are never built, and nothing reads the game while the files are read.
  - The list of spells still to come, and the name requests to the game, are built only when the pages,
    Home or a command read it and something changed (`S.All`); what you have (`S.ScanBook`) is read out
    of a fight only.
  - The watcher that keeps entries in place looks every frame for 10 frames after a layout, then five
    times a second. The reserved mark is a yes/no without a table. Trainer rows already kept are not
    read again. Bar ghosts do nothing on hover unless shown, and stop looking for buttons once all have
    one. A drag looks the bar buttons up once. `IsSpellKnownOrInSpellBook` where the client has it.
  - The `ITEM_DATA_LOAD_RESULT` listener, which could never act, is gone.
- **Tidier:** dead code removed (`binding`, `ns.GOLD`, `ns.charKey`, `D.Target`, `E.Swap`,
  `E.PlaceCursor`); duplicates merged (`L.Compare`, `L.ByLevel`, `B.Locked`, `B.Header`, `I.TextColor`,
  `RequestSpell`); the marks moved to `Spellbook.lua`; Core's `Coins`, `Ask`, `Points`/`Repoint`, `Trace`
  and `Later` used. Moving the takeover out of `Book.lua` was left: it shares about 30 of its locals.

### Core: the options' AddOns tab, shared tools, hardening
Not tried in the game. Tests: 80 checks (Core and Settings).
- **Fixed: the game's options had no AddOns tab** (so no Sane UI pages) when Sane UI was the only addon
  with options. `SettingsPanelMixin:OnShow` hides the *Game* and *AddOns* tabs for the session if no addon
  category exists when the window first opens, and Settings (load on demand) was only read after that, from
  a hook after `OnShow`. Core now puts up the pages at login, empty (`Core.pages`; only when the Settings
  addon is switched on for the character), and Settings fills them when it is read. Settings stays load on
  demand. A module whose switches fail to go on its page no longer keeps the others from theirs.
- **Shared tools in Core** for the modules, so none keeps a copy: `Core.Report` (keep a problem and tell
  it once; replaces `Safe(label, error, problem)`), `Core.Trace` (the `xpcall` handler), `module.Guarded`
  and `module.StandDown` with the module's `GiveBack` and `GIVEN_BACK` (a feature that stands in for the
  game's gives it back when a step fails), `Core.Later` (once, a moment later), `Core.Ask` (a game function
  that may be missing or fail, its answers plain), `Core.Coins`, `Core.Points`/`Core.Repoint`.
- **`Core.Safe` makes no garbage**: no table and no closure per call (the game's `xpcall` hands the
  arguments on).
- **Hardening of the saved settings:** a saved value of the wrong shape (an older version, a hand edit) is
  replaced instead of breaking the load; a switch of the wrong kind gets its default; a number is kept
  within its ends. `Core.NoteError` cannot fail on a spoiled error list (it runs while an error is handled).
  `Window:Place` copes with a window without minimum sizes.
- Guides: `gui-development.md` says why an options page must be registered before the window first opens;
  `addon-standards.md` names the new tools.

### Core: windows
Not tried in the game. Tests: 56 checks (`dev/tests/window.lua`, new), 155 checks (Chat), Spellbook unchanged.
- **A library for windows in Core,** so no module moves or sizes a window with code of its own:
  - `Window.lua`: `Core.Window.Mover` and `Sizer` (the dragging and a grip, for a frame that is not ours),
    and `Core.Window.New` (a window of ours: bar, grip, docking, skin, the place kept in the module's
    store as `{ x, y, width, height, dock }`).
  - `Dock.lua`: twelve zones at the screen's edges (four corners, left, right, three along the top and
    along the bottom). A window let go within 60 of one hangs on it; a tinted shape shows where while it
    is dragged. `Dock.Find` is plain numbers.
  - `Skin.lua`: dark fill and the game's tooltip border in bronze. On a docked side it reaches out of the
    screen by the border's width, so the window is flush with the edge there.
  - `Expand.lua`: a window opens to a larger size when the mouse comes (anywhere on it, or in one corner)
    and closes when it left; the size springs. Driven by one of the game's animations.
  - `Demo.lua`: `/sane window`, a window to try all of it.
- **Chat** uses `Core.Window.New`: its own drag scripts, `PanelResizeButtonTemplate` and place keeping
  are gone. New: it docks, and its grip leaves the lower right corner when that is at the screen's edge.
  The kept place has the same shape as before.
- **Spellbook** uses `Core.Window.Mover` and `Sizer` for its bar and grip; what it does around them
  (the game's sizes, the two modes, fights) is unchanged.
- Tests: the stand-in client reads Core's files from its TOC (`W.LoadCore`) and knows a button's
  textures and `SetCursor`; `dev/tests/run` runs `window.lua`.

### Spellbook, evening
Not tried in the game. Tests: 263 checks (Spellbook) and 259 more with the Settings module switched off.
- **The spellbook can be moved and resized** (`Book/Window.lua`, new): a drag bar over the window's title
  and a grip in its lower right corner, both frames of the module. Size (one for the open book, one for
  the small spellbook) and place are kept in `SaneUIDB.modules.Spellbook.window` and put on the game's
  window again after the game sizes or places it (hooks after `OnShow`, `UpdateSize`,
  `UpdateUIPanelPositions`); only on the spellbook tab, while the pages are the module's, out of a fight.
  Switch *Let me move and resize the spellbook* (on); `/sane sb window reset`.
- **The pages follow the window's size** (`Book.lua`, `Measure`, `B.Layout`): page width and height, columns
  and rows come from the spellbook frame's size at every draw; the right page is placed from the left
  page's frame. `Layout.Paginate(groups, cellWidth, viewHeight, metrics)` takes columns, entry height
  and paddings. Home draws with the same measures.
- **Compact pages:** switch *Compact spellbook pages* (on). Entries, the game's and ours, are scaled to
  0.75 and padded 8 and 4 instead of 15 and 10: four columns of ten on the game's own page (were three of
  seven). `Place` takes a size; a fallback gives every entry the game's size back.
- Tests: the stand-in client knows a frame's scale and size.

### Tooltips: a chat link's tooltip in the middle of the screen, closed by a click, no X
Tests: 286 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **In the middle:** `ItemRefTooltip`'s `OnShow` is hooked (`Pin` in `Tooltips.lua`) and puts it at the
  screen's `CENTER`; `SetItemRef` gives it `ANCHOR_PRESERVE`, so that stays. `Native`'s `Corner` gives
  `CENTER` for a tooltip held by its middle alone, so the panel stands in the tooltip's middle.
- **A click closes it:** hooks on `OnMouseDown`, `OnDragStart` and `OnMouseUp`; a press that began on it
  and did not drag it calls `Hide` (what the X's `HideUIPanel` does for it; `HideUIPanel` from an addon is
  refused in a fight). Dragging still works. In `ns.Safe`, like the mouse switch.
- **The mouse where the panel is:** `Native.Reach` (in `Cover`, for a tooltip that `IsMouseEnabled`) sets
  the tooltip's `SetHitRectInsets` to the panel's edges and takes the mouse off the game's invisible X;
  `Release` gives both back. So hovering (comparisons with Shift), dragging and clicking follow the panel.
- **No X:** the panel's own close button is gone (`Panel.Draw`, `CLOSE`).

### Tooltips: gone at once when the mouse leaves
Tests: 275 checks (Tooltips). Not tried in the game. `/reload` is enough.
- The game lets a tooltip fade out slowly once the mouse has left a unit or a thing in the world
  (`GameTooltip:SetWorldCursor`) or a unit frame (`UnitFrame_OnLeave`): both call `FadeOut`. Every
  adopted tooltip's `FadeOut` is hooked (`Faded`): its panel hides at once and a waiting draw is dropped
  (`pending`). The game's tooltip is not hidden from here (taint); its parts keep alpha 0 until it hides
  and `Release` gives them back.

### Tooltips: fixed: the comparison of what you wear jumped between two places again
Tests: 271 checks (Tooltips). Not tried in the game. `/reload` is enough.
- Came back with the review fixes: `Native.Release` lets go of the panel's points (so two comparison
  panels cannot hang on each other), and `Filled` then placed a refreshed panel with `Cover`. The game
  refreshes a comparison several times a second with `SetOwner` (which hides it) and `ClearAllPoints`,
  fills it, shows it and only then gives it its points: `Beside` found none, the panel went to the
  corner of the game's own tooltip, and the draw at the end of the frame put it beside the other panel
  again. Now `Release` notes where the panel stood, and the refreshed panel waits there, hung on
  `UIParent` only (`Native.Stay`), until it is drawn and placed beside the other panel.

### Tooltips: descriptions in the middle; done objectives left out
Tests: 269 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Descriptions** (a spell's, a buff's: the rows marked `prose`) are centred, each of their lines
  (`Panel.Draw` hands their text `"CENTER"`).
- **A creature's quest lines** leave out what is done: an objective the game says is `completed`, or
  whose count is full (*7/7*: `Done` in `Kinds/Unit.lua`). A quest's name and a party member's line are
  held back until an objective under them is still to do, so a quest with all done here is gone too.
  The tick (`check`) is no longer used there; a quest link keeps its ticks. The unused `titled` is gone.

### Tooltips: the mouse option a dropdown; Always and Default at first
Tests: 267 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Tooltips at the mouse cursor** (`cursor`) is one of `default` (where the game puts them; the new
  default), `shift`, `ctrl`, `alt`, `always`; was a switch. A tooltip the game places with
  `GameTooltip_SetDefaultAnchor` goes to the mouse when the choice holds; where the game put it is noted
  (`placed`), and a key pressed or let go while it is shown moves it to the mouse and back (`Follow`, with
  `SetAnchorType`, which keeps its lines; `SetOwner` would clear them). Its panel follows.
- **Show tooltips** is `always` at first (was `shift`).
- **Older settings** are put right before `Core.Options` checks them (they were in `OnLoad`, after it):
  version 3 makes a saved mouse switch `always` or `default`, and a saved `shift` for *Show tooltips* (the
  default of one day) `always`.

### Tooltips: seen only while a key is held; Settings: dropdowns
Tests: 261 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **The option *Show tooltips*** (`show`, default `shift`): while Shift, Ctrl, Alt, or Shift and Alt are held,
  or `always`. A tooltip that may not be seen yet is filled, placed and drawn as always; only its panel (or
  the game's tooltip where it has none) is see-through (`ns.Allowed`, `Gate` in `Tooltips.lua`; the panel's
  own strength is `panel.strength`, as `panel.alpha` is Native's note of the tooltip's alpha).
  `MODIFIER_STATE_CHANGED` shows or hides the shown tooltips at once.
- **Core:** an option can be one of a few (`choices = { { value, words }, ... }`); a saved value that is none
  of them gets the default (`Saved.lua`, `Chosen`).
- **Settings:** such an option is a dropdown (`Settings.CreateDropdownInitializer` with a
  `CreateControlTextContainer` of the choices). The test stand-in has both.

### Tooltips: quest data by side; grey default panels; more tooltips hooked
Tests: 236 checks (Tooltips). Not tried in the game. `/reload` is enough.
- **Quest data by side:** `Data/Quests.lua` tags what differs by side: a giver or a dropping creature that
  is one side's only ends in `h` or `a`; races, next quest and breadcrumb goal that differ read "h32 a15".
  `Quests.lua` takes the player's side (`UnitFactionGroup`). 21 tagged entries, 3738 creatures with quest
  drops.
- **Default panels are grey:** a tooltip of a kind without a reader of its own (a mailbox, a herb, a hint)
  no longer takes its colour from its name (often gold); `NEUTRAL` is the dead unit's grey (was a blue grey).
- **More tooltips take hints:** `ItemRefShoppingTooltip1/2`, `GameNoHeaderTooltip`, `GameSmallHeaderTooltip`,
  `BuffFrameTooltip`, `AuraButtonTooltip` are hooked at login too (those filled from data were already).

### Tooltips: a dead creature keeps its portrait and dragon
Tests: 235 checks (Tooltips). Not tried in the game. `/reload` is enough.
- The game fills a dead creature's tooltip as a corpse's (`Enum.TooltipDataType.Corpse`), which had no reader
  of its own and got the plain panel: no portrait, no dragon, no bars. It is read as a unit now
  (`Kinds/Unit.lua`); a corpse's data that does not say whose it is means the creature under the mouse, when
  the names agree (`Token`). Alt shows its NPC ID too (`Read.lua`).

### Tooltips: room under the name; no class for friendly NPCs
Tests: 232 checks (Tooltips). Not tried in the game. `/reload` is enough.
- A row close under the one before it (`row.flush`: a guild or an NPC's title under the name) now has a gap
  `FLUSH` (1) smaller than the usual one; was the usual gap and 2 more taken away, which left none.
- A creature's class is not shown when it is friendly to you (`UnitReaction` 5 or more: vendors, trainers).

### Tooltips: a larger quest database; grey panel for dead and offline units
Tests: 231 checks (Tooltips). Not tried in the game. No new file: `/reload` is enough.
- **The quest database grows:** 4606 quests (969 of them new, mostly Forever's own, IDs 90000 and up),
  1814 NPCs, 3732 creatures; 555 KB (was 456 KB).
- **Dead, ghost or offline:** the unit's panel takes a grey colour (`GONE`), which the background's gradient
  makes grey at the top and nearly black at the bottom.

### Tooltips: auction prices of our own
Tests: 229 checks (Tooltips). Not tried in the game. A new file (`Auction.lua`): restart the game.
- **The *Auction* row** is the module's own: `Auction.lua` (new) notes the lowest buyout of each thing
  whenever the game lists auctions (`AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` / `_ADDED`,
  `C_AuctionHouse.GetBrowseResults`) in the module's saved store (`prices[item]`, `seen[item]`: the day).
  Nothing is asked of the server. A thing never seen there has no *Auction* row.

### Tooltips: our own quest database
Tests: 229 checks (Tooltips). Not tried in the game. New files (`Data/Quests.lua`): restart the game.
- **The module's own quest database,** `Data/Quests.lua`, made by a tool of ours: `QUESTS[quest]`,
  `GIVERS[npc]` (gives; takes back), `DROPS[npc]`. Strings, taken apart on demand.
- `Quests.Of(npc)`: what it drops for your quests (objective from `C_QuestLog.GetQuestObjectives`, not when
  finished), the quests in your log it takes back (`ReadyForTurnIn`), the quests it offers (by the fields
  the database has). A broken entry ends the list there.
- **The quest section** merges the game's quest lines (kill or loot) with the database's loot for your
  quests, under the same quest name; objectives written count first ("0/7 Young Nightsaber slain") are read
  too. Offers and hand-ins: the quest's name like a quest's, under it *Offers* / *Turn in* / *In progress*
  with the game's ! or ? and the quest's level in its difficulty colour.
- **Licence:** the Tooltips module has a licence of its own (`src/Tooltips/LICENSE`, TOC
  `X-License`). `dev/build` copies a module's own `LICENSE` into its addon where it has one.
- **Dead creatures:** the game's *Corpse* line is left out (the class line says *Dead*); *Skinnable* (or
  what gathering it needs) goes on the class line in the game's colour for it. A creature whose "class" is
  its own name (the game's answer for one without a class) shows none.

### Tooltips: NPC title and faction in the header; a section for experience and quests
Tests: 227 checks (Tooltips). Not tried in the game. A new file (`Quests.lua`): restart the game.
- **An NPC's title** is the game's line before its level line (*Bowyer*, *Vendor*; was: only a line in
  `<...>`), shown like a guild; **its faction** the line right after the level line (not a skinnable or
  corpse line: `NOT_FACTION`), shown after what it is (*Humanoid · Stormwind*). A creature's **class** is
  always said (was: only when not a warrior).
- **A section for experience and quests** (`QuestSection` in `Kinds/Unit.lua`), under the bars: XP and
  kills to level, then the quests (`Quests.lua`, new): each quest's name, a sword (`Interface\CURSOR\Attack`)
  before what to kill, a sack (`Interface\CURSOR\LootAll`) before what to loot with its drop chance, the
  game's ? before a quest to hand in (*Turn in* in green when complete), the game's ! before a quest it offers
  (with its level). The game's quest lines are left out when the section has the objectives.
  Without it the game's quest lines are shown in the section the
  same way: the icon now before the objective (was: at the right), its count at the right, a tick when done.

### Tooltips: spec, titles, tapped; spell columns, Healing/CC/Utility; health numbers centred
Tests: 218 checks (Tooltips). Not tried in the game.
- **Spec** (`Inspect.Talents`): on this client a class's talents are one trait tree with three groups
  (`C_Traits.GetGroupDisplayInfoByTreeID`), each with its spent points (`C_Traits.GetGroupCurrencyInfo`, as
  the game's talent frame shows them). The group with the most points is the spec: "Fire Mage 0/31/20" on
  the class line. Yours from `C_ClassTalents.GetActiveConfigID` (read again after 5 s); another player's
  with `INSPECT_TRAIT_CONFIG_ID` when the inspection for the item level answers, kept with it. The spec IDs
  of this client are one per class, so `GetInspectSpecialization` says nothing.
- **Guild rank** small after the guild (`row.label`, `detail`); a player's **title** (`UnitPVPName` less the
  name, e.g. a PvP rank), unless the name line has it already.
- **Creatures:** the title line (*<Flight Master>*, or a pet's owner: `UnitOwner` line) as large as the name,
  close under it; the family after what it is (`UnitCreatureFamily`: *Beast · Wolf*); *Tapped*
  (`UnitIsTapDenied`) on the class line.
- **Health numbers** in the middle of the bar (were raised above the power strip). A bar's words stand on a
  frame of their own over the bar (`bar.words`), so the power bar laid over the health bar does not cover them.
- **Spells in columns:** the spell's numbers in pairs of columns; a spell without numbers in one strip.
- **What a spell is** under its name for every spell: its school; else *Healing* (heal or absorb named
  first), *CC* (`STATS.controls`: stun, fear, polymorph, root, ...; blue), *Physical* (damage), *Utility*
  (no colour). A swing is *Physical*.

### Tooltips: unit header in four lines, a weapon's numbers in one, a small plaque
Tests: 212 checks (Tooltips). Not tried in the game.
- **Unit header:** the guild in the name's font (`title`), close under it (`row.flush` now works for text
  rows too: the row gap and `FLUSH` less). Race (a creature: what it is) on its own line; under it the class
  line (`ClassLine`): the class (a creature's only when not a warrior), a creature's rank (*Elite*, *Boss*
  gold; *Rare*, *Rare Elite* silver), *PvP* red, *AFK*/*DND* yellow, *Offline*, *Dead*, *Ghost* grey.
  A dead creature gives no experience.
- **A weapon in one line:** "3.2 DPS  ·  1 - 3 dmg  ·  2.00 spd": the number and *DPS* large, the rest
  smaller after it on the same base line (`row.labelFont`, placed `BASE_LINE` of the size difference
  lower). Was: *DPS 3.2* with the damage line under it.
- **The plaque** is hardly larger than its words (`PLAQUE.pad` 2, `least` 22; was 7 and 14 more than the
  words). Rows beside the portrait that reach the plaque's height make room for a plaque wider than the
  portrait (`reserve`). The plaque's settings are one table (`PLAQUE`): `Panel.Draw` was over Lua 5.1's
  60 upvalues.

### Tooltips: items short and clear, prices, spell numbers, experience, a plainer plaque
Tests: 208 checks (Tooltips). Not tried in the game. A new file (`Numbers.lua`): restart the game.
- **Item header:** the line over the name says how it binds, short as players write it (`TEXT.BINDS` by
  `Enum.TooltipDataItemBinding`: BoP, BoE, BoU, BoA, WuE, Soulbound, Quest; red until bound), or *Equipped*
  on a comparison (`head.compared`, which now alone makes a panel stand back), and whether you have the
  look (*Uncollected*, *Look known*, from the game's transmog lines). Kind and slot are small and grey
  (`detail`), the level it needs beside them; a thing that is not worn says its kind from
  `C_Item.GetItemInfoInstant` (*Trade Goods · Cloth*). *DPS* stands before the large number (was: *Damage
  per Second* after it).
- **The sell price once:** the game also writes it as a line, "Sell Price: 81" (`TooltipDataRules.SellPrice`
  → `GameTooltip_OnTooltipAddMoney`, with *Minimum*/*Maximum* lines for a range); that line is left out.
- **Prices in the footer:** *Vendor* (the game's price) and *Auction* (not for a bound thing). The
  durability bar has no price beside it any more.
- **A comparison's changes:** the sentence over them (`ITEM_DELTA_DESCRIPTION`, `..._MULTIPLE_...`) is left
  out; the changes are marked the game's own lines (normal size, not small), and "damage per second" in
  them says *DPS* (`PATTERN.DPS_WORDS`, any case).
- **Trade goods:** *Used in* with the professions that use the kind of trade good (cloth: tailoring,
  leather, metal and stone: blacksmithing and engineering, herbs, meat, enchanting, parts), named and
  pictured by the professions' spells: by the game's kinds only, no table per item.
- **Spell numbers** (`Numbers.lua`, new): a second strip with the spell's damage or healing on average,
  per second, per point of its power (`GetSpellPowerCost`) and its crit (`GetSpellCritChance`). The melee
  swing and the shots: per swing, per second, speed, crit (`UnitDamage`, `UnitRangedDamage`). The first
  strip's cost also says its share of your mana.
- **Creatures:** XP for a kill by the original game's rule (level difference, grey
  level, elite ×2, rested ×2) and kills to your next level; a creature's class when it is not a warrior.
  Nothing is recorded (kills, loot, drop rates, *Dropped by*).
- **The plaque** is a gold rectangle with a soft edge (`Art/plaque.tga`, 32 x 32, made by
  `dev/tools/tooltip-art`, sliced; gold gradient). Was: the game's gold dialog plaque in three pieces.

### Tooltips: a unit's target above its health
Tests: 180 checks (Tooltips). Not tried in the game.
- The *Target* row comes first under the header's divider, above the health and power bars (was: under them).

### Tooltips: dragons closer, none for creatures without a rank
Tests: 180 checks (Tooltips). Not tried in the game.
- A creature without a rank has no dragon again (silver stays for rares and rare elites).
- The dragons are moved 4 to the left (`DRAGON_LEFT`): the portrait's round picture is a little narrower
  than its square, and a screenshot showed a gap between it and the dragon's body.

### Tooltips: the side's emblem in the top left corner
Tests: 180 checks (Tooltips). Not tried in the game.
- A player's side emblem hangs by its top left corner on the panel's top left corner, 2 in (was: centred
  on the right side, 8 in). The game's emblem picture has an empty border, so it is cut to the emblem
  itself (`SetTexCoord`, the edges measured from the art: `EMBLEMS` in `Panel.lua`) and drawn at the same
  scale as before. Alpha and layer are unchanged.

### Tooltips: narrower soft edge, also on bars and buff icons
Tests: 179 checks (Tooltips). Not tried in the game.
- The icons' and portraits' soft edge is narrower (the outer 6 of 64 fade, was 10).
- A unit's bars (and a buff's bar) fade out at their edge too: `Art/bar-mask.tga` is soft now (3 of 16).
- A unit's buff icons have a soft edge: `Art/aura-mask.tga` (new, 32 x 32), one mask for each icon
  (`Live.lua`).

### Tooltips: soft icons, silver dragon for every other creature
Tests: 178 checks (Tooltips). Not tried in the game.
- **Icons and portraits fade out at their edge** like the panel's border: `Art/icon-mask.tga` is now soft
  (round corners, the outer 10 of 64 fading), and portraits have `Art/portrait-mask.tga` (a circle, the
  same fade); one mask on the icon, its picture chosen by the kind. The frame behind a square icon is gone,
  and with it `Art/round.tga`, which nothing uses any more.
- **The silver dragon** goes round every creature's portrait that is not an elite or a boss (rare, rare
  elite, and those without a rank); the dragons' key `rare` is now `silver`.

### Tooltips: the target frame's dragons
Tests: 177 checks (Tooltips). Not tried in the game.
- **The dragon round a portrait is the game's own from its target frame** (`Interface\HUD\UIUnitFrameBoss2x`,
  as `GetBossPortraitFrameData` picks it): gold winged for a boss (`UnitIsBossMob`, or `worldboss`), gold
  for an elite, silver winged for a rare and a rare elite, and gold for every player. Was: the gold dialog
  dragon, turned, for elites only. Each dragon's box on the sheet and the middle and inner radius of the
  circle it curls round were measured from the art (`DRAGONS`, `DRAGON_RING` in `Panel.lua`); it is
  scaled so that the circle lies on the 64 portrait and covers its edge by 2, and placed by the
  portrait's middle. The sheet has no atlas file in the reference, hence the measured numbers.

### Tooltips: the game's gold plaque, item level on it, power over health
Tests: 174 checks (Tooltips). Not tried in the game.
- **The plaque is the game's own,** from the same set as the dragon: the title plate of the gold dialog box
  (`Interface\DialogFrame\UI-DialogBox-Gold-Header`: gold metal frame with rivets round a worn bronze
  field), in three pieces by `SetTexCoord` (ends 22, middle 104 of its 256 pixels, 42 high) so it can be
  as wide as its words. Was: `Art/round.tga` twice with a gradient. Its right side stays where a plaque with
  a level alone has it (46 wide round the icon's middle); longer words reach left. All its words are
  outlined: a unit's level in its difficulty colour, an item level light.
- **A player's item level is on the plaque,** "iLvl 50 - 60" (`TEXT.PLAQUE`; the dash in the item level's
  light colour, the level in its own), not in a row of its own;
  until another player's answer has come, the plaque has the level alone.
- **The power bar lies over the health bar's lower part** (5 high, nothing behind it, so an empty one is
  not a black bar); the health bar is 18 high, its numbers centred in the part above the power bar.

### Tooltips: fixes after a look at a buff
Tests: 173 checks (Tooltips). Not tried in the game.
- **Fixed: a square icon was cut to a thin strip, and the bars' corners stayed square.** A mask with slice
  margins does not keep its corners in the game. The masks are now pictures of their own shape, stretched
  whole: `Art/icon-mask.tga` (64 x 64) and `Art/bar-mask.tga` (256 x 16, so that over the bars' size its
  corners stay about round). `dev/tools/tooltip-art` makes them; `soft.tga` and `round.tga` are unchanged.
- **Other addons' ID lines are left out** ("Spell ID: 1459", "IconID  135932": `Read.IsIdLine`, a whole
  line of words ending in ID with a number): the section that Alt shows has the numbers. They had stood
  among a buff's lines, full size, with the number coloured.
- **A buff's time line** is the game's last own line that has a number in it and is not the description
  or an ID line (was: its last own line that is not the description).
- **A buff's bar is wide enough** for the time and the caster written inside it.

### Tooltips: a player's item level
Tests: 172 checks (Tooltips). Not tried in the game.
- **A player's item level** in a row of its own under *Target* (`Inspect.lua`, new). Yours from
  `GetAverageItemLevel`; another player's by inspecting them (`NotifyInspect`, `INSPECT_READY`,
  `C_PaperDollInfo.GetInspectItemLevel`), paced:
  out of a fight, `CanInspect`, `CheckInteractDistance(unit, 1)`, not with the inspect
  window open, one question at a time and 2 s after anybody's (`NotifyInspect` hooked), 15 s before the
  same player again, 5 s until an answer counts as lost; kept 5 minutes, at most about 200 players.
  `ClearInspectPlayer` after reading, unless the inspect window is open. The panel shows an ellipsis
  while the answer is on its way and is drawn anew when it comes.
- **A unit's level is coloured by its difficulty again** (`badgeR`, `badgeG`, `badgeB` are back), outlined
  so it reads on the plaque; an item's level stays dark brown. The plaque is quieter: a muted gold at
  alpha 0.75, the edge at 0.85, the light line at 0.3.
- **PvP stands at the end of the race and class line,** in red (a colour code inside the line).

### Tooltips: round icons, gold plaque
Tests: 167 checks (Tooltips). Not tried in the game.
- **Square icons have round corners:** a mask (`Art/round.tga`) on the icon, added for an item's or a
  spell's icon and taken off for a portrait; the frame behind the icon is `Art/round.tga` too (was a
  square), 2 larger on each side.
- **The level is on a gold plaque** at the icon's lower edge: `Art/round.tga` twice (a bronze edge, and a
  gold gradient inset by two pixels) with a light line along its top; the number in dark brown, in the
  title's font. The badge colours (`badgeR`, `badgeG`, `badgeB`) are gone from the model: a creature's
  level is no longer coloured by its difficulty.
- **The elite's dragon is 116** (was 140), its top left 71 left of and 34 over the panel's top right
  corner, so its tail covers the icon's lower edge too, under the plaque.

### Tooltips, a third look
Tests: 165 checks (Tooltips). Not tried in the game.
- **With Alt held, every panel shows its technical details** in a small section at the bottom
  (`Read.lua`, `Details`): the number of the thing at the left (*Spell ID* for spells, buffs and pet
  abilities; *Item ID*, *Quest ID*, ... after the name of the tooltip data's kind; *NPC ID* from a
  creature's GUID; a player's GUID), its icon's at the right (*Icon ID*). `MODIFIER_STATE_CHANGED` for
  Alt reads the shown panels anew.
- **A buff's time is inside its bar:** the game's line for how long it still runs (its last line of its
  own that is not the description) is taken from the rows and written into the bar at the left, the
  caster at the right (`BarText`); the bar is a `LiveBar` like a unit's (flat, half see-through, 16
  high, round corners).
- **The icon stands out over the corner** (10 past the right side, 10 over the top); the dragon keeps its
  place, now set from the panel's corner, and covers the icon's edge.

Tests: 157 checks (Tooltips). Not tried in the game.
- **Fixed: the game's tooltip sometimes showed under a panel.** The game sets a tooltip's alpha itself when
  it shows it and while it fades it out (a creature's, after the mouse left it), so alpha 0 on the tooltip
  did not hold. Now each part that can be seen is made invisible too (`Native.lua`, `FadeParts`: the
  border, the lines, `<name>Texture1..30`, `<name>StatusBar`, the money frames, `CompareHeader`); their
  alphas are noted and given back by `Release`.
- **The icon** is 64 (was 40) and stands in the top right corner (12 in, 4 down); the level or item level
  sits on its lower edge, outlined. The elite's dragon is 140 and placed by the icon, the middle of its
  open side on the icon's middle, drawn over the icon.
- **A unit's bars** are one block with round corners: a mask (`Art/round.tga`, new, made by
  `dev/tools/tooltip-art`) on both bars' fills and tracks.
- **Dividers** two pixels dark (alpha 0.55) and one light (0.10); were one each (0.45, 0.07).
- **Opacity** 97 at first (was 90). The module's saved settings have a version now (`version = 2`): a saved
  90 is taken for the old default and becomes 97; the gone setting `border` is removed.

Tests: 153 checks (Tooltips). Not tried in the game.
- **Fixed: the comparison of what you wear jumped between two places** with the mouse still. The game
  places comparison tooltips by the tooltips' sizes (side and slide in `AnchorShoppingTooltips`), and the
  module made each tooltip as large as its panel with padding, which the game took away and the module put
  back: two sizes, two places. The game's tooltips are no longer changed but for their alpha
  (`Native.lua`: `Fit` and the padding are gone). A panel whose tooltip the game placed beside another
  tooltip with a panel is placed beside that panel instead (`Beside`), by its own size.
- **Hints get panels too:** lines written into a tooltip without data (a button's name and explanation).
  `GameTooltip`, `ItemRefTooltip`, `ShoppingTooltip1/2` are hooked at login; a tooltip shown after it was
  cleared with no data told is drawn at the end of the frame as `Read.Generic`, its name as written.
  Only tooltips with a bar or a frame inside, or with a hidden line, stay the game's.
- **Units:** health and power bars are a flat colour at half alpha (`LiveBar`: one bar each, kept apart
  like the live texts), the health bar 16 high with "current   percent" written on it in a small font, the
  power bar 8 high right under it; the health text row is gone. Guild, race and class, kind and PvP use a
  new small font (`detail`, text size - 4); PvP is always "PvP" (the game's word is "Player vs. Player").
  No frame behind a portrait.
- **The elite's dragon** is 128 large, turned to look left (`SetTexCoord(1, 0, 0, 1)`) and lies round the
  top right corner, under the portrait and the texts.

### Core: the error log
Tests: 64 checks (Core and Settings).
- **Every problem is kept in a log** (`Core.log`, saved as `SaneUIDB.log`): time, label, the text with the
  place it happened, the addon's version, the game's build; newest last, the newest 100, the same problem
  twice in a row counted in one entry. `Core.NoteError` writes it. The log file is the saved settings
  file (an addon cannot write another): the game writes it at a `/reload` or a logout.
- **Errors nothing of ours caught are noted too:** at login Core hooks the game's error window
  (`hooksecurefunc(ScriptErrorsFrame, "DisplayMessageInternal", ...)`) and notes the errors that name a
  Sane UI addon, with their stack. The game's own error handling is not touched.
- **`dev/tools/errors`** prints the log from the game's saved settings file (`10`, a number, `all`, `short`).
- `/sane errors` says how many entries the log has; `/sane errors clear` empties it too.

### Tooltips, later the same day
Tests: 57 checks (Tooltips). Not tried in the game.
- **Tooltips are drawn anew on panels**, in a layout of their own: header (name in capitals, a line under
  it, icon at the right), divider, a spell's strip (cost, cast, cooldown, range), the other lines in rows
  with rules, another addon's lines small at the bottom, a health bar for units. Was: art behind the
  game's own lines. The game's tooltip stays under the panel, invisible (alpha 0) and padded to the
  panel's size.
- New files: `Texts.lua` (own words; the English patterns for the strip), `Read.lua` (lines into a model
  that is filled in place and says whether it changed), `Panel.lua` (frame, pools, layout), `Native.lua`
  (alpha, padding, corner; given back). `Skin.lua` is gone. `Look.lua` also returns the unit.
- **New switch *Anchor tooltips to the mouse cursor***, off at first: a hook on
  `GameTooltip_SetDefaultAnchor` sets `ANCHOR_CURSOR_RIGHT`. The switch *Colour the border* is gone.
- A tooltip is left to the game when it is plain lines, holds a bar, an item or another frame, or has a
  line the game hides.
- **Fixed: a tooltip flickered between its panel and the game's own**, mostly with a comparison open
  (seen in the auction house). Two causes. The game shows its comparison tooltips with `SetShown`, which
  makes a tooltip visible at full strength like `Show` but was not hooked. And data the game adds to a
  filled tooltip came as a fill of its own: read by that data alone, the price was not found, the coins
  counted as something a panel cannot show, and the tooltip was given back until the next fill. A tooltip
  is now always read by the data it was first filled from (`GetPrimaryTooltipData`). A tooltip that is
  cleared and shown before it is filled stays invisible until the next frame decides. Tests: 60 checks.
- **Fixed: the comparison panels changed their size several times a second.** The game tells us a
  comparison tooltip is filled and then goes on writing into it (what would change), on every refresh.
  The panel was drawn short at once and long a frame later. A filled tooltip is now drawn at the end of
  the frame (`Filled` queues it, a frame of the module's that only runs while one waits draws it:
  `Settle`); hidden and filled again in one go, the old picture stays until then. The same lines again
  draw nothing. Also: a comparison's panel hangs on the side that faces the tooltip it belongs to
  (`Native.lua`, `Corner`: a tooltip held by several points), and padding is given back on a hidden
  tooltip too. Tests: 66 checks.
- **Look, after the first try in the game** (`Panel.lua`): the divider with the diamond is gone; the
  strip's captions stand over their values, and every value is equally bright (one the tooltip left out
  was grey); the panel is built from `TooltipBackdropTemplate`, so it has the round corners of the game's
  tooltips, its border tinted with the tooltip's colour (the four flat edges are gone); padding 10
  (was 19), icon 30 (was 38), the header no taller than its lines or the icon, rules and rows closer.
- **New setting *Text size*** (10 to 20, 14 at first; a slider, which the Settings module shows for an
  option with `min` and `max`). Name and lines are that size, the strip's values and the subtitle 2
  smaller, another addon's lines 3, captions 5. The font file is asked of the game's font objects
  (`GameTooltipText`, `GameTooltipHeaderText`) at every draw and only the size is set (`SetFont`): the
  one place where a size of our own is used, because the size is the player's choice.
- **The comparison's tooltip of what you wear** says so at its top, inside the panel, in gold capitals
  (the text of the game's own tab, `CompareHeader.Label`), and its panel is drawn at alpha 0.85.
- **The test realm's line "Press F6 to submit an issue for this ..."** is left out (`Read.lua`,
  `IsFeedback`: known by the start of `PTR_IssueReporter.BugTooltipString`). Tests: 73 checks.
- **A layout for each kind of tooltip**. Tests: 108 checks. Not tried in
  the game.
  - New structure: `Model.lua` (head and rows as data, in two copies that are compared after a fill;
    replaces the fixed fields of the old model), `Read.lua` (the lines and the tools to sort them), one
    file per kind in `Kinds/` (`Item`, `Spell`, `Unit`, `Aura`, `Quest`), `Live.lua` (what changes while a
    panel is shown). `Look.lua` is gone, its parts are in the kinds.
  - **Items:** kind and slot; binding (red while `bonding` is bind on pickup, equip or use) with the
    needed level beside it; item level under the icon; damage per second or armour large; durability as
    a small bar with the price beside it. Recipes: caption *Creates* and the product's icon at the
    `NestedBlock` line. The lines are known by `DPS_TEMPLATE`, `ARMOR_TEMPLATE`, `ITEM_MIN_LEVEL`,
    `DURABILITY_TEMPLATE`, `ITEM_LEVEL` where the client has them, else by the English wording.
  - **Spells:** school from the description (English words, kept per spell), as the panel's colour and a
    word under the name; green for a heal, red for plain damage; the description's numbers coloured.
  - **Units:** name (class colour), guild, race and class or creature type, PvP, portrait
    (`SetPortraitTexture`) and level; health text, health bar, power bar; target; buffs and debuffs
    (outside a fight only); the side's emblem; a dragon for elites; a sword or a bag beside quest
    objectives. The tooltip's own lines for guild, class, level, side and PvP are left out.
  - **Buffs:** kind and dispel type, caster, a bar on the game's timer (`SetTimerDuration`). The buff is
    found from the tooltip's `getterName` and `getterArgs`.
  - **Quests:** level, state (`C_QuestLog`), objectives under a caption with boxes and counts.
  - **Look:** one gradient in the panel's colour, no band behind the name; dividers are a dark hairline
    with a faint light one under it; padding 14 (was 10), icon 40 (was 30).
  - **New setting *Opacity*** (30 to 100, 90 at first): the background's alpha.
  - A player's specialisation is not shown: there is no way to it without inspecting.
- **Fixed: after the update above and only a `/reload`, no panel was shown at all.** The game learns an
  addon's files when it starts; a `/reload` reads those anew but not files added since, so `Model.lua`,
  `Live.lua` and `Kinds/` were missing, the first tooltip failed and the module stood down. At login the
  module now checks that every file has left its part (`PARTS` in `Tooltips.lua`); if one is missing it
  asks in chat for a restart of the game and leaves the tooltips to the game, without an error.
  `ns.StandDown` no longer needs `Panel.lua` and `Native.lua` to be there. Tests: 109 checks.
- **Fixed: an error at the first tooltip after a unit's** (`Panel.lua: attempt to perform arithmetic on a
  secret number value`, found in the saved error list). The texts for a unit's health and its target came
  from the pool of texts; once given a hidden number, such a text answers with hidden numbers when asked
  for its width, and the next draw used it for an ordinary line and measured it. These texts are now kept
  apart (`LiveText`), one for each use and never measured. A hidden name of a target is handed to the
  text as it is. `Guarded` keeps the stack of an error for the log (`xpcall` with `debugstack`).
- **No border.** The panel is a plain frame; its background is drawn with a picture of our own,
  `Art/soft.tga` (a white square with round corners and a soft edge, made by `dev/tools/tooltip-art`),
  stretched with slice margins, coloured by the gradient and reaching 8 past the panel's sides, so the
  edge fades out softly. `TooltipBackdropTemplate` is no longer used. Tests: 163 checks.

### Spellbook, later the same day
Tests: 247 checks (Spellbook) and 243 more with the Settings module switched off.
- **The Home tab was under the spellbook's round icon.** It now stands where the row of the game's tabs
  began, and that row is moved 46 to the right while the pages are the module's (`Home.lua`, `PlaceTabs`;
  place only, put back on a fallback; in a fight, if the row is locked, Home takes the gap as before).
- **Home: quest rewards by level.** Small headings *Level 10*, fainter for a level not reached yet. A row
  says the place of the quest; the level is no longer in the row.
- **Home lists no weapon skills** under *At your trainer now*: the class trainer does not teach them.
- **General tab: two sections.** *Passive spells to learn* holds every passive spell to come (they are
  no longer in the class tabs or under *Other spells to learn*); *Skills to learn* holds weapon skills.
  New: `Data/WeaponSkills.lua`, `Sources.UnlearnedPassives`, `Sources.UnlearnedSkills`, entries with
  `skill = true`, the stats field `skill`. `Sources.Unlearned(tab, showRanks)` lost its third value.
- **Ranks fold into one entry** when *Show all spell ranks* is on (`Book.lua`, `Fold`): the highest rank
  you have or the lowest to learn stays, with a "+" button; the others' entries are parked. Unfolded, the
  ranks are a section under the tab's spells with a "-" heading. Kept until `/reload`. A folded entry
  carries the reserved clock for all its ranks (`BookItem.Set`, sixth value `family`).
- **`Layout.Paginate`:** a header may say its `height` and a group its `gap`, for small subsections.
- **A checkbox *Show hidden spells*** left of the page buttons (`SaneUISpellbookShowHidden`), the same
  switch as in the menu and the options; hidden while Home is on show.

### Removed
- **The built-in training list** and all that only it used: the folder `src/Spellbook/Training` with its
  tab, window, menus, art, key binding (`Bindings.xml`) and saved variables, `/sane sb train`, its line in
  the spellbook's menu, and the tool that built the folder. `dev/tests/lint` allows no globals but Sane UI's
  own.
- **`BINDING_HEADER_SANEUI`** in Core: no module has a key binding any more.

### Changed
- **`CLAUDE.md`, Workflow:** new rule *Parallel sessions*. Several Claude sessions may work in the folder
  at once on different modules; each keeps the others' changes, merges into the current file content and
  commits only its own files by path.
- **The trainer data** moved to `src/Spellbook/Data/Classes/`, the quest rewards to `Data/QuestSpells.lua`,
  read through `ns.Data` (`Data/Trainer.lua`, new).
- **`Sources.lua`** reads `ns.Data`. A spell whose texts the game has not fetched yet is asked for and listed
  when the answer arrives (was: the training code's own cache did that). The stats field `data` is the same.
- **A grey entry's tooltip** shows the trainer's base price as one line.
- **Module titles** in the addon list are the plain names: *Settings*, *Spellbook*, *Tooltips* (were
  *Sane UI Settings*, ...). The minimap's addon list shows *Settings*.
- **Settings is load-on-demand** (`## LoadOnDemand: 1`). Core loads it when the game's options window opens
  (hook on `SettingsPanel` `OnShow`) or on `/sane options`, which is now Core's command and says so when
  the module is switched off. `Core.LoadSettings()`.
- **Core starts a module that arrives after the login:** `OnLoad`, then `OnLogin` at once.
- **A module's options page is called "Sane" and its name** (*Sane Spellbook*, *Sane Tooltips*): that is
  the entry under *Sane UI* and the title at the top of the page.
- **The reserved mark** in the spellbook is a small clock (atlas `auctionhouse-icon-clock`), was a tick.
  With *Show all spell ranks* on, only the rank that was dragged onto the button carries it and says
  *Reserved on ...*; with one icon per spell, that icon does.
- **`Book.lua`:** `Book.SetHome(on)` parks every entry and hides the page buttons while Home is on show;
  `Book.Armed()`; the messages `BOOK_PAGES` (pages taken or given back) and `BOOK_JUMP` (the game jumps
  to a spell). `BookItem.Set` takes a fifth value, the text of the third line.
- **Version 0.3.0** in all four TOCs (Tooltips was added at 0.2.0).
- **Tests:** the stand-in client loads an addon on demand, knows a spell's rank line and whether its texts
  are there, the faction and the race. `spellbook.lua` feeds `ns.Data` and has a row of tabs.

### Added
- **Module Chat** (`src/Chat`, addon `SaneUI_Chat`), a first prototype: a chat window in the style of a
  messenger. Every message is a bubble, yours at the right, everybody else's at the left with class icon,
  name, the chat's name and the time; the system's lines and emotes are centred notes. The window is
  moved by its top bar and sized by a grip in the lower right corner (smallest 180 × 130); place and size
  are kept in Core's settings. A bubble takes a share of the window's width, so the messages wrap anew
  when the width changes. `/sane chat`, `/sane chat reset`. Files: `Chat.lua` (events, command, fall-back), `Log.lua` (what an event says, the
  last 200 messages), `Layout.lua` (sizes and the arithmetic from the width), `Bubble.lua` (one message,
  measured and drawn), `Window.lua`. Built from `TooltipBackdropTemplate`, `WowScrollBoxList` with an
  extent calculator, `MinimalScrollBar`, `PanelResizeButtonTemplate`; no art shipped.
- **Chat: the line to write in** (`Input.lua`). It is the game's own edit box, anchored to the bottom of
  our window whenever the game shows it (`ChatFrame.OnEditBoxShow` / `OnEditBoxHide` of `EventRegistry`),
  so Enter, `/`, slash commands, `/w`, `/r`, history and name completion stay the game's. The list of
  messages ends above it while it is shown (`Layout.INPUT`) and keeps the newest message in view. Its own
  anchors are put back when our window goes.
- **Chat: the list of chats to write in.** A click on the line's label (*Say:*, *Guild:*) opens a menu of
  the chats you can write in now (`Channels.lua`: say, yell, party, raid, instance, guild, officer, the
  channels you joined). The choice is set with the edit box's own `SetChatType`, `SetStickyType`,
  `SetChannelTarget` and stays until another is chosen or typed.
- **Chat: the game's own chat is out of sight while our window is open** (`Native.lua`): its windows,
  the tabs of undocked ones, the dock and its buttons get a hidden parent, and their own back when our
  window is hidden (`/sane chat` now switches between the two) or the module fails. The game's chat goes
  on collecting, so it is complete when it comes back.
- **Chat: printed lines.** What `print` and the game write into the main chat window without a chat event
  (`/sane`, error notes, help texts) is shown as a note (`Log.Note`; a hook on its `AddMessage`, lines
  without a chat type number).
- **Chat: the line to write in is only there while you write.** An empty line without the cursor is
  hidden (the game's IM style would keep it on show, faded and without the chat's name). A button with
  the game's chat icon at the right end of the window's bar opens and closes it (`Input.Toggle`). The
  tooltip on the chat's name is gone.
- **Chat: the newest message is at the bottom.** A few messages stand at the bottom of the window: the
  list's view gets the free room as top padding (`Window` `Settle`, `Layout.ListHeight`).
- **Chat: messages fade out, each by itself** (`Bubble.Fade`, an animation group per row), not while the
  mouse is over the window or the line to write in is open. Two settings on the module's options page:
  *Fade messages out* (on) and *Seconds before a message fades* (60; 5 to 300).
- **Core and Settings: a number as a setting.** An option described with `min`, `max` and `step` is shown
  as a slider (`Settings.CreateSliderOptions`, `CreateSliderInitializer`); the stand-in client knows both.
- **Chat: the window has no background and no border.** Its title, grip, scroll bar and chat button are
  only shown while the mouse is over it (and while a mouse button is held). The chat button moved to the
  lower left corner, as high as the line to write in, which now starts right of it.
- **Chat: drawn above the action bars** (strata `MEDIUM`, frame level 100), all parts as one; the game's
  edit box gets the window's strata instead of `DIALOG` once it is shown.
- **Chat: a message the list's top edge cuts is hidden** (`Window` `Trim`, `Bubble.Cut`; a row's content
  is now one frame inside the row).
- **Chat: round class icons with a ring** for what the speaker is to you: yellow friend, green guild,
  purple raid, blue party (`Log.lua` `Tie`, `Layout.TIES`). The name above a bubble is as large as the
  message; the chat's name and the time stay small, beside it.
- **Chat: a setting *Text size*** (10 to 24, at first 14). A font object of the module (`SaneUIChatFont`)
  copies the game's chat font and sets the size (`Bubble.Size`).
- **Chat: bubbles without a border.** A bubble is a plain fill with round corners (`Plate.lua`, new: two
  bars and four masked dots of plain colour; `Layout.RADIUS`), no longer `TooltipBackdropTemplate`.
- **Chat: bubbles half see-through, and a setting *Bubble transparency (%)*** (0 to 100, at first 50;
  `Bubble.Clear`, `Window.Repaint`). For that the plate's pieces no longer lie over each other: quarter
  dots in the corners, a bar above and below, the middle. The ring around an icon is 1 pixel (was 2).
- **Chat: the line to write in is drawn as your own bubbles** (`Bubble.Yours`, `Input.Paint`): the same
  plate, colour and transparency; it follows the transparency setting. `Layout.WRITE` is gone.
- **Chat: a setting *Short chat names*** (on): above a message the chat is named by the first letter of
  each word of its name (`Channels.Brief`; `entry.short`).
- **Chat: what the window shows can be chosen.** The list on the chat button and on the chat's name has
  a tick for every kind of chat and every channel you are in (`Channels.Shown`); a message carries its
  group (`entry.group`), the switched-off ones are kept in the module's store (`mute`), and the window
  shows the log without them (`Window.Refill`). The stand-in's menu checkboxes carry their data.
- **Chat: links in messages answer the mouse** (`Links.lua`, new): over an item's, spell's, quest's link its
  tooltip (`GameTooltip:SetHyperlink`); a click is the game's own (`SetItemRef`).
- **Chat, fixed: the bubbles' corners** were small whole circles (seen in the game): a mask's texture
  coordinates do not pick a quarter of it. A corner is now a square under the whole mask, twice its size.
- **Chat, fixed: unticking a channel in the list** did not hide its messages (reported from the game). A
  channel's messages were matched to the list by name; now by the channel's number (`"CHANNEL:2"`).
- **Chat: a setting *Show native chat*** (on): the game's own chat stays on show next to the window; switched
  off it is out of sight as before (`Window.Native`). The line to write in is ours either way.
- **Chat: a white ring** around the class icon of somebody who is nothing to you (`Layout.TIES.none`).
- **Chat: the line to write in has the same look and grows with its text.** The game's border art
  around the edit box is invisible, a plate lies behind it; the edit box wraps its text
  (`SetMultiLine`) and is as tall as the text needs, up to 6 lines (`Input.lua` `Dress`, `Grow`,
  `Layout.InputHeight`); the window's room for it follows (`Room(height)`). Undone when the window goes.
- **Chat: the chat button opens the line and the list of chats** (the one you write in marked); a click
  on the chat's name shows the same list.
- **Chat:** the window follows the newest message by a flag set from the list's `OnScroll`, also when it is
  sized smaller or the line to write in opens.
- **Tests:** `dev/tests/chat.lua` (68 checks), run by `dev/tests/run`. The stand-in client hands out its
  widget methods (`W.methods`) so a test can add what its module needs of a widget, and its menus know
  radio lines.
- **Spellbook: the Home tab and page** (`Book/Home.lua`). A button of the module that looks like an icon
  tab (the game's tab art, the hearthstone icon), left of the spellbook's first tab; the game's tabs are
  not touched. Its page lists what the trainer teaches now with prices and their total, and the quest
  reward spells with the place of the quest or the level needed. The spellbook opens on it; a click on
  another tab, a search or a jump to a spell closes it. Laid out with `Layout.Paginate`; what does not
  fit is counted in a line.
- **Spellbook: the switch *Open the spellbook on its Home page*** (on).
- **Spellbook: a yellow "!"** (atlas `QuestNormal`) on the icon of an unlearned spell that is a quest reward
  (the trainer does not sell it). Other unlearned spells carry none.
- **Spellbook: the reserved button on the action bar** carries the same clock as the spell in the
  spellbook, and shows the spell's tooltip (a hook after the button's own `OnEnter`).
- **Module Tooltips** (`src/Tooltips`, the addon `SaneUI_Tooltips`): a new look
  for the game's own tooltips. The tooltip is not replaced: its lines, size and place
  stay the game's, and the module puts art behind them. A dark background and a band behind the first
  line (two textures of the tooltip, anchored to the border's centre and to `TextLeft1`), the game's
  border tinted (`NineSlice:SetBorderColor`), and the icon of items and spells in a frame from
  `TooltipBackdropTemplate` on top of the left corner.
  - `Look.lua`: colour and icon from the tooltip's data. Item and toy: quality and icon; spell and aura:
    icon; player: class colour. Everything else takes the colour of its first line.
  - `Skin.lua`: the art. No art file is shipped.
  - `Tooltips.lua`: dresses a tooltip after `TooltipDataProcessor`'s post call for all types, and on
    `OnShow`/`Show` for lines written in by hand. Three switches: border, class colours, icons.
  - An error takes the art from all tooltips and leaves the game's own for the session (`ns.StandDown`).
  - Not tried in the game yet. Not in it: own panels and layout, a style
    editor, stat colours and markers, badges, spell school colours, drop tables, follow-cursor.
- `dev/tests/tooltips.lua` (43 checks), run by `dev/tests/run`. `wowstub.lua` lets an addon probe for
  `TooltipDataProcessor`, `TooltipBackdropTemplateMixin`, `UnitTokenFromGUID` and the tooltips by name.

## 0.2.0 (2026-10-14)
The split into three addons is not yet tried in the game. Tests: lint, 56 checks (Core and Settings),
204 checks (Spellbook) and 201 more with the Settings module switched off.

### Changed
- **One addon per module.** Sane UI was one addon folder with one TOC. Now Core is the addon `SaneUI`
  (*Sane UI* in the addon list) and every other module an addon of its own under it: `SaneUI_Settings`
  (*Sane UI Settings*) and `SaneUI_Spellbook` (*Sane UI Spellbook*). Each can be switched on and off by
  itself. Their TOCs say `## Dependencies: SaneUI` and `## Group: SaneUI`.
- **A module depends on Core only.** Spellbook no longer needs Settings: it runs the same with the Settings
  module switched off, without its options page.
- **Shared table:** the addons find each other in one global table, `SaneUI` (was the table the game hands
  the files of one addon). A module's own table is the one the game hands its addon:
  `local ADDON, ns = ...`, then `Core.NewModule(ADDON, "Spellbook", ns)` (was `Core.NewModule(name)`).
- **Start of a module:** `OnLoad` runs when the module's own addon is loaded (was: when Sane UI was).
- **Saved settings moved from Settings to Core** (`Core/Saved.lua`): `Core.Store`, `Core.Character`,
  `Core.Options` (were `Config.Store`, `Config.Character`, `Config.Options`). `SaneUIDB` keeps its shape
  and stays in `SavedVariables/SaneUI.lua`, so reservations, layouts and switches carry over.
- **Settings is the options module only.** It reads the described switches from Core at login
  (`Core.described`, `Core.optionOrder`), so the order in which the game reads the modules does not matter.
- **The options:** *Sane UI* is a general page and has one page per module that is switched on under it
  (`Settings.RegisterVerticalLayoutSubcategory`). Was: one page with a heading per module. A module that
  is switched off, or has no switches, has no page.
- **Rows of the options pages** go in through `Settings.RegisterInitializer` (the game's own code adds
  them) instead of `Settings.CreateCheckbox` and `layout:AddInitializer` (addon code added them).
- **The minimap's addon list** shows *Sane UI Settings* (was *Sane UI*): the entry belongs to the Settings
  module and is gone when that is switched off, as is `/sane options`.
- **The training list's own settings** (`SaneUITraining_...`) are declared by `SaneUI_Spellbook` and saved
  to `SavedVariables/SaneUI_Spellbook.lua` (was `SaneUI.lua`).
- **Art paths:** `Interface\AddOns\SaneUI_Spellbook\Training\...`.
- **Files:** `src/SaneUI.toc` is `src/Core/SaneUI.toc`; `src/Bindings.xml` is `src/Spellbook/Bindings.xml`
  (the key binding goes with the module). New: `src/Core/Saved.lua`, `src/Settings/SaneUI_Settings.toc`,
  `src/Spellbook/SaneUI_Spellbook.toc`. In the game the files of an addon no longer sit in a folder named
  after the module (`SaneUI/Core.lua`, `SaneUI_Spellbook/Spellbook.lua`).
- **Icons:** a gear for *Sane UI*, the engineering icon for *Sane UI Settings*, the book stays with
  *Sane UI Spellbook*.
- **`dev/build`** builds one folder per addon into `BUILD` (`BUILD/SaneUI`, `BUILD/SaneUI_Settings`,
  `BUILD/SaneUI_Spellbook`), each named after the TOC in its `src` folder and each with `LICENSE.txt`, and
  copies them all into the game. An addon folder in `BUILD` that no module makes any more is removed; one
  in the game is only named.
- **`dev/tests/lint`** checks every module's folder: one TOC, its files both ways, the dependency on
  `SaneUI`, the group, and that all TOCs share game version and addon version.
- **Tests:** the stand-in client loads a file as one of several addons and knows pages under a page.
  `core.lua` starts Core, then modules as addons of their own, then Settings. `spellbook.lua` reads Settings
  after Spellbook, and runs a second time without it (`--no-settings`).
- **The tool that builds the training list** writes the new first lines (`local _, ns = ...`) and the new
  art path.

### Added
- **A general switch,** *Say in chat when something goes wrong* (on): the first on the general options
  page. Switched off, problems are still kept for `/sane errors`.
- **`/sane`** says which modules are switched on, or that none is.

### Project
- **`CLAUDE.md`:** *Architecture*, the rows `src/` and `BUILD/` and the *Build* line describe one addon per
  module (was: one addon with one TOC, Settings as a base module next to Core).
- **Guides:** `addon-standards.md` (grouped addons, the shared table, where a module's settings are kept,
  a checklist line) and `gui-development.md` (pages under a page, rows through `RegisterInitializer`).
- READMEs of the project and of the three modules.

## 0.1.0 (2026-10-14)
Not yet tried in the game. Tests: lint, 45 checks (Core and Settings), 203 checks (Spellbook).

### Added
- **The addon Sane UI** (`src`, interface 16001, addon list category *Sane UI*): one addon folder,
  one TOC, one folder per module, each with a README.
- **Core** (`Core/Core.lua`): `NewModule` with `OnLoad`/`OnLogin` in TOC order, `Print`, `On` (game events),
  `Safe` and `NoteError` (errors caught, told once, kept), `Plain`/`Secret`, `Command` (`/sane <word>`),
  the character (`class`, `charName`, `charKey` = GUID).
- **Settings** (`Settings/Settings.lua`): one saved table `SaneUIDB` (`modules.<Module>`, its `options` and
  `chars`, `errors`); `Options`, `Store`, `Character`; a page in the game's own options built with
  Blizzard's vertical settings list; `/sane options`; the minimap's addon list opens it.
- **`/sane errors`** lists the kept errors, `/sane errors clear` forgets them. Errors carry a date.
- **Spellbook module** (`Spellbook/`): the former addon *Actionbar Organizer* 0.3.0, on Core and Settings.
- Spellbook's four switches are also on the options page; the spellbook's menu and the page share their
  texts (`ns.OPTION`). New on the page: *Let Sane UI lay out the spellbook's pages*.
- Spellbook warns when *Actionbar Organizer* is loaded next to it.
- **`dev/build`**: tests, builds `BUILD/SaneUI` (no READMEs, plus `LICENSE.txt`), copies it into the game.
  `--no-install`, `--check`. Replaces Actionbar Organizer's `install`.
- **`dev/tests/lint`**: every file in the TOC exists and every file is in the TOC; all Lua parses; no file
  writes a global that is not Sane UI's own.
- **`dev/tests/core.lua`**, **`dev/tests/run`** (everything). The stand-in client learned the game's options,
  `xpcall` with arguments, `CallErrorHandler`, `date`.
- `Doc/changelog.txt`, `Doc/Changed.md`, READMEs for the project and for Core and Settings.

- **`LICENSE`**: the code stays MIT. New in front of it: the name *Sane UI* and its logo are trademarks and
  the original art is all rights reserved, neither is under MIT; Blizzard's code and art stay Blizzard's;
  a request (not a condition) not to publish the whole addon again as a new one.

### Changed (against Actionbar Organizer 0.3.0)
- **Commands:** `/abo ...` is `/sane spellbook ...`, short `/sane sb ...`. `/abo book on|off` is
  `/sane sb pages on|off`.
- **Saved settings:** `ActionbarOrganizerDB` is `SaneUIDB.modules.Spellbook`; the training list's `ABO_...`
  are `SaneUITraining_...`. Nothing is carried over: the old addon was never installed under that name.
- **Names in the game:** frames `ActionbarOrganizerBook(Pager)` are `SaneUISpellbook(Pager)`, `ABOTraining...`
  are `SaneUITraining...`; popups `SANEUI_SPELLBOOK_SAVE/LOAD`; key binding `SANEUI_SPELLBOOK_TRAINING` under
  the header *Sane UI*.
- **Art paths:** `Interface\AddOns\SaneUI\Spellbook\Training\...`.
- **The minimap's addon list** opens the options (was: the training list, still on its key binding and
  `/sane sb train`).
- **Game events:** an error in one listener no longer keeps the others from hearing the event; it goes to the
  game's error handler.
- **Error lines** point to `/sane errors` instead of "tell Claude"; labels carry the module (`Spellbook: scan`).
- **The training list's tool** builds into `src/Spellbook/Training` with the new names.
- Tests moved to `dev/tests` (`run.lua` is `spellbook.lua`), tools to `dev/tools`.

### Removed
- Reading settings saved by Actionbar Organizer 0.1.0 and 0.2.0 (character under its name, trainer rows,
  the planner window's position).
- The folder `ActionbarOrganizer`.

### Project
- **`Doc/guides/`**, three guides written from Blizzard's posts and talks, the add-on policy and the
  Warcraft Wiki, with every template and function name checked against `references/`:
  `blizzard-design-principles.md` (13 principles, each with what it means for Sane UI, and a checklist),
  `addon-standards.md` (policy, TOC, loading, globals, taint, secret values, performance, saved variables,
  languages, resilience), `gui-development.md` (which Blizzard part to build what from; windows, layout,
  art, text, lists, menus, tooltips, changing Blizzard windows). Each lists its sources and says which
  were only read as a summary.
- **`CLAUDE.md`:** three new principles (*Simple*, *Maintainable*, *Design*) and a section *Guides* that
  says which guide to read before which kind of work. The folder paths stay as they are (`src/`, not the
  earlier `src/SaneUI/`).
- **`src/` holds the addon itself** (`src/SaneUI.toc`, `src/Core/`, ...), one folder level less than at first
  (`src/SaneUI/`). `dev/build`, the tests and the tools follow. The build is still `BUILD/SaneUI`.
- **Git history started anew:** one commit with the project's files (ignore and attribute files, licence,
  README, CLAUDE.md), one with the addon and everything else.
- `.gitignore`: `references/`, the history file of `Scripts/addon-categories`, editor
  leftovers. `BUILD/` is committed, so the repository carries the ready addon folder. `.gitattributes`: LF for
  text, art marked binary, `libs/` kept byte for byte.
- `CLAUDE.MD` renamed to `CLAUDE.md` (Claude Code only reads that spelling on Linux); added: one addon with
  one TOC, `dev/build`, the real name of `BUILD/`.
