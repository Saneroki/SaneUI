# Voice generation

How Sane UI's voice overs are made: the voice database (every text that gets a voice, who says it, and
how), the cast of voices, the analysis of each line's tone and cadence, directing lines with a language
model, how a line becomes a request to the cloud voice service, and the voice tool that sends it; and how
the short sounds of windows are made (*Short sounds*). Read this before making, directing or changing
voices or sounds. What the voices are for, and how the game plays them: `Doc/ideas/Lore.md`, *Voice*.

**Status (2026-10-17):** the database, the cast, the names list and the voice tool (`dev/tools/voicegen`:
design the cast, send the names and the lines, make the game's files) are made; the tool is tested against
a stand-in for the service, and nothing has been sent to the service itself yet. The key and the trial come
next (*The voice tool*). The numbers below were measured on the database as built that day.

## The picture

```
 the sources                       the workbench                                       the game
 ───────────                       ─────────────                                       ────────
 the vanilla baseline ──┐
 (the 1.12 game's texts)│
 the client's tables ───┼─► staging files ─► dev/tools/voicedb build ─► dev/voices/build/
 (of one build)         │   dev/voices/staging/   ▲     ▲     ▲          lines.jsonl, voices.sqlite
 the game in play ──────┘                         │     │     │                  │
 (later: the quest sweep,              cast.md, names.md  │  analysis/*.jsonl    ▼
  Core's watchers)                             fixes.jsonl          dev/tools/voicegen ◄─► the voice service
                                                                    WAV ─► Ogg Vorbis (dev/voices/sound/)
                                                                    ─► BUILD/SaneUI_Voice_*/ (later)
```

- **Not the game's data.** The voice database is a workbench for making voices, apart from Core's data
  framework (`Doc/ideas/Data.md`), which is what the game loads. Nothing of it is shipped; the game only gets
  the voice packs and their small indexes (`Doc/ideas/Lore.md`, *Voice packs*).
- **What is in git:** the tools, the cast (`dev/voices/cast.md`), the names (`dev/voices/names.md`), the hand
  fixes (`dev/voices/fixes.jsonl`) and the directions (`dev/voices/analysis/`): our own work, small, and
  worth keeping. **What is not:** the staging files (`dev/voices/staging/`), the built database
  (`dev/voices/build/`, made again in seconds), and the sound (`dev/voices/sound/`, kept with the backups).
  The voice tool adds its record to git: each preset's voice (`dev/voices/voices.json`) and every file made
  (`dev/voices/made.jsonl`).

## The texts

Almost every text comes from the server, not from the client's files (`Doc/ideas/Lore.md`, *The texts*).
Today the database holds the vanilla baseline (the 1.12 game's texts) and the client's own tables of build
70425; Forever's own texts come with the quest sweep and with Core's watchers.

They arrive as **staging files** in `dev/voices/staging/`, in the data plan's staging format
(`Doc/ideas/Data.md`, *Staging*), and `dev/tools/voicedb build` reads every file there (a few seconds). The
sets:

| Set | Key | What |
| --- | --- | --- |
| `VoiceLines` | `quest:<id>:<part>`, `greeting:npc:<id>`, `trainer:npc:<id>`, `bt:<id>`, `page:<id>`, `mail:<id>` | Every text: kind and part, the raw text, chat type, language, whether the game voices it already, who says it, the quest and the zone |
| `VoiceSpeakers` | `npc:<id>`, `object:<id>`, `item:<id>` | Name, title, race and sex (from its model in the client's tables), the model's folder, creature type, rank, class, level, side, roles (quest giver, vendor, trainer, guard, leader, ...) |
| `VoiceQuests` | quest ID | Title, levels, zone, side, kind, chain, givers and takers; whether this client has it, and its texts missing where only this client has it |
| `VoiceZones` | area ID | Name and parent, from this build's `AreaTable` |

**Who says a line** comes with the line in its staging: a quest's offer is its giver's, its progress and
hand-in its taker's; an NPC's talk, says and yells are the NPC's own (else the quest's giver's or
taker's); a book's page belongs to the item or object that holds the book.

**Still to come:** Forever's own texts (about 2,900 quest IDs of this client have no text yet): the quest
sweep reads the quests' offers from the game's quest cache (`Cache/WDB/enUS/questcache.wdb`), Core's
watchers bring the rest from play; then the client's `ConversationLine` texts and the hotfix cache. Each
comes in as one more staging file, and the build merges them by key.

## The database

`dev/tools/voicedb build` writes one line per **part** of a text (`dev/voices/build/lines.jsonl`; the same as
tables in `voices.sqlite`). A text is cut into parts at its paragraphs, so the voice can pause and go on, and
Dialogue shows one part a line (`Doc/ideas/Lore.md`, *Playing*).

| Field | What |
| --- | --- |
| `key` | The text's key, with `#2` for its second part: `quest:176:offer#2` |
| `stage` | What kind of moment it is: `offer`, `progress`, `complete`, `greeting`, `trainer`, `gossip`, `say`, `yell`, `zone yell`, `whisper`, `page`, `mail` (and `objectives`, `emote`: not voiced) |
| `voice`, `why not` | Whether it gets a voice, and why not |
| `text`, `hash` | The part as the game has it, and its hash (a text Blizzard changes gets a new hash) |
| `speech` | The words to say, per variant: `any`, or `male` and `female` where the text has the player's he-or-she placeholder |
| `actions` | The stage directions the text had (`<The dwarf sighs.>`): not said, used for tags |
| `speaker`, `speakers`, `who` | Who says it: the first speaker's key and facts, and every speaker of a shared line |
| `presets`, `why preset` | The voice preset of each speaker (a line shared by speakers of different races gets one file per preset), and how it was chosen |
| `context` | Quest, title, level, kind, side, zone, chain, book and page, chat type, language |
| `analysis` | Tone, intensity, pace, volume, register, tags, stability, direction, and where they came from (`rules`, `llm`, `hand`) |
| `names`, `unknown names` | The lore names in it that `names.md` has, and names it may lack |
| `review` | What a person should look at: a placeholder said as a stand-in word, an unknown race or sex, a direction made for an older text |
| `chars` | What it costs: its characters with tags, for every variant and preset |
| `previous`, `next` | The neighbouring parts, sent with it so the voice keeps its flow |

Questions are asked of the SQLite copy, for example:

```bash
sqlite3 dev/voices/build/voices.sqlite "select preset, count(*), sum(chars) from lines where voice group by preset order by 3 desc"
```

## Speakers and presets

A speaker's preset is `<race>-<sex>-<kind>` for the eight playable races and `<race>-<sex>` for the others
(`dev/voices/cast.md`):

- **Race and sex** come from the speaker's model in the client's tables: the race of a character model (a
  human, a dwarf, an undead), else the model's folder (`ogre`, `troglodyte`, `humanmalekid`, `banshee`,
  `keeperofthegrove`): `dev/tools/voicedb`, `MODELS`, says which folder is which race.
- **Kind** (playable races): `elder`, `martial` or `refined` by words in its name or title (*Elder*, *Guard*,
  *Captain*, *Archmage*, *Lord*), else by its class (a warrior trainer is martial, a priest refined), else
  `common`.
- **Objects and items** that give quests or hold books: the `crier` for notices and wanted posters, else the
  `reader`.
- **Mixed sexes:** an NPC whose spawns are men and women (a town's guards) gets both voices; the game picks by
  the spawn's sex (`UnitSex`).
- **Fallbacks:** no race known: a human, marked for review; no preset for a race and sex: the race's other sex,
  then a human.
- **Fixes:** `dev/voices/fixes.jsonl`, one JSON object a line: `{"key": "npc:448", "preset": "gnoll-male"}` gives
  a speaker its preset; `{"key": "bt:1234", "voice": false}` keeps a line silent.

## Preparing the words

| In the text | Becomes |
| --- | --- |
| `$B` | A space; two or more start a new part |
| `$N` (the player's name) | Left out with its comma (*Greetings, $N.* → *Greetings.*), or at a sentence's start; else *friend*, marked for review |
| `$C`, `$R` (class, race) | Left out the same way; else *adventurer*, *traveler*, marked for review |
| `$Gman:woman;` | Two variants, one per player sex |
| `<...>` | A stage direction: taken out, and a matching tag where it says so (*sighs* → `[sighs]`) |
| An emote (`%s growls.`) | Not voiced: it is told, not said |
| A line the game voices itself | Not voiced |
| The quest's objectives | Not voiced (a choice: the window shows them) |

Racial languages need nothing: a line in Common or Orcish is voiced as written; the other side sees it
garbled, its hash does not match, and it stays silent by itself.

## Tone and cadence

Every line gets an analysis, first by rules (`dev/tools/voicedb`, `analyse`), then, where a language model
or a person directed it, by that (*Directing lines*).

| Field | Values | What it does |
| --- | --- | --- |
| `tone` | `earnest`, `friendly`, `warm`, `grateful`, `proud`, `stern`, `urgent`, `worried`, `fearful`, `grieving`, `angry`, `menacing`, `mocking`, `mysterious`, `solemn`, `excited`, `humorous`, `weary`, `expectant`, `plain` | The feeling; it picks the leading tag |
| `intensity` | 1 (calm) to 5 (all-out) | Lowers the stability: more feeling, more variation |
| `pace` | `slow`, `measured`, `brisk`, `fast` | For the direction and the cue; the preset's speed stays (the newest models follow the text and tags, not a speed per line) |
| `volume` | `whisper`, `soft`, `normal`, `raised`, `shout` | `[whispers]`, `[shouting]` |
| `register` | `plain`, `formal`, `archaic`, `rough` | For the direction, and for checking the voice fits (a noble in rough speech is a wrong preset) |
| `tags` | At most two, at the start | The newest models' audio tags |
| `stability` | 0.25 to 0.85 | The preset's, lowered by 0.05 for each step of intensity above 2 |
| `direction` | A sentence | What the actor is told; kept with the line for listening |

**The rules:** words of each tone are counted (*hurry, at once* urgent; *slain, alas, grave* grieving; *thank,
well done* grateful; *ancient, shadow, prophecy* mysterious; ...), and the strongest wins; where none is found,
the moment decides (an offer is earnest, a hand-in grateful, a greeting friendly, a yell urgent, a hostile
yell menacing). Exclamation marks, a boss and a strong tone raise the intensity; a grieving line is soft; short
sentences with exclamation marks are brisk. The rules see words, not meaning: a joke about death reads as
grief. That is what directing is for.

## Directing lines with a language model

For the lines that matter most (the quests of a zone, a story's chain, a boss), a language model reads each
line in its context and writes the actor's direction. It costs little: about 6 million characters of text
are about 2 million tokens.

1. `dev/tools/voicedb batch dev/voices/build/batch-elwynn.jsonl "Elwynn Forest"` writes the lines of a zone (or
   of a quest, a speaker, a key) with their speaker, context and the rules' guess.
2. The model gets the prompt below and 40 lines at a time, and answers with one JSON object per line.
3. Its answers go into `dev/voices/analysis/<name>.jsonl` (in git). The next build takes them over the rules,
   for as long as the line's hash matches; a changed text loses its direction and is marked for review.

The prompt:

```
You direct voice actors for a fantasy role-playing game: the original world of World of Warcraft (patch
1.12). For each line below, write what an actor needs to say it convincingly, in the speaker's character
and in its moment.

Each line gives: its key and hash; the speaker (name, title, race, sex, rank, side); its voice preset; the
stage (offer: the NPC asks the player for help; progress: the player comes back before the task is done;
complete: the player brings it back; greeting; gossip: the NPC talks when the player talks to it; say, yell, whisper:
said aloud in the world; page: a written text read aloud; mail: a letter read aloud); the context (quest,
zone, level, chain); the text as it will be said; the stage directions the game wrote (actions); and a
first guess made by rules.

Answer with one JSON object per line, nothing else, in the same order, with these fields:
- "key", "hash": as given
- "tone": one of earnest, friendly, warm, grateful, proud, stern, urgent, worried, fearful, grieving, angry,
  menacing, mocking, mysterious, solemn, excited, humorous, weary, expectant, plain
- "intensity": 1 (calm) to 5 (all-out)
- "pace": slow, measured, brisk or fast
- "volume": whisper, soft, normal, raised or shout
- "register": plain, formal, archaic or rough
- "tags": at most two, said at the start, from: [sighs], [laughs], [chuckles], [whispers], [shouting],
  [sorrowful], [angry], [menacing], [urgently], [worried], [fearfully], [warmly], [proudly], [solemnly],
  [mysteriously], [excited], [amused], [tired], [sternly], [sarcastic], [curious], [clears throat]
- "emphasis": up to three words of the text to stress, exactly as written
- "direction": one sentence for the actor, at most 160 characters: who they are, what they feel, what
  they want from the player
- "cue": a narrator's lead-in of at most 80 characters that sets the mood, never said (for example
  "The old farmer said, worn out but hoping:")
- "fix": only if the text reads badly when said aloud (a stand-in word, a broken sentence): the text
  mended with as few changes as possible; else leave it out

Keep to the text: never add to it except in "fix". Fit the speaker and the kind of its preset: a common
speaker talks plainly, a martial one short and firm, a refined one precise and measured, an elder slowly
with pauses; a gnome is quick and bright, an ogre slow and blunt, an imp shrill and sly, a boss in battle
all-out. Most quests offered are earnest requests: let the words decide when one is urgent,
sad or funny. Most lines are not extreme: intensity 2 or 3 is usual.
```

## From a line to the request

`dev/tools/voicedb request <key>` shows what the voice tool will send for a line, without sending anything:

| Sent | From |
| --- | --- |
| The voice | The preset's voice, designed once (*Designing the cast*) |
| The text | The tags, then the speech; tags only for the newest model |
| Stability, similarity, speed | The line's stability; the preset's similarity and speed |
| The text before and after | The neighbouring parts' speech; for a first part, the direction's cue |
| The names list | The service's pronunciation dictionary made from `names.md`, in its pinned version |
| The file | `<key>[-<variant>][-<preset>].ogg`: one file per variant and per preset |

- **One request per file,** sent 3 at a time (`--jobs`: the plans allow 3 to 15 on the newest model, twice
  that on the fast one), each answer's request number and cost noted. A file already made with the same
  text, voice, model, settings and names is never sent again (the voice tool keeps a list by the hash of all
  of these).
- **Timing:** the service's timing of each character comes back with the sound; the voice tool keeps it for
  the voice bar and the parts' lengths.
- **The game's files:** WAV from the service, then the start and end silence cut, the loudness made even, one
  channel at 22.05 kHz, Ogg Vorbis of about 40 kbps (`ffmpeg`), into the voice packs.

## The voice tool

`dev/tools/voicegen` sends the voice database's requests to the service and makes the game's files from its
answers. It needs Python 3 and `ffmpeg` with Vorbis, nothing else. Its usage: `dev/tools/voicegen` alone.

### Setting it up

1. **An account with the service, and an API key** made on its website by Saneroki. The full cast needs a
   voice slot per preset (98), so the plan of about $99 (160 own voices, 10 lines at a time on the newest
   model); a trial of a few presets fits a smaller plan. Where the website offers it, the key gets only what
   the tool uses (speech, voices, voice design, pronunciation dictionaries, sound effects, reading the
   account) and a monthly limit of credits.
2. **The config file** `~/.config/saneui/voice-service.json`, on this computer only and readable by its
   owner only: the service's address, the header the key goes in, and the models (*The models*).
3. **The key:** `dev/tools/voicegen key` asks for it without showing it and writes it into the config file;
   `SANEUI_VOICE_KEY` in the environment wins over the file. The key is never written into the repository, a
   commit message or a chat.
4. **The check:** `dev/tools/voicegen account` shows the plan, the characters used and left, the voice slots,
   and how many presets have their voice.

### The models

The config names the service's models by our own names: `newest` (the most expressive, about $0.08 for 1,000
characters), `fast` (about $0.04), `design` (voice design) and `sound` (short sounds). Each says what it
takes, so a new model of the service needs only a new config:

| Field | What |
| --- | --- |
| `sounds` | It reads the names' sounds (IPA): it gets the sounds' dictionary first, then the respellings; the others get the respellings only |
| `leave out` | Settings and fields it does not take: the newest model has no speed |
| `stability steps` | The only stabilities it takes (an older model knew three: 0, 0.5 and 1); a line's stability goes to the nearest |
| `format` | How short sounds come back: raw PCM at 44.1 kHz on the bigger plans, else MP3 |

**For the trial to settle:** whether the newest model takes the text before and after (else its `leave out`
gets `previous_text` and `next_text`) and any stability (else `stability steps`); whether the fast model
says numbers right (it does not spell them out by itself).

### Making the voices

In this order:

1. `dev/tools/voicegen design <preset>`: three previews of the preset's voice in `dev/voices/design/<preset>/`
   (not in git).
2. `dev/tools/voicegen pick <preset> <n>`: the preview kept as a voice of our account, its number in
   `dev/voices/voices.json`.
3. `dev/tools/voicegen names`: `names.md` as two pronunciation dictionaries, the respellings and the sounds;
   sent again only when `names.md` changed, as a new version of the same dictionaries.
4. `dev/tools/voicegen say "Northshire" --dry-run`: what would be sent, how many characters, and what it costs.
5. `dev/tools/voicegen say "Northshire"`: the voices. More than 20,000 characters at once need `--yes`.
   `--model fast` for the fast model, `--preset`, `--limit` and `--jobs` to narrow it.

**What it keeps:**

- `dev/voices/made.jsonl` (in git): a line per file made: the line's key and hash, preset, model, take,
  voice, the service's request number, characters and seconds. A file is known by the hash of all that shapes
  its sound (the text, the voice, the model and its settings, the text before and after, the names in the
  line, the take): a file is never paid for twice, and a new name in `names.md` remakes only its lines.
- `dev/voices/sound/master/<hash>.wav` and `.json`: the service's sound as it came (24 kHz, one channel), when
  each character is said, and the part kept. Not in git, but kept with the backups: it cost money.
- `dev/voices/sound/<model>/<file>.ogg`: the game's files, the two models' side by side for the trial. A file
  lost is made again from its master, without a request.

**Made again:** `--take 2` makes lines once more with another seed; the new take becomes the game's file, the
old one stays in `master/`. A line that sounds wrong gets a direction or a fix first (*Directing lines*); a new
take is for bad luck only.

**When the service says no:** busy or down, the tool waits and tries again; a wrong key or no credits left
stops the run, and what was made is kept.

## Designing the cast

`dev/voices/cast.md` holds one preset per kind of speaker: its design prompt and design text, its settings,
how it delivers its lines, and what to avoid. The voice tool designs them through the service's voice design:

1. The design prompt and the design text go to the service, which makes three previews.
2. A person listens and picks one; the tool saves it as a voice of our account (a voice slot) and notes its
   number in `dev/voices/voices.json` (in git), so every line of that preset uses the same voice.
3. A preset that sounds wrong gets a better prompt, not a clone: every voice is designed from its description
   only, never made from recordings, so the voices are our own.

**A good design prompt** says, in this order: *Native English*, the sex and the age, the people and the
character in plain words, the timbre, pitch, pace and accent, the attitude, and *Perfect audio quality.* No
effect words (*reverb*, *echo*, *radio*): they spoil the design. Each race keeps the character of its own
voices in the game (a dwarf's burr, a troll's lilt, an undead's dry rasp) without copying them.

**Five samples** for Sane Sync's *Hear a sample* (`Doc/ideas/SaneSync.md`) are picked after the trial: the
narrator and four voices of different races, sides and sexes.

## Listening

Before a pack is built, a person listens to a sample of each preset and each stage, and to every line marked
for review:

- the voice fits the speaker (race, age, standing) and the line's moment;
- the names are said as `names.md` says;
- no word is added, left out or garbled; no tag is said aloud;
- the loudness matches the other lines; no clipping, no long silence;
- a line that fails gets a direction or a fix and is made again (perhaps 15% of the lines).

## Short sounds

The sounds of windows and buttons: a click, a toggle, a whoosh, a soft chime, a tenth of a second to two
seconds long.

1. **The game's own sounds first:** `PlaySound(SOUNDKIT.<NAME>)` costs nothing, ships nothing and sounds like
   the game (the names: `SoundKitConstants.lua` in `references/BlizzardInterfaceCode/`; which sound for what:
   `Doc/guides/gui-development.md`, *Windows*). A sound is made only where the game has none that fits.
2. **Made by the voice service:** `dev/tools/voicegen sound <name> "<what it sounds like>" --seconds 0.5` makes
   four candidates in `assets/generated/sounds/` (not in git), each as it came (`.wav`) and as the game would
   play it (`.ogg`), and notes how in `sounds.jsonl` there. It is good at whooshes, chimes and sparkles; a
   single clean click often comes with a tail or a second hit. It costs about a fifth of a cent a second.
3. **Made on this computer:** a sound model in ComfyUI, where the pictures are made
   (`Doc/guides/image-generation.md`): Stable Audio's small sound-effect model, which ComfyUI runs as it is.
   Made 3 to 5 seconds long over many seeds, the best part cut out. The plainest blips and ticks are best
   made by `ffmpeg` itself (a few sine tones that fade, a few milliseconds of filtered noise): exact, and the
   same every time.
4. **The game's file:** `dev/tools/voicegen ogg <chosen.wav> src/<Module>/Sounds/<name>.ogg --ui`. The quiet
   at the start is cut (the sound starts at once), 30 ms kept at the end, a 3 ms fade in and 20 ms out, the
   peak set to -1 dB (a loudness measure needs longer than a click lasts), one channel at 44.1 kHz, Ogg Vorbis.
   Played with `PlaySoundFile(path, "SFX")`, so the game's sound volume governs it.

**A prompt** says the sound, its material and its length, not a feeling: *a short soft click of a wooden
toggle, dry, close*; *a quick airy whoosh of parchment unrolling*; *a gentle two-note magical chime, bright,
fading fast*. Each candidate is heard next to the game's own sounds, and only one that blends with them is
kept.

## Numbers

Measured on the database as built on 2026-10-17 (the vanilla baseline and build 70425's own tables;
Forever's own texts to come, perhaps a million characters more):

| | |
| --- | --- |
| Texts, parts | 27,909 texts in 36,743 parts; **26,229 parts voiced**, said by 3,249 speakers |
| Presets | 98 in the cast, 87 in use; most used: the reader (3,053 parts), human men, dwarf men, orc men, goblin men |
| Characters | **4.31 million** with every variant and preset, about **80 hours** of speech |
| Cost | about **$345** on the newest model, **$172** on the fast one, before lines made again |
| By stage | offers 1.47M, hand-ins 0.94M, NPC talk 0.80M, progress 0.44M, pages 0.43M, says 0.13M, the rest 0.10M |
| Not voiced | 5,629 nobody known says (most of them unused texts), 3,870 objectives, 648 emotes, 275 voiced by the game, 92 empty or filler |
| To look at | 665 sex unknown, 457 a name said as *friend*, 432 a class or race said as a stand-in word, 289 race unknown, 32 a placeholder left |
| Directed | 53 parts: the quests of Northshire (`dev/voices/analysis/northshire.jsonl`, by a language model) |

`dev/tools/voicedb stats` prints them again after every build.

## Commands

```bash
dev/tools/voicedb build
```

```bash
dev/tools/voicedb stats
```

```bash
dev/tools/voicedb show "Marshal Dughan"
```

```bash
dev/tools/voicedb request quest:62:offer
```

```bash
dev/tools/voicedb names 80
```

```bash
dev/tools/voicedb check
```

```bash
dev/tools/voicegen account
```

```bash
dev/tools/voicegen say "Northshire" --dry-run
```
