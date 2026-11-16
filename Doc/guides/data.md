# Data

How Sane UI keeps its own databases: the master in the repository, the tools that check and compile it,
the set files Core carries into the game, and what a module reads. Read this before adding data, writing a tool that makes
data, or changing the framework. Why it is built this way, and what is still to come, is in the plan
[Doc/ideas/Data.md](../ideas/Data.md); the order of the work in [Data-build.md](../ideas/Data-build.md).

**This guide is the reference.** The formats and answers below are contracts: two sessions that keep to
them build parts that fit. Where this guide and the plan differ, the guide wins; where the guide and the
code differ, the code is wrong or the guide is out of date, and one of them is mended in the same commit.
Parts not built yet are marked with the step that builds them (*1c*, *1f*, ...).

Core and its data are the backend; the modules are logic and views on top (CLAUDE.md, *Backend and views*).
A module only reads. Gathering, keeping, checking, sharing and telling about changes are the framework's.

## The parts

| Part | Where | What |
| --- | --- | --- |
| The master | `assets/data/` | The truth: plain text, one line per version of an entry, every source. Never shipped. |
| The tools | `dev/tools/data`, Python in `dev/data/` | Check the master, take in staging, compile Core's set files, show and compare entries. |
| Staging | `dev/data/staging/` (not committed) | What a tool read from a source, in one neutral format, waiting to be taken in. |
| The set files | `BUILD/SaneUI/Sets/` (not committed) | Part of Core, made from the master by `dev/build`: a Lua file per set, listed at the end of Core's TOC, read with Core at the login. |
| The engine | `src/Core/Data/` (in `SaneUI.toc`) | `Steps.lua` (the scheduler), `Codec.lua` (a row's string into a record), `Data.lua` (the sets, the answers, the data's saved variables), `Characters.lua` (what the account's characters have: *Characters*). |
| Tests | `dev/tests/data/` (tools, sample masters, `sets.py` for a module's tests), `dev/tests/data.lua` (in the game) | Run by `dev/tests/run`. |

## Words

| Word | Meaning |
| --- | --- |
| **Set** | One kind of thing keyed by one ID (*Items* by item ID). What a module asks for, by name. |
| **Entry** | One thing in a set: the item 16801. |
| **Version** | An entry's facts from one build (and day) on. An entry has one or more, oldest first. |
| **Build** | The game's build number (`GetBuildInfo`, second answer), the clock of versions. |
| **Game version** | One game as one kind of client plays it: `forever`, `forever-ptr`, `retail`, `retail-ptr`, `retail-beta` (`forever-beta` only in older files: the beta is gone). |
| **Source** | Where a fact came from: the game, a person (`hand`), or a numbered batch of staging. |
| **Set file** | A set compiled for one game version: `Sets/<Set>.lua`, one of Core's files. |
| **Row** | One version of an entry as one string in a set file. |
| **Record** | A row taken apart in the game: a table of field = value. |

## Game versions

Facts of one game version never reach another (the plan, *Game versions kept apart*).

- **Names:** `forever` (live) and `forever-ptr`; `retail`, `retail-ptr` and `retail-beta` (Retail's data comes later;
  `forever-beta` stands only in older files, the beta being gone). A name ending in `-ptr` or `-beta` **stands on**
  the name without it: its set files are live's with its own on top.
- **Short signs** for messages (`SIGNS` in `Wire.lua`): `f`, `p` (Forever's PTR), `r`, `t` (Retail's PTR), `q` (Retail's beta).
- **The client's game version** (`Data.Game()`): `Core.GAME` first, from `WOW_PROJECT_ID` (`WOW_PROJECT_CAMELOT`, 18,
  is Forever; `WOW_PROJECT_MAINLINE`, 1, is Retail). Then `IsBetaBuild()` gives `-beta`, else `IsPublicTestClient()`
  or `IsTestBuild()` gives `-ptr`. Any other project, or a missing answer, gives nil: **a client that cannot be told
  refuses every set.**
  `/sane data` prints the three answers, so the game shows what each client says.

## Game facts and personal data

The set files are shared by every player and hold facts about the game; the saved files also hold what is the
player's own, which never leaves the computer but into the player's own backups (Saneroki, 2026-10-18).

| Kind | What | Kept in | Goes |
| --- | --- | --- | --- |
| **Game facts** | The same for every player of a game version: items, quests, NPCs, objects, places, drops, vendors, trainers, travel; the markets per auction house | The master and Core's set files; learned ones in `learned` and the series | Into the set files; learned ones by sharing and the harvest |
| **Guild records** (Saneroki, 2026-10-20) | What a player shares about its own characters with its own guild (who they are, what they wear, their professions: the card; more kinds as the module Guild grows), the guild's roster and its history | Core's saved variable `SaneUIData_Guild`, per guild | To the guild's Sane UI only (`Data.Guild`, below), never into the set files, the harvest or any service |
| **Personal** | The account's characters (their bags, bank, money, gear, level, progress), the auction log and own auctions, mail, settings, profiles, layouts, notes and aliases of players (Core.People), players' names (sellers, senders, friends, guilds) | `SaneUIDB`, `SaneUICharDB`, `SaneUIData_Characters`, a module's own saved parts | Nowhere: shown to the player only |

- **A set holds game facts only:** no field for a character, an account, a guild, a GUID or a player's name,
  and no source in `sources.toml` names a player.
- **Learned facts are stripped where they are gathered:** a text with the player's name, race and class put
  back as the game's placeholders (`$N`, `$R`, `$C`); a place as the thing's place, never the path the
  player walked; times no finer than the day; prices without sellers.
- **Personal data stays out of `learned` and the series:** sharing and the harvest read only those, never
  `SaneUIData_Characters` or a part kept for the player's own views (the last whole auction
  scan with its sellers, the auction log).

## The master: `assets/data/`

```
assets/data/
  builds.toml               the builds of every game version: patch and first day
  sources.toml              every source a line may name
  <Set>/
    schema.toml             the set: its key, fields and indexes
    <Set>.jsonl             Forever live's lines, written by the tools
    <Set>.<game>.jsonl      another game version's lines: only what it showed otherwise (<Set>.forever-beta.jsonl)
    <Set>[.<game>].<from>.jsonl   a big set split by key range (int keys only): the keys from <from> to the next file's
    fixes.jsonl             hand fixes of live's lines (fixes.<game>.jsonl for another game version), written by people
```

- **Tools write the master, people write the fixes.** A set that no tool feeds (a short hand-made list) is
  written by hand directly, with the source `hand`.
- No other file belongs in a set's folder; the check says so.
- Corrections of our own mistakes are made in place (`--take`, or by hand in a tool-written file): git
  keeps what a line said before. Versions record what Blizzard changed; git records what we corrected.

### builds.toml

```toml
# The game's builds, per game version: the patch each build is, and the first day it was seen.
[forever]
70245 = { patch = "1.60.1" }

[forever-ptr]

[forever-beta]
70450 = { patch = "1.60.1", day = "2026-10-17" }
```

- A table per game version, also an empty one: these are the game versions the tools know.
- A key is a build number, `patch` its version (*1.60.1*), `day` (optional) the first day it was seen.
- Every `since` other than 0 names a build of its own game version here. Builds are compared only within
  one game version.

### sources.toml

```toml
[game]
kind = "game"
about = "The game itself: its code (the newest export of its interface) and tables, its API, our crawls, scans and learned data."

[hand]
kind = "hand"
about = "Written by people: hand-made sets and the fixes."

[1]
kind = "batch"
game = "forever"
seen = "forever-beta"
build = 70450
about = "What our tool read of every quest, 2026-10-20."
```

- **Kinds:** `game` (the ground truth: wins over imports), `hand` (applied last), `batch` (one batch of
  staging from one of our tools; it fills in what the game does not tell an addon).
- A batch names the game version its lines go to (`game`), where it was seen if that differs (`seen`: a
  batch seen on the beta counts as live's base, decision 27), and the build it was read at (`build`,
  optional).
- A source's name is a number (a batch) or a word. In a line's `src` a number is written as a number.

### schema.toml

```toml
set = "Items"
key = "int"              # Blizzard's ID; "text" for a set keyed by a name (CVarLabels)
learn = true             # the game may teach it in play (Learned, step 1c)
history = false          # optional: the set files carry only the newest versions (a big set no view asks the past of)
about = "Every item players can have: what the game says about it, with its history."

[fields]
name    = { type = "text" }
quality = { type = "int", min = 0, max = 8 }
slot    = { type = "enum", values = ["head", "neck", "shoulder", "back", "chest", "wrist", "hands", "waist", "legs", "feet"] }
stats   = { type = "map", keys = "text", of = "int" }
sell    = { type = "money" }
from    = { type = "list", of = "ref", set = "NPCs" }

[index]
bySlot = "slot"
```

- **Field order is the order in `[fields]`.** It is the order of a row's fields in the set's file, so a field
  is added at the end, and never moved or removed once the set is shipped (a field no longer wanted
  stays, unused). Old lines simply lack a new field.
- `about` says in one sentence what the set holds.
- **`play`** (optional): how play tells each field, for Core's checks in play (*Checked in play*): `"name"` a field
  the game shows whole; `"startNPCs.npc"` a list of tuples the game shows one member of at a time (the giver talked
  to), known by that part; `"services[]"` a list of plain values shown one at a time; `"health{}"` a map shown one
  key at a time (the health at the level seen); a trailing `?` a field the game shows only where our data is wrong
  (a requirement an offer proves wrong): play can correct it, never confirm it, so it does not hold back a whole
  confirmation. An entry is confirmed whole once the game told every field of the list (but the `?` ones) that it
  holds; without a list, every field counts. `Quests`: `play = ["name", "level", "minLevel?", ..., "startNPCs.npc"]`.

**Types:**

| Type | In a line of the master | Parameters |
| --- | --- | --- |
| `int` | a whole number | `min`, `max` |
| `number` | a number | `min`, `max` |
| `text` | a string, not empty, without a tab or the characters 28, 30, 31 | |
| `bool` | `true` (false is not written: it is no value) | |
| `enum` | one of the words | `values` |
| `flags` | a whole number from 0 (a bit mask) | |
| `money` | a whole number of copper from 0 | |
| `point` | `[map, x, y]`: the map's ID, x and y in percent of the map, 0 to 100, at most one decimal | |
| `ref` | a key of another set, which must exist | `set` |
| `tuple` | an object of named parts, each one of the types above but `point` | `parts`: `[{ name = "kind", type = "enum", values = [...] }, ...]` |
| `list` | an array of elements | `of`: the elements' type (any above); their parameters on the field (`values`, `set`, `min`, `max`, `parts`) |
| `map` | an object, key to element | `keys`: `"text"` or `"int"`; `of` and parameters as a list |

- **No deeper nesting:** a list or map of lists is refused by the check. Such a field becomes two fields, or
  a set of its own.
- **Indexes** (`[index]`: name = field) list the keys of the entries by a field's value, worked out by the
  compiler from each entry's newest version. The field is an `int`, `text`, `enum`, `ref`, `flags` or
  `money`, or a list of one of these (each element counts), or one part of a tuple or a list of tuples,
  written `field.part` (`byItem = "goods.item"`: each element's part counts). An entry is listed once per
  value. The names `replaces` and `replacedBy` are the compiler's own (below).

### The sets

Every set of the plan (*Sets by concern*, *The game's own data*) has its schema; its fields and indexes are
in `assets/data/<Set>/schema.toml`. **A set without entries may still change its fields freely;** once it
is shipped, the rule of *schema.toml* holds (a field only added at the end). Real data comes with
prompt 2, which settles what the game gives. Grouped by concern (the plan, *Sets by concern*); every set is
part of Core.

| Concern | Sets and their keys |
| --- | --- |
| Items | Items (item ID), ItemSets (item set ID), Disenchants (the game's row of disenchanting), Enchantments (enchantment ID) |
| Quests | Quests (quest ID), ClassQuests (a chain, numbered by hand: its class × 100 and its place) |
| World | NPCs (creature ID), CreatureSpells (spell ID), Objects (object ID), Zones (map ID), Travel (the game's TaxiPath ID; our own number for a way it has no path for), Places (our own numbers), Drops (`npc:<ID>`, `object:<ID>`, `zone:<map ID>`), Tiles (continent × 4096 + row × 64 + column), Overlays (the game's overlay ID), Indoors (the building's root file ID), Encounters (encounter ID), Bosses (encounter ID), Dungeons (the instance's map ID; Forever's new dungeons, which the game ships no map art of: a floor each made from their ground by `dev/tools/dungeon-ground`, no tiles), DungeonGround (the instance's map ID: each floor's minimap textures), Instances (the game's group-finder row, `LFGDungeons`; an instance Blizzard announced that the client does not hold yet: our own number from 100001, replaced by the game's row once the client holds it: what the group finder lists and Blizzard announced, levels, players, the instance's map, a raid's day), Fishing (area ID: the fishing skill its waters ask, the original game's, kept apart from the game's Areas until play confirms it) |
| Spawns | Spawns (`npc:<ID>`, `object:<ID>`), QuestAreas (`<quest>/<objective>/<stage>/<map>`), PatrolPaths (creature ID) |
| CreatureSpawns | CreatureSpawns (creature ID) |
| Routes | Walking (a terrain tile: continent × 4096 + row × 64 + column) |
| Guides | Guides (a guide, numbered by our tool) |
| Spells | Spells, Auras (spell ID), Trainers (the rank's spell ID), QuestSpells (`<spell ID>/<way>`), WeaponSkills (the teaching spell's ID), SkillLines (skill line ID), Professions (the recipe's spell ID) |
| Characters | No sets: saved data only (*Characters*) |
| Talents | Talents (trait node ID), Legacy (`node:<ID>`, `challenge:<ID>`, `reward:<level>`) |
| Market | Vendors (the vendor's creature ID); the series *Prices* (step 1c.2) |
| Game | CVarLabels (the CVar's name), Currencies (currency ID), Factions (faction ID), FactionTemplates (faction template ID: each one's reaction to each side's players, worked out from the client's table; an NPC's `faction`), Holidays (holiday ID), Races (race ID), Racials (the game's ability ID), Classes (class ID), Maps (map ID), Areas (area ID), PatchNotes (the build), Icons (the icon's file number) |
| Collections | Achievements (achievement ID), Mounts (mount ID), TransmogSets (transmog set ID) |

- **A text key `<kind>:<ID>`** where one set holds things whose IDs overlap (a creature and an object can have
  the same number); **a text key of parts** where an entry is one of several per thing (an area per
  objective, stage and map).
- **Our own number** where the game gives none; the schema's comment says how a staged thing is matched to
  an entry already there.
- **A thing with several parts per entry** (a guide's steps, a quest's objectives) is a list of tuples whose
  parts say which step or objective a row belongs to: a list holds no list (*Types*). A quest's objectives
  carry their number in the game's list (`index`, `C_QuestLog.GetQuestObjectives`): the data may know only
  some of them.
- **A quest a requirement names** (`requires.quest`) is the game's quest ID, also of a quest the set does not
  hold: the game tells whether it is done.

### The icons

`Icons` (Saneroki, 2026-11-04, for Sane Macros' picture window) holds every icon the client of each game holds, by its
file number (what a texture is set to, the same number for one file in both games): its `name` (the file's, without
`.blp`, as the client spells it) and, in Forever, what of the game shows it: `classes` (whose class lines' spells),
`spells` (the first rank of a few players' spells), `items` (a few items, the best first) and `itemClasses` (of every item
that shows it); indexes `byClass` and `byItemClass`; `history = false`. `dev/tools/icon-data` (`saneui readicons`) stages it
from the newest export's art list (`files.tsv`, the files of `Interface/ICONS` the client holds whole) and the master's
Spells, SkillLines and Items, source `game`: one line per icon for each game, `icons-<game version>.jsonl`, an icon
the newest export no longer holds gone. Retail has the set too, as PatchNotes, with the names alone: its spells and items
wait. About 30,000 icons a game, some 1.8 MB of set file each.

### The patch notes

`PatchNotes` holds a build's notes for a view in the game; `/patchday` writes it (`Doc/guides/blizzard-updates.md`, *Patch
day*), and Retail has it too. A record is what the notes say of one build:

```lua
local Notes = Data.Set("PatchNotes")
local notes = Notes:Get(70707)                 -- patch, from, official, sane, points, changes, counts
for _, point in ipairs(notes.points) do
    -- point.section, .group, .sub, .kind ("point", or "extra" and "note" of the point before it), .text, .was,
    -- .origin ("both", "client", "blizzard"), .link, .class (Classes), .race (Races)
end
for _, change in ipairs(notes.changes) do
    -- change.set, .key (as text), .how ("new", "changed", "gone"), .fields (joined by commas), .class, .race, and
    -- .point: its place in notes.points. The values: Data.Set(change.set):Changes(tonumber(change.key) or change.key)
end
local builds = Notes:Keys("byClass", 7)        -- every build that speaks of a class; also byRace, byPatch
```

`counts` says per set how many entries changed, also of a set whose entries are not listed (Walking, Tiles). Facts stand in
their own sets with their history: a racial's change is `Data.Set("Racials"):Changes(680)`.

### A line of the master

```json
{"key":16801,"since":0,"src":[3],"name":"Arcanist Gloves","slot":"hands","stats":{"int":10,"spi":5},"sell":1550}
{"key":16801,"since":65100,"day":"2026-11-03","src":["game"],"stats":{"int":8,"spi":5}}
{"key":19999,"since":65100,"src":["game"],"gone":true}
```

- **Keys in this order:** `key`, `since`, `day`, `src`, `verified`, `gone`, `replaces`, then the fields in schema order.
  The tools write every line so, with `,` and `:` and no spaces, map keys sorted, and the lines sorted by
  key (numbers by value, texts by their characters), then `since`, then `day`. The check refuses another
  order in a file the tools write; a fixes file only has to parse and fit.
- **`key`:** a whole number or a text, as the schema's `key` says.
- **`since`:** the build from which the version holds; 0 means "as far as we know, from the start".
- **`day`:** the server's day of the version (`YYYY-MM-DD`), left out where it is not known. The game's word
  at the same build on a later day is a new version (a hotfix).
- **`src`:** the sources that said it, a non-empty list, each in `sources.toml`; a numbered batch's
  `game` is the file's game version.
- **The first version holds every fact known;** each later one holds only the fields that changed, each in
  full. `null` clears a field (never in a first version).
- **`verified`:** `{"day":"2026-11-07","times":3}`: the game confirmed this version in play (*Verified*): the day of
  the import that took the newest confirmation in and how many imports confirmed it; nothing more. Only the import
  writes it.
- **`gone`:** `true` alone: the game removed the entry from that build on. A gone line holds no fields. A
  version after a gone one is a first version again (the entry came back).
- **`replaces`:** in an entry's first line only: the key of the entry of the same set the game swapped for
  this one. Only this side is written; the compiler adds the other.
- **Every later version changes something,** and no version leaves an entry with no value (that is `gone`).
- **No two lines of one entry** have the same `since` and `day`.

### Fixes

`fixes.jsonl` (live) and `fixes.<game>.jsonl` hold corrections by hand, applied last, after the tools'
lines. A fix line has `key`, `since`, `day` (if the version has one), `src` (`["hand"]`) and fields: it
matches the version line of the same key, `since` and `day`, and its fields replace that line's (`null`
clears). An import compares against the master without the fixes, so taking in a source again never fights
a fix. **The check warns when a later version from the game changes a field a fix sets:** the game may have
mended it itself, and the fix may be stale.

### Another game version's files

`<Set>.forever-beta.jsonl` holds only what the beta showed otherwise, on top of live's files: its lines are
written against the beta's view (live's newest version of each entry, with the beta's own versions on top).
An entry live does not have starts with a full first line there. Its `since` values are the beta's builds:
the check refuses a line whose build belongs to another game version, or whose batch source says another
`game`.

Such a line says what the other game version shows *otherwise*. When live comes to say the same, the import keeps
only what the line still changes and drops one that changes nothing any more (`_catch_up`), and a game version with
no line left in a set has no file there.

## Staging and the import

A tool that reads a source writes staging, never the master: one JSON object per line.

```json
{"set":"Items","key":16801,"game":"forever","build":65100,"day":"2026-11-03","src":"game","fields":{"armor":36}}
{"set":"Items","key":19999,"game":"forever","build":65100,"src":"game","gone":true}
```

- `set`, `key`, `game` and `src` (one source's name) are needed; a line without its game version is
  refused. **`confirmed`** (a day, `YYYY-MM-DD`, from the game alone and with nothing else to say): the game confirmed
  the entry in play that day (the harvest). `build` (0 when not known) and `day` are optional; `fields` holds what the source says, `null`
  for a field it says is empty; `gone` and `replaces` as in the master. A field left out says nothing (the master
  keeps its value), so a tool stages `null` where the source alone holds a field and holds nothing: `dev/tools/game-data`
  for the fields of its `CLEARED` (a spell's forms, a talent's values per rank, an item's stat kinds), the others not yet.
- Staging files go into `dev/data/staging/` (not committed).

`dev/tools/data import <file>` prints a report and changes the master only with `--apply`. Every rule holds
within one game version: a staged fact is compared with its own game version's view and written only into
that game version's files.

| Case | What happens |
| --- | --- |
| **New:** an unknown key | A new entry, its first version `since` the staged build. |
| **Agreeing:** every staged field equals the version current at that build | Nothing changes; the source is added to that version's `src`. |
| **Changed:** a field differs, the source is the game, at a newer build than that version, or the same build on a later day | A new version with the fields that differ. |
| **Conflict:** a field differs otherwise (an import against the game, two values for one build) | Listed, not applied. `--take` writes it into that version as a correction. |
| **Older:** the staged build is older than the entry's first version, and a field differs | A new first version in front: the old first version's facts with the staged ones put in; the old first version keeps only what differs from it. |
| **Gone:** the game (or a person) says the entry is gone | A gone version. From a batch: refused (missing from a source is no proof). |
| **Replaces:** a new entry names the one it replaces | Written into its first line; a different `replaces` for a known entry is a conflict. |
| **Verified:** a confirmation (`confirmed`) of the version current at its build (the newest, at a build the master does not know) | Its `verified` mark written (`times` 1, the import's day), or one more time and the import's day for a confirmation seen after the mark's day; at most once an import per version. Another game version's confirmation of an entry it has no line of is live's (the version it stands on). |
| **Refused:** an unknown set, game version, source or field; a value that does not fit; a build not in `builds.toml`; a batch of another game version | Listed with the reason. |

- Fields a source does not have are left alone: sources are partial.
- Staged lines of one entry are taken in order of build and day, each against what the ones before made.
  **Live's lines are taken in first,** so another game version stands on what the import made of live.
- **A staged line without a day** is compared with its build's newest version: the game at a build the
  master has a day for, saying otherwise, is a conflict, since which came first cannot be told.
- **A change between two versions** (the game at a build between them): the later lines keep only what they
  still change, and one that changes nothing any more is dropped, its sources going to the version before.
- **An entry that comes back** after gone (the game at a later build) starts with a whole first version of
  the staged facts.
- **What `--take` does not mend:** a conflict with a gone version or a gone at a build with later versions,
  and a different `replaces` for an entry another game version stands on. Those are mended by hand.

## The check

`dev/tools/data check` (run by `dev/tests/run`; `dev/build` stops on it, so a broken set file is never made):

- `builds.toml`, `sources.toml` and every schema parse and fit their formats; every `ref` names a set, every index a field of an indexable type.
- Every set folder holds only its own files; every line parses and fits its schema and the rules of *A line
  of the master*, in order, in the right game version's file, its key in the file's key range.
- Every `ref` and every `replaces` points at an entry that exists in that game version's view. A set with no
  entries at all in that view is still to be filled: the refs into it are checked once it has some (the
  quests' items point into Items before it is filled).
- Every fix matches a version; a fix that the game may have overtaken is a warning.
- Text holds no tab and no character 28, 30 or 31.

Errors fail; warnings are printed.

## Compiling: the set files

`dev/tools/data compile <dir> [--game <game version>]` (run by `dev/build`, step 1a.3) writes
`<dir>/Sets/<Set>.lua` for every set that has entries in that game version's view, removes the files there
of sets it no longer makes, and leaves a file that did not change as it is. `<dir>` is Core's built addon
(`BUILD/SaneUI`; for a beta's or PTR's game folder, the game's copy of Core): when it holds Core's TOC, the
files are listed at its end (*Core's TOC*). **The same master always gives the same bytes:** no date, no
clock, entries sorted by key.

- **Live's set files** come from live's files only.
- **Another game version's set files** stand on live: for every entry, live's newest version becomes the
  base (since 0), and that game version's own versions follow on top. Live's history is not in them.
- Fixes are laid on the lines first; then every version is worked out whole (the game never adds up
  changes).
- **`build`** of a set is the newest build its own game version's lines know: their `since`, and the
  `build` of their batches.
- **`S.unverified`** (after the rows, only where there are any): the keys, joined by character 30, of the entries
  whose newest version the game has not confirmed: none of its sources is of the kind `game` or `hand`, and it has no
  `verified` mark (another game version's entry standing on live's: live's newest line decides). `Handle:Unverified`
  reads it (*Verified*).
- **`hash`** of a set is the first 8 hex digits of the SHA-256 of its file, written with the hash as
  `00000000`. A module that keeps something worked out from a set knows by the hash when it is stale.

### Core's TOC

Every set is part of Core (Saneroki, 2026-10-21): the game reads all of them with Core, in the loading
screen, before any module. The data is wanted in the game anyway, and the cost was measured small (the
whole master, 22 MB of set files: about 0.1 s of loading screen and 25 MB of memory, none of it on the
graphics card), so nothing is loaded on demand and the addon list shows no data. The build ends Core's TOC
with:

```
# The data sets: made by dev/tools/data from the master in assets/data; change the master, not these files.
Sets\Achievements.lua
Sets\Auras.lua
...
```

- What follows that line is the compiler's: a compile replaces it. `src/Core/SaneUI.toc` itself lists no
  set file.
- **The data's saved variables** are Core's too, declared in its TOC: `## SavedVariables: SaneUIDB,
  SaneUIData_Characters, SaneUIData_Guild, SaneUIData_Learned, SaneUIData_Shared` (*Saved variables*); `Data.SAVED` names them, and
  `dev/tests/lint` fails when the TOC lacks one. The auction data alone has a file of its own (*The full auction
  scan*): `SaneUI_AuctionData` declares it, and `Data.APART` names it.

### A set's file

```lua
-- Made by dev/tools/data from assets/data/Items; change the master, not this file.
local S = SaneUI.Core.Data.Add(1, "Items", {
    game = "forever", hash = "3f9a2c1e", build = 65100, key = "int",
    fields = { "name", "quality", "slot", "stats", "sell" },
    types = { "text", "int", "text", "map text int", "int" },
    patches = { [65100] = "1.60.2" },
})
if not S then return end
local R, H, I = S.rows, S.history, S.index
local function Fill(f) f() end
Fill(function()
R[16801] = "65100\t20760\tArcanist Gloves\t3\thands\tint\0318\030spi\0315\t1550"
R[16802] = "0\t\tArcanist Boots\t3\tfeet"
end)
Fill(function()
H[16801] = "0\t\tArcanist Gloves\t3\thands\tint\03110\030spi\0315\t1550"
end)
I.bySlot = {}
Fill(function()
I.bySlot.feet = "16802"
I.bySlot.hands = "16801"
end)
```

- `Data.Add(format, set, header)` gives nil for a format, set or game version this Core does not take (a
  type the codec does not know, or a set another file handed over first, too): the file stops there, and
  the set is refused (said once). Otherwise the set is ready from then on: nobody reads it before its file
  has run to its end, and its listeners are told on the next frame.
- **`R`** holds every entry's newest version; **`H`** the older ones, oldest first, joined by character 28,
  only for entries that have them; **`I[index][value]`** the keys, joined by character 30, sorted.
- **At most 50,000 statements per `Fill` function:** Lua 5.1 stops at 262,143 constants in one function, and
  a file over it does not load at all.
- **`types`** are the decoder's, reduced from the schema: `int` (also `money`, `flags` and a `ref` to an
  int-keyed set), `number`, `text` (also `enum` and a `ref` to a text-keyed set), `bool`, `point`,
  `tuple(name:type,...)`, `list <element>`, `map <int|text> <element>`.
- **`patches`** names the patch of every build the set's versions start at (from `builds.toml`).
- **`play`**, where the schema has one: its list as written (*schema.toml*), for `Data.Check`.
- **`S.unverified`**: the entries whose newest version the game has not said whole: an entry is verified only when
  each field it holds was last written by a line of the game's (or a person's), or a confirmation from play (a
  `verified` mark) came after it. A field the game changed alone leaves the batch's other fields unverified.
- The compiler's own indexes: `replaces` (new key → the old one) and `replacedBy` (old key → the new one).

### A row

`build \t day \t field1 \t field2 ...`

- **build** a whole number; **day** the server's day as days since 1970 (empty where not known).
- A tab between fields; inside a field, character 30 (`\030`) between the elements of a list or map,
  character 31 (`\031`) between an element's parts (a map's key and value, a point's map, x and y, a
  tuple's parts). Game text holds none of them, so nothing is escaped and a row is taken apart with plain
  finds. **An empty part is no value,** of every type: an empty element of a list is a hole (those after
  it keep their places), an empty value of a map no key. Empty fields at a row's end are left out, and so
  are empty parts at a tuple's end (`1\031loot\031182`, not `1\031loot\031182\031\031\031`).
- **A row of only a build and a day is a gone version.**
- **Values:** whole numbers as they are, other numbers as `%.14g`; `bool` `1` or empty; `point` `map\031x\031y`.

## In the game

### What a module reads

```lua
local Data = SaneUI.Core.Data

local Items = Data.Set("Items")     -- a handle: cheap, never nil; one per name
```

| Call | Gives |
| --- | --- |
| `Items:Get(key)` | The record of the newest version this client has reached: field = value, also `since`, `day` and `patch`. nil: not known, the set not there, no such entry, gone. |
| `Items:Get(key, field)` | One value of that record. |
| `Items:At(key, build)` | The record as it was at that build, or nil (not there yet, gone). |
| `Items:History(key)` | An array of records, oldest first, each with `since`, `day`, `patch` (none for `since` 0) and, for a gone version, `gone = true`; its newest is the record `Get` gives. nil when not known. |
| `Items:Versions(key, n)` | The last n of `History`, oldest first. |
| `Items:Changes(key)` | An array, oldest first, of `{ since, day, patch, field, from, to }`, one per field that changed, in the set's order of the fields (an entry gone: `field = "gone"`, `from = false`, `to = true`; back again the other way round). An empty array for an entry that never changed. |
| `Items:Keys(index, value)` | An array of keys from the entries' newest versions (`replaces`, `replacedBy` too); an empty one when none. |
| `Items:Each(fn, done)` | A job: `fn(key, record)` for every entry the client has (gone ones left out), out of combat, within the budget; then `done(problem)`: nil after the last entry, the error's text when `fn` failed (the walk stops there; noted under one label per set, `data job Each Items`). Gives the job's handle (`:Stop()`); false when the set is not there. |
| `Items:Stamp()` | A number that moves when the set arrives, when Core learned an entry of it in play (*Learned*), and later when accepted data changes it. |
| `Items:OnStamp(fn)` | `fn(handle)` on the frame after the stamp moved, never inside the set's file (a listener may start a job, or run `Steps.Check`): a view redraws then, instead of looking every frame. A `fn` given twice is told once; its failure is noted as `data: Items listener`. |
| `Items:OffStamp(fn)` | Stops telling `fn`: one given to `OnStamp`, or one waiting in `WhenReady`. |
| `Data.WhenReady(Items, fn)` | `fn(handle)` once the set (its handle or its name) is ready: at once if it is, in the caller's own call; else on the frame after it arrived, once. As a rule a set is there before any module asks. |
| `Items:State()` | `"ready"`; `"refused"` (another format or game version, or the client's cannot be told) or `"missing"` (Core holds no such set), and a few words why; `"loading"` only while Core's own files are still being read. |
| `Items:Ready()` | `State() == "ready"`. |
| `Bosses:Unverified(key, part, own)` | Whether the entry (or a part of it: a boss's item `"l17076"`, an ability `"a8269"`) is not yet confirmed by the game: listed in its set's file (`S.unverified`) and not confirmed in play since (*Verified*), here or by members; `own`: not by the game here, what members told aside (Core's watchers ask so before they confirm). False for an entry learned in play, one the set lacks, a set not ready. |
| `Items.hash`, `Items.build` | Where the data came from: its hash, the newest build it knows (nil while the set is not there). |

- **What this client has reached:** a set made for a later patch than the client's build answers with the
  versions that build has; `History`, `At`, `Changes` and `Each` stop there too. `Keys` come from the set's
  newest versions, so on such a client `Get` of one of them can be nil.
- **nil means not known.** No read ever raises an error, also on a set's values of the wrong kind (a row,
  a history or an index that is no text or table is no entry), and a read is always cheap: one table index
  and, the first time, one row taken apart (about 2.5 µs); a set that cannot be had (missing or refused)
  remembers it, so a `Get` of it makes no text.
- **Records and arrays are shared and read-only.** A module never writes into one (`Versions` and `Keys`
  give a new array each time, of the shared records). The tests hand out
  frozen ones (`Data.frozen`): writing a new key fails at once, changing one is found by
  `Data.Tampered()`.
- **A record is made only for an entry somebody asks for,** and kept while anybody holds it (weak values).
- **A list is an array, a map a table, a point `{ map = m, x = x, y = y }`, a tuple a table by its parts'
  names.** A list's empty element is a hole, nil at its place (a `false` of a `list bool` is one): `ipairs`
  stops at the first, so a list that may hold one is walked with `pairs`.
- **The game first:** where the client tells (an item's name, a quest's title), a module asks the client;
  the data fills in what the client does not say.

### What a map shows (`Data.Map`)

```lua
local Map = SaneUI.Core.Data.Map()
local places = Map:On(1429)          -- the places on that map, or nil while they are first read
Map:OnChange(Redraw)                 -- fn() on the frame after they changed (OffChange)
Map:Spawns("npc:69")                 -- a thing's points: { [map] = { { x, y }, ... } }, 0 to 1
```

- **A place** (read-only, `x` and `y` 0 to 1 on its map): `kind` (`npc`, `object`, `place`, `travel`: the set it
  came from), `key` (one per thing: `npc:69`, `object:1617`, `place:12`, `travel:3`; a dock `travel:<way>:<n>`, its
  number in the way's docks), `id`, `what` (an NPC's `{ services, rare, quests, goods }`, an object's, a place's or
  a way's kind), `name`, `to`, `levelMin`, `levelMax`, `side`, and a dock's `towards` (the way's other docks, each
  `{ map, area }`, the area the game's AreaTable ID or nil; `to` their map where there is one).
- **From** the sets Spawns (NPCs with a service, rares, quest givers, the objects players use; a creature that
  is none of these is the creatures' spawns' business, not the map's), Places and Travel (a boat or a zeppelin at
  each of its `docks`, one place per dock; another way between two places at both ends; flights not: the game knows
  its flight points). An NPC with more than `MapReader.MANY` points on a map stands at its areas' middles there.
- **Filled** by `dev/tools/map-data` (the game's own: *Zones*, the entrances of dungeons and raids in *Places*), by
  `dev/tools/travel-data` (the game's own: the docks of *Travel*'s boats and zeppelins with the areas they lie in)
  and by batches of our picking (`sources.toml`: *NPCs*, *Spawns*, the other *Places*, the treasure chests in
  *Objects*).
  Every map point of them is placed by map-data's `Placer`: on the zone map of the area the game gives the
  position (the building part it stands in, else the terrain's map chunk), on the smallest map box only where
  neither tells; *Places*' numbers by its `PlaceKeys`.
- **What your quests ask for** is no place of `Data.Map`: Navigation's `Goals.lua` reads a creature's or an object's
  points from *Spawns* and *CreatureSpawns* by its key as it is wanted, and what gives an item from `Drops:From`.
- **Read** as walks of the scheduler (`Each`), one set after the other, `MapReader.REREAD` seconds after a set it
  reads arrives or changes, so that a burst of changes (the stamps of NPCs and Quests move in play, with every row
  learned) is one walk. A change of the facts alone (NPCs, Objects, Quests) is first looked through, a job of its own:
  the places are read anew only where a creature's or an object's name or kind changed, not for a creature's health
  learned. A set Core does not hold (empty in the master) or that is refused is passed over without a word.

### The ships' times (`Data.Ships`)

```lua
local Ships = SaneUI.Core.Data.Ships()
Ships:Table(3)        -- a boat's or zeppelin's timetable: { round, known, given, stops = { { arrive, leave, stay, dock, area, ... } } }
Ships:Next(3, 2)      -- when it next arrives at its second stop and leaves (server times), whether it stands there now
Ships:Aboard()        -- aboard one: its key, the stop it comes to next, the seconds until it arrives
Ships:Near(60)        -- the stops within 60 yards of the player: { { key, stop } }
Ships:OnLearn(fn)     -- fn(key) on the frame after a ride taught its times
```

- **The timetable** is made from *Travel*'s record of the way (the game's points and stays): between two stops it
  sails at `Ships.SPEED` yards a second, speeding up and slowing down at `Ships.ACCEL` (the game's transports'
  own), and a leap onto another map takes no time. Its round is the record's `wait` where the set has it (`given`:
  no ride changes it), else one learnt from the rides, else its sailing and stays (`known` false); a known round
  stretches the sailing to it.
- **`wait`** (seconds once round) is the original game's for the ways Forever's client has unchanged, point for
  point and stay for stay: a batch (`sources.toml`, 6), only where every record of it agrees to the millisecond;
  unverified until a ride confirms it. Forever's own ways have none.
- **When it sails** belongs to the realm, not to the game: no call tells where a transport is, and each realm's
  ships run from its own start. It is learnt on a ride: the player's place in the world (`UnitPosition`) moving
  along a way at its full speed says when the ship left its last stop; `Ships.SAMPLES` looks that agree within
  `Ships.AGREE` seconds are a ride. Kept in Core's saved data per realm (`ships[realm][key] = { epoch, seen,
  rides, round, span, doubt }`; a record of the wrong shape is none), on this computer only, never shared or
  harvested. Kept for good where the round is known (the set's or learnt; Saneroki, 2026-11-09: after a `/reload` or
  a login `Next` works them out anew from the clock), every ride correcting them (a restart of the realm starts its
  ships anew); where it is only estimated (some seconds off each round), for `Ships.GUESS` rounds after the ride.
  Without a ride, `Next` gives nil.
- **The round learnt** (where the set gives none): each ride is compared with the round kept, by the rounds since
  the ride before. One that agrees with it (within twice `Ships.AGREE`) is of the same run of the realm: it
  confirms the round, and corrects it when it spans more rounds than the one the round was learnt from (`span`).
  One that does not is of a new run (a restart) or the round is wrong: its time is taken, the round kept but
  doubted (`doubt`), and the next ride that does not agree either gives the round from those two (at most
  `Ships.ROUNDS` rounds apart, within a quarter of the round kept). A round worked out from the estimate starts
  doubted.
- **Looked at** every `Ships.LOOK` seconds, every `Ships.CLOSE` near a stop or aboard; not in a taxi's flight. The
  looks begin when *Travel* arrives (with Core, at the login), never before.

### The trip underway (`Data.Trips`)

```lua
local Trips = SaneUI.Core.Data.Trips()
local trip = Trips:Now()   -- nil, or { kind, stops = { { name or map and area, at } }, yards, at, next, left, nextLeft,
                           --   landing, canLand, points = { { world, x, y } } }
Trips:Land()               -- any flight lands at its next flight point, as the game's button (only from a click)
Trips:OnChange(fn)         -- fn() after a trip began, ended, or a flight's end changed
Trips:NearTram(200)        -- waiting at a station of the tram: its key and the station's number
Trips:TramNext(key)        -- when its next train arrives at a station, leaves, whether one stands there (server times)
```

A trip's `pace` (yards a second) and `t` (the `GetTime()` of Core's look) let a view move it on between two looks:
`at + pace * (GetTime() - t)`.

- **A flight** is read at the flight master (`TakeTaxiNode`: its hops by the game's flight point IDs, each the
  set's flight with its path); kept per character (`Core.Character`) until it lands, so a `/reload` in the air
  finds it again. How far along: the player's place on the hops' points; how long: the yards left at the pace
  measured on this flight, before that the median of the character's last `Trips.KEEP` flights (kept per character,
  a flight flown to its end), `Trips.PACE` before the first. Asked to land early (`TaxiRequestEarlyLanding`, ours
  or the game's button), its end is the next flight point and nothing is learnt from it.
- **A boat or a zeppelin** as `Data.Ships` finds the player aboard; **the tram** (the set's way of kind `tram`):
  a place in its map moving along its stations' line at `Trips.SHARE` of its speed (its run's `time`) or more.
  When its train left its station, `Trips.SAMPLES` looks that agree within `Trips.AGREE` seconds, are its times on
  this realm, kept as the ships' are (`trams[realm][key] = { epoch, seen }`, on this computer only, for good: its
  `wait` is the set's); a train leaves each station every `wait` seconds and stands there `wait` less `time`.
- **Watched** once a module asks for the trips (`Data.Trips()`: Navigation, as its files are read) and the world is
  there: the flight master's hooks and the looks, every `Trips.LOOK` seconds, every `Trips.CLOSE` on a trip or in
  the tram's map. Before, nothing. A kept flight, pace or tram time of the wrong shape is none.

### Learned (`Data.Learn`) *(built ahead of 1c.1, 2026-10-21, for Navigation's teleports)*

What the game showed in play that a set does not hold yet: a game fact (*Game facts and personal data*), the same
for every player, kept until a release takes it in.

```lua
Data.Learn("Travel", 4297659, record)   -- Core's watchers only: record, the set's own with what the game showed put in
```

- **Only Core learns** (its watchers); a module reads the sets as ever, and `Get` gives the learned entry. False
  when it cannot be kept: the set not ready, Core's saved variables not read yet, a value its fields cannot hold
  (text with a separator, no number where one belongs), no field at all.
- **A whole row** in the set's format (`Codec.Encoder`, the decoder turned round), of the client's build and the
  server's day, in `SaneUIData_Learned[game].learned[set][key]`: no merging of fields.
- **Read over the set's own** at once (its stamp moves, its listeners are told on the next frame): the set's newest
  version goes into the entry's history, the learned one is its newest (learnt again, it takes the last one's place).
  At the login, laid over the sets once Core's saved variables are read.
- **Dropped once the set is as new:** at the login a learned row is dropped when the set has a version of that entry
  at its build and day or later, whether it agrees or not (the release has seen that build and decided), and so is
  one that is no row. So a wrong learned fact cannot stand over the sets for ever.
- **Shared** (the sets of `Confirm.SHARED`: Items) with the guild and the group (*Verified*, *Sharing*), and taken
  into the master by the harvest. An entry learnt that the set does not have is read by `Get`, but no index lists it.
- **The builds:** each learning or confirmation notes the client's build with its patch (`builds[build] = "1.60.1"`,
  `Data.NoteBuild`), so the harvest can add a build `builds.toml` lacks.
- **The teleports' watcher** (`Data/Teleports.lua`): after the player cast the spell of a teleport of *Travel*
  (`UNIT_SPELLCAST_SUCCEEDED`; an item's, the spell it casts), the player's place in the world is looked at every
  `Teleports.LOOK` seconds and after a loading screen, for `Teleports.WAIT` seconds; a leap of `Teleports.LEAP`
  yards between two looks, or onto another map, is the teleport (no step, charge or blink goes so far so fast), and
  where it ends, to a hundredth of a yard with its map (no height), the way's path, learnt; within `Teleports.SAME`
  yards of the set's place, nothing (its numbers: `Data.Teleports`).

### Verified (`Data.Confirm`) *(Saneroki, 2026-10-23)*

What a batch alone says (not the game's tables, our crawls or a person) is unverified, and a view says so
(*! Unconfirmed Data !*, Core's `Core.Unconfirmed`, and a red ! before the name of each thing not yet confirmed in a
tooltip that lists several: `Core.UNCONFIRMED_MARK`). The game confirms it in play: then it is kept, shared and
harvested, and the next release ships the entry verified.

```lua
Data.Confirm("Places", 412)              -- Core's watchers: the game agrees with the entry
Data.Confirm("Bosses", 1144, "l17076")   -- ... with a part: a boss's item ("l" and its ID) or ability ("a" and the spell's)
Data.Confirmed("Bosses", 1144, "l17076") -- the whole entry, or that part, confirmed
Data.ConfirmedParts("Bosses", 1144)      -- { "a8269", "l17076" }: a view adds those the entry lacks
Data.OnConfirm(fn)                       -- fn() on the frame after something was confirmed, here or by others
Data.Share("Items", 16801)               -- a row learned here (Data.Learn) shared with the guild and the group
```

- **Kept** in `SaneUIData_Learned[game].confirmed[set][key] = "day\031build\031parts"` (the parts cut by \030, `*` the
  whole entry), until the harvest takes them in. Only an entry the set has and still has unverified (a part the entry
  lacks counts: a fact of its own). **Parts:** a boss's item `l…` or ability `a…`; a spawn point `p…` (its map and
  place to a tenth of a percent: `Watchers.Code`); a field the game told, `name`, or a member of one,
  `startNPCs=69`, `health=12` (*Checked in play*). Of an entry Core learned, the parts the game told are kept too
  (`Confirmations.Told`), so the harvest stages only those. What members confirmed stands apart in `heard[set][key]`, of
  the same shape: the views read it as confirmed (`Data.Confirmed`, `Data.ConfirmedParts`, `Unverified`), it is never sent
  on, and the harvest never reads it. Whether the game's own word is kept and shared is decided by this client's own
  alone (their `own` flag: `Data.Confirm`, the watchers' and `Check.lua`'s questions), so what members told never stands
  in for the game's word here, nor confirms an entry whole through the play list. At the login, the confirmations of an
  entry the set no longer lists unverified (a release took it in) and that Core did not learn (nor take from members)
  are dropped.
- **The watchers** (`Data/Watchers.lua`), never in a fight or while the game restricts addons, a hidden value passed
  over: a creature seen (the mouse, the target, a nameplate) confirms the spawn point (*Spawns*) it stands within
  `Watchers.NEAR` yards of (`C_Map.GetPlayerMapPosition`, `GetMapWorldSize`), the whole spawn once every point of it
  was, and itself (*NPCs*) when it offers nothing to talk to; talked to or used (the game's unit `npc`: a vendor, a
  trainer, a flight master, a quest giver, a mailbox) the creature or object and its spawn, and where the player
  stands is a sighting of its place (`Tally.Point`); a mailbox opened the set *Places*' mailbox within
  `Watchers.MAILBOX` yards; a zone left the crossing within `Watchers.CROSSING` yards. Quests: *Checked in play*.
  **A boss's loot:** within
  `Watchers.LOOT` seconds after the game said it was killed (`ENCOUNTER_END`) and in its instance, an item the set
  *Bosses* names for it; any item of a corpse of the boss's name (the target, dead): the game tells no place inside an
  instance, nor whose corpse a loot is (no `GetLootSourceInfo`), so the time, the instance and the corpse's name hold
  the items to the boss (Saneroki, 2026-10-23). **Its abilities:** a spell its unit casts (the boss frames' units in
  its fight, else a creature of its name; one the set does not name too), a buff it carries of those the set names,
  wherever the game lets them be read. **Items:** every item the character has (bags, worn, bank) compared with
  *Items*: its stats (`GetItemStats`, the game's names), armour, damage and speed (its tooltip's lines,
  `C_TooltipInfo.GetItemByID`) learned where they differ or the set lacks them (many items' are hidden from the
  game's tables), and shared; an item the set lacks only on an English client (the set's names are English).
- **Sharing:** see *Messages* (kinds `V` and `L`).

### Checked in play (`Data.Check`) *(Saneroki, 2026-10-24)*

Every data point starts as what we could gather and guess, and play makes it right: whatever the game shows of an
entry is compared with the set, field by field, by Core's watchers alone.

```lua
Data.Check("Quests", 77, { name = "Wolves", rewardXP = 450, startNPCs = { npc = 69 } })
```

- **How each field is told** is the schema's `play` list (*schema.toml*): whole, one member of a list, one key of a map,
  or `?` (shown only where our data is wrong). `Checks.NONE` says the game shows the field empty.
- **Agrees:** the field confirmed (`name`; a member `startNPCs=69`; a key `health=12`) and shared like any
  confirmation; once every field of the play list the entry holds was told (a list's every member, a map's every
  key), the whole entry.
- **Differs, or the set lacks the entry** (a quest, a creature only Forever has): learned (`Data.Learn`), the set's
  record with what the game told put in: a member added to its list, never one taken away (a giver of the other
  side, a good sold out). Every part told is kept with it, so the harvest stages only what the game said; the set's
  other facts ride along unverified.
- **Texts only on an English client** (names, titles, objectives, ranks, kinds): the sets' are English. A new entry
  on another client is learned without them.

The watchers that check:

| Watcher | What it tells |
| --- | --- |
| **Quests** (`Data/Quests.lua`) | *Offered* (`QUEST_DETAIL`): title, the NPC, thing or item that offers it, rewards (items and choices as the window lists them, money, experience, a spell). *Taken* (`QUEST_ACCEPTED`): level, group size, daily, the objectives as the log lists them (kind, count, text without its numbers). *Worked on* (`QUEST_WATCH_UPDATE`): the creature it asks for (the dead target its text names), the item (looted, its name in the text), where the count went up (`Tally.Cell`, key `quest:<quest>/<objective>`). *Handed in* (`QUEST_COMPLETE`, `QUEST_TURNED_IN`): who takes it, experience and money; the quest the same NPC offers at once after, with no list in between, its `next`. |
| **Requirements** (with an offer) | Offered by an NPC, a thing or an item (never shared by a player): a lower level narrows `minLevel`; a race, class or side our data leaves out is added; a quest our data says must be done first and is not (or one that closes it and is done) is removed. Only the player's own character, only the conclusion. |
| **Rewards** | Experience only below the highest level and at most `QuestWatch.XP` levels over the quest's (it is cut beyond), money only below the highest level, a quest that scales neither. |
| **Creatures** (`Data/Facts.lua`) | Seen out of a fight (never one a player controls): name, level (the set's lowest and highest widened by one seen outside them), rank, kind, health at the level seen (not where the game gives a share of 100). Talked to: its services (vendor and repair, trainer, flight master, banker, auctioneer, stable master, quest giver). |
| **Vendors** | Their goods as the window lists them: an item the set lacks added. Not prices: they are the player's, after the discount their standing earns. |
| **Spells** | Of the spellbook, and every spell a tooltip shows: name, rank, icon. Not cost, cast time, range: talents and gear change them. |
| **Items** | Those the character has, and every item a tooltip shows (`TooltipDataProcessor`): as *Verified* says. |

### Counted in play (`Data.Tally`) *(Saneroki, 2026-10-24)*

What one loot or one sighting cannot settle is counted, and only the sum of many players' counts goes into the
master (*The harvest*).

```lua
Tally.Loot("npc:69", "loot", 0)        -- one loot: how (loot, skin, pickpocket, gather, fish); quest 0 for everybody
Tally.Drop("npc:69", "loot", 769, 0, 2) -- an item it gave, and how many
Tally.Visit("object:1617", "gather")   -- a node come to: the gathers since are one visit's
Tally.Point("npc:69", map, x, y)       -- seen from up close: merged into a place within Tally.MERGE yards, one visit
Tally.Cell("npc:69", map, x, y)        -- looted here: a cell of the map
```

- **Kept** in `SaneUIData_Learned[game].tally[build] = { id, drops, points, cells, fresh }`: one block per build (the build
  period), each with a random id, a packed row per key; at most `Tally.BUILDS` blocks, the maps' sizes in yards beside
  them (`maps`). `fresh` holds the keys counted since the last bundle. No time finer than the build, no name, no trail.
  A row's records: `c how quest n` (loots), `d how item quest times units` (an item), `v how n` (visits);
  `Tally.Read` reads one strictly, `Tally.Counts(key)` adds up the kept builds.
- **The loot watcher** (`Data/Loot.lua`): every loot window, by the game's own source of each slot
  (`GetLootSourceInfo`: the corpses or things it came from, several at once). Without it nothing is counted (a creature
  is never guessed from the target; `Loot.blind`). Each source once a way: a corpse opened again without a cast is the
  same window; right after a cast that gathers (Skinning, Herb Gathering, Mining, by their names in *Spells*) it is
  `skin`; after Pick Pocket `pickpocket`; a node or chest each time a cast opens it (`gather` for the herbs and ore of
  *Objects*). Fishing counts for the zone (`zone:<map>`); a container in the bags not at all. The cast's name comes from
  *Spells*, else from the game (a cast of a new build).
- **Gathering** *(Saneroki, 2026-10-30)*: skinning, mining and herbs first of all. One `gather` for each cast, one `v` the first
  time a node is come to (by its GUID, `Loot.CORPSE`), so a vein of three gathers is three gathers and one visit. A slot the game
  names no source for, in a window of one source, is that source's: a gem is not lost. A window it names no source for at
  all counts only right after a gather cast whose target (`UNIT_SPELLCAST_SENT`) is a herb or ore of that name in *Objects*.
  A rare drop is an item like any other; the reader tells which ones are (*Drop rates*).
- **Quest items:** an item an objective of a quest in the log asks for (not done yet, its text naming the item)
  counts for those on that quest, and so does one more loot for each such quest: the chance while on it.
- **Where:** a creature looted, its cell; a node or chest, its point; a creature or thing talked to, its point.

### Drop rates (`Data.Drops`) *(Saneroki, 2026-10-30)*

The one door for how often things come. The set *Drops* is what shipped; over it what this account counted (every build
kept) and what members told (*Counts and discoveries shared*).

```lua
local Drops = Data.Drops()
Drops:Of("object:1617")             -- what it gives, the likeliest first; list.loots[how], list.visits[how]
Drops:Of("object:1617", "period")   -- this build period only
Drops:Rare("object:1617")           -- only what comes at most Drops.RARE (10) percent of the time
Drops:Chance("npc:69", 769)         -- chance in percent (nil while too few came), drops, loots
Drops:From(2838)                    -- who gives an item, the likeliest first
Drops:Knows("npc:69", "skin", 2318) -- whether the set lists it for that way
```

- **An entry:** `item`, `how`, `quest`, `drops`, `units`, `loots`, `chance`, `rate`, `yield` (units a time it came), `perVisit`,
  `rare`, `shipped` (only the set says so). Read-only; answers are kept until something is counted.
- **A chance needs `Drops.SURE` (3) drops;** until then a view says how many of how many: `Aquamarine 1 of 123`. Below
  `Drops.ENOUGH` (50) loots the set's own chance stands, where it has one.
- **Rare** is by how seldom it comes, not an item's colour.
- **In the game:** `/sane data gathered` lists what was gathered and skinned, how often, in how many visits, and its rare
  drops. Tooltips shows the rare drops on a herb or a vein, and on a rare item where it came from. Navigation's pins show what
  a rare, a chest, a herb or a vein gives, and a dungeon's enemies and bosses too (`PinView.Drops`).
- **Marked:** `listed` an entry whose chance is the set's, `doubt` what the set says of it the game has not confirmed: a view
  gives a chance so counted without its counts, and marks a doubtful one.

### Discoveries (`Data.Found`) *(Saneroki, 2026-10-30)*

Every accepted change to the data in one short list, and the chat line of them (`Data/Found.lua`). Modules print nothing about data.

```lua
Data.Discovered("Quests", 77, "new", { "name" })  -- Core's watchers, once a change was accepted
Data.Found(fromDay)                               -- the list, newest first: { day, build, how, set, key, what, parts }
Data.Discoveries.Prices(count)                    -- a scan moved so many prices: told, not kept
```

- **What it holds:** what `Data.Check` and the watchers learned (`new`, `changed`), an item no data listed for a gather, a skinning or
  a fishing water (`drop`; a corpse's loot is not one, as any creature can drop a world's green), and what was taken from others
  (`how = "shared"`). A field told a piece at a time (a creature's health at a level) is none by itself.
- **Kept** in `SaneUIData_Learned[game].found`, a packed line each, `Found.DAYS` (90) days, at most `Found.MOST`: no time finer than
  the day, nothing of who.
- **Chat:** the switches *Chat message for new data changes* and *... for new auction house data* (page General, both off): the first
  line at once, then at most one of a kind in `Found.GAP` seconds, never in a fight, summed up: `data: 3 new quests, 2 new drops
  (1.60.1). [Details]`. `[Details]` (an addon link, `addon:SaneUI:data`, through `EventRegistry`'s `SetItemRef`) and `/sane data
  found` print the newest.
- **Not yet here:** an entry gone and a chance a build changed: the patch check and the harvest know those.

### The full auction scan (`Data.Scan`) *(Saneroki, 2026-10-30)*

While the auction house is open, Core reads all of it by itself and keeps what it lists, whichever modules are on
(`src/Core/Data/Scan.lua`, the plan in `Doc/ideas/Economy.md`, *The full scan*). It needs no click, so it goes on with the
game in the background, and it reads a full scan another addon asked for just the same.

- **When:** a moment after the window opens (`Scan.SETTLE`), once the game's message queue is ready; then every
  `Scan.INTERVAL` (16 minutes) from the server's last answer, kept in the saved file, so a `/reload` or another
  character knows it. The server allows one scan in 15 minutes and is silent when it refuses: no answer in `Scan.ANSWER`
  (90 seconds) counts as refused, and the next request comes after `Scan.RETRY` (3 minutes).
- **By hand:** the bar pressed (`Scan.Start`) asks at once, whatever the time says. The server still decides: inside its
  15 minutes it stays silent, that counts as a refusal, and the wait goes on where it was. An answer is told by the game
  again as item data comes in, so as many rows within 14 minutes are the same scan, not a new one.
- **Reading:** a job of the scheduler (`Full auction scan`, with priority), so no frame takes more than its budget and
  nothing runs in a fight. Gear and pets need the item known for their key: those rows wait up to `Scan.ITEMS` seconds
  while the items are asked of the server, `Scan.ASKS` a round; what is still unknown then is left out (`left`).
- **Kept** only when the scan was read to its end; a list the game took away halfway leaves nothing.
- **The file:** the auction data is a file of its own, apart from the settings (Saneroki, 2026-10-30): the addon
  `SaneUI_AuctionData` (`src/AuctionData/`, *Data: Auction House*) holds no code, only the saved variable
  `SaneUIData_Market`, so the game writes it to `WTF/Account/<account>/SavedVariables/SaneUI_AuctionData.lua`. It is
  read in the loading screen, like any saved file, so a login and a `/reload` take longer as it grows. Switched off, Sane
  UI neither scans nor shows prices.
- **The whole scans' file:** the addon `SaneUI_AuctionScans` (`src/AuctionScans/`, *Data: Auction Scans*, Forever's) holds only
  `SaneUIData_Scans`, each account's own. Core loads it when the auction house opens, so a login never reads it; opening the
  house for the first time in a session takes longer as it grows, and the game writes it at the logout of such a session.
- **Every scan whole (Forever, `Scan.WHOLE`):** `SaneUIData_Scans[game].houses[house][at]`, one string per scan, by the time the
  server answered:
  `<build>\n<block>\n<block>...`. A block is `Scan.BLOCK` rows packed by the game (zlib, then Base64), each block by itself so
  that packing stays within a frame's budget; the rows stand grouped by item, cut by `\n`:

  ```text
  key,count,buyout,minBid,increment,bid,timeLeft,status,seller,bidder,link
  ```

  `buyout` is for the whole row, `link` the game's item string (gear only). This is the raw history: what goes on into the
  database is filtered there. The sellers' and bidders' names are local and never go on. About 40 bytes a row, so a house
  of 50,000 auctions costs about 2 MB a scan (measured on made-up rows shaped like the game's).
- **A scan as lines (Forever, `Scan.RECENT`):** `recent[at]`, the scans of today and yesterday, `key=low,market;...`, the scan's
  own lowest. A graph of a day reads them: a day's string has one point a day, and a whole scan is too much to open for a
  tooltip. About 20 bytes an item, so the last two days of 6,000 items at 96 scans a day cost at most 25 MB; dropped by whole
  days, unlike `whole` and `days`, which stay.
- **The history:** `SaneUIData_Market[game].houses["eu/1234/horde"]`, the house by region, realm and side (the side of the
  NPC that opened it, `neutral` where it has none). Beside the whole scans one string per server day, `days[day]`:

  ```text
  key=low,market,units,auctions,sellers;...
  ```

  `key` is the game's `ItemKey`: the item's ID, or `item:level:suffix:species` for gear and pets. Prices are per unit in
  copper, 0 where nothing had a buyout: `low` the lowest of the day, `market` the median of the units on offer, the rest
  from the day's last scan that saw the item. `sellers` is a count, no name is kept. `scans[day]` says how many scans the
  day holds, `index` each item's newest point (*Prices*), `rhythm`, `stretch`, `samples`, `watched`, `watchedAt` the forecast's
  (*The forecast*), `onSale`, `onSaleCount` the buyouts of the player's characters' auctions in the last scan, `at` when the server last answered, `kept`, `rows`, `items`, `left` the last scan kept. `Scan.KEEP` limits the days per game: a week for Retail, whose house is far bigger and which keeps no
  scan whole, until its data's plan is made; none for Forever.

```lua
local Scan = SaneUI.Core.Data.Scan
Scan.State()      -- { phase, outcome, read, rows, next, span, kept, total, items }: phase closed, waiting, asking, reading;
                  -- outcome kept, refused, lost; next, the server time of the next request; kept, total, items, the last scan
Scan.OnChange(fn) -- fn(state) at every change, and twice a second while the house is open
Scan.Start()      -- a scan now (the bar, pressed); false while one runs
```

- **The bar** (`src/Core/Data/ScanBar.lua`) is a view of `State`: ours, under the bottom right corner of the game's window,
  anchored to it, made when the window is first there. It fills as the rows are read, then runs down to the next scan.
  Pressed, it starts a scan; a light and a tooltip say so.
- **`/sane data`** names each house: its days, its whole scans and what they weigh, its last scan.

### Fees (`src/Core/Data/Fees.lua`, on `Prices`) *(Saneroki, 2026-10-30)*

What the auction house takes, and what that leaves, the one place it is reckoned. The numbers are the game's own: the client's table
`AuctionHouse` (`DepositRate`, `ConsignmentRate`) and its words for the durations (`AUCTION_DURATION_ONE`, ...), all of Forever's newest build:

| | Cut of a sale | Deposit, of the vendor price of all that is put up |
| --- | --- | --- |
| A faction's house | 5% | 2 hours 5%, 8 hours 20%, 24 hours 60% |
| A neutral house | 15% | 25%, 100%, 300% |

- **The deposit** the window shows is `floor(vendor * count * rate) * length`, what the server takes `floor(vendor * count * rate * length)`
  (`length` 1, 4, 12); the two can differ by a few copper. `Prices:Deposit` is the second. The duration is the game's setting
  `auctionHouseDurationDropdown`, what was last chosen in its Sell tab. Retail has 12, 24 and 48 hours, at 3, 6, 12 times the rate.
- **At least 1s an auction**, however small the deposit shown, and once for a stack of any size. This is no number of the client's and nobody
  of the game has said so; it stands on what players were charged. Whether a sale gives back the 1s or only the deposit shown is not settled, so
  `Prices:Post` counts it in full.
- **Prices move in copper only for what stacks:** the price of a thing that does not stack is always whole silver, 1s at the least (`Prices:Step`).
- **`Prices:Limit`** is the most worth paying to sell an item on: a sale at its best time, less the cut, the post and a tenth (`MARGIN`). **`Prices:Later`** is a
  sale at the price to expect, where that brings 5% more than the best way now. `Prices:PostAt` is one step under a price, never so low
  that a sale brings less than a vendor pays.

- **Two houses** (Saneroki, 2026-10-30): a character can reach its side's house and a neutral one, and each keeps its own history, forecast and sales: a house is part of a price's key from the first scan. `Prices.Other()` is the house of the other kind, `Prices.Within(house, fn, ...)` reads everything as if that house were open, so all of the above reckons by its fees, and `Prices:Route(item, vendor)` says what a sale there brings. A trip must leave a quarter on top of what the item costs (`Prices:Trip`), a sale there 10% over the best way here (`Prices.AWAY`); a neutral sale needs a price some 12% higher just to match one at a faction's house, and more than that for the deposit. What was last seen there over three days ago is told, but it is no ground for a trip.

### The forecast (`Data.Rhythm`, `Prices:Outlook`) *(Saneroki, 2026-10-30)*

"Try to do their best to tell me when to sell or buy this item to make a profit ... when the AH predicts prices to be high vs low
looking at the history and its natural trends, swings between time of day, weekday etc." One short line per item, `rhythm[key]` of a
house (`src/Core/Data/Rhythm.lua`, Forever's: `Scan.RHYTHM`), so a tooltip gets its forecast from one string and opens no history.
Own scans only: what members send stays out, as it can be taken out again.

- **A sample** is an item's lowest price at the first scan of a stretch (three hours by the player's clock, `Rhythm.Stretch`): the
  eight scans of a day that say something new, not the ninety that repeat each other. From the second day a sample counts at most
  twice off the usual price.
- **The usual price:** `fast` over about a day and a half, `slow` over about a week, geometric, so one wild listing moves them little.
- **Swings:** per stretch of the day and per weekday, how the samples stood against the usual price, remembered for four and five weeks.
  A swing counts from three days seen, against the middle of its row, so a rising price shows none, and only at twice what it may be off
  by (`dev`, the item's own noise), and then less that: the best of many stretches is too high by chance alone. A price that only wobbles
  so has no time to name.
- **The trend:** `fast` against `slow`, from five days on, at most 5% a day, and held for three days ahead.
- **What sold** (`Scan.Bought`, *Sold between two scans* in `Doc/ideas/Economy.md`): an auction of the last scan that is gone, the scans at
  most `Scan.WATCH` (30 minutes) apart, except one of short time left (it may have run out), one whose seller has a new auction of the item
  (taken back and posted anew), and one over the market price (a buyer takes the cheapest first). Units and money fade over a week in
  the line, as the watched seconds do in the house (`Rhythm.Watched`), so a pause changes nothing. Under twelve hours watched: not told.
- **Across accounts:** the line of the account that took the most samples, as two accounts in one house see the same auctions (`Join`).

`Prices:Outlook` holds what it read per item for the hour, and until a scan is kept. What that is worth after the cut and the post is *Fees*.

### Prices (`Data.Series("Prices")`) *(Saneroki, 2026-10-30)*

The one door to auction prices: every view reads here, none keeps its own (`src/Core/Data/Prices.lua`). The tooltips' Gold
section, disenchanting's materials, the advice and Speed Leveling's rewards all read it.

```lua
local Prices = SaneUI.Core.Data.Series("Prices")
Prices:Low(item)      -- the lowest price now, per unit, in copper; nil: none, or none for Prices.FRESH (30) days
Prices:Last(item)     -- low, market, units, auctions, sellers, at: the newest point, however old; nil: none
Prices:Range(item, from, to) -- how its price went: { { at, low, market }, ... }, oldest first, from server time from to to
                      -- (nil: from the first point, to now); one table used again: read it at once
Prices:Outlook(item) -- what the scans tell of its price ahead and how it sells (*The forecast*); read it at once
Prices:Under(item, price) -- how many are on offer at that price or less; nil while no scan or list of it was seen this session
Prices:Usual(key)     -- what an item usually costs, a look at its forecast's line alone
Prices:Scanned()      -- the keys of the house's last scan, for a view that looks through them
Prices:OnSale()       -- money, auctions, at: what this player's characters had on sale at the last scans of both houses, on every linked account
Prices.Other()        -- the house of the other kind a character can reach; nil: nobody of yours has seen it
Prices.Within(house, fn, ...) -- fn(...) with everything here reading that house; it must not wait for a frame in there
Prices:Stamp()        -- a number that moves with every change of a price
Prices:OnChange(fn)   -- fn() on the next frame after prices changed
```

- **`item`** is an ID or a link. A link names its kind (gear by level and suffix, a pet by species); an ID, or a link of a kind
  no scan saw, the cheapest of its kinds.
- **Newest first:** what the game lists right now (browsing, the offers of an item: `AUCTION_HOUSE_BROWSE_RESULTS_*`,
  `COMMODITY_SEARCH_RESULTS_UPDATED`, `ITEM_SEARCH_RESULTS_UPDATED`) replaces the point's price and what is on offer, its market
  stays the scan's; each new scan replaces the points of what it saw. Live sightings go into `index` at the logout, never into
  the scans.
- **Per house:** while one is open its own, else the one of your side; a price of one house is never read for another.
- **`index`** is `key=at,low,market,units,auctions,sellers;...`, taken apart when a house is first asked about.
- **The history (`Range`), whichever is more current (Saneroki, 2026-10-30):** each stretch of time from what is most current
  for it: a day's scans, this account's and the database's, a point a scan; else the database's line of the day, which took this
  account's in with all the others'; else this account's own; and last the item's newest point, which what the game lists right
  now moves on. A scan's point stands at its time, a day's in the middle of that day. An item's history is taken apart once and
  held until a scan is kept (64 items a house), so what the game lists moves only the newest point.
- **The database** holds no auction data yet: what the harvest makes of the scans comes in behind this same door. What all
  accounts hold together comes in here already (*Across accounts*).

### Across accounts *(Saneroki, 2026-10-30)*

Every WoW account of a game folder reads every account's auction data. The game keeps saved files per account, and its
machine-wide kind (`## SavedVariablesMachine`, `WTF/SavedVariables/`) is closed to addons. Nor can accounts share one file:
the game writes a new file at every save in place of what stood there, so a link in the `WTF` folder is gone at the first
save, and each running game writes only what it read itself, over what the others scanned. So each account stays the only
writer of its own files, and what the accounts share is the `AddOns` folder:

- **The addon `SaneUI_AuctionDatabase`** is made of links, one to each account's `SaneUI_AuctionData.lua`. A link there follows the
  file's name, so it stays good through every save. `dev/tools/auction-database link` (`saneui auctiondatabase link`) makes it,
  a link only for an account that has saved its file (a link to nothing is a file the game cannot load: a warning at every
  login). `dev/build --install` makes it anew after each install and says so where it changed, so an account's first save
  gets its link at the next install, with a restart of the game. Nothing runs in the background, and the `WTF` folder is
  never written. Made on this computer (`## X-SaneUI-Made`), so it is in neither the repository nor a build.
- **In the game:** each link runs as a file of that addon and leaves its saved variable in the global; the file after it calls
  `Prices.Account()`, which takes what it holds of this game version and clears the global. So the addon must be read before this
  account's own file (`## OptionalDeps` of `SaneUI_AuctionData`), and an account's own file is read twice, which does no harm.
  `database[house]` then holds `index`, `days` (the accounts' texts joined plainly, the last to scan at the end) and `recent`.
- **When an account sees it:** the game writes a saved file only at a `/reload` or logout, and reads addon files only at a login or
  `/reload`, so through the links a scan shows on another account after a `/reload` or logout there, then a `/reload` or login
  here. While they run, and in the same guild or group, it is there at once: an account is a member like any other (*Scans shared*).
- **Every scan whole** stays on the disk in each account's `SaneUI_AuctionScans.lua`; a login reads none of it.
- **Other players** have neither the links nor the addon, and Core does without. Sane Sync is the way to give it to them.

### Scans shared *(Saneroki, 2026-10-30; Data-build 1f.2)*

A full scan reaches every Sane UI member of the guild and the group by itself (`src/Core/Data/Relay.lua`, kind `A` on `Core.Wire`;
the plan: `Doc/ideas/Data.md`, *Scans*). A running game reads no file, so this is also the only way to another running account.

- **`have`:** a scan was kept: one message on the guild and on the raid or else the party: house, time. A member who scans within
  `Relay.QUIET` (15 minutes) of a transfer of that house keeps it to itself; a newer offer stops an older one.
- **`want`:** a member with nothing that new (its own scan, or one taken) answers on that channel after a random moment of up to
  `Relay.WAIT` seconds; the others hear it and stay quiet, and take the blocks all the same.
- **Blocks:** only then, on that channel, once per channel: what moved in that scan (`house\nat\nkey=low,market,units,auctions,sellers;...`),
  at most `Relay.MOST` items, cut at `Relay.BYTES`. The wire's pace is one message a second, about 18 items a second, so a
  first scan of 6,000 items takes about six minutes and later ones far less. With nobody asking, one message is all there is.
- **`ask`:** `Relay.LISTEN` seconds after the login, unless a transfer was heard: who has a scan of this house newer than mine? The holder
  offers its last scan whole (`Prices.Lines`), once in `Relay.QUIET` per house, whoever asks (a whole scan is minutes of messages);
  holders that hear the offer stay quiet. An account asks once in `Relay.QUIET` too, however often it reloads (`asked[house]` in its
  auction file), and a member that asks again within it earns a strike. What came from others is not passed on.
- **Taken in** (`Prices.Heard`): only from the guild, party and raid, never a whisper; every byte of a block by its strict shape, or
  none of it (a key of a kind the game would not make is off it: gear's plain, a plain item's with a kind, a level, suffix or species
  past any); numbers within what the game can hold; at most `Relay.MOST` lines in a block, and `Prices.KEYS` keys of a house standing
  as one member's, the rest passed over; an item the game does not know left out; only where this account's point is older. A price more than five times off a point of the last `Prices.FRESH` days waits apart (`doubted`) for a second sender, one of
  the two of the guild, as a group can hold strangers.
- **Kept apart:** a member's points stand over this account's in `book.index`, `book.shared` says whose, `book.under` holds what they
  stand over. In the saved file they are `heard[sender] = "key=at,low,market,units,auctions,sellers;..."`, never `index`, `days` or
  the whole scans, so they can be taken out again and nothing shared reaches the harvest. A scan of this account's, or what the game
  lists, replaces them.
- **Strikes** (`strikes[sender] = { count, till }`, on this computer only, by the whole name): a message or block off its shape (a time
  that is no number, a block with no lines, a key of a kind the game would not make); a scan's or an offer's time more than
  `Relay.AHEAD` ahead (an offer from the future would keep every member's scans of that house to itself); two scans of a sender closer
  than `Relay.SOONEST`, which the server cannot have allowed; more than `Prices.DOUBTS` far-off prices in one scan; more lines or keys
  than a member can have; a second ask within `Relay.QUIET`. At `Relay.STRIKES` the sender is not heard for `Relay.IGNORED` (a week),
  and what it sent is taken out again (`Prices.Forget(sender)`). A scan older than `Relay.OLD`, or of a house this account does not
  know, is passed over, with no strike.
- **Forget shared prices:** a button on the page General, `/sane data forget` (`Relay.ForgetAll`): everything members sent, and what
  waits, taken out; this account's own points back as they were; strikes stay. `/sane data` says what stands and waits and who is not heard.
- **The switch** *Share data with my guild and group* (`Core.general.shareData`, `Data.Sharing()`, page General, on): off, neither
  this nor the confirmed facts of `Confirm.lua` are sent or taken.
- **The shared facts of `Confirm.lua`** (*Messages*) earn the same strikes: a block of learned rows off its shape is one. They keep no
  sender: a member's confirmation waits in session memory for `Bundle.SENDERS` members, then stands apart (`heard`), never sent on nor
  harvested, as a member's row does (`taken`).

### Counts and discoveries shared *(Saneroki, 2026-10-30; Data-build 1f.3)*

`Data/Bundle.lua`: every `Bundle.EVERY` seconds (15 minutes) a member that counted something tells the guild and the raid or else the
party, in one bundle: what it counted, and the rows it learned of *Quests*, *NPCs*, *Vendors* and *Spells* (`SETS` in `Bundle.lua`) with the
parts the game told. A member that counted nothing says nothing, so an account standing at the auction house costs no traffic.

- **A bundle** is blocks of kind `B`: `id\031build\031at`, then lines cut by \029: `c\028key\028row` (a key's totals of this build) and
  `f\028set\028key\028parts\028row`. What was counted since the last goes first; room left goes to the other keys in turn, so a
  member who came online later catches up. Never in a fight, under a restriction or in an instance: `fresh` and `outgoing`
  are in the saved files and wait.
- **Counts:** kept per tally block (its random id) in `SaneUIData_Shared[game].counts`, this build's only as a block comes in; a
  newer total replaces the older, so nothing counts twice and two characters of an account are one voice. They go into the views
  only (`Drops.lua`), summed a way at a time: a member whose chance is far from everybody else's (`Drops.Z`, `Drops.LOOTS` loots both
  sides) is left out, and with `Drops.VOICES` voices or more none makes up more than `Drops.SHARE`. Never into the harvest.
- **Facts:** wait in `facts` until `Bundle.SENDERS` (3) different members sent the same row, the stamp aside; then the row is taken
  (`Data.LearnRow`) apart from what was learned here (`SaneUIData_Learned`'s `taken`, at most `Confirm.KEPT` rows a set, the oldest
  making room), its told parts as heard (`Confirm.Heard`): neither reaches the harvest, which reads `learned` and `confirmed` alone,
  nor is passed on. What the player saw here always wins: a row of an entry learned here is not taken. *Items* stay on their own way
  (`Confirm.lua`), checked by the game.
- **The player's other accounts** count as the player (`Prices.Mine`): each account's auction file names its characters (`mine`), and every
  account reads every account's through the links (*Across accounts*). Their counts count whole and their facts are taken at once.
  Without the links nobody is.
- **Not trusted:** a line off its shape, a row longer than `Bundle.LINE`, more drops than loots, a total that shrinks or grows faster
  than `Bundle.PACE`, a block from the future, two bundles within `Bundle.SOONEST` seconds or more than `Bundle.IDS` block ids under
  one name this build is a strike (`Relay.Strike`, the same strikes as a scan's); three and the sender is not heard for a week and
  what it sent is gone. A block's id belongs to the member first heard with it: a block under it from another name (an account's
  other character, or an impostor) is passed over without a strike, so nobody can plant counts under a member's id and make its
  honest totals look false; an account's other character speaks through the one first heard. *Forget shared data* (`Data.ForgetShared`, `/sane data forget`)
  takes out all of it, a taken row at the next `/reload`.
- **Limits:** `Bundle.KEYS` of one sender, `Bundle.ALL` in all, `Bundle.IDS` block ids of one sender a build, `Bundle.WAITING` facts
  waiting, `Bundle.BY` per sender, `Bundle.STALE` days, `Confirm.KEPT` rows taken a set.

### The harvest

`dev/tools/data harvest` (`saneui data harvest`) reads the saved files: the game folders' own (`--wow`), or WTF
folders and `SaneUI.lua` files players sent (`--from`, each game version they hold). Read as data, never run; only
`SaneUIData_Learned`.

- **Learned rows** become the game's facts at their build and day, with only the fields the game told (a list only
  once every member was told, over all files). Only this client's own (`learned`, `confirmed`): what members sent
  (`taken`, `heard`, and `SaneUIData_Shared`) the harvest never reads.
- **Confirmations:** `*`, a boss's every item and ability, a spawn's every point, or every field of the play list the
  entry holds, over all files: staged as `confirmed`.
- **The ledger** (`play.py`; kept outside the project where `~/.config/saneui/private.json` points, else in
  `dev/data/staging/`) takes of each tally block only what grew since it last read it (by the block's id: a file read
  twice counts once), adds it up, and stages:
  - **Drops:** a key's chances, once every way it is looted that matters (our data's and play's) has `Play.LOOTS`
    loots; per item how often it came, its chance from `Play.SURE` drops on. An item our data lists that play never
    saw stays where it is rare enough not to have shown, else it goes. A chance a build changed (both sides
    `Play.CHANGE` loots, two-proportion z over `Play.Z`, a fifth up or down) counts from that build on, and is said.
    Staged again once the loots grew by half.
  - **Spawns:** places seen on `Play.VISITS` visits or more; each of our points narrowed to where play saw it (within
    `Play.NEAR` yards), new ones added; only once every point of ours was seen. Unchanged within a yard: confirmed.
  - **Areas:** cells counted `Play.CELLS` times or more, where our data has no area: a creature's (*Spawns*, else
    *CreatureSpawns*), a quest objective's (*QuestAreas*, `from = "play"`).
- The ledger keeps visits beside the loots (`v`); they are not staged yet, the set *Drops* has no field for them.
- Then `dev/tools/data import <staging> --apply`, and a release ships it.

### Loading

- **Every set is read with Core,** at the login, in the loading screen: its file is one of Core's
  (*Core's TOC*). There is no loading later and nothing in the addon list to switch.
- **A set is refused** when its format is not 1, its game version is not the client's, or the client's game
  version cannot be told: reported once (`Core.Report`: one line in chat); the last two once for all sets
  (`data: game`: then every set is so, a copy of Sane UI made for another game folder). A set Core does not hold at all
  is noted once in the error log, quietly, when it is first asked for (`Core.NoteError`); not at all in a game version
  whose world's data is not made yet, which holds only the sets every game version gets (`Data.EVERY`: Icons and
  PatchNotes, Retail's two). The modules fall back.
- **`Data.Prepare(name)`** and **`Data.WhenReady`** stay for readers that ask before Core's files have all
  run (Core's own, as their files are read) and for sets that come late (the tests): `Prepare` does nothing
  but say a set that is not there.
- **The data's saved variables** (`SaneUIData_<Name>`, *Saved variables*) are read with Core's own, so Core's
  readers ask for one with `Data.Saved(name, fn)`: `fn(part)` once Core's saved variables are read (Core's
  `ADDON_LOADED`), at once when they are, with this client's part. A name that is not in `Data.SAVED`: noted
  once, `fn` never called. Modules do not call it; they read what Core makes of it.

### `/sane data`

The client's game version and build with the three answers it was told by, every set with its hash and
build (or its state and why), how much each saved part holds, and the scheduler's jobs, each with the
milliseconds it worked and its frames, and whether they wait now (a fight, a restriction). `/sane data gathered` lists what was
gathered and skinned with its rare drops, `/sane data found` the newest discoveries, `/sane data forget` takes out what others sent.
`/sane data show <set> <key>` prints an entry and what changed, by patch; the key is a number only in a set
keyed by numbers (a text key may look like one). `/sane data` also tells the client anew (`Data.Retell`):
its game version and build; the answers made from them are made again only when either changed.

## The scheduler: jobs

`Core.Steps` (`src/Core/Data/Steps.lua`) runs every long piece of the framework's work in steps: a walk
over a set, later the scan's reading, shared data taken in, the characters, the crawl; and
Core's other long work (Sync finding the game's CVars).

```lua
local Steps = SaneUI.Core.Steps
local job = Steps.Run("Each Items", function(...)  -- a job, run as a coroutine; false if one of that name runs
    for key in pairs(rows) do
        Work(key)
        Steps.Check()                     -- between pieces of work: yields when the frame's time is spent
    end
end, ...)
job:Stop()                                -- it never goes on

Steps.Run({ name = "Scan", priority = true, label = "Market: the scan",
    done = function(problem) end,         -- nil after its last step, the error's text after an error
    error = function(problem) end }, Scan)
```

| Call | Does |
| --- | --- |
| `Steps.Run(name, fn, ...)` | Starts a job and gives its handle; a job of the same name is not started twice (gives false). In place of the name, options: `name`; `priority = true` (served first in every frame, after a job waiting in `Fresh`); `done(problem)`, told when it ended, after its last step (nil) or an error (its text); `error(problem)`, after an error only, after the report; `label`, what a failure is noted under (else `data job <name>`). Both are told outside its coroutine, safely. |
| `job:Stop()`, `Steps.Stop(name)` | Stops a job: it never goes on and is told nothing (from inside, it runs on to its next `Check`, `Fresh` or `Spend`). false when it is over already. `job:Running()`. |
| `job.name`, `job.ms`, `job.frames` | Its name, the milliseconds it worked so far, the frames it worked in (for `/sane data`). |
| `Steps.Check()` | In a job: yields when the frame's budget is spent, else returns at once. Outside a job: nothing. |
| `Steps.Fresh()` | In a job: waits for a frame of its own (no other work before it in that frame). |
| `Steps.Spend()` | In a job: the frame's time is all used; nothing else runs in it. With `Fresh` before it: a step that cannot be cut runs alone in its frame. |
| `Steps.Wait()` | In a job: waits for the next frame and leaves this one's time to the other jobs, for a step that has nothing to do until the game has answered (the scan's wait for an item's data). |
| `Steps.Running(name)`, `Steps.Jobs()`, `Steps.Paused()` | Whether that job runs; the handles of the jobs running, in the order they were started; whether they wait now (a fight or a restriction). |

- **The budget:** at most 5 ms a frame for all jobs together, and never more than a quarter of a frame at
  the current frame rate (`GetFramerate`), measured with `debugprofilestop`. A slower computer takes more
  frames, no frame more time.
- **The order in a frame:** a job waiting in `Fresh` first; then the jobs with priority, in the order they
  were started; then the others, each in its turn first in some frame. A job is served once a frame.
- **Nothing in combat or under a restriction:** the scheduler stops at `PLAYER_REGEN_DISABLED` and while
  `Core.Restricted()` says so: a fight, or a restriction of `Core.RESTRICTIONS` (combat, an encounter, a
  challenge mode, a PvP match, a map; not chat), kept by Core from `ADDON_RESTRICTION_STATE_CHANGED`'s own
  state (the game's `IsAddOnRestrictionActive` answers false while that event is sent); and goes on after.
  Nothing is asked of the game in a frame but the frame rate.
- **Each job is its own guard:** `coroutine.resume` catches its error; the job is dropped and reported
  (`Core.Report`, once per label), the others go on.
- **A job never yields inside `pcall`, `xpcall` or `Core.Safe`:** Lua 5.1 cannot, the yield fails into the
  `pcall`, and the job runs on past its budget without a word. Neither inside an event the game sends from
  within a call of the job's: what an event tells is told after the job, on the next frame (`OnStamp`).
- Its frame is shown only while there is work: no `OnUpdate` at rest.

## Saved variables *(1c; built so far: the data's saved variables, their parts, `format` and `broken`; `learned`)*

- **In Core's saved file:** `SaneUIDB` and the data's own, `SaneUIData_<Name>` (`Data.SAVED`:
  Characters, Guild, Learned, Shared; later the other series), are declared in Core's TOC, so the game writes
  them all into one file, `WTF/Account/<account>/SavedVariables/SaneUI.lua`.
- **The auction data apart (`Data.APART`):** `SaneUIData_Market` and `SaneUIData_Scans` have files of their own (*The full auction
  scan*); `Data.Saved` hands over a part once its addon has loaded, after Core.
- **Keyed by game version first:** `SaneUIDB.data["forever"]`, `SaneUIData_Characters["retail"]`. Core
  uses only its client's key; the others (a copied `WTF`) are left as they are.
- **Core's** (`SaneUIDB.data[game]`) *(1c)*: `format` (1); `checked` (`[set] = build`, the patch check);
  `crawl` (`[kind] = place`).
- **A saved variable of the data** (`SaneUIData_<Name>[game]`): `format` (1); `broken` (parts of a wrong
  shape, kept for the harvest); and what it holds: the characters, the guilds' records, `learned`
  (`SaneUIData_Learned`: `[set][key] = row`, a whole row in the set's format, *Learned*), with `confirmed`
  (`[set][key] = "day\031build\031parts"`, *Verified*), `taken` and `heard` (the rows taken from members and what they
  confirmed, the shapes of `learned` and `confirmed`, apart: never sent on, never harvested), `outbox` (what waits to be
  shared: `"V\031set\031key\031part"`, `"L\031set\031key"`, at most `Confirm.OUTBOX`), `found` (the discoveries) and
  `builds` (`[build] = patch`);
  `SaneUIData_Shared`, what members told, apart from the player's own and never read by the harvest: `counts`, `facts`, `taken`,
  `outgoing` (*Counts and discoveries shared*); `SaneUIData_Market`, the
  scans and prices per auction house, `houses["eu/1234/horde"]` (*The full auction scan*); *(1c)* the drop counts.
- **Packed strings, never tables of tables,** for anything that grows (rows, a series' months, a bag), and
  at most 100,000 values **for Core's saved file as a whole:** Lua 5.1 stops at 262,143 constants in one
  function, the game reads the file as one, and a file over it loads as nothing (every saved variable in
  it lost).
- **Every part is checked on load:** the format number with upgrade steps; a part of a wrong shape goes to
  `broken`, the rest works.

## Characters

What the account's characters have, so every character sees its alts' things (the plan, *Characters*):
`src/Core/Data/Characters.lua`, in Core, kept in Core's saved variable `SaneUIData_Characters`, which ships
nothing and is taken at every login. Never shared.

```lua
SaneUIData_Characters["forever"] = {
    format = 1,
    characters = {
        ["Player-70-0000ABCD"] = {          -- the character's GUID (Core.charKey), never a name
            name = "Sane Lunatic",          -- its whole name: first name and surname (guide, *Players*)
            realm = "...", class = "MAGE", race = 1, level = 12, side = "Alliance",
            seen = 20743,                   -- the server's day it was last seen
            money = 12345,                  -- copper
            bags = "4500\0315\0304501\0311", -- a place: item ID and count, items in order (\030, \031)
            worn = "...", bank = "...", bankSeen = 20743,
            slots = "1\03116854\03016\0312139", -- what is worn slot by slot: slot ID and item ID, slots in order
        },
    },
    account = { bank = "...", seen = 20743 }, -- the account's own bank, once per account
    broken = { { what = "...", value = ... } }, -- parts of a wrong shape, set aside, never wiped
}
```

| Call | Gives |
| --- | --- |
| `Data.Characters()` | Every character of the account, by name: `{ key, name, realm, class, race, level, side, seen, money, bankSeen }`. nil before the login. |
| `Data.Character(key)` | One of them, or nil. |
| `Data.Items(key, place)` | What one of them keeps in a place (`bags`, `bank`, `worn`; the key `account` with `bank`: the account's bank), item by item in the order kept (by item ID): `{ { item = 4500, count = 12 }, ... }`. nil: no such character or place, or not loaded yet. |
| `Data.Worn(key)` | What one of them wears, slot by slot, by the game's inventory slot IDs: `{ [1] = 16854, [16] = 2139, ... }` (the gear, the ammo, the bags' slots), for a paper doll. nil: no such character, not loaded yet, or its slots not read yet (it has not logged in since Sane UI keeps them). |
| `Data.Count(item)` | `{ total = 40, [key] = { bags = 12, bank = 8, worn = 1 } }`, the key `account` for the account's bank (`{ bank = 5 }`); nil: none of them has it, or not counted yet. |
| `Data.CharactersStamp()`, `Data.OnCharacters(fn)` | A number that moves when any of it changes (the gold and the day the bank was seen too), and `fn()` called on a later frame, once for what changed together (never inside the job): a view redraws then. |
| `Data.Forget(key)` | Forgets one of the account's characters (a deleted one, one moved to another account: `Profiles.Forget` calls it): its entry in the saved file and every answer made from it, and those who listen are told. Never the one played; asked before the login, done then. true when there is one to forget. |

- **Places:** `bags` (the backpack, the bags, the reagent bag, the keyring where there is one), `worn` (the
  gear and the bags in their slots), `bank` (the character's bank tabs, `C_Bank.FetchPurchasedBankTabIDs`),
  the account's `bank` (its tabs, where the game lets the character see them).
- **What is worn, slot by slot** (`slots`, no place: never counted): read with `worn` from `GetInventoryItemID` per
  slot (`INVSLOT_FIRST_EQUIPPED` to `INVSLOT_LAST_EQUIPPED`, the bags' slots, and `INVSLOT_AMMO` where the client
  has it: the ammo is in `slots` only, as it lies in the bags and is counted there). Kept even empty (`""`: read,
  wearing nothing), so a character that wears nothing is told from one whose slots were never read.
- **Mark, then read:** an event marks a place (`BAG_UPDATE`, `PLAYER_EQUIPMENT_CHANGED`, `PLAYER_MONEY`,
  `PLAYER_LEVEL_UP`, the bank's events); the reading is a job of the scheduler (out of combat, within the
  budget, a bag at a time), started at `BAG_UPDATE_DELAYED` for the bags. **The bank only while it is open**
  (`BANKFRAME_OPENED`, read again when it closes if still marked), and whole, in one step: read when closed it
  would be empty, and what was seen of it stays (a read cut between two of its tabs would keep it half read). At
  the logout what is still marked is read at once, and the place the job was reading too.
- **The saved part is checked** when the pack loads: an entry that is no table or has no name, a packed place
  that is no text, and a plain value of the wrong kind (`class`, `level`, `money`, ...) are set aside under
  `broken`, never handed out.
- **Nothing read is nothing written:** a client without the container functions reads nothing, and what is
  kept stays.
- **The whole name:** a name without its surname (the game not knowing it yet) never takes the place of a
  whole one; two characters with one first name are two characters (their keys).
- **Counts** are worked out once, in steps, after the login (every place taken apart), and kept up
  to date from then on: an item's tooltip asks one table.
- *Not built yet (1c.4):* the auction log and own auctions, the mailbox.

## Messages *(1f)*

*The transport is built (2026-10-20, ahead of 1f, for the guild's records): `Core.Wire` (`src/Core/Data/Wire.lua`):
`Wire.Listen(kind, fn)`, `Wire.Send(kind, fields, channel, target, urgent)`, `Wire.ListenBlock(kind, fn)`,
`Wire.SendBlock(kind, text, channel, target, tag)`, `Wire.Drop(kind, tag)`. A block's part is the kind P (`P1\t<sign>\t<kind>\t<transfer>\t<part>\t<parts>\t<size>\t<text>`,
200 Base64 characters a part; its numbers are taken only as digits); the sign of a game version: `f` Forever, `b` its
beta, `p` its test realm. A block is queued only when all its parts fit in the queue (a block in part is of no use),
each part with the sender's tag (a record's kind), so that `Wire.Drop` takes out what still waits of it (a switch
turned off). The queue: ten at once, then one a second, half that for 30 seconds after a throttle, nothing in a fight or a
lockdown, at most 300 waiting (urgent for 10 minutes, bulk for an hour). Taken in: 90 messages a minute from a
sender, more and it is not heard for ten minutes; at most 1,000 waiting in the inbox.*

- **Prefix `SaneUI`;** the guild, party and raid channels only (decision 9).
- **Another addon's prefix** *(Saneroki, 2026-11-16)*: `Wire.Hear(prefix, fn)` and `Wire.Say(prefix, text, channel,
  target)` for an addon Sane UI knows (`Core.Neighbours`), in its own words: its messages through the same inbox (the
  player's own left out; `Wire.OTHERS_PER_MINUTE` from a sender, counted apart from ours), ours on it through the same
  queue and budget. Today a dungeon map addon's drawings, Navigation's sketches both ways (`Exchange.lua`).
- **Auction scans** *(Saneroki, 2026-10-30)*: kind `A` (`have`, `want`, `ask`, each with house and time) and its blocks: *Scans shared*.
- **Counts and discoveries** *(Saneroki, 2026-10-30)*: blocks of kind `B`: *Counts and discoveries shared*.
- **Map markers** *(Saneroki, 2026-11-15)*: blocks of kind `M`, only when the player shares them (a marker's card,
  Navigation's `Markers.lua`), to the raid or party or the guild: "1", then a row a marker (its origin: the maker's
  character key and number; map, x, y, icon, title, words). Personal data the player chose to share: the one who gets
  them is asked first and keeps them in Navigation's saved settings, never in a `SaneUIData_` variable or the database.
  A whole plan (markers and drawings, 2026-11-15) as version 2: "2", its head (origin, name, part, parts, the share's
  stamp), then rows `m` (a marker's) and `d` (a drawing's: origin, map, kind, colour, width, its points as three letters
  of base 36 each), in parts put together by sender, origin and stamp.
- **Speed Leveling's place in a guide** *(Saneroki, 2026-11-05)*: kind `S` (the guide's key, at most 180 bytes of it;
  the row of the step's first line in the guide's text; letters: `w` waiting there, `c` busy with a class quest on top
  of it, `a` asking for the others' places), to the party or the raid only, as the place changes, nothing when it follows no guide (an empty key: forget me). Not
  data and never kept: it lives while the group does (`src/SpeedLeveling/Party.lua`, its README's *In a party*).
- **What was confirmed and learned** *(Saneroki, 2026-10-23)*: kind `V` (set, key, the parts cut by commas, `*` the
  whole entry), one message per entry; learned rows as a block of kind `L` (`set\028key\028row`, the rows cut by
  \029, at most `Confirm.ROWS`). Sent to the guild and the raid or else the party, `Confirm.GAP` seconds apart, never
  in a fight, while the game restricts addons, or inside an instance: they wait in the outbox (kept in the saved
  file) until the player is out and has somebody to tell. Taken from the guild, party, raid and instance channels
  only (never a whisper): a confirmation of an entry or part this client has unverified, once `Bundle.SENDERS` members
  sent the same part, one of them on the guild's channel (a group can hold strangers), or this player's other account
  did (`Prices.Mine`); a part must be one `Check.lua` would make of the entry as this client has it (a member of a
  list it holds, a key of its map, a field told whole), at most `Confirm.MOST` of an entry from members and
  `Confirm.WAITING` waiting with one member's name (a part naming an item or a spell the game does not know is
  dropped); kept apart (`heard`). A row only where it changes nothing but what play teaches (`Confirm.SHARED`: an
  item's stats, armour, damage and speed), or where the set lacks the item and the game knows it, never of an entry
  learned here; kept apart (`taken`, at most `Confirm.KEPT` rows a set). A block off its shape (a key that is no
  number, more than `Confirm.ROWS` rows) is a strike (`Relay.Strike`). What was taken from others is not passed on
  again, nor harvested.
- **The sender** is the one the server names (`CHAT_MSG_ADDON`'s sender), by its key (*Players*); a message
  never names its own sender.
- **A message:** its kind (a letter), the protocol number, its game version's short sign, then its fields,
  all cut by tabs (`H1\tf\t...`). A kind, number or game version not known, or not the receiver's, is
  ignored. At most 255 bytes.
- **A block** (a scan's 250 items, a bundle): its rows in the codec's format, packed with
  `C_EncodingUtil.CompressString` naming *Zlib* (its checksum catches damage), made text with
  `EncodeBase64`, cut into numbered parts (`D1\t<transfer>\t<block>\t<part>\t<parts>\t<text>`). The first part
  also says the unpacked size, checked after unpacking; a packed block is at most 4 KB.
- **A scan's messages** name its auction house (`eu/1234/horde`); a receiver takes only its own house's.
- **Received text is read, never run:** no `loadstring` anywhere in the framework.

## Guild records

People information, built locally for each user and never shipped (CLAUDE.md, *Game facts, not people*):
`src/Core/Data/Guild.lua`, quiet until the module Guild starts it (`Data.Guild.Start()`), kept in Core's saved variable
`SaneUIData_Guild`, per guild (its name and realm).

```lua
SaneUIData_Guild["forever"] = { format = 1, guildFormat = 1, guilds = { ["The Order-Realm"] = {
    seen = 20744,                                          -- the server's day the roster was last read
    members = { ["Droopy Fairwind"] = "rank\031level\031joined" },  -- what the history is compared with
    history = "day\031what\031key\031from\031to\030...",       -- oldest first, the last 500: join, leave, up, down, level
    records = { ["Droopy Fairwind"] = { card = "stamp\031text" } }, -- each member's records, newest by stamp
} } }
```

- **Its format:** `guildFormat` is the guilds' own, apart from the framework's `format` (*Saved variables*); a part
  without it is of the first.
- **The roster** is the game's (`GetGuildRosterInfo`), read after `GUILD_ROSTER_UPDATE` by the scheduler (the job
  *guild: roster*: never in a fight or while the game restricts addons, then once it lifts, one read however often the
  game said it changed). It is asked for with `C_GuildInfo.GuildRoster` at the start, by Sync, and while a view shows
  it whenever the game lets (`Data.Guild.Watch`); never on a timer. Each member by its key (*Players*). The first
  read of a guild notes no history and nobody's day of joining; a roster the game gives only in part notes nobody
  leaving, and one that shrinks by more than a tenth at once is believed only when a read a minute later still says it.
- **Records**, by kind (`card`, and the kinds a module adds with `Data.Guild.Kind`), each with its largest size:
  taken only from their owner (the sender the server names: a member publishes only its own), only from a member of
  this guild (a whisper from anybody else is dropped), only newer than the one kept, never stamped more than a day
  ahead of this client's clock. A member's records go when its leaving is noted.
- **The card** (`Data.Guild.Card()`, `ReadCard`): `1`, class, race, sex, level, item level, worn (`slot:item:level`,
  cut by commas), professions (`name:rank:most`, from the game's skill lines of the professions and secondary
  skills), cut by `\031`. Made again 3 seconds after the gear or the level change and a minute after the skills (they
  rise in runs), and published when it differs.
- **The wire's kind G** (*Messages*): `h` (a hello: a fresh flag, Sane UI's version, `kind=stamp` of each record
  this character shares), `a` (asking its owner for a record, by a whisper); a record goes as a block of kind G
  (`kind\031stamp\031text`): to the guild when it changes, whispered to the one who asked (to each member each kind
  once a minute at most; a newer one at once). A hello to the guild at login (a quarter minute after, fresh) and
  every 15 minutes; a fresh one (a newcomer's, or Sync's, once a minute at most) is answered by each member's own,
  whispered to the one who asked, once a minute per member, after a random wait of up to six seconds. Two asks wait
  for an answer at once; the same record of the same member is asked at most once a minute.
- **Allowed by the player:** a kind is sent only while the module's switch for it is on (`Data.Guild.Allow`);
  off, nobody who asks gets it, and what still waits to be sent of it is dropped (`Wire.Drop`).

## Players

WoW: Forever names a player by a **first name and a surname** (`Droopy Fairwind`). Players can share a first
name or a surname, so only the two together tell them apart, and the two together are unique across the
region (`RegionalUniqueNamesEnabled`): the game leaves the realm out. Retail names a player by one name,
unique on its realm (`Thrall-Draenor`).

- **A player's key** is the whole name as one: `Core.PlayerKey(unit)` for a unit,
  `Core.PlayerKeyOf(text)` for a name an event, a list or a message gives (`CHAT_MSG_ADDON`'s sender). On
  Forever the first name, the game's separator (a space) and the surname, with any realm dropped; on Retail
  `Name-Realm`, the own realm added where the name has none. `Core.Surnames()` tells which.
- **Never a part of it:** nothing is kept, counted, compared or shared by a first name alone or a surname
  alone, and a name is never cut at its space. A Forever name that comes without its surname has no key
  (nil): what it would name is dropped, never guessed.
- **What uses it:** the senders of shared data (*Messages*): their limits, quarantine, the three senders
  of a fact, the counts kept per sender, strikes (one sender per key: two members with one first name are
  two senders, one member named with and without a realm is one); the player's own messages, dropped by
  their key; any player named in kept data.
- **The account's own characters** are kept by their GUID (`Core.charKey`), never by a name; their whole
  name is kept beside it for showing (`Core.FullName`, `Core.charName`).
- **Shown** with `Core.FullName(unit)` (Forever: first name and surname) or the key itself.
- **In rows, saved files and messages** a name is text: it may hold a space (only a tab and the characters
  28, 30 and 31 cut), so a key can stand in a field or be a text key (`"Droopy Fairwind"`).
- `/sane data` says how this client names players, with what `RegionalUniqueNamesEnabled` answers.

## Clocks

- **Build:** the number `GetBuildInfo` gives, as a number, compared only within one game version.
- **Game version:** told once (`Data.Game()`).
- **Day:** `floor(GetServerTime() / 86400)`; **time:** `GetServerTime()`. Never `time()` for anything kept or
  shared. In the master a day is a date (`2026-11-03`); in set files, saved files and messages its number.

## Adding a set

1. **Its schema:** `assets/data/<Set>/schema.toml`: its key, `about`, the fields in the order its file will
   carry them, the indexes a module will ask by. The set becomes one of Core's files by itself.
2. **Its facts:** a tool of ours writes staging into `dev/data/staging/`, each line with its game version,
   build and source; a new batch gets its number in `sources.toml` (with `game`, `seen` and `build`). A
   short hand-made list is written into `<Set>.jsonl` directly, with the source `hand`.
3. **Taken in:** `dev/tools/data import <file>`; read the report (new, agreeing, changed, conflicts,
   refused); then `--apply`. Conflicts are looked at, not forced.
4. **Checked and built:** `dev/tools/data check`, `dev/tests/run`, `dev/build`.
5. **Read:** a module asks `Data.Set("<Set>")` and falls back on nil.
6. **Tested** on small sample masters in `dev/tests/data/`, never on the real data.

## Tools

| Command | Does |
| --- | --- |
| `dev/tools/data check` | Checks the master (run by `dev/tests/run`). |
| `dev/tools/data import <file> [--apply] [--take]` | Staging into the master, the report first. |
| `dev/tools/data compile <dir> [--game <game version>]` | Core's set files into Core's addon folder, listed in its TOC (run by `dev/build`). |
| `dev/tools/data game <game folder>` | The game version a game folder holds, by the product its `.flavor.info` names (`PRODUCTS` in `dev/data/compile.py`: `wowf`: `forever`; `wow`: `retail`; `wowt`: `retail-ptr`; `wow_beta`: `retail-beta`; `wow_classic_beta`: `forever-beta`, the beta that is gone); nothing for a product not known. `dev/build` installs that game version's set files. |
| `dev/tools/data show <set> <key> [--game <game version>]` | An entry: every version as its line says it (build, patch, day, sources, what changed) with its fix, then the entry as the set files carry it. |
| `dev/tools/data diff <set> [--patch 1.60.2] [--game <game version>]` | What a patch changed (the game version's newest when none is named): every entry new, changed (field from → to), gone or back at one of its builds. |
| `dev/tools/data stats` | Per game version and set: entries, versions, entries that changed, gone ones, its own lines, its file's size; then all of them together. |
| `dev/tools/data harvest [--wow <folder>] [--from <path> ...] [--ledger <file>] [--out <file>]` | *The harvest*: every game folder's saved files of Sane UI (`WTF/Account/*/SavedVariables/SaneUI.lua`), or those players sent (`--from`), read as data (a small reader of the Lua the game writes, never run), each folder's own game version's part only (`.flavor.info`; a file sent: every one it holds): learned rows as the game's facts at their build and day (only the fields the game told), whole confirmations as `confirmed`, the counts added up in the ledger and staged once enough agree (Drops, Spawns, areas), into `dev/data/staging/harvest.jsonl`; a build `builds.toml` lacks added with the patch the game said and its first day. Then `import --apply`. |
| `dev/tools/cvar-labels --staging` | The CVar labels as staging for the set *CVarLabels*. |
| `dev/tools/icon-data` | The game's icons as staging for the set *Icons*, both games (*The icons*): `icons-forever.jsonl`, `icons-retail.jsonl`. |
| `dev/tools/game-data <game version> <build> <client tables> [<hotfixes> <day>]` | The game's own facts from a build's client tables (and a beta's hotfixes; the beta is gone, so they and `base` are history) as staging for Items, ItemSets, Spells, Auras, SkillLines, Professions, Talents, Legacy, Currencies, QuestAreas, Achievements, Mounts, TransmogSets, Enchantments, Holidays, Factions, FactionTemplates, Encounters, Races, Racials, Classes, Maps, Areas and Instances; `base <batch>` stages for live what only the beta holds (decision 27). What it leaves out and why: `dev/data/staging/game-<game version>-left.csv`. |

## Tests

- **The tools** (`dev/tests/data/tools.py`): each rule of the check caught; every import case on sample
  masters, each within its own game version; compiling twice gives the same bytes; a live set file holds
  nothing of another game version, another's is live's with its own on top; the files listed at the end of
  Core's TOC.
- **In the game** (`dev/tests/data.lua`, Lua 5.1 with `wowstub.lua`): the codec reads back every row the
  Python compiler wrote from the sample masters (the one test that keeps the two languages in step);
  set files run, refused (a wrong format, another game version, a client that cannot be told) or missing;
  frozen records; the answers on a sample with history (`History`, `At`, `Versions`, `Changes`, `Keys`,
  `Each`), also from a set newer than the client; listeners told after the file, `WhenReady`, `OffStamp`;
  the data's saved variables (`Data.Saved`); the codec the other way round (`Codec.Encoder`) and what is learned
  (`Data.Learn`: laid over a set at the login, dropped once the set is as new, learnt anew; the teleports' watcher);
  the scheduler's budget, pauses (by a restriction's own event), guards, handles (`Stop`, `done`, `error`, `label`)
  and priority.
- **Nothing hostile raises an error:** a broken row, a broken saved file or message is dropped or set aside.
- **Players by their key** (`dev/tests/core.lua`): a whole name with or without a realm is one key, the same
  first name or surname two players, a first name alone none; Retail's `Name-Realm`. Steps 1c and 1f test
  their senders and characters the same way.
- **A module's tests** run on a few made-up entries on the real schemas: `python3 -I dev/tests/data/sets.py
  <sample> <out>` copies the real master's tables and schemas with the sample's lines in place of the real
  ones (`dev/tests/data/tooltips/` for Tooltips), checks them and compiles the set files into `<out>/Sets`;
  the test gives them to the stand-in client (`W.AddSets`), which runs them at the end of Core's files, as
  Core's TOC does (or at once, given after Core).
