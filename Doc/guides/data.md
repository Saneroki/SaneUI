# Data

How Sane UI keeps its own databases: the master in the repository, the tools that check and compile it,
the packs the game loads, and what a module reads. Read this before adding data, writing a tool that makes
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
| The tools | `dev/tools/data`, Python in `dev/data/` | Check the master, take in staging, compile the packs, show and compare entries. |
| Staging | `dev/data/staging/` (not committed) | What a tool read from a source, in one neutral format, waiting to be taken in. |
| The packs | `BUILD/SaneUI_Data_<Pack>/` (not committed) | Load-on-demand addons made from the master by `dev/build`: a TOC and a Lua file per set. |
| The engine | `src/Core/Data/` (in `SaneUI.toc`) | `Steps.lua` (the scheduler), `Codec.lua` (a row's string into a record), `Data.lua` (finding and loading packs, the answers). |
| Tests | `dev/tests/data/` (tools, sample masters), `dev/tests/data.lua` (in the game) | Run by `dev/tests/run`. |

## Words

| Word | Meaning |
| --- | --- |
| **Set** | One kind of thing keyed by one ID (*Items* by item ID). What a module asks for, by name. |
| **Entry** | One thing in a set: the item 16801. |
| **Version** | An entry's facts from one build (and day) on. An entry has one or more, oldest first. |
| **Build** | The game's build number (`GetBuildInfo`, second answer), the clock of versions. |
| **Game version** | One game as one kind of client plays it: `forever`, `forever-ptr`, `forever-beta`. |
| **Source** | Where a fact came from: the game, a person (`hand`), or a numbered batch of staging. |
| **Pack** | A load-on-demand addon holding one or more sets, compiled for one game version. |
| **Row** | One version of an entry as one string in a pack. |
| **Record** | A row taken apart in the game: a table of field = value. |

## Game versions

Facts of one game version never reach another (the plan, *Game versions kept apart*).

- **Names:** `forever` (live), `forever-ptr`, `forever-beta`; later `retail` and its own. A name ending in
  `-ptr` or `-beta` **stands on** the name without it: its packs are the live files with its own on top.
- **Short signs** for messages: `f`, `fp`, `fb`.
- **The client's game version** (`Data.Game()`): `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT` (18, this client) is
  Forever. Then `IsBetaBuild()` gives `-beta`, else `IsPublicTestClient()` or `IsTestBuild()` gives `-ptr`.
  Any other project, or a missing answer, gives nil: **a client that cannot be told refuses every pack.**
  `/sane data` prints the three answers, so the game shows what each client says.

## The master: `assets/data/`

```
assets/data/
  builds.toml               the builds of every game version: patch and first day
  sources.toml              every source a line may name
  packs.toml                every pack: its title and notes in the addon list
  <Set>/
    schema.toml             the set: its key, pack, fields and indexes
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
about = "The game itself: its code and tables in references/, its API, our crawls, scans and learned data."

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

### packs.toml

```toml
[Game]
title = "Data: Game"
notes = "Sane UI's data from the game's own code: the names of the options' settings, currencies. Loaded only when Sane UI needs it."
```

Every schema's `pack` is here. The pack's addon is `SaneUI_Data_<name>`.

### schema.toml

```toml
set = "Items"
key = "int"              # Blizzard's ID; "text" for a set keyed by a name (CVarLabels)
pack = "Items"
learn = true             # the game may teach it in play (Learned, step 1c)
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

- **Field order is the order in `[fields]`.** It is the order of a row's fields in the pack, so a field is
  added at the end, and never moved or removed while a pack of the set is in use (a field no longer wanted
  stays, unused). Old lines simply lack a new field.
- `about` says in one sentence what the set holds.

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
in `assets/data/<Set>/schema.toml`. **A set without entries may still change its fields freely;** once a
pack of it is in use, the rule of *schema.toml* holds (a field only added at the end). Real data comes with
prompt 2, which settles what the game gives.

| Pack | Sets and their keys |
| --- | --- |
| Items | Items (item ID), ItemSets (item set ID) |
| Quests | Quests (quest ID) |
| World | NPCs (creature ID), CreatureSpells (spell ID), Objects (object ID), Zones (map ID), Travel and Places (our own numbers), Drops (`npc:<ID>`, `object:<ID>`, `zone:<map ID>`) |
| Spawns | Spawns (`npc:<ID>`, `object:<ID>`), QuestAreas (`<quest>/<objective>/<stage>/<map>`), PatrolPaths (creature ID) |
| CreatureSpawns | CreatureSpawns (creature ID) |
| Routes | Walking (a region, numbered by our tool) |
| Guides | Guides (a guide, numbered by our tool) |
| Spells | Spells, Auras (spell ID), Trainers (the rank's spell ID), QuestSpells (`<spell ID>/<way>`), WeaponSkills (the teaching spell's ID), SkillLines (skill line ID), Professions (the recipe's spell ID) |
| Talents | Talents (trait node ID), Legacy (`node:<ID>`, `challenge:<ID>`, `reward:<level>`) |
| Market | Vendors (the vendor's creature ID); the series *Prices* (step 1c.2) |
| Game | CVarLabels (the CVar's name), Currencies (currency ID) |

- **A text key `<kind>:<ID>`** where one set holds things whose IDs overlap (a creature and an object can have
  the same number); **a text key of parts** where an entry is one of several per thing (an area per
  objective, stage and map).
- **Our own number** where the game gives none; the schema's comment says how a staged thing is matched to
  an entry already there.
- **A thing with several parts per entry** (a guide's steps, a quest's objectives) is a list of tuples whose
  parts say which step or objective a row belongs to: a list holds no list (*Types*).

### A line of the master

```json
{"key":16801,"since":0,"src":[3],"name":"Arcanist Gloves","slot":"hands","stats":{"int":10,"spi":5},"sell":1550}
{"key":16801,"since":65100,"day":"2026-11-03","src":["game"],"stats":{"int":8,"spi":5}}
{"key":19999,"since":65100,"src":["game"],"gone":true}
```

- **Keys in this order:** `key`, `since`, `day`, `src`, `gone`, `replaces`, then the fields in schema order.
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

## Staging and the import

A tool that reads a source writes staging, never the master: one JSON object per line.

```json
{"set":"Items","key":16801,"game":"forever","build":65100,"day":"2026-11-03","src":"game","fields":{"armor":36}}
{"set":"Items","key":19999,"game":"forever","build":65100,"src":"game","gone":true}
```

- `set`, `key`, `game` and `src` (one source's name) are needed; a line without its game version is
  refused. `build` (0 when not known) and `day` are optional; `fields` holds what the source says, `null`
  for a field it says is empty; `gone` and `replaces` as in the master.
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

`dev/tools/data check` (run by `dev/tests/run`; `dev/build` stops on it, so a broken pack is never made):

- `builds.toml`, `sources.toml`, `packs.toml` and every schema parse and fit their formats; every schema's
  pack is known, every `ref` names a set, every index a field of an indexable type.
- Every set folder holds only its own files; every line parses and fits its schema and the rules of *A line
  of the master*, in order, in the right game version's file, its key in the file's key range.
- Every `ref` and every `replaces` points at an entry that exists in that game version's view.
- Every fix matches a version; a fix that the game may have overtaken is a warning.
- Text holds no tab and no character 28, 30 or 31.

Errors fail; warnings are printed.

## Compiling: the packs

`dev/tools/data compile <dir> [--game <game version>]` (run by `dev/build`, step 1a.3) writes
`<dir>/SaneUI_Data_<Pack>/` for every pack one of whose sets has entries in that game version's view, and
removes the `SaneUI_Data_*` folders in `<dir>` it no longer makes. **The same master always gives the same
bytes:** no date, no clock, entries sorted by key.

- **Live's packs** come from live's files only.
- **Another game version's packs** stand on live: for every entry, live's newest version becomes the base
  (since 0), and that game version's own versions follow on top. Live's history is not in them.
- Fixes are laid on the lines first; then every version is worked out whole (the game never adds up
  changes).
- **`build`** of a set is the newest build its own game version's lines know: their `since`, and the
  `build` of their batches.
- **`hash`** of a set is the first 8 hex digits of the SHA-256 of its file, written with the hash as
  `00000000`. A module that keeps something worked out from a set knows by the hash when it is stale.

### A pack's TOC

```
## Interface: 16001
## Title: Data: Game
## Notes: Sane UI's data from the game's own code: ...
## Author: Saneroki
## Version: 0.3.0
## Category: Sane UI
## Group: SaneUI
## Dependencies: SaneUI
## LoadOnDemand: 1
## SavedVariables: SaneUIData_Game
## X-SaneUI-Sets: CVarLabels, Currencies
## X-SaneUI-Format: 1
## X-SaneUI-Game: forever
## X-License: MIT

CVarLabels.lua
Currencies.lua
```

- `Interface` and `Version` are Core's. Every set of the pack has its file, also one with no entries
  (its handle is then ready and answers nil); the sets in name order. A pack's own code (step 1d) follows
  them, copied from `src/Core/Data/Packs/<Pack>/`.
- `LICENSE.txt` is the project's `LICENSE`, as in every addon folder.

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
  type the codec does not know, or a set another pack handed over first, too): the file stops there, and
  the set is not ready (said once).
- **`R`** holds every entry's newest version; **`H`** the older ones, oldest first, joined by character 28,
  only for entries that have them; **`I[index][value]`** the keys, joined by character 30, sorted.
- **At most 50,000 statements per `Fill` function:** Lua 5.1 stops at 262,143 constants in one function, and
  a file over it does not load at all.
- **`types`** are the decoder's, reduced from the schema: `int` (also `money`, `flags` and a `ref` to an
  int-keyed set), `number`, `text` (also `enum` and a `ref` to a text-keyed set), `bool`, `point`,
  `tuple(name:type,...)`, `list <element>`, `map <int|text> <element>`.
- **`patches`** names the patch of every build the set's versions start at (from `builds.toml`).
- The compiler's own indexes: `replaces` (new key → the old one) and `replacedBy` (old key → the new one).

### A row

`build \t day \t field1 \t field2 ...`

- **build** a whole number; **day** the server's day as days since 1970 (empty where not known).
- A tab between fields; inside a field, character 30 (`\030`) between the elements of a list or map,
  character 31 (`\031`) between an element's parts (a map's key and value, a point's map, x and y, a
  tuple's parts). Game text holds none of them, so nothing is escaped and a row is taken apart with plain
  finds. **An empty part is no value,** of every type: an empty element of a list is a hole (those after
  it keep their places), an empty value of a map no key. Empty fields at a row's end are left out.
- **A row of only a build and a day is a gone version.**
- **Values:** whole numbers as they are, other numbers as `%.14g`; `bool` `1` or empty; `point` `map\031x\031y`.

## In the game

### What a module reads

```lua
local Data = SaneUI.Core.Data

local Items = Data.Set("Items")     -- a handle: cheap, loads nothing, never nil; one per name
Data.Prepare("Items")               -- load soon: after the loading screen, out of combat, one pack a frame
```

| Call | Gives |
| --- | --- |
| `Items:Get(key)` | The record of the newest version this client has reached: field = value, also `since`, `day` and `patch`. nil: not known, not loaded (and then `Prepare` is asked for), no such entry, gone. |
| `Items:Get(key, field)` | One value of that record. |
| `Items:At(key, build)` | The record as it was at that build, or nil (not there yet, gone). |
| `Items:History(key)` | An array of records, oldest first, each with `since`, `day`, `patch` (none for `since` 0) and, for a gone version, `gone = true`; its newest is the record `Get` gives. nil when not known. |
| `Items:Versions(key, n)` | The last n of `History`, oldest first. |
| `Items:Changes(key)` | An array, oldest first, of `{ since, day, patch, field, from, to }`, one per field that changed, in the pack's order of the fields (an entry gone: `field = "gone"`, `from = false`, `to = true`; back again the other way round). An empty array for an entry that never changed. |
| `Items:Keys(index, value)` | An array of keys from the entries' newest versions (`replaces`, `replacedBy` too); an empty one when none. |
| `Items:Each(fn, done)` | A job: `fn(key, record)` for every entry the client has (gone ones left out), out of combat, within the budget; then `done(problem)`: nil after the last entry, the error's text when `fn` failed (the walk stops there; noted under one label per set, `data job Each Items`). Gives the job's handle (`:Stop()`); false when the set is not ready (it is asked for). |
| `Items:Stamp()` | A number that moves when the set loads, and later when learned or accepted data changes it. |
| `Items:OnStamp(fn)` | `fn(handle)` on the frame after the stamp moved, never inside the loader's job (a listener may start a job, or run `Steps.Check`): a view redraws then, instead of looking every frame. A `fn` given twice is told once; its failure is noted as `data: Items listener`. |
| `Items:OffStamp(fn)` | Stops telling `fn`: one given to `OnStamp`, or one waiting in `WhenReady`. |
| `Data.WhenReady(Items, fn)` | `fn(handle)` once the set (its handle or its name) is ready: at once if it is, in the caller's own call; else on the frame after it arrived, once, and its pack is asked for (`Prepare`). |
| `Items:State()` | `"ready"`, `"loading"`, `"idle"` (can be loaded, not asked for), `"missing"`, `"off"` (switched off in the addon list) or `"refused"`; and a few words why. |
| `Items:Ready()` | `State() == "ready"`. |
| `Items.hash`, `Items.build` | Where the data came from: its hash, the newest build it knows (nil until loaded). |

- **What this client has reached:** a pack made for a later patch than the client's build answers with the
  versions that build has; `History`, `At`, `Changes` and `Each` stop there too. `Keys` come from the pack's
  newest versions, so on such a client `Get` of one of them can be nil.
- **nil means not known.** No read ever raises an error, also on a pack's values of the wrong kind (a row,
  a history or an index that is no text or table is no entry), and a read is always cheap: one table index
  and, the first time, one row taken apart (about 2.5 µs); a set that cannot be had (its pack missing, off
  or refused) remembers it, so a `Get` of it makes no text. **`Get` never loads a pack** (decision 20).
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
- A module that draws often (Tooltips) calls `Prepare` in its `OnLogin`, so its packs are there before the
  first tooltip.

### Loading

- **Packs are found at first need,** by their TOC lines (`C_AddOns.GetAddOnMetadata`, without loading them):
  every addon named `SaneUI_Data_*` with `X-SaneUI-Sets`, `X-SaneUI-Format` and `X-SaneUI-Game`. Core keeps
  no list of its own.
- **A pack is refused** when its format is not 1, its game version is not the client's, or the client's
  game version cannot be told. **Off** when the player switched it off (`GetAddOnEnableState` for the
  character, or the reason `DISABLED`): the player's choice stands, Core never switches a pack on.
- **`Prepare`** puts the pack in line; the loading is a job of the scheduler (`Steps`) that starts once the
  loading screen is gone (`LOADING_SCREEN_DISABLED`) and waits while one is up: out of combat and without a
  restriction, one pack per frame, alone in its frame (`C_AddOns.LoadAddOn`).
- **Said once:** a pack missing or switched off is noted in the error log, quietly (`Core.NoteError`); a pack
  that fails to load or a set file that does not run is reported (`Core.Report`: one line in chat). The
  modules fall back.

### `/sane data`

The client's game version and build with the three answers it was told by, every pack with its state and
its sets' hashes, and the scheduler's jobs, each with the milliseconds it worked and its frames, and whether
they wait now (a fight, a restriction). `/sane data show <set> <key>` prints an entry and what changed, by
patch (and asks for its pack if it is not loaded); the key is a number only in a set keyed by numbers (a
text key may look like one). `/sane data` also tells the client anew (`Data.Find`): its game version and
build; the answers made from them are made again only when either changed.

## The scheduler: jobs

`Core.Steps` (`src/Core/Data/Steps.lua`) runs every long piece of the framework's work in steps: loading
packs, a walk over a set, later the scan's reading, shared data taken in, the characters, the crawl; and
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
| `Steps.Spend()` | In a job: the frame's time is all used; nothing else runs in it. With `Fresh` before it: a step that cannot be cut (loading a pack) runs alone in its frame. |
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
  within it (a pack's `ADDON_LOADED` comes inside `LoadAddOn`): what an event tells is told after the job,
  on the next frame (`OnStamp`).
- Its frame is shown only while there is work: no `OnUpdate` at rest.

## Saved variables *(1c)*

- **Keyed by game version first:** `SaneUIDB.data["forever"]`, `SaneUIData_Items["forever-beta"]`. Core uses
  only its client's key; the others (a copied `WTF`) are left as they are.
- **Core's** (`SaneUIDB.data[game]`): `format` (1); `inbox` (`[set][key] = row`, at most 2,000 rows: learned
  data for a pack not loaded yet, decision 19); `checked` (`[set] = build`, the patch check); `saved`
  (`[pack] = values`, how much each pack saved last: *a lost file*); `crawl` (`[kind] = place`).
- **A pack's** (`SaneUIData_<Pack>[game]`): `format` (1); `learned` (`[set][key] = row`, a whole row in
  the pack's format); `broken` (parts of a wrong shape, kept for the harvest); and what the pack has of its
  own: the Market pack its series per auction house (`houses["eu/1234/horde"]`), the World pack its drop
  counts, the Characters pack the characters.
- **Packed strings, never tables of tables,** for anything that grows (rows, a series' months, a bag), and
  at most 100,000 values per saved variable (Lua's constant limit would lose the whole file).
- **Every part is checked on load:** the format number with upgrade steps; a part of a wrong shape goes to
  `broken`, the rest works.

## Messages *(1f)*

- **Prefix `SaneUI`;** the guild, party and raid channels only (decision 9).
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
  shared. In the master a day is a date (`2026-11-03`); in packs, saved files and messages its number.

## Adding a set

1. **Its pack:** what is needed together at the same moment goes into one pack; what is big and needed
   rarely gets its own (the plan, *Sets by concern*). A new pack is a section in `packs.toml`.
2. **Its schema:** `assets/data/<Set>/schema.toml`: its key, pack, `about`, the fields in the order a pack
   will carry them, the indexes a module will ask by.
3. **Its facts:** a tool of ours writes staging into `dev/data/staging/`, each line with its game version,
   build and source; a new batch gets its number in `sources.toml` (with `game`, `seen` and `build`). A
   short hand-made list is written into `<Set>.jsonl` directly, with the source `hand`.
4. **Taken in:** `dev/tools/data import <file>`; read the report (new, agreeing, changed, conflicts,
   refused); then `--apply`. Conflicts are looked at, not forced.
5. **Checked and built:** `dev/tools/data check`, `dev/tests/run`, `dev/build`.
6. **Read:** a module asks `Data.Set("<Set>")`, `Prepare`s it where it draws often, and falls back on nil.
7. **Tested** on small sample masters in `dev/tests/data/`, never on the real data.

## Tools

| Command | Does |
| --- | --- |
| `dev/tools/data check` | Checks the master (run by `dev/tests/run`). |
| `dev/tools/data import <file> [--apply] [--take]` | Staging into the master, the report first. |
| `dev/tools/data compile <dir> [--game <game version>]` | The packs (run by `dev/build`). |
| `dev/tools/data game <game folder>` | The game version a game folder holds, by the product its `.flavor.info` names (`wowf`: `forever`; `wow_classic_beta`: `forever-beta` today); nothing for a product not known. `dev/build` installs that game version's packs. |
| `dev/tools/data show <set> <key> [--game <game version>]` | An entry: every version as its line says it (build, patch, day, sources, what changed) with its fix, then the entry as the packs carry it. |
| `dev/tools/data diff <set> [--patch 1.60.2] [--game <game version>]` | What a patch changed (the game version's newest when none is named): every entry new, changed (field from → to), gone or back at one of its builds. |
| `dev/tools/data stats` | Per game version and set: entries, versions, entries that changed, gone ones, its own lines, its file's size in the pack; each pack's totals. |
| `dev/tools/data harvest` *(1c)* | The packs' saved files into staging, accepted data only. |
| `dev/tools/cvar-labels --staging` | The CVar labels as staging for the set *CVarLabels*. |

## Tests

- **The tools** (`dev/tests/data/tools.py`): each rule of the check caught; every import case on sample
  masters, each within its own game version; compiling twice gives the same bytes; a live pack holds nothing
  of another game version, another's is live's with its own on top.
- **In the game** (`dev/tests/data.lua`, Lua 5.1 with `wowstub.lua`): the codec reads back every row the
  Python compiler wrote from the sample masters (the one test that keeps the two languages in step);
  packs found, loaded, refused (missing, switched off, a wrong format, another game version, asked for in
  combat); `Get` never loads; frozen records; the answers on a sample with history (`History`, `At`,
  `Versions`, `Changes`, `Keys`, `Each`), also from a pack newer than the client; listeners told after the
  loader's job, `WhenReady`, `OffStamp`; the scheduler's budget, pauses (by a restriction's own event),
  guards, handles (`Stop`, `done`, `error`, `label`) and priority.
- **Nothing hostile raises an error:** a broken row, a broken saved file or message is dropped or set aside.
- **Players by their key** (`dev/tests/core.lua`): a whole name with or without a realm is one key, the same
  first name or surname two players, a first name alone none; Retail's `Name-Realm`. Steps 1c and 1f test
  their senders and characters the same way.
