# Lore

Planning notes for the **Lore** module (`SaneUI_Lore`, title *Lore*). Saneroki, 2026-10-16: *just an idea for
now*. A module that handles **voice overs**, a **library** about the world and its lore, and **lore
tidbits** in tooltips and other places of Sane UI. Nothing is built.

Saneroki: Lore is our own module, with all of this in one place. Our code, our data, our texts.

## What it is (Saneroki, 2026-10-16)

- **A module of its own**, an addon like every other (`SaneUI_Lore`), depending on Core only.
- **Voice overs with AI voices** (Saneroki): made by an AI voice model, not recorded line by line by people;
  the texts are sent to a cloud voice service (Saneroki's choice, 2026-10-16).
- **A library:** what there is to know about the world and its lore, to read in the game.
- **Tidbits:** short pieces of lore in tooltips and other places of the addon.

**What "AI voices" means in the game:** an addon cannot run a voice model; the game only plays sound files
and speaks with the computer's own text to speech. So the AI voices are made **before**, by the voice
service, and shipped as sound files. The game's text to speech is only the fallback for what has no AI
voice yet.

Everything below is a proposal for Saneroki to discuss.

## Who does what

Core and its data are the backend, the modules are views (CLAUDE.md, *Backend and views*):

| Part | Whose | Why |
| --- | --- | --- |
| The lore entries and tidbits | Core's data framework (`Doc/ideas/Data.md`): a pack `SaneUI_Data_Lore` with the set `Lore` | Data is Core's; modules only read it |
| What the player has met and read: zones, NPCs, kills, quests done, books and letters, the game's texts | Core's watchers and character data (*Characters* in `Data.md`) | Gathered by Core whether Lore is on or not |
| The library, the voice and its bar, the line of a completed tale, the line when a zone is entered | Lore | Its own views |
| A tidbit in a tooltip, in a talk, on the map | The module whose view it is: Tooltips, Social's Dialogue, Navigation | A module draws only its own frames; none calls into another |
| The voices: the sound files, and the index of their own lines | Voice packs (`SaneUI_Voice_*`), Sane UI downloads of their own (Saneroki, 2026-10-16) | Too big to come with Sane UI; on disk only, never in memory until played |

- **Lore waits for the data framework** (`Doc/ideas/Data-build.md`). Only the game's text to speech needs no
  data and could come first.
- **Everything by the game's numbers,** never by names: an NPC by its creature ID, an area by its ID, an
  item by its ID, a quest by its ID. Names change with the language and are shared by namesakes; a match
  by name shows the wrong lore and needs a table per language.

## The library

### Read and heard

The library is the player's own: it holds what this player read and heard in the game, gathered by Core's
watchers (*Collecting*), put in order by Core's quest and zone data, with short texts of ours beside them.

- **An entry is a text the player met:** a quest's words when it was offered and when it was handed in, what
  an NPC said when talked to, what one said or yelled nearby, a book's or a letter's pages. Nothing the
  player has not read or heard is in it, so it can spoil nothing.
- **Our own texts join it** where the player has been: a land's short text once something was read or
  heard there, a people's once one of them spoke to the player, an instance's primer once the player went
  in. They tell what is true in this world now, never more than the player has met: a part tied to a quest
  shows once that quest is handed in.
- **Before Lore:** what Core's watchers kept before Lore was switched on is there at once; nothing else is
  made up.

### Chapters

| Chapter | What it holds | Where the text comes from |
| --- | --- | --- |
| **Tales** | Quest chains told as stories, zone by zone: each chain's words in order, *part 3 of 5*; a quest of its own is a tale of one part | The game's texts as the player read them; the chain from Core's `Quests` set |
| **Writings** | Books, notes, plaques, gravestones, letters from NPCs (by sender); never a letter a player wrote | The game's pages as the player read them |
| **Overheard** | What NPCs said to the player and around the player, by speaker and place | The game's texts as the player heard them |
| **Lands** | The continents and zones the player has been to, each with our short text and its tales, writings and words heard there | Ours; Core's zone data for the order |
| **Peoples** | The races, kinds of creature and factions the player has met | Ours; a faction's own description from the game (`C_Reputation`) |
| **Halls** | A primer per dungeon and raid the player entered: what it is, the player's quests inside, the bosses met | Ours; the Adventure Guide's texts where this client has them (`EJ_GetInstanceInfo`, `EJ_GetEncounterInfo`) |
| **Cinematics** | The game's movies the player has seen, to watch again | The movies this client has (`PLAY_MOVIE`, `MovieFrame_PlayMovie`) |

- **The game first** (Blizzard fidelity): a text the game tells itself is asked live where it can be,
  never copied into our shipped data; what the player read is kept by Core for the player only.
- **Our own entries** (the `Lore` set, source *hand*), checked against the game's own texts; where they
  disagree, the game wins.
- **The world as this client has it:** nothing of later expansions. Another client gets its own entries
  where it differs (a version per build, as every set has).
- **No counts of what is missing:** a chapter shows what it holds, never how much more there could be.

### A page

- **At the top:** a portrait (the speaker's 3D model by its display, a book's item icon, a land's map), the
  title, the chapter.
- **The text,** in parts, as the game showed it, with the player's name put back where it stood.
- **Its origin in the game:** the quest, NPC or book whose words these are, and the character who read
  them.
- **Links:** names of other entries the player has are links; Back and Forward.
- **Listen:** the page in its speaker's voice, or the narrator's for our own texts (*Voice*).

### Quiet by default

- **No banner and no sound for each new text:** reading is its own reward, and the game's own sounds
  already mark a quest or a page.
- **A tale completed** (the chain's last quest handed in) gives one small line on the voice bar's place,
  *The Defias: the tale is complete*, a click opens it (a setting turns it off). Lore's own frame: the game's
  alert lists are not changed.

### The window

- **A Sane UI window** (`Doc/guides/windows.md`): the chapters and entries at the left, the page at the
  right; Blizzard's parchment (the book window's papers, `ItemTextGetMaterial`), the game's fonts
  (`ITEM_TEXT_FONTS`, the fancy one for titles).
- **Search** in the title bar (*Title bars* in `Doc/ideas/Windows.md`), over the words of every entry the
  player has; a hit opens the page at its passage, the words marked. It waits for the typing to stop before
  it searches.
- **Opened by** `/sane lore`, a key binding, the line of a completed tale, and a tidbit's *More in Lore*.
- **Made at first open**, not at login.

## Collecting what the game shows (Core's watchers)

Core's job (CLAUDE.md, *Backend and views*), named here because the library needs it. Kept in saved
variables, private: never sent anywhere.

- **Books and letters:** each page as the player reads it (`ITEM_TEXT_READY`: title, page, text, writer,
  paper), with where and when. The player's name is put back to its placeholder. Letters with a player as
  writer are never kept. Core only reads: it never turns a page for the player.
- **The game's talk:** quest texts (offered, in progress, handed in), what NPCs say when talked to, and
  what they say and yell near the player, with a cap.
- **Movies seen** (`PLAY_MOVIE`).
- **Texts with no voice yet** are kept too, so the next voices are made for them (*Voice*, *Missing
  voices*).
- **A cap on everything,** and kept by key, so a list never grows without end and never needs a slow search.

## Voice

### AI voices (Saneroki)

- **Made by a cloud voice service** (Saneroki, 2026-10-16), through its API: a tool `dev/tools/voicegen` and a
  guide of its own (`Doc/guides/voice-generation.md`, with the voice database `dev/tools/voicedb`, the
  cast `dev/voices/cast.md` and the names `dev/voices/names.md`). The tool sends each text with its voice,
  its settings and its list of names, gets the sound back, and encodes it for the game. The service's key is
  kept on this computer (a config file of its own, or the environment), never in the repository. Made on
  2026-10-17 and tested against a stand-in; the key and the trial come next.
- **A cast of 98 voice presets** (`dev/voices/cast.md`): each playable race and sex in four kinds
  (`common`, `martial`, `refined`, `elder`, as in `gnome-female-refined`), one or two presets for each other
  people and creature (`ogre-male`, `naga-female`), and narrators (the narrator for places and the library,
  the reader for books and letters, the crier for notices). Each is made from a written description (the
  service's voice design) and kept as a voice of our own account, so it stays the same for every line.
  Leaders and other speakers of note may get a voice of their own.
- **Names said right:** one list of how lore names are said (the service's pronunciation dictionaries:
  a name said as another spelling, or by its sounds), used by the voice tool and by the game's text to
  speech alike.
- **The text from the game itself,** as this client shows it (*The texts*). Texts this client changed get
  new voices (*Missing voices*).

### What has a voice

1. **Quest texts:** a quest giver's greeting, a quest offered, in progress, handed in.
2. **What an NPC says when talked to**, page after page.
3. **What NPCs say and yell in the world,** when the chat line is exactly a voiced one (*Finding the
   voice*).
4. **Books and letters,** read whole, page after page, following the player's turns.
5. **Places:** an area's lore the first time the game says it is discovered, and the starting area at a new
   character's first login.
6. **The library:** its pages, on Listen.

- **Never over the game's own voice:** talking heads, cinematics and movies stop Lore's voice; the game's
  sound settings stay as the player set them.
- **From the game's events, not from a window:** Lore listens to the talk's events, so the voice works with
  the game's own windows and with Dialogue (`Doc/ideas/Dialogue.md`) alike.

### The texts

**Gathered** (2026-10-17) into the voice database, the workbench for making the voices, apart from the
game's data: every text, who says it, and how it should sound (`Doc/guides/voice-generation.md`).

Researched on 2026-10-16 (Forever 1.60.1, builds 70245 and the beta's 70425). **Almost every text comes
from the server, not from the client's files:** the client's own `BroadcastText` table holds 12 lines (the
Skyborne intro, already voiced), and it has no table for NPC talk, books or quest texts at all. So the texts
come from four places, merged by the game's IDs:

| Kind | Vanilla (most of the world) | Forever's own (new and changed) |
| --- | --- | --- |
| **Quest offered, objectives** | The vanilla baseline (below) | The quest sweep: the game's quest cache |
| **Quest in progress, handed in; the quest greeting** | The baseline | Only in play: the server sends them while the player stands at the NPC, and they are never cached |
| **NPC talk** | The baseline (by the game's `BroadcastText` IDs) | In play (`C_GossipInfo.GetText`); new lines also come as the server's corrections to the client's tables (the hotfix cache, `Cache/ADB/enUS/DBCache.bin`) |
| **Say, yell in the world** | The baseline (`BroadcastText`, with Blizzard's IDs) | In play (`CHAT_MSG_MONSTER_SAY`, `_YELL`); the hotfix cache |
| **Books, plaques, letters** | The baseline (by the game's page IDs) | In play (`ItemTextGetText`); the page cache `pagetextcache.wdb` |
| **Mail from NPCs** | — | The client's own table `MailTemplate` (112 letters, exact) |
| **Talking heads** | — | The client's `ConversationLine` (634 lines) points to texts the server sends |

- **The baseline:** the texts of the original world that Forever builds on, Blizzard's own, kept in our
  voice database by Blizzard's IDs (quests, `BroadcastText`, pages). Those quests read as in Forever
  (checked on a few).
- **The quest sweep:** Core's crawl (`Data.md`, *How it is gathered*) asks the game for every quest the
  client knows (`QuestV2`: 6,614 IDs, 1,809 of them only in Forever) with `C_QuestLog.RequestLoadQuestByID`,
  slowly. The game writes each answer into `Cache/WDB/enUS/questcache.wdb`: the title, the objectives, the
  text when offered, the quest log's line when done. A tool of ours reads that file: a header (`WQST`, the
  build, the language) and then each quest's ID, length and data (read here on 2026-10-16: 132 quests of
  build 70425, Forever's new ones among them). An addon cannot read those texts for a quest not in the log,
  so the file is the way.
- **In play** (Core's watchers, *Collecting*): what only the NPC sends, above all the progress and hand-in
  texts of Forever's new quests (about 1,000 or more).
- **The client's own tables** (`MailTemplate`, `ConversationLine`, `QuestV2`, which items have pages) are read
  from the game's files.
- **Again after launch:** the beta ends on 22 October and the game opens on 4 November; the server can change a
  text at any time without a patch. The hash (*Finding the voice*) catches it, and *Missing voices* follows.

**How much:** about 5 million characters in vanilla (quests 3.2 million, NPC talk and world lines 1.1
million, pages 0.5 million, greetings, options and the rest 0.2 million), and about 1 million more for
Forever's own: some **6 million characters**, about 100 hours of speech (an estimate).

**Before a text goes to the service:**
- **Placeholders:** `$B` is a new paragraph (a new part); `$N`, `$C`, `$R` are left out or the sentence is
  worded around them; `$G` (he or she for the player) gives two files; `%s` (the speaker's name in an emote)
  and text in `<...>` (what the NPC does) are not voiced. The text kept for the hash stays as the game has it.
- **Male and female:** a `BroadcastText` line has a text for each sex of the speaker; they differ in about 50.
- **Racial languages:** about a fifth of the vanilla lines are in Common, Orcish and others. The other side
  sees them garbled; that text does not match the hash, so it stays silent by itself.
- **Already voiced** by Blizzard (lines with a sound, Forever's 89 voiced lines, the cinematics): left out.
- **Several texts per NPC:** an NPC may greet with one of several texts; each gets its voice.
- **Secret values:** monster chat may be secret in instances in this client (*to check in the game*);
  there only the baseline's text can be used.

### The service: cost and form

From the service's own pages, 2026-10-16 (prices change: check before buying):

- **Price:** charged per character through the API: the newest, most expressive model about $0.08 for 1,000
  characters, its fast version about $0.04. A monthly plan of about $99 has room for 160 own voices and 10
  lines at a time, and counts towards what is used; the rest is paid as used. US dollars; tax may come on top.
- **Time:** some hours for all lines (an estimate); listening to 100 hours of speech takes far longer.
- **A trial first:** a few hundred lines on both models (about $40), to hear the cast and measure time and
  cost.
- **Form:** no Ogg Vorbis from the service. The tool asks for WAV and makes the game's files itself: silence at
  the start and end cut off, the loudness made even, one channel at 22.05 kHz, Ogg Vorbis of about 40 kbps
  (the game plays Ogg Vorbis and MP3; the right rate is chosen by ear in the trial).

**The estimate** (2026-10-16; about 900 characters are a minute of speech):

| What | Characters | Speech | Newest model | Fast version | Size at 40 kbps |
| --- | --- | --- | --- | --- | --- |
| **The game's texts:** quests, NPC talk and world lines, books, mail; vanilla and Forever's own | 5.9 million | 100 to 125 hours | about $470 | about $240 | 1.8 to 2.2 GB |
| **And ours:** place narration, library pages | 7.4 million | 125 to 155 hours | about $590 | about $300 | 2.2 to 2.8 GB |

- **Lines made again** (a wrong word, a name said wrong): perhaps 15% more money.
- **Size by rate,** for the game's texts: 1.4 to 1.8 GB at 32 kbps, 2.1 to 2.7 GB at 48 kbps, 2.8 to 3.5 GB at
  64 kbps; 5.7 to 7.1 GB as the service's own 128 kbps MP3. Zipping saves nothing more.
- **A player needs less:** only the packs of the level bands they play (*Voice packs*).
- **Timing of each word:** the service can return when each character is said; the voice bar lights the
  words with it, and the lengths of the parts come from it.
- **Long texts in parts** stay one voice: each part is sent with the text before and after it.
- **Each line made once:** the tool keeps a list keyed by the hash of everything that shapes the sound (text,
  voice, model, settings, names list), so only new or changed lines are sent and paid. Every request's number
  and cost is noted.

### Finding the voice for a text

| Text | Key | Plays only if |
| --- | --- | --- |
| Quest | Quest ID and part (offered, in progress, handed in) | The text's hash matches |
| NPC talk | Creature ID and the text's hash | The hash matches; no guessing by similar words |
| Book page | The page text's hash | The hash matches |
| Place | Area ID | Always (the text is ours) |
| Library | Entry and part | The entry's version matches |

- **The hash** is of the text as the game shows it, with the player's name, race and class put back to the
  placeholders they came from, and the spaces tidied. A text Blizzard changed is then never voiced wrong: it
  is read aloud or left silent, and kept as a missing voice.
- **Variants:** a file for each player sex where the text has the game's he-or-she placeholder; a file by
  the NPC's sex (`UnitSex`) where an NPC is voiced both ways; a giver's own voice where it has one.
- **Placeholders:** the player's name, race and class are left out of the voice where the sentence allows;
  the voice tool marks the rest to look at by hand.

### Playing

- **`PlaySoundFile(path, "Dialog")`**, so the game's own dialogue volume governs it; `StopSound` to stop.
- **The length comes from the pack's index** (*Voice packs*); the end of a part is a timer, checked with
  `C_Sound.IsPlaying` then. No polling, no files played to test that they are there.
- **Long texts in parts,** a file per paragraph, so:
  - the voice can pause between parts and go on, skip to the next part, or start again;
  - after a `/reload` it can go on where it was;
  - Dialogue shows one part a line, in step with the voice.
- **One queue for everything,** one voice at a time. A quest's text goes before an NPC's talk; a text
  already in the queue is not added twice. *Stop all* empties it.
- **Stops** when the talk ends (a setting, on), when another starts, when a fight begins (a setting), when a
  movie or a talking head starts, and when the game cut the sound.

### The voice bar

- **A small bar in the look of the game's talking head** (`TalkingHeads-<side>-PortraitFrame`,
  `TalkingHeads-TextBackground`): the speaker's 3D model (an icon for a book or a place), the name, the
  words as they are read, *+2 waiting*.
- **On the bar itself:** a click on the words pauses and goes on; its close button stops the voice and
  empties the queue.
- **A choice:** the bar, only the words at the bottom of the screen, or nothing.
- **Not while Dialogue shows the talk:** Dialogue has its own words and face.

### Voice packs

**Saneroki (2026-10-16): the voices are so big that they are Sane UI packages of their own, downloaded
separately. Lore plays a voice only when it finds its package installed.**

- **Sane UI without them** is the same as with them, only silent (or read aloud by the game's text to
  speech, if switched on). Nothing asks the player to download them.
- **Addons of their own,** under Sane UI in the addon list, titled *Voices: Lands 1–20*, *Voices: Halls*,
  ... so they sort together, as the data packs do (*Data: Items*). `## LoadOnDemand: 1`,
  `## Dependencies: SaneUI`.
- **Each holds the sound files and the index of its own lines,** so the two always match, whatever version of
  a pack is installed: per line its file, its parts and their lengths, and the hash of the text it was made
  from. The index is a small file in Core's data format, read through `Core.Data`; the packs share no index.
- **The packs, cut by where and when a player meets the texts:** each land pack holds every kind of text
  of a band of zones (quests, NPC talk, the world's says and yells, books, place narration), the zones
  sorted into bands by their level range from Core's *Zones*; a mail goes with the band of the level it
  arrives at. Sizes at about 40 kbps, an estimate (*The estimate*):

  | Pack | What | Size |
  | --- | --- | --- |
  | `SaneUI_Voice_Lands1` | The zones of levels 1 to 20, and the capital cities | about 0.65 GB |
  | `SaneUI_Voice_Lands2` | The zones of levels 20 to 40 | about 0.6 GB |
  | `SaneUI_Voice_Lands3` | The zones of levels 40 to 60 | about 0.55 GB |
  | `SaneUI_Voice_Halls` | Dungeons and raids | about 0.2 GB |
  | `SaneUI_Voice_Library` | Our own library pages | about 0.35 GB |

  A new character needs the first band only; each pack stays well under the 2 GB a single release file may
  have.

#### How Lore finds them

- **At login,** Core lists the addons named `SaneUI_Voice_*` (`C_AddOns.GetNumAddOns`, `GetAddOnInfo`,
  `DoesAddOnExist`) and reads each one's TOC lines without loading it (`C_AddOns.GetAddOnMetadata`):
  `## X-SaneUI-Voices: lands, 1-20` (what and for which levels), `## X-SaneUI-Format: 1` (the index's
  form).
- **A pack counts** when it is there, switched on (`C_AddOns.GetAddOnEnableState`), and of a format this
  Lore reads.
- **Then** Lore loads its index (`C_AddOns.LoadAddOn`) after the loading screen, out of combat, only while
  voice is switched on; the sound files are only played, never loaded.
- **A line plays only if** its pack counts, the pack's index has the line, and the hash matches the text the
  game shows now. Otherwise it is read aloud (if switched on) or silent.
- **Missing, switched off, or of an older format:** silent. No popups, no lines in chat. Lore's settings page
  lists the packs: installed (with its size and number of lines), switched off, or not installed, with a
  word on where to get them.
- **A pack downloaded while the game runs** is found only after the game is restarted: the game reads its
  addon list at start (*to check in the game*: whether a `/reload` is enough).

#### Downloading and updating

- **Through Sane Sync** (`Doc/ideas/SaneSync.md`, *Voice packs*): the voice packs are offered there one by
  one, with their size, and are not installed unless the player picks them. The app knows the characters'
  levels and offers their bands first.
- **Hear a sample first** (Saneroki, 2026-10-17): a button in the app plays five samples, one per press, in a
  circle: the narrator and four voices of different races, sides and sexes, so a player hears the voices
  before choosing to download them.
- **Updated line by line:** a pack's manifest lists every sound file with its hash, so new or changed voices
  are a small download, not the whole pack again.
- **Their own version:** a voice pack can be newer or older than Sane UI; the hash of every line keeps them
  right, and the format says whether this Lore can read the index at all.

#### Where they are kept

- **Not in the repository:** about 2 GB of sound has no place in git. The voice tool builds the packs into
  `BUILD/SaneUI_Voice_*/`, which git ignores (one line in `.gitignore`), and `dev/build` leaves them alone; the
  voice tool installs them into the game itself, so a build stays fast.
- **What is committed:** the voice tool, the cast (each voice's description and settings), the names list,
  and the list of what was made (per line its hash, voice, model and the service's request number), so it is
  known what each line cost and what must be made again.
- **The sound is kept safe outside git,** with the backups: it cost money, and making it again would cost
  it again.

### Missing voices

- **What has no voice** (a text this client changed, a quest the data did not know) is kept by Core's
  watchers (*Collecting*). `dev/tools/data harvest` brings it home, the voice tool makes its voice, the next
  build ships it. No buttons to send texts anywhere.

## Tidbits

### What a tidbit is

- **One or two short sentences,** in the style of the game's flavour text: gold, in quotes.
- **About one thing:** an NPC, a creature's kind, an item, a zone, a faction, a race, a class.
- **From the `Lore` set:** one of our own short texts, with the same spoiler rule as the library (*Read and
  heard*). The pack's own code (`Lore.lua`, as `Quests.lua` comes with the Quests pack) gives the tidbit for
  a thing with that rule applied, so every module shows it the same way.
- **Not twice:** where the game already shows a text (an item's own flavour text), no tidbit.

### Where

| Place | Whose | What |
| --- | --- | --- |
| **A unit's tooltip** | Tooltips | The NPC's tidbit, else its kind's (*Gnoll: ...*), by creature ID |
| **An item's tooltip** | Tooltips | A flavour quote for quest items and items of note, by item ID, only items of this client |
| **A zone entered** | Lore | A line under the game's zone name, in its font, fading with it; the first visit on this character (a setting: every time). The game's `ZoneTextFrame` is only hooked (`HookScript`) |
| **An instance entered** | Lore | Its line under the zone name, as for a zone; its primer joins the library (*Halls*) |
| **A boss killed** | Lore | The boss joins its primer in the library (`ENCOUNTER_END`) |
| **A talk** | Social's Dialogue | The NPC's tidbit under its name; where the quest stands in its story (*The Defias, part 3 of 5*) |
| **The map** | Navigation | A zone's and an area's lore when the mouse is over it, with Listen |
| **Later** | The character sheet, Abilities | Race and class; a class's lore at the top of its spellbook |

- **No lines in chat** by themselves: Blizzard's interface is quiet.

## How it is built

- **Lore's files:** `Lore.lua` (the module, settings), `Library.lua` and `Page.lua` (the window), `Shelf.lua`
  (the entries made from what was read and heard, our texts joined to them, the line of a completed tale),
  `Voice.lua` and `Queue.lua`, `Bar.lua` (the voice bar), `Zone.lua` (the line when a zone or an instance is
  entered). Listed in `SaneUI_Lore.toc`.
- **At login:** Lore's events, and `Prepare` for the `Lore` set; nothing else. The window is made at first
  open, the voice bar at the first voice. The indexes of the voice packs found are loaded after the loading
  screen, out of combat, while voice is on.
- **Events only:** the talk's events, `ITEM_TEXT_*`, `ZONE_CHANGED_NEW_AREA`, the discovery of an area
  (`MAP_EXPLORATION_UPDATED`, rather than reading every system message),
  `ENCOUNTER_END`, `PLAY_MOVIE`, `CINEMATIC_START`, `TALKINGHEAD_REQUESTED`, `PLAYER_REGEN_DISABLED`.
- **Each call goes through `Core.Ask`**, so a call this client lacks is nil, not an error: no Adventure
  Guide, no text to speech, no voice.
- **A failure stays small** (`module.Guarded`): the voice stops, the window closes, the zone line is not
  shown. Nothing of the game's is changed, so nothing has to be given back.
- **Secret values:** a text or a name that is a secret value is not hashed, kept or voiced (`Core.Plain`).
- **Combat:** the library is a window of ours and follows the window rules (`Doc/guides/windows.md`).

### Rules Lore keeps

- **Its own frames, the game's settings untouched:** Lore draws in frames of its own, hooks the game's at
  most, and writes no sound setting, key binding or addon switch.
- **Only for the exact text:** a voice plays for the text its hash was made from, found by the game's IDs,
  never by a name or by similar words.
- **Small at rest:** at login only its events; everything else when first asked for, and kept by Core with
  a cap and a key.
- **Nothing a player wrote** is kept or voiced.

## Settings

On Lore's page; account-wide.

| Setting | Default |
| --- | --- |
| Show spoilers in our own texts | off |
| A line when a tale is complete | on |
| AI voices (where a voice pack is there) | on |
| Read aloud with the game's text to speech what has no AI voice (voice, speed, volume) | off |
| Voice for quests, NPC talk, the world's says and yells, books, places | on, each |
| Stop the voice when the talk ends; when a fight begins | on; on |
| The voice bar: bar, words only, nothing | bar |
| Lore when a zone is entered (first visit only, or every time) | on, first visit |

Each module that shows tidbits has its own switch on its own page (*Lore tidbits*, on).

## Order of work

1. After the data framework: the `Lore` set's schema, our first texts (one starting zone), the pack's
   `Lore.lua` with the tidbit and the spoiler rule; Core's watchers for books, talk and movies.
2. The module: folder, TOC, README, settings page; the library window with search, filled from what was
   read and heard; the line of a completed tale.
3. Tidbits: the zone line (Lore), the rows in Tooltips.
4. Voice: the queue, the bar and the game's text to speech first (no files needed). Then the texts: the
   vanilla baseline, the reader of the quest cache, the quest sweep. Then
   `dev/tools/voicegen` and its guide (with the ignore line for the packs), the trial on both models, and one
   voice pack for one starting zone, to measure size, cost and quality before more.
5. More of our texts and more voices, band by band. Then the primers, the tales, the cinematics.
6. Later: a diary of the character's own travels (where it went, whom it met, what it did), from Core's
   character data.

## Open questions for Saneroki

- **Tidbits:** each module's own switch (the proposal: no module calls into another), or one switch on
  Lore's page that the others ask Core for?
- **Read aloud:** in Lore only (the proposal: all voice in one place, it works with the game's own windows
  too, and Dialogue only shows the words)?
- **AI voices:** about 6 million characters, about 2 GB. Which first: the first land band whole, or one kind
  (quests) everywhere? The newest
  model (about $470) or its fast version (about $240): decided after the trial? And our own places and
  library too (about 1.5 million characters more)?
- **Forever's new quests:** their progress and hand-in texts come only from play. Wait until enough is
  gathered, or voice what we have and add the rest as it comes?
- **The library:** per account (a book read by one character is in every character's library) or per
  character? The proposal: per account, each text with the character who read it.
- **Our own texts:** how many to write per land and people before the first release?
- **The window:** which place on the screen (a side, or the middle with the talk windows)? Where this client
  has the Adventure Guide, does Lore stand for it (with the button to the game's own window), or beside it?
